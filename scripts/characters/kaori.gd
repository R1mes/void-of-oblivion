class_name KaoriAbilities
extends RefCounted

const ID := "kaori"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Каори",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.HUNT,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 2400,
			"atk": 1900,
			"def": 700,
			"spd": 108,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 1.20, # 120% базового эффекта пробития
			"weakness_efficiency": 0.30,
			"damage_bonus": 0.00,
		},
	})
	
	unit.max_energy = 130.0
	unit.energy = 0.0
	
	# Инициализация уникальных метаданных Каори
	unit.set_meta("weakness_concentration", false)
	unit.set_meta("in_fog_buff", false)
	unit.set_meta("e_shuriken_target", null)
	unit.set_meta("ult_recast_window", 0)
	
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	pass

# Талант: Проверка, находится ли Каори в Концентрации на слабости
static func is_in_concentration(unit: CombatUnit) -> bool:
	return unit.get_meta("weakness_concentration", false)
