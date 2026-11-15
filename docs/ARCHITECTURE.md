# DARTSTORM — Architecture

*How the code fits together. Godot 4.4, GDScript, Forward+ renderer.*

## 1. Folder layout

```
project.godot           main scene, autoloads, physics layer names
scenes/                 thin .tscn wrappers (one root node + script)
  ui/main_menu.tscn     MAIN SCENE
  game/match.tscn       one round: arena + actors + HUD
  arenas/  player/  enemies/  projectiles/  pickups/  effects/  ui/
scripts/
  core/      settings, sfx, input, match flow, modes, scoring, UI kit, physics layers
  combat/    DartData, WeaponData, WeaponState, Arsenal, Actor, Hitbox, DartProjectile, DartPool
  ai/        Bot, BotDifficulty
  player/    Player
  arena/     Arena (base), ArenaKit (primitive builders), BackyardFortress
  systems/   WindField, WindZone, ReflectiveSurface, AmmoBucket, JumpPad, WobbleTarget
  effects/   BlasterModel, CharacterModel, FoamBurst, CombatFx
  ui/        Hud, Crosshair, WindGauge, PauseMenu, SettingsPanel, main_menu
  debug/     DemoDriver (only active with `-- --demo`)
resources/
  weapons/*.tres  darts/*.tres  modes/*.tres  bots/*.tres
assets/materials/lawn.gdshader
tests/test_runner.tscn  headless test suite (tests/test_runner.gd)
tools/
  validate.sh           import → strict compile → boots → tests → leak check
  run.sh                play / editor / demo
  check_scripts.gd      strict compile (every warning is an error)
  dart_table.gd         prints the GDD dart-flight table from the real dart code
docs/                   GDD, ARCHITECTURE, ROADMAP, DECISIONS, CONCEPT_BRIEF, UAT, TUNING
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
│  ├─ WindZone, JumpPad ×2, WobbleTarget ×6, WorldEnvironment, Sun
├─ DartPool                                owns and recycles every dart (cap 400)
├─ CombatFx                                turns impact/tag signals into particles and sound
├─ MatchController                         countdown, clock, scoring, respawns, end
├─ Player (Actor)  → Head → Camera → ViewModel(BlasterModel)
├─ Bot (Actor) ×N  → NavigationAgent3D, CharacterModel(BlasterModel)
├─ Hud (CanvasLayer)
└─ PauseMenu (CanvasLayer, PROCESS_MODE_ALWAYS)
```

## 3. Major systems and data ownership

| System | Owns | Talks via |
|---|---|---|
| **GameSettings** (autoload) | Preferences and last menu choices; saved to `user://settings.cfg` | `changed` signal; read directly |
| **Sfx** (autoload) | Procedurally synthesised sound bank, pooled 2D/3D voices, Chainstorm spin loop, **clean quitting** | `play(id)`, `play_at(id, pos)`, `set_spin(ratio)`, `quit_game(code)` |
| **PauseMenu** | Pause state, the settings panel in a match, **auto-pause on focus loss** | `open()`, `close()`, `pause_for_focus_loss()`, `is_open()` |
| **MatchController** | Match state, clock, Scoreboard, respawn timers | Signals: `countdown_tick`, `clock_tick`, `tag_scored`, `popup`, `match_ended` |
| **GameMode** (Resource) | The rules: duration, points, loadout. `GunGameMode` adds the ladder | Hooks: `get_loadout`, `apply_tag`, `get_early_winner`, `rank`, `describe_progress` |
| **Actor** | Movement, tag meter, alive state, Arsenal, Hitbox, dart launching | Signals: `tagged_out`, `landed_hit`, `meter_changed`, `respawned`, `ammo_collected` |
| **Arsenal** | Held WeaponStates, fire timing, spin-up, reloads | Signals: `fired`, `ammo_changed`, `weapon_changed`, `reload_*`, `dry_fired` |
| **DartPool / DartProjectile** | Every dart's flight, collision, ricochets, lifetime | Pool `impact(kind, at, normal, color)` signal; calls `Actor.receive_dart`, `on_dart_hit`, `on_dart_ricochet` |
| **WindField / WindZone** | Wind at any point in the arena | `get_wind_at(point)`; zones auto-register via the `wind_zones` group |
| **Arena** | Geometry, navmesh, spawns, roam points, buckets | Public arrays + `add_*` builder helpers |
| **Hud** | Purely presentational | Listens to Player, Arsenal, MatchController. Never mutates game state |

The dependency direction is **data → logic → presentation**. WeaponData/DartData never reference nodes.
The Arsenal never knows where darts go. Darts don't know about effects or scoring.
The HUD only listens.

## 4. Weapons: config, runtime, presentation (kept separate)

- **Configuration:** `WeaponData` (`.tres`): fire mode (SEMI / AUTO / SPIN_UP), rate, darts per shot,
  spread, spin-up time, move penalty, magazine (0 = belt-fed), reserve, reload, recoil/shake/sound,
  `model_style` and colours, and bot hints (`ai_min_range`, `ai_max_range`, `ai_preference`).
  `dart` points at a `DartData`.
- **Runtime:** `WeaponState` (ammo for one held blaster) and `Arsenal` (timing; emits `fired`).
  `Actor._on_arsenal_fired` turns each shot into `darts_per_shot` darts with spread.
- **Presentation:** `BlasterModel.create(data, first_person)` builds the mesh from `model_style`
  (PISTOL, SPRAYER, ROTARY, DOUBLE, HAMMER, RIFLE) and the colours. The same model is used in first person
  and in bots' hands.

**To add a blaster:** copy a `.tres` in `resources/weapons/`, give it a new `id`, tune it, then add it to a
mode's `loadout` or the Gun Game `ladder`. If it needs a new shape, add a `ModelStyle` and a `_build_*`
function in BlasterModel. For a new sound, add an entry in `Sfx._build_bank()`. The resource test
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

## 9. Extension points (future work)

- **New arena:** subclass `Arena`, override `_build()`, add a `.tscn`, and point `match.gd`'s `ARENA_SCENE`
  at it (an arena selector belongs on the menu when there are two). Elemental hazards should be their own
  scenes under `scripts/systems/`, and wind changes should go through `WindField.global_wind` or WindZone gusts.
- **Elemental darts:** `DartData.element` is already in the data. Add behaviour in `DartProjectile._on_hit`
  (an effect on the victim) and visuals in `CombatFx`.
- **Team modes:** `Actor.team_id` already gates friendly fire, so a team mode is a new `GameMode` subclass
  that assigns teams and sums the score per team.
- **Multiplayer (later):** the Actor brain is already split from the body (Player input vs Bot AI).
  A networked actor would be a third subclass fed by replicated input. MatchController and scoring are
  authoritative-server shaped (one place decides tags). Darts would be spawned by the server and simulated
  deterministically on clients. See DECISIONS D-008.
- **Capturable buckets:** add a `team_id` and capture progress to AmmoBucket, and have it refill only its owner's team.

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

## 11. Performance budgets

| Resource | Budget | Enforced by |
|---|---|---|
| Live darts | 400 (oldest recycled) | `DartPool.max_active` |
| Shots per actor per physics tick | 4 | `Arsenal.MAX_SHOTS_PER_TICK` |
| Ordinary foam bursts | 6 started per frame, 48 alive (× Visual effects) | `FoamBurst.MAX_PER_FRAME`, `MAX_LIVE` |
| Sound voices | 12 non-positional + 16 positional, same sound ≥ 22 ms apart | `Sfx` |
| Bot thinking | Every 0.25 s (+ jitter); steering and aiming every tick | `Bot.THINK_INTERVAL` |
| Wind-zone streak particles | 12–140 (× Visual effects) | `WindZone._build_visuals` |

Measured during the automated 3-bot Hard match: a peak of about 140 darts in the air, well under the cap.

## 12. Validation pipeline (`tools/validate.sh`)
1. **Import:** `godot --headless --import`. Fails on any import/parse/resource error.
2. **Strict compile:** `check_scripts.gd --print-strict-override` lists every warning currently at "Warn" and
   writes it at "Error" into a temporary `override.cfg` (removed by a trap). Then every `.gd` under `scripts/`,
   `tests/` and `tools/` is recompiled. Zero warnings is the bar.
3. **Boots:** the main menu (120 frames) and a match (300 frames), headless.
4. **Tests:** `tests/test_runner.tscn`, 130 checks in 19 sections. Includes a fast-forwarded bot match
   (8× ticks at 8× time scale, so each tick is still 1/60 s).
5. **Leak check:** the test run must exit without "ObjectDB instances leaked".
