class_name WeaponModding
extends RefCounted
## Backyard Modding & Blaster Mastery System:
## Defines aftermarket attachment slots, attachments catalog, stat modifiers,
## and weapon mastery progression. 100% kid-safe and earned purely through gameplay.

enum Slot {
	NONE = -1,
	OPTIC = 0,
	BARREL = 1,
	SPRING = 2,
	MAGAZINE = 3,
	STOCK = 4,
}

const SLOT_NAMES: Dictionary = {
	Slot.OPTIC: "OPTIC",
	Slot.BARREL: "BARREL",
	Slot.SPRING: "SPRING",
	Slot.MAGAZINE: "MAGAZINE",
	Slot.STOCK: "STOCK",
}

const SLOT_ICONS: Dictionary = {
	Slot.OPTIC: "[OPT]",
	Slot.BARREL: "[BRL]",
	Slot.SPRING: "[SPR]",
	Slot.MAGAZINE: "[MAG]",
	Slot.STOCK: "[STK]",
}

## Standard 7 blasters in the arsenal that support workbench modding
const WORKBENCH_BLASTERS: Array[Dictionary] = [
	{
		"id": &"pocket_popper",
		"name": "Pocket Popper",
		"base_model": &"popper",
		"res_path": "res://resources/weapons/pocket_popper.tres",
		"desc": "Compact single-shot spring pistol. High mobility and snappy handling.",
		"icon": "I"
	},
	{
		"id": &"ricochet_ranger",
		"alias_id": &"six_shot",
		"name": "Ricochet Ranger",
		"base_model": &"six_shot",
		"res_path": "res://resources/weapons/ricochet_ranger.tres",
		"desc": "Heavy revolving 6-dart cylinder. Hard-hitting ricochet rounds.",
		"icon": "II"
	},
	{
		"id": &"dart_sprayer",
		"name": "Dart Sprayer",
		"base_model": &"storm",
		"res_path": "res://resources/weapons/dart_sprayer.tres",
		"desc": "Full-auto motorized dart blaster. Rapid-fire lawn control.",
		"icon": "III"
	},
	{
		"id": &"double_trouble",
		"name": "Double Trouble",
		"base_model": &"sweeper",
		"res_path": "res://resources/weapons/double_trouble.tres",
		"desc": "Pump-action dual-barrel blaster. Fires two darts in wide spread.",
		"icon": "IV"
	},
	{
		"id": &"longshot",
		"name": "Longshot",
		"base_model": &"whisper",
		"res_path": "res://resources/weapons/longshot.tres",
		"desc": "Bolt-action precision marksman rifle. Unmatched range and accuracy.",
		"icon": "V"
	},
	{
		"id": &"flaxs_chainstorm",
		"name": "Flax's Chainstorm",
		"base_model": &"chainstorm",
		"res_path": "res://resources/weapons/flaxs_chainstorm.tres",
		"desc": "Rotating 6-barrel belt-fed heavy minigun. Massive suppressing firepower.",
		"icon": "VI"
	},
	{
		"id": &"thunder_cannon",
		"name": "Thunder Cannon",
		"base_model": &"rocket",
		"res_path": "res://resources/weapons/thunder_cannon.tres",
		"desc": "High-pressure rocket blaster with heavy explosive foam warheads.",
		"icon": "VII"
	},
]

## Weapon Mastery Curves (Ranks 1 to 10)
const MAX_MASTERY_RANK := 10
const XP_PER_WEAPON_TAG := 50
const XP_RICOCHET_BONUS := 25

const MASTERY_THRESHOLDS: Array[int] = [
	0,     # Rank 1: Stock (Starter)
	100,   # Rank 2: Novice Modder (2 tags)
	250,   # Rank 3: Tinkerer (5 tags)
	500,   # Rank 4: Backyard Craftsman (10 tags)
	850,   # Rank 5: Foam Gunsmith (17 tags)
	1300,  # Rank 6: Elite Mechanic (26 tags)
	1850,  # Rank 7: Master Blaster (37 tags)
	2500,  # Rank 8: Tactical Artisan (50 tags)
	3300,  # Rank 9: Workshop Legend (66 tags)
	4500,  # Rank 10: Grandmaster (90 tags - GOLD MASTERY UNLOCKED)
]

const MASTERY_TITLES: Array[String] = [
	"Stock Issue",
	"Novice Modder",
	"Backyard Tinkerer",
	"Foam Craftsman",
	"Garage Gunsmith",
	"Elite Mechanic",
	"Master Blaster",
	"Tactical Artisan",
	"Workshop Legend",
	"Grandmaster",
]

## Complete Aftermarket Attachment Catalog
## Stats keys:
##   spread_mult: float (1.0 = normal, 0.7 = 30% tighter spread)
##   velocity_mult: float (1.0 = normal, 1.2 = 20% faster dart speed)
##   tag_power_mult: float (1.0 = normal, 1.15 = +15% tag power)
##   recoil_mult: float (1.0 = normal, 0.65 = 35% less recoil)
##   rate_mult: float (1.0 = normal, 1.25 = 25% faster fire rate)
##   mag_bonus: int (extra dart capacity in clip)
##   reload_mult: float (0.6 = 40% faster reload)
##   gravity_mult: float (0.7 = less dart drop)
##   zoom_fov: float (ADS zoom target FOV, 0.0 = no zoom)
##   reticle: StringName (&"standard", &"red_dot", &"holo", &"scope")
##   sound_override: StringName (&"" or sound effect)
const ATTACHMENTS: Array[Dictionary] = [
	# --- OPTICS (Sights & Scopes) ---
	{
		"id": &"iron_sights",
		"name": "Standard Iron Sights",
		"slot": Slot.OPTIC,
		"rank": 1,
		"desc": "Factory molded plastic post and notch sights. Reliable and unobstructed.",
		"pros": ["Clear peripheral view", "Standard handling"],
		"cons": ["No magnification"],
		"stats": {"zoom_fov": 0.0, "reticle": &"standard"}
	},
	{
		"id": &"red_dot",
		"name": "Reflex Red Dot",
		"slot": Slot.OPTIC,
		"rank": 2,
		"desc": "3D-printed reflex optic with illuminated red center pip. Fast target acquisition.",
		"pros": ["Crisp red dot reticle", "Gentle target zoom (65° FOV)", "+10% aim recovery"],
		"cons": ["Slight optic frame obstruction"],
		"stats": {"zoom_fov": 65.0, "reticle": &"red_dot", "recoil_mult": 0.9}
	},
	{
		"id": &"holo_sight",
		"name": "Holographic Sight",
		"slot": Slot.OPTIC,
		"rank": 4,
		"desc": "Chunky hooded holographic sight projecting an orange/cyan circle-dot reticle.",
		"pros": ["Wide holographic window", "Precision circle reticle (55° FOV)", "-15% moving spread"],
		"cons": ["Heavier frame"],
		"stats": {"zoom_fov": 55.0, "reticle": &"holo", "spread_mult": 0.85}
	},
	{
		"id": &"marksman_scope",
		"name": "4x Marksman Scope",
		"slot": Slot.OPTIC,
		"rank": 6,
		"desc": "Dual-ring high-magnification spyglass with precision range elevation crosshairs.",
		"pros": ["Extreme zoom (35° FOV)", "Elevation marks for long-range darts", "+20% effective range"],
		"cons": ["Tunnel vision while aiming", "Narrow field of view"],
		"stats": {"zoom_fov": 35.0, "reticle": &"scope", "velocity_mult": 1.1}
	},

	# --- BARRELS & MUZZLES ---
	{
		"id": &"stock_barrel",
		"name": "Factory Muzzle",
		"slot": Slot.BARREL,
		"rank": 1,
		"desc": "Standard orange safety barrel tip.",
		"pros": ["Balanced maneuverability"],
		"cons": ["Standard dart spread"],
		"stats": {}
	},
	{
		"id": &"rifled_extension",
		"name": "Rifled Guide Tube",
		"slot": Slot.BARREL,
		"rank": 3,
		"desc": "Extended smooth-bore PVC barrel with internal spiral rifling grooves.",
		"pros": ["-30% dart spread cone", "+15% dart velocity"],
		"cons": ["Longer front profile"],
		"stats": {"spread_mult": 0.70, "velocity_mult": 1.15}
	},
	{
		"id": &"mega_compensator",
		"name": "Ported Compensator",
		"slot": Slot.BARREL,
		"rank": 5,
		"desc": "Machined muzzle brake with dual horizontal gas ports to redirect muzzle blast.",
		"pros": ["-35% recoil kick", "-25% muzzle climb"],
		"cons": ["Louder dart pop"],
		"stats": {"recoil_mult": 0.65}
	},
	{
		"id": &"whisper_shroud",
		"name": "Foam Whisper Shroud",
		"slot": Slot.BARREL,
		"rank": 7,
		"desc": "Ribbed cardboard silencer tube with internal foam acoustic baffling rings.",
		"pros": ["-50% audible sound radius", "Muffled pop sound", "Stealthy profile"],
		"cons": ["-5% dart velocity"],
		"stats": {"velocity_mult": 0.95, "sound_override": &"whoosh"}
	},

	# --- SPRINGS & INTERNAL MECHANISMS ---
	{
		"id": &"stock_spring",
		"name": "Factory Spring",
		"slot": Slot.SPRING,
		"rank": 1,
		"desc": "Standard toy manufacturer coil spring.",
		"pros": ["Reliable stock performance"],
		"cons": ["Moderate dart power"],
		"stats": {}
	},
	{
		"id": &"heavy_spring",
		"name": "Heavy-Duty Spring Mod",
		"slot": Slot.SPRING,
		"rank": 2,
		"desc": "Stiff tempered steel replacement spring salvaged from the garage toolbox.",
		"pros": ["+20% dart velocity", "+15% tag power"],
		"cons": ["+15% recoil kick"],
		"stats": {"velocity_mult": 1.20, "tag_power_mult": 1.15, "recoil_mult": 1.15}
	},
	{
		"id": &"hair_trigger",
		"name": "Hair-Trigger Sear",
		"slot": Slot.SPRING,
		"rank": 4,
		"desc": "Polished trigger catch with lightened return spring for instant shot response.",
		"pros": ["+25% semi-auto fire rate", "Instant shot response"],
		"cons": ["Requires disciplined trigger finger"],
		"stats": {"rate_mult": 1.25}
	},
	{
		"id": &"sealed_breech",
		"name": "Brass Sealed Breech",
		"slot": Slot.SPRING,
		"rank": 6,
		"desc": "Precision airtight brass plunger tube and high-compression rubber O-ring.",
		"pros": ["30% less dart drop (flatter trajectory)", "+15% tag power", "+15% velocity"],
		"cons": ["Takes craftsmanship to maintain"],
		"stats": {"gravity_mult": 0.70, "tag_power_mult": 1.15, "velocity_mult": 1.15}
	},

	# --- MAGAZINES & FEED SYSTEMS ---
	{
		"id": &"stock_mag",
		"name": "Standard Magazine",
		"slot": Slot.MAGAZINE,
		"rank": 1,
		"desc": "Factory direct dart magazine clip.",
		"pros": ["Fast handling"],
		"cons": ["Standard capacity"],
		"stats": {}
	},
	{
		"id": &"extended_drum",
		"name": "High-Cap Drum Mag",
		"slot": Slot.MAGAZINE,
		"rank": 3,
		"desc": "Chunky circular rotary drum holding 50% more darts between reloads.",
		"pros": ["+50% magazine capacity (+4 to +8 darts)"],
		"cons": ["+0.2s reload duration"],
		"stats": {"mag_bonus": 6, "reload_mult": 1.18}
	},
	{
		"id": &"quick_mag",
		"name": "Jungle-Taped Dual Mags",
		"slot": Slot.MAGAZINE,
		"rank": 5,
		"desc": "Two magazine clips taped together side-by-side with heavy electrical tape.",
		"pros": ["-40% reload time (lightning-fast flip reload)"],
		"cons": ["Slightly heavier side profile"],
		"stats": {"reload_mult": 0.60}
	},
	{
		"id": &"dart_agitator",
		"name": "Motorized Agitator",
		"slot": Slot.MAGAZINE,
		"rank": 7,
		"desc": "Battery-powered vibrating feed ramp that smoothly feeds darts without jams.",
		"pros": ["+15% sustained fire rate", "+2 dart capacity"],
		"cons": ["Subtle motor hum"],
		"stats": {"rate_mult": 1.15, "mag_bonus": 2}
	},

	# --- STOCKS & ERGONOMICS ---
	{
		"id": &"no_stock",
		"name": "Standard Grip",
		"slot": Slot.STOCK,
		"rank": 1,
		"desc": "Factory grip handle without rear shoulder stock.",
		"pros": ["Maximum mobility", "Fast weapon swaps"],
		"cons": ["Standard stability"],
		"stats": {}
	},
	{
		"id": &"skeleton_stock",
		"name": "Wire Skeleton Stock",
		"slot": Slot.STOCK,
		"rank": 2,
		"desc": "Foldable lightweight dual-wire shoulder brace with ribbed rubber buttpad.",
		"pros": ["+20% recoil stabilization", "-10% sustained spread", "+5% mobility"],
		"cons": ["Slightly wider profile"],
		"stats": {"recoil_mult": 0.80, "spread_mult": 0.90, "move_mult": 1.05}
	},
	{
		"id": &"tactical_grip",
		"name": "Angled Foregrip",
		"slot": Slot.STOCK,
		"rank": 4,
		"desc": "Ergonomic front hand stop with textured finger grooves mounted to bottom rail.",
		"pros": ["+20% aim recovery", "+25% ADS speed", "-15% recoil", "+3% mobility"],
		"cons": ["Requires two-handed stance"],
		"stats": {"recoil_mult": 0.85, "spread_mult": 0.90, "move_mult": 1.03, "ads_speed_mult": 1.25}
	},
	{
		"id": &"counterweight_stock",
		"name": "Weighted Crane Stock",
		"slot": Slot.STOCK,
		"rank": 6,
		"desc": "Reinforced crane stock with heavy battery counterweight balancing the blaster.",
		"pros": ["-30% camera shake", "Completely removes idle sway", "-25% recoil"],
		"cons": ["-4% mobility", "Heavier overall weight"],
		"stats": {"recoil_mult": 0.75, "move_mult": 0.96, "sway_mult": 0.0, "shake_mult": 0.70}
	},
]


## Returns the list of attachments valid for the specified slot.
static func get_attachments_for_slot(slot: Slot) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for att in ATTACHMENTS:
		if int(att.get("slot", -1)) == int(slot):
			result.append(att)
	return result


## Finds an attachment dictionary by ID.
static func find_attachment(attachment_id: StringName) -> Dictionary:
	for att in ATTACHMENTS:
		if att.get("id", &"") == attachment_id:
			return att
	return {}


## Calculates the Mastery Rank (1..10) given total weapon mastery XP.
static func get_mastery_rank(xp: int) -> int:
	var rank := 1
	for i in range(1, MASTERY_THRESHOLDS.size()):
		if xp >= MASTERY_THRESHOLDS[i]:
			rank = i + 1
		else:
			break
	return clampi(rank, 1, MAX_MASTERY_RANK)


## Returns details about progress to the next mastery rank:
## { "rank": int, "title": String, "current_xp": int, "needed_xp": int, "ratio": float, "is_max": bool }
static func get_mastery_progress(xp: int) -> Dictionary:
	var rank := get_mastery_rank(xp)
	var title := MASTERY_TITLES[rank - 1]
	if rank >= MAX_MASTERY_RANK:
		return {
			"rank": rank,
			"title": title,
			"current_xp": xp,
			"needed_xp": MASTERY_THRESHOLDS[MAX_MASTERY_RANK - 1],
			"ratio": 1.0,
			"is_max": true,
		}
	var base_xp := MASTERY_THRESHOLDS[rank - 1]
	var next_xp := MASTERY_THRESHOLDS[rank]
	var needed := next_xp - base_xp
	var current := xp - base_xp
	var ratio := clampf(float(current) / float(maxi(needed, 1)), 0.0, 1.0)
	return {
		"rank": rank,
		"title": title,
		"current_xp": current,
		"needed_xp": needed,
		"ratio": ratio,
		"is_max": false,
	}


## Checks whether an attachment is unlocked given current weapon mastery rank.
static func is_attachment_unlocked(attachment_id: StringName, weapon_rank: int) -> bool:
	var att := find_attachment(attachment_id)
	if att.is_empty():
		return false
	var req_rank: int = int(att.get("rank", 1))
	return weapon_rank >= req_rank


## Computes combined stat multipliers and additions for a weapon with equipped attachments.
## attachments format: { "optic": &"red_dot", "barrel": &"...", ... }
static func compute_attachment_modifiers(equipped: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"spread_mult": 1.0,
		"velocity_mult": 1.0,
		"tag_power_mult": 1.0,
		"recoil_mult": 1.0,
		"rate_mult": 1.0,
		"mag_bonus": 0,
		"reload_mult": 1.0,
		"gravity_mult": 1.0,
		"zoom_fov": 0.0,
		"reticle": &"standard",
		"sound_override": &"",
		"move_mult": 1.0,
		"sway_mult": 1.0,
		"shake_mult": 1.0,
		"ads_speed_mult": 1.0,
	}
	for slot_key in equipped:
		var att_id: StringName = StringName(str(equipped[slot_key]))
		var att := find_attachment(att_id)
		if att.is_empty():
			continue
		var stats: Dictionary = att.get("stats", {})
		if stats.has("spread_mult"):
			result["spread_mult"] *= float(stats["spread_mult"])
		if stats.has("velocity_mult"):
			result["velocity_mult"] *= float(stats["velocity_mult"])
		if stats.has("tag_power_mult"):
			result["tag_power_mult"] *= float(stats["tag_power_mult"])
		if stats.has("recoil_mult"):
			result["recoil_mult"] *= float(stats["recoil_mult"])
		if stats.has("rate_mult"):
			result["rate_mult"] *= float(stats["rate_mult"])
		if stats.has("mag_bonus"):
			result["mag_bonus"] += int(stats["mag_bonus"])
		if stats.has("reload_mult"):
			result["reload_mult"] *= float(stats["reload_mult"])
		if stats.has("gravity_mult"):
			result["gravity_mult"] *= float(stats["gravity_mult"])
		if stats.has("move_mult"):
			result["move_mult"] *= float(stats["move_mult"])
		if stats.has("sway_mult"):
			result["sway_mult"] *= float(stats["sway_mult"])
		if stats.has("shake_mult"):
			result["shake_mult"] *= float(stats["shake_mult"])
		if stats.has("ads_speed_mult"):
			result["ads_speed_mult"] *= float(stats["ads_speed_mult"])
		if stats.has("zoom_fov") and float(stats["zoom_fov"]) > 0.0:
			result["zoom_fov"] = float(stats["zoom_fov"])
		if stats.has("reticle"):
			result["reticle"] = StringName(str(stats["reticle"]))
		if stats.has("sound_override") and not str(stats["sound_override"]).is_empty():
			result["sound_override"] = StringName(str(stats["sound_override"]))
	return result


## Finds workbench blaster definition by weapon ID (or legacy alias).
static func find_workbench_blaster(weapon_id: StringName) -> Dictionary:
	for b in WORKBENCH_BLASTERS:
		if b.get("id", &"") == weapon_id or b.get("alias_id", &"") == weapon_id:
			return b
	return {}


## Converts Slot enum to StringName dictionary key.
static func slot_string(slot: Slot) -> StringName:
	match slot:
		Slot.OPTIC: return &"optic"
		Slot.BARREL: return &"barrel"
		Slot.SPRING: return &"spring"
		Slot.MAGAZINE: return &"magazine"
		Slot.STOCK: return &"stock"
	return &""


## Human-readable title for attachment slot.
static func slot_name(slot: Slot) -> String:
	match slot:
		Slot.OPTIC: return "Optic / Sight"
		Slot.BARREL: return "Barrel / Muzzle"
		Slot.SPRING: return "Spring & Sear"
		Slot.MAGAZINE: return "Magazine / Clip"
		Slot.STOCK: return "Stock & Grip"
	return "Attachment"


## Returns the default stock attachment ID for a slot.
static func get_default_attachment_for_slot(slot: Slot) -> StringName:
	match slot:
		Slot.OPTIC: return &"iron_sights"
		Slot.BARREL: return &"stock_barrel"
		Slot.SPRING: return &"stock_spring"
		Slot.MAGAZINE: return &"stock_mag"
		Slot.STOCK: return &"no_stock"
	return &""


## Returns default stock loadout for a blaster.
static func default_equipped() -> Dictionary:
	return {
		"optic": &"iron_sights",
		"barrel": &"stock_barrel",
		"spring": &"stock_spring",
		"magazine": &"stock_mag",
		"stock": &"no_stock",
	}
