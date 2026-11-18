class_name Crosshair
extends Control
## Drawn crosshair with a hit marker. The gap widens briefly with each shot.

const LINE := 9.0
const BASE_GAP := 6.0

var _kick: float = 0.0
var _hit_left: float = 0.0
var _hit_color: Color = Color.WHITE
var _hit_size: float = 1.0
var scoped: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_scoped(s: bool) -> void:
	if scoped != s:
		scoped = s
		queue_redraw()


## Widens the crosshair for a moment (called per shot).
func kick(amount: float) -> void:
	_kick = minf(_kick + amount, 14.0)


## Flashes the hit marker. A tag-out gets a bigger, orange marker.
func show_hit(was_tag: bool) -> void:
	_hit_left = 0.35 if was_tag else 0.18
	_hit_color = UiKit.ORANGE_HOT if was_tag else Color.WHITE
	_hit_size = 1.6 if was_tag else 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if _kick > 0.0 or _hit_left > 0.0:
		_kick = move_toward(_kick, 0.0, delta * 40.0)
		_hit_left = maxf(_hit_left - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	if scoped:
		_draw_scope(centre)
	else:
		_draw_standard(centre)

	if _hit_left > 0.0:
		var reach := 16.0 * _hit_size
		for diagonal in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var unit: Vector2 = diagonal.normalized()
			draw_line(centre + unit * 8.0, centre + unit * reach, UiKit.NAVY_DARK, 6.0, true)
			draw_line(centre + unit * 8.0, centre + unit * reach, _hit_color, 3.0, true)


func _draw_standard(centre: Vector2) -> void:
	var gap := BASE_GAP + _kick
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
	# Darkened outer mask around scope lens
	draw_arc(centre, radius + max_dim * 0.5, 0.0, TAU, 48, Color(0.04, 0.06, 0.1, 0.94), max_dim, true)
	# Lens perimeter rings
	draw_arc(centre, radius, 0.0, TAU, 64, UiKit.NAVY_DARK, 6.0, true)
	draw_arc(centre, radius, 0.0, TAU, 64, Color(0.2, 0.6, 0.9, 0.7), 2.5, true)
	draw_arc(centre, radius * 0.65, 0.0, TAU, 48, Color(0.2, 0.6, 0.9, 0.25), 1.0, true)

	# Crosshair reticle lines with gap at center
	var inner_gap := 14.0 + _kick * 0.5
	# Horizontal line
	draw_line(centre - Vector2(radius, 0.0), centre - Vector2(inner_gap, 0.0), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre - Vector2(radius, 0.0), centre - Vector2(inner_gap, 0.0), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)
	draw_line(centre + Vector2(inner_gap, 0.0), centre + Vector2(radius, 0.0), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre + Vector2(inner_gap, 0.0), centre + Vector2(radius, 0.0), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)

	# Vertical line
	draw_line(centre - Vector2(0.0, radius), centre - Vector2(0.0, inner_gap), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre - Vector2(0.0, radius), centre - Vector2(0.0, inner_gap), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)
	draw_line(centre + Vector2(0.0, inner_gap), centre + Vector2(0.0, radius), Color(0.08, 0.12, 0.18, 0.9), 3.0, true)
	draw_line(centre + Vector2(0.0, inner_gap), centre + Vector2(0.0, radius), Color(0.85, 0.94, 1.0, 0.95), 1.5, true)

	# Range elevation tick marks
	for d in [35.0, 70.0, 105.0, 140.0]:
		if d < radius:
			draw_line(centre + Vector2(-6.0, d), centre + Vector2(6.0, d), Color(0.85, 0.94, 1.0, 0.8), 1.5, true)
			draw_line(centre - Vector2(6.0, d), centre - Vector2(6.0, d), Color(0.85, 0.94, 1.0, 0.5), 1.0, true)
			draw_line(centre + Vector2(d, -4.0), centre + Vector2(d, 4.0), Color(0.85, 0.94, 1.0, 0.6), 1.0, true)
			draw_line(centre - Vector2(d, 4.0), centre - Vector2(d, -4.0), Color(0.85, 0.94, 1.0, 0.6), 1.0, true)

	# Center precision aim dot
	draw_circle(centre, 3.0, UiKit.NAVY_DARK)
	draw_circle(centre, 1.8, UiKit.ORANGE_HOT)
