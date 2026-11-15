class_name Podium
extends Node3D
## The end-of-match celebration: a little stage floating in the sky above the
## yard, with the top three on gold/silver/bronze steps, wearing their hats and
## bouncing about under a shower of confetti. It owns its own camera.

## Where the stage floats (well above the arena, so the sky is the backdrop).
const ORIGIN := Vector3(0.0, 150.0, 0.0)
const STEP_X: Array[float] = [0.0, -2.4, 2.4]
const STEP_HEIGHT: Array[float] = [1.5, 1.0, 0.65]
const STEP_COLOR: Array[Color] = [Color(1.0, 0.8, 0.15), Color(0.78, 0.84, 0.95), Color(0.85, 0.5, 0.25)]
const STEP_SIZE := Vector2(2.1, 2.0)
const PLACE_TEXT: Array[String] = ["1", "2", "3"]
## The camera sits off to the right so the stage fills the left of the screen,
## leaving room for the results panel on the right.
const CAMERA_SHIFT := 3.0

var camera: Camera3D
var dancers: Array[CharacterModel] = []

var _time: float = 0.0


func show_ranking(ranking: Array[ScoreEntry]) -> void:
	top_level = true
	global_position = ORIGIN
	_build_stage()
	for place in mini(3, ranking.size()):
		_add_dancer(place, ranking[place])
	_add_confetti()
	camera = Camera3D.new()
	camera.fov = 48.0
	add_child(camera)
	camera.position = Vector3(CAMERA_SHIFT, 2.9, 10.0)
	camera.look_at(global_position + Vector3(CAMERA_SHIFT, 1.9, 0.0), Vector3.UP)
	camera.current = true
	Sfx.play(&"cheer", 1.0, -4.0)


func _process(delta: float) -> void:
	_time += delta
	for place in dancers.size():
		var dancer := dancers[place]
		var base_y := STEP_HEIGHT[place]
		# The winner bounces highest; everyone hops on their own beat.
		var hop := absf(sin(_time * (5.0 - place * 0.6) + place)) * (0.45 if place == 0 else 0.25)
		dancer.position.y = base_y + hop
		dancer.rotation.y = PI + sin(_time * 2.2 + place) * 0.6
		if place == 0:
			dancer.rotation.y += _time * 1.8 if fmod(_time, 4.0) < 1.0 else 0.0


func _build_stage() -> void:
	var grass := ArenaKit.deco_cylinder(self, 6.0, 0.6, Vector3(0.0, -0.3, 0.0), Color(0.36, 0.72, 0.28))
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ArenaKit.deco_cylinder(self, 6.2, 0.3, Vector3(0.0, -0.7, 0.0), Color(0.55, 0.37, 0.22))
	for place in 3:
		var height := STEP_HEIGHT[place]
		ArenaKit.deco_box(self, Vector3(STEP_SIZE.x, height, STEP_SIZE.y),
				Vector3(STEP_X[place], height * 0.5, 0.0), STEP_COLOR[place])
		ArenaKit.sign_text(self, PLACE_TEXT[place], Vector3(STEP_X[place], height * 0.5, STEP_SIZE.y * 0.5 + 0.01),
				Vector3.ZERO, Color.WHITE, 160, 0.006)
	ArenaKit.sign_text(self, "DARTSTORM\nCHAMPIONS", Vector3(0.0, 5.7, -2.5), Vector3.ZERO, UiKit.ORANGE_HOT, 110, 0.007)


func _add_dancer(place: int, entry: ScoreEntry) -> void:
	var dancer := CharacterModel.new()
	add_child(dancer)
	dancer.setup(entry.display_name, entry.color, entry.hat)
	dancer.show_overhead(false)
	dancer.position = Vector3(STEP_X[place], STEP_HEIGHT[place], 0.0)
	dancer.rotation.y = PI
	dancers.append(dancer)
	var tag := Label3D.new()
	tag.text = "%s\n%d" % [entry.display_name.to_upper(), entry.score]
	tag.font = UiKit.font()
	tag.font_size = 52
	tag.pixel_size = 0.006
	tag.outline_size = 14
	tag.outline_modulate = UiKit.NAVY_DARK
	tag.modulate = entry.color.lightened(0.35)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(STEP_X[place], STEP_HEIGHT[place] + 2.45, 0.0)
	add_child(tag)


func _add_confetti() -> void:
	var amount := int(clampf(140.0 * GameSettings.visual_intensity, 20.0, 220.0))
	var confetti := CPUParticles3D.new()
	confetti.amount = amount
	confetti.lifetime = 3.0
	confetti.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	confetti.emission_box_extents = Vector3(5.0, 0.2, 2.5)
	confetti.position = Vector3(0.0, 6.5, 0.0)
	confetti.direction = Vector3.DOWN
	confetti.spread = 25.0
	confetti.gravity = Vector3(0.0, -2.5, 0.0)
	confetti.initial_velocity_min = 0.5
	confetti.initial_velocity_max = 1.5
	confetti.angular_velocity_min = -300.0
	confetti.angular_velocity_max = 300.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.02, 0.08)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = material
	confetti.mesh = mesh
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	colors.colors = PackedColorArray([UiKit.ORANGE, UiKit.SKY, UiKit.LIME, UiKit.PINK, Color(1.0, 0.85, 0.2)])
	confetti.color_initial_ramp = colors
	confetti.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(confetti)
	confetti.emitting = true
