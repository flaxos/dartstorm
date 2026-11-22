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
var shield_pickups: Array[ShieldPickup] = []
var puddles: Array[WaterPuddle] = []
var ice_slicks: Array[IceSlick] = []
var vents: Array[WindVent] = []
var lava_hazard: LavaHazard = null
var grenade_pickups: Array[GrenadePickup] = []
var elemental_pickups: Array[ElementalPickup] = []
var weather_director: Node = null

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


## The shared sunny sky: procedural sky, a warm sun with shadows, gentle glow, and puffy clouds.
## `sun_pitch` is the sun's angle below the horizon line (more negative = higher
## sun, shorter shadows). `warm_fill` (0..1) swaps some of the sky's blue fill
## light for warm light, so shaded areas (indoors) don't look cold.
func _build_sky_and_sun(sun_pitch: float = -52.0, warm_fill: float = 0.0) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.20, 0.44, 0.88)
	sky_material.sky_horizon_color = Color(0.86, 0.74, 0.62)
	sky_material.ground_horizon_color = Color(0.72, 0.68, 0.58)
	sky_material.ground_bottom_color = Color(0.28, 0.48, 0.24)
	sky_material.sun_angle_max = 24.0
	sky_material.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0
	if warm_fill > 0.0:
		environment.ambient_light_color = Color(1.0, 0.9, 0.78)
		environment.ambient_light_sky_contribution = 1.0 - warm_fill
		environment.ambient_light_energy = 1.0 + warm_fill * 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.10
	environment.adjustment_saturation = 1.18
	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 1.0
	# SSAO, SSR and Volumetric Fog require a RenderingDevice (Forward+ / Mobile Vulkan).
	# Guard them so the Compatibility (WebGL2 / OpenGL ES3) renderer stays warning-free.
	if RenderingServer.get_rendering_device() != null:
		environment.ssao_enabled = true
		environment.ssao_radius = 1.5
		environment.ssao_intensity = 2.0
		environment.ssao_detail = 0.65
		environment.ssr_enabled = true
		environment.ssr_max_steps = 48
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_density = 0.005
		environment.volumetric_fog_albedo = Color(0.96, 0.90, 0.80)
		environment.volumetric_fog_ambient_inject = 0.15
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(sun_pitch, 38.0, 0.0)
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.22
	sun.directional_shadow_split_3 = 0.55
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.85
	sun.directional_shadow_max_distance = 120.0
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 1.2
	add_child(sun)

	_clouds = Node3D.new()
	_clouds.name = "Clouds"
	decor.add_child(_clouds)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 10:
		var cloud := Node3D.new()
		cloud.position = Vector3(rng.randf_range(-150.0, 150.0), rng.randf_range(42.0, 60.0), rng.randf_range(-120.0, 120.0))
		_clouds.add_child(cloud)
		for puff in 4:
			var radius := rng.randf_range(4.0, 7.5)
			var offset := Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(-1.0, 1.5), rng.randf_range(-4.0, 4.0))
			var ball := ArenaKit.deco_sphere(cloud, radius, offset, Color(1.0, 1.0, 1.0), 0.6, 0.35)
			ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
