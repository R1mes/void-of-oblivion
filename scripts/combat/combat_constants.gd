class_name CombatConstants
extends RefCounted

enum Element {
	ICE,
	FIRE,
	PHYSICAL,
	WIND,
	LIGHTNING,
	QUANTUM,
	IMAGINARY,
}

enum Path {
	HUNT,
	ERUDITION,
	DESTRUCTION,
	HARMONY,
	ABUNDANCE,
	PRESERVATION,
	NIHILITY,
	REMEMBRANCE,
}

const ELEMENT_SYMBOLS := {
	Element.ICE: "❄",
	Element.FIRE: "🔥",
	Element.PHYSICAL: "⚔",
	Element.WIND: "🌪",
	Element.LIGHTNING: "⚡",
	Element.QUANTUM: "🔮",
	Element.IMAGINARY: "✨",
}

const ELEMENT_NAMES := {
	Element.ICE: "Ледяной",
	Element.FIRE: "Огненный",
	Element.PHYSICAL: "Физический",
	Element.WIND: "Ветряной",
	Element.LIGHTNING: "Электрический",
	Element.QUANTUM: "Квантовый",
	Element.IMAGINARY: "Мнимый",
}

const ELEMENT_SHORT_NAMES := {
	Element.ICE: "Лёд",
	Element.FIRE: "Огонь",
	Element.PHYSICAL: "Физ",
	Element.WIND: "Ветер",
	Element.LIGHTNING: "Молния",
	Element.QUANTUM: "Квант",
	Element.IMAGINARY: "Мнимый",
}

const ELEMENT_COLORS := {
	Element.ICE: Color(0.4, 0.8, 1.0),
	Element.FIRE: Color(1.0, 0.45, 0.3),
	Element.PHYSICAL: Color(0.9, 0.9, 0.95),
	Element.WIND: Color(0.35, 0.9, 0.55),
	Element.LIGHTNING: Color(0.8, 0.5, 1.0),
	Element.QUANTUM: Color(0.45, 0.55, 1.0),
	Element.IMAGINARY: Color(1.0, 0.85, 0.3),
}

static func get_element_name(element: int) -> String:
	return String(ELEMENT_NAMES.get(element, "Неизвестный"))

static func get_element_short_name(element: int) -> String:
	return String(ELEMENT_SHORT_NAMES.get(element, "???"))

static func get_element_symbol(element: int) -> String:
	return String(ELEMENT_SYMBOLS.get(element, "✦"))

static func get_element_color(element: int) -> Color:
	return ELEMENT_COLORS.get(element, Color(0.4, 0.8, 1.0))

static func get_element_label(element: int) -> String:
	return "%s %s" % [get_element_symbol(element), get_element_short_name(element)]

static func get_element_full_label(element: int) -> String:
	return "%s %s" % [get_element_symbol(element), get_element_name(element)]

const MAX_SKILL_POINTS := 5
const MAX_ENERGY := 100
const AV_BASE := 10000.0

const BREAK_DAMAGE_BONUS := 0.20
const BREAK_ACTION_DELAY := 0.50
const SUPPRESSION_BREAK_EXTRA_DELAY := 0.75

const SUPPRESSION_MAX_STACKS := 5
const SUPPRESSION_SPD_PER_STACK := 0.08
const SUPPRESSION_EHR_PER_STACK := 0.10
const SUPPRESSION_DAMAGE_BONUS := 0.15

static func element_matches_weakness(element: Element, weaknesses: Array) -> bool:
	return element in weaknesses
