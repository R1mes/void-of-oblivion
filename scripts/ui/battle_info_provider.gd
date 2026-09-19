class_name BattleInfoProvider
extends RefCounted

static func _src(source: String) -> String:
	if source.is_empty():
		return ""
	return " — источник: %s" % source

static func _is_antimatter_member(unit: CombatUnit) -> bool:
	if unit == null:
		return false
	return FactionSystem.FACTIONS.has("antimatter") and unit.id in FactionSystem.FACTIONS["antimatter"].members

static func _get_dynamic_crit_rate(unit: CombatUnit, allies: Array = []) -> float:
	if unit == null:
		return 0.0
	var cr: float = unit.stats.crit_rate
	if unit.id == "lenskaya":
		var manipulation: int = int(unit.get_meta("lenskaya_manipulation", 0))
		var stat_stacks: int = int(clampi(manipulation, 0, 15))
		cr += float(stat_stacks) * 0.05
	elif unit.id == "lenskaya_sky_guardian":
		var eff_be := unit.get_effective_be()
		cr += minf(eff_be * 0.10, 0.30)
	elif unit.id == "rimes":
		var stacks: int = int(unit.get_meta("rimes_talent_stacks", 0))
		var max_stacks: int = 6 if unit.eidolon >= 1 else 4
		if stacks == max_stacks:
			cr += 0.35
		if unit.has_meta("rimes_isolation_target"):
			cr += 0.20

	var sara_admin_on_field: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "sara_admin" and ally.is_alive():
			sara_admin_on_field = ally
			break
	if sara_admin_on_field and unit.is_ally:
		var v_count: int = int(unit.get_meta("console_vectors", 0))
		if v_count >= 30:
			cr += 0.20

	var velz_on_field: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "velzebul" and ally.is_alive():
			velz_on_field = ally
			break
	if velz_on_field and unit.is_ally:
		var cur_z: int = int(unit.get_meta("antimatter_xaeroh", 0))
		if cur_z == 0 and velz_on_field.has_meta("antimatter_xaeroh"):
			cur_z = int(velz_on_field.get_meta("antimatter_xaeroh", 0))
		var z_tiers: int = mini(6, int(floor(float(cur_z) / 30.0)))
		if z_tiers > 0:
			cr += float(z_tiers) * 0.05

	# Связь Навыка Q Марины • Хранителя небес
	var marina_sg_on_field: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "marina_sky_guardian" and ally.is_alive():
			marina_sg_on_field = ally
			break
	if marina_sg_on_field != null and int(marina_sg_on_field.get_meta("marina_sk_link_turns", 0)) > 0:
		var linked_ally: CombatUnit = marina_sg_on_field.get_meta("marina_sk_linked_ally", null)
		var is_linked := false
		if unit == marina_sg_on_field or unit == linked_ally:
			is_linked = true
		elif unit is Memosprite and (unit.owner == marina_sg_on_field or unit.owner == linked_ally):
			is_linked = true
		if is_linked:
			cr += float(marina_sg_on_field.get_meta("marina_sk_link_crit_rate", 0.0))

	return cr

static func _get_dynamic_ehr(unit: CombatUnit) -> float:
	if unit == null:
		return 0.0
	var eff_ehr: float = unit.stats.effect_hit_rate
	if unit.id == "valramors":
		eff_ehr += unit.stats.crit_rate * 0.35
	return eff_ehr

# Полностью исправленный метод get_stats_text() для scripts/ui/battle_info_provider.gd:
# Полностью заменяем метод get_stats_text() в scripts/ui/battle_info_provider.gd:
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ МЕТОД get_stats_text() В BATTLE_INFO_PROVIDER.GD ===
static func get_stats_text(unit: CombatUnit, allies: Array = []) -> String:
	var s := unit.stats
	var lines: PackedStringArray = []
	
	if unit is Memosprite:
		var owner_name: String = (unit as Memosprite).owner.display_name if (unit as Memosprite).owner != null else "Неизвестен"
		lines.append("[color=cyan]❄ [Дух Памяти] Владелец: %s[/color]" % owner_name)
	
	# Считываем кэшированные оригинальные (чистые) характеристики персонажа
	var base_hp := float(unit.get_meta("base_hp_original", s.max_hp))
	var base_atk := float(unit.get_meta("base_atk_original", s.atk))
	var base_def := float(unit.get_meta("base_def_original", s.def))
	var base_spd := float(unit.get_meta("base_spd_original", s.spd))
	
	# Дополнительные процентные прибавки от реликвий
	var relic_hp_pct := float(unit.get_meta("relic_hp_pct", 0.0)) * 100.0
	var relic_atk_pct := float(unit.get_meta("relic_atk_pct", 0.0)) * 100.0
	var relic_def_pct := float(unit.get_meta("relic_def_pct", 0.0)) * 100.0
	var relic_speed_flat := float(unit.get_meta("relic_speed_flat", 0.0))
	
	# ИСПРАВЛЕНО: Объявляем переменную Обертона во внешнем скоупе, чтобы избежать потери видимости компилятором
	var milena_overtone_pct: float = 0.0
	
	# ИСПРАВЛЕНО: Учет защитных масок Силуэта для Info-панели
	if unit.has_meta("silhouette_mask_def_buff"):
		relic_def_pct += float(unit.get_meta("silhouette_mask_def_buff", 0.0)) * 100.0
	if unit.has_meta("silhouette_mask_def_buff_permanent"):
		relic_def_pct += float(unit.get_meta("silhouette_mask_def_buff_permanent", 0.0)) * 100.0
		
	# ДИНАМИЧЕСКИЙ РАСЧЕТ РЕЛИКВИЙ В РЕАЛЬНОМ ВРЕМЕНИ ДЛЯ ИНФО-ПАНЕЛИ
	
	# 1. Сет Детройта: доп. +12% СА если скорость >= 120 ед.
	var detroit_dynamic_atk_pct := 0.0
	if unit.has_meta("has_set_detroit"):
		if s.get_effective_spd() >= 120.0:
			detroit_dynamic_atk_pct = 0.12
			
	# 2. Сет Лаборатории сгинувшего края: +8% СА всей пати, если скорость носителя >= 120 ед. (суммируется!)
	var lost_edge_count: int = 0
	for ally in allies:
		if ally is CombatUnit and ally.is_alive() and ally.has_meta("has_set_lost_edge"):
			if ally.stats.get_effective_spd() >= 120.0:
				lost_edge_count += 1
				
	var lost_edge_bonus: float = 0.08 * float(lost_edge_count)
				
	# Сборка модификаторов для эффективной СА
	var extra_flat_atk: float = 0.0
	if unit.id == "kaori":
		var total_be: float = unit.stats.break_effect
		if unit.get_meta("weakness_concentration", false):
			total_be += 0.20 if unit.eidolon >= 2 else 0.0
			
		var living_enemies_count: int = 0
		var has_elite: bool = false
		for ally in allies:
			if ally is CombatUnit and not ally.is_ally and ally.is_alive():
				living_enemies_count += 1
				if ally.is_elite:
					has_elite = true
		if living_enemies_count == 1 and has_elite:
			total_be += 0.40
		if total_be > 2.0:
			var excess_be_percent: float = (total_be - 2.0) * 100.0
			extra_flat_atk += excess_be_percent * 15.0

	var q_pct: float = 0.0
	var q_flat: float = 0.0
	if unit.has_meta("arseniy_q_turns") and int(unit.get_meta("arseniy_q_turns", 0)) > 0:
		q_pct = float(unit.get_meta("arseniy_q_atk_percent", 0.0))
		q_flat = float(unit.get_meta("arseniy_q_atk_flat", 0.0))
		
	var faction_pct: float = 0.0
	if unit.has_meta("faction_chaos_atk_pct"):
		faction_pct += float(unit.get_meta("faction_chaos_atk_pct", 0.0))
	if unit.has_meta("faction_empyrean_atk_pct"):
		faction_pct += float(unit.get_meta("faction_empyrean_atk_pct", 0.0))
		
	var lc_pct: float = 0.0
	if unit.has_meta("lc_atk_pct_bonus"):
		lc_pct = float(unit.get_meta("lc_atk_pct_bonus", 0.0))
		
	var milena_flat_atk: float = 0.0
	var milena_unit: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "milena" and ally.is_alive():
			milena_unit = ally
			break
			
	if milena_unit and milena_unit.is_alive() and unit.is_ally:
		var milena_relic_pct: float = float(milena_unit.get_meta("relic_atk_pct", 0.0))
		var milena_eff_atk: float = milena_unit.stats.atk * (1.0 + milena_relic_pct)
		milena_flat_atk += milena_eff_atk * 0.05
		
		# ИСПРАВЛЕНО: Обертон дает +30% СА от собственной базы каждого союзника
		if int(milena_unit.get_meta("milena_overtone_turns", 0)) > 0:
			milena_overtone_pct = 0.30
	
	
	var vika_flat: float = 0.0
	if unit.id == "vika" and unit.has_meta("vika_e_atk_buff"):
		vika_flat = float(unit.get_meta("vika_e_atk_buff", 0.0))
		
	var lenskaya_t3_pct: float = 0.0
	if unit.has_meta("lenskaya_trace3_atk_percent"):
		lenskaya_t3_pct = float(unit.get_meta("lenskaya_trace3_atk_percent", 0.0))
		
	var keloist_flat_atk: float = 0.0
	if unit.has_meta("keloist_flat_atk_buff"):
		keloist_flat_atk = float(unit.get_meta("keloist_flat_atk_buff", 0.0))
	
	var galilean_flat_atk: float = 0.0
	if unit.has_meta("relic_galilean_atk_pct"):
		galilean_flat_atk = unit.stats.atk * float(unit.get_meta("relic_galilean_atk_pct", 0.0))
		
	var silhouette_flat_atk: float = 0.0
	if unit.has_meta("relic_silhouette_atk_pct"):
		silhouette_flat_atk = unit.stats.atk * float(unit.get_meta("relic_silhouette_atk_pct", 0.0))
		
	var standard_pct: float = unit.statuses.self_atk_buff_percent + unit.statuses.atk_buff_percent
	var standard_flat: float = unit.statuses.atk_buff_flat
	
	# Расчет эффективной силы атаки (включая Детройт, Лабораторию и Обертон)
	var eff_atk: float = get_unit_effective_atk_static(unit, allies)

	# Вывод ХП в чистом скобочном формате
	var hp_add_text := " (+%.0f%% реликвии)" % relic_hp_pct if relic_hp_pct > 0.0 else ""
	lines.append("ХП: %d / %d (%d)%s" % [int(s.hp), int(s.max_hp), int(base_hp), hp_add_text])
	
	# Вывод Силы Атаки (СА) в чистом скобочном формате
	var atk_add_text := " (+%.0f%% реликвии)" % relic_atk_pct if relic_atk_pct > 0.0 else ""
	lines.append("СА: %d (%d)%s (эфф. %d)" % [int(s.atk), int(base_atk), atk_add_text, int(eff_atk)])
	
	var def_buff_pct: float = 0.0
	if not unit.is_ally:
		if unit.has_meta("def_reductions"):
			var reds: Dictionary = unit.get_meta("def_reductions")
			for src in reds:
				var d: Dictionary = reds[src]
				if int(d.get("turns", 0)) > 0:
					def_buff_pct -= float(d.get("percent", 0.0))
		var am_count := 0
		var cur_zero_val := 0
		for ally in allies:
			if ally is CombatUnit and ally.is_alive():
				if _is_antimatter_member(ally):
					am_count += 1
				if ally.has_meta("antimatter_xaeroh"):
					cur_zero_val = maxi(cur_zero_val, int(ally.get_meta("antimatter_xaeroh", 0)))
		if am_count >= 2 and cur_zero_val >= 20:
			var am_shred: float = minf(0.75, floor(float(cur_zero_val) / 20.0) * 0.05)
			def_buff_pct -= am_shred

	# Вывод Защиты (ЗАЩ) в чистом скобочном формате
	var def_add_text := " (+%.0f%% реликвии)" % relic_def_pct if relic_def_pct > 0.0 else ""
	var eff_def: float = base_def * (1.0 + (relic_def_pct / 100.0) + def_buff_pct)
	lines.append("ЗАЩ: %d (%d)%s (эфф. %d)" % [int(s.def), int(base_def), def_add_text, int(eff_def)])
	
	# Вывод Скорости (СКР) в чистом скобочном формате с детализацией
	var spd_add_parts: Array[String] = []
	if relic_speed_flat > 0.0:
		spd_add_parts.append("+%d реликвии" % int(relic_speed_flat))
	var spd_pct_b := float(s.get_meta("spd_pct_bonus", 0.0))
	var spd_flat_b := float(s.get_meta("spd_flat_bonus", 0.0))
	if absf(spd_pct_b) > 0.001:
		spd_add_parts.append("%+d%% баффы" % int(spd_pct_b * 100.0))
	if absf(spd_flat_b) > 0.001:
		spd_add_parts.append("%+d плоск. баффы" % int(spd_flat_b))
	var spd_add_text := " (%s)" % ", ".join(spd_add_parts) if not spd_add_parts.is_empty() else ""
	lines.append("СКР: %d (%d)%s" % [int(s.get_effective_spd()), int(base_spd), spd_add_text])
	
	var dynamic_crit_rate: float = _get_dynamic_crit_rate(unit, allies)

	# --- Расчет эффективного Крит. Урона для Инфо-панели ---
	var effective_crit_dmg: float = s.get_effective_crit_dmg(unit.statuses)
	
	if unit.id == "rimes":
		if unit.has_meta("rimes_isolation_target"):
			effective_crit_dmg += 0.80

	# Учет Следа 3 Сары Админа (30+ Векторов -> КУ +50% для всей пати)
	var sara_admin_on_field: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "sara_admin" and ally.is_alive():
			sara_admin_on_field = ally
			break
			
	if sara_admin_on_field and unit.is_ally:
		var v_count: int = int(unit.get_meta("console_vectors", 0))
		if v_count >= 30:
			effective_crit_dmg += 0.50
			
	# Учет Таланта Вельзевул (за каждые 30 Зеро -> +10% КУ для всех союзников)
	var velz_on_field: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "velzebul" and ally.is_alive():
			velz_on_field = ally
			break
			
	if velz_on_field and unit.is_ally:
		var cur_z: int = int(unit.get_meta("antimatter_xaeroh", 0))
		if cur_z == 0 and velz_on_field.has_meta("antimatter_xaeroh"):
			cur_z = int(velz_on_field.get_meta("antimatter_xaeroh", 0))
		var z_tiers: int = mini(6, int(floor(float(cur_z) / 30.0)))
		if z_tiers > 0:
			effective_crit_dmg += float(z_tiers) * 0.10

	# Учет бонуса Крит. урона от резонанса Антиматерии [2]
	if unit.has_meta("antimatter_crit_dmg_turns") and int(unit.get_meta("antimatter_crit_dmg_turns", 0)) > 0:
		effective_crit_dmg += float(unit.get_meta("antimatter_crit_dmg_bonus", 0.0))

	# ИСПРАВЛЕНО: Сет Иркутска: При 5 стаках Подвига Крит. урон повышается на +25%
	if unit.has_meta("has_set_irkutsk"):
		var i_stacks: int = int(unit.get_meta("relic_irkutsk_feat_stacks", 0))
		if i_stacks == 5:
			effective_crit_dmg += 0.25 # Отображаем прибавку КУ на панели информации
			
	var eff_ehr: float = _get_dynamic_ehr(unit)
	if unit.id == "valramors":
		# Учет Следа 3 (+80% КУ и +EHR% СА)
		var is_active := (unit.slot_index == 0) or (unit.eidolon >= 6)
		if is_active:
			effective_crit_dmg += 0.80
			relic_atk_pct += eff_ehr * 100.0
			
	# ИСПРАВЛЕНО: Сверхспособность Айзека: Крит. урон союзника повышен на 100%
	if unit.has_meta("isaac_ult_buff_turns") and int(unit.get_meta("isaac_ult_buff_turns", 0)) > 0:
		effective_crit_dmg += 1.00

	# Учет Следа 1 Марины (+20% КУ для связанных целей и их духов памяти)
	var marina_sg_unit_for_cd: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "marina_sky_guardian" and ally.is_alive():
			marina_sg_unit_for_cd = ally
			break
	if marina_sg_unit_for_cd != null and int(marina_sg_unit_for_cd.get_meta("marina_sk_link_turns", 0)) > 0:
		var linked_ally: CombatUnit = marina_sg_unit_for_cd.get_meta("marina_sk_linked_ally", null)
		var is_linked := false
		if unit == marina_sg_unit_for_cd or unit == linked_ally:
			is_linked = true
		elif unit is Memosprite and (unit.owner == marina_sg_unit_for_cd or unit.owner == linked_ally):
			is_linked = true
		if is_linked:
			effective_crit_dmg += 0.20

	# Учет Таланта Эго (+30% + 13% от КУ Эго) и фракции Свечение (+30%/+45% КУ) для духов памяти
	if unit is Memosprite:
		var ego_unit: Memosprite = null
		if marina_sg_unit_for_cd != null:
			var sp := MemospriteSystem.get_sprite(marina_sg_unit_for_cd, null)
			if sp != null and sp.is_alive():
				ego_unit = sp
		if ego_unit != null:
			effective_crit_dmg += ego_unit.stats.crit_dmg * 0.13 + 0.30
		var radiance_cnt := 0
		for ally in allies:
			if ally is CombatUnit and ally.is_alive():
				if FactionSystem.FACTIONS.has("radiance") and ally.id in FactionSystem.FACTIONS["radiance"].members:
					radiance_cnt += 1
		if radiance_cnt >= 2:
			effective_crit_dmg += 0.45 if radiance_cnt >= 3 else 0.30

	if unit.id == "lenskaya_sky_guardian":
		var eff_be_val := unit.get_effective_be()
		effective_crit_dmg += minf(eff_be_val * 0.50, 1.50)

	lines.append("Крит: %.0f%% / +%.0f%%" % [dynamic_crit_rate * 100.0, effective_crit_dmg * 100.0])
	
	lines.append("ШПЭ: %.0f%%" % [eff_ehr * 100.0])
	
	var base_be := s.break_effect
	var eff_be := unit.get_effective_be()
	lines.append("ЭП: %.0f%% (эфф. %.0f%%)" % [base_be * 100, eff_be * 100])
	
	if unit is Memosprite:
		var cur_ch: int = int(unit.get_charge())
		var max_ch: int = int(unit.charge_comp.max_charge if unit.charge_comp != null else 100.0)
		lines.append("Заряд (Charge): %d / %d" % [cur_ch, max_ch])
	else:
		lines.append("ЭН: %d / %d" % [int(unit.energy), int(unit.max_energy)])
	if unit.max_toughness > 0:
		lines.append("Стойкость: %d / %d" % [int(unit.toughness), int(unit.max_toughness)])
		var weak: PackedStringArray = []
		for w in unit.weaknesses:
			weak.append(CombatConstants.ELEMENT_NAMES.get(w, "?"))
		lines.append("Уязвимости: %s" % ", ".join(weak))
		
	if not unit.is_ally:
		lines.append("\n[color=yellow]Сопротивления урону:[/color]")
		for elem in [CombatConstants.Element.PHYSICAL, CombatConstants.Element.ICE, CombatConstants.Element.FIRE, CombatConstants.Element.WIND, CombatConstants.Element.LIGHTNING, CombatConstants.Element.QUANTUM, CombatConstants.Element.IMAGINARY]:
			var is_weak: bool = elem in unit.weaknesses
			var base_res := 0.0 if is_weak else 20.0
			if elem == CombatConstants.Element.ICE and unit.has_meta("ice_res_bonus"):
				base_res = float(unit.get_meta("ice_res_bonus", 0.40)) * 100.0
			if elem == CombatConstants.Element.IMAGINARY and unit.has_meta("imaginary_res_bonus"):
				base_res = float(unit.get_meta("imaginary_res_bonus", 0.40)) * 100.0
			
			var shred := 0.0
			if elem == CombatConstants.Element.PHYSICAL and unit.has_meta("phys_res_reduced_turns") and int(unit.get_meta("phys_res_reduced_turns", 0)) > 0:
				shred = 20.0
			if elem == CombatConstants.Element.FIRE and unit.has_meta("shoji_fire_res_reduced_turns") and int(unit.get_meta("shoji_fire_res_reduced_turns", 0)) > 0:
				shred = 40.0
			if (elem == CombatConstants.Element.ICE or elem == CombatConstants.Element.QUANTUM) and unit.has_meta("velzebul_ice_quantum_res_turns") and int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)) > 0:
				shred += 20.0
			if unit.has_meta("katarina_all_res_reduction") and int(unit.get_meta("katarina_vuln_turns", 0)) > 0:
				shred += float(unit.get_meta("katarina_all_res_reduction", 0.20)) * 100.0
			elif elem == CombatConstants.Element.PHYSICAL and unit.has_meta("katarina_phys_res_reduction") and int(unit.get_meta("katarina_vuln_turns", 0)) > 0:
				shred += float(unit.get_meta("katarina_phys_res_reduction", 0.20)) * 100.0
				
			var current_res := base_res - shred
			var elem_name := "Элемент"
			match elem:
				CombatConstants.Element.PHYSICAL: elem_name = "Физический"
				CombatConstants.Element.ICE: elem_name = "Лёд"
				CombatConstants.Element.FIRE: elem_name = "Огонь"
				CombatConstants.Element.WIND: elem_name = "Ветер"
				CombatConstants.Element.LIGHTNING: elem_name = "Электро"
				CombatConstants.Element.QUANTUM: elem_name = "Квант"
				CombatConstants.Element.IMAGINARY: elem_name = "Мнимый"
				
			var color_tag := "green" if is_weak else "red"
			lines.append("  • %s: [color=%s]%.0f%%[/color]%s" % [
				elem_name, 
				color_tag, 
				current_res, 
				" (уязвимость)" if is_weak else ""
			])
			
	return "\n".join(lines)
	

static func get_statuses_text(unit: CombatUnit, allies: Array = []) -> String:
	var buffs: PackedStringArray = []
	var debuffs: PackedStringArray = []
	var st := unit.statuses

	# =========================================================================
	# 1. СБОР УСИЛЕНИЙ (БАФФОВ)
	# =========================================================================
	if st.new_development_turns > 0:
		buffs.append(
			"• Новая разработка (%d действ.)%s: усиленные базовая и Q, доступна сверхспособность." % [
				st.new_development_turns, _src(st.new_development_source),
			],
		)
	if st.patch_turns > 0:
		buffs.append(
			"• Заплатка (%d ход.)%s: хил в свой ход; возврат части урона." % [
				st.patch_turns, _src(st.patch_source),
			],
		)
	if st.atk_buff_turns > 0:
		if st.atk_buff_percent < 0.0:
			# ИСПРАВЛЕНО: Отрицательный бафф СА автоматически перенаправляется в дебаффы (ослабления)
			debuffs.append("• Снижение СА (%d ход.)%s: Сила атаки снижена на %.0f%%." % [st.atk_buff_turns, _src(st.atk_buff_source), -st.atk_buff_percent * 100.0])
		else:
			buffs.append(
				"• Усиление СА (%d ход.)%s: +%.0f%% + %d." % [
					st.atk_buff_turns, _src(st.atk_buff_source),
					st.atk_buff_percent * 100, int(st.atk_buff_flat),
				],
			)
	if st.self_atk_buff_turns > 0:
		buffs.append(
			"• Бафф СА (%d ход.)%s: +%.0f%% к собственной силе атаки." % [
				st.self_atk_buff_turns, _src(st.self_atk_buff_source),
				st.self_atk_buff_percent * 100,
			],
		)
	if st.crit_dmg_buff_turns > 0:
		buffs.append(
			"• Бафф крит. урона (%d ход.)%s: +%.0f%%." % [
				st.crit_dmg_buff_turns, _src(st.crit_dmg_buff_source),
				st.crit_dmg_buff * 100,
			],
		)
	if st.incoming_heal_bonus > 0:
		buffs.append(
			"• +%.0f%% к получаемому лечению%s." % [
				st.incoming_heal_bonus * 100, _src(st.incoming_heal_bonus_source),
			],
		)
	if st.effect_resist_bonus > 0:
		buffs.append(
			"• +%.0f%% к сопротивлению эффектам%s." % [
				st.effect_resist_bonus * 100, _src(st.effect_resist_bonus_source),
			],
		)
	
	if unit.has_meta("lenskaya_trace3_stacks") and int(unit.get_meta("lenskaya_trace3_stacks", 0)) > 0:
		var t3_stacks: int = int(unit.get_meta("lenskaya_trace3_stacks", 0))
		buffs.append("• След 3 Ленской x%d/2 (%d х.): СА повышена на +%d%% за бонус-атаки союзников." % [t3_stacks, int(unit.get_meta("lenskaya_trace3_turns", 0)), t3_stacks * 15])
	
	if unit.has_meta("isaac_theory_stacks") and int(unit.get_meta("isaac_theory_stacks", 0)) > 0:
		buffs.append("• Теория на практике x%d/8: накопление Сверхспособностей. На 8 стаках Q заменяется на Улучшенный Q." % int(unit.get_meta("isaac_theory_stacks", 0)))
		
	if unit.has_meta("isaac_dmg_buff_turns") and int(unit.get_meta("isaac_dmg_buff_turns", 0)) > 0:
		buffs.append("• Наставление Айзека (%d х.): наносимый урон (все типы) повышен на +50%%." % int(unit.get_meta("isaac_dmg_buff_turns", 0)))
		
	if unit.has_meta("isaac_ult_buff_turns") and int(unit.get_meta("isaac_ult_buff_turns", 0)) > 0:
		buffs.append("• Бафф Сверхспособности Айзека (%d х.): Крит. урон повышен на +60%%, скорость на +16 ед." % int(unit.get_meta("isaac_ult_buff_turns", 0)))
	
	if unit.has_meta("mask_layers") and int(unit.get_meta("mask_layers", 0)) > 0:
		buffs.append("• Тайна маски x%d/14: защита Силуэта повышена на +40%%. Получение ударов снижает уровни, но ранит союзника на 3%% макс. ХП." % int(unit.get_meta("mask_layers", 0)))
	if unit.has_meta("silhouette_mask_def_buff_permanent") and float(unit.get_meta("silhouette_mask_def_buff_permanent", 0.0)) > 0.0: # ИСПРАВЛЕНО
		buffs.append("• Сломанная маска (вечный): защита навсегда повышена на +40% (время сброса истекло).")
	
	if unit.has_meta("stage_partner_turns") and int(unit.get_meta("stage_partner_turns", 0)) > 0:
		buffs.append("• Партнёр по сцене (%d х.): СА +15%%, получаемое исцеление +15%%." % int(unit.get_meta("stage_partner_turns", 0)))
		
	if unit.has_meta("blazing_sun_turns") and int(unit.get_meta("blazing_sun_turns", 0)) > 0:
		buffs.append("• Пылающее солнце (%d х.): Сила атаки повышена на +40%%." % int(unit.get_meta("blazing_sun_turns", 0)))
		
	if unit.has_meta("scorching_gaze_next_e_buff"):
		buffs.append("• Палящий взор (конус): следующий Навык Е нанесёт на +30%% больше урона.")
		
	if unit.has_meta("feel_presence_stacks") and not bool(unit.get_meta("feel_presence_completed", false)):
		buffs.append("• Истощение x%d/3 (конус): накопление уникальных дебаффов (ЗАЩ/СКР/СА)." % int(unit.get_meta("feel_presence_stacks", 0)))
		
	if bool(unit.get_meta("feel_presence_completed", false)):
		buffs.append("• Ощути моё присутствие (вечный): наносимый урон +25%, крит. шанс пати +20%.")

	if unit.has_meta("immersion_turns") and int(unit.get_meta("immersion_turns", 0)) > 0:
		buffs.append("• Погружение (%d х.): Бинарный урон союзников +25%%, ВЭ владельца +12%%." % int(unit.get_meta("immersion_turns", 0)))

	if unit.has_meta("refactoring_turns") and int(unit.get_meta("refactoring_turns", 0)) > 0:
		buffs.append("• Рефакторинг (%d х.): ВЭ владельца +15%%, Бинарный урон игнорирует 20%% защиты цели." % int(unit.get_meta("refactoring_turns", 0)))
	
	# Статусы Айзека • Права администратора
	if unit.id == "isaac_admin":
		var h_turns := int(unit.get_meta("isaac_hacked_turns", 0))
		if h_turns > 0:
			buffs.append("• Состояние «Взлом» (%d х.): Базовая атака и Навык Q усилены. (След 1: Бинарный урон пати +20%%)." % h_turns)
		var t2_turns := int(unit.get_meta("isaac_admin_trace2_atk_turns", 0))
		if t2_turns > 0:
			buffs.append("• След 2 (Навык E) (%d х.): Сила атаки повышена на +30%%." % t2_turns)
			
	# Конусы версии 1.1 в панели Инфо союзников
	var active_lc_id: String = unit.get_meta("light_cone_id", "")
	match active_lc_id:
		"quarantine":
			buffs.append("• Поместить в карантин (конус): Сверхспособность владельца продвигает действия всех союзников на 24%.")
		"corrupted_save":
			buffs.append("• Повреждённое сохранение (конус): СКР владельца +18%%, старт боя +10 Векторов.")
		"server_crash_moment":
			buffs.append("• Момент, когда падают сервера (конус): Бинарный урон +40%%.")
		"echoes_of_the_past":
			if unit.has_meta("echoes_spd_buff_turns") and int(unit.get_meta("echoes_spd_buff_turns", 0)) > 0:
				buffs.append("• Конус Отголоски прошлого (%d х.): Скорость повышена на +40%%." % int(unit.get_meta("echoes_spd_buff_turns", 0)))
		"save_the_world_plan":
			var plan_stacks: int = int(unit.get_meta("save_world_plan_stacks", 0))
			if plan_stacks > 0:
				var plan_turns: int = int(unit.get_meta("save_world_plan_turns", 0))
				buffs.append("• Проработка плана x%d/10 (%d х.): СА повышена на +%d%%. При 10 стаках FUA всей пати +20%%." % [plan_stacks, plan_turns, plan_stacks * 4])
		"edge_of_existence":
			var edge_stacks: int = int(unit.get_meta("edge_existence_stacks", 0))
			if edge_stacks > 0:
				buffs.append("• Рубеж Бытия x%d/6: Крит. шанс повышен на +%d%% за атаки." % [edge_stacks, edge_stacks * 3])
				
			var current_spd: float = unit.stats.get_effective_spd()
			if current_spd > 120.0:
				var excess_spd: float = current_spd - 120.0
				var speed_stacks: int = clampi(int(excess_spd / 10.0), 0, 4)
				if speed_stacks > 0:
					buffs.append("• Скорость Рубежа x%d/4: базовые/навык урон +%d%%, КУ ультимейта +%d%%." % [speed_stacks, speed_stacks * 5, speed_stacks * 15])
		"first_minutes_of_war":
			buffs.append("• Первые минуты войны (конус): Получаемый урон снижен на 20%, ульт восстанавливает 20% макс. ХП.")
		"history_soaked_in_blood":
			buffs.append("• История, вымоченная в крови (конус): СА повышена на +40%.")
			var b_stacks: int = int(unit.get_meta("blood_soaked_dmg_red_stacks", 0))
			buffs.append("• Получаемый урон уменьшен на %d%%. Источник: История, вымоченная в крови" % mini(b_stacks * 3, 30))
			var b_rec := int(float(unit.get_meta("blood_soaked_recorded_dmg", 0.0)))
			buffs.append("• Записанный урон: %d. Следующая Сверхспособность владельца нанесёт ветряной урон каждому поражённому врагу в размере 130%% от записанного значения (200%%, если на поле 1 живой противник). Этот урон не может быть критическим." % b_rec)
		"why_did_you_remember_me":
			buffs.append("• Почему ты вспомнила меня? (конус): СА повышена на +40%.")
			if bool(unit.get_meta("remember_me_in_position", false)):
				var rec_out := int(float(unit.get_meta("remember_me_recorded_outgoing", 0.0)))
				var bonus_20 := int(float(rec_out) * 0.20)
				var elem_str := String(CombatConstants.ELEMENT_NAMES.get(unit.element, "своего типа")).to_lower()
				buffs.append("• Занять позицию: накоплено %d урона. Следующая атака с нанесением урона нанесёт +20%% (%d ед.) %s урона, распределённого поровну между поражёнными целями." % [rec_out, bonus_20, elem_str])
		"behind_the_curtains":
			buffs.append("• Выход из-за кулис (конус): Крит. шанс +22%. При трате Зеро восстанавливает 20% от потраченных Зеро в виде энергии.")
			if unit.has_meta("btc_err_turns") and int(unit.get_meta("btc_err_turns", 0)) > 0:
				buffs.append("• Выход из-за кулис [Антиматерия] (%d х.): Скорость восстановления энергии +10%%." % int(unit.get_meta("btc_err_turns", 0)))
			if unit.has_meta("btc_atk_buff_turns") and int(unit.get_meta("btc_atk_buff_turns", 0)) > 0:
				buffs.append("• Выход из-за кулис (%d х.): Сила атаки +30%% (от траты Зеро)." % int(unit.get_meta("btc_atk_buff_turns", 0)))
		"i_will_become_god":
			buffs.append("• Я стану богом (конус): Базовая скорость +12. При нанесении урона накладывает статус «Поклонение» (ЗАЩ -30%, союзники восстанавливают 3 Зеро при атаке цели).")
					
	if unit.has_meta("crimson_tears_atk_pct") and float(unit.get_meta("crimson_tears_atk_pct", 0.0)) > 0.0:
		var ct_pct: float = float(unit.get_meta("crimson_tears_atk_pct", 0.0)) * 100.0
		buffs.append("• [color=green]Баффы Басни о Багровых Слезах (вечный)[/color]: СА повышена на +%.0f%% за побежденных врагов." % ct_pct)
		
	if unit.get_meta("light_cone_id", "") == "moment_of_happiness":
		buffs.append("• [color=green]Конус Мгновение счастья (вечный)[/color]: Базовая сила атаки повышена на +40%.")
	
	# Баффы Сары • Права администратора
	if unit.has_meta("sara_ult_res_pen_turns") and int(unit.get_meta("sara_ult_res_pen_turns", 0)) > 0:
		buffs.append("• Пробитие сопротивления Сары (%d х.): +20%% ко ВСЕМ типам сопротивления." % int(unit.get_meta("sara_ult_res_pen_turns", 0)))
	if unit.has_meta("sara_e1_spd_turns") and int(unit.get_meta("sara_e1_spd_turns", 0)) > 0:
		buffs.append("• Ускорение Сары Е1 (%d х.): Скорость повышена на +30%%." % int(unit.get_meta("sara_e1_spd_turns", 0)))
	
	if unit.has_meta("dasha_ult_binary_turns") and int(unit.get_meta("dasha_ult_binary_turns", 0)) > 0:
		buffs.append("• Протокол Даши (%d х.): Бинарный урон отряда повышен на +50%%." % int(unit.get_meta("dasha_ult_binary_turns", 0)))
		
	if unit.has_meta("dasha_e6_binary_turns") and int(unit.get_meta("dasha_e6_binary_turns", 0)) > 0:
		buffs.append("• Консоль [E6] (%d х.): Бинарный урон повышен на +30%%." % int(unit.get_meta("dasha_e6_binary_turns", 0)))
		
	# Отображение бонуса от Цифрового следа (прочность щитов)
	if unit.has_meta("dasha_digital_footprint") and int(unit.get_meta("dasha_digital_footprint", 0)) > 0:
		var fp: int = int(unit.get_meta("dasha_digital_footprint", 0))
		buffs.append("• Цифровой след x%d/30: прочность щитов повышена на +%d%%." % [fp, fp * 3])

	# Статусы Катарины
	if unit.has_meta("katarina_just_a_memory_turns") and int(unit.get_meta("katarina_just_a_memory_turns", 0)) > 0:
		buffs.append("• «Лишь воспоминание» (%d х.): Невосприимчивость к любому урону! При выходе восстановит 50 энергии." % int(unit.get_meta("katarina_just_a_memory_turns", 0)))
	if bool(unit.get_meta("katarina_prove_it_active", false)):
		buffs.append("• «Докажи» [Катарина]: Скорость +40% (сбрасывается при получении урона).")
	if unit.has_meta("katarina_q_ally_atk_buff_turns") and int(unit.get_meta("katarina_q_ally_atk_buff_turns", 0)) > 0:
		buffs.append("• «Вкус крови» [Катарина] (%d х.): Сила атаки +15%%." % int(unit.get_meta("katarina_q_ally_atk_buff_turns", 0)))

	# Статусы Доцевой • Багровые слёзы
	if bool(unit.get_meta("doceva_tears_zone_active", false)):
		var z_turns: int = int(unit.get_meta("doceva_tears_zone_turns", 0))
		buffs.append("• Защитная Зона [Доцева] (%d х.): перенаправление урона союзников на Доцеву." % z_turns)
	if unit.has_meta("doceva_tears_guarded_immune") and bool(unit.get_meta("doceva_tears_guarded_immune")):
		buffs.append("• Защита Зоны [Доцева]: Иммунитет к урону (100% урона перенаправляется в Доцеву). Крит. шанс повышен на 20%.")
	if unit.has_meta("doceva_tears_ally_damage_reduced") and bool(unit.get_meta("doceva_tears_ally_damage_reduced")):
		buffs.append("• Защита Зоны [Доцева]: Получаемый урон уменьшен на 70% (перенаправляется в Доцеву).")
	if unit.has_meta("doceva_tears_atk_buff_pct") and float(unit.get_meta("doceva_tears_atk_buff_pct", 0.0)) > 0.0:
		var pct_val: int = int(float(unit.get_meta("doceva_tears_atk_buff_pct", 0.0)) * 100.0)
		buffs.append("• «Закрой глаза» [Доцева]: СА всех союзников +%d%%." % pct_val)
	if bool(unit.get_meta("doceva_tears_e4_active", false)):
		buffs.append("• Эйдолон 4 Доцевой: Максимальное ХП +30% во время действия Зоны.")

	# Бафф Следа 1 Катарины (для союзников Небытия и самой Катарины)
	if unit.is_ally:
		var kat_ref: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.is_alive() and ally.id == "katarina":
				kat_ref = ally
				break
		if kat_ref != null:
			if kat_ref.eidolon >= 6:
				buffs.append("• След 1 Катарины (E6): Крит. урон повышен на +100% (источник: Катарина).")
			elif unit.id == "katarina" or unit.path == CombatConstants.Path.NIHILITY:
				var nihility_count := 0
				for ally in allies:
					if ally is CombatUnit and ally.is_alive() and ally.path == CombatConstants.Path.NIHILITY:
						nihility_count += 1
				var cd_pct := 0
				match nihility_count:
					1: cd_pct = 10
					2: cd_pct = 30
					3: cd_pct = 70
					4: cd_pct = 80
					_: cd_pct = 80 if nihility_count > 4 else 0
				if cd_pct > 0:
					buffs.append("• След 1 Катарины: Крит. урон повышен на +%d%% за %d союзник(ов) Пути Небытия (источник: Катарина)." % [cd_pct, nihility_count])
		
	# Статусы Ленской • Хранитель небес
	if unit.has_meta("lenskaya_enhanced_basic_turns") and int(unit.get_meta("lenskaya_enhanced_basic_turns", 0)) > 0:
		buffs.append("• Усиленная базовая атака (%d х.): 6 ударов по 30%% СА (всего 180%% СА), истощение 30 стойкости." % int(unit.get_meta("lenskaya_enhanced_basic_turns", 0)))
	if unit.has_meta("lenskaya_ult_be_turns") and int(unit.get_meta("lenskaya_ult_be_turns", 0)) > 0:
		buffs.append("• Эффект пробития (%d х.): собственный ЭП +40%% (Сверхспособность Ленской)." % int(unit.get_meta("lenskaya_ult_be_turns", 0)))
	if unit.has_meta("lenskaya_trace2_be_turns") and int(unit.get_meta("lenskaya_trace2_be_turns", 0)) > 0:
		buffs.append("• Эффект пробития (%d х.): +40%% ЭП от Сверхспособности Ленской (След 2)." % int(unit.get_meta("lenskaya_trace2_be_turns", 0)))

	# =========================================================================
	# СТАТУСЫ КОНСОЛИ И САРЫ • ПРАВА АДМИНИСТРАТОРА
	# =========================================================================
	if unit.is_ally:
		# 1. Поиск Сары Админа на поле боя
		var sara_adm_ref: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.id == "sara_admin" and ally.is_alive():
				sara_adm_ref = ally
				break
				
		# 2. Считывание текущего пула Векторов Консоли
		var console_vectors: int = 0
		for ally in allies:
			if ally is CombatUnit:
				if ally.has_meta("console_vectors"):
					console_vectors = maxi(console_vectors, int(ally.get_meta("console_vectors", 0)))
				if ally.has_meta("isaac_vectors"):
					console_vectors = maxi(console_vectors, int(ally.get_meta("isaac_vectors", 0)))
					
		# БАФФ 1: Повышение Бинарного урона от Векторов (+1% за каждый Вектор)
		if console_vectors > 0:
			buffs.append("• Протокол Векторов: Бинарный урон повышен на [color=cyan]+%d%%[/color] (от %d Векторов Консоли)." % [console_vectors, console_vectors])
			
		# БАФФ 2: Зона Сары «Среда разработки» (динамический расчет от скорости Сары выше 100)
		if sara_adm_ref and int(sara_adm_ref.get_meta("sara_dev_env_turns", 0)) > 0:
			var env_turns: int = int(sara_adm_ref.get_meta("sara_dev_env_turns", 0))
			var spd_over: float = maxf(sara_adm_ref.stats.get_effective_spd() - 100.0, 0.0)
			var env_bonus: int = int(minf(spd_over, 60.0))
			buffs.append("• Среда разработки (%d х.) [Сара]: Бинарный урон повышен на [color=cyan]+%d%%[/color] (от скорости Сары выше 100)." % [env_turns, env_bonus])

		# БАФФ 3: След 3 Сары (при 30+ Векторах)
		if sara_adm_ref and console_vectors >= 30:
			buffs.append("• След 3 Сары (30+ Векторов): Крит. шанс [color=green]+20%[/color], Крит. урон [color=green]+50%[/color].")

	# Ускорение Е1 Сары
	if unit.has_meta("sara_e1_spd_turns") and int(unit.get_meta("sara_e1_spd_turns", 0)) > 0:
		buffs.append("• Ускорение Сары Е1 (%d х.): Скорость повышена на +30%%." % int(unit.get_meta("sara_e1_spd_turns", 0)))

	# Пробитие сопротивления от ультимейта Сары
	if unit.has_meta("sara_ult_res_pen_turns") and int(unit.get_meta("sara_ult_res_pen_turns", 0)) > 0:
		buffs.append("• Пробитие сопротивления Сары (%d х.): +20%% ко ВСЕМ типам сопротивления." % int(unit.get_meta("sara_ult_res_pen_turns", 0)))

	# Техника Сары
	if unit.has_meta("sara_tech_binary_turns") and int(unit.get_meta("sara_tech_binary_turns", 0)) > 0:
		buffs.append("• Техника Сары (%d х.): Бинарный урон повышен на [color=cyan]+30%%[/color]." % int(unit.get_meta("sara_tech_binary_turns", 0)))

	# Статусы Сёдзи • Лебединое озеро
	if unit.id == "shoji_swan":
		var stance: String = String(unit.get_meta("shoji_swan_stance", ""))
		if stance == "virus":
			var e2_desc: String = " (E2: Бинарный урон союзников +50%, КУ +1% за Вектор)" if unit.eidolon >= 2 else ""
			buffs.append("• Стойка «Вирус» [Слот 1] (ДД): Враги получают +60%% Бинарного урона, Навык Q наносит Бинарный взрывной урон, урон ульты +40%%%s." % e2_desc)
		elif stance == "dance":
			buffs.append("• Стойка «Танец» [Слот 2-4] (Саппорт): Скорость команды +16%%, не-Бинарный урон +25%%. Весь Бинарный урон Сёдзи становится обычным. Q задерживает врагов. След 3: даёт ДД пробитие всех сопротивлений.")
		if unit.get_meta("shoji_swan_enhanced_basic", false):
			buffs.append("• Взрывной аккорд [Сёдзи]: Следующая базовая атака усилена (125%% цели / 35%% соседям, +13 Векторов).")
		if unit.has_meta("shoji_swan_trace2_spd_turns") and int(unit.get_meta("shoji_swan_trace2_spd_turns", 0)) > 0:
			buffs.append("• След 2 Сёдзи (%d х.): Скорость повышена на +20%%." % int(unit.get_meta("shoji_swan_trace2_spd_turns", 0)))

	if unit.has_meta("shoji_swan_dance_ally_buff"):
		buffs.append("• Танец Сёдзи (постоянный): Скорость повышена на +16%%, не-Бинарный урон отряда на +25%%.")

	if unit.has_meta("shoji_swan_atk_turns") and int(unit.get_meta("shoji_swan_atk_turns", 0)) > 0:
		buffs.append("• Разрядка Векторов [Сёдзи] (%d х.): Сила атаки повышена на +50%%." % int(unit.get_meta("shoji_swan_atk_turns", 0)))
				
		
	if unit.id == "joan_spirit":
		var in_spirit: bool = unit.get_meta("joan_spirit_form", false)
		var wishes: int = int(unit.get_meta("joan_last_wish", 0))
		var regrets: int = int(unit.get_meta("joan_regret", 0))
		var gold: int = int(unit.get_meta("joan_gold_remnants", 0))
		
		if in_spirit:
			buffs.append("• Форма духа: урон по Жоану снижен на 40%, открыт весь арсенал умений.")
		if wishes > 0:
			buffs.append("• Последнее желание x%d/12: энергия для активации Сверхспособности." % wishes)
		if regrets > 0:
			buffs.append("• Сожаление x%d/7: расходуется на применение Навыка E." % regrets)
	
	# Бафф Остатков золота Жоана в панели Инфо каждого союзника
	var joan_spirit_ref: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "joan_spirit" and ally.is_alive():
			joan_spirit_ref = ally
			break
			
	if joan_spirit_ref and unit.is_ally:
		var gold_stacks: int = int(joan_spirit_ref.get_meta("joan_gold_remnants", 0))
		if gold_stacks > 0:
			buffs.append("• Остатки золота x%d/12 (Жоан): Сила атаки повышена на +%d%%." % [gold_stacks, gold_stacks * 4])
			
	if unit.get_meta("light_cone_id", "") == "crimson_tears":
		buffs.append("• [color=green]Конус Басня о Багровых Слезах (вечный)[/color]: Базовая сила атаки повышена на +45%.")
		
	if unit.has_meta("untargetable") and unit.get_meta("untargetable"):
		buffs.append("• Недосягаемость: враги не могут выбрать этого персонажа целью одиночных умений.")
	
	if unit.has_meta("vika_awakening_turns") and int(unit.get_meta("vika_awakening_turns", 0)) > 0:
		if unit.eidolon < 6:
			buffs.append("• Пробуждение (%d х.): наносимый Викой урон снижен на 20%%, Вика восстанавливает 30%% от своего макс. хп в начале каждого хода" % int(unit.get_meta("vika_awakening_turns", 0)))
		else:
			buffs.append("• Пробуждение (%d х.): наносимый Викой урон УВЕЛИЧЕН на 20%%, Вика восстанавливает 30%% от своего макс. хп в начале каждого хода" % int(unit.get_meta("vika_awakening_turns", 0)))
		
	if unit.has_meta("keloist_command_stacks") and int(unit.get_meta("keloist_command_stacks", 0)) > 0:
		var command: int = int(unit.get_meta("keloist_command_stacks", 0))
		buffs.append("• Командование x%d/20: Крит.шанс Келойста повышен на +%d%%, Сила атаки союзников повышена на +%d%% от СА Келойста." % [command, command * 3, command * 2])
		
	if unit.has_meta("keloist_orthoshield_turns") and int(unit.get_meta("keloist_orthoshield_turns", 0)) > 0:
		buffs.append("• Ортощит (%d х.): получаемый урон снижен на 40%%, сила атаки повышена на 20%%. Нанесение урона союзником вызывает огненную атаку Келойста." % int(unit.get_meta("keloist_orthoshield_turns", 0)))
		
	if unit.has_meta("adversary_buff_turns"):
		var adv_t: int = int(unit.get_meta("adversary_buff_turns", 0))
		if adv_t > 0:
			buffs.append("• [color=green]Конус Нападение (%d х.)[/color]: Крит. шанс повышен на 24%%." % adv_t)
			
	if unit.has_meta("weakness_concentration") and unit.get_meta("weakness_concentration"):
		buffs.append("• Концентрация на слабости: следующая базовая атака Каори станет усиленной.")
		
	if unit.has_meta("in_fog_buff") and unit.get_meta("in_fog_buff"):
		buffs.append("• В тумане (усиление): следующая атака нанесет на 100% больше Физ. урона.")
		
	if unit.has_meta("circle_dance") and unit.get_meta("circle_dance"):
		buffs.append("• Танец кругов: усилена базовая атака, открыт доступ к Навыку Q и Сверхспособности.")
	
	# === НАЙДИТЕ И ДОБАВЬТЕ ЭТОТ БЛОК В СЕКЦИЮ БАФФОВ МЕТОДА get_statuses_text() ===
	if unit.id == "valramors" or unit.element == CombatConstants.Element.QUANTUM:
		# Находим живого Валраморса в вашей пати
		var valramors_ref: CombatUnit = null
		for ally in allies:
			if ally.is_alive() and ally.id == "valramors":
				valramors_ref = ally
				break
				
		if valramors_ref:
			var q_count := 0
			for ally in allies:
				if ally.is_alive() and ally.element == CombatConstants.Element.QUANTUM:
					q_count += 1
					
			if valramors_ref.eidolon >= 2:
				var pen_val := 30.0 if q_count >= 2 else 20.0
				buffs.append("• Е2 Валраморса (%d Квант. союзн.): Сопротивление ВСЕМ типам урона у всех врагов снижено на -%.0f%%." % [q_count, pen_val])
			else:
				var pen_val := 0.0
				if q_count >= 4: pen_val = 30.0
				elif q_count >= 3: pen_val = 20.0
				elif q_count >= 2: pen_val = 10.0
				if pen_val > 0.0:
					buffs.append("• След 1 Валраморса (%d Квант. союзн.): Квантовое пробитие сопротивления всей команды повышено на +%.0f%%." % [q_count, pen_val])
					
	if unit.has_meta("overload_turns") and int(unit.get_meta("overload_turns", 0)) > 0:
		buffs.append("• Перегрузка (%d ход.): Навык Q не потребляет ОН, а бонус-атаки наносят огромный урон." % int(unit.get_meta("overload_turns", 0)))
		
	if unit.has_meta("pirouette_stacks") and int(unit.get_meta("pirouette_stacks", 0)) > 0:
		buffs.append("• Пируэт x%d/3: при накоплении 3 стаков проводит моментальную бонус-атаку." % int(unit.get_meta("pirouette_stacks", 0)))
		
	if unit.has_meta("hell_armor") and unit.get_meta("hell_armor"):
		buffs.append("• Адская броня: получаемый рыцарем урон снижен на 40%. Пробитие разрушит броню и нанесет x2 урон.")

	if unit.has_meta("server_virus_firewall") and int(unit.get_meta("server_virus_firewall", 0)) > 0:
		var fw := int(unit.get_meta("server_virus_firewall", 0))
		buffs.append("• Файрвол x%d/4: не-Бинарный урон снижен на 25%%. Разрушается каждым ударом Бинарного урона." % fw)
	
	if unit.has_meta("inevitable_fall_wrath_turns") and int(unit.get_meta("inevitable_fall_wrath_turns", 0)) > 0:
		var wrath_turns: int = int(unit.get_meta("inevitable_fall_wrath_turns", 0))
		buffs.append("• Проявление Гнева (%d х.) [color=yellow](конус)[/color]: наносимый урон повышен на +30%%, но в начале своего хода персонаж теряет 1%% от макс. ХП." % wrath_turns)
		
	if unit.has_meta("milena_be_buff"):
		var be_val: float = float(unit.get_meta("milena_be_buff", 0.0)) * 100.0
		buffs.append("• Талант Милены: Эффект пробития повышен на +%.0f%%." % be_val)

	if unit.has_meta("mnema_reverence_stacks") and int(unit.get_meta("mnema_reverence_stacks", 0)) > 0:
		var mn_stk: int = int(unit.get_meta("mnema_reverence_stacks", 0))
		buffs.append("• Почитание памяти x%d/4 [color=yellow](конус «Нити мнемы»)[/color]: наносимый урон повышен на +%d%%." % [mn_stk, mn_stk * 8])

	if unit.has_meta("burned_page_turns") and int(unit.get_meta("burned_page_turns", 0)) > 0:
		var bp_t: int = int(unit.get_meta("burned_page_turns", 0))
		buffs.append("• Сгоревшая страница (%d х.) [color=yellow](конус)[/color]: скорость повышена на +8%%, макс. HP повышено на +15%%." % bp_t)

	if unit.get_meta("light_cone_id", "") == "let_past_stay_behind":
		buffs.append("• Пусть прошлое остаётся позади [color=yellow](конус)[/color]: Крит. урон повышен на +36%%.")

	if unit.has_meta("milena_overtone_spd_active") and unit.get_meta("milena_overtone_spd_active", false):
		buffs.append("• Бафф Обертона (Милена): Скорость повышена на 15%, Сила атаки увеличена на 30%")
		
	if unit.has_meta("vika_e_atk_buff"):
		var vika_e_buff: float = float(unit.get_meta("vika_e_atk_buff", 0.0))
		var vika_e_turns: float = float(unit.get_meta("vika_e_atk_turns", 0.0))
		buffs.append("• Бафф Навыка Е (Вика): Сила атаки увеличена на %d единиц на %d хода" % [vika_e_buff, vika_e_turns])
		
	if unit.has_meta("second_chance_active") and int(unit.get_meta("second_chance_active", 0)) > 0:
		buffs.append("• Второй шанс (Милена След 3): если персонаж убьет врага на этом ходу, он исцелит 20%% макс. ХП!")
	
	if unit.has_meta("lenskaya_manipulation") and int(unit.get_meta("lenskaya_manipulation", 0)) > 0:
		var manipulation: int = int(unit.get_meta("lenskaya_manipulation", 0))
		var stat_stacks: int = int(clampi(manipulation, 0, 15))
		buffs.append("• Манипуляция x%d: Крит.шанс Ленской +%d%%, урон всех бонус-атак +%d%% (стаки свыше 15 усиливают урон Е)." % [manipulation, stat_stacks * 5, stat_stacks * 6])
	
	if unit.has_meta("valramors_corruption_transfer") and bool(unit.get_meta("valramors_corruption_transfer")):
		buffs.append("• Передача порчи: следующая атака этого союзника по противникам срежет их защиту на -40% на 3 хода.")
	if unit.has_meta("valramors_tech_ignore_turns") and int(unit.get_meta("valramors_tech_ignore_turns", 0)) > 0:
		buffs.append("• Техника Валраморса (%d х.): союзник игнорирует 15%% защиты противников." % int(unit.get_meta("valramors_tech_ignore_turns", 0)))
	
	if unit.has_meta("lenskaya_stinger_turns") and int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0:
		buffs.append("• Состояние «Жало» (%d х.): базовая атака и Q Ленской усилены." % int(unit.get_meta("lenskaya_stinger_turns", 0)))
		
	if unit.has_meta("lenskaya_tech_fua_buff_turns") and int(unit.get_meta("lenskaya_tech_fua_buff_turns", 0)) > 0:
		buffs.append("• Бафф Техники Ленской (%d х.): урон бонус-атак союзников повышен на 40%%." % int(unit.get_meta("lenskaya_tech_fua_buff_turns", 0)))
	
	if unit.has_meta("musienko_annihilation_active") and unit.get_meta("musienko_annihilation_active", false):
		var spd_b := int(float(unit.get_meta("musienko_annihilation_spd_bonus", 0.0)))
		var e2_desc := " (Здоровье ограничено до 60%, бессмертие от врагов)" if unit.eidolon >= 2 else ""
		buffs.append("• Аннигиляция бытия: Навыки Q усилены, скорость повышен на +%d ед.%s." % [spd_b, e2_desc])
		
	if unit.has_meta("musienko_retribution_stacks") and int(unit.get_meta("musienko_retribution_stacks", 0)) > 0:
		buffs.append("• Кровавое возмездие x%d/6: при накоплении 6 стаков проводит АоЕ бонус-атаку и исцеляется на 30%%." % int(unit.get_meta("musienko_retribution_stacks", 0)))
		
	if unit.has_meta("musienko_e4_cd_turns") and int(unit.get_meta("musienko_e4_cd_turns", 0)) > 0:
		buffs.append("• Е4 Мусиенко (%d х.): Крит. урон повышен на +60%%." % int(unit.get_meta("musienko_e4_cd_turns", 0)))
		
	if unit.id == "dotseva":
		var cal_stacks: int = int(unit.get_meta("dotseva_calibration_stacks", 0))
		if cal_stacks > 0:
			var cal_turns: int = int(unit.get_meta("dotseva_calibration_turns", 0))
			var max_stacks: int = 30
			if unit.eidolon >= 2:
				max_stacks = 40
			buffs.append("• Калибровка x%d/%d (%d х.): наносит урон при максимуме." % [cal_stacks, max_stacks, cal_turns])
			
		var fog_turns: int = int(unit.get_meta("dotseva_fog_turns", 0))
		if fog_turns > 0:
			var e4_desc: String = ""
			if unit.eidolon >= 4:
				e4_desc = " (СА увеличена на +%d ед. от Е4)" % (cal_stacks * 35)
			buffs.append("• Состояние «Лёгкий туман» (%d х.): базовые умения Доцевой усилены%s." % [fog_turns, e4_desc])
			
	if unit.id == "milena":
		var overtone: int = int(unit.get_meta("milena_overtone_turns", 0))
		if overtone > 0:
			buffs.append("• Обертон (%d х.): СА союзников повышена на 30%% от СА Милены, скорость на 15%%. Пробитие задерживает цель на доп. 50%%." % overtone)
	
	if unit.id == "jeff":
		var active_jeff := unit.has_meta("jeff_make_noise_active") and bool(unit.get_meta("jeff_make_noise_active"))
		if active_jeff:
			buffs.append("• Статус «Пошумите!»: базовая атака любого союзника спровоцирует АоЕ-хил и Бонус-атаку Джеффа.")
		if unit.has_meta("jeff_trace3_heal_turns") and int(unit.get_meta("jeff_trace3_heal_turns", 0)) > 0:
			buffs.append("• Бафф хилла от Следа 3 (%d х.): исходящее исцеление Джеффа повышено на +20%%." % int(unit.get_meta("jeff_trace3_heal_turns", 0)))
		
	if unit.has_meta("faction_crit_bonus"):
		var cr_val: float = float(unit.get_meta("faction_crit_bonus", 0.0)) * 100.0
		buffs.append("• Синергия Обреченных: Крит. шанс повышен на +%.0f%%." % cr_val)
	
	# Синергии Консоли
	if unit.has_meta("faction_console_spd"):
		buffs.append("• Синергия Консоли [2]: скорость повышена на +10%.")
	if unit.has_meta("faction_console_full_access"):
		buffs.append("• Синергия Консоли [4]: Бинарный урон повышен на +20%.")

	# Бафф Следа 3 Сары (30+ Векторов)
	var sara_adm_ref: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "sara_admin" and ally.is_alive():
			sara_adm_ref = ally
			break
			
	if sara_adm_ref and unit.is_ally:
		var v_count: int = int(unit.get_meta("console_vectors", 0))
		if v_count >= 30:
			buffs.append("• След 3 Сары (30+ Векторов): Крит. шанс [color=green]+20%[/color], Крит. урон [color=green]+50%[/color].")

	if unit.has_meta("sara_ult_res_pen_turns") and int(unit.get_meta("sara_ult_res_pen_turns", 0)) > 0:
		buffs.append("• Пробитие сопротивления Сары (%d х.): +20%% ко ВСЕМ типам сопротивления." % int(unit.get_meta("sara_ult_res_pen_turns", 0)))
	if unit.has_meta("sara_e1_spd_turns") and int(unit.get_meta("sara_e1_spd_turns", 0)) > 0:
		buffs.append("• Ускорение Сары Е1 (%d х.): Скорость повышена на +30%%." % int(unit.get_meta("sara_e1_spd_turns", 0)))
	if unit.has_meta("sara_tech_binary_turns") and int(unit.get_meta("sara_tech_binary_turns", 0)) > 0:
		buffs.append("• Техника Сары (%d х.): Бинарный урон повышен на +30%%." % int(unit.get_meta("sara_tech_binary_turns", 0)))
		
	if unit.has_meta("faction_chaos_atk_hp"):
		buffs.append("• Синергия Рассвета Хаоса: СА и макс. ХП повышены на +15%.")
		
	if unit.has_meta("faction_empyrean_atk"):
		buffs.append("• Синергия Эмпирейцев: сила атаки повышена на +30%.")
		
	if unit.has_meta("faction_empyrean_crit_turns") and int(unit.get_meta("faction_empyrean_crit_turns", 0)) > 0:
		var turns: int = int(unit.get_meta("faction_empyrean_crit_turns", 0))
		buffs.append("• Синергия Эмпирейцев [4] (%d х.): Крит. шанс зафиксирован на 100%%!" % turns)
		
	if unit.has_meta("faction_academy_spd"):
		buffs.append("• Синергия Академии [2]: скорость всех союзников повышена на +8%.")
		
	if unit.has_meta("academy_dmg_bonus_turns") and int(unit.get_meta("academy_dmg_bonus_turns", 0)) > 0:
		var turns: int = int(unit.get_meta("academy_dmg_bonus_turns", 0))
		buffs.append("• Синергия Академии [3] (%d х.): наносимый урон повышен на +30%% (от лечения/щита)." % turns)
	
	# Вывод стаков новых наборов реликвий версии 1.1
	if unit.has_meta("relic_galilean_stacks") and int(unit.get_meta("relic_galilean_stacks", 0)) > 0:
		var g_stacks: int = int(unit.get_meta("relic_galilean_stacks", 0))
		buffs.append("• Сет Галилеянина x%d/8 (%d х.): СА повышена на +%d%% за тики бонус-атак." % [g_stacks, int(unit.get_meta("relic_galilean_turns", 0)), g_stacks * 4])
		
	if unit.has_meta("relic_silhouette_stacks") and int(unit.get_meta("relic_silhouette_stacks", 0)) > 0:
		var s_stacks: int = int(unit.get_meta("relic_silhouette_stacks", 0))
		buffs.append("• Сет Силуэта x%d/5: Сила атаки повышена на +%d%% за получение ударов." % [s_stacks, s_stacks * 5])
		
	if unit.has_meta("relic_sin_stacks") and int(unit.get_meta("relic_sin_stacks", 0)) > 0:
		var s_stacks: int = int(unit.get_meta("relic_sin_stacks", 0))
		buffs.append("• Сет Принявшего грех x%d/6 (%d х.): Крит. шанс повышен на +%d%% за потери здоровья." % [s_stacks, int(unit.get_meta("relic_sin_turns", 0)), s_stacks * 5])
		
	# --- ПЛАНАРНЫЕ РЕЛИКВИИ: ПАССИВНЫЕ ЭФФЕКТЫ ---
	var dyn_cr: float = _get_dynamic_crit_rate(unit, allies)
	var dyn_ehr: float = _get_dynamic_ehr(unit)

	# 1. Другая сторона вселенной: Крит. шанс >= 70% -> +20% урон базовой атаки и навыков
	if unit.has_meta("has_set_other_side_universe") or String(unit.get_meta("planar_set", "")) == "other_side_universe":
		if dyn_cr >= 0.70:
			buffs.append("• Другая сторона вселенной [Планарный сет]: Крит. шанс >= 70%% (сейчас %.0f%%) -> урон базовой атаки и навыков повышен на +20%%." % [dyn_cr * 100.0])

	# 2. Сияющий Детройт: Скорость >= 120 -> +12% СА
	if unit.has_meta("has_set_detroit") or String(unit.get_meta("planar_set", "")) == "detroit":
		var eff_spd: float = unit.stats.get_effective_spd()
		if eff_spd >= 120.0:
			buffs.append("• Сияющий Детройт [Планарный сет]: Скорость >= 120 (сейчас %d) -> сила атаки повышена на +12%%." % int(eff_spd))

	# 3. Краснодар - сердце апокалипсиса: Крит. шанс >= 50% -> +15% урон ульты и бонус-атак
	if unit.has_meta("has_set_krasnodar") or String(unit.get_meta("planar_set", "")) == "krasnodar":
		if dyn_cr >= 0.50:
			buffs.append("• Краснодар [Планарный сет]: Крит. шанс >= 50%% (сейчас %.0f%%) -> урон сверхспособности и бонус-атак повышен на +15%%." % [dyn_cr * 100.0])

	# 4. Лаборатория сгинувшего края: Скорость носителя >= 120 -> +8% СА всей пати
	var lost_edge_count: int = 0
	for ally in allies:
		if ally is CombatUnit and ally.is_alive():
			if (ally.has_meta("has_set_lost_edge") or String(ally.get_meta("planar_set", "")) == "lost_edge") and ally.stats.get_effective_spd() >= 120.0:
				lost_edge_count += 1
	if lost_edge_count > 0 and unit.is_ally:
		buffs.append("• Лаборатория края [Планарный сет]: Скорость носителя >= 120 -> сила атаки всех союзников повышена на +%d%%." % [lost_edge_count * 8])

	# 5. Свободный остров Япония: ШПЭ >= 50% -> +15% защиты
	if unit.has_meta("has_set_japan_island") or String(unit.get_meta("planar_set", "")) == "japan_island":
		if dyn_ehr >= 0.50:
			buffs.append("• Остров Япония [Планарный сет]: ШПЭ >= 50%% (сейчас %.0f%%) -> защита повышена на +15%%." % [dyn_ehr * 100.0])

	# 6. Погрязший в руинах Иркутск: стаки Подвига (+5% FUA за стак, при 5 стаках +25% КУ)
	if unit.has_meta("relic_irkutsk_feat_stacks") and int(unit.get_meta("relic_irkutsk_feat_stacks", 0)) > 0:
		var i_stacks: int = int(unit.get_meta("relic_irkutsk_feat_stacks", 0))
		if i_stacks >= 5:
			buffs.append("• Погрязший в руинах Иркутск [Планарный сет] (Подвиг 5/5): урон бонус-атак повышен на +25%%, крит. урон повышен на +25%%.")
		else:
			buffs.append("• Погрязший в руинах Иркутск [Планарный сет] (Подвиг %d/5): урон бонус-атак повышен на +%d%%. На 5 стаках КУ повышен на +25%%." % [i_stacks, i_stacks * 5])
		
	if unit.has_meta("relic_silhouette_spd_turns") and int(unit.get_meta("relic_silhouette_spd_turns", 0)) > 0:
		buffs.append("• Сет Силуэта (%d х.): Скорость повышена на +20 ед. за совершение Казни." % int(unit.get_meta("relic_silhouette_spd_turns", 0)))
		
	if unit.has_meta("relic_bereft_spd_turns") and int(unit.get_meta("relic_bereft_spd_turns", 0)) > 0:
		buffs.append("• Сет Исследователя отнятого будущего (%d х.): Скорость повышена на +12%%." % int(unit.get_meta("relic_bereft_spd_turns", 0)))

	# 7. Сет: След из повреждённых строк (игнорирование защиты)
	if unit.has_meta("damaged_strings_def_ignore_turns") and int(unit.get_meta("damaged_strings_def_ignore_turns", 0)) > 0:
		buffs.append("• След из повреждённых строк (%d х.): Бинарный урон игнорирует 20%% защиты противника." % int(unit.get_meta("damaged_strings_def_ignore_turns", 0)))

	# 8. Сет: Дитя умирающих звёзд (бонус урона при Зеро > 40)
	if unit.has_meta("set_dying_stars_child_4"):
		var cur_z: int = int(unit.get_meta("antimatter_xaeroh", 0))
		if cur_z == 0:
			for a in allies:
				if a is CombatUnit and a.has_meta("antimatter_xaeroh"):
					cur_z = maxi(cur_z, int(a.get_meta("antimatter_xaeroh", 0)))
		if cur_z > 40:
			buffs.append("• Дитя умирающих звёзд (4 шт.): Зеро > 40 (сейчас %d) -> наносимый урон повышен на +15%%." % cur_z)
		else:
			buffs.append("• Дитя умирающих звёзд (4 шт.): Зеро <= 40 (сейчас %d) -> требуется > 40 Зеро для бонуса урона +15%%." % cur_z)

	# 9. Сет: Сервер в глубинах реальности (бонус скорости)
	if unit.has_meta("server_depths_spd_turns") and int(unit.get_meta("server_depths_spd_turns", 0)) > 0:
		buffs.append("• Сервер в глубинах реальности (%d х.): Скорость повышена на +12%%." % int(unit.get_meta("server_depths_spd_turns", 0)))

	# 10. Сет: Потайные глубины Изнанки
	if unit.is_ally:
		if unit.has_meta("has_set_inverted_depths") or String(unit.get_meta("planar_set", "")) == "inverted_depths":
			buffs.append("• Потайные глубины Изнанки (2 шт.): Сила Атаки повышена на +12%%.")
		var inv_active := false
		if unit.slot_index != 0 and (unit.has_meta("has_set_inverted_depths") or String(unit.get_meta("planar_set", "")) == "inverted_depths"):
			var f_ally: CombatUnit = null
			for a in allies:
				if a is CombatUnit and a.slot_index == 0:
					f_ally = a
					break
			if f_ally != null and f_ally.is_alive() and FactionSystem.have_shared_faction(unit.id, f_ally.id):
				inv_active = true
		elif unit.slot_index == 0:
			for a in allies:
				if a is CombatUnit and a.is_alive() and a != unit and a.slot_index != 0:
					if (a.has_meta("has_set_inverted_depths") or String(a.get_meta("planar_set", "")) == "inverted_depths"):
						if FactionSystem.have_shared_faction(unit.id, a.id):
							inv_active = true
							break
		if inv_active:
			buffs.append("• Потайные глубины Изнанки [Планарный сет]: Синергия фракции с лидером -> наносимый урон повышен на +10%%.")
		
	var lc_id: String = unit.get_meta("light_cone_id", "")
	if lc_id != "":
		if lc_id == "multiplication":
			buffs.append("   [color=green]=> Эффект активен:[/color] исходящее исцеление повышено на 25%.")
		elif lc_id == "medical_smell":
			var smell_turns: int = int(unit.get_meta("medical_smell_healing_turns", 0))
			if smell_turns > 0:
				buffs.append("   [color=green]=> Исходящее исцеление повышено на 24%%[/color] после ульты (%d ходов осталось)." % smell_turns)
				
	if unit.has_meta("archive_buff_turns"):
		var arch_t: int = int(unit.get_meta("archive_buff_turns", 0))
		if arch_t > 0:
			buffs.append("• [color=green]Конус Архив (%d х.)[/color]: СА повышена на 30%% после активации Сверхспособности." % arch_t)
			
	for ally in allies:
		if ally != unit and ally.is_alive() and unit.is_ally:
			var ally_lc: String = ally.get_meta("light_cone_id", "")
			if ally_lc == "better_world" and ally.element == unit.element:
				buffs.append("• [color=green]Бафф: Я создам лучший мир[/color] (от %s): Наносимый урон повышен на 20%% (совпадение элементов)." % ally.display_name)
				
	if unit.has_meta("arseniy_q_turns") and int(unit.get_meta("arseniy_q_turns", 0)) > 0:
		var q_turns: int = int(unit.get_meta("arseniy_q_turns", 0))
		var q_pct: float = float(unit.get_meta("arseniy_q_atk_percent", 0.0)) * 100.0
		var q_flat: float = float(unit.get_meta("arseniy_q_atk_flat", 0.0))
		buffs.append("• [color=green]Усиление Q Арсения (%d ход.)[/color]: СА +%d%% и +%d ед. (независимый бафф)." % [q_turns, int(q_pct), int(q_flat)])

	var shield_val: float = float(unit.get_meta("shield_value", 0.0))
	if shield_val > 0.0:
		var sh_turns: int = int(unit.get_meta("shield_turns", 0))
		var sh_src: String = String(unit.get_meta("shield_source", "Код"))
		buffs.append("• Щит (%d ход.): поглощает до %d ед. урона%s." % [sh_turns, int(shield_val), _src(sh_src)])
		
	# ИСПРАВЛЕНО: Учет динамических стаков таланта Данилла в панели информации
	var def_buff_pct: float = 0.0
	if unit.has_meta("danill_talent_stacks"):
		def_buff_pct += 0.10 * float(unit.get_meta("danill_talent_stacks", 0))
	if unit.has_meta("danill_trace3_def_buff") and bool(unit.get_meta("danill_trace3_def_buff")):
		def_buff_pct += 0.30
		
	if unit.has_meta("danill_taunt_turns") and int(unit.get_meta("danill_taunt_turns", 0)) > 0:
		buffs.append("• Провокация (%d ход.): все атаки врагов направлены на Данилла." % int(unit.get_meta("danill_taunt_turns", 0)))
	
	if unit.has_meta("lc_leak_turns") and int(unit.get_meta("lc_leak_turns", 0)) > 0:
				buffs.append("• Конус Утечка (%d х.): Шанс попадания эффектов (ШПЭ) повышен на +40%%." % int(unit.get_meta("lc_leak_turns", 0)))
	
	if unit.get_meta("light_cone_id", "") == "touch_waking_world":
		var debt_stacks: int = int(unit.get_meta("mutual_debt_stacks", 0))
		buffs.append("• Статус «Общий долг» x%d/5: скорость восстановления энергии пати увеличена на %d%%." % [debt_stacks, debt_stacks * 2])
		
	if unit.has_meta("crimson_tears_spd_turns") and int(unit.get_meta("crimson_tears_spd_turns", 0)) > 0:
		buffs.append("• Скорость от Басни багровых слез (%d х.): скорость повышена на +40%%." % int(unit.get_meta("crimson_tears_spd_turns", 0)))
		
	if unit.has_meta("meta_spd_stacks") and int(unit.get_meta("meta_spd_stacks", 0)) > 0:
		buffs.append("• Бафф Идеального Метаморфоза x%d/3: скорость повышена на +%d ед. за атаки." % [int(unit.get_meta("meta_spd_stacks", 0)), int(unit.get_meta("meta_spd_stacks", 0)) * 6])
	
	if unit.id == "rimes":
		var r_stacks := int(unit.get_meta("rimes_talent_stacks", 0))
		var r_max := 6 if unit.eidolon >= 1 else 4
		if r_stacks > 0:
			# ИСПРАВЛЕНО: Изменено отображение с 8% до 6% за стак
			buffs.append("• Талант x%d/%d: Скорость +%d%%, пробитие сопр. +%d%%." % [r_stacks, r_max, r_stacks * 10, r_stacks * 6])
		if r_stacks == r_max:
			buffs.append("• Талант (МАКСИМУМ): Крит. шанс повышен на +35%.")
		if unit.has_meta("rimes_isolation_target"):
			buffs.append("• Вечная Изоляция: Крит. урон +80%, Крит. шанс +20%. Иммунитет к урону от других врагов.")
	if unit.id == "joan":
		var stacks := int(unit.get_meta("joan_coffee_liqueur_stacks", 0))
		buffs.append("• Кофейный ликёр x%d/2: тратится на проведение FUA, когда атаки союзников бьют всех врагов на поле." % stacks)

	# =========================================================================
	# СТАТУСЫ И БАФФЫ ВЕЛЬЗЕВУЛ И ЛЕНСКОЙ ЯА (АНТИМАТЕРИЯ)
	# =========================================================================
	if unit.id == "velzebul":
		if bool(unit.get_meta("velzebul_in_offering", false)):
			buffs.append("• Стойка «Подношение»: базовая атака усилена (восстанавливает 5 Зеро, 0 ОН), сбор Грешных сердец.")
		var v_hearts: int = int(unit.get_meta("velzebul_sinful_hearts", 0))
		if v_hearts > 0:
			buffs.append("• Грешные сердца x%d/4: Сверхспособность разблокируется при 4 сердцах (След 3: Скорость Вельзевул +%d%%)." % [v_hearts, v_hearts * 10])
		if bool(unit.get_meta("velzebul_e_enhanced", false)):
			buffs.append("• Усиленный Навык E (1 ОН): наносит взрывной урон и накладывает «Печать Вельзевула» на 3 хода.")
		if unit.has_meta("velzebul_e4_spd_turns") and int(unit.get_meta("velzebul_e4_spd_turns", 0)) > 0:
			buffs.append("• Эйдолон 4 Вельзевул (%d х.): Скорость повышена на +30%%." % int(unit.get_meta("velzebul_e4_spd_turns", 0)))

	# Баффы от присутствия Вельзевул для команды:
	if unit.is_ally:
		var velz_team_ref: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.id == "velzebul" and ally.is_alive():
				velz_team_ref = ally
				break
		if velz_team_ref != null:
			# След 3: +10% СА за каждое сердце союзникам Антиматерии
			if _is_antimatter_member(unit):
				var h_cnt: int = int(velz_team_ref.get_meta("velzebul_sinful_hearts", 0))
				if h_cnt > 0:
					buffs.append("• След 3 Вельзевул (Грешные сердца x%d): Сила атаки повышена на +%d%%." % [h_cnt, mini(h_cnt * 10, 40)])
			# Талант: +5% КШ, +10% КУ всем союзникам за каждые 30 Зеро
			var cur_z: int = int(unit.get_meta("antimatter_xaeroh", 0))
			if cur_z == 0 and velz_team_ref.has_meta("antimatter_xaeroh"):
				cur_z = int(velz_team_ref.get_meta("antimatter_xaeroh", 0))
			var z_tiers: int = mini(6, int(floor(float(cur_z) / 30.0)))
			if z_tiers > 0:
				buffs.append("• Талант Вельзевул (%d Зеро): Крит. шанс +%d%%, Крит. урон +%d%%." % [cur_z, z_tiers * 5, z_tiers * 10])
			if velz_team_ref.eidolon >= 6 and cur_z > 30:
				buffs.append("• Эйдолон 6 Вельзевул (%d Зеро): Наносимый урон всех союзников +%d%%." % [cur_z, cur_z - 30])

	if unit.has_meta("velzebul_ult_antimatter_dmg_turns") and int(unit.get_meta("velzebul_ult_antimatter_dmg_turns", 0)) > 0:
		buffs.append("• Сверхспособность Вельзевул (%d х.): наносимый урон повышен на +40%%." % int(unit.get_meta("velzebul_ult_antimatter_dmg_turns", 0)))

	if unit.has_meta("velzebul_tech_dmg_turns") and int(unit.get_meta("velzebul_tech_dmg_turns", 0)) > 0:
		buffs.append("• Техника Вельзевул (%d х.): наносимый урон повышен на +15%%." % int(unit.get_meta("velzebul_tech_dmg_turns", 0)))

	# Марина • Хранитель небес:
	if unit.has_meta("marina_sk_link_turns") and int(unit.get_meta("marina_sk_link_turns", 0)) > 0:
		var link_t: int = int(unit.get_meta("marina_sk_link_turns", 0))
		var link_cr: float = float(unit.get_meta("marina_sk_link_crit_rate", 0.0)) * 100.0
		var linked_target: CombatUnit = unit.get_meta("marina_sk_linked_ally", null)
		var t_name: String = linked_target.display_name if linked_target else "Цель"
		buffs.append("• Связь Марины (%d х., цель: %s): Крит. шанс +%.1f%% (След 1: КУ +20%%)." % [link_t, t_name, link_cr])
	elif unit.has_meta("marina_sk_linked_by") or (unit is Memosprite and unit.owner != null and unit.owner.has_meta("marina_sk_linked_by")):
		var marina_src: CombatUnit = unit.get_meta("marina_sk_linked_by") if unit.has_meta("marina_sk_linked_by") else unit.owner.get_meta("marina_sk_linked_by")
		if marina_src != null and int(marina_src.get_meta("marina_sk_link_turns", 0)) > 0:
			var link_t: int = int(marina_src.get_meta("marina_sk_link_turns", 0))
			var link_cr: float = float(marina_src.get_meta("marina_sk_link_crit_rate", 0.0)) * 100.0
			var e4_str := ", Э4: игнорирование защиты 18%" if marina_src.eidolon >= 4 else ""
			buffs.append("• Под связью Марины (%d х.): Крит. шанс +%.1f%%, Крит. урон +20%%%s." % [link_t, link_cr, e4_str])

	if unit.has_meta("marina_sk_elysium_zone_turns") and int(unit.get_meta("marina_sk_elysium_zone_turns", 0)) > 0:
		buffs.append("• Зона «Элизиум» (%d х.): Все враги получают +30%% урона. При атаках союзников враг с наибольшим ХП получает доп. урон." % int(unit.get_meta("marina_sk_elysium_zone_turns", 0)))

	# Раймс • Восхождение:
	if unit.id == "rimes_ascension":
		var c_val := float(unit.get_meta("crescendo_stacks", 0.0))
		buffs.append("• Крещендо: %.1f%%/100%% (Сверхспособность доступна при 100%%)." % c_val)
		var t_st := int(unit.get_meta("talent_dmg_stacks", 0))
		if t_st > 0:
			var t_turns := int(unit.get_meta("talent_dmg_turns", 0))
			buffs.append("• Талант Раймса (%d х.): Наносимый урон повышен на +%d%% (стаков: %d/3)." % [t_turns, t_st * 20, t_st])
		var r_turns := int(unit.get_meta("rimes_rupture_zone_turns", 0))
		if r_turns > 0:
			buffs.append("• Зона «Разрыв» (%d х.): Все враги имеют -20%% сопротивления; при Зеро > 50 даёт КУ." % r_turns)

	if unit.id == "antimatter_paws" or (unit is Memosprite and (unit as Memosprite).definition != null and (unit as Memosprite).definition.id == "antimatter_paws"):
		var ch := int((unit as Memosprite).get_charge()) if unit is Memosprite and (unit as Memosprite).charge_comp != null else 1
		buffs.append("• Заряды Лап: %d/4 (макс. ХП +%d%%)." % [ch, (ch - 1) * 30])
		var p_t3 := int(unit.get_meta("paws_trace3_stacks", 0))
		if p_t3 > 0:
			buffs.append("• След 3 Лап: Наносимый урон +%d%% (стаков: %d/6)." % [p_t3 * 30, p_t3])

	if unit is Memosprite:
		buffs.append("• Талант Эго: Крит. урон повышен на +30% + 13% от КУ Эго.")
		if unit.has_meta("marina_sk_e6_dmg_buff_turns"):
			buffs.append("• Эйдолон 6 Марины (1 х.): Наносимый урон духов памяти +50%.")

	# Статусы Ленской ЯА
	if unit.id == "lenskaya_antimatter":
		var am_st: String = String(unit.get_meta("lenskaya_am_stance", "none"))
		if am_st == "keeper":
			buffs.append("• Форма «Хранитель Ничто»: Навык Q совершает 7 ударов с бонусом от скорости. След 1: вход даёт +1 ОН, расход Зеро даёт +5 ЭН.")
		elif am_st == "warrior":
			buffs.append("• Форма «Воин небытия»: Навык Q бьёт по площади и казнит врагов (<10% ХП) при выходе из изнанки.")
		if bool(unit.get_meta("lenskaya_am_in_inverted", false)):
			buffs.append("• Состояние «В изнанке»: полная недосягаемость для атак противников до следующего действия.")
		if unit.has_meta("lenskaya_am_atk_buff_turns") and int(unit.get_meta("lenskaya_am_atk_buff_turns", 0)) > 0:
			buffs.append("• Выход из изнанки (%d х.): Сила атаки повышена на +40%%." % int(unit.get_meta("lenskaya_am_atk_buff_turns", 0)))
		if unit.has_meta("lenskaya_am_spd_buff_turns") and int(unit.get_meta("lenskaya_am_spd_buff_turns", 0)) > 0:
			buffs.append("• Скорость Хранителя (%d х.): Скорость повышена (30%% от скорости команды)." % int(unit.get_meta("lenskaya_am_spd_buff_turns", 0)))

	# Баффы Ленской ЯА союзникам
	if unit.has_meta("lenskaya_am_team_atk_turns") and int(unit.get_meta("lenskaya_am_team_atk_turns", 0)) > 0:
		var am_atk_f: int = int(float(unit.get_meta("lenskaya_am_team_atk_boost", 0.0)))
		buffs.append("• Благословение Хранителя (%d х.): Сила атаки повышена на +%d ед. (30%% от СА Ленской)." % [int(unit.get_meta("lenskaya_am_team_atk_turns", 0)), am_atk_f])

	if unit.has_meta("antimatter_crit_dmg_turns") and int(unit.get_meta("antimatter_crit_dmg_turns", 0)) > 0:
		var am_cd_val: int = int(float(unit.get_meta("antimatter_crit_dmg_bonus", 0.0)) * 100.0)
		buffs.append("• Резонанс Антиматерии (%d х.): Крит. урон повышен на +%d%% за расход Зеро." % [int(unit.get_meta("antimatter_crit_dmg_turns", 0)), am_cd_val])
	
	# Баффы Сангинии Ял
	if unit.id == "sanguinia":
		var waves := int(unit.get_meta("sanguinia_waves", 0))
		buffs.append("• Журчание волн (%d/47 стаков): урон бонус-атак всего отряда повышен на +%d%%. На 47 продвигает сильнейшего на 100%% с +100%% к урону." % [waves, waves * 2])
		if unit.has_meta("sanguinia_e4_atk_turns") and int(unit.get_meta("sanguinia_e4_atk_turns", 0)) > 0:
			buffs.append("• Эйдолон 4 (%d х.): Сила атаки повышена на +40%%." % int(unit.get_meta("sanguinia_e4_atk_turns", 0)))
		if unit.has_meta("sanguinia_e2_dmg_turns") and int(unit.get_meta("sanguinia_e2_dmg_turns", 0)) > 0:
			buffs.append("• Эйдолон 2 (%d х.): Наносимый урон повышен на +60%%." % int(unit.get_meta("sanguinia_e2_dmg_turns", 0)))

	if unit.has_meta("sanguinia_q_atk_turns") and int(unit.get_meta("sanguinia_q_atk_turns", 0)) > 0:
		buffs.append("• Поддержка Сангинии (Навык Q) (%d х.): Сила атаки повышена на +40%%." % int(unit.get_meta("sanguinia_q_atk_turns", 0)))

	if unit.has_meta("sanguinia_prep_atk_turns") and int(unit.get_meta("sanguinia_prep_atk_turns", 0)) > 0:
		var txt := "• «Готовьтесь...» (%d х.): Сила атаки повышена на +60%%." % int(unit.get_meta("sanguinia_prep_atk_turns", 0))
		if unit.has_meta("sanguinia_prep_ignore_def_attack"):
			txt += " Следующая атака игнорирует 20% защиты (След 2)."
		buffs.append(txt)

	if unit.has_meta("sanguinia_tech_spd_turns") and int(unit.get_meta("sanguinia_tech_spd_turns", 0)) > 0:
		buffs.append("• Техника Сангинии (%d х.): Скорость повышена на +15 ед." % int(unit.get_meta("sanguinia_tech_spd_turns", 0)))

	if unit.has_meta("sanguinia_talent_dmg_boost"):
		buffs.append("• Талант Сангинии (47 стаков): Урон следующей атаки повышен на +100%%.")
	
	# =========================================================================
	# 2. СБОР ОСЛАБЛЕНИЙ (ДЕБАФФОВ)
	# =========================================================================
	if st.has_dark_seal:
		debuffs.append(
			"• Тёмная печать (%d ход.)%s: при убийстве союзник +20%% ЭН." % [
				st.dark_seal_turns, _src(st.dark_seal_source),
			],
		)
	if st.suppression_stacks > 0:
		debuffs.append(
			"• Подавление x%d (%d ход.)%s: −8%% СКР/стак, +15%% урона по цели." % [
				st.suppression_stacks, st.suppression_turns, _src(st.suppression_source),
			],
		)
	if st.toughness_broken:
		debuffs.append(
			"• Пробой стойкости%s: +20%% получаемого урона." % _src(st.toughness_break_source),
		)
	if st.break_status != "":
		debuffs.append(
			"• %s (%d ход.)%s" % [st.break_status, st.break_status_turns, _src(st.break_status_source)],
		)
	if st.entanglement_stacks > 0:
		debuffs.append(
			"• Связывание x%d%s" % [st.entanglement_stacks, _src(st.entanglement_source)],
		)
	if st.skip_next_turn:
		debuffs.append(
			"• Пропуск следующего хода (заморозка)%s." % _src(st.skip_next_turn_source),
		)
	if st.imaginary_spd_debuff_turns > 0:
		debuffs.append(
			"• Оковы (%d ход.)%s: −20%% СКР." % [st.imaginary_spd_debuff_turns, _src(st.imaginary_source)],
		)
	
	if unit.has_meta("lenskaya_bounty_turns") and int(unit.get_meta("lenskaya_bounty_turns", 0)) > 0:
		debuffs.append("• Награда за голову (%d х.): при атаке союзником Ленская немедленно проведет Бонус-атаку по этой цели." % int(unit.get_meta("lenskaya_bounty_turns", 0)))
		
	if unit.has_meta("lenskaya_slow_turns") and int(unit.get_meta("lenskaya_slow_turns", 0)) > 0:
		debuffs.append("• Замедление Ленской (%d х.): скорость цели снижена на 20%%." % int(unit.get_meta("lenskaya_slow_turns", 0)))
		
	if unit.has_meta("priority_target") and unit.get_meta("priority_target"):
		debuffs.append("• Приоритетная Цель: получаемый целью крит. урон +20%, крит. шанс по ней +10%.")
	if unit.has_meta("dead_or_alive") and unit.get_meta("dead_or_alive"):
		debuffs.append("• Живым или мёртвым: получаемый целью крит. урон +20% (дополнительно +20% при E2), крит. шанс по ней +10%.")
		
	if unit.has_meta("worship_turns") and int(unit.get_meta("worship_turns", 0)) > 0:
		debuffs.append("• Поклонение (%d х.): Защита снижена на 30%%. Когда любой союзник наносит урон цели, отряд восстанавливает 3 Зеро." % int(unit.get_meta("worship_turns", 0)))
		
	if unit.has_meta("def_reductions"):
		var reductions: Dictionary = unit.get_meta("def_reductions")
		var base_def: float = float(unit.get_meta("base_def", unit.stats.def))
		for src in reductions:
			if src == "Поклонение":
				continue
			var data: Dictionary = reductions[src]
			var turns: int = int(data.get("turns", 0))
			if turns > 0:
				var pct: float = float(data.get("percent", 0.0)) * 100.0
				var flat_val: float = base_def * float(data.get("percent", 0.0))
				debuffs.append("• Снижение защиты (%d х.): ЗАЩ снижена на -%.0f%% (-%d ед.) (источник: %s)" % [turns, pct, int(flat_val), src])

	if unit.has_meta("phys_res_reduced_turns"):
		var phys_turns: int = int(unit.get_meta("phys_res_reduced_turns", 0))
		if phys_turns > 0:
			debuffs.append("• Слабость к физ. урону (%d ход.): сопротивление физ. урону снижено на 20%%." % phys_turns)
	
	# След 3 Жоана Духа решимости на враге
	if not unit.is_ally:
		var joan_ref: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.id == "joan_spirit" and ally.is_alive():
				joan_ref = ally
				break
		# Используем единый статический метод из BattleManager!
		if joan_ref and not BattleManager.get_unit_active_dots(unit).is_empty():
			debuffs.append("• След 3 Жоана (DoT на цели): Получаемый Крит. урон [color=green]+50%[/color], входящий DoT урон [color=red]-90%[/color].")
			
	if unit.has_meta("isaac_crit_dmg_taken_turns") and int(unit.get_meta("isaac_crit_dmg_taken_turns", 0)) > 0:
		debuffs.append("• Слабость к критическому урону (%d х.): получаемый критический урон увеличен на +35%%." % int(unit.get_meta("isaac_crit_dmg_taken_turns", 0)))
	
	if unit.has_meta("isaac_dmg_reduce_turns") and int(unit.get_meta("isaac_dmg_reduce_turns", 0)) > 0:
		debuffs.append("• Подавление урона (%d х.): наносимый этой целью урон снижен на −20%%." % int(unit.get_meta("isaac_dmg_reduce_turns", 0)))
	
	if unit.has_meta("valramors_talent_turns") and int(unit.get_meta("valramors_talent_turns", 0)) > 0:
		var elem_id: int = int(unit.get_meta("valramors_talent_weakness", -1))
		# ИСПРАВЛЕНО: Явное указание типа String и каст из Variant
		var elem_name: String = String(CombatConstants.ELEMENT_NAMES.get(elem_id, "нет"))
		debuffs.append("• Приказ принят (%d х.): сила атаки снижена на -15%%, скорость снижена на -8%%. Наложена уязвимость к элементу: %s." % [int(unit.get_meta("valramors_talent_turns", 0)), elem_name])
	if unit.has_meta("valramors_ult_vuln_turns") and int(unit.get_meta("valramors_ult_vuln_turns", 0)) > 0:
		debuffs.append("• Печать бессмертия (%d х.): получаемый урон увеличен на +20%%." % int(unit.get_meta("valramors_ult_vuln_turns", 0)))

	if unit.has_meta("shoji_burn_turns") and int(unit.get_meta("shoji_burn_turns", 0)) > 0:
		var sh_turns: int = int(unit.get_meta("shoji_burn_turns", 0))
		debuffs.append("• Горение Сёдзи (%d х.): получает периодический огненный урон в размере 120%% от СА Сёдзи в свой ход." % sh_turns)
		
	if unit.has_meta("shoji_fire_res_reduced_turns") and int(unit.get_meta("shoji_fire_res_reduced_turns", 0)) > 0:
		var fr_turns: int = int(unit.get_meta("shoji_fire_res_reduced_turns", 0))
		debuffs.append("• Огненная уязвимость (%d ход.): сопротивление Огненному урону снижено на 40%% (Сёдзи E1)." % fr_turns)

	if unit.has_meta("shoji_swan_dance_vuln_turns") and int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0:
		var vuln_pct := int(float(unit.get_meta("shoji_swan_dance_vuln_pct", 0.0)) * 100.0)
		debuffs.append("• Лебединая уязвимость (%d х.): Получаемый урон ко всем типам увеличен на +%d%%." % [int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)), vuln_pct])

	if unit.has_meta("shoji_swan_tech_vuln_turns") and int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0:
		debuffs.append("• Техника Сёдзи (%d х.): Получаемый урон ко всем типам увеличен на +25%%." % int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)))
	
	if unit.has_meta("joan_dont_miss_turns") and int(unit.get_meta("joan_dont_miss_turns", 0)) > 0:
		var turns := int(unit.get_meta("joan_dont_miss_turns", 0))
		var pct := int(float(unit.get_meta("joan_dont_miss_vuln", 0.20)) * 100.0)
		debuffs.append("• Не промахнись (%d х.): получаемый противником урон увеличен на +%d%%." % [turns, pct])

	if unit.has_meta("joan_tech_vuln_turns") and int(unit.get_meta("joan_tech_vuln_turns", 0)) > 0:
		debuffs.append("• Слабость от техники Жоана (%d х.): получаемый урон увеличен на +20%%." % int(unit.get_meta("joan_tech_vuln_turns", 0)))
	
	if unit.has_meta("e4_phys_weakness_turns"):
		var e4_turns: int = int(unit.get_meta("e4_phys_weakness_turns", 0))
		if e4_turns > 0:
			debuffs.append("• Наложенная слабость (%d ход.): Эйдолон 4 Каори добавил Физическую уязвимость." % e4_turns)

	# Дебаффы Катарины
	if unit.has_meta("katarina_vuln_turns") and int(unit.get_meta("katarina_vuln_turns", 0)) > 0:
		var k_turns := int(unit.get_meta("katarina_vuln_turns", 0))
		if unit.has_meta("katarina_all_res_reduction"):
			debuffs.append("• Ослабление Катарины (E1) (%d х.): Наложена Физическая уязвимость, Сопротивление ко ВСЕМ типам -20%%, Скорость -30%%." % k_turns)
		else:
			debuffs.append("• Физическая уязвимость (%d х.): Наложена Физическая уязвимость, Физ. сопротивление -20%%." % k_turns)
	if unit.has_meta("katarina_q_ally_mark_turns") and int(unit.get_meta("katarina_q_ally_mark_turns", 0)) > 0:
		debuffs.append("• Метка Катарины (%d х.): Атаки союзников дают атакующему +15%% СА на 2 хода." % int(unit.get_meta("katarina_q_ally_mark_turns", 0)))
	if bool(unit.get_meta("katarina_broken_spirit", false)):
		var rec_dmg := int(float(unit.get_meta("katarina_recorded_broken_spirit_dmg", 0.0)))
		debuffs.append("• «Сломленный дух» [Катарина]: Катарина наносит 0 урона (записано: %d ед.). Получаемый бинарный урон +30%% (E6: весь урон критический, снятие высвобождает 50%% урона)." % rec_dmg)
	if unit.has_meta("katarina_e6_binary_vuln"):
		debuffs.append("• Бинарная уязвимость (E6 Катарины): Получаемый Бинарный урон +40% до конца боя.")

	# След 1 Катарины: Получаемый шанс крит. попадания повышен на +X%
	if not unit.is_ally:
		var kat_ref: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.is_alive() and ally.id == "katarina":
				kat_ref = ally
				break
		if kat_ref != null:
			var debuff_cnt := _count_enemy_debuffs(unit)
			var cr_bonus: int = int(minf(float(debuff_cnt) * 4.0, 32.0))
			debuffs.append("• След 1 Катарины: Получаемый шанс крит. попадания повышен на +%d%% (источник: Катарина)." % cr_bonus)

	# Дебаффы Доцевой • Багровые слёзы
	if unit.has_meta("doceva_tears_q_vuln_turns") and int(unit.get_meta("doceva_tears_q_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость (Q Доцевой) (%d х.): Получаемый урон +15%%." % int(unit.get_meta("doceva_tears_q_vuln_turns", 0)))
	if unit.has_meta("doceva_tears_outgoing_dmg_red_turns") and int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0:
		debuffs.append("• Снижение урона (Ульта Доцевой) (%d х.): Наносимый урон снижен на -30%%." % int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)))
	if unit.has_meta("doceva_tears_e2_vuln_turns") and int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость (E2 Доцевой) (%d х.): Получаемый урон +40%%." % int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)))
	
	# В секции Ослаблений (дебаффов):
	if unit.has_meta("ballast_turns") and int(unit.get_meta("ballast_turns", 0)) > 0:
		debuffs.append("• Балласт (%d х.): в начале хода носителя весь отряд получает урон в размере 125 ед." % int(unit.get_meta("ballast_turns", 0)))
		
	if unit.has_meta("trojan_turns") and int(unit.get_meta("trojan_turns", 0)) > 0:
		debuffs.append("• Троян (%d х.): сила атаки снижена на -20%%, получает периодический урон в начале хода." % int(unit.get_meta("trojan_turns", 0)))
		
	if unit.has_meta("packet_delay_turns") and int(unit.get_meta("packet_delay_turns", 0)) > 0:
		debuffs.append("• Задержка пакетов (%d х.): скорость цели снижена на -15%%." % int(unit.get_meta("packet_delay_turns", 0)))
		
	if unit.has_meta("server_virus_breached_turns") and int(unit.get_meta("server_virus_breached_turns", 0)) > 0:
		debuffs.append("• Взлом файрвола (%d х.): получаемый урон увеличен на +20%%." % int(unit.get_meta("server_virus_breached_turns", 0)))
		
	if unit.has_meta("ortho_acid_dot_turns") and int(unit.get_meta("ortho_acid_dot_turns", 0)) > 0:
		debuffs.append("• Кислотный мутаген (постоянно): цель поражена мутагеном (DoT-эффект для активации Следа 3 Жоана Духа).")
		
		
	if unit.has_meta("musienko_recorded_damage") and float(unit.get_meta("musienko_recorded_damage", 0.0)) > 0.0:
		debuffs.append("• Записанный урон Мусиенко: накоплено %d урона. При выходе из Аннигиляции цель получит чистый урон." % int(float(unit.get_meta("musienko_recorded_damage", 0.0))))
	if unit.has_meta("naama_intox_stacks") and int(unit.get_meta("naama_intox_stacks", 0)) > 0:
		var stacks: int = int(unit.get_meta("naama_intox_stacks", 0))
		debuffs.append("• Опьянение x%d/20: в ход врага наносит DoT урон. На 20 стаках снижает защиту на 20%%." % stacks)
		
	if unit.has_meta("naama_dot_vuln_turns") and int(unit.get_meta("naama_dot_vuln_turns", 0)) > 0:
		debuffs.append("• Слабость к DoT (%d х.): получаемый периодический урон увеличен на 30%%." % int(unit.get_meta("naama_dot_vuln_turns", 0)))
		
	if unit.has_meta("naama_kiss_turns") and int(unit.get_meta("naama_kiss_turns", 0)) > 0:
		var state_str: String = "активен" if String(unit.get_meta("naama_kiss_state", "")) == "active" else "неактивен"
		debuffs.append("• Поцелуй Бездны (%d х.) [%s]: наносимый врагом урон снижен на 20%%, защита снижена на 15%% (След 2)." % [int(unit.get_meta("naama_kiss_turns", 0)), state_str])

	if unit.has_meta("radiance_status_turns") and int(unit.get_meta("radiance_status_turns", 0)) > 0:
		var radiance_host: CombatUnit = unit.get_meta("radiance_owner")
		var radiance_time: int = int(unit.get_meta("radiance_status_turns", 0))
		if radiance_host:
			debuffs.append("• Сияние (%d х.): враг получает периодический огненный урон в размере 70%% от силы атаки %s." % [radiance_time, radiance_host.display_name])
			
	if unit.has_meta("lenskaya_radiance_enemy_turns") and int(unit.get_meta("lenskaya_radiance_enemy_turns", 0)) > 0:
		var r_turns: int = int(unit.get_meta("lenskaya_radiance_enemy_turns", 0))
		var is_e2: bool = bool(unit.get_meta("lenskaya_radiance_enemy_e2", false))
		debuffs.append("• Враг Свечения (%d х.): истощение стойкости 150%% (1.5x), получаемый урон Пробития и Суперпробития +%d%%." % [r_turns, 45 if is_e2 else 30])

	if unit.has_meta("traces_of_memories_turns") and int(unit.get_meta("traces_of_memories_turns", 0)) > 0:
		var t_turns: int = int(unit.get_meta("traces_of_memories_turns", 0))
		debuffs.append("• По следам воспоминаний (%d х.): при атаке владельца конуса восстановит ему 10 энергии, снимется и снизит защиту цели на 10%% на 1 ход." % t_turns)

	if unit.has_meta("lenskaya_e6_weakness_turns") and int(unit.get_meta("lenskaya_e6_weakness_turns", 0)) > 0:
		debuffs.append("• Мнимая уязвимость (%d х.): наложена Навыком E Ленской (E6)." % int(unit.get_meta("lenskaya_e6_weakness_turns", 0)))

	if unit.has_meta("dotseva_debtor_status") and int(unit.get_meta("dotseva_debtor_status", 0)) > 0:
		debuffs.append("• Должник (%d х.): после смерти врага Доцева получит +2 Калибровки, соседи получат урон." % int(unit.get_meta("dotseva_debtor_status", 0)))
		
	if unit.has_meta("dotseva_e6_shared_target"):
		debuffs.append("• Связь Должника (Доцева Е6): любой получаемый урон копируется окружающим противникам!")
	
	if unit.has_meta("rimes_isolation_source"):
		debuffs.append("• Вечная Изоляция: цель может атаковать только Раймса и имеет иммунитет ко всему остальному урону.")
	
	# Ослабления Арсения Админа, Сары и Айзека на противниках
	if unit.has_meta("arseniy_binary_vuln_turns") and int(unit.get_meta("arseniy_binary_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость к Бинарному урону (%d х.): получаемый Бинарный урон увеличен на +30%%." % int(unit.get_meta("arseniy_binary_vuln_turns", 0)))
		
	if unit.has_meta("arseniy_atk_weaken_turns") and int(unit.get_meta("arseniy_atk_weaken_turns", 0)) > 0:
		debuffs.append("• Подавление атаки (%d х.): наносимый врагом урон снижен на −30%%. (Источник: Арсений • Права администратора)" % int(unit.get_meta("arseniy_atk_weaken_turns", 0)))
	
	if unit.has_meta("arseniy_trace3_vuln_turns") and int(unit.get_meta("arseniy_trace3_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость к урону (%d х.): получаемый врагом урон увеличен на 30%%. (Источник: Арсений • Права администратора)" % int(unit.get_meta("arseniy_trace3_vuln_turns", 0)))
	
	if unit.has_meta("sara_e2_vuln_turns") and int(unit.get_meta("sara_e2_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость Сары Е2 (%d х.): получаемый любой урон увеличен на +30%%." % int(unit.get_meta("sara_e2_vuln_turns", 0)))
		
	if unit.has_meta("binary_vuln_turns") and int(unit.get_meta("binary_vuln_turns", 0)) > 0:
		debuffs.append("• Уязвимость к Бинарному урону (Е4 Айзек) (%d х.): получаемый Бинарный урон увеличен на +20%%." % int(unit.get_meta("binary_vuln_turns", 0)))
		
	# В блоке дебаффов:
	if unit.has_meta("jeff_bass_listen_turns") and int(unit.get_meta("jeff_bass_listen_turns", 0)) > 0:
		var turns := int(unit.get_meta("jeff_bass_listen_turns", 0))
		debuffs.append("• Бассы! Слушай! (%d х.): наносит урон в ход врага. Любой DoT на цели лечит весь отряд на 3%% от ХП Джеффа." % turns)
	
	if unit.has_meta("admin_vuln_turns") and int(unit.get_meta("admin_vuln_turns", 0)) > 0:
		debuffs.append("• Тестовая уязвимость (%d х.): получаемый урон увеличен на +%.0f%%." % [int(unit.get_meta("admin_vuln_turns", 0)), float(unit.get_meta("admin_vuln_pct", 0.30)) * 100.0])

	if unit.has_meta("sanguinia_special_guest_charges"):
		var guest_charges := int(unit.get_meta("sanguinia_special_guest_charges", 0))
		debuffs.append("• Особый гость (%d/12 зар.)%s: атаки союзников снижают заряды на 1. На 9, 6, 3, 0 Сангиния немедленно проводит Бонус-атаку (130%% центру, 35%% соседям). При 0 статус снимается и восстанавливается 1 Очко Навыков." % [
			guest_charges, _src("Сангиния Ял")
		])

	for deb_msg in st.debuffs:
		if deb_msg == "sanguinia_special_guest":
			continue
		debuffs.append("• %s" % deb_msg)

	# Ослабления Вельзевул и Ленской ЯА на противниках:
	if unit.has_meta("velzebul_seal_turns") and int(unit.get_meta("velzebul_seal_turns", 0)) > 0:
		debuffs.append("• Печать Вельзевула (%d х.): атаки Навыком Q Ленской восстанавливают 15 энергии и 5 Зеро; атаки Вельзевул дают +1 ОН." % int(unit.get_meta("velzebul_seal_turns", 0)))

	if unit.has_meta("velzebul_ice_quantum_res_turns") and int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)) > 0:
		debuffs.append("• Ослабление Вельзевул (%d х.): сопротивление Ледяному и Квантовому урону снижено на -20%%." % int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)))

	if unit.has_meta("lenskaya_am_decomp_turns") and int(unit.get_meta("lenskaya_am_decomp_turns", 0)) > 0:
		var dec_s: int = int(unit.get_meta("lenskaya_am_decomp_stacks", 1))
		debuffs.append("• Разложение x%d/3 (%d х.): получаемый квантовый урон увеличен на +%d%%." % [dec_s, int(unit.get_meta("lenskaya_am_decomp_turns", 0)), dec_s * 15])

	if unit.has_meta("ego_reality_vuln_turns") and int(unit.get_meta("ego_reality_vuln_turns", 0)) > 0:
		debuffs.append("• Реальность (%d х.): получаемый урон увеличен на +30%%, +5%% чистого урона от атак союзников." % int(unit.get_meta("ego_reality_vuln_turns", 0)))

	if not unit.is_ally:
		var rimes_asc_u: CombatUnit = null
		for ally in allies:
			if ally is CombatUnit and ally.id == "rimes_ascension" and ally.is_alive():
				rimes_asc_u = ally
				break
		if rimes_asc_u != null and int(rimes_asc_u.get_meta("rimes_rupture_zone_turns", 0)) > 0:
			debuffs.append("• Зона «Разрыв» (%d х.): Сопротивление всем типам урона снижено на -20%%." % int(rimes_asc_u.get_meta("rimes_rupture_zone_turns", 0)))
		var am_alive := 0
		var max_z := 0
		for ally in allies:
			if ally is CombatUnit and ally.is_alive():
				if _is_antimatter_member(ally):
					am_alive += 1
				if ally.has_meta("antimatter_xaeroh"):
					max_z = maxi(max_z, int(ally.get_meta("antimatter_xaeroh", 0)))
		if am_alive >= 2 and max_z >= 20:
			var def_s: int = int(minf(75.0, floor(float(max_z) / 20.0) * 5.0))
			debuffs.append("• Поле Антиматерии (%d Зеро): Защита снижена на -%d%%." % [max_z, def_s])

	if unit.has_meta("server_depths_vuln_sources"):
		var s_sources: Dictionary = unit.get_meta("server_depths_vuln_sources", {})
		var s_count: int = 0
		for src_id in s_sources:
			if int(s_sources[src_id]) > 0:
				s_count += 1
		if s_count > 0:
			debuffs.append("• Сервер в глубинах реальности: получаемый Бинарный урон повышен на +%d%% (источников: %d)." % [s_count * 10, s_count])

	if unit.has_meta("hacked_bleed_stacks") and int(unit.get_meta("hacked_bleed_stacks", 0)) > 0:
		debuffs.append("• Кровотечение [Взлом] x%d/5 (%d х.): получает периодический физический урон в ход." % [int(unit.get_meta("hacked_bleed_stacks", 0)), int(unit.get_meta("hacked_bleed_turns", 0))])

	if unit.has_meta("shoji_vz_viral_burn_turns") and int(unit.get_meta("shoji_vz_viral_burn_turns", 0)) > 0:
		debuffs.append("• Вирусный ожог (%d х.): получает периодический урон." % int(unit.get_meta("shoji_vz_viral_burn_turns", 0)))

	if unit.has_meta("cleaner_def_reduction_turns") and int(unit.get_meta("cleaner_def_reduction_turns", 0)) > 0:
		debuffs.append("• Сенсорная перегрузка (%d х.): защита снижена на -20%%." % int(unit.get_meta("cleaner_def_reduction_turns", 0)))

	if bool(unit.get_meta("shoji_vz_firewall_active", false)):
		buffs.append("• Брандмауэр Цитадели: прямой урон снижен на 40% (DoT наносит полный урон).")

	if unit.has_meta("orto_horror_symbiosis_reduction") and float(unit.get_meta("orto_horror_symbiosis_reduction", 0.0)) > 0.0:
		buffs.append("• Ортофетаминовый симбиоз: входящий урон снижен на %.0f%% благодаря свите Заражённых." % (float(unit.get_meta("orto_horror_symbiosis_reduction", 0.0)) * 100.0))

	if unit.id == "velzebul_boss" and VelzebulBoss.is_antimatter_shell_active(unit):
		buffs.append("• Панцирь Антиматерии: входящий урон снижен на 25% (снимается физ. срезкой Катарины).")

	# =========================================================================
	# 3. ФОРМАТИРОВАНИЕ ВЫВОДА
	# =========================================================================
	var final_lines: PackedStringArray = []
	
	if not buffs.is_empty():
		final_lines.append("[color=dodgerblue]==== УСИЛЕНИЯ (БАФФЫ) ====[/color]")
		for b in buffs:
			final_lines.append(b)
			
	if not debuffs.is_empty():
		if not buffs.is_empty():
			final_lines.append("") # Разделительный пробел между блоками
		final_lines.append("[color=crimson]==== ОСЛАБЛЕНИЯ (ДЕБАФФЫ) ====[/color]")
		for d in debuffs:
			final_lines.append(d)
			
	if final_lines.is_empty():
		return "Нет активных эффектов."
		
	return "\n".join(final_lines)
	
# Статический аналог для точного вычисления боевой силы атаки в реальном времени на UI
# Статический аналог для точного вычисления боевой силы атаки в реальном времени на UI
static func get_unit_effective_atk_static(unit: CombatUnit, allies: Array, exclude_milena_talent: bool = false) -> float:
	if unit == null:
		return 0.0
	var s := unit.stats
	
	
	# Учет Следа 1 Жоана Духа (+4% СА за стак Остатков золота)
	var joan_gold_pct := 0.0
	for ally in allies:
		if ally is CombatUnit and ally.id == "joan_spirit" and ally.is_alive() and unit.is_ally:
			var gold_stacks: int = int(ally.get_meta("joan_gold_remnants", 0))
			joan_gold_pct = float(gold_stacks) * 0.04
			break
	
	var relic_atk_pct := float(unit.get_meta("relic_atk_pct", 0.0))
	if unit.id == "valramors":
		var is_active := (unit.slot_index == 0) or (unit.eidolon >= 6)
		if is_active:
			var ehr := s.effect_hit_rate + (s.crit_rate * 0.35)
			relic_atk_pct += ehr
	var lc_pct := float(unit.get_meta("lc_atk_pct_bonus", 0.0))
	
	var stage_partner_pct: float = 0.0
	if unit.has_meta("stage_partner_turns") and int(unit.get_meta("stage_partner_turns", 0)) > 0:
		stage_partner_pct = 0.15

	var blazing_sun_pct: float = 0.0
	if unit.has_meta("blazing_sun_turns") and int(unit.get_meta("blazing_sun_turns", 0)) > 0:
		blazing_sun_pct = 0.40
		
	var detroit_dynamic_atk_pct := 0.0
	if unit.has_meta("has_set_detroit"):
		if s.get_effective_spd() >= 120.0:
			detroit_dynamic_atk_pct = 0.12
			
	var lost_edge_count: int = 0
	for ally in allies:
		if ally is CombatUnit and ally.is_alive() and ally.has_meta("has_set_lost_edge"):
			if ally.stats.get_effective_spd() >= 120.0:
				lost_edge_count += 1
	var lost_edge_bonus: float = 0.08 * float(lost_edge_count)
	
	# Дебафф силы атаки Валраморса (-15% СА)
	var valramors_debuff_pct: float = 0.0
	if unit.has_meta("valramors_talent_turns") and int(unit.get_meta("valramors_talent_turns", 0)) > 0:
		valramors_debuff_pct = -0.15
		
	var q_pct: float = 0.0
	var q_flat: float = 0.0
	if unit.has_meta("arseniy_q_turns") and int(unit.get_meta("arseniy_q_turns", 0)) > 0:
		q_pct = float(unit.get_meta("arseniy_q_atk_percent", 0.0))
		q_flat = float(unit.get_meta("arseniy_q_atk_flat", 0.0))
		
	var faction_pct: float = 0.0
	if unit.has_meta("faction_chaos_atk_pct"):
		faction_pct += float(unit.get_meta("faction_chaos_atk_pct", 0.0))
	if unit.has_meta("faction_empyrean_atk_pct"):
		faction_pct += float(unit.get_meta("faction_empyrean_atk_pct", 0.0))
		
	var joan_flat_atk: float = 0.0
	
	var milena_flat_atk: float = 0.0
	var milena_overtone_pct: float = 0.0
	var milena_unit: CombatUnit = null
	for ally in allies:
		if ally is CombatUnit and ally.id == "milena" and ally.is_alive():
			milena_unit = ally
			break
	

	var isaac_trace2_pct: float = 0.0
	if unit.has_meta("isaac_admin_trace2_atk_turns") and int(unit.get_meta("isaac_admin_trace2_atk_turns", 0)) > 0:
		isaac_trace2_pct = 0.30
		
	# Внутри метода get_unit_effective_atk_static(unit, allies) в battle_info_provider.gd:
	if milena_unit and milena_unit.is_alive() and unit.is_ally:
		if unit.id != "milena":
			var milena_eff := get_unit_effective_atk_static(milena_unit, allies)
			milena_flat_atk += milena_eff * 0.05
			# ИСПРАВЛЕНО: Обертон (+30%) применяется только к другим союзникам
			if int(milena_unit.get_meta("milena_overtone_turns", 0)) > 0:
				milena_overtone_pct = 0.30
			
	var vika_flat: float = 0.0
	if unit.id == "vika" and unit.has_meta("vika_e_atk_buff"):
		vika_flat = float(unit.get_meta("vika_e_atk_buff", 0.0))
		
	var lenskaya_t3_pct: float = 0.0
	if unit.has_meta("lenskaya_trace3_atk_percent"):
		lenskaya_t3_pct = float(unit.get_meta("lenskaya_trace3_atk_percent", 0.0))
		
	var keloist_flat_atk: float = 0.0
	if unit.has_meta("keloist_flat_atk_buff"):
		keloist_flat_atk = float(unit.get_meta("keloist_flat_atk_buff", 0.0))

	var shoji_swan_atk_pct: float = 0.0
	if unit.has_meta("shoji_swan_atk_turns") and int(unit.get_meta("shoji_swan_atk_turns", 0)) > 0:
		shoji_swan_atk_pct = 0.50

	var doceva_tears_pct: float = 0.0
	if unit.has_meta("doceva_tears_atk_buff_pct"):
		doceva_tears_pct = float(unit.get_meta("doceva_tears_atk_buff_pct", 0.0))

	var katarina_q_pct: float = 0.0
	if unit.has_meta("katarina_q_ally_atk_buff_turns") and int(unit.get_meta("katarina_q_ally_atk_buff_turns", 0)) > 0:
		katarina_q_pct = 0.15
	
	var galilean_flat_atk: float = 0.0
	if unit.has_meta("relic_galilean_atk_pct"):
		galilean_flat_atk = s.atk * float(unit.get_meta("relic_galilean_atk_pct", 0.0))
		
	var silhouette_flat_atk: float = 0.0
	if unit.has_meta("relic_silhouette_atk_pct"):
		silhouette_flat_atk = s.atk * float(unit.get_meta("relic_silhouette_atk_pct", 0.0))
		
	var extra_flat_atk: float = 0.0
	if unit.id == "kaori":
		var total_be: float = unit.stats.break_effect
		if unit.get_meta("weakness_concentration", false):
			total_be += 0.20 if unit.eidolon >= 2 else 0.0
		var living_enemies_count: int = 0
		var has_elite: bool = false
		for ally in allies:
			if ally is CombatUnit and not ally.is_ally and ally.is_alive():
				living_enemies_count += 1
				if ally.is_elite:
					has_elite = true
		if living_enemies_count == 1 and has_elite:
			total_be += 0.40
		if total_be > 2.0:
			var excess_be_percent: float = (total_be - 2.0) * 100.0
			extra_flat_atk += excess_be_percent * 15.0
			
	var standard_pct: float = unit.statuses.self_atk_buff_percent + unit.statuses.atk_buff_percent
	var standard_flat: float = unit.statuses.atk_buff_flat
	
	# Бафф Силы Атаки Ленской при выходе из «В изнанке» (+40% на 3 хода)
	var lenskaya_am_self_atk_pct := 0.0
	if unit.has_meta("lenskaya_am_atk_buff_turns") and int(unit.get_meta("lenskaya_am_atk_buff_turns", 0)) > 0:
		lenskaya_am_self_atk_pct = 0.40

	# Бафф Силы Атаки команды от Навыка E «Хранитель Ничто»
	var lenskaya_am_team_flat := 0.0
	if unit.has_meta("lenskaya_am_team_atk_turns") and int(unit.get_meta("lenskaya_am_team_atk_turns", 0)) > 0:
		lenskaya_am_team_flat = float(unit.get_meta("lenskaya_am_team_atk_boost", 0.0))

	# Бафф Силы Атаки союзникам Антиматерии от Следа 3 Вельзевул (+10% за каждое сердце, макс +40%)
	var velz_t3_pct := 0.0
	for ally in allies:
		if ally is CombatUnit and ally.id == "velzebul" and ally.is_alive():
			if _is_antimatter_member(unit):
				var hearts: int = int(ally.get_meta("velzebul_sinful_hearts", 0))
				velz_t3_pct = minf(float(hearts) * 0.10, 0.40)
	# Баффы Силы Атаки от Сангинии Ял (Навык Q, «Готовьтесь...», Эйдолон 4)
	var sanguinia_atk_pct := 0.0
	if unit.has_meta("sanguinia_q_atk_turns") and int(unit.get_meta("sanguinia_q_atk_turns", 0)) > 0:
		sanguinia_atk_pct += float(unit.get_meta("sanguinia_q_atk_buff", 0.40))
	if unit.has_meta("sanguinia_prep_atk_turns") and int(unit.get_meta("sanguinia_prep_atk_turns", 0)) > 0:
		sanguinia_atk_pct += float(unit.get_meta("sanguinia_prep_atk_buff", 0.60))
	if unit.has_meta("sanguinia_e4_atk_turns") and int(unit.get_meta("sanguinia_e4_atk_turns", 0)) > 0:
		sanguinia_atk_pct += float(unit.get_meta("sanguinia_e4_atk_buff", 0.40))
	
	return s.atk * (1.0 + standard_pct + q_pct + faction_pct + lc_pct + lost_edge_bonus + detroit_dynamic_atk_pct + relic_atk_pct + milena_overtone_pct + lenskaya_t3_pct + joan_gold_pct + stage_partner_pct + blazing_sun_pct + valramors_debuff_pct + isaac_trace2_pct + shoji_swan_atk_pct + doceva_tears_pct + katarina_q_pct + lenskaya_am_self_atk_pct + velz_t3_pct + sanguinia_atk_pct) + standard_flat + q_flat + extra_flat_atk + vika_flat + milena_flat_atk + keloist_flat_atk + galilean_flat_atk + silhouette_flat_atk + lenskaya_am_team_flat
	
static func get_skills_text(unit: CombatUnit) -> String:
	if unit is Memosprite:
		return _memosprite_skills(unit as Memosprite)
	match unit.id:
		MarinaAbilities.ID:
			return _marina_skills(unit.eidolon)
		SaraAbilities.ID:
			return _sara_skills(unit.eidolon)
		ArseniyAbilities.ID:
			return _arseniy_skills(unit)
		PusenkovAbilities.ID:
			return _pusenkov_skills(unit.eidolon)
		KaoriAbilities.ID:
			return _kaori_skills(unit.eidolon)
		ShojiAbilities.ID:
			return _shoji_skills(unit.eidolon)
		VoidSoldier.ID:
			return _void_soldier_skills()
		VoidElite.ID:
			return _void_elite_skills()
		"void_boss":
			return _void_boss_skills()
		"void_armored":
			return _void_armored_skills()
		"dasha":
			return _dasha_skills(unit.eidolon)
		"danill":
			return _danill_skills(unit.eidolon)
		"vika":
			return _vika_skills(unit.eidolon)
		"dotseva":
			return _dotseva_skills(unit.eidolon)
		"milena":
			return _milena_skills(unit.eidolon)
		"naama":
			return _naama_skills(unit.eidolon)
		"lenskaya":
			return _lenskaya_skills(unit.eidolon)
		"rimes":
			return _rimes_skills(unit.eidolon)
		"isaac":
			return _isaac_skills(unit.eidolon)
		"keloist":
			return _keloist_skills(unit.eidolon)
		"musienko":
			return _musienko_skills(unit.eidolon)
		"joan":
			return _joan_skills(unit.eidolon)
		"jeff":
			return _jeff_skills(unit.eidolon)
		"valramors":
			return _valramors_skills(unit.eidolon)
		"joan_spirit":
			return _joan_spirit_skills(unit.eidolon)
		"isaac_admin":
			return _isaac_admin_skills(unit.eidolon)
		"sara_admin":
			return _sara_admin_skills(unit.eidolon)
		"arseniy_admin":
			return _arseniy_admin_skills(unit.eidolon)
		"dasha_admin":
			return _dasha_admin_skills(unit.eidolon)
		"shoji_swan":
			return _shoji_swan_skills(unit.eidolon)
		"katarina":
			return _katarina_skills(unit.eidolon)
		"dotseva_crimson_tears":
			return _dotseva_crimson_tears_skills(unit.eidolon)
		"lenskaya_antimatter":
			return _lenskaya_antimatter_skills(unit.eidolon)
		"velzebul":
			return _velzebul_skills(unit.eidolon)
		"marina_sky_guardian":
			return _marina_sky_guardian_skills(unit.eidolon)
		"lenskaya_sky_guardian":
			return _lenskaya_sky_guardian_skills(unit.eidolon)
		"rimes_ascension":
			return _rimes_ascension_skills(unit.eidolon)
		"sanguinia":
			return _sanguinia_skills(unit.eidolon)
			
		"masked_silhouette":
			return "🎭 [color=red]СИЛУЭТ В МАСКЕ (БОСС)[/color] — ХП: 120000 / 180000\n\n" + \
			"[color=yellow]ФАЗА 1:[/color]\n" + \
			"⚔ Базовая атака: 100% СА по одной цели. Провоцирует доп. ход.\n" + \
			"🔷 Способность 1 (Доп. Ход): 120% СА центру и 60% соседям.\n" + \
			"🔹 Способность 2 (Раз в 4 х.): 999% СА по одной цели (не опускает ниже 1 ХП).\n" + \
			"✨ Способность 3 (1 раз за матч): 40% СА по всем героям на старте.\n\n" + \
			"[color=yellow]ФАЗА 2 (после воскрешения):[/color]\n" + \
			"⚔ Базовая атака: 70% СА центру и 20% соседям. Провоцирует доп. ход.\n" + \
			"🔷 Способность 1 (Доп. Ход): 40% СА по всем союзникам.\n" + \
			"🔹 Способность 2 (Раз в 4 х.): 80% СА всем союзникам и вешает статус «Балласт» на 2 хода.\n" + \
			"✨ Способность 3 (Старт Фазы 2): вешает на себя маску на 14 уровней (защита +40%). Каждый удар по боссу снижает уровень на 1, нанося союзнику 3% Квант. ХП. Если слои счищены до 0 за 1 ход босса — его защита падает на -20% навсегда, иначе бафф +40% защиты фиксируется вечно."

		"server_virus":
			return _server_virus_skills()
		"ortho_mutant":
			return _ortho_mutant_skills()
		"infected":
			return _infected_skills()
		"ortho_spore":
			return _ortho_spore_skills()
		"citadel_cleaner":
			return _citadel_cleaner_skills()
		"ortofetamin_horror":
			return _ortofetamin_horror_skills()
		"shoji_vz":
			return _shoji_vz_skills()
		"velzebul_boss":
			return _velzebul_boss_skills()
		"rimes_final_boss":
			return _rimes_final_boss_skills()
		"your_memories":
			return _your_memories_skills()
		"void_paws":
			return _void_paws_skills()
		
	return "Нет данных о способностях."

static func get_single_skill_text(unit: CombatUnit, skill_type: String) -> String:
	if unit == null:
		return ""
	var full_text: String = get_skills_text(unit)
	if full_text.is_empty() or full_text == "Нет данных о способностях.":
		return ""

	var target_char := ""
	var start_idx := -1
	match skill_type:
		"basic":
			target_char = "⚔"
		"enhanced_basic":
			if unit.id == "lenskaya_sky_guardian":
				start_idx = full_text.find("🏹 [b]Усиленная базовая")
				if start_idx == -1:
					start_idx = full_text.find("Усиленная базовая")
				target_char = "🏹"
			elif "💥" in full_text:
				target_char = "💥"
			else:
				target_char = "⚔"
		"skill_q":
			target_char = "🔷"
		"skill_e":
			target_char = "🔹"
		"ult":
			target_char = "✨"
		_:
			return ""

	if start_idx == -1:
		start_idx = full_text.find(target_char)
	if start_idx == -1:
		match skill_type:
			"basic": start_idx = full_text.find("Базовая")
			"enhanced_basic": start_idx = full_text.find("Усиленная")
			"skill_q": start_idx = full_text.find("Навык Q")
			"skill_e": start_idx = full_text.find("Навык E")
			"ult": start_idx = full_text.find("Сверхспособность")
		if start_idx == -1:
			return ""

	var all_markers := ["⚔", "💥", "🔷", "🔹", "✨", "💡", "💎", "⚡", "🎯", "🌙", "🌟", "💫", "🕊", "🔗", "🌌", "🌀", "•"]
	var end_idx := full_text.length()
	for m in all_markers:
		if m == target_char:
			continue
		var m_idx := full_text.find(m, start_idx + 1)
		if m_idx != -1 and m_idx < end_idx:
			if skill_type == "skill_e" and m == "🔹":
				continue
			end_idx = m_idx

	var result := full_text.substr(start_idx, end_idx - start_idx).strip_edges()
	return result

static func _marina_skills(eidolon: int) -> String:
	return "⚔ Базовая: 80% СА по одной цели. +1 ОН, +20 ЭН.\n" + \
	"🔷 Навык Q (1 ОН): 110% СА по всем врагам.\n" + \
	"🔹 Навык E (2 ОН): накладывает Подавление на всех врагов на 3 хода.\n" + \
	"✨ Сверхспособность (100 ЭН): 180% СА по всем, накладывает Подавление на 3 хода.\n" + \
	"💡 Талант: Подавление понижает скорость цели на 8% и её ШПЭ на 10% за уровень. " + \
	"Союзники наносят по целям на 10% больше урона (периодический урон повышен на 15%). " + \
	"Пробитие цели под Подавлением задерживает её ход на дополнительные 75%.\n" + \
	"⚡ Е1: Подавление считается DoT-уроном (до 5 стаков) и наносит 50% СА Марины в ход врага. Эффекты таланта складываются от количества стаков."

static func _sara_skills(eidolon: int) -> String:
	var e_str := ""
	if eidolon >= 1:
		e_str = "\n   Э1: базовая восстанавливает 10% ХП."
	return "⚔ Базовая: 55% СА. +1 ОН, +20 ЭН." + e_str + "\n🔷 Навык Q (1 ОН): лечение 20%+200 ХП, «Заплатка» 2 хода.\n🔹 Навык E (2 ОН): снять 1 дебафф, +20% к лечению, ускорение 30%, Заплатка.\n✨ Аря (140 ЭН): 80 ИД — смерть заблокирована; по окончании массовый хил.\n💡 Талант: Заплатка — хил в ход и возврат урона."

static func _arseniy_skills(unit: CombatUnit) -> String:
	var in_dev := ArseniyAbilities.is_new_development(unit)
	var header := ""
	if in_dev:
		header = "🔶 «Новая разработка» активна — усиленные версии доступны!\n\n"
	
	var q_line := ""
	if in_dev:
		q_line = "🔷 Усил. Q (1 ОН): +30% СА + 150 от СА Арсения союзнику, 1 ход."
	else:
		var free_str := " (1 ОН)"
		if unit.eidolon >= 2:
			free_str = " (бесплатно, Э2)"
		q_line = "🔷 Навык Q: 100% СА по 3 врагам" + free_str + "."
		
	var basic_extra := ""
	if in_dev:
		basic_extra = "\n⚔ Усил. базовая (1 ОН): «Тёмная печать» 2 хода."
		
	return header + "⚔ Базовая: 60% СА по одной цели." + basic_extra + "\n" + q_line + "\n🔹 Навык E (2 ОН): «Новая разработка» на 2 следующих действия.\n✨ Сверхспособность (110 ЭН): 230% СА, +1 ОН. Только в «Новой разработке».\n💡 Талант: усиление союзника / усил. базовая → +10% к своему действию."

static func _pusenkov_skills(eidolon: int) -> String:
	var e_str := ""
	if eidolon >= 3:
		e_str = " (Е3: урон +20%)"
	return "⚔ Базовая: 150% СА" + e_str + ". По «Живым или мёртвым» Кирилл тратит 1 ОН и продвигает себя на 100%.\n⚔ Усил. базовая: 280% СА (+30% от следа)" + e_str + ". Всегда Крит (крит. урон удваивается). Снимает «Живым или мёртвым» за доп. 300% СА (440% при Е6).\n🔷 Навык Q (1 ОН): Накладывает «Приоритетную Цель». Продвигает Кирилла на 80%, +20 СКР на 2 хода.\n🔹 Навык E (2 ОН): 70% СА" + e_str + ". Защита цели −40% на 1 ход, задержка цели на 65%.\n✨ Сверхспособность (160 ЭН): Кирилл Недосягаем до применения Усил. базовой. Накладывает «Приоритетную Цель» (повторно — «Живым или мёртвым»).\n💡 Талант: Каждая 4-я базовая атака усиленная. Враги с целями получают +20% (доп. +20% при Е2) крит. урона."

static func _kaori_skills(eidolon: int) -> String:
	return "⚔ Базовая: 100% СА по одной цели.
⚔ Усил. базовая: 150% СА, истощает стойкость на доп. 20% (30% при Е1). Восстанавливает 1 ОН при Е6.
🔷 Навык Q (1 ОН): Получает «В тумане» (Недосягаемость) на 2 хода. След. атака +100% Физ. урона.
🔹 Навык E (2 ОН): кидает сюрикен силой (50 * ЭП)% СА + 30% СА. При повторном выборе доступен Усиленный E (0 ОН).
🔹 Усиленный Навык E (0 ОН): наносит (100 * ЭП)% СА + 100% СА, снимает усиленное состояние.
✨ Сверхспособность (130 ЭН): наносит (100 * ЭП)% СА + 100% СА. Допускает бесплатный повтор на 2 хода.
💡 Талант: Нанесение урона делает след. базовую атаку усиленной. След 1: при собственном пробитии наносит доп. урон (150 * ЭП)% СА."

static func _shoji_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 120% СА выбранному противнику (E1 снижает огненное сопр. цели на 40% на 3 хода).\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН):[/color] 160% СА цели, взрывает все ДоТы (соседние цели получают 80% СА и 40% урона взрыва Горения).\n" + \
	"[color=yellow]🔹 Навык E (1 ОН):[/color] 70% СА цели и 30% СА соседям. Накладывает Горение Сёдзи (1 стак, 120% СА) на 3 хода.\n" + \
	"[color=yellow]✨ Сверхспособность (110 ЭН):[/color] 130% СА всем врагам. Взрывает все ДоТы на врагах, обновляет его Горения и вешает Горение на всех на 2 хода.\n" + \
	"[color=yellow]💡 Талант:[/color] Враги с Горением Сёдзи получают 120% СА урона за ход. За каждый дебафф DoT на цели защита цели падает на 2% (макс. 30%)."

static func _void_soldier_skills() -> String:
	return "⚔ Атака: 105% СА по случайному союзнику.\nКаждый 4-й ход: «Удар по площади» — 50% СА по всем союзникам."

static func _void_elite_skills() -> String:
	return "⚔ Атака: 110% СА по случайному союзнику.\nКаждый 2-й ход: «Волна Пустоты» — 85% СА по ВСЕМ союзникам.\nКаждый 3-й ход: «Поглощение» — лечит себя на 8% макс. ХП."

static func _void_boss_skills() -> String:
	return "⚔ Атака: 120% СА по одной цели.\nКаждые 3 хода: «Ледяное Заточение» — наносит урон и замораживает цель (пропуск хода).\nКаждые 4 хода: «Коллапс Звезд» — обрушивает АоЕ удар силой 110% СА по всем союзникам."

static func _void_armored_skills() -> String:
	return "⚔ Атака: 110% СА по одной цели.
Каждые 2 хода: «Адская броня» — получает на 40% меньше урона. Пробитие уязвимости снимет броню и нанесет x2 урон пробития."

static func _server_virus_skills() -> String:
	return "🌐 [color=red]СЕРВЕРНЫЙ ВИРУС (БОСС)[/color] — ХП: 405000\n\n" + \
	"⚔ Атака: 100% СА по одной цели.\n" + \
	"🔷 Переполнение буфера (Раз в 4 х.): 120% СА по всем героям (84% СА при 20+ Векторах). Если у отряда есть 20+ Векторов, урон снижен на 30%, босс получает 10% отраженного чистого урона и дает +5 Векторов. Иначе отряд теряет 15% энергии и получает -20% СА на 2 хода!\n" + \
	"🔹 Троянский скрипт (Раз в 4 х.): 100% СА по герою с наивысшей СА и накладывает «Троян» на 2 хода (-20% СА, тики 30% СА вируса). Наличие щита отражает 100% СА героя в босса!\n" + \
	"⚡ Задержка пакетов: 110% СА цели и 50% соседям, снижает их скорость на -15% на 2 хода.\n" + \
	"🛡 Пассивно — Файрвол: 4 слоя защиты (-25% входящего не-Бинарного урона). Каждый удар Бинарного урона сбивает 1 слой (+25% к Бинарному урону). При снятии всех слоёв отряд восстанавливает +10 Векторов, а босс получает +20% уязвимости на 2 хода. Пробитие уязвимости приносит +40 Векторов!"

static func _ortho_mutant_skills() -> String:
	return "🧬 [color=red]ОРТО МУТАНТ (ЭЛИТА)[/color] — ХП: 116000\n\n" + \
	"⚔ Разрастание биомассы: 150% СА по одной цели.\n" + \
	"☣ Выброс био-спор (Каждые 3 х.): 80% СА по всем союзникам и призывает до 2 Орто-спор.\n" + \
	"🧪 Пассивно — Кислотный мутаген: постоянно находится под воздействием мутагена (DoT-статус для Следа 3 Жоана Духа решимости на +50% КУ).\n" + \
	"💥 Слабость к AoE: Получает на 30% больше урона от AoE-атак (Эрудиция / атаки по площади).\n" + \
	"🦠 Симбиоз спор: Уничтожение каждой призванной Орто-споры сносит Орто Мутанту 30 ед. стойкости!"

static func _ortho_spore_skills() -> String:
	return "🦠 [color=orange]ОРТО-СПОРА[/color] — ХП: 27000\n\n" + \
	"⚔ Атака споры: 60% СА по одной цели.\n" + \
	"💥 При гибели: Снижает стойкость Орто Мутанта на 30 ед."

static func _infected_skills() -> String:
	return "☣ [color=orange]ЗАРАЖЁННЫЙ[/color] — ХП: 49500\n\n" + \
	"⚔ Инфекционный укус: 95% СА по одной цели. Если у цели нет щита, накладывает Выветривание на 2 хода.\n" + \
	"⚡ Пассивно — Данные вируса: При поражении восполняет +4 Вектора Консоли.\n" + \
	"💥 Нестабильный патоген: Если погибает при HP < 30%, взрывается, нанося 15% своего макс. HP соседним врагам."

static func _citadel_cleaner_skills() -> String:
	return "🤖 [color=orange]ЧИСТИЛЬЩИК ЦИТАДЕЛИ[/color] — ХП: 38000\n\n" + \
	"⚔ Протокол стерилизации: 100% СА по одной цели.\n" + \
	"🔷 Импульс фильтрации: 80% СА цели и по 40% СА соседям (50% шанс Горения на 2 хода).\n" + \
	"⚡ Сенсорная перегрузка (Пассивно): DoT или Бинарный урон снижают защиту на 20% на 2 хода и задерживают ход на 15%.\n" + \
	"💥 Взрыв ядра [Взломан]: При уничтожении взрывается, нанося 12% макс. ХП союзным врагам и накладывая Кровотечение на 2 хода (складывается до 5 раз)."

static func _ortofetamin_horror_skills() -> String:
	return "☣ [color=red]УЖАС ОРТОФЕТАМИНА (ЭЛИТНЫЙ)[/color] — ХП: 135000\n\n" + \
	"🛡 Симбиоз с Заражёнными: Получает на 25% меньше урона за каждого живого Заражённого (до -50%).\n" + \
	"🧬 Выброс мутагена: 60% СА по всему отряду и призыв до 2 Заражённых (1 раз в 3 хода).\n" + \
	"💉 Ортофетаминовый впрыск: 180% СА по бойцу с наивысшей СА (Катарина) и снижение его СА на 15% на 2 хода.\n" + \
	"💥 Химический разрыв: 120% СА цели и по 60% СА соседям."

static func _shoji_vz_skills() -> String:
	return "🖥 [color=red]СЁДЗИ ВЗ (БОСС — 2 ФАЗЫ)[/color] — ХП: 240000 / 290000\n\n" + \
	"[color=yellow]ФАЗА 1:[/color]\n" + \
	"🤖 Авторизация протокола: Призывает 2 Взломанных Чистильщиков Цитадели (1 раз в 3 хода).\n" + \
	"🛡 Брандмауэр Цитадели: Пока Чистильщики живы, прямой урон снижен на 40% (DoT-урон наносит 100%).\n" + \
	"📡 Потоковый импульс: 120% СА цели и по 60% соседям.\n" + \
	"👾 Вирусное проникновение: 180% СА цели и Вирусный ожог (DoT 80% СА) на 2 хода.\n" + \
	"🔄 Инверсия протокола: Атакует 2 случайные цели по 100% СА и задерживает их действие на 15%.\n\n" + \
	"[color=yellow]ФАЗА 2:[/color]\n" + \
	"⚡ Тотальная перезагрузка: Мгновенно восстанавливает ХП и призывает 2 Чистильщиков.\n" + \
	"🌐 Уязвимость ядра: Получаемый Бинарный и DoT урон увеличен на +5% за каждый активный DoT на боссе (макс. +30%).\n" + \
	"💥 Каскадный сбой (Сверхспособность): 150% СА по всем героям. Урон снижается на 10% за каждый стак Кровотечения на боссе (до -50% при 5 стаках!).\n" + \
	"⚡ Перегрузка терминала: 140% СА цели, 70% соседям (+40% урона по ослабленным)."

static func _velzebul_boss_skills() -> String:
	return "👑 [color=red]ВЕЛЬЗЕВУЛ (БОСС — 2 ФАЗЫ)[/color] — ХП: 320000 / 400000\n\n" + \
	"❄ Сопротивление Льду: 40% базового сопротивления Ледяному элементу.\n" + \
	"🛡 Панцирь Антиматерии: Входящий урон снижен на 25% (снимается физ. срезкой Катарины).\n" + \
	"💥 Нестабильность Антиматерии: При падении ХП ниже 80% и 50% наносит себе 7% макс. ХП чистым уроном (помогает снять Сломленный дух Катарины!).\n" + \
	"[color=yellow]ФАЗА 1:[/color]\n" + \
	"☠ Печать разложения: 200% СА по союзнику с наибольшей СА.\n" + \
	"🌌 Дыхание Бездны: 80% СА по всему отряду.\n" + \
	"🩸 Гнилостное расщепление: 115% СА цели, 55% соседям и срез защиты цели на -15% на 2 хода.\n\n" + \
	"[color=yellow]ФАЗА 2 (Истинная Владычица Мух):[/color]\n" + \
	"🌪 Рой Антиматерии: 80% СА по всему отряду.\n" + \
	"⚡ Смертоносное жало: 200% СА по одной цели.\n" + \
	"💥 Совершает серии из двух сокрушительных действий за ход!"

static func _rimes_final_boss_skills() -> String:
	return "👑 [color=red]РАЙМС • ФИНАЛЬНЫЙ БОСС (НЕДЕЛЬНЫЙ БОСС — 3 ФАЗЫ)[/color]\n\n" + \
	"🛡 Недельный босс: Иммунитет к Казни и расщеплению. 40% сопротивления мнимому урону.\n" + \
	"🌌 Тактика: Антиматерия (Ленская • Явление Антиматерии и Вельзевул).\n\n" + \
	"[color=yellow]ФАЗА 1 (ХП: 280 000 | СА: 2100 | ЗАЩ: 1150):[/color]\n" + \
	"⚔ Гравитационный раскол: 175% СА цели с наивысшей СА, 65% соседям (0 урона Ленской в Изнанке).\n" + \
	"❄ Ледяное расщепление энтропии: AoE 85% СА (урон снижен на 25%, если цель ускорена Вельзевул/следом).\n" + \
	"🌌 Сжатие анти-материи: AoE 100% СА + кража 10 Зеро (урон снижен на 20%, если Зеро > 0).\n\n" + \
	"[color=yellow]ФАЗА 2 (ХП: 380 000 | СА: 2200 | ЗАЩ: 1250):[/color]\n" + \
	"✨ Доступен «ХОР ЧЕЛОВЕЧЕСТВА» (Помощь на панели справа)!\n" + \
	"🕳 Сингулярность забвения: AoE 105% СА + Зона коллапса (3 стака: -20% входящего урона).\n" + \
	"🔀 Инверсия горизонтов: по 115% СА двум случайным союзникам.\n\n" + \
	"[color=yellow]ФАЗА 3 (ХП: 690 000 | СА: 2380 | ЗАЩ: 1350):[/color]\n" + \
	"🐾 Зов Бездны: призывает «Лапы Ничто» на все свободные позиции.\n" + \
	"👑 Сверхспособность «По воле дирижёра»: Подготовка 1 ход. На 2 ход босс и все живые лапы наносят массовый урон и сжигают энергию. Уничтожение ВСЕХ лап срывает атаку и срезает 30% Защиты босса на 2 хода!\n" + \
	"🌌 Пульсация сингулярности: AoE 90% СА (Зеро поглощает до 50% урона).\n\n" + \
	"[color=cyan]ПОМОЩЬ: «ХОР ЧЕЛОВЕЧЕСТВА» (Фазы 2 и 3):[/color]\n" + \
	"• 12 зарядов: +1 за ульту союзника (Каори/Катарина 1 раз за серию), +1 за пробитие босса, +1 за каждые 12 ходов отряда.\n" + \
	"• При 12 зарядах: игрок выбирает союзника -> 100% энергии (или 12 желаний Жоана). Врагам наносится 12 ударов Чистого урона (по 10% СА + 3% макс. ХП команды за удар)."

static func _your_memories_skills() -> String:
	return "💎 [color=cyan]ТВОИ ВОСПОМИНАНИЯ (ЭЛИТНЫЙ ВРАГ — МНИМЫЙ ЭЛЕМЕНТ)[/color] — ХП: 115 000\n\n" + \
	"Уязвимости: Квантовая, Ледяная, Электрическая.\n" + \
	"Тактика: Вельзевул (поддержка) и Марина (керри).\n" + \
	"❄ Пассивка «Отражение на льду»: когда герой накладывает дебафф, его Ледяной урон +15% на 3 хода.\n" + \
	"⏳ Пассивка «Тяжесть прошлого»: СА снижена на 8% за каждый дебафф (до -32%). Если скорость ниже базовой (подавление Марины), Защита снижена на 20%.\n\n" + \
	"[color=yellow]Способности:[/color]\n" + \
	"⏳ Фантомный кристалл: 150% СА мнимым уроном + Оцепенение (-20% скорости на 2 хода).\n" + \
	"⏳ Эхо забвения: AoE 90% СА мнимым уроном по всему отряду.\n" + \
	"💎 Призма памяти: окружает себя щитом-призмой. Любая ледяная атака разбивает призму, откладывает ход врага на 25% и восстанавливает +1 Очко Навыков!"

static func _void_paws_skills() -> String:
	return "🐾 [color=purple]ЛАПА НИЧТО (СВИТА ФИНАЛЬНОГО БОССА)[/color] — ХП: 45 000\n\n" + \
	"Уязвимости: Квантовая, Ледяная, Физическая.\n" + \
	"🐾 Хватка Бездны: атакует случайного союзника (75% СА) и высасывает 15 энергии.\n" + \
	"🌌 Сдерживание Зеро: за каждые 20 Зеро команды потеря энергии снижается на 5 (при 60+ Зеро высасывание полностью блокируется!), а Защита лапы падает на 10% за каждые 20 Зеро."

static func _dasha_skills(eidolon: int) -> String:
	return "⚔ Базовая: 60% СА по одной цели.
⚔ Усил. базовая: 160% СА цели и 90% соседям (в Танце кругов).
🔷 Навык Q (1 ОН): 220% СА цели и соседям. Пробитым уязвимостям наносит урон Суперпробития.
🔹 Навык E (2 ОН): Переходит в «Танец кругов». Сбрасывается, если HP упадет ниже 20%. Мгновенный взмах бонус-атаки (След 2).
✨ Сверхспособность (140 ЭН): Даша теряет 30% макс. ХП и входит в «Перегрузку» на 2 хода (Навык Q бесплатен, бонус-атаки усилены).
💡 Талант: В Танце кругов пробитие дает стак «Пируэта». На 3 стаках Даша немедленно бьет бонус-атакой."

static func _danill_skills(eidolon: int) -> String:
	return "⚔ Базовая: 50% защиты Данилла по одной цели (100% при Е1).\n" + \
	"🔷 Навык Q (1 ОН): щит на союзника (40% ЗАЩ + 300) на 3 хода.\n" + \
	"🔹 Навык E (2 ОН): щит на Данилла (50% ЗАЩ + 400) на 3 хода. Входит в Провокацию на 3 хода, снижая урон пати на 30%. При разрушении щита — АоЕ бонус-атака и +1 ОН.\n" + \
	"✨ Сверхспособность (130 ЭН): Массовый щит на всех (25% ЗАЩ + 300) на 2 хода.\n" + \
	"💡 Талант: Получение урона дает до +30% защиты. Погибший союзник дает постоянные +30% защиты отряду."

static func _vika_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 50% СА выбранному квантовому врагу.\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 140% СА цели и 40% от макс. ХП Вики соседям.\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Тратит 50% текущего ХП (до 1 ед. если ХП <= 50%). СА увеличивается на 50% от потерянного ХП на 3 хода, действие продвигается на 50%.\n\n" + \
			"[color=yellow]✨ Сверхспособность (110 ЭН):[/color] Наносит 280% СА + 30% макс. ХП цели, соседи получают 50% СА + 30% макс. ХП. Входит в Пробуждение на 2 хода.\n\n" + \
			"[color=yellow]💡 Талант:[/color] Если ХП Вики опустилось до 20%, восстанавливает 100% ХП и продвигает действие. Может сработать 1 раз за бой.\n\n" + \
			"[color=cyan]Пробуждение:[/color] Лечит 30% макс. ХП в начале хода, наносимый урон снижен на 20%."

static func _dotseva_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 110% СА выбранному противнику.
[color=yellow]⚔ Усиленная базовая:[/color] Наносит АоЕ урон 45% СА + (Калибровка * 40).
[color=yellow]🔷 Навык Q (1 ОН):[/color] 165% СА + 300 цели, 100% СА + 50 соседям.
[color=yellow]🔷 Усиленный Q (1 ОН):[/color] Наносит АоЕ урон в размере (Калибровка * 10)% СА + 350. Дает +1 Калибровку за каждого пораженного врага (След 3).
[color=yellow]🔹 Навык E (2 ОН):[/color] Доцева получает +5 стаков Калибровки и бьет АоЕ бонус-атакой силой 100% СА + 300.
[color=yellow]🔹 Усиленный Навык E (1 ОН):[/color] Вешает статус 'Должник' на 3 врагов. При их смерти Доцева получает +2 стака Калибровки, а соседи получат урон. (Е6 вешает Должника на всех, а навык связывает урон).
[color=yellow]✨ Сверхспособность (100 ЭН):[/color] Входит в «Легкий туман» на 2 хода, усиливая приемы.
[color=cyan]След 2:[/color] Каждый свой ход Доцева гарантированно получает +2 заряда Калибровки."

static func _milena_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 100% СА, снижает защиту цели на 20% на 1 ход (Е2: задерживает на 35%, Е4: продвигает Милену на 40%).
[color=yellow]🔷 Навык Q (1 ОН):[/color] Забирает у союзников по 10% макс. энергии и возвращает им её обратно. Продлевает Обертон на 3 хода.
[color=yellow]🔹 Навык E (2 ОН):[/color] Накладывает Обертон на 3 хода (СА пати +30% от СА Милены, скорость +15%, пробитие задерживает цель на доп. 50%).
[color=yellow]✨ Сверхспособность (300 ЭН):[/color] Заливает всю ЭН Обреченным и заставляет их ультовать по цепочке.
[color=cyan]Талант:[/color] Увеличивает ЭП союзников на 40% и СА на 5% от СА Милены."

static func _naama_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 80% СА (Е1: +20% урона). Накладывает 2 стака Опьянения (След 3).\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 120% СА цели и 50% соседям, накладывает по 3 стака Опьянения.\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Все враги с Опьянением получают 40% слабость к DoT на 2 хода.\n" + \
			"Если стаков > 10: после DoT их действие откладывается на 15%.\n" + \
			"Если стаков = 20: ЗАЩ падает на 20% до сброса стаков.\n\n" + \
			"[color=yellow]✨ Сверхспособность (130 ЭН):[/color] Наносит 100% СА всем врагам и накладывает «Поцелуй бездны» (урон врага -20%, ЗАЩ -15% по Следу 2).\n" + \
			"В следующий ход врага стаки Опьянения не сбросятся.\n\n" + \
			"[color=cyan]💡 Талант:[/color] В свой ход враг под Опьянением получает Wind DoT в размере (6% СА + 40) за каждый стак и сбрасывает стаки.\n" + \
			"Если DoT срабатывает вне хода врага, он дополнительно получает 2 стака Опьянения (3 при Е2)."

static func _lenskaya_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 110% СА. В «Жале» заменяется на Усиленную (160% центру, 60% соседям).\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 180% СА всем и замедляет на 20% на 2 хода.\n" + \
			"В «Жале» накладывает «Награду за голову» на 1 х (3 х при Е4). Если союзник бьет эту цель, Ленская совершает FUA силой 50% СА (70% цели + 40% соседям, если союзник ударил бонус-атакой. Е1 бьет 70% по всем, Е6 бьет чистым уроном).\n\n" + \
			"[color=yellow]🔹 Навык E (1 ОН):[/color] Потребляет все стаки Манипуляции и наносит выбранному врагу (26 * Манипуляция)% СА, и (7 * Манипуляция)% СА соседям.\n\n" + \
			"[color=yellow]✨ Сверхспособность (130 ЭН):[/color] 80% СА всем врагам, вход в «Жало» на 3 хода, даёт +2 Манипуляции, След 2 делает авто-выстрел по самому толстому врагу.\n\n" + \
			"[color=cyan]💡 Талант:[/color] Любая бонус-атака даёт Ленской +1 Манипуляцию (максимум — 47). Каждый заряд до 15 даёт ей +5% крит. шанса и +3% урона FUA всей команде.\n" + \
			"[color=cyan]След 3:[/color] Бонус-атака союзника повышает его СА на 15% на 2 хода (суммируется до 2х раз)."

static func _rimes_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 160% СА (заменяется на Усиленную в Изоляции или навсегда при Е4).\n" + \
			"[color=yellow]⚔ Усиленная базовая:[/color] Наносит 270% СА.\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 270% СА. Если ХП цели < 20% (и она не босс/элита), то Казнится (Е6 казнит боссов).\n" + \
			"[color=yellow]🔷 Улучшенный Q (1 ОН):[/color] Наносит 350% СА, снижает СА цели на 40% на 1 ход. Активируется в Изоляции.\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Вход в «Вечную Изоляцию» с противником (атакуют только друг друга, иммунитет к DoT и внешнему урону).\n" + \
			"Если ХП цели падает ниже 15% — она Казнится, а Раймс получает +1 ОД.\n" + \
			"Если Раймс умирает — избегает смерти, лечится на 30%, враг лечится на 70% утерянного ХП.\n\n" + \
			"[color=yellow]✨ Сверхспособность (140 ЭН):[/color] Наносит 500% СА выбранному противнику. Восстанавливает Раймсу 30% ХП. Казнит обычных врагов при <30% ХП. Даёт +1 ОН в Изоляции.\n\n" + \
			"[color=cyan]💡 Талант:[/color] Убийство врага даёт +10% скорости и +6% пробития сопр. (макс. 4 стака, 6 при Е1). На макс. стаках даёт +35% крит. шанса и 100% энергии по Следу 3.\n" + \
			"[color=cyan]Э1:[/color] Макс. стаки увеличены до 6. В начале боя Раймс мгновенно получает 2 стака таланта.\n" + \
			"[color=cyan]Э2:[/color] Убийство врага дает доп. действие (1 раз за ход)."

static func _isaac_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 70% СА выбранному противнику. След 3: продвигает действие Айзека на 20%.\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 75% СА всем врагам и даёт +2 стака «Теории на практике».\n" + \
			"На 8 стаках заменяется на Улучшенный Q (0 ОН при Е2): продвигает действие союзника на 100%, увеличивает его урон на +50% на 1 ход (Е4 снимает с него все ослабления).\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Наносит 100% СА цели и 50% соседям, повышая получаемый ими КУ на +35%, а наносимый ими урон падает на −20% на 3 хода.\n\n" + \
			"[color=yellow]✨ Сверхспособность (120 ЭН):[/color] Повышает КУ союзника на +60% и скорость на +16 ед. на 2 хода.\n\n" + \
			"[color=cyan]💡 Талант:[/color] Использование ульты союзниками даёт Айзеку +1 стак «Теории на практике» (макс 8). На 8 стаках Q становится Улучшенным.\n" + \
			"[color=cyan]След 1:[/color] Урон Айзека +50%, пока союзник под его ультимейтом.\n" + \
			"[color=cyan]След 2:[/color] Если в пати есть Сара и на Айзеке есть «Заплатка», он восстанавливает 5 энергии в начале хода."

static func _keloist_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 80% СА chosen врагу. Урон стойкости: 50% от стандарта.\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 90% СА всем врагам. Если на ком-то в пати есть «Ортощит», продвигает действие Келойста на 30%.\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Накладывает Ортощит на 3 хода союзнику. Получаемый им урон снижен на 40%. При его атаках Келойст дополнительно наносит 20% СА (без урона стойкости, макс 1 раз за ход по каждой цели. Е6 снимает 1 дебафф при касте).\n\n" + \
			"[color=yellow]✨ Сверхспособность (120 ЭН):[/color] Наносит 160% СА всем врагам. Урон стойкости: 125% от стандарта (Е1: +10% урона по целям с <30% ХП).\n\n" + \
			"[color=cyan]💡 Талант:[/color] Удары союзников по врагам дают Келойсту стаки «Командования» (макс 20). Каждый стак даёт ему +3% крит. шанса и +2% СА союзникам от СА Келойста.\n" + \
			"[color=cyan]След 1:[/color] Союзник под Ортощитом получает +20% СА от СА Келойста.\n" + \
			"[color=cyan]След 2:[/color] Келойст восстанавливает 5 энергии за каждого побежденного врага."

static func _musienko_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 100% от макс. ХП. В «Аннигиляции» заменяется на Усиленную (130% ХП центру, 70% соседям).\n\n" + \
			"[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 220% от макс. ХП выбранной цели (+30% урона, если ХП цели < 40%).\n" + \
			"В «Аннигиляции» наносит 300% ХП и режет защиту на −25% до окончания состояния.\n\n" + \
			"[color=yellow]🔹 Навык E (2 ОН):[/color] Вход в «Аннигиляцию бытия» (скорость +80%, Навык E блокируется. Повтор приемов досрочно прекратит состояние и взорвет 30%/60% накопленного урона чистым уроном).\n\n" + \
			"[color=yellow]✨ Сверхспособность (140 ЭН):[/color] Исцеляет Мусиенко на 20% ХП, наносит 330% ХП цели и 170% соседям. Казнит центр при <10% ХП.\n\n" + \
			"[color=cyan]💡 Талант:[/color] Использование навыков тратит 15% ХП. Каждое получение урона/расход ХП дает стаки (макс 6). При 6 стаках бьет FUA силой 160% ХП по всем и лечит 30% ХП.\n" + \
			"[color=cyan]След 3:[/color] макс. ХП повышается на +10% за каждого напарника из Рассвета Хаоса в отряде."

static func _joan_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака:[/color] Наносит 100% СА выбранной цели.
[color=yellow]🔷 Навык Q (1 ОН):[/color] Наносит 120% СА выбранному противнику и моментально провоцирует по нему Бонус-атаку Таланта (110% СА).
[color=yellow]🔹 Навык E (2 ОН):[/color] Наносит урон в размере 20% макс. ХП Жоану, продвигает выбранного врага на 100%. Накладывает дебафф «Не промахнись» на 2 хода: если враг один, урон по нему увеличен на +50%, иначе на +20.
[color=yellow]✨ Сверхспособность (100 ЭН):[/color] Наносит 200% СА выбранному противнику и дает +1 уровень «Кофейного ликёра». (След 1: дает Марине +20 энергии при касте).
[color=cyan]💡 Талант:[/color] В начале хода дает Жоану 1 стак «Кофейного ликёра» (макс 2). Когда атака союзника задевает всех живых врагов, Жоан тратит 1 стак ликёра и наносит Бонус-атаку в размере 70% СА по самому плотному противнику.
[color=cyan]След 2:[/color] Если противник один, Взрывные атаки союзников наносят ему на 10% больше урона, а Групповые атаки — на 75% больше урона."

# === НАЙДИТЕ И ОБНОВИТЕ СТРОКИ НАВЫКА Е И ТАЛАНТА В _jeff_skills() ===
static func _jeff_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака [Одиночная атака]:[/color] Наносит 100% СА выбранной цели. (Е4: лечит Джеффа на 10% макс. ХП).
[color=yellow]🔷 Навык Q (1 ОН) [Восстановление]:[/color] Лечит выбранного союзника на 20% макс. ХП Джеффа + 200, и соседей на 10% макс. ХП Джеффа + 50.
[color=yellow]🔹 Навык E (2 ОН) [Ослабление]:[/color] С базовым шансом 85% накладывает статус «Бассы! Слушай!» (Шок) на цель и двух её соседей на 2 хода.
[color=yellow]✨ Сверхспособность (160 ЭН) [Восстановление]:[/color] Массовый хилл отряда на 15% макс. ХП Джеффа + 200, заливает союзникам +20 энергии. (След 1: ультимейт обновляет длительность всех активных DoT на врагах).
[color=cyan]💡 Талант «Пошумите!» [Одиночная атака]:[/color] В начале хода Джефф получает статус «Пошумите!». При базовой атаке союзника Джефф тратит статус и проводит Бонус-атаку силой 30% макс. ХП Джеффа, с базовым шансом 85% накладывая на цель дебафф «Бассы! Слушай!».
[color=cyan]След 2:[/color] Наложение дебаффа «Бассы! Слушай!» лечит союзника с самым низким процентом ХП на 8% макс. ХП Джеффа + 50.
[color=cyan]След 3:[/color] Проведение бонус-атаки повышает исходящее исцеление Джеффа на 20% на 1 ход."

static func _valramors_skills(eidolon: int) -> String:
	return "[color=yellow]⚔ Базовая атака [Одиночная атака]:[/color] Наносит 120% СА выбранной цели.
[color=yellow]🔷 Навык Q (1 ОН) [Одиночная / Групповая при Е6]:[/color] Наносит 190% СА цели с базовым шансом 120% на срез защиты −40% на 2 хода (при Е6 бьет всех врагов).
[color=yellow]🔹 Навык E (1 ОН) [Поддержка]:[/color] Вешает «Передачу порчи» на союзника: его следующая атака срежет защиту цели на −40% на 3 хода (при мульти-ударе вешается на самого толстого врага).
[color=yellow]✨ Сверхспособность (120 ЭН) [Взрывная атака]:[/color] Наносит 300% СА цели и 100% соседям. Казнит не-боссов с ХП < 10% после атаки. Если ХП цели > 50%, вешает уязвимость к урону +20% на 2 хода. (Е4: задерживает ход на 20%).
[color=cyan]💡 Талант «Приказ принят» [Ослабление]:[/color] Каждая атака Валраморса с базовым шансом 100% режет АТК врага на -15%, СКР на -8% и вешает уязвимость к стихии первого героя в отряде на 3 хода.
[color=cyan]След 2:[/color] ШПЭ Валраморса увеличен на +35% от его шанса крит. попадания.
[color=cyan]След 3:[/color] Если Валраморс стоит на 1 месте (или всегда при Е6), его Крит. урон повышен на +80%, а Сила атаки повышена на +(ШПЭ)%."

static func _joan_spirit_skills(eidolon: int) -> String:
	return "[color=gold]⚔ Базовая атака [Одиночная]:[/color] 80% СА, дает +1 «Последнее желание».\n" + \
	"[color=gold]⚔ Усиленная базовая [Взрывная]:[/color] 220% СА цели и 180% соседям. Дает +2 «Сожаления» (0 ОН).\n\n" + \
	"[color=yellow]🔷 Навык Q (0 ОН) [Групповая]:[/color] 120% СА всем врагам. Дает «Сожаление» за каждого пораженного врага.\n\n" + \
	"[color=yellow]🔹 Навык E (4 Сожаления, 3 при Е1) [Групповая]:[/color] 300% СА всем (40 стойкости). За каждого отсутствующего врага ниже 5 наносит доп. 100% СА случайной цели. Дает +1 «Последнее желание» (+2 при Е1).\n\n" + \
	"[color=gold]✨ Сверхспособность:[/color]\n" + \
	"• Первое применение (12 Желаний): Вход в «Форму духа» (урон по Жоану -40%, все враги получают Мнимую уязвимость, открыты усиленные навыки).\n" + \
	"• Повторные применения (8 Желаний): 380% СА всем, игнорируя сопротивление. Если враг один — разделяет его на 5 целей (ХП делится на 5 и умножается на 3). Основная цель сохраняет умения, а копии в свой ход атакуют случайного союзника на 5% СА (позволяя Жоану быстрее копить Желания)!\n\n" + \
	"[color=cyan]💡 Талант:[/color] До Формы духа бьет авто-базовой по самому толстому врагу. Атаки врагов по отряду и урон себе дают по +1 Желанию за ход. При гибели не умирает, а сбрасывает Форму духа и лечится до 10% ХП!\n" + \
	"[color=cyan]След 1:[/color] Ульты и FUA союзников дают стаки золота (+4% СА пати за стак, до +48%).\n" + \
	"[color=cyan]След 2:[/color] Повторные применения Сверхспособности наносят на +30% больше урона, если живых врагов <= 3. Если остался один живой противник, то за каждые 4 атаки по нему любыми союзниками Жоан восстанавливает 1 «Последнее желание».\n" + \
	"[color=cyan]След 3:[/color] Если на враге есть DoT, получаемый им DoT урон снижается на 90%, но получаемый Крит. урон увеличивается на +50%."

static func _isaac_admin_skills(eidolon: int) -> String:
	return "[color=cyan]🌐 БИНАРНЫЙ УРОН:[/color] Увеличивается на +1% за каждый Вектор. Игнорирует общие баффы урона (до E6), но усиливается дебаффами врагов и критует.\n\n" + \
	"[color=yellow]⚔ Базовая атака [Одиночная]:[/color] 100% СА физ. урона.\n" + \
	"[color=cyan]⚔ Усиленная базовая [Взрывная]:[/color] 180% СА цели и 120% соседям Бинарным уроном. E6: Восстанавливает 20 Векторов.\n\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН) [Взрывная]:[/color] 170% цели и 80% соседям. Даёт +5 Векторов.\n" + \
	"[color=cyan]🔷 Улучшенный Q (1 ОН) [Взрывная]:[/color] Бинарный урон 250% цели и 160% соседям. Если Векторов < 50 даёт +8 Векторов, если >= 50 урон +40% (E4: накладывает уязвимость к Бинарному урону 20% на 2 хода. След 3: за каждые 10 Векторов +12% СА центру).\n\n" + \
	"[color=yellow]🔹 Навык E (1 ОН) [Отскоки / Протокол]:[/color] Разблокируется после 50 Векторов. 5 ударов по 70% СА Бинарным уроном (+40% урона при >= 60 Векторах). Если вся пати из Консоли и активен Взлом — активирует совместную атаку всех членов Консоли! След 2: +30% СА на 2 хода.\n\n" + \
	"[color=gold]✨ Сверхспособность (250 ЭН):[/color] Вход в «Взлом» на 3 хода (усиливает Базовую и Q). E2: Даёт 60 Векторов.\n\n" + \
	"[color=cyan]💡 Талант:[/color] Получение Векторов заливает столько же энергии. При переваливании за 101 Вектор проводит моментальный удар 400% СА Бинарным уроном по всем (-101 Вектор). E2: Атака таланта игнорирует 20% защиты цели.\n\n" + \
	"[color=cyan]Следы:[/color]\n" + \
	"• След 1: В состоянии «Взлом» наносимый Бинарный урон всех союзников увеличивается на 20%.\n" + \
	"• След 2: Навык Е увеличивает силу атаки Айзека на 30% на 2 хода.\n" + \
	"• След 3: За каждые 10 Векторов Улучшенный Навык Q дополнительно наносит центральной цели физ. Бинарный урон 12% СА Айзека.\n\n" + \
	"[color=purple]Эйдолоны:[/color]\n" + \
	"• Е1: В начале хода любого союзника (кроме Айзека), Айзек восстанавливает 3 Вектора.\n" + \
	"• Е2: Сверхспособность даёт 60 Векторов. Атака таланта игнорирует 20% защиты цели.\n" + \
	"• Е3: Уровень Базовой атаки и Навыков +20%.\n" + \
	"• Е4: Улучшенный Навык Q накладывает уязвимость к Бинарному урону 20% на поражённых врагов на 2 хода.\n" + \
	"• Е5: Уровень Таланта и Сверхспособности +20%.\n" + \
	"• Е6: Весь урон союзников считается Бинарным (+исходный элемент) и получает усиления урона. Усиленная Базовая атака восстанавливает 20 Векторов."

static func _sara_admin_skills(eidolon: int) -> String:
	return "[color=cyan]🌐 БИНАРНЫЙ УРОН:[/color] Увеличивается на +1% за каждый Вектор отряда.\n\n" + \
	"[color=yellow]⚔ Базовая атака [Одиночная]:[/color] 70% СА физ. урона. След 1: восстанавливает 10 Векторов (Е2: увеличивает получаемый врагом урон на 30% на 2 хода).\n\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН) [Поддержка]:[/color] Зона «Среда разработки» на 3 хода. Бинарный урон пати увеличивается на +1% за каждую единицу скорости Сары выше 100 (до +60%). Каждое действие Сары даёт +3 Вектора.\n\n" + \
	"[color=yellow]🔹 Навык E (1 ОН) [Групповая]:[/color] Открывается после 30 Векторов на весь бой. 80% СА всем врагам Бинарным уроном, восстанавливает 15 Векторов (Е1: даёт пати +30% скорости на 2 хода).\n\n" + \
	"[color=gold]✨ Сверхспособность (180 ЭН):[/color] Даёт +20 Векторов. Немедленно заставляет ВСЕХ членов Консоли в пати активировать Навык E с фиксированными 30 Векторами (даже если он не открыт)! Пробитие всех типов сопротивления пати +20% на 3 хода (Е2: восстанавливает 1 ОН).\n\n" + \
	"[color=cyan]💡 Талант:[/color] При 100 Векторах фиксирует пул, продвигает Консоль на 100%, собирает излишек и на следующем сдвиге шкалы вливает его обратно (кд 3 хода).\n\n" + \
	"[color=cyan]Следы:[/color]\n" + \
	"• След 1: Базовая атака восстанавливает 10 Векторов.\n" + \
	"• След 2: За каждого союзника Консоли восстанавливает в начале боя 20 энергии.\n" + \
	"• След 3: Если Векторы >= 30, КШ и КУ всех союзников повышается на 20% и 50% соответственно.\n\n" + \
	"[color=purple]Эйдолоны:[/color]\n" + \
	"• Е1: Навык Е увеличивает скорость всех союзников на 30% на 2 хода (не складывается).\n" + \
	"• Е2: Сверхспособность восстанавливает 1 ОН. Базовая атака увеличивает получаемый врагом любой урон на 30% на 2 хода.\n" + \
	"• Е3: Уровень Базовой атаки и Навыков +20%.\n" + \
	"• Е4: Наносимый Сарой Бинарный урон увеличивается на 40%.\n" + \
	"• Е5: Уровень Таланта и Сверхспособности +20%.\n" + \
	"• Е6: Когда союзник наносит Бинарный урон, Сара наносит доп. урон 30% СА, а действие всех союзников продвигается на 3%.\n\n" + \
	"[color=orange]⚡ Техника [Поддержка]:[/color] Даёт +20 Векторов и +30% Бинарного урона пати на 3 хода."

static func _arseniy_admin_skills(eidolon: int) -> String:
	return "[color=cyan]🌐 БИНАРНЫЙ УРОН:[/color] Увеличивается на +1% за каждый Вектор отряда.\n\n" + \
	"[color=yellow]⚔ Базовая атака [Одиночная]:[/color] 70% СА квантового урона.\n\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН) [Одиночная]:[/color] 120% СА квантового урона. Шанс 85% снизить Защиту цели на -30% на 2 хода (Е2: базовый шанс 100% снизить квант. сопротивление цели на 12% на 2 хода).\n\n" + \
	"[color=yellow]🔹 Навык E (2 ОН) [Групповая]:[/color] Открывается после 40 Векторов. 110% СА всем врагам Бинарным квантовым уроном. Шанс 85% увеличить получаемый ими Бинарный урон на +30% на 3 хода. След 1: При активации вне очереди восстанавливает 1 ОН.\n\n" + \
	"[color=gold]✨ Сверхспособность (150 ЭН) [Взрывная]:[/color] 180% СА центру и 90% соседям (шанс 85% снизить их исходящий урон на 30%). Если в отряде есть Консоль — урон становится Бинарным, а защита целей дополнительно падает на -20%!\n\n" + \
	"[color=cyan]💡 Талант:[/color] Удары союзников по врагам со срезанной Арсением защитой дают 3 Векторов. При превышении 150 Векторов -> немедленный АоЕ удар 300% СА Бинарным уроном с обнулением всех Векторов!\n\n" + \
	"[color=cyan]Следы:[/color]\n" + \
	"• След 1: Когда Навык Е активируется вне его хода (например, ультой Сары), он восстанавливает 1 очко навыков.\n" + \
	"• След 2: Если текущее значение Векторов > 40, то получаемый всеми противниками Бинарный урон увеличивается на 20%.\n" + \
	"• След 3: Если союзник использует Сверхспособность и тратит > 200 единиц энергии, Арсений увеличивает получаемый противниками урон на 30% на 3 хода (не складывается).\n\n" + \
	"[color=purple]Эйдолоны:[/color]\n" + \
	"• Е1: Победа над противником восстанавливает 5 энергии Арсению.\n" + \
	"• Е2: Навык Q имеет базовый шанс 100% понизить квантовое сопротивление цели на 12% на 2 хода.\n" + \
	"• Е3: Уровень Базовой атаки и Навыков +20%.\n" + \
	"• Е4: При атаке противника с ослаблениями Арсений наносит дополнительный Бинарный урон 40% от своей СА.\n" + \
	"• Е5: Уровень Таланта и Сверхспособности +20%.\n" + \
	"• Е6: Если Векторы >= 60, все типы сопротивлений противников понижаются на 20% (пока Векторы >= 60).\n\n" + \
	"[color=orange]⚡ Техника [Поддержка]:[/color] В начале боя даёт +10 Векторов."

static func _dasha_admin_skills(eidolon: int) -> String:
	return "[color=cyan]🌐 БИНАРНЫЙ УРОН:[/color] Увеличивается на +1% за каждый Вектор отряда.\n\n" + \
	"[color=yellow]⚔ Базовая атака [Одиночная]:[/color] 50% ЗАЩ мнимого урона. След 3: восстанавливает 2 Цифровых следа.\n\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН) [Восстановление]:[/color] Сбрасывает Цифровой след до 0. Если было ровно 30 — исцеляет пати на 20% ЗАЩ Даши (Е6: Бинарный урон отряда +30% на 2 хода).\n\n" + \
	"[color=yellow]🔹 Навык E (2 ОН) [Групповая]:[/color] Открывается после 80 Векторов. 60% ЗАЩ Бинарным уроном всем врагам (Е2: урон +20%) и накладывает щит (20% ЗАЩ + 150) на 3 хода, усиленный Талантом (+3% за каждый Цифровой след).\n\n" + \
	"[color=gold]✨ Сверхспособность (210 ЭН) [Поддержка]:[/color] Даёт +20 Векторов и обновляет длительность всех щитов Даши до 3 ходов. Если есть Консоль — Бинарный урон отряда повышается на +50% на 1 ход.\n\n" + \
	"[color=cyan]💡 Талант:[/color] Накапливает до 30 «Цифровых следов» (+3% к прочности щитов за стак). След 1: +1 след за каждые 10 Векторов команды. След 2: Удар по щиту Даши даёт +1 Вектор и +2 следа.\n\n" + \
	"[color=cyan]Следы:[/color]\n" + \
	"• След 1: За каждые 10 полученных командой Векторов Даша получает 1 Цифровой след.\n" + \
	"• След 2: Когда союзник под действием щита Даши получает урон, команда получает 1 Вектор, а Даша получает 2 Цифровых следа.\n" + \
	"• След 3: Базовая атака восстанавливает 2 Цифровых следа.\n\n" + \
	"[color=purple]Эйдолоны:[/color]\n" + \
	"• Е1: За каждые 100 ед. защиты выше 3000 Даша получает 150 силы атаки.\n" + \
	"• Е2: Наносимый Навыком Е Бинарный урон увеличивается на 20%.\n" + \
	"• Е3: Уровень Базовой атаки и Навыков +20%.\n" + \
	"• Е4: Если здоровье любого союзника опускается ниже 20%, Даша немедленно применяет Навык Е без затрат ОН (1 раз за бой).\n" + \
	"• Е5: Уровень Таланта и Сверхспособности +20%.\n" + \
	"• Е6: Если использование Навыка Q тратит 30 Цифровых следов, Даша увеличивает Бинарный урон отряда на 30% на 2 хода.\n\n" + \
	"[color=orange]⚡ Техника [Поддержка]:[/color] Даёт +10 Цифровых следов и снижает входящий урон пати на 40% на 2 хода."

static func _shoji_swan_skills(eidolon: int) -> String:
	return "[color=cyan]🌐 БИНАРНЫЙ АДАПТЕР (СЁДЗИ • ЛЕБЕДИНОЕ ОЗЕРО):[/color] Роль зависит от позиции в отряде!\n" + \
	"[color=yellow]• Слот 1 (ДД) — Стойка «Вирус»:[/color] Все враги получают +50% Бинарного урона. Навык Q наносит Бинарный урон 170% цели и 55% соседям. Сверхспособность наносит на 35% больше Бинарного урона. (E2: Бинарный урон союзников +50%, свой КУ +1% за Вектор).\n" + \
	"[color=yellow]• Слот 2–4 (Саппорт / Сап-ДД) — Стойка «Танец»:[/color] В начале боя повышает Скорость всех союзников на +16%. Не-Бинарный урон союзников повышен на +25%. Любой Бинарный урон Сёдзи конвертируется в обычный урон ветра (до E6). Навык Q задерживает действие всех врагов на (Векторы/3 + 10)%, блокирует Q на 2 хода и заряжает Усиленную базовую атаку. Сверхспособность накладывает на всех врагов уязвимость ко всем типам урона на (Векторы * 0.75)% (до 50%) [при E1: 65%] на 2 хода. След 3: пока активен Танец, передовой боец (слот 1) получает пробитие всех сопротивлений на +1% за каждые 2 ед. скорости Сёдзи выше 110 (до +25%).\n\n" + \
	"[color=yellow]⚔ Базовая атака [Одиночная]:[/color] 95% СА урона ветра. След 1: восстанавливает 3 Вектора.\n" + \
	"[color=cyan]⚔ Усиленная базовая [Взрывная]:[/color] 125% СА цели и 35% СА соседям. Восстанавливает 13 Векторов.\n\n" + \
	"[color=yellow]🔷 Навык Q (1 ОН):[/color] Зависит от стойки (Вирус: Бинарный взрыв 170%/55%; Танец: Задержка действий всех врагов, перезарядка 2 хода, усиливает след. базовую).\n\n" + \
	"[color=yellow]🔹 Навык E (1 ОН) [Групповая / Детонация]:[/color] Разблокируется при 20 Векторах на весь бой. 115% СА всем врагам Бинарным уроном. Детонирует все эффекты периодического урона (DoT) на всех противниках с силой 30%. За каждый сдетонированный ДоТ восстанавливает +1 Вектор (при E4: дополнительно +20 Векторов единоразово).\n\n" + \
	"[color=gold]✨ Сверхспособность (130 ЭН) [Групповая]:[/color] 145% СА всем врагам уроном ветра. Во «Вирусе» урон Бинарный и на 35% выше. В «Танце» накладывает уязвимость ко всем типам урона на (Векторы * 0.75)% (до 50%) [при E1: 65%] на 2 хода. След 2: даёт Сёдзи +20% скорости на 3 хода.\n\n" + \
	"[color=cyan]💡 Талант «Разрядка Консоли»:[/color] При достижении 90 Векторов сбрасывает счетчик Векторов до 0 и даёт ВСЕМ союзникам +50% Силы атаки на 2 хода.\n\n" + \
	"[color=cyan]Следы:[/color] С1: Базовая атака даёт 3 Вектора. С2: Ульта даёт Сёдзи +20% скорости на 3 хода. С3 (в Танце): ДД отряда получает до +25% пробития всех сопротивлений от скорости Сёдзи.\n\n" + \
	"[color=purple]Эйдолоны:[/color] Е1: В Танце ульта накладывает 65% уязвимости, урон ульты +0.75% за Вектор. Е2: Во Вирусе Бинарный урон союзников +50%, КУ Сёдзи +1% за Вектор. Е4: Навык Е даёт +20 Векторов. Е6: Весь урон всех союзников становится Бинарным, а Бинарный урон получает стандартные баффы урона!\n\n" + \
	"[color=orange]⚡ Техника [Атакующая]:[/color] 90% СА Бинарным уроном всем врагам на старте и накладывает +25% уязвимости ко всем типам урона на 2 хода."

static func _katarina_skills(eidolon: int) -> String:
	return "⚔ [b]Катарина[/b] — Элемент: Физический, Путь: Небытие, Фракция: Эмпирейцы\n\n" + \
	"⚔ [b]Базовая атака[/b]: 90% СА выбранному противнику. (+1 ОН, +20 ЭН, стойкость 50%).\n" + \
	"🔷 [b]Навык Q (1 ОН)[/b]: 280% СА, игнорирует 30% защиты. Накладывает физ. уязвимость (-20% физ. сопр. на 2 хода; E1: -20% ко всем сопр. и -30% СКР). Атакуя его, союзники получают +15% СА на 2 хода.\n" + \
	"🔹 [b]Навык E (2 ОН)[/b]: «Лишь воспоминание» на 2 хода — полный иммунитет к урону! При выходе восстанавливает 50 ЭН.\n" + \
	"✨ [b]Сверхспособность (120 ЭН)[/b]: «Журчание крови» — серия из 3 ударов:\n" + \
	"  • 2× «Секущий удар»: 100% СА цели, 50% соседям (стойкость 0.3).\n" + \
	"  • 1× «Рвущий удар»: 40% от урона «Секущих» цели, 80% СА соседям (стойкость 0.8). +5 ЭН (E4: +1 ОН).\n" + \
	"  (E2: Ультимейт бьет всех врагов мультипликатором основной цели; если враг один, +90% урона).\n" + \
	"  (Если на цели «Сломленный дух», урон не наносится, а записывается; союзник, снявший статус, высвобождает 50% урона).\n" + \
	"🩸 [b]Талант[/b]: При падении макс. ХП врага < 80%/50%/5% накладывает «Сломленный дух». Снимается при < 70%/40%.\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Союзники Небытия получают +10/30/50/60% КУ (E6: +100% всем союзникам; урон по Сломленному духу критический!). Атаки получают +4% КШ за дебафф (макс 32%).\n" + \
	"  • След 2: В «Сломленном духе» цель получает +30% Бинарного урона (E6: +40% всем врагам вечно).\n" + \
	"  • След 3: 3 действия без урона дают статус «Докажи» (+40% Скорости, сброс при уроне).\n" + \
	"🎯 [b]Техника[/b]: +20% СА на 2 хода и бесплатная активация Навыка E на старте боя." + \
	"\n\n"

static func _dotseva_crimson_tears_skills(eidolon: int) -> String:
	return "🩸 [b]Доцева • Багровые слёзы[/b] — Элемент: Ветряной, Путь: Сохранение, Фракция: Эмпирейцы\n\n" + \
	"⚔ [b]Базовая атака[/b]: 65% СА по одной цели. (+1 ОН, +20 ЭН).\n" + \
	"🔷 [b]Навык Q (1 ОН)[/b]: 90% СА всем врагам на поле. (+30 ЭН).\n" + \
	"🔷 [b]Улучшенный Q (0 ОН)[/b] (во время действия Зоны): 100% СА цели, 50% соседям. Лечит Доцеву (25% СА + 200) и союзников (7% СА + 80). Цель получает +15% урона на 2 хода. След 3: >6 дебаффов дает +1 ОН. (E6: доп. чистый урон = 50% СА отряда).\n" + \
	"🔹 [b]Навык E (2 ОН)[/b]: Зона на 3 хода. Крит. шанс выбранного союзника +20% пока активна Зона. 100% урона по выбранному союзнику и 70% по другим перенаправляются на Доцеву (+5 ЭН). (E1: +40% агро цели, экстренный хил 15% СА при ХП < 25%. E4: +30% макс. ХП союзников во время Зоны).\n" + \
	"✨ [b]Сверхспособность (100 ЭН)[/b]: 100% СА всем врагам, наносимый ими урон снижается на 30% на 2 хода. (E2: враги получают +40% урона на 2 хода).\n" + \
	"👁 [b]Талант[/b]: Дебафф от союзника дает стак «Закрой глаза» (макс 15). Каждый стак дает +3% СА всем союзникам.\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Во время активации Зоны, макс. ХП Доцевой повышается на 1% за каждую единицу скорости союзников свыше 100 (максимум: +200% макс. ХП). Эффект не складывается и перепроверяется при повторной активации.\n" + \
	"  • След 2: Входящий урон Доцевой постоянно снижен на 30%.\n" + \
	"  • След 3: Улучшенный Q восстанавливает 1 ОН, если у цели > 6 дебаффов.\n" + \
	"  (E6: Ход союзников продвигает действие Доцевой на 15%).\n" + \
	"🎯 [b]Техника[/b]: Разворачивает защитную Зону на старте боя и восстанавливает +1 Очко навыков."

static func _lenskaya_antimatter_skills(eidolon: int) -> String:
	return "🌌 [b]Ленская • Явление антиматерии[/b] — Элемент: Квантовый, Путь: Разрушение, Фракция: Антиматерия\n\n" + \
	"⚔ [b]Базовая атака («Без формы»)[/b]: 100% СА по одной цели. (+1 ОН, +20 ЭН). (E6: конвертируется в Квантовый Бинарный урон).\n" + \
	"💥 [b]Усиленная базовая атака [Одиночная атака][/b] (в формах «Хранитель» и «Воин»): Наносит выбранному противнику квантовый урон, равный 120% СА. (+1 ОН, +20 ЭН). (E6: считается Бинарным уроном).\n" + \
	"🔷 [b]Навык Q «Без формы» (1 ОН)[/b]: 110% СА главной цели, 50% СА соседям (+30 ЭН). (E6: Квантовый Бинарный урон).\n" + \
	"🔷 [b]Навык Q «Хранитель Ничто» (30 Xaeroh)[/b]: 7 ударов квантовым уроном (1 по выбранной цели + 6 случайных отскоков по 50% СА). Каждый удар получает +1% урона за каждую единицу скорости свыше 100 (макс +175% урона). (+30 ЭН).\n" + \
	"🔷 [b]Навык Q «Воин небытия» (30 Xaeroh)[/b]: В обычном режиме: 180% СА цели, 70% СА соседям. Если в «В изнанке» — выходит из неё (+40% СА на 3 хода) и казнит врага с ХП < 10% (не босса). Наносит 400% СА цели и 120% СА остальным врагам (+30 ЭН).\n" + \
	"🔹 [b]Навык E «Без формы» (2 ОН)[/b]: 300% СА по одной цели (+30 ЭН).\n" + \
	"🔹 [b]Навык E «Хранитель Ничто» (60 Xaeroh)[/b]: Повышает свою скорость на 30% от скорости всех союзников на 2 хода. Повышает СА всей команды на 30% от СА Ленской на 3 хода (+30 ЭН).\n" + \
	"🔹 [b]Навык E «Воин небытия» (60 Xaeroh)[/b]: Входит в состояние «В изнанке» (полная недосягаемость для врагов до следующего действия). (+30 ЭН).\n" + \
	"♻ [b]Талант «Сброс» (0 ОН)[/b]: Доступен в формах при < 30 Xaeroh. Сбрасывает Xaeroh до 0, снимает форму, продвигает действие на 100% вперед и восстанавливает 25 энергии (След 2).\n" + \
	"✨ [b]Сверхспособность (130 ЭН)[/b] — выбор из 3 вариантов:\n" + \
	"  1. [b]Хранитель Ничто[/b]: Переход в форму, +100 Xaeroh, +1 Очко навыков. (E6: наносит 50% СА всем врагам).\n" + \
	"  2. [b]Воин небытия[/b]: Переход в форму, +100 Xaeroh, +1 Очко навыков. (E6: наносит 50% СА всем врагам).\n" + \
	"  3. [b]Уничтожение сверхновой[/b]: Даёт +100 Xaeroh, затем обрушивает колоссальный луч на врага: урон равен 2.8% СА за каждую единицу Xaeroh. При 100+ Xaeroh пробивает уязвимость вне зависимости от типа. (E4: 60% СА квантового Бинарного урона всем остальным врагам. E6: сохраняет 70% Xaeroh и даёт доп. ход ульты для выбора формы).\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Расход Xaeroh даёт +5 энергии; вход в форму восстанавливает 1 ОН.\n" + \
	"  • След 2: Выход из форм через Талант «Сброс» восстанавливает 25 энергии.\n" + \
	"  • След 3: Если в отряде есть участники Консоли, атаки навыком Q наносят доп. чистый урон от накопленных Векторов (20% СА за каждые 20 Векторов).\n" + \
	"🎯 [b]Техника[/b]: В начале боя союзники получают +30 ед. Xaeroh, а Ленская входит в форму «Хранитель Ничто».\n" + \
	"🌌 [b]Фракция Антиматерии[/b]: Общий счетчик Xaeroh (+20 на старте). Каждые 20 Xaeroh снижают защиту врагов на 5%. Траты Xaeroh повышают КУ союзников (+6% за 10 ед. на 1 ход, не складывается). При 3 союзниках призывается Чёрная дыра (казнь врагов < 7% ХП, квантовый DoT)."

static func _count_enemy_debuffs(unit: CombatUnit) -> int:
	if unit == null:
		return 0
	var count: int = 0
	if unit.has_meta("def_reductions"):
		var reds: Dictionary = unit.get_meta("def_reductions")
		count += reds.size()
	if unit.statuses.break_status != "": count += 1
	if unit.statuses.suppression_stacks > 0: count += 1
	if unit.statuses.imaginary_spd_debuff_turns > 0: count += 1
	if unit.statuses.atk_buff_percent < 0.0: count += 1
	if unit.statuses.damage_taken_bonus > 0.0: count += 1
	count += unit.statuses.debuffs.size()
	if int(unit.get_meta("doceva_tears_q_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("doceva_tears_outgoing_dmg_red_turns", 0)) > 0: count += 1
	if int(unit.get_meta("doceva_tears_e2_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_e1_spd_debuff_turns", 0)) > 0: count += 1
	if int(unit.get_meta("katarina_q_ally_mark_turns", 0)) > 0: count += 1
	if bool(unit.get_meta("katarina_broken_spirit", false)): count += 1
	if unit.has_meta("katarina_e6_binary_vuln"): count += 1
	if int(unit.get_meta("shoji_swan_dance_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("shoji_swan_tech_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("shoji_fire_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("phys_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("quantum_res_reduced_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_kiss_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_dot_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("naama_intox_stacks", 0)) > 0: count += 1
	if int(unit.get_meta("valramors_talent_turns", 0)) > 0: count += 1
	if int(unit.get_meta("valramors_ult_vuln_turns", 0)) > 0: count += 1
	if int(unit.get_meta("joan_dont_miss_turns", 0)) > 0: count += 1
	if int(unit.get_meta("velzebul_seal_turns", 0)) > 0: count += 1
	if int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)) > 0: count += 1
	if int(unit.get_meta("lenskaya_am_decomp_turns", 0)) > 0: count += 1
	if int(unit.get_meta("ego_reality_vuln_turns", 0)) > 0: count += 1
	return count

static func _velzebul_skills(eidolon: int) -> String:
	return "🩸 [b]Вельзевул[/b] — Элемент: Ледяной, Путь: Гармония, Фракция: Антиматерия (Базовая СКР: 113)\n\n" + \
	"⚔ [b]Базовая атака [Одиночная атака][/b]: 100% СА ледяного урона по одной цели. (+1 ОН, +20 ЭН).\n" + \
	"💥 [b]Усиленная базовая атака [Одиночная атака][/b] (в стойке «Подношение»): 190% СА ледяного урона по цели. Восстанавливает 5 Зеро, не генерирует и не тратит ОН (0 ОН). Даёт 1 Грешное сердце (макс 4). (+20 ЭН). (E1: +5 ЭН и +5 Зеро).\n" + \
	"🔷 [b]Навык Q [Групповая атака] (1 ОН)[/b]: 110% СА ледяного урона всем врагам. Генерирует 15 Зеро (+30 ЭН). (E4: Скорость +30% на 2 хода).\n" + \
	"🔹 [b]Навык E (Подношение Вельзевул) (2 ОН)[/b]: Переходит в стойку «Подношение». Базовая атака становится Усиленной до сбора 4 сердец. (+30 ЭН).\n" + \
	"🔹 [b]Усиленный Навык E (1 ОН, Взрыв)[/b] (разблокируется навсегда при сборе 4 сердец): 110% СА главной цели, 30% СА соседям. Накладывает статус «Печать Вельзевула» на 3 хода (+30 ЭН).\n" + \
	"🩸 [b]Печать Вельзевула[/b]: При нанесении урона цели Навыком Q союзник с макс. энергией > 240 (Ленская) восстанавливает 15 энергии и 5 Зеро (1 раз за действие).\n" + \
	"✨ [b]Сверхспособность (140 ЭН)[/b] (требует 4 Грешных сердца): 150% СА ледяного урона всем врагам. Союзники пути Антиматерии получают +40% к урону на 2 хода. Сопротивление всех противников льду и кванту снижается на 20% на 2 хода. (E2: продвигает действие союзников Антиматерии на 100%, остальных — на 40%).\n" + \
	"💎 [b]Талант[/b]: За каждые 30 накопленных очков Зеро всеми союзниками повышает Крит. шанс всех союзников на 5% (макс до +30%) и их Крит. урон на 10% (макс до +60%). (E6: В начале своего хода +10 Зеро; за каждую 1 ед. Зеро свыше 30 урон союзников +1%).\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Атаки Вельзевул по цели со статусом «Печать Вельзевула» восстанавливают 1 ОН.\n" + \
	"  • След 2: Когда любой другой союзник Антиматерии применяет Сверхспособность, его атака временно считается совершенной при наличии 80 Зеро.\n" + \
	"  • След 3: За каждое Грешное сердце союзники Антиматерии получают +10% к Силе Атаки (макс +40%), а Вельзевул получает +10% к Скорости (макс +40%). При сборе 4 Грешных сердец макс. ХП Вельзевул повышается на 40% до конца боя.\n" + \
	"🎯 [b]Техника (Поддержка)[/b]: В начале боя продвигает действие первого союзника в отряде (или второго, если Вельзевул на первой позиции) на 100% и восстанавливает ему 30% энергии."

static func _marina_sky_guardian_skills(eidolon: int) -> String:
	var e1 := " (Э1: множитель 36% и +1 удар)" if eidolon >= 1 else ""
	var e2 := " (Э2: 20% урона атаки наносится Чистым уроном)" if eidolon >= 2 else ""
	var e4 := " (Э4: атаки под связью игнорируют 18% защиты)" if eidolon >= 4 else ""
	var e6 := " (Э6: продвигает всех духов памяти на 100% и +50% урона на 1 ход)" if eidolon >= 6 else ""
	return "🕊 [b]Марина • Хранитель небес[/b] — Элемент: Ветряной, Путь: Память, Фракции: Хранители небес, Свечение (Базовая СКР: 105)\n\n" + \
	"⚔ [b]Базовая атака [Одиночная атака][/b]: Наносит 100% СА ветряного урона выбранному противнику и восстанавливает Эго 5% его заряда. (+1 ОН, +20 ЭН).\n\n" + \
	"🔷 [b]Навык Q [Поддержка] (1 ОН)[/b]: Образует связь с выбранным союзником и его духом памяти на 3 хода. Длительность связи уменьшается на 1 в конце каждого хода Марины. Каждый раз, когда связанные цели совершают атаку, их шанс крит. попадания повышается на +1.5% (макс. +25%). След 1: +20% КУ." + e4 + " (+30 ЭН).\n\n" + \
	"🔹 [b]Навык E (2 ОН)[/b]: Призывает духа памяти «Эго». Если дух памяти уже призван, то с него снимаются все эффекты контроля и умение восстанавливает 60% от его макс. ХП. (+30 ЭН).\n\n" + \
	"✨ [b]Сверхспособность (140 ЭН)[/b]: Восстанавливает 40% заряда Эго и создает зону «Элизиум» на 2 хода. Пока активен Элизиум, получаемый противниками урон повышается на 30%. Когда союзник атакует противника, цель с самым высоким ХП среди пораженных этой атакой получает доп. ветряной урон (не считается атакой), равный 30% СА Марины, 1 доп. раз за каждого пораженного противника. Длительность зоны уменьшается на 1 в начале каждого хода Марины." + e1 + e2 + e6 + "\n\n" + \
	"💡 [b]Талант[/b]: Изначально скорость духа памяти Эго равна 130, а макс. ХП – 68% от макс. ХП Марины + 300. За каждые 10 ед. энергии, полученной союзниками, Эго восстанавливает 1% заряда. Действие любого другого союзного духа памяти, кроме Эго, восстанавливает Марине 8 ед. энергии (до 1 раза за ход Марины, сброс в начале хода Марины).\n\n" + \
	"🌙 [b]Фракция «Хранители небес»[/b]: 1 участник: +5% чистого урона за каждого участника. Призывает Деву луны (СКР 60). В свой ход продвигает действия всех союзников на 40% и наносит чистый урон (7% общей СА + 2% макс. ХП союзников за каждый накопленный удар). 2 участника: духи памяти получают +8% чистого урона за участника, Дева луны восстанавливает всем союзникам 15% макс. энергии. 4 участника: действия Хранителей продвигают Деву луны на 5% и дают +2 удара.\n\n" + \
	"🌟 [b]Фракция «Свечение»[/b]: Звёздный проводник Марина: наносимый духами памяти урон +20%, их КУ +30% ([2] активен, [3] в 1.5 раза: +30% урона, +45% КУ).\n\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Крит. урон персонажей и их духов памяти в связи Навыка Q увеличивается на 20%.\n" + \
	"  • След 2: В начале боя действие Марины продвигается на 30%. Во время первого призыва Эго получает 40% заряда.\n" + \
	"  • След 3: При использовании умения «Дежавю?» Эго немедленно получает 5% заряда.\n\n" + \
	"🎯 [b]Техника (Поддержка)[/b]: В начале боя призывает Эго без траты очков навыков."

static func _memosprite_skills(sprite: Memosprite) -> String:
	if sprite.id == "ego":
		return "❄ [b]Дух Памяти «Эго»[/b] (Владелец: Марина • Хранитель небес)\n\n" + \
		"⚔ [b]Навык[/b]:\n" + \
		"  • [b]Дежавю?[/b]: Совершает 4 удара, каждый из которых наносит случайному противнику ветряной урон, равный 30% от силы атаки Эго. В конце наносит всем противникам ветряной урон, равный 90% от силы атаки Эго. След 3: +5% заряда.\n" + \
		"  • [b]Реальность (100% Заряда)[/b]: Наносит выбранному противнику 180% СА и двум окружающим его целям 70% СА. Получаемый этими целями урон увеличивается на 30% на 2 хода, а атаки союзников по ним дополнительно наносят 5% чистого урона.\n\n" + \
		"💡 [b]Талант[/b]:\n" + \
		"Повышает крит. урон всех духов памяти на 13% от крит. урона Эго + 30%.\n" + \
		"Во время своего действия Эго автоматически использует умение «Дежавю?». Если заряд достигает 100%, Эго выполняет действие немедленно и в следующем действии игрок выбирает противника для умения «Реальность»."
	elif sprite.id == "antimatter_paws" or (sprite.definition != null and sprite.definition.id == "antimatter_paws"):
		return _antimatter_paws_skills()
	
	var def := sprite.definition
	var text := "❄ [b]Дух Памяти «%s»[/b]\n\n" % sprite.display_name
	if def:
		text += "⚔ [b]Навык: %s[/b]\n" % def.skill_name
		if def.enhanced_skill_name != "":
			text += "🌟 [b]Усиленный навык: %s (при 100%% Заряда)[/b]\n" % def.enhanced_skill_name
		text += "💡 [b]Талант: %s[/b]\n" % def.talent_name
	return text

static func _antimatter_paws_skills() -> String:
	return "🐾 [b]Дух Памяти «Лапы антиматерии»[/b] (Владелец: Раймс • Восхождение)\n\n" + \
	"Базовая скорость: 165. Макс. ХП = 120% макс. ХП Раймса (+30% за каждый заряд выше 1). Перенаправляет смертельный урон с союзников на себя с множителем 300%. Недоступен для прямой атаки врагов.\n\n" + \
	"⚔ [b]Навык: Con brio (< 4 зарядов)[/b]:\n" + \
	"  • 40% макс. ХП Лап. 1 удар по врагу с наибольшим ХП + по 1 случайному удару за каждый накопленный заряд выше 1 по 35% макс. ХП Лап (макс. 4 удара).\n" + \
	"🌟 [b]Усиленный навык: Sforzando (4 заряда)[/b]:\n" + \
	"  • 3 удара по 50% макс. ХП Лап всем врагам + 4-й удар 90% макс. ХП Лап всем врагам. При наличии >= 60 Зеро тратит 20 Зеро и повторяет 4-й удар (90%). Сбрасывает заряды до 1.\n\n" + \
	"💡 [b]Талант (Пассивный финал)[/b]:\n" + \
	"  • При гибели или исчезновении наносит 6 ударов (E6: 9 ударов) по случайным врагам по 40% (E6: 52%) макс. ХП Лап и восстанавливает всему отряду 6% макс. ХП Лап + 400."

static func _lenskaya_sky_guardian_skills(eidolon: int) -> String:
	var e1 := " (E1: первое использование за бой тратит на 1 ОН меньше)" if eidolon >= 1 else ""
	var e2 := " (E2: +15% урона Суперпробития, суммарно +45%)" if eidolon >= 2 else ""
	var e4 := " (E4: восстанавливает 5 энергии)" if eidolon >= 4 else ""
	var e6 := " (E6: накладывает Мнимую уязвимость на 2 хода перед ударом)" if eidolon >= 6 else ""
	return "🏹 [b]Ленская • Хранитель небес[/b] — Элемент: Мнимый, Путь: Охота, Фракции: Хранители небес, Свечение (Базовая СКР: 108)\n\n" + \
	"⚔ [b]Базовая атака [Одиночная атака][/b]: Наносит 100% СА мнимого урона выбранному противнику и истощает 10 единиц стойкости (+1 ОН, +20 ЭН).\n\n" + \
	"🏹 [b]Усиленная базовая атака[/b]: Наносит 4 удара по 50% СА мнимого урона (суммарно 200% СА) и истощает по 10 единиц стойкости за каждый удар (суммарно 40 единиц стойкости)." + e4 + " След 3: урон Суперпробития +30% (+20 ЭН).\n\n" + \
	"🔷 [b]Навык Q [Ослабление] (1 ОН)[/b]: Накладывает на выбранного противника статус «Враг Свечения» на 3 хода и активирует усиленную базовую атаку на 3 хода. «Враг Свечения»: теряет стойкость с эффективностью 150% (в 1.5 раза быстрее) и получает на 30% больше урона от Пробития и Суперпробития" + e2 + " (+30 ЭН).\n\n" + \
	"💥 [b]Навык E [Одиночная атака] (2 ОН)[/b]: Наносит 300% СА мнимого урона выбранному противнику и истощает 30 единиц стойкости." + e1 + e6 + " (+30 ЭН).\n\n" + \
	"✨ [b]Сверхспособность (110 ЭН)[/b]: Повышает собственный Эффект Пробития на 40% на 3 хода и продвигает собственное действие на 100%. След 2: если Ленская не на первом месте в отряде, первый союзник получает +40% к Эффекту Пробития на 2 хода.\n\n" + \
	"💡 [b]Талант[/b]: Когда Ленская или другие союзники атакуют противника с пробитой уязвимостью, урон этой атаки конвертируется в 60% урона суперпробития 1 раз за действие.\n\n" + \
	"🌙 [b]Фракция «Хранители небес»[/b]: 1 участник: +5% чистого урона за каждого участника. Призывает Деву луны (СКР 60). 2 участника: духи памяти получают +8% чистого урона, Дева луны восстанавливает 15% макс. энергии. 4 участника: продвижение Девы луны на 5% и +2 удара.\n\n" + \
	"🌟 [b]Фракция «Свечение»[/b]: Звёздный проводник Ленская: урон пробития команды +30% ([2] активен, [3] в 1.5 раза: +45% урона пробития).\n\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Крит. Шанс повышается на 10% от Эффекта Пробития (макс. +30%). Крит. Урон повышается на 50% от Эффекта Пробития (макс. +150%).\n" + \
	"  • След 2: При использовании Сверхспособности, если Ленская не на первом месте в отряде, союзник на первом месте получает +40% к Эффекту Пробития на 2 хода.\n" + \
	"  • След 3: Урон Суперпробития Усиленной базовой атаки повышается на 30%.\n\n" + \
	"🎯 [b]Техника (Атакующая)[/b]: В начале боя наносит всем противникам 100% СА Мнимого урона и истощает 40 единиц стойкости независимо от типов уязвимостей."

static func _rimes_ascension_skills(eidolon: int) -> String:
	var e1 := " (E1: +20% урона по врагам с ХП <= 80%, +40% при ХП <= 50%)" if eidolon >= 1 else ""
	var e2 := " (E2: +2 заряда Лап вместо 1, продвижение Лап на 50%, +30% Крещендо)" if eidolon >= 2 else ""
	var e4 := " (E4: исходящее исцеление всего отряда +30%)" if eidolon >= 4 else ""
	var e6 := " (E6: игнорирование уязвимостей, +20% квант. RES PEN, 9 ударов финала Лап по 52%)" if eidolon >= 6 else ""
	return "👑 [b]Раймс • Восхождение[/b] — Элемент: Квантовый, Путь: Память, Фракции: Антиматерия, Небожители (Базовая СКР: 102, ХП: 4500)\n\n" + \
	"⚔ [b]Базовая атака [Одиночная атака][/b]: Наносит квантовый урон, равный 100% от макс. ХП Раймса (+1 ОН, 0 ЭН).\n\n" + \
	"🔷 [b]Навык Q (0 ОН) — Слияние [Групповая атака][/b]: Без Лап наносит 90% макс. ХП Раймса всем врагам. При наличии Лап расходует 15% текущего ХП союзников (30% у Лап) и выполняет совместную атаку (50% макс. ХП Раймса + 30% макс. ХП Лап). При Зеро >= 60 тратит 10 Зеро, увеличивает урон на 20% и восстанавливает Лапам 1 заряд.\n\n" + \
	"🔹 [b]Навык E (2 ОН / След 1: 1 ОН) — Призыв Лап [Призыв / Восстановление][/b]: Призывает Духа Памяти «Лапы антиматерии». Если уже призван — восстанавливает 60% макс. ХП Лап, снимает все эффекты контроля и дает +1 заряд" + e2 + ".\n\n" + \
	"✨ [b]Сверхспособность (100% Крещендо) — Зона Разрыв[/b]: Восстанавливает 10 единиц Зеро и призывает Духа Памяти «Лапы антиматерии» (если уже призваны — восстанавливает 60% их макс. ХП и дает +1 заряд). Продвигает действие Лап на 100% и создает зону «Разрыв» на 3 хода Раймса: понижает все типы сопротивлений врагов на 20%. За каждые 10 Зеро выше 50 крит. урон Раймса и Лап увеличивается на 10% (макс +60%)." + e1 + e4 + e6 + "\n\n" + \
	"💡 [b]Талант — Симфония Антиматерии[/b]: Не накапливает обычную энергию. За каждый 1% потерянного союзниками ХП получает 1% Крещендо (шкала до 100%). При потере ХП союзником наносимый урон Раймса и Лап повышается на 20% на 3 хода (стакается до 3 раз, макс +60%).\n\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Стоимость Навыка E снижается с 2 до 1 ОН.\n" + \
	"  • След 2: 30% получаемого союзниками исцеления конвертируется в Крещендо (не более 12% за ход от каждого союзника).\n" + \
	"  • След 3: За каждое применение/удар Лап их наносимый урон повышается на 10% до конца хода Лап (до 6 раз, макс +60%).\n\n" + \
	"🎯 [b]Техника[/b]: В начале боя наносит квантовый урон 100% макс. ХП Раймса всем врагам, восстанавливает 1 ОН, дает 30% Крещендо и продвигает действие отряда на 20%."

static func _sanguinia_skills(eidolon: int) -> String:
	var e1 := " (E1: Пробитие сопротивления всех типов +18%, для усиленного Навыком Q +12%, урон бонус-атак +15%)" if eidolon >= 1 else ""
	var e2 := " (E2: игнорирование защиты цели (15% + Журчание волн * 0.5%), при сбросе стаков +60% урона на 2 хода)" if eidolon >= 2 else ""
	var e4 := " (E4: ульта дает +40% СА на 3 хода, игнорирует себя при выборе сильнейшего союзника)" if eidolon >= 4 else ""
	var e6 := " (E6: множитель урона «Заселение» удвоен, бонус-атаки наносят чистый урон с +20% бонусом)" if eidolon >= 6 else ""
	return "🍸 [b]Сангиния Ял[/b] — Элемент: Огненный, Путь: Гармония, Фракция: Обречённые (Базовая СКР: 104, СА: 1500)\n\n" + \
	"⚔ [b]Базовая атака [Одиночная атака][/b]: Наносит 100% СА огненного урона выбранному противнику (+1 ОН, +20 ЭН).\n\n" + \
	"🔷 [b]Навык Q [Поддержка] (1 ОН)[/b]: Продвигает действие выбранного союзника на 100% и повышает его силу атаки на 40% на 3 хода (+30 ЭН).\n\n" + \
	"🔹 [b]Навык E [Ослабление] (2 ОН)[/b]: Помечает выбранного врага статусом «Особый гость» (12 зарядов). Каждая атака союзников (в том числе Бонус-атаки) уменьшает заряды на 1. При 9/6/3/0 зарядах Сангиния проводит Бонус-атаку: 130% СА цели и 35% СА двум соседним целям. При 0 зарядах статус снимается, а отряд восстанавливает 1 Очко Навыков (+30 ЭН).\n\n" + \
	"✨ [b]Сверхспособность (150 ЭН) [Усиление][/b]: Создает на шкале действий «Готовьтесь...» (AV 59) и три «Заселение!» (AV 60). В свой ход «Готовьтесь...» продвигает союзника с наивысшей СА на 100%, дает ему 40 энергии, +60% СА на 1 ход и игнорирование 20% защиты на следующую атаку (След 2). В свой ход «Заселение!» наносят групповую бонус-атаку всем врагам (40% СА Сангинии), уменьшают заряды «Особого гостя» и восстанавливают Сангинии 7 энергии (След 1)." + e4 + e6 + "\n\n" + \
	"💡 [b]Талант — «Журчание волн» [Поддержка][/b]: За каждую союзную Бонус-атаку и за Сверхспособность союзника с наибольшей СА получает 2 стака (макс 47). Каждый стак повышает урон Бонус-атак всех союзников на 2%. При 47 стаках моментально продвигает союзника с наивысшей СА на 100% и дает +100% урона следующей атаке. После действия продвинутого персонажа стаки сбрасываются до 0 (След 3: восстанавливает 1 Очко Навыков)." + e1 + e2 + "\n\n" + \
	"⚡ [b]Следы[/b]:\n" + \
	"  • След 1: Атаки «Заселение!» восстанавливают Сангинии 7 единиц энергии.\n" + \
	"  • След 2: Следующая атака союзника, продвинутого «Готовьтесь...», игнорирует 20% защиты цели.\n" + \
	"  • След 3: Когда Журчание волн сбрасывается до 0, Сангиния восстанавливает 1 Очко Навыков.\n\n" + \
	"🎯 [b]Техника (Поддержка)[/b]: В начале следующего боя немедленно продвигает действие на 30% и повышает скорость союзника с наибольшей СА на 15 единиц на 3 хода."
