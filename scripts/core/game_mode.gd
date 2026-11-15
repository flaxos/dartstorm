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
