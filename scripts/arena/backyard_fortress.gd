class_name BackyardFortress
extends Arena
## BACKYARD FORTRESS: the classic blue-versus-orange backyard.
##
## Layout (top-down, north is -Z):
##
##            [mirror]      hedge      [mirror]        <- Mirror Alley
##   BLUE  ==walkway==>  TREEHOUSE  <==walkway==  ORANGE
##   FORT      crates & foam barriers             FORT
##                 ~~~ wind zone + giant fan ~~~       <- Windy Way
##
## Blue fort is at -X, orange at +X. Both forts are raised and joined to the
## treehouse by sloping walkways; a ramp (south) and a slide (north) also reach
## the treehouse deck, and two trampolines bounce you up onto it.

const LAWN_SHADER := preload("res://assets/materials/lawn.gdshader")

const HALF_X := 34.0
const HALF_Z := 24.0
const FORT_HEIGHT := 2.6
const DECK_HEIGHT := 4.6
const DECK_HALF := 4.5

const GRASS := Color(0.36, 0.72, 0.28)
const WOOD := Color(0.76, 0.55, 0.33)
const WOOD_DARK := Color(0.55, 0.37, 0.22)
const TRUNK := Color(0.45, 0.3, 0.18)
const FENCE := Color(0.97, 0.94, 0.86)
const FENCE_POST := Color(0.85, 0.8, 0.7)
const BLUE := Color(0.15, 0.45, 1.0)
const BLUE_DARK := Color(0.1, 0.3, 0.75)
const ORANGE := Color(1.0, 0.5, 0.1)
const ORANGE_DARK := Color(0.85, 0.38, 0.05)
const LEAF := Color(0.25, 0.65, 0.25)
const LEAF_LIGHT := Color(0.38, 0.78, 0.3)
const HEDGE := Color(0.18, 0.52, 0.24)
const SLIDE := Color(1.0, 0.85, 0.15)
const FOAM := [Color(1.0, 0.45, 0.7), Color(1.0, 0.85, 0.2), Color(0.3, 0.85, 0.95), Color(0.6, 0.9, 0.2)]

var _swings: Array[Node3D] = []
var _sprinkler_arm: Node3D
var _duck: Node3D
var _time: float = 0.0
var _chirp_left: float = 2.0
var _rng := RandomNumberGenerator.new()
var dog_house: DogHouse


func _build() -> void:
	arena_name = "Backyard Fortress"
	_build_sky_and_sun()
	_build_ground_and_fence()
	var c0 := GameMode.team_color(0)
	var c1 := GameMode.team_color(1)
	_build_fort(-1.0, c0, c0.darkened(0.25), "%s FORT" % GameMode.team_name(0))
	_build_fort(1.0, c1, c1.darkened(0.25), "%s FORT" % GameMode.team_name(1))
	_build_treehouse()
	_build_mirror_alley()
	_build_windy_way()
	_build_cover()
	_build_targets()
	_build_spawns()
	_build_props()
	_build_neighbourhood()


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	for i in _swings.size():
		_swings[i].rotation.x = sin(_time * 1.9 + i * 1.3) * 0.45
	if _sprinkler_arm != null:
		_sprinkler_arm.rotation.y = sin(_time * 0.9) * 1.1
	if _duck != null:
		_duck.position.y = 0.38 + sin(_time * 2.3) * 0.03
		_duck.rotation.y += delta * 0.4
	# Birdsong from the trees around the yard.
	_chirp_left -= delta
	if _chirp_left <= 0.0:
		_chirp_left = _rng.randf_range(2.5, 6.5)
		var angle := _rng.randf() * TAU
		var spot := Vector3(cos(angle) * 45.0, _rng.randf_range(6.0, 10.0), sin(angle) * 35.0)
		Sfx.play_at(&"chirp", spot, _rng.randf_range(0.85, 1.3), -8.0)


# --- Mood -------------------------------------------------------------------

# --- Yard -------------------------------------------------------------------

func _build_ground_and_fence() -> void:
	var lawn_material := ShaderMaterial.new()
	lawn_material.shader = LAWN_SHADER
	var ground := ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), GRASS)
	(ground.get_node("Mesh") as MeshInstance3D).material_override = lawn_material
	# The rest of the neighbourhood's grass (looks only).
	ArenaKit.deco_box(decor, Vector3(420.0, 0.2, 420.0), Vector3(0.0, -0.16, 0.0), Color(0.33, 0.66, 0.27))

	var height := 4.0
	var thick := 0.5
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, height, thick), Vector3(0.0, height * 0.5, -HALF_Z - thick * 0.5), FENCE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, height, thick), Vector3(0.0, height * 0.5, HALF_Z + thick * 0.5), FENCE)
	ArenaKit.box(geometry, Vector3(thick, height, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, height * 0.5, 0.0), FENCE)
	ArenaKit.box(geometry, Vector3(thick, height, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, height * 0.5, 0.0), FENCE)
	# Posts and a top rail so it reads as a garden fence, not a wall.
	var x := -HALF_X
	while x <= HALF_X + 0.01:
		for z_side: float in [-1.0, 1.0]:
			ArenaKit.deco_box(decor, Vector3(0.45, height + 0.5, 0.75), Vector3(x, (height + 0.5) * 0.5, z_side * (HALF_Z + thick * 0.5)), FENCE_POST)
		x += 4.0
	var z := -HALF_Z
	while z <= HALF_Z + 0.01:
		for x_side: float in [-1.0, 1.0]:
			ArenaKit.deco_box(decor, Vector3(0.75, height + 0.5, 0.45), Vector3(x_side * (HALF_X + thick * 0.5), (height + 0.5) * 0.5, z), FENCE_POST)
		z += 4.0
	# Invisible walls above the fence so nobody trampolines into next door.
	var sky_wall := 14.0
	var wall_y := height + sky_wall * 0.5
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 2.0, sky_wall, thick), Vector3(0.0, wall_y, -HALF_Z - thick * 0.5))
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 2.0, sky_wall, thick), Vector3(0.0, wall_y, HALF_Z + thick * 0.5))
	ArenaKit.blocker(geometry, Vector3(thick, sky_wall, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, wall_y, 0.0))
	ArenaKit.blocker(geometry, Vector3(thick, sky_wall, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, wall_y, 0.0))


## One team fort. `side` is -1 for the west (blue) end, +1 for the east (orange).
func _build_fort(side: float, main: Color, dark: Color, title: String) -> void:
	var front := side * 24.0
	var back := side * 32.0
	var centre_x := side * 28.0
	var top := FORT_HEIGHT

	# Raised platform.
	ArenaKit.box(geometry, Vector3(8.0, FORT_HEIGHT, 12.0), Vector3(centre_x, FORT_HEIGHT * 0.5, 0.0), main)
	ArenaKit.deco_box(decor, Vector3(8.1, 0.25, 12.1), Vector3(centre_x, FORT_HEIGHT - 0.1, 0.0), WOOD)

	# Two ramps down toward the middle of the yard.
	for ramp_z: float in [-4.5, 4.5]:
		ArenaKit.ramp(geometry, Vector3(side * 17.5, 0.0, ramp_z), Vector3(front, top, ramp_z), 3.0, WOOD)

	# Battlements: low walls to duck behind, with gaps to shoot through.
	var wall_y := top + 0.5
	for wall_z: float in [-2.15, 2.15]:
		ArenaKit.box(geometry, Vector3(0.3, 1.0, 1.7), Vector3(front - side * 0.15, wall_y, wall_z), dark)
	for wall_z: float in [-5.85, 5.85]:
		ArenaKit.box(geometry, Vector3(3.0, 1.0, 0.3), Vector3(side * 25.5, wall_y, wall_z), dark)
		ArenaKit.box(geometry, Vector3(3.5, 1.0, 0.3), Vector3(side * 30.25, wall_y, wall_z), dark)
	ArenaKit.box(geometry, Vector3(0.3, 2.4, 12.0), Vector3(back - side * 0.15, top + 1.2, 0.0), dark)

	# Roof over the back half, on four posts.
	for post_z: float in [-5.6, 5.6]:
		ArenaKit.cylinder(geometry, 0.16, 3.0, Vector3(side * 28.2, top + 1.5, post_z), WOOD_DARK)
	ArenaKit.box(geometry, Vector3(4.6, 0.25, 12.6), Vector3(side * 29.9, top + 3.1, 0.0), dark.lightened(0.1))

	# Landmark: a huge team flag and a sign you can read from across the yard.
	ArenaKit.deco_cylinder(decor, 0.12, 8.0, Vector3(side * 30.6, top + 3.2 + 4.0, 0.0), Color(0.92, 0.92, 0.96))
	ArenaKit.deco_box(decor, Vector3(0.12, 2.0, 3.4), Vector3(side * 30.6, top + 3.2 + 6.8, 1.8), main, Vector3.ZERO, 0.4)
	ArenaKit.sign_text(decor, title, Vector3(back - side * 0.35, top + 1.5, 0.0), Vector3(0.0, -90.0 * side, 0.0), Color(1.0, 0.96, 0.88), 120, 0.012)

	add_bucket(Vector3(side * 21.6, 0.0, 0.0), main)


func _build_treehouse() -> void:
	# Trunk and deck.
	ArenaKit.cylinder(geometry, 1.5, 10.0, Vector3(0.0, 5.0, 0.0), TRUNK)
	ArenaKit.box(geometry, Vector3(DECK_HALF * 2.0, 0.4, DECK_HALF * 2.0), Vector3(0.0, DECK_HEIGHT - 0.2, 0.0), WOOD)
	for post_x: float in [-4.1, 4.1]:
		for post_z: float in [-4.1, 4.1]:
			ArenaKit.cylinder(geometry, 0.25, DECK_HEIGHT - 0.4, Vector3(post_x, (DECK_HEIGHT - 0.4) * 0.5, post_z), WOOD_DARK)

	# Railings with a gap in the middle of each side for the four ways up.
	var rail_y := DECK_HEIGHT + 0.5
	for edge: float in [-1.0, 1.0]:
		for piece: float in [-2.95, 2.95]:
			ArenaKit.box(geometry, Vector3(0.2, 1.0, 3.1), Vector3(edge * (DECK_HALF - 0.1), rail_y, piece), WOOD_DARK)
			ArenaKit.box(geometry, Vector3(3.1, 1.0, 0.2), Vector3(piece, rail_y, edge * (DECK_HALF - 0.1)), WOOD_DARK)

	# Leafy canopy: the landmark you can see from anywhere.
	var leaves := [
		[Vector3(0.0, 12.0, 0.0), 4.6, LEAF], [Vector3(3.0, 10.9, 1.6), 3.1, LEAF_LIGHT],
		[Vector3(-2.7, 11.1, -1.9), 3.3, LEAF_LIGHT], [Vector3(0.6, 10.6, -3.2), 2.9, LEAF],
		[Vector3(-1.2, 10.8, 3.2), 2.9, LEAF],
	]
	for leaf in leaves:
		ArenaKit.deco_sphere(decor, leaf[1], leaf[0], leaf[2], 0.85)

	# Walkways from each fort up to the deck, with side rails for cover.
	for side: float in [-1.0, 1.0]:
		var low := Vector3(side * 24.0, FORT_HEIGHT, 0.0)
		var high := Vector3(side * DECK_HALF, DECK_HEIGHT, 0.0)
		ArenaKit.ramp(geometry, low, high, 2.6, WOOD)
		for rail_z: float in [-1.3, 1.3]:
			var lift := Vector3(0.0, 0.7, rail_z)
			ArenaKit.ramp(geometry, low + lift, high + lift, 0.15, WOOD_DARK, 0.7)
		for post_x: float in [10.0, 17.0]:
			var deck_y := lerpf(DECK_HEIGHT, FORT_HEIGHT, (post_x - DECK_HALF) / (24.0 - DECK_HALF))
			ArenaKit.cylinder(geometry, 0.22, deck_y - 0.3, Vector3(side * post_x, (deck_y - 0.3) * 0.5, 0.0), WOOD_DARK)

	# South: a wooden ramp. North: a bright yellow slide.
	ArenaKit.ramp(geometry, Vector3(0.0, 0.0, 14.5), Vector3(0.0, DECK_HEIGHT, DECK_HALF), 2.8, WOOD_DARK)
	var slide_low := Vector3(0.0, 0.0, -14.0)
	var slide_high := Vector3(0.0, DECK_HEIGHT, -DECK_HALF)
	ArenaKit.ramp(geometry, slide_low, slide_high, 2.4, SLIDE)
	for rail_x: float in [-1.25, 1.25]:
		var lift := Vector3(rail_x, 0.35, 0.0)
		ArenaKit.ramp(geometry, slide_low + lift, slide_high + lift, 0.12, SLIDE.darkened(0.2), 0.35)

	# Environmental hazards and power-ups:
	# Ice slick down the yellow slide!
	add_ice_slick(Vector3(0.0, DECK_HEIGHT * 0.5, -9.5), Vector3(2.4, 0.2, 9.2), Vector3(0.0, -0.4, -1.0), Vector3(-24.0, 0.0, 0.0))
	# Foam Shield on the treehouse deck
	add_shield_pickup(Vector3(0.0, DECK_HEIGHT, -2.2))
	# Water puddles in the courtyard and near the garden tap
	add_water_puddle(Vector3(0.0, 0.0, 8.5), 2.5)
	add_water_puddle(Vector3(-11.5, 0.0, 6.0), 2.6)
	# Updraft wind vent near the central walkway
	add_wind_vent(Vector3(8.5, 0.0, 0.0), 1.8, 14.5)
	# Foam Grenades and Elemental Infusion pickups
	add_grenade_pickup(Vector3(-14.0, 0.0, -14.0))
	add_grenade_pickup(Vector3(14.0, 0.0, 14.0))
	add_elemental_pickup(Vector3(0.0, 0.0, 14.0), DartData.Element.FIRE)
	add_elemental_pickup(Vector3(3.2, DECK_HEIGHT, 0.0), DartData.Element.ICE)
	add_elemental_pickup(Vector3(0.0, 0.0, -14.0), DartData.Element.LIGHTNING)

	# Trampolines that bounce you onto the deck corners.
	add_jump_pad(Vector3(6.8, 0.0, -6.8))
	add_jump_pad(Vector3(-6.8, 0.0, 6.8))
	# Where the Chainstorm lands in power-up mode: the treehouse deck.
	add_power_up_spot(Vector3(0.0, DECK_HEIGHT, 3.0))

	add_bucket(Vector3(0.0, 0.0, 3.0), Color(0.95, 0.95, 0.9))
	add_roam_point(Vector3(0.0, DECK_HEIGHT, 3.2))
	add_roam_point(Vector3(3.2, DECK_HEIGHT, 0.0))
	add_roam_point(Vector3(-3.2, DECK_HEIGHT, 0.0))
	add_roam_point(Vector3(-28.0, FORT_HEIGHT, 0.0))
	add_roam_point(Vector3(28.0, FORT_HEIGHT, 0.0))


## North lane: a big hedge with a corridor behind it and two angled mirrors on
## the fence, so you can bank shots around the hedge.
func _build_mirror_alley() -> void:
	ArenaKit.box(geometry, Vector3(9.0, 2.6, 4.0), Vector3(0.0, 1.3, -18.5), HEDGE)
	ArenaKit.deco_sphere(decor, 2.3, Vector3(-3.0, 2.6, -18.5), HEDGE.lightened(0.08), 0.7)
	ArenaKit.deco_sphere(decor, 2.5, Vector3(0.5, 2.7, -18.5), HEDGE.lightened(0.04), 0.7)
	ArenaKit.deco_sphere(decor, 2.2, Vector3(3.3, 2.6, -18.5), HEDGE.lightened(0.1), 0.7)
	add_mirror(Vector3(-9.0, 2.2, -22.8), 15.0, Vector2(6.0, 3.6), 0.4)
	add_mirror(Vector3(9.0, 2.2, -22.8), -15.0, Vector2(6.0, 3.6), 0.4)
	ArenaKit.sign_text(decor, "MIRROR ALLEY", Vector3(0.0, 3.5, -16.0), Vector3.ZERO, Color(0.6, 0.95, 1.0), 72, 0.01)
	add_bucket(Vector3(0.0, 0.0, -22.0), Color(0.3, 0.85, 0.95))


## South lane: a cross-wind from a giant fan pushes darts toward the middle.
func _build_windy_way() -> void:
	add_wind_zone(Vector3(0.0, 2.6, 17.6), Vector3(24.0, 5.2, 12.4), Vector3(0.0, 0.0, -1.0), 40.0)
	ArenaKit.sign_text(decor, "WINDY WAY", Vector3(0.0, 5.8, 23.7), Vector3(0.0, 180.0, 0.0), Color(1.0, 0.96, 0.88), 72, 0.01)
	add_bucket(Vector3(0.0, 0.0, 20.5), Color(0.6, 0.9, 0.2))


func _build_cover() -> void:
	for side: float in [-1.0, 1.0]:
		# Wooden crates: low enough to hop onto.
		_crate(Vector3(side * 11.0, 0.0, 5.5))
		_crate(Vector3(side * 11.0, 0.0, 6.65))
		_crate(Vector3(side * 11.0, 1.1, 6.1))
		_crate(Vector3(side * 13.0, 0.0, -6.0))
		_crate(Vector3(side * 17.0, 0.0, -13.0))
		_crate(Vector3(side * 18.15, 0.0, -13.0))
		_crate(Vector3(side * 9.5, 0.0, 18.0))
		_crate(Vector3(side * 20.0, 0.0, 14.0))
		# Squishy foam barriers in loud colours.
		_barrier(Vector3(side * 15.0, 0.0, 2.6), 90.0, 0)
		_barrier(Vector3(side * 8.0, 0.0, -9.5), 30.0 * side, 1)
		_barrier(Vector3(side * 8.5, 0.0, 9.8), -30.0 * side, 2)
		_barrier(Vector3(side * 14.0, 0.0, -19.5), 0.0, 3)
		_barrier(Vector3(side * 15.0, 0.0, 21.0), 0.0, 0)
		_barrier(Vector3(side * 21.0, 0.0, -8.6), 90.0, 2)
		_barrier(Vector3(side * 21.0, 0.0, 8.6), 90.0, 1)
		add_roam_point(Vector3(side * 13.0, 0.0, -10.0))
		add_roam_point(Vector3(side * 13.0, 0.0, 11.0))
		add_roam_point(Vector3(side * 6.5, 0.0, -20.0))


func _crate(at: Vector3) -> void:
	var size := 1.1
	var centre := at + Vector3(0.0, size * 0.5, 0.0)
	ArenaKit.box(geometry, Vector3.ONE * size, centre, WOOD)
	ArenaKit.deco_box(decor, Vector3(size + 0.04, 0.14, size + 0.04), centre + Vector3(0.0, size * 0.5 - 0.07, 0.0), WOOD_DARK)
	ArenaKit.deco_box(decor, Vector3(size + 0.04, 0.14, size + 0.04), centre - Vector3(0.0, size * 0.5 - 0.07, 0.0), WOOD_DARK)


func _barrier(at: Vector3, yaw_degrees: float, color_index: int) -> void:
	var tint: Color = FOAM[color_index % FOAM.size()]
	ArenaKit.box(geometry, Vector3(2.6, 1.3, 0.6), at + Vector3(0.0, 0.65, 0.0), tint, Vector3(0.0, yaw_degrees, 0.0))


func _build_targets() -> void:
	add_target(Vector3(-19.0, 2.7, -23.7), 0.0)
	add_target(Vector3(19.0, 2.7, -23.7), 0.0)
	add_target(Vector3(-15.0, 2.7, 23.7), 180.0)
	add_target(Vector3(15.0, 2.7, 23.7), 180.0)
	add_target(Vector3(0.0, 7.4, 1.62), 0.0)
	add_target(Vector3(0.0, 7.4, -1.62), 180.0)


func _build_spawns() -> void:
	var centre := Vector3.ZERO
	team_bases = [Vector3(-28.0, FORT_HEIGHT, 0.0), Vector3(28.0, FORT_HEIGHT, 0.0)]
	for side: float in [-1.0, 1.0]:
		add_spawn(Vector3(side * 28.5, FORT_HEIGHT, -3.0), centre)
		add_spawn(Vector3(side * 28.5, FORT_HEIGHT, 3.0), centre)
		add_spawn(Vector3(side * 24.0, 0.0, -18.0), centre)
		add_spawn(Vector3(side * 24.0, 0.0, 18.0), centre)
	add_spawn(Vector3(-12.0, 0.0, -21.5), centre)
	add_spawn(Vector3(12.0, 0.0, 21.5), centre)


# --- Backyard life (mostly looks; the dog house and swing legs are solid) ---

func _build_props() -> void:
	_rng.seed = 4242
	# Dog house in the orange half; the door faces the middle of the yard.
	dog_house = DogHouse.new()
	dog_house.position = Vector3(29.5, 0.0, -15.5)
	dog_house.rotation_degrees.y = -90.0
	geometry.add_child(dog_house)
	_build_swing_set(Vector3(-29.5, 0.0, 15.0))
	_build_paddling_pool(Vector3(-28.5, 0.0, -15.5))
	_build_sprinkler(Vector3(-31.5, 0.0, -20.0))
	_build_gnome(Vector3(5.6, 0.0, -16.0), 160.0)
	_build_gnome(Vector3(-2.4, 0.0, -2.4), 45.0)
	_build_gnome(Vector3(22.8, 0.0, 7.4), -100.0)
	_build_flower_bed(Vector3(-24.5, 0.0, 23.3), 14.0)
	_build_flower_bed(Vector3(24.5, 0.0, 23.3), 14.0)
	_build_flower_bed(Vector3(-25.0, 0.0, -23.3), 12.0)


func _build_swing_set(at: Vector3) -> void:
	var frame := Color(0.95, 0.35, 0.35)
	var height := 2.6
	for z_side: float in [-1.0, 1.0]:
		for x_side: float in [-1.0, 1.0]:
			# Four splayed legs (solid, so you can't walk through them).
			var leg := ArenaKit.box(geometry, Vector3(0.12, height + 0.1, 0.12),
					at + Vector3(x_side * 0.55, height * 0.5, z_side * 2.0), frame)
			leg.rotation_degrees.z = -x_side * 12.0
	ArenaKit.deco_cylinder(decor, 0.08, 4.3, at + Vector3(0.0, height, 0.0), frame, Vector3(90.0, 0.0, 0.0))
	for z_offset: float in [-0.9, 0.9]:
		var pivot := Node3D.new()
		pivot.position = at + Vector3(0.0, height, z_offset)
		decor.add_child(pivot)
		for rope_z: float in [-0.25, 0.25]:
			ArenaKit.deco_cylinder(pivot, 0.015, 1.9, Vector3(0.0, -0.95, rope_z), Color(0.9, 0.9, 0.85))
		ArenaKit.deco_box(pivot, Vector3(0.36, 0.06, 0.6), Vector3(0.0, -1.9, 0.0), Color(1.0, 0.85, 0.2))
		_swings.append(pivot)


func _build_paddling_pool(at: Vector3) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 1.85
	ring.outer_radius = 2.25
	ArenaKit.deco(decor, ring, at + Vector3(0.0, 0.2, 0.0), Color(0.2, 0.55, 1.0)).scale = Vector3(1.0, 1.4, 1.0)
	var water := ArenaKit.deco_cylinder(decor, 1.95, 0.05, at + Vector3(0.0, 0.32, 0.0), Color(0.45, 0.8, 1.0, 0.75))
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_duck = Node3D.new()
	_duck.position = at + Vector3(0.6, 0.38, 0.3)
	decor.add_child(_duck)
	ArenaKit.deco_sphere(_duck, 0.18, Vector3.ZERO, Color(1.0, 0.85, 0.15), 0.8)
	ArenaKit.deco_sphere(_duck, 0.11, Vector3(0.0, 0.16, -0.12), Color(1.0, 0.85, 0.15))
	ArenaKit.deco_box(_duck, Vector3(0.08, 0.04, 0.1), Vector3(0.0, 0.15, -0.24), Color(1.0, 0.5, 0.1))


func _build_sprinkler(at: Vector3) -> void:
	ArenaKit.deco_cylinder(decor, 0.18, 0.12, at + Vector3(0.0, 0.06, 0.0), Color(0.2, 0.7, 0.35))
	_sprinkler_arm = Node3D.new()
	_sprinkler_arm.position = at + Vector3(0.0, 0.2, 0.0)
	decor.add_child(_sprinkler_arm)
	ArenaKit.deco_box(_sprinkler_arm, Vector3(0.06, 0.06, 0.5), Vector3(0.0, 0.0, -0.2), Color(0.85, 0.85, 0.9))
	var spray := CPUParticles3D.new()
	spray.amount = int(clampf(60.0 * GameSettings.visual_intensity, 10.0, 90.0))
	spray.lifetime = 1.1
	spray.local_coords = false
	spray.position = Vector3(0.0, 0.05, -0.45)
	spray.direction = Vector3(0.0, 1.0, -1.2)
	spray.spread = 6.0
	spray.gravity = Vector3(0.0, -9.8, 0.0)
	spray.initial_velocity_min = 5.0
	spray.initial_velocity_max = 6.0
	spray.scale_amount_min = 0.6
	var drop := SphereMesh.new()
	drop.radius = 0.04
	drop.height = 0.08
	drop.radial_segments = 6
	drop.rings = 3
	var drop_material := StandardMaterial3D.new()
	drop_material.albedo_color = Color(0.6, 0.85, 1.0, 0.8)
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = drop_material
	spray.mesh = drop
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sprinkler_arm.add_child(spray)
	spray.emitting = true


func _build_gnome(at: Vector3, yaw_degrees: float) -> void:
	var gnome := Node3D.new()
	gnome.position = at
	gnome.rotation_degrees.y = yaw_degrees
	decor.add_child(gnome)
	ArenaKit.deco_cylinder(gnome, 0.2, 0.36, Vector3(0.0, 0.18, 0.0), Color(0.2, 0.4, 0.9), Vector3.ZERO, 0.14)
	ArenaKit.deco_sphere(gnome, 0.13, Vector3(0.0, 0.46, 0.0), Color(1.0, 0.82, 0.66))
	ArenaKit.deco_cylinder(gnome, 0.11, 0.2, Vector3(0.0, 0.36, -0.08), Color.WHITE, Vector3(-20.0, 0.0, 0.0), 0.0)
	ArenaKit.deco_cylinder(gnome, 0.15, 0.34, Vector3(0.0, 0.7, 0.0), Color(0.95, 0.2, 0.2), Vector3.ZERO, 0.0)
	ArenaKit.deco_sphere(gnome, 0.04, Vector3(0.0, 0.47, -0.13), Color(1.0, 0.6, 0.55))


func _build_flower_bed(centre: Vector3, length: float) -> void:
	var colors: Array[Color] = [Color(1.0, 0.35, 0.5), Color(1.0, 0.85, 0.2), Color(0.7, 0.45, 1.0), Color(1.0, 1.0, 1.0), Color(1.0, 0.55, 0.15)]
	ArenaKit.deco_box(decor, Vector3(length, 0.08, 0.9), centre + Vector3(0.0, 0.04, 0.0), Color(0.45, 0.3, 0.18))
	var count := int(length * 1.4)
	for i in count:
		var x := -length * 0.5 + (float(i) + 0.5) * length / float(count)
		var spot := centre + Vector3(x, 0.0, _rng.randf_range(-0.3, 0.3))
		var stem_height := _rng.randf_range(0.3, 0.55)
		ArenaKit.deco_cylinder(decor, 0.02, stem_height, spot + Vector3(0.0, stem_height * 0.5, 0.0), Color(0.2, 0.55, 0.2))
		ArenaKit.deco_sphere(decor, 0.09, spot + Vector3(0.0, stem_height, 0.0), colors[i % colors.size()], 0.7)


# --- Looks only ---------------------------------------------------------------

func _build_neighbourhood() -> void:
	_house(Vector3(-30.0, 0.0, -48.0), Vector3(16.0, 7.0, 12.0), Color(1.0, 0.9, 0.7), Color(0.8, 0.3, 0.25))
	_house(Vector3(8.0, 0.0, -52.0), Vector3(18.0, 8.0, 13.0), Color(0.8, 0.9, 1.0), Color(0.3, 0.4, 0.6))
	_house(Vector3(44.0, 0.0, -46.0), Vector3(14.0, 6.5, 12.0), Color(1.0, 0.8, 0.85), Color(0.5, 0.35, 0.3))
	_house(Vector3(-20.0, 0.0, 50.0), Vector3(17.0, 7.5, 13.0), Color(0.9, 1.0, 0.85), Color(0.75, 0.45, 0.2))
	_house(Vector3(30.0, 0.0, 52.0), Vector3(15.0, 7.0, 12.0), Color(1.0, 0.95, 0.75), Color(0.35, 0.5, 0.45))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 22:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(52.0, 95.0)
		var spot := Vector3(cos(angle) * distance * 1.2, 0.0, sin(angle) * distance)
		if absf(spot.x) < HALF_X + 6.0 and absf(spot.z) < HALF_Z + 6.0:
			continue
		_tree(spot, rng.randf_range(0.8, 1.5))


func _house(at: Vector3, size: Vector3, wall: Color, roof: Color) -> void:
	ArenaKit.house(decor, at, size, wall, roof)


func _tree(at: Vector3, tree_scale: float) -> void:
	ArenaKit.tree(decor, at, tree_scale)
