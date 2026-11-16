# DARTSTORM — Tuning Guide (no coding needed)

Almost every number in DARTSTORM lives in a small data file (`.tres`) that you can edit in the Godot editor's
**Inspector**, with no code involved. This guide is for anyone who wants to make the bots easier, the
Chainstorm sillier, or add a new blaster.

## How to edit a data file
1. Open the project in Godot (`./tools/run.sh editor`, or Godot → Import → `project.godot`).
2. In the **FileSystem** panel (bottom left), go to the `resources/` folder and **double-click** a `.tres` file.
3. Change values in the **Inspector** panel (right). Hover over a field to see its description.
4. Press **Ctrl+S** to save, then **F5** to play and try it.
5. Optional but recommended: run `./tools/validate.sh` to make sure nothing broke.
6. Changed your mind? Use `git checkout -- resources/` to undo every data change, or `git diff` to see what changed.

| Folder | What's in it | Type |
|---|---|---|
| `resources/weapons/` | One file per blaster | WeaponData |
| `resources/darts/` | One file per dart type (a blaster points at a dart) | DartData |
| `resources/bots/` | `easy`, `normal`, `hard` | BotDifficulty |
| `resources/modes/` | `free_for_all`, `gun_game` | GameMode / GunGameMode |

> Some things are set in code rather than data: player movement (`scripts/combat/actor.gd` exports and
> `scripts/player/player.gd`), bucket capacity per spot (`scripts/arena/backyard_fortress.gd`), and arena layout.

## WeaponData (blasters)
| Field | Meaning | Typical / safe range |
|---|---|---|
| `display_name`, `description` | Shown in the HUD, popups and tag feed | — |
| `dart` | Which DartData it fires (drag a `.tres` from `resources/darts/` onto it) | — |
| `fire_mode` | SEMI (one per click), AUTO (hold), SPIN_UP (wind up, then auto) | — |
| `shots_per_second` | Fire rate | 1–30 (above 30 the effects budget limits impact puffs) |
| `darts_per_shot` | Darts per trigger pull (shotgun-style) | 1–8 |
| `spread_degrees` | Random cone. 0 is laser-straight | 0–8 |
| `spin_up_time` / `spin_down_time` | SPIN_UP only: seconds to reach full speed / to stop | 0.3–1.5 |
| `firing_move_multiplier` | Speed while firing (spin-up: while spun) | 0.3–1.0 |
| `magazine_size` | Darts per magazine. **0 = belt-fed** (fires from the reserve, never reloads) | 0–60 |
| `reserve_max` / `reserve_start` | Spare darts carried: most you can hold / what you spawn with | — |
| `reload_time` | Seconds | 0.5–2.5 |
| `recoil_kick`, `camera_shake` | View kick and shake per shot (the player's shake setting still applies) | 0–2.5 / 0–0.35 |
| `sound`, `sound_pitch` | Launch sound ID (`pop`, `spray`, `chain`, `thump`, `zip`) and pitch | pitch 0.6–1.6 |
| `model_style` | Shape: PISTOL, SPRAYER, ROTARY, DOUBLE, HAMMER, RIFLE | — |
| `body_color`, `accent_color` | Colours of the procedural model | Bright! |
| `view_offset` | Where it sits on screen in first person (x right, y up, z forward is negative) | — |
| `ai_min_range` / `ai_max_range` / `ai_preference` | How bots choose it: preferred range in metres, and how much they like it | pref 0.5–2 |

## DartData (darts)
| Field | Meaning | Typical / safe range |
|---|---|---|
| `initial_speed` | Launch speed, m/s | 30–80 |
| `gravity_multiplier` | 1 = real gravity; lower is a flatter arc | 0.3–1.0 |
| `wind_response` | How much wind pushes it. 0 ignores wind | 0–2 |
| `air_drag` | Speed lost per second | 0.05–1.0 |
| `max_lifetime` | Seconds before it vanishes mid-air | 2–6 |
| `tag_power` | How much of a tag meter (100) one hit fills | 8–70 (100 = one-hit tag; avoid) |
| `max_ricochets` | Bounces allowed off mirrors | 0–4 |
| `ricochet_speed_keep` | Speed kept per bounce | 0.6–0.95 |
| `ricochet_any_surface` | Bounce off *everything*, not just mirrors | on/off |
| `visual_scale` | Size of the dart | 0.7–1.5 |
| `element` | Reserved for elemental darts (no effect yet) | NONE |

After changing a dart, regenerate the GDD's flight table:
`godot --headless --path . -s res://tools/dart_table.gd`

## BotDifficulty (bot skill)
| Field | Meaning | Easy → Hard |
|---|---|---|
| `aim_error_degrees` | Sloppiness added to every shot | 9 → 3 |
| `turn_speed_degrees` | How fast they can swing round | 140 → 340 |
| `lead_factor` | 0 never leads a moving target, 1 leads perfectly | 0.2 → 0.95 |
| `reaction_time` | Seconds they must see you before firing | 1.0 → 0.3 |
| `vision_range` / `fov_degrees` | How far they see / how wide (360 = eyes in the back of their head) | 30/130 → 50/360 |
| `semi_interval` | Seconds between clicks with semi-auto blasters | 0.8 → 0.3 |
| `burst_time` / `burst_pause` | Trigger-hold and rest with automatic blasters | — |
| `damage_scale` | Multiplies their darts' tag power **against you** | 0.4 → 1.0 |
| `move_speed_scale` | Movement speed | 0.75 → 1.0 |

## GameMode / GunGameMode
| Field | Meaning |
|---|---|
| `short_name` | The word on the lobby's mode card (SOLO, DUOS, TEAMS, GUN GAME) |
| `teams` | SOLO (everyone alone), DUOS (pairs) or BLUE_VS_ORANGE (two teams). Team modes add one bot when needed to even the teams |
| `duration_seconds` | Round length (300 = 5:00) |
| `countdown_seconds` | 3-2-1 length |
| `respawn_delay` | Seconds out after being tagged |
| `points_per_tag`, `ricochet_bonus`, `points_per_target` | Scoring |
| `loadout` | SOLO/DUOS/TEAMS: the blasters everyone carries, in key order 1, 2, 3 … |
| `infinite_reserve` | Bottomless ammo (Gun Game uses this) |
| `ladder` (Gun Game) | The blaster sequence; the last one wins |
| `tags_per_tier` (Gun Game) | Tags needed per rung (1 = every tag promotes) |
| `power_weapon` | The blaster that becomes the map power-up when the menu's CHAINSTORM option is POWER-UP |
| `power_weapon_first_delay` / `power_weapon_respawn` | Seconds of play before it first lands (20) / before it returns after each grab (45) |
| `power_weapon_belt` | Darts on its belt when grabbed (300) |

## Other things that are easy to change (tiny code edits)
These live in short lists at the top of a script. Change the values and keep the format.
| What | Where |
|---|---|
| Player colours, hats and RANDOM names | `scripts/core/cosmetics.gd` (`COLORS`, `HATS`, `RANDOM_NAMES`). A new hat also needs a shape in `CharacterModel._build_hat()` |
| Bot names, colours and hats | `BOT_ROSTER` in `scripts/core/match.gd` |
| Award names and minimums | `RULES` in `scripts/core/awards.gd` |
| Announcer words and timing | `MULTI_TAG_TEXT`, `STREAK_TEXT`, `MULTI_TAG_WINDOW` in `scripts/core/match_controller.gd` |
| Music tempo, chords and tunes | `_match_style()` / `_menu_style()` in `scripts/core/sfx.gd` (notes are MIDI numbers: 60 = middle C) |

## Recipes

**Make the bots easier for a younger player.** Open `resources/bots/easy.tres` and raise `aim_error_degrees` to
12, `reaction_time` to 1.4, and lower `damage_scale` to 0.3. Then pick **EASY** on the menu.

**Make the Chainstorm last longer between buckets.** In `flaxs_chainstorm.tres`, raise `reserve_max` (e.g. 600)
and `reserve_start` (e.g. 300), or lower `shots_per_second` (25 is still ridiculous).

**Make the Chainstorm even MORE ridiculous.** `shots_per_second` 30 → 40 and `darts_per_shot` 1 → 2. Expect chaos.
The dart pool (400) and effects budget keep it safe.

**Make tags take fewer hits.** Raise `tag_power` on the darts (e.g. `standard_dart.tres` 34 → 50 makes the Popper a two-hit tag).

**Make the Chainstorm power-up come back sooner.** `free_for_all.tres` → `power_weapon_respawn` 45 → 25.

**Shorter rounds for bedtime.** `resources/modes/free_for_all.tres` → `duration_seconds` 180.

**Add a new blaster (e.g. "Bubble Blaster").**
1. In `resources/weapons/`, right-click `pocket_popper.tres` → **Duplicate** → name it `bubble_blaster.tres`.
2. Change `id` (e.g. `bubble_blaster`), `display_name`, colours, `model_style`, and the numbers.
3. Optional: duplicate a dart in `resources/darts/` for its own dart and set `dart` to it.
4. Add it to a mode: open `free_for_all.tres` → `loadout` → **Add Element** → drag the new file in.
   (Keys 1–3 select the first three; the mouse wheel / Q / E reach the rest.)
5. Run `./tools/validate.sh`. The resource test checks every blaster has a dart and a real sound.

**Add a blaster to the Gun Game ladder.** Open `gun_game.tres` → `ladder` → Add Element → drag the blaster in →
move it to the right rung. Keep the Chainstorm last; it's the winning rung.

**Make a new bot skill (e.g. "Super Easy").** Duplicate `easy.tres` and tune it. To show it on the menu, a
programmer needs to add its path to `DIFFICULTY_PATHS` in `scripts/core/match.gd` and its name to
`DIFFICULTY_NAMES` in `scripts/ui/main_menu.gd`.
