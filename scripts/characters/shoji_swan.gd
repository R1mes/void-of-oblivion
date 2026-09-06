class_name ShojiSwanAbilities
extends RefCounted

const ID: String = "shoji_swan"
const MAX_ENERGY: float = 130.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сёдзи • Лебединое озеро",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3500,
			"atk": 1450,
			"def": 1000,
			"spd": 112,
			"crit_rate": 0.15,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("shoji_swan_e_unlocked", false)
	unit.set_meta("shoji_swan_enhanced_basic", false)
	unit.set_meta("shoji_swan_q_cooldown_turns", 0)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_console_member", true)

	var is_slot_1 := (bm.allies.size() > 0 and bm.allies[0] == unit)
	if is_slot_1:
		unit.set_meta("shoji_swan_stance", "virus")
		bm.log_message("🦢 Талант Сёдзи: Позиция 1 в отряде — активировано постоянное состояние «Вирус» (Главный ДД Консоли)!")
	else:
		unit.set_meta("shoji_swan_stance", "dance")
		bm.log_message("🦢 Талант Сёдзи: Позиция саппорта — активировано постоянное состояние «Танец» (+20%% Скорости, +30%% не-Бинарного урона отряда)!")
		for ally in bm.allies:
			if ally.is_alive():
				ally.add_speed_modifier(0.20, 0.0)

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)

	# След 1: Базовая атака восстанавливает 3 Вектора
	bm.add_console_vectors(3)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🦢 %s — Базовая атака по %s: %d урона. Получено +3 Вектора." % [attacker.display_name, target.display_name, int(dmg)])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# Кэшируем соседей до нанесения урона и возможной гибели цели
	var adj := bm.get_adjacent_enemies(target)

	var res := bm.calc_dmg(attacker, target, 1.30, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var main_dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, main_dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)

	for e in adj:
		if e.is_alive():
			var adj_res := bm.calc_dmg(attacker, e, 0.40, 0.0, false, 0.0, 0.0, false, true, "Basic")
			bm.deal_damage(e, float(adj_res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(adj_res.get("crit", false)), "Basic")
			ToughnessSystem.apply_weakness_hit(attacker, e, bm, 0.5)

	# Восстанавливает 10 Векторов + 3 от Следа 1 = 13 Векторов
	bm.add_console_vectors(13)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	attacker.set_meta("shoji_swan_enhanced_basic", false)
	bm.log_message("🦢 %s — Усиленная базовая атака по %s: %d урона (и соседям по 40%% СА). Получено +13 Векторов." % [attacker.display_name, target.display_name, int(main_dmg)])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var stance: String = String(attacker.get_meta("shoji_swan_stance", "virus"))
	if stance == "virus":
		attacker.set_meta("is_binary_attack", true)
		if target != null and target.is_alive():
			# Кэшируем соседей до нанесения урона
			var adj := bm.get_adjacent_enemies(target)

			var res := bm.calc_dmg(attacker, target, 1.80, 0.0, false, 0.0, 0.0, false, true, "Binary")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(target, dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)

			for e in adj:
				if e.is_alive():
					var adj_res := bm.calc_dmg(attacker, e, 0.60, 0.0, false, 0.0, 0.0, false, true, "Binary")
					bm.deal_damage(e, float(adj_res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(adj_res.get("crit", false)), "Binary")
					ToughnessSystem.apply_weakness_hit(attacker, e, bm, 1.0)

			bm.log_message("🦢 Навык Q Сёдзи (Вирус): %d Бинарного урона по %s и 60%% соседям!" % [int(dmg), target.display_name])
		attacker.remove_meta("is_binary_attack")
	else:
		# Состояние «Танец»: задержка всех врагов на (Векторы/3) + 10%
		var cur_vectors: int = bm.get_console_vectors()
		var delay_pct: float = (float(cur_vectors) / 3.0) + 10.0
		for enemy in bm.get_living_enemies():
			enemy.delay_action(delay_pct)
		bm.log_message("🦢 Навык Q Сёдзи (Танец): действие всех врагов задержано на %.1f%% (%d Векторов)!" % [delay_pct, cur_vectors])

		attacker.set_meta("shoji_swan_q_cooldown_turns", 2)
		attacker.set_meta("shoji_swan_enhanced_basic", true)
		bm.log_message("🦢 Навык Q заблокирован на 2 хода, следующая базовая атака Сёдзи стала Усиленной!")

	bm.gain_energy_with_err(attacker, 30.0)
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	# Конус «Идеальный метаморфоз»: гарантированное наложение статуса «Сияние» ПЕРВЫМ ДЕЛОМ до нанесения урона и подрыва!
	if attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis":
		for enemy in bm.get_living_enemies():
			enemy.set_meta("radiance_status_turns", 1)
			enemy.set_meta("radiance_owner", attacker)
			bm.log_message("🦋 Конус «Идеальный метаморфоз»: на %s наложен статус «Сияние» (Горение) на 1 ход." % enemy.display_name)

	attacker.set_meta("is_binary_attack", true)
	var living := bm.get_living_enemies()
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, 1.20, 0.0, false, 0.0, 0.0, false, true, "Binary")
		bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			
	attacker.remove_meta("is_binary_attack")

	# Подрыв всех DoT на всех врагах с эффективностью 30% (включая только что наложенное Сияние)
	var total_dots: int = 0
	for enemy in bm.get_living_enemies():
		total_dots += bm.explode_dots(enemy, attacker, 0.30)

	if total_dots > 0:
		bm.add_console_vectors(total_dots)
		bm.log_message("🦢 Навык E Сёдзи: подорвано %d DoT-эффектов! Восстановлено +%d Векторов." % [total_dots, total_dots])

	# Е4: Использование Навыка Е восстанавливает 20 Векторов
	if attacker.eidolon >= 4:
		bm.add_console_vectors(20)
		bm.log_message("💎 Е4 Сёдзи: Навык E восстановил +20 Векторов!")

	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	# Конус «Идеальный метаморфоз»: гарантированное наложение статуса «Сияние» ПЕРВЫМ ДЕЛОМ до нанесения урона
	if attacker.get_meta("light_cone_id", "") == "perfect_metamorphosis":
		for enemy in bm.get_living_enemies():
			enemy.set_meta("radiance_status_turns", 1)
			enemy.set_meta("radiance_owner", attacker)
			bm.log_message("🦋 Конус «Идеальный метаморфоз»: на %s наложен статус «Сияние» (Горение) на 1 ход." % enemy.display_name)

	var stance: String = String(attacker.get_meta("shoji_swan_stance", "virus"))
	var living := bm.get_living_enemies()

	if stance == "virus":
		attacker.set_meta("is_binary_attack", true)
		attacker.set_meta("shoji_swan_ult_virus_bonus", 0.40)
		for enemy in living:
			var res := bm.calc_dmg(attacker, enemy, 1.50, 0.0, false, 0.0, 0.0, false, true, "Binary")
			bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
		attacker.remove_meta("shoji_swan_ult_virus_bonus")
		attacker.remove_meta("is_binary_attack")
		bm.log_message("🦢 СВЕРХСПОСОБНОСТЬ СЁДЗИ (Вирус): 150%% СА Бинарного урона (+40%% бонус урона) по всем врагам!")
	else:
		var cur_vectors: int = bm.get_console_vectors()
		var vuln_pct: float = float(cur_vectors) * 0.01
		var e1_dmg_mult: float = 1.0

		if attacker.eidolon >= 1:
			vuln_pct = 0.90
			e1_dmg_mult += float(cur_vectors) * 0.01

		attacker.set_meta("is_binary_attack", true)
		for enemy in living:
			var res := bm.calc_dmg(attacker, enemy, 1.50 * e1_dmg_mult, 0.0, false, 0.0, 0.0, false, true, "Binary")
			bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
			enemy.set_meta("shoji_swan_dance_vuln_turns", 2)
			enemy.set_meta("shoji_swan_dance_vuln_skip_tick", true)
			enemy.set_meta("shoji_swan_dance_vuln_pct", vuln_pct)
		attacker.remove_meta("is_binary_attack")
		bm.log_message("🦢 СВЕРХСПОСОБНОСТЬ СЁДЗИ (Танец): 150%% СА урона по всем врагам, наложена уязвимость ко всем видам урона +%.0f%% на 2 хода!" % [vuln_pct * 100.0])

	# След 2: повышение своей скорости на 20% на 3 хода
	if not attacker.has_meta("shoji_swan_trace2_spd_active"):
		attacker.set_meta("shoji_swan_trace2_spd_active", true)
		attacker.add_speed_modifier(0.20, 0.0)
	attacker.set_meta("shoji_swan_trace2_spd_turns", 3)
	attacker.set_meta("shoji_swan_trace2_spd_skip_tick", true)
	bm.log_message("⚡ След 2 Сёдзи: Скорость Сёдзи повышена на +20%% на 3 хода!")

	bm.unit_updated.emit(attacker)

static func apply_technique(enemies: Array, attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("is_binary_attack", true)
	for enemy in enemies:
		if enemy is CombatUnit and enemy.is_alive():
			var res := bm.calc_dmg(attacker, enemy, 1.00, 0.0, false, 0.0, 0.0, false, true, "Binary")
			bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Binary")
			enemy.set_meta("shoji_swan_tech_vuln_turns", 2)
			enemy.set_meta("shoji_swan_tech_vuln_skip_tick", true)
	attacker.remove_meta("is_binary_attack")
	bm.log_message("⚔ Атакующая техника Сёдзи: нанесено 100%% СА Бинарного урона всем врагам, наложена уязвимость ко всему урону +30%% на 2 хода!")
