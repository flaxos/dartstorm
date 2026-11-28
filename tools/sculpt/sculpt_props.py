#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 Parametric Stylized Arena Props Sculptor (Pure Python + NumPy)

Re-sculpts key shared arena props in assets/models/props/*.glb with beveled
cartoon toy silhouettes, multi-cluster leafy canopies, smooth blow-up vinyl
chambers, curved slides, sculpted stone archways, and baked vertex AO.
Companion .tscn scenes (preserving StaticBody3D colliders on Layers.WORLD and
interactive _dog/_tail nodes) are packed via tools/sculpt/pack_prop_scenes.gd.
"""

from __future__ import annotations

import math
import os
import sys
from typing import Dict, List, Tuple

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_sculpt import (
    MaterialSpec,
    MeshPart,
    NodeSpec,
    beveled_cylinder,
    compute_smooth_normals,
    curved_tube,
    export_glb,
    loft_rings,
    merge_by_material,
    rounded_box,
    squircle_ring,
    superellipsoid,
    transform_part,
)

PROP_MATERIALS: List[MaterialSpec] = [
    MaterialSpec("wood",           (0.76, 0.52, 0.28, 1.0), roughness=0.72, metallic=0.0),
    MaterialSpec("wood_dark",      (0.52, 0.33, 0.17, 1.0), roughness=0.78, metallic=0.0),
    MaterialSpec("shingle",        (0.88, 0.26, 0.20, 1.0), roughness=0.62, metallic=0.0),
    MaterialSpec("plastic_yellow", (1.00, 0.84, 0.12, 1.0), roughness=0.28, metallic=0.04),
    MaterialSpec("plastic_red",    (0.95, 0.24, 0.20, 1.0), roughness=0.28, metallic=0.04),
    MaterialSpec("plastic_blue",   (0.16, 0.50, 0.98, 1.0), roughness=0.28, metallic=0.04),
    MaterialSpec("plastic_orange", (1.00, 0.48, 0.08, 1.0), roughness=0.28, metallic=0.04),
    MaterialSpec("steel",          (0.95, 0.96, 0.99, 1.0), roughness=0.26, metallic=0.75),
    MaterialSpec("steel_dark",     (0.18, 0.22, 0.32, 1.0), roughness=0.34, metallic=0.60),
    MaterialSpec("leaf",           (0.20, 0.66, 0.22, 1.0), roughness=0.62, metallic=0.0),
    MaterialSpec("leaf_light",     (0.38, 0.82, 0.26, 1.0), roughness=0.56, metallic=0.0),
    MaterialSpec("fur",            (0.88, 0.64, 0.36, 1.0), roughness=0.78, metallic=0.0),
    MaterialSpec("fur_dark",       (0.54, 0.35, 0.18, 1.0), roughness=0.82, metallic=0.0),
    MaterialSpec("vinyl",          (0.14, 0.56, 0.98, 1.0), roughness=0.24, metallic=0.05),
    MaterialSpec("vinyl_accent",   (1.00, 0.46, 0.06, 1.0), roughness=0.24, metallic=0.05),
    MaterialSpec("sandstone",      (0.88, 0.77, 0.56, 1.0), roughness=0.82, metallic=0.0),
    MaterialSpec("sandstone_dark", (0.74, 0.62, 0.44, 1.0), roughness=0.85, metallic=0.0),
    MaterialSpec("terracotta",     (0.86, 0.44, 0.26, 1.0), roughness=0.74, metallic=0.0),
    MaterialSpec("barrel_yellow",  (0.98, 0.78, 0.12, 1.0), roughness=0.30, metallic=0.06),
    MaterialSpec("hazard_black",   (0.14, 0.18, 0.28, 1.0), roughness=0.42, metallic=0.0),
    MaterialSpec("pallet_wood",    (0.72, 0.50, 0.30, 1.0), roughness=0.76, metallic=0.0),
]


def _place(part: MeshPart, pos=(0.0, 0.0, 0.0), rot_deg=(0.0, 0.0, 0.0)) -> MeshPart:
    return transform_part(part, pos=pos, rot_deg=rot_deg)


def _box(mat: str, size: Tuple[float, float, float], pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), bevel: float = 0.03) -> MeshPart:
    b = min(bevel, min(size) * 0.32)
    return _place(rounded_box(mat, size, bevel=b), pos, rot)


def _cyl(mat: str, r_bot: float, r_top: float, h: float, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0),
         bevel: float = 0.02, segs: int = 18) -> MeshPart:
    b = min(bevel, min(r_bot, r_top) * 0.35, h * 0.25)
    return _place(beveled_cylinder(mat, r_bot, r_top, h, segs=segs, bevel=b), pos, rot)


def _puff(mat: str, rx: float, ry: float, rz: float, pos=(0.0, 0.0, 0.0), exp: float = 0.92,
          rings: int = 10, segs: int = 16, organic_amp: float = 0.0, seed: float = 0.0) -> MeshPart:
    p = superellipsoid(mat, rx, ry, rz, e1=exp, e2=exp, segs_u=segs, segs_v=rings, grad_top=1.08, grad_bot=0.78)
    if organic_amp > 0.0:
        v = p.positions.astype(np.float64)
        n = p.normals.astype(np.float64)
        # Organic multi-octave leaf-billow surface sculpting (breaks smooth sphere silhouettes!)
        px = v[:, 0] / max(rx, 0.1) + seed * 1.7
        py = v[:, 1] / max(ry, 0.1) + seed * 2.3
        pz = v[:, 2] / max(rz, 0.1) + seed * 3.1
        b1 = np.sin(px * 3.2 + py * 2.1) * np.cos(pz * 3.4 - py * 1.9)
        b2 = np.cos(px * 5.8 - pz * 5.2 + py * 4.4) * 0.45
        disp = (b1 + b2) * organic_amp * min(rx, ry, rz)
        v_new = (v + n * disp[:, None]).astype(np.float32)
        n_new = compute_smooth_normals(v_new, p.indices)
        p = MeshPart(p.material, v_new, n_new, p.uvs, p.colors, p.indices)
    return _place(p, pos)


def _bake_parts(parts: List[MeshPart], dark: float = 0.76) -> List[MeshPart]:
    return merge_by_material(parts)


# ===========================================================================
# 1. CARTOON TREE — Multi-cluster organic sculpted foliage + flared bark trunk
# ===========================================================================
def build_cartoon_tree() -> List[NodeSpec]:
    trunk_parts: List[MeshPart] = []

    # Sculpted curved flared bark trunk (lofted organic rings)
    trunk_specs = [
        (0.00, 1.05, 1.05, 0.00, 0.00),
        (0.55, 0.76, 0.76, 0.03, 0.02),
        (1.60, 0.62, 0.62, 0.06, -0.02),
        (3.10, 0.56, 0.56, 0.02, -0.04),
        (4.50, 0.68, 0.68, 0.00, 0.00),
    ]
    rings = [squircle_ring((cx, y, cz), rx, rz, 16, roundness=1.0) for y, rx, rz, cx, cz in trunk_specs]
    trunk_parts.append(loft_rings("wood_dark", rings, cap_start=True, cap_end=True))

    # 4 smooth curved buttress roots gripping the lawn
    for i in range(4):
        ang = i * math.tau / 4.0 + 0.35
        ca, sa = math.cos(ang), math.sin(ang)
        pts = [
            (ca * 0.45, 0.85, sa * 0.45),
            (ca * 0.88, 0.36, sa * 0.88),
            (ca * 1.28, 0.06, sa * 1.28),
        ]
        trunk_parts.append(curved_tube("wood_dark", pts, 0.22, segs=10))

    # 2 chunky upper boughs reaching into the canopy
    trunk_parts.append(curved_tube("wood_dark", [(0.0, 3.8, 0.0), (0.85, 4.7, 0.35), (1.4, 5.4, 0.55)], 0.22, segs=10))
    trunk_parts.append(curved_tube("wood_dark", [(0.0, 3.9, 0.0), (-0.9, 4.8, -0.35), (-1.45, 5.5, -0.5)], 0.22, segs=10))

    # 11-cluster organically sculpted billowy oak leafy canopy (high-density bumpy foliage tufts!)
    canopy_parts: List[MeshPart] = []
    dark_puffs = [
        (0.0, 5.1, 0.0,   2.75, 1.85, 2.75),
        (-2.1, 5.3, 0.9,  1.65, 1.35, 1.65),
        (2.1, 5.2, -0.8,  1.65, 1.35, 1.65),
        (0.6, 5.2, 2.0,   1.60, 1.30, 1.60),
        (-0.8, 5.3, -2.0, 1.60, 1.30, 1.60),
    ]
    for idx, (x, y, z, rx, ry, rz) in enumerate(dark_puffs):
        canopy_parts.append(_puff("leaf", rx, ry, rz, pos=(x, y, z), exp=0.90, rings=14, segs=22, organic_amp=0.14, seed=float(idx + 1)))

    light_puffs = [
        (0.15, 7.1, -0.15, 2.15, 1.65, 2.15),
        (-1.45, 6.4, 0.65, 1.45, 1.25, 1.45),
        (1.55, 6.3, -0.55, 1.45, 1.25, 1.45),
        (0.55, 6.3, 1.45,  1.38, 1.18, 1.38),
        (-0.65, 6.4, -1.45,1.40, 1.20, 1.40),
        (0.0, 8.2, 0.1,    1.25, 0.98, 1.25),
    ]
    for idx, (x, y, z, rx, ry, rz) in enumerate(light_puffs):
        canopy_parts.append(_puff("leaf_light", rx, ry, rz, pos=(x, y, z), exp=0.88, rings=14, segs=22, organic_amp=0.15, seed=float(idx + 10)))

    return [
        NodeSpec("TrunkBase", parts=_bake_parts(trunk_parts, dark=0.72)),
        NodeSpec("CanopyBase", parts=_bake_parts(canopy_parts, dark=0.72)),
    ]


# ===========================================================================
# 2. INFLATABLE BARRIER — Smooth pill vinyl air chambers + glossy end-caps
# ===========================================================================
def build_inflatable_barrier() -> List[NodeSpec]:
    w, d = 2.4, 0.65
    r = d * 0.5
    body_len = w - d
    low_y = 0.08 + r
    high_y = low_y + r * 1.65

    parts: List[MeshPart] = [
        # Lower & upper smooth rounded vinyl air chambers
        _cyl("vinyl", r, r, body_len, pos=(0.0, low_y, 0.0), rot=(0.0, 0.0, 90.0), bevel=0.04, segs=20),
        _puff("vinyl_accent", r * 1.02, r * 1.02, r * 1.02, pos=(-body_len * 0.5, low_y, 0.0), exp=0.96, rings=10, segs=16),
        _puff("vinyl_accent", r * 1.02, r * 1.02, r * 1.02, pos=( body_len * 0.5, low_y, 0.0), exp=0.96, rings=10, segs=16),

        _cyl("vinyl", r * 0.94, r * 0.94, body_len, pos=(0.0, high_y, 0.0), rot=(0.0, 0.0, 90.0), bevel=0.04, segs=20),
        _puff("vinyl_accent", r * 0.96, r * 0.96, r * 0.96, pos=(-body_len * 0.5, high_y, 0.0), exp=0.96, rings=10, segs=16),
        _puff("vinyl_accent", r * 0.96, r * 0.96, r * 0.96, pos=( body_len * 0.5, high_y, 0.0), exp=0.96, rings=10, segs=16),

        # Yellow reinforced top welting pipe
        _cyl("plastic_yellow", 0.048, 0.048, body_len + 0.22, pos=(0.0, high_y + r * 0.92, 0.0), rot=(0.0, 0.0, 90.0), bevel=0.02, segs=12),
    ]
    # Heavy rubber tie-down straps + beveled weighted feet
    for sx in (-0.70, 0.70):
        parts.append(_box("hazard_black", (0.16, high_y + 0.04, d * 1.06), pos=(sx, high_y * 0.5 + 0.04, 0.0), bevel=0.035))
        parts.append(_box("steel_dark", (0.44, 0.09, d * 1.28), pos=(sx, 0.045, 0.0), bevel=0.025))

    return [NodeSpec("Mesh_Barrier", parts=_bake_parts(parts, dark=0.80))]


# ===========================================================================
# 3. INFLATABLE BUNKER — Smooth domed speedball vinyl pillar
# ===========================================================================
def build_inflatable_bunker() -> List[NodeSpec]:
    r, h = 0.72, 2.1
    body_parts: List[MeshPart] = [
        _cyl("vinyl", r * 1.04, r * 0.98, h - 0.15, pos=(0.0, (h - 0.15) * 0.5 + 0.06, 0.0), bevel=0.08, segs=22),
        _puff("vinyl", r * 0.98, r * 0.55, r * 0.98, pos=(0.0, h - 0.10, 0.0), exp=0.95, rings=10, segs=18),
        _cyl("vinyl_accent", r + 0.12, r + 0.06, 0.16, pos=(0.0, 0.08, 0.0), bevel=0.04, segs=22),
        _cyl("plastic_orange", 0.085, 0.075, 0.10, pos=(r + 0.02, 0.36, 0.0), rot=(0.0, 0.0, 90.0), bevel=0.02, segs=12),
    ]
    band_parts: List[MeshPart] = [
        _cyl("vinyl_accent", r + 0.025, r + 0.025, 0.44, pos=(0.0, h * 0.55, 0.0), bevel=0.03, segs=22),
    ]
    return [
        NodeSpec("VinylBody", parts=_bake_parts(body_parts, dark=0.78)),
        NodeSpec("AccentBand", parts=_bake_parts(band_parts, dark=0.78)),
    ]


# ===========================================================================
# 4. TACTICAL CRATE — Beveled wooden fort crate with chamfered cross-bracing
# ===========================================================================
def build_tactical_crate() -> List[NodeSpec]:
    parts: List[MeshPart] = [
        _box("wood", (1.68, 1.68, 1.68), pos=(0.0, 0.90, 0.0), bevel=0.04),
    ]
    for ox in (-0.82, 0.82):
        for oz in (-0.82, 0.82):
            parts.append(_box("wood_dark", (0.16, 1.80, 0.16), pos=(ox, 0.90, oz), bevel=0.03))
    for y_pos in (0.08, 1.72):
        parts.append(_box("wood_dark", (1.56, 0.16, 0.16), pos=(0.0, y_pos, -0.82), bevel=0.03))
        parts.append(_box("wood_dark", (1.56, 0.16, 0.16), pos=(0.0, y_pos,  0.82), bevel=0.03))
        parts.append(_box("wood_dark", (0.16, 0.16, 1.56), pos=(-0.82, y_pos, 0.0), bevel=0.03))
        parts.append(_box("wood_dark", (0.16, 0.16, 1.56), pos=( 0.82, y_pos, 0.0), bevel=0.03))
    for side in (-0.84, 0.84):
        parts.append(_box("wood_dark", (2.06, 0.12, 0.08), pos=(0.0, 0.90, side), rot=(0.0, 0.0,  45.0), bevel=0.02))
        parts.append(_box("wood_dark", (2.06, 0.12, 0.08), pos=(0.0, 0.90, side), rot=(0.0, 0.0, -45.0), bevel=0.02))
        parts.append(_box("wood_dark", (0.08, 0.12, 2.06), pos=(side, 0.90, 0.0), rot=( 45.0, 0.0, 0.0), bevel=0.02))
        parts.append(_box("wood_dark", (0.08, 0.12, 2.06), pos=(side, 0.90, 0.0), rot=(-45.0, 0.0, 0.0), bevel=0.02))
    for ox in (-0.84, 0.84):
        for oy in (0.09, 1.71):
            for oz in (-0.84, 0.84):
                parts.append(_box("steel_dark", (0.20, 0.20, 0.20), pos=(ox, oy, oz), bevel=0.04))
    return [NodeSpec("Mesh_Crate", parts=_bake_parts(parts, dark=0.72))]


# ===========================================================================
# 5. TACTICAL BARREL — Smooth ribbed cartoon foam barrel with rolled chimes
# ===========================================================================
def build_tactical_barrel() -> List[NodeSpec]:
    parts: List[MeshPart] = [
        _cyl("barrel_yellow", 0.42, 0.42, 1.36, pos=(0.0, 0.70, 0.0), bevel=0.03, segs=22),
        _cyl("steel_dark",    0.45, 0.45, 0.07, pos=(0.0, 1.37, 0.0), bevel=0.02, segs=22),
        _cyl("steel_dark",    0.45, 0.45, 0.07, pos=(0.0, 0.035, 0.0), bevel=0.02, segs=22),
        _cyl("steel_dark",    0.44, 0.44, 0.06, pos=(0.0, 0.48, 0.0), bevel=0.02, segs=22),
        _cyl("steel_dark",    0.44, 0.44, 0.06, pos=(0.0, 0.92, 0.0), bevel=0.02, segs=22),
        _cyl("hazard_black",  0.43, 0.43, 0.24, pos=(0.0, 0.70, 0.0), bevel=0.02, segs=22),
        _cyl("steel",         0.048, 0.048, 0.04, pos=( 0.18, 1.40, 0.0), bevel=0.01, segs=12),
        _cyl("steel",         0.038, 0.038, 0.04, pos=(-0.18, 1.40, 0.0), bevel=0.01, segs=12),
    ]
    return [NodeSpec("Mesh_Barrel", parts=_bake_parts(parts, dark=0.76))]


# ===========================================================================
# 6. PLAYGROUND SLIDE — Glossy yellow cartoon slide with tubular safety rails
# ===========================================================================
def build_playground_slide() -> List[NodeSpec]:
    deck_h = 3.2
    parts: List[MeshPart] = []
    for ox in (-0.95, 0.95):
        for oz in (-0.95, 0.95):
            parts.append(_cyl("steel", 0.14, 0.14, deck_h, pos=(ox, deck_h * 0.5, oz), bevel=0.02, segs=14))
    parts.append(_box("plastic_blue", (2.44, 0.26, 2.44), pos=(0.0, deck_h, 0.0), bevel=0.06))
    parts.append(_box("plastic_yellow", (2.4, 1.0, 0.14), pos=(0.0, deck_h + 0.5, -1.15), bevel=0.04))
    parts.append(_box("plastic_yellow", (0.14, 1.0, 2.4), pos=(-1.15, deck_h + 0.5, 0.0), bevel=0.04))
    # Ladder rails & colorful rungs on South (+Z)
    for lx in (-0.52, 0.52):
        parts.append(_cyl("plastic_red", 0.06, 0.06, deck_h + 0.4, pos=(lx, (deck_h + 0.4) * 0.5, 1.25), bevel=0.02, segs=12))
    for r_i in range(7):
        rung_y = float(r_i) * (deck_h / 7.0) + 0.24
        parts.append(_cyl("plastic_yellow", 0.055, 0.055, 1.04, pos=(0.0, rung_y, 1.25), rot=(0.0, 0.0, 90.0), bevel=0.02, segs=12))

    # Molded Chute running to +X (SlideBed contract preserved!)
    dx = 6.5 - 1.2
    dy = deck_h - 0.15
    slide_len = math.hypot(dx, dy)
    slide_angle = -math.degrees(math.atan2(dy, dx))
    mid = ((1.2 + 6.5) * 0.5, (deck_h + 0.15) * 0.5, 0.0)
    bed_parts: List[MeshPart] = [
        _box("plastic_yellow", (slide_len + 0.15, 0.20, 1.52), pos=mid, rot=(0.0, 0.0, slide_angle), bevel=0.05),
        _box("plastic_yellow", (1.65, 0.18, 1.52), pos=(7.1, 0.09, 0.0), bevel=0.05),
    ]
    for side_z in (-0.72, 0.72):
        # Smooth tubular glossy red handrails down the slide!
        pts = [
            (1.15, deck_h + 0.30, side_z),
            (3.85, (deck_h + 0.15) * 0.5 + 0.26, side_z),
            (6.55, 0.36, side_z),
            (7.75, 0.28, side_z),
        ]
        bed_parts.append(curved_tube("plastic_red", pts, 0.11, segs=12))
    return [
        NodeSpec("SlideFrame", parts=_bake_parts(parts, dark=0.80)),
        NodeSpec("SlideBed", parts=_bake_parts(bed_parts, dark=0.80)),
    ]


# ===========================================================================
# 7. ARCHWAY CURVED — Beveled golden sandstone voussoirs + keystone + plinths
# ===========================================================================
def build_archway_curved() -> List[NodeSpec]:
    pillar_w, pillar_h, depth, span = 0.8, 3.6, 1.2, 3.6
    half_span = span * 0.5
    parts: List[MeshPart] = [
        _box("sandstone", (pillar_w, pillar_h, depth), pos=(-half_span - pillar_w * 0.5, pillar_h * 0.5, 0.0), bevel=0.06),
        _box("sandstone", (pillar_w, pillar_h, depth), pos=( half_span + pillar_w * 0.5, pillar_h * 0.5, 0.0), bevel=0.06),
        _box("sandstone_dark", (pillar_w + 0.18, 0.32, depth + 0.18), pos=(-half_span - pillar_w * 0.5, 0.16, 0.0), bevel=0.05),
        _box("sandstone_dark", (pillar_w + 0.18, 0.32, depth + 0.18), pos=( half_span + pillar_w * 0.5, 0.16, 0.0), bevel=0.05),
        _box("sandstone_dark", (pillar_w + 0.20, 0.28, depth + 0.20), pos=(-half_span - pillar_w * 0.5, pillar_h - 0.12, 0.0), bevel=0.05),
        _box("sandstone_dark", (pillar_w + 0.20, 0.28, depth + 0.20), pos=( half_span + pillar_w * 0.5, pillar_h - 0.12, 0.0), bevel=0.05),
    ]
    segments = 9
    for i in range(segments):
        ang_deg = 180.0 * (i + 0.5) / segments
        rad = math.radians(ang_deg)
        vx = math.cos(rad) * half_span
        vy = pillar_h + math.sin(rad) * 1.12
        parts.append(_box("sandstone", (0.66, 0.44, depth * 0.98), pos=(vx, vy, 0.0), rot=(0.0, 0.0, ang_deg - 90.0), bevel=0.05))
    parts.append(_box("sandstone_dark", (0.70, 0.64, depth * 1.10), pos=(0.0, pillar_h + 1.16, 0.0), bevel=0.06))
    top_w = (half_span + pillar_w) * 2.0 + 0.34
    parts.append(_box("sandstone_dark", (top_w, 0.38, depth + 0.24), pos=(0.0, pillar_h + 1.46, 0.0), bevel=0.06))
    return [NodeSpec("Mesh_Archway", parts=_bake_parts(parts, dark=0.76))]


# ===========================================================================
# 8. DESERT URN — Sculpted lofted terracotta amphora with curved ear handles
# ===========================================================================
def build_desert_urn() -> List[NodeSpec]:
    profile = [
        (0.00, 0.24), (0.08, 0.20), (0.24, 0.36), (0.48, 0.44),
        (0.70, 0.34), (0.86, 0.21), (1.02, 0.20), (1.10, 0.28), (1.14, 0.24),
    ]
    rings = [squircle_ring((0.0, y, 0.0), r, r, 20, roundness=1.0) for y, r in profile]
    parts: List[MeshPart] = [loft_rings("terracotta", rings, cap_start=True, cap_end=True)]
    for side in (-1.0, 1.0):
        pts = [
            (side * 0.21, 0.96, 0.0),
            (side * 0.44, 0.86, 0.0),
            (side * 0.45, 0.64, 0.0),
            (side * 0.36, 0.50, 0.0),
        ]
        parts.append(curved_tube("terracotta", pts, 0.045, segs=10))
    return [NodeSpec("Mesh_Urn", parts=_bake_parts(parts, dark=0.76))]


# ===========================================================================
# 9. DOG HOUSE + SCULPTED CARTOON PUPPY (_dog + _tail preserved!)
# ===========================================================================
def build_dog_house() -> List[NodeSpec]:
    sx, sy, sz = 2.0, 1.6, 2.2
    house_parts: List[MeshPart] = [
        _box("wood_dark", (sx + 0.18, 0.18, sz + 0.18), pos=(0.0, 0.09, 0.0), bevel=0.04),
        _box("shingle", (sx, sy - 0.16, sz), pos=(0.0, (sy + 0.16) * 0.5, 0.0), bevel=0.05),
        # Dark arched entryway
        _box("steel_dark", (0.94, 0.96, 0.10), pos=(0.0, 0.52, sz * 0.5 + 0.02), bevel=0.04),
        _cyl("steel_dark", 0.47, 0.47, 0.10, pos=(0.0, 0.96, sz * 0.5 + 0.02), rot=(90.0, 0.0, 0.0), bevel=0.02, segs=16),
        # Two pitched roof slabs with warm timber trim
        _box("wood_dark", (1.42, 0.16, sz + 0.42), pos=(-0.60, sy + 0.40, 0.0), rot=(0.0, 0.0,  36.0), bevel=0.04),
        _box("wood_dark", (1.42, 0.16, sz + 0.42), pos=( 0.60, sy + 0.40, 0.0), rot=(0.0, 0.0, -36.0), bevel=0.04),
        _cyl("wood_dark", 0.12, 0.12, sz + 0.44, pos=(0.0, sy + 0.82, 0.0), rot=(90.0, 0.0, 0.0), bevel=0.03, segs=12),
        # Food bowl + colorful foam kibbles
        _cyl("steel", 0.25, 0.22, 0.14, pos=(0.76, 0.07, sz * 0.5 + 0.45), bevel=0.03, segs=16),
        _puff("plastic_orange", 0.07, 0.06, 0.07, pos=(0.80, 0.14, sz * 0.5 + 0.47), rings=6, segs=10),
        _puff("plastic_yellow", 0.07, 0.06, 0.07, pos=(0.71, 0.14, sz * 0.5 + 0.41), rings=6, segs=10),
    ]
    for xs in (-1.0, 1.0):
        for zs in (-1.0, 1.0):
            house_parts.append(_box("wood_dark", (0.16, sy, 0.16), pos=(xs * (sx * 0.5 - 0.05), sy * 0.5, zs * (sz * 0.5 - 0.05)), bevel=0.03))

    # Cute sculpted cartoon puppy (_dog) + wagging _tail!
    dog_parts: List[MeshPart] = [
        _puff("fur", 0.36, 0.34, 0.52, pos=(0.0, 0.30, 0.10), exp=0.92, rings=10, segs=16),
        _puff("fur", 0.29, 0.28, 0.29, pos=(0.0, 0.56, -0.42), exp=0.92, rings=10, segs=16),
        _puff("fur_dark", 0.16, 0.13, 0.16, pos=(0.0, 0.50, -0.66), exp=0.90, rings=8, segs=12),
        _puff("steel_dark", 0.06, 0.05, 0.06, pos=(0.0, 0.56, -0.78), rings=6, segs=10),
        # Cute red collar!
        _cyl("plastic_red", 0.23, 0.23, 0.08, pos=(0.0, 0.42, -0.26), rot=(32.0, 0.0, 0.0), bevel=0.02, segs=16),
    ]
    for side in (-1.0, 1.0):
        dog_parts.append(_puff("steel_dark", 0.048, 0.052, 0.042, pos=(side * 0.11, 0.65, -0.64), rings=6, segs=10))
        dog_parts.append(_puff("steel", 0.017, 0.017, 0.017, pos=(side * 0.11 + 0.012, 0.668, -0.675), rings=5, segs=8))
        dog_parts.append(_place(_puff("fur_dark", 0.08, 0.17, 0.10, exp=0.82, rings=7, segs=10),
                                pos=(side * 0.27, 0.60, -0.40), rot_deg=(15.0, 0.0, side * 24.0)))
        dog_parts.append(_puff("fur", 0.11, 0.08, 0.13, pos=(side * 0.22, 0.08, -0.32), rings=6, segs=10))
        dog_parts.append(_puff("fur", 0.12, 0.08, 0.14, pos=(side * 0.24, 0.08,  0.35), rings=6, segs=10))

    tail_parts = [
        curved_tube("fur_dark", [(0.0, 0.0, 0.0), (0.0, 0.20, 0.09), (0.0, 0.40, 0.22)], 0.058, segs=10),
    ]

    return [
        NodeSpec("Mesh_House", parts=_bake_parts(house_parts, dark=0.74)),
        NodeSpec("_dog", translation=(0.0, 0.0, sz * 0.5 + 0.9), parts=_bake_parts(dog_parts, dark=0.80), children=[
            NodeSpec("_tail", translation=(0.0, 0.42, 0.55), parts=_bake_parts(tail_parts, dark=0.82)),
        ]),
    ]


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(repo_root, "assets", "models", "props")
    builders = {
        "cartoon_tree": build_cartoon_tree,
        "inflatable_barrier": build_inflatable_barrier,
        "inflatable_bunker": build_inflatable_bunker,
        "tactical_crate": build_tactical_crate,
        "tactical_barrel": build_tactical_barrel,
        "playground_slide": build_playground_slide,
        "archway_curved": build_archway_curved,
        "desert_urn": build_desert_urn,
        "dog_house": build_dog_house,
    }
    for name, fn in builders.items():
        nodes = fn()
        export_glb(
            out_path=os.path.join(out_dir, f"{name}.glb"),
            nodes=nodes,
            materials=PROP_MATERIALS,
            root_name=f"Prop_{name}",
        )


if __name__ == "__main__":
    main()
