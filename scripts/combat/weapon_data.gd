class_name WeaponData
extends Resource
## Configuration for one blaster. This is pure data: the firing logic lives in
## Arsenal, and the look is built by BlasterModel from the Presentation group.

enum FireMode {
	SEMI,     ## One shot per trigger pull.
	AUTO,     ## Fires for as long as the trigger is held.
	SPIN_UP,  ## Must spin its barrels up to speed first, then fires like AUTO.
	MELEE,    ## Close-range foam bat swing (no ammo needed).
}

enum ModelStyle { PISTOL, SPRAYER, ROTARY, DOUBLE, HAMMER, RIFLE, BAT }

@export var id: StringName = &"blaster"
@export var display_name: String = "Blaster"
@export_multiline var description: String = ""
@export var dart: DartData

@export_group("Firing")
@export var fire_mode: FireMode = FireMode.SEMI
@export var shots_per_second: float = 5.0
@export var darts_per_shot: int = 1
## Cone half-angle of random spread, in degrees.
@export var spread_degrees: float = 0.5
@export var spin_up_time: float = 0.0
@export var spin_down_time: float = 0.6
## Movement speed multiplier while this weapon is firing or spun up.
@export var firing_move_multiplier: float = 1.0
## Passive movement speed multiplier while holding this weapon (e.g. light Foam Bat).
@export var hold_move_multiplier: float = 1.0

@export_group("Melee")
@export var melee_range: float = 3.0
@export var melee_arc_degrees: float = 70.0
@export var melee_damage: float = 100.0
@export var melee_knockback: float = 13.5
@export var melee_lift: float = 4.6

@export_group("Ammo")
## Darts per magazine. 0 means belt-fed: it fires straight from the reserve.
@export var magazine_size: int = 8
@export var reserve_max: int = 48
@export var reserve_start: int = 32
@export var reload_time: float = 0.8

@export_group("Feel")
@export var recoil_kick: float = 1.0
@export var camera_shake: float = 0.1
@export var sound: StringName = &"pop"
@export var sound_pitch: float = 1.0
## Aim-Down-Sights zoom FOV. 0 = no zoom. e.g. 35.0 for sniper scope.
@export var zoom_fov: float = 0.0

@export_group("Presentation")
@export var model_style: ModelStyle = ModelStyle.PISTOL
@export var body_color: Color = Color(0.15, 0.45, 1.0)
@export var accent_color: Color = Color(1.0, 0.85, 0.2)
## Where the first-person model sits relative to the camera.
@export var view_offset: Vector3 = Vector3(0.24, -0.2, -0.5)

@export_group("Bot Hints")
@export var ai_min_range: float = 0.0
@export var ai_max_range: float = 40.0
## Higher means bots like this weapon more when the range fits.
@export var ai_preference: float = 1.0


func shot_interval() -> float:
	return 1.0 / maxf(shots_per_second, 0.01)


func is_belt_fed() -> bool:
	return magazine_size <= 0 and not is_melee()


func is_melee() -> bool:
	return fire_mode == FireMode.MELEE
