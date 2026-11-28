# Changelog

All notable releases of **DARTSTORM: Elemental Arena** are documented in this file.

## [2.0.0] - 2026-11-28 (Cover-Art Parity Visual & Model Uplift)

### Added
- **Chromatic Cel Master Shader & Warm-Navy Comic Ink Outlines:** Added `assets/materials/dartstorm_toon.gdshader` (3-band hue-shifted shadows with zero muddy grey/black undersides, glossy jelly-bean toy specular pills, golden sunlit rim, vertex-color AO, and live combat/elemental effects) and `assets/materials/toon_outline.gdshader` (distance-adaptive `#0a183d` inverted-hull silhouettes gated cleanly by Graphics Quality Presets & rendering backend via `ArenaKit.should_use_outlines`).
- **Pure-Python Parametric 3D Sculpting Pipeline (`tools/sculpt/`):** Deterministic `numpy` Catmull-Clark subdivision, beveled extrusion, spline lofting, smooth capsule multi-bone skinning, and glTF 2.0 `.glb` exporter (`mesh_sculpt.py`, `sculpt_hero.py`, `sculpt_blasters.py`, `sculpt_props.py`, plus Godot `.tscn` packers).
- **Continuous Smooth-Skinned Cartoon Heroes & Expressive Faces:** Replaced disconnected capsule/sphere hero parts with a unified 20-bone smooth-skinned `hero_base.glb`/`.tscn` featuring hoodie cowl, back hood, kangaroo pocket, cream drawstrings, continuous sleeves and trousers (zero leg gap), chunky white-midsole sneakers, sculpted ears & swept bangs, blinking Pixar eyes (`Mesh_Eyelids`), animated smile/flinch mouth swap (`Mesh_MouthSmile` / `Mesh_MouthFlinch`), and chromatic-cel sculpted hats (including cover-art rainbow propeller beanie & aviator goggles).
- **Iconic 5-Element 3D Flight Trails & Comic Starburst Juice:** Upgraded pooled `DartProjectile` trails with zero-allocation 3D elemental signatures (Wind swirling sky-blue calligraphic ribbons, Fire tumbling 4-point cartoon starbursts, Water glossy turquoise droplet wakes, Lightning crackling jagged yellow bolts, Ice spinning hexagonal frost snowflakes); added `CombatFx.spawn_comic_starburst` spiky bursts + world-space `"BONK!"`, `"DEFLECT!"`, `"RICOCHET!"`, `"HOME RUN!"`, and `"TRICK SHOT!"` word pops + comfort-safe local melee hit-stop (`BlasterModel.trigger_hit_stop`).
- **Vertex-Animated Waving Cloth Team Flags:** Added `assets/materials/cloth_flag.gdshader` and `ArenaKit.waving_flag` bringing Backyard Fortress team banners to life in the breeze.
- **Visual Benchmark Harness:** Added `tools/visual_benchmark.gd` capturing 6 fixed-camera 1280×720 Forward+ showcase shots for reproducible visual regression reviews.

### Changed
- **Blow-Molded Sculpted Blasters, Chainstorm Belt & First-Person Cartoon Hands:** Re-sculpted all 7 modular `.glb`/`.tscn` blasters with rounded blow-molded toy housings, ergonomic grips, and flanged safety-orange tips while preserving all sockets, moving parts, and ADS iron-sight clearances; mounted an animated 14-link looping blue/orange foam-dart belt & `"FLAX'S CHAINSTORM"` nameplate on `chainstorm`; upgraded first-person hoodie sleeves & cartoon hands with chromatic cel shading and fine FP outlines; smoothed custom blaster skin speculars in `blaster_skin.gdshader` to eliminate micro-normal sparkle noise.
- **Beveled Glowing Mirrors & Curved Flowing Wind Ribbons:** Upgraded `ReflectiveSurface` with glowing cyan neon border tubes, rounded corner bumpers, animated diagonal cartoon glass sheen streaks, and twin concentric ricochet shockwaves; replaced `WindZone`'s cloudy vertical box wall with a clean ground air-pad shimmer and 6 curved undulating sky-blue wind ribbons plus chromatic-cel outlined fan & windsock.
- **Living Backyard & 14 Sculpted/Cel-Upgraded Shared Arena Props:** Re-sculpted `cartoon_tree`, `inflatable_barrier`, `inflatable_bunker`, `tactical_crate`, `tactical_barrel`, `playground_slide`, `archway_curved`, `desert_urn`, and `dog_house` (including sculpted puppy `_dog` & `_tail`) and upgraded the remaining 5 shared props to chromatic cel while keeping 100% invariant `StaticBody3D` colliders & navmesh footprints; uplifted Backyard Fortress with a 14-cluster oak treehouse canopy, decorative rope ladder, fence picket finial caps, storybook windowed neighbour houses, and chromatic-cel sky clouds.
- **Zero Gameplay Loss:** All 10 game modes, 9 arena layouts/colliders, 12 weapons, split-screen, LAN/online multiplayer, Dedicated Server, bots, workbench, and progression remain 100% intact.

---

## [1.0.0] - 2026-11-28

### Added
- **Foam Bat Melee Weapon:** Kid-safe EVA-foam slugger (`foam_bat.tres`) with custom 3D `"BONK!"` model, diagonal first-person & third-person swing animations, procedural `bat_swing` / `bat_bonk` audio, +14% sprint speed while held, cartoon home-run knockback, and **Baseball Deflect** (bat incoming enemy darts and live `FoamGrenade`s back with ricochet & shooter credit).
  - Final winning rung (**11 / 11**, after Flax's Chainstorm) in **Gun Game**.
  - Starting survivor weapon (Slot `5`) in **Zombies** and **Zombie Siege**.
  - Glowing arena pickup pad (`BatPickup`) with minimap diamond pip across all standard modes, plus full Bot AI support.
- **Tactical Minimap Radar & Enhanced HUD:** Rotating circular top-right radar tracking arena cover, FOV wedge, teammates, nearby/firing rivals, Bomb Sites A & B, CTF flags, Base Core, Foam Bat pickups, and ammo buckets; directional damage arcs; dynamic crosshair spread & multi-color hitmarkers; weapon slot strip (`1`–`5`); live reload progress bar; and contextual `[F]` objective prompts.
- **Multi-Platform Release Suite:** Added `Windows Desktop` single-file `DARTSTORM.exe` export preset (`./tools/export_windows.sh`), unified all-platform release builder (`./tools/export_all.sh`), official cover art (`docs/media/cover_art.jpg`), boot splash screen, multi-size Windows/Linux/Android app icons (`assets/branding/`), and GitHub Actions release workflow (`.github/workflows/release.yml`).
- **3D Iron Sights & ADS Optics Alignment:** Crisp low-profile 3D flip-up iron sights on all modular blasters with camera near-plane clearance checks so aiming down sights never clips inside the blaster mesh.

### Changed
- **Unconstrained Forward+ Graphics Overhaul:** Per-arena AgX atmospheric lighting, SSIL, and `ReflectionProbe` presets across all 9 arenas (including floodlit twilight Soccer Stadium), 4096 desktop shadow atlas with mobile/web overrides, repaired all 9 `.gdshader` shaders, upgraded `CharacterModel` eyes/cheeks/hand poses & Chainstorm pack, unified `BlasterModel` recoil + 3D starburst muzzle flash + hollow Holo-Sight reticle, enhanced `WeatherEffects` & metallic spotlight `Podium`, and enclosed `GarageWorkbench`.
- **All 9 Arenas Audited & Repaired:** Explicit `bomb_sites`, `flag_pedestals`, and `bomb_spawns` on all 9 arenas; rebuilt **Two Fortresses** open moat, navigable basement vaults, water tunnels, and stairs; sealed **Dusty Courtyard** canal gap, opened courtyard arch, aligned sniper bridge & CT compound; opened **Duststorm II** Lower B Tunnel, cleared Pit ramp, sealed CT void, and widened B Window; regenerated `dog_house` and `inflatable_barrier` props.
- **Zero-Emoji UI Compliance:** Stripped all unsupported Unicode emojis across menus, HUD, Shop, Missions, Workbench, and Multiplayer screens so `Lilita One` renders with zero missing glyphs.
- **Live 3D Arena Switcher:** Lobby `<` / `>` arena selector swaps the live 3D arena backdrop immediately alongside a `v1.0.0` version badge.

### Fixed
- Fixed repeating runtime script error in `Hud._process` (`WeaponState.get_reload_seconds` / `reload_left`) by reading `Arsenal.reload_progress()`.
- Fixed Dart Sprayer and blaster ADS iron-sight camera clipping and eliminated floating attachment meshes on melee weapons.
- Decoupled Gamepad LT ADS from sprint; preserved secondary bindings when rebinding keys; eliminated vertical recoil pitch drift.
- Fixed split-screen Zombie Siege co-op team assignment, split-screen end-of-match HUD visibility, non-zombie Orange Team podium display, anchored CTF flag pedestals, Plant the Bomb round scoring, bot attachment isolation from local profile progression, `six_shot` -> `ricochet_ranger` mastery alias, pause music unducking, and permanent hurt-flash lock.
- Fixed `tools/dart_table.gd` stalling on zero-gravity melee placeholder darts.
- Hardened `tools/serve_download.py` against directory traversal, unified `1.0.0` metadata, and removed orphan `.uid` files.

---

## [0.8.0] - 2026-11-23
- Added AAA stylized hero anatomy, 2K procedural PBR texture suite (normal/ORM/micro-detail), `stylized_water.gdshader` and `lawn.gdshader`, Graphics Quality Presets (Low/Medium/High/Ultra), **Floor is Lava**, **Foam Grenades**, **Elemental Weapon Infusions**, **Elemental Weather**, **Capture the Flag**, **Plant the Bomb**, **Realistic Mode**, **Garage Workbench & Weapon Mastery**, **LAN Server Browser & Dedicated Server**, **Local 2-Player Split-Screen**, and arenas **Playground**, **Sunny Park**, **Soccer Stadium**, **Two Fortresses**, **Dusty Courtyard**, and **Duststorm II**.

## [0.7.1] - 2026-11-22
- Mobile touch controls (`TouchControls`, `VirtualJoystick`), WebGL2/GLES3 Compatibility rendering, HTML5/WASM web export, signed Android APK export, kid-feedback game speed slider (`0.70`–`1.10`), Longshot ADS scope buff, zombie lunge telegraph, and Zombie Siege rebalancing.

## [0.7.0] - 2026-11-20
- **Zombie Siege** 5-wave co-op base defense (`BaseCore`, `BaseBarricade`, `HordeDirector`, Mega Foam Titan Boss) and anti-slop triplanar **Blaster Skins** pipeline (8 skins, 4+ PBR finishes).

## [0.6.0] - 2026-11-19
- **Tempest Treehouse** multi-tier canopy arena with suspension rope bridge, Crow's Nest, ice slide chute, jump-pads, and gale wind tunnels.

## [0.5.0] – [0.5.3] - 2026-11-18
- Elemental darts & reactions (Wind, Fire, Water, Lightning, Ice), **Zombies** infection mode, **Foam Shield** & environmental hazards (`WaterPuddle`, `IceSlick`, `WindVent`), and **Progression, Levels, Backyard Missions & 100% Kid-Safe Coin Shop**.

## [0.1.0] – [0.4.0] - 2026-11-15 – 2026-11-17
- First playable **Backyard Fortress**, physical foam-dart ballistics, **Flax's Chainstorm**, Gun Game, bots & runtime navmesh, hardening suite, plug-and-play controller support, procedural music & announcer, podium & awards, young players' 3D squad lobby, team modes (`SOLO`/`DUOS`/`TEAMS`), Linux standalone export, and **Home Turf** toy-scale family home arena.
