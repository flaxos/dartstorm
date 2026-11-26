#!/usr/bin/env python3
"""
Generates seamless PBR texture sets (Albedo, Normal, ORM) for DARTSTORM arenas:
- Sandstone Adobe (de_dust, de_dust2 walls & arches)
- Cobblestone Pavement (courtyards, avenues, paths)
- Weathered Wood Planks (2Fort bridge, towers, decks, crates)
- Fortress Stone Brick (2Fort fortresses, castle masonry)
"""

import os
import math
from PIL import Image, ImageFilter, ImageOps

BASE_DIR = "/home/flax/games/dartstorm"
OUT_DIR = os.path.join(BASE_DIR, "assets/textures/arenas")
os.makedirs(OUT_DIR, exist_ok=True)

SOURCES = {
    "sandstone": {
        "src": "/home/flax/.gemini/antigravity/brain/d63e5a52-fa6e-4ddd-b284-e80cf7779b79/stylized_sandstone_texture_1795346722949.jpg",
        "roughness": 0.84,
        "bump_strength": 3.0,
    },
    "cobble": {
        "src": "/home/flax/.gemini/antigravity/brain/d63e5a52-fa6e-4ddd-b284-e80cf7779b79/stylized_desert_pavers_1795434650725.jpg",
        "roughness": 0.85,
        "bump_strength": 3.2,
    },
    "sand": {
        "src": "/home/flax/.gemini/antigravity/brain/d63e5a52-fa6e-4ddd-b284-e80cf7779b79/stylized_desert_sand_1795434616405.jpg",
        "roughness": 0.94,
        "bump_strength": 2.0,
    },
    "wood": {
        "src": "/home/flax/.gemini/antigravity/brain/d63e5a52-fa6e-4ddd-b284-e80cf7779b79/stylized_wood_planks_1795346772374.jpg",
        "roughness": 0.76,
        "bump_strength": 2.5,
    },
    "brick": {
        "src": "/home/flax/.gemini/antigravity/brain/d63e5a52-fa6e-4ddd-b284-e80cf7779b79/stylized_fortress_brick_1795346801122.jpg",
        "roughness": 0.86,
        "bump_strength": 3.8,
    },
}

def generate_normal_and_orm(albedo_img, base_roughness, bump_strength=3.0):
    size = albedo_img.size
    gray = albedo_img.convert("L")
    gray_pixels = gray.load()

    # Pre-blur slightly for smooth normal gradients without single-pixel noise
    smooth_gray = gray.filter(ImageFilter.GaussianBlur(radius=1.0))
    smooth_pixels = smooth_gray.load()

    normal_img = Image.new("RGB", size)
    norm_pixels = normal_img.load()

    orm_img = Image.new("RGB", size)
    orm_pixels = orm_img.load()

    w, h = size
    strength = bump_strength / 255.0

    # Ambient occlusion: local darkness in crevices
    ao_map = gray.filter(ImageFilter.GaussianBlur(radius=4.0))
    ao_pixels = ao_map.load()

    for y in range(h):
        y_prev = (y - 1) % h
        y_next = (y + 1) % h
        for x in range(w):
            x_prev = (x - 1) % w
            x_next = (x + 1) % w

            # Sobel-like central difference
            dx = (smooth_pixels[x_next, y] - smooth_pixels[x_prev, y]) * strength
            dy = (smooth_pixels[x, y_next] - smooth_pixels[x, y_prev]) * strength
            dz = 1.0

            # Normalize vector
            length = math.sqrt(dx * dx + dy * dy + dz * dz)
            nx = dx / length
            ny = dy / length
            nz = dz / length

            # Map [-1, 1] to [0, 255]
            # OpenGL format: R = +X, G = +Y (inverted screen Y), B = +Z
            r = int((nx * 0.5 + 0.5) * 255)
            g = int((-ny * 0.5 + 0.5) * 255)
            b = int((nz * 0.5 + 0.5) * 255)
            norm_pixels[x, y] = (r, g, b)

            # ORM Packing: R=AO, G=Roughness, B=Metallic
            lum = gray_pixels[x, y] / 255.0
            ao_val = int(min(255, max(128, int(ao_pixels[x, y] * 0.7 + 100))))
            # Crevices and mortar lines are slightly rougher
            rough_val = int(min(255, max(0, int((base_roughness + (1.0 - lum) * 0.12) * 255))))
            metal_val = 0
            orm_pixels[x, y] = (ao_val, rough_val, metal_val)

    return normal_img, orm_img

def make_perfectly_seamless(img, blend_size=80):
    """Blends borders on X and Y with cosine smoothing so textures wrap perfectly with zero seams."""
    import numpy as np
    arr = np.array(img, dtype=float)
    h, w, c = arr.shape
    b = blend_size

    # Horizontal cross-fade
    for i in range(b):
        alpha = 0.5 - 0.5 * math.cos(math.pi * i / float(b))
        left_orig = arr[:, i].copy()
        right_orig = arr[:, w - b + i].copy()
        arr[:, i] = left_orig * alpha + right_orig * (1.0 - alpha)
        arr[:, w - b + i] = right_orig * alpha + left_orig * (1.0 - alpha)
    arr[:, -1] = arr[:, 0]

    # Vertical cross-fade
    for j in range(b):
        alpha = 0.5 - 0.5 * math.cos(math.pi * j / float(b))
        top_orig = arr[j, :].copy()
        bottom_orig = arr[h - b + j, :].copy()
        arr[j, :] = top_orig * alpha + bottom_orig * (1.0 - alpha)
        arr[h - b + j, :] = bottom_orig * alpha + top_orig * (1.0 - alpha)
    arr[-1, :] = arr[0, :]

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))

def main():
    print("Processing Stylized Arena PBR Textures...")
    for name, cfg in SOURCES.items():
        src_path = cfg["src"]
        if not os.path.exists(src_path):
            print(f"ERROR: {src_path} not found!")
            continue

        print(f"Generating {name} PBR texture set from {os.path.basename(src_path)}...")
        raw_img = Image.open(src_path).convert("RGB")
        target_size = (1024, 1024)
        albedo = raw_img.resize(target_size, Image.Resampling.LANCZOS)
        albedo = make_perfectly_seamless(albedo, blend_size=80)

        albedo_path = os.path.join(OUT_DIR, f"{name}_albedo.png")
        normal_path = os.path.join(OUT_DIR, f"{name}_normal.png")
        orm_path = os.path.join(OUT_DIR, f"{name}_orm.png")

        albedo.save(albedo_path, "PNG", optimize=True)

        normal_img, orm_img = generate_normal_and_orm(
            albedo,
            base_roughness=cfg["roughness"],
            bump_strength=cfg["bump_strength"]
        )

        normal_img.save(normal_path, "PNG", optimize=True)
        orm_img.save(orm_path, "PNG", optimize=True)

        print(f"  -> Saved {albedo_path} ({os.path.getsize(albedo_path) // 1024} KB)")
        print(f"  -> Saved {normal_path} ({os.path.getsize(normal_path) // 1024} KB)")
        print(f"  -> Saved {orm_path} ({os.path.getsize(orm_path) // 1024} KB)")

    # Also generate smooth sandstone (for coping ledges, cornices, archway pillars and trims)
    print("Generating smooth sandstone for architectural trim & cornices...")
    sandstone_albedo_path = os.path.join(OUT_DIR, "sandstone_albedo.png")
    if os.path.exists(sandstone_albedo_path):
        base_stone = Image.open(sandstone_albedo_path).convert("RGB")
        # Heavy blur to remove individual brick outlines while retaining rich warm sandstone earthen tones
        smooth_stone = base_stone.filter(ImageFilter.GaussianBlur(radius=16.0))
        # Re-introduce subtle stone grain noise
        import numpy as np
        np.random.seed(42)
        s_arr = np.array(smooth_stone, dtype=float)
        noise = np.random.normal(0, 4.0, s_arr.shape)
        s_arr = np.clip(s_arr + noise, 0, 255).astype(np.uint8)
        smooth_albedo = make_perfectly_seamless(Image.fromarray(s_arr), blend_size=80)

        s_albedo_path = os.path.join(OUT_DIR, "sandstone_smooth_albedo.png")
        s_normal_path = os.path.join(OUT_DIR, "sandstone_smooth_normal.png")
        s_orm_path = os.path.join(OUT_DIR, "sandstone_smooth_orm.png")

        smooth_albedo.save(s_albedo_path, "PNG", optimize=True)
        s_normal, s_orm = generate_normal_and_orm(smooth_albedo, base_roughness=0.78, bump_strength=1.5)
        s_normal.save(s_normal_path, "PNG", optimize=True)
        s_orm.save(s_orm_path, "PNG", optimize=True)
        print(f"  -> Saved {s_albedo_path}")
        print(f"  -> Saved {s_normal_path}")
        print(f"  -> Saved {s_orm_path}")

    print("All arena PBR textures successfully generated!")

if __name__ == "__main__":
    main()
