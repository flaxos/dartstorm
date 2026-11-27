class_name WindVent
extends Node3D
## An interactive floor vent / wind tunnel.
## Stepping onto it pushes actors upward with a buoyant air lift.
## Shooting it with an elemental dart amplifies and infuses the wind stream
## with that element for 5.0 seconds!

signal element_amplified(vent: WindVent, elem: DartData.Element)
signal element_expired(vent: WindVent)

@export var radius: float = 1.6
@export var lift_velocity: float = 14.0
@export var wind_direction: Vector3 = Vector3.UP

var active_element: DartData.Element = DartData.Element.NONE
var amplified_left: float = 0.0

var _area: Area3D
var _fan_blades: Node3D
var _volume: MeshInstance3D
var _volume_mat: StandardMaterial3D
var _grate: MeshInstance3D
var _time: float = 0.0
var _infuser: Actor = null


func _ready() -> void:
	add_to_group(&"wind_vents")

	# Base circular rim and grill
	ArenaKit.deco_cylinder(self, radius + 0.15, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.2, 0.25, 0.35))
	_grate = ArenaKit.deco_cylinder(self, radius, 0.08, Vector3(0.0, 0.08, 0.0), Color(0.12, 0.15, 0.2))

	# Rotating internal fan blades
	_fan_blades = Node3D.new()
	_fan_blades.position.y = 0.04
	add_child(_fan_blades)
	for i in 4:
		var blade := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(radius * 0.85, 0.02, 0.22)
		blade.mesh = box
		blade.rotation.y = float(i) * PI * 0.25
		blade.material_override = ArenaKit.mat(Color(0.35, 0.4, 0.5), 0.5)
		_fan_blades.add_child(blade)

	# Faint rising wind column
	_volume = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 1.15
	cyl.bottom_radius = radius
	cyl.height = 6.0
	cyl.radial_segments = 16
	_volume.mesh = cyl
	_volume_mat = StandardMaterial3D.new()
	_volume_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_volume_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_volume_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_volume_mat.albedo_color = Color(0.7, 0.95, 1.0, 0.12)
	_volume.material_override = _volume_mat
	_volume.position.y = 3.0
	_volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_volume)

	# Detection area
	_area = Area3D.new()
	_area.collision_layer = Layers.TARGETS
	_area.collision_mask = Layers.ACTORS
	var shape := CylinderShape3D.new()
	shape.radius = radius * 1.1
	shape.height = 6.0
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 3.0
	_area.add_child(col)
	add_child(_area)


func amplify(elem: DartData.Element, duration: float = 5.0, by_actor: Actor = null) -> void:
	active_element = elem
	amplified_left = maxf(amplified_left, duration)
	if by_actor != null and is_instance_valid(by_actor):
		_infuser = by_actor
	_refresh_visuals()
	element_amplified.emit(self, elem)


func should_consume_dart(dart: DartProjectile) -> bool:
	return dart != null and dart.data != null and dart.data.element != DartData.Element.NONE


func on_dart_hit(dart: DartProjectile, _hit_point: Vector3) -> void:
	if dart == null or dart.data == null:
		return
	var elem := dart.data.element
	if elem != DartData.Element.NONE:
		amplify(elem, 5.0, dart.shooter if is_instance_valid(dart.shooter) else null)


func _physics_process(delta: float) -> void:
	_time += delta
	_fan_blades.rotate_y(delta * (28.0 if amplified_left > 0.0 else 12.0))

	if amplified_left > 0.0:
		amplified_left -= delta
		if amplified_left <= 0.0:
			active_element = DartData.Element.NONE
			_infuser = null
			_refresh_visuals()
			element_expired.emit(self)

	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive:
			_apply_vent_to_actor(actor, delta)


func _apply_vent_to_actor(actor: Actor, delta: float) -> void:
	# Smooth buoyant updraft lift
	if actor.velocity.y < lift_velocity:
		actor.velocity.y = move_toward(actor.velocity.y, lift_velocity, 30.0 * delta)

	# Elemental effect if active
	if active_element == DartData.Element.NONE or actor.elemental == null or actor.is_tagged_out:
		return

	match active_element:
		DartData.Element.FIRE:
			actor.elemental.sparkle_left = maxf(actor.elemental.sparkle_left, 3.0)
			actor.elemental.status_started.emit(DartData.Element.FIRE, 3.0)
		DartData.Element.WATER:
			actor.elemental.wet_left = maxf(actor.elemental.wet_left, 4.0)
			actor.elemental.status_started.emit(DartData.Element.WATER, 4.0)
		DartData.Element.ICE:
			actor.elemental.frost_left = maxf(actor.elemental.frost_left, 2.5)
			actor.elemental.status_started.emit(DartData.Element.ICE, 2.5)
		DartData.Element.LIGHTNING:
			var attacker: Actor = _infuser if is_instance_valid(_infuser) else null
			actor.apply_hazard_tag(24.0 * delta, self, attacker)
			actor.elemental.status_started.emit(DartData.Element.LIGHTNING, 0.3)


func _refresh_visuals() -> void:
	match active_element:
		DartData.Element.FIRE:
			_volume_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.25)
			Sfx.play_at(&"sparkle", global_position + Vector3.UP * 2.0, 1.0, 0.0)
		DartData.Element.WATER:
			_volume_mat.albedo_color = Color(0.2, 0.7, 1.0, 0.28)
			Sfx.play_at(&"splash", global_position + Vector3.UP * 2.0, 1.0, 0.0)
		DartData.Element.ICE:
			_volume_mat.albedo_color = Color(0.85, 0.98, 1.0, 0.28)
			Sfx.play_at(&"freeze", global_position + Vector3.UP * 2.0, 1.0, 0.0)
		DartData.Element.LIGHTNING:
			_volume_mat.albedo_color = Color(1.0, 0.95, 0.2, 0.32)
			Sfx.play_at(&"zap", global_position + Vector3.UP * 2.0, 1.1, 0.0)
		_:
			_volume_mat.albedo_color = Color(0.7, 0.95, 1.0, 0.12)
