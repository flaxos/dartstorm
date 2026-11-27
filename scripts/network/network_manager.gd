extends Node
## Autoload "NetworkManager": universal multiplayer networking for DARTSTORM.
## Uses WebSocketMultiplayerPeer on port 8920 to enable true cross-play between
## Web browsers (HTML5/WASM) and Desktop (Linux/Windows/macOS) over LAN and Internet.

signal connection_succeeded
signal connection_failed(reason: String)
signal server_disconnected
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal lobby_updated(roster: Array)
signal match_launching(arena_idx: int, mode_idx: int, roster: Array, bot_count: int, bot_diff: int)
signal lan_servers_updated(servers: Array[Dictionary])

const DEFAULT_PORT := 8920
const MAX_CLIENTS := 8

var is_online: bool = false
var is_host: bool = false
var is_dedicated_server: bool = false
var local_peer_id: int = 1
var server_name: String = "DARTSTORM Server"
var active_port: int = DEFAULT_PORT
var max_clients: int = MAX_CLIENTS

## Roster format: Array of Dictionaries:
## { "peer_id": int, "name": String, "color": int, "hat": StringName, "skin": StringName, "level": int, "team_id": int }
var roster: Array[Dictionary] = []

var selected_arena: int = 0
var selected_mode: int = 0
var bot_fill_count: int = 0
var bot_difficulty: int = 1

var _peer: WebSocketMultiplayerPeer
var _lan_discovery: LanDiscovery


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_lan_discovery = LanDiscovery.new()
	_lan_discovery.name = "LanDiscovery"
	add_child(_lan_discovery)
	_lan_discovery.servers_updated.connect(_on_lan_discovery_servers_updated)


func _on_lan_discovery_servers_updated(servers: Array[Dictionary]) -> void:
	lan_servers_updated.emit(servers)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_lan_discovery):
			if _lan_discovery.servers_updated.is_connected(_on_lan_discovery_servers_updated):
				_lan_discovery.servers_updated.disconnect(_on_lan_discovery_servers_updated)
			_lan_discovery.stop_broadcasting()
			_lan_discovery.stop_listening()
			_lan_discovery.free()
			_lan_discovery = null


## Starts hosting a WebSocket server.
func host_game(port: int = DEFAULT_PORT, p_max_players: int = MAX_CLIENTS, p_server_name: String = "", p_dedicated: bool = false) -> Error:
	var keep_dedicated := p_dedicated or is_dedicated_server
	disconnect_game()
	is_dedicated_server = keep_dedicated
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_server(port)
	if err != OK:
		push_error("NetworkManager: Failed to start server on port %d (error %d)" % [port, err])
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	is_online = true
	is_host = true
	local_peer_id = 1
	active_port = port
	max_clients = p_max_players
	if not p_server_name.is_empty():
		server_name = p_server_name
	elif server_name.is_empty() or server_name == "DARTSTORM Server":
		server_name = "%s's Match" % GameSettings.display_name()

	roster.clear()
	if not is_dedicated_server:
		# Register host profile in roster
		var my_info := _get_local_player_info()
		my_info["peer_id"] = 1
		roster.append(my_info)
	lobby_updated.emit(roster)

	start_lan_broadcast(server_name, port)
	return OK


## Joins a remote WebSocket host (ws://address:port).
func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	disconnect_game()
	_peer = WebSocketMultiplayerPeer.new()
	var clean_addr := address.strip_edges()
	if clean_addr.is_empty():
		clean_addr = "127.0.0.1"

	var url := clean_addr
	if not url.begins_with("ws://") and not url.begins_with("wss://"):
		if url.contains(":") and not url.begins_with("["):
			url = "ws://" + url
		else:
			url = "ws://%s:%d" % [url, port]

	var err := _peer.create_client(url)
	if err != OK:
		push_error("NetworkManager: Failed to connect to %s (error %d)" % [url, err])
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	is_online = true
	is_host = false
	roster.clear()
	return OK


## Closes active peer and resets state.
func disconnect_game() -> void:
	stop_lan_broadcast()
	stop_lan_discovery()
	if _peer != null:
		_peer.close()
		_peer = null
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	is_online = false
	is_host = false
	is_dedicated_server = false
	local_peer_id = 1
	roster.clear()


# --- LAN Discovery Bridges ---

func start_lan_broadcast(p_name: String = "", p_port: int = -1) -> void:
	if _lan_discovery == null:
		return
	var b_name := p_name if not p_name.is_empty() else server_name
	var b_port := p_port if p_port > 0 else active_port
	var state_str := "MATCH" if (get_tree().current_scene is MatchScene) else "LOBBY"
	_lan_discovery.start_broadcasting(b_name, b_port, selected_arena, selected_mode, roster.size(), max_clients, is_dedicated_server, state_str)


func update_lan_broadcast(arena_idx: int = -1, mode_idx: int = -1, players: int = -1, p_state: String = "") -> void:
	if _lan_discovery == null:
		return
	var a := arena_idx if arena_idx >= 0 else selected_arena
	var m := mode_idx if mode_idx >= 0 else selected_mode
	var p := players if players >= 0 else roster.size()
	var s := p_state if not p_state.is_empty() else ("MATCH" if (get_tree().current_scene is MatchScene) else "LOBBY")
	_lan_discovery.update_broadcast(a, m, p, s)


func stop_lan_broadcast() -> void:
	if _lan_discovery != null:
		_lan_discovery.stop_broadcasting()


func start_lan_discovery() -> bool:
	if _lan_discovery == null:
		return false
	return _lan_discovery.start_listening()


func stop_lan_discovery() -> void:
	if _lan_discovery != null:
		_lan_discovery.stop_listening()


func get_lan_servers() -> Array[Dictionary]:
	if _lan_discovery == null:
		return []
	return _lan_discovery.get_discovered_servers()


func _get_local_player_info() -> Dictionary:
	var prog: Node = get_node_or_null("/root/Progression")
	var p_data: Dictionary = {}
	if prog != null and prog.has_method("get_profile_data"):
		p_data = prog.call("get_profile_data")
	var p_name: String = str(p_data.get("name", GameSettings.display_name()))
	var p_color: int = int(p_data.get("color", GameSettings.player_color))
	var p_hat: StringName = StringName(str(p_data.get("hat", GameSettings.player_hat)))
	var p_skin: StringName = StringName(str(p_data.get("skin", GameSettings.player_skin)))
	var p_level: int = int(p_data.get("level", 1))

	return {
		"peer_id": local_peer_id,
		"name": p_name,
		"color": p_color,
		"hat": p_hat,
		"skin": p_skin,
		"level": p_level,
		"team_id": 0,
	}


func _on_peer_connected(id: int) -> void:
	peer_connected.emit(id)
	if is_host:
		# Send current lobby settings and current roster to newly joined peer
		_sync_lobby_to_all.call_deferred()


func _on_peer_disconnected(id: int) -> void:
	if is_host:
		for i in range(roster.size() - 1, -1, -1):
			if int(roster[i].get("peer_id", 0)) == id:
				roster.remove_at(i)
				break
		_sync_lobby_to_all()
	peer_disconnected.emit(id)


func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	connection_succeeded.emit()
	# Transmit our profile to host
	var my_info := _get_local_player_info()
	rpc_id(1, &"rpc_register_player", my_info)


func _on_connection_failed() -> void:
	disconnect_game()
	connection_failed.emit("Could not connect to host. Check IP and port.")


func _on_server_disconnected() -> void:
	disconnect_game()
	server_disconnected.emit()


@rpc("any_peer", "reliable")
func rpc_register_player(info: Dictionary) -> void:
	if not is_host:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_peer_id

	# Prevent roster flooding beyond MAX_CLIENTS
	var existing_idx := -1
	for i in roster.size():
		if int(roster[i].get("peer_id", 0)) == sender_id:
			existing_idx = i
			break
	if existing_idx < 0 and roster.size() >= MAX_CLIENTS:
		return

	# Sanitize and bound all incoming player profile attributes
	var raw_name: String = str(info.get("name", "Player"))
	var safe_name := Cosmetics.sanitize_name(raw_name)
	if safe_name.is_empty():
		safe_name = "Player %d" % sender_id
	var safe_color: int = clampi(int(info.get("color", 0)), 0, Cosmetics.COLORS.size() - 1)
	var raw_hat: StringName = StringName(str(info.get("hat", &"cap")))
	var safe_hat: StringName = raw_hat if Cosmetics.has_hat(raw_hat) else &"cap"
	var raw_skin: StringName = StringName(str(info.get("skin", &"default")))
	var safe_skin: StringName = raw_skin if Cosmetics.has_skin(raw_skin) else &"default"
	var safe_level: int = clampi(int(info.get("level", 1)), 1, 100)

	var slot_idx := existing_idx if existing_idx >= 0 else roster.size()
	var mode_obj := MatchScene.resolve_mode(selected_mode)
	var assigned_team := mode_obj.team_for(slot_idx) if mode_obj != null else (slot_idx % 2)
	var clean_entry := {
		"peer_id": sender_id,
		"name": safe_name,
		"color": safe_color,
		"hat": safe_hat,
		"skin": safe_skin,
		"level": safe_level,
		"team_id": assigned_team,
	}

	if existing_idx >= 0:
		roster[existing_idx] = clean_entry
	else:
		roster.append(clean_entry)
	_sync_lobby_to_all()


func _sync_lobby_to_all() -> void:
	if not is_host:
		return
	update_lan_broadcast(selected_arena, selected_mode, roster.size(), "MATCH" if (get_tree().current_scene is MatchScene) else "LOBBY")
	rpc(&"rpc_sync_lobby", roster, selected_arena, selected_mode)
	lobby_updated.emit(roster)


@rpc("authority", "reliable")
func rpc_sync_lobby(p_roster: Array, p_arena: int, p_mode: int) -> void:
	roster.clear()
	for entry in p_roster:
		if entry is Dictionary:
			roster.append(entry)
	selected_arena = p_arena
	selected_mode = p_mode
	lobby_updated.emit(roster)


## Host starts the match for all connected peers.
func launch_match() -> void:
	if not is_host:
		return
	update_lan_broadcast(selected_arena, selected_mode, roster.size(), "MATCH")
	rpc(&"rpc_launch_match", selected_arena, selected_mode, roster, bot_fill_count, bot_difficulty)
	_do_launch(selected_arena, selected_mode, roster, bot_fill_count, bot_difficulty)


@rpc("authority", "reliable")
func rpc_launch_match(p_arena: int, p_mode: int, p_roster: Array, p_bot_fill: int, p_bot_diff: int) -> void:
	var clean_roster: Array[Dictionary] = []
	for r in p_roster:
		if r is Dictionary:
			clean_roster.append(r)
	_do_launch(p_arena, p_mode, clean_roster, p_bot_fill, p_bot_diff)


func _do_launch(p_arena: int, p_mode: int, p_roster: Array[Dictionary], p_bot_fill: int, p_bot_diff: int) -> void:
	roster = p_roster
	selected_arena = p_arena
	selected_mode = p_mode
	GameSettings.arena = p_arena
	GameSettings.match_mode = p_mode
	GameSettings.bot_difficulty = p_bot_diff
	GameSettings.bot_count = p_bot_fill
	GameSettings.split_screen = false
	match_launching.emit(p_arena, p_mode, p_roster, p_bot_fill, p_bot_diff)
	get_tree().change_scene_to_file("res://scenes/game/match.tscn")


# --- In-Game Gameplay RPCs ---

@rpc("any_peer", "unreliable")
func rpc_sync_state(peer_id: int, pos: Vector3, rot_y: float, pitch: float, vel: Vector3, is_aiming: bool, is_sprinting: bool) -> void:
	# Enforce server-verified sender ID to prevent impersonation/spoofing
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = peer_id

	# Drop corrupted or NaN/INF packets
	if not pos.is_finite() or not vel.is_finite() or not is_finite(rot_y) or not is_finite(pitch):
		return

	# Relay to current match if active
	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_state_received"):
		match_scene.call("on_network_state_received", sender_id, pos, rot_y, pitch, vel, is_aiming, is_sprinting)


@rpc("any_peer", "reliable")
func rpc_fire_dart(shooter_id: int, weapon_index: int, origin: Vector3, dir: Vector3, charge: float, element: int) -> void:
	# Enforce server-verified shooter ID to prevent forged hostile fire
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = shooter_id

	# Validate direction and origin vectors against NaN/INF and zero-length
	if not origin.is_finite() or not dir.is_finite() or dir.length_squared() < 0.0001:
		return
	var safe_dir := dir.normalized()
	var safe_charge := clampf(charge, 0.0, 1.0)
	var safe_element := clampi(element, 0, 5)

	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_fire_dart"):
		match_scene.call("on_network_fire_dart", sender_id, weapon_index, origin, safe_dir, safe_charge, safe_element)


@rpc("authority", "reliable")
func rpc_actor_tagged(victim_id: int, attacker_id: int, weapon_name: String, ricochet: bool) -> void:
	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_actor_tagged"):
		match_scene.call("on_network_actor_tagged", victim_id, attacker_id, weapon_name, ricochet)


@rpc("authority", "reliable")
func rpc_actor_respawn(peer_id: int, spawn_pos: Vector3) -> void:
	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_actor_respawn"):
		match_scene.call("on_network_actor_respawn", peer_id, spawn_pos)
