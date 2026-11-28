#!/usr/bin/env python3
"""
DARTSTORM v2.0.0 — Blow-Molded Sculpted Toy Blaster Generator
Re-sculpts all 7 modular blaster .glb files (popper, six_shot, storm, sweeper,
whisper, chainstorm, rocket) with chunky rounded bevels, ergonomic curved grips,
flanged safety-orange muzzles, recessed barrel cooling bands, and preserved
socket/moving-part contracts (MuzzleMarker, GripMarker, ForegripMarker, Slide,
Cylinder, PumpSlide, Spinner, Scope, Magazine).
"""

from __future__ import annotations

import math
import os
import sys
from typing import List, Tuple

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_sculpt import (
    MaterialSpec,
    MeshPart,
    NodeSpec,
    bake_ao_cavity,
    beveled_cylinder,
    curved_tube,
    export_glb,
    merge_by_material,
    rounded_box,
    superellipsoid,
    transform_part,
)

BLASTER_MATERIALS: List[MaterialSpec] = [
    MaterialSpec("chassis",  (0.18, 0.50, 0.96, 1.0), roughness=0.30),
    MaterialSpec("hardware", (0.20, 0.26, 0.38, 1.0), roughness=0.28, metallic=0.45),
    MaterialSpec("safety",   (1.00, 0.46, 0.06, 1.0), roughness=0.30),
    MaterialSpec("grip",     (0.11, 0.14, 0.22, 1.0), roughness=0.78),
]


def _box(mat: str, size: Tuple[float, float, float], pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), bevel: float = 0.014) -> MeshPart:
    p = rounded_box(mat, size, bevel=bevel, segs=16, roundness=0.52)
    return transform_part(p, pos=pos, rot_deg=rot)


def _cyl(mat: str, rb: float, rt: float, h: float, pos=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), bevel: float = 0.008, segs: int = 20) -> MeshPart:
    p = beveled_cylinder(mat, rb, rt, h, bevel=bevel, segs=segs)
    return transform_part(p, pos=pos, rot_deg=rot)


def _flanged_muzzle(r: float, length: float, pos: Tuple[float, float, float]) -> List[MeshPart]:
    """Iconic cover-art chunky flared safety-orange toy muzzle cone + bore recess."""
    return [
        _cyl("safety", r * 1.18, r * 1.02, length, pos=pos, rot=(90.0, 0.0, 0.0), bevel=r * 0.22),
        _cyl("hardware", r * 0.72, r * 0.72, 0.012, pos=(pos[0], pos[1], pos[2] - length * 0.46), rot=(90.0, 0.0, 0.0), bevel=0.002),
    ]


def _ergonomic_grip(pos: Tuple[float, float, float], height: float = 0.145, tilt_deg: float = 16.0) -> List[MeshPart]:
    """Contoured rounded rubber toy grip + curved trigger guard + orange toy trigger."""
    parts = [
        _box("grip", (0.056, height, 0.076), pos=pos, rot=(tilt_deg, 0.0, 0.0), bevel=0.018),
        # Flared pommel cap at bottom of grip
        _box("hardware", (0.064, 0.022, 0.086), pos=(pos[0], pos[1] - height * 0.48, pos[2] + 0.018), rot=(tilt_deg, 0.0, 0.0), bevel=0.009),
        # Curved trigger guard loop
        curved_tube("hardware", [
            (pos[0], pos[1] + 0.015, pos[2] - 0.022),
            (pos[0], pos[1] + 0.008, pos[2] - 0.075),
            (pos[0], pos[1] + 0.055, pos[2] - 0.090),
        ], 0.010, segs=10),
        # Bright safety-orange toy trigger
        _box("safety", (0.016, 0.036, 0.020), pos=(pos[0], pos[1] + 0.036, pos[2] - 0.052), rot=(-14.0, 0.0, 0.0), bevel=0.005),
    ]
    return parts


def _marker(name: str, pos: Tuple[float, float, float]) -> NodeSpec:
    return NodeSpec(name, translation=pos)


# ---------------------------------------------------------------------------
# 1. POPPER (Sculpted Pocket Spring Pistol)
# ---------------------------------------------------------------------------
def build_popper() -> List[NodeSpec]:
    frame: List[MeshPart] = [
        _box("chassis", (0.076, 0.086, 0.255), pos=(0.0, -0.002, -0.052), bevel=0.020),
        # Chunky side decorative ribs
        _box("hardware", (0.084, 0.022, 0.145), pos=(0.0, -0.008, -0.085), bevel=0.008),
        # Under-barrel dart storage nub
        _cyl("safety", 0.015, 0.015, 0.085, pos=(0.0, -0.044, -0.140), rot=(90.0, 0.0, 0.0), bevel=0.005),
        # Sculpted toy barrel
        _cyl("chassis", 0.022, 0.022, 0.130, pos=(0.0, 0.020, -0.175), rot=(90.0, 0.0, 0.0), bevel=0.007),
    ]
    frame.extend(_flanged_muzzle(0.025, 0.044, (0.0, 0.020, -0.235)))
    frame.extend(_ergonomic_grip((0.0, -0.090, 0.044), height=0.145, tilt_deg=16.0))

    # Moving Slide (top Y = 0.064 matching _iron_sight_spec!)
    slide_parts: List[MeshPart] = [
        _box("chassis", (0.074, 0.040, 0.250), pos=(0.0, 0.0, 0.0), bevel=0.015),
        _box("safety",  (0.079, 0.018, 0.068), pos=(0.0, 0.002, 0.072), bevel=0.007),
        _box("hardware", (0.042, 0.014, 0.150), pos=(0.0, 0.018, -0.015), bevel=0.005),
    ]
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(frame)),
        NodeSpec("Slide", translation=(0.0, 0.044, -0.052), parts=merge_by_material(slide_parts)),
        _marker("MuzzleMarker", (0.0, 0.020, -0.260)),
        _marker("GripMarker", (0.0, -0.082, 0.048)),
        _marker("EjectionMarker", (0.042, 0.050, -0.030)),
    ]


# ---------------------------------------------------------------------------
# 2. SIX-SHOT (Chunky 6-Dart Toy Revolver — Foam Hammer / Hydro Soaker)
# ---------------------------------------------------------------------------
def build_six_shot() -> List[NodeSpec]:
    frame: List[MeshPart] = [
        _box("chassis", (0.078, 0.104, 0.295), pos=(0.0, 0.0, -0.065), bevel=0.022),
        # Sculpted top barrel rib (top Y = 0.078 matching _iron_sight_spec!)
        _box("chassis", (0.068, 0.036, 0.235), pos=(0.0, 0.060, -0.125), bevel=0.012),
        _box("safety",  (0.072, 0.014, 0.090), pos=(0.0, 0.058, -0.165), bevel=0.005),
        # Fluted chunky front barrel
        _cyl("chassis", 0.029, 0.026, 0.165, pos=(0.0, 0.028, -0.215), rot=(90.0, 0.0, 0.0), bevel=0.008),
        # Rear thumb-priming hammer
        _box("safety",  (0.024, 0.044, 0.036), pos=(0.0, 0.066, 0.064), rot=(-22.0, 0.0, 0.0), bevel=0.009),
    ]
    frame.extend(_flanged_muzzle(0.033, 0.052, (0.0, 0.028, -0.295)))
    frame.extend(_ergonomic_grip((0.0, -0.098, 0.060), height=0.152, tilt_deg=20.0))

    # Revolving 6-Dart Toy Drum
    cyl_parts: List[MeshPart] = [
        _cyl("hardware", 0.054, 0.054, 0.105, pos=(0.0, 0.0, 0.0), rot=(90.0, 0.0, 0.0), bevel=0.012),
    ]
    for i in range(6):
        ang = i * math.tau / 6.0
        cx, cy = math.sin(ang) * 0.035, math.cos(ang) * 0.035
        cyl_parts.append(_cyl("safety", 0.014, 0.014, 0.096, pos=(cx, cy, -0.014), rot=(90.0, 0.0, 0.0), bevel=0.004, segs=12))
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(frame)),
        NodeSpec("Cylinder", translation=(0.0, 0.010, -0.062), parts=merge_by_material(cyl_parts)),
        _marker("MuzzleMarker", (0.0, 0.028, -0.325)),
        _marker("GripMarker", (0.0, -0.090, 0.068)),
    ]


# ---------------------------------------------------------------------------
# 3. STORM (Sculpted Bullpup SMG — Dart Sprayer / Ricochet Ranger)
# ---------------------------------------------------------------------------
def build_storm() -> List[NodeSpec]:
    body: List[MeshPart] = [
        # Chunky blow-molded lower & upper receiver
        _box("chassis", (0.090, 0.122, 0.370), pos=(0.0, 0.002, -0.080), bevel=0.024),
        _box("chassis", (0.084, 0.066, 0.388), pos=(0.0, 0.080, -0.070), bevel=0.018),
        # Side orange racing stripes + tactical cooling vents
        _box("safety",  (0.095, 0.022, 0.210), pos=(0.0, 0.068, -0.105), bevel=0.008),
        # Top Picatinny accessory rail (top Y = 0.130 matching _iron_sight_spec!)
        _box("hardware", (0.044, 0.022, 0.320), pos=(0.0, 0.119, -0.070), bevel=0.006),
        # Rounded barrel shroud & flared orange muzzle
        _cyl("chassis", 0.036, 0.034, 0.185, pos=(0.0, 0.030, -0.325), rot=(90.0, 0.0, 0.0), bevel=0.010),
        # Rear sculpted stock + soft buttpad
        _box("chassis", (0.062, 0.095, 0.160), pos=(0.0, 0.024, 0.150), bevel=0.020),
        _box("grip",    (0.068, 0.128, 0.038), pos=(0.0, 0.018, 0.228), bevel=0.014),
        # Rounded front foregrip handle
        _cyl("grip", 0.024, 0.022, 0.108, pos=(0.0, -0.074, -0.220), bevel=0.008),
    ]
    body.extend(_flanged_muzzle(0.038, 0.056, (0.0, 0.030, -0.425)))
    body.extend(_ergonomic_grip((0.0, -0.100, 0.070), height=0.150, tilt_deg=18.0))

    mag_parts: List[MeshPart] = [
        _box("chassis", (0.054, 0.165, 0.086), pos=(0.0, 0.0, 0.0), rot=(12.0, 0.0, 0.0), bevel=0.014),
        _box("safety",  (0.062, 0.030, 0.096), pos=(0.0, -0.082, -0.016), rot=(12.0, 0.0, 0.0), bevel=0.010),
    ]
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(body)),
        NodeSpec("Magazine", translation=(0.0, -0.120, -0.050), parts=merge_by_material(mag_parts)),
        _marker("MuzzleMarker", (0.0, 0.030, -0.455)),
        _marker("GripMarker", (0.0, -0.090, 0.080)),
        _marker("ForegripMarker", (0.0, -0.070, -0.220)),
    ]


# ---------------------------------------------------------------------------
# 4. SWEEPER (Sculpted Pump-Action Blaster — Double Trouble)
# ---------------------------------------------------------------------------
def build_sweeper() -> List[NodeSpec]:
    body: List[MeshPart] = [
        _box("chassis", (0.096, 0.128, 0.365), pos=(0.0, 0.008, -0.065), bevel=0.026),
        _box("hardware", (0.048, 0.020, 0.270), pos=(0.0, 0.078, -0.065), bevel=0.006),
        # Twin chunky side-by-side barrels
        _cyl("chassis", 0.025, 0.025, 0.250, pos=(-0.026, 0.032, -0.320), rot=(90.0, 0.0, 0.0), bevel=0.007),
        _cyl("chassis", 0.025, 0.025, 0.250, pos=( 0.026, 0.032, -0.320), rot=(90.0, 0.0, 0.0), bevel=0.007),
        # Under-barrel tubular dart magazine
        _cyl("hardware", 0.024, 0.024, 0.270, pos=(0.0, -0.026, -0.295), rot=(90.0, 0.0, 0.0), bevel=0.007),
        # Stock
        _box("chassis", (0.066, 0.105, 0.185), pos=(0.0, -0.008, 0.165), rot=(8.0, 0.0, 0.0), bevel=0.022),
        _box("grip",    (0.070, 0.125, 0.036), pos=(0.0, -0.020, 0.255), bevel=0.014),
    ]
    body.extend(_flanged_muzzle(0.027, 0.048, (-0.026, 0.032, -0.450)))
    body.extend(_flanged_muzzle(0.027, 0.048, ( 0.026, 0.032, -0.450)))
    body.extend(_ergonomic_grip((0.0, -0.096, 0.065), height=0.148, tilt_deg=20.0))

    # Chunky ribbed orange PumpSlide foregrip
    pump_parts: List[MeshPart] = [
        _box("safety", (0.088, 0.078, 0.168), pos=(0.0, 0.0, 0.0), bevel=0.022),
        _box("grip",   (0.092, 0.020, 0.115), pos=(0.0, -0.020, 0.0), bevel=0.008),
    ]
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(body)),
        NodeSpec("PumpSlide", translation=(0.0, -0.030, -0.255), parts=merge_by_material(pump_parts)),
        _marker("MuzzleMarker", (0.0, 0.032, -0.480)),
        _marker("GripMarker", (0.0, -0.088, 0.072)),
        _marker("ForegripMarker", (0.0, -0.045, -0.255)),
    ]


# ---------------------------------------------------------------------------
# 5. WHISPER (Sculpted Precision Toy Sniper — Longshot / Wind / Frost)
# ---------------------------------------------------------------------------
def build_whisper() -> List[NodeSpec]:
    body: List[MeshPart] = [
        _box("chassis", (0.080, 0.112, 0.430), pos=(0.0, 0.004, -0.085), bevel=0.024),
        _box("safety",  (0.084, 0.022, 0.250), pos=(0.0, 0.028, -0.145), bevel=0.008),
        # Long fluted precision toy barrel + orange crown tip
        _cyl("chassis", 0.026, 0.022, 0.390, pos=(0.0, 0.030, -0.455), rot=(90.0, 0.0, 0.0), bevel=0.008),
        _cyl("hardware", 0.032, 0.032, 0.040, pos=(0.0, 0.030, -0.340), rot=(90.0, 0.0, 0.0), bevel=0.008),
        # Cheek-rest precision stock + rubber pad
        _box("chassis", (0.062, 0.105, 0.220), pos=(0.0, -0.002, 0.205), bevel=0.022),
        _box("safety",  (0.066, 0.026, 0.120), pos=(0.0, 0.056, 0.195), bevel=0.010),
        _box("grip",    (0.066, 0.122, 0.036), pos=(0.0, -0.006, 0.312), bevel=0.014),
        # Magazine
        _box("hardware", (0.048, 0.115, 0.095), pos=(0.0, -0.090, -0.125), bevel=0.012),
    ]
    body.extend(_ergonomic_grip((0.0, -0.096, 0.068), height=0.145, tilt_deg=18.0))

    # Sculpted barrel shroud / suppressor tip (preserves Suppressor contract!)
    suppressor_parts: List[MeshPart] = [
        _cyl("hardware", 0.032, 0.032, 0.140, pos=(0.0, 0.0, 0.0), rot=(90.0, 0.0, 0.0), bevel=0.008),
    ]
    suppressor_parts.extend(_flanged_muzzle(0.030, 0.064, (0.0, 0.0, -0.095)))

    # Built-in chunky stylized toy sniper scope (hidden automatically when aftermarket optic mounted!)
    scope_parts: List[MeshPart] = [
        _box("hardware", (0.026, 0.038, 0.024), pos=(0.0, -0.030, 0.050), bevel=0.005),
        _box("hardware", (0.026, 0.038, 0.024), pos=(0.0, -0.030, -0.070), bevel=0.005),
        _cyl("hardware", 0.028, 0.028, 0.240, pos=(0.0, 0.0, -0.015), rot=(90.0, 0.0, 0.0), bevel=0.008),
        _cyl("chassis",  0.036, 0.032, 0.075, pos=(0.0, 0.0, -0.145), rot=(90.0, 0.0, 0.0), bevel=0.010),
        _cyl("safety",   0.033, 0.033, 0.040, pos=(0.0, 0.0, 0.115), rot=(90.0, 0.0, 0.0), bevel=0.008),
    ]
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(body)),
        NodeSpec("Suppressor", translation=(0.0, 0.030, -0.570), parts=merge_by_material(suppressor_parts)),
        NodeSpec("Scope", translation=(0.0, 0.118, -0.055), parts=merge_by_material(scope_parts)),
        _marker("MuzzleMarker", (0.0, 0.030, -0.700)),
        _marker("GripMarker", (0.0, -0.088, 0.075)),
        _marker("ForegripMarker", (0.0, -0.045, -0.275)),
    ]


# ---------------------------------------------------------------------------
# 6. CHAINSTORM (FLAX'S CHAINSTORM — Hero Six-Barrel Rotary Foam Cannon!)
# ---------------------------------------------------------------------------
def build_chainstorm() -> List[NodeSpec]:
    body: List[MeshPart] = [
        # Chunky oversized blow-molded royal-blue housing (cover_art.jpg!)
        _box("chassis", (0.215, 0.210, 0.355), pos=(0.0, 0.005, 0.035), bevel=0.042),
        # Bold twin safety-orange racing bands wrapping chassis
        _box("safety",  (0.224, 0.036, 0.362), pos=(0.0, 0.062, 0.035), bevel=0.012),
        _box("safety",  (0.224, 0.036, 0.362), pos=(0.0, -0.052, 0.035), bevel=0.012),
        # Rounded front rotary motor collar
        _cyl("chassis", 0.128, 0.118, 0.140, pos=(0.0, 0.005, -0.175), rot=(90.0, 0.0, 0.0), bevel=0.024),
        _cyl("safety",  0.132, 0.132, 0.032, pos=(0.0, 0.005, -0.140), rot=(90.0, 0.0, 0.0), bevel=0.010),
        # Iconic arched chunky top carry handle (curved tube!)
        curved_tube("chassis", [
            (0.0, 0.100,  0.145),
            (0.0, 0.178,  0.125),
            (0.0, 0.184, -0.055),
            (0.0, 0.100, -0.095),
        ], 0.024, segs=12),
        _box("safety", (0.044, 0.034, 0.145), pos=(0.0, 0.184, 0.030), bevel=0.012),
        # Oversized rounded side ammo drum & feed chute (+X side for animated dart belt!)
        _cyl("chassis", 0.088, 0.088, 0.135, pos=(0.142, -0.035, 0.055), rot=(0.0, 0.0, 90.0), bevel=0.024),
        _cyl("safety",  0.052, 0.052, 0.148, pos=(0.142, -0.035, 0.055), rot=(0.0, 0.0, 90.0), bevel=0.014),
        # Rear rounded motor end-cap + rear grip handle
        _box("grip", (0.115, 0.145, 0.075), pos=(0.0, 0.005, 0.225), bevel=0.024),
        _box("grip", (0.062, 0.165, 0.076), pos=(0.0, -0.155, 0.145), rot=(14.0, 0.0, 0.0), bevel=0.020),
    ]

    # Six chunky spinning safety-orange foam barrels + twin cobalt stabilizer rings!
    spinner_parts: List[MeshPart] = [
        _cyl("hardware", 0.036, 0.036, 0.490, pos=(0.0, 0.0, -0.245), rot=(90.0, 0.0, 0.0), bevel=0.010),
        # Two chunky blue barrel clamp rings (cover_art.jpg!)
        _cyl("chassis",  0.118, 0.118, 0.042, pos=(0.0, 0.0, -0.175), rot=(90.0, 0.0, 0.0), bevel=0.012),
        _cyl("chassis",  0.118, 0.118, 0.042, pos=(0.0, 0.0, -0.375), rot=(90.0, 0.0, 0.0), bevel=0.012),
    ]
    for i in range(6):
        ang = i * math.tau / 6.0
        bx, by = math.cos(ang) * 0.076, math.sin(ang) * 0.076
        spinner_parts.append(_cyl("safety", 0.026, 0.026, 0.480, pos=(bx, by, -0.240), rot=(90.0, 0.0, 0.0), bevel=0.006, segs=16))
        spinner_parts.extend(_flanged_muzzle(0.029, 0.054, (bx, by, -0.495)))

    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(body)),
        NodeSpec("Spinner", translation=(0.0, 0.005, -0.225), parts=merge_by_material(spinner_parts)),
        _marker("MuzzleMarker", (0.0, 0.005, -0.760)),
        _marker("GripMarker", (0.0, -0.130, 0.150)),
        _marker("ForegripMarker", (0.0, 0.180, 0.025)),
    ]


# ---------------------------------------------------------------------------
# 7. ROCKET (Sculpted Heavy Elemental Launcher — Thunder Cannon)
# ---------------------------------------------------------------------------
def build_rocket() -> List[NodeSpec]:
    body: List[MeshPart] = [
        _cyl("chassis", 0.078, 0.088, 0.500, pos=(0.0, 0.025, -0.145), rot=(90.0, 0.0, 0.0), bevel=0.022),
        # Flared chunky orange energy blast bell
        _cyl("safety",  0.105, 0.082, 0.120, pos=(0.0, 0.025, -0.435), rot=(90.0, 0.0, 0.0), bevel=0.024),
        _cyl("hardware", 0.068, 0.068, 0.020, pos=(0.0, 0.025, -0.490), rot=(90.0, 0.0, 0.0), bevel=0.005),
        # Twin side elemental capacitor coils
        _cyl("safety", 0.032, 0.032, 0.240, pos=(-0.086, 0.025, -0.175), rot=(90.0, 0.0, 0.0), bevel=0.012),
        _cyl("safety", 0.032, 0.032, 0.240, pos=( 0.086, 0.025, -0.175), rot=(90.0, 0.0, 0.0), bevel=0.012),
        # Rear exhaust cap + front ergonomic foregrip
        _cyl("grip", 0.076, 0.068, 0.080, pos=(0.0, 0.025, 0.130), rot=(90.0, 0.0, 0.0), bevel=0.018),
        _cyl("grip", 0.026, 0.024, 0.120, pos=(0.0, -0.085, -0.265), bevel=0.009),
    ]
    body.extend(_ergonomic_grip((0.0, -0.098, 0.010), height=0.145, tilt_deg=14.0))
    sight_parts: List[MeshPart] = [
        _box("hardware", (0.048, 0.024, 0.280), pos=(0.0, 0.0, 0.0), bevel=0.007),
        _box("safety",   (0.018, 0.032, 0.018), pos=(0.0, 0.024, -0.115), bevel=0.005),
    ]
    return [
        NodeSpec("Mesh_Chassis_Body", parts=merge_by_material(body)),
        NodeSpec("Sight", translation=(0.0, 0.114, -0.125), parts=merge_by_material(sight_parts)),
        _marker("MuzzleMarker", (0.0, 0.025, -0.505)),
        _marker("GripMarker", (0.0, -0.090, 0.018)),
        _marker("ForegripMarker", (0.0, -0.080, -0.265)),
    ]


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(repo_root, "assets", "models", "blasters")
    builders = {
        "popper": build_popper,
        "six_shot": build_six_shot,
        "storm": build_storm,
        "sweeper": build_sweeper,
        "whisper": build_whisper,
        "chainstorm": build_chainstorm,
        "rocket": build_rocket,
    }
    for name, fn in builders.items():
        nodes = fn()
        export_glb(
            out_path=os.path.join(out_dir, f"{name}.glb"),
            nodes=nodes,
            materials=BLASTER_MATERIALS,
            root_name=f"Blaster_{name}",
        )


if __name__ == "__main__":
    main()
