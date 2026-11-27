class_name BatPickup
extends Node3D
## Arena pickup for the Foam Bat melee weapon in standard modes (FFA, Duos,
## Teams, CTF, Plant the Bomb, Floor is Lava, Realistic). Hovering oversized
## cartoon foam bat in a warm golden-orange light beam.

signal spawned
signal collected(actor: Actor)

const PICKUP_RADIUS := 1.4
const BEAM_HEIGHT := 11.0
const BAT_WEAPON_PATH := "res://resources/weapons/foam_bat.tres"

@export var first_delay: float = 2.0
@export var respawn_delay: float = 18.0

var weapon: WeaponData = null
var active: bool = true

var _available: bool = false
var _wait_left: float = 0.0
var _time: float = 0.0
var _area: Area3D
var _display: Node3D
var _model: BlasterModel
var _beam: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group(&"bat_pickups")
	if weapon == null:
		weapon = load(BAT_WEAPON_PATH) as WeaponData
	_wait_left = first_delay

	ArenaKit.deco_cylinder(self, 0.85, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.16, 0.19, 0.28))
	_ring = ArenaKit.deco_cylinder(self, 0.70, 0.13, Vector3(0.0, 0.07, 0.0), Color(1.0, 0.55, 0.12))

	_display = Node3D.new()
	_display.position.y = 1.15
	add_child(_display)
	if weapon != null:
		_model = BlasterModel.create(weapon, false)
		_model.scale = Vector3.ONE * 1.55
		_model.rotation_degrees = Vector3(18.0, 0.0, -24.0)
		_display.add_child(_model)

	_beam = MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.45
	beam_mesh.bottom_radius = 0.68
	beam_mesh.height = BEAM_HEIGHT
	beam_mesh.radial_segments = 16
	beam_mesh.rings = 1
	_beam.mesh = beam_mesh
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_color = Color(1.0, 0.62, 0.15, 0.22)
	_beam.material_override = beam_mat
	_beam.position.y = BEAM_HEIGHT * 0.5
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)

	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 56
	_label.pixel_size = 0.007
	_label.outline_size = 12
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.65
	add_child(_label)

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.ACTORS
	_area.monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = PICKUP_RADIUS
	shape.height = 2.4
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1.2
	_area.add_child(collision)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_refresh()


func is_available() -> bool:
	return _available


func make_available() -> void:
	_available = true
	_wait_left = 0.0
	_refresh()
	spawned.emit()
	Sfx.play_at(&"powerup_pickup", global_position, 1.15, -2.0)


func _process(delta: float) -> void:
	_time += delta
	if _display != null:
		_display.rotation.y += 2.0 * delta
		_display.position.y = 1.15 + sin(_time * 2.8) * 0.14
	if not active:
		return
	if _available:
		if _area != null:
			for body in _area.get_overlapping_bodies():
				_try_collect(body)
				if not _available:
					return
		return
	_wait_left -= delta
	if _wait_left <= 0.0:
		make_available()
	else:
		_label.text = "FOAM BAT IN %ds" % int(ceilf(_wait_left))


func _on_body_entered(body: Node) -> void:
	_try_collect(body)


func _try_collect(body: Node) -> void:
	if not active or not _available or weapon == null:
		return
	var actor := body as Actor
	if actor == null or not is_instance_valid(actor) or not actor.alive or actor.is_zombie or actor.is_tagged_out:
		return
	if actor.arsenal.has_weapon(weapon.id):
		return
	actor.arsenal.add_weapon(weapon, 0)
	_available = false
	_wait_left = respawn_delay
	_refresh()
	Sfx.play_at(&"bat_bonk", global_position, 1.15, -1.0)
	collected.emit(actor)


func _refresh() -> void:
	_display.visible = _available
	_beam.visible = _available
	_ring.visible = _available
	if _available:
		_label.text = "FOAM BAT!"
		_label.modulate = Color(1.0, 0.72, 0.2)
	else:
		_label.text = "FOAM BAT IN %ds" % int(ceilf(maxf(_wait_left, 0.0)))
		_label.modulate = UiKit.CREAM
