class_name NaamaAbilities
extends RefCounted

const ID: String = "naama"
const MAX_ENERGY: float = 130.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit: CombatUnit = CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Наама",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2900,
			"atk": 1950,
			"def": 700,
			"spd": 106,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.30, # Врожденный ШПЭ 30%
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	pass

# Метод безопасного получения Сопротивления эффектам цели
static func get_effect_res(unit: CombatUnit) -> float:
	# Скобка безопасности: если цель погибла или равна null, возвращаем дефолт
	if unit == null:
		return 0.10
		
	if unit.is_ally:
		return float(unit.get_meta("relic_effect_res", 0.0)) + unit.statuses.effect_resist_bonus
		
	# Безопасный дефолтный fallback на основе прописанных в шаблонах коэффициентов
	match unit.id:
		"void_soldier": return 0.10
		"void_elite": return 0.15
		"void_armored": return 0.15
		"void_boss": return 0.30
		"void_dummy": return 0.00
		"masked_silhouette": return 0.40 # Добавлено сопротивление Силуэта
		"server_virus": return 0.35
		"ortho_mutant": return 0.20
		"infected": return 0.10
		"ortho_spore": return 0.10
	return 0.10

# Метод математического расчета наложения дебаффа по формуле HSR
static func roll_debuff(base_chance: float, attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> bool:
	var ehr: float = attacker.stats.effect_hit_rate
	var eff_res: float = get_effect_res(target)
	
	var final_chance: float = base_chance * (1.0 + ehr) * (1.0 - eff_res)
	var roll: float = randf()
	var success: bool = roll < final_chance
	
	bm.log_message("🎲 ШПЭ проверка на %s: Базовый %.0f%% * (1 + ШПЭ %.0f%%) * (1 - Сопр %.0f%%) = Итог %.1f%%. Ролл: %.1f%% -> %s" % [
		target.display_name,
		base_chance * 100.0,
		ehr * 100.0,
		eff_res * 100.0,
		final_chance * 100.0,
		roll * 100.0,
		"[color=green]УСПЕХ[/color]" if success else "[color=red]ПРОМАХ[/color]"
	])
	return success

# Вспомогательный метод добавления стаков Опьянения
static func add_intox_stacks(target: CombatUnit, count: int, bm: BattleManager) -> void:
	var current: int = int(target.get_meta("naama_intox_stacks", 0))
	var new_stacks: int = int(clamp(current + count, 0, 20))
	target.set_meta("naama_intox_stacks", new_stacks)
	
	bm.log_message("Опьянение на %s: %d/20 стаков." % [target.display_name, new_stacks])
	
	if new_stacks == 20:
		bm.apply_def_reduction(target, "Опьянение (20 стаков)", 0.20, 999)
	elif current == 20 and new_stacks < 20:
		if target.has_meta("def_reductions"):
			var reductions: Dictionary = target.get_meta("def_reductions")
			if reductions.has("Опьянение (20 стаков)"):
				reductions.erase("Опьянение (20 стаков)")
				bm.recalculate_target_def(target)
				
	bm.unit_updated.emit(target)

# БАЗОВАЯ АТАКА (80% СА, След 3: Базовый шанс 85% наложить 2 стака Опьянения)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 0.80
	if attacker.eidolon >= 1:
		mult += 0.20
	if attacker.eidolon >= 3:
		mult *= 1.15
		
	var result: Dictionary = bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, result.damage, attacker, attacker.element, result.crit)
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	# След 3: Базовый шанс 85% наложить 2 уровня Опьянения
	if roll_debuff(0.85, attacker, target, bm):
		add_intox_stacks(target, 2, bm)
	else:
		bm.log_message("Опьянение: %s сопротивлялся наложению стаков." % target.display_name)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.log_message("%s наносит %d урона базовой атакой по %s." % [attacker.display_name, int(result.damage), target.display_name])

# НАВЫК Q (120% СА центру, 50% соседям, Базовый шанс 85% наложить 3 стака на все 3 цели)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	var mult_central: float = 1.20
	var mult_adj: float = 0.50
	if attacker.eidolon >= 3:
		mult_central *= 1.15
		mult_adj *= 1.15
		
	var adjacent: Array[CombatUnit] = bm.get_adjacent_enemies(target)
		
	# Урон и наложение по главной цели
	var res_c: Dictionary = bm.calc_dmg(attacker, target, mult_central, 0.0, false, 0.0, 0.0, false, true, "Skill")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit)
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	if roll_debuff(0.85, attacker, target, bm):
		add_intox_stacks(target, 3, bm)

	for adj in adjacent:
		if adj.is_alive():
			var res_a: Dictionary = bm.calc_dmg(attacker, adj, mult_adj, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit)
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 0.5)
			if roll_debuff(0.85, attacker, adj, bm):
				add_intox_stacks(adj, 3, bm)
			
	bm.gain_energy_with_err(attacker, 30.0)

# НАВЫК E (Накладывает слабость к DoT +30% на 2 хода всем врагам с Опьянением - гарантированно)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var living_enemies: Array[CombatUnit] = bm.get_living_enemies()
	for enemy in living_enemies:
		var stacks: int = int(enemy.get_meta("naama_intox_stacks", 0))
		if stacks > 0:
			enemy.set_meta("naama_dot_vuln_turns", 2)
			bm.log_message("На %s наложена 40%% слабость к DoT на 2 хода." % enemy.display_name)
			
	bm.gain_energy_with_err(attacker, 30.0)

# СВЕРХСПОСОБНОСТЬ (Поцелуй бездны - гарантированно)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 1.00
	if attacker.eidolon >= 5:
		mult *= 1.15
		
	var living_enemies: Array[CombatUnit] = bm.get_living_enemies()
	for enemy in living_enemies:
		var res: Dictionary = bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, true)
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit)
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.2)
		
		# Накладываем Поцелуй бездны
		enemy.set_meta("naama_kiss_turns", 2)
		enemy.set_meta("naama_kiss_state", "active")
		bm.recalculate_target_def(enemy)
		
		bm.log_message("На %s наложен дебафф «Поцелуй бездны»." % enemy.display_name)
		bm.unit_updated.emit(enemy)
		
	if attacker.eidolon >= 4:
		attacker.set_meta("naama_e4_free_skill", true)
		bm.log_message("Эйдолон 4 Наамы: Следующий Навык Е не потратит ОН!")
		
	bm.gain_energy_with_err(attacker, 5.0)

# ХУК: Срабатывание DoT Опьянения в начале хода врага
static func process_enemy_turn_start(enemy: CombatUnit, bm: BattleManager) -> void:
	var stacks: int = int(enemy.get_meta("naama_intox_stacks", 0))
	if stacks <= 0:
		return
		
	var naama: CombatUnit = null
	for ally in bm.allies:
		if ally.id == ID and ally.is_alive():
			naama = ally
			break
			
	if naama == null:
		return
		
	var eff_atk: float = bm.get_effective_atk_complete(naama)
	var talent_mult: float = 1.15 if naama.eidolon >= 5 else 1.0
	var damage_mult: float = (0.06 + (40.0 / maxf(eff_atk, 1.0))) * stacks * talent_mult
	
	var res: Dictionary = bm.calc_dmg(naama, enemy, damage_mult, 0.0, false, 0.0, 0.0, false, false, "DoT")
	bm.deal_damage(enemy, res.damage, naama, CombatConstants.Element.WIND, false, "DoT")
	bm.log_message("Опьянение нанесло %d DoT-урона по %s (стаки: %d)." % [int(res.damage), enemy.display_name, stacks])
	
	bm.gain_energy_with_err(naama, 4.0)
	
	var kiss_state: String = String(enemy.get_meta("naama_kiss_state", ""))
	if kiss_state == "active":
		enemy.set_meta("naama_kiss_state", "inactive")
		bm.log_message("«Поцелуй бездны» удержал стаки Опьянения %s от сброса и перешел в неактивный режим." % enemy.display_name)
	else:
		enemy.set_meta("naama_intox_stacks", 0)
		if enemy.has_meta("def_reductions"):
			var reductions: Dictionary = enemy.get_meta("def_reductions")
			if reductions.has("Опьянение (20 стаков)"):
				reductions.erase("Опьянение (20 стаков)")
				bm.recalculate_target_def(enemy)
		bm.log_message("Стаки Опьянения на %s сброшены." % enemy.display_name)
		
	if stacks > 10:
		enemy.delay_action(15.0)
		bm.log_message("Опьянение (>10 стаков): действие %s отложено на 15%%!" % enemy.display_name)
		
	bm.unit_updated.emit(enemy)

# ХУК: Взрыв DoT (например, навыками Сёдзи) вне своего хода
static func trigger_intoxication_explosion(enemy: CombatUnit, attacker: CombatUnit, bm: BattleManager, efficiency: float = 1.0) -> void:
	var stacks: int = int(enemy.get_meta("naama_intox_stacks", 0))
	if stacks <= 0:
		return
		
	var naama: CombatUnit = null
	for ally in bm.allies:
		if ally.id == ID and ally.is_alive():
			naama = ally
			break
			
	if naama == null:
		return
		
	var eff_atk: float = bm.get_effective_atk_complete(naama)
	var talent_mult: float = 1.15 if naama.eidolon >= 5 else 1.0
	var damage_mult: float = (0.06 + (40.0 / maxf(eff_atk, 1.0))) * stacks * talent_mult * efficiency
	
	var res: Dictionary = bm.calc_dmg(naama, enemy, damage_mult, 0.0, false, 0.0, 0.0, false, false, "DoT")
	bm.deal_damage(enemy, res.damage, naama, CombatConstants.Element.WIND, false, "DoT")
	bm.log_message("Детонация Опьянения: %d урона по %s." % [int(res.damage), enemy.display_name])
	
	bm.gain_energy_with_err(naama, 5.0)
	
	if bm.current_unit != enemy:
		# Срабатывание вне хода врага: базовый шанс на доп. стаки равен 100%, используем roll_debuff()
		if roll_debuff(1.00, naama, enemy, bm):
			var extra: int = 3 if naama.eidolon >= 2 else 2
			add_intox_stacks(enemy, extra, bm)
			bm.log_message("Опьянение %s взорвано вне своего хода! Успешно начислено +%d стаков." % [enemy.display_name, extra])
