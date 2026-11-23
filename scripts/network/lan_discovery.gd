class_name LanDiscovery
extends Node
## LAN Auto-Discovery system for DARTSTORM multiplayer.
## Uses UDP broadcast beacons on port 8925 so clients automatically find
## hosted matches and dedicated servers on the local network without manual IP entry.

signal servers_updated(servers: Array[Dictionary])

const DISCOVERY_PORT := 8925
const MAGIC := "DARTSTORM"
const PROTOCOL_VERSION := 1
const BROADCAST_INTERVAL := 1.0
const SERVER_TIMEOUT_MSEC := 3500

var is_broadcasting: bool = false:
	get:
		return _is_broadcasting

var is_listening: bool = false:
	get:
		return _is_listening

var discovered_servers: Dictionary:
	get:
		return _discovered_servers

var server_name: String:
	get:
		return str(_broadcast_data.get("name", ""))

var server_port: int:
	get:
		return int(_broadcast_data.get("port", 0))

var current_arena: int:
	get:
		return int(_broadcast_data.get("arena", 0))

var current_mode: int:
	get:
		return int(_broadcast_data.get("mode", 0))

var player_count: int:
	get:
		return int(_broadcast_data.get("players", 0))

var max_players: int:
	get:
		return int(_broadcast_data.get("max_players", 0))

var is_dedicated: bool:
	get:
		return bool(_broadcast_data.get("dedicated", false))

var _broadcaster: PacketPeerUDP
var _listener: PacketPeerUDP
var _is_broadcasting: bool = false
var _is_listening: bool = false
var _broadcast_timer: float = 0.0
var _broadcast_data: Dictionary = {}
var _discovered_servers: Dictionary = {}  # "ip:port" -> Dictionary


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop_broadcasting()
		stop_listening()


func _process(delta: float) -> void:
	if _is_broadcasting:
		_broadcast_timer -= delta
		if _broadcast_timer <= 0.0:
			_broadcast_timer = BROADCAST_INTERVAL
			_send_broadcast_packet()

	if _is_listening:
		_poll_listener()


## Configures the server information payload dictionary.
func set_server_info(game_port: int, p_name: String, arena_idx: int, mode_idx: int,
		players: int, max_p: int, dedicated: bool, match_state: String = "LOBBY") -> void:
	_broadcast_data = {
		"magic": MAGIC,
		"v": PROTOCOL_VERSION,
		"name": p_name,
		"port": game_port,
		"arena": arena_idx,
		"arena_name": _resolve_arena_name(arena_idx),
		"mode": mode_idx,
		"mode_name": _resolve_mode_name(mode_idx),
		"players": players,
		"max_players": max_p,
		"dedicated": dedicated,
		"state": match_state,
	}


## Starts broadcasting a server heartbeat beacon over UDP.
func start_broadcasting(p_name: String, game_port: int, arena_idx: int, mode_idx: int,
		players: int, max_p: int, dedicated: bool, match_state: String = "LOBBY") -> bool:
	if OS.has_feature("web"):
		return false

	stop_broadcasting()
	set_server_info(game_port, p_name, arena_idx, mode_idx, players, max_p, dedicated, match_state)

	_broadcaster = PacketPeerUDP.new()
	_broadcaster.set_broadcast_enabled(true)
	var err := _broadcaster.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	if err != OK:
		push_warning("LanDiscovery: Could not set broadcast address (error %d)" % err)
		_broadcaster = null
		return false

	_is_broadcasting = true
	_broadcast_timer = 0.0  # Send immediate beacon
	return true


## Updates the dynamic payload fields for an active broadcast (player count, match state, map).
func update_broadcast(arena_idx: int, mode_idx: int, players: int, match_state: String) -> void:
	if not _is_broadcasting:
		return
	_broadcast_data["arena"] = arena_idx
	_broadcast_data["arena_name"] = _resolve_arena_name(arena_idx)
	_broadcast_data["mode"] = mode_idx
	_broadcast_data["mode_name"] = _resolve_mode_name(mode_idx)
	_broadcast_data["players"] = players
	_broadcast_data["state"] = match_state


## Stops transmitting LAN beacons.
func stop_broadcasting() -> void:
	_is_broadcasting = false
	if _broadcaster != null:
		_broadcaster.close()
		_broadcaster = null
	_broadcast_data.clear()


## Starts listening for LAN beacon broadcasts from hosts and dedicated servers.
func start_listening() -> bool:
	if OS.has_feature("web"):
		return false

	stop_listening()

	_listener = PacketPeerUDP.new()
	var err := _listener.bind(DISCOVERY_PORT)
	if err != OK:
		push_warning("LanDiscovery: Could not bind listener on port %d (error %d)" % [DISCOVERY_PORT, err])
		_listener = null
		return false

	_is_listening = true
	_discovered_servers.clear()
	return true


## Stops listening for LAN server beacons.
func stop_listening() -> void:
	_is_listening = false
	if _listener != null:
		_listener.close()
		_listener = null
	_discovered_servers.clear()


## Returns a list of currently discovered active servers.
func get_discovered_servers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _discovered_servers:
		result.append(_discovered_servers[key])
	return result


## Clears discovered servers cache.
func clear_discovered_servers() -> void:
	_discovered_servers.clear()
	servers_updated.emit([])


func _send_broadcast_packet() -> void:
	if _broadcaster == null or not _is_broadcasting:
		return
	var json_str := JSON.stringify(_broadcast_data)
	var bytes := json_str.to_utf8_buffer()
	var _err := _broadcaster.put_packet(bytes)


## Ingests and validates an incoming raw UDP beacon packet from a remote host.
func ingest_packet(pkt: PackedByteArray, sender_ip: String) -> bool:
	if pkt.is_empty() or sender_ip.is_empty():
		return false

	var json_str := pkt.get_string_from_utf8()
	var parsed = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return false

	var dict: Dictionary = parsed
	if str(dict.get("magic", "")) != MAGIC:
		return false

	var game_port: int = int(dict.get("port", 8920))
	var key := "%s:%d" % [sender_ip, game_port]
	var now := Time.get_ticks_msec()

	var server_info: Dictionary = {
		"key": key,
		"ip": sender_ip,
		"port": game_port,
		"name": str(dict.get("name", "DARTSTORM Server")),
		"arena": int(dict.get("arena", 0)),
		"arena_name": str(dict.get("arena_name", "Backyard Fortress")),
		"mode": int(dict.get("mode", 0)),
		"mode_name": str(dict.get("mode_name", "Free-For-All")),
		"players": int(dict.get("players", 1)),
		"max_players": int(dict.get("max_players", 8)),
		"dedicated": bool(dict.get("dedicated", false)),
		"state": str(dict.get("state", "LOBBY")),
		"last_seen_msec": now,
	}

	_discovered_servers[key] = server_info
	servers_updated.emit(get_discovered_servers())
	return true


## Prunes servers that have not sent a heartbeat beacon within SERVER_TIMEOUT_MSEC.
func prune_stale_servers() -> bool:
	var now_msec := Time.get_ticks_msec()
	var keys_to_remove: Array[String] = []
	for k in _discovered_servers:
		var last_seen: int = int(_discovered_servers[k].get("last_seen_msec", 0))
		if now_msec - last_seen > SERVER_TIMEOUT_MSEC:
			keys_to_remove.append(k)

	for k in keys_to_remove:
		_discovered_servers.erase(k)

	if not keys_to_remove.is_empty():
		servers_updated.emit(get_discovered_servers())
		return true
	return false


## Test helper aliases
func _on_packet_received(pkt: PackedByteArray, sender_ip: String, _port: int = 8925) -> void:
	ingest_packet(pkt, sender_ip)


func _prune_stale_servers() -> void:
	prune_stale_servers()


func _poll_listener() -> void:
	if _listener == null or not _is_listening:
		return

	var changed := false
	while _listener.get_available_packet_count() > 0:
		var pkt := _listener.get_packet()
		var sender_ip := _listener.get_packet_ip()
		if ingest_packet(pkt, sender_ip):
			changed = true

	if prune_stale_servers():
		changed = true

	if changed:
		servers_updated.emit(get_discovered_servers())


func _resolve_arena_name(idx: int) -> String:
	if idx >= 0 and idx < MatchScene.ARENAS.size():
		return MatchScene.ARENAS[idx].get("name", "Arena %d" % idx)
	return "Arena %d" % idx


func _resolve_mode_name(idx: int) -> String:
	if idx >= 0 and idx < MatchScene.MODE_PATHS.size():
		var mode := MatchScene.resolve_mode(idx)
		if mode != null:
			return mode.short_name
	return "Mode %d" % idx
