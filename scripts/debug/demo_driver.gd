class_name DemoDriver
extends Node
## Development helper, only active when the game is launched with `-- --demo`.
## It plays the human's part automatically (turning, firing, cycling blasters)
## and can save screenshots, so the game can be checked without hands on keys:
##
##     godot --path . res://scenes/game/match.tscn -- --demo --shots=captures --quit-after=12
##
## Nothing here runs in a normal play session.

var _player: Player
var _time: float = 0.0
var _shot_dir: String = ""
var _shot_times: Array[float] = [1.0, 4.5, 6.0, 8.0, 10.0, 11.5]
var _next_shot: int = 0
var _quit_after: float = 0.0
var _weapon_clock: float = 0.0


func _ready() -> void:
	_player = get_parent().get("player") as Player
	if _player != null and _player.arsenal.weapons.size() > 2:
		_player.arsenal.select(2, true)  # Start on the Chainstorm.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):
			_shot_dir = argument.trim_prefix("--shots=")
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
		elif argument.begins_with("--quit-after="):
			_quit_after = float(argument.trim_prefix("--quit-after="))


func _physics_process(delta: float) -> void:
	_time += delta
	if _player != null and _player.alive and _player.controls_enabled:
		_player.rotate_y(delta * 0.5)
		_player.head.rotation.x = sin(_time * 0.7) * 0.12
		# Drive the real input actions so this exercises the same path as a human.
		if fmod(_time, 0.5) < 0.38:
			Input.action_press(&"fire")
		else:
			Input.action_release(&"fire")
		Input.action_press(&"move_forward")
		_weapon_clock += delta
		if _weapon_clock > 2.6:
			_weapon_clock = 0.0
			_player.arsenal.cycle(1)
	if not _shot_dir.is_empty() and _next_shot < _shot_times.size() and _time >= _shot_times[_next_shot]:
		_save_shot()
		_next_shot += 1
	if _quit_after > 0.0 and _time >= _quit_after:
		get_tree().quit()


func _exit_tree() -> void:
	Input.action_release(&"fire")
	Input.action_release(&"move_forward")


func _save_shot() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var image := get_viewport().get_texture().get_image()
	var path := "%s/shot_%02d.png" % [_shot_dir, _next_shot]
	image.save_png(path)
	print("DemoDriver: saved ", path)
