class_name JoanSpiritAbilities
extends RefCounted

const ID: String = "joan_spirit"
const MAX_LAST_WISH: int = 12
const MAX_REGRET: int = 7
const MAX_GOLD_REMNANTS: int = 12

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Жоан • Дух решимости",
		"element": CombatConstants.Element.IMAGINARY,
		"path": CombatConstants.Path.ERUDITION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": 12.0, # Шкала энергии визуализирует уровни «Последнего желания» (0-12)
		"stats": {
			"hp": 3200,
			"atk": 1550,
			"def": 820,
			"spd": 112,
			"crit_rate": 0.30,
			"crit_dmg": 0.60,
			"effect_hit_rate": 0.00,
			"break_effect": 0.15,
			"weakness_efficiency": 0.00,
		},
	})
	
	# Инициализация уникальных ресурсов
	var start_wishes: int = 12 if eidolon >= 6 else 0
	unit.set_meta("joan_last_wish", start_wishes)
	unit.set_meta("joan_regret", 0)
	unit.energy = float(start_wishes)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_empyrean_member", true)

# --- РАБОТА С РЕСУРСАМИ ---

static func add_last_wish(unit: CombatUnit, amount: int, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive():
		return
	var cur: int = int(unit.get_meta("joan_last_wish", 0))
	var new_val: int = mini(cur + amount, MAX_LAST_WISH)
	unit.set_meta("joan_last_wish", new_val)
	unit.energy = float(new_val) # Синхронизируем с полоской ульты
	bm.unit_updated.emit(unit)
	bm.log_message("🌟 «Последнее желание» Жоана: %d/%d (+%d)." % [new_val, MAX_LAST_WISH, amount])

static func add_regret(unit: CombatUnit, amount: int, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive():
		return
	var cur: int = int(unit.get_meta("joan_regret", 0))
	var new_val: int = mini(cur + amount, MAX_REGRET)
	unit.set_meta("joan_regret", new_val)
	bm.unit_updated.emit(unit)
	bm.log_message("💔 «Сожаление» Жоана: %d/%d (+%d)." % [new_val, MAX_REGRET, amount])

static func add_gold_remnants(unit: CombatUnit, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive():
		return
	var cur: int = int(unit.get_meta("joan_gold_remnants", 0))
	if cur < MAX_GOLD_REMNANTS:
		var new_val: int = cur + 1
		unit.set_meta("joan_gold_remnants", new_val)
		bm.unit_updated.emit(unit)
		bm.log_message("⚜ След 1 Жоана: «Остатки золота» x%d/%d (+%d%% СА всей команде)." % [new_val, MAX_GOLD_REMNANTS, new_val * 4])

# --- СПОСОБНОСТИ ---

# 1. Базовая атака [Одиночная атака] (80% СА)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 0.80, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	add_last_wish(attacker, 1, bm)
	bm.gain_skill_point()
	bm.action_order_changed.emit()

# 2. Усиленная базовая атака [Взрывная атака] (220% центру, 180% соседям, 0 ОН)
static func execute_enhanced_basic(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adjacent := bm.get_adjacent_enemies(target)
	
	# Центр
	var res_c := bm.calc_dmg(attacker, target, 2.20, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.5)
	
	# Соседи
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, 1.80, 0.0, false, 0.0, 0.0, false, true, "Basic")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Basic")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 1.0)
			
	add_regret(attacker, 2, bm)
	# Внимание: Усиленная базовая НЕ восстанавливает ОН!
	bm.log_message("⚔ Усиленная базовая атака Жоана: нанесен взрывной урон, получено +2 «Сожаления».")
	bm.action_order_changed.emit()

# 3. Навык Q - 0 SP [Групповая атака] (120% СА всем)
static func execute_skill_q(attacker: CombatUnit, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	var hit_count := 0
	
	for enemy in living:
		hit_count += 1
		var res := bm.calc_dmg(attacker, enemy, 1.20, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
	add_regret(attacker, hit_count, bm)
	bm.log_message("🔷 Навык Q Жоана: АоЕ удар по %d врагам, получено +%d «Сожаления»." % [hit_count, hit_count])
	bm.unit_updated.emit(attacker)

# 4. Навык E - 4 (или 3 при Е1) Сожаления [Групповая атака] (300% СА всем + 100% за каждого отсутствующего ниже 5)
static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	var cost := 3 if attacker.eidolon >= 1 else 4
	var cur_regret := int(attacker.get_meta("joan_regret", 0))
	attacker.set_meta("joan_regret", maxi(0, cur_regret - cost))
	
	var living := bm.get_living_enemies()
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, 3.00, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Skill")
		# 40 единиц стойкости (х2.0 от стандарта)
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
		
	# За каждого отсутствующего противника ниже 5: случайная цель получает 100% СА
	var missing_enemies: int = maxi(0, 5 - living.size())
	if missing_enemies > 0:
		bm.log_message("🎯 Навык E Жоана: Отсутствует %d целей до 5! Обрушиваются дополнительные удары." % missing_enemies)
		for i in range(missing_enemies):
			var current_alive := bm.get_living_enemies()
			if current_alive.is_empty():
				break
			var random_target: CombatUnit = current_alive.pick_random()
			var extra_res := bm.calc_dmg(attacker, random_target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(random_target, extra_res.damage, attacker, attacker.element, extra_res.crit, "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, random_target, bm, 0.5)
			
	var wish_gain := 2 if attacker.eidolon >= 1 else 1
	add_last_wish(attacker, wish_gain, bm)
	bm.unit_updated.emit(attacker)

# 5. Сверхспособность
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	var in_spirit_form: bool = attacker.get_meta("joan_spirit_form", false)
	
	if not in_spirit_form:
		# --- ПЕРВОЕ ПРИМЕНЕНИЕ (12 УРОВНЕЙ): ВХОД В ФОРМУ ДУХА ---
		attacker.set_meta("joan_spirit_form", true)
		attacker.set_meta("joan_last_wish", 0)
		attacker.energy = 0.0
		
		# НАЧИСЛЕНИЕ 4 СТАРТОВЫХ ЗАРЯДОВ СОЖАЛЕНИЯ:
		add_regret(attacker, 4, bm)
		
		# Все враги получают Мнимую уязвимость
		for enemy in bm.enemies:
			if enemy.is_alive():
				if not CombatConstants.Element.IMAGINARY in enemy.weaknesses:
					enemy.weaknesses.append(CombatConstants.Element.IMAGINARY)
		
		bm.set_meta("joan_spirit_background_active", true)
		bm.log_message("🌟 СВЕРХСПОСОБНОСТЬ: Жоан переходит в «Форму духа»! Получено 4 стартовых заряда «Сожаления», все противники получили Мнимую уязвимость, а урон по Жоану снижен на 40%!")
		bm.unit_updated.emit(attacker)
	else:
		# --- ПОСЛЕДУЮЩИЕ ПРИМЕНЕНИЯ (10 УРОВНЕЙ): АОЕ 480% СА + РАЗДЕЛЕНИЕ БОССА ---
		var cur_wish := int(attacker.get_meta("joan_last_wish", 0))
		attacker.set_meta("joan_last_wish", maxi(0, cur_wish - 8)) # Списываем 8 вместо 10
		attacker.energy = float(attacker.get_meta("joan_last_wish", 0))
		
		# ЭФФЕКТ: Бело-золотая вспышка и сотрясение экрана!
		if bm.has_signal("screen_impact_requested"):
			bm.screen_impact_requested.emit(Color(1.0, 0.96, 0.72, 0.70), 9.0)
		
		var living := bm.get_living_enemies()
		var initial_enemy_count := living.size()
		
		# МЕХАНИКА РАЗДЕЛЕНИЯ ОДНОГО ВРАГА НА 5 КОПИЙ
		if living.size() == 1:
			var solo_enemy: CombatUnit = living[0]
			
			# Формула: делим текущее ХП на 5 и умножаем на 3 для каждой цели
			var cur_hp: float = solo_enemy.stats.hp
			var split_hp: float = maxf(1.0, (cur_hp / 5.0) * 3.0)
			var split_max_hp: float = maxf(split_hp, (solo_enemy.stats.max_hp / 5.0) * 3.0)
			
			bm.log_message("💥 РАЗДЕЛЕНИЕ ДУХА: %s разделяется на 5 сущностей! ХП каждой цели: %d (x3)." % [solo_enemy.display_name, int(split_hp)])
			
			# 1. Настройка ОСНОВНОЙ цели (сохраняет все свои умения и дебаффы)
			solo_enemy.stats.hp = split_hp
			solo_enemy.stats.max_hp = split_max_hp
			solo_enemy.set_meta("base_hp_original", split_max_hp)
			solo_enemy.slot_index = 0
			
			# 2. Очищаем старый список врагов (удаляя всех ранее побежденных)
			bm.enemies.clear()
			bm.enemies.append(solo_enemy)
			
			# 3. Создаем 4 разделённые копии
			for i in range(1, 5):
				var clone := CombatUnit.new()
				clone.setup_from_template({
					"id": solo_enemy.id + "_clone",
					"name": "%s (Копия %d)" % [solo_enemy.display_name, i],
					"element": solo_enemy.element,
					"is_ally": false,
					"stats": {
						"hp": split_hp,
						"max_hp": split_max_hp,
						"atk": solo_enemy.stats.atk,
						"def": solo_enemy.stats.def,
						"spd": solo_enemy.stats.spd,
						"crit_rate": solo_enemy.stats.crit_rate,
						"crit_dmg": solo_enemy.stats.crit_dmg,
						"effect_hit_rate": solo_enemy.stats.effect_hit_rate,
						"break_effect": solo_enemy.stats.break_effect,
					}
				})
				
				clone.weaknesses = solo_enemy.weaknesses.duplicate()
				clone.max_toughness = solo_enemy.max_toughness
				clone.toughness = solo_enemy.max_toughness
				clone.slot_index = i
				
				# Маркер копии (в свой ход наносит 5% СА случайному союзнику, заряжая «Последнее желание» Жоана)
				clone.set_meta("is_joan_spirit_clone", true)
				clone.set_meta("base_hp_original", split_max_hp)
				clone.set_meta("base_atk_original", clone.stats.atk)
				clone.set_meta("base_def_original", clone.stats.def)
				clone.set_meta("base_spd_original", clone.stats.spd)
				
				# С разделённых копий сбрасываются все усиления и ослабления
				clone.statuses.cleanse_all()
				
				# Откладываем действие копии на 100%
				clone.recalculate_action_value()
				clone.delay_action(100.0)
				
				bm.enemies.append(clone)
				
			# Перерисовываем карточки врагов на поле боя
			bm.enemies_reshuffled.emit.call_deferred()
			bm.action_order_changed.emit()
			living = bm.get_living_enemies()
			
		# След 2: Последующие применения Сверхспособности наносят на 30% больше урона, если живых противников <= 3
		var trace2_bonus := 0.30 if (initial_enemy_count <= 3 or living.size() <= 3) else 0.0
		attacker.set_meta("joan_ult_ignore_imaginary_res", true)
		
		for enemy in living:
			var res := bm.calc_dmg(attacker, enemy, 3.80, 0.0, false, trace2_bonus, 0.0, true, true, "Ultimate")
			bm.deal_damage(enemy, res.damage, attacker, CombatConstants.Element.IMAGINARY, res.crit, "Ultimate")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 2.0)
			
		attacker.remove_meta("joan_ult_ignore_imaginary_res")
		if trace2_bonus > 0.0:
			bm.log_message("⚡ След 2 Жоана: Живых врагов <= 3 (%d). Урон Сверхспособности увеличен на +30%%!" % initial_enemy_count)
		
		# Эйдолон 4: Повторные ультимейты лечат союзников на 20% макс. ХП
		if attacker.eidolon >= 4:
			for ally in bm.allies:
				if ally.is_alive():
					var heal_val := ally.stats.max_hp * 0.20
					bm.heal_unit(ally, heal_val)
			bm.log_message("💖 Эйдолон 4 Жоана: Весь отряд исцелен на 20%% макс. ХП!")
			
		bm.log_message("✨ Сверхспособность Жоана нанесла 480%% урона всем целям!")
		bm.unit_updated.emit(attacker)
