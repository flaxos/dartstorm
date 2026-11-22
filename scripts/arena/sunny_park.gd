class_name SunnyPark
extends Arena
## SUNNY PARK: vibrant municipal park battleground.
## Features a central raised wooden gazebo pavilion, a duck pond with an arched
## wooden footbridge, a picnic grove with tables and BBQ grills, boxwood hedge
## labyrinths, leafy oak trees, park benches, and winding gravel paths.

const LAWN_SHADER := preload("res://assets/materials/lawn.gdshader")

const HALF_X := 32.0
const HALF_Z := 26.0

const GRASS := Color(0.32, 0.68, 0.26)
const PATH := Color(0.84, 0.78, 0.68)
const STONE := Color(0.65, 0.65, 0.68)
const WATER := Color(0.2, 0.58, 0.88, 0.85)
const WOOD := Color(0.74, 0.52, 0.32)
const WHITE_WOOD := Color(0.95, 0.94, 0.9)
const ROOF_TILE := Color(0.72, 0.32, 0.2)
const TRUNK := Color(0.45, 0.3, 0.18)
const LEAF := Color(0.25, 0.65, 0.25)
const LEAF_LIGHT := Color(0.38, 0.78, 0.3)
const HEDGE := Color(0.18, 0.52, 0.22)
const BENCH_WOOD := Color(0.68, 0.44, 0.24)
const CAST_IRON := Color(0.22, 0.24, 0.26)

var _time: float = 0.0
var _leaves: Array[Node3D] = []
var _duck: Node3D


func _build() -> void:
	arena_name = "Sunny Park"
	_build_sky_and_sun(-45.0, 0.2)
	_build_ground_and_paths()
	_build_gazebo()
	_build_duck_pond_and_bridge()
	_build_picnic_grove()
	_build_hedges_and_trees()
	_build_park_benches_and_props()
	_build_spawns_and_points()


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	for i in _leaves.size():
		_leaves[i].rotation.y = sin(_time * 1.4 + float(i) * 0.9) * 0.05
	if _duck != null:
		_duck.position.y = 0.12 + sin(_time * 2.2) * 0.04
		_duck.rotation.y += delta * 0.35


func _build_ground_and_paths() -> void:
	# Main lawn with mower stripes
	var lawn_mat := ShaderMaterial.new()
	lawn_mat.shader = LAWN_SHADER
	var ground := ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), GRASS)
	(ground.get_node("Mesh") as MeshInstance3D).material_override = lawn_mat

	# Backdrop surrounding park
	ArenaKit.deco_box(decor, Vector3(400.0, 0.2, 400.0), Vector3(0.0, -0.55, 0.0), Color(0.28, 0.6, 0.24))

	# Boundary park fence / stone wall
	var wall_h := 3.2
	var thick := 0.5
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z - thick * 0.5), STONE, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z + thick * 0.5), STONE, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, wall_h * 0.5, 0.0), STONE, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, wall_h * 0.5, 0.0), STONE, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Cross walking paths (Gravel)
	ArenaKit.box(geometry, Vector3(HALF_X * 1.8, 0.06, 3.2), Vector3(0.0, 0.03, 0.0), PATH)
	ArenaKit.box(geometry, Vector3(3.2, 0.06, HALF_Z * 1.8), Vector3(0.0, 0.03, 0.0), PATH)


func _build_gazebo() -> void:
	# Central raised wooden gazebo
	var pos := Vector3(0.0, 0.0, 0.0)
	var deck_h := 1.8
	var radius := 5.2

	# Octagonal raised base
	ArenaKit.cylinder(geometry, radius, deck_h, pos + Vector3(0.0, deck_h * 0.5, 0.0), WHITE_WOOD, ArenaKit.SurfaceType.WOOD)
	# Floor platform
	ArenaKit.cylinder(geometry, radius + 0.3, 0.2, pos + Vector3(0.0, deck_h + 0.1, 0.0), WOOD, ArenaKit.SurfaceType.WOOD)

	# 8 Peripheral support pillars
	for i in 8:
		var angle := float(i) * TAU / 8.0
		var pillar_pos := pos + Vector3(cos(angle) * (radius - 0.4), deck_h + 1.8, sin(angle) * (radius - 0.4))
		ArenaKit.cylinder(geometry, 0.14, 3.6, pillar_pos, WHITE_WOOD, ArenaKit.SurfaceType.WOOD)

	# Shingle pyramid roof
	ArenaKit.deco_cone(decor, radius + 0.8, 2.6, pos + Vector3(0.0, deck_h + 4.2, 0.0), ROOF_TILE)

	# Safety perimeter railings between pillars with 4 openings
	for i in [1, 3, 5, 7]:
		var angle := float(i) * TAU / 8.0
		var rail_pos := pos + Vector3(cos(angle) * (radius - 0.4), deck_h + 0.5, sin(angle) * (radius - 0.4))
		ArenaKit.box(geometry, Vector3(2.6, 0.8, 0.12), rail_pos, WHITE_WOOD, Vector3(0.0, -rad_to_deg(angle) + 90.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# 4 Access ramps/stairs (North, South, East, West)
	ArenaKit.ramp(geometry, pos + Vector3(0.0, 0.0, -radius - 2.8), pos + Vector3(0.0, deck_h, -radius), 2.2, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, pos + Vector3(0.0, 0.0, radius + 2.8), pos + Vector3(0.0, deck_h, radius), 2.2, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, pos + Vector3(-radius - 2.8, 0.0, 0.0), pos + Vector3(-radius, deck_h, 0.0), 2.2, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, pos + Vector3(radius + 2.8, 0.0, 0.0), pos + Vector3(radius, deck_h, 0.0), 2.2, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)


func _build_duck_pond_and_bridge() -> void:
	var pond_pos := Vector3(16.0, 0.0, -10.0)
	var pond_rx := 8.0
	var pond_rz := 6.5

	# Pond basin (submerged blue water)
	ArenaKit.cylinder(geometry, pond_rx, 0.2, pond_pos + Vector3(0.0, 0.05, 0.0), WATER, ArenaKit.SurfaceType.PLASTIC)
	# Stone shore lip
	for i in 16:
		var a := float(i) * TAU / 16.0
		var sp := pond_pos + Vector3(cos(a) * (pond_rx + 0.4), 0.15, sin(a) * (pond_rz + 0.4))
		ArenaKit.box(geometry, Vector3(1.8, 0.35, 1.2), sp, STONE, Vector3(0.0, -rad_to_deg(a), 0.0), ArenaKit.SurfaceType.WOOD)

	# Arched wooden footbridge spanning North-South across the pond
	var bridge_w := 2.0
	var bridge_arch_h := 1.2
	# South ramp up
	ArenaKit.ramp(geometry, pond_pos + Vector3(0.0, 0.0, pond_rz + 1.2), pond_pos + Vector3(0.0, bridge_arch_h, 0.0), bridge_w, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	# North ramp down
	ArenaKit.ramp(geometry, pond_pos + Vector3(0.0, bridge_arch_h, 0.0), pond_pos + Vector3(0.0, 0.0, -pond_rz - 1.2), bridge_w, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	# Bridge railings
	ArenaKit.box(geometry, Vector3(0.12, 0.8, pond_rz * 2.2), pond_pos + Vector3(-bridge_w * 0.5, bridge_arch_h * 0.5 + 0.4, 0.0), WHITE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.12, 0.8, pond_rz * 2.2), pond_pos + Vector3(bridge_w * 0.5, bridge_arch_h * 0.5 + 0.4, 0.0), WHITE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Rubber duck toy floating in pond
	_duck = Node3D.new()
	_duck.position = pond_pos + Vector3(2.5, 0.12, 1.5)
	decor.add_child(_duck)
	ArenaKit.deco_sphere(_duck, 0.4, Vector3.ZERO, Color(1.0, 0.85, 0.15))
	ArenaKit.deco_box(_duck, Vector3(0.25, 0.15, 0.3), Vector3(0.0, 0.15, 0.3), Color(1.0, 0.45, 0.1))


func _build_picnic_grove() -> void:
	# 4 Picnic tables on West side
	var grove_origin := Vector3(-16.0, 0.0, 10.0)
	for ox in [-4.5, 4.5]:
		for oz in [-4.5, 4.5]:
			_build_picnic_table(grove_origin + Vector3(ox, 0.0, oz))

	# Brick BBQ grill station
	var bbq_pos := grove_origin + Vector3(0.0, 0.0, 7.5)
	ArenaKit.box(geometry, Vector3(2.2, 1.1, 1.4), bbq_pos + Vector3(0.0, 0.55, 0.0), Color(0.68, 0.28, 0.22), Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.8, 0.1, 1.1), bbq_pos + Vector3(0.0, 1.15, 0.0), CAST_IRON, Vector3.ZERO, ArenaKit.SurfaceType.METAL)


func _build_picnic_table(at: Vector3) -> void:
	if ModelLoader.has_prop_model(&"picnic_table"):
		var p := ArenaKit.prop(geometry, &"picnic_table", at)
		if p != null:
			return
	# Tabletop (waist-high cover)
	ArenaKit.box(geometry, Vector3(2.4, 0.12, 1.4), at + Vector3(0.0, 0.85, 0.0), BENCH_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# 4 Legs
	for lx in [-0.9, 0.9]:
		for lz in [-0.5, 0.5]:
			ArenaKit.box(geometry, Vector3(0.12, 0.85, 0.12), at + Vector3(lx, 0.425, lz), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# 2 Benches
	ArenaKit.box(geometry, Vector3(2.4, 0.1, 0.45), at + Vector3(0.0, 0.48, -1.0), BENCH_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(2.4, 0.1, 0.45), at + Vector3(0.0, 0.48, 1.0), BENCH_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Cooler on table
	ArenaKit.box(geometry, Vector3(0.6, 0.4, 0.4), at + Vector3(0.5, 1.1, 0.0), Color(0.95, 0.2, 0.2), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)


func _build_hedges_and_trees() -> void:
	# Boxwood hedge maze corridors on South-West & North-East
	var h_h := 1.4  # Chest-high cover
	var h_th := 0.8
	# L-shaped hedge 1
	ArenaKit.box(geometry, Vector3(8.0, h_h, h_th), Vector3(-16.0, h_h * 0.5, -12.0), HEDGE)
	ArenaKit.box(geometry, Vector3(h_th, h_h, 7.0), Vector3(-12.0, h_h * 0.5, -8.5), HEDGE)
	# L-shaped hedge 2
	ArenaKit.box(geometry, Vector3(8.0, h_h, h_th), Vector3(16.0, h_h * 0.5, 12.0), HEDGE)
	ArenaKit.box(geometry, Vector3(h_th, h_h, 7.0), Vector3(12.0, h_h * 0.5, 8.5), HEDGE)

	# 6 Large Oak Trees providing vertical cover
	var tree_spots: Array[Vector3] = [
		Vector3(-24.0, 0.0, -18.0),
		Vector3(-24.0, 0.0, 18.0),
		Vector3(-8.0, 0.0, -18.0),
		Vector3(8.0, 0.0, 18.0),
		Vector3(24.0, 0.0, -20.0),
		Vector3(25.0, 0.0, 18.0),
	]
	for p in tree_spots:
		_build_oak_tree(p)


func _build_oak_tree(at: Vector3) -> void:
	if ModelLoader.has_prop_model(&"cartoon_tree"):
		var t := ArenaKit.prop(geometry, &"cartoon_tree", at, Vector3.ZERO, Vector3.ONE * 1.15)
		if t != null:
			return
	var trunk_h := 5.5
	var trunk_r := 0.7
	ArenaKit.cylinder(geometry, trunk_r, trunk_h, at + Vector3(0.0, trunk_h * 0.5, 0.0), TRUNK, ArenaKit.SurfaceType.WOOD)
	# Leafy spheres in decor
	var dome1 := ArenaKit.deco_sphere(decor, 3.2, at + Vector3(0.0, trunk_h + 0.8, 0.0), LEAF, 0.75)
	var dome2 := ArenaKit.deco_sphere(decor, 2.4, at + Vector3(1.2, trunk_h + 2.2, -0.8), LEAF_LIGHT, 0.7)
	_leaves.append(dome1)
	_leaves.append(dome2)


func _build_park_benches_and_props() -> void:
	# Park benches along path
	_build_bench(Vector3(-7.5, 0.0, -2.5), 0.0)
	_build_bench(Vector3(7.5, 0.0, 2.5), 180.0)
	_build_bench(Vector3(-2.5, 0.0, 7.5), 90.0)
	_build_bench(Vector3(2.5, 0.0, -7.5), -90.0)

	# Cast iron street lamps
	for lp in [Vector3(-10.0, 0.0, 0.0), Vector3(10.0, 0.0, 0.0), Vector3(0.0, 0.0, -10.0), Vector3(0.0, 0.0, 10.0)]:
		ArenaKit.cylinder(geometry, 0.12, 3.8, lp + Vector3(0.0, 1.9, 0.0), CAST_IRON, ArenaKit.SurfaceType.METAL)
		ArenaKit.deco_sphere(decor, 0.35, lp + Vector3(0.0, 3.9, 0.0), Color(1.0, 0.95, 0.8), 0.4)


func _build_bench(at: Vector3, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation_degrees.y = rot_y
	geometry.add_child(root)
	# Seat
	ArenaKit.box(root, Vector3(2.0, 0.08, 0.6), Vector3(0.0, 0.45, 0.0), BENCH_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Backrest
	ArenaKit.box(root, Vector3(2.0, 0.5, 0.08), Vector3(0.0, 0.75, -0.26), BENCH_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Cast iron legs
	ArenaKit.box(root, Vector3(0.1, 0.45, 0.6), Vector3(-0.85, 0.225, 0.0), CAST_IRON, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(root, Vector3(0.1, 0.45, 0.6), Vector3(0.85, 0.225, 0.0), CAST_IRON, Vector3.ZERO, ArenaKit.SurfaceType.METAL)


func _build_spawns_and_points() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(-24.0, 0.0, 0.0))  # Blue Base (West Picnic Grove)
	team_bases.append(Vector3(24.0, 0.0, 0.0))   # Orange Base (East Duck Pond)

	# 12 Spawns
	var spawns: Array[Vector3] = [
		Vector3(-26.0, 0.0, -8.0),
		Vector3(-26.0, 0.0, 8.0),
		Vector3(-20.0, 0.0, -18.0),
		Vector3(-20.0, 0.0, 18.0),
		Vector3(0.0, 2.0, 0.0),     # Inside Gazebo
		Vector3(0.0, 0.0, -14.0),
		Vector3(0.0, 0.0, 14.0),
		Vector3(16.0, 1.4, 0.0),    # On Bridge
		Vector3(20.0, 0.0, -18.0),
		Vector3(20.0, 0.0, 18.0),
		Vector3(26.0, 0.0, -8.0),
		Vector3(26.0, 0.0, 8.0),
	]
	for p in spawns:
		add_spawn(p, Vector3.ZERO.direction_to(Vector3(-p.x, 0.0, -p.z)))

	# Roam points for bots
	roam_points.clear()
	roam_points.append(Vector3(0.0, 2.0, 0.0))
	roam_points.append(Vector3(16.0, 1.4, 0.0))
	roam_points.append(Vector3(-16.0, 0.0, 10.0))
	roam_points.append(Vector3(-16.0, 0.0, -12.0))
	roam_points.append(Vector3(16.0, 0.0, 12.0))
	roam_points.append(Vector3(0.0, 0.0, -10.0))
	roam_points.append(Vector3(0.0, 0.0, 10.0))
	roam_points.append(Vector3(-10.0, 0.0, 0.0))
	roam_points.append(Vector3(10.0, 0.0, 0.0))

	# Power-up spot (Center of Gazebo)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 2.0, 0.0))

	# Ammo buckets
	add_bucket(Vector3(-14.0, 0.0, 0.0), Color(0.3, 0.75, 0.95))
	add_bucket(Vector3(14.0, 0.0, 0.0), Color(0.95, 0.5, 0.2))
	add_bucket(Vector3(0.0, 0.0, -8.0), Color(0.85, 0.9, 0.3))
	add_bucket(Vector3(0.0, 0.0, 8.0), Color(0.9, 0.35, 0.7))

	# Foam shield pickup on the footbridge
	var shield := ShieldPickup.new()
	shield.position = Vector3(16.0, 1.8, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
