class_name MarinaAbilities
extends RefCounted

const ID := "marina"

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Марина",
		"element": CombatConstants.Element.ICE,
		"path": CombatConstants.Path.ERUDITION,
		"is_ally": true,
		"eidolon": eidolon,
		"stats": {
			"hp": 3200,
			"atk": 1900,
			"def": 750,
			"spd": 102,
			"crit_rate": 0.15,
			"crit_dmg": 0.80,
			"effect_hit_rate": 0.28,
			"break_effect": 0.30,
			"damage_bonus": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit, allies: Array) -> void:
	# Trace 1: +20% от крит. шанса союзника с наибольшим показателем
	var best_crit := 0.0
	for ally in allies:
		if ally is CombatUnit and ally != unit and ally.is_alive():
			best_crit = maxf(best_crit, ally.stats.crit_rate)
	unit.stats.crit_rate += best_crit * 0.20

static func get_skill_multiplier(eidolon: int, _high_hp: bool) -> float:
	var mult := 1.10
	if eidolon >= 3:
		mult *= 1.20
	if eidolon >= 6:
		mult = 1.60
	return mult
	
static func get_basic_multiplier(eidolon: int) -> float:
	var mult := 0.80
	if eidolon >= 3:
		mult *= 1.20
	return mult

static func get_ult_multiplier(eidolon: int, enemy_count: int, target_is_elite: bool) -> float:
	var mult := 1.80
	if eidolon >= 5:
		mult *= 1.20
	if enemy_count > 3:
		mult *= 1.10
	if eidolon >= 2 and target_is_elite:
		mult += 1.80
	return mult

static func apply_e4_speed_bonus(unit: CombatUnit, enemies: Array) -> void:
	if unit.eidolon < 4:
		return
	var total_stacks := 0
	for enemy in enemies:
		if enemy is CombatUnit and enemy.is_alive():
			total_stacks += enemy.statuses.suppression_stacks
	var bonus_spd := mini(total_stacks * 2, 30)
	var base_spd: float = unit.get_meta("base_spd", unit.stats.spd)
	if not unit.has_meta("base_spd"):
		unit.set_meta("base_spd", base_spd)
	var old_spd := unit.stats.get_effective_spd()
	unit.stats.spd = base_spd + bonus_spd
	unit._base_spd = unit.stats.spd
	var new_spd := unit.stats.get_effective_spd()
	if absf(old_spd - new_spd) > 0.01:
		unit.on_speed_changed(old_spd, new_spd)
	unit.recalculate_action_value()

static func apply_suppression(
	target: CombatUnit,
	stacks_to_add: int,
	duration_turns: int,
	is_dot: bool = false,
	source: String = "Марина",
) -> void:
	var before := target.statuses.suppression_stacks
	# ИСПРАВЛЕНО: Без Е1 (is_dot == false) лимит равен 1. Складываться Подавление больше не может.
	var max_stacks := 5 if is_dot else 1
	target.statuses.suppression_stacks = mini(
		target.statuses.suppression_stacks + stacks_to_add,
		max_stacks,
	)
	target.statuses.suppression_turns = maxi(target.statuses.suppression_turns, duration_turns)
	target.statuses.suppression_source = source
	if is_dot:
		target.statuses.suppression_is_dot = true
	_recalc_suppression_debuffs(target, before)
	

static func refresh_suppression_all(enemies: Array, duration_turns: int = 2, source: String = "Марина") -> void:
	for enemy in enemies:
		if enemy is CombatUnit and enemy.is_alive():
			apply_suppression(enemy, 0, duration_turns, false, source)
			enemy.statuses.dot_pending_marina_proc = true

static func recalc_suppression(target: CombatUnit) -> void:
	_recalc_suppression_debuffs(target, 0)

static func _recalc_suppression_debuffs(target: CombatUnit, _old_stacks: int) -> void:
	var old_spd := target.stats.get_effective_spd()
	target.stats.clear_spd_debuffs()
	target.stats.clear_ehr_debuffs()
	var stacks := target.statuses.suppression_stacks
	for _i in stacks:
		target.stats.add_spd_debuff(0.08) # -8% скорости за уровень
		target.stats.add_ehr_debuff(0.10) # -10% ШПЭ за уровень
	var new_spd := target.stats.get_effective_spd()
	target.base_action_value = CombatConstants.AV_BASE / new_spd
	if absf(old_spd - new_spd) > 0.01:
		target.on_speed_changed(old_spd, new_spd)
		
static func tick_suppression_turn(target: CombatUnit) -> void:
	if target.statuses.suppression_turns <= 0:
		return
	target.statuses.suppression_turns -= 1
	if target.statuses.suppression_turns <= 0:
		var before := target.statuses.suppression_stacks
		target.statuses.suppression_stacks = 0
		target.statuses.suppression_is_dot = false
		target.statuses.suppression_source = ""
		_recalc_suppression_debuffs(target, before)


static func apply_technique(enemies: Array, initiator: CombatUnit) -> void:
	for enemy in enemies:
		if enemy is CombatUnit:
			enemy.delay_action(50.0)
