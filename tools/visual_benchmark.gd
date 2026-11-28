extends SceneTree
## Fixed-camera visual benchmark harness for v2.0.0 Cover-Art Parity verification.
## Captures 6 standardized 1280x720 Forward+ shots into --shots=<dir> (defaults to user://visual_benchmark):
##   1. lobby_heroes.png             - 3D squad bunker lobby close-up (heroes, hats, faces, outlines)
##   2. fp_blaster_hands.png         - First-person sculpted blaster + cartoon hoodie hands + Tactical HUD
##   3. fp_bat_swing.png             - First-person Foam Bat mid-swing + Backyard BatPickup
##   4. backyard_fort_vista.png      - Backyard Fortress treehouse, yellow slide, glowing mirrors & Windy Way
##   5. elemental_trails_showcase.png- Mid-air showcase of Wind, Fire, Water, Lightning & Ice dart trails
##   6. dust2_and_stadium.png        - Stylized Duststorm II warm golden-hour showcase
##
## Usage:
##   godot --path . -s res://tools/visual_benchmark.gd -- --shots=/tmp/dartstorm_bench

var _out_dir: String = ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_out_dir = arg.substr(8)
	if _out_dir.is_empty():
		_out_dir = ProjectSettings.globalize_path("user://visual_benchmark")
	_run.call_deferred()


func _snap(filename: String, wait_frames: int = 12) -> void:
	for i in wait_frames:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(filename)
	img.save_png(path)
	print("Benchmark saved: ", path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var match_script := load("res://scripts/core/match.gd")
	var gs := root.get_node("GameSettings")

	# 1. Lobby Heroes Close-Up
	gs.set(&"arena", 0)
	gs.set(&"match_mode", 0)
	gs.set(&"bot_count", 4)
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _snap("lobby_heroes.png", 35)
	menu.queue_free()
	for i in 6:
		await process_frame

	# 2. First-Person Blaster + Hands in Live Backyard Match
	gs.set(&"arena", 0)
	gs.set(&"match_mode", 0)
	gs.set(&"bot_count", 5)
	var match_node := (load("res://scenes/game/match.tscn") as PackedScene).instantiate()
	root.add_child(match_node)
	for i in 210:
		await physics_frame
	var player: Node = match_node.get("player")
	if player != null:
		var arsenal: Node = player.get("arsenal")
		if arsenal != null:
			arsenal.call(&"select", 2, true)  # Flax's Chainstorm hero weapon
	await _snap("fp_blaster_hands.png", 14)
	match_node.queue_free()
	for i in 8:
		await process_frame

	# 3. First-Person Foam Bat Swing + Backyard Treehouse/Mirrors/Wind Vista
	var backyard := (load(match_script.call(&"arena_path", 0)) as PackedScene).instantiate() as Node3D
	backyard.set(&"bake_navigation", false)
	root.add_child(backyard)

	var bp := (load("res://scripts/systems/bat_pickup.gd") as GDScript).new() as Node3D
	backyard.add_child(bp)
	bp.global_position = Vector3(-9.0, 0.0, -13.0)
	bp.call(&"make_available")

	var cam := Camera3D.new()
	cam.near = 0.04
	cam.fov = 78.0
	cam.position = Vector3(-7.0, 1.75, -7.0)
	root.add_child(cam)
	cam.current = true
	cam.look_at(Vector3(-9.5, 1.9, -18.0), Vector3.UP)

	var bm_script := load("res://scripts/effects/blaster_model.gd")
	var fx_script := load("res://scripts/effects/combat_fx.gd")
	var bat_data := load("res://resources/weapons/foam_bat.tres")
	var bat_fp: Node3D = bm_script.call(&"create", bat_data, true, &"default", {})
	cam.add_child(bat_fp)
	bat_fp.position = bat_data.view_offset
	bat_fp.call(&"swing")
	fx_script.call(&"spawn_comic_starburst", backyard, Vector3(-9.2, 2.2, -13.0), "BONK!", Color(1.0, 0.85, 0.16), 1.15)
	for i in 10:
		await process_frame
	await _snap("fp_bat_swing.png", 2)
	bat_fp.queue_free()

	# 4. Backyard Fortress Vista (Treehouse, Yellow Slide, Mirror Alley, Windy Way)
	cam.position = Vector3(-18.0, 7.5, 16.0)
	cam.look_at(Vector3(2.0, 2.8, -6.0), Vector3.UP)
	await _snap("backyard_fort_vista.png", 14)

	# 5. Elemental Trails Showcase (All 5 Elemental Darts Flying Side-by-Side Across Open Sky)
	var pool := (load("res://scripts/combat/dart_pool.gd") as GDScript).new() as Node3D
	backyard.add_child(pool)
	await physics_frame
	cam.position = Vector3(-11.5, 9.2, -7.5)
	cam.look_at(Vector3(-12.5, 8.0, -16.5), Vector3.UP)
	var dart_files := [
		"res://resources/darts/wind_dart.tres",
		"res://resources/darts/fire_dart.tres",
		"res://resources/darts/water_dart.tres",
		"res://resources/darts/lightning_dart.tres",
		"res://resources/darts/ice_dart.tres",
	]
	var tints := [
		Color(0.55, 0.92, 1.0),
		Color(1.0, 0.50, 0.10),
		Color(0.18, 0.80, 1.0),
		Color(1.0, 0.94, 0.20),
		Color(0.75, 0.96, 1.0),
	]
	var no_exclude: Array[RID] = []
	for idx in dart_files.size():
		var ddata := load(dart_files[idx])
		var start_pos := Vector3(-17.5 + float(idx) * 2.2, 8.4 + float(idx % 2) * 0.55, -11.5)
		pool.call(&"fire", ddata, start_pos, Vector3(0.35, 0.02, -0.94).normalized(), null, null, tints[idx], no_exclude)
	fx_script.call(&"spawn_comic_starburst", backyard, Vector3(-12.5, 10.6, -15.5), "DEFLECT!", Color(0.24, 0.94, 1.0), 1.1)
	for i in 5:
		await physics_frame
	await _snap("elemental_trails_showcase.png", 2)
	backyard.queue_free()
	cam.queue_free()
	for i in 6:
		await process_frame

	# 6. Duststorm II Stylized Desert Golden-Hour Showcase + Soccer Stadium
	var dust2 := (load(match_script.call(&"arena_path", 8)) as PackedScene).instantiate() as Node3D
	dust2.set(&"bake_navigation", false)
	root.add_child(dust2)
	var cam2 := Camera3D.new()
	cam2.fov = 74.0
	cam2.position = Vector3(14.0, 9.5, 16.0)
	root.add_child(cam2)
	cam2.current = true
	cam2.look_at(Vector3(-4.0, 2.0, -10.0), Vector3.UP)
	await _snap("dust2_and_stadium.png", 14)
	dust2.queue_free()
	cam2.queue_free()
	for i in 4:
		await process_frame

	# 7. Twilight Floodlit Soccer Stadium Showcase
	var stadium := (load(match_script.call(&"arena_path", 5)) as PackedScene).instantiate() as Node3D
	stadium.set(&"bake_navigation", false)
	root.add_child(stadium)
	var cam3 := Camera3D.new()
	cam3.fov = 74.0
	cam3.position = Vector3(-22.0, 10.0, 20.0)
	root.add_child(cam3)
	cam3.current = true
	cam3.look_at(Vector3(4.0, 2.5, -6.0), Vector3.UP)
	await _snap("stadium_twilight.png", 14)
	stadium.queue_free()
	cam3.queue_free()

	root.get_node("Sfx").call(&"quit_game")
