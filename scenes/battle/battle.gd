extends Control

const LenskayaAntimatterAbilities = preload("res://scripts/characters/lenskaya_antimatter.gd")

@onready var battle_manager: BattleManager = %BattleManager
@onready var allies_container: HBoxContainer = %AlliesContainer
@onready var enemies_container: HBoxContainer = %EnemiesContainer
@onready var action_bar: Control = %ActionBar
@onready var turn_label: Label = %TurnLabel
@onready var arya_label: Label = %AryaLabel
@onready var log_panel: PanelContainer = %LogPanel
@onready var btn_toggle_log: Button = %BtnToggleLog
@onready var log_list: RichTextLabel = %LogList
@onready var skill_points_panel: PanelContainer = %SkillPointsPanel
@onready var skill_points_label: Label = %SkillPointsLabel
@onready var skill_points_pips: HBoxContainer = %SkillPointsPips
@onready var action_panel: PanelContainer = %ActionPanel
@onready var btn_basic: Button = %BtnBasic
@onready var btn_enhanced_basic: Button = %BtnEnhancedBasic
@onready var btn_skill: Button = %BtnSkill
@onready var btn_skill_e: Button = %BtnSkillE
@onready var btn_ult: Button = %BtnUlt
@onready var btn_skills_help: Button = %BtnSkillsHelp
@onready var skills_panel: PanelContainer = %SkillsPanel
@onready var btn_close_skills: Button = %BtnCloseSkills
@onready var skills_text: RichTextLabel = %SkillsText
@onready var vbox_basic: VBoxContainer = %VBoxBasic
@onready var vbox_skill_q: VBoxContainer = %VBoxSkillQ
@onready var vbox_skill_e: VBoxContainer = %VBoxSkillE
@onready var inspect_overlay: ColorRect = %InspectOverlay
@onready var inspect_title: Label = %InspectTitle
@onready var inspect_stats: RichTextLabel = %InspectStats
@onready var inspect_effects: RichTextLabel = %InspectEffects
@onready var inspect_skills: RichTextLabel = %InspectSkills
@onready var btn_close_inspect: Button = %BtnCloseInspect
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var btn_return: Button = %BtnReturn
@onready var support_panel: PanelContainer = %SupportPanel
@onready var btn_support_action: Button = %BtnSupportAction
@onready var chorus_dark_overlay: ColorRect = %ChorusDarkOverlay
var _chorus_glow_tween: Tween = null

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
var btn_graphs: Button = null

var factions_panel: PanelContainer
var factions_text: RichTextLabel
var _factions_open: bool = false
var btn_factions: Button = null

var admin_panel: PanelContainer
var _admin_open: bool = false
var _admin_target_option: OptionButton
var _admin_inspect_text: RichTextLabel
var _admin_god_mode_btn: Button

# Адаптивные компактные размеры карточек участников
const ALLY_PANEL_SIZE := Vector2(210, 285)
const MEMOSPRITE_PANEL_SIZE := Vector2(145, 165)
const ENEMY_PANEL_SIZE := Vector2(200, 265)

func _get_panel_size_for_ally(is_memosprite: bool) -> Vector2:
	var memo_count := 0
	if battle_manager != null and "memosprites" in battle_manager:
		for m in battle_manager.memosprites:
			if m != null and m.is_alive():
				memo_count += 1
	if memo_count > 0:
		if is_memosprite:
			return Vector2(145, 165)
		else:
			return Vector2(175, 275)
	return MEMOSPRITE_PANEL_SIZE if is_memosprite else ALLY_PANEL_SIZE

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
var faction_hud_vbox: VBoxContainer = null
var console_hud_panel: PanelContainer = null
var console_hud_label: RichTextLabel = null
var antimatter_hud_panel: PanelContainer = null
var antimatter_hud_label: RichTextLabel = null
var moon_maiden_hud_panel: PanelContainer = null
var moon_maiden_hud_label: RichTextLabel = null
var lenskaya_ult_root: Control = null
var lenskaya_ult_panel: PanelContainer = null
var star_guide_modal_root: Control = null

var _log_expanded: bool = false
var _highlighted_unit_panel: PanelContainer = null
var _skill_tooltip_panel: PanelContainer = null
var _skill_tooltip_text: RichTextLabel = null
var _selected_target_unit: CombatUnit = null

static func _create_opaque_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.98)
	style.border_color = Color(0.2, 0.75, 0.95, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	return style

func _ready() -> void:
	battle_manager.screen_impact_requested.connect(_on_screen_impact_requested)
	btn_basic.pressed.connect(_on_basic_pressed)
	btn_enhanced_basic.pressed.connect(_on_enhanced_basic_pressed)
	btn_skill.pressed.connect(_on_skill_pressed)
	btn_skill_e.pressed.connect(_on_skill_e_pressed)
	btn_ult.pressed.connect(_on_ult_pressed)
	btn_skills_help.pressed.connect(_on_skills_help_pressed)
	btn_close_skills.pressed.connect(_on_skills_help_pressed)
	btn_close_inspect.pressed.connect(_close_inspect)
	btn_return.pressed.connect(_on_return_pressed)
	btn_toggle_log.pressed.connect(_toggle_log)
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
	battle_manager.xaeroh_changed.connect(func(_val): _update_antimatter_hud())
	battle_manager.black_hole_absorption_changed.connect(func(_val): _update_antimatter_hud())
	battle_manager.lenskaya_am_followup_ult_requested.connect(func(u): _show_lenskaya_am_ult_modal(u, true))
	battle_manager.lenskaya_am_supernova_vfx_requested.connect(_on_lenskaya_am_supernova_vfx)
	battle_manager.lenskaya_am_keeper_q_vfx_requested.connect(_on_lenskaya_am_keeper_q_vfx)
	battle_manager.lenskaya_am_warrior_q_vfx_requested.connect(_on_lenskaya_am_warrior_q_vfx)
	battle_manager.lenskaya_am_warrior_e_slash_requested.connect(_on_lenskaya_am_warrior_e_slash)
	battle_manager.lenskaya_am_inverted_exit_requested.connect(_on_lenskaya_am_inverted_exit)
	btn_support_action.pressed.connect(_on_btn_support_action_pressed)
	battle_manager.chorus_charges_changed.connect(_on_chorus_charges_changed)
	battle_manager.moon_maiden_hits_changed.connect(func(_val): _update_moon_maiden_hud())
	_refresh_support_button()

	result_panel.hide()
	action_panel.hide()
	arya_label.hide()
	skills_panel.hide()
	inspect_overlay.hide()
	btn_ult.hide() 

	# Стилизация панелей непрозрачным стилем
	skills_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	skills_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skills_panel.offset_left = 50.0
	skills_panel.offset_top = 50.0
	skills_panel.offset_right = -50.0
	skills_panel.offset_bottom = -50.0
	skills_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	skills_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	skills_panel.z_index = 80
	action_panel.z_index = 15
	inspect_overlay.z_index = 100
	result_panel.z_index = 110

	skill_points_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	log_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	
	# Лог боя свернут по умолчанию
	_log_expanded = false
	log_panel.offset_top = -52.0
	log_panel.offset_right = 240.0
	log_list.hide()

	# Инициализация всплывающего тултипа способности
	_skill_tooltip_panel = PanelContainer.new()
	_skill_tooltip_panel.name = "SkillTooltipPanel"
	_skill_tooltip_panel.visible = false
	_skill_tooltip_panel.z_index = 85
	_skill_tooltip_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	_skill_tooltip_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_skill_tooltip_panel.offset_left = 320.0
	_skill_tooltip_panel.offset_right = -320.0
	_skill_tooltip_panel.offset_top = -240.0
	_skill_tooltip_panel.offset_bottom = -105.0
	_skill_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_tooltip_text = RichTextLabel.new()
	_skill_tooltip_text.bbcode_enabled = true
	_skill_tooltip_text.fit_content = true
	_skill_tooltip_text.scroll_active = true
	_skill_tooltip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_tooltip_text.add_theme_font_size_override("normal_font_size", 13)
	_skill_tooltip_panel.add_child(_skill_tooltip_text)
	add_child(_skill_tooltip_panel)

	btn_basic.mouse_entered.connect(func(): _show_skill_tooltip("basic"))
	btn_basic.mouse_exited.connect(_hide_skill_tooltip)
	btn_enhanced_basic.mouse_entered.connect(func(): _show_skill_tooltip("enhanced_basic"))
	btn_enhanced_basic.mouse_exited.connect(_hide_skill_tooltip)
	btn_skill.mouse_entered.connect(func(): _show_skill_tooltip("skill_q"))
	btn_skill.mouse_exited.connect(_hide_skill_tooltip)
	btn_skill_e.mouse_entered.connect(func(): _show_skill_tooltip("skill_e"))
	btn_skill_e.mouse_exited.connect(_hide_skill_tooltip)
	btn_ult.mouse_entered.connect(func(): _show_skill_tooltip("ult"))
	btn_ult.mouse_exited.connect(_hide_skill_tooltip)
	
	_init_damage_graphs() 
	_setup_inspect_ui()

	battle_manager.start_battle(TeamConfig.team_members, TeamConfig.battle_initiator_id)
	_build_unit_displays()
	_on_sp_changed(battle_manager.skill_points)
	_refresh_action_bar()
	_init_factions_panel()
	_check_star_guide_selection()
	
	var btn_give_up := Button.new()
	btn_give_up.name = "BtnGiveUp"
	btn_give_up.text = "🏳 Сдаться"
	btn_give_up.pressed.connect(_on_give_up_pressed)
	btn_skills_help.get_parent().add_child(btn_give_up)
	LevelManager.init_tutorial_ui(self)
	_init_spirit_form_vfx()
	_init_doceva_zone_vfx()
	
	_init_console_hud()
	_init_antimatter_hud()
	_init_admin_panel()

	var top_bar := btn_skills_help.get_parent() as Control
	if top_bar:
		top_bar.z_index = 20
		move_child(top_bar, -1)

	
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
	btn_factions = Button.new()
	btn_factions.name = "BtnFactions"
	btn_factions.text = "🛡 Синергии"
	btn_skills_help.get_parent().add_child(btn_factions)
	btn_factions.pressed.connect(_toggle_factions)

	factions_panel = PanelContainer.new()
	factions_panel.name = "FactionsPanel"
	factions_panel.visible = false
	factions_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	factions_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	factions_panel.offset_left = 50.0
	factions_panel.offset_top = 50.0
	factions_panel.offset_right = -50.0
	factions_panel.offset_bottom = -50.0
	factions_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	factions_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	factions_panel.z_index = 80
	skills_panel.get_parent().add_child(factions_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	factions_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "🛡 Действующие Синергии Отряда"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(36, 32)
	btn_close.pressed.connect(_toggle_factions)
	header.add_child(btn_close)

	factions_text = RichTextLabel.new()
	factions_text.name = "FactionsText"
	factions_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	factions_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	factions_text.bbcode_enabled = true
	factions_text.scroll_active = true
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
	btn_graphs = Button.new()
	btn_graphs.name = "BtnGraphs"
	btn_graphs.text = "📊 Урон"
	btn_skills_help.get_parent().add_child(btn_graphs)
	btn_graphs.pressed.connect(_toggle_graphs)

	graphs_panel = PanelContainer.new()
	graphs_panel.name = "GraphsPanel"
	graphs_panel.visible = false
	graphs_panel.add_theme_stylebox_override("panel", _create_opaque_panel_style())
	graphs_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graphs_panel.offset_left = 50.0
	graphs_panel.offset_top = 50.0
	graphs_panel.offset_right = -50.0
	graphs_panel.offset_bottom = -50.0
	graphs_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	graphs_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	graphs_panel.z_index = 80
	skills_panel.get_parent().add_child(graphs_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graphs_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "📊 Статистика урона отряда"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(36, 32)
	btn_close.pressed.connect(_toggle_graphs)
	header.add_child(btn_close)

	graphs_text = RichTextLabel.new()
	graphs_text.name = "GraphsText"
	graphs_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graphs_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graphs_text.bbcode_enabled = true
	graphs_text.scroll_active = true
	vbox.add_child(graphs_text)

func _toggle_graphs() -> void:
	_graphs_open = not _graphs_open
	graphs_panel.visible = _graphs_open
	if _graphs_open:
		_skills_help_open = false
		_factions_open = false
		_admin_open = false
		skills_panel.hide()
		factions_panel.hide()
		if admin_panel: admin_panel.hide()
		_refresh_graphs_panel()

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

	var memo_count := 0
	if battle_manager != null and "memosprites" in battle_manager:
		for m in battle_manager.memosprites:
			if m != null and m.is_alive():
				memo_count += 1
	allies_container.add_theme_constant_override("separation", 8 if memo_count > 0 else 20)

	for ally in battle_manager.allies:
		var panel := _create_unit_panel(ally, true)
		allies_container.add_child(panel)
		if is_duel and ally.id != "rimes":
			panel.hide() # Прячем карточку союзника

		# Духи памяти всегда находятся справа от своего владельца
		if battle_manager != null and "memosprites" in battle_manager:
			for sprite in battle_manager.memosprites:
				if sprite != null and sprite.is_alive() and sprite.owner == ally:
					var sprite_panel := _create_unit_panel(sprite, true)
					allies_container.add_child(sprite_panel)
					if is_duel:
						sprite_panel.hide()

	if battle_manager != null and "memosprites" in battle_manager:
		for sprite in battle_manager.memosprites:
			if sprite != null and sprite.is_alive() and not _unit_panels.has(sprite):
				var sprite_panel := _create_unit_panel(sprite, true)
				allies_container.add_child(sprite_panel)

	for enemy in battle_manager.enemies:
		enemies_container.add_child(_create_unit_panel(enemy, false))

func _create_unit_panel(unit: CombatUnit, is_ally: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var is_memo: bool = unit is Memosprite
	panel.custom_minimum_size = _get_panel_size_for_ally(is_memo) if is_ally else ENEMY_PANEL_SIZE
	if is_memo:
		panel.size_flags_vertical = Control.SIZE_SHRINK_END
	panel.set_meta("unit", unit)

	if is_memo:
		var elem_col: Color = CombatConstants.get_element_color(unit.element)
		var memo_style := StyleBoxFlat.new()
		memo_style.bg_color = Color(0.04, 0.08, 0.14, 0.95)
		memo_style.border_color = elem_col
		memo_style.set_border_width_all(2)
		memo_style.set_corner_radius_all(8)
		memo_style.set_content_margin_all(5)
		panel.add_theme_stylebox_override("panel", memo_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2 if is_memo else 6) 
	panel.add_child(vbox)

	var name_lbl := Label.new()
	var elite_tag := " ★" if unit.is_elite else ""
	var elem_tag := CombatConstants.get_element_short_name(unit.element)
	if is_memo:
		name_lbl.text = "%s %s [%s]" % [
			CombatConstants.ELEMENT_SYMBOLS.get(unit.element, "❄"),
			unit.display_name,
			elem_tag,
		]
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(unit.element))
	else:
		name_lbl.text = "%s %s [%s]%s" % [
			CombatConstants.ELEMENT_SYMBOLS[unit.element],
			unit.display_name,
			elem_tag,
			elite_tag,
		]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(unit.element))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Обертка для наложения рамок и ХП-баров
	var bar_wrapper := Control.new()
	bar_wrapper.name = "BarWrapper"
	bar_wrapper.custom_minimum_size = Vector2(0, 14 if is_memo else 20) 
	vbox.add_child(bar_wrapper)

	if is_ally:
		var shield_bar := ProgressBar.new()
		shield_bar.name = "ShieldBar"
		shield_bar.show_percentage = false
		shield_bar.modulate = Color(1.6, 1.6, 1.6, 1.0) 
		
		shield_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shield_bar.offset_left = -3
		shield_bar.offset_right = 3
		shield_bar.offset_top = -3
		shield_bar.offset_bottom = 3
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
	hp_lbl.add_theme_font_size_override("font_size", 10 if is_memo else 13) 
	vbox.add_child(hp_lbl)

	if not is_ally:
		var weakness_container := HBoxContainer.new()
		weakness_container.name = "WeaknessContainer"
		weakness_container.alignment = BoxContainer.ALIGNMENT_CENTER
		weakness_container.custom_minimum_size = Vector2(0, 18)
		weakness_container.add_theme_constant_override("separation", 6)
		vbox.add_child(weakness_container)

	if not is_ally and unit.max_toughness > 0:
		var tgh_bar := ProgressBar.new()
		tgh_bar.name = "TghBar"
		tgh_bar.custom_minimum_size = Vector2(0, 16) 
		tgh_bar.max_value = unit.max_toughness
		tgh_bar.value = unit.toughness
		tgh_bar.modulate = Color(0.6, 0.8, 1.0)
		tgh_bar.draw.connect(_draw_tgh_preview.bind(tgh_bar, unit))
		vbox.add_child(tgh_bar)

		var tgh_lbl := Label.new()
		tgh_lbl.name = "TghLabel"
		tgh_lbl.text = "Стойкость"
		tgh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tgh_lbl.add_theme_font_size_override("font_size", 12) 
		vbox.add_child(tgh_lbl)

	var status_lbl := Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 10 if is_memo else 12) 
	vbox.add_child(status_lbl)

	if is_ally:
		if is_memo:
			var memo_sprite := unit as Memosprite
			var cur_charge: float = memo_sprite.charge_comp.charge if memo_sprite.charge_comp != null else memo_sprite.energy
			var max_charge: float = memo_sprite.charge_comp.max_charge if memo_sprite.charge_comp != null else 100.0

			var en_bar := ProgressBar.new()
			en_bar.name = "EnergyBarOnCard"
			en_bar.custom_minimum_size = Vector2(0, 10)
			en_bar.max_value = max_charge
			en_bar.value = cur_charge
			en_bar.show_percentage = false
			en_bar.modulate = CombatConstants.get_element_color(unit.element) 
			vbox.add_child(en_bar)

			var charge_lbl := Label.new()
			charge_lbl.name = "ChargeLabelOnCard"
			charge_lbl.text = "Заряд: %d%%" % int(cur_charge)
			charge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			charge_lbl.add_theme_font_size_override("font_size", 10)
			charge_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(unit.element))
			vbox.add_child(charge_lbl)
		else:
			var en_bar := ProgressBar.new()
			en_bar.name = "EnergyBarOnCard"
			en_bar.custom_minimum_size = Vector2(0, 12)
			en_bar.max_value = unit.max_energy
			en_bar.value = unit.energy
			en_bar.show_percentage = false
			en_bar.modulate = Color(0.95, 0.8, 0.25) 
			vbox.add_child(en_bar)

			var ult_btn := Button.new()
			ult_btn.name = "UltButtonOnCard"
			ult_btn.text = "★ СВЕРХСП."
			ult_btn.custom_minimum_size = Vector2(0, 36)
			ult_btn.add_theme_font_size_override("font_size", 13)
			ult_btn.pressed.connect(_on_card_ult_pressed.bind(unit))
			ult_btn.mouse_entered.connect(func(): _show_skill_tooltip_for_unit(unit, "ult"))
			ult_btn.mouse_exited.connect(_hide_skill_tooltip)
			vbox.add_child(ult_btn)

			var ally_idx := battle_manager.allies.find(unit)
			var ult_hotkey_lbl := Label.new()
			ult_hotkey_lbl.name = "UltHotkeyLabel"
			ult_hotkey_lbl.text = "[%d]" % (ally_idx + 1 if ally_idx >= 0 else 1)
			ult_hotkey_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ult_hotkey_lbl.add_theme_font_size_override("font_size", 11)
			ult_hotkey_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
			vbox.add_child(ult_hotkey_lbl)

	var info_btn := Button.new()
	info_btn.name = "InfoButton"
	info_btn.text = "ℹ Инфо"
	info_btn.custom_minimum_size = Vector2(100 if is_memo else 140, 22 if is_memo else 28) 
	info_btn.add_theme_font_size_override("font_size", 10 if is_memo else 12)
	info_btn.pressed.connect(_open_inspect.bind(unit))
	vbox.add_child(info_btn)

	var target_btn := Button.new()
	target_btn.name = "TargetButton"
	target_btn.text = "🎯 Выбрать целью"
	target_btn.custom_minimum_size = Vector2(100 if is_memo else 140, 24 if is_memo else 32)
	target_btn.visible = false
	target_btn.pressed.connect(_on_target_pressed.bind(unit, is_ally))
	target_btn.add_theme_font_size_override("font_size", 10 if is_memo else 13)
	target_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(target_btn)

	var reticle := Control.new()
	reticle.name = "TargetReticle"
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.z_index = 5
	reticle.draw.connect(_draw_target_reticle.bind(reticle, unit))
	panel.add_child(reticle)

	_unit_panels[unit] = panel
	_refresh_unit_panel(unit)
	return panel
	
func _refresh_unit_panel(unit: CombatUnit) -> void:
	if not _unit_panels.has(unit):
		if unit is Memosprite and unit.is_alive():
			_build_unit_displays()
		return
	if unit is Memosprite and not unit.is_alive():
		_build_unit_displays()
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

	if vbox.has_node("WeaknessContainer"):
		var w_cont: HBoxContainer = vbox.get_node("WeaknessContainer")
		for child in w_cont.get_children():
			w_cont.remove_child(child)
			child.queue_free()
		for elem in unit.weaknesses:
			var w_lbl := Label.new()
			w_lbl.text = CombatConstants.get_element_symbol(elem)
			w_lbl.tooltip_text = CombatConstants.get_element_name(elem)
			w_lbl.add_theme_font_size_override("font_size", 14)
			w_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(elem))
			w_lbl.set_meta("elem", elem)
			w_cont.add_child(w_lbl)

	if vbox.has_node("TghBar"):
		var tgh_bar: ProgressBar = vbox.get_node("TghBar")
		tgh_bar.value = unit.toughness

	if vbox.has_node("EnergyBarOnCard"):
		var en_bar: ProgressBar = vbox.get_node("EnergyBarOnCard")
		if unit is Memosprite:
			var memo_sprite := unit as Memosprite
			var cur_c: float = memo_sprite.charge_comp.charge if memo_sprite.charge_comp != null else memo_sprite.energy
			var max_c: float = memo_sprite.charge_comp.max_charge if memo_sprite.charge_comp != null else 100.0
			en_bar.max_value = max_c
			en_bar.value = cur_c
			if vbox.has_node("ChargeLabelOnCard"):
				var charge_lbl: Label = vbox.get_node("ChargeLabelOnCard")
				if memo_sprite.definition != null and memo_sprite.definition.id == "antimatter_paws":
					charge_lbl.text = "Заряд: %d/4" % int(cur_c)
				else:
					charge_lbl.text = "Заряд: %d%%" % int(cur_c)
		else:
			en_bar.value = unit.energy
			en_bar.max_value = unit.max_energy

			if vbox.has_node("UltHotkeyLabel"):
				var ult_hotkey_lbl: Label = vbox.get_node("UltHotkeyLabel")
				var idx := battle_manager.allies.find(unit)
				if idx >= 0:
					ult_hotkey_lbl.text = "[%d]" % (idx + 1)

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

			if unit.id == "velzebul":
				var hearts: int = int(unit.get_meta("velzebul_sinful_hearts", 0))
				if hearts < 4:
					can_ult = false
					ult_btn.text = "★ Сверхспособность (%d/4 сердец)" % hearts

			if unit.id == "rimes_ascension":
				var crescendo: float = float(unit.get_meta("crescendo_stacks", 0.0))
				can_ult = crescendo >= 100.0
				en_bar.max_value = 100.0
				en_bar.value = crescendo
				ult_btn.text = "★ Крещендо (%.0f%%)" % crescendo

			ult_btn.disabled = not can_ult or battle_manager.phase != battle_manager.Phase.RUNNING
			_update_card_ult_button_style(unit, ult_btn, can_ult)
			
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
		
	if unit.id == "velzebul":
		var hearts := int(unit.get_meta("velzebul_sinful_hearts", 0))
		statuses.append("Сердца %d/4" % hearts)
		if bool(unit.get_meta("velzebul_in_offering", false)):
			statuses.append("Подношение")
	if unit.has_meta("velzebul_seal_turns") and int(unit.get_meta("velzebul_seal_turns", 0)) > 0:
		statuses.append("Печать (%d)" % int(unit.get_meta("velzebul_seal_turns", 0)))
	if unit.has_meta("velzebul_ice_quantum_res_turns") and int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)) > 0:
		statuses.append("Срез Рез. (%d)" % int(unit.get_meta("velzebul_ice_quantum_res_turns", 0)))

	if unit.id == "marina_sky_guardian":
		var zone_turns := int(unit.get_meta("marina_sk_elysium_zone_turns", 0))
		if zone_turns > 0:
			statuses.append("Зона: %d х." % zone_turns)
		var link_turns := int(unit.get_meta("marina_sk_link_turns", 0))
		if link_turns > 0:
			var linked_ally: CombatUnit = unit.get_meta("marina_sk_linked_ally", null)
			if linked_ally != null:
				statuses.append("Связь: %s (%d)" % [linked_ally.display_name, link_turns])
			else:
				statuses.append("Связь (%d)" % link_turns)

	if unit.has_meta("marina_sk_linked_by"):
		var marina: CombatUnit = unit.get_meta("marina_sk_linked_by", null)
		if marina != null and marina.is_alive():
			var l_turns := int(marina.get_meta("marina_sk_link_turns", 0))
			statuses.append("Связь Марины (%d)" % l_turns)
	elif unit is Memosprite and unit.owner != null and unit.owner.has_meta("marina_sk_linked_by"):
		var marina: CombatUnit = unit.owner.get_meta("marina_sk_linked_by", null)
		if marina != null and marina.is_alive():
			var l_turns := int(marina.get_meta("marina_sk_link_turns", 0))
			statuses.append("Связь Марины (%d)" % l_turns)

	if unit.id == "rimes_ascension":
		var c_stacks := float(unit.get_meta("crescendo_stacks", 0.0))
		statuses.append("Крещендо %.0f%%" % c_stacks)
		var t_stacks := int(unit.get_meta("talent_dmg_stacks", 0))
		if t_stacks > 0:
			statuses.append("Урон +%d%%" % (t_stacks * 20))
		var r_turns := int(unit.get_meta("rimes_rupture_zone_turns", 0))
		if r_turns > 0:
			statuses.append("Зона Разлома (%d)" % r_turns)

	if unit.id == "antimatter_paws" or (unit is Memosprite and (unit as Memosprite).definition != null and (unit as Memosprite).definition.id == "antimatter_paws"):
		var charges := int((unit as Memosprite).get_charge()) if unit is Memosprite and (unit as Memosprite).charge_comp != null else 1
		statuses.append("Заряды: %d/4" % charges)
		var t3_stacks := int(unit.get_meta("paws_trace3_stacks", 0))
		if t3_stacks > 0:
			statuses.append("Т3 x%d" % t3_stacks)
		
	# Статусы Сангинии Ял
	if unit.has_meta("sanguinia_special_guest_charges"):
		var guest_charges := int(unit.get_meta("sanguinia_special_guest_charges", 0))
		statuses.append("Особый гость: %d" % guest_charges)

	if unit.id == "sanguinia":
		var waves := int(unit.get_meta("sanguinia_waves", 0))
		statuses.append("Волны: %d/47" % waves)
		if unit.has_meta("sanguinia_e4_atk_turns") and int(unit.get_meta("sanguinia_e4_atk_turns", 0)) > 0:
			statuses.append("E4 СА+ (%d)" % int(unit.get_meta("sanguinia_e4_atk_turns", 0)))
		if unit.has_meta("sanguinia_e2_dmg_turns") and int(unit.get_meta("sanguinia_e2_dmg_turns", 0)) > 0:
			statuses.append("E2 Урон+ (%d)" % int(unit.get_meta("sanguinia_e2_dmg_turns", 0)))

	if unit.has_meta("sanguinia_q_atk_turns") and int(unit.get_meta("sanguinia_q_atk_turns", 0)) > 0:
		statuses.append("СА+ [Сангиния Q] (%d)" % int(unit.get_meta("sanguinia_q_atk_turns", 0)))

	if unit.has_meta("sanguinia_prep_atk_turns") and int(unit.get_meta("sanguinia_prep_atk_turns", 0)) > 0:
		statuses.append("СА+ [Готовьтесь] (%d)" % int(unit.get_meta("sanguinia_prep_atk_turns", 0)))

	if unit.has_meta("sanguinia_tech_spd_turns") and int(unit.get_meta("sanguinia_tech_spd_turns", 0)) > 0:
		statuses.append("СКР+ [Сангиния] (%d)" % int(unit.get_meta("sanguinia_tech_spd_turns", 0)))

	if unit.has_meta("sanguinia_talent_dmg_boost"):
		statuses.append("Урон+ 100% [Сангиния]")
		
	status_lbl.text = ", ".join(statuses) if not statuses.is_empty() else "—"

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

	if not unit.is_alive() and unit.has_meta("has_supernova_crater"):
		unit.remove_meta("has_supernova_crater")
		var decal = panel.get_node_or_null("SupernovaCraterDecal")
		if decal != null and is_instance_valid(decal):
			if decal.has_method("fade_out_and_remove"):
				decal.fade_out_and_remove()
			else:
				decal.queue_free()

	if not panel.has_meta("damage_tween"):
		panel.modulate = _get_unit_base_modulate(unit)
		
	if not unit.is_ally and unit.statuses.toughness_broken:
		LevelManager.on_toughness_broken(self)
	
	_update_console_hud()
	_update_antimatter_hud()
	_update_moon_maiden_hud()
	
	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()
	
	if unit.id == "lenskaya_antimatter":
		_update_lenskaya_antimatter_card_vfx(unit, panel)

	if panel.has_node("TargetReticle"):
		panel.get_node("TargetReticle").queue_redraw()
	if vbox.has_node("TghBar"):
		vbox.get_node("TghBar").queue_redraw()
	
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
	
	inspect_overlay.z_index = 100
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
	
	if unit is Memosprite:
		_inspect_tag_label.text = "ДУХ ПАМЯТИ"
		_style_tag_pill(_inspect_tag_label, Color(0.08, 0.25, 0.35, 0.9), Color(0.3, 0.75, 1.0, 0.85), Color(0.5, 0.9, 1.0))
	elif unit.is_ally:
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
	
	inspect_overlay.z_index = 100
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
	formatted = formatted.replace("⚔ [НАВЫК]", "\n\n[b][color=#38bdf8]⚔ [НАВЫК][/color][/b]")
	formatted = formatted.replace("🔷 [НАВЫК]", "\n\n[b][color=#38bdf8]🔷 [НАВЫК][/color][/b]")
	formatted = formatted.replace("✨ [НАВЫК]", "\n\n[b][color=#38bdf8]✨ [НАВЫК][/color][/b]")
	formatted = formatted.replace("💡 [ТАЛАНТ]", "\n\n[b][color=#34d399]💡 [ТАЛАНТ][/color][/b]")
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
		elif line.begins_with("Заряд"):
			var colon_idx := line.find(":")
			var val_part := line.substr(colon_idx + 1).strip_edges() if colon_idx != -1 else line.substr(5).strip_edges()
			result.append("[b][color=#38bdf8]Заряд:[/color][/b] " + val_part)
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
	_factions_open = false
	_admin_open = false
	if graphs_panel: graphs_panel.hide()
	if factions_panel: factions_panel.hide()
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
			var can_target_ally: bool = show_allies and unit.is_alive()
			if can_target_ally and active_char != null and active_char.id == "marina_sky_guardian" and _target_mode == "skill":
				if unit is Memosprite or bool(unit.get_meta("is_memosprite", false)):
					can_target_ally = false
			btn.visible = can_target_ally
			if can_target_ally:
				btn.disabled = false
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
			if can_target_enemy:
				btn.disabled = false

	if show_enemies or show_allies:
		var valid_targets: Array[CombatUnit] = []
		for u in _unit_panels:
			var p: PanelContainer = _unit_panels[u]
			var vbox_node: VBoxContainer = p.get_child(0)
			var b: Button = vbox_node.get_node_or_null("TargetButton")
			if b and b.visible and u.is_alive():
				valid_targets.append(u)
		if not valid_targets.has(_selected_target_unit):
			if not valid_targets.is_empty():
				_selected_target_unit = valid_targets[0]
			else:
				_selected_target_unit = null
	else:
		_selected_target_unit = null

	_update_targeting_visuals()
					
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
	var shown_count: int = 0
	
	for i in order.size():
		if shown_count >= 7:
			break
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
		# Компактный размер маркера вертикальной шкалы
		icon.custom_minimum_size = Vector2(48, 48) 
		icon.color = _unit_color(unit)
		icon.tooltip_text = unit.display_name

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 1)
		icon.add_child(vbox)

		# Первая буква имени
		var lbl_name := Label.new()
		if unit.id == "moon_maiden":
			lbl_name.text = "🌙"
		else:
			lbl_name.text = unit.display_name.substr(0, 1)
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_name.add_theme_font_size_override("font_size", 16)
		vbox.add_child(lbl_name)

		# Оставшийся ИД до хода
		var lbl_av := Label.new()
		lbl_av.text = str(int(accumulated_av_simulation))
		lbl_av.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_av.add_theme_font_size_override("font_size", 11)
		lbl_av.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(lbl_av)

		if i == 0:
			icon.modulate = Color(1.2, 1.2, 1.0)

		action_bar.add_child(icon)
		shown_count += 1

func _unit_color(unit: CombatUnit) -> Color:
	if unit.id == "moon_maiden":
		return Color(1.0, 0.85, 0.4)
	if unit is Memosprite:
		return Color(0.45, 0.85, 1.0)
	if unit.is_ally:
		if unit.id == "marina_sky_guardian":
			return Color(0.4, 0.85, 0.7)
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
		if unit.id == "rimes" or unit.id == "rimes_ascension":
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
	turn_label.text = "Цикл: %d | Ход: %s" % [battle_manager.get_current_cycles(), unit.display_name]
	
	if _target_mode != "ult" and _target_mode != "chorus":
		_selecting_target = false
		_target_mode = ""
		_set_target_buttons_visible(false, false)
		_multi_targets.clear()
		_selected_target_unit = null
		
	_refresh_action_bar()
	_refresh_graphs_panel()
	_refresh_support_button() 

	for u in _unit_panels:
		_refresh_unit_panel(u)

	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()

	_highlight_active_unit(unit)

	if unit.id == "moon_maiden":
		action_panel.hide()
		_update_targeting_visuals()
		return

	if unit is Memosprite:
		action_panel.hide()
		if unit.has_meta("ego_ready_for_reality"):
			_target_mode = "ego_reality"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[❄ %s: Выберите цель для умения «Реальность»!]" % unit.display_name)
		_update_targeting_visuals()
		return

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
	else:
		action_panel.hide()
		if _skills_help_open:
			skills_text.text = "Ход противника: %s" % unit.display_name

	_update_targeting_visuals()
	LevelManager.on_turn_started(unit, self)
			
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
		or unit.id == "lenskaya_antimatter"
		or unit.id == "velzebul"
		or unit.id == "marina_sky_guardian"
		or unit.id == "lenskaya_sky_guardian"
		or unit.id == "rimes_ascension"
		or unit.id == "sanguinia"
	)

	match unit.id:
		"sanguinia":
			btn_basic.visible = true
			btn_basic.disabled = false
			btn_basic.text = "🔥 Базовая (+1 ОН)"
			btn_enhanced_basic.visible = false
			
			btn_skill.visible = true
			btn_skill.text = "🔷 Навык Q (1 ОН) — Продвижение"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			btn_skill_e.visible = true
			btn_skill_e.text = "🍸 Навык E (2 ОН) — Особый гость"
			btn_skill_e.disabled = battle_manager.skill_points < 2
		"rimes_ascension":
			btn_basic.text = "⚔ Базовая (+1 ОН)"
			btn_basic.disabled = false
			var paws := battle_manager.get_antimatter_paws_sprite()
			var has_paws := paws != null and paws.is_alive()
			if has_paws:
				btn_skill.text = "💫 Усил. Q (0 ОН) — Слияние"
			else:
				btn_skill.text = "💫 Навык Q (0 ОН) — 90% ХП"
			btn_skill.disabled = false
			var e_cost: int = 1 if has_paws else 2
			if has_paws:
				btn_skill_e.text = "🐾 Навык E (%d ОН) — Усиление" % e_cost
			else:
				btn_skill_e.text = "🐾 Навык E (%d ОН) — Призыв Лап" % e_cost
			btn_skill_e.disabled = battle_manager.skill_points < e_cost
		"lenskaya_sky_guardian":
			var is_enhanced: bool = unit.has_meta("lenskaya_enhanced_basic_turns") and int(unit.get_meta("lenskaya_enhanced_basic_turns", 0)) > 0
			btn_basic.visible = not is_enhanced
			btn_basic.disabled = is_enhanced
			btn_basic.text = "⚔ Базовая (+1 ОН)"
			btn_enhanced_basic.visible = is_enhanced
			btn_enhanced_basic.disabled = not is_enhanced
			btn_enhanced_basic.text = "🏹 Усиленная базовая (6 уд.)"
			
			btn_skill.text = "✨ Навык Q (1 ОН)"
			btn_skill.disabled = battle_manager.skill_points < 1
			
			var e1_free := unit.eidolon >= 1 and not unit.has_meta("lenskaya_e1_used")
			var e_cost := 1 if e1_free else 2
			btn_skill_e.text = "💥 Навык E (%d ОН)" % e_cost
			btn_skill_e.disabled = battle_manager.skill_points < e_cost
		"marina_sky_guardian":
			btn_basic.text = "⚔ Базовая (+1 ОН)"
			btn_skill.text = "🔗 Навык Q (1 ОН) — Связь"
			btn_skill_e.disabled = battle_manager.skill_points < 2
			var ego := battle_manager.get_ego_memosprite()
			if ego != null and ego.is_alive():
				btn_skill_e.text = "✨ Навык E (2 ОН) — Очищение"
			else:
				btn_skill_e.text = "🕊 Навык E (2 ОН) — Призыв Эго"
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
				btn_basic.text = "⚔ Базовая (70% СА)"
				btn_skill.text = "🔷 Усил. Q" + sp_cost_q
				btn_skill.disabled = not (unit.eidolon >= 2 or battle_manager.skill_points >= 1)
			else:
				btn_basic.text = "⚔ Базовая (70% СА)"
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
				btn_enhanced_basic.text = "⚔ Усил. Базовая (125%/35%)"
			else:
				btn_basic.visible = true
				btn_basic.disabled = false
				btn_basic.text = "⚔ Базовая (95% СА)"
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
		"lenskaya_antimatter":
			var stance: String = String(unit.get_meta("lenskaya_am_stance", "none"))
			var x_val: int = battle_manager.get_xaeroh()
			var in_stance: bool = stance in ["keeper", "warrior"]
			
			if in_stance:
				btn_basic.visible = false
				btn_basic.disabled = true
				btn_enhanced_basic.visible = true
				btn_enhanced_basic.disabled = false
				btn_enhanced_basic.text = "💥 Усиленная атака (120% СА)"
			else:
				btn_basic.visible = true
				btn_basic.disabled = false
				btn_basic.text = "⚔ Базовая (100% СА)"
				btn_enhanced_basic.visible = false
				btn_enhanced_basic.disabled = true
				
			btn_skill_e.visible = true
			match stance:
				"none":
					btn_skill.text = "🔷 Навык Q (1 ОН)"
					btn_skill.disabled = battle_manager.skill_points < 1
					btn_skill_e.text = "🔹 Навык E (2 ОН)"
					btn_skill_e.disabled = battle_manager.skill_points < 2
				"keeper":
					btn_skill.text = "🔷 Навык Q (30 Xaeroh)"
					btn_skill.disabled = x_val < 30
					if x_val < 30:
						btn_skill_e.text = "♻ Сброс (+25 Энерг., 100% AV)"
						btn_skill_e.disabled = false
					else:
						btn_skill_e.text = "🔹 Навык E (60 Xaeroh)"
						btn_skill_e.disabled = x_val < 60
				"warrior":
					var in_inv := bool(unit.get_meta("lenskaya_am_in_inverted", false))
					if in_inv:
						btn_skill.text = "🔷 Навык Q (В изнанке, 30 Xaeroh)"
					else:
						btn_skill.text = "🔷 Навык Q (30 Xaeroh)"
					btn_skill.disabled = x_val < 30
					if x_val < 30:
						btn_skill_e.text = "♻ Сброс (+25 Энерг., 100% AV)"
						btn_skill_e.disabled = false
					else:
						btn_skill_e.text = "🔹 Навык E (60 Xaeroh)"
						btn_skill_e.disabled = x_val < 60 or in_inv
		"velzebul":
			var in_offering: bool = bool(unit.get_meta("velzebul_in_offering", false))
			var hearts: int = int(unit.get_meta("velzebul_sinful_hearts", 0))
			var is_e_enhanced: bool = bool(unit.get_meta("velzebul_e_enhanced", false)) or hearts >= 4
			
			if in_offering:
				btn_basic.visible = false
				btn_basic.disabled = true
				btn_enhanced_basic.visible = true
				btn_enhanced_basic.disabled = false
				btn_enhanced_basic.text = "💥 Усил. Базовая (190% СА, 0 ОН)"
				
				btn_skill_e.visible = true
				btn_skill_e.text = "🔹 Подношение (%d/4 сердец)" % hearts
				btn_skill_e.disabled = true
			else:
				btn_basic.visible = true
				btn_basic.disabled = false
				btn_basic.text = "⚔ Базовая (100% СА, +1 ОН)"
				btn_enhanced_basic.visible = false
				btn_enhanced_basic.disabled = true
				
				btn_skill_e.visible = true
				if is_e_enhanced:
					btn_skill_e.text = "🔹 Усил. Навык E (1 ОН) — Печать"
					btn_skill_e.disabled = battle_manager.skill_points < 1
				else:
					btn_skill_e.text = "🔹 Навык E (2 ОН) — Подношение"
					btn_skill_e.disabled = battle_manager.skill_points < 2
					
			btn_skill.text = "🔷 Навык Q (1 ОН) — Рой (+15 Зеро)"
			btn_skill.disabled = battle_manager.skill_points < 1
		_:
			btn_basic.text = "⚔ Базовая"
			btn_skill.text = "🔷 Навык Q"
			btn_skill_e.text = "🔹 Навык E"

	vbox_basic.visible = btn_basic.visible or btn_enhanced_basic.visible
	vbox_skill_q.visible = btn_skill.visible
	vbox_skill_e.visible = btn_skill_e.visible

func _on_turn_ended(_unit: CombatUnit) -> void:
	_multi_targets.clear()
	_set_target_buttons_visible(false, false)
	_reset_active_unit_visual()
	_hide_skill_tooltip()
	_selected_target_unit = null
	_update_targeting_visuals()
	if is_instance_valid(_unit) and _unit.has_meta("has_supernova_crater"):
		_unit.remove_meta("has_supernova_crater")
		if _unit_panels.has(_unit) and is_instance_valid(_unit_panels[_unit]):
			var p: PanelContainer = _unit_panels[_unit]
			var decal = p.get_node_or_null("SupernovaCraterDecal")
			if decal != null and is_instance_valid(decal):
				if decal.has_method("fade_out_and_remove"):
					decal.fade_out_and_remove()
				else:
					decal.queue_free()
	for u in _unit_panels:
		_refresh_unit_panel(u)
	_refresh_action_bar()
	_refresh_graphs_panel()
	_check_update_spirit_form_vfx()
	_check_update_doceva_zone_vfx()

func _on_sp_changed(points: int) -> void:
	skill_points_label.text = "ОН: %d / %d" % [points, CombatConstants.MAX_SKILL_POINTS]
	for child in skill_points_pips.get_children():
		skill_points_pips.remove_child(child)
		child.queue_free()
	for i in range(CombatConstants.MAX_SKILL_POINTS):
		var pip := Label.new()
		if i < points:
			pip.text = "◆"
			pip.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
		else:
			pip.text = "◇"
			pip.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55, 0.6))
		pip.add_theme_font_size_override("font_size", 16)
		skill_points_pips.add_child(pip)

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
	elif unit.id == "rimes_ascension":
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
	elif unit.id == "lenskaya_antimatter":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите цель для Навыка Q Ленской]")
	elif unit.id == "marina_sky_guardian":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для связи Навыка Q]")
	elif unit.id == "lenskaya_sky_guardian":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка Q (наложение статуса «Враг Свечения»)]")
	elif unit.id == "sanguinia":
		_target_mode = "skill"
		_selecting_target = true
		_set_target_buttons_visible(false, true)
		_on_log("[Выберите союзника для Навыка Q (продвижение на 100% и +40% СА)]")
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
	elif unit.id == "lenskaya_antimatter":
		var stance: String = String(unit.get_meta("lenskaya_am_stance", "none"))
		if stance == "none":
			_target_mode = "skill_e"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[Выберите противника для Навыка E Ленской]")
		else:
			battle_manager.player_skill_e(null)
	elif unit.id == "velzebul":
		var is_enh: bool = bool(unit.get_meta("velzebul_e_enhanced", false))
		if is_enh:
			_target_mode = "skill_e"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_on_log("[Выберите главную цель для Усиленного Навыка E (соседи получат урон)]")
		else:
			battle_manager.player_skill_e(null)
	elif unit.id == "lenskaya_sky_guardian":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для Навыка E Ленской (300% СА, 30 стойкости)]")
	elif unit.id == "rimes_ascension":
		battle_manager.player_skill_e(null)
	elif unit.id == "sanguinia":
		_target_mode = "skill_e"
		_selecting_target = true
		_set_target_buttons_visible(true, false)
		_on_log("[Выберите противника для наложения статуса «Особый гость» (2 ОН)]")
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
	
	if unit.id == "rimes_ascension":
		var crescendo: float = float(unit.get_meta("crescendo_stacks", 0.0))
		if crescendo < 100.0:
			_on_log("[Сверхспособность Раймса заблокирована: нужно накопить 100%% Крещендо (сейчас: %.0f%%)!]" % crescendo)
			return

	if unit.id == "velzebul":
		var hearts: int = int(unit.get_meta("velzebul_sinful_hearts", 0))
		if hearts < 4:
			_on_log("[Сверхспособность Вельзевул заблокирована: нужно собрать 4 Грешных сердца (%d/4)!]" % hearts)
			return

	if unit.id == "lenskaya_antimatter":
		if unit.energy < unit.max_energy:
			return
		_show_lenskaya_am_ult_modal(unit)
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
		or unit.id == "arseniy_admin"
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
		_selected_target_unit = unit
		_update_targeting_visuals()
		match _target_mode:
			"ego_reality":
				if is_ally:
					return
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				_target_mode = ""
				var current_u := battle_manager.current_unit
				if current_u is Memosprite:
					battle_manager.player_memosprite_reality(current_u as Memosprite, unit)
			"chorus":
				if not is_ally:
					return
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				_target_mode = ""
				_execute_chorus_ui(unit)
			"basic", "enhanced_basic":
				if is_ally:
						return
				_selecting_target = false
				_set_target_buttons_visible(false, false)
				
				# Оповещаем обучение про клик
				if LevelManager.is_tutorial:
					if _target_mode == "basic":
						LevelManager.on_action_pressed("basic_target_selected", self)
					else:
						LevelManager.on_action_pressed("enhanced_basic_target_selected", self)
				
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
					if LevelManager.is_tutorial:
						LevelManager.on_action_pressed("ult_target_selected", self)
					
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
					or (current_char_id == "marina_sky_guardian" and _target_mode == "skill")
					or (current_char_id == "sanguinia" and _target_mode == "skill")
				)
				
				if targets_allies:
					if not is_ally:
						return
					if current_char_id == "marina_sky_guardian" and _target_mode == "skill" and (unit is Memosprite or bool(unit.get_meta("is_memosprite", false))):
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
	if is_instance_valid(support_panel):
		support_panel.hide()
	if is_instance_valid(chorus_dark_overlay):
		chorus_dark_overlay.hide()
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
	
func _get_unit_base_modulate(unit: CombatUnit) -> Color:
	if not _unit_panels.has(unit):
		return Color.WHITE
	var panel: PanelContainer = _unit_panels[unit]
	if panel == _highlighted_unit_panel:
		return Color(1.25, 1.25, 1.25, 1.0)
	elif unit in _multi_targets:
		return Color(1.2, 1.0, 0.6)
	elif not unit.is_alive():
		return Color(0.4, 0.4, 0.4, 0.7)
	elif unit.is_elite:
		return Color(1.1, 0.85, 1.0)
	return Color.WHITE

func _play_damage_flash(unit: CombatUnit) -> void:
	if not _unit_panels.has(unit):
		return
	var panel: PanelContainer = _unit_panels[unit]
	if not is_instance_valid(panel):
		return
	
	if panel.has_meta("damage_tween"):
		var old_tw = panel.get_meta("damage_tween")
		if old_tw != null and is_instance_valid(old_tw) and (old_tw is Tween) and (old_tw as Tween).is_valid():
			(old_tw as Tween).kill()
		panel.remove_meta("damage_tween")
	
	var base_mod: Color = _get_unit_base_modulate(unit)
	var flash_mod_1: Color = Color(1.35, 1.35, 1.35, 1.0)
	var flash_dim_1: Color = Color(0.65, 0.65, 0.65, 0.85)
	var flash_mod_2: Color = Color(1.20, 1.20, 1.20, 1.0)
	var flash_dim_2: Color = Color(0.75, 0.75, 0.75, 0.90)
	
	var tw: Tween = create_tween()
	panel.set_meta("damage_tween", tw)
	
	tw.tween_property(panel, "modulate", flash_mod_1, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate", flash_dim_1, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate", flash_mod_2, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate", flash_dim_2, 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate", base_mod, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tw.finished.connect(func():
		if is_instance_valid(panel):
			panel.remove_meta("damage_tween")
			panel.modulate = _get_unit_base_modulate(unit)
	)

func _on_combat_text_spawned(unit: CombatUnit, text: String, color: Color, tag: String, is_crit: bool) -> void:
	if not _unit_panels.has(unit):
		return
	
	var is_damage: bool = (text.is_valid_int() and int(text) > 0) or (text.begins_with("-") and text.substr(1).is_valid_int() and int(text.substr(1)) > 0)
	if is_damage and unit != null and is_instance_valid(unit):
		_play_damage_flash(unit)
	
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
	
	if tag == "MemospriteTalent" or tag == "MemospriteSkill":
		display_tag = ""
	
	var panel_rect := panel.get_global_rect()
	var center_pos := panel_rect.position + panel_rect.size * 0.5
	var random_offset := Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
	
	var fct := FloatingText.new(text, color, 25, display_tag, is_crit, secondary_color)
	fct.z_index = 100
	fct.global_position = center_pos + random_offset - fct.custom_minimum_size * 0.5
	add_child(fct)
	
class FloatingText extends Control:
	var vbox: VBoxContainer
	var label: Label
	var tag_label: Label
	var drift_duration: float = 0.85
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
		
		tween.tween_property(self, "global_position:y", global_position.y - 45.0, drift_duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
		scale = Vector2(0.4, 0.4)
		pivot_offset = custom_minimum_size * 0.5
		var scale_tween := create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)
		
		# ИСПРАВЛЕНО: Анимация цвета через tween_method с вызовом add_theme_color_override!
		if has_sheen:
			var sheen_tween := create_tween().set_loops()
			sheen_tween.tween_method(func(c: Color): label.add_theme_color_override("font_color", c), elem_color, sheen_color, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			sheen_tween.tween_method(func(c: Color): label.add_theme_color_override("font_color", c), sheen_color, elem_color, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		var fade_tween := create_tween()
		fade_tween.tween_interval(0.40)
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_LINEAR)
		
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

func _update_lenskaya_antimatter_card_vfx(unit: CombatUnit, panel: PanelContainer) -> void:
	if not is_instance_valid(panel):
		return
		
	var has_keeper := panel.has_node("LenskayaKeeperOrbs")
	var has_warrior := panel.has_node("LenskayaWarriorLightning")
	var has_aura := panel.has_node("KeeperSpeedAura")
	
	if not unit.is_alive():
		if has_keeper:
			panel.get_node("LenskayaKeeperOrbs").queue_free()
		if has_warrior:
			panel.get_node("LenskayaWarriorLightning").queue_free()
		if has_aura:
			panel.get_node("KeeperSpeedAura").queue_free()
		return

	# Навык E Хранитель Ничто: светящаяся фиолетовая рамка со скоростью
	var spd_buff: int = int(unit.get_meta("lenskaya_am_spd_buff_turns", 0))
	if spd_buff > 0:
		if not has_aura:
			var aura := KeeperSpeedAura.new(panel)
			panel.add_child(aura)
	else:
		if has_aura:
			panel.get_node("KeeperSpeedAura").queue_free()

	# Навык E Воин Небытия: полупрозрачность в состоянии "В изнанке"
	var in_inv := bool(unit.get_meta("lenskaya_am_in_inverted", false))
	if in_inv:
		panel.modulate.a = 0.38
	elif panel.modulate.a < 0.9:
		panel.modulate.a = 1.0

	var stance: String = String(unit.get_meta("lenskaya_am_stance", "none"))
	match stance:
		"keeper":
			if has_warrior:
				panel.get_node("LenskayaWarriorLightning").queue_free()
			if not has_keeper:
				var orbs := LenskayaKeeperOrbs.new(panel)
				panel.add_child(orbs)
		"warrior":
			if has_keeper:
				panel.get_node("LenskayaKeeperOrbs").queue_free()
			if not has_warrior:
				var lightning := LenskayaWarriorLightning.new(panel)
				panel.add_child(lightning)
		_:
			if has_keeper:
				panel.get_node("LenskayaKeeperOrbs").queue_free()
			if has_warrior:
				panel.get_node("LenskayaWarriorLightning").queue_free()

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

# === ЭФФЕКТЫ ЛЕНСКОЙ: ХРАНИТЕЛЬ НИЧТО, ВОИН НЕБЫТИЯ, УНИЧТОЖЕНИЕ СВЕРХНОВОЙ ===

class LenskayaKeeperOrbs extends Control:
	var _time: float = 0.0
	var _parent_panel: PanelContainer = null
	
	var _orb_in_orbit: Array[bool] = [true, true, true, true, true, true, true, true]
	var _respawn_alpha: float = 1.0
	var _is_respawning: bool = false
	
	func _init(panel: PanelContainer) -> void:
		_parent_panel = panel
		name = "LenskayaKeeperOrbs"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
	func _process(delta: float) -> void:
		_time += delta
		if _is_respawning:
			_respawn_alpha += delta * 1.6
			if _respawn_alpha >= 1.0:
				_respawn_alpha = 1.0
				_is_respawning = false
				for i in range(8):
					_orb_in_orbit[i] = true
		queue_redraw()

	func peel_off_orb(idx: int) -> Vector2:
		var i := idx % 8
		_orb_in_orbit[i] = false
		queue_redraw()
		return get_orb_global_pos(i)

	func start_respawn() -> void:
		_is_respawning = true
		_respawn_alpha = 0.0
		for i in range(8):
			_orb_in_orbit[i] = true
		queue_redraw()

	func get_orb_global_pos(i: int) -> Vector2:
		if not is_instance_valid(_parent_panel):
			return global_position
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			p_size = Vector2(160.0, 220.0)
		var center: Vector2 = p_size * 0.5
		var rx: float = p_size.x * 0.52 + 8.0
		var ry: float = p_size.y * 0.48 + 8.0
		var orb_count := 8
		var angle: float = _time * 0.25 + float(i) * (TAU / float(orb_count))
		var bobbing: float = sin(_time * 1.6 + float(i) * 1.2) * 6.0
		var local_pos := center + Vector2(cos(angle) * rx, sin(angle) * ry + bobbing)
		return global_position + local_pos
		
	func _draw() -> void:
		if not is_instance_valid(_parent_panel):
			return
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			p_size = Vector2(160.0, 220.0)
		var center: Vector2 = p_size * 0.5
		# Радиус орбиты ближе к Ленской (облегает карточку)
		var rx: float = p_size.x * 0.52 + 8.0
		var ry: float = p_size.y * 0.48 + 8.0
		
		var orb_count := 8
		for i in range(orb_count):
			if not _orb_in_orbit[i]:
				continue
			var angle: float = _time * 0.25 + float(i) * (TAU / float(orb_count))
			var bobbing: float = sin(_time * 1.6 + float(i) * 1.2) * 6.0
			var orb_pos: Vector2 = center + Vector2(cos(angle) * rx, sin(angle) * ry + bobbing)
			
			var pulse: float = 0.88 + 0.12 * sin(_time * 2.0 + float(i))
			var a_mult: float = _respawn_alpha
			# Полупрозрачные мистические чёрно-фиолетовые сферы
			# 1. Внешний рассеянный фиолетовый ореол
			draw_circle(orb_pos, 30.0 * pulse, Color(0.35, 0.05, 0.60, 0.08 * a_mult))
			# 2. Среднее фиолетовое сияние
			draw_circle(orb_pos, 20.0 * pulse, Color(0.55, 0.15, 0.85, 0.14 * a_mult))
			# 3. Энергетическое кольцо
			draw_arc(orb_pos, 14.0 * pulse, 0.0, TAU, 28, Color(0.75, 0.35, 1.0, 0.22 * a_mult), 1.8)
			# 4. Полупрозрачное тёмное ядро пустоты
			draw_circle(orb_pos, 9.5 * pulse, Color(0.04, 0.01, 0.09, 0.26 * a_mult))
			# 5. Тонкий мистический блик
			draw_circle(orb_pos + Vector2(-2.8, -2.8), 2.5, Color(0.95, 0.85, 1.0, 0.35 * a_mult))

class LenskayaWarriorLightning extends Control:
	var _parent_panel: PanelContainer = null
	var _timer: float = 0.0
	var _next_flash: float = 0.6
	var _active_bolts: Array[Dictionary] = []
	var _had_bolts_last_frame: bool = false
	
	func _init(panel: PanelContainer) -> void:
		_parent_panel = panel
		name = "LenskayaWarriorLightning"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_next_flash = randf_range(0.5, 1.0)

	func _process(delta: float) -> void:
		var need_redraw := false
		_timer += delta
		
		# Затухание молний
		var remaining: Array[Dictionary] = []
		for b in _active_bolts:
			b.alpha -= delta * 4.8
			if b.alpha > 0.0:
				remaining.append(b)
				need_redraw = true
		_active_bolts = remaining
		
		# Заряженный ритм: 1-2 резкие молнии каждые 0.35 - 0.70 сек
		if _timer >= _next_flash:
			_timer = 0.0
			_next_flash = randf_range(0.35, 0.70)
			var count := 1 if randf() < 0.40 else 2
			for c in range(count):
				_spawn_single_sharp_bolt()
			need_redraw = true
				
		var has_active := not _active_bolts.is_empty()
		if has_active or need_redraw or _had_bolts_last_frame:
			queue_redraw()
		_had_bolts_last_frame = has_active
			
	func _spawn_single_sharp_bolt() -> void:
		if not is_instance_valid(_parent_panel):
			return
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			p_size = Vector2(160.0, 220.0)
			
		var center := p_size * 0.5
		var angle := randf_range(0.0, TAU)
		var dir := Vector2(cos(angle), sin(angle)).normalized()
		var start := center + dir * randf_range(p_size.x * 0.20, p_size.x * 0.40)
		
		var pts := PackedVector2Array()
		pts.append(start)
		var cur := start
		var steps := randi_range(3, 5)
		var step_len := randf_range(20.0, 32.0)
		var branches: Array[PackedVector2Array] = []
		
		for s in range(steps):
			var angle_offset := randf_range(-0.85, 0.85)
			var step_dir := dir.rotated(angle_offset)
			cur += step_dir * step_len
			pts.append(cur)
			
			if randf() < 0.25:
				var b_pts := PackedVector2Array()
				var b_cur := cur
				b_pts.append(b_cur)
				var b_dir := step_dir.rotated(randf_range(-0.9, 0.9))
				for bs in range(2):
					b_cur += b_dir * randf_range(12.0, 18.0)
					b_pts.append(b_cur)
				branches.append(b_pts)
				
		var bolt_width: float = randf_range(1.8, 2.6)
		_active_bolts.append({
			"pts": pts,
			"branches": branches,
			"alpha": 1.0,
			"width": bolt_width
		})

	func _draw() -> void:
		for b in _active_bolts:
			var a: float = b.alpha
			var pts: PackedVector2Array = b.pts
			if pts.size() >= 2:
				var w: float = b.width
				# Нежный полупрозрачный фиолетовый ореол
				draw_polyline(pts, Color(0.65, 0.15, 0.95, a * 0.25), w + 3.0)
				# Острая фиолетовая грань
				draw_polyline(pts, Color(0.85, 0.35, 1.0, a * 0.50), w + 1.0)
				# Чёрная сердцевина
				draw_polyline(pts, Color(0.04, 0.01, 0.08, a * 0.65), maxf(1.0, w - 0.8))
				# Тонкий блик
				draw_polyline(pts, Color(0.95, 0.90, 1.0, a * 0.40), 0.8)

			var branches: Array = b.get("branches", [])
			for br in branches:
				var b_pts: PackedVector2Array = br
				if b_pts.size() >= 2:
					var bw: float = maxf(1.0, b.width * 0.5)
					draw_polyline(b_pts, Color(0.65, 0.15, 0.95, a * 0.20), bw + 2.0)
					draw_polyline(b_pts, Color(0.85, 0.35, 1.0, a * 0.40), bw)
					draw_polyline(b_pts, Color(0.04, 0.01, 0.08, a * 0.55), 0.8)

class SupernovaCraterDecal extends Control:
	var _alpha: float = 0.0
	var _target_alpha: float = 0.70
	var _fading_out: bool = false
	var _parent_panel: PanelContainer = null
	var _time: float = 0.0
	var _cracks: Array[PackedVector2Array] = []

	func _init(panel: PanelContainer) -> void:
		_parent_panel = panel
		name = "SupernovaCraterDecal"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		show_behind_parent = true
		z_index = -1
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_generate_cracks()
		var tw := create_tween()
		tw.tween_property(self, "_alpha", _target_alpha, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	func _generate_cracks() -> void:
		_cracks.clear()
		var count := 10
		for i in range(count):
			var pts := PackedVector2Array()
			var base_angle: float = float(i) * (TAU / float(count)) + randf_range(-0.25, 0.25)
			var base_dir := Vector2(cos(base_angle), sin(base_angle))
			var cur := Vector2.ZERO
			pts.append(cur)
			var segs := randi_range(3, 5)
			var seg_len := randf_range(20.0, 38.0)
			for s in range(segs):
				var ang_off := randf_range(-0.35, 0.35)
				var dir := base_dir.rotated(ang_off).normalized()
				cur += dir * seg_len
				pts.append(cur)
			_cracks.append(pts)

	func fade_out_and_remove() -> void:
		if _fading_out:
			return
		_fading_out = true
		var tw := create_tween()
		tw.tween_property(self, "_alpha", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if _alpha <= 0.001 or not is_instance_valid(_parent_panel):
			return
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			p_size = Vector2(160.0, 220.0)
		# Располагается строго ЗА карточкой врага (в центре)
		var center := p_size * 0.5
		
		var pulse: float = 0.92 + 0.08 * sin(_time * 2.0)
		var a: float = _alpha * pulse
		
		# 1. Тёмная прожжённая воронка пустоты (эллипс позади карточки врага)
		var rx: float = p_size.x * 0.92
		var ry: float = p_size.y * 0.74
		for ring in range(6, 0, -1):
			var frac: float = float(ring) / 6.0
			var pts := PackedVector2Array()
			var ring_steps := 32
			for s in range(ring_steps + 1):
				var ang: float = float(s) * (TAU / float(ring_steps))
				pts.append(center + Vector2(cos(ang) * rx * frac, sin(ang) * ry * frac))
			draw_colored_polygon(pts, Color(0.03, 0.005, 0.07, a * 0.22 * frac))

		# 2. Внешняя фиолетовая опалина разлома
		var outer_ring := PackedVector2Array()
		for s in range(36 + 1):
			var ang: float = float(s) * (TAU / 36.0)
			outer_ring.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
		draw_polyline(outer_ring, Color(0.65, 0.18, 0.95, a * 0.45), 2.5)

		# 3. Расходящиеся во все стороны космические трещины
		for pts in _cracks:
			var world_pts := PackedVector2Array()
			for pt in pts:
				world_pts.append(center + pt)
			# Свечение трещин
			draw_polyline(world_pts, Color(0.80, 0.30, 1.0, a * 0.60), 3.2)
			# Внутренняя тёмная линия разлома
			draw_polyline(world_pts, Color(0.05, 0.0, 0.10, a * 0.85), 1.6)

# Светящаяся полупрозрачная фиолетовая рамка для Навыка E Хранителя
class KeeperSpeedAura extends Control:
	var _parent_panel: PanelContainer = null
	var _time: float = 0.0

	func _init(panel: PanelContainer) -> void:
		_parent_panel = panel
		name = "KeeperSpeedAura"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(_parent_panel):
			return
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			return
		var pulse: float = 0.75 + 0.25 * sin(_time * 2.8)
		var rect := Rect2(Vector2.ZERO, p_size)
		# Внешний мягкий ореол
		draw_rect(rect.grow(4.0), Color(0.60, 0.15, 0.95, 0.20 * pulse), false, 4.0)
		# Средняя фиолетовая рамка
		draw_rect(rect.grow(2.0), Color(0.78, 0.35, 1.0, 0.40 * pulse), false, 2.5)
		# Внутренняя яркая линия
		draw_rect(rect, Color(0.92, 0.70, 1.0, 0.65 * pulse), false, 1.5)

# Медленно и редко пульсирующая фиолетовая рамка для кнопки ульты Ленской
class LenskayaUltBtnPulse extends Node:
	var btn: Button
	var time: float = 0.0
	var sb: StyleBoxFlat
	
	func _init(target_btn: Button) -> void:
		name = "LenskayaUltBtnPulse"
		btn = target_btn
		sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.04, 0.22, 0.95)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.70, 0.25, 0.95, 0.85)
		sb.shadow_color = Color(0.70, 0.20, 1.0, 0.35)
		sb.shadow_size = 3
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color", Color(0.92, 0.82, 1.0))
		
	func _process(delta: float) -> void:
		time += delta
		# Период ~5.2с: очень медленное и редкое дыхание
		var wave: float = (sin(time * 1.2) + 1.0) * 0.5
		var pulse: float = pow(wave, 2.5)
		var c := Color(0.55 + 0.35 * pulse, 0.15 + 0.25 * pulse, 0.85 + 0.15 * pulse, 0.65 + 0.35 * pulse)
		sb.border_color = c
		sb.shadow_color = Color(0.70, 0.20, 1.0, 0.20 + 0.30 * pulse)
		sb.shadow_size = int(2.0 + 4.0 * pulse)

# Полет и детонация сфер Навыка Q Хранителя Ничто (запуск именно тех сфер, что кружат вокруг неё)
class LenskayaKeeperProjectilesCanvas extends Control:
	var _orbs_node: LenskayaKeeperOrbs = null
	var _projectiles: Array[Dictionary] = []
	var _explosions: Array[Dictionary] = []
	var _time: float = 0.0
	var _respawn_called: bool = false

	func _init(start_pos: Vector2, target_positions: Array, orbs_ctrl: LenskayaKeeperOrbs = null) -> void:
		name = "LenskayaKeeperProjectilesCanvas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 250
		_orbs_node = orbs_ctrl
		
		for i in range(target_positions.size()):
			var t_pos: Vector2 = target_positions[i]
			_projectiles.append({
				"idx": i,
				"start": start_pos,
				"ctrl": Vector2.ZERO,
				"target": t_pos,
				"progress": 0.0,
				"delay": float(i) * 0.08,
				"alive": true,
				"launched": false
			})

	func _process(delta: float) -> void:
		_time += delta
		var has_active := false
		
		for p in _projectiles:
			if not p.alive:
				continue
			if p.delay > 0.0:
				p.delay -= delta
				has_active = true
				continue
			if not p.launched:
				p.launched = true
				# Именно ТА сфера, которая кружилась вокруг Ленской, отрывается от орбиты!
				if is_instance_valid(_orbs_node):
					p.start = _orbs_node.peel_off_orb(p.idx)
				var p_st: Vector2 = p.start
				var p_tg: Vector2 = p.target
				var mid: Vector2 = (p_st + p_tg) * 0.5
				var perp: Vector2 = (p_tg - p_st).orthogonal().normalized()
				var curve_h: float = randf_range(40.0, 90.0) * (1.0 if randf() < 0.5 else -1.0)
				p.ctrl = mid + perp * curve_h
				
			p.progress += delta * 2.8
			if p.progress >= 1.0:
				p.progress = 1.0
				p.alive = false
				_create_explosion(p.target)
			else:
				has_active = true
				
		var remaining_exp: Array[Dictionary] = []
		for e in _explosions:
			e.progress += delta * 3.5
			if e.progress < 1.0:
				remaining_exp.append(e)
				has_active = true
		_explosions = remaining_exp
		
		if not has_active:
			if not _respawn_called:
				_respawn_called = true
				if is_instance_valid(_orbs_node):
					_orbs_node.start_respawn()
			queue_free()
		else:
			queue_redraw()

	func _create_explosion(pos: Vector2) -> void:
		var sparks: Array[Vector2] = []
		for i in range(8):
			var a := randf_range(0.0, TAU)
			var spd := randf_range(25.0, 55.0)
			sparks.append(Vector2(cos(a), sin(a)) * spd)
		_explosions.append({
			"pos": pos,
			"progress": 0.0,
			"sparks": sparks
		})

	func _draw() -> void:
		for p in _projectiles:
			if not p.alive or not p.launched:
				continue
			var t: float = p.progress
			var p_st: Vector2 = p.start
			var p_ct: Vector2 = p.ctrl
			var p_tg: Vector2 = p.target
			var cur_pos: Vector2 = (1.0 - t) * (1.0 - t) * p_st + 2.0 * (1.0 - t) * t * p_ct + t * t * p_tg
			
			draw_circle(cur_pos, 16.0, Color(0.40, 0.08, 0.70, 0.35))
			draw_circle(cur_pos, 10.0, Color(0.65, 0.20, 0.95, 0.65))
			draw_arc(cur_pos, 8.0, 0.0, TAU, 16, Color(0.85, 0.40, 1.0, 0.85), 1.8)
			draw_circle(cur_pos, 5.0, Color(0.05, 0.01, 0.10, 0.90))
			draw_circle(cur_pos + Vector2(-1.5, -1.5), 1.5, Color(1.0, 0.9, 1.0, 0.90))

		for e in _explosions:
			var ep: float = e.progress
			var pos: Vector2 = e.pos
			var a: float = 1.0 - ep
			draw_arc(pos, 35.0 * ep, 0.0, TAU, 24, Color(0.85, 0.35, 1.0, a * 0.9), 2.5)
			draw_circle(pos, 20.0 * (1.0 - ep * 0.5), Color(0.55, 0.12, 0.85, a * 0.5))
			draw_circle(pos, 8.0 * (1.0 - ep), Color(1.0, 0.95, 1.0, a))
			for sp in e.sparks:
				var spark_vec: Vector2 = sp
				draw_line(pos + spark_vec * (ep * 0.5), pos + spark_vec * ep, Color(0.90, 0.50, 1.0, a), 2.0)

# Разрезающий эффект Навыка Q Воина Небытия (Один большой разрез в обычном режиме, и пространственный разлом со звёздами и лучами в изнанке)
class LenskayaWarriorSlashVFXCanvas extends Control:
	var _is_from_inverted: bool = false
	var _parent_battle: Control = null
	var _time: float = 0.0
	var _duration: float = 0.55
	var _target_positions: Array = []
	var _center_pos: Vector2 = Vector2.ZERO
	var _vp_size: Vector2 = Vector2(1280, 720)
	var _stars: Array[Dictionary] = []
	var _beams: Array[Dictionary] = []
	var _lightning_pts: PackedVector2Array = []
	var _impact_triggered: bool = false

	func _init(battle_ctrl: Control, target_positions: Array, is_inverted: bool) -> void:
		name = "LenskayaWarriorSlashVFXCanvas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 251
		_parent_battle = battle_ctrl
		_target_positions = target_positions
		_is_from_inverted = is_inverted
		
		var vp_size := Vector2(1280, 720)
		if is_instance_valid(battle_ctrl) and battle_ctrl.is_inside_tree():
			vp_size = battle_ctrl.get_viewport_rect().size
		_vp_size = vp_size

		if _is_from_inverted:
			_duration = 0.75
			# Центр удара: чуть выше центра экрана (на уровне карточек врагов)
			var def_center := Vector2(vp_size.x * 0.5, vp_size.y * 0.38)
			if not target_positions.is_empty():
				var t_pos: Vector2 = target_positions[0]
				def_center = Vector2(t_pos.x, clampf(t_pos.y, vp_size.y * 0.28, vp_size.y * 0.44))
			_center_pos = def_center

			_init_stars()
			_init_beams()
			_init_center_lightning()
		else:
			_duration = 0.40

	func _init_stars() -> void:
		_stars.clear()
		for i in range(40):
			var sx := randf_range(-440.0, 440.0)
			var sy := randf_range(-90.0, 90.0)
			var r := randf_range(0.9, 2.4)
			var phase := randf_range(0.0, TAU)
			var col := Color(0.95, 0.90, 1.0) if randf() < 0.65 else Color(0.80, 0.70, 1.0)
			_stars.append({
				"x": sx,
				"y": sy,
				"r": r,
				"phase": phase,
				"col": col
			})

	func _init_beams() -> void:
		_beams.clear()
		var count := 24
		for i in range(count):
			var frac := randf_range(-0.75, 0.75)
			var is_up := randf() < 0.5
			var angle := (-PI * 0.5 if is_up else PI * 0.5) + randf_range(-0.28, 0.28)
			var length := randf_range(70.0, 160.0)
			var width := randf_range(2.0, 4.5)
			_beams.append({
				"frac": frac,
				"is_up": is_up,
				"dir": Vector2(cos(angle), sin(angle)),
				"len": length,
				"w": width
			})

	func _init_center_lightning() -> void:
		_lightning_pts.clear()
		var cur := Vector2(randf_range(-8.0, 8.0), -65.0)
		_lightning_pts.append(cur)
		var steps := 6
		for s in range(steps):
			cur += Vector2(randf_range(-20.0, 20.0), randf_range(18.0, 24.0))
			_lightning_pts.append(cur)

	func _get_rift_half_height(dx: float, W: float, max_h: float, open_factor: float) -> float:
		var u: float = dx / W
		if absf(u) >= 1.0:
			return 0.0
		var shape: float = pow(1.0 - u * u, 1.7)
		return max_h * shape * open_factor

	func _process(delta: float) -> void:
		_time += delta
		if _is_from_inverted and _time >= 0.12 and not _impact_triggered:
			_impact_triggered = true
			if is_instance_valid(_parent_battle) and _parent_battle.has_method("_on_screen_impact_requested"):
				_parent_battle._on_screen_impact_requested(Color(0.85, 0.45, 1.0, 0.85), 18.0, 0.50)

		if _time >= _duration:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var progress := clampf(_time / _duration, 0.0, 1.0)
		var fade := 1.0 - progress

		if _is_from_inverted:
			var W: float = _vp_size.x * 0.52
			var max_h: float = 100.0 # Широкий в центре (~200px высота разлома)
			var left_x: float = _center_pos.x - W
			var right_x: float = _center_pos.x + W

			var open_factor: float = 0.0
			if _time < 0.10:
				open_factor = 0.0
			elif _time < 0.28:
				open_factor = (_time - 0.10) / 0.18
			elif _time < 0.52:
				open_factor = 1.0 + 0.04 * sin((_time - 0.28) * 18.0)
			else:
				open_factor = 1.0 - (_time - 0.52) / 0.23
			open_factor = clampf(open_factor, 0.0, 1.05)

			var tilt: float = -0.04 # Очень малый наклон (почти горизонтально)

			# 1. Горизонтальный разрез (вспышка в начале)
			if _time < 0.24:
				var slash_t: float = clampf(_time / 0.10, 0.0, 1.0)
				var cur_right: float = lerpf(left_x, right_x, slash_t)
				var line_a: float = 1.0 - (_time / 0.24)
				var p1 := _center_pos + Vector2(left_x - _center_pos.x, (left_x - _center_pos.x) * tilt)
				var p2 := _center_pos + Vector2(cur_right - _center_pos.x, (cur_right - _center_pos.x) * tilt)
				draw_line(p1, p2, Color(0.70, 0.25, 0.95, line_a * 0.8), 8.0)
				draw_line(p1, p2, Color(1.0, 0.95, 1.0, line_a), 3.0)

			if open_factor > 0.01:
				var segs := 48
				var top_pts := PackedVector2Array()
				var bot_pts := PackedVector2Array()
				for s in range(segs + 1):
					var frac: float = float(s) / float(segs)
					var dx: float = lerpf(-W, W, frac)
					var hh: float = _get_rift_half_height(dx, W, max_h, open_factor)
					var base_y: float = dx * tilt
					top_pts.append(_center_pos + Vector2(dx, base_y - hh))
					bot_pts.append(_center_pos + Vector2(dx, base_y + hh))

				# СЛОЙ 1: Фиолетовые лучи (God Rays) наружу вверх и вниз
				for bm in _beams:
					var dx: float = bm.frac * W
					var hh: float = _get_rift_half_height(dx, W, max_h, open_factor)
					var base_y: float = dx * tilt
					var start_pt := _center_pos + Vector2(dx, base_y - (hh if bm.is_up else -hh))
					var beam_alpha: float = fade * 0.35 * open_factor
					var dir: Vector2 = bm.dir
					var l: float = bm.len
					var w: float = bm.w
					draw_line(start_pt, start_pt + dir * (l * open_factor), Color(0.65, 0.20, 0.95, beam_alpha), w)

				# СЛОЙ 2: Мягкое фиолетовое свечение по краям
				var glow_poly := PackedVector2Array()
				var glow_offset := 14.0 * open_factor
				for pt in top_pts:
					glow_poly.append(pt + Vector2(0.0, -glow_offset))
				for i in range(bot_pts.size() - 1, -1, -1):
					glow_poly.append(bot_pts[i] + Vector2(0.0, glow_offset))
				draw_colored_polygon(glow_poly, Color(0.55, 0.12, 0.88, fade * 0.25 * open_factor))

				# СЛОЙ 3: Чёрная пустота в центре
				var void_poly := PackedVector2Array()
				for pt in top_pts:
					void_poly.append(pt)
				for i in range(bot_pts.size() - 1, -1, -1):
					void_poly.append(bot_pts[i])
				draw_colored_polygon(void_poly, Color(0.01, 0.004, 0.02, fade * 0.98))

				# СЛОЙ 4: Звёзды внутри чёрной пустоты
				for st in _stars:
					var hh: float = _get_rift_half_height(st.x, W, max_h, open_factor)
					if absf(st.y) < hh * 0.88:
						var base_y: float = st.x * tilt
						var star_pos := _center_pos + Vector2(st.x, base_y + st.y)
						var twinkle: float = 0.5 + 0.5 * sin(_time * 9.0 + st.phase)
						var sa: float = fade * twinkle * open_factor
						var r: float = st.r
						var c: Color = st.col
						draw_circle(star_pos, r * (0.8 + 0.3 * twinkle), Color(c.r, c.g, c.b, sa))
						if r >= 1.8:
							var flare_col := Color(c.r, c.g, c.b, sa * 0.7)
							draw_line(star_pos - Vector2(3.5, 0), star_pos + Vector2(3.5, 0), flare_col, 1.0)
							draw_line(star_pos - Vector2(0, 3.5), star_pos + Vector2(0, 3.5), flare_col, 1.0)

				# СЛОЙ 5: Слегка фиолетовые светящиеся края
				draw_polyline(top_pts, Color(0.65, 0.18, 0.95, fade * 0.55), 4.5)
				draw_polyline(bot_pts, Color(0.65, 0.18, 0.95, fade * 0.55), 4.5)
				draw_polyline(top_pts, Color(0.88, 0.45, 1.0, fade * 0.85), 2.0)
				draw_polyline(bot_pts, Color(0.88, 0.45, 1.0, fade * 0.85), 2.0)

				# СЛОЙ 6: Центральный разлом / молния
				var l_poly := PackedVector2Array()
				for l_pt in _lightning_pts:
					l_poly.append(_center_pos + l_pt * (open_factor * 0.9))
				if l_poly.size() >= 2:
					draw_polyline(l_poly, Color(0.75, 0.25, 0.98, fade * 0.8), 6.0)
					draw_polyline(l_poly, Color(1.0, 0.98, 1.0, fade * 0.95), 2.2)

				draw_circle(_center_pos, 22.0 * open_factor, Color(0.70, 0.20, 0.95, fade * 0.45))
				draw_circle(_center_pos, 10.0 * open_factor, Color(1.0, 1.0, 1.0, fade * 0.8))
		else:
			# ОДИН большой разрез через все поражённые цели
			if _target_positions.is_empty():
				return
			var min_x := 99999.0
			var max_x := -99999.0
			var avg_y := 0.0
			for pos_val in _target_positions:
				var pos: Vector2 = pos_val
				min_x = minf(min_x, pos.x)
				max_x = maxf(max_x, pos.x)
				avg_y += pos.y
			avg_y /= float(_target_positions.size())
			
			var p_start := Vector2(min_x - 85.0, avg_y + 40.0)
			var p_end := Vector2(max_x + 85.0, avg_y - 40.0)
			
			var cut_prog := clampf(_time / 0.16, 0.0, 1.0)
			var cut_cur := p_start.lerp(p_end, cut_prog)
			
			# Широкое фиолетовое лезвие
			draw_line(p_start, cut_cur, Color(0.65, 0.15, 0.95, fade * 0.85), 10.0)
			# Чёрное пустотное ядро
			draw_line(p_start, cut_cur, Color(0.03, 0.01, 0.06, fade * 0.95), 4.5)
			# Бело-фиолетовая режущая кромка
			if _time < 0.22:
				var flash_a := (1.0 - _time / 0.22)
				draw_line(p_start, cut_cur, Color(1.0, 0.92, 1.0, flash_a), 2.0)
				
			# Вспышки и искры на каждой цели при пересечении
			for pos_val in _target_positions:
				var pos: Vector2 = pos_val
				if cut_cur.x >= pos.x - 30.0:
					draw_circle(pos, 16.0 * fade, Color(0.85, 0.35, 1.0, fade * 0.65))
					draw_circle(pos, 7.0 * fade, Color(1.0, 1.0, 1.0, fade * 0.85))

# Пространственный разрез по карточке Ленской (Навык E Воин Небытия)
class LenskayaCardSlash extends Control:
	var _time: float = 0.0
	var _duration: float = 0.28
	var _parent_panel: PanelContainer = null

	func _init(panel: PanelContainer) -> void:
		_parent_panel = panel
		name = "LenskayaCardSlash"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 50

	func _process(delta: float) -> void:
		_time += delta
		if _time >= _duration:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(_parent_panel):
			return
		var p_size: Vector2 = _parent_panel.size
		if p_size.x <= 0 or p_size.y <= 0:
			return
		var p1 := Vector2(p_size.x * 0.15, p_size.y * 0.85)
		var p2 := Vector2(p_size.x * 0.85, p_size.y * 0.15)
		var prog := clampf(_time / 0.10, 0.0, 1.0)
		var fade := 1.0 - (_time / _duration)
		var cur := p1.lerp(p2, prog)
		
		draw_line(p1, cur, Color(0.65, 0.15, 0.95, fade * 0.9), 6.0)
		draw_line(p1, cur, Color(0.04, 0.01, 0.08, fade * 0.95), 2.5)
		draw_line(p1, cur, Color(1.0, 0.90, 1.0, fade), 1.2)

# Радиальная фиолетовая ударная вспышка-волна при выходе из изнанки
class LenskayaInvertedExitFlash extends Control:
	var _center: Vector2
	var _time: float = 0.0
	var _duration: float = 0.45
	var _particles: Array[Vector2] = []

	func _init(global_center: Vector2) -> void:
		name = "LenskayaInvertedExitFlash"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 250
		_center = global_center
		for i in range(16):
			var a := float(i) * (TAU / 16.0) + randf_range(-0.1, 0.1)
			var spd := randf_range(60.0, 120.0)
			_particles.append(Vector2(cos(a), sin(a)) * spd)

	func _process(delta: float) -> void:
		_time += delta
		if _time >= _duration:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var prog := clampf(_time / _duration, 0.0, 1.0)
		var a := 1.0 - prog
		
		# Первая расширяющаяся ударная волна
		draw_arc(_center, 140.0 * prog, 0.0, TAU, 36, Color(0.85, 0.35, 1.0, a * 0.9), 3.5)
		# Вторая волна
		if prog > 0.15:
			var p2 := (prog - 0.15) / 0.85
			draw_arc(_center, 120.0 * p2, 0.0, TAU, 32, Color(0.55, 0.10, 0.85, a * 0.7), 2.5)
		# Центральная вспышка
		draw_circle(_center, 40.0 * (1.0 - prog), Color(0.90, 0.60, 1.0, a * 0.8))
		draw_circle(_center, 20.0 * (1.0 - prog), Color(1.0, 1.0, 1.0, a))
		
		# Радиальные частицы во все стороны
		for pt in _particles:
			draw_line(_center + pt * (prog * 0.4), _center + pt * prog, Color(0.85, 0.40, 1.0, a * 0.85), 2.2)

class LenskayaSupernovaVFXCanvas extends Control:
	var p_start: Vector2
	var p_end: Vector2
	var phase: int = 0
	var charge_progress: float = 0.0
	var beam_progress: float = 0.0
	var fade_alpha: float = 1.0
	var time: float = 0.0
	var blackout_rect: ColorRect = null
	var parent_battle: Control = null
	var hit_sparks: Array[Vector2] = []

	func _init(start_pos: Vector2, end_pos: Vector2, blackout: ColorRect, battle_ctrl: Control) -> void:
		p_start = start_pos
		p_end = end_pos
		blackout_rect = blackout
		parent_battle = battle_ctrl
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 255
		_generate_hit_sparks()

	func _generate_hit_sparks() -> void:
		hit_sparks.clear()
		for i in range(16):
			var angle: float = randf_range(0.0, TAU)
			var dist: float = randf_range(40.0, 110.0)
			hit_sparks.append(Vector2(cos(angle), sin(angle)) * dist)

	func start_sequence() -> void:
		var tw := create_tween()
		# 1. Зарядка энергии (накопление)
		tw.tween_property(self, "charge_progress", 1.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			phase = 1
		)
		# 2. Выстрел луча
		tw.tween_property(self, "beam_progress", 1.0, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			# Яркая вспышка на весь экран с длительным послесвечением (~0.95с)
			if is_instance_valid(parent_battle) and parent_battle.has_method("_on_screen_impact_requested"):
				parent_battle._on_screen_impact_requested(Color(1.0, 0.95, 1.0, 1.0), 22.0, 0.95)
		)
		# 3. Удержание мощного луча во время вспышки
		tw.tween_interval(0.40)
		tw.tween_callback(func():
			phase = 2
		)
		# 4. Плавное затухание луча и затемнения
		tw.tween_property(self, "fade_alpha", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if is_instance_valid(blackout_rect):
			var tw_b := create_tween()
			tw_b.tween_property(blackout_rect, "color:a", 0.0, 0.35)
			tw_b.tween_callback(blackout_rect.queue_free)
			
		tw.tween_callback(queue_free)

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		if fade_alpha <= 0.0:
			return
			
		var alpha: float = fade_alpha
		
		# Фаза накопления (сфера у Ленской)
		if phase == 0 or phase == 1:
			var charge_rad: float = lerpf(6.0, 42.0, charge_progress)
			var pulse: float = 1.0 + 0.18 * sin(time * 35.0)
			var r: float = charge_rad * pulse
			
			if phase == 0:
				var strand_count := 12
				for s in range(strand_count):
					var angle: float = float(s) * (TAU / float(strand_count)) + time * 7.0
					var dist: float = lerpf(80.0, 15.0, charge_progress)
					var strand_start: Vector2 = p_start + Vector2(cos(angle), sin(angle)) * dist
					draw_line(strand_start, p_start, Color(0.75, 0.25, 1.0, (1.0 - charge_progress * 0.4) * alpha * 0.8), 2.5)

			draw_circle(p_start, r * 1.6, Color(0.30, 0.04, 0.55, 0.35 * alpha))
			draw_circle(p_start, r * 1.1, Color(0.60, 0.15, 0.90, 0.65 * alpha))
			draw_circle(p_start, r * 0.65, Color(0.06, 0.01, 0.12, 0.95 * alpha))
			draw_circle(p_start, r * 0.32, Color(0.98, 0.90, 1.0, 0.95 * alpha))

		# Фаза мощного луча и удара
		if phase >= 1:
			var cur_end: Vector2 = p_start.lerp(p_end, beam_progress)
			var beam_dir: Vector2 = (p_end - p_start).normalized()
			var beam_len: float = (cur_end - p_start).length()
			var normal: Vector2 = Vector2(-beam_dir.y, beam_dir.x)
			
			if beam_len > 2.0:
				var jitter: float = sin(time * 50.0) * 2.0
				var w_outer: float = (54.0 + jitter * 2.0) * alpha
				var w_mid: float = (28.0 + jitter * 1.2) * alpha
				var w_inner: float = (14.0 + jitter * 0.6) * alpha
				var w_core: float = (7.0 + jitter * 0.3) * alpha
				
				# 1. Внешняя корона луча
				draw_line(p_start, cur_end, Color(0.25, 0.02, 0.45, 0.60 * alpha), w_outer)
				# 2. Плазменная оболочка
				draw_line(p_start, cur_end, Color(0.65, 0.15, 0.95, 0.85 * alpha), w_mid)
				# 3. Внутренняя яркая энергия
				draw_line(p_start, cur_end, Color(0.88, 0.45, 1.0, 0.95 * alpha), w_inner)
				# 4. Ослепительное лазерное ядро
				draw_line(p_start, cur_end, Color(1.0, 0.98, 1.0, 1.0 * alpha), w_core)

				# Спиральные струи энергии вокруг луча (двойная спираль)
				var helix_steps: int = int(beam_len / 12.0)
				if helix_steps > 1:
					var h_pts1 := PackedVector2Array()
					var h_pts2 := PackedVector2Array()
					for h in range(helix_steps + 1):
						var h_frac: float = float(h) / float(helix_steps)
						var base: Vector2 = p_start.lerp(cur_end, h_frac)
						var phase_shift: float = h_frac * 18.0 - time * 25.0
						var offset1: Vector2 = normal * sin(phase_shift) * (w_mid * 0.65)
						var offset2: Vector2 = normal * sin(phase_shift + PI) * (w_mid * 0.65)
						h_pts1.append(base + offset1)
						h_pts2.append(base + offset2)
					draw_polyline(h_pts1, Color(0.85, 0.40, 1.0, 0.70 * alpha), 2.5)
					draw_polyline(h_pts2, Color(0.50, 0.10, 0.80, 0.70 * alpha), 2.5)

				# Искры вдоль ствола луча
				var spark_steps: int = int(beam_len / 35.0)
				for i in range(spark_steps):
					var frac: float = float(i + 1) / float(spark_steps + 1)
					var base_pt: Vector2 = p_start.lerp(cur_end, frac)
					var side_offset: Vector2 = normal * sin(time * 30.0 + float(i) * 3.5) * (w_mid * 0.9)
					draw_line(base_pt, base_pt + side_offset, Color(1.0, 0.85, 1.0, 0.85 * alpha), 2.0)

			# Эффект колоссального попадания по врагу
			if beam_progress >= 0.75:
				var hit_time: float = time * 25.0
				var hit_pulse: float = 1.0 + 0.25 * sin(hit_time)
				
				# Расширяющиеся ударные волны
				var shock_r1: float = fmod(hit_time * 18.0, 95.0)
				var shock_a1: float = (1.0 - shock_r1 / 95.0) * alpha * 0.7
				draw_arc(p_end, shock_r1, 0.0, TAU, 32, Color(0.85, 0.40, 1.0, shock_a1), 3.0)
				
				var shock_r2: float = fmod(hit_time * 18.0 + 45.0, 95.0)
				var shock_a2: float = (1.0 - shock_r2 / 95.0) * alpha * 0.7
				draw_arc(p_end, shock_r2, 0.0, TAU, 32, Color(0.60, 0.15, 0.95, shock_a2), 2.5)

				# Взрывные частицы/лучи попадания
				for sp in hit_sparks:
					var sp_frac: float = 0.5 + 0.5 * sin(hit_time + sp.x)
					var spark_dest: Vector2 = p_end + sp * sp_frac
					draw_line(p_end, spark_dest, Color(0.95, 0.80, 1.0, (1.0 - sp_frac * 0.5) * alpha * 0.75), 2.0)

				# Ослепляющий центр взрыва
				draw_circle(p_end, 50.0 * hit_pulse, Color(0.55, 0.10, 0.85, 0.45 * alpha))
				draw_circle(p_end, 32.0 * hit_pulse, Color(0.85, 0.40, 1.0, 0.75 * alpha))
				draw_circle(p_end, 18.0, Color(0.04, 0.0, 0.08, 0.95 * alpha))
				draw_circle(p_end, 10.0, Color(1.0, 1.0, 1.0, alpha))

# Эффект удара: сотрясение экрана и бело-фиолетовая вспышка
func _on_screen_impact_requested(flash_color: Color, intensity: float, duration: float = 0.32) -> void:
	# 1. Вспышка на весь экран
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = flash_color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 252
	add_child(flash)
	
	var flash_tween := create_tween()
	if duration > 0.5:
		flash_tween.tween_interval(0.12)
		flash_tween.tween_property(flash, "modulate:a", 0.0, duration - 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		flash_tween.tween_property(flash, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(flash.queue_free)
	
	# 2. Мягкое подрагивание экрана
	var orig_pos := Vector2.ZERO
	var shake_tween := create_tween()
	var shake_steps := 6
	for i in shake_steps:
		var decay: float = 1.0 - (float(i) / float(shake_steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity, intensity) * decay
		)
		shake_tween.tween_property(self, "position", orig_pos + offset, 0.035)
	shake_tween.tween_property(self, "position", orig_pos, 0.04)

func _on_lenskaya_am_supernova_vfx(attacker: CombatUnit, target: CombatUnit) -> void:
	var p_start := Vector2(240, 480)
	var p_end := Vector2(860, 480)
	
	if _unit_panels.has(attacker) and is_instance_valid(_unit_panels[attacker]):
		var ap: PanelContainer = _unit_panels[attacker]
		p_start = ap.get_global_position() + ap.size * 0.5
	if _unit_panels.has(target) and is_instance_valid(_unit_panels[target]):
		var tp: PanelContainer = _unit_panels[target]
		p_end = tp.get_global_position() + tp.size * 0.5
		
		# Оставляем полупрозрачный след/трещину на земле под врагом
		target.set_meta("has_supernova_crater", true)
		var old_crater = tp.get_node_or_null("SupernovaCraterDecal")
		if old_crater != null and is_instance_valid(old_crater):
			old_crater.queue_free()
		var crater := SupernovaCraterDecal.new(tp)
		tp.add_child(crater)

	# 1. Потемнение экрана с блокировкой кликов
	var blackout := ColorRect.new()
	blackout.name = "SupernovaBlackout"
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color(0.02, 0.0, 0.06, 0.0)
	blackout.mouse_filter = Control.MOUSE_FILTER_STOP
	blackout.z_index = 250
	add_child(blackout)
	
	var tw_blackout := create_tween()
	tw_blackout.tween_property(blackout, "color:a", 0.78, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Холст луча и сферы накопления энергии
	var canvas := LenskayaSupernovaVFXCanvas.new(p_start, p_end, blackout, self)
	add_child(canvas)
	canvas.start_sequence()

func _update_card_ult_button_style(unit: CombatUnit, ult_btn: Button, can_ult: bool) -> void:
	if not is_instance_valid(ult_btn):
		return
	var is_ult_ready: bool = can_ult and battle_manager.phase == battle_manager.Phase.RUNNING
	if not is_ult_ready:
		if ult_btn.has_node("LenskayaUltBtnPulse"):
			ult_btn.get_node("LenskayaUltBtnPulse").queue_free()
		ult_btn.remove_theme_stylebox_override("normal")
		ult_btn.remove_theme_stylebox_override("hover")
		ult_btn.remove_theme_stylebox_override("pressed")
		ult_btn.remove_theme_color_override("font_color")
		return

	if unit.id == "lenskaya_antimatter":
		if not ult_btn.has_node("LenskayaUltBtnPulse"):
			ult_btn.add_child(LenskayaUltBtnPulse.new(ult_btn))
	else:
		if ult_btn.has_node("LenskayaUltBtnPulse"):
			ult_btn.get_node("LenskayaUltBtnPulse").queue_free()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.14, 0.04, 0.95)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(2)
		sb.border_color = Color(1.0, 0.85, 0.30, 0.95)
		sb.shadow_color = Color(1.0, 0.80, 0.20, 0.35)
		sb.shadow_size = 3
		ult_btn.add_theme_stylebox_override("normal", sb)
		ult_btn.add_theme_stylebox_override("hover", sb)
		ult_btn.add_theme_stylebox_override("pressed", sb)
		ult_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))

func _on_lenskaya_am_keeper_q_vfx(attacker: CombatUnit, targets: Array) -> void:
	var start_pos := Vector2(240, 480)
	var orbs_node: LenskayaKeeperOrbs = null
	if _unit_panels.has(attacker) and is_instance_valid(_unit_panels[attacker]):
		var ap: PanelContainer = _unit_panels[attacker]
		start_pos = ap.get_global_position() + ap.size * 0.5
		orbs_node = ap.get_node_or_null("LenskayaKeeperOrbs") as LenskayaKeeperOrbs
		
	var target_positions: Array[Vector2] = []
	for t in targets:
		if t is CombatUnit and _unit_panels.has(t) and is_instance_valid(_unit_panels[t]):
			var tp: PanelContainer = _unit_panels[t]
			target_positions.append(tp.get_global_position() + tp.size * 0.5)
			
	if not target_positions.is_empty():
		var canvas := LenskayaKeeperProjectilesCanvas.new(start_pos, target_positions, orbs_node)
		add_child(canvas)

func _on_lenskaya_am_warrior_q_vfx(attacker: CombatUnit, target: CombatUnit, is_from_inverted: bool) -> void:
	var target_positions: Array[Vector2] = []
	if is_from_inverted:
		if target != null and _unit_panels.has(target) and is_instance_valid(_unit_panels[target]):
			var tp: PanelContainer = _unit_panels[target]
			target_positions.append(tp.get_global_position() + tp.size * 0.5)
		var canvas := LenskayaWarriorSlashVFXCanvas.new(self, target_positions, true)
		add_child(canvas)
	else:
		var enemies: Array[CombatUnit] = battle_manager.get_living_enemies()
		var idx := enemies.find(target)
		var affected: Array[CombatUnit] = []
		if idx != -1:
			affected.append(target)
			if idx > 0:
				affected.append(enemies[idx - 1])
			if idx < enemies.size() - 1:
				affected.append(enemies[idx + 1])
		elif target != null:
			affected.append(target)
			
		for e in affected:
			if _unit_panels.has(e) and is_instance_valid(_unit_panels[e]):
				var ep: PanelContainer = _unit_panels[e]
				target_positions.append(ep.get_global_position() + ep.size * 0.5)
				
		var canvas := LenskayaWarriorSlashVFXCanvas.new(self, target_positions, false)
		add_child(canvas)

func _on_lenskaya_am_warrior_e_slash(attacker: CombatUnit) -> void:
	if _unit_panels.has(attacker) and is_instance_valid(_unit_panels[attacker]):
		var ap: PanelContainer = _unit_panels[attacker]
		var slash := LenskayaCardSlash.new(ap)
		ap.add_child(slash)
		var tw := create_tween()
		tw.tween_property(ap, "modulate:a", 0.38, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_lenskaya_am_inverted_exit(attacker: CombatUnit) -> void:
	var center := Vector2(240, 480)
	if _unit_panels.has(attacker) and is_instance_valid(_unit_panels[attacker]):
		var ap: PanelContainer = _unit_panels[attacker]
		center = ap.get_global_position() + ap.size * 0.5
		var tw := create_tween()
		tw.tween_property(ap, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var flash := LenskayaInvertedExitFlash.new(center)
	add_child(flash)

# =========================================================================
# КОНТЕЙНЕР ПАНЕЛЕЙ ФРАКЦИЙ (КОНСОЛЬ И АНТИМАТЕРИЯ)
# =========================================================================

func _get_or_create_faction_hud_container() -> VBoxContainer:
	if faction_hud_vbox != null and is_instance_valid(faction_hud_vbox):
		return faction_hud_vbox
	faction_hud_vbox = VBoxContainer.new()
	faction_hud_vbox.name = "FactionHUDVBox"
	faction_hud_vbox.offset_left = 100.0
	faction_hud_vbox.offset_top = 80.0
	faction_hud_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faction_hud_vbox.add_theme_constant_override("separation", 8)
	faction_hud_vbox.z_index = 15
	add_child(faction_hud_vbox)
	return faction_hud_vbox

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
	console_hud_panel.custom_minimum_size = Vector2(170, 56)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.10, 0.88)
	style.border_color = Color(0.15, 0.95, 0.85, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	console_hud_panel.add_theme_stylebox_override("panel", style)
	
	console_hud_label = RichTextLabel.new()
	console_hud_label.bbcode_enabled = true
	console_hud_label.fit_content = true
	console_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console_hud_panel.add_child(console_hud_label)
	
	var container := _get_or_create_faction_hud_container()
	container.add_child(console_hud_panel)
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
# ПАНЕЛЬ И РЕСУРСЫ АНТИМАТЕРИИ (XAEROH И ПОГЛОЩЕНИЕ)
# =========================================================================

func _init_antimatter_hud() -> void:
	if antimatter_hud_panel != null and is_instance_valid(antimatter_hud_panel):
		return
		
	var has_antimatter_member := false
	for ally in battle_manager.allies:
		if ally.id == "lenskaya_antimatter":
			has_antimatter_member = true
			break
		if FactionSystem.FACTIONS.has("antimatter") and ally.id in FactionSystem.FACTIONS["antimatter"].members:
			has_antimatter_member = true
			break
			
	if not has_antimatter_member:
		return
		
	antimatter_hud_panel = PanelContainer.new()
	antimatter_hud_panel.name = "AntimatterHUDPanel"
	antimatter_hud_panel.custom_minimum_size = Vector2(170, 56)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.03, 0.12, 0.90)
	style.border_color = Color(0.73, 0.33, 0.83, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	antimatter_hud_panel.add_theme_stylebox_override("panel", style)
	
	antimatter_hud_label = RichTextLabel.new()
	antimatter_hud_label.bbcode_enabled = true
	antimatter_hud_label.fit_content = true
	antimatter_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	antimatter_hud_panel.add_child(antimatter_hud_label)
	
	var container := _get_or_create_faction_hud_container()
	container.add_child(antimatter_hud_panel)
	_update_antimatter_hud()

func _update_antimatter_hud() -> void:
	if antimatter_hud_panel == null or not is_instance_valid(antimatter_hud_panel):
		_init_antimatter_hud()
		
	if antimatter_hud_label == null:
		return
		
	var x_val: int = battle_manager.get_xaeroh()
	var bh_stacks: int = battle_manager.get_black_hole_absorption()
	var am_count: int = battle_manager.get_antimatter_count()
	
	var text := "[center][b][color=#ba55d3]🌌 АНТИМАТЕРИЯ[/color][/b]\nXaeroh: [b][color=white][font_size=18]%d[/font_size][/color][/b]" % x_val
	if am_count >= 3:
		text += "\n[color=#da70d6]Поглощение: [/color][b][color=white]%d[/color][/b]" % bh_stacks
	text += "[/center]"
	antimatter_hud_label.text = text

# =========================================================================
# ПАНЕЛЬ ДЕВЫ ЛУНЫ (ХРАНИТЕЛИ НЕБЕС / ПАМЯТЬ)
# =========================================================================

func _init_moon_maiden_hud() -> void:
	if moon_maiden_hud_panel != null and is_instance_valid(moon_maiden_hud_panel):
		return
		
	var has_moon_maiden := false
	if battle_manager.moon_maiden != null:
		has_moon_maiden = true
	else:
		for ally in battle_manager.allies:
			if ally.id == "marina_sky_guardian" or ally.path == CombatConstants.Path.REMEMBRANCE:
				has_moon_maiden = true
				break
				
	if not has_moon_maiden:
		return
		
	moon_maiden_hud_panel = PanelContainer.new()
	moon_maiden_hud_panel.name = "MoonMaidenHUDPanel"
	moon_maiden_hud_panel.custom_minimum_size = Vector2(170, 56)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.90)
	style.border_color = Color(0.40, 0.75, 1.0, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	moon_maiden_hud_panel.add_theme_stylebox_override("panel", style)
	
	moon_maiden_hud_label = RichTextLabel.new()
	moon_maiden_hud_label.bbcode_enabled = true
	moon_maiden_hud_label.fit_content = true
	moon_maiden_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_maiden_hud_panel.add_child(moon_maiden_hud_label)
	
	var container := _get_or_create_faction_hud_container()
	container.add_child(moon_maiden_hud_panel)
	_update_moon_maiden_hud()

func _update_moon_maiden_hud() -> void:
	if moon_maiden_hud_panel == null or not is_instance_valid(moon_maiden_hud_panel):
		_init_moon_maiden_hud()
		
	if moon_maiden_hud_label == null:
		return
		
	var hits: int = battle_manager.moon_maiden_hits if "moon_maiden_hits" in battle_manager else 0
	moon_maiden_hud_label.text = "[center][b][color=#67e8f9]🌙 ДЕВА ЛУНЫ[/color][/b]\nУдары: [b][color=white][font_size=20]%d[/font_size][/color][/b][/center]" % hits

func _show_lenskaya_am_ult_modal(unit: CombatUnit, forms_only: bool = false) -> void:
	if lenskaya_ult_root != null and is_instance_valid(lenskaya_ult_root):
		lenskaya_ult_root.queue_free()
		lenskaya_ult_root = null
	if lenskaya_ult_panel != null and is_instance_valid(lenskaya_ult_panel):
		lenskaya_ult_panel.queue_free()
		lenskaya_ult_panel = null
		
	# Блокирующий экран для предотвращения нажатия любых других кнопок
	lenskaya_ult_root = Control.new()
	lenskaya_ult_root.name = "LenskayaUltModalRoot"
	lenskaya_ult_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lenskaya_ult_root.mouse_filter = Control.MOUSE_FILTER_STOP
	lenskaya_ult_root.z_index = 240
	
	var backdrop := ColorRect.new()
	backdrop.name = "ModalBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.0, 0.03, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	lenskaya_ult_root.add_child(backdrop)
	
	lenskaya_ult_panel = PanelContainer.new()
	lenskaya_ult_panel.name = "LenskayaUltModal"
	lenskaya_ult_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lenskaya_ult_panel.custom_minimum_size = Vector2(380, 240)
	lenskaya_ult_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lenskaya_ult_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	lenskaya_ult_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.04, 0.12, 0.96)
	style.border_color = Color(0.75, 0.35, 0.95, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	lenskaya_ult_panel.add_theme_stylebox_override("panel", style)
	lenskaya_ult_root.add_child(lenskaya_ult_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	lenskaya_ult_panel.add_child(vbox)
	
	var lbl_title := RichTextLabel.new()
	lbl_title.bbcode_enabled = true
	lbl_title.fit_content = true
	var title_text := "[center][b][color=#ba55d3][font_size=18]🌌 Сверхспособность Ленской[/font_size][/color][/b]\n"
	if forms_only:
		title_text += "[color=#e0d0f0][font_size=13]Э6: Выберите форму для перехода:[/font_size][/color][/center]"
	else:
		title_text += "[color=#e0d0f0][font_size=13]Выберите вариант активации:[/font_size][/color][/center]"
	lbl_title.text = title_text
	vbox.add_child(lbl_title)
	
	var close_modal = func():
		if lenskaya_ult_root != null and is_instance_valid(lenskaya_ult_root):
			lenskaya_ult_root.queue_free()
			lenskaya_ult_root = null
		lenskaya_ult_panel = null
		
	var btn_keeper := Button.new()
	btn_keeper.text = "🛡 Хранитель Ничто (+100 Xaeroh, +1 ОН)"
	btn_keeper.custom_minimum_size = Vector2(0, 36)
	btn_keeper.pressed.connect(func():
		close_modal.call()
		unit.set_meta("lenskaya_am_ult_choice", "keeper")
		if forms_only:
			LenskayaAntimatterAbilities.choose_ult_keeper(unit, battle_manager)
		else:
			battle_manager.queue_ultimate(unit)
		for u in _unit_panels:
			_refresh_unit_panel(u)
	)
	vbox.add_child(btn_keeper)
	
	var btn_warrior := Button.new()
	btn_warrior.text = "⚔ Воин небытия (+100 Xaeroh, +1 ОН)"
	btn_warrior.custom_minimum_size = Vector2(0, 36)
	btn_warrior.pressed.connect(func():
		close_modal.call()
		unit.set_meta("lenskaya_am_ult_choice", "warrior")
		if forms_only:
			LenskayaAntimatterAbilities.choose_ult_warrior(unit, battle_manager)
		else:
			battle_manager.queue_ultimate(unit)
		for u in _unit_panels:
			_refresh_unit_panel(u)
	)
	vbox.add_child(btn_warrior)
	
	if not forms_only:
		var btn_supernova := Button.new()
		var cur_x: int = battle_manager.get_xaeroh() + 100
		btn_supernova.text = "💥 Уничтожение сверхновой (%d%% СА)" % int(round(cur_x * 2.8))
		btn_supernova.custom_minimum_size = Vector2(0, 36)
		btn_supernova.pressed.connect(func():
			close_modal.call()
			unit.set_meta("lenskaya_am_ult_choice", "supernova")
			_original_active_unit = battle_manager.current_unit
			battle_manager.current_unit = unit
			_target_mode = "ult"
			_selecting_target = true
			_set_target_buttons_visible(true, false)
			_set_action_buttons_disabled(true)
			battle_manager.set_meta("is_selecting_ult_target", true)
			_on_log("[Выберите цель для «Уничтожения сверхновой»]")
		)
		vbox.add_child(btn_supernova)
		
		var btn_cancel := Button.new()
		btn_cancel.text = "✖ Отмена"
		btn_cancel.custom_minimum_size = Vector2(0, 30)
		btn_cancel.pressed.connect(func():
			close_modal.call()
		)
		vbox.add_child(btn_cancel)
		
	add_child(lenskaya_ult_root)

func _check_star_guide_selection() -> void:
	if battle_manager == null:
		return
	if battle_manager.get_radiance_count() >= 2:
		var guides: Array[CombatUnit] = []
		for ally in battle_manager.allies:
			if ally != null and ally.is_alive() and (ally.id == "marina_sky_guardian" or ally.id == "lenskaya_sky_guardian"):
				guides.append(ally)
		if guides.size() >= 2:
			_show_star_guide_selection_modal()

func _show_star_guide_selection_modal() -> void:
	if star_guide_modal_root != null and is_instance_valid(star_guide_modal_root):
		star_guide_modal_root.queue_free()
		star_guide_modal_root = null

	star_guide_modal_root = Control.new()
	star_guide_modal_root.name = "StarGuideModalRoot"
	star_guide_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	star_guide_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	star_guide_modal_root.z_index = 250
	add_child(star_guide_modal_root)

	var backdrop := ColorRect.new()
	backdrop.name = "ModalBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.01, 0.03, 0.65)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	star_guide_modal_root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "StarGuideModalPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480, 260)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.14, 0.98)
	style.border_color = Color(1.0, 0.85, 0.35, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	star_guide_modal_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var lbl_title := RichTextLabel.new()
	lbl_title.bbcode_enabled = true
	lbl_title.fit_content = true
	lbl_title.text = "[center][b][color=#ffd700][font_size=18]🌟 Фракция «Свечение»[/font_size][/color][/b]\n[color=#e8e8e8][font_size=13]В отряде 2+ участника Свечения!\nВыберите [b]Звёздного проводника[/b], благословение которого получит отряд:[/font_size][/color][/center]"
	vbox.add_child(lbl_title)

	var close_modal = func():
		if star_guide_modal_root != null and is_instance_valid(star_guide_modal_root):
			star_guide_modal_root.queue_free()
			star_guide_modal_root = null

	var r_count: int = battle_manager.get_radiance_count()
	var m_mult_text := " (x1.5 при 3+: +30% урона, +45% КУ)" if r_count >= 3 else ""
	var l_mult_text := " (x1.5 при 3+: +45%)" if r_count >= 3 else ""

	var btn_marina := Button.new()
	btn_marina.text = "🕊 Марина • Хранитель небес\nДухи памяти: Урон +20%, Крит. урон +30%%s" % m_mult_text
	btn_marina.custom_minimum_size = Vector2(0, 52)
	btn_marina.add_theme_font_size_override("font_size", 13)
	btn_marina.pressed.connect(func():
		battle_manager.set_chosen_star_guide("marina_sky_guardian")
		close_modal.call()
		_build_unit_displays()
	)
	vbox.add_child(btn_marina)

	var btn_lenskaya := Button.new()
	btn_lenskaya.text = "🏹 Ленская • Хранитель небес\nОтряд: Урон Пробития +30%, Суперпробития +30%%s" % l_mult_text
	btn_lenskaya.custom_minimum_size = Vector2(0, 52)
	btn_lenskaya.add_theme_font_size_override("font_size", 13)
	btn_lenskaya.pressed.connect(func():
		battle_manager.set_chosen_star_guide("lenskaya_sky_guardian")
		close_modal.call()
		_build_unit_displays()
	)
	vbox.add_child(btn_lenskaya)


# =========================================================================
# ИНСТРУМЕНТ ТЕСТИРОВАНИЯ (АДМИН-ПАНЕЛЬ В БОЮ)
# =========================================================================

func _init_admin_panel() -> void:
	if not TeamConfig.is_admin_battle:
		return
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
	admin_panel.z_index = 90
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

	# Xaeroh (Антиматерия)
	var x_hbox := HBoxContainer.new()
	x_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(x_hbox)
	var x_lbl := Label.new()
	x_lbl.text = "Xaeroh: "
	x_lbl.custom_minimum_size = Vector2(80, 0)
	x_hbox.add_child(x_lbl)

	make_btn.call(x_hbox, "+20", func():
		battle_manager.add_xaeroh(20)
		_update_antimatter_hud()
	)
	make_btn.call(x_hbox, "+60", func():
		battle_manager.add_xaeroh(60)
		_update_antimatter_hud()
	)
	make_btn.call(x_hbox, "+100", func():
		battle_manager.add_xaeroh(100)
		_update_antimatter_hud()
	)
	make_btn.call(x_hbox, "0 (Сброс)", func():
		battle_manager.set_xaeroh(0)
		_update_antimatter_hud()
	)
	make_btn.call(x_hbox, "+1 Поглощ.", func():
		battle_manager.add_black_hole_absorption(1)
		_update_antimatter_hud()
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
	var eff_atk_admin := int(battle_manager.get_effective_atk_complete(unit))
	text += "СКР: %d | СА: %d (эфф. %d) | ЗАЩ: %d | КШ/КУ: %.1f%% / %.1f%%\n" % [
		int(unit.stats.get_effective_spd()), int(unit.stats.atk), eff_atk_admin, int(unit.stats.def),
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

func _toggle_log() -> void:
	_log_expanded = not _log_expanded
	log_list.visible = _log_expanded
	if _log_expanded:
		btn_toggle_log.text = "📜 Лог боя ▼"
		log_panel.offset_top = -480.0
		log_panel.offset_right = 480.0
	else:
		btn_toggle_log.text = "📜 Лог боя ▲"
		log_panel.offset_top = -52.0
		log_panel.offset_right = 240.0

func _show_skill_tooltip(skill_type: String) -> void:
	var unit := battle_manager.current_unit
	if unit == null or not unit.is_ally:
		return
	_show_skill_tooltip_for_unit(unit, skill_type)

func _show_skill_tooltip_for_unit(unit: CombatUnit, skill_type: String) -> void:
	if _skill_tooltip_panel == null or _skill_tooltip_text == null:
		return
	var desc := BattleInfoProvider.get_single_skill_text(unit, skill_type)
	if desc.is_empty():
		return
	_skill_tooltip_text.text = _format_skills_bbcode(desc)
	_skill_tooltip_panel.show()

func _hide_skill_tooltip() -> void:
	if _skill_tooltip_panel != null and is_instance_valid(_skill_tooltip_panel):
		_skill_tooltip_panel.hide()

func _highlight_active_unit(unit: CombatUnit) -> void:
	if _highlighted_unit_panel != null and is_instance_valid(_highlighted_unit_panel):
		var prev_unit = _highlighted_unit_panel.get_meta("unit", null)
		if prev_unit != unit:
			_reset_active_unit_visual()

	if unit == null or not _unit_panels.has(unit):
		return

	var panel: PanelContainer = _unit_panels[unit]
	if not is_instance_valid(panel):
		return

	_highlighted_unit_panel = panel
	panel.z_index = 10
	panel.pivot_offset = Vector2(panel.size.x * 0.5, panel.size.y)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not panel.has_meta("damage_tween"):
		tw.tween_property(panel, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _reset_active_unit_visual() -> void:
	if _highlighted_unit_panel == null or not is_instance_valid(_highlighted_unit_panel):
		_highlighted_unit_panel = null
		return

	var p := _highlighted_unit_panel
	var unit: CombatUnit = p.get_meta("unit", null)
	_highlighted_unit_panel = null
	p.z_index = 0
	
	var target_mod := Color.WHITE
	if unit:
		if not unit.is_alive():
			target_mod = Color(0.4, 0.4, 0.4, 0.7)
		elif unit.is_elite:
			target_mod = Color(1.1, 0.85, 1.0)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if not p.has_meta("damage_tween"):
		tw.tween_property(p, "modulate", target_mod, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _highlight_active_ally(unit: CombatUnit) -> void:
	_highlight_active_unit(unit)

func _reset_active_ally_visual() -> void:
	_reset_active_unit_visual()

func _draw_target_reticle(reticle: Control, unit: CombatUnit) -> void:
	if not _selecting_target or unit == null or not unit.is_alive():
		return
	
	var is_primary: bool = (unit == _selected_target_unit)
	var secondaries := _get_affected_secondary_targets(_selected_target_unit)
	var is_secondary: bool = (unit in secondaries)
	
	if not is_primary and not is_secondary:
		return
		
	var center := reticle.size * 0.5
	if is_primary:
		var radius: float = minf(reticle.size.x, reticle.size.y) * 0.42
		var pastel_blue := Color(0.55, 0.78, 0.98, 0.85)
		var pastel_inner := Color(0.75, 0.90, 1.0, 0.45)
		reticle.draw_arc(center, radius, 0.0, TAU, 64, pastel_blue, 3.0, true)
		reticle.draw_arc(center, radius - 5.0, 0.0, TAU, 48, pastel_inner, 1.5, true)
		var tick_len: float = 8.0
		reticle.draw_line(Vector2(center.x - radius - tick_len, center.y), Vector2(center.x - radius + tick_len, center.y), pastel_blue, 2.0)
		reticle.draw_line(Vector2(center.x + radius - tick_len, center.y), Vector2(center.x + radius + tick_len, center.y), pastel_blue, 2.0)
		reticle.draw_line(Vector2(center.x, center.y - radius - tick_len), Vector2(center.x, center.y - radius + tick_len), pastel_blue, 2.0)
		reticle.draw_line(Vector2(center.x, center.y + radius - tick_len), Vector2(center.x, center.y + radius + tick_len), pastel_blue, 2.0)
	elif is_secondary:
		var radius_sec: float = minf(reticle.size.x, reticle.size.y) * 0.28
		var pastel_sec := Color(0.60, 0.82, 1.0, 0.60)
		reticle.draw_arc(center, radius_sec, 0.0, TAU, 48, pastel_sec, 2.0, true)
		reticle.draw_arc(center, radius_sec - 3.0, 0.0, TAU, 32, Color(0.75, 0.90, 1.0, 0.30), 1.0, true)

func _draw_tgh_preview(tgh_bar: ProgressBar, unit: CombatUnit) -> void:
	if not unit.has_meta("projected_tgh_reduction") or unit.max_toughness <= 0.0:
		return
	var reduction: float = float(unit.get_meta("projected_tgh_reduction"))
	if reduction <= 0.0 or unit.toughness <= 0.0:
		return

	var bar_size := tgh_bar.size
	var cur_ratio := clampf(unit.toughness / unit.max_toughness, 0.0, 1.0)
	var new_tgh := maxf(unit.toughness - reduction, 0.0)
	var new_ratio := clampf(new_tgh / unit.max_toughness, 0.0, 1.0)

	var start_x := new_ratio * bar_size.x
	var width := (cur_ratio - new_ratio) * bar_size.x
	if width > 0.0:
		var rect := Rect2(start_x, 0.0, width, bar_size.y)
		tgh_bar.draw_rect(rect, Color(1.0, 0.55, 0.15, 0.95))

func _get_current_attacker_element() -> int:
	var active := battle_manager.current_unit
	if active == null:
		return -1
	if active.has_meta("current_attack_element"):
		return int(active.get_meta("current_attack_element"))
	if active.id == "lenskaya_antimatter":
		var stance: String = String(active.get_meta("lenskaya_am_stance", "none"))
		if stance == "keeper":
			return CombatConstants.Element.ICE
		elif stance == "warrior":
			return CombatConstants.Element.FIRE
		elif _target_mode == "ult":
			return CombatConstants.Element.QUANTUM
		elif active.eidolon >= 6:
			return CombatConstants.Element.QUANTUM
		else:
			return CombatConstants.Element.PHYSICAL
	return active.element

func _update_targeting_visuals() -> void:
	var attacker_elem := _get_current_attacker_element()
	var is_selecting := _selecting_target and attacker_elem != -1
	var secondaries := _get_affected_secondary_targets(_selected_target_unit)

	for unit in _unit_panels:
		var p: PanelContainer = _unit_panels[unit]
		var vbox: VBoxContainer = p.get_child(0)

		# 1. Обновляем прицел
		var reticle: Control = p.get_node_or_null("TargetReticle")
		if reticle:
			reticle.queue_redraw()

		# 2. Подсветка подходящих уязвимостей
		if not unit.is_ally and vbox.has_node("WeaknessContainer"):
			var w_cont: HBoxContainer = vbox.get_node("WeaknessContainer")
			for w_node in w_cont.get_children():
				if w_node is Label and w_node.has_meta("elem"):
					var w_elem: int = int(w_node.get_meta("elem"))
					if is_selecting and w_elem == attacker_elem:
						w_node.modulate = Color(1.8, 1.8, 1.8, 1.0)
						w_node.scale = Vector2(1.25, 1.25)
						w_node.pivot_offset = w_node.size * 0.5
					elif is_selecting:
						w_node.modulate = Color(0.65, 0.65, 0.65, 0.5)
						w_node.scale = Vector2.ONE
					else:
						w_node.modulate = Color.WHITE
						w_node.scale = Vector2.ONE

		# 3. Прогнозирование среза стойкости на полоске TghBar
		if not unit.is_ally and vbox.has_node("TghBar"):
			var tgh_bar: ProgressBar = vbox.get_node("TghBar")
			var will_take_tgh_dmg := false
			var mult := 1.0
			if is_selecting and unit.is_alive() and not unit.statuses.toughness_broken and unit.toughness > 0.0:
				var is_target: bool = (unit == _selected_target_unit)
				var is_sec: bool = (unit in secondaries)
				if (is_target or is_sec) and CombatConstants.element_matches_weakness(attacker_elem, unit.weaknesses):
					will_take_tgh_dmg = true
					if is_sec and not (_target_mode == "ult" and battle_manager.current_unit and battle_manager.current_unit.id == KaoriAbilities.ID):
						mult = 0.5
					else:
						mult = 1.0

			if will_take_tgh_dmg:
				var attacker := battle_manager.current_unit
				var eff: float = (1.0 + attacker.stats.weakness_efficiency) if attacker else 1.0
				var reduction: float = ToughnessSystem.BASE_TGH_REDUCTION * eff * mult
				unit.set_meta("projected_tgh_reduction", reduction)
			else:
				unit.remove_meta("projected_tgh_reduction")
			tgh_bar.queue_redraw()

func _update_targeting_reticles() -> void:
	_update_targeting_visuals()

func _get_affected_secondary_targets(primary: CombatUnit) -> Array[CombatUnit]:
	var secondaries: Array[CombatUnit] = []
	if primary == null or not primary.is_alive() or primary.is_ally:
		return secondaries
	var active := battle_manager.current_unit
	if active == null:
		return secondaries
	
	var is_blast: bool = false
	var is_aoe: bool = false
	
	match _target_mode:
		"basic":
			if active.id == "lenskaya" and int(active.get_meta("lenskaya_stinger_turns", 0)) > 0:
				is_blast = true
			elif active.id == "dasha" and bool(active.get_meta("circle_dance", false)):
				is_blast = true
			elif active.id == "musienko" and active.has_meta("musienko_annihilation_active"):
				is_blast = true
			# Ленская ЯА: обычная базовая — одиночная атака
			# Сёдзи ЛО: обычная базовая — одиночная атака
		"enhanced_basic":
			if active.id == "lenskaya" and int(active.get_meta("lenskaya_stinger_turns", 0)) > 0:
				is_blast = true
			elif active.id == "joan_spirit":
				is_blast = true
			elif active.id == "shoji_swan":
				is_blast = true
			elif active.id == "lenskaya_antimatter":
				var stance: String = String(active.get_meta("lenskaya_am_stance", "none"))
				if stance == "none":
					is_blast = true
		"skill":
			if active.id == ArseniyAbilities.ID:
				is_blast = true
			elif active.id == "naama":
				is_blast = true
			elif active.id == "lenskaya":
				var in_stinger: bool = int(active.get_meta("lenskaya_stinger_turns", 0)) > 0
				if in_stinger:
					is_blast = true
				else:
					is_aoe = true
			elif active.id == "isaac":
				is_aoe = true
			elif active.id == "keloist":
				is_aoe = true
			elif active.id == "valramors" and active.eidolon >= 6:
				is_aoe = true
			elif active.id == "isaac_admin":
				is_blast = true
			elif active.id == "shoji_swan":
				var stance: String = String(active.get_meta("shoji_swan_stance", "virus"))
				if stance == "virus":
					is_blast = true
				else:
					is_aoe = true
			elif active.id == "shoji" or active.id == ShojiAbilities.ID:
				is_blast = true
			elif active.id == "dasha":
				is_blast = true
			elif active.id == "vika":
				is_blast = true
			elif active.id == "dotseva":
				var in_fog: bool = int(active.get_meta("dotseva_fog_turns", 0)) > 0
				if in_fog:
					is_aoe = true
				else:
					is_blast = true
			elif active.id == "dotseva_crimson_tears":
				var zone_active: bool = bool(active.get_meta("doceva_tears_zone_active", false))
				if zone_active:
					is_blast = true
				else:
					is_aoe = true
			elif active.id == "lenskaya_antimatter":
				var stance: String = String(active.get_meta("lenskaya_am_stance", "none"))
				if stance == "none":
					is_blast = true
				elif stance == "warrior":
					var in_inv: bool = bool(active.get_meta("lenskaya_am_in_inverted", false))
					if in_inv:
						is_aoe = true
					else:
						is_blast = true
		"skill_e":
			if active.id == "lenskaya":
				is_blast = true
			elif active.id == "velzebul" and bool(active.get_meta("velzebul_e_enhanced", false)):
				is_blast = true
			elif active.id == "jeff":
				is_blast = true
			elif active.id == "isaac":
				is_blast = true
			elif active.id == "isaac_admin":
				is_blast = true
			elif active.id == "lenskaya_antimatter":
				var stance: String = String(active.get_meta("lenskaya_am_stance", "none"))
				if stance == "none":
					is_blast = true
		"ult":
			# Обычный Арсений — одиночная ульта!
			if active.id == "arseniy_admin":
				is_blast = true
			elif active.id == KaoriAbilities.ID:
				is_aoe = true
			elif active.id == "musienko":
				is_blast = true
			elif active.id == "valramors":
				is_blast = true
			elif active.id == "shoji_swan" or active.id == ShojiAbilities.ID:
				is_blast = true
			elif active.id == "vika":
				is_blast = true
			elif active.id == "katarina":
				if active.eidolon >= 2:
					is_aoe = true
				else:
					is_blast = true
			elif active.id == "lenskaya_antimatter":
				if active.eidolon >= 4:
					is_aoe = true
				
	if is_aoe:
		for e in battle_manager.get_living_enemies():
			if e != primary:
				secondaries.append(e)
	elif is_blast:
		for adj in battle_manager.get_adjacent_enemies(primary):
			if adj != primary and adj.is_alive():
				secondaries.append(adj)
				
	return secondaries

func _cycle_target(dir: int) -> void:
	if not _selecting_target:
		return
	var valid_targets: Array[CombatUnit] = []
	for u in _unit_panels:
		if u.is_alive():
			var p: PanelContainer = _unit_panels[u]
			var vbox: VBoxContainer = p.get_child(0)
			var btn: Button = vbox.get_node_or_null("TargetButton")
			if btn and btn.visible:
				valid_targets.append(u)
				
	if valid_targets.is_empty():
		return
		
	var cur_idx := valid_targets.find(_selected_target_unit)
	if cur_idx == -1:
		_selected_target_unit = valid_targets[0]
	else:
		var next_idx := (cur_idx + dir) % valid_targets.size()
		if next_idx < 0:
			next_idx += valid_targets.size()
		_selected_target_unit = valid_targets[next_idx]
		
	_update_targeting_visuals()

func _handle_ult_hotkey(ally_index: int) -> void:
	if ally_index < 0 or ally_index >= battle_manager.allies.size():
		return
	var target_ally := battle_manager.allies[ally_index]
	if target_ally == null or not target_ally.is_alive():
		return

	# Повторное нажатие горячей клавиши подтверждает ульту на выбранной цели
	if _selecting_target and _target_mode == "ult" and battle_manager.current_unit == target_ally and _selected_target_unit != null:
		_on_target_pressed(_selected_target_unit, _selected_target_unit.is_ally)
		return

	if _unit_panels.has(target_ally):
		var p: PanelContainer = _unit_panels[target_ally]
		var vbox: VBoxContainer = p.get_child(0)
		var ult_btn: Button = vbox.get_node_or_null("UltButtonOnCard")
		if ult_btn and not ult_btn.disabled:
			ult_btn.emit_signal("pressed")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
		
	if inspect_overlay.visible or _admin_open:
		return
		
	match key_event.keycode:
		KEY_W:
			if _selecting_target and (_target_mode == "basic" or _target_mode == "enhanced_basic") and _selected_target_unit != null:
				_on_target_pressed(_selected_target_unit, _selected_target_unit.is_ally)
			elif btn_enhanced_basic.visible and not btn_enhanced_basic.disabled:
				btn_enhanced_basic.emit_signal("pressed")
			elif btn_basic.visible and not btn_basic.disabled:
				btn_basic.emit_signal("pressed")
		KEY_Q:
			if _selecting_target and _target_mode == "skill" and _selected_target_unit != null:
				_on_target_pressed(_selected_target_unit, _selected_target_unit.is_ally)
			elif btn_skill.visible and not btn_skill.disabled:
				btn_skill.emit_signal("pressed")
		KEY_E:
			if _selecting_target and _target_mode == "skill_e" and _selected_target_unit != null:
				_on_target_pressed(_selected_target_unit, _selected_target_unit.is_ally)
			elif btn_skill_e.visible and not btn_skill_e.disabled:
				btn_skill_e.emit_signal("pressed")
		KEY_R:
			if btn_ult.visible and not btn_ult.disabled:
				btn_ult.emit_signal("pressed")
			elif battle_manager.current_unit and battle_manager.current_unit.is_ally:
				_handle_ult_hotkey(battle_manager.allies.find(battle_manager.current_unit))
		KEY_1:
			_handle_ult_hotkey(0)
		KEY_2:
			_handle_ult_hotkey(1)
		KEY_3:
			_handle_ult_hotkey(2)
		KEY_4:
			_handle_ult_hotkey(3)
		KEY_A, KEY_LEFT:
			_cycle_target(-1)
		KEY_D, KEY_RIGHT:
			_cycle_target(1)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if _selecting_target and _selected_target_unit != null:
				_on_target_pressed(_selected_target_unit, _selected_target_unit.is_ally)

# --- ХОР ЧЕЛОВЕЧЕСТВА (UI ПОДДЕРЖКИ) ---

func _on_btn_support_action_pressed() -> void:
	if battle_manager.chorus_charges < 12:
		return
	if _selecting_target and _target_mode == "chorus":
		_selecting_target = false
		_target_mode = ""
		_set_target_buttons_visible(false, false)
		return
	_selecting_target = true
	_target_mode = "chorus"
	_set_target_buttons_visible(false, true)
	_on_log("[Хор Человечества: Выберите союзника для наполнения силой!]")

func _on_chorus_charges_changed(_charges: int, _unlocked: bool) -> void:
	_refresh_support_button()

func _refresh_support_button() -> void:
	if not is_instance_valid(support_panel) or not is_instance_valid(btn_support_action):
		return
	support_panel.visible = battle_manager.chorus_unlocked
	if not battle_manager.chorus_unlocked:
		if _chorus_glow_tween != null and _chorus_glow_tween.is_valid():
			_chorus_glow_tween.kill()
		return

	var is_ready: bool = (battle_manager.chorus_charges >= 12)
	btn_support_action.disabled = not is_ready
	
	if is_ready:
		btn_support_action.text = "✨ ХОР ЧЕЛОВЕЧЕСТВА ✨\n[ГОТОВО К АКТИВАЦИИ]\n(12/12)"
		if _chorus_glow_tween == null or not _chorus_glow_tween.is_valid():
			_chorus_glow_tween = create_tween().set_loops()
			_chorus_glow_tween.tween_property(btn_support_action, "modulate", Color(2.4, 1.9, 1.2, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_chorus_glow_tween.tween_property(btn_support_action, "modulate", Color(1.5, 0.8, 1.1, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _chorus_glow_tween != null and _chorus_glow_tween.is_valid():
			_chorus_glow_tween.kill()
		btn_support_action.modulate = Color(1.0, 1.0, 1.0, 0.85)
		btn_support_action.text = "Помощь:\nХор Человечества\n(%d/12)" % battle_manager.chorus_charges

func _execute_chorus_ui(chosen_ally: CombatUnit) -> void:
	if chosen_ally == null or not chosen_ally.is_alive():
		return

	# 1. Затемнение экрана на 60%
	if is_instance_valid(chorus_dark_overlay):
		chorus_dark_overlay.show()
		chorus_dark_overlay.modulate.a = 1.0

	# 2. Розово-золотой прожектор на карточке выбранного союзника
	var ally_panel: PanelContainer = _unit_panels.get(chosen_ally, null)
	var spotlight: Panel = null
	if ally_panel != null:
		spotlight = Panel.new()
		spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var spot_style := StyleBoxFlat.new()
		spot_style.bg_color = Color(0.95, 0.72, 0.80, 0.40) # Розово-золотое свечение
		spot_style.border_color = Color(0.98, 0.85, 0.75, 1.0) # Розово-золотая рамка
		spot_style.set_border_width_all(4)
		spot_style.set_corner_radius_all(10)
		spotlight.add_theme_stylebox_override("panel", spot_style)
		ally_panel.add_child(spotlight)

	# 3. Плавное затухание за 1.5 секунды
	var tw := create_tween()
	tw.set_parallel(true)
	if is_instance_valid(chorus_dark_overlay):
		tw.tween_property(chorus_dark_overlay, "modulate:a", 0.0, 1.5)
	if spotlight != null:
		tw.tween_property(spotlight, "modulate:a", 0.0, 1.5)
	tw.chain().tween_callback(func():
		if is_instance_valid(chorus_dark_overlay):
			chorus_dark_overlay.hide()
		if is_instance_valid(spotlight):
			spotlight.queue_free()
	)

	# 4. Активация механики в боевом менеджере
	battle_manager.activate_chorus_of_humanity(chosen_ally)
	_refresh_support_button()
	for u in _unit_panels:
		_refresh_unit_panel(u)
