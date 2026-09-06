class_name SaraAdminAbilities
extends RefCounted

const ID: String = "sara_admin"
const MAX_ENERGY: float = 180.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сара • Права администратора",
		"element": CombatConstants.Element.LIGHTNING,
		"path": CombatConstants.Path.HARMONY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3600,
			"atk": 1350,
			"def": 1050,
			"spd": 110,
			"crit_rate": 0.15,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("sara_admin_e_unlocked", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_console_member", true)
	
	var console_count: int = 0
	for ally in bm.allies:
		if ally.id in FactionSystem.FACTIONS["console"].members:
			console_count += 1
			
	if console_count > 0:
		var energy_gain: float = float(console_count * 20)
		bm.gain_energy_with_err(unit, energy_gain)
		bm.log_message("⚡ След 2 Сары: Восстановлено +%d энергии на старте боя (%d союзников Консоли)." % [int(energy_gain), console_count])

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 0.70 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res: Dictionary = bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.PHYSICAL, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	if attacker.eidolon >= 2:
		target.set_meta("sara_e2_vuln_turns", 2)
		target.set_meta("sara_e2_vuln_skip_tick", true)
		bm.log_message("🎯 Е2 Сары: На %s наложена уязвимость ко всем видам урона +30%% на 2 хода." % target.display_name)
		
	var vector_gain: int = 10
	if int(attacker.get_meta("sara_dev_env_turns", 0)) > 0:
		vector_gain += 3
		
	bm.add_console_vectors(vector_gain)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()

static func execute_skill_q(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("sara_dev_env_turns", 3)
	if bm.current_unit == attacker:
		attacker.set_meta("sara_dev_env_skip_tick", true)
		
	bm.log_message("💻 Навык Q Сары: Активирована зона «Среда разработки» на 3 хода!")
	bm.add_console_vectors(3)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

static func execute_skill_e(attacker: CombatUnit, bm: BattleManager, fixed_vectors: int = -1) -> void:
	var living: Array[CombatUnit] = bm.get_living_enemies()
	attacker.set_meta("is_binary_attack", true)
	if fixed_vectors != -1:
		attacker.set_meta("sara_override_vectors", fixed_vectors)
		
	var mult: float = 0.80 * (1.20 if attacker.eidolon >= 3 else 1.0)
	for enemy in living:
		var res: Dictionary = bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "Binary")
		bm.deal_damage(enemy, float(res.get("damage", 0.0)), attacker, CombatConstants.Element.LIGHTNING, bool(res.get("crit", false)), "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
	attacker.remove_meta("is_binary_attack")
	if attacker.has_meta("sara_override_vectors"):
		attacker.remove_meta("sara_override_vectors")
		
	if attacker.eidolon >= 1:
		for ally in bm.allies:
			if ally.is_alive():
				if not ally.has_meta("sara_e1_spd_active"):
					ally.set_meta("sara_e1_spd_active", true)
					ally.add_speed_modifier(0.30, 0.0)
				ally.set_meta("sara_e1_spd_turns", 2)
				ally.set_meta("sara_e1_spd_skip_tick", ally == attacker)
				ally.recalculate_action_value()
		bm.action_order_changed.emit()
		bm.log_message("⚡ Е1 Сары: Скорость всех союзников увеличена на +30%% на 2 хода!")
		
	var v_gain: int = 15
	if int(attacker.get_meta("sara_dev_env_turns", 0)) > 0:
		v_gain += 3
	bm.add_console_vectors(v_gain)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🌐 СВЕРХСПОСОБНОСТЬ САРЫ: Принудительный запуск Навыков Е протокола Консоли!")
	
	bm.add_console_vectors(20)
	
	if attacker.eidolon >= 2:
		bm.gain_skill_point()
		
	for ally in bm.allies:
		if ally.is_alive():
			ally.set_meta("sara_ult_res_pen_turns", 3)
			ally.set_meta("sara_ult_res_pen_skip_tick", ally == attacker)
	bm.log_message("🔮 Сверхспособность Сары: Пробитие ВСЕХ типов сопротивления отряда повышено на +20%% на 3 хода!")
	
	# Снимаем контекст ультимейта, так как далее запускаются исключительно Навыки Е
	if attacker.has_meta("is_casting_ultimate"):
		attacker.remove_meta("is_casting_ultimate")
	bm.set_meta("current_action_key", "skill_e")
	
	for ally in bm.allies:
		if ally.is_alive() and ally.id in FactionSystem.FACTIONS["console"].members:
			bm.log_message("💻 Протокол Сверхспособности: %s активирует Навык E (учитывается 30 Векторов)!" % ally.display_name)
			if ally.id == "sara_admin":
				execute_skill_e(ally, bm, 30)
			elif ally.id == "isaac_admin":
				var enemies_list: Array[CombatUnit] = bm.get_living_enemies()
				if not enemies_list.is_empty():
					var best_target: CombatUnit = enemies_list[0]
					for e in enemies_list:
						if e.stats.hp > best_target.stats.hp:
							best_target = e
					ally.set_meta("sara_override_vectors", 30)
					IsaacAdminAbilities.execute_skill_e(ally, best_target, bm, true)
					ally.remove_meta("sara_override_vectors")
			elif ally.id == "arseniy_admin":
				ArseniyAdminAbilities.execute_skill_e(ally, bm, true)
			elif ally.id == "dasha_admin":
				DashaAdminAbilities.execute_skill_e(ally, bm)
			elif ally.id == "shoji_swan":
				ShojiSwanAbilities.execute_skill_e(ally, bm)
					
	bm.unit_updated.emit(attacker)

static func add_vectors(amount: int, bm: BattleManager) -> void:
	bm.add_console_vectors(amount)
