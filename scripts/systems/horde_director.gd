class_name HordeDirector
extends Node
## AI Horde Director for Zombie Siege (Base Defense mode).
## Orchestrates 5 escalating zombie waves, batching spawns along the perimeter,
## managing enemy archetypes (Runners, Brutes, Mega Titan Boss), and running
## the 20-second Intermission fortification phase between waves.

signal wave_started(wave_number: int, total_enemies: int, wave_name: String)
signal wave_state_changed(new_state: int)
signal intermission_tick(seconds_left: int)
signal enemy_spawned(bot: Bot, archetype: StringName)
signal enemy_eliminated(bot: Bot, remaining: int)
signal scrap_changed(current_scrap: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared
signal defeat

enum State { INACTIVE, COUNTDOWN, SPAWNING, COMBAT, INTERMISSION, VICTORY, DEFEAT }

const BOT_SCENE := preload("res://scenes/enemies/bot.tscn")
const BATCH_INTERVAL := 2.2
const BATCH_SIZE := 3
const INTERMISSION_DURATION := 25.0

const WAVES: Array[Dictionary] = [
	{"wave": 1, "name": "THE OUTBREAK", "runners": 6, "brutes": 0, "boss": false},
	{"wave": 2, "name": "TWIN PINCER", "runners": 10, "brutes": 0, "boss": false},
	{"wave": 3, "name": "JUMPERS & SPITTERS", "runners": 12, "brutes": 2, "boss": false},
	{"wave": 4, "name": "HEAVY FOAM BRUTES", "runners": 14, "brutes": 4, "boss": false},
	{"wave": 5, "name": "THE MEGA TITAN", "runners": 16, "brutes": 0, "boss": true},
]

var current_wave: int = 0
var state: State = State.INACTIVE
var remaining_enemies: int = 0
var total_wave_enemies: int = 0
var scrap: int = 0
var intermission_time_left: float = 0.0

var arena: Arena
var controller: MatchController
var base_core: BaseCore
var barricades: Array[BaseBarricade] = []
var dart_pool: DartPool
var difficulty: BotDifficulty
var active_zombies: Array[Bot] = []

var _pending_spawns: Array[StringName] = []
var _spawn_timer: float = 0.0
var _last_whole_intermission_sec: int = -1


func _ready() -> void:
	add_to_group(&"horde_director")


func setup(p_arena: Arena, p_controller: MatchController, p_core: BaseCore,
		p_barricades: Array[BaseBarricade], p_pool: DartPool, p_diff: BotDifficulty) -> void:
	arena = p_arena
	controller = p_controller
	base_core = p_core
	barricades = p_barricades
	dart_pool = p_pool
	difficulty = p_diff

	if base_core != null:
		base_core.destroyed.connect(_on_base_core_destroyed)


func start() -> void:
	current_wave = 0
	scrap = 100  # Starting fortification scrap
	scrap_changed.emit(scrap)
	_start_wave(1)


func _start_wave(wave_num: int) -> void:
	current_wave = clampi(wave_num, 1, WAVES.size())
	var wave_info: Dictionary = WAVES[current_wave - 1]
	var runners: int = wave_info.get("runners", 10)
	var brutes: int = wave_info.get("brutes", 0)
	var has_boss: bool = wave_info.get("boss", false)

	_pending_spawns.clear()
	for i in runners:
		_pending_spawns.append(&"runner")
	for i in brutes:
		_pending_spawns.append(&"brute")
	_pending_spawns.shuffle()
	if has_boss:
		_pending_spawns.append(&"titan_boss")

	total_wave_enemies = _pending_spawns.size()
	remaining_enemies = total_wave_enemies
	_spawn_timer = 0.0
	_set_state(State.SPAWNING)

	wave_started.emit(current_wave, total_wave_enemies, str(wave_info.get("name", "HORDE")))
	if controller != null:
		controller.announce(null, "WAVE %d: %s" % [current_wave, str(wave_info.get("name", "HORDE"))],
				Color(0.38, 0.78, 0.28), &"announce")


func _process(delta: float) -> void:
	if controller != null and controller.state != MatchController.State.PLAYING:
		return
	match state:
		State.SPAWNING:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_spawn_timer = BATCH_INTERVAL
				_spawn_batch()
				if _pending_spawns.is_empty():
					_set_state(State.COMBAT)

		State.INTERMISSION:
			intermission_time_left -= delta
			var sec := int(ceilf(intermission_time_left))
			if sec != _last_whole_intermission_sec:
				_last_whole_intermission_sec = sec
				intermission_tick.emit(sec)
			if intermission_time_left <= 0.0:
				_start_wave(current_wave + 1)


func _spawn_batch() -> void:
	for i in mini(BATCH_SIZE, _pending_spawns.size()):
		var arch: StringName = _pending_spawns.pop_front()
		_spawn_single_enemy(arch)


func _spawn_single_enemy(archetype: StringName) -> void:
	var bot := BOT_SCENE.instantiate() as Bot
	bot.name = "HordeZombie_%d" % (total_wave_enemies - _pending_spawns.size())
	bot.display_name = "Mega Foam Titan" if archetype == &"titan_boss" else ("Foam Brute" if archetype == &"brute" else "Foam Runner")
	bot.hat_id = &"horns" if archetype == &"titan_boss" else (&"beanie" if archetype == &"brute" else &"none")
	bot.team_id = 1
	bot.color = Color(0.38, 0.78, 0.28)
	bot.difficulty = difficulty
	bot.arena = arena
	bot.dart_pool = dart_pool
	bot.base_core = base_core
	bot.barricades = barricades

	var spawn_xf := _find_perimeter_spawn()
	add_child(bot)
	bot.global_transform = spawn_xf
	bot.set_zombie(true)
	bot.apply_archetype(archetype)

	if controller != null:
		controller.register(bot)
		bot.controls_enabled = (controller.state == MatchController.State.PLAYING)
		# Link defenders and horde zombie as mutual rivals
		for actor in controller.actors:
			if actor != bot and is_instance_valid(actor) and actor.team_id == 0:
				bot.rivals.append(actor)
				if actor is Bot:
					(actor as Bot).rivals.append(bot)
	else:
		bot.controls_enabled = true

	bot.tagged_out.connect(_on_zombie_tagged_out)
	active_zombies.append(bot)
	enemy_spawned.emit(bot, archetype)


func _find_perimeter_spawn() -> Transform3D:
	if arena == null or arena.spawn_points.is_empty():
		var ang := randf() * TAU
		var p := Vector3(cos(ang) * 22.0, 1.0, sin(ang) * 22.0)
		return Transform3D(Basis(), p)

	# Pick from spawn points furthest from Base Core
	var center := base_core.global_position if base_core != null else Vector3.ZERO
	var sorted := arena.spawn_points.duplicate()
	sorted.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return a.global_position.distance_squared_to(center) > b.global_position.distance_squared_to(center))

	var half := maxi(1, floori(float(sorted.size()) * 0.5))
	var chosen: Marker3D = sorted[randi() % half]
	return chosen.global_transform


func _on_zombie_tagged_out(victim: Actor, attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	var bot := victim as Bot
	if bot == null or not active_zombies.has(bot):
		return

	active_zombies.erase(bot)
	remaining_enemies = maxi(remaining_enemies - 1, 0)

	# Award scrap based on archetype
	var scrap_award := 20
	if bot.archetype == &"runner":
		scrap_award = 35
	elif bot.archetype == &"brute":
		scrap_award = 60
	elif bot.archetype == &"titan_boss":
		scrap_award = 150

	add_scrap(scrap_award)
	enemy_eliminated.emit(bot, remaining_enemies)

	if controller != null and attacker != null and attacker.is_local_human():
		controller.popup.emit(attacker, "+%d SCRAP" % scrap_award, UiKit.LIME)

	# Remove from defender rivals & match controller before freeing
	if controller != null:
		for actor in controller.actors:
			if actor is Bot and is_instance_valid(actor):
				(actor as Bot).rivals.erase(bot)
		controller.unregister(bot)

	# Clean up zombie actor node
	bot.queue_free()

	# Check wave finish
	if remaining_enemies <= 0 and _pending_spawns.is_empty():
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	wave_cleared.emit(current_wave)
	if current_wave >= WAVES.size():
		_trigger_victory()
	else:
		_start_intermission()


func _start_intermission() -> void:
	_set_state(State.INTERMISSION)
	intermission_time_left = INTERMISSION_DURATION
	_last_whole_intermission_sec = -1

	# Replenish ammo buckets in the arena
	if arena != null:
		for b in arena.buckets:
			if b != null:
				b.stock = b.capacity
				b._refresh()

	# Award wave bonus scrap
	add_scrap(75)

	if controller != null:
		controller.announce(null, "WAVE %d CLEARED! INTERMISSION (25s)" % current_wave,
				UiKit.LIME, &"announce")


func _trigger_victory() -> void:
	_set_state(State.VICTORY)

	# Unlock exclusive Toxic Slime blaster skin & award bonus coins/XP
	if Engine.has_singleton("Progression") or get_node_or_null("/root/Progression") != null:
		var prog: Node = get_node("/root/Progression")
		prog.call("unlock_item", &"skin", &"slime")
		prog.call("add_xp", 300)
		prog.call("add_coins", 150)

	if controller != null:
		controller.announce(null, "VICTORY! BASE SECURED! UNLOCKED TOXIC SLIME SKIN!",
				UiKit.LIME, &"announce")
	all_waves_cleared.emit()


func _on_base_core_destroyed() -> void:
	if state == State.VICTORY or state == State.DEFEAT:
		return
	_set_state(State.DEFEAT)
	if controller != null:
		controller.announce(null, "BASE CORE DESTROYED! RETREAT!", Color(0.95, 0.22, 0.25), &"shutdown")
	defeat.emit()


func _set_state(new_state: State) -> void:
	state = new_state
	wave_state_changed.emit(int(state))


func add_scrap(amount: int) -> void:
	if amount <= 0:
		return
	scrap += amount
	scrap_changed.emit(scrap)


func spend_scrap(amount: int) -> bool:
	if amount <= 0:
		return true
	if scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true


func repair_base_core(cost: int = 100, amount: float = 250.0) -> bool:
	if base_core == null or base_core.is_destroyed:
		return false
	if base_core.health >= base_core.max_health:
		return false
	if not spend_scrap(cost):
		return false
	base_core.repair(amount)
	return true


func rebuild_barricade(barricade: BaseBarricade, cost: int = 75) -> bool:
	if barricade == null or not barricade.is_broken:
		return false
	if not spend_scrap(cost):
		return false
	barricade.rebuild()
	return true
