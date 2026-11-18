class_name FoamGrenade
extends RigidBody3D
## A bouncy throwable cartoon foam grenade. Ticking LED fuse detonates after 1.8s
## into a 360-degree radial barrage of 16 foam darts, a squishy blast wave (+65 tag
## damage and physics knockback), and a colorful confetti cloud.

const FUSE_TIME := 1.8
const BLAST_RADIUS := 4.5
const MAX_BLAST_DAMAGE := 65.0
const MIN_BLAST_DAMAGE := 20.0
const IMPULSE_FORCE := 11.5
const DART_BURST_COUNT := 16

var thrower: Actor = null
var team_id: int = 0
var dart_pool: DartPool = null
var time_left: float = FUSE_TIME

var _blink_timer: float = 0.0
var _blink_state: bool = false
var _exploded: bool = false

var _collision: CollisionShape3D
var _body_mesh: MeshInstance3D
var _led_mesh: MeshInstance3D
var _led_mat: StandardMaterial3D
var _led_light: OmniLight3D
var _dart_data: DartData


func _ready() -> void:
	add_to_group(&"grenades")
	mass = 0.35
	collision_layer = Layers.TARGETS
	collision_mask = Layers.WORLD | Layers.ACTORS
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.58
	phys_mat.friction = 0.42
	physics_material_override = phys_mat

	_build_visuals()
	_prepare_dart_data()


func _build_visuals() -> void:
	_collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.16
	shape.height = 0.38
	_collision.shape = shape
	add_child(_collision)

	# Main cylinder body
	var body_mesh_data := CylinderMesh.new()
	body_mesh_data.top_radius = 0.15
	body_mesh_data.bottom_radius = 0.15
	body_mesh_data.height = 0.32
	body_mesh_data.radial_segments = 16

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.95, 0.48, 0.12)  # High-vis foam safety orange
	body_mat.roughness = 0.75

	_body_mesh = MeshInstance3D.new()
	_body_mesh.mesh = body_mesh_data
	_body_mesh.material_override = body_mat
	add_child(_body_mesh)

	# Dark rubber protective grip caps on top and bottom
	var rubber_mat := StandardMaterial3D.new()
	rubber_mat.albedo_color = Color(0.18, 0.20, 0.26)
	rubber_mat.roughness = 0.88

	for cap_y: float in [-0.15, 0.15]:
		var cap := MeshInstance3D.new()
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.165
		cap_mesh.bottom_radius = 0.165
		cap_mesh.height = 0.05
		cap_mesh.radial_segments = 16
		cap.mesh = cap_mesh
		cap.material_override = rubber_mat
		cap.position.y = cap_y
		add_child(cap)

	# Top blinking LED apex
	_led_mat = StandardMaterial3D.new()
	_led_mat.albedo_color = Color(1.0, 0.2, 0.1)
	_led_mat.emission_enabled = true
	_led_mat.emission = Color(1.0, 0.2, 0.1)
	_led_mat.emission_energy_multiplier = 0.5

	_led_mesh = MeshInstance3D.new()
	var led_shape := SphereMesh.new()
	led_shape.radius = 0.05
	led_shape.height = 0.09
	_led_mesh.mesh = led_shape
	_led_mesh.material_override = _led_mat
	_led_mesh.position.y = 0.20
	add_child(_led_mesh)

	_led_light = OmniLight3D.new()
	_led_light.light_color = Color(1.0, 0.3, 0.1)
	_led_light.light_energy = 1.2
	_led_light.omni_range = 2.4
	_led_light.position.y = 0.22
	add_child(_led_light)


func _prepare_dart_data() -> void:
	_dart_data = DartData.new()
	_dart_data.initial_speed = 34.0
	_dart_data.gravity_multiplier = 0.7
	_dart_data.air_drag = 0.25
	_dart_data.max_lifetime = 1.2
	_dart_data.tag_power = 22.0
	_dart_data.element = DartData.Element.NONE


func launch(origin: Vector3, impulse_dir: Vector3, impulse_strength: float = 16.0) -> void:
	global_position = origin
	linear_velocity = impulse_dir.normalized() * impulse_strength
	angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))


func _process(delta: float) -> void:
	if _exploded:
		return

	time_left -= delta
	_blink_timer -= delta

	var blink_interval := clampf((time_left / FUSE_TIME) * 0.32, 0.06, 0.32)
	if _blink_timer <= 0.0:
		_blink_timer = blink_interval
		_blink_state = not _blink_state
		if _led_mat != null:
			_led_mat.emission_energy_multiplier = 3.5 if _blink_state else 0.4
		if _led_light != null:
			_led_light.visible = _blink_state
		if _blink_state:
			var pitch := lerpf(1.8, 1.0, clampf(time_left / FUSE_TIME, 0.0, 1.0))
			Sfx.play_at(&"fuse_beep", global_position, pitch, -6.0, 0.04)

	if time_left <= 0.0:
		explode()


func _on_body_entered(_body: Node) -> void:
	if linear_velocity.length_squared() > 1.5:
		Sfx.play_at(&"grenade_bounce", global_position, randf_range(0.9, 1.15), -4.0, 0.1)


func explode() -> void:
	if _exploded:
		return
	_exploded = true

	var blast_pos := global_position
	Sfx.play_at(&"grenade_blast", blast_pos, 1.0, 2.0)

	# Confetti celebration cloud
	var parent_node := get_parent()
	if parent_node != null:
		FoamBurst.spawn(parent_node, blast_pos, Color(1.0, 0.52, 0.12), 24, 6.0, Vector3.UP, true)

	# 1. Radial Dart Barrage (16 darts fired in 3D sphere)
	if dart_pool != null and is_instance_valid(dart_pool):
		for i in DART_BURST_COUNT:
			var phi := acos(1.0 - 2.0 * (float(i) + 0.5) / float(DART_BURST_COUNT))
			var theta := PI * (1.0 + sqrt(5.0)) * float(i)
			var dir := Vector3(sin(phi) * cos(theta), absf(cos(phi)) * 0.7 + 0.15, sin(phi) * sin(theta)).normalized()
			var dart_origin := blast_pos + Vector3.UP * 0.1 + dir * 0.25
			dart_pool.fire(_dart_data, dart_origin, dir, thrower, null, Color(1.0, 0.6, 0.15), [get_rid()])

	# 2. Direct Area Blast & Physics Knockback
	var actors := get_tree().get_nodes_in_group(&"actors")
	for node in actors:
		var actor := node as Actor
		if actor == null or not is_instance_valid(actor) or not actor.alive:
			continue
		var dist := blast_pos.distance_to(actor.global_position)
		if dist <= BLAST_RADIUS:
			var falloff := 1.0 - (dist / BLAST_RADIUS)
			var tag_damage := lerpf(MIN_BLAST_DAMAGE, MAX_BLAST_DAMAGE, falloff)
			actor.apply_blast_tag(tag_damage, thrower)

			var push_dir := (actor.global_position - blast_pos).normalized()
			push_dir.y = maxf(push_dir.y, 0.4)
			actor.velocity += push_dir * (IMPULSE_FORCE * falloff)

	# 3. Barricade and Core damage in Zombie Siege
	var barricades := get_tree().get_nodes_in_group(&"base_barricades")
	for node in barricades:
		var b := node as BaseBarricade
		if b != null and not b.is_broken and blast_pos.distance_to(b.global_position) <= BLAST_RADIUS:
			b.damage(MAX_BLAST_DAMAGE * 0.8)

	queue_free()
