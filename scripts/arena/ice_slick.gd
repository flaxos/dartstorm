class_name IceSlick
extends Node3D
## A frosty frictionless ice hazard on ramps and slides.
## Stepping onto it triggers an instant slide-boost along its slope vector.
## Fire darts temporarily melt it into steam before it refreezes!

signal melted(slick: IceSlick)
signal refrozen(slick: IceSlick)

@export var size: Vector3 = Vector3(2.6, 0.15, 6.0)
@export var slide_direction: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var boost_speed: float = 9.5

var melted_left: float = 0.0

var _area: Area3D
var _mesh: MeshInstance3D
var _ice_material: StandardMaterial3D
var _water_material: StandardMaterial3D
var _actor_cooldowns: Dictionary = {}


func _ready() -> void:
	add_to_group(&"ice_slicks")

	_ice_material = StandardMaterial3D.new()
	_ice_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ice_material.albedo_color = Color(0.82, 0.95, 1.0, 0.72)
	_ice_material.roughness = 0.04
	_ice_material.metallic = 0.1
	_ice_material.metallic_specular = 0.95

	_water_material = StandardMaterial3D.new()
	_water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_material.albedo_color = Color(0.3, 0.6, 0.85, 0.4)
	_water_material.roughness = 0.15

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	_mesh.mesh = box
	_mesh.material_override = _ice_material
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	_area = Area3D.new()
	_area.collision_layer = Layers.TARGETS
	_area.collision_mask = Layers.ACTORS
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0.0, 0.8, 0.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.4
	_area.add_child(col)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)


func is_melted() -> bool:
	return melted_left > 0.0


func melt(duration: float = 3.5) -> void:
	melted_left = maxf(melted_left, duration)
	_mesh.material_override = _water_material
	Sfx.play_at(&"steam", global_position, 1.0, -1.0)
	melted.emit(self)


func on_dart_hit(dart: DartProjectile, _hit_point: Vector3) -> void:
	if dart == null or dart.data == null:
		return
	if dart.data.element == DartData.Element.FIRE:
		melt(3.5)
	elif dart.data.element == DartData.Element.ICE and is_melted():
		melted_left = 0.0
		_mesh.material_override = _ice_material
		Sfx.play_at(&"freeze", global_position, 1.1, -1.0)
		refrozen.emit(self)


func _on_body_entered(body: Node3D) -> void:
	var actor := body as Actor
	if actor == null or not actor.alive:
		return
	_boost_actor(actor)


func _physics_process(delta: float) -> void:
	# Tick cooldowns for actors that have recently stepped on the slick
	for actor_key in _actor_cooldowns.keys():
		var time_left: float = float(_actor_cooldowns[actor_key]) - delta
		if time_left <= 0.0 or not is_instance_valid(actor_key as Object):
			_actor_cooldowns.erase(actor_key)
		else:
			_actor_cooldowns[actor_key] = time_left

	if melted_left > 0.0:
		melted_left -= delta
		if melted_left <= 0.0:
			_mesh.material_override = _ice_material
			Sfx.play_at(&"freeze", global_position, 1.0, -2.0)
			refrozen.emit(self)
		return

	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive:
			_boost_actor(actor)


func _boost_actor(actor: Actor) -> void:
	if is_melted():
		if actor.elemental != null:
			actor.elemental.wet_left = maxf(actor.elemental.wet_left, 3.0)
		return

	if _actor_cooldowns.has(actor):
		return

	_actor_cooldowns[actor] = 0.8

	if actor.elemental != null:
		actor.elemental.start_slide(1.8)

	var dir := (global_transform.basis * slide_direction.normalized()).normalized()
	var horizontal_vel := Vector3(actor.velocity.x, 0.0, actor.velocity.z)
	var current_proj := horizontal_vel.dot(dir)
	if current_proj < boost_speed:
		actor.velocity += dir * (boost_speed - current_proj)

	Sfx.play_at(&"ice_slide", actor.global_position, 1.05, -3.0, 0.08)
	if actor.is_human:
		var prog: Node = get_node_or_null("/root/Progression")
		if prog != null:
			prog.call("notify_event", &"ice_slide", 1)
