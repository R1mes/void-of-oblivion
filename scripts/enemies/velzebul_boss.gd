class_name VelzebulBoss
extends RefCounted

const ID: String = "velzebul_boss"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Вельзевул",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 320000, # Фаза 1: 320 000
			"atk": 2300,
			"def": 950,
			"spd": 104,
			"crit_rate": 0.0,
			"crit_dmg": 0.65,
			"effect_res": 0.35,
		},
		"toughness": 360,
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.WIND,
			CombatConstants.Element.QUANTUM,
		],
	})
	unit.set_meta("base_hp_original", 320000.0)
	unit.set_meta("base_atk_original", 2300.0)
	unit.set_meta("base_def_original", 950.0)
	unit.set_meta("base_spd_original", 104.0)
	unit.set_meta("phase", 1)
	unit.set_meta("turn_count", 0)
	unit.set_meta("turn_p2_count", 0)
	unit.set_meta("ice_res_bonus", 0.40)
	unit.set_meta("self_dmg_80_done", false)
	unit.set_meta("self_dmg_50_done", false)
	return unit

static func pick_target(allies: Array, prioritize_highest_atk: bool = false) -> CombatUnit:
	# 1. Провокация Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

	# 2. Приоритет наивысшей СА (Катарина / Керри)
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

# Проверка порогов ХП (80% и 50%) для самоповреждения на 7% макс. ХП
static func check_self_damage_thresholds(boss: CombatUnit, was_hp_ratio: float, new_hp_ratio: float, bm: BattleManager) -> void:
	if not boss.is_alive():
		return

	# Рубеж 80%
	if was_hp_ratio >= 0.80 and new_hp_ratio <= 0.80 and not bool(boss.get_meta("self_dmg_80_done", false)):
		boss.set_meta("self_dmg_80_done", true)
		var self_dmg: float = boss.stats.max_hp * 0.07
		bm.log_message("💥 «Нестабильность Антиматерии»: ХП Вельзевул опустилось до 80%%! Внутренний коллапс наносит боссу %d чист. урона (7%% макс. ХП)!" % [int(self_dmg)])
		bm.deal_damage(boss, self_dmg, null, -1, false, "Нестабильность Антиматерии")

	# Рубеж 50%
	if was_hp_ratio >= 0.50 and new_hp_ratio <= 0.50 and not bool(boss.get_meta("self_dmg_50_done", false)):
		boss.set_meta("self_dmg_50_done", true)
		var self_dmg: float = boss.stats.max_hp * 0.07
		bm.log_message("💥 «Нестабильность Антиматерии»: ХП Вельзевул опустилось до 50%%! Внутренний коллапс наносит боссу %d чист. урона (7%% макс. ХП)!" % [int(self_dmg)])
		bm.deal_damage(boss, self_dmg, null, -1, false, "Нестабильность Антиматерии")

# Проверка Панциря Антиматерии (-25% урона, если нет срезки физ. сопра)
static func is_antimatter_shell_active(boss: CombatUnit) -> bool:
	var has_phys_shred: bool = boss.has_meta("katarina_phys_res_reduction") or boss.has_meta("katarina_all_res_reduction") or boss.has_meta("phys_res_reduced_turns")
	return not has_phys_shred

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

	if is_antimatter_shell_active(enemy):
		bm.log_message("🛡 «Панцирь Антиматерии» Вельзевул активен: входящий урон снижен на 25%% (снимается физ. срезкой Катарины)!")

	if turn % 3 == 1:
		_execute_decay_seal(enemy, allies, bm)
	elif turn % 3 == 2:
		_execute_putrid_cleave(enemy, allies, bm)
	else:
		_execute_abyss_breath(enemy, allies, bm)

# --- ИИ ФАЗЫ 2 ---
static func _execute_phase_2(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_p2_count", 0)) + 1
	enemy.set_meta("turn_p2_count", turn)

	bm.log_message("👑 «Истинная Вельзевул — Владычица Мух» [Ход %d]: Ярость Бездны!" % turn)

	# Серия из двух действий за ход
	if turn % 3 == 1:
		_execute_antimatter_swarm(enemy, allies, bm)
		_execute_deadly_sting(enemy, allies, bm)
	elif turn % 3 == 2:
		_execute_decay_seal(enemy, allies, bm)
		_execute_putrid_cleave(enemy, allies, bm)
	else:
		_execute_abyss_breath(enemy, allies, bm)
		_execute_deadly_sting(enemy, allies, bm)

# Способность 1: Печать разложения / Сфокусированная кара (200% СА по топ-ДД)
static func _execute_decay_seal(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return
	bm.log_message("☠ %s: «Печать разложения» по главнейшей угрозе %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 2.00)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 2: Дыхание Бездны (AoE 80% СА всем)
static func _execute_abyss_breath(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("🌌 %s: «Дыхание Бездны» по всему отряду!" % enemy.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, ally, 0.80)
			bm.deal_damage(ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 3: Гнилостное расщепление (Blast: 115% цели, 55% соседям + срез DEF 15%)
static func _execute_putrid_cleave(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, false)
	if target == null:
		return
	bm.log_message("🩸 %s: «Гнилостное расщепление» по %s!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 1.15)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.55)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

	bm.apply_def_reduction(target, "Гнилостное расщепление", 0.15, 2)
	bm.log_message("  → Защита %s снижена на 15%% на 2 хода!" % target.display_name)

# Способность 4 (Фаза 2): Рой Антиматерии (AoE 80% СА)
static func _execute_antimatter_swarm(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("🌪 %s обрушивает «Рой Антиматерии»!" % enemy.display_name)
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, ally, 0.80)
			bm.deal_damage(ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# Способность 5 (Фаза 2): Смертоносное жало (Single Target 200% СА)
static func _execute_deadly_sting(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return
	bm.log_message("⚡ %s: «Смертоносное жало» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 2.00)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))
