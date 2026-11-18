class_name GrenadePickup
extends Node3D
## Foam Grenade pickup: a bouncy foam grenade hovers in a warm orange beam of light.
## Touching it grants +1 Foam Grenade to the player or bot (up to GRENADE_MAX).
## Respawns automatically after collection.

signal spawned
signal collected(actor: Actor)

const PICKUP_RADIUS := 1.3
const BEAM_HEIGHT := 12.0

@export var respawn_delay: float = 25.0
@export var first_delay: float = 6.0

var active: bool = true

var _available: bool = false
var _wait_left: float = 0.0
var _time: float = 0.0
var _area: Area3D
var _display: Node3D
var _model: Node3D
var _beam: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group(&"grenade_pickups")
	_wait_left = first_delay

	ArenaKit.deco_cylinder(self, 0.8, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.18, 0.20, 0.28))
	_ring = ArenaKit.deco_cylinder(self, 0.65, 0.13, Vector3(0.0, 0.07, 0.0), Color(0.95, 0.48, 0.12))

	_display = Node3D.new()
	_display.position.y = 1.3
	add_child(_display)

	_build_model()

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
	beam_material.albedo_color = Color(1.0, 0.55, 0.12, 0.2)
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
	_area.body_entered.connect(_on_body_entered)
	_refresh()


func _build_model() -> void:
	_model = Node3D.new()
	_display.add_child(_model)

	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.24
	cyl.bottom_radius = 0.24
	cyl.height = 0.5
	cyl.radial_segments = 16
	body.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.48, 0.12)
	mat.roughness = 0.7
	body.material_override = mat
	_model.add_child(body)

	var rubber_mat := StandardMaterial3D.new()
	rubber_mat.albedo_color = Color(0.18, 0.20, 0.26)
	rubber_mat.roughness = 0.9

	for cap_y: float in [-0.25, 0.25]:
		var cap := MeshInstance3D.new()
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.26
		cap_mesh.bottom_radius = 0.26
		cap_mesh.height = 0.08
		cap_mesh.radial_segments = 16
		cap.mesh = cap_mesh
		cap.material_override = rubber_mat
		cap.position.y = cap_y
		_model.add_child(cap)


func is_available() -> bool:
	return _available


func make_available() -> void:
	_available = true
	_wait_left = 0.0
	_refresh()
	spawned.emit()
	Sfx.play_at(&"powerup_pickup", global_position, 1.2, -2.0)


func _process(delta: float) -> void:
	_time += delta
	if not active:
		return

	if _available:
		_display.position.y = 1.3 + sin(_time * 2.8) * 0.14
		_display.rotation.y += 1.8 * delta
		return

	_wait_left -= delta
	if _wait_left <= 0.0:
		make_available()
	else:
		_label.text = "GRENADE IN %ds" % int(ceilf(_wait_left))


func _refresh() -> void:
	_display.visible = _available
	_beam.visible = _available
	_label.visible = true
	if _available:
		_label.text = "FOAM GRENADE"
		_label.modulate = Color(1.0, 0.7, 0.2)
	else:
		_label.modulate = UiKit.CREAM


func _on_body_entered(body: Node) -> void:
	if not _available:
		return
	var actor := body as Actor
	if actor == null or not is_instance_valid(actor) or not actor.alive:
		return
	if actor.grenade_count >= Actor.GRENADE_MAX:
		return

	actor.add_grenade(1)
	_available = false
	_wait_left = respawn_delay
	_refresh()
	Sfx.play_at(&"powerup_pickup", global_position, 1.1, -1.0)
	collected.emit(actor)
