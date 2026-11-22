@tool
extends SceneTree
## Generates all 7 production-ready AAA stylized arena 3D props:
## dog_house, playground_slide, picnic_table, inflatable_bunker,
## soccer_goal, cartoon_tree, watchtower.
## Each prop contains static physics collision on Layers.WORLD, PBR material
## assignments, and interactive hooks where applicable.

const PROPS_DIR := "res://assets/models/props/"

# Vibrant Toy Palette
const CEDAR_WOOD := Color(0.72, 0.50, 0.30)
const CEDAR_DARK := Color(0.52, 0.34, 0.18)
const SHINGLE_RED := Color(0.85, 0.26, 0.20)
const STEEL_WHITE := Color(0.95, 0.95, 0.98)
const STEEL_DARK := Color(0.22, 0.24, 0.28)
const TOY_YELLOW := Color(1.0, 0.82, 0.10)
const TOY_BLUE := Color(0.18, 0.48, 0.95)
const TOY_ORANGE := Color(1.0, 0.48, 0.08)
const TOY_GREEN := Color(0.25, 0.75, 0.28)
const LEAF_DARK := Color(0.22, 0.62, 0.22)
const LEAF_LIGHT := Color(0.38, 0.78, 0.30)
const FUR_GOLD := Color(0.85, 0.62, 0.35)
const FUR_BROWN := Color(0.52, 0.35, 0.18)
const VINYL_BLUE := Color(0.12, 0.55, 0.95)
const VINYL_ACCENT := Color(1.0, 0.42, 0.05)

var mat_wood: StandardMaterial3D
var mat_wood_dark: StandardMaterial3D
var mat_shingle: StandardMaterial3D
var mat_plastic_yellow: StandardMaterial3D
var mat_plastic_red: StandardMaterial3D
var mat_plastic_blue: StandardMaterial3D
var mat_plastic_orange: StandardMaterial3D
var mat_steel: StandardMaterial3D
var mat_steel_dark: StandardMaterial3D
var mat_leaf: StandardMaterial3D
var mat_leaf_light: StandardMaterial3D
var mat_fur: StandardMaterial3D
var mat_fur_dark: StandardMaterial3D
var mat_vinyl: StandardMaterial3D
var mat_vinyl_accent: StandardMaterial3D
var mat_net: StandardMaterial3D


func _init() -> void:
	print("Generating AAA 3D stylized arena props...")
	_setup_materials()

	_build_and_save("dog_house", _build_dog_house())
	_build_and_save("playground_slide", _build_playground_slide())
	_build_and_save("picnic_table", _build_picnic_table())
	_build_and_save("inflatable_bunker", _build_inflatable_bunker())
	_build_and_save("soccer_goal", _build_soccer_goal())
	_build_and_save("cartoon_tree", _build_cartoon_tree())
	_build_and_save("watchtower", _build_watchtower())

	print("Arena props generation complete!")
	quit(0)


func _setup_materials() -> void:
	mat_wood = _create_mat(CEDAR_WOOD, "wood", 0.72, 0.0)
	mat_wood_dark = _create_mat(CEDAR_DARK, "wood_dark", 0.78, 0.0)
	mat_shingle = _create_mat(SHINGLE_RED, "shingle", 0.65, 0.0)
	mat_plastic_yellow = _create_mat(TOY_YELLOW, "plastic_yellow", 0.32, 0.04)
	mat_plastic_red = _create_mat(Color(0.92, 0.22, 0.20), "plastic_red", 0.32, 0.04)
	mat_plastic_blue = _create_mat(TOY_BLUE, "plastic_blue", 0.32, 0.04)
	mat_plastic_orange = _create_mat(TOY_ORANGE, "plastic_orange", 0.32, 0.04)
	mat_steel = _create_mat(STEEL_WHITE, "steel", 0.25, 0.85)
	mat_steel_dark = _create_mat(STEEL_DARK, "steel_dark", 0.30, 0.75)
	mat_leaf = _create_mat(LEAF_DARK, "leaf", 0.75, 0.0)
	mat_leaf_light = _create_mat(LEAF_LIGHT, "leaf_light", 0.70, 0.0)
	mat_fur = _create_mat(FUR_GOLD, "fur", 0.82, 0.0)
	mat_fur_dark = _create_mat(FUR_BROWN, "fur_dark", 0.85, 0.0)
	mat_vinyl = _create_mat(VINYL_BLUE, "vinyl", 0.28, 0.06)
	mat_vinyl_accent = _create_mat(VINYL_ACCENT, "vinyl_accent", 0.28, 0.06)

	mat_net = StandardMaterial3D.new()
	mat_net.resource_name = "net"
	mat_net.albedo_color = Color(0.95, 0.96, 0.98, 1.0)
	mat_net.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat_net.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat_net.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_net.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat_net.roughness = 0.6
	mat_net.cull_mode = BaseMaterial3D.CULL_BACK


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


func _build_and_save(prop_id: String, prop_root: Node3D) -> void:
	var tscn_path := PROPS_DIR + prop_id + ".tscn"
	var glb_path := PROPS_DIR + prop_id + ".glb"

	# 1. Save .tscn
	_set_owner_recursive(prop_root, prop_root)
	var packed := PackedScene.new()
	var pack_err := packed.pack(prop_root)
	if pack_err == OK:
		var save_err := ResourceSaver.save(packed, tscn_path)
		if save_err == OK:
			print("Saved %s to %s" % [prop_id, tscn_path])
		else:
			printerr("Failed to save %s: %d" % [tscn_path, save_err])
	else:
		printerr("Failed to pack %s: %d" % [prop_id, pack_err])

	# 2. Export .glb
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var append_err := doc.append_from_scene(prop_root, state)
	if append_err == OK:
		var glb_err := doc.write_to_filesystem(state, glb_path)
		if glb_err == OK:
			print("Exported %s to %s" % [prop_id, glb_path])
		else:
			print("GLTF write note (%s): %d" % [prop_id, glb_err])

	prop_root.free()


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)


# --- Helper Builders --------------------------------------------------------

func _create_static_root(prop_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = prop_name
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	return body


func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _add_sphere(parent: Node3D, node_name: String, radius: float, pos: Vector3, mat: Material, scale_vec: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 16
	sph.rings = 8
	mi.mesh = sph
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_vec
	parent.add_child(mi)
	return mi


func _add_collision_box(parent: StaticBody3D, size: Vector3, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	col.rotation_degrees = rot_deg
	parent.add_child(col)
	return col


func _add_collision_cylinder(parent: StaticBody3D, radius: float, height: float, pos: Vector3) -> CollisionShape3D:
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	col.position = pos
	parent.add_child(col)
	return col


# ============================================================================
# 1. DOG HOUSE + CARTOON PUPPY
# ============================================================================
func _build_dog_house() -> StaticBody3D:
	var prop_root := _create_static_root("DogHouse")
	var size := Vector3(2.0, 1.6, 2.2)

	# Main House Collision
	_add_collision_box(prop_root, size, Vector3(0.0, size.y * 0.5, 0.0))

	# Base wooden foundation
	_add_box(prop_root, "Base", Vector3(size.x + 0.15, 0.16, size.z + 0.15), Vector3(0.0, 0.08, 0.0), mat_wood_dark)

	# Red cedar siding body
	_add_box(prop_root, "Chassis", Vector3(size.x, size.y - 0.16, size.z), Vector3(0.0, (size.y + 0.16) * 0.5, 0.0), mat_shingle)

	# Corner trim posts
	for x_side in [-1.0, 1.0]:
		for z_side in [-1.0, 1.0]:
			var post_pos := Vector3(x_side * (size.x * 0.5 - 0.06), size.y * 0.5, z_side * (size.z * 0.5 - 0.06))
			_add_box(prop_root, "TrimPost", Vector3(0.14, size.y, 0.14), post_pos, mat_wood_dark)

	# Pitched Shingle Roof
	var roof_node := MeshInstance3D.new()
	roof_node.name = "Roof"
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x + 0.45, 0.95, size.z + 0.35)
	roof_node.mesh = prism
	roof_node.material_override = mat_wood_dark
	roof_node.position = Vector3(0.0, size.y + 0.45, 0.0)
	prop_root.add_child(roof_node)

	# Front entryway cutout arch (Dark interior illusion)
	_add_box(prop_root, "Doorway", Vector3(0.92, 1.05, 0.08), Vector3(0.0, 0.55, size.z * 0.5 + 0.02), mat_steel_dark)

	# Food bowl with foam kibbles
	var bowl_pos := Vector3(0.75, 0.0, size.z * 0.5 + 0.45)
	_add_cylinder(prop_root, "DogBowl", 0.24, 0.14, bowl_pos + Vector3(0.0, 0.07, 0.0), mat_steel)
	_add_sphere(prop_root, "Kibble1", 0.06, bowl_pos + Vector3(0.04, 0.12, 0.02), mat_plastic_orange)
	_add_sphere(prop_root, "Kibble2", 0.06, bowl_pos + Vector3(-0.05, 0.12, -0.04), mat_plastic_yellow)

	# Animated Cartoon Puppy (_dog node)
	var dog := Node3D.new()
	dog.name = "_dog"
	dog.position = Vector3(0.0, 0.0, size.z * 0.5 + 0.9)
	prop_root.add_child(dog)

	# Body loaf
	_add_sphere(dog, "DogBody", 0.38, Vector3(0.0, 0.30, 0.10), mat_fur, Vector3(0.95, 0.95, 1.35))
	# Head
	_add_sphere(dog, "DogHead", 0.28, Vector3(0.0, 0.56, -0.42), mat_fur)
	# Muzzle
	_add_sphere(dog, "DogMuzzle", 0.14, Vector3(0.0, 0.50, -0.66), mat_fur_dark, Vector3(1.1, 0.9, 1.1))
	# Button nose
	_add_sphere(dog, "DogNose", 0.055, Vector3(0.0, 0.56, -0.78), mat_steel_dark)

	# Eyes with white catchlights
	for side in [-1.0, 1.0]:
		_add_sphere(dog, "Eye", 0.048, Vector3(side * 0.11, 0.65, -0.63), mat_steel_dark)
		_add_sphere(dog, "EyeCatch", 0.016, Vector3(side * 0.11 + 0.01, 0.665, -0.665), mat_steel)
		# Floppy ears
		var ear := _add_box(dog, "Ear", Vector3(0.12, 0.28, 0.16), Vector3(side * 0.26, 0.62, -0.40), mat_fur_dark)
		ear.rotation_degrees = Vector3(15.0, 0.0, side * 24.0)
		# Paws
		_add_sphere(dog, "FrontPaw", 0.10, Vector3(side * 0.22, 0.09, -0.32), mat_fur, Vector3(1.0, 0.7, 1.2))
		_add_sphere(dog, "BackPaw", 0.11, Vector3(side * 0.24, 0.09, 0.35), mat_fur, Vector3(1.0, 0.7, 1.2))

	# Tail node (_tail)
	var tail := Node3D.new()
	tail.name = "_tail"
	tail.position = Vector3(0.0, 0.42, 0.55)
	dog.add_child(tail)
	_add_cylinder(tail, "TailMesh", 0.055, 0.42, Vector3(0.0, 0.18, 0.0), mat_fur_dark, Vector3(25.0, 0.0, 0.0))

	return prop_root


# ============================================================================
# 2. PLAYGROUND SLIDE
# ============================================================================
func _build_playground_slide() -> StaticBody3D:
	var prop_root := _create_static_root("PlaygroundSlide")
	var deck_h := 3.2
	var platform_size := Vector3(2.4, 0.25, 2.4)

	# 4 Stilt Legs
	for ox in [-0.95, 0.95]:
		for oz in [-0.95, 0.95]:
			_add_cylinder(prop_root, "Stilt", 0.14, deck_h, Vector3(ox, deck_h * 0.5, oz), mat_steel)

	# Platform Slab
	_add_box(prop_root, "Deck", platform_size, Vector3(0.0, deck_h, 0.0), mat_plastic_blue)
	_add_collision_box(prop_root, platform_size, Vector3(0.0, deck_h, 0.0))

	# Safety Railings around Platform (Back and sides)
	_add_box(prop_root, "RailBack", Vector3(2.4, 1.0, 0.12), Vector3(0.0, deck_h + 0.5, -1.15), mat_plastic_yellow)
	_add_box(prop_root, "RailLeft", Vector3(0.12, 1.0, 2.4), Vector3(-1.15, deck_h + 0.5, 0.0), mat_plastic_yellow)
	_add_collision_box(prop_root, Vector3(2.4, 1.0, 0.12), Vector3(0.0, deck_h + 0.5, -1.15))
	_add_collision_box(prop_root, Vector3(0.12, 1.0, 2.4), Vector3(-1.15, deck_h + 0.5, 0.0))

	# Ladder on South side
	for r in 7:
		var rung_y := float(r) * (deck_h / 7.0) + 0.2
		_add_cylinder(prop_root, "LadderRung", 0.06, 1.0, Vector3(0.0, rung_y, 1.25), mat_steel_dark, Vector3(0.0, 0.0, 90.0))

	# Molded Slide Chute running to +X
	# Chute runs from Vector3(1.2, deck_h, 0.0) to Vector3(6.5, 0.15, 0.0)
	var chute_start := Vector3(1.2, deck_h, 0.0)
	var chute_end := Vector3(6.5, 0.15, 0.0)
	var slide_len := (chute_end - chute_start).length()
	var slide_mid := (chute_start + chute_end) * 0.5
	var slide_angle := rad_to_deg(atan2(deck_h - 0.15, 6.5 - 1.2))

	# Main Chute Bed
	var chute := _add_box(prop_root, "SlideBed", Vector3(slide_len, 0.18, 1.5), slide_mid, mat_plastic_yellow)
	chute.rotation_degrees = Vector3(0.0, 0.0, slide_angle)

	# Raised Red Safety Lips on both sides
	var lip_z1 := _add_box(prop_root, "SlideLipL", Vector3(slide_len, 0.45, 0.14), slide_mid + Vector3(0.0, 0.18, -0.72), mat_plastic_red)
	lip_z1.rotation_degrees = Vector3(0.0, 0.0, slide_angle)
	var lip_z2 := _add_box(prop_root, "SlideLipR", Vector3(slide_len, 0.45, 0.14), slide_mid + Vector3(0.0, 0.18, 0.72), mat_plastic_red)
	lip_z2.rotation_degrees = Vector3(0.0, 0.0, slide_angle)

	# Runout exit transition at bottom
	_add_box(prop_root, "SlideRunout", Vector3(1.6, 0.16, 1.5), Vector3(7.1, 0.08, 0.0), mat_plastic_yellow)

	# Slide Collision (Walkable ramp)
	_add_collision_box(prop_root, Vector3(slide_len, 0.25, 1.5), slide_mid, Vector3(0.0, 0.0, slide_angle))
	_add_collision_box(prop_root, Vector3(1.6, 0.20, 1.5), Vector3(7.1, 0.10, 0.0))

	return prop_root


# ============================================================================
# 3. PICNIC TABLE
# ============================================================================
func _build_picnic_table() -> StaticBody3D:
	var prop_root := _create_static_root("PicnicTable")
	var table_size := Vector3(2.5, 0.12, 1.4)
	var table_h := 0.85

	# Tabletop
	_add_box(prop_root, "Tabletop", table_size, Vector3(0.0, table_h, 0.0), mat_wood)
	_add_collision_box(prop_root, table_size, Vector3(0.0, table_h, 0.0))

	# A-Frame Legs and Cross-Bracing
	for x_side in [-0.92, 0.92]:
		for z_side in [-0.55, 0.55]:
			var leg := _add_box(prop_root, "Leg", Vector3(0.12, table_h, 0.12), Vector3(x_side, table_h * 0.5, z_side * 0.7), mat_wood_dark)
			leg.rotation_degrees = Vector3(z_side * 14.0, 0.0, 0.0)
		# Bench support crossbeam
		_add_box(prop_root, "BenchSupport", Vector3(0.12, 0.14, 2.1), Vector3(x_side, 0.45, 0.0), mat_wood_dark)

	# Dual Attached Benches
	var bench_size := Vector3(2.5, 0.10, 0.46)
	_add_box(prop_root, "BenchL", bench_size, Vector3(0.0, 0.48, -0.95), mat_wood)
	_add_box(prop_root, "BenchR", bench_size, Vector3(0.0, 0.48, 0.95), mat_wood)
	_add_collision_box(prop_root, bench_size, Vector3(0.0, 0.48, -0.95))
	_add_collision_box(prop_root, bench_size, Vector3(0.0, 0.48, 0.95))

	# Tabletop Foam Cooler Prop (Waist-high cover)
	_add_box(prop_root, "CoolerBody", Vector3(0.65, 0.38, 0.44), Vector3(0.55, table_h + 0.19, 0.0), mat_plastic_red)
	_add_box(prop_root, "CoolerLid", Vector3(0.68, 0.08, 0.47), Vector3(0.55, table_h + 0.39, 0.0), mat_steel)
	_add_collision_box(prop_root, Vector3(0.68, 0.46, 0.47), Vector3(0.55, table_h + 0.23, 0.0))

	return prop_root


# ============================================================================
# 4. INFLATABLE BUNKER (Speedball Can Bunker)
# ============================================================================
func _build_inflatable_bunker() -> StaticBody3D:
	var prop_root := _create_static_root("InflatableBunker")
	var radius := 0.72
	var height := 2.1

	# Main Inflatable Vinyl Cylinder
	_add_cylinder(prop_root, "VinylBody", radius, height, Vector3(0.0, height * 0.5, 0.0), mat_vinyl)
	# Domed Top Cap
	_add_sphere(prop_root, "DomeTop", radius, Vector3(0.0, height - 0.1, 0.0), mat_vinyl, Vector3(1.0, 0.5, 1.0))
	# Weighted Ground Skirt
	_add_cylinder(prop_root, "GroundSkirt", radius + 0.12, 0.12, Vector3(0.0, 0.06, 0.0), mat_vinyl_accent)

	# Raised Seam Welds
	for i in 4:
		var seam_angle := float(i) * 90.0
		var seam := _add_box(prop_root, "SeamWeld", Vector3(0.04, height * 0.95, 0.05), Vector3(0.0, height * 0.5, radius * 0.98), mat_vinyl_accent)
		seam.rotation_degrees = Vector3(0.0, seam_angle, 0.0)

	# High-visibility Accent Band
	_add_cylinder(prop_root, "AccentBand", radius + 0.015, 0.45, Vector3(0.0, height * 0.55, 0.0), mat_vinyl_accent)

	# Blaze Orange Air Valve
	_add_cylinder(prop_root, "AirValve", 0.08, 0.08, Vector3(radius + 0.02, 0.35, 0.0), mat_plastic_orange, Vector3(0.0, 0.0, 90.0))

	# Collision
	_add_collision_cylinder(prop_root, radius + 0.05, height + 0.2, Vector3(0.0, height * 0.5, 0.0))

	return prop_root


# ============================================================================
# 5. SOCCER GOAL
# ============================================================================
func _build_soccer_goal() -> StaticBody3D:
	var prop_root := _create_static_root("SoccerGoal")
	var w := 7.4
	var h := 2.4
	var d := 2.2
	var post_r := 0.10

	# Left & Right Upright Posts
	_add_cylinder(prop_root, "PostL", post_r, h, Vector3(-w * 0.5, h * 0.5, 0.0), mat_steel)
	_add_cylinder(prop_root, "PostR", post_r, h, Vector3(w * 0.5, h * 0.5, 0.0), mat_steel)
	_add_collision_cylinder(prop_root, post_r + 0.05, h, Vector3(-w * 0.5, h * 0.5, 0.0))
	_add_collision_cylinder(prop_root, post_r + 0.05, h, Vector3(w * 0.5, h * 0.5, 0.0))

	# Top Crossbar
	_add_cylinder(prop_root, "Crossbar", post_r, w, Vector3(0.0, h, 0.0), mat_steel, Vector3(0.0, 0.0, 90.0))
	_add_collision_box(prop_root, Vector3(w, post_r * 2.0, post_r * 2.0), Vector3(0.0, h, 0.0))

	# Rear Tension Stanchions (Angled down to back)
	var stanchion_len := sqrt(h * h + d * d)
	var stanchion_angle := rad_to_deg(atan2(d, h))
	for side in [-1.0, 1.0]:
		var stanchion := _add_cylinder(prop_root, "Stanchion", 0.06, stanchion_len, Vector3(side * w * 0.5, h * 0.5, -d * 0.5), mat_steel_dark)
		stanchion.rotation_degrees = Vector3(stanchion_angle, 0.0, 0.0)

	# Ground Anchor Frame
	_add_cylinder(prop_root, "GroundBack", 0.06, w, Vector3(0.0, 0.04, -d), mat_steel_dark, Vector3(0.0, 0.0, 90.0))
	_add_cylinder(prop_root, "GroundSideL", 0.06, d, Vector3(-w * 0.5, 0.04, -d * 0.5), mat_steel_dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(prop_root, "GroundSideR", 0.06, d, Vector3(w * 0.5, 0.04, -d * 0.5), mat_steel_dark, Vector3(90.0, 0.0, 0.0))

	# Netting Walls (Back, Top, Sides)
	_add_box(prop_root, "NetBack", Vector3(w, h * 1.1, 0.02), Vector3(0.0, h * 0.5, -d * 0.75), mat_net)
	_add_collision_box(prop_root, Vector3(w, h, 0.08), Vector3(0.0, h * 0.5, -d))

	return prop_root


# ============================================================================
# 6. CARTOON TREE
# ============================================================================
func _build_cartoon_tree() -> StaticBody3D:
	var prop_root := _create_static_root("CartoonTree")
	var trunk_h := 4.5
	var trunk_r := 0.65

	# Stylized Curved Bark Trunk
	_add_cylinder(prop_root, "TrunkBase", trunk_r, trunk_h, Vector3(0.0, trunk_h * 0.5, 0.0), mat_wood_dark)

	# Flared Buttress Roots
	for i in 4:
		var root_angle := float(i) * 90.0
		var r_mesh := _add_box(prop_root, "ButtressRoot", Vector3(0.35, 0.65, 1.1), Vector3(0.0, 0.32, trunk_r * 0.8), mat_wood_dark)
		r_mesh.rotation_degrees = Vector3(-18.0, root_angle, 0.0)

	# 4 Stepped Foliage Canopy Clumps
	_add_sphere(prop_root, "CanopyBase", 3.2, Vector3(0.0, trunk_h + 0.7, 0.0), mat_leaf, Vector3(1.15, 0.85, 1.15))
	_add_sphere(prop_root, "CanopyTop", 2.4, Vector3(0.2, trunk_h + 2.2, -0.3), mat_leaf_light, Vector3(1.0, 0.9, 1.0))
	_add_sphere(prop_root, "CanopyWest", 1.9, Vector3(-1.3, trunk_h + 1.2, 0.4), mat_leaf, Vector3(0.9, 0.9, 0.9))
	_add_sphere(prop_root, "CanopyEast", 1.8, Vector3(1.2, trunk_h + 1.0, -0.6), mat_leaf_light, Vector3(0.9, 0.9, 0.9))

	# Trunk Physics Collision (Canopy is above actor height)
	_add_collision_cylinder(prop_root, trunk_r + 0.1, trunk_h, Vector3(0.0, trunk_h * 0.5, 0.0))

	return prop_root


# ============================================================================
# 7. WATCHTOWER (Backyard Fortress Observation Tower)
# ============================================================================
func _build_watchtower() -> StaticBody3D:
	var prop_root := _create_static_root("Watchtower")
	var deck_h := 3.6
	var deck_size := Vector3(4.2, 0.28, 4.2)
	var stilt_r := 0.20

	# 4 Heavy Timber Stilts
	for ox in [-1.8, 1.8]:
		for oz in [-1.8, 1.8]:
			_add_cylinder(prop_root, "Stilt", stilt_r, deck_h, Vector3(ox, deck_h * 0.5, oz), mat_wood_dark)

	# Cross-Braces between stilts
	for ox in [-1.8, 1.8]:
		_add_box(prop_root, "XBrace1", Vector3(0.12, 0.14, 3.8), Vector3(ox, deck_h * 0.5, 0.0), mat_wood)
	for oz in [-1.8, 1.8]:
		_add_box(prop_root, "XBrace2", Vector3(3.8, 0.14, 0.12), Vector3(0.0, deck_h * 0.5, oz), mat_wood)

	# Sturdy Deck Platform
	_add_box(prop_root, "Deck", deck_size, Vector3(0.0, deck_h, 0.0), mat_wood)
	_add_collision_box(prop_root, deck_size, Vector3(0.0, deck_h, 0.0))

	# Safety Railings (with front access gap)
	_add_box(prop_root, "RailingBack", Vector3(4.2, 0.9, 0.15), Vector3(0.0, deck_h + 0.45, -2.0), mat_plastic_yellow)
	_add_box(prop_root, "RailingLeft", Vector3(0.15, 0.9, 4.2), Vector3(-2.0, deck_h + 0.45, 0.0), mat_plastic_yellow)
	_add_box(prop_root, "RailingRight", Vector3(0.15, 0.9, 4.2), Vector3(2.0, deck_h + 0.45, 0.0), mat_plastic_yellow)
	_add_collision_box(prop_root, Vector3(4.2, 0.9, 0.15), Vector3(0.0, deck_h + 0.45, -2.0))
	_add_collision_box(prop_root, Vector3(0.15, 0.9, 4.2), Vector3(-2.0, deck_h + 0.45, 0.0))
	_add_collision_box(prop_root, Vector3(0.15, 0.9, 4.2), Vector3(2.0, deck_h + 0.45, 0.0))

	# Upper Roof Canopy Pillars
	var roof_h := 1.9
	for ox in [-1.9, 1.9]:
		for oz in [-1.9, 1.9]:
			_add_cylinder(prop_root, "RoofPillar", 0.12, roof_h, Vector3(ox, deck_h + roof_h * 0.5, oz), mat_wood_dark)

	# Pitched Shingle Canopy Roof
	var roof_node := MeshInstance3D.new()
	roof_node.name = "RoofCanopy"
	var prism := PrismMesh.new()
	prism.size = Vector3(4.8, 1.6, 4.8)
	roof_node.mesh = prism
	roof_node.material_override = mat_shingle
	roof_node.position = Vector3(0.0, deck_h + roof_h + 0.8, 0.0)
	prop_root.add_child(roof_node)
	_add_collision_box(prop_root, Vector3(4.8, 0.4, 4.8), Vector3(0.0, deck_h + roof_h + 0.2, 0.0))

	# Ladder Rungs
	for r in 9:
		var rung_y := float(r) * (deck_h / 9.0) + 0.2
		_add_cylinder(prop_root, "Rung", 0.06, 1.2, Vector3(0.0, rung_y, 2.05), mat_steel_dark, Vector3(0.0, 0.0, 90.0))

	return prop_root
