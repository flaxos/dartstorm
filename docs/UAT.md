# DARTSTORM — User Acceptance Testing

UAT is the **hands-on check by real players** that a build is fun, works, and meets the
brief's definition of success. Automated checks (`./tools/validate.sh`) prove the code works.
UAT proves the *game* works. A release isn't done until both pass.

## How to run a UAT session
1. Get the build: `git pull`, then open the project in Godot 4.4+ (Import → `project.godot`) and press **F5**,
   or run `./tools/run.sh`.
2. Work through the script below. Tick each line, and note anything odd in the results log at the bottom.
3. Then play for fun. The most useful feedback is "that was boring", "that was too hard", or "do that again!".
4. Record the result (PASSED / PASSED WITH NOTES / FAILED) in the log, with the date and tester.

## Test script

### A. Launch and menus
| ID | Do this | Expect |
|---|---|---|
| A1 | Launch the game | Main menu: big orange DARTSTORM title over the slowly turning backyard. No error pop-ups |
| A2 | Change **BOTS** (−/+) and **BOT SKILL** | Values change (2–5 bots; Easy/Normal/Hard) and are remembered next launch |
| A3 | **SETTINGS** → move every slider, toggle fullscreen | Each changes immediately (volume, fullscreen…) |
| A4 | SETTINGS → **RESET TO DEFAULTS** → DONE *(v0.1.1)* | Everything returns to factory values: FOV 85, shake 1.00, volume 0.80, windowed, look not inverted |

### B. Backyard Battle (the brief's definition of success)
| ID | Do this | Expect |
|---|---|---|
| B1 | **PLAY: BACKYARD BATTLE** | 3-2-1-GO countdown with beeps. You can look around but not move until GO |
| B2 | Run (WASD), sprint (Shift), jump (Space) | Smooth movement, sprint widens the view slightly, jumps clear crates |
| B3 | Fire the **Pocket Popper** (1) at a bot | Darts visibly fly and drop at range. Hits show a white marker. Three hits tag the bot: confetti, **+100 TAG!**, tag feed entry |
| B4 | **Dart Sprayer** (2): hold fire | Full-auto stream, magazine counts down, auto-reload when empty |
| B5 | **Flax's Chainstorm** (3): hold fire | Barrels spin up (sound plus spin bar) for ~0.7 s, then a storm of darts. You move slowly. The belt counter drops fast |
| B6 | Stand at an **AMMO** bucket | "REFILLING!", ammo climbs, the bucket count drops. Drain it: "EMPTY n" counts down, then it refills |
| B7 | Shoot across **Windy Way** (south, by the giant fan) | The wind compass shows the wind; darts curve visibly north |
| B8 | Bounce a dart off a **mirror** in Mirror Alley at a bot | White ripple on the mirror; a ricochet tag scores **+50 RICOCHET BONUS** |
| B9 | Hit a **bullseye** | It spins and dings, **+10**, then pops back |
| B10 | Use a **trampoline** | Bounces you onto the treehouse deck |
| B11 | Get tagged | "TAGGED! You were tagged by …", a respawn countdown, back in 3 s, briefly protected |
| B12 | Hold **Tab** | Live scoreboard |
| B13 | Esc → pause → resume / settings / restart | Each works. The game is frozen while paused |
| B14 | Alt-tab away mid-match, then click back in *(v0.1.1)* | The game is paused when you return, and the click does **not** fire a dart. Resume carries on |
| B15 | Let the clock run out | Orange clock and beeps in the last 10 s, then the results screen with a winner. **PLAY AGAIN** and **MAIN MENU** both work |

### C. Gun Game
| ID | Do this | Expect |
|---|---|---|
| C1 | **PLAY: GUN GAME** | Everyone starts with the Pocket Popper and bottomless ammo ("INF") |
| C2 | Tag a bot | "NEW BLASTER: DOUBLE TROUBLE" and a jingle; the HUD shows BLASTER 2 / 7 |
| C3 | Climb to the Chainstorm and tag someone | Instant win, results screen |

### D. Bots and difficulty
| ID | Do this | Expect |
|---|---|---|
| D1 | Easy, 2 bots | A young player can win |
| D2 | Hard, 5 bots | Chaotic and challenging, but bots don't get permanently stuck on scenery |
| D3 | Watch bots for a minute | They roam, fight, swap blasters, visit buckets and respawn after being tagged |

### F. Controller *(v0.2.0, needs a real pad)*
| ID | Do this | Expect |
|---|---|---|
| F1 | Plug a controller in at the main menu | A "… connected - ready to play!" notice; HOW TO PLAY switches to controller buttons |
| F2 | Use only the pad: D-pad/stick to move around the menu, A to press, B to go back (Settings, YOUR PLAYER) | Every button reachable; B leaves sub-screens |
| F3 | Play a match on the pad | Sticks move and look smoothly; small nudges aim finely; RT fires; A jumps; LT sprints; Y/LB/RB switch blasters; X reloads; Start pauses; Back shows the scoreboard |
| F4 | Aim across a bot | Turning slows slightly over the bot (aim assist), never yanks your aim |
| F5 | Fire, get hit, tag someone | Light rumble per shot, thump when hit, kick on a tag (turn rumble off in Settings and it stops) |
| F6 | Unplug the pad mid-match | The game pauses with a "Controller disconnected" notice; plug back in and resume |

### G. Appeal pack *(v0.2.0)*
| ID | Do this | Expect |
|---|---|---|
| G1 | Main menu → YOUR PLAYER: type a name, try RANDOM, pick a colour and every hat | A live 3D preview; the propeller spins; your choices are remembered next launch |
| G2 | Play a match | Your darts are your colour; your name is in the tag feed; no bot wears your colour |
| G3 | Listen | Menu tune on the menu, a faster tune in the match, quieter when paused; Music and Sound effects sliders work separately |
| G4 | Tag 2–3 bots quickly | "FIRST TAG!", "DOUBLE TAG!", "ON A ROLL!" call-outs under the clock |
| G5 | Shoot the dog house (orange half) | The dog jumps and barks. Spot the swings, paddling pool and duck, sprinkler, gnomes and flowers; hear birds |
| G6 | CHAINSTORM: POWER-UP, then play | No Chainstorm at the start; ~20 s in it lands on the treehouse in an orange beam with a call-out; grabbing it puts it in your hands; it's lost when you're tagged; it comes back later |
| G7 | Let the match end | The camera cuts to the sky podium: the top three dance in their hats under confetti; awards on the right; PLAY AGAIN / MAIN MENU work with mouse and pad |

### H. Linux build *(v0.2.0, on the players' PC)*
| ID | Do this | Expect |
|---|---|---|
| H1 | Copy `build/DARTSTORM-<version>-linux-x86_64.tar.gz` to the PC, extract it, double-click `DARTSTORM.x86_64` | The game opens without Godot installed (if nothing happens, use H2) |
| H2 | Run `install-shortcut.sh` in the DARTSTORM folder | DARTSTORM appears in the applications menu (and on the desktop) with the DARTSTORM icon, and launches from there |
| H3 | Change a setting, quit, relaunch | The setting is kept (saved in `~/.local/share/dartstorm/`) |

### I. The players' lobby and team modes *(v0.3.0)*
| ID | Do this | Expect |
|---|---|---|
| I1 | Launch the game and show the players the main menu | **Their own drawing:** you on a gold-ringed platform with the Chainstorm, bots on platforms around you with name tags, lightning bolts, "YOUR BUNKER" card top left with buttons under it, mode cards top right, logo bottom middle, big PLAY bottom right |
| I2 | CHARACTER: set a name, try the new hats (goggles, bunny ears, horns, spiky hair) | The camera zooms in on you, the others step away; DONE brings them back; the card now says "*NAME*'S BUNKER" |
| I3 | Pick TEAMS, set BOTS to 2, then 7 | The island shows blue team-mates next to you and orange rivals behind; the panel says "2 v 2 (+1 BOT TO EVEN THE TEAMS)", then "4 v 4" |
| I4 | Play TEAMS | Everyone on your team is blue (hats stay); your darts pass through team-mates; blue respawns at the Blue Fort end; team chips under the clock; "YOUR TEAM TAKES THE LEAD!"; scoreboard grouped by team |
| I5 | Finish a TEAMS round | "YOUR TEAM WINS!" (or ORANGE / DRAW); each team dances together on one podium step |
| I6 | Play DUOS with 4 bots | 3 pairs (blue, orange, green); you and your buddy share a colour and a score |
| I7 | Use only a controller in the lobby | Every card and button is reachable; A on PLAY starts; B leaves CHARACTER and HOW TO PLAY |

### J. Home Turf *(v0.4.0)*
| ID | Do this | Expect |
|---|---|---|
| J1 | Lobby → ARENA: HOME TURF → PLAY (SOLO) | A big toy-sized house with no roof, sunny rooms, floor labels (KITCHEN, LOUNGE, ...) |
| J2 | Explore | Chairs are steps onto tables; you can crawl under tables; beds bounce you; the kids' room trampoline gets you onto the loft bed; the big fan's wind bends darts in the kitchen |
| J3 | Run up the orange race-track ramp on the east lawn | You reach the patio roof; ball, frisbee and paper plane up there as cover |
| J4 | Ricochet off the bathroom and wardrobe mirrors | +50 ricochet bonus works indoors too |
| J5 | Play TEAMS on Home Turf | Blue starts at the front (driveway, garage), orange in the backyard; nobody starts on top of anyone |
| J6 | Watch bots for a minute | They go room to room, round the side paths, and up the ramp |

### K. Elemental Gameplay & Reactions *(v0.5.0)*
| ID | Do this | Expect |
|---|---|---|
| K1 | Fire **Wind Darts** at a bot | Notice subtle upward lift / buoyancy on hit; darts drift easily in wind |
| K2 | Fire **Fire Blaster** at a bot | Fire sparkle status ticks over 3s, displaying gentle non-violent flame sparks |
| K3 | Fire **Hydro Soaker** at a bot | High knockback shoves bot backward, applies `wet` status (4s) |
| K4 | Fire **Thunder Cannon** at a `wet` bot | Lightning conducts an instant chain zap shock (+50 combo bonus) |
| K5 | Shoot Fire dart at a `wet` target | Flash steam cloud erupts (+50 steam combo bonus) |
| K6 | Sprint and land from a jump | 2nd-order damped harmonic spring weapon inertia dips and cants smoothly |

### L. Zombies Mode *(v0.5.1)*
| ID | Do this | Expect |
|---|---|---|
| L1 | Lobby → Mode: **ZOMBIES** → PLAY | 1 player/bot chosen as green Alpha Zombie; survivors carry blasters |
| L2 | Play as Survivor | Tag incoming zombies (+100); survive until 180s clock expires to win |
| L3 | Get tagged by a zombie | Pop into foam confetti (+150 infection tag) and respawn on the Zombie horde team with green body and cartoon outstretched arms |
| L4 | Attack as Zombie | Sprint (11.2 m/s) and press Fire for cartoon claw swipes; touch survivors to turn them |
| L5 | Match Conclusion | Survivors win if any survive clock expiry; Zombies win early if all survivors are turned |

### M. Foam Shield & Environmental Hazards *(v0.5.2)*
| ID | Do this | Expect |
|---|---|---|
| M1 | Walk into a **Shield Pickup** bubble | Cyan holographic hexagonal forcefield wraps around your actor; HUD displays cyan shield gauge (50 HP) |
| M2 | Take dart damage while shielded | Shield absorbs tag power 1:1; pops with sparkling burst upon depletion |
| M3 | Walk into a **Water Puddle** | Foam droplet splashes and `wet` status applied for 4.0s |
| M4 | Shoot Water Puddle with Thunder Cannon | Conducts electricity across puddle surface for 2.0s with zapping arcs |
| M5 | Run onto an **Ice Slick** (ramp/slide) | Friction drops to zero and player gets instant +9.5 m/s slide boost |
| M6 | Step into an **Interactive Wind Vent** | Upward buoyant draft launches player into the air; infuses and amplifies elemental dart clouds |

### N. Progression, Levels, Missions & Coin Shop *(v0.5.3)*
| ID | Do this | Expect |
|---|---|---|
| N1 | Check Player Card in Lobby | Displays gold Level badge (`⭐ LVL [N]`), XP progress bar, and live Coin balance |
| N2 | Click **MISSIONS** button | 3 active kid-safe backyard missions displayed with progress bars |
| N3 | Complete a mission in a match | Celebratory fanfare, +200 XP, and +100 Coins awarded; replaced by new mission |
| N4 | Click **SHOP** button | Kid-safe cosmetic shop with Hats and Color Swatches. Unlocks persist across launches in `user://progression.cfg` |
| N5 | Finish any match | Podium results panel displays celebratory match rewards summary banner with earned XP and Coins |

### O. Tempest Treehouse Arena *(v0.6.0)*
| ID | Do this | Expect |
|---|---|---|
| O1 | Lobby → ARENA: **TEMPEST TREEHOUSE** → PLAY | High ancient tree canopy grove with dual fortified decks at $Y=5.4\text{ m}$ |
| O2 | Cross the Suspension Rope Bridge | Realistic catenary rope bridge spanning the 20m central chasm |
| O3 | Climb or Jump-Pad to Crow's Nest ($Y=10.5\text{ m}$) | North Tree high platform holding Foam Shield and Chainstorm pickup |
| O4 | Slide down the Canopy Escape Ice Slide | High-velocity slide-boost down the chute onto the suspension bridge |
| O5 | Cross-chasm gale wind | Strong 28 m/s wind tunnel sweeps darts across the upper chasm |

### P. Zombie Siege (Base Defense) & Blaster Skins *(v0.7.0)*
| ID | Do this | Expect |
|---|---|---|
| P1 | Lobby → Mode: **SIEGE** → PLAY | Yard centre holds the 1000 HP Base Core and 4 choke-point barricades (250 HP) |
| P2 | Defend against Wave 1 & 2 | Standard zombies and fast Runners swarm towards barricades and the core |
| P3 | Survive through Wave 3 & 4 | Armored Brutes (220 HP, 1.35x scale) charge defenses; barricades absorb hits |
| P4 | 20s Intermission phase | "FORTIFY & REPAIR!" countdown; all buckets refill; spend Scrap to repair core and rebuild barricades |
| P5 | Face Wave 5: Mega Foam Titan Boss | 3.5m Titan Boss (650 HP) with ground shockwaves; defeat boss to clear mode and unlock exclusive **Toxic Slime** skin |
| P6 | Lobby → SHOP → **SKINS** tab | Interactive 3D preview of 8 tactile skins with Matte, Gloss, Metallic Flake, and Holographic finishes; equip works in first-person and on lobby squad |

### Q. v1.0.0 Production Polish, Tactical Radar & All 9 Arenas *(v1.0.0)*
| ID | Do this | Expect |
|---|---|---|
| Q1 | Launch Main Menu, cycle all 9 arenas with `<` `>` | Live 3D arena backdrop swaps cleanly; `v1.0.0` badge visible bottom-left; zero tofu-box missing glyphs anywhere in menus, HUD, Shop, Missions, Workbench, or Multiplayer |
| Q2 | Play **Soccer Stadium**, **Two Fortresses**, **Dusty Courtyard**, and **Duststorm II** | Distinct AgX lighting per arena (floodlit twilight stadium!); open Two Fortresses moat & navigable basement vaults/water tunnels; open Dusty Courtyard arch & flush bridge; open Duststorm II Lower B Tunnel & Pit ramp |
| Q3 | Check top-right **Tactical Radar**, crosshair, and weapon strip in match | Rotating radar shows arena cover, FOV wedge, teammates, nearby/firing rivals, and objectives (Bomb Sites A/B, CTF flags, Base Core, ammo buckets); directional damage arcs flash toward attackers; hitmarkers distinguish body/shield/ricochet/tag-out |
| Q4 | Play **Capture the Flag** and **Plant the Bomb** | Explicit Site A/B rings and contextual `[F]` Plant/Defuse prompts work cleanly; dual fuse & defuse bars display during defusal; CTF pedestals stay anchored at home base |
| Q5 | Open **Garage Workbench** and equip barrel/optic/grip/stock attachments | Enclosed garage room with clean lighting, hollow glowing cyan Holo-Sight reticle, attachments stay locked to blaster during recoil, and Reset to Stock updates the 3D model immediately |
| Q6 | Play **2-Player Split-Screen** to match end (including Teams & Zombie Siege) | Both players join Defenders in Zombie Siege; Orange Team does NOT turn into zombies on the metallic spotlight podium; results & PLAY AGAIN remain visible at match end |

### R. Foam Bat Melee, ADS Iron Sights & Multi-Platform Release Packages *(v1.0.0)*
| ID | Do this | Expect |
|---|---|---|
| R1 | Play **Gun Game** through to rung 11, or grab the glowing **Foam Bat** pad in FFA/Teams/CTF, or press `5` in **Zombies / Zombie Siege** | Stylized orange-and-cobalt `"BONK!"` Foam Bat equips cleanly with zero floating attachments, +14% sprint speed, diagonal home-run swing animation, and `MELEE` / `BAT` HUD display |
| R2 | Swing the Foam Bat at a rival, a bullseye target, and an incoming enemy foam dart / grenade | Rival launches with cartoon knockback & breaks Foam Shield cleanly; bullseye spins & scores; incoming darts and grenades bat straight back with ricochet credit |
| R3 | Aim Down Sights (RMB / LT) with **Dart Sprayer** and other iron-sight blasters | Clean 3D flip-up iron sights align right on crosshair with zero camera clipping into the blaster body; reloading any blaster shows smooth HUD progress with zero console script errors |
| R4 | Extract and launch the **Windows (`DARTSTORM.exe`)**, **Linux (`DARTSTORM.x86_64`)**, **Android (`DARTSTORM-1.0.0-android.apk`)**, and **Web** release packages | Custom DARTSTORM cover-art boot splash and app icons display cleanly; each package launches into the 3D lobby and plays a full match smoothly |

### S. v2.0.0 Cover-Art Parity Visual, Character, Weapon & VFX Verification *(v2.0.0)*
| ID | Do this | Expect |
|---|---|---|
| S1 | Inspect heroes on the 3D Bunker Lobby island & Podium | Continuous smooth-skinned cartoon kids (zero floating leg gaps), folded hoodie cowls, chunky rounded sneakers, sculpted hair & ears, blinking Pixar eyes, expressive smiling/cheering mouths, sculpted hats, and warm-navy comic outlines (on High/Ultra) |
| S2 | Cycle all 12 weapons in first person (including **Flax's Chainstorm** & **Foam Bat**) | Chunky blow-molded beveled toy blasters held by player-colored hoodie sleeves & cartoon hands; animated curved Chainstorm foam-dart belt; smooth reload, pump, and two-handed bat swing animations; zero ADS iron-sight clipping |
| S3 | Fire every elemental blaster & deflect a dart/grenade with the Foam Bat | Five iconic mid-air flight trails (Wind blue swirls, Fire star-comets, Water turquoise splash arcs, Lightning yellow comic zig-zags, Ice crystal snowflakes); golden comic starburst + floating `"BONK!"`/`"DEFLECT!"` pop + crisp hit-stop (off when `camera_shake == 0`) |
| S4 | Tour Backyard Fortress & all 9 arenas (especially Mirror Alley & Windy Way) | Multi-cluster swaying tree canopies, beveled oak planks, shingled treehouse roof & rope ladder, waving cloth team flags, glowing beveled cyan mirrors with sheen streaks, curved flowing wind ribbons (no box edges), and zero navmesh/bot path regressions |
| S5 | Cycle Graphics Quality (`Ultra` → `High` → `Medium` → `Low`) & test 2P Split-Screen | Outlines and VFX scale cleanly with zero visual glitches or shader errors; split-screen hides the other player's FP hands properly and locks smooth frame rate |

### E. Comfort
| ID | Do this | Expect |
|---|---|---|
| E1 | Camera shake 0 | No shake at all, even with the Chainstorm |
| E2 | Visual effects 0.2 | Far fewer particles; still readable |
| E3 | Play 10 minutes | No dizziness complaints, no stutter or slowdown worth mentioning |

## Results log

| Version | Date | Tester | Result | Notes |
|---|---|---|---|---|
| 0.1.0 | 2026-11-15 | Project owner | ✅ **PASSED** | First playable (PR #1). UAT reported as passed with no blocking issues; no detailed notes recorded |
| 0.1.1 | — | — | ↪ Folded into 0.2.0 | Hardening release (merged). Its re-checks (A4, B13, B14, D2, D3) are part of the 0.2.0 run |
| 0.2.0 | — | — | ⏳ Pending | Controller support and appeal pack. Run everything, especially sections F (with a real pad) and G, and ask the players what they'd change |
| 0.3.0 | — | — | ⏳ Pending | Their lobby, team modes, Linux build: sections H and I. Can be run together with 0.2.0 |
| 0.4.0 | — | — | ⏳ Pending | Home Turf: section J. Can be run with the others |
| 0.5.0 | — | — | ⏳ Pending | Elemental Arena & Spring Dynamics: section K |
| 0.5.1 | — | — | ⏳ Pending | Zombies Mode: section L |
| 0.5.2 | — | — | ⏳ Pending | Foam Shield & Environmental Hazards: section M |
| 0.5.3 | — | — | ⏳ Pending | Progression, Levels, Missions & Coin Shop: section N |
| 0.6.0 | — | — | ⏳ Pending | Tempest Treehouse: section O |
| 0.7.0 | — | — | ⏳ Pending | Zombie Siege (Base Defense) & Blaster Skins: section P |
| 1.0.0 | — | — | ⏳ Pending | Production 1.0 release: sections Q & R plus controller/split-screen/Windows/Android/Linux/online check |
