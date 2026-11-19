class_name WeatherEffects
extends Node3D
## Manages atmospheric visual effects for weather events: cartoon lightning bolts,
## rain precipitation, snow flurries, gale wind leaves, and heatwave shimmer.

var _active_weather: int = 0
var _particles_rain: CPUParticles3D
var _particles_snow: CPUParticles3D
var _particles_leaves: CPUParticles3D


func _ready() -> void:
	_setup_particles()


func _setup_particles() -> void:
	# Rain particles (falling cyan streaks)
	_particles_rain = _create_weather_particles(
		Color(0.5, 0.8, 1.0, 0.6),
		Vector3(0.06, 0.45, 0.06),
		Vector3(0.0, -22.0, 0.0),
		50
	)
	add_child(_particles_rain)

	# Snow particles (drifting white/soft-blue flakes)
	_particles_snow = _create_weather_particles(
		Color(0.92, 0.96, 1.0, 0.75),
		Vector3(0.12, 0.12, 0.12),
		Vector3(0.0, -3.5, 0.0),
		60
	)
	add_child(_particles_snow)

	# Wind / leaf particles (tumbling green & amber flakes)
	_particles_leaves = _create_weather_particles(
		Color(0.85, 0.75, 0.2, 0.7),
		Vector3(0.15, 0.08, 0.15),
		Vector3(12.0, -2.0, 8.0),
		40
	)
	add_child(_particles_leaves)

	_update_visibility()


func _create_weather_particles(color: Color, particle_size: Vector3, linear_accel: Vector3, count: int) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	var intensity := GameSettings.visual_intensity
	particles.amount = maxi(8, int(count * intensity))
	particles.lifetime = 2.5
	particles.emitting = false

	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(25.0, 6.0, 25.0)
	particles.direction = Vector3.DOWN
	particles.gravity = linear_accel
	particles.color = color

	var mesh_inst := BoxMesh.new()
	mesh_inst.size = particle_size
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


## Spawns an animated vertical lightning bolt striking `strike_pos`.
func flash_lightning(strike_pos: Vector3) -> void:
	var bolt := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.28
	cyl.height = 36.0
	cyl.radial_segments = 8
	bolt.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.98, 0.5, 0.95)
	bolt.material_override = mat

	bolt.position = strike_pos + Vector3.UP * 18.0
	add_child(bolt)

	# Ground burst sparks
	FoamBurst.spawn(self, strike_pos, Color(1.0, 0.95, 0.3), 16, 5.0, Vector3.UP, true)

	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tween.tween_callback(bolt.queue_free)
