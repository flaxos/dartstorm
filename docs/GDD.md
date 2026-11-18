# DARTSTORM: Elemental Arena — Game Design Document

## 0. Document control

| | |
|---|---|
| **Game version** | 0.7.0 (Zombie Siege & Blaster Skins) |
| **Status** | v0.1.0 **passed UAT** on 2026-11-15; v0.1.1–v0.7.0 validated and awaiting UAT with young players (see [UAT.md](UAT.md)) |
| **Platform** | Linux first (the target machine runs Linux). Windows is deferred until needed. |
| **Authority** | This GDD is the authoritative description of the game. Numbers mirror the `.tres` files in `resources/`. If they ever disagree, the `.tres` file is what the game uses, so fix this doc. |
| **Source vision** | [CONCEPT_BRIEF.md](CONCEPT_BRIEF.md), the original brief, archived verbatim (personal details redacted). §1 summarises it and §2 tracks it. §1.9 records the young players' own design sketch. |
| **Related** | [ARCHITECTURE.md](ARCHITECTURE.md) (how it's built) · [TUNING.md](TUNING.md) (changing numbers without code) · [ROADMAP.md](ROADMAP.md) · [DECISIONS.md](DECISIONS.md) |

---

## 1. Concept (from the original brief)

### 1.1 Pitch
**DARTSTORM** is a colourful, chaotic, first-person foam-dart arena shooter inspired by backyard blaster
battles, classic arena shooters and creative elemental environments. You sprint across a backyard fortress,
lob arcing foam darts that bend in the wind and bounce off mirrors, raid ammo buckets, and, when you get
your hands on it, unleash **Flax's Chainstorm**: a ridiculous, belt-fed, six-barrel foam cannon.

### 1.2 Origin
DARTSTORM is a passion project for young players, built around their own ideas. That shapes every decision:
the people this game must delight are young players who are excited about *their* idea. Flax's Chainstorm is
the signature blaster and is meant to be the highlight of the game.

### 1.3 The vision list (from the brief)
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
- Friendly bots so players can play alone.
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
> *[The project owner] can launch Godot, press Play, run around a colourful arena, shoot moving foam darts at bots, get tags,
> refill ammunition and finish a match.*

✅ **Met in v0.1.0, confirmed by UAT on 2026-11-15.**

### 1.8 The most important rule
> This is a game being made for kids who are excited about their idea. Prioritise the things they can see,
> interact with, laugh at and play. Make it fun. Make it colourful. **Make Flax's Chainstorm absolutely ridiculous.**

---

### 1.9 The young players' own design *(2026-11-16)*
Before they had seen the game, the young players drew their own DARTSTORM: a home screen and a page of ideas.
The photo isn't kept in the repo (it has their names on it). This is what it asked for, and what we're doing about it:

| Their idea | Status | Notes |
|---|---|---|
| **A lobby:** your character in the middle on a round platform, your squad on platforms beside you, a player card top left, a column of buttons on the left, modes top right, the logo bottom middle, a big PLAY bottom right | ✅ v0.3.0 | §3.22, built to their layout |
| **Solo, Duo and Team modes** | ✅ v0.3.0 | SOLO, DUOS, TEAMS (Blue vs Orange), §3.21 |
| **Zombie mode** | ✅ v0.5.1 | Goofy green foam zombies: tagged players join the horde (§3.21) |
| **Fire, Water and Electric** (lightning bolts everywhere) | ✅ v0.5.0 | Elemental darts (Wind, Fire, Water, Lightning, Ice) and 10-rung Gun Game ladder (§2.4) |
| **Goggles, bunny ears, horns, spiky hair** (their characters) | ✅ v0.3.0 | New hats (§3.16) |
| **Shield** | ✅ v0.5.2 | Foam Shield power-up: glowing hexagonal bubble absorbs 50 tag points (§3.23) |
| **Missions, Level, Coins, Shop** | ✅ v0.5.3 | Player levels, XP, 3 active backyard missions, cosmetic Coin Shop, zero real money (§10, D-028, D-036) |
| **Gems** | ✗ Not doing | A second currency is a pattern built to sell things |
| **Chat, Clan, 32 players, League, Private** | ✗ Not now | Needs online play; chat isn't safe for young players. Couch/LAN play may come later (D-008) |
| **Phone controls** (LEFT/RIGHT sticks, SHOOT button) | ✅ by controller | The PC version does this with a gamepad (§3.17) |
| **Zombie Siege (Base Defense)** | ✅ v0.7.0 | Defend the Base Core & barricades against 5 zombie waves and the Titan Boss (§3.24) |
| **Blaster Skins** | ✅ v0.7.0 | Anti-slop 2D vector patterns, tactile PBR finishes, 8 collectible skins in Coin Shop (§10.2) |

## 2. Brief traceability

Status key: ✅ done · 🟡 partly done or untested · ⏳ planned, not started. Brief section numbers refer to
[CONCEPT_BRIEF.md](CONCEPT_BRIEF.md).

### 2.1 Technical stack (brief §2)
| Requirement | Status | Where / notes |
|---|---|---|
| Godot 4 (latest local stable), GDScript | ✅ | Godot 4.4.1, typed GDScript |
| 3D first-person shooter | ✅ | `scripts/player/player.gd` |
| Windows primary target | ⏳ | Deferred: the target machine runs Linux. Nothing Windows-specific in the code |
| Linux secondary target | ✅ | Developed and UAT'd on Linux; now the primary platform |
| Keyboard and mouse | ✅ | `scripts/core/input_setup.gd` |
| Gamepad (planned) | 🟡 | **Built in v0.2.0**: plug and play for menus and play, hot-plug, aim assist, rumble (§3.17). Tested with simulated input; a real pad still needs trying |
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
| ≥2 bots that move, find, aim, fire, react, respawn, navigate, configurable difficulty | ✅ | 2–7 bots, Easy/Normal/Hard, navmesh (§3.14) |
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
| Elemental effects | ✅ | `elemental_effect.gd`: Wind lift, Fire sparkle tick, Water knockback/wet, Lightning chain zap, Ice chill/slow, combos (steam, conductive shock) |
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
| Muzzle flash, launch sounds, subtle shake, recoil, trails, foam particles, hit confirmation, score popups, tag sounds, Chainstorm spin feedback | ✅ | §7; upgraded with 2nd-order spring-damper sway, landing dip, and sprint canting |
| Avoid excessive shake, flashing, clutter; shake and intensity settings | ✅ | §9; effects budget added in v0.1.1 |
| Gun Game: start weakest, advance per tag, ladder stored in data | ✅ | `resources/modes/gun_game.tres` |
| Full 10-rung ladder | ✅ | Full 10 rungs: Popper, Double, Sprayer, Wind Whisperer, Hammer, Hydro Soaker, Ricochet, Thunder Cannon, Longshot, Chainstorm |
| Elemental arenas: architecture documented | ✅ | §5.2, ARCHITECTURE §9 |
| Elemental arenas built | ⏳ | Not yet. Playable arenas: Backyard Fortress and Home Turf (§5.3, v0.4.0) |
| Buckets: configurable amount, team or neutral colour, detect players, refill weapons, empty state, regen delay | ✅ | `AmmoBucket` (§6.7) |
| Chainstorm's high ammo use makes buckets strategic | ✅ | A full bucket is ≈5 s of Chainstorm fire |
| Capturable team buckets | ⏳ | Roadmap |
| Weapons as Resources; config, presentation and runtime separate | ✅ | `WeaponData` / `BlasterModel` / `Arsenal` |
| Character customisation (vision list) | 🟡 | Name, 8 colours, 11 hats (§3.16). Outfits and blaster skins later |
| Blue team versus orange team; team battles (vision list) | ✅ | v0.3.0: TEAMS (Blue vs Orange) and DUOS (§3.21) |
| XP, mastery, upgrades, skins, alternate and elemental darts | ⏳ | Deliberately deferred until combat is proven fun (§10) |
| No microtransactions | ✅ | And never |
| HUD: crosshair, weapon name, ammo, tag meter, timer, score, wind, hit confirmation, ricochet notice | ✅ | §8 |
| Deep blue, vibrant orange, rounded, chunky fonts | ✅ | Lilita One (SIL Open Font License) everywhere since v0.2.0 |
| Main menu, settings, pause | ✅ | Plus **Reset to defaults** in v0.1.1. The main menu became the players' own lobby design in v0.3.0 (§3.22) |

### 2.5 Engineering and process (brief §11–§16)
| Requirement | Status | Where / notes |
|---|---|---|
| Suggested project layout | ✅ | ARCHITECTURE §1 |
| Typed GDScript, signals, Resources, few singletons (2), error handling | ✅ | Hardened loading in v0.1.1 |
| No placeholder/TODO core features, no fabricated assets | ✅ | All assets generated in code (`assets/README.md`) |
| Headless validation and automated tests | ✅ | `tools/validate.sh`: import, strict compile (zero warnings), boots, 251 tests, leak check |
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
| Results | Until a choice | Everyone frozen. The camera cuts to the **podium** (§3.20): the top three dance under confetti, with a results panel ("YOU WIN!" / "PICKLE WINS!", table, awards, **PLAY AGAIN** / **MAIN MENU**) |

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
| Wind Spiral Dart | Wind Whisperer | 52 | 0.40 | 0.08 | 0.19 s / 0.08 m | 0.39 s / 0.31 m | 0.59 s / 0.69 m | 0.79 s / 1.24 m | 43 m |
| Sparkle Dart | Pyro Blaster | 42 | 0.65 | 0.22 | 0.25 s / 0.20 m | 0.50 s / 0.80 m | 0.78 s / 1.86 m | 1.07 s / 3.43 m | 26 m |
| Splash Balloon Dart | Hydro Soaker | 36 | 0.95 | 0.30 | 0.29 s / 0.40 m | 0.61 s / 1.67 m | 0.96 s / 3.98 m | 1.36 s / 7.58 m | 18 m |
| Volt Bolt Dart | Thunder Cannon | 55 | 0.45 | 0.12 | 0.18 s / 0.08 m | 0.37 s / 0.31 m | 0.56 s / 0.71 m | 0.76 s / 1.27 m | 42 m |
| Frost Crystal Dart | Frost Ranger | 46 | 0.60 | 0.18 | 0.22 s / 0.15 m | 0.45 s / 0.61 m | 0.69 s / 1.39 m | 0.95 s / 2.53 m | 30 m |

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
You pick your own colour and hat (§3.16). Each bot has its own hat (Blaze a cap, Pickle a beanie, Zoom a propeller hat,
Sprinkles a party hat, Noodle a cowboy hat) and carries its blaster (the Chainstorm comes with a backpack), with a name
tag and a tag meter floating above. If your colour is close to a bot's, that bot switches to a spare colour.

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

### 3.16 Your player: name, colour, hat *(v0.2.0)*
Lobby → **CHARACTER** (called YOUR PLAYER before v0.3.0). The camera zooms in on you while you choose.
- **Name:** up to 12 letters, numbers, spaces, `-` or `_`. Blank shows as "You". **RANDOM** picks a fun name
  (Captain Foam, Sir Splat, Ricochet Rex, …) so a controller player never needs to type.
- **Colour:** 8 choices (blue, red, green, purple, pink, yellow, orange, teal). **Your darts fly in your colour**,
  and your name shows in it in the tag feed and scoreboard.
- **Hat:** cap, beanie, propeller (it spins!), party hat, cowboy hat, crown, goggles, bunny ears, horns, spiky hair, or
  no hat. The last four came from the young players' drawing (§1.9). Bots wear hats too.
- **Team modes:** your shirt and darts switch to your team's colour (your hat stays), so friends are easy to spot.
- Saved on this computer only (`~/.local/share/dartstorm/settings.cfg`). **Reset to defaults** in Settings doesn't touch your look.

### 3.17 Playing with a controller *(v0.2.0)*
Plug a pad in at any time, even mid-match: a notice pops up ("… connected - ready to play!") and it just works.

| Action | Controller |
|---|---|
| Move / look | Left stick / right stick |
| Jump | A |
| Sprint | LT, or click the left stick |
| Fire | RT |
| Reload | X |
| Switch blaster | Y or RB (next), LB (previous) |
| Scoreboard / pause | Back / Start |
| Menus | D-pad or left stick to move, **A** to press, **B** to go back |

- **Fine aim:** the right stick is curved (stick² response), so small nudges aim precisely and full tilt still turns fast.
  Its speed is adjustable (Settings → *Controller look speed*, 0.4–2.0).
- **Aim assist** (on by default, Settings toggle): turning slows to half while your crosshair is over a rival. It never
  moves your aim for you.
- **Rumble** (Settings toggle): a light buzz per shot, a thump when you're hit, a kick when you tag someone, a big rumble when
  you're tagged. Only while a controller is the device you're using.
- **Unplugging** a controller mid-match pauses the game, as on a console.
- The main menu's HOW TO PLAY box switches to controller buttons as soon as you touch the pad.

### 3.18 The announcer *(v0.2.0)*
Big call-outs under the clock, each with its own jingle. A bot's call-outs carry its name ("PICKLE: DOUBLE TAG!").

| Call-out | When |
|---|---|
| FIRST TAG! | The first tag of the match |
| DOUBLE TAG! / TRIPLE TAG! / FOAM FRENZY! | 2 / 3 / 4+ tags within 4 seconds |
| ON A ROLL! / UNSTOPPABLE! / DARTSTORM!! | 3 / 5 / 8 tags without being tagged out |
| SHUT DOWN! | Ending someone's streak of 3 or more |
| 1 MINUTE LEFT! / 10 SECONDS! | Time warnings |
| …HAS LANDED! / …GRABBED… | Power-up mode (§3.19) |
| STORM MODE! | A popup for you the first time your Chainstorm reaches full spin in each life |

Up to 3 call-outs queue; each shows for 1.6 s.

### 3.19 Chainstorm power-up mode *(v0.2.0, optional)*
Main menu → **CHAINSTORM: EVERYONE / POWER-UP**. The default is EVERYONE, as the brief specifies.
In **POWER-UP** (Backyard Battle only; Gun Game ignores it):
- Everyone starts with the Pocket Popper and the Dart Sprayer only.
- **Flax's Chainstorm** lands on the **treehouse deck** 20 s into play, as a giant spinning Chainstorm in a tall orange beam you can
  see from anywhere. The announcer shouts "FLAX'S CHAINSTORM HAS LANDED!".
- First to touch it gets it in their hands with a **300-dart belt**, and keeps it until they're tagged out. Buckets refill it.
- It returns **45 s** after each grab ("CHAINSTORM IN 12" counts down over the deck).
- Bots race for it when nobody's in sight or it's within 22 m.
- Design intent: make the Chainstorm the thing everyone fights over. Whether it beats "everyone has it" is a question for
  the players' playtest.

### 3.20 End of match: podium and awards *(v0.2.0)*
When the round ends the camera cuts to a little **stage floating in the sky**: the top three on gold, silver and bronze steps,
wearing their hats, bouncing and spinning (the winner highest) under a shower of confetti with a crowd cheer.
On the right, the results panel shows the winner, the table, the **awards** and **PLAY AGAIN** / **MAIN MENU**.
The menu music returns after 3 seconds.

**Awards** (up to 5; each needs a minimum, so none are handed out for zero):

| Award | Goes to | Minimum |
|---|---|---|
| Sharpshooter | Best hit rate | 20 darts fired, 25% hits |
| Ricochet King | Most ricochet tags | 1 |
| Storm Bringer | Most Chainstorm darts fired | 60 |
| Bucket Hog | Most darts scooped from buckets | 60 |
| Bullseye Boss | Most bullseyes | 1 |
| Hot Streak | Longest streak | 3 |
| Foam Magnet | Tagged the most | 3 |

### 3.21 Team modes: SOLO, DUOS and TEAMS *(v0.3.0)*
| Mode | Who's on your side | Bots | Wins |
|---|---|---|---|
| **SOLO** (Backyard Battle) | Nobody: everyone for themselves | 2–7 | Most points |
| **DUOS** | You and one bot buddy, against other pairs (blue, orange, green, purple) | Rounded up to make pairs: 3 → 3 (2 pairs), 4 → 5 (3 pairs), 7 → 7 (4 pairs) | The pair with the most points added together |
| **TEAMS** (Blue vs Orange) | Half the players. You're always **blue** | Rounded up to make even teams: 2 → 3 (2 v 2), 5 → 5 (3 v 3), 7 → 7 (4 v 4) | The team with the most points added together |
| **GUN GAME** | Nobody | 2–7 | First to tag with the last blaster |

- **No friendly fire:** your darts fly straight through team-mates. Bots never aim at team-mates, and aim assist ignores them.
- **Team colours:** everyone on a team wears the team colour (shirt, darts, name), and keeps their own hat.
- **Home ends (TEAMS):** blue starts and respawns at the **Blue Fort** end, orange at the **Orange Fort** end. DUOS uses the
  normal "far from rivals" spawns (ignoring your buddy).
- **Scoring:** the usual points (§3.12) for each player. The team score is everyone's points added up.
- **HUD:** coloured team chips under the clock (`BLUE 1200  ORANGE 900`), your team outlined. The score panel says
  `TEAM PLACE 1/2`. The scoreboard groups players under their team's total.
- **Announcer:** "YOUR TEAM TAKES THE LEAD!" / "ORANGE TEAM TAKES THE LEAD!" whenever a different team goes in front.
- **End:** "YOUR TEAM WINS!", "ORANGE TEAM WINS!" or "IT'S A DRAW!" (level points and tags). On the podium each **step holds a
  whole team**, winners on top, with the banner in the winning team's colour. Awards are still for individual players.
- **ZOMBIES mode *(v0.5.1)*:** 1 player/bot begins as the **Alpha Zombie** ("Patient Zero"). All other players are **Survivors** equipped with foam blasters (Pocket Popper, Dart Sprayer, Hydro Soaker, Frost Ranger).
  Zombies carry no blasters, run at high speed (11.2 m/s sprint) with green foam bodies (`Color(0.38, 0.78, 0.28)`) and outstretched cartoon arms.
  A single melee touch or claw swipe from a zombie infects a survivor, tagging them out (+150 infection score) and causing them to pop into confetti and respawn on the horde team.
  Survivors fight back with blasters: Water darts knock zombies back, Ice darts chill and slow them down, and 100 tag power knocks a zombie out (+100 tag score) to respawn far away.
  Survivors win if at least one survivor survives until the 180s clock expires; Zombies win early if all survivors are turned.
  Winning team takes the top step of the podium ("SURVIVORS WIN!" / "ZOMBIES WIN!"), with goofy zombie celebration dances.

### 3.22 The lobby (the young players' design) *(v0.3.0)*
The main menu is the players' own drawing (§1.9), built in 3D:
- **The bunker:** a floating grass island just south of the yard, with the backyard softly blurred behind. **You** stand
  in the middle on a big white platform with a gold ring, holding the Chainstorm. Your bots stand on platforms around you.
  Back rows stand higher, like a team photo. Each has a name tag over their head (the speech bubbles in the drawing), a
  ring in their colour, and a blaster. In DUOS and TEAMS everyone wears their match colour and team-mates stand nearest.
  Now and then someone does a little hop. Two yellow lightning bolts crackle overhead.
- **Top left:** the player card, "*NAME*'S BUNKER" (or "YOUR BUNKER" with a "SET YOUR NAME!" hint), with **CHARACTER**,
  **HOW TO PLAY**, **SETTINGS** and **QUIT** under it.
- **Top right:** **PICK A MODE**: four cards (SOLO, DUOS, TEAMS, GUN GAME), a one-line description, **BOTS − n +** with
  what it means ("3 v 3", "3 PAIRS", "+1 BOT TO EVEN THE TEAMS"), **BOT SKILL** and **CHAINSTORM** (EVERYONE / POWER-UP;
  hidden for Gun Game). Everything is remembered.
- **Bottom middle:** the DARTSTORM logo with three blue swooshes. **Bottom right:** a huge **PLAY** button with the
- Planned from the drawing: a level and coins on the card, and MISSIONS / SHOP buttons in the column (§10).

### 3.23 Foam Shield & Environmental Hazards *(v0.5.2)*
- **Foam Shield Power-Up (`ShieldPickup`):** A floating, glowing hexagonal forcefield bubble in a cyan light beam.
  - Touching it grants 50 shield points, surrounding the character in a procedural holographic hexagonal bubble (`foam_shield.gdshader`).
  - Absorbs incoming dart tag power 1:1. When broken, leftover damage spills onto the tag meter and the shield pops with a sparkling burst (`&"shield_pop"`).
  - In ZOMBIES mode, a shield absorbs 50 points of an infection touch, giving the survivor a crucial escape opportunity instead of an instant tag-out.
  - Displayed on the HUD as a cyan shield gauge right above the tag meter. Respawns 30s after pickup.
- **Conductive Water Puddles (`WaterPuddle`):**
  - Shallow glossy pools located in both arenas (garden tap and kitchen sink).
  - Walking through applies the `wet` status (4.0s) and splashes foam droplets.
  - Shooting a puddle with a Lightning dart or Thunder Cannon conducts electricity across the entire surface for 2.0s (`&"zap"`), shocking and tagging any players inside!
- **Frictionless Ice Slicks (`IceSlick`):**
  - Frosty glistening patches placed on ramps and slides (the backyard yellow slide and the Home Turf toy race-track ramp).
  - Stepping on an ice slick drops friction to zero and launches the player down the slope with an instant high-velocity slide-boost (+9.5 m/s, `&"ice_slide"`).
  - Fire darts temporarily melt ice slicks into water and steam for 3.5s before they refreeze.
- **Interactive Wind Vents (`WindVent`):**
  - Floor vents with spinning fan blades that provide an upward buoyant air launch.
  - Elemental darts infuse and amplify the wind stream for 5.0s (Fire embers, Water mist, Ice blizzard, Lightning plasma), applying those statuses to passing players.
  - Steam combos triggered near vents billow into massive 60-particle amplified steam clouds!

### 3.24 Zombie Siege Mode: Base Defense *(v0.7.0)*
- **Concept:** Co-op/solo survival where players fortify and defend the central **Base Core** against 5 escalating waves of foam zombie hordes.
- **Base Core (`BaseCore`):**
  - High-durability objective (1000 HP) located at the yard centre with pulsing core rings and a 3D rotating health billboard.
  - Emits flashing yellow/orange warnings under 600 HP, and red siren strobe alarm lighting with klaxons under 350 HP.
  - Can be repaired by defenders during intermissions (+250 HP per 100 scrap). If destroyed, the siege fails ("BASE CORE DESTROYED — MATCH OVER!").
- **Destructible Barricades (`BaseBarricade`):**
  - 4 perimeter foam/wood barriers (250 HP each) blocking choke points around the base.
  - Solid collision blocks zombie pathing; flashes yellow/red as damage accumulates. Disables collision when broken.
  - Can be rebuilt during intermissions (75 scrap) to restore full integrity.
- **Wave Director & Escalation (`HordeDirector`):**
  - 5 escalating waves:
    - Wave 1: 10 Standard Zombies (introductory swarm).
    - Wave 2: 15 Zombies including Fast Runners (sprint speed 11.2 m/s).
    - Wave 3: 20 Zombies including Armored Brutes (220 HP, 1.35x scale, heavy damage).
    - Wave 4: 25 Zombies mixed swarm with aggressive perimeter flanking.
    - Wave 5: 30 Zombies led by the **Mega Titan Boss** (650 HP, 1.85x scale, massive foam shockwaves).
  - Spawning: Controlled perimeter batches of 3 zombies every 2.2s to prevent swarming lag while maintaining relentless horde pressure.
  - Intermission: 20s fortification phase between waves where all ammo buckets instantly refill, defenders collect scrap, and repairs can be executed.
- **Economy:** Zombie tags drop scrap (+15 standard, +25 runner, +40 brute, +100 boss).
- **Zombies AI Targeting:** Zombies prioritize hitting the Base Core and Barricades when within range, but aggressively swarm survivors who venture close (< 6m).

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

Keys `1 2 3`, the mouse wheel or `Q`/`E` (controller: Y, LB, RB) switch blasters (0.3 s swap). In free-for-all you carry the
Popper, the Sprayer and the Chainstorm, unless power-up mode is on (§3.19).

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

**Backyard life** *(v0.2.0)*:

| Prop | Where (x, z) | What it does |
|---|---|---|
| Dog house and dog | (29.5, −15.5), orange half | Solid cover. Hit it with a dart and the dog **jumps up and barks** (no points, 0.8 s cooldown). Its tail wags |
| Swing set | (−29.5, 15), blue half | Solid legs (bots path around them); the two swings sway |
| Paddling pool and rubber duck | (−28.5, −15.5) | Wade through it; the duck bobs and turns |
| Sprinkler | (−31.5, −20) | Sweeps a water arc back and forth |
| Garden gnomes ×3 | By the hedge, the trunk, the orange fort | Little decorations to spot |
| Flower beds | Along the north and south fences | Colour |
| Birdsong | The trees around the yard | A tweet every few seconds |

The treehouse deck also hosts the power-up spot (§3.19).

### 5.2 Future elemental arenas (designed, not built)
| Arena | Signature mechanic | Reuses | Needs |
|---|---|---|---|
| **Tempest Treehouse** | Wind tunnels, gusts, vertical climbs, long curved shots | WindZone `gust_amount`, WindField `global_wind`, JumpPad | Gust timing, vertical layout |
| **Ember Workshop** | Glowing vents, moving platforms, temporary flame barriers (**playful, never burns**) | ArenaKit, wind as heat updraft | AnimatableBody3D platforms, toggling barriers, FIRE dart visuals |
| **Thunder Playground** | Storms, electrical relays, energy boosts, machinery | JumpPad-style pads | Timed relay triggers, speed boosts, LIGHTNING darts |
| **Prism Palace** | Mirror walls, glass platforms, creative ricochets | ReflectiveSurface (done), bouncy darts | Many mirrors, transparent floors |
| **Frost Factory** | Ice slides, slippery floors, frozen darts, moving obstacles | Actor movement | Per-surface friction, ICE darts, conveyor obstacles |

Tempest Treehouse is the cheapest next arena because almost all of its systems already exist.

### 5.3 Home Turf: a family home, toy-sized *(v0.4.0)*
A fictional suburban family home and the streets around it: battle through the rooms and out into the street.

> **Fictional world (D-031):** every DARTSTORM place is made up. No real addresses, street, suburb, park or shop names,
> people's names or reference photos go in the repo, commits or PRs. Sizes are rounded game sizes.

**The house:** a single-storey home: an open family room and kitchen at the back, a covered patio beside it, a lounge
and dining area in the middle, four bedrooms (one with its own bathroom), a bathroom and laundry, an entry with a small
porch, and a double garage.

| Zone | Game size (m) | Game idea |
|---|---|---|
| Family room and kitchen (back of the house) | ~24 × 12 | Central battleground: kitchen island and bench as cover, fridge, big back windows |
| Covered patio (beside the family room) | ~27 × 15 | Outdoor fight under a roof: BBQ, outdoor table |
| Lounge and dining | ~24 × 12 | Couch fort, TV wall, a table to duck under |
| Two small bedrooms | ~10 × 10 each | Bunk beds, toy boxes, built-in wardrobes as hiding spots |
| Study | ~10 × 9 | Desk, bookshelves |
| Main bedroom with walk-in wardrobe and bathroom | ~11 × 11 | Bed as a trampoline |
| Bathroom, laundry, hallway | narrow | Tight corridors linking the wings: ambush routes |
| Entry and front porch | small | Front-door spawn |
| Double garage (beside the patio) | ~17 × 17 | Two parked cars as cover, a workbench, the roller door out to the driveway |

**Scale:** players are **toy-sized**. Real rooms are far too small for a shooter at our running speed (7 m/s), so the
house is built about **×3** (a 4 m room becomes 12 m), as in the table. Furniture becomes giant cover. Chairs are
climbable platforms, the kitchen island is a fort, and beds are trampolines (JumpPad). This is the "shrunk to toy size
at home" fantasy.

**The suburb** (later, bigger map): a curving street with a roundabout, front yards, **Splash Pond** park with a little
stream, a playing field (**Foam Field**) and footpaths. It suits ZOMBIES and big TEAMS games, and the pond is perfect
for the planned **Water** darts.

**Built in v0.4.0** (`scripts/arena/home_turf.gd`), house, patio, garage, yards and street as one arena. Pick it in
the lobby: **ARENA: HOME TURF**.

| Callout | Where | What's there |
|---|---|---|
| **Kitchen / family room** | Back middle | Kitchen island (2.7 m fort), bench, fridge, a meals table you can crawl under or climb (chair → table), and a **giant pedestal fan** blowing across the room toward the patio (the house's wind zone) |
| **Lounge** | Middle | Couch, coffee table (a jump-up step), TV. **The Chainstorm power-up lands here** |
| **Hall** | Long corridor west of the kitchen | Doors to bedroom 3, the laundry, the bathroom and bedroom 2; an archway into the kitchen |
| **Bedroom 3** | Back corner | A loft bed with a **trampoline** beside it to bounce up there; a toy-box ammo bucket |
| **Laundry** | Off the hall | Laundry-basket ammo bucket; a door out to the **west side path** |
| **Bathroom / ensuite / wardrobe** | West side | Three **mirrors** for ricochet shots |
| **Bedroom 2 / main bedroom** | West side | **Beds are trampolines** |
| **Dining** | Middle west | A long table with a chair step at each end |
| **Study** | Front west | Desk (chair step), bookshelf, a dartboard |
| **Entry** | Front middle | Front door to the porch; doors to the lounge, study, main bedroom and garage |
| **Garage** | Front east | Two toy cars (huge cover), a workbench and dartboard, roller door to the driveway, side doors to the patio and east lawn |
| **Patio** | Back east | Covered decking with a barbecue, an outdoor table and pot plants. **Its roof is a platform**: run up the **orange toy race-track ramp** from the east lawn. Up there: a ball, a frisbee and a paper plane as cover |
| **Backyard** | North | Shed, sandpit with a toy truck, a big tree, a dartboard on the fence |
| **Front yard and street** | South | Driveway, letterbox (no number), a front tree, the footpath, the street with a parked car |

- **Toy scale:** walls are 9 m tall (nobody gets on top of them), doors 3.6 m wide, chair seats 1.2 m (one jump), tables
  2.25 m (chair, then table). Trampolines launch at 12–14 m/s.
- **Dollhouse:** no roof, so the sun reaches every room. A high sun and warm fill light keep the shaded rooms sunny.
  The fan's wind zone hides its tinted box indoors (`WindZone.show_volume`).
- **Teams:** blue's end is the front (driveway and garage), orange's is the backyard; 8 home spawns each.
- **Loops:** the west side path and the east lawn both join the front and back yards, so there's always a way round.
- **Later:** the suburb map (Splash Pond park, Foam Field) as a separate, bigger arena.

### 5.4 Tempest Treehouse: high canopy decks and chasm *(v0.6.0)*
A sprawling multi-tier canopy fort built high into ancient backyard trees, high above the mossy forest floor.

> **Fictional world (D-031):** like all DARTSTORM arenas, the ancient treehouse grove is completely fictional.

**Built in v0.6.0** (`scripts/arena/tempest_treehouse.gd`), playable across all modes (FFA, Gun Game, Duos, Teams, Zombies). Pick it in the lobby: **ARENA: TEMPEST TREEHOUSE**.

| Zone | Elevation | Description & Features |
|---|---|---|
| **Blue Canopy Fort** | $Y = 5.4\text{ m}$ (West, $-X$) | Fortified lookout hut, team sign, perimeter railings, ammo bucket, kinetic jump-pad launching up to the Crow's Nest. |
| **Orange Canopy Fort** | $Y = 5.4\text{ m}$ (East, $+X$) | Symmetrical fortified lookout hut, team sign, cover crates, ammo bucket, kinetic jump-pad launching up to the Crow's Nest. |
| **Suspension Rope Bridge** | $Y = 5.4\text{ m}$ ($Z = 0.0$) | $20\text{ m}$ wooden plank bridge spanning the canopy chasm between Blue and Orange Forts with catenary sag and rope railings. |
| **High Crow's Nest & Spire** | $Y = 10.5\text{ m}$ (North, $-Z$) | High central treehouse platform around the North ancient tree. Houses the Chainstorm power-up and the Foam Shield pickup. |
| **Canopy Escape Ice Slide** | $Y = 10.5 \to 5.4\text{ m}$ | Frictionless ice slick chute (+9.5 m/s slide-boost) plunging from Crow's Nest down across the chasm to the bridge. |
| **Forest Floor Grove** | $Y = 0\text{ m}$ (Ground) | Lush lawn and buttress roots, Ammo Bucket, Ground Jump-Pad, Upward Wind Vent ($16.5\text{ m/s}$ lift), and Conductive Bird-Bath Puddle. |
| **Gale Wind Tunnels** | Upper & Lower | Upper canopy wind zone blowing West to East at $28\text{ m/s}$, sweeping darts across the chasm; gentle lower floor cross-breeze ($12\text{ m/s}$). |

- **Multi-tier traversal:** 14 balanced spawns (7 Blue, 7 Orange). Ramps link ground to mid-decks and mid-decks to the High Crow's Nest, supplemented by kinetic jump-pads, upward wind vents, and the escape ice slide chute.
- **Elemental interactivity:** Wet puddle conducts lightning from Thunder Cannon darts; ice slide enables high-speed frictionless escapes; wind tunnels curve and amplify dart trajectories across the chasm.

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

### 6.13 Settings *(v0.1.1; extended in v0.2.0)*
- **Rules:** two columns. **Controls:** mouse sensitivity 0.2–3, controller look speed 0.4–2, invert look, controller aim assist,
  controller rumble. **Video & sound:** FOV 60–110, camera shake 0–1.5, visual effects 0.2–1.5, fullscreen, volume, music and
  sound effects 0–1. Saved to `user://settings.cfg` when the panel closes (DONE, or B / Esc).
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

### 6.16 Controller support *(v0.2.0)*
- **Rules:** §3.17. Every binding uses "any device", so whichever pad is plugged in works.
- **Guarantees:** every gameplay action and every menu works with a pad (A presses, B goes back). Hot-plug shows a notice.
  Unplugging mid-match pauses. Rumble does nothing (safely) without a pad. Aim assist only slows turning, never steers.
- **Tests:** *Controller: plug and play* (bindings, simulated right stick turns, simulated trigger fires, aim assist slows
  over a rival, hot-plug notice, unplug pauses).

### 6.17 Your player *(v0.2.0)*
- **Rules:** §3.16.
- **Guarantees:** names are cleaned (trimmed, odd characters removed, capped at 12). Bots never share or nearly share your
  colour, or each other's. Every hat builds.
- **Tests:** *Your player: name, colour, hat*.

### 6.18 Announcer *(v0.2.0)*
- **Rules:** §3.18. The MatchController decides the call-outs; the HUD queues and shows them.
- **Tests:** *Announcer call-outs*.

### 6.19 Chainstorm power-up mode *(v0.2.0)*
- **Rules:** §3.19.
- **Guarantees:** the per-match switch is set on a private copy of the mode, so the shared `.tres` never changes. The countdown
  only runs during play. Being tagged out loses the Chainstorm. Gun Game ignores the mode.
- **Tests:** *Chainstorm power-up mode*.

### 6.20 Podium and awards *(v0.2.0)*
- **Rules:** §3.20. Award stats (darts fired, hits, darts collected, bullseyes, Chainstorm darts, streaks) only count during play.
- **Tests:** *End-of-match podium and awards*.

### 6.21 Music and audio *(v0.2.0)*
- **Rules:** §7. Separate Music and SFX volume, both under the master volume.
- **Guarantees:** the music renders on a worker thread (startup never waits for it). Quitting waits for any render still
  running. Music is quieter (−9 dB) while paused.
- **Tests:** *Chunky font, music and sounds*.

### 6.22 Backyard props *(v0.2.0)*
- **Rules:** §5.1 Backyard life. Solid props live under the arena's geometry, so bots path around them.
- **Tests:** *Backyard props*; *Backyard Fortress navigation* (every roam point still reachable with the props in place).

### 6.23 Team modes *(v0.3.0)*
- **Rules:** §3.21. Data: `GameMode.teams` (SOLO, DUOS, BLUE_VS_ORANGE) in `resources/modes/duos.tres` and
  `blue_vs_orange.tres`; `team_for()`, `bots_for()`, `rank_teams()`, `winning_team()`, `podium_places()`.
- **Guarantees:** teams are always even (an extra bot is added, never more than the 7-bot roster). Team-mates can't tag
  each other (darts pass through). TEAMS respawns are always at your own end. Level team scores are a draw, never a
  random winner. Solo modes behave exactly as before (each player is a "team" of one).
- **Tests:** *Team modes: rules*, *Team modes: Blue vs Orange match*, *Team modes: Duos match*.

### 6.24 Lobby *(v0.3.0)*
- **Rules:** §3.22.
- **Guarantees:** the squad shown is exactly the bots the next match will bring (same count and colours, from
  `MatchScene.team_bot_count()` and `bot_colors()`). PLAY has focus on arrival. Up to 7 bots fit on the island. B closes
  CHARACTER and HOW TO PLAY. Bots in matches wear their own hats (a v0.2.0 bug where they all wore caps is fixed).
- **Tests:** *Lobby (the players' own menu design)*, *Bots wear their own hats*.

### 6.26 Home Turf *(v0.4.0)*
- **Rules:** §5.3. Chosen in the lobby (`GameSettings.arena`, `MatchScene.ARENAS`).
- **Guarantees:** every spawn point is clear of walls and furniture; every room, both side paths and the patio roof
  are on the bots' navmesh; each team has at least 6 home spawns; everyone stays inside the lot (fences and invisible
  walls). Nobody ever spawns on top of anyone (all arenas; a v0.3.0 TEAMS bug fixed here).
- **Tests:** *Home Turf: a toy-sized house*, *Home Turf: a whole bot match*, *Nobody spawns on top of anyone*.
- **Layout check by eye:** `godot --path . -s res://tools/arena_shots.gd -- --arena=1 --shots=<abs dir>` saves views
  from above and from each corner (add `--look=x,y,z:tx,ty,tz` for more).

### 6.25 Linux build *(v0.2.0)*
- **Rules:** `./tools/export_linux.sh` → one executable plus icon, README and `install-shortcut.sh`; settings in
  `~/.local/share/dartstorm/` (D-027).
- **Guarantees:** the script refuses to run without matching export templates, and fails if the exported game doesn't
  boot headless and quit cleanly.
- **Tests:** *Linux build: export preset*, plus the script's own smoke test.

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

**Audio** is all generated in code (`scripts/core/sfx.gd`, DECISIONS D-005), so there are no sound files.
- **Sound effects** (SFX bus): launches `pop`, `spray`, `chain`, `thump`, `zip` (a tone plus a breathy "fwip" of air);
  impacts `hit` (a foam "thwap"), `hit_confirm`, `tag`, `tagged`, `ricochet`, `ding`, `boing`; handling `reload`, `dry`,
  `ammo`, `swap`; flow `beep`, `go`, `ui_click`, `level_up`, `win`, `lose`; announcer `announce`, `streak`, `shutdown`,
  `powerup`; podium `cheer`; controller `connect`, `disconnect`; backyard `woof`, `chirp`; the `spin` Chainstorm loop.
- **Music** (Music bus, *v0.2.0*): two chiptune loops rendered on a worker thread at startup. **Menu:** 108 BPM, soft pads,
  a gentle triangle-wave tune, 4 bars (≈8.9 s). **Match:** 140 BPM, C–G–Am–F, a pulse-wave lead, bass, chord stabs and drums,
  8 bars (≈13.7 s). It crossfades between tracks, gets quieter on pause, and stops at the final whistle for the win/lose
  sting and cheer before the menu tune returns.
- Any sound can be replaced by a real recording later; the IDs stay the same.

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

**Shapes and type:** rounded panels (radius 12–22) and **Lilita One**, a chunky rounded display font (SIL Open Font
License, `assets/fonts/`), with dark outlines everywhere.
Actor colours: you choose (default blue); the bots are Blaze orange, Pickle green, Zoom purple, Sprinkles pink and Noodle
yellow, and swap to a spare colour if yours is close to theirs.

**HUD layout:** top left: score, tags, place and Gun Game rung, plus the wind compass · top centre: clock and mode ·
top right: tag feed · centre: crosshair, hit marker, popups, banners · bottom left: tag meter ("DANGER!" at 70%) ·
bottom right: blaster name, ammo (`mag | reserve`, `BELT n`, or `INF`), hints (REFILLING!, RELOADING..., LOW AMMO,
OUT OF DARTS - FIND A BUCKET!), and the Chainstorm spin bar · under the clock: announcer call-outs · hold Tab: scoreboard ·
bottom centre (any screen): device notices such as "controller connected".

**Screens:** main menu (live orbiting arena, both modes, bot count 2–5, bot skill, Chainstorm rule, YOUR PLAYER, settings,
quit, and how to play that switches between keyboard and controller) → match → pause (resume, restart, settings, main menu) →
podium and results (play again, main menu). Every menu works with keyboard, controller (A/B) or mouse.

## 9. Accessibility and comfort
- **Camera shake** 0–1.5; **0 turns it off entirely**.
- **Visual effects** 0.2–1.5: scales particle counts, the effects budget, muzzle-flash size and the hit tint.
- **No strobing.** The hit tint is soft and short, and there are no full-screen flashes.
- **Field of view** 60–110 (85 default) for players who feel motion-sick.
- **Mouse sensitivity**, **controller look speed** and **invert look**.
- **Controller aim assist** and **rumble**, both switchable; the main menu's help shows controller buttons when a pad is in use.
- **Separate music and sound-effect volumes**.
- **Pause anywhere** in a match. Losing focus pauses automatically.
- **Generous design:** bigger bot hitboxes, weaker bot darts, spawn protection, meter regen, auto-reload.
- **Readable signs:** world signs only show from the front, so nothing reads mirrored.
- **Planned:** remappable keys and buttons, a colour-blind-safe team palette option, subtitles or icons for important sounds.

## 10. Progression, Levels, Missions & Coin Shop (v0.5.3)
Built directly to the young players' wishlist (§1.9, D-028, D-036). A fair, joyous, kid-safe reward system:
- **`Progression` Autoload Singleton:** manages lifetime XP, player levels, coins, unlocks, and active missions. Saved locally to `user://progression.cfg`.
- **Level Curve:** Starts at Level 1 (`0 XP`). Each level $N \to N+1$ requires $100 \times N$ XP (Level 1 requires 100 XP, Level 2 requires 200 XP, etc.). Cumulative XP for level $N$: $50 \times N \times (N - 1)$.
- **Player Card in Lobby:** Prominently displays bunker title, player name, gold Level badge (`⭐ LVL [N]`), XP progress bar (`[====   ] 120 / 200 XP`), and live Coin counter (`🪙 350`).
- **Backyard Missions:** 3 active kid-safe objectives dynamically selected and replenished from the mission pool (ricochet tags off mirrors, lightning chain zaps, extinguishing fire with water, sliding on ice slicks, absorbing damage with Foam Shield, tagging zombies, Pocket Popper tags). Completing a mission awards +200 XP, +100 Coins, and celebratory audio.
- **Kid-Safe Coin Shop:** Strictly one currency (Coins). Earned strictly by playing and finishing missions. Zero real money, zero gems, zero microtransactions, zero timers, and zero paid power. Cosmetic items only: hats (Party, Cowboy, Propeller, Goggles, Bunny Ears, Horns, Spiky Hair, Champion Crown) and custom colour swatches (Bubblegum Pink, Golden Yellow, Tangerine Orange, Electric Teal).
- **Match Rewards Payout:** At match conclusion, awards XP and Coins (+25 XP/+5 Coins per tag, +100/+25 for match completion, +150/+50 for victory) with a celebratory rewards summary banner on the podium results panel.

### 10.2 Anti-Slop Blaster Skin Generative Pipeline *(v0.7.0)*
To elevate blasters beyond plain flat toy plastics while avoiding the muddy, inconsistent look of unconstrained diffusion art ("AI slop"), DARTSTORM uses a strictly guided procedural & generative shader pipeline:
- **Design Principles (Anti-Slop Standard):**
  - **Flat 2D Vector Patterns Only:** AI / generative scripts produce pure unlit black-and-white 2D geometric/stylized graphic patterns (1024x1024 seamless).
  - **Zero Baked Fake Lighting:** Never bake shadows, directional highlights, photorealistic dirt, or simulated ambient occlusion into textures. Godot's Forward+ PBR engine handles all lighting, normal reflection, and Fresnel rim lighting in real time.
  - **Sharp Object-Space Tri-Planar Shader (`blaster_skin.gdshader`):** High-power projection ($P^{12}$) eliminates UV distortion and seam stretching across CSG geometric weapon bodies.
  - **Color Dual-Tone Modulation:** The pattern modulates dynamically between weapon body and accent colors, preserving toy branding.
  - **Safety Tip & Grip Zoning:** Toy safety orange tips (`Color(1.0, 0.45, 0.05)`) and dark tactical rubber grips (`Color(0.13, 0.16, 0.24)`) are strictly preserved and never overwritten by patterns.
  - **4 Tactile Finish Modes:**
    - `MATTE`: Smooth molded toy plastic (Roughness 0.55).
    - `GLOSS`: High-shine reflective coat with clearcoat shine (Roughness 0.18, Clearcoat 0.8).
    - `METALLIC_FLAKE`: Sparkly metal-flake finish with micro-sparkle shimmer (Metallic 0.75, Roughness 0.32).
    - `HOLOGRAPHIC_IRIDESCENT`: Prismatic rainbow rim effect shifting with viewing angle (Fresnel 1.0, pulse glow).
- **8 Distinct Skins Catalog:**
  1. `Default Orange`: Classic factory blaster style (Matte).
  2. `Nitro Neon`: High-octane diagonal racing chevrons (Gloss).
  3. `Cyber Circuit`: Glowing microchip PCB traces (Gloss).
  4. `Hazard Stripe`: Industrial warning caution stripes (Matte).
  5. `Cosmic Galaxy`: Interstellar starfield and constellations (Metallic Flake).
  6. `Dino Scales`: Playful prehistoric reptile scale plating (Matte).
  7. `Holo Prismatic`: Iridescent rainbow holographic foil (Holographic).
  8. `Toxic Slime`: Biohazard radioactive drip splatter (Gloss).
- **Shop Integration:** Available in the Shop under the `SKINS` tab for earned Coins (100–350 Coins). Instantly equip and view on both 3D lobby weapons and third-person character models.


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
| **Call-out** | A big announcer message under the clock ("DOUBLE TAG!") |
| **Power-up mode** | The optional rule where the Chainstorm lands on the map instead of being in everyone's hands |
| **Aim assist** | Controller-only: turning slows while your crosshair is over a rival |
| **Bucket** | An ammo refill station that drains and regenerates |
| **Duo** | A pair: you and a bot buddy (DUOS mode) |
| **Team chip** | A team's name and score under the clock in team modes |
| **Bunker / lobby** | The main menu island where your squad stands (the players' design) |
| **Home Turf** | The house arena: a fictional family home at toy size (§5.3) |
| **Roam point** | A spot bots like to wander to |
