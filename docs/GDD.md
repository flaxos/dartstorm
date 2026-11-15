# DARTSTORM: Elemental Arena — Game Design Document

## 0. Document control

| | |
|---|---|
| **Game version** | 0.1.1 (hardening release) |
| **Status** | v0.1.0 **passed UAT** on 2026-11-15 (see [UAT.md](UAT.md)) |
| **Authority** | This GDD is the authoritative description of the game. Numbers mirror the `.tres` files in `resources/`. If they ever disagree, the `.tres` file is what the game uses, so fix this doc. |
| **Source vision** | [CONCEPT_BRIEF.md](CONCEPT_BRIEF.md), the original brief, archived verbatim. §1 summarises it and §2 tracks it. |
| **Related** | [ARCHITECTURE.md](ARCHITECTURE.md) (how it's built) · [TUNING.md](TUNING.md) (changing numbers without code) · [ROADMAP.md](ROADMAP.md) · [DECISIONS.md](DECISIONS.md) |

---

## 1. Concept (from the original brief)

### 1.1 Pitch
**DARTSTORM** is a colourful, chaotic, first-person foam-dart arena shooter inspired by backyard blaster
battles, classic arena shooters and creative elemental environments. You sprint across a backyard fortress,
lob arcing foam darts that bend in the wind and bounce off mirrors, raid ammo buckets, and, when you get
your hands on it, unleash **Flax's Chainstorm**: a ridiculous, belt-fed, six-barrel foam cannon.

### 1.2 Origin
Sam is making DARTSTORM for his kids, based on ideas they developed together with Flax. That shapes every
decision: the people this game must delight are kids who are excited about *their* idea. The Chainstorm
carries Flax's name because it's Flax's idea, and it is meant to be the highlight of the game.

### 1.3 The vision, in the kids' own list
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

Personality: **playful, energetic, colourful and slightly ridiculous.**

### 1.4 Core philosophy
> **Easy to play, difficult to master, enormously fun to experiment with.**

- *Easy to play:* WASD, mouse, click. Generous hitboxes. No reloading the Chainstorm. Bots that are beatable on Easy.
- *Difficult to master:* darts drop and slow down, so range matters. Wind bends shots. Ricochets reward geometry.
  Bucket control decides who gets to keep the Chainstorm spinning.
- *Fun to experiment with:* bounce shots off mirrors, curve them through the fan's wind, trampoline onto the
  treehouse, hose a bot with 30 darts a second.

### 1.5 Design pillars
Every feature should strengthen at least one pillar and weaken none.

| Pillar | What it means in practice |
|---|---|
| **Darts are physical** | Never hit-scan. Every dart flies, drops, drifts and can miss. Skill is reading the arc. |
| **Colourful and ridiculous** | Loud colours, big silhouettes, confetti, boings and dings. The Chainstorm is gloriously over the top. |
| **Kid-safe by design** | Cartoon tagging only. Nobody is hurt; tagged players pop into foam and respawn. No gore, no real-gun branding, no strobing. |
| **Readable at a glance** | Landmarks, a wind compass, glowing mirror frames, a tag meter you can read, clear hit markers. |
| **Play first** | Every build is playable. Tuning is data, not code. Features land with tests. |

### 1.6 Hard rules (non-negotiable)
- No gore, realistic injuries, realistic firearms or military simulation. All combat is **tagging with foam darts**.
- Fire and lightning are **playful effects**, never burns or electrocution.
- **Original DARTSTORM branding.** No Nerf (or other trademarked) names, logos or product designs.
- **No microtransactions, loot boxes or paid gameplay advantages,** ever.
- Avoid excessive screen shake, flashing or visual clutter. Shake and effect intensity are always user settings.

### 1.7 Definition of success (from the brief), and its status
> *Sam can launch Godot, press Play, run around a colourful arena, shoot moving foam darts at bots, get tags,
> refill ammunition and finish a match.*

✅ **Met in v0.1.0, confirmed by UAT on 2026-11-15.**

### 1.8 The most important rule
> This is a game being made for kids who are excited about their idea. Prioritise the things they can see,
> interact with, laugh at and play. Make it fun. Make it colourful. **Make Flax's Chainstorm absolutely ridiculous.**

---

## 2. Brief traceability

Status key: ✅ done · 🟡 partly done or untested · ⏳ planned, not started. Brief section numbers refer to
[CONCEPT_BRIEF.md](CONCEPT_BRIEF.md).

### 2.1 Technical stack (brief §2)
| Requirement | Status | Where / notes |
|---|---|---|
| Godot 4 (latest local stable), GDScript | ✅ | Godot 4.4.1, typed GDScript |
| 3D first-person shooter | ✅ | `scripts/player/player.gd` |
| Windows primary target | 🟡 | Nothing Windows-specific, but not yet run on Windows |
| Linux secondary target | ✅ | Developed and UAT'd on Linux |
| Keyboard and mouse | ✅ | `scripts/core/input_setup.gd` |
| Gamepad (planned) | 🟡 | Mapped (sticks, triggers, buttons) but untested |
| Multiplayer architected, bots first | 🟡 | Brain/body split, central tag authority (ARCHITECTURE §9, DECISIONS D-008). No networking yet |
| Stylised low-poly look | ✅ | Primitives, flat colours, lawn shader |
| Godot 3D physics, Git, vertical slices | ✅ | |
| Data-driven, no hard-coded weapons | ✅ | `resources/weapons/*.tres` |

### 2.2 First playable: Backyard Battle (brief §3)
| Requirement | Status | Where / notes |
|---|---|---|
| First-person camera, WASD, mouse aim, jump, sprint, smooth acceleration, collision | ✅ | `Player`, `Actor.move_actor` |
| Visible blaster in view, crosshair, HUD | ✅ | `BlasterModel`, `Crosshair`, `Hud` |
| Moving dart projectiles with visible drop | ✅ | `DartProjectile`, §3.8 |
| Projectile collision detection | ✅ | Swept ray every tick, no tunnelling (test: *Fast darts cannot tunnel*) |
| Basic wind effects | ✅ | `WindZone` in Windy Way |
| Reflective surfaces and ricochets | ✅ | `ReflectiveSurface` ×2 in Mirror Alley |
| Colourful hit effects | ✅ | `CombatFx`, `FoamBurst` |
| Tag meter as health; tagging and respawning | ✅ | `Actor`, `MatchController` |
| Pocket Popper: semi, low capacity, accurate, fast reload | ✅ | 8-dart mag, 0.4° spread, 0.8 s reload |
| Dart Sprayer: full-auto, fast, moderate spread, larger magazine | ✅ | 10/s, 2.6°, 30-dart mag |
| Flax's Chainstorm: oversized belt-fed rotary, backpack, visible belt, rotating barrels, spin-up, very high rate, strong feedback, large capacity, move penalty | ✅ | §4.2 |
| Arena: blue and orange bases, elevations, ramps, platforms, foam barriers, crates, treehouse, walkways, 2 mirrors, 1 wind zone, buckets, landmarks | ✅ | §5.1 |
| ≥2 bots that move, find, aim, fire, react, respawn, navigate, configurable difficulty | ✅ | 2–5 bots, Easy/Normal/Hard, navmesh (§3.14) |
| 5-minute round, FFA scoring, scoreboard, tag feed, countdown, respawn timer, results, restart | ✅ | `MatchController`, `Hud` |

### 2.3 Physical dart system (brief §4)
| Property or behaviour | Status | Field / where |
|---|---|---|
| Initial velocity | ✅ | `DartData.initial_speed` |
| Gravity multiplier | ✅ | `gravity_multiplier` |
| Mass / wind responsiveness | ✅ | `wind_response` |
| Air drag | ✅ | `air_drag` |
| Collision layers | ✅ | `collision_mask` (`Layers.DART_MASK`) |
| Maximum lifetime | ✅ | `max_lifetime` |
| Ricochet count (per type) | ✅ | `max_ricochets`, `ricochet_speed_keep`, `ricochet_any_surface` |
| Surface interaction | ✅ | Reflective group, bouncy darts, "spent" darts that tumble and rest |
| Elemental effects | 🟡 | `element` field exists; no behaviour yet (needed for Wind Whisperer, Thunder Cannon, …) |
| Team ID, source weapon, source player | ✅ | `team_id`, `weapon`, `shooter` on each dart |
| `v += (g + wind)·dt; p += v·dt` | ✅ | `DartProjectile._physics_process` (plus drag) |
| Swept collision | ✅ | Ray from old to new position each tick |
| WindZone: direction, strength, size, particles, arrow/windsock | ✅ | Streaks, drifting arrows, windsock, giant fan |
| Darts visibly curve | ✅ | Test: *Wind zones curve darts* |
| Ready for dynamic weather | 🟡 | `WindField.global_wind`, `WindZone.gust_amount` hooks exist but unused |
| Ricochet: reflect, slow, continue, count, no instant re-hit | ✅ | Hardened in v0.1.1 for back-to-back bounces |
| Ricochet tag bonus | ✅ | +50 |

### 2.4 Game feel, Gun Game, arenas, buckets, progression and UI (brief §5–§10)
| Requirement | Status | Where / notes |
|---|---|---|
| Muzzle flash, launch sounds, subtle shake, recoil, trails, foam particles, hit confirmation, score popups, tag sounds, Chainstorm spin feedback | ✅ | §7 |
| Avoid excessive shake, flashing, clutter; shake and intensity settings | ✅ | §9; effects budget added in v0.1.1 |
| Gun Game: start weakest, advance per tag, ladder stored in data | ✅ | `resources/modes/gun_game.tres` |
| Full 10-rung ladder | 🟡 | 7 of 10. Missing: Wind Whisperer, Thunder Cannon, Rocket Dart |
| Elemental arenas: architecture documented | ✅ | §5.2, ARCHITECTURE §9 |
| Elemental arenas built | ⏳ | Only Backyard Fortress (as the brief instructs) |
| Buckets: configurable amount, team or neutral colour, detect players, refill weapons, empty state, regen delay | ✅ | `AmmoBucket` (§6.7) |
| Chainstorm's high ammo use makes buckets strategic | ✅ | A full bucket is ≈5 s of Chainstorm fire |
| Capturable team buckets | ⏳ | Roadmap |
| Weapons as Resources; config, presentation and runtime separate | ✅ | `WeaponData` / `BlasterModel` / `Arsenal` |
| XP, mastery, upgrades, skins, alternate and elemental darts | ⏳ | Deliberately deferred until combat is proven fun (§10) |
| No microtransactions | ✅ | And never |
| HUD: crosshair, weapon name, ammo, tag meter, timer, score, wind, hit confirmation, ricochet notice | ✅ | §8 |
| Deep blue, vibrant orange, rounded, chunky fonts | ✅ / 🟡 | Font is the engine default, emboldened. A chunkier OFL font is on the roadmap |
| Main menu, settings, pause | ✅ | Plus **Reset to defaults** in v0.1.1 |

### 2.5 Engineering and process (brief §11–§16)
| Requirement | Status | Where / notes |
|---|---|---|
| Suggested project layout | ✅ | ARCHITECTURE §1 |
| Typed GDScript, signals, Resources, few singletons (2), error handling | ✅ | Hardened loading in v0.1.1 |
| No placeholder/TODO core features, no fabricated assets | ✅ | All assets generated in code (`assets/README.md`) |
| Headless validation and automated tests | ✅ | `tools/validate.sh`: import, strict compile (zero warnings), boots, 130 tests, leak check |
| Bounded projectiles, pooling | ✅ | 400-dart pool; effect budget |
| Four living docs + CLAUDE.md | ✅ | Plus CONCEPT_BRIEF, UAT, TUNING |

---

## 3. Gameplay

### 3.1 Player fantasy
You're a kid in the best backyard battle ever. Your blaster is chunky and bright, your darts have orange safety
tips, and there's a treehouse to defend. Every shot is a little lob you can *watch*, and landing one feels
earned. Then someone across the yard picks up the Chainstorm, and the whole backyard turns into a foam blizzard.

### 3.2 The first 60 seconds
1. **Main menu.** The backyard slowly spins behind a huge orange DARTSTORM title. Pick **PLAY: BACKYARD BATTLE**
   (bots and skill can be changed right there).
2. **3-2-1-GO.** You're frozen at a spawn point but can look around: forts, the giant tree, flags.
3. **GO!** Run. Your Pocket Popper is out (`1`). Click: a dart arcs away and drops a little at range.
4. **First contact.** A bot (say *Blaze*, in orange) pops up on the walkway. Its tag meter floats above its cap.
   Three Popper hits and it bursts into confetti: **+100 TAG!**, a jingle, an orange hit marker.
5. **Discovery.** Swap to `3`. The Chainstorm whines up for 0.7 s, then roars. You slow to a crawl but the
   air fills with darts. The belt counter plunges, so you head for the nearest **AMMO** bucket.
6. **Experiment.** You notice the giant fan. Shots across Windy Way swing sideways. The glowing mirror in
   Mirror Alley bounces a dart around the hedge: **+50 RICOCHET BONUS!**

### 3.3 Core loop
```
   ┌──► spawn (1.5 s protection) ──► find a target ──► land darts (aim for drop and wind) ──┐
   │                                                                                    │
   │      refill at a bucket ◄── run low ◄── tag them out (+100, confetti) ◄────────────┘
   │             │
   └── tagged out (pop!) ◄── get caught by someone else ◄─┘   (respawn after 3 s)
```

### 3.4 Match timeline
| Phase | Duration | What happens |
|---|---|---|
| Countdown | 3 s | Big 3-2-1 with beeps. Everyone frozen, looking allowed, pause allowed. Anyone tagged out now (e.g. falling) still respawns (v0.1.1) |
| Play | 5:00 | Clock counts down. At 0:10 it turns orange and beeps each second |
| Early finish | — | Gun Game only: a tag while holding the last blaster wins instantly |
| Results | Until a choice | Everyone frozen. Winner banner ("YOU WIN!" / "PICKLE WINS!"), full table, **PLAY AGAIN** / **MAIN MENU** |

### 3.5 Movement and traversal
| Move | Numbers | Notes |
|---|---|---|
| Walk / sprint | 7.0 / 10.5 m/s | Sprint only while moving forward; FOV widens slightly |
| Acceleration | 60 ground, 18 air | Snappy on the ground, committed in the air |
| Jump | 7.6 m/s → **≈1.45 m** high | Clears crates (1.1 m), foam barriers (1.3 m) and battlements (1.0 m) |
| Coyote time / jump buffer | 0.12 s / 0.12 s | Jumps still work a hair late off a ledge, or a hair early before landing |
| Trampoline | 15.5 m/s → **≈6 m** high | Lands you on the treehouse deck (4.6 m) |
| Chainstorm penalty | ×0.45 while spun up | 3.2 m/s walking. Commit to a spot or spin down to move |
| Fall-out safety | Below −25 m you're tagged out | Fences and invisible walls make this near impossible; it's a safety net |

### 3.6 Tagging rules
- Everyone has a **tag meter (0–100)**. Each dart fills it by its *tag power* (× the shooter's damage scale).
  At 100 you're **tagged out**: you pop into a burst of your colour plus confetti, a "TAGGED!" banner shows who
  got you, and you respawn after **3 s** (Gun Game 2 s).
- After **4 s** without being hit, your meter drains at **15/s**. Breaking line of sight works.
- **Spawn protection:** 1.5 s after respawning, darts splat harmlessly on you.
- **Respawn point:** the spawn furthest from everyone else, picked at random from the best three.
- **Friendly fire:** darts pass straight through team-mates (in free-for-all everyone is their own team).
- **Hitboxes are generous:** bots 0.6 m radius, the player 0.45 m (deliberately a bit harder to hit, D-012).

### 3.7 Hits to tag and time to tag
Hits needed = ⌈100 ÷ (tag power × shooter damage scale)⌉. Bots' darts are scaled by difficulty
(Easy ×0.4, Normal ×0.6, Hard ×1.0), so **Easy bots need over twice as many hits to tag you as you need to tag them.**

| Blaster (tag power) | You | Hard bot | Normal bot | Easy bot | Your fastest tag* |
|---|---|---|---|---|---|
| Pocket Popper (34) | **3** | 3 | 5 | 8 | 0.4 s |
| Double Trouble (34 ×2 per pull) | **2 pulls** | 2 pulls | 3 pulls | 4 pulls | 0.31 s |
| Dart Sprayer (13) | **8** | 8 | 13 | 20 | 0.7 s |
| Foam Hammer (15 ×8 slugs) | **1 blast** (7 slugs) | 1 blast | 2 blasts | 3 blasts | instant up close |
| Ricochet Ranger (34) | **3** | 3 | 5 | 8 | 0.67 s |
| Longshot (70) | **2** | 2 | 3 | 4 | 0.91 s |
| Flax's Chainstorm (10) | **10** | 10 | 17 | 25 | ≈1.0 s incl. 0.7 s spin-up |

\* Every dart hits and you fire at the blaster's maximum rate. Spread, drop and dodging make real tags slower.

### 3.8 Dart flight
Darts are **real projectiles** (DECISIONS D-003). Each tick, gravity × `gravity_multiplier` plus wind ×
`wind_response` is added to velocity, drag slows it, and a ray sweeps the path to the next position.
The table is generated by firing the real dart code in calm air (`godot --headless --path . -s res://tools/dart_table.gd`).
"Level-shot range" is how far a dart fired dead level from shoulder height (1.4 m) travels before it lands.

| Dart | Used by | Speed | Gravity × | Drag | 10 m: time / drop | 20 m | 30 m | 40 m | Level-shot range |
|---|---|---|---|---|---|---|---|---|---|
| Foam Dart | Popper, Double Trouble | 44 | 0.70 | 0.25 | 0.23 s / 0.20 m | 0.48 s / 0.80 m | 0.75 s / 1.85 m | 1.03 s / 3.42 m | 26 m |
| Mini Dart | Sprayer | 40 | 0.75 | 0.30 | 0.26 s / 0.26 m | 0.54 s / 1.06 m | 0.85 s / 2.50 m | 1.19 s / 4.71 m | 23 m |
| Belt Dart | Chainstorm | 48 | 0.65 | 0.25 | 0.21 s / 0.15 m | 0.44 s / 0.62 m | 0.68 s / 1.43 m | 0.94 s / 2.63 m | 30 m |
| Foam Slug | Foam Hammer | 36 | 0.90 | 0.90 | 0.32 s / 0.44 m | 0.78 s / 2.18 m | 1.58 s / 7.21 m | never | 17 m |
| Bouncy Dart | Ricochet Ranger | 40 | 0.50 | 0.15 | 0.26 s / 0.17 m | 0.52 s / 0.67 m | 0.80 s / 1.52 m | 1.09 s / 2.77 m | 29 m |
| Mega Dart | Longshot | 78 | 0.35 | 0.10 | 0.13 s / 0.03 m | 0.26 s / 0.12 m | 0.39 s / 0.27 m | 0.53 s / 0.48 m | 68 m |

How to read it: under 10 m, aim straight at them. At 20 m, aim at the top of their head (darts drop about 0.8 m).
At 30 m and beyond, lob it, or use the Longshot.
The crosshair aims at what's under it, so short shots go exactly where you point.

**Spent darts:** a dart that hits scenery stops being dangerous, bounces, tumbles, lies on the ground for
about 1.4 s, then shrinks away. The yard stays readable and darts feel physical.

### 3.9 Wind playbook (Windy Way)
- The giant fan blows **north** (toward the middle of the yard) at **40 m/s²** across a 24 × 12 m lane on the south side.
  That's about 6× the darts' gravity, so it's very noticeable.
- A Foam Dart fired 20 m along the lane (east–west) drifts roughly **4–5 m** north. Aim upwind, on the fan side.
- Shots *with* the wind (south to north) carry further. Shots *into* it fall short.
- The HUD **wind compass** appears whenever you stand in wind, with the arrow relative to where you're looking.
- **Bots ignore wind** (on purpose). Fight them from inside Windy Way and their shots curve off.
- Every dart type has `wind_response`, so future "heavy" darts can shrug wind off and light ones can be blown about.

### 3.10 Ricochet playbook (Mirror Alley)
- Two glowing cyan-framed **mirror panels** stand on the north fence, angled 15° inward behind the hedge.
- A dart that hits a mirror reflects like light (angle in = angle out), keeps **80%** of its speed,
  and can bounce once (Ricochet Ranger darts: 4 bounces off *anything*, keeping 90%).
- A tag by a dart that has ricocheted scores **+50 RICOCHET BONUS** on top of the tag.
- Trick shot: from the hedge's east end, fire at the west mirror to tag someone hiding behind the hedge.
- A white ripple ring flashes where the dart bounced, so you can see your angles and learn them.

### 3.11 Ammo economy and the Chainstorm
| Source / sink | Numbers |
|---|---|
| Pocket Popper | 8-dart magazine, reserve up to 48 (start 32), 0.8 s reload |
| Dart Sprayer | 30-dart magazine, reserve up to 150 (start 90), 1.5 s reload |
| Flax's Chainstorm | Belt-fed: fires straight from a 400-dart belt (start 160) at **30 darts/s** and never reloads |
| Ammo bucket | 150 darts, hands out 90 darts/s to whoever stands within 1.9 m, refills fully **14 s** after it's emptied |
| Refill order | The blaster in your hands fills first, then the others |
| Auto-reload | An empty magazine reloads by itself (you never get stuck clicking) |

**Why it matters:** one bucket is about **5 seconds** of Chainstorm fire. A Chainstorm player who controls a bucket
dominates, and one who doesn't runs dry fast. The bucket labels count down while they refill ("EMPTY 9"),
so you can plan your route. Gun Game hands out bottomless ammo, so buckets don't matter there.

### 3.12 Scoring
| Event | Points |
|---|---|
| Tag someone out | **+100** |
| …with a dart that ricocheted | **+50 bonus** (150 total) |
| Hit a bullseye target | **+10** (the target spins, shrinks and pops back after ≈3.5 s) |
| Being tagged out | 0 (it counts as an "out" on the scoreboard) |
| Tag-outs outside play (countdown, falls) | Nothing scored |

**Free-for-all ranking:** score, then tags, then fewest outs. *Example:* 4 tags (one a ricochet) and 3 bullseyes
gives 4×100 + 50 + 30 = **480**.

### 3.13 Gun Game
- Everyone starts on **rung 1** with **bottomless ammo**. Each tag swaps your blaster for the next rung
  ("NEW BLASTER: …" popup and a level-up jingle).
- Ladder (7 of the 10 planned): Pocket Popper → Double Trouble → Dart Sprayer → Foam Hammer → Ricochet Ranger →
  Longshot → **Flax's Chainstorm**.
- **Tag someone while holding the Chainstorm to win instantly.** If the clock runs out, the highest rung wins
  (then score). The HUD shows "BLASTER n / 7", and the scoreboard has a BLASTER column.
- Planned rungs: *Wind Whisperer* (after Ricochet Ranger), *Thunder Cannon* and *Rocket Dart* (before the Chainstorm).
  To add one, write its `.tres` and drop it into the ladder (TUNING.md).

### 3.14 Bots, from the player's point of view
Five named kids: **Blaze** (orange), **Pickle** (green), **Zoom** (purple), **Sprinkles** (pink), **Noodle** (yellow).
You're blue. Each bot wears a cap in its colour and carries its blaster (the Chainstorm comes with a backpack), with a name
tag and a tag meter floating above.

| They… | How |
|---|---|
| Wander | Between interesting spots (spawns, buckets, the deck, cover), along the navmesh |
| Notice you | Within their vision range and view cone, with clear line of sight. Within 4 m, or if you just hit them, the cone doesn't matter (line of sight still does) |
| Fight | Keep a comfortable range for their blaster (Popper ≈14 m, Sprayer ≈8 m, Chainstorm ≈10 m), strafe and fire in bursts |
| Aim | Lead moving targets (more on harder skill) and aim higher to allow for drop. **They don't allow for wind** |
| React to hits | Flinch, dodge the other way, and hunt whoever hit them for 4 s |
| Resupply | Head to the nearest stocked bucket under 15 darts. When completely dry with all buckets empty, wait at the nearest one (v0.1.1) |
| Switch blasters | Pick the one that suits the range; avoid a nearly empty Chainstorm; **instantly drop an empty blaster** (v0.1.1) |
| Get unstuck | Hop after 0.5 s blocked, pick a new destination after 2 s |

| Skill | Aim error | Reaction | Turn speed | Vision | Dart power | Speed |
|---|---|---|---|---|---|---|
| Easy | 9° | 1.0 s | 140°/s | 30 m, 130° cone | ×0.4 | ×0.75 |
| Normal | 5.5° | 0.6 s | 220°/s | 40 m, 200° cone | ×0.6 | ×0.9 |
| Hard | 3° | 0.3 s | 340°/s | 50 m, all round | ×1.0 | ×1.0 |

### 3.15 Tips for kids (this text could go on a loading screen one day)
- Big distance? Aim a bit **above** them; darts drop.
- Hiding behind a hedge? **Bounce** a dart off the shiny mirror!
- In Windy Way, aim **toward the fan side**; the wind pushes darts north.
- The Chainstorm needs a moment to **spin up**. Start spinning *before* you peek.
- Running low? Follow the floating **AMMO** signs.
- Got hit? Duck out of sight for 4 seconds and your tag meter drains.
- Trampolines launch you onto the **treehouse**, the best view in the yard.

---

## 4. Blasters

### 4.1 Reference
| Blaster | Mode | Rate | Darts/shot | Spread | Magazine / reserve | Reload | Move while firing | Personality |
|---|---|---|---|---|---|---|---|---|
| **Pocket Popper** | Semi | 5/s | 1 | 0.4° | 8 / 48 (32) | 0.8 s | 100% | Accurate, reliable starter |
| **Dart Sprayer** | Auto | 10/s | 1 | 2.6° | 30 / 150 (90) | 1.5 s | 100% | Hold and hose |
| **Flax's Chainstorm** | Spin-up | 30/s | 1 | 4.2° | belt 400 (160) | — | **45%** | The star of the show |
| Double Trouble | Semi | 3.2/s | 2 | 1.6° | 8 / 48 (32) | 1.0 s | 100% | Two at once |
| Foam Hammer | Semi | 1.5/s | 8 | 6.5° | 4 / 28 (20) | 1.6 s | 100% | Point-blank blast |
| Ricochet Ranger | Semi | 3/s | 1 | 0.5° | 6 / 36 (24) | 1.2 s | 100% | Bounces off everything |
| Longshot | Semi | 1.1/s | 1 | 0.1° | 4 / 24 (16) | 1.8 s | 100% | Fast, flat, two-hit tags |

Keys `1 2 3`, the mouse wheel or `Q`/`E` switch blasters (0.3 s swap). In free-for-all you carry the Popper, the Sprayer and the Chainstorm.

### 4.2 Spotlight: FLAX'S CHAINSTORM
Brief: *"This weapon should feel hilariously overpowered and be a highlight of the game."*
- **Look:** an oversized blue housing with orange bands, a carry handle, a **FLAX'S CHAINSTORM** nameplate, and **six barrels
  that visibly spin**. A **dart belt** loops from the feed box and visibly advances with every shot.
  Bots carrying it wear an orange **ammo backpack**.
- **Spin-up:** hold fire and the barrels wind up over **0.7 s**: a rising motor whine, a lime **spin bar** on the HUD,
  and the view-model rattles. Release and it spins down over 0.9 s (you can feather it to stay spun).
- **The storm:** **30 darts/s** with chunky clacks, muzzle puffs and camera buzz. Ten Belt Darts tag anyone.
- **The cost:** you walk at 45% speed while spun up, and the belt drains a full bucket in about 5 seconds.
- **Design intent:** it should be *gloriously* strong. The counterplay is movement (it's slow), range (darts drop past
  30 m), ammo (bucket control) and wind (bots and players can't fight Windy Way's push).

---

## 5. Arenas

### 5.1 Backyard Fortress (playable)
A 68 × 48 m fenced backyard. North is −Z. Blue holds the west end and Orange the east.

```
 N  ┌──────────────────── fence (4 m, invisible wall above) ────────────────────┐
    │ [bullseye]   [MIRROR]   ~~~ HEDGE ~~~   [MIRROR]   [bullseye]            │
    │                     MIRROR ALLEY  (bucket behind the hedge)               │
    │   crates        barrier          slide          barrier        crates     │
 W  │ BLUE ══ramp══   trampoline   ┌─TREEHOUSE─┐      crates   ══ramp══ ORANGE  │ E
    │ FORT ══walkway════════════════│ deck 4.6m │════════════walkway══ FORT     │
    │ 2.6m ══ramp══  crate stacks   └───────────┘  trampoline ══ramp══ 2.6m     │
    │ (bucket)          barrier         ramp            barrier       (bucket)  │
    │ ~~~~~~~~~~~ WINDY WAY: giant fan → wind blows north (bucket) ~~~~~~~~~~~  │
    │ [bullseye]                                                  [bullseye]   │
 S  └───────────────────────────────────────────────────────────────────────────┘
```

**Callouts**
| Callout | Where (x, z) | Height | Purpose |
|---|---|---|---|
| Blue Fort / Orange Fort | x ±24 to ±32, z ±6 | 2.6 m platform | Home bases. Battlements to duck behind, a roofed back half, a huge flag, signage, 2 spawns inside |
| Fort ramps | x ±17.5 to ±24, z ±4.5 | 0 → 2.6 m | Two per fort toward the middle |
| Walkways | x ±4.5 to ±24, z 0 | 2.6 → 4.6 m | Railed bridges from each fort to the deck: the main "high road" |
| Treehouse deck | 9 × 9 m around (0, 0) | 4.6 m | King of the hill. Railings with four gaps, best sightlines, bullseyes on the trunk above |
| South ramp | z 14.5 → 4.5 | 0 → 4.6 m | Wooden ramp up from Windy Way |
| The Slide | z −14 → −4.5 | 0 → 4.6 m | Bright yellow, walkable both ways, from Mirror Alley |
| Trampolines | (6.8, −6.8) and (−6.8, 6.8) | → ≈6 m | Fast route onto the deck |
| Under the Tree | (0, 3) | ground | Neutral bucket beneath the deck: contested and covered |
| Mirror Alley | z −16 to −24 | ground | Hedge (9 × 2.6 m) with mirrors behind it at x ±9, and a bucket behind the hedge |
| Windy Way | z 11.4 to 23.8, x ±12 | ground–5.2 m | Wind lane with a giant fan, a windsock and a bucket at (0, 20.5) |
| Crate stacks | e.g. (±11, 6), (±17.5, −13), (±9.5, 18) | 1.1–2.2 m | Hop-up cover |
| Foam barriers | 14 around the yard | 1.3 m | Bright squishy cover in pink, yellow, cyan and lime |

**Routes:** high road (fort → walkway → deck) · low road (fort ramp → crates → under the tree) · north flank (Mirror Alley) ·
south flank (Windy Way). **Sightlines:** the deck overlooks most of the yard, but the trunk splits it in half and the
railings only leave four gaps, so nobody holds it alone. Walkway rails give half-cover. The hedge blocks the
north lane except by mirror.
**Bucket control:** five buckets (two team-coloured at the fort fronts, three neutral at Under the Tree, Mirror Alley and Windy Way)
spread fights across the map.
**Landmarks:** the giant treehouse canopy, the team flags, the BLUE FORT / ORANGE FORT signs, the yellow slide, the spinning fan,
the glowing mirror frames, and the neighbourhood houses beyond the fence.

### 5.2 Future elemental arenas (designed, not built)
| Arena | Signature mechanic | Reuses | Needs |
|---|---|---|---|
| **Tempest Treehouse** | Wind tunnels, gusts, vertical climbs, long curved shots | WindZone `gust_amount`, WindField `global_wind`, JumpPad | Gust timing, vertical layout |
| **Ember Workshop** | Glowing vents, moving platforms, temporary flame barriers (**playful, never burns**) | ArenaKit, wind as heat updraft | AnimatableBody3D platforms, toggling barriers, FIRE dart visuals |
| **Thunder Playground** | Storms, electrical relays, energy boosts, machinery | JumpPad-style pads | Timed relay triggers, speed boosts, LIGHTNING darts |
| **Prism Palace** | Mirror walls, glass platforms, creative ricochets | ReflectiveSurface (done), bouncy darts | Many mirrors, transparent floors |
| **Frost Factory** | Ice slides, slippery floors, frozen darts, moving obstacles | Actor movement | Per-surface friction, ICE darts, conveyor obstacles |

Tempest Treehouse is the cheapest next arena because almost all of its systems already exist.

---

## 6. Feature specifications (hardened)

Each feature lists its **rules**, its **guarantees** (edge cases it must survive), and the **tests** that hold it
to that (sections of `tests/test_runner.gd`). Items marked *(v0.1.1)* were added by the hardening pass.

### 6.1 Player controller
- **Rules:** §3.5 numbers. Mouse look clamped to ±86°. The crosshair aims at what's under it.
- **Guarantees:** if the blaster pokes through a wall, darts launch from the eye instead (no shooting through walls).
  Clicking back into the window after alt-tab **re-captures the mouse without firing** *(v0.1.1)*.
  Controls are frozen during the countdown and after the match.
- **Tests:** *Bots play a whole match* (frozen after end); the input actions exist (*Resources load and are sane*).

### 6.2 Darts
- **Rules:** §3.8. Pooled, at most **400 live**; at the cap, the oldest live dart is recycled.
- **Guarantees:** no tunnelling at any speed. Darts never hit their own shooter. Spent darts can't tag.
  Team-mates are passed through.
- **Tests:** *Darts drop under gravity*, *Fast darts cannot tunnel*, *Darts fill the tag meter*, *Bots play a whole match* (pool cap).

### 6.3 Blasters and Arsenal
- **Rules:** §4.1. Semi fires once per pull, auto while held, spin-up only at full spin. Belt-fed blasters never reload.
- **Guarantees:** an empty magazine reloads automatically. Dry-fire clicks once per pull, not every frame.
  At most 4 shots per physics tick (no runaway bursts after a hitch). Swapping cancels a reload.
- **Tests:** *Arsenal: fire modes, magazines, reloads, spin-up*.

### 6.4 Flax's Chainstorm
- **Rules:** §4.2.
- **Guarantees:** no darts until fully spun. Movement penalty applies while spun up. The spin sound stops on pause,
  on death and when leaving the match.
- **Tests:** *Arsenal…* (no early fire, slowdown, belt drain, ≥2× Sprayer rate).

### 6.5 Wind
- **Rules:** §3.9. Zones add up; wind outside every zone is calm (or `global_wind`).
- **Guarantees:** a dart with `wind_response` 0 is unaffected. A moved or rotated zone is honoured immediately (no stale cache, v0.1.0 fix).
- **Tests:** *Wind zones curve darts*; *Backyard Fortress navigation* (windy in Windy Way, calm elsewhere).

### 6.6 Ricochets
- **Rules:** §3.10.
- **Guarantees:** each surface a dart bounces off is ignored for 0.08 s **independently**, so back-to-back bounces between
  close mirrors never let a dart slip through *(v0.1.1; previously the first mirror could stay ignored forever)*.
  Ordinary walls don't reflect unless the dart is bouncy. Speed is reduced per bounce. The bounce limit is respected.
- **Tests:** *Reflective surfaces bounce darts*, *Hardening: back-to-back ricochets*.

### 6.7 Ammo buckets
- **Rules:** §3.11.
- **Guarantees:** tagged-out actors can't drain a bucket. Bottomless (Gun Game) actors take nothing. The bucket never gives
  more than it holds or more than you can carry. An empty bucket shows "EMPTY n" and hides its darts and ring.
- **Tests:** *Ammo buckets refill, drain and regenerate*, *Arsenal…* (capacity).

### 6.8 Tagging, respawn and match flow
- **Rules:** §3.4, §3.6, §3.12.
- **Guarantees:** **anyone tagged out, at any time before the results screen, respawns** *(v0.1.1)*. Points are only scored during play.
  The round ends exactly once, when the clock runs out (or on a Gun Game win). Everyone is frozen on the results screen.
- **Tests:** *Bots play a whole match*, *Hardening: tagged-out actors always respawn*.

### 6.9 Gun Game
- **Rules:** §3.13.
- **Guarantees:** a promotion re-equips immediately if alive, otherwise at respawn. The ladder can be any length (data-driven).
  A tier past the end clamps safely.
- **Tests:** *Scoring: free-for-all and Gun Game*, *Gun Game match*.

### 6.10 Bots
- **Rules:** §3.14.
- **Guarantees:** never stand around holding an empty blaster if another has darts, even mid weapon-lock *(v0.1.1)*.
  A completely dry bot waits at the nearest bucket for it to refill instead of chasing *(v0.1.1)*.
  Bots steer in straight lines until the background navmesh is ready *(v0.1.1)*. Every roam point is reachable.
- **Tests:** *Backyard Fortress navigation*, *Bots play a whole match*, *Hardening: bots never get stuck without darts*.

### 6.11 Loading and data safety *(v0.1.1)*
- **Rules:** the match loads its mode, bot skill and arena from files.
- **Guarantees:** a missing or corrupt mode or skill file falls back to Free-for-all / Normal with a warning, never a crash.
  An out-of-range menu choice is clamped. If the arena itself can't load, the game returns to the main menu.
  The navmesh bakes in the background, so loading a match doesn't freeze the screen.
- **Tests:** *Hardening: broken data never crashes a match*, *Backyard Fortress navigation* (background bake).

### 6.12 Pause and window focus *(v0.1.1)*
- **Rules:** Esc / P / Start toggles pause (not on the results screen).
- **Guarantees:** **losing window focus (alt-tab, the Windows key, a pop-up) pauses a running match** and frees the mouse.
  It doesn't cover the results screen. Unattended demo runs are exempt.
- **Tests:** *Hardening: losing window focus pauses the match*.

### 6.13 Settings *(v0.1.1 additions)*
- **Rules:** mouse sensitivity 0.2–3, FOV 60–110, camera shake 0–1.5, visual effects 0.2–1.5, volume 0–1, fullscreen, invert Y.
  Saved to `user://settings.cfg` when the panel closes.
- **Guarantees:** **Reset to defaults** restores every preference. Out-of-range or garbled saved values are clamped.
  The file carries a version number for future migrations.
- **Tests:** *Hardening: settings reset*.

### 6.14 Effects and performance *(v0.1.1)*
- **Rules:** ordinary impact bursts are limited to **6 per frame** and **48 alive**, both scaled by Visual effects.
  Tag-out and respawn bursts always show. Sounds: 12 voices for the player's own sounds and 16 positional;
  the same sound can't retrigger within 22 ms.
- **Guarantees:** five Chainstorms hosing a wall can't flood the scene with particles. Quitting never leaks audio objects.
- **Tests:** *Hardening: effects budget*; validate.sh fails on "leaked at exit".

### 6.15 HUD
- **Rules:** §8.
- **Guarantees:** the HUD only listens and never changes game state. The scoreboard (Tab) refreshes live. The tag feed keeps 5 rows.

---

## 7. Game feel and audio

| Moment | Feedback |
|---|---|
| Firing | Muzzle puff, view-model kick, a small camera punch, crosshair spread, launch sound per blaster |
| Moving | View-model bob and sway, sprint FOV boost |
| Dart in flight | Coloured foam body, orange tip, a trail that stretches with speed |
| Dart hits scenery | Small foam puff; the dart bounces and rests |
| Dart hits a person | Bigger puff, a soft "thup", a white hit marker for you and a flinch for bots |
| Tag-out | Big orange hit marker, tag jingle, **+100 TAG!** popup, a burst in the victim's colour plus confetti |
| Ricochet | Ripple ring on the mirror, rising "zing", **+50 RICOCHET BONUS!** |
| Bullseye | Spin, ding, confetti, **+10 BULLSEYE!** |
| Being hit | Gentle camera shake and a soft orange screen tint (≤16% opacity, fades in 0.35 s) |
| Chainstorm | Rising motor whine, visible barrel spin, spin bar, rattle, belt advance |

**Audio** is synthesised at startup (`scripts/core/sfx.gd`, DECISIONS D-005): `pop`, `spray`, `chain`, `thump`, `zip` (launches);
`hit`, `hit_confirm`, `tag`, `tagged`, `ricochet`, `ding`, `boing` (impacts); `reload`, `dry`, `ammo`, `swap` (handling);
`beep`, `go`, `ui_click`, `level_up`, `win`, `lose` (flow); `spin` (Chainstorm loop). Any of them can be replaced by a real
recording later; the IDs stay the same.

## 8. UI and visual style

**Palette** (`scripts/core/ui_kit.gd`):

| Token | Hex | Use |
|---|---|---|
| NAVY | `#0b1f4b` | Panels |
| NAVY_DARK | `#071230` | Outlines, bar backgrounds |
| BLUE / SKY | `#1f6bff` / `#57b6ff` | Secondary buttons, labels, the player's team |
| ORANGE / ORANGE_HOT / ORANGE_DEEP | `#ff7a1a` / `#ff9d2e` / `#d95a00` | Primary buttons, highlights, the tag meter |
| CREAM | `#fff4e0` | Main text |
| LIME / PINK / GREY | `#9be22d` / `#ff5fa2` / `#8d9ab8` | Spin bar and "refilling", accents, disabled and empty |

**Shapes and type:** rounded panels (radius 12–22), chunky emboldened type with dark outlines everywhere.
Actor colours: you are blue; the bots are Blaze orange, Pickle green, Zoom purple, Sprinkles pink and Noodle yellow.

**HUD layout:** top left: score, tags, place and Gun Game rung, plus the wind compass · top centre: clock and mode ·
top right: tag feed · centre: crosshair, hit marker, popups, banners · bottom left: tag meter ("DANGER!" at 70%) ·
bottom right: blaster name, ammo (`mag | reserve`, `BELT n`, or `INF`), hints (REFILLING!, RELOADING..., LOW AMMO,
OUT OF DARTS - FIND A BUCKET!), and the Chainstorm spin bar · hold Tab: scoreboard.

**Screens:** main menu (live orbiting arena, both modes, bot count 2–5, bot skill, settings, quit, how to play) →
match → pause (resume, restart, settings, main menu) → results (play again, main menu). Every menu works with keyboard
or gamepad focus as well as the mouse.

## 9. Accessibility and comfort
- **Camera shake** 0–1.5; **0 turns it off entirely**.
- **Visual effects** 0.2–1.5: scales particle counts, the effects budget, muzzle-flash size and the hit tint.
- **No strobing.** The hit tint is soft and short, and there are no full-screen flashes.
- **Field of view** 60–110 (85 default) for players who feel motion-sick.
- **Mouse sensitivity** and **invert look**.
- **Pause anywhere** in a match. Losing focus pauses automatically.
- **Generous design:** bigger bot hitboxes, weaker bot darts, spawn protection, meter regen, auto-reload.
- **Planned:** remappable keys, a colour-blind-safe team palette option, subtitles or icons for important sounds.

## 10. Progression (planned, not built)
Weapon XP and mastery, magazine/accuracy/rate/speed upgrades, cosmetic skins, alternate and elemental darts, barrel
customisation. Upgrades must modify a *duplicated* WeaponData at runtime, never the shared `.tres`. **Don't start this
until playtests show the core combat is fun.** No paid advantages, ever.

## 11. Glossary
| Term | Meaning |
|---|---|
| **Tag** | Filling someone's tag meter to 100 with darts, which knocks them out of play for a moment |
| **Tag meter** | Health, in kid terms. It fills when hit and drains after 4 s safe |
| **Out** | Being tagged (scoreboard column) |
| **Spent dart** | A dart that hit scenery: harmless, bouncing and resting |
| **Spin-up** | The Chainstorm's wind-up before it fires |
| **Belt-fed** | Fires straight from the reserve; no magazine, no reloads |
| **Rung** | A step on the Gun Game ladder |
| **Wind response** | How strongly a dart type is pushed by wind |
| **Bucket** | An ammo refill station that drains and regenerates |
| **Roam point** | A spot bots like to wander to |
