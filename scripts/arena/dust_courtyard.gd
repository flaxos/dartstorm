class_name DustCourtyard
extends Arena
## DUSTY COURTYARD: Faithfully reconstructed after Counter-Strike's iconic de_dust (Dust 1).
## Designed strictly according to Dave Johnston's canonical layout and Hammer scale:
##   - T-Spawn: South-West staging plaza with crates, pallets, and urns
##   - The Sunken Underpass: Continuous sunken canal trench (Y = -2.5m) passing directly under the Sniper Bridge
##   - The Hallway: Covered arterial corridor with entrance stairs (Y = 1.5m), 90-degree turn, and iconic blind-corner choke
##   - The Double Doors Choke: Heavy arched gateway with propped wooden doors leading to Central Intersection
##   - The Overhead Sniper Bridge: Suspended deck (Y = 1.0m) over the Underpass with protective stone firing parapets
##   - Bombsite B & CT Spawn: Northern fortified garrison compound containing Bombsite B and CT spawn points
##   - Bombsite A: Expansive open desert courtyard with market awnings, sand dunes, and shipping crate plant zone
##   - Underpass Canal Exit: Curved stone arch portal delivering flanking Terrorists directly into the Courtyard

const HALF_X := 40.0
const HALF_Z := 36.0

const DESERT_SAND := Color(0.88, 0.76, 0.56)
const SANDSTONE := Color(0.85, 0.74, 0.55)
const SANDSTONE_DARK := Color(0.72, 0.62, 0.44)
const PAVER := Color(0.82, 0.72, 0.54)
const CRATE_WOOD := Color(0.68, 0.46, 0.28)
const TRIM_BLUE := Color(0.20, 0.45, 0.85)
const TRIM_ORANGE := Color(0.95, 0.45, 0.10)


func _build() -> void:
	arena_name = "Dusty Courtyard"
	_build_sky_and_sun(-44.0, 0.16)
	_build_ground_and_walls()
	_build_t_spawn_and_hallway()
	_build_underpass_and_bridge()
	_build_east_courtyard_and_bombsite_a()
	_build_ct_spawn_and_bombsite_b()
	_build_spawns_and_objectives()


func _build_ground_and_walls() -> void:
	# Continuous infinite background desert floor (placed deep at Y = -4.0 so it never clips into trenches)
	ArenaKit.deco_box(decor, Vector3(500.0, 0.2, 500.0), Vector3(0.0, -4.0, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# Safety bedrock base floor underneath entire map (at Y = -4.0)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -4.5, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# --- Segmented Ground Slabs at Y = 0.0 (Leaving Underpass Canal completely open!) ---
	# 1. West Ground Slab: T-Spawn West, Hallway, and West boundary (X: -40.0 to -15.5, Z: -36.0 to 36.0)
	ArenaKit.box(geometry, Vector3(24.5, 1.0, 72.0), Vector3(-27.75, -0.5, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 2. East Ground Slab: Grand Courtyard, Bombsite A, and East boundary (X: 5.0 to 40.0, Z: -36.0 to 36.0)
	ArenaKit.box(geometry, Vector3(35.0, 1.0, 72.0), Vector3(22.5, -0.5, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 3. South Ground Slab: Behind T-Spawn (X: -15.5 to 5.0, Z: 20.0 to 36.0)
	ArenaKit.box(geometry, Vector3(20.5, 1.0, 16.0), Vector3(-5.25, -0.5, 28.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 4. North Ground Slab: CT Spawn Garrison & North area (X: -15.5 to 5.0, Z: -36.0 to -14.0)
	ArenaKit.box(geometry, Vector3(20.5, 1.0, 22.0), Vector3(-5.25, -0.5, -25.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 5. Central Island: Between Underpass canal and Courtyard dividing wall, south of the exit ramp (X: -10.5 to 5.0, Z: -6.0 to 20.0)
	ArenaKit.box(geometry, Vector3(15.5, 1.0, 26.0), Vector3(-2.75, -0.5, 7.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# High canyon fortress boundary walls with architectural coping cornices
	var wall_h := 7.5
	var thick := 1.4
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)

	# Decorative coping trim along wall tops
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, -HALF_Z), Vector3(HALF_X * 2.0 + 0.6, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, HALF_Z), Vector3(HALF_X * 2.0 + 0.6, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(-HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.6))
	ArenaKit.cornice(decor, Vector3(HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.6))


func _build_t_spawn_and_hallway() -> void:
	# --- T-Spawn Plaza (South: X: -30 to -10, Z: 18 to 32) ---
	ArenaKit.box(geometry, Vector3(20.0, 0.3, 14.0), Vector3(-20.0, -0.15, 25.0), PAVER)
	ArenaKit.box(geometry, Vector3(20.0, 0.06, 0.4), Vector3(-20.0, 0.03, 18.0), SANDSTONE_DARK)

	# High-poly T-Spawn staging equipment: pallets, stacked crates, barrels, and terracotta urns
	ArenaKit.pallet(geometry, Vector3(-24.0, 0.0, 26.0))
	ArenaKit.crate(geometry, Vector3(-24.0, 0.20, 26.0), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, Vector3(-22.0, 0.0, 26.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 15.0, 0.0))
	ArenaKit.crate(geometry, Vector3(-23.0, 1.6, 26.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, -10.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(-26.0, 0.0, 28.0))
	ArenaKit.urn(decor, Vector3(-17.0, 0.0, 28.0), 1.2)
	ArenaKit.urn(decor, Vector3(-15.5, 0.0, 27.0), 1.0)

	# --- West Long Hallway (leading North from T-Spawn along X = -24.0) ---
	var hall_w := 5.4
	# West exterior wall
	ArenaKit.box(geometry, Vector3(0.9, 5.0, 30.0), Vector3(-27.0, 2.5, 3.0), SANDSTONE)
	# East interior partition wall separating Hallway from Underpass
	ArenaKit.box(geometry, Vector3(0.9, 5.0, 26.0), Vector3(-21.0, 2.5, 5.0), SANDSTONE)

	# Hallway paved floor (Z: 18.0 down to 14.0 at Y = 0.0)
	ArenaKit.box(geometry, Vector3(hall_w, 0.3, 4.0), Vector3(-24.0, -0.15, 16.0), PAVER)

	# Stairs rising up in the hallway from Y = 0.0 to Y = 1.5 (between Z = 14.0 and Z = 8.0)
	ArenaKit.ramp(geometry, Vector3(-24.0, 0.0, 14.0), Vector3(-24.0, 1.5, 8.0), hall_w, SANDSTONE)

	# Elevated Upper Hallway (Y = 1.5, Z from 8.0 down to -8.0)
	ArenaKit.box(geometry, Vector3(hall_w, 1.5, 16.0), Vector3(-24.0, 0.75, 0.0), SANDSTONE)

	# Hallway turns East at Z = -8.0 towards Double Doors (X: -24.0 to -8.0)
	var turn_len := 16.0
	ArenaKit.box(geometry, Vector3(turn_len, 1.5, hall_w), Vector3(-16.0, 0.75, -8.0), SANDSTONE)

	# North and South walls framing the East-heading hallway
	ArenaKit.box(geometry, Vector3(18.0, 5.0, 0.9), Vector3(-18.0, 2.5, -8.0 - hall_w * 0.5 - 0.45), SANDSTONE)
	ArenaKit.box(geometry, Vector3(12.0, 5.0, 0.9), Vector3(-15.0, 2.5, -8.0 + hall_w * 0.5 + 0.45), SANDSTONE)

	# --- The Iconic Blind-Corner Crate Stack at Hallway Turn ---
	# Dave Johnston specifically designed these crates to block long sightlines from T-stairs to Double Doors
	ArenaKit.crate(geometry, Vector3(-24.0, 1.5, -5.5), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, Vector3(-24.0, 1.5, -3.5), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 18.0, 0.0))
	ArenaKit.crate(geometry, Vector3(-24.0, 3.1, -4.5), Vector3(1.4, 1.4, 1.4), Vector3(0.0, -12.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(-22.0, 1.5, -4.5))

	# Tactical crates along hallway corridor
	ArenaKit.crate(geometry, Vector3(-15.0, 1.5, -10.0), Vector3(1.5, 1.5, 1.5))
	ArenaKit.barrel(geometry, Vector3(-17.0, 1.5, -6.2))

	# --- Double Doors Choke (at X = -10.0, Z = -8.0, Y = 1.5) ---
	ArenaKit.arch(geometry, Vector3(-10.0, 1.5, -8.0), hall_w, 4.8, 1.2, Vector3(0.0, 90.0, 0.0))

	# Heavy propped open wooden double doors
	ArenaKit.box(geometry, Vector3(0.2, 3.2, 1.4), Vector3(-9.5, 3.1, -8.0 - 1.3), CRATE_WOOD, Vector3(0.0, 32.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 3.2, 1.4), Vector3(-9.5, 3.1, -8.0 + 1.3), CRATE_WOOD, Vector3(0.0, -32.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# Ramp descending from Double Doors (Y = 1.5) down to Central Intersection (Y = 1.0)
	ArenaKit.ramp(geometry, Vector3(-9.0, 1.5, -8.0), Vector3(-5.0, 1.0, -8.0), hall_w, SANDSTONE)


func _build_underpass_and_bridge() -> void:
	# --- The Sunken Underpass Trench (depth Y = -2.5) ---
	var tun_w := 5.0
	# Shallow decline ramp from T-Spawn (X = -13.0, Z = 20.0, Y = 0.0) down to (X = -13.0, Z = 11.0, Y = -2.5)
	ArenaKit.ramp(geometry, Vector3(-13.0, 0.0, 20.0), Vector3(-13.0, -2.5, 11.0), tun_w, SANDSTONE)

	# Continuous straight underpass canal running South to North (Z: 11.0 down to -7.0 at Y = -2.5)
	var tun_len := 18.0
	ArenaKit.box(geometry, Vector3(tun_w, 0.4, tun_len), Vector3(-13.0, -2.7, 2.0), PAVER)

	# Sturdy retaining stone walls flanking the sunken underpass
	var ret_h := 3.8
	# Left retaining wall (X = -15.95, runs from Z = 20.0 to Z = -13.0)
	ArenaKit.box(geometry, Vector3(0.9, ret_h, 33.0), Vector3(-13.0 - tun_w * 0.5 - 0.45, -0.8, 3.5), SANDSTONE_DARK)
	# Right retaining wall (X = -10.05, runs from Z = 20.0 to Z = -6.0)
	ArenaKit.box(geometry, Vector3(0.9, ret_h, 26.0), Vector3(-13.0 + tun_w * 0.5 + 0.45, -0.8, 7.0), SANDSTONE_DARK)

	# Retaining wall coping cornices (smooth carved stone coping without brick lines)
	ArenaKit.cornice(decor, Vector3(-13.0 - tun_w * 0.5 - 0.45, 1.15, 3.5), Vector3(1.3, 0.3, 33.0))
	ArenaKit.cornice(decor, Vector3(-13.0 + tun_w * 0.5 + 0.45, 1.15, 7.0), Vector3(1.3, 0.3, 26.0))

	# Underpass tactical cover underneath and approaching the bridge
	ArenaKit.pallet(geometry, Vector3(-14.0, -2.5, 5.0))
	ArenaKit.crate(geometry, Vector3(-14.0, -2.3, 5.0), Vector3(1.6, 1.6, 1.6))
	ArenaKit.barrel(geometry, Vector3(-11.5, -2.5, 4.5))
	ArenaKit.crate(geometry, Vector3(-12.0, -2.5, -3.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, 15.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(-14.2, -2.5, -3.5))

	# --- The Overhead Sniper Bridge (deck Y = 1.0, spanning underpass at Z = 0.0) ---
	var bridge_w := 4.4
	# Elevated walkway deck crossing over the underpass
	ArenaKit.box(geometry, Vector3(tun_w + 1.8, 0.4, bridge_w), Vector3(-13.0, 1.0, 0.0), PAVER)

	# High-poly stone arch underneath the bridge framing the underpass passage with full 3.5m clearance
	ArenaKit.arch(geometry, Vector3(-13.0, -2.5, 0.0), tun_w + 0.4, 3.5, bridge_w)

	# Solid stone parapet railings on both sides of the bridge
	ArenaKit.box(geometry, Vector3(tun_w + 1.8, 1.0, 0.4), Vector3(-13.0, 1.7, -bridge_w * 0.5 + 0.2), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(tun_w + 1.8, 1.0, 0.4), Vector3(-13.0, 1.7, bridge_w * 0.5 - 0.2), SANDSTONE_DARK)

	# Bridge walkway connecting to Central Intersection (North-West)
	ArenaKit.box(geometry, Vector3(bridge_w, 0.4, 8.0), Vector3(-8.0, 1.0, -4.0), PAVER)
	ArenaKit.box(geometry, Vector3(6.0, 0.4, bridge_w), Vector3(-10.0, 1.0, 0.0), PAVER)
	# Ramp connecting bridge walkway down to courtyard level
	ArenaKit.ramp(geometry, Vector3(-5.0, 1.0, -4.0), Vector3(0.0, 0.0, -4.0), bridge_w, SANDSTONE)

	# Bridge walkway continuing North into CT Spawn compound
	ArenaKit.box(geometry, Vector3(bridge_w, 0.4, 10.0), Vector3(-13.0, 1.0, -9.0), PAVER)

	# --- Underpass Canal Exit into Courtyard ---
	# At Z = -7.0 to -13.0, the Underpass turns East and ascends via a wide ramp into the Courtyard
	var exit_w := 5.4
	# Canal floor turning East
	ArenaKit.box(geometry, Vector3(8.0, 0.4, exit_w), Vector3(-7.0, -2.7, -9.5), PAVER)
	# North retaining wall of canal turn (Z = -13.0)
	ArenaKit.box(geometry, Vector3(18.0, ret_h, 0.9), Vector3(-5.0, -0.8, -12.65), SANDSTONE_DARK)
	ArenaKit.cornice(decor, Vector3(-5.0, 1.15, -12.65), Vector3(18.0, 0.3, 1.3))
	# South retaining wall of canal turn (Z = -6.0)
	ArenaKit.box(geometry, Vector3(12.0, ret_h, 0.9), Vector3(-2.0, -0.8, -6.35), SANDSTONE_DARK)
	ArenaKit.cornice(decor, Vector3(-2.0, 1.15, -6.35), Vector3(12.0, 0.3, 1.3))

	# Ramp ascending from Underpass canal (Y = -2.5) up to Courtyard (Y = 0.0)
	ArenaKit.ramp(geometry, Vector3(-3.0, -2.5, -9.5), Vector3(5.0, 0.0, -9.5), exit_w, SANDSTONE)

	# High-poly curved arch framing the Underpass exit portal into the open Courtyard
	ArenaKit.arch(geometry, Vector3(5.0, 0.0, -9.5), exit_w + 0.8, 4.8, 1.4, Vector3(0.0, 90.0, 0.0))


func _build_east_courtyard_and_bombsite_a() -> void:
	# Dividing barrier separating the Hallway/Underpass structures from the Courtyard (X = 5.0, Z: -6.0 to 24.0)
	ArenaKit.box(geometry, Vector3(1.0, 5.5, 30.0), Vector3(5.0, 2.75, 9.0), SANDSTONE)

	# High-poly Curved Arch connecting Central Intersection into Courtyard (at X = 5.0, Z = -3.0)
	ArenaKit.arch(geometry, Vector3(5.0, 0.0, -3.0), 5.2, 5.0, 1.4, Vector3(0.0, 90.0, 0.0))
	ArenaKit.ramp(geometry, Vector3(-1.0, 1.0, -3.0), Vector3(4.0, 0.0, -3.0), 4.8, SANDSTONE)

	# Market awnings along courtyard interior walls
	ArenaKit.awning(decor, Vector3(5.6, 3.6, 4.0), 4.2, Vector3(0.0, 90.0, 0.0))
	ArenaKit.awning(decor, Vector3(5.6, 3.6, 16.0), 4.2, Vector3(0.0, 90.0, 0.0))
	ArenaKit.awning(decor, Vector3(39.0, 3.6, 6.0), 4.5, Vector3(0.0, -90.0, 0.0))

	# --- Bombsite A: The Grand Sandstone Courtyard (centered at X = 24.0, Z = 8.0) ---
	var a_pos := Vector3(24.0, 0.0, 8.0)
	var platform_size := 14.0

	# Paved apron stone terrace for Bombsite A
	ArenaKit.box(geometry, Vector3(platform_size, 0.3, platform_size), a_pos + Vector3(0.0, -0.15, 0.0), PAVER)
	ArenaKit.box(geometry, Vector3(platform_size + 0.6, 0.08, 0.4), a_pos + Vector3(0.0, 0.04, -platform_size * 0.5 - 0.2), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(platform_size + 0.6, 0.08, 0.4), a_pos + Vector3(0.0, 0.04, platform_size * 0.5 + 0.2), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.4, 0.08, platform_size + 0.6), a_pos + Vector3(-platform_size * 0.5 - 0.2, 0.04, 0.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.4, 0.08, platform_size + 0.6), a_pos + Vector3(platform_size * 0.5 + 0.2, 0.04, 0.0), SANDSTONE_DARK)

	# Authentic CS 1.6 de_dust Bombsite A Target: High-poly stacked shipping crates, pallets, and hazard barrels
	ArenaKit.pallet(geometry, a_pos + Vector3(0.0, 0.0, 0.0))
	ArenaKit.crate(geometry, a_pos + Vector3(0.0, 0.20, 0.0), Vector3(2.0, 1.8, 2.0))
	ArenaKit.crate(geometry, a_pos + Vector3(1.8, 0.0, -0.2), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 12.0, 0.0))
	ArenaKit.crate(geometry, a_pos + Vector3(-1.6, 0.0, 0.4), Vector3(1.6, 1.6, 1.6), Vector3(0.0, -15.0, 0.0))
	ArenaKit.crate(geometry, a_pos + Vector3(0.2, 2.0, 0.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, 8.0, 0.0))

	# Heavy tactical inflatable barriers framing the perimeter of Site A
	ArenaKit.barrier(geometry, a_pos + Vector3(4.5, 0.0, -4.0), Vector3(0.0, 45.0, 0.0))
	ArenaKit.barrier(geometry, a_pos + Vector3(-4.5, 0.0, 4.0), Vector3(0.0, -45.0, 0.0))

	# Barrels and terracotta urns decorating the courtyard
	ArenaKit.barrel(geometry, a_pos + Vector3(-5.0, 0.0, -3.5))
	ArenaKit.barrel(geometry, a_pos + Vector3(-5.0, 0.0, -4.9))
	ArenaKit.urn(decor, a_pos + Vector3(5.5, 0.0, 3.5), 1.25)
	ArenaKit.urn(decor, a_pos + Vector3(6.5, 0.0, 2.0), 1.05)

	# Southern Courtyard open sand dunes with cover obstacles
	ArenaKit.pallet(geometry, Vector3(18.0, 0.0, 22.0))
	ArenaKit.crate(geometry, Vector3(18.0, 0.20, 22.0), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, Vector3(20.0, 0.0, 22.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, 20.0, 0.0))
	ArenaKit.urn(decor, Vector3(15.5, 0.0, 24.0), 1.15)


func _build_ct_spawn_and_bombsite_b() -> void:
	# --- CT Spawn & Bombsite B Fortified Compound (North: X = -18 to 6, Z = -16 to -34) ---
	var ct_pos := Vector3(-6.0, 0.5, -25.0)

	# Raised garrison terrace floor
	ArenaKit.box(geometry, Vector3(24.0, 0.5, 18.0), ct_pos, SANDSTONE)
	ArenaKit.box(geometry, Vector3(22.0, 0.3, 16.0), ct_pos + Vector3(0.0, 0.25, 0.0), PAVER)

	# Perimeter compound walls
	ArenaKit.box(geometry, Vector3(24.0, 5.0, 0.9), ct_pos + Vector3(0.0, 2.75, -9.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.9, 5.0, 18.0), ct_pos + Vector3(-12.0, 2.75, 0.0), SANDSTONE)

	# South wall connecting to Bridge approach
	ArenaKit.box(geometry, Vector3(8.0, 5.0, 0.9), ct_pos + Vector3(-7.5, 2.75, 9.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(8.0, 5.0, 0.9), ct_pos + Vector3(7.5, 2.75, 9.0), SANDSTONE)

	# Curved archway at South entrance from Sniper Bridge into CT compound
	ArenaKit.arch(geometry, ct_pos + Vector3(0.0, 0.5, 9.0), 5.4, 4.8, 1.4)

	# --- Bombsite B: Located directly inside the CT Spawn compound (Dave Johnston design) ---
	var b_pos := Vector3(-8.0, 0.5, -24.0)
	ArenaKit.pallet(geometry, b_pos)
	ArenaKit.crate(geometry, b_pos + Vector3(0.0, 0.20, 0.0), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, b_pos + Vector3(1.8, 0.0, 0.2), Vector3(1.6, 1.6, 1.6), Vector3(0.0, -15.0, 0.0))
	ArenaKit.crate(geometry, b_pos + Vector3(-0.2, 0.0, -1.8), Vector3(1.5, 1.5, 1.5), Vector3(0.0, 18.0, 0.0))
	ArenaKit.crate(geometry, b_pos + Vector3(0.8, 1.8, 0.0), Vector3(1.4, 1.4, 1.4), Vector3(0.0, -8.0, 0.0))
	ArenaKit.barrel(geometry, b_pos + Vector3(-2.2, 0.0, 1.2))
	ArenaKit.barrel(geometry, b_pos + Vector3(-2.2, 0.0, 2.6))
	ArenaKit.urn(decor, b_pos + Vector3(3.2, 0.0, -1.5), 1.2)

	# Inflatable tactical barricade covering CT Spawn angles
	ArenaKit.barrier(geometry, ct_pos + Vector3(5.0, 0.5, -2.0), Vector3(0.0, 90.0, 0.0))

	# --- CT Connector Eastward into North Courtyard (X from 6.0 to 22.0, Z = -22.0) ---
	var con_w := 5.2
	ArenaKit.box(geometry, Vector3(16.0, 0.3, con_w), Vector3(14.0, -0.15, -22.0), PAVER)
	ArenaKit.box(geometry, Vector3(16.0, 5.0, 0.9), Vector3(14.0, 2.5, -22.0 - con_w * 0.5 - 0.45), SANDSTONE)
	ArenaKit.box(geometry, Vector3(12.0, 5.0, 0.9), Vector3(12.0, 2.5, -22.0 + con_w * 0.5 + 0.45), SANDSTONE)

	# Gateway arch framing the exit from CT compound into North Courtyard
	ArenaKit.arch(geometry, Vector3(6.0, 0.0, -22.0), con_w, 4.8, 1.2, Vector3(0.0, 90.0, 0.0))
	ArenaKit.arch(geometry, Vector3(22.0, 0.0, -22.0), con_w, 4.8, 1.2, Vector3(0.0, 90.0, 0.0))


func _build_spawns_and_objectives() -> void:
	# Team bases: Team 0 (CT / Blue) at North Compound, Team 1 (T / Orange) at South Plaza
	team_bases.clear()
	team_bases.append(Vector3(-6.0, 0.5, -28.0))   # CT Base
	team_bases.append(Vector3(-20.0, 0.0, 25.0))  # T Base

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(-8.0, 0.5, -24.0)) # Blue Flag at Bombsite B (CT compound)
	flag_pedestals.append(Vector3(-20.0, 0.0, 25.0)) # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(24.0, 0.0, 8.0)    # Site A: The Grand Courtyard
	bomb_sites["B"] = Vector3(-8.0, 0.5, -24.0)  # Site B: CT Spawn Garrison Compound
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(-18.0, 0.0, 24.0))

	# Player / Bot Spawns (CT vs T)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(-10.0, 0.5, -28.0), Vector3(-2.0, 0.5, -28.0),
		Vector3(-8.0, 0.5, -31.0), Vector3(-4.0, 0.5, -31.0),
		Vector3(-12.0, 0.5, -26.0), Vector3(0.0, 0.5, -26.0),
	]
	var t_spawns := [
		Vector3(-24.0, 0.0, 22.0), Vector3(-16.0, 0.0, 22.0),
		Vector3(-22.0, 0.0, 27.0), Vector3(-14.0, 0.0, 27.0),
		Vector3(-25.0, 0.0, 30.0), Vector3(-17.0, 0.0, 30.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in t_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Tactical Roam Points across the canonical de_dust routes
	roam_points.append(Vector3(-20.0, 0.0, 25.0))  # T Spawn
	roam_points.append(Vector3(-24.0, 0.0, 16.0))  # Lower Long Hallway
	roam_points.append(Vector3(-24.0, 1.5, 4.0))   # Upper Long Hallway
	roam_points.append(Vector3(-24.0, 1.5, -8.0))  # Hallway Blind Corner
	roam_points.append(Vector3(-10.0, 1.5, -8.0))  # Double Doors Choke
	roam_points.append(Vector3(-5.0, 1.0, -6.0))   # Central Intersection
	roam_points.append(Vector3(-13.0, 1.0, 0.0))   # Overhead Sniper Bridge
	roam_points.append(Vector3(-13.0, -2.5, 12.0)) # Underpass Entrance
	roam_points.append(Vector3(-13.0, -2.5, 0.0))  # Underpass beneath Bridge
	roam_points.append(Vector3(5.0, 0.0, -10.0))   # Underpass Courtyard Exit Portal
	roam_points.append(Vector3(12.0, 0.0, 0.0))    # West Courtyard
	roam_points.append(Vector3(24.0, 0.0, 8.0))    # Bombsite A (Grand Courtyard)
	roam_points.append(Vector3(30.0, 0.0, 18.0))   # South-East Courtyard
	roam_points.append(Vector3(22.0, 0.0, -16.0))  # North Courtyard
	roam_points.append(Vector3(14.0, 0.0, -22.0))  # CT Courtyard Connector
	roam_points.append(Vector3(-8.0, 0.5, -24.0))  # Bombsite B
	roam_points.append(Vector3(-6.0, 0.5, -28.0))  # CT Spawn

	# Power-up Spot (Suspended on the Sniper Bridge over the Underpass)
	power_up_spots.clear()
	power_up_spots.append(Vector3(-13.0, 1.0, 0.0))

	# Tactical Ammo Buckets
	add_bucket(Vector3(-24.0, 0.0, 20.0), Color(0.95, 0.45, 0.15)) # T Hallway start
	add_bucket(Vector3(-10.0, 1.5, -6.0), Color(0.95, 0.45, 0.15)) # Choke Double Doors
	add_bucket(Vector3(-13.0, -2.5, 0.0), Color(0.95, 0.45, 0.15)) # Sunken Underpass
	add_bucket(Vector3(24.0, 0.0, 14.0), Color(0.20, 0.50, 0.95))  # Bombsite A Courtyard
	add_bucket(Vector3(-8.0, 0.5, -20.0), Color(0.20, 0.50, 0.95)) # Bombsite B
	add_bucket(Vector3(-6.0, 0.5, -31.0), Color(0.20, 0.50, 0.95)) # CT Spawn

	# Tactical Foam Shield Pickup on top of the Sniper Bridge
	var shield := ShieldPickup.new()
	shield.position = Vector3(-13.0, 1.8, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
