class_name Cosmetics
extends RefCounted
## The choices for how a player looks: colours, hats and fun random names.
## Pure data, so the menu, the match and the podium all agree.

const NAME_MAX_LENGTH := 12

const COLORS: Array[Dictionary] = [
	{"name": "Blue", "color": Color(0.15, 0.5, 1.0), "cost": 0, "tier": "Starter"},
	{"name": "Red", "color": Color(0.95, 0.22, 0.25), "cost": 0, "tier": "Starter"},
	{"name": "Green", "color": Color(0.25, 0.8, 0.3), "cost": 0, "tier": "Starter"},
	{"name": "Purple", "color": Color(0.62, 0.38, 1.0), "cost": 0, "tier": "Starter"},
	{"name": "Pink", "color": Color(1.0, 0.42, 0.72), "cost": 100, "tier": "Bubblegum"},
	{"name": "Yellow", "color": Color(1.0, 0.84, 0.15), "cost": 100, "tier": "Golden"},
	{"name": "Orange", "color": Color(1.0, 0.52, 0.12), "cost": 100, "tier": "Tangerine"},
	{"name": "Teal", "color": Color(0.1, 0.8, 0.78), "cost": 100, "tier": "Electric"},
]

## Hat ids in menu order, with the name shown on the button, cost in coins, and tier.
const HATS: Array[Dictionary] = [
	{"id": &"cap", "name": "Cap", "cost": 0, "tier": "Starter"},
	{"id": &"beanie", "name": "Beanie", "cost": 0, "tier": "Starter"},
	{"id": &"none", "name": "No Hat", "cost": 0, "tier": "Starter"},
	{"id": &"party", "name": "Party Hat", "cost": 150, "tier": "Party"},
	{"id": &"cowboy", "name": "Cowboy", "cost": 150, "tier": "Classic"},
	{"id": &"propeller", "name": "Propeller", "cost": 250, "tier": "Toy"},
	{"id": &"goggles", "name": "Goggles", "cost": 250, "tier": "Toy"},
	{"id": &"bunny", "name": "Bunny Ears", "cost": 250, "tier": "Fun"},
	{"id": &"horns", "name": "Horns", "cost": 400, "tier": "Costume"},
	{"id": &"spiky", "name": "Spiky Hair", "cost": 400, "tier": "Style"},
	{"id": &"crown", "name": "Crown", "cost": 500, "tier": "Champion"},
]

## Blaster skins with pattern texture, finish mode (0: Matte, 1: Gloss, 2: Metallic, 3: Holographic), cost, and tier.
const SKINS: Array[Dictionary] = [
	{"id": &"default", "name": "Classic Foam", "cost": 0, "tier": "Starter", "pattern": "res://assets/textures/skins/pattern_default.png", "finish": 1},
	{"id": &"nitro", "name": "Nitro Stripe", "cost": 150, "tier": "Speed", "pattern": "res://assets/textures/skins/pattern_nitro.png", "finish": 1},
	{"id": &"cyber", "name": "Neon Circuit", "cost": 250, "tier": "Tech", "pattern": "res://assets/textures/skins/pattern_cyber.png", "finish": 1},
	{"id": &"hazard", "name": "Caution Zone", "cost": 250, "tier": "Hazard", "pattern": "res://assets/textures/skins/pattern_hazard.png", "finish": 0},
	{"id": &"galaxy", "name": "Cosmic Pop", "cost": 400, "tier": "Space", "pattern": "res://assets/textures/skins/pattern_galaxy.png", "finish": 2},
	{"id": &"dino", "name": "Dino Claws", "cost": 400, "tier": "Wild", "pattern": "res://assets/textures/skins/pattern_dino.png", "finish": 0},
	{"id": &"hologram", "name": "Prism Foil", "cost": 500, "tier": "Champion", "pattern": "res://assets/textures/skins/pattern_hologram.png", "finish": 3},
	{"id": &"slime", "name": "Toxic Slime", "cost": 600, "tier": "Outbreak", "pattern": "res://assets/textures/skins/pattern_slime.png", "finish": 1},
	{"id": &"shark", "name": "Shark Bite", "cost": 300, "tier": "Aero", "pattern": "res://assets/textures/skins/pattern_shark.png", "finish": 1},
	{"id": &"flames", "name": "Fire Storm", "cost": 350, "tier": "Hot Rod", "pattern": "res://assets/textures/skins/pattern_flames.png", "finish": 1},
]

const RANDOM_NAMES: Array[String] = [
	"Captain Foam", "Sir Splat", "Blaster Bean", "Tag Master", "Zippy", "Bounce Boss",
	"Captain Fizz", "Dart Wizard", "Foam Ninja", "Turbo Toast", "Mega Muffin", "Ricochet Rex",
	"Breezy Blaster", "Bucket Bandit", "Storm Chaser", "Professor Pop",
]


## Trims, removes anything that isn't a letter, digit, space, dash or
## underscore, and caps the length. Returns "" if nothing usable is left.
static func sanitize_name(raw: String) -> String:
	var out := ""
	for character in raw.strip_edges():
		var code := character.unicode_at(0)
		var ok := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) \
				or character == " " or character == "-" or character == "_"
		if ok:
			out += character
	out = out.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.substr(0, NAME_MAX_LENGTH).strip_edges()


static func color_at(index: int) -> Color:
	return COLORS[clampi(index, 0, COLORS.size() - 1)]["color"]


static func has_hat(id: StringName) -> bool:
	for hat in HATS:
		if hat["id"] == id:
			return true
	return false


static func hat_name(id: StringName) -> String:
	for hat in HATS:
		if hat["id"] == id:
			return hat["name"]
	return "No Hat"


static func hat_cost(id: StringName) -> int:
	for hat in HATS:
		if hat["id"] == id:
			return int(hat.get("cost", 0))
	return 0


static func hat_tier(id: StringName) -> String:
	for hat in HATS:
		if hat["id"] == id:
			return str(hat.get("tier", "Starter"))
	return "Starter"


static func color_cost(index: int) -> int:
	if index >= 0 and index < COLORS.size():
		return int(COLORS[index].get("cost", 0))
	return 0


static func color_tier(index: int) -> String:
	if index >= 0 and index < COLORS.size():
		return str(COLORS[index].get("tier", "Starter"))
	return "Starter"


static func is_default_hat(id: StringName) -> bool:
	return hat_cost(id) <= 0


static func is_default_color(index: int) -> bool:
	return color_cost(index) <= 0


static func has_skin(id: StringName) -> bool:
	for skin in SKINS:
		if skin["id"] == id:
			return true
	return false


static func skin_name(id: StringName) -> String:
	for skin in SKINS:
		if skin["id"] == id:
			return skin["name"]
	return "Classic Foam"


static func skin_cost(id: StringName) -> int:
	for skin in SKINS:
		if skin["id"] == id:
			return int(skin.get("cost", 0))
	return 0


static func skin_tier(id: StringName) -> String:
	for skin in SKINS:
		if skin["id"] == id:
			return str(skin.get("tier", "Starter"))
	return "Starter"


static func skin_pattern(id: StringName) -> String:
	for skin in SKINS:
		if skin["id"] == id:
			return str(skin.get("pattern", "res://assets/textures/skins/pattern_default.png"))
	return "res://assets/textures/skins/pattern_default.png"


static func skin_finish(id: StringName) -> int:
	for skin in SKINS:
		if skin["id"] == id:
			return int(skin.get("finish", 1))
	return 1


static func is_default_skin(id: StringName) -> bool:
	return skin_cost(id) <= 0


static func random_name() -> String:
	return RANDOM_NAMES[randi() % RANDOM_NAMES.size()]


## True when two colours are close enough to be confused across the yard.
static func too_similar(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.3
