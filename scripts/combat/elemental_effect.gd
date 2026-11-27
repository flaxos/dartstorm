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
	if wind_lift_left > 0.0:
		status_ended.emit(DartData.Element.WIND)
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
		if _last_attacker != null and _last_attacker.is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"extinguish", 1)

	var radius := dart.data.chain_radius
	if elem == DartData.Element.LIGHTNING and wet_left > 0.0:
		combo_triggered.emit(&"conductive_shock", hit_point)
		# Wet targets take extra tag power and extend chain radius.
		actor.tag_meter = minf(actor.tag_meter + 15.0, actor.tag_meter_max)
		actor.meter_changed.emit(actor.tag_meter, actor.tag_meter_max)
		radius *= 1.5
		if actor.tag_meter >= actor.tag_meter_max and actor.alive and not actor.is_tagged_out:
			var att := _last_attacker if is_instance_valid(_last_attacker) else null
			actor._tag_out(att, _last_weapon, dart.ricochet_count > 0)
			if att != null:
				att.landed_hit.emit(actor, true, dart.ricochet_count > 0)

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
			if actor.alive and not actor.is_tagged_out:
				sparkle_left = dur
				_sparkle_tick_timer = SPARKLE_INTERVAL
				status_started.emit(DartData.Element.FIRE, dur)

		DartData.Element.WATER:
			if actor.alive and not actor.is_tagged_out:
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
			if actor.alive and not actor.is_tagged_out:
				frost_left = dur
				status_started.emit(DartData.Element.ICE, dur)


func _perform_chain_zap(dart: DartProjectile, radius: float) -> void:
	if actor == null:
		return
	var tree := actor.get_tree()
	if tree == null:
		return

	var valid_shooter: Actor = dart.shooter if is_instance_valid(dart.shooter) else null
	var candidates: Array[Actor] = []
	for node in tree.get_nodes_in_group(&"actors"):
		var other := node as Actor
		if other == null or other == actor or not other.alive or other.is_tagged_out or other.is_protected():
			continue
		if other.accepts_dart_from(dart.team_id):
			var dist := actor.global_position.distance_to(other.global_position)
			if dist <= radius:
				candidates.append(other)

	candidates.sort_custom(func(a: Actor, b: Actor) -> bool:
		return actor.global_position.distance_to(a.global_position) < actor.global_position.distance_to(b.global_position)
	)

	var targets := candidates.slice(0, dart.data.chain_count)
	if not targets.is_empty() and valid_shooter != null and valid_shooter.is_local_human():
		var prog: Node = get_node_or_null("/root/Progression")
		if prog != null:
			prog.call("notify_event", &"chain_zap", targets.size())
	var valid_attacker: Actor = _last_attacker if is_instance_valid(_last_attacker) else valid_shooter
	for target in targets:
		chain_zapped.emit(actor, target)
		var zap_power := maxf(dart.data.element_power, 12.0)
		if target.shield_points > 0.0:
			if zap_power <= target.shield_points:
				target.shield_points -= zap_power
				target.shield_changed.emit(target.shield_points, Actor.SHIELD_MAX)
				target._since_hit = 0.0
				target._on_hit_received(valid_attacker)
				if valid_attacker != null:
					valid_attacker.landed_hit.emit(target, false, false)
				continue
			else:
				zap_power -= target.shield_points
				target.shield_points = 0.0
				target.shield_changed.emit(0.0, Actor.SHIELD_MAX)
				target.shield_broken.emit(target)
		target.tag_meter = minf(target.tag_meter + zap_power, target.tag_meter_max)
		target._since_hit = 0.0
		target.meter_changed.emit(target.tag_meter, target.tag_meter_max)
		target._on_hit_received(valid_attacker)
		if target.elemental != null:
			target.elemental.apply_lightning_jolt()
		var out: bool = target.tag_meter >= target.tag_meter_max
		if out:
			target._tag_out(valid_attacker, _last_weapon, false)
		if valid_attacker != null:
			valid_attacker.landed_hit.emit(target, out, false)


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
			if not actor.is_tagged_out and not actor.is_protected():
				var valid_att: Actor = _last_attacker if is_instance_valid(_last_attacker) else null
				var dmg := SPARKLE_TICK_POWER
				if actor.shield_points > 0.0:
					if dmg <= actor.shield_points:
						actor.shield_points -= dmg
						actor.shield_changed.emit(actor.shield_points, Actor.SHIELD_MAX)
						dmg = 0.0
					else:
						dmg -= actor.shield_points
						actor.shield_points = 0.0
						actor.shield_changed.emit(0.0, Actor.SHIELD_MAX)
						actor.shield_broken.emit(actor)
				if dmg > 0.0:
					actor.tag_meter = minf(actor.tag_meter + dmg, actor.tag_meter_max)
					actor.meter_changed.emit(actor.tag_meter, actor.tag_meter_max)
					if actor.tag_meter >= actor.tag_meter_max:
						sparkle_left = 0.0
						actor._tag_out(valid_att, _last_weapon, false)
						if valid_att != null:
							valid_att.landed_hit.emit(actor, true, false)
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
		if wind_lift_left <= 0.0:
			status_ended.emit(DartData.Element.WIND)

	if sliding_left > 0.0:
		sliding_left -= delta
