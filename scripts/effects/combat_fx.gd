class_name CombatFx
extends Node3D
## Turns combat events into foam particles and sounds. Darts and actors only emit
## signals; everything you see and hear from an impact is decided here.

const CONFETTI := [
	Color(1.0, 0.45, 0.7), Color(1.0, 0.85, 0.2), Color(0.3, 0.85, 0.95),
	Color(0.6, 0.9, 0.2), Color(1.0, 0.5, 0.1),
]


func watch_pool(pool: DartPool) -> void:
	pool.impact.connect(_on_impact)


func watch_actor(actor: Actor) -> void:
	actor.tagged_out.connect(_on_tagged_out)
	actor.respawned.connect(_on_respawned)


func _on_impact(kind: int, at: Vector3, normal: Vector3, tint: Color) -> void:
	match kind:
		DartProjectile.Impact.WORLD:
			FoamBurst.spawn(self, at, tint, 3, 2.5, normal)
		DartProjectile.Impact.ACTOR:
			FoamBurst.spawn(self, at, tint, 8, 4.0, normal)
			Sfx.play_at(&"hit", at, 1.0, -2.0, 0.15)
		DartProjectile.Impact.RICOCHET:
			FoamBurst.spawn(self, at, Color(0.8, 0.97, 1.0), 6, 3.5, normal)
			Sfx.play_at(&"ricochet", at, 1.0, -3.0, 0.12)
		DartProjectile.Impact.TARGET:
			FoamBurst.spawn(self, at, CONFETTI[randi() % CONFETTI.size()], 16, 5.0, normal)


## Tagged players pop into a shower of colourful foam. No one gets hurt.
func _on_tagged_out(victim: Actor, _attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	var centre := victim.global_position + Vector3.UP
	FoamBurst.spawn(self, centre, victim.color, 40, 7.0)
	for i in 3:
		FoamBurst.spawn(self, centre, CONFETTI[randi() % CONFETTI.size()], 14, 6.0)
	Sfx.play_at(&"tag", centre, 1.0, -4.0)


func _on_respawned(actor: Actor) -> void:
	FoamBurst.spawn(self, actor.global_position + Vector3.UP, actor.color.lightened(0.5), 14, 3.0)
