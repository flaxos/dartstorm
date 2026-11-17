extends Node
## Autoload "GameSettings": player preferences, the player's look (name, colour,
## hat), the last match options chosen in the menu, and input-device awareness
## (controller hot-plug notices, rumble, "is a pad being used right now?").
## Saved to user://settings.cfg, which stays on this computer.

signal changed
## A controller was plugged in or unplugged.
signal controller_changed(device: int, connected: bool, pad_name: String)
## The player switched between keyboard/mouse and a controller.
signal input_device_changed(using_controller: bool)

const SAVE_PATH := "user://settings.cfg"
## Bump when the meaning of a saved value changes, then migrate in load_settings().
const SETTINGS_VERSION := 2
## Factory values for every preference. "Reset to defaults" restores these
## (not your name, colour or hat, and not the match options).
const DEFAULTS := {
	"mouse_sensitivity": 1.0,
	"controller_look_speed": 1.0,
	"invert_y": false,
	"aim_assist": true,
	"vibration": true,
	"fov": 85.0,
	"camera_shake": 1.0,
	"visual_intensity": 1.0,
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 1.0,
	"fullscreen": false,
}
const NOTICE_SECONDS := 3.0
## The bots slider on the menu. Team modes may add one more to even the teams.
const MIN_BOTS := 2
const MAX_BOTS := 7

## Saved as numbers, so only ever add to the end.
enum MatchMode { FREE_FOR_ALL, GUN_GAME, DUOS, TEAMS, ZOMBIES }

# --- Preferences ---
var mouse_sensitivity: float = 1.0
## Right-stick turning speed multiplier.
var controller_look_speed: float = 1.0
var invert_y: bool = false
## Controller only: turning slows slightly while the crosshair is over a rival.
var aim_assist: bool = true
## Controller rumble on shots, hits and tags.
var vibration: bool = true
var fov: float = 85.0
## 0 = no camera shake at all, 1 = default.
var camera_shake: float = 1.0
## Scales particle counts and flash strength. 1 = default.
var visual_intensity: float = 1.0
var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 1.0
var fullscreen: bool = false

# --- Your player ---
## Empty means "You".
var player_name: String = ""
var player_color: int = 0
var player_hat: StringName = &"cap"

# --- Match options (picked on the main menu) ---
var match_mode: int = MatchMode.FREE_FOR_ALL
var bot_count: int = 3
## Index into MatchScene.DIFFICULTY_PATHS: 0 easy, 1 normal, 2 hard.
var bot_difficulty: int = 1
## Backyard Battle only: the Chainstorm is a map power-up instead of a starting blaster.
var chainstorm_powerup: bool = false
## Index into MatchScene.ARENAS: 0 Backyard Fortress, 1 Home Turf.
var arena: int = 0

## True while the last input came from a controller.
var using_controller: bool = false

var _notice_layer: CanvasLayer
var _notice_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure_actions()
	load_settings()
	_apply_demo_overrides()
	apply()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	using_controller = not Input.get_connected_joypads().is_empty()
	# Every Control in the game (text boxes included) defaults to the chunky font.
	# Done here rather than in project.godot so a fresh checkout imports cleanly.
	var theme := Theme.new()
	theme.default_font = UiKit.font()
	get_tree().root.theme = theme


## Screenshot runs only (`-- --demo --mode=3 --bots=5 --arena=1`): pick the mode,
## bot count and arena from the command line.
func _apply_demo_overrides() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--demo"):
		return
	for argument in args:
		if argument.begins_with("--mode="):
			match_mode = clampi(int(argument.trim_prefix("--mode=")), 0, MatchMode.size() - 1)
		elif argument.begins_with("--bots="):
			bot_count = clampi(int(argument.trim_prefix("--bots=")), MIN_BOTS, MAX_BOTS)
		elif argument.begins_with("--arena="):
			arena = maxi(int(argument.trim_prefix("--arena=")), 0)


func _input(event: InputEvent) -> void:
	var pad := event is InputEventJoypadButton or (event is InputEventJoypadMotion
			and absf((event as InputEventJoypadMotion).axis_value) > 0.4)
	var desk := event is InputEventKey or event is InputEventMouseButton \
			or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 2.0)
	if pad and not using_controller:
		using_controller = true
		input_device_changed.emit(true)
	elif desk and using_controller:
		using_controller = false
		input_device_changed.emit(false)


func apply() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sfx_volume)
	if DisplayServer.get_name() != "headless":
		var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen and not is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not fullscreen and is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


## The name shown in the tag feed and scoreboard.
func display_name() -> String:
	var clean := Cosmetics.sanitize_name(player_name)
	return clean if not clean.is_empty() else "You"


func color() -> Color:
	return Cosmetics.color_at(player_color)


## Puts every preference (not your look or the match options) back to its
## factory value. Call apply() afterwards; saving happens when the settings
## screen closes.
func reset_to_defaults() -> void:
	for key: String in DEFAULTS:
		set(key, DEFAULTS[key])


## True when every preference equals its factory value.
func is_default() -> bool:
	for key: String in DEFAULTS:
		if get(key) != DEFAULTS[key]:
			return false
	return true


## Rumbles every connected controller, if rumble is on and a pad is in use.
func vibrate(weak: float, strong: float, seconds: float) -> void:
	if not vibration or not using_controller:
		return
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), seconds)


## Shows a small message in the top-right corner of any screen.
func notify(text: String) -> void:
	if _notice_layer == null:
		_notice_layer = CanvasLayer.new()
		_notice_layer.layer = 60
		add_child(_notice_layer)
		_notice_box = VBoxContainer.new()
		_notice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_notice_layer.add_child(_notice_box)
		UiKit.pin(_notice_box, Vector2(0.5, 1.0), Vector2(0, -120), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	var panel := UiKit.panel(UiKit.NAVY, 0.92, 14, 3, UiKit.SKY, 10)
	panel.add_child(UiKit.label(text, 20, UiKit.CREAM, 5))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_notice_box.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(NOTICE_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func notice_count() -> int:
	return _notice_box.get_child_count() if _notice_box != null else 0


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	var pad_name := Input.get_joy_name(device) if connected else ""
	if pad_name.is_empty():
		pad_name = "Controller"
	if connected:
		notify("%s connected - ready to play!" % pad_name)
		Sfx.play(&"connect")
		using_controller = true
		input_device_changed.emit(true)
	else:
		notify("Controller disconnected")
		Sfx.play(&"disconnect")
		if Input.get_connected_joypads().is_empty() and using_controller:
			using_controller = false
			input_device_changed.emit(false)
	controller_changed.emit(device, connected, pad_name)


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(bus, linear <= 0.001)


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # First run, or an unreadable file: keep the defaults.
	if int(file.get_value("meta", "version", SETTINGS_VERSION)) > SETTINGS_VERSION:
		push_warning("Settings were saved by a newer DARTSTORM; loading what we understand.")
	mouse_sensitivity = clampf(float(file.get_value("controls", "mouse_sensitivity", mouse_sensitivity)), 0.1, 4.0)
	controller_look_speed = clampf(float(file.get_value("controls", "controller_look_speed", controller_look_speed)), 0.3, 2.5)
	invert_y = bool(file.get_value("controls", "invert_y", invert_y))
	aim_assist = bool(file.get_value("controls", "aim_assist", aim_assist))
	vibration = bool(file.get_value("controls", "vibration", vibration))
	fov = clampf(float(file.get_value("video", "fov", fov)), 60.0, 110.0)
	camera_shake = clampf(float(file.get_value("video", "camera_shake", camera_shake)), 0.0, 1.5)
	visual_intensity = clampf(float(file.get_value("video", "visual_intensity", visual_intensity)), 0.2, 1.5)
	fullscreen = bool(file.get_value("video", "fullscreen", fullscreen))
	master_volume = clampf(float(file.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(file.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(file.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	player_name = Cosmetics.sanitize_name(str(file.get_value("player", "name", player_name)))
	player_color = clampi(int(file.get_value("player", "color", player_color)), 0, Cosmetics.COLORS.size() - 1)
	var hat := StringName(str(file.get_value("player", "hat", player_hat)))
	player_hat = hat if Cosmetics.has_hat(hat) else &"cap"
	match_mode = clampi(int(file.get_value("match", "mode", match_mode)), 0, MatchMode.size() - 1)
	bot_count = clampi(int(file.get_value("match", "bot_count", bot_count)), MIN_BOTS, MAX_BOTS)
	bot_difficulty = clampi(int(file.get_value("match", "bot_difficulty", bot_difficulty)), 0, 2)
	chainstorm_powerup = bool(file.get_value("match", "chainstorm_powerup", chainstorm_powerup))
	arena = maxi(int(file.get_value("match", "arena", arena)), 0)  # MatchScene clamps it to the arenas that exist.


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("meta", "version", SETTINGS_VERSION)
	file.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("controls", "controller_look_speed", controller_look_speed)
	file.set_value("controls", "invert_y", invert_y)
	file.set_value("controls", "aim_assist", aim_assist)
	file.set_value("controls", "vibration", vibration)
	file.set_value("video", "fov", fov)
	file.set_value("video", "camera_shake", camera_shake)
	file.set_value("video", "visual_intensity", visual_intensity)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("audio", "master_volume", master_volume)
	file.set_value("audio", "music_volume", music_volume)
	file.set_value("audio", "sfx_volume", sfx_volume)
	file.set_value("player", "name", Cosmetics.sanitize_name(player_name))
	file.set_value("player", "color", player_color)
	file.set_value("player", "hat", String(player_hat))
	file.set_value("match", "mode", match_mode)
	file.set_value("match", "bot_count", bot_count)
	file.set_value("match", "bot_difficulty", bot_difficulty)
	file.set_value("match", "chainstorm_powerup", chainstorm_powerup)
	file.set_value("match", "arena", arena)
	var err := file.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save settings (error %d)" % err)
