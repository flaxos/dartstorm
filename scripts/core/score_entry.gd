class_name ScoreEntry
extends RefCounted
## One row of the scoreboard, plus the fun stats used for end-of-match awards.

var actor: Actor
var display_name: String = ""
var color: Color = Color.WHITE
var hat: StringName = &"cap"
var is_human: bool = false
## Times this actor tagged someone out.
var tags: int = 0
## Times this actor was tagged out.
var outs: int = 0
var score: int = 0
var ricochet_tags: int = 0
## Gun Game: position on the weapon ladder, and tags earned at that rung.
var tier: int = 0
var tier_progress: int = 0

# --- Streaks (announcer) ---
## Tags since this actor was last tagged out.
var streak: int = 0
var best_streak: int = 0
## Match-clock times of recent tags, for DOUBLE/TRIPLE TAG.
var recent_tags: Array[float] = []

# --- Award stats (counted only while the round is being played) ---
var darts_fired: int = 0
var hits_landed: int = 0
var darts_collected: int = 0
var targets_hit: int = 0
## Darts fired from spin-up blasters (the Chainstorm).
var storm_darts: int = 0


## Fraction of fired darts that hit someone (0 when nothing was fired).
func accuracy() -> float:
	return float(hits_landed) / float(darts_fired) if darts_fired > 0 else 0.0
