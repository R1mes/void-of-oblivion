class_name DotsevaAbilities
extends RefCounted

const ID := "dotseva"
const MAX_ENERGY := 100.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	# Е1 Доцевой: стоимость ульты снижена на 10 ед. (90 вместо 100)
	var max_en := 90.0 if eidolon >= 1 else MAX_ENERGY
	
	unit.setup_from_template({
		"id": ID,
		"name": "Доцева",
		"element": CombatConstants.Element.IMAGINARY, # Мнимый
		"path": CombatConstants.Path.ERUDITION,       # Эрудиция
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": max_en,
		"stats": {
			"hp": 3000,
			"atk": 2100,
			"def": 650,
			"spd": 100,
			"crit_rate": 0.20, #20%
			"crit_dmg": 0.60,
			"effect_hit_rate": 0.0,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

# В файле dotseva.gd:
static func apply_traces(unit: CombatUnit) -> void:
	pass # Логика техники перенесена в battle_manager для синхронизации стаков
