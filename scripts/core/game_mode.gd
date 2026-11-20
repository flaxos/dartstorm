class_name GameMode
extends Resource
## Rules for one way of playing. The base class is plain free-for-all; other
## modes subclass it and override the hooks. Modes are .tres files in
## resources/modes/, so numbers can be tuned in the Godot inspector.

enum Teams {
	## Everyone for themselves.
	SOLO,
	## Pairs: the player and one bot, against other pairs.
	DUOS,
	## Two big teams, half the players each.
	BLUE_VS_ORANGE,
}

enum TeamPalette {
	DEFAULT,
	COBALT_SUNBURST,
	MAGENTA_MINT,
	HIGH_CONTRAST,
}

const PALETTE_NAMES: Array[String] = [
	"Default (Blue / Orange)",
	"Cobalt & Sunburst",
	"Magenta & Mint",
	"High Contrast",
]

## Team names and colours, by team number. Blue and orange match the forts.
const TEAM_INFO: Array[Dictionary] = [
	{"name": "BLUE", "color": Color(0.15, 0.45, 1.0)},
	{"name": "ORANGE", "color": Color(1.0, 0.5, 0.1)},
	{"name": "GREEN", "color": Color(0.3, 0.82, 0.25)},
	{"name": "PURPLE", "color": Color(0.66, 0.4, 1.0)},
]

const TEAM_PALETTES := {
	TeamPalette.DEFAULT: TEAM_INFO,
	TeamPalette.COBALT_SUNBURST: [
		{"name": "COBALT", "color": Color(0.1, 0.4, 0.95)},
		{"name": "SUNBURST", "color": Color(1.0, 0.82, 0.1)},
		{"name": "EMERALD", "color": Color(0.2, 0.85, 0.45)},
		{"name": "AMETHYST", "color": Color(0.7, 0.35, 1.0)},
	],
	TeamPalette.MAGENTA_MINT: [
		{"name": "MAGENTA", "color": Color(0.96, 0.22, 0.62)},
		{"name": "MINT", "color": Color(0.25, 0.9, 0.68)},
		{"name": "CORAL", "color": Color(1.0, 0.52, 0.38)},
		{"name": "LAVENDER", "color": Color(0.68, 0.55, 0.98)},
	],
	TeamPalette.HIGH_CONTRAST: [
		{"name": "CYAN", "color": Color(0.05, 0.85, 1.0)},
		{"name": "HOT ORANGE", "color": Color(1.0, 0.32, 0.08)},
		{"name": "LIME", "color": Color(0.65, 0.95, 0.15)},
		{"name": "VIOLET", "color": Color(0.85, 0.25, 1.0)},
	],
}

@export var id: StringName = &"free_for_all"
@export var display_name: String = "Free-For-All"
## The word on the menu's mode card ("SOLO", "DUOS", ...).
@export var short_name: String = "SOLO"
@export_multiline var description: String = ""

@export_group("Teams")
@export var teams: Teams = Teams.SOLO

@export_group("Round")
@export var duration_seconds: float = 300.0
@export var countdown_seconds: int = 3
@export var respawn_delay: float = 3.0

@export_group("Scoring")
@export var points_per_tag: int = 100
@export var ricochet_bonus: int = 50
@export var points_per_target: int = 10

@export_group("Loadout")
## Blasters everyone carries, in slot order.
@export var loadout: Array[WeaponData] = []
@export var infinite_reserve: bool = false

@export_group("Power-up")
## The blaster that becomes a map power-up when power-up mode is on (the
## Chainstorm). It's taken out of everyone's loadout and spawns on the map.
@export var power_weapon: WeaponData
## Seconds of play before it first appears, and between pick-ups.
@export var power_weapon_first_delay: float = 20.0
@export var power_weapon_respawn: float = 45.0
## Darts on its belt when you grab it.
@export var power_weapon_belt: int = 300

## Set per match (on a duplicate of this resource) from the menu option.
var power_up_mode: bool = false


## Blasters this player should be holding right now. In power-up mode the
## power weapon is left out: you have to grab it from the map.
func get_loadout(_entry: ScoreEntry) -> Array[WeaponData]:
	if not power_up_mode or power_weapon == null:
		return loadout
	var held: Array[WeaponData] = []
	for weapon in loadout:
		if weapon != power_weapon and weapon.id != power_weapon.id:
			held.append(weapon)
	return held


func uses_power_up() -> bool:
	return power_up_mode and power_weapon != null


# --- Teams --------------------------------------------------------------------

func is_team_mode() -> bool:
	return teams != Teams.SOLO


## How many bots to bring so the teams come out even: in Duos and Blue vs
## Orange an odd number of players gets one extra bot.
func bots_for(requested: int) -> int:
	var humans := 2 if (GameSettings != null and GameSettings.split_screen) else 1
	if is_team_mode() and (requested + humans) % 2 == 1:
		return requested + 1
	return requested


## The team for the n-th player in the match (the human is number 0).
## In solo modes everyone gets their own number.
func team_for(index: int) -> int:
	match teams:
		Teams.DUOS:
			return floori(index / 2.0)
		Teams.BLUE_VS_ORANGE:
			return index % 2
	return index


static func get_palette_info() -> Array:
	var p: int = GameSettings.team_palette if (GameSettings != null and is_instance_valid(GameSettings)) else int(TeamPalette.DEFAULT)
	return TEAM_PALETTES.get(p, TEAM_INFO)


static func team_name(team: int) -> String:
	if team < 0:
		return ""
	var palette := get_palette_info()
	return str(palette[team % palette.size()]["name"])


static func team_color(team: int) -> Color:
	if team < 0:
		return Color.WHITE
	var palette := get_palette_info()
	return palette[team % palette.size()]["color"] as Color


func get_team_name(team: int) -> String:
	return team_name(team)


func get_team_color(team: int) -> Color:
	return team_color(team)


## Every team, best first: [{team, score, tags, members (best first)}].
## In solo modes each player is a "team" of one.
func rank_teams(board: Scoreboard) -> Array[Dictionary]:
	var by_team := {}
	for entry in _rank_players(board):
		if not by_team.has(entry.team):
			var members: Array[ScoreEntry] = []
			by_team[entry.team] = {"team": entry.team, "score": 0, "tags": 0, "members": members}
		var team: Dictionary = by_team[entry.team]
		team["score"] += entry.score
		team["tags"] += entry.tags
		(team["members"] as Array[ScoreEntry]).append(entry)
	var out: Array[Dictionary] = []
	out.assign(by_team.values())
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		if a["tags"] != b["tags"]:
			return a["tags"] > b["tags"]
		return a["team"] < b["team"])
	return out


## The winning team, or -1 if the top teams are level (a draw).
func winning_team(board: Scoreboard) -> int:
	var ranked := rank_teams(board)
	if ranked.is_empty():
		return -1
	if ranked.size() > 1 and ranked[0]["score"] == ranked[1]["score"] and ranked[0]["tags"] == ranked[1]["tags"]:
		return -1
	return ranked[0]["team"]


## Who stands on each podium step: the top three players, or in team modes
## the top three teams (everyone on a team shares its step).
func podium_places(board: Scoreboard) -> Array:
	var places: Array = []
	if not is_team_mode():
		for entry in rank(board):
			if places.size() >= 3:
				break
			var alone: Array[ScoreEntry] = [entry]
			places.append(alone)
		return places
	for team in rank_teams(board):
		if places.size() >= 3:
			break
		places.append(team["members"])
	return places


## Updates the attacker's entry for a tag and returns the points awarded.
func apply_tag(attacker: ScoreEntry, _victim: ScoreEntry, ricochet: bool) -> int:
	var points := points_per_tag + (ricochet_bonus if ricochet else 0)
	attacker.score += points
	return points


## Someone who has won outright before the timer runs out, or null.
func get_early_winner(_board: Scoreboard) -> ScoreEntry:
	return null


## Entries sorted best first. In team modes the best team's players come
## first (each team best player first), then the next team's, and so on.
func rank(board: Scoreboard) -> Array[ScoreEntry]:
	if not is_team_mode():
		return _rank_players(board)
	var sorted: Array[ScoreEntry] = []
	for team in rank_teams(board):
		sorted.append_array(team["members"])
	return sorted


func _rank_players(board: Scoreboard) -> Array[ScoreEntry]:
	var sorted: Array[ScoreEntry] = []
	sorted.assign(board.entries)
	sorted.sort_custom(_is_better)
	return sorted


## Short status for the HUD, e.g. the Gun Game rung.
func describe_progress(_entry: ScoreEntry) -> String:
	return ""


func _is_better(a: ScoreEntry, b: ScoreEntry) -> bool:
	if a.score != b.score:
		return a.score > b.score
	if a.tags != b.tags:
		return a.tags > b.tags
	return a.outs < b.outs


## Whether an actor who was tagged out should respawn on a timer.
func should_respawn(_actor: Actor) -> bool:
	return true
