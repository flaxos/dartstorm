class_name ShieldPickup
extends Node3D
## Foam Shield power-up: a glowing hexagonal bubble hovers in a beam of cyan light.
## Touching it grants 50 shield points, absorbing incoming tag points before popping.
## Respawns automatically after collection.

signal spawned
signal collected(actor: Actor)

const PICKUP_RADIUS := 1.3
const BEAM_HEIGHT := 12.0
const SHIELD_AMOUNT := 50.0

@export var respawn_delay: float = 30.0
@export var first_delay: float = 10.0

var active: bool = true

var _available: bool = false
var _wait_left: float = 0.0
var _time: float = 0.0
var _area: Area3D
var _display: Node3D
var _orb: MeshInstance3D
var _beam: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group(&"shield_pickups")
	_wait_left = first_delay

	ArenaKit.deco_cylinder(self, 0.8, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.12, 0.22, 0.38))
	_ring = ArenaKit.deco_cylinder(self, 0.65, 0.13, Vector3(0.0, 0.07, 0.0), Color(0.2, 0.85, 1.0))

	_display = Node3D.new()
	_display.position.y = 1.3
	add_child(_display)

	_orb = MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.45
	orb_mesh.height = 0.9
	orb_mesh.radial_segments = 20
	orb_mesh.rings = 12
	_orb.mesh = orb_mesh
	var shield_mat := ShaderMaterial.new()
	shield_mat.shader = load("res://assets/materials/foam_shield.gdshader") as Shader
	_orb.material_override = shield_mat
	_display.add_child(_orb)

	_beam = MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.45
	beam_mesh.bottom_radius = 0.65
	beam_mesh.height = BEAM_HEIGHT
	beam_mesh.radial_segments = 16
	beam_mesh.rings = 1
	_beam.mesh = beam_mesh
	var beam_material := StandardMaterial3D.new()
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_material.albedo_color = Color(0.2, 0.85, 1.0, 0.2)
	_beam.material_override = beam_material
	_beam.position.y = BEAM_HEIGHT * 0.5
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)

	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 54
	_label.pixel_size = 0.007
	_label.outline_size = 12
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.6
	add_child(_label)

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.ACTORS
	_area.monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = PICKUP_RADIUS
	shape.height = 2.2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1.1
	_area.add_child(collision)
	add_child(_area)
	_refresh()


func is_available() -> bool:
	return _available


func make_available() -> void:
	_available = true
	_wait_left = 0.0
	_refresh()
	Sfx.play_at(&"powerup", global_position + Vector3.UP, 1.3, -1.0)
	spawned.emit()


func _physics_process(delta: float) -> void:
	_time += delta
	_display.rotation.y = _time * 2.0
	_display.position.y = 1.3 + sin(_time * 2.6) * 0.12

	if not active:
		return
	if not _available:
		_wait_left -= delta
		if _wait_left <= 0.0:
			make_available()
		else:
			_label.text = "SHIELD IN %d" % int(ceilf(_wait_left))
		return

	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive and actor.controls_enabled and not actor.is_zombie and not actor.is_tagged_out and not actor.has_shield():
			give_to(actor)
			return


func give_to(actor: Actor) -> void:
	actor.grant_shield(SHIELD_AMOUNT)
	_available = false
	_wait_left = respawn_delay
	_refresh()
	collected.emit(actor)


func _refresh() -> void:
	_display.visible = _available
	_beam.visible = _available
	_ring.visible = _available
	_label.modulate = Color(0.2, 0.9, 1.0) if _available else UiKit.GREY
	if _available:
		_label.text = "FOAM SHIELD!"
	else:
		_label.text = "SHIELD IN %d" % int(ceilf(maxf(_wait_left, 0.0)))
