class_name Crosshair
extends Control
## Drawn crosshair with a hit marker. The gap widens briefly with each shot.

const LINE := 9.0
const BASE_GAP := 6.0

var _kick: float = 0.0
var _hit_left: float = 0.0
var _hit_color: Color = Color.WHITE
var _hit_size: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
	var gap := BASE_GAP + _kick
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var from: Vector2 = centre + direction * gap
		var to: Vector2 = centre + direction * (gap + LINE)
		draw_line(from, to, UiKit.NAVY_DARK, 6.0, true)
		draw_line(from, to, UiKit.CREAM, 3.0, true)
	draw_circle(centre, 3.5, UiKit.NAVY_DARK)
	draw_circle(centre, 2.2, UiKit.ORANGE)
	if _hit_left > 0.0:
		var reach := 16.0 * _hit_size
		for diagonal in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var unit: Vector2 = diagonal.normalized()
			draw_line(centre + unit * 8.0, centre + unit * reach, UiKit.NAVY_DARK, 6.0, true)
			draw_line(centre + unit * 8.0, centre + unit * reach, _hit_color, 3.0, true)
