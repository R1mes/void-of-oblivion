class_name PusenkovAbilities
extends RefCounted

const ID := "pusenkov"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Кирилл",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.HUNT,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 1950, # Аномально низкая живучесть
			"atk": 2300, # Огромный показатель атаки
			"def": 500,
			"spd": 110,
			"crit_rate": 0.15,
			"crit_dmg": 0.85,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
			"damage_bonus": 0.00,
		},
	})
	
	unit.max_energy = 160.0
	unit.energy = 0.0 # Базовый старт боя с 0 энергии (увеличится техникой)
	
	# След 3: В начале боя первая базовая атака является усиленной (счетчик на 3, первая атака сделает его 4)
	unit.set_meta("basic_counter", 3)
	unit.set_meta("untargetable", false)
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	# Следы Пусенкова рассчитываются динамически во время боя
	pass

# След 2 и Эйдолон 1: конвертация избыточного крит. шанса в крит. урон
static func get_excess_crit_dmg_bonus(unit: CombatUnit) -> float:
	var cr := unit.stats.crit_rate
	if cr > 1.0:
		var excess := cr - 1.0
		var mult := 2.0 if unit.eidolon >= 1 else 1.6
		return excess * mult
	return 0.0

static func is_next_basic_enhanced(unit: CombatUnit) -> bool:
	return unit.get_meta("basic_counter", 0) >= 3

# Вспомогательный метод для смены цели статусов (смена цели сбрасывает старые статусы)
static func set_target_status(new_target: CombatUnit, status_type: String, battle: BattleManager) -> void:
	for enemy in battle.enemies:
		if enemy != new_target:
			enemy.set_meta("priority_target", false)
			enemy.set_meta("dead_or_alive", false)
	
	if status_type == "priority":
		new_target.set_meta("priority_target", true)
		new_target.set_meta("dead_or_alive", false)
	elif status_type == "dead_or_alive":
		new_target.set_meta("priority_target", false)
		new_target.set_meta("dead_or_alive", true)
