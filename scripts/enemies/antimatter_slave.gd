class_name AntimatterSlave
extends RefCounted

const ID: String = "antimatter_slave"

static func create_unit(slot_idx: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Раб Антиматерии",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 30000.0,
			"atk": 1200.0,
			"def": 600.0,
			"spd": 98.0,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.15,
		},
		"toughness": 90.0,
		"weaknesses": [
			CombatConstants.Element.WIND,
			CombatConstants.Element.FIRE,
		],
	})
	unit.slot_index = slot_idx
	unit.set_meta("base_hp_original", 30000.0)
	unit.set_meta("base_atk_original", 1200.0)
	unit.set_meta("base_def_original", 600.0)
	unit.set_meta("base_spd_original", 98.0)
	unit.set_meta("turn_count", 0)
	# Пассивная сингулярность: пока стойкость не пробита, получает на 25% меньше урона
	unit.set_meta("dmg_reduction", 0.25)
	return unit

static func pick_target(allies: Array) -> CombatUnit:
	# Провокация Данилла
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

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	# Раз в 3 хода — «Сингулярный выброс» (Blast), иначе «Тёмный импульс» (Single Target)
	if turn % 3 == 0:
		_execute_singular_blast(enemy, allies, bm)
	else:
		_execute_dark_pulse(enemy, allies, bm)

# Способность 1: Тёмный импульс (Single Target, 100% СА)
static func _execute_dark_pulse(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("🌌 %s атакует «Тёмным импульсом» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.00)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 2: Сингулярный выброс (Blast, 80% основной / 40% смежным)
static func _execute_singular_blast(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("🌌 %s выпускает «Сингулярный выброс» по %s и соседям!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 0.80)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.40)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Тактика Пробития: Взрыв при пробитии уязвимости («Коллапс сингулярности»)
static func on_weakness_break(enemy: CombatUnit, bm: BattleManager) -> void:
	# Снимаем снижение урона пока стойкость пробита
	enemy.set_meta("dmg_reduction", 0.0)
	
	bm.log_message("💥 Сингулярность %s дестабилизирована! Происходит «Коллапс сингулярности»!" % enemy.display_name)
	var explode_dmg: float = enemy.stats.max_hp * 0.15

	# Наносим урон и истощаем стойкость другим врагам
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive() and e != enemy:
			bm.deal_damage(e, explode_dmg, null, CombatConstants.Element.QUANTUM, false, "Коллапс сингулярности")
			if not e.statuses.toughness_broken and e.toughness > 0.0:
				e.toughness = maxf(0.0, e.toughness - 15.0)
				if e.toughness <= 0.0:
					bm.break_enemy_toughness(e, null)
				bm.unit_updated.emit(e)

# Тактика Духов Памяти: Реакция на атаку Духа Памяти
static func on_attacked_by_memosprite(enemy: CombatUnit, memosprite: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("✨ «Эфирный резонанс»: Дух Памяти %s сокрушает сингулярность %s!" % [memosprite.display_name, enemy.display_name])
	# Дополнительное истощение стойкости на 25 ед. независимо от уязвимостей
	if not enemy.statuses.toughness_broken and enemy.toughness > 0.0:
		enemy.toughness = maxf(0.0, enemy.toughness - 25.0)
		if enemy.toughness <= 0.0:
			bm.break_enemy_toughness(enemy, memosprite)
		bm.unit_updated.emit(enemy)

	# Продвижение действия владельца духа на 15%
	var owner_unit: CombatUnit = null
	if memosprite.has_meta("owner_unit"):
		owner_unit = memosprite.get_meta("owner_unit")
	elif memosprite is Memosprite:
		owner_unit = memosprite.owner

	if owner_unit != null and owner_unit.is_alive():
		owner_unit.advance_action(15.0)
		bm.log_message("  ⏩ Действие %s продвинуто на 15%%!" % owner_unit.display_name)
		bm.action_order_changed.emit()
