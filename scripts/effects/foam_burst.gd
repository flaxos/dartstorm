class_name FoamBurst
extends CPUParticles3D
## A one-shot puff of colourful foam bits. Frees itself when finished.

static var _mesh: BoxMesh
static var _shrink: Curve


static func spawn(parent: Node, at: Vector3, tint: Color, amount_wanted: int = 10,
		speed: float = 4.0, normal: Vector3 = Vector3.UP) -> void:
	var count := int(round(float(amount_wanted) * GameSettings.visual_intensity))
	if count <= 0 or parent == null:
		return
	_ensure_shared()
	var burst := FoamBurst.new()
	burst.mesh = _mesh
	burst.amount = count
	burst.lifetime = 0.55
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = normal
	burst.spread = 75.0
	burst.gravity = Vector3(0.0, -13.0, 0.0)
	burst.initial_velocity_min = speed * 0.5
	burst.initial_velocity_max = speed
	burst.angular_velocity_min = -400.0
	burst.angular_velocity_max = 400.0
	burst.scale_amount_min = 0.6
	burst.scale_amount_max = 1.4
	burst.scale_amount_curve = _shrink
	burst.color = tint
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(burst)
	burst.global_position = at
	burst.emitting = true
	burst.get_tree().create_timer(burst.lifetime + 0.25).timeout.connect(burst.queue_free)


static func _ensure_shared() -> void:
	if _mesh != null:
		return
	_mesh = BoxMesh.new()
	_mesh.size = Vector3(0.09, 0.09, 0.09)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	_mesh.material = material
	_shrink = Curve.new()
	_shrink.add_point(Vector2(0.0, 1.0))
	_shrink.add_point(Vector2(0.6, 0.9))
	_shrink.add_point(Vector2(1.0, 0.0))
