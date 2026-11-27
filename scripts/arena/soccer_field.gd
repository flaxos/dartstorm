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

	# Boundary advertising boards / field walls + invisible stadium sky blockers
	var wall_h := 1.2
	var thick := 0.4
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), BLAZE_ORANGE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), CYAN_BLUE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), WHITE_WOOD_COLOR(), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), WHITE_WOOD_COLOR(), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	var sky_h := 18.0
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 1.0, sky_h, thick), Vector3(0.0, wall_h + sky_h * 0.5, -HALF_Z))
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 1.0, sky_h, thick), Vector3(0.0, wall_h + sky_h * 0.5, HALF_Z))
	ArenaKit.blocker(geometry, Vector3(thick, sky_h, HALF_Z * 2.0 + 1.0), Vector3(-HALF_X, wall_h + sky_h * 0.5, 0.0))
	ArenaKit.blocker(geometry, Vector3(thick, sky_h, HALF_Z * 2.0 + 1.0), Vector3(HALF_X, wall_h + sky_h * 0.5, 0.0))

	# Non-colliding chalk lines in decor (zero navmesh fragmentation)
	var line_w := 0.18
	ArenaKit.deco_box(decor, Vector3(HALF_X * 2.0 - 1.0, 0.02, line_w), Vector3(0.0, 0.015, 0.0), CHALK)
	for i in 24:
		var a := float(i) * TAU / 24.0
		var cp := Vector3(cos(a) * 5.0, 0.015, sin(a) * 5.0)
		ArenaKit.deco_box(decor, Vector3(1.3, 0.02, line_w), cp, CHALK, Vector3(0.0, -rad_to_deg(a), 0.0))
	ArenaKit.deco_cylinder(decor, 0.45, 0.02, Vector3(0.0, 0.015, 0.0), CHALK)

	# North penalty box
	ArenaKit.deco_box(decor, Vector3(16.0, 0.02, line_w), Vector3(0.0, 0.015, -HALF_Z + 8.0), CHALK)
	ArenaKit.deco_box(decor, Vector3(line_w, 0.02, 8.0), Vector3(-8.0, 0.015, -HALF_Z + 4.0), CHALK)
	ArenaKit.deco_box(decor, Vector3(line_w, 0.02, 8.0), Vector3(8.0, 0.015, -HALF_Z + 4.0), CHALK)

	# South penalty box
	ArenaKit.deco_box(decor, Vector3(16.0, 0.02, line_w), Vector3(0.0, 0.015, HALF_Z - 8.0), CHALK)
	ArenaKit.deco_box(decor, Vector3(line_w, 0.02, 8.0), Vector3(-8.0, 0.015, HALF_Z - 4.0), CHALK)
	ArenaKit.deco_box(decor, Vector3(line_w, 0.02, 8.0), Vector3(8.0, 0.015, HALF_Z - 4.0), CHALK)


func WHITE_WOOD_COLOR() -> Color:
	return Color(0.92, 0.92, 0.94)


func _build_soccer_goals() -> void:
	# Goals placed fully inside the pitch bounds so nets never clip outside the boards
	_build_single_goal(Vector3(0.0, 0.0, -HALF_Z + 2.5), 0.0)
	_build_single_goal(Vector3(0.0, 0.0, HALF_Z - 2.5), 180.0)


func _build_single_goal(at: Vector3, rot_y: float) -> void:
	if ModelLoader.has_prop_model(&"soccer_goal"):
		var goal_prop := ArenaKit.prop(geometry, &"soccer_goal", at, Vector3(0.0, rot_y, 0.0))
		if goal_prop != null:
			return

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
	var can_spots: Array[Vector3] = [
		Vector3(-4.5, 0.0, -5.5),
		Vector3(4.5, 0.0, -5.5),
		Vector3(-4.5, 0.0, 5.5),
		Vector3(4.5, 0.0, 5.5),
	]
	var can_colors: Array[Color] = [BLAZE_ORANGE, CYAN_BLUE, CYAN_BLUE, BLAZE_ORANGE]
	for i in can_spots.size():
		var spot := can_spots[i]
		if ModelLoader.has_prop_model(&"inflatable_bunker"):
			var b := ArenaKit.prop(geometry, &"inflatable_bunker", spot)
			if b != null:
				continue
		var can_r := 1.1
		var can_h := 2.2
		ArenaKit.cylinder(geometry, can_r, can_h, spot + Vector3(0.0, can_h * 0.5, 0.0), can_colors[i], ArenaKit.SurfaceType.PLASTIC)

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

	# Visual decorated soccer ball with black pentagon patches
	var mesh_inst := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh_inst.mesh = sphere_mesh
	mesh_inst.material_override = ArenaKit.mat_styled(Color(0.96, 0.96, 0.98), ArenaKit.SurfaceType.PLASTIC)
	body.add_child(mesh_inst)
	var patch_dirs: Array[Vector3] = [
		Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK,
		Vector3(0.7, 0.7, 0.0).normalized(), Vector3(-0.7, 0.7, 0.0).normalized(),
		Vector3(0.0, 0.7, 0.7).normalized(), Vector3(0.0, 0.7, -0.7).normalized(),
	]
	for d in patch_dirs:
		var patch := MeshInstance3D.new()
		var p_cyl := CylinderMesh.new()
		p_cyl.top_radius = radius * 0.28
		p_cyl.bottom_radius = radius * 0.28
		p_cyl.height = 0.06
		p_cyl.radial_segments = 5
		patch.mesh = p_cyl
		patch.material_override = ArenaKit.mat_styled(Color(0.10, 0.12, 0.16), ArenaKit.SurfaceType.PLASTIC)
		var up_ref := Vector3.FORWARD if absf(d.y) > 0.9 else Vector3.UP
		var x_axis := up_ref.cross(d).normalized()
		var z_axis := d.cross(x_axis).normalized()
		patch.transform = Transform3D(Basis(x_axis, d, z_axis), d * (radius - 0.015))
		body.add_child(patch)


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
		# 3 Emissive floodlight heads + twilight stadium spotlight aimed at midfield
		for lx in [-1.0, 0.0, 1.0]:
			ArenaKit.deco_sphere(decor, 0.45, p + Vector3(lx, h, 0.0), FLOODLIGHT, 0.85, 4.0)
		var spot := SpotLight3D.new()
		spot.position = p + Vector3(0.0, h - 0.4, 0.0)
		spot.light_color = Color(0.95, 0.97, 1.0)
		spot.light_energy = 5.5
		spot.spot_range = 65.0
		spot.spot_angle = 52.0
		spot.spot_attenuation = 0.6
		decor.add_child(spot)
		spot.look_at(Vector3(p.x * 0.2, 0.0, p.z * 0.2), Vector3.UP)


func _build_spawns_and_points() -> void:
	# Team bases, Flag pedestals & Bomb sites
	team_bases = [Vector3(0.0, 0.0, -HALF_Z + 5.0), Vector3(0.0, 0.0, HALF_Z - 5.0)]
	flag_pedestals = [Vector3(0.0, 0.0, -HALF_Z + 5.0), Vector3(0.0, 0.0, HALF_Z - 5.0)]
	bomb_sites = {
		"A": Vector3(-19.5, 0.0, 0.0),
		"B": Vector3(19.5, 0.0, 0.0),
	}
	bomb_spawns = [Vector3(0.0, 0.0, HALF_Z - 6.0)]

	# 12 Spawn points across both halves and sidelines
	var spawns: Array[Vector3] = [
		Vector3(-12.0, 0.0, -HALF_Z + 4.5),
		Vector3(12.0, 0.0, -HALF_Z + 4.5),
		Vector3(-20.0, 0.0, -10.0),
		Vector3(20.0, 0.0, -10.0),
		Vector3(-6.0, 0.0, -2.0),
		Vector3(6.0, 0.0, -2.0),
		Vector3(-6.0, 0.0, 2.0),
		Vector3(6.0, 0.0, 2.0),
		Vector3(-20.0, 0.0, 10.0),
		Vector3(20.0, 0.0, 10.0),
		Vector3(-12.0, 0.0, HALF_Z - 4.5),
		Vector3(12.0, 0.0, HALF_Z - 4.5),
	]
	for p in spawns:
		add_spawn(p, Vector3.ZERO.direction_to(Vector3(0.0, 0.0, -p.z)))

	# Clear unobstructed roam points around bunkers & balls
	roam_points.clear()
	roam_points.append(Vector3(0.0, 0.0, 0.0))          # Center spot
	roam_points.append(Vector3(-11.5, 0.0, 0.0))        # West midfield lane
	roam_points.append(Vector3(11.5, 0.0, 0.0))         # East midfield lane
	roam_points.append(Vector3(0.0, 0.0, -8.5))         # North midfield
	roam_points.append(Vector3(0.0, 0.0, 8.5))          # South midfield
	roam_points.append(Vector3(-11.5, 0.0, -10.0))      # NW wing
	roam_points.append(Vector3(11.5, 0.0, 10.0))        # SE wing
	roam_points.append(Vector3(0.0, 0.0, -HALF_Z + 6.0)) # North penalty box
	roam_points.append(Vector3(0.0, 0.0, HALF_Z - 6.0))  # South penalty box

	# Power-up spot (Center Circle)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, 0.0))

	# Ammo buckets (4 corners of pitch)
	add_bucket(Vector3(-18.0, 0.0, -12.0), Color(0.2, 0.6, 0.95))
	add_bucket(Vector3(18.0, 0.0, -12.0), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(-18.0, 0.0, 12.0), Color(0.2, 0.6, 0.95))
	add_bucket(Vector3(18.0, 0.0, 12.0), Color(0.95, 0.45, 0.15))

	# Foam shield pickup grounded cleanly in midfield
	add_shield_pickup(Vector3(0.0, 0.0, 0.0))
