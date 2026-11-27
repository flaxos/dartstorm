class_name WeaponState
extends RefCounted
## Runtime ammo for one weapon in someone's hands.

var data: WeaponData
var magazine: int = 0
var reserve: int = 0
## Gun Game hands out bottomless reserves.
var infinite_reserve: bool = false
var attachments: Dictionary = {}
var modifiers: Dictionary = {}


func _init(p_data: WeaponData, p_infinite_reserve: bool = false, p_attachments: Dictionary = {}, p_use_progression: bool = false, p_profile_idx: int = -1) -> void:
	data = p_data
	infinite_reserve = p_infinite_reserve
	attachments = {}
	for k in p_attachments:
		attachments[String(k)] = StringName(str(p_attachments[k]))
	if not attachments.is_empty():
		modifiers = WeaponModding.compute_attachment_modifiers(attachments)
	elif p_use_progression and is_instance_valid(Progression) and p_data != null:
		var raw_atts: Dictionary = Progression.get_equipped_attachments_for_profile(p_profile_idx, p_data.id) if p_profile_idx >= 0 and Progression.has_method(&"get_equipped_attachments_for_profile") else Progression.get_equipped_attachments(p_data.id)
		for k in raw_atts:
			attachments[String(k)] = StringName(str(raw_atts[k]))
		modifiers = WeaponModding.compute_attachment_modifiers(attachments)
	else:
		modifiers = WeaponModding.compute_attachment_modifiers({})
	magazine = get_magazine_size()
	var belt_bonus: int = int(modifiers.get("mag_bonus", 0)) * 5 if (data != null and data.is_belt_fed()) else 0
	var max_res: int = (data.reserve_max if data != null else 0) + belt_bonus
	var start_res: int = (data.reserve_start if data != null else 0) + belt_bonus
	reserve = max_res if infinite_reserve else start_res


## Effective magazine size accounting for extended drum or attachment modifiers.
func get_magazine_size() -> int:
	if data != null and data.is_belt_fed():
		return 0
	var base_size := data.magazine_size if data != null else 6
	var bonus: int = int(modifiers.get("mag_bonus", 0))
	return maxi(1, base_size + bonus)


## Effective reserve cap (belt-fed weapons gain extra drum capacity from magazine mods).
func get_reserve_max() -> int:
	var base_max := data.reserve_max if data != null else 0
	if data != null and data.is_belt_fed():
		return base_max + int(modifiers.get("mag_bonus", 0)) * 5
	return base_max


## Effective reload duration in seconds.
func get_reload_time() -> float:
	var base_time := data.reload_time if data != null else 1.5
	var mult: float = float(modifiers.get("reload_mult", 1.0))
	return maxf(0.2, base_time * mult)


## Effective interval between shots in seconds.
func get_shot_interval() -> float:
	var base_rate := data.shots_per_second if data != null else 3.0
	var mult: float = float(modifiers.get("rate_mult", 1.0))
	var effective_rate := maxf(0.1, base_rate * mult)
	return 1.0 / effective_rate


## Effective spread degrees.
func get_spread_degrees() -> float:
	var base_spread := data.spread_degrees if data != null else 2.0
	var mult: float = float(modifiers.get("spread_mult", 1.0))
	return maxf(0.05, base_spread * mult)


## Effective recoil kick multiplier.
func get_recoil_kick() -> float:
	var base_kick := data.recoil_kick if data != null else 1.0
	var mult: float = float(modifiers.get("recoil_mult", 1.0))
	return base_kick * mult


## Effective ADS zoom FOV (0.0 if no zoom).
func get_zoom_fov() -> float:
	var zoom: float = float(modifiers.get("zoom_fov", 0.0))
	if zoom > 0.0:
		return zoom
	return data.zoom_fov if data != null else 0.0


## Effective reticle type for ADS (&"standard", &"red_dot", &"holo", &"scope").
func get_reticle() -> StringName:
	var ret := StringName(str(modifiers.get("reticle", &"standard")))
	if ret == &"standard" and data != null and data.zoom_fov > 0.0 and data.zoom_fov <= 45.0:
		return &"scope"
	return ret


## Effective movement multiplier from equipped attachments (e.g. stocks).
func get_move_multiplier() -> float:
	return float(modifiers.get("move_mult", 1.0))


## Darts ready to fire right now.
func loaded() -> int:
	if data != null and data.is_melee():
		return 1
	return reserve if data.is_belt_fed() else magazine


func can_fire() -> bool:
	if data != null and data.is_melee():
		return true
	return loaded() > 0


func consume() -> void:
	if data != null and data.is_melee():
		return
	if data.is_belt_fed():
		if not infinite_reserve:
			reserve = maxi(reserve - 1, 0)
	else:
		magazine = maxi(magazine - 1, 0)


func can_reload() -> bool:
	if data != null and data.is_melee():
		return false
	return not data.is_belt_fed() and magazine < get_magazine_size() and reserve > 0


func reload() -> void:
	var wanted := get_magazine_size() - magazine
	var moved := mini(wanted, reserve)
	magazine += moved
	if not infinite_reserve:
		reserve -= moved


func missing() -> int:
	if infinite_reserve or (data != null and data.is_melee()):
		return 0
	return maxi(get_reserve_max() - reserve, 0)


## Adds darts to the reserve and returns how many were actually taken.
func add_ammo(amount: int) -> int:
	var taken := mini(amount, missing())
	reserve += taken
	return taken


func total() -> int:
	if data != null and data.is_melee():
		return 0
	return reserve if data.is_belt_fed() else magazine + reserve
