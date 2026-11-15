class_name Player
extends Actor
## The human player: first-person camera, keyboard/mouse (and gamepad) input,
## the blaster held in view, and all the "feel" (recoil, bob, shake, sounds).

signal shot_fired(state: WeaponState)

const HEAD_HEIGHT := 1.62
const MOUSE_RADIANS_PER_PIXEL := 0.0022
const PAD_LOOK_SPEED := 2.8
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
var _sway: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _aim_query: PhysicsRayQueryParameters3D


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

	arsenal.weapon_changed.connect(_on_weapon_changed)
	arsenal.dry_fired.connect(func(_state: WeaponState) -> void: Sfx.play(&"dry"))
	arsenal.reload_started.connect(func(_state: WeaponState, _seconds: float) -> void: Sfx.play(&"reload", 0.9))
	arsenal.reload_finished.connect(func(_state: WeaponState) -> void: Sfx.play(&"reload", 1.2))
	landed_hit.connect(_on_landed_hit)
	ammo_collected.connect(func(_amount: int) -> void: Sfx.play(&"ammo", 1.0, -6.0, 0.1))


func _exit_tree() -> void:
	Sfx.set_spin(0.0)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var scale_factor := MOUSE_RADIANS_PER_PIXEL * GameSettings.mouse_sensitivity
		_look(-motion.relative.x * scale_factor, -motion.relative.y * scale_factor)
		_sway = (_sway + motion.relative * 0.00012).limit_length(0.03)
		return
	if not alive or not controls_enabled:
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
		_look(-pad_look.x * PAD_LOOK_SPEED * delta, -pad_look.y * PAD_LOOK_SPEED * delta)

	var wish := Vector3.ZERO
	var jump := false
	_sprinting = false
	if controls_enabled:
		var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = (global_transform.basis * Vector3(input.x, 0.0, input.y)).limit_length(1.0)
		_sprinting = Input.is_action_pressed(&"sprint") and input.y < -0.1
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer_left = JUMP_BUFFER
		arsenal.set_trigger(Input.is_action_pressed(&"fire"))
	else:
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
	var fov_target := GameSettings.fov + (SPRINT_FOV_BOOST if _sprinting else 0.0)
	camera.fov = lerpf(camera.fov, fov_target, minf(8.0 * delta, 1.0))

	# Blaster in view: bob while walking, sway with the mouse, kick on each shot.
	_recoil = lerpf(_recoil, 0.0, minf(14.0 * delta, 1.0))
	_swap = move_toward(_swap, 0.0, delta / Arsenal.SWAP_TIME)
	_sway = _sway.lerp(Vector2.ZERO, minf(10.0 * delta, 1.0))
	var speed := Vector2(velocity.x, velocity.z).length()
	var bob_amount := clampf(speed / walk_speed, 0.0, 1.4) if is_on_floor() else 0.0
	if bob_amount > 0.05:
		_bob_phase += delta * (6.0 + speed * 0.9)
	var bob := Vector3(cos(_bob_phase * 0.5) * 0.008, -absf(sin(_bob_phase * 0.5)) * 0.012, 0.0) * bob_amount
	var rattle := Vector3.ZERO
	var state := arsenal.current()
	var spin := 0.0
	if alive and state != null and state.data.fire_mode == WeaponData.FireMode.SPIN_UP:
		spin = arsenal.spin
		rattle = Vector3(sin(_time * 90.0), cos(_time * 77.0), 0.0) * 0.0025 * spin
	Sfx.set_spin(spin)
	if _view_model != null:
		_view_model.set_spin(spin)
	_view_root.visible = alive
	_view_root.position = _view_offset + bob + rattle + Vector3(-_sway.x, _sway.y - 0.35 * _swap, _recoil * 0.07)
	_view_root.rotation = Vector3(_recoil * 0.12 - _swap * 0.6, VIEW_YAW + _sway.x * 0.5, 0.0)


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


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	_pitch = clampf(_pitch + (-pitch if GameSettings.invert_y else pitch), -1.5, 1.5)
	head.rotation.x = _pitch


func respawn(at: Transform3D) -> void:
	super.respawn(at)
	_pitch = 0.0
	head.rotation.x = 0.0


func _on_weapon_changed(state: WeaponState) -> void:
	if _view_model != null:
		_view_model.queue_free()
		_view_model = null
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
	shot_fired.emit(state)


func _on_landed_hit(_victim: Actor, was_tag: bool, _was_ricochet: bool) -> void:
	Sfx.play(&"tag" if was_tag else &"hit_confirm", 1.0, -2.0 if was_tag else -6.0, 0.05)


func _on_hit_received(_attacker: Actor) -> void:
	add_trauma(0.25)


func _tag_out(attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	super._tag_out(attacker, weapon, ricochet)
	Sfx.play(&"tagged")
