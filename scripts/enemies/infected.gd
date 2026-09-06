class_name Infected
extends RefCounted

const ID: String = "infected"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Заражённый",
		"element": CombatConstants.Element.WIND,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 49500,
			"atk": 1500,
			"def": 600,
			"spd": 96,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.10,
		},
		"toughness": 90,
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.WIND,
		],
	})
	unit.set_meta("turn_count", 0)
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
	var target := pick_target(allies)
	if target == null:
		return

	var is_critical := (enemy.stats.hp / enemy.stats.max_hp) < 0.30
	if is_critical:
		bm.log_message("☣ %s пульсирует нестабильной заразой и готовится к детонации!" % enemy.display_name)

	bm.log_message("☣ %s атакует «Инфекционным укусом» по %s!" % [enemy.display_name, target.display_name])
	var res: Dictionary = bm.calc_dmg(enemy, target, 0.95)
	# Если у цели до атаки не было щита — накладывает Выветривание
	var had_shield := float(target.get_meta("shield_value", 0.0)) > 0.0
	bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, enemy.element, bool(res.get("crit", false)))

	if not had_shield:
		target.statuses.break_status = "Выветривание"
		target.statuses.break_status_turns = 2
		target.statuses.break_status_source = enemy.display_name
		bm.log_message("  → %s получил статус Выветривание на 2 хода!" % target.display_name)
