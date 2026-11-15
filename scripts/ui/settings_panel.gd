class_name SettingsPanel
extends PanelContainer
## Settings shared by the main menu and the pause menu. Every control writes
## straight to GameSettings, which saves when the panel is closed.

signal closed


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 24))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := UiKit.label("SETTINGS", 40, UiKit.ORANGE_HOT, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_slider(box, "Mouse sensitivity", 0.2, 3.0, 0.05, GameSettings.mouse_sensitivity,
			func(value: float) -> void: GameSettings.mouse_sensitivity = value)
	_slider(box, "Field of view", 60.0, 110.0, 1.0, GameSettings.fov,
			func(value: float) -> void: GameSettings.fov = value)
	_slider(box, "Camera shake", 0.0, 1.5, 0.05, GameSettings.camera_shake,
			func(value: float) -> void: GameSettings.camera_shake = value)
	_slider(box, "Visual effects", 0.2, 1.5, 0.05, GameSettings.visual_intensity,
			func(value: float) -> void: GameSettings.visual_intensity = value)
	_slider(box, "Volume", 0.0, 1.0, 0.05, GameSettings.master_volume,
			func(value: float) -> void: GameSettings.master_volume = value)
	_toggle(box, "Fullscreen", GameSettings.fullscreen,
			func(on: bool) -> void: GameSettings.fullscreen = on)
	_toggle(box, "Invert look up/down", GameSettings.invert_y,
			func(on: bool) -> void: GameSettings.invert_y = on)

	var done := UiKit.button("DONE", 24, Vector2(220, 52))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(_close)
	box.add_child(done)


func _close() -> void:
	GameSettings.save_settings()
	closed.emit()


func _slider(parent: Control, text: String, low: float, high: float, step: float, value: float,
		setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var name_label := UiKit.label(text, 20, UiKit.CREAM, 4)
	name_label.custom_minimum_size.x = 250
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(260, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	name_label.custom_minimum_size.x = 250
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
