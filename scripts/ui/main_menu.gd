extends Node3D
## Title screen. The Backyard Fortress spins slowly in the background while the
## player picks a mode, the bots, the Chainstorm rule, and their own look
## (name, colour, hat) with a live 3D preview. Fully usable with a controller.

const MATCH_SCENE := "res://scenes/game/match.tscn"
const ARENA_SCENE := preload("res://scenes/arenas/backyard_fortress.tscn")
const DIFFICULTY_NAMES := ["EASY", "NORMAL", "HARD"]
const MIN_BOTS := 2
const MAX_BOTS := 5
const KEYBOARD_HELP := [
	"Move: W A S D     Look: Mouse",
	"Jump: Space     Sprint: Shift",
	"Fire: Left click     Reload: R",
	"Blasters: 1 2 3 or mouse wheel",
	"Scoreboard: Tab     Pause: Esc",
]
const CONTROLLER_HELP := [
	"Move: Left stick     Look: Right stick",
	"Jump: A     Sprint: LT or click left stick",
	"Fire: RT     Reload: X",
	"Blasters: Y, LB or RB",
	"Scoreboard: Back     Pause: Start",
]
const HOW_TO_PLAY := [
	"",
	"Tag the bots with foam darts!",
	"Darts drop, curve in the wind and",
	"bounce off the shiny mirror panels.",
	"Stand by a bucket to refill ammo.",
]

var _orbit: Node3D
var _camera: Camera3D
var _ui: Control
var _menu: Control
var _settings: SettingsPanel
var _customise: PanelContainer
var _preview: CharacterModel
var _bots_value: Label
var _difficulty_button: Button
var _storm_button: Button
var _help_box: VBoxContainer
var _name_edit: LineEdit
var _swatches: Array[Button] = []
var _hat_buttons: Array[Button] = []
var _player_button: Button
var _play_button: Button
var _time: float = 0.0


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var arena := ARENA_SCENE.instantiate() as Arena
	arena.bake_navigation = false
	add_child(arena)
	_orbit = Node3D.new()
	add_child(_orbit)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 17.0, 44.0)
	_camera.rotation_degrees.x = -19.0
	_camera.fov = 60.0
	_camera.current = true
	_orbit.add_child(_camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	_build_menu()
	_build_customise()
	_build_preview()

	_settings = SettingsPanel.new()
	_settings.visible = false
	_ui.add_child(_settings)
	UiKit.pin(_settings, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_settings.closed.connect(_show_settings.bind(false))

	GameSettings.input_device_changed.connect(func(_pad: bool) -> void: _refresh_help())
	Sfx.play_music(&"menu")

	var demo_args := OS.get_cmdline_user_args()
	if demo_args.has("--demo"):
		add_child(DemoDriver.new())
		if demo_args.has("--open-customise"):
			_show_customise(true)


func _process(delta: float) -> void:
	_time += delta
	_orbit.rotate_y(delta * 0.08)
	if _preview.visible:
		_preview.rotation.y = PI + sin(_time * 0.8) * 0.7


func _unhandled_input(event: InputEvent) -> void:
	if _customise.visible and event.is_action_pressed(&"ui_cancel"):
		_show_customise(false)
		get_viewport().set_input_as_handled()


# --- Main panel -----------------------------------------------------------------

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

	_play_button = UiKit.button("PLAY: BACKYARD BATTLE", 26, Vector2(400, 60))
	_play_button.pressed.connect(_play.bind(GameSettings.MatchMode.FREE_FOR_ALL))
	box.add_child(_play_button)
	var gun_game := UiKit.button("PLAY: GUN GAME", 26, Vector2(400, 60))
	gun_game.pressed.connect(_play.bind(GameSettings.MatchMode.GUN_GAME))
	box.add_child(gun_game)

	var bots_row := _option_row(box, "BOTS")
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

	var difficulty_row := _option_row(box, "BOT SKILL")
	_difficulty_button = UiKit.small_button("", Vector2(190, 44))
	_difficulty_button.pressed.connect(_cycle_difficulty)
	difficulty_row.add_child(_difficulty_button)

	var storm_row := _option_row(box, "CHAINSTORM")
	_storm_button = UiKit.small_button("", Vector2(190, 44))
	_storm_button.tooltip_text = "EVERYONE: all players start with it.\nPOWER-UP: it lands on the treehouse; grab it first!"
	_storm_button.pressed.connect(_toggle_storm)
	storm_row.add_child(_storm_button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_player_button = UiKit.small_button("YOUR PLAYER", Vector2(195, 48))
	_player_button.pressed.connect(_show_customise.bind(true))
	row.add_child(_player_button)
	var settings := UiKit.small_button("SETTINGS", Vector2(195, 48))
	settings.pressed.connect(_show_settings.bind(true))
	row.add_child(settings)
	var quit := UiKit.small_button("QUIT", Vector2(400, 40))
	quit.pressed.connect(func() -> void: Sfx.quit_game())
	box.add_child(quit)

	# How to play (shows controller buttons when a pad is in use).
	var help := UiKit.panel(UiKit.NAVY, 0.86, 22, 0, UiKit.ORANGE, 20)
	help.name = "Help"
	_menu.add_child(help)
	UiKit.pin(help, Vector2(1.0, 1.0), Vector2(-36, -36), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BEGIN)
	_help_box = VBoxContainer.new()
	_help_box.add_theme_constant_override("separation", 4)
	help.add_child(_help_box)
	_refresh_help()

	_refresh_options()
	_play_button.grab_focus()


func _option_row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := UiKit.label(text, 22, UiKit.CREAM, 4)
	label.custom_minimum_size.x = 150
	row.add_child(label)
	return row


func _refresh_help() -> void:
	for child in _help_box.get_children():
		child.queue_free()
	var pad := GameSettings.using_controller
	_help_box.add_child(UiKit.label("HOW TO PLAY" + (" (CONTROLLER)" if pad else ""), 26, UiKit.ORANGE_HOT, 8))
	var lines: Array = (CONTROLLER_HELP if pad else KEYBOARD_HELP) + HOW_TO_PLAY
	for line: String in lines:
		_help_box.add_child(UiKit.label(line, 18, UiKit.CREAM, 4))


func _play(mode: int) -> void:
	GameSettings.match_mode = mode
	GameSettings.save_settings()
	get_tree().change_scene_to_file(MATCH_SCENE)


func _change_bots(step: int) -> void:
	GameSettings.bot_count = clampi(GameSettings.bot_count + step, MIN_BOTS, MAX_BOTS)
	GameSettings.save_settings()  # Remembered even if no match is started.
	_refresh_options()


func _cycle_difficulty() -> void:
	GameSettings.bot_difficulty = (GameSettings.bot_difficulty + 1) % DIFFICULTY_NAMES.size()
	GameSettings.save_settings()
	_refresh_options()


func _toggle_storm() -> void:
	GameSettings.chainstorm_powerup = not GameSettings.chainstorm_powerup
	GameSettings.save_settings()
	_refresh_options()


func _refresh_options() -> void:
	_bots_value.text = str(GameSettings.bot_count)
	_difficulty_button.text = DIFFICULTY_NAMES[clampi(GameSettings.bot_difficulty, 0, DIFFICULTY_NAMES.size() - 1)]
	_storm_button.text = "POWER-UP" if GameSettings.chainstorm_powerup else "EVERYONE"


func _show_settings(shown: bool) -> void:
	_settings.visible = shown
	_menu.visible = not shown
	if shown:
		_settings.focus_default()
	else:
		_play_button.grab_focus()


# --- Your player (customise) ---------------------------------------------------

func _build_customise() -> void:
	_customise = UiKit.panel(UiKit.NAVY, 0.94, 22, 4, UiKit.ORANGE, 24)
	_customise.mouse_filter = Control.MOUSE_FILTER_STOP
	_customise.visible = false
	_ui.add_child(_customise)
	UiKit.pin(_customise, Vector2(0.0, 0.5), Vector2(48, 0), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BOTH)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_customise.add_child(box)
	box.add_child(UiKit.label("YOUR PLAYER", 40, UiKit.ORANGE_HOT, 10))

	box.add_child(UiKit.label("NAME", 20, UiKit.SKY, 4))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	box.add_child(name_row)
	_name_edit = LineEdit.new()
	_name_edit.max_length = Cosmetics.NAME_MAX_LENGTH
	_name_edit.placeholder_text = "You"
	_name_edit.custom_minimum_size = Vector2(300, 48)
	_name_edit.add_theme_font_override("font", UiKit.font())
	_name_edit.add_theme_font_size_override("font_size", 26)
	_name_edit.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.NAVY_DARK, 1.0, 12, 2, UiKit.SKY, 10))
	_name_edit.add_theme_stylebox_override("focus", UiKit.panel_style(UiKit.NAVY_DARK, 0.0, 12, 3, UiKit.CREAM, 10))
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)
	var random := UiKit.small_button("RANDOM", Vector2(130, 48))
	random.pressed.connect(func() -> void:
		_name_edit.text = Cosmetics.random_name()
		_on_name_changed(_name_edit.text))
	name_row.add_child(random)

	box.add_child(UiKit.label("COLOUR", 20, UiKit.SKY, 4))
	var colours := HBoxContainer.new()
	colours.add_theme_constant_override("separation", 8)
	box.add_child(colours)
	for i in Cosmetics.COLORS.size():
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(46, 46)
		swatch.tooltip_text = Cosmetics.COLORS[i]["name"]
		swatch.pressed.connect(_pick_color.bind(i))
		swatch.pressed.connect(func() -> void: Sfx.play(&"ui_click"))
		colours.add_child(swatch)
		_swatches.append(swatch)

	box.add_child(UiKit.label("HAT", 20, UiKit.SKY, 4))
	var hats := GridContainer.new()
	hats.columns = 4
	hats.add_theme_constant_override("h_separation", 8)
	hats.add_theme_constant_override("v_separation", 8)
	box.add_child(hats)
	for hat in Cosmetics.HATS:
		var hat_button := UiKit.small_button(String(hat["name"]).to_upper(), Vector2(120, 44))
		hat_button.pressed.connect(_pick_hat.bind(hat["id"]))
		hats.add_child(hat_button)
		_hat_buttons.append(hat_button)

	var done := UiKit.button("DONE", 26, Vector2(220, 54))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(_show_customise.bind(false))
	box.add_child(done)
	_refresh_customise()


## The 3D "you" that appears beside the customise panel.
func _build_preview() -> void:
	_preview = CharacterModel.new()
	_camera.add_child(_preview)
	_preview.setup(GameSettings.display_name(), GameSettings.color(), GameSettings.player_hat)
	_preview.show_overhead(false)
	_preview.position = Vector3(2.0, -1.55, -5.2)
	_preview.rotation.y = PI
	_preview.visible = false


func _show_customise(shown: bool) -> void:
	_customise.visible = shown
	_preview.visible = shown
	_menu.visible = not shown
	if shown:
		_refresh_customise()
		_swatches[clampi(GameSettings.player_color, 0, _swatches.size() - 1)].grab_focus()
	else:
		GameSettings.save_settings()
		_play_button.grab_focus()


## Keeps the raw text while typing (so spaces work); it's cleaned up when
## saved and wherever the name is shown (Cosmetics.sanitize_name).
func _on_name_changed(text: String) -> void:
	GameSettings.player_name = text.substr(0, Cosmetics.NAME_MAX_LENGTH)


func _pick_color(index: int) -> void:
	GameSettings.player_color = index
	_refresh_customise()
	_rebuild_preview()


func _pick_hat(id: StringName) -> void:
	GameSettings.player_hat = id
	_preview.set_hat(id)
	_refresh_customise()


func _rebuild_preview() -> void:
	var was_visible := _preview.visible
	_preview.queue_free()
	_build_preview()
	_preview.visible = was_visible


func _refresh_customise() -> void:
	if not _name_edit.has_focus() and _name_edit.text != GameSettings.player_name:
		_name_edit.text = GameSettings.player_name
	for i in _swatches.size():
		var tint := Cosmetics.color_at(i)
		var chosen := i == GameSettings.player_color
		_swatches[i].add_theme_stylebox_override("normal", UiKit.panel_style(tint, 1.0, 23, 4 if chosen else 0, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("hover", UiKit.panel_style(tint.lightened(0.2), 1.0, 23, 3, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("pressed", UiKit.panel_style(tint.darkened(0.2), 1.0, 23, 4, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("focus", UiKit.panel_style(tint, 0.0, 23, 4, UiKit.ORANGE_HOT, 0))
	for i in _hat_buttons.size():
		var chosen: bool = Cosmetics.HATS[i]["id"] == GameSettings.player_hat
		var style := UiKit.panel_style(UiKit.ORANGE if chosen else UiKit.BLUE, 1.0, 12, 3 if chosen else 0, UiKit.CREAM, 8)
		_hat_buttons[i].add_theme_stylebox_override("normal", style)
