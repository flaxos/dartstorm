@tool
extends SceneTree
## Generates all 7 production-ready AAA 3D blaster models:
## popper, six_shot, storm, sweeper, whisper, chainstorm, rocket
## Each blaster contains standard socket markers (MuzzleMarker, GripMarker, ForegripMarker),
## moving mechanical parts (Cylinder, PumpSlide, Spinner/BarrelCluster), and PBR material slots.

const BLASTER_DIR := "res://assets/models/blasters/"

const DARK := Color(0.13, 0.16, 0.24)
const ORANGE_SAFETY := Color(1.0, 0.45, 0.05)
const CHASSIS_BLUE := Color(0.18, 0.48, 0.95)
const GRIP_DARK := Color(0.10, 0.11, 0.16)

var mat_chassis: StandardMaterial3D
var mat_hardware: StandardMaterial3D
var mat_safety: StandardMaterial3D
var mat_grip: StandardMaterial3D


func _init() -> void:
	print("Generating AAA 3D blaster arsenal...")
	_setup_materials()

	_build_and_save("popper", _build_popper())
	_build_and_save("six_shot", _build_six_shot())
	_build_and_save("storm", _build_storm())
	_build_and_save("sweeper", _build_sweeper())
	_build_and_save("whisper", _build_whisper())
	_build_and_save("chainstorm", _build_chainstorm())
	_build_and_save("rocket", _build_rocket())

	print("Blaster arsenal generation complete!")
	quit(0)


func _setup_materials() -> void:
	mat_chassis = _create_mat(CHASSIS_BLUE, "chassis", 0.4, 0.0)
	mat_hardware = _create_mat(DARK, "hardware", 0.35, 0.7)
	mat_safety = _create_mat(ORANGE_SAFETY, "safety", 0.5, 0.0)
	mat_grip = _create_mat(GRIP_DARK, "grip", 0.85, 0.0)


func _create_mat(color: Color, slot_name: String, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = slot_name
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.roughness = roughness
	mat.metallic = metallic
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return mat


func _build_and_save(blaster_id: String, blaster_root: Node3D) -> void:
	var tscn_path := BLASTER_DIR + blaster_id + ".tscn"
	var glb_path := BLASTER_DIR + blaster_id + ".glb"

	# 1. Save .tscn
	_set_owner_recursive(blaster_root, blaster_root)
	var packed := PackedScene.new()
	var pack_err := packed.pack(blaster_root)
	if pack_err == OK:
		var save_err := ResourceSaver.save(packed, tscn_path)
		if save_err == OK:
			print("Saved %s to %s" % [blaster_id, tscn_path])
		else:
			printerr("Failed to save %s: %d" % [tscn_path, save_err])
	else:
		printerr("Failed to pack %s: %d" % [blaster_id, pack_err])

	# 2. Export .glb
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var append_err := doc.append_from_scene(blaster_root, state)
	if append_err == OK:
		var glb_err := doc.write_to_filesystem(state, glb_path)
		if glb_err == OK:
			print("Exported %s to %s" % [blaster_id, glb_path])
		else:
			print("GLTF write note (%s): %d" % [blaster_id, glb_err])

	blaster_root.free()


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)


# ==============================================================================
# 1. POPPER (Pocket Spring Pistol)
# ==============================================================================
func _build_popper() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_popper"

	# Lower Receiver Frame
	_box(blaster_root, "Mesh_Chassis_Frame", Vector3(0.07, 0.09, 0.24), Vector3(0.0, 0.0, -0.05), mat_chassis)

	# Moving Recoil Slide
	var slide := Node3D.new()
	slide.name = "Slide"
	slide.position = Vector3(0.0, 0.045, -0.05)
	blaster_root.add_child(slide)
	_box(slide, "Mesh_Chassis_Slide", Vector3(0.072, 0.038, 0.25), Vector3.ZERO, mat_chassis)
	_box(slide, "Mesh_Safety_SlideSerrations", Vector3(0.076, 0.02, 0.06), Vector3(0.0, 0.005, 0.08), mat_safety)

	# Barrel & Muzzle
	_cylinder(blaster_root, "Mesh_Chassis_Barrel", 0.016, 0.016, 0.14, Vector3(0.0, 0.02, -0.16), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Muzzle", 0.022, 0.022, 0.04, Vector3(0.0, 0.02, -0.22), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Grip & Trigger Assembly
	_box(blaster_root, "Mesh_Grip_Handle", Vector3(0.06, 0.14, 0.08), Vector3(0.0, -0.09, 0.04), mat_grip, Vector3(16.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Hardware_TriggerGuard", Vector3(0.025, 0.06, 0.08), Vector3(0.0, -0.04, -0.03), mat_hardware)
	_box(blaster_root, "Mesh_Hardware_Trigger", Vector3(0.015, 0.035, 0.02), Vector3(0.0, -0.04, -0.02), mat_hardware, Vector3(-10.0, 0.0, 0.0))

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.02, -0.25))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.08, 0.05))
	_marker(blaster_root, "EjectionMarker", Vector3(0.038, 0.05, -0.03))

	return blaster_root


# ==============================================================================
# 2. SIX-SHOT (Heavy Revolver)
# ==============================================================================
func _build_six_shot() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_six_shot"

	# Heavy Revolver Frame
	_box(blaster_root, "Mesh_Chassis_Frame", Vector3(0.07, 0.10, 0.28), Vector3(0.0, 0.0, -0.06), mat_chassis)
	_box(blaster_root, "Mesh_Chassis_TopShroud", Vector3(0.068, 0.035, 0.22), Vector3(0.0, 0.06, -0.12), mat_chassis)

	# Fluted Barrel & Blaze Tip
	_cylinder(blaster_root, "Mesh_Chassis_Barrel", 0.022, 0.025, 0.16, Vector3(0.0, 0.03, -0.20), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Muzzle", 0.028, 0.028, 0.04, Vector3(0.0, 0.03, -0.28), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Revolving 6-Dart Cylinder
	var cyl := Node3D.new()
	cyl.name = "Cylinder"
	cyl.position = Vector3(0.0, 0.01, -0.06)
	blaster_root.add_child(cyl)
	_cylinder(cyl, "Mesh_Hardware_Drum", 0.048, 0.048, 0.10, Vector3.ZERO, mat_hardware, Vector3(90.0, 0.0, 0.0))
	for i in 6:
		var angle := float(i) * TAU / 6.0
		var chamber_pos := Vector3(sin(angle) * 0.032, cos(angle) * 0.032, -0.01)
		_cylinder(cyl, "Mesh_Safety_Chamber_%d" % i, 0.012, 0.012, 0.08, chamber_pos, mat_safety, Vector3(90.0, 0.0, 0.0))

	# Hammer & Grip
	_box(blaster_root, "Mesh_Hardware_Hammer", Vector3(0.018, 0.04, 0.03), Vector3(0.0, 0.065, 0.06), mat_hardware, Vector3(-20.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Grip_Handle", Vector3(0.065, 0.15, 0.09), Vector3(0.0, -0.10, 0.06), mat_grip, Vector3(20.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Hardware_TriggerGuard", Vector3(0.025, 0.065, 0.09), Vector3(0.0, -0.05, -0.02), mat_hardware)

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.03, -0.31))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.09, 0.07))

	return blaster_root


# ==============================================================================
# 3. STORM (Tactical Bullpup Assault Carbine)
# ==============================================================================
func _build_storm() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_storm"

	# Lower and Upper Receivers
	_box(blaster_root, "Mesh_Chassis_Receiver", Vector3(0.08, 0.12, 0.36), Vector3(0.0, 0.0, -0.08), mat_chassis)
	_box(blaster_root, "Mesh_Chassis_Upper", Vector3(0.075, 0.06, 0.38), Vector3(0.0, 0.08, -0.07), mat_chassis)
	_box(blaster_root, "Mesh_Hardware_Rail", Vector3(0.04, 0.02, 0.32), Vector3(0.0, 0.12, -0.07), mat_hardware)

	# Removable Curved Magazine
	var mag := Node3D.new()
	mag.name = "Magazine"
	mag.position = Vector3(0.0, -0.12, -0.05)
	blaster_root.add_child(mag)
	_box(mag, "Mesh_Chassis_MagBody", Vector3(0.05, 0.16, 0.08), Vector3.ZERO, mat_chassis, Vector3(12.0, 0.0, 0.0))
	_box(mag, "Mesh_Safety_MagBase", Vector3(0.056, 0.025, 0.09), Vector3(0.0, -0.08, -0.015), mat_safety, Vector3(12.0, 0.0, 0.0))

	# Barrel Shroud & Flash Hider
	_cylinder(blaster_root, "Mesh_Chassis_Shroud", 0.03, 0.032, 0.18, Vector3(0.0, 0.03, -0.32), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Muzzle", 0.034, 0.034, 0.05, Vector3(0.0, 0.03, -0.42), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Stock & Grips
	_cylinder(blaster_root, "Mesh_Hardware_Stock", 0.02, 0.02, 0.14, Vector3(0.0, 0.04, 0.16), mat_hardware, Vector3(90.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Grip_Buttpad", Vector3(0.065, 0.12, 0.03), Vector3(0.0, 0.02, 0.23), mat_grip)
	_box(blaster_root, "Mesh_Grip_Rear", Vector3(0.06, 0.15, 0.08), Vector3(0.0, -0.10, 0.07), mat_grip, Vector3(18.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Grip_Fore", 0.02, 0.022, 0.10, Vector3(0.0, -0.07, -0.22), mat_grip)

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.03, -0.45))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.09, 0.08))
	_marker(blaster_root, "ForegripMarker", Vector3(0.0, -0.07, -0.22))
	_marker(blaster_root, "EjectionMarker", Vector3(0.045, 0.07, -0.02))

	return blaster_root


# ==============================================================================
# 4. SWEEPER (Double-Barrel Pump Shotgun)
# ==============================================================================
func _build_sweeper() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_sweeper"

	# Shotgun Receiver
	_box(blaster_root, "Mesh_Chassis_Receiver", Vector3(0.11, 0.11, 0.32), Vector3(0.0, 0.01, -0.04), mat_chassis)

	# Twin Horizontal Barrels & Blaze Muzzles
	_cylinder(blaster_root, "Mesh_Chassis_Barrel_L", 0.022, 0.022, 0.32, Vector3(-0.032, 0.03, -0.26), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Chassis_Barrel_R", 0.022, 0.022, 0.32, Vector3(0.032, 0.03, -0.26), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Muzzle_L", 0.026, 0.026, 0.04, Vector3(-0.032, 0.03, -0.43), mat_safety, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Muzzle_R", 0.026, 0.026, 0.04, Vector3(0.032, 0.03, -0.43), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Lower Tube & Movable Pump Slide
	_cylinder(blaster_root, "Mesh_Hardware_MagTube", 0.022, 0.022, 0.28, Vector3(0.0, -0.025, -0.22), mat_hardware, Vector3(90.0, 0.0, 0.0))
	var pump := Node3D.new()
	pump.name = "PumpSlide"
	pump.position = Vector3(0.0, -0.025, -0.20)
	blaster_root.add_child(pump)
	_box(pump, "Mesh_Grip_PumpSlide", Vector3(0.09, 0.065, 0.14), Vector3.ZERO, mat_grip)
	_box(pump, "Mesh_Safety_PumpRib", Vector3(0.094, 0.068, 0.03), Vector3.ZERO, mat_safety)

	# Rear Grip
	_box(blaster_root, "Mesh_Grip_Handle", Vector3(0.065, 0.15, 0.09), Vector3(0.0, -0.10, 0.10), mat_grip, Vector3(22.0, 0.0, 0.0))

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.03, -0.46))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.09, 0.11))
	_marker(blaster_root, "ForegripMarker", Vector3(0.0, -0.025, -0.20))

	return blaster_root


# ==============================================================================
# 5. WHISPER (Suppressed Precision Marksman Rifle)
# ==============================================================================
func _build_whisper() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_whisper"

	# Match Receiver & Rail
	_box(blaster_root, "Mesh_Chassis_Receiver", Vector3(0.075, 0.09, 0.38), Vector3(0.0, 0.02, -0.06), mat_chassis)
	_box(blaster_root, "Mesh_Hardware_Rail", Vector3(0.04, 0.025, 0.26), Vector3(0.0, 0.08, -0.06), mat_hardware)

	# Elevated Scope Optic
	var scope := Node3D.new()
	scope.name = "Scope"
	scope.position = Vector3(0.0, 0.13, -0.06)
	blaster_root.add_child(scope)
	_cylinder(scope, "Mesh_Hardware_ScopeTube", 0.022, 0.022, 0.20, Vector3.ZERO, mat_hardware, Vector3(90.0, 0.0, 0.0))
	_cylinder(scope, "Mesh_Safety_ScopeBell", 0.032, 0.024, 0.05, Vector3(0.0, 0.0, -0.11), mat_safety, Vector3(90.0, 0.0, 0.0))
	_cylinder(scope, "Mesh_Hardware_ScopeOcular", 0.028, 0.022, 0.04, Vector3(0.0, 0.0, 0.11), mat_hardware, Vector3(90.0, 0.0, 0.0))
	_cylinder(scope, "Mesh_Hardware_Turret", 0.012, 0.012, 0.04, Vector3(0.0, 0.025, 0.0), mat_hardware)

	# Match Barrel & Tactical Suppressor
	var supp := Node3D.new()
	supp.name = "Suppressor"
	supp.position = Vector3(0.0, 0.025, -0.38)
	blaster_root.add_child(supp)
	_cylinder(supp, "Mesh_Hardware_Barrel", 0.018, 0.02, 0.20, Vector3.ZERO, mat_hardware, Vector3(90.0, 0.0, 0.0))
	_cylinder(supp, "Mesh_Chassis_Suppressor", 0.032, 0.032, 0.22, Vector3(0.0, 0.0, -0.16), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(supp, "Mesh_Safety_Muzzle", 0.034, 0.034, 0.03, Vector3(0.0, 0.0, -0.28), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Skeletonized Stock & Grips
	_cylinder(blaster_root, "Mesh_Hardware_Strut_Top", 0.012, 0.012, 0.20, Vector3(0.0, 0.04, 0.21), mat_hardware, Vector3(90.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Grip_Buttpad", Vector3(0.06, 0.14, 0.025), Vector3(0.0, 0.01, 0.31), mat_grip)
	_box(blaster_root, "Mesh_Grip_Precision", Vector3(0.055, 0.14, 0.075), Vector3(0.0, -0.09, 0.10), mat_grip, Vector3(15.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Grip_Handguard", Vector3(0.065, 0.055, 0.18), Vector3(0.0, -0.02, -0.22), mat_grip)

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.025, -0.68))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.08, 0.10))
	_marker(blaster_root, "ForegripMarker", Vector3(0.0, -0.03, -0.22))

	return blaster_root


# ==============================================================================
# 6. CHAINSTORM (Motorized 6-Barrel Rotary Minigun)
# ==============================================================================
func _build_chainstorm() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_chainstorm"

	# Motor Housing & Carry Handle
	_box(blaster_root, "Mesh_Chassis_Housing", Vector3(0.17, 0.18, 0.28), Vector3(0.0, 0.0, 0.02), mat_chassis)
	_box(blaster_root, "Mesh_Hardware_Bridge", Vector3(0.05, 0.03, 0.26), Vector3(0.0, 0.14, -0.04), mat_hardware)
	_cylinder(blaster_root, "Mesh_Hardware_Post_F", 0.015, 0.015, 0.08, Vector3(0.0, 0.10, -0.14), mat_hardware)
	_cylinder(blaster_root, "Mesh_Hardware_Post_R", 0.015, 0.015, 0.08, Vector3(0.0, 0.10, 0.06), mat_hardware)

	# 6-Barrel Spinning Cluster (named Spinner so BlasterModel hooks it automatically)
	var spinner := Node3D.new()
	spinner.name = "Spinner"
	spinner.position = Vector3(0.0, 0.0, -0.12)
	blaster_root.add_child(spinner)
	_cylinder(spinner, "Mesh_Hardware_Spindle", 0.035, 0.035, 0.38, Vector3(0.0, 0.0, -0.16), mat_hardware, Vector3(90.0, 0.0, 0.0))
	_cylinder(spinner, "Mesh_Safety_Collar_F", 0.088, 0.088, 0.025, Vector3(0.0, 0.0, -0.32), mat_safety, Vector3(90.0, 0.0, 0.0))
	_cylinder(spinner, "Mesh_Hardware_Collar_M", 0.088, 0.088, 0.025, Vector3(0.0, 0.0, -0.15), mat_hardware, Vector3(90.0, 0.0, 0.0))

	var cluster_radius := 0.065
	for i in 6:
		var angle := float(i) * TAU / 6.0
		var bx := sin(angle) * cluster_radius
		var by := cos(angle) * cluster_radius
		_cylinder(spinner, "Mesh_Chassis_Barrel_%d" % i, 0.016, 0.016, 0.36, Vector3(bx, by, -0.18), mat_chassis, Vector3(90.0, 0.0, 0.0))
		_cylinder(spinner, "Mesh_Safety_Tip_%d" % i, 0.018, 0.018, 0.04, Vector3(bx, by, -0.37), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Rear Spade Grip & Ammo Chute
	_box(blaster_root, "Mesh_Grip_Rear", Vector3(0.16, 0.14, 0.06), Vector3(0.0, 0.0, 0.18), mat_grip)
	_box(blaster_root, "Mesh_Hardware_Chute", Vector3(0.06, 0.08, 0.12), Vector3(0.11, 0.0, -0.02), mat_hardware)

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.0, -0.52))
	_marker(blaster_root, "GripMarker", Vector3(0.0, 0.0, 0.18))
	_marker(blaster_root, "ForegripMarker", Vector3(0.0, 0.14, -0.04))

	return blaster_root


# ==============================================================================
# 7. ROCKET (Heavy Ordnance Foam Launcher)
# ==============================================================================
func _build_rocket() -> Node3D:
	var blaster_root := Node3D.new()
	blaster_root.name = "Blaster_rocket"

	# Main Launch Tube & Warning Bell
	_cylinder(blaster_root, "Mesh_Chassis_Tube", 0.075, 0.075, 0.68, Vector3(0.0, 0.0, -0.08), mat_chassis, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Safety_Bell", 0.095, 0.078, 0.08, Vector3(0.0, 0.0, -0.44), mat_safety, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Hardware_Exhaust", 0.078, 0.095, 0.08, Vector3(0.0, 0.0, 0.28), mat_hardware, Vector3(90.0, 0.0, 0.0))

	# Circumferential Reinforcing Rings
	_cylinder(blaster_root, "Mesh_Hardware_Ring_F", 0.082, 0.082, 0.03, Vector3(0.0, 0.0, -0.26), mat_hardware, Vector3(90.0, 0.0, 0.0))
	_cylinder(blaster_root, "Mesh_Hardware_Ring_R", 0.082, 0.082, 0.03, Vector3(0.0, 0.0, 0.12), mat_hardware, Vector3(90.0, 0.0, 0.0))

	# Padded Shoulder Rest & Grips
	_box(blaster_root, "Mesh_Grip_ShoulderRest", Vector3(0.14, 0.05, 0.22), Vector3(0.0, 0.09, 0.06), mat_grip)
	_box(blaster_root, "Mesh_Grip_Front", Vector3(0.06, 0.14, 0.08), Vector3(0.0, -0.13, -0.18), mat_grip, Vector3(10.0, 0.0, 0.0))
	_box(blaster_root, "Mesh_Grip_Rear", Vector3(0.06, 0.13, 0.08), Vector3(0.0, -0.13, 0.16), mat_grip, Vector3(10.0, 0.0, 0.0))

	# Flip-up Sight
	var sight := Node3D.new()
	sight.name = "Sight"
	sight.position = Vector3(-0.08, 0.10, -0.16)
	blaster_root.add_child(sight)
	_box(sight, "Mesh_Hardware_SightPost", Vector3(0.02, 0.08, 0.02), Vector3.ZERO, mat_hardware)
	_cylinder(sight, "Mesh_Safety_SightAperture", 0.03, 0.03, 0.015, Vector3(0.0, 0.04, 0.0), mat_safety, Vector3(90.0, 0.0, 0.0))

	# Sockets & Markers
	_marker(blaster_root, "MuzzleMarker", Vector3(0.0, 0.0, -0.50))
	_marker(blaster_root, "GripMarker", Vector3(0.0, -0.12, -0.18))
	_marker(blaster_root, "ForegripMarker", Vector3(0.0, -0.12, 0.16))

	return blaster_root


# ==============================================================================
# MESH GENERATION HELPERS
# ==============================================================================
func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _cylinder(parent: Node, name: String, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = height
	m.radial_segments = 24
	m.rings = 2
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _marker(parent: Node, name: String, pos: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = name
	marker.position = pos
	parent.add_child(marker)
	return marker
