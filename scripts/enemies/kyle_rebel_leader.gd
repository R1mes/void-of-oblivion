class_name KyleRebelLeader
extends RefCounted

const AntimatterSlave = preload("res://scripts/enemies/antimatter_slave.gd")

const ID: String = "kyle_rebel_leader"

static func create_unit(slot_idx: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Кайл • Лидер восстания",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true, # Босс считается элитным
		"stats": {
			"hp": 350000.0, # Фаза 1
			"atk": 2400.0,
			"def": 950.0,
			"spd": 100.0,
			"crit_rate": 0.15,
			"crit_dmg": 0.75,
			"effect_res": 0.35,
		},
		"toughness": 360.0,
		"weaknesses": [
			CombatConstants.Element.WIND,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.PHYSICAL,
		],
	})
	unit.slot_index = slot_idx
	unit.set_meta("base_hp_original", 350000.0)
	unit.set_meta("base_atk_original", 2400.0)
	unit.set_meta("base_def_original", 950.0)
	unit.set_meta("base_spd_original", 100.0)
	unit.set_meta("phase", 1)
	unit.set_meta("turn_count", 0)
	unit.set_meta("turn_p2_count", 0)
	unit.set_meta("rebellion_veil_stacks", 3)
	unit.set_meta("boss_dmg_reduction", 0.45) # 3 стака по 15% = 45%
	return unit

static func pick_target(allies: Array, prioritize_highest_atk: bool = false) -> CombatUnit:
	# 1. Провокация Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

	# 2. Приоритет наивысшей СА
	if prioritize_highest_atk:
		var max_atk: float = -1.0
		var top_target: CombatUnit = null
		for a in allies:
			if a is CombatUnit and a.is_alive():
				if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
					continue
				var cur_atk: float = a.stats.atk
				if cur_atk > max_atk:
					max_atk = cur_atk
					top_target = a
		if top_target != null:
			return top_target

	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
				continue
			living.append(a)

	if living.is_empty():
		for a in allies:
			if a is CombatUnit and a.is_alive():
				living.append(a)

	if living.is_empty():
		return null

	return living[randi() % living.size()]

static func _has_alive_memosprite(bm: BattleManager) -> Memosprite:
	if bm == null:
		return null
	for m in bm.memosprites:
		if m is Memosprite and m.is_alive():
			return m
	return null

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var phase := int(enemy.get_meta("phase", 1))
	if phase == 1:
		_execute_phase_1(enemy, allies, bm)
	else:
		_execute_phase_2(enemy, allies, bm)

# --- ФАЗА 1 ---
static func _execute_phase_1(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	# Восстановление стаков Завесы раз в 4 хода
	if turn > 1 and turn % 4 == 0:
		enemy.set_meta("rebellion_veil_stacks", 3)
		enemy.set_meta("boss_dmg_reduction", 0.45)
		bm.log_message("🛡 %s восстанавливает «Завесу восстания» (3 стака, -45%% входящего урона)!" % enemy.display_name)
		bm.unit_updated.emit(enemy)

	# Раз в 3 хода — «Казнь тиранов» (Special), иначе чередование
	if turn % 3 == 0:
		_execute_tyrants_execution(enemy, allies, bm)
	elif turn % 2 == 0:
		_execute_call_of_rebellion(enemy, allies, bm)
	else:
		_execute_punishing_verdict(enemy, allies, bm)

# Способность 1.1: Карающий приговор (Single Target, 100% СА)
static func _execute_punishing_verdict(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("👑 %s: «Карающий приговор» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.00)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 1.2: Клич восстания (Blast, 80% основной / 40% смежным + «Подавление»)
static func _execute_call_of_rebellion(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("👑 %s: «Клич восстания» по %s и смежным союзникам!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 0.80)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	# Дебафф Подавление (-15% скорости на 2 хода)
	target.add_speed_modifier(-0.15, 0.0)
	target.set_meta("kyle_suppression_turns", 2)
	bm.log_message("  🌀 %s подавлен: скорость снижена на 15%% на 2 хода!" % target.display_name)

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.40)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Способность 1.3: Казнь тиранов (Special, 180% СА)
# Тактика Духов Памяти: Дух Памяти блокирует урон без вреда для себя!
static func _execute_tyrants_execution(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return

	var sprite := _has_alive_memosprite(bm)
	if sprite != null:
		bm.log_message("👑 %s замахивается для «Казни тиранов» по %s!" % [enemy.display_name, target.display_name])
		bm.log_message("🛡✨ Дух Памяти %s воздвигает «Щит памяти»! Удар заблокирован на 70%%!" % sprite.display_name)
		var res: Dictionary = bm.calc_dmg(enemy, target, 1.80 * 0.30)
		bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

		# Кайл получает отдачу: теряет 40 ед. стойкости и задерживается на 25%
		if not enemy.statuses.toughness_broken and enemy.toughness > 0.0:
			enemy.toughness = maxf(0.0, enemy.toughness - 40.0)
			if enemy.toughness <= 0.0:
				bm.break_enemy_toughness(enemy, sprite)
		enemy.delay_action(25.0)
		bm.log_message("  ⚡ Ментальная отдача: %s теряет 40 ед. стойкости, его действие задержано на 25%%!" % enemy.display_name)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(enemy)
	else:
		bm.log_message("👑 %s обрушивает «Казнь тиранов» по %s!" % [enemy.display_name, target.display_name])
		var res: Dictionary = bm.calc_dmg(enemy, target, 1.80)
		bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# --- ПЕРЕХОД ВО 2-Ю ФАЗУ ---
static func start_phase_2(enemy: CombatUnit, bm: BattleManager) -> void:
	enemy.set_meta("phase", 2)
	enemy.stats.max_hp = 400000.0
	enemy.stats.hp = 400000.0
	enemy.set_meta("base_hp_original", 400000.0)
	enemy.stats.atk = 2700.0
	enemy.set_meta("base_atk_original", 2700.0)
	enemy.stats.def = 1050.0
	enemy.set_meta("base_def_original", 1050.0)
	enemy.stats.spd = 106.0
	enemy.set_meta("base_spd_original", 106.0)
	enemy.statuses.toughness_broken = false
	enemy.toughness = enemy.max_toughness
	enemy.set_meta("turn_p2_count", 0)
	enemy.set_meta("rebellion_veil_stacks", 3)
	enemy.set_meta("boss_dmg_reduction", 0.45)
	bm.log_message("👑🚩 Кайл взывает к ядру сингулярности: «Триумвират восстания»! Фаза 2 началась (400 000 ХП)!")
	bm.unit_updated.emit(enemy)

# --- ФАЗА 2 ---
static func _execute_phase_2(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_p2_count", 0)) + 1
	enemy.set_meta("turn_p2_count", turn)

	if turn > 1 and turn % 4 == 0:
		enemy.set_meta("rebellion_veil_stacks", 3)
		enemy.set_meta("boss_dmg_reduction", 0.45)
		bm.log_message("🛡 %s восстанавливает «Завесу восстания» (3 стака, -45%% входящего урона)!" % enemy.display_name)
		bm.unit_updated.emit(enemy)

	if turn % 3 == 0:
		_execute_ultimate_verdict(enemy, allies, bm)
	elif turn % 2 == 0:
		_execute_crush_shackles(enemy, allies, bm)
	else:
		_execute_summon_or_blast(enemy, allies, bm)

# Способность 2.1: Сокрушение оков (AoE 120% СА)
# Если есть Дух Памяти — накладывает щит на всех союзников!
static func _execute_crush_shackles(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("👑 %s: «Сокрушение оков» по всему отряду!" % enemy.display_name)
	var sprite := _has_alive_memosprite(bm)
	if sprite != null:
		var shield_val: float = sprite.stats.max_hp * 0.20
		bm.log_message("✨ Дух Памяти %s излучает «Свет Памяти», укрывая союзников щитом на %d ед.!" % [sprite.display_name, int(shield_val)])
		for a in allies:
			if a is CombatUnit and a.is_alive():
				bm.apply_shield(a, shield_val, 2, "Свет Памяти")
				bm.unit_updated.emit(a)

	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, a, 1.20)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 2.2: Призыв тени восстания (или тяжелый Blast 100%/50%)
static func _execute_summon_or_blast(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	# Проверяем, есть ли свободный слот для раба
	var empty_slot := -1
	for idx in range(bm.enemies.size()):
		var e = bm.enemies[idx]
		if e == null or not e.is_alive():
			empty_slot = idx
			break

	if empty_slot != -1 and bm.enemies.size() < 4:
		var slave: CombatUnit = AntimatterSlave.create_unit(empty_slot)
		slave.stats.max_hp = 30000.0
		slave.stats.hp = slave.stats.max_hp
		slave.stats.atk = 1200.0
		slave.display_name = "Призванный Раб Антиматерии"
		bm.enemies[empty_slot] = slave
		bm.log_message("👑 %s призывает подкрепление: %s!" % [enemy.display_name, slave.display_name])
		bm.enemies_reshuffled.emit.call_deferred()
		bm.action_order_changed.emit()
		bm.unit_updated.emit(slave)
	else:
		var target := pick_target(allies)
		if target == null:
			return
		bm.log_message("👑 %s: «Тяжёлый залп восстания» по %s и смежным!" % [enemy.display_name, target.display_name])
		var res_main: Dictionary = bm.calc_dmg(enemy, target, 1.00)
		bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))
		var adj := bm.get_adjacent_allies(target)
		for neighbor in adj:
			if neighbor.is_alive():
				var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.50)
				bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Способность 2.3: Ультимативный приговор (Ultimate, 220% СА)
# Дух Памяти отвлекает удар на иллюзию: цель получает 0 урона, пати получает +25% КУ!
static func _execute_ultimate_verdict(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return

	var sprite := _has_alive_memosprite(bm)
	if sprite != null:
		bm.log_message("👑 %s зачитывает «Ультимативный приговор» по %s!" % [enemy.display_name, target.display_name])
		bm.log_message("✨🔮 Дух Памяти %s создает иллюзорную копию! Удар Кайла уходит в пустоту (0 урона)!" % sprite.display_name)
		bm.log_message("  ⚔ Вдохновение памятью: Крит. урон всех союзников повышен на +25%% на 2 хода!")
		for a in allies:
			if a is CombatUnit and a.is_alive():
				a.stats.crit_dmg += 0.25
				a.set_meta("kyle_crit_buff_turns", 2)
				bm.unit_updated.emit(a)
	else:
		bm.log_message("👑 %s обрушивает смертоносный «Ультимативный приговор» по %s!" % [enemy.display_name, target.display_name])
		var res: Dictionary = bm.calc_dmg(enemy, target, 2.20)
		bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Тактика Духов Памяти: Реакция на атаку Духа Памяти
static func on_attacked_by_memosprite(enemy: CombatUnit, memosprite: CombatUnit, bm: BattleManager) -> void:
	# Снимаем стак Завесы
	var cur_veil: int = int(enemy.get_meta("rebellion_veil_stacks", 0))
	if cur_veil > 0:
		cur_veil -= 1
		enemy.set_meta("rebellion_veil_stacks", cur_veil)
		enemy.set_meta("boss_dmg_reduction", cur_veil * 0.15)
		bm.log_message("✨ Дух Памяти %s сокрушает «Завесу восстания» %s! (Осталось стаков: %d, защита -%d%%)" % [
			memosprite.display_name, enemy.display_name, cur_veil, int(cur_veil * 15)
		])

	# Накладываем статус «Раскол разума» (+15% получаемого урона на 2 хода, до 3 стаков = +45%)
	var cur_fracture: int = int(enemy.get_meta("kyle_mind_fracture_stacks", 0))
	if cur_fracture < 3:
		cur_fracture += 1
		enemy.set_meta("kyle_mind_fracture_stacks", cur_fracture)
	enemy.set_meta("kyle_mind_fracture_turns", 2)
	enemy.set_meta("kyle_vuln_pct", cur_fracture * 0.15)
	bm.log_message("  🧠 «Раскол разума»: получаемый Кайлом урон увеличен на +%d%%!" % int(cur_fracture * 15))

	# Дополнительное истощение 20 ед. стойкости Кайла
	if not enemy.statuses.toughness_broken and enemy.toughness > 0.0:
		enemy.toughness = maxf(0.0, enemy.toughness - 20.0)
		if enemy.toughness <= 0.0:
			bm.break_enemy_toughness(enemy, memosprite)

	# Восстановление 5 энергии всему отряду
	for a in bm.allies:
		if a is CombatUnit and a.is_alive():
			a.gain_energy(5.0)
			bm.unit_updated.emit(a)
	bm.log_message("  ⚡ Дух Памяти восстановил 5 ед. энергии всему отряду!")

	bm.unit_updated.emit(enemy)
