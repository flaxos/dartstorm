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


func setup(display_name: String, tint: Color, hat: StringName = &"cap") -> void:
	_tint = tint
	_hat_id = hat
	_build()
	_name_label.text = display_name
	_name_label.modulate = tint.lightened(0.35)


## Swaps the hat (used by the customise screen's live preview).
func set_hat(hat: StringName) -> void:
	_hat_id = hat
	_build_hat()


func hat_id() -> StringName:
	return _hat_id


## Hides the floating name and tag meter (menu preview, podium).
func show_overhead(shown: bool) -> void:
	_name_label.visible = shown
	_meter_back.visible = shown
	if not shown:
		_meter_fill.visible = false


func set_zombie(enabled: bool) -> void:
	_is_zombie = enabled
	if enabled:
		var zombie_mat := ArenaKit.mat(ZOMBIE_GREEN, 0.7)
		var zombie_skin_mat := ArenaKit.mat(ZOMBIE_SKIN, 0.7)
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
			leg.material_override = ArenaKit.mat(ZOMBIE_GREEN.darkened(0.25), 0.7)
		set_weapon(null)
		if _name_label != null:
			_name_label.modulate = Color(0.5, 0.95, 0.35)
	else:
		var shirt := ArenaKit.mat(_tint, 0.7)
		if _torso != null:
			_torso.material_override = shirt
		if _head != null:
			_head.material_override = ArenaKit.mat(SKIN, 0.7)
		for i in _arms.size():
			var arm := _arms[i]
			var side: float = -1.0 if i == 0 else 1.0
			arm.material_override = shirt
			arm.rotation_degrees = Vector3(80.0, side * -18.0, 0.0)
		for leg in _legs:
			leg.material_override = ArenaKit.mat(NAVY)
		if _name_label != null:
			_name_label.modulate = _tint.lightened(0.35)


func is_zombie() -> bool:
	return _is_zombie


func _process(delta: float) -> void:
	if _propeller != null and is_instance_valid(_propeller):
		_propeller.rotate_y(delta * 14.0)


func set_weapon(data: WeaponData, skin_id: StringName = &"") -> void:
	if _weapon != null:
		_weapon.queue_free()
		_weapon = null
	if data == null:
		return
	_weapon = BlasterModel.create(data, false, skin_id)
	_weapon.scale = Vector3.ONE * 1.35
	_weapon_mount.add_child(_weapon)
	_backpack.visible = data.model_style == WeaponData.ModelStyle.ROTARY


func get_weapon() -> BlasterModel:
	return _weapon


## Tilts the upper body to match where the bot is aiming.
func set_aim_pitch(radians: float) -> void:
	_upper.rotation.x = clampf(radians, -0.9, 0.9)


## 0 = fresh, 1 = about to be tagged out.
func set_meter(ratio: float) -> void:
	_meter_fill.visible = ratio > 0.01
	_meter_fill.scale.x = clampf(ratio, 0.02, 1.0)


func flinch() -> void:
	_flinch = 1.0


func animate(horizontal_speed: float, delta: float) -> void:
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


func _build() -> void:
	var shirt := ArenaKit.mat(_tint, 0.7)
	for side: float in [-1.0, 1.0]:
		var leg := _capsule(self, 0.12, 0.74, Vector3(side * 0.15, 0.37, 0.0), ArenaKit.mat(NAVY))
		_legs.append(leg)

	_upper = Node3D.new()
	add_child(_upper)
	_torso = _capsule(_upper, 0.31, 0.86, Vector3(0.0, 1.05, 0.0), shirt)
	_head = ArenaKit.deco_sphere(_upper, 0.26, Vector3(0.0, 1.66, 0.0), SKIN)
	_arms.clear()
	for side: float in [-1.0, 1.0]:
		ArenaKit.deco_sphere(_upper, 0.065, Vector3(side * 0.095, 1.7, -0.215), Color.WHITE)
		ArenaKit.deco_sphere(_upper, 0.034, Vector3(side * 0.095, 1.7, -0.265), Color(0.05, 0.05, 0.1))
		var arm := _capsule(_upper, 0.085, 0.52, Vector3(side * 0.3, 1.18, -0.24), shirt)
		arm.rotation_degrees = Vector3(80.0, side * -18.0, 0.0)
		_arms.append(arm)
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
	for child in _hat_root.get_children():
		child.queue_free()
	_propeller = null
	var main := _tint.darkened(0.2)
	match _hat_id:
		&"cap":
			ArenaKit.deco_cylinder(_hat_root, 0.27, 0.13, Vector3(0.0, HAT_Y, 0.0), main)
			ArenaKit.deco_box(_hat_root, Vector3(0.34, 0.035, 0.24), Vector3(0.0, HAT_Y - 0.05, -0.3), main)
		&"beanie":
			ArenaKit.deco_sphere(_hat_root, 0.285, Vector3(0.0, HAT_Y - 0.04, 0.0), main, 0.75)
			ArenaKit.deco_cylinder(_hat_root, 0.29, 0.08, Vector3(0.0, HAT_Y - 0.08, 0.0), _tint.lightened(0.3))
			ArenaKit.deco_sphere(_hat_root, 0.08, Vector3(0.0, HAT_Y + 0.18, 0.0), Color.WHITE)
		&"propeller":
			ArenaKit.deco_sphere(_hat_root, 0.28, Vector3(0.0, HAT_Y - 0.04, 0.0), main, 0.65)
			ArenaKit.deco_cylinder(_hat_root, 0.02, 0.14, Vector3(0.0, HAT_Y + 0.17, 0.0), Color(0.3, 0.3, 0.35))
			_propeller = Node3D.new()
			_propeller.position = Vector3(0.0, HAT_Y + 0.24, 0.0)
			_hat_root.add_child(_propeller)
			ArenaKit.deco_box(_propeller, Vector3(0.52, 0.02, 0.08), Vector3.ZERO, Color(1.0, 0.3, 0.3))
			ArenaKit.deco_box(_propeller, Vector3(0.08, 0.021, 0.52), Vector3.ZERO, Color(1.0, 0.85, 0.2))
		&"party":
			ArenaKit.deco_cylinder(_hat_root, 0.17, 0.42, Vector3(0.0, HAT_Y + 0.17, 0.0), _tint.lightened(0.25), Vector3.ZERO, 0.0)
			ArenaKit.deco_sphere(_hat_root, 0.07, Vector3(0.0, HAT_Y + 0.4, 0.0), Color(1.0, 0.85, 0.2))
		&"cowboy":
			var leather := Color(0.55, 0.36, 0.2)
			ArenaKit.deco_cylinder(_hat_root, 0.46, 0.04, Vector3(0.0, HAT_Y - 0.02, 0.0), leather)
			ArenaKit.deco_cylinder(_hat_root, 0.22, 0.24, Vector3(0.0, HAT_Y + 0.1, 0.0), leather, Vector3.ZERO, 0.19)
			ArenaKit.deco_cylinder(_hat_root, 0.225, 0.05, Vector3(0.0, HAT_Y + 0.02, 0.0), main)
		&"crown":
			ArenaKit.deco_cylinder(_hat_root, 0.23, 0.12, Vector3(0.0, HAT_Y + 0.02, 0.0), GOLD)
			for i in 5:
				var angle := TAU * float(i) / 5.0
				var spot := Vector3(cos(angle) * 0.19, HAT_Y + 0.13, sin(angle) * 0.19)
				ArenaKit.deco_cylinder(_hat_root, 0.06, 0.13, spot, GOLD, Vector3.ZERO, 0.0)
			ArenaKit.deco_sphere(_hat_root, 0.04, Vector3(0.0, HAT_Y + 0.03, -0.235), Color(0.9, 0.15, 0.3))
		&"goggles":
			# Ski goggles pushed up on the forehead.
			ArenaKit.deco_cylinder(_hat_root, 0.265, 0.06, Vector3(0.0, 1.78, 0.0), NAVY)
			for side: float in [-1.0, 1.0]:
				ArenaKit.deco_cylinder(_hat_root, 0.088, 0.06, Vector3(side * 0.1, 1.8, -0.235), main, Vector3(90.0, 0.0, 0.0))
				ArenaKit.deco_cylinder(_hat_root, 0.066, 0.07, Vector3(side * 0.1, 1.8, -0.24), Color(0.45, 0.88, 1.0), Vector3(90.0, 0.0, 0.0))
		&"bunny":
			for side: float in [-1.0, 1.0]:
				var ear := ArenaKit.deco_sphere(_hat_root, 0.07, Vector3(side * 0.11, HAT_Y + 0.2, 0.0), Color(0.97, 0.97, 1.0), 3.2)
				ear.rotation_degrees.z = -side * 14.0
				var inner := ArenaKit.deco_sphere(_hat_root, 0.04, Vector3(side * 0.112, HAT_Y + 0.2, -0.04), Color(1.0, 0.62, 0.75), 4.5)
				inner.rotation_degrees.z = -side * 14.0
		&"horns":
			for side: float in [-1.0, 1.0]:
				ArenaKit.deco_cylinder(_hat_root, 0.065, 0.22, Vector3(side * 0.14, 1.92, -0.05), Color(0.92, 0.16, 0.22),
						Vector3(0.0, 0.0, -side * 25.0), 0.0)
		&"spiky":
			# Spiky cartoon hair, straight out of a comic.
			var hair := Color(1.0, 0.74, 0.18)
			ArenaKit.deco_sphere(_hat_root, 0.235, Vector3(0.0, 1.7, 0.02), hair, 0.85)
			for i in 7:
				var direction := Vector3.UP
				if i > 0:
					var around := TAU * float(i - 1) / 6.0
					direction = Vector3(sin(0.7) * cos(around), cos(0.7), sin(0.7) * sin(around))
				var spike := ArenaKit.deco_cylinder(_hat_root, 0.075, 0.24, Vector3(0.0, 1.68, 0.02) + direction * 0.27, hair,
						Vector3.ZERO, 0.0)
				spike.quaternion = Quaternion(Vector3.UP, direction)
		_:
			# No hat: a cheerful tuft of hair.
			ArenaKit.deco_sphere(_hat_root, 0.2, Vector3(0.0, HAT_Y - 0.06, 0.02), Color(0.4, 0.25, 0.12), 0.6)


func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
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
