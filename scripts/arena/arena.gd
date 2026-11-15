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
var buckets: Array[AmmoBucket] = []

var _spawn_root: Node3D


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


func add_bucket(at: Vector3, tint: Color, capacity: int = 150) -> AmmoBucket:
	var bucket := AMMO_BUCKET_SCENE.instantiate() as AmmoBucket
	bucket.position = at
	bucket.bucket_color = tint
	bucket.capacity = capacity
	geometry.add_child(bucket)
	buckets.append(bucket)
	roam_points.append(at + Vector3(1.2, 0.0, 0.0))
	return bucket


func add_wind_zone(centre: Vector3, zone_size: Vector3, direction: Vector3, strength: float) -> WindZone:
	var zone := WIND_ZONE_SCENE.instantiate() as WindZone
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
