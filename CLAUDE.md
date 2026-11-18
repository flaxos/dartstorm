# CLAUDE.md: notes for future Claude Code sessions

DARTSTORM: Elemental Arena is a family-friendly first-person foam-dart arena shooter in
**Godot 4.4 / GDScript**, made for young players and built around their own ideas.
Priority order: **fun, colourful and playable**, then everything else. Keep it kid-safe: cartoon
tagging only, no gore, no real-firearm branding, no microtransactions.

## Start here

1. Read `docs/ROADMAP.md` (current status and next task), then `docs/ARCHITECTURE.md`.
   `docs/GDD.md` is the authoritative design; `docs/CONCEPT_BRIEF.md` is the original brief (archived verbatim, don't edit it).
2. Validate before and after changes: `./tools/validate.sh` (about 2 minutes; `--quick` skips the tests).
   It fails on any GDScript **warning** (strict compile step), any test failure, or any "leaked at exit".
3. Play: `./tools/run.sh`. The main scene is `scenes/ui/main_menu.tscn`, and the match is `scenes/game/match.tscn`.

Godot lives at `~/bin/godot` (4.4.1) on the dev box. **Linux is the platform that matters now**; Windows is deferred.
Linux release: `./tools/export_linux.sh` (needs the export templates; output in `build/`, which git ignores).
Controllers must stay plug and play: every binding uses device -1, and every screen works with A/B.

## Checking the game without a human

- Headless tests: `godot --headless --path . res://tests/test_runner.tscn` (exit code 0 means pass).
  Add a test for every new system; tests are plain methods in `tests/test_runner.gd`.
- Screenshots: with a display available,
  `godot --path . res://scenes/game/match.tscn -- --demo --shots=<abs dir> --quit-after=12`
  plays the match automatically (turns, fires, cycles blasters) and saves PNGs you can inspect.
  Running the menu with `-- --demo --shots=...` captures the title screen; add `--open-settings` or `--open-customise`
  for those panels. `--mode=N` (GameSettings.MatchMode: 0 SOLO, 1 GUN GAME, 2 DUOS, 3 TEAMS, 4 ZOMBIES, 5 ZOMBIE_SIEGE) and `--bots=N` pick the
  mode and bot count for that run, and `--arena=N` (0 BACKYARD, 1 HOME TURF, 2 TEMPEST TREEHOUSE) the arena, in the lobby or a match.
  In a match, `--powerup` turns on power-up mode and drops the Chainstorm at 4 s, and `--end-after=N`
  ends the round after N seconds (to see the podium). See `scripts/debug/demo_driver.gd`.
- Arena layouts: `godot --path . -s res://tools/arena_shots.gd -- --arena=1 --shots=<abs dir>` saves views from above
  and from each corner.
- There's no physical controller on the dev box: test pads with `Input.parse_input_event(InputEventJoypadMotion/Button)`
  (see `_test_controller_support`).
- Automated checks can't tell you whether the game *feels* good. Say what still needs a human playtest.

## Doc map
| Doc | Update it when |
|---|---|
| `docs/GDD.md` | Gameplay, numbers, or a feature's rules/guarantees change (§6 feature specs list the covering tests) |
| `docs/TUNING.md` | A data field is added or renamed |
| `docs/UAT.md` | A release needs a hands-on check (add rows, then log results) |
| `docs/ARCHITECTURE.md` | Systems, ownership, safeguards (§10) or budgets (§11) change |
| `docs/DECISIONS.md` | A non-obvious choice is made (latest is D-038) |
| `docs/ROADMAP.md` | Always, at the end of a piece of work |

## Conventions
- **Every bug fix or hardening change ships with a regression test** in `tests/test_runner.gd`.
  If you can, prove the test fails without the fix. Use the `fast_forward()`, `start_match()` and `end_match()` helpers
  for match-level tests.
- **No personal information in the repo.** Don't name real people or describe family relationships in docs,
  code, commits or PRs (D-019). "Flax's Chainstorm" is the blaster's in-game name and stays. The repo is public:
  every place in the game is fictional, with no real addresses, street, park or shop names, and no reference photos (D-031).
- **The lobby is the young players' own design** (GDD §1.9, §3.22). Keep their layout when adding to it.
- **Quit only via `Sfx.quit_game()`**, never `get_tree().quit()` directly, or audio objects leak.
- **No `preload` of a scene whose script refers back to the preloading class** (load cycle, D-018).
- `-s` tool scripts compile before autoloads exist: load game classes at runtime there (see `tools/dart_table.gd`).
- After changing a dart, regenerate the GDD flight table: `godot --headless --path . -s res://tools/dart_table.gd`.
- Typed GDScript, `class_name` on reusable scripts, signals for decoupling, tabs for indentation.
- **Data lives in Resources**: blasters in `resources/weapons/*.tres` (WeaponData), darts in `resources/darts/`
  (DartData), modes in `resources/modes/` (GameMode / GunGameMode), bot skill in `resources/bots/` (BotDifficulty).
  A new blaster means a new `.tres` file, not new code. Give it a `model_style` and a `sound` that `Sfx` knows.
- Scenes are thin `.tscn` wrappers around scripts that build their nodes in `_ready()` (see DECISIONS D-002).
  Arenas are built in code from `ArenaKit` primitives. Anything solid must go under `arena.geometry`,
  otherwise bots can't navigate around it.
- Physics layers are in `scripts/core/layers.gd` and must match `project.godot`.
- Input actions are registered in `scripts/core/input_setup.gd`, not in project.godot.
- Only three autoloads: `GameSettings` (preferences), `Sfx` (procedural sounds), and `Progression` (XP, levels, coins, missions, unlocks). Don't add more without a good reason.
- No external assets without recording their source and licence in `assets/README.md`.
- Keep the number of live darts bounded (`DartPool.max_active`).

## Git

- Work on a branch and open a PR against `main` on https://github.com/flaxos/dartstorm.
- Never commit `.godot/`. Do commit `*.uid` and `*.import` files.
- After finishing a feature, update `docs/ROADMAP.md` (and the GDD/ARCHITECTURE/DECISIONS if they changed).
