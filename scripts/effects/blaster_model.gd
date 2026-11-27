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
var _model_asset_id: StringName = &""
var _iron_sights_node: Node3D = null
var _spinner: Node3D
var _cylinder: Node3D = null
var _pump_slide: Node3D = null
var _slide: Node3D = null
var _recoil_z: float = 0.0
var _recoil_pitch: float = 0.0
var _swing_phase: float = -1.0
var _pump_cycle: float = 0.0
var _slide_cycle: float = 0.0
var _belt: Array[Node3D] = []
var _belt_phase: float = 0.0
var _spin: float = 0.0
var _flash: Node3D
var _flash_light: OmniLight3D = null
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
	if p_data != null and p_data.is_melee():
		model.equipped_attachments = {}
	elif not p_attachments.is_empty():
		model.equipped_attachments = p_attachments.duplicate()
	elif p_first_person and is_instance_valid(Progression) and p_data != null:
		model.equipped_attachments = Progression.get_equipped_attachments(p_data.id)
	model._build()
	return model


## 0..1 barrel spin for rotary blasters.
func set_spin(ratio: float) -> void:
	_spin = ratio


## Plays a snappy diagonal cartoon baseball swing animation on melee models.
func swing() -> void:
	_swing_phase = 0.0


## Shows the muzzle star burst + brief dynamic light for one shot (or swings for melee).
func flash(recoil_mult: float = 1.0) -> void:
	if data != null and data.is_melee():
		swing()
		return
	if _flash == null:
		return
	_flash_left = 0.055
	_flash.visible = true
	var intensity := clampf(GameSettings.visual_intensity, 0.3, 1.5)
	var burst := randf_range(0.75, 1.35) * intensity
	_flash.scale = Vector3.ONE * burst
	_flash.rotation.z = randf() * TAU
	if _flash_light != null:
		_flash_light.visible = true
		_flash_light.light_energy = (2.8 if data != null and data.model_style == WeaponData.ModelStyle.ROTARY else 2.2) * intensity
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

	var kick := (data.recoil_kick if data != null else 1.0) * recoil_mult
	_recoil_z = 0.03 * kick
	_recoil_pitch = 0.04 * kick


func _process(delta: float) -> void:
	if _spinner != null and _spin > 0.0:
		_spinner.rotate_z(_spin * BARREL_SPIN_SPEED * delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_light != null:
			_flash_light.light_energy = maxf(_flash_light.light_energy - delta * 55.0, 0.0)
		if _flash_left <= 0.0:
			_flash.visible = false
			if _flash_light != null:
				_flash_light.visible = false

	# Diagonal cartoon foam-bat swing animation
	if _swing_phase >= 0.0:
		_swing_phase += delta / 0.36
		if _swing_phase >= 1.0:
			_swing_phase = -1.0
			if model_root != null:
				model_root.position = Vector3.ZERO
				model_root.rotation = Vector3.ZERO
		elif model_root != null:
			if _swing_phase < 0.20:
				# Crisp wind-up cock back to upper-right
				var u := smoothstep(0.0, 0.20, _swing_phase)
				model_root.position = Vector3(0.11 * u, 0.07 * u, 0.05 * u)
				model_root.rotation = Vector3(0.32 * u, -0.35 * u, -0.35 * u)
			elif _swing_phase < 0.52:
				# Explosive diagonal home-run slash across screen center
				var u := smoothstep(0.20, 0.52, _swing_phase)
				model_root.position = Vector3(lerpf(0.11, -0.38, u), lerpf(0.07, -0.06, u), lerpf(0.05, -0.18, u))
				model_root.rotation = Vector3(lerpf(0.32, -1.15, u), lerpf(-0.35, 0.95, u), lerpf(-0.35, 1.38, u))
			else:
				# Smooth eased recovery to ready batting stance
				var u := smoothstep(0.52, 1.0, _swing_phase)
				model_root.position = Vector3(lerpf(-0.38, 0.0, u), lerpf(-0.06, 0.0, u), lerpf(-0.18, 0.0, u))
				model_root.rotation = Vector3(lerpf(-1.15, 0.0, u), lerpf(0.95, 0.0, u), lerpf(1.38, 0.0, u))

	# Procedural recoil damping
	if _swing_phase < 0.0 and (_recoil_z > 0.001 or _recoil_pitch > 0.001):
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
	if not _build_from_model():
		model_root = Node3D.new()
		model_root.name = "ProceduralRoot"
		add_child(model_root)
		model_root.add_child(muzzle)
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
			WeaponData.ModelStyle.BAT:
				_build_bat()
	else:
		model_root.add_child(muzzle)
		if first_person:
			_disable_shadows_recursive(model_root)
	_build_flash()
	_build_attachments()


## Updates equipped attachments and rebuilds their 3D meshes without rebuilding the whole blaster.
func update_attachments(p_attachments: Dictionary) -> void:
	equipped_attachments = p_attachments.duplicate()
	_build_attachments()


func _equipped_attachment(slot: StringName) -> StringName:
	var raw: Variant = equipped_attachments.get(slot, equipped_attachments.get(String(slot), &"none"))
	var att := StringName(str(raw))
	return att if not att.is_empty() else &"none"


func _has_aftermarket_optic() -> bool:
	var opt := _equipped_attachment(&"optic")
	return opt != &"none" and opt != &"iron_sights"


func _build_attachments() -> void:
	for child in attachment_nodes.values():
		if is_instance_valid(child):
			child.queue_free()
	attachment_nodes.clear()
	if _iron_sights_node != null and is_instance_valid(_iron_sights_node):
		_iron_sights_node.queue_free()
		_iron_sights_node = null

	# Always reset muzzle flash to base barrel tip so unequipping a barrel resets it cleanly
	if _flash != null and muzzle != null:
		_flash.position = muzzle.position + Vector3(0.0, 0.0, -0.04)

	if data != null and data.is_melee():
		return

	var attach_parent: Node3D = model_root if model_root != null else self
	var has_custom_optic := _has_aftermarket_optic()

	# Hide built-in Scope on whisper models when an aftermarket optic replaces it
	if model_root != null:
		var builtin_scope := model_root.find_child("Scope", false, false) as Node3D
		if builtin_scope != null:
			builtin_scope.visible = not has_custom_optic

	var b_id: StringName = data.id if data != null else &""
	for slot_name in equipped_attachments:
		var slot_key := StringName(str(slot_name))
		var att_id := StringName(str(equipped_attachments[slot_name]))
		if att_id.is_empty() or att_id == &"none" or att_id == &"iron_sights":
			continue
		var node := BlasterAttachments.build_attachment(attach_parent, att_id, slot_key, b_id)
		if node != null:
			if att_id == &"tactical_grip":
				# Angled foregrip mounts on the under-barrel front rail instead of rear buttstock
				var grip_pos := foregrip_marker.position if foregrip_marker != null else Vector3(0.0, -0.055, -0.18)
				node.transform = Transform3D(Basis.IDENTITY, grip_pos)
			else:
				node.transform = get_slot_transform(slot_key)
			if first_person:
				_disable_shadows_recursive(node)
			attachment_nodes[slot_key] = node

			# If muzzle attachment, offset flash forward
			if slot_key == &"barrel" and _flash != null and muzzle != null:
				match att_id:
					&"rifled_extension":
						_flash.position.z = muzzle.position.z - 0.15
					&"mega_compensator":
						_flash.position.z = muzzle.position.z - 0.07
					&"whisper_shroud":
						_flash.position.z = muzzle.position.z - 0.17

	if not has_custom_optic:
		_build_iron_sights(attach_parent)


## Builds crisp low-profile 3D flip-up iron sights on top of the rail/receiver
## whenever no aftermarket optic is mounted.
func _build_iron_sights(attach_parent: Node3D) -> void:
	if _model_asset_id == &"whisper" or _model_asset_id == &"rocket" or (data != null and data.is_melee()):
		return
	var spec := _iron_sight_spec()
	var base_y: float = spec["base_y"]
	var rear_z: float = spec["rear_z"]
	var front_z: float = spec["front_z"]
	var post_h: float = spec["post_h"]

	var root := Node3D.new()
	root.name = "IronSights"
	attach_parent.add_child(root)
	_iron_sights_node = root

	var dark_mat := ArenaKit.mat_styled(DARK, ArenaKit.SurfaceType.METAL, 0.35, 0.55)
	var pip_mat := StandardMaterial3D.new()
	pip_mat.albedo_color = Color(0.95, 0.98, 1.0)
	pip_mat.emission_enabled = true
	pip_mat.emission = Color(0.85, 0.95, 1.0)
	pip_mat.emission_energy_multiplier = 1.1
	var front_tip_mat := StandardMaterial3D.new()
	front_tip_mat.albedo_color = ORANGE_TIP
	front_tip_mat.emission_enabled = true
	front_tip_mat.emission = ORANGE_TIP
	front_tip_mat.emission_energy_multiplier = 1.4

	# Rear sight clamp + wide-open U-notch ears with bright alignment dots
	var rear_base := ArenaKit.deco_box(root, Vector3(0.044, 0.005, 0.018), Vector3(0.0, base_y + 0.0025, rear_z), DARK)
	rear_base.material_override = dark_mat
	for side: float in [-1.0, 1.0]:
		var ear := ArenaKit.deco_box(root, Vector3(0.0065, post_h, 0.013), Vector3(side * 0.019, base_y + 0.005 + post_h * 0.5, rear_z), DARK)
		ear.material_override = dark_mat
		var dot := ArenaKit.deco_sphere(root, 0.0024, Vector3(side * 0.019, base_y + 0.005 + post_h * 0.78, rear_z + 0.007), Color.WHITE)
		dot.material_override = pip_mat

	# Front sight base + protective side wings + blazing orange center blade post
	var front_base := ArenaKit.deco_box(root, Vector3(0.036, 0.005, 0.018), Vector3(0.0, base_y + 0.0025, front_z), DARK)
	front_base.material_override = dark_mat
	for side: float in [-1.0, 1.0]:
		var wing := ArenaKit.deco_box(root, Vector3(0.0045, post_h, 0.013), Vector3(side * 0.015, base_y + 0.005 + post_h * 0.5, front_z), DARK)
		wing.material_override = dark_mat
	var blade_h := post_h * 0.92
	var blade := ArenaKit.deco_box(root, Vector3(0.004, blade_h, 0.008), Vector3(0.0, base_y + 0.005 + blade_h * 0.5, front_z), ORANGE_TIP)
	blade.material_override = front_tip_mat

	if first_person:
		_disable_shadows_recursive(root)


## Returns exact top surface Y, rear/front sight Z, post height, and eye alignment Y
## for the active blaster model so iron sights sit flush on top and never clip the camera.
func _iron_sight_spec() -> Dictionary:
	match _model_asset_id:
		&"popper":
			return {"base_y": 0.064, "rear_z": 0.055, "front_z": -0.16, "post_h": 0.018, "eye_y": 0.085}
		&"six_shot":
			return {"base_y": 0.078, "rear_z": -0.02, "front_z": -0.22, "post_h": 0.020, "eye_y": 0.101}
		&"storm":
			# Upper receiver top is 0.11, Mesh_Hardware_Rail top is 0.13 (Z: -0.23..+0.09)
			return {"base_y": 0.130, "rear_z": 0.065, "front_z": -0.215, "post_h": 0.024, "eye_y": 0.159}
		&"sweeper":
			return {"base_y": 0.065, "rear_z": 0.09, "front_z": -0.18, "post_h": 0.020, "eye_y": 0.088}
		&"whisper":
			return {"base_y": 0.093, "rear_z": 0.05, "front_z": -0.18, "post_h": 0.024, "eye_y": 0.178}
		&"chainstorm":
			return {"base_y": 0.155, "rear_z": 0.06, "front_z": -0.15, "post_h": 0.022, "eye_y": 0.180}
		&"rocket":
			return {"base_y": 0.115, "rear_z": 0.02, "front_z": -0.18, "post_h": 0.024, "eye_y": 0.145}
	# Procedural fallback geometry specs
	var style: int = data.model_style if data != null else WeaponData.ModelStyle.PISTOL
	match style:
		WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
			return {"base_y": 0.084, "rear_z": 0.08, "front_z": -0.18, "post_h": 0.018, "eye_y": 0.105}
		WeaponData.ModelStyle.SPRAYER:
			return {"base_y": 0.090, "rear_z": 0.04, "front_z": -0.24, "post_h": 0.022, "eye_y": 0.114}
		WeaponData.ModelStyle.HAMMER:
			return {"base_y": 0.065, "rear_z": 0.08, "front_z": -0.22, "post_h": 0.020, "eye_y": 0.088}
		WeaponData.ModelStyle.RIFLE:
			return {"base_y": 0.128, "rear_z": 0.06, "front_z": -0.22, "post_h": 0.022, "eye_y": 0.152}
		WeaponData.ModelStyle.ROTARY:
			return {"base_y": 0.185, "rear_z": 0.12, "front_z": -0.07, "post_h": 0.022, "eye_y": 0.210}
	return {"base_y": 0.090, "rear_z": 0.05, "front_z": -0.18, "post_h": 0.020, "eye_y": 0.112}


## Rearmost local +Z extent of the blaster geometry (used to guarantee near-plane clearance in ADS).
func _get_max_rear_z() -> float:
	var rear_z := 0.20
	match _model_asset_id:
		&"popper":
			rear_z = 0.085
		&"six_shot":
			rear_z = 0.105
		&"storm":
			rear_z = 0.245
		&"sweeper":
			rear_z = 0.145
		&"whisper":
			rear_z = 0.325
		&"chainstorm":
			rear_z = 0.215
		&"rocket":
			rear_z = 0.325
		_:
			var style: int = data.model_style if data != null else WeaponData.ModelStyle.PISTOL
			match style:
				WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
					rear_z = 0.11
				WeaponData.ModelStyle.SPRAYER:
					rear_z = 0.34
				WeaponData.ModelStyle.HAMMER:
					rear_z = 0.37
				WeaponData.ModelStyle.RIFLE:
					rear_z = 0.43
				WeaponData.ModelStyle.ROTARY:
					rear_z = 0.23
	var stock_att := _equipped_attachment(&"stock")
	if stock_att != &"none" and stock_att != &"stock_none" and stock_att != &"tactical_grip":
		rear_z = maxf(rear_z, get_slot_transform(&"stock").origin.z + 0.14)
	return rear_z


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
			match _model_asset_id:
				&"popper":
					tf.origin = Vector3(0.0, 0.064, -0.05)
				&"six_shot":
					tf.origin = Vector3(0.0, 0.078, -0.10)
				&"storm":
					# Top surface of Mesh_Hardware_Rail is Y = 0.13 (Z: -0.23..+0.09)
					tf.origin = Vector3(0.0, 0.130, -0.07)
				&"sweeper":
					tf.origin = Vector3(0.0, 0.065, -0.04)
				&"whisper":
					tf.origin = Vector3(0.0, 0.093, -0.06)
				&"chainstorm":
					tf.origin = Vector3(0.0, 0.155, -0.04)
				&"rocket":
					tf.origin = Vector3(0.0, 0.115, -0.10)
				_:
					match style:
						WeaponData.ModelStyle.PISTOL, WeaponData.ModelStyle.DOUBLE:
							tf.origin = Vector3(0.0, 0.084, -0.05)
						WeaponData.ModelStyle.SPRAYER:
							tf.origin = Vector3(0.0, 0.09, -0.1)
						WeaponData.ModelStyle.HAMMER:
							tf.origin = Vector3(0.0, 0.065, -0.05)
						WeaponData.ModelStyle.RIFLE:
							tf.origin = Vector3(0.0, 0.125, -0.05)
						WeaponData.ModelStyle.ROTARY:
							tf.origin = Vector3(0.0, 0.185, 0.03)
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
					tf.origin = Vector3(0.0, -0.02, 0.10)
				WeaponData.ModelStyle.SPRAYER:
					tf.origin = Vector3(0.0, -0.01, 0.22)
				WeaponData.ModelStyle.HAMMER:
					tf.origin = Vector3(0.0, -0.02, 0.24)
				WeaponData.ModelStyle.RIFLE:
					tf.origin = Vector3(0.0, -0.02, 0.27)
				WeaponData.ModelStyle.ROTARY:
					tf.origin = Vector3(0.0, -0.04, 0.19)
				_:
					tf.origin = Vector3(0.0, -0.02, 0.20)
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


## Computes the first-person ADS offset so the optic or iron sights center cleanly
## on the camera while guaranteeing the rear receiver/stock stays safely ahead of camera.near.
func get_ads_offset() -> Vector3:
	if data != null and data.is_melee():
		return Vector3(0.0, -0.26, -0.46)
	var sight_pos := Vector3.ZERO
	var desired_eye_z := -0.26

	if _has_aftermarket_optic():
		var opt_id := _equipped_attachment(&"optic")
		var socket := get_slot_transform(&"optic").origin
		var opt_y := 0.038
		if opt_id == &"holo_sight":
			opt_y = 0.045
		elif opt_id == &"marksman_scope":
			opt_y = 0.052
		sight_pos = socket + Vector3(0.0, opt_y, 0.0)
		desired_eye_z = -0.24
	else:
		var spec := _iron_sight_spec()
		sight_pos = Vector3(0.0, float(spec["eye_y"]), float(spec["rear_z"]))
		desired_eye_z = -0.26

	# Guarantee the rearmost part of the blaster stays well ahead of camera.near (0.04m)
	# even under full-auto recoil and subtle movement sway.
	var max_rear_z := _get_max_rear_z()
	var min_safe_z := -(max_rear_z + 0.14)
	var ads_z := minf(desired_eye_z - sight_pos.z, min_safe_z)

	return Vector3(
		-sight_pos.x,
		-sight_pos.y,
		ads_z
	)



func _build_from_model() -> bool:
	if data == null or not is_instance_valid(ModelLoader):
		return false
	if not ModelLoader.has_blaster_model(data.id):
		return false
	var model_node := ModelLoader.instantiate_blaster(data.id)
	if model_node == null:
		return false
	_model_asset_id = ModelLoader.resolve_blaster_id(data.id)
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


## Chunky stylized EVA-foam baseball slugger bat! Ready-angled for crisp first-person & third-person swings.
func _build_bat() -> void:
	var body := data.body_color if data != null else ORANGE_TIP
	var accent := data.accent_color if data != null else Color(0.15, 0.62, 1.0)
	var bat_pivot := Node3D.new()
	bat_pivot.name = "FoamBat"
	# Ready batting angle: tilted slightly forward and inward so the colourful foam barrel is super readable
	bat_pivot.rotation_degrees = Vector3(-16.0, 0.0, 14.0) if first_person else Vector3(-20.0, 0.0, 0.0)
	model_root.add_child(bat_pivot)

	# Bottom safety pommel knob + taped black rubber handle
	var pommel_mesh := SphereMesh.new()
	pommel_mesh.radius = 0.034
	pommel_mesh.height = 0.044
	_part(pommel_mesh, Vector3(0.0, -0.14, 0.0), DARK, Vector3.ZERO, bat_pivot, 0.0)

	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.022
	handle_mesh.bottom_radius = 0.021
	handle_mesh.height = 0.22
	handle_mesh.radial_segments = 20
	_part(handle_mesh, Vector3(0.0, -0.02, 0.0), DARK, Vector3.ZERO, bat_pivot, 0.0)

	# Subtle grip tape accent rings
	for ry: float in [-0.09, -0.04, 0.01, 0.06]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.020
		ring.outer_radius = 0.025
		ring.rings = 16
		ring.ring_segments = 8
		_part(ring, Vector3(0.0, ry, 0.0), accent, Vector3.ZERO, bat_pivot, 0.0)

	# Collar ring separating grip from EVA foam core
	var collar := CylinderMesh.new()
	collar.top_radius = 0.032
	collar.bottom_radius = 0.024
	collar.height = 0.035
	collar.radial_segments = 20
	_part(collar, Vector3(0.0, 0.105, 0.0), Color(0.95, 0.96, 1.0), Vector3.ZERO, bat_pivot, 0.0)

	# Tapered neck expanding into the oversized foam slugger barrel
	var neck := CylinderMesh.new()
	neck.top_radius = 0.046
	neck.bottom_radius = 0.029
	neck.height = 0.18
	neck.radial_segments = 24
	_part(neck, Vector3(0.0, 0.21, 0.0), body, Vector3.ZERO, bat_pivot, 0.0)

	# Oversized thick EVA-foam slugger barrel (uses skin shader when a custom skin is equipped!)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.058
	barrel.bottom_radius = 0.046
	barrel.height = 0.36
	barrel.radial_segments = 24
	_part(barrel, Vector3(0.0, 0.48, 0.0), body, Vector3.ZERO, bat_pivot, 0.0)

	# Bold twin racing stripes around the sweet spot
	for sy: float in [0.39, 0.56]:
		var stripe := CylinderMesh.new()
		stripe.top_radius = 0.0595 if sy > 0.45 else 0.0525
		stripe.bottom_radius = 0.0565 if sy > 0.45 else 0.0495
		stripe.height = 0.048
		stripe.radial_segments = 24
		_part(stripe, Vector3(0.0, sy, 0.0), accent, Vector3.ZERO, bat_pivot, 0.0)

	# Rounded safety-foam dome cap on top of bat
	var dome := SphereMesh.new()
	dome.radius = 0.058
	dome.height = 0.10
	dome.radial_segments = 24
	dome.rings = 10
	_part(dome, Vector3(0.0, 0.66, 0.0), accent, Vector3.ZERO, bat_pivot, 0.0)

	# Fun cartoon "BONK!" decal along barrel
	var decal := Label3D.new()
	decal.text = "BONK!"
	decal.font = UiKit.font()
	decal.font_size = 44
	decal.pixel_size = 0.0012
	decal.outline_size = 10
	decal.outline_modulate = UiKit.NAVY_DARK
	decal.modulate = Color(1.0, 0.96, 0.82)
	decal.position = Vector3(-0.060, 0.475, 0.0)
	decal.rotation_degrees = Vector3(0.0, -90.0, -90.0)
	bat_pivot.add_child(decal)

	grip_marker = Marker3D.new()
	grip_marker.name = "GripMarker"
	grip_marker.position = Vector3(0.0, -0.02, 0.0)
	model_root.add_child(grip_marker)

	muzzle.position = Vector3(0.0, 0.50, -0.15)


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

	var rot_parent: Node3D = model_root if model_root != null else self
	_spinner = Node3D.new()
	_spinner.position = Vector3(0.0, 0.0, -0.22)
	rot_parent.add_child(_spinner)
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
		rot_parent.add_child(link)
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
	rot_parent.add_child(plate)


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
	_flash = Node3D.new()
	_flash.name = "MuzzleFlash"
	var flash_radius := 0.085 if data.model_style == WeaponData.ModelStyle.ROTARY else 0.058

	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.albedo_color = Color(1.0, 0.97, 0.72, 0.92)
	core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var spike_mat := StandardMaterial3D.new()
	spike_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spike_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spike_mat.albedo_color = Color(1.0, 0.68, 0.18, 0.78)
	spike_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Bright central core puff
	var core := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = flash_radius * 0.75
	sph.height = flash_radius * 1.5
	sph.radial_segments = 10
	sph.rings = 5
	core.mesh = sph
	core.material_override = core_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.add_child(core)

	# 4-point cartoon starburst petals + forward muzzle plume
	var spike_mesh := CylinderMesh.new()
	spike_mesh.top_radius = 0.0
	spike_mesh.bottom_radius = flash_radius * 0.45
	spike_mesh.height = flash_radius * 2.6
	spike_mesh.radial_segments = 6
	for i in 4:
		var petal := MeshInstance3D.new()
		petal.mesh = spike_mesh
		petal.material_override = spike_mat
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := float(i) * PI * 0.5
		petal.rotation = Vector3(0.0, 0.0, ang)
		petal.position = Vector3(-sin(ang), cos(ang), 0.0) * (flash_radius * 0.85)
		_flash.add_child(petal)

	var fwd_spike := MeshInstance3D.new()
	fwd_spike.mesh = spike_mesh
	fwd_spike.material_override = spike_mat
	fwd_spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fwd_spike.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	fwd_spike.position = Vector3(0.0, 0.0, -flash_radius * 1.1)
	_flash.add_child(fwd_spike)

	# Brief dynamic muzzle OmniLight3D illuminating nearby walls/hands
	_flash_light = OmniLight3D.new()
	_flash_light.light_color = Color(1.0, 0.82, 0.42)
	_flash_light.light_energy = 0.0
	_flash_light.omni_range = 4.5
	_flash_light.shadow_enabled = false
	_flash_light.visible = false
	_flash.add_child(_flash_light)

	_flash.position = muzzle.position + Vector3(0.0, 0.0, -0.04)
	_flash.visible = false
	var parent_node: Node3D = model_root if model_root != null else self
	parent_node.add_child(_flash)


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
	elif model_root != null:
		model_root.add_child(instance)
	else:
		add_child(instance)
	return instance
