class_name CitadelCleaner
extends RefCounted

const ID: String = "citadel_cleaner"

static func create_unit(slot_idx: int = 0, is_hacked: bool = false) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Чистильщик Цитадели" if not is_hacked else "Чистильщик Цитадели [Взломан]",
		"element": CombatConstants.Element.FIRE,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 12000,
			"atk": 1250, # Прежняя атака (1500) уменьшена на 250
			"def": 600,
			"spd": 98,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.15,
		},
		"toughness": 60,
		"weaknesses": [
			CombatConstants.Element.WIND,
			CombatConstants.Element.FIRE,
		],
	})
	unit.slot_index = slot_idx
	unit.set_meta("base_hp_original", 12000.0)
	unit.set_meta("base_atk_original", 1250.0)
	unit.set_meta("base_def_original", 600.0)
	unit.set_meta("base_spd_original", 98.0)
	unit.set_meta("turn_count", 0)
	unit.set_meta("is_hacked", is_hacked)
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

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	# Чередуем способности: каждый четный ход — «Импульс фильтрации», иначе «Протокол стерилизации»
	if turn % 2 == 0:
		_execute_filtration_pulse(enemy, allies, bm)
	else:
		_execute_sterilization(enemy, allies, bm)

# Способность 1: Протокол стерилизации (Single Target, 100% СА)
static func _execute_sterilization(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("🤖 %s: «Протокол стерилизации» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.00)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 2: Импульс фильтрации (Blast, 80% цели / 40% соседям + шанс Горения)
static func _execute_filtration_pulse(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("🤖 %s: «Импульс фильтрации» по %s и смежным союзникам!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 0.80)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.40)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

	# 50% шанс наложить Горение на 2 хода
	if randf() < 0.50 and target.statuses.break_status == "":
		target.statuses.break_status = "Горение"
		target.statuses.break_status_turns = 2
		target.statuses.break_status_source = enemy.display_name
		bm.log_message("  → %s получил статус Горение на 2 хода!" % target.display_name)

# Пассивка: Сенсорная перегрузка от DoT / Бинарного урона
static func trigger_sensor_overload(cleaner: CombatUnit, bm: BattleManager) -> void:
	if not cleaner.has_meta("sensor_overload_cooldown"):
		cleaner.set_meta("sensor_overload_cooldown", true)
		cleaner.set_meta("cleaner_def_reduction_turns", 2)
		cleaner.set_meta("cleaner_def_reduction_pct", 0.10)
		cleaner.delay_action(15.0)
		bm.log_message("⚡ «Сенсорная перегрузка» %s: цепи перегружены! Защита снижена на 10%% на 2 хода, действие задержано на 15%%!" % cleaner.display_name)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(cleaner)

# Взрыв Взломанного Чистильщика при гибели
static func on_hacked_death_explode(cleaner: CombatUnit, bm: BattleManager) -> void:
	if not bool(cleaner.get_meta("is_hacked", false)):
		return

	bm.log_message("💥 Взломанный %s взрывается при уничтожении!" % cleaner.display_name)
	var explode_dmg: float = cleaner.stats.max_hp * 0.06

	# Наносим урон другим врагам
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive() and e != cleaner:
			bm.deal_damage(e, explode_dmg, null, CombatConstants.Element.PHYSICAL, false, "Взрыв взломанного ядра")
			
			# Накладываем статус Кровотечение на 2 хода (складывается до 2 раз)
			var cur_bleed: int = int(e.get_meta("hacked_bleed_stacks", 0))
			if cur_bleed < 2:
				cur_bleed += 1
				e.set_meta("hacked_bleed_stacks", cur_bleed)
			e.set_meta("hacked_bleed_turns", 2)
			e.set_meta("hacked_bleed_source", cleaner.display_name)
			bm.log_message("  🩸 %s заражён Кровотечением! (Стаков: %d/2, длительность 2 хода)" % [e.display_name, cur_bleed])
			bm.unit_updated.emit(e)
