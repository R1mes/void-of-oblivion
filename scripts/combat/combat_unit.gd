class_name CombatUnit
extends RefCounted

signal hp_changed(unit: CombatUnit)
signal energy_changed(unit: CombatUnit)
signal died(unit: CombatUnit)

var id: String = ""
var display_name: String = ""
var element: CombatConstants.Element = CombatConstants.Element.PHYSICAL
var path: CombatConstants.Path = CombatConstants.Path.HUNT
var is_ally: bool = true
var is_elite: bool = false

var stats: CombatStats = CombatStats.new()
var statuses: StatusEffects = StatusEffects.new()

var energy: float = 0.0
var action_value: float = 0.0
var base_action_value: float = 100.0

var max_toughness: float = 0.0
var toughness: float = 0.0
var weaknesses: Array = []

var eidolon: int = 0
var slot_index: int = 0
var max_energy: float = CombatConstants.MAX_ENERGY

var _base_spd: float = 100.0

func setup_from_template(template: Dictionary) -> void:
	id = template.get("id", id)
	display_name = template.get("name", display_name)
	element = template.get("element", element)
	path = template.get("path", path)
	is_ally = template.get("is_ally", is_ally)
	is_elite = template.get("is_elite", false)
	eidolon = template.get("eidolon", 0)
	max_energy = template.get("max_energy", CombatConstants.MAX_ENERGY)

	var s: Dictionary = template.get("stats", {})
	stats.max_hp = s.get("hp", stats.max_hp)
	stats.hp = stats.max_hp
	stats.atk = s.get("atk", stats.atk)
	stats.def = s.get("def", stats.def)
	stats.spd = s.get("spd", stats.spd)
	stats.crit_rate = s.get("crit_rate", stats.crit_rate)
	stats.crit_dmg = s.get("crit_dmg", stats.crit_dmg)
	stats.effect_hit_rate = s.get("effect_hit_rate", stats.effect_hit_rate)
	stats.break_effect = s.get("break_effect", stats.break_effect)
	stats.weakness_efficiency = s.get("weakness_efficiency", stats.weakness_efficiency)
	stats.damage_bonus = s.get("damage_bonus", stats.damage_bonus)

	_base_spd = stats.spd
	if template.has("toughness"):
		max_toughness = template.toughness
		toughness = max_toughness
	if template.has("weaknesses"):
		weaknesses = template.weaknesses.duplicate()

	recalculate_action_value()

func recalculate_action_value() -> void:
	var spd := stats.get_effective_spd()
	base_action_value = CombatConstants.AV_BASE / spd
	if action_value <= 0.0:
		action_value = base_action_value

func on_speed_changed(old_spd: float, new_spd: float) -> void:
	if new_spd <= 0.0 or old_spd <= 0.0:
		return
	action_value *= old_spd / new_spd
	base_action_value = CombatConstants.AV_BASE / new_spd

func advance_action(percent: float) -> void:
	action_value = maxf(action_value - base_action_value * percent / 100.0, 0.0)

func delay_action(percent: float) -> void:
	action_value += base_action_value * percent / 100.0

func force_immediate_turn() -> void:
	action_value = 0.0

func reset_action_value() -> void:
	action_value = base_action_value

func gain_energy(amount: float) -> void:
	energy = minf(energy + amount, max_energy)
	energy_changed.emit(self)

func spend_energy(amount: float) -> bool:
	if energy < amount:
		return false
	energy -= amount
	energy_changed.emit(self)
	return true

func apply_damage(amount: float) -> float:
	var dealt := stats.take_damage(amount)
	hp_changed.emit(self)
	if not stats.is_alive():
		died.emit(self)
	return dealt

func heal(amount: float) -> float:
	var healed := stats.heal(amount)
	hp_changed.emit(self)
	return healed

func is_alive() -> bool:
	return stats.is_alive()

func get_hp_ratio() -> float:
	if stats.max_hp <= 0.0:
		return 0.0
	return stats.hp / stats.max_hp

func get_toughness_ratio() -> float:
	if max_toughness <= 0.0:
		return 0.0
	return toughness / max_toughness

func get_effective_be() -> float:
	var be := stats.break_effect
	if has_meta("milena_be_buff"):
		be += float(get_meta("milena_be_buff", 0.0))
	return be

func add_speed_modifier(pct: float, flat: float) -> void:
	var old_spd := stats.get_effective_spd()
	
	var current_pct := float(stats.get_meta("spd_pct_bonus", 0.0))
	var current_flat := float(stats.get_meta("spd_flat_bonus", 0.0))
	
	stats.set_meta("spd_pct_bonus", current_pct + pct)
	stats.set_meta("spd_flat_bonus", current_flat + flat)
	
	var new_spd := stats.get_effective_spd()
	if old_spd != new_spd:
		on_speed_changed(old_spd, new_spd)

func remove_speed_modifier(pct: float, flat: float) -> void:
	var old_spd := stats.get_effective_spd()
	
	var current_pct := float(stats.get_meta("spd_pct_bonus", 0.0))
	var current_flat := float(stats.get_meta("spd_flat_bonus", 0.0))
	
	stats.set_meta("spd_pct_bonus", current_pct - pct)
	stats.set_meta("spd_flat_bonus", current_flat - flat)
	
	var new_spd := stats.get_effective_spd()
	if old_spd != new_spd:
		on_speed_changed(old_spd, new_spd)
