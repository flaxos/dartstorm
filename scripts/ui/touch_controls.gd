class_name TouchControls
extends Control
## Responsive on-screen mobile touch controls for DARTSTORM.
## Provides an analog VirtualJoystick for movement, right-screen swipe-look aiming,
## and large tactile action buttons for Fire, Jump, Sprint, Aim, Reload, Grenade,
## Weapon Swap, Pause, and an instant Touch Fire Mode toggle.
##
## Supports two distinct mobile control paradigms:
## 1. HOLD_AND_AIM (Unified): Hold fire button to auto-fire while dragging to steer aim.
## 2. AIM_AND_TAP (Classic): Look swipe zone handles aiming, tap button fires.

signal pause_requested
signal look_swiped(relative: Vector2)
signal fire_mode_changed(mode: int)

var player: Player:
	set(value):
		player = value
		if _joystick != null:
			_joystick.action_prefix = player.action_prefix if player != null else ""
		if _fire_btn != null:
			_fire_btn.player = player

var action_prefix: String = ""
var _joystick: VirtualJoystick
var _look_zone: Control
var _look_touch_id: int = -1
var _buttons: Array[Control] = []
var _fire_btn: SmartFireButton
var _mode_toggle: TouchButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	refresh_fire_mode()
	GameSettings.changed.connect(refresh_fire_mode)


func _build_ui() -> void:
	# 1. Look swipe zone (covers the right 65% of the screen)
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

	# 4. Quick Touch Fire Mode Toggle Pill (top-right, adjacent to Pause)
	_mode_toggle = _create_touch_button("🎯 HOLD AIM", Vector2(136, 48), Color(UiKit.NAVY_DARK, 0.88), UiKit.ORANGE, 13)
	_mode_toggle.name = "FireModeToggle"
	_mode_toggle.anchor_left = 1.0
	_mode_toggle.anchor_top = 0.0
	_mode_toggle.anchor_right = 1.0
	_mode_toggle.anchor_bottom = 0.0
	_mode_toggle.offset_left = -220.0
	_mode_toggle.offset_top = 23.0
	_mode_toggle.offset_right = -84.0
	_mode_toggle.offset_bottom = 71.0
	_mode_toggle.pressed.connect(_on_toggle_fire_mode)
	add_child(_mode_toggle)

	# 5. Smart Fire Button (large, tactile, dynamic hold & drag aim)
	_fire_btn = SmartFireButton.new()
	_fire_btn.name = "SmartFireButton"
	_fire_btn.action_target = &"fire"
	_fire_btn.action_resolver = _act
	_fire_btn.player = player
	_fire_btn.look_callback = _handle_look
	_fire_btn.anchor_left = 1.0
	_fire_btn.anchor_top = 1.0
	_fire_btn.anchor_right = 1.0
	_fire_btn.anchor_bottom = 1.0
	_buttons.append(_fire_btn)
	add_child(_fire_btn)

	# 6. Action buttons cluster arranged in an ergonomic radial arc around Fire
	# Jump button (above fire button)
	var jump_btn := _create_action_button("JUMP", &"jump", Vector2(68, 68), Color(UiKit.SKY, 0.85), UiKit.CREAM, 18)
	jump_btn.anchor_left = 1.0
	jump_btn.anchor_top = 1.0
	jump_btn.anchor_right = 1.0
	jump_btn.anchor_bottom = 1.0
	jump_btn.offset_left = -118.0
	jump_btn.offset_top = -258.0
	jump_btn.offset_right = -50.0
	jump_btn.offset_bottom = -190.0
	add_child(jump_btn)

	# ADS / Aim button (left of fire button)
	var ads_btn := _create_action_button("AIM", &"aim_down_sights", Vector2(64, 64), Color(UiKit.NAVY_DARK, 0.85), UiKit.ORANGE, 18)
	ads_btn.anchor_left = 1.0
	ads_btn.anchor_top = 1.0
	ads_btn.anchor_right = 1.0
	ads_btn.anchor_bottom = 1.0
	ads_btn.offset_left = -242.0
	ads_btn.offset_top = -152.0
	ads_btn.offset_right = -178.0
	ads_btn.offset_bottom = -88.0
	add_child(ads_btn)

	# Sprint button (upper-left of fire button)
	var sprint_btn := _create_action_button("RUN", &"sprint", Vector2(60, 60), Color(UiKit.LIME.darkened(0.2), 0.85), UiKit.LIME, 16)
	sprint_btn.anchor_left = 1.0
	sprint_btn.anchor_top = 1.0
	sprint_btn.anchor_right = 1.0
	sprint_btn.anchor_bottom = 1.0
	sprint_btn.offset_left = -240.0
	sprint_btn.offset_top = -236.0
	sprint_btn.offset_right = -180.0
	sprint_btn.offset_bottom = -176.0
	add_child(sprint_btn)

	# Reload button (diagonal above-left of fire button)
	var reload_btn := _create_action_button("RELOAD", &"reload", Vector2(60, 60), Color(UiKit.BLUE, 0.85), UiKit.SKY, 14)
	reload_btn.anchor_left = 1.0
	reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0
	reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -192.0
	reload_btn.offset_top = -312.0
	reload_btn.offset_right = -132.0
	reload_btn.offset_bottom = -252.0
	add_child(reload_btn)

	# Grenade button (outer perimeter)
	var grenade_btn := _create_action_button("BOMB", &"throw_grenade", Vector2(56, 56), Color(UiKit.PINK, 0.85), UiKit.CREAM, 14)
	grenade_btn.anchor_left = 1.0
	grenade_btn.anchor_top = 1.0
	grenade_btn.anchor_right = 1.0
	grenade_btn.anchor_bottom = 1.0
	grenade_btn.offset_left = -272.0
	grenade_btn.offset_top = -306.0
	grenade_btn.offset_right = -216.0
	grenade_btn.offset_bottom = -250.0
	add_child(grenade_btn)

	# Weapon Swap button (upper column)
	var swap_btn := _create_touch_button("SWAP", Vector2(64, 52), Color(UiKit.ORANGE_HOT, 0.85), UiKit.CREAM, 16)
	swap_btn.anchor_left = 1.0
	swap_btn.anchor_top = 1.0
	swap_btn.anchor_right = 1.0
	swap_btn.anchor_bottom = 1.0
	swap_btn.offset_left = -118.0
	swap_btn.offset_top = -336.0
	swap_btn.offset_right = -54.0
	swap_btn.offset_bottom = -284.0
	swap_btn.pressed.connect(func() -> void:
		if player != null and player.arsenal != null:
			player.arsenal.cycle(1))
	add_child(swap_btn)


## Updates button sizes, labels, and behavior based on GameSettings.
func refresh_fire_mode() -> void:
	var mode: int = GameSettings.touch_fire_mode
	var scale_mult: float = GameSettings.touch_fire_btn_size
	if _mode_toggle != null:
		if mode == GameSettings.TouchFireMode.HOLD_AND_AIM:
			_mode_toggle.label_text = "🎯 HOLD AIM"
			_mode_toggle.border_color = UiKit.ORANGE
		else:
			_mode_toggle.label_text = "👆 TAP FIRE"
			_mode_toggle.border_color = UiKit.SKY
		_mode_toggle.queue_redraw()

	if _fire_btn != null:
		_fire_btn.fire_mode = mode
		var btn_dim: float = (108.0 if mode == GameSettings.TouchFireMode.HOLD_AND_AIM else 88.0) * scale_mult
		_fire_btn.btn_size = Vector2(btn_dim, btn_dim)
		_fire_btn.custom_minimum_size = Vector2(btn_dim, btn_dim)
		_fire_btn.offset_left = -(btn_dim + 44.0)
		_fire_btn.offset_top = -(btn_dim + 52.0)
		_fire_btn.offset_right = -44.0
		_fire_btn.offset_bottom = -52.0
		_fire_btn.queue_redraw()


func _on_toggle_fire_mode() -> void:
	var next_mode: int = 1 - GameSettings.touch_fire_mode
	GameSettings.touch_fire_mode = next_mode
	GameSettings.save_settings()
	refresh_fire_mode()
	fire_mode_changed.emit(next_mode)
	Sfx.play(&"click")
	var msg: String = "Touch Mode: Hold-to-Aim Auto-Fire" if next_mode == GameSettings.TouchFireMode.HOLD_AND_AIM else "Touch Mode: Aim then Tap Fire"
	GameSettings.notify(msg)


func _on_look_zone_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _look_touch_id == -1:
			_look_touch_id = touch.index
			accept_event()
		elif (not touch.pressed or touch.canceled) and touch.index == _look_touch_id:
			_look_touch_id = -1
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _look_touch_id:
			_handle_look(drag.relative)
			accept_event()


func _input(event: InputEvent) -> void:
	if _look_touch_id == -1:
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _look_touch_id:
			_handle_look(drag.relative)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == _look_touch_id and (not touch.pressed or touch.canceled):
			_look_touch_id = -1
			get_viewport().set_input_as_handled()


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
			elif (not touch.pressed or touch.canceled) and touch.index == _touch_id:
				_touch_id = -1
				_set_pressed(false)
				accept_event()
		elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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


	func _input(event: InputEvent) -> void:
		if _touch_id == -1:
			return
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.index == _touch_id and (not touch.pressed or touch.canceled):
				_touch_id = -1
				_set_pressed(false)
				get_viewport().set_input_as_handled()
		elif _touch_id == -2 and event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				_touch_id = -1
				_set_pressed(false)
				get_viewport().set_input_as_handled()


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


## Smart primary Fire button with dual-mode Hold-to-Aim Auto-Fire and Aim-then-Tap.
class SmartFireButton:
	extends TouchButton

	var fire_mode: int = GameSettings.TouchFireMode.HOLD_AND_AIM
	var look_callback: Callable
	var player: Player

	var reticle_offset: Vector2 = Vector2.ZERO
	var _pulse_timer: float = 0.0


	func _ready() -> void:
		super._ready()
		custom_minimum_size = btn_size
		mouse_filter = Control.MOUSE_FILTER_STOP


	func _process(delta: float) -> void:
		_pulse_timer += delta * 6.0
		if is_pressed:
			# Auto-cycle semi-auto blasters while button is held
			if player != null and player.alive and player.controls_enabled and player.arsenal != null:
				var w := player.arsenal.current()
				if w != null and w.data.fire_mode == WeaponData.FireMode.SEMI and not player.is_tagged_out:
					if player.arsenal._cooldown <= 0.0 and player.arsenal._semi_latched:
						player.arsenal._semi_latched = false
			# Smoothly return reticle knob toward center after drag
			if reticle_offset.length_squared() > 0.01:
				reticle_offset = reticle_offset.move_toward(Vector2.ZERO, delta * 35.0)
			queue_redraw()


	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		var is_unified := (fire_mode == GameSettings.TouchFireMode.HOLD_AND_AIM)

		# 1. Outer animated glow / pulse ring while firing
		if is_pressed:
			var pulse := (sin(_pulse_timer) + 1.0) * 0.5
			var glow_r := radius + 4.0 + pulse * 6.0
			draw_circle(center, glow_r, Color(UiKit.ORANGE_HOT.r, UiKit.ORANGE_HOT.g, UiKit.ORANGE_HOT.b, 0.25 * pulse))
			draw_arc(center, radius + 2.0, 0, TAU, 32, UiKit.ORANGE_HOT, 4.0, true)
		else:
			draw_arc(center, radius - 2.0, 0, TAU, 32, UiKit.ORANGE if is_unified else UiKit.ORANGE.lightened(0.1), 3.0, true)

		# 2. Main tactile disc
		var base_bg := Color(0.08, 0.11, 0.18, 0.88)
		if is_pressed:
			base_bg = Color(UiKit.ORANGE.r * 0.5, UiKit.ORANGE.g * 0.25, 0.05, 0.92)
		draw_circle(center, radius - 3.0, base_bg)

		# Concentric target ring
		draw_arc(center, radius * 0.58, 0, TAU, 24, Color(UiKit.ORANGE.r, UiKit.ORANGE.g, UiKit.ORANGE.b, 0.35), 1.5, true)

		# 3. Dynamic aiming reticle knob
		var knob_center := center + reticle_offset
		var knob_r := radius * 0.28
		var knob_col := UiKit.ORANGE_HOT if is_pressed else UiKit.ORANGE
		draw_circle(knob_center, knob_r, Color(knob_col.r, knob_col.g, knob_col.b, 0.7))
		draw_arc(knob_center, knob_r, 0, TAU, 16, UiKit.CREAM, 2.0, true)
		draw_circle(knob_center, 3.0, Color.YELLOW)

		# Crosshair crosslines on reticle
		var cross_len := 12.0
		draw_line(knob_center - Vector2(cross_len, 0), knob_center - Vector2(4, 0), UiKit.CREAM, 2.0)
		draw_line(knob_center + Vector2(4, 0), knob_center + Vector2(cross_len, 0), UiKit.CREAM, 2.0)
		draw_line(knob_center - Vector2(0, cross_len), knob_center - Vector2(0, 4), UiKit.CREAM, 2.0)
		draw_line(knob_center + Vector2(0, 4), knob_center + Vector2(0, cross_len), UiKit.CREAM, 2.0)

		# 4. Text label
		var f := UiKit.font()
		var label_str: String = "FIRE & AIM" if is_unified else "FIRE"
		var font_sz: int = 15 if is_unified else 18
		var text_sz := f.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
		var text_pos := Vector2(center.x - text_sz.x * 0.5, center.y + radius * 0.72)
		draw_string(f, text_pos + Vector2(1, 1), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, Color(0, 0, 0, 0.8))
		draw_string(f, text_pos, label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, UiKit.CREAM)


	func _set_pressed(value: bool) -> void:
		super._set_pressed(value)
		if not value:
			reticle_offset = Vector2.ZERO
		else:
			_pulse_timer = 0.0
		queue_redraw()


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed and _touch_id == -1:
				_touch_id = touch.index
				_set_pressed(true)
				accept_event()
			elif (not touch.pressed or touch.canceled) and touch.index == _touch_id:
				_touch_id = -1
				_set_pressed(false)
				accept_event()
		elif event is InputEventScreenDrag:
			var drag := event as InputEventScreenDrag
			if drag.index == _touch_id:
				_handle_drag(drag.relative)
				accept_event()
		elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
		elif event is InputEventMouseMotion and _touch_id == -2:
			var mm := event as InputEventMouseMotion
			_handle_drag(mm.relative)
			accept_event()


	func _input(event: InputEvent) -> void:
		if _touch_id == -1:
			return
		if event is InputEventScreenDrag:
			var drag := event as InputEventScreenDrag
			if drag.index == _touch_id:
				_handle_drag(drag.relative)
				get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.index == _touch_id and (not touch.pressed or touch.canceled):
				_touch_id = -1
				_set_pressed(false)
				get_viewport().set_input_as_handled()
		elif _touch_id == -2:
			if event is InputEventMouseMotion:
				var mm := event as InputEventMouseMotion
				if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
					_handle_drag(mm.relative)
					get_viewport().set_input_as_handled()
			elif event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
					_touch_id = -1
					_set_pressed(false)
					get_viewport().set_input_as_handled()


	func _handle_drag(relative: Vector2) -> void:
		if fire_mode == GameSettings.TouchFireMode.HOLD_AND_AIM:
			if look_callback.is_valid():
				look_callback.call(relative)
			var max_disp := minf(size.x, size.y) * 0.35
			reticle_offset = (reticle_offset + relative * 0.22).limit_length(max_disp)
			queue_redraw()
