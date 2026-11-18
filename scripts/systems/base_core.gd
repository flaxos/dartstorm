class_name BaseCore
extends StaticBody3D
## The central base objective that defenders protect in Zombie Siege mode.
## Has 1000 HP. If destroyed, the defense fails and the zombies overrun the base!
## Can be repaired between waves using Scrap currency.

signal health_changed(current: float, max_health: float)
signal damaged(amount: float, attacker: Node)
signal repaired(amount: float)
signal destroyed

const MAX_HEALTH := 1000.0

var max_health: float = MAX_HEALTH
var health: float = MAX_HEALTH
var is_destroyed: bool = false

var _collision_shape: CollisionShape3D
var _crystal: MeshInstance3D
var _ring: MeshInstance3D
var _alarm_light: OmniLight3D
var _hp_label: Label3D
var _flash_left: float = 0.0
var _rot_speed: float = 1.5


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_build_visuals()


func _build_visuals() -> void:
	_collision_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.4
	cyl.height = 2.4
	_collision_shape.shape = cyl
	_collision_shape.position = Vector3(0.0, 1.2, 0.0)
	add_child(_collision_shape)

	# Pedestal Base
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.3
	base_mesh.bottom_radius = 1.5
	base_mesh.height = 0.6
	base_mesh.radial_segments = 16
	var pedestal := MeshInstance3D.new()
	pedestal.mesh = base_mesh
	pedestal.material_override = ArenaKit.mat(UiKit.NAVY_DARK, 0.4, 0.2)
	pedestal.position = Vector3(0.0, 0.3, 0.0)
	add_child(pedestal)

	# Glowing Energy Core Crystal (Diamond/Prism)
	var prism_mesh := CylinderMesh.new()
	prism_mesh.top_radius = 0.0
	prism_mesh.bottom_radius = 0.7
	prism_mesh.height = 1.2
	prism_mesh.radial_segments = 6
	_crystal = MeshInstance3D.new()
	_crystal.mesh = prism_mesh
	var crystal_mat := StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.2, 0.75, 1.0, 0.9)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.15, 0.7, 1.0)
	crystal_mat.emission_energy_multiplier = 2.5
	crystal_mat.roughness = 0.1
	crystal_mat.metallic = 0.1
	_crystal.material_override = crystal_mat
	_crystal.position = Vector3(0.0, 1.3, 0.0)
	add_child(_crystal)

	# Orbital Stabilizer Ring
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.85
	ring_mesh.outer_radius = 1.05
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 12
	_ring = MeshInstance3D.new()
	_ring.mesh = ring_mesh
	_ring.material_override = ArenaKit.mat(UiKit.ORANGE, 0.3, 0.8)
	_ring.position = Vector3(0.0, 1.3, 0.0)
	add_child(_ring)

	# Alarm Beacon Light
	_alarm_light = OmniLight3D.new()
	_alarm_light.light_color = UiKit.ORANGE_HOT
	_alarm_light.light_energy = 2.0
	_alarm_light.omni_range = 8.0
	_alarm_light.position = Vector3(0.0, 1.8, 0.0)
	_alarm_light.visible = false
	add_child(_alarm_light)

	# Overhead 3D HP Label
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.no_depth_test = true
	_hp_label.font = UiKit.font()
	_hp_label.font_size = 32
	_hp_label.pixel_size = 0.003
	_hp_label.outline_size = 8
	_hp_label.outline_modulate = UiKit.NAVY_DARK
	_hp_label.modulate = UiKit.CREAM
	_hp_label.position = Vector3(0.0, 2.5, 0.0)
	add_child(_hp_label)
	_update_label()


func _process(delta: float) -> void:
	if is_destroyed:
		return
	if _crystal != null:
		_crystal.rotate_y(delta * _rot_speed)
	if _ring != null:
		_ring.rotate_x(delta * (_rot_speed * 0.7))
		_ring.rotate_z(delta * (_rot_speed * 0.5))

	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_restore_core_materials()

	# Pulse alarm light if critically low (< 350 HP)
	if health < 350.0 and _alarm_light != null:
		_alarm_light.visible = true
		_alarm_light.light_energy = 1.5 + sin(Time.get_ticks_msec() * 0.008) * 1.5


func damage(amount: float, attacker: Node = null) -> void:
	if is_destroyed or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_update_label()
	health_changed.emit(health, max_health)
	damaged.emit(amount, attacker)
	_flash_hit()

	if health <= 0.0:
		destroy_core()


func repair(amount: float) -> void:
	if is_destroyed or amount <= 0.0:
		return
	health = minf(health + amount, max_health)
	_update_label()
	health_changed.emit(health, max_health)
	repaired.emit(amount)
	if _alarm_light != null and health >= 350.0:
		_alarm_light.visible = false
	if has_node("/root/Sfx"):
		(get_node("/root/Sfx") as Node).call("play", &"pickup")


func _flash_hit() -> void:
	_flash_left = 0.1
	if _crystal != null:
		var flash_mat := StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(1.0, 0.1, 0.1)
		flash_mat.emission_energy_multiplier = 4.0
		_crystal.material_override = flash_mat
	if has_node("/root/Sfx"):
		(get_node("/root/Sfx") as Node).call("play", &"tag")


func _restore_core_materials() -> void:
	if _crystal != null:
		var ratio := health / max_health
		var crystal_mat := StandardMaterial3D.new()
		var col := Color(0.2, 0.75, 1.0).lerp(Color(1.0, 0.4, 0.1), 1.0 - ratio)
		crystal_mat.albedo_color = col
		crystal_mat.emission_enabled = true
		crystal_mat.emission = col
		crystal_mat.emission_energy_multiplier = 2.0
		_crystal.material_override = crystal_mat


func _update_label() -> void:
	if _hp_label == null:
		return
	var hp_int := int(ceilf(health))
	var max_int := int(max_health)
	_hp_label.text = "BASE CORE\n%d / %d" % [hp_int, max_int]
	var ratio := health / max_health
	if ratio > 0.6:
		_hp_label.modulate = UiKit.CREAM
	elif ratio > 0.3:
		_hp_label.modulate = UiKit.ORANGE
	else:
		_hp_label.modulate = Color(0.95, 0.22, 0.25)


func destroy_core() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	health = 0.0
	_update_label()
	if _hp_label != null:
		_hp_label.text = "BASE OVERRUN!"
		_hp_label.modulate = Color(0.95, 0.22, 0.25)
	if _crystal != null:
		_crystal.visible = false
	if _ring != null:
		_ring.visible = false
	if _alarm_light != null:
		_alarm_light.visible = true
		_alarm_light.light_color = Color(0.95, 0.22, 0.25)
		_alarm_light.light_energy = 5.0
	destroyed.emit()
