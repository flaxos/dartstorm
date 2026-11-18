class_name ZombieSiegeMode
extends GameMode
## Zombie Siege Mode: Co-op Base Defense mode.
## Defenders (players + friendly bots on Team 0) protect a central Base Core against
## 5 escalating waves of green foam zombie hordes orchestrated by the HordeDirector.
## Features destructible barricades, wave intermission fortification, and the Mega Foam Titan Boss.

const DEFENDER_TEAM := 0
const ZOMBIE_TEAM := 1
const DEFENDER_COLOR := Color(0.2, 0.6, 1.0)
const ZOMBIE_COLOR := Color(0.38, 0.78, 0.28)

var base_core: BaseCore
var horde_director: HordeDirector
var barricades: Array[BaseBarricade] = []


func _init() -> void:
	id = &"zombie_siege"
	display_name = "Zombie Siege"
	short_name = "SIEGE"
	description = "Defend the Base Core against escalating waves of green foam zombies and the Mega Titan Boss!"
	teams = Teams.BLUE_VS_ORANGE
	duration_seconds = 900.0
	countdown_seconds = 3
	respawn_delay = 3.0
	points_per_tag = 100
	ricochet_bonus = 50
	points_per_target = 10


func is_team_mode() -> bool:
	return true


func bots_for(requested: int) -> int:
	return requested


func team_for(_index: int) -> int:
	# Starting actors (player and friendly bots) are all Defenders
	return DEFENDER_TEAM


func should_respawn(actor: Actor) -> bool:
	# Defenders respawn; horde zombies are eliminated upon tag out
	return not actor.is_zombie


func get_loadout(_entry: ScoreEntry) -> Array[WeaponData]:
	return loadout


func apply_tag(attacker: ScoreEntry, _victim: ScoreEntry, ricochet: bool) -> int:
	var points := points_per_tag + (ricochet_bonus if ricochet else 0)
	attacker.score += points
	return points


func get_early_winner(board: Scoreboard) -> ScoreEntry:
	if base_core != null and base_core.is_destroyed:
		for entry in rank(board):
			if entry.team == ZOMBIE_TEAM:
				return entry
	elif horde_director != null and horde_director.state == HordeDirector.State.VICTORY:
		for entry in rank(board):
			if entry.team == DEFENDER_TEAM:
				return entry
	return null


func winning_team(_board: Scoreboard) -> int:
	if horde_director != null and horde_director.state == HordeDirector.State.VICTORY:
		return DEFENDER_TEAM
	if base_core != null and base_core.is_destroyed:
		return ZOMBIE_TEAM
	return DEFENDER_TEAM


func get_team_name(team: int) -> String:
	match team:
		DEFENDER_TEAM:
			return "DEFENDERS"
		ZOMBIE_TEAM:
			return "ZOMBIE HORDE"
	return "DEFENDERS"


func get_team_color(team: int) -> Color:
	match team:
		DEFENDER_TEAM:
			return DEFENDER_COLOR
		ZOMBIE_TEAM:
			return ZOMBIE_COLOR
	return Color.WHITE


func describe_progress(_entry: ScoreEntry) -> String:
	if horde_director != null and horde_director.current_wave > 0:
		return "WAVE %d / 5 • DEFEND THE BASE!" % horde_director.current_wave
	return "DEFEND THE BASE!"
