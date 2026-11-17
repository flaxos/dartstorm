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

const GRAVITY := 20.0
const BODY_RADIUS := 0.4
const BODY_HEIGHT := 1.8
const KILL_PLANE_Y := -25.0
const SHIELD_MAX := 50.0

@export var display_name: String = "Actor"
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 10.5
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

var arsenal: Arsenal
var dart_pool: DartPool
var hitbox: Hitbox
var elemental: ElementalEffect

var _since_hit: float = 0.0
var _protect_left: float = 0.0


func _ready() -> void:
	collision_layer = Layers.ACTORS
	collision_mask = Layers.WORLD | Layers.ACTORS
	floor_snap_length = 0.3

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
	var hit_capsule := CapsuleShape3D.new()
	hit_capsule.radius = hitbox_radius
	hit_capsule.height = 2.0
	var hit_collision := CollisionShape3D.new()
	hit_collision.shape = hit_capsule
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
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if jump:
		velocity.y = jump_velocity
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


func set_zombie(enabled: bool) -> void:
	is_zombie = enabled
	if enabled:
		team_id = 1
		color = Color(0.38, 0.78, 0.28)
		arsenal.set_trigger(false)
		arsenal.enabled = false
		sprint_speed = 11.2
		walk_speed = 7.5
	else:
		sprint_speed = 10.5
		walk_speed = 7.0
		arsenal.enabled = true
	_on_zombie_state_changed(enabled)
	turned_zombie.emit(self)


func try_zombie_infect(victim: Actor) -> bool:
	if not is_zombie or not alive or victim == null or not victim.alive or victim.is_zombie or victim.is_protected():
		return false
	victim.receive_zombie_infection(self)
	return true


func receive_zombie_infection(attacker: Actor) -> void:
	if not alive or is_protected():
		return
	if shield_points > 0.0:
		shield_points = 0.0
		shield_changed.emit(0.0, SHIELD_MAX)
		shield_broken.emit(self)
		Sfx.play_at(&"shield_pop", global_position, 1.0, 0.0)
		tag_meter = minf(tag_meter + 50.0, tag_meter_max)
		meter_changed.emit(tag_meter, tag_meter_max)
		_since_hit = 0.0
		_on_hit_received(attacker)
		if tag_meter >= tag_meter_max:
			_tag_out(attacker, null, false)
		return
	tag_meter = tag_meter_max
	meter_changed.emit(tag_meter, tag_meter_max)
	_tag_out(attacker, null, false)


# --- Being tagged -----------------------------------------------------------

func grant_shield(amount: float = SHIELD_MAX) -> void:
	shield_points = minf(amount, SHIELD_MAX)
	shield_changed.emit(shield_points, SHIELD_MAX)
	Sfx.play_at(&"shield_pickup", global_position, 1.0, 0.0)


func has_shield() -> bool:
	return shield_points > 0.0


func accepts_dart_from(other_team: int) -> bool:
	return alive and other_team != team_id


func is_protected() -> bool:
	return _protect_left > 0.0


## Called by a dart that struck this actor's hitbox.
func receive_dart(dart: DartProjectile) -> void:
	if not alive or _protect_left > 0.0:
		return
	var attacker: Actor = dart.shooter if is_instance_valid(dart.shooter) else null
	var power := dart.data.tag_power * (attacker.damage_scale if attacker != null else 1.0)
	var ricochet := dart.ricochet_count > 0

	if shield_points > 0.0:
		if power <= shield_points:
			shield_points -= power
			shield_changed.emit(shield_points, SHIELD_MAX)
			Sfx.play_at(&"shield_hit", global_position, 1.0, 0.0, 0.1)
			_since_hit = 0.0
			_on_hit_received(attacker)
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
	if out:
		_tag_out(attacker, dart.weapon, ricochet)
	else:
		if elemental != null:
			elemental.apply_dart(dart, dart.global_position)
	if attacker != null:
		attacker.landed_hit.emit(self, out, ricochet)


func respawn(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	tag_meter = 0.0
	shield_points = 0.0
	shield_changed.emit(0.0, SHIELD_MAX)
	_since_hit = 0.0
	_protect_left = spawn_protection
	alive = true
	if elemental != null:
		elemental.clear_all()
	collision_layer = Layers.ACTORS
	hitbox.collision_layer = Layers.HITBOX
	arsenal.enabled = not is_zombie
	_set_body_visible(true)
	meter_changed.emit(tag_meter, tag_meter_max)
	respawned.emit(self)


## Regeneration, spawn protection and the safety net. Call once per physics tick.
func tick_status(delta: float) -> void:
	if not alive:
		return
	_protect_left = maxf(_protect_left - delta, 0.0)
	_since_hit += delta
	if tag_meter > 0.0 and _since_hit >= regen_delay:
		tag_meter = maxf(tag_meter - regen_rate * delta, 0.0)
		meter_changed.emit(tag_meter, tag_meter_max)
	if global_position.y < KILL_PLANE_Y:
		_tag_out(null, null, false)


func _tag_out(attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
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
	if dart_pool == null or state.data.dart == null:
		return
	var weapon := state.data
	var origin := get_muzzle_position()
	var aim := get_aim_direction(origin)
	var exclude: Array[RID] = [hitbox.get_rid(), get_rid()]
	for i in weapon.darts_per_shot:
		var direction := spread(aim, weapon.spread_degrees + get_extra_spread_degrees())
		dart_pool.fire(weapon.dart, origin, direction, self, weapon, color, exclude)


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
