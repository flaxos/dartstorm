class_name BlasterModel
extends Node3D
## Presentation for a blaster, built from primitive meshes using the
## "Presentation" fields of a WeaponData. The same model is used for the
## first-person view and (scaled up) in a bot's hands. Forward is -Z.

const BARREL_SPIN_SPEED := 30.0
const BELT_LINKS := 14
const ORANGE_TIP := Color(1.0, 0.45, 0.05)
const DARK := Color(0.13, 0.16, 0.24)

var data: WeaponData
var first_person: bool = false
var muzzle: Marker3D

var skin_id: StringName = &"default"
static var _skin_shader: Shader = preload("res://assets/materials/blaster_skin.gdshader")

var _spinner: Node3D
var _belt: Array[Node3D] = []
var _belt_phase: float = 0.0
var _spin: float = 0.0
var _flash: MeshInstance3D
var _flash_left: float = 0.0


static func create(p_data: WeaponData, p_first_person: bool, p_skin_id: StringName = &"") -> BlasterModel:
	var model := BlasterModel.new()
	model.data = p_data
	model.first_person = p_first_person
	if not p_skin_id.is_empty():
		model.skin_id = p_skin_id
	elif p_first_person:
		model.skin_id = GameSettings.player_skin
	else:
		model.skin_id = &"default"
	model._build()
	return model


## 0..1 barrel spin for rotary blasters.
func set_spin(ratio: float) -> void:
	_spin = ratio


## Shows the muzzle puff for one shot.
func flash() -> void:
	if _flash == null:
		return
	_flash_left = 0.05
	_flash.visible = true
	var burst := randf_range(0.7, 1.3) * clampf(GameSettings.visual_intensity, 0.3, 1.5)
	_flash.scale = Vector3.ONE * burst
	_flash.rotation.z = randf() * TAU
	if not _belt.is_empty():
		_belt_phase = fposmod(_belt_phase - 0.5, 1.0)
		_layout_belt()


func _process(delta: float) -> void:
	if _spinner != null and _spin > 0.0:
		_spinner.rotate_z(_spin * BARREL_SPIN_SPEED * delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash.visible = false


func _build() -> void:
	muzzle = Marker3D.new()
	add_child(muzzle)
	match data.model_style:
		WeaponData.ModelStyle.PISTOL:
			_build_pistol(false)
		WeaponData.ModelStyle.DOUBLE:
			_build_pistol(true)
		WeaponData.ModelStyle.SPRAYER:
			_build_sprayer()
		WeaponData.ModelStyle.ROTARY:
			_build_rotary()
		WeaponData.ModelStyle.HAMMER:
			_build_hammer()
		WeaponData.ModelStyle.RIFLE:
			_build_rifle()
	_build_flash()


func _build_pistol(double_barrel: bool) -> void:
	var body := data.body_color
	var accent := data.accent_color
	var width := 0.11 if double_barrel else 0.07
	_box(Vector3(width, 0.1, 0.3), Vector3(0.0, 0.0, -0.05), body)
	_box(Vector3(width + 0.006, 0.035, 0.32), Vector3(0.0, 0.066, -0.05), accent)
	_box(Vector3(0.058, 0.15, 0.07), Vector3(0.0, -0.11, 0.06), DARK, Vector3(-14.0, 0.0, 0.0))
	_box(Vector3(0.02, 0.02, 0.09), Vector3(0.0, -0.065, -0.02), DARK)
	if double_barrel:
		for side: float in [-1.0, 1.0]:
			_tube(0.027, 0.07, Vector3(side * 0.028, 0.01, -0.23), ORANGE_TIP)
	else:
		_tube(0.028, 0.07, Vector3(0.0, 0.01, -0.23), ORANGE_TIP)
	muzzle.position = Vector3(0.0, 0.01, -0.28)


func _build_sprayer() -> void:
	var body := data.body_color
	var accent := data.accent_color
	_box(Vector3(0.09, 0.12, 0.5), Vector3(0.0, 0.0, -0.1), body)
	_box(Vector3(0.03, 0.03, 0.32), Vector3(0.0, 0.075, -0.1), accent)
	_box(Vector3(0.06, 0.21, 0.09), Vector3(0.0, -0.155, -0.14), accent, Vector3(8.0, 0.0, 0.0))
	_box(Vector3(0.06, 0.09, 0.2), Vector3(0.0, -0.01, 0.24), DARK)
	_box(Vector3(0.055, 0.14, 0.06), Vector3(0.0, -0.115, 0.08), DARK, Vector3(-14.0, 0.0, 0.0))
	_tube(0.03, 0.2, Vector3(0.0, 0.01, -0.44), ORANGE_TIP)
	_tube(0.046, 0.04, Vector3(0.0, 0.01, -0.55), accent)
	muzzle.position = Vector3(0.0, 0.01, -0.58)


func _build_hammer() -> void:
	var body := data.body_color
	var accent := data.accent_color
	_box(Vector3(0.11, 0.13, 0.4), Vector3(0.0, 0.0, -0.05), body)
	_box(Vector3(0.115, 0.04, 0.2), Vector3(0.0, -0.085, -0.2), accent)
	_box(Vector3(0.06, 0.09, 0.22), Vector3(0.0, -0.02, 0.26), DARK)
	_box(Vector3(0.055, 0.14, 0.06), Vector3(0.0, -0.12, 0.1), DARK, Vector3(-14.0, 0.0, 0.0))
	_tube(0.062, 0.26, Vector3(0.0, 0.01, -0.36), ORANGE_TIP)
	_tube(0.074, 0.05, Vector3(0.0, 0.01, -0.49), accent)
	muzzle.position = Vector3(0.0, 0.01, -0.53)


func _build_rifle() -> void:
	var body := data.body_color
	var accent := data.accent_color
	_box(Vector3(0.07, 0.1, 0.5), Vector3(0.0, 0.0, -0.05), body)
	_box(Vector3(0.055, 0.1, 0.26), Vector3(0.0, -0.02, 0.3), DARK)
	_box(Vector3(0.05, 0.14, 0.06), Vector3(0.0, -0.11, 0.1), DARK, Vector3(-14.0, 0.0, 0.0))
	_tube(0.024, 0.55, Vector3(0.0, 0.01, -0.55), accent)
	_tube(0.03, 0.06, Vector3(0.0, 0.01, -0.84), ORANGE_TIP)
	_tube(0.032, 0.24, Vector3(0.0, 0.095, -0.05), DARK)
	_tube(0.038, 0.03, Vector3(0.0, 0.095, -0.18), accent)
	muzzle.position = Vector3(0.0, 0.01, -0.88)


## FLAX'S CHAINSTORM: six spinning barrels, a chunky housing and a dart belt.
func _build_rotary() -> void:
	var body := data.body_color
	var accent := data.accent_color
	_box(Vector3(0.2, 0.2, 0.34), Vector3(0.0, 0.0, 0.05), body)
	_box(Vector3(0.206, 0.035, 0.345), Vector3(0.0, 0.055, 0.05), accent)
	_box(Vector3(0.206, 0.035, 0.345), Vector3(0.0, -0.055, 0.05), accent)
	_tube(0.125, 0.12, Vector3(0.0, 0.0, -0.17), DARK)
	# Carry handle on top and a grip at the back.
	_box(Vector3(0.03, 0.03, 0.24), Vector3(0.0, 0.17, 0.03), DARK)
	_box(Vector3(0.03, 0.07, 0.03), Vector3(0.0, 0.135, -0.07), DARK)
	_box(Vector3(0.03, 0.07, 0.03), Vector3(0.0, 0.135, 0.13), DARK)
	_box(Vector3(0.06, 0.16, 0.06), Vector3(0.0, -0.16, 0.14), DARK, Vector3(-12.0, 0.0, 0.0))
	# Ammo feed box on the right where the belt enters.
	_box(Vector3(0.1, 0.13, 0.15), Vector3(0.15, -0.01, 0.07), accent)

	_spinner = Node3D.new()
	_spinner.position = Vector3(0.0, 0.0, -0.22)
	add_child(_spinner)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		var offset := Vector3(cos(angle), sin(angle), 0.0) * 0.078
		_tube(0.024, 0.5, offset + Vector3(0.0, 0.0, -0.24), Color(0.35, 0.4, 0.5), _spinner, 0.6)
		_tube(0.029, 0.045, offset + Vector3(0.0, 0.0, -0.505), ORANGE_TIP, _spinner)
	_tube(0.115, 0.022, Vector3(0.0, 0.0, -0.2), accent, _spinner)
	_tube(0.115, 0.022, Vector3(0.0, 0.0, -0.42), accent, _spinner)
	_tube(0.03, 0.5, Vector3(0.0, 0.0, -0.24), DARK, _spinner)
	muzzle.position = Vector3(0.0, 0.0, -0.76)

	# The belt of darts hanging down toward the backpack.
	for i in BELT_LINKS:
		var link := Node3D.new()
		add_child(link)
		_tube(0.017, 0.085, Vector3.ZERO, Color(0.3, 0.65, 1.0), link)
		_tube(0.021, 0.022, Vector3(0.0, 0.0, -0.05), ORANGE_TIP, link)
		_belt.append(link)
	_layout_belt()

	var plate := Label3D.new()
	plate.text = "FLAX'S\nCHAINSTORM"
	plate.font = UiKit.font()
	plate.font_size = 40
	plate.pixel_size = 0.0011
	plate.outline_size = 8
	plate.outline_modulate = UiKit.NAVY_DARK
	plate.modulate = UiKit.CREAM
	plate.position = Vector3(-0.106, 0.0, 0.05)
	plate.rotation_degrees.y = -90.0
	add_child(plate)


func _layout_belt() -> void:
	var start := Vector3(0.2, -0.03, 0.07)
	var bend := Vector3(0.42, -0.08, 0.2)
	var finish := Vector3(0.5, -0.8, 0.5)
	for i in _belt.size():
		var t := (float(i) + _belt_phase) / float(_belt.size())
		var a := start.lerp(bend, t)
		var b := bend.lerp(finish, t)
		_belt[i].position = a.lerp(b, t)


func _build_flash() -> void:
	_flash = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	var flash_radius := 0.09 if data.model_style == WeaponData.ModelStyle.ROTARY else 0.06
	mesh.radius = flash_radius
	mesh.height = flash_radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	_flash.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.95, 0.6, 0.75)
	_flash.material_override = material
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.position = muzzle.position + Vector3(0.0, 0.0, -0.04)
	_flash.visible = false
	add_child(_flash)


func _box(size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO,
		parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part(mesh, pos, color, rot_deg, parent, 0.0)


## A cylinder lying along the barrel axis (Z).
func _tube(radius: float, length: float, pos: Vector3, color: Color, parent: Node3D = null,
		metallic: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 12
	mesh.rings = 1
	return _part(mesh, pos, color, Vector3(90.0, 0.0, 0.0), parent, metallic)


func _part(mesh: Mesh, pos: Vector3, color: Color, rot_deg: Vector3, parent: Node3D,
		metallic: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var is_chassis := not color.is_equal_approx(ORANGE_TIP) and not color.is_equal_approx(DARK) and metallic < 0.2
	if is_chassis and Cosmetics.has_skin(skin_id):
		var skin_mat := ShaderMaterial.new()
		skin_mat.shader = _skin_shader
		var b_col := data.body_color if data != null else color
		var a_col := data.accent_color if data != null else color
		skin_mat.set_shader_parameter("body_color", b_col)
		skin_mat.set_shader_parameter("accent_color", a_col)
		var pattern_path: String = Cosmetics.skin_pattern(skin_id)
		if ResourceLoader.exists(pattern_path):
			skin_mat.set_shader_parameter("skin_pattern", load(pattern_path))
		skin_mat.set_shader_parameter("finish_mode", Cosmetics.skin_finish(skin_id))
		instance.material_override = skin_mat
	else:
		instance.material_override = ArenaKit.mat(color, 0.85 if color.is_equal_approx(DARK) else 0.5, metallic)
	instance.position = pos
	instance.rotation_degrees = rot_deg
	if first_person:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent != null:
		parent.add_child(instance)
	else:
		add_child(instance)
	return instance
