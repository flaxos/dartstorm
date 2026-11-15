# DARTSTORM — Roadmap

*Updated: 2026-11-15. Every phase must end with a playable, validated build.*

## Status at a glance

| Phase | State |
|---|---|
| 0 Bootstrap | ✅ Done |
| 1 Movement & arena | ✅ Done |
| 2 Dart physics | ✅ Done |
| 3 Weapons | ✅ Done (3 required + 4 Gun Game extras) |
| 4 Combat, bots, match | ✅ Done |
| 5 Game feel | 🟡 First pass done, needs a real playtest with the kids |
| 6 Gun Game | ✅ Playable with a 7-rung ladder (3 planned rungs not built) |
| 7 Expansion | ⏳ Not started (on purpose) |

**Verified automatically:** project import, main-menu and match boots, and 101 headless tests covering
dart gravity, wind, ricochet, anti-tunnelling, tagging, fire modes, reloads, the Chainstorm spin-up and belt,
ammo buckets, scoring, the Gun Game ladder, navmesh reachability, a full fast-forwarded bot match, and
Gun Game promotion. Windowed screenshots were checked by eye (the menu and a demo match).

**Not yet verified:** a human playing with mouse and keyboard (feel, difficulty, balance), gamepad, Windows.

## Done

### Phase 0: Bootstrap
- [x] Godot 4.4 project, git, `.gitignore`, README, CLAUDE.md, four living docs
- [x] `tools/validate.sh`, `tools/run.sh`, headless test runner, `--demo` screenshot driver

### Phase 1: Movement & arena
- [x] First-person controller: WASD, mouse look, jump (coyote time and buffer), sprint, smooth acceleration
- [x] Backyard Fortress: two forts, treehouse, walkways, ramps, slide, trampolines, crates, foam barriers,
      hedge, two mirrors, wind zone, five buckets, six bullseyes, landmarks, neighbourhood backdrop
- [x] Runtime navmesh bake

### Phase 2: Dart physics
- [x] Pooled `DartProjectile` with gravity, drag, wind and a swept ray (no tunnelling), lifetime and spent darts
- [x] `WindField` + `WindZone` (streaks, arrows, windsock, fan, gust support)
- [x] `ReflectiveSurface` ricochets with speed loss, a count limit and no repeat hits; ricochet bonus

### Phase 3: Weapons
- [x] Resource-driven `WeaponData` / `DartData`, `Arsenal` runtime, procedural `BlasterModel`
- [x] Pocket Popper, Dart Sprayer, **Flax's Chainstorm** (spin-up, belt, backpack, spinning barrels, motor whine, slowdown)
- [x] Bonus: Double Trouble, Foam Hammer, Ricochet Ranger, Longshot

### Phase 4: Combat
- [x] Tag meter, regen, spawn protection, tag-out foam burst, respawn timer
- [x] Bots: roam, fight and resupply moods, navmesh pathing, leading and drop-compensated aim, weapon choice,
      hit reactions, grudges, anti-stuck; Easy/Normal/Hard
- [x] Match: countdown, 5:00 clock, free-for-all scoring, tag feed, scoreboard, results, restart
- [x] Ammo buckets with drain, empty state and regeneration

### Phase 5: Game feel (first pass)
- [x] Muzzle puffs, recoil, bob, sway, camera shake (with a setting), trails, impact particles, hit markers,
      popups, procedural SFX, Chainstorm spin feedback
- [x] HUD, main menu, settings, pause menu

### Phase 6: Gun Game
- [x] `GunGameMode` with a data-driven ladder, bottomless ammo, instant win on a Chainstorm tag

## Next up (in priority order)

1. **Playtest with the kids and tune** *(highest value)*. Acceptance: Sam and the kids play 3+ rounds and
   report what's too hard or easy and what's fun. Tune the `.tres` numbers (no code needed), especially bot
   difficulty, tag power, Chainstorm ammo burn and bucket regen. Check mouse sensitivity defaults.
2. **Windows check.** Run on Sam's Windows PC. Optionally add an export preset so the kids can launch
   a `.exe` without opening Godot.
3. **Blue vs Orange team mode.** The arena is built for it and `team_id` already exists. Acceptance:
   a menu option, 2 teams with bots split between them, team scoreboard, team-coloured player/bot shirts.
4. **Remaining Gun Game rungs** (Wind Whisperer, Thunder Cannon, Rocket Dart) with simple elemental
   dart effects. Acceptance: a 10-rung ladder, each blaster distinct, tests updated.
5. **Polish:** a real chunky font (OFL-licensed), better blaster/character silhouettes,
   a kill-cam style "tagged by" view, music.
6. **Capturable buckets** as team objectives.

## Later (Phase 7, only once the above is solid)
- Second arena (Tempest Treehouse is the cheapest: it reuses WindZone gusts and JumpPads)
- Weapon customisation and mastery (no economy, no paid anything)
- Smarter bots (cover use, wind awareness, team play)
- Local split-screen or online multiplayer (see DECISIONS D-008)

## Known issues
- Gamepad bindings exist but are untested.
- Bots ignore wind (a deliberate weakness, see the GDD) and can briefly snag on geometry before the unstick hop kicks in.
- The navmesh bakes when a match loads (a short hitch on slow machines). It could be baked once and saved as a resource.
- Godot prints a harmless "ObjectDB instances leaked at exit" warning when the *test runner* quits.
- The font is Godot's built-in default, emboldened. It works, but it isn't as chunky as the style guide wants.
