class_name TwoForts
extends Arena
## TWO FORTRESSES: Inspired by classic TF2 2Fort.
## Features two opposing team fortresses (Blue Fort & Orange Fort) separated
## by a sunken water moat and connected by a covered center wooden bridge.
## Includes upper sniper battlements, courtyard hallways, underground tunnels,
## and secure basement intel vaults for flag pedestals.

const HALF_X := 24.0
const HALF_Z := 36.0

const WOOD_BLUE := Color(0.18, 0.42, 0.85)
const WOOD_ORANGE := Color(0.92, 0.48, 0.12)
const TIMBER := Color(0.55, 0.38, 0.22)
const BRIDGE_RED := Color(0.82, 0.28, 0.20)
const WATER_COLOR := Color(0.18, 0.65, 0.88, 0.65)
const STONE := Color(0.68, 0.70, 0.74)
const FLOOR_WOOD := Color(0.72, 0.54, 0.36)


func _build() -> void:
	arena_name = "Two Fortresses"
	_build_sky_and_sun(-50.0, 0.1)
	_build_terrain_and_moat()
	_build_center_bridge()
	_build_fort(0, -1.0) # Blue Fort (North)
	_build_fort(1, 1.0)  # Orange Fort (South)
	_build_spawns_and_objectives()


func _build_terrain_and_moat() -> void:
	# Outer perimeter barrier
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -0.5, 0.0), Color(0.35, 0.60, 0.28))
	ArenaKit.deco_box(decor, Vector3(300.0, 0.2, 300.0), Vector3(0.0, -0.55, 0.0), Color(0.30, 0.52, 0.24))

	# Boundary walls with decorative coping cornices
	var wall_h := 6.0
	var thick := 0.8
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, -HALF_Z), STONE)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, wall_h, thick), Vector3(0.0, wall_h * 0.5, HALF_Z), STONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(-HALF_X, wall_h * 0.5, 0.0), STONE)
	ArenaKit.box(geometry, Vector3(thick, wall_h, HALF_Z * 2.0), Vector3(HALF_X, wall_h * 0.5, 0.0), STONE)

	# Boundary coping trims
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, -HALF_Z), Vector3(HALF_X * 2.0 + 0.4, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, HALF_Z), Vector3(HALF_X * 2.0 + 0.4, 0.35, thick + 0.4))
	ArenaKit.cornice(decor, Vector3(-HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.4))
	ArenaKit.cornice(decor, Vector3(HALF_X, wall_h + 0.15, 0.0), Vector3(thick + 0.4, 0.35, HALF_Z * 2.0 + 0.4))

	# Sunken Moat (Z between -7.0 and 7.0, X between -18.0 and 18.0, floor at Y = -2.2)
	var moat_w := 14.0
	var moat_l := 36.0
	# Moat floor
	ArenaKit.box(geometry, Vector3(moat_l, 0.4, moat_w), Vector3(0.0, -2.4, 0.0), STONE)
	# Water puddle surface in moat
	var water_puddle := WaterPuddle.new()
	water_puddle.position = Vector3(0.0, -2.0, 0.0)
	water_puddle.scale = Vector3(moat_l * 0.5, 1.0, moat_w * 0.5)
	geometry.add_child(water_puddle)
	puddles.append(water_puddle)

	# Ramps out of the moat on East and West banks
	ArenaKit.ramp(geometry, Vector3(-16.0, -2.2, 0.0), Vector3(-16.0, 0.0, -7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(-16.0, -2.2, 0.0), Vector3(-16.0, 0.0, 7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(16.0, -2.2, 0.0), Vector3(16.0, 0.0, -7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(16.0, -2.2, 0.0), Vector3(16.0, 0.0, 7.0), 3.2, TIMBER)


func _build_center_bridge() -> void:
	# Covered red wooden bridge connecting Blue and Orange forts across the moat
	var bw := 4.8
	var bl := 14.6
	# Bridge deck
	ArenaKit.box(geometry, Vector3(bw, 0.4, bl), Vector3(0.0, -0.2, 0.0), BRIDGE_RED, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Bridge railings (waist-high solid barriers)
	ArenaKit.box(geometry, Vector3(0.3, 1.1, bl), Vector3(-bw * 0.5 + 0.15, 0.55, 0.0), TIMBER)
	ArenaKit.box(geometry, Vector3(0.3, 1.1, bl), Vector3(bw * 0.5 - 0.15, 0.55, 0.0), TIMBER)

	# Roof support posts
	for z_pos in [-6.0, -2.0, 2.0, 6.0]:
		ArenaKit.cylinder(geometry, 0.16, 3.2, Vector3(-bw * 0.5 + 0.15, 1.6, z_pos), TIMBER)
		ArenaKit.cylinder(geometry, 0.16, 3.2, Vector3(bw * 0.5 - 0.15, 1.6, z_pos), TIMBER)

	# Bridge pitched roof
	ArenaKit.deco_box(decor, Vector3(bw + 0.8, 0.3, bl + 0.4), Vector3(0.0, 3.2, 0.0), BRIDGE_RED)
	ArenaKit.deco_box(decor, Vector3(bw * 0.7, 0.6, bl + 0.4), Vector3(0.0, 3.6, 0.0), BRIDGE_RED)

	# Mid-bridge high-poly cover crate and pallet
	ArenaKit.pallet(geometry, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 15.0, 0.0))
	ArenaKit.crate(geometry, Vector3(0.0, 0.20, 0.0), Vector3(1.3, 1.3, 1.3), Vector3(0.0, 15.0, 0.0))


func _build_fort(team_idx: int, dir_z: float) -> void:
	var team_col := WOOD_BLUE if team_idx == 0 else WOOD_ORANGE
	var center_z := 20.0 * dir_z

	# 1. Fort Facade Wall (facing moat at Z = 7.2 * dir_z)
	var facade_z := 7.5 * dir_z
	var wall_h := 5.5
	# Left wing, Right wing, center doorway with high-poly arch
	ArenaKit.box(geometry, Vector3(9.0, wall_h, 0.8), Vector3(-8.5, wall_h * 0.5, facade_z), team_col, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(9.0, wall_h, 0.8), Vector3(8.5, wall_h * 0.5, facade_z), team_col, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.arch(geometry, Vector3(0.0, 0.0, facade_z), 7.2, wall_h, 1.2)

	# Battlement coping cornice along facade top
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, facade_z), Vector3(26.0, 0.35, 1.2))

	# 2. Upper Sniper Battlement / Balcony (Y = 3.4, Z = 11.0 * dir_z)
	var balc_z := 11.5 * dir_z
	var balc_w := 18.0
	var balc_d := 6.0
	# Balcony floor
	ArenaKit.box(geometry, Vector3(balc_w, 0.4, balc_d), Vector3(0.0, 3.2, balc_z), FLOOR_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Waist-high crenellated railing overlooking bridge
	ArenaKit.box(geometry, Vector3(balc_w, 1.1, 0.3), Vector3(0.0, 3.95, balc_z - 2.8 * dir_z), team_col)
	ArenaKit.crate(geometry, Vector3(balc_w * 0.5 - 2.0, 3.4, balc_z), Vector3(1.3, 1.3, 1.3))
	ArenaKit.barrel(geometry, Vector3(-balc_w * 0.5 + 2.0, 3.4, balc_z))

	# Stairs leading from courtyard up to sniper deck
	ArenaKit.ramp(geometry, Vector3(-7.5, 0.0, 15.0 * dir_z), Vector3(-7.5, 3.2, 12.0 * dir_z), 2.4, TIMBER)
	ArenaKit.ramp(geometry, Vector3(7.5, 0.0, 15.0 * dir_z), Vector3(7.5, 3.2, 12.0 * dir_z), 2.4, TIMBER)

	# 3. Fort Courtyard & Interior Corridors
	ArenaKit.box(geometry, Vector3(20.0, 0.4, 14.0), Vector3(0.0, -0.2, center_z), FLOOR_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Interior corridor walls
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 12.0), Vector3(-6.0, 2.0, center_z + 2.0 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 12.0), Vector3(6.0, 2.0, center_z + 2.0 * dir_z), team_col)

	# High-poly tactical crates and barrels in courtyard
	ArenaKit.crate(geometry, Vector3(-3.0, 0.0, center_z - 2.0 * dir_z), Vector3(1.5, 1.5, 1.5))
	ArenaKit.barrel(geometry, Vector3(3.0, 0.0, center_z + 1.0 * dir_z))

	# 4. Basement Intel Vault (Y = -2.2, Z = 27.0 * dir_z)
	var vault_z := 27.5 * dir_z
	# Vault floor
	ArenaKit.box(geometry, Vector3(16.0, 0.4, 12.0), Vector3(0.0, -2.4, vault_z), STONE)
	# Ramp down from courtyard into basement intel vault
	ArenaKit.ramp(geometry, Vector3(0.0, 0.0, 21.0 * dir_z), Vector3(0.0, -2.2, 24.5 * dir_z), 3.2, STONE)

	# Vault back wall and side walls
	ArenaKit.box(geometry, Vector3(16.0, 4.0, 0.8), Vector3(0.0, -0.2, vault_z + 5.5 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 12.0), Vector3(-7.6, -0.2, vault_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 12.0), Vector3(7.6, -0.2, vault_z), team_col)

	# Intel Desk in vault center
	ArenaKit.box(geometry, Vector3(3.0, 0.9, 1.8), Vector3(0.0, -1.75, vault_z + 1.5 * dir_z), TIMBER, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.crate(geometry, Vector3(-4.0, -2.2, vault_z + 2.0 * dir_z), Vector3(1.4, 1.4, 1.4))

	# Low-level water tunnel connecting moat to basement
	ArenaKit.box(geometry, Vector3(2.4, 0.4, 14.0), Vector3(-12.0 * (1.0 if team_idx == 0 else -1.0), -2.4, 15.0 * dir_z), STONE)


func _build_spawns_and_objectives() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(0.0, 0.0, -18.0)) # Blue Fort Base
	team_bases.append(Vector3(0.0, 0.0, 18.0))  # Orange Fort Base

	# Flag Pedestals (Secure basement intel desks!)
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(0.0, -2.2, -26.0)) # Blue Flag
	flag_pedestals.append(Vector3(0.0, -2.2, 26.0))  # Orange Flag

	# Bomb Sites
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(0.0, 3.4, -11.5) # Site A: Blue Upper Sniper Battlement
	bomb_sites["B"] = Vector3(0.0, 0.0, 0.0)    # Site B: Center Bridge Moat Choke

	# Spawns for 8 players/bots
	spawn_points.clear()
	roam_points.clear()
	var blue_spawns := [
		Vector3(-4.0, 0.0, -19.0), Vector3(4.0, 0.0, -19.0),
		Vector3(-2.0, 0.0, -22.0), Vector3(2.0, 0.0, -22.0),
	]
	var orange_spawns := [
		Vector3(-4.0, 0.0, 19.0), Vector3(4.0, 0.0, 19.0),
		Vector3(-2.0, 0.0, 22.0), Vector3(2.0, 0.0, 22.0),
	]
	for p in blue_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in orange_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Strategic Roam Points
	roam_points.append(Vector3(0.0, 0.0, 0.0))          # Mid bridge
	roam_points.append(Vector3(0.0, 3.4, -11.5))        # Blue sniper deck
	roam_points.append(Vector3(0.0, 3.4, 11.5))         # Orange sniper deck
	roam_points.append(Vector3(0.0, -2.2, -26.0))       # Blue intel vault
	roam_points.append(Vector3(0.0, -2.2, 26.0))        # Orange intel vault
	roam_points.append(Vector3(-16.0, -2.2, 0.0))       # West moat water
	roam_points.append(Vector3(16.0, -2.2, 0.0))        # East moat water
	roam_points.append(Vector3(0.0, 0.0, -15.0))        # Blue courtyard
	roam_points.append(Vector3(0.0, 0.0, 15.0))         # Orange courtyard

	# Power-up Spot (Center of Bridge)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.0, 0.0))

	# Ammo Buckets (Sniper battlements & basement intel rooms)
	add_bucket(Vector3(-6.0, 3.4, -11.5), Color(0.2, 0.5, 0.95))
	add_bucket(Vector3(6.0, 3.4, 11.5), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(5.0, -2.2, -26.0), Color(0.2, 0.5, 0.95))
	add_bucket(Vector3(-5.0, -2.2, 26.0), Color(0.95, 0.45, 0.15))

	# Shield Pickup in center bridge
	var shield := ShieldPickup.new()
	shield.position = Vector3(0.0, 0.6, 0.0)
	geometry.add_child(shield)
	shield_pickups.append(shield)
