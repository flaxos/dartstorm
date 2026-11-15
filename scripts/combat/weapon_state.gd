class_name WeaponState
extends RefCounted
## Runtime ammo for one weapon in someone's hands.

var data: WeaponData
var magazine: int = 0
var reserve: int = 0
## Gun Game hands out bottomless reserves.
var infinite_reserve: bool = false


func _init(p_data: WeaponData, p_infinite_reserve: bool = false) -> void:
	data = p_data
	infinite_reserve = p_infinite_reserve
	magazine = data.magazine_size
	reserve = data.reserve_max if infinite_reserve else data.reserve_start


## Darts ready to fire right now.
func loaded() -> int:
	return reserve if data.is_belt_fed() else magazine


func can_fire() -> bool:
	return loaded() > 0


func consume() -> void:
	if data.is_belt_fed():
		if not infinite_reserve:
			reserve = maxi(reserve - 1, 0)
	else:
		magazine = maxi(magazine - 1, 0)


func can_reload() -> bool:
	return not data.is_belt_fed() and magazine < data.magazine_size and reserve > 0


func reload() -> void:
	var wanted := data.magazine_size - magazine
	var moved := mini(wanted, reserve)
	magazine += moved
	if not infinite_reserve:
		reserve -= moved


func missing() -> int:
	if infinite_reserve:
		return 0
	return maxi(data.reserve_max - reserve, 0)


## Adds darts to the reserve and returns how many were actually taken.
func add_ammo(amount: int) -> int:
	var taken := mini(amount, missing())
	reserve += taken
	return taken


func total() -> int:
	return reserve if data.is_belt_fed() else magazine + reserve
