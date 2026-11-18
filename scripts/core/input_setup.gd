class_name InputSetup
extends RefCounted
## Registers the game's input actions in code so the bindings live in one readable
## table (see docs/DECISIONS.md, D-004). Actions already defined in Project Settings
## are left alone, so any of them can still be overridden from the editor.
##
## Controllers are plug and play: every binding uses device -1 ("any device"),
## so a pad plugged in mid-game works at once. Godot's built-in UI actions have
## no controller buttons for accept/cancel by default, so A and B are added here,
## which makes every menu usable with a pad.

## Look sticks get a small deadzone so fine aiming still registers.
const LOOK_DEADZONE := 0.12
const DEFAULT_DEADZONE := 0.3


static func ensure_actions() -> void:
	_add(&"move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add(&"move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add(&"jump", [_key(KEY_SPACE), _pad(JOY_BUTTON_A)])
	_add(&"sprint", [_key(KEY_SHIFT), _pad(JOY_BUTTON_LEFT_STICK), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add(&"fire", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add(&"aim_down_sights", [_mouse(MOUSE_BUTTON_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add(&"throw_grenade", [_key(KEY_G), _mouse(MOUSE_BUTTON_MIDDLE), _pad(JOY_BUTTON_DPAD_DOWN)])
	_add(&"reload", [_key(KEY_R), _pad(JOY_BUTTON_X)])
	_add(&"weapon_1", [_key(KEY_1)])
	_add(&"weapon_2", [_key(KEY_2)])
	_add(&"weapon_3", [_key(KEY_3)])
	_add(&"weapon_next", [_mouse(MOUSE_BUTTON_WHEEL_DOWN), _key(KEY_E), _pad(JOY_BUTTON_RIGHT_SHOULDER), _pad(JOY_BUTTON_Y)])
	_add(&"weapon_prev", [_mouse(MOUSE_BUTTON_WHEEL_UP), _key(KEY_Q), _pad(JOY_BUTTON_LEFT_SHOULDER)])
	_add(&"pause", [_key(KEY_ESCAPE), _key(KEY_P), _pad(JOY_BUTTON_START)])
	_add(&"scoreboard", [_key(KEY_TAB), _pad(JOY_BUTTON_BACK)])
	_add(&"look_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)], LOOK_DEADZONE)
	_add(&"look_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)], LOOK_DEADZONE)
	_add(&"look_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)], LOOK_DEADZONE)
	_add(&"look_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)], LOOK_DEADZONE)
	# Menus: A presses the focused button, B goes back.
	_extend(&"ui_accept", [_pad(JOY_BUTTON_A)])
	_extend(&"ui_cancel", [_pad(JOY_BUTTON_B)])


static func _add(action: StringName, events: Array, deadzone: float = DEFAULT_DEADZONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, deadzone)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


## Adds events to an action that already exists (Godot's built-in ui_* actions).
static func _extend(action: StringName, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEFAULT_DEADZONE)
	for event: InputEvent in events:
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


static func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	return event


static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	return event
