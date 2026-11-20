class_name FoamSplat
extends Node3D
## Vibrant Splatoon-style cartoon foam dart splat decal that sticks to walls,
## floors, and obstacles when a dart impacts geometry.
## Pops in with tactile bounciness, stays for a few seconds, then fizzes out
## with tiny bubbles without cluttering memory.

const SPLAT_SHADER := preload("res://assets/materials/foam_splat.gdshader")
const MAX_ALIVE := 48
const BASE_LIFETIME := 8.5
const FIZZ_DURATION := 1.4

static var _active_splats: Array[FoamSplat] = []

var color: Color = Color(1.0, 0.5, 0.1)
var _age: float = 0.0
var _fizzing: bool = false
var _fizz_progress: float = 0.0
var _mesh_inst: MeshInstance3D
var _mat: ShaderMaterial
var _base_scale: Vector3 = Vector3.ONE


static func live_count() -> int:
	return _active_splats.size()


static func clear_all() -> void:
	for s in _active_splats.duplicate():
		if is_instance_valid(s):
			s.queue_free()
	_active_splats.clear()


static func spawn(parent: Node, at: Vector3, normal: Vector3, tint: Color,
		size_scale: float = 1.0) -> FoamSplat:
	if parent == null:
		return null
	var cap := maxi(int(round(MAX_ALIVE * GameSettings.visual_intensity)), 12)
	while _active_splats.size() >= cap and not _active_splats.is_empty():
		var oldest: FoamSplat = _active_splats.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var splat := FoamSplat.new()
	splat.color = tint
	parent.add_child(splat)
	splat._setup(at, normal, size_scale)
	_active_splats.append(splat)
	return splat


func _setup(at: Vector3, normal: Vector3, size_scale: float) -> void:
	# Position slightly offset from surface to prevent Z-fighting
	global_position = at + normal * 0.015

	# Align quad facing outward along the surface normal
	var safe_normal := normal.normalized()
	if absf(safe_normal.dot(Vector3.UP)) > 0.98:
		# Floor or ceiling
		look_at(global_position + safe_normal, Vector3.FORWARD if safe_normal.y > 0 else Vector3.BACK)
	else:
		look_at(global_position + safe_normal, Vector3.UP)

	# Random rotation around normal axis for organic variation
	rotate_object_local(Vector3.FORWARD, randf() * TAU)

	# Create quad mesh
	var quad := QuadMesh.new()
	var base_radius := randf_range(0.38, 0.52) * size_scale
	quad.size = Vector2(base_radius, base_radius)

	_mat = ShaderMaterial.new()
	_mat.shader = SPLAT_SHADER
	_mat.set_shader_parameter(&"splat_color", color)
	_mat.set_shader_parameter(&"seed_val", randf() * 50.0)
	_mat.set_shader_parameter(&"fizz_progress", 0.0)

	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.mesh = quad
	_mesh_inst.material_override = _mat
	_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_inst)

	_base_scale = Vector3.ONE
	scale = Vector3.ZERO


func start_fizz() -> void:
	if not _fizzing:
		_fizzing = true
		_fizz_progress = 0.0


func _process(delta: float) -> void:
	_age += delta

	# Spring spawn pop (0.0 to 1.15 to 1.0 in 0.1s)
	if _age < 0.1:
		var t := _age / 0.1
		var pop := sin(t * PI * 0.5) * 1.12
		scale = _base_scale * pop
	elif _age < 0.16:
		var t := (_age - 0.1) / 0.06
		scale = _base_scale * lerpf(1.12, 1.0, t)
	else:
		scale = _base_scale

	if _fizzing or _age >= BASE_LIFETIME:
		_fizzing = true
		_fizz_progress += delta / FIZZ_DURATION
		if _mat != null:
			_mat.set_shader_parameter(&"fizz_progress", clampf(_fizz_progress, 0.0, 1.0))
		if _fizz_progress >= 1.0:
			queue_free()


func _exit_tree() -> void:
	_active_splats.erase(self)
