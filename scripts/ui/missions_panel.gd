class_name MissionsPanel
extends PanelContainer
## Backyard Missions modal: displays the player's 3 active kid-safe objectives,
## progress bars, rewards (XP and Coins), and updates live as missions progress.

signal closed

var _box: VBoxContainer
var _cards_box: VBoxContainer
var _done: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 24))
	_build()
	if Engine.has_singleton("Progression") or get_node_or_null("/root/Progression") != null:
		var prog: Node = get_node("/root/Progression")
		prog.connect("mission_progress", func(_id: Variant, _cur: Variant, _tgt: Variant) -> void: _refresh())
		prog.connect("mission_completed", func(_m: Variant) -> void: _refresh())


func focus_default() -> void:
	if _done != null:
		_done.grab_focus()


func _build() -> void:
	if _box != null:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	add_child(_box)

	var title := UiKit.label("BACKYARD MISSIONS", 38, UiKit.ORANGE_HOT, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)

	var subtitle := UiKit.label("Complete fun objectives in the yard to earn Coins and XP!", 18, UiKit.SKY, 4)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(subtitle)

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 10)
	_cards_box.custom_minimum_size = Vector2(560, 260)
	_box.add_child(_cards_box)

	_refresh()

	var footer := UiKit.label("Fresh missions roll in right away when you finish one!", 16, UiKit.CREAM, 4)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(footer)

	_done = UiKit.button("DONE", 26, Vector2(220, 52))
	_done.name = "MissionsDone"
	_done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_done.pressed.connect(func() -> void: closed.emit())
	_box.add_child(_done)


func _refresh() -> void:
	if _cards_box == null:
		return
	for child in _cards_box.get_children():
		child.queue_free()

	var prog: Node = get_node_or_null("/root/Progression")
	var missions: Array = []
	if prog != null:
		missions = prog.get("active_missions")

	if missions.is_empty():
		var empty_lbl := UiKit.label("All caught up! Check back after your next match.", 20, UiKit.CREAM, 4)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cards_box.add_child(empty_lbl)
		return

	for m in missions:
		if m is Dictionary:
			_cards_box.add_child(_create_mission_card(m))


func _create_mission_card(mission: Dictionary) -> PanelContainer:
	var card := UiKit.panel(UiKit.NAVY_DARK, 0.92, 14, 2, UiKit.BLUE, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var icon_lbl := UiKit.label(str(mission.get("icon", "🎯")), 32, UiKit.CREAM, 4)
	icon_lbl.custom_minimum_size = Vector2(40, 40)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(icon_lbl)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 2)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)

	var title_text: String = str(mission.get("title", "MISSION"))
	details.add_child(UiKit.label(title_text, 20, UiKit.CREAM, 5))

	var desc_text: String = str(mission.get("description", ""))
	details.add_child(UiKit.label(desc_text, 16, UiKit.SKY, 4))

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	details.add_child(progress_row)

	var bar := UiKit.bar(UiKit.ORANGE, Vector2(240, 14))
	var target := maxi(int(mission.get("target", 1)), 1)
	var current := clampi(int(mission.get("progress", 0)), 0, target)
	bar.value = float(current) / float(target)
	progress_row.add_child(bar)

	var count_text := "%d / %d" % [current, target]
	var count_lbl := UiKit.label(count_text, 16, UiKit.ORANGE_HOT, 4)
	progress_row.add_child(count_lbl)

	var rewards := VBoxContainer.new()
	rewards.add_theme_constant_override("separation", 2)
	rewards.custom_minimum_size = Vector2(120, 40)
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(rewards)

	var coin_text := "🪙 +%d" % int(mission.get("coin_reward", 100))
	var coins_lbl := UiKit.label(coin_text, 18, UiKit.ORANGE_HOT, 4)
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rewards.add_child(coins_lbl)

	var xp_text := "⭐ +%d XP" % int(mission.get("xp_reward", 200))
	var xp_lbl := UiKit.label(xp_text, 16, UiKit.LIME, 4)
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rewards.add_child(xp_lbl)

	return card
