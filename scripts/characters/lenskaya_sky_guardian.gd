# scripts/characters/lenskaya_sky_guardian.gd
class_name LenskayaSkyGuardianAbilities
extends RefCounted

const ID: String = "lenskaya_sky_guardian"
const MAX_ENERGY: float = 110.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Ленская • Хранитель небес",
		"element": CombatConstants.Element.IMAGINARY,
		"path": CombatConstants.Path.HUNT,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2400,
			"atk": 1700,
			"def": 700,
			"spd": 108,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.60,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.0, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 10.0 / 30.0)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("🏹 %s использует Базовую атаку по %s (100%% СА, 10 стойкости)!" % [attacker.display_name, target.display_name])

static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("is_enhanced_basic", true)
	bm.log_message("🏹 %s использует Усиленную базовую атаку по %s (4 удара по 50%% СА, суммарно 180%% СА и 40 стойкости)!" % [attacker.display_name, target.display_name])
	for i in range(4):
		if not target.is_alive():
			break
		var res := bm.calc_dmg(attacker, target, 0.50, 0.0, false, 0.0, 0.0, false, true, "EnhancedBasic")
		var dmg: float = float(res.get("damage", 0.0))
		bm.deal_damage(target, dmg, attacker, attacker.element, bool(res.get("crit", false)), "EnhancedBasic")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 10.0 / 40.0)
	
	attacker.remove_meta("is_enhanced_basic")
	bm.gain_energy_with_err(attacker, 20.0)
	if attacker.eidolon >= 4:
		bm.gain_energy_with_err(attacker, 5.0)
		bm.log_message("🏹 Эйдолон 4: Усиленная базовая атака восстанавливает +5 энергии!")

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# Накладывает статус "Враг Свечения" на 3 хода
	target.set_meta("lenskaya_radiance_enemy_turns", 3)
	target.set_meta("lenskaya_radiance_enemy_skip_tick", true)
	target.set_meta("lenskaya_radiance_enemy_source", attacker)
	if attacker.eidolon >= 2:
		target.set_meta("lenskaya_radiance_enemy_e2", true)
	
	# Активирует усиленную базовую атаку на 3 хода
	attacker.set_meta("lenskaya_enhanced_basic_turns", 3)
	attacker.set_meta("lenskaya_enhanced_basic_skip_tick", true)
	
	bm.gain_energy_with_err(attacker, 30.0)
	var e2_text := " (E2: +45%% к урону Суперпробития!)" if attacker.eidolon >= 2 else " (+30%% к урону Пробития и Суперпробития)"
	bm.log_message("✨ %s использует Навык Q: на %s наложен статус «Враг Свечения» на 3 хода%s! Усиленная базовая атака активирована на 3 хода." % [
		attacker.display_name,
		target.display_name,
		e2_text
	])
	bm.unit_updated.emit(attacker)
	bm.unit_updated.emit(target)

static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	# E1: Первое использование Навыка E за бой тратит на 1 Очко Навыков меньше
	attacker.set_meta("lenskaya_e1_used", true)
	
	# E6: Перед нанесением урона Навыком E накладывает на цель Мнимую уязвимость на 2 хода (без снижения сопротивления)
	if attacker.eidolon >= 6:
		if not CombatConstants.Element.IMAGINARY in target.weaknesses:
			target.weaknesses.append(CombatConstants.Element.IMAGINARY)
			target.set_meta("lenskaya_added_imaginary_weakness", true)
		target.set_meta("lenskaya_e6_weakness_turns", 2)
		target.set_meta("lenskaya_e6_weakness_skip_tick", true)
		bm.log_message("🏹 Эйдолон 6: Перед ударом на %s наложена Мнимая уязвимость на 2 хода!" % target.display_name)
		bm.unit_updated.emit(target)

	var res := bm.calc_dmg(attacker, target, 3.0, 0.0, false, 0.0, 0.0, false, true, "Skill")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 30.0 / 30.0)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.log_message("💥 %s использует Навык E по %s (300%% СА, 30 стойкости)!" % [attacker.display_name, target.display_name])

static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	# Повышает собственный Эффект Пробития на 40% на 3 хода
	# Продвигает собственное действие на 100%
	attacker.set_meta("lenskaya_ult_be_turns", 3)
	attacker.set_meta("lenskaya_ult_be_skip_tick", true)
	attacker.set_meta("lenskaya_ult_be_buff", 0.40)
	
	bm.log_message("🏹 Сверхспособность Ленской • Хранитель небес: Эффект Пробития +40%% на 3 хода, действие продвинуто на 100%%!")
	attacker.advance_action(100.0)
	bm.action_order_changed.emit()
	
	# След 2: если Ленская находится не на первом месте в отряде, союзник на первом месте получает +40% к Эффекту Пробития на 2 хода
	if bm.allies.size() > 0:
		var slot_0_ally: CombatUnit = bm.allies[0]
		if slot_0_ally != null and slot_0_ally != attacker and slot_0_ally.is_alive():
			slot_0_ally.set_meta("lenskaya_trace2_be_turns", 2)
			slot_0_ally.set_meta("lenskaya_trace2_be_skip_tick", true)
			slot_0_ally.set_meta("lenskaya_trace2_be_buff", 0.40)
			bm.log_message("🏹 След 2: Первый союзник (%s) получает +40%% к Эффекту Пробития на 2 хода!" % slot_0_ally.display_name)
			bm.unit_updated.emit(slot_0_ally)
			
	bm.unit_updated.emit(attacker)

static func execute_technique(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🏹 Техника Ленской • Хранитель небес: Удар по всем врагам (100%% СА Мнимый урон, -40 стойкости независимо от уязвимостей)!")
	var living := bm.get_living_enemies()
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(attacker, enemy, 1.0, 0.0, false, 0.0, 0.0, false, true, "Technique")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(enemy, dmg, attacker, CombatConstants.Element.IMAGINARY, bool(res.get("crit", false)), "Technique")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 40.0 / 30.0, true)
