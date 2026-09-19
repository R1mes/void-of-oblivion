class_name Memosprite
extends CombatUnit

enum State {
	NOT_EXISTING,
	SUMMONING,
	ACTIVE,
	DEFEATED,
	DESPAWNED,
}

signal state_changed(sprite: Memosprite, old_state: int, new_state: int)
signal memosprite_summoned(sprite: Memosprite)
signal memosprite_despawned(sprite: Memosprite)
signal memosprite_defeated(sprite: Memosprite)

var owner: CombatUnit = null
var owner_id: String = ""
var definition: MemospriteDefinition = null
var charge_comp: MemospriteChargeComponent = null
var ai_controller: MemospriteAI = null

var state: State = State.NOT_EXISTING
var is_active: bool = false
var is_targetable: bool = true
var appears_in_action_order: bool = true
var is_backup: bool = false

var can_receive_buffs: bool = true
var can_receive_debuffs: bool = true
var can_receive_healing: bool = true

var aggro_value: float = 100.0
var manual_control: bool = false

func _init() -> void:
	is_ally = true
	set_meta("is_memosprite", true)

func init_from_definition(owner_unit: CombatUnit, def: MemospriteDefinition) -> void:
	owner = owner_unit
	owner_id = owner_unit.id if owner_unit != null else ""
	definition = def
	
	id = "%s_memosprite" % (def.id if not def.id.is_empty() else owner_id)
	display_name = def.display_name
	element = owner_unit.element if owner_unit != null else def.element
	path = def.path
	is_ally = true
	is_elite = false
	max_energy = 0.0
	energy = 0.0
	
	is_targetable = def.is_targetable
	appears_in_action_order = def.appears_in_action_order
	is_backup = def.is_backup
	can_receive_buffs = def.can_receive_buffs
	can_receive_debuffs = def.can_receive_debuffs
	can_receive_healing = def.can_receive_healing
	aggro_value = def.aggro
	
	# Инициализация Charge
	if def.charge_enabled:
		charge_comp = MemospriteChargeComponent.new(def.max_charge, true)
		if def.initial_charge > 0.0:
			charge_comp.set_charge(def.initial_charge)
	else:
		charge_comp = null

	# Расчёт статов HP и SPD
	var owner_hp := owner.stats.max_hp if owner != null else 3000.0
	var calc_hp := def.calculate_max_hp(owner_hp)
	stats.max_hp = calc_hp
	stats.hp = calc_hp
	
	var owner_spd := owner.stats.spd if owner != null else 100.0
	var calc_spd := def.calculate_speed(owner_spd)
	stats.spd = calc_spd
	_base_spd = calc_spd
	
	# Применение наследования характеристик
	apply_stat_inheritance(def.inheritance_mode)
	
	# Расчёт Action Value
	if stats.spd > 0.0:
		recalculate_action_value()
	else:
		action_value = INF
		base_action_value = INF

	# Инициализация AI
	ai_controller = MemospriteAI.create_default_profile(self)
	
	set_state(State.ACTIVE)
	memosprite_summoned.emit(self)

func apply_stat_inheritance(_mode: int = -1) -> void:
	if owner == null or definition == null:
		return
	
	if definition.inherits_attack:
		stats.atk = owner.stats.atk
	if definition.inherits_defense:
		stats.def = owner.stats.def
	if definition.inherits_crit_rate:
		stats.crit_rate = owner.stats.crit_rate
	if definition.inherits_crit_damage:
		stats.crit_dmg = owner.stats.crit_dmg
	if definition.inherits_break_effect:
		stats.break_effect = owner.stats.break_effect
	if definition.inherits_damage_bonus:
		stats.damage_bonus = owner.stats.damage_bonus
	if definition.inherits_effect_res:
		stats.effect_res = owner.stats.effect_res
	if definition.inherits_effect_hit_rate:
		stats.effect_hit_rate = owner.stats.effect_hit_rate
	if definition.inherits_speed:
		stats.spd = owner.stats.spd
		_base_spd = stats.spd
		recalculate_action_value()
	if definition.inherits_hp:
		stats.max_hp = owner.stats.max_hp
		stats.hp = minf(stats.hp, stats.max_hp)

func set_state(new_state: State) -> void:
	if state == new_state:
		return
	var old_state := state
	state = new_state
	is_active = (state == State.ACTIVE)
	state_changed.emit(self, old_state, new_state)

func defeat() -> void:
	if state == State.DEFEATED or state == State.DESPAWNED or state == State.NOT_EXISTING:
		return
	set_state(State.DEFEATED)
	is_targetable = false
	appears_in_action_order = false
	if has_meta("mnema_reverence_stacks"):
		remove_meta("mnema_reverence_stacks")
	if owner != null and owner.has_meta("mnema_reverence_stacks"):
		owner.remove_meta("mnema_reverence_stacks")
	memosprite_defeated.emit(self)
	died.emit(self)

func despawn() -> void:
	if state == State.DESPAWNED or state == State.NOT_EXISTING:
		return
	set_state(State.DESPAWNED)
	is_targetable = false
	appears_in_action_order = false
	action_value = INF
	if has_meta("mnema_reverence_stacks"):
		remove_meta("mnema_reverence_stacks")
	if owner != null and owner.has_meta("mnema_reverence_stacks"):
		owner.remove_meta("mnema_reverence_stacks")
	memosprite_despawned.emit(self)

func get_owner() -> CombatUnit:
	return owner

func is_memosprite_alive() -> bool:
	return is_alive()

func is_alive() -> bool:
	return state == State.ACTIVE and stats.is_alive()

func apply_damage(amount: float) -> float:
	if not is_alive():
		return 0.0
	var dealt := stats.take_damage(amount)
	hp_changed.emit(self)
	if not stats.is_alive():
		defeat()
	return dealt

func heal(amount: float) -> float:
	if not can_receive_healing or not is_alive():
		return 0.0
	var healed := stats.heal(amount)
	hp_changed.emit(self)
	return healed

func get_charge() -> float:
	return charge_comp.get_charge() if charge_comp != null else 0.0

func add_charge(amount: float) -> void:
	if charge_comp:
		charge_comp.add_charge(amount)

func set_charge(amount: float) -> void:
	if charge_comp:
		charge_comp.set_charge(amount)

func get_debug_info() -> String:
	var owner_name := owner.display_name if owner != null else "None"
	var cur_ch := get_charge()
	var max_ch := charge_comp.max_charge if charge_comp != null else 0.0
	var state_str := "ACTIVE"
	match state:
		State.NOT_EXISTING: state_str = "NOT_EXISTING"
		State.SUMMONING: state_str = "SUMMONING"
		State.ACTIVE: state_str = "ACTIVE"
		State.DEFEATED: state_str = "DEFEATED"
		State.DESPAWNED: state_str = "DESPAWNED"

	return "[Memosprite: %s]\nOwner: %s\nHP: %d / %d\nSPD: %.1f\nAV: %.1f\nCharge: %.1f / %.1f\nAggro: %.1f\nState: %s\nTargetable: %s\nActionOrder: %s" % [
		display_name,
		owner_name,
		int(stats.hp),
		int(stats.max_hp),
		stats.spd,
		action_value,
		cur_ch,
		max_ch,
		aggro_value,
		state_str,
		"YES" if is_targetable else "NO",
		"YES" if appears_in_action_order else "NO"
	]
