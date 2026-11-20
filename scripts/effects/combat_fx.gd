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
	pool.elemental_impact.connect(_on_elemental_impact)


func watch_actor(actor: Actor) -> void:
	actor.tagged_out.connect(_on_tagged_out)
	actor.respawned.connect(_on_respawned)
	actor.shield_broken.connect(_on_shield_broken)
	if actor.elemental != null:
		actor.elemental.combo_triggered.connect(_on_combo_triggered)
		actor.elemental.chain_zapped.connect(_on_chain_zapped)


func _on_shield_broken(actor: Actor) -> void:
	var centre := actor.global_position + Vector3.UP
	FoamBurst.spawn(self, centre, Color(0.2, 0.85, 1.0), 22, 5.0, Vector3.UP, true)


func _on_impact(kind: int, at: Vector3, normal: Vector3, tint: Color) -> void:
	match kind:
		DartProjectile.Impact.WORLD:
			FoamBurst.spawn(self, at, tint, 3, 2.5, normal)
			FoamSplat.spawn(self, at, normal, tint, 1.0)
		DartProjectile.Impact.ACTOR:
			FoamBurst.spawn(self, at, tint, 8, 4.0, normal)
			Sfx.play_at(&"hit", at, 1.0, -2.0, 0.15)
		DartProjectile.Impact.RICOCHET:
			FoamBurst.spawn(self, at, Color(0.8, 0.97, 1.0), 6, 3.5, normal)
			Sfx.play_at(&"ricochet", at, 1.0, -3.0, 0.12)
		DartProjectile.Impact.TARGET:
			FoamBurst.spawn(self, at, CONFETTI[randi() % CONFETTI.size()], 16, 5.0, normal)
			FoamSplat.spawn(self, at, normal, tint, 1.15)


func _on_elemental_impact(element: DartData.Element, _kind: int, at: Vector3, normal: Vector3, _tint: Color) -> void:
	match element:
		DartData.Element.WIND:
			FoamBurst.spawn(self, at, Color(0.75, 0.95, 1.0), 6, 4.0, normal)
			Sfx.play_at(&"whoosh", at, 1.2, -3.0, 0.1)
		DartData.Element.FIRE:
			FoamBurst.spawn(self, at, Color(1.0, 0.45, 0.1), 8, 3.5, normal)
			Sfx.play_at(&"sparkle", at, 1.1, -2.0, 0.15)
		DartData.Element.WATER:
			FoamBurst.spawn(self, at, Color(0.25, 0.75, 1.0), 10, 4.5, normal)
			Sfx.play_at(&"splash", at, 1.0, -2.0, 0.1)
		DartData.Element.LIGHTNING:
			FoamBurst.spawn(self, at, Color(1.0, 0.95, 0.25), 10, 5.0, normal)
			Sfx.play_at(&"zap", at, 1.1, -1.0, 0.12)
		DartData.Element.ICE:
			FoamBurst.spawn(self, at, Color(0.85, 0.98, 1.0), 8, 3.5, normal)
			Sfx.play_at(&"freeze", at, 1.0, -2.0, 0.1)


func _on_combo_triggered(combo_name: StringName, at: Vector3) -> void:
	match combo_name:
		&"steam", &"flash_steam":
			var count := 24
			var speed := 3.5
			var tree := get_tree()
			if tree != null:
				for node in tree.get_nodes_in_group(&"wind_vents"):
					var vent := node as WindVent
					if vent != null and vent.global_position.distance_to(at) < 5.5:
						count = 60
						speed = 7.0
						vent.amplify(DartData.Element.WATER, 6.0)
						break
			FoamBurst.spawn(self, at, Color(0.92, 0.94, 0.98, 0.75), count, speed, Vector3.UP, true)
			Sfx.play_at(&"steam", at, 1.0, 1.0)
		&"conductive_shock":
			FoamBurst.spawn(self, at, Color(1.0, 1.0, 0.3), 18, 5.5, Vector3.UP, true)
			Sfx.play_at(&"zap", at, 0.85, 2.0)
		&"extinguish":
			FoamBurst.spawn(self, at, Color(0.6, 0.8, 0.95), 12, 3.0, Vector3.UP)
			Sfx.play_at(&"steam", at, 1.2, -2.0)


func _on_chain_zapped(from_actor: Actor, to_actor: Actor) -> void:
	var mid := (from_actor.global_position + to_actor.global_position) * 0.5 + Vector3.UP
	FoamBurst.spawn(self, mid, Color(1.0, 0.95, 0.2), 12, 4.0, Vector3.UP)
	FoamBurst.spawn(self, to_actor.global_position + Vector3.UP, Color(1.0, 0.9, 0.1), 10, 4.5, Vector3.UP)
	Sfx.play_at(&"zap", mid, 1.3, -1.0, 0.1)


## Tagged players pop into a shower of colourful foam. No one gets hurt.
func _on_tagged_out(victim: Actor, _attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	var centre := victim.global_position + Vector3.UP
	FoamBurst.spawn(self, centre, victim.color, 40, 7.0, Vector3.UP, true)
	for i in 3:
		FoamBurst.spawn(self, centre, CONFETTI[randi() % CONFETTI.size()], 14, 6.0, Vector3.UP, true)
	Sfx.play_at(&"tag", centre, 1.0, -4.0)


func _on_respawned(actor: Actor) -> void:
	FoamBurst.spawn(self, actor.global_position + Vector3.UP, actor.color.lightened(0.5), 14, 3.0, Vector3.UP, true)

