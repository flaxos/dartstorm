class_name Arsenal
extends Node
## Runtime firing behaviour for whatever blasters an Actor is carrying.
## It decides *when* a shot happens (fire rate, spin-up, reloads, ammo) and emits
## `fired`; the owning Actor decides *where* the darts go.

signal weapon_changed(state: WeaponState)
signal ammo_changed(state: WeaponState)
signal fired(state: WeaponState)
signal dry_fired(state: WeaponState)
signal reload_started(state: WeaponState, seconds: float)
signal reload_finished(state: WeaponState)

const SWAP_TIME := 0.3
const MAX_SHOTS_PER_TICK := 4

var weapons: Array[WeaponState] = []
var current_index: int = -1
var enabled: bool = true
var trigger_held: bool = false
## Barrel spin for SPIN_UP weapons, 0..1.
var spin: float = 0.0

var _cooldown: float = 0.0
var _reload_left: float = 0.0
var _reload_total: float = 0.0
var _semi_latched: bool = false
var _dry_latched: bool = false


func set_loadout(list: Array[WeaponData], infinite_reserve: bool = false) -> void:
	weapons.clear()
	for data in list:
		if data != null:
			weapons.append(WeaponState.new(data, infinite_reserve))
	current_index = -1
	_reload_left = 0.0
	spin = 0.0
	if not weapons.is_empty():
		select(0, true)


func current() -> WeaponState:
	if current_index < 0 or current_index >= weapons.size():
		return null
	return weapons[current_index]


func select(index: int, instant: bool = false) -> void:
	if index < 0 or index >= weapons.size() or index == current_index:
		return
	current_index = index
	_reload_left = 0.0
	spin = 0.0
	_cooldown = 0.0 if instant else SWAP_TIME
	_semi_latched = trigger_held
	weapon_changed.emit(current())
	ammo_changed.emit(current())


func cycle(step: int) -> void:
	if weapons.size() < 2:
		return
	select(posmod(current_index + step, weapons.size()))


func set_trigger(held: bool) -> void:
	trigger_held = held and enabled


func request_reload() -> void:
	var state := current()
	if state == null or _reload_left > 0.0 or not state.can_reload():
		return
	_reload_total = state.data.reload_time
	_reload_left = _reload_total
	reload_started.emit(state, _reload_total)


func is_reloading() -> bool:
	return _reload_left > 0.0


## 0..1 progress of the current reload (1 when not reloading).
func reload_progress() -> float:
	if _reload_left <= 0.0 or _reload_total <= 0.0:
		return 1.0
	return 1.0 - _reload_left / _reload_total


## Hands out darts to the held weapon first, then the rest. Returns darts taken.
func add_ammo(amount: int) -> int:
	var left := amount
	var order: Array[WeaponState] = []
	if current() != null:
		order.append(current())
	for state in weapons:
		if state != current():
			order.append(state)
	for state in order:
		if left <= 0:
			break
		left -= state.add_ammo(left)
	var taken := amount - left
	if taken > 0 and current() != null:
		ammo_changed.emit(current())
	return taken


func total_ammo() -> int:
	var sum := 0
	for state in weapons:
		sum += state.total()
	return sum


func total_missing() -> int:
	var sum := 0
	for state in weapons:
		sum += state.missing()
	return sum


## Heavy weapons slow their owner while firing or spun up.
func get_move_multiplier() -> float:
	var state := current()
	if state == null:
		return 1.0
	if state.data.fire_mode == WeaponData.FireMode.SPIN_UP:
		return lerpf(1.0, state.data.firing_move_multiplier, clampf(spin * 2.0, 0.0, 1.0))
	if trigger_held and state.can_fire():
		return state.data.firing_move_multiplier
	return 1.0


func _physics_process(delta: float) -> void:
	var state := current()
	if state == null:
		return
	var data := state.data
	_cooldown -= delta

	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			state.reload()
			reload_finished.emit(state)
			ammo_changed.emit(state)

	var held := trigger_held and enabled
	if data.fire_mode == WeaponData.FireMode.SPIN_UP:
		var spinning := held and state.can_fire()
		var seconds := data.spin_up_time if spinning else data.spin_down_time
		spin = move_toward(spin, 1.0 if spinning else 0.0, delta / maxf(seconds, 0.01))
	else:
		spin = 0.0

	var shot := false
	if held and _reload_left <= 0.0:
		if not state.can_fire():
			if state.can_reload():
				request_reload()
			elif not _dry_latched:
				_dry_latched = true
				dry_fired.emit(state)
		else:
			match data.fire_mode:
				WeaponData.FireMode.SEMI:
					if not _semi_latched and _cooldown <= 0.0:
						_semi_latched = true
						_shoot(state)
						_cooldown = data.shot_interval()
						shot = true
				WeaponData.FireMode.AUTO:
					shot = _auto_fire(state)
				WeaponData.FireMode.SPIN_UP:
					if spin >= 1.0:
						shot = _auto_fire(state)
	if not held:
		_semi_latched = false
		_dry_latched = false
		# Top up an empty magazine automatically so nobody is stuck clicking.
		if _reload_left <= 0.0 and not state.can_fire() and state.can_reload():
			request_reload()
	if not shot:
		_cooldown = maxf(_cooldown, 0.0)


func _auto_fire(state: WeaponState) -> bool:
	var shots := 0
	while _cooldown <= 0.0 and shots < MAX_SHOTS_PER_TICK and state.can_fire():
		_shoot(state)
		_cooldown += state.data.shot_interval()
		shots += 1
	return shots > 0


func _shoot(state: WeaponState) -> void:
	state.consume()
	fired.emit(state)
	ammo_changed.emit(state)
