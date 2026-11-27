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
	# Distant scenic grass skirt below map & safety bedrock under moat/vaults (top at Y = -2.6)
	ArenaKit.deco_box(decor, Vector3(300.0, 0.2, 300.0), Vector3(0.0, -2.7, 0.0), Color(0.30, 0.52, 0.24), Vector3.ZERO, 0.0, ArenaKit.SurfaceType.DEFAULT)
	ArenaKit.box(geometry, Vector3(HALF_X * 2.0, 1.0, HALF_Z * 2.0), Vector3(0.0, -3.1, 0.0), STONE, Vector3.ZERO, ArenaKit.SurfaceType.COBBLE)

	# Segmented surface terrain slabs (top at Y = 0.0, bottom at Y = -2.6) leaving the
	# Moat ([-18, 18] x [-7, 7]), both Basement Vaults ([-8, 8] x [±20.5, ±33.5]), and
	# both Water Tunnels (Blue: X -13.5..-10.5, Orange: X 10.5..13.5) completely open!
	var grass := Color(0.35, 0.60, 0.28)
	var slabs := [
		# East & West moat banks
		[Vector3(6.0, 2.6, 14.0), Vector3(-21.0, -1.3, 0.0)],
		[Vector3(6.0, 2.6, 14.0), Vector3(21.0, -1.3, 0.0)],
		# Blue Fort (North) surrounding terrain
		[Vector3(10.5, 2.6, 29.0), Vector3(-18.75, -1.3, -21.5)],
		[Vector3(16.0, 2.6, 29.0), Vector3(16.0, -1.3, -21.5)],
		[Vector3(18.5, 2.6, 13.5), Vector3(-1.25, -1.3, -13.75)],
		[Vector3(2.5, 2.6, 5.5), Vector3(-9.25, -1.3, -23.25)],
		[Vector3(5.5, 2.6, 7.0), Vector3(-10.75, -1.3, -32.5)],
		[Vector3(16.0, 2.6, 2.5), Vector3(0.0, -1.3, -34.75)],
		# Orange Fort (South) surrounding terrain
		[Vector3(10.5, 2.6, 29.0), Vector3(18.75, -1.3, 21.5)],
		[Vector3(16.0, 2.6, 29.0), Vector3(-16.0, -1.3, 21.5)],
		[Vector3(18.5, 2.6, 13.5), Vector3(1.25, -1.3, 13.75)],
		[Vector3(2.5, 2.6, 5.5), Vector3(9.25, -1.3, 23.25)],
		[Vector3(5.5, 2.6, 7.0), Vector3(10.75, -1.3, 32.5)],
		[Vector3(16.0, 2.6, 2.5), Vector3(0.0, -1.3, 34.75)],
	]
	var lawn_mat := ShaderMaterial.new()
	lawn_mat.shader = load("res://assets/materials/lawn.gdshader") as Shader
	lawn_mat.set_shader_parameter(&"color_a", Color(0.34, 0.62, 0.28))
	lawn_mat.set_shader_parameter(&"color_b", Color(0.26, 0.52, 0.22))
	for s in slabs:
		var slab_body := ArenaKit.box(geometry, s[0], s[1], grass, Vector3.ZERO, ArenaKit.SurfaceType.DEFAULT)
		for ch in slab_body.get_children():
			if ch is MeshInstance3D:
				(ch as MeshInstance3D).material_override = lawn_mat

	# Boundary walls with decorative coping cornices + invisible sky blockers
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

	# Invisible sky blockers above perimeter walls
	var sky_defs := [
		[Vector3(HALF_X * 2.0, 12.0, 1.0), Vector3(0.0, wall_h + 6.0, -HALF_Z)],
		[Vector3(HALF_X * 2.0, 12.0, 1.0), Vector3(0.0, wall_h + 6.0, HALF_Z)],
		[Vector3(1.0, 12.0, HALF_Z * 2.0), Vector3(-HALF_X, wall_h + 6.0, 0.0)],
		[Vector3(1.0, 12.0, HALF_Z * 2.0), Vector3(HALF_X, wall_h + 6.0, 0.0)],
	]
	for sd in sky_defs:
		var sb := StaticBody3D.new()
		sb.collision_layer = Layers.WORLD
		sb.collision_mask = 0
		sb.position = sd[1]
		var cs := CollisionShape3D.new()
		var box_s := BoxShape3D.new()
		box_s.size = sd[0]
		cs.shape = box_s
		sb.add_child(cs)
		geometry.add_child(sb)

	# Sunken Moat (Z between -7.0 and 7.0, X between -18.0 and 18.0, floor top at Y = -2.2)
	var moat_w := 14.0
	var moat_l := 36.0
	ArenaKit.box(geometry, Vector3(moat_l, 0.4, moat_w), Vector3(0.0, -2.4, 0.0), STONE)
	# Three cleanly sized stylized water puddles spanning the moat (no giant stretched cylinder)
	add_water_puddle(Vector3(-10.5, -2.18, 0.0), 5.8)
	add_water_puddle(Vector3(0.0, -2.18, 0.0), 5.8)
	add_water_puddle(Vector3(10.5, -2.18, 0.0), 5.8)

	# Ramps out of the moat on East and West banks (17.4 deg slope)
	ArenaKit.ramp(geometry, Vector3(-16.0, -2.2, 0.0), Vector3(-16.0, 0.0, -7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(-16.0, -2.2, 0.0), Vector3(-16.0, 0.0, 7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(16.0, -2.2, 0.0), Vector3(16.0, 0.0, -7.0), 3.2, TIMBER)
	ArenaKit.ramp(geometry, Vector3(16.0, -2.2, 0.0), Vector3(16.0, 0.0, 7.0), 3.2, TIMBER)

	# Scenic valley trees outside the fortress walls
	for tp in [
		Vector3(-32.0, -2.6, -24.0), Vector3(-34.0, -2.6, 0.0), Vector3(-31.0, -2.6, 22.0),
		Vector3(32.0, -2.6, -22.0), Vector3(34.0, -2.6, 2.0), Vector3(31.0, -2.6, 24.0),
		Vector3(-14.0, -2.6, -44.0), Vector3(14.0, -2.6, -44.0),
		Vector3(-14.0, -2.6, 44.0), Vector3(14.0, -2.6, 44.0),
	]:
		ArenaKit.tree(decor, tp, 1.35)


func _build_center_bridge() -> void:
	# Covered red wooden bridge connecting Blue and Orange forts across the moat
	var bw := 5.2
	var bl := 14.8
	# Bridge deck (top at +0.02 so it sits flush above moat lips with zero Z-fighting)
	ArenaKit.box(geometry, Vector3(bw, 0.4, bl), Vector3(0.0, -0.18, 0.0), BRIDGE_RED, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Bridge railings (waist-high solid barriers)
	ArenaKit.box(geometry, Vector3(0.3, 1.1, bl), Vector3(-bw * 0.5 + 0.15, 0.57, 0.0), TIMBER)
	ArenaKit.box(geometry, Vector3(0.3, 1.1, bl), Vector3(bw * 0.5 - 0.15, 0.57, 0.0), TIMBER)

	# Roof support posts
	for z_pos in [-6.0, -2.0, 2.0, 6.0]:
		ArenaKit.cylinder(geometry, 0.16, 3.2, Vector3(-bw * 0.5 + 0.15, 1.62, z_pos), TIMBER)
		ArenaKit.cylinder(geometry, 0.16, 3.2, Vector3(bw * 0.5 - 0.15, 1.62, z_pos), TIMBER)

	# Bridge pitched roof
	ArenaKit.deco_box(decor, Vector3(bw + 0.8, 0.3, bl + 0.4), Vector3(0.0, 3.22, 0.0), BRIDGE_RED)
	ArenaKit.deco_box(decor, Vector3(bw * 0.7, 0.6, bl + 0.4), Vector3(0.0, 3.62, 0.0), BRIDGE_RED)

	# Staggered bridge flank crates keeping center (0, 0, 0) open for Bomb Site B & Power-Up
	ArenaKit.crate(geometry, Vector3(-1.5, 0.02, -3.8), Vector3(1.1, 1.1, 1.1), Vector3(0.0, 12.0, 0.0))
	ArenaKit.crate(geometry, Vector3(1.5, 0.02, 3.8), Vector3(1.1, 1.1, 1.1), Vector3(0.0, -12.0, 0.0))


func _build_fort(team_idx: int, dir_z: float) -> void:
	var team_col := WOOD_BLUE if team_idx == 0 else WOOD_ORANGE
	var tun_side := -1.0 if team_idx == 0 else 1.0

	# 1. Fort Facade Wall (facing moat at Z = 7.5 * dir_z)
	var facade_z := 7.5 * dir_z
	var wall_h := 5.5
	# Center high-poly arch (7.2m outer span: X -3.6..+3.6)
	ArenaKit.arch(geometry, Vector3(0.0, 0.0, facade_z), 7.2, wall_h, 1.2)
	# Non-tunnel wing: X from 3.5 to 13.5 on (-tun_side)
	ArenaKit.box(geometry, Vector3(10.0, wall_h, 0.8), Vector3(-8.5 * tun_side, wall_h * 0.5, facade_z), team_col, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Tunnel-side wing: X from 3.5 to 10.5 on tun_side, plus high lintel over water canal (X 10.5..13.5)
	ArenaKit.box(geometry, Vector3(7.0, wall_h, 0.8), Vector3(7.0 * tun_side, wall_h * 0.5, facade_z), team_col, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.box(geometry, Vector3(3.4, 4.9, 0.8), Vector3(12.0 * tun_side, 3.05, facade_z), team_col, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Battlement coping cornice along facade top
	ArenaKit.cornice(decor, Vector3(0.0, wall_h + 0.15, facade_z), Vector3(27.0, 0.35, 1.2))

	# 2. Upper Sniper Battlement / Balcony (Y = 3.4, Z = 11.5 * dir_z, spanning Z = 8.5..14.5)
	var balc_z := 11.5 * dir_z
	var balc_w := 18.0
	var balc_d := 6.0
	ArenaKit.box(geometry, Vector3(balc_w, 0.4, balc_d), Vector3(0.0, 3.2, balc_z), FLOOR_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Waist-high crenellated railing overlooking bridge
	ArenaKit.box(geometry, Vector3(balc_w, 1.1, 0.3), Vector3(0.0, 3.95, balc_z - 2.8 * dir_z), team_col)
	ArenaKit.crate(geometry, Vector3(balc_w * 0.5 - 2.0, 3.4, balc_z), Vector3(1.3, 1.3, 1.3))
	ArenaKit.barrel(geometry, Vector3(-balc_w * 0.5 + 2.0, 3.4, balc_z))

	# Walkable 34-deg stairs from courtyard (Z = 19.5) flush up to sniper balcony back edge (Z = 14.5, Y = 3.4)
	ArenaKit.ramp(geometry, Vector3(-7.5, 0.02, 19.5 * dir_z), Vector3(-7.5, 3.4, 14.5 * dir_z), 2.4, TIMBER)
	ArenaKit.ramp(geometry, Vector3(7.5, 0.02, 19.5 * dir_z), Vector3(7.5, 3.4, 14.5 * dir_z), 2.4, TIMBER)

	# 3. Fort Courtyard Deck (Z = 7.5..20.5, top at +0.02 so zero Z-fighting and Vault stays open!)
	ArenaKit.box(geometry, Vector3(18.0, 0.04, 13.0), Vector3(-1.0 * tun_side, 0.0, 14.0 * dir_z), FLOOR_WOOD, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	# Interior corridor walls flanking courtyard
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 8.0), Vector3(-6.0, 2.0, 17.0 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 8.0), Vector3(6.0, 2.0, 17.0 * dir_z), team_col)

	# Courtyard cover crates/barrels clear of spawn points
	ArenaKit.crate(geometry, Vector3(-3.2, 0.02, 14.5 * dir_z), Vector3(1.4, 1.4, 1.4))
	ArenaKit.barrel(geometry, Vector3(3.2, 0.02, 15.0 * dir_z))

	# 4. Basement Intel Vault (top Y = -2.2, X: -8..8, Z: 20.5..33.5)
	var vault_z := 27.0 * dir_z
	ArenaKit.box(geometry, Vector3(16.0, 0.4, 13.0), Vector3(0.0, -2.4, vault_z), STONE)
	# Smooth 28.8-deg ramp down from courtyard edge (Z = 20.5, Y = 0.02) into basement vault (Z = 24.5, Y = -2.2)
	ArenaKit.ramp(geometry, Vector3(0.0, 0.02, 20.5 * dir_z), Vector3(0.0, -2.2, 24.5 * dir_z), 3.4, STONE)

	# Vault back wall and side walls (tunnel side split at Z = 26..29 for water-tunnel doorway!)
	ArenaKit.box(geometry, Vector3(16.0, 4.0, 0.8), Vector3(0.0, -0.2, 33.1 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 13.0), Vector3(-7.6 * tun_side, -0.2, vault_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 5.5), Vector3(7.6 * tun_side, -0.2, 23.25 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 4.0, 4.5), Vector3(7.6 * tun_side, -0.2, 31.25 * dir_z), team_col)
	ArenaKit.box(geometry, Vector3(0.8, 1.6, 3.0), Vector3(7.6 * tun_side, 1.0, 27.5 * dir_z), team_col)

	# Intel Desk behind Flag Pedestal so flag pad at Z = 26.5 is wide open
	ArenaKit.box(geometry, Vector3(3.0, 0.9, 1.6), Vector3(0.0, -1.75, 30.2 * dir_z), TIMBER, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.crate(geometry, Vector3(-4.2, -2.2, 29.5 * dir_z), Vector3(1.4, 1.4, 1.4))

	# Warm lantern lighting inside each Basement Intel Vault
	var vault_light := OmniLight3D.new()
	vault_light.position = Vector3(0.0, 0.8, vault_z)
	vault_light.light_color = Color(1.0, 0.85, 0.58)
	vault_light.light_energy = 2.4
	vault_light.omni_range = 16.0
	decor.add_child(vault_light)

	# Open Water Tunnel canal connecting Moat (Z = 7.0) straight to Vault elbow (Z = 27.5)
	ArenaKit.box(geometry, Vector3(3.0, 0.4, 22.0), Vector3(12.0 * tun_side, -2.4, 18.0 * dir_z), STONE)
	ArenaKit.box(geometry, Vector3(4.0, 0.4, 3.0), Vector3(9.5 * tun_side, -2.4, 27.5 * dir_z), STONE)
	add_water_puddle(Vector3(12.0 * tun_side, -2.18, 16.0 * dir_z), 2.4)


func _build_spawns_and_objectives() -> void:
	# Team bases
	team_bases.clear()
	team_bases.append(Vector3(0.0, 0.02, -16.5)) # Blue Fort Base
	team_bases.append(Vector3(0.0, 0.02, 16.5))  # Orange Fort Base

	# Flag Pedestals (Secure basement intel rooms!)
	flag_pedestals.clear()
	flag_pedestals.append(Vector3(0.0, -2.2, -26.8)) # Blue Flag
	flag_pedestals.append(Vector3(0.0, -2.2, 26.8))  # Orange Flag

	# Bomb Sites & Spawn
	bomb_sites.clear()
	bomb_sites["A"] = Vector3(0.0, 3.4, -11.5)  # Site A: Blue Upper Sniper Battlement
	bomb_sites["B"] = Vector3(0.0, 0.02, 0.0)   # Site B: Center Bridge Moat Choke
	bomb_spawns.clear()
	bomb_spawns.append(Vector3(0.0, 0.02, 15.5))

	# Spawns for 8 players/bots (all grounded safely on courtyard deck)
	spawn_points.clear()
	roam_points.clear()
	var blue_spawns := [
		Vector3(-4.2, 0.02, -10.5), Vector3(4.2, 0.02, -10.5),
		Vector3(-3.5, 0.02, -18.5), Vector3(3.5, 0.02, -18.5),
	]
	var orange_spawns := [
		Vector3(-4.2, 0.02, 10.5), Vector3(4.2, 0.02, 10.5),
		Vector3(-3.5, 0.02, 18.5), Vector3(3.5, 0.02, 18.5),
	]
	for p in blue_spawns:
		add_spawn(p, Vector3(0.0, 0.0, 1.0))
	for p in orange_spawns:
		add_spawn(p, Vector3(0.0, 0.0, -1.0))

	# Strategic Roam Points
	roam_points.append(Vector3(0.0, 0.02, 0.0))          # Mid bridge
	roam_points.append(Vector3(0.0, 3.4, -11.5))         # Blue sniper deck
	roam_points.append(Vector3(0.0, 3.4, 11.5))          # Orange sniper deck
	roam_points.append(Vector3(0.0, -2.2, -26.8))        # Blue intel vault
	roam_points.append(Vector3(0.0, -2.2, 26.8))         # Orange intel vault
	roam_points.append(Vector3(-12.0, -2.2, -16.0))      # Blue water tunnel
	roam_points.append(Vector3(12.0, -2.2, 16.0))        # Orange water tunnel
	roam_points.append(Vector3(-16.0, -2.2, 0.0))        # West moat ramp
	roam_points.append(Vector3(16.0, -2.2, 0.0))         # East moat ramp
	roam_points.append(Vector3(0.0, 0.02, -14.0))        # Blue courtyard
	roam_points.append(Vector3(0.0, 0.02, 14.0))         # Orange courtyard

	# Power-up Spot (Center of Bridge)
	power_up_spots.clear()
	power_up_spots.append(Vector3(0.0, 0.02, 0.0))

	# Ammo Buckets (Sniper battlements & basement intel rooms)
	add_bucket(Vector3(-6.0, 3.4, -11.5), Color(0.2, 0.5, 0.95))
	add_bucket(Vector3(6.0, 3.4, 11.5), Color(0.95, 0.45, 0.15))
	add_bucket(Vector3(5.0, -2.2, -26.5), Color(0.2, 0.5, 0.95))
	add_bucket(Vector3(-5.0, -2.2, 26.5), Color(0.95, 0.45, 0.15))

	# Shield Pickup tucked under the center bridge in the moat
	add_shield_pickup(Vector3(0.0, -2.2, 0.0))
