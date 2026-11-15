# Assets and licences

Everything in DARTSTORM is currently **original and generated in code**:

| What | Where it comes from |
|---|---|
| 3D models (blasters, kids, arena, props) | Built from Godot primitive meshes in `scripts/effects/blaster_model.gd`, `scripts/effects/character_model.gd`, `scripts/arena/*.gd` |
| Materials | Flat colours (`ArenaKit.mat`) and one original shader (`assets/materials/lawn.gdshader`) |
| Sound effects | Synthesised at startup in `scripts/core/sfx.gd` (sine/square/saw tones and noise) |
| Font | Godot's built-in default font (part of the engine, MIT-licensed), emboldened in `UiKit.font()` |
| Icon | `icon.svg`, original |

DARTSTORM branding is original. There are no Nerf (or other trademarked) names, logos or product designs.

## Adding external assets

If you add any third-party file, put it under `assets/<type>/` and add a row here with:
**file, author, source URL, licence** (CC0 / CC-BY / etc.), plus any attribution the licence requires.
Never add assets with unclear or "non-commercial only" licences.
