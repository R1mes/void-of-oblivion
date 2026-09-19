class_name VoidPaws
extends RefCounted

const ID: String = "void_paws"

static func create_unit(slot_idx: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Лапа Ничто",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 45000,
			"atk": 950,
			"def": 750,
			"spd": 98,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_res": 0.15,
		},
		"toughness": 60,
		"weaknesses": [
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.ICE,
			CombatConstants.Element.PHYSICAL,
		],
	})
	unit.slot_index = slot_idx
	unit.set_meta("base_hp_original", 45000.0)
	unit.set_meta("base_atk_original", 950.0)
	unit.set_meta("base_def_original", 750.0)
	unit.set_meta("base_spd_original", 98.0)
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

	# Атака случайного союзника
	var res := DamageCalculator.calc_damage(enemy, target, 0.75)
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))
	
	# Высасывание 15 единиц энергии (снижается на 5 за каждые 20 Зеро)
	var zero: int = bm.get_xaeroh()
	var reduction_steps: int = int(floor(float(zero) / 20.0))
	var drain_amt: float = maxf(0.0, 15.0 - float(reduction_steps) * 5.0)
	
	if drain_amt > 0.0:
		target.energy = maxf(0.0, target.energy - drain_amt)
		bm.log_message("🐾 %s атакует %s на %d урона и поглощает %.0f энергии (Зеро команды: %d -> срез поглощения на %.0f)!" % [
			enemy.display_name, target.display_name, int(dmg), drain_amt, zero, float(reduction_steps) * 5.0
		])
		bm.unit_updated.emit(target)
	else:
		bm.log_message("🐾 %s атакует %s на %d урона. Высокая плотность Зеро (%d) полностью блокирует поглощение энергии!" % [
			enemy.display_name, target.display_name, int(dmg), zero
		])
