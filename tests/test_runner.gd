extends Node3D
## Headless test suite. Run with:
##
##     godot --headless --path . res://tests/test_runner.tscn
##
## (or just ./tools/validate.sh). Exits 0 when everything passes, 1 otherwise.
## Tests are plain methods called from _ready(); `check()` records a result.

const POPPER := "res://resources/weapons/pocket_popper.tres"
const SPRAYER := "res://resources/weapons/dart_sprayer.tres"
const CHAINSTORM := "res://resources/weapons/flaxs_chainstorm.tres"
const FFA := "res://resources/modes/free_for_all.tres"
const GUN_GAME := "res://resources/modes/gun_game.tres"
const ZOMBIES_MODE := "res://resources/modes/zombies.tres"
const ZOMBIE_SIEGE_MODE := "res://resources/modes/zombie_siege.tres"
const WEAPON_DIR := "res://resources/weapons"

var _passed: int = 0
var _failed: int = 0
var _section: String = ""


func _ready() -> void:
	await _test_resources()
	await _test_dart_gravity()
	await _test_dart_wind()
	await _test_dart_ricochet()
	await _test_dart_no_tunnelling()
	await _test_dart_tags_actor()
	await _test_arsenal()
	await _test_ammo_bucket()
	await _test_scoring()
	await _test_navigation()
	await _test_bot_match()
	await _test_gun_game_match()
	# Hardening regressions (v0.1.1)
	await _test_ricochet_back_to_back()
	await _test_respawn_outside_play()
	await _test_bot_ammo_recovery()
	await _test_fx_budget()
	await _test_safe_loading()
	await _test_focus_pause()
	await _test_settings_reset()
	# Appeal pack and controller support (v0.2.0)
	await _test_controller_support()
	await _test_font_and_audio()
	await _test_announcer()
	await _test_customisation()
	await _test_podium_and_awards()
	await _test_backyard_props()
	await _test_power_up()
	# Linux build
	await _test_linux_export_preset()
	# The young players' design: team modes and their lobby
	await _test_team_rules()
	await _test_blue_vs_orange_match()
	await _test_duos_match()
	await _test_bot_hats()
	await _test_no_stacked_spawns()
	await _test_lobby()
	# Home Turf: the toy-sized house arena
	await _test_home_turf()
	await _test_home_turf_match()
	# Tempest Treehouse: high canopy decks and chasm
	await _test_tempest_treehouse()
	await _test_tempest_treehouse_match()
	await _test_elemental_gameplay()
	await _test_zombies_mode()
	await _test_shield_and_hazards()
	await _test_progression_and_shop()
	# Zombie Siege & Blaster Skins (v0.7.0)
	await _test_blaster_skins_and_shader()
	await _test_base_core_and_barricades()
	await _test_zombie_siege_and_director()
	await _test_zombie_siege_match()
	# Feedback, Pacing, Sniper ADS & Zombie Lunge (v0.7.1)
	await _test_kid_feedback_calibration_and_sniper()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	Sfx.quit_game(1 if _failed > 0 else 0)


# --- Helpers ------------------------------------------------------------------

func section(title: String) -> void:
	_section = title
	print("\n[%s]" % title)


func check(condition: bool, what: String) -> void:
	if condition:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what)
		push_error("Test failed: %s / %s" % [_section, what])


func physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func make_dart_data(speed: float, gravity: float = 0.0, drag: float = 0.0) -> DartData:
	var data := DartData.new()
	data.initial_speed = speed
	data.gravity_multiplier = gravity
	data.air_drag = drag
	data.max_lifetime = 10.0
	return data


func make_pool(parent: Node) -> DartPool:
	var pool := DartPool.new()
	parent.add_child(pool)
	return pool


func make_stage() -> Node3D:
	var stage := Node3D.new()
	add_child(stage)
	return stage


func make_actor(parent: Node, at: Vector3, team: int) -> Actor:
	var actor := Actor.new()
	actor.team_id = team
	actor.display_name = "Dummy %d" % team
	parent.add_child(actor)
	actor.global_position = at
	return actor


# --- Tests --------------------------------------------------------------------

func _test_resources() -> void:
	section("Resources load and are sane")
	var names := DirAccess.get_files_at(WEAPON_DIR)
	var count := 0
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		count += 1
		var weapon := load(WEAPON_DIR + "/" + file_name) as WeaponData
		check(weapon != null and weapon.dart != null, "%s loads with a dart" % file_name)
		if weapon != null:
			check(Sfx.has_sound(weapon.sound), "%s uses a real sound (%s)" % [file_name, weapon.sound])
	check(count >= 3, "at least three weapons exist (found %d)" % count)
	var ffa := load(FFA) as GameMode
	check(ffa != null and ffa.loadout.size() == 3, "free-for-all has a three-blaster loadout")
	check(ffa != null and is_equal_approx(ffa.duration_seconds, 300.0), "free-for-all is a five-minute round")
	var gun_game := load(GUN_GAME) as GunGameMode
	check(gun_game != null and gun_game.ladder.size() >= 3, "gun game ladder has at least three rungs")
	if gun_game != null and not gun_game.ladder.is_empty():
		check(gun_game.ladder[0].id == &"pocket_popper", "ladder starts with the Pocket Popper")
		check(gun_game.ladder[-1].id == &"flaxs_chainstorm", "ladder ends with Flax's Chainstorm")
	for action in [&"move_forward", &"jump", &"sprint", &"fire", &"reload", &"pause", &"scoreboard"]:
		check(InputMap.has_action(action), "input action '%s' exists" % action)
	await physics_frames(1)


func _test_dart_gravity() -> void:
	section("Darts drop under gravity")
	var stage := make_stage()
	var pool := make_pool(stage)
	var no_exclude: Array[RID] = []
	var dart := pool.fire(make_dart_data(40.0, 1.0), Vector3(0, 50, 0), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(30)
	var seconds := 30.0 / float(Engine.physics_ticks_per_second)
	var expected_drop := 0.5 * DartProjectile.GRAVITY * seconds * seconds
	var drop := 50.0 - dart.global_position.y
	check(absf(drop - expected_drop) < 0.15, "drop %.2fm matches physics %.2fm" % [drop, expected_drop])
	check(absf(dart.global_position.z + 40.0 * seconds) < 0.05, "travelled forward at launch speed")
	var flat := pool.fire(make_dart_data(40.0, 0.0), Vector3(5, 50, 0), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(20)
	check(absf(flat.global_position.y - 50.0) < 0.001, "gravity multiplier 0 flies level")
	stage.queue_free()


func _test_dart_wind() -> void:
	section("Wind zones curve darts")
	var stage := make_stage()
	var field := WindField.new()
	stage.add_child(field)
	var zone := WindZone.new()
	zone.size = Vector3(20, 20, 20)
	zone.direction = Vector3.RIGHT
	zone.strength = 30.0
	zone.show_fan = false
	stage.add_child(zone)
	zone.global_position = Vector3(0, 50, -15)
	field.register_zone(zone)
	var pool := make_pool(stage)
	pool.wind_field = field
	check(field.get_wind_at(Vector3(0, 50, -15)).is_equal_approx(Vector3.RIGHT * 30.0), "wind inside the zone is 30 to the right")
	check(field.get_wind_at(Vector3(0, 50, 20)).is_zero_approx(), "no wind outside the zone")
	var no_exclude: Array[RID] = []
	var dart := pool.fire(make_dart_data(40.0), Vector3(0, 50, 0), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	var heavy_data := make_dart_data(40.0)
	heavy_data.wind_response = 0.0
	var heavy := pool.fire(heavy_data, Vector3(0, 52, 0), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(30)
	check(dart.global_position.x > 1.0, "dart was blown sideways (%.2fm)" % dart.global_position.x)
	check(absf(heavy.global_position.x) < 0.001, "a dart with wind_response 0 ignores wind")
	stage.queue_free()


func _test_dart_ricochet() -> void:
	section("Reflective surfaces bounce darts")
	var stage := make_stage()
	var pool := make_pool(stage)
	var mirror := ReflectiveSurface.new()
	mirror.panel_size = Vector2(6, 6)
	stage.add_child(mirror)
	mirror.global_position = Vector3(0, 50, -10)
	var wall := ArenaKit.box(stage, Vector3(6, 6, 0.3), Vector3(20, 50, -10), Color.WHITE)
	await physics_frames(2)

	var impacts: Array[int] = []
	pool.impact.connect(func(kind: int, _at: Vector3, _normal: Vector3, _color: Color) -> void: impacts.append(kind))
	var data := make_dart_data(40.0)
	data.max_ricochets = 1
	data.ricochet_speed_keep = 0.75
	var no_exclude: Array[RID] = []
	# 45 degree approach: (1, 0, -1) should leave as (1, 0, 1).
	var dart := pool.fire(data, Vector3(-4, 50, -6), Vector3(1, 0, -1), null, null, Color.WHITE, no_exclude)
	await physics_frames(14)
	check(dart.ricochet_count == 1, "ricochet count went up to 1")
	var out := dart.velocity.normalized()
	check(out.is_equal_approx(Vector3(1, 0, 1).normalized()), "reflected around the surface normal")
	check(absf(dart.velocity.length() - 30.0) < 0.5, "speed reduced to 75%% (%.1f)" % dart.velocity.length())
	check(impacts.has(DartProjectile.Impact.RICOCHET), "a ricochet impact was reported")

	# The same dart type just stops on an ordinary wall.
	var blocked := pool.fire(data, Vector3(20, 50, -6), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(14)
	check(blocked.ricochet_count == 0, "ordinary walls do not reflect")
	check(blocked.global_position.z > -10.0, "dart stayed on the near side of the wall")

	# Bouncy darts ricochet off anything, up to their limit.
	var bouncy := make_dart_data(40.0)
	bouncy.ricochet_any_surface = true
	bouncy.max_ricochets = 2
	var ranger := pool.fire(bouncy, Vector3(20, 50, -6), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(14)
	check(ranger.ricochet_count == 1 and ranger.velocity.z > 0.0, "ricochet_any_surface bounces off walls")
	wall.queue_free()
	stage.queue_free()


func _test_dart_no_tunnelling() -> void:
	section("Fast darts cannot tunnel through thin walls")
	var stage := make_stage()
	var pool := make_pool(stage)
	ArenaKit.box(stage, Vector3(10, 10, 0.05), Vector3(0, 50, -10), Color.WHITE)
	await physics_frames(2)
	var no_exclude: Array[RID] = []
	# 400 m/s is almost 7 metres per tick: far more than the 5cm wall.
	var dart := pool.fire(make_dart_data(400.0), Vector3(0, 50, 0), Vector3.FORWARD, null, null, Color.WHITE, no_exclude)
	await physics_frames(10)
	check(dart.global_position.z > -10.1, "dart stopped at the wall (z = %.2f)" % dart.global_position.z)
	stage.queue_free()


func _test_dart_tags_actor() -> void:
	section("Darts fill the tag meter and tag actors out")
	var stage := make_stage()
	var pool := make_pool(stage)
	ArenaKit.box(stage, Vector3(30, 1, 30), Vector3(0, -0.5, 0), Color.WHITE)
	var shooter := make_actor(stage, Vector3(0, 0, 8), 1)
	var victim := make_actor(stage, Vector3(0, 0, 0), 2)
	victim.spawn_protection = 0.0
	await physics_frames(2)

	var tagged: Array = []
	victim.tagged_out.connect(func(v: Actor, a: Actor, _w: WeaponData, r: bool) -> void: tagged.append([v, a, r]))
	var hits: Array[bool] = []
	shooter.landed_hit.connect(func(_victim: Actor, was_tag: bool, _ricochet: bool) -> void: hits.append(was_tag))

	var data := make_dart_data(40.0)
	data.tag_power = 40.0
	var exclude: Array[RID] = [shooter.hitbox.get_rid()]
	var from := Vector3(0, 1.0, 7)
	pool.fire(data, from, Vector3.FORWARD, shooter, null, Color.WHITE, exclude)
	await physics_frames(15)
	check(is_equal_approx(victim.tag_meter, 40.0), "one hit filled the meter by tag_power (%.0f)" % victim.tag_meter)
	check(victim.alive, "victim is still in play after one hit")
	pool.fire(data, from, Vector3.FORWARD, shooter, null, Color.WHITE, exclude)
	pool.fire(data, from + Vector3(0.1, 0, 0), Vector3.FORWARD, shooter, null, Color.WHITE, exclude)
	await physics_frames(15)
	check(not victim.alive, "three hits tagged the victim out")
	check(tagged.size() == 1 and tagged[0][1] == shooter, "tagged_out named the right attacker")
	check(hits.size() == 3 and hits[2], "attacker heard about every hit and the tag")

	# Own-team darts pass straight through.
	var friend := make_actor(stage, Vector3(4, 0, 0), 1)
	friend.spawn_protection = 0.0
	await physics_frames(2)
	pool.fire(data, Vector3(4, 1.0, 7), Vector3.FORWARD, shooter, null, Color.WHITE, exclude)
	await physics_frames(15)
	check(is_zero_approx(friend.tag_meter), "team-mates are not hurt by friendly darts")

	# Respawn resets everything.
	victim.respawn(Transform3D(Basis.IDENTITY, Vector3(-4, 0, 0)))
	check(victim.alive and is_zero_approx(victim.tag_meter), "respawn restores a fresh tag meter")
	stage.queue_free()


func _test_arsenal() -> void:
	section("Arsenal: fire modes, magazines, reloads, spin-up")
	var stage := make_stage()
	var arsenal := Arsenal.new()
	stage.add_child(arsenal)
	var loadout: Array[WeaponData] = [load(POPPER), load(SPRAYER), load(CHAINSTORM)]
	arsenal.set_loadout(loadout)
	var shots: Array[int] = [0]
	arsenal.fired.connect(func(_state: WeaponState) -> void: shots[0] += 1)
	var ticks := Engine.physics_ticks_per_second

	# Semi-auto: holding the trigger gives exactly one shot.
	var popper := arsenal.current()
	arsenal.set_trigger(true)
	await physics_frames(30)
	check(shots[0] == 1, "semi-auto fires once per trigger pull (got %d)" % shots[0])
	check(popper.magazine == popper.data.magazine_size - 1, "magazine went down by one")
	arsenal.set_trigger(false)
	await physics_frames(2)

	# Emptying the magazine triggers a reload from the reserve.
	for i in popper.data.magazine_size - 1:
		arsenal.set_trigger(true)
		await physics_frames(int(ticks / popper.data.shots_per_second) + 2)
		arsenal.set_trigger(false)
		await physics_frames(1)
	check(popper.magazine == 0, "magazine is empty after %d shots" % popper.data.magazine_size)
	var reserve_before := popper.reserve
	await physics_frames(int(popper.data.reload_time * ticks) + 6)
	check(popper.magazine == popper.data.magazine_size, "empty magazine reloaded automatically")
	check(popper.reserve == reserve_before - popper.data.magazine_size, "reload took darts from the reserve")

	# Full-auto keeps firing at roughly its rate.
	arsenal.select(1, true)
	shots[0] = 0
	arsenal.set_trigger(true)
	await physics_frames(ticks)
	arsenal.set_trigger(false)
	var sprayer := arsenal.current()
	check(absi(shots[0] - int(sprayer.data.shots_per_second)) <= 1, "full-auto fired ~%d shots in a second (got %d)" % [int(sprayer.data.shots_per_second), shots[0]])
	await physics_frames(2)

	# Chainstorm: nothing until spun up, then a storm, straight from the belt.
	arsenal.select(2, true)
	var chain := arsenal.current()
	shots[0] = 0
	arsenal.set_trigger(true)
	await physics_frames(int(chain.data.spin_up_time * ticks * 0.5))
	check(shots[0] == 0, "Chainstorm does not fire while still spinning up")
	check(arsenal.get_move_multiplier() < 1.0, "Chainstorm slows its owner while spinning")
	var belt_before := chain.reserve
	await physics_frames(int(chain.data.spin_up_time * ticks * 0.5) + ticks + 2)
	arsenal.set_trigger(false)
	check(shots[0] >= int(chain.data.shots_per_second * 0.9), "Chainstorm fired %d darts in about a second" % shots[0])
	check(chain.reserve == belt_before - shots[0], "Chainstorm is belt-fed from its reserve")
	check(chain.data.shots_per_second > sprayer.data.shots_per_second * 2.0, "Chainstorm is much faster than the Sprayer")

	# Ammo pickup respects capacity.
	var missing := chain.missing()
	var taken := arsenal.add_ammo(100000)
	check(taken >= missing and arsenal.total_missing() == 0, "add_ammo fills every weapon and no more")
	stage.queue_free()
	await physics_frames(1)


func _test_ammo_bucket() -> void:
	section("Ammo buckets refill, drain and regenerate")
	var stage := make_stage()
	ArenaKit.box(stage, Vector3(30, 1, 30), Vector3(0, -0.5, 0), Color.WHITE)
	var bucket := (load("res://scenes/pickups/ammo_bucket.tscn") as PackedScene).instantiate() as AmmoBucket
	bucket.capacity = 40
	bucket.regen_delay = 0.5
	bucket.transfer_per_second = 600.0
	stage.add_child(bucket)
	var actor := make_actor(stage, Vector3(1.2, 0, 0), 1)
	var loadout: Array[WeaponData] = [load(CHAINSTORM)]
	actor.arsenal.set_loadout(loadout)
	var belt := actor.arsenal.current()
	var before := belt.reserve
	await physics_frames(20)
	check(belt.reserve == before + 40, "actor received the whole bucket (%d darts)" % (belt.reserve - before))
	check(bucket.is_empty(), "bucket is empty after being drained")
	await physics_frames(int(0.5 * Engine.physics_ticks_per_second) + 4)
	check(bucket.stock > 0 or belt.reserve > before + 40, "bucket regenerated after its delay")
	stage.queue_free()
	await physics_frames(1)


func _test_scoring() -> void:
	section("Scoring: free-for-all and Gun Game")
	var stage := make_stage()
	var a := make_actor(stage, Vector3(0, 100, 0), 1)
	var b := make_actor(stage, Vector3(5, 100, 0), 2)

	var ffa := (load(FFA) as GameMode).duplicate() as GameMode
	var board := Scoreboard.new()
	var entry_a := board.add_actor(a)
	var entry_b := board.add_actor(b)
	check(ffa.apply_tag(entry_a, entry_b, false) == 100, "a tag is worth 100 points")
	check(ffa.apply_tag(entry_a, entry_b, true) == 150, "a ricochet tag earns the +50 bonus")
	check(entry_a.score == 250, "points accumulate on the scoreboard")
	check(ffa.rank(board)[0] == entry_a, "ranking puts the top scorer first")
	check(ffa.get_early_winner(board) == null, "free-for-all only ends on the clock")

	var gun_game := (load(GUN_GAME) as GunGameMode).duplicate() as GunGameMode
	var board2 := Scoreboard.new()
	var climber := board2.add_actor(a)
	var other := board2.add_actor(b)
	check(gun_game.get_loadout(climber)[0].id == &"pocket_popper", "everyone starts on the Pocket Popper")
	gun_game.apply_tag(climber, other, false)
	check(climber.tier == 1, "a tag climbs one rung")
	check(gun_game.get_loadout(climber)[0] == gun_game.ladder[1], "loadout follows the ladder")
	for i in gun_game.ladder.size() - 2:
		gun_game.apply_tag(climber, other, false)
	check(gun_game.get_early_winner(board2) == null, "no winner while still holding the last blaster")
	check(gun_game.get_loadout(climber)[0].id == &"flaxs_chainstorm", "the last rung is Flax's Chainstorm")
	gun_game.apply_tag(climber, other, false)
	check(gun_game.get_early_winner(board2) == climber, "a tag with the last blaster wins Gun Game")
	stage.queue_free()
	await physics_frames(1)


func _test_navigation() -> void:
	section("Backyard Fortress navigation")
	var arena := (load("res://scenes/arenas/backyard_fortress.tscn") as PackedScene).instantiate() as Arena
	add_child(arena)
	var map := arena.geometry.get_navigation_map()
	# The navmesh is baked on a worker thread, then the map syncs a frame or two later.
	check(not arena.is_navigation_ready, "navmesh bake runs in the background (arena loads without waiting)")
	var waited := 0
	while not arena.is_navigation_ready and waited < 600:
		await get_tree().physics_frame
		waited += 1
	check(arena.is_navigation_ready, "background navmesh bake finished (after %d frames)" % waited)
	check(arena.geometry.navigation_mesh.get_polygon_count() > 100, "navmesh baked (%d polygons)" % arena.geometry.navigation_mesh.get_polygon_count())
	var probe_from := Vector3(-28.5, 2.6, 3.0)
	var probe_to := Vector3(28.5, 2.6, 3.0)
	waited = 0
	while NavigationServer3D.map_get_path(map, probe_from, probe_to, true).is_empty() and waited < 300:
		await get_tree().physics_frame
		waited += 1
	check(NavigationServer3D.map_get_iteration_id(map) > 0, "navigation map synchronised (after %d more frames)" % waited)
	check(arena.spawn_points.size() >= 8, "arena has %d spawn points" % arena.spawn_points.size())
	check(arena.buckets.size() >= 4, "arena has %d ammo buckets" % arena.buckets.size())
	check(get_tree().get_nodes_in_group(&"reflective").size() == 2, "arena has two reflective panels")
	check(get_tree().get_nodes_in_group(&"wind_zones").size() == 1, "arena has one wind zone")
	check(arena.wind_field.get_wind_at(Vector3(0, 2, 17)).length() > 10.0, "it is windy in Windy Way")
	check(arena.wind_field.get_wind_at(Vector3(-20, 2, -10)).is_zero_approx(), "it is calm elsewhere")

	var blue := Vector3(-28.5, 2.6, 3.0)
	var orange := Vector3(28.5, 2.6, 3.0)
	var across := NavigationServer3D.map_get_path(map, blue, orange, true)
	check(across.size() >= 2 and across[-1].distance_to(orange) < 1.5, "bots can path from the blue fort to the orange fort")
	var deck := Vector3(0.0, 4.6, 3.2)
	var up := NavigationServer3D.map_get_path(map, Vector3(-20, 0, -18), deck, true)
	check(up.size() >= 2 and up[-1].distance_to(deck) < 1.5, "bots can path from the lawn up to the treehouse deck")
	var reachable := 0
	for point in arena.roam_points:
		var path := NavigationServer3D.map_get_path(map, Vector3(0, 0, 8), point, true)
		if path.size() >= 2 and path[-1].distance_to(point) < 2.0:
			reachable += 1
	check(reachable == arena.roam_points.size(), "every roam point is reachable (%d/%d)" % [reachable, arena.roam_points.size()])
	arena.queue_free()
	await physics_frames(2)


## Plays a sped-up match with only bots acting and checks that a real game
## happens: they move, shoot, tag each other, respawn and the round ends.
func _test_bot_match() -> void:
	section("Bots play a whole match (fast-forward)")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	var saved_difficulty := GameSettings.bot_difficulty
	GameSettings.match_mode = GameSettings.MatchMode.FREE_FOR_ALL
	GameSettings.bot_count = 3
	GameSettings.bot_difficulty = 2

	var game := (load("res://scenes/game/match.tscn") as PackedScene).instantiate()
	add_child(game)
	var controller := game.get("controller") as MatchController
	var bots: Array = game.get("bots")
	var pool := game.get("dart_pool") as DartPool
	check(controller != null and bots.size() == 3, "match scene built with 3 bots")
	check(controller.state == MatchController.State.COUNTDOWN, "match starts with a countdown")
	var start_positions: Array[Vector3] = []
	for bot: Bot in bots:
		start_positions.append(bot.global_position)

	var ended: Array = []
	controller.match_ended.connect(func(ranking: Array[ScoreEntry]) -> void: ended.append(ranking))
	var respawns: Array[int] = [0]
	for bot: Bot in bots:
		bot.respawned.connect(func(_actor: Actor) -> void: respawns[0] += 1)

	# Fast-forward: 8x the ticks at 8x time scale keeps each tick at 1/60s.
	var normal_ticks := Engine.physics_ticks_per_second
	var normal_max_steps := Engine.max_physics_steps_per_frame
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = normal_ticks * 8
	Engine.max_physics_steps_per_frame = 64
	var max_darts := 0
	var simulated := 0.0
	var step := 1.0 / float(normal_ticks)
	while simulated < 75.0:
		await get_tree().physics_frame
		simulated += step
		max_darts = maxi(max_darts, pool.live_count())
	check(controller.state == MatchController.State.PLAYING, "countdown finished and play began")
	var moved := 0
	for i in bots.size():
		if (bots[i] as Bot).global_position.distance_to(start_positions[i]) > 3.0:
			moved += 1
	check(moved >= 2, "bots moved around the arena (%d of 3)" % moved)
	check(max_darts > 0, "bots fired darts (peak %d in the air)" % max_darts)
	check(max_darts <= pool.max_active, "live darts stayed within the pool cap")
	var total_tags := 0
	for entry in controller.board.entries:
		total_tags += entry.tags
	check(total_tags > 0, "bots tagged someone within 75 seconds (%d tags)" % total_tags)
	check(respawns[0] > 3, "tagged actors respawned (%d respawns incl. initial)" % respawns[0])

	# Jump to the end of the round.
	controller.time_left = 0.5
	while simulated < 78.0:
		await get_tree().physics_frame
		simulated += step
	check(controller.state == MatchController.State.ENDED, "round ends when the clock runs out")
	check(ended.size() == 1 and ended[0].size() == 4, "end-of-round ranking lists all four players")
	var frozen := true
	for actor in controller.actors:
		frozen = frozen and not actor.controls_enabled
	check(frozen, "everyone is frozen after the match ends")

	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = normal_ticks
	Engine.max_physics_steps_per_frame = normal_max_steps
	GameSettings.match_mode = saved_mode
	GameSettings.bot_count = saved_bots
	GameSettings.bot_difficulty = saved_difficulty
	game.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await physics_frames(2)


## Gun Game boots, hands everyone the first rung with bottomless ammo, and
## promotes a bot to the next blaster when it scores a tag.
func _test_gun_game_match() -> void:
	section("Gun Game match")
	var saved_mode := GameSettings.match_mode
	GameSettings.match_mode = GameSettings.MatchMode.GUN_GAME
	var game := (load("res://scenes/game/match.tscn") as PackedScene).instantiate()
	add_child(game)
	var controller := game.get("controller") as MatchController
	check(controller.mode is GunGameMode, "Gun Game mode loaded")
	var everyone_on_popper := true
	for actor in controller.actors:
		var held := actor.arsenal.current()
		everyone_on_popper = everyone_on_popper and actor.arsenal.weapons.size() == 1 \
				and held.data.id == &"pocket_popper" and held.infinite_reserve
	check(everyone_on_popper, "everyone starts with just the Pocket Popper and bottomless ammo")

	# Force play to start, then score a tag for the first bot.
	controller.time_left = controller.mode.duration_seconds
	while controller.state != MatchController.State.PLAYING:
		await get_tree().physics_frame
	var bots: Array = game.get("bots")
	var hunter := bots[0] as Bot
	var prey := bots[1] as Bot
	prey.spawn_protection = 0.0
	prey._protect_left = 0.0
	prey._tag_out(hunter, hunter.arsenal.current().data, false)
	await physics_frames(2)
	var hunter_held := hunter.arsenal.current()
	check(hunter_held != null and hunter_held.data.id == &"double_trouble", "a tag promotes the bot to Double Trouble")
	check(controller.board.entry_for(hunter).tier == 1, "the scoreboard tracks the new rung")

	GameSettings.match_mode = saved_mode
	game.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await physics_frames(2)


# --- Hardening regressions (v0.1.1) ------------------------------------------

## Runs `seconds` of game time about `speed` times faster than real time, while
## keeping every physics tick at the normal 1/60 s so behaviour is unchanged.
func fast_forward(seconds: float, speed: float = 8.0) -> void:
	var normal_ticks := Engine.physics_ticks_per_second
	var normal_steps := Engine.max_physics_steps_per_frame
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(normal_ticks * speed)
	Engine.max_physics_steps_per_frame = 64
	for i in int(seconds * normal_ticks):
		await get_tree().physics_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = normal_ticks
	Engine.max_physics_steps_per_frame = normal_steps


## Builds a match with the given mode. Pair with end_match().
func start_match(mode: int) -> Node:
	GameSettings.match_mode = mode
	var game := (load("res://scenes/game/match.tscn") as PackedScene).instantiate()
	add_child(game)
	return game


func end_match(game: Node, saved_mode: int) -> void:
	get_tree().paused = false
	GameSettings.match_mode = saved_mode
	game.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await physics_frames(2)


## H2: a dart between two facing mirrors bounces back and forth faster than
## the 0.08 s re-hit guard. Each mirror must become hittable again on its own.
func _test_ricochet_back_to_back() -> void:
	section("Hardening: back-to-back ricochets")
	var stage := make_stage()
	var pool := make_pool(stage)
	for side: float in [-1.0, 1.0]:
		var mirror := ReflectiveSurface.new()
		mirror.panel_size = Vector2(24, 6)
		stage.add_child(mirror)
		mirror.global_position = Vector3(side * 0.75, 50, -8)
		mirror.rotation_degrees.y = -90.0 * side  # Both faces point at the gap.
	await physics_frames(2)
	var data := make_dart_data(40.0)
	data.max_ricochets = 3
	data.ricochet_speed_keep = 1.0
	var no_exclude: Array[RID] = []
	var dart := pool.fire(data, Vector3(0, 50, 0), Vector3(1, 0, -1), null, null, Color.WHITE, no_exclude)
	await physics_frames(20)
	check(dart.ricochet_count == 3, "dart bounced between two close mirrors 3 times (got %d)" % dart.ricochet_count)
	check(absf(dart.global_position.x) < 0.75, "dart never slipped through a mirror (x = %.2f)" % dart.global_position.x)
	stage.queue_free()
	await physics_frames(1)


## H3: an actor tagged out outside normal play (e.g. falling off the map during
## the countdown) still comes back, and nobody scores for it.
func _test_respawn_outside_play() -> void:
	section("Hardening: tagged-out actors always respawn")
	var saved_mode := GameSettings.match_mode
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	var bots: Array = game.get("bots")
	var bot := bots[0] as Bot
	check(controller.state == MatchController.State.COUNTDOWN, "still in the countdown")
	bot._tag_out(null, null, false)
	check(not bot.alive, "bot tagged out during the countdown")
	check(controller.respawn_time_left(bot) > 0.0, "a respawn was scheduled anyway")
	# Checked straight away: once play starts, bots may legitimately tag each other.
	var entry := controller.board.entry_for(bot)
	check(entry.outs == 0 and entry.score == 0, "nothing was scored for a tag-out outside play")
	await fast_forward(controller.mode.countdown_seconds + controller.mode.respawn_delay + 0.5)
	check(bot.alive, "bot is back in play")
	await end_match(game, saved_mode)


## H4: bots drop an empty blaster immediately, and a bot with no darts at all
## waits at a bucket rather than chasing people it can't tag.
func _test_bot_ammo_recovery() -> void:
	section("Hardening: bots never get stuck without darts")
	var stage := make_stage()
	ArenaKit.box(stage, Vector3(60, 1, 60), Vector3(0, -0.5, 0), Color.WHITE)
	var arena := Arena.new()
	arena.bake_navigation = false
	stage.add_child(arena)
	var east := arena.add_bucket(Vector3(6, 0, 0), Color.WHITE, 50)
	var west := arena.add_bucket(Vector3(-20, 0, 0), Color.WHITE, 50)
	var bot := (load("res://scenes/enemies/bot.tscn") as PackedScene).instantiate() as Bot
	bot.arena = arena
	bot.difficulty = load("res://resources/bots/normal.tres") as BotDifficulty
	stage.add_child(bot)
	bot.global_position = Vector3.ZERO
	await physics_frames(2)
	var loadout: Array[WeaponData] = [load(CHAINSTORM), load(POPPER)]
	bot.arsenal.set_loadout(loadout)
	bot.arsenal.current().reserve = 0
	bot._weapon_lock_left = 99.0  # Even mid weapon-lock...
	bot.controls_enabled = true
	await physics_frames(40)
	check(bot.arsenal.current().data.id == &"pocket_popper", "bot swapped off its empty Chainstorm straight away")

	# Now empty everything: the bot and both buckets.
	for state in bot.arsenal.weapons:
		state.magazine = 0
		state.reserve = 0
	for bucket: AmmoBucket in [east, west]:
		bucket.stock = 0
		bucket._regen_left = 999.0
	await physics_frames(40)
	var nearest := east
	if bot.global_position.distance_to(west.global_position) < bot.global_position.distance_to(east.global_position):
		nearest = west
	check(bot._mood == Bot.Mood.RESUPPLY, "a dry bot heads for a bucket even when every bucket is empty")
	check(bot._goal.distance_to(nearest.global_position) < 0.1, "it waits at the nearest bucket")
	stage.queue_free()
	await physics_frames(2)


## H6: ordinary impact bursts are budgeted; tag-out bursts always show.
func _test_fx_budget() -> void:
	section("Hardening: effects budget")
	var saved_intensity := GameSettings.visual_intensity
	GameSettings.visual_intensity = 1.0
	var stage := make_stage()
	await get_tree().process_frame
	var before := FoamBurst.live_count()
	var shown := 0
	for i in 500:
		if FoamBurst.spawn(stage, Vector3(0, 50, 0), Color.WHITE, 10):
			shown += 1
	check(shown <= FoamBurst.MAX_PER_FRAME, "500 impacts in one frame started only %d bursts" % shown)
	for frame in 30:
		for i in 20:
			FoamBurst.spawn(stage, Vector3(0, 50, 0), Color.WHITE, 10)
		await get_tree().process_frame
	var live := FoamBurst.live_count() - before
	check(live <= FoamBurst.live_cap(), "live bursts stay under the cap (%d of %d)" % [live, FoamBurst.live_cap()])
	check(FoamBurst.spawn(stage, Vector3(0, 50, 0), Color.WHITE, 10, 4.0, Vector3.UP, true),
			"a tag-out burst still shows when the budget is spent")
	stage.queue_free()
	await physics_frames(2)
	check(FoamBurst.live_count() == before, "the live counter drops back when bursts are freed")
	GameSettings.visual_intensity = saved_intensity


## H7: missing or broken data files fall back to defaults instead of crashing.
func _test_safe_loading() -> void:
	section("Hardening: broken data never crashes a match")
	check(MatchScene.try_load("res://does/not/exist.tres") == null, "a missing file loads as null instead of crashing")
	check(MatchScene.load_or_fallback("res://does/not/exist.tres", FFA) is GameMode, "a missing mode falls back to free-for-all")
	check(MatchScene.resolve_mode(99) is GameMode, "an out-of-range mode choice is still playable")
	check(MatchScene.resolve_mode(GameSettings.MatchMode.GUN_GAME) is GunGameMode, "Gun Game resolves normally")
	check(MatchScene.resolve_difficulty(-5) is BotDifficulty, "an out-of-range bot skill is still usable")
	await physics_frames(1)


## H1: alt-tab (focus lost) pauses a running match, but not a finished one.
func _test_focus_pause() -> void:
	section("Hardening: losing window focus pauses the match")
	var saved_mode := GameSettings.match_mode
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	var pause := game.get("pause_menu") as PauseMenu
	check(not get_tree().paused, "match starts unpaused")
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(get_tree().paused and pause.is_open(), "losing focus pauses the game and shows the pause menu")
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(pause.is_open(), "losing focus again while paused is harmless")
	pause.close()
	check(not get_tree().paused and not pause.is_open(), "resume unpauses")
	controller._finish()
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not get_tree().paused, "the results screen is not covered by a pause menu")
	await end_match(game, saved_mode)


## H10: "Reset to defaults" restores every preference.
func _test_settings_reset() -> void:
	section("Hardening: settings reset")
	var saved := {}
	for key: String in GameSettings.DEFAULTS:
		saved[key] = GameSettings.get(key)
	GameSettings.mouse_sensitivity = 2.7
	GameSettings.camera_shake = 0.0
	GameSettings.fov = 104.0
	GameSettings.invert_y = true
	check(not GameSettings.is_default(), "changed settings differ from the defaults")
	var panel := SettingsPanel.new()
	add_child(panel)
	panel._reset()
	check(GameSettings.is_default(), "the RESET TO DEFAULTS button restores every factory value")
	check(is_equal_approx(GameSettings.fov, 85.0) and not GameSettings.invert_y, "e.g. FOV is 85 and look is not inverted")
	panel.queue_free()
	for key: String in saved:
		GameSettings.set(key, saved[key])
	GameSettings.apply()
	await physics_frames(1)


# --- Appeal pack and controller support (v0.2.0) ------------------------------

func _has_pad_event(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _pad_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _test_controller_support() -> void:
	section("Controller: plug and play")
	for action in [&"ui_accept", &"ui_cancel", &"move_forward", &"move_left", &"look_left", &"look_up",
			&"jump", &"sprint", &"fire", &"reload", &"weapon_next", &"weapon_prev", &"pause", &"scoreboard"]:
		check(_has_pad_event(action), "'%s' works on a controller" % action)
	var saved_mode := GameSettings.match_mode
	var saved_assist := GameSettings.aim_assist
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	var player := game.get("player") as Player
	var pause := game.get("pause_menu") as PauseMenu
	await physics_frames(2)

	# Right stick turns the view (looking is allowed even during the countdown).
	var yaw_before := player.rotation.y
	_pad_axis(JOY_AXIS_RIGHT_X, 1.0)
	await physics_frames(10)
	_pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	await physics_frames(1)
	check(absf(player.rotation.y - yaw_before) > 0.18, "right stick turns the player (%.2f rad)" % absf(player.rotation.y - yaw_before))
	check(player.pad_look_step(Vector2(0.3, 0.0), 1.0).length() < player.pad_look_step(Vector2(1.0, 0.0), 1.0).length() * 0.2,
			"small stick nudges turn much slower than full tilt (fine aim)")

	# Right trigger fires once play starts.
	await fast_forward(controller.mode.countdown_seconds + 0.3)
	var shots: Array[int] = [0]
	player.arsenal.fired.connect(func(_state: WeaponState) -> void: shots[0] += 1)
	player.arsenal.select(0, true)
	_pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await physics_frames(6)
	_pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await physics_frames(2)
	check(shots[0] >= 1, "right trigger fires the blaster")

	# Aim assist: turning slows while the crosshair is over a rival.
	var bots: Array = game.get("bots")
	var rival := bots[0] as Bot
	var eye := player.head.global_transform
	rival.global_position = Vector3(eye.origin.x, player.global_position.y, eye.origin.z) - eye.basis.z * 6.0
	rival.velocity = Vector3.ZERO
	await physics_frames(2)
	GameSettings.aim_assist = true
	var assisted := player.pad_look_step(Vector2(1.0, 0.0), 1.0).length()
	GameSettings.aim_assist = false
	var free := player.pad_look_step(Vector2(1.0, 0.0), 1.0).length()
	check(player.crosshair_on_rival(), "crosshair detects a rival straight ahead")
	check(assisted < free * 0.75, "aim assist slows turning over a rival (%.2f vs %.2f)" % [assisted, free])
	GameSettings.aim_assist = saved_assist

	# Hot-plug: a notice on connect, and a pause when the pad is unplugged mid-match.
	var notices := GameSettings.notice_count()
	GameSettings._on_joy_connection_changed(0, true)
	check(GameSettings.notice_count() > notices, "plugging in a controller shows a notice")
	check(GameSettings.using_controller, "the game switches to controller mode")
	GameSettings._on_joy_connection_changed(0, false)
	check(get_tree().paused and pause.is_open(), "unplugging the controller mid-match pauses the game")
	pause.close()
	GameSettings.vibrate(0.5, 0.5, 0.1)  # No pad connected: must simply do nothing.
	check(true, "rumble with no controller connected is harmless")
	GameSettings.using_controller = false
	await end_match(game, saved_mode)


func _test_font_and_audio() -> void:
	section("Chunky font, music and sounds")
	var font_file := UiKit.font().base_font
	check(font_file != null and font_file.resource_path.ends_with("LilitaOne-Regular.ttf"), "UI uses the Lilita One font")
	check(get_tree().root.theme != null and get_tree().root.theme.default_font == UiKit.font(), "every Control defaults to the chunky font")
	check(AudioServer.get_bus_index(&"Music") >= 0 and AudioServer.get_bus_index(&"SFX") >= 0, "Music and SFX audio buses exist")
	var waited := 0
	while (not Sfx.is_music_ready(&"menu") or not Sfx.is_music_ready(&"match")) and waited < 900:
		await get_tree().process_frame
		waited += 1
	check(Sfx.is_music_ready(&"menu") and Sfx.is_music_ready(&"match"), "both music loops rendered in the background (%d frames)" % waited)
	check(Sfx.music_length(&"match") > 10.0 and Sfx.music_length(&"menu") > 8.0,
			"music loops are a decent length (%.1f s / %.1f s)" % [Sfx.music_length(&"match"), Sfx.music_length(&"menu")])
	Sfx.play_music(&"match")
	check(Sfx.current_music() == &"match", "play_music switches tracks")
	Sfx.stop_music()
	for sound in [&"woof", &"chirp", &"announce", &"streak", &"shutdown", &"powerup", &"cheer", &"connect", &"disconnect"]:
		check(Sfx.has_sound(sound), "sound '%s' exists" % sound)
	var saved := GameSettings.music_volume
	GameSettings.music_volume = 0.0
	GameSettings.apply()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "music volume 0 mutes the music bus")
	GameSettings.music_volume = saved
	GameSettings.apply()
	await physics_frames(1)


func _test_announcer() -> void:
	section("Announcer call-outs")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	GameSettings.bot_count = 3
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	var player := game.get("player") as Player
	var hud := game.get("hud") as Hud
	var bots: Array = game.get("bots")
	var heard: Array[String] = []
	controller.announcement.connect(func(_e: ScoreEntry, text: String, _c: Color, _s: StringName) -> void: heard.append(text))
	await fast_forward(controller.mode.countdown_seconds + 0.3)
	var popper := load(POPPER) as WeaponData
	for i in 3:
		(bots[i] as Bot)._tag_out(player, popper, false)
	check(heard.has("FIRST TAG!"), "the first tag of the match is announced")
	check(heard.has("DOUBLE TAG!") and heard.has("TRIPLE TAG!"), "quick tags are DOUBLE and TRIPLE TAGs")
	check(heard.has("ON A ROLL!"), "three tags in a row is ON A ROLL!")
	player._tag_out(bots[0] as Bot, popper, false)
	var shut := false
	for text in heard:
		shut = shut or (text.contains("SHUT DOWN") and text.contains((bots[0] as Bot).display_name.to_upper()))
	check(shut, "ending a 3-tag streak is a SHUT DOWN by the bot who did it")
	# The HUD updates in _process; several physics steps can pass in one idle frame.
	for i in 3:
		await get_tree().process_frame
	check(not hud.current_announcement().is_empty(), "the HUD shows the call-out (%s)" % hud.current_announcement())
	GameSettings.bot_count = saved_bots
	await end_match(game, saved_mode)


func _test_customisation() -> void:
	section("Your player: name, colour, hat")
	check(Cosmetics.sanitize_name("  Ab   Cd  ") == "Ab Cd", "names are trimmed and spaces tidied")
	check(Cosmetics.sanitize_name("<b>!!</b>") == "bb", "odd characters are removed")
	check(Cosmetics.sanitize_name("Supercalifragilistic").length() == Cosmetics.NAME_MAX_LENGTH, "names are capped at %d letters" % Cosmetics.NAME_MAX_LENGTH)
	var saved_name := GameSettings.player_name
	var saved_color := GameSettings.player_color
	var saved_hat := GameSettings.player_hat
	var saved_mode := GameSettings.match_mode
	GameSettings.player_name = ""
	check(GameSettings.display_name() == "You", "no name shows as 'You'")
	GameSettings.player_name = "Tester"
	GameSettings.player_color = 1
	GameSettings.player_hat = &"crown"
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var player := game.get("player") as Player
	var controller := game.get("controller") as MatchController
	check(player.display_name == "Tester", "the player uses their chosen name")
	check(player.color.is_equal_approx(Cosmetics.color_at(1)), "…their chosen colour (their darts are that colour too)")
	check(controller.board.entry_for(player).hat == &"crown", "…and their hat")
	await end_match(game, saved_mode)
	GameSettings.player_name = saved_name
	GameSettings.player_color = saved_color
	GameSettings.player_hat = saved_hat

	var orange := Cosmetics.color_at(6)
	var colors := MatchScene.bot_colors(orange, 5)
	var clash := false
	for i in colors.size():
		clash = clash or Cosmetics.too_similar(colors[i], orange)
		for j in i:
			clash = clash or Cosmetics.too_similar(colors[i], colors[j])
	check(not clash, "bots never share (or nearly share) the player's colour or each other's")

	var stage := make_stage()
	var all_hats := true
	for hat in Cosmetics.HATS:
		var model := CharacterModel.new()
		stage.add_child(model)
		model.setup("Hat test", Color.RED, hat["id"])
		all_hats = all_hats and model.hat_id() == hat["id"]
	check(all_hats, "every hat (%d) builds on a character" % Cosmetics.HATS.size())
	stage.queue_free()
	await physics_frames(1)


func _test_podium_and_awards() -> void:
	section("End-of-match podium and awards")
	var a := ScoreEntry.new()
	a.display_name = "A"
	a.ricochet_tags = 2
	a.darts_fired = 40
	a.hits_landed = 20
	var b := ScoreEntry.new()
	b.display_name = "B"
	b.darts_fired = 30
	b.hits_landed = 5
	b.outs = 4
	b.darts_collected = 200
	var ranked: Array[ScoreEntry] = [a, b]
	var titles := {}
	for award in Awards.compute(ranked):
		titles[award["title"]] = (award["entry"] as ScoreEntry).display_name
	check(titles.get("Ricochet King") == "A", "Ricochet King goes to the ricochet tagger")
	check(titles.get("Sharpshooter") == "A", "Sharpshooter goes to the best hit rate")
	check(titles.get("Foam Magnet") == "B" and titles.get("Bucket Hog") == "B", "Foam Magnet and Bucket Hog go to B")
	check(not titles.has("Bullseye Boss"), "no award without reaching its minimum")

	var saved_mode := GameSettings.match_mode
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	await fast_forward(controller.mode.countdown_seconds + 0.5)
	controller._finish()
	await physics_frames(2)
	var podium := game.get("podium") as Podium
	check(podium != null, "a podium appears when the match ends")
	check(podium != null and podium.dancers.size() == mini(3, controller.actors.size()), "the top three stand on it")
	check(podium != null and get_viewport().get_camera_3d() == podium.camera, "the camera cuts to the podium")
	await end_match(game, saved_mode)


func _test_backyard_props() -> void:
	section("Backyard props")
	var arena := (load("res://scenes/arenas/backyard_fortress.tscn") as PackedScene).instantiate() as Arena
	arena.bake_navigation = false
	add_child(arena)
	await physics_frames(1)
	var dog: DogHouse = arena.get("dog_house")
	check(dog != null and dog.get_parent() == arena.geometry, "the dog house is solid scenery bots can path around")
	var barks: Array[int] = [0]
	dog.barked.connect(func() -> void: barks[0] += 1)
	dog.on_dart_hit(null, Vector3.ZERO)
	check(barks[0] == 1, "a dart on the dog house makes the dog bark")
	dog.on_dart_hit(null, Vector3.ZERO)
	check(barks[0] == 1, "…but not twice in a row (cooldown)")
	check(arena.power_up_spots.size() == 1, "the arena has a power-up spot on the treehouse deck")
	arena.queue_free()
	await physics_frames(2)


func _test_power_up() -> void:
	section("Chainstorm power-up mode")
	var saved_mode := GameSettings.match_mode
	var saved_powerup := GameSettings.chainstorm_powerup
	GameSettings.chainstorm_powerup = true
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var controller := game.get("controller") as MatchController
	var player := game.get("player") as Player
	var pickup := game.get("power_up") as PowerUpPickup
	var heard: Array[String] = []
	controller.announcement.connect(func(_e: ScoreEntry, text: String, _c: Color, _s: StringName) -> void: heard.append(text))
	check(controller.mode.uses_power_up(), "power-up mode is on for Backyard Battle")
	check(not player.arsenal.has_weapon(&"flaxs_chainstorm"), "nobody starts with the Chainstorm")
	check(pickup != null and not pickup.is_available(), "the Chainstorm hasn't landed during the countdown")
	check(not (load(FFA) as GameMode).power_up_mode, "the shared mode file is untouched")
	await fast_forward(controller.mode.countdown_seconds + 0.5)
	pickup.make_available()
	check(heard.any(func(t: String) -> bool: return t.contains("HAS LANDED")), "its landing is announced")
	player.global_position = pickup.global_position + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO
	await physics_frames(4)
	check(player.arsenal.has_weapon(&"flaxs_chainstorm"), "touching it gives you the Chainstorm")
	check(player.arsenal.current().data.id == &"flaxs_chainstorm", "…in your hands straight away")
	check(not pickup.is_available() and pickup.seconds_until_ready() > 30.0, "then it's gone until it respawns")
	check(heard.any(func(t: String) -> bool: return t.contains("GRABBED")), "the grab is announced")
	player._tag_out(null, null, false)
	await fast_forward(controller.mode.respawn_delay + 0.5)
	check(player.alive and not player.arsenal.has_weapon(&"flaxs_chainstorm"), "being tagged out loses it")
	await end_match(game, saved_mode)

	var gun_game := start_match(GameSettings.MatchMode.GUN_GAME)
	check(gun_game.get("power_up") == null, "Gun Game ignores power-up mode")
	await end_match(gun_game, saved_mode)
	GameSettings.chainstorm_powerup = saved_powerup


# --- Linux build --------------------------------------------------------------

func _test_linux_export_preset() -> void:
	section("Linux build: export preset")
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg exists")
	check(presets.get_value("preset.0", "platform", "") == "Linux", "preset 0 targets Linux")
	check(presets.get_value("preset.0", "name", "") == "Linux", "…and is called \"Linux\" (tools/export_linux.sh uses that name)")
	var excluded := str(presets.get_value("preset.0", "exclude_filter", ""))
	check(excluded.contains("tests/*") and excluded.contains("tools/*"), "tests and tools stay out of the game")
	check(bool(presets.get_value("preset.0.options", "binary_format/embed_pck", false)), "one self-contained executable (data embedded)")
	check(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)
			and ProjectSettings.get_setting("application/config/custom_user_dir_name", "") == "dartstorm",
			"settings live in ~/.local/share/dartstorm")
	await physics_frames(1)


# --- Team modes and the lobby (the young players' design) ---------------------

func _entry(team: int, score: int, tags: int) -> ScoreEntry:
	var entry := ScoreEntry.new()
	entry.team = team
	entry.score = score
	entry.tags = tags
	return entry


func _test_team_rules() -> void:
	section("Team modes: rules")
	var duos := MatchScene.resolve_mode(GameSettings.MatchMode.DUOS)
	var teams := MatchScene.resolve_mode(GameSettings.MatchMode.TEAMS)
	check(duos.teams == GameMode.Teams.DUOS and duos.short_name == "DUOS", "DUOS loads from its mode file")
	check(teams.teams == GameMode.Teams.BLUE_VS_ORANGE and teams.short_name == "TEAMS", "TEAMS (Blue vs Orange) loads from its mode file")
	check(not MatchScene.resolve_mode(GameSettings.MatchMode.FREE_FOR_ALL).is_team_mode(), "SOLO is everyone for themselves")
	check(teams.bots_for(2) == 3 and teams.bots_for(3) == 3, "an odd team gets one extra bot (2 bots become 3, so 2 v 2)")
	check(duos.bots_for(4) == 5 and duos.bots_for(7) == 7, "every duo gets a partner (4 bots become 5)")
	check(MatchScene.team_bot_count(teams, 7) == 7, "7 bots make 4 v 4, the biggest match")
	var blue_orange: Array[int] = []
	var pairs: Array[int] = []
	for i in 6:
		blue_orange.append(teams.team_for(i))
		pairs.append(duos.team_for(i))
	check(blue_orange == [0, 1, 0, 1, 0, 1], "Blue vs Orange alternates players between blue and orange")
	check(pairs == [0, 0, 1, 1, 2, 2], "Duos pairs players up (you and the first bot are a pair)")
	check(GameMode.team_name(0) == "BLUE" and GameMode.team_name(1) == "ORANGE", "team 0 is blue and team 1 is orange, like the forts")

	var board := Scoreboard.new()
	board.entries.assign([_entry(0, 300, 3), _entry(1, 200, 2), _entry(0, 0, 0), _entry(1, 200, 2)])
	var ranked := teams.rank_teams(board)
	check(ranked.size() == 2 and ranked[0]["team"] == 1 and ranked[0]["score"] == 400, "team score is everyone's points added up (orange 400 beats blue 300)")
	check(teams.winning_team(board) == 1, "the higher team total wins")
	check(teams.rank(board)[0].team == 1 and teams.rank(board)[2].team == 0, "the ranking lists the winning team's players first")
	var places := teams.podium_places(board)
	check(places.size() == 2 and (places[0] as Array).size() == 2, "the whole winning team shares the top step of the podium")
	var level := Scoreboard.new()
	level.entries.assign([_entry(0, 100, 1), _entry(1, 100, 1)])
	check(teams.winning_team(level) == -1, "level scores are a draw")
	await physics_frames(1)


func _test_blue_vs_orange_match() -> void:
	section("Team modes: Blue vs Orange match")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	GameSettings.bot_count = 2
	var game := start_match(GameSettings.MatchMode.TEAMS)
	var controller := game.get("controller") as MatchController
	var player := game.get("player") as Player
	var hud := game.get("hud") as Hud
	var bots: Array = game.get("bots")
	check(bots.size() == 3, "2 bots asked for, 3 brought: 2 v 2")
	check(player.team_id == 0 and player.color.is_equal_approx(GameMode.team_color(0)), "you're on blue, wearing blue")
	var blue_mate := bots[1] as Bot
	var orange := bots[0] as Bot
	check(blue_mate.team_id == 0 and orange.team_id == 1 and orange.color.is_equal_approx(GameMode.team_color(1)),
			"bots wear their team's colour")
	check(not blue_mate.accepts_dart_from(player.team_id) and orange.accepts_dart_from(player.team_id),
			"your darts fly straight through team-mates and tag rivals")
	var home := true
	for actor in controller.actors:
		home = home and controller.is_home_spawn(actor.team_id, actor.global_position)
	check(home, "everyone starts at their own team's end of the yard")
	check(hud.team_chip_count() == 2, "the HUD shows both team scores under the clock")

	var heard: Array[String] = []
	controller.announcement.connect(func(_e: ScoreEntry, text: String, _c: Color, _s: StringName) -> void: heard.append(text))
	await fast_forward(controller.mode.countdown_seconds + 0.5)
	for bot: Bot in bots:
		bot.controls_enabled = false  # Keep the score predictable.
	orange._protect_left = 0.0
	orange._tag_out(blue_mate, blue_mate.arsenal.current().data, false)
	await physics_frames(2)
	var ranked := controller.mode.rank_teams(controller.board)
	check(ranked[0]["team"] == 0 and ranked[0]["score"] == controller.mode.points_per_tag, "a blue tag scores for the blue team")
	check(heard.has("YOUR TEAM TAKES THE LEAD!"), "the announcer calls the lead change")
	await fast_forward(controller.mode.respawn_delay + 0.5)
	check(orange.alive and controller.is_home_spawn(orange.team_id, orange.global_position), "tagged players respawn at their own end")

	controller._finish()
	await physics_frames(2)
	check(hud.result_title(controller.mode.rank(controller.board)) == "YOUR TEAM WINS!", "the results say YOUR TEAM WINS!")
	var podium := game.get("podium") as Podium
	check(podium != null and podium.dancers.size() == 4 and podium.dancer_places.count(0) == 2,
			"both teams dance on the podium, the winners together on the top step")
	GameSettings.bot_count = saved_bots
	await end_match(game, saved_mode)


func _test_duos_match() -> void:
	section("Team modes: Duos match")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	GameSettings.bot_count = 4
	var game := start_match(GameSettings.MatchMode.DUOS)
	var controller := game.get("controller") as MatchController
	var player := game.get("player") as Player
	var teams := {}
	for actor in controller.actors:
		teams[actor.team_id] = int(teams.get(actor.team_id, 0)) + 1
	check(controller.actors.size() == 6 and teams.size() == 3, "4 bots asked for, 5 brought: three pairs")
	check(teams.values().all(func(count: int) -> bool: return count == 2), "every pair has exactly two players")
	var buddy := (game.get("bots") as Array)[0] as Bot
	check(buddy.team_id == player.team_id and buddy.color.is_equal_approx(player.color), "your buddy is on your team, in your colour")
	GameSettings.bot_count = saved_bots
	await end_match(game, saved_mode)


## Regression: bots used to wear the default cap whatever hat the roster gave them.
func _test_bot_hats() -> void:
	section("Bots wear their own hats")
	var saved_mode := GameSettings.match_mode
	var game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	var bots: Array = game.get("bots")
	var right := true
	for i in bots.size():
		var model := (bots[i] as Bot).get_node("Model") as CharacterModel
		right = right and model.hat_id() == MatchScene.BOT_ROSTER[i]["hat"]
	check(right, "every bot's model wears its roster hat (%d bots)" % bots.size())
	await end_match(game, saved_mode)


func _test_lobby() -> void:
	section("Lobby (the players' own menu design)")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	GameSettings.match_mode = GameSettings.MatchMode.FREE_FOR_ALL
	GameSettings.bot_count = 3
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await physics_frames(2)
	var squad: Array = menu.get("squad")
	check(menu.get("player_model") != null, "you stand in the middle of the island")
	check(squad.size() == 3, "your 3 bots stand on platforms around you")
	var play := menu.get("_play_button") as Button
	check(play != null and play.has_focus(), "the big PLAY button has focus (A on a controller starts a match)")
	check((menu.get("_mode_buttons") as Array).size() == 6, "six mode cards: SOLO, DUOS, TEAMS, GUN GAME, ZOMBIES, SIEGE")

	menu.call("_pick_mode", GameSettings.MatchMode.TEAMS)
	await physics_frames(1)
	squad = menu.get("squad")
	check(GameSettings.match_mode == GameSettings.MatchMode.TEAMS, "picking TEAMS selects Blue vs Orange")
	check(squad.size() == 3, "…with 3 bots for an even 2 v 2")
	var mate := squad[0] as CharacterModel
	check((mate.get("_tint") as Color).is_equal_approx(GameMode.team_color(0)), "your team-mate stands nearest you, in blue")
	check(((menu.get("player_model") as CharacterModel).get("_tint") as Color).is_equal_approx(GameMode.team_color(0)),
			"…and so do you (your own colour comes back in SOLO)")
	menu.call("_change_bots", 99)
	await physics_frames(1)
	check(GameSettings.bot_count == GameSettings.MAX_BOTS and (menu.get("squad") as Array).size() == GameSettings.MAX_BOTS,
			"the bots button stops at %d, and they all fit on the island" % GameSettings.MAX_BOTS)

	menu.call("_show_customise", true)
	await physics_frames(1)
	var slots: Array = menu.get("_slots")
	check(slots.all(func(slot: Node3D) -> bool: return not slot.visible), "customising clears the stage so you're alone")
	menu.call("_show_customise", false)
	await physics_frames(1)
	slots = menu.get("_slots")
	check(slots.all(func(slot: Node3D) -> bool: return slot.visible), "…and everyone comes back afterwards")

	menu.queue_free()
	GameSettings.match_mode = saved_mode
	GameSettings.bot_count = saved_bots
	GameSettings.save_settings()
	await physics_frames(2)


# --- Home Turf (the toy-sized house) ---------------------------------------------

func _test_home_turf() -> void:
	section("Home Turf: a toy-sized house")
	var arena := (load(MatchScene.arena_path(1)) as PackedScene).instantiate() as Arena
	add_child(arena)
	await physics_frames(2)
	check(arena.arena_name == "Home Turf", "the lobby's second arena is Home Turf")
	check(arena.spawn_points.size() >= 12, "%d spawn points" % arena.spawn_points.size())
	check(arena.buckets.size() >= 5, "%d ammo buckets (toy box, laundry basket, ...)" % arena.buckets.size())
	check(arena.power_up_spots.size() == 1, "one power-up spot (the lounge)")
	check(arena.find_children("*", "ReflectiveSurface", true, false).size() >= 3, "bathroom and wardrobe mirrors for ricochets")
	check(arena.find_children("*", "JumpPad", true, false).size() >= 3, "beds are trampolines")
	check(arena.find_children("*", "WobbleTarget", true, false).size() >= 3, "dartboards to practise on")
	check(arena.wind_field.get_wind_at(Vector3(-6.0, 2.0, -32.0)).length() > 10.0, "the big fan makes the family room windy")
	check(arena.wind_field.get_wind_at(Vector3(-19.0, 2.0, 22.0)).is_zero_approx(), "…and the main bedroom is calm")

	# Nobody spawns inside a wall, a car or the furniture.
	var space := arena.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = Actor.BODY_RADIUS
	capsule.height = Actor.BODY_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = Layers.WORLD
	var clear := 0
	for marker in arena.spawn_points:
		query.transform = Transform3D(Basis.IDENTITY, marker.global_position + Vector3.UP * (Actor.BODY_HEIGHT * 0.5 + 0.05))
		if space.intersect_shape(query, 1).is_empty():
			clear += 1
	check(clear == arena.spawn_points.size(), "every spawn point is clear of walls and furniture (%d/%d)" % [clear, arena.spawn_points.size()])

	# Blue vs Orange: both ends have plenty of home spawns.
	check(arena.team_bases.size() == 2, "blue's end (front) and orange's end (backyard)")
	var home := [0, 0]
	for marker in arena.spawn_points:
		var spot := marker.global_position
		home[0 if spot.distance_to(arena.team_bases[0]) < spot.distance_to(arena.team_bases[1]) else 1] += 1
	check(home[0] >= 6 and home[1] >= 6, "each team has at least 6 home spawns (blue %d, orange %d)" % [home[0], home[1]])

	# Bots can get everywhere: every room, round both sides, and up the ramp onto the patio roof.
	var waited := 0
	while not arena.is_navigation_ready and waited < 900:
		await get_tree().physics_frame
		waited += 1
	check(arena.is_navigation_ready, "navmesh baked (after %d frames)" % waited)
	var map := arena.geometry.get_navigation_map()
	var start := arena.spawn_points[0].global_position
	waited = 0
	while NavigationServer3D.map_get_path(map, start, arena.team_bases[1], true).is_empty() and waited < 300:
		await get_tree().physics_frame
		waited += 1
	var reachable := 0
	var missing: Array[String] = []
	for point in arena.roam_points:
		var path := NavigationServer3D.map_get_path(map, start, point, true)
		if path.size() >= 2 and path[-1].distance_to(point) < 2.0:
			reachable += 1
		else:
			missing.append(str(point))
	check(reachable == arena.roam_points.size(), "every room and yard is reachable from the driveway (%d/%d) %s" % [reachable, arena.roam_points.size(), ", ".join(missing)])
	var roof := NavigationServer3D.map_get_path(map, start, Vector3(7.5, HomeTurf.PATIO_ROOF_TOP, -22.5), true)
	check(roof.size() >= 2 and roof[-1].y > HomeTurf.PATIO_ROOF_TOP - 0.5, "bots can walk up the race-track ramp onto the patio roof")
	arena.queue_free()
	await physics_frames(2)


func _test_home_turf_match() -> void:
	section("Home Turf: a whole bot match")
	var saved_mode := GameSettings.match_mode
	var saved_arena := GameSettings.arena
	var saved_bots := GameSettings.bot_count
	GameSettings.arena = 1
	GameSettings.bot_count = 3
	var game := start_match(GameSettings.MatchMode.TEAMS)
	var controller := game.get("controller") as MatchController
	check(controller.arena is HomeTurf, "picking HOME TURF in the lobby loads the house")
	var player := game.get("player") as Player
	player.controls_enabled = false
	var bots: Array = game.get("bots")
	var starts: Array[Vector3] = []
	for bot: Bot in bots:
		starts.append(bot.global_position)
	await fast_forward(controller.mode.countdown_seconds + 60.0)
	player.controls_enabled = false
	var moved := 0
	for i in bots.size():
		if (bots[i] as Bot).global_position.distance_to(starts[i]) > 4.0:
			moved += 1
	check(moved >= 2, "bots find their way round the house (%d of %d moved)" % [moved, bots.size()])
	var tags := 0
	for entry in controller.board.entries:
		tags += entry.tags
	check(tags > 0, "and tag each other within a minute (%d tags)" % tags)
	var inside := true
	for actor in controller.actors:
		var spot := actor.global_position
		inside = inside and spot.x > HomeTurf.LOT_WEST and spot.x < HomeTurf.LOT_EAST \
				and spot.z > HomeTurf.LOT_NORTH and spot.z < HomeTurf.LOT_SOUTH and spot.y > -1.0
	check(inside, "everyone stays inside the lot")
	GameSettings.arena = saved_arena
	GameSettings.bot_count = saved_bots
	await end_match(game, saved_mode)


func _test_tempest_treehouse() -> void:
	section("Tempest Treehouse: high canopy decks and chasm")
	var arena := (load(MatchScene.arena_path(2)) as PackedScene).instantiate() as Arena
	add_child(arena)
	await physics_frames(2)
	check(arena.arena_name == "Tempest Treehouse", "the lobby's third arena is Tempest Treehouse")
	check(arena.spawn_points.size() >= 12, "%d spawn points across canopies and ground" % arena.spawn_points.size())
	check(arena.buckets.size() >= 3, "%d ammo buckets (blue base, orange base, forest floor)" % arena.buckets.size())
	check(arena.power_up_spots.size() == 1, "one power-up spot (high crow's nest)")
	check(arena.shield_pickups.size() == 1, "one foam shield pickup (crow's nest)")
	check(arena.ice_slicks.size() == 1, "canopy escape ice slide chute")
	check(arena.vents.size() == 1, "forest floor wind vent")
	check(arena.puddles.size() == 1, "conductive bird-bath puddle")
	check(arena.find_children("*", "JumpPad", true, false).size() >= 3, "kinetic jump-pads (%d found)" % arena.find_children("*", "JumpPad", true, false).size())
	check(arena.find_children("*", "ReflectiveSurface", true, false).size() >= 3, "reflective mirrors for trick ricochets")
	check(arena.find_children("*", "WobbleTarget", true, false).size() >= 3, "wobble bullseye targets")
	check(arena.wind_field.get_wind_at(Vector3(0.0, TempestTreehouse.DECK_Y + 2.5, 0.0)).length() > 20.0, "strong gale wind tunnel blows across canopy chasm")
	check(arena.wind_field.get_wind_at(Vector3(-25.0, 1.0, -15.0)).is_zero_approx(), "calm in shielded forest pockets")

	# Nobody spawns inside trunks, railings or geometry
	var space := arena.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = Actor.BODY_RADIUS
	capsule.height = Actor.BODY_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = Layers.WORLD
	var clear := 0
	for marker in arena.spawn_points:
		query.transform = Transform3D(Basis.IDENTITY, marker.global_position + Vector3.UP * (Actor.BODY_HEIGHT * 0.5 + 0.05))
		if space.intersect_shape(query, 1).is_empty():
			clear += 1
	check(clear == arena.spawn_points.size(), "every spawn point is clear of geometry (%d/%d)" % [clear, arena.spawn_points.size()])

	# Blue vs Orange bases
	check(arena.team_bases.size() == 2, "blue fort base (-X) and orange fort base (+X)")
	var home := [0, 0]
	for marker in arena.spawn_points:
		var spot := marker.global_position
		home[0 if spot.distance_to(arena.team_bases[0]) < spot.distance_to(arena.team_bases[1]) else 1] += 1
	check(home[0] >= 5 and home[1] >= 5, "each team has balanced home spawns (blue %d, orange %d)" % [home[0], home[1]])

	# Navigation mesh bake
	var waited := 0
	while not arena.is_navigation_ready and waited < 900:
		await get_tree().physics_frame
		waited += 1
	check(arena.is_navigation_ready, "navmesh baked (after %d frames)" % waited)
	var map := arena.geometry.get_navigation_map()
	var start := arena.spawn_points[0].global_position
	waited = 0
	while NavigationServer3D.map_get_path(map, start, arena.team_bases[1], true).is_empty() and waited < 300:
		await get_tree().physics_frame
		waited += 1
	var reachable := 0
	var missing: Array[String] = []
	for point in arena.roam_points:
		var path := NavigationServer3D.map_get_path(map, start, point, true)
		if path.size() >= 2 and path[-1].distance_to(point) < 3.5:
			reachable += 1
		else:
			missing.append(str(point))
	check(reachable == arena.roam_points.size(), "every roam point is reachable across decks and ground (%d/%d) %s" % [reachable, arena.roam_points.size(), ", ".join(missing)])
	arena.queue_free()
	await physics_frames(2)


func _test_tempest_treehouse_match() -> void:
	section("Tempest Treehouse: a whole bot match")
	var saved_mode := GameSettings.match_mode
	var saved_arena := GameSettings.arena
	var saved_bots := GameSettings.bot_count
	GameSettings.arena = 2
	GameSettings.bot_count = 3
	var game := start_match(GameSettings.MatchMode.TEAMS)
	var controller := game.get("controller") as MatchController
	check(controller.arena is TempestTreehouse, "picking TEMPEST TREEHOUSE in the lobby loads the treehouse")
	var player := game.get("player") as Player
	player.controls_enabled = false
	var bots: Array = game.get("bots")
	var starts: Array[Vector3] = []
	for bot: Bot in bots:
		starts.append(bot.global_position)
	await fast_forward(controller.mode.countdown_seconds + 60.0)
	player.controls_enabled = false
	var moved := 0
	for i in bots.size():
		if (bots[i] as Bot).global_position.distance_to(starts[i]) > 4.0:
			moved += 1
	check(moved >= 2, "bots navigate treehouse decks and bridge (%d of %d moved)" % [moved, bots.size()])
	var tags := 0
	for entry in controller.board.entries:
		tags += entry.tags
	check(tags > 0, "and tag each other in the treehouse canopy (%d tags)" % tags)
	var inside := true
	for actor in controller.actors:
		var spot := actor.global_position
		inside = inside and spot.x > -TempestTreehouse.HALF_X and spot.x < TempestTreehouse.HALF_X \
				and spot.z > -TempestTreehouse.HALF_Z and spot.z < TempestTreehouse.HALF_Z and spot.y > -1.0
	check(inside, "everyone stays inside the treehouse grounds")
	GameSettings.arena = saved_arena
	GameSettings.bot_count = saved_bots
	await end_match(game, saved_mode)


## Regression: in team modes team-mates ignored each other when picking a spawn,
## so two could land on the same marker and the physics flung them into the sky.
func _test_no_stacked_spawns() -> void:
	section("Nobody spawns on top of anyone")
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	var saved_arena := GameSettings.arena
	GameSettings.bot_count = GameSettings.MAX_BOTS
	for arena_index in MatchScene.ARENAS.size():
		GameSettings.arena = arena_index
		for attempt in 3:
			var game := start_match(GameSettings.MatchMode.TEAMS)
			var controller := game.get("controller") as MatchController
			var closest := INF
			for i in controller.actors.size():
				for j in i:
					closest = minf(closest, controller.actors[i].global_position.distance_to(controller.actors[j].global_position))
			check(closest >= MatchController.SPAWN_CLEARANCE, "%s, 4 v 4, start %d: everyone on their own spot (closest %.1f m)"
					% [MatchScene.ARENAS[arena_index]["name"], attempt + 1, closest])
			await end_match(game, saved_mode)
	GameSettings.bot_count = saved_bots
	GameSettings.arena = saved_arena


func _test_elemental_gameplay() -> void:
	section("Elemental gameplay & combos")
	var wind_dart := load("res://resources/darts/wind_dart.tres") as DartData
	var fire_dart := load("res://resources/darts/fire_dart.tres") as DartData
	var water_dart := load("res://resources/darts/water_dart.tres") as DartData
	var lightning_dart := load("res://resources/darts/lightning_dart.tres") as DartData
	var ice_dart := load("res://resources/darts/ice_dart.tres") as DartData

	check(wind_dart != null and wind_dart.element == DartData.Element.WIND, "wind dart is Element.WIND")
	check(wind_dart != null and wind_dart.wind_response > 1.2, "wind dart catches drafts strongly (%.1fx)" % (wind_dart.wind_response if wind_dart != null else 0.0))
	check(fire_dart != null and fire_dart.element == DartData.Element.FIRE, "fire dart is Element.FIRE")
	check(water_dart != null and water_dart.element == DartData.Element.WATER, "water dart is Element.WATER")
	check(water_dart != null and water_dart.knockback_impulse >= 5.0, "water dart has strong knockback (%.1f m/s)" % (water_dart.knockback_impulse if water_dart != null else 0.0))
	check(lightning_dart != null and lightning_dart.element == DartData.Element.LIGHTNING, "lightning dart is Element.LIGHTNING")
	check(lightning_dart != null and lightning_dart.chain_count >= 2, "lightning dart chains across rivals (%d)" % (lightning_dart.chain_count if lightning_dart != null else 0))
	check(ice_dart != null and ice_dart.element == DartData.Element.ICE, "ice dart is Element.ICE")

	var gun_game := load(GUN_GAME) as GunGameMode
	check(gun_game != null and gun_game.ladder.size() == 10, "Gun Game ladder now has the full 10 rungs (10/10)")
	var ladder_ids: Array[StringName] = []
	if gun_game != null:
		for weapon in gun_game.ladder:
			ladder_ids.append(weapon.id)
	check(ladder_ids.has(&"wind_whisperer"), "ladder includes Wind Whisperer")
	check(ladder_ids.has(&"hydro_soaker"), "ladder includes Hydro Soaker")
	check(ladder_ids.has(&"thunder_cannon"), "ladder includes Thunder Cannon")

	# Actor elemental effects & combos
	var victim := Actor.new()
	add_child(victim)
	await get_tree().physics_frame

	check(victim.elemental != null, "actor automatically initializes an ElementalEffect component")
	check(victim.elemental.get_speed_multiplier() == 1.0, "default speed multiplier is 1.0")

	# Mock dart projectile for testing payloads
	var mock_dart := DartProjectile.new()
	mock_dart.velocity = Vector3(0.0, 0.0, -30.0)

	# Water splash: sets wet and pushes victim
	mock_dart.data = water_dart
	victim.elemental.apply_dart(mock_dart, victim.global_position)
	check(victim.elemental.has_status(DartData.Element.WATER), "water dart wets the actor")
	check(victim.velocity.z < -4.0, "water dart pushes victim backwards (velocity.z = %.1f)" % victim.velocity.z)

	# Combo: Fire on Wet actor -> Steam combo!
	var combos: Array[StringName] = []
	victim.elemental.combo_triggered.connect(func(combo: StringName, _at: Vector3) -> void: combos.append(combo))
	mock_dart.data = fire_dart
	victim.elemental.apply_dart(mock_dart, victim.global_position)
	check(combos.has(&"steam"), "fire on wet actor triggers 'steam' combo")
	check(not victim.elemental.has_status(DartData.Element.WATER), "steam combo clears wet status")
	check(not victim.elemental.has_status(DartData.Element.FIRE), "fire was doused by steam")

	# Frost slow & ice sliding
	mock_dart.data = ice_dart
	victim.elemental.apply_dart(mock_dart, victim.global_position)
	check(victim.elemental.has_status(DartData.Element.ICE), "ice dart applies frost status")
	check(victim.elemental.get_speed_multiplier() <= 0.75, "frost status slows actor (%.2f)" % victim.elemental.get_speed_multiplier())
	victim.elemental.clear_all()
	victim.elemental.start_slide(1.0)
	check(victim.elemental.is_sliding(), "start_slide enables sliding flag")
	check(victim.elemental.get_speed_multiplier() >= 1.4, "sliding gives a speed boost (%.2f)" % victim.elemental.get_speed_multiplier())

	# Lightning chain zap test with a nearby rival
	var rival := Actor.new()
	rival.team_id = 1
	add_child(rival)
	rival.global_position = victim.global_position + Vector3(3.0, 0.0, 0.0)
	await get_tree().physics_frame

	var chains: Array[Actor] = []
	victim.elemental.chain_zapped.connect(func(_from: Actor, to: Actor) -> void: chains.append(to))
	mock_dart.data = lightning_dart
	mock_dart.team_id = 0
	victim.elemental.apply_dart(mock_dart, victim.global_position)
	check(chains.has(rival), "lightning dart on victim chain-zaps nearby rival (3m away)")
	check(rival.tag_meter > 0.0, "chain zap fills rival's tag meter (%.1f)" % rival.tag_meter)

	# Clean teardown
	mock_dart.free()
	rival.queue_free()
	victim.queue_free()
	await physics_frames(2)


func _test_zombies_mode() -> void:
	section("Zombies mode")
	var zom_mode := load(ZOMBIES_MODE) as ZombieMode
	check(zom_mode != null, "zombies mode resource loads cleanly")
	check(zom_mode.id == &"zombies", "zombies mode id is 'zombies'")
	check(zom_mode.is_team_mode(), "zombies mode is a team mode (Survivors vs Horde)")
	check(zom_mode.get_team_name(0) == "SURVIVORS", "team 0 is named SURVIVORS")
	check(zom_mode.get_team_name(1) == "ZOMBIES", "team 1 is named ZOMBIES")
	check(zom_mode.get_team_color(1) == ZombieMode.ZOMBIE_COLOR, "team 1 color is ZOMBIE_COLOR")
	check(zom_mode.loadout.size() >= 4, "survivor loadout has at least 4 blasters (%d)" % zom_mode.loadout.size())

	# Loadout checks
	var survivor_entry := ScoreEntry.new()
	survivor_entry.display_name = "Survivor"
	survivor_entry.color = Color.BLUE
	survivor_entry.hat = &"cap"
	survivor_entry.team = ZombieMode.SURVIVOR_TEAM
	var zombie_entry := ScoreEntry.new()
	zombie_entry.display_name = "Zombie"
	zombie_entry.color = ZombieMode.ZOMBIE_COLOR
	zombie_entry.hat = &"cap"
	zombie_entry.team = ZombieMode.ZOMBIE_TEAM

	check(zom_mode.get_loadout(survivor_entry).size() >= 4, "survivor gets weapon loadout")
	check(zom_mode.get_loadout(zombie_entry).is_empty(), "zombies have empty loadout (no blasters)")

	# Actor infection & tag out test
	var survivor_actor := Actor.new()
	survivor_actor.team_id = ZombieMode.SURVIVOR_TEAM
	var zombie_actor := Actor.new()
	add_child(survivor_actor)
	add_child(zombie_actor)
	await get_tree().physics_frame

	zombie_actor.set_zombie(true)
	check(zombie_actor.is_zombie, "set_zombie sets is_zombie to true")
	check(zombie_actor.team_id == ZombieMode.ZOMBIE_TEAM, "set_zombie sets team_id to 1")
	check(not zombie_actor.arsenal.enabled, "zombie actor has arsenal disabled")
	check(zombie_actor.sprint_speed >= 8.4, "zombie actor gets calibrated sprint speed (%.1f)" % zombie_actor.sprint_speed)

	# Zombie touches survivor -> survivor infected & tagged out
	var infected := zombie_actor.try_zombie_infect(survivor_actor)
	check(infected, "try_zombie_infect returns true when touching survivor")
	check(not survivor_actor.alive, "infected survivor is tagged out")
	check(survivor_actor.tag_meter == survivor_actor.tag_meter_max, "tag meter maxed on infection")

	# Mode scoring test
	var pts := zom_mode.apply_tag(zombie_entry, survivor_entry, false)
	check(pts == 150, "zombie tagging survivor awards 150 points")
	check(survivor_entry.team == ZombieMode.ZOMBIE_TEAM, "victim converted to zombie team")
	check(survivor_entry.color == ZombieMode.ZOMBIE_COLOR, "victim color converted to zombie color")

	# Win condition evaluation
	var board := Scoreboard.new()
	var e1 := ScoreEntry.new()
	e1.display_name = "S1"
	e1.color = Color.BLUE
	e1.hat = &"cap"
	e1.team = ZombieMode.SURVIVOR_TEAM
	var e2 := ScoreEntry.new()
	e2.display_name = "Z1"
	e2.color = ZombieMode.ZOMBIE_COLOR
	e2.hat = &"cap"
	e2.team = ZombieMode.ZOMBIE_TEAM
	board.entries = [e1, e2]

	check(zom_mode.count_survivors(board) == 1, "count_survivors finds 1 survivor")
	check(zom_mode.count_zombies(board) == 1, "count_zombies finds 1 zombie")
	check(zom_mode.get_early_winner(board) == null, "no early winner while survivors remain")
	check(zom_mode.winning_team(board) == ZombieMode.SURVIVOR_TEAM, "survivors win if time expires with survivors left")

	# All turned -> Zombies early victory
	e1.team = ZombieMode.ZOMBIE_TEAM
	check(zom_mode.count_survivors(board) == 0, "0 survivors remain after conversion")
	check(zom_mode.get_early_winner(board) == e2 or zom_mode.get_early_winner(board) == e1, "zombies win early when all survivors turned")
	check(zom_mode.winning_team(board) == ZombieMode.ZOMBIE_TEAM, "zombies are the winning team")

	# Teardown actor nodes
	survivor_actor.queue_free()
	zombie_actor.queue_free()
	await physics_frames(2)

	# Fast live match verification
	var saved_mode := GameSettings.match_mode
	var game := start_match(GameSettings.MatchMode.ZOMBIES)
	await physics_frames(5)
	check(game.controller.mode is ZombieMode, "match instantiated with ZombieMode")
	var zombie_count := 0
	var survivor_count := 0
	for actor: Actor in game.controller.actors:
		if actor.is_zombie:
			zombie_count += 1
		else:
			survivor_count += 1
	check(zombie_count == 1, "exactly 1 Alpha Zombie spawned at match start (1/%d)" % game.controller.actors.size())
	check(survivor_count == game.controller.actors.size() - 1, "all other players begin as Survivors (%d)" % survivor_count)
	await end_match(game, saved_mode)


func _test_shield_and_hazards() -> void:
	section("Foam Shield & Environmental Hazards")

	# 1. Foam Shield absorption mechanics
	var stage := make_stage()
	var victim := make_actor(stage, Vector3.ZERO, 0)
	var attacker := make_actor(stage, Vector3(0.0, 0.0, -5.0), 1)
	await physics_frames(1)

	var shield_broken_called: Array[bool] = [false]
	victim.shield_broken.connect(func(_a: Actor) -> void: shield_broken_called[0] = true)

	victim.grant_shield(50.0)
	check(victim.has_shield(), "grant_shield gives active shield")
	check(victim.shield_points == 50.0, "shield points start at 50")

	var pool := make_pool(stage)
	var dart_data := make_dart_data(40.0)
	dart_data.tag_power = 20.0
	var dart1 := pool.fire(dart_data, Vector3(0.0, 1.0, -1.0), Vector3.FORWARD, attacker, null, Color.RED, [])
	victim.receive_dart(dart1)
	check(victim.shield_points == 30.0, "20-power dart reduces shield from 50 to 30 (got %.1f)" % victim.shield_points)
	check(victim.tag_meter == 0.0, "tag meter untouched while shield absorbs hit")
	check(not shield_broken_called[0], "shield_broken not called while shield holds")

	# Dart with overflow damage (40 power vs 30 shield points)
	var dart2 := pool.fire(dart_data, Vector3(0.0, 1.0, -1.0), Vector3.FORWARD, attacker, null, Color.RED, [])
	dart2.data.tag_power = 40.0
	victim.receive_dart(dart2)
	check(victim.shield_points == 0.0, "shield points depleted on break")
	check(not victim.has_shield(), "has_shield returns false when depleted")
	check(shield_broken_called[0], "shield_broken emitted on break")
	check(victim.tag_meter == 10.0, "leftover 10 damage flows to tag meter (got %.1f)" % victim.tag_meter)

	# 2. Zombie infection protection with shield
	victim.respawn(Transform3D.IDENTITY)
	victim._protect_left = 0.0
	victim.grant_shield(50.0)
	var zombie := make_actor(stage, Vector3(1.0, 0.0, 0.0), 1)
	zombie.is_zombie = true
	victim.receive_zombie_infection(zombie)
	check(victim.alive, "shielded survivor survives zombie infection touch")
	check(not victim.has_shield(), "shield pops on zombie infection touch")
	check(victim.tag_meter == 50.0, "survivor takes 50 tag points instead of instant tag-out")

	# 3. Water Puddle mechanics & electric conduction
	victim.respawn(Transform3D.IDENTITY)
	victim._protect_left = 0.0
	var puddle := WaterPuddle.new()
	puddle.radius = 2.5
	stage.add_child(puddle)
	puddle.global_position = Vector3(10.0, 0.0, 0.0)
	victim.global_position = puddle.global_position
	await physics_frames(2)
	puddle._splash_actor(victim)
	check(victim.elemental.has_status(DartData.Element.WATER), "puddle splashes and applies wet status to actor")

	# Electrification by lightning dart
	var lightning_dart_res := load("res://resources/darts/lightning_dart.tres") as DartData
	var elec_dart := pool.fire(lightning_dart_res, Vector3(10.0, 1.0, -1.0), Vector3.FORWARD, attacker, null, Color.YELLOW, [])
	puddle.on_dart_hit(elec_dart, puddle.global_position)
	check(puddle.is_electrified(), "lightning dart electrifies water puddle")
	puddle._shock_occupants()
	check(victim.tag_meter > 0.0, "electrified puddle shocks actor inside (tag meter %.1f)" % victim.tag_meter)

	# 4. Ice Slick mechanics & melting
	var slick := IceSlick.new()
	slick.size = Vector3(2.5, 0.2, 6.0)
	slick.slide_direction = Vector3(0.0, 0.0, 1.0)
	stage.add_child(slick)
	slick.global_position = Vector3(20.0, 0.0, 0.0)
	victim.global_position = slick.global_position
	victim.velocity = Vector3.ZERO
	slick._boost_actor(victim)
	check(victim.elemental.is_sliding(), "ice slick triggers slide on actor")
	check(victim.velocity.z > 5.0, "ice slick imparts directional boost velocity (got %.1f)" % victim.velocity.z)

	var fire_dart_res := load("res://resources/darts/fire_dart.tres") as DartData
	var fire_dart := pool.fire(fire_dart_res, Vector3(20.0, 1.0, -1.0), Vector3.FORWARD, attacker, null, Color.ORANGE, [])
	slick.on_dart_hit(fire_dart, slick.global_position)
	check(slick.is_melted(), "fire dart melts ice slick into water")

	# 5. Wind Vent mechanics & elemental amplification
	var vent := WindVent.new()
	vent.radius = 1.6
	stage.add_child(vent)
	vent.global_position = Vector3(30.0, 0.0, 0.0)
	victim.global_position = vent.global_position
	victim.velocity = Vector3.ZERO
	vent._apply_vent_to_actor(victim, 0.016)
	check(victim.velocity.y > 0.0, "wind vent applies buoyant upward lift (%.1f m/s)" % victim.velocity.y)

	var ice_dart_res := load("res://resources/darts/ice_dart.tres") as DartData
	var ice_dart := pool.fire(ice_dart_res, Vector3(30.0, 1.0, -1.0), Vector3.FORWARD, attacker, null, Color.CYAN, [])
	vent.on_dart_hit(ice_dart, vent.global_position)
	check(vent.active_element == DartData.Element.ICE, "ice dart infuses wind vent with Ice element")
	vent._apply_vent_to_actor(victim, 0.016)
	check(victim.elemental.has_status(DartData.Element.ICE), "infused wind vent applies frost chill to actor inside")

	# Teardown
	stage.queue_free()
	await physics_frames(2)


func _test_progression_and_shop() -> void:
	section("Progression, Levels, Missions & Coin Shop")

	# 1. Level formulas and progress calculations
	check(Progression.level_for_xp(0) == 1, "0 XP is Level 1")
	check(Progression.level_for_xp(99) == 1, "99 XP is Level 1")
	check(Progression.level_for_xp(100) == 2, "100 XP is Level 2")
	check(Progression.level_for_xp(299) == 2, "299 XP is Level 2")
	check(Progression.level_for_xp(300) == 3, "300 XP is Level 3")
	check(Progression.level_for_xp(600) == 4, "600 XP is Level 4")

	check(Progression.xp_for_level(1) == 0, "Level 1 base XP is 0")
	check(Progression.xp_for_level(2) == 100, "Level 2 base XP is 100")
	check(Progression.xp_for_level(3) == 300, "Level 3 base XP is 300")
	check(Progression.xp_for_level(4) == 600, "Level 4 base XP is 600")

	var prog_stat: Dictionary = Progression.level_progress(150)
	check(int(prog_stat["level"]) == 2, "150 XP resolves to level 2")
	check(int(prog_stat["current_xp"]) == 50, "150 XP has 50 XP into level 2")
	check(int(prog_stat["needed_xp"]) == 200, "Level 2 needs 200 XP to level up")
	check(is_equal_approx(float(prog_stat["ratio"]), 0.25), "Ratio at 150 XP is 0.25 (25%)")

	# 2. XP accumulation and level up signal
	Progression.reset_to_defaults()
	check(Progression.coins == 250, "fresh progression profile has 250 starting coins")
	check(Progression.get_level() == 1, "fresh progression profile starts at Level 1")

	var level_up_result: Array[int] = [0]
	var on_level_up := func(lvl: int) -> void: level_up_result[0] = lvl
	Progression.level_up.connect(on_level_up)
	Progression.add_xp(150)
	check(Progression.get_level() == 2, "player reaches level 2 after earning 150 XP")
	check(level_up_result[0] == 2, "level_up signal emitted with new level 2")
	Progression.level_up.disconnect(on_level_up)

	# 3. Coins balance, earning, spending, affordability
	check(Progression.can_afford(200), "can afford 200 coins with 250 balance")
	check(not Progression.can_afford(300), "cannot afford 300 coins with 250 balance")
	Progression.add_coins(100)
	check(Progression.coins == 350, "balance increased to 350 coins")
	var spent := Progression.spend_coins(150)
	check(spent and Progression.coins == 200, "successfully spent 150 coins, balance is now 200")
	var failed_spend := Progression.spend_coins(500)
	check(not failed_spend and Progression.coins == 200, "overspending fails gracefully without changing balance")

	# 4. Cosmetics Unlocks & Default states
	check(Progression.is_unlocked(&"hat", &"cap"), "default cap is unlocked")
	check(Progression.is_unlocked(&"hat", &"beanie"), "default beanie is unlocked")
	check(Progression.is_unlocked(&"hat", &"none"), "default none is unlocked")
	check(not Progression.is_unlocked(&"hat", &"crown"), "champion crown starts locked")
	check(Progression.is_unlocked(&"color", 0), "default blue color is unlocked")
	check(not Progression.is_unlocked(&"color", 4), "bubblegum pink color starts locked")

	# Unlock crown and pink
	var crown_unlocked := Progression.unlock_item(&"hat", &"crown")
	check(crown_unlocked and Progression.is_unlocked(&"hat", &"crown"), "crown unlocks successfully")
	var pink_unlocked := Progression.unlock_item(&"color", 4)
	check(pink_unlocked and Progression.is_unlocked(&"color", 4), "pink color unlocks successfully")

	# 5. Backyard Missions
	check(Progression.active_missions.size() == 3, "3 active backyard missions generated")
	var m0: Dictionary = Progression.active_missions[0]
	var m0_ev: StringName = m0["event"]
	var m0_tgt: int = m0["target"]
	var xp_before := Progression.lifetime_xp
	var coins_before := Progression.coins
	Progression.notify_event(m0_ev, m0_tgt)
	check(Progression.lifetime_xp > xp_before, "completing backyard mission awards XP")
	check(Progression.coins > coins_before, "completing backyard mission awards Coins")
	check(Progression.active_missions.size() == 3, "active missions list replenished after completion")

	# 6. Shop and Missions Panel Modals
	var shop := ShopPanel.new()
	add_child(shop)
	await physics_frames(2)
	check(shop._coin_label.text.contains(str(Progression.coins)), "shop panel displays live coin balance")
	shop.queue_free()

	var mpanel := MissionsPanel.new()
	add_child(mpanel)
	await physics_frames(2)
	check(mpanel._cards_box.get_child_count() == 3, "missions panel displays cards for all 3 active missions")
	mpanel.queue_free()

	# 7. Persistence integrity
	Progression.save_progression()
	Progression.load_progression()
	check(Progression.is_unlocked(&"hat", &"crown"), "persistence preserved unlocked crown after load")
	check(Progression.is_unlocked(&"color", 4), "persistence preserved unlocked pink after load")

	# Clean up to defaults
	Progression.reset_to_defaults()
	await physics_frames(2)


func _test_blaster_skins_and_shader() -> void:
	section("Blaster skins and generative shader pipeline")
	check(Cosmetics.SKINS.size() == 8, "Cosmetics catalog defines 8 skins (%d)" % Cosmetics.SKINS.size())

	# 1. Catalog integrity & pattern textures
	for skin in Cosmetics.SKINS:
		var skid: StringName = skin["id"]
		check(Cosmetics.has_skin(skid), "Cosmetics.has_skin recognizes %s" % skid)
		check(not Cosmetics.skin_name(skid).is_empty(), "skin %s has non-empty display name" % skid)
		var pattern_path := Cosmetics.skin_pattern(skid)
		check(ResourceLoader.exists(pattern_path), "pattern texture exists on disk: %s" % pattern_path)
		var img_tex := load(pattern_path) as Texture2D
		check(img_tex != null and img_tex.get_width() == 1024 and img_tex.get_height() == 1024,
				"skin pattern %s is valid 1024x1024 texture" % skid)

	# 2. Shader compilation
	var shader := load("res://assets/materials/blaster_skin.gdshader") as Shader
	check(shader != null, "blaster_skin.gdshader loads cleanly")

	# 3. Progression unlocks & equipping
	Progression.reset_to_defaults()
	check(Progression.is_unlocked(&"skin", &"default"), "default skin is unlocked by default")
	check(not Progression.is_unlocked(&"skin", &"cyber"), "neon circuit skin starts locked")
	var unlocked_cyber := Progression.unlock_item(&"skin", &"cyber")
	check(unlocked_cyber and Progression.is_unlocked(&"skin", &"cyber"), "unlock_item successfully unlocks cyber skin")

	# Save and reload persistence
	Progression.save_progression()
	Progression.load_progression()
	check(Progression.is_unlocked(&"skin", &"cyber"), "persistence preserves unlocked cyber skin across save/load")

	# 4. BlasterModel shader application & part zoning
	var popper_data := load(POPPER) as WeaponData
	var model := BlasterModel.create(popper_data, true, &"cyber")
	add_child(model)
	await physics_frames(2)
	check(model.skin_id == &"cyber", "BlasterModel has skin_id &\"cyber\"")

	var found_chassis_shader := false
	var preserved_orange_tip := false
	var preserved_dark_grip := false

	for child in model.get_children():
		var mesh_inst := child as MeshInstance3D
		if mesh_inst != null and mesh_inst.material_override != null:
			if mesh_inst.material_override is ShaderMaterial:
				found_chassis_shader = true
			elif mesh_inst.material_override is StandardMaterial3D:
				var std_mat := mesh_inst.material_override as StandardMaterial3D
				if std_mat.albedo_color.is_equal_approx(BlasterModel.ORANGE_TIP):
					preserved_orange_tip = true
				elif std_mat.albedo_color.is_equal_approx(BlasterModel.DARK):
					preserved_dark_grip = true

	check(found_chassis_shader, "chassis parts use ShaderMaterial with tri-planar skin shader")
	check(preserved_orange_tip, "safety orange muzzle tip preserves official safety plastic")
	check(preserved_dark_grip, "dark grip preserves matte tactile polymer material")
	model.queue_free()

	# 5. Shop Panel skins tab
	var shop := ShopPanel.new()
	add_child(shop)
	await physics_frames(2)
	shop._switch_tab(ShopPanel.Tab.SKINS)
	await physics_frames(2)
	var active_cards := 0
	for child in shop._grid_container.get_children():
		if not child.is_queued_for_deletion():
			active_cards += 1
	check(active_cards == 8, "shop panel renders 8 skin cards in SKINS tab")
	shop.queue_free()

	Progression.reset_to_defaults()
	await physics_frames(2)


func _test_base_core_and_barricades() -> void:
	section("Base Core and Barricades")
	var core := BaseCore.new()
	add_child(core)
	await physics_frames(2)

	check(core.health == 1250.0, "BaseCore initializes with 1250 HP")
	check(not core.is_destroyed, "BaseCore is not destroyed at start")

	var core_events := {"damaged": 0.0, "destroyed": false}
	core.damaged.connect(func(amount: float, _attacker: Node) -> void: core_events["damaged"] += amount)
	core.damage(250.0)
	check(core.health == 1000.0, "BaseCore takes 250 damage -> 1000 HP remaining")
	check(float(core_events["damaged"]) == 250.0, "BaseCore damaged signal emitted with correct amount")

	core.repair(150.0)
	check(core.health == 1150.0, "BaseCore repair restores 150 HP -> 1150 HP")
	core.repair(500.0)
	check(core.health == 1250.0, "BaseCore repair clamps to max 1250 HP")

	core.destroyed.connect(func() -> void: core_events["destroyed"] = true)
	core.damage(1250.0)
	check(core.health == 0.0, "BaseCore HP reduced to 0")
	check(core.is_destroyed, "BaseCore is_destroyed is true")
	check(bool(core_events["destroyed"]), "BaseCore destroyed signal emitted")
	core.queue_free()

	# BaseBarricade tests
	var barricade := BaseBarricade.new()
	add_child(barricade)
	await physics_frames(2)

	check(barricade.health == 350.0, "BaseBarricade initializes with 350 HP")
	check(not barricade.is_broken, "BaseBarricade is not broken at start")

	barricade.damage(100.0)
	check(barricade.health == 250.0, "BaseBarricade takes 100 damage -> 250 HP remaining")

	var b_events := {"broken": false, "repaired": false}
	barricade.broken.connect(func() -> void: b_events["broken"] = true)
	barricade.damage(250.0)
	check(barricade.health == 0.0, "BaseBarricade HP reduced to 0")
	check(barricade.is_broken, "BaseBarricade is_broken is true")
	check(bool(b_events["broken"]), "BaseBarricade broken signal emitted")

	barricade.repaired.connect(func() -> void: b_events["repaired"] = true)
	barricade.rebuild()
	check(barricade.health == 350.0, "BaseBarricade rebuilt to 350 HP")
	check(not barricade.is_broken, "BaseBarricade is_broken is false after rebuild")
	check(bool(b_events["repaired"]), "BaseBarricade repaired signal emitted")
	barricade.queue_free()


func _test_zombie_siege_and_director() -> void:
	section("Zombie Siege mode and Horde Director")
	var siege := load(ZOMBIE_SIEGE_MODE) as ZombieSiegeMode
	check(siege != null, "zombie_siege.tres loads cleanly")
	check(siege.id == &"zombie_siege", "mode id is 'zombie_siege'")
	check(siege.is_team_mode(), "ZombieSiegeMode is a team mode")
	check(siege.get_team_name(0) == "DEFENDERS", "team 0 is DEFENDERS")
	check(siege.get_team_name(1) == "ZOMBIE HORDE", "team 1 is ZOMBIE HORDE")

	var dummy_actor := Actor.new()
	add_child(dummy_actor)
	await physics_frames(1)
	check(siege.should_respawn(dummy_actor), "defenders respawn when tagged out")
	dummy_actor.set_zombie(true)
	check(not siege.should_respawn(dummy_actor), "horde zombies do NOT respawn when tagged out")
	dummy_actor.queue_free()

	# HordeDirector wave configuration & pacing
	check(HordeDirector.WAVES.size() == 5, "HordeDirector defines 5 escalating waves")
	check(HordeDirector.INTERMISSION_DURATION == 25.0, "HordeDirector intermission duration is 25 seconds")
	check(HordeDirector.WAVES[0]["runners"] == 6, "Wave 1 spawns 6 Runners")
	check(HordeDirector.WAVES[3]["brutes"] == 4, "Wave 4 spawns 4 Brutes")
	check(HordeDirector.WAVES[4]["boss"] == true, "Wave 5 spawns Mega Titan Boss")

	var hd := HordeDirector.new()
	add_child(hd)
	await physics_frames(1)

	var core := BaseCore.new()
	var barricade := BaseBarricade.new()
	add_child(core)
	add_child(barricade)
	hd.setup(null, null, core, [barricade], null, null)

	hd.start()
	check(hd.current_wave == 1, "HordeDirector starts at wave 1")
	check(hd.scrap == 100, "HordeDirector starts with 100 starting scrap")
	check(hd.remaining_enemies == 6, "Wave 1 has 6 remaining enemies")

	# Test scrap operations
	hd.add_scrap(50)
	check(hd.scrap == 150, "add_scrap adds 50 scrap -> 150")
	var spent_ok := hd.spend_scrap(75)
	check(spent_ok and hd.scrap == 75, "spend_scrap spends 75 scrap -> 75 remaining")
	var spent_fail := hd.spend_scrap(100)
	check(not spent_fail and hd.scrap == 75, "spend_scrap fails when unaffordable")

	# Test base core repair via scrap
	core.damage(300.0)
	hd.add_scrap(100)
	var repair_ok := hd.repair_base_core(100, 250.0)
	check(repair_ok and core.health == 1200.0, "repair_base_core spends scrap and restores core HP")

	# Test barricade rebuild via scrap
	barricade.damage(350.0)
	check(barricade.is_broken, "barricade is broken")
	var rebuild_ok := hd.rebuild_barricade(barricade, 75)
	check(rebuild_ok and not barricade.is_broken and barricade.health == 350.0, "rebuild_barricade restores broken barricade")

	# Test bot archetypes
	var bot := Bot.new()
	add_child(bot)
	await physics_frames(1)

	bot.apply_archetype(&"runner")
	check(bot.tag_meter_max == 100.0 and bot.melee_damage == 15.0 and bot.sprint_speed == 9.2,
			"runner archetype has 100 HP, 15 melee damage, 9.2 sprint speed")

	bot.apply_archetype(&"brute")
	check(bot.tag_meter_max == 300.0 and bot.melee_damage == 35.0 and bot.sprint_speed == 6.8 and bot.scale.x > 1.3,
			"brute archetype has 300 HP, 35 melee damage, 6.8 sprint speed, and 1.35x scale")

	bot.apply_archetype(&"titan_boss")
	check(bot.tag_meter_max == 800.0 and bot.melee_damage == 70.0 and bot.sprint_speed == 5.5 and bot.scale.x > 2.0,
			"titan_boss archetype has 800 HP, 70 melee damage, 5.5 sprint speed, and 2.2x scale")

	bot.queue_free()
	barricade.queue_free()
	core.queue_free()
	hd.queue_free()


func _test_zombie_siege_match() -> void:
	section("Zombie Siege Match Simulation")
	GameSettings.match_mode = GameSettings.MatchMode.ZOMBIE_SIEGE
	GameSettings.bot_count = 2

	var match_scene := MatchScene.new()
	add_child(match_scene)

	# Allow initialization and spawn frames
	await physics_frames(10)

	check(match_scene.base_core != null, "MatchScene instantiated BaseCore")
	check(match_scene.base_core.health == 1250.0, "BaseCore has full 1250 HP")
	check(match_scene.horde_director != null, "MatchScene instantiated HordeDirector")
	check(match_scene.horde_director.current_wave == 1, "HordeDirector started Wave 1")
	check(match_scene.horde_director.barricades.size() == 4, "MatchScene deployed 4 perimeter barricades")

	# Check HUD integration
	check(match_scene.hud._core_bar != null, "HUD instantiated BaseCore progress bar")
	check(match_scene.hud._core_bar.value == 1250.0, "HUD core bar shows 1250 HP")
	check(match_scene.hud._wave_label != null, "HUD instantiated wave label")
	check(match_scene.hud._wave_label.text.contains("WAVE 1"), "HUD wave label displays WAVE 1")
	check(match_scene.hud._scrap_label != null, "HUD instantiated scrap label")

	# Test BaseCore damage reflects in HUD
	match_scene.base_core.damage(100.0)
	await physics_frames(2)
	check(match_scene.hud._core_bar.value == 1150.0, "BaseCore damage updates HUD progress bar to 1150")

	# Clean up match scene
	match_scene.queue_free()
	GameSettings.match_mode = GameSettings.MatchMode.FREE_FOR_ALL
	await physics_frames(2)


func _test_kid_feedback_calibration_and_sniper() -> void:
	section("Kid Feedback: Game Pacing, Physics Safety, Sniper ADS, and Zombie Lunge (v0.7.1)")

	# 1. GameSettings game_speed calibration
	var original_speed := GameSettings.game_speed
	GameSettings.game_speed = 0.90
	check(is_equal_approx(GameSettings.game_speed, 0.90), "GameSettings.game_speed defaults to calibrated 0.90")
	GameSettings.game_speed = 0.50
	check(is_equal_approx(GameSettings.game_speed, 0.70), "GameSettings.game_speed clamps lower bound to 0.70")
	GameSettings.game_speed = 1.50
	check(is_equal_approx(GameSettings.game_speed, 1.10), "GameSettings.game_speed clamps upper bound to 1.10")
	GameSettings.game_speed = original_speed

	# 2. Actor maximum horizontal speed ceiling (yeet glitch prevention)
	check(Actor.MAX_HORIZONTAL_SPEED == 24.0, "Actor MAX_HORIZONTAL_SPEED constant is 24.0 m/s")
	var dummy_actor := Actor.new()
	add_child(dummy_actor)
	await physics_frames(1)
	dummy_actor.velocity = Vector3(50.0, 0.0, 50.0)
	dummy_actor.move_actor(Vector3.ZERO, false, false, 0.016)
	var horiz_vel := Vector2(dummy_actor.velocity.x, dummy_actor.velocity.z).length()
	check(horiz_vel <= Actor.MAX_HORIZONTAL_SPEED + 0.01, "Actor horizontal velocity is clamped within MAX_HORIZONTAL_SPEED")

	# 3. IceSlick boost ceiling and throttling
	var slick := IceSlick.new()
	slick.boost_speed = 12.0
	slick.slide_direction = Vector3.FORWARD
	dummy_actor.velocity = Vector3.ZERO
	slick._boost_actor(dummy_actor)
	check(dummy_actor.velocity.z < 0.0, "IceSlick imparts forward boost to actor")
	# Instant subsequent boost on same actor is throttled by cooldown
	var vel_before := dummy_actor.velocity
	slick._boost_actor(dummy_actor)
	check(dummy_actor.velocity == vel_before, "IceSlick throttles repetitive boost spam with cooldown")
	slick.free()

	# 4. Longshot Rifle ADS zoom and damage buff
	var longshot := load("res://resources/weapons/longshot.tres") as WeaponData
	check(longshot != null, "longshot.tres loaded successfully")
	check(longshot.zoom_fov == 35.0, "Longshot has zoom_fov configured to 35.0 degrees")
	var long_dart := load("res://resources/darts/long_dart.tres") as DartData
	check(long_dart != null, "long_dart.tres loaded successfully")
	check(long_dart.tag_power == 85.0, "Long dart tag power buffed to 85.0")

	# 5. Player ADS state & Crosshair scoping
	var player := Player.new()
	add_child(player)
	await physics_frames(2)
	player.arsenal.loadout = [longshot]
	player.arsenal.equip_all()
	check(player.arsenal.current().data.zoom_fov == 35.0, "Player equipped Longshot with zoom_fov")

	var crosshair := Crosshair.new()
	add_child(crosshair)
	crosshair.set_scoped(true)
	check(crosshair.scoped, "Crosshair set_scoped(true) enables sniper scope overlay")
	crosshair.set_scoped(false)
	check(not crosshair.scoped, "Crosshair set_scoped(false) restores standard crosshair")
	crosshair.queue_free()

	# 6. Zombie lunge mechanics and pacing
	check(is_equal_approx(dummy_actor.walk_speed, 6.4), "Actor base walk speed softened to 6.4")
	check(is_equal_approx(dummy_actor.sprint_speed, 9.6), "Actor base sprint speed softened to 9.6")

	dummy_actor.set_zombie(true)
	check(is_equal_approx(dummy_actor.walk_speed, 5.8), "Zombie walk speed calibrated to 5.8")
	check(is_equal_approx(dummy_actor.sprint_speed, 8.4), "Zombie sprint speed calibrated to 8.4")

	dummy_actor.velocity = Vector3.ZERO
	dummy_actor.lunge(Vector3.FORWARD, 7.5)
	check(dummy_actor.velocity.z < -7.0, "Actor.lunge imparts forward velocity impulse")

	dummy_actor.queue_free()
	player.queue_free()


