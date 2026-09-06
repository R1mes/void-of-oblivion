extends Control

@onready var battle_manager: BattleManager = %BattleManager
@onready var allies_container: HBoxContainer = %AlliesContainer
@onready var enemies_container: HBoxContainer = %EnemiesContainer
@onready var action_bar: HBoxContainer = %ActionBar
@onready var skill_points_label: Label = %SkillPointsLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
@onready var turn_label: Label = %TurnLabel
@onready var arya_label: Label = %AryaLabel
@onready var log_list: RichTextLabel = %LogList
@onready var action_panel: PanelContainer = %ActionPanel
@onready var btn_basic: Button = %BtnBasic
@onready var btn_enhanced_basic: Button = %BtnEnhancedBasic
@onready var btn_skill: Button = %BtnSkill
@onready var btn_skill_e: Button = %BtnSkillE
@onready var btn_ult: Button = %BtnUlt
@onready var btn_skills_help: Button = %BtnSkillsHelp
@onready var skills_panel: PanelContainer = %SkillsPanel
@onready var skills_text: RichTextLabel = %SkillsText
@onready var inspect_overlay: ColorRect = %InspectOverlay
@onready var inspect_title: Label = %InspectTitle
@onready var inspect_stats: RichTextLabel = %InspectStats
@onready var inspect_effects: RichTextLabel = %InspectEffects
@onready var inspect_skills: RichTextLabel = %InspectSkills
@onready var btn_close_inspect: Button = %BtnCloseInspect
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var btn_return: Button = %BtnReturn

# === Новые переменные для 3-вкладочного окна Инфо персонажа ===
var _btn_inspect_tab_info: Button
var _btn_inspect_tab_skills: Button
var _btn_inspect_tab_cone: Button
var _inspect_view_info: Control
var _inspect_view_skills: Control
var _inspect_view_cone: Control
var _current_inspect_tab: int = 0

var _inspect_elem_label: Label
var _inspect_path_label: Label
var _inspect_tag_label: Label
var _btn_inspect_header_close: Button

var _inspect_eidolon_rank_label: Label
var _inspect_eidolons_list_vbox: VBoxContainer

var _inspect_cone_card: PanelContainer
var _inspect_cone_stars_label: Label
var _inspect_cone_tier_label: Label
var _inspect_cone_name_label: Label
var _inspect_cone_path_label: Label
var _inspect_cone_carrier_label: Label
var _inspect_cone_desc_text: RichTextLabel
var _inspect_cone_empty_label: RichTextLabel
var _inspect_cone_content_vbox: VBoxContainer

# Динамически создаваемые элементы для графиков урона
var graphs_panel: PanelContainer
var graphs_text: RichTextLabel
var _graphs_open: bool = false

var factions_panel: PanelContainer
var factions_text: RichTextLabel
var _factions_open: bool = false

var admin_panel: PanelContainer
var _admin_open: bool = false
var _admin_target_option: OptionButton
var _admin_inspect_text: RichTextLabel
var _admin_god_mode_btn: Button

# Новые увеличенные размеры карточек участников
const ALLY_PANEL_SIZE := Vector2(270, 420)
const ENEMY_PANEL_SIZE := Vector2(240, 380)

var _unit_panels: Dictionary = {}
var _selecting_target: bool = false
var _target_mode: String = ""
var _multi_targets: Array[CombatUnit] = []
var _skills_help_open: bool = false

# Элементы мягкого золотого фона «Формы духа»
var _spirit_vfx_container: Control = null
var _spirit_vfx_active: bool = false

# Элементы свитков Зоны Доцевой • Багровые слёзы
var _doceva_vfx_container: Control = null
var _doceva_vfx_active: bool = false
var _doceva_left_group: Control = null
var _doceva_right_group: Control = null
var _doceva_left_glow: TextureRect = null
var _doceva_right_glow: TextureRect = null
var _doceva_left_scrolls: Array[TextureRect] = []
var _doceva_right_scrolls: Array[TextureRect] = []

# Переменная для сохранения истинного владельца хода во время прерываний ультами
var _original_active_unit: CombatUnit = null

# Токен прерывания авто-хода Жоана при нажатии Ульты
var _joan_auto_turn_id: int = 0

# Виджет общего пула Векторов Консоли
var console_hud_panel: PanelContainer = null
var console_hud_label: RichTextLabel = null

func _ready() -> void:
	battle_manager.screen_impact_requested.connect(_on_screen_impact_requested)
	btn_basic.pressed.connect(_on_basic_pressed)
	btn_enhanced_basic.pressed.connect(_on_enhanced_basic_pressed)
	btn_skill.pressed.connect(_on_skill_pressed)
	btn_skill_e.pressed.connect(_on_skill_e_pressed)
	btn_ult.pressed.connect(_on_ult_pressed)
	btn_skills_help.pressed.connect(_on_skills_help_pressed)
	btn_close_inspect.pressed.connect(_close_inspect)
	btn_return.pressed.connect(_on_return_pressed)
	inspect_overlay.gui_input.connect(_on_inspect_overlay_input)
	battle_manager.ult_targeting_requested.connect(_on_ult_targeting_requested)
	
	battle_manager.enemies_reshuffled.connect(_build_unit_displays)
	battle_manager.log_added.connect(_on_log)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.turn_ended.connect(_on_turn_ended)
	battle_manager.skill_points_changed.connect(_on_sp_changed)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.action_order_changed.connect(_refresh_action_bar)
	battle_manager.unit_updated.connect(_refresh_unit_panel)
	battle_manager.arya_changed.connect(_on_arya_changed)
	battle_manager.combat_text_spawned.connect(_on_combat_text_spawned)

	result_panel.hide()
	action_panel.hide()
	arya_label.hide()
	skills_panel.hide()
	inspect_overlay.hide()
	btn_ult.hide() 
	
	

	
	_init_damage_graphs() 
	_setup_inspect_ui()

	battle_manager.start_battle(TeamConfig.team_members, TeamConfig.battle_initiator_id)
	_build_unit_displays()
	_on_sp_changed(battle_manager.skill_points)
	_refresh_action_bar()
	_init_factions_panel()
	
	var btn_give_up := Button.new()
	btn_give_up.text = "🏳 Сдаться"
	btn_give_up.pressed.connect(_on_give_up_pressed)
	btn_skills_help.get_parent().add_child(btn_give_up)
	LevelManager.init_tutorial_ui(self)
	_init_spirit_form_vfx()
	_init_doceva_zone_vfx()
	
	_init_console_hud()
	_init_admin_panel()

	
# Обработчик сигнала автоприцеливания при активации ульты Миленой
# === НАЙДИТЕ ЭТОТ МЕТОД В BATTLE.GD И ЗАМЕНИТЕ ЕГО ===
func _on_ult_targeting_requested(unit: CombatUnit) -> void:
	_original_active_unit = battle_manager.current_unit
	battle_manager.current_unit = unit
	_target_mode = "ult"
	_selecting_target = true
	
	# ИСПРАВЛЕНО: Учитываем союзную направленность ультимейта Айзека при авто-выборе
	var targets_allies_ult := (unit.id == "isaac")
	_set_target_buttons_visible(not targets_allies_ult, targets_allies_ult)
	
	_set_action_buttons_disabled(true)
	_on_log("[Выберите %s для Сверхспособности %s]" % ["союзника" if targets_allies_ult else "противника", unit.display_name])
	
func _on_give_up_pressed() -> void:
	battle_manager.log_message("🏳 Вы сдались и покинули поле боя.")
	_return_to_previous_screen()
	
func _return_to_previous_screen() -> void:
	if TeamConfig.battle_mode.begins_with("level_") or TeamConfig.battle_mode == "fiction" or TeamConfig.battle_mode == "boss" or TeamConfig.battle_mode.begins_with("dungeon_") or TeamConfig.battle_mode.begins_with("planar_"):
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/team_setup/team_setup.tscn")
		
func _init_factions_panel() -> void:
	var btn_factions := Button.new()
	btn_factions.text = "🛡 Синергии"
	btn_skills_help.get_parent().add_child(btn_factions)
	btn_factions.pressed.connect(_toggle_factions)

	factions_panel = PanelContainer.new()
	factions_panel.name = "FactionsPanel"
	factions_panel.visible = false
	skills_panel.get_parent().add_child(factions_panel)

	var vbox := VBoxContainer.new()
	factions_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🛡 Действующие Синергии Отряда"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	factions_text = RichTextLabel.new()
	factions_text.name = "FactionsText"
	factions_text.custom_minimum_size = Vector2(300, 200)
	factions_text.bbcode_enabled = true
	vbox.add_child(factions_text)

func _toggle_factions() -> void:
	LevelManager.on_action_pressed("factions_toggle", self)
	_factions_open = not _factions_open
	factions_panel.visible = _factions_open
	if _factions_open:
		_skills_help_open = false
		_graphs_open = false
		_admin_open = false
		skills_panel.hide()
		graphs_panel.hide()
		if admin_panel: admin_panel.hide()
		_refresh_factions_panel()

func _refresh_factions_panel() -> void:
	if not _factions_open:
		return

	var active_f: Dictionary = {}
	if battle_manager.has_meta("active_factions"):
		active_f = battle_manager.get_meta("active_factions")

	var lines: PackedStringArray = []
	for f_id in FactionSystem.FACTIONS:
		var f_data: Dictionary = FactionSystem.FACTIONS[f_id]
		var count: int = active_f.get(f_id, 0)
		
		var active_tier_desc := "Нет активных синергий"
		var highest_active_tier := 0
		for tier in f_data.desc_tiers:
			if count >= tier:
				highest_active_tier = max(highest_active_tier, tier)
				
		if highest_active_tier > 0:
			active_tier_desc = "[color=green]Активен [%d ур.]: %s[/color]" % [highest_active_tier, f_data.desc_tiers[highest_active_tier]]
			lines.append("[color=gold]%s[/color] (Участников: %d/4)\n   %s\n" % [f_data.name, count, active_tier_desc])
		else:
			lines.append("[color=gray]%s (Участников: %d/4)[/color]\n   [color=gray]%s[/color]\n" % [f_data.name, count, active_tier_desc])

	factions_text.text = "\n".join(lines)
	
func _init_damage_graphs() -> void:
	var btn_graphs := Button.new()
	btn_graphs.text = "📊 Урон"
	btn_skills_help.get_parent().add_child(btn_graphs)
	btn_graphs.pressed.connect(_toggle_graphs)

	graphs_panel = PanelContainer.new()
	graphs_panel.name = "GraphsPanel"
	graphs_panel.visible = false
	skills_panel.get_parent().add_child(graphs_panel)

	var vbox := VBoxContainer.new()
	graphs_panel.add_child(vbox)

	var title := Label.new()
	title.text = "📊 Статистика урона отряда"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	graphs_text = RichTextLabel.new()
	graphs_text.name = "GraphsText"
	graphs_text.custom_minimum_size = Vector2(300, 400)
	graphs_text.bbcode_enabled = true
	vbox.add_child(graphs_text)

func _toggle_graphs() -> void:
	_graphs_open = not _graphs_open
	graphs_panel.visible = _graphs_open
	if _graphs_open:
		_skills_help_open = false
		_admin_open = false
		skills_panel.hide()
		if admin_panel: admin_panel.hide()
		_refresh_graphs_panel()
	_refresh_factions_panel()

func _refresh_graphs_panel() -> void:
	if not _graphs_open:
		return

	var tracker: Dictionary = battle_manager.damage_tracker
	var total_damage: float = 0.0
	for id in tracker:
		total_damage += float(tracker[id])

	var lines: PackedStringArray = []
	lines.append("[color=yellow]Цикл: %d (Накоплено ИД: %.1f)[/color]\n" % [
		battle_manager.get_current_cycles(),
		battle_manager.accumulated_av
	])

	for ally in battle_manager.allies:
		var dmg: float = float(tracker.get(ally.id, 0.0))
		var percent: float = (dmg / total_damage * 100.0) if total_damage > 0.0 else 0.0
		var bar_str := ""
		var bar_blocks: int = int(percent / 10.0)
		for b in 10:
			if b < bar_blocks:
				bar_str += "■"
			else:
				bar_str += "□"
		
		var weapon_text := ""
		var weapon_id: String = ally.get_meta("light_cone_id", "")
		if weapon_id != "":
			var cone: Dictionary = LightConeRegistry.get_cone(weapon_id)
			weapon_text = " [color=cyan][%s][/color]" % cone.get("name", "Конус")

		lines.append("[color=%s]%s[/color]: %d (%s) [color=gray]%s[/color]%s" % [
			_unit_color_hex(ally),
			ally.display_name,
			int(dmg),
			"%.1f%%" % percent,
			bar_str,
			weapon_text
		])

	graphs_text.text = "\n".join(lines)

func _unit_color_hex(unit: CombatUnit) -> String:
	return "#" + _unit_color(unit).to_html(false)

func _build_unit_displays() -> void:
	for child in allies_container.get_children():
		child.queue_free()
	for child in enemies_container.get_children():
		child.queue_free()
	_unit_panels.clear()

	var is_duel: bool = battle_manager.has_meta("rimes_duel_active") and bool(battle_manager.get_meta("rimes_duel_active"))

	for ally in battle_manager.allies:
		var panel := _create_unit_panel(ally, true)
		allies_container.add_child(panel)
		if is_duel and ally.id != "rimes":
			panel.hide() # Прячем карточку союзника

	for enemy in battle_manager.enemies:
		enemies_container.add_child(_create_unit_panel(enemy, false))

func _create_unit_panel(unit: CombatUnit, is_ally: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	# ИСПРАВЛЕНО: Устанавливаем новые увеличенные размеры карточек
	panel.custom_minimum_size = ALLY_PANEL_SIZE if is_ally else ENEMY_PANEL_SIZE
	panel.set_meta("unit", unit)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10) 
	panel.add_child(vbox)

	var name_lbl := Label.new()
	var elite_tag := " ★" if unit.is_elite else ""
	var elem_tag := CombatConstants.get_element_short_name(unit.element)
	name_lbl.text = "%s %s [%s]%s" % [
		CombatConstants.ELEMENT_SYMBOLS[unit.element],
		unit.display_name,
		elem_tag,
		elite_tag,
	]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(unit.element))
	vbox.add_child(name_lbl)

	# НОВАЯ МЕХАНИКА: Обертка для наложения рамок и ХП-баров
	var bar_wrapper := Control.new()
	bar_wrapper.name = "BarWrapper"
	bar_wrapper.custom_minimum_size = Vector2(0, 28) 
	vbox.add_child(bar_wrapper)

	if is_ally:
		var shield_bar := ProgressBar.new()
		shield_bar.name = "ShieldBar"
		shield_bar.show_percentage = false
		shield_bar.modulate = Color(1.6, 1.6, 1.6, 1.0) 
		
		shield_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shield_bar.offset_left = -4
		shield_bar.offset_right = 4
		shield_bar.offset_top = -4
		shield_bar.offset_bottom = 4
		bar_wrapper.add_child(shield_bar)

	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = unit.stats.max_hp
	hp_bar.value = unit.stats.hp
	hp_bar.show_percentage = false
	hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_wrapper.add_child(hp_bar)

	if not is_ally:
		var kat_overlay := KatarinaThresholdsOverlay.new(battle_manager, unit)
		bar_wrapper.add_child(kat_overlay)

	var hp_lbl := Label.new()
	hp_lbl.name = "HPLabel"
	hp_lbl.text = "%d / %d" % [int(unit.stats.hp), int(unit.stats.max_hp)]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 16) 
	vbox.add_child(hp_lbl)

	if not is_ally and unit.max_toughness > 0:
		var tgh_bar := ProgressBar.new()
		tgh_bar.name = "TghBar"
		tgh_bar.custom_minimum_size = Vector2(0, 22) 
		tgh_bar.max_value = unit.max_toughness
		tgh_bar.value = unit.toughness
		tgh_bar.modulate = Color(0.6, 0.8, 1.0)
		vbox.add_child(tgh_bar)

		var tgh_lbl := Label.new()
		tgh_lbl.name = "TghLabel"
		tgh_lbl.text = "Стойкость"
		tgh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tgh_lbl.add_theme_font_size_override("font_size", 14) 
		vbox.add_child(tgh_lbl)

	var status_lbl := Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 15) 
	vbox.add_child(status_lbl)

	if is_ally:
		var en_bar := ProgressBar.new()
		en_bar.name = "EnergyBarOnCard"
		en_bar.custom_minimum_size = Vector2(0, 16)
		en_bar.max_value = unit.max_energy
		en_bar.value = unit.energy
		en_bar.show_percentage = false
		en_bar.modulate = Color(0.95, 0.8, 0.25) 
		vbox.add_child(en_bar)

		var ult_btn := Button.new()
		ult_btn.name = "UltButtonOnCard"
		ult_btn.text = "★ СВЕРХСП."
		ult_btn.custom_minimum_size = Vector2(0, 64)
		ult_btn.add_theme_font_size_override("font_size", 16)
		ult_btn.pressed.connect(_on_card_ult_pressed.bind(unit))
		vbox.add_child(ult_btn)

	# ИСПРАВЛЕНО: Располагаем Инфо и Цель на двух разных строках вертикально для экономии места
	var info_btn := Button.new()
	info_btn.name = "InfoButton"
	info_btn.text = "ℹ Инфо"
	info_btn.custom_minimum_size = Vector2(180, 36) 
	info_btn.pressed.connect(_open_inspect.bind(unit))
	vbox.add_child(info_btn)

	var target_btn := Button.new()
	target_btn.name = "TargetButton"
	target_btn.text = "🎯 Выбрать целью"
	target_btn.custom_minimum_size = Vector2(180, 42) # Крупная кнопка
	target_btn.visible = false
	target_btn.pressed.connect(_on_target_pressed.bind(unit, is_ally))
	target_btn.add_theme_font_size_override("font_size", 16) # Крупный шрифт
	target_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3)) # Золотистый цвет
	vbox.add_child(target_btn)

	_unit_panels[unit] = panel
	_refresh_unit_panel(unit)
	return panel
	
func _refresh_unit_panel(unit: CombatUnit) -> void:
	if not _unit_panels.has(unit):
		return
	var panel: PanelContainer = _unit_panels[unit]
	
	# Скрываем карточки напарников, если активна дуэль, и показываем обратно после её окончания
	var is_duel: bool = battle_manager.has_meta("rimes_duel_active") and bool(battle_manager.get_meta("rimes_duel_active"))
	if is_duel:
		if unit.is_ally and unit.id != "rimes":
			panel.hide()
			return
	else:
		if not panel.visible:
			panel.show()
			
	var vbox: VBoxContainer = panel.get_child(0)

	# Находим обертку
	var bar_wrapper: Control = vbox.get_node("BarWrapper")
	var hp_bar: ProgressBar = bar_wrapper.get_node("HPBar")
	hp_bar.value = unit.stats.hp
	hp_bar.max_value = unit.stats.max_hp
	
	var hp_lbl: Label = vbox.get_node("HPLabel")
	hp_lbl.text = "%d / %d" % [int(unit.stats.hp), int(unit.stats.max_hp)]
	
	
	if bar_wrapper.has_node("ShieldBar"):
		var shield_bar: ProgressBar = bar_wrapper.get_node("ShieldBar")
		var shield_val: float = float(unit.get_meta("shield_value", 0.0))
		if shield_val > 0.0:
			shield_bar.show()
			shield_bar.max_value = unit.stats.max_hp
			shield_bar.value = minf(shield_val, unit.stats.max_hp)
			hp_lbl.text = "%d / %d (+%d)" % [int(unit.stats.hp), int(unit.stats.max_hp), int(shield_val)]
		else:
			shield_bar.hide()

	if bar_wrapper.has_node("KatarinaThresholdsOverlay"):
		var kat_overlay: Control = bar_wrapper.get_node("KatarinaThresholdsOverlay")
		var kat_alive := (battle_manager.get_katarina_unit() != null and battle_manager.get_katarina_unit().is_alive())
		kat_overlay.visible = kat_alive
		if kat_alive:
			kat_overlay.queue_redraw()

	if vbox.has_node("TghBar"):
		var tgh_bar: ProgressBar = vbox.get_node("TghBar")
		tgh_bar.value = unit.toughness

	if vbox.has_node("EnergyBarOnCard"):
		var en_bar: ProgressBar = vbox.get_node("EnergyBarOnCard")
		en_bar.value = unit.energy
		en_bar.max_value = unit.max_energy

		var ult_btn: Button = vbox.get_node("UltButtonOnCard")
		
		var can_ult: bool = unit.energy >= unit.max_energy
		if unit.id == KaoriAbilities.ID and int(unit.get_meta("ult_recast_window", 0)) > 0:
			can_ult = true
		if unit.id == "dasha" and not unit.get_meta("circle_dance", false):
			can_ult = false 
			
		if unit.id == ArseniyAbilities.ID and unit.statuses.new_development_turns <= 0:
			can_ult = false
			
		if unit.statuses.skip_next_turn:
			can_ult = false

		if unit.id == "joan_spirit":
			var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
			var wishes: int = int(unit.get_meta("joan_last_wish", 0))
			var required: int = 8 if in_spirit else 12
			can_ult = wishes >= required
			en_bar.max_value = float(required)
			
			if in_spirit:
				ult_btn.text = "★ Последнее желание (%d/%d)" % [wishes, required]
			else:
				ult_btn.text = "★ ДУХ (%d/%d)" % [wishes, required]

		ult_btn.disabled = not can_ult or battle_manager.phase != battle_manager.Phase.RUNNING
			
	var status_lbl: Label = vbox.get_node("StatusLabel")
	var statuses: PackedStringArray = []
	if unit.statuses.new_development_turns > 0:
		statuses.append("Нов. разраб. (%d)" % unit.statuses.new_development_turns)
	if unit.statuses.has_dark_seal:
		statuses.append("Тёмн. печать")
	if unit.statuses.patch_turns > 0:
		statuses.append("Заплатка (%d)" % unit.statuses.patch_turns)
	if unit.statuses.atk_buff_turns > 0:
		statuses.append("СА+")
	if unit.statuses.suppression_stacks > 0:
		statuses.append("Подавл. x%d" % unit.statuses.suppression_stacks)
	if unit.statuses.toughness_broken:
		statuses.append("Пробой!")
	if unit.statuses.break_status != "":
		statuses.append(unit.statuses.break_status)
	if unit.statuses.entanglement_stacks > 0:
		statuses.append("Связ. x%d" % unit.statuses.entanglement_stacks)
		
	if unit.has_meta("untargetable") and unit.get_meta("untargetable"):
		statuses.append("Недосягаем")
	if unit.has_meta("priority_target") and unit.get_meta("priority_target"):
		statuses.append("Приор. Цель")
	if unit.has_meta("dead_or_alive") and unit.get_meta("dead_or_alive"):
		statuses.append("Жив/Мертв")
		
	if unit.has_meta("weakness_concentration") and unit.get_meta("weakness_concentration"):
		statuses.append("Концентр.")
	if unit.has_meta("in_fog_buff") and unit.get_meta("in_fog_buff"):
		statuses.append("В Тумане")
	if unit.has_meta("phys_res_reduced_turns") and int(unit.get_meta("phys_res_reduced_turns", 0)) > 0:
		statuses.append("Физ. Слаб.")
	if unit.has_meta("shoji_burn_turns") and int(unit.get_meta("shoji_burn_turns", 0)) > 0:
		statuses.append("Горение [Сёдзи] x%d" % int(unit.get_meta("shoji_burn_stacks", 0)))
		
	if unit.has_meta("circle_dance") and unit.get_meta("circle_dance"):
		statuses.append("Танец")
	if unit.has_meta("overload_turns") and int(unit.get_meta("overload_turns", 0)) > 0:
		statuses.append("Перегруз x%d" % int(unit.get_meta("overload_turns", 0)))
	if unit.has_meta("pirouette_stacks") and int(unit.get_meta("pirouette_stacks", 0)) > 0:
		statuses.append("Пируэт x%d" % int(unit.get_meta("pirouette_stacks", 0)))
		
	if unit.id == "dasha_admin":
		var fp := int(unit.get_meta("dasha_digital_footprint", 0))
		statuses.append("Цифровой след: %d/30" % fp)
		
	if unit.has_meta("danill_talent_stacks") and int(unit.get_meta("danill_talent_stacks", 0)) > 0:
		statuses.append("Защ x%d" % int(unit.get_meta("danill_talent_stacks", 0)))
	if unit.has_meta("danill_taunt_turns") and int(unit.get_meta("danill_taunt_turns", 0)) > 0:
		statuses.append("Провок")
	
	if unit.id == "isaac_admin":
		if int(unit.get_meta("isaac_hacked_turns", 0)) > 0:
			statuses.append("Взлом (%d)" % int(unit.get_meta("isaac_hacked_turns", 0)))
			
	if unit.id == "joan":
		var stacks := int(unit.get_meta("joan_coffee_liqueur_stacks", 0))
		statuses.append("Ликёр %d" % stacks)
		
	# НОВАЯ МЕХАНИКА: Визуализация Пробуждения Вики
	if unit.id == "vika" and int(unit.get_meta("vika_awakening_turns", 0)) > 0:
		statuses.append("Пробужд. (%d)" % int(unit.get_meta("vika_awakening_turns", 0)))
	# Внутри _refresh_unit_panel():
	# Вставьте этот блок прямо перед формированием текста status_lbl:
	if unit.id == "dotseva":
		var stacks := int(unit.get_meta("dotseva_calibration_stacks", 0))
		statuses.append("Калибр. %d" % stacks)
		if int(unit.get_meta("dotseva_fog_turns", 0)) > 0:
			statuses.append("Туман (%d)" % int(unit.get_meta("dotseva_fog_turns", 0)))
		if unit.has_meta("dotseva_debtor_status") and unit.get_meta("dotseva_debtor_status", false):
			statuses.append("Должник")
	if unit.id == "milena":
		var overtone := int(unit.get_meta("milena_overtone_turns", 0))
		if overtone > 0:
			statuses.append("Обертон (%d)" % overtone)
	if unit.has_meta("radiance_status_turns") and int(unit.get_meta("radiance_status_turns", 0)) > 0:
		var owner: CombatUnit = unit.get_meta("radiance_owner")
		if owner:
			statuses.append("Сияние: %s" % owner.display_name)
		else:
			statuses.append("Сияние")
	if unit.id == "rimes":
		var r_stacks := int(unit.get_meta("rimes_talent_stacks", 0))
		if r_stacks > 0:
			statuses.append("Талант x%d" % r_stacks)
		if unit.has_meta("rimes_isolation_target"):
			statuses.append("Изоляция")
	if unit.id == "isaac":
		var stacks := int(unit.get_meta("isaac_theory_stacks", 0))
		if stacks > 0:
			statuses.append("Теория x%d" % stacks)
	if unit.id == "musienko":
		var anni := unit.has_meta("musienko_annihilation_active")
		if anni:
			statuses.append("Аннигил.")
		var retribution := int(unit.get_meta("musienko_retribution_stacks", 0))
		if retribution > 0:
			statuses.append("Возмезд. %d" % retribution)
	if unit.id == "jeff":
		var active: bool = bool(unit.has_meta("jeff_make_noise_active")) and bool(unit.get_meta("jeff_make_noise_active"))
		if active:
			statuses.append("Пошумим!")
			
	if unit.has_meta("rimes_isolation_source"):
		statuses.append("Изолирован")
	if unit.id == "masked_silhouette": # ДОБАВЛЕНО: Вывод слоев Маски на карточку босса
		if unit.has_meta("mask_layers") and int(unit.get_meta("mask_layers", 0)) > 0:
			var layers := int(unit.get_meta("mask_layers", 0))
			statuses.append("Маска %d" % layers)
			
	var naama_stacks: int = int(unit.get_meta("naama_intox_stacks", 0))
	if naama_stacks > 0:
		statuses.append("Опьянение x%d" % naama_stacks)
		
	# ИСПРАВЛЕНО: Отображение Шока Джеффа на карточке противника
	if unit.has_meta("jeff_bass_listen_turns") and int(unit.get_meta("jeff_bass_listen_turns", 0)) > 0:
		statuses.append("Бассы! (%d)" % int(unit.get_meta("jeff_bass_listen_turns", 0)))
		
	if unit.has_meta("naama_dot_vuln_turns") and int(unit.get_meta("naama_dot_vuln_turns", 0)) > 0:
		statuses.append("DoT Слаб. (%d)" % int(unit.get_meta("naama_dot_vuln_turns", 0)))
		
	if unit.has_meta("naama_kiss_turns") and int(unit.get_meta("naama_kiss_turns", 0)) > 0:
		statuses.append("Поцелуй (%d)" % int(unit.get_meta("naama_kiss_turns", 0)))
	
	if unit.id == "lenskaya":
		var manipulation: int = int(unit.get_meta("lenskaya_manipulation", 0))
		if manipulation > 0:
			statuses.append("Манипул. %d" % manipulation)
		var stinger: int = int(unit.get_meta("lenskaya_stinger_turns", 0))
		if stinger > 0:
			statuses.append("Жало (%d)" % stinger)
			
	if unit.id == "keloist":
		var stacks := int(unit.get_meta("keloist_command_stacks", 0))
		if stacks > 0:
			statuses.append("Команд. %d" % stacks)
	
	if unit.id == "sara_admin":
		if int(unit.get_meta("sara_dev_env_turns", 0)) > 0:
			statuses.append("Среда (%d)" % int(unit.get_meta("sara_dev_env_turns", 0)))
			
	if unit.id == "joan_spirit":
		var stacks := int(unit.get_meta("joan_regret", 0))
		if stacks > 0:
			statuses.append("Сожаление: %d" % stacks)
			
	if unit.has_meta("lenskaya_bounty_turns") and int(unit.get_meta("lenskaya_bounty_turns", 0)) > 0:
		statuses.append("Награда (%d)" % int(unit.get_meta("lenskaya_bounty_turns", 0)))
		
	if unit.has_meta("lenskaya_slow_turns") and int(unit.get_meta("lenskaya_slow_turns", 0)) > 0:
		statuses.append("Замедлен (%d)" % int(unit.get_meta("lenskaya_slow_turns", 0)))
		
		
	status_lbl.text = ", ".join(statuses) if not statuses.is_empty() else "—"

	if unit in _multi_targets:
		panel.modulate = Color(1.2, 1.0, 0.6)
	elif not unit.is_alive():
		panel.modulate = Color(0.4, 0.4, 0.4, 0.7)
	elif unit.is_elite:
		panel.modulate = Color(1.1, 0.85, 1.0)
	else:
		panel.modulate = Color.WHITE
	if panel.has_node("FreezeOverlay"):
		panel.get_node("FreezeOverlay").visible = unit.statuses.skip_next_turn
	else:
		if unit.statuses.skip_next_turn:
			var ice_overlay := ColorRect.new()
			ice_overlay.name = "FreezeOverlay"
			ice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ice_overlay.color = Color(0.4, 0.75, 1.0, 0.35) # Полупрозрачный голубой лед
			ice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(ice_overlay)
		
	status_lbl.text = ", ".join(statuses) if not statuses.is_empty() else "—"

	if unit in _multi_targets:
		panel.modulate = Color(1.2, 1.0, 0.6)
	elif not unit.is_alive():
		panel.modulate = Color(0.4, 0.4, 0.4, 0.7)
	elif unit.is_elite:
		panel.modulate = Color(1.1, 0.85, 1.0)
	else:
		panel.modulate = Color.WHITE
		
	if not unit.is_ally and unit.statuses.toughness_broken:
		LevelManager.on_toughness_broken(self)
	
	_update_console_hud()
	
	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()
	
	if battle_manager.current_unit and battle_manager.current_unit.id == "joan_spirit" and bool(battle_manager.current_unit.get_meta("joan_spirit_form", false)):
		if not battle_manager._is_processing_ult_queue and battle_manager.ult_queue.is_empty():
			_set_action_buttons_disabled(false)
			_update_action_buttons(battle_manager.current_unit)
		
func _setup_inspect_ui() -> void:
	var panel: PanelContainer = %InspectPanel
	panel.custom_minimum_size = Vector2(960, 640)
	panel.offset_left = -480.0
	panel.offset_top = -320.0
	panel.offset_right = 480.0
	panel.offset_bottom = 320.0
	
	inspect_overlay.color = Color(0.02, 0.03, 0.05, 0.80)
	
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.08, 0.10, 0.15, 0.98)
	panel_sb.border_color = Color(0.28, 0.38, 0.58, 0.85)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(14)
	panel_sb.shadow_color = Color(0, 0, 0, 0.6)
	panel_sb.shadow_size = 20
	panel_sb.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", panel_sb)
	
	var margin: MarginContainer = panel.get_node("InspectMargin") as MarginContainer
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	
	var inspect_vbox: VBoxContainer = margin.get_node("InspectVBox") as VBoxContainer
	inspect_vbox.add_theme_constant_override("separation", 12)
	
	# Удаляем старые статические метки
	for child in inspect_vbox.get_children():
		if child is Label and (child.name == "InspectStatsLabel" or child.name == "InspectEffectsLabel" or child.name == "InspectSkillsLabel"):
			inspect_vbox.remove_child(child)
			child.queue_free()
			
	# Отсоединяем сохраняемые узлы от старого родителя
	for n in [inspect_title, inspect_stats, inspect_effects, inspect_skills, btn_close_inspect]:
		if n and n.get_parent():
			n.get_parent().remove_child(n)
			
	# --- 1. ШАПКА ОКНА (HEADER) ---
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	
	var elem_panel := PanelContainer.new()
	elem_panel.name = "ElemPanel"
	_inspect_elem_label = Label.new()
	_inspect_elem_label.add_theme_font_size_override("font_size", 13)
	elem_panel.add_child(_inspect_elem_label)
	header_hbox.add_child(elem_panel)
	
	inspect_title.add_theme_font_size_override("font_size", 22)
	inspect_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	inspect_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hbox.add_child(inspect_title)
	
	var path_panel := PanelContainer.new()
	path_panel.name = "PathPanel"
	_inspect_path_label = Label.new()
	_inspect_path_label.add_theme_font_size_override("font_size", 13)
	path_panel.add_child(_inspect_path_label)
	header_hbox.add_child(path_panel)
	
	var tag_panel := PanelContainer.new()
	tag_panel.name = "TagPanel"
	_inspect_tag_label = Label.new()
	_inspect_tag_label.add_theme_font_size_override("font_size", 13)
	tag_panel.add_child(_inspect_tag_label)
	header_hbox.add_child(tag_panel)
	
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_spacer)
	
	_btn_inspect_header_close = Button.new()
	_btn_inspect_header_close.text = "✕"
	_btn_inspect_header_close.custom_minimum_size = Vector2(34, 34)
	_btn_inspect_header_close.add_theme_font_size_override("font_size", 16)
	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color(0.18, 0.22, 0.32, 0.8)
	close_sb.border_color = Color(0.35, 0.45, 0.65, 0.7)
	close_sb.set_border_width_all(1)
	close_sb.set_corner_radius_all(8)
	_btn_inspect_header_close.add_theme_stylebox_override("normal", close_sb)
	var close_sb_h := close_sb.duplicate() as StyleBoxFlat
	close_sb_h.bg_color = Color(0.70, 0.20, 0.25, 0.95)
	close_sb_h.border_color = Color(0.95, 0.40, 0.45, 1.0)
	_btn_inspect_header_close.add_theme_stylebox_override("hover", close_sb_h)
	_btn_inspect_header_close.pressed.connect(_close_inspect)
	header_hbox.add_child(_btn_inspect_header_close)
	
	inspect_vbox.add_child(header_hbox)
	
	# --- 2. ПАНЕЛЬ ВКЛАДОК (TAB BAR) ---
	var tab_bar_hbox := HBoxContainer.new()
	tab_bar_hbox.add_theme_constant_override("separation", 10)
	
	_btn_inspect_tab_info = Button.new()
	_btn_inspect_tab_info.text = "ℹ Инфо"
	_btn_inspect_tab_info.custom_minimum_size = Vector2(180, 38)
	_btn_inspect_tab_info.add_theme_font_size_override("font_size", 15)
	_btn_inspect_tab_info.pressed.connect(_switch_inspect_tab.bind(0))
	tab_bar_hbox.add_child(_btn_inspect_tab_info)
	
	_btn_inspect_tab_skills = Button.new()
	_btn_inspect_tab_skills.text = "⚔ Умения"
	_btn_inspect_tab_skills.custom_minimum_size = Vector2(180, 38)
	_btn_inspect_tab_skills.add_theme_font_size_override("font_size", 15)
	_btn_inspect_tab_skills.pressed.connect(_switch_inspect_tab.bind(1))
	tab_bar_hbox.add_child(_btn_inspect_tab_skills)
	
	_btn_inspect_tab_cone = Button.new()
	_btn_inspect_tab_cone.text = "🛡 Световой конус"
	_btn_inspect_tab_cone.custom_minimum_size = Vector2(200, 38)
	_btn_inspect_tab_cone.add_theme_font_size_override("font_size", 15)
	_btn_inspect_tab_cone.pressed.connect(_switch_inspect_tab.bind(2))
	tab_bar_hbox.add_child(_btn_inspect_tab_cone)
	
	inspect_vbox.add_child(tab_bar_hbox)
	
	# --- 3. КОНТЕЙНЕР СОДЕРЖИМОГО ВКЛАДОК ---
	var tabs_content := PanelContainer.new()
	tabs_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content_sb := StyleBoxFlat.new()
	content_sb.bg_color = Color(0.05, 0.07, 0.11, 0.5)
	content_sb.border_color = Color(0.18, 0.24, 0.35, 0.6)
	content_sb.set_border_width_all(1)
	content_sb.set_corner_radius_all(10)
	content_sb.content_margin_left = 12
	content_sb.content_margin_right = 12
	content_sb.content_margin_top = 12
	content_sb.content_margin_bottom = 12
	tabs_content.add_theme_stylebox_override("panel", content_sb)
	
	# Вкладка 1: "Инфо" (Характеристики + Эффекты)
	_inspect_view_info = HBoxContainer.new()
	_inspect_view_info.add_theme_constant_override("separation", 14)
	_inspect_view_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_view_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var stats_card := _create_inspect_card("📊 БОЕВЫЕ ХАРАКТЕРИСТИКИ", Color(0.40, 0.75, 1.0))
	inspect_stats.custom_minimum_size = Vector2(0, 0)
	inspect_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect_stats.fit_content = true
	inspect_stats.scroll_active = false
	inspect_stats.add_theme_font_size_override("normal_font_size", 14)
	var stats_scroll := ScrollContainer.new()
	stats_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stats_scroll.add_child(inspect_stats)
	stats_card.get_node("VBox").add_child(stats_scroll)
	_inspect_view_info.add_child(stats_card)
	
	var effects_card := _create_inspect_card("✨ АКТИВНЫЕ ЭФФЕКТЫ (БАФФЫ И ДЕБАФФЫ)", Color(0.75, 0.55, 1.0))
	inspect_effects.custom_minimum_size = Vector2(0, 0)
	inspect_effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect_effects.fit_content = true
	inspect_effects.scroll_active = false
	inspect_effects.add_theme_font_size_override("normal_font_size", 14)
	var effects_scroll := ScrollContainer.new()
	effects_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effects_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	effects_scroll.add_child(inspect_effects)
	effects_card.get_node("VBox").add_child(effects_scroll)
	_inspect_view_info.add_child(effects_card)
	
	tabs_content.add_child(_inspect_view_info)
	
	# Вкладка 2: "Умения" (Боевые навыки + Эйдолоны)
	_inspect_view_skills = HBoxContainer.new()
	_inspect_view_skills.add_theme_constant_override("separation", 14)
	_inspect_view_skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_view_skills.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var skills_card := _create_inspect_card("⚔ БОЕВЫЕ УМЕНИЯ", Color(0.35, 0.80, 1.0))
	inspect_skills.custom_minimum_size = Vector2(0, 0)
	inspect_skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_skills.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect_skills.fit_content = true
	inspect_skills.scroll_active = false
	inspect_skills.add_theme_font_size_override("normal_font_size", 14)
	var skills_scroll := ScrollContainer.new()
	skills_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skills_scroll.add_child(inspect_skills)
	skills_card.get_node("VBox").add_child(skills_scroll)
	_inspect_view_skills.add_child(skills_card)
	
	var eidolons_card := _create_inspect_card("🌟 ЭЙДОЛОНЫ (E0–E6)", Color(1.0, 0.85, 0.35))
	_inspect_eidolon_rank_label = Label.new()
	_inspect_eidolon_rank_label.text = "Ранг: E0"
	_inspect_eidolon_rank_label.add_theme_font_size_override("font_size", 13)
	_inspect_eidolon_rank_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	var eidolons_header_row: HBoxContainer = eidolons_card.get_node("VBox/HeaderRow")
	eidolons_header_row.add_child(_inspect_eidolon_rank_label)
	
	var eidolons_scroll := ScrollContainer.new()
	eidolons_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eidolons_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	eidolons_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inspect_eidolons_list_vbox = VBoxContainer.new()
	_inspect_eidolons_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_eidolons_list_vbox.add_theme_constant_override("separation", 8)
	eidolons_scroll.add_child(_inspect_eidolons_list_vbox)
	eidolons_card.get_node("VBox").add_child(eidolons_scroll)
	_inspect_view_skills.add_child(eidolons_card)
	
	tabs_content.add_child(_inspect_view_skills)
	
	# Вкладка 3: "Световой конус"
	_inspect_view_cone = CenterContainer.new()
	_inspect_view_cone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_view_cone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_inspect_cone_card = PanelContainer.new()
	_inspect_cone_card.custom_minimum_size = Vector2(760, 420)
	
	_inspect_cone_content_vbox = VBoxContainer.new()
	_inspect_cone_content_vbox.add_theme_constant_override("separation", 10)
	_inspect_cone_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_cone_content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var cone_top_row := HBoxContainer.new()
	cone_top_row.add_theme_constant_override("separation", 10)
	_inspect_cone_stars_label = Label.new()
	_inspect_cone_stars_label.add_theme_font_size_override("font_size", 18)
	cone_top_row.add_child(_inspect_cone_stars_label)
	
	_inspect_cone_tier_label = Label.new()
	_inspect_cone_tier_label.add_theme_font_size_override("font_size", 14)
	cone_top_row.add_child(_inspect_cone_tier_label)
	
	var cone_spacer := Control.new()
	cone_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cone_top_row.add_child(cone_spacer)
	
	var cone_path_panel := PanelContainer.new()
	cone_path_panel.name = "ConePathPanel"
	_inspect_cone_path_label = Label.new()
	_inspect_cone_path_label.add_theme_font_size_override("font_size", 13)
	cone_path_panel.add_child(_inspect_cone_path_label)
	cone_top_row.add_child(cone_path_panel)
	_inspect_cone_content_vbox.add_child(cone_top_row)
	
	_inspect_cone_name_label = Label.new()
	_inspect_cone_name_label.add_theme_font_size_override("font_size", 22)
	_inspect_cone_content_vbox.add_child(_inspect_cone_name_label)
	
	_inspect_cone_carrier_label = Label.new()
	_inspect_cone_carrier_label.add_theme_font_size_override("font_size", 13)
	_inspect_cone_content_vbox.add_child(_inspect_cone_carrier_label)
	
	_inspect_cone_content_vbox.add_child(HSeparator.new())
	
	var cone_passive_title := Label.new()
	cone_passive_title.text = "📜 ПАССИВНЫЙ НАВЫК:"
	cone_passive_title.add_theme_font_size_override("font_size", 14)
	cone_passive_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_inspect_cone_content_vbox.add_child(cone_passive_title)
	
	var cone_desc_scroll := ScrollContainer.new()
	cone_desc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cone_desc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cone_desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	_inspect_cone_desc_text = RichTextLabel.new()
	_inspect_cone_desc_text.bbcode_enabled = true
	_inspect_cone_desc_text.fit_content = true
	_inspect_cone_desc_text.scroll_active = false
	_inspect_cone_desc_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_cone_desc_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cone_desc_scroll.add_child(_inspect_cone_desc_text)
	_inspect_cone_content_vbox.add_child(cone_desc_scroll)
	
	_inspect_cone_card.add_child(_inspect_cone_content_vbox)
	
	_inspect_cone_empty_label = RichTextLabel.new()
	_inspect_cone_empty_label.bbcode_enabled = true
	_inspect_cone_empty_label.fit_content = true
	_inspect_cone_empty_label.scroll_active = false
	_inspect_cone_empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect_cone_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspect_cone_card.add_child(_inspect_cone_empty_label)
	
	_inspect_view_cone.add_child(_inspect_cone_card)
	tabs_content.add_child(_inspect_view_cone)
	
	inspect_vbox.add_child(tabs_content)
	
	# --- 4. ПОДВАЛ ОКНА (FOOTER) ---
	var footer_hbox := HBoxContainer.new()
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.add_child(footer_spacer)
	
	btn_close_inspect.text = "✕ Закрыть"
	btn_close_inspect.custom_minimum_size = Vector2(160, 38)
	btn_close_inspect.add_theme_font_size_override("font_size", 14)
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.18, 0.22, 0.32, 0.85)
	btn_sb.border_color = Color(0.35, 0.45, 0.65, 0.75)
	btn_sb.set_border_width_all(1)
	btn_sb.set_corner_radius_all(8)
	btn_close_inspect.add_theme_stylebox_override("normal", btn_sb)
	var btn_sb_h := btn_sb.duplicate() as StyleBoxFlat
	btn_sb_h.bg_color = Color(0.25, 0.32, 0.48, 0.95)
	btn_sb_h.border_color = Color(0.50, 0.70, 1.0, 0.9)
	btn_close_inspect.add_theme_stylebox_override("hover", btn_sb_h)
	footer_hbox.add_child(btn_close_inspect)
	
	inspect_vbox.add_child(footer_hbox)
	
	_update_inspect_tab_styles()

func _create_inspect_card(title: String, title_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.07, 0.09, 0.14, 0.85)
	card_sb.border_color = Color(0.22, 0.30, 0.45, 0.7)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(10)
	card_sb.content_margin_left = 14
	card_sb.content_margin_right = 14
	card_sb.content_margin_top = 12
	card_sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_sb)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", title_color)
	header_row.add_child(title_lbl)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)
	
	vbox.add_child(header_row)
	vbox.add_child(HSeparator.new())
	
	card.add_child(vbox)
	return card

func _switch_inspect_tab(idx: int) -> void:
	_current_inspect_tab = idx
	if _inspect_view_info:
		_inspect_view_info.visible = (idx == 0)
	if _inspect_view_skills:
		_inspect_view_skills.visible = (idx == 1)
	if _inspect_view_cone:
		_inspect_view_cone.visible = (idx == 2)
	_update_inspect_tab_styles()

func _update_inspect_tab_styles() -> void:
	var tabs: Array[Button] = [_btn_inspect_tab_info, _btn_inspect_tab_skills, _btn_inspect_tab_cone]
	for i in range(tabs.size()):
		var b := tabs[i]
		if not b:
			continue
		var is_active := (i == _current_inspect_tab)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		if is_active:
			sb.bg_color = Color(0.20, 0.32, 0.55, 0.98)
			sb.border_color = Color(0.50, 0.75, 1.0, 1.0)
			sb.set_border_width_all(2)
			b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		else:
			sb.bg_color = Color(0.10, 0.12, 0.18, 0.8)
			sb.border_color = Color(0.24, 0.30, 0.42, 0.6)
			sb.set_border_width_all(1)
			b.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
		b.add_theme_stylebox_override("normal", sb)
		
		var sb_h := sb.duplicate() as StyleBoxFlat
		if not is_active:
			sb_h.bg_color = Color(0.15, 0.19, 0.28, 0.9)
			sb_h.border_color = Color(0.35, 0.45, 0.65, 0.85)
		b.add_theme_stylebox_override("hover", sb_h)

func _open_inspect(unit: CombatUnit) -> void:
	LevelManager.on_action_pressed("inspect_open", self)
	
	# 1. Заполнение Header
	var elem_symbol: String = CombatConstants.ELEMENT_SYMBOLS.get(unit.element, "⚪")
	var elem_name: String = CombatConstants.ELEMENT_NAMES.get(unit.element, "Неизвестный")
	_inspect_elem_label.text = "%s %s" % [elem_symbol, elem_name.to_upper()]
	_style_element_pill(_inspect_elem_label, unit.element)
	
	inspect_title.text = unit.display_name
	
	var path_str: String = CharacterRegistry.get_path_name(unit.path)
	_inspect_path_label.text = "ПУТЬ: %s" % path_str.to_upper()
	_style_path_pill(_inspect_path_label)
	
	if unit.is_ally:
		_inspect_tag_label.text = "СОЮЗНИК"
		_style_tag_pill(_inspect_tag_label, Color(0.10, 0.35, 0.20, 0.9), Color(0.25, 0.80, 0.45, 0.85), Color(0.40, 1.0, 0.60))
	else:
		var tag_name := "ПРОТИВНИК"
		var border_c := Color(0.85, 0.25, 0.30, 0.85)
		var bg_c := Color(0.35, 0.10, 0.14, 0.9)
		var txt_c := Color(1.0, 0.45, 0.50)
		if unit.is_elite:
			tag_name = "ЭЛИТНЫЙ ВРАГ"
			border_c = Color(0.75, 0.40, 0.95, 0.85)
			bg_c = Color(0.25, 0.10, 0.35, 0.9)
			txt_c = Color(0.85, 0.60, 1.0)
		elif unit.id == "void_boss":
			tag_name = "БОСС"
			border_c = Color(1.0, 0.70, 0.20, 0.9)
			bg_c = Color(0.40, 0.15, 0.08, 0.9)
			txt_c = Color(1.0, 0.80, 0.30)
		_inspect_tag_label.text = tag_name
		_style_tag_pill(_inspect_tag_label, bg_c, border_c, txt_c)

	# 2. Вкладка "Инфо"
	var raw_stats := BattleInfoProvider.get_stats_text(unit, battle_manager.allies)
	inspect_stats.text = _format_stats_bbcode(raw_stats)
	inspect_effects.text = BattleInfoProvider.get_statuses_text(unit, battle_manager.allies)
	
	# 3. Вкладка "Умения"
	var raw_skills := BattleInfoProvider.get_skills_text(unit)
	inspect_skills.text = _format_skills_bbcode(raw_skills)
	_populate_eidolons(unit)
	
	# 4. Вкладка "Световой конус"
	_populate_light_cone(unit)
	
	# По умолчанию всегда открываем 1-ю вкладку ("Инфо")
	_switch_inspect_tab(0)
	
	inspect_overlay.show()
	inspect_overlay.move_to_front()

func _populate_eidolons(unit: CombatUnit) -> void:
	for child in _inspect_eidolons_list_vbox.get_children():
		_inspect_eidolons_list_vbox.remove_child(child)
		child.queue_free()
		
	var main_menu_script = load("res://scenes/main_menu/main_menu.gd")
	var e_dict: Dictionary = {}
	if main_menu_script and "EIDOLON_DESCRIPTIONS" in main_menu_script:
		e_dict = main_menu_script.EIDOLON_DESCRIPTIONS.get(unit.id, {})
		
	if not unit.is_ally or e_dict.is_empty():
		_inspect_eidolon_rank_label.text = "—"
		var empty_card := PanelContainer.new()
		var empty_sb := StyleBoxFlat.new()
		empty_sb.bg_color = Color(0.08, 0.10, 0.14, 0.6)
		empty_sb.border_color = Color(0.20, 0.25, 0.35, 0.5)
		empty_sb.set_border_width_all(1)
		empty_sb.set_corner_radius_all(8)
		empty_card.add_theme_stylebox_override("panel", empty_sb)
		
		var empty_lbl := RichTextLabel.new()
		empty_lbl.bbcode_enabled = true
		empty_lbl.fit_content = true
		empty_lbl.scroll_active = false
		empty_lbl.text = "[center][color=#64748b]\n✦ Для данного персонажа или существа\nэйдолоны не предусмотрены.\n[/color][/center]"
		empty_card.add_child(empty_lbl)
		_inspect_eidolons_list_vbox.add_child(empty_card)
		return
		
	_inspect_eidolon_rank_label.text = "Текущий ранг: E%d" % unit.eidolon
	
	for i in range(1, 7):
		var e_key := "E%d" % i
		var e_desc: String = String(e_dict.get(e_key, "Описание эффекта отсутствует."))
		var is_unlocked := (unit.eidolon >= i)
		
		var item_card := PanelContainer.new()
		var item_sb := StyleBoxFlat.new()
		item_sb.set_corner_radius_all(8)
		item_sb.content_margin_left = 12
		item_sb.content_margin_right = 12
		item_sb.content_margin_top = 8
		item_sb.content_margin_bottom = 8
		
		if is_unlocked:
			item_sb.bg_color = Color(0.18, 0.14, 0.07, 0.9)
			item_sb.border_color = Color(0.90, 0.72, 0.22, 0.95)
			item_sb.set_border_width_all(2)
		else:
			item_sb.bg_color = Color(0.08, 0.09, 0.13, 0.6)
			item_sb.border_color = Color(0.20, 0.24, 0.33, 0.5)
			item_sb.set_border_width_all(1)
		item_card.add_theme_stylebox_override("panel", item_sb)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		
		var top_row := HBoxContainer.new()
		var title_lbl := Label.new()
		title_lbl.text = "🌟 Эйдолон %d" % i if is_unlocked else "🔒 Эйдолон %d" % i
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if is_unlocked else Color(0.45, 0.52, 0.65))
		top_row.add_child(title_lbl)
		
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(spacer)
		
		var status_badge := Label.new()
		status_badge.text = "[АКТИВЕН]" if is_unlocked else "[НЕ ОТКРЫТ]"
		status_badge.add_theme_font_size_override("font_size", 12)
		status_badge.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55) if is_unlocked else Color(0.40, 0.45, 0.55))
		top_row.add_child(status_badge)
		
		vbox.add_child(top_row)
		
		var desc_lbl := RichTextLabel.new()
		desc_lbl.bbcode_enabled = true
		desc_lbl.fit_content = true
		desc_lbl.scroll_active = false
		desc_lbl.add_theme_font_size_override("normal_font_size", 13)
		if is_unlocked:
			desc_lbl.text = "[color=#f1f5f9]%s[/color]" % e_desc
		else:
			desc_lbl.text = "[color=#64748b]%s[/color]" % e_desc
		vbox.add_child(desc_lbl)
		
		item_card.add_child(vbox)
		_inspect_eidolons_list_vbox.add_child(item_card)

func _populate_light_cone(unit: CombatUnit) -> void:
	var lc_id: String = String(unit.get_meta("light_cone_id", ""))
	var cone: Dictionary = LightConeRegistry.get_cone(lc_id) if not lc_id.is_empty() else {}
	
	if cone.is_empty():
		_inspect_cone_content_vbox.hide()
		_inspect_cone_empty_label.show()
		
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.07, 0.09, 0.14, 0.95)
		card_sb.border_color = Color(0.22, 0.28, 0.40, 0.6)
		card_sb.set_border_width_all(2)
		card_sb.set_corner_radius_all(14)
		card_sb.shadow_color = Color(0, 0, 0, 0.5)
		card_sb.shadow_size = 14
		card_sb.content_margin_left = 30
		card_sb.content_margin_right = 30
		card_sb.content_margin_top = 40
		card_sb.content_margin_bottom = 40
		_inspect_cone_card.add_theme_stylebox_override("panel", card_sb)
		
		if unit.is_ally:
			_inspect_cone_empty_label.text = "[center][font_size=32]🛡[/font_size]\n\n[font_size=18][b]Световой конус не экипирован[/b][/font_size]\n\n[color=#94a3b8]У персонажа %s в данный момент отсутствует экипированный световой конус.\nВы можете экипировать его перед началом боя в меню настройки отряда.[/color][/center]" % unit.display_name
		else:
			_inspect_cone_empty_label.text = "[center][font_size=32]⚔[/font_size]\n\n[font_size=18][b]Световой конус отсутствует[/b][/font_size]\n\n[color=#94a3b8]Противники не используют световые конусы.\nБоевая мощь и умения противника определяются его рангом.[/color][/center]"
		return
		
	_inspect_cone_empty_label.hide()
	_inspect_cone_content_vbox.show()
	
	var rarity: int = int(cone.get("rarity", 3))
	var c_name: String = String(cone.get("name", "Световой конус"))
	var c_path: int = int(cone.get("path", CombatConstants.Path.HUNT))
	var c_desc: String = String(cone.get("desc", ""))
	
	var stars_txt := ""
	for _s in range(rarity):
		stars_txt += "★"
	_inspect_cone_stars_label.text = stars_txt
	
	var card_sb := StyleBoxFlat.new()
	card_sb.set_corner_radius_all(14)
	card_sb.set_border_width_all(2)
	card_sb.shadow_color = Color(0, 0, 0, 0.5)
	card_sb.shadow_size = 16
	card_sb.content_margin_left = 22
	card_sb.content_margin_right = 22
	card_sb.content_margin_top = 20
	card_sb.content_margin_bottom = 20
	
	var tier_txt := ""
	var star_color: Color
	var border_color: Color
	var bg_color: Color
	
	match rarity:
		5:
			tier_txt = "5★ Легендарный Световой конус"
			star_color = Color(1.0, 0.85, 0.25)
			border_color = Color(0.95, 0.75, 0.25, 0.95)
			bg_color = Color(0.13, 0.10, 0.06, 0.97)
		4:
			tier_txt = "4★ Эпический Световой конус"
			star_color = Color(0.85, 0.55, 1.0)
			border_color = Color(0.75, 0.45, 0.95, 0.95)
			bg_color = Color(0.11, 0.08, 0.16, 0.97)
		_:
			tier_txt = "3★ Редкий Световой конус"
			star_color = Color(0.40, 0.75, 1.0)
			border_color = Color(0.35, 0.60, 0.95, 0.95)
			bg_color = Color(0.07, 0.10, 0.16, 0.97)
			
	card_sb.bg_color = bg_color
	card_sb.border_color = border_color
	_inspect_cone_card.add_theme_stylebox_override("panel", card_sb)
	
	_inspect_cone_stars_label.add_theme_color_override("font_color", star_color)
	_inspect_cone_tier_label.text = tier_txt
	_inspect_cone_tier_label.add_theme_color_override("font_color", star_color)
	
	_inspect_cone_name_label.text = c_name
	_inspect_cone_name_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	
	var path_name := CharacterRegistry.get_path_name(c_path)
	_inspect_cone_path_label.text = "Путь: %s" % path_name
	_style_path_pill(_inspect_cone_path_label)
	
	_inspect_cone_carrier_label.text = "Носитель: %s" % unit.display_name
	_inspect_cone_carrier_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	
	var desc_formatted := "[color=#f8fafc][font_size=15]%s[/font_size][/color]" % c_desc
	
	var extra_meta_info: PackedStringArray = []
	if unit.has_meta("lc_atk_pct_bonus"):
		extra_meta_info.append("• Дополнительный бонус СА конуса: +%.0f%%" % (float(unit.get_meta("lc_atk_pct_bonus", 0.0)) * 100.0))
	if unit.has_meta("touch_debt_stacks"):
		extra_meta_info.append("• Стаки «Долга» (Коснись - и верни её в мир): %d" % int(unit.get_meta("touch_debt_stacks", 0)))
	if unit.has_meta("katarina_lc_recorded_dmg"):
		extra_meta_info.append("• Записанный полученный урон: %d ед." % int(unit.get_meta("katarina_lc_recorded_dmg", 0)))
	if unit.has_meta("crimson_tears_atk_stacks"):
		extra_meta_info.append("• Накопленный бонус СА: +%d%%" % int(unit.get_meta("crimson_tears_atk_stacks", 0) * 3))
	
	if not extra_meta_info.is_empty():
		desc_formatted += "\n\n[color=#fbbf24][b]Текущие параметры в бою:[/b][/color]\n" + "\n".join(extra_meta_info)
		
	_inspect_cone_desc_text.text = desc_formatted

func _style_element_pill(lbl: Label, elem: CombatConstants.Element) -> void:
	var color: Color
	match elem:
		CombatConstants.Element.ICE: color = Color(0.35, 0.65, 1.0)
		CombatConstants.Element.FIRE: color = Color(1.0, 0.40, 0.30)
		CombatConstants.Element.PHYSICAL: color = Color(0.85, 0.88, 0.92)
		CombatConstants.Element.WIND: color = Color(0.35, 0.90, 0.60)
		CombatConstants.Element.LIGHTNING: color = Color(0.80, 0.45, 1.0)
		CombatConstants.Element.QUANTUM: color = Color(0.30, 0.40, 0.95)
		CombatConstants.Element.IMAGINARY: color = Color(1.0, 0.85, 0.30)
		_: color = Color(0.7, 0.7, 0.7)
		
	var parent_panel = lbl.get_parent()
	if parent_panel is PanelContainer:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.9)
		sb.border_color = color
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		parent_panel.add_theme_stylebox_override("panel", sb)
	lbl.add_theme_color_override("font_color", color)

func _style_path_pill(lbl: Label) -> void:
	var parent_panel = lbl.get_parent()
	if parent_panel is PanelContainer:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.16, 0.24, 0.9)
		sb.border_color = Color(0.30, 0.42, 0.62, 0.7)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		parent_panel.add_theme_stylebox_override("panel", sb)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))

func _style_tag_pill(lbl: Label, bg: Color, border: Color, txt: Color) -> void:
	var parent_panel = lbl.get_parent()
	if parent_panel is PanelContainer:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		parent_panel.add_theme_stylebox_override("panel", sb)
	lbl.add_theme_color_override("font_color", txt)

func _format_skills_bbcode(raw: String) -> String:
	if raw.is_empty():
		return "[color=#64748b]Нет данных о способностях.[/color]"
	var formatted := raw
	formatted = formatted.replace("⚔ Базовая:", "[b][color=#60a5fa]⚔ Базовая атака:[/color][/b]")
	formatted = formatted.replace("🔷 Навык Q", "\n\n[b][color=#38bdf8]🔷 Навык Q[/color][/b]")
	formatted = formatted.replace("🔹 Навык E", "\n\n[b][color=#818cf8]🔹 Навык E[/color][/b]")
	formatted = formatted.replace("✨ Сверхспособность", "\n\n[b][color=#f59e0b]✨ Сверхспособность[/color][/b]")
	formatted = formatted.replace("✨ Аря", "\n\n[b][color=#f59e0b]✨ Аря (Сверхспособность)[/color][/b]")
	formatted = formatted.replace("💡 Талант:", "\n\n[b][color=#34d399]💡 Талант:[/color][/b]")
	formatted = formatted.replace("⚡ Техника:", "\n\n[b][color=#fbbf24]⚡ Техника:[/color][/b]")
	formatted = formatted.replace("⚡ Е1:", "\n\n[b][color=#fbbf24]⚡ Эйдолон 1:[/color][/b]")
	formatted = formatted.replace("⚡ Е", "\n\n[b][color=#fbbf24]⚡ Эйдолон [/color][/b]")
	return formatted.strip_edges()

func _format_stats_bbcode(raw: String) -> String:
	if raw.is_empty():
		return "[color=#64748b]Нет данных о характеристиках.[/color]"
	var lines := raw.split("\n")
	var result: PackedStringArray = []
	for l in lines:
		var line := l.strip_edges()
		if line.begins_with("ХП:"):
			result.append("[b][color=#4ade80]ХП:[/color][/b] " + line.substr(3).strip_edges())
		elif line.begins_with("СА:"):
			result.append("[b][color=#f87171]СА:[/color][/b] " + line.substr(3).strip_edges())
		elif line.begins_with("ЗАЩ:"):
			result.append("[b][color=#60a5fa]ЗАЩ:[/color][/b] " + line.substr(4).strip_edges())
		elif line.begins_with("СКР:"):
			result.append("[b][color=#38bdf8]СКР:[/color][/b] " + line.substr(4).strip_edges())
		elif line.begins_with("Крит:"):
			result.append("[b][color=#fbbf24]Крит:[/color][/b] " + line.substr(5).strip_edges())
		elif line.begins_with("ШПЭ:"):
			result.append("[b][color=#c084fc]ШПЭ:[/color][/b] " + line.substr(4).strip_edges())
		elif line.begins_with("ЭП:"):
			result.append("[b][color=#e879f9]ЭП:[/color][/b] " + line.substr(3).strip_edges())
		elif line.begins_with("ЭН:"):
			result.append("[b][color=#facc15]ЭН:[/color][/b] " + line.substr(3).strip_edges())
		elif line.begins_with("Стойкость:"):
			result.append("[b][color=#94a3b8]Стойкость:[/color][/b] " + line.substr(10).strip_edges())
		elif line.begins_with("Уязвимости:"):
			result.append("[b][color=#f43f5e]Уязвимости:[/color][/b] " + line.substr(11).strip_edges())
		else:
			result.append(line)
	return "\n".join(result)
	
func _close_inspect() -> void:
	LevelManager.on_action_pressed("inspect_close", self)
	inspect_overlay.hide()

func _on_inspect_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel: PanelContainer = %InspectPanel
		if not panel.get_global_rect().has_point(event.global_position):
			_close_inspect()

func _refresh_skills_panel(unit: CombatUnit) -> void:
	skills_text.text = BattleInfoProvider.get_skills_text(unit)
	skills_panel.visible = _skills_help_open

func _on_skills_help_pressed() -> void:
	_skills_help_open = not _skills_help_open
	_graphs_open = false
	_admin_open = false
	graphs_panel.hide()
	if admin_panel: admin_panel.hide()
	
	var unit := battle_manager.current_unit
	if unit and unit.is_ally:
		_refresh_skills_panel(unit)
	else:
		skills_panel.visible = _skills_help_open
		if _skills_help_open:
			skills_text.text = "Выберите ход союзника, чтобы увидеть его способности."

# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В SCENES/BATTLE/BATTLE.GD ===
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В SCENES/BATTLE/BATTLE.GD ===
func _set_target_buttons_visible(show_enemies: bool, show_allies: bool) -> void:
	var active_char: CombatUnit = battle_manager.current_unit
	
	for unit in _unit_panels:
		var panel: PanelContainer = _unit_panels[unit]
		var vbox: VBoxContainer = panel.get_child(0)
		var btn: Button = vbox.get_node("TargetButton")
		
		if unit.is_ally:
			btn.visible = show_allies and unit.is_alive()
		else:
			var can_target_enemy: bool = show_enemies and unit.is_alive()
			
			# Ограничение выбора целей в Вечной Изоляции Раймса
			if can_target_enemy and active_char and active_char.is_ally:
				# ИСПРАВЛЕНО: Если это дуэль 1 на 1, то все союзники в Изоляции, и они МОГУТ целиться в босса!
				if not battle_manager.is_rimes_duel_active():
					if active_char.id == "rimes":
						# Если Раймс в Изоляции, он может целиться ТОЛЬКО в своего партнера
						if active_char.has_meta("rimes_isolation_target"):
							var isolated_target = active_char.get_meta("rimes_isolation_target")
							if unit != isolated_target:
								can_target_enemy = false
					else:
						# Другие союзники НЕ могут вручную целиться в изолированного врага (если врагов несколько)
						if unit.has_meta("rimes_isolation_source"):
							can_target_enemy = false

			var kat_murmur_unit: CombatUnit = null
			var kat_ref := battle_manager.get_katarina_unit()
			if kat_ref != null and bool(kat_ref.get_meta("katarina_blood_murmur", false)):
				kat_murmur_unit = kat_ref
			elif active_char != null and active_char.id == "katarina" and bool(active_char.get_meta("katarina_blood_murmur", false)):
				kat_murmur_unit = active_char

			if can_target_enemy and kat_murmur_unit != null:
				var locked_target: CombatUnit = kat_murmur_unit.get_meta("katarina_blood_murmur_target", null)
				if locked_target != null:
					if not locked_target.is_alive():
						var living := battle_manager.get_living_enemies()
						if not living.is_empty():
							locked_target = living[0]
							kat_murmur_unit.set_meta("katarina_blood_murmur_target", locked_target)
					if unit != locked_target:
						can_target_enemy = false
					else:
						var step: int = int(kat_murmur_unit.get_meta("katarina_blood_murmur_step", 0))
						if step == 1:
							btn.text = "🎯 Секущий удар (2/2)"
						elif step >= 2:
							btn.text = "🎯 Рвущий удар (Финал)"
			elif kat_murmur_unit == null:
				btn.text = "🎯 Выбрать целью"
							
			btn.visible = can_target_enemy
					
func _refresh_action_bar() -> void:
	for child in action_bar.get_children():
		child.queue_free()

	# Получаем список участников и их текущие AV
	var units_av_temp: Dictionary = {}
	for unit in battle_manager.get_all_units():
		if unit.is_alive():
			units_av_temp[unit] = unit.action_value

	var order := battle_manager.get_action_preview()
	var accumulated_av_simulation: float = 0.0
	
	for i in order.size():
		var unit: CombatUnit = order[i]
		if unit == null or not units_av_temp.has(unit):
			continue
			
		# Рассчитываем оставшийся ИД до хода этого юнита
		var remaining_av: float = units_av_temp[unit]
		accumulated_av_simulation += remaining_av
		
		# Симулируем ход: вычитаем remaining_av из всех участников в симуляции
		for u in units_av_temp:
			units_av_temp[u] = maxf(units_av_temp[u] - remaining_av, 0.0)
		# Сбрасываем AV сходившего юнита на полный ИД для последующих витков на шкале
		units_av_temp[unit] = unit.base_action_value

		var icon := ColorRect.new()
		# Делаем ячейки шкалы чуть шире, чтобы текст умещался
		icon.custom_minimum_size = Vector2(70, 70) 
		icon.color = _unit_color(unit)
		icon.tooltip_text = unit.display_name

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		icon.add_child(vbox)

		# Первая буква имени
		var lbl_name := Label.new()
		lbl_name.text = unit.display_name.substr(0, 1)
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_name.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl_name)

		# Оставшийся ИД до хода
		var lbl_av := Label.new()
		lbl_av.text = str(int(accumulated_av_simulation))
		lbl_av.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_av.add_theme_font_size_override("font_size", 13)
		lbl_av.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(lbl_av)

		if i == 0:
			icon.modulate = Color(1.2, 1.2, 1.0)

		action_bar.add_child(icon)

func _unit_color(unit: CombatUnit) -> Color:
	if unit.is_ally:
		if unit.id == SaraAbilities.ID:
			return Color(0.482, 0.482, 0.482, 1.0)
		if unit.id == ArseniyAbilities.ID:
			return Color(0.5, 0.7, 1.0)
		if unit.id == PusenkovAbilities.ID:
			return Color(0.2, 0.8, 0.4)
		if unit.id == KaoriAbilities.ID:
			return Color(0.482, 0.482, 0.482, 1.0)
		if unit.id == ShojiAbilities.ID:
			return Color(0.9, 0.3, 0.3) 
		if unit.id == "dasha":
			return Color(0.573, 0.36, 0.72, 1.0)
		if unit.id == "danill":
			return Color(0.9, 0.3, 0.3) 
		# НОВАЯ МЕХАНИКА: Насыщенный Квантовый (фиолетово-синий) цвет для Вики
		if unit.id == "vika":
			return Color(0.4, 0.1, 0.9)
		if unit.id == "dotseva":
			return Color(0.95, 0.8, 0.3) # Золотой цвет Мнимого элемента для Доцевой
		if unit.id == "milena":
			return Color(0.4, 0.1, 0.9)
		if unit.id == "naama": # <--- ДОБАВИТЬ ЭТО ДЛЯ НААМЫ
			return Color(0.2, 0.8, 0.4)
		if unit.id == "lenskaya":
			return Color(0.5, 0.8, 1.0)
		if unit.id == "rimes":
			return Color(0.365, 0.106, 0.627, 1.0)
		if unit.id == "isaac":
			return Color(0.2, 0.8, 0.4) # Ветряной цвет Исаака
		if unit.id == "keloist":
			return Color(1.0, 0.28, 0.2) 
		if unit.id == "musienko":
			return Color(1.0, 0.28, 0.2) 
		if unit.id == "joan":
			return Color(0.75, 0.45, 1.0)
		if unit.id == "jeff":
			return Color(0.714, 0.292, 0.767, 1.0) 
		if unit.id == "valramors":
			return Color(0.152, 0.048, 0.391, 1.0)
		if unit.id == "joan_spirit":
			return Color(0.95, 0.78, 0.22) # Сияющий золотой
		if unit.id == "isaac_admin":
			return Color(0.462, 0.581, 0.574, 1.0)
		if unit.id == "sara_admin":
			return Color(0.494, 0.433, 0.944, 1.0) 
		if unit.id == "shoji_swan":
			return Color(0.2, 0.85, 0.75, 1.0) # Бирюзово-зеленый оттенок Лебедя
		return Color(0.3, 0.5, 0.9)
	if unit.is_elite:
		return Color(0.7, 0.4, 0.9)
	match unit.element:
		CombatConstants.Element.ICE: return Color(0.4, 0.7, 1.0)
		CombatConstants.Element.FIRE: return Color(1.0, 0.4, 0.3)
		_: return Color(0.6, 0.6, 0.6)

func _on_turn_started(unit: CombatUnit) -> void:
	LevelManager.on_turn_started(unit, self)
	turn_label.text = "Цикл: %d | Ход: %s" % [battle_manager.get_current_cycles(), unit.display_name]
	
	if _target_mode != "ult":
		_selecting_target = false
		_target_mode = ""
		_set_target_buttons_visible(false, false)
		_multi_targets.clear()
		
	_refresh_action_bar()
	_refresh_graphs_panel() 

	for u in _unit_panels:
		_refresh_unit_panel(u)

	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()

	if unit.is_ally:
		action_panel.show()
		_update_action_buttons(unit)
		# ТАЛАНТ ЖОАНА: До формы духа он бьет авто-базовой по цели с максимальным ХП
		if unit.id == "joan_spirit" and not bool(unit.get_meta("joan_spirit_form", false)):
			_set_action_buttons_disabled(true)
			_on_log("[Талант: Жоан концентрируется и автоматически атакует врага с наибольшим ХП...]")
			
			_joan_auto_turn_id += 1
			var my_auto_id := _joan_auto_turn_id
			
			await get_tree().create_timer(0.6).timeout
			
			# ПРОВЕРКА ПРЕРЫВАНИЯ УЛЬТОЙ:
			# Если игрок успел прожать Ульту и Жоан вошел в Форму духа — НЕМЕДЛЕННО ОТМЕНЯЕМ АВТО-АТАКУ!
			if my_auto_id != _joan_auto_turn_id or bool(unit.get_meta("joan_spirit_form", false)) or battle_manager._is_processing_ult_queue or not battle_manager.ult_queue.is_empty():
				_on_log("[🌟 Управление Жоаном разблокировано после перехода в Форму духа!]")
				_set_action_buttons_disabled(false)
				_update_action_buttons(unit)
				return
				
			var target_enemy: CombatUnit = null
			for e in battle_manager.get_living_enemies():
				if target_enemy == null or e.stats.hp > target_enemy.stats.hp:
					target_enemy = e
			if target_enemy:
				battle_manager.player_basic_attack(target_enemy)
			return
		energy_bar.max_value = unit.max_energy
		energy_bar.value = unit.energy
		if unit.id == "joan_spirit":
			var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
			var wishes: int = int(unit.get_meta("joan_last_wish", 0))
			var title_str := "Последнее желание" if in_spirit else "ДУХ"
			energy_label.text = "%s: %d / %d" % [title_str, wishes, 8 if in_spirit else 12] # Было 10, стало 8
		else:
			energy_label.text = "ЭН: %d / %d" % [int(unit.energy), int(unit.max_energy)]
	else:
		action_panel.hide()
		if _skills_help_open:
			skills_text.text = "Ход противника: %s" % unit.display_name
			
func _update_action_buttons(unit: CombatUnit) -> void:
	btn_basic.visible = true
	btn_basic.disabled = false
	btn_enhanced_basic.visible = false
	btn_enhanced_basic.disabled = true
	btn_skill.disabled = false
	btn_skill_e.disabled = false

	var in_new_dev := unit.id == ArseniyAbilities.ID and ArseniyAbilities.is_new_development(unit)
	var q_free := unit.id == ArseniyAbilities.ID and not ArseniyAbilities.skill_q_costs_sp(unit)

	btn_skill.disabled = not q_free and battle_manager.skill_points < 1
	btn_skill_e.disabled = battle_manager.skill_points < 2
	btn_ult.disabled = true 

	btn_enhanced_basic.visible = false
	btn_enhanced_basic.disabled = true

	# ИСПРАВЛЕНО: Кнопка Навыка Е теперь всегда видна Даше, Даниллу и Вике
	btn_skill_e.visible = (
		unit.id == MarinaAbilities.ID
		or unit.id == SaraAbilities.ID
		or unit.id == ArseniyAbilities.ID
		or unit.id == PusenkovAbilities.ID
		or unit.id == KaoriAbilities.ID
		or unit.id == ShojiAbilities.ID
		or unit.id == "dasha"
		or unit.id == "danill"
		or unit.id == "vika"
		or unit.id == "dotseva" 
		or unit.id == "milena" # ДОБАВЛЕНО
		or unit.id == "naama"
		or unit.id == "lenskaya"
		or unit.id == "rimes"
		or unit.id == "isaac"
		or unit.id == "keloist"
		or unit.id == "musienko"
		or unit.id == "joan"
		or unit.id == "jeff"
		or unit.id == "valramors"
		or unit.id == "joan_spirit"
		or unit.id == "isaac_admin"
		or unit.id == "sara_admin"
		or unit.id == "arseniy_admin"
		or unit.id == "shoji_swan"
		or unit.id == "katarina"
		or unit.id == "dotseva_crimson_tears"
	)

	match unit.id:
		SaraAbilities.ID:
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
		ArseniyAbilities.ID:
			btn_basic.text = "⚔ Базовая (60%)"
			btn_enhanced_basic.visible = in_new_dev
			btn_enhanced_basic.disabled = battle_manager.skill_points < 1
			if in_new_dev:
				btn_skill.text = "🔷 Усил. Q (1 ОН)"
			elif q_free:
				btn_skill.text = "🔷 Q — 3 врага (беспл.)"
			else:
				btn_skill.text = "🔷 Q (1 ОН) — 3 врага"
			btn_skill_e.text = "🔹 E (2 ОН) — Нов. разраб."
		MarinaAbilities.ID:
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
		PusenkovAbilities.ID:
			var counter: int = int(unit.get_meta("basic_counter", 0))
			if counter >= 3:
				btn_basic.text = "⚔ Усил. Базовая (310%)"
			else:
				btn_basic.text = "⚔ Базовая %d/3" % [counter + 1]
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
		KaoriAbilities.ID:
			var conc: bool = unit.get_meta("weakness_concentration", false)
			
			if conc:
				btn_basic.text = "⚔ Усил. Базовая"
			else:
				btn_basic.text = "⚔ Базовая"
				
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
			btn_skill_e.disabled = battle_manager.skill_points < 2
			
			var shuriken_target = null
			if unit.has_meta("e_shuriken_target"):
				shuriken_target = unit.get_meta("e_shuriken_target")
				
			if shuriken_target and shuriken_target.is_alive():
				btn_skill_e.text = "🔹 Усил. Навык E (0 ОН)"
				btn_skill_e.disabled = false 
		ShojiAbilities.ID:
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (1 ОН)"
			btn_skill_e.disabled = battle_manager.skill_points < 1
		"dasha":
			var in_dance: bool = unit.get_meta("circle_dance", false)
			var in_overload: bool = int(unit.get_meta("overload_turns", 0)) > 0
			
			if in_dance:
				btn_basic.text = "⚔ Усил. Базовая"
			else:
				btn_basic.text = "⚔ Базовая"
				
			var q_cost := " (0 ОН)" if in_overload else " (1 ОН)"
			btn_skill.text = "🔷 Навык Q" + q_cost if in_dance else "🔒 Навык Q (Нужен Танец)"
			btn_skill.disabled = not in_dance or (not in_overload and battle_manager.skill_points < 1)
			
			if in_dance:
				btn_skill_e.text = "🔒 Навык E (Активен)"
				btn_skill_e.disabled = true
			else:
				btn_skill_e.text = "🔹 Навык E (2 ОН)"
				btn_skill_e.disabled = battle_manager.skill_points < 2
		"danill":
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		# НОВАЯ МЕХАНИКА: Настройка подписей кнопок действий Вики
		"vika":
			btn_basic.text = "⚔ Базовая (50% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН)"
			btn_skill_e.text = "🔹 Навык E (2 ОН)"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"dotseva":
			var in_fog := int(unit.get_meta("dotseva_fog_turns", 0)) > 0
			var stacks := int(unit.get_meta("dotseva_calibration_stacks", 0))
			
			if in_fog:
				btn_basic.text = "⚔ Усил. Базовая (Калибр.)"
				btn_skill.text = "🔷 Усил. Q (1 ОН)"
				btn_skill.disabled = battle_manager.skill_points < 1
				
				if unit.eidolon >= 6:
					btn_skill_e.text = "🔹 Е6 Навык E (1 ОН)"
				else:
					btn_skill_e.text = "🔹 Усил. Навык E (1 ОН)"
				btn_skill_e.disabled = battle_manager.skill_points < 1
			else:
				btn_basic.text = "⚔ Базовая (110% СА)"
				btn_skill.text = "🔷 Навык Q (1 ОН) — Сплэш"
				btn_skill.disabled = battle_manager.skill_points < 1
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Калибр."
				btn_skill_e.disabled = battle_manager.skill_points < 2
		"milena":
			btn_basic.text = "⚔ Базовая (Срез защиты)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — Слияние"
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Обертон"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"naama": # <--- ДОБАВИТЬ ЭТО ДЛЯ НААМЫ (включая проверку бесплатного E4)
			btn_basic.text = "⚔ Базовая (80% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — Сплэш"
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Слабость"
			if unit.get_meta("naama_e4_free_skill", false):
				btn_skill_e.text = "🔹 Навык E (0 ОН) [БЕСПЛАТНО]"
				btn_skill_e.disabled = false
			else:
				btn_skill_e.disabled = battle_manager.skill_points < 2
		"lenskaya": # <--- ДОБАВИТЬ ЭТО ДЛЯ ЛЕНСКОЙ (смена текста в Жале и расход 1 ОН)
			var in_stinger: bool = int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0
			if in_stinger:
				btn_basic.text = "⚔ Усил. Базовая (Сплэш)"
				btn_skill.text = "🔷 Усил. Навык Q (1 ОН)"
			else:
				btn_basic.text = "⚔ Базовая (110% СА)"
				btn_skill.text = "🔷 Навык Q (1 ОН) — АоЕ"
				
			btn_skill_e.text = "🔹 Навык E (1 ОН) — Взрыв"
			btn_skill.disabled = battle_manager.skill_points < 1
			btn_skill_e.disabled = battle_manager.skill_points < 1
		"rimes":
			var in_isolation := unit.has_meta("rimes_isolation_target")
			var is_enhanced_basic := in_isolation or unit.eidolon >= 4
			
			if is_enhanced_basic:
				btn_basic.text = "⚔ Усил. Базовая (270% СА)"
			else:
				btn_basic.text = "⚔ Базовая (160% СА)"
				
			if in_isolation:
				btn_skill.text = "🔷 Усил. Q (1 ОН) — Дебафф"
			else:
				btn_skill.text = "🔷 Навык Q (1 ОН) — Казнь"
				
			var other_allies_alive := false
			for ally in battle_manager.allies:
				if ally.is_alive() and ally != unit:
					other_allies_alive = true
					break
				
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Изоляция"
			btn_skill.disabled = battle_manager.skill_points < 1
			btn_skill_e.disabled = battle_manager.skill_points < 2
			
			if in_isolation:
				btn_skill_e.text = "🔒 Изоляция (Активна)"
				btn_skill_e.disabled = true
			if other_allies_alive == false:
				btn_skill_e.text = "🔒 Изоляция (Недоступно)"
				btn_skill_e.disabled = true
		"isaac":
			var stacks := int(unit.get_meta("isaac_theory_stacks", 0))
			var has_enhanced_q := stacks >= 8
			
			if has_enhanced_q:
				var sp_cost_q := " (0 ОН)" if unit.eidolon >= 2 else " (1 ОН)"
				btn_basic.text = "⚔ Базовая (80% СА)"
				btn_skill.text = "🔷 Усил. Q" + sp_cost_q
				btn_skill.disabled = not (unit.eidolon >= 2 or battle_manager.skill_points >= 1)
			else:
				btn_basic.text = "⚔ Базовая (80% СА)"
				btn_skill.text = "🔷 Навык Q (1 ОН) — АоЕ"
				btn_skill.disabled = battle_manager.skill_points < 1
				
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Криты"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"keloist":
			btn_basic.text = "⚔ Базовая (90% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — АоЕ"
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Ортощит"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			# Проверка наличия живых напарников для кнопки E
			var other_allies_alive := false
			for ally in battle_manager.allies:
				if ally.is_alive() and ally != unit:
					other_allies_alive = true
					break
			btn_skill_e.disabled = battle_manager.skill_points < 2 or not other_allies_alive
		"musienko":
			var in_anni := unit.has_meta("musienko_annihilation_active")
			btn_basic.text = "⚔ Усил. Базовая (ХП)" if in_anni else "⚔ Базовая (120% ХП)"
			
			if in_anni:
				btn_skill.text = "🔷 Усил. Q (1 ОН) — Срез"
				btn_skill_e.text = "🔒 Навык E (Блокирован)"
				btn_skill_e.disabled = true
			else:
				btn_skill.text = "🔷 Навык Q (1 ОН)"
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Аннигил."
				btn_skill_e.disabled = battle_manager.skill_points < 2
		"joan": # ДОБАВЛЕНО: Подписи для кнопок действий Жоана
			btn_basic.text = "⚔ Базовая (100% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — Одиночная атака"
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Ослабление"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"jeff":
			btn_basic.text = "⚔ Базовая (100% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — Восстановление"
			btn_skill_e.text = "🔹 Навык E (2 ОН) — Ослабление"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"valramors":
			var e6_active := unit.eidolon >= 6
			btn_basic.text = "⚔ Базовая (120% СА)"
			btn_skill.text = "🔷 Навык Q (1 ОН) — " + ("АоЕ Срез" if e6_active else "Срез защиты")
			btn_skill_e.text = "🔹 Навык E (1 ОН) — Порча"
			btn_skill_e.disabled = battle_manager.skill_points < 1
		"joan_spirit":
			var in_spirit: bool = bool(unit.get_meta("joan_spirit_form", false))
			var regrets: int = int(unit.get_meta("joan_regret", 0))
			var e_cost: int = 3 if unit.eidolon >= 1 else 4
			
			if in_spirit:
				# Базовая атака полностью исчезает
				btn_basic.visible = false
				btn_basic.disabled = true
				
				# Открыта усиленная базовая атака с надписью +2 Сожал.
				btn_enhanced_basic.visible = true
				btn_enhanced_basic.disabled = false
				btn_enhanced_basic.text = "⚔ Усил. Базовая (+2 Сожал.)"
				
				btn_skill.text = "🔷 Навык Q (0 ОН)"
				btn_skill.disabled = false
				
				btn_skill_e.text = "🔹 Навык E (%d Сожал.)" % e_cost
				btn_skill_e.disabled = regrets < e_cost
			else:
				# До формы духа базовая видна как авто-ход
				btn_basic.visible = true
				btn_basic.text = "🔒 Авто-ход (Талант)"
				btn_basic.disabled = true
				btn_enhanced_basic.visible = false
				
				btn_skill.text = "🔒 Навык Q (Нужна Форма духа)"
				btn_skill.disabled = true
				btn_skill_e.text = "🔒 Навык E (Нужна Форма духа)"
				btn_skill_e.disabled = true
		"isaac_admin":
			var in_hacked := int(unit.get_meta("isaac_hacked_turns", 0)) > 0
			var vectors: int = battle_manager.get_console_vectors()
			var e_unlocked: bool = bool(unit.get_meta("isaac_admin_e_unlocked", false)) or vectors >= 50
			
			if in_hacked:
				btn_basic.visible = false
				btn_enhanced_basic.visible = true
				btn_enhanced_basic.disabled = false
				btn_enhanced_basic.text = "⚔ Бинарная Базовая"
				btn_skill.text = "🔷 Усил. Q (1 ОН) — Бинарн."
			else:
				btn_basic.visible = true
				btn_basic.disabled = false
				btn_basic.text = "⚔ Базовая (100% СА)"
				btn_enhanced_basic.visible = false
				btn_skill.text = "🔷 Навык Q (1 ОН) — Векторы"
				
			btn_skill.disabled = battle_manager.skill_points < 1
			
			# ИСПРАВЛЕНО: Кнопка Навыка Е гарантированно видна!
			btn_skill_e.visible = true
			if e_unlocked:
				btn_skill_e.text = "🔹 Навык E (1 ОН)"
				btn_skill_e.disabled = battle_manager.skill_points < 1
			else:
				btn_skill_e.text = "🔒 Навык E (50 Векторов)"
				btn_skill_e.disabled = true
		"sara_admin":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "⚔ Базовая (Физ. 70% СА)"
			btn_enhanced_basic.visible = false
			
			btn_skill.text = "🔷 Навык Q (1 ОН) — Зона"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			var vectors := battle_manager.get_console_vectors()
			# ИСПРАВЛЕНО: Навык Е разблокируется навсегда, ориентируясь на маркер!
			var e_unlocked: bool = bool(unit.get_meta("sara_admin_e_unlocked", false)) or vectors >= 30
			
			btn_skill_e.visible = true
			if e_unlocked:
				btn_skill_e.text = "🔹 Навык E (1 ОН) — Бинарн."
				btn_skill_e.disabled = battle_manager.skill_points < 1
			else:
				btn_skill_e.text = "🔒 Навык E (30 Векторов)"
				btn_skill_e.disabled = true
		"arseniy_admin":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "⚔ Базовая (Квант. 70% СА)"
			btn_enhanced_basic.visible = false
			
			btn_skill.text = "🔷 Навык Q (1 ОН) — Срез ЗАЩ"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			var vectors := battle_manager.get_console_vectors()
			var e_unlocked: bool = bool(unit.get_meta("arseniy_admin_e_unlocked", false)) or vectors >= 40
			
			btn_skill_e.visible = true
			if e_unlocked:
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Бинарн."
				btn_skill_e.disabled = battle_manager.skill_points < 2
			else:
				btn_skill_e.text = "🔒 Навык E (40 Векторов)"
				btn_skill_e.disabled = true
		"dasha_admin":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "⚔ Базовая (Защита 50%)"
			btn_enhanced_basic.visible = false
			
			btn_skill.text = "🔷 Навык Q (1 ОН) — Сброс"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			var vectors := battle_manager.get_console_vectors()
			var e_unlocked: bool = bool(unit.get_meta("dasha_admin_e_unlocked", false)) or vectors >= 80
			
			btn_skill_e.visible = true
			if e_unlocked:
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Щит"
				btn_skill_e.disabled = battle_manager.skill_points < 2
			else:
				btn_skill_e.text = "🔒 Навык E (80 Векторов)"
				btn_skill_e.disabled = true
		"shoji_swan":
			var stance: String = battle_manager.get_shoji_swan_stance()
			var is_enhanced: bool = bool(unit.get_meta("shoji_swan_enhanced_basic", false))
			var vectors: int = battle_manager.get_console_vectors()
			var e_unlocked: bool = bool(unit.get_meta("shoji_swan_e_unlocked", false)) or vectors >= 20
			var q_cd: int = int(unit.get_meta("shoji_swan_q_cooldown_turns", 0))

			if is_enhanced:
				btn_basic.visible = false
				btn_enhanced_basic.visible = true
				btn_enhanced_basic.disabled = false
				btn_enhanced_basic.text = "⚔ Усил. Базовая (130%/40%)"
			else:
				btn_basic.visible = true
				btn_basic.disabled = false
				btn_basic.text = "⚔ Базовая (100% СА)"
				btn_enhanced_basic.visible = false

			if stance == "virus":
				btn_skill.text = "🔷 Навык Q (1 ОН) — Взрыв"
				btn_skill.disabled = battle_manager.skill_points < 1
			else:
				if q_cd > 0:
					btn_skill.text = "🔒 Навык Q (Перезарядка: %d)" % q_cd
					btn_skill.disabled = true
				else:
					btn_skill.text = "🔷 Навык Q (1 ОН) — Задержка"
					btn_skill.disabled = battle_manager.skill_points < 1

			btn_skill_e.visible = true
			if e_unlocked:
				btn_skill_e.text = "🔹 Навык E (1 ОН) — Детонация"
				btn_skill_e.disabled = battle_manager.skill_points < 1
			else:
				btn_skill_e.text = "🔒 Навык E (20 Векторов)"
				btn_skill_e.disabled = true
		"katarina":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "⚔ Базовая (90% СА)"
			btn_enhanced_basic.visible = false
			btn_skill.text = "🔷 Навык Q (1 ОН) — Физ. Уязв."
			btn_skill.disabled = battle_manager.skill_points < 1
			var mem_turns := int(unit.get_meta("katarina_just_a_memory_turns", 0))
			if mem_turns > 0:
				btn_skill_e.text = "🔹 Воспоминание (%d)" % mem_turns
			else:
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Иммунитет"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"dotseva_crimson_tears":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "⚔ Базовая (80% СА)"
			btn_enhanced_basic.visible = false
			var zone_active: bool = bool(unit.get_meta("doceva_tears_zone_active", false))
			if zone_active:
				btn_skill.text = "🔷 Усил. Q (0 ОН) — Взрыв"
				btn_skill.disabled = false
			else:
				btn_skill.text = "🔷 Навык Q (1 ОН) — AoE"
				btn_skill.disabled = battle_manager.skill_points < 1
			if zone_active:
				var z_turns: int = int(unit.get_meta("doceva_tears_zone_turns", 0))
				btn_skill_e.text = "🔹 Зона активна (%d)" % z_turns
			else:
				btn_skill_e.text = "🔹 Навык E (2 ОН) — Зона"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		_:
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q"
			btn_skill_e.text = "🔹 Навык E"

func _on_turn_ended(_unit: CombatUnit) -> void:
	_multi_targets.clear()
	_set_target_buttons_visible(false, false)
	for u in _unit_panels:
		_refresh_unit_panel(u)
	_refresh_action_bar()
	_refresh_graphs_panel()
	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()

func _on_sp_changed(points: int) -> void:
	skill_points_label.text = "ОН: %d / %d" % [points, CombatConstants.MAX_SKILL_POINTS]
	if battle_manager.current_unit and battle_manager.current_unit.is_ally:
		_update_action_buttons(battle_manager.current_unit)

func _on_arya_changed(active: bool, remaining: float) -> void:
	if active:
		arya_label.show()
		arya_label.text = "Аря: %.0f ИД (смерть заблокирована)" % remaining
	else:
		arya_label.hide()

func _on_log(message: String) -> void:
	log_list.append_text(message + "\n")

func _on_basic_pressed() -> void:
	LevelManager.on_action_pressed("basic", self)
	_target_mode = "basic"
	_selecting_target = true
	_set_target_buttons_visible(true, false)
	_on_log("[Выберите противника для базовой атаки]")

func _on_enhanced_basic_pressed() -> void:
	LevelManager.on_action_pressed("enhanced_basic", self)
	if battle_manager.current_unit.id == "joan_spirit":
		battle_manager.set_meta("joan_spirit_enhanced_basic_selected", true)
		_target_mode = "basic"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите врага для Усиленной базовой атаки (нанесет урон и соседям)]")
		return
	if battle_manager.current_unit.id == "isaac_admin":
		_target_mode = "enhanced_basic"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Усиленной Бинарной базовой атаки]")
		return
	if battle_manager.current_unit.id == "shoji_swan":
		_target_mode = "enhanced_basic"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Усиленной базовой атаки Сёдзи (соседи получат 40% СА)]")
		return
	_target_mode = "enhanced_basic"
	_selecting_target = true
	_set_target_buttons_visible(true, false)
	_on_log("[Выберите противника для услиленной атаки]")

func _on_skill_pressed() -> void:
	LevelManager.on_action_pressed("skill_q", self)
	var unit := battle_manager.current_unit
	if unit == null:
		return

	if unit.id == SaraAbilities.ID:
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для лечения]")
	elif unit.id == ArseniyAbilities.ID and ArseniyAbilities.is_new_development(unit):
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для услиления]")
	elif unit.id == ArseniyAbilities.ID:
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для атаки Q (соседи получат урон автоматически)]")
	elif unit.id == PusenkovAbilities.ID:
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника, чтобы пометить Приоритетной Целью]")
	elif unit.id == KaoriAbilities.ID:
		battle_manager.player_skill(null)
	elif unit.id == ShojiAbilities.ID:
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для взрыва DoT (Навык Q)]")
	elif unit.id == "dasha":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q и Суперпробития]")
	elif unit.id == "danill":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для наложения Щита (Навык Q)]")
	# НОВАЯ МЕХАНИКА: Навык Q Вики бьет по сплэш-зоне и требует выбора цели
	elif unit.id == "vika":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q]")
	elif unit.id == "dotseva":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q]")
	elif unit.id == "dotseva":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q]")
	elif unit.id == "naama": # <--- ДОБАВИТЬ ЭТО ДЛЯ НААМЫ
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для Навыка Q Наамы]")
	elif unit.id == "lenskaya": # <--- ДОБАВИТЬ ЭТО ДЛЯ ЛЕНСКОЙ
		var in_stinger: bool = int(unit.get_meta("lenskaya_stinger_turns", 0)) > 0
		if in_stinger:
			_target_mode = "skill"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[Выберите цель для наложения Награды за голову Навыком Q Ленской]")
		else:
			# Обычный Q бьет всех без выбора цели
			battle_manager.player_skill(null)
	elif unit.id == "rimes": # <--- ДОБАВИТЬ ЭТО ДЛЯ РАЙМСА!
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для Навыка Q Раймса]")
	elif unit.id == "isaac":
		var stacks := int(unit.get_meta("isaac_theory_stacks", 0))
		if stacks >= 8:
			_target_mode = "skill"
			_selecting_target = true
			_set_target_buttons_visible(false, true) # Целимся в союзников!
			_on_log("[Выберите союзника для продвижения действия Усиленным Навыком Q]")
		else:
			# Обычный Q бьет всех врагов сразу
			battle_manager.player_skill(null)
	elif unit.id == "musienko":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для Навыка Q Мусиенко]")
	elif unit.id == "joan": # ДОБАВЛЕНО: Прицеливание Q Жоана
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q Жоана (вызовет Бонус-атаку)]")
	elif unit.id == "jeff":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("Выбранный союзник и 2 окружающих его союзника восстановят здоровье")
	elif unit.id == "valramors":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q Валраморса]")
	elif unit.id == "joan_spirit":
		battle_manager.player_skill(null) # АоЕ удар, сразу кастует без выбора цели
	elif unit.id == "isaac_admin":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите врага для Навыка Q Айзека]")
	elif unit.id == "sara_admin":
		battle_manager.player_skill(null) # Зона открывается сразу без выбора цели
	elif unit.id == "arseniy_admin":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите врага для Навыка Q (срез защиты)]")
	elif unit.id == "dasha_admin":
		battle_manager.player_skill(null)
	elif unit.id == "shoji_swan":
		var stance := battle_manager.get_shoji_swan_stance()
		if stance == "virus":
			_target_mode = "skill"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[Выберите врага для Навыка Q (соседи получат урон автоматически)]")
		else:
			# Режим «Танец» задерживает всех врагов сразу
			battle_manager.player_skill(null)
	elif unit.id == "katarina":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите врага для Навыка Q Катарины]")
	elif unit.id == "dotseva_crimson_tears":
		var zone_active: bool = bool(unit.get_meta("doceva_tears_zone_active", false))
		if zone_active:
			_target_mode = "skill"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[Выберите главную цель для Улучшенного Навыка Q Доцевой]")
		else:
			battle_manager.player_skill(null)
	else:
		battle_manager.player_skill(null)

func _confirm_multi_skill() -> void:
	var living := battle_manager.get_living_enemies()
	var required := mini(3, living.size())
	if _multi_targets.size() < required:
		_on_log("[Нужно выбрать %d враг(ов)]" % required)
		return
	_selecting_target = false
	_set_target_buttons_visible(false, false)
	battle_manager.player_skill(null, _multi_targets)
	_multi_targets.clear()
	_target_mode = ""

func _on_skill_e_pressed() -> void:
	LevelManager.on_action_pressed("skill_e", self)
	var unit := battle_manager.current_unit
	if unit == null:
		return
	if unit.id == SaraAbilities.ID:
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для поддержки]")
	elif unit.id == PusenkovAbilities.ID or unit.id == KaoriAbilities.ID or unit.id == ShojiAbilities.ID:
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для атаки]")
	elif unit.id == "dotseva" and int(unit.get_meta("dotseva_fog_turns", 0)) > 0:
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E]")
	elif unit.id == "dotseva" and int(unit.get_meta("dotseva_fog_turns", 0)) > 0:
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E]")
	elif unit.id == "lenskaya": # <--- ДОБАВИТЬ ЭТО ДЛЯ ЛЕНСКОЙ
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для взрыва Манипуляции Навыком Е]")
	elif unit.id == "rimes": # <--- ДОБАВИТЬ ЭТО ДЛЯ РАЙМСА!
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для наложения Вечной Изоляции Навыком E]")
	elif unit.id == "isaac":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false) # Целимся во врагов!
		_on_log("[Выберите противника для атаки и дебаффа КУ]")
	elif unit.id == "keloist":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(false, true) # Целимся в союзников!
		_on_log("[Выберите союзника для наложения Ортощита]")
	elif unit.id == "joan": # ДОБАВЛЕНО: Прицеливание Е Жоана
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E Жоана (продвинет его и наложит уязвимость)]")
	elif unit.id == "jeff": 
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E Джеффа]")
	elif unit.id == "valramors":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(false, true) # Наводится только на союзников!
		_on_log("[Выберите союзника для Передачи порчи Навыком E]")
	elif unit.id == "joan_spirit":
		battle_manager.player_skill_e(null) # АоЕ удар с дополнительными отскоками
	elif unit.id == "isaac_admin":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E Айзека]")
	elif unit.id == "sara_admin":
		battle_manager.player_skill_e(null) # АоЕ удар по всем врагам
	elif unit.id == "arseniy_admin":
		battle_manager.player_skill_e(null) # АоЕ удар по всем врагам (Навык E)
	elif unit.id == "dasha_admin":
		battle_manager.player_skill_e(null)
	elif unit.id == "shoji_swan":
		battle_manager.player_skill_e(null) # АоЕ удар по всем врагам и подрыв DoT
	elif unit.id == "katarina":
		battle_manager.player_skill_e(null)
	elif unit.id == "dotseva_crimson_tears":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для защиты Зоны Доцевой]")
	else:
		battle_manager.player_skill_e(null)

func _on_ult_pressed() -> void:
	pass

func _on_card_ult_pressed(unit: CombatUnit) -> void:
	if unit in battle_manager.ult_queue:
		return
	LevelManager.on_action_pressed("ult_card", self)
	if battle_manager.phase != battle_manager.Phase.RUNNING:
		return
	if unit.statuses.skip_next_turn:
		_on_log("[%s заморожен и не может ультовать!]" % unit.display_name)
		return
	
	if unit.id == "joan_spirit":
		_joan_auto_turn_id += 1
		
	# ИСПРАВЛЕНО: Добавлен ID Вики в список ультимейтов, требующих выбора цели на поле боя
	var requires_target := (
		unit.id == ArseniyAbilities.ID 
		or unit.id == PusenkovAbilities.ID 
		or unit.id == KaoriAbilities.ID 
		or unit.id == ShojiAbilities.ID
		or unit.id == "vika"
		or unit.id == "rimes"
		or unit.id == "isaac"
		or unit.id == "musienko"
		or unit.id == "joan"
		or unit.id == "valramors"
		or unit.id == "katarina"
	)
	
	if requires_target:
		_original_active_unit = battle_manager.current_unit
		
		battle_manager.current_unit = unit
		_target_mode = "ult"
		_selecting_target = true
		
		# ИСПРАВЛЕНО: Открываем кнопки выбора на союзниках, если ультует Айзек
		var targets_allies_ult := (unit.id == "isaac")
		_set_target_buttons_visible(not targets_allies_ult, targets_allies_ult)
		
		_set_action_buttons_disabled(true) 
		battle_manager.set_meta("is_selecting_ult_target", true)
		
		_on_log("[Выберите %s для Сверхспособности %s]" % ["союзника" if targets_allies_ult else "противника", unit.display_name])
	else:
		battle_manager.queue_ultimate(unit)
		for u in _unit_panels:
			_refresh_unit_panel(u)

func _on_target_pressed(unit: CombatUnit, is_ally: bool) -> void:
	if _selecting_target:
		if not unit.is_alive():
			return
		match _target_mode:
			"basic", "enhanced_basic":
				if is_ally:
						return
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				
				# Оповещаем обучение про клик
				if LevelManager.is_tutorial and LevelManager.current_level_id == "level_1" and LevelManager.tut_step == 3:
					battle_manager.set_meta("is_selecting_ult_target", true)
					LevelManager.on_action_pressed("basic_target_selected", self)
				
				if _target_mode == "basic":
					battle_manager.player_basic_attack(unit)
				else:
					battle_manager.player_enhanced_basic(unit)
				_target_mode = ""
			# Внутри _on_target_pressed() -> match _target_mode:
			"ult":
				var ult_user := battle_manager.current_unit
				var targets_allies_ult := (ult_user != null and ult_user.id == "isaac")
				
				# ИСПРАВЛЕНО: Проверяем валидность цели с учетом союза/врага для ульты Айзека
				if targets_allies_ult:
					if not is_ally:
						return
				else:
					if is_ally:
						return

				if ult_user != null and ult_user.id == "katarina":
					_handle_katarina_ult_target_press(ult_user, unit)
					return
						
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				
				if ult_user:
					ult_user.set_meta("ult_target", unit)
					if not battle_manager._is_processing_ult_queue:
						battle_manager.queue_ultimate(ult_user)
					
				battle_manager.set_meta("is_selecting_ult_target", false)
					
				if _original_active_unit:
					battle_manager.current_unit = _original_active_unit
					_original_active_unit = null
					_update_action_buttons(battle_manager.current_unit)
				_target_mode = ""
			"skill", "skill_e":
				var current_char_id := battle_manager.current_unit.id
				var targets_allies := (
					current_char_id == SaraAbilities.ID 
					or (current_char_id == ArseniyAbilities.ID and ArseniyAbilities.is_new_development(battle_manager.current_unit))
					or (current_char_id == "danill" and _target_mode == "skill") 
					or (current_char_id == "isaac" and _target_mode == "ult") # <--- ДОБАВИТЬ ЭТО
					or (current_char_id == "isaac" and _target_mode == "skill" and int(battle_manager.current_unit.get_meta("isaac_theory_stacks", 0)) >= 8) # <--- ДОБАВИТЬ ЭТО
					or (current_char_id == "keloist" and _target_mode == "skill_e")
					or (current_char_id == "jeff" and _target_mode == "skill")
					or (current_char_id == "valramors" and _target_mode == "skill_e")
					or (current_char_id == "dotseva_crimson_tears" and _target_mode == "skill_e")
				)
				
				if targets_allies:
					if not is_ally:
						return
				else:
					if is_ally:
						return
						
				
						
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				if _target_mode == "skill":
					# Сообщаем обучающему менеджеру о выборе цели для Навыка Q
					LevelManager.on_action_pressed("skill_q_target_selected", self)
					battle_manager.player_skill(unit)
				else:
					LevelManager.on_action_pressed("skill_e_target_selected", self)
					battle_manager.player_skill_e(unit)
				_target_mode = ""
				if _target_mode == "skill":
					battle_manager.player_skill(unit)
				else:
					battle_manager.player_skill_e(unit)
				_target_mode = ""
			"skill_q_multi":
				if is_ally:
					return
				if unit in _multi_targets:
					var idx := _multi_targets.find(unit)
					if idx >= 0:
						_multi_targets.remove_at(idx)
				elif _multi_targets.size() < 3:
					_multi_targets.append(unit)
				_refresh_unit_panel(unit)
				_on_log("[Выбрано %d/3 — нажмите Q]" % _multi_targets.size())
		return

func _on_battle_ended(victory: bool) -> void:
	action_panel.hide()
	skills_panel.hide()
	graphs_panel.hide()
	_close_inspect()
	_set_target_buttons_visible(false, false)
	result_panel.show()
	result_panel.move_to_front()
	result_label.text = "Победа!" if victory else "Поражение"
	LevelManager.on_battle_ended(victory, battle_manager)

func _on_return_pressed() -> void:
	_return_to_previous_screen()

func _set_action_buttons_disabled(disabled: bool) -> void:
	btn_basic.disabled = disabled
	btn_enhanced_basic.disabled = disabled
	btn_skill.disabled = disabled
	btn_skill_e.disabled = disabled
	
func _on_combat_text_spawned(unit: CombatUnit, text: String, color: Color, tag: String, is_crit: bool) -> void:
	if not _unit_panels.has(unit):
		return
	
	var panel: PanelContainer = _unit_panels[unit]
	var secondary_color := Color.TRANSPARENT
	var display_tag := tag
	
	# ИСПРАВЛЕНО: Для Бинарного урона формируем бирюзовую неоновую ауру и перелив
	if tag == "Binary" or tag == "Бинарный" or tag == "BinaryGroup":
		var elem_color := color # Родной цвет стихии (серый физ.)
		var turquoise := Color(0.506, 0.945, 0.873, 1.0) # Яркий бинарный бирюзовый
		color = elem_color
		secondary_color = turquoise
		display_tag = "01 БИНАРНЫЙ"
	
	var fct := FloatingText.new(text, color, 25, display_tag, is_crit, secondary_color)
	add_child(fct)
	
	var panel_rect := panel.get_global_rect()
	var center_pos := panel_rect.position + panel_rect.size * 0.5
	var random_offset := Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
	fct.global_position = center_pos + random_offset - fct.custom_minimum_size * 0.5
	
class FloatingText extends Control:
	var vbox: VBoxContainer
	var label: Label
	var tag_label: Label
	var drift_duration: float = 2.0
	var elem_color: Color
	var sheen_color: Color
	var has_sheen: bool = false

	func _init(text: String, text_color: Color, font_size: int, tag: String = "", is_crit: bool = false, secondary_color: Color = Color.TRANSPARENT) -> void:
		custom_minimum_size = Vector2(250, 85)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		elem_color = text_color
		sheen_color = secondary_color
		has_sheen = (secondary_color != Color.TRANSPARENT)
		
		vbox = VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 0)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vbox)
		
		if tag != "":
			tag_label = Label.new()
			tag_label.text = tag
			tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var tag_c := secondary_color if has_sheen else text_color
			tag_label.add_theme_color_override("font_color", tag_c)
			tag_label.add_theme_font_size_override("font_size", int(font_size * 0.65))
			tag_label.add_theme_color_override("font_outline_color", Color.BLACK)
			tag_label.add_theme_constant_override("outline_size", 4)
			tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(tag_label)
			
		label = Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_font_size_override("font_size", font_size)
		
		# ИСПРАВЛЕНО: Тонкая аккуратная обводка (3 px базово, 4 px при Крите)
		var outline_c := Color(0.10, 0.82, 0.74, 0.90) if has_sheen else Color.BLACK
		var base_outline_size := 1 if has_sheen else 3
		label.add_theme_color_override("font_outline_color", outline_c)
		label.add_theme_constant_override("outline_size", base_outline_size)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_crit:
			label.add_theme_font_size_override("font_size", int(font_size * 1.35))
			label.add_theme_constant_override("outline_size", base_outline_size + 1)
			
		vbox.add_child(label)

	func _ready() -> void:
		var tween := create_tween().set_parallel(true)
		
		tween.tween_property(self, "global_position:y", global_position.y - 28.0, drift_duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
		scale = Vector2(0.4, 0.4)
		pivot_offset = custom_minimum_size * 0.5
		var scale_tween := create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
		
		# ИСПРАВЛЕНО: Анимация цвета через tween_method с вызовом add_theme_color_override!
		if has_sheen:
			var sheen_tween := create_tween().set_loops()
			sheen_tween.tween_method(func(c: Color): label.add_theme_color_override("font_color", c), elem_color, sheen_color, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			sheen_tween.tween_method(func(c: Color): label.add_theme_color_override("font_color", c), sheen_color, elem_color, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var fade_tween := create_tween()
		fade_tween.tween_interval(1.1)
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_LINEAR)
		
		tween.chain().tween_callback(queue_free)
		
# Процедурная генерация мягкого золотого фона, солнечных лучей и блёсток
# Процедурная генерация мягкого золотого фона, солнечных лучей и блёсток
func _init_spirit_form_vfx() -> void:
	_spirit_vfx_container = Control.new()
	_spirit_vfx_container.name = "SpiritFormVFX"
	_spirit_vfx_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spirit_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spirit_vfx_container.modulate.a = 0.0
	_spirit_vfx_container.visible = false
	
	add_child(_spirit_vfx_container)
	if allies_container:
		move_child(_spirit_vfx_container, allies_container.get_index())
	
	# 1. Тёплая золотисто-янтарная подложка
	var bg_tint := ColorRect.new()
	bg_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tint.color = Color(0.40, 0.28, 0.06, 0.40)
	bg_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spirit_vfx_container.add_child(bg_tint)
	
	# Материал аддитивного свечения
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# 2. Мягкие пробивающиеся солнечные лучи
	var sun_rays := TextureRect.new()
	sun_rays.name = "SunRays"
	sun_rays.material = add_mat
	sun_rays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sun_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sun_rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.55, 0.42, 0.12, 0.70),
		Color(0.35, 0.25, 0.05, 0.25),
		Color(0.0, 0.0, 0.0, 0.0)
	])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	sun_rays.texture = grad_tex
	_spirit_vfx_container.add_child(sun_rays)
	
	var sun_tween := create_tween().set_loops()
	sun_tween.tween_property(sun_rays, "modulate:a", 0.60, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sun_tween.tween_property(sun_rays, "modulate:a", 1.0, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 3. ИСПРАВЛЕНО: Золотые блёстки падают СВЕРХУ ВНИЗ по ВСЕЙ ширине экрана
	var vp_size := get_viewport_rect().size
	if vp_size.x < 100: vp_size = Vector2(1920, 1080)
	
	var particles := CPUParticles2D.new()
	particles.name = "GoldenSparkles"
	particles.material = add_mat
	particles.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.5)
	particles.amount = 40
	particles.lifetime = 5.5 # Дольше и медленнее
	particles.preprocess = 2.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(maxf(vp_size.x, 1920.0) * 0.5 + 50.0, maxf(vp_size.y, 1080.0) * 0.5 + 50.0)
	
	# Движение строго сверху вниз
	particles.direction = Vector2(0, 1)
	particles.spread = 20.0
	particles.gravity = Vector2(0, 10.0)
	particles.initial_velocity_min = 18.0
	particles.initial_velocity_max = 36.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.5
	
	# ИСПРАВЛЕНО: Градиент плавного появления и медленного растворения блёсток (Fade In & Out)
	var p_grad := Gradient.new()
	p_grad.colors = PackedColorArray([
		Color(1.0, 0.90, 0.45, 0.0),   # Рождается из невидимости вверху
		Color(1.0, 0.90, 0.45, 0.65),  # Плавно загорается
		Color(1.0, 0.85, 0.40, 0.60),  # Светится во время падения
		Color(1.0, 0.75, 0.20, 0.0)    # Мягко и медленно тает внизу
	])
	p_grad.offsets = PackedFloat32Array([0.0, 0.15, 0.70, 1.0])
	particles.color_ramp = p_grad
	
	# Круглая мягкая текстура без резких пикселей
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var center := Vector2(8, 8)
	for x in 16:
		for y in 16:
			var d := center.distance_to(Vector2(x, y))
			if d <= 7.0:
				var a := clampf(1.0 - (d / 7.0), 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a * a))
	particles.texture = ImageTexture.create_from_image(img)
	_spirit_vfx_container.add_child(particles)
	
# Плавное включение/отключение атмосферного фона
func _check_update_spirit_form_vfx() -> void:
	if _spirit_vfx_container == null:
		return
		
	var is_active := false
	var js: CombatUnit = battle_manager.get_joan_spirit_unit()
	if js and js.is_alive() and bool(js.get_meta("joan_spirit_form", false)):
		is_active = true
		
	if is_active != _spirit_vfx_active:
		_spirit_vfx_active = is_active
		var tween := create_tween()
		if is_active:
			_spirit_vfx_container.visible = true
			tween.tween_property(_spirit_vfx_container, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(_spirit_vfx_container, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.tween_callback(func(): _spirit_vfx_container.visible = false)

# Вспомогательный метод безопасной загрузки текстур свитков
func _load_doceva_scroll_texture(path: String, fallback: Texture2D = null) -> Texture2D:
	var real_p := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(real_p):
		var s_img := Image.new()
		var err := s_img.load(real_p)
		if err == OK:
			return ImageTexture.create_from_image(s_img)
	if ResourceLoader.exists(path):
		return load(path)
	return fallback

# Процедурная генерация полупрозрачных размытых свитков Зоны Доцевой по углам экрана
# Каскад перекрывающихся непрерывных свитков разной длины и прозрачности в углах экрана
func _init_doceva_zone_vfx() -> void:
	_doceva_vfx_container = Control.new()
	_doceva_vfx_container.name = "DocevaZoneVFX"
	_doceva_vfx_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_doceva_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doceva_vfx_container.modulate.a = 0.0
	_doceva_vfx_container.visible = false

	add_child(_doceva_vfx_container)
	if allies_container:
		move_child(_doceva_vfx_container, allies_container.get_index())

	# Подписка на изменение размеров контейнера / окна для строгого закрепления в углах
	_doceva_vfx_container.resized.connect(_layout_doceva_zone_scrolls)

	# Загрузка текстуры золотистого свечения фона и 5 вариантов свитков
	var tex_glow: Texture2D = _load_doceva_scroll_texture("res://scenes/battle/doceva_corner_glow.png")
	var tex_scrolls: Array[Texture2D] = []
	for i in range(1, 6):
		var t_path := "res://scenes/battle/doceva_top_scroll_%d.png" % i
		var tex := _load_doceva_scroll_texture(t_path)
		tex_scrolls.append(tex)

	var scroll_alphas: Array[float] = [0.35, 0.52, 0.68, 0.82, 0.94]

	# --- ВЕРХНИЙ ЛЕВЫЙ УГОЛ ---
	_doceva_left_group = Control.new()
	_doceva_left_group.name = "LeftScrollGroup"
	_doceva_left_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doceva_vfx_container.add_child(_doceva_left_group)
	_doceva_left_scrolls.clear()

	# 0. Золотистое фоновое свечение в левом углу за свитками
	_doceva_left_glow = TextureRect.new()
	_doceva_left_glow.name = "LeftCornerGlow"
	_doceva_left_glow.texture = tex_glow
	_doceva_left_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doceva_left_glow.modulate = Color(1.0, 0.90, 0.55, 0.45)
	_doceva_left_group.add_child(_doceva_left_glow)

	# 5 переплетающихся свитков, уходящих за пределы экрана
	for i in range(5):
		var s_rect := TextureRect.new()
		s_rect.name = "LeftScroll_%d" % (i + 1)
		s_rect.texture = tex_scrolls[i]
		s_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s_rect.modulate.a = scroll_alphas[i]
		_doceva_left_group.add_child(s_rect)
		_doceva_left_scrolls.append(s_rect)

	# --- ВЕРХНИЙ ПРАВЫЙ УГОЛ ---
	_doceva_right_group = Control.new()
	_doceva_right_group.name = "RightScrollGroup"
	_doceva_right_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doceva_vfx_container.add_child(_doceva_right_group)
	_doceva_right_scrolls.clear()

	# 0. Золотистое фоновое свечение в правом углу за свитками
	_doceva_right_glow = TextureRect.new()
	_doceva_right_glow.name = "RightCornerGlow"
	_doceva_right_glow.texture = tex_glow
	_doceva_right_glow.flip_h = true
	_doceva_right_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doceva_right_glow.modulate = Color(1.0, 0.90, 0.55, 0.45)
	_doceva_right_group.add_child(_doceva_right_glow)

	for i in range(5):
		var s_rect := TextureRect.new()
		s_rect.name = "RightScroll_%d" % (i + 1)
		s_rect.texture = tex_scrolls[i]
		s_rect.flip_h = true
		s_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s_rect.modulate.a = scroll_alphas[i]
		_doceva_right_group.add_child(s_rect)
		_doceva_right_scrolls.append(s_rect)

	# Расчет позиций строго вокруг верхних углов (прижаты ближе к углам)
	_layout_doceva_zone_scrolls()

	# Мягкое пульсирующее дыхание золотистого свечения фона
	var tw_glow := create_tween().set_loops()
	tw_glow.tween_property(_doceva_left_glow, "modulate:a", 0.60, 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_glow.parallel().tween_property(_doceva_right_glow, "modulate:a", 0.60, 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_glow.tween_property(_doceva_left_glow, "modulate:a", 0.32, 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_glow.parallel().tween_property(_doceva_right_glow, "modulate:a", 0.32, 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Новая плавная органическая анимация парения и покачивания (многомерное скольжение и дыхание слоёв)
	# 1. Слой 1 (внешнее полотно): волнообразный диагональный дрейф
	if _doceva_left_scrolls.size() > 0 and _doceva_right_scrolls.size() > 0:
		var tw1 := create_tween().set_loops()
		tw1.tween_property(_doceva_left_scrolls[0], "position", Vector2(1.8, -1.4), 5.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw1.parallel().tween_property(_doceva_right_scrolls[0], "position", Vector2(-1.8, -1.4), 5.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw1.tween_property(_doceva_left_scrolls[0], "position", Vector2(-1.8, 1.4), 5.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw1.parallel().tween_property(_doceva_right_scrolls[0], "position", Vector2(1.8, 1.4), 5.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Слой 2 (промежуточное полотно): мягкое вращательное покачивание (наклон)
	if _doceva_left_scrolls.size() > 1 and _doceva_right_scrolls.size() > 1:
		var tw2 := create_tween().set_loops()
		tw2.tween_property(_doceva_left_scrolls[1], "rotation", deg_to_rad(0.9), 4.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw2.parallel().tween_property(_doceva_right_scrolls[1], "rotation", deg_to_rad(-0.9), 4.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw2.tween_property(_doceva_left_scrolls[1], "rotation", deg_to_rad(-0.9), 4.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw2.parallel().tween_property(_doceva_right_scrolls[1], "rotation", deg_to_rad(0.9), 4.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. Слой 3 (струящийся талисман): вертикальное парение
	if _doceva_left_scrolls.size() > 2 and _doceva_right_scrolls.size() > 2:
		var tw3 := create_tween().set_loops()
		tw3.tween_property(_doceva_left_scrolls[2], "position:y", -2.4, 5.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw3.parallel().tween_property(_doceva_right_scrolls[2], "position:y", -2.4, 5.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw3.tween_property(_doceva_left_scrolls[2], "position:y", 2.4, 5.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw3.parallel().tween_property(_doceva_right_scrolls[2], "position:y", 2.4, 5.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 4. Слой 4 (внутренний талисман): горизонтальное скольжение
	if _doceva_left_scrolls.size() > 3 and _doceva_right_scrolls.size() > 3:
		var tw4 := create_tween().set_loops()
		tw4.tween_property(_doceva_left_scrolls[3], "position:x", -2.6, 4.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw4.parallel().tween_property(_doceva_right_scrolls[3], "position:x", 2.6, 4.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw4.tween_property(_doceva_left_scrolls[3], "position:x", 2.6, 4.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw4.parallel().tween_property(_doceva_right_scrolls[3], "position:x", -2.6, 4.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 5. Слой 5 (компактная внутренняя дуга в самом углу): мягкое пульсирующее дыхание
	if _doceva_left_scrolls.size() > 4 and _doceva_right_scrolls.size() > 4:
		var tw5 := create_tween().set_loops()
		tw5.tween_property(_doceva_left_scrolls[4], "scale", Vector2(1.02, 1.02), 3.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw5.parallel().tween_property(_doceva_right_scrolls[4], "scale", Vector2(1.02, 1.02), 3.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw5.tween_property(_doceva_left_scrolls[4], "scale", Vector2(1.0, 1.0), 3.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw5.parallel().tween_property(_doceva_right_scrolls[4], "scale", Vector2(1.0, 1.0), 3.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Активация Зоны сразу с начала боя (если техника Доцевой уже развернула Зону)
	# Прозрачность контейнера установлена на уровне (modulate.a = 0.45) для мягкого виньетирования
	var doceva: CombatUnit = battle_manager.get_dotseva_crimson_tears_unit()
	if doceva and doceva.is_alive() and bool(doceva.get_meta("doceva_tears_zone_active", false)):
		_doceva_vfx_active = true
		_layout_doceva_zone_scrolls()
		_doceva_vfx_container.visible = true
		_doceva_vfx_container.modulate.a = 0.45

# Динамическая расстановка свитков вокруг ВЕРХНИХ УГЛОВ ЭКРАНА (прижаты ближе к углам)
# Каждый свиток выходит за экран (x < 0 или x > sw) и уходит за верх (y < 0) — никаких срезов на экране!
func _layout_doceva_zone_scrolls() -> void:
	if _doceva_vfx_container == null:
		return
	var sw: float = _doceva_vfx_container.size.x
	var sh: float = _doceva_vfx_container.size.y
	if sw < 100.0 or sh < 100.0:
		var vp := get_viewport_rect().size
		sw = maxf(vp.x, 1280.0)
		sh = maxf(vp.y, 720.0)

	var base_sc: float = clampf(sh / 920.0, 0.70, 1.15)
	var w_sc: float = 480.0 * base_sc

	# --- ВЕРХНИЙ ЛЕВЫЙ УГОЛ (Position: (0, 0)) ---
	if _doceva_left_group:
		_doceva_left_group.position = Vector2(0, 0)
	if is_instance_valid(_doceva_left_glow):
		_doceva_left_glow.scale = Vector2(base_sc, base_sc)
		_doceva_left_glow.position = Vector2(0, 0)
	for s_rect in _doceva_left_scrolls:
		if is_instance_valid(s_rect):
			s_rect.scale = Vector2(base_sc, base_sc)
			s_rect.pivot_offset = Vector2(0, 0)
			s_rect.position = Vector2(0, 0)

	# --- ВЕРХНИЙ ПРАВЫЙ УГОЛ (Position: (sw - w_sc, 0)) ---
	if _doceva_right_group:
		_doceva_right_group.position = Vector2(sw - w_sc, 0)
	if is_instance_valid(_doceva_right_glow):
		_doceva_right_glow.scale = Vector2(base_sc, base_sc)
		_doceva_right_glow.position = Vector2(0, 0)
	for s_rect in _doceva_right_scrolls:
		if is_instance_valid(s_rect):
			s_rect.scale = Vector2(base_sc, base_sc)
			s_rect.pivot_offset = Vector2(480.0, 0)
			s_rect.position = Vector2(0, 0)

func _check_update_doceva_zone_vfx() -> void:
	if _doceva_vfx_container == null:
		return
	var is_active := false
	var doceva: CombatUnit = battle_manager.get_dotseva_crimson_tears_unit()
	if doceva and doceva.is_alive() and bool(doceva.get_meta("doceva_tears_zone_active", false)):
		is_active = true

	if is_active != _doceva_vfx_active:
		_doceva_vfx_active = is_active
		var tween := create_tween()
		if is_active:
			_layout_doceva_zone_scrolls()
			_doceva_vfx_container.visible = true
			# Размытые нежные свитки в верхних углах с повышенной прозрачностью (modulate.a = 0.40)
			tween.tween_property(_doceva_vfx_container, "modulate:a", 0.40, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(_doceva_vfx_container, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.tween_callback(func(): _doceva_vfx_container.visible = false)

# Интерактивная Сверхспособность Катарины: серия из 3 ударов (2 Секущих + 1 Рвущий)
func _handle_katarina_ult_target_press(katarina: CombatUnit, target: CombatUnit) -> void:
	var in_murmur := bool(katarina.get_meta("katarina_blood_murmur", false))
	if in_murmur:
		# Цель фиксируется: все последующие удары серии проводятся ТОЛЬКО по изначально выбранной цели
		var locked_target: CombatUnit = katarina.get_meta("katarina_blood_murmur_target", null)
		if locked_target != null and locked_target.is_alive():
			target = locked_target
		elif target == null or not target.is_alive():
			var living := battle_manager.get_living_enemies()
			if living.is_empty():
				_end_katarina_interactive_ult(katarina)
				return
			target = living[0]
			katarina.set_meta("katarina_blood_murmur_target", target)
	else:
		if target == null or not target.is_alive():
			var living := battle_manager.get_living_enemies()
			if living.is_empty():
				_end_katarina_interactive_ult(katarina)
				return
			target = living[0]

	if not in_murmur:
		# Нажатие 1: Активация и 1-й Секущий удар
		katarina.spend_energy(katarina.max_energy)

		# Однократные триггеры конусов при ультимейте
		for ally in battle_manager.allies:
			if ally.is_alive() and ally != katarina and ally.get_meta("light_cone_id", "") == "touch_waking_world":
				var energy_gain := ally.max_energy * 0.08
				battle_manager.gain_energy_with_err(ally, energy_gain)
				battle_manager.log_message("Конус «Коснись...»: %s получил %d энергии за ульт Катарины." % [ally.display_name, int(energy_gain)])

		if katarina.get_meta("light_cone_id", "") == "medical_smell":
			katarina.set_meta("medical_smell_healing_turns", 2)

		if katarina.get_meta("light_cone_id", "") == "archive":
			katarina.statuses.self_atk_buff_percent += 0.30
			katarina.set_meta("archive_buff_turns", 2)
			battle_manager.log_message("Конус Архив: СА %s повышена на 30%% на 2 хода!" % katarina.display_name)

		KatarinaAbilities.start_ultimate_sequence(katarina, target, battle_manager)

		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Катарина: Секущий удар (1/2) нанесён! Нажмите на цель ещё раз для 2-го удара]")
		for u in _unit_panels:
			_refresh_unit_panel(u)
		_refresh_action_bar()
		return

	var step: int = int(katarina.get_meta("katarina_blood_murmur_step", 0))
	if step == 1:
		# Нажатие 2: 2-й Секущий удар
		KatarinaAbilities.execute_murmur_hit(katarina, target, battle_manager)
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Катарина: Секущий удар (2/2) нанесён! Нажмите на цель для финального Рвущего удара]")
		for u in _unit_panels:
			_refresh_unit_panel(u)
		_refresh_action_bar()
		return
	else:
		# Нажатие 3: Рвущий удар (финал)
		KatarinaAbilities.execute_murmur_hit(katarina, target, battle_manager)
		_on_log("[Катарина: Рвущий удар нанесён! Серия Сверхспособности завершена.]")
		_end_katarina_interactive_ult(katarina)

func _end_katarina_interactive_ult(katarina: CombatUnit) -> void:
	_selecting_target = false
	_set_target_buttons_visible(false, false)
	# Сброс текста кнопок целей для всех противников
	for u in _unit_panels:
		if not u.is_ally:
			var panel: PanelContainer = _unit_panels[u]
			var vbox: VBoxContainer = panel.get_child(0)
			var btn: Button = vbox.get_node("TargetButton")
			btn.text = "🎯 Выбрать целью"

	if katarina.get_meta("light_cone_id", "") == "history_soaked_in_blood":
		katarina.remove_meta("blood_soaked_hit_targets")
		if bool(katarina.get_meta("blood_soaked_ult_triggered", false)):
			katarina.remove_meta("blood_soaked_ult_triggered")
			katarina.set_meta("blood_soaked_recorded_dmg", 0.0)
			battle_manager.log_message("🩸 Конус «История, вымоченная в крови»: Накопленный урон очищен после Сверхспособности.")
			battle_manager.unit_updated.emit(katarina)

	battle_manager.set_meta("is_selecting_ult_target", false)
	battle_manager.evaluate_feel_my_presence(katarina)
	battle_manager.check_joan_talent_trigger()

	if _original_active_unit:
		battle_manager.current_unit = _original_active_unit
		_original_active_unit = null
		_update_action_buttons(battle_manager.current_unit)
	_target_mode = ""

	for u in _unit_panels:
		_refresh_unit_panel(u)
	_refresh_action_bar()
	battle_manager._check_battle_end()

# Оверлей порогов и затемнённых зон Катарины на HP-баре врагов
class KatarinaThresholdsOverlay extends Control:
	var battle_manager: BattleManager = null
	var target_unit: CombatUnit = null

	func _init(bm: BattleManager, u: CombatUnit) -> void:
		name = "KatarinaThresholdsOverlay"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		battle_manager = bm
		target_unit = u

	func _draw() -> void:
		if battle_manager == null or target_unit == null or target_unit.is_ally:
			return
		var kat := battle_manager.get_katarina_unit()
		if kat == null or not kat.is_alive():
			return

		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return

		# Затемнённые отрезки: [80%..70%], [50%..40%], [5%..0%]
		var dark_shade := Color(0.02, 0.02, 0.05, 0.60)
		draw_rect(Rect2(0.0, 0.0, 0.05 * w, h), dark_shade)
		draw_rect(Rect2(0.40 * w, 0.0, 0.10 * w, h), dark_shade)
		draw_rect(Rect2(0.70 * w, 0.0, 0.10 * w, h), dark_shade)

		# Красные пороги: 80%, 50%, 5%
		var line_col := Color(1.0, 0.22, 0.22, 0.95)
		var shadow_col := Color(0.0, 0.0, 0.0, 0.8)

		var thresholds: Array[float] = [0.80, 0.50, 0.05]
		for pct: float in thresholds:
			var px: float = pct * w
			draw_line(Vector2(px - 1.0, 0.0), Vector2(px - 1.0, h), shadow_col, 1.0)
			draw_line(Vector2(px + 1.0, 0.0), Vector2(px + 1.0, h), shadow_col, 1.0)
			draw_line(Vector2(px, 0.0), Vector2(px, h), line_col, 2.0)
			draw_line(Vector2(px - 2.5, 0.0), Vector2(px + 2.5, 0.0), line_col, 2.0)
			draw_line(Vector2(px - 2.5, h), Vector2(px + 2.5, h), line_col, 2.0)

# Эффект удара: сотрясение экрана и бело-золотая вспышка
func _on_screen_impact_requested(flash_color: Color, intensity: float) -> void:
	# 1. Бело-золотая вспышка на весь экран
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = flash_color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(flash.queue_free)
	
	# 2. Мягкое подрагивание экрана
	var orig_pos := Vector2.ZERO
	var shake_tween := create_tween()
	var shake_steps := 5
	for i in shake_steps:
		var decay := 1.0 - (float(i) / float(shake_steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity, intensity) * decay
		)
		shake_tween.tween_property(self, "position", orig_pos + offset, 0.035)
	shake_tween.tween_property(self, "position", orig_pos, 0.04)

# Инициализация стильного виджета Векторов в левой части экрана
# Инициализация стильного виджета Векторов в левой части экрана
# Инициализация стильного виджета общего пула Векторов Консоли
func _init_console_hud() -> void:
	if console_hud_panel != null and is_instance_valid(console_hud_panel):
		return
		
	var has_console_member := false
	for ally in battle_manager.allies:
		if ally.id == "isaac_admin" or ally.has_meta("faction_console_member"):
			has_console_member = true
			break
		if FactionSystem.FACTIONS.has("console") and ally.id in FactionSystem.FACTIONS["console"].members:
			has_console_member = true
			break
			
	if not has_console_member:
		return
		
	console_hud_panel = PanelContainer.new()
	console_hud_panel.name = "ConsoleHUDPanel"
	console_hud_panel.custom_minimum_size = Vector2(180, 60) # Компактный размер
	
	# Размещение строго по центру левого края
	console_hud_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	console_hud_panel.offset_left = 30
	console_hud_panel.offset_top = -35
	console_hud_panel.offset_right = 210
	console_hud_panel.offset_bottom = 30
	console_hud_panel.z_index = 10
	
	# Аккуратный тёмный кибер-стиль
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.10, 0.88)
	style.border_color = Color(0.15, 0.95, 0.85, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	console_hud_panel.add_theme_stylebox_override("panel", style)
	
	console_hud_label = RichTextLabel.new()
	console_hud_label.bbcode_enabled = true
	console_hud_label.fit_content = true
	console_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console_hud_panel.add_child(console_hud_label)
	
	add_child(console_hud_panel)
	_update_console_hud()

# Обновление текста: только общее число Векторов Консоли
func _update_console_hud() -> void:
	if console_hud_panel == null or not is_instance_valid(console_hud_panel):
		_init_console_hud()
		
	if console_hud_label == null:
		return
		
	var vectors: int = battle_manager.get_console_vectors()
	console_hud_label.text = "[center][b][color=#1fe0d0]⚙ СЕТЬ КОНСОЛИ[/color][/b]\nВекторы: [b][color=white][font_size=20]%d[/font_size][/color][/b][/center]" % vectors

# =========================================================================
# ИНСТРУМЕНТ ТЕСТИРОВАНИЯ (АДМИН-ПАНЕЛЬ В БОЮ)
# =========================================================================

func _init_admin_panel() -> void:
	var btn_admin := Button.new()
	btn_admin.text = "🛠 Админ"
	btn_admin.pressed.connect(_toggle_admin_panel)
	btn_skills_help.get_parent().add_child(btn_admin)

	admin_panel = PanelContainer.new()
	admin_panel.name = "AdminPanel"
	admin_panel.visible = false
	admin_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	admin_panel.offset_left = -480.0
	admin_panel.offset_top = 80.0
	admin_panel.offset_right = -10.0
	admin_panel.offset_bottom = -70.0
	admin_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	admin_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.96)
	style.border_color = Color(0.2, 0.75, 0.95, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	admin_panel.add_theme_stylebox_override("panel", style)
	skills_panel.get_parent().add_child(admin_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	admin_panel.add_child(main_vbox)

	# Шапка
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "🛠 Панель тестирования (Dev Tools)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(_toggle_admin_panel)
	header.add_child(close_btn)

	# Скролл с контролами
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var add_sec_hdr := func(text: String) -> void:
		var sep := HSeparator.new()
		vbox.add_child(sep)
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		vbox.add_child(lbl)

	var make_btn := func(parent: Control, txt: String, cb: Callable, col: Color = Color.WHITE) -> Button:
		var b := Button.new()
		b.text = txt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if col != Color.WHITE:
			b.add_theme_color_override("font_color", col)
		b.pressed.connect(cb)
		parent.add_child(b)
		return b

	# 1. ЦЕЛЬ И ИНСПЕКТОР
	add_sec_hdr.call("🎯 Выбор цели и Инспектор")
	var target_hbox := HBoxContainer.new()
	target_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(target_hbox)

	_admin_target_option = OptionButton.new()
	_admin_target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_admin_target_option.item_selected.connect(func(_idx): _refresh_admin_inspector())
	target_hbox.add_child(_admin_target_option)

	var btn_refresh_inspect := Button.new()
	btn_refresh_inspect.text = "🔍 Обновить"
	btn_refresh_inspect.pressed.connect(_refresh_admin_inspector)
	target_hbox.add_child(btn_refresh_inspect)

	_admin_inspect_text = RichTextLabel.new()
	_admin_inspect_text.custom_minimum_size = Vector2(0, 160)
	_admin_inspect_text.bbcode_enabled = true
	_admin_inspect_text.text = "[color=gray]Выберите цель для просмотра подробностей.[/color]"
	vbox.add_child(_admin_inspect_text)

	# 2. БАФФЫ
	add_sec_hdr.call("✨ Баффы (применить к цели / отряду)")
	var buff_grid := GridContainer.new()
	buff_grid.columns = 2
	buff_grid.add_theme_constant_override("h_separation", 6)
	buff_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(buff_grid)

	make_btn.call(buff_grid, "⚔ СА +50% (2х)", func():
		for t in _get_admin_selected_targets():
			t.statuses.atk_buff_percent += 0.50
			t.statuses.atk_buff_turns = maxi(t.statuses.atk_buff_turns, 2)
			t.statuses.atk_buff_source = "Админ"
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен бафф СА +50% на 2 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "💥 КУ +50% (2х)", func():
		for t in _get_admin_selected_targets():
			t.statuses.crit_dmg_buff += 0.50
			t.statuses.crit_dmg_buff_turns = maxi(t.statuses.crit_dmg_buff_turns, 2)
			t.statuses.crit_dmg_buff_source = "Админ"
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен бафф КУ +50% на 2 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "🎯 КШ +30% (2х)", func():
		for t in _get_admin_selected_targets():
			t.stats.crit_rate += 0.30
			t.set_meta("admin_cr_buff_turns", 2)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен бафф Крит. Шанса +30% на 2 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "⚡ СКР +50 (2х)", func():
		for t in _get_admin_selected_targets():
			t.add_speed_modifier(0.0, 50.0)
			t.set_meta("admin_spd_buff_turns", 2)
			_refresh_unit_panel(t)
		battle_manager.action_order_changed.emit()
		battle_manager.log_message("🛠 [Админ] Наложен бафф Скорости +50 на 2 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "🔥 Урон +50% (2х)", func():
		for t in _get_admin_selected_targets():
			t.stats.damage_bonus += 0.50
			t.set_meta("admin_dmg_buff_turns", 2)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен бафф наносимого урона +50% на 2 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "🛡 Щит (5000)", func():
		for t in _get_admin_selected_targets():
			battle_manager.apply_shield(t, 5000.0, 3, "Админ Щит")
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен щит 5000 на 3 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "⚡ Зарядить ульту", func():
		for t in _get_admin_selected_targets():
			t.gain_energy(t.max_energy)
			_refresh_unit_panel(t)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
		battle_manager.log_message("🛠 [Админ] Энергия цели установлена на 100%.")
		_refresh_admin_inspector()
	)

	make_btn.call(buff_grid, "🧹 Снять ВСЕ баффы", func():
		for t in _get_admin_selected_targets():
			_admin_cleanse(t, false)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Все баффы сняты с выбранных целей.")
		_refresh_admin_inspector()
	, Color(1.0, 0.6, 0.6))

	# 3. ДЕБАФФЫ
	add_sec_hdr.call("💀 Дебаффы (применить к цели / врагам)")
	var debuff_grid := GridContainer.new()
	debuff_grid.columns = 2
	debuff_grid.add_theme_constant_override("h_separation", 6)
	debuff_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(debuff_grid)

	make_btn.call(debuff_grid, "🛡 Срез ЗАЩ -40% (2х)", func():
		for t in _get_admin_selected_targets():
			battle_manager.apply_def_reduction(t, "Админ Срез", 0.40, 2)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Снижение защиты -40% на 2 хода наложено.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🎯 Уязвимость +30% (2х)", func():
		for t in _get_admin_selected_targets():
			t.set_meta("admin_vuln_turns", 2)
			t.set_meta("admin_vuln_pct", 0.30)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Уязвимость +30% на 2 хода наложена.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🐌 Замедление -30 (2х)", func():
		for t in _get_admin_selected_targets():
			t.add_speed_modifier(0.0, -30.0)
			t.set_meta("admin_slow_turns", 2)
			_refresh_unit_panel(t)
		battle_manager.action_order_changed.emit()
		battle_manager.log_message("🛠 [Админ] Замедление -30 Скорости на 2 хода наложено.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "⚔ Срез СА -30% (2х)", func():
		for t in _get_admin_selected_targets():
			t.statuses.atk_buff_percent -= 0.30
			t.statuses.atk_buff_turns = maxi(t.statuses.atk_buff_turns, 2)
			t.statuses.atk_buff_source = "Админ Ослабление"
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Снижение СА -30% на 2 хода наложено.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🔥 DoT Горение (3х)", func():
		for t in _get_admin_selected_targets():
			t.set_meta("shoji_burn_turns", 3)
			t.set_meta("shoji_burn_dmg", 5000.0)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложено Горение (5000 урона/ход, 3 хода).")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "⚡ DoT Шок (3х)", func():
		for t in _get_admin_selected_targets():
			t.set_meta("jeff_bass_listen_turns", 3)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен Шок Джеффа на 3 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🍃 DoT Выветривание", func():
		for t in _get_admin_selected_targets():
			t.statuses.break_status = "Выветривание"
			t.statuses.break_status_turns = 3
			t.statuses.break_status_source = "Админ"
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложено Выветривание на 3 хода.")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🧪 Кислотный мутаген", func():
		for t in _get_admin_selected_targets():
			t.set_meta("ortho_acid_dot_turns", 3)
			t.set_meta("ortho_acid_dot_dmg", 3000.0)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Наложен Кислотный мутаген (3000 урона/ход).")
		_refresh_admin_inspector()
	)

	make_btn.call(debuff_grid, "🧹 Очистить дебаффы", func():
		for t in _get_admin_selected_targets():
			_admin_cleanse(t, true)
			_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Все дебаффы сняты с выбранных целей.")
		_refresh_admin_inspector()
	, Color(0.5, 1.0, 0.5))

	# 4. БОЕВЫЕ РЕСУРСЫ
	add_sec_hdr.call("💎 Боевые Ресурсы")

	# Очки навыков (SP)
	var sp_hbox := HBoxContainer.new()
	sp_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(sp_hbox)
	var sp_lbl := Label.new()
	sp_lbl.text = "ОН (SP): "
	sp_lbl.custom_minimum_size = Vector2(80, 0)
	sp_hbox.add_child(sp_lbl)

	make_btn.call(sp_hbox, "+1 SP", func():
		battle_manager.skill_points = mini(battle_manager.skill_points + 1, CombatConstants.MAX_SKILL_POINTS)
		battle_manager.skill_points_changed.emit(battle_manager.skill_points)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
	)
	make_btn.call(sp_hbox, "5 SP (Макс)", func():
		battle_manager.skill_points = CombatConstants.MAX_SKILL_POINTS
		battle_manager.skill_points_changed.emit(battle_manager.skill_points)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
	)
	make_btn.call(sp_hbox, "0 SP", func():
		battle_manager.skill_points = 0
		battle_manager.skill_points_changed.emit(battle_manager.skill_points)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
	)

	# Векторы Консоли
	var vec_hbox := HBoxContainer.new()
	vec_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(vec_hbox)
	var vec_lbl := Label.new()
	vec_lbl.text = "Векторы: "
	vec_lbl.custom_minimum_size = Vector2(80, 0)
	vec_hbox.add_child(vec_lbl)

	make_btn.call(vec_hbox, "+10", func():
		battle_manager.add_console_vectors(10)
		_update_console_hud()
	)
	make_btn.call(vec_hbox, "+20", func():
		battle_manager.add_console_vectors(20)
		_update_console_hud()
	)
	make_btn.call(vec_hbox, "+40", func():
		battle_manager.add_console_vectors(40)
		_update_console_hud()
	)
	make_btn.call(vec_hbox, "90 (Сброс)", func():
		battle_manager.set_console_vectors(90)
		_update_console_hud()
	)
	make_btn.call(vec_hbox, "0", func():
		battle_manager.set_console_vectors(0)
		_update_console_hud()
	)

	# Энергия отряда
	var en_hbox := HBoxContainer.new()
	en_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(en_hbox)
	var en_lbl := Label.new()
	en_lbl.text = "Энергия: "
	en_lbl.custom_minimum_size = Vector2(80, 0)
	en_hbox.add_child(en_lbl)

	make_btn.call(en_hbox, "⚡ 100% Всем", func():
		for a in battle_manager.allies:
			if a.is_alive():
				a.gain_energy(a.max_energy)
				_refresh_unit_panel(a)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
		battle_manager.log_message("🛠 [Админ] Заряжена ульта всем союзникам!")
	)
	make_btn.call(en_hbox, "❌ 0% Всем", func():
		for a in battle_manager.allies:
			if a.is_alive():
				a.energy = 0.0
				a.energy_changed.emit(a)
				_refresh_unit_panel(a)
		if battle_manager.current_unit != null:
			_update_action_buttons(battle_manager.current_unit)
		battle_manager.log_message("🛠 [Админ] Энергия всех союзников обнулена.")
	)

	# 5. ЗДОРОВЬЕ, СТОЙКОСТЬ И РЕЖИМЫ
	add_sec_hdr.call("❤ Здоровье, Стойкость и Режимы")
	var hp_grid := GridContainer.new()
	hp_grid.columns = 2
	hp_grid.add_theme_constant_override("h_separation", 6)
	hp_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(hp_grid)

	_admin_god_mode_btn = make_btn.call(hp_grid, "🛡 Бессмертие: ВЫКЛ", func():
		var cur: bool = bool(battle_manager.get_meta("admin_god_mode", false))
		var new_val: bool = not cur
		battle_manager.set_meta("admin_god_mode", new_val)
		if new_val:
			_admin_god_mode_btn.text = "🛡 Бессмертие: ВКЛ"
			_admin_god_mode_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			battle_manager.log_message("🛠 [Админ] Режим бессмертия ВКЛЮЧЕН!")
		else:
			_admin_god_mode_btn.text = "🛡 Бессмертие: ВЫКЛ"
			_admin_god_mode_btn.add_theme_color_override("font_color", Color.WHITE)
			battle_manager.log_message("🛠 [Админ] Режим бессмертия ВЫКЛЮЧЕН.")
	)

	make_btn.call(hp_grid, "💖 Исцелить всех 100%", func():
		for a in battle_manager.allies:
			if a.is_alive():
				a.stats.hp = a.stats.max_hp
				a.hp_changed.emit(a)
				_refresh_unit_panel(a)
		battle_manager.log_message("🛠 [Админ] Все союзники полностью исцелены!")
		_refresh_admin_inspector()
	)

	make_btn.call(hp_grid, "🩸 Оставить 1 HP союзникам", func():
		for a in battle_manager.allies:
			if a.is_alive():
				a.stats.hp = 1.0
				a.hp_changed.emit(a)
				_refresh_unit_panel(a)
		battle_manager.log_message("🛠 [Админ] Здоровье всех союзников снижено до 1 HP!")
		_refresh_admin_inspector()
	)

	make_btn.call(hp_grid, "⚡ Пробить стойкость цели", func():
		for t in _get_admin_selected_targets():
			if not t.is_ally and t.is_alive() and t.max_toughness > 0.0:
				t.toughness = 0.0
				var attacker := battle_manager.current_unit if battle_manager.current_unit != null else (battle_manager.allies[0] if not battle_manager.allies.is_empty() else t)
				ToughnessSystem._trigger_break(attacker, t, battle_manager)
				_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Стойкость цели мгновенно пробита!")
		_refresh_admin_inspector()
	)

	make_btn.call(hp_grid, "🔄 Восстановить стойкость", func():
		for t in _get_admin_selected_targets():
			if not t.is_ally and t.is_alive():
				t.toughness = t.max_toughness
				t.statuses.clear_break_phase()
				_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Стойкость цели восстановлена.")
		_refresh_admin_inspector()
	)

	make_btn.call(hp_grid, "💥 Снять 50% HP врагам", func():
		for e in battle_manager.get_living_enemies():
			var half := e.stats.hp * 0.5
			e.apply_damage(half)
			_refresh_unit_panel(e)
		battle_manager.log_message("🛠 [Админ] Всем врагам нанесено 50% урона от текущего HP.")
		_refresh_admin_inspector()
	)

	make_btn.call(hp_grid, "💀 Убить цель", func():
		for t in _get_admin_selected_targets():
			if t.is_alive():
				t.apply_damage(t.stats.hp + 9999.0)
				_refresh_unit_panel(t)
		battle_manager.log_message("🛠 [Админ] Цель уничтожена.")
		_refresh_admin_inspector()
	, Color(1.0, 0.4, 0.4))

	make_btn.call(hp_grid, "🏆 Мгновенная победа", func():
		for e in battle_manager.get_living_enemies():
			e.apply_damage(e.stats.hp + 9999.0)
			_refresh_unit_panel(e)
		battle_manager.log_message("🛠 [Админ] Все враги уничтожены. Мгновенная победа!")
	, Color(1.0, 0.85, 0.2))

	# 6. ДЕЙСТВИЯ И ШКАЛА ХОДОВ
	add_sec_hdr.call("⏱ Действия и Шкала ходов")
	var act_grid := GridContainer.new()
	act_grid.columns = 2
	act_grid.add_theme_constant_override("h_separation", 6)
	act_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(act_grid)

	make_btn.call(act_grid, "⏩ Продвинуть действие 100%", func():
		for t in _get_admin_selected_targets():
			t.advance_action(100.0)
		battle_manager.action_order_changed.emit()
		battle_manager.log_message("🛠 [Админ] Действие цели продвинуто на 100%!")
		_refresh_admin_inspector()
	)

	make_btn.call(act_grid, "⏪ Задержать действие 100%", func():
		for t in _get_admin_selected_targets():
			t.delay_action(100.0)
		battle_manager.action_order_changed.emit()
		battle_manager.log_message("🛠 [Админ] Действие цели задержано на 100%!")
		_refresh_admin_inspector()
	)

	make_btn.call(act_grid, "⏭ Завершить ход", func():
		battle_manager.force_end_turn()
		battle_manager.log_message("🛠 [Админ] Текущий ход принудительно завершён.")
	)

func _toggle_admin_panel() -> void:
	_admin_open = not _admin_open
	admin_panel.visible = _admin_open
	if _admin_open:
		_skills_help_open = false
		_graphs_open = false
		_factions_open = false
		skills_panel.hide()
		graphs_panel.hide()
		factions_panel.hide()
		_refresh_admin_targets()
		_refresh_admin_inspector()

func _refresh_admin_targets() -> void:
	if _admin_target_option == null:
		return
	var prev_selected_unit: CombatUnit = null
	if _admin_target_option.selected >= 0 and _admin_target_option.selected < _admin_target_option.item_count:
		var prev_meta = _admin_target_option.get_item_metadata(_admin_target_option.selected)
		if prev_meta is CombatUnit:
			prev_selected_unit = prev_meta

	_admin_target_option.clear()
	_admin_target_option.add_item("👥 Все союзники", 0)
	_admin_target_option.set_item_metadata(0, "all_allies")
	_admin_target_option.add_item("👾 Все враги", 1)
	_admin_target_option.set_item_metadata(1, "all_enemies")

	var item_idx: int = 2
	var reselect_idx: int = 0
	for a in battle_manager.allies:
		if a.is_alive():
			_admin_target_option.add_item("🛡 [Союзник] %s" % a.display_name, item_idx)
			_admin_target_option.set_item_metadata(item_idx, a)
			if a == prev_selected_unit or (prev_selected_unit == null and a == battle_manager.current_unit):
				reselect_idx = item_idx
			item_idx += 1

	for e in battle_manager.enemies:
		if e.is_alive():
			_admin_target_option.add_item("⚔ [Враг] %s" % e.display_name, item_idx)
			_admin_target_option.set_item_metadata(item_idx, e)
			if e == prev_selected_unit:
				reselect_idx = item_idx
			item_idx += 1

	_admin_target_option.select(reselect_idx)

func _get_admin_selected_targets() -> Array[CombatUnit]:
	var targets: Array[CombatUnit] = []
	if _admin_target_option == null or _admin_target_option.selected < 0:
		return targets
	var meta = _admin_target_option.get_item_metadata(_admin_target_option.selected)
	if meta is String:
		if meta == "all_allies":
			for a in battle_manager.allies:
				if a.is_alive():
					targets.append(a)
		elif meta == "all_enemies":
			for e in battle_manager.enemies:
				if e.is_alive():
					targets.append(e)
	elif meta is CombatUnit:
		if meta.is_alive():
			targets.append(meta)
	return targets

func _admin_cleanse(unit: CombatUnit, is_debuffs: bool) -> void:
	if is_debuffs:
		unit.statuses.cleanse_all()
		unit.remove_meta("def_reductions")
		unit.remove_meta("admin_vuln_turns")
		unit.remove_meta("admin_vuln_pct")
		unit.remove_meta("shoji_burn_turns")
		unit.remove_meta("shoji_burn_dmg")
		unit.remove_meta("jeff_bass_listen_turns")
		unit.remove_meta("ortho_acid_dot_turns")
		unit.remove_meta("ortho_acid_dot_dmg")
		unit.remove_meta("admin_slow_turns")
		unit.remove_meta("valramors_ult_vuln_turns")
		unit.remove_meta("joan_dont_miss_turns")
		unit.remove_meta("naama_kiss_turns")
		unit.remove_meta("naama_intox_stacks")
		unit.statuses.debuffs.clear()
	else:
		unit.statuses.atk_buff_percent = 0.0
		unit.statuses.atk_buff_flat = 0.0
		unit.statuses.atk_buff_turns = 0
		unit.statuses.self_atk_buff_percent = 0.0
		unit.statuses.self_atk_buff_turns = 0
		unit.statuses.crit_dmg_buff = 0.0
		unit.statuses.crit_dmg_buff_turns = 0
		unit.statuses.incoming_heal_bonus = 0.0
		unit.statuses.effect_resist_bonus = 0.0
		unit.set_meta("shield_value", 0.0)
		unit.set_meta("shield_turns", 0)
		unit.remove_meta("admin_cr_buff_turns")
		unit.remove_meta("admin_spd_buff_turns")
		unit.remove_meta("admin_dmg_buff_turns")

func _refresh_admin_inspector() -> void:
	if _admin_inspect_text == null:
		return
	var targets := _get_admin_selected_targets()
	if targets.is_empty():
		_admin_inspect_text.text = "[color=gray]Цель не выбрана или мертва.[/color]"
		return

	var unit: CombatUnit = targets[0]
	var text := ""
	text += "[b]%s[/b] (%s)\n" % [unit.display_name, "Союзник" if unit.is_ally else "Враг"]
	text += "ХП: [color=green]%d / %d[/color] | Щит: [color=cyan]%d[/color] | Энергия: [color=yellow]%d / %d[/color]\n" % [
		int(unit.stats.hp), int(unit.stats.max_hp),
		int(unit.get_meta("shield_value", 0.0)),
		int(unit.energy), int(unit.max_energy)
	]
	text += "СКР: %d | СА: %d | ЗАЩ: %d | КШ/КУ: %.1f%% / %.1f%%\n" % [
		int(unit.stats.get_effective_spd()), int(unit.stats.atk), int(unit.stats.def),
		unit.stats.crit_rate * 100.0, unit.stats.crit_dmg * 100.0
	]
	if not unit.is_ally and unit.max_toughness > 0.0:
		text += "Стойкость: %d / %d (Пробита: %s)\n" % [
			int(unit.toughness), int(unit.max_toughness),
			"Да" if unit.statuses.toughness_broken else "Нет"
		]

	var statuses_str := BattleInfoProvider.get_statuses_text(unit, battle_manager.allies)
	if statuses_str.strip_edges() != "":
		text += "\n[b]Действующие эффекты:[/b]\n" + statuses_str

	_admin_inspect_text.text = text
	
