class_name GameMode
extends Resource
## Rules for one way of playing. The base class is plain free-for-all; other
## modes subclass it and override the hooks. Modes are .tres files in
## resources/modes/, so numbers can be tuned in the Godot inspector.

@export var id: StringName = &"free_for_all"
@export var display_name: String = "Free-For-All"
@export_multiline var description: String = ""

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


## Blasters this player should be holding right now.
func get_loadout(_entry: ScoreEntry) -> Array[WeaponData]:
	return loadout


## Updates the attacker's entry for a tag and returns the points awarded.
func apply_tag(attacker: ScoreEntry, _victim: ScoreEntry, ricochet: bool) -> int:
	var points := points_per_tag + (ricochet_bonus if ricochet else 0)
	attacker.score += points
	return points


## Someone who has won outright before the timer runs out, or null.
func get_early_winner(_board: Scoreboard) -> ScoreEntry:
	return null


## Entries sorted best first.
func rank(board: Scoreboard) -> Array[ScoreEntry]:
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
