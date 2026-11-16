class_name HomeTurf
extends Arena
## HOME TURF: a fictional family home, and you're toy-sized (GDD §5.3).
## Everything is about three times real size: chairs are steps, tables are
## platforms you can also crawl under, beds are trampolines, the kitchen island
## is a fort and the cars in the garage are giant cover. The roof is off, like a
## dollhouse, so the sun shines into every room.
##
## Layout (top-down, north is -Z, the street is to the south):
##
##                 BACKYARD  (shed, sandpit, tree, toy race-track ramp up to the patio roof)
##   ┌─────────┬─────┬──────────────┐┌────────────┐
##   │  BED 3  │     │   FAMILY     ││            │
##   ├─────────┤  H  │   (big fan)  ││   PATIO    │  east
##   │ LAUNDRY ├  A  ┤              ││ (roof you  │  lawn
##   ├─────────┤  L  │   KITCHEN    ││ can climb) │
##   │  BATH   │  L  │ ─bench─      ││            │
##   ├─────────┤     ├──────────────┤├────────────┴──┐
##   │  BED 2  │     │   LOUNGE     ││   GARAGE      │
##   ├─────────┴─────┤              ││  (two cars)   │
##   │    DINING     ├──────────────┤│               │
##   ├───────────────┤    ENTRY     │└──roller door──┘
##   │    STUDY      │              │    driveway
##   ├────┬──────────┤──front door──┘
##   │ENS │   MAIN   │    porch            front yard
##   └────┴──────────┘
##   ═══════════════ footpath ═══════════ street ═══════════
##
## Blue's home end is the front (driveway and garage), orange's is the backyard.
## West of the house a side path joins the front and back yards; the east lawn
## does the same, so there are always ways round.

const LAWN_SHADER := preload("res://assets/materials/lawn.gdshader")

## Toy scale: walls are tall enough that nobody can climb onto them.
const WALL_HEIGHT := 9.0
const WALL_THICK := 0.6
const DOOR_WIDTH := 3.6
const DOOR_HEIGHT := 5.6
## The lot (the fenced yard plus the street out front).
const LOT_WEST := -36.0
const LOT_EAST := 32.0
const LOT_NORTH := -52.0
const LOT_SOUTH := 48.0
const FENCE_HEIGHT := 5.4
const FENCE_FRONT := 30.0
const PATIO_ROOF_TOP := 6.8

const WALL := Color(0.98, 0.93, 0.84)
const WALL_EDGE := Color(0.62, 0.5, 0.42)
const WINDOW := Color(0.62, 0.84, 1.0)
const WOOD_FLOOR := Color(0.8, 0.62, 0.42)
const TILE := Color(0.88, 0.9, 0.93)
const CONCRETE := Color(0.68, 0.68, 0.7)
const DECKING := Color(0.72, 0.52, 0.36)
const ASPHALT := Color(0.26, 0.28, 0.32)
const FURNITURE := Color(0.62, 0.44, 0.3)
const FURNITURE_LIGHT := Color(0.86, 0.72, 0.52)
const COUCH := Color(0.3, 0.55, 0.85)
const FENCE := Color(0.74, 0.56, 0.38)
const LAWN := Color(0.36, 0.72, 0.28)

## The two team ends (also used for respawns in TEAMS).
const BLUE_BASE := Vector3(8.0, 0.0, 20.0)
const ORANGE_BASE := Vector3(0.0, 0.0, -44.0)

var _rng := RandomNumberGenerator.new()


func _build() -> void:
	arena_name = "Home Turf"
	_rng.seed = 4711
	# A high sun and warm fill light, so the rooms (in the walls' shade) feel sunny.
	_build_sky_and_sun(-68.0, 0.55)
	_build_lot()
	_build_house()
	_build_patio()
	_build_garage()
	_build_furniture()
	_build_yards()
	_build_street()
	_build_features()
	_build_spawns()
	_build_neighbourhood()


# --- Lot, fences and street ---------------------------------------------------------

func _build_lot() -> void:
	var lawn_material := ShaderMaterial.new()
	lawn_material.shader = LAWN_SHADER
	var width := LOT_EAST - LOT_WEST
	var depth := LOT_SOUTH - LOT_NORTH
	var centre := Vector3((LOT_WEST + LOT_EAST) * 0.5, -0.5, (LOT_NORTH + LOT_SOUTH) * 0.5)
	var ground := ArenaKit.box(geometry, Vector3(width, 1.0, depth), centre, LAWN)
	(ground.get_node("Mesh") as MeshInstance3D).material_override = lawn_material
	ArenaKit.deco_box(decor, Vector3(460.0, 0.2, 460.0), Vector3(0.0, -0.16, 0.0), Color(0.33, 0.66, 0.27))

	# Timber fence round the back and sides (toy scale, so it towers over you).
	var fence_z := (LOT_NORTH + FENCE_FRONT) * 0.5
	var fence_len := FENCE_FRONT - LOT_NORTH
	ArenaKit.box(geometry, Vector3(width + WALL_THICK, FENCE_HEIGHT, 0.5), Vector3(centre.x, FENCE_HEIGHT * 0.5, LOT_NORTH), FENCE)
	ArenaKit.box(geometry, Vector3(0.5, FENCE_HEIGHT, fence_len), Vector3(LOT_WEST, FENCE_HEIGHT * 0.5, fence_z), FENCE)
	ArenaKit.box(geometry, Vector3(0.5, FENCE_HEIGHT, fence_len), Vector3(LOT_EAST, FENCE_HEIGHT * 0.5, fence_z), FENCE)
	var x := LOT_WEST
	while x <= LOT_EAST + 0.01:
		ArenaKit.deco_box(decor, Vector3(0.5, FENCE_HEIGHT + 0.4, 0.8), Vector3(x, (FENCE_HEIGHT + 0.4) * 0.5, LOT_NORTH), FENCE.darkened(0.15))
		x += 4.0
	var z := LOT_NORTH
	while z <= FENCE_FRONT + 0.01:
		for side: float in [LOT_WEST, LOT_EAST]:
			ArenaKit.deco_box(decor, Vector3(0.8, FENCE_HEIGHT + 0.4, 0.5), Vector3(side, (FENCE_HEIGHT + 0.4) * 0.5, z), FENCE.darkened(0.15))
		z += 4.0
	# Invisible walls: above the fences, along the open front-yard sides, and across the far side of the street.
	var sky := 30.0
	ArenaKit.blocker(geometry, Vector3(width + 2.0, sky, 0.5), Vector3(centre.x, sky * 0.5, LOT_NORTH))
	ArenaKit.blocker(geometry, Vector3(width + 2.0, sky, 0.5), Vector3(centre.x, sky * 0.5, LOT_SOUTH))
	ArenaKit.blocker(geometry, Vector3(0.5, sky, depth), Vector3(LOT_WEST, sky * 0.5, centre.z))
	ArenaKit.blocker(geometry, Vector3(0.5, sky, depth), Vector3(LOT_EAST, sky * 0.5, centre.z))


func _build_street() -> void:
	var width := LOT_EAST - LOT_WEST
	var mid_x := (LOT_WEST + LOT_EAST) * 0.5
	_floor(Rect2(LOT_WEST, 34.0, width, 4.0), Color(0.82, 0.8, 0.76))  # Footpath.
	_floor(Rect2(LOT_WEST, 38.0, width, LOT_SOUTH - 38.0), ASPHALT, 0.05)
	ArenaKit.deco_box(decor, Vector3(width, 0.35, 0.5), Vector3(mid_x, 0.17, 38.1), Color(0.75, 0.75, 0.72))  # Kerb.
	var x := LOT_WEST + 2.0
	while x < LOT_EAST - 2.0:
		ArenaKit.deco_box(decor, Vector3(3.0, 0.08, 0.35), Vector3(x + 1.5, 0.09, 43.0), Color(0.96, 0.96, 0.92))
		x += 7.0
	# A car parked across the road: cover in the street.
	_car(Vector3(-18.0, 0.0, 43.5), Color(0.98, 0.78, 0.15), 90.0)
	# The letterbox (no number: this house is nowhere in particular).
	ArenaKit.box(geometry, Vector3(0.4, 3.0, 0.4), Vector3(-3.0, 1.5, 33.0), Color(0.4, 0.3, 0.25))
	ArenaKit.deco_box(decor, Vector3(1.4, 1.1, 1.8), Vector3(-3.0, 3.4, 33.0), Color(0.85, 0.2, 0.2))


# --- The house ----------------------------------------------------------------

func _build_house() -> void:
	# Floors (looks only; everyone stands on the yard's ground underneath).
	_floor(Rect2(-12.0, -36.0, 12.0, 38.0), WOOD_FLOOR)         # Family, kitchen and lounge.
	_floor(Rect2(-17.0, -36.0, 5.0, 30.0), WOOD_FLOOR.darkened(0.08))  # Hallway.
	_floor(Rect2(-26.0, -6.0, 14.0, 10.0), WOOD_FLOOR)           # Dining.
	_floor(Rect2(-12.0, 2.0, 12.0, 16.0), Color(0.78, 0.72, 0.66))  # Entry tiles.
	_floor(Rect2(-26.0, -36.0, 9.0, 10.0), Color(0.55, 0.78, 0.55))  # Bedroom 3 (green carpet).
	_floor(Rect2(-26.0, -26.0, 9.0, 10.0), TILE)                 # Laundry and bathroom.
	_floor(Rect2(-26.0, -16.0, 9.0, 10.0), Color(0.6, 0.66, 0.9))   # Bedroom 2 (blue carpet).
	_floor(Rect2(-26.0, 4.0, 14.0, 9.0), Color(0.72, 0.6, 0.5))   # Study.
	_floor(Rect2(-26.0, 13.0, 14.0, 13.0), Color(0.85, 0.7, 0.75))  # Main bedroom.
	_floor(Rect2(-26.0, 13.0, 6.0, 5.0), TILE, 0.04)             # Ensuite.

	# Outside walls.
	_wall(Vector2(-26.0, -36.0), Vector2(0.0, -36.0), [_door(-3.0, 4.0)])                 # Back (door to the backyard).
	_wall(Vector2(-26.0, -36.0), Vector2(-26.0, 26.0), [_door(-23.5)])                    # West (laundry door to the side path).
	_wall(Vector2(-26.0, 26.0), Vector2(-12.0, 26.0))                                     # Main bedroom front.
	_wall(Vector2(-12.0, 18.0), Vector2(0.0, 18.0), [_door(-6.0, 4.0)])                   # Entry front (front door).
	_wall(Vector2(0.0, -36.0), Vector2(0.0, 18.0), [_door(-30.0, 5.0), _door(-24.0, 5.0), # Sliding doors to the patio,
			_door(-11.5), _door(-3.0), _door(5.0)])                                        # the patio, garage and garage.

	# Inside walls.
	_wall(Vector2(-12.0, -36.0), Vector2(-12.0, -6.0), [_door(-25.0, 8.0), _door(-9.0)])  # Hall | family (archway), lounge.
	_wall(Vector2(-17.0, -36.0), Vector2(-17.0, -6.0), [_door(-31.0), _door(-23.5), _door(-18.5), _door(-11.0)])  # Hall | rooms.
	_wall(Vector2(-26.0, -26.0), Vector2(-17.0, -26.0))
	_wall(Vector2(-26.0, -21.0), Vector2(-17.0, -21.0))
	_wall(Vector2(-26.0, -16.0), Vector2(-17.0, -16.0))
	_wall(Vector2(-26.0, -6.0), Vector2(-17.0, -6.0))
	_wall(Vector2(-12.0, 2.0), Vector2(-12.0, 26.0), [_door(8.5), _door(15.5)])           # Entry | study, main bedroom.
	_wall(Vector2(-12.0, 2.0), Vector2(0.0, 2.0), [_door(-6.0, 4.4)])                     # Lounge | entry.
	_wall(Vector2(-26.0, 4.0), Vector2(-12.0, 4.0), [_door(-15.0)])                       # Dining | study.
	_wall(Vector2(-26.0, 13.0), Vector2(-12.0, 13.0))                                     # Study | main bedroom.
	_wall(Vector2(-20.0, 13.0), Vector2(-20.0, 18.0), [_door(15.5)])                      # Ensuite.
	_wall(Vector2(-26.0, 18.0), Vector2(-20.0, 18.0))

	# Windows (looks only): in the back and front walls (along x) and the west wall (along z).
	for spot: Vector3 in [Vector3(-21.5, 4.6, -36.0), Vector3(-9.0, 4.6, -36.0), Vector3(-19.0, 4.6, 26.0)]:
		_window(spot, 4.2, true)
	for spot: Vector3 in [Vector3(-26.0, 4.6, -11.0), Vector3(-26.0, 4.6, -31.0), Vector3(-26.0, 4.6, 8.5)]:
		_window(spot, 4.2, false)

	# Floor labels so everyone knows where "the kitchen" is.
	for label: Array in [["KITCHEN", Vector3(-6.0, 0.0, -18.5)], ["LOUNGE", Vector3(-6.0, 0.0, -11.5)],
			["DINING", Vector3(-19.0, 0.0, -4.6)], ["ENTRY", Vector3(-6.0, 0.0, 15.5)], ["HALL", Vector3(-14.5, 0.0, -16.0)],
			["STUDY", Vector3(-17.0, 0.0, 11.5)], ["PATIO", Vector3(7.5, 0.0, -11.0)], ["GARAGE", Vector3(9.8, 0.0, -7.6)]]:
		ArenaKit.sign_text(decor, label[0], label[1] + Vector3(0.0, 0.09, 0.0), Vector3(-90.0, 0.0, 0.0),
				Color(1.0, 1.0, 1.0, 0.55), 120, 0.012)


## A door gap in a wall: `centre` along the wall, its width, and the height of
## the lintel over it (0 = open to the sky).
func _door(centre: float, width: float = DOOR_WIDTH, height: float = DOOR_HEIGHT) -> Vector3:
	return Vector3(centre, width, height)


## A straight wall from `a` to `b` (x, z), along one axis, with door gaps.
func _wall(a: Vector2, b: Vector2, openings: Array[Vector3] = []) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var line := a.y if along_x else a.x
	# Run past the ends by half a thickness so corners meet with no gaps.
	var start := (minf(a.x, b.x) if along_x else minf(a.y, b.y)) - WALL_THICK * 0.5
	var end := (maxf(a.x, b.x) if along_x else maxf(a.y, b.y)) + WALL_THICK * 0.5
	var gaps := openings.duplicate()
	gaps.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.x < q.x)
	var cursor := start
	for gap: Vector3 in gaps:
		var left := gap.x - gap.y * 0.5
		_wall_piece(along_x, line, cursor, left, 0.0)
		if gap.z > 0.0:
			_wall_piece(along_x, line, left, left + gap.y, gap.z)
		cursor = left + gap.y
	_wall_piece(along_x, line, cursor, end, 0.0)


func _wall_piece(along_x: bool, line: float, from: float, to: float, bottom: float) -> void:
	var length := to - from
	if length < 0.05:
		return
	var mid := (from + to) * 0.5
	var height := WALL_HEIGHT - bottom
	var dims := Vector3(length, height, WALL_THICK) if along_x else Vector3(WALL_THICK, height, length)
	var centre := Vector3(mid, bottom + height * 0.5, line) if along_x else Vector3(line, bottom + height * 0.5, mid)
	ArenaKit.box(geometry, dims, centre, WALL)
	# A darker cap along the top: the cut-away edge of a dollhouse.
	ArenaKit.deco_box(decor, Vector3(dims.x + 0.04, 0.22, dims.z + 0.04), Vector3(centre.x, WALL_HEIGHT + 0.1, centre.z), WALL_EDGE)


func _window(at: Vector3, width: float, along_x: bool) -> void:
	var dims := Vector3(width, 3.0, WALL_THICK + 0.1) if along_x else Vector3(WALL_THICK + 0.1, 3.0, width)
	ArenaKit.deco_box(decor, dims, at, WINDOW, Vector3.ZERO, 0.15)
	var bar := Vector3(width, 0.18, WALL_THICK + 0.14) if along_x else Vector3(WALL_THICK + 0.14, 0.18, width)
	ArenaKit.deco_box(decor, bar, at, Color.WHITE)


## A flat floor finish (looks only). `rect` is x, z, width (x), depth (z).
func _floor(rect: Rect2, color: Color, lift: float = 0.03) -> void:
	ArenaKit.deco_box(decor, Vector3(rect.size.x, 0.06, rect.size.y),
			Vector3(rect.position.x + rect.size.x * 0.5, lift, rect.position.y + rect.size.y * 0.5), color)


# --- Patio and garage --------------------------------------------------------------

func _build_patio() -> void:
	_floor(Rect2(0.0, -36.0, 15.0, 27.0), DECKING)
	# The roof is a platform: reach it up the toy race-track ramp from the east lawn.
	var roof_thick := 0.4
	ArenaKit.box(geometry, Vector3(15.0, roof_thick, 27.0), Vector3(7.8, PATIO_ROOF_TOP - roof_thick * 0.5, -22.5), Color(0.44, 0.49, 0.57))
	# Toys that ended up on the roof (as they do): cover for rooftop fights.
	ArenaKit.cylinder(geometry, 1.3, 2.6, Vector3(4.5, PATIO_ROOF_TOP + 1.3, -30.0), Color(1.0, 0.55, 0.15))
	ArenaKit.deco_sphere(decor, 1.45, Vector3(4.5, PATIO_ROOF_TOP + 1.3, -30.0), Color(1.0, 0.55, 0.15))
	ArenaKit.cylinder(geometry, 1.8, 0.5, Vector3(10.5, PATIO_ROOF_TOP + 0.25, -15.0), Color(1.0, 0.3, 0.5))
	ArenaKit.box(geometry, Vector3(5.0, 1.6, 1.2), Vector3(6.0, PATIO_ROOF_TOP + 0.8, -18.5), Color(0.96, 0.96, 0.9), Vector3(0.0, 25.0, 0.0))
	for post: Vector3 in [Vector3(14.6, 0.0, -35.6), Vector3(14.6, 0.0, -22.5), Vector3(14.6, 0.0, -9.6), Vector3(7.5, 0.0, -35.6)]:
		ArenaKit.box(geometry, Vector3(0.6, PATIO_ROOF_TOP - roof_thick, 0.6), post + Vector3(0.0, (PATIO_ROOF_TOP - roof_thick) * 0.5, 0.0), Color(0.95, 0.95, 0.95))
	# A low rim so the roof reads as a roof.
	ArenaKit.box(geometry, Vector3(15.0, 0.6, 0.3), Vector3(7.8, PATIO_ROOF_TOP + 0.3, -35.85), Color(0.75, 0.75, 0.8))
	var ramp_colour := Color(1.0, 0.5, 0.1)
	ArenaKit.ramp(geometry, Vector3(29.0, 0.0, -22.0), Vector3(15.1, PATIO_ROOF_TOP, -22.0), 4.0, ramp_colour)
	for side: float in [-1.0, 1.0]:
		ArenaKit.ramp(geometry, Vector3(29.0, 0.35, -22.0 + side * 2.1), Vector3(15.1, PATIO_ROOF_TOP + 0.35, -22.0 + side * 2.1),
				0.3, Color(1.0, 0.85, 0.2), 0.7)
	add_roam_point(Vector3(7.5, PATIO_ROOF_TOP, -22.5))

	# Barbecue, outdoor table and benches, pot plants.
	ArenaKit.box(geometry, Vector3(3.6, 2.8, 2.0), Vector3(12.0, 1.4, -33.8), Color(0.25, 0.27, 0.3))
	ArenaKit.deco_box(decor, Vector3(3.7, 0.5, 2.1), Vector3(12.0, 3.05, -33.8), Color(0.15, 0.15, 0.18))
	_table(Vector3(7.5, 0.0, -22.5), Vector2(3.6, 7.0), 2.25, FURNITURE_LIGHT)
	for side: float in [-1.0, 1.0]:
		ArenaKit.box(geometry, Vector3(1.4, 1.2, 6.0), Vector3(7.5 + side * 3.2, 0.6, -22.5), FURNITURE)
	for pot: Vector3 in [Vector3(13.8, 0.0, -12.0), Vector3(1.6, 0.0, -34.4), Vector3(13.8, 0.0, -28.5)]:
		ArenaKit.cylinder(geometry, 0.9, 1.8, pot + Vector3(0.0, 0.9, 0.0), Color(0.8, 0.45, 0.3))
		ArenaKit.deco_sphere(decor, 1.3, pot + Vector3(0.0, 2.6, 0.0), Color(0.25, 0.65, 0.3))


func _build_garage() -> void:
	_floor(Rect2(0.0, -9.0, 19.0, 17.0), CONCRETE)
	_wall(Vector2(0.0, -9.0), Vector2(19.0, -9.0), [_door(9.8)])                    # Side door to the patio.
	_wall(Vector2(19.0, -9.0), Vector2(19.0, 8.0), [_door(-3.0)])                   # Side door to the east lawn.
	_wall(Vector2(0.0, 8.0), Vector2(19.0, 8.0), [_door(9.5, 15.0, 6.3)])           # The big roller door.
	_car(Vector3(6.0, 0.0, -0.5), Color(0.9, 0.22, 0.25), 0.0)
	_car(Vector3(13.7, 0.0, 0.5), Color(0.1, 0.72, 0.7), 0.0)
	# Workbench with a dartboard over it.
	ArenaKit.box(geometry, Vector3(4.6, 2.7, 1.6), Vector3(16.2, 1.35, -7.9), FURNITURE)
	ArenaKit.sign_text(decor, "HOME TURF", Vector3(9.5, 7.6, 8.35), Vector3.ZERO, Color(1.0, 0.6, 0.15), 150, 0.014)


## A toy car: a big body you hide behind, a cabin on top, chunky wheels.
func _car(at: Vector3, color: Color, yaw: float) -> void:
	var car := Node3D.new()
	car.position = at
	car.rotation_degrees.y = yaw
	geometry.add_child(car)
	ArenaKit.box(car, Vector3(5.4, 2.2, 12.0), Vector3(0.0, 1.3, 0.0), color)
	ArenaKit.box(car, Vector3(4.8, 1.8, 6.4), Vector3(0.0, 3.3, 0.6), color.lightened(0.1))
	for side: float in [-1.0, 1.0]:
		ArenaKit.deco_box(car, Vector3(0.1, 1.2, 5.4), Vector3(side * 2.42, 3.4, 0.6), WINDOW)
		for end: float in [-1.0, 1.0]:
			ArenaKit.deco_cylinder(car, 0.95, 0.9, Vector3(side * 2.5, 0.95, end * 3.9), Color(0.12, 0.12, 0.14), Vector3(0.0, 0.0, 90.0))
	ArenaKit.deco_box(car, Vector3(4.4, 1.0, 0.1), Vector3(0.0, 3.5, -2.65), WINDOW)


# --- Furniture ---------------------------------------------------------------------

func _build_furniture() -> void:
	# Kitchen: the bench between kitchen and lounge, the island fort, the fridge.
	ArenaKit.box(geometry, Vector3(7.2, 2.7, 2.0), Vector3(-8.1, 1.35, -15.0), Color(0.95, 0.95, 0.95))
	ArenaKit.deco_box(decor, Vector3(7.3, 0.2, 2.1), Vector3(-8.1, 2.8, -15.0), Color(0.3, 0.3, 0.35))
	ArenaKit.box(geometry, Vector3(7.5, 2.7, 3.2), Vector3(-6.0, 1.35, -21.6), Color(0.95, 0.95, 0.95))
	ArenaKit.deco_box(decor, Vector3(7.7, 0.25, 3.4), Vector3(-6.0, 2.82, -21.6), Color(0.3, 0.3, 0.35))
	ArenaKit.box(geometry, Vector3(2.6, 5.6, 2.4), Vector3(-10.3, 2.8, -17.4), Color(0.85, 0.88, 0.92))
	# Meals table with chairs as steps up onto it (and room to crawl underneath).
	_table(Vector3(-6.5, 0.0, -28.5), Vector2(7.0, 4.4), 2.25, FURNITURE)
	for x: float in [-8.5, -4.5]:
		_chair(Vector3(x, 0.0, -31.6), 0.0)
		_chair(Vector3(x, 0.0, -25.4), 180.0)
	_rug(Vector3(-6.0, 0.0, -28.5), Vector2(10.0, 8.0), Color(0.95, 0.55, 0.35))

	# Lounge: couch, coffee table (a jumpable step) and the TV.
	ArenaKit.box(geometry, Vector3(2.8, 1.3, 8.0), Vector3(-9.0, 0.65, -6.5), COUCH)
	ArenaKit.box(geometry, Vector3(0.8, 2.6, 8.0), Vector3(-10.8, 1.3, -6.5), COUCH.darkened(0.15))
	for end: float in [-1.0, 1.0]:
		ArenaKit.box(geometry, Vector3(3.4, 1.9, 0.8), Vector3(-9.3, 0.95, -6.5 + end * 4.2), COUCH.darkened(0.15))
	ArenaKit.box(geometry, Vector3(2.4, 1.2, 4.5), Vector3(-5.0, 0.6, -6.5), FURNITURE_LIGHT)
	ArenaKit.box(geometry, Vector3(1.4, 1.8, 4.4), Vector3(-1.1, 0.9, -7.3), FURNITURE)
	ArenaKit.deco_box(decor, Vector3(0.2, 2.8, 4.2), Vector3(-0.7, 3.4, -7.3), Color(0.08, 0.08, 0.12), Vector3.ZERO, 0.1)
	_rug(Vector3(-6.0, 0.0, -6.5), Vector2(9.0, 9.0), Color(0.45, 0.75, 0.95))

	# Dining: a long table with a chair at each end (the steps up onto it). The
	# long sides stay clear: chairs there left gaps too narrow for bots to use.
	_table(Vector3(-19.0, 0.0, -1.0), Vector2(9.0, 3.2), 2.25, FURNITURE)
	_chair(Vector3(-24.4, 0.0, -1.0), 90.0)
	_chair(Vector3(-13.6, 0.0, -1.0), -90.0)

	# Bedroom 3: a loft bed with a trampoline beside it to bounce up there.
	ArenaKit.box(geometry, Vector3(3.4, 0.4, 6.6), Vector3(-24.0, 4.4, -31.0), Color(0.95, 0.45, 0.6))
	for corner: Vector2 in [Vector2(-25.5, -34.1), Vector2(-22.5, -34.1), Vector2(-25.5, -27.9), Vector2(-22.5, -27.9)]:
		ArenaKit.box(geometry, Vector3(0.4, 4.2, 0.4), Vector3(corner.x, 2.1, corner.y), FURNITURE_LIGHT)
	ArenaKit.box(geometry, Vector3(2.4, 1.6, 2.4), Vector3(-24.0, 0.8, -31.0), Color(0.95, 0.75, 0.2))  # Toy box under the loft.
	_trampoline(Vector3(-20.6, 0.0, -31.0), 1.5, 14.0, Color(0.3, 0.8, 0.4))

	# Bathroom: bathtub, and a mirror for ricochets.
	ArenaKit.box(geometry, Vector3(6.0, 1.6, 2.2), Vector3(-22.7, 0.8, -17.4), Color(0.97, 0.97, 1.0))
	ArenaKit.deco_box(decor, Vector3(5.4, 0.1, 1.6), Vector3(-22.7, 1.62, -17.4), Color(0.45, 0.75, 1.0))
	add_mirror(Vector3(-25.35, 4.4, -19.4), 90.0, Vector2(2.8, 3.0))

	# Bedroom 2: a bed trampoline and a wardrobe.
	_bed(Vector3(-23.7, 0.0, -10.2), Vector2(4.0, 6.4), Color(0.4, 0.55, 0.95), 12.0)
	ArenaKit.box(geometry, Vector3(5.4, 6.3, 1.8), Vector3(-23.0, 3.15, -14.8), FURNITURE_LIGHT)

	# Study: desk with a chair step, bookshelf, and a dartboard.
	_table(Vector3(-24.3, 0.0, 8.5), Vector2(2.6, 6.0), 2.25, FURNITURE)
	_chair(Vector3(-21.6, 0.0, 8.5), -90.0)
	ArenaKit.box(geometry, Vector3(6.0, 6.6, 1.4), Vector3(-17.0, 3.3, 12.0), FURNITURE)
	for shelf in 3:
		ArenaKit.deco_box(decor, Vector3(5.6, 1.2, 0.1), Vector3(-17.0, 1.4 + shelf * 2.0, 11.27), Color(0.9, 0.3 + shelf * 0.2, 0.35))

	# Main bedroom: a big bed trampoline, bedside tables, a mirror wardrobe.
	_bed(Vector3(-19.0, 0.0, 22.4), Vector2(6.6, 6.6), Color(0.95, 0.6, 0.7), 13.0)
	for x: float in [-23.4, -14.6]:
		ArenaKit.box(geometry, Vector3(1.6, 1.8, 1.6), Vector3(x, 0.9, 24.8), FURNITURE_LIGHT)
	add_mirror(Vector3(-25.35, 3.4, 22.0), 90.0, Vector2(4.6, 5.0))

	# Ensuite: vanity and mirror.
	ArenaKit.box(geometry, Vector3(1.8, 2.7, 3.0), Vector3(-24.8, 1.35, 15.6), Color(0.97, 0.97, 1.0))
	add_mirror(Vector3(-25.35, 5.2, 15.6), 90.0, Vector2(2.8, 2.2))

	# Entry: hall table and a shoe rack.
	ArenaKit.box(geometry, Vector3(1.6, 2.4, 5.0), Vector3(-1.1, 1.2, 12.5), FURNITURE)
	ArenaKit.box(geometry, Vector3(3.4, 1.4, 1.2), Vector3(-10.0, 0.7, 17.0), FURNITURE_LIGHT)


func _table(at: Vector3, top: Vector2, height: float, color: Color) -> void:
	ArenaKit.box(geometry, Vector3(top.x, 0.3, top.y), at + Vector3(0.0, height - 0.15, 0.0), color)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var leg := at + Vector3(sx * (top.x * 0.5 - 0.45), (height - 0.3) * 0.5, sz * (top.y * 0.5 - 0.45))
			ArenaKit.box(geometry, Vector3(0.45, height - 0.3, 0.45), leg, color.darkened(0.15))


## A chair seat (a step up), with its back on the side facing away from `yaw`.
func _chair(at: Vector3, yaw: float) -> void:
	var chair := Node3D.new()
	chair.position = at
	chair.rotation_degrees.y = yaw
	geometry.add_child(chair)
	ArenaKit.box(chair, Vector3(1.6, 1.2, 1.6), Vector3(0.0, 0.6, 0.0), FURNITURE_LIGHT)
	ArenaKit.box(chair, Vector3(1.6, 1.9, 0.3), Vector3(0.0, 2.15, -0.65), FURNITURE_LIGHT)


## A bed: a mattress you can hop onto that bounces you high (it's a trampoline!).
func _bed(at: Vector3, top: Vector2, color: Color, launch: float) -> void:
	ArenaKit.box(geometry, Vector3(top.x, 1.1, top.y), at + Vector3(0.0, 0.55, 0.0), Color(0.95, 0.95, 0.97))
	ArenaKit.deco_box(decor, Vector3(top.x + 0.05, 0.2, top.y * 0.7), at + Vector3(0.0, 1.05, top.y * 0.15), color)
	ArenaKit.deco_box(decor, Vector3(top.x * 0.7, 0.4, 0.9), at + Vector3(0.0, 1.3, -top.y * 0.5 + 0.7), Color.WHITE)
	_trampoline(at + Vector3(0.0, 1.1, top.y * 0.12), minf(top.x, top.y) * 0.32, launch, color.lightened(0.2))


func _trampoline(at: Vector3, radius: float, launch: float, color: Color) -> void:
	var pad := JUMP_PAD_SCENE.instantiate() as JumpPad
	pad.position = at
	pad.pad_radius = radius
	pad.launch_speed = launch
	pad.pad_color = color
	add_child(pad)


func _rug(at: Vector3, extent: Vector2, color: Color) -> void:
	ArenaKit.deco_box(decor, Vector3(extent.x, 0.05, extent.y), at + Vector3(0.0, 0.07, 0.0), color)


# --- Yards -------------------------------------------------------------------------

func _build_yards() -> void:
	# Front: driveway, porch, a front tree and some bushes.
	_floor(Rect2(1.0, 8.0, 17.0, 26.0), CONCRETE, 0.04)
	_floor(Rect2(-10.0, 18.0, 8.0, 3.6), Color(0.75, 0.55, 0.45), 0.05)
	for post: float in [-9.6, -2.4]:
		ArenaKit.box(geometry, Vector3(0.5, 6.0, 0.5), Vector3(post, 3.0, 21.3), Color.WHITE)
	ArenaKit.deco_box(decor, Vector3(8.6, 0.4, 4.2), Vector3(-6.0, 6.2, 19.9), WALL_EDGE)
	_yard_tree(Vector3(-28.0, 0.0, 30.0), 1.3)
	for bush: Vector3 in [Vector3(-15.0, 0.0, 30.5), Vector3(-21.0, 0.0, 29.0), Vector3(24.0, 0.0, 28.0)]:
		_bush(bush, 1.6)

	# West side path: wheelie bins and a hose.
	ArenaKit.box(geometry, Vector3(2.2, 3.3, 2.4), Vector3(-33.6, 1.65, -2.0), Color(0.2, 0.45, 0.25))
	ArenaKit.box(geometry, Vector3(2.2, 3.3, 2.4), Vector3(-33.6, 1.65, 1.2), Color(0.85, 0.2, 0.2))
	ArenaKit.deco_cylinder(decor, 0.8, 0.5, Vector3(-35.3, 1.6, -12.0), Color(0.2, 0.7, 0.3), Vector3(0.0, 0.0, 90.0))

	# Backyard: a shed, a sandpit with a toy truck, a big tree, bushes.
	ArenaKit.box(geometry, Vector3(9.0, 6.0, 7.0), Vector3(24.0, 3.0, -46.0), Color(0.55, 0.7, 0.55))
	var prism := PrismMesh.new()
	prism.size = Vector3(9.8, 2.2, 7.6)
	ArenaKit.deco(decor, prism, Vector3(24.0, 7.1, -46.0), Color(0.45, 0.3, 0.25))
	_floor(Rect2(-18.0, -48.0, 9.0, 7.0), Color(0.95, 0.85, 0.55), 0.06)
	ArenaKit.box(geometry, Vector3(4.6, 2.6, 2.6), Vector3(-13.5, 1.3, -44.5), Color(1.0, 0.75, 0.1))
	ArenaKit.box(geometry, Vector3(2.0, 1.4, 2.6), Vector3(-10.9, 3.3, -44.5), Color(0.95, 0.35, 0.2))
	_yard_tree(Vector3(-27.0, 0.0, -44.0), 1.5)
	for bush: Vector3 in [Vector3(6.0, 0.0, -49.0), Vector3(15.0, 0.0, -40.0), Vector3(-31.0, 0.0, -34.0), Vector3(27.0, 0.0, -30.0)]:
		_bush(bush, 1.4)
	# East lawn: a garden bed.
	_floor(Rect2(24.0, 0.0, 6.0, 12.0), Color(0.45, 0.32, 0.22), 0.06)
	for flower in 6:
		var colour := [Color(1.0, 0.4, 0.6), Color(1.0, 0.85, 0.2), Color(0.6, 0.45, 1.0)][flower % 3] as Color
		ArenaKit.deco_sphere(decor, 0.5, Vector3(25.5 + (flower % 2) * 3.0, 0.6, 1.5 + flower * 1.8), colour)


func _yard_tree(at: Vector3, tree_scale: float) -> void:
	ArenaKit.cylinder(geometry, 0.7 * tree_scale, 6.0 * tree_scale, at + Vector3(0.0, 3.0 * tree_scale, 0.0), ArenaKit.TRUNK)
	ArenaKit.deco_sphere(decor, 3.8 * tree_scale, at + Vector3(0.0, 7.6 * tree_scale, 0.0), ArenaKit.LEAF)
	ArenaKit.deco_sphere(decor, 2.6 * tree_scale, at + Vector3(1.6, 9.2, -0.8) * tree_scale, ArenaKit.LEAF_LIGHT)


func _bush(at: Vector3, radius: float) -> void:
	ArenaKit.cylinder(geometry, radius * 0.8, radius * 1.4, at + Vector3(0.0, radius * 0.7, 0.0), Color(0.2, 0.55, 0.25))
	ArenaKit.deco_sphere(decor, radius, at + Vector3(0.0, radius * 1.3, 0.0), Color(0.26, 0.62, 0.28))


# --- Buckets, wind, mirrors, targets, power-up ----------------------------------------

func _build_features() -> void:
	add_bucket(Vector3(-19.0, 0.0, -34.0), Color(0.95, 0.75, 0.2))    # Toy box in bedroom 3.
	add_bucket(Vector3(-20.0, 0.0, -24.6), Color(0.95, 0.95, 0.9))    # Laundry basket.
	add_bucket(Vector3(11.0, 0.0, -13.0), Color(0.3, 0.75, 0.95))     # Patio.
	add_bucket(Vector3(2.0, 0.0, -7.6), Color(0.95, 0.45, 0.2))       # Garage.
	add_bucket(Vector3(4.0, 0.0, -44.0), Color(0.6, 0.85, 0.3))       # Backyard.
	add_bucket(Vector3(-10.0, 0.0, 28.5), Color(0.95, 0.4, 0.7))      # Front yard.

	# A giant pedestal fan in the family room blows across the kitchen, toward the patio.
	add_wind_zone(Vector3(-6.0, 3.0, -32.0), Vector3(11.4, 6.0, 7.6), Vector3(1.0, 0.0, 0.0), 26.0, false)

	add_target(Vector3(-21.0, 5.0, 4.95), 0.0)     # Study dartboard.
	add_target(Vector3(16.2, 5.2, -8.05), 0.0)     # Over the garage workbench.
	add_target(Vector3(0.95, 4.8, -16.5), 90.0)    # On the house wall, facing the patio.
	add_target(Vector3(-6.0, 3.8, -51.1), 0.0)     # On the back fence.

	add_power_up_spot(Vector3(-5.0, 0.0, -0.6))    # In the lounge, in the middle of everything.


func _build_spawns() -> void:
	team_bases = [BLUE_BASE, ORANGE_BASE]
	var centre := Vector3(-6.0, 0.0, -8.0)
	# Front (blue's end).
	add_spawn(Vector3(9.5, 0.0, 16.0), centre)
	add_spawn(Vector3(-6.0, 0.0, 28.0), centre)
	add_spawn(Vector3(-6.0, 0.0, 9.0), centre)
	add_spawn(Vector3(1.8, 0.0, 0.0), centre)
	add_spawn(Vector3(10.0, 0.0, 42.0), centre)
	add_spawn(Vector3(25.0, 0.0, 14.0), centre)
	add_spawn(Vector3(-24.5, 0.0, 2.8), centre)
	add_spawn(Vector3(-15.0, 0.0, 16.0), centre)
	# Back (orange's end).
	add_spawn(Vector3(0.0, 0.0, -45.5), centre)
	add_spawn(Vector3(-29.0, 0.0, -47.0), centre)
	add_spawn(Vector3(14.0, 0.0, -47.0), centre)
	add_spawn(Vector3(-10.0, 0.0, -34.0), centre)
	add_spawn(Vector3(-18.6, 0.0, -28.0), centre)
	add_spawn(Vector3(-31.0, 0.0, -28.0), centre)
	add_spawn(Vector3(5.0, 0.0, -14.0), centre)
	add_spawn(Vector3(-5.0, 0.0, -11.0), centre)
	# More places bots like to wander.
	for spot: Vector3 in [Vector3(-21.0, 0.0, -23.5), Vector3(-20.0, 0.0, -8.0), Vector3(-18.0, 0.0, 9.0),
			Vector3(-14.5, 0.0, -22.0), Vector3(9.8, 0.0, 0.0), Vector3(-10.0, 0.0, 42.0), Vector3(18.0, 0.0, -38.0),
			Vector3(-31.0, 0.0, 12.0), Vector3(25.0, 0.0, -10.0), Vector3(-14.0, 0.0, 20.0)]:
		add_roam_point(spot)


func _build_neighbourhood() -> void:
	var houses := [
		[Vector3(-28.0, 0.0, 64.0), Vector3(18.0, 8.0, 13.0), Color(1.0, 0.9, 0.7), Color(0.75, 0.3, 0.25)],
		[Vector3(2.0, 0.0, 66.0), Vector3(17.0, 7.5, 12.0), Color(0.82, 0.9, 1.0), Color(0.3, 0.4, 0.6)],
		[Vector3(30.0, 0.0, 64.0), Vector3(16.0, 7.0, 12.0), Color(1.0, 0.82, 0.86), Color(0.5, 0.35, 0.3)],
		[Vector3(-20.0, 0.0, -70.0), Vector3(18.0, 8.0, 13.0), Color(0.9, 1.0, 0.85), Color(0.7, 0.42, 0.2)],
		[Vector3(18.0, 0.0, -72.0), Vector3(17.0, 7.0, 12.0), Color(1.0, 0.95, 0.75), Color(0.35, 0.5, 0.45)],
		[Vector3(-56.0, 0.0, -10.0), Vector3(13.0, 7.5, 18.0), Color(0.95, 0.85, 0.75), Color(0.45, 0.3, 0.3)],
		[Vector3(52.0, 0.0, -6.0), Vector3(13.0, 7.0, 17.0), Color(0.85, 0.95, 0.95), Color(0.3, 0.35, 0.5)],
	]
	for house: Array in houses:
		ArenaKit.house(decor, house[0], house[1], house[2], house[3])
	for i in 24:
		var angle := _rng.randf() * TAU
		var distance := _rng.randf_range(62.0, 110.0)
		var spot := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		ArenaKit.tree(decor, spot, _rng.randf_range(0.9, 1.5))
