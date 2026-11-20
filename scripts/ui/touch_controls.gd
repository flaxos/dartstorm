class_name TouchControls
extends Control
## Responsive on-screen mobile touch controls for DARTSTORM.
## Provides an analog VirtualJoystick for movement, right-screen swipe-look aiming,
## and large tactile action buttons for Fire, Jump, Sprint, Aim, Reload, Grenade,
## Weapon Swap, and Pause.

signal pause_requested
signal look_swiped(relative: Vector2)

var player: Player:
	set(value):
		player = value
		if _joystick != null:
			_joystick.action_prefix = player.action_prefix if player != null else ""

var action_prefix: String = ""
var _joystick: VirtualJoystick
var _look_zone: Control
var _look_touch_id: int = -1
var _buttons: Array[Control] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _build_ui() -> void:
	# 1. Look swipe zone (covers the right 60% of the screen)
	_look_zone = Control.new()
	_look_zone.name = "LookSwipeZone"
	_look_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	_look_zone.anchor_left = 0.35
	_look_zone.anchor_right = 1.0
	_look_zone.anchor_top = 0.0
	_look_zone.anchor_bottom = 1.0
	_look_zone.gui_input.connect(_on_look_zone_input)
	add_child(_look_zone)

	# 2. Movement Virtual Joystick (bottom-left)
	_joystick = VirtualJoystick.new()
	_joystick.name = "VirtualJoystick"
	_joystick.action_prefix = action_prefix
	_joystick.anchor_left = 0.0
	_joystick.anchor_top = 1.0
	_joystick.anchor_right = 0.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_left = 40.0
	_joystick.offset_top = -200.0
	_joystick.offset_right = 200.0
	_joystick.offset_bottom = -40.0
	add_child(_joystick)

	# 3. Pause button (top-right corner)
	var pause_btn := _create_touch_button("||", Vector2(54, 54), Color(UiKit.NAVY_DARK, 0.75), UiKit.SKY)
	pause_btn.name = "PauseButton"
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_top = 0.0
	pause_btn.anchor_right = 1.0
	pause_btn.anchor_bottom = 0.0
	pause_btn.offset_left = -74.0
	pause_btn.offset_top = 20.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_bottom = 74.0
	pause_btn.pressed.connect(func() -> void: pause_requested.emit())
	add_child(pause_btn)

	# 4. Action buttons cluster (bottom-right)
	# Primary Fire button (large, prominent)
	var fire_btn := _create_action_button("FIRE", &"fire", Vector2(88, 88), Color(UiKit.ORANGE, 0.9), UiKit.ORANGE_HOT, 24)
	fire_btn.anchor_left = 1.0
	fire_btn.anchor_top = 1.0
	fire_btn.anchor_right = 1.0
	fire_btn.anchor_bottom = 1.0
	fire_btn.offset_left = -140.0
	fire_btn.offset_top = -150.0
	fire_btn.offset_right = -52.0
	fire_btn.offset_bottom = -62.0
	add_child(fire_btn)

	# Jump button
	var jump_btn := _create_action_button("JUMP", &"jump", Vector2(68, 68), Color(UiKit.SKY, 0.85), UiKit.CREAM, 18)
	jump_btn.anchor_left = 1.0
	jump_btn.anchor_top = 1.0
	jump_btn.anchor_right = 1.0
	jump_btn.anchor_bottom = 1.0
	jump_btn.offset_left = -110.0
	jump_btn.offset_top = -240.0
	jump_btn.offset_right = -42.0
	jump_btn.offset_bottom = -172.0
	add_child(jump_btn)

	# ADS / Aim button
	var ads_btn := _create_action_button("AIM", &"aim_down_sights", Vector2(64, 64), Color(UiKit.NAVY_DARK, 0.85), UiKit.ORANGE, 18)
	ads_btn.anchor_left = 1.0
	ads_btn.anchor_top = 1.0
	ads_btn.anchor_right = 1.0
	ads_btn.anchor_bottom = 1.0
	ads_btn.offset_left = -225.0
	ads_btn.offset_top = -145.0
	ads_btn.offset_right = -161.0
	ads_btn.offset_bottom = -81.0
	add_child(ads_btn)

	# Sprint button
	var sprint_btn := _create_action_button("RUN", &"sprint", Vector2(60, 60), Color(UiKit.LIME.darkened(0.2), 0.85), UiKit.LIME, 16)
	sprint_btn.anchor_left = 1.0
	sprint_btn.anchor_top = 1.0
	sprint_btn.anchor_right = 1.0
	sprint_btn.anchor_bottom = 1.0
	sprint_btn.offset_left = -225.0
	sprint_btn.offset_top = -225.0
	sprint_btn.offset_right = -165.0
	sprint_btn.offset_bottom = -165.0
	add_child(sprint_btn)

	# Reload button
	var reload_btn := _create_action_button("RELOAD", &"reload", Vector2(60, 60), Color(UiKit.BLUE, 0.85), UiKit.SKY, 14)
	reload_btn.anchor_left = 1.0
	reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0
	reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -185.0
	reload_btn.offset_top = -305.0
	reload_btn.offset_right = -125.0
	reload_btn.offset_bottom = -245.0
	add_child(reload_btn)

	# Grenade button
	var grenade_btn := _create_action_button("BOMB", &"throw_grenade", Vector2(56, 56), Color(UiKit.PINK, 0.85), UiKit.CREAM, 14)
	grenade_btn.anchor_left = 1.0
	grenade_btn.anchor_top = 1.0
	grenade_btn.anchor_right = 1.0
	grenade_btn.anchor_bottom = 1.0
	grenade_btn.offset_left = -260.0
	grenade_btn.offset_top = -295.0
	grenade_btn.offset_right = -204.0
	grenade_btn.offset_bottom = -239.0
	add_child(grenade_btn)

	# Weapon Swap button
	var swap_btn := _create_touch_button("SWAP", Vector2(64, 52), Color(UiKit.ORANGE_HOT, 0.85), UiKit.CREAM, 16)
	swap_btn.anchor_left = 1.0
	swap_btn.anchor_top = 1.0
	swap_btn.anchor_right = 1.0
	swap_btn.anchor_bottom = 1.0
	swap_btn.offset_left = -110.0
	swap_btn.offset_top = -325.0
	swap_btn.offset_right = -46.0
	swap_btn.offset_bottom = -273.0
	swap_btn.pressed.connect(func() -> void:
		if player != null and player.arsenal != null:
			player.arsenal.cycle(1))
	add_child(swap_btn)


func _on_look_zone_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _look_touch_id == -1:
			_look_touch_id = touch.index
			accept_event()
		elif not touch.pressed and touch.index == _look_touch_id:
			_look_touch_id = -1
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _look_touch_id:
			_handle_look(drag.relative)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _look_touch_id == -1:
				_look_touch_id = -2
				accept_event()
			elif not mb.pressed and _look_touch_id == -2:
				_look_touch_id = -1
				accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _look_touch_id == -2:
			_handle_look(mm.relative)
			accept_event()


func _handle_look(delta: Vector2) -> void:
	if player != null:
		player.look_relative(delta)
	look_swiped.emit(delta)


func _act(base: StringName) -> StringName:
	var prefix := player.action_prefix if player != null else action_prefix
	return StringName(prefix + String(base)) if not prefix.is_empty() else base


func _create_action_button(text: String, action: StringName, btn_size: Vector2,
		bg: Color, border: Color, font_size: int = 16) -> TouchButton:
	var btn := TouchButton.new()
	btn.label_text = text
	btn.btn_size = btn_size
	btn.bg_color = bg
	btn.border_color = border
	btn.font_size = font_size
	btn.action_target = action
	btn.action_resolver = _act
	_buttons.append(btn)
	return btn


func _create_touch_button(text: String, btn_size: Vector2,
		bg: Color, border: Color, font_size: int = 16) -> TouchButton:
	var btn := TouchButton.new()
	btn.label_text = text
	btn.btn_size = btn_size
	btn.bg_color = bg
	btn.border_color = border
	btn.font_size = font_size
	_buttons.append(btn)
	return btn


func reset() -> void:
	_look_touch_id = -1
	if _joystick != null:
		_joystick.reset()
	for btn in _buttons:
		if btn is TouchButton:
			btn.reset()


## Internal tactile touch button component
class TouchButton:
	extends Control

	signal pressed
	signal released

	var label_text: String = ""
	var btn_size: Vector2 = Vector2(64, 64)
	var bg_color: Color = Color(0.1, 0.1, 0.2, 0.8)
	var border_color: Color = Color.WHITE
	var font_size: int = 16
	var action_target: StringName = &""
	var action_resolver: Callable

	var is_pressed: bool = false
	var _touch_id: int = -1


	func _ready() -> void:
		custom_minimum_size = btn_size
		mouse_filter = Control.MOUSE_FILTER_STOP


	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5

		var cur_bg := bg_color
		var cur_border := border_color
		if is_pressed:
			cur_bg = bg_color.lightened(0.25)
			cur_border = border_color.lightened(0.3)

		# Draw circular or rounded rectangle
		if absf(size.x - size.y) < 4.0:
			draw_circle(center, radius, cur_bg)
			draw_arc(center, radius - 2.0, 0, TAU, 32, cur_border, 3.0, true)
		else:
			draw_rect(r, cur_bg, true, -1.0)
			draw_rect(r, cur_border, false, 3.0)

		# Draw text label centered
		var f := UiKit.font()
		var text_sz := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(center.x - text_sz.x * 0.5, center.y + text_sz.y * 0.35)
		draw_string(f, text_pos + Vector2(1, 2), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.6))
		draw_string(f, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, UiKit.CREAM)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed and _touch_id == -1:
				_touch_id = touch.index
				_set_pressed(true)
				accept_event()
			elif not touch.pressed and touch.index == _touch_id:
				_touch_id = -1
				_set_pressed(false)
				accept_event()
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed and _touch_id == -1:
					_touch_id = -2
					_set_pressed(true)
					accept_event()
				elif not mb.pressed and _touch_id == -2:
					_touch_id = -1
					_set_pressed(false)
					accept_event()


	func _set_pressed(value: bool) -> void:
		if is_pressed == value:
			return
		is_pressed = value
		queue_redraw()
		if is_pressed:
			if not action_target.is_empty():
				var act: StringName = action_resolver.call(action_target) if action_resolver.is_valid() else action_target
				if InputMap.has_action(act):
					Input.action_press(act, 1.0)
			pressed.emit()
		else:
			if not action_target.is_empty():
				var act: StringName = action_resolver.call(action_target) if action_resolver.is_valid() else action_target
				if InputMap.has_action(act):
					Input.action_release(act)
			released.emit()


	func reset() -> void:
		_touch_id = -1
		if is_pressed:
			_set_pressed(false)
