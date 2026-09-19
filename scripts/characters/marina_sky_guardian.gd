class_name MarinaSkyGuardianAbilities
extends RefCounted

const ID: String = "marina_sky_guardian"
const MAX_ENERGY: float = 140.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Марина • Хранитель небес",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.REMEMBRANCE,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2800,
			"atk": 1050,
			"def": 750,
			"spd": 105,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.0,
			"effect_res": 0.0,
			"break_effect": 0.0,
			"weakness_efficiency": 0.0,
		},
	})
	unit.set_meta("marina_sk_link_turns", 0)
	unit.set_meta("marina_sk_link_crit_rate", 0.0)
	unit.set_meta("marina_sk_elysium_zone_turns", 0)
	unit.set_meta("marina_sk_other_sprite_energy_triggered", false)
	return unit

static func create_ego_definition() -> MemospriteDefinition:
	var def := MemospriteDefinition.new()
	def.id = "ego"
	def.display_name = "Эго"
	def.element = CombatConstants.Element.WIND
	def.path = CombatConstants.Path.REMEMBRANCE
	
	def.hp_mode = MemospriteDefinition.HpMode.OWNER_SCALING
	def.hp_coefficient = 0.68
	def.hp_flat = 300.0
	
	def.speed_mode = MemospriteDefinition.SpeedMode.FIXED
	def.base_speed = 130.0
	
	def.charge_enabled = true
	def.max_charge = 100.0
	def.initial_charge = 0.0
	
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
	
	def.skill_name = "Дежавю?"
	def.enhanced_skill_name = "Реальность"
	def.talent_name = "Талант Эго"
	
	def.skill_callable = Callable(MarinaSkyGuardianAbilities, "execute_ego_dejavu")
	def.enhanced_skill_callable = Callable(MarinaSkyGuardianAbilities, "execute_ego_reality")
	def.talent_callable = Callable(MarinaSkyGuardianAbilities, "on_ego_talent_energy")
	
	return def

static func apply_battle_start_traces(marina: CombatUnit, bm: BattleManager) -> void:
	# След 2: В начале боя действие Марины продвигается на 30%
	marina.advance_action(30.0)
	bm.log_message("🕊 След 2: Действие Марины • Хранителя небес продвинуто на 30% в начале боя!")
	bm.action_order_changed.emit()

static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.0, 0.0, false, 0.0, 0.0, false, true, "Basic")
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, attacker, attacker.element, bool(res.get("crit", false)), "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	# Восстанавливает Эго 5% его заряда
	var ego := get_ego_sprite(attacker, bm)
	if ego != null and ego.is_alive() and ego.charge_comp != null:
		ego.add_charge(5.0)
		bm.log_message("✨ Базовая атака Марины: Эго восстанавливает 5%% заряда (Текущий: %.0f%%)!" % ego.get_charge())
		check_ego_full_charge(ego, bm)
		
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	on_attack_performed(attacker, bm)

static func execute_skill_q(attacker: CombatUnit, target_ally: CombatUnit, bm: BattleManager) -> void:
	if target_ally is Memosprite or (target_ally != null and bool(target_ally.get_meta("is_memosprite", false))):
		bm.log_message("❌ Марина не может выбрать Духа Памяти в качестве цели Навыка Q!")
		return
	var prev_target: CombatUnit = attacker.get_meta("marina_sk_linked_ally") if attacker.has_meta("marina_sk_linked_ally") else null
	if prev_target != target_ally:
		if prev_target != null:
			prev_target.remove_meta("marina_sk_linked_by")
		attacker.set_meta("marina_sk_link_crit_rate", 0.0)
		bm.log_message("🔗 Марина сменила цель связи: накопленный бонус крит. шанса сброшен.")
	
	attacker.set_meta("marina_sk_linked_ally", target_ally)
	attacker.set_meta("marina_sk_link_turns", 3)
	attacker.set_meta("marina_sk_link_skip_tick", true)
	
	if target_ally != null:
		target_ally.set_meta("marina_sk_linked_by", attacker)
	
	bm.gain_energy_with_err(attacker, 30.0)
	var cur_cr := float(attacker.get_meta("marina_sk_link_crit_rate", 0.0)) * 100.0
	bm.log_message("🔗 Марина • Хранитель небес образовала связь с «%s» на 3 хода (Текущий бонус КШ связи: +%.1f%%)!" % [
		target_ally.display_name if target_ally else "None",
		cur_cr
	])
	bm.unit_updated.emit(attacker)
	if target_ally:
		bm.unit_updated.emit(target_ally)

static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	
	var ego := get_ego_sprite(attacker, bm)
	if ego == null or not ego.is_alive():
		var def := create_ego_definition()
		var is_first_summon := not attacker.has_meta("marina_sk_ego_summoned_once")
		attacker.set_meta("marina_sk_ego_summoned_once", true)
		
		# След 2: Во время первого призыва Эго получает 40% заряда
		if is_first_summon:
			def.initial_charge = 40.0
			
		ego = MemospriteSystem.summon(attacker, def, bm)
		if is_first_summon and ego and ego.charge_comp:
			ego.charge_comp.set_charge(40.0)
			bm.log_message("🕊 След 2: Первый призыв Эго наделяет его 40% заряда!")
	else:
		# Эго уже призвано: снимаются все эффекты контроля и лечит на 60% макс. ХП
		MemospriteSystem.dispel_crowd_control(ego)
		var heal_amt := ego.stats.max_hp * 0.60
		ego.heal(heal_amt)
		bm.log_message("✨ Навык E: Эго очищено от всех эффектов контроля и восстановило %d ХП (60%% от макс. ХП)!" % int(heal_amt))
		bm.unit_updated.emit(ego)
		
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🌌 СВЕРХСПОСОБНОСТЬ: Марина • Хранитель небес разворачивает зону «Элизиум»!")
	
	# Восстанавливает 40% заряда Эго
	var ego := get_ego_sprite(attacker, bm)
	if ego != null and ego.is_alive() and ego.charge_comp != null:
		ego.add_charge(40.0)
		bm.log_message("✨ Сверхспособность: Эго восстанавливает 40%% заряда (Текущий: %.0f%%)!" % ego.get_charge())
		check_ego_full_charge(ego, bm)
	
	# Создание зоны «Элизиум» на 2 хода
	attacker.set_meta("marina_sk_elysium_zone_turns", 2)
	attacker.set_meta("marina_sk_elysium_skip_start_tick", true)
	
	# E6: продвигает действие всех духов памяти на 100% и увеличивает наносимый ими урон на 50% на 1 ход
	if attacker.eidolon >= 6:
		for m in bm.memosprites:
			if m != null and m.is_alive():
				m.advance_action(100.0)
				m.set_meta("marina_sk_e6_dmg_buff_turns", 1)
		bm.log_message("👑 Эйдолон 6: Действие всех духов памяти продвинуто на 100%, их наносимый урон повышен на +50% на 1 ход!")
		bm.action_order_changed.emit()

	bm.unit_updated.emit(attacker)

static func apply_technique(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🕊 Техника Марины: Призыв Эго в начале боя без траты очков навыков!")
	var def := create_ego_definition()
	var is_first_summon := not attacker.has_meta("marina_sk_ego_summoned_once")
	attacker.set_meta("marina_sk_ego_summoned_once", true)
	if is_first_summon:
		def.initial_charge = 40.0
	var ego := MemospriteSystem.summon(attacker, def, bm)
	if is_first_summon and ego and ego.charge_comp:
		ego.charge_comp.set_charge(40.0)

static func execute_ego_dejavu(ego: Memosprite, _target: CombatUnit, bm: BattleManager) -> void:
	bm.start_attack_action()
	bm.start_attack_recording(ego)
	bm.log_message("🌀 Эго применяет умение: «Дежавю?»!")
	
	# 4 удара случайным врагам по 30% СА Эго
	for i in range(4):
		var enemies := bm.get_living_enemies()
		if enemies.is_empty():
			break
		var rand_enemy: CombatUnit = enemies[randi() % enemies.size()]
		var res := bm.calc_dmg(ego, rand_enemy, 0.30, 0.0, false, 0.0, 0.0, false, true, "memosprite_skill")
		bm.deal_damage(rand_enemy, float(res.get("damage", 0.0)), ego, CombatConstants.Element.WIND, bool(res.get("crit", false)), "memosprite_skill")
		ToughnessSystem.apply_weakness_hit(ego, rand_enemy, bm, 0.5)
		
	# 1 удар по всем врагам по 90% СА Эго
	var all_enemies := bm.get_living_enemies()
	for enemy in all_enemies:
		if enemy.is_alive():
			var res_all := bm.calc_dmg(ego, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "memosprite_skill")
			bm.deal_damage(enemy, float(res_all.get("damage", 0.0)), ego, CombatConstants.Element.WIND, bool(res_all.get("crit", false)), "memosprite_skill")
			ToughnessSystem.apply_weakness_hit(ego, enemy, bm, 1.0)
			
	# След 3: При использовании «Дежавю?» Эго немедленно получает 5% заряда
	if ego.charge_comp != null:
		ego.add_charge(5.0)
		bm.log_message("🕊 След 3: Эго получает +5%% заряда от «Дежавю?» (Текущий: %.0f%%)!" % ego.get_charge())
		check_ego_full_charge(ego, bm)
		
	on_attack_performed(ego, bm)
	bm.finish_attack_action()

static func execute_ego_reality(ego: Memosprite, target: CombatUnit, bm: BattleManager) -> void:
	bm.start_attack_action()
	bm.start_attack_recording(ego)
	bm.log_message("🌟 ЭГО РАСХОДУЕТ ЗАРЯД И ВЫПУСКАЕТ: «Реальность»!")
	
	if target == null or not target.is_alive():
		var living := bm.get_living_enemies()
		if not living.is_empty():
			target = living[0]
			
	if target != null:
		# Выбранная цель: 180% СА
		var res_main := bm.calc_dmg(ego, target, 1.80, 0.0, false, 0.0, 0.0, false, true, "memosprite_skill")
		bm.deal_damage(target, float(res_main.get("damage", 0.0)), ego, CombatConstants.Element.WIND, bool(res_main.get("crit", false)), "memosprite_skill")
		ToughnessSystem.apply_weakness_hit(ego, target, bm, 2.0)
		_apply_reality_debuff(target, bm)
		
		# Соседние цели: 70% СА
		var adj := bm.get_adjacent_enemies(target)
		for a in adj:
			if a.is_alive():
				var res_adj := bm.calc_dmg(ego, a, 0.70, 0.0, false, 0.0, 0.0, false, true, "memosprite_skill")
				bm.deal_damage(a, float(res_adj.get("damage", 0.0)), ego, CombatConstants.Element.WIND, bool(res_adj.get("crit", false)), "memosprite_skill")
				ToughnessSystem.apply_weakness_hit(ego, a, bm, 1.0)
				_apply_reality_debuff(a, bm)

	# Сброс флага использования Реальности и расхода заряда
	ego.remove_meta("ego_ready_for_reality")
	ego.set_meta("use_reality", false)
	if ego.charge_comp != null:
		ego.charge_comp.set_charge(0.0)
		
	on_attack_performed(ego, bm)
	bm.finish_attack_action()

static func _apply_reality_debuff(enemy: CombatUnit, bm: BattleManager) -> void:
	enemy.set_meta("ego_reality_vuln_turns", 2)
	enemy.set_meta("ego_reality_true_dmg_turns", 2)
	enemy.set_meta("ego_reality_skip_tick", true)
	bm.log_message("👁 «Реальность»: %s получает +30%% входящего урона и +5%% чистого урона от атак союзников на 2 хода!" % enemy.display_name)
	bm.unit_updated.emit(enemy)

static func check_ego_full_charge(ego: Memosprite, bm: BattleManager) -> void:
	if ego == null or ego.charge_comp == null:
		return
	if ego.charge_comp.get_charge() >= 100.0 and not bool(ego.get_meta("ego_ready_for_reality", false)):
		ego.set_meta("ego_ready_for_reality", true)
		ego.set_meta("use_reality", true)
		ego.force_immediate_turn()
		bm.log_message("⚡ Заряд Эго достиг 100%! Действие Эго продвигается немедленно, следующее умение: «Реальность»!")
		bm.action_order_changed.emit()
		if bm.has_method("trigger_immediate_memosprite_turn"):
			bm.trigger_immediate_memosprite_turn(ego)

static func on_ego_talent_energy(_ego: Memosprite, _ally: CombatUnit, _energy_amt: float, bm: BattleManager) -> void:
	var ego := _ego
	if ego != null and ego.charge_comp != null:
		check_ego_full_charge(ego, bm)

static func get_ego_sprite(marina: CombatUnit, bm: BattleManager) -> Memosprite:
	return MemospriteSystem.get_sprite(marina, bm)

static func is_in_skill_q_link(unit: CombatUnit, marina: CombatUnit, bm: BattleManager) -> bool:
	if unit == null or marina == null:
		return false
	if int(marina.get_meta("marina_sk_link_turns", 0)) <= 0:
		return false
	var linked_ally: CombatUnit = marina.get_meta("marina_sk_linked_ally", null)
	if linked_ally == null or not linked_ally.is_alive():
		return false
		
	# 1. Сама Марина
	if unit == marina:
		return true
	# 2. Дух Памяти Марины (Эго)
	if unit is Memosprite and unit.owner == marina:
		return true
	# 3. Связанный союзник
	if unit == linked_ally:
		return true
	# 4. Дух Памяти связанного союзника
	if unit is Memosprite and unit.owner == linked_ally:
		return true
		
	return false

static func on_attack_performed(attacker: CombatUnit, bm: BattleManager) -> void:
	var marina := get_marina_unit(bm)
	if marina == null or not marina.is_alive():
		return
	if is_in_skill_q_link(attacker, marina, bm):
		var cur_cr: float = float(marina.get_meta("marina_sk_link_crit_rate", 0.0))
		if cur_cr < 0.25:
			var next_cr := minf(cur_cr + 0.015, 0.25)
			marina.set_meta("marina_sk_link_crit_rate", next_cr)
			bm.log_message("🔗 Связь Навыка Q: Атака %s повышает КШ связи на +1.5%%! (Всего: +%.1f%% / макс. +25%%)" % [attacker.display_name, next_cr * 100.0])

static func get_marina_unit(bm: BattleManager) -> CombatUnit:
	if bm == null:
		return null
	for ally in bm.allies:
		if ally != null and ally.is_alive() and ally.id == ID:
			return ally
	return null

static func check_other_memosprite_action(sprite: Memosprite, bm: BattleManager) -> void:
	var marina := get_marina_unit(bm)
	if marina == null or not marina.is_alive():
		return
	var ego := get_ego_sprite(marina, bm)
	if sprite != ego and not bool(marina.get_meta("marina_sk_other_sprite_energy_triggered", false)):
		marina.set_meta("marina_sk_other_sprite_energy_triggered", true)
		bm.gain_energy_with_err(marina, 8.0)
		bm.log_message("🕊 Талант Марины: Действие союзного духа памяти %s восстанавливает Марине 8 ед. энергии!" % sprite.display_name)
