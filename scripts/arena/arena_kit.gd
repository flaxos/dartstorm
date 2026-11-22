class_name ArenaKit
extends RefCounted
## Helpers for building arenas and props out of primitive shapes.
## Everything collidable goes on the WORLD layer so darts, actors and the
## navigation bake all see the same geometry.

enum SurfaceType {
	DEFAULT,
	PLASTIC,
	WOOD,
	METAL,
	CARDBOARD,
}

const WOOD_SHADER := preload("res://assets/materials/toy_wood.gdshader")

const TRUNK := Color(0.45, 0.3, 0.18)
const LEAF := Color(0.25, 0.65, 0.25)
const LEAF_LIGHT := Color(0.38, 0.78, 0.3)

static var _materials: Dictionary = {}
static var _wood_normal: Texture2D = preload("res://assets/textures/pbr/stylized_wood_normal.png")
static var _wood_orm: Texture2D = preload("res://assets/textures/pbr/stylized_wood_orm.png")
static var _plastic_normal: Texture2D = preload("res://assets/textures/pbr/blaster_body_normal.png")
static var _plastic_orm: Texture2D = preload("res://assets/textures/pbr/blaster_body_orm.png")
static var _metal_normal: Texture2D = preload("res://assets/textures/pbr/brushed_metal_normal.png")
static var _metal_orm: Texture2D = preload("res://assets/textures/pbr/brushed_metal_orm.png")


static func clear_materials() -> void:
	_materials.clear()


## Cached tactile material. Supports molded toy plastic, procedural timber, and brushed metal.
static func mat_styled(color: Color, surface: int = SurfaceType.DEFAULT,
		roughness: float = -1.0, metallic: float = -1.0, emission: float = 0.0) -> Material:
	var key := "%s|%d|%.2f|%.2f|%.2f" % [color.to_html(), surface, roughness, metallic, emission]
	if _materials.has(key):
		return _materials[key]

	if surface == SurfaceType.WOOD:
		var sm := ShaderMaterial.new()
		sm.shader = WOOD_SHADER
		sm.set_shader_parameter(&"wood_tint", color)
		sm.set_shader_parameter(&"roughness", 0.72 if roughness < 0.0 else roughness)
		sm.set_shader_parameter(&"rim_strength", 0.32)
		sm.set_shader_parameter(&"texture_normal", _wood_normal)
		sm.set_shader_parameter(&"texture_orm", _wood_orm)
		_materials[key] = sm
		return sm

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.rim_enabled = true

	match surface:
		SurfaceType.PLASTIC:
			material.roughness = 0.32 if roughness < 0.0 else roughness
			material.metallic = 0.04 if metallic < 0.0 else metallic
			material.metallic_specular = 0.6
			material.rim = 0.42
			material.rim_tint = 0.45
			material.normal_enabled = true
			material.normal_texture = _plastic_normal
			material.normal_scale = 0.4
			material.ao_enabled = true
			material.ao_texture = _plastic_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _plastic_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		SurfaceType.METAL:
			material.roughness = 0.24 if roughness < 0.0 else roughness
			material.metallic = 0.85 if metallic < 0.0 else metallic
			material.metallic_specular = 0.85
			material.rim = 0.2
			material.rim_tint = 0.2
			material.normal_enabled = true
			material.normal_texture = _metal_normal
			material.normal_scale = 0.5
			material.roughness_texture = _metal_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			material.metallic_texture = _metal_orm
			material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		SurfaceType.CARDBOARD:
			material.roughness = 0.88 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.15
			material.rim = 0.25
			material.rim_tint = 0.2
		_:
			# DEFAULT: High-quality vibrant toy surface
			material.roughness = 0.75 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.rim = 0.35
			material.rim_tint = 0.35

	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = emission

	_materials[key] = material
	return material


## Cached flat-colour material. Sharing materials keeps draw calls low.
static func mat(color: Color, roughness: float = 0.75, metallic: float = 0.0,
		emission: float = 0.0) -> StandardMaterial3D:
	return mat_styled(color, SurfaceType.DEFAULT, roughness, metallic, emission) as StandardMaterial3D


## Solid coloured box. `pos` is the box centre.
static func box(parent: Node, size: Vector3, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, surface: int = SurfaceType.DEFAULT) -> StaticBody3D:
	var body := _body(pos, rot_deg)
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_mesh(body, mesh, color, surface)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## Solid upright cylinder. `pos` is its centre.
static func cylinder(parent: Node, radius: float, height: float, pos: Vector3,
		color: Color, surface: int = SurfaceType.DEFAULT) -> StaticBody3D:
	var body := _body(pos, Vector3.ZERO)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	_add_mesh(body, mesh, color, surface)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_add_shape(body, shape)
	parent.add_child(body)
	return body


## A walkable slab whose top surface runs from `low` to `high` (centre line).
## Used for ramps, slides and sloped walkways.
static func ramp(parent: Node, low: Vector3, high: Vector3, width: float, color: Color,
		thickness: float = 0.3, surface: int = SurfaceType.DEFAULT) -> StaticBody3D:
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
	_add_mesh(body, mesh, color, surface)
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
		rot_deg: Vector3 = Vector3.ZERO, emission: float = 0.0, surface: int = SurfaceType.DEFAULT) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat_styled(color, surface, -1.0, -1.0, emission)
	instance.position = pos
	instance.rotation_degrees = rot_deg
	parent.add_child(instance)
	return instance


static func deco_box(parent: Node, size: Vector3, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, emission: float = 0.0, surface: int = SurfaceType.DEFAULT) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return deco(parent, mesh, pos, color, rot_deg, emission, surface)


static func deco_sphere(parent: Node, radius: float, pos: Vector3, color: Color,
		squash: float = 1.0, emission: float = 0.0, surface: int = SurfaceType.DEFAULT) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 16
	mesh.rings = 8
	return deco(parent, mesh, pos, color, Vector3.ZERO, emission, surface)


static func deco_cylinder(parent: Node, radius: float, height: float, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, top_radius: float = -1.0, surface: int = SurfaceType.DEFAULT) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return deco(parent, mesh, pos, color, rot_deg, 0.0, surface)


static func deco_cone(parent: Node, radius: float, height: float, pos: Vector3, color: Color,
		rot_deg: Vector3 = Vector3.ZERO, surface: int = SurfaceType.DEFAULT) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.001
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return deco(parent, mesh, pos, color, rot_deg, 0.0, surface)


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
	# Signs read from the front only; from behind they'd show mirrored text.
	label.double_sided = false
	parent.add_child(label)
	return label


## A simple neighbour's house for the skyline (looks only): walls and a pitched roof.
static func house(parent: Node, at: Vector3, size: Vector3, wall: Color, roof: Color) -> void:
	deco_box(parent, size, at + Vector3(0.0, size.y * 0.5, 0.0), wall)
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x + 1.5, size.y * 0.55, size.z + 1.5)
	deco(parent, prism, at + Vector3(0.0, size.y + size.y * 0.275, 0.0), roof)


## Instantiates a 3D arena prop if available, positions it, and adds it to parent.
## Returns the instantiated Node3D, or null if models are disabled or missing.
static func prop(parent: Node, prop_id: StringName, pos: Vector3,
		rot_deg: Vector3 = Vector3.ZERO, prop_scale: Vector3 = Vector3.ONE) -> Node3D:
	if not ModelLoader.has_prop_model(prop_id):
		return null
	var instance := ModelLoader.instantiate_prop(prop_id)
	if instance == null:
		return null
	instance.position = pos
	instance.rotation_degrees = rot_deg
	if prop_scale != Vector3.ONE:
		instance.scale = prop_scale
	if parent != null and parent.name == "Decor" and instance is CollisionObject3D:
		(instance as CollisionObject3D).collision_layer = 0
	parent.add_child(instance)
	return instance


## A round cartoon tree. Uses 3D model if available with graceful procedural fallback.
static func tree(parent: Node, at: Vector3, tree_scale: float) -> void:
	if ModelLoader.has_prop_model(&"cartoon_tree"):
		var t := prop(parent, &"cartoon_tree", at, Vector3.ZERO, Vector3.ONE * tree_scale)
		if t != null:
			return
	deco_cylinder(parent, 0.5 * tree_scale, 5.0 * tree_scale, at + Vector3(0.0, 2.5 * tree_scale, 0.0), TRUNK, Vector3.ZERO, -1.0, SurfaceType.WOOD)
	deco_sphere(parent, 3.2 * tree_scale, at + Vector3(0.0, 6.5 * tree_scale, 0.0), LEAF)
	deco_sphere(parent, 2.3 * tree_scale, at + Vector3(1.2, 8.3, -0.6) * tree_scale, LEAF_LIGHT)


static func _body(pos: Vector3, rot_deg: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.position = pos
	body.rotation_degrees = rot_deg
	return body


static func _add_mesh(body: Node3D, mesh: Mesh, color: Color, surface: int = SurfaceType.DEFAULT) -> void:
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = mesh
	instance.material_override = mat_styled(color, surface)
	body.add_child(instance)


static func _add_shape(body: Node3D, shape: Shape3D) -> void:
	var node := CollisionShape3D.new()
	node.shape = shape
	body.add_child(node)
