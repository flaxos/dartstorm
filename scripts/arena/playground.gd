class_name Playground
extends Arena
## PLAYGROUND: colorful neighborhood schoolyard battleground.
## Features a multi-tier jungle gym fort, yellow plastic spiral slide, monkey bars,
## swinging tire sets, stacked giant tractor tires, crawl tubes, spring rockers,
## and a soft rubber mulch ground.

const HALF_X := 28.0
const HALF_Z := 24.0

const MULCH := Color(0.65, 0.28, 0.2)
const MULCH_ACCENT := Color(0.25, 0.52, 0.82)
const SAND := Color(0.92, 0.82, 0.58)
const WOOD := Color(0.72, 0.5, 0.3)
const LOG := Color(0.5, 0.35, 0.2)
const STEEL := Color(0.85, 0.88, 0.92)
const RED := Color(0.92, 0.22, 0.2)
const YELLOW := Color(1.0, 0.82, 0.1)
const BLUE := Color(0.18, 0.45, 0.95)
const GREEN := Color(0.24, 0.75, 0.3)
const PURPLE := Color(0.65, 0.35, 0.85)
const FENCE := Color(0.88, 0.86, 0.8)

var _time: float = 0.0
var _swings: Array[Node3D] = []
var _rockers: Array[Node3D] = []


func _build() -> void:
	arena_name = "Playground"
	_build_sky_and_sun(-50.0, 0.1)
	_build_ground_and_fences()
	_build_jungle_gym()
	_build_monkey_bars()
	_build_swing_sets()
	_build_tire_stacks_and_tubes()
	_build_seesaw_and_rockers()
	_build_sandpit()
	_build_spawns_and_points()


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	for i in _swings.size():
		_swings[i].rotation.x = sin(_time * 1.8 + float(i) * 1.1) * 0.35
	for i in _rockers.size():
		_rockers[i].rotation.z = sin(_time * 2.4 + float(i) * 1.4) * 0.12


func _build_ground_and_fences() -> void:
	# Main rubber mulch ground
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), MULCH, Vector3.ZERO, ArenaKit.SurfaceType.DEFAULT)
	# Center blue court inlay
	ArenaKit.box(geometry, Vector3(18.0, 0.05, 16.0), Vector3(0.0, 0.02, 0.0), MULCH_ACCENT, Vector3.ZERO, ArenaKit.SurfaceType.DEFAULT)

	# Surrounding schoolyard perimeter fences
	var wall_h := 3.8
	var thick := 0.4
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z - thick * 0.5), FENCE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z + thick * 0.5), FENCE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, wall_h * 0.5, 0.0), FENCE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, wall_h * 0.5, 0.0), FENCE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)

	# Schoolyard backdrop lawn
	ArenaKit.deco_box(decor, Vector3(300.0, 0.2, 300.0), Vector3(0.0, -0.6, 0.0), Color(0.32, 0.65, 0.28))


func _build_jungle_gym() -> void:
	# Tower A (West, height 2.2m)
	var pos_a := Vector3(-4.5, 0.0, 0.0)
	var deck_a_h := 2.2
	var size_a := Vector3(4.2, 0.3, 4.2)
	# 4 wooden support stilts
	for ox in [-1.8, 1.8]:
		for oz in [-1.8, 1.8]:
			ArenaKit.cylinder(geometry, 0.16, deck_a_h, pos_a + Vector3(ox, deck_a_h * 0.5, oz), WOOD, ArenaKit.SurfaceType.WOOD)
	# Platform slab
	ArenaKit.box(geometry, size_a, pos_a + Vector3(0.0, deck_a_h, 0.0), RED, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	# Safety railings
	ArenaKit.box(geometry, Vector3(4.2, 0.9, 0.15), pos_a + Vector3(0.0, deck_a_h + 0.45, -2.0), YELLOW, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(4.2, 0.9, 0.15), pos_a + Vector3(0.0, deck_a_h + 0.45, 2.0), YELLOW, Vector3.ZERO, ArenaKit.SurfaceType.METAL)

	# Climbing Ramp onto Tower A from South
	ArenaKit.ramp(geometry, pos_a + Vector3(0.0, 0.0, 5.5), pos_a + Vector3(0.0, deck_a_h, 2.1), 2.2, BLUE, 0.25, ArenaKit.SurfaceType.PLASTIC)

	# Tower B (East, height 3.5m)
	var pos_b := Vector3(4.5, 0.0, 0.0)
	var deck_b_h := 3.5
	var size_b := Vector3(4.5, 0.3, 4.5)
	for ox in [-2.0, 2.0]:
		for oz in [-2.0, 2.0]:
			ArenaKit.cylinder(geometry, 0.18, deck_b_h, pos_b + Vector3(ox, deck_b_h * 0.5, oz), WOOD, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, size_b, pos_b + Vector3(0.0, deck_b_h, 0.0), BLUE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	# Pyramid canopy roof over Tower B
	ArenaKit.deco_cone(decor, 3.4, 2.2, pos_b + Vector3(0.0, deck_b_h + 2.0, 0.0), YELLOW)

	# Suspension bridge between Tower A and Tower B
	var bridge_w := 1.8
	ArenaKit.ramp(geometry, pos_a + Vector3(2.1, deck_a_h, 0.0), pos_b + Vector3(-2.2, deck_b_h, 0.0), bridge_w, WOOD, 0.2, ArenaKit.SurfaceType.WOOD)
	# Bridge side safety ropes
	ArenaKit.box(geometry, Vector3(5.0, 0.8, 0.12), (pos_a + pos_b) * 0.5 + Vector3(0.0, (deck_a_h + deck_b_h) * 0.5 + 0.4, -bridge_w * 0.5), RED, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(5.0, 0.8, 0.12), (pos_a + pos_b) * 0.5 + Vector3(0.0, (deck_a_h + deck_b_h) * 0.5 + 0.4, bridge_w * 0.5), RED, Vector3.ZERO, ArenaKit.SurfaceType.METAL)

	# Yellow plastic slide from Tower B to East
	if ModelLoader.has_prop_model(&"playground_slide"):
		var slide_prop := ArenaKit.prop(geometry, &"playground_slide", pos_b + Vector3(1.2, 0.0, 0.0))
		if slide_prop == null:
			ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h, 0.0), pos_b + Vector3(7.5, 0.0, 0.0), 1.6, YELLOW, 0.25, ArenaKit.SurfaceType.PLASTIC)
			ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h + 0.35, -0.8), pos_b + Vector3(7.5, 0.35, -0.8), 0.15, RED, 0.25, ArenaKit.SurfaceType.PLASTIC)
			ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h + 0.35, 0.8), pos_b + Vector3(7.5, 0.35, 0.8), 0.15, RED, 0.25, ArenaKit.SurfaceType.PLASTIC)
	else:
		ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h, 0.0), pos_b + Vector3(7.5, 0.0, 0.0), 1.6, YELLOW, 0.25, ArenaKit.SurfaceType.PLASTIC)
		ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h + 0.35, -0.8), pos_b + Vector3(7.5, 0.35, -0.8), 0.15, RED, 0.25, ArenaKit.SurfaceType.PLASTIC)
		ArenaKit.ramp(geometry, pos_b + Vector3(2.2, deck_b_h + 0.35, 0.8), pos_b + Vector3(7.5, 0.35, 0.8), 0.15, RED, 0.25, ArenaKit.SurfaceType.PLASTIC)

	# Jump Pad on North side bouncing onto Tower B
	add_jump_pad(pos_b + Vector3(0.0, 0.0, -4.5), 11.5)


func _build_monkey_bars() -> void:
	var base_z := -12.0
	var h := 2.4
	# Left post and platform
	ArenaKit.box(geometry, Vector3(1.4, h, 1.4), Vector3(-6.0, h * 0.5, base_z), GREEN, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	# Right post and platform
	ArenaKit.box(geometry, Vector3(1.4, h, 1.4), Vector3(6.0, h * 0.5, base_z), GREEN, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	# Horizontal ladder spine
	ArenaKit.box(geometry, Vector3(12.0, 0.2, 0.8), Vector3(0.0, h, base_z), STEEL, Vector3.ZERO, ArenaKit.SurfaceType.METAL)
	# 9 rungs
	for i in range(-5, 6):
		ArenaKit.cylinder(geometry, 0.06, 1.1, Vector3(float(i), h, base_z), STEEL, ArenaKit.SurfaceType.METAL)


func _build_swing_sets() -> void:
	var at := Vector3(14.0, 0.0, 10.0)
	var h := 3.2
	# Top beam
	ArenaKit.cylinder(geometry, 0.12, 11.0, at + Vector3(0.0, h, 0.0), RED, ArenaKit.SurfaceType.METAL)
	# A-frame legs
	for ox in [-5.2, 5.2]:
		ArenaKit.box(geometry, Vector3(0.18, h * 1.1, 0.18), at + Vector3(ox, h * 0.5, -1.1), BLUE, Vector3(18.0, 0.0, 0.0), ArenaKit.SurfaceType.METAL)
		ArenaKit.box(geometry, Vector3(0.18, h * 1.1, 0.18), at + Vector3(ox, h * 0.5, 1.1), BLUE, Vector3(-18.0, 0.0, 0.0), ArenaKit.SurfaceType.METAL)
	# 3 hanging swings
	for i in [-1, 0, 1]:
		var swing_root := Node3D.new()
		swing_root.position = at + Vector3(float(i) * 2.8, h, 0.0)
		decor.add_child(swing_root)
		# Chains
		ArenaKit.deco_box(swing_root, Vector3(0.05, 2.2, 0.05), Vector3(-0.4, -1.1, 0.0), STEEL)
		ArenaKit.deco_box(swing_root, Vector3(0.05, 2.2, 0.05), Vector3(0.4, -1.1, 0.0), STEEL)
		# Seat (collidable in geometry so it blocks darts!)
		var _seat := ArenaKit.box(geometry, Vector3(1.1, 0.12, 0.45), at + Vector3(float(i) * 2.8, 0.8, 0.0), PURPLE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
		_swings.append(swing_root)


func _build_tire_stacks_and_tubes() -> void:
	# Tire Stack 1 (West cover)
	_build_tire_pile(Vector3(-14.0, 0.0, 8.0), 3)
	# Tire Stack 2 (Mid-North cover)
	_build_tire_pile(Vector3(-12.0, 0.0, -6.0), 2)
	# Tire Stack 3 (East cover)
	_build_tire_pile(Vector3(12.0, 0.0, -8.0), 3)

	# Plastic crawl tunnel 1 (Blue)
	_build_crawl_tube(Vector3(-6.0, 0.0, 11.0), 1.2, 5.5, BLUE)
	# Plastic crawl tunnel 2 (Yellow)
	_build_crawl_tube(Vector3(5.0, 0.0, -11.0), 1.2, 5.5, YELLOW)


func _build_tire_pile(at: Vector3, count: int) -> void:
	var radius := 1.2
	var h := 0.65
	for i in count:
		var c: Color = [Color(0.2, 0.2, 0.22), YELLOW, GREEN, PURPLE][i % 4]
		ArenaKit.cylinder(geometry, radius, h, at + Vector3(0.0, h * 0.5 + float(i) * h, 0.0), c, ArenaKit.SurfaceType.DEFAULT)


func _build_crawl_tube(at: Vector3, radius: float, length: float, color: Color) -> void:
	# Large hollow-style cover tube with collision
	ArenaKit.box(geometry, Vector3(radius * 2.0, radius * 1.8, length), at + Vector3(0.0, radius * 0.9, 0.0), color, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)


func _build_seesaw_and_rockers() -> void:
	# Seesaw on South-West
	var pos_sw := Vector3(-14.0, 0.0, -12.0)
	ArenaKit.cylinder(geometry, 0.25, 0.8, pos_sw + Vector3(0.0, 0.4, 0.0), RED, ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(5.0, 0.15, 0.55), pos_sw + Vector3(0.0, 0.8, 0.0), YELLOW, Vector3(0.0, 0.0, 12.0), ArenaKit.SurfaceType.WOOD)
	# Seats
	ArenaKit.box(geometry, Vector3(0.6, 0.1, 0.55), pos_sw + Vector3(-2.2, 0.35, 0.0), BLUE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.box(geometry, Vector3(0.6, 0.1, 0.55), pos_sw + Vector3(2.2, 1.25, 0.0), BLUE, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)

	# Spring rockers
	_build_rocker(Vector3(-18.0, 0.0, -4.0), YELLOW, "duck")
	_build_rocker(Vector3(-18.0, 0.0, 4.0), RED, "horse")


func _build_rocker(at: Vector3, color: Color, _kind: String) -> void:
	var root := Node3D.new()
	root.position = at
	decor.add_child(root)
	# Spring base
	ArenaKit.cylinder(geometry, 0.2, 0.5, at + Vector3(0.0, 0.25, 0.0), STEEL, ArenaKit.SurfaceType.METAL)
	# Body
	ArenaKit.box(geometry, Vector3(1.2, 0.6, 0.45), at + Vector3(0.0, 0.8, 0.0), color, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	_rockers.append(root)


func _build_sandpit() -> void:
	var at := Vector3(15.0, 0.0, -14.0)
	var w := 7.0
	var d := 6.0
	# Sand ground
	ArenaKit.box(geometry, Vector3(w, 0.1, d), at + Vector3(0.0, 0.05, 0.0), SAND, Vector3.ZERO, ArenaKit.SurfaceType.DEFAULT)
	# Border timber logs
	ArenaKit.box(geometry, Vector3(w + 0.6, 0.4, 0.4), at + Vector3(0.0, 0.2, -d * 0.5), LOG, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(w + 0.6, 0.4, 0.4), at + Vector3(0.0, 0.2, d * 0.5), LOG, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.4, 0.4, d), at + Vector3(-w * 0.5, 0.2, 0.0), LOG, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.4, 0.4, d), at + Vector3(w * 0.5, 0.2, 0.0), LOG, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_spawns_and_points() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(-20.0, 0.0, 0.0))  # Blue Base (West schoolyard)
	team_bases.append(Vector3(20.0, 0.0, 0.0))   # Orange Base (East sandbox)

	# 12 Spawn points spread evenly
	var spawn_coords: Array[Vector3] = [
		Vector3(-22.0, 0.0, -6.0),
		Vector3(-22.0, 0.0, 6.0),
		Vector3(-18.0, 0.0, -14.0),
		Vector3(-18.0, 0.0, 14.0),
		Vector3(-4.5, 2.5, 0.0),   # On Tower A deck
		Vector3(4.5, 3.8, 0.0),    # On Tower B deck
		Vector3(0.0, 0.0, -16.0),
		Vector3(0.0, 0.0, 16.0),
		Vector3(18.0, 0.0, -14.0),
		Vector3(18.0, 0.0, 14.0),
		Vector3(22.0, 0.0, -6.0),
		Vector3(22.0, 0.0, 6.0),
	]
	for p in spawn_coords:
		add_spawn(p, Vector3.ZERO.direction_to(Vector3(-p.x, 0.0, -p.z)))

	# Roam points for bot navigation
	roam_points.clear()
	roam_points.append(Vector3(-4.5, 2.5, 0.0))
	roam_points.append(Vector3(4.5, 3.8, 0.0))
	roam_points.append(Vector3(0.0, 0.0, 0.0))
	roam_points.append(Vector3(0.0, 0.0, -12.0))
	roam_points.append(Vector3(0.0, 0.0, 12.0))
	roam_points.append(Vector3(-14.0, 0.0, 8.0))
	roam_points.append(Vector3(14.0, 0.0, 10.0))
	roam_points.append(Vector3(15.0, 0.0, -14.0))
	roam_points.append(Vector3(-14.0, 0.0, -12.0))

	# Power-up spot (Top of Tower B lookout)
	power_up_spots.clear()
	power_up_spots.append(Vector3(4.5, 3.8, 0.0))

	# Ammo buckets
	add_bucket(Vector3(-12.0, 0.0, 0.0), Color(0.95, 0.45, 0.2))
	add_bucket(Vector3(12.0, 0.0, 0.0), Color(0.2, 0.65, 0.95))
	add_bucket(Vector3(0.0, 0.0, -8.0), Color(0.95, 0.85, 0.2))
	add_bucket(Vector3(0.0, 0.0, 8.0), Color(0.3, 0.85, 0.4))

	# Foam shield pickup
	var shield := ShieldPickup.new()
	shield.position = Vector3(0.0, 0.6, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
