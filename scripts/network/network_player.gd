class_name NetworkPlayer
extends Actor
## Represents a remote human player in an online multiplayer match.
## Controlled via network state replication packets rather than local keyboard/mouse.

var peer_id: int = 0
var skin_id: StringName = &"default"
var _model: CharacterModel
var _target_position: Vector3 = Vector3.ZERO
var _target_rotation_y: float = 0.0
var _target_pitch: float = 0.0
var _target_velocity: Vector3 = Vector3.ZERO
var _is_aiming: bool = false
var _is_sprinting: bool = false
var _has_received_state: bool = false


func _ready() -> void:
	hitbox_radius = 0.45
	super._ready()
	is_human = true

	_model = CharacterModel.new()
	_model.name = "Model"
	add_child(_model)
	_model.setup(display_name, color, hat_id)
	_model.show_overhead(true)

	arsenal.weapon_changed.connect(_on_weapon_changed)
	var current_w := arsenal.current()
	if current_w != null:
		_model.set_weapon(current_w.data, skin_id)
	damage_received.connect(func(_att: Actor, _amt: float) -> void:
		if _model != null:
			_model.trigger_hit_flash())
	respawned.connect(func(_a: Actor) -> void:
		if _model != null:
			_model.clear_elemental_visuals())
	if elemental != null:
		elemental.status_started.connect(func(el: DartData.Element, _dur: float) -> void:
			if _model != null:
				_model.set_elemental_visual(el, true))
		elemental.status_ended.connect(func(el: DartData.Element) -> void:
			if _model != null:
				_model.set_elemental_visual(el, false))

	_target_position = position
	_target_rotation_y = rotation.y


func setup_profile(p_peer_id: int, p_name: String, p_color: Color, p_hat: StringName, p_skin: StringName) -> void:
	peer_id = p_peer_id
	display_name = p_name
	color = p_color
	hat_id = p_hat
	skin_id = p_skin
	if _model != null:
		_model.setup(display_name, color, hat_id)
		var current_w := arsenal.current()
		if current_w != null:
			_model.set_weapon(current_w.data, skin_id)


func apply_network_state(pos: Vector3, rot_y: float, pitch: float, vel: Vector3, aiming: bool, sprinting: bool) -> void:
	if not pos.is_finite() or not vel.is_finite() or not is_finite(rot_y) or not is_finite(pitch):
		return
	_target_position = pos
	_target_rotation_y = rot_y
	_target_pitch = pitch
	_target_velocity = vel
	_is_aiming = aiming
	_is_sprinting = sprinting
	if not _has_received_state:
		position = pos
		rotation.y = rot_y
		_has_received_state = true


func _physics_process(delta: float) -> void:
	tick_status(delta)
	if not alive:
		return

	# Smoothly interpolate transform towards target
	position = position.lerp(_target_position, clampf(18.0 * delta, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, _target_rotation_y, clampf(18.0 * delta, 0.0, 1.0))
	velocity = _target_velocity

	# Animate third person model
	var speed_h := Vector2(velocity.x, velocity.z).length()
	_model.animate(speed_h, delta)
	_model.set_aim_pitch(_target_pitch)
	_model.set_meter(tag_meter / maxf(tag_meter_max, 1.0))
	_model.set_shield_visible(shield_points > 0.0)


func fire_network_dart(weapon_idx: int, origin: Vector3, dir: Vector3, charge: float, element: int) -> void:
	if dart_pool == null:
		return
	var weapon_data: WeaponData = null
	if weapon_idx >= 0 and weapon_idx < arsenal.weapons.size():
		weapon_data = arsenal.weapons[weapon_idx].data
	if weapon_data == null:
		var cur := arsenal.current()
		if cur != null:
			weapon_data = cur.data
	if weapon_data == null or weapon_data.dart == null:
		return

	# Flash weapon model
	var held := _model.get_weapon()
	if held != null:
		held.flash()

	# Audio
	Sfx.play_at(weapon_data.sound, origin, weapon_data.sound_pitch, -4.0, 0.08)

	# Launch dart projectile via dart_pool.fire()
	var elem_enum := clampi(element, 0, 5) as DartData.Element
	var dart_data := weapon_data.dart
	if elem_enum != DartData.Element.NONE:
		dart_data = _get_infused_dart_data(dart_data, elem_enum)
	var exclude: Array[RID] = [hitbox.get_rid(), get_rid()]
	var dart := dart_pool.fire(dart_data, origin, dir.normalized(), self, weapon_data, color, exclude)
	if dart != null and charge != 1.0:
		dart.velocity *= lerpf(0.85, 1.15, clampf(charge, 0.0, 1.0))


func _set_body_visible(shown: bool) -> void:
	if _model != null:
		_model.visible = shown


func _on_zombie_state_changed(enabled: bool) -> void:
	if _model != null:
		_model.set_zombie(enabled)


func _on_weapon_changed(state: WeaponState) -> void:
	if is_zombie:
		_model.set_weapon(null)
		return
	_model.set_weapon(state.data if state != null else null, skin_id, state.attachments if state != null else {})
