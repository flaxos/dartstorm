class_name WindZone
extends Node3D
## A box of moving air. Darts inside it are pushed along `direction`, so shots
## visibly curve. The zone draws its own streaks, drifting arrows, windsock and
## (optionally) a giant fan so players can read the wind at a glance.

## Wind direction in this node's local space.
@export var direction: Vector3 = Vector3(0.0, 0.0, -1.0)
## Push applied to darts, in m/s^2 (scaled by each dart's wind_response).
@export var strength: float = 40.0
## Size of the windy box, centred on this node.
@export var size: Vector3 = Vector3(20.0, 5.0, 12.0)
@export var tint: Color = Color(0.75, 0.95, 1.0)
@export var show_fan: bool = true
## 0 = steady wind. Above 0 the strength pulses, ready for stormy arenas.
@export_range(0.0, 1.0) var gust_amount: float = 0.0
@export var gust_period: float = 4.0

var _time: float = 0.0
var _arrows: Array[Node3D] = []
var _fan_blades: Node3D
var _sock: Node3D


func _ready() -> void:
	add_to_group(&"wind_zones")
	_build_visuals()
	var field := get_tree().get_first_node_in_group(&"wind_field") as WindField
	if field != null and field.is_ancestor_of_arena(self):
		field.register_zone(self)


func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return absf(local.x) <= size.x * 0.5 and absf(local.y) <= size.y * 0.5 and absf(local.z) <= size.z * 0.5


## Wind acceleration at a world point (zero outside the box).
func get_wind_at(point: Vector3) -> Vector3:
	if not contains(point):
		return Vector3.ZERO
	return (global_transform.basis * direction.normalized()).normalized() * current_strength()


func current_strength() -> float:
	if gust_amount <= 0.0:
		return strength
	return strength * (1.0 + gust_amount * sin(_time * TAU / maxf(gust_period, 0.1)))


func _process(delta: float) -> void:
	_time += delta
	var local_dir := direction.normalized()
	var travel := _extent_along(local_dir)
	for i in _arrows.size():
		var offset := fposmod(_time * 0.12 + float(i) / float(_arrows.size()), 1.0) - 0.5
		var arrow := _arrows[i]
		arrow.position = local_dir * offset * travel * 2.0 + _arrow_lane(i)
		arrow.scale = Vector3.ONE * (0.4 + 0.6 * sin((offset + 0.5) * PI))
	if _fan_blades != null:
		_fan_blades.rotate_z(delta * 9.0)
	if _sock != null:
		_sock.rotation.x = sin(_time * 5.0) * 0.12
		_sock.rotation.y = sin(_time * 3.1) * 0.15


func _extent_along(local_dir: Vector3) -> float:
	return absf(local_dir.x) * size.x * 0.5 + absf(local_dir.y) * size.y * 0.5 + absf(local_dir.z) * size.z * 0.5


func _arrow_lane(index: int) -> Vector3:
	var local_dir := direction.normalized()
	var across := local_dir.cross(Vector3.UP)
	if across.length_squared() < 0.01:
		across = Vector3.RIGHT
	across = across.normalized()
	var width := _extent_along(across)
	var lanes := float(maxi(_arrows.size(), 1))
	return across * width * ((float(index) + 0.5) / lanes * 2.0 - 1.0) * 0.7


func _build_visuals() -> void:
	var local_dir := direction.normalized()
	var facing := Basis.looking_at(local_dir, Vector3.UP if absf(local_dir.y) < 0.99 else Vector3.RIGHT)
	var travel := _extent_along(local_dir)

	# Faint tinted volume so the edges of the zone are readable.
	var volume := MeshInstance3D.new()
	var volume_mesh := BoxMesh.new()
	volume_mesh.size = size
	volume.mesh = volume_mesh
	var volume_material := StandardMaterial3D.new()
	volume_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	volume_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	volume_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	volume_material.albedo_color = Color(tint, 0.07)
	volume.material_override = volume_material
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(volume)

	# Streaks of air racing downwind.
	var streak_speed := 14.0
	var streak_life := 0.45
	var drift := streak_speed * streak_life
	var streaks := CPUParticles3D.new()
	streaks.amount = int(clampf(70.0 * GameSettings.visual_intensity, 12.0, 140.0))
	streaks.lifetime = streak_life
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var extents := size * 0.5 - Vector3(absf(local_dir.x), absf(local_dir.y), absf(local_dir.z)) * drift * 0.5
	streaks.emission_box_extents = Vector3(maxf(extents.x, 0.2), maxf(extents.y, 0.2), maxf(extents.z, 0.2))
	streaks.position = -local_dir * drift * 0.5
	streaks.direction = local_dir
	streaks.spread = 1.5
	streaks.gravity = Vector3.ZERO
	streaks.initial_velocity_min = streak_speed * 0.8
	streaks.initial_velocity_max = streak_speed * 1.2
	streaks.particle_flag_align_y = true
	var streak_mesh := BoxMesh.new()
	streak_mesh.size = Vector3(0.04, 1.3, 0.04)
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(1.0, 1.0, 1.0, 0.55)
	streak_mesh.material = streak_material
	streaks.mesh = streak_mesh
	streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streaks)

	# Big drifting arrows that point the way the wind blows.
	var arrow_material := StandardMaterial3D.new()
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_material.albedo_color = Color(tint.lightened(0.3), 0.6)
	for i in 3:
		var arrow := Node3D.new()
		arrow.basis = facing
		_arrow_part(arrow, Vector3(0.3, 0.08, 1.6), Vector3(0.0, 0.0, 0.3), 0.0, arrow_material)
		_arrow_part(arrow, Vector3(0.3, 0.08, 1.1), Vector3(0.36, 0.0, -0.75), -38.0, arrow_material)
		_arrow_part(arrow, Vector3(0.3, 0.08, 1.1), Vector3(-0.36, 0.0, -0.75), 38.0, arrow_material)
		add_child(arrow)
		_arrows.append(arrow)

	# Windsock on a pole at the upwind corner.
	var pole_height := size.y + 1.0
	var across := local_dir.cross(Vector3.UP)
	if across.length_squared() < 0.01:
		across = Vector3.RIGHT
	across = across.normalized()
	var pole_base := -local_dir * (travel - 0.8) + across * (_extent_along(across) - 0.8) + Vector3.DOWN * size.y * 0.5
	ArenaKit.deco_cylinder(self, 0.07, pole_height, pole_base + Vector3.UP * pole_height * 0.5, Color(0.9, 0.9, 0.95))
	var sock_pivot := Node3D.new()
	sock_pivot.position = pole_base + Vector3.UP * (pole_height - 0.3)
	sock_pivot.basis = facing
	add_child(sock_pivot)
	_sock = Node3D.new()
	sock_pivot.add_child(_sock)
	ArenaKit.deco_cylinder(_sock, 0.16, 0.7, Vector3(0.0, 0.0, -0.45), Color(1.0, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), 0.34)
	ArenaKit.deco_cylinder(_sock, 0.1, 0.7, Vector3(0.0, 0.0, -1.15), Color(1.0, 1.0, 1.0), Vector3(90.0, 0.0, 0.0), 0.16)
	ArenaKit.deco_cylinder(_sock, 0.05, 0.6, Vector3(0.0, 0.0, -1.8), Color(1.0, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), 0.1)

	if show_fan:
		_build_fan(facing, -local_dir * (travel - 0.35))


func _arrow_part(parent: Node3D, part_size: Vector3, pos: Vector3, yaw_deg: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = part_size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation_degrees.y = yaw_deg
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _build_fan(facing: Basis, at: Vector3) -> void:
	var fan := Node3D.new()
	fan.basis = facing
	fan.position = at
	add_child(fan)
	var radius := minf(size.y * 0.5 - 0.1, 2.4)
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.25
	ring.outer_radius = radius
	ArenaKit.deco(fan, ring, Vector3.ZERO, Color(0.2, 0.25, 0.35), Vector3(90.0, 0.0, 0.0))
	ArenaKit.deco_cylinder(fan, radius - 0.1, 0.12, Vector3(0.0, 0.0, 0.25), Color(0.14, 0.18, 0.28), Vector3(90.0, 0.0, 0.0))
	_fan_blades = Node3D.new()
	fan.add_child(_fan_blades)
	for i in 4:
		var blade := ArenaKit.deco_box(_fan_blades, Vector3(0.55, radius - 0.4, 0.07), Vector3.ZERO, Color(1.0, 0.55, 0.1))
		blade.rotation_degrees = Vector3(0.0, 18.0, 90.0 * i)
		blade.position = blade.basis * Vector3(0.0, (radius - 0.4) * 0.5 + 0.15, 0.0)
	ArenaKit.deco_sphere(_fan_blades, 0.35, Vector3.ZERO, Color(1.0, 0.85, 0.2))
