class_name DanillAbilities
extends RefCounted

const ID := "danill"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Данилл",
		"element": CombatConstants.Element.FIRE,
		"path": CombatConstants.Path.PRESERVATION,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 3100,
			"atk": 800,
			"def": 1400, # Очень высокая базовая защита
			"spd": 98,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
			"damage_bonus": 0.00,
		},
	})
	
	unit.max_energy = 130.0
	unit.energy = 0.0
	
	# Инициализация уникальных метаданных Данилла
	unit.set_meta("danill_talent_stacks", 0)
	unit.set_meta("danill_taunt_turns", 0)
	unit.set_meta("e_shield_active", false)
	unit.set_meta("e6_cooldown", 0)
	
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	pass
