class_name CharacterModel
extends Node3D
## A chunky cartoon kid built from primitives: used for bots (and later for
## other players in multiplayer). Forward is -Z, origin at the feet.

const SKIN := Color(1.0, 0.82, 0.66)
const NAVY := Color(0.1, 0.14, 0.3)

var _tint: Color = Color.WHITE
var _upper: Node3D
var _legs: Array[MeshInstance3D] = []
var _weapon_mount: Node3D
var _weapon: BlasterModel
var _backpack: Node3D
var _name_label: Label3D
var _meter_fill: MeshInstance3D
var _walk_phase: float = 0.0
var _flinch: float = 0.0


func setup(display_name: String, tint: Color) -> void:
	_tint = tint
	_build()
	_name_label.text = display_name
	_name_label.modulate = tint.lightened(0.35)


func set_weapon(data: WeaponData) -> void:
	if _weapon != null:
		_weapon.queue_free()
		_weapon = null
	if data == null:
		return
	_weapon = BlasterModel.create(data, false)
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


func _build() -> void:
	var shirt := ArenaKit.mat(_tint, 0.7)
	for side: float in [-1.0, 1.0]:
		var leg := _capsule(self, 0.12, 0.74, Vector3(side * 0.15, 0.37, 0.0), ArenaKit.mat(NAVY))
		_legs.append(leg)

	_upper = Node3D.new()
	add_child(_upper)
	_capsule(_upper, 0.31, 0.86, Vector3(0.0, 1.05, 0.0), shirt)
	ArenaKit.deco_sphere(_upper, 0.26, Vector3(0.0, 1.66, 0.0), SKIN)
	for side: float in [-1.0, 1.0]:
		ArenaKit.deco_sphere(_upper, 0.065, Vector3(side * 0.095, 1.7, -0.215), Color.WHITE)
		ArenaKit.deco_sphere(_upper, 0.034, Vector3(side * 0.095, 1.7, -0.265), Color(0.05, 0.05, 0.1))
		var arm := _capsule(_upper, 0.085, 0.52, Vector3(side * 0.3, 1.18, -0.24), shirt)
		arm.rotation_degrees = Vector3(80.0, side * -18.0, 0.0)
	# Cap with a brim, in the actor's colour.
	ArenaKit.deco_cylinder(_upper, 0.27, 0.13, Vector3(0.0, 1.86, 0.0), _tint.darkened(0.2))
	ArenaKit.deco_box(_upper, Vector3(0.34, 0.035, 0.24), Vector3(0.0, 1.81, -0.3), _tint.darkened(0.2))

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
	var back := _billboard_quad(Vector2(0.9, 0.11), Color(0.03, 0.07, 0.19, 0.8))
	back.position.y = 2.16
	add_child(back)
	_meter_fill = _billboard_quad(Vector2(0.86, 0.075), Color(1.0, 0.48, 0.1))
	_meter_fill.position.y = 2.16
	_meter_fill.sorting_offset = 1.0
	_meter_fill.visible = false
	add_child(_meter_fill)


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
