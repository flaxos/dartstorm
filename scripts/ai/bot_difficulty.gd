class_name BotDifficulty
extends Resource
## Everything that makes a bot easier or harder. Add a new .tres in
## resources/bots/ to make a new difficulty level.

@export var display_name: String = "Normal"

@export_group("Aim")
## Random cone added to every shot, in degrees. Bigger is sloppier.
@export var aim_error_degrees: float = 5.0
## How fast the bot can turn to track a target.
@export var turn_speed_degrees: float = 220.0
## 0 never leads a moving target, 1 leads perfectly.
@export_range(0.0, 1.0) var lead_factor: float = 0.6

@export_group("Awareness")
## Seconds the bot must see a target before it starts shooting.
@export var reaction_time: float = 0.6
@export var vision_range: float = 40.0
## Field of view in degrees. 360 sees everything around it.
@export var fov_degrees: float = 200.0

@export_group("Trigger")
## Seconds between shots with semi-automatic blasters.
@export var semi_interval: float = 0.45
## How long a burst lasts with automatic blasters.
@export var burst_time: float = 0.7
## Rest between bursts.
@export var burst_pause: float = 0.7

@export_group("Body")
## Multiplies the tag power of this bot's darts.
@export var damage_scale: float = 0.6
@export var move_speed_scale: float = 0.9
