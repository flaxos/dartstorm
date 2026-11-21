class_name ShopPanel
extends PanelContainer
## Kid-Safe Coin Shop modal (D-028):
## Strictly zero microtransactions, zero real money, zero gems, zero timers.
## Purely cosmetic (hats and colour swatches). All items are earned through play.

signal closed
signal item_equipped(category: StringName, id: Variant)

enum Tab { HATS, COLORS, SKINS }

var _box: VBoxContainer
var _coin_label: Label
var _hats_tab_btn: Button
var _colors_tab_btn: Button
var _skins_tab_btn: Button
var _grid_container: GridContainer
var _done_btn: Button
var _current_tab: Tab = Tab.HATS


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 24))
	_build()
	if Engine.has_singleton("Progression") or get_node_or_null("/root/Progression") != null:
		var prog: Node = get_node("/root/Progression")
		prog.connect("coins_changed", func(_c: Variant) -> void: _refresh_header())
		prog.connect("item_unlocked", func(_cat: Variant, _id: Variant) -> void: _refresh_catalog())


func focus_default() -> void:
	if _done_btn != null:
		_done_btn.grab_focus()


func _build() -> void:
	if _box != null:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)

	# Top header bar: Title and Coin Balance
	var header_bar := HBoxContainer.new()
	header_bar.add_theme_constant_override("separation", 20)
	_box.add_child(header_bar)

	var title := UiKit.label("COIN SHOP", 38, UiKit.ORANGE_HOT, 10)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(title)

	var coin_box := UiKit.panel(UiKit.NAVY_DARK, 0.9, 12, 2, UiKit.ORANGE, 6)
	header_bar.add_child(coin_box)
	_coin_label = UiKit.label("", 24, UiKit.ORANGE_HOT, 6)
	coin_box.add_child(_coin_label)
	_refresh_header()

	var subtitle := UiKit.label("100% Kid-Safe! No real money, no gems, no timers. Earn coins by playing!", 16, UiKit.SKY, 4)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(subtitle)

	# Tab bar: Hats / Colours / Skins
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 12)
	_box.add_child(tab_row)

	_hats_tab_btn = UiKit.small_button("HATS", Vector2(140, 44))
	_hats_tab_btn.pressed.connect(_switch_tab.bind(Tab.HATS))
	tab_row.add_child(_hats_tab_btn)

	_colors_tab_btn = UiKit.small_button("COLOURS", Vector2(140, 44))
	_colors_tab_btn.pressed.connect(_switch_tab.bind(Tab.COLORS))
	tab_row.add_child(_colors_tab_btn)

	_skins_tab_btn = UiKit.small_button("SKINS", Vector2(140, 44))
	_skins_tab_btn.pressed.connect(_switch_tab.bind(Tab.SKINS))
	tab_row.add_child(_skins_tab_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)

	_grid_container = GridContainer.new()
	_grid_container.columns = 3
	_grid_container.add_theme_constant_override("h_separation", 12)
	_grid_container.add_theme_constant_override("v_separation", 12)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid_container)

	var btm_row := HBoxContainer.new()
	btm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btm_row.add_theme_constant_override("separation", 16)
	_box.add_child(btm_row)

	var boss_btn := UiKit.button("👑 BOSS MODE: UNLOCK ALL", 22, Vector2(320, 52))
	boss_btn.name = "ShopBossMode"
	boss_btn.pressed.connect(func() -> void:
		var prog: Node = get_node_or_null("/root/Progression")
		if prog != null and prog.has_method("activate_boss_mode"):
			prog.call("activate_boss_mode")
			GameSettings.notify("👑 BOSS MODE! 99,999 Coins & All Items Unlocked!")
			_refresh_header()
			_refresh_catalog())
	btm_row.add_child(boss_btn)

	_done_btn = UiKit.button("DONE", 26, Vector2(180, 52))
	_done_btn.name = "ShopDone"
	_done_btn.pressed.connect(func() -> void: closed.emit())
	btm_row.add_child(_done_btn)

	_switch_tab(Tab.HATS)


func _refresh_header() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	var coin_val := 0
	if prog != null:
		coin_val = int(prog.get("coins"))
	if _coin_label != null:
		_coin_label.text = "🪙 %d COINS" % coin_val


func _switch_tab(tab: Tab) -> void:
	_current_tab = tab
	if _hats_tab_btn != null and _colors_tab_btn != null and _skins_tab_btn != null:
		var hats_active := tab == Tab.HATS
		var colors_active := tab == Tab.COLORS
		var skins_active := tab == Tab.SKINS
		_hats_tab_btn.add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if hats_active else UiKit.BLUE, 1.0, 12, 3 if hats_active else 0, UiKit.CREAM, 8))
		_colors_tab_btn.add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if colors_active else UiKit.BLUE, 1.0, 12, 3 if colors_active else 0, UiKit.CREAM, 8))
		_skins_tab_btn.add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if skins_active else UiKit.BLUE, 1.0, 12, 3 if skins_active else 0, UiKit.CREAM, 8))
	_refresh_catalog()


func _refresh_catalog() -> void:
	if _grid_container == null:
		return
	for child in _grid_container.get_children():
		child.queue_free()

	match _current_tab:
		Tab.HATS:
			_build_hats_catalog()
		Tab.COLORS:
			_build_colors_catalog()
		Tab.SKINS:
			_build_skins_catalog()


func _build_hats_catalog() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	for hat in Cosmetics.HATS:
		var id: StringName = hat["id"]
		var hat_name: String = hat["name"]
		var cost: int = int(hat.get("cost", 0))
		var tier: String = str(hat.get("tier", "Starter"))

		var is_unlocked: bool = false
		if prog != null:
			is_unlocked = bool(prog.call("is_unlocked", &"hat", id))
		else:
			is_unlocked = Cosmetics.is_default_hat(id)

		var is_equipped: bool = GameSettings.player_hat == id
		_grid_container.add_child(_create_hat_card(id, hat_name, tier, cost, is_unlocked, is_equipped))


func _create_hat_card(id: StringName, hat_name: String, tier: String, cost: int, unlocked: bool, equipped: bool) -> PanelContainer:
	var card := UiKit.panel(UiKit.NAVY_DARK, 0.92, 14, 2, UiKit.SKY if equipped else UiKit.BLUE, 10)
	card.custom_minimum_size = Vector2(200, 140)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var name_lbl := UiKit.label(hat_name.to_upper(), 18, UiKit.CREAM, 5)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var tier_lbl := UiKit.label(tier, 14, UiKit.SKY, 3)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_lbl)

	var prog: Node = get_node_or_null("/root/Progression")
	var can_afford: bool = prog != null and bool(prog.call("can_afford", cost))

	var btn: Button
	if equipped:
		btn = UiKit.small_button("EQUIPPED", Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.LIME.darkened(0.3), 0.9, 10, 2, UiKit.LIME, 6))
	elif unlocked:
		btn = UiKit.small_button("EQUIP", Vector2(160, 36))
		btn.pressed.connect(func() -> void:
			GameSettings.player_hat = id
			GameSettings.save_settings()
			item_equipped.emit(&"hat", id)
			_refresh_catalog())
	elif can_afford:
		btn = UiKit.small_button("BUY 🪙 %d" % cost, Vector2(160, 36))
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.ORANGE, 1.0, 10, 0, UiKit.ORANGE, 6))
		btn.pressed.connect(func() -> void:
			if prog != null and bool(prog.call("spend_coins", cost)):
				prog.call("unlock_item", &"hat", id)
				GameSettings.player_hat = id
				GameSettings.save_settings()
				if has_node("/root/Sfx"):
					(get_node("/root/Sfx") as Node).call("play", &"pickup")
				item_equipped.emit(&"hat", id)
				_refresh_header()
				_refresh_catalog())
	else:
		btn = UiKit.small_button("NEED 🪙 %d" % cost, Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.GREY.darkened(0.4), 0.8, 10, 0, UiKit.GREY, 6))

	vbox.add_child(btn)
	return card


func _build_colors_catalog() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	for i in Cosmetics.COLORS.size():
		var col_info: Dictionary = Cosmetics.COLORS[i]
		var col_name: String = col_info["name"]
		var tint: Color = col_info["color"]
		var cost: int = int(col_info.get("cost", 0))
		var tier: String = str(col_info.get("tier", "Starter"))

		var is_unlocked: bool = false
		if prog != null:
			is_unlocked = bool(prog.call("is_unlocked", &"color", i))
		else:
			is_unlocked = Cosmetics.is_default_color(i)

		var is_equipped: bool = GameSettings.player_color == i
		_grid_container.add_child(_create_color_card(i, col_name, tint, tier, cost, is_unlocked, is_equipped))


func _create_color_card(index: int, col_name: String, tint: Color, tier: String, cost: int, unlocked: bool, equipped: bool) -> PanelContainer:
	var card := UiKit.panel(UiKit.NAVY_DARK, 0.92, 14, 2, UiKit.SKY if equipped else UiKit.BLUE, 10)
	card.custom_minimum_size = Vector2(200, 140)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Swatch preview circle/box
	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(36, 22)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.add_theme_stylebox_override("panel", UiKit.panel_style(tint, 1.0, 6, 2, UiKit.CREAM, 0))
	vbox.add_child(swatch)

	var name_lbl := UiKit.label(col_name.to_upper(), 18, UiKit.CREAM, 5)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var tier_lbl := UiKit.label(tier, 14, UiKit.SKY, 3)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_lbl)

	var prog: Node = get_node_or_null("/root/Progression")
	var can_afford: bool = prog != null and bool(prog.call("can_afford", cost))

	var btn: Button
	if equipped:
		btn = UiKit.small_button("EQUIPPED", Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.LIME.darkened(0.3), 0.9, 10, 2, UiKit.LIME, 6))
	elif unlocked:
		btn = UiKit.small_button("EQUIP", Vector2(160, 36))
		btn.pressed.connect(func() -> void:
			GameSettings.player_color = index
			GameSettings.save_settings()
			item_equipped.emit(&"color", index)
			_refresh_catalog())
	elif can_afford:
		btn = UiKit.small_button("BUY 🪙 %d" % cost, Vector2(160, 36))
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.ORANGE, 1.0, 10, 0, UiKit.ORANGE, 6))
		btn.pressed.connect(func() -> void:
			if prog != null and bool(prog.call("spend_coins", cost)):
				prog.call("unlock_item", &"color", index)
				GameSettings.player_color = index
				GameSettings.save_settings()
				if has_node("/root/Sfx"):
					(get_node("/root/Sfx") as Node).call("play", &"pickup")
				item_equipped.emit(&"color", index)
				_refresh_header()
				_refresh_catalog())
	else:
		btn = UiKit.small_button("NEED 🪙 %d" % cost, Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.GREY.darkened(0.4), 0.8, 10, 0, UiKit.GREY, 6))

	vbox.add_child(btn)
	return card


func _build_skins_catalog() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	for skin in Cosmetics.SKINS:
		var id: StringName = skin["id"]
		var skin_name: String = skin["name"]
		var cost: int = int(skin.get("cost", 0))
		var tier: String = str(skin.get("tier", "Starter"))
		var finish: int = int(skin.get("finish", 1))

		var is_unlocked: bool = false
		if prog != null:
			is_unlocked = bool(prog.call("is_unlocked", &"skin", id))
		else:
			is_unlocked = Cosmetics.is_default_skin(id)

		var is_equipped: bool = GameSettings.player_skin == id
		_grid_container.add_child(_create_skin_card(id, skin_name, tier, cost, finish, is_unlocked, is_equipped))


func _create_skin_card(id: StringName, skin_name: String, tier: String, cost: int, finish: int, unlocked: bool, equipped: bool) -> PanelContainer:
	var card := UiKit.panel(UiKit.NAVY_DARK, 0.92, 14, 2, UiKit.SKY if equipped else UiKit.BLUE, 10)
	card.custom_minimum_size = Vector2(200, 150)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var finish_names := ["MATTE", "GLOSS", "METALLIC", "HOLOGRAPHIC"]
	var finish_name: String = finish_names[clampi(finish, 0, finish_names.size() - 1)]

	var name_lbl := UiKit.label(skin_name.to_upper(), 18, UiKit.CREAM, 5)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var info_lbl := UiKit.label("%s • %s" % [tier, finish_name], 14, UiKit.SKY, 3)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_lbl)

	var prog: Node = get_node_or_null("/root/Progression")
	var can_afford: bool = prog != null and bool(prog.call("can_afford", cost))

	var btn: Button
	if equipped:
		btn = UiKit.small_button("EQUIPPED", Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.LIME.darkened(0.3), 0.9, 10, 2, UiKit.LIME, 6))
	elif unlocked:
		btn = UiKit.small_button("EQUIP", Vector2(160, 36))
		btn.pressed.connect(func() -> void:
			GameSettings.player_skin = id
			GameSettings.save_settings()
			item_equipped.emit(&"skin", id)
			_refresh_catalog())
	elif can_afford:
		btn = UiKit.small_button("BUY 🪙 %d" % cost, Vector2(160, 36))
		btn.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.ORANGE, 1.0, 10, 0, UiKit.ORANGE, 6))
		btn.pressed.connect(func() -> void:
			if prog != null and bool(prog.call("spend_coins", cost)):
				prog.call("unlock_item", &"skin", id)
				GameSettings.player_skin = id
				GameSettings.save_settings()
				if has_node("/root/Sfx"):
					(get_node("/root/Sfx") as Node).call("play", &"pickup")
				item_equipped.emit(&"skin", id)
				_refresh_header()
				_refresh_catalog())
	else:
		btn = UiKit.small_button("NEED 🪙 %d" % cost, Vector2(160, 36))
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", UiKit.panel_style(UiKit.GREY.darkened(0.4), 0.8, 10, 0, UiKit.GREY, 6))

	vbox.add_child(btn)
	return card
