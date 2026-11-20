class_name BindingsPanel
extends PanelContainer
## Full remapping UI for keyboard, mouse, and gamepad controls.
## Allows rebinding any gameplay action with live listening and validation.

signal closed

var _box: VBoxContainer
var _rows_box: VBoxContainer
var _back_button: Button

var _listening_action: StringName = &""
var _listening_controller: bool = false
var _listening_button: Button = null

var _action_buttons: Dictionary = {}  # { action: { "kb": Button, "pad": Button } }


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.98, 22, 4, UiKit.ORANGE, 24))
	_build()


func focus_default() -> void:
	if _back_button != null:
		_back_button.grab_focus()


func _build() -> void:
	if _box != null:
		_box.queue_free()
	_action_buttons.clear()

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)

	var title := UiKit.label("CUSTOM CONTROLS & BINDINGS", 32, UiKit.ORANGE_HOT, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)

	var hint := UiKit.label("Click any slot to rebind. Press Esc or Start to cancel.", 18, UiKit.SKY, 4)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(hint)

	# Scroll area for action list
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_box.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows_box)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	_rows_box.add_child(header)

	var h_action := UiKit.label("ACTION", 20, UiKit.ORANGE, 4)
	h_action.custom_minimum_size.x = 220
	header.add_child(h_action)

	var h_kb := UiKit.label("KEY / MOUSE", 20, UiKit.ORANGE, 4)
	h_kb.custom_minimum_size.x = 230
	header.add_child(h_kb)

	var h_pad := UiKit.label("CONTROLLER", 20, UiKit.ORANGE, 4)
	h_pad.custom_minimum_size.x = 230
	header.add_child(h_pad)

	# Action rows
	for item in InputSetup.REBINDABLE_ACTIONS:
		var action: StringName = item["action"]
		var label_text: String = item["label"]
		_add_action_row(action, label_text)

	# Bottom action buttons
	var buttons_row := HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.add_theme_constant_override("separation", 20)
	_box.add_child(buttons_row)

	var reset_btn := UiKit.small_button("RESET TO DEFAULTS", Vector2(240, 48))
	reset_btn.pressed.connect(_reset_bindings)
	buttons_row.add_child(reset_btn)

	_back_button = UiKit.button("BACK", 22, Vector2(180, 48))
	_back_button.pressed.connect(close)
	buttons_row.add_child(_back_button)


func _add_action_row(action: StringName, action_label: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_rows_box.add_child(row)

	var lbl := UiKit.label(action_label, 18, UiKit.CREAM, 4)
	lbl.custom_minimum_size.x = 220
	row.add_child(lbl)

	# Keyboard/Mouse binding button
	var kb_event := InputSetup.get_keyboard_event(action)
	var kb_text := InputSetup.event_to_label(kb_event)
	var kb_btn := UiKit.small_button(kb_text, Vector2(230, 36))
	kb_btn.pressed.connect(_start_listening.bind(action, false, kb_btn))
	row.add_child(kb_btn)

	# Controller binding button
	var pad_event := InputSetup.get_controller_event(action)
	var pad_text := InputSetup.event_to_label(pad_event)
	var pad_btn := UiKit.small_button(pad_text, Vector2(230, 36))
	pad_btn.pressed.connect(_start_listening.bind(action, true, pad_btn))
	row.add_child(pad_btn)

	_action_buttons[action] = {"kb": kb_btn, "pad": pad_btn}


func _start_listening(action: StringName, is_controller: bool, button: Button) -> void:
	if _listening_button != null:
		_cancel_listening()

	_listening_action = action
	_listening_controller = is_controller
	_listening_button = button

	button.text = "[ PRESS KEY/CLICK... ]" if not is_controller else "[ PRESS BUTTON... ]"
	button.modulate = UiKit.ORANGE_HOT
	Sfx.play(&"click")


func _cancel_listening() -> void:
	if _listening_button != null and _listening_action != &"":
		var event := InputSetup.get_controller_event(_listening_action) if _listening_controller else InputSetup.get_keyboard_event(_listening_action)
		_listening_button.text = InputSetup.event_to_label(event)
		_listening_button.modulate = Color.WHITE
	_listening_action = &""
	_listening_controller = false
	_listening_button = null


func _finish_listening() -> void:
	if _listening_button != null and _listening_action != &"":
		var event := InputSetup.get_controller_event(_listening_action) if _listening_controller else InputSetup.get_keyboard_event(_listening_action)
		_listening_button.text = InputSetup.event_to_label(event)
		_listening_button.modulate = Color.WHITE
	_listening_action = &""
	_listening_controller = false
	_listening_button = null


func _refresh_all_buttons() -> void:
	for action: StringName in _action_buttons:
		var pair: Dictionary = _action_buttons[action]
		var kb_btn: Button = pair["kb"]
		var pad_btn: Button = pair["pad"]
		var kb_event := InputSetup.get_keyboard_event(action)
		var pad_event := InputSetup.get_controller_event(action)
		kb_btn.text = InputSetup.event_to_label(kb_event)
		pad_btn.text = InputSetup.event_to_label(pad_event)
		kb_btn.modulate = Color.WHITE
		pad_btn.modulate = Color.WHITE


func _reset_bindings() -> void:
	InputSetup.reset_to_defaults()
	_refresh_all_buttons()
	Sfx.play(&"click")


func close() -> void:
	_cancel_listening()
	GameSettings.save_settings()
	closed.emit()


func _input(event: InputEvent) -> void:
	if _listening_action == &"" or _listening_button == null:
		return

	# Cancel handling
	if event is InputEventKey and event.pressed:
		var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if code == KEY_ESCAPE:
			_cancel_listening()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK:
			_cancel_listening()
			get_viewport().set_input_as_handled()
			return

	# Capture input based on listening target
	if not _listening_controller:
		# Keyboard / Mouse
		if event is InputEventKey and event.pressed:
			InputSetup.rebind_action_event(_listening_action, event, false)
			_finish_listening()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			InputSetup.rebind_action_event(_listening_action, event, false)
			_finish_listening()
			get_viewport().set_input_as_handled()
	else:
		# Controller
		if event is InputEventJoypadButton and event.pressed:
			InputSetup.rebind_action_event(_listening_action, event, true)
			_finish_listening()
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadMotion:
			if (event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT) and event.axis_value > 0.6:
				InputSetup.rebind_action_event(_listening_action, event, true)
				_finish_listening()
				get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action == &"" and is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
