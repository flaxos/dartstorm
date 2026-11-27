class_name DedicatedServer
extends Node
## Headless Dedicated Server controller for DARTSTORM.
## Manages server startup, CLI configuration, LAN auto-discovery, player lobbies,
## match lifecycle, automated map rotations, and headless execution.

const BANNER := """
============================================================
  DARTSTORM HEADLESS DEDICATED SERVER v1.0.0
============================================================
"""

var port: int = NetworkManager.DEFAULT_PORT
var server_name: String = "DARTSTORM Dedicated Server"
var selected_arena: int = 0
var selected_mode: int = 0
var max_players: int = NetworkManager.MAX_CLIENTS
var bot_fill: int = 0
var bot_difficulty: int = 1
var min_players_to_start: int = 1
var auto_start_delay: float = 10.0
var intermission_delay: float = 10.0
var map_rotation: Array[int] = [0, 6, 7, 8, 1, 2]  # Default rotation across classic & core maps
var rotation_index: int = 0

enum ServerState { LOBBY, COUNTDOWN, IN_MATCH, INTERMISSION }
var state: ServerState = ServerState.LOBBY
var _countdown_timer: float = 0.0
var _intermission_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "DedicatedServer"
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	_parse_cmdline_args()
	_start_server()


func _process(delta: float) -> void:
	match state:
		ServerState.COUNTDOWN:
			_countdown_timer -= delta
			if _countdown_timer <= 0.0:
				_start_match()
		ServerState.INTERMISSION:
			_intermission_timer -= delta
			if _intermission_timer <= 0.0:
				_advance_map_rotation()


func _parse_cmdline_args() -> void:
	var all_args: PackedStringArray = OS.get_cmdline_args()
	all_args.append_array(OS.get_cmdline_user_args())

	for arg in all_args:
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--name="):
			server_name = arg.trim_prefix("--name=").strip_edges().trim_prefix("\"").trim_suffix("\"")
		elif arg.begins_with("--arena="):
			selected_arena = parse_arena(arg.trim_prefix("--arena="))
		elif arg.begins_with("--mode="):
			selected_mode = parse_mode(arg.trim_prefix("--mode="))
		elif arg.begins_with("--max-players="):
			max_players = clampi(int(arg.trim_prefix("--max-players=")), 2, 16)
		elif arg.begins_with("--bot-fill="):
			bot_fill = clampi(int(arg.trim_prefix("--bot-fill=")), 0, 7)
		elif arg.begins_with("--bot-diff="):
			bot_difficulty = clampi(int(arg.trim_prefix("--bot-diff=")), 0, 2)
		elif arg.begins_with("--min-players="):
			min_players_to_start = clampi(int(arg.trim_prefix("--min-players=")), 1, 16)
		elif arg.begins_with("--auto-start="):
			auto_start_delay = maxf(1.0, float(arg.trim_prefix("--auto-start=")))
		elif arg.begins_with("--intermission="):
			intermission_delay = maxf(2.0, float(arg.trim_prefix("--intermission=")))
		elif arg.begins_with("--map-rotation="):
			map_rotation = parse_map_rotation(arg.trim_prefix("--map-rotation="))
			rotation_index = 0


func _start_server() -> void:
	var ver := str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
	print("\n============================================================\n  DARTSTORM HEADLESS DEDICATED SERVER v%s\n============================================================\n" % ver)
	NetworkManager.is_dedicated_server = true
	NetworkManager.server_name = server_name
	NetworkManager.selected_arena = selected_arena
	NetworkManager.selected_mode = selected_mode
	NetworkManager.bot_fill_count = bot_fill
	NetworkManager.bot_difficulty = bot_difficulty

	var err := NetworkManager.host_game(port, max_players, server_name, true)
	if err != OK:
		push_error("[SERVER ERROR] Could not start server on port %d (code %d)" % [port, err])
		get_tree().quit(1)
		return

	# Connect signals
	NetworkManager.peer_connected.connect(_on_peer_connected)
	NetworkManager.peer_disconnected.connect(_on_peer_disconnected)

	var arena_name: String = str(MatchScene.ARENAS[selected_arena]["name"]) if selected_arena < MatchScene.ARENAS.size() else "Arena %d" % selected_arena
	var mode_name: String = str(MatchScene.resolve_mode(selected_mode).short_name) if selected_mode < MatchScene.MODE_PATHS.size() else "Mode %d" % selected_mode

	print("  Server Name   : %s" % server_name)
	print("  WebSocket Port: %d" % port)
	print("  Discovery UDP : %d (Broadcast Active)" % LanDiscovery.DISCOVERY_PORT)
	print("  Initial Map   : %s (ID %d)" % [arena_name, selected_arena])
	print("  Initial Mode  : %s (ID %d)" % [mode_name, selected_mode])
	print("  Max Players   : %d" % max_players)
	print("  Bot Fill      : %d (Difficulty: %d)" % [bot_fill, bot_difficulty])
	print("  Map Rotation  : %s" % str(map_rotation))
	print("============================================================")
	print("[SERVER] Dedicated Server initialized and listening for connections.\n")


func _on_peer_connected(id: int) -> void:
	print("[SERVER] Peer %d connected. Current roster size: %d/%d" % [id, NetworkManager.roster.size() + 1, max_players])
	if state == ServerState.LOBBY:
		if NetworkManager.roster.size() + 1 >= min_players_to_start:
			_start_countdown()


func _on_peer_disconnected(id: int) -> void:
	print("[SERVER] Peer %d disconnected. Remaining roster: %d/%d" % [id, NetworkManager.roster.size(), max_players])
	if state == ServerState.COUNTDOWN and NetworkManager.roster.size() < min_players_to_start:
		state = ServerState.LOBBY
		print("[SERVER] Auto-start aborted: not enough players.")


func _start_countdown() -> void:
	state = ServerState.COUNTDOWN
	_countdown_timer = auto_start_delay
	print("[SERVER] Auto-start countdown initiated (%d seconds)..." % int(auto_start_delay))


func _start_match() -> void:
	state = ServerState.IN_MATCH
	print("\n[SERVER] >>> LAUNCHING MATCH: Arena %d, Mode %d, %d Players, %d Bots <<<" % [
		NetworkManager.selected_arena, NetworkManager.selected_mode, NetworkManager.roster.size(), NetworkManager.bot_fill_count
	])
	NetworkManager.launch_match()


## Called when the current active match completes on the server.
func on_match_completed(winning_banner: String) -> void:
	state = ServerState.INTERMISSION
	_intermission_timer = intermission_delay
	print("\n[SERVER] >>> MATCH COMPLETED: %s <<<" % winning_banner.replace("\n", " "))
	print("[SERVER] Intermission active (%d seconds until next rotation)..." % int(intermission_delay))


func _advance_map_rotation() -> void:
	if map_rotation.is_empty():
		map_rotation = [0]
	rotation_index = (rotation_index + 1) % map_rotation.size()
	selected_arena = map_rotation[rotation_index]
	NetworkManager.selected_arena = selected_arena

	var arena_name: String = str(MatchScene.ARENAS[selected_arena]["name"]) if selected_arena < MatchScene.ARENAS.size() else "Arena %d" % selected_arena
	print("[SERVER] Rotating map to: %s (Arena ID %d)" % [arena_name, selected_arena])

	if NetworkManager.roster.is_empty() and min_players_to_start > 0:
		state = ServerState.LOBBY
		print("[SERVER] Waiting for players before launching next match...")
	else:
		_start_match()


static func parse_arena(val: String) -> int:
	val = val.strip_edges().to_lower()
	if val.is_valid_int():
		return clampi(int(val), 0, MatchScene.ARENAS.size() - 1)
	match val:
		"backyard", "fortress": return 0
		"house", "turf", "home": return 1
		"treehouse", "tempest": return 2
		"playground": return 3
		"park", "sunny": return 4
		"soccer": return 5
		"2fort", "two_forts", "twoforts": return 6
		"dust", "dust_courtyard", "courtyard": return 7
		"dust2", "duststorm", "duststorm2": return 8
	return 0


static func parse_mode(val: String) -> int:
	val = val.strip_edges().to_lower()
	if val.is_valid_int():
		return clampi(int(val), 0, MatchScene.MODE_PATHS.size() - 1)
	match val:
		"ffa", "free_for_all": return GameSettings.MatchMode.FREE_FOR_ALL
		"gun_game", "gungame": return GameSettings.MatchMode.GUN_GAME
		"duos": return GameSettings.MatchMode.DUOS
		"teams", "tdm": return GameSettings.MatchMode.TEAMS
		"zombies", "infection": return GameSettings.MatchMode.ZOMBIES
		"zombie_siege", "siege": return GameSettings.MatchMode.ZOMBIE_SIEGE
		"lava", "floor_is_lava": return GameSettings.MatchMode.FLOOR_IS_LAVA
		"realistic": return GameSettings.MatchMode.REALISTIC
		"ctf", "capture_the_flag": return GameSettings.MatchMode.CAPTURE_THE_FLAG
		"bomb", "plant_the_bomb", "sd": return GameSettings.MatchMode.PLANT_THE_BOMB
	return 0


static func parse_map_rotation(val: String) -> Array[int]:
	var result: Array[int] = []
	var parts := val.split(",")
	for p in parts:
		p = p.strip_edges()
		if not p.is_empty():
			result.append(parse_arena(p))
	if result.is_empty():
		result = [0]
	return result
