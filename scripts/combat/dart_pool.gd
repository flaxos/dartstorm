class_name DartPool
extends Node3D
## Owns every dart in a match. Darts are created once and recycled, and the total
## number alive is capped so the Chainstorm cannot melt the frame rate.

## Emitted for every dart impact so effects/audio can react without darts
## knowing about them. `kind` is a DartProjectile.Impact value.
signal impact(kind: int, at: Vector3, normal: Vector3, color: Color)
signal elemental_impact(element: DartData.Element, kind: int, at: Vector3, normal: Vector3, color: Color)


## Loaded at runtime, not preloaded: dart_projectile.gd refers back to
## DartPool, and a preload here makes a load cycle when the editor re-imports.
const DART_SCENE_PATH := "res://scenes/projectiles/dart_projectile.tscn"

@export var max_active: int = 400

## Set by the match so darts can ask what the wind is doing.
var wind_field: WindField
var persists_as_pickup: bool = false

var _idle: Array[DartProjectile] = []
var _live: Array[DartProjectile] = []
var _dart_scene: PackedScene


func _ready() -> void:
	_dart_scene = load(DART_SCENE_PATH) as PackedScene
	if _dart_scene == null:
		push_error("DartPool: could not load %s, using plain DartProjectile nodes." % DART_SCENE_PATH)


func fire(data: DartData, origin: Vector3, direction: Vector3, shooter: Actor,
		weapon: WeaponData, color: Color, exclude: Array[RID]) -> DartProjectile:
	var dart: DartProjectile
	if _live.size() >= max_active:
		dart = _live.pop_front()  # Recycle the oldest dart still flying.
		if dart.scavengeable:
			DartProjectile.resting_pickups.erase(dart)
			dart.scavengeable = false
	elif not _idle.is_empty():
		dart = _idle.pop_back()
	else:
		dart = _dart_scene.instantiate() as DartProjectile if _dart_scene != null else DartProjectile.new()
		dart.pool = self
		add_child(dart)
	_live.append(dart)
	dart.launch(data, origin, direction, shooter, weapon, color, exclude)
	return dart


func release(dart: DartProjectile) -> void:
	_live.erase(dart)
	_idle.append(dart)


func report_impact(kind: int, at: Vector3, normal: Vector3, color: Color, element: DartData.Element = DartData.Element.NONE) -> void:
	impact.emit(kind, at, normal, color)
	if element != DartData.Element.NONE:
		elemental_impact.emit(element, kind, at, normal, color)


func live_count() -> int:
	return _live.size()
