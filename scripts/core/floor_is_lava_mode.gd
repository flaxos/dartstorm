class_name FloorIsLavaMode
extends GameMode
## Floor is Lava Mode: Molten cartoon foam lava rises from the ground level.
## Players and bots must parkour across elevated platforms, fort walkways,
## crates, and trampolines. Water and Ice darts create temporary obsidian stepping stones.

var lava_director: LavaDirector
var lava_hazard: LavaHazard


func _init() -> void:
	id = &"floor_is_lava"
	display_name = "Floor is Lava"
	short_name = "LAVA"
	description = "The floor is rising molten foam lava! Scramble to high ground and shoot water darts to make stepping stones."
	teams = Teams.SOLO
	duration_seconds = 300.0
	countdown_seconds = 3
	respawn_delay = 3.0
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10


func is_team_mode() -> bool:
	return false


func bots_for(requested: int) -> int:
	return requested


func team_for(index: int) -> int:
	return index


func apply_tag(attacker: ScoreEntry, victim: ScoreEntry, ricochet: bool) -> int:
	var points := points_per_tag + (ricochet_bonus if ricochet else 0)
	# Check if victim was in or near lava level when tagged out for bonus
	if lava_hazard != null and victim.actor != null and is_instance_valid(victim.actor):
		if victim.actor.global_position.y <= lava_hazard.current_lava_y + 0.6:
			points += 50
	attacker.score += points
	return points


func on_high_tide_survived(board: Scoreboard) -> void:
	if board == null:
		return
	for entry in board.entries:
		if entry.actor != null and is_instance_valid(entry.actor) and entry.actor.alive:
			entry.score += 25


func describe_progress(_entry: ScoreEntry) -> String:
	if lava_director == null:
		return "THE FLOOR IS LAVA!"
	match lava_director.phase:
		LavaDirector.Phase.CALM:
			return "FLOOR SAFE • %ds" % int(ceilf(lava_director.time_left))
		LavaDirector.Phase.WARNING:
			return "LAVA RISING IN %ds!" % int(ceilf(lava_director.time_left))
		LavaDirector.Phase.RISING:
			return "LAVA RISING! GET UP!"
		LavaDirector.Phase.HIGH_TIDE:
			return "HIGH TIDE • %ds" % int(ceilf(lava_director.time_left))
		LavaDirector.Phase.RECEDING:
			return "LAVA RECEDING..."
	return "FLOOR IS LAVA"
