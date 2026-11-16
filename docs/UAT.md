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
