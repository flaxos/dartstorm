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
tests/test_runner.tscn  headless test suite
tools/validate.sh  tools/run.sh
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
| **Sfx** (autoload) | Procedurally synthesised sound bank, pooled 2D/3D voices, Chainstorm spin loop | `play(id)`, `play_at(id, pos)`, `set_spin(ratio)` |
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
   collider RID for 0.08 s.
4. Otherwise the dart becomes *spent* (harmless and physical) and is recycled shortly after.

Darts are pooled. `DartPool.fire()` reuses idle darts, and at the cap (400) recycles the oldest live one.
Meshes and materials are shared statics, and materials are cached per colour.

## 6. Bots and navigation

`Arena._bake_navigation()` bakes a NavigationMesh at load time from the static colliders under `geometry`
(agent radius 0.5 m, climb 0.5 m, slope 40°). The map syncs on the NavigationServer a few frames later.
`Bot._path_direction` falls back to straight-line steering until it does.
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
