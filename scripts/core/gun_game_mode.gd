class_name GunGameMode
extends GameMode
## Gun Game: everyone starts on the first rung of the weapon ladder, and each tag
## moves you up to the next blaster. Tag someone with the last blaster to win.
## The ladder is just an exported array: add weapons in the inspector, no code.

@export_group("Ladder")
@export var ladder: Array[WeaponData] = []
@export var tags_per_tier: int = 1


func get_loadout(entry: ScoreEntry) -> Array[WeaponData]:
	var held: Array[WeaponData] = []
	if ladder.is_empty():
		return held
	held.append(ladder[clampi(entry.tier, 0, ladder.size() - 1)])
	return held


func apply_tag(attacker: ScoreEntry, victim: ScoreEntry, ricochet: bool) -> int:
	var points := super.apply_tag(attacker, victim, ricochet)
	attacker.tier_progress += 1
	if attacker.tier_progress >= tags_per_tier:
		attacker.tier_progress = 0
		attacker.tier += 1
	return points


func get_early_winner(board: Scoreboard) -> ScoreEntry:
	for entry in board.entries:
		if entry.tier >= ladder.size():
			return entry
	return null


func describe_progress(entry: ScoreEntry) -> String:
	return "BLASTER %d / %d" % [mini(entry.tier + 1, ladder.size()), ladder.size()]


func _is_better(a: ScoreEntry, b: ScoreEntry) -> bool:
	if a.tier != b.tier:
		return a.tier > b.tier
	return super._is_better(a, b)
