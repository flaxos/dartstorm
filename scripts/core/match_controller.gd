class_name MatchController
extends Node
## Runs one round: countdown, clock, scoring, respawns and the final result.
## It knows nothing about the HUD: it just emits signals.

signal state_changed(state: State)
signal countdown_tick(seconds_left: int)
signal clock_tick(seconds_left: int)
signal tag_scored(attacker: ScoreEntry, victim: ScoreEntry, weapon: WeaponData, ricochet: bool)
## A message for one actor's screen, e.g. "+100 TAG!".
signal popup(actor: Actor, text: String, color: Color)
signal match_ended(ranking: Array[ScoreEntry])

enum State { WAITING, COUNTDOWN, PLAYING, ENDED }

var mode: GameMode
var arena: Arena
var board: Scoreboard = Scoreboard.new()
var actors: Array[Actor] = []
var state: State = State.WAITING
var time_left: float = 0.0

var _countdown_left: float = 0.0
var _last_whole_second: int = -1
var _respawns: Dictionary = {}


func setup(p_mode: GameMode, p_arena: Arena) -> void:
	mode = p_mode
	arena = p_arena
	time_left = mode.duration_seconds


func register(actor: Actor) -> void:
	actors.append(actor)
	board.add_actor(actor)
	actor.controls_enabled = false
	actor.tagged_out.connect(_on_tagged_out)


## Places everyone and starts the countdown.
func begin() -> void:
	for actor in actors:
		_spawn(actor)
	_countdown_left = float(mode.countdown_seconds)
	_last_whole_second = -1
	_set_state(State.COUNTDOWN)
	if mode.countdown_seconds <= 0:
		_start_play()


## Seconds until this actor respawns (0 if they are in play).
func respawn_time_left(actor: Actor) -> float:
	return _respawns.get(actor, 0.0)


func award_target_hit(shooter: Actor) -> void:
	if state != State.PLAYING or shooter == null:
		return
	var entry := board.entry_for(shooter)
	if entry == null:
		return
	entry.score += mode.points_per_target
	board.notify_changed()
	popup.emit(shooter, "+%d BULLSEYE!" % mode.points_per_target, UiKit.LIME)


func _physics_process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_tick_respawns(delta)
			_countdown_left -= delta
			var whole := int(ceilf(_countdown_left))
			if whole != _last_whole_second and whole > 0:
				_last_whole_second = whole
				countdown_tick.emit(whole)
			if _countdown_left <= 0.0:
				_start_play()
		State.PLAYING:
			time_left = maxf(time_left - delta, 0.0)
			var whole := int(ceilf(time_left))
			if whole != _last_whole_second:
				_last_whole_second = whole
				clock_tick.emit(whole)
			_tick_respawns(delta)
			if time_left <= 0.0:
				_finish()


func _start_play() -> void:
	_last_whole_second = -1
	for actor in actors:
		actor.controls_enabled = true
	countdown_tick.emit(0)
	_set_state(State.PLAYING)


func _finish() -> void:
	if state == State.ENDED:
		return
	for actor in actors:
		actor.controls_enabled = false
		actor.arsenal.set_trigger(false)
	_set_state(State.ENDED)
	match_ended.emit(mode.rank(board))


func _set_state(next: State) -> void:
	state = next
	state_changed.emit(state)


func _tick_respawns(delta: float) -> void:
	for actor: Actor in _respawns.keys():
		var left: float = _respawns[actor] - delta
		if left <= 0.0:
			_respawns.erase(actor)
			if is_instance_valid(actor):
				_spawn(actor)
		else:
			_respawns[actor] = left


func _on_tagged_out(victim: Actor, attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	if state == State.ENDED:
		return
	# Anyone tagged out comes back, whenever it happens (even a fall off the
	# map during the countdown). Points are only awarded while playing.
	_respawns[victim] = mode.respawn_delay
	if state != State.PLAYING:
		return
	var victim_entry := board.entry_for(victim)
	if victim_entry != null:
		victim_entry.outs += 1
	var attacker_entry: ScoreEntry = null
	if attacker != null:
		attacker_entry = board.entry_for(attacker)
	if attacker_entry == null or attacker == victim:
		board.notify_changed()
		return

	var tier_before := attacker_entry.tier
	attacker_entry.tags += 1
	if ricochet:
		attacker_entry.ricochet_tags += 1
	mode.apply_tag(attacker_entry, victim_entry, ricochet)
	popup.emit(attacker, "+%d TAG!" % mode.points_per_tag, UiKit.ORANGE_HOT)
	if ricochet:
		popup.emit(attacker, "+%d RICOCHET BONUS!" % mode.ricochet_bonus, UiKit.SKY)
	tag_scored.emit(attacker_entry, victim_entry, weapon, ricochet)
	board.notify_changed()

	var winner := mode.get_early_winner(board)
	if winner != null:
		_finish()
		return
	if attacker_entry.tier != tier_before and attacker.alive:
		_equip(attacker)
		var held := attacker.arsenal.current()
		if held != null:
			popup.emit(attacker, "NEW BLASTER: %s" % held.data.display_name.to_upper(), UiKit.LIME)


func _spawn(actor: Actor) -> void:
	actor.respawn(_choose_spawn(actor))
	_equip(actor)


func _equip(actor: Actor) -> void:
	var entry := board.entry_for(actor)
	if entry == null:
		return
	actor.arsenal.set_loadout(mode.get_loadout(entry), mode.infinite_reserve)


## Picks a spawn point far from everyone else, with a little randomness.
func _choose_spawn(actor: Actor) -> Transform3D:
	if arena == null or arena.spawn_points.is_empty():
		return actor.global_transform
	var scored: Array = []
	for marker in arena.spawn_points:
		var nearest := 999.0
		for other in actors:
			if other != actor and other.alive:
				nearest = minf(nearest, marker.global_position.distance_to(other.global_position))
		scored.append([nearest, marker])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var pick: Marker3D = scored[randi() % mini(3, scored.size())][1]
	return pick.global_transform
