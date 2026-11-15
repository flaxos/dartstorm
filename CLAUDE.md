# CLAUDE.md: notes for future Claude Code sessions

DARTSTORM: Elemental Arena is a family-friendly first-person foam-dart arena shooter in
**Godot 4.4 / GDScript**. It's built by Sam for his kids (the ideas came from the kids and Flax).
Priority order: **fun, colourful and playable**, then everything else. Keep it kid-safe: cartoon
tagging only, no gore, no real-firearm branding, no microtransactions.

## Start here

1. Read `docs/ROADMAP.md` (current status and next task), then `docs/ARCHITECTURE.md`.
2. Validate before and after changes: `./tools/validate.sh` (about 1–2 minutes; `--quick` skips the tests).
3. Play: `./tools/run.sh`. The main scene is `scenes/ui/main_menu.tscn`, and the match is `scenes/game/match.tscn`.

Godot lives at `~/bin/godot` (4.4.1) on Sam's dev box. The project targets Windows first and Linux second.

## Checking the game without a human

- Headless tests: `godot --headless --path . res://tests/test_runner.tscn` (exit code 0 means pass).
  Add a test for every new system; tests are plain methods in `tests/test_runner.gd`.
- Screenshots: with a display available,
  `godot --path . res://scenes/game/match.tscn -- --demo --shots=<abs dir> --quit-after=12`
  plays the match automatically (turns, fires, cycles blasters) and saves PNGs you can inspect.
  Running the menu with `-- --demo --shots=...` captures the title screen. See `scripts/debug/demo_driver.gd`.
- Automated checks can't tell you whether the game *feels* good. Say what still needs a human playtest.

## Conventions

- Typed GDScript, `class_name` on reusable scripts, signals for decoupling, tabs for indentation.
- **Data lives in Resources**: blasters in `resources/weapons/*.tres` (WeaponData), darts in `resources/darts/`
  (DartData), modes in `resources/modes/` (GameMode / GunGameMode), bot skill in `resources/bots/` (BotDifficulty).
  A new blaster means a new `.tres` file, not new code. Give it a `model_style` and a `sound` that `Sfx` knows.
- Scenes are thin `.tscn` wrappers around scripts that build their nodes in `_ready()` (see DECISIONS D-002).
  Arenas are built in code from `ArenaKit` primitives. Anything solid must go under `arena.geometry`,
  otherwise bots can't navigate around it.
- Physics layers are in `scripts/core/layers.gd` and must match `project.godot`.
- Input actions are registered in `scripts/core/input_setup.gd`, not in project.godot.
- Only two autoloads: `GameSettings` (preferences) and `Sfx` (procedural sounds). Don't add more without a good reason.
- No external assets without recording their source and licence in `assets/README.md`.
- Keep the number of live darts bounded (`DartPool.max_active`).

## Git

- Work on a branch and open a PR against `main` on https://github.com/flaxos/dartstorm.
- Never commit `.godot/`. Do commit `*.uid` and `*.import` files.
- After finishing a feature, update `docs/ROADMAP.md` (and the GDD/ARCHITECTURE/DECISIONS if they changed).
