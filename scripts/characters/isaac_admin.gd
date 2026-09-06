class_name IsaacAdminAbilities
extends RefCounted

const ID: String = "isaac_admin"
const MAX_ENERGY: float = 250.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Айзек • Права администратора",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3400,
			"atk": 1620,
			"def": 890,
			"spd": 104,
			"crit_rate": 0.20,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	
	unit.set_meta("isaac_vectors", 0)
	unit.set_meta("isaac_admin_e_unlocked", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_console_member", true)

# Мгновенная атака таланта (не считается бонус-атакой)
static func trigger_talent_overload_attack(attacker: CombatUnit, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	attacker.set_meta("is_binary_attack", true)
	if attacker.eidolon >= 2:
		attacker.set_meta("talent_ignore_20_def", true)
		
	var mult: float = 4.00 * (1.20 if attacker.eidolon >= 5 else 1.0)
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "BinaryGroup")
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "BinaryGroup")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
		
	attacker.remove_meta("is_binary_attack")
	if attacker.has_meta("talent_ignore_20_def"):
		attacker.remove_meta("talent_ignore_20_def")

# --- СПОСОБНОСТИ ---

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 1.00 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 10.0)
	bm.action_order_changed.emit()

static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adjacent := bm.get_adjacent_enemies(target)
	attacker.set_meta("is_binary_attack", true)
	
	var mult_c: float = 1.80 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var mult_a: float = 1.20 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res_c := bm.calc_dmg(attacker, target, mult_c, 0.0, false, 0.0, 0.0, false, true, "Binary")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Binary")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, mult_a, 0.0, false, 0.0, 0.0, false, true, "Binary")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			
	attacker.remove_meta("is_binary_attack")
	
	if attacker.eidolon >= 6:
		bm.add_console_vectors(20)
		
	bm.gain_skill_point()
	bm.action_order_changed.emit()

static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adjacent := bm.get_adjacent_enemies(target)
	var mult_c: float = 1.70 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var mult_a: float = 0.80 * (1.20 if attacker.eidolon >= 3 else 1.0)
	
	var res_c := bm.calc_dmg(attacker, target, mult_c, 0.0, false, 0.0, 0.0, false, true, "Skill")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, mult_a, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			
	bm.add_console_vectors(5)
	bm.unit_updated.emit(attacker)
	bm.gain_energy_with_err(attacker, 5.0)

static func execute_enhanced_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var vectors: int = bm.get_console_vectors()
	var extra_bonus := 0.40 if vectors >= 50 else 0.0
	
	var adjacent := bm.get_adjacent_enemies(target)
	attacker.set_meta("is_binary_attack", true)
	var mult_c: float = 2.50 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var mult_a: float = 1.60 * (1.20 if attacker.eidolon >= 3 else 1.0)
	
	var res_c := bm.calc_dmg(attacker, target, mult_c, 0.0, false, extra_bonus, 0.0, false, true, "Binary")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Binary")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 2.0)
	
	if attacker.eidolon >= 4:
		target.set_meta("binary_vuln_turns", 2)
		target.set_meta("binary_vuln_skip_tick", true)
		
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, mult_a, 0.0, false, extra_bonus, 0.0, false, true, "Binary")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			if attacker.eidolon >= 4:
				adj.set_meta("binary_vuln_turns", 2)
				adj.set_meta("binary_vuln_skip_tick", true)
	
	bm.gain_energy_with_err(attacker, 10.0)
				
	var extra_hits: int = int(vectors / 10)
	if extra_hits > 0 and target.is_alive():
		bm.log_message("⚡ След 3 Айзека: %d доп. тычек по 12%% СА (за %d Векторов) по %s!" % [extra_hits, vectors, target.display_name])
		for i in range(extra_hits):
			if not target.is_alive(): break
			var res_tick := bm.calc_dmg(attacker, target, 0.12, 0.0, false, extra_bonus, 0.0, false, true, "Binary")
			bm.deal_damage(target, res_tick.damage, attacker, attacker.element, res_tick.crit, "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.2)
			
	attacker.remove_meta("is_binary_attack")
	
	if vectors < 50:
		bm.add_console_vectors(8)
	bm.unit_updated.emit(attacker)
	
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager, is_forced_by_sara: bool = false) -> void:
	attacker.set_meta("isaac_admin_trace2_atk_turns", 2)
	attacker.set_meta("isaac_admin_trace2_skip_tick", true)
	
	var vectors: int = bm.get_console_vectors()
	var extra_dmg_e := 0.40 if vectors >= 60 else 0.0
	
	var in_hacked := int(attacker.get_meta("isaac_hacked_turns", 0)) > 0
	var can_use_console_protocol := in_hacked or is_forced_by_sara
	var all_console := true
	for ally in bm.allies:
		if ally.is_alive() and not ally.id in FactionSystem.FACTIONS["console"].members:
			all_console = false
			break
			
	if all_console and in_hacked and bm.allies.size() >= 4:
		bm.log_message("💻 [CONSOLE OVERRIDE]: Совместный протокол Консоли активирован!")
		attacker.set_meta("is_binary_attack", true)
		
		var mult_main: float = 1.20 * (1.20 if attacker.eidolon >= 3 else 1.0)
		var res_main := bm.calc_dmg(attacker, target, mult_main, 0.0, false, extra_dmg_e, 0.0, false, true, "Binary")
		bm.deal_damage(target, res_main.damage, attacker, attacker.element, res_main.crit, "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
		
		var member_ids := ["sara_admin", "arseniy_admin", "dasha_admin", "isaac_admin"]
		for m_id in member_ids:
			var living := bm.get_living_enemies()
			if living.is_empty(): break
			var rnd_target: CombatUnit = living.pick_random()
			
			var partner: CombatUnit = null
			for ally in bm.allies:
				if ally.id == m_id: partner = ally; break
			if partner == null: partner = attacker
			
			var formula_val: float = (attacker.stats.atk * 0.80 + partner.stats.atk * 1.50) * (1.0 + (float(vectors) / 100.0))
			var res_p := bm.calc_dmg(partner, rnd_target, 0.0, 0.0, false, 0.0, 0.0, false, true, "Binary")
			var final_dmg: float = (formula_val + float(res_p.damage)) * DamageCalculator.calc_def_multiplier(rnd_target.stats.def)
			
			bm.deal_damage(rnd_target, final_dmg, partner, partner.element, res_p.crit, "Binary")
			ToughnessSystem.apply_weakness_hit(partner, rnd_target, bm, 1.0)
			
		attacker.remove_meta("is_binary_attack")
	else:
		attacker.set_meta("is_binary_attack", true)
		
		var mult_e: float = 0.70 * (1.20 if attacker.eidolon >= 3 else 1.0)
		var res_1 := bm.calc_dmg(attacker, target, mult_e, 0.0, false, extra_dmg_e, 0.0, false, true, "Binary")
		bm.deal_damage(target, res_1.damage, attacker, attacker.element, res_1.crit, "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.8)
		
		var hit_targets: Array[CombatUnit] = [target]
		for bounce in range(4):
			var living := bm.get_living_enemies()
			if living.is_empty(): break
			
			var unhit: Array[CombatUnit] = []
			for e in living:
				if not e in hit_targets: unhit.append(e)
				
			var chosen: CombatUnit = unhit.pick_random() if not unhit.is_empty() else living.pick_random()
			hit_targets.append(chosen)
			
			var res_b := bm.calc_dmg(attacker, chosen, mult_e, 0.0, false, extra_dmg_e, 0.0, false, true, "Binary")
			bm.deal_damage(chosen, res_b.damage, attacker, attacker.element, res_b.crit, "Binary")
			ToughnessSystem.apply_weakness_hit(attacker, chosen, bm, 0.5)
			
		attacker.remove_meta("is_binary_attack")
		bm.gain_energy_with_err(attacker, 15.0)
		
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("isaac_hacked_turns", 3)
	if bm.current_unit == attacker:
		attacker.set_meta("isaac_hacked_skip_tick", true)
		
	bm.log_message("🌐 СВЕРХСПОСОБНОСТЬ: Айзек переходит в состояние «Взлом» на 3 хода! Способности усилены.")
	
	if attacker.eidolon >= 2:
		bm.add_console_vectors(60)
		
	bm.unit_updated.emit(attacker)

static func add_vectors(_unit: CombatUnit, amount: int, bm: BattleManager) -> void:
	bm.add_console_vectors(amount)
