# DARTSTORM: Elemental Arena — Game Design Document

*Living document: the authoritative description of how the game plays. Numbers here mirror the
`.tres` files in `resources/`; if they disagree, the `.tres` file is what the game uses, so update this doc.*

## 1. Vision

A colourful, chaotic, first-person foam-dart shooter inspired by backyard blaster battles, classic
arena shooters and creative elemental environments. **Easy to play, hard to master, enormously fun to
experiment with.** Playful, energetic, slightly ridiculous. Made by Sam for his kids.

**Hard rules:** cartoon tagging only (no gore, injuries or realistic firearms). Fire and lightning are
playful effects, never burns or electrocution. Original DARTSTORM branding. No microtransactions,
loot boxes or paid advantages.

## 2. Core loop

Spawn → grab a blaster → find someone → land darts (watch the drop and the wind) → tag them out →
run low → refill at a bucket → repeat. Five-minute rounds, quick respawns, a big end-of-round scoreboard.

## 3. Player

| Stat | Value |
|---|---|
| Walk / sprint speed | 7.0 / 10.5 m/s (sprint only while moving forward; slight FOV boost) |
| Jump | 7.6 m/s; coyote time 0.12 s and a 0.12 s jump buffer |
| Acceleration | 60 on the ground, 18 in the air (smooth but responsive) |
| Tag meter | 0–100. Darts fill it, and at 100 you're **tagged out** |
| Meter regen | After 4 s without being hit, drains at 15/s |
| Respawn | 3 s (Gun Game: 2 s), at the spawn point furthest from other players (random pick of the best 3) |
| Spawn protection | 1.5 s |
| Hitbox | The player's dart hitbox is a little smaller than the bots' (radius 0.45 vs 0.6). That's deliberate and keeps it kid-friendly. |

## 4. Darts (`resources/darts/`)

Darts are **real projectiles, never hit-scan**. Every tick:
`velocity += (gravity × gravity_multiplier + wind × wind_response) × dt`, then air drag, then a swept
ray from the old to the new position, so fast darts can't tunnel through walls.

| Dart | Speed | Gravity × | Drag | Tag power | Ricochets | Notes |
|---|---|---|---|---|---|---|
| Foam Dart | 44 | 0.7 | 0.25 | 34 (3 hits) | 1 | Pocket Popper, Double Trouble |
| Mini Dart | 40 | 0.75 | 0.3 | 13 (8 hits) | 1 | Dart Sprayer |
| Belt Dart | 48 | 0.65 | 0.25 | 10 (10 hits) | 1 | Chainstorm |
| Foam Slug | 36 | 0.9 | 0.9 | 15 ×8 pellets | 1 | Foam Hammer: heavy drag, so it only works up close |
| Bouncy Dart | 40 | 0.5 | 0.15 | 34 | 4, any surface | Ricochet Ranger |
| Mega Dart | 78 | 0.35 | 0.1 | 70 (2 hits) | 1 | Longshot |

- **Ricochet:** reflective surfaces (and any surface for bouncy darts) reflect the velocity about the
  hit normal, keep 80% of the speed (90% for bouncy), and ignore that surface for 0.08 s.
  A tag from a dart that has ricocheted earns **+50 RICOCHET BONUS**.
- **Spent darts:** a dart that hits ordinary scenery stops being dangerous, bounces, tumbles,
  lies on the ground for about 1.4 s and then shrinks away.
- Friendly darts pass through team-mates (in free-for-all everyone is their own team).
- Bot darts are scaled by difficulty (Easy ×0.4, Normal ×0.6, Hard ×1.0).

## 5. Blasters (`resources/weapons/`)

| Blaster | Mode | Rate | Mag / reserve | Reload | Spread | Personality |
|---|---|---|---|---|---|---|
| **Pocket Popper** | Semi | 5/s | 8 / 48 (start 32) | 0.8 s | 0.4° | Accurate, easy, reliable |
| **Dart Sprayer** | Auto | 10/s | 30 / 150 (start 90) | 1.5 s | 2.6° | Hose it around |
| **FLAX'S CHAINSTORM** | Spin-up | **30/s** | belt-fed: 400 max (start 160) | none | 4.2° | See below |
| Double Trouble | Semi | 3.2/s ×2 darts | 8 / 48 | 1.0 s | 1.6° | Gun Game rung 2 |
| Foam Hammer | Semi | 1.5/s ×8 slugs | 4 / 28 | 1.6 s | 6.5° | Gun Game rung 4 |
| Ricochet Ranger | Semi | 3/s | 6 / 36 | 1.2 s | 0.5° | Bounces off everything |
| Longshot | Semi | 1.1/s | 4 / 24 | 1.8 s | 0.1° | Fast, flat, two-hit tags |

### FLAX'S CHAINSTORM: the star of the show

- Oversized six-barrel rotary foam cannon with a carry handle, a nameplate and a **visible dart belt**
  that cycles with every shot. Bots carry it with an orange **ammo backpack**.
- **Spin-up** of 0.7 s before the first dart, shown by a lime spin bar on the HUD, a rising motor whine
  and barrels you can see spinning. It spins down over 0.9 s.
- Then **30 darts per second**, a constant rattle, camera buzz and muzzle puffs.
- **Movement penalty:** speed drops to 45% while spun up.
- **Belt-fed:** it fires straight from a 400-dart reserve, so it never reloads, but a full bucket
  (150) lasts about 5 seconds of trigger time. **Controlling the buckets is the strategy.**

Every rate, spread, model and sound comes from data. Adding a blaster means writing a `.tres`
(see ARCHITECTURE.md §4).

## 6. Modes (`resources/modes/`)

### Backyard Battle (free-for-all), the default
- 5:00 round after a 3-2-1-GO countdown. Everyone is their own team.
- Loadout: Pocket Popper, Dart Sprayer and Flax's Chainstorm (keys 1/2/3).
- Scoring: tag **+100**, ricochet bonus **+50**, bullseye target **+10**.
- Ranking: score, then tags, then fewest outs. The end screen shows the winner, a full table,
  and **Play Again** / **Main Menu** buttons.

### Gun Game
- Everyone starts on rung 1 with **bottomless ammo**. Each tag moves you up one rung.
- Current ladder (7 of the 10 planned rungs): Pocket Popper → Double Trouble → Dart Sprayer →
  Foam Hammer → Ricochet Ranger → Longshot → **Flax's Chainstorm**.
- **Tag someone while holding the Chainstorm to win instantly.** If the clock runs out,
  the highest rung wins.
- Planned rungs not built yet: *Wind Whisperer* (between Ricochet Ranger and Longshot),
  *Thunder Cannon* and *Rocket Dart* (before the Chainstorm). They need elemental dart effects.
  To add one, write its `.tres` and drop it into the `ladder` array in `gun_game.tres`.

## 7. Arenas

### Backyard Fortress (playable)
A 68 × 48 m fenced backyard, built for combat and movement first:

```
 N   [mirror]   ~ hedge ~   [mirror]          MIRROR ALLEY (bucket)
     crate stacks       slide             crate stacks
 BLUE ==walkway==>  TREEHOUSE  <==walkway== ORANGE
 FORT   barriers     (deck 4.6 m,  barriers  FORT
 (2.6m)  trampoline    bucket under) trampoline (2.6m)
     ramp                 ramp
 S  ~~~~~~~~ WINDY WAY: giant fan, wind blows north ~~~~~~~~ (bucket)
```

- **Elevations:** ground → forts (2.6 m, two ramps each, battlements and a roofed back half) →
  sloped walkways → treehouse deck (4.6 m, railings, reachable four ways plus two trampolines).
- **Landmarks:** a giant leafy treehouse canopy, huge team flags, BLUE FORT / ORANGE FORT signs,
  a yellow slide, the spinning fan, glowing cyan mirror frames, and houses beyond the fence.
- **Mirror Alley:** two angled reflective panels on the north fence let you bank shots around the hedge.
- **Windy Way:** a 24 × 12 m wind zone (40 m/s² northward) with streaks, drifting arrows, a windsock
  and a giant fan. Darts visibly curve, and the HUD wind compass shows strength and direction.
- **Ammo buckets (5):** blue fort, orange fort, under the treehouse, Mirror Alley, Windy Way.
  Each holds 150 darts, transfers 90/s, and refills 14 s after being emptied.
- **Bullseyes (6):** on the fences and the treehouse trunk.

### Future elemental arenas (designed, not built)
| Arena | Signature mechanic | Systems it reuses or needs |
|---|---|---|
| **Tempest Treehouse** | Wind tunnels, gusts, vertical climbs, long curved shots | WindZone `gust_amount`, WindField `global_wind`, JumpPad |
| **Ember Workshop** | Glowing vents, moving platforms, temporary flame barriers (playful, never burns) | Needs: AnimatableBody3D platforms, toggling barrier walls, `DartData.element = FIRE` visuals |
| **Thunder Playground** | Storms, electrical relays, energy boosts, machinery | Needs: timed relay triggers, speed-boost pads, LIGHTNING darts |
| **Prism Palace** | Mirror walls, glass platforms, creative ricochets | ReflectiveSurface (already done), many-bounce darts |
| **Frost Factory** | Ice slides, slippery floors, frozen darts, moving obstacles | Needs: per-surface friction in `Actor.move_actor`, ICE darts |

## 8. Bots

Three moods: **Roam** (wander between interesting spots on the navmesh), **Fight** (keep the
blaster's ideal range, strafe, shoot), **Resupply** (head to the nearest stocked bucket when under 15 darts).
They lead moving targets and aim high for dart drop, but **ignore wind**, which clever players can exploit.
When hit, they flinch, dodge and hunt the attacker for 4 s. They pick the blaster that suits the range.
There's anti-stuck hopping and re-pathing.

| Difficulty | Aim error | Reaction | Turn speed | Vision | Dart power | Speed |
|---|---|---|---|---|---|---|
| Easy | 9° | 1.0 s | 140°/s | 30 m, 130° cone | ×0.4 | ×0.75 |
| Normal | 5.5° | 0.6 s | 220°/s | 40 m, 200° cone | ×0.6 | ×0.9 |
| Hard | 3° | 0.3 s | 340°/s | 50 m, 360° | ×1.0 | ×1.0 |

Bot names: Blaze, Pickle, Zoom, Sprinkles, Noodle.

## 9. Game feel

Muzzle puffs, procedural launch sounds per blaster, gentle trauma-based camera shake, view-model recoil,
bob and sway, coloured dart trails, foam-chunk impact particles, ricochet ripples, hit markers (orange
and bigger on a tag), arcade popups (+100 TAG!, +50 RICOCHET BONUS!, NEW BLASTER: …), tag jingles,
and confetti bursts when someone is tagged out. A soft orange edge flash when you're hit (never a strobe).
**Camera shake** and **visual effects intensity** are both in Settings, and 0 shake disables it entirely.

## 10. UI

Deep-blue rounded panels with hot-orange highlights and a chunky emboldened font.
HUD: crosshair and hit marker, score/tags/place (plus the Gun Game rung), wind compass, match clock and mode,
tag feed, tag meter, blaster name with ammo (magazine | reserve, or BELT n), reload/low-ammo/refill hints,
Chainstorm spin bar, centre banners (countdown, TAGGED!, respawn timer), and a hold-Tab scoreboard.
Screens: main menu (live orbiting arena backdrop, mode buttons, bot count, bot skill, how to play),
settings, pause menu (resume, restart, settings, main menu), end-of-round results.

## 11. Progression (planned, not built)

Weapon XP and mastery, magazine/accuracy/rate/speed upgrades, cosmetic skins, alternate and elemental
darts, barrel customisation. Upgrades should modify a duplicated WeaponData at runtime, never the shared
`.tres`. Not to be started until the core combat has been playtested and is fun. No paid advantages, ever.
