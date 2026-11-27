class_name WeatherEffects
extends Node3D
## Manages atmospheric visual effects for weather events: jagged 3D lightning bolts,
## rain precipitation, snow flurries, gale wind leaves, and heatwave shimmer motes.
## Precipitation volumes follow the active camera XZ so large maps stay fully covered.

var _active_weather: int = 0
var _particles_rain: CPUParticles3D
var _particles_snow: CPUParticles3D
var _particles_leaves: CPUParticles3D
var _particles_heat: CPUParticles3D


func _ready() -> void:
	_setup_particles()


func _process(_delta: float) -> void:
	if _active_weather == 0:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var cam := vp.get_camera_3d()
	if cam != null and is_instance_valid(cam):
		var target := Vector3(cam.global_position.x, 12.0, cam.global_position.z)
		for p in [_particles_rain, _particles_snow, _particles_leaves]:
			if p != null:
				p.global_position = target
		if _particles_heat != null:
			_particles_heat.global_position = Vector3(cam.global_position.x, 2.5, cam.global_position.z)


func _setup_particles() -> void:
	# Rain particles (translucent falling cyan streaks)
	_particles_rain = _create_weather_particles(
		Color(0.62, 0.86, 1.0, 0.55),
		Vector3(0.035, 0.58, 0.035),
		Vector3(0.0, -24.0, 0.0),
		95,
		1.8
	)
	add_child(_particles_rain)

	# Snow particles (soft drifting white-cyan flakes)
	_particles_snow = _create_weather_particles(
		Color(0.95, 0.98, 1.0, 0.82),
		Vector3(0.10, 0.10, 0.10),
		Vector3(0.8, -3.2, 0.4),
		100,
		3.2
	)
	add_child(_particles_snow)

	# Wind / leaf particles (tumbling autumn & emerald leaves)
	_particles_leaves = _create_weather_particles(
		Color(0.92, 0.72, 0.18, 0.85),
		Vector3(0.18, 0.04, 0.12),
		Vector3(14.0, -2.0, 8.0),
		65,
		2.8
	)
	_particles_leaves.angular_velocity_min = -260.0
	_particles_leaves.angular_velocity_max = 260.0
	add_child(_particles_leaves)

	# Heatwave shimmer motes (rising warm golden-orange sparks & heat dust)
	_particles_heat = _create_weather_particles(
		Color(1.0, 0.72, 0.25, 0.58),
		Vector3(0.07, 0.07, 0.07),
		Vector3(0.0, 2.4, 0.0),
		65,
		2.4
	)
	_particles_heat.position.y = 2.5
	_particles_heat.emission_box_extents = Vector3(24.0, 2.5, 24.0)
	_particles_heat.direction = Vector3.UP
	add_child(_particles_heat)

	_update_visibility()


func _create_weather_particles(color: Color, particle_size: Vector3, linear_accel: Vector3,
		count: int, p_lifetime: float = 2.5) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	var intensity := clampf(GameSettings.visual_intensity, 0.3, 1.5)
	particles.amount = maxi(12, int(round(float(count) * intensity)))
	particles.lifetime = p_lifetime
	particles.emitting = false
	particles.local_coords = false

	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(26.0, 6.0, 26.0)
	particles.direction = Vector3.DOWN
	particles.gravity = linear_accel
	particles.color = color

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_inst := BoxMesh.new()
	mesh_inst.size = particle_size
	mesh_inst.material = mat
	particles.mesh = mesh_inst
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	particles.position.y = 12.0
	return particles


func set_weather(weather: int) -> void:
	_active_weather = weather
	_update_visibility()


func _update_visibility() -> void:
	if _particles_rain != null:
		_particles_rain.emitting = (_active_weather == 1)  # THUNDERSTORM
	if _particles_snow != null:
		_particles_snow.emitting = (_active_weather == 2)  # BLIZZARD
	if _particles_leaves != null:
		_particles_leaves.emitting = (_active_weather == 3)  # GALE_GUSTS
	if _particles_heat != null:
		_particles_heat.emitting = (_active_weather == 4)  # HEATWAVE


## Spawns a dramatic jagged 3D lightning bolt + shockwave ring + sparks at `strike_pos`.
func flash_lightning(strike_pos: Vector3) -> void:
	var sky_top := strike_pos + Vector3(randf_range(-2.5, 2.5), 36.0, randf_range(-2.5, 2.5))
	CombatFx.spawn_lightning_arc(self, sky_top, strike_pos, Color(1.0, 0.98, 0.55), 0.30, 0.16)
	# Secondary side fork branch
	var fork_mid := sky_top.lerp(strike_pos, 0.45)
	var fork_end := fork_mid + Vector3(randf_range(-4.5, 4.5), -10.0, randf_range(-4.5, 4.5))
	CombatFx.spawn_lightning_arc(self, fork_mid, fork_end, Color(0.75, 0.94, 1.0), 0.22, 0.08)
	CombatFx.spawn_blast_wave(self, strike_pos, Color(1.0, 0.95, 0.35), 4.4)
	FoamBurst.spawn(self, strike_pos, Color(1.0, 0.95, 0.3), 18, 5.5, Vector3.UP, true)
