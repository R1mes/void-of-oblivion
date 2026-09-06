class_name DashaAdminAbilities
extends RefCounted

const ID: String = "dasha_admin"
const MAX_ENERGY: float = 210.0
const MAX_DIGITAL_FOOTPRINT: int = 30

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Даша • Права администратора",
		"element": CombatConstants.Element.IMAGINARY,
		"path": CombatConstants.Path.PRESERVATION,
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 3300,
			"atk": 1050,
			"def": 1420,
			"spd": 103,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.00,
			"weakness_efficiency": 0.00,
		},
	})
	
	unit.set_meta("dasha_digital_footprint", 0)
	unit.set_meta("dasha_vector_acc", 0)
	unit.set_meta("dasha_admin_e_unlocked", false)
	return unit

static func apply_traces(unit: CombatUnit, bm: BattleManager) -> void:
	unit.set_meta("faction_console_member", true)

static func add_digital_footprint(unit: CombatUnit, amount: int, bm: BattleManager) -> void:
	if unit == null or not unit.is_alive() or amount <= 0: return
	var cur: int = int(unit.get_meta("dasha_digital_footprint", 0))
	var new_val: int = mini(cur + amount, MAX_DIGITAL_FOOTPRINT)
	unit.set_meta("dasha_digital_footprint", new_val)
	bm.unit_updated.emit(unit)
	bm.log_message("🛡 Цифровой след Даши: %d/%d (+%d)." % [new_val, MAX_DIGITAL_FOOTPRINT, amount])

# --- СПОСОБНОСТИ ---

# 1. Базовая атака: 50% ЗАЩ мнимого урона. След 3: +2 Цифровых следа.
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var mult: float = 0.50 * (1.20 if attacker.eidolon >= 3 else 1.0)
	var res := bm.calc_dmg(attacker, target, mult, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, CombatConstants.Element.IMAGINARY, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	# След 3: +2 Цифровых следа
	add_digital_footprint(attacker, 2, bm)
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()

# 2. Навык Q: Сброс следов до 0. Если было ровно 30 — хил пати на 20% ЗАЩ.
static func execute_skill_q(attacker: CombatUnit, bm: BattleManager) -> void:
	var footprint: int = int(attacker.get_meta("dasha_digital_footprint", 0))
	
	# ИСПРАВЛЕНО: При трате 30+ следов возвращаем 1 ОН
	if footprint >= 30:
		bm.gain_skill_point()
		
	attacker.set_meta("dasha_digital_footprint", 0)
	
	bm.log_message("💻 Навык Q Даши: Цифровой след сброшен до 0 (было стаков: %d)." % footprint)
	
	if footprint == 30:
		var def_val := bm.get_effective_def_complete(attacker)
		var heal_mult: float = 0.20 * (1.20 if attacker.eidolon >= 3 else 1.0)
		var heal_amt := def_val * heal_mult
		for ally in bm.allies:
			if ally.is_alive():
				bm.heal_unit(ally, heal_amt)
		bm.log_message("✨ Максимальный Цифровой след (30)! Отряд исцелен на %d ХП (20%% ЗАЩ Даши)." % int(heal_amt))
		
		# Е6: Если потрачено 30 следов, Бинарный урон пати +30% на 2 хода
		if attacker.eidolon >= 6:
			for ally in bm.allies:
				if ally.is_alive():
					ally.set_meta("dasha_e6_binary_turns", 2)
					ally.set_meta("dasha_e6_binary_skip_tick", ally == attacker)
			bm.log_message("⚡ Е6 Даши: Потрачено 30 следов! Бинарный урон отряда повышен на +30%% на 2 хода.")
			
	bm.gain_energy_with_err(attacker, 20.0)
	bm.unit_updated.emit(attacker)

# 3. Навык E (2 ОН): 60% ЗАЩ Бинарный АоЕ урон + щит 20% ЗАЩ + 150 на 3 хода.
static func execute_skill_e(attacker: CombatUnit, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	attacker.set_meta("is_binary_attack", true)
	if attacker.eidolon >= 2:
		attacker.set_meta("dasha_e2_binary_boost", true)
		
	var mult: float = 0.60 * (0.90 if attacker.eidolon >= 3 else 1.0)
	
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, false, true, "Binary")
		bm.deal_damage(enemy, res.damage, attacker, CombatConstants.Element.IMAGINARY, res.crit, "Binary")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
	attacker.remove_meta("is_binary_attack")
	if attacker.has_meta("dasha_e2_binary_boost"):
		attacker.remove_meta("dasha_e2_binary_boost")
	
	# Наложение щита (20% ЗАЩ + 150), умноженное на бонус Таланта (+3% за каждый Цифровой след)
	var def_val := bm.get_effective_def_complete(attacker)
	var base_shield := def_val * 0.20 + 150.0
	var footprint := int(attacker.get_meta("dasha_digital_footprint", 0))
	var talent_multiplier := 1.0 + (float(footprint) * 0.03)
	var final_shield := base_shield * talent_multiplier
	
	for ally in bm.allies:
		if ally.is_alive():
			bm.apply_shield(ally, final_shield, 3, "Щит Даши • Админ")
			
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)

# 4. Сверхспособность (210 ЭН): Обновление щитов до 3 ходов + Бинарный урон пати +50% на 1 ход.
static func execute_ultimate(attacker: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("🌐 СВЕРХСПОСОБНОСТЬ ДАШИ: Протокол обновления щитов!")
	
	for ally in bm.allies:
		if ally.is_alive():
			var current_shd := float(ally.get_meta("shield_value", 0.0))
			if current_shd > 0.0:
				ally.set_meta("shield_turns", 3)
				bm.combat_text_spawned.emit(ally, "Щит обновлен", Color(0.7, 0.85, 1.0), "", false)
				
	# Если в отряде есть другие персонажи Консоли, увеличиваем Бинарный урон на 50% на 1 ход
	var console_mates := 0
	for ally in bm.allies:
		if ally.is_alive() and ally.id in FactionSystem.FACTIONS["console"].members:
			console_mates += 1
			
	if console_mates >= 2 or (console_mates == 1 and bm.allies.size() > 1):
		for ally in bm.allies:
			if ally.is_alive():
				ally.set_meta("dasha_ult_binary_turns", 1)
				ally.set_meta("dasha_ult_binary_skip_tick", ally == attacker)
		bm.log_message("🔮 Ульта Даши: Благодаря союзникам Консоли, Бинарный урон отряда повышен на +50%% на 1 ход!")
		
	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(attacker)
