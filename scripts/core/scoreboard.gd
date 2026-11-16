class_name Scoreboard
extends RefCounted
## Who is playing and how they are doing. Pure data plus a `changed` signal.

signal changed

var entries: Array[ScoreEntry] = []


func add_actor(actor: Actor) -> ScoreEntry:
	var entry := ScoreEntry.new()
	entry.actor = actor
	entry.display_name = actor.display_name
	entry.color = actor.color
	entry.hat = actor.hat_id
	entry.is_human = actor.is_human
	entry.team = actor.team_id
	entries.append(entry)
	changed.emit()
	return entry


func entry_for(actor: Actor) -> ScoreEntry:
	for entry in entries:
		if entry.actor == actor:
			return entry
	return null


func notify_changed() -> void:
	changed.emit()
