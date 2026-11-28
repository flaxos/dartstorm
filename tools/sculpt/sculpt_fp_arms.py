#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 — Sculpted Articulated First-Person Pixar Hoodie Arms & Hands
Exports assets/models/characters/fp_arms.glb with separate RightArm & LeftArm
nodes containing folded fleece hoodie forearms, knitted ribbed cuffs, anatomical
stylized palms, opposable thumbs, and 4 softly curled gripping fingers.
"""

from __future__ import annotations

import os
import sys
from typing import List

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_sculpt import (
    MaterialSpec,
    MeshPart,
    NodeSpec,
    beveled_cylinder,
    curved_tube,
    export_glb,
    merge_by_material,
    superellipsoid,
    transform_part,
)

FP_MATERIALS: List[MaterialSpec] = [
    MaterialSpec("sleeve", (0.16, 0.48, 0.98, 1.0), roughness=0.86),
    MaterialSpec("cuff",   (0.11, 0.36, 0.80, 1.0), roughness=0.90),
    MaterialSpec("skin",   (1.00, 0.80, 0.64, 1.0), roughness=0.56),
]


def _build_right_arm() -> List[MeshPart]:
    """Trigger-hand forearm & sculpted 5-finger gripping hand anchored near (0.01, -0.10, 0.06)."""
    parts: List[MeshPart] = []

    # Sculpted curved fleece forearm sleeve reaching seamlessly into wrist cuff
    sleeve_pts = [
        (0.20, -0.34, 0.30),
        (0.14, -0.25, 0.21),
        (0.088, -0.185, 0.142),
        (0.052, -0.145, 0.098),
    ]
    parts.append(curved_tube("sleeve", sleeve_pts, [0.064, 0.058, 0.053, 0.044], segs=18, roundness=0.88))

    # Knitted ribbed hoodie cuff hugging the wrist cleanly
    cuff_pts = [
        (0.056, -0.150, 0.104),
        (0.034, -0.125, 0.080),
    ]
    parts.append(curved_tube("cuff", cuff_pts, [0.048, 0.044], segs=18))

    # Anatomical wrist + softly sculpted palm cushion
    wrist = beveled_cylinder("skin", 0.032, 0.034, 0.045, bevel=0.008, segs=14)
    parts.append(transform_part(wrist, pos=(0.025, -0.116, 0.072), rot_deg=(48.0, -18.0, 14.0)))
    palm = superellipsoid("skin", 0.038, 0.046, 0.030, e1=0.72, e2=0.78, segs_u=18, segs_v=12)
    parts.append(transform_part(palm, pos=(0.012, -0.100, 0.056), rot_deg=(-14.0, 10.0, 0.0)))

    # Opposable curved thumb wrapping upper-left side of grip
    thumb_pts = [
        (-0.012, -0.096, 0.064),
        (-0.026, -0.082, 0.052),
        (-0.024, -0.072, 0.030),
    ]
    parts.append(curved_tube("skin", thumb_pts, [0.016, 0.014, 0.011], segs=12))

    # 4 softly curled gripping fingers wrapping front of grip
    finger_ys = [-0.078, -0.096, -0.113, -0.128]
    finger_r = [0.011, 0.0115, 0.0105, 0.0095]
    for fy, fr in zip(finger_ys, finger_r):
        f_pts = [
            (0.024, fy, 0.042),
            (0.014, fy - 0.003, 0.014),
            (-0.010, fy - 0.004, 0.010),
        ]
        parts.append(curved_tube("skin", f_pts, [fr, fr * 0.94, fr * 0.82], segs=10))

    return merge_by_material(parts)


def _build_left_arm() -> List[MeshPart]:
    """Supporting forearm & cupped 5-finger cradling hand anchored near (-0.03, -0.12, -0.09)."""
    parts: List[MeshPart] = []

    # Continuous curved hoodie forearm seamlessly connecting into cuff (ZERO gap!)
    sleeve_pts = [
        (-0.22, -0.34, 0.24),
        (-0.155, -0.245, 0.125),
        (-0.102, -0.180, 0.030),
        (-0.068, -0.148, -0.032),
    ]
    parts.append(curved_tube("sleeve", sleeve_pts, [0.062, 0.055, 0.048, 0.041], segs=18, roundness=0.88))

    # Knitted ribbed hoodie cuff
    cuff_pts = [
        (-0.074, -0.154, -0.024),
        (-0.052, -0.135, -0.062),
    ]
    parts.append(curved_tube("cuff", cuff_pts, [0.045, 0.040], segs=18))

    # Sculpted cupped supporting palm
    palm = superellipsoid("skin", 0.042, 0.030, 0.040, e1=0.72, e2=0.78, segs_u=18, segs_v=12)
    parts.append(transform_part(palm, pos=(-0.032, -0.122, -0.092), rot_deg=(12.0, 22.0, -8.0)))

    # Opposable supporting thumb along inner edge
    thumb_pts = [
        (-0.012, -0.118, -0.072),
        ( 0.006, -0.106, -0.088),
        ( 0.008, -0.096, -0.112),
    ]
    parts.append(curved_tube("skin", thumb_pts, [0.015, 0.013, 0.010], segs=12))

    # 4 softly curled cradling fingers wrapping under/around foregrip
    finger_zs = [-0.076, -0.092, -0.108, -0.122]
    finger_r = [0.0105, 0.011, 0.010, 0.009]
    for fz, fr in zip(finger_zs, finger_r):
        f_pts = [
            (-0.042, -0.128, fz),
            (-0.018, -0.134, fz - 0.012),
            ( 0.012, -0.118, fz - 0.016),
        ]
        parts.append(curved_tube("skin", f_pts, [fr, fr * 0.94, fr * 0.80], segs=10))

    return merge_by_material(parts)


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_glb = os.path.join(repo_root, "assets", "models", "characters", "fp_arms.glb")
    nodes = [
        NodeSpec("RightArm", parts=_build_right_arm()),
        NodeSpec("LeftArm", parts=_build_left_arm()),
    ]
    export_glb(out_path=out_glb, nodes=nodes, materials=FP_MATERIALS, root_name="FirstPersonArms")


if __name__ == "__main__":
    main()
