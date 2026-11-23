class_name MatchController
extends Node
## Runs one round: countdown, clock, scoring, respawns and the final result.
## It is also the announcer (first tag, multi-tags, streaks, shut-downs, time
## warnings) and keeps the fun stats used for end-of-match awards.
## It knows nothing about the HUD: it just emits signals.

signal state_changed(state: State)
signal countdown_tick(seconds_left: int)
signal clock_tick(seconds_left: int)
signal tag_scored(attacker: ScoreEntry, victim: ScoreEntry, weapon: WeaponData, ricochet: bool)
## A message for one actor's screen, e.g. "+100 TAG!".
signal popup(actor: Actor, text: String, color: Color)
signal match_ended(ranking: Array[ScoreEntry])
## A big call-out for everyone's screen. `entry` is who it's about (or null).
signal announcement(entry: ScoreEntry, text: String, color: Color, sound: StringName)

## Tags this close together (seconds of play) count as a DOUBLE/TRIPLE TAG.
const MULTI_TAG_WINDOW := 4.0
## A streak at least this long earns a "SHUT DOWN!" when it's ended.
const SHUTDOWN_STREAK := 3
## A spawn point this close to someone counts as taken.
const SPAWN_CLEARANCE := 2.5
const MULTI_TAG_TEXT := {2: "DOUBLE TAG!", 3: "TRIPLE TAG!"}
const MULTI_TAG_MAX_TEXT := "FOAM FRENZY!"
const STREAK_TEXT := {3: "ON A ROLL!", 5: "UNSTOPPABLE!", 8: "DARTSTORM!!"}

enum State { WAITING, COUNTDOWN, PLAYING, ENDED }

var mode: GameMode
var arena: Arena
var board: Scoreboard = Scoreboard.new()
var actors: Array[Actor] = []
var state: State = State.WAITING
var time_left: float = 0.0
## Seconds of actual play so far.
var play_time: float = 0.0
var total_tags: int = 0

var _countdown_left: float = 0.0
var _last_whole_second: int = -1
var _respawns: Dictionary = {}
## Team modes: the team currently in front (-1 before anyone scores or when level).
var _leading_team: int = -1
var flags: Array[FlagPickup] = []
var bomb_target: BombTarget = null


func setup(p_mode: GameMode, p_arena: Arena) -> void:
	mode = p_mode
	arena = p_arena
	time_left = mode.duration_seconds
	if mode is RealisticMode:
		_build_realistic_base_zones()


func register(actor: Actor) -> void:
	actors.append(actor)
	board.add_actor(actor)
	actor.controls_enabled = false
	if mode is RealisticMode:
		actor.realistic_mode = true
	actor.tagged_out.connect(_on_tagged_out)
	actor.arsenal.fired.connect(_on_fired.bind(actor))
	actor.landed_hit.connect(_on_landed_hit.bind(actor))
	actor.ammo_collected.connect(_on_ammo_collected.bind(actor))


## Places everyone and starts the countdown.
func begin() -> void:
	for actor in actors:
		_spawn(actor)
	_countdown_left = float(mode.countdown_seconds)
	_last_whole_second = -1
	_set_state(State.COUNTDOWN)
	if mode.countdown_seconds <= 0:
		_start_play()


## Seconds until this actor respawns (0 if they are in play).
func respawn_time_left(actor: Actor) -> float:
	return _respawns.get(actor, 0.0)


func award_target_hit(shooter: Actor) -> void:
	if state != State.PLAYING or shooter == null:
		return
	var entry := board.entry_for(shooter)
	if entry == null:
		return
	entry.score += mode.points_per_target
	entry.targets_hit += 1
	board.notify_changed()
	popup.emit(shooter, "+%d BULLSEYE!" % mode.points_per_target, UiKit.LIME)


## Sends a call-out to everyone's screen (also used by power-ups).
func announce(entry: ScoreEntry, text: String, color: Color = UiKit.ORANGE_HOT, sound: StringName = &"announce") -> void:
	announcement.emit(entry, text, color, sound)


## "DOUBLE TAG!" for you, "PICKLE: DOUBLE TAG!" for anyone else.
static func call_out(entry: ScoreEntry, text: String) -> String:
	if entry == null or entry.is_human:
		return text
	return "%s: %s" % [entry.display_name.to_upper(), text]


static func color_for(entry: ScoreEntry) -> Color:
	if entry == null or entry.is_human:
		return UiKit.ORANGE_HOT
	return entry.color.lightened(0.35)


func _physics_process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_tick_respawns(delta)
			_countdown_left -= delta
			var whole := int(ceilf(_countdown_left))
			if whole != _last_whole_second and whole > 0:
				_last_whole_second = whole
				countdown_tick.emit(whole)
			if _countdown_left <= 0.0:
				_start_play()
		State.PLAYING:
			time_left = maxf(time_left - delta, 0.0)
			play_time += delta
			var whole := int(ceilf(time_left))
			if whole != _last_whole_second:
				_last_whole_second = whole
				clock_tick.emit(whole)
				if whole == 60 and mode.duration_seconds > 60.0:
					announce(null, "1 MINUTE LEFT!", UiKit.SKY, &"announce")
				elif whole == 10:
					announce(null, "10 SECONDS!", UiKit.ORANGE_HOT, &"announce")
			_tick_respawns(delta)
			if mode is RealisticMode:
				_tick_realistic_bases()
			if mode is CaptureTheFlagMode:
				_tick_ctf_captures()
			if time_left <= 0.0:
				_finish()


func _start_play() -> void:
	_last_whole_second = -1
	for actor in actors:
		actor.controls_enabled = true
	countdown_tick.emit(0)
	_set_state(State.PLAYING)


func end_match() -> void:
	_finish()


func _finish() -> void:
	if state == State.ENDED:
		return
	for actor in actors:
		actor.controls_enabled = false
		actor.arsenal.set_trigger(false)
	_set_state(State.ENDED)
	match_ended.emit(mode.rank(board))


func _set_state(next: State) -> void:
	state = next
	state_changed.emit(state)


func _tick_respawns(delta: float) -> void:
	for actor: Actor in _respawns.keys():
		var left: float = _respawns[actor] - delta
		if left <= 0.0:
			_respawns.erase(actor)
			if is_instance_valid(actor):
				_spawn(actor)
		else:
			_respawns[actor] = left


func _on_tagged_out(victim: Actor, attacker: Actor, weapon: WeaponData, ricochet: bool) -> void:
	if state == State.ENDED:
		return
	# Anyone tagged out comes back if allowed by mode.
	if mode.should_respawn(victim):
		_respawns[victim] = mode.respawn_delay
	if state != State.PLAYING:
		return
	var victim_entry := board.entry_for(victim)
	var ended_streak := 0
	if victim_entry != null:
		victim_entry.outs += 1
		ended_streak = victim_entry.streak
		victim_entry.streak = 0
		victim_entry.recent_tags.clear()
	var attacker_entry: ScoreEntry = null
	if attacker != null:
		attacker_entry = board.entry_for(attacker)
	if attacker_entry == null or attacker == victim:
		board.notify_changed()
		return

	var tier_before := attacker_entry.tier
	attacker_entry.tags += 1
	if ricochet:
		attacker_entry.ricochet_tags += 1
	var points := mode.apply_tag(attacker_entry, victim_entry, ricochet)
	if mode is ZombieMode:
		if attacker.is_zombie and not victim.is_zombie:
			victim.set_zombie(true)
			announce(victim_entry, "%s WAS INFECTED!" % victim.display_name.to_upper(), ZombieMode.ZOMBIE_COLOR, &"infect")
			popup.emit(attacker, "+%d INFECTED!" % points, ZombieMode.ZOMBIE_COLOR)
		else:
			popup.emit(attacker, "+%d TAGGED ZOMBIE!" % points, UiKit.ORANGE_HOT)
	else:
		popup.emit(attacker, "+%d TAG!" % mode.points_per_tag, UiKit.ORANGE_HOT)
		if ricochet:
			popup.emit(attacker, "+%d RICOCHET BONUS!" % mode.ricochet_bonus, UiKit.SKY)
	tag_scored.emit(attacker_entry, victim_entry, weapon, ricochet)
	if attacker.is_human:
		var prog: Node = get_node_or_null("/root/Progression")
		if prog != null:
			if weapon != null:
				prog.call("record_weapon_tag", weapon.id, ricochet)
			if ricochet:
				prog.call("notify_event", &"ricochet_tag", 1)
			if weapon != null and weapon.display_name.to_lower().contains("popper"):
				prog.call("notify_event", &"popper_tag", 1)
			if mode is ZombieMode and not attacker.is_zombie and victim != null and victim.is_zombie:
				prog.call("notify_event", &"zombie_tag", 1)
	board.notify_changed()
	_announce_tag(attacker_entry, victim_entry, ended_streak)

	var winner := mode.get_early_winner(board)
	if winner != null:
		_finish()
		return
	if mode is PlantTheBombMode and state == State.PLAYING:
		_check_bomb_elimination()
	if attacker_entry.tier != tier_before and attacker.alive:
		_equip(attacker)
		var held := attacker.arsenal.current()
		if held != null:
			popup.emit(attacker, "NEW BLASTER: %s" % held.data.display_name.to_upper(), UiKit.LIME)


func _announce_tag(attacker: ScoreEntry, victim: ScoreEntry, ended_streak: int) -> void:
	total_tags += 1
	attacker.streak += 1
	attacker.best_streak = maxi(attacker.best_streak, attacker.streak)
	var recent: Array[float] = []
	for time in attacker.recent_tags:
		if play_time - time <= MULTI_TAG_WINDOW:
			recent.append(time)
	recent.append(play_time)
	attacker.recent_tags = recent

	var color := color_for(attacker)
	if total_tags == 1:
		announce(attacker, call_out(attacker, "FIRST TAG!"), color, &"announce")
	if ended_streak >= SHUTDOWN_STREAK and victim != null:
		var whose := "YOUR" if victim.is_human else "%s'S" % victim.display_name.to_upper()
		var text := "SHUT DOWN! %s STREAK IS OVER" % whose if attacker.is_human \
				else call_out(attacker, "SHUT DOWN %s!" % ("YOU" if victim.is_human else victim.display_name.to_upper()))
		announce(attacker, text, color, &"shutdown")
	if recent.size() >= 2:
		var multi: String = MULTI_TAG_TEXT.get(recent.size(), MULTI_TAG_MAX_TEXT)
		announce(attacker, call_out(attacker, multi), color, &"streak")
	if STREAK_TEXT.has(attacker.streak):
		announce(attacker, call_out(attacker, STREAK_TEXT[attacker.streak]), color, &"streak")
	if mode.is_team_mode():
		_announce_team_lead()


## "BLUE TEAM TAKES THE LEAD!" whenever a different team goes out in front.
func _announce_team_lead() -> void:
	var leader := mode.winning_team(board)
	if leader < 0 or leader == _leading_team:
		return
	_leading_team = leader
	var mine := false
	for entry in board.entries:
		mine = mine or (entry.is_human and entry.team == leader)
	var text := "YOUR TEAM TAKES THE LEAD!" if mine else "%s TEAM TAKES THE LEAD!" % GameMode.team_name(leader)
	announce(null, text, GameMode.team_color(leader).lightened(0.3), &"announce")


func _on_fired(state_fired: WeaponState, actor: Actor) -> void:
	if state != State.PLAYING:
		return
	var entry := board.entry_for(actor)
	if entry == null:
		return
	entry.darts_fired += state_fired.data.darts_per_shot
	if state_fired.data.fire_mode == WeaponData.FireMode.SPIN_UP:
		entry.storm_darts += state_fired.data.darts_per_shot


func _on_landed_hit(_victim: Actor, _was_tag: bool, _was_ricochet: bool, actor: Actor) -> void:
	if state != State.PLAYING:
		return
	var entry := board.entry_for(actor)
	if entry != null:
		entry.hits_landed += 1


func _on_ammo_collected(amount: int, actor: Actor) -> void:
	if state != State.PLAYING:
		return
	var entry := board.entry_for(actor)
	if entry != null:
		entry.darts_collected += amount


## True if `point` is on this team's side of the yard (Blue vs Orange only;
## every point counts as home in other modes).
func is_home_spawn(team: int, point: Vector3) -> bool:
	if mode is ZombieMode or mode.teams != GameMode.Teams.BLUE_VS_ORANGE or arena.team_bases.size() < 2:
		return true
	var home := arena.team_bases[team % arena.team_bases.size()]
	var away := arena.team_bases[(team + 1) % arena.team_bases.size()]
	return point.distance_to(home) < point.distance_to(away)


func _spawn(actor: Actor) -> void:
	actor.respawn(_choose_spawn(actor))
	_equip(actor)


func _equip(actor: Actor) -> void:
	var entry := board.entry_for(actor)
	if entry == null:
		return
	actor.arsenal.set_loadout(mode.get_loadout(entry), mode.infinite_reserve)


## Picks a spawn point far from rivals, with a little randomness. In Blue vs
## Orange you always come back at your own end of the yard. In DUOS you spawn
## near your buddy.
func _choose_spawn(actor: Actor) -> Transform3D:
	if arena == null or arena.spawn_points.is_empty():
		return actor.global_transform
	var markers: Array[Marker3D] = []
	for marker in arena.spawn_points:
		if is_home_spawn(actor.team_id, marker.global_position):
			markers.append(marker)
	if markers.is_empty():
		markers = arena.spawn_points
	var scored: Array = []
	var free := 0
	var buddy := actor.buddy_actor if actor.buddy_actor != null and actor.buddy_actor.alive else null
	for marker in markers:
		var nearest_rival := 999.0
		var taken := false
		for other in actors:
			if other == actor or not other.alive:
				continue
			var distance := marker.global_position.distance_to(other.global_position)
			# Never on top of anyone, team-mates included: overlapping bodies get
			# pushed apart by the physics, which can fling them into the sky.
			taken = taken or distance < SPAWN_CLEARANCE
			if other.team_id != actor.team_id:
				nearest_rival = minf(nearest_rival, distance)
		if taken:
			scored.append([-1.0, marker])
		else:
			free += 1
			var score := nearest_rival
			if buddy != null:
				var dist_to_buddy := marker.global_position.distance_to(buddy.global_position)
				score += maxf(0.0, 32.0 - dist_to_buddy) * 2.0
			scored.append([score, marker])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var pick: Marker3D = scored[randi() % clampi(free, 1, min(free, 2))][1]
	return pick.global_transform


var _base_rings: Array[Node3D] = []


func _build_realistic_base_zones() -> void:
	if arena == null:
		return
	var bases := arena.team_bases
	if bases.is_empty():
		bases = [Vector3(-15.0, 0.0, 0.0), Vector3(15.0, 0.0, 0.0)]
	for i in bases.size():
		var b_pos := bases[i]
		var col := GameMode.team_color(i)
		var ring := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 3.6
		mesh.bottom_radius = 3.6
		mesh.height = 0.08
		mesh.radial_segments = 24
		ring.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(col.r, col.g, col.b, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(col.r, col.g, col.b)
		mat.emission_energy_multiplier = 0.5
		ring.material_override = mat
		ring.position = b_pos + Vector3(0.0, 0.04, 0.0)
		arena.decor.add_child(ring)
		_base_rings.append(ring)


func get_home_base_pos(actor: Actor) -> Vector3:
	if arena == null or arena.team_bases.is_empty():
		return Vector3.ZERO
	var team := actor.team_id
	if team >= 0 and team < arena.team_bases.size():
		return arena.team_bases[team]
	return arena.team_bases[0]


func _tick_realistic_bases() -> void:
	for actor in actors:
		if actor != null and is_instance_valid(actor) and actor.alive and actor.is_tagged_out:
			var home := get_home_base_pos(actor)
			if actor.global_position.distance_to(home) <= 3.8:
				actor.revive_at_base()
				var entry := board.entry_for(actor)
				if actor.is_human:
					popup.emit(actor, "SAFE! BACK IN PLAY!", UiKit.LIME)
					announce(entry, "REVIVED AT BASE!", UiKit.LIME, &"powerup")
				else:
					popup.emit(actor, "BACK IN PLAY!", UiKit.LIME)
					announce(entry, "%s REVIVED AT BASE!" % actor.display_name.to_upper(), UiKit.LIME, &"powerup")


# --- Capture The Flag (CTF) ---

func setup_ctf(ctf_mode: CaptureTheFlagMode, p_flags: Array[FlagPickup]) -> void:
	flags = p_flags
	for flag in flags:
		flag.picked_up.connect(func(_f: FlagPickup, carrier: Actor) -> void:
			var entry := board.entry_for(carrier)
			announce(entry, "%s TOOK THE %s FLAG!" % [carrier.display_name.to_upper(), GameMode.team_name(flag.team_id)], GameMode.team_color(flag.team_id).lightened(0.2), &"flag_pickup")
		)
		flag.dropped.connect(func(_f: FlagPickup, _pos: Vector3) -> void:
			announce(null, "%s FLAG DROPPED!" % GameMode.team_name(flag.team_id), GameMode.team_color(flag.team_id).lightened(0.2), &"powerup")
		)
		flag.returned.connect(func(_f: FlagPickup) -> void:
			announce(null, "%s FLAG RETURNED TO BASE!" % GameMode.team_name(flag.team_id), GameMode.team_color(flag.team_id).lightened(0.2), &"flag_capture")
		)
		flag.captured.connect(func(_f: FlagPickup, carrier: Actor) -> void:
			var entry := board.entry_for(carrier)
			if entry != null:
				entry.score += CaptureTheFlagMode.CAPTURE_SCORE
				board.notify_changed()
			ctf_mode.record_capture(carrier.team_id)
			announce(entry, "%s SCORED A CAPTURE FOR %s TEAM!" % [carrier.display_name.to_upper(), GameMode.team_name(carrier.team_id)], UiKit.LIME, &"win")
			popup.emit(carrier, "+%d FLAG CAPTURE!" % CaptureTheFlagMode.CAPTURE_SCORE, UiKit.LIME)
			if ctf_mode.is_won():
				announce(entry, "%s TEAM WINS CTF!" % GameMode.team_name(carrier.team_id), UiKit.LIME, &"win")
				_finish()
		)


func _tick_ctf_captures() -> void:
	if arena == null:
		return
	for flag in flags:
		if flag.state == FlagPickup.State.CARRIED and flag.carrier != null and is_instance_valid(flag.carrier) and flag.carrier.alive:
			var friendly_team := flag.carrier.team_id
			var home_ped := arena.get_flag_pedestal(friendly_team)
			if flag.carrier.global_position.distance_to(home_ped) <= FlagPickup.CAPTURE_RADIUS:
				flag.capture(flag.carrier)


# --- Plant The Bomb ---

func setup_bomb(bomb_mode: PlantTheBombMode, p_bomb_target: BombTarget) -> void:
	bomb_target = p_bomb_target
	bomb_target.bomb_picked_up.connect(func(carrier: Actor) -> void:
		var entry := board.entry_for(carrier)
		announce(entry, "%s HAS THE FOAM BOMB!" % carrier.display_name.to_upper(), UiKit.ORANGE_HOT, &"ammo")
	)
	bomb_target.bomb_dropped.connect(func(_pos: Vector3) -> void:
		announce(null, "THE FOAM BOMB WAS DROPPED!", UiKit.ORANGE_HOT, &"dry")
	)
	bomb_target.bomb_plant_started.connect(func(site: String, carrier: Actor) -> void:
		popup.emit(carrier, "ARMING BOMB AT SITE %s..." % site, UiKit.ORANGE_HOT)
	)
	bomb_target.bomb_planted.connect(func(site: String, _pos: Vector3) -> void:
		announce(null, "THE BOMB HAS BEEN PLANTED AT SITE %s!" % site, UiKit.ORANGE_HOT, &"bomb_plant")
	)
	bomb_target.bomb_defuse_started.connect(func(defuser: Actor) -> void:
		popup.emit(defuser, "DEFUSING BOMB...", UiKit.SKY)
	)
	bomb_target.bomb_defused.connect(func(defuser: Actor) -> void:
		var entry := board.entry_for(defuser)
		if entry != null:
			entry.score += PlantTheBombMode.DEFUSE_SCORE
			board.notify_changed()
		announce(entry, "BOMB DEFUSED! GUARDIANS WIN THE ROUND!", UiKit.SKY, &"bomb_defuse")
		popup.emit(defuser, "+%d BOMB DEFUSED!" % PlantTheBombMode.DEFUSE_SCORE, UiKit.SKY)
		bomb_mode.record_round_win(0)
		if bomb_mode.is_won():
			announce(null, "GUARDIANS WIN THE MATCH!", UiKit.SKY, &"win")
			_finish()
		else:
			_reset_bomb_round()
	)
	bomb_target.bomb_detonated.connect(func(site: String, _pos: Vector3) -> void:
		announce(null, "TARGET AT SITE %s DESTROYED! INFILTRATORS WIN THE ROUND!" % site, UiKit.ORANGE_HOT, &"bomb_detonate")
		bomb_mode.record_round_win(1)
		if bomb_mode.is_won():
			announce(null, "INFILTRATORS WIN THE MATCH!", UiKit.ORANGE_HOT, &"win")
			_finish()
		else:
			_reset_bomb_round()
	)


func _check_bomb_elimination() -> void:
	if not mode is PlantTheBombMode:
		return
	var bomb_mode := mode as PlantTheBombMode
	var living_defenders := 0
	var living_attackers := 0
	for actor in actors:
		if is_instance_valid(actor) and actor.alive and not actor.is_tagged_out:
			if actor.team_id == 0:
				living_defenders += 1
			elif actor.team_id == 1:
				living_attackers += 1

	if bomb_target != null and (bomb_target.state == BombTarget.BombState.PLANTED or bomb_target.state == BombTarget.BombState.DEFUSING):
		# If bomb is planted: defenders must defuse even if all attackers are tagged out!
		if living_defenders == 0:
			announce(null, "ALL GUARDIANS ELIMINATED! INFILTRATORS WIN THE ROUND!", UiKit.ORANGE_HOT, &"streak")
			bomb_mode.record_round_win(1)
			if bomb_mode.is_won():
				announce(null, "INFILTRATORS WIN THE MATCH!", UiKit.ORANGE_HOT, &"win")
				_finish()
			else:
				_reset_bomb_round()
	else:
		# Bomb not planted yet
		if living_attackers == 0:
			announce(null, "ALL INFILTRATORS ELIMINATED! GUARDIANS WIN THE ROUND!", UiKit.SKY, &"streak")
			bomb_mode.record_round_win(0)
			if bomb_mode.is_won():
				announce(null, "GUARDIANS WIN THE MATCH!", UiKit.SKY, &"win")
				_finish()
			else:
				_reset_bomb_round()
		elif living_defenders == 0:
			announce(null, "ALL GUARDIANS ELIMINATED! INFILTRATORS WIN THE ROUND!", UiKit.ORANGE_HOT, &"streak")
			bomb_mode.record_round_win(1)
			if bomb_mode.is_won():
				announce(null, "INFILTRATORS WIN THE MATCH!", UiKit.ORANGE_HOT, &"win")
				_finish()
			else:
				_reset_bomb_round()


func _reset_bomb_round() -> void:
	await get_tree().create_timer(2.0).timeout
	if state == State.ENDED:
		return
	for actor in actors:
		if is_instance_valid(actor):
			actor.is_tagged_out = false
			actor.alive = true
			actor.tag_meter = 0.0
			actor.meter_changed.emit(0.0, actor.tag_meter_max)
			_spawn(actor)
	if bomb_target != null:
		var b_spawn := arena.bomb_spawns[0] if (arena != null and not arena.bomb_spawns.is_empty()) else arena.team_bases[1] if (arena != null and arena.team_bases.size() > 1) else Vector3(0.0, 0.0, 15.0)
		var carrier: Actor = null
		for act in actors:
			if act.team_id == 1 and act.is_human:
				carrier = act
				break
		if carrier == null:
			for act in actors:
				if act.team_id == 1:
					carrier = act
					break
		bomb_target.spawn_bomb(b_spawn, carrier)


