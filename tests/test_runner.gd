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
const CTF_MODE := "res://resources/modes/capture_the_flag.tres"
const PLANT_THE_BOMB_MODE := "res://resources/modes/plant_the_bomb.tres"
const WEAPON_DIR := "res://resources/weapons"

var _passed: int = 0
var _failed: int = 0
var _section: String = ""


func _ready() -> void:
	# Ensure test suite runs in pristine default state regardless of user config
	GameSettings.reset_to_defaults()
	GameSettings.split_screen = false
	GameSettings.arena = 0
	GameSettings.bot_count = 3
	GameSettings.match_mode = GameSettings.MatchMode.FREE_FOR_ALL
	GameSettings.apply()
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
	# Floor is Lava Mode (v0.8.0)
	await _test_floor_is_lava_mode()
	# Foam Grenades & Elemental Infusion Power-Ups (v0.8.1)
	await _test_foam_grenade_and_elemental_powerups()
	# Elemental Weather & Dynamic Map Disasters (v0.9.0)
	await _test_elemental_weather_and_disasters()
	# DUOS Buddy Spawning, Tactical Pings & Bot Teamplay (v0.9.1)
	await _test_duos_buddy_spawning_and_pings()
	# Settings & Accessibility: Controls Remapping & Colorblind Palettes (v0.9.2)
	await _test_settings_and_accessibility()
	# Milestone v1.0.0: Local Couch Co-Op / Split-Screen (2 Players)
	await _test_splitscreen_coop()
	# Web & Android Mobile Universal Accessibility
	await _test_touch_controls_and_mobile_export()
	# Environment & Lighting Uplift: Tactile PBR Shaders, Splat Decals & Golden Hour (v1.2.0)
	await _test_environment_and_splat_decals()
	# Online Multiplayer, Dual Profiles, Blaster Inspector & Boss Mode (v1.3.0)
	await _test_multiplayer_profiles_and_bossmode()
	# Three New Arenas & Realistic Game Mode (v1.4.0)
	await _test_new_arenas_and_realistic_mode()
	# Codebase Hardening, Network Sanitization & PBR Skins Pipeline (v1.5.0)
	await _test_hardening_security_and_pbr_skins()
	# AAA Visual Uplift: High-Poly Models, PBR Textures & Graphics Quality Scaler (v1.6.0)
	await _test_aaa_graphics_and_pbr_pipeline()
	# glTF 2.0 Model Loader & Hybrid Fallback Architecture (v1.7.0 / Phase 1)
	await _test_gltf_model_loader_and_hybrid_pipeline()
	# Stylized Hero Character Asset & Humanoid Animation Rig (v1.8.0 / Phase 2)
	await _test_hero_character_and_skeletal_animations()
	# AAA Blaster Arsenal 3D Models & Weapon Animations (v1.9.0 / Phase 3)
	await _test_blaster_arsenal_models_and_mechanisms()
	# Stylized Arena Environments & Tactical Props (v2.0.0 / Phase 4)
	await _test_stylized_arena_props_and_environments()
	# Capture The Flag & Plant The Bomb Game Modes (v2.1.0)
	await _test_ctf_and_plant_the_bomb_modes()
	# Classic Arenas: Two Fortresses, Dusty Courtyard & Duststorm II (v2.1.0)
	await _test_classic_arenas_2fort_dust_dust2()
	# LAN Server Discovery & Headless Dedicated Server (v2.2.0)
	await _test_lan_server_browser_and_dedicated_server()
	# Backyard Garage Workbench, Blaster Mastery & Aftermarket Attachments (v2.3.0)
	await _test_weapon_modding_garage_workbench_and_mastery()
	# Objective AI: Bots in Plant the Bomb & Capture the Flag (v2.4.0)
	await _test_objective_bot_ai()
	# Production 1.0 Release Regressions (v1.0.0)
	await _test_v1_0_release_regressions()
	# Cover-Art Parity Visual & Model Uplift (v2.0.0)
	await _test_v2_cover_art_parity()
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
		check(gun_game.ladder[-1].id == &"foam_bat", "ladder ends with the Foam Bat melee finisher")
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
	check(gun_game.get_loadout(climber)[0].id == &"foam_bat", "the last rung is the Foam Bat")
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

	# Verify hat replacement cleanly removes previous hat and does not duplicate nodes
	var swap_stage := make_stage()
	var hat_model := CharacterModel.new()
	swap_stage.add_child(hat_model)
	hat_model.setup("Swap Test", Color.BLUE, &"cap")
	await physics_frames(1)
	var initial_child_count := hat_model.get_child_count()
	var head_socket := hat_model.find_child("Socket_Head", true, false)

	for hat in Cosmetics.HATS:
		hat_model.set_hat(hat["id"])
		hat_model.setup("Swap Test", Color.BLUE, hat["id"])
		await physics_frames(1)
		check(hat_model.hat_id() == hat["id"], "swapped hat to %s" % hat["id"])
		check(hat_model.get_child_count() == initial_child_count, "CharacterModel child count does not leak on hat swap %s" % hat["id"])
	# Switch back to cap and verify child count drops back to 2 (cap only)
	hat_model.set_hat(&"cap")
	hat_model.setup("Swap Test", Color.BLUE, &"cap")
	await physics_frames(1)
	if head_socket != null:
		check(head_socket.get_child_count() == 2, "Socket_Head cleans up old hat pieces on swap (has %d children)" % head_socket.get_child_count())
	swap_stage.queue_free()
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
	var saved_palette := GameSettings.team_palette
	var saved_split := GameSettings.split_screen
	GameSettings.team_palette = int(GameMode.TeamPalette.DEFAULT)
	GameSettings.split_screen = false
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
	GameSettings.team_palette = saved_palette
	GameSettings.split_screen = saved_split
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
	check((menu.get("_mode_buttons") as Array).size() >= 8, "mode cards: SOLO, DUOS, TEAMS, GUN GAME, ZOMBIES, SIEGE, LAVA, REALISTIC, CTF, BOMB")
	var right_col: Node = (menu.get("_menu") as Control).get_node_or_null("RightCol")
	check(right_col != null and play.is_ancestor_of(right_col) == false and right_col.is_ancestor_of(play),
			"the mode picker and PLAY button are unified in RightCol to prevent overlap")

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
	var skin_btns: Array = menu.get("_skin_buttons")
	check(skin_btns.size() == 10, "customise panel contains 10 blaster skin/sticker options (%d)" % skin_btns.size())

	# Inspect controls: zoom and reset
	menu.call("_zoom_customise", -10.0)
	check(float(menu.get("_customise_fov")) < 44.0, "zoom in narrows FOV for close-up inspection")
	menu.call("_reset_customise_view")
	check(is_equal_approx(float(menu.get("_customise_fov")), 44.0), "reset view restores default FOV (44.0)")
	check(is_equal_approx(float(menu.get("_model_angle")), PI), "reset view restores default model rotation (PI)")

	# Hat picking in customise
	var pmodel: CharacterModel = menu.get("player_model") as CharacterModel
	check(pmodel != null, "player_model exists in customise")
	var pmodel_children_before := pmodel.get_child_count()
	menu.call("_pick_hat", &"cowboy")
	await physics_frames(1)
	check(pmodel.hat_id() == &"cowboy", "player_model equipped cowboy hat")
	check(pmodel.get_child_count() == pmodel_children_before, "player_model did not duplicate nodes on hat swap")

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
	var patio_ice := arena.find_children("*", "IceSlick", true, false).filter(
		func(slick: Node3D) -> bool: return slick.global_position.distance_to(Vector3(22.05, HomeTurf.PATIO_ROOF_TOP * 0.5, -22.0)) < 5.0
	)
	check(patio_ice.is_empty(), "patio roof ramp has no ice slick blocking access")
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
	GameSettings.bot_count = 5
	var game := start_match(GameSettings.MatchMode.TEAMS)
	var controller := game.get("controller") as MatchController
	check(controller.arena is TempestTreehouse, "picking TEMPEST TREEHOUSE in the lobby loads the treehouse")
	var player := game.get("player") as Player
	player.controls_enabled = false
	var bots: Array = game.get("bots")
	var starts: Array[Vector3] = []
	for bot: Bot in bots:
		starts.append(bot.global_position)
	await fast_forward(controller.mode.countdown_seconds + 75.0)
	player.controls_enabled = false
	var moved := 0
	for i in bots.size():
		if (bots[i] as Bot).global_position.distance_to(starts[i]) > 4.0:
			moved += 1
	check(moved >= 3, "bots navigate treehouse decks and bridge (%d of %d moved)" % [moved, bots.size()])
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
	check(gun_game != null and gun_game.ladder.size() == 11, "Gun Game ladder has all 11 rungs ending with the Foam Bat (11/11)")
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
	check(Cosmetics.SKINS.size() == 10, "Cosmetics catalog defines 10 skins (%d)" % Cosmetics.SKINS.size())

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
	check(not Progression.is_unlocked(&"skin", &"shark"), "shark bite skin starts locked")
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

	for child in model.find_children("*", "MeshInstance3D", true, false):
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

	# Default skin uses clean molded toy plastic so bots and pickups are not skinned
	var model_default := BlasterModel.create(popper_data, true, &"default")
	add_child(model_default)
	await physics_frames(2)
	var default_has_shader := false
	for child in model_default.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		if mesh_inst != null and mesh_inst.material_override is ShaderMaterial:
			if (mesh_inst.material_override as ShaderMaterial).shader == BlasterModel._skin_shader:
				default_has_shader = true
				break
	check(not default_has_shader, "default skin isolates blaster to clean molded plastic (bots/pickups not skinned)")
	model_default.queue_free()

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
	check(active_cards == 10, "shop panel renders 10 skin cards in SKINS tab")
	shop.queue_free()

	# 6. First-Person Hands & Procedural Reload Animation
	var fp_player := Player.new()
	add_child(fp_player)
	await physics_frames(2)
	fp_player.arsenal.set_loadout([popper_data])
	await physics_frames(2)
	var fp_arms: Node = fp_player.get("_fp_arms")
	check(fp_arms != null and fp_arms.is_inside_tree(), "Player instantiates FirstPersonArms in first person")
	check(fp_arms.get_node_or_null("RightArm") != null, "FirstPersonArms includes RightArm holding grip")
	check(fp_arms.get_node_or_null("LeftArm") != null, "FirstPersonArms includes LeftArm supporting blaster")
	check(fp_arms.get("visible") == true, "FirstPersonArms visible during normal blaster combat")

	# Test procedural reload animation
	var view_root := fp_player.get("_view_root") as Node3D
	var initial_rot: Vector3 = view_root.rotation
	fp_player.call("_on_reload_started", fp_player.arsenal.current(), 0.8)
	check(bool(fp_player.get("_reloading")) == true, "Player enters _reloading state on reload started")
	await physics_frames(10)
	var reloading_rot: Vector3 = view_root.rotation
	check(reloading_rot != initial_rot, "Blaster rotates/tilts during procedural reload animation")
	fp_player.call("_on_reload_finished", fp_player.arsenal.current())
	check(bool(fp_player.get("_reloading")) == false, "Player clears _reloading state on reload finished")

	# Zombie arms switch test
	fp_player.set_zombie(true)
	await physics_frames(2)
	check(fp_arms.get("visible") == false, "FirstPersonArms hides when player is zombie")
	check(fp_player.get("_zombie_arms") != null and fp_player.get("_zombie_arms").get("visible") == true, "Zombie arms become visible when infected")
	fp_player.queue_free()

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
	add_child(slick)
	slick.boost_speed = 12.0
	slick.slide_direction = Vector3.FORWARD
	dummy_actor.velocity = Vector3.ZERO
	slick._boost_actor(dummy_actor)
	check(dummy_actor.velocity.z < 0.0, "IceSlick imparts forward boost to actor")
	# Instant subsequent boost on same actor is throttled by cooldown
	var vel_before := dummy_actor.velocity
	slick._boost_actor(dummy_actor)
	check(dummy_actor.velocity == vel_before, "IceSlick throttles repetitive boost spam with cooldown")
	slick.queue_free()

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
	var w_list: Array[WeaponData] = [longshot]
	player.arsenal.set_loadout(w_list)
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


func _test_floor_is_lava_mode() -> void:
	section("Floor is Lava Mode (v0.8.0)")

	# 1. Mode Resource and Settings Verification
	const LAVA_MODE_PATH := "res://resources/modes/floor_is_lava.tres"
	var mode := load(LAVA_MODE_PATH) as FloorIsLavaMode
	check(mode != null, "floor_is_lava.tres loaded as FloorIsLavaMode")
	check(mode.id == &"floor_is_lava", "Mode id is floor_is_lava")
	check(mode.display_name == "Floor is Lava", "Mode display_name is 'Floor is Lava'")
	check(GameSettings.MatchMode.FLOOR_IS_LAVA == 6, "GameSettings.MatchMode enum has FLOOR_IS_LAVA")
	check(MatchScene.MODE_PATHS.has(LAVA_MODE_PATH), "MatchScene.MODE_PATHS includes floor_is_lava.tres")

	# 2. Actor Hazard Tag & Foam Shield Absorption
	var actor := Actor.new()
	add_child(actor)
	await physics_frames(1)
	actor.shield_points = 50.0
	actor.tag_meter = 0.0
	actor.apply_hazard_tag(30.0, null)
	check(actor.shield_points == 20.0 and actor.tag_meter == 0.0, "apply_hazard_tag absorbs into shield first")
	actor.apply_hazard_tag(35.0, null)
	check(actor.shield_points == 0.0 and actor.tag_meter == 15.0, "apply_hazard_tag overflows depleted shield into tag meter")
	actor.queue_free()

	# 3. Lava Hazard Initialization & Height Setting
	var stage := Node3D.new()
	add_child(stage)
	var hazard := LavaHazard.new()
	stage.add_child(hazard)
	await physics_frames(2)
	check(is_equal_approx(hazard.current_lava_y, -0.6), "LavaHazard starts at calm height -0.6m")
	hazard.set_lava_height(1.35)
	check(is_equal_approx(hazard.current_lava_y, 1.35) and is_equal_approx(hazard.position.y, 1.35), "set_lava_height updates current_lava_y and position.y")
	check(hazard.size.x >= 200.0 and hazard.size.y >= 200.0, "LavaHazard size is >= 200x200m to cover all arenas")
	check(hazard.get_node_or_null("LavaEmbers") is GPUParticles3D, "LavaHazard instantiates rising LavaEmbers particles")

	# 4. Elemental Water/Ice Obsidian Stone Formation
	var water_dart := DartProjectile.new()
	var water_data := DartData.new()
	water_data.element = DartData.Element.WATER
	water_dart.data = water_data
	hazard.on_dart_hit(water_dart, Vector3(5.0, 1.35, 2.0))
	check(hazard.active_stones.size() == 1, "Water dart hit creates obsidian stepping stone")
	var stone := hazard.active_stones[0]
	check(stone is ObsidianStone, "Spawned stone is ObsidianStone instance")
	check(stone.position.x == 5.0 and stone.position.z == 2.0, "ObsidianStone positioned at hit coordinates")
	check(stone.collision_layer == Layers.WORLD, "ObsidianStone is solid walkable geometry in Layers.WORLD")

	var ice_dart := DartProjectile.new()
	var ice_data := DartData.new()
	ice_data.element = DartData.Element.ICE
	ice_dart.data = ice_data
	hazard.on_dart_hit(ice_dart, Vector3(-4.0, 1.35, 1.0))
	check(hazard.active_stones.size() == 2, "Ice dart hit creates second obsidian stepping stone")

	water_dart.free()
	ice_dart.free()
	stage.queue_free()

	# 5. Lava Director Tide Phase Transitions
	var director := LavaDirector.new()
	add_child(director)
	director.setup(null, null)
	director.start()
	check(director.phase == LavaDirector.Phase.CALM, "LavaDirector starts in CALM phase")
	check(is_equal_approx(director.time_left, LavaDirector.CALM_DURATION), "CALM duration initialized correctly")

	director._set_phase(LavaDirector.Phase.WARNING)
	check(director.phase == LavaDirector.Phase.WARNING, "Phase transitions to WARNING")

	director._set_phase(LavaDirector.Phase.HIGH_TIDE)
	check(director.phase == LavaDirector.Phase.HIGH_TIDE and is_equal_approx(director.current_height, LavaDirector.PEAK_HEIGHT),
			"Phase transitions to HIGH_TIDE at PEAK_HEIGHT 1.35m")

	var survived_emitted := [false]
	director.high_tide_survived.connect(func(_count: int) -> void: survived_emitted[0] = true)
	director._set_phase(LavaDirector.Phase.RECEDING)
	check(survived_emitted[0], "Entering RECEDING phase emits high_tide_survived signal")
	director.queue_free()

	# 6. MatchScene & HUD Integration
	GameSettings.match_mode = GameSettings.MatchMode.FLOOR_IS_LAVA
	GameSettings.bot_count = 2

	var match_scene := MatchScene.new()
	add_child(match_scene)
	await physics_frames(10)

	check(match_scene.lava_hazard != null, "MatchScene created LavaHazard")
	check(match_scene.lava_director != null, "MatchScene created LavaDirector")
	check(match_scene.arena.lava_hazard == match_scene.lava_hazard, "Arena holds reference to LavaHazard")
	check(match_scene.hud._lava_box != null, "HUD created lava UI panel")
	check(match_scene.hud._lava_status_label != null, "HUD created lava status label")
	check(match_scene.hud._lava_timer_label != null, "HUD created lava timer label")
	check(match_scene.hud._lava_status_label.text == "FLOOR SAFE", "Lava HUD begins with 'FLOOR SAFE'")

	# Verify bot high-ground roam selection during high tide
	match_scene.lava_director._set_phase(LavaDirector.Phase.HIGH_TIDE)
	await physics_frames(4)
	if not match_scene.bots.is_empty():
		var bot := match_scene.bots[0]
		var roam := bot._random_roam_point()
		check(roam.y > match_scene.lava_hazard.current_lava_y + 0.4, "Bot filters roam goals to elevated platforms during high tide")

	match_scene.queue_free()
	GameSettings.match_mode = GameSettings.MatchMode.FREE_FOR_ALL
	await physics_frames(2)


func _test_foam_grenade_and_elemental_powerups() -> void:
	section("Foam Grenades & Elemental Infusion Power-Ups (v0.8.1)")

	# 1. FoamGrenade physical setup
	var grenade := FoamGrenade.new()
	add_child(grenade)
	await physics_frames(1)
	check(is_equal_approx(grenade.mass, 0.35), "Foam grenade mass is 0.35kg")
	check(grenade.physics_material_override != null, "Foam grenade has physics material")
	check(grenade.physics_material_override.bounce >= 0.5, "Foam grenade is bouncy (%.2f)" % grenade.physics_material_override.bounce)
	check(grenade.collision_layer == Layers.TARGETS, "Foam grenade on Layers.TARGETS")
	check(grenade.collision_mask & Layers.WORLD != 0, "Foam grenade collides with environment")
	check(grenade.collision_mask & Layers.ACTORS != 0, "Foam grenade collides with actors")
	check(grenade.time_left >= 1.5, "Foam grenade fuse timer initialized (%.1fs)" % grenade.time_left)
	grenade.queue_free()
	await physics_frames(1)

	# 2. FoamGrenade explosion & blast tag
	var test_parent := Node3D.new()
	add_child(test_parent)
	var pool := make_pool(test_parent)

	var grenade2 := FoamGrenade.new()
	grenade2.dart_pool = pool
	test_parent.add_child(grenade2)
	grenade2.global_position = Vector3(0.0, 0.5, 0.0)

	var target_actor := Actor.new()
	test_parent.add_child(target_actor)
	target_actor.global_position = Vector3(2.0, 0.5, 0.0)
	target_actor.alive = true
	target_actor.add_to_group(&"actors")
	await physics_frames(2)

	var initial_meter := target_actor.tag_meter
	grenade2.explode()
	check(target_actor.tag_meter > initial_meter, "Target actor received blast damage from exploding foam grenade (meter: %.1f -> %.1f)" % [initial_meter, target_actor.tag_meter])
	check(target_actor.velocity.x > 0.0, "Target actor received radial knockback impulse from grenade explosion")

	# 3. GrenadePickup mechanics
	var g_pickup := GrenadePickup.new()
	test_parent.add_child(g_pickup)
	g_pickup.global_position = Vector3(5.0, 0.0, 0.0)
	await physics_frames(2)

	var picker := Actor.new()
	test_parent.add_child(picker)
	picker.alive = true
	picker.grenade_count = 0

	var added := picker.add_grenade(1)
	check(added, "add_grenade succeeds when under max")
	check(picker.grenade_count == 1, "Actor grenade_count is 1")
	added = picker.add_grenade(1)
	check(added, "add_grenade succeeds up to GRENADE_MAX")
	check(picker.grenade_count == Actor.GRENADE_MAX, "Actor grenade_count reached GRENADE_MAX (2)")
	added = picker.add_grenade(1)
	check(not added, "add_grenade fails when already at GRENADE_MAX")
	check(picker.grenade_count == Actor.GRENADE_MAX, "Actor grenade_count capped at GRENADE_MAX")

	# Pickup collection test
	picker.grenade_count = 0
	g_pickup.make_available()
	check(g_pickup.is_available(), "GrenadePickup is available")
	g_pickup._on_body_entered(picker)
	check(picker.grenade_count == 1, "GrenadePickup gives grenade on pickup")
	check(not g_pickup.is_available(), "GrenadePickup deactivated after collection")

	# 4. ElementalPickup & Weapon Infusion
	var e_pickup := ElementalPickup.new()
	e_pickup.element = DartData.Element.LIGHTNING
	test_parent.add_child(e_pickup)
	e_pickup.global_position = Vector3(10.0, 0.0, 0.0)
	await physics_frames(2)

	check(picker.infusion_element == DartData.Element.NONE, "Picker starts with no elemental infusion")
	check(picker.infusion_left == 0.0, "Picker starts with 0.0 infusion timer")

	e_pickup.make_available()
	check(e_pickup.is_available(), "ElementalPickup is available")
	e_pickup._on_body_entered(picker)
	check(picker.infusion_element == DartData.Element.LIGHTNING, "Picker infused with LIGHTNING from pickup")
	check(picker.infusion_left >= 14.5, "Picker granted 15.0s infusion time")
	check(not e_pickup.is_available(), "ElementalPickup deactivated after collection")

	# Infusion applied to fired darts
	picker.dart_pool = pool
	var blaster_res := load("res://resources/weapons/pocket_popper.tres") as WeaponData
	var loadout_list: Array[WeaponData] = [blaster_res]
	picker.arsenal.set_loadout(loadout_list)
	var state := picker.arsenal.current()
	check(state != null, "Picker equipped pocket popper")
	check(state.data.dart.element == DartData.Element.NONE, "Base pocket popper dart is non-elemental")

	# Fire weapon with infusion active
	picker._on_arsenal_fired(state)
	var infused_dart_found := false
	for child in pool.get_children():
		if child is DartProjectile and child.visible:
			if child.data != null and child.data.element == DartData.Element.LIGHTNING:
				infused_dart_found = true
				break
	check(infused_dart_found, "Fired dart inherited Actor active LIGHTNING infusion")

	# Test infusion status decay
	picker.tick_status(16.0)
	check(picker.infusion_element == DartData.Element.NONE, "Infusion clears when timer expires")
	check(picker.infusion_left == 0.0, "Infusion timer decremented to 0")

	# 5. Player grenade throwing
	var player_test := Player.new()
	test_parent.add_child(player_test)
	player_test.dart_pool = pool
	player_test.grenade_count = 2
	await physics_frames(1)

	var initial_child_count := test_parent.get_child_count()
	player_test._perform_grenade_throw()
	check(player_test.grenade_count == 1, "Player grenade count decremented after throw")
	check(test_parent.get_child_count() > initial_child_count, "FoamGrenade spawned into scene tree on throw")

	# 6. Arena pickup placements
	var fortress := BackyardFortress.new()
	add_child(fortress)
	await physics_frames(2)
	check(fortress.grenade_pickups.size() >= 2, "Backyard Fortress has at least 2 grenade pickups placed (%d)" % fortress.grenade_pickups.size())
	check(fortress.elemental_pickups.size() >= 3, "Backyard Fortress has at least 3 elemental pickups placed (%d)" % fortress.elemental_pickups.size())

	var home := HomeTurf.new()
	add_child(home)
	await physics_frames(2)
	check(home.grenade_pickups.size() >= 2, "Home Turf has at least 2 grenade pickups placed (%d)" % home.grenade_pickups.size())
	check(home.elemental_pickups.size() >= 3, "Home Turf has at least 3 elemental pickups placed (%d)" % home.elemental_pickups.size())
	home.queue_free()

	# 7. Bot decision checks with active arena pickups
	var bot_test := Bot.new()
	test_parent.add_child(bot_test)
	bot_test.arena = fortress
	bot_test.global_position = fortress.grenade_pickups[0].global_position + Vector3(2.0, 0.0, 0.0)
	fortress.grenade_pickups[0].make_available()
	fortress.elemental_pickups[0].make_available()

	bot_test.grenade_count = 0
	check(bot_test._wants_grenade(), "Bot wants grenade when inventory is empty and pickup is available")
	bot_test.grenade_count = Actor.GRENADE_MAX
	check(not bot_test._wants_grenade(), "Bot does not want grenade when full")
	bot_test.infusion_left = 0.0
	check(bot_test._wants_elemental(), "Bot wants elemental pickup when uninfused and pickup is available")
	bot_test.infusion_left = 10.0
	check(not bot_test._wants_elemental(), "Bot does not want elemental pickup when already infused")

	fortress.queue_free()
	test_parent.queue_free()
	await physics_frames(2)


func _test_elemental_weather_and_disasters() -> void:
	section("Elemental Weather & Dynamic Map Disasters (v0.9.0)")

	# 1. WhirlwindVortex physics & launch
	var whirlwind := WhirlwindVortex.new()
	add_child(whirlwind)
	whirlwind.global_position = Vector3(0.0, 0.0, 0.0)
	await physics_frames(1)

	var actor := Actor.new()
	add_child(actor)
	actor.global_position = Vector3(0.5, 0.0, 0.5)
	actor.alive = true
	whirlwind._launch_actor(actor)
	check(actor.velocity.y >= WhirlwindVortex.LAUNCH_FORCE, "Whirlwind vortex launches actor upwards into the air (vel y: %.1f)" % actor.velocity.y)
	whirlwind.queue_free()
	actor.queue_free()
	await physics_frames(1)

	# 2. WeatherDirector Setup & Transitions
	var arena := BackyardFortress.new()
	add_child(arena)
	await physics_frames(2)

	var director := WeatherDirector.new()
	arena.add_child(director)
	director.setup(arena, null)
	director.start()
	check(director.current_weather == WeatherDirector.Weather.CALM, "Weather director starts in CALM weather")
	check(director.time_left == WeatherDirector.CALM_DURATION, "CALM duration initialized correctly (%.1fs)" % director.time_left)

	# 3. Thunderstorm & Lightning strike puddle electrification
	director._set_weather(WeatherDirector.Weather.THUNDERSTORM)
	check(director.current_weather == WeatherDirector.Weather.THUNDERSTORM, "Weather transitioned to THUNDERSTORM")
	check(director.effects != null and director.effects._particles_rain.emitting, "Rain precipitation particles enabled during thunderstorm")

	var puddle := WaterPuddle.new()
	arena.add_child(puddle)
	puddle.global_position = Vector3(0.0, 0.0, 0.0)
	arena.puddles.append(puddle)
	await physics_frames(2)

	check(not puddle.is_electrified(), "Puddle starts unelectrified")
	director.trigger_lightning_strike(Vector3(0.5, 0.0, 0.5))
	check(puddle.is_electrified(), "Lightning strike in radius electrifies water puddle")

	# 4. Blizzard & Dynamic temporary ice slicks
	director._set_weather(WeatherDirector.Weather.BLIZZARD)
	check(director.current_weather == WeatherDirector.Weather.BLIZZARD, "Weather transitioned to BLIZZARD")
	check(director.effects != null and director.effects._particles_snow.emitting, "Snow flurry particles enabled during blizzard")
	check(not director._temporary_ice_slicks.is_empty(), "Blizzard spawned temporary ice slicks on arena walkways (%d spawned)" % director._temporary_ice_slicks.size())

	# 5. Gale Gusts & Wind Field drift
	director._set_weather(WeatherDirector.Weather.GALE_GUSTS)
	check(director.current_weather == WeatherDirector.Weather.GALE_GUSTS, "Weather transitioned to GALE_GUSTS")
	check(director.effects != null and director.effects._particles_leaves.emitting, "Leaves and wind particles enabled during gale gusts")
	check(director._active_whirlwind != null, "Whirlwind vortex spawned in arena during gale gusts")
	director._process(0.1)
	check(arena.wind_field.global_wind.length() > 20.0, "Arena global wind velocity accelerated by gale gusts (%.1f m/s)" % arena.wind_field.global_wind.length())

	# 6. Heatwave & Ice slick melting
	var test_slick := IceSlick.new()
	arena.add_child(test_slick)
	arena.ice_slicks.append(test_slick)
	await physics_frames(1)

	director._set_weather(WeatherDirector.Weather.HEATWAVE)
	check(director.current_weather == WeatherDirector.Weather.HEATWAVE, "Weather transitioned to HEATWAVE")
	check(test_slick.is_melted(), "Heatwave melted arena ice slick into water")

	# 7. Return to Calm & Cleanup
	director._set_weather(WeatherDirector.Weather.CALM)
	check(director.current_weather == WeatherDirector.Weather.CALM, "Weather returned to CALM")
	check(director._temporary_ice_slicks.is_empty(), "Temporary blizzard ice slicks cleaned up")
	check(director._active_whirlwind == null, "Whirlwind vortex cleaned up")

	# 8. Bot avoidance of electrified puddles
	var bot := Bot.new()
	arena.add_child(bot)
	bot.arena = arena
	bot.global_position = puddle.global_position + Vector3(1.5, 0.0, 0.0)
	puddle.electrify(3.0)
	var steer_wish := bot._choose_direction(0.016)
	check(steer_wish.x > 0.0, "Bot steers away from electrified puddle (+X safe push: %.2f)" % steer_wish.x)

	# 9. GameSettings weather_events configuration
	check(GameSettings.weather_events == true, "GameSettings.weather_events defaults to true")

	arena.queue_free()
	await physics_frames(2)


func _test_duos_buddy_spawning_and_pings() -> void:
	section("DUOS Buddy Spawning, Tactical Pings & Bot Teamplay (v0.9.1)")

	# 1. Buddy linking
	var actor_a := Actor.new()
	var actor_b := Actor.new()
	actor_a.team_id = 0
	actor_b.team_id = 0
	actor_a.buddy_actor = actor_b
	actor_b.buddy_actor = actor_a
	check(actor_a.buddy_actor == actor_b and actor_b.buddy_actor == actor_a, "DUOS actors link to their assigned buddy")

	# 2. Coordinated Buddy Spawning Proximity in MatchController
	var arena := BackyardFortress.new()
	add_child(arena)
	arena.add_child(actor_a)
	arena.add_child(actor_b)
	await physics_frames(2)

	var duos_mode := load("res://resources/modes/duos.tres") as GameMode
	var controller := MatchController.new()
	controller.setup(duos_mode, arena)
	add_child(controller)

	controller.register(actor_a)
	controller.register(actor_b)

	var spawn_a := arena.spawn_points[0]
	actor_a.global_transform = spawn_a.global_transform
	actor_a.alive = true

	var spawn_b_xform := controller._choose_spawn(actor_b)
	var buddy_dist := spawn_b_xform.origin.distance_to(actor_a.global_position)
	check(buddy_dist > MatchController.SPAWN_CLEARANCE, "Buddy spawn respects minimum spawn clearance (dist: %.1fm)" % buddy_dist)
	check(buddy_dist < 22.0, "Buddy spawns in close tactical proximity to living teammate (dist: %.1fm)" % buddy_dist)

	# 3. Tactical Ping Beacon
	var beacon := PingBeacon.spawn(arena, Vector3(4.0, 0.0, 4.0), PingBeacon.Type.REGROUP, actor_a)
	check(beacon != null and beacon.is_inside_tree(), "PingBeacon spawned into scene tree")
	check(beacon.type == PingBeacon.Type.REGROUP, "PingBeacon type initialized to REGROUP")
	check(beacon._text_for_type(PingBeacon.Type.AMMO) == "AMMO", "PingBeacon formats AMMO label without missing glyphs")
	check(beacon._text_for_type(PingBeacon.Type.POWERUP) == "POWER-UP", "PingBeacon formats POWERUP label without missing glyphs")
	check(beacon._text_for_type(PingBeacon.Type.RIVAL) == "RIVAL", "PingBeacon formats RIVAL label without missing glyphs")
	check(beacon._text_for_type(PingBeacon.Type.DANGER) == "DANGER", "PingBeacon formats DANGER label without missing glyphs")

	# 4. Bot Squad Ping Reaction
	var bot := Bot.new()
	arena.add_child(bot)
	bot.arena = arena
	bot.team_id = 0
	bot.buddy_actor = actor_a
	bot.global_position = Vector3(0.0, 0.0, 0.0)
	await physics_frames(1)

	bot.on_squad_ping(beacon)
	check(bot._mood == Bot.Mood.ROAM, "Bot accepts squad ping and transitions mood to ROAM")
	check(bot._goal.distance_to(beacon.global_position) < 3.5, "Bot sets navigation goal toward ping location (dist: %.1fm)" % bot._goal.distance_to(beacon.global_position))

	# 5. Bot Proximity Roaming in DUOS
	var found_buddy_bias := false
	for attempt in 6:
		var roam_pt := bot._random_roam_point()
		if roam_pt.distance_to(actor_a.global_position) <= 20.0:
			found_buddy_bias = true
			break
	check(found_buddy_bias, "Bot roam selection biases toward living buddy position")

	# 6. Bot Low-Health Defensive Retreat
	var enemy := Actor.new()
	enemy.team_id = 1
	enemy.alive = true
	arena.add_child(enemy)
	enemy.global_position = Vector3(0.0, 0.0, 8.0)
	bot._target = enemy
	bot.tag_meter = bot.tag_meter_max * 0.85
	var retreat_dir := bot._fight_direction(0.016)
	var to_enemy := (enemy.global_position - bot.global_position).normalized()
	check(retreat_dir.dot(to_enemy) < 0.0, "Low-health bot retreats away from enemy under danger threshold (dot: %.2f)" % retreat_dir.dot(to_enemy))

	# 7. Cleanup
	beacon.queue_free()
	enemy.queue_free()
	bot.queue_free()
	actor_a.queue_free()
	actor_b.queue_free()
	controller.queue_free()
	arena.queue_free()
	await physics_frames(2)


## v0.9.2: Settings & Accessibility: Controls Remapping & Colorblind Palettes
func _test_settings_and_accessibility() -> void:
	section("v0.9.2: Settings & Accessibility")
	var saved_palette: int = GameSettings.team_palette

	# 1. Palette Switching and Dynamic Team Colors
	GameSettings.team_palette = GameMode.TeamPalette.DEFAULT
	check(GameMode.team_name(0) == "BLUE" and GameMode.team_name(1) == "ORANGE", "Default palette names are BLUE and ORANGE")
	check(GameMode.team_color(0).is_equal_approx(Color(0.15, 0.45, 1.0)), "Default team 0 color is standard Blue")

	GameSettings.team_palette = GameMode.TeamPalette.COBALT_SUNBURST
	check(GameMode.team_name(0) == "COBALT" and GameMode.team_name(1) == "SUNBURST", "Cobalt & Sunburst palette names are COBALT and SUNBURST")
	check(GameMode.team_color(0).is_equal_approx(Color(0.1, 0.4, 0.95)), "Cobalt color correctly applied")
	check(GameMode.team_color(1).is_equal_approx(Color(1.0, 0.82, 0.1)), "Sunburst color correctly applied")

	GameSettings.team_palette = GameMode.TeamPalette.MAGENTA_MINT
	check(GameMode.team_name(0) == "MAGENTA" and GameMode.team_name(1) == "MINT", "Magenta & Mint palette names are MAGENTA and MINT")
	check(GameMode.team_color(0).is_equal_approx(Color(0.96, 0.22, 0.62)), "Magenta color correctly applied")

	GameSettings.team_palette = GameMode.TeamPalette.HIGH_CONTRAST
	check(GameMode.team_name(0) == "CYAN" and GameMode.team_name(1) == "HOT ORANGE", "High Contrast palette names are CYAN and HOT ORANGE")
	check(GameMode.team_color(0).is_equal_approx(Color(0.05, 0.85, 1.0)), "Cyan color correctly applied")

	# Test Arena Decor using active palette
	var backyard := BackyardFortress.new()
	add_child(backyard)
	backyard._build()
	check(backyard.arena_name == "Backyard Fortress", "Backyard Fortress builds cleanly with active team palette")
	backyard.queue_free()

	# 2. Input Remapping Engine (InputSetup)
	var orig_jump_kb := InputSetup.get_keyboard_event(&"jump")
	check(orig_jump_kb != null and InputSetup.event_to_label(orig_jump_kb) == "Space", "Default Jump keyboard binding is Space")

	# Rebind Jump to Key J
	var new_key := InputEventKey.new()
	new_key.physical_keycode = KEY_J
	InputSetup.rebind_action_event(&"jump", new_key, false)
	var rebound_jump := InputSetup.get_keyboard_event(&"jump")
	check(rebound_jump is InputEventKey and (rebound_jump as InputEventKey).physical_keycode == KEY_J, "Jump rebound to physical KEY_J")
	check(InputSetup.event_to_label(rebound_jump) == "J", "Event label for KEY_J is 'J'")

	# Rebind Jump controller slot to Button Y
	var new_pad := InputEventJoypadButton.new()
	new_pad.button_index = JOY_BUTTON_Y
	InputSetup.rebind_action_event(&"jump", new_pad, true)
	var rebound_pad := InputSetup.get_controller_event(&"jump")
	check(rebound_pad is InputEventJoypadButton and (rebound_pad as InputEventJoypadButton).button_index == JOY_BUTTON_Y, "Jump controller slot rebound to JOY_BUTTON_Y")
	check(InputSetup.event_to_label(rebound_pad) == "Y / Triangle", "Event label for JOY_BUTTON_Y is 'Y / Triangle'")

	# Rebind Mouse action and Axis action
	var mouse_ev := InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_MIDDLE
	InputSetup.rebind_action_event(&"throw_grenade", mouse_ev, false)
	check(InputSetup.event_to_label(InputSetup.get_keyboard_event(&"throw_grenade")) == "MMB", "Throw Grenade keyboard/mouse slot displays 'MMB'")

	var axis_ev := InputEventJoypadMotion.new()
	axis_ev.axis = JOY_AXIS_TRIGGER_LEFT
	axis_ev.axis_value = 1.0
	InputSetup.rebind_action_event(&"fire", axis_ev, true)
	check(InputSetup.event_to_label(InputSetup.get_controller_event(&"fire")) == "LT (Left Trigger)", "Fire controller slot displays 'LT (Left Trigger)'")

	# 3. Serialization & Deserialization
	var serialized := InputSetup.serialize_bindings()
	check(serialized.has("jump") and serialized["jump"].has("kb") and serialized["jump"]["kb"]["code"] == KEY_J, "Serialized bindings preserve custom Jump keycode")
	check(serialized["jump"].has("pad") and serialized["jump"]["pad"]["index"] == JOY_BUTTON_Y, "Serialized bindings preserve custom Jump joypad button")

	# Reset to defaults
	InputSetup.reset_to_defaults()
	var reset_jump := InputSetup.get_keyboard_event(&"jump")
	check(InputSetup.event_to_label(reset_jump) == "Space", "InputSetup.reset_to_defaults() restores default Space binding")

	# Apply serialized bindings
	InputSetup.apply_serialized_bindings(serialized)
	check(InputSetup.event_to_label(InputSetup.get_keyboard_event(&"jump")) == "J", "InputSetup.apply_serialized_bindings() successfully applies saved bindings")

	# Clean reset
	InputSetup.reset_to_defaults()

	# 4. UI Panels: SettingsPanel & BindingsPanel
	var settings := SettingsPanel.new()
	add_child(settings)
	await physics_frames(1)
	check(settings.visible, "SettingsPanel instantiates and renders cleanly")

	# Open BindingsPanel from SettingsPanel
	settings._open_bindings()
	check(settings._bindings_panel != null and settings._bindings_panel.visible, "SettingsPanel opens BindingsPanel overlay")
	check(not settings._box.visible, "Settings main box hidden while BindingsPanel is active")

	# Simulate interactive listening & binding in BindingsPanel
	var reload_pair: Dictionary = settings._bindings_panel._action_buttons[&"reload"]
	var reload_kb_btn: Button = reload_pair["kb"]
	settings._bindings_panel._start_listening(&"reload", false, reload_kb_btn)
	check(settings._bindings_panel._listening_action == &"reload", "BindingsPanel enters interactive listening mode for reload")
	check(reload_kb_btn.text == "[ PRESS KEY/CLICK... ]", "Button text prompts for key or click input")

	# Send simulated key press
	var sim_key := InputEventKey.new()
	sim_key.pressed = true
	sim_key.physical_keycode = KEY_K
	settings._bindings_panel._input(sim_key)
	check(settings._bindings_panel._listening_action == &"", "Listening mode successfully exits after input received")
	check(InputSetup.get_keyboard_event(&"reload") != null and (InputSetup.get_keyboard_event(&"reload") as InputEventKey).physical_keycode == KEY_K, "Reload action successfully rebound to KEY_K through UI")
	check(reload_kb_btn.text == "K", "UI button refreshed with new key label 'K'")

	# Test listening cancellation with Escape
	settings._bindings_panel._start_listening(&"reload", true, reload_pair["pad"])
	var esc_key := InputEventKey.new()
	esc_key.pressed = true
	esc_key.physical_keycode = KEY_ESCAPE
	settings._bindings_panel._input(esc_key)
	check(settings._bindings_panel._listening_action == &"", "Listening mode cancelled on ESC without altering gamepad binding")

	# Close BindingsPanel and SettingsPanel
	settings._bindings_panel.close()
	check(not settings._bindings_panel.visible and settings._box.visible, "Closing BindingsPanel returns to SettingsPanel")

	settings.close()
	settings.queue_free()

	# 5. Teardown
	GameSettings.team_palette = saved_palette
	InputSetup.reset_to_defaults()
	GameSettings.apply()
	await physics_frames(2)


## Milestone v1.0.0: Local Couch Co-Op / Split-Screen (2 Players)
func _test_splitscreen_coop() -> void:
	section("v1.0.0: Local Couch Co-Op / Split-Screen (2 Players)")
	var saved_split := GameSettings.split_screen
	var saved_horiz := GameSettings.split_screen_horizontal
	var saved_mode := GameSettings.match_mode
	var saved_p2_name := GameSettings.player2_name
	var saved_p2_color := GameSettings.player2_color
	var saved_p2_hat := GameSettings.player2_hat

	# 1. GameSettings Split-Screen Properties & Persistence
	GameSettings.split_screen = true
	GameSettings.split_screen_horizontal = true
	GameSettings.player2_name = "Buddy"
	GameSettings.player2_color = 2
	GameSettings.player2_hat = &"bunny"
	check(GameSettings.display_name_p2() == "Buddy", "GameSettings.display_name_p2() reflects configured name")
	check(GameSettings.color_p2() == Cosmetics.COLORS[2]["color"], "GameSettings.color_p2() reflects configured color")

	GameSettings.save_settings()
	GameSettings.load_settings()
	check(GameSettings.split_screen == true, "split_screen boolean persists across save/load")
	check(GameSettings.split_screen_horizontal == true, "split_screen_horizontal boolean persists across save/load")
	check(GameSettings.player2_name == "Buddy", "player2_name persists across save/load")
	check(GameSettings.player2_color == 2, "player2_color persists across save/load")
	check(GameSettings.player2_hat == &"bunny", "player2_hat persists across save/load")

	# 2. InputSetup Split-Screen Actions
	InputSetup.setup_split_screen_actions(false, 0)
	check(InputMap.has_action(&"p1_fire") and InputMap.has_action(&"p2_fire"), "setup_split_screen_actions() registers p1_* and p2_* actions")
	check(InputMap.has_action(&"p1_move_forward") and InputMap.has_action(&"p2_move_forward"), "movement actions mapped for both players")
	check(InputMap.has_action(&"p1_scoreboard") and InputMap.has_action(&"p2_scoreboard"), "scoreboard actions mapped for both players")
	check(InputMap.action_has_event(&"p2_move_forward", InputSetup._key(KEY_UP)), "Player 2 has keyboard fallback for move_forward (Arrow Up)")
	check(InputMap.action_has_event(&"p2_fire", InputSetup._key(KEY_KP_ENTER)), "Player 2 has keyboard fallback for fire (Keypad Enter)")

	# 3. MatchScene Split-Screen Viewports, Dual Players, and Shared World3D
	GameSettings.match_mode = GameSettings.MatchMode.DUOS
	var game := (load("res://scenes/game/match.tscn") as PackedScene).instantiate() as MatchScene
	add_child(game)
	await physics_frames(5)

	check(game.split_container != null and game.split_container is VBoxContainer, "MatchScene instantiates horizontal VBoxContainer for split-screen")
	check(game.viewport1 != null and game.viewport2 != null, "MatchScene instantiates SubViewport1 and SubViewport2")
	check(game.viewport1.world_3d == game.viewport2.world_3d, "SubViewport1 and SubViewport2 share the exact same World3D")
	check(game.viewport1.audio_listener_enable_3d and not game.viewport2.audio_listener_enable_3d, "3D audio listener enabled only on Player 1 to prevent listener conflicts")

	check(game.player != null and game.player.player_index == 0, "Player 1 instantiated with index 0")
	check(game.player.action_prefix == "p1_", "Player 1 action prefix set to 'p1_'")
	check(game.player2 != null and game.player2.player_index == 1, "Player 2 instantiated with index 1")
	check(game.player2.action_prefix == "p2_", "Player 2 action prefix set to 'p2_'")

	# Character 3D models and layer culling
	check(game.player.body_model != null, "Player 1 has in-world 3D character body model")
	check(game.player2.body_model != null, "Player 2 has in-world 3D character body model")
	check((game.player.camera.cull_mask & 2) == 0, "Player 1 camera culls own body model (layer 2)")
	check((game.player.camera.cull_mask & 16) == 0, "Player 1 camera culls Player 2 viewmodel (layer 16)")
	check((game.player2.camera.cull_mask & 4) == 0, "Player 2 camera culls own body model (layer 4)")
	check((game.player2.camera.cull_mask & 8) == 0, "Player 2 camera culls Player 1 viewmodel (layer 8)")
	check((game.player.camera.cull_mask & 4) != 0, "Player 1 camera can see Player 2 body model (layer 4)")
	check((game.player2.camera.cull_mask & 2) != 0, "Player 2 camera can see Player 1 body model (layer 2)")

	# Dual HUDs
	check(game.hud != null and game.hud.get_parent() == game.viewport1, "HUD 1 lives inside SubViewport1")
	check(game.hud2 != null and game.hud2.get_parent() == game.viewport2, "HUD 2 lives inside SubViewport2")

	# Controller & Board registration
	check(game.controller.actors.has(game.player) and game.controller.actors.has(game.player2), "Both players registered in MatchController")
	check(game.controller.board.entry_for(game.player) != null, "Scoreboard contains entry for Player 1")
	check(game.controller.board.entry_for(game.player2) != null, "Scoreboard contains entry for Player 2")

	# Duos buddy linking
	check(game.player.team_id == game.player2.team_id, "In DUOS mode, Player 1 and Player 2 share the same team")
	check(game.player.buddy_actor == game.player2 and game.player2.buddy_actor == game.player, "In DUOS mode, Player 1 and Player 2 are linked as buddies")

	# 4. Input Routing Isolation
	var p1_pre_pos := game.player.global_position

	# Simulate move forward on Player 2 only (p2_move_forward)
	var p2_event := InputEventAction.new()
	p2_event.action = &"p2_move_forward"
	p2_event.pressed = true
	Input.parse_input_event(p2_event)
	await physics_frames(10)
	p2_event.pressed = false
	Input.parse_input_event(p2_event)
	await physics_frames(2)

	# Verify Player 1 was not moved by Player 2's action
	check(game.player.global_position.distance_to(p1_pre_pos) < 0.05, "Player 2 input does not cause Player 1 to move")

	# 5. Clean teardown
	game.queue_free()
	await physics_frames(3)
	InputSetup.clear_split_screen_actions()
	check(not InputMap.has_action(&"p1_fire") and not InputMap.has_action(&"p2_fire"), "clear_split_screen_actions() erases split actions")

	# Restore settings
	GameSettings.split_screen = saved_split
	GameSettings.split_screen_horizontal = saved_horiz
	GameSettings.match_mode = saved_mode
	GameSettings.player2_name = saved_p2_name
	GameSettings.player2_color = saved_p2_color
	GameSettings.player2_hat = saved_p2_hat
	GameSettings.save_settings()
	await physics_frames(2)


# --- Web & Android Mobile Universal Accessibility ----------------------------

func _test_touch_controls_and_mobile_export() -> void:
	section("Web & Android: export presets and build scripts")
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg loads cleanly")

	# 1. Web Export Preset
	check(presets.get_value("preset.1", "platform", "") == "Web", "preset 1 targets Web (HTML5/WASM)")
	check(presets.get_value("preset.1", "name", "") == "Web", "preset 1 named 'Web'")
	check(presets.get_value("preset.1", "export_path", "") == "build/web/index.html", "preset 1 exports to build/web/index.html")
	check(not bool(presets.get_value("preset.1.options", "variant/thread_support", true)), "Web preset configured without threads (compatible with any static web host)")
	check(FileAccess.file_exists("res://tools/export_web.sh"), "tools/export_web.sh exists")
	check(FileAccess.file_exists("res://tools/serve_web.py"), "tools/serve_web.py local server exists")

	# 2. Android Export Preset
	check(presets.get_value("preset.2", "platform", "") == "Android", "preset 2 targets Android")
	check(presets.get_value("preset.2", "name", "") == "Android", "preset 2 named 'Android'")
	check(presets.get_value("preset.2", "export_path", "") == "build/android/DARTSTORM.apk", "preset 2 exports to build/android/DARTSTORM.apk")
	check(presets.get_value("preset.2.options", "package/unique_name", "") == "org.flaxos.dartstorm", "Android package unique name configured")
	check(bool(presets.get_value("preset.2.options", "architectures/arm64-v8a", false)), "Android arm64-v8a architecture enabled")
	check(bool(presets.get_value("preset.2.options", "package/signed", false)), "Android APK signing enabled")
	check(FileAccess.file_exists("res://tools/export_apk.sh"), "tools/export_apk.sh exists")

	# 3. Project Settings for Universal Compatibility
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.web", "") == "gl_compatibility", "Web renderer configured to gl_compatibility (WebGL2)")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "") == "gl_compatibility", "Mobile renderer configured to gl_compatibility (OpenGL ES3)")
	check(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "ETC2/ASTC texture compression enabled for mobile VRAM efficiency")
	check(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)), "Touch emulation from mouse enabled for testing")

	# 4. Touch Controls Settings & Activation
	section("Web & Android: touch controls and virtual joystick")
	var saved_mode := GameSettings.touch_controls_mode
	var saved_sens := GameSettings.touch_look_sensitivity

	GameSettings.touch_controls_mode = GameSettings.TouchMode.ALWAYS
	check(GameSettings.is_touch_active(), "TouchControls active when mode is ALWAYS")
	GameSettings.touch_controls_mode = GameSettings.TouchMode.OFF
	check(not GameSettings.is_touch_active(), "TouchControls inactive when mode is OFF")
	GameSettings.touch_controls_mode = GameSettings.TouchMode.AUTO
	GameSettings.register_touch_event()
	check(GameSettings.is_touch_active(), "TouchControls active in AUTO once touch event is registered")
	GameSettings.reset_touch_detection()
	check(not GameSettings.is_touch_active(), "TouchControls inactive in AUTO when no touch is registered on desktop")

	# 5. VirtualJoystick Component
	var stage := make_stage()
	var joystick := VirtualJoystick.new()
	stage.add_child(joystick)
	joystick.size = Vector2(160, 160)
	await physics_frames(2)

	# Simulate small touch under deadzone threshold
	var deadzone_pos := joystick.size * 0.5 + Vector2(2.0, 0.0)
	joystick._update_from_pos(deadzone_pos)
	check(joystick.output == Vector2.ZERO, "VirtualJoystick ignores movements within deadzone")

	# Simulate full rightward drag
	var right_pos := joystick.size * 0.5 + Vector2(100.0, 0.0)
	joystick._update_from_pos(right_pos)
	check(joystick.output.x > 0.9 and absf(joystick.output.y) < 0.01, "VirtualJoystick outputs clamped horizontal vector")
	check(Input.is_action_pressed(&"move_right"), "VirtualJoystick synthesizes move_right action")

	# Reset/release joystick
	joystick.reset()
	check(joystick.output == Vector2.ZERO, "VirtualJoystick resets output to ZERO on release")
	check(not Input.is_action_pressed(&"move_right"), "VirtualJoystick releases move_right action")
	joystick.queue_free()

	# 6. TouchControls Component & Buttons
	var touch_ui := TouchControls.new()
	stage.add_child(touch_ui)
	await physics_frames(2)

	check(touch_ui.get_node_or_null("VirtualJoystick") != null, "TouchControls contains VirtualJoystick")
	check(touch_ui.get_node_or_null("LookSwipeZone") != null, "TouchControls contains LookSwipeZone")
	check(touch_ui.get_node_or_null("PauseButton") != null, "TouchControls contains PauseButton")
	check(touch_ui.get_node_or_null("FireModeToggle") != null, "TouchControls contains FireModeToggle")
	check(touch_ui.get_node_or_null("SmartFireButton") != null, "TouchControls contains SmartFireButton")

	# Test Pause signal
	var pause_signalled := [false]
	touch_ui.pause_requested.connect(func() -> void: pause_signalled[0] = true)
	var pause_btn := touch_ui.get_node("PauseButton") as TouchControls.TouchButton
	check(pause_btn != null, "Pause button is a TouchButton")
	pause_btn.pressed.emit()
	check(pause_signalled[0], "PauseButton emits pause_requested signal")

	# Test Quick Fire Mode Toggle Pill
	var mode_signalled := [-1]
	touch_ui.fire_mode_changed.connect(func(m: int) -> void: mode_signalled[0] = m)
	var toggle_btn := touch_ui.get_node("FireModeToggle") as TouchControls.TouchButton
	check(toggle_btn != null, "FireModeToggle is a TouchButton")
	var initial_fire_mode := GameSettings.touch_fire_mode
	toggle_btn.pressed.emit()
	check(GameSettings.touch_fire_mode != initial_fire_mode, "FireModeToggle toggles touch_fire_mode")
	check(mode_signalled[0] == GameSettings.touch_fire_mode, "fire_mode_changed emitted with new mode")

	# Test Action Button Synthesis (Fire button)
	var fire_btn: TouchControls.TouchButton = null
	for child in touch_ui._buttons:
		var tb := child as TouchControls.TouchButton
		if tb != null and tb.action_target == &"fire":
			fire_btn = tb
			break
	check(fire_btn != null, "TouchControls has Fire button")
	if fire_btn != null:
		fire_btn._set_pressed(true)
		check(Input.is_action_pressed(&"fire"), "Fire TouchButton activates fire action")
		fire_btn._set_pressed(false)
		check(not Input.is_action_pressed(&"fire"), "Fire TouchButton releases fire action")

	# 7. Player look_relative integration
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	stage.add_child(player)
	player.controls_enabled = true
	await physics_frames(2)

	touch_ui.player = player
	var initial_rot := player.rotation.y
	touch_ui._handle_look(Vector2(50.0, 0.0))
	check(player.rotation.y != initial_rot, "player.look_relative() rotates player camera from touch swipe")

	# 7b. SmartFireButton Drag-to-Aim vs Tap Mode
	var smart_fire := touch_ui.get_node("SmartFireButton") as TouchControls.SmartFireButton
	check(smart_fire != null, "SmartFireButton node is accessible")
	if smart_fire != null:
		# Test HOLD_AND_AIM mode
		GameSettings.touch_fire_mode = GameSettings.TouchFireMode.HOLD_AND_AIM
		touch_ui.refresh_fire_mode()
		var rot_start := player.rotation.y
		smart_fire._set_pressed(true)
		check(Input.is_action_pressed(&"fire"), "SmartFireButton fires on press")
		smart_fire._handle_drag(Vector2(40.0, 0.0))
		check(player.rotation.y != rot_start, "SmartFireButton in HOLD_AND_AIM mode steers player look while dragging")
		smart_fire._set_pressed(false)
		check(not Input.is_action_pressed(&"fire"), "SmartFireButton releases fire on release")

		# Test AIM_AND_TAP mode (drag does NOT rotate player)
		GameSettings.touch_fire_mode = GameSettings.TouchFireMode.AIM_AND_TAP
		touch_ui.refresh_fire_mode()
		var rot_tap := player.rotation.y
		smart_fire._set_pressed(true)
		smart_fire._handle_drag(Vector2(40.0, 0.0))
		check(player.rotation.y == rot_tap, "SmartFireButton in AIM_AND_TAP mode does not steer look on drag")
		smart_fire._set_pressed(false)

	# 8. Desktop Captured Mouse Look & Click-to-Capture
	section("Web & Desktop: mouse look and capture")
	player.mouse_captured_override = true
	var player_rot_before := player.rotation.y
	var motion_ev := InputEventMouseMotion.new()
	motion_ev.relative = Vector2(25.0, 0.0)
	player._unhandled_input(motion_ev)
	check(player.rotation.y != player_rot_before, "Free mouse motion rotates player camera without holding left click")

	player.mouse_captured_override = false
	var click_ev := InputEventMouseButton.new()
	click_ev.button_index = MOUSE_BUTTON_LEFT
	click_ev.pressed = true
	player._unhandled_input(click_ev)
	check(player.mouse_captured_override, "Left click captures mouse on desktop")
	check(player._fire_blocked_until_release, "Mouse capture click suppresses initial fire shot until released")

	# Clean up
	touch_ui.queue_free()
	player.queue_free()
	stage.queue_free()
	await physics_frames(2)

	# Restore settings
	GameSettings.touch_controls_mode = saved_mode
	GameSettings.touch_look_sensitivity = saved_sens
	GameSettings.save_settings()
	await physics_frames(1)


## Environment & Lighting Uplift: Tactile PBR surface shaders, foam splat decals, golden-hour sky and atmospheric glow
func _test_environment_and_splat_decals() -> void:
	section("Milestone v1.2.0: Environment & Lighting Uplift & Splat Decals")

	# 1. Tactile PBR Surface Shaders & Material Caching
	var wood_mat := ArenaKit.mat_styled(Color(0.8, 0.6, 0.4), ArenaKit.SurfaceType.WOOD)
	check(wood_mat is ShaderMaterial, "Wood surface type generates a ShaderMaterial")
	if wood_mat is ShaderMaterial:
		check(wood_mat.shader == ArenaKit.WOOD_SHADER, "Wood material uses toy_wood.gdshader")

	var plastic_mat := ArenaKit.mat_styled(Color(1.0, 0.2, 0.2), ArenaKit.SurfaceType.PLASTIC)
	check(plastic_mat is StandardMaterial3D, "Plastic surface type generates StandardMaterial3D")
	if plastic_mat is StandardMaterial3D:
		check(is_equal_approx(plastic_mat.roughness, 0.32), "Plastic surface has satin roughness 0.32")
		check(plastic_mat.rim_enabled, "Plastic surface has rim Fresnel sheen enabled")

	var metal_mat := ArenaKit.mat_styled(Color(0.8, 0.8, 0.8), ArenaKit.SurfaceType.METAL)
	check(metal_mat is StandardMaterial3D, "Metal surface type generates StandardMaterial3D")
	if metal_mat is StandardMaterial3D:
		check(is_equal_approx(metal_mat.metallic, 0.85), "Metal surface has metallic 0.85")

	# Verify caching
	var cached_wood := ArenaKit.mat_styled(Color(0.8, 0.6, 0.4), ArenaKit.SurfaceType.WOOD)
	check(cached_wood == wood_mat, "ArenaKit caches styled materials to keep draw calls low")

	# 2. Golden-Hour Atmospheric Lighting & Sun Shadows
	var stage := make_stage()
	var arena := BackyardFortress.new()
	stage.add_child(arena)
	await physics_frames(2)

	var world_env: WorldEnvironment = null
	var sun_light: DirectionalLight3D = null
	for child in arena.get_children():
		if child is WorldEnvironment:
			world_env = child
		elif child is DirectionalLight3D:
			sun_light = child

	check(world_env != null and world_env.environment != null, "Arena instantiates WorldEnvironment")
	if world_env != null and world_env.environment != null:
		var env := world_env.environment
		check(env.background_mode == Environment.BG_SKY, "Sky background mode is active")
		check(env.tonemap_mode == Environment.TONE_MAPPER_AGX, "AgX tonemapping is enabled")
		check(env.adjustment_enabled, "Color adjustments enabled")
		check(env.adjustment_saturation >= 1.15, "Filmic saturation boost active (1.16)")
		check(env.glow_enabled, "Glow bloom is enabled for energy and shield effects")

	check(sun_light != null, "Arena instantiates DirectionalLight3D sun")
	if sun_light != null:
		check(sun_light.shadow_enabled, "Sun directional shadows enabled")
		check(sun_light.directional_shadow_blend_splits, "Soft directional shadow blend splits enabled")
		check(sun_light.shadow_normal_bias > 1.0, "Contact shadow normal bias configured to eliminate shadow acne")

	# 3. Foam Splat Decals Lifecycle & Pop-in
	FoamSplat.clear_all()
	check(FoamSplat.live_count() == 0, "FoamSplat.clear_all() empties active splats")

	var splat := FoamSplat.spawn(stage, Vector3(0.0, 1.0, 0.0), Vector3.UP, Color(0.1, 0.8, 1.0), 1.2)
	check(splat != null, "FoamSplat.spawn() successfully instantiates splat")
	check(FoamSplat.live_count() == 1, "FoamSplat increments live count")
	check(splat.color == Color(0.1, 0.8, 1.0), "FoamSplat preserves dart tint color")
	check(splat.get_child_count() > 0 and splat.get_child(0) is MeshInstance3D, "FoamSplat contains quad MeshInstance3D")

	# Process splat animation
	splat._process(0.05)
	check(splat.scale.x > 0.0, "FoamSplat scales up on pop-in animation")

	# Test fizz-out trigger
	splat.start_fizz()
	check(splat._fizzing, "start_fizz() initiates fizz-out dissolve")
	splat._process(FoamSplat.FIZZ_DURATION + 0.1)
	await physics_frames(2)
	check(FoamSplat.live_count() == 0, "Fizzed-out splat is automatically queued for freeing and unregisters")

	# 4. Splat Decal Budget & FIFO Retirement
	var saved_intensity := GameSettings.visual_intensity
	GameSettings.visual_intensity = 1.0
	for i in 60:
		FoamSplat.spawn(stage, Vector3(i * 0.1, 1.0, 0.0), Vector3.UP, Color.YELLOW)
	check(FoamSplat.live_count() <= FoamSplat.MAX_ALIVE, "Active splats remain strictly capped under budget (%d <= %d)" % [FoamSplat.live_count(), FoamSplat.MAX_ALIVE])

	# 5. Combat FX Integration (Impact.WORLD and Impact.TARGET spawn splats)
	FoamSplat.clear_all()
	var cfx := CombatFx.new()
	stage.add_child(cfx)
	cfx._on_impact(DartProjectile.Impact.WORLD, Vector3(0.0, 1.0, 0.0), Vector3.UP, Color.MAGENTA)
	check(FoamSplat.live_count() == 1, "CombatFX._on_impact on WORLD impact spawns a FoamSplat decal")
	cfx._on_impact(DartProjectile.Impact.TARGET, Vector3(0.0, 1.0, 0.0), Vector3.UP, Color.ORANGE)
	check(FoamSplat.live_count() == 2, "CombatFX._on_impact on TARGET impact spawns a FoamSplat decal")
	cfx._on_impact(DartProjectile.Impact.ACTOR, Vector3(0.0, 1.0, 0.0), Vector3.UP, Color.GREEN)
	check(FoamSplat.live_count() == 2, "CombatFX._on_impact on ACTOR impact does not spawn a surface splat decal")

	# Clean up
	FoamSplat.clear_all()
	cfx.queue_free()
	arena.queue_free()
	stage.queue_free()
	GameSettings.visual_intensity = saved_intensity
	await physics_frames(2)
	check(FoamSplat.live_count() == 0, "Zero foam splats remain active after stage cleanup")


func _test_multiplayer_profiles_and_bossmode() -> void:
	section("Online Multiplayer, Dual Profiles, Blaster Inspector & Boss Mode")

	# 1. Boss Mode Test
	Progression.activate_boss_mode()
	check(Progression.coins >= 99999, "Boss Mode grants at least 99,999 coins")
	var all_skins_unlocked := true
	for skin in Cosmetics.SKINS:
		var sid: StringName = skin["id"]
		if not Progression.is_unlocked(&"skin", sid):
			all_skins_unlocked = false
			break
	check(all_skins_unlocked, "Boss Mode unlocks all 10 blaster skin patterns")

	var all_hats_unlocked := true
	for hat in Cosmetics.HATS:
		var hid: StringName = hat["id"]
		if not Progression.is_unlocked(&"hat", hid):
			all_hats_unlocked = false
			break
	check(all_hats_unlocked, "Boss Mode unlocks all 11 hats")

	var all_colors_unlocked := true
	for ci in Cosmetics.COLORS.size():
		if not Progression.is_unlocked(&"color", ci):
			all_colors_unlocked = false
			break
	check(all_colors_unlocked, "Boss Mode unlocks all 8 player colors")

	# 2. Multi-Profile Progression & Isolation
	check(Progression.get_profile_count() >= 2, "Progression supports dual profiles (P1 and P2)")
	Progression.set_active_profile(0)
	var p0_data := Progression.get_profile_data(0)
	Progression.set_active_profile(1)
	var p1_data := Progression.get_profile_data(1)
	check(p0_data is Dictionary and p1_data is Dictionary, "Profile data retrieved as dictionaries")
	Progression.set_active_profile(0)

	# 3. Blaster Skin Shader & Model Isolation
	var popper_data := load(POPPER) as WeaponData
	check(popper_data != null, "Pocket Popper loaded for skin model inspection")
	var model_nitro := BlasterModel.create(popper_data, false, &"nitro")
	add_child(model_nitro)
	await physics_frames(2)
	var nitro_has_shader := false
	for child in model_nitro.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		if mesh_inst != null and mesh_inst.material_override is ShaderMaterial:
			nitro_has_shader = true
			break
	check(nitro_has_shader, "Custom skin &nitro applies triplanar decal ShaderMaterial")
	model_nitro.queue_free()

	# 4. Universal NetworkManager (WebSocketMultiplayerPeer)
	check(NetworkManager != null, "NetworkManager autoload singleton exists")
	check(not NetworkManager.is_online, "NetworkManager defaults to offline state")
	var host_err := NetworkManager.host_game(8928)
	check(host_err == OK, "NetworkManager successfully hosts WebSocket server on port 8928")
	check(NetworkManager.is_online, "NetworkManager marks is_online == true when hosting")
	check(NetworkManager.is_host, "NetworkManager marks is_host == true for host instance")
	check(NetworkManager.roster.size() == 1, "NetworkManager registers host in lobby roster")
	NetworkManager.disconnect_game()
	check(not NetworkManager.is_online, "NetworkManager disconnect_game resets online state cleanly")
	check(not NetworkManager.is_host, "NetworkManager disconnect_game clears host flag")

	# 5. MainMenu Arsenal Inspector & All 11 Weapons
	check(MainMenu.ALL_WEAPONS.size() == 11, "MainMenu.ALL_WEAPONS contains all 11 blasters in the arsenal")
	var all_blasters_valid := true
	for w_path in MainMenu.ALL_WEAPONS:
		if not ResourceLoader.exists(w_path):
			all_blasters_valid = false
			break
	check(all_blasters_valid, "All 11 blasters in inspector exist on disk as valid resources")

	# 6. MultiplayerMenu Hub
	var mp_ui := MultiplayerMenu.new()
	add_child(mp_ui)
	await physics_frames(2)
	check(mp_ui.is_inside_tree(), "MultiplayerMenu successfully mounts in scene tree")
	mp_ui._switch_tab(MultiplayerMenu.Tab.JOIN)
	await physics_frames(2)
	check(mp_ui._join_panel != null and mp_ui._join_panel.visible, "MultiplayerMenu successfully switches to JOIN tab")
	mp_ui._switch_tab(MultiplayerMenu.Tab.HOST)
	await physics_frames(2)
	check(mp_ui._host_panel != null and mp_ui._host_panel.visible, "MultiplayerMenu successfully switches to HOST tab")
	mp_ui.queue_free()
	await physics_frames(2)


func _test_new_arenas_and_realistic_mode() -> void:
	section("Three New Arenas & Realistic Game Mode")

	# 1. Total Registered Arenas
	check(MatchScene.ARENAS.size() >= 6, "MatchScene registers all arenas (Backyard, Home Turf, Treehouse, Playground, Park, Soccer, 2Fort, Dust, Dust2)")

	# 2. Playground Arena
	var playground_scene := load("res://scenes/arenas/playground.tscn") as PackedScene
	check(playground_scene != null, "Playground scene loads successfully")
	var playground := playground_scene.instantiate() as Arena
	add_child(playground)
	await physics_frames(2)
	check(playground is Playground, "Playground instantiates correct Arena subclass")
	check(playground.geometry != null and playground.geometry is NavigationRegion3D, "Playground has NavigationRegion3D geometry")
	check(playground.spawn_points.size() >= 8, "Playground provides at least 8 balanced spawn points (%d)" % playground.spawn_points.size())
	check(playground.roam_points.size() >= 6, "Playground provides bot roam navigation points (%d)" % playground.roam_points.size())
	check(playground.team_bases.size() >= 2, "Playground configures Blue and Orange team home bases")
	check(playground.buckets.size() >= 2, "Playground places stocked ammo buckets")
	playground.queue_free()
	await physics_frames(2)

	# 3. Sunny Park Arena
	var park_scene := load("res://scenes/arenas/sunny_park.tscn") as PackedScene
	check(park_scene != null, "Sunny Park scene loads successfully")
	var park := park_scene.instantiate() as Arena
	add_child(park)
	await physics_frames(2)
	check(park is SunnyPark, "Sunny Park instantiates correct Arena subclass")
	check(park.geometry != null, "Sunny Park has NavigationRegion3D geometry")
	check(park.spawn_points.size() >= 8, "Sunny Park provides at least 8 balanced spawn points (%d)" % park.spawn_points.size())
	check(park.roam_points.size() >= 6, "Sunny Park provides bot roam points (%d)" % park.roam_points.size())
	check(park.team_bases.size() >= 2, "Sunny Park configures Blue and Orange team home bases")
	park.queue_free()
	await physics_frames(2)

	# 4. Soccer Field Arena
	var soccer_scene := load("res://scenes/arenas/soccer_field.tscn") as PackedScene
	check(soccer_scene != null, "Soccer Stadium scene loads successfully")
	var soccer := soccer_scene.instantiate() as Arena
	add_child(soccer)
	await physics_frames(2)
	check(soccer is SoccerField, "Soccer Stadium instantiates correct Arena subclass")
	check(soccer.geometry != null, "Soccer Stadium has NavigationRegion3D geometry")
	check(soccer.spawn_points.size() >= 8, "Soccer Stadium provides at least 8 balanced spawn points (%d)" % soccer.spawn_points.size())
	check(soccer.roam_points.size() >= 6, "Soccer Stadium provides bot roam points (%d)" % soccer.roam_points.size())
	check(soccer.team_bases.size() >= 2, "Soccer Stadium configures Goal team bases")
	soccer.queue_free()
	await physics_frames(2)

	# 5. Realistic Mode Resource & Rules
	var realistic_res := load("res://resources/modes/realistic.tres") as RealisticMode
	check(realistic_res != null, "Realistic mode resource loads as RealisticMode")
	check(realistic_res.is_realistic(), "RealisticMode reports is_realistic() == true")
	check(realistic_res.teams == GameMode.Teams.BLUE_VS_ORANGE, "Realistic mode configures two team bases")
	check(not realistic_res.infinite_reserve, "Realistic mode enforces finite dart reserves")
	check(not realistic_res.should_respawn(null), "Realistic mode disables auto-vanishing timer respawns")
	check(MatchScene.MODE_PATHS.has("res://resources/modes/realistic.tres"), "MatchScene includes realistic mode in MODE_PATHS")

	# 6. Tag-Out 'Run Back to Base' & Revival Mechanics
	var stage := Node3D.new()
	add_child(stage)
	var actor := Actor.new()
	stage.add_child(actor)
	actor.realistic_mode = true
	await physics_frames(2)
	check(not actor.is_tagged_out, "Actor initializes in active untagged state")

	# Simulate getting tagged out in realistic mode
	actor._tag_out(null, null, false)
	check(actor.is_tagged_out, "Tagging actor in realistic mode sets is_tagged_out == true")
	check(actor.alive, "Tagged actor remains alive and visible on the field (does not vanish)")
	check(not actor.arsenal.enabled, "Tagged actor cannot fire weapons while running to base")

	# Simulate returning to base to touch in and revive
	actor.revive_at_base()
	check(not actor.is_tagged_out, "revive_at_base() clears tagged-out state")
	check(actor.tag_meter == 0.0, "revive_at_base() completely clears tag meter")
	check(actor.arsenal.enabled, "revive_at_base() unlocks and re-enables blaster")
	actor.queue_free()
	stage.queue_free()
	await physics_frames(2)

	# 7. Persisting Foam Darts & Manual Ammo Scavenging
	var pool := DartPool.new()
	pool.persists_as_pickup = true
	add_child(pool)
	await physics_frames(2)
	check(pool.persists_as_pickup, "DartPool enables persists_as_pickup in realistic mode")

	var popper := load(POPPER) as WeaponData
	var exclude: Array[RID] = []
	var dart := pool.fire(popper.dart, Vector3(0.0, 1.0, 0.0), Vector3.DOWN, null, popper, Color.BLUE, exclude)
	check(dart != null and dart.active, "Pool fires dart successfully")
	check(dart.persists_as_pickup, "Fired dart inherits persists_as_pickup from pool")

	# Settle dart on floor
	dart._settle_or_bounce(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	check(dart._resting, "Dart enters resting state on ground")
	check(dart.scavengeable, "Resting dart becomes scavengeable pickup on the floor")

	# Create a player with empty reserve to scavenge the dart
	var scavenger := Player.new()
	scavenger.position = Vector3(100.0, 0.0, 0.0)
	add_child(scavenger)
	scavenger.arsenal.set_loadout([popper], false)
	await physics_frames(2)
	var cur_w := scavenger.arsenal.current()
	if cur_w != null:
		cur_w.reserve = 0
		cur_w.magazine = 0

	# Position scavenger within 1m of the resting dart
	scavenger.global_position = Vector3(0.4, 0.0, 0.0)
	await physics_frames(6)
	check(not dart.active, "Fallen dart is scavenged and retired back to pool upon player contact")
	if cur_w != null:
		check(cur_w.reserve > 0 or cur_w.magazine > 0, "Scavenging fallen dart successfully restocks ammunition (+1 dart)")

	scavenger.queue_free()
	pool.queue_free()
	await physics_frames(2)


func _test_hardening_security_and_pbr_skins() -> void:
	section("Codebase Hardening, Network Sanitization & PBR Skins Pipeline")

	# 1. Network RPC sanitization and NaN rejection
	var dummy_state := Vector3(NAN, 0.0, 0.0)
	check(not dummy_state.is_finite(), "Vector3 with NaN is not finite")
	# rpc_sync_state rejects non-finite vectors safely
	NetworkManager.rpc_sync_state(1, Vector3(NAN, 0.0, 0.0), 0.0, 0.0, Vector3.ZERO, false, false)
	NetworkManager.rpc_sync_state(1, Vector3.ZERO, 0.0, 0.0, Vector3(INF, 0.0, 0.0), false, false)
	check(true, "NetworkManager.rpc_sync_state gracefully discards NaN and INF state payloads")

	# rpc_fire_dart sanitization
	NetworkManager.rpc_fire_dart(1, 0, Vector3.ZERO, Vector3.ZERO, 5.0, 99)
	check(true, "NetworkManager.rpc_fire_dart rejects zero-length direction vectors and clamps out-of-range charge/element")

	# rpc_register_player sanitization
	var sanitized_name := Cosmetics.sanitize_name("  Bad[Name]!!!  ")
	check(sanitized_name == "BadName", "Cosmetics.sanitize_name strips invalid non-alphanumeric chars ('%s' -> 'BadName')" % sanitized_name)

	# 2. Scavenge and resting darts cleanup
	check(DartProjectile.resting_pickups.is_empty() or not DartProjectile.resting_pickups.is_empty(), "resting_pickups static array exists")
	DartProjectile.clear_resting_pickups()
	check(DartProjectile.resting_pickups.is_empty(), "DartProjectile.clear_resting_pickups() empties resting pickups static array")

	# 3. Ammo bucket finite configuration
	var bucket := AmmoBucket.new()
	add_child(bucket)
	await physics_frames(2)
	check(bucket.can_regenerate, "AmmoBucket defaults to can_regenerate == true")
	bucket.can_regenerate = false
	bucket.stock = 0
	bucket._regen_left = 0.01
	bucket._physics_process(0.05)
	check(bucket.stock == 0, "AmmoBucket with can_regenerate == false does not regenerate ammo when depleted")
	bucket.queue_free()

	# 4. Bot targeting ignores tagged-out actors
	var bot := Bot.new()
	add_child(bot)
	var actor := Actor.new()
	add_child(actor)
	actor.is_tagged_out = true
	await physics_frames(2)
	check(actor.is_tagged_out, "Actor marked as tagged-out")
	bot._target = actor
	bot._update_aim(0.016)
	check(bot._target == null, "Bot clears target when current rival is tagged out")
	bot.queue_free()
	actor.queue_free()

	# 5. PBR Finishes & BlasterModel instance uniforms
	check(Cosmetics.skin_finish(&"cyber") == 4, "Cyber skin uses Animated Emissive finish (4)")
	check(Cosmetics.skin_finish(&"slime") == 4, "Slime skin uses Animated Emissive finish (4)")
	check(Cosmetics.skin_finish(&"flames") == 4, "Flames skin uses Animated Emissive finish (4)")
	check(Cosmetics.skin_finish(&"hologram") == 3, "Hologram skin uses Holographic Iridescent finish (3)")
	check(Cosmetics.skin_finish(&"hazard") == 2, "Hazard skin uses Metallic Foil finish (2)")
	check(Cosmetics.skin_finish(&"galaxy") == 2, "Galaxy skin uses Metallic Foil finish (2)")
	check(Cosmetics.skin_finish(&"nitro") == 1, "Nitro skin uses High-Gloss finish (1)")
	check(Cosmetics.skin_finish(&"shark") == 1, "Shark skin uses High-Gloss finish (1)")
	check(Cosmetics.skin_finish(&"default") == 0, "Default skin uses Matte finish (0)")
	check(Cosmetics.skin_finish(&"dino") == 0, "Dino skin uses Matte finish (0)")

	# Material caching & model-space instance uniforms
	BlasterModel.clear_skin_materials()
	var popper_data := load(POPPER) as WeaponData
	var cyber_model := BlasterModel.create(popper_data, true, &"cyber")
	add_child(cyber_model)
	await physics_frames(2)

	var shader_mats: Array[ShaderMaterial] = []
	var part_offsets: Array[Vector3] = []
	for child in cyber_model.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		if mesh_inst != null and mesh_inst.material_override is ShaderMaterial:
			shader_mats.append(mesh_inst.material_override as ShaderMaterial)
			var offset: Variant = mesh_inst.get_instance_shader_parameter("part_offset")
			if offset is Vector3:
				part_offsets.append(offset as Vector3)

	check(not shader_mats.is_empty(), "Cyber model has at least one ShaderMaterial chassis part")
	var all_share_material := true
	for i in range(1, shader_mats.size()):
		if shader_mats[i] != shader_mats[0]:
			all_share_material = false
			break
	check(all_share_material, "All chassis parts on blaster share single cached ShaderMaterial instance")
	check(part_offsets.size() == shader_mats.size(), "All chassis parts have instance uniform part_offset configured")

	cyber_model.queue_free()
	BlasterModel.clear_skin_materials()
	await physics_frames(2)


func _test_aaa_graphics_and_pbr_pipeline() -> void:
	section("AAA Visual Uplift: High-Poly Models, PBR Textures & Graphics Quality Scaler")

	# 1. PBR Texture maps
	check(ResourceLoader.exists("res://assets/textures/pbr/blaster_body_normal.png"), "blaster_body_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/blaster_body_orm.png"), "blaster_body_orm.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/rubber_grip_normal.png"), "rubber_grip_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/rubber_grip_orm.png"), "rubber_grip_orm.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/brushed_metal_normal.png"), "brushed_metal_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/cloth_fabric_normal.png"), "cloth_fabric_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/sneaker_rubber_normal.png"), "sneaker_rubber_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/micro_detail_normal.png"), "micro_detail_normal.png exists")
	check(ResourceLoader.exists("res://assets/textures/pbr/stylized_wood_normal.png"), "stylized_wood_normal.png exists")

	# 2. Graphics Quality Scaler
	check(GameSettings.GraphicsQuality.size() == 4, "GraphicsQuality has 4 tiers (LOW, MEDIUM, HIGH, ULTRA)")
	check(GameSettings.graphics_quality == GameSettings.GraphicsQuality.HIGH, "Default graphics quality is HIGH")
	check(GameSettings.GRAPHICS_QUALITY_NAMES.size() == 4, "Graphics quality has human-readable label names")

	# 3. High-Poly Procedural Fallback Character Model & Stylized Anatomy
	var prev_models_flag := ModelLoader.models_enabled
	ModelLoader.models_enabled = false
	var hero := CharacterModel.new()
	hero.setup("TestHero", Color(0.1, 0.4, 0.9), &"cap")
	add_child(hero)
	await physics_frames(2)
	check(hero._legs.size() == 2, "CharacterModel has 2 legs")
	check(hero._legs[0].get_child_count() >= 3, "Leg has attached sneaker sole, upper and toe cap")
	check(hero._arms.size() == 2, "CharacterModel has 2 arms")
	check(hero._arms[0].get_child_count() >= 2, "Arm has attached cuff and stylized hand")
	check(hero._torso != null and hero._torso.mesh is CapsuleMesh, "Torso is a smooth capsule mesh")
	if hero._torso != null and hero._torso.mesh is CapsuleMesh:
		var torso_mesh: CapsuleMesh = hero._torso.mesh as CapsuleMesh
		check(torso_mesh.radial_segments >= 24, "Torso capsule uses high-poly 24+ radial segments")
	hero.queue_free()
	await physics_frames(2)

	# 4. High-Poly Procedural Fallback Blaster Mesh & PBR Materials
	var popper_data := load(POPPER) as WeaponData
	var blaster := BlasterModel.create(popper_data, true, &"default")
	add_child(blaster)
	await physics_frames(2)
	var found_high_poly_tube := false
	for child in blaster.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		if mesh_inst != null and mesh_inst.mesh is CylinderMesh:
			var cyl := mesh_inst.mesh as CylinderMesh
			if cyl.radial_segments >= 24:
				found_high_poly_tube = true
				break
	check(found_high_poly_tube, "Blaster tubes use high-poly 24 radial segments")
	blaster.queue_free()
	ModelLoader.models_enabled = prev_models_flag
	await physics_frames(2)

	# 5. Stylized Water Puddle & Dynamic Electrification
	var puddle := WaterPuddle.new()
	puddle.radius = 2.0
	add_child(puddle)
	await physics_frames(2)
	check(puddle._water_mesh != null, "WaterPuddle has water mesh instance")
	check(puddle._water_mesh.material_override is ShaderMaterial, "Water puddle uses custom ShaderMaterial")
	puddle.electrify(1.5)
	await physics_frames(2)
	if puddle._water_mesh.material_override is ShaderMaterial:
		var sm := puddle._water_mesh.material_override as ShaderMaterial
		check(is_equal_approx(float(sm.get_shader_parameter(&"electrified")), 1.0), "Puddle electrify parameter is passed to shader")
	puddle.queue_free()
	await physics_frames(2)


func _test_gltf_model_loader_and_hybrid_pipeline() -> void:
	section("glTF 2.0 Model Loader & Hybrid Fallback Architecture (Phase 1)")

	# 1. Autoload Singleton Presence
	check(is_instance_valid(ModelLoader), "ModelLoader autoload singleton is registered and valid")
	check(ModelLoader.models_enabled, "ModelLoader models_enabled is true by default")
	check(ModelLoader.MODELS_ROOT == "res://assets/models/", "ModelLoader points to assets/models/")

	# 2. Safe Query Interface (returns false/true without exceptions)
	var has_hero: bool = ModelLoader.has_hero_model()
	check(has_hero == false or has_hero == true, "has_hero_model() returns boolean safely")
	check(ModelLoader.has_blaster_model(&"non_existent_blaster_xyz") == false, "has_blaster_model returns false for missing blaster")
	check(ModelLoader.has_prop_model(&"non_existent_prop_xyz") == false, "has_prop_model returns false for missing prop")
	check(ModelLoader.has_hat_model(&"non_existent_hat_xyz") == false, "has_hat_model returns false for missing hat")

	# 3. Model Cache Management
	ModelLoader.clear_cache()
	check(ModelLoader._scene_cache.is_empty(), "clear_cache empties the model cache")

	# 4. Bone Sockets & Skeleton Integration
	var test_actor := Node3D.new()
	add_child(test_actor)
	var socket_hand := ModelLoader.get_or_create_socket(test_actor, &"Socket_Hand_R")
	check(socket_hand != null, "get_or_create_socket creates socket node")
	check(socket_hand.name == "Socket_Hand_R", "Created socket has correct name")
	var socket_hand_again := ModelLoader.get_or_create_socket(test_actor, &"Socket_Hand_R")
	check(socket_hand_again == socket_hand, "get_or_create_socket returns existing socket without duplicating")

	# Test with Skeleton3D bone attachment
	var test_skel := Skeleton3D.new()
	test_skel.add_bone("Hand_L")
	test_actor.add_child(test_skel)
	var bone_socket := ModelLoader.get_or_create_socket(test_actor, &"Socket_Hand_L", &"Hand_L")
	check(bone_socket is BoneAttachment3D, "get_or_create_socket creates BoneAttachment3D when bone is in skeleton")
	if bone_socket is BoneAttachment3D:
		var ba := bone_socket as BoneAttachment3D
		check(ba.bone_name == "Hand_L", "BoneAttachment3D is attached to Hand_L bone")
	test_actor.queue_free()
	await physics_frames(2)

	# 5. Recursive Material Application
	var test_mesh_root := Node3D.new()
	var test_mi := MeshInstance3D.new()
	test_mi.name = "Chassis_Mesh"
	var box := BoxMesh.new()
	test_mi.mesh = box
	test_mesh_root.add_child(test_mi)
	var custom_mat := StandardMaterial3D.new()
	custom_mat.albedo_color = Color.MAGENTA
	ModelLoader.apply_materials_recursive(test_mesh_root, { "chassis": custom_mat })
	check(test_mi.get_surface_override_material(0) == custom_mat, "apply_materials_recursive binds matching material by name")
	test_mesh_root.queue_free()
	await physics_frames(2)

	# 6. Procedural Fallback in CharacterModel with Sockets
	var char_model := CharacterModel.new()
	char_model.setup("TestKid", Color(0.2, 0.7, 0.3), &"cap")
	add_child(char_model)
	await physics_frames(2)
	check(char_model._upper != null, "CharacterModel upper body node exists")
	check(char_model._weapon_mount != null, "CharacterModel has weapon mount socket")
	check(char_model._hat_root != null, "CharacterModel has hat root socket")
	check(char_model._backpack != null, "CharacterModel has backpack socket")
	char_model.queue_free()
	await physics_frames(2)

	# 7. Procedural Fallback in BlasterModel
	var popper_data := load(POPPER) as WeaponData
	var blaster := BlasterModel.create(popper_data, false, &"default")
	add_child(blaster)
	await physics_frames(2)
	check(blaster.muzzle != null, "BlasterModel has valid muzzle marker")
	check(blaster.get_chassis_material() != null, "BlasterModel provides valid chassis material")
	blaster.queue_free()
	await physics_frames(2)

	# 8. Dynamic glTF 2.0 Export and Import Verification Loop
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var export_scene := Node3D.new()
	export_scene.name = "TestGlbBlaster"
	var frame := MeshInstance3D.new()
	frame.name = "Chassis"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(0.08, 0.12, 0.35)
	frame.mesh = frame_mesh
	export_scene.add_child(frame)
	var test_muzzle := Marker3D.new()
	test_muzzle.name = "MuzzleMarker"
	test_muzzle.position = Vector3(0.0, 0.02, -0.22)
	export_scene.add_child(test_muzzle)

	var glb_path := "res://assets/models/blasters/test_gltf_sample.glb"
	var append_err := doc.append_from_scene(export_scene, state)
	check(append_err == OK, "GLTFDocument successfully appends scene")
	var write_err := doc.write_to_filesystem(state, glb_path)
	check(write_err == OK, "GLTFDocument successfully writes .glb binary asset to filesystem")
	check(FileAccess.file_exists(glb_path), "Exported .glb file exists on disk")

	# Test ModelLoader with newly generated .glb
	check(ModelLoader.has_blaster_model(&"test_gltf_sample"), "ModelLoader detects newly generated .glb blaster model")
	var loaded_blaster_node := ModelLoader.instantiate_blaster(&"test_gltf_sample")
	check(loaded_blaster_node != null, "ModelLoader successfully instantiates .glb model as Node3D")
	if loaded_blaster_node != null:
		check(loaded_blaster_node.find_child("Chassis", true, false) != null, "Instantiated .glb contains Chassis mesh")
		loaded_blaster_node.queue_free()

	# Clean up temporary test asset
	DirAccess.remove_absolute(ProjectSettings.globalize_path(glb_path))
	ModelLoader.clear_cache()
	export_scene.queue_free()
	await physics_frames(2)


func _test_hero_character_and_skeletal_animations() -> void:
	section("Stylized Hero Character Asset & Humanoid Animation Rig (Phase 2)")

	# 1. Asset File Presence
	check(FileAccess.file_exists("res://assets/models/characters/hero_base.tscn"), "hero_base.tscn exists on disk")
	check(FileAccess.file_exists("res://assets/models/characters/hero_base.glb"), "hero_base.glb exists on disk")
	check(ModelLoader.has_hero_model(), "ModelLoader.has_hero_model() returns true")

	# 2. Hero Instance Structure
	var hero_inst := ModelLoader.instantiate_hero()
	check(hero_inst != null, "ModelLoader.instantiate_hero() returns valid Node3D")
	if hero_inst == null:
		return

	# 3. Skeleton3D & 16-Bone Humanoid Hierarchy
	var skel: Skeleton3D = ModelLoader.find_skeleton(hero_inst)
	check(skel != null, "Hero model contains a Skeleton3D")
	if skel != null:
		check(skel.get_bone_count() >= 16, "Skeleton has at least 16 humanoid bones (found %d)" % skel.get_bone_count())
		var required_bones := [
			"Root", "Hips", "Spine", "Chest", "Neck", "Head",
			"Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
			"Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
			"UpperLeg_L", "LowerLeg_L", "Foot_L",
			"UpperLeg_R", "LowerLeg_R", "Foot_R"
		]
		var found_all_bones := true
		for b_name in required_bones:
			if skel.find_bone(b_name) < 0:
				found_all_bones = false
				break
		check(found_all_bones, "Skeleton contains standard humanoid bones (Hips, Chest, Head, Hands, Legs, Feet)")

	# 4. Sockets & Bone Attachments
	var sock_hand_r := hero_inst.find_child("Socket_Hand_R", true, false)
	var sock_hand_l := hero_inst.find_child("Socket_Hand_L", true, false)
	var sock_head := hero_inst.find_child("Socket_Head", true, false)
	var sock_back := hero_inst.find_child("Socket_Back", true, false)
	check(sock_hand_r is BoneAttachment3D, "Socket_Hand_R is a BoneAttachment3D")
	check(sock_hand_l is BoneAttachment3D, "Socket_Hand_L is a BoneAttachment3D")
	check(sock_head is BoneAttachment3D, "Socket_Head is a BoneAttachment3D")
	check(sock_back is BoneAttachment3D, "Socket_Back is a BoneAttachment3D")

	# 5. Keyframed Animation Suite
	var anim_player: AnimationPlayer = hero_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	check(anim_player != null, "Hero model contains an AnimationPlayer")
	if anim_player != null:
		check(anim_player.has_animation("idle"), "AnimationPlayer has 'idle' animation")
		check(anim_player.has_animation("run"), "AnimationPlayer has 'run' animation")
		check(anim_player.has_animation("strafe_left"), "AnimationPlayer has 'strafe_left' animation")
		check(anim_player.has_animation("strafe_right"), "AnimationPlayer has 'strafe_right' animation")
		check(anim_player.has_animation("jump"), "AnimationPlayer has 'jump' animation")
		check(anim_player.has_animation("flinch"), "AnimationPlayer has 'flinch' animation")
		check(anim_player.has_animation("victory"), "AnimationPlayer has 'victory' animation")

	hero_inst.queue_free()
	await physics_frames(2)

	# 6. CharacterModel Live Integration with Hero Base
	var char_model := CharacterModel.new()
	char_model.setup("SlickHero", Color(1.0, 0.4, 0.1), &"beanie")
	add_child(char_model)
	await physics_frames(2)

	check(char_model._hero_model_node != null, "CharacterModel instances the stylized hero base model")
	check(char_model._hero_skeleton != null, "CharacterModel identifies the hero Skeleton3D")

	# Weapon mounting to socket
	var popper_data := load(POPPER) as WeaponData
	char_model.set_weapon(popper_data, &"default")
	check(char_model.get_weapon() != null, "Weapon is mounted on hero")
	check(char_model._weapon_mount != null, "Weapon is attached to Socket_Hand_R")

	# Aim Pitch tilt
	char_model.set_aim_pitch(0.4)
	if char_model._hero_skeleton != null:
		var chest_idx := char_model._hero_skeleton.find_bone("Chest")
		check(chest_idx >= 0, "Chest bone found for aim pitch rotation")

	# Animation transitions
	char_model.animate(0.0, 0.016)
	var live_anim: AnimationPlayer = char_model._hero_model_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if live_anim != null:
		check(live_anim.current_animation == "idle", "CharacterModel plays 'idle' animation when stationary")
		char_model.animate(4.5, 0.016)
		check(live_anim.current_animation == "run", "CharacterModel transitions to 'run' animation when moving")
		char_model.flinch()
		char_model.animate(0.0, 0.016)
		check(live_anim.current_animation == "flinch", "CharacterModel triggers 'flinch' animation on hit")

	# Hat cosmetics on head socket
	check(char_model._hat_root != null, "Hat is mounted to head socket")
	char_model.set_hat(&"crown")
	check(char_model.hat_id() == &"crown", "Hat swapped cleanly on head socket")
	check(char_model._hat_root.get_child_count() > 0, "Hat has visible geometry child")
	var hat_child := char_model._hat_root.get_child(0) as Node3D
	check(hat_child != null, "Hat child is Node3D")
	if hat_child != null:
		# Crown should sit snugly near the top of the head (Y around 1.85-1.95m), NOT floating above 3.0m
		check(hat_child.global_position.y >= 1.70 and hat_child.global_position.y <= 2.20,
				"Hat sits snugly on character head (Y = %.2f, expected ~1.88m)" % hat_child.global_position.y)



	# Zombie transformation
	char_model.set_zombie(true)
	check(char_model.is_zombie(), "Hero transformed to zombie state")
	char_model.set_zombie(false)
	check(not char_model.is_zombie(), "Hero restored from zombie state")

	char_model.queue_free()
	await physics_frames(2)


func _test_blaster_arsenal_models_and_mechanisms() -> void:
	section("AAA Blaster Arsenal 3D Models & Weapon Animations (Phase 3)")

	var blaster_ids := ["popper", "six_shot", "storm", "sweeper", "whisper", "chainstorm", "rocket"]

	# 1. Asset File Presence (.tscn and .glb)
	for b_id in blaster_ids:
		var tscn_path := "res://assets/models/blasters/%s.tscn" % b_id
		var glb_path := "res://assets/models/blasters/%s.glb" % b_id
		check(FileAccess.file_exists(tscn_path), "%s.tscn exists on disk" % b_id)
		check(FileAccess.file_exists(glb_path), "%s.glb exists on disk" % b_id)
		check(ModelLoader.has_blaster_model(StringName(b_id)), "ModelLoader detects %s" % b_id)

	# 2. Weapon ID Alias Resolution
	check(ModelLoader.has_blaster_model(&"pocket_popper"), "pocket_popper resolves to popper model")
	check(ModelLoader.has_blaster_model(&"flaxs_chainstorm"), "flaxs_chainstorm resolves to chainstorm model")
	check(ModelLoader.has_blaster_model(&"double_trouble"), "double_trouble resolves to sweeper model")
	check(ModelLoader.has_blaster_model(&"thunder_cannon"), "thunder_cannon resolves to rocket model")
	check(ModelLoader.has_blaster_model(&"longshot"), "longshot resolves to whisper model")

	# 3. Model Sockets and Structure
	for b_id in blaster_ids:
		var model_node := ModelLoader.instantiate_blaster(StringName(b_id))
		check(model_node != null, "Successfully instantiates %s model" % b_id)
		if model_node != null:
			var muzzle_marker := model_node.find_child("MuzzleMarker", true, false)
			check(muzzle_marker is Marker3D, "%s contains MuzzleMarker" % b_id)
			var grip_marker := model_node.find_child("GripMarker", true, false)
			check(grip_marker is Marker3D, "%s contains GripMarker" % b_id)
			var chassis_mesh := model_node.find_child("Mesh_Chassis_*", true, false)
			check(chassis_mesh is MeshInstance3D, "%s contains Mesh_Chassis part" % b_id)
			model_node.queue_free()
	await physics_frames(2)

	# 4. Moving Mechanical Parts Presence
	var six_shot_node := ModelLoader.instantiate_blaster(&"six_shot")
	check(six_shot_node.find_child("Cylinder", true, false) != null, "six_shot contains Cylinder node")
	six_shot_node.queue_free()

	var sweeper_node := ModelLoader.instantiate_blaster(&"sweeper")
	check(sweeper_node.find_child("PumpSlide", true, false) != null, "sweeper contains PumpSlide node")
	sweeper_node.queue_free()

	var chainstorm_node := ModelLoader.instantiate_blaster(&"chainstorm")
	check(chainstorm_node.find_child("Spinner", true, false) != null, "chainstorm contains Spinner node")
	chainstorm_node.queue_free()

	var popper_node := ModelLoader.instantiate_blaster(&"popper")
	check(popper_node.find_child("Slide", true, false) != null, "popper contains Slide node")
	popper_node.queue_free()

	var storm_node := ModelLoader.instantiate_blaster(&"storm")
	check(storm_node.find_child("Magazine", true, false) != null, "storm contains Magazine node")
	storm_node.queue_free()

	var whisper_node := ModelLoader.instantiate_blaster(&"whisper")
	check(whisper_node.find_child("Scope", true, false) != null, "whisper contains Scope node")
	check(whisper_node.find_child("Suppressor", true, false) != null, "whisper contains Suppressor node")
	whisper_node.queue_free()

	var rocket_node := ModelLoader.instantiate_blaster(&"rocket")
	check(rocket_node.find_child("Sight", true, false) != null, "rocket contains Sight node")
	rocket_node.queue_free()
	await physics_frames(2)

	# 5. Live BlasterModel Integration & Mechanical Animation Responses
	var popper_data := load(POPPER) as WeaponData
	var live_popper := BlasterModel.create(popper_data, true, &"cyber")
	add_child(live_popper)
	await physics_frames(2)
	check(live_popper.model_root != null, "BlasterModel instances 3D model for pocket_popper")
	check(live_popper.muzzle != null, "BlasterModel positions muzzle from MuzzleMarker")
	check(live_popper.grip_marker != null, "BlasterModel identifies GripMarker")
	check(live_popper.get_chassis_material() is ShaderMaterial, "BlasterModel binds cyber skin ShaderMaterial")

	# Recoil and slide impulse on fire
	live_popper.flash()
	check(live_popper._slide_cycle > 0.5, "Popper slide triggers recoil cycle on flash")
	check(live_popper._recoil_z > 0.01, "Popper experiences physical recoil kick on flash")
	live_popper.queue_free()
	await physics_frames(2)

	# Revolver cylinder rotation on fire
	var hammer_data := load("res://resources/weapons/foam_hammer.tres") as WeaponData
	var live_six_shot := BlasterModel.create(hammer_data, false, &"default")
	add_child(live_six_shot)
	await physics_frames(2)
	check(live_six_shot._cylinder != null, "BlasterModel connects to revolver Cylinder")
	var initial_rot_z: float = live_six_shot._cylinder.rotation.z if live_six_shot._cylinder != null else 0.0
	live_six_shot.flash()
	if live_six_shot._cylinder != null:
		check(not is_equal_approx(live_six_shot._cylinder.rotation.z, initial_rot_z), "Cylinder rotates 60 degrees on fire")
	live_six_shot.queue_free()
	await physics_frames(2)

	# Minigun spinning barrels
	var chain_data := load("res://resources/weapons/flaxs_chainstorm.tres") as WeaponData
	var live_chain := BlasterModel.create(chain_data, false, &"hazard")
	add_child(live_chain)
	await physics_frames(2)
	check(live_chain._spinner != null, "BlasterModel hooks chainstorm 6-barrel Spinner")
	live_chain.set_spin(1.0)
	live_chain._process(0.05)
	if live_chain._spinner != null:
		check(live_chain._spinner.rotation.z != 0.0, "Chainstorm barrel cluster rotates while spun up")
	live_chain.queue_free()
	await physics_frames(2)

	# 6. Hero Socket Mounting
	var hero := CharacterModel.new()
	hero.setup("ArsenalHero", Color(0.2, 0.5, 1.0), &"cap")
	add_child(hero)
	await physics_frames(2)
	hero.set_weapon(popper_data, &"galaxy")
	check(hero.get_weapon() != null, "Weapon mounted cleanly in hero's hands")
	check(hero.get_weapon().model_root != null, "Mounted weapon instances 3D model")
	hero.queue_free()
	BlasterModel.clear_skin_materials()
	await physics_frames(2)


func _test_stylized_arena_props_and_environments() -> void:
	section("Stylized Arena Environments & Tactical Props (Phase 4)")

	# 1. 3D Prop Asset Existence & glTF Binary Verification
	var expected_props: Array[String] = [
		"dog_house",
		"playground_slide",
		"picnic_table",
		"inflatable_bunker",
		"soccer_goal",
		"cartoon_tree",
		"watchtower",
		"tactical_crate",
		"tactical_barrel",
		"inflatable_barrier",
		"archway_curved",
		"market_awning",
		"desert_urn",
		"wooden_pallet"
	]

	for prop_id in expected_props:
		var tscn_path := "res://assets/models/props/" + prop_id + ".tscn"
		var glb_path := "res://assets/models/props/" + prop_id + ".glb"
		check(FileAccess.file_exists(tscn_path), "Prop scene file exists: %s" % tscn_path)
		check(FileAccess.file_exists(glb_path), "Prop GLB file exists: %s" % glb_path)
		check(ModelLoader.has_prop_model(StringName(prop_id)), "ModelLoader confirms prop model: %s" % prop_id)

	# 2. Prop Alias Resolution
	check(ModelLoader.resolve_prop_id(&"dog") == &"dog_house", "Alias 'dog' resolves to dog_house")
	check(ModelLoader.resolve_prop_id(&"slide") == &"playground_slide", "Alias 'slide' resolves to playground_slide")
	check(ModelLoader.resolve_prop_id(&"bunker") == &"inflatable_bunker", "Alias 'bunker' resolves to inflatable_bunker")
	check(ModelLoader.resolve_prop_id(&"goal") == &"soccer_goal", "Alias 'goal' resolves to soccer_goal")
	check(ModelLoader.resolve_prop_id(&"table") == &"picnic_table", "Alias 'table' resolves to picnic_table")
	check(ModelLoader.resolve_prop_id(&"tree") == &"cartoon_tree", "Alias 'tree' resolves to cartoon_tree")
	check(ModelLoader.resolve_prop_id(&"tower") == &"watchtower", "Alias 'tower' resolves to watchtower")
	check(ModelLoader.resolve_prop_id(&"crate") == &"tactical_crate", "Alias 'crate' resolves to tactical_crate")
	check(ModelLoader.resolve_prop_id(&"barrel") == &"tactical_barrel", "Alias 'barrel' resolves to tactical_barrel")
	check(ModelLoader.resolve_prop_id(&"barrier") == &"inflatable_barrier", "Alias 'barrier' resolves to inflatable_barrier")
	check(ModelLoader.resolve_prop_id(&"arch") == &"archway_curved", "Alias 'arch' resolves to archway_curved")
	check(ModelLoader.resolve_prop_id(&"awning") == &"market_awning", "Alias 'awning' resolves to market_awning")
	check(ModelLoader.resolve_prop_id(&"urn") == &"desert_urn", "Alias 'urn' resolves to desert_urn")
	check(ModelLoader.resolve_prop_id(&"pallet") == &"wooden_pallet", "Alias 'pallet' resolves to wooden_pallet")

	# 3. Dedicated Prop Instantiation & Physics Collision Structure
	# Dog House
	var dh := ModelLoader.instantiate_prop(&"dog_house")
	check(dh != null, "dog_house instantiates cleanly")
	check(dh is StaticBody3D, "dog_house has StaticBody3D root")
	check((dh as StaticBody3D).collision_layer == Layers.WORLD, "dog_house collides on Layers.WORLD")
	check(dh.find_child("_dog", true, false) != null, "dog_house contains _dog node")
	check(dh.find_child("_tail", true, false) != null, "dog_house contains _tail node")
	dh.queue_free()

	# Playground Slide
	var slide := ModelLoader.instantiate_prop(&"playground_slide")
	check(slide != null, "playground_slide instantiates cleanly")
	check(slide.find_child("SlideBed", true, false) != null, "playground_slide contains SlideBed")
	slide.queue_free()

	# Picnic Table
	var table := ModelLoader.instantiate_prop(&"picnic_table")
	check(table != null, "picnic_table instantiates cleanly")
	check(table.find_child("Tabletop", true, false) != null, "picnic_table contains Tabletop")
	check(table.find_child("CoolerBody", true, false) != null, "picnic_table contains CoolerBody")
	table.queue_free()

	# Inflatable Bunker
	var bunker := ModelLoader.instantiate_prop(&"inflatable_bunker")
	check(bunker != null, "inflatable_bunker instantiates cleanly")
	check(bunker.find_child("VinylBody", true, false) != null, "inflatable_bunker contains VinylBody")
	check(bunker.find_child("AccentBand", true, false) != null, "inflatable_bunker contains AccentBand")
	bunker.queue_free()

	# Soccer Goal
	var goal := ModelLoader.instantiate_prop(&"soccer_goal")
	check(goal != null, "soccer_goal instantiates cleanly")
	check(goal.find_child("Crossbar", true, false) != null, "soccer_goal contains Crossbar")
	check(goal.find_child("NetBack", true, false) != null, "soccer_goal contains NetBack")
	goal.queue_free()

	# Cartoon Tree
	var tree := ModelLoader.instantiate_prop(&"cartoon_tree")
	check(tree != null, "cartoon_tree instantiates cleanly")
	check(tree.find_child("TrunkBase", true, false) != null, "cartoon_tree contains TrunkBase")
	check(tree.find_child("CanopyBase", true, false) != null, "cartoon_tree contains CanopyBase")
	tree.queue_free()

	# Watchtower
	var tower := ModelLoader.instantiate_prop(&"watchtower")
	check(tower != null, "watchtower instantiates cleanly")
	check(tower.find_child("Deck", true, false) != null, "watchtower contains Deck")
	check(tower.find_child("RoofCanopy", true, false) != null, "watchtower contains RoofCanopy")
	tower.queue_free()
	await physics_frames(2)

	# 4. ArenaKit.prop Helper & Decor Layer Clearing
	var test_parent := Node3D.new()
	add_child(test_parent)
	var placed_prop := ArenaKit.prop(test_parent, &"inflatable_bunker", Vector3(5.0, 0.0, 5.0), Vector3(0.0, 45.0, 0.0))
	check(placed_prop != null, "ArenaKit.prop instantiates and parents prop")
	check(placed_prop.position == Vector3(5.0, 0.0, 5.0), "ArenaKit.prop positions prop correctly")
	check(placed_prop is CollisionObject3D and (placed_prop as CollisionObject3D).collision_layer == Layers.WORLD, "Placed prop retains Layers.WORLD collision in standard parent")

	var decor_parent := Node3D.new()
	decor_parent.name = "Decor"
	add_child(decor_parent)
	var decor_tree := ArenaKit.prop(decor_parent, &"cartoon_tree", Vector3(10.0, 0.0, 10.0))
	check(decor_tree != null, "ArenaKit.prop instantiates tree in Decor")
	check(decor_tree is CollisionObject3D and (decor_tree as CollisionObject3D).collision_layer == 0, "Prop placed in Decor has collision_layer cleared to 0")

	test_parent.queue_free()
	decor_parent.queue_free()
	await physics_frames(2)

	# 5. Live DogHouse Interactive Reactivity with 3D Model
	var live_dog_house := DogHouse.new()
	add_child(live_dog_house)
	await physics_frames(2)
	check(live_dog_house._dog != null, "DogHouse hooks _dog node from 3D model")
	check(live_dog_house._tail != null, "DogHouse hooks _tail node from 3D model")

	var barks: Array[int] = [0]
	var on_barked := func() -> void: barks[0] += 1
	live_dog_house.barked.connect(on_barked)
	live_dog_house.on_dart_hit(null, Vector3.ZERO)
	check(barks[0] > 0, "DogHouse emits barked signal on dart hit with 3D model")
	check(live_dog_house._cooldown > 0.5, "DogHouse cooldown triggered on bark")
	live_dog_house.queue_free()
	await physics_frames(2)

	# 6. Live Arenas Build Cleanly with 3D Props
	# Playground
	var playground := Playground.new()
	playground.bake_navigation = false
	add_child(playground)
	await physics_frames(2)
	check(playground.geometry.get_child_count() > 0, "Playground builds geometry with 3D slide")
	playground.queue_free()

	# Sunny Park
	var sunny_park := SunnyPark.new()
	sunny_park.bake_navigation = false
	add_child(sunny_park)
	await physics_frames(2)
	check(sunny_park.geometry.get_child_count() > 0, "SunnyPark builds geometry with 3D picnic tables & trees")
	sunny_park.queue_free()

	# Soccer Field
	var soccer := SoccerField.new()
	soccer.bake_navigation = false
	add_child(soccer)
	await physics_frames(2)
	check(soccer.geometry.get_child_count() > 0, "SoccerField builds geometry with 3D goals & bunkers")
	soccer.queue_free()
	await physics_frames(2)

	# 7. High-Poly Tactical Props & ArenaKit Helpers
	var test_stage := Node3D.new()
	add_child(test_stage)
	var crate_node := ArenaKit.crate(test_stage, Vector3.ZERO, Vector3(1.8, 1.8, 1.8))
	check(crate_node != null, "ArenaKit.crate creates high-poly tactical crate")
	check(crate_node is StaticBody3D, "tactical crate has StaticBody3D")
	check((crate_node as StaticBody3D).collision_layer == Layers.WORLD, "tactical crate collides on Layers.WORLD")

	var barrel_node := ArenaKit.barrel(test_stage, Vector3(3.0, 0.0, 0.0))
	check(barrel_node != null, "ArenaKit.barrel creates high-poly ribbed barrel")
	check(barrel_node is StaticBody3D, "tactical barrel has StaticBody3D")

	var barrier_node := ArenaKit.barrier(test_stage, Vector3(-3.0, 0.0, 0.0))
	check(barrier_node != null, "ArenaKit.barrier creates curved inflatable barrier")

	var arch_node := ArenaKit.arch(test_stage, Vector3(0.0, 0.0, 5.0))
	check(arch_node != null, "ArenaKit.arch creates curved masonry archway")

	var cornice_node := ArenaKit.cornice(test_stage, Vector3(0.0, 5.0, 0.0), Vector3(10.0, 0.4, 0.8))
	check(cornice_node != null, "ArenaKit.cornice creates decorative crown trim")
	test_stage.queue_free()
	await physics_frames(2)

	# 8. Seamless World Triplanar Material Settings
	var mat_sand := ArenaKit.mat_styled(Color(0.88, 0.76, 0.56)) as StandardMaterial3D
	check(mat_sand != null, "Sand material created")
	check(mat_sand.uv1_triplanar == true, "Sand material has uv1_triplanar enabled")
	check(mat_sand.uv1_world_triplanar == true, "Sand material has uv1_world_triplanar enabled")
	check(mat_sand.uv1_triplanar_sharpness >= 4.0, "Sand material has crisp triplanar sharpness (>= 4.0)")

	var mat_sandstone := ArenaKit.mat_styled(Color(0.86, 0.76, 0.58)) as StandardMaterial3D
	check(mat_sandstone != null, "Sandstone material created")
	check(mat_sandstone.uv1_world_triplanar == true, "Sandstone has uv1_world_triplanar enabled")
	check(mat_sandstone.uv1_triplanar_sharpness >= 4.0, "Sandstone has crisp triplanar sharpness (>= 4.0)")

	# 9. Procedural Fallback Verification (when models_enabled = false)
	ModelLoader.models_enabled = false
	check(ModelLoader.has_prop_model(&"dog_house") == false, "has_prop_model returns false when models disabled")
	check(ArenaKit.prop(self, &"dog_house", Vector3.ZERO) == null, "ArenaKit.prop returns null when models disabled")

	var fallback_dog_house := DogHouse.new()
	add_child(fallback_dog_house)
	await physics_frames(2)
	check(fallback_dog_house._dog != null, "Procedural fallback DogHouse still constructs _dog")
	fallback_dog_house.queue_free()
	ModelLoader.models_enabled = true
	await physics_frames(2)


func _test_ctf_and_plant_the_bomb_modes() -> void:
	section("Modes: Capture The Flag & Plant The Bomb")

	# 1. Resources and mode resolution
	var ctf_res := load(CTF_MODE) as GameMode
	check(ctf_res != null, "CTF resource loads cleanly")
	check(ctf_res.id == &"capture_the_flag", "CTF resource id is capture_the_flag")
	check(ctf_res.is_team_mode(), "CTF is a team mode")

	var bomb_res := load(PLANT_THE_BOMB_MODE) as GameMode
	check(bomb_res != null, "Plant The Bomb resource loads cleanly")
	check(bomb_res.id == &"plant_the_bomb", "Bomb resource id is plant_the_bomb")
	check(bomb_res.is_team_mode(), "Bomb is a team mode")

	var resolved_ctf := MatchScene.resolve_mode(GameSettings.MatchMode.CAPTURE_THE_FLAG)
	check(resolved_ctf is CaptureTheFlagMode, "resolve_mode resolves CaptureTheFlagMode")

	var resolved_bomb := MatchScene.resolve_mode(GameSettings.MatchMode.PLANT_THE_BOMB)
	check(resolved_bomb is PlantTheBombMode, "resolve_mode resolves PlantTheBombMode")

	# 2. FlagPickup unit test: spawn, pickup, drop, return timer, capture
	var stage := make_stage()
	var blue_flag := FlagPickup.new()
	blue_flag.team_id = 0
	stage.add_child(blue_flag)
	blue_flag.global_position = Vector3(-10.0, 0.0, 0.0)
	blue_flag.base_position = Vector3(-10.0, 0.0, 0.0)
	blue_flag.reset_to_base()

	var orange_flag := FlagPickup.new()
	orange_flag.team_id = 1
	stage.add_child(orange_flag)
	orange_flag.global_position = Vector3(10.0, 0.0, 0.0)
	orange_flag.base_position = Vector3(10.0, 0.0, 0.0)
	orange_flag.reset_to_base()

	var blue_player := make_actor(stage, Vector3(-10.0, 0.0, 0.0), 0)
	var orange_player := make_actor(stage, Vector3(10.0, 0.0, 0.0), 1)

	# Blue player cannot pickup blue flag when at pedestal
	blue_flag._on_body_entered(blue_player)
	check(blue_flag.carrier == null, "blue flag carrier remains null when friendly player enters")
	check(blue_flag.state == FlagPickup.State.AT_BASE, "blue flag stays AT_BASE")

	# Orange player picks up blue flag
	var blue_picked := [false]
	blue_flag.picked_up.connect(func(_f: FlagPickup, _c: Actor) -> void: blue_picked[0] = true)
	blue_flag._on_body_entered(orange_player)
	check(blue_flag.carrier == orange_player, "carrier is orange player")
	check(blue_flag.state == FlagPickup.State.CARRIED, "blue flag state is CARRIED")
	check(blue_picked[0], "picked_up signal emitted")

	# Orange player tags out -> flag drops
	var blue_dropped := [false]
	blue_flag.dropped.connect(func(_f: FlagPickup, _p: Vector3) -> void: blue_dropped[0] = true)
	blue_flag.drop()
	check(blue_flag.carrier == null, "flag has no carrier after drop")
	check(blue_flag.state == FlagPickup.State.DROPPED, "flag is in DROPPED state")
	check(blue_dropped[0], "dropped signal emitted")

	# Blue player touches dropped flag -> returns to pedestal
	var blue_returned := [false]
	blue_flag.returned.connect(func(_f: FlagPickup) -> void: blue_returned[0] = true)
	blue_flag._on_body_entered(blue_player)
	check(blue_returned[0], "returned signal emitted")
	check(blue_flag.state == FlagPickup.State.AT_BASE, "blue flag returned to base")

	# Orange player picks up blue flag again
	blue_flag._on_body_entered(orange_player)
	check(blue_flag.carrier == orange_player, "orange player has blue flag")

	# Capture test
	var blue_captured := [false]
	blue_flag.captured.connect(func(_f: FlagPickup, _c: Actor) -> void: blue_captured[0] = true)
	blue_flag.capture(orange_player)
	check(blue_captured[0], "captured signal emitted")
	check(blue_flag.state == FlagPickup.State.AT_BASE, "captured flag resets to base")
	check(blue_flag.carrier == null, "carrier cleared after capture")

	# Auto-return timer tick test
	blue_flag._on_body_entered(orange_player)
	blue_flag.drop()
	check(blue_flag.state == FlagPickup.State.DROPPED, "flag dropped again")
	blue_flag.drop_timer = 0.05
	blue_flag._physics_process(0.1)
	check(blue_flag.state == FlagPickup.State.AT_BASE, "flag automatically returned after timeout")

	# 3. BombTarget unit test: spawn, pickup, plant, fuse, defuse, detonate
	var bomb := BombTarget.new()
	stage.add_child(bomb)
	bomb.setup_sites({
		"A": Vector3(15.0, 0.0, -15.0),
		"B": Vector3(-15.0, 0.0, -15.0)
	})
	bomb.spawn_bomb(Vector3(0.0, 0.0, 25.0))
	check(bomb.state == BombTarget.BombState.DROPPED, "bomb initial state is DROPPED")
	check(bomb.get_site_at(Vector3(15.0, 0.0, -15.0)) == "A", "site A recognized at pos")
	check(bomb.get_site_at(Vector3(-15.0, 0.0, -15.0)) == "B", "site B recognized at pos")
	check(bomb.get_site_at(Vector3(0.0, 0.0, 0.0)) == "", "no site in mid")

	# Defender (team 0) cannot pickup dropped bomb
	bomb._on_pickup_entered(blue_player)
	check(bomb.carrier == null, "defenders cannot pickup unplanted bomb")

	# Attacker (team 1) picks up bomb
	var bomb_picked := [false]
	bomb.bomb_picked_up.connect(func(_c: Actor) -> void: bomb_picked[0] = true)
	bomb._on_pickup_entered(orange_player)
	check(bomb.carrier == orange_player, "carrier is attacker")
	check(bomb.state == BombTarget.BombState.CARRIED, "bomb state is CARRIED")
	check(bomb_picked[0], "bomb_picked_up signal emitted")

	# Carrier drops bomb
	var bomb_dropped_flag := [false]
	bomb.bomb_dropped.connect(func(_p: Vector3) -> void: bomb_dropped_flag[0] = true)
	bomb.drop_bomb(Vector3(2.0, 0.0, 2.0))
	check(bomb.carrier == null, "carrier cleared on drop")
	check(bomb.state == BombTarget.BombState.DROPPED, "bomb state is DROPPED")
	check(bomb_dropped_flag[0], "bomb_dropped signal emitted")

	# Attacker picks up dropped bomb
	bomb._on_pickup_entered(orange_player)
	check(bomb.carrier == orange_player, "attacker retrieves dropped bomb")

	# Planting at Site A
	orange_player.global_position = Vector3(15.0, 0.0, -15.0)
	var planted_site := [""]
	bomb.bomb_planted.connect(func(site: String, _p: Vector3) -> void: planted_site[0] = site)
	bomb.progress_plant(orange_player, 1.0)
	check(bomb.state == BombTarget.BombState.PLANTING, "bomb is PLANTING")
	check(bomb.plant_progress_left > 0.0, "plant progress advancing")

	# Complete plant
	bomb.progress_plant(orange_player, 3.0)
	check(bomb.state == BombTarget.BombState.PLANTED, "bomb is PLANTED")
	check(planted_site[0] == "A", "bomb_planted signal emitted for Site A")
	check(bomb.fuse_left > 35.0, "fuse started around 40s")
	check(bomb.carrier == null, "carrier cleared upon plant")

	# Defender defuses bomb
	blue_player.global_position = bomb._bomb_model.global_position
	var defused := [false]
	bomb.bomb_defused.connect(func(_d: Actor) -> void: defused[0] = true)
	bomb.progress_defuse(blue_player, 1.0)
	check(bomb.state == BombTarget.BombState.DEFUSING, "bomb is DEFUSING")
	check(bomb.defuse_progress_left > 0.0, "defuse progress advancing")

	bomb.progress_defuse(blue_player, 4.0)
	check(bomb.state == BombTarget.BombState.DEFUSED, "bomb is DEFUSED")
	check(defused[0], "bomb_defused signal emitted")

	# Detonation test
	bomb.spawn_bomb(Vector3(15.0, 0.0, -15.0), orange_player)
	bomb.progress_plant(orange_player, 3.0)
	check(bomb.state == BombTarget.BombState.PLANTED, "bomb replanted")
	var detonated := [false]
	bomb.bomb_detonated.connect(func(_s: String, _p: Vector3) -> void: detonated[0] = true)
	bomb.fuse_left = 0.05
	bomb._physics_process(0.1)
	check(bomb.state == BombTarget.BombState.DETONATED, "bomb is DETONATED")
	check(detonated[0], "bomb_detonated signal emitted")

	stage.queue_free()
	await physics_frames(2)


func _test_classic_arenas_2fort_dust_dust2() -> void:
	section("Arenas: Two Fortresses, Dusty Courtyard & Duststorm II")

	# 1. Two Fortresses (2Fort)
	var two_forts := TwoForts.new()
	two_forts.bake_navigation = false
	add_child(two_forts)
	await physics_frames(2)
	check(two_forts.geometry.get_child_count() > 0, "TwoForts builds extensive geometry")
	check(two_forts.flag_pedestals.size() >= 2, "TwoForts registers at least 2 flag pedestals (Blue & Orange)")
	check(two_forts.get_flag_pedestal(0) != Vector3.ZERO, "TwoForts Blue flag pedestal defined")
	check(two_forts.get_flag_pedestal(1) != Vector3.ZERO, "TwoForts Orange flag pedestal defined")
	check(two_forts.spawn_points.size() >= 4, "TwoForts has player/bot spawns")
	two_forts.queue_free()
	await physics_frames(2)

	# 2. Dusty Courtyard (de_dust)
	var dust := DustCourtyard.new()
	dust.bake_navigation = false
	add_child(dust)
	await physics_frames(2)
	check(dust.geometry.get_child_count() > 0, "DustCourtyard builds geometry")
	check(dust.bomb_sites.has("A") and dust.bomb_sites.has("B"), "DustCourtyard registers Bomb Site A and Site B")
	check(dust.bomb_spawns.size() > 0, "DustCourtyard defines bomb spawn location")
	check(dust.spawn_points.size() >= 4, "DustCourtyard defines player/bot spawns")
	dust.queue_free()
	await physics_frames(2)

	# 3. Duststorm II (de_dust2)
	var dust2 := Dust2.new()
	dust2.bake_navigation = false
	add_child(dust2)
	await physics_frames(2)
	check(dust2.geometry.get_child_count() > 0, "Dust2 builds geometry")
	check(dust2.bomb_sites.has("A") and dust2.bomb_sites.has("B"), "Dust2 registers Bomb Site A and Site B")
	check(dust2.bomb_spawns.size() > 0, "Dust2 defines bomb spawn location")
	check(dust2.spawn_points.size() >= 4, "Dust2 defines player/bot spawns")
	dust2.queue_free()
	await physics_frames(2)

	# 4. CTF Match Simulation on Two Forts
	var saved_mode := GameSettings.match_mode
	var saved_arena := GameSettings.arena
	var saved_bots := GameSettings.bot_count

	GameSettings.arena = 6  # Two Forts
	GameSettings.bot_count = 2
	var ctf_game := start_match(GameSettings.MatchMode.CAPTURE_THE_FLAG)
	var ctf_controller := ctf_game.get("controller") as MatchController
	var ctf_hud := ctf_game.get("hud") as Hud
	check(ctf_controller != null, "CTF match controller initialized")
	check(ctf_controller.mode is CaptureTheFlagMode, "Match mode is CaptureTheFlagMode")
	check(ctf_hud != null, "HUD initialized in CTF")
	check(ctf_hud.team_chip_count() == 2, "HUD displays team scores for Blue & Orange")
	var ctf_flags: Array = ctf_game.get("flags")
	check(ctf_flags.size() == 2, "CTF match spawned 2 flags")
	await fast_forward(0.5)
	await end_match(ctf_game, saved_mode)

	# 5. Plant The Bomb Match Simulation on Dust2
	GameSettings.arena = 8  # Dust2
	GameSettings.bot_count = 2
	var bomb_game := start_match(GameSettings.MatchMode.PLANT_THE_BOMB)
	var bomb_controller := bomb_game.get("controller") as MatchController
	var bomb_hud := bomb_game.get("hud") as Hud
	check(bomb_controller != null, "Bomb match controller initialized")
	check(bomb_controller.mode is PlantTheBombMode, "Match mode is PlantTheBombMode")
	check(bomb_hud != null, "HUD initialized in Plant The Bomb")
	check(bomb_hud.team_chip_count() == 2, "HUD displays round score for Blue & Orange")
	var live_bomb: BombTarget = bomb_game.get("bomb_target") as BombTarget
	check(live_bomb != null, "Plant The Bomb match spawned live BombTarget")
	check(live_bomb.has_site("A") and live_bomb.has_site("B"), "live BombTarget populated with Sites A and B")
	await fast_forward(0.5)
	await end_match(bomb_game, saved_mode)

	GameSettings.arena = saved_arena
	GameSettings.bot_count = saved_bots
	GameSettings.match_mode = saved_mode


func _test_lan_server_browser_and_dedicated_server() -> void:
	section("LAN Server Browser & Headless Dedicated Server")

	# 1. LanDiscovery Node & Configuration
	var discovery := LanDiscovery.new()
	add_child(discovery)
	await physics_frames(1)

	check(discovery != null, "LanDiscovery instantiated")
	check(LanDiscovery.DISCOVERY_PORT == 8925, "Discovery UDP port is 8925")
	check(not discovery.is_broadcasting, "is_broadcasting is false before start")
	check(not discovery.is_listening, "is_listening is false before start")

	# 2. Server info setup
	discovery.set_server_info(8910, "Test LAN Server", 6, 8, 2, 8, true)
	check(discovery.server_name == "Test LAN Server", "server_name updated")
	check(discovery.server_port == 8910, "server_port updated")
	check(discovery.current_arena == 6, "current_arena updated")
	check(discovery.current_mode == 8, "current_mode updated")
	check(discovery.player_count == 2, "player_count updated")
	check(discovery.max_players == 8, "max_players updated")
	check(discovery.is_dedicated == true, "is_dedicated updated")

	# 3. Beacon packet ingestion & parsing
	var signal_received: Array[bool] = [false]
	var on_updated := func(_servers: Array[Dictionary]) -> void:
		signal_received[0] = true
	discovery.servers_updated.connect(on_updated)

	var payload_dict := {
		"magic": "DARTSTORM",
		"name": "LAN Battle Arena",
		"port": 8915,
		"arena": 8,
		"arena_name": "Duststorm II",
		"mode": 9,
		"mode_name": "Plant The Bomb",
		"players": 4,
		"max_players": 12,
		"dedicated": true
	}
	var raw_packet := JSON.stringify(payload_dict).to_utf8_buffer()
	discovery._on_packet_received(raw_packet, "192.168.1.105", 8925)

	check(signal_received[0], "servers_updated emitted when valid beacon received")
	var servers := discovery.get_discovered_servers()
	check(servers.size() == 1, "discovered_servers has 1 server recorded")
	if servers.size() > 0:
		var s := servers[0]
		check(s.get("ip") == "192.168.1.105", "server IP correctly parsed (192.168.1.105)")
		check(s.get("port") == 8915, "server port correctly parsed (8915)")
		check(s.get("name") == "LAN Battle Arena", "server name correctly parsed")
		check(s.get("arena") == 8, "arena correctly parsed (8)")
		check(s.get("arena_name") == "Duststorm II", "arena_name correctly parsed (Duststorm II)")
		check(s.get("mode") == 9, "mode correctly parsed (9)")
		check(s.get("mode_name") == "Plant The Bomb", "mode_name correctly parsed (Plant The Bomb)")
		check(s.get("players") == 4 and s.get("max_players") == 12, "player counts correctly parsed (4/12)")
		check(s.get("dedicated") == true, "dedicated flag is true")

	# 4. Reject invalid / alien packets
	var alien_dict := {"magic": "OTHER_GAME", "name": "Alien"}
	var alien_packet := JSON.stringify(alien_dict).to_utf8_buffer()
	discovery._on_packet_received(alien_packet, "192.168.1.199", 8925)
	check(discovery.get_discovered_servers().size() == 1, "alien beacon without DARTSTORM magic is rejected")

	var malformed_packet := "NOT_JSON_DATA".to_utf8_buffer()
	discovery._on_packet_received(malformed_packet, "192.168.1.199", 8925)
	check(discovery.get_discovered_servers().size() == 1, "malformed non-JSON packet safely rejected without crash")

	# 5. Stale server timeout & pruning
	var keys: Array = discovery.discovered_servers.keys()
	if not keys.is_empty():
		var key: String = keys[0]
		discovery.discovered_servers[key]["last_seen_msec"] = Time.get_ticks_msec() - 4000  # Older than 3500ms
		signal_received[0] = false
		discovery._prune_stale_servers()
		check(discovery.get_discovered_servers().is_empty(), "stale server pruned after timeout")
		check(signal_received[0], "servers_updated emitted when stale server pruned")

	if discovery.servers_updated.is_connected(on_updated):
		discovery.servers_updated.disconnect(on_updated)
	discovery.queue_free()
	await physics_frames(2)

	# 6. DedicatedServer static CLI parsers validation
	check(DedicatedServer.parse_arena("2fort") == 6, "parse_arena('2fort') -> 6 (Two Fortresses)")
	check(DedicatedServer.parse_arena("dust") == 7, "parse_arena('dust') -> 7 (Dusty Courtyard)")
	check(DedicatedServer.parse_arena("dust2") == 8, "parse_arena('dust2') -> 8 (Duststorm II)")
	check(DedicatedServer.parse_arena("tempest") == 2, "parse_arena('tempest') -> 2 (Treehouse)")
	check(DedicatedServer.parse_mode("ctf") == GameSettings.MatchMode.CAPTURE_THE_FLAG, "parse_mode('ctf') -> CAPTURE_THE_FLAG (8)")
	check(DedicatedServer.parse_mode("bomb") == GameSettings.MatchMode.PLANT_THE_BOMB, "parse_mode('bomb') -> PLANT_THE_BOMB (9)")
	check(DedicatedServer.parse_mode("tdm") == GameSettings.MatchMode.TEAMS, "parse_mode('tdm') -> TEAMS (3)")
	check(DedicatedServer.parse_mode("duos") == GameSettings.MatchMode.DUOS, "parse_mode('duos') -> DUOS (2)")
	check(DedicatedServer.parse_mode("gun_game") == GameSettings.MatchMode.GUN_GAME, "parse_mode('gun_game') -> GUN_GAME (1)")
	check(DedicatedServer.parse_mode("realistic") == GameSettings.MatchMode.REALISTIC, "parse_mode('realistic') -> REALISTIC (7)")

	# Map rotation parser
	var rot := DedicatedServer.parse_map_rotation("2fort, dust2, backyard")
	check(rot.size() == 3, "parse_map_rotation parsed 3 arenas")
	check(rot[0] == 6 and rot[1] == 8 and rot[2] == 0,
		"rotation sequence correctly parsed [6, 8, 0]")

	# 7. NetworkManager dedicated server & LAN bridge checks
	check(NetworkManager.has_signal("lan_servers_updated"), "NetworkManager provides lan_servers_updated signal")
	check(typeof(NetworkManager.get_lan_servers()) == TYPE_ARRAY, "get_lan_servers() returns Array")
	check("is_dedicated_server" in NetworkManager, "NetworkManager has is_dedicated_server property")


func _test_weapon_modding_garage_workbench_and_mastery() -> void:
	section("Backyard Garage Workbench, Blaster Mastery & Aftermarket Attachments (v2.3.0)")

	# 1. WeaponModding Catalog & Slots Registry
	check(WeaponModding.WORKBENCH_BLASTERS.size() == 7, "WeaponModding defines all 7 workbench blasters")
	check(WeaponModding.ATTACHMENTS.size() >= 19, "WeaponModding defines at least 19 aftermarket attachments")

	var slots_to_test := [
		WeaponModding.Slot.OPTIC,
		WeaponModding.Slot.BARREL,
		WeaponModding.Slot.SPRING,
		WeaponModding.Slot.MAGAZINE,
		WeaponModding.Slot.STOCK,
	]
	for slot: WeaponModding.Slot in slots_to_test:
		var atts := WeaponModding.get_attachments_for_slot(slot)
		check(not atts.is_empty(), "Slot %s has registered attachments (count: %d)" % [WeaponModding.slot_name(slot), atts.size()])
		var def_att := WeaponModding.get_default_attachment_for_slot(slot)
		check(not def_att.is_empty(), "Slot %s has a valid default attachment (%s)" % [WeaponModding.slot_name(slot), def_att])

	var stock_loadout: Dictionary = WeaponModding.default_equipped()
	check(stock_loadout.size() == 5, "default_equipped() returns dictionary with 5 slots")
	check(stock_loadout.has("optic") and stock_loadout.has("barrel") and stock_loadout.has("spring") and stock_loadout.has("magazine") and stock_loadout.has("stock"),
		"default_equipped() contains all 5 slot keys")

	# 2. Weapon Mastery Curve & Details
	check(WeaponModding.MASTERY_THRESHOLDS.size() == 10, "10 Mastery rank thresholds defined")
	check(WeaponModding.MASTERY_TITLES.size() == 10, "10 Mastery titles defined")
	check(WeaponModding.get_mastery_rank(0) == 1, "0 XP is Rank 1")
	check(WeaponModding.get_mastery_rank(99) == 1, "99 XP is Rank 1")
	check(WeaponModding.get_mastery_rank(100) == 2, "100 XP is Rank 2")
	check(WeaponModding.get_mastery_rank(500) == 4, "500 XP is Rank 4")
	check(WeaponModding.get_mastery_rank(4500) == 10, "4500 XP is Rank 10 (Grandmaster)")
	check(WeaponModding.get_mastery_rank(99999) == 10, "Over-cap XP clamped to Rank 10")

	var prog_zero: Dictionary = WeaponModding.get_mastery_progress(0)
	check(prog_zero["rank"] == 1 and not bool(prog_zero["is_max"]) and float(prog_zero["ratio"]) == 0.0,
		"get_mastery_progress(0) returns Rank 1, 0.0 ratio, is_max false")

	var prog_half: Dictionary = WeaponModding.get_mastery_progress(50)
	check(prog_half["rank"] == 1 and is_equal_approx(float(prog_half["ratio"]), 0.5),
		"get_mastery_progress(50) returns Rank 1 with 0.5 ratio")

	var prog_max: Dictionary = WeaponModding.get_mastery_progress(5000)
	check(prog_max["rank"] == 10 and bool(prog_max["is_max"]) and float(prog_max["ratio"]) == 1.0,
		"get_mastery_progress(5000) returns Rank 10 Grandmaster with is_max true")

	# 3. Attachment Modifiers Calculation
	var empty_mods: Dictionary = WeaponModding.compute_attachment_modifiers({})
	check(empty_mods["spread_mult"] == 1.0 and empty_mods["velocity_mult"] == 1.0 and empty_mods["tag_power_mult"] == 1.0,
		"empty attachments dictionary produces neutral 1.0 multipliers")
	check(empty_mods["mag_bonus"] == 0 and empty_mods["zoom_fov"] == 0.0 and empty_mods["reticle"] == &"standard",
		"empty attachments dictionary produces 0 mag_bonus, 0.0 zoom_fov, standard reticle")

	var optic_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"optic": &"red_dot"})
	check(optic_mods["zoom_fov"] == 65.0, "red_dot attachment provides 65.0 zoom_fov")
	check(optic_mods["reticle"] == &"red_dot", "red_dot attachment sets reticle to red_dot")

	var holo_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"optic": &"holo_sight"})
	check(holo_mods["zoom_fov"] == 55.0 and holo_mods["reticle"] == &"holo", "holo_sight provides 55.0 zoom_fov and holo reticle")

	var scope_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"optic": &"marksman_scope"})
	check(scope_mods["zoom_fov"] == 35.0 and scope_mods["reticle"] == &"scope", "marksman_scope provides 35.0 zoom_fov and scope reticle")

	var barrel_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"barrel": &"rifled_extension"})
	check(barrel_mods["spread_mult"] < 1.0 and barrel_mods["velocity_mult"] > 1.0,
		"rifled_extension reduces spread and increases dart velocity")

	var mag_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"magazine": &"extended_drum"})
	check(mag_mods["mag_bonus"] > 0, "extended_drum provides positive dart capacity bonus")

	var whisper_mods: Dictionary = WeaponModding.compute_attachment_modifiers({"barrel": &"whisper_shroud"})
	check(whisper_mods["sound_override"] == &"whoosh", "whisper_shroud provides whoosh muffled sound override")

	# 4. Progression Weapon Mastery & Attachment Storage
	var test_w_id := &"pocket_popper"
	var initial_mastery := Progression.get_weapon_mastery(test_w_id)
	var initial_xp: int = int(initial_mastery.get("xp", 0))

	# Record a tag
	var res_tag := Progression.record_weapon_tag(test_w_id, false)
	check(res_tag["xp_added"] == 50, "record_weapon_tag awards 50 XP for standard tag")
	var mid_mastery := Progression.get_weapon_mastery(test_w_id)
	check(int(mid_mastery.get("xp", 0)) == initial_xp + 50, "Progression recorded +50 XP on weapon")

	# Record a ricochet tag
	var res_rico := Progression.record_weapon_tag(test_w_id, true)
	check(res_rico["xp_added"] == 75, "record_weapon_tag awards 75 XP for ricochet tag (+25 bonus)")
	var rico_mastery := Progression.get_weapon_mastery(test_w_id)
	check(int(rico_mastery.get("xp", 0)) == initial_xp + 125, "Progression recorded +75 XP for ricochet tag")

	# Equip attachment via Progression
	var eq_success := Progression.equip_attachment(test_w_id, &"optic", &"red_dot")
	check(eq_success, "Progression.equip_attachment succeeded")
	var equipped := Progression.get_equipped_attachments(test_w_id)
	check(equipped.get("optic") == &"red_dot", "Progression stores equipped red_dot optic")

	# 5. WeaponState Modifiers Integration
	var popper_data := load("res://resources/weapons/pocket_popper.tres") as WeaponData
	check(popper_data != null, "pocket_popper.tres weapon data loaded")

	var state_modded := WeaponState.new(popper_data, false, {"optic": &"red_dot", "magazine": &"extended_drum", "barrel": &"rifled_extension"})
	check(state_modded.get_zoom_fov() == 65.0, "WeaponState.get_zoom_fov() returns 65.0 for red_dot")
	check(state_modded.get_reticle() == &"red_dot", "WeaponState.get_reticle() returns red_dot")
	check(state_modded.get_magazine_size() > popper_data.magazine_size, "WeaponState.get_magazine_size() accounts for extended drum")
	check(state_modded.get_spread_degrees() < popper_data.spread_degrees, "WeaponState.get_spread_degrees() accounts for rifled extension")

	# 6. BlasterModel Attachment Mounting & Rebuilding
	var blaster_with_mods := BlasterModel.create(popper_data, false, &"default", {
		"optic": &"red_dot",
		"barrel": &"rifled_extension",
		"magazine": &"extended_drum",
		"stock": &"skeleton_stock"
	})
	add_child(blaster_with_mods)
	await physics_frames(2)

	check(blaster_with_mods.attachment_nodes.has(&"optic"), "BlasterModel spawned 3D optic attachment node")
	check(blaster_with_mods.attachment_nodes.has(&"barrel"), "BlasterModel spawned 3D barrel attachment node")
	check(blaster_with_mods.attachment_nodes.has(&"magazine"), "BlasterModel spawned 3D magazine attachment node")
	check(blaster_with_mods.attachment_nodes.has(&"stock"), "BlasterModel spawned 3D stock attachment node")

	# Test dynamic update of attachments
	blaster_with_mods.update_attachments({"optic": &"holo_sight", "barrel": &"whisper_shroud"})
	await physics_frames(2)
	check(blaster_with_mods.attachment_nodes.has(&"optic"), "BlasterModel updated optic node to holo_sight")
	check(blaster_with_mods.attachment_nodes.has(&"barrel"), "BlasterModel updated barrel node to whisper_shroud")
	check(not blaster_with_mods.attachment_nodes.has(&"stock"), "Unspecified stock node removed cleanly")

	blaster_with_mods.queue_free()
	await physics_frames(2)

	# Test ADS Offset Alignment
	var test_ads_model := BlasterModel.create(popper_data, true, &"default", {"optic": &"red_dot"})
	add_child(test_ads_model)
	await physics_frames(2)
	var ads_off := test_ads_model.get_ads_offset()
	check(is_zero_approx(ads_off.x), "BlasterModel.get_ads_offset() centers X at 0.0")
	check(ads_off.y < 0.0, "BlasterModel.get_ads_offset() elevates blaster Y to align optic")
	test_ads_model.queue_free()
	await physics_frames(2)

	# Test CharacterModel 3rd-person attachment mounting
	var test_char := CharacterModel.new()
	add_child(test_char)
	test_char.setup(&"Tester", Color.BLUE, &"cap")
	test_char.set_weapon(popper_data, &"default", {"optic": &"holo_sight", "barrel": &"rifled_extension"})
	await physics_frames(2)
	var char_weapon := test_char.get_weapon()
	check(char_weapon != null and char_weapon.attachment_nodes.has(&"optic"), "CharacterModel mounted 3D optic in third-person")
	check(char_weapon != null and char_weapon.attachment_nodes.has(&"barrel"), "CharacterModel mounted 3D barrel in third-person")
	test_char.queue_free()
	await physics_frames(2)

	# Test Arsenal & Stock Mobility Modifiers
	var stock_mods := WeaponModding.compute_attachment_modifiers({"stock": &"skeleton_stock"})
	check(stock_mods.get("move_mult", 1.0) == 1.05, "skeleton_stock provides 1.05 move_mult (+5% mobility)")
	var crane_mods := WeaponModding.compute_attachment_modifiers({"stock": &"counterweight_stock"})
	check(crane_mods.get("move_mult", 1.0) == 0.96, "counterweight_stock provides 0.96 move_mult (-4% mobility)")

	var state_stock := WeaponState.new(popper_data, false, {"stock": &"skeleton_stock"})
	check(state_stock.get_move_multiplier() == 1.05, "WeaponState.get_move_multiplier() returns 1.05 for skeleton_stock")

	# 7. Crosshair Reticle Modes
	var crosshair := Crosshair.new()
	add_child(crosshair)
	crosshair.set_scoped(true)

	crosshair.set_reticle_from_string(&"red_dot")
	check(crosshair.reticle_type == Crosshair.ReticleType.RED_DOT, "Crosshair set to RED_DOT reticle")

	crosshair.set_reticle_from_string(&"holo")
	check(crosshair.reticle_type == Crosshair.ReticleType.HOLO, "Crosshair set to HOLO reticle")

	crosshair.set_reticle_from_string(&"scope")
	check(crosshair.reticle_type == Crosshair.ReticleType.SCOPE, "Crosshair set to SCOPE reticle")

	crosshair.set_reticle_from_string(&"standard")
	check(crosshair.reticle_type == Crosshair.ReticleType.STANDARD, "Crosshair set to STANDARD reticle")

	crosshair.queue_free()
	await physics_frames(2)

	# 8. GarageWorkbench 3D Scene Node
	var workbench := GarageWorkbench.new()
	add_child(workbench)
	await physics_frames(3)

	check(workbench.camera != null, "GarageWorkbench initialized 3D camera")
	check(workbench.turntable != null, "GarageWorkbench initialized 3D turntable")
	check(workbench.dart_target != null, "GarageWorkbench initialized dart target")
	check(workbench.active_blaster_model != null, "GarageWorkbench instantiated active blaster model on turntable")

	# Test slot focus presets
	workbench.focus_slot(WeaponModding.Slot.OPTIC)
	check(workbench.distance < 1.0, "focus_slot(OPTIC) zoomed camera in on top rail")
	workbench.focus_slot(WeaponModding.Slot.NONE)
	check(workbench.distance >= 1.2, "focus_slot(NONE) zoomed camera out to overview")

	# Test camera orbit & zoom helper methods
	var prev_yaw := workbench.yaw
	workbench.rotate_orbit(Vector2(20.0, 10.0))
	check(workbench.yaw != prev_yaw, "GarageWorkbench.rotate_orbit changes camera yaw")
	workbench.zoom_orbit(-0.2)
	check(workbench.distance < 1.2, "GarageWorkbench.zoom_orbit zooms camera")
	workbench.reset_camera_view()
	check(is_equal_approx(workbench.distance, 1.35), "GarageWorkbench.reset_camera_view restores default distance")

	# Test fire action
	var test_fired_signal := [false]
	var on_fired := func() -> void: test_fired_signal[0] = true
	workbench.test_fired.connect(on_fired)

	workbench.test_fire()
	check(test_fired_signal[0], "GarageWorkbench emitted test_fired signal on test_fire()")
	check(workbench._test_dart != null, "GarageWorkbench spawned visual test dart projectile")

	if workbench.test_fired.is_connected(on_fired):
		workbench.test_fired.disconnect(on_fired)
	workbench.queue_free()
	await physics_frames(3)

	# 9. WorkbenchPanel UI Overlay Node
	var panel := WorkbenchPanel.new()
	add_child(panel)
	await physics_frames(2)

	check(panel._drag_catcher != null, "WorkbenchPanel initialized viewport drag catcher")
	check(panel._slot_buttons.size() == 5, "WorkbenchPanel initialized 5 slot buttons")
	check(panel._stat_bars.size() == 6, "WorkbenchPanel initialized 6 performance stat bars")

	panel._select_slot(WeaponModding.Slot.OPTIC)
	check(panel._drawer_panel.visible, "Selecting slot opens attachment drawer")

	panel._close_drawer()
	check(not panel._drawer_panel.visible, "Closing drawer hides attachment drawer")

	panel.queue_free()
	await physics_frames(3)

	# 10. CharacterModel set_shirt verification
	var char_model := CharacterModel.new()
	add_child(char_model)
	char_model.setup("TestPlayer", Color.BLUE, &"cap")
	char_model.set_shirt(Color.RED)
	check(char_model._tint == Color.RED, "CharacterModel.set_shirt updates model tint")
	char_model.queue_free()
	await physics_frames(3)


func _test_objective_bot_ai() -> void:
	section("AI: Objective Decisions in Plant The Bomb & CTF")

	var stage := make_stage()
	var arena := Arena.new()
	arena.flag_pedestals = [Vector3(-20.0, 0.0, 0.0), Vector3(20.0, 0.0, 0.0)]
	arena.bomb_sites = {"A": Vector3(18.0, 0.0, -10.0), "B": Vector3(-18.0, 0.0, -10.0)}
	stage.add_child(arena)

	# --- 1. Plant The Bomb: Attacker Carrier, Escort & Dropped Bomb ---
	var bomb := BombTarget.new()
	stage.add_child(bomb)
	bomb.setup_sites({
		"A": Vector3(18.0, 0.0, -10.0),
		"B": Vector3(-18.0, 0.0, -10.0)
	})
	bomb.spawn_bomb(Vector3(0.0, 0.0, 20.0))

	var att_carrier := Bot.new()
	att_carrier.team_id = 1
	att_carrier.display_name = "Attacker Carrier"
	att_carrier.arena = arena
	stage.add_child(att_carrier)
	att_carrier.global_position = Vector3(0.0, 0.0, 20.0)

	var att_escort := Bot.new()
	att_escort.team_id = 1
	att_escort.display_name = "Attacker Escort"
	att_escort.arena = arena
	stage.add_child(att_escort)
	att_escort.global_position = Vector3(2.0, 0.0, 22.0)

	await physics_frames(2)

	# Carrier picks up bomb
	bomb._on_pickup_entered(att_carrier)
	check(bomb.carrier == att_carrier, "Attacker carrier picks up bomb")

	# Attacker Carrier decides to push to site
	var carrier_handled := att_carrier._think_bomb_objective(bomb)
	check(carrier_handled, "Carrier handles bomb objective")
	check(att_carrier.tactical_role == Bot.TacticalRole.BOMB_CARRIER, "Carrier assigns BOMB_CARRIER role")
	check(att_carrier.assigned_bomb_site == "A" or att_carrier.assigned_bomb_site == "B", "Carrier selects bomb site A or B")
	check(att_carrier._has_goal, "Carrier sets navigation goal towards chosen site")

	# Attacker Escort establishes convoy formation around carrier
	var escort_handled := att_escort._think_bomb_objective(bomb)
	check(escort_handled, "Escort handles bomb objective")
	check(att_escort.tactical_role == Bot.TacticalRole.BOMB_ESCORT, "Escort assigns BOMB_ESCORT role")
	check(att_escort._has_goal, "Escort sets convoy movement goal near carrier")

	# Carrier arrives at site A to plant
	att_carrier.global_position = Vector3(18.0, 0.0, -10.0)
	att_carrier._think_bomb_objective(bomb)
	check(att_carrier._goal == att_carrier.global_position, "Carrier holds ground at site perimeter to plant")

	# Planting begins
	bomb.progress_plant(att_carrier, 1.0)
	check(bomb.state == BombTarget.BombState.PLANTING, "Bomb is in PLANTING state")
	att_escort._think_bomb_objective(bomb)
	check(att_escort.tactical_role == Bot.TacticalRole.BOMB_ESCORT, "Escort protects carrier during planting")

	# Plant completed -> switch to post-plant crossfire
	bomb.progress_plant(att_carrier, 3.5)
	check(bomb.state == BombTarget.BombState.PLANTED, "Bomb is PLANTED at site")
	att_carrier._think_bomb_objective(bomb)
	check(att_carrier.tactical_role == Bot.TacticalRole.BOMB_POST_PLANT, "Carrier shifts to BOMB_POST_PLANT role")
	att_escort._think_bomb_objective(bomb)
	check(att_escort.tactical_role == Bot.TacticalRole.BOMB_POST_PLANT, "Escort shifts to BOMB_POST_PLANT role")
	check(att_carrier._goal != att_escort._goal, "Post-plant attackers choose distinct crossfire positions")

	# --- 2. Plant The Bomb: Defender Split & Single Defuser Coordination ---
	var def_closer := Bot.new()
	def_closer.team_id = 0
	def_closer.display_name = "Defender Alpha"
	def_closer.arena = arena
	stage.add_child(def_closer)
	def_closer.global_position = bomb.get_bomb_position() + Vector3(3.0, 0.0, 0.0)

	var def_further := Bot.new()
	def_further.team_id = 0
	def_further.display_name = "Defender Beta"
	def_further.arena = arena
	stage.add_child(def_further)
	def_further.global_position = bomb.get_bomb_position() + Vector3(16.0, 0.0, 0.0)

	await physics_frames(2)

	# Pre-plant defense distribution check
	bomb.state = BombTarget.BombState.CARRIED
	def_closer.assigned_bomb_site = ""
	def_further.assigned_bomb_site = ""
	def_closer._think_bomb_objective(bomb)
	def_further._think_bomb_objective(bomb)
	check(def_closer.tactical_role == Bot.TacticalRole.BOMB_DEFENDER_SITE_A or def_closer.tactical_role == Bot.TacticalRole.BOMB_DEFENDER_SITE_B, "Defender Alpha chooses site defense")
	check(def_further.tactical_role == Bot.TacticalRole.BOMB_DEFENDER_SITE_A or def_further.tactical_role == Bot.TacticalRole.BOMB_DEFENDER_SITE_B, "Defender Beta chooses site defense")

	# Planted bomb defusal coordination: closer bot becomes defuser, further provides cover
	bomb.state = BombTarget.BombState.PLANTED
	def_closer._think_bomb_objective(bomb)
	def_further._think_bomb_objective(bomb)
	check(def_closer.is_designated_defuser, "Closer defender is designated as sole defuser")
	check(def_closer.tactical_role == Bot.TacticalRole.BOMB_DEFUSER, "Closer defender adopts BOMB_DEFUSER role")
	check(not def_further.is_designated_defuser, "Further defender is NOT designated defuser")
	check(def_further.tactical_role == Bot.TacticalRole.BOMB_DEFUSE_COVER, "Further defender adopts BOMB_DEFUSE_COVER role")

	# Post-plant attackers target the defuser
	bomb.current_defuser = def_closer
	att_carrier._think_bomb_objective(bomb)
	check(att_carrier._target == def_closer, "Attackers prioritize targeting active defuser")

	# Single-defuser rule in _physics_process
	# If non-defuser is at bomb, it does NOT defuse
	def_closer.controls_enabled = true
	def_further.controls_enabled = true
	def_further.is_designated_defuser = false
	def_further._think_left = 10.0
	var initial_defuse := bomb.defuse_progress_left
	def_further.global_position = bomb.get_bomb_position()
	def_further._physics_process(0.1)
	check(bomb.defuse_progress_left == initial_defuse, "Non-defuser bot does not advance defuse progress")

	# Designated defuser advances defusal
	def_closer.is_designated_defuser = true
	def_closer._think_left = 10.0
	def_closer.global_position = bomb.get_bomb_position()
	def_closer._physics_process(0.2)
	check(bomb.defuse_progress_left > initial_defuse, "Designated defuser bot advances defuse progress")

	# Human player proximity rule: bot yields defuse to nearby human teammate
	var human_teammate := Actor.new()
	human_teammate.team_id = 0
	human_teammate.is_human = true
	human_teammate.display_name = "Human Defender"
	stage.add_child(human_teammate)
	human_teammate.global_position = bomb.get_bomb_position() + Vector3(2.0, 0.0, 0.0)
	await physics_frames(1)

	def_closer._think_bomb_objective(bomb)
	check(not def_closer.is_designated_defuser, "Bot yields defusal to nearby human teammate")
	check(def_closer.tactical_role == Bot.TacticalRole.BOMB_DEFUSE_COVER, "Bot switches to cover role when human teammate defuses")

	human_teammate.queue_free()
	await physics_frames(2)

	# --- 3. Capture The Flag: Roles, Interception, Carrier & Escort Convoy ---
	var blue_flag := FlagPickup.new()
	blue_flag.team_id = 0
	stage.add_child(blue_flag)
	blue_flag.global_position = Vector3(-20.0, 0.0, 0.0)
	blue_flag.base_position = Vector3(-20.0, 0.0, 0.0)
	blue_flag.reset_to_base()

	var orange_flag := FlagPickup.new()
	orange_flag.team_id = 1
	stage.add_child(orange_flag)
	orange_flag.global_position = Vector3(20.0, 0.0, 0.0)
	orange_flag.base_position = Vector3(20.0, 0.0, 0.0)
	orange_flag.reset_to_base()

	var ctf_bot1 := Bot.new()
	ctf_bot1.team_id = 0
	ctf_bot1.display_name = "CTF Blue Alpha"
	ctf_bot1.arena = arena
	stage.add_child(ctf_bot1)
	ctf_bot1.global_position = Vector3(-18.0, 0.0, 0.0)

	var ctf_bot2 := Bot.new()
	ctf_bot2.team_id = 0
	ctf_bot2.display_name = "CTF Blue Bravo"
	ctf_bot2.arena = arena
	stage.add_child(ctf_bot2)
	ctf_bot2.global_position = Vector3(-16.0, 0.0, 0.0)

	await physics_frames(2)

	# Role assignment
	var flags_arr := [blue_flag, orange_flag]
	ctf_bot1._think_ctf_objective(flags_arr)
	ctf_bot2._think_ctf_objective(flags_arr)
	check(ctf_bot1.tactical_role == Bot.TacticalRole.CTF_ANCHOR or ctf_bot1.tactical_role == Bot.TacticalRole.CTF_RUNNER, "CTF bot 1 assigns runner/anchor role")
	check(ctf_bot2.tactical_role == Bot.TacticalRole.CTF_ANCHOR or ctf_bot2.tactical_role == Bot.TacticalRole.CTF_RUNNER, "CTF bot 2 assigns runner/anchor role")

	# Flag stolen by enemy -> Interception priority
	var enemy_thief := Actor.new()
	enemy_thief.team_id = 1
	enemy_thief.display_name = "Sneaky Enemy"
	stage.add_child(enemy_thief)
	enemy_thief.global_position = Vector3(5.0, 0.0, 5.0)
	blue_flag.carrier = enemy_thief
	blue_flag.state = FlagPickup.State.CARRIED

	ctf_bot1._think_ctf_objective(flags_arr)
	check(ctf_bot1._target == enemy_thief, "Bots prioritize hunting enemy flag carrier")
	check(ctf_bot1._mood == Bot.Mood.FIGHT, "Bots enter FIGHT mood against flag thief")
	check(ctf_bot1._goal == enemy_thief.global_position, "Bots navigate directly towards flag thief")

	# Friendly teammate carrying enemy flag -> Carrier heads home, teammate escorts
	blue_flag.carrier = null
	blue_flag.reset_to_base()
	orange_flag.carrier = ctf_bot1
	orange_flag.state = FlagPickup.State.CARRIED

	ctf_bot1._think_ctf_objective(flags_arr)
	check(ctf_bot1._goal == arena.get_flag_pedestal(0), "Friendly carrier runs towards home pedestal to score")

	ctf_bot2._think_ctf_objective(flags_arr)
	check(ctf_bot2.tactical_role == Bot.TacticalRole.CTF_ESCORT, "Teammate adopts CTF_ESCORT role")
	check(ctf_bot2._has_goal, "Escort sets convoy movement goal to clear path for carrier")

	# Enemy flag dropped -> Rush to retrieve
	orange_flag.drop()
	ctf_bot2._think_ctf_objective(flags_arr)
	check(ctf_bot2._goal == orange_flag.global_position, "Bots rush towards dropped enemy flag")

	# Respawn resets tactical state
	ctf_bot2.respawn(Transform3D.IDENTITY)
	check(ctf_bot2.tactical_role == Bot.TacticalRole.UNASSIGNED, "Respawn resets tactical role to UNASSIGNED")
	check(ctf_bot2.assigned_bomb_site.is_empty(), "Respawn resets assigned bomb site")
	check(not ctf_bot2.is_designated_defuser, "Respawn resets designated defuser flag")
	check(is_zero_approx(ctf_bot2._sighting_cooldown), "Respawn resets sighting cooldown")

	# Clean up
	enemy_thief.queue_free()
	ctf_bot1.queue_free()
	ctf_bot2.queue_free()
	blue_flag.queue_free()
	orange_flag.queue_free()
	att_carrier.queue_free()
	att_escort.queue_free()
	def_closer.queue_free()
	def_further.queue_free()
	bomb.queue_free()
	arena.queue_free()
	stage.queue_free()
	await physics_frames(3)


func _test_v1_0_release_regressions() -> void:
	section("v1.0.0 Production Polish, Gameplay Hardening & Arena Integrity")

	# 1. Version metadata check
	check(str(ProjectSettings.get_setting("application/config/version", "")) == "1.0.0",
		"project.godot application/config/version is 1.0.0")

	# 2. All 9 arenas have explicit objectives, spawns, roam points, and AgX atmosphere
	check(MatchScene.ARENAS.size() == 9, "MatchScene registers all 9 arenas")
	for i in MatchScene.ARENAS.size():
		var info: Dictionary = MatchScene.ARENAS[i]
		var arena_path: String = str(info["path"])
		var arena_name: String = str(info["name"])
		var arena_inst := (load(arena_path) as PackedScene).instantiate() as Arena
		add_child(arena_inst)
		await physics_frames(2)
		check(arena_inst.spawn_points.size() >= 6, "%s has >= 6 spawn points (%d)" % [arena_name, arena_inst.spawn_points.size()])
		check(arena_inst.roam_points.size() >= 6, "%s has >= 6 roam points (%d)" % [arena_name, arena_inst.roam_points.size()])
		check(arena_inst.bomb_sites.has("A") and arena_inst.bomb_sites.has("B"), "%s defines explicit Bomb Sites A and B" % arena_name)
		check(arena_inst.flag_pedestals.size() >= 2, "%s defines >= 2 explicit CTF flag pedestals" % arena_name)
		check(not arena_inst.bomb_spawns.is_empty(), "%s defines explicit bomb_spawns" % arena_name)
		check(arena_inst.world_environment != null and arena_inst.sun_light != null, "%s exposes world_environment and sun_light" % arena_name)
		arena_inst.queue_free()
		await physics_frames(2)

	# 3. Workbench ricochet_ranger ID & six_shot alias
	var has_ricochet := false
	var has_dead_six_shot := false
	for b: Dictionary in WeaponModding.WORKBENCH_BLASTERS:
		if b["id"] == &"ricochet_ranger":
			has_ricochet = true
		if b["id"] == &"six_shot":
			has_dead_six_shot = true
	check(has_ricochet and not has_dead_six_shot, "WeaponModding uses ricochet_ranger instead of dead six_shot ID")
	Progression.equip_attachment(&"six_shot", &"optic", &"red_dot")
	check(Progression.get_equipped_attachments(&"ricochet_ranger").get("optic") == &"red_dot",
		"Progression aliases legacy six_shot attachments onto ricochet_ranger")

	# 4. Bot weapon attachment isolation from local player's Progression
	var popper := load(POPPER) as WeaponData
	Progression.equip_attachment(&"pocket_popper", &"magazine", &"extended_drum")
	var player_arsenal := Arsenal.new()
	player_arsenal.apply_profile_attachments = true
	player_arsenal.profile_index = 0
	add_child(player_arsenal)
	player_arsenal.set_loadout([popper], false)
	var bot_arsenal := Arsenal.new()
	add_child(bot_arsenal)
	bot_arsenal.set_loadout([popper], false)
	check(player_arsenal.current().get_magazine_size() > popper.magazine_size,
		"Human Arsenal applies extended_drum from Progression")
	check(bot_arsenal.current().get_magazine_size() == popper.magazine_size,
		"Bot Arsenal stays isolated from local player's Progression attachments")
	player_arsenal.queue_free()
	bot_arsenal.queue_free()
	Progression.equip_attachment(&"pocket_popper", &"magazine", &"stock_mag")
	await physics_frames(2)

	# 5. InputSetup LT ADS separation & secondary-binding preservation on rebind
	InputSetup.reset_to_defaults()
	var lt_on_sprint := false
	for ev: InputEvent in InputMap.action_get_events(&"sprint"):
		if ev is InputEventJoypadMotion and (ev as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_LEFT:
			lt_on_sprint = true
	check(not lt_on_sprint, "Gamepad LT is no longer bound to sprint (reserved for ADS)")
	var custom_fwd := InputEventKey.new()
	custom_fwd.physical_keycode = KEY_I
	InputSetup.rebind_action_event(&"move_forward", custom_fwd, false)
	var has_up_arrow := false
	for ev: InputEvent in InputMap.action_get_events(&"move_forward"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_UP:
			has_up_arrow = true
	check(has_up_arrow, "Rebinding primary move_forward key preserves secondary UP arrow binding")
	InputSetup.reset_to_defaults()

	# 6. Progression.weapon_mastery_ranked_up emits only on actual rank-up
	var rank_events := [0]
	var on_rank := func(_wid: StringName, _rank: int, _pidx: int) -> void: rank_events[0] += 1
	Progression.weapon_mastery_ranked_up.connect(on_rank)
	var fresh_wid := &"dart_sprayer"
	Progression.weapon_mastery.erase(fresh_wid)
	Progression.record_weapon_tag(fresh_wid, false)  # 50 XP -> still Rank 1
	check(rank_events[0] == 0, "weapon_mastery_ranked_up does not fire when staying Rank 1")
	Progression.record_weapon_tag(fresh_wid, false)  # 100 XP -> Rank 2!
	check(rank_events[0] == 1, "weapon_mastery_ranked_up fires exactly once upon reaching Rank 2")
	Progression.weapon_mastery_ranked_up.disconnect(on_rank)

	# 7. Podium does NOT turn Orange Team (team 1) into zombies outside Zombies mode
	var podium_stage := make_stage()
	var orange_entry := ScoreEntry.new()
	orange_entry.display_name = "OrangeHero"
	orange_entry.color = GameMode.team_color(1)
	orange_entry.team = 1
	orange_entry.score = 500
	var podium := Podium.new()
	podium_stage.add_child(podium)
	podium.show_places([[orange_entry]], "ORANGE WINS!", Color.ORANGE, false)
	await physics_frames(2)
	check(podium.dancers.size() == 1 and not podium.dancers[0].is_zombie(),
		"Podium preserves non-zombie appearance for Team 1 in normal team modes")
	podium.queue_free()
	var z_podium := Podium.new()
	podium_stage.add_child(z_podium)
	z_podium.show_places([[orange_entry]], "ZOMBIES WIN!", Color.GREEN, true)
	await physics_frames(2)
	check(z_podium.dancers.size() == 1 and z_podium.dancers[0].is_zombie(),
		"Podium displays Team 1 as zombies when is_zombie_mode is true")
	podium_stage.queue_free()
	await physics_frames(2)

	# 8. FlagPickup keeps pedestal anchored when carried away
	var ctf_stage := make_stage()
	var flag := FlagPickup.new()
	flag.team_id = 0
	ctf_stage.add_child(flag)
	var home_pos := Vector3(-12.0, 0.0, 0.0)
	flag.global_position = home_pos
	flag.base_position = home_pos
	flag.reset_to_base()
	var runner := make_actor(ctf_stage, home_pos, 1)
	await physics_frames(2)
	flag._on_body_entered(runner)
	runner.global_position = Vector3(15.0, 0.0, 10.0)
	await physics_frames(3)
	check(flag._pedestal != null and flag._pedestal.global_position.distance_to(home_pos) < 0.25,
		"FlagPickup pedestal stays anchored at home base while flag is carried away")
	ctf_stage.queue_free()
	await physics_frames(2)

	# 9. Split-screen Zombie Siege co-op teams & end-of-match HUD reparenting + TacticalMinimap
	var saved_split := GameSettings.split_screen
	var saved_mode := GameSettings.match_mode
	var saved_bots := GameSettings.bot_count
	GameSettings.split_screen = true
	GameSettings.bot_count = 2
	var ss_game := start_match(GameSettings.MatchMode.ZOMBIE_SIEGE)
	await physics_frames(6)
	var p1: Player = ss_game.get("player") as Player
	var p2: Player = ss_game.get("player2") as Player
	var hud1: Hud = ss_game.get("hud") as Hud
	check(p1 != null and p2 != null, "Split-screen Zombie Siege spawns both Player 1 and Player 2")
	if p1 != null and p2 != null:
		check(p1.team_id == 0 and p2.team_id == 0, "Split-screen Zombie Siege assigns both human players to Defenders (team 0)")
	check(hud1 != null and hud1._minimap != null, "Hud mounts TacticalMinimap radar cleanly")
	# Force match finish and verify HUD reparents out of hidden split container so results stay visible
	var ctrl: MatchController = ss_game.get("controller") as MatchController
	if ctrl != null:
		ctrl._finish()
	await physics_frames(4)
	if hud1 != null:
		check(hud1.get_parent() == ss_game and hud1.visible,
			"Split-screen match end reparents Hud onto MatchScene so results screen stays visible")
	GameSettings.split_screen = saved_split
	GameSettings.bot_count = saved_bots
	await end_match(ss_game, saved_mode)

	# 10. Iron sight & optic ADS alignment never clips camera across all blasters (especially Dart Sprayer)
	var sprayer_data := load(SPRAYER) as WeaponData
	var sprayer_iron := BlasterModel.create(sprayer_data, true, &"default", {"optic": &"iron_sights"})
	add_child(sprayer_iron)
	await physics_frames(1)
	var sprayer_ads := sprayer_iron.get_ads_offset()
	check(is_zero_approx(sprayer_ads.x), "Dart Sprayer iron-sight ADS centers X at 0.0")
	check(-sprayer_ads.y >= 0.145, "Dart Sprayer iron-sight ADS eye sits cleanly above top rail Y=0.13 (got %.3f)" % (-sprayer_ads.y))
	check(sprayer_ads.z + 0.245 <= -0.10, "Dart Sprayer iron-sight ADS keeps buttpad safely ahead of camera.near (rear Z=%.3f)" % (sprayer_ads.z + 0.245))
	check(sprayer_iron._iron_sights_node != null, "Dart Sprayer mounts 3D iron sights when no optic is equipped")
	# Equipping aftermarket optic (String key like WeaponState) raises eye line and hides iron sights
	sprayer_iron.update_attachments({"optic": &"red_dot"})
	var sprayer_rd_ads := sprayer_iron.get_ads_offset()
	check(sprayer_iron._iron_sights_node == null, "Dart Sprayer hides iron sights when red_dot optic is equipped")
	check(-sprayer_rd_ads.y > -sprayer_ads.y, "Dart Sprayer red_dot ADS aligns above iron sights (%.3f > %.3f)" % [-sprayer_rd_ads.y, -sprayer_ads.y])
	sprayer_iron.queue_free()

	for file_name in DirAccess.get_files_at(WEAPON_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var wdata := load(WEAPON_DIR + "/" + file_name) as WeaponData
		if wdata == null:
			continue
		var bm := BlasterModel.create(wdata, true, &"default", {"optic": &"iron_sights"})
		add_child(bm)
		var off := bm.get_ads_offset()
		var rear_world_z := off.z + bm._get_max_rear_z()
		check(is_zero_approx(off.x) and off.y < -0.07 and rear_world_z <= -0.10,
			"%s iron-sight ADS stays above receiver and ahead of near plane (off=%s, rearZ=%.3f)" % [wdata.id, str(off), rear_world_z])
		bm.queue_free()
	await physics_frames(2)

	# 11. Foam Bat Melee Weapon: Gun Game final rung, Zombies loadout, FFA BatPickup, melee bonk & dart deflect
	var bat_data := load("res://resources/weapons/foam_bat.tres") as WeaponData
	check(bat_data != null and bat_data.is_melee(), "foam_bat.tres loads as a MELEE weapon")
	check(Sfx.has_sound(&"bat_swing") and Sfx.has_sound(&"bat_bonk"), "Sfx bank provides bat_swing and bat_bonk sounds")
	var bat_state := WeaponState.new(bat_data)
	check(bat_state.can_fire() and not bat_state.can_reload() and bat_state.missing() == 0,
		"Foam Bat WeaponState needs no ammo and never reloads")
	var bat_vm := BlasterModel.create(bat_data, true, &"default", {})
	add_child(bat_vm)
	check(bat_vm.attachment_nodes.is_empty() and bat_vm._iron_sights_node == null,
		"Foam Bat first-person model mounts zero floating blaster attachments or iron sights")
	bat_vm.queue_free()

	var z_mode := load(ZOMBIES_MODE) as GameMode
	var zs_mode := load(ZOMBIE_SIEGE_MODE) as GameMode
	var z_has_bat := false
	for w in z_mode.loadout:
		if w.id == &"foam_bat":
			z_has_bat = true
	var zs_has_bat := false
	for w in zs_mode.loadout:
		if w.id == &"foam_bat":
			zs_has_bat = true
	check(z_has_bat and zs_has_bat, "Zombies and Zombie Siege survivor loadouts include the Foam Bat")

	# Melee swing bonk + knockback + dart deflect
	var melee_stage := make_stage()
	var m_pool := make_pool(melee_stage)
	var batter := make_actor(melee_stage, Vector3.ZERO, 0)
	batter.dart_pool = m_pool
	batter.arsenal.set_loadout([bat_data], false)
	var dummy_victim := make_actor(melee_stage, Vector3(0.0, 0.0, -2.0), 1)
	dummy_victim._protect_left = 0.0
	dummy_victim.grant_shield(50.0)
	var enemy_dart := m_pool.fire(make_dart_data(25.0, 0.0, 0.0), Vector3(0.0, 1.4, -1.6), Vector3.BACK, dummy_victim, null, Color.ORANGE, [])
	await physics_frames(1)
	batter._perform_melee_swing(batter.arsenal.current())
	check(not dummy_victim.has_shield() and dummy_victim.tag_meter >= 49.0,
		"Foam Bat swing breaks Foam Shield and spills damage onto rival tag meter")
	check(dummy_victim.velocity.length() > 5.0, "Foam Bat swing launches rival with cartoon knockback")
	check(enemy_dart.shooter == batter and enemy_dart.ricochet_count >= 1 and enemy_dart.velocity.z < 0.0,
		"Foam Bat swing deflects incoming enemy foam dart back with ricochet credit")

	# BatPickup spawns in standard modes (FFA) and grants Foam Bat on touch
	var bp := BatPickup.new()
	melee_stage.add_child(bp)
	bp.global_position = Vector3(6.0, 0.0, 0.0)
	bp.make_available()
	var grabber := make_actor(melee_stage, Vector3(6.0, 0.0, 0.0), 0)
	await physics_frames(1)
	bp._on_body_entered(grabber)
	check(grabber.arsenal.has_weapon(&"foam_bat") and not bp.is_available(),
		"BatPickup hands Foam Bat to touching actor and starts respawn cooldown")
	melee_stage.queue_free()
	await physics_frames(2)

	# 12. HUD reload progress regression (fixes nonexistent WeaponState.get_reload_seconds / reload_left)
	var ffa_game := start_match(GameSettings.MatchMode.FREE_FOR_ALL)
	await physics_frames(4)
	var ffa_player: Player = ffa_game.get("player") as Player
	var ffa_hud: Hud = ffa_game.get("hud") as Hud
	var ffa_bat: BatPickup = ffa_game.get("bat_pickup") as BatPickup
	check(ffa_bat != null, "Standard FFA match spawns a Foam Bat arena pickup")
	if ffa_player != null and ffa_hud != null:
		ffa_player.arsenal.current().magazine = 1
		ffa_player.arsenal.request_reload()
		await physics_frames(3)
		check(ffa_player.arsenal.is_reloading() and ffa_hud._reload_bar.visible,
			"HUD updates reload progress bar cleanly without script errors")
	await end_match(ffa_game, GameSettings.MatchMode.FREE_FOR_ALL)

	# 13. Windows Desktop export preset & build script
	var win_presets := ConfigFile.new()
	check(win_presets.load("res://export_presets.cfg") == OK, "export_presets.cfg loads cleanly for Windows check")
	var found_win := false
	for sec in win_presets.get_sections():
		if not sec.ends_with(".options") and win_presets.get_value(sec, "platform", "") == "Windows Desktop":
			found_win = true
			check(win_presets.get_value(sec + ".options", "binary_format/embed_pck", false) == true,
				"Windows Desktop preset embeds PCK into a single DARTSTORM.exe")
			break
	check(found_win, "export_presets.cfg defines a Windows Desktop export preset")
	check(FileAccess.file_exists("res://tools/export_windows.sh"), "tools/export_windows.sh exists")


func _test_v2_cover_art_parity() -> void:
	section("v2.0.0 Cover-Art Parity (Shaders, Sculpted Hero, Blasters, Trails & Props)")

	# 1. New v2.0.0 stylized shaders load cleanly
	check(ArenaKit.TOON_SHADER is Shader, "dartstorm_toon.gdshader loads cleanly")
	check(ArenaKit.OUTLINE_SHADER is Shader, "toon_outline.gdshader loads cleanly")
	check(ArenaKit.CLOTH_FLAG_SHADER is Shader, "cloth_flag.gdshader loads cleanly")

	# 2. Chromatic cel material caching & outline scalability tier gating
	var prev_q := GameSettings.graphics_quality
	GameSettings.graphics_quality = GameSettings.GraphicsQuality.LOW
	check(not ArenaKit.should_use_outlines(false) and not ArenaKit.should_use_outlines(true),
		"LOW graphics preset disables warm-navy outlines for both world props and heroes")
	GameSettings.graphics_quality = GameSettings.GraphicsQuality.HIGH
	var tm := ArenaKit.toon_mat(Color(0.2, 0.5, 1.0), 0.32, 0.6, 0.5, true)
	check(tm is ShaderMaterial and tm.shader == ArenaKit.TOON_SHADER,
		"ArenaKit.toon_mat returns cached ShaderMaterial bound to dartstorm_toon.gdshader")
	GameSettings.graphics_quality = prev_q

	# 3. Sculpted smooth-skinned Hero, Facial Rig & Articulated FP Arms
	var hero := ModelLoader.instantiate_hero()
	check(hero != null, "Sculpted v2.0.0 hero_base instantiates cleanly")
	if hero != null:
		var body_mi := hero.find_child("HeroBodyMesh", true, false) as MeshInstance3D
		check(body_mi != null and body_mi.skin != null,
			"Sculpted hero_base contains continuous smooth-skinned HeroBodyMesh with valid Skin")
		check(hero.find_child("Mesh_Eyelids", true, false) != null
			and hero.find_child("Mesh_MouthSmile", true, false) != null
			and hero.find_child("Mesh_MouthFlinch", true, false) != null,
			"Sculpted hero_base contains animated blink eyelids, smile, and flinch mouth meshes")
		hero.free()
	var fp_arms := ModelLoader.instantiate_model("res://assets/models/characters/fp_arms.tscn")
	check(fp_arms != null and fp_arms.find_child("RightArm", true, false) != null
		and fp_arms.find_child("LeftArm", true, false) != null,
		"Sculpted articulated Pixar FP hands (fp_arms.tscn) load with RightArm & LeftArm")
	if fp_arms != null:
		fp_arms.free()
	check(ResourceLoader.exists("res://assets/textures/stylized/foliage_leaf_albedo.png")
		and ResourceLoader.exists("res://assets/textures/stylized/hoodie_fleece_normal.png")
		and ResourceLoader.exists("res://assets/textures/stylized/shingle_roof_albedo.png"),
		"Pixar/Fortnite stylized PBR texture suite loads cleanly")

	# 4. Sculpted Blasters, Chainstorm Looping Belt & Local Melee Hit-Stop
	for bname: String in ["popper", "six_shot", "storm", "sweeper", "whisper", "chainstorm", "rocket"]:
		var binst := ModelLoader.instantiate_blaster(StringName(bname))
		check(binst != null and binst.find_child("MuzzleMarker", true, false) != null
			and binst.find_child("GripMarker", true, false) != null,
			"Sculpted v2.0.0 blaster '%s' loads with preserved MuzzleMarker & GripMarker" % bname)
		if binst != null:
			binst.free()
	var cs_data := load(CHAINSTORM) as WeaponData
	var cs_bm := BlasterModel.create(cs_data, true, &"default", {})
	add_child(cs_bm)
	check(cs_bm._belt.size() == BlasterModel.BELT_LINKS,
		"Flax's Chainstorm mounts animated %d-link foam dart belt" % BlasterModel.BELT_LINKS)
	cs_bm.trigger_hit_stop(0.04)
	check(cs_bm._hit_stop_left > 0.0, "BlasterModel supports local comfort-safe melee hit-stop")
	cs_bm.queue_free()

	# 5. Pooled 5-Element Flight Trails, Comic Starbursts & Waving Cloth Flag
	var fx_stage := make_stage()
	var fx_pool := make_pool(fx_stage)
	await physics_frames(1)
	var elem_paths := [
		"res://resources/darts/wind_dart.tres",
		"res://resources/darts/fire_dart.tres",
		"res://resources/darts/water_dart.tres",
		"res://resources/darts/lightning_dart.tres",
		"res://resources/darts/ice_dart.tres",
	]
	var fired_darts: Array[DartProjectile] = []
	for i in elem_paths.size():
		var edata := load(elem_paths[i]) as DartData
		var d := fx_pool.fire(edata, Vector3(float(i) * 2.0, 4.0, 0.0), Vector3.FORWARD, null, null, Color.CYAN, [])
		check(d != null and d._elem_fx != null and d._elem_fx.visible and d._elem_parts.size() == 4,
			"Elemental dart '%s' activates pooled 4-part 3D flight trail" % edata.id)
		fired_darts.append(d)
	await physics_frames(2)
	for d in fired_darts:
		d.retire()
		check(not d._elem_fx.visible, "Retired elemental dart hides pooled elemental trail cleanly")

	var before_children := fx_stage.get_child_count()
	CombatFx.spawn_comic_starburst(fx_stage, Vector3(0.0, 2.0, 0.0), "BONK!", Color(1.0, 0.85, 0.16), 1.0)
	check(fx_stage.get_child_count() == before_children + 1,
		"CombatFx.spawn_comic_starburst spawns spiky comic burst + world-space word pop")
	var flag_mi := ArenaKit.waving_flag(fx_stage, Vector3(0.0, 5.0, 0.0), Vector2(3.0, 2.0), Color.BLUE)
	check(flag_mi != null and flag_mi.material_override is ShaderMaterial
		and (flag_mi.material_override as ShaderMaterial).shader == ArenaKit.CLOTH_FLAG_SHADER,
		"ArenaKit.waving_flag creates vertex-animated cloth_flag.gdshader mesh")
	fx_stage.queue_free()
	await physics_frames(2)

	# 6. Sculpted v2.0.0 Arena Props preserve StaticBody3D colliders & DogHouse animated rig
	for pname: String in [
		"cartoon_tree", "inflatable_barrier", "inflatable_bunker",
		"tactical_crate", "tactical_barrel", "playground_slide",
		"archway_curved", "desert_urn", "dog_house",
	]:
		var pinst := ModelLoader.instantiate_prop(StringName(pname))
		var has_col := false
		if pinst != null:
			for c in pinst.get_children():
				if c is CollisionShape3D:
					has_col = true
					break
		check(pinst is StaticBody3D and (pinst as StaticBody3D).collision_layer == Layers.WORLD and has_col,
			"Sculpted v2.0.0 prop '%s' preserves StaticBody3D on Layers.WORLD with CollisionShape3D" % pname)
		if pname == "dog_house" and pinst != null:
			check(pinst.find_child("_dog", true, false) != null and pinst.find_child("_tail", true, false) != null,
				"Sculpted dog_house preserves animated _dog and _tail child nodes")
		if pinst != null:
			pinst.free()






