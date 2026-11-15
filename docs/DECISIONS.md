# DARTSTORM — Decisions

*Important choices, the alternatives considered, and why. Add new entries at the bottom.*

### D-001: Godot 4.4 + GDScript, Forward+
**Chosen:** Godot 4.4.1 (installed locally), typed GDScript, Forward+ renderer.
**Alternatives:** C#/.NET (needs the Mono build and SDK); the Compatibility renderer.
**Why:** No extra tooling for Sam; GDScript is quickest to iterate on. Forward+ gives glow and good
shadows on any mid-range gaming PC. The game uses no Forward+-only features, so it could be switched
to Compatibility for weaker machines.

### D-002: Build scenes and arenas in code, keep .tscn files thin
**Chosen:** each `.tscn` is a root node and a script. The script builds its children in `_ready()`.
Arenas use `ArenaKit` helpers (box, ramp, cylinder, deco…).
**Alternatives:** author everything in the Godot editor as big `.tscn` files.
**Why:** hand-written large `.tscn` files are fragile, and procedural primitives need no art. Code is
diffable, reviewable and testable headless. **Trade-off:** you can't drag arena pieces around in the
editor yet. When the layout stabilises, the arena could be "baked" into a real `.tscn` for designers.

### D-003: Darts are pooled nodes with manual ray sweeps, not RigidBody3D
**Chosen:** `Node3D` darts that integrate their own velocity and `intersect_ray` from the old to the new
position each physics tick.
**Alternatives:** RigidBody3D with continuous collision detection; ShapeCast3D per dart; hit-scan.
**Why:** exact control over the brief's formula (`v += (g + wind)·dt; p += v·dt`), no tunnelling at any
speed, cheap enough for the Chainstorm's 30 darts/s ×5 players, deterministic (helps future multiplayer),
and ricochet maths in one place. A ray (not a shape) is fine because actors have generous Area3D
hitboxes (D-006).

### D-004: Input actions registered in code
**Chosen:** `InputSetup.ensure_actions()` adds every action at startup, skipping any already defined in
Project Settings.
**Alternatives:** define them in `project.godot`.
**Why:** project.godot input entries are long serialized objects that are easy to corrupt by hand. One
readable table is easy to review and extend, and Sam can still override any binding from the editor.

### D-005: Procedural audio, no sound files
**Chosen:** `Sfx` synthesises every effect into `AudioStreamWAV` at startup.
**Alternatives:** CC0 sound packs.
**Why:** zero licensing risk and nothing to download, and it works now. Real recordings can replace any entry later
(the IDs stay the same).

### D-006: Forgiving hitboxes separate from the movement capsule
**Chosen:** each Actor has a `Hitbox` Area3D (radius 0.6 for bots, 0.45 for the player) on its own layer.
Darts hit the Area, not the CharacterBody.
**Why:** kids should land hits. The movement capsule stays tight for good collision, and the hit volume
can be tuned per difficulty without touching movement.

### D-007: Free-for-all = one team per actor
**Chosen:** `team_id` is unique per actor in FFA. Friendly-fire checks use `accepts_dart_from(team)`.
**Why:** the same code supports Blue vs Orange later by just assigning shared team IDs.

### D-008: Multiplayer is planned for, not implemented
**Chosen:** offline single-player against bots first. The architecture keeps the *brain* (Player input /
Bot AI) separate from the *body* (Actor), centralises tag decisions in MatchController and Actor, and makes
darts deterministic.
**Alternatives:** build networking from day one.
**Why:** the brief prioritises a playable game for the kids now. Expected future path: Godot high-level
multiplayer (ENet), with the server authoritative for tags and scores, clients sending input, and the server spawning darts.

### D-009: Two autoloads only
**Chosen:** `GameSettings` (preferences) and `Sfx` (audio bank). Everything else is owned by the match scene.
**Why:** the brief asks to avoid unnecessary singletons, and match state belonging to the scene makes restart trivial
(reload the scene).

### D-010: Runtime navmesh bake *(refined by D-014)*
**Chosen:** `Arena._bake_navigation()` bakes from static colliders when the arena loads.
**Alternatives:** pre-bake in the editor and save a `.res`.
**Why:** the arena is generated in code (D-002), so the navmesh always matches the geometry with no manual
step. If load time becomes a problem, cache the baked mesh to a resource.

### D-011: GameMode as a Resource with overridable hooks
**Chosen:** `GameMode` (FFA) and the `GunGameMode` subclass, configured in `.tres`. MatchController calls hooks.
**Why:** Gun Game's ladder lives in data (`ladder` array) as the brief requires, and new modes (team battle,
capture the bucket) won't need to touch MatchController.

### D-012: Bot dart power scales with difficulty; the player's hitbox is smaller
**Why:** a family game should be winnable. Easy bots need 8 Pocket Popper hits to tag you, Hard bots need 3, same as you.

### D-013: Losing window focus pauses the match (v0.1.1)
**Chosen:** `PauseMenu` listens for `NOTIFICATION_APPLICATION_FOCUS_OUT` and opens itself during the countdown or play.
The click that re-captures the mouse afterwards is swallowed (`Player._fire_blocked_until_release`).
**Alternatives:** keep playing in the background; only release the mouse.
**Why:** kids alt-tab, press the Windows key, or get a pop-up. Coming back to find you were tagged five times, or
firing a surprise dart, feels unfair. Unattended `--demo` runs are exempt so screenshots don't stall.

### D-014: Bake the navmesh on a worker thread (v0.1.1)
**Chosen:** `bake_navigation_mesh(true)` plus an `Arena.is_navigation_ready` flag / `navigation_ready` signal.
Bots steer straight at their goal until it's ready.
**Alternatives:** keep the synchronous bake (a visible hitch on slower PCs); pre-bake and save a `.res`
(goes stale whenever the code-built arena changes, see D-002).
**Why:** no hitch and no manual step. The bake and sync take about 20 frames, hidden by the 3 s countdown.

### D-015: Budget ordinary impact effects (v0.1.1)
**Chosen:** `FoamBurst` caps ordinary bursts at 6 started per frame and 48 alive, both scaled by the Visual effects
setting. Tag-out and respawn bursts are "important" and always shown.
**Alternatives:** pool CPUParticles3D nodes; GPU particles with one emitter per colour.
**Why:** the simplest change that bounds the worst case (five Chainstorms at a wall was about 450 nodes/s) without
losing the moments that matter. Pooling can come later if profiling asks for it.

### D-016: Validation treats GDScript warnings as errors (v0.1.1)
**Chosen:** `tools/check_scripts.gd` asks Godot which warnings are at "Warn" and writes them at "Error" into a
temporary `override.cfg`, then recompiles every script. `validate.sh` removes the file with a trap.
**Alternatives:** a single `debug/gdscript/warnings/treat_warnings_as_errors` switch (it had no effect when tested on
4.4.1); setting the levels permanently in `project.godot` (one stray warning would stop Sam's game from running at all).
**Why:** Sam opens the editor and sees zero yellow warnings, and new ones are caught by automation, not by
him. The game itself still runs normally with warnings.

### D-017: Archive the concept brief verbatim; the GDD is authoritative (v0.1.1)
**Chosen:** `docs/CONCEPT_BRIEF.md` keeps the original brief word for word. GDD §1 summarises it and GDD §2 traces
every requirement to its status.
**Alternatives:** paste the whole brief into the GDD; summary only.
**Why:** the brief is the family's original vision and worth keeping exactly. But the GDD must be free to
evolve (numbers, scope), so it is the single source of truth. The project owner chose this option on 2026-11-16.
The repo is public, so the brief's mention of Sam, Flax and the kids is public too, as are the existing README and
blaster names.

### D-018: No preload cycles; quit through Sfx (v0.1.1)
**Chosen:** `DartPool` loads `dart_projectile.tscn` at runtime instead of `preload`, because the dart script refers
back to `DartPool`. Every quit goes through `Sfx.quit_game()`, which stops all sounds, waits 0.4 s of real time
and then quits (re-entrant calls are ignored).
**Why:** the preload produced a "Busy" load error when the editor re-imported `dart_projectile.gd`. Quitting
mid-sound leaked audio playback objects (a 0.15 s wait still leaked in about 1 run in 4; 0.4 s was clean in 6 of 6), and a per-frame quit call leaked timers. validate.sh now fails on either.
