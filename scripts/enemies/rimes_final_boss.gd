class_name RimesFinalBoss
extends RefCounted

const ID: String = "rimes_final_boss"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Раймс • Финальный босс",
		"element": CombatConstants.Element.QUANTUM,
		"path": CombatConstants.Path.DESTRUCTION,
		"is_ally": false,
		"is_elite": true,
		"stats": {
			"hp": 280000, # Фаза 1: 280 000
			"atk": 2100,
			"def": 1150,
			"spd": 110,
			"crit_rate": 0.15,
			"crit_dmg": 0.65,
			"effect_res": 0.40,
		},
		"toughness": 420,
		"weaknesses": [
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.ICE,
			CombatConstants.Element.PHYSICAL,
		],
	})
	unit.set_meta("base_hp_original", 280000.0)
	unit.set_meta("base_atk_original", 2100.0)
	unit.set_meta("base_def_original", 1150.0)
	unit.set_meta("base_spd_original", 110.0)
	unit.set_meta("phase", 1)
	unit.set_meta("turn_count", 0)
	unit.set_meta("turn_p2_count", 0)
	unit.set_meta("turn_p3_count", 0)
	unit.set_meta("is_weekly_boss", true)
	unit.set_meta("cannot_be_executed", true)
	unit.set_meta("cannot_be_split", true)
	unit.set_meta("imaginary_res_bonus", 0.40) # 40% сопротивления мнимому урону
	unit.set_meta("rimes_conductor_charging", false)
	return unit

static func pick_target(allies: Array, prioritize_highest_atk: bool = false) -> CombatUnit:
	# 1. Провокация Данилла
	for a in allies:
		if a is CombatUnit and a.is_alive() and (a.id == "danill" or a.id == "danila"):
			if a.has_meta("danill_taunt_turns") and int(a.get_meta("danill_taunt_turns", 0)) > 0:
				return a

	# 2. Приоритет наивысшей СА (Керри)
	if prioritize_highest_atk:
		var max_atk: float = -1.0
		var top_target: CombatUnit = null
		for a in allies:
			if a is CombatUnit and a.is_alive():
				if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
					continue
				var cur_atk: float = a.stats.atk
				if cur_atk > max_atk:
					max_atk = cur_atk
					top_target = a
		if top_target != null:
			return top_target

	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			if a.has_meta("untargetable") and bool(a.get_meta("untargetable", false)):
				continue
			living.append(a)

	if living.is_empty():
		for a in allies:
			if a is CombatUnit and a.is_alive():
				living.append(a)

	if living.is_empty():
		return null

	return living[randi() % living.size()]

static func execute_turn(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var phase: int = int(enemy.get_meta("phase", 1))
	match phase:
		1:
			_execute_phase_1(enemy, allies, bm)
		2:
			_execute_phase_2(enemy, allies, bm)
		3:
			_execute_phase_3(enemy, allies, bm)

# --- ФАЗА 1 ---
static func _execute_phase_1(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn: int = int(enemy.get_meta("turn_count", 0)) + 1
	enemy.set_meta("turn_count", turn)
	
	match turn % 3:
		1:
			_skill_gravitational_cleave(enemy, allies, bm)
		2:
			_skill_entropy_shatter(enemy, allies, bm)
		0:
			_skill_antimatter_compression(enemy, allies, bm)

# --- ФАЗА 2 ---
static func _execute_phase_2(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn_p2: int = int(enemy.get_meta("turn_p2_count", 0)) + 1
	enemy.set_meta("turn_p2_count", turn_p2)
	
	match turn_p2 % 3:
		1:
			_skill_singularity_of_oblivion(enemy, allies, bm)
		2:
			_skill_horizon_inversion(enemy, allies, bm)
		0:
			_skill_gravitational_cleave(enemy, allies, bm)

# --- ФАЗА 3 ---
static func _execute_phase_3(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var turn_p3: int = int(enemy.get_meta("turn_p3_count", 0)) + 1
	enemy.set_meta("turn_p3_count", turn_p3)
	
	# Проверка ультимейта «По воле дирижёра»
	if bool(enemy.get_meta("rimes_conductor_charging", false)):
		_resolve_conductor_will(enemy, allies, bm)
		return

	# На 1 ходу 3 фазы и каждые 4 хода босс призывает лапы и заряжает ультимейт
	if turn_p3 == 1 or turn_p3 % 4 == 1:
		_summon_void_paws(enemy, bm)
		enemy.set_meta("rimes_conductor_charging", true)
		bm.log_message("👑 Раймс • Финальный босс взмахивает дирижёрской палочкой: началась подготовка Сверхспособности «По воле дирижёра»! Уничтожьте все Лапы Ничто, чтобы сорвать атаку!")
		return
		
	match turn_p3 % 3:
		2:
			_skill_singularity_pulsation(enemy, allies, bm)
		0:
			_skill_gravitational_cleave(enemy, allies, bm)
		_:
			_skill_horizon_inversion(enemy, allies, bm)

# --- СПОСОБНОСТИ БОССА ---

# 1. «Гравитационный раскол» (180% СА цели, 70% соседям). Если Ленская в изнанке — 0 урона ей.
static func _skill_gravitational_cleave(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var target := pick_target(allies, true)
	if target == null:
		return
	bm.log_message("🌌 %s применяет «Гравитационный раскол» по %s!" % [enemy.display_name, target.display_name])
	var adj := bm.get_adjacent_allies(target)
	
	var res := DamageCalculator.calc_damage(enemy, target, 1.75)
	var dmg: float = float(res.get("damage", 0.0))
	bm.deal_damage(target, dmg, enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))
	
	for a in adj:
		if a.is_alive():
			var a_res := DamageCalculator.calc_damage(enemy, a, 0.65)
			bm.deal_damage(a, float(a_res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(a_res.get("crit", false)))

# 2. «Ледяное расщепление энтропии» (AoE 85% СА). Если цель имеет бафф скорости (от Вельзевул/Следа) -> -25% урона.
static func _skill_entropy_shatter(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("❄ %s выпускает волну «Ледяного расщепления энтропии» по всем союзникам!" % enemy.display_name)
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var mult: float = 0.85
			# Если скорость выше базовой (бафф скорости Вельзевул)
			if a.stats.get_effective_spd() > a.stats.spd:
				mult *= 0.75
				bm.log_message("  ↳ %s ускорен -> входящий урон снижен на 25%%!" % a.display_name)
			var res := DamageCalculator.calc_damage(enemy, a, mult)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.ICE, bool(res.get("crit", false)))

# 3. «Сжатие анти-материи» (Атака по всем + кража 10 Зеро, но урон снижен на 20% если Зеро > 0)
static func _skill_antimatter_compression(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var zero: int = bm.get_xaeroh()
	var dmg_mult: float = 1.00
	if zero > 0:
		dmg_mult = 0.80
		bm.log_message("🌌 Плотность Зеро (%d) сдерживает «Сжатие анти-материи»: урон босса снижен на 20%%!" % zero)
		bm.spend_xaeroh(mini(zero, 10))
	bm.log_message("🌌 %s применяет «Сжатие анти-материи» по отряду!" % enemy.display_name)
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res := DamageCalculator.calc_damage(enemy, a, dmg_mult)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))

# 4. «Сингулярность забвения» (Фаза 2, AoE 105% СА + Зона коллапса на 3 стака)
static func _skill_singularity_of_oblivion(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	bm.log_message("🕳 %s разворачивает «Сингулярность забвения»! Активирована Зона коллапса (3 стака: -20%% входящего урона)!" % enemy.display_name)
	enemy.set_meta("rimes_collapse_zone_stacks", 3)
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res := DamageCalculator.calc_damage(enemy, a, 1.05)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))

# 5. «Инверсия горизонтов» (Фаза 2/3: бьет 2 случайных союзников по 115% СА)
static func _skill_horizon_inversion(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var living: Array[CombatUnit] = []
	for a in allies:
		if a is CombatUnit and a.is_alive():
			living.append(a)
	if living.is_empty():
		return
	living.shuffle()
	var hit_count := mini(living.size(), 2)
	bm.log_message("🔀 %s использует «Инверсию горизонтов» по %d целям!" % [enemy.display_name, hit_count])
	for i in hit_count:
		var target: CombatUnit = living[i]
		var res := DamageCalculator.calc_damage(enemy, target, 1.15)
		bm.deal_damage(target, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))

# 6. «Пульсация сингулярности» (Фаза 3: AoE 90% СА, урон падает на 1% за каждое Зеро, кап 50%)
static func _skill_singularity_pulsation(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	var zero: int = bm.get_xaeroh()
	var red_pct: float = minf(float(zero) * 0.005, 0.50)
	var mult: float = 0.90 * (1.0 - red_pct)
	bm.log_message("🌌 %s сотрясает поле «Пульсацией сингулярности»! Защитное поле Зеро (%d) поглощает %.1f%% урона!" % [
		enemy.display_name, zero, red_pct * 100.0
	])
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res := DamageCalculator.calc_damage(enemy, a, mult)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))

# 7. Разрешение ультимейта «По воле дирижёра»
static func _resolve_conductor_will(enemy: CombatUnit, allies: Array, bm: BattleManager) -> void:
	enemy.set_meta("rimes_conductor_charging", false)
	
	# Считаем живые Лапы Ничто
	var live_paws: Array[CombatUnit] = []
	for e in bm.enemies:
		if e.is_alive() and e.id == "void_paws":
			live_paws.append(e)
			
	if live_paws.is_empty():
		# Все лапы уничтожены -> срыв атаки!
		bm.log_message("💥 СРЫВ АТАКИ! Все «Лапы Ничто» уничтожены! Сверхспособность Раймса сорвана, босс теряет 30%% Защиты на 2 хода!")
		enemy.set_meta("rimes_conductor_stagger_turns", 2)
		bm.apply_def_reduction(enemy, "Срыв Дирижёра", 0.30, 2)
		return

	# Лапы живы -> сокрушительный удар босса + атака каждой лапы
	bm.log_message("👑 СВЕРХСПОСОБНОСТЬ «ПО ВОЛЕ ДИРИЖЁРА»! Раймс и %d Лап Ничто обрушивают симфонию разрушения!" % live_paws.size())
	
	# Удар Раймса
	for a in allies:
		if a is CombatUnit and a.is_alive():
			var res := DamageCalculator.calc_damage(enemy, a, 1.40)
			bm.deal_damage(a, float(res.get("damage", 0.0)), enemy, CombatConstants.Element.QUANTUM, bool(res.get("crit", false)))

	# Каждая лапа наносит урон и выжигает энергию
	var zero: int = bm.get_xaeroh()
	var drain_per_paw: float = maxf(0.0, 15.0 - floor(float(zero) / 20.0) * 5.0)
	var total_drain: float = drain_per_paw * float(live_paws.size())

	for a in allies:
		if a is CombatUnit and a.is_alive():
			for paw in live_paws:
				var p_res := DamageCalculator.calc_damage(paw, a, 0.35)
				bm.deal_damage(a, float(p_res.get("damage", 0.0)), paw, CombatConstants.Element.QUANTUM, bool(p_res.get("crit", false)))
			if total_drain > 0.0:
				a.energy = maxf(0.0, a.energy - total_drain)
				bm.unit_updated.emit(a)
				
	bm.log_message("⚡ «По воле дирижёра»: Лапы Ничто поглотили по %.0f энергии у всех союзников (с учётом Зеро %d)!" % [total_drain, zero])

# 8. Призыв «Лап Ничто»
static func _summon_void_paws(boss: CombatUnit, bm: BattleManager) -> void:
	var VoidPawsScript = load("res://scripts/enemies/void_paws.gd")
	if VoidPawsScript == null:
		return

	# Раймс старается находиться в центре (слот 2 из 0..4)
	if boss.slot_index != 2:
		for e in bm.enemies:
			if e != boss and e.slot_index == 2:
				e.slot_index = boss.slot_index
				break
		boss.slot_index = 2

	# Удаляем старые мёртвые лапы (трупы) с поля боя
	var to_remove: Array[CombatUnit] = []
	for e in bm.enemies:
		if e is CombatUnit and not e.is_alive():
			to_remove.append(e)
	for dead_e in to_remove:
		bm.enemies.erase(dead_e)

	var spawned: int = 0
	# Заполняем позиции вокруг босса: сначала ближние (1 и 3), затем внешние (0 и 4)
	for slot in [1, 3, 0, 4]:
		var slot_occupied := false
		for e in bm.enemies:
			if e.is_alive() and e.slot_index == slot:
				slot_occupied = true
				break
		if not slot_occupied:
			var paw: CombatUnit = VoidPawsScript.create_unit(slot)
			paw.recalculate_action_value()
			paw.action_value = paw.base_action_value
			bm.enemies.append(paw)
			spawned += 1

	# Сортируем противников по слотам (0, 1, 2 [Раймс], 3, 4)
	bm.enemies.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool:
		return a.slot_index < b.slot_index
	)

	if spawned > 0 or not to_remove.is_empty():
		if spawned > 0:
			bm.log_message("🐾 «Зов Бездны»: Раймс занимает центр и призывает %d «Лап Ничто» вокруг себя!" % spawned)
		bm.enemies_reshuffled.emit()
		bm.action_order_changed.emit()
