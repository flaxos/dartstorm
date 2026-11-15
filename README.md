# DARTSTORM: Elemental Arena

A colourful, family-friendly, first-person **foam-dart arena shooter** made with Godot 4.
Blue team versus orange team, backyard forts, buckets of darts, wind that bends your shots,
mirrors you can bounce darts off, and **FLAX'S CHAINSTORM**: a ridiculous belt-fed, six-barrel
foam cannon.

No gore and no real-world guns. Tagged players pop into a shower of foam confetti and respawn.

## Play it

1. Install **Godot 4.4 or newer** (the standard build, not .NET) from <https://godotengine.org/download>.
   It's a single program with no installer to run.
2. Open Godot, click **Import**, pick this folder's `project.godot`, then click **Import & Edit**.
3. Press **F5** (or the ▶ Play button at the top right).

From a terminal you can also run:

```bash
./tools/run.sh          # play
./tools/run.sh editor   # open in the Godot editor
./tools/run.sh demo     # watch a 20-second automatic demo
```

## Controls

| Action | Keyboard / mouse | Gamepad (mapped, not yet tested) |
|---|---|---|
| Move | W A S D / arrow keys | Left stick |
| Look | Mouse | Right stick |
| Jump | Space | A |
| Sprint | Shift (while moving forward) | Left stick click |
| Fire | Left mouse button | Right trigger |
| Reload | R | X |
| Pick blaster | 1, 2, 3, mouse wheel, Q / E | Shoulder buttons |
| Scoreboard | Tab (hold) | Back |
| Pause | Esc or P | Start |

**Version 0.1.1.** v0.1.0 passed user acceptance testing on 2026-11-15; 0.1.1 is a hardening and docs release
(see [docs/ROADMAP.md](docs/ROADMAP.md)).

## What's in it right now

- **Backyard Battle**: a five-minute free-for-all against 2–5 bots (Easy, Normal or Hard).
- **Gun Game**: every tag swaps your blaster for the next one on the ladder. Score a tag with the Chainstorm to win.
- **Backyard Fortress** arena: blue and orange forts, a treehouse with walkways, a slide and trampolines,
  Mirror Alley (two ricochet mirrors) and Windy Way (a giant fan that bends darts sideways).
- Real foam-dart physics: darts drop, slow down, curve in the wind and ricochet off mirrors (+50 bonus for a ricochet tag).
- Ammo buckets that drain and refill themselves. The Chainstorm empties them fast.
- Bullseye targets for practice (+10 points).
- Settings for mouse sensitivity, FOV, **camera shake**, **visual effects intensity**, volume and fullscreen,
  with a **Reset to defaults** button.
- Alt-tabbing out of a match pauses it automatically.

## For developers

- `./tools/validate.sh` imports the project, compiles every script with warnings treated as errors, boots the menu
  and a match headless, runs 130 automated tests, and checks for leaks at exit.
- Start with [`CLAUDE.md`](CLAUDE.md), then read [`docs/`](docs/):

| Doc | What it's for |
|---|---|
| [GDD.md](docs/GDD.md) | **The** game design: concept, brief traceability, gameplay, blasters, arena, feature specs |
| [CONCEPT_BRIEF.md](docs/CONCEPT_BRIEF.md) | The original brief that started it all, archived word for word |
| [TUNING.md](docs/TUNING.md) | Change blasters, darts, bots and modes in the Godot inspector, no code needed |
| [UAT.md](docs/UAT.md) | The hands-on acceptance test script and results log |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the code fits together, safeguards, performance budgets |
| [ROADMAP.md](docs/ROADMAP.md) | What's done and what's next |
| [DECISIONS.md](docs/DECISIONS.md) | Why things are the way they are |

All art and sound is generated in code from Godot primitives, so there are no third-party assets and nothing to licence.
See [`assets/README.md`](assets/README.md).
