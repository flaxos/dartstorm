class_name Bot
extends Actor
## A friendly computer opponent. Deliberately simple:
##   ROAM      wander between interesting spots using the navmesh
##   FIGHT     keep a comfortable range from a visible rival, strafe and shoot
##   RESUPPLY  run to the nearest stocked ammo bucket when nearly out of darts
## Bots lead moving targets and aim up to allow for dart drop, but they do NOT
## account for wind, so a clever player can use wind zones against them.

enum Mood { ROAM, FIGHT, RESUPPLY }

const EYE_HEIGHT := 1.5
const THINK_INTERVAL := 0.25
const LOW_AMMO := 15
const GRUDGE_SECONDS := 4.0
const WEAPON_LOCK_SECONDS := 2.5
const GOAL_REACHED_DISTANCE := 2.0
const GOAL_TIMEOUT := 14.0

var difficulty: BotDifficulty
var arena: Arena
## Everyone else in the match. Set by the match scene.
var rivals: Array[Actor] = []

var _nav: NavigationAgent3D
var _model: CharacterModel
var _mood: Mood = Mood.ROAM
var _target: Actor
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
var _goal_age: float = 0.0
var _bucket: AmmoBucket
var _think_left: float = 0.0
var _aim: Vector3 = Vector3.FORWARD
var _on_target: bool = false
var _seen_for: float = 0.0
var _trigger_clock: float = 0.0
var _strafe_sign: float = 1.0
var _strafe_left: float = 0.0
var _stuck_for: float = 0.0
var _grudge: Actor
var _grudge_left: float = 0.0
var _weapon_lock_left: float = 0.0
var _sight_query: PhysicsRayQueryParameters3D


func _ready() -> void:
	hitbox_radius = 0.6
	super._ready()
	if difficulty == null:
		difficulty = BotDifficulty.new()
	damage_scale = difficulty.damage_scale

	_nav = NavigationAgent3D.new()
	_nav.path_desired_distance = 0.8
	_nav.target_desired_distance = 1.2
	_nav.radius = 0.5
	_nav.height = BODY_HEIGHT
	add_child(_nav)

	_model = CharacterModel.new()
	_model.name = "Model"
	add_child(_model)
	_model.setup(display_name, color)

	_sight_query = PhysicsRayQueryParameters3D.new()
	_sight_query.collision_mask = Layers.WORLD
	_think_left = randf() * THINK_INTERVAL
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0

	arsenal.weapon_changed.connect(_on_weapon_changed)
	meter_changed.connect(func(value: float, maximum: float) -> void: _model.set_meter(value / maximum))


func _physics_process(delta: float) -> void:
	tick_status(delta)
	if not alive:
		return
	_goal_age += delta
	_grudge_left = maxf(_grudge_left - delta, 0.0)
	_weapon_lock_left = maxf(_weapon_lock_left - delta, 0.0)

	var wish := Vector3.ZERO
	var jump := false
	if controls_enabled:
		_think_left -= delta
		if _think_left <= 0.0:
			_think_left = THINK_INTERVAL + randf() * 0.1
			_think()
		_update_aim(delta)
		_update_trigger(delta)
		wish = _choose_direction(delta)
		# Unstick: hop, and if that fails pick somewhere else to go.
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		if wish.length_squared() > 0.25 and horizontal_speed < 1.0:
			_stuck_for += delta
			if _stuck_for > 0.5 and is_on_floor():
				jump = true
				_strafe_sign = -_strafe_sign
			if _stuck_for > 2.0:
				_stuck_for = 0.0
				_has_goal = false
		else:
			_stuck_for = 0.0
	else:
		arsenal.set_trigger(false)

	move_actor(wish * difficulty.move_speed_scale, false, jump, delta)
	_model.animate(Vector2(velocity.x, velocity.z).length(), delta)
	var held := _model.get_weapon()
	if held != null:
		held.set_spin(arsenal.spin)


# --- Deciding ---------------------------------------------------------------

func _think() -> void:
	_target = _pick_target()
	_ensure_loaded_weapon()

	if _wants_resupply():
		var stocked := _nearest_bucket(true)
		if stocked != null:
			_bucket = stocked
		elif arsenal.total_ammo() <= 0:
			# Completely dry and every bucket is empty: wait at the nearest one
			# for it to refill instead of chasing people we can't tag.
			_bucket = _nearest_bucket(false)
		else:
			_bucket = null
		if _bucket != null:
			_mood = Mood.RESUPPLY
			_set_goal(_bucket.global_position)
			return
	_bucket = null

	if _target != null:
		_mood = Mood.FIGHT
		_choose_weapon()
		return

	_mood = Mood.ROAM
	var arrived := _has_goal and global_position.distance_to(_goal) < GOAL_REACHED_DISTANCE
	if not _has_goal or arrived or _goal_age > GOAL_TIMEOUT:
		if _grudge_left > 0.0 and is_instance_valid(_grudge) and _grudge.alive:
			_set_goal(_grudge.global_position)  # Go and find whoever hit us.
		else:
			_set_goal(_random_roam_point())


func _pick_target() -> Actor:
	var best: Actor = null
	var best_distance := INF
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var flat_aim := Vector3(_aim.x, 0.0, _aim.z).normalized()
	var half_fov := deg_to_rad(difficulty.fov_degrees) * 0.5
	for rival in rivals:
		if not is_instance_valid(rival) or not rival.alive or rival.team_id == team_id:
			continue
		var to_rival := rival.global_position - global_position
		var distance := to_rival.length()
		if distance > difficulty.vision_range:
			continue
		var holds_grudge := rival == _grudge and _grudge_left > 0.0
		if not holds_grudge and distance > 4.0:
			var flat := Vector3(to_rival.x, 0.0, to_rival.z).normalized()
			if flat_aim.angle_to(flat) > half_fov:
				continue
		_sight_query.from = eye
		_sight_query.to = rival.global_position + Vector3.UP * 1.1
		if not get_world_3d().direct_space_state.intersect_ray(_sight_query).is_empty():
			continue
		var score := distance * (0.6 if holds_grudge else 1.0)
		if score < best_distance:
			best_distance = score
			best = rival
	return best


func _choose_weapon() -> void:
	if arsenal.weapons.size() < 2 or _weapon_lock_left > 0.0 or arsenal.is_reloading():
		return
	var distance := global_position.distance_to(_target.global_position)
	var best_index := arsenal.current_index
	var best_score := -INF
	for i in arsenal.weapons.size():
		var state := arsenal.weapons[i]
		if state.total() <= 0:
			continue
		var data := state.data
		var score := data.ai_preference + randf() * 0.6
		if distance < data.ai_min_range or distance > data.ai_max_range:
			score -= 2.0
		if data.fire_mode == WeaponData.FireMode.SPIN_UP and state.total() < 40:
			score -= 3.0
		if i == arsenal.current_index:
			score += 0.3
		if score > best_score:
			best_score = score
			best_index = i
	if best_index != arsenal.current_index:
		arsenal.select(best_index)
		_weapon_lock_left = WEAPON_LOCK_SECONDS


func _wants_resupply() -> bool:
	if arsenal.total_missing() <= 0:
		return false  # Full up (or bottomless, as in Gun Game).
	if arsenal.total_ammo() < LOW_AMMO:
		return true
	# Already at a bucket: stay until topped up or it runs dry.
	return _mood == Mood.RESUPPLY and _bucket != null and not _bucket.is_empty()


## Never stand around holding an empty blaster if another one has darts,
## even if we only just switched to it.
func _ensure_loaded_weapon() -> void:
	var held := arsenal.current()
	if held == null or held.total() > 0 or arsenal.weapons.size() < 2:
		return
	for i in arsenal.weapons.size():
		if arsenal.weapons[i].total() > 0:
			arsenal.select(i)
			_weapon_lock_left = WEAPON_LOCK_SECONDS
			return


func _nearest_bucket(stocked_only: bool) -> AmmoBucket:
	if arena == null:
		return null
	var best: AmmoBucket = null
	var best_distance := INF
	for bucket in arena.buckets:
		if stocked_only and bucket.is_empty():
			continue
		var distance := global_position.distance_squared_to(bucket.global_position)
		if distance < best_distance:
			best_distance = distance
			best = bucket
	return best


func _random_roam_point() -> Vector3:
	if arena == null or arena.roam_points.is_empty():
		return global_position + Vector3(randf_range(-10.0, 10.0), 0.0, randf_range(-10.0, 10.0))
	return arena.roam_points[randi() % arena.roam_points.size()]


func _set_goal(point: Vector3) -> void:
	if not _has_goal or _goal.distance_squared_to(point) > 1.0:
		_goal_age = 0.0
	_goal = point
	_has_goal = true


# --- Aiming and shooting ------------------------------------------------------

func _update_aim(delta: float) -> void:
	var desired := _aim
	if _target != null and is_instance_valid(_target) and _target.alive:
		desired = _ballistic_aim(_target)
		_seen_for += delta
	else:
		_target = null
		_seen_for = 0.0
		var flat_velocity := Vector3(velocity.x, 0.0, velocity.z)
		if flat_velocity.length_squared() > 1.0:
			desired = flat_velocity.normalized()
	var angle := _aim.angle_to(desired)
	if angle > 0.001:
		var step := deg_to_rad(difficulty.turn_speed_degrees) * delta
		if angle > 3.0:
			desired = (desired + global_transform.basis.x * 0.2).normalized()
		_aim = _aim.slerp(desired, minf(step / angle, 1.0)).normalized()
	_on_target = _target != null and angle < deg_to_rad(8.0)
	rotation.y = atan2(-_aim.x, -_aim.z)
	_model.set_aim_pitch(asin(clampf(_aim.y, -1.0, 1.0)))


## Where to point so a dart arrives on a moving target despite gravity.
func _ballistic_aim(target: Actor) -> Vector3:
	var from := global_position + Vector3.UP * EYE_HEIGHT
	var point := target.global_position + Vector3.UP * 1.0
	var state := arsenal.current()
	if state == null or state.data.dart == null:
		return (point - from).normalized()
	var dart := state.data.dart
	var flight_time := from.distance_to(point) / maxf(dart.initial_speed, 1.0)
	flight_time *= 1.0 + 0.5 * dart.air_drag * flight_time
	point += target.velocity * flight_time * difficulty.lead_factor
	point.y += 0.5 * DartProjectile.GRAVITY * dart.gravity_multiplier * flight_time * flight_time
	return (point - from).normalized()


func _update_trigger(delta: float) -> void:
	var state := arsenal.current()
	var wants_fire := state != null and _target != null and _on_target and _seen_for >= difficulty.reaction_time
	if not wants_fire:
		arsenal.set_trigger(false)
		_trigger_clock = 0.0
		return
	var hold := 0.07
	var rest := difficulty.semi_interval
	match state.data.fire_mode:
		WeaponData.FireMode.AUTO:
			hold = difficulty.burst_time
			rest = difficulty.burst_pause
		WeaponData.FireMode.SPIN_UP:
			hold = state.data.spin_up_time + difficulty.burst_time * 2.5
			rest = difficulty.burst_pause
	_trigger_clock += delta
	arsenal.set_trigger(fmod(_trigger_clock, hold + rest) < hold)


# --- Moving -----------------------------------------------------------------

func _choose_direction(delta: float) -> Vector3:
	match _mood:
		Mood.FIGHT:
			if _target == null:
				return Vector3.ZERO
			return _fight_direction(delta)
		Mood.RESUPPLY:
			if global_position.distance_to(_goal) < 1.3:
				return Vector3.ZERO
			return _path_direction(_goal)
		_:
			if not _has_goal:
				return Vector3.ZERO
			return _path_direction(_goal)


func _fight_direction(delta: float) -> Vector3:
	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	to_target.y = 0.0
	var toward := to_target.normalized()
	var state := arsenal.current()
	var ideal := 12.0
	if state != null:
		ideal = lerpf(state.data.ai_min_range, minf(state.data.ai_max_range, 26.0), 0.4)

	_strafe_left -= delta
	if _strafe_left <= 0.0:
		_strafe_left = randf_range(0.8, 2.0)
		_strafe_sign = -_strafe_sign
	var strafe := toward.cross(Vector3.UP) * _strafe_sign

	var advance := Vector3.ZERO
	if distance > ideal + 4.0:
		advance = _path_direction(_target.global_position)
	elif distance < ideal - 4.0:
		advance = -toward
	return (advance + strafe * 0.7).limit_length(1.0)


## Next step along the navmesh toward `goal` (falls back to a straight line).
func _path_direction(goal: Vector3) -> Vector3:
	var direct := goal - global_position
	direct.y = 0.0
	# Until the background navmesh bake lands, steer straight at the goal.
	var nav_pending := arena != null and not arena.is_navigation_ready
	if nav_pending or NavigationServer3D.map_get_iteration_id(_nav.get_navigation_map()) == 0:
		return direct.normalized()
	if _nav.target_position.distance_squared_to(goal) > 0.25:
		_nav.target_position = goal
	if _nav.is_navigation_finished():
		return Vector3.ZERO
	var step := _nav.get_next_path_position() - global_position
	step.y = 0.0
	if step.length_squared() < 0.01:
		return direct.normalized()
	return step.normalized()


# --- Actor hooks --------------------------------------------------------------

func get_muzzle_position() -> Vector3:
	return global_position + Vector3.UP * 1.35 + _aim * 0.7


func get_aim_direction(_origin: Vector3) -> Vector3:
	return _aim


func get_extra_spread_degrees() -> float:
	return difficulty.aim_error_degrees


func respawn(at: Transform3D) -> void:
	super.respawn(at)
	_aim = -global_transform.basis.z
	_mood = Mood.ROAM
	_target = null
	_bucket = null
	_has_goal = false
	_seen_for = 0.0
	_stuck_for = 0.0
	_model.set_meter(0.0)


func _on_weapon_changed(state: WeaponState) -> void:
	_model.set_weapon(state.data if state != null else null)


func _on_shot_feedback(state: WeaponState) -> void:
	Sfx.play_at(state.data.sound, global_position + Vector3.UP * 1.3, state.data.sound_pitch, -4.0, 0.08)
	var held := _model.get_weapon()
	if held != null:
		held.flash()


## React to being hit: flinch, dodge the other way and remember who did it.
func _on_hit_received(attacker: Actor) -> void:
	_model.flinch()
	_strafe_sign = -_strafe_sign
	_strafe_left = randf_range(0.6, 1.4)
	if attacker != null:
		_grudge = attacker
		_grudge_left = GRUDGE_SECONDS
		if _mood == Mood.ROAM:
			_set_goal(attacker.global_position)


func _set_body_visible(shown: bool) -> void:
	_model.visible = shown
