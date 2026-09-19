class_name MemospriteDefinition
extends RefCounted

enum HpMode {
	OWNER_SCALING,
	FIXED,
}

enum SpeedMode {
	FIXED,
	OWNER_SCALING,
	ZERO,
}

enum InheritanceMode {
	ON_SUMMON,
	DYNAMIC,
}

enum OwnerDeathRule {
	DESPAWN,
	STAY,
	SELF_DESTRUCT,
	BECOME_INACTIVE,
}

# Идентификация
var id: String = ""
var display_name: String = ""
var element: CombatConstants.Element = CombatConstants.Element.ICE
var path: CombatConstants.Path = CombatConstants.Path.REMEMBRANCE

# HP настройки
var hp_mode: HpMode = HpMode.OWNER_SCALING
var hp_coefficient: float = 0.8
var hp_flat: float = 640.0
var fixed_hp: float = 3000.0

# Скорость (SPD)
var speed_mode: SpeedMode = SpeedMode.FIXED
var base_speed: float = 130.0
var speed_coefficient: float = 1.0

# Агрессия (Aggro/Taunt)
var aggro: float = 100.0

# Наследование характеристик
var inheritance_mode: InheritanceMode = InheritanceMode.ON_SUMMON
var inherits_attack: bool = true
var inherits_defense: bool = true
var inherits_crit_rate: bool = true
var inherits_crit_damage: bool = true
var inherits_break_effect: bool = true
var inherits_damage_bonus: bool = true
var inherits_effect_res: bool = true
var inherits_effect_hit_rate: bool = true
var inherits_speed: bool = false
var inherits_hp: bool = false

# Ресурс Charge
var charge_enabled: bool = true
var max_charge: float = 100.0
var initial_charge: float = 0.0
var consumes_charge_on_enhanced: bool = true

# Позиционирование и таргетинг
var is_targetable: bool = true
var appears_in_action_order: bool = true
var is_backup: bool = false
var can_receive_buffs: bool = true
var can_receive_debuffs: bool = true
var can_receive_healing: bool = true

# Поведение при гибели владельца
var owner_death_rule: OwnerDeathRule = OwnerDeathRule.DESPAWN

# Способности и AI
var ai_profile: String = "default"
var skill_name: String = "Memosprite Skill"
var talent_name: String = "Memosprite Talent"
var enhanced_skill_name: String = "Enhanced Memosprite Skill"

var skill_toughness_reduction: float = 1.0 # 1.0 = базовая сбивка (30 стойкости)
var skill_energy_generation: float = 20.0  # Энергия для владельца/команды

# Callables для логики
var skill_callable: Callable = Callable()
var enhanced_skill_callable: Callable = Callable()
var talent_callable: Callable = Callable()

# Совместная атака (Joint Attack)
var joint_attack_enabled: bool = false
var joint_owner_multiplier: float = 1.0
var joint_sprite_multiplier: float = 1.0

func calculate_max_hp(owner_max_hp: float) -> float:
	match hp_mode:
		HpMode.OWNER_SCALING:
			return maxf(1.0, owner_max_hp * hp_coefficient + hp_flat)
		HpMode.FIXED:
			return maxf(1.0, fixed_hp)
	return 3000.0

func calculate_speed(owner_speed: float) -> float:
	match speed_mode:
		SpeedMode.ZERO:
			return 0.0
		SpeedMode.OWNER_SCALING:
			return maxf(1.0, owner_speed * speed_coefficient)
		SpeedMode.FIXED:
			return maxf(1.0, base_speed)
	return 130.0
