class_name BlasterAttachments
extends RefCounted
## Procedural 3D Model Builder for Aftermarket Blaster Attachments:
## Builds authentic, stylized PBR 3D meshes for Optics, Barrels, Magazines,
## Stocks, and Internals, mounting them to the blaster model's physical sockets.

const DARK_HARDWARE := Color(0.12, 0.14, 0.20)
const MATTE_BLACK := Color(0.08, 0.09, 0.12)
const TACTICAL_TAN := Color(0.68, 0.58, 0.44)
const ORANGE_SAFETY := Color(1.0, 0.45, 0.05)
const RED_DOT_COLOR := Color(1.0, 0.15, 0.15)
const HOLO_COLOR := Color(0.15, 0.85, 1.0)
const BRASS_GOLD := Color(0.92, 0.75, 0.25)
const GLASS_TINT := Color(0.3, 0.7, 0.8, 0.45)
const TAPE_BLUE := Color(0.15, 0.45, 0.95)

static var _mat_cache: Dictionary = {}


static func _get_mat(color: Color, roughness: float = 0.5, metallic: float = 0.0, emissive: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%.2f" % [color.to_html(true), roughness, metallic, emissive]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.cull_mode = BaseMaterial3D.CULL_BACK
	if emissive > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emissive
	_mat_cache[key] = mat
	return mat


## Builds and returns the 3D attachment node hierarchy mounted at the given socket offset.
static func build_attachment(parent: Node3D, attachment_id: StringName, slot_name: StringName, blaster_id: StringName = &"") -> Node3D:
	if parent == null or attachment_id.is_empty():
		return null

	var root := Node3D.new()
	root.name = "Attachment_%s" % attachment_id
	parent.add_child(root)

	var slot := str(slot_name).to_lower()
	match slot:
		"optic":
			_build_optic(root, attachment_id, blaster_id)
		"barrel":
			_build_barrel(root, attachment_id, blaster_id)
		"spring":
			_build_spring(root, attachment_id, blaster_id)
		"magazine":
			_build_magazine(root, attachment_id, blaster_id)
		"stock":
			_build_stock(root, attachment_id, blaster_id)
		_:
			pass

	return root


# ==============================================================================
# OPTICS
# ==============================================================================
static func _build_optic(root: Node3D, id: StringName, _blaster_id: StringName) -> void:
	match id:
		&"red_dot":
			# Mounting base clamp
			ArenaKit.deco_box(root, Vector3(0.045, 0.015, 0.06), Vector3(0.0, 0.008, 0.0), DARK_HARDWARE)
			# Sight hood arch
			ArenaKit.deco_box(root, Vector3(0.008, 0.05, 0.045), Vector3(-0.022, 0.038, 0.0), MATTE_BLACK)
			ArenaKit.deco_box(root, Vector3(0.008, 0.05, 0.045), Vector3(0.022, 0.038, 0.0), MATTE_BLACK)
			ArenaKit.deco_box(root, Vector3(0.048, 0.008, 0.045), Vector3(0.0, 0.063, 0.0), MATTE_BLACK)
			# Tinted glass lens
			var glass := ArenaKit.deco_box(root, Vector3(0.036, 0.044, 0.004), Vector3(0.0, 0.038, -0.005), GLASS_TINT)
			glass.material_override = _get_mat(GLASS_TINT, 0.1, 0.0)
			# Illuminated glowing red laser pip in center of glass
			var pip := ArenaKit.deco_sphere(root, 0.004, Vector3(0.0, 0.038, 0.0), RED_DOT_COLOR)
			pip.material_override = _get_mat(RED_DOT_COLOR, 0.1, 0.0, 2.5)

		&"holo_sight":
			# Heavy duty hood base
			ArenaKit.deco_box(root, Vector3(0.055, 0.018, 0.09), Vector3(0.0, 0.01, 0.0), TACTICAL_TAN)
			# EOTech style rectangular protective shroud
			ArenaKit.deco_box(root, Vector3(0.01, 0.058, 0.075), Vector3(-0.025, 0.045, 0.0), MATTE_BLACK)
			ArenaKit.deco_box(root, Vector3(0.01, 0.058, 0.075), Vector3(0.025, 0.045, 0.0), MATTE_BLACK)
			ArenaKit.deco_box(root, Vector3(0.055, 0.01, 0.075), Vector3(0.0, 0.074, 0.0), MATTE_BLACK)
			# Side battery compartment cylinder
			ArenaKit.deco_cylinder(root, 0.012, 0.06, Vector3(0.034, 0.022, 0.0), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			# Glass holographic projection window
			var glass := ArenaKit.deco_box(root, Vector3(0.04, 0.05, 0.004), Vector3(0.0, 0.045, -0.01), GLASS_TINT)
			glass.material_override = _get_mat(GLASS_TINT, 0.1, 0.0)
			# Hollow glowing cyan holographic reticle ring + crisp center pip (clear view in ADS!)
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = 0.0095
			ring_mesh.outer_radius = 0.0125
			ring_mesh.rings = 16
			ring_mesh.ring_segments = 8
			var reticle := MeshInstance3D.new()
			reticle.mesh = ring_mesh
			reticle.position = Vector3(0.0, 0.045, 0.0)
			reticle.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			reticle.material_override = _get_mat(HOLO_COLOR, 0.1, 0.0, 3.2)
			reticle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(reticle)
			var pip := ArenaKit.deco_sphere(root, 0.0022, Vector3(0.0, 0.045, 0.0), HOLO_COLOR)
			pip.material_override = _get_mat(HOLO_COLOR, 0.1, 0.0, 3.6)

		&"marksman_scope":
			# Dual mounting rings
			ArenaKit.deco_cylinder(root, 0.024, 0.015, Vector3(0.0, 0.025, -0.04), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			ArenaKit.deco_cylinder(root, 0.024, 0.015, Vector3(0.0, 0.025, 0.04), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			ArenaKit.deco_box(root, Vector3(0.04, 0.012, 0.10), Vector3(0.0, 0.008, 0.0), DARK_HARDWARE)
			# Main scope tube
			ArenaKit.deco_cylinder(root, 0.018, 0.18, Vector3(0.0, 0.038, 0.0), MATTE_BLACK, Vector3(90.0, 0.0, 0.0))
			# Front objective bell (magnification cone)
			ArenaKit.deco_cylinder(root, 0.028, 0.045, Vector3(0.0, 0.038, -0.10), MATTE_BLACK, Vector3(90.0, 0.0, 0.0))
			# Rear ocular eyepiece bell
			ArenaKit.deco_cylinder(root, 0.024, 0.035, Vector3(0.0, 0.038, 0.095), MATTE_BLACK, Vector3(90.0, 0.0, 0.0))
			# Windage and elevation turret dials
			ArenaKit.deco_cylinder(root, 0.009, 0.016, Vector3(0.0, 0.058, 0.0), BRASS_GOLD)
			ArenaKit.deco_cylinder(root, 0.009, 0.016, Vector3(0.026, 0.038, 0.0), BRASS_GOLD, Vector3(0.0, 0.0, 90.0))
			# Front optical glass lens with high-clarity reflection
			var lens := ArenaKit.deco_cylinder(root, 0.024, 0.003, Vector3(0.0, 0.038, -0.12), GLASS_TINT, Vector3(90.0, 0.0, 0.0))
			lens.material_override = _get_mat(GLASS_TINT, 0.05, 0.1)

		_:
			# Stock iron sights: small plastic front post
			ArenaKit.deco_box(root, Vector3(0.012, 0.025, 0.015), Vector3(0.0, 0.012, 0.0), ORANGE_SAFETY)


# ==============================================================================
# BARRELS & MUZZLES
# ==============================================================================
static func _build_barrel(root: Node3D, id: StringName, _blaster_id: StringName) -> void:
	match id:
		&"rifled_extension":
			# Coupling lock ring
			ArenaKit.deco_cylinder(root, 0.026, 0.02, Vector3(0.0, 0.0, 0.01), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			# Extended guide barrel tube
			ArenaKit.deco_cylinder(root, 0.020, 0.14, Vector3(0.0, 0.0, -0.06), MATTE_BLACK, Vector3(90.0, 0.0, 0.0))
			# Orange spiral rifling crown tip
			ArenaKit.deco_cylinder(root, 0.023, 0.03, Vector3(0.0, 0.0, -0.13), ORANGE_SAFETY, Vector3(90.0, 0.0, 0.0))
			# Internal bore guide ring
			ArenaKit.deco_cylinder(root, 0.012, 0.032, Vector3(0.0, 0.0, -0.13), BRASS_GOLD, Vector3(90.0, 0.0, 0.0))

		&"mega_compensator":
			# Muzzle brake base
			ArenaKit.deco_box(root, Vector3(0.046, 0.046, 0.06), Vector3(0.0, 0.0, -0.03), DARK_HARDWARE)
			# Dual horizontal side recoil gas ports (left & right)
			for side: float in [-1.0, 1.0]:
				ArenaKit.deco_box(root, Vector3(0.01, 0.018, 0.015), Vector3(side * 0.022, 0.0, -0.022), ORANGE_SAFETY)
				ArenaKit.deco_box(root, Vector3(0.01, 0.018, 0.015), Vector3(side * 0.022, 0.0, -0.042), ORANGE_SAFETY)
			# Front blaze ring
			ArenaKit.deco_cylinder(root, 0.018, 0.012, Vector3(0.0, 0.0, -0.065), ORANGE_SAFETY, Vector3(90.0, 0.0, 0.0))

		&"whisper_shroud":
			# Thick cylindrical foam silencer can
			ArenaKit.deco_cylinder(root, 0.034, 0.16, Vector3(0.0, 0.0, -0.08), MATTE_BLACK, Vector3(90.0, 0.0, 0.0))
			# Knurled grip grooves around the suppressor body
			for z in [-0.04, -0.08, -0.12]:
				ArenaKit.deco_cylinder(root, 0.036, 0.008, Vector3(0.0, 0.0, z), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			# Safety ring at front endcap
			ArenaKit.deco_cylinder(root, 0.028, 0.01, Vector3(0.0, 0.0, -0.16), ORANGE_SAFETY, Vector3(90.0, 0.0, 0.0))

		_:
			# Stock barrel: simple safety collar
			ArenaKit.deco_cylinder(root, 0.022, 0.02, Vector3(0.0, 0.0, -0.01), ORANGE_SAFETY, Vector3(90.0, 0.0, 0.0))


# ==============================================================================
# SPRINGS & INTERNAL MECHANISMS
# ==============================================================================
static func _build_spring(root: Node3D, id: StringName, _blaster_id: StringName) -> void:
	match id:
		&"heavy_spring":
			# External reinforced plunger bracket with visible heavy spring coils
			ArenaKit.deco_box(root, Vector3(0.02, 0.035, 0.08), Vector3(0.032, 0.01, 0.0), DARK_HARDWARE)
			for i in 6:
				var z_pos := -0.025 + float(i) * 0.01
				ArenaKit.deco_cylinder(root, 0.008, 0.005, Vector3(0.034, 0.01, z_pos), BRASS_GOLD, Vector3(90.0, 0.0, 0.0))

		&"hair_trigger":
			# Polished gold match trigger sear extension
			ArenaKit.deco_box(root, Vector3(0.012, 0.03, 0.012), Vector3(0.0, -0.02, 0.0), BRASS_GOLD, Vector3(-12.0, 0.0, 0.0))

		&"sealed_breech":
			# Machined brass compression chamber sleeve
			ArenaKit.deco_cylinder(root, 0.022, 0.06, Vector3(0.0, 0.01, 0.0), BRASS_GOLD, Vector3(90.0, 0.0, 0.0))
			ArenaKit.deco_cylinder(root, 0.024, 0.008, Vector3(0.0, 0.01, 0.02), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))

		_:
			pass


# ==============================================================================
# MAGAZINES & FEED SYSTEMS
# ==============================================================================
static func _build_magazine(root: Node3D, id: StringName, _blaster_id: StringName) -> void:
	match id:
		&"extended_drum":
			# Magwell insertion neck
			ArenaKit.deco_box(root, Vector3(0.032, 0.04, 0.06), Vector3(0.0, -0.02, 0.0), DARK_HARDWARE)
			# Circular high-capacity rotary drum
			ArenaKit.deco_cylinder(root, 0.058, 0.045, Vector3(0.0, -0.08, 0.0), MATTE_BLACK, Vector3(0.0, 0.0, 90.0))
			# Transparent clear polycarbonate ammo window
			var window := ArenaKit.deco_cylinder(root, 0.042, 0.047, Vector3(0.0, -0.08, 0.0), GLASS_TINT, Vector3(0.0, 0.0, 90.0))
			window.material_override = _get_mat(GLASS_TINT, 0.2, 0.0)
			# Visible blue foam darts inside drum
			for angle in [0.0, 60.0, 120.0, 180.0, 240.0, 300.0]:
				var rad := deg_to_rad(angle)
				var pos := Vector3(0.0, -0.08 + sin(rad) * 0.035, cos(rad) * 0.035)
				ArenaKit.deco_cylinder(root, 0.006, 0.032, pos, TAPE_BLUE, Vector3(0.0, 0.0, 90.0))

		&"quick_mag":
			# First magazine
			ArenaKit.deco_box(root, Vector3(0.026, 0.12, 0.055), Vector3(-0.016, -0.06, 0.0), DARK_HARDWARE, Vector3(8.0, 0.0, 0.0))
			# Second magazine side-by-side
			ArenaKit.deco_box(root, Vector3(0.026, 0.12, 0.055), Vector3(0.016, -0.06, 0.0), DARK_HARDWARE, Vector3(8.0, 0.0, 0.0))
			# Heavy duty blue electric tape wrapping holding them together
			ArenaKit.deco_box(root, Vector3(0.062, 0.035, 0.06), Vector3(0.0, -0.05, 0.0), TAPE_BLUE, Vector3(8.0, 0.0, 0.0))
			ArenaKit.deco_box(root, Vector3(0.062, 0.025, 0.06), Vector3(0.0, -0.09, 0.0), TAPE_BLUE, Vector3(8.0, 0.0, 0.0))

		&"dart_agitator":
			# Motorized feeder housing
			ArenaKit.deco_box(root, Vector3(0.04, 0.07, 0.06), Vector3(0.0, -0.035, 0.0), MATTE_BLACK)
			# Battery compartment on side
			ArenaKit.deco_box(root, Vector3(0.018, 0.04, 0.035), Vector3(0.026, -0.035, 0.0), DARK_HARDWARE)
			# Green active LED
			var led := ArenaKit.deco_sphere(root, 0.004, Vector3(0.036, -0.02, 0.01), Color(0.2, 0.9, 0.3))
			led.material_override = _get_mat(Color(0.2, 0.9, 0.3), 0.1, 0.0, 2.0)

		_:
			# Stock straight clip
			ArenaKit.deco_box(root, Vector3(0.028, 0.08, 0.055), Vector3(0.0, -0.04, 0.0), DARK_HARDWARE, Vector3(6.0, 0.0, 0.0))


# ==============================================================================
# STOCKS & ERGONOMICS
# ==============================================================================
static func _build_stock(root: Node3D, id: StringName, _blaster_id: StringName) -> void:
	match id:
		&"skeleton_stock":
			# Buffer mount collar
			ArenaKit.deco_cylinder(root, 0.018, 0.02, Vector3(0.0, 0.0, 0.01), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			# Upper and lower tubular wire struts extending backward
			ArenaKit.deco_cylinder(root, 0.006, 0.16, Vector3(-0.014, 0.01, 0.09), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			ArenaKit.deco_cylinder(root, 0.006, 0.16, Vector3(0.014, 0.01, 0.09), DARK_HARDWARE, Vector3(90.0, 0.0, 0.0))
			ArenaKit.deco_cylinder(root, 0.006, 0.14, Vector3(0.0, -0.04, 0.09), DARK_HARDWARE, Vector3(72.0, 0.0, 0.0))
			# Textured rubber buttpad
			ArenaKit.deco_box(root, Vector3(0.038, 0.11, 0.02), Vector3(0.0, -0.015, 0.17), MATTE_BLACK)

		&"tactical_grip":
			# Front under-rail mount clamp (mounted directly at the foregrip socket)
			ArenaKit.deco_box(root, Vector3(0.038, 0.016, 0.065), Vector3(0.0, 0.0, 0.0), DARK_HARDWARE)
			# Angled foregrip with ergonomic finger ridges
			ArenaKit.deco_box(root, Vector3(0.032, 0.085, 0.036), Vector3(0.0, -0.046, -0.015), MATTE_BLACK, Vector3(22.0, 0.0, 0.0))
			for y in [-0.030, -0.050, -0.070]:
				ArenaKit.deco_box(root, Vector3(0.035, 0.008, 0.038), Vector3(0.0, y, -0.015), DARK_HARDWARE, Vector3(22.0, 0.0, 0.0))

		&"counterweight_stock":
			# Heavy polymer crane stock body
			ArenaKit.deco_box(root, Vector3(0.044, 0.07, 0.15), Vector3(0.0, -0.01, 0.09), TACTICAL_TAN)
			# Top cheek rest
			ArenaKit.deco_box(root, Vector3(0.048, 0.02, 0.12), Vector3(0.0, 0.03, 0.09), MATTE_BLACK)
			# Heavy rear battery counterweight
			ArenaKit.deco_box(root, Vector3(0.046, 0.12, 0.03), Vector3(0.0, -0.025, 0.165), DARK_HARDWARE)
			ArenaKit.deco_cylinder(root, 0.008, 0.015, Vector3(0.0, -0.05, 0.10), ORANGE_SAFETY, Vector3(0.0, 0.0, 90.0))

		_:
			pass
