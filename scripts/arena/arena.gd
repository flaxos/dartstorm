class_name Arena
extends Node3D
## Base class for every arena. An arena supplies:
##   * `geometry`     a NavigationRegion3D holding all solid, walkable pieces
##   * `decor`        visual-only pieces (no collision, ignored by navigation)
##   * `wind_field`   the arena's WindField
##   * `spawn_points` where actors appear
##   * `roam_points`  interesting places for bots to wander to
##   * `buckets`      its AmmoBuckets
## Subclasses override _build() and call the add_* helpers. The match scene only
## talks to this interface, so new elemental arenas drop straight in.

const WIND_ZONE_SCENE := preload("res://scenes/effects/wind_zone.tscn")
const REFLECTIVE_SCENE := preload("res://scenes/effects/reflective_surface.tscn")
const AMMO_BUCKET_SCENE := preload("res://scenes/pickups/ammo_bucket.tscn")
const JUMP_PAD_SCENE := preload("res://scenes/pickups/jump_pad.tscn")
const TARGET_SCENE := preload("res://scenes/effects/wobble_target.tscn")

@export var arena_name: String = "Arena"
## The main menu shows the arena as a backdrop and skips the navmesh bake.
@export var bake_navigation: bool = true

## Emitted once the navmesh bake finishes. Bots steer in straight lines until
## then, so matches can start before it's done.
signal navigation_ready

var is_navigation_ready: bool = false
var geometry: NavigationRegion3D
var decor: Node3D
var wind_field: WindField
var spawn_points: Array[Marker3D] = []
var roam_points: Array[Vector3] = []
## Where a power-up blaster (the Chainstorm in power-up mode) appears.
var power_up_spots: Array[Vector3] = []
var buckets: Array[AmmoBucket] = []
## Each team's home end, by team number (0 blue, 1 orange). Team modes respawn
## players at the end nearest their own base.
var team_bases: Array[Vector3] = []
## Flag pedestals for Capture The Flag (0 Blue, 1 Orange). Falls back to team_bases.
var flag_pedestals: Array[Vector3] = []
## Bomb sites for Plant The Bomb ("A": Vector3, "B": Vector3).
var bomb_sites: Dictionary = {}
## Where the bomb spawns for Attackers (falls back to team_bases[1] or spawn).
var bomb_spawns: Array[Vector3] = []
var shield_pickups: Array[ShieldPickup] = []
var puddles: Array[WaterPuddle] = []
var ice_slicks: Array[IceSlick] = []
var vents: Array[WindVent] = []
var lava_hazard: LavaHazard = null
var grenade_pickups: Array[GrenadePickup] = []
var elemental_pickups: Array[ElementalPickup] = []
var weather_director: Node = null
var world_environment: WorldEnvironment = null
var sun_light: DirectionalLight3D = null

var _spawn_root: Node3D
var _clouds: Node3D


func _ready() -> void:
	wind_field = WindField.new()
	wind_field.name = "WindField"
	add_child(wind_field)
	geometry = NavigationRegion3D.new()
	geometry.name = "Geometry"
	add_child(geometry)
	decor = Node3D.new()
	decor.name = "Decor"
	add_child(decor)
	_spawn_root = Node3D.new()
	_spawn_root.name = "Spawns"
	add_child(_spawn_root)
	_build()
	if bake_navigation:
		_bake_navigation()


## Override to construct the arena.
func _build() -> void:
	pass


## Clouds drift slowly across the sky. Subclasses that override _process call super(delta).
func _process(delta: float) -> void:
	if _clouds == null:
		return
	for cloud: Node3D in _clouds.get_children():
		cloud.position.x += delta * 0.8
		if cloud.position.x > 150.0:
			cloud.position.x = -150.0


## Curated per-arena atmosphere & sky lighting: AgX tonemapping, SSIL color bounce,
## ReflectionProbe IBL, volumetric sun-haze on Forward+, and clean depth fog on Web/Mobile.
func _build_sky_and_sun(sun_pitch: float = -52.0, warm_fill: float = 0.0) -> void:
	var preset := _atmosphere_preset(sun_pitch, warm_fill)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = preset["sky_top"]
	sky_material.sky_horizon_color = preset["sky_horizon"]
	sky_material.ground_horizon_color = preset["ground_horizon"]
	sky_material.ground_bottom_color = preset["ground_bottom"]
	sky_material.sun_angle_max = preset["sun_angle_max"]
	sky_material.sun_curve = preset["sun_curve"]
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = preset["ambient_energy"]
	var eff_warm: float = preset["warm_fill"]
	if eff_warm > 0.0:
		environment.ambient_light_color = preset["ambient_color"]
		environment.ambient_light_sky_contribution = 1.0 - eff_warm
		environment.ambient_light_energy = preset["ambient_energy"] + eff_warm * 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = preset["exposure"]
	environment.adjustment_enabled = true
	environment.adjustment_contrast = preset["contrast"]
	environment.adjustment_saturation = preset["saturation"]
	environment.glow_enabled = true
	environment.glow_intensity = preset["glow_intensity"]
	environment.glow_bloom = preset["glow_bloom"]
	environment.glow_hdr_threshold = 1.15
	# Forward+ / Vulkan gets SSAO + SSIL bounce lighting + Volumetric Sun Haze + ReflectionProbe.
	# Compatibility (WebGL2 / OpenGL ES3) gets clean depth fog so it stays warning-free and atmospheric.
	if RenderingServer.get_rendering_device() != null:
		environment.ssao_enabled = true
		environment.ssao_radius = 1.4
		environment.ssao_intensity = 1.55
		environment.ssao_detail = 0.65
		environment.ssil_enabled = true
		environment.ssil_radius = 4.2
		environment.ssil_intensity = 0.78
		environment.ssil_normal_rejection = 1.0
		environment.ssr_enabled = false
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_density = preset["vol_fog_density"]
		environment.volumetric_fog_albedo = preset["vol_fog_albedo"]
		environment.volumetric_fog_ambient_inject = 0.14
		var probe := ReflectionProbe.new()
		probe.name = "ArenaReflectionProbe"
		probe.size = Vector3(115.0, 48.0, 115.0)
		probe.position = Vector3(0.0, 8.0, 0.0)
		probe.intensity = 0.65
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
		add_child(probe)
	else:
		environment.fog_enabled = true
		environment.fog_mode = Environment.FOG_MODE_DEPTH
		environment.fog_light_color = preset["vol_fog_albedo"]
		environment.fog_light_energy = 0.85
		environment.fog_depth_begin = 36.0
		environment.fog_depth_end = 155.0

	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(preset["sun_pitch"], preset["sun_yaw"], 0.0)
	sun_light.light_energy = preset["sun_energy"]
	sun_light.light_color = preset["sun_color"]
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 1.5
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_split_1 = 0.08
	sun_light.directional_shadow_split_2 = 0.22
	sun_light.directional_shadow_split_3 = 0.55
	sun_light.directional_shadow_blend_splits = true
	sun_light.directional_shadow_fade_start = 0.85
	sun_light.directional_shadow_max_distance = 130.0
	sun_light.shadow_bias = 0.02
	sun_light.shadow_normal_bias = 1.2
	add_child(sun_light)

	_clouds = Node3D.new()
	_clouds.name = "Clouds"
	decor.add_child(_clouds)
	var cloud_tint: Color = preset["cloud_color"]
	var cloud_mat := ArenaKit.toon_mat(cloud_tint, 0.90, 0.05, 0.0, false, Color(0.52, 0.66, 0.94))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 14:
		var cloud := Node3D.new()
		cloud.position = Vector3(rng.randf_range(-150.0, 150.0), rng.randf_range(44.0, 62.0), rng.randf_range(-120.0, 120.0))
		_clouds.add_child(cloud)
		for puff in 5:
			var radius := rng.randf_range(4.2, 8.2)
			var offset := Vector3(rng.randf_range(-8.5, 8.5), rng.randf_range(-1.0, 1.8), rng.randf_range(-4.5, 4.5))
			var ball := ArenaKit.deco_sphere(cloud, radius, offset, cloud_tint, 0.56, 0.0)
			ball.material_override = cloud_mat
			ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _atmosphere_preset(default_pitch: float, default_warm: float) -> Dictionary:
	var n := arena_name.to_lower()
	# 1. Soccer Stadium: Dramatic Twilight Floodlit Stadium!
	if "soccer" in n:
		return {
			"sky_top": Color(0.03, 0.07, 0.22),
			"sky_horizon": Color(0.22, 0.34, 0.62),
			"ground_horizon": Color(0.16, 0.20, 0.34),
			"ground_bottom": Color(0.08, 0.14, 0.12),
			"sun_angle_max": 28.0,
			"sun_curve": 0.07,
			"sun_pitch": -20.0,
			"sun_yaw": 48.0,
			"sun_energy": 0.72,
			"sun_color": Color(0.95, 0.88, 0.78),
			"ambient_energy": 0.68,
			"ambient_color": Color(0.68, 0.78, 1.0),
			"warm_fill": 0.12,
			"exposure": 1.06,
			"contrast": 1.07,
			"saturation": 1.16,
			"glow_intensity": 0.36,
			"glow_bloom": 0.07,
			"vol_fog_density": 0.0038,
			"vol_fog_albedo": Color(0.45, 0.58, 0.82),
			"cloud_color": Color(0.76, 0.82, 0.96),
		}
	# 2. Dust 1 / Dust 2: Scorching Desert Amber with sandy ground bounce
	if "dust" in n:
		return {
			"sky_top": Color(0.14, 0.38, 0.84),
			"sky_horizon": Color(0.96, 0.76, 0.52),
			"ground_horizon": Color(0.84, 0.68, 0.46),
			"ground_bottom": Color(0.72, 0.56, 0.36),
			"sun_angle_max": 28.0,
			"sun_curve": 0.07,
			"sun_pitch": default_pitch,
			"sun_yaw": 34.0,
			"sun_energy": 1.24,
			"sun_color": Color(1.0, 0.92, 0.76),
			"ambient_energy": 0.78,
			"ambient_color": Color(1.0, 0.88, 0.70),
			"warm_fill": maxf(default_warm, 0.22),
			"exposure": 1.02,
			"contrast": 1.06,
			"saturation": 1.14,
			"glow_intensity": 0.24,
			"glow_bloom": 0.03,
			"vol_fog_density": 0.0046,
			"vol_fog_albedo": Color(0.98, 0.84, 0.64),
			"cloud_color": Color(1.0, 0.94, 0.84),
		}
	# 3. Tempest Treehouse: Canopy Forest Sunbeams
	if "treehouse" in n or "tempest" in n:
		return {
			"sky_top": Color(0.18, 0.48, 0.88),
			"sky_horizon": Color(0.76, 0.88, 0.78),
			"ground_horizon": Color(0.46, 0.66, 0.44),
			"ground_bottom": Color(0.20, 0.42, 0.20),
			"sun_angle_max": 26.0,
			"sun_curve": 0.08,
			"sun_pitch": -42.0,
			"sun_yaw": 42.0,
			"sun_energy": 1.18,
			"sun_color": Color(1.0, 0.95, 0.82),
			"ambient_energy": 0.82,
			"ambient_color": Color(0.92, 0.98, 0.86),
			"warm_fill": maxf(default_warm, 0.14),
			"exposure": 1.04,
			"contrast": 1.05,
			"saturation": 1.18,
			"glow_intensity": 0.26,
			"glow_bloom": 0.04,
			"vol_fog_density": 0.0052,
			"vol_fog_albedo": Color(0.90, 0.96, 0.84),
			"cloud_color": Color(0.98, 1.0, 0.97),
		}
	# 4. Two Fortresses: Crisp Alpine Valley Morning
	if "fortress" in n and "two" in n:
		return {
			"sky_top": Color(0.16, 0.44, 0.90),
			"sky_horizon": Color(0.84, 0.90, 0.96),
			"ground_horizon": Color(0.64, 0.72, 0.62),
			"ground_bottom": Color(0.26, 0.48, 0.24),
			"sun_angle_max": 22.0,
			"sun_curve": 0.09,
			"sun_pitch": default_pitch,
			"sun_yaw": 36.0,
			"sun_energy": 1.16,
			"sun_color": Color(1.0, 0.96, 0.90),
			"ambient_energy": 0.84,
			"ambient_color": Color(0.96, 0.94, 0.88),
			"warm_fill": maxf(default_warm, 0.10),
			"exposure": 1.03,
			"contrast": 1.05,
			"saturation": 1.16,
			"glow_intensity": 0.22,
			"glow_bloom": 0.03,
			"vol_fog_density": 0.0032,
			"vol_fog_albedo": Color(0.90, 0.93, 0.96),
			"cloud_color": Color(1.0, 1.0, 1.0),
		}
	# 5. Home Turf: Warm Sunlit Dollhouse / Indoor-Outdoor Blend
	if "home" in n:
		return {
			"sky_top": Color(0.22, 0.48, 0.90),
			"sky_horizon": Color(0.94, 0.82, 0.68),
			"ground_horizon": Color(0.76, 0.70, 0.58),
			"ground_bottom": Color(0.32, 0.54, 0.26),
			"sun_angle_max": 24.0,
			"sun_curve": 0.08,
			"sun_pitch": default_pitch,
			"sun_yaw": 40.0,
			"sun_energy": 1.10,
			"sun_color": Color(1.0, 0.94, 0.84),
			"ambient_energy": 0.86,
			"ambient_color": Color(1.0, 0.92, 0.80),
			"warm_fill": maxf(default_warm, 0.34),
			"exposure": 1.04,
			"contrast": 1.04,
			"saturation": 1.15,
			"glow_intensity": 0.22,
			"glow_bloom": 0.03,
			"vol_fog_density": 0.0024,
			"vol_fog_albedo": Color(0.98, 0.92, 0.84),
			"cloud_color": Color(1.0, 0.98, 0.95),
		}
	# Default (Backyard Fortress, Sunny Park, Playground): Vibrant Cover-Art Golden Afternoon
	return {
		"sky_top": Color(0.15, 0.50, 0.96),
		"sky_horizon": Color(0.92, 0.84, 0.72),
		"ground_horizon": Color(0.72, 0.76, 0.58),
		"ground_bottom": Color(0.28, 0.54, 0.24),
		"sun_angle_max": 28.0,
		"sun_curve": 0.08,
		"sun_pitch": default_pitch,
		"sun_yaw": 38.0,
		"sun_energy": 1.24,
		"sun_color": Color(1.0, 0.95, 0.84),
		"ambient_energy": 0.92,
		"ambient_color": Color(0.98, 0.94, 0.84),
		"warm_fill": maxf(default_warm, 0.18),
		"exposure": 1.06,
		"contrast": 1.06,
		"saturation": 1.20,
		"glow_intensity": 0.26,
		"glow_bloom": 0.04,
		"vol_fog_density": 0.0024,
		"vol_fog_albedo": Color(0.96, 0.92, 0.82),
		"cloud_color": Color(1.0, 0.99, 0.97),
	}


func add_spawn(at: Vector3, facing: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.position = at
	_spawn_root.add_child(marker)
	var look := Vector3(facing.x, at.y, facing.z)
	if look.distance_squared_to(at) > 0.01:
		marker.look_at(look, Vector3.UP)
	spawn_points.append(marker)
	roam_points.append(at)
	return marker


func add_roam_point(at: Vector3) -> void:
	roam_points.append(at)


func add_power_up_spot(at: Vector3) -> void:
	power_up_spots.append(at)


func add_bucket(at: Vector3, tint: Color = Color(0.95, 0.75, 0.2), capacity: int = 150) -> AmmoBucket:
	var bucket := AMMO_BUCKET_SCENE.instantiate() as AmmoBucket
	bucket.position = at
	bucket.bucket_color = tint
	bucket.capacity = capacity
	geometry.add_child(bucket)
	buckets.append(bucket)
	roam_points.append(at + Vector3(1.2, 0.0, 0.0))
	return bucket


func get_flag_pedestal(team: int) -> Vector3:
	if team >= 0 and team < flag_pedestals.size():
		return flag_pedestals[team]
	if team >= 0 and team < team_bases.size():
		return team_bases[team]
	return Vector3(-14.0, 0.0, 0.0) if team == 0 else Vector3(14.0, 0.0, 0.0)


func get_bomb_site_pos(site_id: String) -> Vector3:
	if bomb_sites.has(site_id):
		return bomb_sites[site_id]
	if not bomb_sites.is_empty():
		return bomb_sites.values()[0]
	return Vector3(0.0, 0.0, -12.0) if site_id == "A" else Vector3(0.0, 0.0, 12.0)


func add_wind_zone(centre: Vector3, zone_size: Vector3, direction: Vector3, strength: float,
		show_volume: bool = true) -> WindZone:
	var zone := WIND_ZONE_SCENE.instantiate() as WindZone
	zone.show_volume = show_volume
	zone.position = centre
	zone.size = zone_size
	zone.direction = direction
	zone.strength = strength
	add_child(zone)
	return zone


## Adds a mirror panel. It faces +Z before `yaw_degrees` is applied.
func add_mirror(centre: Vector3, yaw_degrees: float, panel_size: Vector2, legs: float = 0.0) -> ReflectiveSurface:
	var mirror := REFLECTIVE_SCENE.instantiate() as ReflectiveSurface
	mirror.position = centre
	mirror.rotation_degrees.y = yaw_degrees
	mirror.panel_size = panel_size
	mirror.leg_length = legs
	geometry.add_child(mirror)
	return mirror


func add_jump_pad(at: Vector3, launch_speed: float = 15.5) -> JumpPad:
	var pad := JUMP_PAD_SCENE.instantiate() as JumpPad
	pad.position = at
	pad.launch_speed = launch_speed
	add_child(pad)
	return pad


func add_target(at: Vector3, yaw_degrees: float) -> WobbleTarget:
	var target := TARGET_SCENE.instantiate() as WobbleTarget
	target.position = at
	target.rotation_degrees.y = yaw_degrees
	add_child(target)
	return target


func add_shield_pickup(at: Vector3) -> ShieldPickup:
	var pickup := ShieldPickup.new()
	pickup.position = at
	add_child(pickup)
	shield_pickups.append(pickup)
	roam_points.append(at)
	return pickup


func add_grenade_pickup(at: Vector3) -> GrenadePickup:
	var pickup := GrenadePickup.new()
	pickup.position = at
	add_child(pickup)
	grenade_pickups.append(pickup)
	roam_points.append(at)
	return pickup


func add_elemental_pickup(at: Vector3, p_element: DartData.Element = DartData.Element.FIRE) -> ElementalPickup:
	var pickup := ElementalPickup.new()
	pickup.element = p_element
	pickup.position = at
	add_child(pickup)
	elemental_pickups.append(pickup)
	roam_points.append(at)
	return pickup


func add_water_puddle(at: Vector3, radius: float = 2.5) -> WaterPuddle:
	var puddle := WaterPuddle.new()
	puddle.position = at
	puddle.radius = radius
	add_child(puddle)
	puddles.append(puddle)
	return puddle


func add_ice_slick(at: Vector3, size: Vector3, slope_dir: Vector3 = Vector3(0.0, 0.0, 1.0), rot_deg: Vector3 = Vector3.ZERO) -> IceSlick:
	var slick := IceSlick.new()
	slick.position = at
	slick.size = size
	slick.slide_direction = slope_dir
	slick.rotation_degrees = rot_deg
	add_child(slick)
	ice_slicks.append(slick)
	return slick


func add_wind_vent(at: Vector3, radius: float = 1.6, lift: float = 14.0) -> WindVent:
	var vent := WindVent.new()
	vent.position = at
	vent.radius = radius
	vent.lift_velocity = lift
	add_child(vent)
	vents.append(vent)
	return vent


## Bakes a navmesh for bots from every static collider under `geometry`.
## The heavy part runs on a worker thread so loading a match doesn't hitch.
func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.75
	mesh.agent_max_climb = 0.5
	mesh.agent_max_slope = 40.0
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers.WORLD
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	geometry.navigation_mesh = mesh
	geometry.bake_finished.connect(_on_bake_finished, CONNECT_ONE_SHOT)
	geometry.bake_navigation_mesh(true)


func _on_bake_finished() -> void:
	is_navigation_ready = true
	navigation_ready.emit()
