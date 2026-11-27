class_name ElementalPickup
extends Node3D
## Elemental Infusion pickup: a glowing elemental canister floating in a colored beam of light.
## Touching it infuses the actor's blasters with that element for 15 seconds.
## Respawns automatically after collection.

signal spawned
signal collected(actor: Actor)

const PICKUP_RADIUS := 1.3
const BEAM_HEIGHT := 12.0
const INFUSION_DURATION := 15.0

@export var element: DartData.Element = DartData.Element.FIRE
@export var respawn_delay: float = 35.0
@export var first_delay: float = 8.0

var active: bool = true

var _available: bool = false
var _wait_left: float = 0.0
var _time: float = 0.0
var _area: Area3D
var _display: Node3D
var _canister: MeshInstance3D
var _beam: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group(&"elemental_pickups")
	_wait_left = first_delay

	var color := _get_element_color()

	ArenaKit.deco_cylinder(self, 0.8, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.15, 0.18, 0.25))
	_ring = ArenaKit.deco_cylinder(self, 0.65, 0.13, Vector3(0.0, 0.07, 0.0), color)

	_display = Node3D.new()
	_display.position.y = 1.3
	add_child(_display)

	_build_canister(color)

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
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.22)
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


func _get_element_color() -> Color:
	match element:
		DartData.Element.FIRE:
			return Color(1.0, 0.45, 0.12)
		DartData.Element.WATER:
			return Color(0.2, 0.75, 1.0)
		DartData.Element.LIGHTNING:
			return Color(1.0, 0.95, 0.25)
		DartData.Element.ICE:
			return Color(0.82, 0.96, 1.0)
		DartData.Element.WIND:
			return Color(0.75, 0.95, 0.85)
	return Color.WHITE


func _get_element_title() -> String:
	match element:
		DartData.Element.FIRE:
			return "PYRO INFUSION"
		DartData.Element.WATER:
			return "HYDRO INFUSION"
		DartData.Element.LIGHTNING:
			return "VOLT INFUSION"
		DartData.Element.ICE:
			return "FROST INFUSION"
		DartData.Element.WIND:
			return "GALE INFUSION"
	return "ELEMENTAL INFUSION"


func _build_canister(color: Color) -> void:
	_canister = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.22
	mesh.height = 0.52
	mesh.radial_segments = 16
	_canister.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.lightened(0.2)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mat.roughness = 0.3
	mat.metallic = 0.4
	_canister.material_override = mat
	_display.add_child(_canister)

	# Metallic core bands
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.2, 0.22, 0.28)
	band_mat.metallic = 0.8
	band_mat.roughness = 0.4

	for band_y: float in [-0.18, 0.18]:
		var band := MeshInstance3D.new()
		var band_mesh := TorusMesh.new()
		band_mesh.inner_radius = 0.20
		band_mesh.outer_radius = 0.25
		band.mesh = band_mesh
		band.material_override = band_mat
		band.position.y = band_y
		_display.add_child(band)


func is_available() -> bool:
	return _available


func make_available() -> void:
	_available = true
	_wait_left = 0.0
	_refresh()
	spawned.emit()
	Sfx.play_at(&"powerup_pickup", global_position, 1.25, -2.0)


func _process(delta: float) -> void:
	_time += delta
	if not active:
		return

	if _available:
		_display.position.y = 1.3 + sin(_time * 2.8) * 0.12
		_display.rotation.y += 2.0 * delta
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
		_label.text = "%s IN %ds" % [_get_element_title().split(" ")[0], int(ceilf(_wait_left))]


func _refresh() -> void:
	_display.visible = _available
	_beam.visible = _available
	_label.visible = true
	if _available:
		_label.text = _get_element_title()
		_label.modulate = _get_element_color().lightened(0.2)
	else:
		_label.modulate = UiKit.CREAM


func _on_body_entered(body: Node) -> void:
	_try_collect(body)


func _try_collect(body: Node) -> void:
	if not active or not _available:
		return
	var actor := body as Actor
	if actor == null or not is_instance_valid(actor) or not actor.alive or actor.is_zombie or actor.is_tagged_out:
		return

	actor.apply_elemental_infusion(element, INFUSION_DURATION)
	_available = false
	_wait_left = respawn_delay
	_refresh()
	Sfx.play_at(&"powerup_pickup", global_position, 1.3, 0.0)
	collected.emit(actor)
