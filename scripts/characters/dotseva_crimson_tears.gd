class_name DotsevaCrimsonTearsAbilities
extends RefCounted

const ID: String = "dotseva_crimson_tears"
const MAX_ENERGY: float = 100.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Доцева • Багровые слёзы",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.PRESERVATION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 4000,
			"atk": 1900,
			"def": 1200,
			"spd": 102,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.20,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("doceva_tears_zone_active", false)
	unit.set_meta("doceva_tears_zone_turns", 0)
	unit.set_meta("doceva_tears_talent_stacks", 0)
	unit.set_meta("doceva_tears_enhanced_q_counter", 0)
	unit.set_meta("doceva_tears_e1_heal_cd", 0)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	# След 1: Во время активации зоны, макс. хп Доцевой повышается на 1% за каждую единицу скорости союзников свыше 100 (макс: +200%)
	unit.set_meta("doceva_tears_trace1_unlocked", true)

	# След 2: Получаемый Доцевой урон уменьшается на 30%
	unit.set_meta("doceva_tears_trace2_dmg_red", 0.30)
	bm.log_message("🛡 След 2 Доцевой: Входящий урон Доцевой постоянно снижен на 30%%.")

static func update_trace1_hp_bonus(unit: CombatUnit, bm: BattleManager) -> void:
	if not bool(unit.get_meta("doceva_tears_trace1_unlocked", false)):
		return

	# Если бонус уже был применен, снимаем его перед перепроверкой
	var prev_bonus: float = float(unit.get_meta("doceva_tears_trace1_flat_bonus", 0.0))
	if prev_bonus > 0.0:
		unit.stats.max_hp -= prev_bonus
		unit.stats.hp = minf(unit.stats.hp, unit.stats.max_hp)
		unit.set_meta("doceva_tears_trace1_flat_bonus", 0.0)

	var speed_excess_sum: float = 0.0
	for ally in bm.allies:
		if ally.is_alive() and ally != unit:
			var spd_val: float = ally.stats.get_effective_spd()
			if spd_val > 100.0:
				speed_excess_sum += (spd_val - 100.0)

	var bonus_pct: float = clampf(speed_excess_sum * 0.01, 0.0, 2.00)
	if bonus_pct > 0.0:
		var hp_gain: float = unit.stats.max_hp * bonus_pct
		unit.stats.max_hp += hp_gain
		unit.stats.hp += hp_gain
		unit.set_meta("doceva_tears_trace1_flat_bonus", hp_gain)
		bm.log_message("🩸 След 1 Доцевой: Превышение скорости отряда (+%.0f ед.) увеличило макс. ХП Доцевой на +%.1f%% (+%d ХП, макс. +200%%)!" % [speed_excess_sum, bonus_pct * 100.0, int(hp_gain)])

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 0.65, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)

	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🩸 %s — Базовая атака по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg)])

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var zone_active: bool = bool(attacker.get_meta("doceva_tears_zone_active", false))
	if zone_active:
		execute_enhanced_skill_q(attacker, target, bm)
	else:
		# Обычный Навык Q: 90% СА всем врагам на поле
		var enemies := bm.get_living_enemies()
		var total_dmg := 0.0
		for enemy in enemies:
			var res := bm.calc_dmg(attacker, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(enemy, dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			total_dmg += dmg

		bm.gain_energy_with_err(attacker, 30.0)
		bm.log_message("🩸 %s — Навык Q по всем врагам: %d общего урона." % [attacker.display_name, int(total_dmg)])

static func execute_enhanced_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var enemies := bm.get_living_enemies()
	if target == null or not target.is_alive():
		if not enemies.is_empty():
			target = enemies[0]
		else:
			return

	var res_main := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var main_dmg: float = float(res_main.get("damage", 0.0))
	bm.deal_damage(target, main_dmg, attacker, CombatConstants.Element.WIND, bool(res_main.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)

	var adj := bm.get_adjacent_enemies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj := bm.calc_dmg(attacker, neighbor, 0.50, 0.0, false, 0.0, 0.0, false, true, "Skill")
			var adj_dmg: float = float(res_adj.get("damage", 0.0))
			bm.deal_damage(neighbor, adj_dmg, attacker, CombatConstants.Element.WIND, bool(res_adj.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, neighbor, bm, 0.5)

	# Получаемый центральной целью урон увеличивается на 15% на 2 хода
	target.set_meta("doceva_tears_q_vuln_turns", 2)
	target.set_meta("doceva_tears_q_vuln_skip_tick", true)
	target.set_meta("doceva_tears_q_vuln_pct", 0.15)
	bm.log_message("🩸 Улучшенный Навык Q: %s получает статус «Уязвимость» (+15%% получаемого урона) на 2 хода." % target.display_name)
	# Дебафф союзника триггерит талант Доцевой
	add_close_your_eyes_stack(attacker, bm)

	# Лечит себя на 25% СА + 200, и всех союзников на 7% СА + 80
	var heal_self: float = attacker.stats.atk * 0.25 + 200.0
	bm.heal_unit(attacker, heal_self)
	var heal_allies: float = attacker.stats.atk * 0.07 + 80.0
	for ally in bm.allies:
		if ally.is_alive() and ally != attacker:
			bm.heal_unit(ally, heal_allies)
	bm.log_message("🩸 Улучшенный Навык Q: Доцева вылечила себя на %d ХП, а команду на %d ХП." % [int(heal_self), int(heal_allies)])

	# След 3: Если центральная цель имеет > 6 ослаблений, восстанавливает 1 ОН (1 раз за 2 каста)
	var debuff_count := _count_enemy_debuffs(target, bm)
	var q_cnt: int = int(attacker.get_meta("doceva_tears_enhanced_q_counter", 0)) + 1
	attacker.set_meta("doceva_tears_enhanced_q_counter", q_cnt)
	if debuff_count > 6 and (q_cnt % 2 == 1):
		bm.gain_skill_point()
		bm.log_message("⚡ След 3: У цели %d дебаффов (>6)! Доцева восстановила +1 Очко навыков." % debuff_count)

	# E6: Улучшенный Навык Q наносит поражённым врагам дополнительный чистый урон, равный 50% от общей СА отряда
	if attacker.eidolon >= 6:
		var total_team_atk: float = 0.0
		for ally in bm.allies:
			if ally.is_alive():
				total_team_atk += ally.stats.atk
		var extra_true_dmg: float = total_team_atk * 0.50
		bm.deal_damage(target, extra_true_dmg, attacker, -1, false, "True Damage")
		for neighbor in adj:
			if neighbor.is_alive():
				bm.deal_damage(neighbor, extra_true_dmg, attacker, -1, false, "True Damage")
		bm.log_message("🩸 Эйдолон 6: Улучшенный Навык Q нанёс %d доп. чистого урона (50%% СА отряда)!" % int(extra_true_dmg))

	bm.gain_energy_with_err(attacker, 30.0)

static func execute_skill_e(attacker: CombatUnit, target_ally: CombatUnit, bm: BattleManager) -> void:
	if target_ally == null or not target_ally.is_alive():
		# Если союзник не выбран, выбираем первого живого союзника кроме Доцевой, или саму Доцеву
		for ally in bm.allies:
			if ally.is_alive() and ally != attacker:
				target_ally = ally
				break
		if target_ally == null:
			target_ally = attacker

	# Снимаем бафф крит. шанса с предыдущего союзника, если цель изменилась
	var prev_guarded: CombatUnit = attacker.get_meta("doceva_tears_guarded_ally") if attacker.has_meta("doceva_tears_guarded_ally") else null
	if prev_guarded != null and prev_guarded != target_ally:
		if prev_guarded.has_meta("doceva_tears_crit_buff") and bool(prev_guarded.get_meta("doceva_tears_crit_buff")):
			prev_guarded.stats.crit_rate -= 0.20
			prev_guarded.remove_meta("doceva_tears_crit_buff")
			bm.unit_updated.emit(prev_guarded)

	attacker.set_meta("doceva_tears_zone_active", true)
	attacker.set_meta("doceva_tears_zone_turns", 3)
	attacker.set_meta("doceva_tears_guarded_ally", target_ally)

	# Пассивка: Крит. шанс союзника, выбранного Навыком E, повышается на 20% пока активна Зона
	if target_ally != null and not bool(target_ally.get_meta("doceva_tears_crit_buff", false)):
		target_ally.stats.crit_rate += 0.20
		target_ally.set_meta("doceva_tears_crit_buff", true)
		bm.log_message("🩸 Навык E Доцевой: Крит. шанс %s повышен на +20%% на время действия Зоны!" % target_ally.display_name)
		bm.unit_updated.emit(target_ally)

	# След 1: Перепроверка и применение бонуса макс. ХП от скорости союзников при активации Зоны
	update_trace1_hp_bonus(attacker, bm)

	# Статусы защиты для команды
	for ally in bm.allies:
		if ally.is_alive():
			if ally == target_ally:
				ally.set_meta("doceva_tears_guarded_immune", true)
				ally.remove_meta("doceva_tears_ally_damage_reduced")
			elif ally != attacker:
				ally.set_meta("doceva_tears_ally_damage_reduced", true)
				ally.remove_meta("doceva_tears_guarded_immune")
			else:
				ally.remove_meta("doceva_tears_guarded_immune")
				ally.remove_meta("doceva_tears_ally_damage_reduced")
			bm.unit_updated.emit(ally)

	# E1: Персонаж имеет больший шанс быть выбранным врагом (+40% агро)
	if attacker.eidolon >= 1:
		target_ally.set_meta("doceva_tears_aggro_bonus", 0.40)

	# E4: Пока действует зона, макс. хп всех союзников повышается на 30%
	if attacker.eidolon >= 4 and not bool(attacker.get_meta("doceva_tears_e4_active", false)):
		attacker.set_meta("doceva_tears_e4_active", true)
		for ally in bm.allies:
			if ally.is_alive():
				var old_max := ally.stats.max_hp
				ally.stats.max_hp *= 1.30
				var gained_hp := ally.stats.max_hp - old_max
				ally.stats.hp += gained_hp
		bm.log_message("🩸 Эйдолон 4 Доцевой: Макс. ХП всех союзников повышено на +30%% во время действия Зоны!")

	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🛡 %s развернула защитную Зону на 3 хода! 100%% урона по %s и 80%% урона команды перенаправляются на Доцеву." % [attacker.display_name, target_ally.display_name])

static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.energy = 0.0
	var enemies := bm.get_living_enemies()
	var total_dmg := 0.0
	var is_e2 := attacker.eidolon >= 2

	for enemy in enemies:
		var res := bm.calc_dmg(attacker, enemy, 1.00, 0.0, false, 0.0, 0.0, false, true, "Ultimate")
		var dmg: float = float(res.get("damage", 0.0))
		bm.deal_damage(enemy, dmg, attacker, CombatConstants.Element.WIND, bool(res.get("crit", false)), "Ultimate")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
		total_dmg += dmg

		# Уменьшает наносимый ими урон на 30% на 2 хода
		enemy.set_meta("doceva_tears_outgoing_dmg_red_turns", 2)
		enemy.set_meta("doceva_tears_outgoing_dmg_red_skip_tick", true)
		enemy.set_meta("doceva_tears_outgoing_dmg_red_pct", 0.30)

		# E2: Враги получают на 40% больше урона в течение 2 ходов
		if is_e2:
			enemy.set_meta("doceva_tears_e2_vuln_turns", 2)
			enemy.set_meta("doceva_tears_e2_vuln_skip_tick", true)
			enemy.set_meta("doceva_tears_e2_vuln_pct", 0.40)

		add_close_your_eyes_stack(attacker, bm)

	bm.log_message("🩸 Сверхспособность Доцевой по всем врагам: %d общего урона. Наносимый врагами урон снижен на 30%% на 2 хода%s." % [int(total_dmg), " (+40%% уязвимость врагов от E2)" if is_e2 else ""])

static func add_close_your_eyes_stack(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	var cur_stacks: int = int(doceva_unit.get_meta("doceva_tears_talent_stacks", 0))
	if cur_stacks < 15:
		cur_stacks += 1
		doceva_unit.set_meta("doceva_tears_talent_stacks", cur_stacks)
		bm.log_message("👁 Талант Доцевой: Получен статус «Закрой глаза» (%d/15)! СА всех союзников +%d%%." % [cur_stacks, cur_stacks * 3])
		_apply_close_your_eyes_buff(doceva_unit, bm)

static func _apply_close_your_eyes_buff(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	var stacks: int = int(doceva_unit.get_meta("doceva_tears_talent_stacks", 0))
	var atk_pct: float = stacks * 0.03
	for ally in bm.allies:
		if ally.is_alive():
			ally.set_meta("doceva_tears_atk_buff_pct", atk_pct)

static func on_turn_start(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	# Уменьшение ходов отката E1
	var heal_cd: int = int(doceva_unit.get_meta("doceva_tears_e1_heal_cd", 0))
	if heal_cd > 0:
		doceva_unit.set_meta("doceva_tears_e1_heal_cd", heal_cd - 1)

	# Длительность зоны уменьшается на 1 ход в начале каждого хода Доцевой
	if bool(doceva_unit.get_meta("doceva_tears_zone_active", false)):
		var turns: int = int(doceva_unit.get_meta("doceva_tears_zone_turns", 0)) - 1
		doceva_unit.set_meta("doceva_tears_zone_turns", turns)
		bm.log_message("🛡 Зона Доцевой: Осталось ходов: %d." % turns)
		if turns <= 0:
			end_zone(doceva_unit, bm)

static func end_zone(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	doceva_unit.set_meta("doceva_tears_zone_active", false)
	doceva_unit.set_meta("doceva_tears_zone_turns", 0)
	var guarded: CombatUnit = doceva_unit.get_meta("doceva_tears_guarded_ally") if doceva_unit.has_meta("doceva_tears_guarded_ally") else null
	if guarded != null:
		guarded.remove_meta("doceva_tears_aggro_bonus")
		if guarded.has_meta("doceva_tears_crit_buff") and bool(guarded.get_meta("doceva_tears_crit_buff")):
			guarded.stats.crit_rate -= 0.20
			guarded.remove_meta("doceva_tears_crit_buff")
			bm.log_message("🩸 Навык E Доцевой: Зона завершилась, бонус +20%% крит. шанса с %s снят." % guarded.display_name)
			bm.unit_updated.emit(guarded)
	if doceva_unit.has_meta("doceva_tears_guarded_ally"):
		doceva_unit.remove_meta("doceva_tears_guarded_ally")

	# След 1: Снятие бонуса макс. ХП при завершении действия Зоны
	var prev_bonus: float = float(doceva_unit.get_meta("doceva_tears_trace1_flat_bonus", 0.0))
	if prev_bonus > 0.0:
		doceva_unit.stats.max_hp -= prev_bonus
		doceva_unit.stats.hp = minf(doceva_unit.stats.hp, doceva_unit.stats.max_hp)
		doceva_unit.set_meta("doceva_tears_trace1_flat_bonus", 0.0)
		bm.log_message("🩸 След 1 Доцевой: Зона завершилась, бонус макс. ХП снят (ХП: %d/%d)." % [int(doceva_unit.stats.hp), int(doceva_unit.stats.max_hp)])
		bm.unit_updated.emit(doceva_unit)

	# Очистка статусов защиты со всех союзников
	for ally in bm.allies:
		if ally.has_meta("doceva_tears_guarded_immune"):
			ally.remove_meta("doceva_tears_guarded_immune")
		if ally.has_meta("doceva_tears_ally_damage_reduced"):
			ally.remove_meta("doceva_tears_ally_damage_reduced")
		bm.unit_updated.emit(ally)

	# Снятие E4 баффа на макс. ХП
	if bool(doceva_unit.get_meta("doceva_tears_e4_active", false)):
		doceva_unit.set_meta("doceva_tears_e4_active", false)
		for ally in bm.allies:
			if ally.is_alive():
				ally.stats.max_hp /= 1.30
				ally.stats.hp = minf(ally.stats.hp, ally.stats.max_hp)
		bm.log_message("🛡 Действие Зоны завершено. Бонус E4 к макс. ХП снят.")

static func on_ally_turn_started(doceva_unit: CombatUnit, ally: CombatUnit, bm: BattleManager) -> void:
	# E6: Каждый ход союзников продвигает действие Доцевой на 15%
	if doceva_unit.eidolon >= 6 and ally != doceva_unit and doceva_unit.is_alive():
		doceva_unit.advance_action(15.0)
		bm.action_order_changed.emit()
		bm.log_message("🩸 Эйдолон 6: Ход %s продвинул действие Доцевой на +15%%!" % ally.display_name)

static func check_e1_emergency_heal(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	if doceva_unit.eidolon < 1 or not doceva_unit.is_alive():
		return
	var cd: int = int(doceva_unit.get_meta("doceva_tears_e1_heal_cd", 0))
	if cd > 0:
		return

	# Проверяем, стало ли ХП любого союзника ниже 25%
	var need_heal := false
	for ally in bm.allies:
		if ally.is_alive() and (ally.stats.hp / ally.stats.max_hp) < 0.25:
			need_heal = true
			break

	if need_heal:
		doceva_unit.set_meta("doceva_tears_e1_heal_cd", 4)
		var heal_val: float = doceva_unit.stats.atk * 0.15
		for ally in bm.allies:
			if ally.is_alive():
				bm.heal_unit(ally, heal_val)
		bm.log_message("🚨 Эйдолон 1 Доцевой: ХП союзника опустилось ниже 25%%! Экстренное лечение команды на %d ХП (15%% СА Доцевой, откат 4 хода)!" % int(heal_val))

static func _count_enemy_debuffs(enemy: CombatUnit, bm: BattleManager = null) -> int:
	if bm != null:
		return bm.get_unit_debuff_count(enemy)
	var count := 0
	if enemy.has_meta("def_reductions"):
		var reds: Dictionary = enemy.get_meta("def_reductions")
		count += reds.size()
	if int(enemy.get_meta("doceva_tears_q_vuln_turns", 0)) > 0: count += 1
	if int(enemy.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0: count += 1
	if int(enemy.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0: count += 1
	if int(enemy.get_meta("katarina_vuln_turns", 0)) > 0: count += 1
	if bool(enemy.get_meta("katarina_broken_spirit", false)): count += 1
	if int(enemy.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0: count += 1
	if int(enemy.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0: count += 1
	if int(enemy.get_meta("intox_stacks", 0)) > 0: count += 1
	return count

static func apply_technique(doceva_unit: CombatUnit, bm: BattleManager) -> void:
	# Моментально разворачивает зону, описанную в Навыке Е и восстанавливает 1 очко навыков
	# Цель: первый союзник в отряде, а если Доцева первая — то второй
	var target_ally: CombatUnit = null
	if not bm.allies.is_empty():
		if bm.allies[0] != doceva_unit and bm.allies[0].is_alive():
			target_ally = bm.allies[0]
		elif bm.allies.size() > 1 and bm.allies[1].is_alive():
			target_ally = bm.allies[1]
		elif bm.allies[0].is_alive():
			target_ally = bm.allies[0]
	if target_ally == null:
		target_ally = doceva_unit

	execute_skill_e(doceva_unit, target_ally, bm)
	bm.gain_skill_point()
	bm.log_message("🩸 Техника Доцевой: Зона развернута на старте боя (цель: %s), получено +1 Очко навыков!" % target_ally.display_name)
