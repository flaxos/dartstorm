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
	spawn_blast_wave(self, centre, Color(0.25, 0.9, 1.0), 2.4)


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
			var plume_scale := 1.0
			var tree := get_tree()
			if tree != null:
				for node in tree.get_nodes_in_group(&"wind_vents"):
					var vent := node as WindVent
					if vent != null and vent.global_position.distance_to(at) < 5.5:
						count = 60
						speed = 7.0
						plume_scale = 1.8
						vent.amplify(DartData.Element.WATER, 6.0)
						break
			FoamBurst.spawn(self, at, Color(0.92, 0.94, 0.98, 0.75), count, speed, Vector3.UP, true)
			spawn_steam_plume(self, at, plume_scale)
			Sfx.play_at(&"steam", at, 1.0, 1.0)
		&"conductive_shock":
			FoamBurst.spawn(self, at, Color(1.0, 1.0, 0.3), 18, 5.5, Vector3.UP, true)
			spawn_blast_wave(self, at, Color(1.0, 0.96, 0.3), 3.0)
			Sfx.play_at(&"zap", at, 0.85, 2.0)
		&"extinguish":
			FoamBurst.spawn(self, at, Color(0.6, 0.8, 0.95), 12, 3.0, Vector3.UP)
			spawn_steam_plume(self, at, 0.75)
			Sfx.play_at(&"steam", at, 1.2, -2.0)


func _on_chain_zapped(from_actor: Actor, to_actor: Actor) -> void:
	var a_pos := from_actor.global_position + Vector3.UP * 1.15
	var b_pos := to_actor.global_position + Vector3.UP * 1.15
	var mid := (a_pos + b_pos) * 0.5
	spawn_lightning_arc(self, a_pos, b_pos, Color(1.0, 0.96, 0.35), 0.24)
	FoamBurst.spawn(self, mid, Color(1.0, 0.95, 0.2), 10, 4.0, Vector3.UP)
	FoamBurst.spawn(self, b_pos, Color(1.0, 0.9, 0.1), 10, 4.5, Vector3.UP)
	Sfx.play_at(&"zap", mid, 1.3, -1.0, 0.1)


## Tagged players pop into a shower of colourful foam + celebratory shockwave ring.
func _on_tagged_out(victim: Actor, _attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	var centre := victim.global_position + Vector3.UP
	FoamBurst.spawn(self, centre, victim.color, 40, 7.0, Vector3.UP, true)
	spawn_blast_wave(self, centre, victim.color.lightened(0.25), 3.2)
	for i in 3:
		FoamBurst.spawn(self, centre, CONFETTI[randi() % CONFETTI.size()], 14, 6.0, Vector3.UP, true)
	Sfx.play_at(&"tag", centre, 1.0, -4.0)


func _on_respawned(actor: Actor) -> void:
	FoamBurst.spawn(self, actor.global_position + Vector3.UP, actor.color.lightened(0.5), 14, 3.0, Vector3.UP, true)


## Rising translucent cartoon steam cloud plume for Fire+Water / Heatwave combos.
static func spawn_steam_plume(parent: Node, at: Vector3, scale_mult: float = 1.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.52)

	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.55 * scale_mult
	puff_mesh.height = 0.95 * scale_mult
	puff_mesh.radial_segments = 12
	puff_mesh.rings = 6

	var count := clampi(int(round(6.0 * clampf(GameSettings.visual_intensity, 0.4, 1.5))), 3, 9)
	var tween := root.create_tween()
	tween.set_parallel(true)
	for i in count:
		var puff := MeshInstance3D.new()
		puff.mesh = puff_mesh
		puff.material_override = mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := TAU * float(i) / float(count)
		var r := randf_range(0.15, 0.65) * scale_mult
		puff.position = Vector3(cos(ang) * r, randf_range(0.0, 0.35), sin(ang) * r)
		puff.scale = Vector3.ONE * randf_range(0.45, 0.85)
		root.add_child(puff)
		var end_pos := puff.position + Vector3(cos(ang) * r * 1.4, randf_range(2.2, 3.6) * scale_mult, sin(ang) * r * 1.4)
		tween.tween_property(puff, "position", end_pos, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(puff, "scale", Vector3.ONE * (1.85 * scale_mult), 1.1)
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(root.queue_free)


## 3D jagged glowing lightning bolt between two world points (Chain Zap & Weather Strikes).
static func spawn_lightning_arc(parent: Node, from_pos: Vector3, to_pos: Vector3,
		tint: Color = Color(1.0, 0.96, 0.35), duration: float = 0.24, thickness: float = 0.065) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var span := to_pos - from_pos
	var dist := span.length()
	if dist < 0.05:
		return

	var root := Node3D.new()
	parent.add_child(root)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.95)
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 3.2

	var segments := clampi(int(dist * 1.4), 5, 14)
	var dir := span / dist
	var side_a := dir.cross(Vector3.UP)
	if side_a.length_squared() < 0.01:
		side_a = dir.cross(Vector3.RIGHT)
	side_a = side_a.normalized()
	var side_b := dir.cross(side_a).normalized()
	var jitter := minf(dist * 0.14, 0.85)

	var pts: Array[Vector3] = [from_pos]
	for i in range(1, segments):
		var t := float(i) / float(segments)
		var base := from_pos.lerp(to_pos, t)
		var off := side_a * randf_range(-jitter, jitter) + side_b * randf_range(-jitter, jitter)
		pts.append(base + off)
	pts.append(to_pos)

	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg_vec := b - a
		var seg_len := seg_vec.length()
		if seg_len < 0.01:
			continue
		var seg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = thickness * 0.85
		cyl.bottom_radius = thickness
		cyl.height = seg_len
		cyl.radial_segments = 6
		seg.mesh = cyl
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mid := (a + b) * 0.5
		seg.position = mid
		var up_axis := seg_vec / seg_len
		seg.quaternion = Quaternion(Vector3.UP, up_axis)
		root.add_child(seg)

	var light := OmniLight3D.new()
	light.position = (from_pos + to_pos) * 0.5
	light.light_color = tint
	light.light_energy = 5.0 * clampf(GameSettings.visual_intensity, 0.3, 1.5)
	light.omni_range = clampf(dist * 1.2, 5.0, 16.0)
	light.shadow_enabled = false
	root.add_child(light)

	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.tween_property(light, "light_energy", 0.0, duration * 0.8)
	tween.chain().tween_callback(root.queue_free)


## Expanding cartoon shockwave ring + brief flash light for grenade blasts & tag-outs.
static func spawn_blast_wave(parent: Node, at: Vector3, tint: Color, max_radius: float = 5.5) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var wave := Node3D.new()
	wave.position = at + Vector3.UP * 0.15
	parent.add_child(wave)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.72
	torus.outer_radius = 1.0
	torus.rings = 20
	torus.ring_segments = 8
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.85)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3(0.25, 0.35, 0.25)
	wave.add_child(ring)

	var flash := OmniLight3D.new()
	flash.light_color = tint.lightened(0.25)
	flash.light_energy = 4.5 * clampf(GameSettings.visual_intensity, 0.3, 1.5)
	flash.omni_range = max_radius * 1.8
	wave.add_child(flash)

	var tween := wave.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(max_radius, 0.15, max_radius), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tween.tween_property(flash, "light_energy", 0.0, 0.22)
	tween.chain().tween_callback(wave.queue_free)

