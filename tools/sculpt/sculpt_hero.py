#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 — Sculpted Continuous Smooth-Skinned Cartoon Hero Generator
Generates assets/models/characters/hero_base.glb matching the vibrant Pixar/Splatoon
proportions, cozy hoodie, chunky rounded sneakers, layered hair bangs, glossy eyes,
and joyful cartoon smile demonstrated in docs/media/cover_art.jpg.
"""

from __future__ import annotations

import math
import os
import sys
from typing import List, Tuple

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_sculpt import (
    BoneSpec,
    MaterialSpec,
    MeshPart,
    NodeSpec,
    assign_rigid_bone,
    assign_smooth_bone_segments,
    bake_ao_cavity,
    beveled_cylinder,
    curved_tube,
    export_glb,
    loft_rings,
    merge_by_material,
    rounded_box,
    squircle_ring,
    superellipsoid,
    transform_part,
)


# ---------------------------------------------------------------------------
# Skeleton Definition (Exact bone names expected by CharacterModel & tests)
# ---------------------------------------------------------------------------

BONES: List[BoneSpec] = [
    BoneSpec("Root",        -1, (0.0,  0.00,  0.00)),   # 0
    BoneSpec("Hips",         0, (0.0,  0.66,  0.00)),   # 1  world (0, 0.66, 0)
    BoneSpec("Spine",        1, (0.0,  0.20,  0.00)),   # 2  world (0, 0.86, 0)
    BoneSpec("Chest",        2, (0.0,  0.26,  0.00)),   # 3  world (0, 1.12, 0)
    BoneSpec("Neck",         3, (0.0,  0.20,  0.00)),   # 4  world (0, 1.32, 0)
    BoneSpec("Head",         4, (0.0,  0.16,  0.00)),   # 5  world (0, 1.48, 0)

    BoneSpec("Shoulder_L",   3, (-0.14,  0.10,  0.00)), # 6  world (-0.14, 1.22, 0)
    BoneSpec("UpperArm_L",   6, (-0.15, -0.02,  0.00)), # 7  world (-0.29, 1.20, 0)
    BoneSpec("LowerArm_L",   7, (-0.02, -0.22, -0.02)), # 8  world (-0.31, 0.98, -0.02)
    BoneSpec("Hand_L",       8, ( 0.01, -0.20, -0.02)), # 9  world (-0.30, 0.78, -0.04)

    BoneSpec("Shoulder_R",   3, ( 0.14,  0.10,  0.00)), # 10 world (0.14, 1.22, 0)
    BoneSpec("UpperArm_R",  10, ( 0.15, -0.02,  0.00)), # 11 world (0.29, 1.20, 0)
    BoneSpec("LowerArm_R",  11, ( 0.02, -0.22, -0.02)), # 12 world (0.31, 0.98, -0.02)
    BoneSpec("Hand_R",      12, (-0.01, -0.20, -0.02)), # 13 world (0.30, 0.78, -0.04)

    BoneSpec("UpperLeg_L",   1, (-0.14, -0.04,  0.00)), # 14 world (-0.14, 0.62, 0)
    BoneSpec("LowerLeg_L",  14, ( 0.00, -0.26,  0.00)), # 15 world (-0.14, 0.36, 0)
    BoneSpec("Foot_L",      15, ( 0.00, -0.26, -0.02)), # 16 world (-0.14, 0.10, -0.02)

    BoneSpec("UpperLeg_R",   1, ( 0.14, -0.04,  0.00)), # 17 world (0.14, 0.62, 0)
    BoneSpec("LowerLeg_R",  17, ( 0.00, -0.26,  0.00)), # 18 world (0.14, 0.36, 0)
    BoneSpec("Foot_R",      18, ( 0.00, -0.26, -0.02)), # 19 world (0.14, 0.10, -0.02)
]

B_HIPS, B_SPINE, B_CHEST, B_NECK, B_HEAD = 1, 2, 3, 4, 5
B_SH_L, B_UA_L, B_LA_L, B_HA_L = 6, 7, 8, 9
B_SH_R, B_UA_R, B_LA_R, B_HA_R = 10, 11, 12, 13
B_UL_L, B_LL_L, B_FT_L = 14, 15, 16
B_UL_R, B_LL_R, B_FT_R = 17, 18, 19


MATERIALS: List[MaterialSpec] = [
    MaterialSpec("Mat_Clothing",   (0.15, 0.50, 0.96, 1.0), roughness=0.72),
    MaterialSpec("Mat_Pants",      (0.14, 0.24, 0.48, 1.0), roughness=0.78),
    MaterialSpec("Mat_Skin",       (1.00, 0.80, 0.64, 1.0), roughness=0.62),
    MaterialSpec("Mat_Shoes",      (0.97, 0.97, 0.99, 1.0), roughness=0.52),
    MaterialSpec("Mat_Hair",       (0.42, 0.23, 0.11, 1.0), roughness=0.58),
    MaterialSpec("Mat_Hardware",   (0.10, 0.13, 0.22, 1.0), roughness=0.35, metallic=0.25),
    MaterialSpec("Mat_WhiteTrim",  (0.98, 0.96, 0.92, 1.0), roughness=0.55),
    MaterialSpec("Mat_Sclera",     (0.99, 0.99, 1.00, 1.0), roughness=0.18),
    MaterialSpec("Mat_Iris",       (0.18, 0.44, 0.85, 1.0), roughness=0.15),
    MaterialSpec("Mat_Pupil",      (0.04, 0.05, 0.10, 1.0), roughness=0.10),
    MaterialSpec("Mat_Catchlight", (1.00, 1.00, 1.00, 1.0), roughness=0.05),
    MaterialSpec("Mat_Cheek",      (1.00, 0.56, 0.54, 1.0), roughness=0.68),
    MaterialSpec("Mat_MouthInner", (0.58, 0.14, 0.20, 1.0), roughness=0.65),
    MaterialSpec("Mat_Teeth",      (0.99, 0.99, 0.97, 1.0), roughness=0.22),
    MaterialSpec("Mat_Tongue",     (0.96, 0.42, 0.48, 1.0), roughness=0.48),
]


def _build_hoodie_torso() -> List[MeshPart]:
    """Cozy Pixar-proportioned sculpted hoodie with ribbed hem, collar cowl, back hood, pocket & drawstrings."""
    parts: List[MeshPart] = []

    # Main hoodie shell (tucks comfortably over hips down to Y=0.59 so pants never separate!)
    torso_rings = [
        squircle_ring((0.0, 0.59,  0.00), 0.275, 0.215, 24, 0.72),  # ribbed bottom hem edge
        squircle_ring((0.0, 0.64,  0.00), 0.295, 0.232, 24, 0.72),  # puffed above ribbing
        squircle_ring((0.0, 0.76, -0.01), 0.305, 0.238, 24, 0.74),  # cozy belly
        squircle_ring((0.0, 0.94, -0.01), 0.295, 0.226, 24, 0.74),  # mid chest
        squircle_ring((0.0, 1.12,  0.00), 0.290, 0.215, 24, 0.72),  # upper chest / shoulders
        squircle_ring((0.0, 1.24,  0.00), 0.245, 0.185, 24, 0.76),  # shoulder slope
        squircle_ring((0.0, 1.31,  0.00), 0.155, 0.145, 24, 0.88),  # neck opening
    ]
    torso = loft_rings("Mat_Clothing", torso_rings, cap_start=True, cap_end=True, grad_top=1.06, grad_bot=0.84)
    torso = bake_ao_cavity(torso, [
        ((0.0, 1.32, 0.0), 0.18, 0.18),   # collar shadow
        ((-0.26, 1.14, 0.0), 0.16, 0.16), # left armpit
        (( 0.26, 1.14, 0.0), 0.16, 0.16), # right armpit
        ((0.0, 0.60, 0.0), 0.28, 0.14),   # bottom hem crease
    ])
    parts.append(torso)

    # Folded chunky hoodie collar cowl wrapping warmly around the neck
    collar_pts = []
    n_c = 20
    for i in range(n_c + 1):
        a = (i / n_c) * 2.0 * math.pi
        collar_pts.append((math.sin(a) * 0.175, 1.315 - math.cos(a) * 0.022, math.cos(a) * 0.165 + 0.015))
    collar = curved_tube("Mat_Clothing", collar_pts, 0.056, segs=12, cap_start=False, cap_end=False)
    parts.append(collar)

    # Draped hood resting warmly behind shoulders (+Z)
    hood = superellipsoid("Mat_Clothing", 0.215, 0.115, 0.145, e1=0.68, e2=0.72, segs_u=18, segs_v=12)
    hood = transform_part(hood, pos=(0.0, 1.23, 0.205), rot_deg=(-22.0, 0.0, 0.0))
    parts.append(hood)

    # Front kangaroo belly pocket with curved top bevel
    pocket = superellipsoid("Mat_Clothing", 0.185, 0.095, 0.052, e1=0.48, e2=0.55, segs_u=18, segs_v=10, grad_top=1.02, grad_bot=0.82)
    pocket = transform_part(pocket, pos=(0.0, 0.77, -0.228), rot_deg=(-5.0, 0.0, 0.0))
    parts.append(pocket)

    # Two cute cream hoodie drawstrings with rounded aglets hanging down front
    for side in (-1.0, 1.0):
        string_pts = [
            (side * 0.062, 1.28, -0.175),
            (side * 0.068, 1.18, -0.218),
            (side * 0.064, 1.07, -0.232),
            (side * 0.058, 0.99, -0.236),
        ]
        parts.append(curved_tube("Mat_WhiteTrim", string_pts, 0.010, segs=8))
        aglet = beveled_cylinder("Mat_Hardware", 0.012, 0.012, 0.032, bevel=0.004, segs=10)
        parts.append(transform_part(aglet, pos=(side * 0.058, 0.975, -0.236)))

    # Smooth skin neck column connecting chest to head cleanly
    neck = beveled_cylinder("Mat_Skin", 0.095, 0.088, 0.16, bevel=0.01, segs=16)
    parts.append(transform_part(neck, pos=(0.0, 1.34, 0.0)))

    torso_segments = [
        (B_HIPS,  (0.0, 0.56, 0.0), (0.0, 0.74, 0.0), 0.26),
        (B_SPINE, (0.0, 0.76, 0.0), (0.0, 0.98, 0.0), 0.26),
        (B_CHEST, (0.0, 1.00, 0.0), (0.0, 1.28, 0.0), 0.28),
        (B_NECK,  (0.0, 1.29, 0.0), (0.0, 1.42, 0.0), 0.16),
    ]
    return [assign_smooth_bone_segments(p, torso_segments, falloff_power=3.0) for p in parts]


def _build_arm(side: float) -> List[MeshPart]:
    """Continuous lofted hoodie sleeve + ribbed cuff + sculpted cartoon hand with thumb."""
    parts: List[MeshPart] = []
    if side < 0:
        b_sh, b_ua, b_la, b_ha = B_SH_L, B_UA_L, B_LA_L, B_HA_L
    else:
        b_sh, b_ua, b_la, b_ha = B_SH_R, B_UA_R, B_LA_R, B_HA_R

    # Rounded shoulder cap tucked cleanly inside hoodie shoulder
    sh_cap = superellipsoid("Mat_Clothing", 0.105, 0.105, 0.102, e1=0.9, e2=0.9, segs_u=16, segs_v=10)
    parts.append(transform_part(sh_cap, pos=(side * 0.265, 1.185, 0.0)))

    # Continuous lofted hoodie sleeve from shoulder -> elbow -> wrist cuff
    sleeve_pts = [
        (side * 0.255, 1.19,  0.00),
        (side * 0.295, 1.10, -0.008),
        (side * 0.310, 0.98, -0.018),
        (side * 0.305, 0.87, -0.032),
        (side * 0.300, 0.825, -0.038),
    ]
    sleeve_radii = [0.095, 0.090, 0.086, 0.082, 0.070]
    parts.append(curved_tube("Mat_Clothing", sleeve_pts, sleeve_radii, segs=16, roundness=0.88))

    # Chunky ribbed cuff band
    cuff = beveled_cylinder("Mat_Clothing", 0.072, 0.078, 0.055, bevel=0.012, segs=16)
    parts.append(transform_part(cuff, pos=(side * 0.300, 0.835, -0.036)))

    # Sculpted cartoon hand: rounded mitten palm + cute thumb + soft curled finger pad
    palm = superellipsoid("Mat_Skin", 0.064, 0.068, 0.056, e1=0.82, e2=0.82, segs_u=16, segs_v=10)
    parts.append(transform_part(palm, pos=(side * 0.298, 0.765, -0.042)))
    thumb = superellipsoid("Mat_Skin", 0.026, 0.042, 0.026, e1=0.85, e2=0.85, segs_u=12, segs_v=8)
    parts.append(transform_part(thumb, pos=(side * 0.246, 0.772, -0.078), rot_deg=(28.0, 0.0, side * -32.0)))

    arm_segments = [
        (b_sh, (side * 0.16, 1.22,  0.00), (side * 0.26, 1.20,  0.00), 0.14),
        (b_ua, (side * 0.28, 1.19,  0.00), (side * 0.31, 1.00, -0.02), 0.12),
        (b_la, (side * 0.31, 0.98, -0.02), (side * 0.30, 0.82, -0.04), 0.11),
        (b_ha, (side * 0.30, 0.80, -0.04), (side * 0.30, 0.72, -0.05), 0.10),
    ]
    return [assign_smooth_bone_segments(p, arm_segments, falloff_power=3.6) for p in parts]


def _build_pants_and_sneakers() -> List[MeshPart]:
    """Continuous denim pelvis + tapered legs + chunky Pixar rounded sneakers resting at Y=0.0."""
    parts: List[MeshPart] = []

    # Pelvis / shorts base tucked neatly inside hoodie hem (Y=0.52..0.72) -> zero hip gap!
    pelvis = superellipsoid("Mat_Pants", 0.248, 0.135, 0.195, e1=0.72, e2=0.75, segs_u=22, segs_v=12, grad_top=0.92, grad_bot=0.84)
    pelvis = transform_part(pelvis, pos=(0.0, 0.615, 0.0))
    parts.append(assign_rigid_bone(pelvis, B_HIPS))

    for side in (-1.0, 1.0):
        b_ul, b_ll, b_ft = (B_UL_L, B_LL_L, B_FT_L) if side < 0 else (B_UL_R, B_LL_R, B_FT_R)
        x = side * 0.140

        # Smooth lofted pant leg from hip -> knee -> cuffed ankle inside sneaker
        leg_rings = [
            squircle_ring((x, 0.125, -0.01), 0.082, 0.085, 18, 0.88),  # ankle inside shoe collar
            squircle_ring((x, 0.165, -0.01), 0.095, 0.096, 18, 0.86),  # rolled pant cuff
            squircle_ring((x, 0.355, -0.005), 0.102, 0.105, 18, 0.88), # knee
            squircle_ring((x, 0.540,  0.00), 0.118, 0.120, 18, 0.86),  # upper thigh
            squircle_ring((x, 0.640,  0.00), 0.122, 0.125, 18, 0.86),  # hip blend
        ]
        leg = loft_rings("Mat_Pants", leg_rings, cap_start=True, cap_end=True, grad_top=0.98, grad_bot=0.84)
        leg = bake_ao_cavity(leg, [((x, 0.62, 0.0), 0.16, 0.18), ((x, 0.14, -0.01), 0.10, 0.15)])
        leg_segs = [
            (B_HIPS, (0.0, 0.65, 0.0), (x, 0.63, 0.0), 0.16),
            (b_ul,   (x, 0.61, 0.0),   (x, 0.38, 0.0), 0.14),
            (b_ll,   (x, 0.36, 0.0),   (x, 0.14, -0.01), 0.13),
        ]
        parts.append(assign_smooth_bone_segments(leg, leg_segs, falloff_power=3.6))

        # Chunky Pixar Cartoon Sneaker (rigidly weighted to Foot bone, bottom flat at Y=0.0)
        shoe_parts: List[MeshPart] = []

        # Thick rounded white rubber midsole (Y = 0.0..0.068)
        sole_rings = [
            squircle_ring((x, 0.000, -0.042), 0.088, 0.152, 20, 0.62),
            squircle_ring((x, 0.014, -0.042), 0.096, 0.162, 20, 0.62),
            squircle_ring((x, 0.056, -0.042), 0.096, 0.162, 20, 0.62),
            squircle_ring((x, 0.068, -0.040), 0.090, 0.154, 20, 0.64),
        ]
        shoe_parts.append(loft_rings("Mat_Shoes", sole_rings, cap_start=True, cap_end=True, grad_top=1.02, grad_bot=0.90))

        # Colorful sculpted sneaker upper (uses Mat_Clothing so shoes coordinate with hoodie!)
        upper = superellipsoid("Mat_Clothing", 0.088, 0.068, 0.138, e1=0.68, e2=0.72, segs_u=18, segs_v=12)
        shoe_parts.append(transform_part(upper, pos=(x, 0.096, -0.036)))

        # Padded white ankle collar + sculpted white sneaker toe-cap bumper
        collar = beveled_cylinder("Mat_Shoes", 0.092, 0.088, 0.046, bevel=0.014, segs=18)
        shoe_parts.append(transform_part(collar, pos=(x, 0.136, 0.006)))
        toe_cap = superellipsoid("Mat_Shoes", 0.082, 0.046, 0.058, e1=0.78, e2=0.75, segs_u=16, segs_v=10)
        shoe_parts.append(transform_part(toe_cap, pos=(x, 0.072, -0.145)))

        # Three chunky white sneaker laces across instep
        for li, (ly, lz) in enumerate([(0.128, -0.072), (0.112, -0.100), (0.096, -0.126)]):
            lace = rounded_box("Mat_WhiteTrim", (0.088, 0.016, 0.018), bevel=0.006, segs=10)
            shoe_parts.append(transform_part(lace, pos=(x, ly, lz), rot_deg=(28.0, 0.0, 0.0)))

        for sp in shoe_parts:
            parts.append(assign_rigid_bone(sp, b_ft))

    return parts


def _build_head_and_face() -> Tuple[List[MeshPart], List[MeshPart], List[MeshPart], List[MeshPart]]:
    """
    Returns (head_skinned_parts, eyelid_parts_local_to_head, smile_parts_local, flinch_parts_local).
    Head bone world origin is (0.0, 1.48, 0.0).
    """
    hy = 1.48  # Head bone world Y
    head_parts: List[MeshPart] = []

    # 1. Smooth higher-res Pixar kid head (soft sculpted cheeks, defined chin, rounded temples)
    head_rings = [
        squircle_ring((0.0, hy - 0.158, -0.014), 0.108, 0.112, 32, 0.92), # soft chin
        squircle_ring((0.0, hy - 0.112, -0.020), 0.190, 0.188, 32, 0.88), # smooth jawline
        squircle_ring((0.0, hy - 0.025, -0.012), 0.256, 0.244, 32, 0.88), # full Pixar cheeks
        squircle_ring((0.0, hy + 0.078, -0.004), 0.252, 0.250, 32, 0.90), # eye line
        squircle_ring((0.0, hy + 0.182,  0.004), 0.240, 0.244, 32, 0.92), # forehead
        squircle_ring((0.0, hy + 0.268,  0.006), 0.192, 0.198, 32, 0.94), # upper dome
        squircle_ring((0.0, hy + 0.314,  0.006), 0.092, 0.095, 32, 0.96), # crown
    ]
    head_mesh = loft_rings("Mat_Skin", head_rings, cap_start=True, cap_end=True, grad_top=1.04, grad_bot=0.92)
    head_mesh = bake_ao_cavity(head_mesh, [
        ((0.0, hy - 0.15, 0.0), 0.14, 0.14),
        ((-0.092, hy + 0.08, -0.22), 0.075, 0.10),
        (( 0.092, hy + 0.08, -0.22), 0.075, 0.10),
    ])
    head_parts.append(head_mesh)

    # Sculpted rounded ears with inner recess softness
    for side in (-1.0, 1.0):
        ear = superellipsoid("Mat_Skin", 0.056, 0.078, 0.042, e1=0.88, e2=0.88, segs_u=16, segs_v=12)
        head_parts.append(transform_part(ear, pos=(side * 0.248, hy + 0.050, 0.012), rot_deg=(0.0, side * -18.0, side * -8.0)))

    # Sculpted Pixar nose bridge + soft rounded tip
    nose_bridge = superellipsoid("Mat_Skin", 0.022, 0.032, 0.026, e1=0.85, e2=0.85, segs_u=14, segs_v=10)
    head_parts.append(transform_part(nose_bridge, pos=(0.0, hy + 0.046, -0.242), rot_deg=(-18.0, 0.0, 0.0)))
    nose = superellipsoid("Mat_Skin", 0.036, 0.028, 0.036, e1=0.88, e2=0.88, segs_u=16, segs_v=10, grad_top=1.06, grad_bot=0.88)
    head_parts.append(transform_part(nose, pos=(0.0, hy + 0.022, -0.260), rot_deg=(-10.0, 0.0, 0.0)))

    # Soft rosy cheek highlights (blended gently onto skin, never garish dots)
    for side in (-1.0, 1.0):
        cheek = superellipsoid("Mat_Cheek", 0.046, 0.024, 0.014, e1=0.92, e2=0.92, segs_u=14, segs_v=8)
        head_parts.append(transform_part(cheek, pos=(side * 0.152, hy + 0.002, -0.208), rot_deg=(0.0, side * 34.0, 0.0)))

    # Big Expressive Glossy Pixar Eyes + Soft Upper Eyelid Fold + Arched Sculpted Eyebrows
    for side in (-1.0, 1.0):
        ex, ey, ez = side * 0.090, hy + 0.082, -0.214
        sclera = superellipsoid("Mat_Sclera", 0.060, 0.068, 0.042, e1=0.88, e2=0.88, segs_u=20, segs_v=14)
        head_parts.append(transform_part(sclera, pos=(ex, ey, ez), rot_deg=(0.0, side * 14.0, 0.0)))
        iris = superellipsoid("Mat_Iris", 0.040, 0.046, 0.020, e1=0.9, e2=0.9, segs_u=18, segs_v=12)
        head_parts.append(transform_part(iris, pos=(ex * 0.99, ey, ez - 0.032), rot_deg=(0.0, side * 14.0, 0.0)))
        pupil = superellipsoid("Mat_Pupil", 0.024, 0.028, 0.015, e1=0.9, e2=0.9, segs_u=16, segs_v=10)
        head_parts.append(transform_part(pupil, pos=(ex * 0.99, ey, ez - 0.043), rot_deg=(0.0, side * 14.0, 0.0)))
        glint1 = superellipsoid("Mat_Catchlight", 0.013, 0.014, 0.008, e1=1.0, e2=1.0, segs_u=10, segs_v=6)
        head_parts.append(transform_part(glint1, pos=(ex + 0.016, ey + 0.019, ez - 0.052)))
        glint2 = superellipsoid("Mat_Catchlight", 0.006, 0.006, 0.005, e1=1.0, e2=1.0, segs_u=8, segs_v=6)
        head_parts.append(transform_part(glint2, pos=(ex - 0.013, ey - 0.014, ez - 0.051)))

        # Subtle sculpted upper lash/lid rim for warm Pixar expression
        lid_rim = [
            (ex - side * 0.048, ey + 0.038, ez - 0.024),
            (ex,                ey + 0.062, ez - 0.034),
            (ex + side * 0.050, ey + 0.036, ez - 0.018),
        ]
        head_parts.append(curved_tube("Mat_Hair", lid_rim, [0.006, 0.009, 0.006], segs=8))

        # Thick expressive arched Pixar eyebrows
        brow_pts = [
            (side * 0.040, ey + 0.088, -0.232),
            (side * 0.094, ey + 0.106, -0.236),
            (side * 0.148, ey + 0.086, -0.212),
        ]
        head_parts.append(curved_tube("Mat_Hair", brow_pts, [0.013, 0.019, 0.012], segs=12))

    # Voluminous Layered 3D Pixar Hair (rich crown cap + side tufts + 6 sculpted flowing locks!)
    hair_cap = superellipsoid("Mat_Hair", 0.264, 0.235, 0.260, e1=0.86, e2=0.88, segs_u=26, segs_v=16, grad_top=1.10, grad_bot=0.76)
    head_parts.append(transform_part(hair_cap, pos=(0.0, hy + 0.140, 0.034)))
    # Side locks framing temples & ears naturally
    for side in (-1.0, 1.0):
        sb = superellipsoid("Mat_Hair", 0.048, 0.102, 0.066, e1=0.78, e2=0.80, segs_u=14, segs_v=10)
        head_parts.append(transform_part(sb, pos=(side * 0.228, hy + 0.078, -0.052), rot_deg=(0.0, side * 12.0, side * 10.0)))
        tuft = curved_tube("Mat_Hair", [
            (side * 0.215, hy + 0.18, -0.06),
            (side * 0.235, hy + 0.11, -0.10),
            (side * 0.220, hy + 0.04, -0.11),
        ], [0.042, 0.036, 0.016], segs=10)
        head_parts.append(tuft)
    # 6 lush sculpted overlapping swept Pixar bangs & quiff curls!
    bang_specs = [
        ([(-0.14, hy + 0.275, -0.10), (-0.05, hy + 0.255, -0.225), (0.06, hy + 0.195, -0.258)], [0.064, 0.056, 0.020]),
        ([(-0.02, hy + 0.285, -0.11), ( 0.08, hy + 0.250, -0.225), (0.17, hy + 0.185, -0.218)], [0.060, 0.052, 0.020]),
        ([(-0.19, hy + 0.245, -0.08), (-0.17, hy + 0.205, -0.185), (-0.12, hy + 0.155, -0.232)], [0.052, 0.044, 0.018]),
        ([( 0.08, hy + 0.275, -0.09), ( 0.17, hy + 0.230, -0.175), (0.21, hy + 0.165, -0.168)], [0.052, 0.042, 0.018]),
        ([(-0.08, hy + 0.295, -0.04), ( 0.00, hy + 0.305, -0.155), (0.09, hy + 0.268, -0.215)], [0.068, 0.058, 0.026]),
        ([(-0.10, hy + 0.240, -0.16), (-0.02, hy + 0.205, -0.245), (0.05, hy + 0.172, -0.248)], [0.044, 0.036, 0.014]),
    ]
    for bpts, brads in bang_specs:
        head_parts.append(curved_tube("Mat_Hair", bpts, brads, segs=12))

    head_skinned = [assign_rigid_bone(p, B_HEAD) for p in head_parts]

    # --- Separate Facial Expression Nodes (local to Head bone origin (0, hy, 0)!) ---
    # 1. Animated Blinking Eyelids (closed shells slightly forward of sclera; scaled Y in CharacterModel)
    eyelid_parts: List[MeshPart] = []
    for side in (-1.0, 1.0):
        lid = superellipsoid("Mat_Skin", 0.068, 0.076, 0.048, e1=0.88, e2=0.88, segs_u=16, segs_v=10)
        eyelid_parts.append(transform_part(lid, pos=(side * 0.092, 0.082, -0.214), rot_deg=(0.0, side * 14.0, 0.0)))

    # 2. Joyful Open Cartoon Smile (bold curved coral grin + crisp white upper teeth + cute tongue)
    smile_parts: List[MeshPart] = []
    mouth_pts = [
        (-0.098, -0.028, -0.220),
        (-0.052, -0.068, -0.244),
        ( 0.000, -0.078, -0.252),
        ( 0.052, -0.068, -0.244),
        ( 0.098, -0.028, -0.220),
    ]
    smile_parts.append(curved_tube("Mat_MouthInner", mouth_pts, [0.015, 0.036, 0.042, 0.036, 0.015], segs=12))
    teeth_pts = [
        (-0.078, -0.032, -0.236),
        (-0.040, -0.048, -0.255),
        ( 0.000, -0.052, -0.262),
        ( 0.040, -0.048, -0.255),
        ( 0.078, -0.032, -0.236),
    ]
    smile_parts.append(curved_tube("Mat_Teeth", teeth_pts, [0.010, 0.017, 0.018, 0.017, 0.010], segs=10))
    tongue = superellipsoid("Mat_Tongue", 0.044, 0.020, 0.024, e1=0.88, e2=0.88, segs_u=12, segs_v=8)
    smile_parts.append(transform_part(tongue, pos=(0.0, -0.088, -0.250), rot_deg=(-12.0, 0.0, 0.0)))

    # 3. Surprised "O" Flinch / Zombie Mouth
    flinch_parts: List[MeshPart] = []
    o_mouth = superellipsoid("Mat_MouthInner", 0.042, 0.052, 0.026, e1=0.88, e2=0.88, segs_u=14, segs_v=10)
    flinch_parts.append(transform_part(o_mouth, pos=(0.0, -0.058, -0.238)))
    o_tongue = superellipsoid("Mat_Tongue", 0.024, 0.016, 0.016, e1=0.9, e2=0.9, segs_u=10, segs_v=6)
    flinch_parts.append(transform_part(o_tongue, pos=(0.0, -0.084, -0.244)))

    return head_skinned, eyelid_parts, smile_parts, flinch_parts


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_glb = os.path.join(repo_root, "assets", "models", "characters", "hero_base.glb")

    skinned_parts: List[MeshPart] = []
    skinned_parts.extend(_build_hoodie_torso())
    skinned_parts.extend(_build_arm(-1.0))
    skinned_parts.extend(_build_arm(1.0))
    skinned_parts.extend(_build_pants_and_sneakers())

    head_skinned, eyelid_parts, smile_parts, flinch_parts = _build_head_and_face()
    skinned_parts.extend(head_skinned)

    merged_body = merge_by_material(skinned_parts)

    # Facial expression overlays exported as clean static nodes under FacialExpressions
    # (pack_hero_scene.gd reparents them under BoneAttachment3D Attach_Head cleanly!)
    face_nodes = [
        NodeSpec("Mesh_Eyelids", parts=merge_by_material(eyelid_parts)),
        NodeSpec("Mesh_MouthSmile", parts=merge_by_material(smile_parts)),
        NodeSpec("Mesh_MouthFlinch", parts=merge_by_material(flinch_parts)),
    ]

    export_glb(
        out_path=out_glb,
        nodes=face_nodes,
        materials=MATERIALS,
        bones=BONES,
        skinned_root_parts=merged_body,
        skinned_mesh_name="HeroBodyMesh",
        root_name="HeroBase",
    )


if __name__ == "__main__":
    main()
