class_name LavaHazard
extends Node3D
## Dynamic molten foam lava hazard that floods the arena floor in Floor is Lava mode.
## Submerged actors take continuous heat tag damage unless protected or standing
## on cooled obsidian foam stepping stones created by Water and Ice darts.

signal stone_created(stone: ObsidianStone)

const LAVA_SHADER := preload("res://assets/materials/lava_foam.gdshader")

@export var size: Vector2 = Vector2(85.0, 85.0)
@export var current_lava_y: float = -0.6
@export var heat_dps: float = 38.0

var active_stones: Array[ObsidianStone] = []

var _mesh_instance: MeshInstance3D
var _area: Area3D
var _collision_shape: CollisionShape3D
var _sizzle_timer: float = 0.0


func _ready() -> void:
	add_to_group(&"lava_hazards")
	position.y = current_lava_y
	_build_visuals()
	_build_area()


func _build_visuals() -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 36
	plane.subdivide_depth = 36

	var mat := ShaderMaterial.new()
	mat.shader = LAVA_SHADER

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = plane
	_mesh_instance.material_override = mat
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)


class LavaArea extends Area3D:
	var hazard: LavaHazard = null
	func on_dart_hit(dart: DartProjectile, hit_point: Vector3) -> void:
		if hazard != null:
			hazard.on_dart_hit(dart, hit_point)


func _build_area() -> void:
	var lava_area := LavaArea.new()
	lava_area.hazard = self
	_area = lava_area
	_area.name = "LavaArea"
	_area.collision_layer = Layers.TARGETS
	_area.collision_mask = Layers.ACTORS
	_area.monitoring = true

	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 3.0, size.y)

	_collision_shape = CollisionShape3D.new()
	_collision_shape.shape = box
	# Area extends slightly below and up to the lava surface
	_collision_shape.position = Vector3(0.0, -1.2, 0.0)
	_area.add_child(_collision_shape)
	add_child(_area)


func set_lava_height(new_y: float) -> void:
	current_lava_y = new_y
	position.y = new_y


func on_dart_hit(dart: DartProjectile, hit_point: Vector3) -> void:
	if dart == null or dart.data == null:
		return
	if dart.data.element == DartData.Element.WATER or dart.data.element == DartData.Element.ICE:
		spawn_obsidian_stone(Vector3(hit_point.x, current_lava_y, hit_point.z))
	elif dart.data.element == DartData.Element.FIRE:
		Sfx.play_at(&"sparkle", hit_point, 0.85, -1.0)


func spawn_obsidian_stone(at: Vector3) -> ObsidianStone:
	var stone := ObsidianStone.new()
	stone.position = at
	get_parent().add_child(stone)
	active_stones.append(stone)
	stone.melted.connect(func(s: ObsidianStone) -> void: active_stones.erase(s))
	Sfx.play_at(&"steam", at, 1.05, 0.0)
	stone_created.emit(stone)
	return stone


func _physics_process(delta: float) -> void:
	_sizzle_timer = maxf(_sizzle_timer - delta, 0.0)

	# Clean up any invalidated stones
	active_stones = active_stones.filter(func(s: ObsidianStone) -> bool: return is_instance_valid(s))

	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor == null or not actor.alive:
			continue

		# Check if actor's feet are touching or submerged in lava
		if actor.global_position.y > current_lava_y + 0.35:
			continue

		# Check if standing on an active obsidian stone platform
		var safe_on_stone := false
		for stone in active_stones:
			if is_instance_valid(stone):
				var h_dist := Vector2(actor.global_position.x - stone.global_position.x,
						actor.global_position.z - stone.global_position.z).length()
				if h_dist <= 1.45 and actor.global_position.y >= stone.global_position.y - 0.1:
					safe_on_stone = true
					break

		if safe_on_stone:
			continue

		actor.apply_hazard_tag(heat_dps * delta, self)

		if actor.elemental != null:
			actor.elemental.wet_left = 0.0  # Lava instantly boils away moisture

		if _sizzle_timer <= 0.0:
			_sizzle_timer = 0.4
			Sfx.play_at(&"lava_sizzle", actor.global_position, 1.0, -2.0, 0.1)
