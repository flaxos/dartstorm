class_name WeatherDirector
extends Node
## Orchestrates dynamic elemental weather events across matches:
## Thunderstorms with lightning strikes electrifying water puddles,
## Flash-Freeze Blizzards spawning dynamic temporary ice slicks,
## Gale Gusts spinning high-velocity wind fields and roving whirlwinds,
## and Heatwaves melting ice and boiling puddles into steam.

signal weather_changed(new_weather: Weather, duration: float)
signal forecast_warning(weather: Weather, seconds_left: int)
signal lightning_struck(position: Vector3)

enum Weather {
	CALM = 0,
	THUNDERSTORM = 1,
	BLIZZARD = 2,
	GALE_GUSTS = 3,
	HEATWAVE = 4,
}

const CALM_DURATION := 28.0
const WARNING_DURATION := 5.0
const EVENT_DURATION := 20.0

var current_weather: Weather = Weather.CALM
var next_weather: Weather = Weather.CALM
var is_warning: bool = false
var time_left: float = CALM_DURATION
var cycle_count: int = 0

var arena: Arena
var controller: MatchController
var effects: WeatherEffects

var _temporary_ice_slicks: Array[IceSlick] = []
var _active_whirlwind: WhirlwindVortex = null
var _strike_cooldown: float = 0.0
var _last_warning_second: int = -1
var _original_global_wind: Vector3 = Vector3.ZERO
var _base_env_saved: bool = false
var _base_sky_top: Color = Color.WHITE
var _base_sky_horizon: Color = Color.WHITE
var _base_sun_energy: float = 1.0
var _base_sun_color: Color = Color.WHITE
var _base_fog_density: float = 0.003
var _base_fog_albedo: Color = Color.WHITE
var _env_tween: Tween = null
var _time: float = 0.0
var _weather_order: Array[Weather] = [
	Weather.THUNDERSTORM,
	Weather.BLIZZARD,
	Weather.GALE_GUSTS,
	Weather.HEATWAVE,
]
var _order_index: int = 0


func setup(p_arena: Arena, p_controller: MatchController) -> void:
	arena = p_arena
	controller = p_controller
	if arena != null and arena.wind_field != null:
		_original_global_wind = arena.wind_field.global_wind
	_capture_base_atmosphere()

	effects = WeatherEffects.new()
	effects.name = "WeatherEffects"
	add_child(effects)


func _capture_base_atmosphere() -> void:
	if _base_env_saved or arena == null:
		return
	if arena.world_environment != null and arena.world_environment.environment != null:
		var env := arena.world_environment.environment
		if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
			var sm := env.sky.sky_material as ProceduralSkyMaterial
			_base_sky_top = sm.sky_top_color
			_base_sky_horizon = sm.sky_horizon_color
		_base_fog_density = env.volumetric_fog_density
		_base_fog_albedo = env.volumetric_fog_albedo
		_base_env_saved = true
	if arena.sun_light != null:
		_base_sun_energy = arena.sun_light.light_energy
		_base_sun_color = arena.sun_light.light_color


func _morph_atmosphere(weather: Weather) -> void:
	if not _base_env_saved or arena == null:
		return
	var env: Environment = arena.world_environment.environment if arena.world_environment != null else null
	var sm: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial if (env != null and env.sky != null and env.sky.sky_material is ProceduralSkyMaterial) else null
	var sun: DirectionalLight3D = arena.sun_light
	if env == null and sun == null:
		return

	var target_top := _base_sky_top
	var target_hor := _base_sky_horizon
	var target_sun_e := _base_sun_energy
	var target_sun_c := _base_sun_color
	var target_fog_d := _base_fog_density
	var target_fog_a := _base_fog_albedo

	match weather:
		Weather.THUNDERSTORM:
			target_top = Color(0.10, 0.14, 0.24)
			target_hor = Color(0.28, 0.34, 0.44)
			target_sun_e = _base_sun_energy * 0.48
			target_sun_c = Color(0.75, 0.84, 1.0)
			target_fog_d = maxf(_base_fog_density * 2.2, 0.008)
			target_fog_a = Color(0.45, 0.52, 0.64)
		Weather.BLIZZARD:
			target_top = Color(0.42, 0.58, 0.78)
			target_hor = Color(0.80, 0.90, 0.98)
			target_sun_e = _base_sun_energy * 0.78
			target_sun_c = Color(0.86, 0.94, 1.0)
			target_fog_d = maxf(_base_fog_density * 2.5, 0.009)
			target_fog_a = Color(0.86, 0.93, 1.0)
		Weather.GALE_GUSTS:
			target_top = _base_sky_top.lerp(Color(0.24, 0.46, 0.62), 0.45)
			target_hor = _base_sky_horizon.lerp(Color(0.84, 0.86, 0.76), 0.45)
			target_sun_e = _base_sun_energy * 0.92
			target_fog_d = maxf(_base_fog_density * 1.5, 0.0055)
		Weather.HEATWAVE:
			target_top = _base_sky_top.lerp(Color(0.28, 0.34, 0.72), 0.3)
			target_hor = Color(1.0, 0.66, 0.36)
			target_sun_e = _base_sun_energy * 1.28
			target_sun_c = Color(1.0, 0.82, 0.56)
			target_fog_d = maxf(_base_fog_density * 1.8, 0.0065)
			target_fog_a = Color(1.0, 0.78, 0.52)

	if _env_tween != null and _env_tween.is_valid():
		_env_tween.kill()
	_env_tween = create_tween()
	_env_tween.set_parallel(true)
	if sm != null:
		_env_tween.tween_property(sm, "sky_top_color", target_top, 2.2)
		_env_tween.tween_property(sm, "sky_horizon_color", target_hor, 2.2)
	if sun != null:
		_env_tween.tween_property(sun, "light_energy", target_sun_e, 2.2)
		_env_tween.tween_property(sun, "light_color", target_sun_c, 2.2)
	if env != null:
		_env_tween.tween_property(env, "volumetric_fog_density", target_fog_d, 2.2)
		_env_tween.tween_property(env, "volumetric_fog_albedo", target_fog_a, 2.2)


func start() -> void:
	cycle_count = 0
	_order_index = 0
	_weather_order.shuffle()
	_set_weather(Weather.CALM)
	time_left = CALM_DURATION


func _pick_next_weather() -> Weather:
	var picked: Weather = _weather_order[_order_index % _weather_order.size()]
	_order_index += 1
	return picked


func _set_weather(weather: Weather) -> void:
	current_weather = weather
	time_left = EVENT_DURATION if current_weather != Weather.CALM else CALM_DURATION
	is_warning = false

	if effects != null:
		effects.set_weather(int(current_weather))
	_morph_atmosphere(current_weather)

	match current_weather:
		Weather.CALM:
			_cleanup_weather_hazards()
			if arena != null and arena.wind_field != null:
				arena.wind_field.global_wind = _original_global_wind
			if controller != null and cycle_count > 0:
				controller.announce(null, "WEATHER CALM", UiKit.LIME, &"go")

		Weather.THUNDERSTORM:
			cycle_count += 1
			_strike_cooldown = 1.8
			Sfx.play(&"thunder")
			if controller != null:
				controller.announce(null, "THUNDERSTORM! WATCH OUT FOR LIGHTNING!", UiKit.ORANGE_HOT, &"announce")

		Weather.BLIZZARD:
			cycle_count += 1
			Sfx.play(&"blizzard_wind")
			_spawn_blizzard_ice_slicks()
			if controller != null:
				controller.announce(null, "BLIZZARD! ICY GROUNDS AHEAD!", UiKit.SKY, &"announce")

		Weather.GALE_GUSTS:
			cycle_count += 1
			Sfx.play(&"tornado_whirl")
			_spawn_whirlwind()
			if controller != null:
				controller.announce(null, "GALE GUSTS! WILD WINDS!", UiKit.LIME, &"announce")

		Weather.HEATWAVE:
			cycle_count += 1
			Sfx.play(&"steam", 1.0, 0.0)
			_trigger_heatwave_melts()
			if controller != null:
				controller.announce(null, "HEATWAVE! MELTING ICE & STEAM!", UiKit.ORANGE, &"announce")

	weather_changed.emit(current_weather, time_left)


func _process(delta: float) -> void:
	if controller != null and controller.state != MatchController.State.PLAYING:
		return
	_time += delta
	time_left -= delta

	if is_warning:
		var sec := maxi(0, int(ceilf(time_left)))
		if sec != _last_warning_second and sec > 0:
			_last_warning_second = sec
			forecast_warning.emit(next_weather, sec)
			Sfx.play(&"beep", 1.3, -4.0)

		if time_left <= 0.0:
			_set_weather(next_weather)
		return

	if current_weather == Weather.CALM:
		if time_left <= 0.0:
			is_warning = true
			time_left = WARNING_DURATION
			_last_warning_second = -1
			next_weather = _pick_next_weather()
			Sfx.play(&"siren")
			if controller != null:
				var weather_title := get_weather_title(next_weather)
				controller.announce(null, "WARNING: %s INCOMING!" % weather_title, UiKit.ORANGE_HOT, &"announce")
		return

	# Handle active weather processes
	match current_weather:
		Weather.THUNDERSTORM:
			_strike_cooldown -= delta
			if _strike_cooldown <= 0.0:
				_strike_cooldown = randf_range(3.5, 5.5)
				trigger_lightning_strike()

		Weather.GALE_GUSTS:
			if arena != null and arena.wind_field != null:
				# Rotating 26 m/s gale wind
				var angle := _time * 0.65
				arena.wind_field.global_wind = Vector3(cos(angle) * 26.0, 0.0, sin(angle) * 26.0)

	if time_left <= 0.0:
		_set_weather(Weather.CALM)


func trigger_lightning_strike(custom_target: Vector3 = Vector3.ZERO) -> Vector3:
	var strike_pos := custom_target
	if strike_pos == Vector3.ZERO and arena != null:
		# Prefer striking near a puddle or random roam point
		if not arena.puddles.is_empty() and randf() < 0.6:
			var p := arena.puddles[randi() % arena.puddles.size()]
			strike_pos = p.global_position + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		elif not arena.roam_points.is_empty():
			strike_pos = arena.roam_points[randi() % arena.roam_points.size()]
		else:
			strike_pos = Vector3(randf_range(-12.0, 12.0), 0.0, randf_range(-12.0, 12.0))

	if effects != null:
		effects.flash_lightning(strike_pos)

	Sfx.play_at(&"lightning_strike", strike_pos, 1.0, 1.0)
	lightning_struck.emit(strike_pos)

	# 1. Electrify any puddles in radius
	if arena != null:
		for puddle in arena.puddles:
			if is_instance_valid(puddle) and strike_pos.distance_to(puddle.global_position) <= (puddle.radius + 3.0):
				puddle.electrify(4.0)

	# 2. Blast damage to nearby actors
	var actors := get_tree().get_nodes_in_group(&"actors")
	for node in actors:
		var actor := node as Actor
		if actor != null and is_instance_valid(actor) and actor.alive and not actor.is_tagged_out:
			var d := strike_pos.distance_to(actor.global_position)
			if d <= 4.0:
				actor.apply_blast_tag(35.0, null)
				var push := (actor.global_position - strike_pos).normalized()
				push.y = 0.5
				actor.velocity += push * 8.0

	return strike_pos


func _spawn_blizzard_ice_slicks() -> void:
	if arena == null:
		return
	_cleanup_weather_hazards()

	var spots: Array[Vector3] = []
	if not arena.roam_points.is_empty():
		for pt in arena.roam_points:
			if absf(pt.y) < 1.0:  # Outdoor ground level
				spots.append(pt)

	if spots.size() >= 2:
		spots.shuffle()
		for i in mini(3, spots.size()):
			var slick := IceSlick.new()
			slick.size = Vector3(3.5, 0.15, 3.5)
			slick.boost_speed = 10.5
			var angle := randf() * TAU
			slick.slide_direction = Vector3(cos(angle), 0.0, sin(angle))
			slick.position = spots[i]
			arena.add_child(slick)
			_temporary_ice_slicks.append(slick)


func _spawn_whirlwind() -> void:
	if arena == null:
		return
	if _active_whirlwind != null and is_instance_valid(_active_whirlwind):
		_active_whirlwind.queue_free()

	_active_whirlwind = WhirlwindVortex.new()
	var spawn_pos := Vector3.ZERO
	if not arena.roam_points.is_empty():
		spawn_pos = arena.roam_points[0]
		_active_whirlwind.target_roam_points = arena.roam_points.duplicate()
	_active_whirlwind.position = spawn_pos
	arena.add_child(_active_whirlwind)


func _trigger_heatwave_melts() -> void:
	if arena == null:
		return
	for slick in arena.ice_slicks:
		if is_instance_valid(slick):
			slick.melt(8.0)
	for puddle in arena.puddles:
		if is_instance_valid(puddle):
			Sfx.play_at(&"steam", puddle.global_position, 1.1, -2.0)


func _cleanup_weather_hazards() -> void:
	for slick in _temporary_ice_slicks:
		if is_instance_valid(slick):
			slick.queue_free()
	_temporary_ice_slicks.clear()

	if _active_whirlwind != null and is_instance_valid(_active_whirlwind):
		_active_whirlwind.queue_free()
		_active_whirlwind = null


func get_weather_title(weather: Weather = current_weather) -> String:
	match weather:
		Weather.THUNDERSTORM: return "THUNDERSTORM"
		Weather.BLIZZARD: return "BLIZZARD"
		Weather.GALE_GUSTS: return "GALE GUSTS"
		Weather.HEATWAVE: return "HEATWAVE"
	return "CALM"


func get_weather_icon(weather: Weather = current_weather) -> String:
	match weather:
		Weather.THUNDERSTORM: return "STORM"
		Weather.BLIZZARD: return "SNOW"
		Weather.GALE_GUSTS: return "GALE"
		Weather.HEATWAVE: return "HEAT"
	return "CLEAR"
