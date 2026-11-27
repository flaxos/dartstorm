class_name Crosshair
extends Control
## Drawn crosshair with dynamic spread, rich body/shield/ricochet/tag hitmarkers,
## radial reload progress ring, and directional damage indicator arcs.

const LINE := 9.0
const BASE_GAP := 6.0

enum ReticleType { STANDARD, RED_DOT, HOLO, SCOPE }

var _kick: float = 0.0
var _dynamic_gap: float = 0.0
var _target_gap: float = 0.0
var _hit_left: float = 0.0
var _hit_color: Color = Color.WHITE
var _hit_size: float = 1.0
var _hit_double: bool = false
var _reload_progress: float = -1.0
var _damage_arcs: Array[Dictionary] = [] # { "world_from": Vector3, "time": float, "max_time": float, "color": Color }
var _player_ref: Player = null
var scoped: bool = false
var reticle_type: ReticleType = ReticleType.STANDARD


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_player(p: Player) -> void:
	_player_ref = p


func set_scoped(s: bool) -> void:
	if scoped != s:
		scoped = s
		queue_redraw()


func set_reticle_type(type: ReticleType) -> void:
	if reticle_type != type:
		reticle_type = type
		queue_redraw()


func set_reticle_from_string(type_name: StringName) -> void:
	match type_name:
		&"red_dot":
			set_reticle_type(ReticleType.RED_DOT)
		&"holo":
			set_reticle_type(ReticleType.HOLO)
		&"scope":
			set_reticle_type(ReticleType.SCOPE)
		_:
			set_reticle_type(ReticleType.STANDARD)


## Dynamic movement / ADS spread gap offset in pixels.
func set_dynamic_gap(pixels: float) -> void:
	_target_gap = clampf(pixels, -2.5, 16.0)


## Sets reload ring progress in [0, 1], or < 0 to hide.
func set_reload_progress(ratio: float) -> void:
	var prev := _reload_progress
	_reload_progress = ratio
	if absf(prev - ratio) > 0.004 or (prev < 0.0) != (ratio < 0.0):
		queue_redraw()


## Adds a directional damage indicator arc pointing toward `attacker_pos` in world space.
func add_damage_arc(attacker_pos: Vector3, tint: Color = UiKit.ORANGE_HOT) -> void:
	_damage_arcs.append({
		"world_from": attacker_pos,
		"time": 0.95,
		"max_time": 0.95,
		"color": tint,
	})
	if _damage_arcs.size() > 6:
		_damage_arcs.pop_front()
	queue_redraw()


## Widens the crosshair for a moment (called per shot).
func kick(amount: float) -> void:
	_kick = minf(_kick + amount, 14.0)
	queue_redraw()


## Flashes the hit marker: crisp white on hit, cyan on shield, gold on ricochet, big double-X orange on tag-out.
func show_hit(was_tag: bool, is_shield: bool = false, is_ricochet: bool = false) -> void:
	_hit_left = 0.38 if was_tag else 0.20
	_hit_double = was_tag
	if was_tag:
		_hit_color = UiKit.ORANGE_HOT
		_hit_size = 1.65
	elif is_ricochet:
		_hit_color = Color(1.0, 0.92, 0.2)
		_hit_size = 1.3
	elif is_shield:
		_hit_color = Color(0.25, 0.88, 1.0)
		_hit_size = 1.15
	else:
		_hit_color = Color.WHITE
		_hit_size = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	var dirty := false
	if absf(_dynamic_gap - _target_gap) > 0.05:
		_dynamic_gap = lerpf(_dynamic_gap, _target_gap, clampf(delta * 14.0, 0.0, 1.0))
		dirty = true
	if _kick > 0.0 or _hit_left > 0.0:
		_kick = move_toward(_kick, 0.0, delta * 40.0)
		_hit_left = maxf(_hit_left - delta, 0.0)
		dirty = true
	if not _damage_arcs.is_empty():
		for i in range(_damage_arcs.size() - 1, -1, -1):
			_damage_arcs[i]["time"] = float(_damage_arcs[i]["time"]) - delta
			if float(_damage_arcs[i]["time"]) <= 0.0:
				_damage_arcs.remove_at(i)
		dirty = true
	if dirty:
		queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	if scoped:
		match reticle_type:
			ReticleType.RED_DOT:
				_draw_red_dot(centre)
			ReticleType.HOLO:
				_draw_holo(centre)
			ReticleType.SCOPE:
				_draw_scope(centre)
			_:
				_draw_standard(centre)
	else:
		_draw_standard(centre)

	# Radial reload ring cleanly wrapping center crosshair
	if _reload_progress >= 0.0:
		var r := 22.0
		var start_a := -PI * 0.5
		draw_arc(centre, r, 0.0, TAU, 32, Color(UiKit.NAVY_DARK, 0.7), 5.0, true)
		draw_arc(centre, r, start_a, start_a + TAU * clampf(_reload_progress, 0.0, 1.0), 32, UiKit.SKY, 3.0, true)

	# Directional damage indicator arcs pointing toward incoming attacker
	if not _damage_arcs.is_empty() and _player_ref != null and is_instance_valid(_player_ref):
		var p_pos := _player_ref.global_position
		var basis := _player_ref.global_transform.basis
		var arc_r := minf(size.x, size.y) * 0.19
		for arc_info: Dictionary in _damage_arcs:
			var from_world: Vector3 = arc_info["world_from"]
			var to_att := from_world - p_pos
			to_att.y = 0.0
			if to_att.length_squared() < 0.001:
				continue
			var rel_x := to_att.dot(basis.x)
			var rel_fwd := to_att.dot(-basis.z)
			# Screen angle: -PI/2 is straight ahead (UP), 0 is RIGHT, +PI/2 is BEHIND (DOWN)
			var angle := atan2(-rel_fwd, rel_x)
			var alpha := clampf(float(arc_info["time"]) / float(arc_info["max_time"]), 0.0, 1.0)
			var col: Color = arc_info["color"]
			draw_arc(centre, arc_r, angle - 0.30, angle + 0.30, 18, Color(UiKit.NAVY_DARK, alpha * 0.7), 10.0, true)
			draw_arc(centre, arc_r, angle - 0.28, angle + 0.28, 18, Color(col.r, col.g, col.b, alpha * 0.92), 6.0, true)

	if _hit_left > 0.0:
		var reach := 16.0 * _hit_size
		for diagonal in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var unit: Vector2 = diagonal.normalized()
			draw_line(centre + unit * 8.0, centre + unit * reach, UiKit.NAVY_DARK, 6.0, true)
			draw_line(centre + unit * 8.0, centre + unit * reach, _hit_color, 3.0, true)
			if _hit_double:
				draw_line(centre + unit * (reach + 4.0), centre + unit * (reach + 10.0), UiKit.NAVY_DARK, 5.0, true)
				draw_line(centre + unit * (reach + 4.0), centre + unit * (reach + 10.0), UiKit.CREAM, 2.5, true)


func _draw_standard(centre: Vector2) -> void:
	var gap := maxf(3.0, BASE_GAP + _kick + _dynamic_gap)
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var from: Vector2 = centre + direction * gap
		var to: Vector2 = centre + direction * (gap + LINE)
		draw_line(from, to, UiKit.NAVY_DARK, 6.0, true)
		draw_line(from, to, UiKit.CREAM, 3.0, true)
	draw_circle(centre, 3.5, UiKit.NAVY_DARK)
	draw_circle(centre, 2.2, UiKit.ORANGE)


func _draw_scope(centre: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.42
	var max_dim := maxf(size.x, size.y)
	draw_arc(centre, radius + max_dim * 0.5, 0.0, TAU, 48, Color(0.04, 0.06, 0.1, 0.94), max_dim, true)
	draw_arc(centre, radius, 0.0, TAU, 64, UiKit.NAVY_DARK, 6.0, true)
	draw_arc(centre, radius, 0.0, TAU, 64, Color(0.2, 0.6, 0.9, 0.7), 2.5, true)
	draw_arc(centre, radius * 0.65, 0.0, TAU, 48, Color(0.2, 0.6, 0.9, 0.25), 1.0, true)

	var inner_gap := 14.0 + _kick * 0.5
	draw_line(centre - Vector2(radius, 0.0), centre - Vector2(inner_gap, 0.0), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre - Vector2(radius, 0.0), centre - Vector2(inner_gap, 0.0), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)
	draw_line(centre + Vector2(inner_gap, 0.0), centre + Vector2(radius, 0.0), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre + Vector2(inner_gap, 0.0), centre + Vector2(radius, 0.0), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)

	draw_line(centre - Vector2(0.0, radius), centre - Vector2(0.0, inner_gap), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre - Vector2(0.0, radius), centre - Vector2(0.0, inner_gap), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)
	draw_line(centre + Vector2(0.0, inner_gap), centre + Vector2(0.0, radius), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre + Vector2(0.0, inner_gap), centre + Vector2(0.0, radius), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)

	for d in [35.0, 70.0, 105.0, 140.0]:
		if d < radius:
			draw_line(centre + Vector2(-6.0, d), centre + Vector2(6.0, d), Color(0.85, 0.94, 1.0, 0.8), 1.5, true)
			draw_line(centre - Vector2(6.0, d), centre - Vector2(6.0, d), Color(0.85, 0.94, 1.0, 0.5), 1.0, true)
			draw_line(centre + Vector2(d, -4.0), centre + Vector2(d, 4.0), Color(0.85, 0.94, 1.0, 0.6), 1.0, true)
			draw_line(centre - Vector2(d, 4.0), centre - Vector2(d, -4.0), Color(0.85, 0.94, 1.0, 0.6), 1.0, true)

	draw_circle(centre, 3.0, UiKit.NAVY_DARK)
	draw_circle(centre, 1.8, UiKit.ORANGE_HOT)


func _draw_red_dot(centre: Vector2) -> void:
	var ring_r := 26.0 + _kick * 0.4
	draw_arc(centre, ring_r + 20.0, 0.0, TAU, 36, Color(0.08, 0.1, 0.16, 0.5), 18.0, true)
	draw_arc(centre, ring_r + 11.0, 0.0, TAU, 36, UiKit.NAVY_DARK, 3.5, true)
	draw_circle(centre, ring_r + 9.0, Color(0.15, 0.5, 0.7, 0.12))

	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var p1: Vector2 = centre + dir * (ring_r - 2.0)
		var p2: Vector2 = centre + dir * (ring_r + 7.0)
		draw_line(p1, p2, UiKit.NAVY_DARK, 3.0, true)
		draw_line(p1, p2, Color(0.85, 0.95, 1.0, 0.7), 1.5, true)

	draw_circle(centre, 4.5, UiKit.NAVY_DARK)
	draw_circle(centre, 3.0, Color(1.0, 0.15, 0.15))
	draw_circle(centre, 1.5, Color(1.0, 0.85, 0.85))


func _draw_holo(centre: Vector2) -> void:
	var outer_r := 34.0 + _kick * 0.5
	var inner_r := 18.0
	var window_rect := Rect2(centre - Vector2(55.0, 42.0), Vector2(110.0, 84.0))
	draw_rect(window_rect, Color(0.1, 0.4, 0.6, 0.1), true)
	draw_rect(window_rect, Color(0.08, 0.12, 0.18, 0.6), false, 3.0)

	var holo_color := Color(0.15, 0.9, 1.0, 0.9)
	var glow_color := Color(0.05, 0.2, 0.3, 0.6)

	draw_arc(centre, outer_r, 0.0, TAU, 48, glow_color, 4.0, true)
	draw_arc(centre, outer_r, 0.0, TAU, 48, holo_color, 2.0, true)

	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var p1: Vector2 = centre + dir * (outer_r - 6.0)
		var p2: Vector2 = centre + dir * (outer_r + 12.0)
		draw_line(p1, p2, glow_color, 4.0, true)
		draw_line(p1, p2, holo_color, 2.0, true)

	draw_arc(centre, inner_r, 0.0, TAU, 32, glow_color, 3.0, true)
	draw_arc(centre, inner_r, 0.0, TAU, 32, holo_color, 1.2, true)

	draw_circle(centre, 3.5, UiKit.NAVY_DARK)
	draw_circle(centre, 2.2, Color(1.0, 0.35, 0.1))
	draw_circle(centre, 1.0, Color(1.0, 0.95, 0.8))
