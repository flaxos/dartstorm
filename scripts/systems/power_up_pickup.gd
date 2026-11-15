class_name PowerUpPickup
extends Node3D
## Power-up mode: a giant spinning Chainstorm hovers in a beam of orange light
## on the treehouse deck. Whoever touches it first carries it (with a full belt)
## until they're tagged out. Then it comes back after a while, and the announcer
## tells everyone. The countdown only runs while the match is being played.

signal spawned
signal collected(actor: Actor)

const PICKUP_RADIUS := 1.3
const BEAM_HEIGHT := 14.0

var weapon: WeaponData
var belt: int = 300
var first_delay: float = 20.0
var respawn_delay: float = 45.0
## The match turns this on when play starts and off when it ends.
var active: bool = false

var _available: bool = false
var _wait_left: float = 0.0
var _time: float = 0.0
var _area: Area3D
var _display: Node3D
var _model: BlasterModel
var _beam: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D


func setup(p_weapon: WeaponData, p_belt: int, p_first_delay: float, p_respawn: float) -> void:
	weapon = p_weapon
	belt = p_belt
	first_delay = p_first_delay
	respawn_delay = p_respawn
	_wait_left = first_delay


func _ready() -> void:
	add_to_group(&"power_ups")
	ArenaKit.deco_cylinder(self, 0.9, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.15, 0.2, 0.35))
	_ring = ArenaKit.deco_cylinder(self, 0.75, 0.13, Vector3(0.0, 0.07, 0.0), UiKit.ORANGE)
	_display = Node3D.new()
	_display.position.y = 1.4
	add_child(_display)
	if weapon != null:
		_model = BlasterModel.create(weapon, false)
		_model.scale = Vector3.ONE * 2.6
		_display.add_child(_model)
	_beam = MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.55
	beam_mesh.bottom_radius = 0.8
	beam_mesh.height = BEAM_HEIGHT
	beam_mesh.radial_segments = 16
	beam_mesh.rings = 1
	_beam.mesh = beam_mesh
	var beam_material := StandardMaterial3D.new()
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_material.albedo_color = Color(1.0, 0.55, 0.1, 0.22)
	_beam.material_override = beam_material
	_beam.position.y = BEAM_HEIGHT * 0.5
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 64
	_label.pixel_size = 0.007
	_label.outline_size = 14
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.9
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
	_refresh()


func is_available() -> bool:
	return _available


func seconds_until_ready() -> float:
	return 0.0 if _available else _wait_left


## Makes it appear right now (used by tests and by the countdown).
func make_available() -> void:
	_available = true
	_wait_left = 0.0
	_refresh()
	Sfx.play_at(&"powerup", global_position + Vector3.UP, 1.0, 2.0)
	spawned.emit()


func _physics_process(delta: float) -> void:
	_time += delta
	_display.rotation.y = _time * 1.6
	_display.position.y = 1.4 + sin(_time * 2.4) * 0.15
	if not active:
		return
	if not _available:
		_wait_left -= delta
		if _wait_left <= 0.0:
			make_available()
		else:
			_label.text = "%s IN %d" % [_short_name(), int(ceilf(_wait_left))]
		return
	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive and actor.controls_enabled and not actor.arsenal.has_weapon(weapon.id):
			give_to(actor)
			return


## Hands the power weapon to an actor and starts the respawn countdown.
func give_to(actor: Actor) -> void:
	actor.arsenal.add_weapon(weapon, belt)
	_available = false
	_wait_left = respawn_delay
	_refresh()
	Sfx.play_at(&"level_up", global_position + Vector3.UP, 0.8)
	collected.emit(actor)


func _refresh() -> void:
	_display.visible = _available
	_beam.visible = _available
	_ring.visible = _available
	_label.modulate = UiKit.ORANGE_HOT if _available else UiKit.GREY
	if _available:
		_label.text = "GRAB THE %s!" % _short_name()
	else:
		_label.text = "%s IN %d" % [_short_name(), int(ceilf(maxf(_wait_left, 0.0)))]


func _short_name() -> String:
	if weapon == null:
		return "POWER-UP"
	var words := weapon.display_name.to_upper().split(" ")
	return words[words.size() - 1]
