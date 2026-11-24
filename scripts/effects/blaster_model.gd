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
static var _body_normal: Texture2D = preload("res://assets/textures/pbr/blaster_body_normal.png")
static var _body_orm: Texture2D = preload("res://assets/textures/pbr/blaster_body_orm.png")
static var _detail_normal: Texture2D = preload("res://assets/textures/pbr/micro_detail_normal.png")
static var _grip_normal: Texture2D = preload("res://assets/textures/pbr/rubber_grip_normal.png")
static var _grip_mat: StandardMaterial3D = null
static var _skin_materials: Dictionary = {}

static func clear_skin_materials() -> void:
	_skin_materials.clear()
	_grip_mat = null

static func _grip_material() -> StandardMaterial3D:
	if _grip_mat == null:
		_grip_mat = StandardMaterial3D.new()
		_grip_mat.albedo_color = Color(DARK.r, DARK.g, DARK.b, 1.0)
		_grip_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_grip_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		_grip_mat.cull_mode = BaseMaterial3D.CULL_BACK
		_grip_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		_grip_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		_grip_mat.roughness = 0.85
		_grip_mat.normal_enabled = true
		_grip_mat.normal_texture = _grip_normal
		_grip_mat.normal_scale = 0.5
	return _grip_mat

var model_root: Node3D = null
var grip_marker: Marker3D = null
var foregrip_marker: Marker3D = null
var equipped_attachments: Dictionary = {}
var attachment_nodes: Dictionary = {}
var _spinner: Node3D
var _cylinder: Node3D = null
var _pump_slide: Node3D = null
var _slide: Node3D = null
var _recoil_z: float = 0.0
var _recoil_pitch: float = 0.0
var _pump_cycle: float = 0.0
var _slide_cycle: float = 0.0
var _belt: Array[Node3D] = []
var _belt_phase: float = 0.0
var _spin: float = 0.0
var _flash: MeshInstance3D
var _flash_left: float = 0.0


static func create(p_data: WeaponData, p_first_person: bool, p_skin_id: StringName = &"", p_attachments: Dictionary = {}) -> BlasterModel:
	var model := BlasterModel.new()
	model.data = p_data
	model.first_person = p_first_person
	if not p_skin_id.is_empty():
		model.skin_id = p_skin_id
	elif p_first_person:
		model.skin_id = GameSettings.player_skin
	else:
		model.skin_id = &"default"
	if not p_attachments.is_empty():
		model.equipped_attachments = p_attachments.duplicate()
	elif p_first_person and is_instance_valid(Progression) and p_data != null:
		model.equipped_attachments = Progression.get_equipped_attachments(p_data.id)
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

	# Moving mechanical parts response
	if _cylinder != null:
		_cylinder.rotate_z(deg_to_rad(60.0))
	if _pump_slide != null:
		_pump_cycle = 1.0
	if _slide != null:
		_slide_cycle = 1.0

	var kick := data.recoil_kick if data != null else 1.0
	_recoil_z = 0.03 * kick
	_recoil_pitch = 0.04 * kick


func _process(delta: float) -> void:
	if _spinner != null and _spin > 0.0:
		_spinner.rotate_z(_spin * BARREL_SPIN_SPEED * delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash.visible = false

	# Procedural recoil damping
	if _recoil_z > 0.001 or _recoil_pitch > 0.001:
		_recoil_z = move_toward(_recoil_z, 0.0, delta * 0.35)
		_recoil_pitch = move_toward(_recoil_pitch, 0.0, delta * 0.5)
		if model_root != null:
			model_root.position.z = _recoil_z
			model_root.rotation.x = _recoil_pitch

	# Pump action slide cycle
	if _pump_cycle > 0.0:
		_pump_cycle = move_toward(_pump_cycle, 0.0, delta * 4.0)
		if _pump_slide != null:
			_pump_slide.position.z = -0.20 + sin(_pump_cycle * PI) * 0.06

	# Semi-auto pistol slide cycle
	if _slide_cycle > 0.0:
		_slide_cycle = move_toward(_slide_cycle, 0.0, delta * 6.0)
		if _slide != null:
			_slide.position.z = -0.05 + _slide_cycle * 0.035


func _build() -> void:
	muzzle = Marker3D.new()
	add_child(muzzle)
	if not _build_from_model():
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
	_build_attachments()


## Updates equipped attachments and rebuilds their 3D meshes without rebuilding the whole blaster.
func update_attachments(p_attachments: Dictionary) -> void:
	equipped_attachments = p_attachments.duplicate()
	_build_attachments()


func _build_attachments() -> void:
	for child in attachment_nodes.values():
		if is_instance_valid(child):
			child.queue_free()
	attachment_nodes.clear()

	if equipped_attachments.is_empty():
		return

	var b_id: StringName = data.id if data != null else &""
	for slot_name in equipped_attachments:
		var att_id: StringName = equipped_attachments[slot_name]
		if att_id.is_empty() or att_id == &"none":
			continue
		var node := BlasterAttachments.build_attachment(self, att_id, slot_name, b_id)
		if node != null:
			node.transform = get_slot_transform(slot_name)
			if first_person:
				_disable_shadows_recursive(node)
			attachment_nodes[slot_name] = node

			# If muzzle attachment, offset flash forward
			if slot_name == &"barrel" and _flash != null:
				match att_id:
					&"rifled_extension":
						_flash.position.z = muzzle.position.z - 0.15
					&"mega_compensator":
						_flash.position.z = muzzle.position.z - 0.07
					&"whisper_shroud":
						_flash.position.z = muzzle.position.z - 0.17


func _disable_shadows_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows_recursive(child)


func get_slot_transform(slot: StringName) -> Transform3D:
	var tf := Transform3D.IDENTITY
	var style: int = data.model_style if data != null else WeaponData.ModelStyle.PISTOL
	var s := str(slot).to_lower()

	match s:
		"optic":
			match style:
				WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
					tf.origin = Vector3(0.0, 0.08, -0.05)
				WeaponData.ModelStyle.SPRAYER:
					tf.origin = Vector3(0.0, 0.09, -0.1)
				WeaponData.ModelStyle.HAMMER:
					tf.origin = Vector3(0.0, 0.08, -0.05)
				WeaponData.ModelStyle.RIFLE:
					tf.origin = Vector3(0.0, 0.12, -0.05)
				WeaponData.ModelStyle.ROTARY:
					tf.origin = Vector3(0.0, 0.19, 0.03)
				_:
					tf.origin = Vector3(0.0, muzzle.position.y + 0.07, muzzle.position.z * 0.4)
		"barrel":
			if muzzle != null:
				tf.origin = muzzle.position
			else:
				tf.origin = Vector3(0.0, 0.01, -0.3)
		"magazine":
			match style:
				WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
					tf.origin = Vector3(0.0, -0.16, 0.06)
				WeaponData.ModelStyle.SPRAYER:
					tf.origin = Vector3(0.0, -0.155, -0.14)
				WeaponData.ModelStyle.HAMMER:
					tf.origin = Vector3(0.0, -0.085, -0.12)
				WeaponData.ModelStyle.RIFLE:
					tf.origin = Vector3(0.0, -0.06, 0.02)
				WeaponData.ModelStyle.ROTARY:
					tf.origin = Vector3(0.15, -0.01, 0.07)
				_:
					tf.origin = Vector3(0.0, -0.10, 0.0)
		"stock":
			match style:
				WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
					tf.origin = Vector3(0.0, -0.03, 0.10)
				WeaponData.ModelStyle.SPRAYER:
					tf.origin = Vector3(0.0, -0.01, 0.34)
				WeaponData.ModelStyle.HAMMER:
					tf.origin = Vector3(0.0, -0.02, 0.37)
				WeaponData.ModelStyle.RIFLE:
					tf.origin = Vector3(0.0, -0.02, 0.43)
				WeaponData.ModelStyle.ROTARY:
					tf.origin = Vector3(0.0, -0.05, 0.22)
				_:
					tf.origin = Vector3(0.0, -0.02, 0.25)
		"spring":
			match style:
				WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
					tf.origin = Vector3(0.038, 0.02, -0.05)
				WeaponData.ModelStyle.SPRAYER:
					tf.origin = Vector3(0.048, 0.02, -0.1)
				WeaponData.ModelStyle.HAMMER:
					tf.origin = Vector3(0.058, 0.02, -0.05)
				WeaponData.ModelStyle.RIFLE:
					tf.origin = Vector3(0.038, 0.02, -0.05)
				WeaponData.ModelStyle.ROTARY:
					tf.origin = Vector3(0.105, 0.05, 0.05)
				_:
					tf.origin = Vector3(0.04, 0.02, 0.0)

	return tf


## Computes the first-person ADS offset so the optic or iron sights center on the camera.
func get_ads_offset() -> Vector3:
	var sight_pos := Vector3(0.0, 0.10, -0.05)
	if equipped_attachments.has(&"optic") and equipped_attachments[&"optic"] != &"none" and equipped_attachments[&"optic"] != &"iron_sights":
		var opt_id: StringName = equipped_attachments[&"optic"]
		var socket := get_slot_transform(&"optic").origin
		var opt_y := 0.038
		if opt_id == &"holo_sight":
			opt_y = 0.045
		sight_pos = socket + Vector3(0.0, opt_y, 0.0)
	elif muzzle != null:
		sight_pos = Vector3(0.0, muzzle.position.y + 0.035, muzzle.position.z * 0.5)
	else:
		sight_pos = Vector3(0.0, 0.08, -0.15)

	var target_z := -0.28
	return Vector3(
		-sight_pos.x,
		-sight_pos.y,
		target_z - sight_pos.z
	)



func _build_from_model() -> bool:
	if data == null or not is_instance_valid(ModelLoader):
		return false
	if not ModelLoader.has_blaster_model(data.id):
		return false
	var model_node := ModelLoader.instantiate_blaster(data.id)
	if model_node == null:
		return false
	model_root = model_node
	add_child(model_node)

	var chassis_mat := get_chassis_material()
	var mat_map := {
		"chassis": chassis_mat,
		"hardware": ArenaKit.mat_styled(data.accent_color, ArenaKit.SurfaceType.METAL),
		"safety": ArenaKit.mat_styled(ORANGE_TIP, ArenaKit.SurfaceType.PLASTIC),
		"grip": _grip_material()
	}
	ModelLoader.apply_materials_recursive(model_node, mat_map)

	if chassis_mat is ShaderMaterial:
		_setup_shader_uniforms_recursive(model_node, model_node)

	var found_muzzle := model_node.find_child("Muzzle*", true, false)
	if found_muzzle is Node3D:
		muzzle.position = (found_muzzle as Node3D).position
	else:
		muzzle.position = Vector3(0.0, 0.02, -0.32)

	var found_grip := model_node.find_child("GripMarker", true, false)
	if found_grip is Marker3D:
		grip_marker = found_grip as Marker3D

	var found_foregrip := model_node.find_child("ForegripMarker", true, false)
	if found_foregrip is Marker3D:
		foregrip_marker = found_foregrip as Marker3D

	var found_spinner := model_node.find_child("Spinner*", true, false)
	if found_spinner is Node3D:
		_spinner = found_spinner as Node3D

	var found_cyl := model_node.find_child("Cylinder*", true, false)
	if found_cyl is Node3D:
		_cylinder = found_cyl as Node3D

	var found_pump := model_node.find_child("PumpSlide*", true, false)
	if found_pump is Node3D:
		_pump_slide = found_pump as Node3D

	var found_slide := model_node.find_child("Slide*", true, false)
	if found_slide is Node3D:
		_slide = found_slide as Node3D

	return true


func _setup_shader_uniforms_recursive(node: Node, root: Node3D) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.name.to_lower().contains("chassis"):
			var local_pos := _get_relative_position(mi, root)
			mi.set_instance_shader_parameter(&"part_offset", local_pos)
			mi.set_instance_shader_parameter(&"part_rot", Vector3.ZERO)
	for child in node.get_children():
		_setup_shader_uniforms_recursive(child, root)


func _get_relative_position(node: Node3D, root: Node3D) -> Vector3:
	var pos := Vector3.ZERO
	var curr: Node3D = node
	while curr != null and curr != root:
		pos += curr.position
		curr = curr.get_parent() as Node3D
	return pos


func get_chassis_material() -> Material:
	var b_col := data.body_color if data != null else Color.WHITE
	var a_col := data.accent_color if data != null else Color.WHITE
	var has_custom_skin := skin_id != &"default" and not skin_id.is_empty() and Cosmetics.has_skin(skin_id)
	if has_custom_skin:
		var mat_key := "%s_%s_%s" % [skin_id, b_col.to_html(false), a_col.to_html(false)]
		var skin_mat: ShaderMaterial = _skin_materials.get(mat_key, null)
		if skin_mat == null:
			skin_mat = ShaderMaterial.new()
			skin_mat.shader = _skin_shader
			skin_mat.set_shader_parameter("body_color", b_col)
			skin_mat.set_shader_parameter("accent_color", a_col)
			skin_mat.set_shader_parameter("texture_normal", _body_normal)
			skin_mat.set_shader_parameter("texture_orm", _body_orm)
			skin_mat.set_shader_parameter("texture_detail_normal", _detail_normal)
			skin_mat.set_shader_parameter("normal_scale", 1.0)
			skin_mat.set_shader_parameter("detail_normal_scale", 20.0)
			var pattern_path: String = Cosmetics.skin_pattern(skin_id)
			if ResourceLoader.exists(pattern_path):
				skin_mat.set_shader_parameter("skin_pattern", load(pattern_path))
			skin_mat.set_shader_parameter("finish_mode", Cosmetics.skin_finish(skin_id))
			_skin_materials[mat_key] = skin_mat
		return skin_mat
	return ArenaKit.mat_styled(b_col, ArenaKit.SurfaceType.PLASTIC, 0.32, 0.0)


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
	mesh.radial_segments = 24
	mesh.rings = 2
	return _part(mesh, pos, color, Vector3(90.0, 0.0, 0.0), parent, metallic)


func _part(mesh: Mesh, pos: Vector3, color: Color, rot_deg: Vector3, parent: Node3D,
		metallic: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var is_chassis := not color.is_equal_approx(ORANGE_TIP) and not color.is_equal_approx(DARK) and metallic < 0.2
	var has_custom_skin := skin_id != &"default" and not skin_id.is_empty() and Cosmetics.has_skin(skin_id)
	if is_chassis and has_custom_skin:
		var b_col := data.body_color if data != null else color
		var a_col := data.accent_color if data != null else color
		var mat_key := "%s_%s_%s" % [skin_id, b_col.to_html(false), a_col.to_html(false)]
		var skin_mat: ShaderMaterial = _skin_materials.get(mat_key, null)
		if skin_mat == null:
			skin_mat = ShaderMaterial.new()
			skin_mat.shader = _skin_shader
			skin_mat.set_shader_parameter("body_color", b_col)
			skin_mat.set_shader_parameter("accent_color", a_col)
			skin_mat.set_shader_parameter("texture_normal", _body_normal)
			skin_mat.set_shader_parameter("texture_orm", _body_orm)
			skin_mat.set_shader_parameter("texture_detail_normal", _detail_normal)
			skin_mat.set_shader_parameter("normal_scale", 1.0)
			skin_mat.set_shader_parameter("detail_normal_scale", 20.0)
			var pattern_path: String = Cosmetics.skin_pattern(skin_id)
			if ResourceLoader.exists(pattern_path):
				skin_mat.set_shader_parameter("skin_pattern", load(pattern_path))
			skin_mat.set_shader_parameter("finish_mode", Cosmetics.skin_finish(skin_id))
			_skin_materials[mat_key] = skin_mat
		instance.material_override = skin_mat
		var part_offset := pos
		var part_rot := rot_deg
		if parent != null and parent != self:
			part_offset += parent.position
			part_rot += parent.rotation_degrees
		instance.set_instance_shader_parameter("part_offset", part_offset)
		instance.set_instance_shader_parameter("part_rot", part_rot)
	elif color.is_equal_approx(DARK) and metallic < 0.2:
		instance.material_override = _grip_material()
	elif metallic > 0.4:
		instance.material_override = ArenaKit.mat_styled(color, ArenaKit.SurfaceType.METAL, 0.24, metallic)
	else:
		instance.material_override = ArenaKit.mat_styled(color, ArenaKit.SurfaceType.PLASTIC, 0.45, metallic)
	instance.position = pos
	instance.rotation_degrees = rot_deg
	if first_person:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent != null:
		parent.add_child(instance)
	else:
		add_child(instance)
	return instance
