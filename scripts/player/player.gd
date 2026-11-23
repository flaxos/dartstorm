class_name Player
extends Actor
## The human player: first-person camera, keyboard/mouse (and gamepad) input,
## the blaster held in view, and all the "feel" (recoil, bob, shake, sounds).

signal shot_fired(state: WeaponState)
signal aiming_changed(is_aiming: bool)

const HEAD_HEIGHT := 1.62
const MOUSE_RADIANS_PER_PIXEL := 0.0022
## Right-stick turn speed at full tilt, radians per second (× the player's setting).
const PAD_LOOK_SPEED := 2.8
## Controller aim assist: turning slows to this fraction while over a rival.
const AIM_ASSIST_SLOWDOWN := 0.5
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.12
const SPRINT_FOV_BOOST := 6.0
const AIM_DISTANCE := 60.0
## The held blaster is turned slightly inward so you can see its side and tip.
const VIEW_YAW := 0.07

@export var player_index: int = 0
@export var action_prefix: String = ""
var skin_id: StringName = &"default"
var body_model: CharacterModel = null
var view_layer_mask: int = 1


func set_view_layer(mask: int) -> void:
	view_layer_mask = mask
	if _view_root != null:
		_set_model_layers(_view_root, mask)


var head: Node3D
var camera: Camera3D


func _act(base: StringName) -> StringName:
	return StringName(action_prefix + String(base)) if not action_prefix.is_empty() else base

var _view_root: Node3D
var _view_model: BlasterModel
var _view_offset: Vector3 = Vector3(0.24, -0.2, -0.5)
var _pitch: float = 0.0
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _sprinting: bool = false
var _trauma: float = 0.0
var _punch: float = 0.0
var _recoil: float = 0.0
var _swap: float = 0.0
var _bob_phase: float = 0.0
var _sway_pos := Vector2.ZERO
var _sway_vel := Vector2.ZERO
var _dip_pos: float = 0.0
var _dip_vel: float = 0.0
var _was_on_floor: bool = true
var _last_vel_y: float = 0.0
var _time: float = 0.0
var _aim_query: PhysicsRayQueryParameters3D
## Set when a click was used to re-capture the mouse, so that click never fires.
var _fire_blocked_until_release: bool = false
var mouse_captured_override: bool = false
var _assist_query: PhysicsRayQueryParameters3D
## Shown once per life when the Chainstorm reaches full spin.
var storm_mode_announced: bool = false
var _zombie_arms: Node3D
var _zombie_swipe: float = 0.0
var _fp_arms: Node3D
var _fp_left_arm: Node3D
var _fp_right_arm: Node3D
var _sleeve_mat: StandardMaterial3D
var _skin_mat: StandardMaterial3D
var _reloading: bool = false
var _reload_time: float = 0.0
var _reload_duration: float = 0.8
var _reload_slapped: bool = false
var is_aiming_down_sights: bool = false
var _net_sync_timer: float = 0.0


func _ready() -> void:
	hitbox_radius = 0.45  # A little harder to hit than the bots. Shh.
	super._ready()
	is_human = true

	head = Node3D.new()
	head.name = "Head"
	head.position.y = HEAD_HEIGHT
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.04
	camera.far = 500.0
	camera.fov = GameSettings.fov
	camera.current = true
	head.add_child(camera)
	_view_root = Node3D.new()
	_view_root.name = "ViewModel"
	camera.add_child(_view_root)

	_aim_query = PhysicsRayQueryParameters3D.new()
	_assist_query = PhysicsRayQueryParameters3D.new()
	_assist_query.collision_mask = Layers.WORLD | Layers.HITBOX
	_assist_query.collide_with_areas = true

	arsenal.weapon_changed.connect(_on_weapon_changed)
	arsenal.dry_fired.connect(func(_state: WeaponState) -> void: Sfx.play(&"dry"))
	arsenal.reload_started.connect(_on_reload_started)
	arsenal.reload_finished.connect(_on_reload_finished)
	landed_hit.connect(_on_landed_hit)
	ammo_collected.connect(func(_amount: int) -> void: Sfx.play(&"ammo", 1.0, -6.0, 0.1))
	respawned.connect(func(_actor: Actor) -> void: storm_mode_announced = false)
	tagged_out_status_changed.connect(func(_a: Actor, is_out: bool) -> void:
		if _view_root != null:
			_view_root.visible = not is_out
		if _fp_arms != null:
			_fp_arms.visible = not is_out
	)


func _exit_tree() -> void:
	Sfx.set_spin(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")):
		GameSettings.register_touch_event()
	var motion := event as InputEventMouseMotion
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or mouse_captured_override
	if motion != null and captured and player_index == 0:
		var zoom_ratio := camera.fov / maxf(GameSettings.fov, 1.0) if is_aiming_down_sights else 1.0
		var scale_factor := MOUSE_RADIANS_PER_PIXEL * GameSettings.mouse_sensitivity * zoom_ratio
		_look(-motion.relative.x * scale_factor, -motion.relative.y * scale_factor)
		_sway_vel += Vector2(-motion.relative.x, motion.relative.y) * (0.0012 * zoom_ratio)
		return
	# Clicking back into the window after alt-tab grabs the mouse again
	# instead of firing a surprise shot (desktop keyboard/mouse only).
	if event is InputEventMouseButton and event.pressed \
			and not captured and controls_enabled \
			and not get_tree().paused and player_index == 0 \
			and not OS.has_feature("mobile") and not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured_override = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			_fire_blocked_until_release = true
		get_viewport().set_input_as_handled()
		return
	if not alive or not controls_enabled or is_zombie:
		return
	if event.is_action_pressed(_act(&"weapon_next")):
		arsenal.cycle(1)
	elif event.is_action_pressed(_act(&"weapon_prev")):
		arsenal.cycle(-1)
	elif event.is_action_pressed(_act(&"weapon_1")):
		arsenal.select(0)
	elif event.is_action_pressed(_act(&"weapon_2")):
		arsenal.select(1)
	elif event.is_action_pressed(_act(&"weapon_3")):
		arsenal.select(2)
	elif event.is_action_pressed(_act(&"reload")):
		arsenal.request_reload()


func _physics_process(delta: float) -> void:
	tick_status(delta)
	if not alive:
		arsenal.set_trigger(false)
		return

	var pad_look := Input.get_vector(_act(&"look_left"), _act(&"look_right"), _act(&"look_up"), _act(&"look_down"))
	if pad_look.length_squared() > 0.0:
		var turn := pad_look_step(pad_look, delta)
		_look(turn.x, turn.y)

	var wish := Vector3.ZERO
	var jump := false
	_sprinting = false
	if controls_enabled:
		var input := Input.get_vector(_act(&"move_left"), _act(&"move_right"), _act(&"move_forward"), _act(&"move_back"))
		wish = (global_transform.basis * Vector3(input.x, 0.0, input.y)).limit_length(1.0)
		_sprinting = Input.is_action_pressed(_act(&"sprint")) and input.y < -0.1
		if Input.is_action_just_pressed(_act(&"jump")):
			_jump_buffer_left = JUMP_BUFFER
		var fire_held := Input.is_action_pressed(_act(&"fire"))
		if _fire_blocked_until_release:
			if fire_held:
				fire_held = false
			else:
				_fire_blocked_until_release = false

		var current_w := arsenal.current()
		var wants_aim := Input.is_action_pressed(_act(&"aim_down_sights")) and not is_zombie and not _sprinting and current_w != null and current_w.get_zoom_fov() > 0.0
		if wants_aim != is_aiming_down_sights:
			is_aiming_down_sights = wants_aim
			aiming_changed.emit(is_aiming_down_sights)

		if is_zombie or is_tagged_out:
			if is_aiming_down_sights:
				is_aiming_down_sights = false
				aiming_changed.emit(false)
			arsenal.set_trigger(false)
			if is_zombie and Input.is_action_just_pressed(_act(&"fire")) and not _fire_blocked_until_release:
				_perform_zombie_swipe()
				if wish.length_squared() > 0.05:
					lunge(wish.normalized(), 6.0)
		else:
			var planting_or_defusing := false
			var bomb_target: BombTarget = get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
			if bomb_target != null:
				if (bomb_target.state == BombTarget.BombState.PLANTING and bomb_target.carrier == self) \
						or (bomb_target.state == BombTarget.BombState.DEFUSING and bomb_target.current_defuser == self):
					planting_or_defusing = true
			arsenal.set_trigger(fire_held and not planting_or_defusing)

		if Input.is_action_just_pressed(_act(&"throw_grenade")) and not is_zombie and grenade_count > 0:
			_perform_grenade_throw()

		if Input.is_action_just_pressed(_act(&"ping")):
			_perform_ping()

		_handle_bomb_interaction(delta)
	else:
		if is_aiming_down_sights:
			is_aiming_down_sights = false
			aiming_changed.emit(false)
		arsenal.set_trigger(false)

	_coyote_left = COYOTE_TIME if is_on_floor() else maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		jump = true
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	move_actor(wish, _sprinting, jump, delta)


func _handle_bomb_interaction(delta: float) -> void:
	var bomb_target: BombTarget = get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
	if bomb_target == null:
		return
	var wants_interact := Input.is_action_pressed(_act(&"interact")) or Input.is_action_pressed(_act(&"fire"))
	if bomb_target.carrier == self:
		if not bomb_target.get_site_at(global_position).is_empty() and wants_interact:
			bomb_target.progress_plant(self, delta)
		else:
			bomb_target.cancel_plant()
	elif team_id == 0 and (bomb_target.state == BombTarget.BombState.PLANTED or bomb_target.state == BombTarget.BombState.DEFUSING):
		if wants_interact:
			bomb_target.progress_defuse(self, delta)
		else:
			bomb_target.cancel_defuse()


func _process(delta: float) -> void:
	_time += delta
	var shake_setting := GameSettings.camera_shake

	# Camera: gentle trauma-based shake plus a tiny upward punch per shot.
	_trauma = maxf(_trauma - 1.6 * delta, 0.0)
	_punch = lerpf(_punch, 0.0, minf(12.0 * delta, 1.0))
	var shake := _trauma * _trauma * shake_setting
	camera.rotation = Vector3(
		sin(_time * 47.0) * 0.012 * shake + _punch * shake_setting,
		sin(_time * 39.0 + 1.3) * 0.012 * shake,
		sin(_time * 31.0 + 2.1) * 0.01 * shake)
	var target_base_fov := GameSettings.fov
	var current_w := arsenal.current()
	if is_aiming_down_sights and current_w != null and current_w.get_zoom_fov() > 0.0:
		target_base_fov = current_w.get_zoom_fov()
	var fov_target := target_base_fov + (SPRINT_FOV_BOOST if _sprinting and not is_aiming_down_sights else 0.0)
	var fov_speed := 16.0 if is_aiming_down_sights else 8.0
	camera.fov = lerpf(camera.fov, fov_target, minf(fov_speed * delta, 1.0))

	# Blaster in view: spring-damper sway with looking, bob while walking,
	# landing dip, sprint canting, and kick on each shot.
	_recoil = lerpf(_recoil, 0.0, minf(14.0 * delta, 1.0))
	_swap = move_toward(_swap, 0.0, delta / Arsenal.SWAP_TIME)

	# 2nd-order spring for weapon inertia
	var sway_accel := -65.0 * _sway_pos - 14.0 * _sway_vel
	_sway_vel += sway_accel * delta
	_sway_pos += _sway_vel * delta
	_sway_pos = _sway_pos.limit_length(0.05)

	# Landing dip spring
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _last_vel_y < -2.5:
		_dip_vel += clampf(-_last_vel_y * 0.015, 0.0, 0.12)
	_was_on_floor = on_floor
	_last_vel_y = velocity.y

	var dip_accel := -75.0 * _dip_pos - 15.0 * _dip_vel
	_dip_vel += dip_accel * delta
	_dip_pos += _dip_vel * delta
	_dip_pos = clampf(_dip_pos, -0.04, 0.08)

	if NetworkManager != null and NetworkManager.is_online and is_human and player_index == 0:
		_net_sync_timer += delta
		if _net_sync_timer >= 0.05:
			_net_sync_timer = 0.0
			NetworkManager.rpc(&"rpc_sync_state", NetworkManager.local_peer_id, global_position, rotation.y, _pitch, velocity, is_aiming_down_sights, _sprinting)

	var speed := Vector2(velocity.x, velocity.z).length()
	var bob_amount := clampf(speed / walk_speed, 0.0, 1.4) if on_floor else 0.0
	if bob_amount > 0.05:
		_bob_phase += delta * (6.0 + speed * 0.9)
	var bob := Vector3(cos(_bob_phase * 0.5) * 0.008, -absf(sin(_bob_phase * 0.5)) * 0.012, 0.0) * bob_amount

	# Breathing idle sway
	var idle := Vector3(sin(_time * 1.5) * 0.0015, cos(_time * 3.0) * 0.0012, 0.0) * (1.0 - bob_amount)

	# Sprint weapon posture
	var sprint_factor := 0.0
	if _sprinting and speed > walk_speed * 0.7:
		sprint_factor = clampf((speed - walk_speed * 0.7) / (sprint_speed - walk_speed * 0.7), 0.0, 1.0)
	var sprint_offset := Vector3(0.01, -0.035, -0.03) * sprint_factor
	var sprint_rot := Vector3(-0.12, -0.15, 0.08) * sprint_factor

	var rattle := Vector3.ZERO
	var state := arsenal.current()
	var spin := 0.0
	if alive and state != null and state.data.fire_mode == WeaponData.FireMode.SPIN_UP:
		spin = arsenal.spin
		rattle = Vector3(sin(_time * 90.0), cos(_time * 77.0), 0.0) * 0.0025 * spin
	Sfx.set_spin(spin)
	if _view_model != null:
		_view_model.set_spin(spin)
	_zombie_swipe = maxf(_zombie_swipe - delta * 4.0, 0.0)
	if _zombie_arms != null and _zombie_arms.visible:
		var swipe_forward := sin(_zombie_swipe * PI) * 0.22
		var swipe_down := -sin(_zombie_swipe * PI) * 0.08
		_zombie_arms.position = Vector3(0.0, swipe_down, -swipe_forward)
		_zombie_arms.rotation = Vector3(-sin(_zombie_swipe * PI) * 0.35, 0.0, 0.0)

	var reload_offset := Vector3.ZERO
	var reload_rot := Vector3.ZERO
	if _reloading:
		_reload_time = minf(_reload_time + delta, _reload_duration)
		var p := _reload_time / _reload_duration
		if p < 0.28:
			var t := p / 0.28
			var ease_t := sin(t * PI * 0.5)
			reload_offset = Vector3(-0.04, -0.06, 0.06) * ease_t
			reload_rot = Vector3(0.35, -0.25, 0.25) * ease_t
			if _fp_left_arm != null:
				_fp_left_arm.position = Vector3(-0.06, -0.22 * ease_t, 0.15 * ease_t)
				_fp_left_arm.rotation = Vector3(-0.4 * ease_t, 0.0, 0.0)
		elif p < 0.68:
			var t := (p - 0.28) / 0.40
			var slap := sin(t * PI)
			if t >= 0.5 and not _reload_slapped:
				_reload_slapped = true
				_punch = -0.045
				_recoil = minf(_recoil + 0.35, 1.2)
				add_trauma(0.08)
				Sfx.play(&"ui_click", 1.35, -2.0)
			reload_offset = Vector3(-0.04, -0.06 - slap * 0.035, 0.06 - slap * 0.02)
			reload_rot = Vector3(0.35 - slap * 0.18, -0.25, 0.25 - slap * 0.12)
			if _fp_left_arm != null:
				_fp_left_arm.position = Vector3(-0.02, -0.08 * (1.0 - t), -0.02 + slap * 0.04)
				_fp_left_arm.rotation = Vector3(0.2 * slap, 0.0, 0.1 * slap)
		else:
			var t := (p - 0.68) / 0.32
			var ease_out := cos(t * PI * 0.5)
			reload_offset = Vector3(-0.04, -0.06, 0.06) * ease_out
			reload_rot = Vector3(0.35, -0.25, 0.25) * ease_out
			if _fp_left_arm != null:
				_fp_left_arm.position = Vector3(-0.04 * ease_out, -0.05 * ease_out, 0.0)
				_fp_left_arm.rotation = Vector3.ZERO

	_view_root.visible = alive and not (is_aiming_down_sights and camera.fov < GameSettings.fov - 10.0)
	_view_root.position = _view_offset + bob + idle + sprint_offset + rattle + reload_offset + Vector3(_sway_pos.x, -_sway_pos.y - 0.35 * _swap - _dip_pos, _recoil * 0.07)
	_view_root.rotation = Vector3(_recoil * 0.12 - _swap * 0.6 + sprint_rot.x - _dip_pos * 1.2, VIEW_YAW - _sway_pos.x * 0.5 + sprint_rot.y, sprint_rot.z - _sway_pos.x * 0.3) + reload_rot

	if body_model != null:
		var horiz := Vector2(velocity.x, velocity.z).length()
		body_model.animate(horiz, delta)
		body_model.set_aim_pitch(_pitch)
		body_model.set_meter(tag_meter / maxf(tag_meter_max, 1.0))
		body_model.set_shield_visible(shield_points > 0.0)


## Adds camera shake. `amount` 0..1; scaled by the player's shake setting.
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func get_muzzle_position() -> Vector3:
	var eye := head.global_transform
	var origin := eye.origin + eye.basis * Vector3(0.16, -0.14, -0.5)
	# If the blaster is poking through a wall, launch from the eye instead.
	_aim_query.from = eye.origin
	_aim_query.to = origin
	_aim_query.collision_mask = Layers.WORLD
	_aim_query.collide_with_areas = false
	_aim_query.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(_aim_query).is_empty():
		return eye.origin
	return origin


## Darts leave the muzzle but converge on whatever the crosshair is over.
func get_aim_direction(origin: Vector3) -> Vector3:
	var eye := head.global_transform
	var forward := -eye.basis.z
	var aim_point := eye.origin + forward * AIM_DISTANCE
	_aim_query.from = eye.origin
	_aim_query.to = aim_point
	_aim_query.collision_mask = Layers.WORLD | Layers.HITBOX | Layers.TARGETS
	_aim_query.collide_with_areas = true
	_aim_query.exclude = [get_rid(), hitbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
	if not hit.is_empty():
		aim_point = hit["position"]
	if origin.distance_to(aim_point) < 2.0:
		return forward
	return (aim_point - origin).normalized()


## Converts right-stick input into a yaw/pitch step (radians) for this frame.
## The response is curved (stick² in magnitude) so small nudges aim finely and
## full tilt still turns fast. With aim assist on, turning slows while the
## crosshair is over a rival, which makes controller aim far friendlier.
func pad_look_step(stick: Vector2, delta: float) -> Vector2:
	var curved := stick * stick.length()
	var speed := PAD_LOOK_SPEED * GameSettings.controller_look_speed
	if is_aiming_down_sights:
		speed *= (camera.fov / maxf(GameSettings.fov, 1.0))
	if GameSettings.aim_assist and crosshair_on_rival():
		speed *= AIM_ASSIST_SLOWDOWN
	return Vector2(-curved.x, -curved.y) * speed * delta


## True when the crosshair is over a rival who can be tagged.
func crosshair_on_rival() -> bool:
	var eye := head.global_transform
	_assist_query.from = eye.origin
	_assist_query.to = eye.origin - eye.basis.z * AIM_DISTANCE
	_assist_query.exclude = [get_rid(), hitbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(_assist_query)
	var box := hit.get("collider") as Hitbox
	if is_zombie:
		return box != null and box.actor != null and box.actor != self and not box.actor.is_zombie and box.actor.alive
	return box != null and box.actor != null and box.actor != self and box.actor.accepts_dart_from(team_id)


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	_pitch = clampf(_pitch + (-pitch if GameSettings.invert_y else pitch), -1.5, 1.5)
	head.rotation.x = _pitch


## Applies relative look delta from touch swipe or virtual controls.
func look_relative(delta: Vector2) -> void:
	if not alive or not controls_enabled:
		return
	var zoom_ratio := camera.fov / maxf(GameSettings.fov, 1.0) if is_aiming_down_sights else 1.0
	var scale_factor := MOUSE_RADIANS_PER_PIXEL * GameSettings.touch_look_sensitivity * zoom_ratio * 1.5
	_look(-delta.x * scale_factor, -delta.y * scale_factor)
	_sway_vel += Vector2(-delta.x, delta.y) * (0.0012 * zoom_ratio)


func _perform_grenade_throw() -> void:
	var toss_origin := camera.global_position + -camera.global_transform.basis.z * 0.45 + Vector3.DOWN * 0.15
	var toss_dir := (-camera.global_transform.basis.z + Vector3.UP * 0.22).normalized()
	throw_grenade(toss_origin, toss_dir, 17.5)
	_punch = -0.04
	_dip_vel = 0.06
	Sfx.play(&"whoosh", 1.25, -2.0)


func _perform_ping() -> void:
	var eye := head.global_transform
	var forward := -eye.basis.z
	_aim_query.from = eye.origin
	_aim_query.to = eye.origin + forward * 60.0
	_aim_query.collision_mask = Layers.WORLD | Layers.HITBOX | Layers.TARGETS
	_aim_query.collide_with_areas = true
	_aim_query.exclude = [get_rid(), hitbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
	var ping_pos: Vector3
	var ping_type := PingBeacon.Type.REGROUP
	if not hit.is_empty():
		ping_pos = hit["position"]
		var collider: Object = hit.get("collider")
		if collider is Hitbox and (collider as Hitbox).actor != null:
			var target_actor: Actor = (collider as Hitbox).actor
			if target_actor.accepts_dart_from(team_id):
				ping_type = PingBeacon.Type.RIVAL
		elif collider is Node:
			var n := collider as Node
			if n.is_in_group(&"ammo_buckets") or n is AmmoBucket:
				ping_type = PingBeacon.Type.AMMO
			elif n.is_in_group(&"shield_pickups") or n is ShieldPickup or n is GrenadePickup or n is ElementalPickup or n is PowerUpPickup:
				ping_type = PingBeacon.Type.POWERUP
			elif n is FoamGrenade or n.is_in_group(&"hazard"):
				ping_type = PingBeacon.Type.DANGER
	else:
		ping_pos = eye.origin + forward * 16.0

	var parent: Node = get_parent()
	if parent != null:
		var beacon := PingBeacon.spawn(parent, ping_pos, ping_type, self)
		Sfx.play(&"ping")
		for node in get_tree().get_nodes_in_group(&"bots"):
			var b := node as Bot
			if b != null and b.team_id == team_id and b != self:
				b.on_squad_ping(beacon)


func respawn(at: Transform3D) -> void:
	super.respawn(at)
	_pitch = 0.0
	head.rotation.x = 0.0
	if is_aiming_down_sights:
		is_aiming_down_sights = false
		aiming_changed.emit(false)
	if is_zombie:
		_on_weapon_changed(null)


func _on_weapon_changed(state: WeaponState) -> void:
	if is_aiming_down_sights:
		is_aiming_down_sights = false
		aiming_changed.emit(false)
	if _view_model != null:
		_view_model.queue_free()
		_view_model = null
	if is_zombie:
		if _fp_arms != null:
			_fp_arms.visible = false
		if _zombie_arms == null:
			_build_zombie_arms()
		_zombie_arms.visible = true
		_view_offset = Vector3(0.0, -0.15, -0.3)
		return
	if _zombie_arms != null:
		_zombie_arms.visible = false
	if state == null:
		if _fp_arms != null:
			_fp_arms.visible = false
		return
	if _fp_arms == null:
		_build_fp_arms()
	_fp_arms.visible = true
	if _sleeve_mat != null:
		_sleeve_mat.albedo_color = color
	var skin: StringName = skin_id if skin_id != &"default" else (GameSettings.player2_skin if player_index == 1 else GameSettings.player_skin)
	_view_model = BlasterModel.create(state.data, true, skin)
	_view_root.add_child(_view_model)
	if view_layer_mask != 1:
		_set_model_layers(_view_model, view_layer_mask)
	_view_offset = state.data.view_offset
	_swap = 1.0
	_recoil = 0.0
	if _fp_arms != null and _view_model != null:
		if _view_model.grip_marker != null and _fp_right_arm != null:
			_fp_right_arm.position = _view_model.grip_marker.position - Vector3(0.0, -0.09, 0.07)
		elif _fp_right_arm != null:
			_fp_right_arm.position = Vector3.ZERO
		if _fp_left_arm != null:
			if _view_model.foregrip_marker != null:
				_fp_left_arm.visible = true
				_fp_left_arm.position = _view_model.foregrip_marker.position - Vector3(0.0, -0.07, -0.22)
			elif _view_model.grip_marker != null:
				_fp_left_arm.visible = false
			else:
				_fp_left_arm.visible = true
				_fp_left_arm.position = Vector3.ZERO
	if body_model != null:
		body_model.set_weapon(state.data, skin)
	Sfx.play(&"swap")


func _on_shot_feedback(state: WeaponState) -> void:
	var weapon := state.data
	var snd: StringName = weapon.sound
	var snd_pitch: float = weapon.sound_pitch
	var vol_db: float = -3.0
	var kick: float = state.get_recoil_kick() if state != null else weapon.recoil_kick
	var shake: float = weapon.camera_shake * (float(state.modifiers.get("recoil_mult", 1.0)) if state != null else 1.0)
	if state != null and state.modifiers.has("sound_override") and not str(state.modifiers["sound_override"]).is_empty():
		snd = StringName(str(state.modifiers["sound_override"]))
		vol_db = -8.0
	Sfx.play(snd, snd_pitch, vol_db, 0.07)
	_recoil = minf(_recoil + kick, 1.6)
	_punch += 0.006 * kick
	add_trauma(shake)
	if _view_model != null:
		_view_model.flash()
	GameSettings.vibrate(0.12 * kick + 0.05, 0.0, 0.06)
	shot_fired.emit(state)


func _on_landed_hit(_victim: Actor, was_tag: bool, _was_ricochet: bool) -> void:
	Sfx.play(&"tag" if was_tag else &"hit_confirm", 1.0, -2.0 if was_tag else -6.0, 0.05)
	if was_tag:
		GameSettings.vibrate(0.5, 0.2, 0.15)


func _on_hit_received(_attacker: Actor) -> void:
	add_trauma(0.25)
	GameSettings.vibrate(0.3, 0.45, 0.16)


func _tag_out(attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	if is_aiming_down_sights:
		is_aiming_down_sights = false
		aiming_changed.emit(false)
	super._tag_out(attacker, weapon, ricochet)
	Sfx.play(&"tagged")
	GameSettings.vibrate(0.8, 0.8, 0.4)


func _on_zombie_state_changed(enabled: bool) -> void:
	if enabled:
		_on_weapon_changed(null)
	elif _zombie_arms != null:
		_zombie_arms.visible = false


func _perform_zombie_swipe() -> void:
	_zombie_swipe = 1.0
	var eye := head.global_transform
	var reach := 2.4
	_aim_query.from = eye.origin
	_aim_query.to = eye.origin - eye.basis.z * reach
	_aim_query.collision_mask = Layers.HITBOX | Layers.ACTORS
	_aim_query.collide_with_areas = true
	_aim_query.exclude = [get_rid(), hitbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
	var hit_actor: Actor = null
	if not hit.is_empty():
		var box := hit.get("collider") as Hitbox
		if box != null and box.actor != null:
			hit_actor = box.actor
		else:
			hit_actor = hit.get("collider") as Actor
	if hit_actor != null and hit_actor != self and not hit_actor.is_zombie and hit_actor.alive:
		try_zombie_infect(hit_actor)
		Sfx.play(&"infect")
		Sfx.play(&"zombie_moan", 1.1, -1.0)
		GameSettings.vibrate(0.7, 0.7, 0.2)
	else:
		Sfx.play(&"whoosh", 1.2, -4.0, 0.05)


func _on_reload_started(_state: WeaponState, seconds: float) -> void:
	_reloading = true
	_reload_time = 0.0
	_reload_duration = maxf(seconds, 0.1)
	_reload_slapped = false
	Sfx.play(&"reload", 0.9)


func _on_reload_finished(_state: WeaponState) -> void:
	_reloading = false
	_reload_time = 0.0
	_reload_slapped = false
	if _fp_left_arm != null:
		_fp_left_arm.position = Vector3.ZERO
		_fp_left_arm.rotation = Vector3.ZERO
	Sfx.play(&"reload", 1.2)


func _build_fp_arms() -> void:
	if _fp_arms != null:
		return
	_fp_arms = Node3D.new()
	_fp_arms.name = "FirstPersonArms"
	_view_root.add_child(_fp_arms)

	_sleeve_mat = ArenaKit.mat(color, 0.7)
	_skin_mat = ArenaKit.mat(Color(0.96, 0.78, 0.65), 0.55)

	# Right Arm: reaches forward to grip handle and trigger
	_fp_right_arm = Node3D.new()
	_fp_right_arm.name = "RightArm"
	_fp_arms.add_child(_fp_right_arm)
	# Forearm sleeve
	var r_sleeve := _capsule_arm(_fp_right_arm, 0.048, 0.28, Vector3(0.12, -0.22, 0.16), _sleeve_mat)
	r_sleeve.rotation_degrees = Vector3(48.0, -18.0, 15.0)
	# Hand wrapping handle
	var r_hand := ArenaKit.deco_box(_fp_right_arm, Vector3(0.065, 0.08, 0.065), Vector3(0.015, -0.11, 0.06), Color(0.96, 0.78, 0.65), Vector3(-14.0, 0.0, 0.0))
	r_hand.material_override = _skin_mat
	# Thumb over grip
	var r_thumb := ArenaKit.deco_box(_fp_right_arm, Vector3(0.03, 0.04, 0.05), Vector3(-0.02, -0.09, 0.07), Color(0.96, 0.78, 0.65), Vector3(-14.0, 20.0, 0.0))
	r_thumb.material_override = _skin_mat

	# Left Arm: reaches forward to support barrel / under-barrel forend
	_fp_left_arm = Node3D.new()
	_fp_left_arm.name = "LeftArm"
	_fp_arms.add_child(_fp_left_arm)
	# Forearm sleeve
	var l_sleeve := _capsule_arm(_fp_left_arm, 0.046, 0.30, Vector3(-0.16, -0.24, 0.14), _sleeve_mat)
	l_sleeve.rotation_degrees = Vector3(54.0, 32.0, -22.0)
	# Hand supporting receiver / forend
	var l_hand := ArenaKit.deco_box(_fp_left_arm, Vector3(0.075, 0.06, 0.07), Vector3(-0.03, -0.13, -0.12), Color(0.96, 0.78, 0.65), Vector3(10.0, 25.0, 0.0))
	l_hand.material_override = _skin_mat

	if view_layer_mask != 1:
		_set_model_layers(_fp_arms, view_layer_mask)


func _build_zombie_arms() -> void:
	if _zombie_arms != null:
		return
	_zombie_arms = Node3D.new()
	_zombie_arms.name = "ZombieArms"
	_view_root.add_child(_zombie_arms)
	var mat := ArenaKit.mat(Color(0.38, 0.78, 0.28), 0.7)
	for side: float in [-1.0, 1.0]:
		var arm := _capsule_arm(_zombie_arms, 0.065, 0.42, Vector3(side * 0.22, -0.16, -0.36), mat)
		arm.rotation_degrees = Vector3(70.0, side * -12.0, 0.0)
		ArenaKit.deco_sphere(_zombie_arms, 0.05, Vector3(side * 0.22, -0.06, -0.52), Color(0.48, 0.82, 0.38))
	if view_layer_mask != 1:
		_set_model_layers(_zombie_arms, view_layer_mask)


func _capsule_arm(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 3
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func enable_body_model(layer_mask: int = 2) -> void:
	if body_model == null:
		body_model = CharacterModel.new()
		add_child(body_model)
		body_model.setup(display_name, color, hat_id)
		body_model.show_overhead(true)
		var current_w := arsenal.current()
		if current_w != null:
			var skin: StringName = skin_id if skin_id != &"default" else (GameSettings.player2_skin if player_index == 1 else GameSettings.player_skin)
			body_model.set_weapon(current_w.data, skin)
		_set_model_layers(body_model, layer_mask)


func _set_model_layers(node: Node, mask: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = mask
	for child in node.get_children():
		_set_model_layers(child, mask)


func set_zombie(enabled: bool) -> void:
	super.set_zombie(enabled)
	if body_model != null:
		body_model.set_zombie(enabled)

