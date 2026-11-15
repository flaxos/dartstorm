class_name UiKit
extends RefCounted
## Shared look for every menu and HUD element: deep blue panels, hot orange
## highlights, rounded corners and one chunky font.

const NAVY := Color("0b1f4b")
const NAVY_DARK := Color("071230")
const BLUE := Color("1f6bff")
const SKY := Color("57b6ff")
const ORANGE := Color("ff7a1a")
const ORANGE_HOT := Color("ff9d2e")
const ORANGE_DEEP := Color("d95a00")
const CREAM := Color("fff4e0")
const LIME := Color("9be22d")
const PINK := Color("ff5fa2")
const GREY := Color("8d9ab8")

static var _font: FontVariation


## The engine's built-in font, emboldened so it reads as chunky arcade type.
static func font() -> FontVariation:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = 0.9
		_font.spacing_glyph = 1
	return _font


static func panel_style(bg: Color = NAVY, alpha: float = 0.86, radius: int = 16,
		border_width: int = 0, border: Color = ORANGE, margin: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg, alpha)
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.set_content_margin_all(margin)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 4
	return style


static func panel(bg: Color = NAVY, alpha: float = 0.86, radius: int = 16,
		border_width: int = 0, border: Color = ORANGE, margin: int = 12) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel_style(bg, alpha, radius, border_width, border, margin))
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return container


static func label(text: String, size: int = 22, color: Color = CREAM, outline: int = 6) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", NAVY_DARK)
	node.add_theme_constant_override("outline_size", outline)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func button(text: String, size: int = 26, min_size: Vector2 = Vector2(300, 56)) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = min_size
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, CREAM)
	node.add_theme_color_override("font_outline_color", NAVY_DARK)
	node.add_theme_constant_override("outline_size", 6)
	node.add_theme_stylebox_override("normal", panel_style(ORANGE, 1.0, 14, 0, ORANGE, 10))
	node.add_theme_stylebox_override("hover", panel_style(ORANGE_HOT, 1.0, 14, 3, CREAM, 10))
	node.add_theme_stylebox_override("pressed", panel_style(ORANGE_DEEP, 1.0, 14, 3, CREAM, 10))
	node.add_theme_stylebox_override("focus", panel_style(ORANGE_HOT, 0.0, 14, 3, CREAM, 10))
	node.add_theme_stylebox_override("disabled", panel_style(GREY, 0.8, 14, 0, GREY, 10))
	node.pressed.connect(func() -> void: Sfx.play(&"ui_click"))
	return node


## A smaller blue button for secondary choices (option cycling, back).
static func small_button(text: String, min_size: Vector2 = Vector2(56, 44)) -> Button:
	var node := button(text, 22, min_size)
	node.add_theme_stylebox_override("normal", panel_style(BLUE, 1.0, 12, 0, BLUE, 8))
	node.add_theme_stylebox_override("hover", panel_style(SKY, 1.0, 12, 3, CREAM, 8))
	node.add_theme_stylebox_override("pressed", panel_style(NAVY, 1.0, 12, 3, CREAM, 8))
	node.add_theme_stylebox_override("focus", panel_style(SKY, 0.0, 12, 3, CREAM, 8))
	return node


static func bar(fill: Color, min_size: Vector2 = Vector2(240, 22)) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = min_size
	node.min_value = 0.0
	node.max_value = 1.0
	node.add_theme_stylebox_override("background", panel_style(NAVY_DARK, 0.9, 10, 2, NAVY_DARK, 0))
	node.add_theme_stylebox_override("fill", panel_style(fill, 1.0, 10, 0, fill, 0))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Pins a control to a point of its parent and lets it grow away from that point.
static func pin(node: Control, anchor: Vector2, offset: Vector2,
		grow_h: Control.GrowDirection, grow_v: Control.GrowDirection) -> void:
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = offset.x
	node.offset_right = offset.x
	node.offset_top = offset.y
	node.offset_bottom = offset.y
	node.grow_horizontal = grow_h
	node.grow_vertical = grow_v
