class_name LavaDirector
extends Node
## Controls the dynamic rising and falling tides of molten foam lava in Floor is Lava mode.
## Coordinates sirens, warning countdowns, height interpolation, and survival bonuses.

signal phase_changed(new_phase: int, duration: float)
signal warning_tick(seconds_left: int)
signal high_tide_survived(cycle_count: int)
signal lava_height_updated(new_y: float)

enum Phase { CALM, WARNING, RISING, HIGH_TIDE, RECEDING }

const CALM_DURATION := 24.0
const WARNING_DURATION := 5.0
const RISING_DURATION := 4.0
const HIGH_TIDE_DURATION := 20.0
const RECEDING_DURATION := 4.0

const CALM_HEIGHT := -0.6
const PEAK_HEIGHT := 1.35

var phase: Phase = Phase.CALM
var time_left: float = CALM_DURATION
var current_height: float = CALM_HEIGHT
var cycle_count: int = 0

var hazard: LavaHazard
var controller: MatchController
var _last_whole_warning: int = -1


func setup(p_hazard: LavaHazard, p_controller: MatchController) -> void:
	hazard = p_hazard
	controller = p_controller
	current_height = CALM_HEIGHT
	if hazard != null:
		hazard.set_lava_height(current_height)


func start() -> void:
	cycle_count = 0
	_set_phase(Phase.CALM)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	match phase:
		Phase.CALM:
			time_left = CALM_DURATION
			current_height = CALM_HEIGHT
			if hazard != null:
				hazard.set_lava_height(current_height)
			if controller != null and cycle_count > 0:
				controller.announce(null, "FLOOR SAFE!", UiKit.LIME, &"go")
		Phase.WARNING:
			time_left = WARNING_DURATION
			_last_whole_warning = -1
			Sfx.play(&"siren")
			if controller != null:
				controller.announce(null, "WARNING: LAVA RISING!", UiKit.ORANGE_HOT, &"announce")
		Phase.RISING:
			time_left = RISING_DURATION
			Sfx.play(&"whoosh", 0.8)
		Phase.HIGH_TIDE:
			time_left = HIGH_TIDE_DURATION
			current_height = PEAK_HEIGHT
			if hazard != null:
				hazard.set_lava_height(current_height)
			cycle_count += 1
			if controller != null:
				controller.announce(null, "HIGH TIDE — STAY HIGH!", UiKit.ORANGE_HOT, &"announce")
		Phase.RECEDING:
			time_left = RECEDING_DURATION
			Sfx.play(&"steam", 1.0, 0.0)
			if controller != null:
				controller.announce(null, "LAVA RECEDING!", UiKit.SKY, &"announce")
			high_tide_survived.emit(cycle_count)

	phase_changed.emit(int(phase), time_left)


func _process(delta: float) -> void:
	time_left -= delta

	match phase:
		Phase.CALM:
			if time_left <= 0.0:
				_set_phase(Phase.WARNING)

		Phase.WARNING:
			var sec := int(ceilf(time_left))
			if sec != _last_whole_warning and sec > 0:
				_last_whole_warning = sec
				warning_tick.emit(sec)
				Sfx.play(&"beep", 1.2, -4.0)
			if time_left <= 0.0:
				_set_phase(Phase.RISING)

		Phase.RISING:
			var progress := 1.0 - clampf(time_left / RISING_DURATION, 0.0, 1.0)
			current_height = lerpf(CALM_HEIGHT, PEAK_HEIGHT, progress)
			if hazard != null:
				hazard.set_lava_height(current_height)
			lava_height_updated.emit(current_height)
			if time_left <= 0.0:
				_set_phase(Phase.HIGH_TIDE)

		Phase.HIGH_TIDE:
			if time_left <= 0.0:
				_set_phase(Phase.RECEDING)

		Phase.RECEDING:
			var progress := 1.0 - clampf(time_left / RECEDING_DURATION, 0.0, 1.0)
			current_height = lerpf(PEAK_HEIGHT, CALM_HEIGHT, progress)
			if hazard != null:
				hazard.set_lava_height(current_height)
			lava_height_updated.emit(current_height)
			if time_left <= 0.0:
				_set_phase(Phase.CALM)
