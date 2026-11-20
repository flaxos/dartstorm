# DARTSTORM — Roadmap

*Updated: 2026-11-16. Every milestone must end with a playable, validated build. Releases also need a UAT pass
([UAT.md](UAT.md)).*

## Status at a glance

| Milestone | State |
|---|---|
| Phase 0 Bootstrap | ✅ Done |
| Phase 1 Movement and arena | ✅ Done |
| Phase 2 Dart physics | ✅ Done |
| Phase 3 Weapons | ✅ Done (3 required + 4 Gun Game extras) |
| Phase 4 Combat, bots, match | ✅ Done |
| Phase 5 Game feel | ✅ First pass done, **UAT passed** |
| Phase 6 Gun Game | ✅ Playable with a 7-rung ladder (3 planned rungs not built) |
| **v0.1.0 release** | ✅ Merged (PR #1), **UAT passed 2026-11-15** |
| **v0.1.1 hardening + docs** | ✅ Merged (PR #2) |
| **v0.2.0 controller + appeal pack** | ✅ Built and validated. PR #3. ⏳ UAT with young players and a real controller |
| **v0.3.0 the players' design: lobby, team modes, Linux build** | ✅ Built and validated. PR #5 to main. ⏳ UAT |
| **v0.4.0 Home Turf arena** | ✅ Built and validated (276 tests). ⏳ UAT |
| **v0.5.0 Elemental Arena & AAA Game Feel** | ✅ Built and validated (309 tests). ⏳ UAT |
| **v0.5.1 Zombies Mode** | ✅ Built and validated (338 tests). ⏳ UAT |
| **v0.5.2 Foam Shield & Environmental Hazards** | ✅ Built and validated (359 tests). ⏳ UAT |
| **v0.5.3 Progression, Levels, Missions & Coin Shop** | ✅ Built and validated (398 tests). ⏳ UAT |
| **v0.6.0 Tempest Treehouse Arena** | ✅ Built and validated (423 tests). ⏳ UAT |
| **v0.7.0 Zombie Siege & Blaster Skins** | ✅ Built and validated (518 tests). ⏳ UAT |
| **v0.7.1 Kid Feedback Calibration & Sniper Buff** | ✅ Merged (PR #13, 530 tests). ⏳ UAT |
| **v0.8.0 Floor is Lava Mode** | ✅ Built and validated (557 tests). ⏳ UAT |
| **v0.8.1 Foam Grenades & Elemental Infusion** | ✅ Built and validated (595 tests). ⏳ UAT |
| **v0.9.0 Elemental Weather & Dynamic Disasters** | ✅ Built and validated (616 tests). ⏳ UAT |
| **v0.9.1 DUOS Buddy Spawning & Squad Pings** | ✅ Built and validated (638 tests). ⏳ UAT |
| **v0.9.2 Settings & Accessibility** | ✅ Built and validated (669 tests). ⏳ UAT |
| **v1.0.0 Local Couch Co-Op / Split-Screen (2 Players)** | ✅ Built and validated (706 tests). ⏳ UAT |
| **v1.1.0 Web & Android Mobile Universal Accessibility** | ✅ Built and validated (741 tests). ⏳ UAT |
| **v1.2.0 Environment & Lighting Uplift & Splat Decals** | ✅ Built and validated (776 tests). ⏳ UAT |
| Phase 7 Expansion | ⏳ Not started (on purpose) |

## v1.2.0: Environment & Lighting Uplift (Tactile PBR Shaders, Splat Decals, Golden-Hour Sun & Atmospheric Glow) (this release)

Goal: Elevate arena visuals to tactile, vibrant cartoon quality with procedural backyard timber and lawn shaders, Splatoon-style popping foam dart splat decals, golden-hour sunlight with soft contact shadows, filmic color grading, and bloom.

- [x] **Tactile PBR Surface Shaders (`ArenaKit.SurfaceType`):**
  - Procedural backyard timber plank shader (`toy_wood.gdshader`) with board striations, micro-bevel seams, and warm satin finish.
  - Upgraded lawn grass shader (`lawn.gdshader`) with soft mower stripes, tuft noise, and velvet rim Fresnel sheen.
  - Molded toy plastic PBR surfaces with subtle gloss, specular highlights, and edge sheen (`roughness = 0.32`, `rim = 0.42`).
  - Brushed toy metal surfaces (`metallic = 0.85`, `roughness = 0.24`).
  - Applied tactile surface types across Backyard Fortress, Home Turf, and Tempest Treehouse geometry.
- [x] **Cartoon Foam Splat Decals (`FoamSplat` & `foam_splat.gdshader`):**
  - High-impact cartoon splatter decal with central puddle blob, 5 radiating satellite droplets, and white specular highlight.
  - QuadMesh normal-oriented placement at `point + normal * 0.015` facing outward, eliminating Z-fighting across desktop, WebGL2, and mobile.
  - Organic spring pop-in spawn animation (`scale` pops to 1.12x before settling).
  - Foam bubble fizz-out dissolve decay at end of lifetime or under memory pressure.
  - Strict FIFO ring-buffer memory cap (`MAX_ALIVE = 48`, scaled by `visual_intensity`) ensuring 0 memory leaks and zero performance degradation during intense firefights.
  - Integrated into `CombatFx` on `DartProjectile.Impact.WORLD` and `DartProjectile.Impact.TARGET`.
- [x] **Golden-Hour Atmospheric Lighting & Post-Processing (`Arena._build_sky_and_sun`):**
  - Rich procedural sky gradient (deep zenith azure `#3370e0`, warm apricot horizon `#dcbca0`, warm earth tones).
  - Filmic tone mapping (`Environment.TONE_MAPPER_FILMIC`) with +16% saturation and 1.06 contrast boost.
  - Warm directional sunlight (`light_color = #ffeed1`, `energy = 1.35`) with soft contact shadows (`shadow_bias = 0.02`, `shadow_normal_bias = 1.2`, `blend_splits = true`).
  - Soft glow bloom (`intensity = 0.45`, `bloom = 0.10`) for shields, energy hazards, and elemental power-ups.
  - Volumetric atmospheric sunbeams and fog for Forward+ / Mobile Vulkan renderers (guarded for Web compatibility).
- [x] **Test Isolation & Automated Test Suite:**
  - Added `_test_environment_and_splat_decals()` in `tests/test_runner.gd` verifying shader generation, surface caching, lighting adjustments, splat lifecycle, and FIFO budget capping.
  - Hardened test runner with pristine defaults initialization ensuring test isolation from local disk settings.
  - All 776 automated tests pass with 0 errors, 0 warnings, and 0 memory leaks.

**Acceptance:** `./tools/validate.sh` passes (**776/776 tests**), `./tools/export_web.sh` compiles cleanly, and local web server is live ✅.

## v1.1.0: Web Browser (Mobile & Desktop) & Android APK Universal Accessibility

Goal: Full universal accessibility across desktop web browsers, mobile web browsers (Chrome, Safari, Firefox), and Android devices via signed APK, with on-screen mobile touch controls, WebGL2/GLES3 compatibility rendering, and automated export pipelines.

- [x] **Mobile Touch Controls Architecture (`TouchControls` & `VirtualJoystick`):**
  - Left-thumb `VirtualJoystick` with smooth 360-degree analog output, deadzone filtering (0.12), and analog action synthesis (`move_left`, `move_right`, `move_forward`, `move_back`).
  - Right-screen swipe look zone feeding into `player.look_relative(delta)` with zoom compensation.
  - Large arcade action touch buttons: `FIRE`, `JUMP`, `RUN` (sprint), `AIM` (ADS), `RELOAD`, `BOMB` (grenade), `SWAP` (weapon cycle), and `||` (`PAUSE` in top-right corner).
  - Multitouch support with independent touch index tracking for concurrent moving, aiming, and firing.
  - Auto-detection (`DisplayServer.is_touchscreen_available()`, mobile OS tags, first touch) and Settings toggle (`AUTO` / `ALWAYS ON` / `OFF`).
- [x] **Universal Compatibility Rendering (`gl_compatibility`):**
  - Configured `gl_compatibility` for Web (WebGL2) and Mobile (OpenGL ES3) in `project.godot`.
  - Guarded SSAO and SSR in `scripts/arena/arena.gd` with `RenderingServer.get_rendering_device() != null` to eliminate WebGL warnings.
  - Enabled mobile ETC2/ASTC texture compression.
  - Enabled touch emulation from mouse for testing.
- [x] **Web Export Pipeline:**
  - Configured Web preset in `export_presets.cfg` without threads (`web_nothreads_release.zip`) for static host compatibility.
  - Automated build script (`tools/export_web.sh`) and local server (`tools/serve_web.py`).
- [x] **Android APK Export Pipeline:**
  - Configured Android preset in `export_presets.cfg` (`org.flaxos.dartstorm`, arm64-v8a, signed).
  - Automated export and verification script (`tools/export_apk.sh`).
- [x] Automated unit and integration tests in `tests/test_runner.gd` (741 tests passed, 0 leaks, 0 warnings).

**Acceptance:** `./tools/validate.sh` passes (**741/741 tests**), `./tools/export_web.sh` generates valid HTML5/WASM bundle, and `./tools/export_apk.sh` generates verified signed APK ✅.

## v1.0.0: Local Couch Co-Op / Split-Screen (2 Players)

Goal: Full 2-player local couch co-op / split-screen on one machine (Keyboard + Gamepad or dual Gamepads) across all game modes (Versus/Free-For-All, Duos, Blue vs Orange, Zombie Siege, Floor is Lava, Gun Game).

- [x] **Dual Viewport & Shared World3D Architecture (`MatchScene`):**
  - Responsive `SplitContainer` with dual `SubViewport`s (`SubViewport1` & `SubViewport2`).
  - Configurable split orientation (Horizontal top/bottom default, or Vertical side-by-side).
  - Shared `World3D` ensures single unified physics and actor simulation without state duplication or desyncs.
  - Dedicated 3D audio listener assignment prevents audio listener conflicts.
- [x] **In-World 3D Character Models & Layer Culling:**
  - Both players render full in-world 3D `CharacterModel`s with movement animations, aim pitch, overhead name tags, shield bubbles, and equipped blasters.
  - Visual layer mask culling: Camera 1 culls Player 1 body (layer 2) and Player 2 viewmodel (layer 16); Camera 2 culls Player 2 body (layer 4) and Player 1 viewmodel (layer 8).
- [x] **Input Device Routing & Action Isolation:**
  - Automatic hardware input routing via `InputSetup.setup_split_screen_actions()`: 1 pad maps Player 1 to KBM and Player 2 to Gamepad 0; 2 pads map Player 1 to Pad 0 and Player 2 to Pad 1.
  - Testing keyboard fallbacks for Player 2 (Arrow keys, Keypad Enter, Keypad 0, Keypad 1, IJKL look keys).
  - Full input isolation across all 14 actions and scoreboard toggles.
- [x] **Per-Player Viewport HUDs:**
  - Independent `Hud` instances mounted directly inside each subviewport, confining reticles, ammo, health, shields, and popups cleanly to each player's half of the screen.
- [x] **Universal Match Mode Integration:**
  - DUOS: Players 1 and 2 assigned to Team 0 as buddy teammates with adjacent buddy spawning.
  - Blue vs Orange: Player 1 on Blue team, Player 2 on Orange team.
  - Zombie Siege & Zombies: Both players collaborate as co-op defenders / survivors.
  - FFA, Gun Game, Floor is Lava: Competitive rivalry.
  - Progression rewards tags and victories earned by both players to the profile.
- [x] **Lobby UI & Persistence:**
  - Lobby match options toggle: `PLAYERS: 1 PLAYER / 2 PLAYERS`.
  - 3D lobby preview displays Player 2 standing beside Player 1 on the squad island platform.
  - Full Player 2 customization and split-screen settings persisted cleanly in `user://settings.cfg`.
- [x] Automated unit and whole-match tests in `tests/test_runner.gd` (706 tests passed, 0 leaks, 0 warnings).

**Acceptance:** `./tools/validate.sh` passes (**706/706 tests**) ✅.

## v0.9.2: Settings & Accessibility: Controls Remapping & Colorblind Palettes


Goal: Comprehensive in-game key and gamepad button remapping with full cancellation protection, coupled with high-contrast colorblind accessibility palettes for team colors with live swatches and dynamic map fort theming.

- [x] **In-Game Input Remapping (`BindingsPanel` & `InputSetup`):**
  - Dedicated `BindingsPanel` modal with scrollable grid for all 14 core gameplay actions (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `fire`, `aim_down_sights`, `throw_grenade`, `ping`, `reload`, `weapon_next`, `weapon_prev`, `scoreboard`).
  - Dual slots: separate remapping for Keyboard/Mouse and Gamepad.
  - Interactive listening prompt (`[ PRESS KEY/CLICK... ]`, `[ PRESS BUTTON... ]`) with color highlight.
  - Cancel safety via `Escape` or controller `Start/Back`.
  - Analog stick deadzone filtering (>0.6) prevents trigger binding from being tripped by stick drift.
  - Core system navigation keys (`ui_accept`, `ui_cancel`, `pause`, look analog sticks) strictly preserved.
  - Persistent serialization/deserialization into `settings.cfg` under `[bindings]`.
  - One-click `RESET TO DEFAULTS` restoring factory bindings.
- [x] **Colorblind Team Color Palettes (`GameMode.TeamPalette`):**
  - Four distinct palettes:
    1. `DEFAULT`: Classic Blue (`#2673ff`) vs Orange (`#ff801a`), Green, Purple.
    2. `COBALT_SUNBURST` (Deuteranopia / Protanopia): Cobalt (`#1a66f2`) vs Sunburst (`#ffd11a`), Emerald, Amethyst.
    3. `MAGENTA_MINT` (Tritanopia): Magenta (`#f5389e`) vs Mint (`#40e6ad`), Coral, Lavender.
    4. `HIGH_CONTRAST`: Cyan (`#0dd9ff`) vs Hot Orange (`#ff5214`), Lime, Violet.
  - Live dual-color swatch preview in `SettingsPanel` alongside cycle button.
  - Global real-time propagation across player jersey colors, bot models, HUD banners, match announcements, and scoreboard headers.
  - Arena decor adaptation: `BackyardFortress` and `TempestTreehouse` fort structures and banners dynamically update with active team colors and names.
- [x] Automated unit and whole-match tests in `tests/test_runner.gd` (669 tests passed, 0 leaks, 0 warnings).

**Acceptance:** `./tools/validate.sh` passes (**669/669 tests**) ✅.


Goal: Pure high-energy parkour combat where dynamic molten foam lava tides flood the arena floor, cooled into temporary obsidian stepping stones by water and ice darts.

- [x] **Floor is Lava Mode (`FloorIsLavaMode`):** Solo parkour combat mode with +100 base tag points, +50 submerged kill bonus, and +25 high tide survival bonus.
- [x] **Dynamic Molten Foam Tides (`LavaDirector`):** Continuous tide cycles: CALM (24s at $Y=-0.6\text{m}$), WARNING (5s siren countdown), RISING (4s surge interpolation), HIGH TIDE (20s peak height at $Y=1.35\text{m}$), and RECEDING (4s cooling steam).
- [x] **Cartoon Molten Foam Visuals (`lava_foam.gdshader`):** Custom animated voronoi bubbling crust shader with vertex waves, hot yellow emission seams, and gentle surface bobbing. Zero gore or burning, family-friendly cartoon molten cheese/foam aesthetic.
- [x] **Hazard Damage & Foam Shield Synergy:** Submerged actors take continuous heat tag damage (+38 dps); damage absorbs 100% into active `FoamShield` (`shield_points`) before damaging tag meters, enabling daring leaps across lava lakes.
- [x] **Elemental Obsidian Cooling (`ObsidianStone`):** Water and Ice darts striking molten lava instantly create solid $1.4\text{m}$-radius cylindrical obsidian stepping platforms lasting 6.0 seconds before heating up and melting back.
- [x] **Bot Elevation AI & Panic Leaping:** Bots filter roam destinations to elevated structures ($Y > \text{lava\_height} + 0.4\text{m}$) during high tide. When submerged, bots trigger emergency jump impulses and steer toward the nearest obsidian stepping stone or high-ground structure.
- [x] **HUD Integration:** Lava tide status card under clock showing current tide state, warning countdowns, and high-tide remaining time.
- [x] Automated unit and whole-match tests in `tests/test_runner.gd` (557 tests passed, 0 leaks, 0 warnings).

**Acceptance:** `./tools/validate.sh` passes (**557/557 tests**) ✅.

## v0.7.0: Zombie Siege & Blaster Skins

Goal: Co-op base defense mode against 5 escalating zombie waves and the Mega Foam Titan Boss, combined with an anti-slop generative blaster skin pipeline.

- [x] **Zombie Siege Mode (Base Defense):** 5 escalating horde waves (Runners, Brutes, and Wave 5 Mega Titan Boss) defending a 1000 HP physical `BaseCore` and 4 destructible lane `BaseBarricade`s (250 HP).
- [x] **Intermission Fortification:** 20-second building/repair phase between waves; defenders earn Scrap to repair the base (+250 HP for 100 scrap), rebuild barricades (75 scrap), and auto-replenish ammo buckets.
- [x] **Anti-Slop Blaster Skin Architecture:** Sharp object-space tri-planar shader projection ($P^{12}$ blend power in `blaster_skin.gdshader`) with 8 seamless 1024x1024 2D vector graphic patterns, tactile PBR finishes (Matte, Gloss, Metallic Flake, and Holographic Iridescence), strict material zoning (body chassis mapped while preserving safety orange muzzle tips and dark rubber grips).
- [x] **Collectible Skin Catalog:** 8 skins in Coin Shop (`SKINS` tab with 3D preview) earnable via gameplay coins; Wave 5 boss clear unlocks exclusive **Toxic Slime** blaster skin.
- [x] **Horde AI & Archetypes:** Bot AI extended with BaseCore/barricade targeting and melee strikes; Runner (1.0x scale, 100 HP), Brute (1.35x scale, 300 HP), and Mega Foam Titan Boss (2.2x scale, 800 HP).
- [x] Automated unit and whole-match tests in `tests/test_runner.gd` (518 tests passed, 0 leaks, 0 warnings).

**Acceptance:** `./tools/validate.sh` passes (**518/518 tests**) ✅.

## v0.6.0: Tempest Treehouse

Goal: the high-canopy elemental treehouse arena from GDD §5.4.

- [x] **Tempest Treehouse** (GDD §5.4): high ancient tree grove with dual fortified canopy decks (Blue Fort, Orange Fort at $Y=5.4\text{ m}$), suspension rope bridge spanning the chasm, High Crow's Nest ($Y=10.5\text{ m}$)
- [x] **Multi-Tier Traversals:** rising canopy ramps, 3 kinetic jump-pads, upward forest wind vent ($16.5\text{ m/s}$ lift), escape ice slide chute (+9.5 m/s boost)
- [x] **Elemental Interactivity:** Gale-force wind tunnels ($28\text{ m/s}$ upper chasm), conductive bird-bath water puddle, High Crow's Nest Foam Shield & Chainstorm pickups
- [x] **Lobby & Match Integration:** Registered as third selectable arena; 14 balanced spawns; 100% navmesh bake and bot traversal across all tiers and game modes
- [x] Automated unit and whole-match tests in `tests/test_runner.gd` (423 tests passed, 0 leaks, 0 warnings)

**Acceptance:** `./tools/validate.sh` passes (**423/423 tests**) ✅.

Goal: the house arena, built now at the owner's request (it was item 5 below).

- [x] **Home Turf** (GDD §5.3): a fictional family home at toy scale. A dollhouse with no roof; every room furnished as
      cover; beds and a kids'-room trampoline; three mirrors; a giant fan in the kitchen; a climbable patio roof up a toy
      race-track ramp; a garage with two cars; front yard, driveway, footpath and street; side paths for flanking
- [x] **ARENA** option in the lobby (BACKYARD / HOME TURF), remembered; `--arena=N` for screenshot runs
- [x] Shared arena pieces: sky/sun/clouds in `Arena` (with sun height and warm fill options), houses and trees in
      `ArenaKit`; `WindZone.show_volume` for indoor wind
- [x] `tools/arena_shots.gd`: overview screenshots of any arena
- [x] **Fix:** in team modes two team-mates could spawn on the same spot and get flung into the sky (since v0.3.0)
- [x] TEAMS description no longer mentions forts (it fits any arena)

**Acceptance:** `./tools/validate.sh` passes (**276/276 tests**) ✅ · UAT section J ⏳.

## v0.3.0: the young players' design

Goal: the young players drew their own DARTSTORM before seeing it (GDD §1.9). Build what they drew first.

- [x] **Their lobby:** a floating "bunker" island with you in the middle and your squad on platforms around you
      (team-mates nearest, back rows higher), the player card and button column top left, mode cards top right, the logo
      bottom middle and a big PLAY bottom right (GDD §3.22)
- [x] **SOLO / DUOS / TEAMS:** Blue vs Orange and pairs, with even teams (an extra bot when needed), no friendly fire,
      team colours, home-end respawns, team chips on the HUD, a grouped scoreboard, lead-change call-outs, team results
      and a team podium (GDD §3.21)
- [x] Up to **7 bots** (4 v 4); two new bots, Comet and Biscuit
- [x] **New hats from their characters:** goggles, bunny ears, horns, spiky hair
- [x] Fix: bots now wear their own hats in matches (they all wore caps)
- [x] Fix: a flaky announcer test (it waited for physics frames, not HUD frames)
- [x] Screenshot flags `--mode=N --bots=N` for demo runs
- [x] Planned and written up: Zombie mode (§3.21), rewards with coins only (§10, D-028), the **Home Turf** arena built
      as a fictional family home at toy scale (§5.3, D-031)

**Acceptance:** `./tools/validate.sh` passes (import, strict compile, boots, **251/251 tests**, leak check) ✅ ·
UAT section I in UAT.md ⏳.

## v0.2.0: controller support and appeal pack

Goal: plug-and-play controllers (the target machine runs Linux, so Windows can wait), plus the "small and medium" appeal ideas:
things players can see, hear and laugh at.

- [x] **Controller plug and play:** A/B in every menu, hot-plug notices, unplug pauses, curved stick aim, aim assist,
      rumble, LT sprint / Y next blaster, look-speed setting, help text switches to pad buttons (GDD §3.17)
- [x] **Chunky font:** Lilita One (OFL) everywhere
- [x] **Music and better sounds:** procedural menu and match loops (rendered off the main thread), foam-y effects,
      separate Music / Sound effects volumes
- [x] **Announcer:** first tag, multi-tags, streaks, shut-downs, time warnings, STORM MODE! (GDD §3.18)
- [x] **Your player:** name (with RANDOM), 8 colours, 7 hats, live 3D preview; bots get their own hats (GDD §3.16)
- [x] **Podium and awards** at the end of every match (GDD §3.20)
- [x] **Backyard life:** dog house with a barking dog, swing set, paddling pool and duck, sprinkler, gnomes, flowers,
      birdsong (GDD §5.1)
- [x] **Chainstorm power-up mode** (optional; default stays EVERYONE as the brief says) (GDD §3.19)
- [x] Fixes found on the way: mirrored signs seen from behind; podium framing; name typing kept spaces
- [x] **Double-clickable Linux build:** `./tools/export_linux.sh` → `build/linux/DARTSTORM/` (one executable, icon,
      README, `install-shortcut.sh`) and a `.tar.gz`; the exported game is booted headless as a smoke test (D-027)

**Acceptance:** `./tools/validate.sh` passes (import, strict compile of 49 scripts, boots, **211/211 tests**, no leaks) ✅ ·
the export builds and boots ✅ · UAT sections F, G and H in UAT.md ⏳.

## v0.1.1: hardening and docs

Goal: make the UAT-approved game robust for real-world play, and turn the docs into a complete reference
built around the original concept brief.

**Hardening.** Each item ships with a regression test (GDD §6, ARCHITECTURE §10):
- [x] H1 Losing window focus pauses the match; the click that re-captures the mouse doesn't fire
- [x] H2 Back-to-back ricochets between close mirrors no longer let darts slip through (the test fails on the old code)
- [x] H3 Anyone tagged out outside play (e.g. during the countdown) always respawns, with nothing scored
- [x] H4 Bots drop an empty blaster at once; completely dry bots wait at the nearest bucket
- [x] H5 Navmesh bakes on a worker thread (no load hitch); bots steer straight until it's ready
- [x] H6 Effects budget: 6 new impact bursts per frame and 48 alive (× Visual effects); tag-out bursts always show
- [x] H7 A missing or corrupt mode/skill file falls back to defaults; an arena failure returns to the menu
- [x] H8 Clean exit: every quit goes through `Sfx.quit_game()`; no leaked objects (and validation checks it)
- [x] H9 Zero GDScript warnings, enforced by a strict compile step in `validate.sh`
- [x] H10 Settings: **Reset to defaults** button and a settings file version
- [x] Also: the menu saves bot count and skill as soon as they change; a preload cycle in DartPool is removed

**Docs:**
- [x] `CONCEPT_BRIEF.md`: the original brief, archived verbatim
- [x] `GDD.md`: concept chapter, brief traceability matrix, expanded gameplay (hits-to-tag, generated dart-flight
      table, wind and ricochet playbooks, ammo economy, scoring, bots, tips), arena callouts, hardened feature specs,
      style guide, accessibility, glossary
- [x] `UAT.md`: a repeatable acceptance script and results log
- [x] `TUNING.md`: a no-code guide to every data field, with recipes
- [x] `ARCHITECTURE.md`: failure modes, performance budgets, validation pipeline · `DECISIONS.md` D-013 to D-019
- [x] Personal information removed from docs and comments; the archived brief is redacted (D-019)

**Acceptance:** `./tools/validate.sh` passes (import, strict compile, boots, **130/130 tests**, no leaks) ✅ ·
UAT re-check of A4, B13, B14, D2 and D3 ⏳.

## Done earlier (v0.1.0)

<details><summary>Phases 0–6 detail</summary>

- **Phase 0:** Godot 4.4 project, git, README, CLAUDE.md, living docs, `validate.sh`, `run.sh`, headless tests, `--demo` screenshot driver
- **Phase 1:** first-person controller (WASD, mouse, jump with coyote time and buffer, sprint, smooth acceleration); Backyard Fortress
  (two forts, treehouse, walkways, ramps, slide, trampolines, crates, barriers, hedge, two mirrors, wind zone, five buckets, six bullseyes,
  landmarks); runtime navmesh
- **Phase 2:** pooled `DartProjectile` (gravity, drag, wind, swept ray, lifetime, spent darts); `WindField` + `WindZone`; `ReflectiveSurface`; ricochet bonus
- **Phase 3:** resource-driven `WeaponData`/`DartData`, `Arsenal`, procedural `BlasterModel`; Pocket Popper, Dart Sprayer,
  **Flax's Chainstorm**; plus Double Trouble, Foam Hammer, Ricochet Ranger, Longshot
- **Phase 4:** tag meter, regen, spawn protection, respawns; bots (roam/fight/resupply, navmesh, leading aim, weapon choice,
  hit reactions); match flow (countdown, 5:00, scoring, tag feed, scoreboard, results, restart); ammo buckets
- **Phase 5:** muzzle puffs, recoil, bob, sway, shake setting, trails, particles, hit markers, popups, procedural SFX,
  Chainstorm feedback; HUD, main menu, settings, pause
- **Phase 6:** `GunGameMode` with a data-driven ladder, bottomless ammo, instant Chainstorm win
</details>

## Next up (in priority order)

1. **UAT of v0.2.0 and v0.3.0 with young players** *(next, for the humans)*. Show them their lobby first! Run UAT.md
   (F with a real controller, G, H on their PC, I for the lobby and teams), then just let them play. Ask: best moment,
   most annoying thing, what would you add? Does TEAMS or DUOS beat SOLO? POWER-UP or EVERYONE?
2. ✅ **ZOMBIES mode** (v0.5.1): Goofy green foam zombies with no blasters. 1 Alpha Zombie ("Patient Zero") hunts survivors; touching infects survivors into green foam horde members (+150 pts). Survivors use elemental blasters (Hydro Soaker knockback & Frost Ranger chills repel charging zombies). Zombie bot AI, first-person green cartoon zombie arms/swipe, lobby preview card, survivor HUD counter, procedural audio (&"zombie_moan", &"infect"), and 338 passing automated tests.
3. ✅ **Elements, Foam Shield & Environmental Hazards** (v0.5.0 & v0.5.2):
   - *v0.5.0*: Playful elemental darts (Fire, Water, Lightning, Ice, Wind), full 10-rung Gun Game ladder, and elemental combos (steam, flash steam, conductive shock).
   - *v0.5.2*: **Foam Shield** power-up (`ShieldPickup`, holographic hexagonal bubble with `foam_shield.gdshader`, 50 tag point buffer, zombie infection protection), **conductive water puddles** (`WaterPuddle` electrified by Thunder Cannon/lightning), **frictionless ice slicks** on ramps/slides (`IceSlick`, meltable by fire), and **interactive wind vents** (`WindVent`) amplifying elemental dart clouds. Tested across 359 automated tests with zero warnings and zero leaks.
4. ✅ **Progression, Levels, Missions & Coin Shop** (v0.5.3, D-028, D-036):
   - **`Progression` Autoload**: Lifetime XP, Player Levels ($100 \times \text{level}$ XP per level), Coins (starts with 250 coins), unlocked cosmetics, and active backyard missions. Clean persistence to `user://progression.cfg`.
   - **Player Card**: Displays gold Level badge (`⭐ LVL [N]`), XP progress bar, and live Coin balance in the lobby.
   - **Backyard Missions**: 3 active kid-safe objectives dynamically replenished from mission pool upon completion (+200 XP, +100 Coins).
   - **Coin Shop**: 100% kid-safe cosmetic catalog for hats and colours. Zero real money, zero gems, zero microtransactions, zero paid power.
   - **Match End Payout**: Rewards calculated and awarded on match completion (+25 XP/+5 Coins per tag, +100/+25 match finish, +150/+50 win) with a celebratory breakdown banner in the results panel beside the podium.
   - **Validation**: 398 automated tests passing with zero errors, zero warnings, and zero leaks.
5. ✅ **Tempest Treehouse arena** (v0.6.0): Multi-tier backyard treehouse canopy arena with rope bridge, Crow's Nest, kinetic jump-pads, ice slide chute, high-elevation wind tunnels, and foam shield spire.
6. ✅ **Zombie Siege & Blaster Skins** (v0.7.0): 5-wave base defense mode protecting BaseCore and barricades against zombie hordes and Mega Titan Boss. Generative anti-slop tri-planar shader pipeline with 8 collectible vector skins.
7. ✅ **Kid-Feedback Calibration, Sniper ADS & Zombie Lunge** (v0.7.1):
   - **Game Pacing & Calibration**: Added `GameSettings.game_speed` (default `0.90`, range `0.70` to `1.10`) with a dedicated calibration slider in the Settings menu and `Engine.time_scale` integration. Softened base actor movement speeds.
   - **Physics Yeet Glitch Prevention**: Fixed compounding velocity runaway in `IceSlick` with 0.8s cooldown and velocity ceiling; enforced `Actor.MAX_HORIZONTAL_SPEED = 24.0 m/s`; raised Tempest Treehouse boundary walls to 22.0m.
   - **Sniper Rifle Buff & ADS Scope**: Added `zoom_fov = 35.0` to Longshot rifle, buffed tag power to 85.0, registered `aim_down_sights` action, scaled mouse/controller sensitivity, hid viewmodel while scoped, and added authentic sniper scope overlay with range mil-dots.
   - **Zombie Pacing & Lunge**: Calibrated zombie speeds so humans can kite; added sudden telegraphed lunge (+7.5 m/s impulse) when within 2.5–4.2m with line-of-sight on a $\ge 3.5\text{s}$ cooldown.
   - **Zombie Siege Rebalancing**: BaseCore HP boosted to 1250, Barricade HP boosted to 350, intermission extended to 25s, rebalanced wave batches, boosted scrap economy.
8. ✅ **Floor is Lava Mode** (v0.8.0):
   - **Dynamic Tides**: Cyclic phases (CALM 24s, WARNING 5s siren countdown, RISING 4s, HIGH TIDE 20s at 1.35m, RECEDING 4s with +25 Survival Bonus).
   - **Molten Foam Hazard**: Heat tag damage (+38 dps) with sizzling audio, absorbs into Foam Shield first.
   - **Elemental Cooling**: Water and ice darts instantly cool molten lava into solid 6.0s `ObsidianStone` stepping platforms.
   - **Bot High-Ground AI**: Bots filter roam targets to elevated platforms during high tide and leap away if submerged.
9. ✅ **Foam Grenades & Elemental Weapon Power-Ups** (v0.8.1):
   - **Foam Grenade (`FoamGrenade`)**: Physical bouncy 0.35kg throwable with ticking LED fuse (1.8s), 16 radial physical darts, 4.5m area blast wave (20–65 tag damage, 11.5 m/s knockback), and confetti cloud. Thrown via `G` key, middle mouse, or D-Pad Down (`throw_grenade`).
   - **Foam Grenade Pickup (`GrenadePickup`)**: Spawns in arenas, granting +1 grenade up to `GRENADE_MAX = 2` on a 25s respawn timer.
   - **Elemental Weapon Infusions (`ElementalPickup`)**: Canisters granting 15 seconds of Pyro, Hydro, Frost, or Volt infusion across all carried blasters.
   - **HUD & Bot Integration**: Weapon HUD grenade counter (`💣 N [G]`) and elemental infusion timer bar with badges; bot AI incorporates grenade and infusion seeking into decisions.
10. ✅ **Elemental Weather & Dynamic Map Disasters** (v0.9.0):
   - **Weather Director (`WeatherDirector`)**: Cyclic weather progression (CALM 28s, FORECAST_WARNING 5s with HUD countdown chime, active disaster 20s).
   - **Thunderstorm**: Rain precipitation particles, rolling thunder sounds (`&"thunder"`), and lightning strikes that dynamically electrify `WaterPuddle`s (`puddle.electrify(4.0)`).
   - **Blizzard**: Snow flurries, howling wind (`&"blizzard_wind"`), and dynamic spawning of temporary `IceSlick` patches on arena walkways.
   - **Gale Gusts**: Swirling leaves, global wind acceleration up to 26 m/s, and a roving cartoon `WhirlwindVortex` that spring-launches players +14.5 m/s into the air.
   - **Heatwave**: Summer heatwave that melts ice slicks into water pools and causes puddles to sizzle with steam.
   - **HUD & Settings**: Persistent weather badge icon (`⛈️`, `❄️`, `🌪️`, `☀️`, `🌤️`) with countdown timer, and `GameSettings.weather_events` toggle.
   - **Bot Navigation**: Bots dynamically detect electrified puddles and steer away to avoid getting zapped.
   - **Validation**: 625 automated tests passing with zero errors, zero warnings, and zero leaks.
11. ✅ **DUOS Buddy Spawning, Tactical Pings & Bot Teamplay** (v0.9.1):
   - **Coordinated DUOS Spawns**: Teammate pairs spawn at adjacent spawn points (6m–20m) at match start and on respawn.
   - **Tactical Squad Ping System (`PingBeacon`)**: Interactive in-world 3D marker with context raycast (Ammo, Power-Up, Rival, Danger, Regroup) triggered by `T` key, Middle Mouse, or Controller D-Pad Up (`ping`).
   - **Smarter Bot Teamplay**: Bots bias roaming toward living buddy (5m–18m pocket), acknowledge and react to squad pings, and fall back into defensive retreat when tag meter exceeds 70%.
   - **Resolved Known Issue**: Fixed DUOS spawn distribution bug where buddies spawned apart across the yard.
   - **Validation**: 638 automated tests passing with zero errors, zero warnings, and zero leaks.

## Later (Phase 7 / Wishlist from Young Players)
- Weapon customisation and mastery (cosmetic or sidegrades only, D-028)
- ✅ Local split-screen (2 Players) (v1.0.0)
- ✅ Accessibility: key remapping, a colour-blind team palette option (v0.9.2)
- Online / LAN multiplayer (DECISIONS D-008)

## Known issues
- Controller support is tested with simulated input only. A real pad (Xbox/PlayStation/generic) needs the UAT check.
- Windows is deferred (the target machine runs Linux).
- The music is simple chiptune made in code; real recordings could replace it later.
- Bots ignore wind (deliberate, see GDD §3.9) and can briefly snag on geometry before the unstick hop kicks in.

*Resolved in v0.1.1:* the navmesh load hitch, the "ObjectDB instances leaked at exit" warning, and the integer-division
warnings in the HUD.
*Resolved in v0.5.3:* the lobby shows Player Level, XP progress, and Coins; Backyard Missions and Coin Shop are live.
*Resolved in v0.7.1:* the physics yeet velocity runaway bug, gameplay pacing calibrated with UAT slider, Longshot sniper rifle ADS scope buff, and zombie horde pacing and lunge mechanics rebalanced.
*Resolved in v0.9.1:* the DUOS spawning bug where teammates spawned apart; now spawn side-by-side at adjacent launch points; tactical ping system and bot teamplay added.
*Resolved in v0.9.2:* In-game key and controller button remapping with full cancel protection, and high-contrast colorblind team palettes (Cobalt & Sunburst, Magenta & Mint, High Contrast).
*Resolved in v1.0.0:* 2-Player Local Couch Co-Op / Split-Screen implemented across all game modes (Versus, Duos, Teams, Zombie Siege, Floor is Lava, Gun Game) with dual viewports, input device isolation, layer-culled in-world 3D character models, independent HUDs, and lobby integration.

