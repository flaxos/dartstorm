class_name FoamBurst
extends CPUParticles3D
## A one-shot puff of colourful foam bits. Frees itself when finished.
##
## Budgeted: five Chainstorms hosing a wall would otherwise create hundreds of
## particle nodes a second. Ordinary impacts are limited per frame and in total
## (both scaled by the Visual Effects setting). "Important" bursts (someone
## getting tagged out, respawning) are rare and always shown.

## Most ordinary bursts alive at once at visual intensity 1.0.
const MAX_LIVE := 48
## Most ordinary bursts started in a single frame at visual intensity 1.0.
const MAX_PER_FRAME := 6

static var _mesh: BoxMesh
static var _shrink: Curve
static var _live: int = 0
static var _frame: int = -1
static var _spawned_this_frame: int = 0


## Spawns a burst and returns true, or returns false if the budget says no.
static func spawn(parent: Node, at: Vector3, tint: Color, amount_wanted: int = 10,
		speed: float = 4.0, normal: Vector3 = Vector3.UP, important: bool = false) -> bool:
	var intensity := GameSettings.visual_intensity
	var count := int(round(float(amount_wanted) * intensity))
	if count <= 0 or parent == null or not parent.is_inside_tree():
		return false
	if not important and not _take_budget(intensity):
		return false
	_ensure_shared()
	var burst := FoamBurst.new()
	burst.mesh = _mesh
	burst.amount = count
	burst.lifetime = 0.55
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.direction = normal
	burst.spread = 75.0
	burst.gravity = Vector3(0.0, -13.0, 0.0)
	burst.initial_velocity_min = speed * 0.5
	burst.initial_velocity_max = speed
	burst.angular_velocity_min = -400.0
	burst.angular_velocity_max = 400.0
	burst.scale_amount_min = 0.6
	burst.scale_amount_max = 1.4
	burst.scale_amount_curve = _shrink
	burst.color = tint
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_live += 1
	parent.add_child(burst)
	burst.global_position = at
	burst.emitting = true
	burst.get_tree().create_timer(burst.lifetime + 0.25).timeout.connect(burst.queue_free)
	return true


## Bursts currently alive (ordinary and important).
static func live_count() -> int:
	return _live


static func live_cap() -> int:
	return maxi(int(round(MAX_LIVE * clampf(GameSettings.visual_intensity, 0.2, 1.5))), 4)


func _exit_tree() -> void:
	_live = maxi(_live - 1, 0)


static func _take_budget(intensity: float) -> bool:
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_spawned_this_frame = 0
	var per_frame := maxi(int(round(MAX_PER_FRAME * clampf(intensity, 0.2, 1.5))), 1)
	if _spawned_this_frame >= per_frame or _live >= live_cap():
		return false
	_spawned_this_frame += 1
	return true


static func _ensure_shared() -> void:
	if _mesh != null:
		return
	_mesh = BoxMesh.new()
	_mesh.size = Vector3(0.09, 0.09, 0.09)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	_mesh.material = material
	_shrink = Curve.new()
	_shrink.add_point(Vector2(0.0, 1.0))
	_shrink.add_point(Vector2(0.6, 0.9))
	_shrink.add_point(Vector2(1.0, 0.0))
