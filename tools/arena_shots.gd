extends SceneTree
## Saves overview screenshots of an arena from above and from each corner, so
## a layout can be checked by eye. Needs a display (don't pass --headless):
##
##     godot --path . -s res://tools/arena_shots.gd -- --arena=1 --shots=/abs/dir
##
## --arena is an index into MatchScene.ARENAS (0 Backyard, 1 Home Turf).
## Optional --look=x,y,z:tx,ty,tz adds one more shot from x,y,z looking at tx,ty,tz.

const POSES := [
	[Vector3(0.0, 120.0, 30.0), Vector3(0.0, 0.0, -2.0)],
	[Vector3(70.0, 55.0, 75.0), Vector3(-4.0, 0.0, -4.0)],
	[Vector3(-70.0, 55.0, 75.0), Vector3(-4.0, 0.0, -4.0)],
	[Vector3(70.0, 55.0, -80.0), Vector3(-4.0, 0.0, -4.0)],
	[Vector3(-70.0, 55.0, -80.0), Vector3(-4.0, 0.0, -4.0)],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena_index := 0
	var out_dir := ""
	var poses: Array = POSES.duplicate()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--arena="):
			arena_index = int(argument.trim_prefix("--arena="))
		elif argument.begins_with("--shots="):
			out_dir = argument.trim_prefix("--shots=")
		elif argument.begins_with("--look="):
			var parts := argument.trim_prefix("--look=").split(":")
			poses.append([_vec(parts[0]), _vec(parts[1])])
	if out_dir.is_empty():
		push_error("Pass --shots=<absolute directory>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	# Game classes load at runtime: -s scripts compile before autoloads exist.
	var match_script := load("res://scripts/core/match.gd")
	var path: String = match_script.call(&"arena_path", arena_index)
	var arena := (load(path) as PackedScene).instantiate() as Node3D
	arena.set(&"bake_navigation", false)
	root.add_child(arena)
	var camera := Camera3D.new()
	camera.fov = 55.0
	camera.far = 600.0
	root.add_child(camera)
	camera.current = true
	for i in poses.size():
		camera.position = poses[i][0]
		camera.look_at(poses[i][1], Vector3.UP)
		for frame in 8:
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var file := "%s/arena_%d_%02d.png" % [out_dir, arena_index, i]
		image.save_png(file)
		print("arena_shots: saved ", file)
	root.get_node("Sfx").call(&"quit_game")


func _vec(text: String) -> Vector3:
	var numbers := text.split(",")
	return Vector3(float(numbers[0]), float(numbers[1]), float(numbers[2]))
