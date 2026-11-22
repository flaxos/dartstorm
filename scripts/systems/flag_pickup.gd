class_name FlagPickup
extends Node3D
## 3D Flag entity for Capture The Flag (CTF).
## Sits on a home base pedestal. An opposing team player picks it up and carries
## it on their back to their home base to score a capture. If the carrier is tagged
## out, the flag drops to the ground and can be recovered by teammates or enemy players.

signal picked_up(flag: FlagPickup, carrier: Actor)
signal dropped(flag: FlagPickup, at_position: Vector3)
signal returned(flag: FlagPickup)
signal captured(flag: FlagPickup, carrier: Actor)

enum State { AT_BASE, CARRIED, DROPPED }

const PICKUP_RADIUS := 1.8
const CAPTURE_RADIUS := 2.6
const AUTO_RETURN_SECONDS := 18.0
const POLE_HEIGHT := 2.2

@export var team_id: int = 0  # 0 = Blue, 1 = Orange

var state: State = State.AT_BASE
var carrier: Actor = null
var base_position: Vector3 = Vector3.ZERO
var drop_timer: float = 0.0

var _time: float = 0.0
var _area: Area3D
var _pedestal: Node3D
var _flag_model: Node3D
var _banner_mesh: MeshInstance3D
var _label: Label3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group(&"flags")
	base_position = global_position

	var team_col := GameMode.team_color(team_id)

	# 1. Base Pedestal (permanent fixture at base)
	_pedestal = Node3D.new()
	_pedestal.name = "Pedestal"
	add_child(_pedestal)
	ArenaKit.deco_cylinder(_pedestal, 1.4, 0.12, Vector3(0.0, 0.06, 0.0), Color(0.15, 0.18, 0.25))
	var ring := ArenaKit.deco_cylinder(_pedestal, 1.25, 0.14, Vector3(0.0, 0.07, 0.0), team_col, Vector3.ZERO, -1.0, ArenaKit.SurfaceType.PLASTIC)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 2. Moving Flag Assembly
	_flag_model = Node3D.new()
	_flag_model.name = "FlagModel"
	add_child(_flag_model)

	# Pole
	var pole := ArenaKit.deco_cylinder(_flag_model, 0.045, POLE_HEIGHT, Vector3(0.0, POLE_HEIGHT * 0.5, 0.0), Color(0.85, 0.88, 0.92), Vector3.ZERO, -1.0, ArenaKit.SurfaceType.METAL)
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Gold finial sphere on top
	ArenaKit.deco_sphere(_flag_model, 0.09, Vector3(0.0, POLE_HEIGHT + 0.08, 0.0), Color(1.0, 0.85, 0.2), 1.0, 0.2, ArenaKit.SurfaceType.METAL)

	# Cloth Banner (Pennant)
	_banner_mesh = MeshInstance3D.new()
	var banner_box := BoxMesh.new()
	banner_box.size = Vector3(0.85, 0.55, 0.02)
	_banner_mesh.mesh = banner_box
	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = team_col
	banner_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	banner_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	banner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	banner_mat.roughness = 0.6
	_banner_mesh.material_override = banner_mat
	_banner_mesh.position = Vector3(0.44, POLE_HEIGHT - 0.35, 0.0)
	_flag_model.add_child(_banner_mesh)

	# Beacon glow
	_light = OmniLight3D.new()
	_light.light_color = team_col
	_light.light_energy = 1.2
	_light.omni_range = 6.0
	_light.position = Vector3(0.0, 1.8, 0.0)
	_flag_model.add_child(_light)

	# Floating Label
	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 46
	_label.pixel_size = 0.0075
	_label.outline_size = 10
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = POLE_HEIGHT + 0.45
	_label.modulate = team_col
	_flag_model.add_child(_label)

	# 3. Detection Area
	_area = Area3D.new()
	_area.name = "DetectionArea"
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
	_area.body_entered.connect(_on_body_entered)
	add_child(_area)

	reset_to_base()


func reset_to_base() -> void:
	if carrier != null and is_instance_valid(carrier):
		if carrier.tagged_out.is_connected(_on_carrier_tagged_out):
			carrier.tagged_out.disconnect(_on_carrier_tagged_out)
	carrier = null
	state = State.AT_BASE
	drop_timer = 0.0
	global_position = base_position
	_flag_model.position = Vector3.ZERO
	_flag_model.rotation = Vector3.ZERO
	_flag_model.visible = true
	_pedestal.visible = true
	_update_label()


func drop() -> void:
	if state != State.CARRIED:
		return
	var drop_pos := global_position
	if carrier != null and is_instance_valid(carrier):
		drop_pos = carrier.global_position
		if carrier.tagged_out.is_connected(_on_carrier_tagged_out):
			carrier.tagged_out.disconnect(_on_carrier_tagged_out)
	carrier = null
	state = State.DROPPED
	drop_timer = AUTO_RETURN_SECONDS
	global_position = drop_pos
	_flag_model.position = Vector3.ZERO
	_flag_model.rotation = Vector3(0.0, 0.0, deg_to_rad(25.0))  # Leaning on floor
	_update_label()
	Sfx.play_at(&"powerup", global_position, 0.8, -2.0)
	dropped.emit(self, drop_pos)


func return_to_base() -> void:
	reset_to_base()
	Sfx.play(&"flag_capture", 1.2, -1.0)
	returned.emit(self)


func capture(by_actor: Actor) -> void:
	reset_to_base()
	Sfx.play(&"flag_capture", 1.0, 2.0)
	captured.emit(self, by_actor)


func _on_carrier_tagged_out(_victim: Actor, _attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	drop()


func _physics_process(delta: float) -> void:
	_time += delta

	# Animated flag fluttering in wind
	if _banner_mesh != null:
		_banner_mesh.rotation.y = sin(_time * 5.0) * 0.15
		_banner_mesh.rotation.z = cos(_time * 4.0) * 0.08

	match state:
		State.AT_BASE:
			_flag_model.position = Vector3(0.0, sin(_time * 2.0) * 0.04, 0.0)
			_flag_model.rotation.y = _time * 0.5
		State.CARRIED:
			if carrier == null or not is_instance_valid(carrier) or not carrier.alive or carrier.is_tagged_out:
				drop()
				return
			# Stick closely behind carrier's torso
			var fwd := -carrier.global_transform.basis.z
			var up := carrier.global_transform.basis.y
			global_position = carrier.global_position - fwd * 0.35 + up * 0.6
			_flag_model.rotation = carrier.rotation
			_flag_model.rotation.x = deg_to_rad(15.0)  # Tilted proudly back
			_area.global_position = carrier.global_position
		State.DROPPED:
			drop_timer -= delta
			_update_label()
			if drop_timer <= 0.0:
				return_to_base()


func _on_body_entered(body: Node3D) -> void:
	var actor := body as Actor
	if actor == null or not actor.alive or actor.is_tagged_out:
		return

	match state:
		State.AT_BASE:
			if actor.team_id != team_id:
				# Enemy touches our flag at base -> Pick it up!
				_attach_carrier(actor)
		State.DROPPED:
			if actor.team_id == team_id:
				# Teammate touches dropped flag -> Return it!
				return_to_base()
			else:
				# Enemy touches dropped flag -> Pick it up!
				_attach_carrier(actor)
		State.CARRIED:
			pass


func _attach_carrier(actor: Actor) -> void:
	carrier = actor
	state = State.CARRIED
	drop_timer = 0.0
	if not carrier.tagged_out.is_connected(_on_carrier_tagged_out):
		carrier.tagged_out.connect(_on_carrier_tagged_out)
	_update_label()
	Sfx.play(&"flag_pickup", 1.0, 1.0)
	picked_up.emit(self, carrier)


func _update_label() -> void:
	var team_name_str := GameMode.team_name(team_id)
	match state:
		State.AT_BASE:
			_label.text = "%s FLAG" % team_name_str
		State.CARRIED:
			_label.text = "TAKEN!"
		State.DROPPED:
			_label.text = "DROPPED (%ds)" % maxi(int(drop_timer), 0)
