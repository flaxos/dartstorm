class_name CharacterModel
extends Node3D
## A chunky cartoon kid built from primitives: used for bots, the menu's
## "your player" preview and the podium. Forward is -Z, origin at the feet.
## Hats come from Cosmetics.HATS; the propeller hat really spins.

const SKIN := Color(1.0, 0.82, 0.66)
const NAVY := Color(0.1, 0.14, 0.3)
const GOLD := Color(1.0, 0.8, 0.15)
const HAT_Y := 1.86
const ZOMBIE_GREEN := Color(0.38, 0.78, 0.28)
const ZOMBIE_SKIN := Color(0.48, 0.82, 0.38)

static var _cloth_normal: Texture2D = preload("res://assets/textures/pbr/cloth_fabric_normal.png")
static var _sneaker_normal: Texture2D = preload("res://assets/textures/pbr/sneaker_rubber_normal.png")

static var _cached_cloth_mats: Dictionary = {}
static var _cached_sneaker_mat: StandardMaterial3D = null
static var _cached_skin_mats: Dictionary = {}

static func clear_character_materials() -> void:
	_cached_cloth_mats.clear()
	_cached_sneaker_mat = null
	_cached_skin_mats.clear()

static func _cloth_mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html(false)
	if _cached_cloth_mats.has(key):
		return _cached_cloth_mats[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.roughness = 0.85
	mat.metallic_specular = 0.2
	mat.normal_enabled = true
	mat.normal_texture = _cloth_normal
	mat.normal_scale = 0.35
	mat.rim_enabled = true
	mat.rim = 0.18
	mat.rim_tint = 0.3
	_cached_cloth_mats[key] = mat
	return mat

static func _sneaker_mat() -> StandardMaterial3D:
	if _cached_sneaker_mat == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.96, 0.96, 0.98, 1.0)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		mat.roughness = 0.70
		mat.metallic_specular = 0.2
		mat.normal_enabled = true
		mat.normal_texture = _sneaker_normal
		mat.normal_scale = 0.45
		mat.rim_enabled = true
		mat.rim = 0.15
		mat.rim_tint = 0.3
		_cached_sneaker_mat = mat
	return _cached_sneaker_mat

static func _skin_mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html(false)
	if _cached_skin_mats.has(key):
		return _cached_skin_mats[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.roughness = 0.72
	mat.metallic_specular = 0.2
	mat.rim_enabled = true
	mat.rim = 0.15
	mat.rim_tint = 0.3
	_cached_skin_mats[key] = mat
	return mat

var _tint: Color = Color.WHITE
var _upper: Node3D
var _torso: MeshInstance3D
var _head: MeshInstance3D
var _arms: Array[MeshInstance3D] = []
var _legs: Array[MeshInstance3D] = []
var _weapon_mount: Node3D
var _weapon: BlasterModel
var _backpack: Node3D
var _name_label: Label3D
var _meter_fill: MeshInstance3D
var _meter_back: MeshInstance3D
var _walk_phase: float = 0.0
var _flinch: float = 0.0
var _hat_root: Node3D
var _propeller: Node3D
var _hat_id: StringName = &"cap"
var _is_zombie: bool = false
var _shield_bubble: MeshInstance3D
var _hero_model_node: Node3D = null
var _hero_skeleton: Skeleton3D = null


var _raw_display_name: String = ""


func setup(display_name: String, tint: Color, hat: StringName = &"cap") -> void:
	_raw_display_name = display_name
	_tint = tint
	_hat_id = hat
	if _hero_model_node != null or _upper != null:
		set_shirt(tint)
		set_hat(hat)
		if _is_zombie:
			set_zombie(true)
		if _name_label != null:
			_name_label.text = display_name
			_name_label.modulate = Color(0.5, 0.95, 0.35) if _is_zombie else tint.lightened(0.35)
		return
	_build()
	if _name_label != null:
		_name_label.text = display_name
		_name_label.modulate = tint.lightened(0.35)


## Toggles tagged-out visual status (weapon hidden, overhead warning label).
func set_tagged_out(is_out: bool) -> void:
	if _name_label != null:
		if is_out:
			_name_label.text = "[TAGGED OUT - RUN TO BASE!]"
			_name_label.modulate = Color(1.0, 0.25, 0.2)
		else:
			_name_label.text = _raw_display_name
			_name_label.modulate = _tint.lightened(0.35)
	if _weapon_mount != null:
		_weapon_mount.visible = not is_out


## Swaps the hat (used by the customise screen's live preview).
func set_hat(hat: StringName) -> void:
	_hat_id = hat
	_build_hat()


func hat_id() -> StringName:
	return _hat_id


## Swaps shirt / clothing color (used by customise screen).
func set_shirt(color: Color) -> void:
	_tint = color
	if _name_label != null:
		_name_label.modulate = _tint.lightened(0.35)
	if _hero_model_node != null and is_instance_valid(ModelLoader):
		var overrides := {
			"clothing": _cloth_mat(_tint),
			"shirt": _cloth_mat(_tint),
		}
		ModelLoader.apply_materials_recursive(_hero_model_node, overrides)
	elif _torso != null:
		var shirt := _cloth_mat(_tint)
		_torso.material_override = shirt
		for arm in _arms:
			arm.material_override = shirt
	else:
		_build()
	_build_hat()


## Hides the floating name and tag meter (menu preview, podium).
func show_overhead(shown: bool) -> void:
	_name_label.visible = shown
	_meter_back.visible = shown
	if not shown:
		_meter_fill.visible = false


func set_zombie(enabled: bool) -> void:
	_is_zombie = enabled
	if _hero_model_node != null and is_instance_valid(ModelLoader):
		var zombie_mat := _cloth_mat(ZOMBIE_GREEN)
		var zombie_skin_mat := _skin_mat(ZOMBIE_SKIN)
		var zombie_map := {
			"clothing": zombie_mat if enabled else _cloth_mat(_tint),
			"pants": _cloth_mat(ZOMBIE_GREEN.darkened(0.25)) if enabled else _cloth_mat(NAVY),
			"skin": zombie_skin_mat if enabled else _skin_mat(SKIN)
		}
		ModelLoader.apply_materials_recursive(_hero_model_node, zombie_map)
		if enabled:
			set_weapon(null)
		if _name_label != null:
			_name_label.modulate = Color(0.5, 0.95, 0.35) if enabled else _tint.lightened(0.35)
		return

	if enabled:
		var zombie_mat := _cloth_mat(ZOMBIE_GREEN)
		var zombie_skin_mat := _skin_mat(ZOMBIE_SKIN)
		if _torso != null:
			_torso.material_override = zombie_mat
		if _head != null:
			_head.material_override = zombie_skin_mat
		for i in _arms.size():
			var arm := _arms[i]
			var side: float = -1.0 if i == 0 else 1.0
			arm.material_override = zombie_mat
			arm.rotation_degrees = Vector3(90.0, side * -5.0, 0.0)
		for leg in _legs:
			leg.material_override = _cloth_mat(ZOMBIE_GREEN.darkened(0.25))
		set_weapon(null)
		if _name_label != null:
			_name_label.modulate = Color(0.5, 0.95, 0.35)
	else:
		var shirt := _cloth_mat(_tint)
		if _torso != null:
			_torso.material_override = shirt
		if _head != null:
			_head.material_override = _skin_mat(SKIN)
		for i in _arms.size():
			var arm := _arms[i]
			var side: float = -1.0 if i == 0 else 1.0
			arm.material_override = shirt
			arm.rotation_degrees = Vector3(80.0, side * -18.0, 0.0)
		for leg in _legs:
			leg.material_override = _cloth_mat(NAVY)
		if _name_label != null:
			_name_label.modulate = _tint.lightened(0.35)


func is_zombie() -> bool:
	return _is_zombie


func _process(delta: float) -> void:
	if _propeller != null and is_instance_valid(_propeller):
		_propeller.rotate_y(delta * 14.0)


func set_weapon(data: WeaponData, skin_id: StringName = &"", attachments: Dictionary = {}) -> void:
	if _weapon != null:
		_weapon.queue_free()
		_weapon = null
	if data == null:
		return
	_weapon = BlasterModel.create(data, false, skin_id, attachments)
	_weapon.scale = Vector3.ONE * 1.35
	_weapon_mount.add_child(_weapon)
	if _weapon.grip_marker != null:
		_weapon.position = -_weapon.grip_marker.position * 1.35
	_backpack.visible = data.model_style == WeaponData.ModelStyle.ROTARY


func get_weapon() -> BlasterModel:
	return _weapon


## Tilts the upper body to match where the bot is aiming.
func set_aim_pitch(radians: float) -> void:
	if _hero_skeleton != null:
		var bone_idx := _hero_skeleton.find_bone("Chest")
		if bone_idx >= 0:
			var pitch := clampf(radians, -0.9, 0.9)
			_hero_skeleton.set_bone_pose_rotation(bone_idx, Quaternion(Vector3.RIGHT, pitch))
			return
	if _upper != null:
		_upper.rotation.x = clampf(radians, -0.9, 0.9)


## 0 = fresh, 1 = about to be tagged out.
func set_meter(ratio: float) -> void:
	_meter_fill.visible = ratio > 0.01
	_meter_fill.scale.x = clampf(ratio, 0.02, 1.0)


func flinch() -> void:
	_flinch = 1.0


func animate(horizontal_speed: float, delta: float) -> void:
	if _hero_model_node != null:
		var anim_player: AnimationPlayer = _hero_model_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player != null:
			if _flinch > 0.05 and anim_player.has_animation("flinch"):
				if anim_player.current_animation != "flinch":
					anim_player.play("flinch")
			elif horizontal_speed > 0.5:
				if anim_player.has_animation("run") and anim_player.current_animation != "run":
					anim_player.play("run")
			else:
				if anim_player.has_animation("idle") and anim_player.current_animation != "idle":
					anim_player.play("idle")
		_flinch = move_toward(_flinch, 0.0, delta * 5.0)
		return

	_walk_phase += delta * horizontal_speed * 1.6
	var swing := sin(_walk_phase) * clampf(horizontal_speed / 6.0, 0.0, 1.0) * 0.6
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing
	_flinch = move_toward(_flinch, 0.0, delta * 5.0)
	_upper.position.y = absf(sin(_walk_phase)) * 0.04 * clampf(horizontal_speed / 6.0, 0.0, 1.0)
	_upper.rotation.z = sin(_flinch * PI * 2.0) * 0.25 * _flinch
	if _is_zombie:
		for i in _arms.size():
			var arm := _arms[i]
			var side: float = -1.0 if i == 0 else 1.0
			var lurch := sin(_walk_phase * 0.8 + float(i) * 1.5) * 0.12
			arm.rotation = Vector3(deg_to_rad(90.0) + lurch, deg_to_rad(side * -5.0), sin(_walk_phase * 0.5) * 0.05)


func _clear_model() -> void:
	if _hero_model_node != null:
		if is_instance_valid(_hero_model_node):
			if _hero_model_node.get_parent() == self:
				remove_child(_hero_model_node)
			_hero_model_node.queue_free()
		_hero_model_node = null
		_hero_skeleton = null
	if _upper != null:
		if is_instance_valid(_upper) and _upper != _hero_model_node:
			if _upper.get_parent() == self:
				remove_child(_upper)
			_upper.queue_free()
		_upper = null
	for leg in _legs:
		if is_instance_valid(leg) and leg.get_parent() == self:
			remove_child(leg)
			leg.queue_free()
	_legs.clear()
	_arms.clear()
	_torso = null
	_head = null
	_weapon = null
	_weapon_mount = null
	_backpack = null
	_propeller = null
	_hat_root = null
	if _name_label != null:
		if is_instance_valid(_name_label) and _name_label.get_parent() == self:
			remove_child(_name_label)
		_name_label.queue_free()
		_name_label = null
	if _meter_back != null:
		if is_instance_valid(_meter_back) and _meter_back.get_parent() == self:
			remove_child(_meter_back)
		_meter_back.queue_free()
		_meter_back = null
	if _meter_fill != null:
		if is_instance_valid(_meter_fill) and _meter_fill.get_parent() == self:
			remove_child(_meter_fill)
		_meter_fill.queue_free()
		_meter_fill = null
	if _shield_bubble != null:
		if is_instance_valid(_shield_bubble) and _shield_bubble.get_parent() == self:
			remove_child(_shield_bubble)
		_shield_bubble.queue_free()
		_shield_bubble = null


func _build() -> void:
	_clear_model()
	if _build_from_hero_model():
		return

	var shirt := _cloth_mat(_tint)
	var pants := _cloth_mat(NAVY)
	_legs.clear()
	for side: float in [-1.0, 1.0]:
		var leg := _capsule(self, 0.12, 0.74, Vector3(side * 0.15, 0.37, 0.0), pants)
		_legs.append(leg)

		# Stylized High-Traction Sneaker attached to foot
		_box_child(leg, Vector3(0.15, 0.055, 0.28), Vector3(0.0, -0.34, -0.04), _sneaker_mat())
		_box_child(leg, Vector3(0.14, 0.08, 0.22), Vector3(0.0, -0.28, -0.03), _cloth_mat(_tint.darkened(0.25)))
		_box_child(leg, Vector3(0.145, 0.065, 0.09), Vector3(0.0, -0.32, -0.15), _sneaker_mat())

	_upper = Node3D.new()
	add_child(_upper)
	_torso = _capsule(_upper, 0.31, 0.86, Vector3(0.0, 1.05, 0.0), shirt)

	# Hoodie / Combat Vest Cowl Collar
	_tube_child(_upper, 0.26, 0.07, Vector3(0.0, 1.48, 0.0), _cloth_mat(_tint.darkened(0.18)))
	# Tactical chest pocket
	_box_child(_upper, Vector3(0.11, 0.13, 0.04), Vector3(0.12, 1.15, -0.29), _cloth_mat(_tint.darkened(0.28)))

	# Head
	_head = _sphere_child(_upper, 0.26, Vector3(0.0, 1.66, 0.0), _skin_mat(SKIN), 1.0)

	# Stylized Eyes & Facial Features
	_arms.clear()
	for side: float in [-1.0, 1.0]:
		# Eyebrows
		_box_child(_upper, Vector3(0.075, 0.022, 0.025), Vector3(side * 0.095, 1.795, -0.235), ArenaKit.mat(Color(0.25, 0.16, 0.08), 0.8), Vector3(0.0, 0.0, side * -12.0))
		# White Sclera
		_sphere_child(_upper, 0.065, Vector3(side * 0.095, 1.7, -0.215), ArenaKit.mat(Color(0.98, 0.98, 1.0), 0.15))
		# Iris & Pupil
		_sphere_child(_upper, 0.038, Vector3(side * 0.095, 1.7, -0.265), ArenaKit.mat(Color(0.08, 0.25, 0.5), 0.2))
		_sphere_child(_upper, 0.024, Vector3(side * 0.095, 1.7, -0.275), ArenaKit.mat(Color(0.02, 0.02, 0.04), 0.1))
		# Pixar Specular Catchlight
		_sphere_child(_upper, 0.012, Vector3(side * 0.095 + 0.016, 1.722, -0.285), ArenaKit.mat(Color.WHITE, 0.0, 0.0, 1.5))
		# Rosy Cheeks
		_sphere_child(_upper, 0.035, Vector3(side * 0.155, 1.605, -0.205), ArenaKit.mat(Color(1.0, 0.65, 0.65, 0.5), 0.8))

		# Arm
		var arm := _capsule(_upper, 0.085, 0.52, Vector3(side * 0.3, 1.18, -0.24), shirt)
		arm.rotation_degrees = Vector3(80.0, side * -18.0, 0.0)
		_arms.append(arm)

		# Sleeve cuff
		_tube_child(arm, 0.092, 0.04, Vector3(0.0, -0.22, 0.0), _cloth_mat(_tint.darkened(0.2)))
		# Molded hand
		_sphere_child(arm, 0.072, Vector3(0.0, -0.28, 0.0), _skin_mat(SKIN), 0.85)

	# Cute button nose
	_sphere_child(_upper, 0.032, Vector3(0.0, 1.63, -0.26), _skin_mat(SKIN.darkened(0.12)))

	_hat_root = Node3D.new()
	_upper.add_child(_hat_root)
	_build_hat()

	_weapon_mount = Node3D.new()
	_weapon_mount.position = Vector3(0.2, 1.2, -0.52)
	_upper.add_child(_weapon_mount)

	# Chainstorm ammo backpack (only shown while carrying it).
	_backpack = Node3D.new()
	_upper.add_child(_backpack)
	ArenaKit.deco_box(_backpack, Vector3(0.5, 0.6, 0.28), Vector3(0.0, 1.12, 0.38), Color(1.0, 0.5, 0.1))
	ArenaKit.deco_box(_backpack, Vector3(0.52, 0.1, 0.3), Vector3(0.0, 1.3, 0.38), Color(1.0, 0.85, 0.2))
	_backpack.visible = false

	_build_overhead_and_shield()


func _build_from_hero_model() -> bool:
	if not is_instance_valid(ModelLoader) or not ModelLoader.has_hero_model():
		return false
	_hero_model_node = ModelLoader.instantiate_hero()
	if _hero_model_node == null:
		return false
	add_child(_hero_model_node)
	_upper = _hero_model_node
	_hero_skeleton = ModelLoader.find_skeleton(_hero_model_node)
	if _hero_skeleton != null:
		_hero_skeleton.reset_bone_poses()
		for c in _hero_skeleton.get_children():
			if c is BoneAttachment3D:
				var b_idx := _hero_skeleton.find_bone(c.bone_name)
				if b_idx >= 0:
					c.bone_idx = b_idx
					c.transform = _hero_skeleton.get_bone_global_rest(b_idx)
					_hero_skeleton.force_update_bone_child_transform(b_idx)

	var mat_map := {
		"clothing": _cloth_mat(_tint),
		"shirt": _cloth_mat(_tint),
		"pants": _cloth_mat(NAVY),
		"skin": _skin_mat(SKIN),
		"shoes": _sneaker_mat(),
		"sneaker": _sneaker_mat()
	}
	ModelLoader.apply_materials_recursive(_hero_model_node, mat_map)

	_legs.clear()
	var leg_l := _hero_model_node.find_child("Mesh_UpperLeg_L*", true, false) as MeshInstance3D
	var leg_r := _hero_model_node.find_child("Mesh_UpperLeg_R*", true, false) as MeshInstance3D
	if leg_l != null and leg_r != null:
		_legs = [leg_l, leg_r]

	_arms.clear()
	var arm_l := _hero_model_node.find_child("Mesh_UpperArm_L*", true, false) as MeshInstance3D
	var arm_r := _hero_model_node.find_child("Mesh_UpperArm_R*", true, false) as MeshInstance3D
	if arm_l != null and arm_r != null:
		_arms = [arm_l, arm_r]

	_torso = _hero_model_node.find_child("Mesh_Torso*", true, false) as MeshInstance3D
	_head = _hero_model_node.find_child("Mesh_Head*", true, false) as MeshInstance3D

	_weapon_mount = ModelLoader.get_or_create_socket(_hero_model_node, &"Socket_Hand_R", &"Hand_R")
	_hat_root = ModelLoader.get_or_create_socket(_hero_model_node, &"Socket_Head", &"Head")
	_backpack = ModelLoader.get_or_create_socket(_hero_model_node, &"Socket_Back", &"Chest")

	var anim_player: AnimationPlayer = _hero_model_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player != null and anim_player.has_animation("idle"):
		anim_player.play("idle")

	_build_hat()
	_build_overhead_and_shield()
	return true


func _build_overhead_and_shield() -> void:
	_name_label = Label3D.new()
	_name_label.font = UiKit.font()
	_name_label.font_size = 56
	_name_label.pixel_size = 0.006
	_name_label.outline_size = 12
	_name_label.outline_modulate = UiKit.NAVY_DARK
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.position.y = 2.42
	add_child(_name_label)

	# Tag meter above the head: shows how close this kid is to being tagged out.
	_meter_back = _billboard_quad(Vector2(0.9, 0.11), Color(0.03, 0.07, 0.19, 0.8))
	_meter_back.position.y = 2.16
	add_child(_meter_back)
	_meter_fill = _billboard_quad(Vector2(0.86, 0.075), Color(1.0, 0.48, 0.1))
	_meter_fill.position.y = 2.16
	_meter_fill.sorting_offset = 1.0
	_meter_fill.visible = false
	add_child(_meter_fill)

	# Hexagonal Foam Shield bubble
	_shield_bubble = MeshInstance3D.new()
	var bubble_mesh := SphereMesh.new()
	bubble_mesh.radius = 0.95
	bubble_mesh.height = 2.1
	bubble_mesh.radial_segments = 24
	bubble_mesh.rings = 16
	_shield_bubble.mesh = bubble_mesh
	var shield_mat := ShaderMaterial.new()
	shield_mat.shader = load("res://assets/materials/foam_shield.gdshader") as Shader
	_shield_bubble.material_override = shield_mat
	_shield_bubble.position.y = 1.05
	_shield_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield_bubble.visible = false
	add_child(_shield_bubble)


func set_shield_visible(shown: bool) -> void:
	if _shield_bubble != null:
		_shield_bubble.visible = shown


func flash_shield() -> void:
	if _shield_bubble != null and _shield_bubble.material_override is ShaderMaterial:
		var mat := _shield_bubble.material_override as ShaderMaterial
		mat.set_shader_parameter(&"hit_flash", 1.0)
		var tween := create_tween()
		if tween != null:
			tween.tween_method(func(val: float) -> void: mat.set_shader_parameter(&"hit_flash", val), 1.0, 0.0, 0.25)


func _build_hat() -> void:
	if _hat_root == null or not is_instance_valid(_hat_root):
		return
	for child in _hat_root.get_children():
		_hat_root.remove_child(child)
		child.queue_free()
	_propeller = null
	var base_y: float = (HAT_Y - 1.66) if _hero_skeleton != null else HAT_Y
	if is_instance_valid(ModelLoader) and ModelLoader.has_hat_model(_hat_id):
		var hat_node := ModelLoader.instantiate_hat(_hat_id)
		if hat_node != null:
			hat_node.position = Vector3(0.0, base_y, 0.0)
			_hat_root.add_child(hat_node)
			ModelLoader.apply_materials_recursive(hat_node, {
				"main": _cloth_mat(_tint.darkened(0.2)),
				"accent": _cloth_mat(_tint.lightened(0.3))
			})
			return

	var main := _tint.darkened(0.2)
	match _hat_id:
		&"cap":
			ArenaKit.deco_cylinder(_hat_root, 0.27, 0.13, Vector3(0.0, base_y, 0.0), main)
			ArenaKit.deco_box(_hat_root, Vector3(0.34, 0.035, 0.24), Vector3(0.0, base_y - 0.05, -0.3), main)
		&"beanie":
			ArenaKit.deco_sphere(_hat_root, 0.285, Vector3(0.0, base_y - 0.04, 0.0), main, 0.75)
			ArenaKit.deco_cylinder(_hat_root, 0.29, 0.08, Vector3(0.0, base_y - 0.08, 0.0), _tint.lightened(0.3))
			ArenaKit.deco_sphere(_hat_root, 0.08, Vector3(0.0, base_y + 0.18, 0.0), Color.WHITE)
		&"propeller":
			ArenaKit.deco_sphere(_hat_root, 0.28, Vector3(0.0, base_y - 0.04, 0.0), main, 0.65)
			ArenaKit.deco_cylinder(_hat_root, 0.02, 0.14, Vector3(0.0, base_y + 0.17, 0.0), Color(0.3, 0.3, 0.35))
			_propeller = Node3D.new()
			_propeller.position = Vector3(0.0, base_y + 0.24, 0.0)
			_hat_root.add_child(_propeller)
			ArenaKit.deco_box(_propeller, Vector3(0.52, 0.02, 0.08), Vector3.ZERO, Color(1.0, 0.3, 0.3))
			ArenaKit.deco_box(_propeller, Vector3(0.08, 0.021, 0.52), Vector3.ZERO, Color(1.0, 0.85, 0.2))
		&"party":
			ArenaKit.deco_cylinder(_hat_root, 0.17, 0.42, Vector3(0.0, base_y + 0.17, 0.0), _tint.lightened(0.25), Vector3.ZERO, 0.0)
			ArenaKit.deco_sphere(_hat_root, 0.07, Vector3(0.0, base_y + 0.4, 0.0), Color(1.0, 0.85, 0.2))
		&"cowboy":
			var leather := Color(0.55, 0.36, 0.2)
			ArenaKit.deco_cylinder(_hat_root, 0.46, 0.04, Vector3(0.0, base_y - 0.02, 0.0), leather)
			ArenaKit.deco_cylinder(_hat_root, 0.22, 0.24, Vector3(0.0, base_y + 0.1, 0.0), leather, Vector3.ZERO, 0.19)
			ArenaKit.deco_cylinder(_hat_root, 0.225, 0.05, Vector3(0.0, base_y + 0.02, 0.0), main)
		&"crown":
			ArenaKit.deco_cylinder(_hat_root, 0.23, 0.12, Vector3(0.0, base_y + 0.02, 0.0), GOLD)
			for i in 5:
				var angle := TAU * float(i) / 5.0
				var spot := Vector3(cos(angle) * 0.19, base_y + 0.13, sin(angle) * 0.19)
				ArenaKit.deco_cylinder(_hat_root, 0.06, 0.13, spot, GOLD, Vector3.ZERO, 0.0)
			ArenaKit.deco_sphere(_hat_root, 0.04, Vector3(0.0, base_y + 0.03, -0.235), Color(0.9, 0.15, 0.3))
		&"goggles":
			# Ski goggles pushed up on the forehead.
			ArenaKit.deco_cylinder(_hat_root, 0.265, 0.06, Vector3(0.0, base_y - 0.08, 0.0), NAVY)
			for side: float in [-1.0, 1.0]:
				ArenaKit.deco_cylinder(_hat_root, 0.088, 0.06, Vector3(side * 0.1, base_y - 0.06, -0.235), main, Vector3(90.0, 0.0, 0.0))
				ArenaKit.deco_cylinder(_hat_root, 0.066, 0.07, Vector3(side * 0.1, base_y - 0.06, -0.24), Color(0.45, 0.88, 1.0), Vector3(90.0, 0.0, 0.0))
		&"bunny":
			for side: float in [-1.0, 1.0]:
				var ear := ArenaKit.deco_sphere(_hat_root, 0.07, Vector3(side * 0.11, base_y + 0.2, 0.0), Color(0.97, 0.97, 1.0), 3.2)
				ear.rotation_degrees.z = -side * 14.0
				var inner := ArenaKit.deco_sphere(_hat_root, 0.04, Vector3(side * 0.112, base_y + 0.2, -0.04), Color(1.0, 0.62, 0.75), 4.5)
				inner.rotation_degrees.z = -side * 14.0
		&"horns":
			for side: float in [-1.0, 1.0]:
				ArenaKit.deco_cylinder(_hat_root, 0.065, 0.22, Vector3(side * 0.14, base_y + 0.06, -0.05), Color(0.92, 0.16, 0.22),
						Vector3(0.0, 0.0, -side * 25.0), 0.0)
		&"spiky":
			# Spiky cartoon hair, straight out of a comic.
			var hair := Color(1.0, 0.74, 0.18)
			ArenaKit.deco_sphere(_hat_root, 0.235, Vector3(0.0, base_y - 0.16, 0.02), hair, 0.85)
			for i in 7:
				var direction := Vector3.UP
				if i > 0:
					var around := TAU * float(i - 1) / 6.0
					direction = Vector3(sin(0.7) * cos(around), cos(0.7), sin(0.7) * sin(around))
				var spike := ArenaKit.deco_cylinder(_hat_root, 0.075, 0.24, Vector3(0.0, base_y - 0.18, 0.02) + direction * 0.27, hair,
						Vector3.ZERO, 0.0)
				spike.quaternion = Quaternion(Vector3.UP, direction)
		_:
			# No hat: a cheerful tuft of hair.
			ArenaKit.deco_sphere(_hat_root, 0.2, Vector3(0.0, base_y - 0.06, 0.02), Color(0.4, 0.25, 0.12), 0.6)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _box_child(parent: Node3D, size: Vector3, pos: Vector3, material: Material,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation_degrees = rot_deg
	parent.add_child(instance)
	return instance


func _sphere_child(parent: Node3D, radius: float, pos: Vector3, material: Material,
		squash: float = 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 24
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _tube_child(parent: Node3D, radius: float, length: float, pos: Vector3, material: Material,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 24
	mesh.rings = 2
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation_degrees = rot_deg
	parent.add_child(instance)
	return instance


func _billboard_quad(quad_size: Vector2, tint: Color) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = quad_size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.albedo_color = tint
	if tint.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
