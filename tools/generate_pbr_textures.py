#!/usr/bin/env python3
"""
Procedural AAA PBR Texture Synthesizer for DARTSTORM
Generates ultra-high quality 2048x2048 PBR texture maps:
- Tangent-space Normal Maps (with OpenGL Y+ convention for Godot)
- Packed ORM Maps (R = Ambient Occlusion, G = Roughness, B = Metallic)
- Detail Micro-Normals (tileable 1024x1024)

Outputs to assets/textures/pbr/
"""

import os
import sys
import numpy as np
from PIL import Image

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "textures", "pbr")
os.makedirs(OUT_DIR, exist_ok=True)

def height_to_normal(heightmap: np.ndarray, bump_scale: float = 2.0) -> np.ndarray:
    """
    Converts a 2D float heightmap [0..1] to an RGB normal map uint8 [0..255].
    Godot uses OpenGL standard tangent space:
    +X = Right (Red)
    +Y = Up (Green)
    +Z = Surface Normal out of screen (Blue)
    In 2D image coordinates, Y=0 is top, so +Y in 3D corresponds to decreasing image row index (-gy).
    """
    # Calculate central differences
    gy, gx = np.gradient(heightmap.astype(np.float32))
    
    # +X is right (+gx), +Y is up in 3D (-gy in image rows)
    nx = -gx * bump_scale
    ny = gy * bump_scale
    nz = np.ones_like(nx)
    
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx /= length
    ny /= length
    nz /= length
    
    r = np.clip((nx * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    g = np.clip((ny * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    b = np.clip((nz * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    
    return np.stack([r, g, b], axis=-1)

def save_image(arr: np.ndarray, filename: str):
    path = os.path.join(OUT_DIR, filename)
    img = Image.fromarray(arr)
    img.save(path, format="PNG", optimize=True)
    print(f"Saved: {path} ({arr.shape[1]}x{arr.shape[0]})")

def generate_micro_detail_normal(size=1024):
    """Tileable micro-pebble molded polymer grain for close-up ADS and inspection."""
    np.random.seed(42)
    # Generate seamless multi-octave noise
    x = np.linspace(0, 32 * np.pi, size, endpoint=False)
    y = np.linspace(0, 32 * np.pi, size, endpoint=False)
    xx, yy = np.meshgrid(x, y)
    
    # Seamless trigonometric synthetic pebble grain
    h = (
        np.sin(xx * 4.0) * np.cos(yy * 4.0) * 0.5 +
        np.sin(xx * 8.0 + 1.2) * np.cos(yy * 8.0 + 0.7) * 0.25 +
        np.sin(xx * 16.0 + 2.4) * np.cos(yy * 16.0 + 1.8) * 0.15 +
        np.sin((xx + yy) * 12.0) * 0.1
    )
    h = (h - h.min()) / (h.max() - h.min())
    
    normal = height_to_normal(h, bump_scale=3.5)
    save_image(normal, "micro_detail_normal.png")

def generate_blaster_body_pbr(size=2048):
    """
    High-end molded toy polymer casing with:
    - Chamfered panel margins and recessed panel seams
    - Corner hex screws with socket indents
    - Horizontal cooling/airflow vents
    - Stippled ergonomic side grip inserts
    """
    h = np.ones((size, size), dtype=np.float32) * 0.5
    ao = np.ones((size, size), dtype=np.float32)
    roughness = np.ones((size, size), dtype=np.float32) * 0.38  # Smooth molded ABS
    metallic = np.zeros((size, size), dtype=np.float32)
    
    x = np.arange(size)
    y = np.arange(size)
    xx, yy = np.meshgrid(x, y)
    
    # 1. Beveled outer edge
    margin = 48
    d_border = np.minimum(np.minimum(xx, size - 1 - xx), np.minimum(yy, size - 1 - yy))
    bevel_mask = d_border < margin
    bevel_t = np.clip(d_border / float(margin), 0.0, 1.0)
    h[bevel_mask] = bevel_t[bevel_mask] * 0.5
    roughness[bevel_mask] = 0.22  # Polished chamfer reflection
    
    # 2. Recessed central panel seams
    seam_w = 6
    seam_x = np.abs(xx - size // 2) < seam_w
    seam_y = np.abs(yy - size // 2) < seam_w
    seams = seam_x | seam_y
    h[seams] = 0.2
    ao[seams] = 0.25
    roughness[seams] = 0.65
    
    # Additional quadrant seams
    q_seam_x = (np.abs(xx - size // 4) < seam_w) | (np.abs(xx - 3 * size // 4) < seam_w)
    q_seams = q_seam_x & (yy > size // 4) & (yy < 3 * size // 4)
    h[q_seams] = 0.2
    ao[q_seams] = 0.3
    
    # 3. Horizontal cooling vents in top right & bottom left quadrants
    for qx, qy in [(size * 3 // 4, size // 4), (size // 4, size * 3 // 4)]:
        vent_box = (np.abs(xx - qx) < 220) & (np.abs(yy - qy) < 160)
        vent_bars = vent_box & ((yy % 32) < 14)
        h[vent_bars] = 0.1
        ao[vent_bars] = 0.2
        roughness[vent_bars] = 0.75
    
    # 4. Corner Hex Screws with center socket
    screw_centers = [
        (size // 8, size // 8),
        (size * 7 // 8, size // 8),
        (size // 8, size * 7 // 8),
        (size * 7 // 8, size * 7 // 8),
        (size // 2, size // 8),
        (size // 2, size * 7 // 8),
    ]
    screw_r = 38
    socket_r = 16
    for cx, cy in screw_centers:
        dist = np.sqrt((xx - cx)**2 + (yy - cy)**2)
        # Screw recess well
        recess = (dist >= screw_r) & (dist < screw_r + 10)
        h[recess] = 0.2
        ao[recess] = 0.3
        
        # Screw dome head
        head = dist < screw_r
        h[head] = 0.5 + np.cos((dist[head] / screw_r) * (np.pi / 2)) * 0.25
        roughness[head] = 0.22
        metallic[head] = 0.95  # Chrome/alloy hardware screw
        
        # Hex socket in center
        socket = dist < socket_r
        h[socket] = 0.25
        ao[socket] = 0.2
        roughness[socket] = 0.5
        metallic[socket] = 0.7
    
    # 5. Tactile grip stippling in lower right quadrant
    grip_box = (np.abs(xx - size * 3 // 4) < 240) & (np.abs(yy - size * 3 // 4) < 200)
    stipple = np.sin(xx * 0.25) * np.cos(yy * 0.25) * 0.12
    h[grip_box] += stipple[grip_box]
    roughness[grip_box] = 0.82
    
    normal = height_to_normal(h, bump_scale=4.0)
    save_image(normal, "blaster_body_normal.png")
    
    orm = np.stack([
        (np.clip(ao, 0, 1) * 255).astype(np.uint8),
        (np.clip(roughness, 0, 1) * 255).astype(np.uint8),
        (np.clip(metallic, 0, 1) * 255).astype(np.uint8)
    ], axis=-1)
    save_image(orm, "blaster_body_orm.png")

def generate_rubber_grip_pbr(size=2048):
    """
    Diamond-knurled tactile non-slip rubber grip:
    - High-frequency diamond pyramids
    - Deep occluded crevices
    - Matte tactile finish
    """
    x = np.arange(size)
    y = np.arange(size)
    xx, yy = np.meshgrid(x, y)
    
    # Diagonal diamond knurling coordinates
    grid_size = 32.0
    u = ((xx + yy) % grid_size) / grid_size
    v = ((xx - yy) % grid_size) / grid_size
    
    # Pyramid profile
    pyramid = np.maximum(0.0, 1.0 - (np.abs(u - 0.5) * 2.0 + np.abs(v - 0.5) * 2.0))
    h = pyramid * 0.6
    
    # Border bevel
    b_dist = np.minimum(np.minimum(xx, size - 1 - xx), np.minimum(yy, size - 1 - yy))
    bevel_mask = b_dist < 40
    h[bevel_mask] *= np.clip(b_dist[bevel_mask] / 40.0, 0.0, 1.0)
    
    # AO is dark in the valleys
    ao = np.clip(pyramid * 0.8 + 0.2, 0.0, 1.0)
    roughness = np.ones((size, size), dtype=np.float32) * 0.86  # Soft rubber
    metallic = np.zeros((size, size), dtype=np.float32)
    
    normal = height_to_normal(h, bump_scale=6.0)
    save_image(normal, "rubber_grip_normal.png")
    
    orm = np.stack([
        (ao * 255).astype(np.uint8),
        (roughness * 255).astype(np.uint8),
        (metallic * 255).astype(np.uint8)
    ], axis=-1)
    save_image(orm, "rubber_grip_orm.png")

def generate_brushed_metal_pbr(size=2048):
    """
    Machined aluminum / brass barrel and trigger linkage:
    - Directional fine hairline brush grooves
    - Crisp metallic sheen
    """
    np.random.seed(123)
    y = np.linspace(0, 1, size)
    # Horizontal brush lines vary purely along Y
    brush = np.sin(y * size * 0.8) * 0.15 + np.sin(y * size * 2.1) * 0.1
    # Repeat along X
    h = np.tile(brush[:, np.newaxis], (1, size)).astype(np.float32) + 0.5
    
    normal = height_to_normal(h, bump_scale=2.0)
    save_image(normal, "brushed_metal_normal.png")
    
    ao = np.ones((size, size), dtype=np.uint8) * 255
    roughness = (np.ones((size, size), dtype=np.float32) * 0.26 * 255).astype(np.uint8)
    metallic = (np.ones((size, size), dtype=np.float32) * 0.98 * 255).astype(np.uint8)
    orm = np.stack([ao, roughness, metallic], axis=-1)
    save_image(orm, "brushed_metal_orm.png")

def generate_cloth_fabric_pbr(size=2048):
    """
    Stylized hoodie and combat vest cloth:
    - Diagonal twill cross-weave
    - Double seam stitches along border
    """
    x = np.arange(size)
    y = np.arange(size)
    xx, yy = np.meshgrid(x, y)
    
    # Twill weave
    twill = (np.sin((xx + yy) * 0.6) * 0.5 + np.sin((xx - yy) * 0.6) * 0.5) * 0.15 + 0.5
    h = twill.astype(np.float32)
    ao = np.clip(twill * 0.6 + 0.4, 0.0, 1.0)
    roughness = np.ones((size, size), dtype=np.float32) * 0.90
    metallic = np.zeros((size, size), dtype=np.float32)
    
    # Seam stitch lines along border
    for margin in [32, 48]:
        stitch_mask = (np.abs(xx - margin) < 3) | (np.abs(xx - (size - margin)) < 3) | \
                      (np.abs(yy - margin) < 3) | (np.abs(yy - (size - margin)) < 3)
        stitch_dots = stitch_mask & (((xx + yy) % 20) < 12)
        h[stitch_dots] += 0.35
        ao[stitch_mask] *= 0.6
        roughness[stitch_dots] = 0.4
    
    normal = height_to_normal(h, bump_scale=3.0)
    save_image(normal, "cloth_fabric_normal.png")
    
    orm = np.stack([
        (ao * 255).astype(np.uint8),
        (roughness * 255).astype(np.uint8),
        (metallic * 255).astype(np.uint8)
    ], axis=-1)
    save_image(orm, "cloth_fabric_orm.png")

def generate_sneaker_rubber_pbr(size=2048):
    """
    High-traction sneaker tread and rubber sidewall:
    - Chevron / herringbone tread grooves
    - Thick molded rubber sole
    """
    x = np.arange(size)
    y = np.arange(size)
    xx, yy = np.meshgrid(x, y)
    
    # Chevron wave along Y
    wave = np.abs((xx % 120) - 60)
    chevron = ((yy + wave) % 80) < 24
    
    h = np.ones((size, size), dtype=np.float32) * 0.6
    h[chevron] = 0.2
    
    ao = np.ones((size, size), dtype=np.float32)
    ao[chevron] = 0.25
    
    roughness = np.ones((size, size), dtype=np.float32) * 0.62
    metallic = np.zeros((size, size), dtype=np.float32)
    
    normal = height_to_normal(h, bump_scale=5.0)
    save_image(normal, "sneaker_rubber_normal.png")
    
    orm = np.stack([
        (ao * 255).astype(np.uint8),
        (roughness * 255).astype(np.uint8),
        (metallic * 255).astype(np.uint8)
    ], axis=-1)
    save_image(orm, "sneaker_rubber_orm.png")

def generate_stylized_wood_pbr(size=2048):
    """
    Stylized cedar/oak planks for arena ramps, picnic tables and crates:
    - Defined plank gap seams
    - Flowing wood grain ridges
    """
    x = np.arange(size)
    y = np.arange(size)
    xx, yy = np.meshgrid(x, y)
    
    # 4 Vertical planks across width
    plank_w = size // 4
    seam = (xx % plank_w) < 10
    
    # Flowing organic grain
    np.random.seed(99)
    grain = (
        np.sin(xx * 0.04 + np.sin(yy * 0.008) * 6.0) * 0.15 +
        np.sin(xx * 0.08 + np.cos(yy * 0.012) * 4.0) * 0.08
    )
    
    h = 0.5 + grain
    h[seam] = 0.1
    
    ao = np.clip(0.8 + grain * 0.4, 0.0, 1.0)
    ao[seam] = 0.2
    
    roughness = np.ones((size, size), dtype=np.float32) * 0.72
    metallic = np.zeros((size, size), dtype=np.float32)
    
    normal = height_to_normal(h, bump_scale=3.5)
    save_image(normal, "stylized_wood_normal.png")
    
    orm = np.stack([
        (ao * 255).astype(np.uint8),
        (roughness * 255).astype(np.uint8),
        (metallic * 255).astype(np.uint8)
    ], axis=-1)
    save_image(orm, "stylized_wood_orm.png")

def main():
    print(f"Generating AAA PBR texture suite into {OUT_DIR}...")
    generate_micro_detail_normal(1024)
    generate_blaster_body_pbr(2048)
    generate_rubber_grip_pbr(2048)
    generate_brushed_metal_pbr(2048)
    generate_cloth_fabric_pbr(2048)
    generate_sneaker_rubber_pbr(2048)
    generate_stylized_wood_pbr(2048)
    print("All PBR textures generated successfully!")

if __name__ == "__main__":
    main()
