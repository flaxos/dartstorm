class_name PauseMenu
extends CanvasLayer
## Pause screen. Press Esc/P (or Start on a gamepad) to open and close it.

signal restart_requested
signal menu_requested

var _controller: MatchController
var _dim: ColorRect
var _menu: PanelContainer
var _settings: SettingsPanel
var _resume: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	_dim = ColorRect.new()
	_dim.color = Color(UiKit.NAVY_DARK, 0.65)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_menu = UiKit.panel(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 28)
	_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.add_child(_menu)
	UiKit.pin(_menu, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_menu.add_child(box)
	var title := UiKit.label("PAUSED", 56, UiKit.ORANGE_HOT, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_resume = UiKit.button("RESUME")
	_resume.pressed.connect(close)
	box.add_child(_resume)
	var restart := UiKit.button("RESTART MATCH")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)
	var settings := UiKit.button("SETTINGS")
	settings.pressed.connect(_show_settings.bind(true))
	box.add_child(settings)
	var quit := UiKit.small_button("MAIN MENU", Vector2(300, 50))
	quit.pressed.connect(func() -> void: menu_requested.emit())
	box.add_child(quit)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_dim.add_child(_settings)
	UiKit.pin(_settings, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_settings.closed.connect(_show_settings.bind(false))

	_dim.visible = false


func setup(controller: MatchController) -> void:
	_controller = controller
	GameSettings.controller_changed.connect(_on_controller_changed)


## Unplugging a controller mid-match pauses, like on a console.
func _on_controller_changed(_device: int, connected: bool, _pad_name: String) -> void:
	if not connected:
		pause_for_focus_loss()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pause_for_focus_loss()


## Alt-tab, the Windows key or a pop-up stealing focus pauses the match, so
## nobody gets tagged while they're away and the mouse is safely released.
func pause_for_focus_loss() -> void:
	if _dim == null or _dim.visible or _controller == null:
		return
	if _controller.state != MatchController.State.COUNTDOWN and _controller.state != MatchController.State.PLAYING:
		return
	if OS.get_cmdline_user_args().has("--demo"):
		return  # Unattended demo/screenshot runs shouldn't stop if focus wanders.
	open()


func is_open() -> bool:
	return _dim != null and _dim.visible


func _unhandled_input(event: InputEvent) -> void:
	# B / Esc-style "back": leave settings first, then resume.
	if _dim.visible and event.is_action_pressed(&"ui_cancel") and not event.is_action_pressed(&"pause"):
		if _settings.visible:
			_settings.close()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"pause"):
		return
	if _controller != null and _controller.state == MatchController.State.ENDED:
		return
	if _dim.visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_dim.visible = true
	_show_settings(false)
	get_tree().paused = true
	Sfx.set_spin(0.0)
	Sfx.duck_music(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume.grab_focus()


func close() -> void:
	GameSettings.save_settings()
	_dim.visible = false
	get_tree().paused = false
	Sfx.duck_music(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_settings(shown: bool) -> void:
	_settings.visible = shown
	_menu.visible = not shown
	if shown:
		_settings.focus_default()
	elif _dim.visible:
		_resume.grab_focus()
