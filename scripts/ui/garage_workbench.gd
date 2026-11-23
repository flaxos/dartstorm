class_name GarageWorkbench
extends Node3D
## Dedicated 3D Garage Workshop environment for the backyard blaster workbench:
## Features a wooden butcher-block workbench, green cutting mat, articulated lamp,
## vise, pegboard with tools, interactive 3D blaster turntable, orbit camera,
## and a test-fire dartboard.

signal test_fired()

const TABLE_HEIGHT := 0.86
const CONCRETE_COLOR := Color(0.72, 0.72, 0.74)
const WALL_COLOR := Color(0.88, 0.86, 0.82)
const WOOD_TOP := Color(0.78, 0.52, 0.30)
const STEEL_LEG := Color(0.14, 0.16, 0.20)
const CUTTING_MAT := Color(0.12, 0.38, 0.22)
const VISE_BLUE := Color(0.18, 0.36, 0.65)
const PEGBOARD_COLOR := Color(0.60, 0.48, 0.36)

var active_blaster_id: StringName = &"pocket_popper"
var active_blaster_model: BlasterModel = null
var active_weapon_data: WeaponData = null

var camera: Camera3D = null
var turntable: Node3D = null
var dart_target: Node3D = null

# Orbit Camera Controls (spherical coordinates: yaw horizontal, pitch elevation above table)
var yaw: float = -0.55
var pitch: float = 0.38
var distance: float = 1.35
var target_pos: Vector3 = Vector3(0.0, 0.98, 0.0)

var _curr_yaw: float = -0.55
var _curr_pitch: float = 0.38
var _curr_dist: float = 1.35
var _curr_target: Vector3 = Vector3(0.0, 0.98, 0.0)

var _dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

# Test Fire Dart FX
var _test_dart: Node3D = null
var _dart_start: Vector3 = Vector3.ZERO
var _dart_end: Vector3 = Vector3.ZERO
var _dart_progress: float = 1.0


func _ready() -> void:
	_build_garage()
	_build_workbench_table()
	_build_decorations()
	_build_camera()
	load_blaster(active_blaster_id)


func _build_garage() -> void:
	# Garage Concrete Floor (smooth sealed workshop concrete)
	var floor_mesh := ArenaKit.box(self, Vector3(14.0, 0.2, 12.0), Vector3(0.0, -0.1, 0.0), CONCRETE_COLOR, Vector3.ZERO, ArenaKit.SurfaceType.DEFAULT)
	if floor_mesh != null:
		floor_mesh.name = "GarageFloor"

	# Back wall (North, behind workbench)
	ArenaKit.box(self, Vector3(14.0, 5.0, 0.2), Vector3(0.0, 2.5, -2.5), WALL_COLOR, Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	# Baseboard trim along back wall
	ArenaKit.deco_box(self, Vector3(14.0, 0.16, 0.04), Vector3(0.0, 0.08, -2.38), WOOD_TOP.darkened(0.3))

	# Left Wall (West)
	ArenaKit.box(self, Vector3(0.2, 5.0, 12.0), Vector3(-6.5, 2.5, 0.0), WALL_COLOR.darkened(0.05), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)
	# Right Wall (East)
	ArenaKit.box(self, Vector3(0.2, 5.0, 12.0), Vector3(6.5, 2.5, 0.0), WALL_COLOR.darkened(0.05), Vector3.ZERO, ArenaKit.SurfaceType.PLASTIC)

	# Ceiling rafters (exposed wooden roof trusses)
	for z in [-1.5, 0.5, 2.5]:
		ArenaKit.deco_box(self, Vector3(13.0, 0.18, 0.18), Vector3(0.0, 4.4, z), WOOD_TOP.darkened(0.25))
		ArenaKit.deco_box(self, Vector3(0.18, 1.2, 0.18), Vector3(-3.5, 3.8, z), WOOD_TOP.darkened(0.25))
		ArenaKit.deco_box(self, Vector3(0.18, 1.2, 0.18), Vector3(3.5, 3.8, z), WOOD_TOP.darkened(0.25))

	# Garage Ceiling Fluorescent Shop Light
	var shop_light := OmniLight3D.new()
	shop_light.position = Vector3(0.0, 3.8, 0.0)
	shop_light.light_color = Color(0.92, 0.95, 1.0)
	shop_light.light_energy = 1.4
	shop_light.omni_range = 12.0
	shop_light.shadow_enabled = false
	add_child(shop_light)

	# Studio Key/Fill Light for crisp blaster highlights and specular shine
	var studio_key := DirectionalLight3D.new()
	studio_key.rotation_degrees = Vector3(-35.0, 40.0, 0.0)
	studio_key.light_color = Color(1.0, 0.97, 0.92)
	studio_key.light_energy = 0.85
	studio_key.shadow_enabled = false
	add_child(studio_key)


func _build_workbench_table() -> void:
	# Heavy solid butcher block tabletop
	ArenaKit.box(self, Vector3(2.4, 0.08, 1.1), Vector3(0.0, TABLE_HEIGHT, 0.0), WOOD_TOP, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# 4 Heavy Steel Legs
	for x in [-1.05, 1.05]:
		for z in [-0.42, 0.42]:
			ArenaKit.deco_box(self, Vector3(0.08, TABLE_HEIGHT, 0.08), Vector3(x, TABLE_HEIGHT * 0.5, z), STEEL_LEG)

	# Lower storage shelf
	ArenaKit.box(self, Vector3(2.2, 0.04, 0.9), Vector3(0.0, 0.22, 0.0), WOOD_TOP.darkened(0.2), Vector3.ZERO, ArenaKit.SurfaceType.WOOD)

	# Items on lower shelf (ammo crates / plastic storage tubs)
	ArenaKit.deco_box(self, Vector3(0.45, 0.32, 0.38), Vector3(-0.65, 0.38, 0.0), Color(0.2, 0.5, 0.8))
	ArenaKit.deco_box(self, Vector3(0.52, 0.28, 0.34), Vector3(0.55, 0.36, 0.05), Color(0.9, 0.45, 0.15))

	# Self-Healing Green Cutting Mat in center of table
	ArenaKit.deco_box(self, Vector3(1.35, 0.008, 0.68), Vector3(0.0, TABLE_HEIGHT + 0.044, 0.0), CUTTING_MAT)
	# Cutting mat grid border
	ArenaKit.deco_box(self, Vector3(1.30, 0.009, 0.015), Vector3(0.0, TABLE_HEIGHT + 0.045, 0.31), Color(0.85, 0.95, 0.85, 0.8))
	ArenaKit.deco_box(self, Vector3(1.30, 0.009, 0.015), Vector3(0.0, TABLE_HEIGHT + 0.045, -0.31), Color(0.85, 0.95, 0.85, 0.8))

	# Heavy Blue Workshop Bench Vise on Left Corner
	var vise_pos := Vector3(-1.02, TABLE_HEIGHT + 0.04, 0.25)
	ArenaKit.deco_box(self, Vector3(0.18, 0.12, 0.22), vise_pos + Vector3(0.0, 0.06, 0.0), VISE_BLUE)
	ArenaKit.deco_box(self, Vector3(0.08, 0.08, 0.22), vise_pos + Vector3(-0.06, 0.14, 0.0), STEEL_LEG)
	ArenaKit.deco_box(self, Vector3(0.08, 0.08, 0.22), vise_pos + Vector3(0.06, 0.14, 0.0), STEEL_LEG)
	ArenaKit.deco_cylinder(self, 0.01, 0.24, vise_pos + Vector3(-0.12, 0.08, 0.0), Color(0.85, 0.85, 0.9), Vector3(0.0, 0.0, 90.0))

	# Articulated Desk Lamp on Right Side
	var lamp_base := Vector3(0.95, TABLE_HEIGHT + 0.04, -0.25)
	ArenaKit.deco_cylinder(self, 0.09, 0.02, lamp_base + Vector3(0.0, 0.01, 0.0), STEEL_LEG)
	# Cantilever arm struts
	ArenaKit.deco_cylinder(self, 0.012, 0.38, lamp_base + Vector3(-0.08, 0.18, 0.05), STEEL_LEG, Vector3(-20.0, 0.0, -15.0))
	ArenaKit.deco_cylinder(self, 0.012, 0.36, lamp_base + Vector3(-0.24, 0.38, 0.10), STEEL_LEG, Vector3(25.0, 0.0, -40.0))
	# Conical lamp shade angled down
	var shade_pos := lamp_base + Vector3(-0.38, 0.45, 0.14)
	ArenaKit.deco_cylinder(self, 0.07, 0.10, shade_pos, Color(0.95, 0.75, 0.2), Vector3(35.0, 30.0, 0.0))

	# Warm Focused Task Lamp Light illuminating the turntable!
	var task_light := OmniLight3D.new()
	task_light.position = shade_pos + Vector3(0.0, -0.05, 0.0)
	task_light.light_color = Color(1.0, 0.92, 0.78)
	task_light.light_energy = 2.2
	task_light.omni_range = 3.6
	task_light.shadow_enabled = true
	add_child(task_light)


func _build_decorations() -> void:
	# Wooden Wall Pegboard behind table
	ArenaKit.box(self, Vector3(2.4, 1.3, 0.04), Vector3(0.0, 1.85, -2.38), PEGBOARD_COLOR, Vector3.ZERO, ArenaKit.SurfaceType.WOOD)
	ArenaKit.deco_box(self, Vector3(2.48, 0.06, 0.06), Vector3(0.0, 2.52, -2.37), WOOD_TOP.darkened(0.4))
	ArenaKit.deco_box(self, Vector3(2.48, 0.06, 0.06), Vector3(0.0, 1.18, -2.37), WOOD_TOP.darkened(0.4))

	# Pegboard Hanging Tools (Wrench, Pliers, Screwdrivers)
	ArenaKit.deco_box(self, Vector3(0.04, 0.32, 0.015), Vector3(-0.8, 1.9, -2.34), Color(0.8, 0.82, 0.85))
	ArenaKit.deco_box(self, Vector3(0.05, 0.24, 0.02), Vector3(-0.6, 1.85, -2.34), Color(0.9, 0.2, 0.2))
	ArenaKit.deco_box(self, Vector3(0.04, 0.28, 0.02), Vector3(-0.4, 1.88, -2.34), Color(0.2, 0.2, 0.25))

	# Garage Dartboard Test Target (concentric foam target circles)
	dart_target = Node3D.new()
	dart_target.name = "DartTarget"
	dart_target.position = Vector3(0.65, 1.85, -2.35)
	add_child(dart_target)

	# Target backboard (Black square)
	ArenaKit.deco_box(dart_target, Vector3(0.72, 0.72, 0.03), Vector3.ZERO, Color(0.12, 0.14, 0.18))
	# White outer circle (25 pts)
	ArenaKit.deco_cylinder(dart_target, 0.32, 0.015, Vector3(0.0, 0.0, 0.02), Color(0.95, 0.95, 0.95), Vector3(90.0, 0.0, 0.0))
	# Blue ring (50 pts)
	ArenaKit.deco_cylinder(dart_target, 0.24, 0.018, Vector3(0.0, 0.0, 0.025), Color(0.2, 0.55, 0.95), Vector3(90.0, 0.0, 0.0))
	# Red ring (75 pts)
	ArenaKit.deco_cylinder(dart_target, 0.15, 0.020, Vector3(0.0, 0.0, 0.03), Color(0.95, 0.25, 0.2), Vector3(90.0, 0.0, 0.0))
	# Yellow Bullseye (100 pts!)
	ArenaKit.deco_cylinder(dart_target, 0.06, 0.022, Vector3(0.0, 0.0, 0.035), Color(1.0, 0.85, 0.15), Vector3(90.0, 0.0, 0.0))

	# Small workshop accessories on the cutting mat
	var mat_y := TABLE_HEIGHT + 0.048
	# Roll of blue electrical tape
	ArenaKit.deco_cylinder(self, 0.042, 0.026, Vector3(-0.48, mat_y + 0.013, 0.18), Color(0.15, 0.45, 0.95), Vector3(90.0, 0.0, 0.0))
	ArenaKit.deco_cylinder(self, 0.024, 0.028, Vector3(-0.48, mat_y + 0.013, 0.18), Color(0.7, 0.7, 0.75), Vector3(90.0, 0.0, 0.0))
	# Roll of orange tape
	ArenaKit.deco_cylinder(self, 0.038, 0.022, Vector3(-0.40, mat_y + 0.011, 0.24), Color(1.0, 0.45, 0.05), Vector3(90.0, 0.0, 0.0))
	# Screwdrivers lying on bench
	ArenaKit.deco_box(self, Vector3(0.022, 0.022, 0.16), Vector3(0.48, mat_y + 0.01, 0.18), Color(0.9, 0.2, 0.15), Vector3(0.0, 25.0, 0.0))
	ArenaKit.deco_cylinder(self, 0.004, 0.10, Vector3(0.53, mat_y + 0.01, 0.10), Color(0.85, 0.85, 0.9), Vector3(90.0, 25.0, 0.0))
	# Spare upgrade spring coils
	for i in 3:
		ArenaKit.deco_cylinder(self, 0.014, 0.06, Vector3(-0.35 + float(i) * 0.04, mat_y + 0.014, -0.22), Color(0.88, 0.75, 0.3), Vector3(0.0, 0.0, 90.0))
	# Loose foam darts on mat
	for i in 3:
		var dart_z := 0.20 + float(i) * 0.04
		ArenaKit.deco_cylinder(self, 0.008, 0.07, Vector3(0.32, mat_y + 0.008, dart_z), Color(0.2, 0.6, 1.0), Vector3(0.0, 0.0, 90.0))
		ArenaKit.deco_cylinder(self, 0.010, 0.014, Vector3(0.36, mat_y + 0.008, dart_z), Color(1.0, 0.45, 0.05), Vector3(0.0, 0.0, 90.0))

	# Padded foam gun cradle / stand in center
	var stand_y := mat_y + 0.025
	ArenaKit.deco_box(self, Vector3(0.04, 0.05, 0.03), Vector3(-0.16, stand_y, 0.0), STEEL_LEG)
	ArenaKit.deco_box(self, Vector3(0.04, 0.05, 0.03), Vector3(0.16, stand_y, 0.0), STEEL_LEG)

	# Turntable root node for blaster
	turntable = Node3D.new()
	turntable.name = "Turntable"
	turntable.position = Vector3(0.0, stand_y + 0.04, 0.0)
	add_child(turntable)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "WorkbenchCamera"
	camera.fov = 48.0
	camera.current = false
	add_child(camera)
	_update_camera_transform(true)


func _update_camera_transform(instant: bool = false) -> void:
	if camera == null:
		return
	if instant:
		_curr_yaw = yaw
		_curr_pitch = pitch
		_curr_dist = distance
		_curr_target = target_pos

	var cos_p := cos(_curr_pitch)
	var offset := Vector3(
		sin(_curr_yaw) * cos_p * _curr_dist,
		sin(_curr_pitch) * _curr_dist,
		cos(_curr_yaw) * cos_p * _curr_dist
	)
	var global_target := to_global(_curr_target)
	camera.global_position = to_global(_curr_target + offset)
	camera.look_at(global_target, Vector3.UP)


func rotate_orbit(delta: Vector2) -> void:
	yaw -= delta.x * 0.007
	pitch = clampf(pitch - delta.y * 0.006, 0.06, 1.25)


func zoom_orbit(delta: float) -> void:
	distance = clampf(distance + delta, 0.65, 2.4)


func reset_camera_view() -> void:
	yaw = -0.55
	pitch = 0.38
	distance = 1.35
	target_pos = Vector3(0.0, 0.98, 0.0)
	_curr_yaw = yaw
	_curr_pitch = pitch
	_curr_dist = distance
	_curr_target = target_pos
	_update_camera_transform(true)


func _process(delta: float) -> void:
	# Smoothly lerp camera orbit values
	var t := clampf(delta * 12.0, 0.0, 1.0)
	_curr_yaw = lerpf(_curr_yaw, yaw, t)
	_curr_pitch = lerpf(_curr_pitch, pitch, t)
	_curr_dist = lerpf(_curr_dist, distance, t)
	_curr_target = _curr_target.lerp(target_pos, t)
	_update_camera_transform(false)

	# Animate test dart flight
	if _dart_progress < 1.0 and _test_dart != null:
		_dart_progress = minf(_dart_progress + delta * 3.5, 1.0)
		_test_dart.global_position = _dart_start.lerp(_dart_end, _dart_progress)
		if _dart_progress >= 1.0:
			_on_dart_impact()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_visible_in_tree():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			_last_mouse_pos = mb.position
			if mb.double_click:
				reset_camera_view()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			reset_camera_view()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_orbit(-0.12)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_orbit(0.12)

	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		rotate_orbit(mm.relative)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		rotate_orbit(sd.relative)


## Loads a blaster by ID, equips saved attachments, and displays it on the turntable.
func load_blaster(weapon_id: StringName, attachments: Dictionary = {}) -> void:
	active_blaster_id = weapon_id
	var b_info: Dictionary = WeaponModding.find_workbench_blaster(weapon_id)
	var res_path: String = b_info.get("res_path", "res://resources/weapons/pocket_popper.tres")
	if ResourceLoader.exists(res_path):
		active_weapon_data = load(res_path) as WeaponData
	else:
		push_error("GarageWorkbench: could not load weapon data at %s" % res_path)
		return

	if attachments.is_empty() and is_instance_valid(Progression):
		attachments = Progression.get_equipped_attachments(weapon_id)

	# Clean up previous blaster model
	if active_blaster_model != null and is_instance_valid(active_blaster_model):
		active_blaster_model.queue_free()
		active_blaster_model = null

	var skin: StringName = GameSettings.player_skin
	active_blaster_model = BlasterModel.create(active_weapon_data, false, skin, attachments)
	# Turn weapon broadside to camera on turntable
	active_blaster_model.rotation_degrees = Vector3(0.0, -85.0, 0.0)
	turntable.add_child(active_blaster_model)


## Updates equipped attachments without reloading the entire blaster model.
func update_attachments(attachments: Dictionary) -> void:
	if active_blaster_model != null and is_instance_valid(active_blaster_model):
		active_blaster_model.update_attachments(attachments)


## Smoothly focuses camera on a specific attachment slot.
func focus_slot(slot: WeaponModding.Slot) -> void:
	var base_target := Vector3(0.0, 0.98, 0.0)
	match slot:
		WeaponModding.Slot.OPTIC:
			target_pos = base_target + Vector3(0.0, 0.09, 0.0)
			distance = 0.85
			pitch = 0.35
		WeaponModding.Slot.BARREL:
			target_pos = base_target + Vector3(0.24, 0.02, 0.0)
			distance = 0.85
			pitch = 0.28
		WeaponModding.Slot.SPRING:
			target_pos = base_target + Vector3(0.0, 0.02, 0.0)
			distance = 0.80
			pitch = 0.36
		WeaponModding.Slot.MAGAZINE:
			target_pos = base_target + Vector3(0.03, -0.09, 0.0)
			distance = 0.88
			pitch = 0.22
		WeaponModding.Slot.STOCK:
			target_pos = base_target + Vector3(-0.24, 0.0, 0.0)
			distance = 0.86
			pitch = 0.30
		_:
			target_pos = base_target
			distance = 1.35
			pitch = 0.38


## Launches a test foam dart from the blaster muzzle at the garage dartboard!
func test_fire() -> void:
	if active_blaster_model == null or active_weapon_data == null:
		return

	# Flash blaster muzzle
	active_blaster_model.flash()

	# Play weapon firing sound
	var snd: StringName = active_weapon_data.sound
	var vol_db: float = -3.0
	var atts := Progression.get_equipped_attachments(active_blaster_id) if is_instance_valid(Progression) else {}
	var mods := WeaponModding.compute_attachment_modifiers(atts)
	if mods.has("sound_override") and not str(mods["sound_override"]).is_empty():
		snd = StringName(str(mods["sound_override"]))
		vol_db = -8.0
	Sfx.play(snd, active_weapon_data.sound_pitch, vol_db, 0.05)

	# Clean up previous dart
	if _test_dart != null and is_instance_valid(_test_dart):
		_test_dart.queue_free()

	# Create visual foam dart projectile
	_test_dart = Node3D.new()
	_test_dart.name = "TestDart"
	add_child(_test_dart)

	ArenaKit.deco_cylinder(_test_dart, 0.014, 0.11, Vector3.ZERO, Color(0.2, 0.65, 1.0), Vector3(90.0, 0.0, 0.0))
	ArenaKit.deco_cylinder(_test_dart, 0.016, 0.024, Vector3(0.0, 0.0, -0.06), Color(1.0, 0.45, 0.05), Vector3(90.0, 0.0, 0.0))

	# Launch trajectory from muzzle to dartboard center
	var muzzle_pos := active_blaster_model.muzzle.global_position if (active_blaster_model.muzzle != null) else (active_blaster_model.global_position + Vector3(0.25, 0.05, 0.0))
	_dart_start = muzzle_pos
	_dart_end = dart_target.global_position + Vector3(randf_range(-0.06, 0.06), randf_range(-0.06, 0.06), 0.02)
	_test_dart.global_position = _dart_start
	_test_dart.look_at(_dart_end, Vector3.UP)
	_dart_progress = 0.0

	test_fired.emit()


func _on_dart_impact() -> void:
	Sfx.play(&"hit_confirm", 1.2, -4.0, 0.05)
	# Slight camera punch for feedback
	pitch += 0.02
	# Foam dart sticks in dartboard for 1.5 seconds then fades
	if _test_dart != null and is_instance_valid(_test_dart):
		var tw := create_tween()
		tw.tween_interval(1.5)
		tw.tween_property(_test_dart, "scale", Vector3.ZERO, 0.25)
		tw.tween_callback(func() -> void:
			if _test_dart != null and is_instance_valid(_test_dart):
				_test_dart.queue_free()
				_test_dart = null
		)
