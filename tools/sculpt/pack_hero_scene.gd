@tool
extends SceneTree
## Imports the Python-sculpted smooth-skinned assets/models/characters/hero_base.glb,
## attaches all 4 BoneAttachment3D sockets (Socket_Hand_R, Socket_Hand_L, Socket_Head,
## Socket_Back), parents animated facial expression meshes (Mesh_Eyelids, Mesh_MouthSmile,
## Mesh_MouthFlinch) under Attach_Head, builds lively bouncy AnimationPlayer clips,
## and packs assets/models/characters/hero_base.tscn so ModelLoader & all tests pass cleanly.

const SRC_GLB := "res://assets/models/characters/hero_base.glb"
const OUT_TSCN := "res://assets/models/characters/hero_base.tscn"


func _init() -> void:
	print("Packing sculpted v2.0.0 hero_base.tscn from ", SRC_GLB)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(SRC_GLB), state)
	if err != OK:
		printerr("Failed to read GLB: ", err)
		quit(1)
		return
	var root_node := doc.generate_scene(state) as Node3D
	if root_node == null:
		printerr("GLTFDocument returned null scene")
		quit(1)
		return
	root_node.name = "HeroBase"

	var skel := _find_skeleton(root_node)
	if skel == null:
		printerr("No Skeleton3D found inside sculpted hero_base.glb!")
		root_node.free()
		quit(1)
		return
	skel.name = "GeneralSkeleton"

	# 1. Standard 4 BoneAttachment3D sockets expected by CharacterModel & test suite
	_add_bone_socket(skel, "Socket_Hand_R", "Hand_R", Vector3.ZERO)
	_add_bone_socket(skel, "Socket_Hand_L", "Hand_L", Vector3.ZERO)
	_add_bone_socket(skel, "Socket_Head", "Head", Vector3(0.0, 0.24, 0.0))
	_add_bone_socket(skel, "Socket_Back", "Chest", Vector3(0.0, 0.02, 0.22))

	# 2. Reparent facial expression meshes under Attach_Head so they follow Head bone cleanly
	var attach_head := _add_bone_socket(skel, "Attach_Head", "Head", Vector3.ZERO)
	for expr_name in ["Mesh_Eyelids", "Mesh_MouthSmile", "Mesh_MouthFlinch"]:
		var node := root_node.find_child(expr_name, true, false) as Node3D
		if node != null:
			node.owner = null
			node.get_parent().remove_child(node)
			attach_head.add_child(node)
			node.position = Vector3.ZERO
			node.rotation = Vector3.ZERO
			if expr_name == "Mesh_Eyelids" or expr_name == "Mesh_MouthFlinch":
				node.visible = false

	# 3. Build expressive AnimationPlayer clips targeting GeneralSkeleton
	var skel_path := str(root_node.get_path_to(skel))
	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root_node.add_child(anim_player)

	var lib := AnimationLibrary.new()
	lib.add_animation(&"idle", _build_anim_idle(skel_path))
	lib.add_animation(&"run", _build_anim_run(skel_path))
	lib.add_animation(&"strafe_left", _build_anim_strafe(skel_path, -1.0))
	lib.add_animation(&"strafe_right", _build_anim_strafe(skel_path, 1.0))
	lib.add_animation(&"jump", _build_anim_jump(skel_path))
	lib.add_animation(&"flinch", _build_anim_flinch(skel_path))
	lib.add_animation(&"victory", _build_anim_victory(skel_path))
	anim_player.add_animation_library(&"", lib)

	skel.reset_bone_poses()
	for i in skel.get_bone_count():
		skel.force_update_bone_child_transform(i)

	_set_owner_recursive(root_node, root_node)
	var packed := PackedScene.new()
	var pack_err := packed.pack(root_node)
	if pack_err != OK:
		printerr("Failed to pack hero_base.tscn: ", pack_err)
		root_node.free()
		quit(1)
		return
	var save_err := ResourceSaver.save(packed, OUT_TSCN)
	if save_err != OK:
		printerr("Failed to save hero_base.tscn: ", save_err)
		root_node.free()
		quit(1)
		return
	print("Saved sculpted smooth-skinned hero scene to ", OUT_TSCN, " (bones=", skel.get_bone_count(), ")")
	root_node.free()
	quit(0)


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var found := _find_skeleton(c)
		if found != null:
			return found
	return null


func _add_bone_socket(skel: Skeleton3D, node_name: String, bone_name: String, offset: Vector3) -> BoneAttachment3D:
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


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for c in node.get_children():
		c.owner = new_owner
		_set_owner_recursive(c, new_owner)


func _add_rot_track(anim: Animation, skel_path: String, bone: String, keys: Array) -> void:
	var t := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, "%s:%s" % [skel_path, bone])
	for k in keys:
		var e: Vector3 = k[1]
		var q := Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))
		anim.rotation_track_insert_key(t, float(k[0]), q)


func _add_pos_track(anim: Animation, skel_path: String, bone: String, keys: Array) -> void:
	var t := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t, "%s:%s" % [skel_path, bone])
	for k in keys:
		anim.position_track_insert_key(t, float(k[0]), k[1] as Vector3)


func _build_anim_idle(sp: String) -> Animation:
	var a := Animation.new()
	a.length = 1.8
	a.loop_mode = Animation.LOOP_LINEAR
	_add_pos_track(a, sp, "Hips", [
		[0.0, Vector3(0.0, 0.66, 0.0)],
		[0.9, Vector3(0.0, 0.685, 0.0)],
		[1.8, Vector3(0.0, 0.66, 0.0)],
	])
	_add_rot_track(a, sp, "Chest", [
		[0.0, Vector3(0.0, 0.0, 0.0)],
		[0.9, Vector3(2.8, 2.0, 0.0)],
		[1.8, Vector3(0.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "Head", [
		[0.0, Vector3(0.0, -2.0, 0.0)],
		[0.9, Vector3(-2.5, 3.0, 2.0)],
		[1.8, Vector3(0.0, -2.0, 0.0)],
	])
	_add_rot_track(a, sp, "UpperArm_L", [
		[0.0, Vector3(6.0, 0.0, -7.0)],
		[0.9, Vector3(11.0, 0.0, -10.0)],
		[1.8, Vector3(6.0, 0.0, -7.0)],
	])
	return a


func _build_anim_run(sp: String) -> Animation:
	var a := Animation.new()
	a.length = 0.56
	a.loop_mode = Animation.LOOP_LINEAR
	_add_pos_track(a, sp, "Hips", [
		[0.00, Vector3(0.0, 0.65, 0.0)],
		[0.14, Vector3(0.0, 0.72, 0.0)],
		[0.28, Vector3(0.0, 0.65, 0.0)],
		[0.42, Vector3(0.0, 0.72, 0.0)],
		[0.56, Vector3(0.0, 0.65, 0.0)],
	])
	_add_rot_track(a, sp, "Spine", [
		[0.00, Vector3(-11.0, 6.0, 0.0)],
		[0.28, Vector3(-11.0, -6.0, 0.0)],
		[0.56, Vector3(-11.0, 6.0, 0.0)],
	])
	_add_rot_track(a, sp, "UpperLeg_L", [
		[0.00, Vector3(42.0, 0.0, 0.0)],
		[0.28, Vector3(-38.0, 0.0, 0.0)],
		[0.56, Vector3(42.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "LowerLeg_L", [
		[0.00, Vector3(-10.0, 0.0, 0.0)],
		[0.14, Vector3(-48.0, 0.0, 0.0)],
		[0.28, Vector3(-18.0, 0.0, 0.0)],
		[0.56, Vector3(-10.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "UpperLeg_R", [
		[0.00, Vector3(-38.0, 0.0, 0.0)],
		[0.28, Vector3(42.0, 0.0, 0.0)],
		[0.56, Vector3(-38.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "LowerLeg_R", [
		[0.00, Vector3(-18.0, 0.0, 0.0)],
		[0.28, Vector3(-10.0, 0.0, 0.0)],
		[0.42, Vector3(-48.0, 0.0, 0.0)],
		[0.56, Vector3(-18.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "UpperArm_L", [
		[0.00, Vector3(-32.0, 0.0, -10.0)],
		[0.28, Vector3(36.0, 0.0, -10.0)],
		[0.56, Vector3(-32.0, 0.0, -10.0)],
	])
	return a


func _build_anim_strafe(sp: String, dir: float) -> Animation:
	var a := Animation.new()
	a.length = 0.52
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot_track(a, sp, "Spine", [
		[0.0, Vector3(-5.0, 0.0, dir * -8.0)],
		[0.52, Vector3(-5.0, 0.0, dir * -8.0)],
	])
	_add_rot_track(a, sp, "UpperLeg_L", [
		[0.00, Vector3(0.0, 0.0, dir * 20.0)],
		[0.26, Vector3(0.0, 0.0, dir * -12.0)],
		[0.52, Vector3(0.0, 0.0, dir * 20.0)],
	])
	_add_rot_track(a, sp, "UpperLeg_R", [
		[0.00, Vector3(0.0, 0.0, dir * -12.0)],
		[0.26, Vector3(0.0, 0.0, dir * 20.0)],
		[0.52, Vector3(0.0, 0.0, dir * -12.0)],
	])
	return a


func _build_anim_jump(sp: String) -> Animation:
	var a := Animation.new()
	a.length = 0.45
	_add_rot_track(a, sp, "UpperLeg_L", [[0.0, Vector3(36.0, 0.0, -8.0)]])
	_add_rot_track(a, sp, "LowerLeg_L", [[0.0, Vector3(-52.0, 0.0, 0.0)]])
	_add_rot_track(a, sp, "UpperLeg_R", [[0.0, Vector3(-24.0, 0.0, 8.0)]])
	_add_rot_track(a, sp, "LowerLeg_R", [[0.0, Vector3(-38.0, 0.0, 0.0)]])
	_add_rot_track(a, sp, "UpperArm_L", [[0.0, Vector3(28.0, 0.0, -32.0)]])
	return a


func _build_anim_flinch(sp: String) -> Animation:
	var a := Animation.new()
	a.length = 0.28
	_add_rot_track(a, sp, "Chest", [
		[0.00, Vector3(0.0, 0.0, 0.0)],
		[0.08, Vector3(18.0, -14.0, 10.0)],
		[0.28, Vector3(0.0, 0.0, 0.0)],
	])
	_add_rot_track(a, sp, "Head", [
		[0.00, Vector3(0.0, 0.0, 0.0)],
		[0.08, Vector3(14.0, 10.0, -8.0)],
		[0.28, Vector3(0.0, 0.0, 0.0)],
	])
	return a


func _build_anim_victory(sp: String) -> Animation:
	var a := Animation.new()
	a.length = 1.0
	a.loop_mode = Animation.LOOP_LINEAR
	_add_pos_track(a, sp, "Hips", [
		[0.00, Vector3(0.0, 0.66, 0.0)],
		[0.25, Vector3(0.0, 0.80, 0.0)],
		[0.50, Vector3(0.0, 0.66, 0.0)],
		[0.75, Vector3(0.0, 0.78, 0.0)],
		[1.00, Vector3(0.0, 0.66, 0.0)],
	])
	_add_rot_track(a, sp, "UpperArm_L", [
		[0.00, Vector3(145.0, 0.0, -24.0)],
		[0.50, Vector3(162.0, 0.0, -40.0)],
		[1.00, Vector3(145.0, 0.0, -24.0)],
	])
	_add_rot_track(a, sp, "UpperArm_R", [
		[0.00, Vector3(162.0, 0.0, 40.0)],
		[0.50, Vector3(145.0, 0.0, 24.0)],
		[1.00, Vector3(162.0, 0.0, 40.0)],
	])
	_add_rot_track(a, sp, "Head", [
		[0.00, Vector3(-6.0, -10.0, -8.0)],
		[0.50, Vector3(-6.0, 10.0, 8.0)],
		[1.00, Vector3(-6.0, -10.0, -8.0)],
	])
	return a
