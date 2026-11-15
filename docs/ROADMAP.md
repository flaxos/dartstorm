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
| **v0.1.1 hardening + docs** | ✅ Built and validated. ⏳ UAT re-check pending |
| Phase 7 Expansion | ⏳ Not started (on purpose) |

## v0.1.1: hardening and docs (this release)

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

1. **UAT re-check of v0.1.1** *(quick)*. Run the v0.1.1 rows in UAT.md, especially alt-tab and Reset to defaults.
2. **Playtest-driven tuning.** Watch young players play several rounds and note what's too hard, too easy or most fun.
   Tune the `.tres` numbers ([TUNING.md](TUNING.md)), especially bot skill, tag power, Chainstorm ammo burn and
   bucket regen. Record the findings in UAT.md.
3. **Windows check and a double-clickable build.** Run on a Windows PC. Add a Windows export preset so
   players can launch a `.exe` without opening Godot (needs the Godot export templates).
4. **Blue vs Orange team mode.** The arena is built for it and `team_id` already exists. Acceptance: a menu option,
   two teams with bots split between them, a team scoreboard, team-coloured shirts, team-coloured bucket ownership.
5. **Remaining Gun Game rungs** (Wind Whisperer, Thunder Cannon, Rocket Dart) with simple, playful elemental dart effects.
   Acceptance: a 10-rung ladder, each blaster distinct, tests updated.
6. **Polish:** a chunkier OFL-licensed font, better blaster and kid silhouettes, music, a "tagged by" camera.
7. **Capturable buckets** as team objectives.

## Later (Phase 7, only once the above is solid)
- Second arena: **Tempest Treehouse** is cheapest (it reuses WindZone gusts and JumpPads)
- Weapon customisation and mastery (no economy, no paid anything)
- Smarter bots (cover, wind awareness, team play)
- Local split-screen or online multiplayer (DECISIONS D-008)
- Accessibility: key remapping, a colour-blind team palette option

## Known issues
- Gamepad bindings exist but are untested.
- Not yet run on Windows.
- Bots ignore wind (deliberate, see GDD §3.9) and can briefly snag on geometry before the unstick hop kicks in.
- The font is Godot's built-in default, emboldened. It works, but isn't as chunky as the style guide wants.
- Gun Game has 7 of the 10 planned rungs.

*Resolved in v0.1.1:* the navmesh load hitch, the "ObjectDB instances leaked at exit" warning, and the integer-division
warnings in the HUD.
