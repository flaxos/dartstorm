class_name ReflectiveSurface
extends StaticBody3D
## A shiny panel that darts bounce off. The dart does the maths (it reflects its
## velocity around the collision normal); this scene just marks itself as
## reflective via the "reflective" group and shows a ripple where it was hit.
## The mirror faces this node's local +Z.

@export var panel_size: Vector2 = Vector2(6.0, 3.5)
@export var frame_color: Color = Color(0.2, 0.9, 1.0)
## Length of the two support legs below the panel (0 for wall-mounted).
@export var leg_length: float = 0.0

const THICKNESS := 0.25

var _sheen_strips: Array[MeshInstance3D] = []
var _sheen_time: float = 0.0
var _mirror_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group(&"reflective")
	collision_layer = Layers.WORLD
	collision_mask = 0

	var shape := BoxShape3D.new()
	shape.size = Vector3(panel_size.x, panel_size.y, THICKNESS)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

	# Stylized comic sky-cyan glossy mirror face with crisp reflection feel
	var mirror := MeshInstance3D.new()
	var mirror_mesh := BoxMesh.new()
	mirror_mesh.size = Vector3(panel_size.x, panel_size.y, THICKNESS * 0.58)
	mirror.mesh = mirror_mesh
	_mirror_mat = StandardMaterial3D.new()
	_mirror_mat.albedo_color = Color(0.76, 0.94, 1.0)
	_mirror_mat.metallic = 0.86
	_mirror_mat.roughness = 0.05
	_mirror_mat.emission_enabled = true
	_mirror_mat.emission = Color(0.32, 0.80, 1.0)
	_mirror_mat.emission_energy_multiplier = 0.22
	mirror.material_override = _mirror_mat
	add_child(mirror)

	# Animated diagonal cartoon glass sheen streaks on both front & back mirror faces
	var sheen_mat := StandardMaterial3D.new()
	sheen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sheen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheen_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.34)
	sheen_mat.emission_enabled = true
	sheen_mat.emission = Color(0.92, 0.98, 1.0)
	sheen_mat.emission_energy_multiplier = 0.8
	var strip_offsets := [-0.26, 0.05, 0.22]
	var strip_widths := [0.28, 0.14, 0.22]
	for face_z: float in [1.0, -1.0]:
		for i in strip_offsets.size():
			var strip := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(strip_widths[i], panel_size.y * 0.86, 0.015)
			strip.mesh = sm
			strip.material_override = sheen_mat
			strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			strip.position = Vector3(strip_offsets[i] * panel_size.x, 0.0, face_z * (THICKNESS * 0.31))
			strip.rotation_degrees = Vector3(0.0, 0.0, -24.0)
			add_child(strip)
			_sheen_strips.append(strip)

	# Beveled glowing cyan neon border tubes + rounded dark-navy corner bumpers
	var bar := 0.24
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.roughness = 0.22
	frame_mat.emission_enabled = true
	frame_mat.emission = frame_color
	frame_mat.emission_energy_multiplier = 1.45
	frame_mat.next_pass = ArenaKit.outline_mat(0.75, false)

	var corner_mat := ArenaKit.toon_mat(Color(0.14, 0.22, 0.38), 0.32, 0.65, 0.75, false)
	for side: float in [-1.0, 1.0]:
		# Top & bottom glowing horizontal tubular bars
		var h_cyl := CylinderMesh.new()
		h_cyl.top_radius = bar * 0.58
		h_cyl.bottom_radius = bar * 0.58
		h_cyl.height = panel_size.x + bar
		h_cyl.radial_segments = 14
		var h_bar := MeshInstance3D.new()
		h_bar.mesh = h_cyl
		h_bar.material_override = frame_mat
		h_bar.position = Vector3(0.0, side * (panel_size.y + bar * 0.6) * 0.5, 0.0)
		h_bar.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		add_child(h_bar)

		# Left & right glowing vertical tubular bars
		var v_cyl := CylinderMesh.new()
		v_cyl.top_radius = bar * 0.58
		v_cyl.bottom_radius = bar * 0.58
		v_cyl.height = panel_size.y + bar
		v_cyl.radial_segments = 14
		var v_bar := MeshInstance3D.new()
		v_bar.mesh = v_cyl
		v_bar.material_override = frame_mat
		v_bar.position = Vector3(side * (panel_size.x + bar * 0.6) * 0.5, 0.0, 0.0)
		add_child(v_bar)

		if leg_length > 0.0:
			var leg_cyl := CylinderMesh.new()
			leg_cyl.top_radius = bar * 0.55
			leg_cyl.bottom_radius = bar * 0.68
			leg_cyl.height = leg_length
			leg_cyl.radial_segments = 12
			var leg := MeshInstance3D.new()
			leg.mesh = leg_cyl
			leg.material_override = corner_mat
			leg.position = Vector3(side * panel_size.x * 0.4, -(panel_size.y + leg_length) * 0.5, 0.0)
			add_child(leg)

	# 4 rounded corner bumper caps
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = bar * 0.85
	cap_mesh.height = bar * 1.7
	cap_mesh.radial_segments = 12
	cap_mesh.rings = 8
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var cap := MeshInstance3D.new()
			cap.mesh = cap_mesh
			cap.material_override = corner_mat
			cap.position = Vector3(sx * (panel_size.x + bar * 0.6) * 0.5, sy * (panel_size.y + bar * 0.6) * 0.5, 0.0)
			add_child(cap)


func _process(delta: float) -> void:
	_sheen_time += delta
	var drift := sin(_sheen_time * 1.1) * 0.22
	var base_offsets := [-0.26, 0.05, 0.22]
	for i in _sheen_strips.size():
		var idx := i % 3
		_sheen_strips[i].position.x = base_offsets[idx] * panel_size.x + drift


## Called by a dart at the moment it bounces off this panel.
func on_dart_ricochet(point: Vector3, normal: Vector3) -> void:
	# Twin concentric glowing cyan + bright white cartoon shockwave rings
	var tangent := normal.cross(Vector3.UP)
	if tangent.length_squared() < 0.01:
		tangent = Vector3.RIGHT
	tangent = tangent.normalized()
	var orient := Basis(tangent, normal, tangent.cross(normal))

	var ring_specs := [
		[Color(0.30, 0.96, 1.0, 0.95), 4.8, 0.34],
		[Color(1.0, 1.0, 1.0, 0.95), 3.1, 0.24],
	]
	for spec: Array in ring_specs:
		var ripple := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.14
		mesh.outer_radius = 0.26
		mesh.rings = 18
		mesh.ring_segments = 8
		ripple.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var col: Color = spec[0]
		material.albedo_color = col
		material.emission_enabled = true
		material.emission = Color(col.r, col.g, col.b)
		material.emission_energy_multiplier = 2.2
		ripple.material_override = material
		ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ripple)
		ripple.global_position = point + normal * 0.06
		ripple.global_basis = orient
		var target_scale: float = spec[1]
		var dur: float = spec[2]
		var tween := create_tween().set_parallel(true)
		tween.tween_property(ripple, "scale", Vector3.ONE * target_scale, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(material, "albedo_color:a", 0.0, dur)
		tween.chain().tween_callback(ripple.queue_free)

	if _mirror_mat != null:
		_mirror_mat.emission_energy_multiplier = 1.65
		var flash_tw := create_tween()
		flash_tw.tween_property(_mirror_mat, "emission_energy_multiplier", 0.22, 0.22)
