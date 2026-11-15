extends Node
## Autoload "GameSettings": player preferences plus the last match options chosen in
## the menu. Saved to user://settings.cfg. Everything visual/audio reads from here.

signal changed

const SAVE_PATH := "user://settings.cfg"
## Bump when the meaning of a saved value changes, then migrate in load_settings().
const SETTINGS_VERSION := 1
## Factory values for every preference. "Reset to defaults" restores these.
const DEFAULTS := {
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"fov": 85.0,
	"camera_shake": 1.0,
	"visual_intensity": 1.0,
	"master_volume": 0.8,
	"fullscreen": false,
}

enum MatchMode { FREE_FOR_ALL, GUN_GAME }

# --- Preferences ---
var mouse_sensitivity: float = 1.0
var invert_y: bool = false
var fov: float = 85.0
## 0 = no camera shake at all, 1 = default.
var camera_shake: float = 1.0
## Scales particle counts and flash strength. 1 = default.
var visual_intensity: float = 1.0
var master_volume: float = 0.8
var fullscreen: bool = false

# --- Match options (picked on the main menu) ---
var match_mode: int = MatchMode.FREE_FOR_ALL
var bot_count: int = 3
## Index into Match.DIFFICULTY_PATHS: 0 easy, 1 normal, 2 hard.
var bot_difficulty: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure_actions()
	load_settings()
	apply()


func apply() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	if DisplayServer.get_name() != "headless":
		var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen and not is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not fullscreen and is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


## Puts every preference (not the match options) back to its factory value.
## Call apply() afterwards; saving happens when the settings screen closes.
func reset_to_defaults() -> void:
	for key: String in DEFAULTS:
		set(key, DEFAULTS[key])


## True when every preference equals its factory value.
func is_default() -> bool:
	for key: String in DEFAULTS:
		if get(key) != DEFAULTS[key]:
			return false
	return true


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # First run, or an unreadable file: keep the defaults.
	if int(file.get_value("meta", "version", SETTINGS_VERSION)) > SETTINGS_VERSION:
		push_warning("Settings were saved by a newer DARTSTORM; loading what we understand.")
	mouse_sensitivity = clampf(float(file.get_value("controls", "mouse_sensitivity", mouse_sensitivity)), 0.1, 4.0)
	invert_y = bool(file.get_value("controls", "invert_y", invert_y))
	fov = clampf(float(file.get_value("video", "fov", fov)), 60.0, 110.0)
	camera_shake = clampf(float(file.get_value("video", "camera_shake", camera_shake)), 0.0, 1.5)
	visual_intensity = clampf(float(file.get_value("video", "visual_intensity", visual_intensity)), 0.2, 1.5)
	fullscreen = bool(file.get_value("video", "fullscreen", fullscreen))
	master_volume = clampf(float(file.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	match_mode = clampi(int(file.get_value("match", "mode", match_mode)), 0, 1)
	bot_count = clampi(int(file.get_value("match", "bot_count", bot_count)), 2, 5)
	bot_difficulty = clampi(int(file.get_value("match", "bot_difficulty", bot_difficulty)), 0, 2)


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("meta", "version", SETTINGS_VERSION)
	file.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("controls", "invert_y", invert_y)
	file.set_value("video", "fov", fov)
	file.set_value("video", "camera_shake", camera_shake)
	file.set_value("video", "visual_intensity", visual_intensity)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("audio", "master_volume", master_volume)
	file.set_value("match", "mode", match_mode)
	file.set_value("match", "bot_count", bot_count)
	file.set_value("match", "bot_difficulty", bot_difficulty)
	var err := file.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save settings (error %d)" % err)
