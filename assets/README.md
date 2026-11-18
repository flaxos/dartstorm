# Assets and licences

Everything in DARTSTORM is **original and generated in code**, except one font:

| What | Where it comes from |
|---|---|
| 3D models (blasters, kids, arena, props) | Built from Godot primitive meshes in `scripts/effects/blaster_model.gd`, `scripts/effects/character_model.gd`, `scripts/arena/*.gd` |
| Materials & Shaders | Flat colours (`ArenaKit.mat`), procedural lawn shader (`assets/materials/lawn.gdshader`), holographic forcefield shader (`assets/materials/foam_shield.gdshader`), and anti-slop PBR tri-planar skin shader (`assets/materials/blaster_skin.gdshader`) |
| Blaster Skin Textures | 8 seamless 1024x1024 2D vector patterns in `assets/textures/skins/`, procedurally generated via `tools/generate_skins.py` |
| Sound effects | Synthesised at startup in `scripts/core/sfx.gd` (sine/square/saw tones and noise) |
| Font | **Lilita One**, **SIL Open Font License 1.1**, from the Google Fonts repository (github.com/google/fonts, `ofl/lilitaone`). Used unmodified. The designer's copyright notice and the licence are in `assets/fonts/OFL.txt` (the licence requires them to travel with the font). Fallback: Godot's built-in font |
| Music | Generated in code: two chiptune loops in `scripts/core/sfx.gd` |
| Icon | `icon.svg`, original |

DARTSTORM branding is original. There are no Nerf (or other trademarked) names, logos or product designs.

## Adding external assets

If you add any third-party file, put it under `assets/<type>/` and add a row here with:
**file, author, source URL, licence** (CC0 / CC-BY / etc.), plus any attribution the licence requires.
Never add assets with unclear or "non-commercial only" licences.
