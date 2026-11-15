class_name ArenaKit
extends RefCounted
## Helpers for building arenas and props out of primitive shapes.
## Everything collidable goes on the WORLD layer so darts, actors and the
## navigation bake all see the same geometry.

static var _materials: Dictionary = {}


## Cached flat-colour material. Sharing materials keeps draw calls low.
static func mat(color: Color, roughness: float = 0.85, metallic: float = 0.0,
		emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%.2f" % [color.to_html(), roughness, metallic, emission]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = emission
	_materials[key] = material
	return material


## Solid coloured box. `pos` is the box centre.
static func box(parent: Node, size: Vector3, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := _body(pos, rot_deg)
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_mesh(body, mesh, color)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## Solid upright cylinder. `pos` is its centre.
static func cylinder(parent: Node, radius: float, height: float, pos: Vector3,
		color: Color) -> StaticBody3D:
	var body := _body(pos, Vector3.ZERO)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	_add_mesh(body, mesh, color)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## A walkable slab whose top surface runs from `low` to `high` (centre line).
## Used for ramps, slides and sloped walkways.
static func ramp(parent: Node, low: Vector3, high: Vector3, width: float, color: Color,
		thickness: float = 0.3) -> StaticBody3D:
	var along := (high - low).normalized()
	var side := Vector3.UP.cross(along).normalized()
	var up := along.cross(side).normalized()
	var length := low.distance_to(high)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.transform = Transform3D(Basis(side, up, along), (low + high) * 0.5 - up * thickness * 0.5)
	var size := Vector3(width, thickness, length)
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_mesh(body, mesh, color)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## Invisible wall (keeps players and darts inside the yard).
static func blocker(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := _body(pos, Vector3.ZERO)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## Decoration with no collision.
static func deco(parent: Node, mesh: Mesh, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat(color, 0.85, 0.0, emission)
	instance.position = pos
	instance.rotation_degrees = rot_deg
	parent.add_child(instance)
	return instance


static func deco_box(parent: Node, size: Vector3, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return deco(parent, mesh, pos, color, rot_deg, emission)


static func deco_sphere(parent: Node, radius: float, pos: Vector3, color: Color,
		squash: float = 1.0, emission: float = 0.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 16
	mesh.rings = 8
	return deco(parent, mesh, pos, color, Vector3.ZERO, emission)


static func deco_cylinder(parent: Node, radius: float, height: float, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return deco(parent, mesh, pos, color, rot_deg)


## Text painted in the world (signs, labels).
static func sign_text(parent: Node, text: String, pos: Vector3, rot_deg: Vector3, color: Color,
		font_size: int = 96, pixel_size: float = 0.01) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = int(font_size * 0.18)
	label.outline_modulate = Color(0.03, 0.07, 0.19)
	label.position = pos
	label.rotation_degrees = rot_deg
	parent.add_child(label)
	return label


static func _body(pos: Vector3, rot_deg: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = pos
	body.rotation_degrees = rot_deg
	return body


static func _add_mesh(body: Node3D, mesh: Mesh, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = mesh
	instance.material_override = mat(color)
	body.add_child(instance)


static func _add_shape(body: Node3D, shape: Shape3D) -> void:
	var node := CollisionShape3D.new()
	node.shape = shape
	body.add_child(node)
