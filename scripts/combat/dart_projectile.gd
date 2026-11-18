class_name DartProjectile
extends Node3D
## One pooled foam dart. Darts are real projectiles, never hit-scan:
##
##     velocity += (gravity + wind) * delta
##     position += velocity * delta
##
## Each physics tick the dart sweeps a ray along the distance it is about to
## travel, so even a very fast dart cannot tunnel through a thin wall.
## After hitting something ordinary it becomes "spent": a harmless bit of foam
## that bounces, tumbles and rests on the ground for a moment before recycling.

enum Impact { WORLD, ACTOR, RICOCHET, TARGET }

const GRAVITY := 9.8
const REST_SECONDS := 1.4
const SPENT_SECONDS := 2.0
const SPENT_BOUNCE := 0.28
const RICOCHET_IGNORE_SECONDS := 0.08
const FOAM_LENGTH := 0.3
const FOAM_RADIUS := 0.04

static var _foam_mesh: CylinderMesh
static var _tip_mesh: CylinderMesh
static var _trail_mesh: BoxMesh
static var _tip_material: StandardMaterial3D
static var _foam_materials: Dictionary = {}
static var _trail_materials: Dictionary = {}

var pool: DartPool
var data: DartData
var weapon: WeaponData
var shooter: Actor
var team_id: int = -1
var color: Color = Color.WHITE
var velocity: Vector3 = Vector3.ZERO
var ricochet_count: int = 0
var age: float = 0.0
var active: bool = false

var _spent: bool = false
var _resting: bool = false
var _rest_left: float = 0.0
var _spent_left: float = 0.0
var _exclude: Array[RID] = []
## Surfaces this dart just bounced off, mapped to seconds left before they can
## be hit again. One entry per surface, so quick back-to-back ricochets
## (two mirrors facing each other) each expire on their own.
var _ricochet_ignore: Dictionary = {}
var _query: PhysicsRayQueryParameters3D
var _visual: Node3D
var _foam: MeshInstance3D
var _trail: MeshInstance3D


func _ready() -> void:
	_ensure_shared_resources()
	_visual = Node3D.new()
	add_child(_visual)

	_foam = MeshInstance3D.new()
	_foam.mesh = _foam_mesh
	_foam.rotation_degrees.x = 90.0
	_foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(_foam)

	var tip := MeshInstance3D.new()
	tip.mesh = _tip_mesh
	tip.material_override = _tip_material
	tip.rotation_degrees.x = 90.0
	tip.position.z = -(FOAM_LENGTH * 0.5 + 0.03)
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(tip)

	_trail = MeshInstance3D.new()
	_trail.mesh = _trail_mesh
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_trail)

	_query = PhysicsRayQueryParameters3D.new()
	visible = false
	set_physics_process(false)


func launch(p_data: DartData, origin: Vector3, direction: Vector3, p_shooter: Actor,
		p_weapon: WeaponData, p_color: Color, exclude: Array[RID]) -> void:
	data = p_data
	weapon = p_weapon
	shooter = p_shooter
	team_id = p_shooter.team_id if p_shooter != null else -1
	color = p_color
	velocity = direction.normalized() * data.initial_speed
	ricochet_count = 0
	age = 0.0
	active = true
	_spent = false
	_resting = false
	_exclude.assign(exclude)
	_ricochet_ignore.clear()
	scale = Vector3.ONE
	_visual.rotation = Vector3.ZERO
	_visual.scale = Vector3.ONE * data.visual_scale
	var dart_color := color
	if data.element != DartData.Element.NONE:
		match data.element:
			DartData.Element.WIND:
				dart_color = dart_color.lerp(Color(0.7, 0.95, 1.0), 0.6)
			DartData.Element.FIRE:
				dart_color = dart_color.lerp(Color(1.0, 0.4, 0.1), 0.75)
			DartData.Element.WATER:
				dart_color = dart_color.lerp(Color(0.2, 0.75, 1.0), 0.75)
			DartData.Element.LIGHTNING:
				dart_color = dart_color.lerp(Color(1.0, 0.95, 0.25), 0.75)
			DartData.Element.ICE:
				dart_color = dart_color.lerp(Color(0.85, 0.98, 1.0), 0.75)
	_foam.material_override = _foam_material(dart_color)
	_trail.material_override = _trail_material(dart_color)
	_trail.visible = true
	global_position = origin
	_face_velocity()
	_stretch_trail()
	visible = true
	set_physics_process(true)


func retire() -> void:
	if not active:
		return
	active = false
	visible = false
	set_physics_process(false)
	if pool != null:
		pool.release(self)


func _physics_process(delta: float) -> void:
	age += delta
	if _resting:
		_rest_left -= delta
		if _rest_left <= 0.0:
			retire()
		elif _rest_left < 0.25:
			scale = Vector3.ONE * maxf(_rest_left / 0.25, 0.05)
		return
	if _spent:
		_spent_left -= delta
		if _spent_left <= 0.0:
			retire()
			return
	elif age >= data.max_lifetime:
		retire()
		return

	if not _ricochet_ignore.is_empty():
		_expire_ricochet_ignores(delta)

	var acceleration := Vector3.DOWN * GRAVITY * (1.0 if _spent else data.gravity_multiplier)
	if not _spent and pool != null and pool.wind_field != null:
		acceleration += pool.wind_field.get_wind_at(global_position) * data.wind_response
	velocity += acceleration * delta
	velocity *= maxf(1.0 - data.air_drag * delta, 0.0)

	var from := global_position
	var to := from + velocity * delta
	var hit := _sweep(from, to)
	if hit.is_empty():
		global_position = to
	else:
		_on_hit(hit)
	if not active or _resting:
		return
	if _spent:
		_visual.rotate_x(18.0 * delta)
	else:
		_face_velocity()
		_stretch_trail()


func _sweep(from: Vector3, to: Vector3) -> Dictionary:
	_query.from = from
	_query.to = to
	_query.collision_mask = Layers.WORLD if _spent else data.collision_mask
	_query.collide_with_areas = not _spent
	_query.exclude = _exclude
	return get_world_3d().direct_space_state.intersect_ray(_query)


func _on_hit(hit: Dictionary) -> void:
	var collider: Object = hit.get("collider")
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var rid: RID = hit["rid"]

	if _spent:
		_settle_or_bounce(point, normal)
		return

	if collider is Hitbox:
		var victim := (collider as Hitbox).actor
		global_position = point
		if victim == null or victim == shooter or not victim.accepts_dart_from(team_id):
			_exclude.append(rid)  # Pass straight through friends and ghosts.
			return
		victim.receive_dart(self)
		_report(Impact.ACTOR, point, normal)
		retire()
		return

	var target_collider: Object = collider
	if target_collider != null and not target_collider.has_method(&"on_dart_hit") and target_collider is Node:
		var parent := (target_collider as Node).get_parent()
		if parent != null and parent.has_method(&"on_dart_hit"):
			target_collider = parent

	if target_collider != null and target_collider.has_method(&"on_dart_hit"):
		global_position = point
		target_collider.call(&"on_dart_hit", self, point)
		_report(Impact.TARGET, point, normal)
		retire()
		return

	var reflective := data.ricochet_any_surface
	if not reflective and collider is Node:
		reflective = (collider as Node).is_in_group(&"reflective")
	if reflective and ricochet_count < data.max_ricochets:
		_ricochet(collider, rid, point, normal)
		return

	_report(Impact.WORLD, point, normal)
	_become_spent(point, normal)


func _ricochet(collider: Object, rid: RID, point: Vector3, normal: Vector3) -> void:
	velocity = velocity.bounce(normal) * data.ricochet_speed_keep
	ricochet_count += 1
	global_position = point + normal * 0.03
	# Never re-hit the surface we just left on the very next sweep.
	if not _ricochet_ignore.has(rid):
		_exclude.append(rid)
	_ricochet_ignore[rid] = RICOCHET_IGNORE_SECONDS
	if collider != null and collider.has_method(&"on_dart_ricochet"):
		collider.call(&"on_dart_ricochet", point, normal)
	_report(Impact.RICOCHET, point, normal)


func _expire_ricochet_ignores(delta: float) -> void:
	for rid: RID in _ricochet_ignore.keys():
		var left: float = _ricochet_ignore[rid] - delta
		if left <= 0.0:
			_ricochet_ignore.erase(rid)
			_exclude.erase(rid)
		else:
			_ricochet_ignore[rid] = left


func _become_spent(point: Vector3, normal: Vector3) -> void:
	_spent = true
	_spent_left = SPENT_SECONDS
	_trail.visible = false
	velocity = velocity.bounce(normal) * SPENT_BOUNCE + normal * 0.6
	global_position = point + normal * 0.03


func _settle_or_bounce(point: Vector3, normal: Vector3) -> void:
	if normal.y > 0.6 or velocity.length() < 1.5:
		_resting = true
		_rest_left = REST_SECONDS
		velocity = Vector3.ZERO
		global_position = point + normal * (FOAM_RADIUS * data.visual_scale)
		rotation = Vector3(0.0, randf() * TAU, 0.0)
		_visual.rotation = Vector3.ZERO
	else:
		velocity = velocity.bounce(normal) * SPENT_BOUNCE
		global_position = point + normal * 0.03


func _report(kind: Impact, point: Vector3, normal: Vector3) -> void:
	if pool != null:
		pool.report_impact(kind, point, normal, color, data.element if data != null else DartData.Element.NONE)


func _face_velocity() -> void:
	if velocity.length_squared() < 0.01:
		return
	var direction := velocity.normalized()
	var up := Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT
	look_at(global_position + direction, up)


func _stretch_trail() -> void:
	var length := clampf(velocity.length() * 0.035, 0.3, 1.8)
	_trail.scale = Vector3(1.0, 1.0, length)
	_trail.position = Vector3(0.0, 0.0, FOAM_LENGTH * 0.5 + length * 0.5)


static func _ensure_shared_resources() -> void:
	if _foam_mesh != null:
		return
	_foam_mesh = CylinderMesh.new()
	_foam_mesh.top_radius = FOAM_RADIUS
	_foam_mesh.bottom_radius = FOAM_RADIUS
	_foam_mesh.height = FOAM_LENGTH
	_foam_mesh.radial_segments = 8
	_foam_mesh.rings = 1
	_tip_mesh = CylinderMesh.new()
	_tip_mesh.top_radius = FOAM_RADIUS * 1.25
	_tip_mesh.bottom_radius = FOAM_RADIUS * 1.25
	_tip_mesh.height = 0.07
	_tip_mesh.radial_segments = 8
	_tip_mesh.rings = 1
	_trail_mesh = BoxMesh.new()
	_trail_mesh.size = Vector3(0.035, 0.035, 1.0)
	_tip_material = StandardMaterial3D.new()
	_tip_material.albedo_color = Color(1.0, 0.45, 0.05)
	_tip_material.emission_enabled = true
	_tip_material.emission = Color(1.0, 0.4, 0.0)
	_tip_material.emission_energy_multiplier = 0.6


static func _foam_material(tint: Color) -> StandardMaterial3D:
	var key := tint.to_html()
	if not _foam_materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.roughness = 0.9
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 0.35
		_foam_materials[key] = material
	return _foam_materials[key]


static func _trail_material(tint: Color) -> StandardMaterial3D:
	var key := tint.to_html()
	if not _trail_materials.has(key):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(tint.lightened(0.45), 0.4)
		_trail_materials[key] = material
	return _trail_materials[key]
