extends SceneTree
## Strict compile check, run by tools/validate.sh in two steps:
##
## 1. `godot --headless --path . -s res://tools/check_scripts.gd -- --print-strict-override`
##    prints every GDScript warning that is currently set to "Warn", as
##    override.cfg lines that raise it to "Error". (Godot 4 has no single
##    "treat warnings as errors" switch; each warning has its own level.)
## 2. With that written to a temporary override.cfg, running this script again
##    recompiles every GDScript in the project. A warning that would show up
##    yellow in the editor now fails validation. It exits 1 if any script fails.

const ROOTS := ["res://scripts", "res://tests", "res://tools"]
const WARNING_PREFIX := "debug/gdscript/warnings/"
const LEVEL_WARN := 1
const LEVEL_ERROR := 2


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--print-strict-override"):
		_print_strict_override()
		quit(0)
		return
	var paths: Array[String] = []
	for folder: String in ROOTS:
		_collect(folder, paths)
	var broken := 0
	for path in paths:
		var script := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			broken += 1
			print("BROKEN SCRIPT: ", path)
	print("Checked %d scripts, %d with errors or warnings." % [paths.size(), broken])
	quit(1 if broken > 0 else 0)


func _print_strict_override() -> void:
	print("[debug]")
	for property in ProjectSettings.get_property_list():
		var setting: String = property["name"]
		if not setting.begins_with(WARNING_PREFIX):
			continue
		var value: Variant = ProjectSettings.get_setting(setting)
		if typeof(value) == TYPE_INT and int(value) == LEVEL_WARN:
			print("%s=%d" % [setting.trim_prefix("debug/"), LEVEL_ERROR])


func _collect(dir_path: String, out: Array[String]) -> void:
	for file_name in DirAccess.get_files_at(dir_path):
		var path := dir_path.path_join(file_name)
		# Reloading the script that is running right now would break it.
		if file_name.ends_with(".gd") and path != get_script().resource_path:
			out.append(path)
	for sub in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(sub), out)
