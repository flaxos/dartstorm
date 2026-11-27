class_name SettingsPanel
extends PanelContainer
## Settings shared by the main menu and the pause menu. Every control writes
## straight to GameSettings, which saves when the panel is closed.

signal closed

var _box: VBoxContainer
var _done: Button
var _bindings_panel: BindingsPanel


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 24))
	_build()


## Grabs keyboard/gamepad focus so the panel works without a mouse.
func focus_default() -> void:
	if _bindings_panel != null and _bindings_panel.visible:
		_bindings_panel.focus_default()
		return
	if _done != null:
		_done.grab_focus()


func _build() -> void:
	if _box != null:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)
	var title := UiKit.label("SETTINGS", 40, UiKit.ORANGE_HOT, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(980, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_box.add_child(scroll)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	scroll.add_child(columns)
	var controls := _column(columns, "CONTROLS")
	_slider(controls, "Mouse sensitivity", 0.2, 3.0, 0.05, GameSettings.mouse_sensitivity,
			func(value: float) -> void: GameSettings.mouse_sensitivity = value)
	_slider(controls, "Controller look speed", 0.4, 2.0, 0.05, GameSettings.controller_look_speed,
			func(value: float) -> void: GameSettings.controller_look_speed = value)
	_toggle(controls, "Invert look up/down", GameSettings.invert_y,
			func(on: bool) -> void: GameSettings.invert_y = on)
	_toggle(controls, "Controller aim assist", GameSettings.aim_assist,
			func(on: bool) -> void: GameSettings.aim_assist = on)
	_toggle(controls, "Controller rumble", GameSettings.vibration,
			func(on: bool) -> void: GameSettings.vibration = on)
	_slider(controls, "Game speed", 0.70, 1.10, 0.05, GameSettings.game_speed,
			func(value: float) -> void: GameSettings.game_speed = value)
	_touch_picker(controls)
	_touch_fire_mode_picker(controls)
	_touch_btn_size_picker(controls)
	_slider(controls, "Touch look speed", 0.4, 2.5, 0.05, GameSettings.touch_look_sensitivity,
			func(value: float) -> void: GameSettings.touch_look_sensitivity = value)
	var bindings_btn := UiKit.small_button("CUSTOM CONTROLS...", Vector2(240, 42))
	bindings_btn.pressed.connect(_open_bindings)
	controls.add_child(bindings_btn)

	var video := _column(columns, "VIDEO & SOUND")
	_slider(video, "Field of view", 60.0, 110.0, 1.0, GameSettings.fov,
			func(value: float) -> void: GameSettings.fov = value)
	_slider(video, "Camera shake", 0.0, 1.5, 0.05, GameSettings.camera_shake,
			func(value: float) -> void: GameSettings.camera_shake = value)
	_slider(video, "Visual effects", 0.2, 1.5, 0.05, GameSettings.visual_intensity,
			func(value: float) -> void: GameSettings.visual_intensity = value)
	_graphics_quality_picker(video)
	_toggle(video, "Fullscreen", GameSettings.fullscreen,
			func(on: bool) -> void: GameSettings.fullscreen = on)
	_slider(video, "Volume", 0.0, 1.0, 0.05, GameSettings.master_volume,
			func(value: float) -> void: GameSettings.master_volume = value)
	_slider(video, "Music", 0.0, 1.0, 0.05, GameSettings.music_volume,
			func(value: float) -> void: GameSettings.music_volume = value)
	_slider(video, "Sound effects", 0.0, 1.0, 0.05, GameSettings.sfx_volume,
			func(value: float) -> void: GameSettings.sfx_volume = value)
	_palette_picker(video)
	_toggle(video, "Split-screen co-op", GameSettings.split_screen,
			func(on: bool) -> void: GameSettings.split_screen = on)
	_toggle(video, "Split horizontal (top/bottom)", GameSettings.split_screen_horizontal,
			func(on: bool) -> void: GameSettings.split_screen_horizontal = on)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	_box.add_child(buttons)
	var reset := UiKit.small_button("RESET TO DEFAULTS", Vector2(260, 52))
	reset.pressed.connect(_reset)
	buttons.add_child(reset)
	_done = UiKit.button("DONE", 24, Vector2(200, 52))
	_done.pressed.connect(close)
	buttons.add_child(_done)


func _palette_picker(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label("Team Colors", 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)

	var p_idx := [GameSettings.team_palette]
	var current_name: String = GameMode.PALETTE_NAMES[p_idx[0]] if p_idx[0] < GameMode.PALETTE_NAMES.size() else "Default"
	var button := UiKit.small_button(current_name, Vector2(210, 40))
	row.add_child(button)

	var swatch_box := HBoxContainer.new()
	swatch_box.add_theme_constant_override("separation", 6)
	swatch_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch_box)

	var s0 := ColorRect.new()
	s0.custom_minimum_size = Vector2(20, 20)
	s0.color = GameMode.team_color(0)
	swatch_box.add_child(s0)

	var s1 := ColorRect.new()
	s1.custom_minimum_size = Vector2(20, 20)
	s1.color = GameMode.team_color(1)
	swatch_box.add_child(s1)

	button.pressed.connect(func() -> void:
		p_idx[0] = (p_idx[0] + 1) % GameMode.TeamPalette.size()
		GameSettings.team_palette = p_idx[0]
		button.text = GameMode.PALETTE_NAMES[p_idx[0]]
		s0.color = GameMode.team_color(0)
		s1.color = GameMode.team_color(1)
		GameSettings.apply()
		Sfx.play(&"ui_click"))


func _graphics_quality_picker(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label("Graphics Quality", 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)

	var q_idx := [GameSettings.graphics_quality]
	var current_name: String = GameSettings.GRAPHICS_QUALITY_NAMES[clampi(q_idx[0], 0, GameSettings.GRAPHICS_QUALITY_NAMES.size() - 1)]
	var button := UiKit.small_button(current_name, Vector2(210, 40))
	row.add_child(button)

	button.pressed.connect(func() -> void:
		q_idx[0] = (q_idx[0] + 1) % GameSettings.GraphicsQuality.size()
		GameSettings.graphics_quality = q_idx[0]
		button.text = GameSettings.GRAPHICS_QUALITY_NAMES[q_idx[0]]
		GameSettings.apply()
		Sfx.play(&"ui_click"))


func _touch_picker(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label("Touch Controls", 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)

	var modes := ["Auto", "Always On", "Off"]
	var t_idx := [GameSettings.touch_controls_mode]
	var current_name: String = modes[clampi(t_idx[0], 0, modes.size() - 1)]
	var button := UiKit.small_button(current_name, Vector2(210, 40))
	row.add_child(button)

	button.pressed.connect(func() -> void:
		t_idx[0] = (t_idx[0] + 1) % modes.size()
		GameSettings.touch_controls_mode = t_idx[0]
		button.text = modes[t_idx[0]]
		GameSettings.apply()
		Sfx.play(&"ui_click"))


func _touch_fire_mode_picker(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label("Touch Fire Style", 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)

	var modes := ["Aim then Tap", "Hold-to-Aim Auto"]
	var f_idx := [GameSettings.touch_fire_mode]
	var current_name: String = modes[clampi(f_idx[0], 0, modes.size() - 1)]
	var button := UiKit.small_button(current_name, Vector2(210, 40))
	row.add_child(button)

	button.pressed.connect(func() -> void:
		f_idx[0] = (f_idx[0] + 1) % modes.size()
		GameSettings.touch_fire_mode = f_idx[0]
		button.text = modes[f_idx[0]]
		GameSettings.apply()
		Sfx.play(&"ui_click"))


func _touch_btn_size_picker(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label("Fire Button Size", 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)

	var labels := ["Compact (88px)", "Standard (104px)", "Large (120px)"]
	var scales := [0.85, 1.0, 1.15]
	var cur_idx := 1
	if absf(GameSettings.touch_fire_btn_size - 0.85) < 0.05:
		cur_idx = 0
	elif absf(GameSettings.touch_fire_btn_size - 1.15) < 0.05:
		cur_idx = 2
	var s_idx := [cur_idx]
	var button := UiKit.small_button(labels[s_idx[0]], Vector2(210, 40))
	row.add_child(button)

	button.pressed.connect(func() -> void:
		s_idx[0] = (s_idx[0] + 1) % labels.size()
		GameSettings.touch_fire_btn_size = scales[s_idx[0]]
		button.text = labels[s_idx[0]]
		GameSettings.apply()
		Sfx.play(&"ui_click"))


func _open_bindings() -> void:
	if _box != null:
		_box.visible = false
	if _bindings_panel == null:
		_bindings_panel = BindingsPanel.new()
		add_child(_bindings_panel)
		_bindings_panel.closed.connect(_on_bindings_closed)
	_bindings_panel.visible = true
	_bindings_panel.focus_default()


func _on_bindings_closed() -> void:
	if _bindings_panel != null:
		_bindings_panel.visible = false
	if _box != null:
		_box.visible = true
	focus_default()


func _reset() -> void:
	GameSettings.reset_to_defaults()
	GameSettings.apply()
	_build()
	focus_default()


## Saves and leaves the panel (DONE button, or B / Esc).
func close() -> void:
	if _bindings_panel != null and _bindings_panel.visible:
		_bindings_panel.close()
		return
	GameSettings.save_settings()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _bindings_panel != null and _bindings_panel.visible:
		return
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _column(parent: Control, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	column.add_child(UiKit.label(title, 22, UiKit.SKY, 6))
	return column


func _slider(parent: Control, text: String, low: float, high: float, step: float, value: float,
		setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label(text, 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(190, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.add_theme_stylebox_override("slider", UiKit.panel_style(UiKit.NAVY_DARK, 1.0, 6, 1, UiKit.BLUE, 4))
	slider.add_theme_stylebox_override("grabber_area", UiKit.panel_style(UiKit.ORANGE, 1.0, 6, 0, UiKit.ORANGE, 4))
	slider.add_theme_stylebox_override("grabber_area_highlight", UiKit.panel_style(UiKit.ORANGE_HOT, 1.0, 6, 2, UiKit.CREAM, 4))
	row.add_child(slider)
	var value_label := UiKit.label(_format(value, step), 20, UiKit.SKY, 4)
	value_label.custom_minimum_size.x = 64
	row.add_child(value_label)
	slider.value_changed.connect(func(new_value: float) -> void:
		setter.call(new_value)
		value_label.text = _format(new_value, step)
		GameSettings.apply())


func _toggle(parent: Control, text: String, value: bool, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label(text, 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 220
	row.add_child(name_label)
	var button := UiKit.small_button("ON" if value else "OFF", Vector2(110, 40))
	row.add_child(button)
	var state := [value]
	button.pressed.connect(func() -> void:
		state[0] = not state[0]
		button.text = "ON" if state[0] else "OFF"
		setter.call(state[0])
		GameSettings.apply())


func _format(value: float, step: float) -> String:
	return str(int(round(value))) if step >= 1.0 else "%.2f" % value
