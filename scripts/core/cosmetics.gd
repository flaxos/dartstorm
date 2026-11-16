class_name Cosmetics
extends RefCounted
## The choices for how a player looks: colours, hats and fun random names.
## Pure data, so the menu, the match and the podium all agree.

const NAME_MAX_LENGTH := 12

const COLORS: Array[Dictionary] = [
	{"name": "Blue", "color": Color(0.15, 0.5, 1.0)},
	{"name": "Red", "color": Color(0.95, 0.22, 0.25)},
	{"name": "Green", "color": Color(0.25, 0.8, 0.3)},
	{"name": "Purple", "color": Color(0.62, 0.38, 1.0)},
	{"name": "Pink", "color": Color(1.0, 0.42, 0.72)},
	{"name": "Yellow", "color": Color(1.0, 0.84, 0.15)},
	{"name": "Orange", "color": Color(1.0, 0.52, 0.12)},
	{"name": "Teal", "color": Color(0.1, 0.8, 0.78)},
]

## Hat ids in menu order, with the name shown on the button.
const HATS: Array[Dictionary] = [
	{"id": &"cap", "name": "Cap"},
	{"id": &"beanie", "name": "Beanie"},
	{"id": &"propeller", "name": "Propeller"},
	{"id": &"party", "name": "Party Hat"},
	{"id": &"cowboy", "name": "Cowboy"},
	{"id": &"crown", "name": "Crown"},
	{"id": &"goggles", "name": "Goggles"},
	{"id": &"bunny", "name": "Bunny Ears"},
	{"id": &"horns", "name": "Horns"},
	{"id": &"spiky", "name": "Spiky Hair"},
	{"id": &"none", "name": "No Hat"},
]

const RANDOM_NAMES: Array[String] = [
	"Captain Foam", "Sir Splat", "Blaster Bean", "Tag Master", "Zippy", "Bounce Boss",
	"Captain Fizz", "Dart Wizard", "Foam Ninja", "Turbo Toast", "Mega Muffin", "Ricochet Rex",
	"Windy Wendy", "Bucket Bandit", "Storm Chaser", "Professor Pop",
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


static func random_name() -> String:
	return RANDOM_NAMES[randi() % RANDOM_NAMES.size()]


## True when two colours are close enough to be confused across the yard.
static func too_similar(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.3
