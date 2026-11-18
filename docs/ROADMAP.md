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
| Phase 7 Expansion | ⏳ Not started (on purpose) |

## v0.8.0: Floor is Lava Mode (this release)

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

## Later (Phase 7 / Wishlist from Young Players)
- **Floor is Lava Mode**: Dynamic rising lava hazard where ground level becomes dangerous and players must parkour across backyard forts, furniture, and rooftops.
- **Foam Grenade Pickup Item**: Throwable bouncing canister that detonates into a multi-dart area-of-effect foam burst with festive confetti.
- **Elemental Weather & Map Disasters**: Lightning storms electrifying puddles, flash freezing blizzards creating ice slicks, and wind whirlwinds.
- **Elemental Weapon Power-Ups**: Temporary pickups providing fire, lightning, water, and ice dart infusions to any standard blaster.
- Weapon customisation and mastery (cosmetic or sidegrades only, D-028)
- Smarter bots (cover, wind awareness, team play)
- Local split-screen or online multiplayer (DECISIONS D-008)
- Accessibility: key remapping, a colour-blind team palette option

## Known issues
- Controller support is tested with simulated input only. A real pad (Xbox/PlayStation/generic) needs the UAT check.
- Windows is deferred (the target machine runs Linux).
- The music is simple chiptune made in code; real recordings could replace it later.
- Bots ignore wind (deliberate, see GDD §3.9) and can briefly snag on geometry before the unstick hop kicks in.
- Gun Game has 7 of the 10 planned rungs.
- In DUOS, spawns don't put buddies together; you'll often start apart from your buddy.

*Resolved in v0.1.1:* the navmesh load hitch, the "ObjectDB instances leaked at exit" warning, and the integer-division
warnings in the HUD.
*Resolved in v0.5.3:* the lobby shows Player Level, XP progress, and Coins; Backyard Missions and Coin Shop are live.
*Resolved in v0.7.1:* the physics yeet velocity runaway bug, gameplay pacing calibrated with UAT slider, Longshot sniper rifle ADS scope buff, and zombie horde pacing and lunge mechanics rebalanced.
