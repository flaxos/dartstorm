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

### D-010: Runtime navmesh bake
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
