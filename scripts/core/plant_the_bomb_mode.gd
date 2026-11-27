class_name PlantTheBombMode
extends GameMode
## PLANT THE BOMB: Tactical round-based objective mode (Search & Destroy).
## Orange (Infiltrators/Attackers) carry the foam bomb to plant at Site A or Site B.
## Blue (Guardians/Defenders) must protect the sites and defuse the planted bomb.
## First team to win 3 rounds wins the match.

const WINNING_ROUNDS := 3
const PLANT_SCORE := 150
const DEFUSE_SCORE := 250
const DETONATION_SCORE := 250

var team_rounds: Dictionary = {0: 0, 1: 0}
var current_round: int = 1


func _init() -> void:
	id = &"plant_the_bomb"
	display_name = "Plant The Bomb"
	short_name = "BOMB"
	description = "Infiltrators must plant the foam bomb at Site A or B. Guardians must defuse it or eliminate attackers! First to 3 rounds wins."
	teams = Teams.BLUE_VS_ORANGE
	duration_seconds = 420.0
	countdown_seconds = 3
	respawn_delay = 0.0 # Round elimination / reset
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10
	infinite_reserve = true


func is_plant_the_bomb() -> bool:
	return true


func should_respawn(_actor: Actor) -> bool:
	return false


func get_team_name(team: int) -> String:
	return "GUARDIANS" if team == 0 else "INFILTRATORS"


func winning_team(board: Scoreboard) -> int:
	var by_rounds := winning_team_by_rounds()
	if by_rounds >= 0:
		return by_rounds
	return super.winning_team(board)


func reset_rounds() -> void:
	team_rounds[0] = 0
	team_rounds[1] = 0
	current_round = 1


func record_round_win(team: int) -> int:
	team_rounds[team] = team_rounds.get(team, 0) + 1
	current_round += 1
	return team_rounds[team]


func get_rounds(team: int) -> int:
	return team_rounds.get(team, 0)


func is_won() -> bool:
	return team_rounds.get(0, 0) >= WINNING_ROUNDS or team_rounds.get(1, 0) >= WINNING_ROUNDS


func winning_team_by_rounds() -> int:
	if team_rounds.get(0, 0) >= WINNING_ROUNDS:
		return 0
	if team_rounds.get(1, 0) >= WINNING_ROUNDS:
		return 1
	if team_rounds.get(0, 0) > team_rounds.get(1, 0):
		return 0
	if team_rounds.get(1, 0) > team_rounds.get(0, 0):
		return 1
	return -1


func get_early_winner(board: Scoreboard) -> ScoreEntry:
	var win_team := winning_team_by_rounds()
	if win_team < 0 or (team_rounds.get(0, 0) < WINNING_ROUNDS and team_rounds.get(1, 0) < WINNING_ROUNDS):
		return null
	var best: ScoreEntry = null
	for entry in board.entries:
		if entry.team == win_team:
			if best == null or entry.score > best.score:
				best = entry
	return best


func rank_teams(board: Scoreboard) -> Array[Dictionary]:
	var by_team := {}
	for entry in _rank_players(board):
		if not by_team.has(entry.team):
			var members: Array[ScoreEntry] = []
			by_team[entry.team] = {"team": entry.team, "score": 0, "tags": 0, "rounds": team_rounds.get(entry.team, 0), "members": members}
		var team: Dictionary = by_team[entry.team]
		team["score"] += entry.score
		team["tags"] += entry.tags
		(team["members"] as Array[ScoreEntry]).append(entry)
	var out: Array[Dictionary] = []
	out.assign(by_team.values())
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_rds: int = a.get("rounds", 0)
		var b_rds: int = b.get("rounds", 0)
		if a_rds != b_rds:
			return a_rds > b_rds
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		if a["tags"] != b["tags"]:
			return a["tags"] > b["tags"]
		return a["team"] < b["team"])
	return out


func describe_progress(entry: ScoreEntry) -> String:
	return "%d/%d RDS" % [get_rounds(entry.team), WINNING_ROUNDS]
