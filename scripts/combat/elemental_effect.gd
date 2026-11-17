class_name ElementalEffect
extends Node
## Manages elemental afflictions, combos, and status on an Actor.
## DARTSTORM is kid-safe cartoon tagging: Fire sparkles, Water splashes,
## Lightning zaps and chains, Ice cools down and slides, Wind lifts.

signal status_started(element: DartData.Element, duration: float)
signal status_ended(element: DartData.Element)
signal combo_triggered(combo_name: StringName, at: Vector3)
signal chain_zapped(from_actor: Actor, to_actor: Actor)

const SPARKLE_INTERVAL := 0.4
const SPARKLE_TICK_POWER := 3.0

var actor: Actor
var sparkle_left: float = 0.0
var frost_left: float = 0.0
var wet_left: float = 0.0
var wind_lift_left: float = 0.0
var sliding_left: float = 0.0

var _sparkle_tick_timer: float = 0.0
var _last_attacker: Actor
var _last_weapon: WeaponData


func _ready() -> void:
	if actor == null and get_parent() is Actor:
		actor = get_parent() as Actor


func clear_all() -> void:
	if sparkle_left > 0.0:
		status_ended.emit(DartData.Element.FIRE)
	if frost_left > 0.0:
		status_ended.emit(DartData.Element.ICE)
	if wet_left > 0.0:
		status_ended.emit(DartData.Element.WATER)
	sparkle_left = 0.0
	frost_left = 0.0
	wet_left = 0.0
	wind_lift_left = 0.0
	sliding_left = 0.0
	_last_attacker = null
	_last_weapon = null


func get_speed_multiplier() -> float:
	if frost_left > 0.0:
		return 0.7
	if sliding_left > 0.0:
		return 1.45
	return 1.0


func is_sliding() -> bool:
	return sliding_left > 0.0


func start_slide(duration: float = 1.5) -> void:
	sliding_left = maxf(sliding_left, duration)


func has_status(elem: DartData.Element) -> bool:
	match elem:
		DartData.Element.FIRE:
			return sparkle_left > 0.0
		DartData.Element.ICE:
			return frost_left > 0.0
		DartData.Element.WATER:
			return wet_left > 0.0
		DartData.Element.WIND:
			return wind_lift_left > 0.0
		_:
			return false


## Applies the elemental payload of an incoming dart.
func apply_dart(dart: DartProjectile, hit_point: Vector3) -> void:
	if dart == null or dart.data == null or actor == null or not actor.alive:
		return
	var elem := dart.data.element
	if elem == DartData.Element.NONE:
		return

	_last_attacker = dart.shooter if is_instance_valid(dart.shooter) else null
	_last_weapon = dart.weapon
	var dur := maxf(dart.data.element_duration, 0.5)

	# --- Elemental Reactions / Combos ---
	if elem == DartData.Element.FIRE and wet_left > 0.0:
		wet_left = 0.0
		combo_triggered.emit(&"steam", hit_point)
		status_ended.emit(DartData.Element.WATER)
		return

	if elem == DartData.Element.ICE and sparkle_left > 0.0:
		sparkle_left = 0.0
		combo_triggered.emit(&"flash_steam", hit_point)
		status_ended.emit(DartData.Element.FIRE)
		return

	if elem == DartData.Element.WATER and sparkle_left > 0.0:
		sparkle_left = 0.0
		combo_triggered.emit(&"extinguish", hit_point)
		status_ended.emit(DartData.Element.FIRE)

	var radius := dart.data.chain_radius
	if elem == DartData.Element.LIGHTNING and wet_left > 0.0:
		combo_triggered.emit(&"conductive_shock", hit_point)
		# Wet targets take extra tag power and extend chain radius.
		actor.tag_meter = minf(actor.tag_meter + 15.0, actor.tag_meter_max)
		actor.meter_changed.emit(actor.tag_meter, actor.tag_meter_max)
		radius *= 1.5

	# --- Primary Elemental Mechanics ---
	match elem:
		DartData.Element.WIND:
			wind_lift_left = 0.4
			actor.velocity.y = maxf(actor.velocity.y, 4.2)
			if dart.data.knockback_impulse > 0.0:
				var push := dart.velocity.normalized() * dart.data.knockback_impulse
				actor.velocity += Vector3(push.x, 0.0, push.z)
			status_started.emit(DartData.Element.WIND, wind_lift_left)

		DartData.Element.FIRE:
			sparkle_left = dur
			_sparkle_tick_timer = SPARKLE_INTERVAL
			status_started.emit(DartData.Element.FIRE, dur)

		DartData.Element.WATER:
			wet_left = dur
			var impulse := dart.data.knockback_impulse if dart.data.knockback_impulse > 0.0 else 5.5
			var push := dart.velocity.normalized() * impulse
			actor.velocity += Vector3(push.x, 1.2, push.z)
			status_started.emit(DartData.Element.WATER, dur)

		DartData.Element.LIGHTNING:
			status_started.emit(DartData.Element.LIGHTNING, 0.3)
			if dart.data.chain_count > 0:
				_perform_chain_zap(dart, radius)

		DartData.Element.ICE:
			frost_left = dur
			status_started.emit(DartData.Element.ICE, dur)


func _perform_chain_zap(dart: DartProjectile, radius: float) -> void:
	if actor == null:
		return
	var tree := actor.get_tree()
	if tree == null:
		return

	var candidates: Array[Actor] = []
	for node in tree.get_nodes_in_group(&"actors"):
		var other := node as Actor
		if other == null or other == actor or not other.alive:
			continue
		if other.accepts_dart_from(dart.team_id):
			var dist := actor.global_position.distance_to(other.global_position)
			if dist <= radius:
				candidates.append(other)

	candidates.sort_custom(func(a: Actor, b: Actor) -> bool:
		return actor.global_position.distance_to(a.global_position) < actor.global_position.distance_to(b.global_position)
	)

	var targets := candidates.slice(0, dart.data.chain_count)
	for target in targets:
		chain_zapped.emit(actor, target)
		var zap_power := maxf(dart.data.element_power, 12.0)
		target.tag_meter = minf(target.tag_meter + zap_power, target.tag_meter_max)
		target.meter_changed.emit(target.tag_meter, target.tag_meter_max)
		if target.elemental != null:
			target.elemental.apply_lightning_jolt()
		if target.tag_meter >= target.tag_meter_max:
			target._tag_out(_last_attacker, _last_weapon, false)


func apply_lightning_jolt() -> void:
	status_started.emit(DartData.Element.LIGHTNING, 0.3)
	if actor != null:
		actor.velocity += Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5))


func _physics_process(delta: float) -> void:
	if actor == null or not actor.alive:
		clear_all()
		return

	if sparkle_left > 0.0:
		sparkle_left -= delta
		_sparkle_tick_timer -= delta
		actor._since_hit = 0.0
		if _sparkle_tick_timer <= 0.0:
			_sparkle_tick_timer = SPARKLE_INTERVAL
			actor.tag_meter = minf(actor.tag_meter + SPARKLE_TICK_POWER, actor.tag_meter_max)
			actor.meter_changed.emit(actor.tag_meter, actor.tag_meter_max)
			if actor.tag_meter >= actor.tag_meter_max:
				sparkle_left = 0.0
				actor._tag_out(_last_attacker, _last_weapon, false)
		if sparkle_left <= 0.0:
			status_ended.emit(DartData.Element.FIRE)

	if frost_left > 0.0:
		frost_left -= delta
		if frost_left <= 0.0:
			status_ended.emit(DartData.Element.ICE)

	if wet_left > 0.0:
		wet_left -= delta
		if wet_left <= 0.0:
			status_ended.emit(DartData.Element.WATER)

	if wind_lift_left > 0.0:
		wind_lift_left -= delta

	if sliding_left > 0.0:
		sliding_left -= delta
