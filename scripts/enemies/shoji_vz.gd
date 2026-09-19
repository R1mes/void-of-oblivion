class_name ShojiVz
extends RefCounted

const ID: String = "shoji_vz"
const SUMMON_INTERVAL: int = 3
const ULT_INTERVAL: int = 4

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сёдзи: Воплощение Зависти",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.NIHILITY,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 240000, # Фаза 1: 240 000
			"atk": 2250,  # Прежняя атака (2500) уменьшена на 250
			"def": 1000,
			"spd": 105,
			"crit_rate": 0.15,
			"crit_dmg": 0.60,
			"effect_res": 0.30,
		},
		"toughness": 360,
		"weaknesses": [
			CombatConstants.Element.WIND,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.FIRE,
		],
	})
	unit.set_meta("base_hp_original", 240000.0)
	unit.set_meta("base_atk_original", 2250.0)
	unit.set_meta("base_def_original", 1000.0)
	unit.set_meta("base_spd_original", 105.0)
	unit.set_meta("phase", 1)
	unit.set_meta("turn_count", 0)
	unit.set_meta("turn_p2_count", 0)
	return unit

static func pick_target(allies: Array) -> CombatUnit:
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
	var phase := int(enemy.get_meta("phase", 1))
	if phase == 1:
		_execute_phase_1(enemy, allies, bm)
	else:
		_execute_phase_2(enemy, allies, bm)

# --- ФАЗА 1 ---
static func _execute_phase_1(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	_update_firewall_status(enemy, bm)

	if turn % 3 == 1:
		_execute_viral_penetration(enemy, allies, bm)
	elif turn % 3 == 2:
		_execute_protocol_inversion(enemy, allies, bm)
	else:
		_execute_stream_pulse(enemy, allies, bm)

# --- ФАЗА 2 ---
static func _execute_phase_2(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_p2_count", 0)) + 1
	enemy.set_meta("turn_p2_count", turn)

	_update_firewall_status(enemy, bm)
	_update_phase2_dot_vulnerability(enemy, bm)

	if turn == 1:
		_execute_summon_cleaners(enemy, bm)
		_execute_stream_pulse(enemy, allies, bm)
	elif turn % ULT_INTERVAL == 0:
		_execute_cascade_failure_ult(enemy, allies, bm)
	elif turn % 3 == 1:
		_execute_terminal_overload(enemy, allies, bm)
	elif turn % 3 == 2:
		_execute_viral_penetration(enemy, allies, bm)
	else:
		_execute_stream_pulse(enemy, allies, bm)

# Проверка Брандмауэра Цитадели: пока живы Чистильщики, прямой урон снижен на 40%
static func _update_firewall_status(enemy: CombatUnit, bm: BattleManager) -> void:
	var cleaners_alive: int = 0
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive() and e.id == "citadel_cleaner":
			cleaners_alive += 1
	if cleaners_alive > 0:
		enemy.set_meta("shoji_vz_firewall_active", true)
		bm.log_message("🛡 «Брандмауэр Цитадели» активен (%d Чистильщиков)! Прямой урон по %s снижен на 40%% (DoT-урон наносит 100%%)!" % [cleaners_alive, enemy.display_name])
	else:
		enemy.set_meta("shoji_vz_firewall_active", false)

# Фаза 2: Пассивная уязвимость к Бинарному и DoT урону за каждый DoT (+5% за каждый, до 30%)
static func _update_phase2_dot_vulnerability(enemy: CombatUnit, bm: BattleManager) -> void:
	var dots_count := bm.get_active_dots_count(enemy)
	# Дополнительно учитываем стаки Кровотечения от Взломанных Чистильщиков
	var bleed_stacks: int = int(enemy.get_meta("hacked_bleed_stacks", 0))
	var total_dots := dots_count + bleed_stacks
	var bonus_vuln: float = minf(float(total_dots) * 0.05, 0.30)
	enemy.set_meta("shoji_vz_p2_dot_vuln", bonus_vuln)
	if bonus_vuln > 0.0:
		bm.log_message("🌐 «Уязвимость ядра»: На %s действует %d DoT-эффектов! Получаемый Бинарный и DoT урон увеличен на +%d%% (макс 30%%)." % [enemy.display_name, total_dots, int(bonus_vuln * 100.0)])

# Призыв 2 Взломанных Чистильщиков Цитадели
static func _execute_summon_cleaners(enemy: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("⚙ %s: «Авторизация протокола Цитадели» — призыв Взломанных Чистильщиков!" % enemy.display_name)

	# Сначала удаляем мёртвых врагов для очистки слотов и карточек
	var to_remove: Array[CombatUnit] = []
	for e in bm.enemies:
		if e is CombatUnit and not e.is_alive():
			to_remove.append(e)
	for dead_e in to_remove:
		bm.enemies.erase(dead_e)

	var occupied_slots: Array[int] = []
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive():
			occupied_slots.append(e.slot_index)

	var living_count := occupied_slots.size()
	var spawn_limit := mini(2, 5 - living_count)
	if spawn_limit <= 0:
		if not to_remove.is_empty():
			bm.enemies_reshuffled.emit()
			bm.action_order_changed.emit()
		return

	var spawned := 0
	for s in range(5):
		if spawned >= spawn_limit:
			break
		if not s in occupied_slots:
			var cleaner := CitadelCleaner.create_unit(s, true)
			cleaner.recalculate_action_value()
			cleaner.action_value = cleaner.base_action_value
			bm.enemies.append(cleaner)
			occupied_slots.append(s)
			spawned += 1
			bm.log_message("🤖 На поле боя подключён %s в слоте %d!" % [cleaner.display_name, s + 1])

	if spawned > 0:
		_update_firewall_status(enemy, bm)
	if spawned > 0 or not to_remove.is_empty():
		bm.enemies_reshuffled.emit()
		bm.action_order_changed.emit()

# Атака 1: Потоковый импульс (Blast: 120% цели, 60% соседям)
static func _execute_stream_pulse(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("📡 %s: «Потоковый импульс» по %s!" % [enemy.display_name, target.display_name])
	var res_main: Dictionary = bm.calc_dmg(enemy, target, 1.20)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.60)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Атака 2: Вирусное проникновение (Single Target 180% + DoT 80% на 2 хода)
static func _execute_viral_penetration(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("👾 %s: «Вирусное проникновение» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.80)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

	target.set_meta("shoji_vz_viral_burn_turns", 2)
	target.set_meta("shoji_vz_viral_burn_atk", enemy.stats.atk * 0.80)
	bm.log_message("  → На %s наложен «Вирусный ожог» на 2 хода!" % target.display_name)

# Атака 3: Инверсия протокола (2 случайных цели по 100% + задержка хода 15%)
static func _execute_protocol_inversion(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			living.append(a)
	if living.is_empty():
		return

	bm.log_message("🔄 %s: «Инверсия протокола» по системам отряда!" % enemy.display_name)
	living.shuffle()
	var targets_count := mini(2, living.size())
	for i in targets_count:
		var t: CombatUnit = living[i]
		var res: Dictionary = bm.calc_dmg(enemy, t, 1.00)
		bm.deal_damage(t, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))
		t.delay_action(15.0)
		bm.log_message("  → %s получает урон и задерживается на 15%%!" % t.display_name)
	bm.action_order_changed.emit()

# Атака 4 (Фаза 2): Перегрузка терминала (Blast 140% / 70% + бонус против ослабленных)
static func _execute_terminal_overload(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("⚡ %s: «Перегрузка терминала» по %s!" % [enemy.display_name, target.display_name])
	var mult: float = 1.40
	if target.has_meta("shoji_vz_viral_burn_turns") or target.statuses.break_status != "":
		mult += 0.40 # +40% урона по ослабленным
		bm.log_message("  ⚠ Цель ослаблена: урон увеличен на +40%%!")

	var res_main: Dictionary = bm.calc_dmg(enemy, target, mult)
	bm.deal_damage(target, float(res_main.get("damage", 0.0)), enemy, enemy.element, bool(res_main.get("crit", false)))

	var adj := bm.get_adjacent_allies(target)
	for neighbor in adj:
		if neighbor.is_alive():
			var res_adj: Dictionary = bm.calc_dmg(enemy, neighbor, 0.70)
			bm.deal_damage(neighbor, float(res_adj.get("damage", 0.0)), enemy, enemy.element, bool(res_adj.get("crit", false)))

# Сверхспособность (Фаза 2): Каскадный сбой (AoE урон, снижается на 10% за стак Кровотечения)
static func _execute_cascade_failure_ult(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var bleed_stacks: int = int(enemy.get_meta("hacked_bleed_stacks", 0))
	var dmg_reduction_pct: float = minf(float(bleed_stacks) * 0.10, 0.50)
	var final_mult: float = maxf(1.50 * (1.0 - dmg_reduction_pct), 0.75)

	bm.log_message("💥💥 %s активирует «Каскадный сбой системы»!" % enemy.display_name)
	if dmg_reduction_pct > 0.0:
		bm.log_message("  🩸 Кровотечение на боссе (%d стаков) сбило калибровку: урон ульты снижен на %d%%!" % [bleed_stacks, int(dmg_reduction_pct * 100.0)])

	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, ally, final_mult)
			bm.deal_damage(ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))
