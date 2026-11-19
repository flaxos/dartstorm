class_name PingBeacon
extends Node3D
## An in-world tactical marker placed by a player or bot to communicate points
## of interest: regrouping locations, ammo buckets, power-ups, rivals, or danger.

enum Type {
	REGROUP = 0,
	AMMO = 1,
	POWERUP = 2,
	RIVAL = 3,
	DANGER = 4,
}

var type: Type = Type.REGROUP
var author: Actor = null
var life_time: float = 4.5

var _time: float = 0.0
var _ring: MeshInstance3D
var _beam: MeshInstance3D
var _label: Label3D
var _mat_ring: StandardMaterial3D
var _mat_beam: StandardMaterial3D


static func spawn(parent: Node, at: Vector3, p_type: Type, p_author: Actor = null) -> PingBeacon:
	if parent == null:
		return null
	var beacon := PingBeacon.new()
	beacon.type = p_type
	beacon.author = p_author
	parent.add_child(beacon)
	beacon.global_position = at
	return beacon


func _ready() -> void:
	add_to_group(&"ping_beacons")
	_build_visuals()


func _build_visuals() -> void:
	var color := _color_for_type(type)

	# Ground ring
	_mat_ring = StandardMaterial3D.new()
	_mat_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_ring.albedo_color = color
	_mat_ring.cull_mode = BaseMaterial3D.CULL_DISABLED

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.65
	ring_mesh.outer_radius = 0.85
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 6

	_ring = MeshInstance3D.new()
	_ring.mesh = ring_mesh
	_ring.material_override = _mat_ring
	_ring.position.y = 0.08
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	# Vertical light beam
	_mat_beam = StandardMaterial3D.new()
	_mat_beam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_beam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_beam.albedo_color = Color(color.r, color.g, color.b, 0.45)

	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.08
	cyl.height = 3.2
	cyl.radial_segments = 8

	_beam = MeshInstance3D.new()
	_beam.mesh = cyl
	_beam.material_override = _mat_beam
	_beam.position.y = 1.6
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)

	# In-world 3D billboard label
	_label = Label3D.new()
	_label.text = _text_for_type(type)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 2
	_label.font_size = 28
	_label.outline_size = 8
	_label.outline_modulate = Color(0.04, 0.08, 0.18, 0.95)
	_label.modulate = color
	_label.position.y = 2.4
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	life_time -= delta

	if life_time <= 0.0:
		queue_free()
		return

	# Pulse scale and hover
	var pulse := 1.0 + sin(_time * 6.0) * 0.12
	if _ring != null:
		_ring.scale = Vector3(pulse, 1.0, pulse)
		_ring.rotation.y += delta * 2.0

	if _label != null:
		_label.position.y = 2.4 + sin(_time * 4.0) * 0.15

	# Fade out during last 0.8s
	if life_time < 0.8:
		var alpha := clampf(life_time / 0.8, 0.0, 1.0)
		if _mat_ring != null:
			_mat_ring.albedo_color.a = alpha * 0.9
		if _mat_beam != null:
			_mat_beam.albedo_color.a = alpha * 0.45
		if _label != null:
			_label.modulate.a = alpha


func _color_for_type(p_type: Type) -> Color:
	match p_type:
		Type.REGROUP:
			return UiKit.SKY
		Type.AMMO:
			return UiKit.LIME
		Type.POWERUP:
			return Color(1.0, 0.85, 0.25)
		Type.RIVAL:
			return UiKit.ORANGE_HOT
		Type.DANGER:
			return Color(1.0, 0.25, 0.3)
	return UiKit.SKY


func _text_for_type(p_type: Type) -> String:
	match p_type:
		Type.REGROUP:
			return "📍 REGROUP"
		Type.AMMO:
			return "📦 AMMO"
		Type.POWERUP:
			return "✨ POWER-UP"
		Type.RIVAL:
			return "⚠️ RIVAL"
		Type.DANGER:
			return "💥 DANGER"
	return "📍 PING"
