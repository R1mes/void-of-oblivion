class_name StatusEffects
extends RefCounted

var suppression_stacks: int = 0
var suppression_turns: int = 0
var suppression_is_dot: bool = false

var break_status: String = ""
var break_status_turns: int = 0
var entanglement_stacks: int = 0

var imaginary_chains_turns: int = 0
var imaginary_spd_debuff_turns: int = 0

var skip_next_turn: bool = false
var toughness_broken: bool = false
var damage_taken_bonus: float = 0.0

var dot_pending_marina_proc: bool = false

# Источники эффектов (имя персонажа/врага)
var suppression_source: String = ""
var patch_source: String = ""
var dark_seal_source: String = ""
var atk_buff_source: String = ""
var self_atk_buff_source: String = ""
var crit_dmg_buff_source: String = ""
var break_status_source: String = ""
var toughness_break_source: String = ""
var skip_next_turn_source: String = ""
var entanglement_source: String = ""
var imaginary_source: String = ""
var incoming_heal_bonus_source: String = ""
var effect_resist_bonus_source: String = ""
var new_development_source: String = ""

# Сара — Заплатка
var patch_turns: int = 0
var incoming_heal_bonus: float = 0.0
var effect_resist_bonus: float = 0.0

var debuffs: Array[String] = []

# Арсений
var has_dark_seal: bool = false
var dark_seal_turns: int = 0
var new_development_turns: int = 0
var atk_buff_percent: float = 0.0
var atk_buff_flat: float = 0.0
var atk_buff_turns: int = 0
var self_atk_buff_percent: float = 0.0
var self_atk_buff_turns: int = 0
var crit_dmg_buff: float = 0.0
var crit_dmg_buff_turns: int = 0

func clear_break_phase() -> void:
	toughness_broken = false
	damage_taken_bonus = 0.0
	break_status = ""
	break_status_turns = 0

func has_debuffs() -> bool:
	return not debuffs.is_empty() or suppression_stacks > 0 or break_status != ""

func cleanse_one() -> bool:
	if suppression_stacks > 0:
		suppression_stacks -= 1
		if suppression_stacks <= 0:
			suppression_turns = 0
			suppression_is_dot = false
			suppression_source = ""
		return true
	if break_status != "":
		break_status = ""
		break_status_turns = 0
		break_status_source = ""
		return true
	if not debuffs.is_empty():
		debuffs.pop_back()
		return true
	return false

func cleanse_all() -> void:
	suppression_stacks = 0
	suppression_turns = 0
	suppression_is_dot = false
	suppression_source = ""
	break_status = ""
	break_status_turns = 0
	break_status_source = ""
	entanglement_stacks = 0
	entanglement_source = ""
	imaginary_chains_turns = 0
	imaginary_spd_debuff_turns = 0
	imaginary_source = ""
	patch_turns = 0
	patch_source = ""
	incoming_heal_bonus = 0.0
	incoming_heal_bonus_source = ""
	effect_resist_bonus = 0.0
	effect_resist_bonus_source = ""
	dark_seal_turns = 0
	has_dark_seal = false
	dark_seal_source = ""
	atk_buff_turns = 0
	atk_buff_percent = 0.0
	atk_buff_flat = 0.0
	atk_buff_source = ""
	self_atk_buff_turns = 0
	self_atk_buff_percent = 0.0
	self_atk_buff_source = ""
	crit_dmg_buff_turns = 0
	crit_dmg_buff = 0.0
	crit_dmg_buff_source = ""
	new_development_turns = 0
	new_development_source = ""
	toughness_broken = false
	toughness_break_source = ""
	skip_next_turn = false
	skip_next_turn_source = ""
	debuffs.clear()
