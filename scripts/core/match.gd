class_name MatchScene
extends Node3D
## The match scene: builds one round out of an arena, the player, some bots and
## the UI, then hands control to the MatchController. This is the only place
## that knows how those pieces are wired together.
##
## Hardened against broken data: if a mode or difficulty file is missing or
## corrupt it falls back to the defaults (with a warning) rather than crashing,
## and if the arena itself can't load it returns to the main menu.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const ARENA_SCENE := "res://scenes/arenas/backyard_fortress.tscn"
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BOT_SCENE := preload("res://scenes/enemies/bot.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")

## Indexed by GameSettings.match_mode.
const MODE_PATHS := [
	"res://resources/modes/free_for_all.tres",
	"res://resources/modes/gun_game.tres",
]
## Indexed by GameSettings.bot_difficulty.
const DIFFICULTY_PATHS := [
	"res://resources/bots/easy.tres",
	"res://resources/bots/normal.tres",
	"res://resources/bots/hard.tres",
]
const BOT_ROSTER := [
	{"name": "Blaze", "color": Color(1.0, 0.5, 0.1), "hat": &"cap"},
	{"name": "Pickle", "color": Color(0.55, 0.85, 0.15), "hat": &"beanie"},
	{"name": "Zoom", "color": Color(0.7, 0.4, 1.0), "hat": &"propeller"},
	{"name": "Sprinkles", "color": Color(1.0, 0.4, 0.7), "hat": &"party"},
	{"name": "Noodle", "color": Color(1.0, 0.85, 0.2), "hat": &"cowboy"},
]
## Seconds of podium celebration before the relaxed music returns.
const RESULTS_MUSIC_DELAY := 3.0

var arena: Arena
var controller: MatchController
var dart_pool: DartPool
var player: Player
var bots: Array[Bot] = []
var hud: Hud
var pause_menu: PauseMenu
var podium: Podium
var power_up: PowerUpPickup


## Loads a resource without ever crashing: returns null if the file is missing
## or can't be parsed.
static func try_load(path: String) -> Resource:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path)


## Loads `path`, or `fallback` if that fails, so a broken file never stops a match.
static func load_or_fallback(path: String, fallback: String) -> Resource:
	var resource := try_load(path)
	if resource == null:
		push_warning("Could not load %s, using %s instead." % [path, fallback])
		resource = try_load(fallback)
	return resource


## The GameMode for a menu index. Always returns something playable.
static func resolve_mode(index: int) -> GameMode:
	var path: String = MODE_PATHS[clampi(index, 0, MODE_PATHS.size() - 1)]
	var mode := load_or_fallback(path, MODE_PATHS[0]) as GameMode
	if mode == null:
		push_error("No usable game mode found, using built-in free-for-all rules.")
		mode = GameMode.new()
	return mode


## Colours for the bots: their usual colour, unless it's too close to the
## player's. Then they borrow an unused one from the palette.
static func bot_colors(player_color: Color, count: int) -> Array[Color]:
	var taken: Array[Color] = [player_color]
	var out: Array[Color] = []
	for i in count:
		var wanted: Color = BOT_ROSTER[i]["color"]
		if Cosmetics.too_similar(wanted, player_color):
			for option in Cosmetics.COLORS:
				var candidate: Color = option["color"]
				var free := true
				for used in taken:
					free = free and not Cosmetics.too_similar(candidate, used)
				for roster_entry: Dictionary in BOT_ROSTER:
					free = free and not Cosmetics.too_similar(candidate, roster_entry["color"])
				if free:
					wanted = candidate
					break
		taken.append(wanted)
		out.append(wanted)
	return out


## The BotDifficulty for a menu index. Always returns something usable.
static func resolve_difficulty(index: int) -> BotDifficulty:
	var path: String = DIFFICULTY_PATHS[clampi(index, 0, DIFFICULTY_PATHS.size() - 1)]
	var difficulty := load_or_fallback(path, DIFFICULTY_PATHS[1]) as BotDifficulty
	if difficulty == null:
		push_error("No usable bot difficulty found, using built-in Normal.")
		difficulty = BotDifficulty.new()
	return difficulty


func _ready() -> void:
	# A private copy, so per-match switches never leak into the shared .tres.
	var mode := resolve_mode(GameSettings.match_mode).duplicate() as GameMode
	var demo_powerup := OS.get_cmdline_user_args().has("--powerup")  # Screenshot runs only.
	mode.power_up_mode = (GameSettings.chainstorm_powerup or demo_powerup) and not mode is GunGameMode
	var difficulty := resolve_difficulty(GameSettings.bot_difficulty)

	var arena_scene := try_load(ARENA_SCENE) as PackedScene
	arena = arena_scene.instantiate() as Arena if arena_scene != null else null
	if arena == null:
		push_error("Could not load the arena %s, returning to the menu." % ARENA_SCENE)
		quit_to_menu.call_deferred()
		return
	add_child(arena)

	dart_pool = DartPool.new()
	dart_pool.name = "DartPool"
	dart_pool.wind_field = arena.wind_field
	add_child(dart_pool)

	var fx := CombatFx.new()
	fx.name = "CombatFx"
	add_child(fx)
	fx.watch_pool(dart_pool)

	controller = MatchController.new()
	controller.name = "MatchController"
	controller.setup(mode, arena)
	add_child(controller)

	player = PLAYER_SCENE.instantiate() as Player
	player.display_name = GameSettings.display_name()
	player.color = GameSettings.color()
	player.hat_id = GameSettings.player_hat
	player.team_id = 0
	player.dart_pool = dart_pool
	add_child(player)
	fx.watch_actor(player)
	controller.register(player)

	var bot_count := clampi(GameSettings.bot_count, 1, BOT_ROSTER.size())
	var colors := bot_colors(player.color, bot_count)
	for i in bot_count:
		var bot := BOT_SCENE.instantiate() as Bot
		bot.display_name = BOT_ROSTER[i]["name"]
		bot.color = colors[i]
		bot.hat_id = BOT_ROSTER[i]["hat"]
		bot.team_id = i + 1
		bot.difficulty = difficulty
		bot.arena = arena
		bot.dart_pool = dart_pool
		add_child(bot)
		fx.watch_actor(bot)
		controller.register(bot)
		bots.append(bot)
	for bot in bots:
		for actor in controller.actors:
			if actor != bot:
				bot.rivals.append(actor)

	if mode.uses_power_up() and not arena.power_up_spots.is_empty():
		_create_power_up(mode)

	for node in get_tree().get_nodes_in_group(&"wobble_targets"):
		var target := node as WobbleTarget
		if target != null:
			target.hit.connect(controller.award_target_hit)

	hud = HUD_SCENE.instantiate() as Hud
	add_child(hud)
	hud.setup(player, controller)
	hud.restart_requested.connect(restart)
	hud.menu_requested.connect(quit_to_menu)

	pause_menu = PAUSE_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	pause_menu.setup(controller)
	pause_menu.restart_requested.connect(restart)
	pause_menu.menu_requested.connect(quit_to_menu)

	controller.match_ended.connect(_on_match_ended)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.play_music(&"match")
	controller.begin()

	if OS.get_cmdline_user_args().has("--demo"):
		add_child(DemoDriver.new())


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_match_ended(ranking: Array[ScoreEntry]) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_music()
	if power_up != null:
		power_up.active = false
	podium = Podium.new()
	podium.name = "Podium"
	add_child(podium)
	podium.show_ranking(ranking)
	get_tree().create_timer(RESULTS_MUSIC_DELAY).timeout.connect(func() -> void: Sfx.play_music(&"menu"))


func _create_power_up(mode: GameMode) -> void:
	power_up = PowerUpPickup.new()
	power_up.name = "PowerUp"
	power_up.setup(mode.power_weapon, mode.power_weapon_belt, mode.power_weapon_first_delay, mode.power_weapon_respawn)
	arena.add_child(power_up)
	power_up.global_position = arena.power_up_spots[0]
	for bot in bots:
		bot.power_up = power_up
	controller.state_changed.connect(func(state: MatchController.State) -> void:
		power_up.active = state == MatchController.State.PLAYING)
	power_up.spawned.connect(func() -> void:
		controller.announce(null, "%s HAS LANDED!" % mode.power_weapon.display_name.to_upper(), UiKit.ORANGE_HOT, &"powerup"))
	power_up.collected.connect(func(actor: Actor) -> void:
		var entry := controller.board.entry_for(actor)
		var prize := mode.power_weapon.display_name.to_upper()
		var text := "YOU GRABBED %s!" % prize if actor.is_human else "%s GRABBED %s!" % [actor.display_name.to_upper(), prize]
		controller.announce(entry, text, MatchController.color_for(entry), &"announce"))
