@tool
extends SceneTree
## Packs sculpted First-Person Pixar Hoodie Arms & Articulated Hands (.glb -> .tscn).

const GLB_PATH := "res://assets/models/characters/fp_arms.glb"
const TSCN_PATH := "res://assets/models/characters/fp_arms.tscn"


func _init() -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(GLB_PATH), state)
	if err != OK:
		printerr("Failed to read ", GLB_PATH, " err=", err)
		quit(1)
		return
	var arms_root := doc.generate_scene(state) as Node3D
	if arms_root == null:
		printerr("Null FP arms root")
		quit(1)
		return
	# Flatten single redundant glTF root wrapper so RightArm & LeftArm are direct children!
	var pack_root: Node3D = arms_root
	if arms_root.get_child_count() == 1 and arms_root.get_child(0) is Node3D and arms_root.get_child(0).name == "FirstPersonArms":
		var inner := arms_root.get_child(0) as Node3D
		inner.owner = null
		arms_root.remove_child(inner)
		arms_root.free()
		pack_root = inner
	pack_root.name = "FirstPersonArms"
	_set_owner_recursive(pack_root, pack_root)
	var packed := PackedScene.new()
	if packed.pack(pack_root) != OK:
		pack_root.free()
		quit(1)
		return
	if ResourceSaver.save(packed, TSCN_PATH) != OK:
		pack_root.free()
		quit(1)
		return
	print("Packed sculpted FP arms: ", TSCN_PATH)
	pack_root.free()
	quit(0)


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for c in node.get_children():
		c.owner = new_owner
		_set_owner_recursive(c, new_owner)
