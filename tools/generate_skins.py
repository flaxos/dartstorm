#!/usr/bin/env python3
"""
Generate crisp, seamless, stylized 1024x1024 vector-style skin and sticker textures for DARTSTORM.
Features authentic toy decals, brand markings, racing graphics, and die-cut sticker badges.
"""

import math
import os
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


def draw_sticker_badge(draw, bbox, bg_color, border_color=(255, 255, 255, 255), border_w=8):
    """Draws a die-cut vinyl sticker backing badge with rounded corners and a white border."""
    x0, y0, x1, y1 = bbox
    r = 20
    # Outer white die-cut vinyl border
    draw.rounded_rectangle([x0 - border_w, y0 - border_w, x1 + border_w, y1 + border_w], radius=r + border_w, fill=border_color)
    # Inner sticker color
    draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=bg_color)


def gen_default():
    """Default Authentic Nerf: Molded diamond grip + DARTSTORM branding & velocity gauge."""
    img = Image.new("RGBA", (SIZE, SIZE), (210, 215, 225, 255))
    draw = ImageDraw.Draw(img)

    # Molded diamond grip stippling across background
    step = 32
    for y in range(0, SIZE, step):
        for x in range(0, SIZE, step):
            draw.polygon([(x + 16, y), (x + 32, y + 16), (x + 16, y + 32), (x, y + 16)], fill=(195, 200, 212, 255))

    font_large = get_font(72)
    font_med = get_font(36)
    font_small = get_font(24)

    # 1. Main "DARTSTORM" die-cut logo sticker
    draw_sticker_badge(draw, [120, 140, 904, 280], bg_color=(255, 110, 20, 255), border_color=(255, 255, 255, 255), border_w=12)
    if font_large:
        draw.text((150, 155), "DARTSTORM", fill=(255, 255, 255, 255), font=font_large, stroke_width=4, stroke_fill=(15, 30, 70, 255))
    if font_small:
        draw.text((700, 235), "ELEMENTAL", fill=(255, 230, 100, 255), font=font_small)

    # 2. "MAX 120 FPS" velocity dial sticker
    cx, cy, rad = 320, 560, 140
    draw.ellipse([cx - rad - 10, cy - rad - 10, cx + rad + 10, cy + rad + 10], fill=(255, 255, 255, 255))
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(20, 35, 75, 255))
    draw.arc([cx - rad + 20, cy - rad + 20, cx + rad - 20, cy + rad - 20], start=140, end=400, fill=(255, 160, 20, 255), width=16)
    draw.line([(cx, cy), (cx + 65, cy - 65)], fill=(255, 60, 60, 255), width=8)
    draw.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(255, 255, 255, 255))
    if font_med:
        draw.text((cx - 80, cy + 30), "120 FPS", fill=(255, 255, 255, 255), font=font_med)
    if font_small:
        draw.text((cx - 65, cy + 75), "MAX VELOCITY", fill=(255, 210, 50, 255), font=font_small)

    # 3. Yellow/black warning tape badge: "FOAM ONLY"
    draw_sticker_badge(draw, [560, 480, 920, 620], bg_color=(250, 200, 20, 255), border_color=(255, 255, 255, 255), border_w=10)
    for i in range(540, 940, 48):
        draw.polygon([(i, 480), (i + 24, 480), (i + 48, 530), (i + 24, 530)], fill=(25, 25, 30, 255))
    if font_med:
        draw.text((610, 545), "FOAM ONLY", fill=(20, 25, 35, 255), font=font_med)

    # 4. Lightning bolt energy badge
    bx, by = 512, 820
    draw_sticker_badge(draw, [bx - 260, by - 80, bx + 260, by + 80], bg_color=(15, 65, 180, 255), border_w=10)
    # Bolt polygon
    bolt = [(bx - 180, by - 50), (bx - 120, by - 50), (bx - 145, by), (bx - 90, by), (bx - 165, by + 60), (bx - 140, by + 10), (bx - 190, by + 10)]
    draw.polygon(bolt, fill=(255, 230, 40, 255))
    if font_med:
        draw.text((bx - 60, by - 30), "RAPID FIRE // HIGH PSI", fill=(255, 255, 255, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_default.png"))
    print("Saved pattern_default.png")


def gen_nitro():
    """Nitro Stripe: bold racing stripes, 07 roundel, checkered flags, turbo arrows."""
    img = Image.new("RGBA", (SIZE, SIZE), (250, 250, 250, 255))
    draw = ImageDraw.Draw(img)

    # Racing dual stripes
    draw.rectangle([180, 0, 300, SIZE], fill=(20, 25, 35, 255))
    draw.rectangle([340, 0, 460, SIZE], fill=(20, 25, 35, 255))
    draw.rectangle([290, 0, 300, SIZE], fill=(255, 90, 20, 255))
    draw.rectangle([340, 0, 350, SIZE], fill=(255, 90, 20, 255))

    font_large = get_font(120)
    font_med = get_font(42)

    # Racing roundel "07"
    cx, cy, rad = 720, 320, 180
    draw.ellipse([cx - rad - 12, cy - rad - 12, cx + rad + 12, cy + rad + 12], fill=(255, 255, 255, 255))
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 90, 20, 255))
    draw.ellipse([cx - rad + 18, cy - rad + 18, cx + rad - 18, cy + rad - 18], fill=(245, 245, 245, 255))
    if font_large:
        draw.text((cx - 85, cy - 75), "07", fill=(20, 25, 35, 255), font=font_large)

    # Checkered flag pattern
    for r in range(4):
        for c in range(8):
            color = (25, 25, 30, 255) if (r + c) % 2 == 0 else (240, 240, 240, 255)
            draw.rectangle([540 + c * 50, 600 + r * 45, 590 + c * 50, 645 + r * 45], fill=color)

    # "TURBO SPEED" badge
    draw_sticker_badge(draw, [540, 820, 940, 930], bg_color=(255, 90, 20, 255), border_w=10)
    if font_med:
        draw.text((580, 845), "TURBO SPEED", fill=(255, 255, 255, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_nitro.png"))
    print("Saved pattern_nitro.png")


def gen_cyber():
    """Neon Cyber: circuit traces, CPU chip sticker, digital reticle, matrix dots."""
    img = Image.new("RGBA", (SIZE, SIZE), (15, 20, 35, 255))
    draw = ImageDraw.Draw(img)

    # Circuit board traces
    trace_col = (0, 240, 255, 255)
    accent_col = (255, 20, 160, 255)

    for y in range(80, SIZE, 160):
        draw.line([(0, y), (SIZE, y)], fill=trace_col, width=8)
        for x in range(80, SIZE, 200):
            draw.line([(x, y), (x + 60, y + 60)], fill=trace_col, width=8)
            draw.ellipse([x + 60 - 12, y + 60 - 12, x + 60 + 12, y + 60 + 12], fill=accent_col)

    font_med = get_font(36)
    font_small = get_font(24)

    # Microchip processor badge
    draw_sticker_badge(draw, [180, 480, 480, 780], bg_color=(25, 30, 50, 255), border_color=trace_col, border_w=10)
    # Chip pins
    for py in range(520, 750, 28):
        draw.rectangle([150, py, 180, py + 12], fill=(255, 210, 40, 255))
        draw.rectangle([480, py, 510, py + 12], fill=(255, 210, 40, 255))
    if font_med:
        draw.text((230, 580), "CYBER\nCORE", fill=trace_col, font=font_med)
    if font_small:
        draw.text((215, 680), "V2.0 QUANTUM", fill=accent_col, font=font_small)

    # Digital targeting reticle
    rx, ry, rr = 750, 600, 130
    draw.ellipse([rx - rr, ry - rr, rx + rr, ry + rr], outline=trace_col, width=6)
    draw.ellipse([rx - 60, ry - 60, rx + 60, ry + 60], outline=accent_col, width=4)
    draw.line([(rx - rr - 20, ry), (rx + rr + 20, ry)], fill=trace_col, width=4)
    draw.line([(rx, ry - rr - 20), (rx, ry + rr + 20)], fill=trace_col, width=4)

    img.save(os.path.join(OUTPUT_DIR, "pattern_cyber.png"))
    print("Saved pattern_cyber.png")


def gen_hazard():
    """Caution Zone: bold industrial hazard chevrons, radioactive trefoil, caution stencil."""
    img = Image.new("RGBA", (SIZE, SIZE), (250, 205, 20, 255))
    draw = ImageDraw.Draw(img)

    # Chevrons
    sw = 80
    for i in range(-SIZE, SIZE * 2, sw * 2):
        draw.polygon([(i, 0), (i + sw, 0), (i + sw + SIZE, SIZE), (i + SIZE, SIZE)], fill=(25, 25, 30, 255))

    font_large = get_font(52)
    font_med = get_font(32)

    # Biohazard / radioactive trefoil badge
    cx, cy, rad = 320, 480, 160
    draw.ellipse([cx - rad - 12, cy - rad - 12, cx + rad + 12, cy + rad + 12], fill=(255, 255, 255, 255))
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(250, 205, 20, 255))
    # Trefoil petals
    for deg in [90, 210, 330]:
        rad_ang = math.radians(deg)
        px = cx + math.cos(rad_ang) * 65
        py = cy - math.sin(rad_ang) * 65
        draw.ellipse([px - 40, py - 40, px + 40, py + 40], fill=(25, 25, 30, 255))
    draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(25, 25, 30, 255))
    draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=(250, 205, 20, 255))

    # "DANGER: HIGH PSI" die-cut sticker
    draw_sticker_badge(draw, [540, 380, 950, 580], bg_color=(220, 40, 30, 255), border_color=(255, 255, 255, 255), border_w=12)
    if font_large:
        draw.text((580, 405), "DANGER", fill=(255, 255, 255, 255), font=font_large)
    if font_med:
        draw.text((590, 485), "HIGH PRESSURE FOAM", fill=(255, 230, 50, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_hazard.png"))
    print("Saved pattern_hazard.png")


def gen_galaxy():
    """Cosmic Pop: starbursts, planet Saturn ring decal, 8-bit rocket ship badge."""
    img = Image.new("RGBA", (SIZE, SIZE), (25, 15, 50, 255))
    draw = ImageDraw.Draw(img)

    # Stars & sparkles
    for y in range(60, SIZE, 120):
        for x in range(60, SIZE, 120):
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 255, 255, 220))
            if (x + y) % 240 == 0:
                # 4-point starburst
                draw.polygon([(x, y - 24), (x + 6, y - 6), (x + 24, y), (x + 6, y + 6),
                              (x, y + 24), (x - 6, y + 6), (x - 24, y), (x - 6, y - 6)],
                             fill=(255, 220, 50, 255))

    font_med = get_font(38)

    # Saturn planet decal
    px, py = 320, 420
    draw.ellipse([px - 140, py - 45, px + 140, py + 45], outline=(255, 120, 210, 255), width=14)
    draw.ellipse([px - 80, py - 80, px + 80, py + 80], fill=(255, 180, 40, 255))

    # Arcade Rocket Ship sticker
    rx, ry = 720, 540
    draw_sticker_badge(draw, [rx - 150, ry - 180, rx + 150, ry + 180], bg_color=(20, 45, 110, 255), border_w=12)
    # Rocket body
    draw.polygon([(rx, ry - 120), (rx + 45, ry - 20), (rx + 45, ry + 70), (rx - 45, ry + 70), (rx - 45, ry - 20)], fill=(255, 255, 255, 255))
    # Nose cone
    draw.polygon([(rx, ry - 120), (rx + 35, ry - 35), (rx - 35, ry - 35)], fill=(255, 60, 60, 255))
    # Rocket fins
    draw.polygon([(rx - 45, ry + 30), (rx - 90, ry + 80), (rx - 45, ry + 70)], fill=(255, 60, 60, 255))
    draw.polygon([(rx + 45, ry + 30), (rx + 90, ry + 80), (rx + 45, ry + 70)], fill=(255, 60, 60, 255))
    # Porthole
    draw.ellipse([rx - 20, ry - 10, rx + 20, ry + 30], fill=(80, 200, 255, 255))

    if font_med:
        draw.text((rx - 90, ry + 105), "COSMIC", fill=(255, 220, 40, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_galaxy.png"))
    print("Saved pattern_galaxy.png")


def gen_dino():
    """Dino Claws: scale grip, giant 3-claw slash marks, T-Rex skull badge."""
    img = Image.new("RGBA", (SIZE, SIZE), (35, 120, 50, 255))
    draw = ImageDraw.Draw(img)

    # Reptilian scales
    hw, hh = 56, 48
    for y in range(0, SIZE + hh, hh):
        for x in range(0, SIZE + hw, hw):
            ox = (hw // 2) if (y // hh) % 2 == 1 else 0
            cx = (x + ox) % SIZE
            draw.regular_polygon((cx, y, 22), 6, fill=(28, 95, 42, 255), outline=(50, 160, 70, 255))

    # Giant 3-claw slash marks
    for offset in [-60, 0, 60]:
        draw.polygon([(360 + offset - 18, 180), (440 + offset + 18, 480),
                      (430 + offset + 10, 490), (345 + offset - 25, 190)], fill=(255, 235, 60, 255))

    font_large = get_font(52)
    font_med = get_font(34)

    # T-Rex Dino Squad badge
    draw_sticker_badge(draw, [480, 560, 940, 840], bg_color=(18, 55, 28, 255), border_color=(255, 255, 255, 255), border_w=12)
    # Dino jaw vector
    draw.polygon([(520, 640), (620, 590), (680, 620), (660, 710), (560, 730)], fill=(245, 240, 220, 255))
    for tx in [550, 580, 610, 640]:
        draw.polygon([(tx, 710), (tx + 12, 735), (tx + 24, 710)], fill=(255, 255, 255, 255))
    if font_large:
        draw.text((710, 620), "DINO", fill=(255, 220, 50, 255), font=font_large)
    if font_med:
        draw.text((710, 690), "SQUAD", fill=(255, 255, 255, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_dino.png"))
    print("Saved pattern_dino.png")


def gen_hologram():
    """Prism Foil: honeycomb faceted foil grid, iridescent star stickers, trophy badge."""
    img = Image.new("RGBA", (SIZE, SIZE), (245, 245, 255, 255))
    draw = ImageDraw.Draw(img)

    # Prismatic honeycomb grid
    hex_r = 38
    step_x = int(hex_r * 1.5)
    step_y = int(hex_r * math.sqrt(3))
    for row in range(-1, SIZE // step_y + 2):
        for col in range(-1, SIZE // step_x + 2):
            cx = col * step_x
            cy = row * step_y + ((step_y // 2) if col % 2 == 1 else 0)
            draw.regular_polygon((cx, cy, hex_r), 6, outline=(140, 160, 210, 255))
            draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(80, 110, 190, 255))

    font_large = get_font(52)
    font_med = get_font(34)

    # Holographic Champion Trophy Crest
    draw_sticker_badge(draw, [280, 420, 744, 780], bg_color=(30, 40, 80, 255), border_color=(255, 255, 255, 255), border_w=14)
    # Trophy cup
    tx, ty = 512, 530
    draw.polygon([(tx - 60, ty - 60), (tx + 60, ty - 60), (tx + 40, ty + 40), (tx - 40, ty + 40)], fill=(255, 215, 30, 255))
    draw.rectangle([tx - 15, ty + 40, tx + 15, ty + 70], fill=(220, 180, 20, 255))
    draw.rectangle([tx - 45, ty + 70, tx + 45, ty + 95], fill=(255, 215, 30, 255))
    if font_large:
        draw.text((tx - 120, ty + 120), "CHAMPION", fill=(255, 255, 255, 255), font=font_large)

    img.save(os.path.join(OUTPUT_DIR, "pattern_hologram.png"))
    print("Saved pattern_hologram.png")


def gen_slime():
    """Toxic Slime: dripping radioactive green slime waves, biohazard skull sticker."""
    img = Image.new("RGBA", (SIZE, SIZE), (25, 55, 28, 255))
    draw = ImageDraw.Draw(img)

    # Slime drip waves
    for y in [120, 420, 720]:
        draw.rectangle([0, y, SIZE, y + 40], fill=(110, 255, 45, 255))
        for x in range(30, SIZE, 80):
            drip_len = 40 + int(math.sin(x * 0.08) * 35)
            draw.ellipse([x, y + 20, x + 36, y + 20 + drip_len], fill=(110, 255, 45, 255))
            draw.ellipse([x + 4, y + 25 + drip_len, x + 32, y + 50 + drip_len], fill=(160, 255, 80, 255))

    font_large = get_font(52)
    font_med = get_font(34)

    # Biohazard slime skull badge
    draw_sticker_badge(draw, [460, 360, 920, 640], bg_color=(15, 35, 18, 255), border_color=(120, 255, 50, 255), border_w=12)
    if font_large:
        draw.text((510, 400), "BIO-FOAM", fill=(120, 255, 50, 255), font=font_large)
    if font_med:
        draw.text((540, 490), "TOXIC OUTBREAK", fill=(255, 255, 255, 255), font=font_med)

    img.save(os.path.join(OUTPUT_DIR, "pattern_slime.png"))
    print("Saved pattern_slime.png")


def gen_shark():
    """Shark Bite: WW2 Flying Tigers fighter shark teeth, menacing eye, steel rivet seams."""
    img = Image.new("RGBA", (SIZE, SIZE), (70, 85, 105, 255))
    draw = ImageDraw.Draw(img)

    # Steel plate rivet seams
    draw.line([(0, 240), (SIZE, 240)], fill=(45, 55, 70, 255), width=8)
    draw.line([(0, 780), (SIZE, 780)], fill=(45, 55, 70, 255), width=8)
    for x in range(40, SIZE, 90):
        draw.ellipse([x - 6, 240 - 6, x + 6, 240 + 6], fill=(180, 195, 215, 255))
        draw.ellipse([x - 6, 780 - 6, x + 6, 780 + 6], fill=(180, 195, 215, 255))

    font_large = get_font(60)
    font_med = get_font(36)

    # Menacing Shark Eye badge
    ex, ey = 320, 420
    draw.ellipse([ex - 90, ey - 60, ex + 90, ey + 60], fill=(255, 255, 255, 255))
    draw.ellipse([ex - 45, ey - 45, ex + 45, ey + 45], fill=(255, 215, 20, 255))
    draw.ellipse([ex - 20, ey - 40, ex + 20, ey + 40], fill=(15, 15, 20, 255))

    # Shark Mouth with jagged teeth
    # Red gum background
    draw.polygon([(180, 680), (450, 540), (880, 540), (940, 680), (600, 740)], fill=(210, 30, 40, 255))
    # Top teeth
    for tx in range(240, 840, 70):
        draw.polygon([(tx, 540), (tx + 30, 615), (tx + 60, 540)], fill=(255, 255, 255, 255))
    # Bottom teeth
    for tx in range(280, 800, 70):
        draw.polygon([(tx, 710), (tx + 30, 635), (tx + 60, 710)], fill=(255, 255, 255, 255))

    # "SHARK BITE" stencil badge
    draw_sticker_badge(draw, [520, 320, 920, 460], bg_color=(200, 35, 35, 255), border_w=10)
    if font_large:
        draw.text((550, 345), "SHARK BITE", fill=(255, 255, 255, 255), font=font_large)

    img.save(os.path.join(OUTPUT_DIR, "pattern_shark.png"))
    print("Saved pattern_shark.png")


def gen_flames():
    """Hot-Rod Flames: blazing layered fire tongues, skull spark plug, drag racing badge."""
    img = Image.new("RGBA", (SIZE, SIZE), (20, 20, 25, 255))
    draw = ImageDraw.Draw(img)

    # Layered hot-rod flame tongues licking across
    def draw_flame_wave(y_base, height, color):
        points = [(0, y_base)]
        for x in range(0, SIZE + 64, 64):
            fy = y_base - height * (0.6 + 0.4 * math.sin(x * 0.05))
            points.append((x - 24, fy + 40))
            points.append((x, fy))
            points.append((x + 24, fy + 40))
        points.append((SIZE, y_base))
        draw.polygon(points, fill=color)

    # Red flame layer
    draw_flame_wave(920, 380, (215, 30, 20, 255))
    # Orange flame layer
    draw_flame_wave(920, 280, (255, 120, 15, 255))
    # Yellow hot tip layer
    draw_flame_wave(920, 160, (255, 230, 40, 255))

    font_large = get_font(64)
    font_med = get_font(36)

    # "FIRE STORM" speed badge
    draw_sticker_badge(draw, [180, 180, 844, 340], bg_color=(220, 40, 20, 255), border_color=(255, 230, 40, 255), border_w=12)
    if font_large:
        draw.text((220, 200), "FIRE STORM", fill=(255, 255, 255, 255), font=font_large)
    if font_med:
        draw.text((360, 275), "HOT-ROD RACING", fill=(255, 220, 40, 255), font=font_med)

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
    print("All 10 skin and sticker patterns generated successfully.")

