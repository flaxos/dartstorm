class_name ModelLoaderService
extends Node
## Central 3D Model & Rigging Loader for DARTSTORM.
## Discovers, loads, caches, and instances .glb / glTF 2.0 assets for
## heroes, blasters, arena props, and cosmetics, with automatic fallback
## to procedural geometry if a model is missing.

const MODELS_ROOT := "res://assets/models/"
const HERO_MODEL_PATH := "res://assets/models/characters/hero_base.glb"
const HERO_MODEL_TSCN := "res://assets/models/characters/hero_base.tscn"
const BLASTER_DIR := "res://assets/models/blasters/"
const PROPS_DIR := "res://assets/models/props/"
const HATS_DIR := "res://assets/models/hats/"

## Master toggle to force procedural fallback for benchmarking / debugging.
var models_enabled: bool = true

var _scene_cache: Dictionary = {}


## Clears all cached PackedScene references.
func clear_cache() -> void:
	_scene_cache.clear()


## Checks if a 3D model asset exists at the specified project path.
func has_model(res_path: String) -> bool:
	if not models_enabled or res_path.is_empty():
		return false
	return ResourceLoader.exists(res_path) or FileAccess.file_exists(res_path)


## Checks if the base stylized hero model exists (.tscn or .glb).
func has_hero_model() -> bool:
	return has_model(HERO_MODEL_TSCN) or has_model(HERO_MODEL_PATH)


const BLASTER_ALIASES: Dictionary = {
	&"pocket_popper": &"popper",
	&"dart_sprayer": &"storm",
	&"ricochet_ranger": &"storm",
	&"double_trouble": &"sweeper",
	&"flaxs_chainstorm": &"chainstorm",
	&"foam_hammer": &"six_shot",
	&"hydro_soaker": &"six_shot",
	&"thunder_cannon": &"rocket",
	&"longshot": &"whisper",
	&"wind_whisperer": &"whisper",
	&"frost_ranger": &"whisper"
}


const PROP_ALIASES: Dictionary = {
	&"tree": &"cartoon_tree",
	&"slide": &"playground_slide",
	&"bunker": &"inflatable_bunker",
	&"goal": &"soccer_goal",
	&"table": &"picnic_table",
	&"dog": &"dog_house",
	&"tower": &"watchtower",
	&"crate": &"tactical_crate",
	&"barrel": &"tactical_barrel",
	&"barrier": &"inflatable_barrier",
	&"arch": &"archway_curved",
	&"awning": &"market_awning",
	&"urn": &"desert_urn",
	&"pallet": &"wooden_pallet"
}


## Resolves a prop ID to its base model ID via direct match or alias.
func resolve_prop_id(prop_id: StringName) -> StringName:
	var tscn_path := PROPS_DIR + str(prop_id) + ".tscn"
	var glb_path := PROPS_DIR + str(prop_id) + ".glb"
	if has_model(tscn_path) or has_model(glb_path):
		return prop_id
	if PROP_ALIASES.has(prop_id):
		return PROP_ALIASES[prop_id]
	return prop_id


## Resolves a weapon ID to its base blaster model ID via direct match or alias.
func resolve_blaster_id(blaster_id: StringName) -> StringName:
	var tscn_path := BLASTER_DIR + str(blaster_id) + ".tscn"
	var glb_path := BLASTER_DIR + str(blaster_id) + ".glb"
	if has_model(tscn_path) or has_model(glb_path):
		return blaster_id
	if BLASTER_ALIASES.has(blaster_id):
		return BLASTER_ALIASES[blaster_id]
	return blaster_id


## Checks if a model exists for the given blaster ID (e.g. "popper", "six_shot").
func has_blaster_model(blaster_id: StringName) -> bool:
	if not models_enabled or blaster_id.is_empty():
		return false
	var resolved := resolve_blaster_id(blaster_id)
	var tscn_path := BLASTER_DIR + str(resolved) + ".tscn"
	if has_model(tscn_path):
		return true
	var glb_path := BLASTER_DIR + str(resolved) + ".glb"
	return has_model(glb_path)


## Checks if a model exists for the given prop ID (e.g. "slide", "gym", "tree").
func has_prop_model(prop_id: StringName) -> bool:
	if not models_enabled or prop_id.is_empty():
		return false
	var resolved := resolve_prop_id(prop_id)
	var tscn_path := PROPS_DIR + str(resolved) + ".tscn"
	if has_model(tscn_path):
		return true
	var glb_path := PROPS_DIR + str(resolved) + ".glb"
	return has_model(glb_path)


## Checks if a model exists for the given hat ID (e.g. "cap", "cowboy").
func has_hat_model(hat_id: StringName) -> bool:
	if not models_enabled or hat_id.is_empty():
		return false
	var glb_path := HATS_DIR + str(hat_id) + ".glb"
	if has_model(glb_path):
		return true
	var tscn_path := HATS_DIR + str(hat_id) + ".tscn"
	return has_model(tscn_path)


## Loads and caches a PackedScene from a path. Returns null on failure.
func load_scene(res_path: String) -> PackedScene:
	if not has_model(res_path):
		return null
	if _scene_cache.has(res_path):
		return _scene_cache[res_path]

	var scene: PackedScene = null

	# 1. Try native Godot ResourceLoader if already imported
	if ResourceLoader.exists(res_path):
		scene = ResourceLoader.load(res_path) as PackedScene

	# 2. Direct glTF / GLB loading via GLTFDocument for runtime/unimported files
	if scene == null and (res_path.ends_with(".glb") or res_path.ends_with(".gltf")):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(res_path, state)
		if err == OK:
			var root_node := doc.generate_scene(state)
			if root_node != null:
				scene = PackedScene.new()
				_set_owner_recursive(root_node, root_node)
				var pack_err := scene.pack(root_node)
				root_node.queue_free()
				if pack_err != OK:
					scene = null

	# 3. Fallback for .tscn and native scene files
	if scene == null and FileAccess.file_exists(res_path) and not (res_path.ends_with(".glb") or res_path.ends_with(".gltf")):
		scene = load(res_path) as PackedScene

	if scene != null:
		_scene_cache[res_path] = scene
	return scene


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)


## Instantiates a model node from a resource path. Returns null if missing.
func instantiate_model(res_path: String) -> Node3D:
	var scene := load_scene(res_path)
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance is Node3D:
		return instance as Node3D
	var wrapper := Node3D.new()
	wrapper.add_child(instance)
	return wrapper


## Instantiates the base hero model if present (.tscn or .glb).
func instantiate_hero() -> Node3D:
	if has_model(HERO_MODEL_TSCN):
		return instantiate_model(HERO_MODEL_TSCN)
	if has_model(HERO_MODEL_PATH):
		return instantiate_model(HERO_MODEL_PATH)
	return null


## Instantiates a blaster model by ID, resolving .tscn first then .glb.
func instantiate_blaster(blaster_id: StringName) -> Node3D:
	var resolved := resolve_blaster_id(blaster_id)
	var tscn_path := BLASTER_DIR + str(resolved) + ".tscn"
	if has_model(tscn_path):
		return instantiate_model(tscn_path)
	var glb_path := BLASTER_DIR + str(resolved) + ".glb"
	if has_model(glb_path):
		return instantiate_model(glb_path)
	return null


## Instantiates an arena prop model by ID, resolving .tscn first then .glb.
func instantiate_prop(prop_id: StringName) -> Node3D:
	var resolved := resolve_prop_id(prop_id)
	var tscn_path := PROPS_DIR + str(resolved) + ".tscn"
	if has_model(tscn_path):
		return instantiate_model(tscn_path)
	var glb_path := PROPS_DIR + str(resolved) + ".glb"
	if has_model(glb_path):
		return instantiate_model(glb_path)
	return null


## Instantiates a hat cosmetic model by ID.
func instantiate_hat(hat_id: StringName) -> Node3D:
	var glb_path := HATS_DIR + str(hat_id) + ".glb"
	if has_model(glb_path):
		return instantiate_model(glb_path)
	var tscn_path := HATS_DIR + str(hat_id) + ".tscn"
	if has_model(tscn_path):
		return instantiate_model(tscn_path)
	return null


## Recursively locates a Skeleton3D inside a model hierarchy.
func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null:
			return found
	return null


## Finds or creates a bone socket attachment on a character model.
## If the model contains a Skeleton3D and the bone exists, attaches a BoneAttachment3D.
## Otherwise creates a named Marker3D at the root.
func get_or_create_socket(root: Node3D, socket_name: StringName, bone_name: StringName = &"") -> Node3D:
	if root == null:
		return null

	# Check if socket node already exists
	var existing := root.find_child(str(socket_name), true, false)
	if existing is Node3D:
		return existing as Node3D

	# Search for skeleton
	var skeleton := find_skeleton(root)
	if skeleton != null and not bone_name.is_empty():
		var bone_idx := skeleton.find_bone(str(bone_name))
		if bone_idx >= 0:
			var attach := BoneAttachment3D.new()
			attach.name = str(socket_name)
			attach.bone_name = str(bone_name)
			skeleton.add_child(attach)
			return attach

	# Fallback marker
	var marker := Marker3D.new()
	marker.name = str(socket_name)
	root.add_child(marker)
	return marker


## Recursively applies custom materials to MeshInstance3D nodes matching slot names.
## material_map keys can match surface material names (case-insensitive substring)
## or standard slot identifiers: "chassis", "hardware", "safety", "grip", "clothing", "skin", "pants".
func apply_materials_recursive(node: Node, material_map: Dictionary) -> void:
	if node == null or material_map.is_empty():
		return

	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var node_name := mi.name.to_lower()
		var override_mat_name := mi.material_override.resource_name.to_lower() if mi.material_override != null else ""

		var matched_mat: Material = null
		for key in material_map.keys():
			var key_str := str(key).to_lower()
			if not override_mat_name.is_empty() and key_str in override_mat_name:
				matched_mat = material_map[key] as Material
				break
			elif key_str in node_name:
				matched_mat = material_map[key] as Material
				break

		if matched_mat != null:
			mi.material_override = matched_mat

		if mi.mesh != null and mi.mesh.get_surface_count() > 0:
			for surf_idx in mi.mesh.get_surface_count():
				var surf_mat := mi.mesh.surface_get_material(surf_idx)
				var mat_name := surf_mat.resource_name.to_lower() if surf_mat != null else ""
				var surf_matched: Material = matched_mat
				if surf_matched == null:
					for key in material_map.keys():
						var key_str := str(key).to_lower()
						if not mat_name.is_empty() and key_str in mat_name:
							surf_matched = material_map[key] as Material
							break
				if surf_matched != null:
					mi.set_surface_override_material(surf_idx, surf_matched)

	for child in node.get_children():
		apply_materials_recursive(child, material_map)
