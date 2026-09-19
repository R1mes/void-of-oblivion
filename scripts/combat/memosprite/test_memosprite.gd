class_name TestSprite
extends RefCounted

const ID: String = "test_sprite"

static func create_definition() -> MemospriteDefinition:
	var def := MemospriteDefinition.new()
	def.id = ID
	def.display_name = "Тестовый Дух Памяти"
	def.element = CombatConstants.Element.ICE
	def.path = CombatConstants.Path.REMEMBRANCE

	# HP = 80% Owner HP + 500
	def.hp_mode = MemospriteDefinition.HpMode.OWNER_SCALING
	def.hp_coefficient = 0.80
	def.hp_flat = 500.0

	# SPD = 130
	def.speed_mode = MemospriteDefinition.SpeedMode.FIXED
	def.base_speed = 130.0

	# Aggro = 100
	def.aggro = 100.0

	# Наследование статов
	def.inherits_attack = true
	def.inherits_defense = true
	def.inherits_crit_rate = true
	def.inherits_crit_damage = true
	def.inherits_speed = false
	def.inherits_hp = false

	# Charge = 0/100
	def.charge_enabled = true
	def.max_charge = 100.0
	def.initial_charge = 0.0

	def.is_targetable = true
	def.appears_in_action_order = true
	def.can_receive_buffs = true
	def.can_receive_debuffs = true
	def.can_receive_healing = true

	# Навыки
	def.skill_name = "Ледяной укол Памяти"
	def.enhanced_skill_name = "Сверхзвуковой всплеск Памяти"
	def.skill_toughness_reduction = 1.0

	# Обычный навык (100% ATK)
	def.skill_callable = Callable(TestSprite, "_execute_skill")
	# Усиленный навык (200% ATK при 100 Charge)
	def.enhanced_skill_callable = Callable(TestSprite, "_execute_enhanced_skill")

	return def

static func _execute_skill(sprite: Memosprite, target: CombatUnit, bm: BattleManager) -> void:
	if target == null:
		return
	bm.log_message("❄ %s: «Ледяной укол Памяти» по %s (100%% СА)!" % [sprite.display_name, target.display_name])
	var res := bm.calc_dmg(sprite, target, 1.0)
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, sprite, sprite.element, bool(res.get("crit", false)), "test_sprite_skill")
	ToughnessSystem.apply_weakness_hit(sprite, target, bm, 1.0)
	if sprite.owner and sprite.owner.is_alive():
		bm.gain_energy_with_err(sprite.owner, 20.0)

static func _execute_enhanced_skill(sprite: Memosprite, target: CombatUnit, bm: BattleManager) -> void:
	if target == null:
		return
	bm.log_message("💥❄ %s: «УСИЛЕННЫЙ ВСПЛЕСК ПАМЯТИ» по %s (200%% СА, Заряд 100%%)!" % [sprite.display_name, target.display_name])
	var res := bm.calc_dmg(sprite, target, 2.0)
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, sprite, sprite.element, bool(res.get("crit", false)), "test_sprite_enhanced_skill")
	ToughnessSystem.apply_weakness_hit(sprite, target, bm, 2.0)
	if sprite.owner and sprite.owner.is_alive():
		bm.gain_energy_with_err(sprite.owner, 30.0)
