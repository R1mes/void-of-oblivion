class_name OrtofetaminHorror
extends RefCounted

const ID: String = "ortofetamin_horror"
const SUMMON_INTERVAL: int = 3

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Ужас ортофетамина",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 95000,
			"atk": 2250, # Прежняя атака (2500) уменьшена на 250
			"def": 950,
			"spd": 102,
			"crit_rate": 0.10,
			"crit_dmg": 0.60,
			"effect_res": 0.25,
		},
		"toughness": 240,
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.ICE,
		],
	})
	unit.set_meta("base_hp_original", 95000.0)
	unit.set_meta("base_atk_original", 2250.0)
	unit.set_meta("base_def_original", 950.0)
	unit.set_meta("base_spd_original", 102.0)
	unit.set_meta("turn_count", 0)
	return unit

static func pick_target(allies: Array, prioritize_highest_atk: bool = false) -> CombatUnit:
	# 1. Провокация Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

	# 2. Приоритет наивысшей СА (Катарина / Керри)
	if prioritize_highest_atk:
		var max_atk: float = -1.0
		var top_target: CombatUnit = null
		for a in allies:
			if a is CombatUnit and a.is_alive():
				if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
					continue
				var cur_atk: float = a.stats.atk
				if cur_atk > max_atk:
					max_atk = cur_atk
					top_target = a
		if top_target != null:
			return top_target

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

	# Проверяем пассивку симбиоза с Зараженными
	_update_symbiosis_buff(enemy, bm)

	if turn == 1 or turn % SUMMON_INTERVAL == 0:
		_execute_toxic_summon(enemy, allies, bm)
	elif turn % 2 == 0:
		_execute_ortofetamin_injection(enemy, allies, bm)
	else:
		_execute_chemical_burst(enemy, allies, bm)

# Обновление пассивного снижения урона от свиты Заражённых
static func _update_symbiosis_buff(enemy: CombatUnit, bm: BattleManager) -> void:
	var infected_count: int = 0
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive() and e.id == "infected":
			infected_count += 1
	var dmg_reduction: float = minf(float(infected_count) * 0.10, 0.20)
	enemy.set_meta("orto_horror_symbiosis_reduction", dmg_reduction)
	if dmg_reduction > 0.0:
		bm.log_message("🛡 «Ортофетаминовый симбиоз»: %s защищён колонией Заражённых (%d шт.) -> входящий урон снижен на %d%%!" % [enemy.display_name, infected_count, int(dmg_reduction * 100.0)])

# Способность 1: Выброс мутагена (АоЕ + Призыв Зараженных)
static func _execute_toxic_summon(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("☣ %s: «Выброс мутагена»!" % enemy.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, ally, 0.60)
			bm.deal_damage(ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

	# Удаляем мертвых врагов для очистки слотов
	var to_remove: Array[CombatUnit] = []
	for e in bm.enemies:
		if e is CombatUnit and not e.is_alive():
			to_remove.append(e)
	for dead_e in to_remove:
		bm.enemies.erase(dead_e)

	# Призыв Заражённых
	var occupied_slots: Array[int] = []
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive():
			occupied_slots.append(e.slot_index)

	var living_count := occupied_slots.size()
	var spawn_limit := mini(2, 5 - living_count)
	if spawn_limit <= 0:
		if not to_remove.is_empty():
			bm.enemies_reshuffled.emit()
			bm.action_order_changed.emit()
		return

	var spawned := 0
	for s in range(5):
		if spawned >= spawn_limit:
			break
		if not s in occupied_slots:
			var inf := Infected.create_unit()
			inf.slot_index = s
			inf.display_name = "Заражённый"
			inf.recalculate_action_value()
			inf.action_value = inf.base_action_value
			bm.enemies.append(inf)
			occupied_slots.append(s)
			spawned += 1
			bm.log_message("🧬 На поле боя материализуется %s в слоте %d!" % [inf.display_name, s + 1])

	if spawned > 0:
		_update_symbiosis_buff(enemy, bm)
	if spawned > 0 or not to_remove.is_empty():
		bm.enemies_reshuffled.emit()
		bm.action_order_changed.emit()

# Способность 2: Ортофетаминовый впрыск (Фокус на гиперкерри, 180% СА)
static func _execute_ortofetamin_injection(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return
	bm.log_message("💉 %s: «Ортофетаминовый впрыск» по сильнейшему бойцу %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.80)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))
	
	# Ослабление атаки цели на 15% на 2 хода
	target.statuses.atk_buff_percent -= 0.15
	target.statuses.atk_buff_turns = 2
	target.statuses.atk_buff_source = "Ортофетаминовый яд"
	bm.log_message("  → СА %s снижена на 15%% на 2 хода!" % target.display_name)

# Способность 3: Химический разрыв (Blast: 120% цели, 60% соседям)
static func _execute_chemical_burst(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, false)
	if target == null:
		return
	bm.log_message("💥 %s: «Химический разрыв» по %s!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 1.20)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.60)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))
