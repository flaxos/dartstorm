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
	SANDSTONE,
	COBBLE,
	BRICK,
	SAND,
}

const WOOD_SHADER := preload("res://assets/materials/toy_wood.gdshader")

const TRUNK := Color(0.45, 0.3, 0.18)
const LEAF := Color(0.25, 0.65, 0.25)
const LEAF_LIGHT := Color(0.38, 0.78, 0.3)

static var _materials: Dictionary = {}

static var _sandstone_albedo: Texture2D = preload("res://assets/textures/arenas/sandstone_albedo.png")
static var _sandstone_normal: Texture2D = preload("res://assets/textures/arenas/sandstone_normal.png")
static var _sandstone_orm: Texture2D = preload("res://assets/textures/arenas/sandstone_orm.png")

static var _cobble_albedo: Texture2D = preload("res://assets/textures/arenas/cobble_albedo.png")
static var _cobble_normal: Texture2D = preload("res://assets/textures/arenas/cobble_normal.png")
static var _cobble_orm: Texture2D = preload("res://assets/textures/arenas/cobble_orm.png")

static var _sand_albedo: Texture2D = preload("res://assets/textures/arenas/sand_albedo.png")
static var _sand_normal: Texture2D = preload("res://assets/textures/arenas/sand_normal.png")
static var _sand_orm: Texture2D = preload("res://assets/textures/arenas/sand_orm.png")

static var _wood_normal: Texture2D = preload("res://assets/textures/arenas/wood_normal.png")
static var _wood_orm: Texture2D = preload("res://assets/textures/arenas/wood_orm.png")

static var _brick_albedo: Texture2D = preload("res://assets/textures/arenas/brick_albedo.png")
static var _brick_normal: Texture2D = preload("res://assets/textures/arenas/brick_normal.png")
static var _brick_orm: Texture2D = preload("res://assets/textures/arenas/brick_orm.png")

static var _plastic_normal: Texture2D = preload("res://assets/textures/pbr/blaster_body_normal.png")
static var _plastic_orm: Texture2D = preload("res://assets/textures/pbr/blaster_body_orm.png")
static var _metal_normal: Texture2D = preload("res://assets/textures/pbr/brushed_metal_normal.png")
static var _metal_orm: Texture2D = preload("res://assets/textures/pbr/brushed_metal_orm.png")


static func clear_materials() -> void:
	_materials.clear()


## Cached tactile material. Supports molded toy plastic, procedural timber, and brushed metal.
static func mat_styled(color: Color, surface: int = SurfaceType.DEFAULT,
		roughness: float = -1.0, metallic: float = -1.0, emission: float = 0.0) -> Material:
	if surface == SurfaceType.DEFAULT:
		# Detect desert sand / earth tones
		if (color.is_equal_approx(Color(0.88, 0.76, 0.56))
				or color.is_equal_approx(Color(0.87, 0.75, 0.55))):
			surface = SurfaceType.SAND
		# Detect sandstone / desert adobe tones
		elif (color.is_equal_approx(Color(0.86, 0.76, 0.58))
				or color.is_equal_approx(Color(0.85, 0.74, 0.55))
				or color.is_equal_approx(Color(0.74, 0.64, 0.46))
				or color.is_equal_approx(Color(0.72, 0.62, 0.44))):
			surface = SurfaceType.SANDSTONE
		# Detect desert paver / cobblestone pavement tones
		elif (color.is_equal_approx(Color(0.82, 0.72, 0.54))
				or color.is_equal_approx(Color(0.78, 0.68, 0.50))
				or color.is_equal_approx(Color(0.66, 0.60, 0.50))
				or color.is_equal_approx(Color(0.65, 0.58, 0.48))):
			surface = SurfaceType.COBBLE
		# Detect stone masonry / brick tones
		elif (color.is_equal_approx(Color(0.68, 0.70, 0.74))
				or color.is_equal_approx(Color(0.55, 0.58, 0.62))):
			surface = SurfaceType.BRICK
		# Detect timber / crate / wood tones
		elif (color.is_equal_approx(Color(0.70, 0.48, 0.30))
				or color.is_equal_approx(Color(0.68, 0.46, 0.28))
				or color.is_equal_approx(Color(0.72, 0.54, 0.36))
				or color.is_equal_approx(Color(0.55, 0.38, 0.22))
				or color.is_equal_approx(Color(0.55, 0.37, 0.22))
				or color.is_equal_approx(Color(0.76, 0.55, 0.33))
				or color.is_equal_approx(Color(0.82, 0.28, 0.20))
				or color.is_equal_approx(Color(0.45, 0.3, 0.18))
				or color.is_equal_approx(Color(0.72, 0.50, 0.30))):
			surface = SurfaceType.WOOD

	var key := "%s|%d|%.2f|%.2f|%.2f" % [color.to_html(), surface, roughness, metallic, emission]
	if _materials.has(key):
		return _materials[key]

	if surface == SurfaceType.WOOD:
		var sm := ShaderMaterial.new()
		sm.shader = WOOD_SHADER
		sm.set_shader_parameter(&"wood_tint", color)
		sm.set_shader_parameter(&"roughness", 0.72 if roughness < 0.0 else roughness)
		sm.set_shader_parameter(&"rim_strength", 0.18)
		sm.set_shader_parameter(&"texture_normal", _wood_normal)
		sm.set_shader_parameter(&"texture_orm", _wood_orm)
		_materials[key] = sm
		return sm

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	material.rim_enabled = false

	match surface:
		SurfaceType.SAND:
			material.albedo_texture = _sand_albedo
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_triplanar_sharpness = 4.0
			material.uv1_scale = Vector3(0.12, 0.12, 0.12)
			material.albedo_color = Color.WHITE if (color.is_equal_approx(Color(0.88, 0.76, 0.56)) or color.is_equal_approx(Color(0.87, 0.75, 0.55))) else color
			material.roughness = 0.94 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.05
			material.normal_enabled = true
			material.normal_texture = _sand_normal
			material.normal_scale = 0.45
			material.ao_enabled = true
			material.ao_texture = _sand_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _sand_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		SurfaceType.SANDSTONE:
			material.albedo_texture = _sandstone_albedo
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_triplanar_sharpness = 4.0
			material.uv1_scale = Vector3(0.2, 0.2, 0.2)
			material.albedo_color = Color.WHITE if (color.is_equal_approx(Color(0.86, 0.76, 0.58)) or color.is_equal_approx(Color(0.85, 0.74, 0.55))) else color
			material.roughness = 0.86 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.12
			material.normal_enabled = true
			material.normal_texture = _sandstone_normal
			material.normal_scale = 0.75
			material.ao_enabled = true
			material.ao_texture = _sandstone_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _sandstone_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		SurfaceType.COBBLE:
			material.albedo_texture = _cobble_albedo
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_triplanar_sharpness = 4.0
			material.uv1_scale = Vector3(0.18, 0.18, 0.18)
			material.albedo_color = Color.WHITE if (color.is_equal_approx(Color(0.82, 0.72, 0.54)) or color.is_equal_approx(Color(0.78, 0.68, 0.50))) else color
			material.roughness = 0.84 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.10
			material.normal_enabled = true
			material.normal_texture = _cobble_normal
			material.normal_scale = 0.75
			material.ao_enabled = true
			material.ao_texture = _cobble_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _cobble_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		SurfaceType.BRICK:
			material.albedo_texture = _brick_albedo
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_triplanar_sharpness = 4.0
			material.uv1_scale = Vector3(0.22, 0.22, 0.22)
			material.albedo_color = Color.WHITE if (color.is_equal_approx(Color(0.68, 0.70, 0.74)) or color.is_equal_approx(Color(0.55, 0.58, 0.62))) else color
			material.roughness = 0.88 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.10
			material.normal_enabled = true
			material.normal_texture = _brick_normal
			material.normal_scale = 0.85
			material.ao_enabled = true
			material.ao_texture = _brick_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _brick_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		SurfaceType.PLASTIC:
			material.roughness = 0.32 if roughness < 0.0 else roughness
			material.metallic = 0.04 if metallic < 0.0 else metallic
			material.metallic_specular = 0.35
			material.rim_enabled = true
			material.rim = 0.22
			material.rim_tint = 0.30
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
			material.metallic_specular = 0.50
			material.rim_enabled = false
			material.normal_enabled = true
			material.normal_texture = _metal_normal
			material.normal_scale = 0.45
			material.roughness_texture = _metal_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			material.metallic_texture = _metal_orm
			material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		SurfaceType.CARDBOARD:
			material.roughness = 0.88 if roughness < 0.0 else roughness
			material.metallic = 0.0 if metallic < 0.0 else metallic
			material.metallic_specular = 0.10
		_:
			# DEFAULT: Tactile molded toy plastic with micro-relief, contact AO, and rim
			material.roughness = 0.72 if roughness < 0.0 else roughness
			material.metallic = 0.02 if metallic < 0.0 else metallic
			material.metallic_specular = 0.28
			material.rim_enabled = true
			material.rim = 0.20
			material.rim_tint = 0.25
			material.normal_enabled = true
			material.normal_texture = _plastic_normal
			material.normal_scale = 0.28
			material.ao_enabled = true
			material.ao_texture = _plastic_orm
			material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			material.roughness_texture = _plastic_orm
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN

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


## High-poly stylized wooden shipping crate with beveled frame rails, metal brackets, and cross-bracing.
static func crate(parent: Node, pos: Vector3, size: Vector3 = Vector3(1.8, 1.8, 1.8),
		rot_deg: Vector3 = Vector3.ZERO, is_center_pos: bool = false) -> Node3D:
	var base_pos := pos if not is_center_pos else (pos - Vector3(0.0, size.y * 0.5, 0.0))
	if ModelLoader.has_prop_model(&"tactical_crate"):
		var p_scale := Vector3(size.x / 1.8, size.y / 1.8, size.z / 1.8)
		var p := prop(parent, &"tactical_crate", base_pos, rot_deg, p_scale)
		if p != null:
			return p
	var center := base_pos + Vector3(0.0, size.y * 0.5, 0.0)
	return box(parent, size, center, Color(0.70, 0.48, 0.30), rot_deg, SurfaceType.WOOD)


## High-poly stylized 55-gallon ribbed barrel with metal chimes, swage ribs, and dual bung plugs.
static func barrel(parent: Node, pos: Vector3, radius: float = 0.45, height: float = 1.4,
		rot_deg: Vector3 = Vector3.ZERO, is_center_pos: bool = false) -> Node3D:
	var base_pos := pos if not is_center_pos else (pos - Vector3(0.0, height * 0.5, 0.0))
	if ModelLoader.has_prop_model(&"tactical_barrel"):
		var p_scale := Vector3(radius / 0.45, height / 1.4, radius / 0.45)
		var p := prop(parent, &"tactical_barrel", base_pos, rot_deg, p_scale)
		if p != null:
			return p
	var center := base_pos + Vector3(0.0, height * 0.5, 0.0)
	return cylinder(parent, radius, height, center, Color(0.95, 0.75, 0.12), SurfaceType.PLASTIC)


## High-poly curved pill-shaped vinyl air barrier.
static func barrier(parent: Node, pos: Vector3, size: Vector3 = Vector3(2.4, 1.3, 0.65),
		rot_deg: Vector3 = Vector3.ZERO, is_center_pos: bool = false) -> Node3D:
	var base_pos := pos if not is_center_pos else (pos - Vector3(0.0, size.y * 0.5, 0.0))
	if ModelLoader.has_prop_model(&"inflatable_barrier"):
		var p_scale := Vector3(size.x / 2.4, size.y / 1.3, size.z / 0.65)
		var p := prop(parent, &"inflatable_barrier", base_pos, rot_deg, p_scale)
		if p != null:
			return p
	var center := base_pos + Vector3(0.0, size.y * 0.5, 0.0)
	return box(parent, size, center, Color(0.12, 0.55, 0.95), rot_deg, SurfaceType.PLASTIC)


## High-poly curved stone/sandstone archway with voussoirs and keystone.
static func arch(parent: Node, pos: Vector3, width: float = 4.4, height: float = 5.0,
		depth: float = 1.2, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	if ModelLoader.has_prop_model(&"archway_curved"):
		var p_scale := Vector3(width / 4.4, height / 5.0, depth / 1.2)
		var p := prop(parent, &"archway_curved", pos, rot_deg, p_scale)
		if p != null:
			return p
	var body := _body(pos, rot_deg)
	var pillar_w := width * 0.18
	var span := width - pillar_w * 2.0
	box(body, Vector3(pillar_w, height, depth), Vector3(-span * 0.5 - pillar_w * 0.5, height * 0.5, 0.0), Color(0.86, 0.76, 0.58), Vector3.ZERO, SurfaceType.SANDSTONE)
	box(body, Vector3(pillar_w, height, depth), Vector3(span * 0.5 + pillar_w * 0.5, height * 0.5, 0.0), Color(0.86, 0.76, 0.58), Vector3.ZERO, SurfaceType.SANDSTONE)
	box(body, Vector3(width, height * 0.25, depth), Vector3(0.0, height * 0.875, 0.0), Color(0.74, 0.64, 0.46), Vector3.ZERO, SurfaceType.SANDSTONE)
	parent.add_child(body)
	return body


## Stylized fabric market awning with diagonal wall mounting struts.
static func awning(parent: Node, pos: Vector3, width: float = 3.6, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	if ModelLoader.has_prop_model(&"market_awning"):
		var p_scale := Vector3(width / 3.6, 1.0, 1.0)
		return prop(parent, &"market_awning", pos, rot_deg, p_scale)
	return null


## Terracotta amphora / pottery urn.
static func urn(parent: Node, pos: Vector3, scale_mult: float = 1.0, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	if ModelLoader.has_prop_model(&"desert_urn"):
		return prop(parent, &"desert_urn", pos, rot_deg, Vector3.ONE * scale_mult)
	return null


## Heavy-duty wooden shipping pallet.
static func pallet(parent: Node, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> Node3D:
	if ModelLoader.has_prop_model(&"wooden_pallet"):
		return prop(parent, &"wooden_pallet", pos, rot_deg)
	return null


## Decorative architectural cornice / crown molding trim along walls.
static func cornice(parent: Node, pos: Vector3, size: Vector3, color: Color = Color(0.74, 0.64, 0.46),
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return deco_box(parent, size, pos, color, rot_deg, 0.0, SurfaceType.SANDSTONE)



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
