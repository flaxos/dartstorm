#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 — Pixar / Fortnite Stylized PBR Texture Suite Generator
Generates seamless 512x512 / 1024x1024 painterly-stylized albedo, tangent-space
normal, and ORM maps under assets/textures/stylized/ using pure NumPy + Pillow.
"""

from __future__ import annotations

import math
import os
import numpy as np
from PIL import Image


def _tileable_fbm(size: int, base_freqs=(4, 8, 16, 32), weights=(0.5, 0.25, 0.15, 0.10), seed: int = 42) -> np.ndarray:
    """Fast tileable periodic multi-octave value noise in [0, 1]."""
    rng = np.random.default_rng(seed)
    out = np.zeros((size, size), dtype=np.float32)
    ys = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    xs = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)

    for freq, w in zip(base_freqs, weights):
        grid = rng.random((freq, freq), dtype=np.float32)
        fx = gx * freq
        fy = gy * freq
        ix0 = np.floor(fx).astype(np.int32) % freq
        iy0 = np.floor(fy).astype(np.int32) % freq
        ix1 = (ix0 + 1) % freq
        iy1 = (iy0 + 1) % freq
        tx = fx - np.floor(fx)
        ty = fy - np.floor(fy)
        # Quintic smoothstep
        ux = tx * tx * tx * (tx * (tx * 6.0 - 15.0) + 10.0)
        uy = ty * ty * ty * (ty * (ty * 6.0 - 15.0) + 10.0)
        v00 = grid[iy0, ix0]
        v10 = grid[iy0, ix1]
        v01 = grid[iy1, ix0]
        v11 = grid[iy1, ix1]
        v0 = v00 * (1.0 - ux) + v10 * ux
        v1 = v01 * (1.0 - ux) + v11 * ux
        out += (v0 * (1.0 - uy) + v1 * uy) * w

    lo, hi = float(out.min()), float(out.max())
    return (out - lo) / max(hi - lo, 1e-6)


def _height_to_normal(height: np.ndarray, strength: float = 3.0) -> np.ndarray:
    """Convert periodic heightmap in [0, 1] to OpenGL tangent-space RGB normal map."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5 * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5 * strength
    nx = -dx
    ny = -dy
    nz = np.ones_like(height)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz + 1e-8)
    rgb = np.stack([nx * inv * 0.5 + 0.5, ny * inv * 0.5 + 0.5, nz * inv * 0.5 + 0.5], axis=-1)
    return np.clip(rgb * 255.0, 0.0, 255.0).astype(np.uint8)


def _save_rgb(path: str, arr: np.ndarray) -> None:
    if arr.dtype != np.uint8:
        arr = np.clip(arr * 255.0, 0.0, 255.0).astype(np.uint8)
    Image.fromarray(arr, mode="RGB").save(path, optimize=True)


# ---------------------------------------------------------------------------
# 1. Painterly Stylized Oak Foliage Leaf Clusters (Albedo + Normal)
# ---------------------------------------------------------------------------
def gen_foliage(out_dir: str, size: int = 512) -> None:
    rng = np.random.default_rng(101)
    height = np.zeros((size, size), dtype=np.float32)
    albedo = np.zeros((size, size, 3), dtype=np.float32)
    # Deep lush emerald-moss shadow base
    albedo[:, :] = np.array([0.13, 0.36, 0.14], dtype=np.float32)

    ys = np.arange(size, dtype=np.float32)
    xs = np.arange(size, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)

    # Stamp 420 overlapping painterly stylized oak leaf petals (tileable across edges!)
    n_leaves = 420
    for i in range(n_leaves):
        t_layer = i / float(n_leaves)
        cx = rng.uniform(0.0, size)
        cy = rng.uniform(0.0, size)
        ang = rng.uniform(0.0, math.tau)
        rx = rng.uniform(size * 0.036, size * 0.068)
        ry = rx * rng.uniform(0.55, 0.80)

        # Periodic shortest distance on torus
        dx = ((gx - cx + size * 0.5) % size) - size * 0.5
        dy = ((gy - cy + size * 0.5) % size) - size * 0.5
        ca, sa = math.cos(ang), math.sin(ang)
        lx = (dx * ca + dy * sa) / rx
        ly = (-dx * sa + dy * ca) / ry

        # Pointed Pixar leaf silhouette (tapered tip + gentle scalloped lobes)
        lobe = 1.0 + 0.14 * np.cos(np.arctan2(ly, lx) * 5.0)
        r2 = (lx * lx + ly * ly) / (lobe * lobe)
        mask = np.clip((1.0 - r2) * 3.2, 0.0, 1.0)
        if not np.any(mask > 0.01):
            continue

        # Center vein crease & rounded pillowy leaf dome
        vein = np.exp(-abs(ly) * 9.0) * 0.12
        leaf_h = (0.28 + 0.72 * t_layer) * np.sqrt(np.clip(1.0 - r2, 0.0, 1.0)) + vein * mask
        # Sunlit lime-gold upper leaves over lush emerald mid-leaves
        sun_bias = np.clip(t_layer * 0.85 + rng.uniform(-0.12, 0.18), 0.0, 1.0)
        c_dark = np.array([0.16, 0.50, 0.18], dtype=np.float32)
        c_mid = np.array([0.28, 0.70, 0.22], dtype=np.float32)
        c_sun = np.array([0.52, 0.86, 0.24], dtype=np.float32)
        if sun_bias < 0.55:
            col = c_dark * (1.0 - sun_bias / 0.55) + c_mid * (sun_bias / 0.55)
        else:
            u = (sun_bias - 0.55) / 0.45
            col = c_mid * (1.0 - u) + c_sun * u

        # Tip highlight & dark base AO per leaf
        grad = np.clip(0.84 + 0.24 * (lx * 0.5 + 0.5), 0.72, 1.12)
        blend = (mask > 0.15) & (leaf_h >= height - 0.10)
        alpha = np.where(blend, np.clip(mask * 1.15, 0.0, 1.0), 0.0)
        height = np.where(alpha > 0.0, np.maximum(height, leaf_h), height)
        for c in range(3):
            albedo[:, :, c] = albedo[:, :, c] * (1.0 - alpha) + np.clip(col[c] * grad, 0.0, 1.0) * alpha

    # Subtle overall organic variation
    macro = _tileable_fbm(size, (4, 8), (0.65, 0.35), seed=102)
    albedo = np.clip(albedo * (0.86 + 0.28 * macro[:, :, None]), 0.0, 1.0)

    _save_rgb(os.path.join(out_dir, "foliage_leaf_albedo.png"), albedo)
    _save_rgb(os.path.join(out_dir, "foliage_leaf_normal.png"), _height_to_normal(height, strength=4.2))


# ---------------------------------------------------------------------------
# 2. Warm Stylized Oak Bark (Albedo + Normal)
# ---------------------------------------------------------------------------
def gen_bark(out_dir: str, size: int = 512) -> None:
    ys = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    xs = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)
    warp = _tileable_fbm(size, (4, 8, 16), (0.55, 0.30, 0.15), seed=201)
    ridge = np.sin((gx * 18.0 + warp * 1.65) * math.tau) * 0.5 + 0.5
    fine = _tileable_fbm(size, (16, 32), (0.6, 0.4), seed=202)
    h = np.clip(ridge * 0.72 + fine * 0.28, 0.0, 1.0)

    c_crevice = np.array([0.28, 0.16, 0.09], dtype=np.float32)
    c_mid = np.array([0.48, 0.30, 0.17], dtype=np.float32)
    c_ridge = np.array([0.62, 0.42, 0.24], dtype=np.float32)
    t1 = np.clip(h * 2.0, 0.0, 1.0)[:, :, None]
    t2 = np.clip((h - 0.5) * 2.0, 0.0, 1.0)[:, :, None]
    col = np.where(h[:, :, None] < 0.5, c_crevice * (1.0 - t1) + c_mid * t1, c_mid * (1.0 - t2) + c_ridge * t2)

    _save_rgb(os.path.join(out_dir, "bark_oak_albedo.png"), col)
    _save_rgb(os.path.join(out_dir, "bark_oak_normal.png"), _height_to_normal(h, strength=4.5))


# ---------------------------------------------------------------------------
# 3. Knitted Hoodie Fleece & Denim Twill Fabric Normals + ORM
# ---------------------------------------------------------------------------
def gen_fabrics(out_dir: str, size: int = 512) -> None:
    ys = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    xs = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)

    # Soft cotton fleece knit (gentle herringbone V-stitch + soft fabric folds)
    knit_x = np.sin(gx * 64.0 * math.tau)
    knit_y = np.sin((gy * 64.0 + np.abs((gx * 32.0) % 1.0 - 0.5) * 0.8) * math.tau)
    soft_fold = _tileable_fbm(size, (4, 8, 16), (0.5, 0.3, 0.2), seed=301)
    fleece_h = np.clip(0.5 + 0.16 * knit_x * knit_y + 0.30 * (soft_fold - 0.5), 0.0, 1.0)
    _save_rgb(os.path.join(out_dir, "hoodie_fleece_normal.png"), _height_to_normal(fleece_h, strength=2.2))

    # Denim diagonal twill weave
    twill = np.sin((gx * 72.0 + gy * 72.0) * math.tau) * 0.5 + 0.5
    cross = np.sin((gx * 72.0 - gy * 24.0) * math.tau) * 0.5 + 0.5
    denim_noise = _tileable_fbm(size, (8, 16, 32), (0.45, 0.35, 0.20), seed=302)
    denim_h = np.clip(twill * 0.55 + cross * 0.20 + denim_noise * 0.25, 0.0, 1.0)
    _save_rgb(os.path.join(out_dir, "denim_weave_normal.png"), _height_to_normal(denim_h, strength=2.6))

    # Stylized Pixar brushed hair strand ridges
    hair_w = _tileable_fbm(size, (4, 16), (0.65, 0.35), seed=303)
    strands = np.sin((gx * 42.0 + hair_w * 0.9) * math.tau) * 0.5 + 0.5
    micro_s = np.sin((gx * 96.0 + hair_w * 1.4) * math.tau) * 0.5 + 0.5
    hair_h = np.clip(strands * 0.65 + micro_s * 0.35, 0.0, 1.0)
    _save_rgb(os.path.join(out_dir, "hair_strands_normal.png"), _height_to_normal(hair_h, strength=2.8))


# ---------------------------------------------------------------------------
# 4. Scalloped Cedar Roof Shingles (Albedo + Normal)
# ---------------------------------------------------------------------------
def gen_shingles(out_dir: str, size: int = 512) -> None:
    ys = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    xs = np.linspace(0.0, 1.0, size, endpoint=False, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)

    rows = 8.0
    cols = 6.0
    row_idx = np.floor(gy * rows)
    row_v = (gy * rows) % 1.0
    stagger = (row_idx % 2.0) * 0.5
    col_x = (gx * cols + stagger)
    col_idx = np.floor(col_x) % cols
    col_u = col_x % 1.0

    # Vertical shingle gap & overlapping stepped course shadow
    edge_gap = np.clip(np.minimum(col_u, 1.0 - col_u) * 18.0, 0.0, 1.0)
    course_step = np.clip(row_v * 14.0, 0.0, 1.0)
    grain = _tileable_fbm(size, (8, 32), (0.6, 0.4), seed=401)
    tile_var = np.sin(row_idx * 12.7 + col_idx * 31.3) * 0.5 + 0.5

    h = np.clip((0.35 + 0.55 * (1.0 - row_v)) * edge_gap * course_step + grain * 0.12, 0.0, 1.0)
    # Neutral warm cedar albedo (tinted per roof by shader albedo_color!)
    base = 0.72 + 0.24 * tile_var + 0.10 * (grain - 0.5)
    shadow = 0.58 + 0.42 * np.minimum(edge_gap, course_step)
    albedo = np.stack([
        np.clip(base * shadow * 1.04, 0.0, 1.0),
        np.clip(base * shadow * 0.96, 0.0, 1.0),
        np.clip(base * shadow * 0.88, 0.0, 1.0),
    ], axis=-1)
    _save_rgb(os.path.join(out_dir, "shingle_roof_albedo.png"), albedo)
    _save_rgb(os.path.join(out_dir, "shingle_roof_normal.png"), _height_to_normal(h, strength=4.2))


# ---------------------------------------------------------------------------
# 5. Painterly Sunlit Lawn Grass Blades & Clover Micro-Detail (Normal + Albedo)
# ---------------------------------------------------------------------------
def gen_grass(out_dir: str, size: int = 512) -> None:
    rng = np.random.default_rng(501)
    h = _tileable_fbm(size, (8, 16, 32, 64), (0.35, 0.28, 0.22, 0.15), seed=502)
    albedo = np.zeros((size, size, 3), dtype=np.float32)
    c1 = np.array([0.26, 0.62, 0.22], dtype=np.float32)
    c2 = np.array([0.44, 0.78, 0.26], dtype=np.float32)
    albedo = c1 * (1.0 - h[:, :, None]) + c2 * h[:, :, None]

    # Stamp 700 crisp painterly stylized grass blade tufts
    ys = np.arange(size, dtype=np.float32)
    xs = np.arange(size, dtype=np.float32)
    gx, gy = np.meshgrid(xs, ys)
    for _ in range(700):
        cx = rng.uniform(0.0, size)
        cy = rng.uniform(0.0, size)
        ang = rng.uniform(-0.6, 0.6)
        blen = rng.uniform(size * 0.016, size * 0.036)
        bw = blen * 0.24
        dx = ((gx - cx + size * 0.5) % size) - size * 0.5
        dy = ((gy - cy + size * 0.5) % size) - size * 0.5
        ca, sa = math.cos(ang), math.sin(ang)
        lx = (dx * ca + dy * sa) / bw
        ly = (-dx * sa + dy * ca) / blen
        d2 = lx * lx + ly * ly
        m = np.clip((1.0 - d2) * 2.5, 0.0, 1.0)
        if not np.any(m > 0.02):
            continue
        h = np.clip(h + m * 0.18, 0.0, 1.0)
        bright = rng.uniform(0.88, 1.18)
        blade_col = np.array([0.38 * bright, 0.78 * bright, 0.22 * bright], dtype=np.float32)
        for c in range(3):
            albedo[:, :, c] = albedo[:, :, c] * (1.0 - m * 0.55) + np.clip(blade_col[c], 0.0, 1.0) * (m * 0.55)

    _save_rgb(os.path.join(out_dir, "grass_tuft_albedo.png"), albedo)
    _save_rgb(os.path.join(out_dir, "grass_tuft_normal.png"), _height_to_normal(h, strength=3.0))


# ---------------------------------------------------------------------------
# 6. Soft Bounce-House PVC Vinyl Micro-Grain Normal
# ---------------------------------------------------------------------------
def gen_vinyl(out_dir: str, size: int = 256) -> None:
    h = _tileable_fbm(size, (16, 32, 64), (0.45, 0.35, 0.20), seed=601)
    _save_rgb(os.path.join(out_dir, "vinyl_grain_normal.png"), _height_to_normal(h, strength=1.2))


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(repo_root, "assets", "textures", "stylized")
    os.makedirs(out_dir, exist_ok=True)
    gen_foliage(out_dir, 512)
    gen_bark(out_dir, 512)
    gen_fabrics(out_dir, 512)
    gen_shingles(out_dir, 512)
    gen_grass(out_dir, 512)
    gen_vinyl(out_dir, 256)
    print("Generated Pixar/Fortnite stylized PBR textures in", out_dir)


if __name__ == "__main__":
    main()
