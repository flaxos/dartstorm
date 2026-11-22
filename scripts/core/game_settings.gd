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
	"game_speed": 0.90,
	"weather_events": true,
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"team_palette": 0,
	"split_screen_horizontal": true,
	"touch_controls_mode": 0,
	"touch_look_sensitivity": 1.0,
	"touch_fire_mode": 1,
	"touch_fire_btn_size": 1.0,
	"graphics_quality": 2,
}
const NOTICE_SECONDS := 3.0
## The bots slider on the menu. Team modes may add one more to even the teams.
const MIN_BOTS := 2
const MAX_BOTS := 7

## Saved as numbers, so only ever add to the end.
enum MatchMode { FREE_FOR_ALL, GUN_GAME, DUOS, TEAMS, ZOMBIES, ZOMBIE_SIEGE, FLOOR_IS_LAVA, REALISTIC, CAPTURE_THE_FLAG, PLANT_THE_BOMB }
enum TouchMode { AUTO, ALWAYS, OFF }
enum TouchFireMode { AIM_AND_TAP, HOLD_AND_AIM }
enum GraphicsQuality { LOW, MEDIUM, HIGH, ULTRA }
const GRAPHICS_QUALITY_NAMES := ["Low (Performance)", "Medium (Balanced)", "High (AAA Quality)", "Ultra (Cinematic)"]

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
## Scales gameplay speed (0.70 to 1.10). 0.90 = slightly relaxed for kids.
var game_speed: float = 0.90:
	set(value):
		game_speed = clampf(value, 0.70, 1.10)
var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 1.0
var fullscreen: bool = false
## Colorblind team color palette (GameMode.TeamPalette).
var team_palette: int = 0
## Touch controls on-screen overlay mode (Auto, Always On, Off)
var touch_controls_mode: int = TouchMode.AUTO
var touch_look_sensitivity: float = 1.0
## Touch firing style: 0 = AIM_AND_TAP (split swipe + tap), 1 = HOLD_AND_AIM (hold to auto-fire & drag to aim)
var touch_fire_mode: int = TouchFireMode.HOLD_AND_AIM
## Multiplier for touch fire button size (0.85 = compact, 1.0 = standard 104px, 1.2 = large 120px)
var touch_fire_btn_size: float = 1.0
## Graphics quality preset: 0 = Low, 1 = Medium, 2 = High, 3 = Ultra
var graphics_quality: int = GraphicsQuality.HIGH
var _touch_detected: bool = false

# --- Your player (Player 1) ---
## Empty means "You".
var player_name: String = ""
var player_color: int = 0
var player_hat: StringName = &"cap"
var player_skin: StringName = &"default"

# --- Player 2 (Local Split-Screen) ---
var player2_name: String = "Player 2"
var player2_color: int = 1
var player2_hat: StringName = &"beanie"
var player2_skin: StringName = &"default"

# --- Match options (picked on the main menu) ---
var match_mode: int = MatchMode.FREE_FOR_ALL
var bot_count: int = 3
## Index into MatchScene.DIFFICULTY_PATHS: 0 easy, 1 normal, 2 hard.
var bot_difficulty: int = 1
## Backyard Battle only: the Chainstorm is a map power-up instead of a starting blaster.
var chainstorm_powerup: bool = false
## Dynamic weather events (thunderstorms, blizzards, gale gusts, heatwaves).
var weather_events: bool = true
## Index into MatchScene.ARENAS: 0 Backyard Fortress, 1 Home Turf.
var arena: int = 0
## 2-player local split-screen couch co-op/versus.
var split_screen: bool = false
## Horizontal (top/bottom) if true, Vertical (side-by-side) if false.
var split_screen_horizontal: bool = true

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
	if get_tree() != null and get_tree().current_scene != null and get_tree().current_scene.name == "Match":
		Engine.time_scale = game_speed
	_apply_graphics_quality()
	changed.emit()


func _apply_graphics_quality() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var vp := get_viewport()
	if vp == null:
		return
	match graphics_quality:
		GraphicsQuality.LOW:
			vp.scaling_3d_scale = 0.85
			vp.msaa_3d = Viewport.MSAA_DISABLED
		GraphicsQuality.MEDIUM:
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_DISABLED
		GraphicsQuality.HIGH:
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_2X
		GraphicsQuality.ULTRA:
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_4X


## The name shown in the tag feed and scoreboard.
func display_name() -> String:
	var clean := Cosmetics.sanitize_name(player_name)
	return clean if not clean.is_empty() else "You"


func color() -> Color:
	return Cosmetics.color_at(player_color)


func display_name_p2() -> String:
	var clean := Cosmetics.sanitize_name(player2_name)
	return clean if not clean.is_empty() else "Player 2"


func color_p2() -> Color:
	return Cosmetics.color_at(player2_color)


## Whether on-screen touch controls should be shown and active.
func is_touch_active() -> bool:
	match touch_controls_mode:
		TouchMode.ALWAYS:
			return true
		TouchMode.OFF:
			return false
		TouchMode.AUTO:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				return false
			return OS.has_feature("mobile") \
				or OS.has_feature("web_android") \
				or OS.has_feature("web_ios") \
				or _touch_detected
	return false


func register_touch_event() -> void:
	if not _touch_detected:
		_touch_detected = true
		changed.emit()


func reset_touch_detection() -> void:
	if _touch_detected:
		_touch_detected = false
		changed.emit()


## Puts every preference (not your look or the match options) back to its
## factory value. Call apply() afterwards; saving happens when the settings
## screen closes.
func reset_to_defaults() -> void:
	_touch_detected = false
	for key: String in DEFAULTS:
		set(key, DEFAULTS[key])
	InputSetup.reset_to_defaults()


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
	graphics_quality = clampi(int(file.get_value("video", "graphics_quality", graphics_quality)), 0, GraphicsQuality.size() - 1)
	game_speed = clampf(float(file.get_value("gameplay", "game_speed", game_speed)), 0.70, 1.10)
	master_volume = clampf(float(file.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(file.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(file.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	player_name = Cosmetics.sanitize_name(str(file.get_value("player", "name", player_name)))
	player_color = clampi(int(file.get_value("player", "color", player_color)), 0, Cosmetics.COLORS.size() - 1)
	var hat := StringName(str(file.get_value("player", "hat", player_hat)))
	player_hat = hat if Cosmetics.has_hat(hat) else &"cap"
	var skin := StringName(str(file.get_value("player", "skin", player_skin)))
	player_skin = skin if Cosmetics.has_skin(skin) else &"default"
	match_mode = clampi(int(file.get_value("match", "mode", match_mode)), 0, MatchMode.size() - 1)
	bot_count = clampi(int(file.get_value("match", "bot_count", bot_count)), MIN_BOTS, MAX_BOTS)
	bot_difficulty = clampi(int(file.get_value("match", "bot_difficulty", bot_difficulty)), 0, 2)
	chainstorm_powerup = bool(file.get_value("match", "chainstorm_powerup", chainstorm_powerup))
	weather_events = bool(file.get_value("match", "weather_events", weather_events))
	arena = maxi(int(file.get_value("match", "arena", arena)), 0)  # MatchScene clamps it to the arenas that exist.
	split_screen = bool(file.get_value("split_screen", "enabled", split_screen))
	split_screen_horizontal = bool(file.get_value("split_screen", "horizontal", split_screen_horizontal))
	player2_name = Cosmetics.sanitize_name(str(file.get_value("player2", "name", player2_name)))
	player2_color = clampi(int(file.get_value("player2", "color", player2_color)), 0, Cosmetics.COLORS.size() - 1)
	var hat2 := StringName(str(file.get_value("player2", "hat", player2_hat)))
	player2_hat = hat2 if Cosmetics.has_hat(hat2) else &"beanie"
	var skin2 := StringName(str(file.get_value("player2", "skin", player2_skin)))
	player2_skin = skin2 if Cosmetics.has_skin(skin2) else &"default"
	team_palette = clampi(int(file.get_value("accessibility", "team_palette", team_palette)), 0, GameMode.TeamPalette.size() - 1)
	touch_controls_mode = clampi(int(file.get_value("controls", "touch_controls_mode", touch_controls_mode)), 0, TouchMode.size() - 1)
	touch_look_sensitivity = clampf(float(file.get_value("controls", "touch_look_sensitivity", touch_look_sensitivity)), 0.2, 3.0)
	touch_fire_mode = clampi(int(file.get_value("controls", "touch_fire_mode", touch_fire_mode)), 0, TouchFireMode.size() - 1)
	touch_fire_btn_size = clampf(float(file.get_value("controls", "touch_fire_btn_size", touch_fire_btn_size)), 0.8, 1.4)
	if file.has_section("bindings"):
		var raw_bindings: Dictionary = {}
		for action: String in file.get_section_keys("bindings"):
			raw_bindings[action] = file.get_value("bindings", action)
		InputSetup.apply_serialized_bindings(raw_bindings)


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("meta", "version", SETTINGS_VERSION)
	file.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("controls", "controller_look_speed", controller_look_speed)
	file.set_value("controls", "invert_y", invert_y)
	file.set_value("controls", "aim_assist", aim_assist)
	file.set_value("controls", "vibration", vibration)
	file.set_value("controls", "touch_controls_mode", touch_controls_mode)
	file.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	file.set_value("controls", "touch_fire_mode", touch_fire_mode)
	file.set_value("controls", "touch_fire_btn_size", touch_fire_btn_size)
	file.set_value("video", "fov", fov)
	file.set_value("video", "camera_shake", camera_shake)
	file.set_value("video", "visual_intensity", visual_intensity)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "graphics_quality", graphics_quality)
	file.set_value("gameplay", "game_speed", game_speed)
	file.set_value("audio", "master_volume", master_volume)
	file.set_value("audio", "music_volume", music_volume)
	file.set_value("audio", "sfx_volume", sfx_volume)
	file.set_value("player", "name", Cosmetics.sanitize_name(player_name))
	file.set_value("player", "color", player_color)
	file.set_value("player", "hat", String(player_hat))
	file.set_value("player", "skin", String(player_skin))
	file.set_value("player2", "name", Cosmetics.sanitize_name(player2_name))
	file.set_value("player2", "color", player2_color)
	file.set_value("player2", "hat", String(player2_hat))
	file.set_value("player2", "skin", String(player2_skin))
	file.set_value("match", "mode", match_mode)
	file.set_value("match", "bot_count", bot_count)
	file.set_value("match", "bot_difficulty", bot_difficulty)
	file.set_value("match", "chainstorm_powerup", chainstorm_powerup)
	file.set_value("match", "weather_events", weather_events)
	file.set_value("match", "arena", arena)
	file.set_value("split_screen", "enabled", split_screen)
	file.set_value("split_screen", "horizontal", split_screen_horizontal)
	file.set_value("accessibility", "team_palette", team_palette)
	var serialized_bindings := InputSetup.serialize_bindings()
	for action: String in serialized_bindings:
		file.set_value("bindings", action, serialized_bindings[action])
	var err := file.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save settings (error %d)" % err)
