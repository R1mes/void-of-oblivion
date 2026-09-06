class_name OrthoMutant
extends RefCounted

const ID: String = "ortho_mutant"
const SPORE_ID: String = "ortho_spore"
const SPORE_INTERVAL: int = 3

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Орто Мутант",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 116000,
			"atk": 2300,
			"def": 900,
			"spd": 102,
			"crit_rate": 0.10,
			"crit_dmg": 0.50,
			"effect_res": 0.20,
		},
		"toughness": 240,
		"weaknesses": [
			CombatConstants.Element.IMAGINARY,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.WIND,
		],
	})
	unit.set_meta("turn_count", 0)
	# Постоянный пассивный DoT (активирует След 3 Жоана на +50% Крит. урона)
	unit.set_meta("ortho_acid_dot_turns", 999)
	return unit

static func create_spore(slot_idx: int = 1) -> CombatUnit:
	var spore := CombatUnit.new()
	spore.setup_from_template({
		"id": SPORE_ID,
		"name": "Орто-спора",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 27000,
			"atk": 1200,
			"def": 600,
			"spd": 95,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.10,
		},
		"toughness": 60,
		"weaknesses": [
			CombatConstants.Element.IMAGINARY,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.WIND,
		],
	})
	spore.slot_index = slot_idx
	spore.set_meta("base_hp_original", 27000.0)
	spore.set_meta("base_atk_original", 1200.0)
	spore.set_meta("base_def_original", 600.0)
	spore.set_meta("base_spd_original", 95.0)
	return spore

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
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)

	if turn == 1 or turn % SPORE_INTERVAL == 0:
		_execute_spore_summon(enemy, allies, bm)
	else:
		_execute_biomass_growth(enemy, allies, bm)

# Способность 1: Выброс био-спор (АоЕ + Призыв спор)
static func _execute_spore_summon(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("☣ Орто Мутант: «Выброс био-спор»!")
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			var res: Dictionary = bm.calc_dmg(enemy, ally, 0.80)
			bm.deal_damage(ally, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

	# Удаляем мертвых врагов из массива перед спавном новых, чтобы освободить место для новых карточек
	var occupied_slots: Array[int] = []
	for e in bm.enemies:
		if e is CombatUnit and e.is_alive():
			occupied_slots.append(e.slot_index)

	var living_count := occupied_slots.size()
	var spawn_limit := mini(2, 5 - living_count)
	if spawn_limit <= 0:
		return

	# Если есть мёртвые враги, удаляем их из bm.enemies, чтобы освободить карточки на поле боя
	var to_remove: Array[CombatUnit] = []
	for e in bm.enemies:
		if e is CombatUnit and not e.is_alive():
			to_remove.append(e)
	for dead_e in to_remove:
		bm.enemies.erase(dead_e)

	var spawned := 0
	for s in range(5):
		if spawned >= spawn_limit:
			break
		if not s in occupied_slots:
			var spore := create_spore(s)
			spore.recalculate_action_value()
			spore.action_value = spore.base_action_value
			bm.enemies.append(spore)
			occupied_slots.append(s)
			spawned += 1
			bm.log_message("🌱 На поле боя прорастает %s в слоте %d!" % [spore.display_name, s + 1])

	if spawned > 0:
		bm.enemies_reshuffled.emit()
		bm.action_order_changed.emit()

# Способность 2: Разрастание биомассы (Single)
static func _execute_biomass_growth(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return

	bm.log_message("🧬 Орто Мутант: «Разрастание биомассы» по %s!" % target.display_name)
	var res: Dictionary = bm.calc_dmg(enemy, target, 1.50)
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

# ИИ для Орто-споры
static func execute_spore_turn(spore: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies)
	if target == null:
		return
	bm.log_message("🦠 %s атакует %s!" % [spore.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(spore, target, 0.60)
	bm.deal_damage(target, float(res.get("damage", 0.0)), spore, spore.element, bool(res.get("crit", false)))
