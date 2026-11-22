class_name Dust2
extends Arena
## DUSTSTORM II: Inspired by the iconic Counter-Strike de_dust2.
## The legendary four-square tactical layout faithfully adapted for DARTSTORM:
## Long A (Pit, Long Doors, A Ramp), Catwalk/Short A, Mid Doors, Upper/Lower
## B Tunnels, Site B (B Window, B Platform), and Site A (Elevated Platform).

const HALF_X := 36.0
const HALF_Z := 36.0

const SANDSTONE := Color(0.86, 0.76, 0.58)
const SANDSTONE_DARK := Color(0.74, 0.64, 0.46)
const COBBLE := Color(0.66, 0.60, 0.50)
const CRATE_WOOD := Color(0.70, 0.48, 0.30)
const METAL_DOOR := Color(0.45, 0.50, 0.55)


func _build() -> void:
	arena_name = "Duststorm II"
	_build_sky_and_sun(-48.0, 0.12)
	_build_ground_and_walls()
	_build_mid_and_doors()
	_build_long_a()
	_build_catwalk_and_short_a()
	_build_b_tunnels_and_site_b()
	_build_site_a()
	_build_spawns_and_objectives()


func _build_ground_and_walls() -> void:
	# Main ground plane
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), SANDSTONE)
	ArenaKit.deco_box(decor, Vector3(450.0, 0.2, 450.0), Vector3(0.0, -0.55, 0.0), SANDSTONE_DARK)

	# Boundary canyon fortress walls
	var wall_h := 7.0
	var thick := 1.0
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)


func _build_mid_and_doors() -> void:
	# Central Mid Avenue (X around 0.0, Z from -18.0 to 18.0)
	# Dividing barrier walls separating Mid from Long and Tunnels
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 22.0), Vector3(-8.0, 2.5, 2.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 22.0), Vector3(8.0, 2.5, 2.0), SANDSTONE)

	# Mid Double Doors (at Z = -4.0, X = 0.0)
	# Door frame arches
	ArenaKit.box(geometry, Vector3(2.6, 5.0, 0.8), Vector3(-3.2, 2.5, -4.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.6, 5.0, 0.8), Vector3(3.2, 2.5, -4.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(4.0, 1.6, 0.8), Vector3(0.0, 4.2, -4.0), SANDSTONE_DARK)

	# Propped open metal double doors (with sniper gap slit)
	ArenaKit.box(geometry, Vector3(1.6, 3.2, 0.15), Vector3(-1.2, 1.6, -4.3), METAL_DOOR, Vector3(0.0, 25.0, 0.0), ArenaKit.SurfaceType.METAL)
	ArenaKit.box(geometry, Vector3(1.6, 3.2, 0.15), Vector3(1.2, 1.6, -4.3), METAL_DOOR, Vector3(0.0, -25.0, 0.0), ArenaKit.SurfaceType.METAL)

	# The famous "Xbox" tactical crate in Mid (jump up to Catwalk)
	ArenaKit.box(geometry, Vector3(2.0, 1.9, 2.0), Vector3(5.0, 0.95, 2.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_long_a() -> void:
	# East corridor: Long A (X between 12.0 and 26.0)
	# Long Doors Choke at (X = 18.0, Z = 14.0)
	ArenaKit.box(geometry, Vector3(8.0, 5.0, 0.8), Vector3(12.0, 2.5, 14.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(8.0, 5.0, 0.8), Vector3(24.0, 2.5, 14.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(4.0, 1.8, 0.8), Vector3(18.0, 4.1, 14.0), SANDSTONE)

	# Long Pit (sunken depression at X = 24.0, Z = 2.0, Y = -1.4)
	var pit_w := 6.0
	var pit_l := 8.0
	ArenaKit.box(geometry, Vector3(pit_w, 0.4, pit_l), Vector3(24.0, -1.6, 2.0), COBBLE)
	ArenaKit.ramp(geometry, Vector3(24.0, -1.4, -2.0), Vector3(24.0, 0.0, -4.5), 4.0, SANDSTONE)

	# Long A Corner wall (X = 14.0, Z from -6.0 to 10.0)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 16.0), Vector3(14.0, 2.5, 2.0), SANDSTONE)

	# Long A Blue Shipping Container / Crates
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 3.6), Vector3(16.5, 0.9, -6.0), CRATE_WOOD, Vector3(0.0, 10.0, 0.0), ArenaKit.SurfaceType.WOOD)


func _build_catwalk_and_short_a() -> void:
	# Catwalk / Short A elevated walkway (Y = 2.0)
	# Starts near Xbox at X = 6.0, Z = 2.0 and extends North toward Site A
	var cat_w := 3.4
	# Catwalk platform
	ArenaKit.box(geometry, Vector3(cat_w, 2.0, 16.0), Vector3(6.5, 1.0, -6.0), SANDSTONE)
	# Ramp up to Catwalk from Mid
	ArenaKit.ramp(geometry, Vector3(6.5, 0.0, 5.0), Vector3(6.5, 2.0, 2.0), 3.0, SANDSTONE)

	# Short A stairs winding East onto Site A
	ArenaKit.box(geometry, Vector3(6.0, 2.0, cat_w), Vector3(10.0, 1.0, -14.0), SANDSTONE)


func _build_b_tunnels_and_site_b() -> void:
	# West: Upper B Tunnels (X between -26.0 and -12.0, Z from 2.0 to 20.0)
	var tun_l := 18.0
	# Tunnel side walls
	ArenaKit.box(geometry, Vector3(0.8, 4.5, tun_l), Vector3(-12.0, 2.25, 11.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, tun_l), Vector3(-24.0, 2.25, 11.0), SANDSTONE)

	# Lower Tunnels stairs down to Mid (X around -10.0, Z = 2.0)
	ArenaKit.ramp(geometry, Vector3(-12.0, 0.0, 2.0), Vector3(-8.0, 0.0, 2.0), 3.0, SANDSTONE)

	# B Site (North-West, centered at X = -18.0, Z = -12.0)
	var b_site_w := 14.0
	var b_site_l := 14.0
	# B Site boundary enclosure walls
	ArenaKit.box(geometry, Vector3(b_site_l, 4.5, 0.8), Vector3(-18.0, 2.25, -5.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, b_site_w), Vector3(-11.0, 2.25, -12.0), SANDSTONE)

	# B Doors entrance into B site
	ArenaKit.box(geometry, Vector3(2.4, 4.5, 0.8), Vector3(-14.0, 2.25, -5.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.4, 4.5, 0.8), Vector3(-22.0, 2.25, -5.0), SANDSTONE_DARK)

	# B Window looking out to CT Spawn (raised opening at X = -11.0, Z = -16.0)
	ArenaKit.box(geometry, Vector3(0.8, 1.4, 3.0), Vector3(-11.0, 0.7, -16.0), SANDSTONE_DARK)

	# Stacked tactical crates on B Platform
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-18.0, 0.8, -12.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-18.0, 2.3, -12.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-20.0, 0.8, -14.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_site_a() -> void:
	# Site A (North-East, centered at X = 16.0, Z = -16.0, Y = 2.0)
	var a_w := 12.0
	var a_l := 12.0
	# Raised platform for Site A
	ArenaKit.box(geometry, Vector3(a_l, 2.0, a_w), Vector3(16.0, 1.0, -16.0), SANDSTONE)

	# Long A Ramp up to Site A platform
	ArenaKit.ramp(geometry, Vector3(16.0, 0.0, -8.0), Vector3(16.0, 2.0, -10.0), 4.2, SANDSTONE)

	# Crates on Site A (Gooseneck & Default plant spots)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(15.0, 2.75, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(17.0, 2.75, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(16.0, 4.2, -15.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_spawns_and_objectives() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(0.0, 0.0, -26.0)) # CT / Guardians Spawn (North)
	team_bases.append(Vector3(0.0, 0.0, 26.0))  # T / Infiltrators Spawn (South)

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(16.0, 2.0, -16.0)) # Blue Flag on Site A Platform
	flag_pedestals.append(Vector3(0.0, 0.0, 26.0))    # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(16.0, 2.0, -16.0) # Site A (Terrace Platform)
	bomb_sites["B"] = Vector3(-18.0, 0.0, -12.0) # Site B (Enclosed Platform)
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(0.0, 0.0, 24.0))

	# Player / Bot Spawns (North vs South)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(-4.0, 0.0, -25.0), Vector3(4.0, 0.0, -25.0),
		Vector3(-2.0, 0.0, -27.0), Vector3(2.0, 0.0, -27.0),
	]
	var t_spawns := [
		Vector3(-4.0, 0.0, 25.0), Vector3(4.0, 0.0, 25.0),
		Vector3(-2.0, 0.0, 27.0), Vector3(2.0, 0.0, 27.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in t_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Tactical Roam Points across the 4 quadrants
	roam_points.append(Vector3(0.0, 0.0, 0.0))          # Mid Doors
	roam_points.append(Vector3(0.0, 0.0, 10.0))         # T Mid
	roam_points.append(Vector3(0.0, 0.0, -14.0))        # CT Mid
	roam_points.append(Vector3(18.0, 0.0, 14.0))        # Long Doors
	roam_points.append(Vector3(24.0, -1.4, 2.0))        # Long Pit
	roam_points.append(Vector3(16.0, 0.0, -4.0))        # Long A Corner
	roam_points.append(Vector3(16.0, 2.0, -16.0))       # Site A
	roam_points.append(Vector3(6.5, 2.0, -6.0))         # Catwalk
	roam_points.append(Vector3(-18.0, 0.0, 10.0))       # Upper B Tunnels
	roam_points.append(Vector3(-18.0, 0.0, -12.0))      # Site B
	roam_points.append(Vector3(-11.0, 0.0, -16.0))      # B Window

	# Power-up Spot (Center of Mid)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, 0.0))

	# Ammo Buckets
	add_bucket(Vector3(18.0, 0.0, 12.0), Color(0.95, 0.45, 0.15)) # Long Doors
	add_bucket(Vector3(16.0, 2.0, -18.0), Color(0.2, 0.5, 0.95))   # Site A
	add_bucket(Vector3(-18.0, 0.0, 14.0), Color(0.95, 0.45, 0.15)) # B Tunnels
	add_bucket(Vector3(-18.0, 0.0, -14.0), Color(0.2, 0.5, 0.95))  # Site B

	# Foam Shield Pickup (Catwalk near Xbox)
	var shield := ShieldPickup.new()
	shield.position = Vector3(6.5, 2.8, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
