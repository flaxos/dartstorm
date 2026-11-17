class_name ZombieMode
extends GameMode
## ZOMBIES Mode: 1 player/bot begins as the Alpha Zombie ("Patient Zero").
## All other players are Survivors armed with blasters.
## Touching a survivor infects them into a green foam zombie!
## Survivors win if anyone survives when time runs out.
## Zombies win early if all survivors are infected.

const SURVIVOR_TEAM := 0
const ZOMBIE_TEAM := 1
const ZOMBIE_COLOR := Color(0.38, 0.78, 0.28)
const SURVIVOR_COLOR := Color(0.2, 0.6, 1.0)


func _init() -> void:
	id = &"zombies"
	display_name = "Zombies"
	short_name = "ZOMBIES"
	description = "Survive the green foam zombie outbreak! Darts knock them back, but one touch turns you."
	teams = Teams.BLUE_VS_ORANGE
	duration_seconds = 180.0
	countdown_seconds = 3
	respawn_delay = 2.0
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10


func is_team_mode() -> bool:
	return true


func bots_for(requested: int) -> int:
	return requested


func team_for(_index: int) -> int:
	# Everyone defaults to survivor team; alpha zombie is assigned at match start.
	return SURVIVOR_TEAM


func get_loadout(entry: ScoreEntry) -> Array[WeaponData]:
	if entry.team == ZOMBIE_TEAM:
		return []
	return loadout


func apply_tag(attacker: ScoreEntry, victim: ScoreEntry, ricochet: bool) -> int:
	if attacker.team == ZOMBIE_TEAM and victim.team == SURVIVOR_TEAM:
		victim.team = ZOMBIE_TEAM
		victim.color = ZOMBIE_COLOR
		var points := 150
		attacker.score += points
		return points
	elif attacker.team == SURVIVOR_TEAM and victim.team == ZOMBIE_TEAM:
		var points := points_per_tag + (ricochet_bonus if ricochet else 0)
		attacker.score += points
		return points
	return super.apply_tag(attacker, victim, ricochet)


func count_survivors(board: Scoreboard) -> int:
	var count := 0
	for entry in board.entries:
		if entry.team == SURVIVOR_TEAM:
			count += 1
	return count


func count_zombies(board: Scoreboard) -> int:
	var count := 0
	for entry in board.entries:
		if entry.team == ZOMBIE_TEAM:
			count += 1
	return count


func get_early_winner(board: Scoreboard) -> ScoreEntry:
	if count_survivors(board) == 0:
		for entry in rank(board):
			if entry.team == ZOMBIE_TEAM:
				return entry
	return null


func winning_team(board: Scoreboard) -> int:
	if count_survivors(board) > 0:
		return SURVIVOR_TEAM
	return ZOMBIE_TEAM


func rank_teams(board: Scoreboard) -> Array[Dictionary]:
	var by_team := {}
	for t in [SURVIVOR_TEAM, ZOMBIE_TEAM]:
		var members: Array[ScoreEntry] = []
		by_team[t] = {"team": t, "score": 0, "tags": 0, "members": members}
	for entry in _rank_players(board):
		if by_team.has(entry.team):
			var team_dict: Dictionary = by_team[entry.team]
			team_dict["score"] += entry.score
			team_dict["tags"] += entry.tags
			(team_dict["members"] as Array[ScoreEntry]).append(entry)
	var winner := winning_team(board)
	var loser := ZOMBIE_TEAM if winner == SURVIVOR_TEAM else SURVIVOR_TEAM
	var out: Array[Dictionary] = []
	if by_team.has(winner) and not (by_team[winner]["members"] as Array).is_empty():
		out.append(by_team[winner])
	if by_team.has(loser) and not (by_team[loser]["members"] as Array).is_empty():
		out.append(by_team[loser])
	return out


func get_team_name(team: int) -> String:
	match team:
		SURVIVOR_TEAM:
			return "SURVIVORS"
		ZOMBIE_TEAM:
			return "ZOMBIES"
	return "SURVIVORS"


func get_team_color(team: int) -> Color:
	match team:
		SURVIVOR_TEAM:
			return SURVIVOR_COLOR
		ZOMBIE_TEAM:
			return ZOMBIE_COLOR
	return Color.WHITE


func describe_progress(entry: ScoreEntry) -> String:
	if entry.team == ZOMBIE_TEAM:
		return "ZOMBIE (INFECT SURVIVORS!)"
	return "SURVIVOR (HOLD OUT!)"
