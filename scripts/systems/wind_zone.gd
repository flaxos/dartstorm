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
@export var show_windsock: bool = true
## The faint tinted box that shows the zone's edges. Indoors (where the zone
## fills a whole room) it just tints everything, so it can be turned off.
@export var show_volume: bool = true
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
		var speed := 0.20 + float(i % 3) * 0.045
		var offset := fposmod(_time * speed + float(i) / float(maxi(_arrows.size(), 1)), 1.0) - 0.5
		var ribbon := _arrows[i]
		var bob_y := sin(_time * 3.2 + float(i) * 1.4 + offset * 5.0) * 0.35
		var lane := _arrow_lane(i)
		var height_off := ((float(i % 3) - 1.0) * 0.28) * size.y
		ribbon.position = local_dir * offset * travel * 1.85 + lane + Vector3(0.0, height_off + bob_y, 0.0)
		var fade_s := sin((offset + 0.5) * PI)
		ribbon.scale = Vector3(0.65 + 0.45 * fade_s, 0.7 + 0.4 * fade_s, 0.45 + 0.85 * fade_s)
	if _fan_blades != null:
		_fan_blades.rotate_z(delta * 9.0)
	if _sock != null:
		_sock.rotation.x = sin(_time * 5.0) * 0.14
		_sock.rotation.y = sin(_time * 3.1) * 0.18


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

	# Subtle ground-level air-lane pad shimmer (replaces tall cloudy box wall that obscured the sky!)
	var volume := MeshInstance3D.new()
	var volume_mesh := BoxMesh.new()
	volume_mesh.size = Vector3(size.x, 0.06, size.z)
	volume.mesh = volume_mesh
	var volume_material := StandardMaterial3D.new()
	volume_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	volume_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	volume_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	volume_material.albedo_color = Color(tint.r, tint.g, tint.b, 0.11)
	volume.material_override = volume_material
	volume.position = Vector3(0.0, -size.y * 0.5 + 0.06, 0.0)
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	volume.visible = show_volume
	add_child(volume)

	# Crisp stylized streaks of air racing downwind.
	var streak_speed := 15.0
	var streak_life := 0.48
	var drift := streak_speed * streak_life
	var streaks := CPUParticles3D.new()
	streaks.amount = int(clampf(65.0 * GameSettings.visual_intensity, 12.0, 130.0))
	streaks.lifetime = streak_life
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var extents := size * 0.5 - Vector3(absf(local_dir.x), absf(local_dir.y), absf(local_dir.z)) * drift * 0.5
	streaks.emission_box_extents = Vector3(maxf(extents.x, 0.2), maxf(extents.y, 0.2), maxf(extents.z, 0.2))
	streaks.position = -local_dir * drift * 0.5
	streaks.direction = local_dir
	streaks.spread = 1.2
	streaks.gravity = Vector3.ZERO
	streaks.initial_velocity_min = streak_speed * 0.85
	streaks.initial_velocity_max = streak_speed * 1.2
	streaks.particle_flag_align_y = true
	var streak_mesh := CylinderMesh.new()
	streak_mesh.top_radius = 0.008
	streak_mesh.bottom_radius = 0.036
	streak_mesh.height = 1.8
	streak_mesh.radial_segments = 6
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(0.86, 0.97, 1.0, 0.56)
	streak_mesh.material = streak_material
	streaks.mesh = streak_mesh
	streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streaks)

	# 6 Cover-art curved, undulating aerodynamic sky-blue wind ribbons gliding downwind!
	var ribbon_mesh := _build_wind_ribbon_mesh(4.8, 0.30)
	var ribbon_material := StandardMaterial3D.new()
	ribbon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ribbon_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon_material.albedo_color = Color(0.68, 0.95, 1.0, 0.52)
	ribbon_material.emission_enabled = true
	ribbon_material.emission = Color(0.45, 0.90, 1.0)
	ribbon_material.emission_energy_multiplier = 1.15
	for i in 6:
		var ribbon := MeshInstance3D.new()
		ribbon.mesh = ribbon_mesh
		ribbon.material_override = ribbon_material
		ribbon.basis = facing
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ribbon)
		_arrows.append(ribbon)

	# Windsock on a pole at the upwind corner (chromatic cel striped cartoon sock).
	if show_windsock:
		var pole_height := size.y + 1.0
		var across := local_dir.cross(Vector3.UP)
		if across.length_squared() < 0.01:
			across = Vector3.RIGHT
		across = across.normalized()
		var pole_base := -local_dir * (travel - 0.8) + across * (_extent_along(across) - 0.8) + Vector3.DOWN * size.y * 0.5
		var pole := ArenaKit.deco_cylinder(self, 0.08, pole_height, pole_base + Vector3.UP * pole_height * 0.5, Color(0.92, 0.94, 0.98))
		pole.material_override = ArenaKit.toon_mat(Color(0.92, 0.94, 0.98), 0.30, 0.62, 0.65, false)
		var sock_pivot := Node3D.new()
		sock_pivot.position = pole_base + Vector3.UP * (pole_height - 0.3)
		sock_pivot.basis = facing
		add_child(sock_pivot)
		_sock = Node3D.new()
		sock_pivot.add_child(_sock)
		var sock_o := ArenaKit.toon_mat(Color(1.0, 0.45, 0.08), 0.42, 0.48, 0.65, false)
		var sock_w := ArenaKit.toon_mat(Color(0.98, 0.98, 1.0), 0.42, 0.48, 0.65, false)
		var s0 := ArenaKit.deco_cylinder(_sock, 0.18, 0.72, Vector3(0.0, 0.0, -0.46), Color(1.0, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), 0.36)
		s0.material_override = sock_o
		var s1 := ArenaKit.deco_cylinder(_sock, 0.12, 0.72, Vector3(0.0, 0.0, -1.16), Color(1.0, 1.0, 1.0), Vector3(90.0, 0.0, 0.0), 0.18)
		s1.material_override = sock_w
		var s2 := ArenaKit.deco_cylinder(_sock, 0.06, 0.62, Vector3(0.0, 0.0, -1.82), Color(1.0, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), 0.12)
		s2.material_override = sock_o

	if show_fan:
		_build_fan(facing, -local_dir * (travel - 0.35))


func _build_wind_ribbon_mesh(ribbon_len: float, ribbon_width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 14
	for s in segs:
		var t0 := float(s) / float(segs)
		var t1 := float(s + 1) / float(segs)
		var z0 := (0.5 - t0) * ribbon_len
		var z1 := (0.5 - t1) * ribbon_len
		var x0 := sin(t0 * TAU) * 0.24
		var x1 := sin(t1 * TAU) * 0.24
		var y0 := sin(t0 * PI) * 0.28 + cos(t0 * TAU) * 0.08
		var y1 := sin(t1 * PI) * 0.28 + cos(t1 * TAU) * 0.08
		# Taper to pointed calligraphic tips at head and tail
		var w0 := ribbon_width * sin(t0 * PI)
		var w1 := ribbon_width * sin(t1 * PI)
		var a := Vector3(x0 - w0 * 0.5, y0, z0)
		var b := Vector3(x0 + w0 * 0.5, y0, z0)
		var c := Vector3(x1 + w1 * 0.5, y1, z1)
		var d := Vector3(x1 - w1 * 0.5, y1, z1)
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)
	# Subtle pointed arrowhead flare at the leading tip (-Z)
	var tip := Vector3(0.0, 0.08, -ribbon_len * 0.54)
	var left_w := Vector3(-ribbon_width * 0.85, 0.08, -ribbon_len * 0.38)
	var right_w := Vector3(ribbon_width * 0.85, 0.08, -ribbon_len * 0.38)
	st.add_vertex(tip); st.add_vertex(left_w); st.add_vertex(right_w)
	st.generate_normals()
	return st.commit()


func _build_fan(facing: Basis, at: Vector3) -> void:
	var fan := Node3D.new()
	fan.basis = facing
	fan.position = at
	add_child(fan)
	var radius := minf(size.y * 0.5 - 0.1, 2.4)
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.28
	ring.outer_radius = radius
	ring.rings = 28
	ring.ring_segments = 12
	var housing := ArenaKit.deco(fan, ring, Vector3.ZERO, Color(0.18, 0.26, 0.42), Vector3(90.0, 0.0, 0.0))
	housing.material_override = ArenaKit.toon_mat(Color(0.18, 0.26, 0.42), 0.32, 0.65, 0.85, false)
	var back_plate := ArenaKit.deco_cylinder(fan, radius - 0.1, 0.14, Vector3(0.0, 0.0, 0.25), Color(0.12, 0.17, 0.30), Vector3(90.0, 0.0, 0.0))
	back_plate.material_override = ArenaKit.toon_mat(Color(0.12, 0.17, 0.30), 0.40, 0.45, 0.0, false)
	_fan_blades = Node3D.new()
	fan.add_child(_fan_blades)
	var blade_mat := ArenaKit.toon_mat(Color(1.0, 0.52, 0.08), 0.28, 0.72, 0.75, false)
	for i in 4:
		var blade := ArenaKit.deco_box(_fan_blades, Vector3(0.60, radius - 0.42, 0.08), Vector3.ZERO, Color(1.0, 0.55, 0.1))
		blade.material_override = blade_mat
		blade.rotation_degrees = Vector3(0.0, 18.0, 90.0 * i)
		blade.position = blade.basis * Vector3(0.0, (radius - 0.4) * 0.5 + 0.15, 0.0)
	var hub := ArenaKit.deco_sphere(_fan_blades, 0.38, Vector3.ZERO, Color(1.0, 0.86, 0.18))
	hub.material_override = ArenaKit.toon_mat(Color(1.0, 0.86, 0.18), 0.26, 0.75, 0.75, false)
