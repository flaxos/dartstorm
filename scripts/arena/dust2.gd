class_name Dust2
extends Arena
## DUSTSTORM II: Faithfully reconstructed after Counter-Strike's iconic de_dust2.
## Designed strictly according to Valve & Dave Johnston's canonical layout and Hammer scale:
##   - T-Spawn & Suicide: Elevated staging terrace with sunken Suicide ramp giving direct sniper peek to Mid Doors
##   - Outside Long & Long House: Two-gate gatehouse with outer/inner arches leading into A Long
##   - Pit & Pit Plat: Sunken rectangular Pit basin (Y = -1.6m) with elevated Pit Plat sniper ledge and exit ramp
##   - A Long, A Car & A Cross: Wide straightway leading to A Ramp and exposed crossing to CT Spawn
##   - Bombsite A & CT Ramp: Elevated terrace (Y = 1.8m) with Default crates, Goose, Ninja, and wide CT Ramp to CT Spawn
##   - Catwalk & Short A: Top Mid stairs rising to elevated Catwalk (Y = 1.8m), stone parapet, and Short Boost
##   - Mid Doors & Lower Mid: Curved arch with propped metal double doors (sniper slit) sloping to Lower Mid
##   - B Tunnels: Outside Tunnel, Upper B Tunnel, Tunnel Stairs to Lower Tunnel (emerging beside Xbox)
##   - Bombsite B: Upper Tunnel exit onto raised B Platform (Y = 1.0m), sunken B site floor (Y = 0.0),
##     central Big Box plant crates, elevated B Window with hop crates, and B Double Doors
##   - CT Spawn: Sunken central compound (Y = -0.5m) seamlessly linking Lower Mid, B Doors, and CT Ramp to Site A

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
	# Continuous infinite background desert floor (placed deep at Y = -3.5 so it never clips into trenches)
	ArenaKit.deco_box(decor, Vector3(500.0, 0.2, 500.0), Vector3(0.0, -3.55, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# Safety bedrock base floor underneath entire map (at Y = -3.5)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -4.0, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# --- Segmented Ground Slabs at Y = 0.0 (Preserving Pit, Suicide, and CT Spawn depth!) ---
	# 1. West Ground (West of Suicide / Mid, south of CT Spawn): X: -44.0 to -2.5, Z: -15.0 to 44.0
	ArenaKit.box(geometry, Vector3(41.5, 1.0, 59.0), Vector3(-23.25, -0.5, 14.5), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 2. Far West North Ground (behind Site B, west of CT Spawn): X: -44.0 to -9.0, Z: -44.0 to -15.0
	ArenaKit.box(geometry, Vector3(35.0, 1.0, 29.0), Vector3(-26.5, -0.5, -29.5), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 3. East Ground (Between Suicide/Mid and Pit): X: 2.5 to 25.5, Z: -15.0 to 44.0
	ArenaKit.box(geometry, Vector3(23.0, 1.0, 59.0), Vector3(14.0, -0.5, 14.5), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 4. Far East Boundary Ground (East of Pit): X: 34.5 to 44.0, Z: -44.0 to 44.0
	ArenaKit.box(geometry, Vector3(9.5, 1.0, 88.0), Vector3(39.25, -0.5, 0.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 5. North-East Ground (Bombsite A terrace & A Long North, east of CT Spawn): X: 9.0 to 34.5, Z: -44.0 to 4.0
	ArenaKit.box(geometry, Vector3(25.5, 1.0, 48.0), Vector3(21.75, -0.5, -20.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 6. Outside Long & Outside Pit South Ground (South of Pit): X: 25.5 to 34.5, Z: 14.0 to 44.0
	ArenaKit.box(geometry, Vector3(9.0, 1.0, 30.0), Vector3(30.0, -0.5, 29.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 7. T-Spawn South Ground (Behind Suicide start): X: -2.5 to 2.5, Z: 30.0 to 44.0
	ArenaKit.box(geometry, Vector3(5.0, 1.0, 14.0), Vector3(0.0, -0.5, 37.0), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# 8. Top Mid Ground (North of Suicide): X: -2.5 to 2.5, Z: -15.0 to 12.0
	ArenaKit.box(geometry, Vector3(5.0, 1.0, 27.0), Vector3(0.0, -0.5, -1.5), DESERT_SAND, Vector3.ZERO, ArenaKit.SurfaceType.SAND)

	# Boundary fortress canyon walls with architectural coping cornices
	var wall_h := 7.5
	var thick := 1.4
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)

	# Decorative coping trim along canyon wall tops
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, -HALF_Z), Vector3(HALF_X * 2.0 + 0.6, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, HALF_Z), Vector3(HALF_X * 2.0 + 0.6, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(-HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.6))
	ArenaKit.cornice(decor, Vector3(HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.6))


func _build_t_spawn_and_approaches() -> void:
	# --- T-Spawn Plaza (South: X: -12 to 12, Z: 30 to 42, Y = 0.0) ---
	ArenaKit.box(geometry, Vector3(24.0, 0.3, 12.0), Vector3(0.0, -0.15, 36.0), PAVER)
	ArenaKit.box(geometry, Vector3(24.0, 0.06, 0.4), Vector3(0.0, 0.03, 30.0), SANDSTONE_DARK)

	# Staging equipment at T Spawn
	ArenaKit.pallet(geometry, Vector3(-4.0, 0.0, 37.0))
	ArenaKit.crate(geometry, Vector3(-4.0, 0.20, 37.0), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, Vector3(-2.0, 0.0, 37.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 15.0, 0.0))
	ArenaKit.crate(geometry, Vector3(3.0, 0.0, 36.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, -10.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(5.5, 0.0, 38.0))
	ArenaKit.urn(decor, Vector3(7.0, 0.0, 38.0), 1.2)
	ArenaKit.urn(decor, Vector3(-7.5, 0.0, 37.0), 1.1)

	# --- Suicide (Iconic Sunken Sniper Ramp leading straight North into Mid) ---
	# Drops from T-Spawn (Y = 0.0) down to Y = -1.0 (Z = 30.0 to 16.0)
	var sui_w := 4.4
	ArenaKit.ramp(geometry, Vector3(0.0, 0.0, 30.0), Vector3(0.0, -1.0, 16.0), sui_w, SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 6.0, 14.0), Vector3(-sui_w * 0.5 - 0.4, 1.5, 23.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 6.0, 14.0), Vector3(sui_w * 0.5 + 0.4, 1.5, 23.0), SANDSTONE)

	# Ramp emerging from Suicide into Top Mid (Y = -1.0 to 0.0, Z = 16.0 to 12.0)
	ArenaKit.ramp(geometry, Vector3(0.0, -1.0, 16.0), Vector3(0.0, 0.0, 12.0), sui_w, SANDSTONE)

	# --- T-Ramp & Outside Tunnel (West approach towards B Tunnels) ---
	# Corridor from T Spawn West (X: -12.0 to -24.0, Z = 28.0)
	ArenaKit.box(geometry, Vector3(14.0, 0.3, 6.0), Vector3(-18.0, -0.15, 28.0), PAVER)
	ArenaKit.box(geometry, Vector3(14.0, 5.0, 0.8), Vector3(-18.0, 2.5, 31.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 5.0, 0.8), Vector3(-16.0, 2.5, 24.5), SANDSTONE)

	# Outside Tunnel Turn (X = -24.0, Z: 28.0 to 18.0)
	ArenaKit.box(geometry, Vector3(6.0, 0.3, 10.0), Vector3(-24.0, -0.15, 23.0), PAVER)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 12.0), Vector3(-27.5, 2.5, 22.0), SANDSTONE)
	ArenaKit.pallet(geometry, Vector3(-24.0, 0.0, 24.0))
	ArenaKit.crate(geometry, Vector3(-24.0, 0.20, 24.0), Vector3(1.6, 1.6, 1.6))

	# --- TAXI & Outside Long approach (East approach towards Long Doors) ---
	# Corridor from T Spawn East (X: 12.0 to 22.0, Z = 28.0)
	ArenaKit.box(geometry, Vector3(14.0, 0.3, 6.0), Vector3(18.0, -0.15, 28.0), PAVER)
	ArenaKit.box(geometry, Vector3(14.0, 5.0, 0.8), Vector3(18.0, 2.5, 31.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 5.0, 0.8), Vector3(16.0, 2.5, 24.5), SANDSTONE)

	# Outside Long Open Square with TAXI obstacle (at X = 20.0, Z = 20.0)
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 10.0), Vector3(20.0, -0.15, 20.0), PAVER)
	ArenaKit.barrier(geometry, Vector3(18.0, 0.0, 20.0), Vector3(0.0, 20.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(19.5, 0.0, 21.5))


func _build_long_a_and_pit() -> void:
	# --- The Long House (Two-Gate Gatehouse at X = 20.0, Z = 11.0 to 17.0) ---
	var house_w := 5.2
	var house_len := 6.0
	# Gatehouse floor
	ArenaKit.box(geometry, Vector3(house_w, 0.3, house_len), Vector3(20.0, -0.15, 14.0), PAVER)
	# Gatehouse side walls
	ArenaKit.box(geometry, Vector3(0.9, 5.5, house_len), Vector3(20.0 - house_w * 0.5 - 0.45, 2.75, 14.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.9, 5.5, house_len), Vector3(20.0 + house_w * 0.5 + 0.45, 2.75, 14.0), SANDSTONE)
	# Gatehouse roof
	ArenaKit.box(geometry, Vector3(house_w + 1.8, 0.6, house_len), Vector3(20.0, 5.8, 14.0), SANDSTONE_DARK)

	# Gate 1: Outer Curved Arch (South entrance from Outside Long at Z = 17.0)
	ArenaKit.arch(geometry, Vector3(20.0, 0.0, 17.0), house_w, 5.2, 1.2)
	# Propped wooden outer doors
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.3), Vector3(19.5, 1.7, 17.0 - 1.2), CRATE_WOOD, Vector3(0.0, 30.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.3), Vector3(19.5, 1.7, 17.0 + 1.2), CRATE_WOOD, Vector3(0.0, -30.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# Gate 2: Inner Curved Arch (North exit spilling onto A Long at Z = 11.0)
	ArenaKit.arch(geometry, Vector3(20.0, 0.0, 11.0), house_w, 5.2, 1.2)
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.3), Vector3(19.5, 1.7, 11.0 - 1.2), CRATE_WOOD, Vector3(0.0, -30.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 3.4, 1.3), Vector3(19.5, 1.7, 11.0 + 1.2), CRATE_WOOD, Vector3(0.0, 30.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- Blue Box (outside Long Doors at X = 15.0, Z = 8.0) ---
	ArenaKit.box(geometry, Vector3(2.4, 2.2, 4.8), Vector3(15.0, 1.1, 8.0), TRIM_BLUE, Vector3.ZERO, ArenaKit.SurfaceType.METAL)

	# --- Long Pit & Pit Plat (Sunken depression at X: 26 to 36, Z: 4 to 14, depth Y = -1.6) ---
	var pit_w := 9.0
	var pit_l := 10.0
	var pit_pos := Vector3(30.0, -1.8, 9.0)
	ArenaKit.box(geometry, Vector3(pit_w, 0.4, pit_l), pit_pos, PAVER)

	# Pit retaining walls (enclosing South, East, West, and North of Pit)
	ArenaKit.box(geometry, Vector3(pit_w + 1.6, 2.2, 0.8), Vector3(30.0, -0.5, 14.4), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 2.2, pit_l + 1.6), Vector3(34.9, -0.5, 9.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 2.2, pit_l), Vector3(25.1, -0.5, 9.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(4.2, 2.2, 0.8), Vector3(32.6, -0.5, 4.0), SANDSTONE)

	# Smooth carved stone coping trim along Pit rim
	ArenaKit.cornice(decor, Vector3(30.0, 0.7, 14.4), Vector3(pit_w + 1.6, 0.25, 1.2))
	ArenaKit.cornice(decor, Vector3(34.9, 0.7, 9.0), Vector3(1.2, 0.25, pit_l + 1.6))
	ArenaKit.cornice(decor, Vector3(25.1, 0.7, 9.0), Vector3(1.2, 0.25, pit_l))
	ArenaKit.cornice(decor, Vector3(32.6, 0.7, 4.0), Vector3(4.2, 0.25, 1.2))

	# Pit Plat (Elevated sniper ledge in Pit corner at X = 33.0, Z = 12.0, Y = 0.0)
	ArenaKit.box(geometry, Vector3(3.2, 1.6, 3.2), Vector3(33.0, -0.8, 12.0), SANDSTONE)
	ArenaKit.crate(geometry, Vector3(33.0, 0.0, 12.0), Vector3(1.4, 1.4, 1.4))

	# Ramp emerging from Pit heading North onto A Long
	ArenaKit.ramp(geometry, Vector3(28.0, -1.6, 5.0), Vector3(28.0, 0.0, 1.0), 5.5, SANDSTONE)

	# Pit barrels and decorative pottery urn
	ArenaKit.barrel(geometry, Vector3(28.0, -1.6, 11.0))
	ArenaKit.barrel(geometry, Vector3(29.2, -1.6, 11.8))
	ArenaKit.urn(decor, Vector3(31.5, -1.6, 13.0), 1.15)

	# --- A Long Straightway (X = 26.0, Z from 2.0 down to -8.0) ---
	var long_w := 8.4
	ArenaKit.box(geometry, Vector3(long_w, 0.3, 12.0), Vector3(26.0, -0.15, -3.0), SANDSTONE)
	# Wall separating A Long from Mid/Catwalk
	ArenaKit.box(geometry, Vector3(0.9, 5.5, 26.0), Vector3(20.0, 2.75, -3.0), SANDSTONE)
	# Market awning along A Long wall
	ArenaKit.awning(decor, Vector3(20.5, 3.6, -3.0), 4.2, Vector3(0.0, 90.0, 0.0))

	# A Car (vehicle obstacle / crate cover on A Long at X = 28.0, Z = -4.0)
	ArenaKit.barrier(geometry, Vector3(28.0, 0.0, -4.0), Vector3(0.0, -15.0, 0.0))
	ArenaKit.crate(geometry, Vector3(26.0, 0.0, -4.0), Vector3(1.5, 1.5, 1.5))
	ArenaKit.barrel(geometry, Vector3(29.5, 0.0, -2.5))

	# --- A Ramp (rising up onto Site A: Y = 0.0 to Y = 1.8 between Z = -8.0 and Z = -14.0) ---
	ArenaKit.ramp(geometry, Vector3(24.0, 0.0, -8.0), Vector3(24.0, 1.8, -14.0), 6.5, SANDSTONE)


func _build_mid_and_doors() -> void:
	# --- Top Mid & Mid Avenue (X: -4.0 to 4.0, Z: 12.0 down to -4.0) ---
	var mid_w := 8.4
	ArenaKit.box(geometry, Vector3(mid_w, 0.3, 16.0), Vector3(0.0, -0.15, 4.0), PAVER)

	# West wall of Mid (separating Mid from B Tunnels)
	ArenaKit.box(geometry, Vector3(0.9, 5.5, 24.0), Vector3(-5.0, 2.75, 4.0), SANDSTONE)

	# Top Mid barrels & pallet
	ArenaKit.barrel(geometry, Vector3(-3.5, 0.0, 12.0))
	ArenaKit.barrel(geometry, Vector3(-4.2, 0.0, 12.6))
	ArenaKit.pallet(geometry, Vector3(3.2, 0.0, 8.0))

	# --- X-Box (The iconic jump crate at X = 2.8, Z = 0.0) ---
	# High-poly stylized crate stack allowing players to jump up to Catwalk!
	ArenaKit.crate(geometry, Vector3(2.8, 0.0, 0.0), Vector3(2.2, 1.8, 2.2))
	ArenaKit.crate(geometry, Vector3(2.8, 0.0, 1.8), Vector3(1.2, 0.9, 1.2))

	# --- Mid Double Doors (at Z = -4.0, X = 0.0) ---
	# Heavy stone doorway with high-poly curved arch
	ArenaKit.box(geometry, Vector3(2.6, 5.2, 0.9), Vector3(-3.2, 2.6, -4.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.6, 5.2, 0.9), Vector3(3.2, 2.6, -4.0), SANDSTONE_DARK)
	ArenaKit.arch(geometry, Vector3(0.0, 0.0, -4.0), 4.4, 5.0, 1.2)

	# Metal double doors propped open with sniper slit
	ArenaKit.box(geometry, Vector3(1.6, 3.4, 0.15), Vector3(-1.1, 1.7, -4.3), METAL_DOOR, Vector3(0.0, 26.0, 0.0), ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(1.6, 3.4, 0.15), Vector3(1.1, 1.7, -4.3), METAL_DOOR, Vector3(0.0, -26.0, 0.0), ArenaKit.SurfaceType.METAL)

	# --- Lower Mid (North of Mid Doors, sloping down from Z = -5.0 to -16.0) ---
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 12.0), Vector3(-1.0, -0.15, -10.0), PAVER)

	# Truck / Barricade obstacle in Lower Mid (at X = -4.0, Z = -11.0)
	ArenaKit.barrier(geometry, Vector3(-4.0, 0.0, -11.0), Vector3(0.0, 20.0, 0.0))
	ArenaKit.crate(geometry, Vector3(-2.2, 0.0, -12.0), Vector3(1.5, 1.5, 1.5))
	ArenaKit.barrel(geometry, Vector3(-4.2, 0.0, -8.5))


func _build_catwalk_short_and_site_a() -> void:
	# --- Catwalk (Elevated walkway Y = 1.8 running along East Mid from Z = 4.0 to -10.0) ---
	var cat_w := 3.8
	# Wide stone stairs up to Catwalk from Top Mid (Z = 6.0 to 1.0)
	ArenaKit.ramp(geometry, Vector3(6.5, 0.0, 6.0), Vector3(6.5, 1.8, 1.0), cat_w, SANDSTONE)
	# Main Catwalk platform
	ArenaKit.box(geometry, Vector3(cat_w, 1.8, 12.0), Vector3(6.5, 0.9, -5.0), SANDSTONE)
	# Parapet stone ledge on Catwalk looking over Mid
	ArenaKit.box(geometry, Vector3(0.35, 0.9, 12.0), Vector3(6.5 - cat_w * 0.5 + 0.18, 2.25, -5.0), SANDSTONE_DARK)

	# --- Short A (Turns East from Catwalk at Z = -11.0 across X: 6.5 to 16.0) ---
	ArenaKit.box(geometry, Vector3(10.0, 1.8, 4.4), Vector3(11.5, 0.9, -11.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 4.5, 0.8), Vector3(11.5, 2.25, -13.6), SANDSTONE)

	# Short Boost crate
	ArenaKit.crate(geometry, Vector3(10.0, 1.8, -11.0), Vector3(1.4, 1.4, 1.4))

	# --- Bombsite A Platform (Raised Y = 1.8, centered at X = 20.0, Z = -18.0) ---
	var a_size := 14.0
	ArenaKit.box(geometry, Vector3(a_size, 1.8, a_size), Vector3(20.0, 0.9, -18.0), SANDSTONE)

	# Default plant crates on Site A (High-Poly)
	ArenaKit.crate(geometry, Vector3(18.0, 1.8, -16.0), Vector3(1.6, 1.6, 1.6))
	ArenaKit.crate(geometry, Vector3(19.8, 1.8, -16.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, 15.0, 0.0))
	ArenaKit.crate(geometry, Vector3(18.8, 3.4, -16.0), Vector3(1.4, 1.4, 1.4), Vector3(0.0, -10.0, 0.0))

	# Goose corner at North-East back of Site A (X = 24.0, Z = -23.0)
	ArenaKit.crate(geometry, Vector3(24.0, 1.8, -23.0), Vector3(1.6, 1.6, 1.6))
	ArenaKit.barrel(geometry, Vector3(25.5, 1.8, -23.0))

	# Ninja hideout crate behind A ramp (X = 14.5, Z = -19.0)
	ArenaKit.crate(geometry, Vector3(14.5, 1.8, -19.0), Vector3(1.5, 1.5, 1.5))

	# Decorative barrels and urns on Site A
	ArenaKit.barrel(geometry, Vector3(24.0, 1.8, -14.0))
	ArenaKit.urn(decor, Vector3(26.0, 1.8, -20.0), 1.15)

	# --- The Authentic CT Ramp (connecting Site A directly down to CT Spawn) ---
	# Slopes down from Site A (Y = 1.8, X = 13.0, Z = -20.0) to CT Spawn (Y = -0.5, X = 7.0, Z = -20.0)
	ArenaKit.ramp(geometry, Vector3(13.0, 1.8, -20.0), Vector3(6.0, -0.5, -20.0), 5.5, SANDSTONE)


func _build_b_tunnels_and_site_b() -> void:
	# --- Upper B Tunnel (X: -26.0 to -20.0, Z: 18.0 to -2.0) ---
	var tun_w := 5.4
	var tun_l := 20.0
	# Tunnel floor
	ArenaKit.box(geometry, Vector3(tun_w, 0.3, tun_l), Vector3(-23.0, -0.15, 8.0), PAVER)
	# Tunnel walls
	ArenaKit.box(geometry, Vector3(0.9, 4.5, tun_l), Vector3(-23.0 - tun_w * 0.5 - 0.45, 2.25, 8.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.9, 4.5, tun_l), Vector3(-23.0 + tun_w * 0.5 + 0.45, 2.25, 8.0), SANDSTONE)
	# Tunnel ceiling
	ArenaKit.box(geometry, Vector3(tun_w + 1.8, 0.6, tun_l), Vector3(-23.0, 4.8, 8.0), SANDSTONE_DARK)

	# --- Tunnel Stairs down to Lower Tunnel (at X = -17.0, Z = 1.0) ---
	ArenaKit.ramp(geometry, Vector3(-20.0, 0.0, 1.0), Vector3(-14.0, -1.5, 1.0), 4.0, SANDSTONE)

	# --- Lower Tunnel (X: -14.0 to -5.0, Z = 1.0, depth Y = -1.5) ---
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 4.0), Vector3(-9.0, -1.65, 1.0), PAVER)
	ArenaKit.box(geometry, Vector3(10.0, 0.6, 5.2), Vector3(-9.0, 2.5, 1.0), SANDSTONE_DARK)
	# Ramp emerging from Lower Tunnel into Mid right beside Xbox
	ArenaKit.ramp(geometry, Vector3(-6.0, -1.5, 1.0), Vector3(-4.0, 0.0, 1.0), 4.0, SANDSTONE)

	# --- Upper Tunnel Exit Portal onto B Platform (at X = -23.0, Z = -2.0) ---
	ArenaKit.arch(geometry, Vector3(-23.0, 0.0, -2.0), tun_w, 4.6, 1.2)

	# --- Bombsite B Enclosure (centered at X = -24.0, Z = -16.0) ---
	# B Site Platform (raised Y = 1.0, along North and West walls: X: -30.0 to -16.0, Z: -24.0 to -10.0)
	ArenaKit.box(geometry, Vector3(6.0, 1.0, 14.0), Vector3(-27.0, 0.5, -17.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(14.0, 1.0, 5.0), Vector3(-23.0, 0.5, -21.5), SANDSTONE)

	# Ramps down from B Platform to sunken B Site floor (Y = 0.0)
	ArenaKit.ramp(geometry, Vector3(-24.0, 1.0, -10.0), Vector3(-24.0, 0.0, -7.0), 4.2, SANDSTONE)
	ArenaKit.ramp(geometry, Vector3(-24.0, 1.0, -19.0), Vector3(-24.0, 0.0, -16.0), 4.2, SANDSTONE)

	# Sunken B Site Floor (Y = 0.0, X: -24 to -16, Z: -18 to -10)
	ArenaKit.box(geometry, Vector3(10.0, 0.3, 10.0), Vector3(-20.0, -0.15, -14.0), PAVER)

	# High-poly Default plant crates at B Site (The "Big Box" stack)
	ArenaKit.pallet(geometry, Vector3(-20.0, 0.0, -14.0))
	ArenaKit.crate(geometry, Vector3(-20.0, 0.20, -14.0), Vector3(2.0, 1.8, 2.0))
	ArenaKit.crate(geometry, Vector3(-21.8, 0.0, -14.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 12.0, 0.0))
	ArenaKit.crate(geometry, Vector3(-20.8, 1.8, -14.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, -8.0, 0.0))

	# High-poly ribbed Barrels at B Site corner
	ArenaKit.barrel(geometry, Vector3(-28.5, 1.0, -16.0))
	ArenaKit.barrel(geometry, Vector3(-28.5, 1.0, -17.4))
	ArenaKit.urn(decor, Vector3(-28.8, 1.0, -14.6), 1.1)

	# Snipers Box on B Back Platform
	ArenaKit.pallet(geometry, Vector3(-28.0, 1.0, -21.5))
	ArenaKit.crate(geometry, Vector3(-28.0, 1.2, -21.5), Vector3(2.0, 1.8, 2.0))

	# Market awning on Site B back wall
	ArenaKit.awning(decor, Vector3(-25.0, 3.6, -23.5), 4.0)

	# B Car / barrier cover obstacle near tunnel mouth (X = -17.0, Z = -7.0)
	ArenaKit.barrier(geometry, Vector3(-17.0, 0.0, -7.0), Vector3(0.0, -15.0, 0.0))

	# B Window looking out into CT Spawn (raised opening at X = -14.0, Z = -16.0, Y = 1.2)
	ArenaKit.box(geometry, Vector3(0.8, 1.2, 3.4), Vector3(-14.0, 0.6, -16.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 1.6, 3.4), Vector3(-14.0, 3.8, -16.0), SANDSTONE_DARK)
	# Hop crate underneath B Window for mantling
	ArenaKit.crate(geometry, Vector3(-15.2, 0.0, -16.0), Vector3(1.2, 1.0, 1.2))
	ArenaKit.crate(geometry, Vector3(-12.8, -0.5, -16.0), Vector3(1.2, 1.0, 1.2))

	# B Double Doors to CT Spawn (double doors at X = -14.0, Z = -9.0)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.2), Vector3(-14.0, 2.25, -11.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.2), Vector3(-14.0, 2.25, -6.5), SANDSTONE)
	ArenaKit.arch(geometry, Vector3(-14.0, 0.0, -9.0), 3.8, 4.5, 1.2, Vector3(0.0, 90.0, 0.0))
	ArenaKit.box(geometry, Vector3(0.15, 3.0, 1.3), Vector3(-14.0, 1.5, -7.8), CRATE_WOOD, Vector3(0.0, 28.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.15, 3.0, 1.3), Vector3(-14.0, 1.5, -10.2), CRATE_WOOD, Vector3(0.0, -28.0, 0.0), ArenaKit.SurfaceType.WOOD)


func _build_ct_spawn() -> void:
	# --- CT Spawn (Sunken North-Central Compound: X = 2.0, Z = -22.0, Y = -0.5) ---
	ArenaKit.box(geometry, Vector3(18.0, 0.3, 14.0), Vector3(0.0, -0.65, -22.0), PAVER)
	ArenaKit.box(geometry, Vector3(18.0, 0.06, 0.4), Vector3(0.0, -0.47, -15.0), SANDSTONE_DARK)

	# Tactical crates and equipment in CT Spawn
	ArenaKit.pallet(geometry, Vector3(0.0, -0.5, -25.0))
	ArenaKit.crate(geometry, Vector3(0.0, -0.30, -25.0), Vector3(1.8, 1.8, 1.8))
	ArenaKit.crate(geometry, Vector3(2.0, -0.5, -25.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 15.0, 0.0))
	ArenaKit.barrel(geometry, Vector3(-2.2, -0.5, -25.0))
	ArenaKit.urn(decor, Vector3(4.5, -0.5, -26.0), 1.2)


func _build_spawns_and_objectives() -> void:
	# Team bases: Team 0 (CT / Blue) at North, Team 1 (T / Orange) at South
	team_bases.clear()
	team_bases.append(Vector3(0.0, -0.5, -22.0))  # CT Spawn
	team_bases.append(Vector3(0.0, 0.0, 36.0))    # T Spawn

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(20.0, 1.8, -18.0)) # Blue Flag on Site A Platform
	flag_pedestals.append(Vector3(0.0, 0.0, 36.0))    # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(20.0, 1.8, -18.0) # Site A (Elevated Terrace Platform)
	bomb_sites["B"] = Vector3(-20.0, 0.0, -14.0) # Site B (Sunken B Site Floor)
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(0.0, 0.0, 34.0))

	# Player / Bot Spawns (CT vs T)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(-4.0, -0.5, -20.0), Vector3(2.0, -0.5, -20.0), Vector3(6.0, -0.5, -20.0),
		Vector3(-4.0, -0.5, -24.0), Vector3(1.0, -0.5, -24.0), Vector3(6.0, -0.5, -24.0),
	]
	var t_spawns := [
		Vector3(-6.0, 0.0, 34.0), Vector3(0.0, 0.0, 34.0), Vector3(6.0, 0.0, 34.0),
		Vector3(-4.0, 0.0, 38.0), Vector3(2.0, 0.0, 38.0), Vector3(7.0, 0.0, 38.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in t_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Tactical Roam Points across the iconic de_dust2 callouts
	roam_points.append(Vector3(0.0, 0.0, 36.0))    # T Spawn
	roam_points.append(Vector3(0.0, -1.0, 20.0))   # Suicide
	roam_points.append(Vector3(-24.0, 0.0, 22.0))  # Outside Tunnel
	roam_points.append(Vector3(-23.0, 0.0, 8.0))   # Upper B Tunnel
	roam_points.append(Vector3(-9.0, -1.5, 1.0))   # Lower Tunnel
	roam_points.append(Vector3(0.0, 0.0, 6.0))     # Top Mid
	roam_points.append(Vector3(2.8, 1.8, 0.0))     # Xbox
	roam_points.append(Vector3(0.0, 0.0, -2.0))    # Mid Doors
	roam_points.append(Vector3(-1.0, 0.0, -10.0))  # Lower Mid / Truck
	roam_points.append(Vector3(0.0, -0.5, -22.0))  # CT Spawn
	roam_points.append(Vector3(6.5, 1.8, -5.0))    # Catwalk
	roam_points.append(Vector3(11.5, 1.8, -11.0))  # Short A
	roam_points.append(Vector3(20.0, 1.8, -18.0))  # Site A
	roam_points.append(Vector3(24.0, 1.8, -23.0))  # Goose
	roam_points.append(Vector3(24.0, 0.0, -8.0))   # A Ramp
	roam_points.append(Vector3(26.0, 0.0, -3.0))   # A Long / A Car
	roam_points.append(Vector3(30.0, -1.6, 9.0))   # Pit
	roam_points.append(Vector3(20.0, 0.0, 14.0))   # Long House
	roam_points.append(Vector3(20.0, 0.0, 20.0))   # Outside Long
	roam_points.append(Vector3(-14.0, 0.0, -9.0))  # B Doors approach
	roam_points.append(Vector3(-27.0, 1.0, -17.0)) # B Platform
	roam_points.append(Vector3(-20.0, 0.0, -14.0)) # Site B Floor
	roam_points.append(Vector3(-14.0, 0.0, -16.0)) # B Window

	# Power-up Spot (Dead-center of Mid Doors)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, -2.0))

	# Tactical Ammo Buckets
	add_bucket(Vector3(20.0, 0.0, 18.0), Color(0.95, 0.45, 0.15))  # Long Doors approach
	add_bucket(Vector3(-24.0, 0.0, 16.0), Color(0.95, 0.45, 0.15)) # Upper B Tunnel
	add_bucket(Vector3(20.0, 1.8, -22.0), Color(0.20, 0.50, 0.95)) # Site A
	add_bucket(Vector3(-20.0, 0.0, -17.0), Color(0.20, 0.50, 0.95)) # Site B Floor
	add_bucket(Vector3(0.0, -0.5, -26.0), Color(0.20, 0.50, 0.95)) # CT Spawn

	# Tactical Foam Shield Pickup on Catwalk beside Xbox
	var shield := ShieldPickup.new()
	shield.position = Vector3(6.5, 2.6, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
