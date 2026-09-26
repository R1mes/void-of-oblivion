class_name MemospriteSystem
extends RefCounted

enum TargetScope {
	SELF,
	SINGLE_ALLY,
	OWNER,
	MEMOSPRITE,
	ALL_ALLIES,
	ALL_COMBAT_UNITS,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	OWNER_MEMOSPRITE_PAIR,
}

static func summon(owner: CombatUnit, definition: MemospriteDefinition, bm: BattleManager, heal_pct: float = -1.0) -> Memosprite:
	if owner == null or definition == null:
		return null

	var existing: Memosprite = get_sprite(owner, bm)
	if existing != null:
		# Если дух уже существует
		if not existing.is_alive():
			# Воскрешение / повторный призыв
			existing.stats.hp = existing.definition.calculate_max_hp(owner.stats.max_hp)
			existing.stats.max_hp = existing.stats.hp
			existing.is_targetable = existing.definition.is_targetable
			existing.appears_in_action_order = existing.definition.appears_in_action_order
			existing.set_state(Memosprite.State.ACTIVE)
			existing.recalculate_action_value()
			bm.log_message("✨ %s: Дух Памяти %s вновь призван на поле боя!" % [owner.display_name, existing.display_name])
			_apply_burned_page_if_equipped(owner, existing, bm)
			if existing.has_meta("paws_despawn_handled"):
				existing.remove_meta("paws_despawn_handled")
			bm.action_order_changed.emit()
			bm.unit_updated.emit(existing)
			return existing
		else:
			# Дух уже на поле: лечим и снимаем контроль (вариант B / C)
			var effective_heal_pct := heal_pct if heal_pct > 0.0 else (0.60 if (owner != null and owner.id == "marina_sky_guardian") else 0.30)
			var heal_amt := existing.stats.max_hp * effective_heal_pct
			existing.heal(heal_amt)
			dispel_crowd_control(existing)
			bm.log_message("✨ %s: Дух Памяти %s усилен (+%d ХП, снятие контроля)!" % [owner.display_name, existing.display_name, int(heal_amt)])
			bm.unit_updated.emit(existing)
			return existing

	# Создание нового Memosprite
	var sprite := Memosprite.new()
	sprite.init_from_definition(owner, definition)
	
	owner.set_meta("memosprite", sprite)
	sprite.set_meta("owner_unit", owner)

	if bm != null:
		if not sprite in bm.memosprites:
			bm.memosprites.append(sprite)
		bm.log_message("❄ %s призывает Духа Памяти: «%s» (ХП: %d, СКР: %.0f)!" % [
			owner.display_name,
			sprite.display_name,
			int(sprite.stats.max_hp),
			sprite.stats.spd
		])
		_apply_burned_page_if_equipped(owner, sprite, bm)
		_apply_bloom_defender_if_equipped(owner, bm)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(sprite)

	return sprite

static func _apply_bloom_defender_if_equipped(owner: CombatUnit, bm: BattleManager) -> void:
	if owner == null:
		return
	if owner.has_meta("set_bloom_defender_2") and not bool(owner.get_meta("bloom_defender_spd_active", false)):
		owner.add_speed_modifier(0.06, 0.0)
		owner.set_meta("bloom_defender_spd_active", true)
		if bm != null:
			bm.log_message("🌸 Сет «Защитница цветущей земли»: пока дух памяти на поле боя, скорость %s повышена на +6%%!" % owner.display_name)
			bm.unit_updated.emit(owner)

static func _apply_burned_page_if_equipped(owner: CombatUnit, sprite: Memosprite, bm: BattleManager) -> void:
	if owner == null or sprite == null or bm == null:
		return
	if owner.get_meta("light_cone_id", "") == "burned_page":
		owner.set_meta("burned_page_turns", 2)
		owner.set_meta("burned_page_skip_tick", true)
		owner.set_meta("burned_page_hp_pct", 0.15)
		owner.add_speed_modifier(0.08, 0.0)
		bm.recalculate_unit_max_hp(owner)
		
		sprite.set_meta("burned_page_turns", 2)
		sprite.set_meta("burned_page_skip_tick", true)
		sprite.set_meta("burned_page_hp_pct", 0.15)
		sprite.add_speed_modifier(0.08, 0.0)
		bm.recalculate_unit_max_hp(sprite)
		
		bm.log_message("🔥 Конус «Сгоревшая страница»: после призыва духа памяти скорость %s и %s повышена на +8%%, а макс. HP — на +15%% на 2 хода!" % [owner.display_name, sprite.display_name])
		bm.unit_updated.emit(owner)
		bm.unit_updated.emit(sprite)

static func despawn(sprite: Memosprite, bm: BattleManager = null) -> void:
	if sprite == null:
		return
	sprite.despawn()
	if sprite.owner != null and sprite.owner.has_meta("set_bloom_defender_2") and bool(sprite.owner.get_meta("bloom_defender_spd_active", false)):
		sprite.owner.remove_speed_modifier(0.06, 0.0)
		sprite.owner.set_meta("bloom_defender_spd_active", false)
		if bm != null:
			bm.log_message("🌸 Сет «Защитница цветущей земли»: дух памяти покинул поле боя, бонус скорости %s снят." % sprite.owner.display_name)
	if bm != null:
		bm.log_message("🌫 Дух Памяти %s покинул поле боя." % sprite.display_name)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(sprite)
		if sprite.owner != null:
			bm.unit_updated.emit(sprite.owner)

static func defeat(sprite: Memosprite, bm: BattleManager = null) -> void:
	if sprite == null:
		return
	sprite.defeat()
	if sprite.owner != null and sprite.owner.has_meta("set_bloom_defender_2") and bool(sprite.owner.get_meta("bloom_defender_spd_active", false)):
		sprite.owner.remove_speed_modifier(0.06, 0.0)
		sprite.owner.set_meta("bloom_defender_spd_active", false)
		if bm != null:
			bm.log_message("🌸 Сет «Защитница цветущей земли»: дух памяти повержен, бонус скорости %s снят." % sprite.owner.display_name)
	if bm != null:
		bm.log_message("💀 Дух Памяти %s повержен!" % sprite.display_name)
		bm.action_order_changed.emit()
		bm.unit_updated.emit(sprite)
		if sprite.owner != null:
			bm.unit_updated.emit(sprite.owner)

static func get_sprite(owner: CombatUnit, bm: BattleManager = null) -> Memosprite:
	if owner == null:
		return null
	if owner.has_meta("memosprite"):
		var s = owner.get_meta("memosprite")
		if s is Memosprite:
			return s
	if bm != null:
		for m in bm.memosprites:
			if m.owner == owner:
				return m
	return null

static func has_sprite(owner: CombatUnit, bm: BattleManager = null) -> bool:
	var s := get_sprite(owner, bm)
	return s != null and s.is_alive()

static func is_sprite_alive(owner: CombatUnit, bm: BattleManager = null) -> bool:
	var s := get_sprite(owner, bm)
	return s != null and s.is_alive()

static func restore_hp(sprite: Memosprite, amount: float) -> float:
	if sprite == null or not sprite.is_alive():
		return 0.0
	return sprite.heal(amount)

static func apply_damage(sprite: Memosprite, amount: float, _attacker: CombatUnit = null, _bm: BattleManager = null) -> float:
	if sprite == null or not sprite.is_alive():
		return 0.0
	return sprite.apply_damage(amount)

static func add_charge(sprite: Memosprite, amount: float) -> void:
	if sprite != null and sprite.charge_comp != null:
		sprite.charge_comp.add_charge(amount)

static func consume_charge(sprite: Memosprite, amount: float) -> bool:
	if sprite != null and sprite.charge_comp != null:
		return sprite.charge_comp.consume_charge(amount)
	return false

static func advance_action(sprite: Memosprite, percentage: float, bm: BattleManager = null) -> void:
	if sprite != null and sprite.is_alive():
		sprite.advance_action(percentage)
		if bm != null:
			bm.log_message("⏩ Действие Духа Памяти %s продвинуто на %.0f%%!" % [sprite.display_name, percentage])
			bm.action_order_changed.emit()

static func delay_action(sprite: Memosprite, percentage: float, bm: BattleManager = null) -> void:
	if sprite != null and sprite.is_alive():
		sprite.delay_action(percentage)
		if bm != null:
			bm.action_order_changed.emit()

static func dispel_crowd_control(sprite: Memosprite) -> void:
	if sprite == null:
		return
	sprite.statuses.skip_next_turn = false
	if sprite.statuses.break_status in ["freeze", "imprisonment", "entanglement"]:
		sprite.statuses.break_status = ""
		sprite.statuses.break_status_turns = 0
	sprite.statuses.entanglement_stacks = 0
	sprite.statuses.imaginary_chains_turns = 0

static func on_ally_energy_gained(ally: CombatUnit, amount: float, bm: BattleManager) -> void:
	if bm == null or amount <= 0.0:
		return
	for m in bm.memosprites:
		if m != null and m.is_alive() and m.charge_comp != null:
			# Талант Эго Марины и тестового спрайта: за каждые 10 ед. энергии команды +1 Charge
			if m.definition != null and (m.definition.id == "ego" or m.definition.id == "remembrance_ego" or m.definition.id == "test_sprite"):
				var gained_charge := amount * 0.10
				m.charge_comp.add_charge(gained_charge)
			if m.definition != null and m.definition.talent_callable.is_valid():
				m.definition.talent_callable.call(m, ally, amount, bm)

static func on_owner_died(owner: CombatUnit, bm: BattleManager) -> void:
	var sprite := get_sprite(owner, bm)
	if sprite == null or not sprite.is_alive():
		return
	
	var rule := sprite.definition.owner_death_rule if sprite.definition != null else MemospriteDefinition.OwnerDeathRule.DESPAWN
	match rule:
		MemospriteDefinition.OwnerDeathRule.DESPAWN:
			despawn(sprite, bm)
		MemospriteDefinition.OwnerDeathRule.SELF_DESTRUCT:
			defeat(sprite, bm)
		MemospriteDefinition.OwnerDeathRule.BECOME_INACTIVE:
			sprite.is_active = false
			sprite.appears_in_action_order = false
			sprite.action_value = INF
			if bm != null:
				bm.action_order_changed.emit()
		MemospriteDefinition.OwnerDeathRule.STAY:
			pass

# Совместная атака: Владелец + Дух (2 Damage Instances, 1 Action)
static func execute_joint_attack(owner: CombatUnit, sprite: Memosprite, target: CombatUnit, owner_mult: float, sprite_mult: float, bm: BattleManager) -> Dictionary:
	if bm == null or target == null or not target.is_alive():
		return {"owner_damage": 0.0, "sprite_damage": 0.0, "total_damage": 0.0}

	bm.log_message("⚔ СОВМЕСТНАЯ АТАКА: %s и Дух Памяти %s атакуют %s!" % [owner.display_name, sprite.display_name, target.display_name])
	
	bm.start_attack_action()
	
	# Атака 1: Владелец
	var res_owner := bm.calc_dmg(owner, target, owner_mult)
	var dmg_owner: float = float(res_owner.get("damage", 0.0))
	bm.deal_damage(target, dmg_owner, owner, owner.element, bool(res_owner.get("crit", false)), "joint_attack_owner")
	ToughnessSystem.apply_weakness_hit(owner, target, bm, 1.0)

	# Атака 2: Дух Памяти
	var dmg_sprite: float = 0.0
	if target.is_alive() and sprite.is_alive():
		var res_sprite := bm.calc_dmg(sprite, target, sprite_mult)
		dmg_sprite = float(res_sprite.get("damage", 0.0))
		bm.deal_damage(target, dmg_sprite, sprite, sprite.element, bool(res_sprite.get("crit", false)), "joint_attack_memosprite")
		var tgh_reduction := sprite.definition.skill_toughness_reduction if sprite.definition != null else 1.0
		ToughnessSystem.apply_weakness_hit(sprite, target, bm, tgh_reduction)

	bm.finish_attack_action()

	return {
		"owner_damage": dmg_owner,
		"sprite_damage": dmg_sprite,
		"total_damage": dmg_owner + dmg_sprite
	}

static func process_turn(sprite: Memosprite, bm: BattleManager) -> void:
	if sprite == null or not sprite.is_alive() or bm == null:
		return

	bm.log_message("❄ [Ход Духа Памяти] «%s» (Заряд: %.0f/%.0f)" % [
		sprite.display_name,
		sprite.get_charge(),
		sprite.charge_comp.max_charge if sprite.charge_comp != null else 0.0
	])

	# Если под контролем
	if sprite.statuses.skip_next_turn:
		sprite.statuses.skip_next_turn = false
		bm.log_message("❄ %s пропускает ход (Контроль)!" % sprite.display_name)
		bm._end_turn(sprite)
		return

	# Динамическое обновление статов от владельца при необходимости
	if sprite.definition and sprite.definition.inheritance_mode == MemospriteDefinition.InheritanceMode.DYNAMIC:
		sprite.apply_stat_inheritance()

	# Выполнение действия через AI
	if sprite.ai_controller != null:
		sprite.ai_controller.evaluate_and_execute(sprite, bm)
	else:
		MemospriteAI._execute_fallback_attack(sprite, MemospriteAI.select_target_default(sprite, bm), bm)

	bm._end_turn(sprite)

static func resolve_targets(scope: TargetScope, context: Dictionary, bm: BattleManager) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	if bm == null:
		return result

	var actor: CombatUnit = context.get("actor", null)
	var main_target: CombatUnit = context.get("target", null)

	match scope:
		TargetScope.SELF:
			if actor != null and actor.is_alive():
				result.append(actor)
		TargetScope.SINGLE_ALLY:
			if main_target != null and main_target.is_alive() and main_target.is_ally:
				result.append(main_target)
		TargetScope.OWNER:
			if actor is Memosprite and actor.owner != null and actor.owner.is_alive():
				result.append(actor.owner)
			elif actor != null and actor.is_alive():
				result.append(actor)
		TargetScope.MEMOSPRITE:
			if actor != null:
				var s := get_sprite(actor, bm)
				if s != null and s.is_alive():
					result.append(s)
		TargetScope.OWNER_MEMOSPRITE_PAIR:
			var owner_u: CombatUnit = (actor as Memosprite).owner if actor is Memosprite else actor
			if owner_u != null and owner_u.is_alive():
				result.append(owner_u)
			var sp := get_sprite(owner_u, bm)
			if sp != null and sp.is_alive():
				result.append(sp)
		TargetScope.ALL_ALLIES:
			for a in bm.allies:
				if a.is_alive():
					result.append(a)
			for m in bm.memosprites:
				if m.is_alive() and m.is_active and m.can_receive_buffs:
					result.append(m)
		TargetScope.ALL_COMBAT_UNITS:
			for u in bm.get_all_units():
				if u is CombatUnit and u.is_alive():
					result.append(u)
		TargetScope.SINGLE_ENEMY:
			if main_target != null and main_target.is_alive() and not main_target.is_ally:
				result.append(main_target)
		TargetScope.ALL_ENEMIES:
			for e in bm.get_living_enemies():
				result.append(e)

	return result
