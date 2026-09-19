class_name RimesAscensionAbilities
extends RefCounted

const ID: String = "rimes_ascension"
const PAWS_ID: String = "antimatter_paws"

# ==============================================================================
# 1. ИНИЦИАЛИЗАЦИЯ ПЕРСОНАЖА
# ==============================================================================
static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Раймс • Восхождение",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.REMEMBRANCE,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": 100.0,
		"stats": {
			"hp": 4500,
			"atk": 500,
			"def": 850,
			"spd": 102,
			"crit_rate": 0.15,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.0,
			"break_effect": 0.0,
			"weakness_efficiency": 0.0,
		},
	})
	unit.energy = 0.0
	unit.set_meta("crescendo_stacks", 0.0)
	unit.set_meta("talent_dmg_stacks", 0)
	unit.set_meta("talent_dmg_turns", 0)
	unit.set_meta("rupture_zone_turns", 0)
	unit.set_meta("faction_antimatter_member", true)
	unit.set_meta("faction_empyrean_member", true)
	unit.set_meta("is_hp_scaler", true)
	return unit

# ==============================================================================
# 2. ОПРЕДЕЛЕНИЕ ДУХА ПАМЯТИ «ЛАПЫ АНТИМАТЕРИИ»
# ==============================================================================
static func create_paws_definition(owner: CombatUnit) -> MemospriteDefinition:
	var def := MemospriteDefinition.new()
	def.id = PAWS_ID
	def.display_name = "Лапы антиматерии"
	def.element = CombatConstants.Element.QUANTUM
	def.path = CombatConstants.Path.REMEMBRANCE
	
	def.hp_mode = MemospriteDefinition.HpMode.OWNER_SCALING
	def.hp_coefficient = 1.50
	def.hp_flat = 0.0
	
	def.speed_mode = MemospriteDefinition.SpeedMode.FIXED
	def.base_speed = 165.0
	
	# Подкрепление: враги не могут брать в таргет
	def.is_targetable = false
	def.is_backup = true
	def.appears_in_action_order = true
	
	def.charge_enabled = true
	def.max_charge = 4.0
	def.initial_charge = 1.0
	def.consumes_charge_on_enhanced = false
	
	def.inherits_attack = true
	def.inherits_defense = true
	def.inherits_crit_rate = true
	def.inherits_crit_damage = true
	def.inherits_break_effect = true
	def.inherits_damage_bonus = true
	def.inherits_effect_res = true
	def.inherits_effect_hit_rate = true
	def.inherits_speed = false
	def.inherits_hp = false
	
	def.skill_name = "Con brio"
	def.enhanced_skill_name = "Sforzando"
	def.talent_name = "Талант духа памяти"
	
	def.skill_callable = Callable(RimesAscensionAbilities, "execute_paws_skill")
	def.enhanced_skill_callable = Callable(RimesAscensionAbilities, "execute_paws_skill")
	def.talent_callable = Callable(RimesAscensionAbilities, "on_paws_talent")
	
	return def

static func get_paws_sprite(owner: CombatUnit, bm: BattleManager) -> Memosprite:
	return MemospriteSystem.get_sprite(owner, bm)

static func recalculate_paws_max_hp(paws: Memosprite, owner: CombatUnit) -> void:
	if paws == null or owner == null:
		return
	var base_hp := owner.stats.max_hp * 1.50
	var charges := paws.get_charge() if paws.charge_comp != null else 1.0
	var bonus_mult := maxf(0.0, charges - 1.0) * 0.75
	var new_max := base_hp * (1.0 + bonus_mult)
	var gained := new_max - paws.stats.max_hp
	paws.stats.max_hp = new_max
	if gained > 0.0:
		paws.stats.hp += gained
	paws.stats.hp = minf(paws.stats.hp, paws.stats.max_hp)

# ==============================================================================
# 3. МЕХАНИКИ КРЕЩЕНДО И ТАЛАНТА РАЙМСА
# ==============================================================================
static func add_crescendo(rimes: CombatUnit, amount: float, bm: BattleManager = null) -> void:
	if rimes == null or amount <= 0.0:
		return
	var current: float = float(rimes.get_meta("crescendo_stacks", 0.0))
	var updated := minf(100.0, current + amount)
	rimes.set_meta("crescendo_stacks", updated)
	rimes.energy = updated
	if bm != null and int(updated) != int(current):
		bm.log_message("🎼 Крещендо Раймса: +%.1f%% (Всего: %.1f%%/100%%)!" % [amount, updated])
		bm.unit_updated.emit(rimes)

static func on_ally_hp_lost(rimes: CombatUnit, ally: CombatUnit, hp_lost: float, bm: BattleManager) -> void:
	if rimes == null or not rimes.is_alive() or ally == null or hp_lost <= 0.0:
		return
	if ally.stats.max_hp <= 0.0:
		return
	
	# Конверсия 1% потерянного ХП = 1% Крещендо
	var pct_lost := (hp_lost / ally.stats.max_hp) * 100.0
	add_crescendo(rimes, pct_lost, bm)
	
	# Талант: +20% наносимого урона Раймсу и Лапам, стакается до 3 раз на 3 хода
	var cur_stacks: int = int(rimes.get_meta("talent_dmg_stacks", 0))
	var new_stacks := mini(cur_stacks + 1, 3)
	rimes.set_meta("talent_dmg_stacks", new_stacks)
	rimes.set_meta("talent_dmg_turns", 3)
	rimes.set_meta("rimes_talent_skip_tick", true)
	if bm != null:
		bm.log_message("✨ Талант Раймса: Союзник потерял ХП -> наносимый урон +%d%% (стаков: %d/3) на 3 хода!" % [
			new_stacks * 20, new_stacks
		])
		bm.unit_updated.emit(rimes)

# ==============================================================================
# 4. БАЗОВАЯ АТАКА (100% макс. ХП)
# ==============================================================================
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.0, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	bm.gain_skill_point()
	bm.log_message("⚔ %s — Базовая атака: %d квант. урона (100%% макс. ХП) по %s!" % [
		attacker.display_name, int(dmg), target.display_name
	])

# ==============================================================================
# 5. НАВЫК Q (0 SP, Базовый / Усиленный совместный)
# ==============================================================================
static func execute_skill_q(attacker: CombatUnit, bm: BattleManager) -> void:
	var paws := get_paws_sprite(attacker, bm)
	var paws_alive := paws != null and paws.is_alive()
	
	if not paws_alive:
		# Базовый Навык Q: наносит 90% макс. ХП Раймса всем врагам (0 SP, без расхода ХП команды)
		var living_enemies := bm.get_living_enemies()
		for enemy in living_enemies:
			if not enemy.is_alive():
				continue
			var res := bm.calc_dmg(attacker, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(enemy, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		bm.log_message("💫 %s использует Навык Q: 90%% макс. ХП квантового урона всем противникам!" % attacker.display_name)
		return

	# Усиленный Навык Q (Лапы на поле боя):
	# Проверка расхода Зеро (>= 60 -> тратит 10 Зеро, +20% урона, +1 заряд Лапам)
	var zero_boost := false
	if bm.get_xaeroh() >= 60:
		bm.spend_xaeroh(10)
		zero_boost = true
		if paws.charge_comp != null:
			paws.charge_comp.add_charge(1.0)
			recalculate_paws_max_hp(paws, attacker)
		bm.log_message("🌌 Усиленный Навык Q: Израсходовано 10 Зеро -> урон навыка +20%%, Лапам восстановлен 1 заряд (текущий: %.0f/4)!" % paws.get_charge())
		
	var skill_dmg_mult: float = 1.20 if zero_boost else 1.0
	
	# Слив ХП союзников (15% текущего, Лапы 30%)
	for ally in bm.allies:
		if not ally.is_alive():
			continue
		var drain_pct := 0.30 if (ally == paws) else 0.15
		var drain_amount := ally.stats.hp * drain_pct
		var actual_drain := minf(drain_amount, maxf(0.0, ally.stats.hp - 1.0))
		if actual_drain > 0.0:
			ally.stats.hp = maxf(1.0, ally.stats.hp - actual_drain)
			bm.log_message("🩸 Навык Q: %s жертвует %d ХП (осталось: %d)!" % [
				ally.display_name, int(actual_drain), int(ally.stats.hp)
			])
			on_ally_hp_lost(attacker, ally, actual_drain, bm)
			bm.unit_updated.emit(ally)
			
	if paws_alive and not (paws in bm.allies):
		var drain_amount := paws.stats.hp * 0.30
		var actual_drain := minf(drain_amount, maxf(0.0, paws.stats.hp - 1.0))
		if actual_drain > 0.0:
			paws.stats.hp = maxf(1.0, paws.stats.hp - actual_drain)
			bm.log_message("🐾 Навык Q: Лапы антиматерии жертвуют %d ХП (осталось: %d)!" % [
				int(actual_drain), int(paws.stats.hp)
			])
			on_ally_hp_lost(attacker, paws, actual_drain, bm)
			bm.unit_updated.emit(paws)

	# Совместная атака по всем противникам: 50% макс ХП Раймса + 30% макс ХП Лап
	var living_enemies := bm.get_living_enemies()
	for enemy in living_enemies:
		if not enemy.is_alive():
			continue
		var rimes_res := bm.calc_dmg(attacker, enemy, 0.50 * skill_dmg_mult, 0.0, false, 0.0, 0.0, false, true, "Skill")
		var r_dmg: float = float(rimes_res.get("damage", 0.0))
		bm.deal_damage(enemy, r_dmg, attacker, attacker.element, bool(rimes_res.get("crit", false)), "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
		var paws_res := bm.calc_dmg(paws, enemy, 0.30 * skill_dmg_mult, 0.0, false, 0.0, 0.0, false, true, "Skill")
		var p_dmg: float = float(paws_res.get("damage", 0.0))
		var paws_ignore_w: bool = attacker.eidolon >= 6
		bm.deal_damage(enemy, p_dmg, paws, paws.element, bool(paws_res.get("crit", false)), "Skill")
		ToughnessSystem.apply_weakness_hit(paws, enemy, bm, 1.0, paws_ignore_w)

	bm.log_message("💥 %s и Лапы антиматерии провели совместную атаку Навыком Q!" % attacker.display_name)

# ==============================================================================
# 6. НАВЫК E (2 SP базово, 1 SP со Следом 1 при наличии Лап)
# ==============================================================================
static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	var paws := get_paws_sprite(attacker, bm)
	if paws == null or not paws.is_alive():
		var def := create_paws_definition(attacker)
		paws = MemospriteSystem.summon(attacker, def, bm)
		if attacker.eidolon >= 2:
			paws.charge_comp.add_charge(2.0)
		recalculate_paws_max_hp(paws, attacker)
		bm.log_message("🐾 %s призывает Духа Памяти «Лапы антиматерии»!" % attacker.display_name)
	else:
		MemospriteSystem.dispel_crowd_control(paws)
		var heal_amt := paws.stats.max_hp * 0.60
		bm.heal_unit(paws, heal_amt)
		var add_ch: float = 2.0 if attacker.eidolon >= 2 else 1.0
		paws.charge_comp.add_charge(add_ch)
		recalculate_paws_max_hp(paws, attacker)
		bm.log_message("🐾 Лапы антиматерии очищены от контроля, восстановлено %d ХП (+%.0f заряда, текущий: %.0f/4)!" % [
			int(heal_amt), add_ch, paws.get_charge()
		])
		
	if attacker.eidolon >= 2:
		attacker.advance_action(50.0)
		add_crescendo(attacker, 30.0, bm)
		bm.log_message("🩸 Эйдолон 2: Действие Раймса продвинуто на 50%%, получено +30%% Крещендо!")
		bm.action_order_changed.emit()

# ==============================================================================
# 7. СВЕРХСПОСОБНОСТЬ (100% Крещендо)
# ==============================================================================
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	attacker.set_meta("crescendo_stacks", 0.0)
	attacker.energy = 0.0
	
	bm.add_xaeroh(10)
	
	var paws := get_paws_sprite(attacker, bm)
	if paws == null or not paws.is_alive():
		var def := create_paws_definition(attacker)
		paws = MemospriteSystem.summon(attacker, def, bm)
		if attacker.eidolon >= 2:
			paws.charge_comp.add_charge(2.0)
		recalculate_paws_max_hp(paws, attacker)
		bm.log_message("🌌 Сверхспособность: «Лапы антиматерии» призваны на поле боя (+10 Зеро)!")
	else:
		var heal_amt := paws.stats.max_hp * 0.60
		bm.heal_unit(paws, heal_amt)
		var add_ch: float = 2.0 if attacker.eidolon >= 2 else 1.0
		paws.charge_comp.add_charge(add_ch)
		recalculate_paws_max_hp(paws, attacker)
		bm.log_message("🌌 Сверхспособность: Лапам антиматерии восстановлено %d ХП (+%.0f заряда, +10 Зеро)!" % [
			int(heal_amt), add_ch
		])
		
	if paws != null and paws.is_alive():
		paws.advance_action(100.0)
		bm.action_order_changed.emit()
		
	# Создание зоны «Разрыв» на 3 хода Раймса
	attacker.set_meta("rupture_zone_turns", 3)
	attacker.set_meta("rimes_rupture_zone_turns", 3)
	attacker.set_meta("rimes_rupture_skip_tick", true)
	bm.log_message("🔮 Создана территория «Разрыв» на 3 хода Раймса • Восхождение: Сопротивления противников понижены на 20%%!")
	bm.unit_updated.emit(attacker)

# ==============================================================================
# 8. АТАКУЮЩАЯ ТЕХНИКА
# ==============================================================================
static func execute_technique(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.gain_skill_point()
	add_crescendo(attacker, 30.0, bm)
	for ally in bm.allies:
		if ally.is_alive():
			ally.advance_action(20.0)
	bm.action_order_changed.emit()
	
	var living_enemies := bm.get_living_enemies()
	for enemy in living_enemies:
		if enemy.is_alive():
			var res := bm.calc_dmg(attacker, enemy, 1.0, 0.0, false, 0.0, 0.0, false, true, "Technique")
			var dmg: float = float(res.get("damage", 0.0))
			bm.deal_damage(enemy, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Technique")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			
	bm.log_message("⚔ Атакующая техника Раймса • Восхождение: 100%% макс. ХП всем врагам, +1 ОН, +30%% Крещендо, действия команды +20%%!")

# ==============================================================================
# 9. ХОД И УМЕНИЯ ДУХА ПАМЯТИ
# ==============================================================================
static func execute_paws_skill(paws: Memosprite, _target: CombatUnit, bm: BattleManager) -> void:
	if paws == null or not paws.is_alive():
		return
	var current_charge := paws.get_charge() if paws.charge_comp != null else 1.0
	if current_charge >= 4.0:
		execute_paws_sforzando(paws, bm)
	else:
		execute_paws_con_brio(paws, bm)

static func _apply_e1_mult(target: CombatUnit, base_dmg: float, owner: CombatUnit) -> float:
	if owner == null or owner.eidolon < 1 or target == null or target.stats.max_hp <= 0.0:
		return base_dmg
	var hp_ratio := target.stats.hp / target.stats.max_hp
	if hp_ratio <= 0.50:
		return base_dmg * 1.40
	elif hp_ratio <= 0.80:
		return base_dmg * 1.20
	return base_dmg

static func execute_paws_con_brio(paws: Memosprite, bm: BattleManager) -> void:
	var owner := paws.owner
	var living := bm.get_living_enemies()
	if living.is_empty():
		return
		
	# Ищем противника с самым высоким текущим ХП
	var highest_hp_enemy: CombatUnit = living[0]
	for e in living:
		if e.stats.hp > highest_hp_enemy.stats.hp:
			highest_hp_enemy = e
			
	var charges: int = int(paws.get_charge()) if paws.charge_comp != null else 1
	var total_hits: int = maxi(1, charges)
	
	bm.log_message("🐾 Лапы антиматерии используют «Con brio» (%d ударов)!" % total_hits)
	
	for i in range(total_hits):
		# След 3: +30% урона за применение/удар, стакается до 6 раз до конца хода
		var t3_st: int = int(paws.get_meta("paws_trace3_stacks", 0))
		paws.set_meta("paws_trace3_stacks", mini(t3_st + 1, 6))
		
		living = bm.get_living_enemies()
		if living.is_empty():
			break
			
		var target: CombatUnit = highest_hp_enemy if (i == 0 and highest_hp_enemy.is_alive()) else living.pick_random()
		if target == null or not target.is_alive():
			target = living.pick_random()
			
		var scale: float = 0.40 if i == 0 else 0.35
		var res := bm.calc_dmg(paws, target, scale, 0.0, false, 0.0, 0.0, false, true, "MemospriteSkill")
		var dmg: float = float(res.get("damage", 0.0))
		dmg = _apply_e1_mult(target, dmg, owner)
		var ignore_w: bool = owner != null and owner.eidolon >= 6
		bm.deal_damage(target, dmg, paws, paws.element, bool(res.get("crit", false)), "MemospriteSkill")
		ToughnessSystem.apply_weakness_hit(paws, target, bm, 1.0, ignore_w)

static func execute_paws_sforzando(paws: Memosprite, bm: BattleManager) -> void:
	var owner := paws.owner
	var living := bm.get_living_enemies()
	if living.is_empty():
		return
		
	bm.log_message("🎶 Лапы антиматерии активируют «Sforzando» (Групповая атака)!")
	
	# 3 удара по 50% макс. ХП Лап всем врагам
	for hit_idx in range(3):
		var t3_st: int = int(paws.get_meta("paws_trace3_stacks", 0))
		paws.set_meta("paws_trace3_stacks", mini(t3_st + 1, 6))
		living = bm.get_living_enemies()
		for enemy in living:
			if enemy.is_alive():
				var res := bm.calc_dmg(paws, enemy, 0.50, 0.0, false, 0.0, 0.0, false, true, "MemospriteSkill")
				var dmg: float = float(res.get("damage", 0.0))
				dmg = _apply_e1_mult(enemy, dmg, owner)
				var ignore_w: bool = owner != null and owner.eidolon >= 6
				bm.deal_damage(enemy, dmg, paws, paws.element, bool(res.get("crit", false)), "MemospriteSkill")
				ToughnessSystem.apply_weakness_hit(paws, enemy, bm, 0.6, ignore_w)
				
	# 4-й удар: 90% макс. ХП Лап всем врагам
	var t3_st_4: int = int(paws.get_meta("paws_trace3_stacks", 0))
	paws.set_meta("paws_trace3_stacks", mini(t3_st_4 + 1, 6))
	living = bm.get_living_enemies()
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(paws, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "MemospriteSkill")
			var dmg: float = float(res.get("damage", 0.0))
			dmg = _apply_e1_mult(enemy, dmg, owner)
			var ignore_w: bool = owner != null and owner.eidolon >= 6
			bm.deal_damage(enemy, dmg, paws, paws.element, bool(res.get("crit", false)), "MemospriteSkill")
			ToughnessSystem.apply_weakness_hit(paws, enemy, bm, 1.0, ignore_w)
			
	# Если Зеро >= 60: тратит 20 Зеро и повторяет 4-й удар
	if bm.get_xaeroh() >= 60:
		bm.spend_xaeroh(20)
		bm.log_message("🌌 Sforzando: Потрачено 20 Зеро -> повтор 4-го сокрушительного удара (90%%)!")
		living = bm.get_living_enemies()
		for enemy in living:
			if enemy.is_alive():
				var res := bm.calc_dmg(paws, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "MemospriteSkill")
				var dmg: float = float(res.get("damage", 0.0))
				dmg = _apply_e1_mult(enemy, dmg, owner)
				var ignore_w: bool = owner != null and owner.eidolon >= 6
				bm.deal_damage(enemy, dmg, paws, paws.element, bool(res.get("crit", false)), "MemospriteSkill")
				ToughnessSystem.apply_weakness_hit(paws, enemy, bm, 1.0, ignore_w)

	# Сброс зарядов до 1
	if paws.charge_comp != null:
		paws.charge_comp.set_charge(1.0)
	recalculate_paws_max_hp(paws, owner)
	bm.log_message("🐾 Лапы антиматерии сбросили заряды до 1.")

# ==============================================================================
# 10. ТАЛАНТ ДУХА ПАМЯТИ (ГИБЕЛЬ / ИСЧЕЗНОВЕНИЕ)
# ==============================================================================
static func on_paws_talent(_sprite: Memosprite, _ally: CombatUnit, _amt: float, _bm: BattleManager) -> void:
	pass

static func on_paws_despawn(paws: Memosprite, bm: BattleManager) -> void:
	if paws == null or bm == null:
		return
	var owner := paws.owner
	if owner == null:
		return
		
	var hits_count := 9 if (owner != null and owner.eidolon >= 6) else 6
	var dmg_scale: float = 0.52 if (owner != null and owner.eidolon >= 6) else 0.40
	
	bm.log_message("💥 Талант Духа Памяти: Лапы антиматерии исчезают, обрушивая %d ударов возмездия!" % hits_count)
	
	for i in range(hits_count):
		var living := bm.get_living_enemies()
		if living.is_empty():
			break
		var target: CombatUnit = living.pick_random()
		var res := bm.calc_dmg(owner, target, dmg_scale, 0.0, false, 0.0, 0.0, false, true, "MemospriteTalent")
		var dmg: float = float(res.get("damage", 0.0))
		dmg = _apply_e1_mult(target, dmg, owner)
		bm.deal_damage(target, dmg, owner, owner.element, bool(res.get("crit", false)), "MemospriteTalent")
		ToughnessSystem.apply_weakness_hit(owner, target, bm, 0.5)

	# Восстановление ХП союзникам: 6% от макс. ХП Раймса + 400
	var heal_amt: float = owner.stats.max_hp * 0.06 + 400.0
	for ally in bm.allies:
		if ally.is_alive():
			bm.heal_unit(ally, heal_amt)
	bm.log_message("💖 Талант Лап: Восстановлено всем союзникам по %d ХП!" % int(heal_amt))
