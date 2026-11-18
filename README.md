# DARTSTORM: Elemental Arena

A colourful, family-friendly, first-person **foam-dart arena shooter** made with Godot 4.
Blue team versus orange team, backyard forts, buckets of darts, wind that bends your shots,
mirrors you can bounce darts off, elemental reactions (Wind, Fire, Water, Lightning, Ice),
and **FLAX'S CHAINSTORM**: a ridiculous belt-fed, six-barrel foam cannon.

No gore and no real-world guns. Tagged players pop into a shower of foam confetti and respawn.
Zero pay-to-win, zero microtransactions, and 100% kid-safe.

---

## How to Install & Play

### Option 1: Standalone Linux Release (No Godot Required)
Build a portable, double-clickable standalone Linux release with the included build tool:
```bash
./tools/export_linux.sh
```
This produces:
- `build/linux/DARTSTORM/`: A self-contained folder containing the 64-bit executable (`DARTSTORM.x86_64`), icon, and desktop shortcut installer.
- `build/DARTSTORM-0.7.0-linux-x86_64.tar.gz`: A compressed archive ready to copy to any 64-bit Linux PC.

**To install and launch on any 64-bit Linux desktop:**
1. Extract the archive or open `build/linux/DARTSTORM/`.
2. Double-click `DARTSTORM.x86_64` to play immediately, **OR**
3. Run `./install-shortcut.sh` once in that directory (or in a terminal) to install DARTSTORM with its icon into your Linux application launcher menu and desktop.
4. *(To uninstall the desktop shortcut later: `./install-shortcut.sh --remove`)*.

> *Note: Building the release requires Godot's export templates. In the Godot editor, select **Editor > Manage Export Templates** to install them once.*

### Option 2: Run From Source (with Godot Engine)
1. Download and run **Godot 4.4 or newer** (Standard build, not .NET) from <https://godotengine.org/download>.
2. Open Godot, click **Import**, select this repository's `project.godot`, and click **Import & Edit**.
3. Press **F5** (or click the ▶ Play button in the top right).

### Option 3: Terminal Quick Launch
You can also run directly from your terminal using the helper script:
```bash
./tools/run.sh          # Launch the game (Main Menu)
./tools/run.sh editor   # Open the project in the Godot Editor
./tools/run.sh demo     # Watch an automated 20-second gameplay demo
```

---

## Controls

Fully playable with keyboard & mouse or any standard gamepad (Xbox, PlayStation, Logitech, etc.). Controllers are plug-and-play with automatic hot-plugging, aim assist, and rumble.

| Action | Keyboard / Mouse | Gamepad / Controller |
|---|---|---|
| **Move** | W A S D / Arrow keys | Left stick |
| **Look / Aim** | Mouse | Right stick (curved response + aim assist) |
| **Jump** | Space | A / Cross |
| **Sprint** | Shift (while moving forward) | LT, or click Left Stick (L3) |
| **Fire Blaster** | Left Mouse Button | Right Trigger (RT / R2) |
| **Zombie Claw Swipe** | Left Mouse Button (when Zombie) | Right Trigger (RT / R2) |
| **Reload** | R | X / Square |
| **Switch Blaster** | 1, 2, 3, Scroll Wheel, Q / E | Y / Triangle, LB, RB |
| **Scoreboard** | Tab (hold) | Back / View / Share |
| **Pause Game** | Esc or P | Start / Menu / Options |
| **Menu Navigation** | Mouse or Arrow keys + Enter | D-pad or Left Stick |
| **Menu Select / Back** | Enter / Esc | A to Select, B to Go Back |

---

## Game Modes

Choose from 6 distinct match types in the 3D lobby:

1. **SOLO (Backyard Battle):** Fast-paced 5-minute free-for-all against 2–7 bots.
2. **DUOS:** Partner with a bot buddy against competing rival duos. Shared team colors and combined scores.
3. **TEAMS (Blue vs Orange):** Large-scale team battles (up to 4 v 4). No friendly fire, home-base respawns, live team score chips, and team podium ceremonies.
4. **GUN GAME:** 10-rung elemental blaster progression ladder. Every tag advances your weapon; score a tag with Flax's Chainstorm on the final rung to win.
5. **ZOMBIES:** Asymmetrical infection tag. 1 player/bot begins as the high-speed green foam Alpha Zombie. Tagged survivors turn into zombies. Survivors win if anyone survives the 180s round timer!
6. **ZOMBIE SIEGE (Base Defense):** Co-op horde survival. Defend the 1000 HP physical **Base Core** and 4 choke-point **Barricades** across 5 escalating waves of Runners, Brutes, and the 3.5m **Mega Foam Titan Boss**. Collect Scrap from tagged zombies and fortify during 20s intermissions.

---

## Arenas

Select your battleground in the lobby:

- **Backyard Fortress:** The classic outdoor arena with Blue & Orange Forts, connecting rope walkways, a slide, trampolines, Mirror Alley (ricochet shots), and Windy Way (giant fan that curves darts).
- **Home Turf:** A full house where you are shrunk to toy scale! Chairs are stepping stones, beds are trampolines, the kitchen has a giant table fan, and an orange toy race-track ramp leads onto the patio roof.
- **Tempest Treehouse:** A high-canopy ancient tree grove. Features dual canopy fort decks at $Y=5.4\text{ m}$, a swaying suspension rope bridge spanning the central chasm, kinetic jump-pads, an escape ice slide chute (+9.5 m/s boost), an upward buoyant forest-floor wind vent, and a high Crow's Nest at $Y=10.5\text{ m}$.

---

## Progression, Coin Shop & Blaster Skins

Directly inspired by the young players' design sketches:
- **Leveling & XP:** Earn XP from tags, ricochets, match finishes, and victories. Level up with clean visual badges on your Player Card in the lobby.
- **Backyard Missions:** 3 active dynamic objectives (e.g., ricochet tags, ice slides, lightning zaps, shield absorbs) that award bonus XP and Coins.
- **100% Kid-Safe Coin Shop:** Strictly one currency (Coins) earned solely through gameplay. Zero real money, zero microtransactions, and zero paid power.
- **Customization:**
  - **Hats:** 11 fun wearable hats (Party Hat, Cowboy, Propeller, Goggles, Bunny Ears, Horns, Spiky Hair, Champion Crown, etc.).
  - **Color Swatches:** Custom player and dart colors (Bubblegum Pink, Electric Teal, Golden Yellow, etc.).
  - **Blaster Skins:** 8 collectible tactile skins powered by an anti-slop PBR shader pipeline (Default Orange, Nitro Neon, Cyber Circuit, Hazard Stripe, Cosmic Galaxy, Dino Scales, Holo Prismatic, and Toxic Slime).

---

## Elemental Combat & Hazards

- **Elemental Darts:** Wind (micro-lift), Fire (sparkle tick), Water (high knockback), Lightning (chain zap), and Ice (chilling slow & slide boost).
- **Elemental Reactions:** Combine elements for emergent effects (Water + Lightning = Conductive shock; Fire + Water = Steam clouds).
- **World Hazards:**
  - **Foam Shield (`ShieldPickup`):** Holographic hexagonal bubble absorbing 50 tag points before popping.
  - **Water Puddles:** Conduct electricity across the surface when hit by lightning darts.
  - **Ice Slicks:** Zero friction slide-boosts along slopes and ramps (+9.5 m/s).
  - **Wind Vents:** Upward air drafts launching players into the air while catching and amplifying elemental dart clouds.

---

## For Developers

- `./tools/validate.sh`: Comprehensive automated test runner. Imports the project, compiles all 65 scripts with warnings treated as errors, boots the main menu and match headless, runs **518 automated unit and integration tests**, and verifies zero memory leaks at exit.
- `./tools/export_linux.sh`: Builds and packages the standalone Linux release, running headless smoke tests on the exported binary.
- `./tools/check_scripts.gd`: Strict compiler validation (fails on any GDScript warning).
- `./tools/generate_skins.py`: Generates the 8 seamless 1024x1024 vector pattern textures used by the tri-planar blaster shader.

### Documentation Map
Start with [`CLAUDE.md`](CLAUDE.md) for architectural guidelines and session notes, then see [`docs/`](docs/):

| Document | Purpose |
|---|---|
| [GDD.md](docs/GDD.md) | **Authoritative Game Design Document**: mechanics, weapons, arenas, and feature specs |
| [CONCEPT_BRIEF.md](docs/CONCEPT_BRIEF.md) | Original brief and young players' design sketch, archived verbatim |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Systems architecture, data ownership, safeguards, and performance budgets |
| [TUNING.md](docs/TUNING.md) | Inspector tuning guide for blasters, darts, bots, and game modes (no coding needed) |
| [ROADMAP.md](docs/ROADMAP.md) | Release milestones, current status, and changelogs |
| [DECISIONS.md](docs/DECISIONS.md) | Architectural decision records (D-001 through D-038) |
| [UAT.md](docs/UAT.md) | User Acceptance Testing scripts and results log |
| [assets/README.md](assets/README.md) | Asset provenance, procedural generation notes, and open-source licenses |

All models, sounds, music, patterns, and visual effects are procedurally generated in code from Godot primitives. The sole external asset is the open-source **Lilita One** display font (SIL Open Font License 1.1).
See [`assets/README.md`](assets/README.md).
