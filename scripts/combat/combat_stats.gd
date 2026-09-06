class_name CombatStats
extends RefCounted

var max_hp: float = 1000.0
var hp: float = 1000.0
var atk: float = 500.0
var def: float = 300.0
var spd: float = 100.0
var crit_rate: float = 0.05
var crit_dmg: float = 0.50
var effect_hit_rate: float = 0.0
var break_effect: float = 0.0
var weakness_efficiency: float = 0.0
var damage_bonus: float = 0.0

var _spd_modifiers: Array[float] = []
var _ehr_modifiers: Array[float] = []

func get_effective_atk(unit_statuses: StatusEffects) -> float:
	var total := atk
	total *= 1.0 + unit_statuses.self_atk_buff_percent + unit_statuses.atk_buff_percent
	total += unit_statuses.atk_buff_flat
	return total

func get_effective_crit_dmg(unit_statuses: StatusEffects, extra: float = 0.0) -> float:
	return crit_dmg + unit_statuses.crit_dmg_buff + extra

func duplicate_stats() -> CombatStats:
	var copy := CombatStats.new()
	copy.max_hp = max_hp
	copy.hp = hp
	copy.atk = atk
	copy.def = def
	copy.spd = spd
	copy.crit_rate = crit_rate
	copy.crit_dmg = crit_dmg
	copy.effect_hit_rate = effect_hit_rate
	copy.break_effect = break_effect
	copy.weakness_efficiency = weakness_efficiency
	copy.damage_bonus = damage_bonus
	copy._spd_modifiers = _spd_modifiers.duplicate()
	copy._ehr_modifiers = _ehr_modifiers.duplicate()
	return copy

func get_effective_spd() -> float:
	var base_spd := spd
	
	# Суммируем все процентные модификаторы скорости (например, дебаффы)
	var pct_bonus := 0.0
	for mod in _spd_modifiers:
		pct_bonus -= mod # Дебаффы вычитаются процентно от базы
		
	# Прибавляем кастомные баффы скорости из метаданных (от конусов/способностей)
	if has_meta("spd_pct_bonus"):
		pct_bonus += float(get_meta("spd_pct_bonus", 0.0))
		
	var flat_bonus := 0.0
	if has_meta("spd_flat_bonus"):
		flat_bonus += float(get_meta("spd_flat_bonus", 0.0))
		
	# Итоговая формула: базовая * (1 + сумма %) + плоские прибавки
	var total := base_spd * (1.0 + pct_bonus) + flat_bonus
	return maxf(total, 1.0)

func get_effective_ehr() -> float:
	var total := effect_hit_rate
	for mod in _ehr_modifiers:
		total -= mod
	return maxf(total, 0.0)

func add_spd_debuff(percent: float) -> void:
	_spd_modifiers.append(percent)

func clear_spd_debuffs() -> void:
	_spd_modifiers.clear()

func add_ehr_debuff(percent: float) -> void:
	_ehr_modifiers.append(percent)

func clear_ehr_debuffs() -> void:
	_ehr_modifiers.clear()

func is_alive() -> bool:
	return hp > 0.0

func heal(amount: float) -> float:
	var before := hp
	hp = minf(hp + amount, max_hp)
	return hp - before

func take_damage(amount: float) -> float:
	var actual := minf(amount, hp)
	hp -= actual
	return actual
