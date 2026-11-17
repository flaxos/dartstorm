class_name WaterPuddle
extends Node3D
## An environmental water hazard. Walking into it splashes and soaks actors
## with the Wet status. Hitting it with a Lightning dart conducts electricity,
## electrifying the puddle for 2.0 seconds and zapping anyone inside!

signal puddle_electrified(puddle: WaterPuddle)

@export var radius: float = 2.5
@export var puddle_color: Color = Color(0.2, 0.65, 0.95, 0.55)

var electrified_left: float = 0.0

var _area: Area3D
var _water_mesh: MeshInstance3D
var _electric_mesh: MeshInstance3D
var _time: float = 0.0


func _ready() -> void:
	add_to_group(&"water_puddles")

	# Water disk
	_water_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 0.95
	cyl.height = 0.04
	cyl.radial_segments = 24
	cyl.rings = 1
	_water_mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = puddle_color
	mat.roughness = 0.08
	mat.metallic = 0.2
	mat.metallic_specular = 0.9
	_water_mesh.material_override = mat
	_water_mesh.position.y = 0.02
	_water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_mesh)

	# Electric crackle ring/disk
	_electric_mesh = MeshInstance3D.new()
	var elec_cyl := CylinderMesh.new()
	elec_cyl.top_radius = radius * 0.98
	elec_cyl.bottom_radius = radius * 0.98
	elec_cyl.height = 0.06
	elec_cyl.radial_segments = 20
	elec_cyl.rings = 1
	_electric_mesh.mesh = elec_cyl
	var elec_mat := StandardMaterial3D.new()
	elec_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	elec_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	elec_mat.albedo_color = Color(1.0, 1.0, 0.3, 0.75)
	_electric_mesh.material_override = elec_mat
	_electric_mesh.position.y = 0.03
	_electric_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_electric_mesh.visible = false
	add_child(_electric_mesh)

	# Trigger area for actors and darts
	_area = Area3D.new()
	_area.collision_layer = Layers.TARGETS
	_area.collision_mask = Layers.ACTORS
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.8
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.4
	_area.add_child(col)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)


func is_electrified() -> bool:
	return electrified_left > 0.0


func electrify(duration: float = 2.0) -> void:
	electrified_left = maxf(electrified_left, duration)
	_electric_mesh.visible = true
	Sfx.play_at(&"zap", global_position + Vector3.UP * 0.5, 0.95, 2.0)
	puddle_electrified.emit(self)
	_shock_occupants()


func on_dart_hit(dart: DartProjectile, _hit_point: Vector3) -> void:
	if dart == null or dart.data == null:
		return
	if dart.data.element == DartData.Element.LIGHTNING:
		electrify(2.0)
	elif dart.data.element == DartData.Element.FIRE:
		Sfx.play_at(&"steam", global_position + Vector3.UP * 0.3, 1.2, -3.0)


func _on_body_entered(body: Node3D) -> void:
	var actor := body as Actor
	if actor == null or not actor.alive:
		return
	_splash_actor(actor)
	if is_electrified():
		_shock_actor(actor)


func _physics_process(delta: float) -> void:
	_time += delta
	if electrified_left > 0.0:
		electrified_left -= delta
		_electric_mesh.visible = true
		_electric_mesh.scale = Vector3.ONE * (1.0 + sin(_time * 40.0) * 0.06)
		_shock_occupants()
		if electrified_left <= 0.0:
			_electric_mesh.visible = false


func _splash_actor(actor: Actor) -> void:
	if actor.elemental != null:
		actor.elemental.wet_left = maxf(actor.elemental.wet_left, 4.0)
		actor.elemental.status_started.emit(DartData.Element.WATER, 4.0)
	Sfx.play_at(&"splash", actor.global_position, 1.1, -4.0, 0.1)


func _shock_occupants() -> void:
	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive and not actor.is_protected():
			_shock_actor(actor)


func _shock_actor(actor: Actor) -> void:
	# Electrocution damage tick
	var power := 15.0
	if actor.shield_points > 0.0:
		if power <= actor.shield_points:
			actor.shield_points -= power
			actor.shield_changed.emit(actor.shield_points, Actor.SHIELD_MAX)
			Sfx.play_at(&"shield_hit", actor.global_position, 1.0, 0.0, 0.1)
			return
		else:
			power -= actor.shield_points
			actor.shield_points = 0.0
			actor.shield_changed.emit(0.0, Actor.SHIELD_MAX)
			actor.shield_broken.emit(actor)
			Sfx.play_at(&"shield_pop", actor.global_position, 1.0, 0.0)

	actor.tag_meter = minf(actor.tag_meter + power, actor.tag_meter_max)
	actor.meter_changed.emit(actor.tag_meter, actor.tag_meter_max)
	if actor.elemental != null and actor.elemental.wet_left > 0.0:
		actor.elemental.combo_triggered.emit(&"conductive_shock", actor.global_position + Vector3.UP)
	if actor.tag_meter >= actor.tag_meter_max:
		actor._tag_out(null, null, false)
