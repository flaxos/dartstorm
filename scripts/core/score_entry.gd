class_name ScoreEntry
extends RefCounted
## One row of the scoreboard.

var actor: Actor
var display_name: String = ""
var color: Color = Color.WHITE
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
