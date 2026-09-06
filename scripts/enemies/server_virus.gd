class_name ServerVirus
extends RefCounted

const ID: String = "server_virus"
const OVERFLOW_INTERVAL: int = 4
const TROJAN_INTERVAL: int = 4

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Серверный Вирус",
		"element": CombatConstants.Element.LIGHTNING,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 405000,
			"atk": 2600,
			"def": 1100,
			"spd": 105,
			"crit_rate": 0.15,
			"crit_dmg": 0.60,
			"effect_res": 0.35,
		},
		"toughness": 360,
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.WIND,
		],
	})
	unit.set_meta("server_virus_firewall", 4)
	unit.set_meta("turn_count", 0)
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

	# Восстановление слоев Брандмауэра каждые 3 хода
	if turn > 1 and turn % 3 == 0:
		enemy.set_meta("server_virus_firewall", 4)
		bm.log_message("🛡 Серверный Вирус восстанавливает 4 слоя Антивирусного Брандмауэра!")

	if turn % OVERFLOW_INTERVAL == 0:
		_execute_buffer_overflow(enemy, allies, bm)
	elif turn % TROJAN_INTERVAL == 2:
		_execute_trojan_script(enemy, allies, bm)
	else:
		_execute_packet_delay(enemy, allies, bm)

# Способность 1: Переполнение буфера (АоЕ)
static func _execute_buffer_overflow(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("💥 Серверный Вирус запускает «Переполнение буфера»!")
	var cur_vectors := bm.get_console_vectors()
	var has_vector_protection := cur_vectors >= 20
	var total_dealt := 0.0

	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var mult := 1.20
			if has_vector_protection:
				mult = 0.84 # Защита Векторов Консоли (20+ Векторов) снижает урон на 30%
			var res: Dictionary = bm.calc_dmg(enemy, ally, mult)
			var dmg_val: float = float(res.get("damage", 0.0))
			bm.deal_damage(ally, dmg_val, enemy, enemy.element, bool(res.get("crit", false)))
			total_dealt += dmg_val

			if not has_vector_protection:
				# Штраф при недостатке Векторов: потеря 15% макс. энергии и -20% СА
				ally.energy = maxf(0.0, ally.energy - ally.max_energy * 0.15)
				ally.statuses.atk_buff_percent = -0.20
				ally.statuses.atk_buff_turns = 2
				ally.statuses.atk_buff_source = "Переполнение буфера"

	if has_vector_protection:
		var reflect_dmg: float = total_dealt * 0.10
		bm.deal_damage(enemy, reflect_dmg, null, -1, false, "True Damage")
		bm.add_console_vectors(5)
		bm.log_message("🌐 Защита Консоли (20+ Векторов): урон снижен на 30%%, отражено %d чист. урона, получено +5 Векторов!" % int(reflect_dmg))
	else:
		bm.log_message("⚠ Нехватка Векторов (<20): команда понесла полный урон, потеряла 15%% энергии и ослаблена на -20%% СА!")

# Способность 2: Троянский скрипт (таргетинг наивысшей СА или провокация Данилла)
static func _execute_trojan_script(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target_ally: CombatUnit = null

	# 1. Проверяем провокацию Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				target_ally = a
				break

	# 2. Если провокации нет — выбираем союзника с наивысшей СА
	if target_ally == null:
		var max_atk: float = -1.0
		for a in allies:
			if a is CombatUnit and a.is_alive():
				if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
					continue
				var eff_atk: float = bm.get_effective_atk_complete(a)
				if eff_atk > max_atk:
					max_atk = eff_atk
					target_ally = a

	if target_ally == null:
		for a in allies:
			if a is CombatUnit and a.is_alive():
				target_ally = a
				break

	if target_ally == null:
		return

	bm.log_message("👾 Серверный Вирус внедряет «Троянский скрипт» в %s!" % target_ally.display_name)
	var shield_val: float = float(target_ally.get_meta("shield_value", 0.0))
	var has_shield := shield_val > 0.0 or target_ally.statuses.incoming_heal_bonus > 0.0

	if has_shield:
		var reflect := target_ally.stats.atk * 1.0
		bm.deal_damage(enemy, reflect, target_ally, -1, false, "True Damage")
		bm.log_message("🛡 Защитный барьер %s изолировал Троян! Отражено %d чист. урона в босса." % [target_ally.display_name, int(reflect)])
	else:
		target_ally.set_meta("trojan_turns", 2)
		target_ally.set_meta("trojan_source_atk", enemy.stats.atk)
		var res: Dictionary = bm.calc_dmg(enemy, target_ally, 1.0)
		bm.deal_damage(target_ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))
		bm.log_message("  → %s заражён Трояном на 2 хода!" % target_ally.display_name)

# Способность 3: Задержка пакетов (Blast)
static func _execute_packet_delay(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return

	bm.log_message("⚡ Серверный Вирус использует «Задержку пакетов» по %s!" % target.display_name)
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 1.10)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))
	target.add_speed_modifier(-0.15, 0.0) # -15% скорости
	target.set_meta("packet_delay_turns", 2)

	var adjacent := bm.get_adjacent_allies(target)
	for adj in adjacent:
		if adj is CombatUnit and adj.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, adj, 0.50)
			bm.deal_damage(adj, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))
			adj.add_speed_modifier(-0.15, 0.0)
			adj.set_meta("packet_delay_turns", 2)
