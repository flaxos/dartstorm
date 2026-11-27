# DARTSTORM — Architecture

*How the code fits together. Godot 4.4.1, typed GDScript, Forward+ desktop renderer with Compatibility fallback for Web & Android.*

## 1. Folder layout

```
project.godot           main scene, autoloads, physics layer names, branding icon & boot splash
default_bus_layout.tres audio buses: Master → Music, SFX
export_presets.cfg      Linux, Web, Android, Linux Server, Windows Desktop presets
scenes/                 thin .tscn wrappers (one root node + script)
  ui/main_menu.tscn     MAIN SCENE (3D bunker lobby + live 9-arena backdrop)
  game/match.tscn       one round: arena + actors + HUD (1P or 2P split-screen)
  server/server.tscn    headless dedicated server scene
  arenas/  player/  enemies/  projectiles/  pickups/  effects/  ui/
scripts/
  core/      settings, sfx (+ music), input, match flow & announcer, progression, weapon modding,
             model loader, 10 modes (solo, duos, teams, gun game, zombies, zombie siege,
             floor is lava, realistic, ctf, plant the bomb), scoring, awards, cosmetics, UI kit, layers
  combat/    DartData, WeaponData, WeaponState, Arsenal, Actor, Hitbox, DartProjectile, DartPool,
             ElementalEffect, FoamGrenade
  ai/        Bot, BotDifficulty
  player/    Player
  arena/     Arena (base: per-arena AgX lighting, sky, clouds, navmesh), ArenaKit (stylized builders
             & modular props), plus all 9 arenas: BackyardFortress, HomeTurf, TempestTreehouse,
             Playground, SunnyPark, SoccerField, TwoForts, DustCourtyard, Dust2;
             hazards: WaterPuddle, IceSlick, LavaHazard, ObsidianStone
  network/   NetworkManager, NetworkPlayer, LanDiscovery, DedicatedServer
  systems/   WindField, WindZone, ReflectiveSurface, AmmoBucket, JumpPad, WobbleTarget,
             PowerUpPickup, BatPickup, DogHouse, ShieldPickup, GrenadePickup, ElementalPickup,
             WindVent, BaseCore, BaseBarricade, HordeDirector, LavaDirector, WeatherDirector,
             WeatherEffects, WhirlwindVortex, PingBeacon, FlagPickup, BombTarget
  effects/   BlasterModel, BlasterAttachments, CharacterModel, FoamBurst, FoamSplat, CombatFx, Podium
  ui/        Hud, TacticalMinimap, Crosshair, WindGauge, PauseMenu, SettingsPanel, BindingsPanel,
             ShopPanel, MissionsPanel, GarageWorkbench, WorkbenchPanel, MultiplayerMenu,
             TouchControls, VirtualJoystick, main_menu
  debug/     DemoDriver (only active with `-- --demo`)
resources/
  weapons/*.tres (12)  darts/*.tres (12)  modes/*.tres (10)  bots/*.tres (3)
assets/
  branding/  boot_splash.png, icon_512.png, icon_192.png, icon_adaptive_*.png, dartstorm.ico
  materials/ 9 spatial shaders (blaster_skin, foam_dart, foam_shield, foam_splat, lava_foam,
             lawn, stylized_water, toon_character, toy_wood)
  models/    glTF 2.0 (.glb/.tscn) hero rig, 7 modular blasters, 13 arena dressing props
  textures/  skins/ (8 vector patterns), pbr/ (2K normal/ORM), arenas/ (triplanar PBR sets)
  fonts/     LilitaOne-Regular.ttf (+ OFL.txt)
tests/test_runner.tscn  headless test suite (tests/test_runner.gd — 1,544+ assertions)
tools/
  validate.sh           import → strict compile → boots → tests → leak check
  export_windows.sh     Windows 64-bit single-EXE + zip release
  export_linux.sh       Linux 64-bit release + headless smoke test
  export_apk.sh         Android ARM64 signed APK release
  export_web.sh         HTML5 / WebAssembly release
  export_server.sh      Linux headless dedicated server release
  export_all.sh         builds all 5 platforms + SHA256SUMS.txt into build/release-v<ver>/
  run.sh / run_server.sh / serve_web.py / serve_download.py
  check_scripts.gd      strict compile (every warning is an error)
  dart_table.gd         prints the GDD dart-flight table from real DartProjectile physics
  arena_shots.gd        overview screenshots of any arena
  generate_*.py / *.gd  procedural skin, PBR texture, hero, blaster & prop asset generators
docs/                   GDD, ARCHITECTURE, ROADMAP, DECISIONS, CONCEPT_BRIEF, UAT, TUNING, media/
```

## 2. Scene tree during a match

```
Match (scripts/core/match.gd)              wires everything, owns restart/quit
├─ BackyardFortress (Arena)
│  ├─ WindField                            sums global wind + registered WindZones
│  ├─ Geometry (NavigationRegion3D)        ALL solid pieces; navmesh baked at runtime
│  │   ├─ StaticBody3D …, ReflectiveSurface ×2, AmmoBucket ×5
│  ├─ Decor                                visual only (no collision, not in the navmesh)
│  ├─ Spawns (Marker3D …)
│  │   ├─ DogHouse, swing-set legs
│  ├─ WindZone, JumpPad ×2, WobbleTarget ×6, WorldEnvironment, Sun
│  └─ PowerUp (PowerUpPickup)              power-up mode only, on the treehouse deck
├─ DartPool                                owns and recycles every dart (cap 400)
├─ CombatFx                                turns impact/tag signals into particles and sound
├─ MatchController                         countdown, clock, scoring, respawns, end
├─ Player (Actor)  → Head → Camera → ViewModel(BlasterModel)
├─ Bot (Actor) ×N  → NavigationAgent3D, CharacterModel(BlasterModel)
├─ Hud (CanvasLayer)
├─ PauseMenu (CanvasLayer, PROCESS_MODE_ALWAYS)
└─ Podium (top_level, floats at y=150)     added when the match ends; owns its own camera
```

## 3. Major systems and data ownership

| System | Owns | Talks via |
|---|---|---|
| **GameSettings** (autoload) | Preferences, your look (name/colour/hat/skin), last menu choices, saved to `user://settings.cfg`. **Input-device awareness**: controller hot-plug, which device is in use, rumble, on-screen notices. Applies the default font to the root window's theme | `changed`, `controller_changed`, `input_device_changed` signals; `vibrate()`, `notify()` |
| **Sfx** (autoload) | Synthesised sound bank on pooled voices (SFX bus), Chainstorm spin loop, **two music loops rendered on worker threads** (Music bus), **clean quitting** | `play(id)`, `play_at(id, pos)`, `set_spin(ratio)`, `play_music(id)`, `stop_music()`, `duck_music()`, `quit_game(code)` |
| **Progression** (autoload) | Player lifetime XP, Level curve ($100 \times N$), gameplay Coins, 3 active Backyard Missions, cosmetic unlocks, Weapon Mastery XP & equipped workbench attachments (dual-profile), saved to `user://progression.cfg` | `xp_changed`, `leveled_up`, `coins_changed`, `mission_completed`, `weapon_mastery_ranked_up`; `add_xp()`, `add_coins()`, `unlock_item()`, `record_weapon_tag()`, `equip_attachment()` |
| **NetworkManager** (autoload) | WebSocket client/server transport, lobby roster sync, player transform/fire RPCs, LAN browser bridge | `server_started`, `connected_to_server`, `player_list_changed`, `lan_servers_updated` |
| **ModelLoader** (autoload) | Shared 3D `.glb` / `.tscn` asset cache for hero rig, 7 blasters, and 13 arena props with clean procedural fallback | `load_model(path)`, `instantiate_model(path)` |
| **LanDiscovery / DedicatedServer** | UDP port 8925 LAN beacon broadcast & discovery; headless CLI dedicated server with map rotation & bot fill | `servers_updated`; CLI flags `--port`, `--arena`, `--mode`, `--map-rotation`, `--bot-fill` |
| **BatPickup / FlagPickup / BombTarget** | Glowing Foam Bat arena pickup pad; CTF anchored pedestals & carry logic; Plant the Bomb Site A/B arming & defusal | `collected`, `flag_captured`, `bomb_planted`, `bomb_defused`, `bomb_detonated` |
| **LavaDirector / WeatherDirector** | Cyclic molten-foam Floor is Lava tides & obsidian cooling; dynamic Thunderstorm, Blizzard, Gale Gust & Heatwave events | `phase_changed`, `weather_changed`, `lightning_strike` |
| **GarageWorkbench / WeaponModding** | Enclosed 3D blaster customization studio, 5 attachment slots (optic, barrel, spring, magazine, stock), 19+ aftermarket mods & 10-rank mastery curve | `compute_attachment_modifiers()`, `get_mastery_rank()`, `update_attachments()` |
| **TacticalMinimap** | Rotating circular HUD radar rendering arena cover silhouettes, FOV cone, teammates, firing/nearby rivals, objectives & Foam Bat pickups | `configure(arena, controller, player)` |
| **PauseMenu** | Pause state, the settings panel in a match, **auto-pause on focus loss** | `open()`, `close()`, `pause_for_focus_loss()`, `is_open()` |
| **MatchController** | Match state, clock, Scoreboard, respawn timers, **announcer** (streaks, multi-tags, time warnings) and **award stats** | Signals: `countdown_tick`, `clock_tick`, `tag_scored`, `popup`, `announcement`, `match_ended`; `announce()` |
| **Cosmetics** (static data) | Player colours, hats, blaster skins, random names, name cleaning | `sanitize_name()`, `color_at()`, `skin_pattern()`, `skin_finish()` |
| **Awards** (static logic) | Turns ScoreEntry stats into end-of-match awards | `Awards.compute(ranked)` |
| **Podium** | The end-of-match sky stage, dancers, confetti, camera, match reward summary | `show_ranking(ranking)` |
| **PowerUpPickup** | Power-up mode: availability, countdown, handing over the blaster | `spawned`, `collected(actor)` signals; `active`, `make_available()`, `give_to()` |
| **ShieldPickup** | Holographic hexagonal bubble power-up absorbing 50 tag points | `picked_up` signal; `apply_shield()` |
| **WaterPuddle / IceSlick / WindVent** | Interactive arena environmental hazards (conductive puddle, frictionless slide-boost, upward buoyant launch & elemental amplifier) | Area3D signals; elemental reactions on contact |
| **BaseCore** | 1000 HP physical base objective with pulsating rings, rotating 3D HP billboard, sirens (< 350 HP), repair API | `damaged`, `repaired`, `destroyed` signals; `damage()`, `repair()` |
| **BaseBarricade** | 250 HP destructible choke barriers, solid collision disabling when broken, rebuild API | `damaged`, `broken`, `repaired` signals; `damage()`, `rebuild()` |
| **HordeDirector** | 5-wave horde escalation, perimeter batch spawns, 20s intermission fortification, scrap economy, victory triggers | `wave_started`, `wave_cleared`, `intermission_tick`, `scrap_changed`, `all_waves_cleared`, `defeat` signals |
| **DogHouse** | Solid prop; barks when a dart hits it | `barked` signal; `on_dart_hit()` |
| **GameMode** (Resource) | The rules: duration, points, loadout. Subclasses: `GunGameMode`, `ZombieMode`, `ZombieSiegeMode` | Hooks: `get_loadout`, `apply_tag`, `get_early_winner`, `rank`, `describe_progress`, `should_respawn` |
| **Actor** | Movement, tag meter, alive state, Arsenal, Hitbox, dart launching | Signals: `tagged_out`, `landed_hit`, `meter_changed`, `respawned`, `ammo_collected` |
| **ElementalEffect** | Afflictions (Wind lift, Fire sparkle, Water wet/knockback, Lightning chain zap, Ice slow/slide), reactions & combos | Signals: `status_started`, `status_ended`, `combo_triggered`, `chain_zapped` |
| **Arsenal** | Held WeaponStates, fire timing, spin-up, reloads | Signals: `fired`, `ammo_changed`, `weapon_changed`, `reload_*`, `dry_fired` |
| **DartPool / DartProjectile** | Every dart's flight, collision, ricochets, lifetime, elemental payload | Pool `impact` and `elemental_impact` signals; calls `Actor.receive_dart`, `on_dart_hit`, `on_dart_ricochet` |
| **WindField / WindZone** | Wind at any point in the arena | `get_wind_at(point)`; zones auto-register via the `wind_zones` group |
| **Arena** | Geometry, navmesh, spawns, roam points, buckets | Public arrays + `add_*` builder helpers |
| **Hud** | Purely presentational: HUD, announcer queue, results panel, Base Core HP bar, Wave badge, Intermission timer, live scrap counter | Listens to Player, Arsenal, MatchController, HordeDirector, BaseCore. Never mutates game state |

The dependency direction is **data → logic → presentation**. WeaponData/DartData never reference nodes.
The Arsenal never knows where darts go. Darts don't know about effects or scoring.
The HUD only listens.

## 4. Weapons: config, runtime, presentation (kept separate)

- **Configuration:** `WeaponData` (`.tres`): fire mode (`SEMI` / `AUTO` / `SPIN_UP` / `MELEE`), rate, darts per shot,
  spread, spin-up time, firing & hold move multipliers, melee cone/range/knockback exports, magazine (`0` = belt-fed
  or melee), reserve, reload, recoil/shake/sound, `model_style` and colours, and bot hints (`ai_min_range`,
  `ai_max_range`, `ai_preference`). `dart` points at a `DartData`.
- **Runtime:** `WeaponState` (ammo & active `WeaponModding` attachment modifiers for one held weapon) and `Arsenal`
  (fire cadence, melee swing timing, spin-up, reloads; emits `fired`). `Actor._on_arsenal_fired` turns ranged shots
  into `darts_per_shot` physical darts, and melee swings into `_perform_melee_swing()` (cone bonk, shield break,
  knockback, `WobbleTarget` hit, and `DartProjectile.deflect()` / `FoamGrenade` baseball deflect).
- **Presentation:** `BlasterModel.create(data, first_person, skin_id, attachments)` loads stylized `.glb` assets via
  `ModelLoader` (with procedural fallback) or builds custom styles (`PISTOL`, `SPRAYER`, `ROTARY`, `DOUBLE`, `HAMMER`,
  `RIFLE`, `BAT`), mounts 3D flip-up iron sights or aftermarket attachments from `BlasterAttachments` (skipped cleanly
  on melee weapons), and drives recoil, starburst muzzle flash, and diagonal bat swings.

**To add a blaster:** copy a `.tres` in `resources/weapons/`, give it a new `id`, tune it, then add it to a
mode's `loadout` or the Gun Game `ladder`. If it needs a new shape, add a `ModelStyle` and a `_build_*`
function in `BlasterModel`. For a new sound, add an entry in `Sfx._build_bank()`. The resource test
checks every weapon's sound exists.

## 5. Dart physics

`DartProjectile._physics_process`: gravity × `gravity_multiplier` plus `WindField.get_wind_at() × wind_response`,
then drag, then one `intersect_ray` from the current to the next position with mask `DART_MASK`
(world, targets and hitbox Areas), excluding the shooter. On a hit:

1. `Hitbox` (Area3D around an Actor) calls `actor.receive_dart(dart)` if `accepts_dart_from(team)`;
   otherwise the dart passes through.
2. Anything with `on_dart_hit()` (WobbleTarget) is notified.
3. A surface in the `reflective` group (or any surface for `ricochet_any_surface`) reflects the velocity
   with `velocity.bounce(normal)`, scales the speed, increments `ricochet_count`, and excludes that
   collider RID for 0.08 s. Each bounced surface has its own timer (`_ricochet_ignore`: RID → seconds),
   so quick back-to-back bounces between close mirrors each expire independently (v0.1.1).
4. Otherwise the dart becomes *spent* (harmless and physical) and is recycled shortly after.

Darts are pooled. `DartPool.fire()` reuses idle darts, and at the cap (400) recycles the oldest live one.
Meshes and materials are shared statics, and materials are cached per colour. The pool loads
`dart_projectile.tscn` at runtime rather than `preload`ing it, because `dart_projectile.gd` refers back to
`DartPool`, and a preload made a load cycle when the editor re-imported (D-018).

## 6. Bots and navigation

`Arena._bake_navigation()` bakes a NavigationMesh from the static colliders under `geometry`
(agent radius 0.5 m, climb 0.5 m, slope 40°). Since v0.1.1 the bake runs **on a worker thread**
(`bake_navigation_mesh(true)`). When it finishes, `Arena.is_navigation_ready` becomes true and `navigation_ready`
is emitted; the NavigationServer map then syncs a frame or two later. Until both have happened,
`Bot._path_direction` steers straight at its goal. In practice the bake and sync take about 20 frames (a third of a second), well inside the 3 s countdown.
A bot "thinks" every 0.25 s (choose target, choose mood, choose weapon) and steers, aims and fires every physics tick.
Line-of-sight is a world-only ray. Aim leads the target and adds a gravity drop compensation.

## 7. Match flow

`match.gd` reads `GameSettings.match_mode / bot_count / bot_difficulty`, loads the mode and difficulty
`.tres`, builds the arena, pool, FX, controller, player, bots, HUD and pause menu, and calls `controller.begin()`.
`MatchController`: WAITING → COUNTDOWN (actors frozen) → PLAYING (clock runs, respawn timers tick) → ENDED
(everyone frozen, `match_ended(ranking)`). On `tagged_out`, it schedules a respawn, updates the Scoreboard,
asks the mode for points, emits popups, and (in Gun Game) re-equips the attacker on promotion.
Restart reloads `match.tscn`.

## 8. Physics layers (`scripts/core/layers.gd`)

| Bit | Name | Used by |
|---|---|---|
| 1 | world | All static arena geometry, mirrors, bucket bodies, invisible fence-top walls |
| 2 | actors | Player and bot CharacterBody3D |
| 3 | targets | WobbleTarget |
| 4 | pickups | Reserved |
| 5 | hitboxes | Generous dart hit volumes (Area3D) on actors |

## 9. Extension points

- **New arena:** subclass `Arena`, override `_build()`, add a `.tscn`, configure a lighting preset, set `team_bases`, `bomb_sites`, `flag_pedestals`, and `bomb_spawns`, and register it in `MatchScene.ARENAS` (currently 9 arenas).
- **Elemental darts & combos:** `DartData.element` drives physical traits, projectile tints, and victim afflictions via `ElementalEffect` (Wind lift, Fire sparkle tick, Water knockback/wet, Lightning chain zap, Ice slow & slide boosting, plus steam/shock combos).
- **New game mode:** subclass `GameMode` (10 modes shipped: Solo, Gun Game, Duos, Teams, Zombies, Zombie Siege, Floor is Lava, Realistic, CTF, Plant the Bomb), add a `.tres` under `resources/modes/`, and wire it into `GameSettings.MatchMode` and `MatchScene`.
- **Multiplayer & Dedicated Servers (shipped):** `NetworkManager`, `NetworkPlayer`, `LanDiscovery` (UDP 8925), and `DedicatedServer` (`scenes/server/server.tscn`) implement WebSocket LAN/online play, auto-discovery, bot backfill, and CLI map rotation.
- **Local Couch Co-Op (shipped):** Dual `SubViewport`s sharing a single `World3D` with layer-culled 3D character bodies and isolated `p1_*` / `p2_*` input maps.

## 10. Failure modes and safeguards (v0.1.1)

| What can go wrong | Safeguard | Where | Test |
|---|---|---|---|
| A mode or bot-skill `.tres` is missing or corrupt | `MatchScene.load_or_fallback()` falls back to Free-for-all / Normal (warning); `resolve_*` never returns null | `scripts/core/match.gd` | *broken data never crashes a match* |
| The arena scene can't load | `push_error` and return to the main menu | `match.gd` | — |
| Out-of-range menu indexes or garbled settings | Clamped on load and on use | `game_settings.gd`, `match.gd` | *broken data…* |
| Someone is tagged out outside PLAYING (countdown fall) | Respawn is always scheduled unless ENDED; nothing is scored | `match_controller.gd` | *tagged-out actors always respawn* |
| A dart bounces between two close mirrors | Per-surface ricochet ignore timers | `dart_projectile.gd` | *back-to-back ricochets* |
| A bot holds an empty blaster, or every bucket is empty | Instant swap to a loaded blaster; dry bots wait at the nearest bucket | `bot.gd` | *bots never get stuck without darts* |
| Window loses focus mid-match | Auto-pause; the click that re-captures the mouse never fires | `pause_menu.gd`, `player.gd` | *losing window focus pauses the match* |
| Navmesh bake stalls the load | Background bake; bots steer straight until ready | `arena.gd`, `bot.gd` | *Backyard Fortress navigation* |
| Particle flood from mass fire | FoamBurst per-frame and live caps (important bursts exempt) | `foam_burst.gd` | *effects budget* |
| Quitting while sounds play leaks objects | Every quit goes through `Sfx.quit_game()`: stop all, wait 0.4 s real time (the headless audio driver needs a couple of ~46 ms mixing passes to free stopped sounds), quit. Re-entrant calls are ignored; the window close button is routed there too (`auto_accept_quit = false`) | `sfx.gd` | validate.sh fails on "leaked at exit" |
| Script warnings creep in | Strict compile step: every warning that's at "Warn" is raised to "Error" via a temporary `override.cfg` | `tools/check_scripts.gd`, `tools/validate.sh` | validate step |
| Load cycle between scripts and scenes | No `preload` of a scene whose script refers back to the preloader (D-018) | `dart_pool.gd` | import step |
| A fresh checkout imports before the font is imported | The default font is applied at runtime through the root window theme, not `project.godot` (D-020) | `game_settings.gd` | import step |
| Quitting while a music loop is still rendering | `quit_game()` and `_exit_tree()` wait for every render task | `sfx.gd` | leak check |
| Controller unplugged mid-match | Pause, with a notice | `game_settings.gd`, `pause_menu.gd` | *Controller: plug and play* |
| A per-match rule (power-up mode) leaking into the shared `.tres` | The match works on `mode.duplicate()` | `match.gd` | *Chainstorm power-up mode* |

## 11. Performance budgets

| Resource | Budget | Enforced by |
|---|---|---|
| Live darts | 400 (oldest recycled) | `DartPool.max_active` |
| Shots per actor per physics tick | 4 | `Arsenal.MAX_SHOTS_PER_TICK` |
| Ordinary foam bursts | 6 started per frame, 48 alive (× Visual effects) | `FoamBurst.MAX_PER_FRAME`, `MAX_LIVE` |
| Sound voices | 12 non-positional + 16 positional, same sound ≥ 22 ms apart | `Sfx` |
| Bot thinking | Every 0.25 s (+ jitter); steering and aiming every tick | `Bot.THINK_INTERVAL` |
| Wind-zone streak particles | 12–140 (× Visual effects) | `WindZone._build_visuals` |
| Music | Two loops (≈9 s and ≈14 s, 22 kHz mono) rendered once at startup on worker threads | `Sfx._start_music_job` |
| Podium confetti / sprinkler | 20–220 / 10–90 particles (× Visual effects) | `Podium`, `BackyardFortress` |

Measured during the automated 3-bot Hard match: a peak of about 140 darts in the air, well under the cap.

## 12. Validation pipeline (`tools/validate.sh`)
1. **Import:** `godot --headless --import`. Fails on any import/parse/resource error.
2. **Strict compile:** `check_scripts.gd --print-strict-override` lists every warning currently at "Warn" and
   writes it at "Error" into a temporary `override.cfg` (removed by a trap). Then every `.gd` under `scripts/`,
   `tests/` and `tools/` (106 scripts) is recompiled. Zero warnings is the bar.
3. **Boots:** the main menu (120 frames) and a match (300 frames), headless.
4. **Tests:** `tests/test_runner.tscn`, **1,544+ checks across 70 sections**. Includes fast-forwarded bot matches
   (8× ticks at 8× time scale, so each tick is still 1/60 s), all 9 arenas, all 10 modes, split-screen, LAN/server,
   workbench modding, Foam Bat melee/deflect, ADS iron sights, and export preset checks.
5. **Leak check:** the test run must exit without "ObjectDB instances leaked".

## 13. Input and controllers (v0.2.0)
- **Bindings** are registered in `InputSetup.ensure_actions()` with device -1 (any pad), so hot-plugged pads work at
  once. Godot's `ui_accept` / `ui_cancel` get A / B added, which makes every menu pad-driven.
- **Which device is in use:** `GameSettings._input` flips `using_controller` on pad or keyboard/mouse activity and emits
  `input_device_changed` (the main menu's help text listens).
- **Hot-plug:** `Input.joy_connection_changed` → `GameSettings` shows a notice and emits `controller_changed`. The
  PauseMenu pauses on a disconnect during play.
- **Aiming:** `Player.pad_look_step()` curves the right stick (stick²) and, with aim assist on, halves the turn speed
  while `crosshair_on_rival()` (a ray against hitboxes) is true. It never rotates the view by itself.
- **Rumble:** `GameSettings.vibrate()` only fires when rumble is on and a pad is the active device.
- **"Back":** SettingsPanel, the lobby's CHARACTER and HOW TO PLAY panels and PauseMenu all close on `ui_cancel` (B / Esc).

## 14. Music
`Sfx` describes each loop as a small style dictionary (tempo, chord list, bass pattern, drum steps, melody as MIDI notes)
and renders it with `WorkerThreadPool` into a looping `AudioStreamWAV`. Notes that run past the end wrap to the start,
so the loop is seamless. `_process` picks up finished renders on the main thread. `play_music()` before a loop is ready
just remembers the request. Crossfades and pause-ducking are tweens on the Music player.

## 15. Teams (v0.3.0)
Teams are data on the mode, not a separate code path:
- `GameMode.teams` (SOLO, DUOS, BLUE_VS_ORANGE). `team_for(index)` gives each player's team (the human is index 0, so
  always team 0, which is blue). In SOLO everyone gets their own number, so all the team code below also works there.
- `MatchScene` asks `team_bot_count()` (the menu's number, plus one to even the teams, capped by the 7-bot roster), sets
  `Actor.team_id`, and in team modes overrides `Actor.color` with `GameMode.team_color()`.
- **No friendly fire** comes from code that was already there: `Actor.accepts_dart_from(team)` makes darts pass
  through team-mates, bots skip team-mates in `_pick_target`, and aim assist uses the same check.
- `ScoreEntry.team` copies the actor's team. `GameMode.rank_teams()` sums scores per team; `rank()` lists the best
  team's players first; `winning_team()` returns -1 for a draw; `podium_places()` gives the Podium one group per step.
- `MatchController.is_home_spawn()` keeps TEAMS respawns at the team's end (`Arena.team_bases`: blue, then orange).
  `_announce_team_lead()` calls lead changes.
- `Hud` builds the team chips, the grouped scoreboard and `result_title()`. `Podium.show_places()` widens steps
  to fit a team and pulls the camera back for wide stages.

## 16. Lobby (v0.3.0)
`scripts/ui/main_menu.gd` builds the young players' layout (GDD §3.22). The 3D part is a floating island at
`STAGE` (just south of the yard, so the Backyard Fortress, loaded without a navmesh, is the backdrop) with
depth-of-field far blur on the camera. Name tags use `ALPHA_CUT_OPAQUE_PREPASS` so they write depth and aren't
blurred. The squad is rebuilt whenever the mode or bot count changes, using the same `MatchScene.team_bot_count()` and
`bot_colors()` as the match, so the lobby always shows exactly who you'll play with. Each squad member lives under one
"slot" node so CHARACTER can hide everyone but you, and the camera tweens to a close-up.

## 17. Arenas (v0.4.0)
`MatchScene.ARENAS` lists the playable arenas (name for the lobby, scene path); `GameSettings.arena` picks one.
An arena is a script extending `Arena` that builds itself in `_build()`: call `_build_sky_and_sun(sun_pitch, warm_fill)`,
put everything solid under `geometry` (so the navmesh sees it), looks under `decor`, and use the `add_*` helpers for
spawns, buckets, mirrors, wind zones, targets and the power-up spot. Set `team_bases` (blue, then orange) for TEAMS.
To add one: write the script and a thin `.tscn`, add it to `ARENAS`, and copy the *Home Turf* tests (spawns clear,
every roam point reachable, a bot match). Check the layout with `tools/arena_shots.gd`.

## 18. Zombie Siege & Base Defense (v0.7.0)
Base defense is orchestrated by `HordeDirector` alongside `ZombieSiegeMode`:
- Defenders belong to Team 0 (`SURVIVORS`) and respawn on tag-out; zombies belong to Team 1 (`ZOMBIES`) and do not respawn when tagged.
- Physical `BaseCore` (1000 HP) and 4 `BaseBarricade`s (250 HP) reside directly under `arena.geometry` to integrate with navmesh pathfinding.
- Zombies evaluate threat targets: prioritizing melee strikes on barricades and the core, but switching dynamically to swarm defenders within 6m.
- Tagged zombies drop Scrap (+15 standard, +25 runner, +40 brute, +100 boss).
- Wave progression: 5 waves escalating to the Wave 5 Mega Titan Boss (650 HP, 1.85x scale).
- 20s Intermissions between waves replenish all ammo buckets and enable core repair (+250 HP for 100 scrap) and barricade rebuilds (75 scrap).

## 19. Anti-Slop Generative Blaster Skin Pipeline (v0.7.0)
To avoid noisy, washed-out diffusion art with baked lighting ("AI slop"), DARTSTORM uses a clean vector + shader architecture:
- Generative 2D vector graphic patterns only: unlit, seamless, black-and-white 1024x1024 patterns in `assets/textures/skins/` generated by `tools/generate_skins.py`.
- `blaster_skin.gdshader`: Spatial PBR tri-planar projection with object-space coordinates and a sharp blend power ($P^{12}$), preventing seam distortion and UV pinching on CSG blaster geometry.
- Dynamic Forward+ PBR lighting: real-time Fresnel rim glow, roughness, metallic, and specular reflection.
- 4 tactile finishes: `MATTE` (0.55 roughness), `GLOSS` (0.18 roughness + clearcoat), `METALLIC_FLAKE` (0.75 metallic + micro-sparkle shimmer), and `HOLOGRAPHIC_IRIDESCENT` (view-dependent prismatic rainbow rim).
- Strict zoning: preserves toy safety orange muzzle tips (`Color(1.0, 0.45, 0.05)`) and dark tactical rubber grips (`Color(0.13, 0.16, 0.24)`).

