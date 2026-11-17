class_name DartData
extends Resource
## Tunable flight and impact numbers for one kind of foam dart.
## Weapons point at a DartData, so new dart types need no code.

enum Element { NONE, WIND, FIRE, WATER, LIGHTNING, ICE }

@export var display_name: String = "Foam Dart"

@export_group("Flight")
## Launch speed in metres per second.
@export var initial_speed: float = 44.0
## 1.0 is real gravity. Lower values give flatter, friendlier arcs.
@export var gravity_multiplier: float = 0.7
## How strongly wind zones push this dart (0 ignores wind completely).
@export var wind_response: float = 1.0
## Fraction of speed lost per second to air resistance.
@export var air_drag: float = 0.25
## Seconds before the dart is recycled.
@export var max_lifetime: float = 4.0

@export_group("Impact")
## How much of the victim's tag meter one hit fills (meter is 100).
@export var tag_power: float = 34.0
## How many times this dart may bounce off a reflective surface.
@export var max_ricochets: int = 1
## Fraction of speed kept after each ricochet.
@export var ricochet_speed_keep: float = 0.8
## If true the dart bounces off ordinary walls too (Ricochet Ranger).
@export var ricochet_any_surface: bool = false
@export_flags_3d_physics var collision_mask: int = Layers.DART_MASK

@export_group("Look")
@export var visual_scale: float = 1.0

@export_group("Elemental")
@export var element: Element = Element.NONE
## Auxiliary elemental strength (burn ticks, chain damage, or slow percentage).
@export var element_power: float = 0.0
## Seconds the elemental condition lasts on the target.
@export var element_duration: float = 2.0
## Velocity impulse applied to the victim upon hit (metres per second).
@export var knockback_impulse: float = 0.0
## For Lightning darts: max number of nearby rivals to zap in a chain.
@export var chain_count: int = 0
## Search radius for lightning chain targets.
@export var chain_radius: float = 5.0

