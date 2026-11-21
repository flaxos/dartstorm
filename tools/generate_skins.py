#!/usr/bin/env python3
"""
Generate crisp, continuous, stylized 1024x1024 vector livery wraps and PBR surface textures for DARTSTORM.
Eliminates fragmented isolated text badges in favor of continuous seamless surface finishes:
- High-tactile molded grip textures
- Carbon fiber weaves and racing stripes
- Glowing cyberpunk PCB circuitry
- Industrial hazard chevrons and diamond tread
- Deep cosmic nebulas and starlight starbursts
- Prehistoric reptilian scute scales and claw lacerations
- Prismatic faceted crystal foil lattices
- Toxic radioactive bio-slime ooze and drip channels
- Fighter aircraft shark mouth and rivet panel seams
- Hot-rod layered flame tongues and magma fissures
"""

import math
import os
import random
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/textures/skins"))
FONT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../assets/fonts/LilitaOne-Regular.ttf"))
SIZE = 1024


def create_dir():
    os.makedirs(OUTPUT_DIR, exist_ok=True)


def get_font(size):
    if os.path.exists(FONT_PATH):
        try:
            return ImageFont.truetype(FONT_PATH, size)
        except Exception:
            pass
    return None


def gen_default():
    """Default: High-tactile molded engineered polymer with panel seams and grip stippling."""
    img = Image.new("RGBA", (SIZE, SIZE), (20, 24, 34, 255))
    draw = ImageDraw.Draw(img)

    # 1. Subtle hex grip matrix across upper and lower chassis
    hex_r = 18
    step_x = int(hex_r * 1.5)
    step_y = int(hex_r * math.sqrt(3))
    for r in range(-1, SIZE // step_y + 2):
        for c in range(-1, SIZE // step_x + 2):
            cx = c * step_x
            cy = r * step_y + ((step_y // 2) if c % 2 == 1 else 0)
            draw.regular_polygon((cx, cy, hex_r - 2), 6, fill=(28, 34, 48, 255), outline=(42, 52, 74, 255))

    # 2. Engineered recessed panel seam lines
    seams = [160, 360, 560, 760, 960]
    for y in seams:
        draw.line([(0, y), (SIZE, y)], fill=(12, 14, 20, 255), width=6)
        draw.line([(0, y + 3), (SIZE, y + 3)], fill=(55, 68, 95, 255), width=2)

    for x in [220, 512, 800]:
        draw.line([(x, 0), (x, SIZE)], fill=(12, 14, 20, 255), width=6)
        draw.line([(x + 3, 0), (x + 3, SIZE)], fill=(55, 68, 95, 255), width=2)

    # 3. High-vis competition safety accents (Speed orange & crisp white)
    for y in [340, 740]:
        draw.rectangle([0, y, SIZE, y + 16], fill=(255, 110, 20, 255))
        draw.rectangle([0, y + 16, SIZE, y + 20], fill=(255, 255, 255, 255))

    # 4. Aerodynamic ventilation louvers / slots
    for start_x in [120, 420, 720]:
        for i in range(5):
            ly = 420 + i * 24
            draw.rounded_rectangle([start_x, ly, start_x + 180, ly + 14], radius=6, fill=(10, 12, 16, 255), outline=(60, 75, 105, 255), width=2)

    # 5. Bold geometric dart chevron badges
    for cx in [280, 580, 880]:
        cy = 240
        draw.polygon([(cx - 40, cy - 30), (cx + 10, cy), (cx - 40, cy + 30), (cx - 20, cy)], fill=(255, 190, 20, 255))
        draw.polygon([(cx, cy - 30), (cx + 50, cy), (cx, cy + 30), (cx + 20, cy)], fill=(255, 110, 20, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_default.png"))
    print("Saved pattern_default.png")


def gen_nitro():
    """Nitro Stripe: Carbon fiber twill weave with bold dual racing stripes and speed chevrons."""
    img = Image.new("RGBA", (SIZE, SIZE), (16, 18, 24, 255))
    draw = ImageDraw.Draw(img)

    # 1. Carbon fiber 2x2 twill weave texture
    cw = 16
    for y in range(0, SIZE, cw * 2):
        for x in range(0, SIZE, cw * 2):
            draw.rectangle([x, y, x + cw, y + cw], fill=(26, 29, 38, 255))
            draw.rectangle([x + cw, y, x + cw * 2, y + cw], fill=(12, 14, 18, 255))
            draw.rectangle([x, y + cw, x + cw, y + cw * 2], fill=(12, 14, 18, 255))
            draw.rectangle([x + cw, y + cw, x + cw * 2, y + cw * 2], fill=(32, 36, 48, 255))

    # 2. Dual central racing stripes running continuously
    s1_x0, s1_x1 = 360, 480
    s2_x0, s2_x1 = 544, 664
    # White base stripes
    draw.rectangle([s1_x0, 0, s1_x1, SIZE], fill=(245, 248, 255, 255))
    draw.rectangle([s2_x0, 0, s2_x1, SIZE], fill=(245, 248, 255, 255))
    # Fiery orange center cores
    draw.rectangle([s1_x0 + 16, 0, s1_x1 - 16, SIZE], fill=(255, 95, 15, 255))
    draw.rectangle([s2_x0 + 16, 0, s2_x1 - 16, SIZE], fill=(255, 95, 15, 255))
    # Thin outer pinstripes
    draw.rectangle([s1_x0 - 12, 0, s1_x0 - 4, SIZE], fill=(255, 215, 30, 255))
    draw.rectangle([s2_x1 + 4, 0, s2_x1 + 12, SIZE], fill=(255, 215, 30, 255))

    # 3. Flanking checkered speed blocks
    for r in range(0, SIZE, 40):
        c_fill = (245, 248, 255, 255) if (r // 40) % 2 == 0 else (16, 18, 24, 255)
        draw.rectangle([280, r, 320, r + 40], fill=c_fill)
        draw.rectangle([704, r, 744, r + 40], fill=c_fill)

    # 4. Aerodynamic speed chevrons
    for y in range(80, SIZE, 160):
        for side in [140, 860]:
            draw.polygon([(side - 40, y), (side + 40, y + 30), (side - 40, y + 60), (side - 15, y + 30)], fill=(255, 95, 15, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_nitro.png"))
    print("Saved pattern_nitro.png")


def gen_cyber():
    """Neon Circuit: Glowing cyberpunk PCB traces, hexagonal nodes, and data bus conduits."""
    img = Image.new("RGBA", (SIZE, SIZE), (8, 12, 22, 255))
    draw = ImageDraw.Draw(img)

    cyan_bright = (0, 255, 240, 255)
    cyan_glow = (0, 180, 210, 220)
    magenta_bright = (255, 20, 170, 255)
    magenta_glow = (200, 10, 130, 200)

    # 1. Subtle hex data grid background
    hex_r = 32
    step_x = int(hex_r * 1.5)
    step_y = int(hex_r * math.sqrt(3))
    for r in range(-1, SIZE // step_y + 2):
        for c in range(-1, SIZE // step_x + 2):
            cx = c * step_x
            cy = r * step_y + ((step_y // 2) if c % 2 == 1 else 0)
            draw.regular_polygon((cx, cy, hex_r), 6, outline=(16, 26, 44, 255))

    # 2. Glowing circuit bus traces with 45-degree angled runs
    random.seed(42)
    for y in range(60, SIZE, 100):
        col = cyan_bright if (y // 100) % 2 == 0 else magenta_bright
        glow = cyan_glow if col == cyan_bright else magenta_glow
        # Glow pass
        draw.line([(0, y), (SIZE, y)], fill=glow, width=10)
        # Core wire pass
        draw.line([(0, y), (SIZE, y)], fill=(255, 255, 255, 255), width=3)
        # Angled conduits
        for x in range(120, SIZE, 180):
            ny = (y + 60) % SIZE
            draw.line([(x, y), (x + 50, ny)], fill=glow, width=8)
            draw.line([(x, y), (x + 50, ny)], fill=col, width=3)
            # Solder terminal node
            draw.ellipse([x + 50 - 10, ny - 10, x + 50 + 10, ny + 10], fill=(255, 255, 255, 255), outline=col, width=3)

    # 3. Microchip processor hex cores
    for cx, cy in [(320, 320), (704, 320), (320, 704), (704, 704)]:
        draw.regular_polygon((cx, cy, 54), 6, fill=(14, 20, 36, 255), outline=cyan_bright, width=4)
        draw.regular_polygon((cx, cy, 32), 6, fill=cyan_glow, outline=(255, 255, 255, 255), width=2)
        # Data pulse radiate bars
        for ang in range(0, 360, 60):
            rad = math.radians(ang)
            px = cx + math.cos(rad) * 72
            py = cy + math.sin(rad) * 72
            draw.line([(cx, cy), (px, py)], fill=cyan_bright, width=3)

    img.save(os.path.join(OUTPUT_DIR, "pattern_cyber.png"))
    print("Saved pattern_cyber.png")


def gen_hazard():
    """Caution Zone: Bold continuous 45-degree black/yellow hazard chevrons and steel diamond tread."""
    img = Image.new("RGBA", (SIZE, SIZE), (255, 205, 10, 255))
    draw = ImageDraw.Draw(img)

    # 1. 45-degree diagonal safety chevrons
    band_w = 90
    dark_col = (20, 22, 26, 255)
    for i in range(-SIZE, SIZE * 2, band_w * 2):
        draw.polygon([(i, 0), (i + band_w, 0), (i + band_w + SIZE, SIZE), (i + SIZE, SIZE)], fill=dark_col)

    # 2. Industrial diamond tread embossing on dark bands
    dt_step = 28
    for y in range(0, SIZE, dt_step):
        for x in range(0, SIZE, dt_step):
            px = x + ((dt_step // 2) if (y // dt_step) % 2 == 1 else 0)
            # Tread bar 1
            draw.line([(px - 6, y - 6), (px + 6, y + 6)], fill=(50, 54, 62, 140), width=3)
            # Tread bar 2
            draw.line([(px + 6, y - 6), (px - 6, y + 6)], fill=(50, 54, 62, 140), width=3)

    # 3. Hazard border caution stripes
    for y in [180, 500, 820]:
        draw.rectangle([0, y, SIZE, y + 24], fill=(220, 35, 25, 255))
        draw.rectangle([0, y + 24, SIZE, y + 28], fill=(255, 255, 255, 255))
        # Trefoil warning icons along the hazard rail
        for x in range(100, SIZE, 200):
            draw.ellipse([x - 12, y + 12 - 12, x + 12, y + 12 + 12], fill=(255, 255, 255, 255))
            draw.ellipse([x - 8, y + 12 - 8, x + 8, y + 12 + 8], fill=(20, 22, 26, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_hazard.png"))
    print("Saved pattern_hazard.png")


def gen_galaxy():
    """Cosmic Pop: Deep multi-spectral nebula clouds, shimmering starfields and cross-flare starbursts."""
    img = Image.new("RGBA", (SIZE, SIZE), (12, 8, 26, 255))
    draw = ImageDraw.Draw(img)

    # 1. Layered cosmic nebula dust clouds (soft gradients)
    random.seed(1337)
    nebula_colors = [
        (130, 20, 160, 60),  # Deep violet
        (220, 30, 150, 50),  # Magenta
        (0, 160, 230, 45),   # Cosmic cyan
        (60, 20, 120, 70),   # Purple void
    ]
    for _ in range(80):
        cx = random.randint(0, SIZE)
        cy = random.randint(0, SIZE)
        rad = random.randint(80, 240)
        col = random.choice(nebula_colors)
        draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=col)

    # 2. Fine star dust field
    for _ in range(600):
        sx = random.randint(0, SIZE - 1)
        sy = random.randint(0, SIZE - 1)
        sr = random.choice([1, 1, 2, 2, 3])
        brightness = random.randint(180, 255)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(brightness, brightness, 255, 240))

    # 3. Brilliant 4-point cross-flare starbursts
    star_positions = [
        (180, 220), (450, 160), (780, 280),
        (260, 600), (620, 520), (880, 720),
        (140, 840), (512, 860)
    ]
    for sx, sy in star_positions:
        s_rad = 36
        # Cross flare spikes
        draw.polygon([(sx, sy - s_rad), (sx + 4, sy - 6), (sx + s_rad, sy), (sx + 4, sy + 6),
                      (sx, sy + s_rad), (sx - 4, sy + 6), (sx - s_rad, sy), (sx - 4, sy - 6)],
                     fill=(255, 255, 255, 255))
        # Inner warm glow
        draw.ellipse([sx - 10, sy - 10, sx + 10, sy + 10], fill=(255, 230, 120, 255))
        draw.ellipse([sx - 4, sy - 4, sx + 4, sy + 4], fill=(255, 255, 255, 255))

    # 4. Planetary orbital ring arcs
    for cx, cy in [(340, 420), (740, 680)]:
        draw.ellipse([cx - 160, cy - 50, cx + 160, cy + 50], outline=(0, 230, 255, 160), width=6)
        draw.ellipse([cx - 120, cy - 35, cx + 120, cy + 35], outline=(255, 80, 200, 140), width=4)

    img.save(os.path.join(OUTPUT_DIR, "pattern_galaxy.png"))
    print("Saved pattern_galaxy.png")


def gen_dino():
    """Dino Claws: Interlocking reptilian scute scales, predator claw lacerations, and bone markings."""
    img = Image.new("RGBA", (SIZE, SIZE), (24, 68, 36, 255))
    draw = ImageDraw.Draw(img)

    # 1. Interlocking reptilian scute scales
    scale_w = 48
    scale_h = 40
    for r in range(-1, SIZE // scale_h + 2):
        for c in range(-1, SIZE // scale_w + 2):
            cx = c * scale_w + ((scale_w // 2) if r % 2 == 1 else 0)
            cy = r * scale_h
            # Shaded scale body
            draw.regular_polygon((cx, cy, 22), 6, fill=(34, 98, 48, 255), outline=(18, 50, 26, 255))
            # Scale highlight facet
            draw.regular_polygon((cx - 2, cy - 2, 10), 6, fill=(58, 148, 76, 255))

    # 2. Giant ferocious 3-claw predator slash marks
    for x_base, y_base in [(240, 200), (680, 560)]:
        for i, offset_x in enumerate([-45, 0, 45]):
            # Dark bloody under-flesh
            p_top = (x_base + offset_x - 20, y_base)
            p_bot = (x_base + offset_x + 35, y_base + 240)
            draw.line([p_top, p_bot], fill=(160, 20, 20, 255), width=24)
            # Searing bone / predator scratch core
            draw.line([p_top, p_bot], fill=(255, 230, 60, 255), width=10)
            draw.line([p_top, p_bot], fill=(255, 255, 255, 255), width=3)

    # 3. Prehistoric amber warning stripes
    for y in [380, 840]:
        draw.rectangle([0, y, SIZE, y + 20], fill=(230, 140, 15, 255))
        draw.rectangle([0, y + 20, SIZE, y + 24], fill=(255, 230, 80, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_dino.png"))
    print("Saved pattern_dino.png")


def gen_hologram():
    """Prism Foil: Faceted diamond crystal lattice and prismatic holographic diffraction grating."""
    img = Image.new("RGBA", (SIZE, SIZE), (240, 245, 255, 255))
    draw = ImageDraw.Draw(img)

    # 1. Diamond kaleidoscope crystal facets
    step = 64
    for y in range(0, SIZE + step, step):
        for x in range(0, SIZE + step, step):
            # Alternating prism shading
            fill_1 = (220, 235, 255, 255) if (x + y) % (step * 2) == 0 else (200, 215, 250, 255)
            fill_2 = (180, 200, 245, 255) if (x + y) % (step * 2) == 0 else (240, 250, 255, 255)
            draw.polygon([(x, y - step // 2), (x + step // 2, y), (x, y + step // 2), (x - step // 2, y)], fill=fill_1, outline=(130, 160, 220, 255))
            draw.line([(x - step // 2, y), (x + step // 2, y)], fill=(255, 255, 255, 255), width=2)
            draw.line([(x, y - step // 2), (x, y + step // 2)], fill=(110, 140, 210, 255), width=2)

    # 2. Prismatic rainbow dispersion lattice lines
    for y in range(120, SIZE, 240):
        draw.line([(0, y), (SIZE, y)], fill=(120, 180, 255, 255), width=6)
        draw.line([(0, y + 4), (SIZE, y + 4)], fill=(255, 120, 220, 255), width=4)
        draw.line([(0, y + 8), (SIZE, y + 8)], fill=(120, 255, 220, 255), width=4)

    # 3. Concentric starburst prism emblems
    for cx, cy in [(280, 360), (740, 360), (512, 720)]:
        for r, col in [(60, (140, 180, 255, 180)), (44, (255, 140, 220, 200)), (28, (255, 255, 255, 255))]:
            draw.regular_polygon((cx, cy, r), 8, outline=col, width=3)
        draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_hologram.png"))
    print("Saved pattern_hologram.png")


def gen_slime():
    """Toxic Slime: Acidic biohazard ooze, dripping slime tendrils and bioluminescent chemical bubbles."""
    img = Image.new("RGBA", (SIZE, SIZE), (16, 28, 14, 255))
    draw = ImageDraw.Draw(img)

    neon_green = (80, 255, 30, 255)
    bright_lime = (160, 255, 50, 255)
    deep_ooze = (34, 140, 20, 255)

    # 1. Dripping ooze wave channels
    for y_base in [160, 480, 800]:
        # Upper slime blanket
        draw.rectangle([0, y_base, SIZE, y_base + 60], fill=deep_ooze)
        draw.rectangle([0, y_base + 60, SIZE, y_base + 80], fill=neon_green)
        draw.rectangle([0, y_base + 80, SIZE, y_base + 88], fill=bright_lime)

        # Dripping tendrils
        for x in range(30, SIZE, 64):
            drip_len = 50 + int(math.sin(x * 0.12) * 45) + (x % 30)
            # Tapered teardrop drip
            draw.polygon([(x - 14, y_base + 80), (x + 14, y_base + 80), (x + 10, y_base + 80 + drip_len), (x - 10, y_base + 80 + drip_len)], fill=neon_green)
            draw.ellipse([x - 18, y_base + 70 + drip_len, x + 18, y_base + 100 + drip_len], fill=bright_lime)
            draw.ellipse([x - 8, y_base + 75 + drip_len, x + 8, y_base + 90 + drip_len], fill=(255, 255, 255, 255))

    # 2. Toxic bubbling ooze pockets
    random.seed(999)
    for _ in range(70):
        bx = random.randint(0, SIZE - 1)
        by = random.randint(0, SIZE - 1)
        br = random.randint(8, 24)
        draw.ellipse([bx - br, by - br, bx + br, by + br], fill=deep_ooze, outline=neon_green, width=3)
        draw.ellipse([bx - br // 2, by - br // 2, bx - 2, by - 2], fill=bright_lime)

    img.save(os.path.join(OUTPUT_DIR, "pattern_slime.png"))
    print("Saved pattern_slime.png")


def gen_shark():
    """Shark Bite: Naval fighter aircraft camouflage, steel rivet seams, and ferocious shark mouth jaw."""
    img = Image.new("RGBA", (SIZE, SIZE), (44, 58, 76, 255))
    draw = ImageDraw.Draw(img)

    # 1. Fighter fuselage panel seams with steel flush rivets
    for y in [180, 460, 740]:
        draw.line([(0, y), (SIZE, y)], fill=(24, 32, 44, 255), width=6)
        draw.line([(0, y + 3), (SIZE, y + 3)], fill=(75, 95, 120, 255), width=2)
        for x in range(20, SIZE, 40):
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(160, 180, 205, 255), outline=(24, 32, 44, 255))

    # 2. Menacing predator shark eye
    for cx, cy in [(320, 320), (740, 600)]:
        # Eye socket
        draw.ellipse([cx - 70, cy - 45, cx + 70, cy + 45], fill=(240, 245, 250, 255), outline=(15, 20, 28, 255), width=8)
        # Menacing gold iris
        draw.ellipse([cx - 35, cy - 35, cx + 35, cy + 35], fill=(255, 195, 10, 255))
        # Predatory slit pupil
        draw.ellipse([cx - 12, cy - 32, cx + 12, cy + 32], fill=(12, 14, 18, 255))

    # 3. Ferocious shark mouth with razor white teeth
    # Red inner maw
    mouth_box = [120, 540, 904, 700]
    draw.polygon([(mouth_box[0], mouth_box[1] + 80), (320, mouth_box[1]), (704, mouth_box[1]),
                  (mouth_box[2], mouth_box[1] + 80), (512, mouth_box[3])],
                 fill=(210, 28, 38, 255), outline=(20, 24, 32, 255), width=8)
    # Upper row of predator teeth
    for tx in range(220, 820, 50):
        draw.polygon([(tx, mouth_box[1] + 10), (tx + 22, mouth_box[1] + 70), (tx + 44, mouth_box[1] + 10)], fill=(255, 255, 255, 255), outline=(20, 24, 32, 255), width=2)
    # Lower row of predator teeth
    for tx in range(260, 780, 50):
        draw.polygon([(tx, mouth_box[3] - 20), (tx + 22, mouth_box[3] - 80), (tx + 44, mouth_box[3] - 20)], fill=(255, 255, 255, 255), outline=(20, 24, 32, 255), width=2)

    # 4. Red air-intake warning chevrons
    for x in range(160, SIZE, 220):
        draw.polygon([(x - 30, 260), (x + 30, 260), (x + 50, 320), (x - 10, 320)], fill=(220, 35, 30, 255))

    img.save(os.path.join(OUTPUT_DIR, "pattern_shark.png"))
    print("Saved pattern_shark.png")


def gen_flames():
    """Hot-Rod Flames: Sweeping multi-layer fiery flame tongues and molten magma fissures."""
    img = Image.new("RGBA", (SIZE, SIZE), (10, 10, 14, 255))
    draw = ImageDraw.Draw(img)

    # 1. Molten magma fissure veins branching across background
    random.seed(777)
    for y in range(80, SIZE, 140):
        draw.line([(0, y), (SIZE, y + 30)], fill=(180, 20, 10, 255), width=8)
        draw.line([(0, y), (SIZE, y + 30)], fill=(255, 120, 15, 255), width=3)
        for x in range(100, SIZE, 160):
            draw.line([(x, y), (x + 40, (y + 80) % SIZE)], fill=(255, 220, 40, 255), width=3)

    # 2. Sweeping hot-rod flame tongues (3-layer gradient)
    def draw_flames(y_base, height, color):
        points = [(0, y_base)]
        step = 64
        for x in range(0, SIZE + step, step):
            fy = y_base - height * (0.65 + 0.35 * math.sin(x * 0.08))
            points.append((x - 22, fy + 45))
            points.append((x, fy))
            points.append((x + 22, fy + 45))
        points.append((SIZE, y_base))
        draw.polygon(points, fill=color)

    for base_y in [460, 960]:
        # Deep candy red base
        draw_flames(base_y, 220, (220, 25, 15, 255))
        # Tangerine orange mid-layer
        draw_flames(base_y, 160, (255, 110, 15, 255))
        # Searing yellow-white hot core tips
        draw_flames(base_y, 95, (255, 235, 60, 255))
        draw_flames(base_y, 45, (255, 255, 230, 255))

    # 3. Flying ember sparks
    for _ in range(90):
        ex = random.randint(0, SIZE - 1)
        ey = random.randint(0, SIZE - 1)
        er = random.randint(2, 6)
        draw.ellipse([ex - er, ey - er, ex + er, ey + er], fill=(255, 200, 40, 240))

    img.save(os.path.join(OUTPUT_DIR, "pattern_flames.png"))
    print("Saved pattern_flames.png")


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
    gen_shark()
    gen_flames()
    print("All 10 next-gen skin and PBR textures generated successfully.")


