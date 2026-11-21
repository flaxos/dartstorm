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

const DEFAULT_PORT := 8920
const MAX_CLIENTS := 8

var is_online: bool = false
var is_host: bool = false
var local_peer_id: int = 1

## Roster format: Array of Dictionaries:
## { "peer_id": int, "name": String, "color": int, "hat": StringName, "skin": StringName, "level": int, "team_id": int }
var roster: Array[Dictionary] = []

var selected_arena: int = 0
var selected_mode: int = 0
var bot_fill_count: int = 0
var bot_difficulty: int = 1

var _peer: WebSocketMultiplayerPeer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Starts hosting a WebSocket server.
func host_game(port: int = DEFAULT_PORT, _max_players: int = MAX_CLIENTS) -> Error:
	disconnect_game()
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

	# Register host profile in roster
	roster.clear()
	var my_info := _get_local_player_info()
	my_info["peer_id"] = 1
	roster.append(my_info)
	lobby_updated.emit(roster)
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
	if _peer != null:
		_peer.close()
		_peer = null
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	is_online = false
	is_host = false
	local_peer_id = 1
	roster.clear()


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
	peer_disconnected.emit(id)
	if is_host:
		for i in range(roster.size() - 1, -1, -1):
			if int(roster[i].get("peer_id", 0)) == id:
				roster.remove_at(i)
				break
		_sync_lobby_to_all()


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
	info["peer_id"] = sender_id
	# Assign team index based on mode
	info["team_id"] = roster.size() % 2
	# Remove any old entry for this peer
	for i in range(roster.size() - 1, -1, -1):
		if int(roster[i].get("peer_id", 0)) == sender_id:
			roster.remove_at(i)
			break
	roster.append(info)
	_sync_lobby_to_all()


func _sync_lobby_to_all() -> void:
	if not is_host:
		return
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
	# Relay to current match if active
	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_state_received"):
		match_scene.call("on_network_state_received", peer_id, pos, rot_y, pitch, vel, is_aiming, is_sprinting)


@rpc("any_peer", "reliable")
func rpc_fire_dart(shooter_id: int, weapon_index: int, origin: Vector3, dir: Vector3, charge: float, element: int) -> void:
	var match_scene := get_tree().current_scene as MatchScene
	if match_scene != null and match_scene.has_method("on_network_fire_dart"):
		match_scene.call("on_network_fire_dart", shooter_id, weapon_index, origin, dir, charge, element)


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
