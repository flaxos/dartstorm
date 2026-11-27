class_name WobbleTarget
extends StaticBody3D
## A bullseye that spins and dings when a dart hits it, then pops back after a
## short rest. Great for practising arcs, wind shots and ricochets.
## The face points along this node's local +Z.

signal hit(shooter: Actor)

@export var target_radius: float = 0.9
@export var reset_seconds: float = 2.5

var _face: Node3D
var _ready_to_hit: bool = true


func _ready() -> void:
	add_to_group(&"wobble_targets")
	collision_layer = Layers.TARGETS
	collision_mask = 0
	var shape := CylinderShape3D.new()
	shape.radius = target_radius
	shape.height = 0.2
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.rotation_degrees.x = 90.0
	add_child(collision)

	_face = Node3D.new()
	add_child(_face)
	var rings := [Color(1.0, 1.0, 1.0), Color(1.0, 0.3, 0.25), Color(1.0, 1.0, 1.0), Color(1.0, 0.75, 0.1)]
	for i in rings.size():
		var ring_radius := target_radius * (1.0 - float(i) / float(rings.size()))
		ArenaKit.deco_cylinder(_face, ring_radius, 0.08, Vector3(0.0, 0.0, 0.03 * i), rings[i], Vector3(90.0, 0.0, 0.0))
	ArenaKit.deco_box(self, Vector3(0.14, 0.14, 0.5), Vector3(0.0, 0.0, -0.3), Color(0.3, 0.3, 0.4))


## Called by a dart when it lands on the target.
func on_dart_hit(dart: DartProjectile, _point: Vector3) -> void:
	_trigger_hit(dart.shooter)


## Called when bonked by a melee weapon (e.g. Foam Bat).
func on_melee_hit(attacker: Actor) -> void:
	_trigger_hit(attacker)


func _trigger_hit(attacker: Actor) -> void:
	if not _ready_to_hit:
		return
	_ready_to_hit = false
	collision_layer = 0
	Sfx.play_at(&"ding", global_position, 1.0, 0.0, 0.05)
	hit.emit(attacker)
	var tween := create_tween()
	tween.tween_property(_face, "rotation:y", TAU * 3.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_face, "scale", Vector3.ONE * 0.35, 0.2)
	tween.tween_interval(reset_seconds)
	tween.tween_callback(func() -> void: _face.rotation.y = 0.0)
	tween.tween_property(_face, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_reset)


func _reset() -> void:
	_ready_to_hit = true
	collision_layer = Layers.TARGETS
