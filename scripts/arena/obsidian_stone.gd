class_name ObsidianStone
extends StaticBody3D
## Temporary cooled volcanic foam platform created when a Water or Ice dart hits the lava.
## Allows players and bots to safely traverse molten gaps for 6 seconds before melting back.

signal melted(stone: ObsidianStone)

const DURATION := 6.0
const SINK_TIME := 1.5

var lifetime: float = DURATION
var initial_y: float = 0.0

var _collision: CollisionShape3D
var _mesh_instance: MeshInstance3D
var _mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	initial_y = position.y
	_build_visuals()


func _build_visuals() -> void:
	_collision = CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 1.35
	cyl_shape.height = 0.32
	_collision.shape = cyl_shape
	_collision.position.y = 0.16
	add_child(_collision)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.14, 0.12, 0.16)
	_mat.roughness = 0.82
	_mat.metallic = 0.15
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.3, 0.05)
	_mat.emission_energy_multiplier = 0.4

	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.35
	mesh.bottom_radius = 1.45
	mesh.height = 0.32
	mesh.radial_segments = 16

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = _mat
	_mesh_instance.position.y = 0.16
	add_child(_mesh_instance)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= SINK_TIME:
		# Gradually sink back down into lava before vanishing
		var sink_ratio := 1.0 - maxf(lifetime / SINK_TIME, 0.0)
		position.y = initial_y - sink_ratio * 0.4
		if _mat != null:
			_mat.emission_energy_multiplier = 0.4 + sink_ratio * 1.5
	if lifetime <= 0.0:
		melted.emit(self)
		queue_free()
