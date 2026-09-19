class_name MemospriteAI
extends RefCounted

class ActionRule extends RefCounted:
	var name: String = ""
	var priority: int = 0
	var condition_func: Callable = Callable()
	var action_func: Callable = Callable()
	var target_selector: Callable = Callable()

	func _init(p_name: String, p_priority: int, p_cond: Callable, p_action: Callable, p_target: Callable = Callable()) -> void:
		name = p_name
		priority = p_priority
		condition_func = p_cond
		action_func = p_action
		target_selector = p_target

var rules: Array[ActionRule] = []

func add_rule(rule: ActionRule) -> void:
	rules.append(rule)
	_sort_rules()

func clear_rules() -> void:
	rules.clear()

func _sort_rules() -> void:
	rules.sort_custom(func(a: ActionRule, b: ActionRule): return a.priority > b.priority)

static func select_target_default(_sprite: Memosprite, bm: BattleManager) -> CombatUnit:
	var enemies := bm.get_living_enemies()
	if enemies.is_empty():
		return null
	# По умолчанию выбираем цель с наименьшим текущим процентом HP
	var best: CombatUnit = enemies[0]
	var min_ratio := best.get_hp_ratio()
	for e in enemies:
		var r := e.get_hp_ratio()
		if r < min_ratio:
			min_ratio = r
			best = e
	return best

func evaluate_and_execute(sprite: Memosprite, bm: BattleManager) -> bool:
	for rule in rules:
		var condition_met := true
		if rule.condition_func.is_valid():
			condition_met = bool(rule.condition_func.call(sprite, bm))
		
		if condition_met:
			var target: CombatUnit = null
			if rule.target_selector.is_valid():
				target = rule.target_selector.call(sprite, bm)
			else:
				target = select_target_default(sprite, bm)
			
			if rule.action_func.is_valid():
				rule.action_func.call(sprite, target, bm)
				return true
	
	# Фолбэк на дефолтную способность из definition
	if sprite.definition:
		var target := select_target_default(sprite, bm)
		if target != null:
			if sprite.charge_comp and sprite.charge_comp.is_fully_charged() and sprite.definition.enhanced_skill_callable.is_valid():
				if sprite.definition.consumes_charge_on_enhanced:
					sprite.charge_comp.consume_charge(sprite.definition.max_charge)
				sprite.definition.enhanced_skill_callable.call(sprite, target, bm)
				return true
			elif sprite.definition.skill_callable.is_valid():
				sprite.definition.skill_callable.call(sprite, target, bm)
				return true
			else:
				# Базовая атака духа
				_execute_fallback_attack(sprite, target, bm)
				return true
	return false

static func _execute_fallback_attack(sprite: Memosprite, target: CombatUnit, bm: BattleManager) -> void:
	bm.log_message("👻 %s атакует %s!" % [sprite.display_name, target.display_name])
	var res := bm.calc_dmg(sprite, target, 1.0)
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, sprite, sprite.element, bool(res.get("crit", false)), "memosprite_skill")
	ToughnessSystem.apply_weakness_hit(sprite, target, bm, 1.0)
	if sprite.owner and sprite.owner.is_alive():
		bm.gain_energy_with_err(sprite.owner, 20.0)

static func create_default_profile(sprite: Memosprite) -> MemospriteAI:
	var ai := MemospriteAI.new()
	var def := sprite.definition
	if def == null:
		return ai

	# Правило 100: Усиленный навык при полном заряде (Charge >= 100)
	if def.enhanced_skill_callable.is_valid():
		var charged_rule := ActionRule.new(
			"EnhancedSkill",
			100,
			func(s: Memosprite, _bm: BattleManager) -> bool:
				return s.charge_comp != null and s.charge_comp.is_fully_charged(),
			func(s: Memosprite, tgt: CombatUnit, bm: BattleManager) -> void:
				if def.consumes_charge_on_enhanced and s.charge_comp:
					s.charge_comp.consume_charge(def.max_charge)
				def.enhanced_skill_callable.call(s, tgt, bm),
			func(s: Memosprite, bm: BattleManager) -> CombatUnit:
				return ai.select_target_default(s, bm)
		)
		ai.add_rule(charged_rule)

	# Правило 0: Обычный навык
	if def.skill_callable.is_valid():
		var normal_rule := ActionRule.new(
			"NormalSkill",
			0,
			func(_s: Memosprite, _bm: BattleManager) -> bool: return true,
			func(s: Memosprite, tgt: CombatUnit, bm: BattleManager) -> void:
				def.skill_callable.call(s, tgt, bm),
			func(s: Memosprite, bm: BattleManager) -> CombatUnit:
				return ai.select_target_default(s, bm)
		)
		ai.add_rule(normal_rule)

	return ai
