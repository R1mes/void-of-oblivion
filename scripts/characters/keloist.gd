# scripts/characters/keloist.gd
class_name KeloistAbilities
extends RefCounted

const ID: String = "keloist"
const MAX_ENERGY: float = 120.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Келойст",
		"element": CombatConstants.Element.FIRE, # Огонь
		"path": CombatConstants.Path.ERUDITION,    # Эрудиция
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2650,
			"atk": 1700,
			"def": 680,
			"spd": 103,
			"crit_rate": 0.05,
			"crit_dmg": 0.50,
			"effect_hit_rate": 0.00,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	pass

# Метод динамического перерасчета плоской СА всех союзников (След 1 + Талант Командования)
static func recalculate_allies_atk_buffs(bm: BattleManager) -> void:
	var keloist: CombatUnit = bm.get_keloist_unit()
	if keloist == null or not keloist.is_alive():
		# Если Келойст погиб, обнуляем все его баффы СА на союзниках
		for ally in bm.allies:
			if ally.has_meta("keloist_flat_atk_buff"):
				ally.remove_meta("keloist_flat_atk_buff")
				bm.unit_updated.emit(ally)
		return
		
	var keloist_base_atk: float = float(keloist.get_meta("base_atk_original", keloist.stats.atk))
	var command_stacks: int = int(keloist.get_meta("keloist_command_stacks", 0))
	
	for ally in bm.allies:
		if not ally.is_alive():
			if ally.has_meta("keloist_flat_atk_buff"):
				ally.remove_meta("keloist_flat_atk_buff")
			continue
			
		if ally == keloist:
			# Келойст не баффает самого себя
			if ally.has_meta("keloist_flat_atk_buff"):
				ally.remove_meta("keloist_flat_atk_buff")
			continue
			
		var pct_bonus: float = 0.0
		# 1. Талант: +2% силы атаки союзникам за каждый стак Командования от СА Келойста
		pct_bonus += 0.02 * float(command_stacks)
		
		# 2. След 1: Союзник под Ортощитом получает доп. +20% СА от СА Келойста
		if ally.has_meta("keloist_orthoshield_turns") and int(ally.get_meta("keloist_orthoshield_turns", 0)) > 0:
			pct_bonus += 0.20
			
		var flat_buff: float = keloist_base_atk * pct_bonus
		ally.set_meta("keloist_flat_atk_buff", flat_buff)
		bm.unit_updated.emit(ally)

# Начисление стаков Командования (КШ прибавляется напрямую в stats.crit_rate)
static func increment_command_stacks(unit: CombatUnit, count: int, bm: BattleManager) -> void:
	var current: int = int(unit.get_meta("keloist_command_stacks", 0))
	if current >= 20:
		return
		
	var new_stacks: int = int(clamp(current + count, 0, 20))
	unit.set_meta("keloist_command_stacks", new_stacks)
	bm.log_message("Командование Келойста: %d/20 стаков." % new_stacks)
	
	# Талант: +3% крит. шанса Келойсту за каждый стак Командования напрямую в stats
	var diff: int = new_stacks - current
	if diff > 0:
		unit.stats.crit_rate += 0.03 * float(diff)
		bm.log_message("Талант Келойста: Крит. шанс повышен на +%d%% (Текущий КШ: %.0f%%)." % [diff * 3, unit.stats.crit_rate * 100.0])
		
	# Запускаем перерасчет баффов СА союзников
	recalculate_allies_atk_buffs(bm)

# Очистка дебаффа при наложении Ортощита (Е6)
static func cleanse_one_debuff(target: CombatUnit, bm: BattleManager) -> void:
	if target.has_meta("def_reductions"):
		var reductions: Dictionary = target.get_meta("def_reductions")
		if not reductions.is_empty():
			var first_key: String = String(reductions.keys()[0])
			reductions.erase(first_key)
			bm.recalculate_target_def(target)
			bm.log_message("Э6 Келойста: Снят дебафф защиты «%s» с %s." % [first_key, target.display_name])
			return
			
	if target.statuses.suppression_stacks > 0:
		target.statuses.suppression_stacks = max(0, target.statuses.suppression_stacks - 1)
		bm.log_message("Э6 Келойста: Снят 1 стак Подавления с %s." % target.display_name)
		return
		
	if target.has_meta("lenskaya_slow_turns") and int(target.get_meta("lenskaya_slow_turns", 0)) > 0:
		target.remove_meta("lenskaya_slow_turns")
		var slow_val: float = float(target.get_meta("lenskaya_slow_value", 20.0))
		target.add_speed_modifier(0.0, slow_val)
		bm.log_message("Э6 Келойста: Снято Замедление с %s." % target.display_name)
		return

# БАЗОВАЯ АТАКА (90% СА, Урон по стойкости: 50% от стандарта)
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 0.80, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 0.5)
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)

# НАВЫК Q (100% СА всем врагам. Продвижение на 30% при Ортощите в команде)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	for enemy in living:
		var res := bm.calc_dmg(attacker, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Skill")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
		
	# Проверяем, есть ли на поле союзник с Ортощитом
	var has_orthoshield := false
	for ally in bm.allies:
		if ally.is_alive() and ally.has_meta("keloist_orthoshield_turns") and int(ally.get_meta("keloist_orthoshield_turns", 0)) > 0:
			has_orthoshield = true
			break
			
	if has_orthoshield:
		# ИСПРАВЛЕНО: Используем отложенный буфер продвижения хода, чтобы сброс в _end_turn не затирал его!
		attacker.set_meta("action_advance_pending", 30.0)
		bm.log_message("Навык Q Келойста: В команде есть Ортощит! Продвижение действия на 30%% зарезервировано.")
		
	bm.gain_energy_with_err(attacker, 30.0)
	bm.action_order_changed.emit()

# НАВЫК E (Накладывает Ортощит на союзника на 3 хода)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	for ally in bm.allies:
		ally.remove_meta("keloist_orthoshield_turns")
		
	target.set_meta("keloist_orthoshield_turns", 3)
	target.set_meta("keloist_orthoshield_skip_tick", true)
	
	# E6: Снимает 1 дебафф при наложении
	if attacker.eidolon >= 6:
		cleanse_one_debuff(target, bm)
		
	bm.log_message("Навык E Келойста: На %s наложен Ортощит на 3 хода." % target.display_name)
	
	# Перерасчитываем Силу Атаки союзников
	recalculate_allies_atk_buffs(bm)
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(target)

# СВЕРХСПОСОБНОСТЬ (Е1 интегрирован внутрь расчета ульты Келойста!)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var living := bm.get_living_enemies()
	for enemy in living:
		var mult: float = 1.60
		# Е1: Наносимый урон ульты повышен на 10% по противникам с ХП < 30%
		if attacker.eidolon >= 1:
			if enemy.stats.hp / enemy.stats.max_hp < 0.30:
				mult += 0.10
				
		var res := bm.calc_dmg(attacker, enemy, mult, 0.0, false, 0.0, 0.0, true)
		bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Ultimate")
		ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.25)
		
	bm.gain_energy_with_err(attacker, 5.0)

# Совместная атака Ортощита (не сносит уязвимость врага)
static func trigger_joint_attack(target: CombatUnit, bm: BattleManager) -> void:
	var keloist := bm.get_keloist_unit()
	if keloist == null or not keloist.is_alive():
		return
		
	var res := bm.calc_dmg(keloist, target, 0.20, 0.0, false, 0.0, 0.0, false, false, "keloist_joint_attack")
	# ИСПРАВЛЕНО: Теперь удар Ортощита передается под тегом "keloist_joint_attack", а не "Бонус-атака"!
	bm.deal_damage(target, res.damage, keloist, keloist.element, res.crit)
	
# Метод обработки смерти врагов для Следа 2 (энергия Келойсту)
static func on_enemy_killed(unit: CombatUnit, bm: BattleManager) -> void:
	bm.gain_energy_with_err(unit, 5.0)
	bm.log_message("След 2 Келойста: Враг побежден! Келойст восстановил +5 энергии.")

# Метод обработки смерти союзников для Е2 (восстановление ОН при смерти Ортощита)
static func on_ally_killed(target: CombatUnit, bm: BattleManager) -> void:
	if target.has_meta("keloist_orthoshield_turns") and int(target.get_meta("keloist_orthoshield_turns", 0)) > 0:
		var keloist := bm.get_keloist_unit()
		if keloist and keloist.is_alive() and keloist.eidolon >= 2:
			bm.gain_skill_point()
			bm.gain_skill_point()
			bm.log_message("Эйдолон 2 Келойста: Союзник с Ортощитом пал! Восстановлено +2 ОН.")
			
	# Обновляем баффы отряда (так как союзник погиб)
	recalculate_allies_atk_buffs(bm)
