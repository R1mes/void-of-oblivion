# scripts/characters/isaac.gd
class_name IsaacAbilities
extends RefCounted

const ID: String = "isaac"
const MAX_ENERGY: float = 120.0

static func create_unit(eidolon: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Айзек",
		"element": CombatConstants.Element.WIND, # Ветер
		"path": CombatConstants.Path.HARMONY,      # Гармония
		"is_ally": true,
		"eidolon": eidolon,
		"max_energy": MAX_ENERGY,
		"stats": {
			"hp": 2600,
			"atk": 1350,
			"def": 750,
			"spd": 103,
			"crit_rate": 0.45 if eidolon >= 1 else 0.05, # E1: КШ повышен на +40%
			"crit_dmg": 0.40,
			"effect_hit_rate": 0.10,
			"break_effect": 0.20,
			"weakness_efficiency": 0.00,
		},
	})
	return unit

static func apply_traces(unit: CombatUnit) -> void:
	# Е6: в начале боя Айзек получает 8 уровней статуса Теория на практике
	if unit.eidolon >= 6:
		unit.set_meta("isaac_theory_stacks", 8)

# Накопление стаков Теории на практике
static func add_theory_stacks(unit: CombatUnit, count: int, bm: BattleManager) -> void:
	var current: int = int(unit.get_meta("isaac_theory_stacks", 0))
	if current >= 8:
		return
		
	var new_stacks: int = int(clamp(current + count, 0, 8))
	unit.set_meta("isaac_theory_stacks", new_stacks)
	bm.log_message("Теория на практике Айзека: %d/8 зарядов." % new_stacks)
	bm.unit_updated.emit(unit)
	bm.action_order_changed.emit()

# БАЗОВАЯ АТАКА (80% СА, След 3: Продвижение действия на 20%)
# === НАЙДИТЕ И ОБНОВИТЕ ЭТОТ МЕТОД В ISAAC.GD ===
static func execute_basic_attack(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var res := bm.calc_dmg(attacker, target, 0.80, 0.0, false, 0.0, 0.0, false, true, "Basic")
	bm.deal_damage(target, res.damage, attacker, attacker.element, res.crit, "Basic")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm)
	
	# ИСПРАВЛЕНО: Записываем продвижение в отложенный буфер, чтобы сброс хода не стирал его!
	attacker.set_meta("action_advance_pending", 20.0)
	bm.log_message("След 3 Айзека: Продвижение действия на 20%% зарезервировано.")
	
	bm.gain_skill_point()
	bm.gain_energy_with_err(attacker, 20.0)
	bm.action_order_changed.emit()
	
# НАВЫК Q (Обычный AoE / Улучшенный - Продвижение союзника на 100% и бафф урона +80%)
static func execute_skill_q(attacker: CombatUnit, target: CombatUnit, extra_targets: Array, bm: BattleManager) -> void:
	var stacks: int = int(attacker.get_meta("isaac_theory_stacks", 0))
	var is_enhanced: bool = stacks >= 8
	
	if is_enhanced:
		# Улучшенный Q: продвигает союзника и увеличивает его урон на 80% на 1 ход
		target.advance_action(100.0)
		target.set_meta("isaac_dmg_buff_turns", 1)
		target.set_meta("isaac_dmg_buff_skip_tick", true)
		
		# E4: Снимает с выбранного союзника все ослабления
		if attacker.eidolon >= 4:
			target.statuses.cleanse_all()
			bm.log_message("Эйдолон 4 Айзека: Все дебаффы с %s сняты!" % target.display_name)
			
		# Сбрасывает стаки до 0
		attacker.set_meta("isaac_theory_stacks", 0)
		bm.log_message("Улучшенный Q Айзека: действие %s продвинуто на 100%%, урон повышен на +80%% на 1 ход." % target.display_name)
	else:
		# Обычный Q: 90% СА всем врагам и +2 уровня Теории на практике
		var living := bm.get_living_enemies()
		for enemy in living:
			var res := bm.calc_dmg(attacker, enemy, 0.90, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(enemy, res.damage, attacker, attacker.element, res.crit, "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, enemy, bm, 1.0)
			
		add_theory_stacks(attacker, 2, bm)
		
	bm.gain_energy_with_err(attacker, 30.0)
	bm.unit_updated.emit(attacker)
	if target:
		bm.unit_updated.emit(target)
	bm.action_order_changed.emit()

# НАВЫК E (120% СА цели, 60% соседям, накладывает +50% получаемого КУ и -30% наносимого урона на 3 хода)
static func execute_skill_e(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	var adjacent := bm.get_adjacent_enemies(target)
	
	# Урон по главной цели
	var res_c := bm.calc_dmg(attacker, target, 1.20, 0.0, false, 0.0, 0.0, false, true, "Skill")
	bm.deal_damage(target, res_c.damage, attacker, attacker.element, res_c.crit, "Skill")
	ToughnessSystem.apply_weakness_hit(attacker, target, bm, 1.0)
	
	# Дебаффы на главную цель (100% Базовый Шанс)
	if NaamaAbilities.roll_debuff(1.00, attacker, target, bm):
		target.set_meta("isaac_crit_dmg_taken_turns", 3)
		target.set_meta("isaac_dmg_reduce_turns", 3)
		bm.log_message("Дебафф Айзека на %s: Получаемый КУ +50%%, наносимый урон −30%% на 3 хода." % target.display_name)
		
	# Урон и дебаффы по соседям
	for adj in adjacent:
		if adj.is_alive():
			var res_a := bm.calc_dmg(attacker, adj, 0.60, 0.0, false, 0.0, 0.0, false, true, "Skill")
			bm.deal_damage(adj, res_a.damage, attacker, attacker.element, res_a.crit, "Skill")
			ToughnessSystem.apply_weakness_hit(attacker, adj, bm, 0.5)
			
			if NaamaAbilities.roll_debuff(1.00, attacker, adj, bm):
				adj.set_meta("isaac_crit_dmg_taken_turns", 3)
				adj.set_meta("isaac_dmg_reduce_turns", 3)
				bm.log_message("Дебафф Айзека на соседа %s: Получаемый КУ +50%%, наносимый урон −30%% на 3 хода." % adj.display_name)
				
	bm.gain_energy_with_err(attacker, 30.0)

# СВЕРХСПОСОБНОСТЬ (Бафф КУ союзника на +100% и скорости на +20 на 2 хода)
static func execute_ultimate(attacker: CombatUnit, target: CombatUnit, bm: BattleManager) -> void:
	target.set_meta("isaac_ult_buff_turns", 2)
	target.set_meta("isaac_ult_buff_skip_tick", true)
	
	# Начисляем +20 плоской скорости
	target.add_speed_modifier(0.0, 20.0)
	target.set_meta("isaac_ult_spd_bonus", 20.0)
	
	bm.log_message("Сверхспособность Айзека: Крит. урон %s повышен на +100%%, скорость на +20 ед. на 2 хода!" % target.display_name)
	
	target.recalculate_action_value()
	bm.gain_energy_with_err(attacker, 5.0)
	bm.unit_updated.emit(target)
	bm.action_order_changed.emit()
