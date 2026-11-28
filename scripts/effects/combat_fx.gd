class_name CombatFx
extends Node3D
## Turns combat events into foam particles and sounds. Darts and actors only emit
## signals; everything you see and hear from an impact is decided here.

const CONFETTI := [
	Color(1.0, 0.45, 0.7), Color(1.0, 0.85, 0.2), Color(0.3, 0.85, 0.95),
	Color(0.6, 0.9, 0.2), Color(1.0, 0.5, 0.1),
]

static var _starburst_outer_mesh: ArrayMesh
static var _starburst_inner_mesh: ArrayMesh
static var _mini_star_mesh: ArrayMesh

var _last_ricochet_pop_msec: int = 0


static func clear_cached_meshes() -> void:
	_starburst_outer_mesh = null
	_starburst_inner_mesh = null
	_mini_star_mesh = null


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
			FoamBurst.spawn(self, at, Color(0.8, 0.97, 1.0), 8, 4.0, normal)
			Sfx.play_at(&"ricochet", at, 1.0, -3.0, 0.12)
			var now_ms := Time.get_ticks_msec()
			if now_ms - _last_ricochet_pop_msec >= 180:
				_last_ricochet_pop_msec = now_ms
				spawn_comic_starburst(self, at + normal * 0.28, "RICOCHET!", Color(0.28, 0.94, 1.0), 0.72)
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
func _on_tagged_out(victim: Actor, _attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	var centre := victim.global_position + Vector3.UP
	FoamBurst.spawn(self, centre, victim.color, 40, 7.0, Vector3.UP, true)
	spawn_blast_wave(self, centre, victim.color.lightened(0.25), 3.2)
	if weapon != null and weapon.is_melee():
		spawn_comic_starburst(self, centre + Vector3.UP * 0.65, "BONK!", Color(1.0, 0.84, 0.16), 1.28)
	elif ricochet:
		spawn_comic_starburst(self, centre + Vector3.UP * 0.65, "TRICK SHOT!", Color(0.25, 0.94, 1.0), 1.15)
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


## Cover-art comic impact burst: spiky twin-layer starburst + flying mini-stars + bold word pop
## ("BONK!", "DEFLECT!", "RICOCHET!", "HOME RUN!", "TRICK SHOT!"). Self-frees cleanly.
static func spawn_comic_starburst(parent: Node, at: Vector3, label_text: String = "BONK!",
		tint: Color = Color(1.0, 0.85, 0.16), scale_mult: float = 1.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	_ensure_starburst_meshes()
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)

	var star_holder := Node3D.new()
	star_holder.scale = Vector3.ONE * (0.18 * scale_mult)
	root.add_child(star_holder)

	var outer_mat := StandardMaterial3D.new()
	outer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	outer_mat.billboard_keep_scale = true
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_mat.no_depth_test = false
	outer_mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.96)
	outer_mat.emission_enabled = true
	outer_mat.emission = tint
	outer_mat.emission_energy_multiplier = 1.8

	var outer := MeshInstance3D.new()
	outer.mesh = _starburst_outer_mesh
	outer.material_override = outer_mat
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	star_holder.add_child(outer)

	var inner_mat := StandardMaterial3D.new()
	inner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	inner_mat.billboard_keep_scale = true
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.albedo_color = Color(1.0, 0.98, 0.84, 0.98)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(1.0, 0.97, 0.78)
	inner_mat.emission_energy_multiplier = 2.2

	var inner := MeshInstance3D.new()
	inner.mesh = _starburst_inner_mesh
	inner.material_override = inner_mat
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	star_holder.add_child(inner)

	var tween := root.create_tween()
	tween.set_parallel(true)
	# Snappy comic pop-in then crisp fade-out
	tween.tween_property(star_holder, "scale", Vector3.ONE * (1.18 * scale_mult), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(outer_mat, "albedo_color:a", 0.0, 0.36).set_delay(0.10)
	tween.tween_property(inner_mat, "albedo_color:a", 0.0, 0.30).set_delay(0.08)

	# 5 flying comic star confetti pieces bursting radially outward
	var confetti_count := clampi(int(round(5.0 * clampf(GameSettings.visual_intensity, 0.4, 1.4))), 2, 7)
	for i in confetti_count:
		var ang := TAU * float(i) / float(confetti_count) + randf_range(-0.22, 0.22)
		var c_mat := StandardMaterial3D.new()
		c_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		c_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c_col: Color = tint.lightened(0.2) if (i % 2 == 0) else Color(1.0, 0.95, 0.38)
		c_mat.albedo_color = Color(c_col.r, c_col.g, c_col.b, 0.95)
		c_mat.emission_enabled = true
		c_mat.emission = c_col
		c_mat.emission_energy_multiplier = 1.6
		var shard := MeshInstance3D.new()
		shard.mesh = _mini_star_mesh
		shard.material_override = c_mat
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.scale = Vector3.ONE * (0.85 * scale_mult)
		root.add_child(shard)
		var out_vec := Vector3(cos(ang) * randf_range(0.8, 1.45), randf_range(0.35, 1.15), sin(ang) * randf_range(0.8, 1.45)) * scale_mult
		tween.tween_property(shard, "position", out_vec, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", Vector3(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)), 0.44)
		tween.tween_property(c_mat, "albedo_color:a", 0.0, 0.28).set_delay(0.16)

	if not label_text.is_empty():
		var word := Label3D.new()
		word.text = label_text
		word.font = UiKit.font()
		word.font_size = 76
		word.pixel_size = 0.0085 * scale_mult
		word.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		word.no_depth_test = true
		word.render_priority = 6
		word.outline_render_priority = 5
		word.modulate = Color(1.0, 0.97, 0.85, 1.0)
		word.outline_size = 20
		word.outline_modulate = Color(0.039, 0.094, 0.239, 1.0)
		word.position = Vector3(0.0, 0.16 * scale_mult, 0.0)
		word.scale = Vector3.ONE * 0.25
		root.add_child(word)
		tween.tween_property(word, "scale", Vector3.ONE * 1.12, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(word, "position:y", 0.72 * scale_mult, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(word, "modulate:a", 0.0, 0.22).set_delay(0.24)
		tween.tween_property(word, "outline_modulate:a", 0.0, 0.22).set_delay(0.24)

	tween.chain().tween_callback(root.queue_free)


static func _ensure_starburst_meshes() -> void:
	if _starburst_outer_mesh != null:
		return
	_starburst_outer_mesh = _build_star_polygon(10, 0.78, 0.34, 0.0)
	_starburst_inner_mesh = _build_star_polygon(10, 0.50, 0.24, 0.314)
	_mini_star_mesh = _build_star_3d(5, 0.16, 0.065, 0.03)


static func _build_star_polygon(points: int, outer_r: float, inner_r: float, angle_off: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := points * 2
	var center := Vector3.ZERO
	var ring: Array[Vector3] = []
	for i in total:
		var ang := angle_off + float(i) * TAU / float(total)
		var r := outer_r if (i % 2 == 0) else inner_r
		ring.append(Vector3(cos(ang) * r, sin(ang) * r, 0.0))
	for i in total:
		var a := ring[i]
		var b := ring[(i + 1) % total]
		st.add_vertex(center); st.add_vertex(a); st.add_vertex(b)
		st.add_vertex(center); st.add_vertex(b); st.add_vertex(a)
	st.generate_normals()
	return st.commit()


static func _build_star_3d(points: int, outer_r: float, inner_r: float, half_thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := points * 2
	var ring: Array[Vector3] = []
	for i in total:
		var ang := float(i) * TAU / float(total)
		var r := outer_r if (i % 2 == 0) else inner_r
		ring.append(Vector3(cos(ang) * r, sin(ang) * r, 0.0))
	var f := Vector3(0.0, 0.0, half_thick)
	var b := Vector3(0.0, 0.0, -half_thick)
	for i in total:
		var p0 := ring[i]
		var p1 := ring[(i + 1) % total]
		st.add_vertex(f); st.add_vertex(p0); st.add_vertex(p1)
		st.add_vertex(b); st.add_vertex(p1); st.add_vertex(p0)
	st.generate_normals()
	return st.commit()

