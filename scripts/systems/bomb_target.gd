class_name BombTarget
extends Node3D
## Bomb Sites and Foam Time-Bomb system for Plant The Bomb (Search & Destroy).
## Attackers (Orange/Infiltrators) must plant the foam bomb at Site A or Site B.
## Defenders (Blue/Guardians) must prevent the plant or defuse before detonation.

signal bomb_picked_up(carrier: Actor)
signal bomb_dropped(pos: Vector3)
signal bomb_plant_started(site_name: String, carrier: Actor)
signal bomb_planted(site_name: String, at_position: Vector3)
signal bomb_defuse_started(defuser: Actor)
signal bomb_defused(defuser: Actor)
signal bomb_detonated(site_name: String, at_position: Vector3)
signal plant_progress(ratio: float)
signal defuse_progress(ratio: float)

enum BombState { CARRIED, DROPPED, PLANTING, PLANTED, DEFUSING, DEFUSED, DETONATED }

const PLANT_TIME := 2.5
const DEFUSE_TIME := 3.5
const FUSE_TIME := 40.0
const PICKUP_RADIUS := 1.8
const SITE_RADIUS := 4.2
const DEFUSE_RADIUS := 2.4

var state: BombState = BombState.DROPPED
var carrier: Actor = null
var active_site: String = ""
var fuse_left: float = FUSE_TIME
var plant_progress_left: float = 0.0
var defuse_progress_left: float = 0.0
var current_defuser: Actor = null

var _time: float = 0.0
var _last_beep: float = 0.0
var _sites: Dictionary = {} # "A": Area3D, "B": Area3D
var _bomb_model: Node3D
var _bomb_light: OmniLight3D
var _label: Label3D
var _pickup_area: Area3D


func _ready() -> void:
	add_to_group(&"bomb_target")
	_build_bomb_model()


## Sets up Site A and Site B locations from arena data.
func setup_sites(sites_data: Dictionary) -> void:
	for site_id: String in sites_data:
		var pos: Vector3 = sites_data[site_id]
		_create_site(site_id, pos)


func has_site(site_id: String) -> bool:
	return _sites.has(site_id)


func get_site_keys() -> Array:
	return _sites.keys()


func _create_site(site_id: String, pos: Vector3) -> void:
	var site_root := Node3D.new()
	site_root.name = "Site_" + site_id
	site_root.position = pos
	add_child(site_root)

	# 1. Site Floor Boundary Ring & Stencil
	var ring := ArenaKit.deco_cylinder(site_root, SITE_RADIUS, 0.08, Vector3(0.0, 0.04, 0.0), Color(0.95, 0.25, 0.15))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var inner := ArenaKit.deco_cylinder(site_root, SITE_RADIUS - 0.25, 0.09, Vector3(0.0, 0.045, 0.0), Color(0.12, 0.14, 0.18))
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Glowing beacon light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.35, 0.15)
	light.light_energy = 0.9
	light.omni_range = 8.0
	light.position = Vector3(0.0, 1.5, 0.0)
	site_root.add_child(light)

	# Floating 3D Site Name
	var label := Label3D.new()
	label.font = UiKit.font()
	label.font_size = 72
	label.pixel_size = 0.01
	label.outline_size = 14
	label.outline_modulate = UiKit.NAVY_DARK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.4
	label.modulate = Color(1.0, 0.85, 0.2)
	label.text = "SITE " + site_id
	site_root.add_child(label)

	# 2. Trigger Area
	var area := Area3D.new()
	area.name = "Area_" + site_id
	area.collision_layer = 0
	area.collision_mask = Layers.ACTORS
	area.monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = SITE_RADIUS
	shape.height = 3.0
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.5
	area.add_child(col)
	site_root.add_child(area)

	_sites[site_id] = area


func _build_bomb_model() -> void:
	_bomb_model = Node3D.new()
	_bomb_model.name = "BombModel"
	add_child(_bomb_model)

	# Sleek tactical briefcase / C4 foam pack
	ArenaKit.deco_box(_bomb_model, Vector3(0.38, 0.28, 0.14), Vector3(0.0, 0.14, 0.0), Color(0.18, 0.2, 0.24), Vector3.ZERO, 0.0, ArenaKit.SurfaceType.PLASTIC)
	# Dual foam explosive canisters
	ArenaKit.deco_cylinder(_bomb_model, 0.05, 0.34, Vector3(-0.09, 0.14, 0.08), Color(0.95, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), -1.0, ArenaKit.SurfaceType.PLASTIC)
	ArenaKit.deco_cylinder(_bomb_model, 0.05, 0.34, Vector3(0.09, 0.14, 0.08), Color(0.95, 0.45, 0.1), Vector3(90.0, 0.0, 0.0), -1.0, ArenaKit.SurfaceType.PLASTIC)
	# Keypad & digital display screen
	ArenaKit.deco_box(_bomb_model, Vector3(0.16, 0.08, 0.03), Vector3(0.0, 0.20, 0.08), Color(0.1, 0.8, 0.3), Vector3.ZERO, 0.4, ArenaKit.SurfaceType.PLASTIC)

	# Blinking LED Light
	_bomb_light = OmniLight3D.new()
	_bomb_light.light_color = Color(1.0, 0.1, 0.1)
	_bomb_light.light_energy = 1.5
	_bomb_light.omni_range = 4.0
	_bomb_light.position = Vector3(0.0, 0.25, 0.0)
	_bomb_model.add_child(_bomb_light)

	# Status Label
	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 48
	_label.pixel_size = 0.007
	_label.outline_size = 10
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 0.65
	_label.modulate = Color(1.0, 0.3, 0.2)
	_label.text = "FOAM BOMB"
	_bomb_model.add_child(_label)

	# Pickup Area for dropped bomb
	_pickup_area = Area3D.new()
	_pickup_area.name = "PickupArea"
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = Layers.ACTORS
	_pickup_area.monitorable = false
	var shape := CylinderShape3D.new()
	shape.radius = PICKUP_RADIUS
	shape.height = 2.0
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.0
	_pickup_area.add_child(col)
	_pickup_area.body_entered.connect(_on_pickup_entered)
	_bomb_model.add_child(_pickup_area)


## Spawns the bomb at `pos` and assigns it to `initial_carrier` (or leaves it dropped).
func spawn_bomb(pos: Vector3, initial_carrier: Actor = null) -> void:
	fuse_left = FUSE_TIME
	plant_progress_left = 0.0
	defuse_progress_left = 0.0
	current_defuser = null
	active_site = ""
	_bomb_model.visible = true
	_bomb_model.rotation = Vector3.ZERO

	if initial_carrier != null and is_instance_valid(initial_carrier):
		_attach_carrier(initial_carrier)
	else:
		state = BombState.DROPPED
		carrier = null
		_bomb_model.global_position = pos
		_update_label()


func _attach_carrier(actor: Actor) -> void:
	if carrier != null and is_instance_valid(carrier):
		if carrier.tagged_out.is_connected(_on_carrier_tagged_out):
			carrier.tagged_out.disconnect(_on_carrier_tagged_out)
	carrier = actor
	state = BombState.CARRIED
	plant_progress_left = 0.0
	defuse_progress_left = 0.0
	if not carrier.tagged_out.is_connected(_on_carrier_tagged_out):
		carrier.tagged_out.connect(_on_carrier_tagged_out)
	_update_label()
	Sfx.play(&"ammo", 1.2, -1.0)
	bomb_picked_up.emit(carrier)


func drop_bomb(drop_pos: Vector3) -> void:
	if carrier != null and is_instance_valid(carrier):
		if carrier.tagged_out.is_connected(_on_carrier_tagged_out):
			carrier.tagged_out.disconnect(_on_carrier_tagged_out)
	carrier = null
	state = BombState.DROPPED
	plant_progress_left = 0.0
	defuse_progress_left = 0.0
	_bomb_model.global_position = drop_pos
	_bomb_model.rotation = Vector3.ZERO
	_update_label()
	bomb_dropped.emit(drop_pos)


func _on_carrier_tagged_out(_victim: Actor, _attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	if carrier != null and is_instance_valid(carrier):
		drop_bomb(carrier.global_position)


func _on_pickup_entered(body: Node3D) -> void:
	if state != BombState.DROPPED:
		return
	var actor := body as Actor
	if actor == null or not actor.alive or actor.is_tagged_out:
		return
	# Attackers are team 1 (Orange/Infiltrators)
	if actor.team_id == 1:
		_attach_carrier(actor)


## Returns which site ("A" or "B") `pos` is inside, or empty string.
func get_site_at(pos: Vector3) -> String:
	for site_id: String in _sites:
		var area: Area3D = _sites[site_id]
		if area.global_position.distance_to(pos) <= SITE_RADIUS:
			return site_id
	return ""


## Returns the world position of Site A or Site B.
func get_site_position(site_id: String) -> Vector3:
	if _sites.has(site_id):
		var area: Area3D = _sites[site_id]
		if area != null:
			return area.global_position
	return Vector3.ZERO


## Returns current world position of the bomb.
func get_bomb_position() -> Vector3:
	if _bomb_model != null:
		return _bomb_model.global_position
	return global_position


## Returns the closest site ("A" or "B") to a given world position.
func get_closest_site(pos: Vector3) -> String:
	var closest_site := ""
	var closest_dist := INF
	for site_id: String in _sites:
		var area: Area3D = _sites[site_id]
		if area != null:
			var d := area.global_position.distance_to(pos)
			if d < closest_dist:
				closest_dist = d
				closest_site = site_id
	return closest_site


## Called by player or bot to start/continue planting when inside a site.
func progress_plant(actor: Actor, delta: float) -> bool:
	if state != BombState.CARRIED and state != BombState.PLANTING:
		return false
	if actor != carrier:
		return false
	var site := get_site_at(actor.global_position)
	if site.is_empty():
		plant_progress_left = 0.0
		state = BombState.CARRIED
		plant_progress.emit(0.0)
		return false

	if state != BombState.PLANTING:
		state = BombState.PLANTING
		plant_progress_left = 0.0
		active_site = site
		bomb_plant_started.emit(site, actor)
		Sfx.play(&"bomb_plant", 1.0, 1.0)

	plant_progress_left += delta
	var ratio := clampf(plant_progress_left / PLANT_TIME, 0.0, 1.0)
	plant_progress.emit(ratio)

	if plant_progress_left >= PLANT_TIME:
		_complete_plant(site, actor.global_position)
		return true
	return false


func cancel_plant() -> void:
	if state == BombState.PLANTING:
		state = BombState.CARRIED
		plant_progress_left = 0.0
		plant_progress.emit(0.0)


func _complete_plant(site: String, plant_pos: Vector3) -> void:
	if carrier != null and is_instance_valid(carrier):
		if carrier.tagged_out.is_connected(_on_carrier_tagged_out):
			carrier.tagged_out.disconnect(_on_carrier_tagged_out)
	carrier = null
	state = BombState.PLANTED
	active_site = site
	fuse_left = FUSE_TIME
	_bomb_model.global_position = plant_pos
	_bomb_model.rotation = Vector3.ZERO
	_last_beep = 0.0
	_update_label()
	plant_progress.emit(1.0)
	bomb_planted.emit(site, plant_pos)


## Called by player or bot (Defenders, team 0) to defuse a planted bomb.
func progress_defuse(actor: Actor, delta: float) -> bool:
	if state != BombState.PLANTED and state != BombState.DEFUSING:
		return false
	if actor.team_id != 0: # Defenders only
		return false
	if actor.global_position.distance_to(_bomb_model.global_position) > DEFUSE_RADIUS:
		cancel_defuse()
		return false

	if state != BombState.DEFUSING:
		state = BombState.DEFUSING
		defuse_progress_left = 0.0
		current_defuser = actor
		bomb_defuse_started.emit(actor)

	defuse_progress_left += delta
	var ratio := clampf(defuse_progress_left / DEFUSE_TIME, 0.0, 1.0)
	defuse_progress.emit(ratio)

	if defuse_progress_left >= DEFUSE_TIME:
		_complete_defuse(actor)
		return true
	return false


func cancel_defuse() -> void:
	if state == BombState.DEFUSING:
		state = BombState.PLANTED
		defuse_progress_left = 0.0
		current_defuser = null
		defuse_progress.emit(0.0)


func _complete_defuse(actor: Actor) -> void:
	state = BombState.DEFUSED
	current_defuser = null
	_update_label()
	defuse_progress.emit(1.0)
	Sfx.play(&"bomb_defuse", 1.0, 2.0)
	bomb_defused.emit(actor)


func _physics_process(delta: float) -> void:
	_time += delta

	match state:
		BombState.CARRIED, BombState.PLANTING:
			if carrier == null or not is_instance_valid(carrier) or not carrier.alive or carrier.is_tagged_out:
				drop_bomb(_bomb_model.global_position)
				return
			# Stick neatly onto carrier's backpack area
			var fwd := -carrier.global_transform.basis.z
			var up := carrier.global_transform.basis.y
			_bomb_model.global_position = carrier.global_position - fwd * 0.28 + up * 0.95
			_bomb_model.rotation = carrier.rotation
			_bomb_light.light_energy = 0.8 + sin(_time * 4.0) * 0.5
		BombState.DROPPED:
			_bomb_model.position.y += sin(_time * 3.0) * 0.002
			_bomb_light.light_energy = 0.5 + sin(_time * 2.0) * 0.3
		BombState.PLANTED, BombState.DEFUSING:
			fuse_left -= delta
			_update_label()

			# Dynamic ticking beeps that accelerate as fuse runs out
			var beep_interval := 1.0
			if fuse_left < 4.0:
				beep_interval = 0.2
			elif fuse_left < 10.0:
				beep_interval = 0.4
			elif fuse_left < 20.0:
				beep_interval = 0.7

			if _time - _last_beep >= beep_interval:
				_last_beep = _time
				Sfx.play_at(&"bomb_beep", _bomb_model.global_position, 1.0 + (1.0 - fuse_left / FUSE_TIME) * 0.5, 0.0)
				_bomb_light.light_energy = 3.0
			else:
				_bomb_light.light_energy = move_toward(_bomb_light.light_energy, 0.4, delta * 8.0)

			if fuse_left <= 0.0:
				_detonate()


func _detonate() -> void:
	state = BombState.DETONATED
	_bomb_model.visible = false
	_update_label()
	Sfx.play_at(&"bomb_detonate", _bomb_model.global_position, 1.0, 3.0)
	bomb_detonated.emit(active_site, _bomb_model.global_position)


func _update_label() -> void:
	match state:
		BombState.CARRIED:
			_label.text = "CARRIED"
		BombState.DROPPED:
			_label.text = "FOAM BOMB (E TO TAKE)"
		BombState.PLANTING:
			_label.text = "ARMING..."
		BombState.PLANTED, BombState.DEFUSING:
			_label.text = "PLANTED! (%.1fs)" % maxf(fuse_left, 0.0)
		BombState.DEFUSED:
			_label.text = "DEFUSED!"
		BombState.DETONATED:
			_label.text = "DETONATED!"
