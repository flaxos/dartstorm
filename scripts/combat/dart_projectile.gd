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
static var _trail_mesh: CylinderMesh
static var _elem_ribbon_mesh: ArrayMesh
static var _elem_star_mesh: ArrayMesh
static var _elem_drop_mesh: SphereMesh
static var _elem_bolt_mesh: BoxMesh
static var _elem_flake_mesh: ArrayMesh
static var _tip_material: StandardMaterial3D
static var _foam_shader: Shader = preload("res://assets/materials/foam_dart.gdshader")
static var _foam_materials: Dictionary = {}
static var _trail_materials: Dictionary = {}
static var _elem_materials: Dictionary = {}

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
var persists_as_pickup: bool = false
var scavengeable: bool = false
var gravity_scale: float = 1.0
var tag_power_multiplier: float = 1.0
static var resting_pickups: Array[DartProjectile] = []
const MAX_RESTING_PICKUPS := 120

static func clear_resting_pickups() -> void:
	for p in resting_pickups:
		if is_instance_valid(p):
			p.scavengeable = false
	resting_pickups.clear()

var _scavenge_check_timer: float = 0.0
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
var _elem_fx: Node3D
var _elem_parts: Array[MeshInstance3D] = []
var _elem_phase: float = 0.0
var _active_element: DartData.Element = DartData.Element.NONE


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
	_trail.rotation_degrees.x = 90.0
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_trail)

	_elem_fx = Node3D.new()
	_elem_fx.visible = false
	add_child(_elem_fx)
	for _i in 4:
		var part := MeshInstance3D.new()
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.visible = false
		_elem_fx.add_child(part)
		_elem_parts.append(part)

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
	gravity_scale = 1.0
	tag_power_multiplier = 1.0
	_spent = false
	_resting = false
	persists_as_pickup = pool != null and pool.persists_as_pickup
	if scavengeable:
		resting_pickups.erase(self)
	scavengeable = false
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
	_configure_elemental_trail(data.element, dart_color)
	global_position = origin
	_face_velocity()
	_stretch_trail()
	visible = true
	set_physics_process(true)


func retire() -> void:
	if not active:
		return
	if scavengeable:
		resting_pickups.erase(self)
		scavengeable = false
	active = false
	visible = false
	if _elem_fx != null:
		_elem_fx.visible = false
	set_physics_process(false)
	if pool != null:
		pool.release(self)


func is_flying() -> bool:
	return active and not _spent and not _resting


## Reverses a live dart mid-air when batted by a melee weapon, transferring
## shooter credit, team ownership, and hitbox exclusions so it can tag the original shooter.
func deflect(new_shooter: Actor, new_direction: Vector3, min_speed: float = 30.0) -> void:
	if not is_flying() or new_shooter == null or new_direction.length_squared() < 0.0001:
		return
	var aim := new_direction.normalized()
	var speed := maxf(velocity.length() * 1.25, min_speed)
	velocity = aim * speed
	shooter = new_shooter
	team_id = new_shooter.team_id
	color = new_shooter.color
	ricochet_count += 1
	age = 0.0
	_exclude.clear()
	if new_shooter.hitbox != null:
		_exclude.append(new_shooter.hitbox.get_rid())
	_exclude.append(new_shooter.get_rid())
	_ricochet_ignore.clear()
	if _foam != null:
		_foam.material_override = _foam_material(color)
	if _trail != null:
		_trail.material_override = _trail_material(color)
	_face_velocity()
	_stretch_trail()


func _physics_process(delta: float) -> void:
	age += delta
	if _resting:
		if scavengeable:
			scale = Vector3.ONE * 1.15
			_scavenge_check_timer -= delta
			if _scavenge_check_timer <= 0.0:
				_scavenge_check_timer = 0.05
				var actors: Array[Node] = get_tree().get_nodes_in_group(&"actors")
				for a in actors:
					var act: Actor = a as Actor
					if act != null and is_instance_valid(act) and act.alive and not act.is_tagged_out:
						if act.global_position.distance_to(global_position) < 1.3:
							var added: int = act.collect_ammo(1)
							if added > 0:
								Sfx.play_at(&"ammo", global_position, 1.2, -6.0, 0.08)
								retire()
								return
			return
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

	var acceleration := Vector3.DOWN * GRAVITY * (1.0 if _spent else data.gravity_multiplier * gravity_scale)
	if not _spent and pool != null and pool.wind_field != null:
		acceleration += pool.wind_field.get_wind_at(global_position) * data.wind_response
	velocity += acceleration * delta
	velocity *= maxf(1.0 - data.air_drag * delta, 0.0)

	var from := global_position
	var to := from + velocity * delta
	var hit := _sweep(from, to)
	var pass_throughs := 0
	while not hit.is_empty() and not _spent and pass_throughs < 4:
		var consumed := _on_hit(hit)
		if consumed or not active or _resting or _spent:
			break
		pass_throughs += 1
		from = hit["position"]
		hit = _sweep(from, to)
	if hit.is_empty() and active and not _resting:
		global_position = to
	elif not hit.is_empty() and _spent and active and not _resting:
		_on_hit(hit)
	if not active or _resting:
		return
	if _spent:
		_visual.rotate_x(18.0 * delta)
	else:
		_face_velocity()
		_stretch_trail()
		if _active_element != DartData.Element.NONE:
			_update_elemental_trail(delta)


func _sweep(from: Vector3, to: Vector3) -> Dictionary:
	_query.from = from
	_query.to = to
	_query.collision_mask = Layers.WORLD if _spent else data.collision_mask
	_query.collide_with_areas = not _spent
	_query.hit_from_inside = not _spent
	_query.exclude = _exclude
	return get_world_3d().direct_space_state.intersect_ray(_query)


## Returns true if the dart was consumed/bounced/settled; false if it passed straight through.
func _on_hit(hit: Dictionary) -> bool:
	var collider: Object = hit.get("collider")
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var rid: RID = hit["rid"]

	if _spent:
		_settle_or_bounce(point, normal)
		return true

	if collider is Hitbox:
		var victim := (collider as Hitbox).actor
		if victim == null or victim == shooter or not victim.accepts_dart_from(team_id):
			if not _exclude.has(rid):
				_exclude.append(rid)  # Pass straight through friends and ghosts.
			return false
		global_position = point
		victim.receive_dart(self)
		_report(Impact.ACTOR, point, normal)
		retire()
		return true

	var target_collider: Object = collider
	if target_collider != null and not target_collider.has_method(&"on_dart_hit") and target_collider is Node:
		var parent := (target_collider as Node).get_parent()
		if parent != null and parent.has_method(&"on_dart_hit"):
			target_collider = parent

	if target_collider != null and target_collider.has_method(&"on_dart_hit"):
		if target_collider.has_method(&"should_consume_dart") and not bool(target_collider.call(&"should_consume_dart", self)):
			if not _exclude.has(rid):
				_exclude.append(rid)
			return false
		global_position = point
		target_collider.call(&"on_dart_hit", self, point)
		_report(Impact.TARGET, point, normal)
		retire()
		return true

	var reflective := data.ricochet_any_surface
	if not reflective and collider is Node:
		reflective = (collider as Node).is_in_group(&"reflective")
	if reflective and ricochet_count < data.max_ricochets:
		_ricochet(collider, rid, point, normal)
		return true

	_report(Impact.WORLD, point, normal)
	_become_spent(point, normal)
	return true


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
	if _elem_fx != null:
		_elem_fx.visible = false
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
		if persists_as_pickup:
			scavengeable = true
			if resting_pickups.size() >= MAX_RESTING_PICKUPS:
				var oldest: DartProjectile = resting_pickups.pop_front() as DartProjectile
				if is_instance_valid(oldest) and oldest.active:
					oldest.retire()
			resting_pickups.append(self)
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
	var is_elem := _active_element != DartData.Element.NONE
	var length := clampf(velocity.length() * (0.068 if is_elem else 0.045), 0.75 if is_elem else 0.45, 3.2 if is_elem else 2.2)
	var width := 1.65 if is_elem else 1.15
	_trail.scale = Vector3(width, length, width)
	_trail.position = Vector3(0.0, 0.0, FOAM_LENGTH * 0.5 + length * 0.5)


func _configure_elemental_trail(elem: DartData.Element, dart_color: Color) -> void:
	_active_element = elem
	_elem_phase = randf() * TAU
	if _elem_fx == null:
		return
	if elem == DartData.Element.NONE:
		_elem_fx.visible = false
		return
	_elem_fx.visible = true
	var mesh: Mesh = _elem_ribbon_mesh
	var mat: StandardMaterial3D = _elem_material(elem, dart_color)
	match elem:
		DartData.Element.WIND:
			mesh = _elem_ribbon_mesh
		DartData.Element.FIRE:
			mesh = _elem_star_mesh
		DartData.Element.WATER:
			mesh = _elem_drop_mesh
		DartData.Element.LIGHTNING:
			mesh = _elem_bolt_mesh
		DartData.Element.ICE:
			mesh = _elem_flake_mesh
	for i in _elem_parts.size():
		var part := _elem_parts[i]
		part.mesh = mesh
		part.material_override = mat
		part.visible = true
	_update_elemental_trail(0.0)


func _update_elemental_trail(delta: float) -> void:
	_elem_phase += delta
	var trail_len := clampf(velocity.length() * 0.065, 0.9, 3.0)
	var n := _elem_parts.size()
	for i in n:
		var part := _elem_parts[i]
		var frac := (float(i) + 0.45) / float(n)
		var z := FOAM_LENGTH * 0.5 + frac * trail_len
		match _active_element:
			DartData.Element.WIND:
				# Swirling translucent sky-blue calligraphic wind ribbon helix
				var ang := _elem_phase * 14.0 - frac * TAU * 1.35
				var rad := 0.14 + frac * 0.16
				part.position = Vector3(cos(ang) * rad, sin(ang) * rad, z)
				part.rotation = Vector3(0.0, 0.0, ang)
				var s := 1.05 - frac * 0.35
				part.scale = Vector3(s, s, 0.9 + frac * 0.55)
			DartData.Element.FIRE:
				# Blazing comet core + orbiting tumbling 4-point cartoon golden starbursts
				var ang := _elem_phase * 11.0 + float(i) * 1.7
				var rad := 0.10 + frac * 0.16
				part.position = Vector3(cos(ang) * rad, sin(ang) * rad, z)
				part.rotation = Vector3(_elem_phase * 8.0 + float(i), _elem_phase * 10.0, ang)
				var pulse := (1.15 - frac * 0.42) * (0.85 + 0.25 * sin(_elem_phase * 18.0 + float(i) * 2.1))
				part.scale = Vector3.ONE * pulse
			DartData.Element.WATER:
				# Glossy electric-turquoise splash wake with bouncing water droplet beads
				var wave := _elem_phase * 12.0 - float(i) * 1.4
				var side := -1.0 if (i % 2 == 0) else 1.0
				part.position = Vector3(side * (0.09 + frac * 0.14) * (0.7 + 0.3 * sin(wave)),
						cos(wave) * (0.07 + frac * 0.09), z)
				part.rotation = Vector3(0.0, 0.0, 0.0)
				var s := 1.15 - frac * 0.45
				part.scale = Vector3(s, s * 0.9, s * 1.45)
			DartData.Element.LIGHTNING:
				# Crackling bright-yellow jagged comic lightning zig-zag bolts
				var step_t := floorf(_elem_phase * 22.0)
				var side := 1.0 if ((i + int(step_t)) % 2 == 0) else -1.0
				var jitter := 0.14 + 0.05 * sin(step_t * 3.7 + float(i) * 2.3)
				var seg_len := trail_len / float(n) * 1.25
				part.position = Vector3(side * jitter * 0.55, sin(step_t * 2.1 + float(i)) * 0.06, z)
				part.rotation = Vector3(0.0, side * 0.48, side * 0.32)
				part.scale = Vector3(0.065, 0.065, seg_len)
			DartData.Element.ICE:
				# Sparkling hexagonal cyan-white frost snowflakes spinning in the wake
				var ang := _elem_phase * 7.5 + float(i) * 1.57
				var rad := 0.11 + frac * 0.14
				part.position = Vector3(cos(ang) * rad, sin(ang) * rad, z)
				part.rotation = Vector3(0.4 * float(i), _elem_phase * 5.0, ang)
				var s := 1.05 - frac * 0.35
				part.scale = Vector3.ONE * s


static func _ensure_shared_resources() -> void:
	if _foam_mesh != null:
		return
	_foam_mesh = CylinderMesh.new()
	_foam_mesh.top_radius = FOAM_RADIUS
	_foam_mesh.bottom_radius = FOAM_RADIUS
	_foam_mesh.height = FOAM_LENGTH
	_foam_mesh.radial_segments = 10
	_foam_mesh.rings = 1
	_tip_mesh = CylinderMesh.new()
	_tip_mesh.top_radius = FOAM_RADIUS * 1.25
	_tip_mesh.bottom_radius = FOAM_RADIUS * 1.25
	_tip_mesh.height = 0.07
	_tip_mesh.radial_segments = 10
	_tip_mesh.rings = 1
	# Sweeping tapered aerodynamic ribbon-core streak (thick glowing wake behind dart)
	_trail_mesh = CylinderMesh.new()
	_trail_mesh.top_radius = 0.004
	_trail_mesh.bottom_radius = 0.036
	_trail_mesh.height = 1.0
	_trail_mesh.radial_segments = 8
	_trail_mesh.rings = 1
	_tip_material = StandardMaterial3D.new()
	_tip_material.albedo_color = Color(1.0, 0.45, 0.05)
	_tip_material.emission_enabled = true
	_tip_material.emission = Color(1.0, 0.4, 0.0)
	_tip_material.emission_energy_multiplier = 0.85

	# 1. Wind calligraphic curved ribbon mesh
	var st_r := SurfaceTool.new()
	st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_segs := 6
	for s in r_segs:
		var t0 := float(s) / float(r_segs)
		var t1 := float(s + 1) / float(r_segs)
		var z0 := (t0 - 0.5) * 0.72
		var z1 := (t1 - 0.5) * 0.72
		var y0 := sin(t0 * PI) * 0.08
		var y1 := sin(t1 * PI) * 0.08
		var w0 := sin(t0 * PI) * 0.085 + 0.012
		var w1 := sin(t1 * PI) * 0.085 + 0.012
		var a := Vector3(-w0, y0, z0)
		var b := Vector3( w0, y0, z0)
		var c := Vector3( w1, y1, z1)
		var d := Vector3(-w1, y1, z1)
		st_r.add_vertex(a); st_r.add_vertex(b); st_r.add_vertex(c)
		st_r.add_vertex(a); st_r.add_vertex(c); st_r.add_vertex(d)
	st_r.generate_normals()
	_elem_ribbon_mesh = st_r.commit()

	# 2. Fire 4-point cartoon starburst sparkle mesh (double-sided 3D octa-star)
	var st_s := SurfaceTool.new()
	st_s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer := 0.145
	var inner := 0.038
	var thick := 0.028
	var ring_pts: Array[Vector3] = []
	for k in 8:
		var ang := float(k) * TAU / 8.0
		var rad := outer if (k % 2 == 0) else inner
		ring_pts.append(Vector3(cos(ang) * rad, sin(ang) * rad, 0.0))
	var front := Vector3(0.0, 0.0, thick)
	var back := Vector3(0.0, 0.0, -thick)
	for k in 8:
		var p0 := ring_pts[k]
		var p1 := ring_pts[(k + 1) % 8]
		st_s.add_vertex(front); st_s.add_vertex(p0); st_s.add_vertex(p1)
		st_s.add_vertex(back); st_s.add_vertex(p1); st_s.add_vertex(p0)
	st_s.generate_normals()
	_elem_star_mesh = st_s.commit()

	# 3. Water glossy droplet bead
	_elem_drop_mesh = SphereMesh.new()
	_elem_drop_mesh.radius = 0.072
	_elem_drop_mesh.height = 0.144
	_elem_drop_mesh.radial_segments = 10
	_elem_drop_mesh.rings = 6

	# 4. Lightning jagged comic bolt segment
	_elem_bolt_mesh = BoxMesh.new()
	_elem_bolt_mesh.size = Vector3(1.0, 1.0, 1.0)

	# 5. Ice spinning hexagonal crystal snowflake star
	var st_f := SurfaceTool.new()
	st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
	var f_outer := 0.135
	var f_inner := 0.048
	var f_pts: Array[Vector3] = []
	for k in 12:
		var ang := float(k) * TAU / 12.0
		var rad := f_outer if (k % 2 == 0) else f_inner
		f_pts.append(Vector3(cos(ang) * rad, sin(ang) * rad, 0.0))
	var f_front := Vector3(0.0, 0.0, 0.022)
	var f_back := Vector3(0.0, 0.0, -0.022)
	for k in 12:
		var p0 := f_pts[k]
		var p1 := f_pts[(k + 1) % 12]
		st_f.add_vertex(f_front); st_f.add_vertex(p0); st_f.add_vertex(p1)
		st_f.add_vertex(f_back); st_f.add_vertex(p1); st_f.add_vertex(p0)
	st_f.generate_normals()
	_elem_flake_mesh = st_f.commit()


static func _elem_material(elem: DartData.Element, fallback_tint: Color) -> StandardMaterial3D:
	var key := int(elem)
	if _elem_materials.has(key):
		return _elem_materials[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	match elem:
		DartData.Element.WIND:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0.72, 0.96, 1.0, 0.78)
			mat.emission = Color(0.55, 0.92, 1.0)
			mat.emission_energy_multiplier = 1.6
		DartData.Element.FIRE:
			mat.albedo_color = Color(1.0, 0.86, 0.22, 1.0)
			mat.emission = Color(1.0, 0.56, 0.10)
			mat.emission_energy_multiplier = 2.4
		DartData.Element.WATER:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0.28, 0.88, 1.0, 0.88)
			mat.emission = Color(0.22, 0.82, 1.0)
			mat.emission_energy_multiplier = 1.5
		DartData.Element.LIGHTNING:
			mat.albedo_color = Color(1.0, 0.98, 0.32, 1.0)
			mat.emission = Color(1.0, 0.94, 0.18)
			mat.emission_energy_multiplier = 2.8
		DartData.Element.ICE:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0.84, 0.98, 1.0, 0.92)
			mat.emission = Color(0.55, 0.92, 1.0)
			mat.emission_energy_multiplier = 2.0
		_:
			mat.albedo_color = fallback_tint
			mat.emission = fallback_tint
			mat.emission_energy_multiplier = 1.4
	_elem_materials[key] = mat
	return mat


static func _foam_material(tint: Color) -> Material:
	var key := tint.to_html()
	if not _foam_materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = _foam_shader
		material.set_shader_parameter(&"albedo", Color(tint.r, tint.g, tint.b, 1.0))
		material.set_shader_parameter(&"roughness", 0.88)
		material.set_shader_parameter(&"emission_energy", 0.55)
		_foam_materials[key] = material
	return _foam_materials[key]


static func _trail_material(tint: Color) -> StandardMaterial3D:
	var key := tint.to_html()
	if not _trail_materials.has(key):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(tint.lightened(0.35), 0.76)
		material.emission_enabled = true
		material.emission = tint.lightened(0.25)
		material.emission_energy_multiplier = 1.5
		_trail_materials[key] = material
	return _trail_materials[key]
