@tool
extends SceneTree
## Generates the production-ready stylized hero character base asset
## (hero_base.tscn and hero_base.glb) with a 16-bone humanoid Skeleton3D,
## BoneAttachment3D sockets, PBR material slots, and keyframed animations.

const SKIN := Color(1.0, 0.82, 0.66)
const NAVY := Color(0.1, 0.14, 0.3)
const SHIRT := Color(0.15, 0.5, 0.95)
const DARK := Color(0.12, 0.14, 0.22)
const WHITE := Color(0.96, 0.96, 0.98)

const OUTPUT_TSCN := "res://assets/models/characters/hero_base.tscn"
const OUTPUT_GLB := "res://assets/models/characters/hero_base.glb"


func _init() -> void:
	print("Generating stylized hero character asset...")
	var hero := _build_hero_rig()
	
	# Pack and save as .tscn
	_set_owner_recursive(hero, hero)
	var packed := PackedScene.new()
	var pack_err := packed.pack(hero)
	if pack_err != OK:
		printerr("Failed to pack hero scene: ", pack_err)
		quit(1)
		return
		
	var save_err := ResourceSaver.save(packed, OUTPUT_TSCN)
	if save_err != OK:
		printerr("Failed to save hero scene to ", OUTPUT_TSCN, ": ", save_err)
		quit(1)
		return
	print("Saved .tscn to ", OUTPUT_TSCN)
	
	# Export as .glb
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var append_err := doc.append_from_scene(hero, state)
	if append_err == OK:
		var glb_err := doc.write_to_filesystem(state, OUTPUT_GLB)
		if glb_err == OK:
			print("Exported .glb to ", OUTPUT_GLB)
		else:
			print("GLTF write notice: ", glb_err)
	else:
		print("GLTF append notice: ", append_err)
		
	print("Hero generation complete!")
	hero.free()
	quit(0)


func _build_hero_rig() -> Node3D:
	var hero_root := Node3D.new()
	hero_root.name = "HeroBase"

	var skel := Skeleton3D.new()
	skel.name = "GeneralSkeleton"
	hero_root.add_child(skel)

	# --- 16-Bone Humanoid Hierarchy ---
	var b_root := skel.add_bone("Root")
	skel.set_bone_rest(b_root, Transform3D.IDENTITY)

	var b_hips := skel.add_bone("Hips")
	skel.set_bone_parent(b_hips, b_root)
	skel.set_bone_rest(b_hips, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.74, 0.0)))

	var b_spine := skel.add_bone("Spine")
	skel.set_bone_parent(b_spine, b_hips)
	skel.set_bone_rest(b_spine, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.21, 0.0)))

	var b_chest := skel.add_bone("Chest")
	skel.set_bone_parent(b_chest, b_spine)
	skel.set_bone_rest(b_chest, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.30, 0.0)))

	var b_neck := skel.add_bone("Neck")
	skel.set_bone_parent(b_neck, b_chest)
	skel.set_bone_rest(b_neck, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.23, 0.0)))

	var b_head := skel.add_bone("Head")
	skel.set_bone_parent(b_head, b_neck)
	skel.set_bone_rest(b_head, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.18, 0.0)))

	# Left Arm
	var b_sh_l := skel.add_bone("Shoulder_L")
	skel.set_bone_parent(b_sh_l, b_chest)
	skel.set_bone_rest(b_sh_l, Transform3D(Basis.IDENTITY, Vector3(-0.16, 0.10, 0.0)))

	var b_ua_l := skel.add_bone("UpperArm_L")
	skel.set_bone_parent(b_ua_l, b_sh_l)
	skel.set_bone_rest(b_ua_l, Transform3D(Basis.IDENTITY, Vector3(-0.14, -0.05, 0.0)))

	var b_la_l := skel.add_bone("LowerArm_L")
	skel.set_bone_parent(b_la_l, b_ua_l)
	skel.set_bone_rest(b_la_l, Transform3D(Basis.IDENTITY, Vector3(-0.02, -0.26, -0.12)))

	var b_ha_l := skel.add_bone("Hand_L")
	skel.set_bone_parent(b_ha_l, b_la_l)
	skel.set_bone_rest(b_ha_l, Transform3D(Basis.IDENTITY, Vector3(0.06, -0.18, -0.14)))

	# Right Arm
	var b_sh_r := skel.add_bone("Shoulder_R")
	skel.set_bone_parent(b_sh_r, b_chest)
	skel.set_bone_rest(b_sh_r, Transform3D(Basis.IDENTITY, Vector3(0.16, 0.10, 0.0)))

	var b_ua_r := skel.add_bone("UpperArm_R")
	skel.set_bone_parent(b_ua_r, b_sh_r)
	skel.set_bone_rest(b_ua_r, Transform3D(Basis.IDENTITY, Vector3(0.14, -0.05, 0.0)))

	var b_la_r := skel.add_bone("LowerArm_R")
	skel.set_bone_parent(b_la_r, b_ua_r)
	skel.set_bone_rest(b_la_r, Transform3D(Basis.IDENTITY, Vector3(0.02, -0.26, -0.12)))

	var b_ha_r := skel.add_bone("Hand_R")
	skel.set_bone_parent(b_ha_r, b_la_r)
	skel.set_bone_rest(b_ha_r, Transform3D(Basis.IDENTITY, Vector3(-0.06, -0.18, -0.14)))

	# Left Leg
	var b_ul_l := skel.add_bone("UpperLeg_L")
	skel.set_bone_parent(b_ul_l, b_hips)
	skel.set_bone_rest(b_ul_l, Transform3D(Basis.IDENTITY, Vector3(-0.15, -0.10, 0.0)))

	var b_ll_l := skel.add_bone("LowerLeg_L")
	skel.set_bone_parent(b_ll_l, b_ul_l)
	skel.set_bone_rest(b_ll_l, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.32, 0.0)))

	var b_ft_l := skel.add_bone("Foot_L")
	skel.set_bone_parent(b_ft_l, b_ll_l)
	skel.set_bone_rest(b_ft_l, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.26, -0.04)))

	# Right Leg
	var b_ul_r := skel.add_bone("UpperLeg_R")
	skel.set_bone_parent(b_ul_r, b_hips)
	skel.set_bone_rest(b_ul_r, Transform3D(Basis.IDENTITY, Vector3(0.15, -0.10, 0.0)))

	var b_ll_r := skel.add_bone("LowerLeg_R")
	skel.set_bone_parent(b_ll_r, b_ul_r)
	skel.set_bone_rest(b_ll_r, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.32, 0.0)))

	var b_ft_r := skel.add_bone("Foot_R")
	skel.set_bone_parent(b_ft_r, b_ll_r)
	skel.set_bone_rest(b_ft_r, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.26, -0.04)))

	# --- Sockets (BoneAttachment3D) ---
	_bone_attachment(skel, "Socket_Hand_R", "Hand_R")
	_bone_attachment(skel, "Socket_Hand_L", "Hand_L")
	_bone_attachment(skel, "Socket_Head", "Head", Vector3(0.0, 0.18, 0.0))
	_bone_attachment(skel, "Socket_Back", "Chest", Vector3(0.0, 0.0, 0.16))

	# --- Attachment Nodes for Meshes ---
	var attach_head := _bone_attachment(skel, "Attach_Head", "Head")
	var attach_chest := _bone_attachment(skel, "Attach_Chest", "Chest")
	var attach_hips := _bone_attachment(skel, "Attach_Hips", "Hips")
	var attach_ua_l := _bone_attachment(skel, "Attach_UpperArm_L", "UpperArm_L")
	var attach_ua_r := _bone_attachment(skel, "Attach_UpperArm_R", "UpperArm_R")
	var attach_ul_l := _bone_attachment(skel, "Attach_UpperLeg_L", "UpperLeg_L")
	var attach_ul_r := _bone_attachment(skel, "Attach_UpperLeg_R", "UpperLeg_R")

	# --- Materials Setup ---
	var mat_clothing := _make_mat(SHIRT, "clothing")
	var mat_pants := _make_mat(NAVY, "pants")
	var mat_skin := _make_mat(SKIN, "skin")
	var mat_shoes := _make_mat(WHITE, "shoes")
	var mat_dark := _make_mat(DARK, "hardware")

	# --- Meshes Construction ---

	# 1. Head & Facial Features (Attached to Attach_Head)
	_sphere(attach_head, "Mesh_Head_Skin", 0.26, Vector3.ZERO, mat_skin)
	_tube(attach_head, "Mesh_Cowl_Collar_Clothing", 0.24, 0.07, Vector3(0.0, -0.16, 0.0), mat_clothing)
	_sphere(attach_head, "Mesh_Nose_Skin", 0.034, Vector3(0.0, -0.03, -0.255), mat_skin)

	# Eyes & Pixar Catchlights
	for side: float in [-1.0, 1.0]:
		_box(attach_head, "Mesh_Brow_" + ("L" if side < 0 else "R"), Vector3(0.075, 0.022, 0.025), Vector3(side * 0.095, 0.12, -0.235), mat_dark, Vector3(0.0, 0.0, side * -12.0))
		_sphere(attach_head, "Mesh_Sclera_" + ("L" if side < 0 else "R"), 0.065, Vector3(side * 0.095, 0.04, -0.215), mat_shoes)
		_sphere(attach_head, "Mesh_Iris_" + ("L" if side < 0 else "R"), 0.038, Vector3(side * 0.095, 0.04, -0.265), _make_mat(Color(0.1, 0.3, 0.65), "iris"))
		_sphere(attach_head, "Mesh_Pupil_" + ("L" if side < 0 else "R"), 0.024, Vector3(side * 0.095, 0.04, -0.275), mat_dark)
		_sphere(attach_head, "Mesh_Catchlight_" + ("L" if side < 0 else "R"), 0.012, Vector3(side * 0.095 + 0.016, 0.058, -0.285), mat_shoes)
		_sphere(attach_head, "Mesh_Cheek_" + ("L" if side < 0 else "R"), 0.035, Vector3(side * 0.155, -0.055, -0.205), _make_mat(Color(1.0, 0.62, 0.62, 1.0), "skin"))

	# 2. Chest & Torso (Attached to Attach_Chest)
	_capsule(attach_chest, "Mesh_Torso_Clothing", 0.29, 0.54, Vector3(0.0, -0.10, 0.0), mat_clothing)
	_box(attach_chest, "Mesh_Zipper_Hardware", Vector3(0.018, 0.44, 0.03), Vector3(0.0, -0.10, -0.28), mat_dark)
	_box(attach_chest, "Mesh_Pocket_Clothing", Vector3(0.10, 0.12, 0.035), Vector3(0.12, -0.05, -0.27), mat_clothing)

	# 3. Hips / Waist (Attached to Attach_Hips)
	_capsule(attach_hips, "Mesh_Hips_Pants", 0.27, 0.24, Vector3.ZERO, mat_pants)

	# 4. Left Arm & Hand
	var arm_l := _capsule(attach_ua_l, "Mesh_UpperArm_L_Clothing", 0.082, 0.44, Vector3(0.0, -0.16, 0.0), mat_clothing)
	_tube(arm_l, "Mesh_Cuff_L_Clothing", 0.088, 0.04, Vector3(0.0, -0.20, 0.0), mat_clothing)
	_sphere(arm_l, "Mesh_Hand_L_Skin", 0.074, Vector3(0.0, -0.27, 0.0), mat_skin)

	# 5. Right Arm & Molded Trigger Hand
	var arm_r := _capsule(attach_ua_r, "Mesh_UpperArm_R_Clothing", 0.082, 0.44, Vector3(0.0, -0.16, 0.0), mat_clothing)
	_tube(arm_r, "Mesh_Cuff_R_Clothing", 0.088, 0.04, Vector3(0.0, -0.20, 0.0), mat_clothing)
	_sphere(arm_r, "Mesh_Hand_R_Skin", 0.074, Vector3(0.0, -0.27, 0.0), mat_skin)

	# 6. Left Leg & High-Traction Sneaker
	var leg_l := _capsule(attach_ul_l, "Mesh_UpperLeg_L_Pants", 0.11, 0.62, Vector3(0.0, -0.26, 0.0), mat_pants)
	_box(leg_l, "Mesh_Sneaker_Sole_L_Shoes", Vector3(0.155, 0.055, 0.28), Vector3(0.0, -0.58, -0.04), mat_shoes)
	_box(leg_l, "Mesh_Sneaker_Upper_L_Shoes", Vector3(0.14, 0.08, 0.22), Vector3(0.0, -0.52, -0.03), mat_clothing)
	_box(leg_l, "Mesh_Sneaker_Toe_L_Shoes", Vector3(0.145, 0.065, 0.09), Vector3(0.0, -0.56, -0.15), mat_shoes)

	# 7. Right Leg & High-Traction Sneaker
	var leg_r := _capsule(attach_ul_r, "Mesh_UpperLeg_R_Pants", 0.11, 0.62, Vector3(0.0, -0.26, 0.0), mat_pants)
	_box(leg_r, "Mesh_Sneaker_Sole_R_Shoes", Vector3(0.155, 0.055, 0.28), Vector3(0.0, -0.58, -0.04), mat_shoes)
	_box(leg_r, "Mesh_Sneaker_Upper_R_Shoes", Vector3(0.14, 0.08, 0.22), Vector3(0.0, -0.52, -0.03), mat_clothing)
	_box(leg_r, "Mesh_Sneaker_Toe_R_Shoes", Vector3(0.145, 0.065, 0.09), Vector3(0.0, -0.56, -0.15), mat_shoes)

	# --- AnimationPlayer & Keyframed Clips ---
	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	hero_root.add_child(anim_player)

	var lib := AnimationLibrary.new()
	lib.add_animation("idle", _build_anim_idle())
	lib.add_animation("run", _build_anim_run())
	lib.add_animation("strafe_left", _build_anim_strafe(-1.0))
	lib.add_animation("strafe_right", _build_anim_strafe(1.0))
	lib.add_animation("jump", _build_anim_jump())
	lib.add_animation("flinch", _build_anim_flinch())
	lib.add_animation("victory", _build_anim_victory())
	anim_player.add_animation_library("", lib)

	skel.reset_bone_poses()
	for i in skel.get_bone_count():
		skel.force_update_bone_child_transform(i)

	return hero_root


func _bone_attachment(skel: Skeleton3D, node_name: String, bone_name: String, offset: Vector3 = Vector3.ZERO) -> BoneAttachment3D:
	var attach := BoneAttachment3D.new()
	attach.name = node_name
	attach.bone_name = bone_name
	var b_idx := skel.find_bone(bone_name)
	if b_idx >= 0:
		attach.bone_idx = b_idx
		var rest_t := skel.get_bone_global_rest(b_idx)
		attach.transform = Transform3D(rest_t.basis, rest_t.origin + offset)
	else:
		attach.position = offset
	skel.add_child(attach)
	return attach


func _make_mat(color: Color, slot_name: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = slot_name
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.5
	return mat


func _sphere(parent: Node, name: String, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 24
	m.rings = 14
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _capsule(parent: Node, name: String, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 24
	m.rings = 6
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _tube(parent: Node, name: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 24
	m.rings = 2
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


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


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)


# --- Animations ---

func _build_anim_idle() -> Animation:
	var anim := Animation.new()
	anim.length = 1.6
	anim.loop_mode = Animation.LOOP_LINEAR

	var t_chest := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_chest, "GeneralSkeleton:Chest")
	anim.rotation_track_insert_key(t_chest, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_chest, 0.8, Quaternion(Vector3.RIGHT, deg_to_rad(2.0)))
	anim.rotation_track_insert_key(t_chest, 1.6, Quaternion.IDENTITY)

	var t_head := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_head, "GeneralSkeleton:Head")
	anim.rotation_track_insert_key(t_head, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_head, 0.8, Quaternion(Vector3.RIGHT, deg_to_rad(-1.5)))
	anim.rotation_track_insert_key(t_head, 1.6, Quaternion.IDENTITY)

	var t_ua_l := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_ua_l, "GeneralSkeleton:UpperArm_L")
	anim.rotation_track_insert_key(t_ua_l, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_ua_l, 0.8, Quaternion(Vector3.RIGHT, deg_to_rad(3.0)))
	anim.rotation_track_insert_key(t_ua_l, 1.6, Quaternion.IDENTITY)

	return anim


func _build_anim_run() -> Animation:
	var anim := Animation.new()
	anim.length = 0.65
	anim.loop_mode = Animation.LOOP_LINEAR

	var t_chest := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_chest, "GeneralSkeleton:Chest")
	anim.rotation_track_insert_key(t_chest, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(12.0)))
	anim.rotation_track_insert_key(t_chest, 0.325, Quaternion(Vector3.RIGHT, deg_to_rad(10.0)))
	anim.rotation_track_insert_key(t_chest, 0.65, Quaternion(Vector3.RIGHT, deg_to_rad(12.0)))

	var t_leg_l := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_leg_l, "GeneralSkeleton:UpperLeg_L")
	anim.rotation_track_insert_key(t_leg_l, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
	anim.rotation_track_insert_key(t_leg_l, 0.325, Quaternion(Vector3.RIGHT, deg_to_rad(-28.0)))
	anim.rotation_track_insert_key(t_leg_l, 0.65, Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))

	var t_leg_r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_leg_r, "GeneralSkeleton:UpperLeg_R")
	anim.rotation_track_insert_key(t_leg_r, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(-28.0)))
	anim.rotation_track_insert_key(t_leg_r, 0.325, Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
	anim.rotation_track_insert_key(t_leg_r, 0.65, Quaternion(Vector3.RIGHT, deg_to_rad(-28.0)))

	var t_arm_l := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_arm_l, "GeneralSkeleton:UpperArm_L")
	anim.rotation_track_insert_key(t_arm_l, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(-22.0)))
	anim.rotation_track_insert_key(t_arm_l, 0.325, Quaternion(Vector3.RIGHT, deg_to_rad(22.0)))
	anim.rotation_track_insert_key(t_arm_l, 0.65, Quaternion(Vector3.RIGHT, deg_to_rad(-22.0)))

	return anim


func _build_anim_strafe(direction: float) -> Animation:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_LINEAR

	var t_chest := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_chest, "GeneralSkeleton:Chest")
	anim.rotation_track_insert_key(t_chest, 0.0, Quaternion(Vector3.FORWARD, deg_to_rad(direction * 4.0)))
	anim.rotation_track_insert_key(t_chest, 0.3, Quaternion(Vector3.FORWARD, deg_to_rad(direction * 6.0)))
	anim.rotation_track_insert_key(t_chest, 0.6, Quaternion(Vector3.FORWARD, deg_to_rad(direction * 4.0)))

	var t_leg_l := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_leg_l, "GeneralSkeleton:UpperLeg_L")
	anim.rotation_track_insert_key(t_leg_l, 0.0, Quaternion(Vector3.FORWARD, deg_to_rad(direction * 8.0)))
	anim.rotation_track_insert_key(t_leg_l, 0.3, Quaternion(Vector3.FORWARD, deg_to_rad(direction * -4.0)))
	anim.rotation_track_insert_key(t_leg_l, 0.6, Quaternion(Vector3.FORWARD, deg_to_rad(direction * 8.0)))

	return anim


func _build_anim_jump() -> Animation:
	var anim := Animation.new()
	anim.length = 0.8
	anim.loop_mode = Animation.LOOP_NONE

	var t_chest := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_chest, "GeneralSkeleton:Chest")
	anim.rotation_track_insert_key(t_chest, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_chest, 0.35, Quaternion(Vector3.RIGHT, deg_to_rad(15.0)))
	anim.rotation_track_insert_key(t_chest, 0.8, Quaternion.IDENTITY)

	var t_leg_l := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_leg_l, "GeneralSkeleton:UpperLeg_L")
	anim.rotation_track_insert_key(t_leg_l, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_leg_l, 0.35, Quaternion(Vector3.RIGHT, deg_to_rad(30.0)))
	anim.rotation_track_insert_key(t_leg_l, 0.8, Quaternion.IDENTITY)

	var t_leg_r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_leg_r, "GeneralSkeleton:UpperLeg_R")
	anim.rotation_track_insert_key(t_leg_r, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_leg_r, 0.35, Quaternion(Vector3.RIGHT, deg_to_rad(30.0)))
	anim.rotation_track_insert_key(t_leg_r, 0.8, Quaternion.IDENTITY)

	return anim


func _build_anim_flinch() -> Animation:
	var anim := Animation.new()
	anim.length = 0.35
	anim.loop_mode = Animation.LOOP_NONE

	var t_chest := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_chest, "GeneralSkeleton:Chest")
	anim.rotation_track_insert_key(t_chest, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_chest, 0.08, Quaternion(Vector3.RIGHT, deg_to_rad(-18.0)))
	anim.rotation_track_insert_key(t_chest, 0.35, Quaternion.IDENTITY)

	var t_head := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_head, "GeneralSkeleton:Head")
	anim.rotation_track_insert_key(t_head, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(t_head, 0.08, Quaternion(Vector3.RIGHT, deg_to_rad(-12.0)))
	anim.rotation_track_insert_key(t_head, 0.35, Quaternion.IDENTITY)

	return anim


func _build_anim_victory() -> Animation:
	var anim := Animation.new()
	anim.length = 1.5
	anim.loop_mode = Animation.LOOP_LINEAR

	var t_arm_r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_arm_r, "GeneralSkeleton:UpperArm_R")
	anim.rotation_track_insert_key(t_arm_r, 0.0, Quaternion(Vector3.FORWARD, deg_to_rad(-120.0)))
	anim.rotation_track_insert_key(t_arm_r, 0.75, Quaternion(Vector3.FORWARD, deg_to_rad(-135.0)))
	anim.rotation_track_insert_key(t_arm_r, 1.5, Quaternion(Vector3.FORWARD, deg_to_rad(-120.0)))

	var t_head := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t_head, "GeneralSkeleton:Head")
	anim.rotation_track_insert_key(t_head, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(-5.0)))
	anim.rotation_track_insert_key(t_head, 0.75, Quaternion(Vector3.RIGHT, deg_to_rad(5.0)))
	anim.rotation_track_insert_key(t_head, 1.5, Quaternion(Vector3.RIGHT, deg_to_rad(-5.0)))

	return anim
