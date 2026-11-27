class_name WhirlwindVortex
extends Node3D
## A playful, swirling cartoon dust devil / gale whirlwind that sweeps across
## the arena during Gale Gust weather events. It curves nearby darts and launches
## any player or bot who leaps into it high into the air!

signal actor_launched(actor: Actor)

const RADIUS := 3.2
const HEIGHT := 7.0
const LAUNCH_FORCE := 14.5
const COOLDOWN_TIME := 1.2

var drift_velocity: Vector3 = Vector3.ZERO
var target_roam_points: Array[Vector3] = []
var target_index: int = 0
var life_time: float = 24.0

var _area: Area3D
var _wind_zone: WindZone
var _rings: Array[MeshInstance3D] = []
var _time: float = 0.0
var _actor_cooldowns: Dictionary = {}


func _ready() -> void:
	add_to_group(&"whirlwinds")
	_build_visuals()
	_setup_area()
	_setup_wind_zone()


func _build_visuals() -> void:
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(0.85, 0.95, 0.9, 0.35)
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var tiers: Array[Dictionary] = [
		{"y": 0.5, "r": 1.2, "h": 0.25},
		{"y": 1.8, "r": 1.8, "h": 0.3},
		{"y": 3.4, "r": 2.5, "h": 0.35},
		{"y": 5.2, "r": 3.2, "h": 0.4},
	]

	for tier in tiers:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = (tier["r"] as float) * 0.8
		torus.outer_radius = tier["r"] as float
		ring.mesh = torus
		ring.material_override = ring_mat
		ring.position.y = tier["y"] as float
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)


func _setup_area() -> void:
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.ACTORS
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT
	col.shape = shape
	col.position.y = HEIGHT * 0.5
	_area.add_child(col)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)


func _setup_wind_zone() -> void:
	_wind_zone = WindZone.new()
	_wind_zone.direction = Vector3.UP
	_wind_zone.strength = 18.0
	_wind_zone.size = Vector3(RADIUS * 2.0, HEIGHT, RADIUS * 2.0)
	_wind_zone.show_fan = false
	_wind_zone.show_windsock = false
	_wind_zone.show_volume = false
	add_child(_wind_zone)


func _physics_process(delta: float) -> void:
	_time += delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()
		return

	# Animate spiraling rings
	for i in _rings.size():
		var ring := _rings[i]
		ring.rotation.y += (4.0 + float(i) * 1.5) * delta
		ring.position.y += sin(_time * 4.0 + float(i)) * 0.05 * delta
		var scale_pulse := 1.0 + sin(_time * 5.0 + float(i) * 1.2) * 0.06
		ring.scale = Vector3(scale_pulse, 1.0, scale_pulse)

	# Steer toward next roam target if provided
	if not target_roam_points.is_empty():
		var target := target_roam_points[target_index]
		var to_target := target - global_position
		to_target.y = 0.0
		if to_target.length_squared() < 2.0:
			target_index = (target_index + 1) % target_roam_points.size()
		else:
			drift_velocity = to_target.normalized() * 3.5
	global_position += drift_velocity * delta

	# Tick cooldowns
	for key in _actor_cooldowns.keys():
		var remaining: float = float(_actor_cooldowns[key]) - delta
		if remaining <= 0.0 or not is_instance_valid(key as Object):
			_actor_cooldowns.erase(key)
		else:
			_actor_cooldowns[key] = remaining

	# Launch any occupying bodies
	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive:
			_launch_actor(actor)


func _on_body_entered(body: Node3D) -> void:
	var actor := body as Actor
	if actor != null and actor.alive:
		_launch_actor(actor)


func _launch_actor(actor: Actor) -> void:
	if actor == null or not actor.alive or actor.is_tagged_out:
		return
	if _actor_cooldowns.has(actor):
		return
	_actor_cooldowns[actor] = COOLDOWN_TIME

	# Upward spring launch with gentle outward fling
	var outward := (actor.global_position - global_position).normalized()
	outward.y = 0.0
	actor.velocity.y = maxf(actor.velocity.y + LAUNCH_FORCE, LAUNCH_FORCE)
	actor.velocity += outward * 5.0

	Sfx.play_at(&"tornado_whirl", global_position, 1.1, -1.0)
	actor_launched.emit(actor)
