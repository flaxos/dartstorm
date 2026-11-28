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
var _body_layer_mask: int = 2
static var _active_spins: Dictionary = {}


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
var _ads_offset: Vector3 = Vector3(0.0, -0.16, -0.28)
var _ads_blend: float = 0.0
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
var _fp_left_arm_rest_pos: Vector3 = Vector3.ZERO
var _sleeve_mat: Material
var _skin_mat: Material
var _reloading: bool = false
var _reload_time: float = 0.0
var _reload_duration: float = 0.8
var _reload_slapped: bool = false
var _zombie_lunge_cd: float = 0.0
var _inspect_timer: float = 0.0
var _wall_pullback: float = 0.0
var _strafe_tilt: float = 0.0
var _air_lag: float = 0.0
var _last_step_half: int = 0
var is_aiming_down_sights: bool = false
var _net_sync_timer: float = 0.0


func _ready() -> void:
	hitbox_radius = 0.45  # A little harder to hit than the bots. Shh.
	super._ready()
	is_human = true
	arsenal.apply_profile_attachments = true
	arsenal.profile_index = player_index

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
	arsenal.reload_cancelled.connect(_on_reload_cancelled)
	landed_hit.connect(_on_landed_hit)
	ammo_collected.connect(func(_amount: int) -> void: Sfx.play(&"ammo", 1.0, -6.0, 0.1))
	respawned.connect(func(_actor: Actor) -> void:
		storm_mode_announced = false
		_reloading = false
		_reload_time = 0.0
		_inspect_timer = 0.0
	)
	tagged_out_status_changed.connect(func(_a: Actor, is_out: bool) -> void:
		if is_out:
			arsenal.cancel_reload()
			_reloading = false
			_inspect_timer = 0.0
		if _view_root != null:
			_view_root.visible = alive and not is_out
		if _fp_arms != null:
			_fp_arms.visible = not is_out
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_captured_override = false


func _exit_tree() -> void:
	_active_spins.erase(get_instance_id())
	var max_spin := 0.0
	for v: Variant in _active_spins.values():
		max_spin = maxf(max_spin, float(v))
	Sfx.set_spin(max_spin)


func get_spread_multiplier() -> float:
	return 0.55 if is_aiming_down_sights else 1.0


func launch(upward_speed: float) -> void:
	_coyote_left = 0.0
	super.launch(upward_speed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")):
		GameSettings.register_touch_event()
	if get_tree().paused or not controls_enabled or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not controls_enabled:
		mouse_captured_override = false
	var motion := event as InputEventMouseMotion
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or mouse_captured_override
	if motion != null and captured and alive and controls_enabled and not get_tree().paused and player_index == 0:
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
			and GameSettings.touch_controls_mode != GameSettings.TouchMode.ALWAYS \
			and not GameSettings.is_touch_active() \
			and not OS.has_feature("mobile") and not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured_override = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			_fire_blocked_until_release = true
		get_viewport().set_input_as_handled()
		return
	if not alive or not controls_enabled or is_zombie or is_tagged_out:
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
	elif event.is_action_pressed(_act(&"weapon_4")):
		arsenal.select(3)
	elif event.is_action_pressed(_act(&"weapon_5")):
		arsenal.select(4)
	elif event.is_action_pressed(_act(&"reload")):
		arsenal.request_reload()
	elif event.is_action_pressed(_act(&"inspect")):
		if not _reloading and not is_aiming_down_sights:
			_inspect_timer = 1.6


func _physics_process(delta: float) -> void:
	arsenal.profile_index = player_index
	_zombie_lunge_cd = maxf(_zombie_lunge_cd - delta, 0.0)
	tick_status(delta)
	if not alive:
		_sprinting = false
		if is_aiming_down_sights:
			is_aiming_down_sights = false
			aiming_changed.emit(false)
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
		if not is_zombie and not is_tagged_out:
			if Input.is_action_just_pressed(_act(&"reload")):
				arsenal.request_reload()
			if Input.is_action_just_pressed(_act(&"inspect")) and not _reloading and not is_aiming_down_sights:
				_inspect_timer = 1.6
		var fire_held := Input.is_action_pressed(_act(&"fire"))
		if _fire_blocked_until_release:
			if fire_held:
				fire_held = false
			else:
				_fire_blocked_until_release = false

		var current_w := arsenal.current()
		var wants_aim := Input.is_action_pressed(_act(&"aim_down_sights")) and not is_zombie and not is_tagged_out and not _sprinting and not _reloading and current_w != null and not current_w.data.is_melee()
		if wants_aim != is_aiming_down_sights:
			is_aiming_down_sights = wants_aim
			if is_aiming_down_sights:
				_inspect_timer = 0.0
			aiming_changed.emit(is_aiming_down_sights)

		if is_zombie or is_tagged_out:
			if is_aiming_down_sights:
				is_aiming_down_sights = false
				aiming_changed.emit(false)
			arsenal.set_trigger(false)
			if is_zombie and Input.is_action_just_pressed(_act(&"fire")) and not _fire_blocked_until_release and _zombie_lunge_cd <= 0.0:
				_zombie_lunge_cd = 0.85
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
			if fire_held and not planting_or_defusing:
				_inspect_timer = 0.0
			arsenal.set_trigger(fire_held and not planting_or_defusing)

		if Input.is_action_just_pressed(_act(&"throw_grenade")) and not is_zombie and not is_tagged_out and grenade_count > 0:
			_perform_grenade_throw()

		if Input.is_action_just_pressed(_act(&"ping")):
			_perform_ping()

		_handle_bomb_interaction(delta)
		_handle_siege_interaction()
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
	var pre_vel_y := velocity.y
	move_actor(wish, _sprinting, jump, delta)
	var now_on_floor := is_on_floor()
	if now_on_floor and not _was_on_floor and minf(_last_vel_y, pre_vel_y) < -2.5:
		var impact := minf(_last_vel_y, pre_vel_y)
		_dip_vel += clampf(-impact * 0.015, 0.0, 0.12)
		if impact < -7.5:
			add_trauma(clampf((-impact - 7.5) * 0.015, 0.0, 0.14))
	_was_on_floor = now_on_floor
	_last_vel_y = velocity.y


func _handle_bomb_interaction(delta: float) -> void:
	var bomb_target: BombTarget = get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
	if bomb_target == null:
		return
	var wants_interact := Input.is_action_pressed(_act(&"interact"))
	if bomb_target.carrier == self:
		if not bomb_target.get_site_at(global_position).is_empty() and wants_interact:
			bomb_target.progress_plant(self, delta)
		else:
			bomb_target.cancel_plant()
	elif team_id == 0 and (bomb_target.state == BombTarget.BombState.PLANTED or bomb_target.state == BombTarget.BombState.DEFUSING):
		if wants_interact:
			bomb_target.progress_defuse(self, delta)
		elif bomb_target.current_defuser == self:
			bomb_target.cancel_defuse()


func _handle_siege_interaction() -> void:
	if is_zombie or is_tagged_out or not Input.is_action_just_pressed(_act(&"interact")):
		return
	var director := get_tree().get_first_node_in_group(&"horde_director") as HordeDirector
	if director == null:
		return
	# Check Base Core repair within 4.5m
	var core := director.base_core
	if core != null and is_instance_valid(core) and not core.is_destroyed \
			and core.health < core.max_health \
			and global_position.distance_to(core.global_position) <= 4.5:
		if director.repair_base_core():
			if director.controller != null:
				director.controller.popup.emit(self, "CORE REPAIRED! +250 HP", UiKit.LIME)
		elif director.controller != null:
			director.controller.popup.emit(self, "NEED 100 SCRAP TO REPAIR CORE", UiKit.ORANGE)
		return
	# Check nearest broken barricade within 4.5m
	var best_barricade: BaseBarricade = null
	var best_dist := 4.5
	for b in director.barricades:
		if b != null and is_instance_valid(b) and b.is_broken:
			var d := global_position.distance_to(b.global_position)
			if d < best_dist:
				best_dist = d
				best_barricade = b
	if best_barricade != null:
		if director.rebuild_barricade(best_barricade):
			if director.controller != null:
				director.controller.popup.emit(self, "BARRICADE REBUILT!", UiKit.LIME)
		elif director.controller != null:
			director.controller.popup.emit(self, "NEED 75 SCRAP TO REBUILD", UiKit.ORANGE)


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
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
	var sway_mult := float(current_w.modifiers.get("sway_mult", 1.0)) if current_w != null else 1.0
	var ads_speed_mult := float(current_w.modifiers.get("ads_speed_mult", 1.0)) if current_w != null else 1.0
	if is_aiming_down_sights and current_w != null:
		if current_w.get_zoom_fov() > 0.0:
			target_base_fov = minf(current_w.get_zoom_fov(), GameSettings.fov - 6.0)
		else:
			target_base_fov = maxf(GameSettings.fov - 10.0, 50.0)
	var fov_target := target_base_fov + (SPRINT_FOV_BOOST if _sprinting and not is_aiming_down_sights else 0.0)
	var fov_speed := (16.0 * ads_speed_mult) if is_aiming_down_sights else 8.0
	camera.fov = lerpf(camera.fov, fov_target, minf(fov_speed * delta, 1.0))

	# Blaster in view: spring-damper sway with looking, bob while walking,
	# landing dip, strafe bank, airborne lag, wall pullback, sprint canting, and kick.
	_recoil = lerpf(_recoil, 0.0, minf(14.0 * delta, 1.0))
	_swap = move_toward(_swap, 0.0, delta / Arsenal.SWAP_TIME)

	# 2nd-order spring for weapon inertia
	var sway_accel := -65.0 * _sway_pos - 14.0 * _sway_vel
	_sway_vel += sway_accel * dt
	_sway_pos += _sway_vel * dt
	_sway_pos = _sway_pos.limit_length(0.05)

	var dip_accel := -75.0 * _dip_pos - 15.0 * _dip_vel
	_dip_vel += dip_accel * dt
	_dip_pos += _dip_vel * dt
	_dip_pos = clampf(_dip_pos, -0.04, 0.08)

	if NetworkManager != null and NetworkManager.is_online and is_human and player_index == 0:
		_net_sync_timer += delta
		if _net_sync_timer >= 0.05:
			_net_sync_timer = 0.0
			NetworkManager.rpc(&"rpc_sync_state", NetworkManager.local_peer_id, global_position, rotation.y, _pitch, velocity, is_aiming_down_sights, _sprinting)

	var on_floor := is_on_floor()
	var speed := Vector2(velocity.x, velocity.z).length()
	var bob_amount := clampf(speed / walk_speed, 0.0, 1.4) if on_floor else 0.0
	if bob_amount > 0.05:
		_bob_phase += delta * (6.0 + speed * 0.9)
		var step_half := int(floorf(_bob_phase / PI))
		if step_half != _last_step_half:
			_last_step_half = step_half
			if controls_enabled and alive and player_index == 0:
				Sfx.play(&"ui_click", 0.55 if not _sprinting else 0.72, -24.0, 0.1)
	var bob := Vector3(cos(_bob_phase * 0.5) * 0.008, -absf(sin(_bob_phase * 0.5)) * 0.012, 0.0) * bob_amount

	# Subtle strafe bank and vertical air lag
	var lateral_vel := velocity.dot(global_transform.basis.x)
	_strafe_tilt = lerpf(_strafe_tilt, clampf(-lateral_vel / maxf(walk_speed, 1.0), -1.0, 1.0) * 0.045, minf(10.0 * dt, 1.0))
	var target_air_lag := 0.0 if on_floor else clampf(-velocity.y * 0.004, -0.03, 0.03)
	_air_lag = lerpf(_air_lag, target_air_lag, minf(10.0 * dt, 1.0))

	# Pull viewmodel back smoothly when standing flush against a wall/fence
	var target_pullback := 0.0
	if alive and not is_zombie and not is_tagged_out and head != null:
		var eye := head.global_transform
		_aim_query.from = eye.origin
		_aim_query.to = eye.origin - eye.basis.z * 0.78
		_aim_query.collision_mask = Layers.WORLD
		_aim_query.collide_with_areas = false
		_aim_query.exclude = [get_rid()]
		var wall_hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
		if not wall_hit.is_empty():
			var d := eye.origin.distance_to(wall_hit["position"])
			target_pullback = clampf((0.78 - d) / 0.5, 0.0, 1.0)
	_wall_pullback = lerpf(_wall_pullback, target_pullback, minf(16.0 * dt, 1.0))

	# Breathing idle sway
	var idle := Vector3(sin(_time * 1.5) * 0.0015, cos(_time * 3.0) * 0.0012, 0.0) * (1.0 - bob_amount)

	# Sprint weapon posture
	var sprint_factor := 0.0
	if _sprinting and speed > walk_speed * 0.7:
		sprint_factor = clampf((speed - walk_speed * 0.7) / (sprint_speed - walk_speed * 0.7), 0.0, 1.0)
		_inspect_timer = 0.0
	var sprint_offset := Vector3(0.01, -0.035, -0.03) * sprint_factor
	var sprint_rot := Vector3(-0.12, -0.15, 0.08) * sprint_factor

	# Weapon inspect flourish (V / D-Pad Left)
	var inspect_offset := Vector3.ZERO
	var inspect_rot := Vector3.ZERO
	if _inspect_timer > 0.0:
		_inspect_timer = maxf(_inspect_timer - delta, 0.0)
		var insp_p := 1.0 - (_inspect_timer / 1.6)
		var env := sin(clampf(insp_p, 0.0, 1.0) * PI)
		var twist := sin(insp_p * TAU)
		inspect_offset = Vector3(-0.07 * env, 0.03 * env, 0.05 * env)
		inspect_rot = Vector3(0.18 * env, 0.55 * env + 0.25 * twist, -0.35 * env)

	var rattle := Vector3.ZERO
	var state := arsenal.current()
	var spin := 0.0
	if alive and controls_enabled and not is_tagged_out and state != null and state.data.fire_mode == WeaponData.FireMode.SPIN_UP:
		spin = arsenal.spin
		rattle = Vector3(sin(_time * 90.0), cos(_time * 77.0), 0.0) * 0.0025 * spin
	_active_spins[get_instance_id()] = spin
	var max_spin := 0.0
	for v: Variant in _active_spins.values():
		max_spin = maxf(max_spin, float(v))
	Sfx.set_spin(max_spin)
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
				_fp_left_arm.position = _fp_left_arm_rest_pos + Vector3(-0.06, -0.22 * ease_t, 0.15 * ease_t)
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
				_fp_left_arm.position = _fp_left_arm_rest_pos + Vector3(-0.02, -0.08 * (1.0 - t), -0.02 + slap * 0.04)
				_fp_left_arm.rotation = Vector3(0.2 * slap, 0.0, 0.1 * slap)
		else:
			var t := (p - 0.68) / 0.32
			var ease_out := cos(t * PI * 0.5)
			reload_offset = Vector3(-0.04, -0.06, 0.06) * ease_out
			reload_rot = Vector3(0.35, -0.25, 0.25) * ease_out
			if _fp_left_arm != null:
				_fp_left_arm.position = _fp_left_arm_rest_pos + Vector3(-0.04 * ease_out, -0.05 * ease_out, 0.0)
				_fp_left_arm.rotation = Vector3.ZERO

	_ads_blend = move_toward(_ads_blend, 1.0 if is_aiming_down_sights else 0.0, delta * 14.0 * ads_speed_mult)
	var is_scoped_optic := current_w != null and current_w.get_reticle() == &"scope"
	var hide_viewmodel := is_scoped_optic and is_aiming_down_sights and camera.fov < GameSettings.fov - 15.0
	_view_root.visible = alive and not is_tagged_out and not hide_viewmodel

	var base_offset: Vector3 = _view_offset.lerp(_ads_offset, _ads_blend)
	var base_yaw: float = lerpf(VIEW_YAW, 0.0, _ads_blend)
	var ads_stability: float = (1.0 - 0.82 * _ads_blend) * sway_mult
	var wall_offset := Vector3(0.0, -0.04 * _wall_pullback, 0.22 * _wall_pullback) * (1.0 - 0.85 * _ads_blend)
	var wall_rot := Vector3(0.32 * _wall_pullback, 0.0, 0.0) * (1.0 - 0.85 * _ads_blend)
	var recoil_z_scale := lerpf(0.07, 0.022, _ads_blend)

	_view_root.position = base_offset + (bob + idle + Vector3(_sway_pos.x, -_sway_pos.y + _air_lag, 0.0)) * ads_stability + sprint_offset + inspect_offset + wall_offset + rattle + reload_offset + Vector3(0.0, -0.35 * _swap - _dip_pos * ads_stability, _recoil * recoil_z_scale)
	_view_root.rotation = Vector3(_recoil * 0.12 - _swap * 0.6 + sprint_rot.x - _dip_pos * 1.2 * ads_stability, base_yaw - _sway_pos.x * 0.5 * ads_stability + sprint_rot.y, sprint_rot.z - _sway_pos.x * 0.3 * ads_stability + _strafe_tilt * ads_stability) + reload_rot + inspect_rot + wall_rot

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
	var fwd := -camera.global_transform.basis.z
	var toss_origin := camera.global_position + fwd * 0.45 + Vector3.DOWN * 0.15
	_aim_query.from = camera.global_position
	_aim_query.to = toss_origin
	_aim_query.collision_mask = Layers.WORLD
	_aim_query.collide_with_areas = false
	_aim_query.exclude = [get_rid()]
	var wall_hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
	if not wall_hit.is_empty():
		toss_origin = wall_hit["position"] - fwd * 0.18
	var toss_dir := (fwd + Vector3.UP * 0.22).normalized()
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
			var cur: Node = collider as Node
			for _depth in 3:
				if cur == null:
					break
				if cur.is_in_group(&"ammo_buckets") or cur is AmmoBucket:
					ping_type = PingBeacon.Type.AMMO
					break
				elif cur.is_in_group(&"shield_pickups") or cur is ShieldPickup or cur is GrenadePickup or cur is ElementalPickup or cur is PowerUpPickup:
					ping_type = PingBeacon.Type.POWERUP
					break
				elif cur is FoamGrenade or cur.is_in_group(&"hazard"):
					ping_type = PingBeacon.Type.DANGER
					break
				cur = cur.get_parent()
	else:
		ping_pos = eye.origin + forward * 16.0

	# If ray landed on floor/wall near an interactive bucket or pickup, classify it smartly.
	if ping_type == PingBeacon.Type.REGROUP:
		for node in get_tree().get_nodes_in_group(&"ammo_buckets"):
			var n3 := node as Node3D
			if n3 != null and n3.global_position.distance_to(ping_pos) <= 2.2:
				ping_type = PingBeacon.Type.AMMO
				ping_pos = n3.global_position
				break
	if ping_type == PingBeacon.Type.REGROUP:
		for grp: StringName in [&"shield_pickups", &"power_ups", &"elemental_pickups", &"grenade_pickups"]:
			for node in get_tree().get_nodes_in_group(grp):
				var n3 := node as Node3D
				if n3 != null and n3.global_position.distance_to(ping_pos) <= 2.2:
					ping_type = PingBeacon.Type.POWERUP
					ping_pos = n3.global_position
					break
			if ping_type != PingBeacon.Type.REGROUP:
				break

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
	_reloading = false
	_reload_time = 0.0
	_reload_slapped = false
	_inspect_timer = 0.0
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
	_fp_arms.visible = not is_tagged_out
	if _sleeve_mat != null:
		if _sleeve_mat is ShaderMaterial:
			(_sleeve_mat as ShaderMaterial).set_shader_parameter(&"albedo_color", Color(color.r, color.g, color.b, 1.0))
		elif _sleeve_mat is StandardMaterial3D:
			(_sleeve_mat as StandardMaterial3D).albedo_color = color
	var skin: StringName = skin_id if skin_id != &"default" else (GameSettings.player2_skin if player_index == 1 else GameSettings.player_skin)
	var atts: Dictionary = state.attachments if state != null else {}
	_view_model = BlasterModel.create(state.data, true, skin, atts)
	_view_root.add_child(_view_model)
	if view_layer_mask != 1:
		_set_model_layers(_view_model, view_layer_mask)
	_view_offset = state.data.view_offset
	_ads_offset = _view_model.get_ads_offset() if _view_model != null else Vector3(0.0, -0.16, -0.28)
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
				var fg := _view_model.foregrip_marker.position
				if fg.y > 0.08:
					# Top carry-handle grip (Chainstorm): compact left arm tucking cleanly beside receiver
					_fp_left_arm.position = fg + Vector3(-0.085, -0.055, -0.05)
					_fp_left_arm.rotation_degrees = Vector3(14.0, 20.0, -14.0)
				else:
					_fp_left_arm.position = fg - Vector3(0.0, -0.07, -0.22)
					_fp_left_arm.rotation = Vector3.ZERO
			elif _view_model.grip_marker != null:
				_fp_left_arm.visible = false
				_fp_left_arm.rotation = Vector3.ZERO
			else:
				_fp_left_arm.visible = true
				_fp_left_arm.position = Vector3.ZERO
				_fp_left_arm.rotation = Vector3.ZERO
			_fp_left_arm_rest_pos = _fp_left_arm.position
	if body_model != null:
		body_model.set_weapon(state.data, skin, atts)
		_set_model_layers(body_model, _body_layer_mask)
	Sfx.play(&"swap")


func _on_shot_feedback(state: WeaponState) -> void:
	var weapon := state.data
	var snd: StringName = weapon.sound
	var snd_pitch: float = weapon.sound_pitch
	var vol_db: float = -3.0
	var kick: float = state.get_recoil_kick() if state != null else weapon.recoil_kick
	var recoil_mult := float(state.modifiers.get("recoil_mult", 1.0)) if state != null else 1.0
	var shake_mult := float(state.modifiers.get("shake_mult", 1.0)) if state != null else 1.0
	var shake: float = weapon.camera_shake * recoil_mult * shake_mult
	if state != null and state.modifiers.has("sound_override") and not str(state.modifiers["sound_override"]).is_empty():
		snd = StringName(str(state.modifiers["sound_override"]))
		vol_db = -8.0
	Sfx.play(snd, snd_pitch, vol_db, 0.07)
	_recoil = minf(_recoil + kick, 1.6)
	_punch += 0.006 * kick
	add_trauma(shake)
	if _view_model != null:
		_view_model.flash(recoil_mult)
	if body_model != null and weapon.is_melee():
		body_model.play_melee_swing()
	GameSettings.vibrate(0.12 * kick + 0.05, 0.0, 0.06, player_index)
	shot_fired.emit(state)


func _on_landed_hit(_victim: Actor, was_tag: bool, _was_ricochet: bool) -> void:
	Sfx.play(&"tag" if was_tag else &"hit_confirm", 1.0, -2.0 if was_tag else -6.0, 0.05)
	if was_tag:
		GameSettings.vibrate(0.5, 0.2, 0.15, player_index)


func _on_melee_impact_juice() -> void:
	if GameSettings.camera_shake <= 0.01:
		return
	add_trauma(0.28)
	if _view_model != null:
		_view_model.trigger_hit_stop(0.042)
	GameSettings.vibrate(0.45, 0.35, 0.12, player_index)


func _on_hit_received(_attacker: Actor) -> void:
	add_trauma(0.25)
	GameSettings.vibrate(0.3, 0.45, 0.16, player_index)


func _tag_out(attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	_reloading = false
	_inspect_timer = 0.0
	if is_aiming_down_sights:
		is_aiming_down_sights = false
		aiming_changed.emit(false)
	super._tag_out(attacker, weapon, ricochet)
	Sfx.play(&"tagged")
	GameSettings.vibrate(0.8, 0.8, 0.4, player_index)


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
	_aim_query.collision_mask = Layers.WORLD | Layers.HITBOX | Layers.ACTORS
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
	if hit_actor != null and hit_actor != self and not hit_actor.is_zombie and hit_actor.alive and try_zombie_infect(hit_actor):
		Sfx.play(&"infect")
		Sfx.play(&"zombie_moan", 1.1, -1.0)
		GameSettings.vibrate(0.7, 0.7, 0.2, player_index)
	else:
		Sfx.play(&"whoosh", 1.2, -4.0, 0.05)


func _on_reload_started(_state: WeaponState, seconds: float) -> void:
	_reloading = true
	_reload_time = 0.0
	_reload_duration = maxf(seconds, 0.1)
	_reload_slapped = false
	_inspect_timer = 0.0
	if is_aiming_down_sights:
		is_aiming_down_sights = false
		aiming_changed.emit(false)
	Sfx.play(&"reload", 0.9)


func _on_reload_finished(_state: WeaponState) -> void:
	_reloading = false
	_reload_time = 0.0
	_reload_slapped = false
	if _fp_left_arm != null:
		_fp_left_arm.position = _fp_left_arm_rest_pos
		_fp_left_arm.rotation = Vector3.ZERO
	Sfx.play(&"reload", 1.2)


func _on_reload_cancelled(_state: WeaponState) -> void:
	_reloading = false
	_reload_time = 0.0
	_reload_slapped = false
	if _fp_left_arm != null:
		_fp_left_arm.position = _fp_left_arm_rest_pos
		_fp_left_arm.rotation = Vector3.ZERO


func _build_fp_arms() -> void:
	if _fp_arms != null:
		return
	_fp_arms = Node3D.new()
	_fp_arms.name = "FirstPersonArms"
	_view_root.add_child(_fp_arms)

	# Cover-Art stylized chromatic cel hoodie sleeves & cartoon hands with fine FP ink outlines
	var sleeve_sm := ArenaKit.toon_mat(color, 0.62, 0.30, 0.22, true, Color(0.22, 0.26, 0.56)).duplicate() as ShaderMaterial
	var cuff_sm := ArenaKit.toon_mat(color.darkened(0.16), 0.72, 0.20, 0.22, true, Color(0.18, 0.22, 0.48))
	var skin_sm := ArenaKit.toon_mat(Color(1.0, 0.80, 0.64), 0.58, 0.35, 0.22, true, Color(0.72, 0.38, 0.36))
	_sleeve_mat = sleeve_sm
	_skin_mat = skin_sm

	# Right Arm: chunky hoodie forearm, ribbed cuff & rounded cartoon gripping hand
	_fp_right_arm = Node3D.new()
	_fp_right_arm.name = "RightArm"
	_fp_arms.add_child(_fp_right_arm)
	var r_sleeve := _capsule_arm(_fp_right_arm, 0.044, 0.28, Vector3(0.11, -0.22, 0.17), sleeve_sm)
	r_sleeve.rotation_degrees = Vector3(50.0, -18.0, 14.0)
	var r_cuff := _fp_cyl(_fp_right_arm, 0.042, 0.047, 0.044, Vector3(0.050, -0.148, 0.102), cuff_sm, Vector3(50.0, -18.0, 14.0))
	r_cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r_palm := _fp_sphere(_fp_right_arm, 0.042, Vector3(0.012, -0.105, 0.062), skin_sm, Vector3(0.95, 1.10, 0.95))
	r_palm.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	var r_thumb := _fp_sphere(_fp_right_arm, 0.022, Vector3(-0.024, -0.082, 0.068), skin_sm, Vector3(0.85, 1.32, 0.95))
	r_thumb.rotation_degrees = Vector3(-18.0, 24.0, 28.0)

	# Left Arm: supporting hoodie forearm, ribbed cuff & rounded palm (seamless cuff-to-sleeve join!)
	_fp_left_arm = Node3D.new()
	_fp_left_arm.name = "LeftArm"
	_fp_arms.add_child(_fp_left_arm)
	var l_sleeve := _capsule_arm(_fp_left_arm, 0.044, 0.30, Vector3(-0.128, -0.205, 0.062), sleeve_sm)
	l_sleeve.rotation_degrees = Vector3(52.0, 26.0, -22.0)
	var l_cuff := _fp_cyl(_fp_left_arm, 0.042, 0.047, 0.052, Vector3(-0.072, -0.152, -0.025), cuff_sm, Vector3(52.0, 26.0, -22.0))
	l_cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l_palm := _fp_sphere(_fp_left_arm, 0.042, Vector3(-0.036, -0.122, -0.088), skin_sm, Vector3(1.10, 0.88, 1.04))
	l_palm.rotation_degrees = Vector3(12.0, 24.0, 0.0)
	var l_thumb := _fp_sphere(_fp_left_arm, 0.023, Vector3(0.008, -0.105, -0.085), skin_sm, Vector3(0.9, 1.25, 0.95))
	l_thumb.rotation_degrees = Vector3(10.0, -20.0, -32.0)

	if view_layer_mask != 1:
		_set_model_layers(_fp_arms, view_layer_mask)


func _build_zombie_arms() -> void:
	if _zombie_arms != null:
		return
	_zombie_arms = Node3D.new()
	_zombie_arms.name = "ZombieArms"
	_view_root.add_child(_zombie_arms)
	var z_sleeve := ArenaKit.toon_mat(Color(0.38, 0.78, 0.28), 0.65, 0.30, 0.24, true, Color(0.16, 0.42, 0.20))
	var z_hand := ArenaKit.toon_mat(Color(0.48, 0.86, 0.38), 0.55, 0.38, 0.24, true, Color(0.20, 0.48, 0.22))
	for side: float in [-1.0, 1.0]:
		var arm := _capsule_arm(_zombie_arms, 0.066, 0.42, Vector3(side * 0.22, -0.16, -0.36), z_sleeve)
		arm.rotation_degrees = Vector3(70.0, side * -12.0, 0.0)
		_fp_sphere(_zombie_arms, 0.056, Vector3(side * 0.22, -0.06, -0.52), z_hand, Vector3(1.0, 0.9, 1.15))
	if view_layer_mask != 1:
		_set_model_layers(_zombie_arms, view_layer_mask)


func _fp_sphere(parent: Node3D, radius: float, pos: Vector3, material: Material, s: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 10
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.position = pos
	inst.scale = s
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _fp_cyl(parent: Node3D, r_top: float, r_bot: float, height: float, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = height
	mesh.radial_segments = 16
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _capsule_arm(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func enable_body_model(layer_mask: int = 2) -> void:
	_body_layer_mask = layer_mask
	if body_model == null:
		body_model = CharacterModel.new()
		add_child(body_model)
		body_model.setup(display_name, color, hat_id)
		body_model.show_overhead(true)
		var current_w := arsenal.current()
		if current_w != null:
			var skin: StringName = skin_id if skin_id != &"default" else (GameSettings.player2_skin if player_index == 1 else GameSettings.player_skin)
			body_model.set_weapon(current_w.data, skin, current_w.attachments if current_w != null else {})
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

