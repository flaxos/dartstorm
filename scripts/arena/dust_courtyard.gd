class_name DustCourtyard
extends Arena
## DUSTY COURTYARD: Inspired by the legendary Counter-Strike de_dust.
## Features sun-bleached sandstone walls, a long double-door choke hallway,
## a sunken underpass tunnel, an expansive open middle courtyard with stacked
## shipping crates, and two distinct bomb sites (Site A & Site B).

const HALF_X := 32.0
const HALF_Z := 24.0

const SANDSTONE := Color(0.85, 0.74, 0.55)
const SANDSTONE_DARK := Color(0.72, 0.62, 0.44)
const COBBLE := Color(0.65, 0.58, 0.48)
const CRATE_WOOD := Color(0.68, 0.46, 0.28)
const TRIM_BLUE := Color(0.2, 0.45, 0.85)
const TRIM_ORANGE := Color(0.95, 0.45, 0.1)


func _build() -> void:
	arena_name = "Dusty Courtyard"
	_build_sky_and_sun(-42.0, 0.15)
	_build_ground_and_walls()
	_build_long_hallway()
	_build_underpass_tunnel()
	_build_central_courtyard()
	_build_bomb_sites()
	_build_spawns_and_objectives()


func _build_ground_and_walls() -> void:
	# Main courtyard ground
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), SANDSTONE)
	ArenaKit.deco_box(decor, Vector3(400.0, 0.2, 400.0), Vector3(0.0, -0.55, 0.0), SANDSTONE_DARK)

	# High canyon perimeter walls
	var wall_h := 6.5
	var thick := 1.0
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), SANDSTONE)


func _build_long_hallway() -> void:
	# West Hallway / Choke Point (X between -24.0 and -10.0, Z around -6.0)
	var hall_w := 5.2
	var hall_l := 14.0
	# North and South hall walls
	ArenaKit.box(geometry, Vector3(hall_l, 4.5, 0.8), Vector3(-17.0, 2.25, -6.0 - hall_w * 0.5), SANDSTONE)
	ArenaKit.box(geometry, Vector3(hall_l, 4.5, 0.8), Vector3(-17.0, 2.25, -6.0 + hall_w * 0.5), SANDSTONE)

	# Double Door Choke Archway (at X = -10.0)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.4), Vector3(-10.0, 2.25, -6.0 - 1.8), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 4.5, 1.4), Vector3(-10.0, 2.25, -6.0 + 1.8), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(0.8, 1.5, hall_w), Vector3(-10.0, 3.75, -6.0), SANDSTONE_DARK)

	# Decorative wooden double doors propped open
	ArenaKit.box(geometry, Vector3(0.2, 2.8, 1.2), Vector3(-9.6, 1.4, -6.0 - 1.2), CRATE_WOOD, Vector3(0.0, 30.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(0.2, 2.8, 1.2), Vector3(-9.6, 1.4, -6.0 + 1.2), CRATE_WOOD, Vector3(0.0, -30.0, 0.0), ArenaKit.SurfaceType.WOOD)


func _build_underpass_tunnel() -> void:
	# Sunken Underpass (floor at Y = -2.2, X between -18.0 and 2.0, Z around 6.0)
	var tunnel_w := 4.4
	var tunnel_l := 20.0
	# Underpass floor
	ArenaKit.box(geometry, Vector3(tunnel_l, 0.4, tunnel_w), Vector3(-8.0, -2.4, 6.0), COBBLE)

	# Entrance ramp from T-spawn into underpass
	ArenaKit.ramp(geometry, Vector3(-20.0, 0.0, 6.0), Vector3(-16.0, -2.2, 6.0), 3.6, SANDSTONE)
	# Exit ramp from underpass up into central courtyard
	ArenaKit.ramp(geometry, Vector3(0.0, -2.2, 6.0), Vector3(4.0, 0.0, 6.0), 3.6, SANDSTONE)

	# Tunnel side retaining walls
	ArenaKit.box(geometry, Vector3(tunnel_l, 2.4, 0.8), Vector3(-8.0, -1.0, 6.0 - tunnel_w * 0.5 - 0.4), SANDSTONE)
	ArenaKit.box(geometry, Vector3(tunnel_l, 2.4, 0.8), Vector3(-8.0, -1.0, 6.0 + tunnel_w * 0.5 + 0.4), SANDSTONE)

	# Walkway bridge overhead spanning across underpass at X = -8.0
	ArenaKit.box(geometry, Vector3(3.6, 0.4, tunnel_w + 1.6), Vector3(-8.0, -0.2, 6.0), SANDSTONE)


func _build_central_courtyard() -> void:
	# Central open courtyard features stone archways and stacked tactical crates
	# Big central pillar / archway structure at (0, 0, -4)
	ArenaKit.cylinder(geometry, 0.8, 5.0, Vector3(0.0, 2.5, -8.0), SANDSTONE_DARK)
	ArenaKit.cylinder(geometry, 0.8, 5.0, Vector3(0.0, 2.5, 0.0), SANDSTONE_DARK)
	ArenaKit.box(geometry, Vector3(2.0, 1.2, 9.6), Vector3(0.0, 4.4, -4.0), SANDSTONE_DARK)

	# Stacked tactical shipping crates
	# West stack
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(-4.0, 0.8, -2.0), CRATE_WOOD, Vector3(0.0, 10.0, 0.0), ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(-3.8, 2.3, -2.0), CRATE_WOOD, Vector3(0.0, -5.0, 0.0), ArenaKit.SurfaceType.WOOD)
	# East stack
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(8.0, 0.8, -2.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.6, 1.6, 1.6), Vector3(8.0, 0.8, 0.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(8.0, 2.3, -1.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)


func _build_bomb_sites() -> void:
	# Bomb Site A: Raised Sandstone Terrace (North-East, X = 16.0, Z = -10.0, Y = 2.0)
	var terrace_w := 14.0
	var terrace_l := 12.0
	ArenaKit.box(geometry, Vector3(terrace_l, 2.0, terrace_w), Vector3(16.0, 1.0, -10.0), SANDSTONE)
	# Ramps up to Site A terrace from courtyard (West) and CT spawn (East)
	ArenaKit.ramp(geometry, Vector3(8.0, 0.0, -10.0), Vector3(10.0, 2.0, -10.0), 3.2, SANDSTONE)
	ArenaKit.ramp(geometry, Vector3(24.0, 0.0, -10.0), Vector3(22.0, 2.0, -10.0), 3.2, SANDSTONE)
	# Crates on Site A
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(15.0, 2.7, -9.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(1.4, 1.4, 1.4), Vector3(17.0, 2.7, -9.0), CRATE_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Bomb Site B: Enclosed courtyard / underpass exit (South-East, X = 10.0, Z = 12.0, Y = 0.0)
	# Protective boundary walls
	ArenaKit.box(geometry, Vector3(0.8, 3.5, 8.0), Vector3(5.0, 1.75, 12.0), SANDSTONE)
	ArenaKit.box(geometry, Vector3(8.0, 3.5, 0.8), Vector3(10.0, 1.75, 7.5), SANDSTONE)
	# Crates at Site B
	ArenaKit.box(geometry, Vector3(1.5, 1.5, 1.5), Vector3(11.0, 0.75, 12.0), CRATE_WOOD, Vector3(0.0, 15.0, 0.0), ArenaKit.SurfaceType.WOOD)


func _build_spawns_and_objectives() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(22.0, 0.0, 0.0))  # CT / Guardians Base (East)
	team_bases.append(Vector3(-24.0, 0.0, 0.0)) # T / Infiltrators Base (West)

	# Flag Pedestals for CTF
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(20.0, 2.0, -10.0)) # Blue Flag on Site A Terrace
	flag_pedestals.append(Vector3(-24.0, 0.0, 0.0))  # Orange Flag at T Spawn

	# Bomb Sites for Plant The Bomb
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(16.0, 2.0, -10.0) # Site A (Terrace)
	bomb_sites["B"] = Vector3(10.0, 0.0, 12.0)  # Site B (Courtyard)
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(-22.0, 0.0, 0.0))

	# Player / Bot Spawns (East vs West)
	spawn_points.clear()
	roam_points.clear()
	var ct_spawns := [
		Vector3(22.0, 0.0, -3.0), Vector3(22.0, 0.0, 3.0),
		Vector3(24.0, 0.0, -6.0), Vector3(24.0, 0.0, 6.0),
	]
	var t_spawns := [
		Vector3(-24.0, 0.0, -3.0), Vector3(-24.0, 0.0, 3.0),
		Vector3(-22.0, 0.0, -6.0), Vector3(-22.0, 0.0, 6.0),
	]
	for p in ct_spawns:
		add_spawn(p, Vector3(-1.0, 0.0, 0.0))
	for p in t_spawns:
		add_spawn(p, Vector3(1.0, 0.0, 0.0))

	# Tactical Roam Points
	roam_points.append(Vector3(0.0, 0.0, 0.0))         # Mid Courtyard
	roam_points.append(Vector3(16.0, 2.0, -10.0))      # Site A
	roam_points.append(Vector3(10.0, 0.0, 12.0))       # Site B
	roam_points.append(Vector3(-14.0, 0.0, -6.0))      # Long Hallway
	roam_points.append(Vector3(-8.0, -2.2, 6.0))       # Underpass Tunnel
	roam_points.append(Vector3(0.0, 0.0, 6.0))         # Underpass Exit
	roam_points.append(Vector3(22.0, 0.0, 0.0))        # CT Spawn
	roam_points.append(Vector3(-24.0, 0.0, 0.0))       # T Spawn

	# Power-up Spot (Middle of courtyard)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, 0.0))

	# Ammo Buckets
	add_bucket(Vector3(-14.0, 0.0, -6.0), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(16.0, 2.0, -14.0), Color(0.2, 0.5, 0.95))
	add_bucket(Vector3(-8.0, -2.2, 6.0), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(12.0, 0.0, 14.0), Color(0.2, 0.5, 0.95))

	# Foam Shield Pickup (Courtyard bridge)
	var shield := ShieldPickup.new()
	shield.position = Vector3(0.0, 0.8, -2.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
