class_name MilenaAbilities
extends RefCounted

const ID := "milena"
const MAX_ENERGY := 300.0 # Очень дорогая ульта

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Милена",
		"element": CombatConstants.Element.QUANTUM, # Квант
		"path": CombatConstants.Path.HARMONY,       # Гармония
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3400,
			"atk": 1100,
			"def": 950,
			"spd": 106,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.0,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit, allies: Array) -> void:
	# След 1: За каждого участника Рассвета Хаоса СА Милены увеличена на 35%
	var chaos_count := 0
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var is_chaos = ally.id in ["arseniy", "dasha", "shoji", "danill", "kaori"]
			if is_chaos:
				chaos_count += 1
				
	if chaos_count > 0:
		var bonus_pct := 0.35 * float(chaos_count)
		# ИСПРАВЛЕНО: Прибавляем процентный бафф СА к self_atk_buff_percent
		unit.statuses.self_atk_buff_percent += bonus_pct 
		unit.set_meta("milena_trace1_atk_pct", bonus_pct)
