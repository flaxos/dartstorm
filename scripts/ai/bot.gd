class_name Bot
extends Actor
## A friendly computer opponent. Deliberately simple:
##   ROAM      wander between interesting spots using the navmesh
##   FIGHT     keep a comfortable range from a visible rival, strafe and shoot
##   RESUPPLY  run to the nearest stocked ammo bucket when nearly out of darts
## Bots lead moving targets and aim up to allow for dart drop, but they do NOT
## account for wind, so a clever player can use wind zones against them.

enum Mood { ROAM, FIGHT, RESUPPLY, RETURN_TO_BASE }

enum TacticalRole {
	UNASSIGNED,
	# Plant The Bomb roles
	BOMB_CARRIER,
	BOMB_ESCORT,
	BOMB_POST_PLANT,
	BOMB_DEFENDER_SITE_A,
	BOMB_DEFENDER_SITE_B,
	BOMB_DEFUSER,
	BOMB_DEFUSE_COVER,
	# CTF roles
	CTF_RUNNER,
	CTF_ANCHOR,
	CTF_ESCORT,
}

const EYE_HEIGHT := 1.5
const THINK_INTERVAL := 0.25
const LOW_AMMO := 15
const GRUDGE_SECONDS := 4.0
const WEAPON_LOCK_SECONDS := 2.5
const GOAL_REACHED_DISTANCE := 2.0
const GOAL_TIMEOUT := 14.0
## Bots in a fight still detour for the power-up if it's this close.
const POWER_UP_DETOUR := 22.0

var difficulty: BotDifficulty
var arena: Arena
## Everyone else in the match. Set by the match scene.
var rivals: Array[Actor] = []
## Power-up mode: the Chainstorm pickup to race for (null otherwise).
var power_up: PowerUpPickup

var archetype: StringName = &"runner"
var base_core: BaseCore = null
var barricades: Array[BaseBarricade] = []
var melee_damage: float = 15.0
var tactical_role: TacticalRole = TacticalRole.UNASSIGNED
var assigned_bomb_site: String = ""
var is_designated_defuser: bool = false
var _sighting_cooldown: float = 0.0
var _melee_cooldown: float = 0.0
var _lunge_cooldown: float = 0.0
var _lunge_telegraph_left: float = 0.0
var _lunge_dir: Vector3 = Vector3.ZERO

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
	add_to_group(&"bots")
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
	_model.setup(display_name, color, hat_id)

	_sight_query = PhysicsRayQueryParameters3D.new()
	_sight_query.collision_mask = Layers.WORLD
	_think_left = randf() * THINK_INTERVAL
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0

	arsenal.weapon_changed.connect(_on_weapon_changed)
	meter_changed.connect(func(value: float, maximum: float) -> void: _model.set_meter(value / maximum))
	shield_changed.connect(func(curr: float, _max: float) -> void: _model.set_shield_visible(curr > 0.0))
	shield_broken.connect(func(_a: Actor) -> void: _model.set_shield_visible(false))
	tagged_out_status_changed.connect(func(_a: Actor, is_out: bool) -> void:
		_model.set_tagged_out(is_out)
		if is_out:
			_mood = Mood.RETURN_TO_BASE
			_target = null)


func _physics_process(delta: float) -> void:
	tick_status(delta)
	if not alive:
		return
	_goal_age += delta
	_grudge_left = maxf(_grudge_left - delta, 0.0)
	_weapon_lock_left = maxf(_weapon_lock_left - delta, 0.0)
	_sighting_cooldown = maxf(_sighting_cooldown - delta, 0.0)

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
		var bomb_target_node := get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
		if bomb_target_node != null:
			if bomb_target_node.carrier == self and not bomb_target_node.get_site_at(global_position).is_empty():
				bomb_target_node.progress_plant(self, delta)
				wish = Vector3.ZERO
			elif team_id == 0 and is_designated_defuser and (bomb_target_node.state == BombTarget.BombState.PLANTED or bomb_target_node.state == BombTarget.BombState.DEFUSING) and global_position.distance_to(bomb_target_node.get_bomb_position()) <= BombTarget.DEFUSE_RADIUS:
				bomb_target_node.progress_defuse(self, delta)
				wish = Vector3.ZERO
		_melee_cooldown = maxf(_melee_cooldown - delta, 0.0)
		_lunge_cooldown = maxf(_lunge_cooldown - delta, 0.0)
		if _lunge_telegraph_left > 0.0:
			_lunge_telegraph_left = maxf(_lunge_telegraph_left - delta, 0.0)
			_model.position.y = -0.2
			wish = Vector3.ZERO
			if _lunge_telegraph_left <= 0.0:
				_model.position.y = 0.0
				lunge(_lunge_dir, 7.5)
				Sfx.play(&"whoosh", 0.9, -2.0)
		else:
			_model.position.y = 0.0
			if is_zombie and _target != null and is_instance_valid(_target) and _target.alive:
				var to_target := _target.global_position - global_position
				var dist := to_target.length()
				if dist < 1.4:
					try_zombie_infect(_target)
				elif dist >= 2.5 and dist <= 4.2 and _lunge_cooldown <= 0.0 and is_on_floor() and _has_line_of_sight(_target):
					_lunge_cooldown = 3.5 + randf() * 1.5
					_lunge_telegraph_left = 0.25
					_lunge_dir = Vector3(to_target.x, 0.0, to_target.z).normalized()
					Sfx.play(&"zombie_moan", 1.3, -3.0)
		if is_zombie and _melee_cooldown <= 0.0:
			var attacked := false
			for b in barricades:
				if is_instance_valid(b) and not b.is_broken:
					if global_position.distance_to(b.global_position) < 2.5:
						b.damage(melee_damage)
						_melee_cooldown = 1.0
						attacked = true
						break
			if not attacked and base_core != null and is_instance_valid(base_core) and not base_core.is_destroyed:
				if global_position.distance_to(base_core.global_position) < 2.8:
					base_core.damage(melee_damage, self)
					_melee_cooldown = 1.0
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

		# Floor is Lava: panic when submerged or near molten foam
		if arena != null and arena.lava_hazard != null and arena.lava_hazard.current_lava_y > -0.4:
			var lava_y := arena.lava_hazard.current_lava_y
			if global_position.y <= lava_y + 0.35:
				if is_on_floor():
					jump = true
				var escape_dir := _get_lava_escape_direction(lava_y)
				if escape_dir.length_squared() > 0.01:
					wish = escape_dir
	else:
		arsenal.set_trigger(false)

	move_actor(wish * difficulty.move_speed_scale, is_zombie, jump, delta)
	_model.animate(Vector2(velocity.x, velocity.z).length(), delta)
	var held := _model.get_weapon()
	if held != null:
		held.set_spin(arsenal.spin)


func apply_archetype(p_archetype: StringName) -> void:
	archetype = p_archetype
	match p_archetype:
		&"runner":
			scale = Vector3.ONE
			hitbox_radius = 0.6
			sprint_speed = 9.2
			walk_speed = 6.2
			melee_damage = 15.0
			tag_meter_max = 100.0
			tag_meter = 0.0
			meter_changed.emit(tag_meter, tag_meter_max)
		&"brute":
			scale = Vector3.ONE * 1.35
			hitbox_radius = 0.85
			sprint_speed = 6.8
			walk_speed = 4.8
			melee_damage = 35.0
			tag_meter_max = 300.0
			tag_meter = 0.0
			meter_changed.emit(tag_meter, tag_meter_max)
		&"titan_boss":
			scale = Vector3.ONE * 2.2
			hitbox_radius = 1.4
			sprint_speed = 5.5
			walk_speed = 3.8
			melee_damage = 70.0
			tag_meter_max = 800.0
			tag_meter = 0.0
			meter_changed.emit(tag_meter, tag_meter_max)


func _has_line_of_sight(target_actor: Actor) -> bool:
	if target_actor == null or not is_instance_valid(target_actor):
		return false
	_sight_query.from = global_position + Vector3.UP * EYE_HEIGHT
	_sight_query.to = target_actor.global_position + Vector3.UP * 1.1
	return get_world_3d().direct_space_state.intersect_ray(_sight_query).is_empty()


# --- Deciding ---------------------------------------------------------------

func _think() -> void:
	if is_tagged_out:
		_mood = Mood.RETURN_TO_BASE
		_target = null
		if arena != null and not arena.team_bases.is_empty():
			var home := arena.team_bases[team_id % arena.team_bases.size()]
			_set_goal(home)
		return

	if is_zombie:
		var survivor := _pick_survivor_target()
		if survivor != null and global_position.distance_to(survivor.global_position) < 6.0:
			_target = survivor
			_mood = Mood.FIGHT
			_set_goal(survivor.global_position)
			return
		if base_core != null and is_instance_valid(base_core) and not base_core.is_destroyed:
			var target_pos := base_core.global_position
			var closest_b: BaseBarricade = null
			var closest_dist := INF
			for b in barricades:
				if is_instance_valid(b) and not b.is_broken:
					var dist := global_position.distance_squared_to(b.global_position)
					if dist < closest_dist and dist < 64.0:
						closest_dist = dist
						closest_b = b
			if closest_b != null:
				target_pos = closest_b.global_position
			_target = null
			_mood = Mood.ROAM
			_set_goal(target_pos)
			return
		elif survivor != null:
			_target = survivor
			_mood = Mood.FIGHT
			_set_goal(survivor.global_position)
			return
		else:
			_mood = Mood.ROAM
			var zom_arrived := _has_goal and global_position.distance_to(_goal) < GOAL_REACHED_DISTANCE
			if not _has_goal or zom_arrived or _goal_age > GOAL_TIMEOUT:
				_set_goal(_random_roam_point())
		return

	_target = _pick_target()
	_ensure_loaded_weapon()

	# 1. CTF Objectives
	var flags_in_match := get_tree().get_nodes_in_group(&"flags")
	if not flags_in_match.is_empty():
		if _think_ctf_objective(flags_in_match):
			return

	# 2. Plant The Bomb Objectives
	var bomb_target_obj: BombTarget = get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
	if bomb_target_obj != null:
		if _think_bomb_objective(bomb_target_obj):
			return

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

	if _wants_power_up():
		_mood = Mood.ROAM  # Keeps shooting at any target while it runs.
		_set_goal(power_up.global_position)
		return

	if _wants_shield():
		var sp := _nearest_shield_pickup()
		if sp != null:
			_mood = Mood.ROAM
			_set_goal(sp.global_position)
			return

	if _wants_grenade():
		var gp := _nearest_grenade_pickup()
		if gp != null:
			_mood = Mood.ROAM
			_set_goal(gp.global_position)
			return

	if _wants_elemental():
		var ep := _nearest_elemental_pickup()
		if ep != null:
			_mood = Mood.ROAM
			_set_goal(ep.global_position)
			return

	if _target != null:
		_mood = Mood.FIGHT
		_choose_weapon()
		_consider_grenade_throw()
		return

	_mood = Mood.ROAM
	var arrived := _has_goal and global_position.distance_to(_goal) < GOAL_REACHED_DISTANCE
	if not _has_goal or arrived or _goal_age > GOAL_TIMEOUT:
		if _grudge_left > 0.0 and is_instance_valid(_grudge) and _grudge.alive:
			_set_goal(_grudge.global_position)  # Go and find whoever hit us.
		else:
			_set_goal(_random_roam_point())


# --- Objective AI: Plant The Bomb & CTF --------------------------------------

func _think_bomb_objective(bomb: BombTarget) -> bool:
	if bomb == null or not is_instance_valid(bomb) or arena == null:
		return false

	var bomb_pos := bomb.get_bomb_position()

	# --------------------------------------------------------------------------
	# TEAM 1: ATTACKERS (INFILTRATORS)
	# --------------------------------------------------------------------------
	if team_id == 1:
		match bomb.state:
			BombTarget.BombState.CARRIED, BombTarget.BombState.PLANTING:
				if bomb.carrier == self:
					tactical_role = TacticalRole.BOMB_CARRIER
					if assigned_bomb_site.is_empty():
						var site_keys := bomb.get_site_keys()
						if not site_keys.is_empty():
							assigned_bomb_site = str(site_keys[posmod(int(hash(display_name)), site_keys.size())])
						else:
							assigned_bomb_site = "A"

					var current_site := bomb.get_site_at(global_position)
					if not current_site.is_empty():
						# Stand ground and plant
						_mood = Mood.ROAM
						if _target != null and is_instance_valid(_target) and _target.alive:
							_aim = (_target.global_position - global_position).normalized()
						_set_goal(global_position)
						return true
					else:
						# Push to target bomb site
						var site_pos := bomb.get_site_position(assigned_bomb_site)
						if site_pos == Vector3.ZERO and arena != null:
							site_pos = arena.get_bomb_site_pos(assigned_bomb_site)
						_mood = Mood.ROAM
						_set_goal(site_pos)
						return true
				elif bomb.carrier != null and is_instance_valid(bomb.carrier) and bomb.carrier.alive:
					tactical_role = TacticalRole.BOMB_ESCORT
					var carrier_pos := bomb.carrier.global_position
					if bomb.state == BombTarget.BombState.PLANTING:
						# Carrier is planting: hold perimeter around site to protect them
						if _target != null and is_instance_valid(_target) and _target.alive and _has_line_of_sight(_target):
							_callout_sighting(_target)
							_mood = Mood.FIGHT
							return true
						var guard_pos := _get_crossfire_position(carrier_pos)
						_mood = Mood.ROAM
						_set_goal(guard_pos)
						_aim = (carrier_pos - global_position).normalized()
						return true
					else:
						# Convoy formation around carrier
						if _target != null and is_instance_valid(_target) and _target.alive and global_position.distance_to(_target.global_position) < 14.0:
							_callout_sighting(_target)
							_mood = Mood.FIGHT
							return true
						var fwd := -bomb.carrier.global_transform.basis.z
						var right := bomb.carrier.global_transform.basis.x
						var side_sign := 1.0 if posmod(int(hash(display_name)), 2) == 0 else -1.0
						var escort_goal := carrier_pos + fwd * 4.0 + right * (3.5 * side_sign)
						_mood = Mood.ROAM
						_set_goal(escort_goal)
						return true

			BombTarget.BombState.DROPPED:
				var living_attackers := _get_living_teammates()
				living_attackers.append(self)
				var closest_attacker: Actor = null
				var closest_d := INF
				for a in living_attackers:
					var d := a.global_position.distance_to(bomb_pos)
					if d < closest_d:
						closest_d = d
						closest_attacker = a
				if closest_attacker == self:
					tactical_role = TacticalRole.BOMB_CARRIER
					_mood = Mood.ROAM
					_set_goal(bomb_pos)
					return true
				else:
					tactical_role = TacticalRole.BOMB_ESCORT
					if _target != null and is_instance_valid(_target) and _target.alive and _has_line_of_sight(_target):
						_callout_sighting(_target)
						_mood = Mood.FIGHT
						return true
					var cover_pos := bomb_pos + Vector3(sin(hash(display_name)), 0.0, cos(hash(display_name))).normalized() * 6.0
					_mood = Mood.ROAM
					_set_goal(cover_pos)
					return true

			BombTarget.BombState.PLANTED, BombTarget.BombState.DEFUSING:
				tactical_role = TacticalRole.BOMB_POST_PLANT
				# Prioritize stopping the defuser!
				if bomb.current_defuser != null and is_instance_valid(bomb.current_defuser) and bomb.current_defuser.alive:
					_target = bomb.current_defuser
					_mood = Mood.FIGHT
					_callout_sighting(_target, PingBeacon.Type.DANGER)
					_set_goal(bomb.current_defuser.global_position)
					return true
				if _target != null and is_instance_valid(_target) and _target.alive:
					var dist_to_bomb := _target.global_position.distance_to(bomb_pos)
					if dist_to_bomb < 10.0 or _has_line_of_sight(_target):
						_mood = Mood.FIGHT
						return true
				# Hold post-plant crossfire watching the bomb
				var crossfire_pos := _get_crossfire_position(bomb_pos)
				_mood = Mood.ROAM
				_set_goal(crossfire_pos)
				if global_position.distance_to(crossfire_pos) < 2.5:
					_aim = (bomb_pos - global_position).normalized()
				return true

			_:
				pass

	# --------------------------------------------------------------------------
	# TEAM 0: DEFENDERS (GUARDIANS)
	# --------------------------------------------------------------------------
	elif team_id == 0:
		match bomb.state:
			BombTarget.BombState.CARRIED, BombTarget.BombState.DROPPED, BombTarget.BombState.PLANTING:
				# Pre-plant defense: distribute between Site A and Site B
				if assigned_bomb_site.is_empty():
					var site_keys := bomb.get_site_keys()
					if site_keys.size() >= 2:
						assigned_bomb_site = str(site_keys[posmod(int(hash(display_name)), site_keys.size())])
					elif not site_keys.is_empty():
						assigned_bomb_site = str(site_keys[0])
					else:
						assigned_bomb_site = "A"

				tactical_role = TacticalRole.BOMB_DEFENDER_SITE_A if assigned_bomb_site == "A" else TacticalRole.BOMB_DEFENDER_SITE_B

				if _target != null and is_instance_valid(_target) and _target.alive and _has_line_of_sight(_target):
					_callout_sighting(_target)
					_mood = Mood.FIGHT
					return true

				var site_guard_pos := _get_site_guard_position(assigned_bomb_site, bomb)
				_mood = Mood.ROAM
				_set_goal(site_guard_pos)
				return true

			BombTarget.BombState.PLANTED, BombTarget.BombState.DEFUSING:
				# Bomb is planted: rotate to active site and coordinate single defuser + cover
				assigned_bomb_site = bomb.active_site

				var living_defenders: Array[Actor] = []
				var has_human_defuser_near := false
				for act in get_tree().get_nodes_in_group(&"actors"):
					var a := act as Actor
					if a != null and is_instance_valid(a) and a.alive and not a.is_tagged_out and a.team_id == 0:
						living_defenders.append(a)
						if a.is_human and a.global_position.distance_to(bomb_pos) <= 8.0:
							has_human_defuser_near = true

				if has_human_defuser_near:
					is_designated_defuser = false
				else:
					var closest_d := INF
					var closest_actor: Actor = null
					for d in living_defenders:
						var dist := d.global_position.distance_to(bomb_pos)
						if dist < closest_d:
							closest_d = dist
							closest_actor = d
					is_designated_defuser = (closest_actor == self)

				if is_designated_defuser:
					tactical_role = TacticalRole.BOMB_DEFUSER
					_mood = Mood.ROAM
					_set_goal(bomb_pos)
					return true
				else:
					tactical_role = TacticalRole.BOMB_DEFUSE_COVER
					if _target != null and is_instance_valid(_target) and _target.alive and _has_line_of_sight(_target):
						_mood = Mood.FIGHT
						return true
					var cover_pos := _get_crossfire_position(bomb_pos)
					_mood = Mood.ROAM
					_set_goal(cover_pos)
					if global_position.distance_to(cover_pos) < 2.5:
						var out_dir := (cover_pos - bomb_pos).normalized()
						if out_dir.length_squared() > 0.01:
							_aim = out_dir
					return true

			_:
				pass

	return false


func _think_ctf_objective(flags: Array) -> bool:
	if flags.is_empty() or arena == null:
		return false

	var our_flag: FlagPickup = null
	var enemy_flag: FlagPickup = null
	for f in flags:
		var flag := f as FlagPickup
		if flag != null:
			if flag.team_id == team_id:
				our_flag = flag
			else:
				enemy_flag = flag

	if our_flag == null or enemy_flag == null:
		return false

	var home_ped := arena.get_flag_pedestal(team_id)
	var enemy_ped := arena.get_flag_pedestal(1 - team_id)

	# 1. OUR FLAG IS STOLEN: High priority interception!
	if our_flag.state == FlagPickup.State.CARRIED:
		if our_flag.carrier != null and is_instance_valid(our_flag.carrier) and our_flag.carrier.alive:
			_target = our_flag.carrier
			_callout_sighting(_target, PingBeacon.Type.DANGER)
			_mood = Mood.FIGHT
			_set_goal(our_flag.carrier.global_position)
			return true

	# 2. OUR FLAG IS DROPPED: Quick recovery
	if our_flag.state == FlagPickup.State.DROPPED:
		if global_position.distance_to(our_flag.global_position) < 25.0:
			_mood = Mood.ROAM
			_set_goal(our_flag.global_position)
			return true

	# 3. WE ARE CARRYING THE ENEMY FLAG: Run home to score!
	if enemy_flag.carrier == self:
		_mood = Mood.ROAM
		_set_goal(home_ped)
		return true

	# 4. A TEAMMATE IS CARRYING THE ENEMY FLAG: Escort convoy!
	if enemy_flag.carrier != null and is_instance_valid(enemy_flag.carrier) and enemy_flag.carrier.alive and enemy_flag.carrier.team_id == team_id:
		tactical_role = TacticalRole.CTF_ESCORT
		var carrier_pos := enemy_flag.carrier.global_position
		if _target != null and is_instance_valid(_target) and _target.alive and _has_line_of_sight(_target):
			_mood = Mood.FIGHT
			return true
		var to_home := (home_ped - carrier_pos).normalized()
		var side_sign := 1.0 if posmod(int(hash(display_name)), 2) == 0 else -1.0
		var escort_pos := carrier_pos + to_home * 4.5 + Vector3(-to_home.z, 0.0, to_home.x) * (2.8 * side_sign)
		_mood = Mood.ROAM
		_set_goal(escort_pos)
		return true

	# 5. ENEMY FLAG IS DROPPED: Rush to pick it up
	if enemy_flag.state == FlagPickup.State.DROPPED:
		_mood = Mood.ROAM
		_set_goal(enemy_flag.global_position)
		return true

	# 6. BASELINE CTF ROLES: Runners vs Anchors
	_assign_ctf_role()

	if tactical_role == TacticalRole.CTF_ANCHOR:
		if _target != null and is_instance_valid(_target) and _target.alive and _target.global_position.distance_to(home_ped) < 22.0:
			_callout_sighting(_target)
			_mood = Mood.FIGHT
			return true
		var patrol_angle := float(posmod(int(hash(display_name)), 360)) * (PI / 180.0)
		var patrol_pos := home_ped + Vector3(cos(patrol_angle), 0.0, sin(patrol_angle)) * 6.5
		_mood = Mood.ROAM
		_set_goal(patrol_pos)
		return true

	elif tactical_role == TacticalRole.CTF_RUNNER:
		if _target != null and is_instance_valid(_target) and _target.alive and global_position.distance_to(_target.global_position) < 10.0 and _has_line_of_sight(_target):
			_mood = Mood.FIGHT
			return true
		_mood = Mood.ROAM
		_set_goal(enemy_ped)
		return true

	return false


func _assign_ctf_role() -> void:
	if tactical_role == TacticalRole.CTF_RUNNER or tactical_role == TacticalRole.CTF_ANCHOR:
		return
	if posmod(int(hash(display_name)), 2) == 0:
		tactical_role = TacticalRole.CTF_ANCHOR
	else:
		tactical_role = TacticalRole.CTF_RUNNER


func _callout_sighting(target_actor: Actor, ping_type: PingBeacon.Type = PingBeacon.Type.RIVAL) -> void:
	if target_actor == null or not is_instance_valid(target_actor) or _sighting_cooldown > 0.0:
		return
	_sighting_cooldown = 7.5
	var parent_node := get_parent()
	if parent_node != null:
		var beacon := PingBeacon.spawn(parent_node, target_actor.global_position, ping_type, self)
		if beacon != null:
			Sfx.play_at(&"ping", global_position, randf_range(0.95, 1.05), -4.0)
			for bot_node in get_tree().get_nodes_in_group(&"bots"):
				var b := bot_node as Bot
				if b != null and b != self and b.team_id == team_id and b.alive:
					b.on_squad_ping(beacon)


func _get_crossfire_position(bomb_pos: Vector3) -> Vector3:
	var angle := float(posmod(int(hash(display_name)), 360)) * (PI / 180.0)
	var dist := 7.0 + float(posmod(int(hash(display_name)), 5))
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * dist
	var target_pos := bomb_pos + offset
	if arena != null and not arena.roam_points.is_empty():
		var nearest_roam := Vector3.ZERO
		var nearest_d := INF
		for rp in arena.roam_points:
			var d := rp.distance_to(target_pos)
			if d < nearest_d and d < 6.0:
				nearest_d = d
				nearest_roam = rp
		if nearest_d < 6.0:
			return nearest_roam
	return target_pos


func _get_site_guard_position(site_id: String, bomb: BombTarget) -> Vector3:
	var site_pos := bomb.get_site_position(site_id)
	if site_pos == Vector3.ZERO and arena != null:
		site_pos = arena.get_bomb_site_pos(site_id)
	var angle := float(posmod(int(hash(display_name)), 360)) * (PI / 180.0)
	var dist := 3.5 + float(posmod(int(hash(display_name)), 4))
	var target_pos := site_pos + Vector3(cos(angle), 0.0, sin(angle)) * dist
	if arena != null and not arena.roam_points.is_empty():
		var nearest_roam := Vector3.ZERO
		var nearest_d := INF
		for rp in arena.roam_points:
			var d := rp.distance_to(target_pos)
			if d < nearest_d and d < 5.0:
				nearest_d = d
				nearest_roam = rp
		if nearest_d < 5.0:
			return nearest_roam
	return target_pos


func _get_living_teammates() -> Array[Actor]:
	var mates: Array[Actor] = []
	for act in get_tree().get_nodes_in_group(&"actors"):
		var a := act as Actor
		if a != null and a != self and is_instance_valid(a) and a.alive and not a.is_tagged_out and a.team_id == team_id:
			mates.append(a)
	return mates


func _pick_survivor_target() -> Actor:
	var best: Actor = null
	var best_distance := INF
	for rival in rivals:
		if not is_instance_valid(rival) or not rival.alive or rival.is_tagged_out or rival.team_id == team_id or rival.is_zombie:
			continue
		var distance := global_position.distance_squared_to(rival.global_position)
		if distance < best_distance:
			best_distance = distance
			best = rival
	return best


func _pick_target() -> Actor:
	var best: Actor = null
	var best_distance := INF
	var eye := global_position + Vector3.UP * EYE_HEIGHT
	var flat_aim := Vector3(_aim.x, 0.0, _aim.z).normalized()
	var half_fov := deg_to_rad(difficulty.fov_degrees) * 0.5
	for rival in rivals:
		if not is_instance_valid(rival) or not rival.alive or rival.is_tagged_out or rival.team_id == team_id:
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


## Go for the power-up when it's out, we don't have it, and it's close or
## there's nobody to fight.
func _wants_power_up() -> bool:
	if is_zombie or power_up == null or not power_up.is_available() or power_up.weapon == null:
		return false
	if arsenal.has_weapon(power_up.weapon.id):
		return false
	return _target == null or global_position.distance_to(power_up.global_position) < POWER_UP_DETOUR


func _wants_shield() -> bool:
	if is_zombie or shield_points > 0.0 or arena == null or arena.shield_pickups.is_empty():
		return false
	var nearest := _nearest_shield_pickup()
	if nearest == null or not nearest.is_available():
		return false
	return _target == null or global_position.distance_to(nearest.global_position) < 20.0


func _nearest_shield_pickup() -> ShieldPickup:
	if arena == null:
		return null
	var best: ShieldPickup = null
	var best_dist := INF
	for sp in arena.shield_pickups:
		if sp != null and sp.is_available():
			var d := global_position.distance_to(sp.global_position)
			if d < best_dist:
				best_dist = d
				best = sp
	return best


func _wants_grenade() -> bool:
	if is_zombie or grenade_count >= GRENADE_MAX or arena == null or arena.grenade_pickups.is_empty():
		return false
	var nearest := _nearest_grenade_pickup()
	if nearest == null or not nearest.is_available():
		return false
	return _target == null or global_position.distance_to(nearest.global_position) < 18.0


func _nearest_grenade_pickup() -> GrenadePickup:
	if arena == null:
		return null
	var best: GrenadePickup = null
	var best_dist := INF
	for gp in arena.grenade_pickups:
		if gp != null and gp.is_available():
			var d := global_position.distance_to(gp.global_position)
			if d < best_dist:
				best_dist = d
				best = gp
	return best


func _wants_elemental() -> bool:
	if is_zombie or infusion_left > 3.0 or arena == null or arena.elemental_pickups.is_empty():
		return false
	var nearest := _nearest_elemental_pickup()
	if nearest == null or not nearest.is_available():
		return false
	return _target == null or global_position.distance_to(nearest.global_position) < 18.0


func _nearest_elemental_pickup() -> ElementalPickup:
	if arena == null:
		return null
	var best: ElementalPickup = null
	var best_dist := INF
	for ep in arena.elemental_pickups:
		if ep != null and ep.is_available():
			var d := global_position.distance_to(ep.global_position)
			if d < best_dist:
				best_dist = d
				best = ep
	return best


func _consider_grenade_throw() -> void:
	if is_zombie or grenade_count <= 0 or _target == null or not is_instance_valid(_target) or not _target.alive:
		return
	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	if dist >= 5.0 and dist <= 19.0 and randf() < 0.3:
		var toss_origin := global_position + Vector3.UP * 1.5 + _aim * 0.4
		var toss_dir := (Vector3(to_target.x, 0.0, to_target.z).normalized() + Vector3.UP * 0.35).normalized()
		throw_grenade(toss_origin, toss_dir, clampf(dist * 1.25, 12.0, 20.0))


func _wants_resupply() -> bool:
	if is_zombie or arsenal.total_missing() <= 0:
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
	if arena.lava_hazard != null and arena.lava_hazard.current_lava_y > -0.4:
		var safe_points := arena.roam_points.filter(func(p: Vector3) -> bool: return p.y > arena.lava_hazard.current_lava_y + 0.5)
		if not safe_points.is_empty():
			return safe_points[randi() % safe_points.size()]
		var highest := arena.roam_points[0]
		for p in arena.roam_points:
			if p.y > highest.y:
				highest = p
		return highest

	# In DUOS / Teams, bias roaming toward living buddy so teammates stick together
	if buddy_actor != null and is_instance_valid(buddy_actor) and buddy_actor.alive:
		var buddy_pos := buddy_actor.global_position
		var buddy_near := arena.roam_points.filter(func(p: Vector3) -> bool:
			var d := p.distance_to(buddy_pos)
			return d >= 5.0 and d <= 18.0
		)
		if not buddy_near.is_empty() and randf() < 0.75:
			return buddy_near[randi() % buddy_near.size()]

	return arena.roam_points[randi() % arena.roam_points.size()]


func _get_lava_escape_direction(lava_y: float) -> Vector3:
	if arena == null:
		return Vector3.ZERO

	if arena.lava_hazard != null and not arena.lava_hazard.active_stones.is_empty():
		var best_stone: ObsidianStone = null
		var best_dist := INF
		for stone in arena.lava_hazard.active_stones:
			if is_instance_valid(stone) and stone.lifetime > 0.5:
				var d := global_position.distance_to(stone.global_position)
				if d < best_dist and d < 18.0:
					best_dist = d
					best_stone = stone
		if best_stone != null:
			var dir := best_stone.global_position - global_position
			dir.y = 0.0
			return dir.normalized()

	var safe_points := arena.roam_points.filter(func(p: Vector3) -> bool: return p.y > lava_y + 0.5)
	if not safe_points.is_empty():
		var best_point: Vector3 = safe_points[0]
		var best_dist := INF
		for p: Vector3 in safe_points:
			var d := global_position.distance_to(p)
			if d < best_dist:
				best_dist = d
				best_point = p
		var dir := best_point - global_position
		dir.y = 0.0
		return dir.normalized()

	for base in arena.team_bases:
		if base.y > lava_y + 0.5:
			var dir := base - global_position
			dir.y = 0.0
			return dir.normalized()

	return Vector3.ZERO


func _set_goal(point: Vector3) -> void:
	if not _has_goal or _goal.distance_squared_to(point) > 1.0:
		_goal_age = 0.0
	_goal = point
	_has_goal = true


# --- Aiming and shooting ------------------------------------------------------

func _update_aim(delta: float) -> void:
	var desired := _aim
	if _target != null and is_instance_valid(_target) and _target.alive and not _target.is_tagged_out:
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
	if is_zombie or is_tagged_out:
		arsenal.set_trigger(false)
		_trigger_clock = 0.0
		return
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
	var wish := Vector3.ZERO
	if is_zombie:
		if _target != null and is_instance_valid(_target) and _target.alive and not _target.is_tagged_out:
			wish = _path_direction(_target.global_position)
		elif _has_goal:
			wish = _path_direction(_goal)
	else:
		match _mood:
			Mood.FIGHT:
				if _target != null:
					wish = _fight_direction(delta)
			Mood.RESUPPLY:
				if global_position.distance_to(_goal) >= 1.3:
					wish = _path_direction(_goal)
			_:
				if _has_goal:
					wish = _path_direction(_goal)

	# Avoid stepping into electrified puddles during thunderstorms
	if arena != null and not arena.puddles.is_empty():
		for puddle in arena.puddles:
			if puddle != null and is_instance_valid(puddle) and puddle.is_electrified():
				var to_puddle := puddle.global_position - global_position
				to_puddle.y = 0.0
				var safe_dist := puddle.radius + 1.2
				if to_puddle.length_squared() < safe_dist * safe_dist:
					var avoid_dir := -to_puddle.normalized()
					wish = (wish + avoid_dir * 1.6).normalized()
					break
	return wish


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

	# Low-health defensive retreat: fall back from target to avoid tag-out
	if tag_meter >= tag_meter_max * 0.70:
		return (-toward + strafe * 0.4).limit_length(1.0)

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
	tactical_role = TacticalRole.UNASSIGNED
	assigned_bomb_site = ""
	is_designated_defuser = false
	_sighting_cooldown = 0.0
	if is_zombie:
		_model.set_zombie(true)


func _on_weapon_changed(state: WeaponState) -> void:
	if is_zombie:
		_model.set_weapon(null)
		return
	_model.set_weapon(state.data if state != null else null, &"", state.attachments if state != null else {})


func _on_shot_feedback(state: WeaponState) -> void:
	Sfx.play_at(state.data.sound, global_position + Vector3.UP * 1.3, state.data.sound_pitch, -4.0, 0.08)
	var held := _model.get_weapon()
	if held != null:
		held.flash()


## React to being hit: flinch, dodge the other way and remember who did it.
func _on_hit_received(attacker: Actor) -> void:
	_model.flinch()
	if shield_points > 0.0:
		_model.flash_shield()
	_strafe_sign = -_strafe_sign
	_strafe_left = randf_range(0.6, 1.4)
	if attacker != null:
		_grudge = attacker
		_grudge_left = GRUDGE_SECONDS
		if _mood == Mood.ROAM:
			_set_goal(attacker.global_position)


func _set_body_visible(shown: bool) -> void:
	_model.visible = shown


func _on_zombie_state_changed(enabled: bool) -> void:
	if _model != null:
		_model.set_zombie(enabled)


## Responds to an interactive tactical ping from a teammate or player.
func on_squad_ping(beacon: PingBeacon) -> void:
	if beacon == null or not is_instance_valid(beacon):
		return
	if is_zombie or not alive:
		return

	if global_position.distance_to(beacon.global_position) < 30.0:
		Sfx.play_at(&"ping_ack", global_position, randf_range(0.95, 1.05), -2.0)

	match beacon.type:
		PingBeacon.Type.REGROUP:
			_set_goal(beacon.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)))
			_mood = Mood.ROAM
		PingBeacon.Type.RIVAL:
			var to_ping := (beacon.global_position - global_position).normalized()
			to_ping.y = 0.0
			_aim = to_ping
			if _target == null:
				_set_goal(beacon.global_position)
				_mood = Mood.FIGHT
		PingBeacon.Type.AMMO:
			if _wants_resupply():
				_set_goal(beacon.global_position)
				_mood = Mood.RESUPPLY
		PingBeacon.Type.POWERUP:
			if _wants_shield() or _wants_grenade() or _wants_elemental():
				_set_goal(beacon.global_position)
				_mood = Mood.ROAM
		PingBeacon.Type.DANGER:
			if global_position.distance_to(beacon.global_position) < 8.0:
				var away := (global_position - beacon.global_position).normalized()
				_set_goal(global_position + away * 10.0)
				_mood = Mood.ROAM
