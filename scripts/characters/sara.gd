class_name SaraAbilities
extends RefCounted

const ID := "sara"
const MAX_ENERGY := 140.0
const ARYA_DURATION_AV := 80.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Сара",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.ABUNDANCE,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3600,
			"atk": 980,
			"def": 720,
			"spd": 98,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_resist": 0.30,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	unit.set_meta("heal_bonus_flat", unit.stats.max_hp * 0.00005)
	unit.set_meta("control_resist_bonus", 0.35)
	unit.set_meta("trace3_patch_bonus", true)

static func get_heal_amount(sara: CombatUnit, percent: float, flat: float = 0.0) -> float:
	var bonus: float = sara.get_meta("heal_bonus_flat", 0.0)
	var base := sara.stats.max_hp * percent + flat
	return base * (1.0 + bonus)

static func apply_patch(target: CombatUnit, sara: CombatUnit, turns: int) -> void:
	target.statuses.patch_turns = maxi(target.statuses.patch_turns, turns)
	target.statuses.patch_source = sara.display_name
	if sara.eidolon >= 2:
		target.statuses.effect_resist_bonus = 0.15
		target.statuses.effect_resist_bonus_source = sara.display_name

static func heal_ally(sara: CombatUnit, target: CombatUnit, percent: float, flat: float, battle: BattleManager) -> float:
	var amount := get_heal_amount(sara, percent, flat)
	amount *= 1.0 + target.statuses.incoming_heal_bonus
	var healed: float = battle.heal_unit(target, amount)
	battle.log_message(
		"%s лечит %s: +%d ХП" % [sara.display_name, target.display_name, int(healed)],
	)
	return healed

static func execute_basic(attacker: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	var result := battle.calc_dmg(attacker, target, 0.55)
	battle.deal_damage(target, result.damage, attacker)
	ToughnessSystem.apply_weakness_hit(attacker, target, battle)
	ToughnessSystem.on_hit_entanglement(target)
	battle.gain_skill_point()
	attacker.gain_energy(20)
	battle.log_message(
		"%s — базовая атака по %s: %d%s" % [
			attacker.display_name,
			target.display_name,
			int(result.damage),
			" (КРИТ!)" if result.crit else "",
		],
	)
	if attacker.eidolon >= 1:
		var self_heal := attacker.stats.max_hp * 0.10
		battle.heal_unit(attacker, self_heal)
		battle.log_message("Э1: Сара восстанавливает %d ХП" % int(self_heal))

static func execute_skill_q(sara: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	heal_ally(sara, target, 0.20, 200.0, battle)
	apply_patch(target, sara, 2)
	battle.log_message("Навык Q: «Заплатка» на %s (2 хода)" % target.display_name)
	sara.gain_energy(30)
	battle.unit_updated.emit(target)

static func execute_skill_e(sara: CombatUnit, target: CombatUnit, battle: BattleManager) -> void:
	if target.statuses.cleanse_one():
		battle.log_message("Навык E: снято 1 ослабление с %s" % target.display_name)
		MarinaAbilities.recalc_suppression(target)
	target.statuses.incoming_heal_bonus = 0.20
	target.statuses.incoming_heal_bonus_source = sara.display_name
	target.advance_action(30.0)
	apply_patch(target, sara, 2)
	battle.log_message(
		"Навык E: +20% к лечению, ускорение 30%%, «Заплатка» на %s" % target.display_name,
	)
	sara.gain_energy(25)
	battle.action_order_changed.emit()
	battle.unit_updated.emit(target)

static func execute_ultimate(sara: CombatUnit, battle: BattleManager) -> void:
	battle.start_arya(ARYA_DURATION_AV)
	battle.log_message("Сверхспособность: «Аря» активирована (%d ИД)" % int(ARYA_DURATION_AV))

static func end_arya(sara: CombatUnit, battle: BattleManager) -> void:
	battle.log_message("«Аря» завершилась")
	var patch_turns := 1
	if sara.has_meta("trace3_patch_bonus"):
		patch_turns += 1

	for ally in battle.allies:
		if not ally.is_alive():
			continue
		heal_ally(sara, ally, 0.15, 0.0, battle)
		if ally.statuses.cleanse_one():
			battle.log_message("Снято 1 ослабление с %s" % ally.display_name)
		apply_patch(ally, sara, patch_turns)
		battle.unit_updated.emit(ally)

	if sara.eidolon >= 6:
		for ally in battle.allies:
			if ally.is_alive():
				ally.statuses.cleanse_all()
		battle.log_message("Э6: все ослабления сняты с союзников")

static func on_ally_turn_start(ally: CombatUnit, battle: BattleManager) -> void:
	if ally.statuses.patch_turns <= 0:
		return
	var sara := battle.get_sara_unit()
	if sara == null:
		return
	heal_ally(sara, ally, 0.08, 0.0, battle)
	ally.statuses.patch_turns -= 1
	if ally.statuses.patch_turns <= 0:
		ally.statuses.incoming_heal_bonus = 0.0
		ally.statuses.incoming_heal_bonus_source = ""
		ally.statuses.effect_resist_bonus = 0.0
		ally.statuses.effect_resist_bonus_source = ""
		ally.statuses.patch_source = ""
	battle.unit_updated.emit(ally)

static func on_ally_damaged(ally: CombatUnit, damage: float, battle: BattleManager) -> void:
	if ally.statuses.patch_turns <= 0 or damage <= 0.0:
		return
	var sara := battle.get_sara_unit()
	if sara == null:
		return
	var heal_ratio := 0.30
	if sara.eidolon >= 2:
		heal_ratio = 0.40
	var heal_amount := damage * heal_ratio
	battle.heal_unit(ally, heal_amount)
	battle.log_message(
		"Заплатка: %s восстанавливает %d ХП от урона" % [ally.display_name, int(heal_amount)],
	)

static func try_e4_revive(target: CombatUnit, battle: BattleManager) -> bool:
	var sara := battle.get_sara_unit()
	if sara == null or sara.eidolon < 4 or battle.sara_e4_used:
		return false
	battle.sara_e4_used = true
	target.stats.hp = target.stats.max_hp * 0.20
	target.hp_changed.emit(target)
	battle.log_message(
		"Э4: %s избегает смерти и восстанавливает 20%% ХП!" % target.display_name,
	)
	return true

static func apply_technique_to_team(allies: Array, battle: BattleManager) -> void:
	for ally in allies:
		if not ally.is_alive():
			continue
		var healed: float = ally.heal(ally.stats.max_hp * 0.20)
		battle.log_message(
			"Техника Сары: %s +%d ХП" % [ally.display_name, int(healed)],
		)
	var sara := battle.get_sara_unit()
	if sara:
		for ally in allies:
			if ally.is_alive():
				apply_patch(ally, sara, 1)
		battle.log_message("Техника Сары: «Заплатка» на всех союзниках (1 ход)")
