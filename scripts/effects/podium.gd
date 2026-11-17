class_name Podium
extends Node3D
## The end-of-match celebration: a little stage floating in the sky above the
## yard, with gold/silver/bronze steps, everyone on them wearing their hats and
## bouncing about under a shower of confetti. It owns its own camera.
##
## Each step holds one "place": a single player in solo modes, or a whole team
## (side by side) in team modes. Steps widen to fit, and the camera pulls back.

## Where the stage floats (well above the arena, so the sky is the backdrop).
const ORIGIN := Vector3(0.0, 150.0, 0.0)
const STEP_HEIGHT: Array[float] = [1.5, 1.0, 0.65]
const STEP_COLOR: Array[Color] = [Color(1.0, 0.8, 0.15), Color(0.78, 0.84, 0.95), Color(0.85, 0.5, 0.25)]
const STEP_DEPTH := 2.0
const MIN_STEP_WIDTH := 2.1
## Room for each dancer on a shared step.
const DANCER_SPACING := 1.0
const STEP_GAP := 0.3
const PLACE_TEXT: Array[String] = ["1", "2", "3"]
## The camera sits off to the right so the stage fills the left of the screen,
## leaving room for the results panel on the right. Wide team stages pull it back.
const CAMERA_DISTANCE := 10.0
## The stage may fill this share of the screen width (the rest is the results panel)…
const STAGE_SCREEN_SHARE := 0.52
## …centred this far left of the screen centre (in half-screen widths).
const STAGE_SCREEN_OFFSET := 0.4

var camera: Camera3D
var dancers: Array[CharacterModel] = []
## Which step (0 = winner) each dancer stands on.
var dancer_places: Array[int] = []
## Centre x of each step.
var step_x: Array[float] = []

var _time: float = 0.0


## `places[i]` is the list of players on step i (best first).
func show_places(places: Array, banner: String, banner_color: Color) -> void:
	top_level = true
	global_position = ORIGIN
	var widths: Array[float] = []
	for place in mini(3, places.size()):
		var members: Array = places[place]
		widths.append(maxf(MIN_STEP_WIDTH, members.size() * DANCER_SPACING + 0.3))
	_layout_steps(widths)
	_build_ground(widths)
	for place in widths.size():
		_build_step(place, widths[place])
		var members: Array = places[place]
		for k in members.size():
			var entry := members[k] as ScoreEntry
			var offset := (k - (members.size() - 1) * 0.5) * DANCER_SPACING
			_add_dancer(place, entry, step_x[place] + offset, k, members.size() > 1)
	var bounds := _stage_bounds(widths)
	var centre := (bounds.x + bounds.y) * 0.5
	var shared := false
	for place in places:
		shared = shared or (place as Array).size() > 1
	# Team name tags sit higher (they alternate heights), so the banner goes up too.
	ArenaKit.sign_text(self, banner, Vector3(centre, 6.5 if shared else 5.7, -2.5), Vector3.ZERO, banner_color, 110, 0.007)
	_add_confetti()

	camera = Camera3D.new()
	camera.fov = 48.0
	add_child(camera)
	var view := frame_stage(bounds)
	camera.position = Vector3(view.x, 1.9 + view.y * 0.1, view.y)
	camera.look_at(global_position + Vector3(view.x, 1.9, 0.0), Vector3.UP)
	camera.current = true
	Sfx.play(&"cheer", 1.0, -4.0)


## Where the camera goes (x, distance) so the stage between `bounds` (left,
## right) fills the left part of the screen, clear of the results panel on the
## right. A one-player-per-step stage gives the classic framing.
static func frame_stage(bounds: Vector2) -> Vector2:
	var half_view := tan(deg_to_rad(24.0)) * 16.0 / 9.0  # Half-width per metre of distance at 16:9.
	var distance := maxf(CAMERA_DISTANCE, (bounds.y - bounds.x) / (STAGE_SCREEN_SHARE * 2.0 * half_view))
	var centre := (bounds.x + bounds.y) * 0.5
	return Vector2(centre + STAGE_SCREEN_OFFSET * distance * half_view, distance)


func _process(delta: float) -> void:
	_time += delta
	for i in dancers.size():
		var dancer := dancers[i]
		var place := dancer_places[i]
		var beat := float(i) * 0.7
		# The winners bounce highest; everyone hops on their own beat.
		var hop := absf(sin(_time * (5.0 - place * 0.6) + beat)) * (0.45 if place == 0 else 0.25)
		dancer.position.y = STEP_HEIGHT[place] + hop
		dancer.rotation.y = PI + sin(_time * 2.2 + beat) * 0.6
		if place == 0:
			dancer.rotation.y += _time * 1.8 if fmod(_time + beat, 4.0) < 1.0 else 0.0


## Winner in the middle, second on the left, third on the right.
func _layout_steps(widths: Array[float]) -> void:
	step_x.clear()
	for place in widths.size():
		match place:
			0:
				step_x.append(0.0)
			1:
				step_x.append(-(widths[0] * 0.5 + widths[1] * 0.5 + STEP_GAP))
			_:
				step_x.append(widths[0] * 0.5 + widths[2] * 0.5 + STEP_GAP)


## The stage's left and right edges (x).
func _stage_bounds(widths: Array[float]) -> Vector2:
	var left := 0.0
	var right := 0.0
	for place in widths.size():
		left = minf(left, step_x[place] - widths[place] * 0.5)
		right = maxf(right, step_x[place] + widths[place] * 0.5)
	return Vector2(left, right)


func _build_ground(widths: Array[float]) -> void:
	var bounds := _stage_bounds(widths)
	var radius := maxf(6.0, (bounds.y - bounds.x) * 0.5 + 1.5)
	var centre := Vector3((bounds.x + bounds.y) * 0.5, 0.0, 0.0)
	var grass := ArenaKit.deco_cylinder(self, radius, 0.6, centre + Vector3(0.0, -0.3, 0.0), Color(0.36, 0.72, 0.28))
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ArenaKit.deco_cylinder(self, radius + 0.2, 0.3, centre + Vector3(0.0, -0.7, 0.0), Color(0.55, 0.37, 0.22))


func _build_step(place: int, width: float) -> void:
	var height := STEP_HEIGHT[place]
	ArenaKit.deco_box(self, Vector3(width, height, STEP_DEPTH), Vector3(step_x[place], height * 0.5, 0.0), STEP_COLOR[place])
	ArenaKit.sign_text(self, PLACE_TEXT[place], Vector3(step_x[place], height * 0.5, STEP_DEPTH * 0.5 + 0.01),
			Vector3.ZERO, Color.WHITE, 160, 0.006)


func _add_dancer(place: int, entry: ScoreEntry, x: float, slot: int, shared: bool) -> void:
	var dancer := CharacterModel.new()
	add_child(dancer)
	dancer.setup(entry.display_name, entry.color, entry.hat)
	if entry.color == ZombieMode.ZOMBIE_COLOR or entry.team == ZombieMode.ZOMBIE_TEAM:
		dancer.set_zombie(true)
	dancer.show_overhead(false)
	dancer.position = Vector3(x, STEP_HEIGHT[place], 0.0)
	dancer.rotation.y = PI
	dancers.append(dancer)
	dancer_places.append(place)
	var tag := Label3D.new()
	tag.text = "%s\n%d" % [entry.display_name.to_upper(), entry.score]
	tag.font = UiKit.font()
	tag.font_size = 40 if shared else 52
	tag.pixel_size = 0.006
	tag.outline_size = 12 if shared else 14
	tag.outline_modulate = UiKit.NAVY_DARK
	tag.modulate = entry.color.lightened(0.35)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Team-mates' names alternate heights so they don't overlap.
	var lift := 0.45 if shared and slot % 2 == 1 else 0.0
	tag.position = Vector3(x, STEP_HEIGHT[place] + 2.45 + lift, 0.0)
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
