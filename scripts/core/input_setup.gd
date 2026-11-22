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

const REBINDABLE_ACTIONS: Array[Dictionary] = [
	{"action": &"move_forward", "label": "Move Forward"},
	{"action": &"move_back", "label": "Move Backward"},
	{"action": &"move_left", "label": "Strafe Left"},
	{"action": &"move_right", "label": "Strafe Right"},
	{"action": &"jump", "label": "Jump"},
	{"action": &"sprint", "label": "Sprint"},
	{"action": &"fire", "label": "Fire Blaster"},
	{"action": &"aim_down_sights", "label": "Aim Down Sights"},
	{"action": &"throw_grenade", "label": "Throw Grenade"},
	{"action": &"ping", "label": "Tactical Ping"},
	{"action": &"reload", "label": "Reload"},
	{"action": &"interact", "label": "Interact / Objective"},
	{"action": &"weapon_next", "label": "Next Blaster"},
	{"action": &"weapon_prev", "label": "Previous Blaster"},
	{"action": &"scoreboard", "label": "Scoreboard"},
]


static func ensure_actions() -> void:
	_add(&"move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add(&"move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add(&"jump", [_key(KEY_SPACE), _pad(JOY_BUTTON_A)])
	_add(&"sprint", [_key(KEY_SHIFT), _pad(JOY_BUTTON_LEFT_STICK), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add(&"fire", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add(&"aim_down_sights", [_mouse(MOUSE_BUTTON_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add(&"throw_grenade", [_key(KEY_G), _pad(JOY_BUTTON_DPAD_DOWN)])
	_add(&"ping", [_key(KEY_T), _mouse(MOUSE_BUTTON_MIDDLE), _pad(JOY_BUTTON_DPAD_UP)])
	_add(&"reload", [_key(KEY_R), _pad(JOY_BUTTON_X)])
	_add(&"interact", [_key(KEY_F), _key(KEY_E), _pad(JOY_BUTTON_X)])
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


static func get_keyboard_event(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return event
	return null


static func get_controller_event(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null


static func rebind_action_event(action: StringName, new_event: InputEvent, is_controller: bool) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEFAULT_DEADZONE)
	var to_remove: Array[InputEvent] = []
	for event in InputMap.action_get_events(action):
		if is_controller:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				to_remove.append(event)
		else:
			if event is InputEventKey or event is InputEventMouseButton:
				to_remove.append(event)
	for event in to_remove:
		InputMap.action_erase_event(action, event)
	if new_event != null:
		InputMap.action_add_event(action, new_event)


static func event_to_label(event: InputEvent) -> String:
	if event == null:
		return "-"
	if event is InputEventKey:
		var k: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		match k:
			KEY_SPACE: return "Space"
			KEY_SHIFT: return "Shift"
			KEY_CTRL: return "Ctrl"
			KEY_ALT: return "Alt"
			KEY_TAB: return "Tab"
			KEY_ESCAPE: return "Esc"
			KEY_ENTER: return "Enter"
			KEY_UP: return "Up Arrow"
			KEY_DOWN: return "Down Arrow"
			KEY_LEFT: return "Left Arrow"
			KEY_RIGHT: return "Right Arrow"
			_: return OS.get_keycode_string(k)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse %d" % event.button_index
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_A: return "A / Cross"
			JOY_BUTTON_B: return "B / Circle"
			JOY_BUTTON_X: return "X / Square"
			JOY_BUTTON_Y: return "Y / Triangle"
			JOY_BUTTON_BACK: return "Back / View"
			JOY_BUTTON_START: return "Start / Menu"
			JOY_BUTTON_LEFT_STICK: return "L3 (Left Stick)"
			JOY_BUTTON_RIGHT_STICK: return "R3 (Right Stick)"
			JOY_BUTTON_LEFT_SHOULDER: return "LB (Left Bumper)"
			JOY_BUTTON_RIGHT_SHOULDER: return "RB (Right Bumper)"
			JOY_BUTTON_DPAD_UP: return "D-Pad Up"
			JOY_BUTTON_DPAD_DOWN: return "D-Pad Down"
			JOY_BUTTON_DPAD_LEFT: return "D-Pad Left"
			JOY_BUTTON_DPAD_RIGHT: return "D-Pad Right"
			_: return "Button %d" % event.button_index
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_TRIGGER_LEFT: return "LT (Left Trigger)"
			JOY_AXIS_TRIGGER_RIGHT: return "RT (Right Trigger)"
			JOY_AXIS_LEFT_X: return "L-Stick Right" if event.axis_value > 0.0 else "L-Stick Left"
			JOY_AXIS_LEFT_Y: return "L-Stick Down" if event.axis_value > 0.0 else "L-Stick Up"
			JOY_AXIS_RIGHT_X: return "R-Stick Right" if event.axis_value > 0.0 else "R-Stick Left"
			JOY_AXIS_RIGHT_Y: return "R-Stick Down" if event.axis_value > 0.0 else "R-Stick Up"
			_: return "Axis %d" % event.axis
	return event.as_text()


static func serialize_bindings() -> Dictionary:
	var out: Dictionary = {}
	for item in REBINDABLE_ACTIONS:
		var action: StringName = item["action"]
		var kb := get_keyboard_event(action)
		var pad := get_controller_event(action)
		var entry: Dictionary = {}
		if kb is InputEventKey:
			var code: int = int(kb.physical_keycode if kb.physical_keycode != KEY_NONE else kb.keycode)
			entry["kb"] = {"type": "key", "code": code}
		elif kb is InputEventMouseButton:
			entry["kb"] = {"type": "mouse", "button": int(kb.button_index)}
		if pad is InputEventJoypadButton:
			entry["pad"] = {"type": "button", "index": int(pad.button_index)}
		elif pad is InputEventJoypadMotion:
			entry["pad"] = {"type": "axis", "axis": int(pad.axis), "value": float(pad.axis_value)}
		out[String(action)] = entry
	return out


static func apply_serialized_bindings(data: Dictionary) -> void:
	for action_str: String in data:
		var action := StringName(action_str)
		if not InputMap.has_action(action):
			continue
		var val: Variant = data[action_str]
		if not val is Dictionary:
			continue
		var entry: Dictionary = val
		if entry.has("kb") and entry["kb"] is Dictionary:
			var kb_data: Dictionary = entry["kb"]
			var kb_type: String = str(kb_data.get("type", ""))
			if kb_type == "key":
				rebind_action_event(action, _key(kb_data.get("code", 0)), false)
			elif kb_type == "mouse":
				rebind_action_event(action, _mouse(kb_data.get("button", 0)), false)
		if entry.has("pad") and entry["pad"] is Dictionary:
			var pad_data: Dictionary = entry["pad"]
			var pad_type: String = str(pad_data.get("type", ""))
			if pad_type == "button":
				rebind_action_event(action, _pad(pad_data.get("index", 0)), true)
			elif pad_type == "axis":
				rebind_action_event(action, _axis(pad_data.get("axis", 0), float(pad_data.get("value", 1.0))), true)


static func reset_to_defaults() -> void:
	for item in REBINDABLE_ACTIONS:
		var action: StringName = item["action"]
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	ensure_actions()


## Configures dedicated p1_* and p2_* input actions for 2-player split-screen.
static func setup_split_screen_actions(p1_is_pad: bool = false, p2_device: int = 0) -> void:
	clear_split_screen_actions()

	var pads := Input.get_connected_joypads()
	if pads.size() >= 2:
		p1_is_pad = true
		p2_device = 1
	elif pads.size() == 1:
		p1_is_pad = false
		p2_device = 0

	var core_actions := [
		&"move_forward", &"move_back", &"move_left", &"move_right",
		&"jump", &"sprint", &"fire", &"aim_down_sights", &"throw_grenade",
		&"ping", &"reload", &"weapon_1", &"weapon_2", &"weapon_3",
		&"weapon_next", &"weapon_prev", &"scoreboard",
		&"look_left", &"look_right", &"look_up", &"look_down"
	]

	# Build Player 1 actions (p1_*)
	for act in core_actions:
		var p1_act := StringName("p1_" + String(act))
		var deadzone := LOOK_DEADZONE if act.begins_with(&"look_") else DEFAULT_DEADZONE
		InputMap.add_action(p1_act, deadzone)

		# Add keyboard & mouse events from base action
		if InputMap.has_action(act):
			for event in InputMap.action_get_events(act):
				if event is InputEventKey or event is InputEventMouseButton:
					InputMap.action_add_event(p1_act, event.duplicate())
				elif p1_is_pad and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
					var pad_event: InputEvent = event.duplicate()
					pad_event.device = 0
					InputMap.action_add_event(p1_act, pad_event)

	# Build Player 2 actions (p2_*)
	for act in core_actions:
		var p2_act := StringName("p2_" + String(act))
		var deadzone := LOOK_DEADZONE if act.begins_with(&"look_") else DEFAULT_DEADZONE
		InputMap.add_action(p2_act, deadzone)

		# Add gamepad events mapped to p2_device
		if InputMap.has_action(act):
			for event in InputMap.action_get_events(act):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					var pad_event: InputEvent = event.duplicate()
					pad_event.device = p2_device
					InputMap.action_add_event(p2_act, pad_event)

	# Add testing fallback keyboard bindings for Player 2
	_add_event(&"p2_move_forward", _key(KEY_UP))
	_add_event(&"p2_move_back", _key(KEY_DOWN))
	_add_event(&"p2_move_left", _key(KEY_LEFT))
	_add_event(&"p2_move_right", _key(KEY_RIGHT))
	_add_event(&"p2_jump", _key(KEY_KP_0))
	_add_event(&"p2_fire", _key(KEY_KP_ENTER))
	_add_event(&"p2_aim_down_sights", _key(KEY_KP_PERIOD))
	_add_event(&"p2_reload", _key(KEY_KP_1))
	_add_event(&"p2_throw_grenade", _key(KEY_KP_2))
	_add_event(&"p2_ping", _key(KEY_KP_3))
	_add_event(&"p2_weapon_next", _key(KEY_KP_ADD))
	_add_event(&"p2_weapon_prev", _key(KEY_KP_SUBTRACT))
	_add_event(&"p2_sprint", _key(KEY_KP_5))
	_add_event(&"p2_scoreboard", _key(KEY_KP_7))
	_add_event(&"p2_look_left", _key(KEY_J))
	_add_event(&"p2_look_right", _key(KEY_L))
	_add_event(&"p2_look_up", _key(KEY_I))
	_add_event(&"p2_look_down", _key(KEY_K))


static func _add_event(action: StringName, event: InputEvent) -> void:
	if InputMap.has_action(action) and not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


## Erases any split-screen p1_* and p2_* actions from InputMap.
static func clear_split_screen_actions() -> void:
	for action in InputMap.get_actions():
		if action.begins_with(&"p1_") or action.begins_with(&"p2_"):
			InputMap.erase_action(action)


