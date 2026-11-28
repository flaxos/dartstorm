@tool
extends SceneTree
## Packs all sculpted v2.0.0 arena prop .glb models into companion .tscn scenes
## with StaticBody3D root on Layers.WORLD, exact v1.0 CollisionShape3D footprints,
## chromatic cel ShaderMaterials (vertex-AO enabled), and warm-navy comic outlines.
## Also upgrades the remaining 5 procedural prop .tscn scenes with chromatic cel shaders!

const PROPS_DIR := "res://assets/models/props/"
const TOON_SHADER := preload("res://assets/materials/dartstorm_toon.gdshader")
const OUTLINE_SHADER := preload("res://assets/materials/toon_outline.gdshader")
const WOOD_SHADER := preload("res://assets/materials/toy_wood.gdshader")

const SCULPTED_PROPS := [
	"cartoon_tree",
	"inflatable_barrier",
	"inflatable_bunker",
	"tactical_crate",
	"tactical_barrel",
	"playground_slide",
	"archway_curved",
	"desert_urn",
	"dog_house",
]

const UPGRADE_ONLY_PROPS := [
	"picnic_table",
	"soccer_goal",
	"watchtower",
	"market_awning",
	"wooden_pallet",
]

var _outline_mat: ShaderMaterial


func _init() -> void:
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = OUTLINE_SHADER
	_outline_mat.set_shader_parameter(&"outline_color", Color(0.039, 0.094, 0.239, 1.0))
	_outline_mat.set_shader_parameter(&"outline_width", 0.008)
	_outline_mat.set_shader_parameter(&"distance_scale", 0.0018)
	_outline_mat.set_shader_parameter(&"fade_start", 30.0)
	_outline_mat.set_shader_parameter(&"fade_end", 54.0)

	for pname: String in SCULPTED_PROPS:
		if not _pack_sculpted(pname):
			quit(1)
			return
	for pname: String in UPGRADE_ONLY_PROPS:
		if not _upgrade_existing_tscn(pname):
			quit(1)
			return
	print("All 14 v2.0.0 arena prop scenes packed cleanly!")
	quit(0)


func _pack_sculpted(pname: String) -> bool:
	var glb_path: String = ProjectSettings.globalize_path(PROPS_DIR + pname + ".glb")
	var tscn_path: String = PROPS_DIR + pname + ".tscn"
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(glb_path, state)
	if err != OK:
		printerr("Failed to read prop GLB: ", glb_path, " err=", err)
		return false
	var gltf_root := doc.generate_scene(state) as Node3D
	if gltf_root == null:
		printerr("Null GLTF scene for ", pname)
		return false

	var body := StaticBody3D.new()
	body.name = pname.to_pascal_case()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0

	while gltf_root.get_child_count() > 0:
		var child := gltf_root.get_child(0)
		child.owner = null
		gltf_root.remove_child(child)
		body.add_child(child)
	gltf_root.free()

	_apply_cel_materials_recursive(body, true)
	_add_prop_colliders(body, pname)
	_set_owner_recursive(body, body)

	var packed := PackedScene.new()
	if packed.pack(body) != OK:
		printerr("Failed to pack prop: ", pname)
		body.free()
		return false
	if ResourceSaver.save(packed, tscn_path) != OK:
		printerr("Failed to save prop: ", tscn_path)
		body.free()
		return false
	print("Packed sculpted v2 prop: ", tscn_path)
	body.free()
	return true


func _upgrade_existing_tscn(pname: String) -> bool:
	var tscn_path: String = PROPS_DIR + pname + ".tscn"
	var scene := ResourceLoader.load(tscn_path) as PackedScene
	if scene == null:
		printerr("Missing existing prop tscn: ", tscn_path)
		return false
	var inst := scene.instantiate() as Node3D
	if inst == null:
		return false
	_apply_cel_materials_recursive(inst, false)
	_set_owner_recursive(inst, inst)
	var packed := PackedScene.new()
	if packed.pack(inst) != OK:
		inst.free()
		return false
	if ResourceSaver.save(packed, tscn_path) != OK:
		inst.free()
		return false
	print("Upgraded cel materials on prop: ", tscn_path)
	inst.free()
	return true


func _apply_cel_materials_recursive(node: Node, use_vcol: bool) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var std := mi.material_override as StandardMaterial3D
			mi.material_override = _make_cel_mat(std.albedo_color, std.resource_name, std.roughness, use_vcol)
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var sm := mi.mesh.surface_get_material(s)
				if sm is StandardMaterial3D:
					var std2 := sm as StandardMaterial3D
					mi.set_surface_override_material(s, _make_cel_mat(std2.albedo_color, std2.resource_name, std2.roughness, use_vcol))
	for child in node.get_children():
		_apply_cel_materials_recursive(child, use_vcol)


func _make_cel_mat(col: Color, slot: String, rough: float, use_vcol: bool) -> ShaderMaterial:
	var key := slot.to_lower()
	var sm := ShaderMaterial.new()
	sm.resource_name = slot
	sm.shader = TOON_SHADER
	sm.set_shader_parameter(&"albedo_color", Color(col.r, col.g, col.b, 1.0))
	sm.set_shader_parameter(&"roughness", clampf(rough, 0.18, 0.88))
	sm.set_shader_parameter(&"use_vertex_color", use_vcol)
	var is_foliage := "leaf" in key
	var is_glossy := "vinyl" in key or "plastic" in key or "barrel" in key
	sm.set_shader_parameter(&"roughness", 0.88 if is_foliage else clampf(rough, 0.18, 0.88))
	sm.set_shader_parameter(&"specular_strength", 0.72 if is_glossy else (0.03 if is_foliage else 0.38))
	if is_foliage:
		sm.set_shader_parameter(&"shadow_tint", Color(0.10, 0.36, 0.24, 1.0))
		sm.set_shader_parameter(&"shadow_strength", 0.46)
	elif "wood" in key or "sandstone" in key or "terracotta" in key:
		sm.set_shader_parameter(&"shadow_tint", Color(0.38, 0.22, 0.18, 1.0))
		sm.set_shader_parameter(&"shadow_strength", 0.42)
	else:
		sm.set_shader_parameter(&"shadow_tint", Color(0.22, 0.26, 0.56, 1.0))
		sm.set_shader_parameter(&"shadow_strength", 0.42)
	if not ("net" in key):
		sm.next_pass = _outline_mat
	return sm


func _add_prop_colliders(body: StaticBody3D, pname: String) -> void:
	match pname:
		"cartoon_tree":
			_col_cyl(body, 0.75, 4.5, Vector3(0.0, 2.25, 0.0))
		"inflatable_barrier":
			_col_box(body, Vector3(2.4, 1.3, 0.65), Vector3(0.0, 0.65, 0.0))
		"inflatable_bunker":
			_col_cyl(body, 0.77, 2.3, Vector3(0.0, 1.05, 0.0))
		"tactical_crate":
			_col_box(body, Vector3(1.8, 1.8, 1.8), Vector3(0.0, 0.9, 0.0))
		"tactical_barrel":
			_col_cyl(body, 0.44, 1.4, Vector3(0.0, 0.7, 0.0))
		"playground_slide":
			var deck_h := 3.2
			_col_box(body, Vector3(2.4, 0.25, 2.4), Vector3(0.0, deck_h, 0.0))
			_col_box(body, Vector3(2.4, 1.0, 0.12), Vector3(0.0, deck_h + 0.5, -1.15))
			_col_box(body, Vector3(0.12, 1.0, 2.4), Vector3(-1.15, deck_h + 0.5, 0.0))
			var chute_start := Vector3(1.2, deck_h, 0.0)
			var chute_end := Vector3(6.5, 0.15, 0.0)
			var slide_len := (chute_end - chute_start).length()
			var slide_mid := (chute_start + chute_end) * 0.5
			var slide_angle := rad_to_deg(atan2(deck_h - 0.15, 6.5 - 1.2))
			_col_box(body, Vector3(slide_len, 0.25, 1.5), slide_mid, Vector3(0.0, 0.0, slide_angle))
			_col_box(body, Vector3(1.6, 0.20, 1.5), Vector3(7.1, 0.10, 0.0))
		"archway_curved":
			var pillar_w := 0.8
			var pillar_h := 3.6
			var depth := 1.2
			var half_span := 1.8
			var top_w := (half_span + pillar_w) * 2.0 + 0.3
			_col_box(body, Vector3(pillar_w, pillar_h, depth), Vector3(-half_span - pillar_w * 0.5, pillar_h * 0.5, 0.0))
			_col_box(body, Vector3(pillar_w, pillar_h, depth), Vector3(half_span + pillar_w * 0.5, pillar_h * 0.5, 0.0))
			_col_box(body, Vector3(top_w, 1.2, depth), Vector3(0.0, pillar_h + 0.9, 0.0))
		"desert_urn":
			_col_cyl(body, 0.44, 1.14, Vector3(0.0, 0.57, 0.0))
		"dog_house":
			_col_box(body, Vector3(2.0, 1.6, 2.2), Vector3(0.0, 0.8, 0.0))
			_col_box(body, Vector3(0.85, 0.85, 1.35), Vector3(0.0, 0.425, 2.0))


func _col_box(body: StaticBody3D, size: Vector3, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	c.position = pos
	c.rotation_degrees = rot_deg
	body.add_child(c)


func _col_cyl(body: StaticBody3D, r: float, h: float, pos: Vector3) -> void:
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	c.shape = s
	c.position = pos
	body.add_child(c)


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for c in node.get_children():
		c.owner = new_owner
		_set_owner_recursive(c, new_owner)
