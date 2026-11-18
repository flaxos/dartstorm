#!/usr/bin/env python3
"""
Generate crisp, seamless, stylized 1024x1024 vector-style skin textures for DARTSTORM.
Pure albedo pattern masks without baked fake lighting or noisy diffusion slop.
"""

import math
import os
from PIL import Image, ImageDraw

OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/textures/skins"))
SIZE = 1024


def create_dir():
    os.makedirs(OUTPUT_DIR, exist_ok=True)


def gen_default():
    """Default subtle molded toy plastic pebble/hex pattern."""
    img = Image.new("RGBA", (SIZE, SIZE), (230, 230, 230, 255))
    draw = ImageDraw.Draw(img)
    step = 32
    for y in range(0, SIZE, step):
        for x in range(0, SIZE, step):
            offset = (step // 2) if (y // step) % 2 == 1 else 0
            px = (x + offset) % SIZE
            draw.ellipse([px + 8, y + 8, px + 24, y + 24], fill=(255, 255, 255, 255))
            draw.ellipse([px + 12, y + 12, px + 20, y + 20], fill=(210, 210, 210, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_default.png"))
    print("Saved pattern_default.png")


def gen_nitro():
    """Nitro Stripe: bold racing stripes, angled speed chevrons."""
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    stripe_w = 64
    for x in range(0, SIZE, stripe_w * 4):
        # Dual primary stripes
        draw.rectangle([x, 0, x + stripe_w, SIZE], fill=(20, 20, 20, 255))
        draw.rectangle([x + stripe_w + 24, 0, x + stripe_w * 2, SIZE], fill=(20, 20, 20, 255))
        # Thin pin stripes
        draw.rectangle([x + stripe_w * 2 + 16, 0, x + stripe_w * 2 + 28, SIZE], fill=(180, 180, 180, 255))
    # Angled speed dashes
    for y in range(0, SIZE, 128):
        for x in range(0, SIZE, 128):
            points = [(x, y), (x + 60, y), (x + 80, y + 40), (x + 20, y + 40)]
            draw.polygon(points, fill=(60, 60, 60, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_nitro.png"))
    print("Saved pattern_nitro.png")


def gen_cyber():
    """Neon Cyber: crisp circuit traces, chips, and digital bus grids."""
    img = Image.new("RGBA", (SIZE, SIZE), (25, 30, 45, 255))
    draw = ImageDraw.Draw(img)
    # Background subtle grid
    grid = 64
    for i in range(0, SIZE, grid):
        draw.line([(i, 0), (i, SIZE)], fill=(45, 55, 80, 255), width=2)
        draw.line([(0, i), (SIZE, i)], fill=(45, 55, 80, 255), width=2)
    # Circuit traces
    trace_color = (0, 240, 255, 255)
    accent_color = (255, 0, 180, 255)
    for y in range(64, SIZE, 128):
        draw.line([(0, y), (SIZE, y)], fill=trace_color, width=8)
        for x in range(64, SIZE, 128):
            draw.rectangle([x - 16, y - 16, x + 16, y + 16], fill=accent_color)
            draw.line([(x, y), (x + 48, y + 48)], fill=trace_color, width=8)
            draw.ellipse([x + 48 - 8, y + 48 - 8, x + 48 + 8, y + 48 + 8], fill=(255, 255, 255, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_cyber.png"))
    print("Saved pattern_cyber.png")


def gen_hazard():
    """Caution Zone: bold industrial hazard diagonal chevrons."""
    img = Image.new("RGBA", (SIZE, SIZE), (245, 200, 20, 255))
    draw = ImageDraw.Draw(img)
    stripe_w = 64
    for i in range(-SIZE, SIZE * 2, stripe_w * 2):
        points = [
            (i, 0),
            (i + stripe_w, 0),
            (i + stripe_w + SIZE, SIZE),
            (i + SIZE, SIZE),
        ]
        draw.polygon(points, fill=(25, 25, 25, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_hazard.png"))
    print("Saved pattern_hazard.png")


def gen_galaxy():
    """Cosmic Pop: stylized cartoon starbursts, rings, and geometric constellations."""
    img = Image.new("RGBA", (SIZE, SIZE), (30, 20, 60, 255))
    draw = ImageDraw.Draw(img)
    step = 128
    for y in range(0, SIZE, step):
        for x in range(0, SIZE, step):
            cx = x + 64
            cy = y + 64
            # Starburst 4-point star
            star_r = 32
            draw.polygon([(cx, cy - star_r), (cx + 8, cy - 8), (cx + star_r, cy), (cx + 8, cy + 8),
                          (cx, cy + star_r), (cx - 8, cy + 8), (cx - star_r, cy), (cx - 8, cy - 8)],
                         fill=(255, 220, 50, 255))
            # Planetary orbit ring
            draw.ellipse([cx - 48, cy - 16, cx + 48, cy + 16], outline=(180, 100, 255, 255), width=4)
            # Dot stars
            draw.ellipse([x + 20, y + 20, x + 28, y + 28], fill=(255, 255, 255, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_galaxy.png"))
    print("Saved pattern_galaxy.png")


def gen_dino():
    """Dino Claws: bold claw scratch marks and stylized reptilian toy scales."""
    img = Image.new("RGBA", (SIZE, SIZE), (40, 140, 60, 255))
    draw = ImageDraw.Draw(img)
    # Hexagonal scale tiling
    h_w = 64
    h_h = 56
    for y in range(0, SIZE + h_h, h_h):
        for x in range(0, SIZE + h_w, h_w):
            ox = (h_w // 2) if (y // h_h) % 2 == 1 else 0
            cx = (x + ox) % SIZE
            draw.regular_polygon((cx, y, 26), 6, fill=(30, 110, 48, 255), outline=(60, 190, 80, 255))
    # Claw slash marks across quadrants
    for cy in [256, 768]:
        for cx in [256, 768]:
            for offset in [-36, 0, 36]:
                points = [(cx + offset - 20, cy - 60), (cx + offset + 20, cy + 60),
                          (cx + offset + 10, cy + 65), (cx + offset - 30, cy - 55)]
                draw.polygon(points, fill=(240, 230, 80, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_dino.png"))
    print("Saved pattern_dino.png")


def gen_hologram():
    """Prism Foil: clean mathematical honeycomb grid with diamond faceted nodes."""
    img = Image.new("RGBA", (SIZE, SIZE), (240, 240, 250, 255))
    draw = ImageDraw.Draw(img)
    hex_r = 40
    step_x = int(hex_r * 1.5)
    step_y = int(hex_r * math.sqrt(3))
    for row in range(-1, SIZE // step_y + 2):
        for col in range(-1, SIZE // step_x + 2):
            cx = col * step_x
            cy = row * step_y + ((step_y // 2) if col % 2 == 1 else 0)
            draw.regular_polygon((cx, cy, hex_r), 6, outline=(120, 140, 180, 255))
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(60, 80, 140, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_hologram.png"))
    print("Saved pattern_hologram.png")


def gen_slime():
    """Toxic Slime: cartoon dripping green slime waves for Zombie Siege reward."""
    img = Image.new("RGBA", (SIZE, SIZE), (20, 60, 25, 255))
    draw = ImageDraw.Draw(img)
    wave_h = 128
    for y in range(0, SIZE, wave_h):
        for x in range(0, SIZE, 64):
            # Slime drip drops
            drip_len = 35 + int(math.sin(x * 0.1) * 25)
            draw.ellipse([x + 10, y + 20, x + 40, y + 20 + drip_len], fill=(90, 230, 40, 255))
            draw.ellipse([x + 16, y + 25 + drip_len, x + 34, y + 40 + drip_len], fill=(120, 255, 60, 255))
        draw.rectangle([0, y, SIZE, y + 24], fill=(90, 230, 40, 255))
    img.save(os.path.join(OUTPUT_DIR, "pattern_slime.png"))
    print("Saved pattern_slime.png")


if __name__ == "__main__":
    create_dir()
    gen_default()
    gen_nitro()
    gen_cyber()
    gen_hazard()
    gen_galaxy()
    gen_dino()
    gen_hologram()
    gen_slime()
    print("All skin patterns generated successfully.")
