class_name MaskedSilhouette
extends RefCounted

const ID: String = "masked_silhouette"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Силуэт в маске",
		"element": CombatConstants.Element.QUANTUM, # Мнимый
		"path": CombatConstants.Path.NIHILITY,        # Босс
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 120000, # ХП 1-й фазы
			"atk": 2500,
			"def": 1100,
			"spd": 110,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.40,
		},
		"toughness": 360,
		"weaknesses": [
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.IMAGINARY,
		],
	})
	unit.set_meta("phase", 1)
	unit.set_meta("turn_count", 0)
	unit.set_meta("turn_p2_count", 0)
	return unit

# Выбор случайного союзника
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В MASKED_SILHOUETTE.GD ===
static func pick_target(allies: Array) -> CombatUnit:
	# 1. Проверяем, есть ли в живых Данилл с активной Провокацией
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a # Провокация перехватывает удар босса!
				
	# 2. Если Провокации нет, выбираем случайную живую цель
	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			# Недосягаемые цели (Кирилл/Каори в тумане) игнорируются
			if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
				continue
			living.append(a)
			
	if living.is_empty():
		# Если все живые цели недосягаемы, бьем любого живого союзника
		for a in allies:
			if a is CombatUnit and a.is_alive():
				living.append(a)
				
	if living.is_empty():
		return null
		
	return living[randi() % living.size()]

# Поведение ИИ Силуэта в маске в зависимости от фазы и хода
static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var phase := int(enemy.get_meta("phase", 1))
	
	if phase == 1:
		_execute_phase_1(enemy, allies, bm)
	else:
		_execute_phase_2(enemy, allies, bm)

# --- ИИ ФАЗЫ 1 ---
static func _execute_phase_1(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)
	
	# Первый ход: Способность 3 (40% СА АоЕ по всем)
	if turn == 1:
		bm.log_message("🎭 Силуэт в маске: Способность 3 — Волна иллюзий!")
		for ally in allies:
			if ally.is_alive():
				var res := bm.calc_dmg(enemy, ally, 0.40)
				bm.deal_damage(ally, res.damage, enemy, enemy.element, res.crit)
		
		# Мгновенный доп. ход (Способность 1)
		_execute_phase1_extra_turn(enemy, allies, bm)
		return
		
	# Каждые 4 хода: Способность 2 (999% СА, не опускает ниже 1 ХП)
	if turn % 4 == 0:
		var target := pick_target(allies)
		if target:
			bm.log_message("🎭 Силуэт в маске: Способность 2 — Смертельный приговор %s!" % target.display_name)
			var res := bm.calc_dmg(enemy, target, 9.99)
			# Ограничение урона: не может опустить ХП ниже 1
			var final_damage := float(res.damage)
			if final_damage >= target.stats.hp:
				final_damage = target.stats.hp - 1.0
			bm.deal_damage(target, maxf(0.0, final_damage), enemy, enemy.element, res.crit)
		return
		
	# Обычный ход: Базовая атака (100% СА) + доп. ход
	var target := pick_target(allies)
	if target:
		bm.log_message("🎭 Силуэт в маске: Базовая атака по %s!" % target.display_name)
		var res := bm.calc_dmg(enemy, target, 1.00)
		bm.deal_damage(target, res.damage, enemy, enemy.element, res.crit)
		
		# Мгновенный доп. ход (Способность 1)
		_execute_phase1_extra_turn(enemy, allies, bm)

# Дополнительный ход 1-й фазы (Способность 1: 120% СА центру, 60% соседям)
static func _execute_phase1_extra_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
		
	bm.log_message("🎭 Силуэт в маске: Способность 1 [Доп. Ход] по %s!" % target.display_name)
	
	# Урон по главной цели
	var res := bm.calc_dmg(enemy, target, 1.20)
	bm.deal_damage(target, res.damage, enemy, enemy.element, res.crit)
	
	# Урон по соседям
	var adjacent := bm.get_adjacent_allies(target)
	for adj in adjacent:
		if adj.is_alive():
			var adj_res := bm.calc_dmg(enemy, adj, 0.60)
			bm.deal_damage(adj, adj_res.damage, enemy, enemy.element, adj_res.crit)

# --- ИИ ФАЗЫ 2 ---
static func _execute_phase_2(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	# Проверка 1-го действия во 2-й фазе: «Тайна сияющей маски»
	if enemy.has_meta("first_action_p2") and bool(enemy.get_meta("first_action_p2", false)):
		enemy.set_meta("first_action_p2", false)
		bm.log_message("🎭 Силуэт в маске: Способность 3 — Активация «Тайны сияющей маски» [14 уровней]!")
		
		# ИСПРАВЛЕНО: Чистые метаданные Силуэта вместо joan_
		enemy.set_meta("mask_layers", 14)
		enemy.set_meta("silhouette_mask_def_buff", 0.40)
		bm.unit_updated.emit(enemy)
		
		enemy.delay_action(80.0)
		bm.action_order_changed.emit()
		return
		
	var turn: int = int(enemy.get_meta("turn_p2_count", 0)) + 1
	enemy.set_meta("turn_p2_count", turn)
	
	# Каждые 4 хода во 2-й фазе: Способность 2 (80% СА всем + статус «Балласт» на 2 хода)
	if turn % 4 == 0:
		bm.log_message("🎭 Силуэт в маске: Способность 2 — Волна балласта!")
		for ally in allies:
			if ally.is_alive():
				var res := bm.calc_dmg(enemy, ally, 0.80)
				bm.deal_damage(ally, res.damage, enemy, enemy.element, res.crit)
				
				# Наложение статуса Балласт на 2 хода
				ally.set_meta("ballast_turns", 2)
				ally.set_meta("ballast_skip_tick", true)
				bm.unit_updated.emit(ally)
		return
		
	# Обычный ход: Базовая атака (70% СА центру, 20% соседям) + доп. ход
	var target := pick_target(allies)
	if target:
		bm.log_message("🎭 Силуэт в маске: Базовая атака по %s и окружающим!" % target.display_name)
		var res := bm.calc_dmg(enemy, target, 0.70)
		bm.deal_damage(target, res.damage, enemy, enemy.element, res.crit)
		
		var adjacent := bm.get_adjacent_allies(target)
		for adj in adjacent:
			if adj.is_alive():
				var adj_res := bm.calc_dmg(enemy, adj, 0.20)
				bm.deal_damage(adj, adj_res.damage, enemy, enemy.element, adj_res.crit)
				
		# Мгновенный доп. ход (Способность 1: 40% СА всем союзникам)
		_execute_phase2_extra_turn(enemy, allies, bm)

# Дополнительный ход 2-й фазы (Способность 1: 40% СА всем персонажам)
static func _execute_phase2_extra_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("🎭 Силуэт в маске: Способность 1 [Доп. Ход] — Огненный дождь по отряду!")
	for ally in allies:
		if ally.is_alive():
			var res := bm.calc_dmg(enemy, ally, 0.40)
			bm.deal_damage(ally, res.damage, enemy, enemy.element, res.crit)
