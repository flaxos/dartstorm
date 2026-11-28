class_name Actor
extends CharacterBody3D
## Shared body for anyone who can run around and be tagged: the Player and Bots.
## Owns movement, the tag meter, the Arsenal and dart launching. Subclasses supply
## the brain (input or AI) and the look (first-person view or character model).

signal tagged_out(victim: Actor, attacker: Actor, weapon: WeaponData, ricochet: bool)
signal meter_changed(value: float, maximum: float)
signal landed_hit(victim: Actor, was_tag: bool, was_ricochet: bool)
signal respawned(actor: Actor)
signal ammo_collected(amount: int)
signal turned_zombie(actor: Actor)
signal shield_changed(current: float, max_val: float)
signal shield_broken(actor: Actor)
signal grenade_count_changed(count: int, max_val: int)
signal infusion_changed(element: DartData.Element, time_left: float)
signal tagged_out_status_changed(actor: Actor, is_out: bool)
signal damage_received(attacker: Actor, amount: float)

const GRAVITY := 20.0
const BODY_RADIUS := 0.4
const BODY_HEIGHT := 1.8
const KILL_PLANE_Y := -25.0
const SHIELD_MAX := 50.0
const MAX_HORIZONTAL_SPEED := 24.0
const GRENADE_MAX := 2

@export var display_name: String = "Actor"
@export var walk_speed: float = 6.4
@export var sprint_speed: float = 9.6
@export var jump_velocity: float = 7.6
@export var ground_acceleration: float = 60.0
@export var air_acceleration: float = 18.0
## Radius of the dart-catching hitbox. Bigger is easier to hit.
@export var hitbox_radius: float = 0.55
@export var tag_meter_max: float = 100.0
## Seconds without being hit before the tag meter starts draining.
@export var regen_delay: float = 4.0
@export var regen_rate: float = 15.0
## Seconds of safety after respawning.
@export var spawn_protection: float = 1.5

## In free-for-all every actor is its own team.
var team_id: int = 0
var color: Color = Color(0.15, 0.45, 1.0)
## Which hat this actor wears (see Cosmetics.HATS); shown on bots and the podium.
var hat_id: StringName = &"cap"
var alive: bool = true
## False during the countdown and after the match ends.
var controls_enabled: bool = false
var tag_meter: float = 0.0
## Multiplies the tag power of darts this actor fires (bot difficulty).
var damage_scale: float = 1.0
var is_human: bool = false
var is_zombie: bool = false
var shield_points: float = 0.0
var grenade_count: int = 0
var infusion_element: DartData.Element = DartData.Element.NONE
var infusion_left: float = 0.0
var buddy_actor: Actor = null
var realistic_mode: bool = false
var is_tagged_out: bool = false

var arsenal: Arsenal
var dart_pool: DartPool
var hitbox: Hitbox
var elemental: ElementalEffect

var _since_hit: float = 0.0
var _protect_left: float = 0.0
var _zombie_shield_grace: float = 0.0
var _hazard_feedback_cooldown: float = 0.0
var _hit_capsule: CapsuleShape3D
var _infused_dart_cache: Dictionary = {}


func _ready() -> void:
	collision_layer = Layers.ACTORS
	collision_mask = Layers.WORLD | Layers.ACTORS
	floor_snap_length = 0.3
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)

	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = BODY_HEIGHT * 0.5
	add_child(collision)

	hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.actor = self
	hitbox.collision_layer = Layers.HITBOX
	hitbox.collision_mask = 0
	hitbox.monitoring = false
	_hit_capsule = CapsuleShape3D.new()
	_hit_capsule.radius = hitbox_radius
	_hit_capsule.height = 2.0
	var hit_collision := CollisionShape3D.new()
	hit_collision.shape = _hit_capsule
	hit_collision.position.y = 1.0
	hitbox.add_child(hit_collision)
	add_child(hitbox)

	arsenal = Arsenal.new()
	arsenal.name = "Arsenal"
	add_child(arsenal)
	arsenal.fired.connect(_on_arsenal_fired)

	add_to_group(&"actors")
	elemental = ElementalEffect.new()
	elemental.name = "ElementalEffect"
	elemental.actor = self
	add_child(elemental)


# --- Movement ---------------------------------------------------------------

## Updates hitbox capsule radius at runtime (e.g. Zombie Siege archetypes).
func update_hitbox_radius(new_radius: float) -> void:
	hitbox_radius = new_radius
	if _hit_capsule != null:
		_hit_capsule.radius = new_radius


## Moves with smooth acceleration. `wish` is a horizontal direction of length 0..1.
func move_actor(wish: Vector3, sprinting: bool, jump: bool, delta: float) -> void:
	var speed := (sprint_speed if sprinting else walk_speed) * arsenal.get_move_multiplier()
	if elemental != null:
		speed *= elemental.get_speed_multiplier()
	var target := wish * speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	if elemental != null and elemental.is_sliding():
		acceleration *= 0.25
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, acceleration * delta)
	if horizontal.length_squared() > MAX_HORIZONTAL_SPEED * MAX_HORIZONTAL_SPEED:
		horizontal = horizontal.normalized() * MAX_HORIZONTAL_SPEED
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if jump:
		velocity.y = maxf(velocity.y, jump_velocity)
	elif not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if is_zombie and controls_enabled and alive:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			var other := col.get_collider() as Actor
			if other != null and not other.is_zombie and other.alive and not other.is_protected():
				try_zombie_infect(other)
				break


## Throws the actor upward (trampolines).
func launch(upward_speed: float) -> void:
	velocity.y = upward_speed


## Sudden short forward burst for zombie lunges or melee leaps.
func lunge(direction: Vector3, impulse_speed: float = 7.5) -> void:
	var dir := Vector3(direction.x, 0.0, direction.z).normalized()
	if dir.length_squared() > 0.01:
		velocity.x += dir.x * impulse_speed
		velocity.z += dir.z * impulse_speed
		var horiz := Vector3(velocity.x, 0.0, velocity.z)
		if horiz.length_squared() > MAX_HORIZONTAL_SPEED * MAX_HORIZONTAL_SPEED:
			horiz = horiz.normalized() * MAX_HORIZONTAL_SPEED
			velocity.x = horiz.x
			velocity.z = horiz.z


func set_zombie(enabled: bool) -> void:
	is_zombie = enabled
	if enabled:
		team_id = 1
		color = Color(0.38, 0.78, 0.28)
		arsenal.set_trigger(false)
		arsenal.enabled = false
		sprint_speed = 8.4
		walk_speed = 5.8
	else:
		sprint_speed = 9.6
		walk_speed = 6.4
		arsenal.enabled = true
	_on_zombie_state_changed(enabled)
	turned_zombie.emit(self)


func try_zombie_infect(victim: Actor) -> bool:
	if not is_zombie or not alive or victim == null or not victim.alive or victim.is_zombie or victim.is_protected():
		return false
	victim.receive_zombie_infection(self)
	return true


func is_local_human() -> bool:
	return is_human and not (self is NetworkPlayer)


func receive_zombie_infection(attacker: Actor) -> void:
	if not alive or is_tagged_out or is_protected() or _zombie_shield_grace > 0.0:
		return
	if shield_points > 0.0:
		if is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"shield_absorb", 1)
		shield_points = 0.0
		shield_changed.emit(0.0, SHIELD_MAX)
		shield_broken.emit(self)
		Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)
		_zombie_shield_grace = 0.75
		# Knock survivor away from zombie so the Foam Shield genuinely saves them.
		if attacker != null and is_instance_valid(attacker):
			var away := global_position - attacker.global_position
			away.y = 0.0
			if away.length_squared() > 0.001:
				velocity += away.normalized() * 8.0 + Vector3.UP * 2.5
		tag_meter = minf(tag_meter + 50.0, tag_meter_max - 1.0)
		meter_changed.emit(tag_meter, tag_meter_max)
		_since_hit = 0.0
		_on_hit_received(attacker)
		damage_received.emit(attacker, 50.0)
		return
	tag_meter = tag_meter_max
	meter_changed.emit(tag_meter, tag_meter_max)
	damage_received.emit(attacker, tag_meter_max)
	_tag_out(attacker, null, false)


# --- Being tagged -----------------------------------------------------------

func grant_shield(amount: float = SHIELD_MAX) -> void:
	shield_points = minf(amount, SHIELD_MAX)
	shield_changed.emit(shield_points, SHIELD_MAX)
	Sfx.play_at(&"shield_pickup", global_position, 1.0, 0.0)


func has_shield() -> bool:
	return shield_points > 0.0


func accepts_dart_from(other_team: int) -> bool:
	return alive and not is_tagged_out and other_team != team_id


func is_protected() -> bool:
	return _protect_left > 0.0


## Called by a dart that struck this actor's hitbox.
func receive_dart(dart: DartProjectile) -> void:
	if not alive or is_tagged_out or _protect_left > 0.0:
		return
	var attacker: Actor = dart.shooter if is_instance_valid(dart.shooter) else null
	var power := dart.data.tag_power * dart.tag_power_multiplier * (attacker.damage_scale if attacker != null else 1.0)
	var ricochet := dart.ricochet_count > 0

	if shield_points > 0.0:
		if is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"shield_absorb", 1)
		if power <= shield_points:
			shield_points -= power
			shield_changed.emit(shield_points, SHIELD_MAX)
			Sfx.play_at(&"shield_hit", global_position, 1.0, 0.0, 0.1)
			_since_hit = 0.0
			_on_hit_received(attacker)
			damage_received.emit(attacker, power)
			if attacker != null:
				attacker.landed_hit.emit(self, false, ricochet)
			return
		else:
			power -= shield_points
			shield_points = 0.0
			shield_changed.emit(0.0, SHIELD_MAX)
			shield_broken.emit(self)
			Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)

	tag_meter = minf(tag_meter + power, tag_meter_max)
	_since_hit = 0.0
	meter_changed.emit(tag_meter, tag_meter_max)
	var out := tag_meter >= tag_meter_max
	_on_hit_received(attacker)
	damage_received.emit(attacker, power)
	if elemental != null:
		elemental.apply_dart(dart, dart.global_position)
	if out and alive and not is_tagged_out:
		_tag_out(attacker, dart.weapon, ricochet)
	if attacker != null:
		attacker.landed_hit.emit(self, out, ricochet)


## Called when bonked by a close-range melee weapon (e.g. Foam Bat).
func receive_melee_hit(attacker: Actor, weapon: WeaponData, knockback_dir: Vector3) -> void:
	if not alive or is_tagged_out or _protect_left > 0.0:
		return
	var valid_attacker: Actor = attacker if is_instance_valid(attacker) else null
	if valid_attacker != null and not accepts_dart_from(valid_attacker.team_id):
		return

	var base_power := weapon.melee_damage if weapon != null else 100.0
	var power := base_power * (valid_attacker.damage_scale if valid_attacker != null else 1.0)
	var kb_speed := weapon.melee_knockback if weapon != null else 13.5
	var kb_lift := weapon.melee_lift if weapon != null else 4.6

	# Cartoon Home-Run knockback (damped gently on heavy Brutes / Titan Bosses)
	var flat_dir := Vector3(knockback_dir.x, 0.0, knockback_dir.z)
	if flat_dir.length_squared() < 0.001 and valid_attacker != null:
		flat_dir = global_position - valid_attacker.global_position
		flat_dir.y = 0.0
	if flat_dir.length_squared() > 0.001:
		var mass_scale := 0.35 if tag_meter_max >= 600.0 else (0.55 if tag_meter_max >= 250.0 else 1.0)
		velocity += flat_dir.normalized() * (kb_speed * mass_scale) + Vector3.UP * (kb_lift * mass_scale)
		var horiz := Vector2(velocity.x, velocity.z)
		if horiz.length() > MAX_HORIZONTAL_SPEED:
			horiz = horiz.normalized() * MAX_HORIZONTAL_SPEED
			velocity.x = horiz.x
			velocity.z = horiz.y

	Sfx.play_at(&"bat_bonk", global_position + Vector3.UP * 1.1, randf_range(0.95, 1.12), 1.0)

	if shield_points > 0.0:
		if is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"shield_absorb", 1)
		if power <= shield_points:
			shield_points -= power
			shield_changed.emit(shield_points, SHIELD_MAX)
			Sfx.play_at(&"shield_hit", global_position, 1.0, 0.0, 0.1)
			_since_hit = 0.0
			_on_hit_received(valid_attacker)
			damage_received.emit(valid_attacker, power)
			if valid_attacker != null:
				valid_attacker.landed_hit.emit(self, false, false)
			return
		else:
			power -= shield_points
			shield_points = 0.0
			shield_changed.emit(0.0, SHIELD_MAX)
			shield_broken.emit(self)
			Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)

	tag_meter = minf(tag_meter + power, tag_meter_max)
	_since_hit = 0.0
	meter_changed.emit(tag_meter, tag_meter_max)
	var out := tag_meter >= tag_meter_max
	_on_hit_received(valid_attacker)
	damage_received.emit(valid_attacker, power)
	if out and alive and not is_tagged_out:
		_tag_out(valid_attacker, weapon, false)
	if valid_attacker != null:
		valid_attacker.landed_hit.emit(self, out, false)


## Applies environmental hazard tag points (e.g. molten lava heat, toxic goo, electrified water).
## Foam Shield absorbs hazard damage before tag meter.
func apply_hazard_tag(amount: float, _hazard_source: Node = null, attacker: Actor = null) -> void:
	if not alive or is_tagged_out or _protect_left > 0.0 or amount <= 0.0:
		return
	var give_feedback := _hazard_feedback_cooldown <= 0.0
	if give_feedback:
		_hazard_feedback_cooldown = 0.35
	if shield_points > 0.0:
		if give_feedback and is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"shield_absorb", 1)
		if amount <= shield_points:
			shield_points -= amount
			shield_changed.emit(shield_points, SHIELD_MAX)
			if give_feedback:
				Sfx.play_at(&"shield_hit", global_position, 1.0, 0.0, 0.1)
				_on_hit_received(attacker)
				damage_received.emit(attacker, amount)
			_since_hit = 0.0
			return
		else:
			amount -= shield_points
			shield_points = 0.0
			shield_changed.emit(0.0, SHIELD_MAX)
			shield_broken.emit(self)
			Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)

	tag_meter = minf(tag_meter + amount, tag_meter_max)
	_since_hit = 0.0
	meter_changed.emit(tag_meter, tag_meter_max)
	if give_feedback:
		_on_hit_received(attacker)
		damage_received.emit(attacker, amount)
	if tag_meter >= tag_meter_max:
		_tag_out(attacker, null, false)


func add_grenade(amount: int = 1) -> bool:
	if grenade_count >= GRENADE_MAX:
		return false
	grenade_count = mini(grenade_count + amount, GRENADE_MAX)
	grenade_count_changed.emit(grenade_count, GRENADE_MAX)
	return true


func throw_grenade(launch_pos: Vector3, launch_dir: Vector3, impulse: float = 16.0) -> FoamGrenade:
	if grenade_count <= 0:
		return null
	grenade_count -= 1
	grenade_count_changed.emit(grenade_count, GRENADE_MAX)
	var grenade := FoamGrenade.new()
	grenade.thrower = self
	grenade.team_id = team_id
	grenade.dart_pool = dart_pool
	var parent_node := get_parent()
	if parent_node != null:
		parent_node.add_child(grenade)
	else:
		get_tree().root.add_child(grenade)
	grenade.add_collision_exception_with(self)
	grenade.launch(launch_pos, launch_dir, impulse)
	return grenade


func apply_elemental_infusion(p_element: DartData.Element, duration: float = 15.0) -> void:
	infusion_element = p_element
	infusion_left = duration
	infusion_changed.emit(infusion_element, infusion_left)


func apply_blast_tag(amount: float, attacker: Actor = null, p_team_id: int = -1) -> void:
	if not alive or is_tagged_out or _protect_left > 0.0:
		return
	var valid_attacker: Actor = attacker if is_instance_valid(attacker) else null
	var source_team: int = p_team_id if p_team_id >= 0 else (valid_attacker.team_id if valid_attacker != null else -1)
	if valid_attacker != null and valid_attacker != self and source_team >= 0 and not accepts_dart_from(source_team):
		return
	var power := amount * (valid_attacker.damage_scale if valid_attacker != null else 1.0)
	if shield_points > 0.0:
		if is_local_human():
			var prog: Node = get_node_or_null("/root/Progression")
			if prog != null:
				prog.call("notify_event", &"shield_absorb", 1)
		if power <= shield_points:
			shield_points -= power
			shield_changed.emit(shield_points, SHIELD_MAX)
			Sfx.play_at(&"shield_hit", global_position, 1.0, 0.0, 0.1)
			_since_hit = 0.0
			_on_hit_received(valid_attacker)
			damage_received.emit(valid_attacker, power)
			if valid_attacker != null:
				valid_attacker.landed_hit.emit(self, false, false)
			return
		else:
			power -= shield_points
			shield_points = 0.0
			shield_changed.emit(0.0, SHIELD_MAX)
			shield_broken.emit(self)
			Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)

	tag_meter = minf(tag_meter + power, tag_meter_max)
	_since_hit = 0.0
	meter_changed.emit(tag_meter, tag_meter_max)
	var out := tag_meter >= tag_meter_max
	_on_hit_received(valid_attacker)
	damage_received.emit(valid_attacker, power)
	if valid_attacker != null:
		valid_attacker.landed_hit.emit(self, out, false)
	if out:
		_tag_out(valid_attacker, null, false)


func respawn(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	tag_meter = 0.0
	is_tagged_out = false
	shield_points = 0.0
	shield_changed.emit(0.0, SHIELD_MAX)
	grenade_count = 0
	grenade_count_changed.emit(0, GRENADE_MAX)
	infusion_element = DartData.Element.NONE
	infusion_left = 0.0
	infusion_changed.emit(infusion_element, 0.0)
	_since_hit = 0.0
	_protect_left = spawn_protection
	_zombie_shield_grace = 0.0
	_hazard_feedback_cooldown = 0.0
	alive = true
	if elemental != null:
		elemental.clear_all()
	collision_layer = Layers.ACTORS
	hitbox.collision_layer = Layers.HITBOX
	arsenal.enabled = not is_zombie
	_set_body_visible(true)
	meter_changed.emit(tag_meter, tag_meter_max)
	tagged_out_status_changed.emit(self, false)
	respawned.emit(self)


## Regeneration, spawn protection and the safety net. Call once per physics tick.
func tick_status(delta: float) -> void:
	if not alive:
		return
	_protect_left = maxf(_protect_left - delta, 0.0)
	_zombie_shield_grace = maxf(_zombie_shield_grace - delta, 0.0)
	_hazard_feedback_cooldown = maxf(_hazard_feedback_cooldown - delta, 0.0)
	_since_hit += delta
	if not is_tagged_out and tag_meter > 0.0 and _since_hit >= regen_delay:
		tag_meter = maxf(tag_meter - regen_rate * delta, 0.0)
		meter_changed.emit(tag_meter, tag_meter_max)
	if infusion_left > 0.0:
		infusion_left = maxf(infusion_left - delta, 0.0)
		if infusion_left <= 0.0:
			infusion_element = DartData.Element.NONE
			infusion_changed.emit(infusion_element, 0.0)
	if global_position.y < KILL_PLANE_Y:
		if realistic_mode and is_tagged_out:
			# Prevent endless out-of-bounds soft-lock in Realistic mode: warp safely back up.
			global_position = Vector3(0.0, 2.0, 0.0)
			velocity = Vector3.ZERO
		else:
			_tag_out(null, null, false)


func _tag_out(attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	if realistic_mode:
		is_tagged_out = true
		if elemental != null:
			elemental.clear_all()
		arsenal.set_trigger(false)
		arsenal.enabled = false
		tagged_out_status_changed.emit(self, true)
		tagged_out.emit(self, attacker, weapon, ricochet)
		return

	alive = false
	if elemental != null:
		elemental.clear_all()
	arsenal.set_trigger(false)
	arsenal.enabled = false
	collision_layer = 0
	hitbox.collision_layer = 0
	velocity = Vector3.ZERO
	_set_body_visible(false)
	tagged_out.emit(self, attacker, weapon, ricochet)


## Realistic mode: revived when touching the team home base zone.
func revive_at_base() -> void:
	if not is_tagged_out:
		return
	is_tagged_out = false
	tag_meter = 0.0
	meter_changed.emit(tag_meter, tag_meter_max)
	arsenal.enabled = not is_zombie
	_protect_left = 2.0
	tagged_out_status_changed.emit(self, false)
	Sfx.play_at(&"powerup", global_position, 1.1, -2.0)


# --- Ammo -------------------------------------------------------------------

## Takes up to `amount` darts from a bucket. Returns how many were needed.
func collect_ammo(amount: int) -> int:
	var taken := arsenal.add_ammo(amount)
	if taken > 0:
		ammo_collected.emit(taken)
	return taken


# --- Firing -----------------------------------------------------------------

func _on_arsenal_fired(state: WeaponState) -> void:
	_on_shot_feedback(state)
	if state == null or state.data == null:
		return
	if state.data.is_melee():
		_perform_melee_swing(state)
		return
	if dart_pool == null or state.data.dart == null:
		return
	var weapon := state.data
	var origin := get_muzzle_position()
	var aim := get_aim_direction(origin)
	var exclude: Array[RID] = [hitbox.get_rid(), get_rid()]
	var dart_data := weapon.dart
	if infusion_left > 0.0 and infusion_element != DartData.Element.NONE:
		if dart_data.element != infusion_element:
			dart_data = _get_infused_dart_data(dart_data, infusion_element)
	var spread_mult := get_spread_multiplier()
	for i in weapon.darts_per_shot:
		var eff_spread: float = (state.get_spread_degrees() if state != null else weapon.spread_degrees) * spread_mult
		var direction := spread(aim, eff_spread + get_extra_spread_degrees())
		var dart := dart_pool.fire(dart_data, origin, direction, self, weapon, color, exclude)
		if state != null and dart != null:
			var speed_mult: float = float(state.modifiers.get("velocity_mult", 1.0))
			if speed_mult != 1.0:
				dart.velocity *= speed_mult
			var grav_mult: float = float(state.modifiers.get("gravity_mult", 1.0))
			if grav_mult != 1.0:
				dart.gravity_scale = grav_mult
			var power_mult: float = float(state.modifiers.get("tag_power_mult", 1.0))
			if power_mult != 1.0:
				dart.tag_power_multiplier = power_mult

	if NetworkManager != null and NetworkManager.is_online and is_local_human():
		NetworkManager.rpc(&"rpc_fire_dart", NetworkManager.local_peer_id, arsenal.current_index, origin, aim, 1.0, int(infusion_element))


## Sweeps a wide cartoon melee arc in front of the actor: bonks rivals & bullseyes,
## and bats incoming enemy foam darts or grenades right back along our aim!
func _perform_melee_swing(state: WeaponState) -> void:
	var weapon := state.data
	var eye := global_position + Vector3.UP * 1.4
	var aim := get_aim_direction(eye).normalized()
	var max_range := weapon.melee_range
	var min_dot := cos(deg_to_rad(weapon.melee_arc_degrees))
	var space := get_world_3d().direct_space_state if is_inside_tree() and get_world_3d() != null else null

	var fx_parent: Node = get_parent() if get_parent() != null else self
	var landed_bonk_or_deflect := false

	# 1. Bonk enemy actors inside melee arc & unobstructed line-of-sight
	for node in get_tree().get_nodes_in_group(&"actors"):
		var victim := node as Actor
		if victim == null or victim == self or not is_instance_valid(victim) or not victim.alive or victim.is_tagged_out:
			continue
		if not victim.accepts_dart_from(team_id):
			continue
		var target_center := victim.global_position + Vector3.UP * 1.05
		var to_victim := target_center - eye
		var dist := to_victim.length()
		var eff_range := max_range + victim.hitbox_radius * 0.65
		if dist > eff_range:
			continue
		if dist > 0.35 and aim.dot(to_victim / dist) < min_dot:
			continue
		if space != null and dist > 0.45:
			var q := PhysicsRayQueryParameters3D.create(eye, target_center, Layers.WORLD)
			q.collide_with_areas = false
			if not space.intersect_ray(q).is_empty():
				continue
		victim.receive_melee_hit(self, weapon, aim)
		CombatFx.spawn_comic_starburst(fx_parent, target_center + Vector3.UP * 0.45, "BONK!", Color(1.0, 0.85, 0.16), 1.05)
		landed_bonk_or_deflect = true

	# 2. Bonk bullseye wobble targets in reach
	for tnode in get_tree().get_nodes_in_group(&"wobble_targets"):
		var wt := tnode as WobbleTarget
		if wt == null or not is_instance_valid(wt):
			continue
		var to_t := wt.global_position - eye
		var d := to_t.length()
		if d <= max_range + 0.7 and (d < 0.4 or aim.dot(to_t / d) >= min_dot):
			wt.on_melee_hit(self)
			CombatFx.spawn_comic_starburst(fx_parent, wt.global_position + Vector3.UP * 0.35, "POW!", Color(1.0, 0.72, 0.14), 0.92)
			Sfx.play_at(&"bat_bonk", wt.global_position, 1.2, -1.0)
			landed_bonk_or_deflect = true

	# 3. Baseball Deflect! Bat incoming enemy foam darts straight back for ricochet bonus!
	if dart_pool != null and is_instance_valid(dart_pool):
		for child in dart_pool.get_children():
			var dart := child as DartProjectile
			if dart == null or not dart.is_flying():
				continue
			if dart.shooter == self or dart.team_id == team_id:
				continue
			var to_d := dart.global_position - eye
			var d := to_d.length()
			if d <= max_range + 0.8 and (d < 0.4 or aim.dot(to_d / d) >= min_dot - 0.1):
				dart.deflect(self, aim, 30.0)
				CombatFx.spawn_comic_starburst(fx_parent, dart.global_position, "DEFLECT!", Color(0.24, 0.94, 1.0), 0.98)
				Sfx.play_at(&"bat_bonk", dart.global_position, 1.3, 1.0)
				Sfx.play_at(&"ricochet", dart.global_position, 1.15, -2.0)
				landed_bonk_or_deflect = true

	# 4. Bat live foam grenades straight back (and claim thrower credit!)
	for gnode in get_tree().get_nodes_in_group(&"grenades"):
		var gren := gnode as FoamGrenade
		if gren == null or not is_instance_valid(gren) or gren.thrower == self:
			continue
		var to_g := gren.global_position - eye
		var d := to_g.length()
		if d <= max_range + 0.8 and (d < 0.4 or aim.dot(to_g / d) >= min_dot - 0.1):
			gren.linear_velocity = aim * 18.0 + Vector3.UP * 5.0
			gren.thrower = self
			gren.team_id = team_id
			CombatFx.spawn_comic_starburst(fx_parent, gren.global_position, "HOME RUN!", Color(1.0, 0.54, 0.12), 1.15)
			Sfx.play_at(&"bat_bonk", gren.global_position, 1.1, 1.0)
			landed_bonk_or_deflect = true

	if landed_bonk_or_deflect:
		_on_melee_impact_juice()


func _get_infused_dart_data(base_dart: DartData, elem: DartData.Element) -> DartData:
	var key := "%d_%d" % [base_dart.get_instance_id(), int(elem)]
	if _infused_dart_cache.has(key):
		return _infused_dart_cache[key] as DartData
	var copy := base_dart.duplicate() as DartData
	copy.element = elem
	match elem:
		DartData.Element.FIRE:
			copy.element_duration = maxf(copy.element_duration, 3.5)
			copy.element_power = maxf(copy.element_power, 3.0)
		DartData.Element.WATER:
			copy.element_duration = maxf(copy.element_duration, 4.0)
			copy.knockback_impulse = maxf(copy.knockback_impulse, 5.5)
		DartData.Element.LIGHTNING:
			copy.chain_count = maxi(copy.chain_count, 2)
			copy.chain_radius = maxf(copy.chain_radius, 6.5)
			copy.element_power = maxf(copy.element_power, 15.0)
		DartData.Element.ICE:
			copy.element_duration = maxf(copy.element_duration, 3.5)
		DartData.Element.WIND:
			copy.knockback_impulse = maxf(copy.knockback_impulse, 6.5)
			copy.element_duration = maxf(copy.element_duration, 0.6)
	_infused_dart_cache[key] = copy
	return copy


func get_spread_multiplier() -> float:
	return 1.0


## Random direction inside a cone of `degrees` around `direction`.
static func spread(direction: Vector3, degrees: float) -> Vector3:
	if degrees <= 0.0:
		return direction.normalized()
	var forward := direction.normalized()
	var side := forward.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = forward.cross(Vector3.RIGHT)
	side = side.normalized()
	var tilt := deg_to_rad(degrees) * sqrt(randf())
	return forward.rotated(side, tilt).rotated(forward, randf() * TAU).normalized()


# --- Overridden by Player and Bot ---------------------------------------------

func get_muzzle_position() -> Vector3:
	return global_position + Vector3.UP * 1.4


func get_aim_direction(_origin: Vector3) -> Vector3:
	return -global_transform.basis.z


func get_extra_spread_degrees() -> float:
	return 0.0


func _on_shot_feedback(_state: WeaponState) -> void:
	pass


func _on_hit_received(_attacker: Actor) -> void:
	pass


func _set_body_visible(_shown: bool) -> void:
	pass


func _on_zombie_state_changed(_enabled: bool) -> void:
	pass


func _on_melee_impact_juice() -> void:
	pass
