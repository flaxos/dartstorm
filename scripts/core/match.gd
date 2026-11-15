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
const PLAYER_COLOR := Color(0.15, 0.5, 1.0)
const BOT_ROSTER := [
	{"name": "Blaze", "color": Color(1.0, 0.5, 0.1)},
	{"name": "Pickle", "color": Color(0.55, 0.85, 0.15)},
	{"name": "Zoom", "color": Color(0.7, 0.4, 1.0)},
	{"name": "Sprinkles", "color": Color(1.0, 0.4, 0.7)},
	{"name": "Noodle", "color": Color(1.0, 0.85, 0.2)},
]

var arena: Arena
var controller: MatchController
var dart_pool: DartPool
var player: Player
var bots: Array[Bot] = []
var hud: Hud
var pause_menu: PauseMenu


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


## The BotDifficulty for a menu index. Always returns something usable.
static func resolve_difficulty(index: int) -> BotDifficulty:
	var path: String = DIFFICULTY_PATHS[clampi(index, 0, DIFFICULTY_PATHS.size() - 1)]
	var difficulty := load_or_fallback(path, DIFFICULTY_PATHS[1]) as BotDifficulty
	if difficulty == null:
		push_error("No usable bot difficulty found, using built-in Normal.")
		difficulty = BotDifficulty.new()
	return difficulty


func _ready() -> void:
	var mode := resolve_mode(GameSettings.match_mode)
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
	player.display_name = "You"
	player.color = PLAYER_COLOR
	player.team_id = 0
	player.dart_pool = dart_pool
	add_child(player)
	fx.watch_actor(player)
	controller.register(player)

	var bot_count := clampi(GameSettings.bot_count, 1, BOT_ROSTER.size())
	for i in bot_count:
		var bot := BOT_SCENE.instantiate() as Bot
		bot.display_name = BOT_ROSTER[i]["name"]
		bot.color = BOT_ROSTER[i]["color"]
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


func _on_match_ended(_ranking: Array[ScoreEntry]) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
