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

var head: Node3D
var camera: Camera3D

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
var _assist_query: PhysicsRayQueryParameters3D
## Shown once per life when the Chainstorm reaches full spin.
var storm_mode_announced: bool = false
var _zombie_arms: Node3D
var _zombie_swipe: float = 0.0
var is_aiming_down_sights: bool = false


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
	arsenal.reload_started.connect(func(_state: WeaponState, _seconds: float) -> void: Sfx.play(&"reload", 0.9))
	arsenal.reload_finished.connect(func(_state: WeaponState) -> void: Sfx.play(&"reload", 1.2))
	landed_hit.connect(_on_landed_hit)
	ammo_collected.connect(func(_amount: int) -> void: Sfx.play(&"ammo", 1.0, -6.0, 0.1))
	respawned.connect(func(_actor: Actor) -> void: storm_mode_announced = false)


func _exit_tree() -> void:
	Sfx.set_spin(0.0)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var zoom_ratio := camera.fov / maxf(GameSettings.fov, 1.0) if is_aiming_down_sights else 1.0
		var scale_factor := MOUSE_RADIANS_PER_PIXEL * GameSettings.mouse_sensitivity * zoom_ratio
		_look(-motion.relative.x * scale_factor, -motion.relative.y * scale_factor)
		_sway_vel += Vector2(-motion.relative.x, motion.relative.y) * (0.0012 * zoom_ratio)
		return
	# Clicking back into the window after alt-tab grabs the mouse again
	# instead of firing a surprise shot.
	if event is InputEventMouseButton and event.is_action_pressed(&"fire") \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and controls_enabled \
			and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_fire_blocked_until_release = true
		get_viewport().set_input_as_handled()
		return
	if not alive or not controls_enabled or is_zombie:
		return
	if event.is_action_pressed(&"weapon_next"):
		arsenal.cycle(1)
	elif event.is_action_pressed(&"weapon_prev"):
		arsenal.cycle(-1)
	elif event.is_action_pressed(&"weapon_1"):
		arsenal.select(0)
	elif event.is_action_pressed(&"weapon_2"):
		arsenal.select(1)
	elif event.is_action_pressed(&"weapon_3"):
		arsenal.select(2)
	elif event.is_action_pressed(&"reload"):
		arsenal.request_reload()


func _physics_process(delta: float) -> void:
	tick_status(delta)
	if not alive:
		arsenal.set_trigger(false)
		return

	var pad_look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if pad_look.length_squared() > 0.0:
		var turn := pad_look_step(pad_look, delta)
		_look(turn.x, turn.y)

	var wish := Vector3.ZERO
	var jump := false
	_sprinting = false
	if controls_enabled:
		var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = (global_transform.basis * Vector3(input.x, 0.0, input.y)).limit_length(1.0)
		_sprinting = Input.is_action_pressed(&"sprint") and input.y < -0.1
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer_left = JUMP_BUFFER
		var fire_held := Input.is_action_pressed(&"fire")
		if _fire_blocked_until_release:
			if fire_held:
				fire_held = false
			else:
				_fire_blocked_until_release = false

		var current_w := arsenal.current()
		var wants_aim := Input.is_action_pressed(&"aim_down_sights") and not is_zombie and not _sprinting and current_w != null and current_w.data.zoom_fov > 0.0
		if wants_aim != is_aiming_down_sights:
			is_aiming_down_sights = wants_aim
			aiming_changed.emit(is_aiming_down_sights)

		if is_zombie:
			if is_aiming_down_sights:
				is_aiming_down_sights = false
				aiming_changed.emit(false)
			arsenal.set_trigger(false)
			if Input.is_action_just_pressed(&"fire") and not _fire_blocked_until_release:
				_perform_zombie_swipe()
				if wish.length_squared() > 0.05:
					lunge(wish.normalized(), 6.0)
		else:
			arsenal.set_trigger(fire_held)
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
	if is_aiming_down_sights and current_w != null and current_w.data.zoom_fov > 0.0:
		target_base_fov = current_w.data.zoom_fov
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
	_view_root.visible = alive and not (is_aiming_down_sights and camera.fov < GameSettings.fov - 10.0)
	_view_root.position = _view_offset + bob + idle + sprint_offset + rattle + Vector3(_sway_pos.x, -_sway_pos.y - 0.35 * _swap - _dip_pos, _recoil * 0.07)
	_view_root.rotation = Vector3(_recoil * 0.12 - _swap * 0.6 + sprint_rot.x - _dip_pos * 1.2, VIEW_YAW - _sway_pos.x * 0.5 + sprint_rot.y, sprint_rot.z - _sway_pos.x * 0.3)


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
		if _zombie_arms == null:
			_build_zombie_arms()
		_zombie_arms.visible = true
		_view_offset = Vector3(0.0, -0.15, -0.3)
		return
	if _zombie_arms != null:
		_zombie_arms.visible = false
	if state == null:
		return
	_view_model = BlasterModel.create(state.data, true)
	_view_root.add_child(_view_model)
	_view_offset = state.data.view_offset
	_swap = 1.0
	_recoil = 0.0
	Sfx.play(&"swap")


func _on_shot_feedback(state: WeaponState) -> void:
	var weapon := state.data
	Sfx.play(weapon.sound, weapon.sound_pitch, -3.0, 0.07)
	_recoil = minf(_recoil + weapon.recoil_kick, 1.6)
	_punch += 0.006 * weapon.recoil_kick
	add_trauma(weapon.camera_shake)
	if _view_model != null:
		_view_model.flash()
	GameSettings.vibrate(0.12 * weapon.recoil_kick + 0.05, 0.0, 0.06)
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
