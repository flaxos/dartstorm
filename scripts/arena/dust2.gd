class_name Dust2
extends Arena
## DUSTSTORM II: Authentically laid out after Counter-Strike 2's iconic de_dust2.
## Faithfully maps every callout from the official CS2 radar map:
##   - T-Spawn, Suicide, T-Ramp, TAXI
##   - Long A: Long Doors, Blue Box, Pit, A Long, A Car, A Ramp
##   - Mid: Top Mid, Mid Doors, Lower Mid, Truck, X-box
##   - Catwalk & Short A: Catwalk, Stairs, Short Boost
##   - B Route: Outside Tunnel, Upper B Tunnel, Tunnel Stairs, Lower Tunnel
##   - Bombsite B: B Platform, Default, Barrels, Snipers Box, B Car, B Window, B Doors
##   - Bombsite A: Elevated Platform, Default, Goose, Ninja
##   - CT Spawn connecting seamlessly to Lower Mid, B Doors, and Site A

const HALF_X := 44.0
const HALF_Z := 44.0

const DESERT_SAND := Color(0.88, 0.76, 0.56)
const SANDSTONE := Color(0.86, 0.76, 0.58)
const SANDSTONE_DARK := Color(0.74, 0.64, 0.46)
const PAVER := Color(0.82, 0.72, 0.54)
const CRATE_WOOD := Color(0.70, 0.48, 0.30)
const METAL_DOOR := Color(0.45, 0.50, 0.55)
const CAR_BLUE := Color(0.20, 0.40, 0.75)
const TRIM_BLUE := Color(0.20, 0.45, 0.85)


func _build() -> void:
	arena_name = "Duststorm II"
	_build_sky_and_sun(-48.0, 0.14)
	_build_ground_and_walls()
	_build_t_spawn_and_approaches()
	_build_long_a_and_pit()
	_build_mid_and_doors()
	_build_catwalk_short_and_site_a()
	_build_b_tunnels_and_site_b()
	_build_ct_spawn()
	_build_spawns_and_objectives()


func _build_ground_and_walls() -> void:
	# Main terrain ground plane - sun-baked desert sand
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)
	ArenaKit.deco_box(decor, Vector3(500.0, 0.2, 500.0), Vector3(0.0, -0.55, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# Boundary fortress canyon walls
	var wall_h := 7.5
	var thick := 1.2
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)


func _build_t_spawn_and_approaches() -> void:
	# --- T-Spawn Plaza (South: X: -10 to 10, Z: 30 to 40) ---
	ArenaKit.box(geometry, Vector3(22.0, 0.3, 12.0), Vector3(0.0, -0.15, 34.0), PAVER)
	# Stone curb framing the northern edge of T-Spawn towards Suicide and approaches
	ArenaKit.box(geometry, Vector3(22.0, 0.06, 0.4), Vector3(0.0, 0.03, 28.0), SANDSTONE_DARK)

	# Staging crates at T Spawn
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 1.8), Vector3(-4.0, 0.9, 36.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-2.0, 0.8, 36.0), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(3.0, 0.8, 35.0), CRATE_WOOD, Vector3(0.0, -10.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- Suicide (Sniper Alley looking straight North into Mid) ---
	# Corridor walls framing Suicide from Z = 28 to Z = 14
	var sui_w := 4.2
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 16.0), Vector3(-sui_w * 0.5 - 0.4, 2.5, 20.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 16.0), Vector3(sui_w * 0.5 + 0.4, 2.5, 20.0), SANDSTONE)

	# --- T-Ramp & Outside Tunnel (West approach towards B Tunnels) ---
	# Connecting corridor from T Spawn West (X: -10.0 to -24.0, Z: 26.0)
	ArenaKit.box(geometry, Vector3(16.0, 0.3, 6.0), Vector3(-17.0, -0.15, 26.0), PAVER)
	ArenaKit.box(geometry, Vector3(16.0, 5.0, 0.8), Vector3(-17.0, 2.5, 29.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(12.0, 5.0, 0.8), Vector3(-15.0, 2.5, 22.5), SANDSTONE)
	# Turn North into Outside Tunnel (X = -24.0, Z: 26.0 to 18.0)
	ArenaKit.box(geometry, Vector3(6.0, 0.3, 10.0), Vector3(-24.0, -0.15, 21.0), PAVER)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 12.0), Vector3(-27.5, 2.5, 20.0), SANDSTONE)

	# --- TAXI & Long Doors approach (East approach towards Long A) ---
	# Connecting corridor from T Spawn East (X: 10.0 to 22.0, Z: 26.0)
	ArenaKit.box(geometry, Vector3(14.0, 0.3, 6.0), Vector3(16.0, -0.15, 26.0), PAVER)
	ArenaKit.box(geometry, Vector3(14.0, 5.0, 0.8), Vector3(16.0, 2.5, 29.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 5.0, 0.8), Vector3(14.0, 2.5, 22.5), SANDSTONE)
	# TAXI cover obstacle at (X = 18.0, Z = 20.0)
	ArenaKit.box(geometry, Vector3(2.2, 1.4, 4.2), Vector3(18.0, 0.7, 20.0), CAR_BLUE, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.METAL)


func _build_long_a_and_pit() -> void:
	# --- Long Doors (Double Doors gateway at X = 20.0, Z = 14.0) ---
	var door_w := 4.4
	# Building enclosing Long Doors
	ArenaKit.box(geometry, Vector3(6.0, 5.0, 0.8), Vector3(14.0, 2.5, 14.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(6.0, 5.0, 0.8), Vector3(26.0, 2.5, 14.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(door_w, 1.6, 0.8), Vector3(20.0, 4.2, 14.0), SANDSTONE_DARK)

	# Propped wooden/metal doors
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.2), Vector3(19.6, 1.7, 14.0 - 1.1), CRATE_WOOD, Vector3(0.0, 30.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.2), Vector3(19.6, 1.7, 14.0 + 1.1), CRATE_WOOD, Vector3(0.0, -30.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- Blue Box (outside Long Doors at X = 15.0, Z = 7.0) ---
	ArenaKit.box(geometry, Vector3(2.4, 2.2, 5.0), Vector3(15.0, 1.1, 7.0), TRIM_BLUE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)

	# --- Long Pit (Sunken Depression at X = 25.0 to 33.0, Z = 6.0 to 14.0, depth Y = -1.6) ---
	var pit_w := 8.0
	var pit_l := 9.0
	ArenaKit.box(geometry, Vector3(pit_w, 0.4, pit_l), Vector3(29.0, -1.8, 10.0), PAVER)
	# Pit retaining walls
	ArenaKit.box(geometry, Vector3(pit_w, 2.0, 0.8), Vector3(29.0, -0.6, 14.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 2.0, pit_l), Vector3(33.5, -0.6, 10.0), SANDSTONE)
	# Ramp emerging from Pit heading North onto A Long
	ArenaKit.ramp(geometry, Vector3(28.0, -1.6, 6.0), Vector3(28.0, 0.0, 3.0), 5.0, SANDSTONE)

	# --- A Long Straightway (X = 26.0, Z from 4.0 down to -8.0) ---
	var long_w := 8.0
	ArenaKit.box(geometry, Vector3(long_w, 0.3, 14.0), Vector3(26.0, -0.15, -2.0), SANDSTONE)
	# Wall separating A Long from Mid/Catwalk
	ArenaKit.box(geometry, Vector3(0.8, 5.5, 26.0), Vector3(20.0, 2.75, -2.0), SANDSTONE)

	# A Car (wreck/crates on A Long at X = 28.0, Z = -3.0)
	ArenaKit.box(geometry, Vector3(2.2, 1.4, 4.4), Vector3(28.0, 0.7, -3.0), CAR_BLUE, Vector3(0.0, -12.0, 0.0), ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(26.0, 0.7, -3.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# --- A Ramp (rising up onto Site A: Y = 0.0 to Y = 1.8 between Z = -8.0 and Z = -14.0) ---
	ArenaKit.ramp(geometry, Vector3(24.0, 0.0, -8.0), Vector3(24.0, 1.8, -14.0), 6.5, SANDSTONE)


func _build_mid_and_doors() -> void:
	# --- Top Mid & Mid Avenue (X: -4.0 to 4.0, Z: 12.0 down to -4.0) ---
	var mid_w := 8.0
	ArenaKit.box(geometry, Vector3(mid_w, 0.3, 18.0), Vector3(0.0, -0.15, 4.0), PAVER)

	# West wall of Mid (separating Mid from B Tunnels)
	ArenaKit.box(geometry, Vector3(0.8, 5.5, 24.0), Vector3(-5.0, 2.75, 4.0), SANDSTONE)

	# --- X-Box (The iconic jump crate at X = 2.8, Z = 0.0) ---
	# Dimensions 2.2m x 1.8m x 2.2m - allows players to jump up to Catwalk!
	ArenaKit.box(geometry, Vector3(2.2, 1.8, 2.2), Vector3(2.8, 0.9, 0.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Smaller helper step crate
	ArenaKit.box(geometry, Vector3(1.2, 0.9, 1.2), Vector3(2.8, 0.45, 1.8), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# --- Mid Double Doors (at Z = -5.0, X = 0.0) ---
	# Heavy stone doorway
	ArenaKit.box(geometry, Vector3(2.6, 5.0, 0.8), Vector3(-3.2, 2.5, -5.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.6, 5.0, 0.8), Vector3(3.2, 2.5, -5.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(4.0, 1.6, 0.8), Vector3(0.0, 4.2, -5.0), SANDSTONE_DARK)

	# Metal double doors propped open with sniper slit
	ArenaKit.box(geometry, Vector3(1.6, 3.4, 0.15), Vector3(-1.1, 1.7, -5.3), METAL_DOOR, Vector3(0.0, 26.0, 0.0), ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(1.6, 3.4, 0.15), Vector3(1.1, 1.7, -5.3), METAL_DOOR, Vector3(0.0, -26.0, 0.0), ArenaKit.SurfaceType.METAL)

	# --- Lower Mid (North of Mid Doors, sloping down from Z = -6.0 to -16.0) ---
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 12.0), Vector3(-1.0, -0.15, -11.0), PAVER)

	# Truck obstacle in Lower Mid (at X = -4.0, Z = -12.0)
	ArenaKit.box(geometry, Vector3(2.4, 1.6, 4.6), Vector3(-4.0, 0.8, -12.0), CAR_BLUE, Vector3(0.0, 20.0, 0.0), ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-2.2, 0.7, -13.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# CT Boost box in Lower Mid (X = 3.0, Z = -10.0)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(3.0, 0.7, -10.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_catwalk_short_and_site_a() -> void:
	# --- Catwalk (Elevated walkway Y = 1.8 running along East Mid from Z = 4.0 to -12.0) ---
	var cat_w := 3.6
	# Ramp up to Catwalk from Top Mid (Z = 6.0 to 2.0)
	ArenaKit.ramp(geometry, Vector3(6.5, 0.0, 6.0), Vector3(6.5, 1.8, 2.0), cat_w, SANDSTONE)
	# Main Catwalk platform
	ArenaKit.box(geometry, Vector3(cat_w, 1.8, 14.0), Vector3(6.5, 0.9, -5.0), SANDSTONE)
	# Parapet stone ledge on Catwalk looking over Mid
	ArenaKit.box(geometry, Vector3(0.35, 0.9, 14.0), Vector3(6.5 - cat_w * 0.5 + 0.18, 2.25, -5.0), SANDSTONE_DARK)

	# --- Short A (Turns East from Catwalk at Z = -12.0 across X: 6.5 to 16.0) ---
	ArenaKit.box(geometry, Vector3(10.0, 1.8, 4.2), Vector3(11.5, 0.9, -12.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 4.5, 0.8), Vector3(11.5, 2.25, -14.5), SANDSTONE)

	# Short Boost crate
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(10.0, 2.5, -12.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# --- Bombsite A Platform (Raised Y = 1.8, centered at X = 20.0, Z = -18.0) ---
	var a_size := 14.0
	ArenaKit.box(geometry, Vector3(a_size, 1.8, a_size), Vector3(20.0, 0.9, -18.0), SANDSTONE)

	# Default plant crates on Site A
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(18.0, 2.6, -16.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(19.8, 2.55, -16.0), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(18.8, 4.1, -16.0), CRATE_WOOD, Vector3(0.0, -10.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# Goose corner at North-East back of Site A (X = 24.0, Z = -23.0)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(24.0, 2.6, -23.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Ninja hideout crate behind A ramp (X = 14.5, Z = -19.0)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(14.5, 2.55, -19.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_b_tunnels_and_site_b() -> void:
	# --- Upper B Tunnel (X: -26.0 to -20.0, Z: 18.0 to -2.0) ---
	var tun_w := 5.2
	var tun_l := 20.0
	# Tunnel floor
	ArenaKit.box(geometry, Vector3(tun_w, 0.3, tun_l), Vector3(-23.0, -0.15, 8.0), PAVER)
	# Tunnel walls
	ArenaKit.box(geometry, Vector3(0.8, 4.5, tun_l), Vector3(-23.0 - tun_w * 0.5 - 0.4, 2.25, 8.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, tun_l), Vector3(-23.0 + tun_w * 0.5 + 0.4, 2.25, 8.0), SANDSTONE)
	# Tunnel ceiling
	ArenaKit.box(geometry, Vector3(tun_w + 1.6, 0.6, tun_l), Vector3(-23.0, 4.8, 8.0), SANDSTONE_DARK)

	# --- Tunnel Stairs down to Lower Tunnel (at X = -17.0, Z = 1.0) ---
	ArenaKit.ramp(geometry, Vector3(-20.0, 0.0, 1.0), Vector3(-14.0, -1.5, 1.0), 3.8, SANDSTONE)

	# --- Lower Tunnel (X: -14.0 to -5.0, Z = 1.0, depth Y = -1.5) ---
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 3.8), Vector3(-9.0, -1.65, 1.0), PAVER)
	# Lower Tunnel ceiling
	ArenaKit.box(geometry, Vector3(10.0, 0.6, 5.0), Vector3(-9.0, 2.5, 1.0), SANDSTONE_DARK)
	# Ramp emerging from Lower Tunnel into Mid right beside Xbox
	ArenaKit.ramp(geometry, Vector3(-6.0, -1.5, 1.0), Vector3(-4.0, 0.0, 1.0), 3.8, SANDSTONE)

	# --- B Doors entrance into Site B (at X = -20.0, Z = -4.0) ---
	ArenaKit.box(geometry, Vector3(2.4, 4.5, 0.8), Vector3(-16.0, 2.25, -4.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.4, 4.5, 0.8), Vector3(-24.0, 2.25, -4.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(5.6, 1.5, 0.8), Vector3(-20.0, 3.75, -4.0), SANDSTONE_DARK)

	# Propped wooden B Doors
	ArenaKit.box(geometry, Vector3(1.3, 3.0, 0.15), Vector3(-18.5, 1.5, -4.3), CRATE_WOOD, Vector3(0.0, 28.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.3, 3.0, 0.15), Vector3(-21.5, 1.5, -4.3), CRATE_WOOD, Vector3(0.0, -28.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- Bombsite B Enclosure (centered at X = -24.0, Z = -16.0) ---
	# B Site Platform (raised Y = 1.0, X: -30.0 to -16.0, Z: -22.0 to -10.0)
	ArenaKit.box(geometry, Vector3(14.0, 1.0, 12.0), Vector3(-23.0, 0.5, -16.0), SANDSTONE)
	# Ramps up to B Platform from B Doors (South) and B Window (East)
	ArenaKit.ramp(geometry, Vector3(-21.0, 0.0, -7.0), Vector3(-21.0, 1.0, -10.0), 4.2, SANDSTONE)

	# Default plant crates at B Site
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-22.0, 1.8, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-23.8, 1.8, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-22.8, 3.3, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Barrels at B Site corner
	ArenaKit.cylinder(geometry, 0.45, 1.3, Vector3(-28.5, 1.65, -16.0), TRIM_BLUE, ArenaKit.SurfaceType.METAL)
	ArenaKit.cylinder(geometry, 0.45, 1.3, Vector3(-28.5, 1.65, -17.2), TRIM_BLUE, ArenaKit.SurfaceType.METAL)

	# Snipers Box (raised wooden platform at X = -28.0, Z = -21.0, Y = 2.4)
	ArenaKit.box(geometry, Vector3(3.2, 1.4, 3.2), Vector3(-28.0, 1.7, -20.5), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# B Car cover obstacle (X = -17.0, Z = -8.0)
	ArenaKit.box(geometry, Vector3(2.2, 1.4, 4.4), Vector3(-17.0, 0.7, -8.0), CAR_BLUE, Vector3(0.0, -15.0, 0.0), ArenaKit.SurfaceType.METAL)

	# B Window looking out into CT Spawn (raised opening at X = -14.0, Z = -16.0)
	ArenaKit.box(geometry, Vector3(0.8, 1.4, 3.2), Vector3(-14.0, 0.7, -16.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 1.6, 3.2), Vector3(-14.0, 3.7, -16.0), SANDSTONE_DARK)

	# B Doors to CT Spawn (double doors at X = -14.0, Z = -10.0)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.2), Vector3(-14.0, 2.25, -12.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.2), Vector3(-14.0, 2.25, -8.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 1.5, 3.2), Vector3(-14.0, 3.75, -10.0), SANDSTONE_DARK)


func _build_ct_spawn() -> void:
	# --- CT Spawn (North-Central: X = 4.0, Z = -24.0) ---
	ArenaKit.box(geometry, Vector3(16.0, 0.3, 10.0), Vector3(4.0, -0.15, -24.0), PAVER)
	# Stone curb framing the CT Spawn terrace towards Lower Mid
	ArenaKit.box(geometry, Vector3(16.0, 0.06, 0.4), Vector3(4.0, 0.03, -19.0), SANDSTONE_DARK)

	# Tactical crates and equipment in CT Spawn
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 1.8), Vector3(2.0, 0.9, -26.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(4.0, 0.8, -26.0), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(3.0, 2.45, -26.0), CRATE_WOOD, Vector3(0.0, -8.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# CT Spawn connects:
	# - West directly towards B Window and B Doors (Z = -16 to -10)
	# - South directly down Lower Mid toward Mid Doors
	# - East directly under A Ramp / up toward Site A


func _build_spawns_and_objectives() -> void:
	# Team bases: Team 0 (CT / Blue) at North, Team 1 (T / Orange) at South
	team_bases.clear()
	team_bases.append(Vector3(4.0, 0.0, -24.0))  # CT Spawn
	team_bases.append(Vector3(0.0, 0.0, 34.0))   # T Spawn

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(20.0, 1.8, -18.0)) # Blue Flag on Site A Platform
	flag_pedestals.append(Vector3(0.0, 0.0, 34.0))    # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(20.0, 1.8, -18.0) # Site A (Elevated Terrace Platform)
	bomb_sites["B"] = Vector3(-22.0, 1.0, -15.0) # Site B (B Platform)
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(0.0, 0.0, 32.0))

	# Player / Bot Spawns (CT vs T)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(-2.0, 0.0, -22.0), Vector3(4.0, 0.0, -22.0), Vector3(10.0, 0.0, -22.0),
		Vector3(-2.0, 0.0, -26.0), Vector3(1.0, 0.0, -26.0), Vector3(7.0, 0.0, -26.0),
	]
	var t_spawns := [
		Vector3(-6.0, 0.0, 32.0), Vector3(0.0, 0.0, 32.0), Vector3(6.0, 0.0, 32.0),
		Vector3(-3.0, 0.0, 36.0), Vector3(3.0, 0.0, 36.0), Vector3(8.0, 0.0, 36.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in t_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Tactical Roam Points across the iconic de_dust2 callouts
	roam_points.append(Vector3(0.0, 0.0, 34.0))    # T Spawn
	roam_points.append(Vector3(0.0, 0.0, 20.0))    # Suicide
	roam_points.append(Vector3(-24.0, 0.0, 20.0))  # Outside Tunnel
	roam_points.append(Vector3(-23.0, 0.0, 8.0))   # Upper B Tunnel
	roam_points.append(Vector3(-9.0, -1.5, 1.0))   # Lower Tunnel
	roam_points.append(Vector3(0.0, 0.0, 6.0))     # Top Mid
	roam_points.append(Vector3(2.8, 1.8, 0.0))     # Xbox
	roam_points.append(Vector3(0.0, 0.0, -2.0))    # Mid Doors
	roam_points.append(Vector3(-1.0, 0.0, -11.0))  # Lower Mid / Truck
	roam_points.append(Vector3(4.0, 0.0, -24.0))   # CT Spawn
	roam_points.append(Vector3(6.5, 1.8, -5.0))    # Catwalk
	roam_points.append(Vector3(11.5, 1.8, -12.0))  # Short A
	roam_points.append(Vector3(20.0, 1.8, -18.0))  # Site A
	roam_points.append(Vector3(24.0, 1.8, -23.0))  # Goose
	roam_points.append(Vector3(24.0, 0.0, -10.0))  # A Ramp
	roam_points.append(Vector3(26.0, 0.0, -2.0))   # A Long / A Car
	roam_points.append(Vector3(29.0, -1.6, 10.0))  # Pit
	roam_points.append(Vector3(20.0, 0.0, 14.0))   # Long Doors
	roam_points.append(Vector3(18.0, 0.0, 20.0))   # TAXI
	roam_points.append(Vector3(-20.0, 0.0, -4.0))  # B Doors approach
	roam_points.append(Vector3(-22.0, 1.0, -15.0)) # Site B Platform
	roam_points.append(Vector3(-14.0, 0.0, -16.0)) # B Window drop

	# Power-up Spot (Dead-center of Mid Doors)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, -2.0))

	# Tactical Ammo Buckets
	add_bucket(Vector3(18.0, 0.0, 18.0), Color(0.95, 0.45, 0.15))  # Long Doors approach
	add_bucket(Vector3(-24.0, 0.0, 16.0), Color(0.95, 0.45, 0.15)) # Upper B Tunnel
	add_bucket(Vector3(20.0, 1.8, -22.0), Color(0.2, 0.5, 0.95))   # Site A
	add_bucket(Vector3(-24.0, 1.0, -18.0), Color(0.2, 0.5, 0.95))  # Site B Platform
	add_bucket(Vector3(4.0, 0.0, -28.0), Color(0.2, 0.5, 0.95))    # CT Spawn

	# Tactical Foam Shield Pickup on Catwalk beside Xbox
	var shield := ShieldPickup.new()
	shield.position = Vector3(6.5, 2.6, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
