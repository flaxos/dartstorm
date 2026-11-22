# DARTSTORM 3D Model Asset Pipeline Specification

This directory contains 3D models (`.glb` / glTF 2.0 binary format) for characters, weapons, props, and cosmetics in DARTSTORM.

## Conventions

- **Units**: 1 Godot unit = 1 meter.
- **Coordinate System**: Godot 3D convention:
  - `+Y` is Up.
  - `-Z` is Forward (direction character or blaster faces).
  - `+X` is Right.
- **Format**: `.glb` (glTF 2.0 Binary) is the preferred format for single-file self-contained geometry, embedded/referenced textures, and skeletal animations.

---

## Directory Layout

```
assets/models/
├── characters/        # Hero base meshes and rigs
│   ├── hero_base.glb  # Base stylized character mesh & Skeleton3D
│   └── animations/    # Standalone animation libraries (.glb / .res)
├── blasters/          # 6 weapon classes
│   ├── popper.glb     # Pistol
│   ├── sprayer.glb    # SMG
│   ├── six_shot.glb   # Heavy Revolver
│   ├── hammer.glb     # Pump-Action Shotgun
│   ├── chainstorm.glb # Rotary Minigun
│   └── outrider.glb   # Precision Sniper
├── props/             # Arena environment assets
│   ├── slide.glb      # Playground spiral slide
│   ├── gym.glb        # Jungle gym / climbing dome
│   ├── tree_clump.glb # Stylized cartoon foliage tree
│   └── ...
└── hats/              # Head cosmetics
    ├── cap.glb
    ├── beanie.glb
    ├── cowboy.glb
    └── ...
```

---

## Rigging & Bone Naming Standard (Characters)

Characters use a standard 24-bone humanoid hierarchy for compatibility with Godot `Skeleton3D` and retargeting:

```
Root
└── Hips
    ├── Spine
    │   └── Chest
    │       ├── Neck
    │       │   └── Head
    │       ├── Shoulder_L -> UpperArm_L -> LowerArm_L -> Hand_L
    │       └── Shoulder_R -> UpperArm_R -> LowerArm_R -> Hand_R
    ├── UpperLeg_L -> LowerLeg_L -> Foot_L -> Toe_L
    └── UpperLeg_R -> LowerLeg_R -> Foot_R -> Toe_R
```

### Standard Attachment Sockets:
- `Socket_Hand_R`: Attached to `Hand_R` bone for holding weapons.
- `Socket_Hand_L`: Attached to `Hand_L` bone for two-handed weapon foregrips.
- `Socket_Head`: Attached to `Head` bone (offset `+Y 0.2m`) for hats, helmets, and goggles.
- `Socket_Back`: Attached to `Chest` bone (offset `+Z 0.15m`) for ammo backpacks, quivers, and tanks.

---

## Material Slots Convention

### Blasters:
1. `Mat_Chassis`: Base plastic/metal body receiving DARTSTORM's procedural skin shader, ORM, and normal maps.
2. `Mat_Hardware`: Triggers, pins, safety levers, bolts (metallic).
3. `Mat_Safety`: High-visibility safety orange muzzle tips and battery detents.
4. `Mat_Grip`: Rubberized tactical grip panels with tactile grip ORM/normals.

### Characters:
1. `Mat_Clothing`: Shirt / hoodie / team color slot.
2. `Mat_Pants`: Trousers / shorts.
3. `Mat_Skin`: Exposed face, neck, and hands.
4. `Mat_Shoes`: Sneaker uppers and rubber soles.

---

## Polycount Budgets (Mobile 60 FPS Target)

- **Hero Character**: 3,500 – 5,500 triangles (LOD0).
- **Blasters**: 1,500 – 2,500 triangles (LOD0).
- **Arena Props**: 500 – 2,000 triangles each.
- **Target Scene Total**: < 50,000 rendered triangles per frame on mobile.
