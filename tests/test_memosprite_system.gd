extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК АВТОМАТИЧЕСКИХ ТЕСТОВ ПУТИ ПАМЯТИ (MEMOSPRITE)")
	print("========================================================\n")
	
	var passed := 0
	var failed := 0

	var tests := [
		"test_1_summon",
		"test_2_action_order",
		"test_3_independent_speed",
		"test_4_damage_isolation",
		"test_5_healing_all_allies",
		"test_6_single_target_buff",
		"test_7_team_wide_buff",
		"test_8_death_and_queue_removal",
		"test_9_resummon",
		"test_10_charge_energy_generation",
		"test_11_crowd_control_dispel",
		"test_12_joint_attack_instances",
		"test_13_joint_attack_toughness",
		"test_14_aggro_distribution",
		"test_15_zero_speed_memosprite",
	]

	for t_name in tests:
		var ok: bool = call(t_name)
		if ok:
			passed += 1
			print("  [PASS] %s" % t_name)
		else:
			failed += 1
			print("  [FAIL] %s" % t_name)

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Пройдено: %d / %d  (Ошибок: %d)" % [passed, tests.size(), failed])
	print("========================================================\n")
	
	get_tree().quit(0 if failed == 0 else 1)

func _create_dummy_owner(hp: float = 4000.0, spd: float = 134.0, atk: float = 2000.0) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = "sara_memomaster"
	u.display_name = "Сара"
	u.is_ally = true
	u.stats.max_hp = hp
	u.stats.hp = hp
	u.stats.spd = spd
	u.stats.atk = atk
	u.stats.def = 800.0
	u.stats.crit_rate = 0.50
	u.stats.crit_dmg = 1.00
	u.recalculate_action_value()
	return u

func _create_dummy_enemy(hp: float = 10000.0, toughness_val: float = 60.0) -> CombatUnit:
	var e := CombatUnit.new()
	e.id = "void_soldier"
	e.display_name = "Солдат Бездны"
	e.is_ally = false
	e.stats.max_hp = hp
	e.stats.hp = hp
	e.stats.spd = 100.0
	e.stats.def = 500.0
	e.max_toughness = toughness_val
	e.toughness = toughness_val
	e.weaknesses = [CombatConstants.Element.ICE, CombatConstants.Element.PHYSICAL]
	e.recalculate_action_value()
	return e

func _create_dummy_bm(owner: CombatUnit, enemy: CombatUnit) -> BattleManager:
	var bm := BattleManager.new()
	add_child(bm)
	bm.allies = [owner]
	bm.enemies = [enemy]
	return bm

# Test 1 — Summon: Owner uses Skill -> Sprite appears
func test_1_summon() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	if sprite == null: return false
	if not sprite.is_alive(): return false
	if sprite.state != Memosprite.State.ACTIVE: return false
	if sprite.owner != owner: return false
	if sprite.get_owner() != owner: return false
	if not sprite in bm.memosprites: return false
	# HP: 80% Owner HP (4000) + 500 = 3700
	if absf(sprite.stats.max_hp - 3700.0) > 0.1: return false
	bm.queue_free()
	return true

# Test 2 — Action Order: Sprite appears in Action Queue
func test_2_action_order() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var all_units := bm.get_all_units()
	if not sprite in all_units:
		bm.queue_free()
		return false
	
	var preview := bm.get_action_preview()
	var in_preview := false
	for u in preview:
		if u == sprite:
			in_preview = true
			break
	bm.queue_free()
	return in_preview

# Test 3 — Independent Speed: Owner SPD != Sprite SPD, independent turns
func test_3_independent_speed() -> bool:
	var owner := _create_dummy_owner(4000.0, 100.0) # AV = 100.0
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	def.base_speed = 200.0 # AV = 50.0
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	if absf(owner.stats.spd - 100.0) > 0.01:
		bm.queue_free()
		return false
	if absf(sprite.stats.spd - 200.0) > 0.01:
		bm.queue_free()
		return false
	if absf(owner.action_value - 100.0) > 0.01:
		bm.queue_free()
		return false
	if absf(sprite.action_value - 50.0) > 0.01:
		bm.queue_free()
		return false
	
	var next_res := ActionValueSystem.get_next_actor(bm.get_all_units())
	bm.queue_free()
	# Sprite with 200 SPD (50 AV) must act before Owner with 100 SPD (100 AV)
	return next_res.unit == sprite

# Test 4 — Damage: Enemy attacks Sprite -> Sprite loses HP, Owner does NOT lose HP
func test_4_damage_isolation() -> bool:
	var owner := _create_dummy_owner(4000.0)
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var initial_owner_hp := owner.stats.hp
	var initial_sprite_hp := sprite.stats.hp
	
	bm.deal_damage(sprite, 500.0, enemy)
	
	var ok: bool = (absf(owner.stats.hp - initial_owner_hp) <= 0.01 and absf(sprite.stats.hp - (initial_sprite_hp - 500.0)) <= 0.01)
	bm.queue_free()
	return ok

# Test 5 — Healing: Heal All Allies -> Sprite receives healing
func test_5_healing_all_allies() -> bool:
	var owner := _create_dummy_owner(4000.0)
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	# Повреждаем обоих
	owner.stats.hp = 2000.0
	sprite.stats.hp = 1000.0
	
	# Лечим команду через TargetScope.ALL_ALLIES
	var targets := MemospriteSystem.resolve_targets(MemospriteSystem.TargetScope.ALL_ALLIES, {}, bm)
	for t in targets:
		bm.heal_unit(t, 500.0)
		
	var ok: bool = (absf(owner.stats.hp - 2500.0) <= 0.01 and absf(sprite.stats.hp - 1500.0) <= 0.01)
	bm.queue_free()
	return ok

# Test 6 — Single-target buff: Buff Owner -> Owner receives buff, Sprite does NOT
func test_6_single_target_buff() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var targets := MemospriteSystem.resolve_targets(MemospriteSystem.TargetScope.OWNER, {"actor": owner}, bm)
	for t in targets:
		t.stats.damage_bonus += 0.50
		
	var ok: bool = (absf(owner.stats.damage_bonus - 0.50) <= 0.01 and absf(sprite.stats.damage_bonus - 0.0) <= 0.01)
	bm.queue_free()
	return ok

# Test 7 — Team-wide buff: Buff All Allies -> Owner receives buff, Sprite receives buff
func test_7_team_wide_buff() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var targets := MemospriteSystem.resolve_targets(MemospriteSystem.TargetScope.ALL_ALLIES, {}, bm)
	for t in targets:
		t.stats.crit_dmg += 0.30
		
	var ok: bool = (absf(owner.stats.crit_dmg - 1.30) <= 0.01 and absf(sprite.stats.crit_dmg - 1.30) <= 0.01)
	bm.queue_free()
	return ok

# Test 8 — Death: Sprite HP = 0 -> Removed from queue and targeting
func test_8_death_and_queue_removal() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	# Наносим смертельный урон
	bm.deal_damage(sprite, 99999.0, enemy)
	
	var ok: bool = (not sprite.is_alive() and sprite.state == Memosprite.State.DEFEATED and not sprite in bm.get_all_units() and not sprite in bm.get_valid_targets_for_enemy(enemy))
	bm.queue_free()
	return ok

# Test 9 — Resummon: Owner uses Skill -> Sprite appears again with restored HP
func test_9_resummon() -> bool:
	var owner := _create_dummy_owner(4000.0)
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	bm.deal_damage(sprite, 99999.0, enemy)
	if sprite.is_alive():
		bm.queue_free()
		return false
	
	# Повторный призыв
	var resummoned := MemospriteSystem.summon(owner, def, bm)
	var ok: bool = (resummoned == sprite and resummoned.is_alive() and resummoned.state == Memosprite.State.ACTIVE and absf(resummoned.stats.hp - 3700.0) <= 0.1 and resummoned in bm.get_all_units())
	bm.queue_free()
	return ok

# Test 10 — Charge: Team generates 100 Energy -> Sprite gains 10 Charge
func test_10_charge_energy_generation() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	if absf(sprite.get_charge() - 0.0) > 0.01:
		bm.queue_free()
		return false
	
	# Отряд получает 100 энергии
	bm.gain_energy_with_err(owner, 100.0)
	
	# 100 * 0.10 = 10 Charge
	var ok: bool = (absf(sprite.get_charge() - 10.0) <= 0.01)
	bm.queue_free()
	return ok

# Test 11 — CC: Sprite is Frozen -> Owner dispels CC -> Sprite CC removed
func test_11_crowd_control_dispel() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	# Накладываем заморозку на духа
	sprite.statuses.skip_next_turn = true
	sprite.statuses.break_status = "freeze"
	sprite.statuses.break_status_turns = 1
	
	if not sprite.statuses.skip_next_turn:
		bm.queue_free()
		return false
	
	# Способность снимает контроль с духа
	MemospriteSystem.dispel_crowd_control(sprite)
	
	var ok: bool = (not sprite.statuses.skip_next_turn and sprite.statuses.break_status != "freeze")
	bm.queue_free()
	return ok

# Test 12 — Joint Attack: Owner + Sprite attack -> 2 Damage Instances, 1 Action
func test_12_joint_attack_instances() -> bool:
	var owner := _create_dummy_owner(4000.0, 100.0, 1000.0)
	var enemy := _create_dummy_enemy(20000.0, 200.0)
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var initial_enemy_hp := enemy.stats.hp
	var res := MemospriteSystem.execute_joint_attack(owner, sprite, enemy, 1.20, 1.50, bm)
	
	var d_owner: float = float(res.get("owner_damage", 0.0))
	var d_sprite: float = float(res.get("sprite_damage", 0.0))
	var d_total: float = float(res.get("total_damage", 0.0))
	
	var ok: bool = (d_owner > 0.0 and d_sprite > 0.0 and absf(d_total - (d_owner + d_sprite)) <= 0.01 and absf(enemy.stats.hp - (initial_enemy_hp - d_total)) <= 0.1)
	bm.queue_free()
	return ok

# Test 13 — Toughness: Both attacks of Joint Attack reduce Toughness separately
func test_13_joint_attack_toughness() -> bool:
	var owner := _create_dummy_owner(4000.0, 100.0, 1000.0)
	owner.element = CombatConstants.Element.PHYSICAL # Враг уязвим
	var enemy := _create_dummy_enemy(20000.0, 90.0) # 90 стойкости
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	def.element = CombatConstants.Element.ICE # Враг уязвим
	def.skill_toughness_reduction = 1.0 # 30 стойкости
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var initial_tgh := enemy.toughness
	MemospriteSystem.execute_joint_attack(owner, sprite, enemy, 1.0, 1.0, bm)
	
	# Owner сбивает 30 стойкости, Sprite сбивает 30 стойкости -> всего 60 стойкости сбито
	var expected_tgh := initial_tgh - 60.0
	var ok: bool = (absf(enemy.toughness - expected_tgh) <= 0.1)
	bm.queue_free()
	return ok

# Test 14 — Aggro: Sprite with Aggro increases total taunt pool and is selectable
func test_14_aggro_distribution() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	def.aggro = 125.0
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	var valid_targets := bm.get_valid_targets_for_enemy(enemy)
	var ok: bool = (owner in valid_targets and sprite in valid_targets and sprite.aggro_value == 125.0)
	bm.queue_free()
	return ok

# Test 15 — Zero SPD: Sprite with SPD = 0 does NOT appear in normal queue
func test_15_zero_speed_memosprite() -> bool:
	var owner := _create_dummy_owner()
	var enemy := _create_dummy_enemy()
	var bm := _create_dummy_bm(owner, enemy)
	
	var def := TestSprite.create_definition()
	def.speed_mode = MemospriteDefinition.SpeedMode.ZERO
	def.appears_in_action_order = false
	var sprite := MemospriteSystem.summon(owner, def, bm)
	
	if sprite.stats.spd != 0.0 or sprite.appears_in_action_order != false:
		bm.queue_free()
		return false
	
	var all_units := bm.get_all_units()
	if sprite in all_units:
		bm.queue_free()
		return false
	
	# Проверяем, что дух все равно существует на поле и может действовать по триггеру
	if not sprite.is_alive():
		bm.queue_free()
		return false
	
	var enemy_hp_before := enemy.stats.hp
	TestSprite._execute_skill(sprite, enemy, bm)
	var ok: bool = (enemy.stats.hp < enemy_hp_before)
	bm.queue_free()
	return ok
