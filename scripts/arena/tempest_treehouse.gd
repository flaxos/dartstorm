class_name TempestTreehouse
extends Arena
## TEMPEST TREEHOUSE: a high-canopy fort built into ancient backyard trees (GDD §5.4).
##
## Multi-tier layout (top-down, north is -Z):
##
##                 [North Trunk & High Crow's Nest (Y=10.5m)]
##                           [Shield Pickup & Chainstorm]
##                            \ (Ice Slide Chute) \
##                             \                   \
##   BLUE CANOPY FORT  <==== Rope Bridge (Y=5.4m) ====>  ORANGE CANOPY FORT
##     (West, -X)             [Gale Wind Tunnel]              (East, +X)
##        [JumpPad]                                            [JumpPad]
##   -----------------------------------------------------------------------
##                 [Forest Floor: Moss, Bird Bath, Wind Vent] (Y=0m)
##
## Features:
##   * High multi-tier canopy decks and suspension rope bridge.
##   * Kinetic jump-pads launching players into high canopy nests.
##   * A high-speed ice slick slide chute for quick escapes down from the nest.
##   * Gale-force wind tunnels pushing darts across the canopy chasm.
##   * Upward wind vents and a conductive bird-bath water puddle.

const LAWN_SHADER := preload("res://assets/materials/lawn.gdshader")

const HALF_X := 35.0
const HALF_Z := 28.0
const DECK_Y := 5.4
const HIGH_NEST_Y := 10.5

const WOOD := Color(0.72, 0.52, 0.32)
const WOOD_DARK := Color(0.5, 0.34, 0.2)
const ROPE := Color(0.78, 0.68, 0.48)
const LEAF := Color(0.2, 0.58, 0.22)
const LEAF_GOLD := Color(0.85, 0.65, 0.15)
const LEAF_LIGHT := Color(0.35, 0.75, 0.28)
const TRUNK := Color(0.42, 0.28, 0.16)
const FENCE := Color(0.92, 0.88, 0.8)
const BLUE := Color(0.15, 0.45, 1.0)
const BLUE_DARK := Color(0.1, 0.3, 0.75)
const ORANGE := Color(1.0, 0.5, 0.1)
const ORANGE_DARK := Color(0.85, 0.38, 0.05)

var _time: float = 0.0
var _leaves: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _build() -> void:
	arena_name = "Tempest Treehouse"
	_rng.seed = 2026
	_build_sky_and_sun(-48.0, 0.15)
	_build_ground_and_trees()
	_build_canopy_forts()
	_build_suspension_bridge()
	_build_crow_nest()
	_build_traversals_and_hazards()
	_build_spawns_and_points()
	_build_scenery()


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	# Ambient gentle swaying of canopy leaf clusters in the gale wind
	for i in _leaves.size():
		var sway := sin(_time * 2.2 + float(i) * 0.7) * 0.08
		_leaves[i].rotation.z = sway


# --- Environment & Ground ---

func _build_ground_and_trees() -> void:
	var lawn_material := ShaderMaterial.new()
	lawn_material.shader = LAWN_SHADER
	var ground := ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), Color(0.32, 0.65, 0.26))
	(ground.get_node("Mesh") as MeshInstance3D).material_override = lawn_material

	# Surrounding neighbourhood backdrop
	ArenaKit.deco_box(decor, Vector3(400.0, 0.2, 400.0), Vector3(0.0, -0.16, 0.0), Color(0.28, 0.58, 0.24))

	# Rustic wooden perimeter fence + invisible sky blockers so forest skyline stays open!
	var fence_h := 3.8
	var sky_h := 22.0
	var thick := 0.6
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, fence_h, thick), Vector3(0.0, fence_h * 0.5, -HALF_Z - thick * 0.5), WOOD_DARK, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0 + thick * 2.0, fence_h, thick), Vector3(0.0, fence_h * 0.5, HALF_Z + thick * 0.5), WOOD_DARK, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(thick, fence_h, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, fence_h * 0.5, 0.0), WOOD_DARK, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(thick, fence_h, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, fence_h * 0.5, 0.0), WOOD_DARK, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 2.0, sky_h, thick), Vector3(0.0, fence_h + sky_h * 0.5, -HALF_Z - thick * 0.5))
	ArenaKit.blocker(geometry, Vector3(HALF_X * 2.0 + 2.0, sky_h, thick), Vector3(0.0, fence_h + sky_h * 0.5, HALF_Z + thick * 0.5))
	ArenaKit.blocker(geometry, Vector3(thick, sky_h, HALF_Z * 2.0), Vector3(-HALF_X - thick * 0.5, fence_h + sky_h * 0.5, 0.0))
	ArenaKit.blocker(geometry, Vector3(thick, sky_h, HALF_Z * 2.0), Vector3(HALF_X + thick * 0.5, fence_h + sky_h * 0.5, 0.0))

	# 4 Giant Ancient Tree Trunks (Walkable colliders in geometry)
	# 1. West Tree (Blue Base Trunk)
	_build_giant_tree(Vector3(-16.0, 0.0, 0.0), 2.0, 18.0)
	# 2. East Tree (Orange Base Trunk)
	_build_giant_tree(Vector3(16.0, 0.0, 0.0), 2.0, 18.0)
	# 3. North Tree (High Spire Trunk)
	_build_giant_tree(Vector3(0.0, 0.0, -6.0), 1.6, 22.0)
	# 4. South Tree (Grove Trunk)
	_build_giant_tree(Vector3(0.0, 0.0, 16.0), 2.0, 16.0)

	# Ground buttress roots for low cover
	_build_root_cover(Vector3(-6.0, 0.0, 4.0), Vector3(4.5, 1.2, 1.2), 25.0)
	_build_root_cover(Vector3(6.0, 0.0, 4.0), Vector3(4.5, 1.2, 1.2), -25.0)
	_build_root_cover(Vector3(-4.0, 0.0, -4.0), Vector3(3.8, 1.0, 1.0), -40.0)
	_build_root_cover(Vector3(4.0, 0.0, -4.0), Vector3(3.8, 1.0, 1.0), 40.0)


func _build_giant_tree(at: Vector3, radius: float, height: float) -> void:
	# Solid trunk
	ArenaKit.cylinder(geometry, radius, height, at + Vector3(0.0, height * 0.5, 0.0), TRUNK, ArenaKit.SurfaceType.WOOD)
	# Massive canopy leafy domes
	var dome1 := ArenaKit.deco_sphere(decor, radius * 3.4, at + Vector3(0.0, height - 1.0, 0.0), LEAF, 0.75)
	var dome2 := ArenaKit.deco_sphere(decor, radius * 2.8, at + Vector3(1.5, height + 2.0, -1.0), LEAF_LIGHT, 0.7)
	var dome3 := ArenaKit.deco_sphere(decor, radius * 2.2, at + Vector3(-1.2, height + 3.2, 1.2), LEAF_GOLD, 0.65)
	_leaves.append(dome1)
	_leaves.append(dome2)
	_leaves.append(dome3)


func _build_root_cover(at: Vector3, size: Vector3, rot_y: float) -> void:
	ArenaKit.box(geometry, size, at + Vector3(0.0, size.y * 0.5, 0.0), TRUNK, Vector3(0.0, rot_y, 0.0), ArenaKit.SurfaceType.WOOD)


# --- Canopy Forts ---

func _build_canopy_forts() -> void:
	var c0 := GameMode.team_color(0)
	var c1 := GameMode.team_color(1)
	# Team 0 Fort (West: -X)
	_build_fort_deck(Vector3(-16.0, DECK_Y, 0.0), c0, c0.darkened(0.25), "%s CANOPY FORT" % GameMode.team_name(0))
	# Team 1 Fort (East: +X)
	_build_fort_deck(Vector3(16.0, DECK_Y, 0.0), c1, c1.darkened(0.25), "%s CANOPY FORT" % GameMode.team_name(1))

	# Ramps from ground up to mid-decks with properly pitched railings
	ArenaKit.ramp(geometry, Vector3(-16.0, 0.0, 14.0), Vector3(-16.0, DECK_Y, 6.0), 2.8, WOOD, 0.3, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, Vector3(16.0, 0.0, 14.0), Vector3(16.0, DECK_Y, 6.0), 2.8, WOOD, 0.3, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, Vector3(-14.5, 0.5, 14.0), Vector3(-14.5, DECK_Y + 0.5, 6.0), 0.18, WOOD_DARK, 0.85, ArenaKit.SurfaceType.WOOD)
	ArenaKit.ramp(geometry, Vector3(14.5, 0.5, 14.0), Vector3(14.5, DECK_Y + 0.5, 6.0), 0.18, WOOD_DARK, 0.85, ArenaKit.SurfaceType.WOOD)


func _build_fort_deck(at: Vector3, tint: Color, tint_dark: Color, sign_title: String) -> void:
	var deck_size := Vector3(12.0, 0.6, 12.0)
	ArenaKit.box(geometry, deck_size, at - Vector3(0.0, 0.3, 0.0), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Perimeter railings
	var rail_h := 1.1
	var rail_thick := 0.25
	# North railing: leave opening on inner side for the ramp to the Crow's Nest
	var north_sign := -1.7 if at.x < 0 else 1.7
	ArenaKit.box(geometry, Vector3(8.6, rail_h, rail_thick), at + Vector3(north_sign, rail_h * 0.5, -deck_size.z * 0.5), WOOD_DARK)
	# South railing: left and right segments, leaving center opening (width 3.2) for the ground ramp
	ArenaKit.box(geometry, Vector3(4.4, rail_h, rail_thick), at + Vector3(-3.8, rail_h * 0.5, deck_size.z * 0.5), WOOD_DARK)
	ArenaKit.box(geometry, Vector3(4.4, rail_h, rail_thick), at + Vector3(3.8, rail_h * 0.5, deck_size.z * 0.5), WOOD_DARK)

	# Chasm-facing inner edge: leave openings for suspension bridge (Z=0, width 3.4) and canopy ramp (Z=-6.0)
	var inner_x := deck_size.x * 0.5 * (1.0 if at.x < 0 else -1.0)
	# South section of inner edge (from Z = 1.8 to 6.0)
	ArenaKit.box(geometry, Vector3(rail_thick, rail_h, 4.2), at + Vector3(inner_x, rail_h * 0.5, 3.9), WOOD_DARK)
	# Middle section between bridge and north ramp (from Z = -1.8 to -4.6)
	ArenaKit.box(geometry, Vector3(rail_thick, rail_h, 2.8), at + Vector3(inner_x, rail_h * 0.5, -3.2), WOOD_DARK)

	# Fort Shelter (3-sided treehouse lookout hut)
	var hut_pos := at + Vector3(-2.5 if at.x < 0 else 2.5, 0.0, 0.0)
	ArenaKit.box(geometry, Vector3(4.0, 3.2, 0.4), hut_pos + Vector3(0.0, 1.6, -2.5), tint)
	ArenaKit.box(geometry, Vector3(4.0, 3.2, 0.4), hut_pos + Vector3(0.0, 1.6, 2.5), tint)
	ArenaKit.box(geometry, Vector3(0.4, 3.2, 5.0), hut_pos + Vector3(-2.0 if at.x < 0 else 2.0, 1.6, 0.0), tint)
	ArenaKit.box(geometry, Vector3(4.6, 0.3, 5.6), hut_pos + Vector3(0.0, 3.3, 0.0), tint_dark)

	# Team Name Sign facing inward across the canopy chasm
	var inward_x := 2.25 if at.x < 0 else -2.25
	ArenaKit.sign_text(decor, sign_title, hut_pos + Vector3(inward_x, 3.85, 0.0),
			Vector3(0.0, 90.0 if at.x < 0 else -90.0, 0.0), Color.WHITE, 72, 0.008)

	# Fort cover crates & foam barricades
	ArenaKit.box(geometry, Vector3(1.2, 1.2, 1.2), at + Vector3(3.0 if at.x < 0 else -3.0, 0.6, -3.0), WOOD_DARK)
	ArenaKit.box(geometry, Vector3(1.4, 1.1, 0.5), at + Vector3(1.5 if at.x < 0 else -1.5, 0.55, 3.5), tint)


# --- Suspension Rope Bridge ---

func _build_suspension_bridge() -> void:
	# Spans from X = -10.0 to X = 10.0 at Z = 0.0, Y = DECK_Y
	var bridge_w := 3.4
	var plank_count := 14
	var start_x := -10.0
	var end_x := 10.0
	var step_x := (end_x - start_x) / float(plank_count)

	# Continuous walking beam underlay placed cleanly below catenary plank dip (zero Z-fighting)
	ArenaKit.box(geometry, Vector3(20.0, 0.25, bridge_w - 0.1), Vector3(0.0, DECK_Y - 0.55, 0.0), WOOD_DARK, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	for i in plank_count:
		var x := start_x + step_x * (float(i) + 0.5)
		# Catenary slight dip in the middle (0.35m dip)
		var t := (x - start_x) / (end_x - start_x)
		var dip := sin(t * PI) * 0.35
		var plank_pos := Vector3(x, DECK_Y - dip, 0.0)
		ArenaKit.box(geometry, Vector3(step_x * 0.98, 0.25, bridge_w), plank_pos, WOOD)

	# Rope railings along bridge
	ArenaKit.deco_box(decor, Vector3(20.4, 0.15, 0.15), Vector3(0.0, DECK_Y + 0.85, -bridge_w * 0.5), ROPE)
	ArenaKit.deco_box(decor, Vector3(20.4, 0.15, 0.15), Vector3(0.0, DECK_Y + 0.85, bridge_w * 0.5), ROPE)
	ArenaKit.box(geometry, Vector3(20.4, 0.9, 0.1), Vector3(0.0, DECK_Y + 0.45, -bridge_w * 0.5), ROPE)
	ArenaKit.box(geometry, Vector3(20.4, 0.9, 0.1), Vector3(0.0, DECK_Y + 0.45, bridge_w * 0.5), ROPE)

	# Canopy Walkway Ramps rising from both fort decks directly up to the High Crow's Nest
	ArenaKit.ramp(geometry, Vector3(-12.0, DECK_Y, -6.0), Vector3(-4.0, HIGH_NEST_Y, -6.0), 2.4, WOOD)
	ArenaKit.ramp(geometry, Vector3(12.0, DECK_Y, -6.0), Vector3(4.0, HIGH_NEST_Y, -6.0), 2.4, WOOD)


# --- High Crow's Nest & Spire ---

func _build_crow_nest() -> void:
	# High center platform around North Tree at Y = HIGH_NEST_Y (10.5m)
	var nest_pos := Vector3(0.0, HIGH_NEST_Y, -6.0)
	var nest_size := Vector3(8.0, 0.5, 8.0)
	ArenaKit.box(geometry, nest_size, nest_pos - Vector3(0.0, 0.25, 0.0), WOOD_DARK)

	# Railings around the crow's nest (leaving entrances for West/East ramps and South slide)
	var rail_h := 1.2
	# North railing
	ArenaKit.box(geometry, Vector3(nest_size.x, rail_h, 0.2), nest_pos + Vector3(0.0, rail_h * 0.5, -nest_size.z * 0.5), WOOD)
	# West railing segments (opening in center at Z=-6.0 for west ramp entry)
	ArenaKit.box(geometry, Vector3(0.2, rail_h, 2.6), nest_pos + Vector3(-nest_size.x * 0.5, rail_h * 0.5, -2.7), WOOD)
	ArenaKit.box(geometry, Vector3(0.2, rail_h, 2.6), nest_pos + Vector3(-nest_size.x * 0.5, rail_h * 0.5, 2.7), WOOD)
	# East railing segments (opening in center at Z=-6.0 for east ramp entry)
	ArenaKit.box(geometry, Vector3(0.2, rail_h, 2.6), nest_pos + Vector3(nest_size.x * 0.5, rail_h * 0.5, -2.7), WOOD)
	ArenaKit.box(geometry, Vector3(0.2, rail_h, 2.6), nest_pos + Vector3(nest_size.x * 0.5, rail_h * 0.5, 2.7), WOOD)
	# South railing (leaves center opening for ice slide chute)
	ArenaKit.box(geometry, Vector3(2.5, rail_h, 0.2), nest_pos + Vector3(-2.75, rail_h * 0.5, nest_size.z * 0.5), WOOD)
	ArenaKit.box(geometry, Vector3(2.5, rail_h, 0.2), nest_pos + Vector3(2.75, rail_h * 0.5, nest_size.z * 0.5), WOOD)

	# Cover crates on crow's nest
	ArenaKit.box(geometry, Vector3(1.1, 1.1, 1.1), nest_pos + Vector3(-2.2, 0.55, -2.0), Color(1.0, 0.75, 0.2))
	ArenaKit.box(geometry, Vector3(1.1, 1.1, 1.1), nest_pos + Vector3(2.2, 0.55, -2.0), Color(0.2, 0.8, 0.9))

	# Chainstorm Power-Up Spot on the high lookout (North of trunk)
	add_power_up_spot(nest_pos + Vector3(0.0, 0.0, -2.8))

	# High Canopy Foam Shield Pickup (South of trunk)
	add_shield_pickup(nest_pos + Vector3(0.0, 0.0, 2.8))


# --- Traversals, Jump-Pads & Elemental Hazards ---

func _build_traversals_and_hazards() -> void:
	# 1. Kinetic Jump-Pads: Launch from mid-decks up to the High Crow's Nest
	add_jump_pad(Vector3(-8.5, DECK_Y, -3.5), 17.5)
	add_jump_pad(Vector3(8.5, DECK_Y, -3.5), 17.5)
	# Ground Jump-Pad: launches straight up to the bridge deck
	add_jump_pad(Vector3(0.0, 0.0, 8.0), 15.5)

	# 2. Canopy Escape Ice Slide Chute + Bridge Landing Apron
	# Smooth frictionless slide descending from Crow's Nest (Y=10.5, Z=-2.0) to landing deck (Y=5.4, Z=4.5)
	ArenaKit.box(geometry, Vector3(3.8, 0.35, 3.6), Vector3(0.0, DECK_Y - 0.175, 3.4), WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	var slide_len := 8.3
	var slide_drop := HIGH_NEST_Y - DECK_Y
	var slide_mid := Vector3(0.0, (HIGH_NEST_Y + DECK_Y) * 0.5, 1.25)
	var slide_angle := rad_to_deg(atan2(slide_drop, 6.5))
	# Solid supporting slide slab
	ArenaKit.ramp(geometry, Vector3(0.0, DECK_Y, 4.5), Vector3(0.0, HIGH_NEST_Y, -2.0), 2.6, Color(0.65, 0.85, 0.95), 0.3, ArenaKit.SurfaceType.PLASTIC)
	# Frictionless Ice Slick trigger tilted downward toward +Z
	add_ice_slick(slide_mid + Vector3(0.0, 0.14, 0.0), Vector3(2.4, 0.16, slide_len),
			Vector3(0.0, 0.0, 1.0), Vector3(slide_angle, 0.0, 0.0))

	# 3. Gale-Force Wind Tunnels
	# Upper canopy wind zone blowing West to East strongly through the chasm
	add_wind_zone(Vector3(0.0, DECK_Y + 2.5, 0.0), Vector3(32.0, 6.0, 14.0), Vector3(1.0, 0.0, 0.0), 28.0, true)
	# Forest floor cross-breeze
	add_wind_zone(Vector3(0.0, 2.0, 10.0), Vector3(28.0, 4.0, 12.0), Vector3(-1.0, 0.0, 0.0), 12.0, false)

	# 4. Canopy Wind Vent on the Forest Floor (clear of bridge deck overhead)
	add_wind_vent(Vector3(5.2, 0.0, 4.2), 1.8, 16.5)

	# 5. Conductive Bird-Bath Puddle on the forest floor
	add_water_puddle(Vector3(0.0, 0.0, 2.5), 3.2)

	# 6. Ammo Buckets (Blue base, Orange base, Forest floor)
	add_bucket(Vector3(-18.5, DECK_Y, 2.5), BLUE, 150)
	add_bucket(Vector3(18.5, DECK_Y, 2.5), ORANGE, 150)
	add_bucket(Vector3(0.0, 0.0, 12.5), Color(0.25, 0.8, 0.4), 150)

	# 7. Reflective Mirrors for Trick Ricochet Tags (clear of ramps & trunks)
	add_mirror(Vector3(-18.5, DECK_Y + 1.5, -5.6), 25.0, Vector2(3.2, 2.2))
	add_mirror(Vector3(18.5, DECK_Y + 1.5, -5.6), -25.0, Vector2(3.2, 2.2))
	add_mirror(Vector3(0.0, HIGH_NEST_Y + 1.6, -9.8), 0.0, Vector2(4.0, 2.4))

	# 8. Wobble Bullseye Targets (mounted cleanly in front of trunk)
	add_target(Vector3(-10.0, DECK_Y + 2.2, 4.5), 45.0)
	add_target(Vector3(10.0, DECK_Y + 2.2, 4.5), -45.0)
	add_target(Vector3(0.0, 1.8, -3.9), 0.0)


# --- Spawns, Roam Points & Team Bases ---

func _build_spawns_and_points() -> void:
	# Team Bases, Flag Pedestals & Bomb Sites clear of the 4m tree trunks
	team_bases = [Vector3(-12.5, DECK_Y, 0.0), Vector3(12.5, DECK_Y, 0.0)]
	flag_pedestals = [Vector3(-12.5, DECK_Y, 0.0), Vector3(12.5, DECK_Y, 0.0)]
	bomb_sites = {
		"A": Vector3(0.0, HIGH_NEST_Y, -3.0),
		"B": Vector3(-12.5, DECK_Y, -3.2),
	}
	bomb_spawns = [Vector3(12.5, DECK_Y, 2.8)]

	# 14 Spawns covering all tiers and locations
	# West Fort Spawns
	add_spawn(Vector3(-18.5, DECK_Y, -4.0), Vector3(0.0, DECK_Y, 0.0))
	add_spawn(Vector3(-18.5, DECK_Y, 4.0), Vector3(0.0, DECK_Y, 0.0))
	add_spawn(Vector3(-12.0, DECK_Y, 2.5), Vector3(0.0, DECK_Y, 0.0))

	# East Fort Spawns
	add_spawn(Vector3(18.5, DECK_Y, -4.0), Vector3(0.0, DECK_Y, 0.0))
	add_spawn(Vector3(18.5, DECK_Y, 4.0), Vector3(0.0, DECK_Y, 0.0))
	add_spawn(Vector3(12.0, DECK_Y, 2.5), Vector3(0.0, DECK_Y, 0.0))

	# Bridge Spawns
	add_spawn(Vector3(-4.0, DECK_Y, 0.0), Vector3(1.0, DECK_Y, 0.0))
	add_spawn(Vector3(4.0, DECK_Y, 0.0), Vector3(-1.0, DECK_Y, 0.0))

	# High Crow's Nest Spawns
	add_spawn(Vector3(-2.2, HIGH_NEST_Y, -2.8), Vector3(0.0, HIGH_NEST_Y, 0.0))
	add_spawn(Vector3(2.2, HIGH_NEST_Y, -2.8), Vector3(0.0, HIGH_NEST_Y, 0.0))

	# Forest Floor Spawns
	add_spawn(Vector3(-12.0, 0.0, 10.0), Vector3(0.0, 0.0, 0.0))
	add_spawn(Vector3(12.0, 0.0, 10.0), Vector3(0.0, 0.0, 0.0))
	add_spawn(Vector3(-10.0, 0.0, -14.0), Vector3(0.0, 0.0, 0.0))
	add_spawn(Vector3(10.0, 0.0, -14.0), Vector3(0.0, 0.0, 0.0))

	# Additional Roam Points for Bot pathfinding
	add_roam_point(Vector3(0.0, DECK_Y, 0.0))
	add_roam_point(Vector3(-8.0, (DECK_Y + HIGH_NEST_Y) * 0.5, -6.0))
	add_roam_point(Vector3(8.0, (DECK_Y + HIGH_NEST_Y) * 0.5, -6.0))
	add_roam_point(Vector3(-16.0, DECK_Y * 0.5, 10.0))
	add_roam_point(Vector3(16.0, DECK_Y * 0.5, 10.0))
	add_roam_point(Vector3(0.0, HIGH_NEST_Y, -8.8))
	add_roam_point(Vector3(0.0, 0.0, 8.0))
	add_roam_point(Vector3(0.0, 0.0, -8.0))


# --- Decorative Scenery ---

func _build_scenery() -> void:
	# Surrounding forest trees outside the fence
	for i in 16:
		var angle := float(i) / 16.0 * TAU
		var dist := _rng.randf_range(44.0, 68.0)
		var tree_pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		ArenaKit.tree(decor, tree_pos, _rng.randf_range(1.4, 2.2))

	# Distant neighbour houses
	ArenaKit.house(decor, Vector3(-58.0, 0.0, -42.0), Vector3(14.0, 7.5, 18.0), Color(0.9, 0.86, 0.78), Color(0.72, 0.28, 0.22))
	ArenaKit.house(decor, Vector3(56.0, 0.0, -44.0), Vector3(16.0, 8.0, 16.0), Color(0.85, 0.88, 0.92), Color(0.24, 0.38, 0.58))
	ArenaKit.house(decor, Vector3(54.0, 0.0, 48.0), Vector3(15.0, 7.0, 17.0), Color(0.95, 0.92, 0.82), Color(0.48, 0.32, 0.22))
