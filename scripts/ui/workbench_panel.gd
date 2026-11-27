class_name WorkbenchPanel
extends Control
## Call of Duty Gunsmith-style UI overlay for the Backyard Modding Workbench:
## Allows selecting blasters, viewing Battlefield-style mastery progression,
## inspecting attachment slots, comparing live stat diffs, and equipping mods.

signal closed()
signal blaster_selected(weapon_id: StringName)
signal attachment_changed(slot: WeaponModding.Slot, attachment_id: StringName)
signal slot_focused(slot: WeaponModding.Slot)
signal test_fire_requested()
signal orbit_requested(delta: Vector2)
signal zoom_requested(delta: float)
signal reset_view_requested()

const STAT_MAX_DAMAGE := 60.0
const STAT_MAX_ACCURACY := 10.0 # Lower spread degrees is better accuracy
const STAT_MAX_RANGE := 60.0
const STAT_MAX_RATE := 15.0
const STAT_MAX_CAPACITY := 50.0
const STAT_MAX_MOBILITY := 2.5 # Lower kick is higher mobility

var current_blaster_idx: int = 0
var active_slot: WeaponModding.Slot = WeaponModding.Slot.NONE
var hovered_attachment_id: StringName = &""
var _is_dragging_orbit: bool = false
var _drag_catcher: Control

# UI Node References
var _blaster_name_label: Label
var _blaster_desc_label: Label
var _mastery_title_label: Label
var _mastery_xp_label: Label
var _mastery_bar: ProgressBar
var _tags_label: Label

var _slot_buttons: Dictionary = {} # Slot -> Button
var _drawer_panel: PanelContainer
var _drawer_title: Label
var _drawer_container: HBoxContainer
var _drawer_scroll: ScrollContainer

var _stat_bars: Dictionary = {} # Stat key -> { "fill": ProgressBar, "diff": ProgressBar, "label": Label }


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_drag_catcher()
	_build_ui()
	_refresh_all()


func _build_drag_catcher() -> void:
	_drag_catcher = Control.new()
	_drag_catcher.name = "ViewportDragCatcher"
	_drag_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drag_catcher.mouse_filter = Control.MOUSE_FILTER_PASS
	_drag_catcher.gui_input.connect(_on_drag_catcher_gui_input)
	add_child(_drag_catcher)


func focus_default() -> void:
	if _slot_buttons.has(WeaponModding.Slot.OPTIC):
		var btn: Button = _slot_buttons[WeaponModding.Slot.OPTIC]
		if btn != null:
			btn.grab_focus()


func _on_drag_catcher_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging_orbit = mb.pressed
			if mb.double_click:
				reset_view_requested.emit()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			reset_view_requested.emit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_requested.emit(-0.12)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_requested.emit(0.12)
	elif event is InputEventMouseMotion and _is_dragging_orbit:
		var mm := event as InputEventMouseMotion
		orbit_requested.emit(mm.relative)
	elif event is InputEventScreenDrag and not _is_dragging_orbit:
		var sd := event as InputEventScreenDrag
		orbit_requested.emit(sd.relative)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_is_dragging_orbit = false


func _build_ui() -> void:
	# Top Header Bar
	_build_top_bar()

	# Left Column: Slot Buttons
	_build_slot_column()

	# Right Column: Performance Radar & Stat Diff Bars
	_build_stats_column()

	# Bottom Center: Attachment Drawer
	_build_attachment_drawer()

	# Bottom Action Bar: Controls, Test Fire, Reset, Back
	_build_bottom_bar()


func _build_top_bar() -> void:
	var top_panel := UiKit.panel(UiKit.NAVY_DARK, 0.92, 16, 2, UiKit.BLUE, 12)
	add_child(top_panel)
	UiKit.pin(top_panel, Vector2(0.5, 0.0), Vector2(0.0, 12.0), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	top_panel.custom_minimum_size = Vector2(960, 96)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	top_panel.add_child(hbox)

	# Blaster Switcher Carousel
	var prev_btn := UiKit.small_button("<", Vector2(48, 48))
	prev_btn.pressed.connect(_on_prev_blaster)
	hbox.add_child(prev_btn)

	var blaster_vbox := VBoxContainer.new()
	blaster_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	blaster_vbox.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(blaster_vbox)

	_blaster_name_label = UiKit.label("POCKET POPPER", 26, UiKit.CREAM, 8)
	_blaster_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blaster_vbox.add_child(_blaster_name_label)

	_blaster_desc_label = UiKit.label("Single-shot spring pistol.", 13, UiKit.GREY, 4)
	_blaster_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blaster_vbox.add_child(_blaster_desc_label)

	var next_btn := UiKit.small_button(">", Vector2(48, 48))
	next_btn.pressed.connect(_on_next_blaster)
	hbox.add_child(next_btn)

	var divider := VSeparator.new()
	divider.custom_minimum_size = Vector2(12, 60)
	hbox.add_child(divider)

	# Mastery Progress Center
	var mastery_vbox := VBoxContainer.new()
	mastery_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mastery_vbox.custom_minimum_size = Vector2(400, 0)
	hbox.add_child(mastery_vbox)

	var title_hbox := HBoxContainer.new()
	mastery_vbox.add_child(title_hbox)

	_mastery_title_label = UiKit.label("RANK 1: STOCK ISSUE", 18, UiKit.ORANGE_HOT, 6)
	title_hbox.add_child(_mastery_title_label)

	title_hbox.add_child(Control.new())
	title_hbox.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_mastery_xp_label = UiKit.label("0 / 100 XP", 15, UiKit.SKY, 4)
	title_hbox.add_child(_mastery_xp_label)

	_mastery_bar = ProgressBar.new()
	_mastery_bar.custom_minimum_size = Vector2(380, 12)
	_mastery_bar.show_percentage = false
	_mastery_bar.max_value = 1.0
	_mastery_bar.value = 0.0
	_mastery_bar.add_theme_stylebox_override("background", UiKit.panel_style(UiKit.NAVY, 0.9, 6, 0))
	_mastery_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.ORANGE, 1.0, 6, 0))
	mastery_vbox.add_child(_mastery_bar)

	_tags_label = UiKit.label("Tags: 0  |  XP: 0", 13, UiKit.CREAM, 4)
	mastery_vbox.add_child(_tags_label)


func _build_slot_column() -> void:
	var left_panel := UiKit.panel(UiKit.NAVY_DARK, 0.88, 16, 2, UiKit.NAVY, 12)
	add_child(left_panel)
	UiKit.pin(left_panel, Vector2(0.0, 0.5), Vector2(16.0, 0.0), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BOTH)
	left_panel.custom_minimum_size = Vector2(236, 430)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(vbox)

	var title := UiKit.label("ATTACHMENT SLOTS", 18, UiKit.SKY, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var slots: Array = [
		{"slot": WeaponModding.Slot.OPTIC, "name": "OPTIC / SIGHT"},
		{"slot": WeaponModding.Slot.BARREL, "name": "BARREL / MUZZLE"},
		{"slot": WeaponModding.Slot.SPRING, "name": "SPRING & SEAR"},
		{"slot": WeaponModding.Slot.MAGAZINE, "name": "MAGAZINE / CLIP"},
		{"slot": WeaponModding.Slot.STOCK, "name": "STOCK & GRIP"},
	]

	for item in slots:
		var slot_enum: WeaponModding.Slot = item["slot"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(212, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_override("font", UiKit.font())
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", UiKit.CREAM)
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.NAVY, 0.9, 12, 1, UiKit.BLUE, 8))
		btn.add_theme_stylebox_override("hover", UiKit.panel_style(UiKit.BLUE, 0.95, 12, 2, UiKit.SKY, 8))
		btn.add_theme_stylebox_override("pressed", UiKit.panel_style(UiKit.ORANGE, 1.0, 12, 2, UiKit.CREAM, 8))
		btn.pressed.connect(func() -> void: _select_slot(slot_enum))

		vbox.add_child(btn)
		_slot_buttons[slot_enum] = btn


func _build_stats_column() -> void:
	var right_panel := UiKit.panel(UiKit.NAVY_DARK, 0.88, 16, 2, UiKit.NAVY, 12)
	add_child(right_panel)
	UiKit.pin(right_panel, Vector2(1.0, 0.5), Vector2(-16.0, 0.0), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BOTH)
	right_panel.custom_minimum_size = Vector2(268, 430)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	right_panel.add_child(vbox)

	var title := UiKit.label("PERFORMANCE RADAR", 18, UiKit.ORANGE, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var stat_keys := [
		{"key": "power", "name": "TAG POWER", "color": UiKit.ORANGE_HOT},
		{"key": "accuracy", "name": "ACCURACY", "color": UiKit.LIME},
		{"key": "range", "name": "RANGE / VELOCITY", "color": UiKit.SKY},
		{"key": "rate", "name": "FIRE RATE", "color": UiKit.PINK},
		{"key": "capacity", "name": "MAG CAPACITY", "color": UiKit.CREAM},
		{"key": "mobility", "name": "MOBILITY / CONTROL", "color": Color(0.9, 0.8, 0.3)},
	]

	for item in stat_keys:
		var stat_vbox := VBoxContainer.new()
		vbox.add_child(stat_vbox)

		var header := HBoxContainer.new()
		stat_vbox.add_child(header)

		var stat_label := UiKit.label(item["name"], 13, UiKit.CREAM, 4)
		header.add_child(stat_label)

		header.add_child(Control.new())
		header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var val_label := UiKit.label("0", 13, item["color"], 4)
		header.add_child(val_label)

		# Layered progress bar for live diff comparison
		var bar_container := Control.new()
		bar_container.custom_minimum_size = Vector2(244, 13)
		stat_vbox.add_child(bar_container)

		var base_bar := ProgressBar.new()
		base_bar.show_percentage = false
		base_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		base_bar.add_theme_stylebox_override("background", UiKit.panel_style(UiKit.NAVY_DARK.darkened(0.5), 0.9, 6, 0))
		base_bar.add_theme_stylebox_override("fill", UiKit.panel_style(item["color"].darkened(0.15), 1.0, 6, 0))
		bar_container.add_child(base_bar)

		var diff_bar := ProgressBar.new()
		diff_bar.show_percentage = false
		diff_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		diff_bar.add_theme_stylebox_override("background", UiKit.panel_style(Color.TRANSPARENT, 0.0, 6, 0))
		diff_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.LIME, 0.85, 6, 0))
		bar_container.add_child(diff_bar)

		_stat_bars[item["key"]] = {
			"base": base_bar,
			"diff": diff_bar,
			"label": val_label,
			"color": item["color"],
		}


func _build_attachment_drawer() -> void:
	_drawer_panel = UiKit.panel(UiKit.NAVY_DARK, 0.95, 18, 2, UiKit.ORANGE, 12)
	add_child(_drawer_panel)
	UiKit.pin(_drawer_panel, Vector2(0.5, 1.0), Vector2(0.0, -76.0), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	_drawer_panel.custom_minimum_size = Vector2(680, 198)
	_drawer_panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_drawer_panel.add_child(vbox)

	var title_bar := HBoxContainer.new()
	vbox.add_child(title_bar)

	_drawer_title = UiKit.label("SELECT ATTACHMENT", 18, UiKit.ORANGE_HOT, 6)
	title_bar.add_child(_drawer_title)

	title_bar.add_child(Control.new())
	title_bar.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var close_drawer_btn := UiKit.small_button("X", Vector2(34, 30))
	close_drawer_btn.pressed.connect(func() -> void: _close_drawer())
	title_bar.add_child(close_drawer_btn)

	_drawer_scroll = ScrollContainer.new()
	_drawer_scroll.custom_minimum_size = Vector2(656, 138)
	_drawer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_drawer_scroll.follow_focus = true
	vbox.add_child(_drawer_scroll)

	_drawer_container = HBoxContainer.new()
	_drawer_container.add_theme_constant_override("separation", 12)
	_drawer_scroll.add_child(_drawer_container)


func _build_bottom_bar() -> void:
	var bottom_panel := UiKit.panel(UiKit.NAVY_DARK, 0.90, 16, 2, UiKit.NAVY, 10)
	add_child(bottom_panel)
	UiKit.pin(bottom_panel, Vector2(0.5, 1.0), Vector2(0.0, -12.0), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	bottom_panel.custom_minimum_size = Vector2(960, 56)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	bottom_panel.add_child(hbox)

	var back_btn := UiKit.small_button("< BACK TO MENU", Vector2(170, 40))
	back_btn.pressed.connect(func() -> void: closed.emit())
	hbox.add_child(back_btn)

	var reset_btn := UiKit.small_button("RESET TO STOCK", Vector2(160, 40))
	reset_btn.pressed.connect(_on_reset_to_stock)
	hbox.add_child(reset_btn)

	var test_btn := UiKit.button("TEST FIRE [T]", 19, Vector2(200, 42))
	test_btn.pressed.connect(func() -> void: test_fire_requested.emit())
	hbox.add_child(test_btn)

	var hint_label := UiKit.label("Left Drag: Orbit  |  Scroll: Zoom  |  Double-Click: Reset", 13, UiKit.GREY, 4)
	hbox.add_child(hint_label)


# ==============================================================================
# SELECTION & PROGRESSION LOGIC
# ==============================================================================

func _get_current_blaster_info() -> Dictionary:
	return WeaponModding.WORKBENCH_BLASTERS[current_blaster_idx]


func _on_prev_blaster() -> void:
	current_blaster_idx = posmod(current_blaster_idx - 1, WeaponModding.WORKBENCH_BLASTERS.size())
	_close_drawer()
	_refresh_all()
	blaster_selected.emit(_get_current_blaster_info()["id"])


func _on_next_blaster() -> void:
	current_blaster_idx = posmod(current_blaster_idx + 1, WeaponModding.WORKBENCH_BLASTERS.size())
	_close_drawer()
	_refresh_all()
	blaster_selected.emit(_get_current_blaster_info()["id"])


func _select_slot(slot: WeaponModding.Slot) -> void:
	active_slot = slot
	slot_focused.emit(slot)
	_open_drawer(slot)


func _close_drawer() -> void:
	active_slot = WeaponModding.Slot.NONE
	_drawer_panel.visible = false
	hovered_attachment_id = &""
	slot_focused.emit(WeaponModding.Slot.NONE)
	_refresh_stats()


func _open_drawer(slot: WeaponModding.Slot) -> void:
	_drawer_panel.visible = true
	var slot_name: String = WeaponModding.slot_name(slot)
	_drawer_title.text = "SELECT %s" % slot_name.to_upper()

	# Clear previous cards
	for child in _drawer_container.get_children():
		child.queue_free()

	var w_info := _get_current_blaster_info()
	var w_id: StringName = w_info["id"]
	var mastery := Progression.get_weapon_mastery(w_id) if is_instance_valid(Progression) else {"rank": 1}
	var weapon_rank: int = int(mastery.get("rank", 1))

	var equipped_atts := Progression.get_equipped_attachments(w_id) if is_instance_valid(Progression) else {}
	var slot_key: StringName = WeaponModding.slot_string(slot)
	var currently_equipped: StringName = equipped_atts.get(slot_key, &"")

	var available := WeaponModding.get_attachments_for_slot(slot)
	for att in available:
		var att_id: StringName = att["id"]
		var req_rank: int = int(att.get("rank", 1))
		var is_unlocked := weapon_rank >= req_rank
		var is_equipped := (currently_equipped == att_id)

		var card := _build_attachment_card(att, is_unlocked, is_equipped)
		_drawer_container.add_child(card)


func _build_attachment_card(att: Dictionary, is_unlocked: bool, is_equipped: bool) -> Control:
	var att_id: StringName = att["id"]
	var panel := UiKit.panel(UiKit.NAVY if not is_equipped else UiKit.BLUE, 0.92, 14, 2, UiKit.ORANGE if is_equipped else UiKit.NAVY_DARK, 8)
	panel.custom_minimum_size = Vector2(216, 130)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var name_label := UiKit.label(att["name"], 15, UiKit.CREAM if is_unlocked else UiKit.GREY, 4)
	header.add_child(name_label)

	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var rank_label := UiKit.label("R%d" % int(att.get("rank", 1)), 13, UiKit.ORANGE_HOT if is_unlocked else UiKit.GREY, 4)
	header.add_child(rank_label)

	var desc_label := UiKit.label(att.get("desc", ""), 11, UiKit.GREY, 3)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Pros & Cons
	var pros: Array = att.get("pros", [])
	if not pros.is_empty():
		var pro_text := "+ %s" % str(pros[0])
		var pro_label := UiKit.label(pro_text, 11, UiKit.LIME, 3)
		vbox.add_child(pro_label)

	# Action Button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 30)
	btn.add_theme_font_override("font", UiKit.font())
	btn.add_theme_font_size_override("font_size", 13)

	if is_equipped:
		btn.text = "EQUIPPED"
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.ORANGE, 0.9, 8, 0))
	elif not is_unlocked:
		btn.text = "LOCKED (RANK %d)" % int(att.get("rank", 1))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.NAVY_DARK, 0.8, 8, 0))
	else:
		btn.text = "EQUIP"
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.BLUE, 1.0, 8, 0))
		btn.add_theme_stylebox_override("hover", UiKit.panel_style(UiKit.SKY, 1.0, 8, 2, UiKit.CREAM))
		btn.add_theme_stylebox_override("focus", UiKit.panel_style(UiKit.SKY, 1.0, 8, 3, UiKit.CREAM))
		btn.pressed.connect(func() -> void: _equip_attachment(att_id))

	# Mouse hover AND controller/keyboard focus trigger live stat diff comparison!
	var on_enter := func() -> void:
		hovered_attachment_id = att_id
		_refresh_stats()
	var on_exit := func() -> void:
		if hovered_attachment_id == att_id:
			hovered_attachment_id = &""
			_refresh_stats()
	panel.mouse_entered.connect(on_enter)
	panel.mouse_exited.connect(on_exit)
	btn.focus_entered.connect(on_enter)
	btn.focus_exited.connect(on_exit)

	vbox.add_child(btn)
	return panel


func _equip_attachment(att_id: StringName) -> void:
	var w_info := _get_current_blaster_info()
	var w_id: StringName = w_info["id"]
	var slot_key: StringName = WeaponModding.slot_string(active_slot)

	if is_instance_valid(Progression):
		Progression.equip_attachment(w_id, slot_key, att_id)

	Sfx.play(&"swap")
	attachment_changed.emit(active_slot, att_id)
	_refresh_all()
	_open_drawer(active_slot)


func _on_reset_to_stock() -> void:
	var w_info := _get_current_blaster_info()
	var w_id: StringName = w_info["id"]
	if is_instance_valid(Progression):
		for slot in [WeaponModding.Slot.OPTIC, WeaponModding.Slot.BARREL, WeaponModding.Slot.SPRING, WeaponModding.Slot.MAGAZINE, WeaponModding.Slot.STOCK]:
			var default_att: StringName = WeaponModding.get_default_attachment_for_slot(slot)
			Progression.equip_attachment(w_id, WeaponModding.slot_string(slot), default_att)

	Sfx.play(&"swap")
	attachment_changed.emit(WeaponModding.Slot.NONE, &"")
	_refresh_all()
	if active_slot != WeaponModding.Slot.NONE:
		_open_drawer(active_slot)


func _refresh_all() -> void:
	var w_info := _get_current_blaster_info()
	var w_id: StringName = w_info["id"]

	_blaster_name_label.text = w_info["name"].to_upper()
	_blaster_desc_label.text = w_info.get("desc", "")

	# Refresh Mastery Info
	var mastery := Progression.get_weapon_mastery(w_id) if is_instance_valid(Progression) else {"xp": 0, "tags": 0, "rank": 1}
	var xp: int = int(mastery.get("xp", 0))
	var tags: int = int(mastery.get("tags", 0))
	var progress := WeaponModding.get_mastery_progress(xp)

	var rank: int = int(progress["rank"])
	var title: String = str(progress["title"])
	_mastery_title_label.text = "RANK %d: %s" % [rank, title.to_upper()]
	_mastery_bar.value = float(progress["ratio"])
	if bool(progress["is_max"]):
		_mastery_xp_label.text = "MAX RANK (GOLD MASTER)"
	else:
		_mastery_xp_label.text = "%d / %d XP" % [int(progress["current_xp"]), int(progress["needed_xp"])]

	_tags_label.text = "Tags: %d  |  XP: %d" % [tags, xp]

	# Refresh Slot Buttons text
	var equipped_atts := Progression.get_equipped_attachments(w_id) if is_instance_valid(Progression) else {}
	for slot_enum in _slot_buttons:
		var slot_key: StringName = WeaponModding.slot_string(slot_enum)
		var att_id: StringName = equipped_atts.get(slot_key, &"")
		var att_def: Dictionary = WeaponModding.find_attachment(att_id)
		var btn: Button = _slot_buttons[slot_enum]
		var slot_name: String = WeaponModding.slot_name(slot_enum)
		var att_name: String = String(att_def.get("name", "Factory Stock"))
		btn.text = "%s\n  > %s" % [slot_name.to_upper(), att_name]

	# Refresh Performance Stat Bars
	_refresh_stats()


func _refresh_stats() -> void:
	var w_info := _get_current_blaster_info()
	var res_path: String = w_info["res_path"]
	var data: WeaponData = load(res_path) as WeaponData if ResourceLoader.exists(res_path) else null
	if data == null:
		return

	var w_id: StringName = w_info["id"]
	var current_equipped := Progression.get_equipped_attachments(w_id) if is_instance_valid(Progression) else {}
	var current_mods := WeaponModding.compute_attachment_modifiers(current_equipped)

	# Compute preview modifiers if hovering over an attachment in the drawer
	var preview_mods := current_mods
	if not hovered_attachment_id.is_empty() and active_slot != WeaponModding.Slot.NONE:
		var preview_equipped := current_equipped.duplicate()
		preview_equipped[WeaponModding.slot_string(active_slot)] = hovered_attachment_id
		preview_mods = WeaponModding.compute_attachment_modifiers(preview_equipped)

	# 1. TAG POWER
	var base_dmg := (data.dart.tag_power if data.dart != null else 10.0) * float(current_mods.get("tag_power_mult", 1.0))
	var prev_dmg := (data.dart.tag_power if data.dart != null else 10.0) * float(preview_mods.get("tag_power_mult", 1.0))
	_update_stat_bar("power", base_dmg, prev_dmg, STAT_MAX_DAMAGE, "%.1f" % prev_dmg)

	# 2. ACCURACY (Spread)
	var base_acc := clampf(STAT_MAX_ACCURACY - (data.spread_degrees * float(current_mods.get("spread_mult", 1.0))), 0.5, STAT_MAX_ACCURACY)
	var prev_acc := clampf(STAT_MAX_ACCURACY - (data.spread_degrees * float(preview_mods.get("spread_mult", 1.0))), 0.5, STAT_MAX_ACCURACY)
	_update_stat_bar("accuracy", base_acc, prev_acc, STAT_MAX_ACCURACY, "%.1f°" % (data.spread_degrees * float(preview_mods.get("spread_mult", 1.0))))

	# 3. RANGE / VELOCITY
	var base_rng := (data.dart.initial_speed if data.dart != null else 25.0) * float(current_mods.get("velocity_mult", 1.0))
	var prev_rng := (data.dart.initial_speed if data.dart != null else 25.0) * float(preview_mods.get("velocity_mult", 1.0))
	_update_stat_bar("range", base_rng, prev_rng, STAT_MAX_RANGE, "%d m/s" % int(prev_rng))

	# 4. FIRE RATE
	var base_rate := data.shots_per_second * float(current_mods.get("rate_mult", 1.0))
	var prev_rate := data.shots_per_second * float(preview_mods.get("rate_mult", 1.0))
	_update_stat_bar("rate", base_rate, prev_rate, STAT_MAX_RATE, "%.1f/s" % prev_rate)

	# 5. CAPACITY
	var base_cap := float(data.magazine_size + int(current_mods.get("mag_bonus", 0)))
	var prev_cap := float(data.magazine_size + int(preview_mods.get("mag_bonus", 0)))
	_update_stat_bar("capacity", base_cap, prev_cap, STAT_MAX_CAPACITY, "%d Darts" % int(prev_cap))

	# 6. MOBILITY / RECOIL CONTROL
	var base_mob := clampf(STAT_MAX_MOBILITY - (data.recoil_kick * float(current_mods.get("recoil_mult", 1.0))), 0.1, STAT_MAX_MOBILITY)
	var prev_mob := clampf(STAT_MAX_MOBILITY - (data.recoil_kick * float(preview_mods.get("recoil_mult", 1.0))), 0.1, STAT_MAX_MOBILITY)
	_update_stat_bar("mobility", base_mob, prev_mob, STAT_MAX_MOBILITY, "%.2f" % prev_mob)


func _update_stat_bar(key: String, curr_val: float, prev_val: float, max_val: float, text: String) -> void:
	if not _stat_bars.has(key):
		return
	var item: Dictionary = _stat_bars[key]
	var base_bar: ProgressBar = item["base"]
	var diff_bar: ProgressBar = item["diff"]
	var val_label: Label = item["label"]

	val_label.text = text
	base_bar.max_value = max_val
	diff_bar.max_value = max_val

	base_bar.value = curr_val
	diff_bar.value = prev_val

	if prev_val > curr_val:
		# Positive buff (Green)
		diff_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.LIME, 0.9, 6, 0))
	elif prev_val < curr_val:
		# Penalty reduction (Orange/Red)
		diff_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.ORANGE_HOT, 0.9, 6, 0))
	else:
		diff_bar.add_theme_stylebox_override("fill", UiKit.panel_style(Color.TRANSPARENT, 0.0, 6, 0))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_T) \
			or (event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_Y):
		test_fire_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		if active_slot != WeaponModding.Slot.NONE:
			_close_drawer()
			focus_default()
			get_viewport().set_input_as_handled()
