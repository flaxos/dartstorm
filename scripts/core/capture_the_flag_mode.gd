class_name CaptureTheFlagMode
extends GameMode
## CAPTURE THE FLAG (CTF): Classic 2-team objective mode (Blue vs Orange).
## Each team defends a flag at their home base. Infiltrate the enemy fortress,
## seize their flag, and carry it across the battlefield back to your home base!
## Dropped flags can be recovered by teammates or stolen again by enemies.
## First team to 3 captures wins the match.

const WINNING_CAPTURES := 3
const CAPTURE_SCORE := 250

var team_captures: Dictionary = {0: 0, 1: 0}


func _init() -> void:
	id = &"capture_the_flag"
	display_name = "Capture The Flag"
	short_name = "CTF"
	description = "Infiltrate the enemy base, steal their flag, and bring it home! First team to 3 captures wins."
	teams = Teams.BLUE_VS_ORANGE
	duration_seconds = 360.0
	countdown_seconds = 3
	respawn_delay = 3.0
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10
	infinite_reserve = true


func is_ctf() -> bool:
	return true


func winning_team(board: Scoreboard) -> int:
	var by_caps := winning_team_by_caps()
	if by_caps >= 0:
		return by_caps
	return super.winning_team(board)


func reset_captures() -> void:
	team_captures[0] = 0
	team_captures[1] = 0


func record_capture(team: int) -> int:
	team_captures[team] = team_captures.get(team, 0) + 1
	return team_captures[team]


func get_captures(team: int) -> int:
	return team_captures.get(team, 0)


func is_won() -> bool:
	return team_captures.get(0, 0) >= WINNING_CAPTURES or team_captures.get(1, 0) >= WINNING_CAPTURES


func winning_team_by_caps() -> int:
	if team_captures.get(0, 0) >= WINNING_CAPTURES:
		return 0
	if team_captures.get(1, 0) >= WINNING_CAPTURES:
		return 1
	if team_captures.get(0, 0) > team_captures.get(1, 0):
		return 0
	if team_captures.get(1, 0) > team_captures.get(0, 0):
		return 1
	return -1


func get_early_winner(board: Scoreboard) -> ScoreEntry:
	var win_team := winning_team_by_caps()
	if win_team < 0 or (team_captures.get(0, 0) < WINNING_CAPTURES and team_captures.get(1, 0) < WINNING_CAPTURES):
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
			by_team[entry.team] = {"team": entry.team, "score": 0, "tags": 0, "caps": team_captures.get(entry.team, 0), "members": members}
		var team: Dictionary = by_team[entry.team]
		team["score"] += entry.score
		team["tags"] += entry.tags
		(team["members"] as Array[ScoreEntry]).append(entry)
	var out: Array[Dictionary] = []
	out.assign(by_team.values())
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_caps: int = a.get("caps", 0)
		var b_caps: int = b.get("caps", 0)
		if a_caps != b_caps:
			return a_caps > b_caps
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		if a["tags"] != b["tags"]:
			return a["tags"] > b["tags"]
		return a["team"] < b["team"])
	return out


func describe_progress(entry: ScoreEntry) -> String:
	return "%d/%d CAPS" % [get_captures(entry.team), WINNING_CAPTURES]
