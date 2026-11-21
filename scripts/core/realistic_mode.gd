class_name RealisticMode
extends GameMode
## REALISTIC MODE: Tactical foam combat with authentic playground rules.
## 1. When tagged, you do NOT disappear or teleport. Instead, your blaster is locked
##    and you must physically run back to your team base to touch in and revive!
## 2. Every spent foam dart persists in the arena instead of vanishing.
## 3. Players and bots have a finite dart supply and must scavenge fallen darts
##    off the ground to restock their blasters.

func _init() -> void:
	id = &"realistic"
	display_name = "Realistic Mode"
	short_name = "REALISTIC"
	description = "When tagged, sprint back to your base to re-enter! Darts persist on the ground to scavenge with finite ammo."
	teams = Teams.BLUE_VS_ORANGE
	duration_seconds = 300.0
	countdown_seconds = 3
	respawn_delay = 0.0
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10
	infinite_reserve = false


func is_realistic() -> bool:
	return true


func should_respawn(_actor: Actor) -> bool:
	# Realistic mode does NOT use timer-based vanishing respawn;
	# actors must physically run back to their home base!
	return false
