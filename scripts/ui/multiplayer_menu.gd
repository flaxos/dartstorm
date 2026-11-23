class_name MultiplayerMenu
extends PanelContainer
## Online Multiplayer Hub for DARTSTORM.
## Supports hosting and joining cross-platform WebSocket matches across LAN and Internet.

signal closed

enum Tab { HOST, JOIN }

var _current_tab: Tab = Tab.HOST
var _box: VBoxContainer
var _host_panel: VBoxContainer
var _join_panel: VBoxContainer
var _lobby_panel: VBoxContainer
var _host_tab_btn: Button
var _join_tab_btn: Button
var _status_label: Label
var _ip_label: Label
var _server_name_edit: LineEdit
var _lan_scan_label: Label
var _server_list_container: VBoxContainer
var _address_edit: LineEdit
var _port_edit: LineEdit
var _host_port_edit: LineEdit
var _arena_label: Label
var _mode_label: Label
var _bot_fill_btn: Button
var _roster_container: VBoxContainer
var _launch_btn: Button
var _leave_btn: Button
var _selected_arena: int = 0
var _selected_mode: int = 0
var _bot_fill: bool = true


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY, 0.96, 22, 4, UiKit.ORANGE, 24))
	_build()
	_connect_network_signals()


func _exit_tree() -> void:
	if NetworkManager != null:
		NetworkManager.stop_lan_discovery()


func _connect_network_signals() -> void:
	if NetworkManager != null:
		NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
		NetworkManager.connection_failed.connect(_on_connection_failed)
		NetworkManager.server_disconnected.connect(_on_server_disconnected)
		NetworkManager.lobby_updated.connect(_on_lobby_updated)
		NetworkManager.lan_servers_updated.connect(_on_lan_servers_updated)


func _build() -> void:
	for child in get_children():
		child.queue_free()

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	add_child(_box)

	# Header
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	_box.add_child(title_row)

	var title := UiKit.label("ONLINE MULTIPLAYER", 36, UiKit.ORANGE_HOT, 8)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := UiKit.small_button("BACK", Vector2(100, 42))
	close_btn.pressed.connect(func() -> void:
		if NetworkManager != null and NetworkManager.is_online:
			NetworkManager.disconnect_game()
		closed.emit())
	title_row.add_child(close_btn)

	# Local IP & Profile Bar
	var info_bar := HBoxContainer.new()
	info_bar.add_theme_constant_override("separation", 16)
	_box.add_child(info_bar)

	var my_name: String = GameSettings.display_name()
	var profile_badge := UiKit.label("PROFILE: %s" % my_name.to_upper(), 18, UiKit.SKY, 4)
	info_bar.add_child(profile_badge)

	_ip_label = UiKit.label("LOCAL IP: %s (PORT %d)" % [_get_local_ip(), NetworkManager.DEFAULT_PORT], 16, UiKit.CREAM, 3)
	_ip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_bar.add_child(_ip_label)

	# Navigation Tabs (HOST / JOIN)
	var tabs_row := HBoxContainer.new()
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_row.add_theme_constant_override("separation", 12)
	_box.add_child(tabs_row)

	_host_tab_btn = UiKit.button("HOST MATCH", 22, Vector2(220, 48))
	_host_tab_btn.pressed.connect(_switch_tab.bind(Tab.HOST))
	tabs_row.add_child(_host_tab_btn)

	_join_tab_btn = UiKit.button("JOIN MATCH", 22, Vector2(220, 48))
	_join_tab_btn.pressed.connect(_switch_tab.bind(Tab.JOIN))
	tabs_row.add_child(_join_tab_btn)

	# Content Area
	var content_box := VBoxContainer.new()
	content_box.custom_minimum_size = Vector2(620, 340)
	_box.add_child(content_box)

	_build_host_panel(content_box)
	_build_join_panel(content_box)
	_build_lobby_panel(content_box)

	_status_label = UiKit.label("", 18, UiKit.ORANGE_HOT, 4)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_status_label)

	_switch_tab(Tab.HOST)


func _build_host_panel(parent: Control) -> void:
	_host_panel = VBoxContainer.new()
	_host_panel.add_theme_constant_override("separation", 12)
	parent.add_child(_host_panel)

	# Server Name
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	_host_panel.add_child(name_row)
	var n_lbl := UiKit.label("NAME:", 18, UiKit.SKY, 4)
	n_lbl.custom_minimum_size.x = 100
	name_row.add_child(n_lbl)
	_server_name_edit = LineEdit.new()
	_server_name_edit.text = "%s's Match" % GameSettings.display_name()
	_server_name_edit.custom_minimum_size = Vector2(260, 36)
	name_row.add_child(_server_name_edit)

	# Arena picker
	var arena_row := HBoxContainer.new()
	arena_row.add_theme_constant_override("separation", 10)
	_host_panel.add_child(arena_row)
	var a_lbl := UiKit.label("ARENA:", 18, UiKit.SKY, 4)
	a_lbl.custom_minimum_size.x = 100
	arena_row.add_child(a_lbl)
	var prev_a := UiKit.small_button("<", Vector2(40, 36))
	prev_a.pressed.connect(_cycle_arena.bind(-1))
	arena_row.add_child(prev_a)
	_arena_label = UiKit.label(MatchScene.ARENAS[_selected_arena]["name"], 18, UiKit.CREAM, 4)
	_arena_label.custom_minimum_size = Vector2(260, 36)
	_arena_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_row.add_child(_arena_label)
	var next_a := UiKit.small_button(">", Vector2(40, 36))
	next_a.pressed.connect(_cycle_arena.bind(1))
	arena_row.add_child(next_a)

	# Mode picker
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 10)
	_host_panel.add_child(mode_row)
	var m_lbl := UiKit.label("MODE:", 18, UiKit.SKY, 4)
	m_lbl.custom_minimum_size.x = 100
	mode_row.add_child(m_lbl)
	var prev_m := UiKit.small_button("<", Vector2(40, 36))
	prev_m.pressed.connect(_cycle_mode.bind(-1))
	mode_row.add_child(prev_m)
	_mode_label = UiKit.label(MatchScene.resolve_mode(_selected_mode).short_name.to_upper(), 18, UiKit.CREAM, 4)
	_mode_label.custom_minimum_size = Vector2(260, 36)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_row.add_child(_mode_label)
	var next_m := UiKit.small_button(">", Vector2(40, 36))
	next_m.pressed.connect(_cycle_mode.bind(1))
	mode_row.add_child(next_m)

	# Bot Fill Toggle
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 10)
	_host_panel.add_child(bot_row)
	var b_lbl := UiKit.label("BOT FILL:", 18, UiKit.SKY, 4)
	b_lbl.custom_minimum_size.x = 100
	bot_row.add_child(b_lbl)
	_bot_fill_btn = UiKit.small_button("ENABLED (4 PLAYERS)", Vector2(260, 36))
	_bot_fill_btn.pressed.connect(func() -> void:
		_bot_fill = not _bot_fill
		_bot_fill_btn.text = "ENABLED (4 PLAYERS)" if _bot_fill else "OFF (HUMANS ONLY)")
	bot_row.add_child(_bot_fill_btn)

	# Port selection
	var port_row := HBoxContainer.new()
	port_row.add_theme_constant_override("separation", 10)
	_host_panel.add_child(port_row)
	var p_lbl := UiKit.label("PORT:", 18, UiKit.SKY, 4)
	p_lbl.custom_minimum_size.x = 100
	port_row.add_child(p_lbl)
	_host_port_edit = LineEdit.new()
	_host_port_edit.text = str(NetworkManager.DEFAULT_PORT)
	_host_port_edit.custom_minimum_size = Vector2(140, 36)
	port_row.add_child(_host_port_edit)

	var start_host_btn := UiKit.button("START HOSTING", 24, Vector2(280, 52))
	start_host_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_host_btn.pressed.connect(_on_start_hosting_pressed)
	_host_panel.add_child(start_host_btn)


func _build_join_panel(parent: Control) -> void:
	_join_panel = VBoxContainer.new()
	_join_panel.add_theme_constant_override("separation", 8)
	parent.add_child(_join_panel)

	# LAN Server Browser Header
	var browser_header := HBoxContainer.new()
	browser_header.add_theme_constant_override("separation", 10)
	_join_panel.add_child(browser_header)

	var title_lbl := UiKit.label("LAN SERVER BROWSER", 20, UiKit.ORANGE_HOT, 5)
	browser_header.add_child(title_lbl)

	_lan_scan_label = UiKit.label("SCANNING...", 15, UiKit.CREAM, 3)
	_lan_scan_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lan_scan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	browser_header.add_child(_lan_scan_label)

	var refresh_btn := UiKit.small_button("REFRESH", Vector2(90, 32))
	refresh_btn.pressed.connect(_on_refresh_lan_servers)
	browser_header.add_child(refresh_btn)

	# Scrollable Server List
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 150)
	_join_panel.add_child(scroll)

	_server_list_container = VBoxContainer.new()
	_server_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_server_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_server_list_container)

	_update_server_list_ui([])

	# Separator and Direct Connect
	var sep := HSeparator.new()
	_join_panel.add_child(sep)

	var dc_title := UiKit.label("OR DIRECT CONNECT (MANUAL IP / DOMAIN):", 16, UiKit.SKY, 4)
	_join_panel.add_child(dc_title)

	var dc_row := HBoxContainer.new()
	dc_row.add_theme_constant_override("separation", 8)
	_join_panel.add_child(dc_row)

	var a_lbl := UiKit.label("IP:", 16, UiKit.CREAM, 3)
	dc_row.add_child(a_lbl)

	_address_edit = LineEdit.new()
	_address_edit.placeholder_text = "192.168.1.50 or ws://domain"
	_address_edit.text = _get_local_ip()
	_address_edit.custom_minimum_size = Vector2(230, 38)
	dc_row.add_child(_address_edit)

	var p_lbl := UiKit.label("PORT:", 16, UiKit.CREAM, 3)
	dc_row.add_child(p_lbl)

	_port_edit = LineEdit.new()
	_port_edit.text = str(NetworkManager.DEFAULT_PORT)
	_port_edit.custom_minimum_size = Vector2(80, 38)
	dc_row.add_child(_port_edit)

	var connect_btn := UiKit.button("CONNECT", 20, Vector2(130, 40))
	connect_btn.pressed.connect(_on_connect_pressed)
	dc_row.add_child(connect_btn)


func _build_lobby_panel(parent: Control) -> void:
	_lobby_panel = VBoxContainer.new()
	_lobby_panel.add_theme_constant_override("separation", 12)
	_lobby_panel.visible = false
	parent.add_child(_lobby_panel)

	var lobby_header := UiKit.label("LOBBY SQUAD", 22, UiKit.ORANGE_HOT, 5)
	_lobby_panel.add_child(lobby_header)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 180)
	_lobby_panel.add_child(scroll)

	_roster_container = VBoxContainer.new()
	_roster_container.add_theme_constant_override("separation", 6)
	_roster_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_roster_container)

	var actions_row := HBoxContainer.new()
	actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_row.add_theme_constant_override("separation", 16)
	_lobby_panel.add_child(actions_row)

	_leave_btn = UiKit.button("LEAVE ROOM", 22, Vector2(180, 50))
	_leave_btn.pressed.connect(_on_leave_lobby)
	actions_row.add_child(_leave_btn)

	_launch_btn = UiKit.button("LAUNCH MATCH!", 26, Vector2(240, 50))
	_launch_btn.pressed.connect(_on_launch_match)
	actions_row.add_child(_launch_btn)


func _switch_tab(tab: Tab) -> void:
	_current_tab = tab
	var is_h := tab == Tab.HOST
	_host_panel.visible = is_h and not (NetworkManager != null and NetworkManager.is_online)
	_join_panel.visible = not is_h and not (NetworkManager != null and NetworkManager.is_online)
	_lobby_panel.visible = NetworkManager != null and NetworkManager.is_online
	_host_tab_btn.add_theme_stylebox_override("normal",
			UiKit.panel_style(UiKit.ORANGE if is_h else UiKit.BLUE, 1.0, 12, 3 if is_h else 0, UiKit.CREAM, 8))
	_join_tab_btn.add_theme_stylebox_override("normal",
			UiKit.panel_style(UiKit.ORANGE if not is_h else UiKit.BLUE, 1.0, 12, 3 if not is_h else 0, UiKit.CREAM, 8))

	if tab == Tab.JOIN and NetworkManager != null:
		NetworkManager.start_lan_discovery()
		_update_server_list_ui(NetworkManager.get_lan_servers())
	elif NetworkManager != null and not NetworkManager.is_online:
		NetworkManager.stop_lan_discovery()


func _on_refresh_lan_servers() -> void:
	if NetworkManager != null:
		NetworkManager.stop_lan_discovery()
		NetworkManager.start_lan_discovery()
		_update_server_list_ui(NetworkManager.get_lan_servers())


func _on_lan_servers_updated(servers: Array[Dictionary]) -> void:
	if _join_panel != null and _join_panel.visible:
		_update_server_list_ui(servers)


func _update_server_list_ui(servers: Array[Dictionary]) -> void:
	if _server_list_container == null:
		return
	for child in _server_list_container.get_children():
		child.queue_free()

	if OS.has_feature("web"):
		var web_notice := UiKit.label("LAN Auto-Discovery is available on Desktop & Mobile apps.\nUse Direct Connect below on Web.", 14, UiKit.CREAM, 2)
		_server_list_container.add_child(web_notice)
		_lan_scan_label.text = "WEB BROWSER MODE"
		return

	if servers.is_empty():
		var empty_lbl := UiKit.label("No active LAN servers detected yet.\nHost a match or launch a Dedicated Server to play!", 14, UiKit.CREAM, 2)
		_server_list_container.add_child(empty_lbl)
		_lan_scan_label.text = "LISTENING (PORT 8925)..."
		return

	_lan_scan_label.text = "%d SERVER%s FOUND" % [servers.size(), "S" if servers.size() != 1 else ""]
	for s in servers:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY_DARK, 0.92, 10, 2, UiKit.ORANGE if bool(s.get("dedicated", false)) else UiKit.SKY, 10))
		_server_list_container.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_col)

		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		info_col.add_child(name_row)

		var s_name := str(s.get("name", "DARTSTORM Server"))
		var name_lbl := UiKit.label(s_name, 18, UiKit.CREAM, 4)
		name_row.add_child(name_lbl)

		if bool(s.get("dedicated", false)):
			var ded_badge := UiKit.label("[DEDICATED]", 14, UiKit.ORANGE_HOT, 3)
			name_row.add_child(ded_badge)
		else:
			var host_badge := UiKit.label("[LAN HOST]", 14, UiKit.SKY, 3)
			name_row.add_child(host_badge)

		var sub_txt := "%s • %s • %s" % [str(s.get("arena_name", "")), str(s.get("mode_name", "")), str(s.get("state", "LOBBY"))]
		var sub_lbl := UiKit.label(sub_txt, 14, UiKit.SKY, 2)
		info_col.add_child(sub_lbl)

		var p_count: int = int(s.get("players", 1))
		var p_max: int = int(s.get("max_players", 8))
		var p_col: Color = UiKit.LIME if p_count < p_max else UiKit.ORANGE_HOT
		var p_lbl := UiKit.label("%d/%d PLAYERS\n%s:%d" % [p_count, p_max, str(s.get("ip", "")), int(s.get("port", 8920))], 13, p_col, 2)
		p_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(p_lbl)

		var join_btn := UiKit.button("JOIN", 18, Vector2(85, 38))
		var target_ip := str(s.get("ip", "127.0.0.1"))
		var target_port := int(s.get("port", 8920))
		join_btn.pressed.connect(func() -> void:
			_status_label.text = "Connecting to %s:%d..." % [target_ip, target_port]
			NetworkManager.join_game(target_ip, target_port))
		row.add_child(join_btn)


func _cycle_arena(step: int) -> void:
	_selected_arena = (_selected_arena + step + MatchScene.ARENAS.size()) % MatchScene.ARENAS.size()
	_arena_label.text = MatchScene.ARENAS[_selected_arena]["name"]


func _cycle_mode(step: int) -> void:
	_selected_mode = (_selected_mode + step + MatchScene.MODE_PATHS.size()) % MatchScene.MODE_PATHS.size()
	_mode_label.text = MatchScene.resolve_mode(_selected_mode).short_name.to_upper()


func _on_start_hosting_pressed() -> void:
	var port := int(_host_port_edit.text)
	if port <= 0:
		port = NetworkManager.DEFAULT_PORT
	NetworkManager.selected_arena = _selected_arena
	NetworkManager.selected_mode = _selected_mode
	NetworkManager.bot_fill_count = 3 if _bot_fill else 0
	var s_name := _server_name_edit.text.strip_edges() if _server_name_edit != null else ""

	var err := NetworkManager.host_game(port, NetworkManager.MAX_CLIENTS, s_name)
	if err == OK:
		_status_label.text = "Server hosted! Broadcasting on LAN (Port %d)." % port
		_show_lobby_view()
	else:
		_status_label.text = "Error hosting server (code %d)" % err


func _on_connect_pressed() -> void:
	var addr := _address_edit.text.strip_edges()
	var port := int(_port_edit.text)
	if port <= 0:
		port = NetworkManager.DEFAULT_PORT
	_status_label.text = "Connecting to %s..." % addr
	var err := NetworkManager.join_game(addr, port)
	if err != OK:
		_status_label.text = "Failed to initiate connection (code %d)" % err


func _on_connection_succeeded() -> void:
	_status_label.text = "Connected to host!"
	_show_lobby_view()


func _on_connection_failed(reason: String) -> void:
	_status_label.text = reason
	_switch_tab(_current_tab)


func _on_server_disconnected() -> void:
	_status_label.text = "Host disconnected."
	_switch_tab(_current_tab)


func _on_lobby_updated(roster: Array) -> void:
	if not _lobby_panel.visible:
		_show_lobby_view()
	for child in _roster_container.get_children():
		child.queue_free()

	for entry in roster:
		if entry is Dictionary:
			var p_row := HBoxContainer.new()
			p_row.add_theme_constant_override("separation", 12)
			_roster_container.add_child(p_row)

			var p_id: int = int(entry.get("peer_id", 0))
			var p_name: String = str(entry.get("name", "Player"))
			var is_me := p_id == NetworkManager.local_peer_id
			var is_h := p_id == 1

			var tag := " [YOU]" if is_me else ""
			var role := " (HOST)" if is_h else ""
			var lbl := UiKit.label("• %s%s%s" % [p_name, role, tag], 18, UiKit.ORANGE_HOT if is_me else UiKit.CREAM, 4)
			p_row.add_child(lbl)

	if _launch_btn != null:
		_launch_btn.visible = NetworkManager.is_host


func _show_lobby_view() -> void:
	_host_panel.visible = false
	_join_panel.visible = false
	_lobby_panel.visible = true
	_launch_btn.visible = NetworkManager.is_host


func _on_leave_lobby() -> void:
	NetworkManager.disconnect_game()
	_status_label.text = "Left room."
	_switch_tab(_current_tab)


func _on_launch_match() -> void:
	if NetworkManager.is_host:
		NetworkManager.launch_match()


func _get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if not ip.contains(":") and ip != "127.0.0.1" and not ip.begins_with("169.254"):
			return ip
	return "127.0.0.1"
