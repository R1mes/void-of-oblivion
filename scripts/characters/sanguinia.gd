# scripts/characters/sanguinia.gd
class_name SanguiniaAbilities
extends RefCounted

const ID: String = "sanguinia"
const MAX_ENERGY: float = 150.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сангиния Ял",
		"element": CombatConstants.Element.FIRE,
		"path": CombatConstants.Path.HARMONY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3200,
			"atk": 1500,
			"def": 750,
			"spd": 104,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("sanguinia_waves", 0)
	return unit

static func apply_traces(_unit: CombatUnit) -> void:
	pass

# -------------------------------------------------------------------------
# Хелперы
# -------------------------------------------------------------------------
static func get_highest_atk_ally(bm: BattleManager, ignore_sanguinia: bool = false) -> CombatUnit:
	var best_ally: CombatUnit = null
	var best_atk: float = -1.0
	for ally in bm.get_living_allies():
		if ignore_sanguinia and ally.id == ID:
			continue
		var eff_atk: float = bm.get_effective_atk_complete(ally)
		if best_ally == null or eff_atk > best_atk:
			best_atk = eff_atk
			best_ally = ally
	return best_ally

# -------------------------------------------------------------------------
# Базовая атака
# -------------------------------------------------------------------------
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.0, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, CombatConstants.Element.FIRE, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 10.0 / 30.0)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🔥 %s использует Базовую атаку по %s (100%% СА, 10 стойкости)!" % [attacker.display_name, target.display_name])

# -------------------------------------------------------------------------
# Навык Q - 1 SP [Поддержка]
# Продвигает действие выбранного союзника на 100% и повышает его силу атаки на 40% на 3 хода.
# -------------------------------------------------------------------------
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	target.advance_action(100.0)
	target.set_meta("sanguinia_q_atk_turns", 3)
	target.set_meta("sanguinia_q_atk_skip_tick", true)
	target.set_meta("sanguinia_q_atk_buff", 0.40)
	target.set_meta("sanguinia_q_buffed_by", attacker)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("✨ %s использует Навык Q на %s: действие продвинуто на 100%%, СА +40%% на 3 хода!" % [
		attacker.display_name, target.display_name
	])
	bm.action_order_changed.emit()
	bm.unit_updated.emit(target)
	bm.unit_updated.emit(attacker)

# -------------------------------------------------------------------------
# Навык E - 2 SP [Ослабление]
# Помечает выбранного врага статусом "Особый гость" (12 зарядов).
# -------------------------------------------------------------------------
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# Снимаем старую метку с других врагов
	for enemy in bm.enemies:
		if enemy.has_meta("sanguinia_special_guest_charges"):
			enemy.remove_meta("sanguinia_special_guest_charges")
			enemy.remove_meta("sanguinia_special_guest_source")
			if enemy.statuses.debuffs.has("sanguinia_special_guest"):
				enemy.statuses.debuffs.erase("sanguinia_special_guest")
			bm.unit_updated.emit(enemy)
			
	target.set_meta("sanguinia_special_guest_charges", 12)
	target.set_meta("sanguinia_special_guest_source", attacker)
	if not target.statuses.debuffs.has("sanguinia_special_guest"):
		target.statuses.debuffs.append("sanguinia_special_guest")
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("🍸 %s использует Навык E: на %s наложен статус «Особый гость» (12 зарядов)!" % [
		attacker.display_name, target.display_name
	])
	bm.unit_updated.emit(target)
	bm.unit_updated.emit(attacker)

# -------------------------------------------------------------------------
# Сверхспособность (150 Energy) [Усиление]
# Создаёт «Готовьтесь...» (AV 59) и три «Заселение!» (AV 60).
# -------------------------------------------------------------------------
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.gain_energy_with_err(attacker, 5.0)
	
	if attacker.eidolon >= 4:
		attacker.set_meta("sanguinia_e4_atk_turns", 3)
		attacker.set_meta("sanguinia_e4_atk_skip_tick", true)
		attacker.set_meta("sanguinia_e4_atk_buff", 0.40)
		bm.log_message("👑 Эйдолон 4 Сангинии: СА повышена на +40%% на 3 хода!")

	# Создаем «Готовьтесь...»
	var prep := CombatUnit.new()
	prep.id = "sanguinia_prep"
	prep.display_name = "Готовьтесь..."
	prep.is_ally = true
	prep.stats.max_hp = 1.0
	prep.stats.hp = 1.0
	prep.stats.spd = 100.0
	prep._base_spd = 100.0
	prep.action_value = 59.0
	prep.base_action_value = 59.0
	prep.set_meta("sanguinia_owner", attacker)
	bm.sanguinia_summons.append(prep)

	# Создаем 3 сущности «Заселение!»
	for i in range(3):
		var pop := CombatUnit.new()
		pop.id = "sanguinia_settlement"
		pop.display_name = "Заселение!"
		pop.is_ally = true
		pop.stats.max_hp = 1.0
		pop.stats.hp = 1.0
		pop.stats.spd = 100.0
		pop._base_spd = 100.0
		pop.action_value = 60.0
		pop.base_action_value = 60.0
		pop.set_meta("sanguinia_owner", attacker)
		pop.set_meta("sanguinia_settlement_index", i + 1)
		bm.sanguinia_summons.append(pop)

	bm.log_message("🚪 Сверхспособность Сангинии: на шкале действий созданы призываемые существа «Готовьтесь...» (AV 59) и три «Заселение!» (AV 60)!")
	bm.action_order_changed.emit()
	bm.unit_updated.emit(attacker)

# -------------------------------------------------------------------------
# Действие сущности «Готовьтесь...» (AV 59)
# Продвигает союзника с высшей СА на 100%, восстанавливает 40 энергии, +60% СА на 1 ход.
# След 2: следующая атака союзника игнорирует 20% защиты.
# -------------------------------------------------------------------------
static func execute_prep_turn(prep: CombatUnit, bm: BattleManager) -> void:
	var sanguinia: CombatUnit = prep.get_meta("sanguinia_owner", null) as CombatUnit
	var ignore_self := sanguinia != null and sanguinia.eidolon >= 4
	var target_ally := get_highest_atk_ally(bm, ignore_self)
	
	if target_ally:
		target_ally.advance_action(100.0)
		bm.gain_energy_with_err(target_ally, 40.0)
		target_ally.set_meta("sanguinia_prep_atk_turns", 1)
		target_ally.set_meta("sanguinia_prep_atk_skip_tick", true)
		target_ally.set_meta("sanguinia_prep_atk_buff", 0.60)
		# След 2: следующая атака союзника игнорирует 20% защиты
		target_ally.set_meta("sanguinia_prep_ignore_def_attack", true)
		
		bm.log_message("🛎️ «Готовьтесь...»: союзник %s с наибольшей СА продвинут на 100%%, получил +40 энергии, +60%% СА на 1 ход и игнорирование 20%% защиты на следующую атаку (След 2)!" % target_ally.display_name)
		bm.unit_updated.emit(target_ally)
		bm.action_order_changed.emit()

# -------------------------------------------------------------------------
# Действие сущности «Заселение!» (AV 60)
# Групповая атака по всем врагам: 40% СА Сангинии (считается бонус-атакой).
# E6: множитель повышается на 100% (до 80% СА), чистый урон с +20% бонусом.
# След 1: атаки восстанавливают Сангинии 7 единиц энергии.
# Уменьшает заряды «Особого гостя».
# -------------------------------------------------------------------------
static func execute_settlement_turn(settlement: CombatUnit, bm: BattleManager) -> void:
	var sanguinia: CombatUnit = settlement.get_meta("sanguinia_owner", null) as CombatUnit
	if sanguinia == null:
		sanguinia = bm.get_sanguinia_unit()
	if sanguinia == null:
		return
		
	var mult: float = 0.40
	var is_e6: bool = sanguinia.eidolon >= 6
	if is_e6:
		mult = 0.80 # Повышает множитель урона Заселение на 100%

	var tag: String = "sanguinia_true_fua" if is_e6 else "Бонус-атака"
	var living := bm.get_living_enemies()
	
	bm.advance_fua_sequence()
	bm.start_attack_recording(sanguinia)
	bm.start_attack_action()
	bm.set_meta("current_attack_type", "fua")
	
	bm.log_message("🛎️ «Заселение!»: Групповая Бонус-атака по всем врагам (%d%% СА Сангинии)!" % int(mult * 100.0))
	
	for enemy in living:
		if enemy.is_alive():
			if is_e6:
				var true_dmg: float = bm.get_effective_atk_complete(sanguinia) * mult * 1.20
				bm.deal_damage(enemy, true_dmg, sanguinia, CombatConstants.Element.FIRE, false, tag)
			else:
				var res := bm.calc_dmg(sanguinia, enemy, mult, 0.0, false, 0.0, 0.0, false, true, tag)
				var dmg: float = float(res.get("damage", 0.0))
				bm.deal_damage(enemy, dmg, sanguinia, CombatConstants.Element.FIRE, bool(res.get("crit", false)), tag)
			ToughnessSystem.apply_weakness_hit(sanguinia, enemy, bm, 10.0 / 30.0)

	# След 1: Атаки "Заселение!" восстанавливают Сангинии 7 единиц энергии
	if sanguinia.is_alive():
		bm.gain_energy_with_err(sanguinia, 7.0)
		bm.log_message("☕ След 1 Сангинии: Атака «Заселение!» восстановила 7 энергии (Текущая: %d/%d)!" % [
			int(sanguinia.energy), int(sanguinia.max_energy)
		])

	bm.finish_attack_action()
	bm.finish_attack_recording(sanguinia)
	bm.set_meta("current_attack_type", "")

# -------------------------------------------------------------------------
# Талант "Журчание волн"
# Добавление стаков (до 47). За каждую бонус-атаку союзников или ульту союзника с наивысшей СА.
# При 47: продвигает союзника с наивысшей СА на 100%, +50% урона следующей атаки.
# -------------------------------------------------------------------------
static func add_waves_stacks(count: int, bm: BattleManager) -> void:
	var sanguinia: CombatUnit = bm.get_sanguinia_unit()
	if sanguinia == null or not sanguinia.is_alive():
		return

	var current: int = int(sanguinia.get_meta("sanguinia_waves", 0))
	if current >= 47:
		return
		
	var new_val: int = mini(current + count, 47)
	sanguinia.set_meta("sanguinia_waves", new_val)
	bm.log_message("🌊 Журчание волн Сангинии: %d/47 зарядов (+%d%% урона бонус-атак отряда)." % [new_val, new_val * 2])
	bm.unit_updated.emit(sanguinia)
	
	if new_val >= 47:
		_trigger_talent_threshold(sanguinia, bm)

static func _trigger_talent_threshold(sanguinia: CombatUnit, bm: BattleManager) -> void:
	var ignore_self := sanguinia.eidolon >= 4
	var target_ally := get_highest_atk_ally(bm, ignore_self)
	if target_ally:
		target_ally.advance_action(100.0)
		target_ally.set_meta("sanguinia_talent_dmg_boost", 1.00)
		sanguinia.set_meta("sanguinia_waves_pending_reset_target", target_ally)
		bm.log_message("🌊 ТАЛАНТ САНГИНИИ (47 стаков): Действие союзника %s с наивысшей СА моментально продвинуто на 100%%, а урон следующей атаки повышен на 100%%!" % target_ally.display_name)
		bm.unit_updated.emit(target_ally)
		bm.action_order_changed.emit()

# Вызывается при завершении действия союзника, усиленного 47 стаками таланта
static func check_reset_waves_stacks(actor: CombatUnit, bm: BattleManager) -> void:
	var sanguinia: CombatUnit = bm.get_sanguinia_unit()
	if sanguinia == null:
		return
	if actor.has_meta("sanguinia_talent_dmg_boost"):
		actor.remove_meta("sanguinia_talent_dmg_boost")
		bm.unit_updated.emit(actor)
		
	if sanguinia.has_meta("sanguinia_waves_pending_reset_target"):
		var target: CombatUnit = sanguinia.get_meta("sanguinia_waves_pending_reset_target") as CombatUnit
		if target == actor:
			sanguinia.remove_meta("sanguinia_waves_pending_reset_target")
			sanguinia.set_meta("sanguinia_waves", 0)
			bm.log_message("🌊 Журчание волн Сангинии сброшено до 0.")
			
			# След 3: Когда Журчание волн сбрасывается до 0, Сангиния восстанавливает 1 очко навыков
			bm.gain_skill_point()
			bm.log_message("🕊️ След 3 Сангинии: Сброс Журчания волн восстановил 1 Очко Навыков!")
			
			# E2: При сбросе уровней Журчания волн увеличивает наносимый Сангинией урон на 60% на 2 хода
			if sanguinia.eidolon >= 2:
				sanguinia.set_meta("sanguinia_e2_dmg_turns", 2)
				sanguinia.set_meta("sanguinia_e2_dmg_skip_tick", true)
				sanguinia.set_meta("sanguinia_e2_dmg_buff", 0.60)
				bm.log_message("👑 Эйдолон 2 Сангинии: Наносимый урон повышен на +60%% на 2 хода!")
				
			bm.unit_updated.emit(sanguinia)

# -------------------------------------------------------------------------
# Обработка статуса "Особый гость" при атаке союзника
# -------------------------------------------------------------------------
static func on_ally_attack_action_performed(attacker: CombatUnit, bm: BattleManager, target: CombatUnit = null) -> void:
	var sanguinia: CombatUnit = bm.get_sanguinia_unit()
	if sanguinia == null or not sanguinia.is_alive():
		return
		
	var target_guest: CombatUnit = null
	if target != null and target.has_meta("sanguinia_special_guest_charges"):
		target_guest = target
	else:
		for enemy in bm.get_living_enemies():
			if enemy.has_meta("sanguinia_special_guest_charges"):
				target_guest = enemy
				break
			
	if target_guest == null or not target_guest.is_alive():
		return
		
	var charges: int = int(target_guest.get_meta("sanguinia_special_guest_charges", 0))
	if charges <= 0:
		return
		
	charges -= 1
	target_guest.set_meta("sanguinia_special_guest_charges", charges)
	bm.log_message("🍸 «Особый гость» на %s: осталось %d/12 зарядов (атака от %s)." % [
		target_guest.display_name, charges, attacker.display_name
	])
	bm.unit_updated.emit(target_guest)
	
	if charges in [9, 6, 3, 0]:
		_trigger_guest_fua(sanguinia, target_guest, charges == 0, bm)

static func _trigger_guest_fua(sanguinia: CombatUnit, target_guest: CombatUnit, is_final: bool, bm: BattleManager) -> void:
	var prev_credited: bool = bm.has_meta("sanguinia_guest_credited_this_action")
	bm.set_meta("sanguinia_guest_credited_this_action", true)
	bm.set_meta("is_sanguinia_guest_fua", true)
	bm.advance_fua_sequence()
	var is_e6: bool = sanguinia.eidolon >= 6
	var tag: String = "sanguinia_true_fua" if is_e6 else "Бонус-атака"
	var adjacent := bm.get_adjacent_enemies(target_guest)
	
	bm.log_message("🎯 Бонус-атака Сангинии по «Особому гостю» (%s) [130%% СА центру, 35%% СА соседям]!" % target_guest.display_name)
	
	# Центральная цель (130% СА)
	if target_guest.is_alive():
		if is_e6:
			var true_dmg: float = bm.get_effective_atk_complete(sanguinia) * 1.30 * 1.20
			bm.deal_damage(target_guest, true_dmg, sanguinia, CombatConstants.Element.FIRE, false, tag)
		else:
			var res := bm.calc_dmg(sanguinia, target_guest, 1.30, 0.0, false, 0.0, 0.0, false, true, tag)
			bm.deal_damage(target_guest, float(res.get("damage", 0.0)), sanguinia, CombatConstants.Element.FIRE, bool(res.get("crit", false)), tag)
		ToughnessSystem.apply_weakness_hit(sanguinia, target_guest, bm, 20.0 / 30.0)
		
	# Соседи (35% СА)
	for adj in adjacent:
		if adj.is_alive():
			if is_e6:
				var true_dmg_adj: float = bm.get_effective_atk_complete(sanguinia) * 0.35 * 1.20
				bm.deal_damage(adj, true_dmg_adj, sanguinia, CombatConstants.Element.FIRE, false, tag)
			else:
				var res_adj := bm.calc_dmg(sanguinia, adj, 0.35, 0.0, false, 0.0, 0.0, false, true, tag)
				bm.deal_damage(adj, float(res_adj.get("damage", 0.0)), sanguinia, CombatConstants.Element.FIRE, bool(res_adj.get("crit", false)), tag)
			ToughnessSystem.apply_weakness_hit(sanguinia, adj, bm, 10.0 / 30.0)

	if is_final:
		target_guest.remove_meta("sanguinia_special_guest_charges")
		target_guest.remove_meta("sanguinia_special_guest_source")
		if target_guest.statuses.debuffs.has("sanguinia_special_guest"):
			target_guest.statuses.debuffs.erase("sanguinia_special_guest")
		bm.gain_skill_point()
		bm.log_message("🍸 Статус «Особый гость» снят с %s! Восстановлено 1 Очко Навыков." % target_guest.display_name)
		bm.unit_updated.emit(target_guest)

	bm.remove_meta("is_sanguinia_guest_fua")
	if not prev_credited:
		bm.remove_meta("sanguinia_guest_credited_this_action")

# -------------------------------------------------------------------------
# Техника поддержки
# Продвигает действие сильнейшего союзника на 30% и даёт +15 скорости на 3 хода.
# -------------------------------------------------------------------------
static func execute_technique(sanguinia: CombatUnit, bm: BattleManager) -> void:
	var ignore_self := sanguinia.eidolon >= 4
	var target_ally := get_highest_atk_ally(bm, ignore_self)
	if target_ally:
		target_ally.advance_action(30.0)
		target_ally.add_speed_modifier(0.0, 15.0)
		target_ally.set_meta("sanguinia_tech_spd_turns", 3)
		target_ally.set_meta("sanguinia_tech_spd_skip_tick", true)
		bm.log_message("✨ Техника Сангинии: Действие %s продвинуто на 30%%, Скорость +15 ед. на 3 хода!" % target_ally.display_name)
		bm.unit_updated.emit(target_ally)
		bm.action_order_changed.emit()
