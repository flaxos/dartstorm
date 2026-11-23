class_name DustCourtyard
extends Arena
## DUSTY COURTYARD: Authentically laid out after Counter-Strike's iconic de_dust (Dust I).
## Features:
##   - West Long Hallway with stairs, alcoves, and propped double-door choke
##   - Sunken Underpass tunnel running beneath the overhead CT sniper bridge
##   - Expansive East Courtyard featuring the iconic octagonal gazebo monument (Bombsite A)
##   - North Corridor with Bombsite B and CT Spawn
##   - CT connecting route from CT Spawn into North Courtyard

const HALF_X := 42.0
const HALF_Z := 36.0

const SANDSTONE := Color(0.85, 0.74, 0.55)
const SANDSTONE_DARK := Color(0.72, 0.62, 0.44)
const COBBLE := Color(0.65, 0.58, 0.48)
const CRATE_WOOD := Color(0.68, 0.46, 0.28)
const TRIM_BLUE := Color(0.2, 0.45, 0.85)
const TRIM_ORANGE := Color(0.95, 0.45, 0.1)


func _build() -> void:
	arena_name = "Dusty Courtyard"
	_build_sky_and_sun(-44.0, 0.16)
	_build_ground_and_walls()
	_build_t_spawn_and_hallway()
	_build_underpass_and_bridge()
	_build_east_courtyard_and_monument()
	_build_north_hall_and_site_b()
	_build_spawns_and_objectives()


func _build_ground_and_walls() -> void:
	# Main courtyard ground
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), SANDSTONE)
	# Infinite background desert floor
	ArenaKit.deco_box(decor, Vector3(450.0, 0.2, 450.0), Vector3(0.0, -0.55, 0.0), SANDSTONE_DARK)

	# High canyon fortress boundary walls
	var wall_h := 7.0
	var thick := 1.2
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)


func _build_t_spawn_and_hallway() -> void:
	# --- T-Spawn Plaza (South-West: X = -28 to -14, Z = 16 to 28) ---
	# Decorative boundary wall dividing T-spawn from underpass approach
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 12.0), Vector3(-13.0, 2.25, 22.0), SANDSTONE)

	# T-Spawn staging crates and cover
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 1.8), Vector3(-24.0, 0.9, 22.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-22.0, 0.8, 22.0), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(-23.0, 2.45, 22.0), CRATE_WOOD, Vector3(0.0, -10.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- West Long Hallway (leading North from T-Spawn along X = -24) ---
	var hall_w := 5.2
	# West exterior wall is boundary wall at -HALF_X (-42.0) or inner hall wall at -27.0
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 32.0), Vector3(-27.0, 2.5, 2.0), SANDSTONE)
	# East hall partition wall
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 28.0), Vector3(-21.0, 2.5, 4.0), SANDSTONE)

	# Hallway floor (Z: 18 down to 6 at Y = 0.0)
	ArenaKit.box(geometry, Vector3(hall_w, 0.4, 12.0), Vector3(-24.0, -0.2, 12.0), COBBLE)

	# Stairs rising up in the hallway from Y = 0.0 to Y = 1.6 (between Z = 6 and Z = 0)
	ArenaKit.ramp(geometry, Vector3(-24.0, 0.0, 6.0), Vector3(-24.0, 1.6, 0.0), hall_w, SANDSTONE)

	# Elevated Upper Hallway (Y = 1.6, Z from 0.0 to -14.0)
	ArenaKit.box(geometry, Vector3(hall_w, 1.6, 14.0), Vector3(-24.0, 0.8, -7.0), SANDSTONE)

	# Hallway corner alcove / crates at stairs top
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-26.0, 2.3, -2.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Hallway turns East at Z = -14.0: Corridor towards Double Doors (X: -24.0 to -10.0)
	ArenaKit.box(geometry, Vector3(14.0, 1.6, hall_w), Vector3(-17.0, 0.8, -14.0), SANDSTONE)
	# North and South walls for the East-heading hallway
	ArenaKit.box(geometry, Vector3(16.0, 5.0, 0.8), Vector3(-19.0, 2.5, -14.0 - hall_w * 0.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(10.0, 5.0, 0.8), Vector3(-16.0, 2.5, -14.0 + hall_w * 0.5), SANDSTONE)

	# --- Double Doors Choke (at X = -10.0, Z = -14.0, Y = 1.6) ---
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 1.4), Vector3(-10.0, 2.5, -14.0 - 1.9), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 1.4), Vector3(-10.0, 2.5, -14.0 + 1.9), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 1.6, hall_w), Vector3(-10.0, 4.2, -14.0), SANDSTONE_DARK)

	# Propped open heavy wooden doors
	ArenaKit.box(geometry, Vector3(0.2, 3.2, 1.3), Vector3(-9.5, 3.2, -14.0 - 1.2), CRATE_WOOD, Vector3(0.0, 32.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 3.2, 1.3), Vector3(-9.5, 3.2, -14.0 + 1.2), CRATE_WOOD, Vector3(0.0, -32.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# Ramp descending from Double Doors (Y = 1.6) down to Choke Junction (Y = 0.5)
	ArenaKit.ramp(geometry, Vector3(-9.0, 1.6, -14.0), Vector3(-5.0, 0.5, -14.0), hall_w, SANDSTONE)


func _build_underpass_and_bridge() -> void:
	# --- Sunken Underpass Tunnel ---
	# Ramps down from T-spawn (X = -16, Z = 16, Y = 0.0) to (X = -16, Z = 10, Y = -2.4)
	var tun_w := 4.6
	ArenaKit.ramp(geometry, Vector3(-16.0, 0.0, 16.0), Vector3(-16.0, -2.4, 10.0), tun_w, SANDSTONE)

	# North-South tunnel segment (Z: 10 down to 2 at depth Y = -2.4)
	ArenaKit.box(geometry, Vector3(tun_w, 0.4, 8.0), Vector3(-16.0, -2.6, 6.0), COBBLE)
	ArenaKit.box(geometry, Vector3(0.8, 3.0, 8.0), Vector3(-16.0 - tun_w * 0.5 - 0.4, -1.0, 6.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 3.0, 8.0), Vector3(-16.0 + tun_w * 0.5 + 0.4, -1.0, 6.0), SANDSTONE_DARK)

	# Underpass turns East towards X = 4 under the bridge:
	# East-West tunnel segment (X: -16.0 to 4.0, Z = 0.0, Y = -2.4)
	var tun_l := 20.0
	ArenaKit.box(geometry, Vector3(tun_l, 0.4, tun_w), Vector3(-6.0, -2.6, 0.0), COBBLE)
	ArenaKit.box(geometry, Vector3(tun_l, 3.0, 0.8), Vector3(-6.0, -1.0, -tun_w * 0.5 - 0.4), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(tun_l, 3.0, 0.8), Vector3(-6.0, -1.0, tun_w * 0.5 + 0.4), SANDSTONE_DARK)

	# --- The Overhead Sniper Bridge (at X = -4.0, spanning across Z from -4.0 to 4.0 at Y = 0.5) ---
	var bridge_w := 4.2
	# Solid bridge deck over the underpass
	ArenaKit.box(geometry, Vector3(bridge_w, 0.5, tun_w + 2.0), Vector3(-4.0, 0.25, 0.0), SANDSTONE)
	# Parapet stone railings on the bridge overlooking the underpass
	ArenaKit.box(geometry, Vector3(0.4, 1.1, tun_w + 2.0), Vector3(-4.0 - bridge_w * 0.5 + 0.2, 0.95, 0.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.4, 1.1, tun_w + 2.0), Vector3(-4.0 + bridge_w * 0.5 - 0.2, 0.95, 0.0), SANDSTONE_DARK)

	# Ramp up to bridge from Choke Junction (North)
	ArenaKit.ramp(geometry, Vector3(-4.0, 0.5, -7.0), Vector3(-4.0, 0.5, -3.0), bridge_w, SANDSTONE)
	# Walkway continuing South off the bridge towards Central Ridge
	ArenaKit.box(geometry, Vector3(bridge_w, 0.5, 6.0), Vector3(-4.0, 0.25, 6.0), SANDSTONE)

	# --- Underpass Exit Ramp into Courtyard ---
	# From (X = 2.0, Z = 0.0, Y = -2.4) ramping up East to (X = 7.0, Z = 0.0, Y = 0.0)
	ArenaKit.ramp(geometry, Vector3(1.0, -2.4, 0.0), Vector3(7.0, 0.0, 0.0), tun_w, SANDSTONE)

	# Retaining stone arch framing the underpass exit into courtyard
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 1.2), Vector3(7.0, 2.0, -tun_w * 0.5), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 1.2), Vector3(7.0, 2.0, tun_w * 0.5), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 1.2, tun_w + 1.2), Vector3(7.0, 3.4, 0.0), SANDSTONE_DARK)


func _build_east_courtyard_and_monument() -> void:
	# Dividing barrier separating hallway/bridge territory from big courtyard (X = 7.0, Z from -6.0 to -18.0)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 14.0), Vector3(7.0, 2.5, -12.0), SANDSTONE)

	# Opening arch connecting Choke Junction into Courtyard (at X = 7.0, Z = -10.0)
	ArenaKit.box(geometry, Vector3(0.8, 1.4, 4.4), Vector3(7.0, 4.3, -10.0), SANDSTONE_DARK)

	# --- The Iconic Octagonal Sandstone Monument / Gazebo (Bombsite A) ---
	# Centered at X = 28.0, Z = 12.0
	var mon_pos := Vector3(28.0, 0.0, 12.0)
	var base_size := 10.0
	# Base platform (raised Y = 2.2)
	ArenaKit.box(geometry, Vector3(base_size, 2.2, base_size), mon_pos + Vector3(0.0, 1.1, 0.0), SANDSTONE)
	# Beveled chamfered corners of the monument
	for c_angle: float in [45.0, 135.0, 225.0, 315.0]:
		var rad := deg_to_rad(c_angle)
		var corner_offset := Vector3(cos(rad) * (base_size * 0.5), 1.1, sin(rad) * (base_size * 0.5))
		ArenaKit.box(geometry, Vector3(2.8, 2.2, 2.8), mon_pos + corner_offset, SANDSTONE, Vector3(0.0, 45.0, 0.0))

	# Wide stone access stairs up to Monument top from North and West
	ArenaKit.ramp(geometry, mon_pos + Vector3(0.0, 0.0, -base_size * 0.5 - 3.2), mon_pos + Vector3(0.0, 2.2, -base_size * 0.5), 4.2, SANDSTONE)
	ArenaKit.ramp(geometry, mon_pos + Vector3(-base_size * 0.5 - 3.2, 0.0, 0.0), mon_pos + Vector3(-base_size * 0.5, 2.2, 0.0), 4.2, SANDSTONE)

	# 4 Heavy Sandstone Columns on Monument corners
	var col_h := 3.2
	var col_r := 0.55
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var col_pos := mon_pos + Vector3(sx * 3.8, 2.2 + col_h * 0.5, sz * 3.8)
			ArenaKit.cylinder(geometry, col_r, col_h, col_pos, SANDSTONE_DARK)

	# Top decorative stone cornice & architraves spanning columns
	ArenaKit.box(geometry, Vector3(8.4, 0.7, 0.9), mon_pos + Vector3(0.0, 2.2 + col_h + 0.35, -3.8), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(8.4, 0.7, 0.9), mon_pos + Vector3(0.0, 2.2 + col_h + 0.35, 3.8), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.9, 0.7, 8.4), mon_pos + Vector3(-3.8, 2.2 + col_h + 0.35, 0.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.9, 0.7, 8.4), mon_pos + Vector3(3.8, 2.2 + col_h + 0.35, 0.0), SANDSTONE_DARK)

	# Stacked tactical shipping crates on top of Site A Monument
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), mon_pos + Vector3(1.2, 2.2 + 0.8, -1.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), mon_pos + Vector3(-1.4, 2.2 + 0.7, 1.2), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), mon_pos + Vector3(1.2, 2.2 + 2.3, -1.0), CRATE_WOOD, Vector3(0.0, -8.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# Crates on ground level surrounding Monument
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 1.8), mon_pos + Vector3(-base_size * 0.5 - 1.5, 0.9, 3.5), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), mon_pos + Vector3(-base_size * 0.5 - 1.5, 0.8, 5.2), CRATE_WOOD, Vector3(0.0, 20.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.8, 1.8, 1.8), Vector3(14.0, 0.9, 4.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(14.0, 0.8, 5.8), CRATE_WOOD, Vector3(0.0, -12.0, 0.0), ArenaKit.SurfaceType.WOOD)


func _build_north_hall_and_site_b() -> void:
	# --- North Corridor (Bombsite B: centered at X = 0.0, Z from -14.0 to -32.0) ---
	# West and East corridor boundary walls
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 18.0), Vector3(-3.0, 2.5, -23.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(0.8, 5.0, 18.0), Vector3(3.0, 2.5, -23.0), SANDSTONE)

	# Site B target area (Z = -22.0, X = 0.0)
	# Tactical defensive crates at Bombsite B
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-1.4, 0.8, -21.0), CRATE_WOOD, Vector3(0.0, 12.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(1.4, 0.75, -23.0), CRATE_WOOD, Vector3(0.0, -10.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-1.4, 2.3, -21.0), CRATE_WOOD, Vector3(0.0, 5.0, 0.0), ArenaKit.SurfaceType.WOOD)

	# --- CT Spawn Area (at North End: X = 0.0, Z = -31.0) ---
	ArenaKit.box(geometry, Vector3(10.0, 0.8, 6.0), Vector3(0.0, 0.4, -31.0), SANDSTONE_DARK)
	ArenaKit.ramp(geometry, Vector3(0.0, 0.0, -27.0), Vector3(0.0, 0.8, -29.0), 4.0, SANDSTONE)

	# --- CT Connector Eastward into North Courtyard (X from 3.0 to 20.0, Z = -26.0) ---
	ArenaKit.box(geometry, Vector3(18.0, 0.3, 5.2), Vector3(12.0, -0.15, -26.0), COBBLE)
	ArenaKit.box(geometry, Vector3(18.0, 5.0, 0.8), Vector3(12.0, 2.5, -29.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(14.0, 5.0, 0.8), Vector3(10.0, 2.5, -23.0), SANDSTONE)
	# Turn South into North Courtyard
	ArenaKit.box(geometry, Vector3(5.2, 0.3, 12.0), Vector3(20.0, -0.15, -17.0), COBBLE)


func _build_spawns_and_objectives() -> void:
	# Team bases: Team 0 (Blue / CT) at North, Team 1 (Orange / T) at South-West
	team_bases.clear()
	team_bases.append(Vector3(0.0, 0.8, -31.0))   # CT Base
	team_bases.append(Vector3(-22.0, 0.0, 22.0))  # T Base

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(28.0, 2.2, 12.0)) # Blue Flag on Site A Monument top
	flag_pedestals.append(Vector3(-22.0, 0.0, 22.0)) # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(28.0, 2.2, 12.0)  # Site A: On top of the Monument
	bomb_sites["B"] = Vector3(0.0, 0.0, -22.0)   # Site B: In the North Hallway
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(-20.0, 0.0, 20.0))

	# Player / Bot Spawns (CT vs T)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(-4.0, 0.8, -31.0), Vector3(4.0, 0.8, -31.0),
		Vector3(-2.0, 0.8, -34.0), Vector3(2.0, 0.8, -34.0),
		Vector3(-6.0, 0.0, -27.0), Vector3(6.0, 0.0, -27.0),
	]
	var t_spawns := [
		Vector3(-26.0, 0.0, 20.0), Vector3(-20.0, 0.0, 20.0),
		Vector3(-23.0, 0.0, 24.0), Vector3(-17.0, 0.0, 24.0),
		Vector3(-26.0, 0.0, 28.0), Vector3(-20.0, 0.0, 28.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in t_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Tactical Roam Points across the iconic de_dust routes
	roam_points.append(Vector3(-22.0, 0.0, 22.0))  # T Spawn
	roam_points.append(Vector3(-24.0, 0.0, 12.0))  # Lower Long Hallway
	roam_points.append(Vector3(-24.0, 1.6, -6.0))  # Upper Long Hallway
	roam_points.append(Vector3(-10.0, 1.6, -14.0)) # Double Doors Choke
	roam_points.append(Vector3(-5.0, 0.5, -10.0))  # Choke Junction
	roam_points.append(Vector3(-4.0, 0.5, 0.0))    # Overhead Sniper Bridge
	roam_points.append(Vector3(-16.0, -2.4, 6.0))  # Underpass Entrance
	roam_points.append(Vector3(-6.0, -2.4, 0.0))   # Underpass beneath Bridge
	roam_points.append(Vector3(6.0, 0.0, 4.0))     # Underpass Courtyard Exit
	roam_points.append(Vector3(16.0, 0.0, 8.0))    # West Courtyard
	roam_points.append(Vector3(28.0, 2.2, 12.0))   # Site A Monument Top
	roam_points.append(Vector3(26.0, 0.0, 0.0))    # North-East Courtyard
	roam_points.append(Vector3(20.0, 0.0, -18.0))  # CT Courtyard Corridor
	roam_points.append(Vector3(0.0, 0.0, -22.0))   # Site B Hallway
	roam_points.append(Vector3(0.0, 0.8, -31.0))   # CT Spawn

	# Power-up Spot (At the iconic Underpass Bridge)
	power_up_spots.clear()
	power_up_spots.append(Vector3(-4.0, 0.5, 0.0))

	# Tactical Ammo Buckets
	add_bucket(Vector3(-24.0, 0.0, 16.0), Color(0.95, 0.45, 0.15)) # T Hallway start
	add_bucket(Vector3(-10.0, 1.6, -12.0), Color(0.95, 0.45, 0.15)) # Choke Double Doors
	add_bucket(Vector3(-6.0, -2.4, 0.0), Color(0.95, 0.45, 0.15))  # Sunken Underpass
	add_bucket(Vector3(28.0, 2.2, 16.0), Color(0.2, 0.5, 0.95))   # Site A Monument
	add_bucket(Vector3(0.0, 0.0, -25.0), Color(0.2, 0.5, 0.95))    # Site B Hallway
	add_bucket(Vector3(0.0, 0.8, -33.0), Color(0.2, 0.5, 0.95))    # CT Spawn

	# Tactical Foam Shield Pickup on top of the Sniper Bridge
	var shield := ShieldPickup.new()
	shield.position = Vector3(-4.0, 1.3, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
