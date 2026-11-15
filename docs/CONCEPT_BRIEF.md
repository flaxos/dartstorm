# DARTSTORM — Original Concept Brief (archived verbatim)

> **Provenance.** This is the brief that started the project. Sam wrote it, building on ideas he and his kids
> developed together with Flax, and gave it to Claude Code at the first development session on 2026-11-15.
> It is kept here **word for word** as a historical record of the original vision.
>
> **Authority.** The brief is the *why*. [`GDD.md`](GDD.md) is the *what*: the authoritative, current description
> of the game. Where they differ (numbers, scope, order of work), the GDD wins. GDD §1 summarises the brief,
> and GDD §2 tracks every brief requirement against what has been built.

---

# PROJECT: DARTSTORM — ELEMENTAL ARENA
## Godot 4 | 3D Foam-Dart Arena Shooter

You are the lead game developer, technical architect, gameplay programmer and game designer for a new indie game called **DARTSTORM: Elemental Arena**.

Your mission is to build a playable, family-friendly, 3D foam-dart arena shooter using **Godot 4 and GDScript**.

This is a real game development project, not a documentation exercise.

The game is being created by a dad, Sam, for his kids, based on ideas they developed together with Flax.

Prioritise getting something fun, visually appealing and playable as quickly as possible.

**DO NOT stop after creating a GDD or project skeleton. Start implementing the game.**

---

# 1. GAME VISION

DARTSTORM is a colourful, chaotic first-person foam-dart shooter inspired by backyard blaster battles, classic arena shooters and creative elemental environments.

Imagine:

- Blue team versus orange team.
- Massive backyard forts and obstacle courses.
- Foam-dart weapons with orange safety tips.
- Buckets full of foam darts to collect for ammunition.
- Giant belt-fed rotary blasters.
- Wind that physically changes dart trajectories.
- Reflective surfaces that allow ricochet shots.
- Fire, lightning, ice and wind-themed arenas.
- Upgradable blasters and character customisation.
- Gun Game, team battles and free-for-all.
- Friendly bots so the kids can play alone.
- Eventually, multiplayer with friends and family.

The game's personality should be playful, energetic, colourful and slightly ridiculous.

**Core philosophy: Easy to play, difficult to master, enormously fun to experiment with.**

No gore, realistic injuries, realistic firearms or military simulation.

All combat is cartoon-style tagging with foam darts. Tagged players burst into colourful foam particles and respawn.

Use original DARTSTORM branding and assets rather than licensed Nerf logos or product designs.

# 2. TECHNICAL STACK

- Engine: Latest locally installed stable Godot 4 release.
- Language: GDScript.
- Game type: 3D first-person shooter.
- Primary target: Windows PC.
- Secondary target: Linux.
- Input: Keyboard, mouse, with gamepad support planned.
- Multiplayer: Architect for future expansion, but implement offline single-player against bots first.
- Graphics: Stylised low-poly / colourful cartoon aesthetic.
- Physics: Godot 3D physics system.
- Repository: Git.
- Development method: Incremental, independently playable vertical slices.

Do not introduce external frameworks unless genuinely required.

Prefer native Godot nodes, resources, signals and scenes.

Use reusable, data-driven systems rather than hard-coding each weapon.

# 3. FIRST PLAYABLE GAME

Build a playable prototype called **Backyard Battle**.

It must include:

### Player controller
- First-person camera.
- WASD movement.
- Mouse aiming.
- Jumping.
- Sprinting.
- Smooth acceleration.
- Collision handling.
- A visible blaster held in front of the player.
- Crosshair and basic HUD.

### Combat
- Actual moving foam-dart projectiles.
- Gravity and visible projectile drop.
- Projectile collision detection.
- Basic wind effects.
- Reflective surfaces and ricochets.
- Colourful hit effects.
- Player health represented as a tag meter.
- Tagging and respawning.

### Weapons

Implement three starting weapons:

**1. Pocket Popper**
- Semi-automatic foam-dart pistol.
- Low ammunition capacity.
- Accurate and easy to use.
- Fast reload.

**2. Dart Sprayer**
- Fully automatic blaster.
- Fast firing rate.
- Moderate spread.
- Larger dart magazine.

**3. FLAX'S CHAINSTORM**
- Oversized, belt-fed rotary foam-dart cannon.
- Large backpack ammunition container.
- Visible ammunition belt.
- Rotating barrels.
- Spin-up before firing.
- Extremely high firing rate.
- Strong visual and audio feedback.
- Large ammunition capacity.
- Movement-speed penalty while firing.

This weapon should feel hilariously overpowered and be a highlight of the game.

Use procedural geometry and simple meshes for the prototype. Do not block development waiting for 3D artwork.

### Arena

Create a colourful outdoor backyard fortress containing:

- Blue team base.
- Orange team base.
- Multiple elevations.
- Ramps and platforms.
- Foam barriers.
- Crates and cover.
- A treehouse-style structure.
- Elevated walkways.
- Two reflective panels.
- One clearly visible wind zone.
- Ammunition refill buckets.
- Distinctive landmarks for navigation.

Build the map from primitive geometry first.

Design it around combat encounters and movement rather than decoration.

### Bots

Create at least two functional computer-controlled opponents.

They must:
- Move around the arena.
- Find opponents.
- Aim and fire.
- React to being tagged.
- Respawn.
- Navigate around basic obstacles.
- Have configurable difficulty.

Keep the AI simple but functional. Use Godot navigation where appropriate.

### Match system

Implement:

- Five-minute round.
- Free-for-all scoring.
- Scoreboard.
- Kill/tag feed.
- Match countdown.
- Respawn timer.
- End-of-round results.
- Restart match option.

**Definition of success: Sam can launch Godot, press Play, run around a colourful arena, shoot moving foam darts at bots, get tags, refill ammunition and finish a match.**

# 4. PHYSICAL DART SYSTEM

This is one of the game's defining systems.

Darts must behave like physical projectiles rather than instant-hit laser weapons.

Each dart should support configurable properties:

- Initial velocity.
- Gravity multiplier.
- Mass or effective wind responsiveness.
- Air drag.
- Collision layers.
- Maximum lifetime.
- Ricochet count.
- Surface interaction.
- Elemental effects.
- Team identification.
- Source weapon.
- Source player.

Projectile motion should behave approximately as:

velocity += (gravity + wind_acceleration) * delta

position += velocity * delta

Use physics-safe collision checks, preferably a swept segment or shape query to prevent fast projectiles passing through objects.

Develop a configurable DartProjectile system reusable across every weapon.

**Wind behaviour**

Create a WindZone scene with:
- Direction.
- Strength.
- Area dimensions.
- Visible particle or ribbon effects.
- An arrow or windsock indicating wind direction.

Darts travelling through wind zones must visibly curve.

The wind system should also be designed to support future dynamic weather.

**Ricochet behaviour**

Create a ReflectiveSurface scene.

When a dart hits the surface:
- Calculate the reflection vector using the collision normal.
- Reduce projectile speed.
- Continue travelling.
- Increment its ricochet count.
- Prevent immediate repeat collision with the same surface.

Different projectile types may have different ricochet limits.

Award a bonus for successful ricochet tags.

# 5. GAME FEEL

Make firing a toy blaster satisfying.

Implement:
- Muzzle flashes.
- Dart launch sounds.
- Subtle camera shake.
- Weapon recoil animation.
- Flying dart trails.
- Colourful foam hit particles.
- Clear hit confirmation.
- Arcade-style scoring popups.
- Fun tag sound effects.
- Distinctive Chainstorm barrel-spin feedback.

Avoid excessive screen shake, flashing or visual clutter.

Expose visual intensity and camera shake as settings.

Prioritise responsive controls and visual feedback over graphical complexity.

# 6. GUN GAME MODE

Once basic free-for-all works, implement Gun Game.

Players start with the weakest weapon.

Each successful tag advances them through a predefined weapon ladder.

Proposed progression:

1. Pocket Popper.
2. Double Trouble.
3. Dart Sprayer.
4. Foam Hammer.
5. Ricochet Ranger.
6. Wind Whisperer.
7. Longshot.
8. Thunder Cannon.
9. Rocket Dart.
10. Flax's Chainstorm.

For the first implementation, only three functional weapons are required.

The full weapon ladder can be introduced incrementally.

Store the weapon progression in data so new weapons can be added without rewriting the match controller.

# 7. ELEMENTAL ARENAS

Design the architecture for these future environments:

**Backyard Fortress**
Classic blue-versus-orange arena with treehouses, buckets and forts.

**Tempest Treehouse**
Wind tunnels, powerful gusts, vertical movement and long-distance curved shots.

**Ember Workshop**
Glowing fire effects, moving platforms, heat vents and temporary flame barriers.

**Thunder Playground**
Lightning storms, electrical relays, energy boosts and interactive machinery.

**Prism Palace**
Reflective walls, mirrors, glass platforms and creative ricochet opportunities.

**Frost Factory**
Ice slides, slippery surfaces, frozen darts and moving environmental obstacles.

Do not build all these maps immediately.

Document the intended architecture, then focus on completing Backyard Fortress.

Fire and lightning are playful elemental effects, not realistic burns or electrocution.

# 8. AMMUNITION BUCKETS

Create reusable AmmoBucket scenes.

Each bucket should:
- Contain a configurable amount of ammunition.
- Have a clear team or neutral colour.
- Detect nearby players.
- Refill compatible weapons.
- Have a visual indication when empty.
- Regenerate ammunition after a configurable delay.

Give the Chainstorm a high ammunition consumption rate so controlling buckets matters strategically.

Later, buckets can become capturable team objectives.

# 9. WEAPON PROGRESSION

Weapons should eventually support:

- XP and weapon mastery levels.
- Magazine capacity upgrades.
- Accuracy upgrades.
- Rate-of-fire modifications.
- Projectile speed upgrades.
- Cosmetic skins.
- Alternate dart types.
- Elemental modifications.
- Fun barrel and ammunition customisation.

Build the weapon system using configurable Godot Resource files.

Separate weapon configuration, weapon presentation and runtime firing behaviour.

Do not implement a complete progression economy until the core combat is enjoyable.

No microtransactions, loot boxes or paid gameplay advantages.

# 10. USER INTERFACE

Create a polished but simple arcade HUD.

Display:
- Crosshair.
- Weapon name.
- Ammo remaining.
- Tag meter.
- Match timer.
- Score.
- Wind indicator.
- Small hit confirmation.
- Ricochet bonus notification.

Style:
- Deep blue backgrounds.
- Vibrant orange highlights.
- Rounded modern UI.
- Chunky readable fonts.
- Clear silhouettes and icons.
- Cartoon-styled visual effects.

Include a basic main menu, settings screen and pause menu.

# 11. PROJECT STRUCTURE

Use a maintainable Godot project layout similar to:

dartstorm/
- project.godot
- README.md
- CLAUDE.md
- docs/
  - GDD.md
  - ARCHITECTURE.md
  - ROADMAP.md
  - DECISIONS.md
- scenes/
  - player/
  - weapons/
  - projectiles/
  - arenas/
  - enemies/
  - pickups/
  - effects/
  - ui/
- scripts/
  - core/
  - combat/
  - ai/
  - systems/
- resources/
  - weapons/
  - balance/
- assets/
  - models/
  - materials/
  - sounds/
  - textures/
- tests/

This is a suggested structure, not a rigid requirement.

Organise by ownership and responsibilities. Avoid unnecessary abstractions.

Use version control from the start.

# 12. DEVELOPMENT PHASES

## Phase 0 — Bootstrap
Create the Godot project, Git repository, architecture notes, README, development instructions and initial playable scene.

## Phase 1 — Movement and Arena
Implement first-person controls, collision, a basic backyard level and working camera.

## Phase 2 — Dart Physics
Implement projectile firing, gravity, collision, wind and ricochets.

## Phase 3 — Weapons
Create Pocket Popper, Dart Sprayer and Flax's Chainstorm.

## Phase 4 — Combat
Implement hit detection, bots, tagging, scores, ammunition buckets, respawns and the round timer.

## Phase 5 — Game Feel
Improve materials, models, effects, sound, UI, animations and overall responsiveness.

## Phase 6 — Gun Game
Introduce automatic weapon progression and win conditions.

## Phase 7 — Expansion
Additional arenas, elemental weapons, customisation, better AI and multiplayer.

Every phase should end with a functional, testable build.

Do not work on Phase 7 while the first playable match remains broken.

# 13. ENGINEERING REQUIREMENTS

Write production-quality GDScript appropriate for a small indie game.

Requirements:
- Typed GDScript where practical.
- Clear scene ownership.
- Signals for decoupled communication.
- Reusable Resource definitions.
- Avoid unnecessary singletons.
- Sensible error handling.
- No unresolved references.
- No fabricated third-party assets.
- No placeholder functions that prevent playing.
- No TODO-only implementations for core features.
- No undocumented critical assumptions.

Use procedural or built-in Godot geometry and original generated materials where practical.

Do not require Sam to install commercial plugins or buy assets.

If external assets are introduced, document their source and licence.

### Verification

If the Godot executable is available:
- Verify the engine version.
- Import the project.
- Run available headless validation.
- Check scripts and scene references.
- Run automated tests where practical.
- Fix errors before claiming completion.

If the executable is unavailable:
- Provide the exact local setup and validation commands.
- State clearly what remains unverified.
- Do not claim the project has been run.

Aim for smooth performance on a typical mid-range gaming PC.

Keep projectile counts bounded and prepare for object pooling where needed.

# 14. WORKING WITH SAM

Sam is building this for his kids.

Do not assume he wants to spend weeks configuring development tooling.

Make the workflow simple.

At each milestone:
1. Explain what has been built.
2. Explain exactly how to launch and test it.
3. Describe what the player should see.
4. Report known issues.
5. Identify the next highest-value development task.

Use reasonable defaults and proceed without unnecessary clarification.

Ask Sam questions only when a choice would materially alter the game or its scope.

Do not spend multiple sessions designing systems that have no playable implementation.

When a feature is completed, update the documentation and roadmap.

# 15. REQUIRED DOCUMENTATION

Maintain four living documents:

**GDD.md**
The authoritative description of gameplay, weapons, maps, modes and mechanics.

**ARCHITECTURE.md**
Scene structure, major systems, data ownership and integration decisions.

**ROADMAP.md**
Milestones, priorities, completed work, active tasks and acceptance criteria.

**DECISIONS.md**
Important architectural decisions, alternatives considered and reasons.

Create a CLAUDE.md at the repository root containing instructions for future Claude Code sessions.

A new session should be able to understand the current project, run the game and resume development without needing the entire conversation history.

# 16. FIRST EXECUTION INSTRUCTIONS

Begin now.

First:
1. Inspect the current working directory and available development tools.
2. Check whether a Godot project or Git repository already exists. Preserve existing work.
3. Confirm the installed Godot version and available command-line tools.
4. Create the project only if one doesn't already exist.
5. Initialise the required documentation and Git configuration.
6. Implement the first playable scene.
7. Add keyboard-and-mouse movement.
8. Add a basic foam-dart blaster.
9. Add working projectile physics and a target that reacts to hits.
10. Validate the project and provide launch instructions.

Then continue implementing the vertical slice according to the roadmap.

**Do not ask for permission between ordinary development steps.**

Prioritise writing working code, building functional Godot scenes and validating them.

If the full vertical slice cannot be completed in one session, leave the project in a playable state, document exactly what works, and identify the next implementation step.

The immediate objective is:

**A player can launch DARTSTORM, move around a colourful 3D backyard arena, fire foam darts, and successfully hit a target.**

Everything else grows from that working foundation.

# 17. THE MOST IMPORTANT RULE

This is a game being made for kids who are excited about their idea.

Prioritise the things they can see, interact with, laugh at and play.

Make it fun.

Make it colourful.

Make Flax's Chainstorm absolutely ridiculous.

**BUILD THE GAME.**
