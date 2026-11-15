extends SceneTree
## Prints a Markdown table of how every dart in resources/darts/ flies, measured
## by firing the real DartProjectile code in calm air. Used for docs/GDD.md;
## re-run it after tuning a dart:
##
##     godot --headless --path . -s res://tools/dart_table.gd
##
## Columns: flight time and drop when the dart has travelled 10/20/30/40 m
## horizontally after a level shot, and how far a level shot from shoulder
## height (1.4 m) goes before it lands.
##
## Game classes are loaded at runtime (not referenced by name) because a `-s`
## script compiles before the GameSettings/Sfx autoloads are registered.

const DART_DIR := "res://resources/darts"
const DISTANCES: Array[float] = [10.0, 20.0, 30.0, 40.0]
const SHOULDER_HEIGHT := 1.4
const START := Vector3(0.0, 500.0, 0.0)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var pool: Node3D = (load("res://scripts/combat/dart_pool.gd") as GDScript).new()
	root.add_child(pool)
	await physics_frame
	var step := 1.0 / float(Engine.physics_ticks_per_second)
	var header := "| Dart | Speed | Gravity × | Drag |"
	var divider := "|---|---|---|---|"
	for distance in DISTANCES:
		header += " %d m: time / drop |" % int(distance)
		divider += "---|"
	header += " Level-shot range |"
	divider += "---|"
	print(header)
	print(divider)
	var files := Array(DirAccess.get_files_at(DART_DIR))
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".tres"):
			continue
		var data: Resource = load(DART_DIR.path_join(file_name)).duplicate()
		data.set("max_lifetime", 20.0)
		var no_exclude: Array[RID] = []
		var dart: Node3D = pool.call("fire", data, START, Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
		var cells: Dictionary = {}
		var level_range := -1.0
		var time := 0.0
		var previous := START
		while dart.get("active") and time < 20.0 and (cells.size() < DISTANCES.size() or level_range < 0.0):
			await physics_frame
			time += step
			var now := dart.global_position
			for distance in DISTANCES:
				if not cells.has(distance) and -now.z >= distance:
					var t := _fraction(-previous.z, -now.z, distance)
					var drop := START.y - lerpf(previous.y, now.y, t)
					cells[distance] = "%.2f s / %.2f m" % [time - step * (1.0 - t), drop]
			if level_range < 0.0 and START.y - now.y >= SHOULDER_HEIGHT:
				var t := _fraction(START.y - previous.y, START.y - now.y, SHOULDER_HEIGHT)
				level_range = lerpf(-previous.z, -now.z, t)
			previous = now
		var row := "| %s | %d | %.2f | %.2f |" % [data.get("display_name"), int(data.get("initial_speed")),
				data.get("gravity_multiplier"), data.get("air_drag")]
		for distance in DISTANCES:
			row += " %s |" % cells.get(distance, "never")
		row += " %s |" % ("%.0f m" % level_range if level_range >= 0.0 else "n/a")
		print(row)
		dart.call("retire")
	quit(0)


## Where `target` sits between `a` and `b`, from 0 to 1.
func _fraction(a: float, b: float, target: float) -> float:
	if is_equal_approx(a, b):
		return 1.0
	return clampf((target - a) / (b - a), 0.0, 1.0)
