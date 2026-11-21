class_name Hud
extends CanvasLayer
## The in-match arcade HUD. It only listens: to the player, the player's
## Arsenal and the MatchController. Layout is built in code with UiKit so the
## whole game shares one look.

signal restart_requested
signal menu_requested
signal pause_requested

const FEED_LIMIT := 5
const FEED_SECONDS := 5.0
## How long each announcer call-out stays up, and how many can wait in line.
const ANNOUNCE_SECONDS := 1.6
const ANNOUNCE_QUEUE_MAX := 3

var _player: Player
var _controller: MatchController

var _root: Control
var _crosshair: Crosshair
var _touch_controls: TouchControls
var _meter_bar: ProgressBar
var _meter_label: Label
var _shield_box: HBoxContainer
var _shield_label: Label
var _shield_bar: ProgressBar
var _weapon_label: Label
var _ammo_label: Label
var _ammo_hint: Label
var _grenade_label: Label
var _infusion_label: Label
var _infusion_bar: ProgressBar
var _spin_bar: ProgressBar
var _clock_label: Label
var _mode_label: Label
var _score_label: Label
var _rank_label: Label
var _wind_gauge: WindGauge
var _wind_label: Label
var _feed: VBoxContainer
var _banner: Label
var _banner_sub: Label
var _popups: Control
var _hurt_flash: ColorRect
var _board_panel: PanelContainer
var _board_title: Label
var _board_grid: GridContainer
var _board_buttons: HBoxContainer
var _banner_tween: Tween
var _refill_left: float = 0.0
var _popup_slot: int = 0
var _match_over: bool = false
var _announce_label: Label
var _announce_queue: Array[Dictionary] = []
var _announce_left: float = 0.0
var _awards_count: int = 0
var _team_strip: HBoxContainer
var _siege_box: VBoxContainer
var _core_bar: ProgressBar
var _core_label: Label
var _wave_label: Label
var _intermission_label: Label
var _scrap_label: Label
var _lava_box: VBoxContainer
var _lava_status_label: Label
var _lava_timer_label: Label
var _weather_panel: PanelContainer
var _weather_icon_label: Label
var _weather_text_label: Label


func setup(player: Player, controller: MatchController) -> void:
	_player = player
	_controller = controller
	_build()

	player.meter_changed.connect(_on_meter_changed)
	player.shield_changed.connect(_on_shield_changed)
	player.shield_broken.connect(_on_shield_broken)
	player.landed_hit.connect(_on_landed_hit)
	player.shot_fired.connect(_on_shot_fired)
	player.aiming_changed.connect(func(is_aiming: bool) -> void: _crosshair.set_scoped(is_aiming))
	player.tagged_out.connect(_on_player_tagged)
	player.tagged_out_status_changed.connect(func(_a: Actor, is_out: bool) -> void:
		if not is_out:
			_hide_banner())
	player.respawned.connect(func(_actor: Actor) -> void: _hide_banner())
	player.ammo_collected.connect(func(_amount: int) -> void: _refill_left = 0.5)
	player.grenade_count_changed.connect(_on_grenade_count_changed)
	player.infusion_changed.connect(_on_infusion_changed)
	player.arsenal.weapon_changed.connect(_on_weapon_changed)
	player.arsenal.ammo_changed.connect(_on_ammo_changed)

	controller.countdown_tick.connect(_on_countdown_tick)
	controller.clock_tick.connect(_on_clock_tick)
	controller.tag_scored.connect(_on_tag_scored)
	controller.popup.connect(_on_popup)
	controller.match_ended.connect(_on_match_ended)
	controller.announcement.connect(_on_announcement)
	controller.board.changed.connect(_refresh_score)

	_mode_label.text = controller.mode.display_name.to_upper()
	_on_clock_tick(int(ceilf(controller.time_left)))
	_refresh_score()
	_on_weapon_changed(player.arsenal.current())
	_on_grenade_count_changed(player.grenade_count, Actor.GRENADE_MAX)
	_on_infusion_changed(player.infusion_element, player.infusion_left)

	if controller.mode is ZombieSiegeMode:
		_build_siege_ui(controller.mode as ZombieSiegeMode)

	if controller.mode is FloorIsLavaMode:
		_build_lava_ui(controller.mode as FloorIsLavaMode)

	_setup_touch_controls()
	GameSettings.changed.connect(_update_touch_controls_visibility)


func _setup_touch_controls() -> void:
	if _touch_controls != null:
		return
	if _player != null and _player.player_index == 0:
		_touch_controls = TouchControls.new()
		_touch_controls.player = _player
		_touch_controls.pause_requested.connect(func() -> void:
			pause_requested.emit())
		_root.add_child(_touch_controls)
		_update_touch_controls_visibility()


func _update_touch_controls_visibility() -> void:
	if _touch_controls != null:
		var touch_should_be_visible: bool = GameSettings.is_touch_active() and not _match_over and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		if _touch_controls.visible != touch_should_be_visible:
			_touch_controls.visible = touch_should_be_visible


func _process(delta: float) -> void:
	_update_touch_controls_visibility()
	if _player == null:
		return
	# Wind compass, relative to where the player is facing.
	var wind := _controller.arena.wind_field.get_wind_at(_player.global_position + Vector3.UP)
	var strength := wind.length()
	if strength < 0.5:
		_wind_gauge.set_wind(0.0, 0.0)
		_wind_label.text = "CALM"
	else:
		var basis := _player.global_transform.basis
		_wind_gauge.set_wind(atan2(wind.dot(basis.x), wind.dot(-basis.z)), clampf(strength / 50.0, 0.1, 1.0))
		_wind_label.text = "WIND %d" % int(round(strength))

	# Ammo hints and the Chainstorm spin bar.
	var state := _player.arsenal.current()
	_refill_left = maxf(_refill_left - delta, 0.0)
	if state != null:
		var spinner := state.data.fire_mode == WeaponData.FireMode.SPIN_UP
		_spin_bar.visible = spinner
		if spinner:
			_spin_bar.value = _player.arsenal.spin
			if _player.arsenal.spin >= 1.0 and not _player.storm_mode_announced:
				_player.storm_mode_announced = true
				_on_popup(_player, "STORM MODE!", UiKit.LIME)
		if _refill_left > 0.0:
			_set_hint("REFILLING!", UiKit.LIME)
		elif _player.arsenal.is_reloading():
			_set_hint("RELOADING...", UiKit.SKY)
		elif state.total() <= 0:
			_set_hint("OUT OF DARTS - FIND A BUCKET!", UiKit.ORANGE_HOT)
		elif not state.infinite_reserve and state.total() <= maxi(floori(state.data.reserve_max / 8.0), 3):
			_set_hint("LOW AMMO", UiKit.ORANGE_HOT)
		else:
			_set_hint("", UiKit.CREAM)

	_tick_announcer(delta)

	if _player != null and _infusion_bar != null and _infusion_label != null:
		if _player.infusion_left > 0.0 and _player.infusion_element != DartData.Element.NONE:
			_infusion_bar.value = clampf(_player.infusion_left / 15.0, 0.0, 1.0)
			_infusion_label.text = "%s %ds" % [_get_element_name(_player.infusion_element), int(ceilf(_player.infusion_left))]
		elif _infusion_bar.visible:
			_infusion_bar.visible = false
			_infusion_label.visible = false

	if _lava_box != null and _controller.mode is FloorIsLavaMode:
		var lm := _controller.mode as FloorIsLavaMode
		if lm.lava_director != null:
			var ld := lm.lava_director
			var sec := maxi(0, int(ceilf(ld.time_left)))
			match ld.phase:
				LavaDirector.Phase.CALM:
					_lava_status_label.text = "FLOOR SAFE"
					_lava_status_label.add_theme_color_override("font_color", UiKit.LIME)
					_lava_timer_label.text = "NEXT TIDE IN %ds" % sec
				LavaDirector.Phase.WARNING:
					_lava_status_label.text = "WARNING: LAVA RISING!"
					_lava_status_label.add_theme_color_override("font_color", UiKit.ORANGE_HOT)
					_lava_timer_label.text = "RISING IN %ds!" % sec
				LavaDirector.Phase.RISING:
					_lava_status_label.text = "LAVA RISING!"
					_lava_status_label.add_theme_color_override("font_color", UiKit.ORANGE_HOT)
					_lava_timer_label.text = "SEEK HIGH GROUND!"
				LavaDirector.Phase.HIGH_TIDE:
					_lava_status_label.text = "HIGH TIDE — STAY HIGH!"
					_lava_status_label.add_theme_color_override("font_color", UiKit.ORANGE_HOT)
					_lava_timer_label.text = "%ds REMAINING" % sec
				LavaDirector.Phase.RECEDING:
					_lava_status_label.text = "LAVA RECEDING..."
					_lava_status_label.add_theme_color_override("font_color", UiKit.SKY)
					_lava_timer_label.text = "COOLING DOWN"

	# Weather status
	if _weather_panel != null:
		var wd: WeatherDirector = _controller.arena.weather_director if _controller != null and _controller.arena != null else null
		if wd != null and wd.is_inside_tree():
			_weather_panel.visible = true
			if wd.is_warning:
				_weather_icon_label.text = wd.get_weather_icon(wd.next_weather)
				_weather_text_label.text = "WARN: %ds" % maxi(0, int(ceilf(wd.time_left)))
				_weather_text_label.add_theme_color_override("font_color", UiKit.ORANGE_HOT)
			elif wd.current_weather != WeatherDirector.Weather.CALM:
				_weather_icon_label.text = wd.get_weather_icon()
				_weather_text_label.text = "%s %ds" % [wd.get_weather_title(), maxi(0, int(ceilf(wd.time_left)))]
				_weather_text_label.add_theme_color_override("font_color", UiKit.SKY)
			else:
				_weather_icon_label.text = "🌤️"
				_weather_text_label.text = "CALM"
				_weather_text_label.add_theme_color_override("font_color", UiKit.CREAM)
		else:
			_weather_panel.visible = false

	# Respawn countdown while tagged out.
	if not _player.alive and not _match_over:
		var left := _controller.respawn_time_left(_player)
		_banner_sub.text = "Back in %d..." % int(ceilf(left)) if left > 0.0 else ""

	if not _match_over:
		var sb_action := StringName(_player.action_prefix + "scoreboard") if (_player != null and not _player.action_prefix.is_empty()) else &"scoreboard"
		var show_board := Input.is_action_pressed(sb_action)
		if show_board and not _board_panel.visible:
			_rebuild_board("SCOREBOARD")
		_board_panel.visible = show_board


# --- Building -----------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_hurt_flash = ColorRect.new()
	_hurt_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hurt_flash.color = Color(UiKit.ORANGE, 0.0)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hurt_flash)

	_crosshair = Crosshair.new()
	_root.add_child(_crosshair)

	# Bottom left: the tag meter. When it fills up, you are tagged out.
	var meter_panel := UiKit.panel()
	_root.add_child(meter_panel)
	UiKit.pin(meter_panel, Vector2(0.0, 1.0), Vector2(20, -20), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BEGIN)
	var meter_box := VBoxContainer.new()
	meter_panel.add_child(meter_box)
	_shield_box = HBoxContainer.new()
	_shield_label = UiKit.label("SHIELD", 14, Color(0.2, 0.85, 1.0))
	_shield_box.add_child(_shield_label)
	_shield_bar = UiKit.bar(Color(0.2, 0.85, 1.0), Vector2(160, 14))
	_shield_box.add_child(_shield_bar)
	_shield_box.visible = false
	meter_box.add_child(_shield_box)
	_meter_label = UiKit.label("TAG METER", 18, UiKit.SKY)
	meter_box.add_child(_meter_label)
	_meter_bar = UiKit.bar(UiKit.ORANGE, Vector2(260, 26))
	meter_box.add_child(_meter_bar)

	# Bottom right: blaster and ammo.
	var weapon_panel := UiKit.panel()
	_root.add_child(weapon_panel)
	UiKit.pin(weapon_panel, Vector2(1.0, 1.0), Vector2(-20, -20), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BEGIN)
	var weapon_box := VBoxContainer.new()
	weapon_box.alignment = BoxContainer.ALIGNMENT_END
	weapon_panel.add_child(weapon_box)
	_infusion_label = UiKit.label("", 16, UiKit.ORANGE_HOT)
	_infusion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_infusion_label.visible = false
	weapon_box.add_child(_infusion_label)
	_infusion_bar = UiKit.bar(UiKit.ORANGE, Vector2(240, 8))
	_infusion_bar.visible = false
	weapon_box.add_child(_infusion_bar)
	_ammo_hint = UiKit.label("", 16, UiKit.ORANGE_HOT)
	_ammo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(_ammo_hint)
	_weapon_label = UiKit.label("BLASTER", 22, UiKit.ORANGE_HOT)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(_weapon_label)
	_ammo_label = UiKit.label("0", 44)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(_ammo_label)
	_grenade_label = UiKit.label("💣 0", 18, UiKit.CREAM)
	_grenade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_box.add_child(_grenade_label)
	_spin_bar = UiKit.bar(UiKit.LIME, Vector2(240, 14))
	_spin_bar.visible = false
	weapon_box.add_child(_spin_bar)

	# Top centre: the clock.
	var clock_panel := UiKit.panel(UiKit.NAVY, 0.86, 18, 3)
	_root.add_child(clock_panel)
	UiKit.pin(clock_panel, Vector2(0.5, 0.0), Vector2(0, 14), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	var clock_box := VBoxContainer.new()
	clock_panel.add_child(clock_box)
	_clock_label = UiKit.label("5:00", 40)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_label.custom_minimum_size.x = 150
	clock_box.add_child(_clock_label)
	_mode_label = UiKit.label("", 14, UiKit.SKY, 4)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_mode_label)

	# Top left: score, then the wind compass.
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	left_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(left_box)
	UiKit.pin(left_box, Vector2(0.0, 0.0), Vector2(20, 14), Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_END)
	var score_panel := UiKit.panel()
	left_box.add_child(score_panel)
	var score_box := VBoxContainer.new()
	score_panel.add_child(score_box)
	_score_label = UiKit.label("SCORE 0", 28, UiKit.ORANGE_HOT)
	score_box.add_child(_score_label)
	_rank_label = UiKit.label("", 16, UiKit.CREAM, 4)
	score_box.add_child(_rank_label)
	var wind_panel := UiKit.panel()
	wind_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_box.add_child(wind_panel)
	var wind_box := HBoxContainer.new()
	wind_box.add_theme_constant_override("separation", 10)
	wind_panel.add_child(wind_box)
	_wind_gauge = WindGauge.new()
	wind_box.add_child(_wind_gauge)
	_wind_label = UiKit.label("CALM", 20, UiKit.SKY)
	_wind_label.custom_minimum_size.x = 110
	wind_box.add_child(_wind_label)

	_weather_panel = UiKit.panel()
	_weather_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_box.add_child(_weather_panel)
	var weather_box := HBoxContainer.new()
	weather_box.add_theme_constant_override("separation", 8)
	_weather_panel.add_child(weather_box)
	_weather_icon_label = UiKit.label("🌤️", 18)
	weather_box.add_child(_weather_icon_label)
	_weather_text_label = UiKit.label("CALM", 16, UiKit.CREAM)
	_weather_text_label.custom_minimum_size.x = 120
	weather_box.add_child(_weather_text_label)

	# Top right: who tagged whom.
	_feed = VBoxContainer.new()
	_feed.alignment = BoxContainer.ALIGNMENT_BEGIN
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_feed)
	UiKit.pin(_feed, Vector2(1.0, 0.0), Vector2(-20, 14), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_END)

	# Centre: big announcements (countdown, tagged out, match over).
	var banner_box := VBoxContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(banner_box)
	UiKit.pin(banner_box, Vector2(0.5, 0.26), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	_banner = UiKit.label("", 96, UiKit.ORANGE_HOT, 16)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(_banner)
	_banner_sub = UiKit.label("", 28, UiKit.CREAM, 8)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(_banner_sub)

	# Team modes: every team's score in a row of coloured chips under the clock.
	var teams := _controller.mode.is_team_mode()
	_team_strip = HBoxContainer.new()
	_team_strip.add_theme_constant_override("separation", 8)
	_team_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_strip.visible = teams
	_root.add_child(_team_strip)
	UiKit.pin(_team_strip, Vector2(0.5, 0.0), Vector2(0, 108), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)

	# Announcer call-outs sit just under the clock (and the team scores).
	_announce_label = UiKit.label("", 40, UiKit.ORANGE_HOT, 12)
	_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_announce_label)
	UiKit.pin(_announce_label, Vector2(0.5, 0.0), Vector2(0, 160 if teams else 128), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)

	_popups = Control.new()
	_popups.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_popups)

	_build_board()


func _build_board() -> void:
	_board_panel = UiKit.panel(UiKit.NAVY, 0.94, 22, 4, UiKit.ORANGE, 24)
	_board_panel.visible = false
	_root.add_child(_board_panel)
	UiKit.pin(_board_panel, Vector2(0.5, 0.52), Vector2.ZERO, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BOTH)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_board_panel.add_child(box)
	_board_title = UiKit.label("SCOREBOARD", 40, UiKit.ORANGE_HOT, 10)
	_board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_board_title)
	_board_grid = GridContainer.new()
	_board_grid.add_theme_constant_override("h_separation", 34)
	_board_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(_board_grid)
	_board_buttons = HBoxContainer.new()
	_board_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_board_buttons.add_theme_constant_override("separation", 16)
	_board_buttons.visible = false
	box.add_child(_board_buttons)
	var again := UiKit.button("PLAY AGAIN", 24, Vector2(230, 54))
	again.pressed.connect(func() -> void: restart_requested.emit())
	_board_buttons.add_child(again)
	var menu := UiKit.small_button("MAIN MENU", Vector2(200, 54))
	menu.pressed.connect(func() -> void: menu_requested.emit())
	_board_buttons.add_child(menu)


func _rebuild_board(title: String, compact: bool = false) -> void:
	_board_title.text = title
	_board_grid.add_theme_constant_override("h_separation", 20 if compact else 34)
	for child in _board_grid.get_children():
		child.queue_free()
	var mode := _controller.mode
	var gun_game := mode is GunGameMode
	var headers := ["#", "PLAYER", "TAGS", "OUTS", "SCORE"]
	if gun_game:
		headers.append("BLASTER")
	_board_grid.columns = headers.size()
	for header: String in headers:
		_board_grid.add_child(UiKit.label(header, 14 if compact else 16, UiKit.SKY, 4))
	var row_size := 20 if compact else 24
	if mode.is_team_mode():
		# One block per team, best team first: a header with the team total, then its players.
		var place := 0
		for team in mode.rank_teams(_controller.board):
			place += 1
			var team_id: int = team["team"]
			var tint := mode.get_team_color(team_id).lightened(0.35)
			var team_title := mode.get_team_name(team_id) if mode is ZombieMode else "%s TEAM" % mode.get_team_name(team_id)
			var header := [str(place), team_title, str(team["tags"]), "", str(team["score"])]
			for cell: String in header:
				_board_grid.add_child(UiKit.label(cell, row_size, tint, 6))
			for entry: ScoreEntry in team["members"]:
				_add_board_row(["", "  " + _board_name(entry), str(entry.tags), str(entry.outs), str(entry.score)],
						entry.color.lightened(0.3), row_size - 2)
		return
	var ranking := mode.rank(_controller.board)
	for i in ranking.size():
		var entry := ranking[i]
		var cells := [str(i + 1), _board_name(entry), str(entry.tags), str(entry.outs), str(entry.score)]
		if gun_game:
			cells.append(mode.describe_progress(entry).trim_prefix("BLASTER "))
		_add_board_row(cells, entry.color.lightened(0.3), row_size)


func _board_name(entry: ScoreEntry) -> String:
	return entry.display_name + ("  (you)" if entry.is_human and entry.display_name != "You" else "")


## A scoreboard row: the name (second cell) in the player's colour, the rest in cream.
func _add_board_row(cells: Array, name_tint: Color, font_size: int) -> void:
	for i in cells.size():
		_board_grid.add_child(UiKit.label(cells[i], font_size, name_tint if i == 1 else UiKit.CREAM, 6))


# --- Reacting -----------------------------------------------------------------

func _on_meter_changed(value: float, maximum: float) -> void:
	var ratio := value / maxf(maximum, 1.0)
	if ratio > _meter_bar.value + 0.001:
		# Soft orange flash at the screen edges when hit; never a full-screen strobe.
		_hurt_flash.color.a = 0.16 * clampf(GameSettings.visual_intensity, 0.0, 1.0)
		create_tween().tween_property(_hurt_flash, "color:a", 0.0, 0.35)
	_meter_bar.value = ratio
	_meter_label.text = "TAG METER" if ratio < 0.7 else "TAG METER - DANGER!"
	_meter_label.add_theme_color_override("font_color", UiKit.SKY if ratio < 0.7 else UiKit.ORANGE_HOT)


func _on_shield_changed(current: float, max_val: float) -> void:
	if _shield_box == null:
		return
	_shield_box.visible = current > 0.0
	_shield_bar.value = clampf(current / maxf(max_val, 1.0), 0.0, 1.0)
	_shield_label.text = "SHIELD %d/%d" % [int(current), int(max_val)]


func _on_shield_broken(_actor: Actor) -> void:
	if _shield_box != null:
		_shield_box.visible = false
	if _hurt_flash != null:
		_hurt_flash.color = Color(0.2, 0.85, 1.0, 0.25 * clampf(GameSettings.visual_intensity, 0.0, 1.0))
		create_tween().tween_property(_hurt_flash, "color:a", 0.0, 0.4)


func _on_weapon_changed(state: WeaponState) -> void:
	if _crosshair != null:
		_crosshair.set_scoped(false)
	if state == null:
		return
	_weapon_label.text = state.data.display_name.to_upper()
	_on_ammo_changed(state)


func _on_ammo_changed(state: WeaponState) -> void:
	if state == null or state != _player.arsenal.current():
		return
	var reserve_text := "INF" if state.infinite_reserve else str(state.reserve)
	if state.data.is_belt_fed():
		_ammo_label.text = "BELT %s" % reserve_text
	else:
		_ammo_label.text = "%d | %s" % [state.magazine, reserve_text]


func _on_grenade_count_changed(count: int, _max_val: int) -> void:
	if _grenade_label != null:
		_grenade_label.text = "💣 %d [G]" % count if count > 0 else "💣 0"
		_grenade_label.add_theme_color_override("font_color", UiKit.LIME if count > 0 else UiKit.CREAM)


func _on_infusion_changed(element: DartData.Element, time_left: float) -> void:
	if _infusion_bar == null or _infusion_label == null:
		return
	var active := time_left > 0.0 and element != DartData.Element.NONE
	_infusion_bar.visible = active
	_infusion_label.visible = active
	if active:
		var col := _get_element_color(element)
		_infusion_bar.value = clampf(time_left / 15.0, 0.0, 1.0)
		_infusion_bar.add_theme_stylebox_override("fill", UiKit.panel_style(col, 1.0, 4))
		_infusion_label.text = "%s %ds" % [_get_element_name(element), int(ceilf(time_left))]
		_infusion_label.add_theme_color_override("font_color", col.lightened(0.2))


func _get_element_name(element: DartData.Element) -> String:
	match element:
		DartData.Element.FIRE: return "🔥 PYRO"
		DartData.Element.WATER: return "💧 HYDRO"
		DartData.Element.LIGHTNING: return "⚡ VOLT"
		DartData.Element.ICE: return "❄️ FROST"
		DartData.Element.WIND: return "💨 GALE"
	return "ELEMENT"


func _get_element_color(element: DartData.Element) -> Color:
	match element:
		DartData.Element.FIRE: return Color(1.0, 0.45, 0.12)
		DartData.Element.WATER: return Color(0.2, 0.75, 1.0)
		DartData.Element.LIGHTNING: return Color(1.0, 0.95, 0.25)
		DartData.Element.ICE: return Color(0.82, 0.96, 1.0)
		DartData.Element.WIND: return Color(0.75, 0.95, 0.85)
	return Color.WHITE


func _on_shot_fired(state: WeaponState) -> void:
	_crosshair.kick(2.0 + state.data.spread_degrees)


func _on_landed_hit(_victim: Actor, was_tag: bool, _was_ricochet: bool) -> void:
	_crosshair.show_hit(was_tag)


func _on_player_tagged(_victim: Actor, attacker: Actor, _weapon: WeaponData, _ricochet: bool) -> void:
	if _crosshair != null:
		_crosshair.set_scoped(false)
	var by := " by %s" % attacker.display_name if attacker != null else ""
	if _player != null and _player.realistic_mode:
		_show_banner("TAGGED OUT!", "Run back to your team base to revive!", 0.0)
	else:
		_show_banner("TAGGED!", "You were tagged%s" % by, 0.0)


func _on_countdown_tick(seconds_left: int) -> void:
	if seconds_left > 0:
		_show_banner(str(seconds_left), "Get ready!", 0.0)
		Sfx.play(&"beep")
	else:
		_show_banner("GO!", "", 0.9)
		Sfx.play(&"go")


func _on_clock_tick(seconds_left: int) -> void:
	_clock_label.text = "%d:%02d" % [floori(seconds_left / 60.0), seconds_left % 60]
	var urgent := seconds_left <= 10
	_clock_label.add_theme_color_override("font_color", UiKit.ORANGE_HOT if urgent else UiKit.CREAM)
	if urgent and seconds_left > 0 and _controller.state == MatchController.State.PLAYING:
		Sfx.play(&"beep", 1.3, -8.0)


func _on_tag_scored(attacker: ScoreEntry, victim: ScoreEntry, weapon: WeaponData, ricochet: bool) -> void:
	var row := UiKit.panel(UiKit.NAVY_DARK, 0.75, 12, 0, UiKit.ORANGE, 8)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	row.add_child(line)
	line.add_child(UiKit.label(attacker.display_name, 18, attacker.color.lightened(0.3), 4))
	var how := weapon.display_name if weapon != null else "tagged"
	if ricochet:
		how += " (RICOCHET!)"
	line.add_child(UiKit.label("> %s >" % how, 14, UiKit.CREAM, 4))
	line.add_child(UiKit.label(victim.display_name, 18, victim.color.lightened(0.3), 4))
	row.size_flags_horizontal = Control.SIZE_SHRINK_END
	_feed.add_child(row)
	if _feed.get_child_count() > FEED_LIMIT:
		_feed.get_child(0).queue_free()
	var tween := row.create_tween()
	tween.tween_interval(FEED_SECONDS)
	tween.tween_property(row, "modulate:a", 0.0, 0.5)
	tween.tween_callback(row.queue_free)


## Arcade score popups that float up from under the crosshair.
func _on_popup(actor: Actor, text: String, tint: Color) -> void:
	if actor != _player:
		return
	var label := UiKit.label(text, 30, tint, 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popups.add_child(label)
	UiKit.pin(label, Vector2(0.5, 0.5), Vector2(0, 54 + _popup_slot * 36), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)
	_popup_slot = (_popup_slot + 1) % 3
	label.pivot_offset = Vector2(0, 18)
	label.scale = Vector2(0.6, 0.6)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.7)
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -50.0, 0.5).as_relative()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(label.queue_free)
	if text.begins_with("NEW BLASTER"):
		Sfx.play(&"level_up")


func _on_match_ended(ranking: Array[ScoreEntry]) -> void:
	_match_over = true
	_hide_banner()
	_announce_queue.clear()
	# Clear the gameplay HUD so the podium (in 3D behind us) is the star.
	for child in _root.get_children():
		if child != _board_panel:
			(child as CanvasItem).visible = false
	var title := result_title(ranking)
	if not ranking.is_empty():
		Sfx.play(&"win" if title.begins_with("YOU") else &"lose")
	_rebuild_board(title, true)
	UiKit.pin(_board_panel, Vector2(1.0, 0.5), Vector2(-24, 0), Control.GROW_DIRECTION_BEGIN, Control.GROW_DIRECTION_BOTH)
	_board_buttons.visible = true
	_board_panel.visible = true
	_build_rewards(ranking)
	_build_awards(Awards.compute(ranking))
	var first := _board_buttons.get_child(0) as Button
	if first != null:
		first.grab_focus()


## "YOU WIN!", "BLAZE WINS!", "YOUR TEAM WINS!", "ORANGE TEAM WINS!" or "IT'S A DRAW!".
func result_title(ranking: Array[ScoreEntry]) -> String:
	if ranking.is_empty():
		return "MATCH OVER"
	var mode := _controller.mode
	if not mode.is_team_mode():
		var winner := ranking[0]
		return "YOU WIN!" if winner.is_human else "%s WINS!" % winner.display_name.to_upper()
	var team := mode.winning_team(_controller.board)
	if team < 0:
		return "IT'S A DRAW!"
	return "YOUR TEAM WINS!" if team == _player.team_id else "%s TEAM WINS!" % GameMode.team_name(team)


func _build_rewards(ranking: Array[ScoreEntry]) -> void:
	var human_entry: ScoreEntry = _controller.board.entry_for(_player)
	var tags := human_entry.tags if human_entry != null else 0
	var mode := _controller.mode
	var won := false
	if not ranking.is_empty():
		if not mode.is_team_mode():
			won = ranking[0].is_human
		else:
			var winning_team := mode.winning_team(_controller.board)
			won = winning_team == _player.team_id
	var prog: Node = get_node_or_null("/root/Progression")
	var xp_per_tag: int = int(prog.get("XP_PER_TAG")) if prog != null else 25
	var coins_per_tag: int = int(prog.get("COINS_PER_TAG")) if prog != null else 5
	var xp_finish: int = int(prog.get("XP_MATCH_FINISH")) if prog != null else 100
	var coins_finish: int = int(prog.get("COINS_MATCH_FINISH")) if prog != null else 25
	var xp_win: int = int(prog.get("XP_MATCH_WIN")) if prog != null else 150
	var coins_win: int = int(prog.get("COINS_MATCH_WIN")) if prog != null else 50

	var xp_earned := tags * xp_per_tag + xp_finish + (xp_win if won else 0)
	var coins_earned := tags * coins_per_tag + coins_finish + (coins_win if won else 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var panel_box := _board_buttons.get_parent()
	panel_box.add_child(box)
	panel_box.move_child(box, _board_buttons.get_index())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	row.add_child(UiKit.label("REWARDS:", 20, UiKit.CREAM, 5))
	row.add_child(UiKit.label("⭐ +%d XP" % xp_earned, 20, UiKit.LIME, 5))
	row.add_child(UiKit.label("🪙 +%d COINS" % coins_earned, 20, UiKit.ORANGE_HOT, 5))


func _build_awards(awards: Array[Dictionary]) -> void:
	_awards_count = awards.size()
	if awards.is_empty():
		return
	# Awards sit inside the results panel, between the table and the buttons,
	# so the podium on the left stays in full view.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var panel_box := _board_buttons.get_parent()
	panel_box.add_child(box)
	panel_box.move_child(box, _board_buttons.get_index())
	box.add_child(UiKit.label("AWARDS", 24, UiKit.SKY, 6))
	for award in awards:
		var entry: ScoreEntry = award["entry"]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		box.add_child(line)
		line.add_child(UiKit.label(String(award["title"]).to_upper(), 18, UiKit.ORANGE_HOT, 5))
		var who := "You" if entry.is_human else entry.display_name
		line.add_child(UiKit.label("%s - %s" % [who, award["detail"]], 16, entry.color.lightened(0.35), 4))


func awards_shown() -> int:
	return _awards_count


func _on_announcement(_entry: ScoreEntry, text: String, color: Color, sound: StringName) -> void:
	if _match_over:
		return
	_announce_queue.append({"text": text, "color": color, "sound": sound})
	while _announce_queue.size() > ANNOUNCE_QUEUE_MAX:
		_announce_queue.pop_front()


## The text currently being announced ("" when quiet). Used by tests.
func current_announcement() -> String:
	return _announce_label.text if _announce_left > 0.0 else ""


func _tick_announcer(delta: float) -> void:
	_announce_left -= delta
	if _announce_left > 0.0:
		return
	if _announce_queue.is_empty():
		_announce_label.text = ""
		return
	var next: Dictionary = _announce_queue.pop_front()
	_announce_label.text = next["text"]
	_announce_label.add_theme_color_override("font_color", next["color"])
	_announce_label.reset_size()
	_announce_label.pivot_offset = _announce_label.size * 0.5
	_announce_label.scale = Vector2(0.5, 0.5)
	_announce_label.modulate.a = 1.0
	_announce_left = ANNOUNCE_SECONDS
	var tween := _announce_label.create_tween()
	tween.tween_property(_announce_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(ANNOUNCE_SECONDS - 0.5)
	tween.tween_property(_announce_label, "modulate:a", 0.0, 0.3)
	Sfx.play(next["sound"], 1.0, -3.0)


func _refresh_score() -> void:
	var entry := _controller.board.entry_for(_player)
	if entry == null:
		return
	_score_label.text = "SCORE %d" % entry.score
	var mode := _controller.mode
	var progress := mode.describe_progress(entry)
	var text := ""
	if mode is ZombieMode:
		var zombie_mode := mode as ZombieMode
		var survivors := zombie_mode.count_survivors(_controller.board)
		var total := _controller.board.entries.size()
		text = "TAGS %d   SURVIVORS LEFT %d/%d" % [entry.tags, survivors, total]
		var teams := mode.rank_teams(_controller.board)
		_refresh_team_strip(teams, entry.team)
	elif mode.is_team_mode():
		var teams := mode.rank_teams(_controller.board)
		var team_place := 1
		for i in teams.size():
			if teams[i]["team"] == entry.team:
				team_place = i + 1
		text = "TAGS %d   TEAM PLACE %d/%d" % [entry.tags, team_place, teams.size()]
		_refresh_team_strip(teams, entry.team)
	else:
		var ranking := mode.rank(_controller.board)
		text = "TAGS %d   PLACE %d/%d" % [entry.tags, ranking.find(entry) + 1, ranking.size()]
	if not progress.is_empty():
		text += "\n" + progress
	_rank_label.text = text
	if _board_panel.visible and not _match_over:
		_rebuild_board("SCOREBOARD")


## One chip per team, always in team order (so they don't jump about); your
## team's chip has a white border.
func _refresh_team_strip(teams: Array[Dictionary], mine: int) -> void:
	for child in _team_strip.get_children():
		child.queue_free()
	var ordered := teams.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["team"] < b["team"])
	for team: Dictionary in ordered:
		var id: int = team["team"]
		var color := _controller.mode.get_team_color(id)
		var name_str := _controller.mode.get_team_name(id)
		var chip := UiKit.panel(color.darkened(0.25), 0.92, 14, 3 if id == mine else 0, UiKit.CREAM, 8)
		chip.add_child(UiKit.label("%s %d" % [name_str, team["score"]], 22, UiKit.CREAM, 5))
		_team_strip.add_child(chip)


## Team chips currently shown under the clock (tests use this).
func team_chip_count() -> int:
	var count := 0
	for child in _team_strip.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func _set_hint(text: String, tint: Color) -> void:
	if _ammo_hint.text != text:
		_ammo_hint.text = text
		_ammo_hint.add_theme_color_override("font_color", tint)


func _show_banner(title: String, subtitle: String, hide_after: float) -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.text = title
	_banner_sub.text = subtitle
	_banner.modulate.a = 1.0
	_banner_sub.modulate.a = 1.0
	if hide_after > 0.0:
		_banner_tween = create_tween()
		_banner_tween.tween_interval(hide_after)
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
		_banner_tween.tween_callback(_hide_banner)


func _hide_banner() -> void:
	_banner.text = ""
	_banner_sub.text = ""


func _build_siege_ui(siege: ZombieSiegeMode) -> void:
	_team_strip.visible = false
	_siege_box = VBoxContainer.new()
	_siege_box.add_theme_constant_override("separation", 4)
	_siege_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_siege_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_siege_box)
	UiKit.pin(_siege_box, Vector2(0.5, 0.0), Vector2(0, 96), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)

	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 16)
	_siege_box.add_child(info_row)

	_wave_label = UiKit.label("WAVE 1 / 5", 20, UiKit.CREAM, 6)
	info_row.add_child(_wave_label)

	_scrap_label = UiKit.label("🔧 100 SCRAP", 20, UiKit.LIME, 6)
	info_row.add_child(_scrap_label)

	var core_panel := PanelContainer.new()
	core_panel.custom_minimum_size = Vector2(360, 26)
	core_panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY_DARK, 0.9, 10, 2, UiKit.BLUE, 2))
	_siege_box.add_child(core_panel)

	var init_max := siege.base_core.max_health if siege.base_core != null else BaseCore.MAX_HEALTH
	var init_curr := siege.base_core.health if siege.base_core != null else init_max

	_core_bar = ProgressBar.new()
	_core_bar.min_value = 0.0
	_core_bar.max_value = init_max
	_core_bar.value = init_curr
	_core_bar.show_percentage = false
	_core_bar.custom_minimum_size = Vector2(356, 22)
	_core_bar.add_theme_stylebox_override("background", UiKit.panel_style(Color(0.05, 0.1, 0.2), 0.8, 8))
	_core_bar.add_theme_stylebox_override("fill", UiKit.panel_style(UiKit.SKY, 1.0, 8))
	core_panel.add_child(_core_bar)

	_core_label = UiKit.label("BASE CORE: %d / %d" % [int(ceilf(init_curr)), int(init_max)], 14, UiKit.CREAM, 4)
	_core_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_panel.add_child(_core_label)

	_intermission_label = UiKit.label("", 18, UiKit.ORANGE_HOT, 6)
	_intermission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intermission_label.visible = false
	_siege_box.add_child(_intermission_label)

	if siege.base_core != null:
		siege.base_core.health_changed.connect(func(curr: float, max_hp: float) -> void:
			_core_bar.value = curr
			_core_bar.max_value = max_hp
			_core_label.text = "BASE CORE: %d / %d" % [int(ceilf(curr)), int(max_hp)]
			var ratio := curr / max_hp
			_core_bar.add_theme_stylebox_override("fill", UiKit.panel_style(
					UiKit.SKY if ratio > 0.5 else (UiKit.ORANGE if ratio > 0.25 else Color(0.95, 0.22, 0.25)), 1.0, 8))
		)

	if siege.horde_director != null:
		var hd := siege.horde_director
		hd.wave_started.connect(func(wave_num: int, _total: int, wave_name: String) -> void:
			_wave_label.text = "WAVE %d / 5 • %s" % [wave_num, wave_name]
			_intermission_label.visible = false
		)
		hd.intermission_tick.connect(func(seconds_left: int) -> void:
			_intermission_label.visible = true
			_intermission_label.text = "FORTIFY & REPAIR! (%ds)" % seconds_left
		)
		hd.scrap_changed.connect(func(current_scrap: int) -> void:
			_scrap_label.text = "🔧 %d SCRAP" % current_scrap
		)
		_scrap_label.text = "🔧 %d SCRAP" % hd.scrap


func _build_lava_ui(_lava_mode: FloorIsLavaMode) -> void:
	_team_strip.visible = false
	_lava_box = VBoxContainer.new()
	_lava_box.add_theme_constant_override("separation", 2)
	_lava_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_lava_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_lava_box)
	UiKit.pin(_lava_box, Vector2(0.5, 0.0), Vector2(0, 96), Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 48)
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.NAVY_DARK, 0.9, 12, 2, UiKit.ORANGE_HOT, 2))
	_lava_box.add_child(panel)

	var inner_box := VBoxContainer.new()
	inner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_box.add_theme_constant_override("separation", 2)
	panel.add_child(inner_box)

	_lava_status_label = UiKit.label("FLOOR SAFE", 18, UiKit.LIME, 4)
	_lava_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_box.add_child(_lava_status_label)

	_lava_timer_label = UiKit.label("NEXT TIDE IN 24s", 14, UiKit.CREAM, 2)
	_lava_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_box.add_child(_lava_timer_label)
