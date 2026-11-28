@tool
extends SceneTree
## Converts all 7 sculpted v2.0.0 blaster .glb assets into companion .tscn scenes
## with Marker3D sockets preserved cleanly so ModelLoader & all tests load them identically.

const BLASTER_DIR := "res://assets/models/blasters/"
const NAMES := ["popper", "six_shot", "storm", "sweeper", "whisper", "chainstorm", "rocket"]


func _init() -> void:
	for bname: String in NAMES:
		var glb_path: String = ProjectSettings.globalize_path(BLASTER_DIR + bname + ".glb")
		var tscn_path: String = BLASTER_DIR + bname + ".tscn"
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(glb_path, state)
		if err != OK:
			printerr("Failed to read ", glb_path, " err=", err)
			quit(1)
			return
		var scene_root := doc.generate_scene(state) as Node3D
		if scene_root == null:
			printerr("Null scene for ", bname)
			quit(1)
			return
		scene_root.name = "Blaster_" + bname
		_convert_markers_recursive(scene_root)
		_set_owner_recursive(scene_root, scene_root)
		var packed := PackedScene.new()
		if packed.pack(scene_root) != OK:
			printerr("Failed to pack ", bname)
			scene_root.free()
			quit(1)
			return
		if ResourceSaver.save(packed, tscn_path) != OK:
			printerr("Failed to save ", tscn_path)
			scene_root.free()
			quit(1)
			return
		print("Packed sculpted blaster: ", tscn_path)
		scene_root.free()
	quit(0)


func _convert_markers_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D and not (child is MeshInstance3D) and String(child.name).ends_with("Marker"):
			var c3 := child as Node3D
			var mk := Marker3D.new()
			mk.name = c3.name
			mk.transform = c3.transform
			var idx := c3.get_index()
			node.remove_child(c3)
			c3.free()
			node.add_child(mk)
			node.move_child(mk, idx)
		else:
			_convert_markers_recursive(child)


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for c in node.get_children():
		c.owner = new_owner
		_set_owner_recursive(c, new_owner)
