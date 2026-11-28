#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 — Pure-Python Parametric 3D Sculptor & glTF 2.0 (.glb) Exporter
Uses numpy to build smooth, beveled, Catmull-Clark subdivided, spline-lofted,
vertex-AO-shaded, and multi-bone smooth-skinned stylized cartoon meshes exported
as 100% spec-compliant glTF 2.0 binary (.glb) assets for Godot 4.4.
"""

from __future__ import annotations

import json
import math
import os
import struct
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np


# ---------------------------------------------------------------------------
# Geometry Container
# ---------------------------------------------------------------------------

@dataclass
class MeshPart:
    """One triangulated surface belonging to a named material slot."""
    material: str
    positions: np.ndarray          # (N, 3) float32
    normals: np.ndarray            # (N, 3) float32
    uvs: np.ndarray                # (N, 2) float32
    colors: np.ndarray             # (N, 4) float32 (linear RGBA, carries baked AO)
    indices: np.ndarray            # (M,)   uint32
    joints: Optional[np.ndarray] = None   # (N, 4) uint8
    weights: Optional[np.ndarray] = None  # (N, 4) float32


@dataclass
class MaterialSpec:
    name: str
    color: Tuple[float, float, float, float] = (1.0, 1.0, 1.0, 1.0)
    roughness: float = 0.45
    metallic: float = 0.0
    double_sided: bool = False


@dataclass
class BoneSpec:
    name: str
    parent: int                    # -1 for root
    local_pos: Tuple[float, float, float]


@dataclass
class NodeSpec:
    name: str
    translation: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    rotation: Tuple[float, float, float, float] = (0.0, 0.0, 0.0, 1.0)
    scale: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    parts: List[MeshPart] = field(default_factory=list)
    children: List["NodeSpec"] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Core Math & Normals
# ---------------------------------------------------------------------------

def compute_smooth_normals(verts: np.ndarray, tris: np.ndarray) -> np.ndarray:
    """Area-weighted smooth vertex normals (right-handed CCW outward)."""
    verts = np.asarray(verts, dtype=np.float64)
    tris = np.asarray(tris, dtype=np.int64).reshape(-1, 3)
    v0 = verts[tris[:, 0]]
    v1 = verts[tris[:, 1]]
    v2 = verts[tris[:, 2]]
    fn = np.cross(v1 - v0, v2 - v0)
    norms = np.zeros_like(verts)
    np.add.at(norms, tris[:, 0], fn)
    np.add.at(norms, tris[:, 1], fn)
    np.add.at(norms, tris[:, 2], fn)
    lens = np.linalg.norm(norms, axis=1, keepdims=True)
    lens = np.where(lens < 1e-8, 1.0, lens)
    return (norms / lens).astype(np.float32)


def ensure_outward_winding(verts: np.ndarray, tris: np.ndarray, center: Optional[np.ndarray] = None) -> np.ndarray:
    """Verify closed mesh signed volume > 0 (CCW outward); flip if inverted."""
    tris = np.asarray(tris, dtype=np.uint32).reshape(-1, 3)
    v = np.asarray(verts, dtype=np.float64)
    if center is None:
        center = v.mean(axis=0)
    v0 = v[tris[:, 0]] - center
    v1 = v[tris[:, 1]] - center
    v2 = v[tris[:, 2]] - center
    vol6 = np.sum(np.einsum("ij,ij->i", v0, np.cross(v1, v2)))
    if vol6 < 0.0:
        tris = tris[:, [0, 2, 1]]
    return tris.reshape(-1)


def quads_to_tris(quads: np.ndarray) -> np.ndarray:
    q = np.asarray(quads, dtype=np.uint32).reshape(-1, 4)
    t1 = q[:, [0, 1, 2]]
    t2 = q[:, [0, 2, 3]]
    return np.concatenate([t1, t2], axis=0).reshape(-1)


def rot_matrix_deg(rx: float = 0.0, ry: float = 0.0, rz: float = 0.0) -> np.ndarray:
    ax, ay, az = math.radians(rx), math.radians(ry), math.radians(rz)
    cx, sx = math.cos(ax), math.sin(ax)
    cy, sy = math.cos(ay), math.sin(ay)
    cz, sz = math.cos(az), math.sin(az)
    mx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]], dtype=np.float64)
    my = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]], dtype=np.float64)
    mz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]], dtype=np.float64)
    return mz @ my @ mx


def transform_part(part: MeshPart, pos=(0.0, 0.0, 0.0), rot_deg=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)) -> MeshPart:
    s = np.asarray(scale, dtype=np.float64)
    r = rot_matrix_deg(*rot_deg)
    t = np.asarray(pos, dtype=np.float64)
    new_pos = (part.positions.astype(np.float64) * s) @ r.T + t
    inv_s = np.where(np.abs(s) < 1e-6, 1.0, 1.0 / s)
    new_nrm = (part.normals.astype(np.float64) * inv_s) @ r.T
    nl = np.linalg.norm(new_nrm, axis=1, keepdims=True)
    new_nrm = new_nrm / np.where(nl < 1e-8, 1.0, nl)
    idx = part.indices.copy()
    if s[0] * s[1] * s[2] < 0.0:
        idx = idx.reshape(-1, 3)[:, [0, 2, 1]].reshape(-1)
    return MeshPart(
        material=part.material,
        positions=new_pos.astype(np.float32),
        normals=new_nrm.astype(np.float32),
        uvs=part.uvs.copy(),
        colors=part.colors.copy(),
        indices=idx,
        joints=None if part.joints is None else part.joints.copy(),
        weights=None if part.weights is None else part.weights.copy(),
    )


def merge_parts(parts: Sequence[MeshPart], material: Optional[str] = None) -> MeshPart:
    """Combine multiple MeshParts into one single surface."""
    assert len(parts) > 0
    mat = material if material is not None else parts[0].material
    pos_list, nrm_list, uv_list, col_list, idx_list = [], [], [], [], []
    j_list, w_list = [], []
    has_skin = any(p.joints is not None for p in parts)
    offset = 0
    for p in parts:
        n = len(p.positions)
        pos_list.append(p.positions.astype(np.float32))
        nrm_list.append(p.normals.astype(np.float32))
        uv_list.append(p.uvs.astype(np.float32))
        col_list.append(p.colors.astype(np.float32))
        idx_list.append(p.indices.astype(np.uint32) + offset)
        if has_skin:
            if p.joints is not None:
                j_list.append(p.joints.astype(np.uint8))
                w_list.append(p.weights.astype(np.float32))
            else:
                j_list.append(np.zeros((n, 4), dtype=np.uint8))
                w = np.zeros((n, 4), dtype=np.float32)
                w[:, 0] = 1.0
                w_list.append(w)
        offset += n
    return MeshPart(
        material=mat,
        positions=np.concatenate(pos_list, axis=0),
        normals=np.concatenate(nrm_list, axis=0),
        uvs=np.concatenate(uv_list, axis=0),
        colors=np.concatenate(col_list, axis=0),
        indices=np.concatenate(idx_list, axis=0),
        joints=np.concatenate(j_list, axis=0) if has_skin else None,
        weights=np.concatenate(w_list, axis=0) if has_skin else None,
    )


def merge_by_material(parts: Sequence[MeshPart]) -> List[MeshPart]:
    """Group MeshParts by material name (preserving insertion order)."""
    buckets: Dict[str, List[MeshPart]] = {}
    for p in parts:
        buckets.setdefault(p.material, []).append(p)
    return [merge_parts(group, mat) for mat, group in buckets.items()]


# ---------------------------------------------------------------------------
# Catmull-Clark Subdivision Surface
# ---------------------------------------------------------------------------

def catmull_clark(verts: np.ndarray, quads: np.ndarray, levels: int = 1) -> Tuple[np.ndarray, np.ndarray]:
    """Subdivide a closed quad mesh with exact Catmull-Clark smoothing."""
    v = np.asarray(verts, dtype=np.float64)
    q = np.asarray(quads, dtype=np.int64).reshape(-1, 4)

    for _ in range(levels):
        n_v = len(v)
        n_f = len(q)
        face_pts = v[q].mean(axis=1)  # (n_f, 3)

        # Build edge -> incident faces map
        edge_faces: Dict[Tuple[int, int], List[int]] = {}
        vert_faces: List[List[int]] = [[] for _ in range(n_v)]
        vert_edges: List[set] = [set() for _ in range(n_v)]

        for fi in range(n_f):
            f = q[fi]
            for k in range(4):
                a, b = int(f[k]), int(f[(k + 1) % 4])
                vert_faces[a].append(fi)
                ek = (a, b) if a < b else (b, a)
                edge_faces.setdefault(ek, []).append(fi)
                vert_edges[a].add(ek)
                vert_edges[b].add(ek)

        edge_list = list(edge_faces.keys())
        edge_idx = {ek: i for i, ek in enumerate(edge_list)}
        edge_pts = np.zeros((len(edge_list), 3), dtype=np.float64)
        for i, (a, b) in enumerate(edge_list):
            inc = edge_faces[(a, b)]
            if len(inc) == 2:
                edge_pts[i] = 0.25 * (v[a] + v[b] + face_pts[inc[0]] + face_pts[inc[1]])
            else:
                edge_pts[i] = 0.5 * (v[a] + v[b])

        new_v = np.zeros_like(v)
        for vi in range(n_v):
            inc_f = vert_faces[vi]
            inc_e = list(vert_edges[vi])
            boundary_e = [ek for ek in inc_e if len(edge_faces[ek]) < 2]
            if boundary_e:
                mids = [0.5 * (v[a] + v[b]) for a, b in boundary_e]
                new_v[vi] = 0.5 * v[vi] + 0.5 * np.mean(mids, axis=0)
            else:
                n = float(len(inc_f))
                if n < 3.0:
                    new_v[vi] = v[vi]
                else:
                    avg_f = face_pts[inc_f].mean(axis=0)
                    avg_r = np.mean([0.5 * (v[a] + v[b]) for a, b in inc_e], axis=0)
                    new_v[vi] = (avg_f + 2.0 * avg_r + (n - 3.0) * v[vi]) / n

        f_offset = n_v
        e_offset = n_v + n_f
        all_v = np.concatenate([new_v, face_pts, edge_pts], axis=0)

        new_q = np.zeros((n_f * 4, 4), dtype=np.int64)
        for fi in range(n_f):
            f = q[fi]
            fp = f_offset + fi
            es = []
            for k in range(4):
                a, b = int(f[k]), int(f[(k + 1) % 4])
                ek = (a, b) if a < b else (b, a)
                es.append(e_offset + edge_idx[ek])
            for k in range(4):
                new_q[fi * 4 + k] = [f[k], es[k], fp, es[(k - 1) % 4]]

        v = all_v
        q = new_q

    return v, q


# ---------------------------------------------------------------------------
# Stylized Sculpting Primitives
# ---------------------------------------------------------------------------

def _default_colors(n: int, col=(1.0, 1.0, 1.0, 1.0)) -> np.ndarray:
    arr = np.empty((n, 4), dtype=np.float32)
    arr[:] = col
    return arr


def superellipsoid(
    material: str,
    rx: float,
    ry: float,
    rz: float,
    e1: float = 0.85,
    e2: float = 0.85,
    segs_u: int = 20,
    segs_v: int = 14,
    grad_top: float = 1.04,
    grad_bot: float = 0.86,
) -> MeshPart:
    """
    Smooth superellipsoid:
      e1=e2=1.0 -> perfect sphere
      e1=e2=0.45 -> chunky Pixar rounded toy box / cushion
      e1=0.6, e2=0.9 -> rounded cylinder / hoodie torso / sneaker
    """
    def spow(x: np.ndarray, p: float) -> np.ndarray:
        return np.sign(x) * (np.abs(x) ** p)

    us = np.linspace(0.0, 2.0 * math.pi, segs_u, endpoint=False)
    vs = np.linspace(-0.5 * math.pi + 1e-3, 0.5 * math.pi - 1e-3, segs_v)

    rings = []
    uvs = []
    for iv, phi in enumerate(vs):
        cphi = math.cos(phi)
        sphi = math.sin(phi)
        y = ry * (1.0 if sphi >= 0 else -1.0) * (abs(sphi) ** e1)
        rc = (abs(cphi) ** e1)
        ring = np.zeros((segs_u, 3), dtype=np.float64)
        ring[:, 0] = rx * rc * spow(np.cos(us), e2)
        ring[:, 1] = y
        ring[:, 2] = rz * rc * spow(np.sin(us), e2)
        rings.append(ring)
        v_coord = iv / max(segs_v - 1, 1)
        for iu in range(segs_u):
            uvs.append([iu / segs_u, v_coord])

    verts = np.vstack(rings)
    bot_idx = len(verts)
    top_idx = bot_idx + 1
    verts = np.vstack([verts, [[0.0, -ry, 0.0], [0.0, ry, 0.0]]])
    uvs.extend([[0.5, 0.0], [0.5, 1.0]])

    tris = []
    for iv in range(segs_v - 1):
        r0 = iv * segs_u
        r1 = (iv + 1) * segs_u
        for iu in range(segs_u):
            iu2 = (iu + 1) % segs_u
            a, b, c, d = r0 + iu, r0 + iu2, r1 + iu2, r1 + iu
            tris.extend([a, d, c, a, c, b])
    # Caps
    for iu in range(segs_u):
        iu2 = (iu + 1) % segs_u
        tris.extend([bot_idx, iu, iu2])
        last_r = (segs_v - 1) * segs_u
        tris.extend([top_idx, last_r + iu2, last_r + iu])

    idx = ensure_outward_winding(verts, np.array(tris, dtype=np.uint32))
    nrms = compute_smooth_normals(verts, idx)
    t_y = np.clip((verts[:, 1] + ry) / max(2.0 * ry, 1e-5), 0.0, 1.0)
    shade = grad_bot + (grad_top - grad_bot) * t_y
    cols = np.ones((len(verts), 4), dtype=np.float32)
    cols[:, :3] = shade[:, None]
    return MeshPart(
        material=material,
        positions=verts.astype(np.float32),
        normals=nrms,
        uvs=np.asarray(uvs, dtype=np.float32),
        colors=cols,
        indices=idx,
    )


def loft_rings(
    material: str,
    rings: Sequence[np.ndarray],
    cap_start: bool = True,
    cap_end: bool = True,
    subdiv_levels: int = 0,
    grad_top: float = 1.04,
    grad_bot: float = 0.88,
) -> MeshPart:
    """
    Loft a smooth watertight mesh through a list of 3D cross-section rings,
    each shaped (S, 3) with consistent cyclic ordering.
    """
    ring_arr = [np.asarray(r, dtype=np.float64) for r in rings]
    n_rings = len(ring_arr)
    segs = len(ring_arr[0])

    verts = np.vstack(ring_arr)
    quads = []
    for ir in range(n_rings - 1):
        r0 = ir * segs
        r1 = (ir + 1) * segs
        for iu in range(segs):
            iu2 = (iu + 1) % segs
            quads.append([r0 + iu, r0 + iu2, r1 + iu2, r1 + iu])

    if subdiv_levels > 0:
        # Close ends smoothly with quad-friendly inset rings before Catmull-Clark
        verts_work = verts
        quads_arr = np.array(quads, dtype=np.int64)
        verts_s, quads_s = catmull_clark(verts_work, quads_arr, levels=subdiv_levels)
        tris_list = list(quads_to_tris(quads_s))
        verts = verts_s
        # Simple center-fan caps on boundary loops if requested
        if cap_start or cap_end:
            # Find boundary edges after subdiv
            edge_cnt: Dict[Tuple[int, int], int] = {}
            for q in quads_s:
                for k in range(4):
                    a, b = int(q[k]), int(q[(k + 1) % 4])
                    ek = (a, b) if a < b else (b, a)
                    edge_cnt[ek] = edge_cnt.get(ek, 0) + 1
            b_edges = []
            for q in quads_s:
                for k in range(4):
                    a, b = int(q[k]), int(q[(k + 1) % 4])
                    ek = (a, b) if a < b else (b, a)
                    if edge_cnt[ek] == 1:
                        b_edges.append((a, b))
            # Partition boundary into loops
            nxt = {a: b for a, b in b_edges}
            visited = set()
            loops = []
            for a, _ in b_edges:
                if a in visited:
                    continue
                loop = []
                cur = a
                while cur not in visited and cur in nxt:
                    visited.add(cur)
                    loop.append(cur)
                    cur = nxt[cur]
                if len(loop) >= 3:
                    loops.append(loop)
            for loop in loops:
                c_pt = verts[loop].mean(axis=0)
                c_idx = len(verts)
                verts = np.vstack([verts, [c_pt]])
                for i in range(len(loop)):
                    tris_list.extend([c_idx, loop[(i + 1) % len(loop)], loop[i]])
        idx = ensure_outward_winding(verts, np.array(tris_list, dtype=np.uint32))
    else:
        tris_list = list(quads_to_tris(np.array(quads, dtype=np.uint32)))
        if cap_start:
            c0 = ring_arr[0].mean(axis=0)
            c0_idx = len(verts)
            verts = np.vstack([verts, [c0]])
            for iu in range(segs):
                iu2 = (iu + 1) % segs
                tris_list.extend([c0_idx, iu2, iu])
        if cap_end:
            c1 = ring_arr[-1].mean(axis=0)
            c1_idx = len(verts)
            verts = np.vstack([verts, [c1]])
            base = (n_rings - 1) * segs
            for iu in range(segs):
                iu2 = (iu + 1) % segs
                tris_list.extend([c1_idx, base + iu, base + iu2])
        idx = ensure_outward_winding(verts, np.array(tris_list, dtype=np.uint32))

    nrms = compute_smooth_normals(verts, idx)
    # Cylindrical UVs
    ymin, ymax = verts[:, 1].min(), verts[:, 1].max()
    ang = np.arctan2(verts[:, 2], verts[:, 0]) / (2.0 * math.pi) + 0.5
    v_uv = (verts[:, 1] - ymin) / max(ymax - ymin, 1e-5)
    uvs = np.stack([ang, v_uv], axis=1).astype(np.float32)

    shade = grad_bot + (grad_top - grad_bot) * np.clip(v_uv, 0.0, 1.0)
    cols = np.ones((len(verts), 4), dtype=np.float32)
    cols[:, :3] = shade[:, None]
    return MeshPart(
        material=material,
        positions=verts.astype(np.float32),
        normals=nrms,
        uvs=uvs,
        colors=cols,
        indices=idx,
    )


def squircle_ring(
    center: Tuple[float, float, float],
    rx: float,
    rz: float,
    segs: int = 20,
    roundness: float = 0.75,
    tilt_x_deg: float = 0.0,
    tilt_z_deg: float = 0.0,
) -> np.ndarray:
    """Horizontal cross-section ring (superellipse) ready for loft_rings."""
    us = np.linspace(0.0, 2.0 * math.pi, segs, endpoint=False)
    ca, sa = np.cos(us), np.sin(us)
    pts = np.zeros((segs, 3), dtype=np.float64)
    pts[:, 0] = rx * np.sign(ca) * (np.abs(ca) ** roundness)
    pts[:, 2] = rz * np.sign(sa) * (np.abs(sa) ** roundness)
    if abs(tilt_x_deg) > 1e-4 or abs(tilt_z_deg) > 1e-4:
        r = rot_matrix_deg(tilt_x_deg, 0.0, tilt_z_deg)
        pts = pts @ r.T
    pts += np.asarray(center, dtype=np.float64)
    return pts


def rounded_box(
    material: str,
    size: Tuple[float, float, float],
    bevel: float = 0.02,
    segs: int = 16,
    roundness: float = 0.45,
) -> MeshPart:
    """Chunky blow-molded beveled toy box (replaces sharp 90-degree cuboids)."""
    sx, sy, sz = size
    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
    b = min(bevel, hx * 0.48, hy * 0.48, hz * 0.48)
    rings = [
        squircle_ring((0.0, -hy, 0.0), max(hx - b, 1e-4), max(hz - b, 1e-4), segs, roundness),
        squircle_ring((0.0, -hy + b * 0.45, 0.0), max(hx - b * 0.25, 1e-4), max(hz - b * 0.25, 1e-4), segs, roundness),
        squircle_ring((0.0, -hy + b, 0.0), hx, hz, segs, roundness),
        squircle_ring((0.0, hy - b, 0.0), hx, hz, segs, roundness),
        squircle_ring((0.0, hy - b * 0.45, 0.0), max(hx - b * 0.25, 1e-4), max(hz - b * 0.25, 1e-4), segs, roundness),
        squircle_ring((0.0, hy, 0.0), max(hx - b, 1e-4), max(hz - b, 1e-4), segs, roundness),
    ]
    return loft_rings(material, rings, cap_start=True, cap_end=True)


def beveled_cylinder(
    material: str,
    r_bot: float,
    r_top: float,
    height: float,
    bevel: float = 0.012,
    segs: int = 20,
) -> MeshPart:
    """Smooth toy cylinder with beveled top/bottom rims."""
    hy = height * 0.5
    b = min(bevel, height * 0.25, r_bot * 0.4, r_top * 0.4)
    rings = [
        squircle_ring((0.0, -hy, 0.0), max(r_bot - b, 1e-4), max(r_bot - b, 1e-4), segs, 1.0),
        squircle_ring((0.0, -hy + b * 0.5, 0.0), max(r_bot - b * 0.2, 1e-4), max(r_bot - b * 0.2, 1e-4), segs, 1.0),
        squircle_ring((0.0, -hy + b, 0.0), r_bot, r_bot, segs, 1.0),
        squircle_ring((0.0, hy - b, 0.0), r_top, r_top, segs, 1.0),
        squircle_ring((0.0, hy - b * 0.5, 0.0), max(r_top - b * 0.2, 1e-4), max(r_top - b * 0.2, 1e-4), segs, 1.0),
        squircle_ring((0.0, hy, 0.0), max(r_top - b, 1e-4), max(r_top - b, 1e-4), segs, 1.0),
    ]
    return loft_rings(material, rings, cap_start=True, cap_end=True)


def curved_tube(
    material: str,
    points: Sequence[Tuple[float, float, float]],
    radii: Sequence[float] | float,
    segs: int = 12,
    cap_start: bool = True,
    cap_end: bool = True,
    roundness: float = 1.0,
) -> MeshPart:
    """Sweep a circular/squircle cross-section along an arbitrary 3D polyline using parallel transport."""
    pts = np.asarray(points, dtype=np.float64)
    n_p = len(pts)
    if isinstance(radii, (int, float)):
        r_arr = np.full(n_p, float(radii), dtype=np.float64)
    else:
        r_arr = np.asarray(radii, dtype=np.float64)

    tangents = np.zeros_like(pts)
    for i in range(n_p):
        if i == 0:
            t = pts[1] - pts[0]
        elif i == n_p - 1:
            t = pts[-1] - pts[-2]
        else:
            t = pts[i + 1] - pts[i - 1]
        tl = np.linalg.norm(t)
        tangents[i] = t / (tl if tl > 1e-8 else 1.0)

    # Parallel transport frame
    ref = np.array([0.0, 1.0, 0.0]) if abs(tangents[0, 1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    n_vec = np.cross(tangents[0], ref)
    n_vec /= max(np.linalg.norm(n_vec), 1e-8)
    b_vec = np.cross(tangents[0], n_vec)

    us = np.linspace(0.0, 2.0 * math.pi, segs, endpoint=False)
    ca = np.sign(np.cos(us)) * (np.abs(np.cos(us)) ** roundness)
    sa = np.sign(np.sin(us)) * (np.abs(np.sin(us)) ** roundness)

    rings = []
    for i in range(n_p):
        if i > 0:
            t_prev = tangents[i - 1]
            t_cur = tangents[i]
            axis = np.cross(t_prev, t_cur)
            al = np.linalg.norm(axis)
            if al > 1e-6:
                axis /= al
                ang = math.acos(float(np.clip(np.dot(t_prev, t_cur), -1.0, 1.0)))
                # Rodrigues rotation
                c, s = math.cos(ang), math.sin(ang)
                n_vec = n_vec * c + np.cross(axis, n_vec) * s + axis * np.dot(axis, n_vec) * (1.0 - c)
                n_vec /= max(np.linalg.norm(n_vec), 1e-8)
            b_vec = np.cross(t_cur, n_vec)
            b_vec /= max(np.linalg.norm(b_vec), 1e-8)
        r = r_arr[i]
        ring = pts[i] + r * (ca[:, None] * n_vec[None, :] + sa[:, None] * b_vec[None, :])
        rings.append(ring)

    return loft_rings(material, rings, cap_start=cap_start, cap_end=cap_end)


def bake_ao_cavity(part: MeshPart, ao_points: Sequence[Tuple[Tuple[float, float, float], float, float]]) -> MeshPart:
    """Darken vertex colors softly near crease/cavity anchor points (pos, radius, strength)."""
    cols = part.colors.copy()
    v = part.positions.astype(np.float64)
    for center, radius, strength in ao_points:
        c = np.asarray(center, dtype=np.float64)
        d = np.linalg.norm(v - c, axis=1)
        t = np.clip(1.0 - d / max(radius, 1e-5), 0.0, 1.0)
        factor = 1.0 - (t * t) * strength
        cols[:, :3] *= factor[:, None].astype(np.float32)
    cols[:, :3] = np.clip(cols[:, :3], 0.55, 1.15)
    return MeshPart(
        material=part.material,
        positions=part.positions,
        normals=part.normals,
        uvs=part.uvs,
        colors=cols,
        indices=part.indices,
        joints=part.joints,
        weights=part.weights,
    )


# ---------------------------------------------------------------------------
# Smooth Multi-Bone Skinning
# ---------------------------------------------------------------------------

def assign_rigid_bone(part: MeshPart, bone_idx: int) -> MeshPart:
    n = len(part.positions)
    joints = np.zeros((n, 4), dtype=np.uint8)
    weights = np.zeros((n, 4), dtype=np.float32)
    joints[:, 0] = bone_idx
    weights[:, 0] = 1.0
    return MeshPart(
        material=part.material,
        positions=part.positions,
        normals=part.normals,
        uvs=part.uvs,
        colors=part.colors,
        indices=part.indices,
        joints=joints,
        weights=weights,
    )


def assign_smooth_bone_segments(
    part: MeshPart,
    segments: Sequence[Tuple[int, Tuple[float, float, float], Tuple[float, float, float], float]],
    falloff_power: float = 3.2,
) -> MeshPart:
    """
    Smooth multi-bone capsule-distance skinning.
    Each segment is (bone_idx, start_xyz, end_xyz, influence_radius).
    Produces up to 4 normalized bone weights per vertex for seamless limb bending.
    """
    v = part.positions.astype(np.float64)
    n = len(v)
    k = len(segments)
    raw_w = np.zeros((n, k), dtype=np.float64)
    bone_ids = np.array([s[0] for s in segments], dtype=np.uint8)

    for si, (_, p0, p1, rad) in enumerate(segments):
        a = np.asarray(p0, dtype=np.float64)
        b = np.asarray(p1, dtype=np.float64)
        ab = b - a
        ab_len2 = float(np.dot(ab, ab))
        if ab_len2 < 1e-10:
            dist = np.linalg.norm(v - a, axis=1)
        else:
            t = np.clip(np.einsum("ij,j->i", v - a, ab) / ab_len2, 0.0, 1.0)
            proj = a + t[:, None] * ab[None, :]
            dist = np.linalg.norm(v - proj, axis=1)
        raw_w[:, si] = 1.0 / ((dist / max(rad, 1e-4) + 0.08) ** falloff_power)

    # Pick top 4 segments per vertex and merge weights if duplicate bone indices exist
    joints = np.zeros((n, 4), dtype=np.uint8)
    weights = np.zeros((n, 4), dtype=np.float32)
    top_k = min(4, k)
    order = np.argsort(-raw_w, axis=1)[:, :top_k]
    for vi in range(n):
        acc: Dict[int, float] = {}
        for slot in range(top_k):
            si = int(order[vi, slot])
            bi = int(bone_ids[si])
            acc[bi] = acc.get(bi, 0.0) + float(raw_w[vi, si])
        items = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
        total = sum(w for _, w in items)
        if total <= 1e-12:
            joints[vi, 0] = bone_ids[0]
            weights[vi, 0] = 1.0
        else:
            for slot, (bi, w) in enumerate(items):
                joints[vi, slot] = bi
                weights[vi, slot] = w / total

    return MeshPart(
        material=part.material,
        positions=part.positions,
        normals=part.normals,
        uvs=part.uvs,
        colors=part.colors,
        indices=part.indices,
        joints=joints,
        weights=weights,
    )


# ---------------------------------------------------------------------------
# Spec-Compliant glTF 2.0 (.glb) Binary Exporter
# ---------------------------------------------------------------------------

def export_glb(
    out_path: str,
    nodes: Sequence[NodeSpec],
    materials: Sequence[MaterialSpec],
    bones: Optional[Sequence[BoneSpec]] = None,
    skinned_root_parts: Optional[Sequence[MeshPart]] = None,
    skinned_mesh_name: str = "HeroBodyMesh",
    root_name: str = "RootNode",
) -> None:
    """Write a complete glTF 2.0 binary (.glb) file ready for Godot 4.4 import."""
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)

    buf = bytearray()
    buffer_views: List[dict] = []
    accessors: List[dict] = []
    gltf_materials: List[dict] = []
    mat_idx_map: Dict[str, int] = {}

    for m in materials:
        mat_idx_map[m.name] = len(gltf_materials)
        gltf_materials.append({
            "name": m.name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [float(c) for c in m.color],
                "metallicFactor": float(m.metallic),
                "roughnessFactor": float(m.roughness),
            },
            "doubleSided": bool(m.double_sided),
        })

    def add_bytes(raw: bytes, target: Optional[int] = None) -> int:
        while len(buf) % 4 != 0:
            buf.append(0)
        offset = len(buf)
        buf.extend(raw)
        bv = {"buffer": 0, "byteOffset": offset, "byteLength": len(raw)}
        if target is not None:
            bv["target"] = target
        idx = len(buffer_views)
        buffer_views.append(bv)
        return idx

    def add_accessor(
        arr: np.ndarray,
        component_type: int,
        acc_type: str,
        target: Optional[int] = None,
        with_minmax: bool = False,
    ) -> int:
        raw = np.ascontiguousarray(arr).tobytes()
        bv = add_bytes(raw, target=target)
        acc = {
            "bufferView": bv,
            "componentType": component_type,
            "count": int(len(arr)),
            "type": acc_type,
        }
        if with_minmax and len(arr) > 0:
            acc["min"] = [float(x) for x in arr.min(axis=0)]
            acc["max"] = [float(x) for x in arr.max(axis=0)]
        idx = len(accessors)
        accessors.append(acc)
        return idx

    gltf_meshes: List[dict] = []

    def add_mesh_from_parts(mesh_name: str, parts: Sequence[MeshPart], skinned: bool = False) -> int:
        primitives = []
        for p in parts:
            if p.material not in mat_idx_map:
                mat_idx_map[p.material] = len(gltf_materials)
                gltf_materials.append({
                    "name": p.material,
                    "pbrMetallicRoughness": {
                        "baseColorFactor": [1.0, 1.0, 1.0, 1.0],
                        "metallicFactor": 0.0,
                        "roughnessFactor": 0.45,
                    },
                })
            pos_acc = add_accessor(p.positions.astype(np.float32), 5126, "VEC3", target=34962, with_minmax=True)
            nrm_acc = add_accessor(p.normals.astype(np.float32), 5126, "VEC3", target=34962)
            uv_acc = add_accessor(p.uvs.astype(np.float32), 5126, "VEC2", target=34962)
            col_acc = add_accessor(p.colors.astype(np.float32), 5126, "VEC4", target=34962)
            attrs = {
                "POSITION": pos_acc,
                "NORMAL": nrm_acc,
                "TEXCOORD_0": uv_acc,
                "COLOR_0": col_acc,
            }
            if skinned:
                j = p.joints if p.joints is not None else np.zeros((len(p.positions), 4), dtype=np.uint8)
                w = p.weights if p.weights is not None else np.tile(np.array([1, 0, 0, 0], dtype=np.float32), (len(p.positions), 1))
                attrs["JOINTS_0"] = add_accessor(j.astype(np.uint8), 5121, "VEC4", target=34962)
                attrs["WEIGHTS_0"] = add_accessor(w.astype(np.float32), 5126, "VEC4", target=34962)
            idx_u32 = p.indices.astype(np.uint32)
            if len(p.positions) < 65535:
                idx_acc = add_accessor(idx_u32.astype(np.uint16), 5123, "SCALAR", target=34963)
            else:
                idx_acc = add_accessor(idx_u32, 5125, "SCALAR", target=34963)
            primitives.append({
                "attributes": attrs,
                "indices": idx_acc,
                "material": mat_idx_map[p.material],
            })
        m_idx = len(gltf_meshes)
        gltf_meshes.append({"name": mesh_name, "primitives": primitives})
        return m_idx

    gltf_nodes: List[dict] = []
    gltf_skins: List[dict] = []
    scene_root_children: List[int] = []

    # 1. Optional Skeleton + Skinned Mesh
    if bones:
        bone_node_indices: List[int] = []
        world_pos = [np.zeros(3, dtype=np.float64) for _ in bones]
        for bi, b in enumerate(bones):
            if b.parent >= 0:
                world_pos[bi] = world_pos[b.parent] + np.asarray(b.local_pos, dtype=np.float64)
            else:
                world_pos[bi] = np.asarray(b.local_pos, dtype=np.float64)
            ni = len(gltf_nodes)
            bone_node_indices.append(ni)
            gltf_nodes.append({
                "name": b.name,
                "translation": [float(x) for x in b.local_pos],
            })
        for bi, b in enumerate(bones):
            ni = bone_node_indices[bi]
            if b.parent >= 0:
                p_ni = bone_node_indices[b.parent]
                gltf_nodes[p_ni].setdefault("children", []).append(ni)
            else:
                scene_root_children.append(ni)

        # Inverse bind matrices (column-major 4x4 translation -world_pos)
        ibms = np.zeros((len(bones), 16), dtype=np.float32)
        for bi, wp in enumerate(world_pos):
            ibms[bi] = [
                1.0, 0.0, 0.0, 0.0,
                0.0, 1.0, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                float(-wp[0]), float(-wp[1]), float(-wp[2]), 1.0,
            ]
        ibm_acc = add_accessor(ibms, 5126, "MAT4")
        gltf_skins.append({
            "name": "GeneralSkeleton",
            "inverseBindMatrices": ibm_acc,
            "joints": bone_node_indices,
            "skeleton": bone_node_indices[0],
        })

        if skinned_root_parts:
            sm_idx = add_mesh_from_parts(skinned_mesh_name, skinned_root_parts, skinned=True)
            sm_node_idx = len(gltf_nodes)
            gltf_nodes.append({
                "name": skinned_mesh_name,
                "mesh": sm_idx,
                "skin": 0,
            })
            scene_root_children.append(sm_node_idx)

    # 2. Regular Hierarchy Nodes (Blasters, Props, Expression Submeshes, Markers)
    def build_node(spec: NodeSpec) -> int:
        nd: dict = {"name": spec.name}
        if spec.translation != (0.0, 0.0, 0.0):
            nd["translation"] = [float(x) for x in spec.translation]
        if spec.rotation != (0.0, 0.0, 0.0, 1.0):
            nd["rotation"] = [float(x) for x in spec.rotation]
        if spec.scale != (1.0, 1.0, 1.0):
            nd["scale"] = [float(x) for x in spec.scale]
        if spec.parts:
            nd["mesh"] = add_mesh_from_parts(spec.name, spec.parts, skinned=False)
        ni = len(gltf_nodes)
        gltf_nodes.append(nd)
        child_ids = [build_node(c) for c in spec.children]
        if child_ids:
            gltf_nodes[ni]["children"] = child_ids
        return ni

    for top in nodes:
        scene_root_children.append(build_node(top))

    # Wrap cleanly under a single root node so Godot imports one tidy tree
    root_idx = len(gltf_nodes)
    gltf_nodes.append({
        "name": root_name,
        "children": scene_root_children,
    })

    while len(buf) % 4 != 0:
        buf.append(0)

    gltf_doc = {
        "asset": {"version": "2.0", "generator": "DARTSTORM Sculptor v2.0"},
        "scene": 0,
        "scenes": [{"name": root_name, "nodes": [root_idx]}],
        "nodes": gltf_nodes,
        "materials": gltf_materials,
        "meshes": gltf_meshes,
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(buf)}],
    }
    if gltf_skins:
        gltf_doc["skins"] = gltf_skins

    json_bytes = json.dumps(gltf_doc, separators=(",", ":")).encode("utf-8")
    while len(json_bytes) % 4 != 0:
        json_bytes += b" "

    total_len = 12 + 8 + len(json_bytes) + 8 + len(buf)
    with open(out_path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total_len))
        f.write(struct.pack("<II", len(json_bytes), 0x4E4F534A))
        f.write(json_bytes)
        f.write(struct.pack("<II", len(buf), 0x004E4942))
        f.write(buf)

    total_tris = sum(len(p.indices) // 3 for p in (skinned_root_parts or []))
    def _count_node_tris(ns: NodeSpec) -> int:
        return sum(len(p.indices) // 3 for p in ns.parts) + sum(_count_node_tris(c) for c in ns.children)
    total_tris += sum(_count_node_tris(n) for n in nodes)
    print(f"Exported {out_path} ({total_len // 1024} KB, {total_tris} tris)")
