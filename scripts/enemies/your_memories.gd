class_name YourMemories
extends RefCounted

const ID: String = "your_memories"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Твои воспоминания",
		"element": CombatConstants.Element.IMAGINARY,
		"path": CombatConstants.Path.REMEMBRANCE if "REMEMBRANCE" in CombatConstants.Path else CombatConstants.Path.NIHILITY,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 115000,
			"atk": 1650,
			"def": 850,
			"spd": 106,
			"crit_rate": 0.10,
			"crit_dmg": 0.50,
			"effect_res": 0.25,
		},
		"toughness": 240,
		"weaknesses": [
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.ICE,
			CombatConstants.Element.LIGHTNING,
		],
	})
	unit.set_meta("base_hp_original", 115000.0)
	unit.set_meta("base_atk_original", 1650.0)
	unit.set_meta("base_def_original", 850.0)
	unit.set_meta("base_spd_original", 106.0)
	unit.set_meta("turn_count", 0)
	unit.set_meta("has_memory_prism", false)
	return unit

static func pick_target(allies: Array) -> CombatUnit:
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
				continue
			living.append(a)

	if living.is_empty():
		for a in allies:
			if a is CombatUnit and a.is_alive():
				living.append(a)

	if living.is_empty():
		return null

	return living[randi() % living.size()]

# Проверка пассивки «Отражение на льду» при наложении дебаффа героем
static func on_debuff_applied_by(hero: CombatUnit, bm: BattleManager) -> void:
	if hero == null or not hero.is_alive():
		return
	hero.set_meta("ice_reflection_buff_turns", 3)
	hero.set_meta("ice_reflection_bonus", 0.15)
	bm.log_message("❄ «Отражение на льду»: %s наложил дебафф на Твои воспоминания -> наносимый ледяной урон повышен на +15%% на 3 хода!" % hero.display_name)

# Расчет снижения СА от пассивки «Тяжесть прошлого» (-8% за дебафф, макс 32%)
static func get_weaken_atk_mult(enemy: CombatUnit, bm: BattleManager) -> float:
	var debuff_count: int = bm.count_unique_debuffs(enemy)
	var reduction: float = minf(float(debuff_count) * 0.08, 0.32)
	return 1.0 - reduction

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)
	
	var weaken_mult: float = get_weaken_atk_mult(enemy, bm)
	
	match turn % 3:
		1:
			_skill_phantom_crystal(enemy, allies, bm, weaken_mult)
		2:
			_skill_echo_of_oblivion(enemy, allies, bm, weaken_mult)
		0:
			_skill_memory_prism(enemy, bm)

# 1. «Фантомный кристалл» (Одиночная атака 150% СА мнимым уроном + дебафф «Оцепенение» -20% скорости)
static func _skill_phantom_crystal(enemy: CombatUnit, allies: Array, bm: BattleManager, weaken_mult: float) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("⏳ %s выпускает «Фантомный кристалл» по %s (мнимый урон)!" % [enemy.display_name, target.display_name])
	var res := DamageCalculator.calc_damage(enemy, target, 1.50 * weaken_mult)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.IMAGINARY, bool(res.get("crit", false)))
	
	target.add_speed_modifier(-0.20, 0.0)
	target.set_meta("numbness_spd_debuff_turns", 2)
	bm.log_message("  ↳ %s скован «Оцепенением»: скорость снижена на 20%% на 2 хода!" % target.display_name)
	bm.action_order_changed.emit()

# 2. «Эхо забвения» (AoE атака 90% СА мнимым уроном)
static func _skill_echo_of_oblivion(enemy: CombatUnit, allies: Array, bm: BattleManager, weaken_mult: float) -> void:
	bm.log_message("⏳ %s наполняет зал «Эхом забвения» (мнимый урон по всем союзникам)!" % enemy.display_name)
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res := DamageCalculator.calc_damage(enemy, a, 0.90 * weaken_mult)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.IMAGINARY, bool(res.get("crit", false)))

# 3. «Призма памяти» (Активация защитной призмы)
static func _skill_memory_prism(enemy: CombatUnit, bm: BattleManager) -> void:
	enemy.set_meta("has_memory_prism", true)
	bm.log_message("💎 %s возводит вокруг себя «Призму памяти»! Ледяная атака разрушит призму, задержит действие врага на 25%% и восстановит +1 ОН!" % enemy.display_name)
