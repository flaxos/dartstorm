class_name WindField
extends Node
## Answers "what is the wind doing at this point?" for darts and the HUD.
## It sums a global breeze with every registered WindZone. Dynamic weather
## (Tempest Treehouse, storms) only needs to animate `global_wind` or the zones.

## Arena-wide wind acceleration in m/s^2. Zero means calm outside wind zones.
@export var global_wind: Vector3 = Vector3.ZERO

var _zones: Array[WindZone] = []


func _enter_tree() -> void:
	add_to_group(&"wind_field")


func _ready() -> void:
	# Pick up zones that were ready before this field existed.
	for node in get_tree().get_nodes_in_group(&"wind_zones"):
		var zone := node as WindZone
		if zone != null and is_ancestor_of_arena(zone):
			register_zone(zone)


func register_zone(zone: WindZone) -> void:
	if not _zones.has(zone):
		_zones.append(zone)
		zone.tree_exiting.connect(unregister_zone.bind(zone), CONNECT_ONE_SHOT)


func unregister_zone(zone: WindZone) -> void:
	_zones.erase(zone)


## Wind acceleration (m/s^2) at a world position.
func get_wind_at(point: Vector3) -> Vector3:
	var wind := global_wind
	for zone in _zones:
		wind += zone.get_wind_at(point)
	return wind


## Zones belong to the field that shares their arena (its parent node).
func is_ancestor_of_arena(zone: WindZone) -> bool:
	var arena := get_parent()
	return arena == null or arena.is_ancestor_of(zone)
