class_name MainMenu
extends Node3D
## The lobby, laid out like the young players' own drawing of DARTSTORM's home
## screen (GDD §3.21): you stand on a round platform in the middle of a
## floating island, with your squad on platforms around you and the backyard
## battlefield behind. Your player card is top left with a column of buttons
## under it, the mode picker is top right, the DARTSTORM logo is bottom middle
## and a big PLAY button is bottom right. Fully usable with a controller.

const MATCH_SCENE := "res://scenes/game/match.tscn"
const ARENA_SCENE := preload("res://scenes/arenas/backyard_fortress.tscn")
const DIFFICULTY_NAMES := ["EASY", "NORMAL", "HARD"]
## Mode cards, in the order shown (GameSettings.MatchMode values).
const MODE_ORDER: Array[int] = [
	GameSettings.MatchMode.FREE_FOR_ALL,
	GameSettings.MatchMode.DUOS,
	GameSettings.MatchMode.TEAMS,
	GameSettings.MatchMode.GUN_GAME,
	GameSettings.MatchMode.ZOMBIES,
	GameSettings.MatchMode.ZOMBIE_SIEGE,
	GameSettings.MatchMode.FLOOR_IS_LAVA,
	GameSettings.MatchMode.REALISTIC,
	GameSettings.MatchMode.CAPTURE_THE_FLAG,
	GameSettings.MatchMode.PLANT_THE_BOMB,
]
## The lobby island floats just south of the yard, so the backyard fills the background.
const STAGE := Vector3(0.0, 9.0, 38.0)
## Where your squad stands (relative to the island), nearest spots first.
## Back rows stand higher, like a team photo, so nobody hides behind anyone.
const SQUAD_SPOTS: Array[Vector3] = [
	Vector3(-2.0, 0.0, -0.5), Vector3(2.0, 0.0, -0.5),
	Vector3(-3.3, 0.45, -2.3), Vector3(3.3, 0.45, -2.3),
	Vector3(-1.1, 0.9, -3.7), Vector3(1.1, 0.9, -3.7),
	Vector3(-3.9, 1.3, -5.0), Vector3(3.9, 1.3, -5.0),
]
const PLAYER_SPOT := Vector3(0.0, 0.0, 0.7)
## Camera poses: the whole squad, or a close-up of you while customising.
## The lobby camera sits a little right so the squad fills the gap between the
## button column on the left and the mode picker on the right.
const CAMERA_LOBBY := Vector3(1.0, 3.9, 10.6)
const LOOK_LOBBY := Vector3(1.0, 1.1, -1.6)
const CAMERA_CLOSE := Vector3(-1.45, 1.9, 4.6)
const LOOK_CLOSE := Vector3(-1.45, 1.15, 0.0)
const BLASTERS := [
	"res://resources/weapons/dart_sprayer.tres",
	"res://resources/weapons/pocket_popper.tres",
	"res://resources/weapons/flaxs_chainstorm.tres",
]
const ALL_WEAPONS: Array[String] = [
	"res://resources/weapons/pocket_popper.tres",
	"res://resources/weapons/dart_sprayer.tres",
	"res://resources/weapons/flaxs_chainstorm.tres",
	"res://resources/weapons/double_trouble.tres",
	"res://resources/weapons/foam_hammer.tres",
	"res://resources/weapons/longshot.tres",
	"res://resources/weapons/thunder_cannon.tres",
	"res://resources/weapons/frost_ranger.tres",
	"res://resources/weapons/hydro_soaker.tres",
	"res://resources/weapons/ricochet_ranger.tres",
	"res://resources/weapons/wind_whisperer.tres",
]
const KEYBOARD_HELP := [
	"Move: W A S D     Look: Mouse     ADS: Right click",
	"Jump: Space     Sprint: Shift     Grenade: G",
	"Fire: Left click     Reload: R     Inspect: V",
	"Interact / Plant / Defuse / Repair: F or E",
	"Blasters: 1 2 3 4 or wheel     Score: Tab     Pause: Esc",
]
const CONTROLLER_HELP := [
	"Move: Left stick     Look: Right stick     ADS: LT",
	"Jump: A     Sprint: Click left stick     Grenade: LB",
	"Fire: RT     Reload: X     Inspect: D-Pad Left",
	"Interact / Plant / Defuse / Repair: D-Pad Right",
	"Blasters: Y or RB     Score: Back     Pause: Start",
]
const HOW_TO_PLAY := [
	"",
	"Tag your rivals with foam darts!",
	"Darts drop, curve in the wind and",
	"bounce off the shiny mirror panels.",
	"Stand by a bucket to refill ammo.",
	"In DUOS and TEAMS your darts fly",
	"straight through your friends.",
]

## Your character in the middle of the island (also the customise preview).
var player_model: CharacterModel
## Everyone else on the island, in the colours they'll wear in the match.
var squad: Array[CharacterModel] = []

var _backdrop_arena: Arena
var _stage: Node3D
var _squad_root: Node3D
var _camera: Camera3D
var _camera_tween: Tween
var _ui: Control
var _menu: Control
var _settings: SettingsPanel
var _missions: MissionsPanel
var _shop: ShopPanel
var _multiplayer_menu: MultiplayerMenu
var _workbench: GarageWorkbench
var _workbench_panel: WorkbenchPanel
var _customise: PanelContainer
var _preview_weapon_index: int = 0
var _weapon_inspect_label: Label
var _customise_profile: int = 0
var _profile_tab_p1: Button
var _profile_tab_p2: Button
var _is_dragging_model: bool = false
var _model_angle: float = PI
var _customise_pitch: float = 0.0
var _customise_fov: float = 44.0
var _turntable_auto: bool = true
var _turntable_btn: Button
var _reset_view_btn: Button
var _inspect_light: OmniLight3D
var _help: PanelContainer
var _help_box: VBoxContainer
var _bunker_label: Label
var _card_name: Label
var _level_badge: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _coins_label: Label
var _mode_buttons: Array[Button] = []
var _mode_blurb: Label
var _bots_value: Label
var _teams_info: Label
var _players_button: Button
var _difficulty_button: Button
var _arena_button: Button
var _storm_row: HBoxContainer
var _storm_button: Button
var _name_edit: LineEdit
var _swatches: Array[Button] = []
var _hat_buttons: Array[Button] = []
var _skin_buttons: Array[Button] = []
var _play_button: Button
var _play_mode_label: Label
var _bolts: Array[Node3D] = []
## Height each squad member stands at (their platform top).
var _squad_floor: Array[float] = []
var _slots: Array[Node3D] = []
var _time: float = 0.0


func _ready() -> void:
	var all_args: PackedStringArray = OS.get_cmdline_args()
	all_args.append_array(OS.get_cmdline_user_args())
	for arg in all_args:
		if arg == "--server" or arg.begins_with("--server="):
			get_tree().change_scene_to_file.call_deferred("res://scenes/server/server.tscn")
			return

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_swap_backdrop_arena(GameSettings.arena)
	_build_island()

	_camera = Camera3D.new()
	_camera.fov = 50.0
	_camera.current = true
	# Soft focus on the yard far behind, so the squad stands out like on a poster.
	var focus := CameraAttributesPractical.new()
	focus.dof_blur_far_enabled = true
	focus.dof_blur_far_distance = 26.0
	focus.dof_blur_far_transition = 14.0
	focus.dof_blur_amount = 0.06
	_camera.attributes = focus
	add_child(_camera)
	_place_camera(CAMERA_LOBBY, LOOK_LOBBY)

	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	_build_menu()
	_build_help()
	_build_customise()

	_settings = SettingsPanel.new()
	_settings.visible = false
	_ui.add_child(_settings)
	UiKit.pin(_settings, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_settings.closed.connect(_show_settings.bind(false))

	_missions = MissionsPanel.new()
	_missions.visible = false
	_ui.add_child(_missions)
	UiKit.pin(_missions, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_missions.closed.connect(_show_missions.bind(false))

	_shop = ShopPanel.new()
	_shop.visible = false
	_ui.add_child(_shop)
	UiKit.pin(_shop, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_shop.closed.connect(_show_shop.bind(false))
	_shop.item_equipped.connect(func(_cat: Variant, _id: Variant) -> void:
		_rebuild_squad()
		_refresh_card()
		_refresh_customise())

	_multiplayer_menu = MultiplayerMenu.new()
	_multiplayer_menu.visible = false
	_ui.add_child(_multiplayer_menu)
	UiKit.pin(_multiplayer_menu, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_multiplayer_menu.closed.connect(_show_multiplayer.bind(false))

	_workbench = GarageWorkbench.new()
	_workbench.visible = false
	_workbench.position = Vector3(120.0, 0.0, 0.0)
	add_child(_workbench)

	_workbench_panel = WorkbenchPanel.new()
	_workbench_panel.visible = false
	_ui.add_child(_workbench_panel)
	_workbench_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workbench_panel.closed.connect(_show_workbench.bind(false))
	_workbench_panel.blaster_selected.connect(func(w_id: StringName) -> void:
		if _workbench != null:
			_workbench.load_blaster(w_id)
	)
	_workbench_panel.attachment_changed.connect(func(_slot: Variant, _att_id: Variant) -> void:
		if _workbench != null and is_instance_valid(Progression):
			var cur_atts := Progression.get_equipped_attachments(_workbench.active_blaster_id)
			_workbench.update_attachments(cur_atts)
	)
	_workbench_panel.slot_focused.connect(func(slot: Variant) -> void:
		if _workbench != null:
			_workbench.focus_slot(slot)
	)
	_workbench_panel.test_fire_requested.connect(func() -> void:
		if _workbench != null:
			_workbench.test_fire()
	)
	_workbench_panel.orbit_requested.connect(func(delta: Vector2) -> void:
		if _workbench != null:
			_workbench.rotate_orbit(delta)
	)
	_workbench_panel.zoom_requested.connect(func(delta: float) -> void:
		if _workbench != null:
			_workbench.zoom_orbit(delta)
	)
	_workbench_panel.reset_view_requested.connect(func() -> void:
		if _workbench != null:
			_workbench.reset_camera_view()
	)

	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null:
		prog.connect("xp_gained", func(_a: Variant, _t: Variant) -> void: _refresh_card())
		prog.connect("level_up", func(_l: Variant) -> void: _refresh_card())
		prog.connect("coins_changed", func(_c: Variant) -> void: _refresh_card())

	_rebuild_squad()
	GameSettings.input_device_changed.connect(func(_pad: bool) -> void: _refresh_help())
	Sfx.play_music(&"menu")

	var demo_args := OS.get_cmdline_user_args()
	if demo_args.has("--demo"):
		add_child(DemoDriver.new())
		if demo_args.has("--open-customise"):
			_show_customise(true)


func _process(delta: float) -> void:
	_time += delta
	if player_model != null:
		if _customise != null and _customise.visible:
			if _turntable_auto and not _is_dragging_model:
				_model_angle = fmod(_model_angle + delta * 0.45, TAU)
			player_model.rotation.y = _model_angle
		else:
			player_model.rotation.y = PI + sin(_time * 0.8) * 0.3
		player_model.position.y = PLAYER_SPOT.y + 0.32 + absf(sin(_time * 1.6)) * 0.04
	for i in squad.size():
		var member := squad[i]
		member.rotation.y = PI + sin(_time * 0.7 + i * 1.3) * 0.35
		# Now and then someone does a happy little hop.
		var hop := maxf(sin(_time * 1.1 + i * 2.1) - 0.93, 0.0) * 4.0
		member.position.y = _squad_floor[i] + hop
	for i in _bolts.size():
		_bolts[i].scale = Vector3.ONE * (1.0 + sin(_time * 5.0 + i * 2.0) * 0.06)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_is_dragging_model = false
	if _customise != null and _customise.visible and _is_dragging_model:
		if event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			_model_angle = fmod(_model_angle + mm.relative.x * 0.012, TAU)
			if player_model != null:
				player_model.rotation.y = _model_angle
			_customise_pitch = clampf(_customise_pitch - mm.relative.y * 0.004, -0.38, 0.38)
			_update_customise_camera()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _customise != null and _customise.visible and player_model != null:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_is_dragging_model = true
					if _turntable_auto:
						_turntable_auto = false
						if _turntable_btn != null:
							_turntable_btn.text = "PAUSE"
					if mb.double_click:
						_reset_customise_view()
					get_viewport().set_input_as_handled()
				else:
					_is_dragging_model = false
			elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				_reset_customise_view()
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				_zoom_customise(-2.5)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				_zoom_customise(2.5)
				get_viewport().set_input_as_handled()
		elif event is InputEventScreenDrag and not _is_dragging_model:
			var sd := event as InputEventScreenDrag
			_model_angle = fmod(_model_angle + sd.relative.x * 0.012, TAU)
			player_model.rotation.y = _model_angle
			_customise_pitch = clampf(_customise_pitch - sd.relative.y * 0.004, -0.38, 0.38)
			_update_customise_camera()
			get_viewport().set_input_as_handled()

	if not event.is_action_pressed(&"ui_cancel"):
		return
	if _workbench_panel != null and _workbench_panel.visible:
		_show_workbench(false)
		get_viewport().set_input_as_handled()
	elif _multiplayer_menu != null and _multiplayer_menu.visible:
		_multiplayer_menu.close()
		get_viewport().set_input_as_handled()
	elif _missions != null and _missions.visible:
		_show_missions(false)
		get_viewport().set_input_as_handled()
	elif _shop != null and _shop.visible:
		_show_shop(false)
		get_viewport().set_input_as_handled()
	elif _customise != null and _customise.visible:
		_show_customise(false)
		get_viewport().set_input_as_handled()
	elif _help != null and _help.visible:
		_show_help(false)
		get_viewport().set_input_as_handled()
	elif _settings != null and _settings.visible:
		_show_settings(false)
		get_viewport().set_input_as_handled()


func _swap_backdrop_arena(arena_idx: int) -> void:
	if _backdrop_arena != null and is_instance_valid(_backdrop_arena):
		_backdrop_arena.queue_free()
		_backdrop_arena = null
	var idx := clampi(arena_idx, 0, MatchScene.ARENAS.size() - 1)
	var scene_path: String = MatchScene.ARENAS[idx]["path"]
	var packed: PackedScene = load(scene_path) as PackedScene if ResourceLoader.exists(scene_path) else ARENA_SCENE
	if packed == null:
		packed = ARENA_SCENE
	_backdrop_arena = packed.instantiate() as Arena
	if _backdrop_arena != null:
		_backdrop_arena.bake_navigation = false
		add_child(_backdrop_arena)
		move_child(_backdrop_arena, 0)


# --- The island (3D) ---------------------------------------------------------------

func _build_island() -> void:
	_stage = Node3D.new()
	_stage.name = "Lobby"
	add_child(_stage)
	_stage.position = STAGE
	var grass := ArenaKit.deco_cylinder(_stage, 7.6, 0.5, Vector3(0.0, -0.25, -1.6), Color(0.36, 0.72, 0.28))
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lawn_mat := ShaderMaterial.new()
	lawn_mat.shader = load("res://assets/materials/lawn.gdshader") as Shader
	grass.material_override = lawn_mat
	ArenaKit.deco_cylinder(_stage, 2.4, 4.2, Vector3(0.0, -2.6, -1.6), Color(0.55, 0.37, 0.22), Vector3.ZERO, 7.4)
	ArenaKit.deco_cylinder(_stage, 0.9, 1.6, Vector3(0.0, -5.5, -1.6), Color(0.45, 0.3, 0.18), Vector3.ZERO, 2.3)
	for rock: Vector3 in [Vector3(-8.5, -1.5, 0.5), Vector3(8.8, -0.8, -2.5), Vector3(-6.5, -3.5, -5.0)]:
		ArenaKit.deco_sphere(_stage, 0.7, rock, Color(0.5, 0.42, 0.36), 0.7)
	# Your platform: bigger, with a gold ring.
	ArenaKit.deco_cylinder(_stage, 1.15, 0.3, PLAYER_SPOT + Vector3(0.0, 0.15, 0.0), Color(0.93, 0.93, 0.98))
	var ring := ArenaKit.deco_cylinder(_stage, 1.25, 0.12, PLAYER_SPOT + Vector3(0.0, 0.08, 0.0), Color(1.0, 0.8, 0.15))
	ring.material_override = ArenaKit.mat(Color(1.0, 0.8, 0.15), 0.5, 0.0, 0.6)
	# Yellow lightning bolts crackling over the squad, straight from the drawing.
	_bolts.append(_lightning_bolt(Vector3(-2.5, 4.9, -3.0), -14.0))
	_bolts.append(_lightning_bolt(Vector3(4.2, 4.6, -3.0), 12.0))
	# Studio inspect light for character/blaster customize inspection
	_inspect_light = OmniLight3D.new()
	_inspect_light.position = PLAYER_SPOT + Vector3(-0.6, 1.8, 1.6)
	_inspect_light.light_color = Color(1.0, 0.96, 0.9)
	_inspect_light.light_energy = 0.0
	_inspect_light.omni_range = 6.0
	_inspect_light.omni_attenuation = 0.8
	_stage.add_child(_inspect_light)
	_squad_root = Node3D.new()
	_stage.add_child(_squad_root)


func _lightning_bolt(at: Vector3, tilt: float) -> Node3D:
	var bolt := Node3D.new()
	_stage.add_child(bolt)
	bolt.position = at
	bolt.rotation_degrees.z = tilt
	var yellow := Color(1.0, 0.86, 0.15)
	ArenaKit.deco_box(bolt, Vector3(0.16, 0.8, 0.12), Vector3(0.12, 0.45, 0.0), yellow, Vector3(0.0, 0.0, -28.0), 1.2)
	ArenaKit.deco_box(bolt, Vector3(0.6, 0.14, 0.12), Vector3(0.0, 0.05, 0.0), yellow, Vector3(0.0, 0.0, 10.0), 1.2)
	ArenaKit.deco_box(bolt, Vector3(0.16, 0.8, 0.12), Vector3(-0.12, -0.35, 0.0), yellow, Vector3(0.0, 0.0, -28.0), 1.2)
	return bolt


## Rebuilds everyone on the island for the selected mode and bot count: team
## colours in DUOS and TEAMS (your team-mates nearest you), your own colour
## while you're customising.
func _rebuild_squad() -> void:
	for child in _squad_root.get_children():
		child.queue_free()
	squad.clear()
	_slots.clear()
	_squad_floor.clear()
	var mode := MatchScene.resolve_mode(GameSettings.match_mode)
	var teams := mode.is_team_mode()
	var my_team := mode.team_for(0)
	var my_color := GameMode.team_color(my_team) if teams and not _customise.visible else GameSettings.color()

	player_model = CharacterModel.new()
	_squad_root.add_child(player_model)
	player_model.setup(GameSettings.display_name(), my_color, GameSettings.player_hat)
	player_model.show_overhead(false)
	player_model.position = PLAYER_SPOT + Vector3(0.0, 0.32, 0.0)
	player_model.rotation.y = PI
	player_model.set_weapon(load(BLASTERS[2]) as WeaponData, GameSettings.player_skin)

	var count := MatchScene.team_bot_count(mode, GameSettings.bot_count)
	var colors := MatchScene.bot_colors(GameSettings.color(), count, GameSettings.color_p2() if GameSettings.split_screen else Color.TRANSPARENT)
	var spot_offset := 0
	if GameSettings.split_screen and not SQUAD_SPOTS.is_empty():
		spot_offset = 1
		var p2_team := mode.team_for(1)
		var p2_color: Color = GameMode.team_color(p2_team) if teams and not _customise.visible else GameSettings.color_p2()
		_add_squad_member(GameSettings.display_name_p2(), p2_color, GameSettings.player2_hat, SQUAD_SPOTS[0], 0)

	var bot_offset := 2 if GameSettings.split_screen else 1
	# Team-mates first, so they stand right beside you.
	var order: Array[int] = []
	for i in count:
		if mode.team_for(i + bot_offset) == my_team:
			order.append(i)
	for i in count:
		if not order.has(i):
			order.append(i)
	for slot in mini(order.size(), SQUAD_SPOTS.size() - spot_offset):
		var i := order[slot]
		var team := mode.team_for(i + bot_offset)
		var tint: Color = GameMode.team_color(team) if teams else colors[i]
		var member := _add_squad_member(MatchScene.BOT_ROSTER[i]["name"], tint, MatchScene.BOT_ROSTER[i]["hat"], SQUAD_SPOTS[slot + spot_offset], i)
		if mode is ZombieMode and i == count - 1:
			member.set_zombie(true)
	_show_squad(not _customise.visible)


func _add_squad_member(member_name: String, tint: Color, hat: StringName, spot: Vector3, index: int) -> CharacterModel:
	# Everything for one member lives under one node, so they can be hidden together.
	var slot := Node3D.new()
	_squad_root.add_child(slot)
	_slots.append(slot)
	# A floating platform; raised ones get a little stalk underneath.
	var top := spot.y + 0.25
	ArenaKit.deco_cylinder(slot, 0.78, 0.25, spot + Vector3(0.0, 0.125, 0.0), Color(0.93, 0.93, 0.98))
	var ring := ArenaKit.deco_cylinder(slot, 0.86, 0.1, spot + Vector3(0.0, 0.05, 0.0), tint)
	ring.material_override = ArenaKit.mat(tint, 0.5, 0.0, 0.5)
	if spot.y > 0.0:
		ArenaKit.deco_cylinder(slot, 0.18, spot.y, Vector3(spot.x, spot.y * 0.5, spot.z), Color(0.8, 0.82, 0.9))
	var model := CharacterModel.new()
	slot.add_child(model)
	model.setup(member_name, tint, hat)
	model.show_overhead(false)
	model.position = Vector3(spot.x, top, spot.z)
	model.rotation.y = PI
	model.set_weapon(load(BLASTERS[index % 2]) as WeaponData)
	squad.append(model)
	_squad_floor.append(top)
	# A name tag over each head, like the speech bubbles in the drawing.
	var bubble := Label3D.new()
	bubble.text = member_name.to_upper()
	bubble.font = UiKit.font()
	bubble.font_size = 44
	bubble.pixel_size = 0.0062
	bubble.modulate = tint.lightened(0.4)
	bubble.outline_size = 14
	bubble.outline_modulate = UiKit.NAVY_DARK
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Write depth, or the background blur treats the text as far away and smears it.
	bubble.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	bubble.position = Vector3(spot.x, top + 2.4, spot.z)
	slot.add_child(bubble)
	return model


## Shows or hides everyone but you (they step aside while you customise).
func _show_squad(shown: bool) -> void:
	for slot in _slots:
		slot.visible = shown


func _place_camera(offset: Vector3, look: Vector3) -> void:
	_camera.position = STAGE + offset
	_camera.look_at(STAGE + look, Vector3.UP)


func _move_camera(offset: Vector3, look: Vector3) -> void:
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	var target := Transform3D(Basis.IDENTITY, STAGE + offset).looking_at(STAGE + look, Vector3.UP)
	_camera_tween = create_tween()
	_camera_tween.tween_property(_camera, "global_transform", target, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _reset_customise_view(update_cam: bool = true) -> void:
	_model_angle = PI
	_customise_pitch = 0.0
	_customise_fov = 44.0
	_is_dragging_model = false
	if player_model != null:
		player_model.rotation.y = _model_angle
	if update_cam:
		_update_customise_camera()


func _zoom_customise(amount: float) -> void:
	_customise_fov = clampf(_customise_fov + amount, 18.0, 52.0)
	_update_customise_camera()


func _update_customise_camera() -> void:
	if _camera == null:
		return
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera.fov = _customise_fov
	var zoom_t := inverse_lerp(52.0, 18.0, _customise_fov)
	var look_y := lerpf(LOOK_CLOSE.y, LOOK_CLOSE.y + 0.48, zoom_t) + _customise_pitch
	var cam_y := lerpf(CAMERA_CLOSE.y, CAMERA_CLOSE.y + 0.22, zoom_t) + _customise_pitch * 0.5
	_camera.position = STAGE + Vector3(CAMERA_CLOSE.x, cam_y, CAMERA_CLOSE.z)
	_camera.look_at(STAGE + Vector3(LOOK_CLOSE.x, look_y, LOOK_CLOSE.z), Vector3.UP)


# --- The lobby screen (2D) ------------------------------------------------------------

func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_menu)
	_build_player_card()
	_build_mode_picker()
	_build_logo()

	_refresh_options()
	_play_button.grab_focus()


## Top left: "<NAME>'S BUNKER", Level, XP Bar, Coins and a column of buttons.
func _build_player_card() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_menu.add_child(column)
	UiKit.pin(column, Vector2(0.0, 0.0), Vector2(28, 20), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_END)
	var card := UiKit.panel(UiKit.NAVY, 0.9, 18, 4, UiKit.ORANGE, 12)
	column.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 3)
	card.add_child(card_box)

	_bunker_label = UiKit.label("", 26, UiKit.ORANGE_HOT, 8)
	card_box.add_child(_bunker_label)

	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 8)
	card_box.add_child(sub_row)

	_card_name = UiKit.label("", 20, UiKit.CREAM, 6)
	_card_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_row.add_child(_card_name)

	_level_badge = UiKit.label("LVL 1", 20, UiKit.ORANGE_HOT, 6)
	sub_row.add_child(_level_badge)

	# XP Progress Bar & Counter
	var xp_box := VBoxContainer.new()
	xp_box.add_theme_constant_override("separation", 2)
	card_box.add_child(xp_box)

	_xp_bar = UiKit.bar(UiKit.SKY, Vector2(230, 12))
	xp_box.add_child(_xp_bar)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 6)
	xp_box.add_child(xp_row)

	_xp_label = UiKit.label("0 / 100 XP", 14, UiKit.CREAM, 4)
	_xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_row.add_child(_xp_label)

	_coins_label = UiKit.label("250 COINS", 16, UiKit.ORANGE_HOT, 5)
	xp_row.add_child(_coins_label)

	for entry: Array in [
		["ONLINE MULTIPLAYER", _show_multiplayer.bind(true)],
		["WORKBENCH", _show_workbench.bind(true)],
		["MISSIONS", _show_missions.bind(true)],
		["SHOP", _show_shop.bind(true)],
		["CHARACTER", _show_customise.bind(true)],
		["HOW TO PLAY", _show_help.bind(true)],
		["SETTINGS", _show_settings.bind(true)],
		["QUIT", func() -> void: Sfx.quit_game()]
	]:
		var button := UiKit.small_button(entry[0], Vector2(230, 42))
		button.name = String(entry[0]).replace(" ", "")
		button.pressed.connect(entry[1])
		column.add_child(button)
	_refresh_card()


## Top right: the mode cards, match options, and PLAY button in a unified vertical column.
func _build_mode_picker() -> void:
	var right_col := VBoxContainer.new()
	right_col.name = "RightCol"
	right_col.add_theme_constant_override("separation", 6)
	_menu.add_child(right_col)
	UiKit.pin(right_col, Vector2(1.0, 0.0), Vector2(-28, 16), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_END)

	var panel := UiKit.panel(UiKit.NAVY, 0.9, 14, 3, UiKit.SKY, 10)
	right_col.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UiKit.label("PICK A MODE", 20, UiKit.SKY, 5))
	var cards := GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 4)
	box.add_child(cards)
	for mode_index in MODE_ORDER:
		var mode := MatchScene.resolve_mode(mode_index)
		var card := UiKit.small_button(mode.short_name, Vector2(170, 34))
		card.add_theme_font_size_override("font_size", 18)
		card.name = mode.short_name.replace(" ", "")
		card.pressed.connect(_pick_mode.bind(mode_index))
		cards.add_child(card)
		_mode_buttons.append(card)
	_mode_blurb = UiKit.label("", 14, UiKit.CREAM, 3)
	_mode_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_blurb.custom_minimum_size = Vector2(346, 32)
	box.add_child(_mode_blurb)

	var bots_row := _option_row(box, "BOTS")
	var fewer := UiKit.small_button("-", Vector2(40, 30))
	fewer.add_theme_font_size_override("font_size", 18)
	fewer.pressed.connect(_change_bots.bind(-1))
	bots_row.add_child(fewer)
	_bots_value = UiKit.label("", 22, UiKit.ORANGE_HOT)
	_bots_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bots_value.custom_minimum_size.x = 44
	bots_row.add_child(_bots_value)
	var more := UiKit.small_button("+", Vector2(40, 30))
	more.add_theme_font_size_override("font_size", 18)
	more.pressed.connect(_change_bots.bind(1))
	bots_row.add_child(more)
	_teams_info = UiKit.label("", 14, UiKit.SKY, 3)
	box.add_child(_teams_info)

	var players_row := _option_row(box, "PLAYERS")
	_players_button = UiKit.small_button("", Vector2(210, 30))
	_players_button.add_theme_font_size_override("font_size", 15)
	_players_button.tooltip_text = "1 PLAYER: Solo against bots.\n2 PLAYERS: Local Couch Co-Op split-screen (Keyboard + Pad, or dual Gamepads)!"
	_players_button.pressed.connect(_toggle_players)
	players_row.add_child(_players_button)

	var arena_row := _option_row(box, "ARENA")
	var prev_arena := UiKit.small_button("<", Vector2(32, 30))
	prev_arena.add_theme_font_size_override("font_size", 16)
	prev_arena.pressed.connect(_cycle_arena.bind(-1))
	arena_row.add_child(prev_arena)
	_arena_button = UiKit.small_button("", Vector2(142, 30))
	_arena_button.add_theme_font_size_override("font_size", 14)
	_arena_button.tooltip_text = "9 Arenas: Backyard Fortress, Home Turf, Tempest Treehouse, Sunny Park, Playground, Soccer Stadium (Twilight), Two Fortresses, Dusty Courtyard (de_dust), Duststorm II (de_dust2)."
	_arena_button.pressed.connect(_cycle_arena.bind(1))
	arena_row.add_child(_arena_button)
	var next_arena := UiKit.small_button(">", Vector2(32, 30))
	next_arena.add_theme_font_size_override("font_size", 16)
	next_arena.pressed.connect(_cycle_arena.bind(1))
	arena_row.add_child(next_arena)

	var difficulty_row := _option_row(box, "BOT SKILL")
	_difficulty_button = UiKit.small_button("", Vector2(210, 30))
	_difficulty_button.add_theme_font_size_override("font_size", 15)
	_difficulty_button.pressed.connect(_cycle_difficulty)
	difficulty_row.add_child(_difficulty_button)

	_storm_row = _option_row(box, "CHAINSTORM")
	_storm_button = UiKit.small_button("", Vector2(210, 30))
	_storm_button.add_theme_font_size_override("font_size", 15)
	_storm_button.tooltip_text = "EVERYONE: all players start with it.\nPOWER-UP: it lands on the treehouse; grab it first!"
	_storm_button.pressed.connect(_toggle_storm)
	_storm_row.add_child(_storm_button)

	# Bottom of column: PLAY button
	var play_box := VBoxContainer.new()
	play_box.add_theme_constant_override("separation", 3)
	right_col.add_child(play_box)
	_play_mode_label = UiKit.label("", 16, UiKit.CREAM, 4)
	_play_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_box.add_child(_play_mode_label)
	_play_button = UiKit.button("PLAY", 50, Vector2(366, 68))
	_play_button.add_theme_constant_override("outline_size", 10)
	_play_button.pressed.connect(_play)
	play_box.add_child(_play_button)


## Bottom middle: the DARTSTORM logo with blue swooshes.
func _build_logo() -> void:
	var logo := HBoxContainer.new()
	logo.add_theme_constant_override("separation", 6)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(logo)
	UiKit.pin(logo, Vector2(0.4, 1.0), Vector2(0, -20), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -14)
	logo.add_child(words)
	words.add_child(UiKit.label("DARTSTORM", 80, UiKit.ORANGE_HOT, 18))
	var sub := UiKit.label("ELEMENTAL ARENA", 28, UiKit.SKY, 9)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(sub)
	logo.add_child(Swoosh.new())

	# Clean 1.0 release version badge in bottom-left corner
	var ver_str := str(ProjectSettings.get_setting("application/config/version", "2.0.0"))
	var ver_lbl := UiKit.label("v%s" % ver_str, 15, Color(UiKit.SKY, 0.85), 4)
	_menu.add_child(ver_lbl)
	UiKit.pin(ver_lbl, Vector2(0.0, 1.0), Vector2(28, -14), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)


func _option_row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := UiKit.label(text, 18, UiKit.CREAM, 4)
	label.custom_minimum_size.x = 125
	row.add_child(label)
	return row


func _build_help() -> void:
	_help = UiKit.panel(UiKit.NAVY, 0.95, 22, 4, UiKit.ORANGE, 24)
	_help.mouse_filter = Control.MOUSE_FILTER_STOP
	_help.visible = false
	_ui.add_child(_help)
	UiKit.pin(_help, Vector2(0.5, 0.5), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_help.add_child(box)
	_help_box = VBoxContainer.new()
	_help_box.add_theme_constant_override("separation", 4)
	box.add_child(_help_box)
	var done := UiKit.button("GOT IT!", 26, Vector2(220, 54))
	done.name = "HelpDone"
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(_show_help.bind(false))
	box.add_child(done)
	_refresh_help()


func _refresh_help() -> void:
	for child in _help_box.get_children():
		child.queue_free()
	var pad := GameSettings.using_controller
	_help_box.add_child(UiKit.label("HOW TO PLAY" + (" (CONTROLLER)" if pad else ""), 32, UiKit.ORANGE_HOT, 8))
	var lines: Array = (CONTROLLER_HELP if pad else KEYBOARD_HELP) + HOW_TO_PLAY
	for line: String in lines:
		_help_box.add_child(UiKit.label(line, 20, UiKit.CREAM, 4))


func _refresh_card() -> void:
	var shown := GameSettings.display_name()
	var named := shown != "You"
	_bunker_label.text = "%s'S BUNKER" % shown.to_upper() if named else "YOUR BUNKER"
	_card_name.text = shown.to_upper() if named else "SET YOUR NAME!"
	_card_name.add_theme_color_override("font_color", GameSettings.color().lightened(0.3) if named else UiKit.SKY)

	var prog: Node = get_node_or_null("/root/Progression")
	var lvl := 1
	var cur_xp := 0
	var need_xp := 100
	var ratio := 0.0
	var coins_val := 250
	if prog != null:
		var prog_dict: Dictionary = prog.call("level_progress", int(prog.get("lifetime_xp")))
		lvl = int(prog_dict.get("level", 1))
		cur_xp = int(prog_dict.get("current_xp", 0))
		need_xp = int(prog_dict.get("needed_xp", 100))
		ratio = float(prog_dict.get("ratio", 0.0))
		coins_val = int(prog.get("coins"))

	if _level_badge != null:
		_level_badge.text = "LVL %d" % lvl
	if _xp_bar != null:
		_xp_bar.value = ratio
	if _xp_label != null:
		_xp_label.text = "%d / %d XP" % [cur_xp, need_xp]
	if _coins_label != null:
		_coins_label.text = "%d COINS" % coins_val


func _refresh_options() -> void:
	var mode := MatchScene.resolve_mode(GameSettings.match_mode)
	for i in _mode_buttons.size():
		var chosen := MODE_ORDER[i] == GameSettings.match_mode
		_mode_buttons[i].add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if chosen else UiKit.BLUE, 1.0, 12, 3 if chosen else 0, UiKit.CREAM, 8))
	_mode_blurb.text = mode.description
	_players_button.text = "2 PLAYERS (SPLIT)" if GameSettings.split_screen else "1 PLAYER"
	_play_mode_label.text = "%s  -  %s%s" % [mode.display_name.to_upper(),
			MatchScene.ARENAS[clampi(GameSettings.arena, 0, MatchScene.ARENAS.size() - 1)]["name"],
			"  [2 PLAYERS]" if GameSettings.split_screen else ""]
	_bots_value.text = str(GameSettings.bot_count)
	var bots := MatchScene.team_bot_count(mode, GameSettings.bot_count)
	var players := bots + (2 if GameSettings.split_screen else 1)
	var info := ""
	if mode is ZombieMode:
		info = "1 ALPHA ZOMBIE vs %d SURVIVORS" % (players - 1)
	elif mode is ZombieSiegeMode:
		info = "%d DEFENDERS vs ZOMBIE HORDE (5 WAVES)" % players
	else:
		match mode.teams:
			GameMode.Teams.DUOS:
				info = "%d PAIRS" % (players >> 1)
			GameMode.Teams.BLUE_VS_ORANGE:
				info = "%d v %d" % [players >> 1, players >> 1]
			_:
				info = ("2 PLAYERS + %d BOTS" if GameSettings.split_screen else "YOU + %d BOTS") % bots
		if bots > GameSettings.bot_count:
			info += "  (+1 BOT TO EVEN THE TEAMS)"
	_teams_info.text = info
	_arena_button.text = MatchScene.ARENAS[clampi(GameSettings.arena, 0, MatchScene.ARENAS.size() - 1)]["name"]
	_difficulty_button.text = DIFFICULTY_NAMES[clampi(GameSettings.bot_difficulty, 0, DIFFICULTY_NAMES.size() - 1)]
	_storm_row.visible = mode.power_weapon != null
	_storm_button.text = "POWER-UP" if GameSettings.chainstorm_powerup else "EVERYONE"


func _toggle_players() -> void:
	GameSettings.split_screen = not GameSettings.split_screen
	GameSettings.save_settings()
	_refresh_options()
	_rebuild_squad()


func _pick_mode(mode_index: int) -> void:
	GameSettings.match_mode = mode_index
	GameSettings.save_settings()  # Remembered even if no match is started.
	_refresh_options()
	_rebuild_squad()


func _play() -> void:
	GameSettings.save_settings()
	get_tree().change_scene_to_file(MATCH_SCENE)


func _change_bots(step: int) -> void:
	GameSettings.bot_count = clampi(GameSettings.bot_count + step, GameSettings.MIN_BOTS, GameSettings.MAX_BOTS)
	GameSettings.save_settings()
	_refresh_options()
	_rebuild_squad()


func _cycle_arena(step: int = 1) -> void:
	GameSettings.arena = posmod(clampi(GameSettings.arena, 0, MatchScene.ARENAS.size() - 1) + step, MatchScene.ARENAS.size())
	GameSettings.save_settings()
	_swap_backdrop_arena(GameSettings.arena)
	_refresh_options()


func _cycle_difficulty() -> void:
	GameSettings.bot_difficulty = (GameSettings.bot_difficulty + 1) % DIFFICULTY_NAMES.size()
	GameSettings.save_settings()
	_refresh_options()


func _toggle_storm() -> void:
	GameSettings.chainstorm_powerup = not GameSettings.chainstorm_powerup
	GameSettings.save_settings()
	_refresh_options()


func _show_missions(shown: bool) -> void:
	_missions.visible = shown
	_menu.visible = not shown
	if shown:
		_missions.focus_default()
	else:
		_refresh_card()
		_play_button.grab_focus()


func _show_shop(shown: bool) -> void:
	_shop.visible = shown
	_menu.visible = not shown
	if shown:
		_shop.focus_default()
	else:
		_rebuild_squad()
		_refresh_card()
		_play_button.grab_focus()


func _show_settings(shown: bool) -> void:
	_settings.visible = shown
	_menu.visible = not shown
	if shown:
		_settings.focus_default()
	else:
		_play_button.grab_focus()


func _show_multiplayer(shown: bool) -> void:
	_multiplayer_menu.visible = shown
	_menu.visible = not shown
	if shown:
		_multiplayer_menu.focus_default()
	else:
		_refresh_card()
		_play_button.grab_focus()


func _show_workbench(shown: bool) -> void:
	if shown:
		_menu.visible = false
		_show_squad(false)
		if _stage != null:
			_stage.visible = false
		# Mute outdoor arena sun while inside the enclosed garage workshop
		if _backdrop_arena != null and _backdrop_arena.sun_light != null:
			_backdrop_arena.sun_light.visible = false
		if _camera != null:
			_camera.current = false
		if _workbench != null:
			_workbench.visible = true
			if _workbench.camera != null:
				_workbench.camera.make_current()
			_workbench.reset_camera_view()
		if _workbench_panel != null:
			_workbench_panel.visible = true
			_workbench_panel._refresh_all()
			_workbench_panel.focus_default()
	else:
		if _workbench != null:
			_workbench.visible = false
			if _workbench.camera != null:
				_workbench.camera.current = false
		if _workbench_panel != null:
			_workbench_panel.visible = false
		if _backdrop_arena != null and _backdrop_arena.sun_light != null:
			_backdrop_arena.sun_light.visible = true
		if _camera != null:
			_camera.make_current()
		if _stage != null:
			_stage.visible = true
		_show_squad(true)
		_menu.visible = true
		_rebuild_squad()
		_refresh_card()
		_play_button.grab_focus()


func _show_help(shown: bool) -> void:
	_help.visible = shown
	_menu.visible = not shown
	if shown:
		(_help.find_child("HelpDone", true, false) as Button).grab_focus()
	else:
		_play_button.grab_focus()


# --- Character (customise) -------------------------------------------------------

func _build_customise() -> void:
	_customise = UiKit.panel(UiKit.NAVY, 0.94, 22, 4, UiKit.ORANGE, 20)
	_customise.mouse_filter = Control.MOUSE_FILTER_STOP
	_customise.visible = false
	_ui.add_child(_customise)
	UiKit.pin(_customise, Vector2(0.0, 0.5), Vector2(28, 0), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BOTH)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_customise.add_child(outer)
	outer.add_child(UiKit.label("CHARACTER", 34, UiKit.ORANGE_HOT, 10))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(526, 510)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	outer.add_child(scroll)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	# Profile selection tabs
	var prof_row := HBoxContainer.new()
	prof_row.add_theme_constant_override("separation", 10)
	box.add_child(prof_row)
	_profile_tab_p1 = UiKit.small_button("PROFILE 1 (P1)", Vector2(170, 36))
	_profile_tab_p1.pressed.connect(_switch_customise_profile.bind(0))
	prof_row.add_child(_profile_tab_p1)
	_profile_tab_p2 = UiKit.small_button("PROFILE 2 (P2)", Vector2(170, 36))
	_profile_tab_p2.pressed.connect(_switch_customise_profile.bind(1))
	prof_row.add_child(_profile_tab_p2)

	box.add_child(UiKit.label("NAME", 18, UiKit.SKY, 4))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	box.add_child(name_row)
	_name_edit = LineEdit.new()
	_name_edit.max_length = Cosmetics.NAME_MAX_LENGTH
	_name_edit.placeholder_text = "You"
	_name_edit.custom_minimum_size = Vector2(300, 44)
	_name_edit.add_theme_font_override("font", UiKit.font())
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.add_theme_stylebox_override("normal", UiKit.panel_style(UiKit.NAVY_DARK, 1.0, 12, 2, UiKit.SKY, 10))
	_name_edit.add_theme_stylebox_override("focus", UiKit.panel_style(UiKit.NAVY_DARK, 0.0, 12, 3, UiKit.CREAM, 10))
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)
	var random := UiKit.small_button("RANDOM", Vector2(120, 44))
	random.pressed.connect(func() -> void:
		_name_edit.text = Cosmetics.random_name()
		_on_name_changed(_name_edit.text))
	name_row.add_child(random)

	box.add_child(UiKit.label("COLOUR  (TEAM MODES USE TEAM COLOURS)", 16, UiKit.SKY, 4))
	var colours := HBoxContainer.new()
	colours.add_theme_constant_override("separation", 8)
	box.add_child(colours)
	for i in Cosmetics.COLORS.size():
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(44, 44)
		swatch.tooltip_text = Cosmetics.COLORS[i]["name"]
		swatch.pressed.connect(_pick_color.bind(i))
		swatch.pressed.connect(func() -> void: Sfx.play(&"ui_click"))
		colours.add_child(swatch)
		_swatches.append(swatch)

	box.add_child(UiKit.label("HAT", 18, UiKit.SKY, 4))
	var hats := GridContainer.new()
	hats.columns = 4
	hats.add_theme_constant_override("h_separation", 6)
	hats.add_theme_constant_override("v_separation", 6)
	box.add_child(hats)
	for hat in Cosmetics.HATS:
		var hat_button := UiKit.small_button(String(hat["name"]).to_upper(), Vector2(118, 38))
		hat_button.add_theme_font_size_override("font_size", 16)
		hat_button.pressed.connect(_pick_hat.bind(hat["id"]))
		hats.add_child(hat_button)
		_hat_buttons.append(hat_button)

	box.add_child(UiKit.label("BLASTER SKIN / STICKERS", 18, UiKit.SKY, 4))
	var skins_grid := GridContainer.new()
	skins_grid.columns = 4
	skins_grid.add_theme_constant_override("h_separation", 6)
	skins_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(skins_grid)
	for skin in Cosmetics.SKINS:
		var skin_button := UiKit.small_button(String(skin["name"]).to_upper(), Vector2(118, 36))
		skin_button.add_theme_font_size_override("font_size", 14)
		skin_button.pressed.connect(_pick_skin.bind(skin["id"]))
		skins_grid.add_child(skin_button)
		_skin_buttons.append(skin_button)

	box.add_child(UiKit.label("INSPECT BLASTER", 18, UiKit.SKY, 4))
	var inspect_row := HBoxContainer.new()
	inspect_row.add_theme_constant_override("separation", 8)
	box.add_child(inspect_row)

	var prev_w := UiKit.small_button("<", Vector2(40, 36))
	prev_w.pressed.connect(_cycle_preview_weapon.bind(-1))
	inspect_row.add_child(prev_w)

	_weapon_inspect_label = UiKit.label("", 16, UiKit.CREAM, 4)
	_weapon_inspect_label.custom_minimum_size = Vector2(180, 36)
	_weapon_inspect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_inspect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inspect_row.add_child(_weapon_inspect_label)

	var next_w := UiKit.small_button(">", Vector2(40, 36))
	next_w.pressed.connect(_cycle_preview_weapon.bind(1))
	inspect_row.add_child(next_w)

	_turntable_btn = UiKit.small_button("AUTO", Vector2(82, 36))
	_turntable_btn.pressed.connect(func() -> void:
		_turntable_auto = not _turntable_auto
		_turntable_btn.text = "AUTO" if _turntable_auto else "PAUSE")
	inspect_row.add_child(_turntable_btn)

	_reset_view_btn = UiKit.small_button("RESET", Vector2(78, 36))
	_reset_view_btn.pressed.connect(func() -> void:
		_reset_customise_view()
	)
	inspect_row.add_child(_reset_view_btn)

	var tip_label := UiKit.label("Drag: Rotate & Tilt  |  Scroll: Zoom  |  Right-Click: Reset", 13, UiKit.SKY, 2)
	box.add_child(tip_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(btn_row)

	var shop_btn := UiKit.small_button("SHOP", Vector2(120, 46))
	shop_btn.pressed.connect(func() -> void:
		_show_customise(false)
		_show_shop(true))
	btn_row.add_child(shop_btn)

	var boss_btn := UiKit.button("BOSS MODE", 18, Vector2(170, 46))
	boss_btn.name = "CustomiseBossMode"
	boss_btn.pressed.connect(func() -> void:
		var prog: Node = get_node_or_null("/root/Progression")
		if prog != null and prog.has_method("activate_boss_mode"):
			prog.call("activate_boss_mode")
			GameSettings.notify("BOSS MODE! 99,999 Coins & All Items Unlocked!")
			_refresh_customise()
			_update_preview_weapon())
	btn_row.add_child(boss_btn)

	var done := UiKit.button("DONE", 22, Vector2(130, 46))
	done.pressed.connect(_show_customise.bind(false))
	btn_row.add_child(done)
	_refresh_customise()
	_update_preview_weapon()


func _switch_customise_profile(idx: int) -> void:
	_customise_profile = idx
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and prog.has_method("set_active_profile"):
		prog.call("set_active_profile", idx)
	_refresh_customise()
	_update_preview_weapon()


func _cycle_preview_weapon(step: int) -> void:
	_preview_weapon_index = (_preview_weapon_index + step + ALL_WEAPONS.size()) % ALL_WEAPONS.size()
	Sfx.play(&"swap")
	_update_preview_weapon()


func _update_preview_weapon() -> void:
	if player_model == null or ALL_WEAPONS.is_empty():
		return
	_preview_weapon_index = clampi(_preview_weapon_index, 0, ALL_WEAPONS.size() - 1)
	var path: String = ALL_WEAPONS[_preview_weapon_index]
	var wdata := load(path) as WeaponData
	var active_skin: StringName = GameSettings.player2_skin if _customise_profile == 1 else GameSettings.player_skin
	var atts: Dictionary = Progression.get_equipped_attachments(wdata.id, _customise_profile) if (is_instance_valid(Progression) and wdata != null) else {}
	player_model.set_weapon(wdata, active_skin, atts)
	if _weapon_inspect_label != null and wdata != null:
		_weapon_inspect_label.text = "%s (%d/%d)" % [wdata.display_name.to_upper(), _preview_weapon_index + 1, ALL_WEAPONS.size()]


func _show_customise(shown: bool) -> void:
	_customise.visible = shown
	_menu.visible = not shown
	_rebuild_squad()  # Your own colour while customising (alone); team colours otherwise.
	if shown:
		_reset_customise_view(false)
		_camera.fov = _customise_fov
		_move_camera(CAMERA_CLOSE, LOOK_CLOSE)
		_refresh_customise()
		_update_preview_weapon()
		_swatches[clampi(GameSettings.player_color, 0, _swatches.size() - 1)].grab_focus()
		if _inspect_light != null:
			_inspect_light.light_energy = 1.8
	else:
		_camera.fov = 50.0
		_move_camera(CAMERA_LOBBY, LOOK_LOBBY)
		_is_dragging_model = false
		_turntable_auto = true
		if _turntable_btn != null:
			_turntable_btn.text = "AUTO"
		GameSettings.save_settings()
		_refresh_card()
		_play_button.grab_focus()
		if _inspect_light != null:
			_inspect_light.light_energy = 0.0


## Keeps the raw text while typing (so spaces work); it's cleaned up when
## saved and wherever the name is shown (Cosmetics.sanitize_name).
func _on_name_changed(text: String) -> void:
	if _customise_profile == 0:
		GameSettings.player_name = text.substr(0, Cosmetics.NAME_MAX_LENGTH)
	else:
		GameSettings.player2_name = text.substr(0, Cosmetics.NAME_MAX_LENGTH)


func _pick_color(index: int) -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and not bool(prog.call("is_unlocked", &"color", index)):
		GameSettings.notify("Colour locked! Visit the Coin Shop (%d COINS)" % Cosmetics.color_cost(index))
		return
	if _customise_profile == 0:
		GameSettings.player_color = index
	else:
		GameSettings.player2_color = index
	player_model.set_shirt(Cosmetics.color_at(index))
	_refresh_customise()


func _pick_hat(id: StringName) -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and not bool(prog.call("is_unlocked", &"hat", id)):
		GameSettings.notify("Hat locked! Visit the Coin Shop (%d COINS)" % Cosmetics.hat_cost(id))
		return
	if _customise_profile == 0:
		GameSettings.player_hat = id
	else:
		GameSettings.player2_hat = id
	player_model.set_hat(id)
	_refresh_customise()


func _pick_skin(id: StringName) -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and not bool(prog.call("is_unlocked", &"skin", id)) and not Cosmetics.is_default_skin(id):
		GameSettings.notify("Skin locked! Visit the Coin Shop (%d COINS)" % Cosmetics.skin_cost(id))
		return
	if _customise_profile == 0:
		GameSettings.player_skin = id
	else:
		GameSettings.player2_skin = id
	_update_preview_weapon()
	_refresh_customise()


func _refresh_customise() -> void:
	var is_p1 := _customise_profile == 0
	if _profile_tab_p1 != null and _profile_tab_p2 != null:
		_profile_tab_p1.add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if is_p1 else UiKit.BLUE, 1.0, 10, 3 if is_p1 else 0, UiKit.CREAM, 6))
		_profile_tab_p2.add_theme_stylebox_override("normal",
				UiKit.panel_style(UiKit.ORANGE if not is_p1 else UiKit.BLUE, 1.0, 10, 3 if not is_p1 else 0, UiKit.CREAM, 6))

	var cur_name: String = GameSettings.player_name if is_p1 else GameSettings.player2_name
	if not _name_edit.has_focus() and _name_edit.text != cur_name:
		_name_edit.text = cur_name
	var cur_color: int = GameSettings.player_color if is_p1 else GameSettings.player2_color
	var cur_hat: StringName = GameSettings.player_hat if is_p1 else GameSettings.player2_hat
	var cur_skin: StringName = GameSettings.player_skin if is_p1 else GameSettings.player2_skin

	if player_model != null:
		player_model.setup(cur_name, Cosmetics.color_at(cur_color), cur_hat)

	var prog: Node = get_node_or_null("/root/Progression")
	for i in _swatches.size():
		var tint := Cosmetics.color_at(i)
		var chosen := i == cur_color
		var unlocked := prog == null or bool(prog.call("is_unlocked", &"color", i))
		var display_tint := tint if unlocked else tint.darkened(0.5)
		_swatches[i].add_theme_stylebox_override("normal", UiKit.panel_style(display_tint, 1.0, 23, 4 if chosen else 0, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("hover", UiKit.panel_style(display_tint.lightened(0.2), 1.0, 23, 3, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("pressed", UiKit.panel_style(display_tint.darkened(0.2), 1.0, 23, 4, UiKit.CREAM, 0))
		_swatches[i].add_theme_stylebox_override("focus", UiKit.panel_style(display_tint, 0.0, 23, 4, UiKit.ORANGE_HOT, 0))
		_swatches[i].tooltip_text = Cosmetics.COLORS[i]["name"] + ("" if unlocked else " (Locked - %d COINS)" % Cosmetics.color_cost(i))
	for i in _hat_buttons.size():
		var hat_id: StringName = Cosmetics.HATS[i]["id"]
		var hat_name: String = Cosmetics.HATS[i]["name"]
		var chosen: bool = hat_id == cur_hat
		var unlocked := prog == null or bool(prog.call("is_unlocked", &"hat", hat_id))
		_hat_buttons[i].text = (hat_name if unlocked else "[LOCK] " + hat_name).to_upper()
		var bg_col := (UiKit.ORANGE if chosen else UiKit.BLUE) if unlocked else UiKit.NAVY_DARK
		var style := UiKit.panel_style(bg_col, 1.0, 12, 3 if chosen else 0, UiKit.CREAM if unlocked else UiKit.GREY, 8)
		_hat_buttons[i].add_theme_stylebox_override("normal", style)
		_hat_buttons[i].tooltip_text = hat_name + ("" if unlocked else " (Locked - %d COINS)" % Cosmetics.hat_cost(hat_id))
	for i in _skin_buttons.size():
		var skin_id: StringName = Cosmetics.SKINS[i]["id"]
		var skin_name: String = Cosmetics.SKINS[i]["name"]
		var chosen: bool = skin_id == cur_skin
		var unlocked := prog == null or bool(prog.call("is_unlocked", &"skin", skin_id)) or Cosmetics.is_default_skin(skin_id)
		_skin_buttons[i].text = (skin_name if unlocked else "[LOCK] " + skin_name).to_upper()
		var bg_col := (UiKit.ORANGE if chosen else UiKit.BLUE) if unlocked else UiKit.NAVY_DARK
		var style := UiKit.panel_style(bg_col, 1.0, 12, 3 if chosen else 0, UiKit.CREAM if unlocked else UiKit.GREY, 8)
		_skin_buttons[i].add_theme_stylebox_override("normal", style)
		_skin_buttons[i].tooltip_text = skin_name + ("" if unlocked else " (Locked - %d COINS)" % Cosmetics.skin_cost(skin_id))


## The three blue ")))" swooshes beside the logo in the drawing.
class Swoosh extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(90, 110)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in 3:
			var radius := 34.0 + i * 16.0
			draw_arc(Vector2(-6.0, size.y * 0.5), radius, -1.0, 1.0, 24, Color(UiKit.SKY, 1.0 - i * 0.22), 8.0, true)
