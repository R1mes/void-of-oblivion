class_name KatarinaAbilities
extends RefCounted

const ID: String = "katarina"
const MAX_ENERGY: float = 120.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Катарина",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3200,
			"atk": 2100,
			"def": 750,
			"spd": 104,
			"crit_rate": 0.15,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.20,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("katarina_just_a_memory_turns", 0)
	unit.set_meta("katarina_actions_no_dmg", 0)
	unit.set_meta("katarina_prove_it_active", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	# Проверяем количество союзников пути Небытия
	var nihility_count := 0
	for ally in bm.allies:
		if ally.is_alive() and ally.path == CombatConstants.Path.NIHILITY:
			nihility_count += 1

	var cd_bonus := 0.0
	if unit.eidolon >= 6:
		# E6: След 1 даёт всем союзникам 100% Крит. урона безусловно
		cd_bonus = 1.00
		for ally in bm.allies:
			if ally.is_alive():
				ally.stats.crit_dmg += cd_bonus
		bm.log_message("⚔ Эйдолон 6 Катарины: След 1 даёт всем союзникам +100%% Крит. урона!")
		# E6: След 2 увеличивает получаемый врагами Бинарный урон на 40% до конца боя безусловно
		for enemy in bm.enemies:
			enemy.set_meta("katarina_e6_binary_vuln", 0.40)
		bm.log_message("⚔ Эйдолон 6 Катарины: След 2 безусловно увеличивает получаемый врагами Бинарный урон на +40%%!")
	else:
		match nihility_count:
			1: cd_bonus = 0.10
			2: cd_bonus = 0.30
			3: cd_bonus = 0.50
			4: cd_bonus = 0.60
			_: cd_bonus = 0.60 if nihility_count > 4 else 0.0

		if cd_bonus > 0.0:
			for ally in bm.allies:
				if ally.is_alive() and ally.path == CombatConstants.Path.NIHILITY:
					ally.stats.crit_dmg += cd_bonus
			bm.log_message("⚔ След 1 Катарины: Союзники Пути Небытия (%d) получают +%d%% Крит. урона!" % [nihility_count, int(cd_bonus * 100)])

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.start_attack_recording(attacker)
	var res := bm.calc_dmg(attacker, target, 0.90, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.PHYSICAL, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.5)

	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("⚔ %s — Базовая атака по %s: %d урона (стойкость 50%%)." % [attacker.display_name, target.display_name, int(dmg)])
	_on_katarina_action_taken(attacker, bm)
	bm.finish_attack_recording(attacker)

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	bm.start_attack_recording(attacker)

	# Накладывает физ. уязвимость (-20% физ. сопр. на 2 хода)
	# E1: снижает все типы сопротивления на 20% и скорость на 30% на 2 хода
	var is_e1 := attacker.eidolon >= 1
	target.set_meta("katarina_vuln_turns", 2)
	target.set_meta("katarina_vuln_skip_tick", true)

	if not CombatConstants.Element.PHYSICAL in target.weaknesses:
		target.weaknesses.append(CombatConstants.Element.PHYSICAL)
		target.set_meta("katarina_added_phys_weakness", true)

	if is_e1:
		target.set_meta("katarina_all_res_reduction", 0.20)
		target.add_speed_modifier(-0.30, 0.0)
		target.set_meta("katarina_e1_spd_debuff_turns", 2)
		target.set_meta("katarina_e1_spd_skip_tick", true)
		bm.log_message("⚔ Эйдолон 1: На %s наложена Физическая уязвимость, снижение всех типов сопротивления на 20%% и замедление на 30%% на 2 хода!" % target.display_name)
	else:
		target.set_meta("katarina_phys_res_reduction", 0.20)
		bm.log_message("⚔ Навык Q: На %s наложена Физическая уязвимость и снижение физического сопротивления на 20%% на 2 хода!" % target.display_name)

	# Метка для союзников: атакуя его, союзники получают 15% СА на 2 хода
	target.set_meta("katarina_q_ally_mark_turns", 2)
	target.set_meta("katarina_q_ally_mark_skip_tick", true)

	bm.notify_debuff_applied(target, attacker)
	bm.unit_updated.emit(target)

	# Наносит 280% СА, игнорируя 30% защиты
	var res := bm.calc_dmg(attacker, target, 2.80, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.PHYSICAL, bool(res.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)

	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("⚔ %s — Навык Q по %s: %d урона." % [attacker.display_name, target.display_name, int(dmg)])
	_on_katarina_action_taken(attacker, bm)
	bm.finish_attack_recording(attacker)

static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("katarina_just_a_memory_turns", 2)
	attacker.set_meta("katarina_just_a_memory_skip_tick", true)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🕊 %s переходит в состояние «Лишь воспоминание» на 2 хода: не может получать урон! После выхода восстановит 50 энергии." % attacker.display_name)
	_on_katarina_action_taken(attacker, bm)

static func start_ultimate_sequence(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	attacker.energy = 0.0
	attacker.set_meta("katarina_blood_murmur", true)
	attacker.set_meta("katarina_blood_murmur_target", target)
	attacker.set_meta("katarina_blood_murmur_step", 0)
	attacker.set_meta("katarina_slashing_total_dmg", 0.0)
	bm.log_message("🩸 %s переходит в состояние «Журчание крови»! Серия ударов начинается." % attacker.display_name)
	# Первый удар серии (Секущий 1/2)
	execute_murmur_hit(attacker, target, bm)

static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	start_ultimate_sequence(attacker, target, bm)
	# 2. Секущий удар
	execute_murmur_hit(attacker, target, bm)
	# 3. Рвущий удар (Финал)
	execute_murmur_hit(attacker, target, bm)

static func execute_murmur_hit(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> bool:
	if not attacker.has_meta("katarina_blood_murmur") or not bool(attacker.get_meta("katarina_blood_murmur", false)):
		return false

	var step: int = int(attacker.get_meta("katarina_blood_murmur_step", 0))
	var is_e2 := attacker.eidolon >= 2
	var enemies := bm.get_living_enemies()
	var is_solo_target: bool = (enemies.size() == 1)

	var locked_target: CombatUnit = attacker.get_meta("katarina_blood_murmur_target", null)
	if locked_target != null and locked_target.is_alive():
		target = locked_target
	elif target == null or not target.is_alive():
		if not enemies.is_empty():
			target = enemies[0]
			attacker.set_meta("katarina_blood_murmur_target", target)
		else:
			_exit_blood_murmur(attacker, bm)
			return false

	bm.start_attack_recording(attacker)

	if step < 2:
		# Удары 1 и 2: «Секущий»
		var main_mult := 1.00
		var adj_mult := 0.50
		var bonus_solo := 0.90 if (is_e2 and is_solo_target) else 0.0

		var hit_total_dmg := 0.0

		if is_e2:
			# E2: Групповая атака по всем врагам с мультипликатором для основной цели
			for enemy in enemies:
				var res := bm.calc_dmg(attacker, enemy, main_mult, 0.0, false, bonus_solo, 0.0, true, true, "Ultimate")
				var dmg: float = float(res.get("damage", 0.0))
				var dealt: float = _apply_katarina_ult_hit_damage(attacker, enemy, dmg, bool(res.get("crit", false)), bm)
				hit_total_dmg += dealt
				ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 0.3)
			bm.log_message("🩸 [Секущий удар %d/2] (E2 Групповая): %d общего урона всем врагам." % [step + 1, int(hit_total_dmg)])
		else:
			# Стандарт: выбранной цели 100% СА, двум соседним 50% СА
			var adj := bm.get_adjacent_enemies(target)
			var res_main := bm.calc_dmg(attacker, target, main_mult, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
			var main_dmg: float = float(res_main.get("damage", 0.0))
			var dealt_main: float = _apply_katarina_ult_hit_damage(attacker, target, main_dmg, bool(res_main.get("crit", false)), bm)
			hit_total_dmg += dealt_main
			ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.3)

			for neighbor in adj:
				if neighbor.is_alive():
					var res_adj := bm.calc_dmg(attacker, neighbor, adj_mult, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
					var adj_dmg: float = float(res_adj.get("damage", 0.0))
					var dealt_adj: float = _apply_katarina_ult_hit_damage(attacker, neighbor, adj_dmg, bool(res_adj.get("crit", false)), bm)
					hit_total_dmg += dealt_adj
					ToughnessSystem.apply_weakness_hit(attacker, neighbor, bm, 0.3)

			bm.log_message("🩸 [Секущий удар %d/2]: %d цели %s (+урон соседям). Всего за удар: %d." % [step + 1, int(dealt_main), target.display_name, int(hit_total_dmg)])

		var accumulated: float = float(attacker.get_meta("katarina_slashing_total_dmg", 0.0)) + hit_total_dmg
		attacker.set_meta("katarina_slashing_total_dmg", accumulated)
		attacker.set_meta("katarina_blood_murmur_step", step + 1)
		bm.finish_attack_recording(attacker)
		return true

	else:
		# Удар 3: «Рвущий»
		var slashing_total: float = float(attacker.get_meta("katarina_slashing_total_dmg", 0.0))
		var bonus_solo := 0.90 if (is_e2 and is_solo_target) else 0.0

		# Основной цели: 40% от урона, нанесенного ВСЕМ целям умением "Секущий"
		var tearing_main_dmg: float = slashing_total * 0.40
		if bonus_solo > 0.0:
			tearing_main_dmg *= (1.0 + bonus_solo)

		if is_e2:
			# E2: атакует всех врагов мультипликатором для основной цели
			for enemy in enemies:
				_apply_katarina_ult_hit_damage(attacker, enemy, tearing_main_dmg, false, bm)
				ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 0.8)
			bm.log_message("🩸 [Рвущий удар (Финал)] (E2 Групповая): %d урона (40%% от Секущих) по всем врагам!" % int(tearing_main_dmg))
		else:
			var adj := bm.get_adjacent_enemies(target)
			_apply_katarina_ult_hit_damage(attacker, target, tearing_main_dmg, false, bm)
			ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.8)

			for neighbor in adj:
				if neighbor.is_alive():
					var res_adj := bm.calc_dmg(attacker, neighbor, 0.80, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
					var adj_dmg: float = float(res_adj.get("damage", 0.0))
					_apply_katarina_ult_hit_damage(attacker, neighbor, adj_dmg, bool(res_adj.get("crit", false)), bm)
					ToughnessSystem.apply_weakness_hit(attacker, neighbor, bm, 0.8)

			bm.log_message("🩸 [Рвущий удар (Финал)]: %d урона по цели %s и по 80%% СА соседям!" % [int(tearing_main_dmg), target.display_name])

		# Рвущий восстанавливает 5 энергии
		bm.gain_energy_with_err(attacker, 5.0)

		# E4: Применение удара "Рвущий" восстанавливает 1 очко навыков
		if attacker.eidolon >= 4:
			bm.gain_skill_point()
			bm.log_message("🩸 Эйдолон 4: Удар «Рвущий» восстановил +1 Очко навыков!")

		bm.finish_attack_recording(attacker)
		_exit_blood_murmur(attacker, bm)
		_on_katarina_action_taken(attacker, bm)
		return false

static func _apply_katarina_ult_hit_damage(attacker: CombatUnit, target: CombatUnit, intended_dmg: float, is_crit: bool, bm: BattleManager) -> float:
	return bm.deal_damage(target, intended_dmg, attacker, CombatConstants.Element.PHYSICAL, is_crit, "Ultimate")

static func _exit_blood_murmur(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("katarina_blood_murmur", false)
	attacker.remove_meta("katarina_blood_murmur_target")
	attacker.remove_meta("katarina_blood_murmur_step")
	attacker.remove_meta("katarina_slashing_total_dmg")
	if attacker.get_meta("light_cone_id", "") == "history_soaked_in_blood":
		attacker.remove_meta("blood_soaked_hit_targets")
		if bool(attacker.get_meta("blood_soaked_ult_triggered", false)):
			attacker.remove_meta("blood_soaked_ult_triggered")
			attacker.set_meta("blood_soaked_recorded_dmg", 0.0)
			bm.log_message("🩸 Конус «История, вымоченная в крови»: Накопленный урон очищен после Сверхспособности.")
			bm.unit_updated.emit(attacker)
	bm.log_message("🩸 %s выходит из состояния «Журчание крови»." % attacker.display_name)

static func check_talent_thresholds(target: CombatUnit, was_hp_ratio: float, new_hp_ratio: float, bm: BattleManager, attacker: CombatUnit = null) -> void:
	var katarina_in_party := false
	for ally in bm.allies:
		if ally.id == ID and ally.is_alive():
			katarina_in_party = true
			break
	if not katarina_in_party:
		return

	# Наложение Сломленного духа при падении ниже 80%, 50%, 5%
	var has_bs := bool(target.get_meta("katarina_broken_spirit", false))
	var applied := false

	if not has_bs:
		if was_hp_ratio >= 0.80 and new_hp_ratio < 0.80 and new_hp_ratio >= 0.70:
			applied = true
		elif was_hp_ratio >= 0.50 and new_hp_ratio < 0.50 and new_hp_ratio >= 0.40:
			applied = true
		elif was_hp_ratio >= 0.05 and new_hp_ratio < 0.05 and new_hp_ratio > 0.0:
			applied = true

		if applied:
			target.set_meta("katarina_broken_spirit", true)
			bm.log_message("⛓ Талант Катарины: ХП %s опустилось ниже порога! Наложен статус «Сломленный дух» (Катарина не наносит урон)." % target.display_name)
			bm.unit_updated.emit(target)

	# Снятие Сломленного духа при падении ниже 70%, 40%
	if has_bs and not applied:
		var removed := false
		if was_hp_ratio >= 0.70 and new_hp_ratio < 0.70:
			removed = true
		elif was_hp_ratio >= 0.40 and new_hp_ratio < 0.40:
			removed = true

		if removed:
			target.set_meta("katarina_broken_spirit", false)
			bm.log_message("⛓ Талант Катарины: ХП %s опустилось ниже рубежа снятия! Статус «Сломленный дух» снят." % target.display_name)

			# Атака союзника, снявшая его, дополнительно наносит 50% от записанного урона
			var recorded: float = float(target.get_meta("katarina_recorded_broken_spirit_dmg", 0.0))
			if recorded > 0.0:
				target.set_meta("katarina_recorded_broken_spirit_dmg", 0.0)
				var bonus_dmg := recorded * 0.50
				var dealer: CombatUnit = attacker if attacker != null else bm.current_unit
				bm.deal_damage(target, bonus_dmg, dealer, CombatConstants.Element.PHYSICAL, false, "katarina_recorded_release")
				bm.log_message("💥 Атака %s высвобождает 50%% записанного урона Катарины: нанесено дополнительно %d ед. урона!" % [dealer.display_name if dealer else "союзника", int(bonus_dmg)])

			bm.unit_updated.emit(target)

static func _on_katarina_action_taken(attacker: CombatUnit, bm: BattleManager) -> void:
	# Проверка Следа 3: 3 действия без получения урона -> "Докажи" (+40% скорости)
	var count: int = int(attacker.get_meta("katarina_actions_no_dmg", 0)) + 1
	attacker.set_meta("katarina_actions_no_dmg", count)
	if count >= 3 and not bool(attacker.get_meta("katarina_prove_it_active", false)):
		attacker.set_meta("katarina_prove_it_active", true)
		attacker.add_speed_modifier(0.40, 0.0)
		bm.log_message("⚡ След 3: %s совершила 3 действия без получения урона! Получен статус «Докажи» (+40%% Скорости)!" % attacker.display_name)
		bm.action_order_changed.emit()

static func on_katarina_took_damage(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("katarina_actions_no_dmg", 0)
	if bool(unit.get_meta("katarina_prove_it_active", false)):
		unit.set_meta("katarina_prove_it_active", false)
		unit.remove_speed_modifier(0.40, 0.0)
		bm.log_message("⚡ Статус «Докажи» сброшен с %s из-за получения урона!" % unit.display_name)
		bm.action_order_changed.emit()

static func apply_technique(katarina_unit: CombatUnit, bm: BattleManager) -> void:
	# В начале боя повышает свою силу атаки на 20% на 2 хода и активирует Навык E без трат очков навыков
	katarina_unit.statuses.self_atk_buff_percent += 0.20
	katarina_unit.statuses.self_atk_buff_turns = 2
	katarina_unit.statuses.self_atk_buff_source = "Техника Катарины"

	katarina_unit.set_meta("katarina_just_a_memory_turns", 2)
	katarina_unit.set_meta("katarina_just_a_memory_skip_tick", true)

	bm.log_message("⚔ Техника Катарины: +20%% СА на 2 хода и активация «Лишь воспоминание» без траты ОН!")
