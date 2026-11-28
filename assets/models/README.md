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
├── characters/            # Hero base mesh & rig (generated via tools/generate_hero_asset.gd)
│   ├── hero_base.glb      # Base stylized character mesh & Skeleton3D
│   ├── hero_base.tscn     # Godot scene wrapper with stylized materials
│   └── animations/        # Reserved for standalone animation libraries
├── blasters/              # 7 modular 3D blaster classes (tools/generate_blaster_assets.gd)
│   ├── popper.glb         # Pocket Popper / Double Trouble pistol chassis
│   ├── storm.glb          # Dart Sprayer rapid-fire SMG chassis
│   ├── six_shot.glb       # Ricochet Ranger heavy revolver chassis
│   ├── sweeper.glb        # Foam Hammer pump-action shotgun chassis
│   ├── chainstorm.glb     # Flax's Chainstorm six-barrel rotary minigun
│   ├── whisper.glb        # Longshot / Wind Whisperer precision rifle
│   └── rocket.glb         # Heavy elemental launcher (Hydro Soaker / Thunder Cannon / Frost Ranger)
│   # Note: Foam Bat melee weapon is built procedurally in scripts/effects/blaster_model.gd (_build_bat).
├── props/                 # 13 stylized arena dressing props (tools/generate_prop_assets.gd)
│   ├── archway_curved.glb     # Desert / temple rounded sandstone arch
│   ├── cartoon_tree.glb       # Chunky stylized backyard / park foliage tree
│   ├── desert_urn.glb         # Terracotta desert pottery prop
│   ├── dog_house.glb          # Backyard dog house with arched doorway
│   ├── inflatable_barrier.glb # High-vis curved foam barricade
│   ├── inflatable_bunker.glb  # Chunky inflatable arena bunker
│   ├── market_awning.glb      # Striped fabric market canopy
│   ├── picnic_table.glb       # Wooden backyard picnic table
│   ├── playground_slide.glb   # Curved playground slide
│   ├── soccer_goal.glb        # Stadium soccer goal frame
│   ├── tactical_barrel.glb    # Cartoon safety-banded foam barrel
│   ├── tactical_crate.glb     # Beveled wooden supply crate
│   ├── watchtower.glb         # Elevated wooden fort watchtower
│   └── wooden_pallet.glb      # Stacked timber pallet cover
└── hats/                  # Procedural hats built in scripts/effects/character_model.gd
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

## Polycount Budgets & v2.0.0 Cover-Art Sculpting Standard

All v2.0.0 `.glb` models are authored deterministically via pure-Python parametric sculpting (`tools/sculpt/` using `numpy` + `PIL` Catmull-Clark subdivision, beveled extrusion, spline lofting, smooth automatic bone weights, and baked curvature/AO textures) and validated in Godot 4.4:

- **Hero Character (`hero_base.glb`):** Continuous smooth-skinned humanoid mesh weighted to `GeneralSkeleton` (zero disconnected capsule gaps), 4,500–7,500 triangles (LOD0), preserving all 4 `BoneAttachment3D` sockets (`Socket_Hand_R`, `Socket_Hand_L`, `Socket_Head`, `Socket_Back`) and animated facial expression meshes (eyes, blink lids, brows, smiling/flinching/cheering mouth).
- **First-Person Cartoon Arms (`fp_arms.glb` / `scripts/effects/fp_arms.gd`):** Sculpted hoodie sleeves + chunky cartoon hands tracking blaster `GripMarker` and `ForegripMarker` sockets (~1,200 triangles total, tinted dynamically to player jersey & skin tone).
- **Blasters & Foam Bat (`blasters/*.glb`):** Chunky blow-molded beveled toy shells with ergonomic grips and flanged safety-orange tips, 2,000–4,000 triangles (LOD0), preserving all moving mechanical sub-nodes (`Slide`, `Cylinder`, `PumpSlide`, `BarrelCluster`) and attachment rails.
- **Arena Props (`props/*.glb`):** Sculpted multi-cluster canopies, beveled timber structures, rounded inflatable bunkers, and comic props, 600–2,800 triangles each (visual-only children; solid `arena.geometry` colliders stay simple and navmesh-clean).
- **Target Scene Total:** < 60,000 rendered triangles per frame on mobile/Web (`Low`/`Medium`), unconstrained crisp stylized detail on desktop Forward+ (`High`/`Ultra`).
