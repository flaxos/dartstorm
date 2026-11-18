class_name BaseBarricade
extends StaticBody3D
## Destructible foam/wood barricade defending lane choke-points in Zombie Siege.
## Absorbs zombie melee attacks to protect the Base Core.
## Can be rebuilt during the Intermission phase using earned Scrap.

signal health_changed(current: float, max_health: float)
signal damaged(amount: float)
signal broken
signal repaired

const MAX_HEALTH := 250.0

var max_health: float = MAX_HEALTH
var health: float = MAX_HEALTH
var is_broken: bool = false

var _mesh_container: Node3D
var _collision_shape: CollisionShape3D
var _boards: Array[MeshInstance3D] = []
var _flash_left: float = 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	_build_visuals()


func _build_visuals() -> void:
	_collision_shape = CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(3.0, 1.6, 0.8)
	_collision_shape.shape = box_shape
	_collision_shape.position = Vector3(0.0, 0.8, 0.0)
	add_child(_collision_shape)

	_mesh_container = Node3D.new()
	add_child(_mesh_container)

	# 2 Vertical posts
	var post_mat := ArenaKit.mat(Color(0.45, 0.3, 0.18), 0.7)
	for x in [-1.3, 1.3]:
		var post := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(0.24, 1.7, 0.24)
		post.mesh = p_mesh
		post.material_override = post_mat
		post.position = Vector3(x, 0.85, 0.0)
		_mesh_container.add_child(post)
		_boards.append(post)

	# 4 Horizontal fortified foam planks
	var plank_colors := [
		Color(0.65, 0.45, 0.25),
		Color(0.72, 0.52, 0.28),
		Color(0.58, 0.38, 0.22),
		Color(0.68, 0.48, 0.26)
	]
	for i in 4:
		var plank := MeshInstance3D.new()
		var b_mesh := BoxMesh.new()
		b_mesh.size = Vector3(2.8, 0.28, 0.12)
		plank.mesh = b_mesh
		plank.material_override = ArenaKit.mat(plank_colors[i % plank_colors.size()], 0.6)
		plank.position = Vector3(0.0, 0.3 + i * 0.36, (0.05 if i % 2 == 0 else -0.05))
		plank.rotation_degrees.z = (randf() - 0.5) * 2.0
		_mesh_container.add_child(plank)
		_boards.append(plank)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_restore_board_materials()


func damage(amount: float) -> void:
	if is_broken or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	damaged.emit(amount)
	_flash_hit()

	if health <= 0.0:
		break_barricade()


func _flash_hit() -> void:
	_flash_left = 0.08
	var flash_mat := ArenaKit.mat(Color(1.0, 0.3, 0.2), 0.3)
	for b in _boards:
		b.material_override = flash_mat


func _restore_board_materials() -> void:
	var ratio := health / max_health
	var base_col := Color(0.65, 0.45, 0.25).lerp(Color(0.3, 0.2, 0.15), 1.0 - ratio)
	var mat := ArenaKit.mat(base_col, 0.7)
	for b in _boards:
		b.material_override = mat


func break_barricade() -> void:
	if is_broken:
		return
	is_broken = true
	health = 0.0
	_mesh_container.visible = false
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)
	broken.emit()
	if has_node("/root/Sfx"):
		(get_node("/root/Sfx") as Node).call("play", &"tag")


func rebuild() -> void:
	is_broken = false
	health = max_health
	_mesh_container.visible = true
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", false)
	_restore_board_materials()
	health_changed.emit(health, max_health)
	repaired.emit()
	if has_node("/root/Sfx"):
		(get_node("/root/Sfx") as Node).call("play", &"pickup")
