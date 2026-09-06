class_name JoanAbilities
extends RefCounted

const ID: String = "joan"
const MAX_ENERGY: float = 100.0

# Классификация атак Жоана:
# Basic: Одиночная атака
# Skill Q: Одиночная атака
# Skill E: Ослабление
# Ultimate: Одиночная атака
# FUA (Талант): Одиночная атака

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Жоан",
		"element": CombatConstants.Element.LIGHTNING, # Электрический
		"path": CombatConstants.Path.HUNT,           # Охота
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2750,
			"atk": 1380,
			"def": 780,
			"spd": 107,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.10,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	unit.set_meta("joan_coffee_liqueur_stacks", 0)
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	unit.set_meta("faction_empyrean_member", true)

static func add_coffee_liqueur_stacks(unit: CombatUnit, count: int, bm: BattleManager) -> void:
	var current: int = int(unit.get_meta("joan_coffee_liqueur_stacks", 0))
	var new_stacks: int = int(clamp(current + count, 0, 2))
	unit.set_meta("joan_coffee_liqueur_stacks", new_stacks)
	bm.log_message("☕ Кофейный ликёр Жоана: %d/2 стаков." % new_stacks)
	bm.unit_updated.emit(unit)

# БАЗОВАЯ АТАКА (Одиночная атака — 100% СА)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.00, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	bm.apply_weakness_hit_and_delay(attacker, target, bm) # ИСПРАВЛЕНО (вместо ToughnessSystem)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()

# НАВЫК Q (Одиночная атака — 120% СА + Бонус-атака)
# === НАЙДИТЕ И ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В JOAN.GD ===
# НАВЫК Q (120% СА + мгновенная бонус-атака Таланта)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 1.20, 0.0, false, 0.0, 0.0, false, true, "Skill")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Skill")
	bm.apply_weakness_hit_and_delay(attacker, target, bm, 1.0)
	
	bm.log_message("⚡ Навык Q: Жоан совершает выстрел и провоцирует Бонус-атаку по цели!")
	
	# ИСПРАВЛЕНО: Изменено на false. Теперь бонус-атака из Навыка Q списывает стак ликёра
	trigger_talent_fua(attacker, target, bm, false) 
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	bm.action_order_changed.emit()

# НАВЫК E (Ослабление — Трата 20% ХП, продвижение врага на 100% и наложение дебаффа "Не промахнись")
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var damage_amt: float = attacker.stats.max_hp * 0.20
	attacker.stats.hp = maxf(attacker.stats.hp - damage_amt, 1.0)
	bm.unit_updated.emit(attacker)
	bm.trigger_accepted_sin_hp_loss(attacker)
	
	target.advance_action(100.0)
	
	var living_enemies := bm.get_living_enemies()
	var vuln_pct: float = 0.20
	if living_enemies.size() <= 1:
		vuln_pct = 0.50
		bm.log_message("🎯 На поле боя только 1 противник! «Не промахнись» дает +50%% получаемого урона.")
	else:
		bm.log_message("🎯 На поле боя несколько противников. «Не промахнись» дает +20%% получаемого урона.")
		
	target.set_meta("joan_dont_miss_vuln", vuln_pct)
	target.set_meta("joan_dont_miss_turns", 2)
	target.set_meta("joan_dont_miss_skip_tick", true)
	
	bm.gain_energy_with_err(attacker, 30.0)
	bm.action_order_changed.emit()

# СВЕРХСПОСОБНОСТЬ (Одиночная атака — 200% СА, получение 1 стака Ликёра)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 2.00, 0.0, false, 0.0, 0.0, true, true, "Ultimate")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Ultimate")
	bm.apply_weakness_hit_and_delay(attacker, target, bm, 2.0) # ИСПРАВЛЕНО (вместо ToughnessSystem)
	
	add_coffee_liqueur_stacks(attacker, 1, bm)
	
	var marina := bm.get_marina_unit()
	if marina and marina.is_alive():
		bm.gain_energy_with_err(marina, 20.0)
		bm.log_message("❄ След 1 Жоана: Марине восстановлено 20 единиц энергии!")
		
	bm.gain_energy_with_err(attacker, 5.0)

# БОНУС-АТАКА (Одиночная атака — 110% СА)
static func trigger_talent_fua(unit: CombatUnit, target: CombatUnit, bm: BattleManager, force: bool = false) -> void:
	if target == null or not target.is_alive():
		return
		
	var stacks := int(unit.get_meta("joan_coffee_liqueur_stacks", 0))
	if not force and stacks <= 0:
		return
		
	if not force:
		unit.set_meta("joan_coffee_liqueur_stacks", stacks - 1)
		bm.log_message("☕ Жоан тратит 1 заряд ликёра! Остаток: %d/2" % (stacks - 1))
		
	bm.advance_fua_sequence()
	bm.log_message("💥 Жоан проводит БОНУС-АТАКУ по %s!" % target.display_name)
	
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")
		
	var res := bm.calc_dmg(unit, target, 0.70, 0.0, false, 0.0, 0.0, false, true, "Бонус-атака")
	bm.deal_damage(target, res.damage, unit, unit.element, res.crit, "Бонус-атака")
	bm.apply_weakness_hit_and_delay(unit, target, bm, 0.5) # ИСПРАВЛЕНО: Множитель стойкости снижен до 0.5x
	
	if unit.eidolon >= 6:
		bm.gain_energy_with_err(unit, 5.0)
		bm.log_message("⚡ Эйдолон 6 Жоана: Получено +5 энергии за Бонус-атаку.")
		
	if bm.has_meta("lenskaya_fua_attacker_credited"):
		bm.remove_meta("lenskaya_fua_attacker_credited")

static func trigger_death_trace(unit: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("⚡ СЛЕД 3 ЖОАНА: Жоан погиб! Нанесение Мнимого урона всем противникам!")
	var living := bm.get_living_enemies()
	for enemy in living:
		if enemy.is_alive():
			var res := bm.calc_dmg(unit, enemy, 1.00, 0.0, false, 0.0, 0.0, false, false, "Trace3")
			bm.deal_damage(enemy, res.damage, unit, CombatConstants.Element.IMAGINARY, res.crit, "Trace3")
