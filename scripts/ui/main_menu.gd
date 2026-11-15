extends Node3D
## Title screen. The Backyard Fortress spins slowly in the background while the
## player picks a mode, how many bots, and how tough they are.

const MATCH_SCENE := "res://scenes/game/match.tscn"
const ARENA_SCENE := preload("res://scenes/arenas/backyard_fortress.tscn")
const DIFFICULTY_NAMES := ["EASY", "NORMAL", "HARD"]
const MIN_BOTS := 2
const MAX_BOTS := 5

var _orbit: Node3D
var _ui: Control
var _menu: Control
var _settings: SettingsPanel
var _bots_value: Label
var _difficulty_button: Button


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var arena := ARENA_SCENE.instantiate() as Arena
	arena.bake_navigation = false
	add_child(arena)
	_orbit = Node3D.new()
	add_child(_orbit)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 17.0, 44.0)
	camera.rotation_degrees.x = -19.0
	camera.fov = 60.0
	camera.current = true
	_orbit.add_child(camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	_build_menu()

	_settings = SettingsPanel.new()
	_settings.visible = false
	_ui.add_child(_settings)
	UiKit.pin(_settings, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_settings.closed.connect(_show_settings.bind(false))

	if OS.get_cmdline_user_args().has("--demo"):
		add_child(DemoDriver.new())


func _process(delta: float) -> void:
	_orbit.rotate_y(delta * 0.08)


func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_menu)

	# Title.
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", -8)
	_menu.add_child(title_box)
	UiKit.pin(title_box, Vector2(0.0, 0.0), Vector2(48, 28), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_END)
	title_box.add_child(UiKit.label("DARTSTORM", 104, UiKit.ORANGE_HOT, 20))
	title_box.add_child(UiKit.label("ELEMENTAL ARENA", 36, UiKit.SKY, 10))

	# Buttons.
	var panel := UiKit.panel(UiKit.NAVY, 0.9, 22, 4, UiKit.ORANGE, 22)
	_menu.add_child(panel)
	UiKit.pin(panel, Vector2(0.0, 1.0), Vector2(48, -36), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var play := UiKit.button("PLAY: BACKYARD BATTLE", 26, Vector2(400, 60))
	play.pressed.connect(_play.bind(GameSettings.MatchMode.FREE_FOR_ALL))
	box.add_child(play)
	var gun_game := UiKit.button("PLAY: GUN GAME", 26, Vector2(400, 60))
	gun_game.pressed.connect(_play.bind(GameSettings.MatchMode.GUN_GAME))
	box.add_child(gun_game)

	var bots_row := HBoxContainer.new()
	bots_row.add_theme_constant_override("separation", 10)
	box.add_child(bots_row)
	var bots_label := UiKit.label("BOTS", 22, UiKit.CREAM, 4)
	bots_label.custom_minimum_size.x = 150
	bots_row.add_child(bots_label)
	var fewer := UiKit.small_button("-")
	fewer.pressed.connect(_change_bots.bind(-1))
	bots_row.add_child(fewer)
	_bots_value = UiKit.label("", 28, UiKit.ORANGE_HOT)
	_bots_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bots_value.custom_minimum_size.x = 60
	bots_row.add_child(_bots_value)
	var more := UiKit.small_button("+")
	more.pressed.connect(_change_bots.bind(1))
	bots_row.add_child(more)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 10)
	box.add_child(difficulty_row)
	var difficulty_label := UiKit.label("BOT SKILL", 22, UiKit.CREAM, 4)
	difficulty_label.custom_minimum_size.x = 150
	difficulty_row.add_child(difficulty_label)
	_difficulty_button = UiKit.small_button("", Vector2(190, 44))
	_difficulty_button.pressed.connect(_cycle_difficulty)
	difficulty_row.add_child(_difficulty_button)

	var settings := UiKit.small_button("SETTINGS", Vector2(400, 48))
	settings.pressed.connect(_show_settings.bind(true))
	box.add_child(settings)
	var quit := UiKit.small_button("QUIT", Vector2(400, 48))
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)

	# How to play.
	var help := UiKit.panel(UiKit.NAVY, 0.86, 22, 0, UiKit.ORANGE, 20)
	_menu.add_child(help)
	UiKit.pin(help, Vector2(1.0, 1.0), Vector2(-36, -36), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BEGIN)
	var help_box := VBoxContainer.new()
	help_box.add_theme_constant_override("separation", 4)
	help.add_child(help_box)
	help_box.add_child(UiKit.label("HOW TO PLAY", 26, UiKit.ORANGE_HOT, 8))
	var lines := [
		"Move: W A S D     Look: Mouse",
		"Jump: Space     Sprint: Shift",
		"Fire: Left click     Reload: R",
		"Blasters: 1 2 3 or mouse wheel",
		"Scoreboard: Tab     Pause: Esc",
		"",
		"Tag the bots with foam darts!",
		"Darts drop, curve in the wind and",
		"bounce off the shiny mirror panels.",
		"Stand by a bucket to refill ammo.",
	]
	for line: String in lines:
		help_box.add_child(UiKit.label(line, 18, UiKit.CREAM, 4))

	_refresh_options()
	play.grab_focus()


func _play(mode: int) -> void:
	GameSettings.match_mode = mode
	GameSettings.save_settings()
	get_tree().change_scene_to_file(MATCH_SCENE)


func _change_bots(step: int) -> void:
	GameSettings.bot_count = clampi(GameSettings.bot_count + step, MIN_BOTS, MAX_BOTS)
	_refresh_options()


func _cycle_difficulty() -> void:
	GameSettings.bot_difficulty = (GameSettings.bot_difficulty + 1) % DIFFICULTY_NAMES.size()
	_refresh_options()


func _refresh_options() -> void:
	_bots_value.text = str(GameSettings.bot_count)
	_difficulty_button.text = DIFFICULTY_NAMES[clampi(GameSettings.bot_difficulty, 0, DIFFICULTY_NAMES.size() - 1)]


func _show_settings(shown: bool) -> void:
	_settings.visible = shown
	_menu.visible = not shown
