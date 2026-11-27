# DARTSTORM: Elemental Arena

A colourful, family-friendly, first-person **foam-dart arena shooter** made with Godot 4.
Blue team versus orange team, backyard forts, buckets of darts, wind that bends your shots,
mirrors you can bounce darts off, elemental reactions (Wind, Fire, Water, Lightning, Ice),
and **FLAX'S CHAINSTORM**: a ridiculous belt-fed, six-barrel foam cannon.

No gore and no real-world guns. Tagged players pop into a shower of foam confetti and respawn.
Zero pay-to-win, zero microtransactions, and 100% kid-safe.

---

## How to Install & Play

### Option 1: Standalone Releases (Windows `.exe` & Linux — No Godot Required)
Build double-clickable standalone releases with the included build tools:
```bash
./tools/export_windows.sh   # -> build/windows/DARTSTORM/DARTSTORM.exe + zip archive
./tools/export_linux.sh     # -> build/linux/DARTSTORM/DARTSTORM.x86_64 + tar.gz archive
```
- **Windows (64-bit):** Extract `build/DARTSTORM-1.0.0-windows-x86_64.zip` and double-click `DARTSTORM.exe` (single self-contained executable with embedded data).
- **Linux (64-bit):** Extract `build/DARTSTORM-1.0.0-linux-x86_64.tar.gz` and double-click `DARTSTORM.x86_64`, or run `./install-shortcut.sh` once to add DARTSTORM to your application menu (`./install-shortcut.sh --remove` to uninstall).

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
| **Sprint** | Shift (while moving forward) | Click Left Stick (L3) |
| **Aim Down Sights (ADS)** | Right Mouse Button | Left Trigger (LT / L2) |
| **Fire Blaster** | Left Mouse Button | Right Trigger (RT / R2) |
| **Zombie Claw Swipe** | Left Mouse Button (when Zombie) | Right Trigger (RT / R2) |
| **Foam Grenade** | G / Middle Mouse | D-Pad Down |
| **Interact (Plant / Defuse / Repair)** | F / E | D-Pad Right |
| **Reload** | R | X / Square |
| **Squad Ping** | T | D-Pad Up |
| **Switch Weapon / Foam Bat** | 1–5, Scroll Wheel, Q / E | Y / Triangle, LB, RB |
| **Scoreboard** | Tab (hold) | Back / View / Share |
| **Pause Game** | Esc or P | Start / Menu / Options |
| **Menu Navigation** | Mouse or Arrow keys + Enter | D-pad or Left Stick |
| **Menu Select / Back** | Enter / Esc | A to Select, B to Go Back |

---

## Game Modes

Choose from **10 distinct match types** in the 3D lobby (solo, 2-player couch split-screen, or LAN/online WebSocket multiplayer):

1. **SOLO (Backyard Battle):** Fast-paced 5-minute free-for-all against 2–7 bots.
2. **GUN GAME:** 11-rung elemental blaster progression ladder. Every tag advances your weapon — climb past Flax's Chainstorm and land the final melee bonk with the **Foam Bat** to win!
3. **DUOS:** Partner with a bot buddy (or Player 2 in split-screen) against competing rival duos with coordinated buddy spawning and squad pings.
4. **TEAMS (Blue vs Orange):** Large-scale team battles (up to 4 v 4) with no friendly fire, home-base respawns, live team score chips, and team podium ceremonies.
5. **ZOMBIES:** Asymmetrical infection tag. 1 Alpha Zombie hunts survivors; tagged survivors join the green foam horde.
6. **ZOMBIE SIEGE (Base Defense):** Co-op horde survival across 5 escalating waves defending the physical **Base Core** and 4 **Barricades** against Runners, Brutes, and the **Mega Foam Titan Boss**.
7. **FLOOR IS LAVA:** Dynamic molten-foam tides flood the arena floor; cool the lava with Water or Ice darts to create solid obsidian stepping stones!
8. **REALISTIC:** High-stakes tactical tagging with lowered tag thresholds and minimal HUD assistance.
9. **CAPTURE THE FLAG (CTF):** Grab the rival team's flag from their pedestal and carry it home while defending your own.
10. **PLANT THE BOMB:** Round-based Attackers vs Defenders objective mode at explicit Site A & Site B zones with arming, defusing, and tactical callouts.

---

## Arenas

Select from **9 handcrafted stylized arenas** in the lobby (with live 3D arena backdrop preview and bespoke per-arena AgX atmospheric lighting):

- **Backyard Fortress:** Classic outdoor fort-vs-fort yard with walkways, trampolines, Mirror Alley, Windy Way, dog house, and paddling pool.
- **Home Turf:** Toy-scale family house with furnished rooms, bouncy beds, kitchen wind fan, and patio roof ramp.
- **Tempest Treehouse:** Multi-tier ancient canopy grove with suspension rope bridge, jump-pads, ice slide chute, and high Crow's Nest.
- **Playground:** Vibrant park playground with climbing towers, slides, sandpits, and fast vertical sightlines.
- **Sunny Park:** Open sunlit park with bandstand pavilion, pond bridges, gazebo cover, and winding paths.
- **Soccer Stadium:** Floodlit twilight stadium with pitch cover, grandstand sidelines, and golden-cyan night lighting.
- **Two Fortresses:** Classic dual-fort valley connected by a covered wooden bridge over an open moat, navigable basement vaults, water tunnels, and sniper battlements.
- **Dusty Courtyard:** Sun-baked sandstone desert courtyard with sunken underpass, sniper bridge, open central arch, and Sites A & B.
- **Duststorm II:** Faithful stylized desert tactical arena with Long A, Pit ramp, Mid/Lower B Tunnel, Catwalk, and Sites A & B.

---

## HUD, Tactical Radar, Workbench & Progression

Directly inspired by the young players' design sketches:
- **Tactical Radar / Minimap:** Rotating circular top-right radar tracking arena cover, teammates, gunfire/proximity rivals, bomb sites, CTF flags, Base Core, and ammo buckets, paired with directional damage arcs and dynamic hitmarkers.
- **Garage Workbench & Weapon Mastery:** Earn Weapon XP and unlock barrels, optics, magazines, grips, and stocks for 7 modular blasters in the interactive 3D Garage Workbench.
- **Leveling, Missions & 100% Kid-Safe Coin Shop:** Earn XP and Coins purely through gameplay. Unlock 11 wearable hats, custom jersey/dart color swatches, and 8 anti-slop triplanar blaster skins with 5 PBR finishes (Matte, Gloss, Metallic, Holographic, Emissive). Zero real money, zero microtransactions, zero pay-to-win.

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

- `./tools/validate.sh`: Comprehensive automated test runner. Imports the project, compiles all scripts with warnings treated as errors, boots the main menu and match headless, runs the full automated unit & integration test suite, and verifies zero memory leaks at exit.
- `./tools/export_windows.sh` / `./tools/export_linux.sh`: Build standalone Windows `.exe` and Linux releases.
- `./tools/export_web.sh` / `./tools/export_apk.sh` / `./tools/export_server.sh`: Build HTML5/WASM web, Android APK, and Linux Dedicated Server releases.
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
| [DECISIONS.md](docs/DECISIONS.md) | Architectural decision records (D-001 through D-048) |
| [UAT.md](docs/UAT.md) | User Acceptance Testing scripts and results log |
| [assets/README.md](assets/README.md) | Asset provenance, procedural generation notes, and open-source licenses |

All models, sounds, music, patterns, and visual effects are procedurally generated in code from Godot primitives. The sole external asset is the open-source **Lilita One** display font (SIL Open Font License 1.1).
See [`assets/README.md`](assets/README.md).
