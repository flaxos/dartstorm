class_name JumpPad
extends Node3D
## A backyard trampoline. Anyone who lands on it is bounced high into the air.

@export var launch_speed: float = 15.5
@export var pad_radius: float = 1.5
@export var pad_color: Color = Color(1.0, 0.35, 0.6)

var _area: Area3D
var _mat: MeshInstance3D
var _squash: float = 0.0


func _ready() -> void:
	ArenaKit.deco_cylinder(self, pad_radius + 0.15, 0.14, Vector3(0.0, 0.07, 0.0), Color(0.15, 0.2, 0.35))
	_mat = ArenaKit.deco_cylinder(self, pad_radius, 0.06, Vector3(0.0, 0.16, 0.0), pad_color)
	ArenaKit.deco_cylinder(self, pad_radius * 0.45, 0.065, Vector3(0.0, 0.165, 0.0), Color(1.0, 0.9, 0.3))

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.ACTORS
	_area.monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = pad_radius
	shape.height = 0.6
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.3
	_area.add_child(collision)
	add_child(_area)


func _physics_process(delta: float) -> void:
	_squash = move_toward(_squash, 0.0, delta * 3.0)
	_mat.position.y = 0.16 - _squash * 0.08
	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor != null and actor.alive and actor.velocity.y <= 0.5:
			actor.launch(launch_speed)
			_squash = 1.0
			Sfx.play_at(&"boing", global_position, 1.0, 0.0, 0.08)
