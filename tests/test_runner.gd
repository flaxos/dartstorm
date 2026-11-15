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
	await fast_forward(controller.mode.countdown_seconds + controller.mode.respawn_delay + 0.5)
	check(bot.alive, "bot is back in play")
	var entry := controller.board.entry_for(bot)
	check(entry.outs == 0 and entry.score == 0, "nothing was scored for a tag-out outside play")
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
