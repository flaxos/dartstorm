# DARTSTORM — Decisions

*Important choices, the alternatives considered, and why. Add new entries at the bottom.*

### D-001: Godot 4.4 + GDScript, Forward+
**Chosen:** Godot 4.4.1 (installed locally), typed GDScript, Forward+ renderer.
**Alternatives:** C#/.NET (needs the Mono build and SDK); the Compatibility renderer.
**Why:** No extra tooling for the project owner; GDScript is quickest to iterate on. Forward+ gives glow and good
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
readable table is easy to review and extend, and any binding can still be overridden from the editor.

### D-005: Procedural audio, no sound files
**Chosen:** `Sfx` synthesises every effect into `AudioStreamWAV` at startup.
**Alternatives:** CC0 sound packs.
**Why:** zero licensing risk and nothing to download, and it works now. Real recordings can replace any entry later
(the IDs stay the same).

### D-006: Forgiving hitboxes separate from the movement capsule
**Chosen:** each Actor has a `Hitbox` Area3D (radius 0.6 for bots, 0.45 for the player) on its own layer.
Darts hit the Area, not the CharacterBody.
**Why:** young players should land hits. The movement capsule stays tight for good collision, and the hit volume
can be tuned per difficulty without touching movement.

### D-007: Free-for-all = one team per actor
**Chosen:** `team_id` is unique per actor in FFA. Friendly-fire checks use `accepts_dart_from(team)`.
**Why:** the same code supports Blue vs Orange later by just assigning shared team IDs.

### D-008: Multiplayer is planned for, not implemented
**Chosen:** offline single-player against bots first. The architecture keeps the *brain* (Player input /
Bot AI) separate from the *body* (Actor), centralises tag decisions in MatchController and Actor, and makes
darts deterministic.
**Alternatives:** build networking from day one.
**Why:** the brief prioritises a playable game now. Expected future path: Godot high-level
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
**Why:** players alt-tab, press the Windows key, or get a pop-up. Coming back to find you were tagged five times, or
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
4.4.1); setting the levels permanently in `project.godot` (one stray warning would stop the game from running at all).
**Why:** opening the editor shows zero yellow warnings, and new ones are caught by automation, not by
a person. The game itself still runs normally with warnings.

### D-017: Archive the concept brief verbatim; the GDD is authoritative (v0.1.1)
**Chosen:** `docs/CONCEPT_BRIEF.md` keeps the original brief word for word (personal details redacted, D-019). GDD §1 summarises it and GDD §2 traces
every requirement to its status.
**Alternatives:** paste the whole brief into the GDD; summary only.
**Why:** the brief is the original vision and worth keeping exactly. But the GDD must be free to
evolve (numbers, scope), so it is the single source of truth. The project owner chose this option on 2026-11-16.
The repo is public, so personal details are redacted from the archived copy (D-019).

### D-018: No preload cycles; quit through Sfx (v0.1.1)
**Chosen:** `DartPool` loads `dart_projectile.tscn` at runtime instead of `preload`, because the dart script refers
back to `DartPool`. Every quit goes through `Sfx.quit_game()`, which stops all sounds, waits 0.4 s of real time
and then quits (re-entrant calls are ignored).
**Why:** the preload produced a "Busy" load error when the editor re-imported `dart_projectile.gd`. Quitting
mid-sound leaked audio playback objects (a 0.15 s wait still leaked in about 1 run in 4; 0.4 s was clean in 6 of 6), and a per-frame quit call leaked timers. validate.sh now fails on either.

### D-019: No personal information in the repo (v0.1.1)
**Chosen:** the docs, code comments, commits and PR descriptions don't name real people or describe family
relationships. The archived concept brief keeps its wording but redacts those details, marked in brackets.
"Flax's Chainstorm" stays as the blaster's in-game name.
**Why:** the repository is public, and the project owner asked for personal details to be removed (2026-11-16).
Neutral roles ("the project owner", "young players") say everything the docs need.
**Note:** this cleans the current files. Earlier commits on `main` (from PR #1) still contain the old wording in
git history until that history is rewritten.

### D-020: Lilita One, applied through the root window theme (v0.2.0)
**Chosen:** the OFL-licensed Lilita One font in `assets/fonts/`, used by `UiKit.font()` and set as the root window
theme's default font at startup by `GameSettings`.
**Alternatives:** keep the emboldened engine font; set `gui/theme/custom_font` in `project.godot`.
**Why:** the brief asks for chunky readable fonts. The project setting made a fresh checkout log an error on its very
first import (the font isn't imported yet), which would fail validation. The runtime theme avoids that.

### D-021: Procedural music rendered on worker threads (v0.2.0)
**Chosen:** two chiptune loops composed as data and rendered by `WorkerThreadPool` at startup.
**Alternatives:** CC0 music files; rendering on the main thread.
**Why:** it keeps the zero-audio-files rule (D-005) with no licensing. Rendering takes a moment, so it runs off the main
thread and the game never stalls. Every render is waited for before quitting.

### D-022: Chainstorm power-up mode is an option; the brief's default stays (v0.2.0)
**Chosen:** a menu toggle CHAINSTORM: EVERYONE / POWER-UP, defaulting to EVERYONE. Data lives on `GameMode`
(`power_weapon`, delays, belt); the switch is set on a per-match `duplicate()` of the mode.
**Why:** the brief lists the Chainstorm as a starting blaster, but making it a contested power-up may be more fun.
Let the players decide in UAT rather than changing the default unasked.

### D-023: Controller support design (v0.2.0)
**Chosen:** any-device bindings; A/B added to the UI actions; a curved right stick; aim assist that only *slows*
turning over a rival (never steers); rumble only while a pad is the active device; unplugging pauses.
**Why:** plug and play for young players on the couch, while keeping aim honest and avoiding surprise rumble for
keyboard players. No physical pad is available on the dev box, so it's tested with simulated input events.

### D-024: GameSettings shows device notices (no new autoload) (v0.2.0)
**Chosen:** `GameSettings` owns a small CanvasLayer for toasts like "controller connected".
**Alternatives:** a third autoload; per-scene toasts.
**Why:** notices must work on every screen. D-009 limits autoloads, and device state already lives in GameSettings.

### D-025: The podium floats in the sky above the arena (v0.2.0)
**Chosen:** a `top_level` Podium node at y=150, with its own camera, built when the match ends.
**Alternatives:** a separate results scene; podium props inside the yard.
**Why:** the arena's sky, sun and environment come for free, there's no scene change, and nothing in the yard needs
to make room. The camera is shifted right so the results panel doesn't cover the stage.

### D-026: World signs are single-sided (v0.2.0)
**Chosen:** `ArenaKit.sign_text()` sets `double_sided = false`.
**Why:** from behind, Label3D text shows mirrored ("YAW YDNIW" on the menu). Signs now read only from the front.

### D-027: The Linux build is one executable in a folder, with a shortcut helper (v0.2.0)
**Chosen:** an export preset "Linux" with the game data embedded in `DARTSTORM.x86_64`; `tools/export_linux.sh`
adds the icon, a README and `install-shortcut.sh` (an applications-menu entry plus a trusted desktop shortcut), packs a
`.tar.gz`, and boots the exported game headless as a smoke test. Settings move to `~/.local/share/dartstorm/` via
`config/use_custom_user_dir`.
**Alternatives:** AppImage or Flatpak; a separate `.pck` file; the default `~/.local/share/godot/app_userdata/...` path.
**Why:** the simplest thing a family can copy to a PC and launch. Many Linux file managers won't run a binary on
double-click, so the shortcut script gives a reliable fallback. The custom settings folder is easy to find and delete.
AppImage/Flatpak add tooling for no benefit at this size. The engine falls back to OpenGL on PCs without Vulkan.

### D-028: Rewards: earned coins, cosmetics only (v0.3.0, planned)
**Chosen:** one currency (coins) earned by playing and missions, spent only on looks. Levels from XP and a free reward
track are fine. No gems, no timers, no real money, no power for sale; weapon "upgrades" are cosmetic or sidegrades.
**Alternatives:** coins plus gems (as the players drew); no currency, levelling unlocks everything.
**Why:** the players asked for a shop, coins and a pass, and the brief allows progression once combat is fun. But a
second currency and paid-feeling systems copy mobile monetisation, and power upgrades would make games against
friends unfair. Chosen by the project owner on 2026-11-16.

### D-029: Team play reuses the free-for-all machinery (v0.3.0)
**Chosen:** a `teams` enum on GameMode plus `team_for()`. Solo modes give everyone their own team number, so scoring,
ranking and the podium have one code path. Team modes even the teams by adding a bot, override shirt colours with the
team colour, and let darts pass through team-mates (no friendly fire).
**Alternatives:** a separate TeamMatchController; friendly fire on; keeping personal colours in team games.
**Why:** much less code to keep in sync, and SOLO behaviour is unchanged (all earlier tests still pass). Young players
tagging a team-mate by accident is frustrating, and personal colours would make teams unreadable at a distance.

### D-030: The lobby is the players' drawing, on a floating island (v0.3.0)
**Chosen:** rebuild the main menu to the young players' sketch: a 3D island south of the yard with the squad on
platforms, the yard blurred behind, and their 2D layout (card + buttons left, modes right, logo bottom middle, PLAY
bottom right).
**Alternatives:** keep the orbiting overview menu; a separate lobby scene.
**Why:** seeing their own design in the game is the biggest appeal win available. Reusing the arena as the
backdrop keeps the sky, sun and backyard with no extra assets.

### D-031: Every place in DARTSTORM is fictional (v0.3.0)
**Chosen:** arenas (including the planned Home Turf) use invented names, generic layouts and rounded game-scale sizes.
No real addresses, street, suburb, park or shop names, people's names or reference photos go in the repo, commits or
PRs, even when a real place inspired the design.
**Why:** the repository is public and the players are children. A real name or an exact floor plan could point
strangers to a real home. This extends D-019.

### D-032: Home Turf is a toy-scale dollhouse (v0.4.0)
**Chosen:** build the house about ×3 real size with 9 m walls, 3.6 m doors and no roof; furniture is solid cover with
heights picked for one-jump steps (seats 1.2 m, tables 2.25 m); beds are trampolines; the patio roof is the one high
platform, reached by a ramp.
**Alternatives:** real scale; a roofed house with indoor lights; walls you can walk along.
**Why:** real rooms are too small for running and dart arcs. No roof keeps rooms sunlit and cheap to render, and lets
the overview camera see in. Walls too tall to climb keep fights inside the rooms. Furniture pushed against walls can
box in corners for bots, so walkways are at least 1.5 m (the dining chairs moved to the table ends for this reason).

### D-033: Elemental Reaction Engine & 2nd-Order Spring Dynamics (v0.5.0)
**Chosen:** attach an `ElementalEffect` component to `Actor` that processes status afflictions (Wind micro-lift, Fire sparkle tick, Water knockback/wet, Lightning chain zap, Ice slow & slide boost) and combos (Fire on Wet -> Steam cloud; Ice on Fire -> Flash steam; Lightning on Wet -> Conductive shock). Upgrade player viewmodel with 2nd-order damped harmonic spring dynamics for weapon inertia, landing dip, and sprint canting. Enable Forward+ Screen-Space Ambient Occlusion (SSAO), Screen-Space Reflections (SSR), and tactile rim lighting with Burley diffuse on materials.
**Alternatives:** complex stat machines with debuff stacks; static weapon transforms.
**Why:** keeps combat joyful, non-violent, and readable while introducing emergent tactical depth (e.g. wet targets conduct lightning; ice ramps boost slides). Spring physics give blasters a weighty, responsive, modern AAA feel without sacrificing responsive twitch aim.
### D-034: Zombies Mode Architecture & Infection Flow (v0.5.1)
**Chosen:** Implement `ZombieMode` extending `GameMode`, assigning 1 Alpha Zombie ("Patient Zero") at round start with Team 1 (`ZOMBIES`, `Color(0.38, 0.78, 0.28)`) and all other players to Team 0 (`SURVIVORS`, `Color(0.2, 0.6, 1.0)`). Zombies carry zero blasters (`get_loadout` returns `[]`), have increased sprint velocity (11.2 m/s), outstretched cartoon foam arms, and infectious melee touches via physical slide collisions and dedicated swipe attacks. Surviving victims tagged by zombies are converted to Team 1 on tag out (+150 infection score). Survivors counter horde charges using elemental darts (Water dart knockback, Ice dart frost slow), staggering zombies (+100 tag score). Early victory triggers if survivors reach 0; survivors win if any survive when match timer expires.
**Alternatives:** Spawning separate non-player zombie AI mobs; complex infection timers; infected players becoming spectators.
**Why:** Directly fulfills the young players' primary sketched mode (§1.9). Asymmetrical tag where players switch sides upon being tagged creates natural tension and thrilling comeback dynamics while preserving the cheerful cartoon backyard vibe with zero gore.

### D-035: Foam Shield & Environmental World Hazards (v0.5.2)
**Chosen:** Implement `ShieldPickup` providing a 50 tag point temporary buffer wrapped in a procedural holographic hexagonal forcefield (`foam_shield.gdshader`). In standard combat, damage is absorbed 1:1 before popping with `shield_pop` and overflowing to tag meter. In ZOMBIES mode, shield absorbs 50 points of infection touch, avoiding instant tag-out. Implement interactive arena hazards: `WaterPuddle` (applies `wet`, conducts Lightning darts into 2.0s AoE electrocution), `IceSlick` (frictionless slide boost along ramp slopes, meltable by Fire darts), and `WindVent` (upward air launch, catches and amplifies elemental dart clouds and infusion).
**Alternatives:** Static invulnerability power-ups; hardcoded level script triggers.
**Why:** Directly completes the young players' "Shield" drawing (§1.9), synergizes with the elemental combat engine (wet conducting lightning, fire melting ice, wind amplifying steam), and introduces thrilling environmental traversal and combat physics while strictly preserving non-violent family-friendly fun.

### D-036: Progression, Levels, Missions & Coin Shop (v0.5.3)
**Chosen:** Implement an autoload singleton `Progression` managing player lifetime XP, levels ($100 \times \text{level}$ XP per level), gameplay-earned Coins (starting with 250 coins), cosmetic unlocks, and Backyard Missions. Display Player Card in the lobby featuring Player Level badge (`⭐ LVL [N]`), XP progress bar, and Coin balance. Implement `MissionsPanel` with 3 active kid-safe objectives dynamically replenished from a backyard mission pool upon completion. Implement `ShopPanel` featuring cosmetic-only catalog (hats and color swatches) with immediate equip options and zero real-world currency, zero gems, zero microtransactions, and zero paid power (D-028). Award match completion and victory payouts on podium. Persist progression cleanly to `user://progression.cfg`.
**Alternatives:** Real-money microtransactions or battle passes; paid stat-boosting blasters; timer gates.
**Why:** Directly fulfills young players' wishlist (§1.9, §10, D-028). Ensures a fair, kid-safe, and deeply rewarding experience where every cosmetic is unlocked strictly through gameplay accomplishments without predatory monetization.

### D-037: Tempest Treehouse Arena & High-Canopy Traversals (v0.6.0)
**Chosen:** Implement `TempestTreehouse` (`scenes/arenas/tempest_treehouse.tscn`) as the game's third arena, featuring a multi-tier ancient backyard treehouse grove. The layout comprises dual fortified canopy decks (Blue Fort at $X=-16$, Orange Fort at $X=16$, $Y=5.4\text{ m}$), a catenary suspension rope bridge across the central canopy chasm ($Z=0$), open-air canopy stairway ramps leading to a high central Crow's Nest ($Y=10.5\text{ m}$), kinetic jump-pads launching players between tiers, an escape ice slide chute (+9.5 m/s slide-boost down to the bridge), gale-force wind tunnels ($28\text{ m/s}$ upper canopy cross-wind), an upward forest floor wind vent ($16.5\text{ m/s}$ lift), a conductive bird-bath water puddle, and a foam shield pickup atop the high spire.
**Alternatives:** Enclosed multi-floor towers; teleport portals; single-plane treehouse deck.
**Why:** Directly brings to life the elemental arena scope in GDD §5.4. Delivers dynamic multi-elevation combat where wind, water, lightning, and ice hazards interact directly with player movement, jump-pads, and dart trajectories across open canopy chasms, while maintaining 100% continuous navigation mesh connectivity and kid-safe backyard charm.

### D-038: Zombie Siege (Base Defense) & Blaster Skin Generative Pipeline (v0.7.0)
**Chosen:** Implement `ZombieSiegeMode` (`resources/modes/zombie_siege.tres`) and `HordeDirector` as a multi-wave co-op base defense mode where survivors protect a 1000 HP physical `BaseCore` and destructible wooden foam `BaseBarricade`s (250 HP) against 5 escalating waves of green foam zombie hordes (Runners, Brutes, and the 3.5m Mega Foam Titan Boss). Introduce a 20-second Intermission fortification phase where players spend earned Scrap to repair the base, rebuild barricades, and resupply. Implement an Anti-Slop Blaster Skin architecture using sharp object-space tri-planar shader projection ($P^{12}$ blend power in `blaster_skin.gdshader`) with 8 seamless 1024x1024 2D vector graphic patterns, tactile PBR finishes (Matte, Gloss, Metallic Flake, and Holographic Iridescence), strict material zoning (body chassis mapped while preserving safety orange muzzle tips and dark rubber grips), and kid-safe Coin Shop integration. Defeating the Mega Titan Boss on Wave 5 unlocks the exclusive **Toxic Slime** blaster skin.
**Alternatives:** Full 3D photorealistic diffusion texturing (produces muddy baked shadows, noise, and procedural UV seam stretching); infinite endless zombie waves without base defense objectives.
**Why:** Banishing AI slop requires restricting generative assets to flat, unlit, 2D vector graphic patterns and executing all lighting, Fresnel rims, and specular reflections dynamically in Godot's Forward+ PBR engine. Base defense introduces collaborative team play, tactical barricade maintenance, and high-stakes boss battles that directly extend D-034 and D-036.

### D-039: Kid-Feedback Calibration, Sniper ADS Scope, and Zombie Lunge Mechanics (v0.7.1)
**Chosen:**
1. **Game Pacing & Calibration:** Add `GameSettings.game_speed` (default `0.90`, range `0.70` to `1.10`) with a dedicated calibration slider in the Settings menu and set `Engine.time_scale` during matches. Soften Actor base speeds (`walk_speed = 6.4`, `sprint_speed = 9.6`).
2. **Physics Yeet Glitch Prevention:** Fix `IceSlick` velocity runaway by adding per-actor cooldowns (`_actor_cooldowns` 0.8s) and capping forward projection to `boost_speed` rather than additive acceleration. Hard-clamp actor horizontal velocity to `Actor.MAX_HORIZONTAL_SPEED = 24.0 m/s` in `move_actor()`. Raise `TempestTreehouse` perimeter boundary walls from 14.0m to 22.0m.
3. **Sniper Longshot Rifle Buff & ADS Scope:** Add `WeaponData.zoom_fov = 35.0` to `Longshot` rifle and buff Long Dart tag power from 70.0 to 85.0. Register `aim_down_sights` input action (RMB / Gamepad Left Trigger). Support dynamic FOV zoom interpolation (16.0 speed), scaled mouse & controller sensitivity during ADS, hide viewmodel while zoomed, and draw a darkened vignette sniper aperture with precision crosshair reticle and range tick marks in `Crosshair`.
4. **Zombie Pacing & Telegraphed Lunge:** Recalibrate zombie speeds (standard sprint 8.4 m/s, runner 9.2 m/s, brute 6.8 m/s, titan 5.5 m/s) so humans can outrun hordes when kiting. Add an explosive forward lunge impulse (`lunge(dir, 7.5)`) triggered when within 2.5–4.2m with line-of-sight on a $\ge 3.5\text{s}$ cooldown, preceded by a 0.25s crouch telegraph and audio growl cue.
5. **Zombie Siege Rebalancing:** Boost BaseCore HP to 1250, BaseBarricade HP to 350, increase intermission duration to 25s, and rebalance wave escalation (6, 10, 14, 18, 17 enemies) and scrap rewards (+20 standard, +35 runner, +60 brute, +150 boss, +75 wave clear bonus).
6. **Future Wishlist Logging:** Formally log "Floor is Lava" game mode, throwable "Foam Grenade" pickup, and dynamic "Elemental Weather / Map Disasters" (lightning storms, flash freezes, lava geysers) in roadmap §1.9 and §Phase 7.
**Alternatives:** Removing ice slides entirely; reducing zombie health without addressing speed or leap mechanics; hitscan sniper buff.
**Why:** Directly addresses authentic young player playtest feedback: game pacing felt too frantic for younger players, ice ramps launched actors out of the arena, snipers felt underwhelming, and horde modes were brutally punishing. These refinements restore joyful balance and tactical excitement while keeping gameplay completely kid-safe and non-violent.

### D-040: Floor is Lava Mode, Molten Foam Hazards, and Dynamic Tides (v0.8.0)
**Chosen:**
1. **Dynamic Molten Foam Tides (`LavaDirector`):** Orchestrate dynamic tide states across the match: CALM (24s at $Y=-0.6\text{m}$), WARNING (5s siren countdown), RISING (4s surge interpolation), HIGH TIDE (20s peak height at $Y=1.35\text{m}$), and RECEDING (4s cooldown with +25 point Survival Bonus).
2. **Cartoon Molten Foam Visuals (`lava_foam.gdshader`):** Use a custom voronoi animated foam shader with vertex waves, bright orange/yellow emission veins, and dark foam crust bobbing. Strictly avoid realistic gore, fire, or burning aesthetics.
3. **Hazard Tag & Foam Shield Absorption:** Submerged actors take continuous heat tag damage (+38 dps) with sizzling audio (`&"lava_sizzle"`). Damage absorbs 100% into active `FoamShield` (`shield_points`) before damaging tag meters, rewarding players who grab shields with temporary molten immunity.
4. **Elemental Counterplay via Obsidian Cooling:** Firing Water or Ice darts into molten lava cools the hit spot into a solid $1.4\text{m}$-radius cylindrical `ObsidianStone` platform lasting 6.0 seconds. Players can shoot stepping stones across molten gaps.
5. **Bot Elevation AI & Panic Leaping:** Bots filter roam destinations to elevated spots ($Y > \text{lava\_height} + 0.4\text{m}$) during high tide. When submerged, bots trigger emergency jump impulses and steer toward the nearest obsidian stone or high-ground structure.
**Alternatives:** Static instant-kill lava planes; permanent rising lava with no tides; complex volumetric smoke particles.
**Why:** Directly delivers on the young players' primary wishlist item (#5) with thrilling parkour combat, emergent elemental mechanics, and family-friendly cartoon fun.### D-041: Foam Grenades and Elemental Weapon Infusion Pickups (v0.8.1)
**Chosen:**
1. **Foam Grenade (`FoamGrenade`):** A physical throwable `RigidBody3D` (0.35kg, 0.58 bounce) styled as a toy high-vis safety orange foam canister with dark rubber caps and a flashing LED apex. Blinks and beeps (`&"fuse_beep"`) with accelerating pitch over a 1.8-second fuse before detonating into 16 radial physical darts (`DartPool`), an area shockwave (4.5m radius, 20.0–65.0 tag damage, 11.5 m/s knockback), and a colorful confetti burst. Thrown with `G`, middle mouse click, or Controller D-Pad Down.
2. **Foam Grenade Pickup (`GrenadePickup`):** A hovering grenade in an orange light beam granting +1 grenade (up to 2 maximum) on a 25-second respawn timer.
3. **Elemental Weapon Infusion Pickups (`ElementalPickup`):** Floating elemental canisters (Fire, Ice, Water, Lightning) inside illuminated light pillars that grant 15 seconds of weapon infusion (`apply_elemental_infusion`).
4. **Universal Blaster Infusion:** In `Actor._on_arsenal_fired()`, all darts fired by an infused actor inherit that element, applying status effects (water knockback/obsidian creation, fire burns/melts, ice slows/slides, lightning chain shocks) across any blaster in the player's or bot's arsenal.
5. **HUD Integration:** Added a grenade counter label (`💣 N [G]`) and an infusion timer bar with badge text (`🔥 PYRO 15s`) to the weapon cluster.
6. **Bot Pickup AI:** Bots proactively evaluate grenade and elemental pickup availability, incorporate them into roaming goals, and throw grenades at clustered opponents during firefights.
**Alternatives:** Impact-detonated shrapnel grenades; permanent elemental blaster variants cluttering inventory; separate button per element.
**Why:** Directly fulfills the young players' #1 and #2 wishlist items ("nerf grenade pickup" and "elemental weapon power-ups") in a fun, non-violent, family-friendly manner while seamlessly integrating with existing elemental combo and status effect systems.

### D-042: Elemental Weather and Dynamic Map Disasters (v0.9.0)
**Chosen:**
1. **Dynamic Weather Lifecycle (`WeatherDirector`):** Continuous cyclic environmental phases: CALM (28s baseline), FORECAST_WARNING (5s alert with HUD icons and chime countdown), and active weather events (20s duration):
   - **THUNDERSTORM:** Rain streaks (`WeatherEffects` with `CPUParticles3D`), thunder audio (`&"thunder"`), and periodic lightning strikes (`trigger_lightning_strike`). Lightning strikes contacting or within proximity of `WaterPuddle` surfaces dynamically electrify the water (`puddle.electrify(4.0)`), shocking and tagging any players standing inside.
   - **BLIZZARD:** Snow flurries, blizzard howling sound (`&"blizzard_wind"`), and dynamic spawning of temporary `IceSlick` patches across walkway roam points that boost actors down pathways with frictionless sliding.
   - **GALE GUSTS:** Swirling leaf particles, arena `WindField.global_wind` accelerated up to 26 m/s in rotating angular vectors, and a mobile cartoon dust devil `WhirlwindVortex` roving between roam points that spring-launches any actor stepping into it +14.5 m/s straight into the air!
   - **HEATWAVE:** Scorching summer heat that instantly melts active ice slicks into water pools (`slick.melt(5.0)`) and makes puddles sizzle with steam puffs.
2. **Safe Visuals & Zero-Leak Architecture:** Particle systems implemented with lightweight `CPUParticles3D` and box/cylinder meshes to eliminate GPU dummy texture resource leaks in headless validation. Decoupled circular class references between `Arena` and `WeatherDirector` using base Node typing.
3. **HUD Weather Status:** Persistent badge with animated weather icon (`⛈️`, `❄️`, `🌪️`, `☀️`, `🌤️`) and time remaining countdown.
4. **Bot Navigation Safety:** Bots query `puddle.is_electrified()` and add strong repulsive steering vectors during navigation to avoid zapping hazards.
**Alternatives:** Static skybox texture changes; instant-kill lightning bolts; full-screen blinding blizzard overlays.
**Why:** Directly fulfills the young players' final core wishlist item ("elemental weather / map features: lightning, fire, water, wind, lava") while reinforcing the physical, cartoon, kid-safe design pillars with zero gore and zero violence.

### D-043: Coordinated DUOS Spawning, Tactical Squad Pings, and Bot Teamplay (v0.9.1)
**Chosen:**
1. **Coordinated DUOS Buddy Spawning:** In `DUOS` mode, link each actor to their teammate (`actor.buddy_actor`). In `MatchController._choose_spawn()`, calculate a proximity bonus (`maxf(0.0, 32.0 - dist_to_buddy) * 2.0`) for spawn markers near a living teammate while preserving minimum clearance (`SPAWN_CLEARANCE = 2.5m`). At match start and on respawn, buddy pairs spawn side-by-side at adjacent launch points, directly resolving the known issue.
2. **Tactical Squad Ping System (`PingBeacon`):** An in-world 3D marker spawned via `T` key, Middle Mouse Button, or Controller D-Pad Up (`ping`). Uses forward eye raycasting (up to 60m) to identify target context: Ammo Buckets (`"📦 AMMO"`), Pickups (`"✨ POWER-UP"`), Rivals (`"⚠️ RIVAL"`), Hazards (`"💥 DANGER"`), or Scenery (`"📍 REGROUP"`). Displays an animated pulsing ground ring, vertical light beam, and billboard label fading smoothly over 4.5 seconds with procedural audio (`&"ping"` and `&"ping_ack"`).
3. **Smarter Bot Teamplay & Cover:**
   - **Buddy Proximity Roaming:** In `Bot._random_roam_point()`, bias 75% of roam choices to points within 5m–18m of a living buddy, keeping partners in supporting distance without doorway bunching.
   - **Ping Reaction:** Teammate bots listen to pings via `on_squad_ping()`, re-orienting aim toward reported rivals, routing toward ammo/power-up beacons, or moving to regroup pins.
   - **Low-Health Defensive Retreat:** When a bot's tag meter exceeds 70% (danger threshold), `_fight_direction()` prioritizes backing away from threats to seek cover and regenerate.
**Alternatives:** Full voice chat (unsafe for young kids); compass-only 2D HUD pings without 3D world markers; rigid following that blocks doorways.
**Why:** Elevates cooperative play, resolves a longstanding DUOS spawning bug, and fosters tactical communication and bot teamwork entirely through friendly cartoon mechanics.

### D-044: In-Game Input Remapping & Colorblind Accessibility Palettes (v0.9.2)
**Chosen:**
1. **In-Game Input Remapping Architecture (`InputSetup` & `BindingsPanel`):**
   - Provide full dual-slot remapping (Keyboard/Mouse and Gamepad) for all 14 core gameplay actions (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `fire`, `aim_down_sights`, `throw_grenade`, `ping`, `reload`, `weapon_next`, `weapon_prev`, `scoreboard`).
   - Essential system and menu actions (`ui_accept`, `ui_cancel`, `pause`, and look stick analog axes) are strictly protected to ensure players never trap themselves in menus or break camera controls.
   - Interactive listening mode prompts for key, mouse click, or controller button/trigger press with full escape cancellation (`KEY_ESCAPE`, `JOY_BUTTON_START`).
   - Trigger axes (`JOY_AXIS_TRIGGER_LEFT`, `JOY_AXIS_TRIGGER_RIGHT`) are captured above a 0.6 deadzone threshold to completely protect against analog stick drift.
   - Clean serialization/deserialization into `settings.cfg` under `[bindings]`, with a one-click factory reset button.
2. **Colorblind Team Color Palettes (`GameMode.TeamPalette`):**
   - Four high-contrast color palettes:
     - `DEFAULT`: Classic Blue (`#2673ff`) vs Orange (`#ff801a`), Green (`#4dd140`), Purple (`#a866ff`).
     - `COBALT_SUNBURST` (Deuteranopia / Protanopia): Deep Cobalt (`#1a66f2`) vs Bright Sunburst (`#ffd11a`), Emerald (`#33d973`), Amethyst (`#b359ff`).
     - `MAGENTA_MINT` (Tritanopia): Vivid Magenta (`#f5389e`) vs Cool Mint (`#40e6ad`), Coral (`#ff8561`), Lavender (`#ad8cfa`).
     - `HIGH_CONTRAST`: Electric Cyan (`#0dd9ff`) vs Hot Orange (`#ff5214`), Lime (`#a6f226`), Violet (`#d940ff`).
   - Dynamic global propagation: `GameMode.team_name()` and `GameMode.team_color()` evaluate the active palette in real-time, instantly adjusting player/bot jerseys, HUD banners, match announcements, and scoreboard headers.
   - Interactive live swatch preview in `SettingsPanel` alongside a cycle button.
   - Arena decor integration: `BackyardFortress` and `TempestTreehouse` dynamically construct fort battlements and canopy decks with the active team colors and signage.
**Alternatives:** External configuration file editing only; post-processing color grading shaders that distort map scenery.
**Why:** Unlocks tailored accessibility for players with color vision deficiencies and varied motor control or controller preferences, while preserving clear visual identity and vibrant cartoon charm.

### D-045: Local Couch Co-Op / Split-Screen (2 Players) (v1.0.0)
**Chosen:**
1. **Viewport & Shared World3D Architecture (`MatchScene`):**
   - Dual `SubViewport` instances (`SubViewport1` and `SubViewport2`) embedded in a responsive `BoxContainer` (`VBoxContainer` for horizontal top/bottom split by default, or `HBoxContainer` for vertical side-by-side).
   - Both subviewports share the exact same 3D physics and rendering world via `viewport2.world_3d = viewport1.world_3d = get_viewport().find_world_3d()`, completely avoiding duplicate simulations or desync issues.
   - Dedicated 3D audio listener assignment (`viewport1.audio_listener_enable_3d = true`, `viewport2.audio_listener_enable_3d = false`) to eliminate Godot audio listener conflicts.
2. **Layer Culling & 3D Character Models:**
   - Both human players instantiate full in-world 3D character models (`body_model`) with run animations, aim pitch, overhead name tags, shield bubbles, and equipped blasters.
   - Visual layer culling prevents clipping into your own head or viewing the other player's first-person viewmodel:
     - Layer 2: Player 1 body (culled from Camera 1 via `cull_mask & ~2`, visible to Camera 2).
     - Layer 3 (bit 4): Player 2 body (culled from Camera 2 via `cull_mask & ~4`, visible to Camera 1).
     - Layer 4 (bit 8): Player 1 viewmodel (visible to Camera 1, culled from Camera 2).
     - Layer 5 (bit 16): Player 2 viewmodel (visible to Camera 2, culled from Camera 1).
3. **Input Device Routing & Action Isolation:**
   - Distinct `p1_*` and `p2_*` action maps generated in `InputSetup.setup_split_screen_actions()`.
   - Automatic hardware routing: KBM + Gamepad 0 for 1-pad setups; Gamepad 0 + Gamepad 1 for dual-gamepad setups; secondary keyboard bindings (Arrow keys, Keypad Enter, Keypad 0, IJKL look) for testing without physical controllers.
4. **Per-Player HUD Subviewports:**
   - Individual `Hud` instances parented to their respective `SubViewport`, confining reticles, ammo, health, shields, and popups cleanly to each player's half of the screen.
5. **Universal Match Mode Integration:**
   - Supports all match modes seamlessly: DUOS (co-op buddy spawning on Team 0), Blue vs Orange (rivalry on opposing teams), FFA / Gun Game / Floor is Lava (rivals), Zombie Siege / Zombies (co-op survivor defense).
6. **Lobby & Persistence:**
   - Lobby options toggle `1 PLAYER` / `2 PLAYERS`, previewing both characters side-by-side on the squad island platform.
   - Player 2 customization (name, color, hat, skin) and split-screen orientation persisted cleanly in `user://settings.cfg`.
**Alternatives:** Separate local networked instances (requires network sync and duplicate memory); top-down camera shared screen (loses immersive first-person blaster perspective).
**Why:** Brings the ultimate local multiplayer couch experience to DARTSTORM, achieving the full v1.0.0 milestone vision while maintaining 60 FPS, 0 warnings, and 0 memory leaks.


