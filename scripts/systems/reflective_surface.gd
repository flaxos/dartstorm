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


func _ready() -> void:
	add_to_group(&"reflective")
	collision_layer = Layers.WORLD
	collision_mask = 0

	var shape := BoxShape3D.new()
	shape.size = Vector3(panel_size.x, panel_size.y, THICKNESS)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

	var mirror := MeshInstance3D.new()
	var mirror_mesh := BoxMesh.new()
	mirror_mesh.size = Vector3(panel_size.x, panel_size.y, THICKNESS * 0.6)
	mirror.mesh = mirror_mesh
	var mirror_material := StandardMaterial3D.new()
	mirror_material.albedo_color = Color(0.78, 0.92, 1.0)
	mirror_material.metallic = 1.0
	mirror_material.roughness = 0.06
	mirror.material_override = mirror_material
	add_child(mirror)

	# Glowing frame so the panel reads as "special" from across the yard.
	var bar := 0.22
	var depth := THICKNESS + 0.1
	for side: float in [-1.0, 1.0]:
		ArenaKit.deco_box(self, Vector3(panel_size.x + bar * 2.0, bar, depth),
				Vector3(0.0, side * (panel_size.y + bar) * 0.5, 0.0), frame_color, Vector3.ZERO, 1.2)
		ArenaKit.deco_box(self, Vector3(bar, panel_size.y, depth),
				Vector3(side * (panel_size.x + bar) * 0.5, 0.0, 0.0), frame_color, Vector3.ZERO, 1.2)
		if leg_length > 0.0:
			ArenaKit.deco_box(self, Vector3(bar, leg_length, bar),
					Vector3(side * panel_size.x * 0.4, -(panel_size.y + leg_length) * 0.5, 0.0), Color(0.25, 0.3, 0.4))


## Called by a dart at the moment it bounces off this panel.
func on_dart_ricochet(point: Vector3, normal: Vector3) -> void:
	var ripple := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.16
	mesh.outer_radius = 0.24
	ripple.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	ripple.material_override = material
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ripple)
	ripple.global_position = point + normal * 0.05
	# Lay the ring flat against the surface (a torus's hole runs along its Y axis).
	var tangent := normal.cross(Vector3.UP)
	if tangent.length_squared() < 0.01:
		tangent = Vector3.RIGHT
	tangent = tangent.normalized()
	ripple.global_basis = Basis(tangent, normal, tangent.cross(normal))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector3.ONE * 4.0, 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(ripple.queue_free)
