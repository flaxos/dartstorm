class_name WindGauge
extends Control
## A little compass that shows which way the wind is pushing darts, relative to
## where the player is looking (up = straight ahead).

var _angle: float = 0.0
var _power: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `angle` is clockwise from straight ahead, `power` is 0..1.
func set_wind(angle: float, power: float) -> void:
	if is_equal_approx(angle, _angle) and is_equal_approx(power, _power):
		return
	_angle = angle
	_power = power
	queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 2.0
	draw_circle(centre, radius, Color(UiKit.NAVY_DARK, 0.9))
	draw_arc(centre, radius, 0.0, TAU, 32, UiKit.SKY, 3.0, true)
	if _power < 0.02:
		draw_circle(centre, 5.0, UiKit.GREY)
		return
	var forward := Vector2.UP.rotated(_angle)
	var side := forward.orthogonal()
	var reach := radius * lerpf(0.55, 0.85, _power)
	var tip := centre + forward * reach
	var tail := centre - forward * reach
	var neck := centre + forward * reach * 0.1
	draw_line(tail, neck, UiKit.ORANGE_HOT, 6.0, true)
	draw_colored_polygon(PackedVector2Array([tip, neck + side * radius * 0.42, neck - side * radius * 0.42]), UiKit.ORANGE_HOT)
