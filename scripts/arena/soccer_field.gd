class_name SoccerField
extends Arena
## SOCCER STADIUM: regulation grass soccer pitch turned tactical foam obstacle arena.
## Features chalk lines, soccer goals with nets, inflatable speedball bunkers,
## giant foam soccer balls, agility slalom cones, covered player dugouts,
## multi-tier spectator bleachers, and 4 corner floodlight towers.

const LAWN_SHADER := preload("res://assets/materials/lawn.gdshader")

const HALF_X := 30.0
const HALF_Z := 24.0

const PITCH_GRASS := Color(0.26, 0.64, 0.22)
const CHALK := Color(0.96, 0.96, 0.96)
const GOAL_WHITE := Color(0.95, 0.95, 0.95)
const NET_COLOR := Color(0.85, 0.88, 0.9, 0.7)
const BLAZE_ORANGE := Color(1.0, 0.45, 0.08)
const CYAN_BLUE := Color(0.08, 0.75, 0.95)
const LIME_GREEN := Color(0.45, 0.88, 0.15)
const STEEL := Color(0.82, 0.84, 0.88)
const WOOD := Color(0.72, 0.52, 0.32)
const DUGOUT_ROOF := Color(0.2, 0.4, 0.8, 0.8)
const FLOODLIGHT := Color(0.95, 0.98, 1.0)


func _build() -> void:
	arena_name = "Soccer Stadium"
	_build_sky_and_sun(-55.0, 0.05)
	_build_pitch_and_chalk()
	_build_soccer_goals()
	_build_inflatable_bunkers()
	_build_agility_obstacles()
	_build_dugouts_and_bleachers()
	_build_floodlight_towers()
	_build_spawns_and_points()


func _build_pitch_and_chalk() -> void:
	# Pitch grass with alternating mower stripes
	var lawn_mat := ShaderMaterial.new()
	lawn_mat.shader = LAWN_SHADER
	var ground := ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), PITCH_GRASS)
	(ground.get_node("Mesh") as MeshInstance3D).material_override = lawn_mat

	# Stadium running track & outer grass backdrop
	ArenaKit.deco_box(decor, Vector3(400.0, 0.2, 400.0), Vector3(0.0, -0.55, 0.0), Color(0.75, 0.32, 0.22))

	# Boundary advertising boards / field walls (waist-high and solid)
	var wall_h := 1.2
	var thick := 0.4
	# North and South boundary
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), BLAZE_ORANGE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), CYAN_BLUE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	# East and West boundary
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), WHITE_WOOD_COLOR(), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), WHITE_WOOD_COLOR(), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)

	# Chalk lines (flush decals with ground)
	var line_w := 0.18
	# Halfway line (along X)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 - 1.0, 0.02, line_w), Vector3(0.0, 0.01, 0.0), CHALK)
	# Center circle (approximate with ring of small segments)
	for i in 24:
		var a := float(i) * TAU / 24.0
		var cp := Vector3(cos(a) * 5.0, 0.01, sin(a) * 5.0)
		ArenaKit.box(geometry, Vector3(1.3, 0.02, line_w), cp, CHALK, Vector3(0.0, -rad_to_deg(a), 0.0))
	# Center spot
	ArenaKit.cylinder(geometry, 0.45, 0.02, Vector3(0.0, 0.01, 0.0), CHALK)

	# North penalty box
	ArenaKit.box(geometry, Vector3(16.0, 0.02, line_w), Vector3(0.0, 0.01, -HALF_Z + 8.0), CHALK)
	ArenaKit.box(geometry, Vector3(line_w, 0.02, 8.0), Vector3(-8.0, 0.01, -HALF_Z + 4.0), CHALK)
	ArenaKit.box(geometry, Vector3(line_w, 0.02, 8.0), Vector3(8.0, 0.01, -HALF_Z + 4.0), CHALK)

	# South penalty box
	ArenaKit.box(geometry, Vector3(16.0, 0.02, line_w), Vector3(0.0, 0.01, HALF_Z - 8.0), CHALK)
	ArenaKit.box(geometry, Vector3(line_w, 0.02, 8.0), Vector3(-8.0, 0.01, HALF_Z - 4.0), CHALK)
	ArenaKit.box(geometry, Vector3(line_w, 0.02, 8.0), Vector3(8.0, 0.01, HALF_Z - 4.0), CHALK)


func WHITE_WOOD_COLOR() -> Color:
	return Color(0.92, 0.92, 0.94)


func _build_soccer_goals() -> void:
	# North Goal (Blue end)
	_build_single_goal(Vector3(0.0, 0.0, -HALF_Z + 0.8), 0.0)
	# South Goal (Orange end)
	_build_single_goal(Vector3(0.0, 0.0, HALF_Z - 0.8), 180.0)


func _build_single_goal(at: Vector3, rot_y: float) -> void:
	var goal_root := Node3D.new()
	goal_root.position = at
	goal_root.rotation_degrees.y = rot_y
	geometry.add_child(goal_root)

	var w := 7.3
	var h := 2.4
	var d := 2.2
	var r := 0.12

	# Left and Right posts
	ArenaKit.cylinder(goal_root, r, h, Vector3(-w * 0.5, h * 0.5, 0.0), GOAL_WHITE, ArenaKit.SurfaceType.METAL)
	ArenaKit.cylinder(goal_root, r, h, Vector3(w * 0.5, h * 0.5, 0.0), GOAL_WHITE, ArenaKit.SurfaceType.METAL)
	# Crossbar
	ArenaKit.cylinder(goal_root, r, w, Vector3(0.0, h, 0.0), GOAL_WHITE, ArenaKit.SurfaceType.METAL)
	var crossbar_mesh := goal_root.get_child(goal_root.get_child_count() - 1) as StaticBody3D
	crossbar_mesh.rotation_degrees.z = 90.0

	# Netting back frame (sloped back)
	ArenaKit.ramp(goal_root, Vector3(0.0, h, 0.0), Vector3(0.0, 0.0, -d), w, NET_COLOR, 0.1, ArenaKit.SurfaceType.PLASTIC)
	# Net side triangles
	ArenaKit.box(goal_root, Vector3(0.1, h, d), Vector3(-w * 0.5, h * 0.5, -d * 0.5), NET_COLOR, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(goal_root, Vector3(0.1, h, d), Vector3(w * 0.5, h * 0.5, -d * 0.5), NET_COLOR, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)


func _build_inflatable_bunkers() -> void:
	# Tactical speedball bunkers positioned symmetrically across midfield
	# Center wedge bunkers flanking the center circle
	_build_wedge_bunker(Vector3(-8.0, 0.0, 0.0), 3.4, 1.8, BLAZE_ORANGE, 90.0)
	_build_wedge_bunker(Vector3(8.0, 0.0, 0.0), 3.4, 1.8, CYAN_BLUE, -90.0)

	# Stand-up inflatable cylinders (Cans)
	var can_r := 1.1
	var can_h := 2.2
	ArenaKit.cylinder(geometry, can_r, can_h, Vector3(-4.5, can_h * 0.5, -5.5), BLAZE_ORANGE, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.cylinder(geometry, can_r, can_h, Vector3(4.5, can_h * 0.5, -5.5), CYAN_BLUE, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.cylinder(geometry, can_r, can_h, Vector3(-4.5, can_h * 0.5, 5.5), CYAN_BLUE, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.cylinder(geometry, can_r, can_h, Vector3(4.5, can_h * 0.5, 5.5), BLAZE_ORANGE, ArenaKit.SurfaceType.PLASTIC)

	# Aztec Pyramid bunkers (flanking wing cover)
	_build_pyramid_bunker(Vector3(-16.0, 0.0, -8.0), 4.2, 2.0, LIME_GREEN)
	_build_pyramid_bunker(Vector3(16.0, 0.0, -8.0), 4.2, 2.0, BLAZE_ORANGE)
	_build_pyramid_bunker(Vector3(-16.0, 0.0, 8.0), 4.2, 2.0, CYAN_BLUE)
	_build_pyramid_bunker(Vector3(16.0, 0.0, 8.0), 4.2, 2.0, LIME_GREEN)

	# Giant novelty foam soccer balls (solid waist/chest cover)
	_build_foam_soccer_ball(Vector3(0.0, 0.0, -12.0), 1.3)
	_build_foam_soccer_ball(Vector3(0.0, 0.0, 12.0), 1.3)
	_build_foam_soccer_ball(Vector3(-14.0, 0.0, 0.0), 1.1)
	_build_foam_soccer_ball(Vector3(14.0, 0.0, 0.0), 1.1)


func _build_wedge_bunker(at: Vector3, width: float, height: float, color: Color, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation_degrees.y = rot_y
	geometry.add_child(root)
	ArenaKit.ramp(root, Vector3(0.0, 0.0, 1.8), Vector3(0.0, height, 0.0), width, color, 0.2, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.ramp(root, Vector3(0.0, height, 0.0), Vector3(0.0, 0.0, -1.8), width, color, 0.2, ArenaKit.SurfaceType.PLASTIC)


func _build_pyramid_bunker(at: Vector3, base_size: float, height: float, color: Color) -> void:
	# Stepped pyramid (2 tiers)
	var t1_h := height * 0.55
	var t2_h := height * 0.45
	ArenaKit.box(geometry, Vector3(base_size, t1_h, base_size), at + Vector3(0.0, t1_h * 0.5, 0.0), color, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(base_size * 0.65, t2_h, base_size * 0.65), at + Vector3(0.0, t1_h + t2_h * 0.5, 0.0), color.lightened(0.15), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)


func _build_foam_soccer_ball(at: Vector3, radius: float) -> void:
	# Solid sphere in geometry
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.position = at + Vector3(0.0, radius, 0.0)
	var shape := SphereShape3D.new()
	shape.radius = radius
	var owner_id := body.create_shape_owner(body)
	body.shape_owner_add_shape(owner_id, shape)
	geometry.add_child(body)

	# Visual decorated sphere
	var mesh_inst := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh_inst.mesh = sphere_mesh
	mesh_inst.material_override = ArenaKit.mat_styled(Color(0.96, 0.96, 0.98), ArenaKit.SurfaceType.PLASTIC)
	body.add_child(mesh_inst)


func _build_agility_obstacles() -> void:
	# Slalom agility training poles (West & East sidelines)
	for i in range(-3, 4):
		var p_west := Vector3(-22.0, 0.0, float(i) * 3.5)
		ArenaKit.cylinder(geometry, 0.1, 1.8, p_west + Vector3(0.0, 0.9, 0.0), BLAZE_ORANGE, ArenaKit.SurfaceType.PLASTIC)
		var p_east := Vector3(22.0, 0.0, float(i) * 3.5)
		ArenaKit.cylinder(geometry, 0.1, 1.8, p_east + Vector3(0.0, 0.9, 0.0), CYAN_BLUE, ArenaKit.SurfaceType.PLASTIC)

	# Hurdle barriers (North-West and South-East)
	ArenaKit.box(geometry, Vector3(3.5, 0.65, 0.15), Vector3(-10.0, 0.325, -16.0), LIME_GREEN, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(3.5, 0.65, 0.15), Vector3(10.0, 0.325, 16.0), LIME_GREEN, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)


func _build_dugouts_and_bleachers() -> void:
	# West sideline: Covered player dugout (Height 2.6m, depth 3.2m, length 8.0m)
	var dugout_pos := Vector3(-HALF_X - 1.8, 0.0, 0.0)
	# Floor slab
	ArenaKit.box(geometry, Vector3(3.2, 0.2, 8.0), dugout_pos + Vector3(0.0, 0.1, 0.0), Color(0.35, 0.35, 0.38), Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Back wall & sides
	ArenaKit.box(geometry, Vector3(0.2, 2.4, 8.0), dugout_pos + Vector3(-1.5, 1.2, 0.0), STEEL, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(3.2, 2.4, 0.2), dugout_pos + Vector3(0.0, 1.2, -3.9), STEEL, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(3.2, 2.4, 0.2), dugout_pos + Vector3(0.0, 1.2, 3.9), STEEL, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	# Bench seat
	ArenaKit.box(geometry, Vector3(1.0, 0.45, 7.2), dugout_pos + Vector3(-0.6, 0.225, 0.0), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Curved acrylic roof
	ArenaKit.box(geometry, Vector3(3.4, 0.15, 8.4), dugout_pos + Vector3(0.0, 2.5, 0.0), DUGOUT_ROOF, Vector3(0.0, 0.0, 10.0), ArenaKit.SurfaceType.PLASTIC)

	# East sideline: Spectator bleachers (3 tiers)
	var bleacher_pos := Vector3(HALF_X + 2.4, 0.0, 0.0)
	var bl_len := 10.0
	# Tier 1
	ArenaKit.box(geometry, Vector3(1.2, 0.5, bl_len), bleacher_pos + Vector3(-1.2, 0.25, 0.0), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Tier 2
	ArenaKit.box(geometry, Vector3(1.2, 1.0, bl_len), bleacher_pos + Vector3(0.0, 0.5, 0.0), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Tier 3
	ArenaKit.box(geometry, Vector3(1.2, 1.5, bl_len), bleacher_pos + Vector3(1.2, 0.75, 0.0), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_floodlight_towers() -> void:
	var h := 14.0
	var tower_spots: Array[Vector3] = [
		Vector3(-HALF_X - 1.0, 0.0, -HALF_Z - 1.0),
		Vector3(HALF_X + 1.0, 0.0, -HALF_Z - 1.0),
		Vector3(-HALF_X - 1.0, 0.0, HALF_Z + 1.0),
		Vector3(HALF_X + 1.0, 0.0, HALF_Z + 1.0),
	]
	for p in tower_spots:
		# Lattice tower pole
		ArenaKit.cylinder(geometry, 0.35, h, p + Vector3(0.0, h * 0.5, 0.0), STEEL, ArenaKit.SurfaceType.METAL)
		# Crossbar light fixture in decor
		ArenaKit.deco_box(decor, Vector3(3.2, 0.8, 0.8), p + Vector3(0.0, h, 0.0), STEEL)
		# 3 Floodlight emissive heads
		for lx in [-1.0, 0.0, 1.0]:
			ArenaKit.deco_sphere(decor, 0.45, p + Vector3(lx, h, 0.0), FLOODLIGHT, 0.75)


func _build_spawns_and_points() -> void:
	# Team bases: North Goal (Blue Base) vs South Goal (Orange Base)
	team_bases.clear()
	team_bases.append(Vector3(0.0, 0.0, -HALF_Z + 3.0))   # Blue Base (North Goal)
	team_bases.append(Vector3(0.0, 0.0, HALF_Z - 3.0))    # Orange Base (South Goal)

	# 12 Spawn points across both halves and sidelines
	var spawns: Array[Vector3] = [
		Vector3(-12.0, 0.0, -HALF_Z + 4.0),
		Vector3(12.0, 0.0, -HALF_Z + 4.0),
		Vector3(-20.0, 0.0, -10.0),
		Vector3(20.0, 0.0, -10.0),
		Vector3(-6.0, 0.0, -2.0),
		Vector3(6.0, 0.0, -2.0),
		Vector3(-6.0, 0.0, 2.0),
		Vector3(6.0, 0.0, 2.0),
		Vector3(-20.0, 0.0, 10.0),
		Vector3(20.0, 0.0, 10.0),
		Vector3(-12.0, 0.0, HALF_Z - 4.0),
		Vector3(12.0, 0.0, HALF_Z - 4.0),
	]
	for p in spawns:
		add_spawn(p, Vector3.ZERO.direction_to(Vector3(0.0, 0.0, -p.z)))

	# Roam points for bots
	roam_points.clear()
	roam_points.append(Vector3(0.0, 0.0, 0.0))        # Center spot
	roam_points.append(Vector3(-8.0, 0.0, 0.0))       # West midfield
	roam_points.append(Vector3(8.0, 0.0, 0.0))        # East midfield
	roam_points.append(Vector3(0.0, 0.0, -12.0))      # North giant soccer ball
	roam_points.append(Vector3(0.0, 0.0, 12.0))       # South giant soccer ball
	roam_points.append(Vector3(-16.0, 0.0, -8.0))     # NW pyramid
	roam_points.append(Vector3(16.0, 0.0, 8.0))       # SE pyramid
	roam_points.append(Vector3(0.0, 0.0, -HALF_Z + 4.0)) # North penalty box
	roam_points.append(Vector3(0.0, 0.0, HALF_Z - 4.0))  # South penalty box

	# Power-up spot (Center Circle)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, 0.0))

	# Ammo buckets (4 corners of pitch)
	add_bucket(Vector3(-18.0, 0.0, -12.0), Color(0.2, 0.6, 0.95))
	add_bucket(Vector3(18.0, 0.0, -12.0), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(-18.0, 0.0, 12.0), Color(0.2, 0.6, 0.95))
	add_bucket(Vector3(18.0, 0.0, 12.0), Color(0.95, 0.45, 0.15))

	# Foam shield pickup in midfield
	var shield := ShieldPickup.new()
	shield.position = Vector3(0.0, 0.8, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
