class_name Insurgent
extends RefCounted

const ID: String = "insurgent"

static func create_unit(slot_idx: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Восставший",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 225000.0,
			"atk": 1900.0,
			"def": 850.0,
			"spd": 94.0,
			"crit_rate": 0.12,
			"crit_dmg": 0.70,
			"effect_res": 0.25,
		},
		"toughness": 240.0,
		"weaknesses": [
			CombatConstants.Element.IMAGINARY,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.QUANTUM,
		],
	})
	unit.slot_index = slot_idx
	unit.set_meta("base_hp_original", 225000.0)
	unit.set_meta("base_atk_original", 1900.0)
	unit.set_meta("base_def_original", 850.0)
	unit.set_meta("base_spd_original", 94.0)
	unit.set_meta("turn_count", 0)
	unit.set_meta("is_preparing_riot", false)
	# Пассивная стойкость мятежника: пока стойкость цела, получает на 20% меньше урона
	unit.set_meta("dmg_reduction", 0.20)
	return unit

static func pick_target(allies: Array) -> CombatUnit:
	# Провокация Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

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

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	# 1. Если был в стойке подготовки «Неумолимый бунт» и не был пробит
	if bool(enemy.get_meta("is_preparing_riot", false)):
		enemy.set_meta("is_preparing_riot", false)
		_execute_flame_of_revolution(enemy, allies, bm)
		return

	# 2. Каждые 3 хода входит в подготовку к бунту
	if turn % 3 == 0 and not enemy.statuses.toughness_broken:
		_start_preparing_riot(enemy, bm)
		return

	# 3. Чередование: четные ходы — «Дробящий заряд» (Blast), нечетные — «Революционный выпад» (Single Target)
	if turn % 2 == 0:
		_execute_crushing_charge(enemy, allies, bm)
	else:
		_execute_revolutionary_strike(enemy, allies, bm)

# Способность 1: Революционный выпад (Single Target, 110% СА)
static func _execute_revolutionary_strike(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("⚔ %s наносит «Революционный выпад» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.10)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 2: Дробящий заряд (Blast, 90% основной / 45% смежным)
static func _execute_crushing_charge(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("⚔ %s обрушивает «Дробящий заряд» на %s и смежные цели!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 0.90)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.45)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Подготовка к сокрушительной атаке
static func _start_preparing_riot(enemy: CombatUnit, bm: BattleManager) -> void:
	enemy.set_meta("is_preparing_riot", true)
	bm.log_message("🔥 %s концентрирует ярость: «Подготовка к восстанию»! Пробейте уязвимость, чтобы сорвать атаку!" % enemy.display_name)
	bm.unit_updated.emit(enemy)

# Сокрушительная атака после подготовки: Пламя революции (AoE 160% СА)
static func _execute_flame_of_revolution(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("💥 %s завершил подготовку и обрушивает «Пламя революции» по всему отряду!" % enemy.display_name)
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, a, 1.60)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Тактика Пробития: Реакция на пробитие стойкости (Weakness Break)
static func on_weakness_break(enemy: CombatUnit, bm: BattleManager) -> void:
	# Снимаем снижение урона
	enemy.set_meta("dmg_reduction", 0.0)

	var was_preparing: bool = bool(enemy.get_meta("is_preparing_riot", false))
	if was_preparing:
		enemy.set_meta("is_preparing_riot", false)
		bm.log_message("🛡 Стойкость %s сокрушена! «Подготовка к восстанию» сорвана!" % enemy.display_name)
	else:
		bm.log_message("🛡 Стойкость %s сокрушена!" % enemy.display_name)

	# Задерживаем ход на 40%
	enemy.delay_action(40.0)
	bm.log_message("  ⏳ Действие %s задержано на 40%%!" % enemy.display_name)

	# Накладываем статус «Сломленный дух»: +100% урона от пробития и суперпробития, -20% защиты
	enemy.set_meta("insurgent_broken_spirit", true)
	enemy.set_meta("insurgent_extra_break_vuln", 1.0)
	var reductions: Dictionary = enemy.get_meta("def_reductions", {}).duplicate()
	reductions["broken_spirit"] = {"percent": 0.20, "turns": 2}
	enemy.set_meta("def_reductions", reductions)
	bm.log_message("  💔 %s получает статус «Сломленный дух»: защита -20%%, получаемый урон от Пробития и Суперпробития +100%%!" % enemy.display_name)

	bm.action_order_changed.emit()
	bm.unit_updated.emit(enemy)
