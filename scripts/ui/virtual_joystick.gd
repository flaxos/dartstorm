class_name VirtualJoystick
extends Control
## On-screen analog joystick for mobile touch screens and web browser touch.
## Translates touch drags into analog movement actions (move_left, move_right,
## move_forward, move_back) and emits vector_changed.

signal vector_changed(vector: Vector2)

const BASE_RADIUS := 64.0
const KNOB_RADIUS := 28.0
const DEADZONE := 0.12

var action_prefix: String = ""
var output: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(BASE_RADIUS * 2 + 32, BASE_RADIUS * 2 + 32)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		queue_redraw()


func _draw() -> void:
	var c := _center
	# Outer base
	draw_circle(c, BASE_RADIUS, Color(UiKit.NAVY_DARK.r, UiKit.NAVY_DARK.g, UiKit.NAVY_DARK.b, 0.55))
	draw_arc(c, BASE_RADIUS, 0, TAU, 32, Color(UiKit.SKY.r, UiKit.SKY.g, UiKit.SKY.b, 0.7), 3.0, true)
	draw_arc(c, BASE_RADIUS * DEADZONE, 0, TAU, 16, Color(UiKit.SKY.r, UiKit.SKY.g, UiKit.SKY.b, 0.25), 1.5, true)

	# Inner knob
	var knob_pos := c + _knob_offset
	draw_circle(knob_pos, KNOB_RADIUS, Color(UiKit.ORANGE.r, UiKit.ORANGE.g, UiKit.ORANGE.b, 0.85))
	draw_arc(knob_pos, KNOB_RADIUS, 0, TAU, 24, Color(UiKit.ORANGE_HOT.r, UiKit.ORANGE_HOT.g, UiKit.ORANGE_HOT.b, 0.95), 2.5, true)
	draw_circle(knob_pos, KNOB_RADIUS * 0.35, Color(UiKit.CREAM.r, UiKit.CREAM.g, UiKit.CREAM.b, 0.9))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_id == -1:
			_touch_id = touch.index
			_update_from_pos(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _touch_id:
			_release()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_id:
			_update_from_pos(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _touch_id == -1:
				_touch_id = -2
				_update_from_pos(mb.position)
				accept_event()
			elif not mb.pressed and _touch_id == -2:
				_release()
				accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _touch_id == -2:
			_update_from_pos(mm.position)
			accept_event()


func _update_from_pos(pos: Vector2) -> void:
	var delta := pos - _center
	var dist := delta.length()
	if dist > BASE_RADIUS:
		_knob_offset = delta.normalized() * BASE_RADIUS
	else:
		_knob_offset = delta

	var norm := _knob_offset / BASE_RADIUS
	var length := norm.length()
	if length < DEADZONE:
		output = Vector2.ZERO
	else:
		# Scale smooth between deadzone and 1.0
		var factor := (length - DEADZONE) / (1.0 - DEADZONE)
		output = norm.normalized() * factor

	_apply_input_actions()
	vector_changed.emit(output)
	queue_redraw()


func _release() -> void:
	_touch_id = -1
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	_apply_input_actions()
	vector_changed.emit(output)
	queue_redraw()


func _apply_input_actions() -> void:
	var left_act := _act(&"move_left")
	var right_act := _act(&"move_right")
	var fwd_act := _act(&"move_forward")
	var back_act := _act(&"move_back")

	var x := output.x
	var y := output.y  # In 2D screen space: negative is up (forward), positive is down (back)

	_set_action(left_act, maxf(-x, 0.0))
	_set_action(right_act, maxf(x, 0.0))
	_set_action(fwd_act, maxf(-y, 0.0))
	_set_action(back_act, maxf(y, 0.0))


func _set_action(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength > 0.01:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _act(base: StringName) -> StringName:
	return StringName(action_prefix + String(base)) if not action_prefix.is_empty() else base


func reset() -> void:
	_release()
