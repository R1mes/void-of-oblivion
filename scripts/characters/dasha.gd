class_name DashaAbilities
extends RefCounted

const ID := "dasha"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Даша",
		"element": CombatConstants.Element.LIGHTNING,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 3400,
			"atk": 1700,
			"def": 900,
			"spd": 103,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.80, # 80% базового эффекта пробития
			"weakness_efficiency": 0.30,
			"damage_bonus": 0.00,
		},
	})
	
	unit.max_energy = 140.0
	unit.energy = 0.0
	
	unit.set_meta("circle_dance", false)
	unit.set_meta("overload_turns", 0)
	unit.set_meta("pirouette_stacks", 0)
	
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	pass
