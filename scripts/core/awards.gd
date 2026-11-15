class_name Awards
extends RefCounted
## Silly end-of-match awards. Each award goes to whoever has the most of one
## stat, as long as they reach a minimum (no "Ricochet King" for zero ricochets).
## Ties go to the higher-ranked player, so pass entries best-first.

## [title, stat key, minimum, description format]
const RULES: Array = [
	["Ricochet King", "ricochet_tags", 1, "%d ricochet tags"],
	["Storm Bringer", "storm_darts", 60, "%d Chainstorm darts"],
	["Bucket Hog", "darts_collected", 60, "%d darts scooped"],
	["Bullseye Boss", "targets_hit", 1, "%d bullseyes"],
	["Hot Streak", "best_streak", 3, "%d tags in a row"],
	["Foam Magnet", "outs", 3, "tagged %d times"],
]
## Sharpshooter is the best hit rate, after firing at least this many darts.
const SHARPSHOOTER_MIN_DARTS := 20
const SHARPSHOOTER_MIN_ACCURACY := 0.25
const MAX_AWARDS := 5


## Returns up to MAX_AWARDS awards as {title, entry, detail}.
static func compute(ranked: Array[ScoreEntry]) -> Array[Dictionary]:
	var awards: Array[Dictionary] = []
	var sharp: ScoreEntry = null
	for entry in ranked:
		if entry.darts_fired >= SHARPSHOOTER_MIN_DARTS and entry.accuracy() >= SHARPSHOOTER_MIN_ACCURACY:
			if sharp == null or entry.accuracy() > sharp.accuracy():
				sharp = entry
	if sharp != null:
		awards.append({"title": "Sharpshooter", "entry": sharp,
				"detail": "%d%% of darts hit" % int(round(sharp.accuracy() * 100.0))})
	for rule: Array in RULES:
		var best: ScoreEntry = null
		var best_value := 0
		for entry in ranked:
			var value := int(entry.get(rule[1]))
			if value >= int(rule[2]) and value > best_value:
				best = entry
				best_value = value
		if best != null:
			awards.append({"title": rule[0], "entry": best, "detail": String(rule[3]) % best_value})
		if awards.size() >= MAX_AWARDS:
			break
	return awards
