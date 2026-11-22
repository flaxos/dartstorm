class_name DogHouse
extends StaticBody3D
## A dog house with a friendly cartoon dog lying in front of it. It's solid
## cover. Hit it (or the dog) with a dart and the dog jumps up and barks.
## Purely for fun: no points, and nobody gets hurt. The door faces local +Z.

signal barked

const SIZE := Vector3(2.0, 1.6, 2.2)
const BARK_COOLDOWN := 0.8
const FUR := Color(0.85, 0.62, 0.35)
const FUR_DARK := Color(0.55, 0.36, 0.2)

var _dog: Node3D
var _tail: Node3D
var _time: float = 0.0
var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0

	if ModelLoader.has_prop_model(&"dog_house"):
		var model_root := ModelLoader.instantiate_prop(&"dog_house")
		if model_root != null:
			while model_root.get_child_count() > 0:
				var c := model_root.get_child(0)
				model_root.remove_child(c)
				c.owner = null
				add_child(c)
			model_root.queue_free()
			_dog = find_child("_dog", true, false) as Node3D
			_tail = find_child("_tail", true, false) as Node3D
			return

	# Fallback procedural dog house
	var shape := BoxShape3D.new()
	shape.size = SIZE
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = SIZE.y * 0.5
	add_child(collision)

	ArenaKit.deco_box(self, SIZE, Vector3(0.0, SIZE.y * 0.5, 0.0), Color(0.9, 0.25, 0.22))
	var roof := PrismMesh.new()
	roof.size = Vector3(SIZE.x + 0.4, 0.9, SIZE.z + 0.3)
	ArenaKit.deco(self, roof, Vector3(0.0, SIZE.y + 0.45, 0.0), Color(0.35, 0.3, 0.55))
	ArenaKit.deco_box(self, Vector3(0.9, 1.0, 0.05), Vector3(0.0, 0.5, SIZE.z * 0.5 + 0.01), Color(0.12, 0.08, 0.1))
	var plate := ArenaKit.sign_text(self, "WOOF", Vector3(0.0, SIZE.y - 0.15, SIZE.z * 0.5 + 0.03), Vector3.ZERO, UiKit.CREAM, 60, 0.006)
	plate.outline_size = 8

	_dog = Node3D.new()
	_dog.position = Vector3(0.0, 0.0, SIZE.z * 0.5 + 0.9)
	add_child(_dog)
	var body := ArenaKit.deco_sphere(_dog, 0.38, Vector3(0.0, 0.3, 0.1), FUR, 0.7)
	body.scale = Vector3(0.9, 1.0, 1.4)
	ArenaKit.deco_sphere(_dog, 0.27, Vector3(0.0, 0.55, -0.42), FUR)
	ArenaKit.deco_sphere(_dog, 0.12, Vector3(0.0, 0.5, -0.66), FUR_DARK)
	ArenaKit.deco_sphere(_dog, 0.05, Vector3(0.0, 0.55, -0.77), Color(0.08, 0.05, 0.05))
	for side: float in [-1.0, 1.0]:
		ArenaKit.deco_sphere(_dog, 0.045, Vector3(side * 0.1, 0.64, -0.62), Color(0.08, 0.05, 0.05))
		var ear := ArenaKit.deco_box(_dog, Vector3(0.1, 0.26, 0.16), Vector3(side * 0.24, 0.6, -0.4), FUR_DARK)
		ear.rotation_degrees.z = side * 20.0
		ArenaKit.deco_sphere(_dog, 0.09, Vector3(side * 0.2, 0.08, -0.3), FUR)
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 0.42, 0.55)
	_dog.add_child(_tail)
	var tail_mesh := ArenaKit.deco_cylinder(_tail, 0.05, 0.4, Vector3(0.0, 0.18, 0.0), FUR_DARK)
	tail_mesh.rotation_degrees.x = 20.0


func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _tail != null:
		_tail.rotation.z = sin(_time * 9.0) * 0.6


## Called by a dart that lands on the dog house.
func on_dart_hit(_dart: DartProjectile, _point: Vector3) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = BARK_COOLDOWN
	var dog_pos: Vector3 = (_dog.global_position if is_inside_tree() else position) if _dog != null else position
	Sfx.play_at(&"woof", dog_pos + Vector3.UP * 0.5, 1.0, 0.0, 0.08)
	barked.emit()
	if _dog != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_dog, "position:y", 0.7, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_dog, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
