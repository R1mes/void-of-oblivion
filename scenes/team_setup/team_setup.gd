extends Control

@onready var roster_list: GridContainer = %RosterList
@onready var team_slots: HBoxContainer = %TeamSlots
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_name: Label = %DetailName
@onready var detail_desc: Label = %DetailDesc
@onready var eidolon_spin: SpinBox = %EidolonSpin
@onready var initiator_option: OptionButton = %InitiatorOption
@onready var start_button: Button = %StartButton
@onready var btn_save_team: Button = %BtnSaveTeam
@onready var btn_load_team: Button = %BtnLoadTeam

# UI-элементы для врагов
@onready var enemy_roster_list: VBoxContainer = %EnemyRosterList
@onready var enemy_slots: HBoxContainer = %EnemySlots

# Новые элементы управления и вкладок
@onready var btn_back: Button = %BtnBack
@onready var mode_option: OptionButton = %ModeOption
@onready var admin_tabs: TabContainer = %AdminTabs
@onready var enemy_custom_container: VBoxContainer = %EnemyCustomContainer
@onready var enemy_preset_notice: PanelContainer = %EnemyPresetNotice
@onready var enemy_preset_notice_label: Label = %EnemyPresetNoticeLabel
@onready var enemy_detail_name: Label = %EnemyDetailName
@onready var enemy_detail_desc: Label = %EnemyDetailDesc
@onready var btn_add_selected_to_team: Button = %BtnAddSelectedToTeam
@onready var btn_add_selected_to_enemy: Button = %BtnAddSelectedToEnemy
@onready var btn_clear_enemies: Button = %BtnClearEnemies
@onready var btn_preset_dummies: Button = %BtnPresetDummies
@onready var btn_preset_boss: Button = %BtnPresetBoss

var gear_overlay: ColorRect # Всплывающее окно снаряжения

# UI-элементы для режима «Тестовая среда»
var test_env_container: PanelContainer = null
var test_submode_option: OptionButton = null
var test_boss_hp_spin: SpinBox = null
var test_trio_boss_hp_spin: SpinBox = null
var test_trio_elite_hp_spin: SpinBox = null
var test_fiction_count_spin: SpinBox = null
var test_fiction_hp_spin: SpinBox = null
var test_boss_settings_box: VBoxContainer = null
var test_trio_settings_box: VBoxContainer = null
var test_fiction_settings_box: VBoxContainer = null

const TEAM_SIZE := 4
const ENEMY_TEAM_SIZE := 5

var _selected_char_id: String = ""
var _selected_enemy_id: String = ""

var _team: Array = [] # Array of {id, eidolon, light_cone, relics: {...}} or null
var _enemy_team: Array = [] # Array of {id} or null

const AVAILABLE_ENEMIES = [
	{
		"id": VoidSoldier.ID,
		"name": "Солдат Пустоты",
		"description": "Базовый противник. Физический элемент. Каждые 4 хода проводит атаку по площади."
	},
	{
		"id": VoidElite.ID,
		"name": "Элитный Страж",
		"description": "Опасный противник. Квантовый элемент. Наносит сильный AoE-урон и умеет лечить себя."
	},
	{
		"id": "void_boss",
		"name": "Повелитель Пустоты (Босс)",
		"description": "Могущественный Босс. Уязвимости: Физическая, Ветряная, Мнимая. Замораживает союзников и обрушивает разрушительный AoE-коллапс."
	},
	{
		"id": "void_armored",
		"name": "Бронированный Рыцарь (Элита)",
		"description": "Элитный враг. Уязвимости: Молния, Квант, Огонь. Каждые 4 хода активирует «Адскую броню» (−40% урона). Пробитие уязвимости ломает брою и удваивает урон пробития."
	},
	{
		"id": "void_dummy",
		"name": "Манекен-Мишень",
		"description": "Манекен со всеми уязвимостями для тестов."
	},
	{
		"id": "masked_silhouette",
		"name": "Силуэт в Маске",
		"description": "Ужасающий противник. Уязвимости: Электрическая, Квантовая, Мнимая"
	},
	{
		"id": "server_virus",
		"name": "Серверный Вирус (Босс)",
		"description": "Босс Консоли. Уязвимости: Физический, Электрический, Ветряной. Пробитие стойкости даёт +40 Векторов. Имеет 4 слоя Файрвола (-25% не-Бинарного урона, рушится Бинарным уроном). Запускает Переполнение буфера, Троян и Задержку пакетов."
	},
	{
		"id": "ortho_mutant",
		"name": "Орто Мутант (Элита)",
		"description": "Элитный мутант. Уязвимости: Мнимая, Квантовый, Ветряной. Пассивный Кислотный мутаген (DoT для активации Следа 3 Жоана на +50% КУ). Слабость к AoE (+30% урона). Призывает споры, гибель которых сносит ему 30 стойкости."
	},
	{
		"id": "infected",
		"name": "Заражённый",
		"description": "Обычный враг. Уязвимости: Физический, Электрический, Ветряной. Поражение даёт +4 Вектора Консоли. При HP < 30% взрывается при гибели (15% макс. HP соседним врагам)."
	},
	{
		"id": "ortofetamin_horror",
		"name": "Ужас ортофетамина (Элита)",
		"description": "Элитный враг. Уязвимости: Физическая, Электрическая, Ледяная. Тактика: Катарина и Доцева БС. Призывает Заражённых (Симбиоз колонии даёт до -20% урона). Наносит прицельные инъекции по сильнейшему союзнику."
	},
	{
		"id": "citadel_cleaner",
		"name": "Чистильщик Цитадели",
		"description": "Обычный враг Цитадели. Уязвимости: Ветряная, Огненная. Тактика: Консоль и DoT. Пассивная Сенсорная перегрузка (-10% защиты и задержка от DoT/Бинарного урона). Взрывается при гибели (6% ХП и Кровотечение)."
	},
	{
		"id": "shoji_vz",
		"name": "Сёдзи ВЗ (Босс)",
		"description": "Босс Цитадели (2 фазы). Уязвимости: Ветряная, Квантовая, Огненная. Тактика: Консоль и DoT (Сёдзи • Лебединое озеро). Брандмауэр снижает прямой урон на 10%. Во 2 фазе получает до +30% урона от каждого DoT."
	},
	{
		"id": "velzebul_boss",
		"name": "Вельзевул (Босс)",
		"description": "Могущественный Босс Антиматерии (2 фазы). Уязвимости: Физическая, Ветряная, Квантовая (40% сопр. к Льду). Тактика: Катарина и Доцева БС. Панцирь Антиматерии, разрушительные атаки и внутренняя нестабильность ядра."
	},
	{
		"id": "rimes_final_boss",
		"name": "Раймс • Финальный босс (Недельный босс)",
		"description": "Недельный босс (3 фазы). Уязвимости: Квантовая, Ледяная, Физическая (40% сопр. к Мнимому). Не может быть казнён или разделен. Со 2 фазы активирует Помощь «Хор Человечества». В 3 фазе призывает Лапы Ничто и готовит ультимейт «По воле дирижёра»."
	},
	{
		"id": "your_memories",
		"name": "Твои воспоминания (Элита)",
		"description": "Элитный противник (Мнимый). Уязвимости: Квантовая, Ледяная, Электрическая. Тактика: Вельзевул и Марина. Пассивка «Отражение на льду» (+15% ледяного урона атакующему при дебаффе) и «Тяжесть прошлого»."
	},
	{
		"id": "antimatter_slave",
		"name": "Раб Антиматерии",
		"description": "Рядовой враг Антиматерии. Уязвимости: Ветряная, Огненная. Пассивная Сингулярность (-25% входящего урона до пробития стойкости). Атаки Духов Памяти истощают 25 стойкости и продвигают владельца на 15%. Пробитие стойкости («Коллапс сингулярности») наносит 15% макс. ХП и -15 стойкости другим врагам."
	},
	{
		"id": "insurgent",
		"name": "Восставший (Элита)",
		"description": "Элитный мятежник. Уязвимости: Мнимая, Электрическая, Квантовая. Пассивная стойкость (-20% входящего урона до пробития). Каждые 3 хода готовит «Неумолимый бунт» (AoE 160% СА). Пробитие стойкости срывает подготовку, задерживает ход на 40% и накладывает «Сломленный дух» (+100% уязвимости к пробитию/суперпробитию, -20% защиты)."
	},
	{
		"id": "kyle_rebel_leader",
		"name": "Кайл • Лидер восстания (Босс)",
		"description": "Босс Восстания (2 фазы). Уязвимости: Ветряная, Квантовая, Физическая. Фаза 1: «Завеса восстания» (3 стака, -45% урона). Атаки Духов Памяти снимают стак, накладывают «Раскол разума» (+15% уязвимости), истощают 20 стойкости и дают 5 энергии команде. Дух блокирует 70% «Казни тиранов». Фаза 2 (400 000 ХП): «Сокрушение оков» (Дух Памяти укрывает союзников щитом) и «Ультимативный приговор» (Дух отвлекает удар: 0 урона, +25% КУ команде)."
	}
]

func _ready() -> void:
	_team.resize(TEAM_SIZE)
	for i in TEAM_SIZE:
		_team[i] = null
		
	_enemy_team.resize(ENEMY_TEAM_SIZE)
	for i in ENEMY_TEAM_SIZE:
		_enemy_team[i] = null

	# Создаем директорию для хранения пресетов, если её нет
	DirAccess.make_dir_absolute("user://presets/")

	# Скрываем старые контроли Конусов и Эйдолонов с главного экрана
	eidolon_spin.hide()
	if eidolon_spin.get_parent() is Control:
		eidolon_spin.get_parent().visible = false

	# Кнопка возврата в главное меню
	if btn_back:
		btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))

	# Настройка селектора режимов боя
	mode_option.clear()
	mode_option.add_item("Свой бой (настройка врагов)", 0)
	mode_option.set_item_metadata(0, "custom")
	mode_option.add_item("Босс-файт (Повелитель Пустоты)", 1)
	mode_option.set_item_metadata(1, "boss")
	mode_option.add_item("Чистый вымысел (15 Солдат)", 2)
	mode_option.set_item_metadata(2, "fiction")
	mode_option.add_item("🧪 Тестовая среда", 3)
	mode_option.set_item_metadata(3, "test_env")
	mode_option.select(0)
	mode_option.item_selected.connect(_on_mode_selected)

	_build_test_env_ui()

	# Восстановление экипированного снаряжения из TeamConfig с сохранением оригинальных слотов
	if not TeamConfig.team_members.is_empty():
		for member in TeamConfig.team_members:
			var slot_idx: int = int(member.get("slot_idx", -1))
			if slot_idx >= 0 and slot_idx < TEAM_SIZE:
				_team[slot_idx] = member.duplicate()
		_sanitize_team_light_cones()
			
	if not TeamConfig.enemy_members.is_empty() and TeamConfig.battle_mode == "custom":
		for enemy in TeamConfig.enemy_members:
			var slot_idx: int = int(enemy.get("slot_idx", -1))
			if slot_idx >= 0 and slot_idx < ENEMY_TEAM_SIZE:
				_enemy_team[slot_idx] = enemy.duplicate()

	_build_roster()
	_build_team_slots()
	_build_enemy_roster()
	_build_enemy_slots()

	# Принудительное обновление интерфейса при первой загрузке лобби
	_refresh_team_slots()
	_refresh_enemy_slots()
	_refresh_initiator_options()

	start_button.pressed.connect(_on_start_pressed)
	btn_save_team.pressed.connect(_show_save_team_dialog)
	btn_load_team.pressed.connect(_show_load_team_dialog)
	initiator_option.item_selected.connect(_on_initiator_changed)

	# Подключение кнопок быстрого добавления и пресетов врагов
	if btn_add_selected_to_team:
		btn_add_selected_to_team.pressed.connect(_on_add_selected_to_team_pressed)
	if btn_add_selected_to_enemy:
		btn_add_selected_to_enemy.pressed.connect(_on_add_selected_to_enemy_pressed)
	if btn_clear_enemies:
		btn_clear_enemies.pressed.connect(_on_clear_enemies_pressed)
	if btn_preset_dummies:
		btn_preset_dummies.pressed.connect(_on_preset_dummies_pressed)
	if btn_preset_boss:
		btn_preset_boss.pressed.connect(_on_preset_boss_pressed)

	_select_character(MarinaAbilities.ID)
	_select_enemy(AVAILABLE_ENEMIES[0].id)

func _build_test_env_ui() -> void:
	if test_env_container != null or enemy_preset_notice == null:
		return
		
	var parent_box := enemy_preset_notice.get_parent()
	test_env_container = PanelContainer.new()
	test_env_container.visible = false
	test_env_container.custom_minimum_size = Vector2(0, 260)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	test_env_container.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Заголовок
	var title_lbl := Label.new()
	title_lbl.text = "🧪 НАСТРОЙКА ТЕСТОВОЙ СРЕДЫ (SANDBOX)"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox.add_child(title_lbl)
	
	# Выбор подрежима
	var submode_row := HBoxContainer.new()
	submode_row.add_theme_constant_override("separation", 12)
	vbox.add_child(submode_row)
	
	var submode_lbl := Label.new()
	submode_lbl.text = "Режим тестирования:"
	submode_lbl.add_theme_font_size_override("font_size", 14)
	submode_row.add_child(submode_lbl)
	
	test_submode_option = OptionButton.new()
	test_submode_option.custom_minimum_size = Vector2(280, 36)
	test_submode_option.add_item("👑 Босс (Тест Босс)", 0)
	test_submode_option.set_item_metadata(0, "boss")
	test_submode_option.add_item("⚔ 3 противника (Босс + 2 Элиты)", 1)
	test_submode_option.set_item_metadata(1, "trio")
	test_submode_option.add_item("🌊 Чистый вымысел (30 противников)", 2)
	test_submode_option.set_item_metadata(2, "fiction")
	test_submode_option.select(0)
	test_submode_option.item_selected.connect(_on_test_submode_changed)
	submode_row.add_child(test_submode_option)
	
	# Контейнер настроек Босса
	test_boss_settings_box = VBoxContainer.new()
	test_boss_settings_box.add_theme_constant_override("separation", 8)
	vbox.add_child(test_boss_settings_box)
	
	var boss_hp_row := HBoxContainer.new()
	boss_hp_row.add_theme_constant_override("separation", 10)
	test_boss_settings_box.add_child(boss_hp_row)
	
	var boss_hp_lbl := Label.new()
	boss_hp_lbl.text = "Здоровье Тест Босса (HP):"
	boss_hp_row.add_child(boss_hp_lbl)
	
	test_boss_hp_spin = SpinBox.new()
	test_boss_hp_spin.min_value = 10000
	test_boss_hp_spin.max_value = 100000000
	test_boss_hp_spin.step = 50000
	test_boss_hp_spin.value = 1500000
	test_boss_hp_spin.custom_minimum_size = Vector2(160, 32)
	boss_hp_row.add_child(test_boss_hp_spin)
	
	# Контейнер настроек 3 противников
	test_trio_settings_box = VBoxContainer.new()
	test_trio_settings_box.add_theme_constant_override("separation", 8)
	test_trio_settings_box.visible = false
	vbox.add_child(test_trio_settings_box)
	
	var trio_boss_row := HBoxContainer.new()
	trio_boss_row.add_theme_constant_override("separation", 10)
	test_trio_settings_box.add_child(trio_boss_row)
	var trio_b_lbl := Label.new()
	trio_b_lbl.text = "Здоровье Босса (HP):"
	trio_boss_row.add_child(trio_b_lbl)
	test_trio_boss_hp_spin = SpinBox.new()
	test_trio_boss_hp_spin.min_value = 10000
	test_trio_boss_hp_spin.max_value = 100000000
	test_trio_boss_hp_spin.step = 50000
	test_trio_boss_hp_spin.value = 1200000
	test_trio_boss_hp_spin.custom_minimum_size = Vector2(160, 32)
	trio_boss_row.add_child(test_trio_boss_hp_spin)
	
	var trio_elite_row := HBoxContainer.new()
	trio_elite_row.add_theme_constant_override("separation", 10)
	test_trio_settings_box.add_child(trio_elite_row)
	var trio_e_lbl := Label.new()
	trio_e_lbl.text = "Здоровье каждой Элиты (HP):"
	trio_elite_row.add_child(trio_e_lbl)
	test_trio_elite_hp_spin = SpinBox.new()
	test_trio_elite_hp_spin.min_value = 10000
	test_trio_elite_hp_spin.max_value = 50000000
	test_trio_elite_hp_spin.step = 25000
	test_trio_elite_hp_spin.value = 500000
	test_trio_elite_hp_spin.custom_minimum_size = Vector2(160, 32)
	trio_elite_row.add_child(test_trio_elite_hp_spin)
	
	# Контейнер настроек Чистого вымысла
	test_fiction_settings_box = VBoxContainer.new()
	test_fiction_settings_box.add_theme_constant_override("separation", 8)
	test_fiction_settings_box.visible = false
	vbox.add_child(test_fiction_settings_box)
	
	var fic_count_row := HBoxContainer.new()
	fic_count_row.add_theme_constant_override("separation", 10)
	test_fiction_settings_box.add_child(fic_count_row)
	var fic_c_lbl := Label.new()
	fic_c_lbl.text = "Общее количество противников:"
	fic_count_row.add_child(fic_c_lbl)
	test_fiction_count_spin = SpinBox.new()
	test_fiction_count_spin.min_value = 5
	test_fiction_count_spin.max_value = 200
	test_fiction_count_spin.step = 5
	test_fiction_count_spin.value = 30
	test_fiction_count_spin.custom_minimum_size = Vector2(160, 32)
	fic_count_row.add_child(test_fiction_count_spin)
	
	var fic_hp_row := HBoxContainer.new()
	fic_hp_row.add_theme_constant_override("separation", 10)
	test_fiction_settings_box.add_child(fic_hp_row)
	var fic_h_lbl := Label.new()
	fic_h_lbl.text = "Здоровье каждого противника (HP):"
	fic_hp_row.add_child(fic_h_lbl)
	test_fiction_hp_spin = SpinBox.new()
	test_fiction_hp_spin.min_value = 1000
	test_fiction_hp_spin.max_value = 10000000
	test_fiction_hp_spin.step = 5000
	test_fiction_hp_spin.value = 70000
	test_fiction_hp_spin.custom_minimum_size = Vector2(160, 32)
	fic_hp_row.add_child(test_fiction_hp_spin)
	
	# Информационный блок с правилами
	var rules_lbl := Label.new()
	rules_lbl.text = "📋 Правила Тестовой среды:\n• Крит. шанс всех союзников = 100% (избыток >100% конвертируется: 1% КШ = 1.5% КУ)\n• Фиксированный сид RNG: детерминированный выбор целей и отскоков между всеми запусками\n• Сопротивление эффектам у всех врагов = 0%\n• Защита противников: Босс — 1200, Элиты — 800, Обычные — 400"
	rules_lbl.add_theme_font_size_override("font_size", 13)
	rules_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(rules_lbl)
	
	parent_box.add_child(test_env_container)

func _on_test_submode_changed(idx: int) -> void:
	if test_submode_option == null:
		return
	var submode: String = test_submode_option.get_item_metadata(idx)
	if test_boss_settings_box:
		test_boss_settings_box.visible = (submode == "boss")
	if test_trio_settings_box:
		test_trio_settings_box.visible = (submode == "trio")
	if test_fiction_settings_box:
		test_fiction_settings_box.visible = (submode == "fiction")

func _on_mode_selected(index: int) -> void:
	var mode: String = mode_option.get_item_metadata(index)
	var is_custom: bool = (mode == "custom")
	var is_test_env: bool = (mode == "test_env")
	if enemy_custom_container:
		enemy_custom_container.visible = is_custom
	if enemy_preset_notice:
		enemy_preset_notice.visible = not is_custom and not is_test_env
		if not is_custom and not is_test_env:
			if mode == "boss":
				enemy_preset_notice_label.text = "👑 В режиме «Босс-файт» противником выступает Повелитель Пустоты (117 000 HP, 360 стойкости).\nВраги будут выставлены автоматически при запуске боя."
			elif mode == "fiction":
				enemy_preset_notice_label.text = "⚔ В режиме «Чистый вымысел» противниками выступают 15 Солдат Пустоты (волнами по 5).\nВраги будут выставлены автоматически при запуске боя."
	if test_env_container:
		test_env_container.visible = is_test_env

func _on_add_selected_to_team_pressed() -> void:
	if _selected_char_id.is_empty():
		return
	for slot in _team:
		if slot != null and slot.id == _selected_char_id:
			return
	for i in TEAM_SIZE:
		if _team[i] == null:
			_add_to_slot(i)
			break

func _on_add_selected_to_enemy_pressed() -> void:
	if _selected_enemy_id.is_empty():
		return
	for i in ENEMY_TEAM_SIZE:
		if _enemy_team[i] == null:
			_add_enemy_to_slot(i)
			break

func _on_clear_enemies_pressed() -> void:
	for i in ENEMY_TEAM_SIZE:
		_enemy_team[i] = null
	_refresh_enemy_slots()

func _on_preset_dummies_pressed() -> void:
	for i in ENEMY_TEAM_SIZE:
		_enemy_team[i] = {"id": "void_dummy"}
	_refresh_enemy_slots()

func _on_preset_boss_pressed() -> void:
	_enemy_team[0] = {"id": VoidElite.ID}
	_enemy_team[1] = null
	_enemy_team[2] = {"id": "void_boss"}
	_enemy_team[3] = null
	_enemy_team[4] = {"id": VoidElite.ID}
	_refresh_enemy_slots()

func _build_roster() -> void:
	for child in roster_list.get_children():
		child.queue_free()

	roster_list.columns = 7
	roster_list.add_theme_constant_override("h_separation", 8)
	roster_list.add_theme_constant_override("v_separation", 8)

	for char_data in CharacterRegistry.get_available_characters():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(108, 90)
		btn.clip_contents = true
		btn.pressed.connect(_on_roster_member_pressed.bind(char_data.id))

		var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_data.id)
		if splash_tex != null:
			var bg_tex := TextureRect.new()
			bg_tex.name = "RosterSplashBG"
			bg_tex.texture = splash_tex
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_tex.modulate = Color(0.38, 0.38, 0.45, 0.38)
			bg_tex.z_index = 0
			btn.add_child(bg_tex)

		roster_list.add_child(btn)

		var label := RichTextLabel.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.bbcode_enabled = true
		
		var elem_color_hex: String = CombatConstants.get_element_color(char_data.element).to_html(false)
		var elem_label: String = CombatConstants.get_element_label(char_data.element)
		label.text = "[center]\n[color=#%s][font_size=14][b]%s[/b][/font_size][/color]\n[font_size=13][b]%s[/b][/font_size]\n[color=gray][font_size=11][%s][/font_size][/color][/center]" % [
			elem_color_hex,
			elem_label,
			char_data.name,
			_get_path_name(char_data.path)
		]
		btn.add_child(label)
		
func _on_roster_member_pressed(char_id: String) -> void:
	_select_character(char_id)
	
	for slot in _team:
		if slot != null and slot.id == char_id:
			return 
			
	var free_idx: int = -1
	for i in TEAM_SIZE:
		if _team[i] == null:
			free_idx = i
			break
			
	if free_idx != -1:
		_add_to_slot(free_idx)

func _build_team_slots() -> void:
	for child in team_slots.get_children():
		child.queue_free()

	for i in TEAM_SIZE:
		var slot := _create_slot_panel(i)
		team_slots.add_child(slot)

func _create_slot_panel(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(185, 210)
	panel.clip_contents = true

	var vbox := VBoxContainer.new()
	vbox.name = "SlotVBox"
	vbox.z_index = 1
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = "Слот %d" % (index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.text = "Пусто"
	vbox.add_child(name_label)

	var add_btn := Button.new()
	add_btn.name = "AddButton"
	add_btn.text = "+ Добавить"
	add_btn.custom_minimum_size = Vector2(0, 42)
	add_btn.add_theme_font_size_override("font_size", 14)
	add_btn.pressed.connect(_add_to_slot.bind(index))
	vbox.add_child(add_btn)

	var equip_btn := Button.new()
	equip_btn.name = "EquipButton"
	equip_btn.text = "🛡 Снаряжение"
	equip_btn.custom_minimum_size = Vector2(0, 42)
	equip_btn.add_theme_font_size_override("font_size", 14)
	equip_btn.pressed.connect(_open_equip_panel.bind(index))
	equip_btn.visible = false 
	vbox.add_child(equip_btn)

	var remove_btn := Button.new()
	remove_btn.name = "RemoveButton"
	remove_btn.text = "Убрать"
	remove_btn.custom_minimum_size = Vector2(0, 38)
	remove_btn.add_theme_font_size_override("font_size", 14)
	remove_btn.pressed.connect(_remove_from_slot.bind(index))
	vbox.add_child(remove_btn)

	return panel
	
func _build_enemy_roster() -> void:
	for child in enemy_roster_list.get_children():
		child.queue_free()

	for enemy_data in AVAILABLE_ENEMIES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		btn.text = "👾  " + enemy_data.name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_select_enemy.bind(enemy_data.id))
		enemy_roster_list.add_child(btn)

func _build_enemy_slots() -> void:
	for child in enemy_slots.get_children():
		child.queue_free()

	for i in ENEMY_TEAM_SIZE:
		var slot := _create_enemy_slot_panel(i)
		enemy_slots.add_child(slot)

func _create_enemy_slot_panel(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 160)
	panel.clip_contents = true

	var vbox := VBoxContainer.new()
	vbox.name = "SlotVBox"
	vbox.z_index = 1
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = "Враг %d" % (index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.text = "Пусто"
	vbox.add_child(name_label)

	var add_btn := Button.new()
	add_btn.name = "AddButton"
	add_btn.text = "+ Добавить"
	add_btn.custom_minimum_size = Vector2(0, 36)
	add_btn.add_theme_font_size_override("font_size", 13)
	add_btn.pressed.connect(_add_enemy_to_slot.bind(index))
	vbox.add_child(add_btn)

	var remove_btn := Button.new()
	remove_btn.name = "RemoveButton"
	remove_btn.text = "Убрать"
	remove_btn.custom_minimum_size = Vector2(0, 36)
	remove_btn.add_theme_font_size_override("font_size", 13)
	remove_btn.pressed.connect(_remove_enemy_from_slot.bind(index))
	vbox.add_child(remove_btn)

	return panel

func _select_character(char_id: String) -> void:
	_selected_char_id = char_id
	var data := CharacterRegistry.get_character(char_id)
	if data.is_empty():
		return

	var elem_name: String = CombatConstants.get_element_name(data.element)
	detail_name.text = "%s %s  •  %s  [%s]" % [
		CombatConstants.ELEMENT_SYMBOLS[data.element],
		data.name,
		elem_name,
		_get_path_name(data.path)
	]
	detail_desc.text = data.description

func _select_enemy(enemy_id: String) -> void:
	_selected_enemy_id = enemy_id
	var selected_enemy_data := {}
	for enemy in AVAILABLE_ENEMIES:
		if enemy.id == enemy_id:
			selected_enemy_data = enemy
			break
			
	if selected_enemy_data.is_empty():
		return

	if enemy_detail_name:
		enemy_detail_name.text = selected_enemy_data.name
	if enemy_detail_desc:
		enemy_detail_desc.text = selected_enemy_data.description

func _add_to_slot(index: int) -> void:
	if _selected_char_id.is_empty():
		return
	for slot in _team:
		if slot != null and slot.id == _selected_char_id:
			return

	# Загружаем сохраненную сборку игрока, либо оригинальный базовый пресет по умолчанию
	var saved_build: Dictionary = TeamConfig.get_saved_build(_selected_char_id)
	_team[index] = saved_build.duplicate(true)
	
	var lc_id: String = String(_team[index].get("light_cone", ""))
	if not lc_id.is_empty() and not TeamConfig.can_equip_light_cone(_selected_char_id, lc_id, _team):
		_team[index]["light_cone"] = ""
	
	_refresh_team_slots()
	_refresh_initiator_options()
	
func _remove_from_slot(index: int) -> void:
	_team[index] = null
	_refresh_team_slots()
	_refresh_initiator_options()

func _add_enemy_to_slot(index: int) -> void:
	if _selected_enemy_id.is_empty():
		return
	_enemy_team[index] = {"id": _selected_enemy_id}
	_refresh_enemy_slots()

func _remove_enemy_from_slot(index: int) -> void:
	_enemy_team[index] = null
	_refresh_enemy_slots()

func _refresh_team_slots() -> void:
	var children: Array = team_slots.get_children()
	for i in mini(children.size(), TEAM_SIZE):
		var panel: PanelContainer = children[i]
		var vbox: VBoxContainer = panel.get_node_or_null("SlotVBox") as VBoxContainer
		if vbox == null:
			vbox = panel.get_child(0) as VBoxContainer
		if vbox == null:
			continue
		var name_label: Label = vbox.get_node("NameLabel")
		var add_btn: Button = vbox.get_node("AddButton")
		var equip_btn: Button = vbox.get_node("EquipButton")
		var slot_data = _team[i]
		var splash_bg: TextureRect = panel.get_node_or_null("SlotSplashBG") as TextureRect
		
		if slot_data == null:
			name_label.text = "Пусто"
			add_btn.show()
			equip_btn.hide()
			if splash_bg:
				splash_bg.visible = false
		else:
			var data := CharacterRegistry.get_character(slot_data.id)
			var lc_text := ""
			if slot_data.get("light_cone", "") != "":
				var cone = LightConeRegistry.get_cone(slot_data.light_cone)
				lc_text = "\n[%s]" % cone.get("name", "Конус")
			name_label.text = "%s\nE%d%s" % [data.get("name", "?"), slot_data.eidolon, lc_text]
			add_btn.hide()
			equip_btn.show()

			var splash_tex: Texture2D = CharacterRegistry.get_character_splash(slot_data.id)
			if splash_tex != null:
				if splash_bg == null:
					splash_bg = TextureRect.new()
					splash_bg.name = "SlotSplashBG"
					splash_bg.z_index = 0
					splash_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					splash_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
					splash_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
					splash_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					panel.add_child(splash_bg)
				splash_bg.texture = splash_tex
				splash_bg.modulate = Color(0.38, 0.38, 0.42, 0.35)
				splash_bg.visible = true
			elif splash_bg != null:
				splash_bg.visible = false

func _refresh_enemy_slots() -> void:
	var children: Array = enemy_slots.get_children()
	for i in mini(children.size(), ENEMY_TEAM_SIZE):
		var panel: PanelContainer = children[i]
		var vbox: VBoxContainer = panel.get_node_or_null("SlotVBox") as VBoxContainer
		if vbox == null:
			vbox = panel.get_child(0) as VBoxContainer
		if vbox == null:
			continue
		var name_label: Label = vbox.get_node("NameLabel")
		var slot_data = _enemy_team[i]
		var splash_bg: TextureRect = panel.get_node_or_null("EnemySlotSplashBG") as TextureRect

		if slot_data == null:
			name_label.text = "Пусто"
			if splash_bg:
				splash_bg.visible = false
		else:
			var name_str := "Неизвестно"
			for enemy in AVAILABLE_ENEMIES:
				if enemy.id == slot_data.id:
					name_str = enemy.name
					break
			name_label.text = name_str

			var splash_tex: Texture2D = CharacterRegistry.get_character_splash(slot_data.id)
			if splash_tex != null:
				if splash_bg == null:
					splash_bg = TextureRect.new()
					splash_bg.name = "EnemySlotSplashBG"
					splash_bg.z_index = 0
					splash_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					splash_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
					splash_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
					splash_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					panel.add_child(splash_bg)
				splash_bg.texture = splash_tex
				splash_bg.modulate = Color(0.40, 0.32, 0.42, 0.35)
				splash_bg.visible = true
			elif splash_bg != null:
				splash_bg.visible = false

func _refresh_initiator_options() -> void:
	initiator_option.clear()
	var idx: int = 0
	for slot in _team:
		if slot != null:
			if slot.id in ["pusenkov", "kaori", "shoji", "dasha", "vika", "rimes", "musienko", "joan", "joan_spirit", "isaac_admin", "shoji_swan", "lenskaya_antimatter", "lenskaya_sky_guardian", "rimes_ascension"]:
				var data := CharacterRegistry.get_character(slot.id)
				initiator_option.add_item(data.get("name", slot.id))
				initiator_option.set_item_metadata(idx, slot.id)
				idx += 1
	if idx == 0:
		initiator_option.add_item("Без атакующей техники")
		initiator_option.set_item_metadata(0, "")
		
func _on_initiator_changed(_index: int) -> void:
	pass

# --- ВСПЛЫВАЮЩИЙ ИНТЕРФЕЙС НАСТРОЙКИ СНАРЯЖЕНИЯ И РЕЛИКВИЙ (МЕНЮ) ---
# === ПОЛНОСТЬЮ ЗАМЕНИТЕ ЭТОТ МЕТОД В TEAM_SETUP.GD ===
func _open_equip_panel(index: int) -> void:
	var slot_data = _team[index]
	if slot_data == null:
		return
		
	var data := CharacterRegistry.get_character(slot_data.id)
	
	gear_overlay = ColorRect.new()
	gear_overlay.color = Color(0, 0, 0, 0.85)
	gear_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gear_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gear_overlay.add_child(center)
	
	var panel := PanelContainer.new()
	# Меню настройки снаряжения увеличено под мобильные дисплеи
	panel.custom_minimum_size = Vector2(650, 850) 
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "🛡 Снаряжение: %s" % data.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26) # Увеличен шрифт заголовка
	vbox.add_child(title)
	
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 15)
	vbox.add_child(grid)
	
	# Выбор Эйдолона
	var eid_lbl := Label.new()
	eid_lbl.text = "Уровень Эйдолона:"
	eid_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(eid_lbl)
	
	var eid_select := SpinBox.new()
	eid_select.min_value = 0
	eid_select.max_value = 6
	eid_select.value = slot_data.get("eidolon", 0)
	eid_select.custom_minimum_size = Vector2(320, 48)
	eid_select.add_theme_font_size_override("font_size", 16)
	grid.add_child(eid_select)
	
	# Оружие
	var lc_lbl := Label.new()
	lc_lbl.text = "Световой Конус:"
	lc_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(lc_lbl)
	
	var lc_select := OptionButton.new()
	lc_select.custom_minimum_size = Vector2(320, 48)
	lc_select.add_theme_font_size_override("font_size", 16)
	lc_select.add_item("Без оружия")
	lc_select.set_item_metadata(0, "")
	var lc_idx: int = 1
	var current_lc_select_idx: int = 0
	for lc in LightConeRegistry.LIST:
		if lc.path == data.path:
			lc_select.add_item("%s (%d★)" % [lc.name, lc.rarity])
			lc_select.set_item_metadata(lc_idx, lc.id)
			if lc.id == slot_data.get("light_cone", ""):
				current_lc_select_idx = lc_idx
			lc_idx += 1
	lc_select.select(current_lc_select_idx)
	lc_select.visible = false

	var lc_btn := Button.new()
	lc_btn.custom_minimum_size = Vector2(320, 48)
	lc_btn.add_theme_font_size_override("font_size", 15)
	_update_team_setup_lc_btn(lc_btn, slot_data.get("light_cone", ""))
	lc_btn.pressed.connect(func():
		_open_team_setup_light_cone_dialog(index, lc_btn, lc_select)
	)

	var lc_container := HBoxContainer.new()
	lc_container.custom_minimum_size = Vector2(320, 48)
	lc_container.add_child(lc_btn)
	lc_container.add_child(lc_select)
	grid.add_child(lc_container)
	
	var sep1 := HSeparator.new()
	grid.add_child(sep1)
	var sep2 := HSeparator.new()
	grid.add_child(sep2)
	
	# Реликвии
	var relics: Dictionary = slot_data.get("relics", {})
	
	# Выбор Схемы Комплекта Пещерных реликвий
	var type_lbl := Label.new()
	type_lbl.text = "Схема комплекта:"
	type_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(type_lbl)
	
	var type_select := OptionButton.new()
	type_select.custom_minimum_size = Vector2(320, 48)
	type_select.add_theme_font_size_override("font_size", 16)
	type_select.add_item("Без комплекта", 0)
	type_select.add_item("4 части (Один сет)", 1)
	type_select.add_item("2+2 части (Два разных сета)", 2)
	grid.add_child(type_select)
	
	# Выпадающий список Пещерного сета 1
	var set1_lbl := Label.new()
	set1_lbl.text = "Пещерный сет 1:"
	set1_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(set1_lbl)
	
	var cavern_sets := [
		{"name": "Жертва долгого симбиоза", "id": "symbiosis"},
		{"name": "Истинный родоначальник хаоса", "id": "chaos"},
		{"name": "Отпор бренного мира", "id": "mortal_world"},
		{"name": "Боец огня и лавы", "id": "lava_fighter"},
		{"name": "Принявший дар света", "id": "light_gift"},
		{"name": "Дающий луч надежды путник", "id": "hope_beam"},
		{"name": "Отряд быстрого реагирования", "id": "rapid_response"},
		{"name": "Доктор биологических наук", "id": "biology_doctor"},
		{"name": "Оборона умирающей планеты", "id": "dying_planet"},
		{"name": "Потерянное в вечности Я", "id": "lost_self"},
		{"name": "Галилеянин изолированного мира", "id": "galilean"},
		{"name": "Прячущийся во тьме силуэт", "id": "silhouette"},
		{"name": "Принявший грех глава", "id": "accepted_sin"},
		{"name": "Исследователь отнятого будущего", "id": "bereft_future"},
		{"name": "След из повреждённых строк", "id": "damaged_strings"},
		{"name": "Дитя умирающих звёзд", "id": "dying_stars_child"},
		{"name": "Перебежщик тёмной стороны", "id": "dark_side_defector"},
		{"name": "Защитница цветущей земли", "id": "bloom_defender"},
	]
	
	var set1_select := OptionButton.new()
	set1_select.custom_minimum_size = Vector2(320, 48)
	set1_select.add_theme_font_size_override("font_size", 16)
	for s_idx in cavern_sets.size():
		set1_select.add_item(cavern_sets[s_idx].name)
		set1_select.set_item_metadata(s_idx, cavern_sets[s_idx].id)
	grid.add_child(set1_select)
	
	# Выпадающий список Пещерного сета 2
	var set2_lbl := Label.new()
	set2_lbl.text = "Пещерный сет 2:"
	set2_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(set2_lbl)
	
	var set2_select := OptionButton.new()
	set2_select.custom_minimum_size = Vector2(320, 48)
	set2_select.add_theme_font_size_override("font_size", 16)
	for s_idx in cavern_sets.size():
		set2_select.add_item(cavern_sets[s_idx].name)
		set2_select.set_item_metadata(s_idx, cavern_sets[s_idx].id)
	grid.add_child(set2_select)
	
	# Восстанавливаем состояние комплектов
	var cur_s1: String = String(relics.get("cavern_set_1", ""))
	var cur_s2: String = String(relics.get("cavern_set_2", ""))
	
	if cur_s1 == "":
		type_select.select(0)
	elif cur_s2 == "":
		type_select.select(1)
		for i in set1_select.item_count:
			if set1_select.get_item_metadata(i) == cur_s1:
				set1_select.select(i)
	else:
		type_select.select(2)
		for i in set1_select.item_count:
			if set1_select.get_item_metadata(i) == cur_s1:
				set1_select.select(i)
		for i in set2_select.item_count:
			if set2_select.get_item_metadata(i) == cur_s2:
				set2_select.select(i)
				
	# Динамически скрываем/показываем выпадающие списки в зависимости от выбора
	var update_visibility := func():
		var sel: int = type_select.selected
		set1_lbl.visible = (sel > 0)
		set1_select.visible = (sel > 0)
		set2_lbl.visible = (sel == 2)
		set2_select.visible = (sel == 2)
		
	type_select.item_selected.connect(func(_idx): update_visibility.call())
	update_visibility.call() 
	
	# Наложение всплывающих окон описания (Тултипов) при наведении мыши на комплекты
	_apply_relic_tooltips(set1_select, true)
	_apply_relic_tooltips(set2_select, true)
	
	# 3. Характеристики тела и ног
	var body_lbl := Label.new()
	body_lbl.text = "Тело (Характеристика):"
	body_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(body_lbl)
	
	var body_select := OptionButton.new()
	body_select.custom_minimum_size = Vector2(320, 48)
	body_select.add_theme_font_size_override("font_size", 16)
	var body_stats := [
		{"name": "21% Силы Атаки", "id": "atk_pct"},
		{"name": "26% Защиты", "id": "def_pct"},
		{"name": "21% ШПЭ", "id": "ehr"},
		{"name": "21% ХП", "id": "hp_pct"},
		{"name": "17% Бонуса исцеления", "id": "heal"},
		{"name": "16% Крит. Шанса", "id": "crit_rate"},
		{"name": "32% Крит. Урона", "id": "crit_dmg"}
	]
	var cur_body: String = String(relics.get("body", "crit_rate"))
	for b_i in body_stats.size():
		body_select.add_item(body_stats[b_i].name)
		body_select.set_item_metadata(b_i, body_stats[b_i].id)
		if body_stats[b_i].id == cur_body:
			body_select.select(b_i)
	grid.add_child(body_select)
	
	var feet_lbl := Label.new()
	feet_lbl.text = "Ноги (Характеристика):"
	feet_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(feet_lbl)
	
	var feet_select := OptionButton.new()
	feet_select.custom_minimum_size = Vector2(320, 48)
	feet_select.add_theme_font_size_override("font_size", 16)
	var feet_stats := [
		{"name": "21% Силы Атаки", "id": "atk_pct"},
		{"name": "21% ХП", "id": "hp_pct"},
		{"name": "26% Защиты", "id": "def_pct"},
		{"name": "12 ед. Скорости", "id": "speed"}
	]
	var cur_feet: String = String(relics.get("feet", "speed"))
	for f_i in feet_stats.size():
		feet_select.add_item(feet_stats[f_i].name)
		feet_select.set_item_metadata(f_i, feet_stats[f_i].id)
		if feet_stats[f_i].id == cur_feet:
			feet_select.select(f_i)
	grid.add_child(feet_select)
	
	var sep3 := HSeparator.new()
	grid.add_child(sep3)
	var sep4 := HSeparator.new()
	grid.add_child(sep4)
	
	# 4. Планарный сет
	var plan_lbl := Label.new()
	plan_lbl.text = "Планарные реликвии (сет):"
	plan_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(plan_lbl)
	
	var planar_sets := [
		{"name": "Сияющий Детройт", "id": "detroit"},
		{"name": "Лаборатория сгинувшего края", "id": "lost_edge"},
		{"name": "Свободный остров Япония", "id": "japan_island"},
		{"name": "Краснодар - сердце апокалипсиса", "id": "krasnodar"},
		{"name": "Другая сторона вселенной", "id": "other_side_universe"},
		{"name": "Погрязший в руинах Иркутск", "id": "irkutsk"},
		{"name": "Сервер в глубинах реальности", "id": "server_depths"},
		{"name": "Потайные глубины Изнанки", "id": "inverted_depths"},
		{"name": "Восставший Краснодар", "id": "risen_krasnodar"},
		{"name": "Замурованный под руинами штаб", "id": "ruins_hq"},
	]
	
	var plan_select := OptionButton.new()
	plan_select.custom_minimum_size = Vector2(320, 48)
	plan_select.add_theme_font_size_override("font_size", 16)
	plan_select.add_item("Без комплекта", 0)
	plan_select.set_item_metadata(0, "")
	for p_idx in planar_sets.size():
		plan_select.add_item("%s (2 части)" % planar_sets[p_idx].name)
		plan_select.set_item_metadata(p_idx + 1, planar_sets[p_idx].id)
		
	var cur_plan: String = String(relics.get("planar_set", ""))
	var cur_plan_idx: int = 0
	for i in plan_select.item_count:
		if plan_select.get_item_metadata(i) == cur_plan:
			cur_plan_idx = i
			break
	plan_select.select(cur_plan_idx)
	grid.add_child(plan_select)
	
	_apply_relic_tooltips(plan_select, false)
	
	# 5. Сферы со стихийным выбором
	var sph_lbl := Label.new()
	sph_lbl.text = "Сфера (Характеристика):"
	sph_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(sph_lbl)
	
	var sph_select := OptionButton.new()
	sph_select.custom_minimum_size = Vector2(320, 48)
	sph_select.add_theme_font_size_override("font_size", 16)
	var sph_stats := [
		{"name": "19% Бонус Физ. урона", "id": "phys_dmg"},
		{"name": "19% Бонус Ледяного урона", "id": "ice_dmg"},
		{"name": "19% Бонус Огненного урона", "id": "fire_dmg"},
		{"name": "19% Бонус Ветряного урона", "id": "wind_dmg"},
		{"name": "19% Бонус Электро урона", "id": "lightning_dmg"},
		{"name": "19% Бонус Квантового урона", "id": "quantum_dmg"},
		{"name": "19% Бонус Мнимого урона", "id": "imaginary_dmg"},
		{"name": "21% Силы Атаки", "id": "atk_pct"},
		{"name": "26% Защиты", "id": "def_pct"},
		{"name": "21% ХП", "id": "hp_pct"}
	]
	var cur_sph: String = String(relics.get("sphere", "ice_dmg"))
	for s_i in sph_stats.size():
		sph_select.add_item(sph_stats[s_i].name)
		sph_select.set_item_metadata(s_i, sph_stats[s_i].id)
		if sph_stats[s_i].id == cur_sph:
			sph_select.select(s_i)
	grid.add_child(sph_select)
	
	# 6. Веревка
	var rope_lbl := Label.new()
	rope_lbl.text = "Верёвка (Характеристика):"
	rope_lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(rope_lbl)
	
	var rope_select := OptionButton.new()
	rope_select.custom_minimum_size = Vector2(320, 48)
	rope_select.add_theme_font_size_override("font_size", 16)
	var rope_stats := [
		{"name": "21% Силы Атаки", "id": "atk_pct"},
		{"name": "21% ХП", "id": "hp_pct"},
		{"name": "26% Защиты", "id": "def_pct"},
		{"name": "32% Эффекта Пробития", "id": "break_effect"},
		{"name": "10% Восст. Энергии (ВЭ)", "id": "err"}
	]
	var cur_rope: String = String(relics.get("rope", "break_effect"))
	for r_i in rope_stats.size():
		rope_select.add_item(rope_stats[r_i].name)
		rope_select.set_item_metadata(r_i, rope_stats[r_i].id)
		if rope_stats[r_i].id == cur_rope:
			rope_select.select(r_i)
	grid.add_child(rope_select)
	
	# Контейнер для кнопок сохранения/загрузки шаблонов снаряжения
	var preset_hbox := HBoxContainer.new()
	preset_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preset_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(preset_hbox)
	
	# НОВАЯ МЕХАНИКА: Сохранение и загрузка шаблонов в/из user://presets/
	var btn_save := Button.new()
	btn_save.text = "💾 Сохранить"
	btn_save.custom_minimum_size = Vector2(200, 52)
	btn_save.add_theme_font_size_override("font_size", 16)
	btn_save.pressed.connect(_show_save_preset_dialog.bind(data, eid_select, lc_select, type_select, set1_select, set2_select, body_select, feet_select, plan_select, sph_select, rope_select))
	preset_hbox.add_child(btn_save)
	
	var btn_load := Button.new()
	btn_load.text = "📂 Загрузить"
	btn_load.custom_minimum_size = Vector2(200, 52)
	btn_load.add_theme_font_size_override("font_size", 16)
	btn_load.pressed.connect(_show_load_preset_dialog.bind(data, eid_select, lc_select, type_select, set1_select, set2_select, body_select, feet_select, plan_select, sph_select, rope_select, update_visibility, lc_btn))
	preset_hbox.add_child(btn_load)
	
	var close_btn := Button.new()
	close_btn.text = "Сохранить и закрыть"
	close_btn.custom_minimum_size = Vector2(0, 64)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_save_relic_settings.bind(index, eid_select, lc_select, type_select, set1_select, set2_select, body_select, feet_select, plan_select, sph_select, rope_select))
	vbox.add_child(close_btn)
	
func _save_relic_settings(index: int, eid_s: SpinBox, lc_s: OptionButton, type_s: OptionButton, s1_s: OptionButton, s2_s: OptionButton, body_s: OptionButton, feet_s: OptionButton, plan_s: OptionButton, sph_s: OptionButton, rope_s: OptionButton) -> void:
	if _team[index] == null:
		return
		
	var selected_lc := String(lc_s.get_item_metadata(lc_s.selected))
	var cavern_type: int = type_s.selected
	var s1 := ""
	var s2 := ""
	
	if cavern_type == 1: 
		s1 = String(s1_s.get_item_metadata(s1_s.selected))
	elif cavern_type == 2: 
		s1 = String(s1_s.get_item_metadata(s1_s.selected))
		s2 = String(s2_s.get_item_metadata(s2_s.selected))
		
	var selected_plan := String(plan_s.get_item_metadata(plan_s.selected))
	
	_team[index]["eidolon"] = int(eid_s.value) # Сохраняем эйдолон
	_team[index]["light_cone"] = selected_lc
	_team[index]["relics"] = {
		"cavern_set_1": s1,
		"cavern_set_2": s2,
		"body": body_s.get_item_metadata(body_s.selected),
		"feet": feet_s.get_item_metadata(feet_s.selected),
		"planar_set": selected_plan,
		"sphere": sph_s.get_item_metadata(sph_s.selected),
		"rope": rope_s.get_item_metadata(rope_s.selected)
	}

	var cur_build := TeamConfig.get_saved_build(_team[index].id)
	cur_build["eidolon"] = _team[index]["eidolon"]
	cur_build["light_cone"] = selected_lc
	cur_build["relics"] = _team[index]["relics"]
	TeamConfig.set_saved_build(_team[index].id, cur_build)
	TeamConfig.save_game()
	
	_refresh_team_slots()
	_refresh_initiator_options()
	
	if gear_overlay != null:
		gear_overlay.queue_free()
		gear_overlay = null

func _sanitize_team_light_cones() -> void:
	var equipped_counts: Dictionary = {}
	for i in TEAM_SIZE:
		var slot = _team[i]
		if slot != null and slot is Dictionary:
			var lc_id: String = String(slot.get("light_cone", ""))
			if not lc_id.is_empty():
				var cone = LightConeRegistry.get_cone(lc_id)
				if int(cone.get("rarity", 3)) > 3:
					var total := TeamConfig.get_light_cone_total_count(lc_id)
					var cur_count: int = int(equipped_counts.get(lc_id, 0))
					if cur_count >= total:
						slot["light_cone"] = ""
					else:
						equipped_counts[lc_id] = cur_count + 1

func _update_team_setup_lc_btn(btn: Button, lc_id: String) -> void:
	if not btn or not is_instance_valid(btn):
		return
	if lc_id.is_empty():
		btn.text = "🗡 [Без оружия]  [Выбрать конус ▾]"
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		var cone := LightConeRegistry.get_cone(lc_id)
		var c_name: String = cone.get("name", lc_id)
		var c_rarity: int = int(cone.get("rarity", 3))
		var col: Color = Color(1.0, 0.85, 0.3) if c_rarity == 5 else (Color(0.8, 0.5, 1.0) if c_rarity == 4 else Color(0.4, 0.7, 1.0))
		btn.text = "🗡 %s (%d★)  [Сменить ▾]" % [c_name, c_rarity]
		btn.add_theme_color_override("font_color", col)

func _select_option_by_meta_ts(opt: OptionButton, meta_val: String) -> void:
	for i in opt.item_count:
		if String(opt.get_item_metadata(i)) == meta_val:
			opt.select(i)
			return
	opt.select(0)

func _open_team_setup_light_cone_dialog(slot_index: int, lc_btn: Button, lc_select: OptionButton) -> void:
	var slot_data = _team[slot_index]
	if slot_data == null:
		return
	var char_id: String = slot_data.id
	var data := CharacterRegistry.get_character(char_id)
	if data.is_empty():
		return

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 620)
	center.add_child(panel)

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.09, 0.11, 0.16, 0.98)
	panel_sb.border_color = Color(0.35, 0.45, 0.65, 0.9)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(14)
	panel_sb.content_margin_left = 22
	panel_sb.content_margin_right = 22
	panel_sb.content_margin_top = 18
	panel_sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", panel_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "🗡 Выбор Светового Конуса: %s (%s)" % [data.name, _get_path_name(data.path)]
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): overlay.queue_free())
	header_hbox.add_child(close_btn)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "3★ конусы неограничены. 4★ и 5★ требуют свободных копий или переноса с другого персонажа."
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	vbox.add_child(subtitle_lbl)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(716, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(list_vbox)

	var current_lc_id: String = String(slot_data.get("light_cone", ""))

	# 1. Карточка "Без оружия"
	var unequip_card := PanelContainer.new()
	var unequip_sb := StyleBoxFlat.new()
	unequip_sb.bg_color = Color(0.12, 0.14, 0.20, 0.9)
	unequip_sb.border_color = Color(0.25, 0.3, 0.4, 0.6)
	unequip_sb.set_border_width_all(1)
	unequip_sb.set_corner_radius_all(8)
	unequip_sb.content_margin_left = 14
	unequip_sb.content_margin_right = 14
	unequip_sb.content_margin_top = 10
	unequip_sb.content_margin_bottom = 10
	unequip_card.add_theme_stylebox_override("panel", unequip_sb)
	list_vbox.add_child(unequip_card)

	var unequip_hbox := HBoxContainer.new()
	unequip_hbox.add_theme_constant_override("separation", 14)
	unequip_card.add_child(unequip_hbox)

	var unequip_info := VBoxContainer.new()
	unequip_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unequip_hbox.add_child(unequip_info)

	var unequip_title := Label.new()
	unequip_title.text = "🚫 Без оружия"
	unequip_title.add_theme_font_size_override("font_size", 16)
	unequip_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	unequip_info.add_child(unequip_title)

	var unequip_desc := Label.new()
	unequip_desc.text = "Снять световой конус с персонажа."
	unequip_desc.add_theme_font_size_override("font_size", 12)
	unequip_desc.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	unequip_info.add_child(unequip_desc)

	var unequip_btn := Button.new()
	unequip_btn.custom_minimum_size = Vector2(130, 38)
	if current_lc_id.is_empty():
		unequip_btn.text = "✓ Выбрано"
		unequip_btn.disabled = true
	else:
		unequip_btn.text = "Снять"
		unequip_btn.pressed.connect(func():
			TeamConfig.unequip_light_cone_from_character(char_id, _team)
			_team[slot_index]["light_cone"] = ""
			_select_option_by_meta_ts(lc_select, "")
			_update_team_setup_lc_btn(lc_btn, "")
			_refresh_team_slots()
			overlay.queue_free()
		)
	unequip_hbox.add_child(unequip_btn)

	# 2. Карточки световых конусов
	for lc in LightConeRegistry.LIST:
		if lc.path != data.path:
			continue
		var is_3star: bool = (int(lc.get("rarity", 3)) == 3)
		var total_copies: int = TeamConfig.get_light_cone_total_count(lc.id)
		if not is_3star and total_copies <= 0:
			continue

		var equipped_chars: Array[String] = TeamConfig.get_light_cone_equipped_characters(lc.id, _team)
		var is_current: bool = (current_lc_id == lc.id)
		var busy_count: int = equipped_chars.size()
		var free_copies: int = maxi(0, total_copies - busy_count) if not is_3star else 999

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 14
		card_sb.content_margin_right = 14
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10

		if is_current:
			card_sb.bg_color = Color(0.12, 0.18, 0.16, 0.95)
			card_sb.border_color = Color(0.3, 0.8, 0.45, 0.9)
		else:
			card_sb.bg_color = Color(0.10, 0.12, 0.18, 0.92)
			card_sb.border_color = Color(0.28, 0.35, 0.50, 0.6)
		card.add_theme_stylebox_override("panel", card_sb)
		list_vbox.add_child(card)

		var card_hbox := HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 14)
		card.add_child(card_hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		card_hbox.add_child(info_vbox)

		# Имя и Редкость
		var top_hbox := HBoxContainer.new()
		top_hbox.add_theme_constant_override("separation", 8)
		info_vbox.add_child(top_hbox)

		var stars_lbl := Label.new()
		var rarity_val: int = int(lc.get("rarity", 3))
		var stars_str := ""
		for s in range(rarity_val):
			stars_str += "★"
		stars_lbl.text = stars_str
		stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if rarity_val == 5 else (Color(0.8, 0.5, 1.0) if rarity_val == 4 else Color(0.4, 0.7, 1.0)))
		stars_lbl.add_theme_font_size_override("font_size", 14)
		top_hbox.add_child(stars_lbl)

		var name_lbl := Label.new()
		name_lbl.text = lc.name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		top_hbox.add_child(name_lbl)

		# Описание эффекта
		var desc_lbl := Label.new()
		desc_lbl.text = lc.desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.94))
		info_vbox.add_child(desc_lbl)

		# Строка статуса занятости
		var status_lbl := Label.new()
		status_lbl.add_theme_font_size_override("font_size", 12)

		var wearers_names: Array[String] = []
		for ec_id in equipped_chars:
			var ec_data := CharacterRegistry.get_character(ec_id)
			var in_team_note := ""
			for slot in _team:
				if slot != null and slot.get("id", "") == ec_id:
					in_team_note = " (в отряде)"
					break
			wearers_names.append(ec_data.get("name", ec_id) + in_team_note)
		var wearers_str: String = ", ".join(wearers_names)

		if is_3star:
			status_lbl.text = "♾️ Неограниченно • Доступен для всех персонажей"
			status_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif is_current:
			var extra := (" • Также занят: " + wearers_str) if busy_count > 1 else ""
			status_lbl.text = "✅ Экипирован на %s (Всего копий: %d)%s" % [data.name, total_copies, extra]
			status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		elif free_copies > 0:
			var extra := (" • Занят: " + wearers_str) if busy_count > 0 else ""
			status_lbl.text = "🟢 Свободно: %d из %d%s" % [free_copies, total_copies, extra]
			status_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
		else:
			status_lbl.text = "🔴 Все копии заняты (%d/%d) • Экипирован у: %s" % [busy_count, total_copies, wearers_str]
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		info_vbox.add_child(status_lbl)

		# Кнопка действия
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(130, 38)
		if is_current:
			action_btn.text = "✓ Надет"
			action_btn.disabled = true
		elif free_copies > 0:
			action_btn.text = "Надеть"
			action_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
			var chosen_lc_id: String = lc.id
			action_btn.pressed.connect(func():
				TeamConfig.equip_light_cone_to_character(char_id, chosen_lc_id, "", _team)
				_team[slot_index]["light_cone"] = chosen_lc_id
				_select_option_by_meta_ts(lc_select, chosen_lc_id)
				_update_team_setup_lc_btn(lc_btn, chosen_lc_id)
				_refresh_team_slots()
				overlay.queue_free()
			)
		else:
			action_btn.text = "🔄 Перенести"
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
			var chosen_lc_id: String = lc.id
			var eq_copy: Array[String] = equipped_chars.duplicate()
			action_btn.pressed.connect(func():
				_show_team_setup_lc_transfer_confirm(char_id, chosen_lc_id, eq_copy, func():
					_team[slot_index]["light_cone"] = chosen_lc_id
					_select_option_by_meta_ts(lc_select, chosen_lc_id)
					_update_team_setup_lc_btn(lc_btn, chosen_lc_id)
					_refresh_team_slots()
					overlay.queue_free()
				)
			)
		card_hbox.add_child(action_btn)

func _show_team_setup_lc_transfer_confirm(to_char_id: String, lc_id: String, from_chars: Array[String], on_confirmed: Callable) -> void:
	if from_chars.is_empty():
		return

	var cone := LightConeRegistry.get_cone(lc_id)
	var to_data := CharacterRegistry.get_character(to_char_id)
	var cone_name: String = cone.get("name", lc_id)
	var to_name: String = to_data.get("name", to_char_id)

	var conf_overlay := ColorRect.new()
	conf_overlay.color = Color(0, 0, 0, 0.85)
	conf_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	conf_overlay.z_index = 60
	add_child(conf_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	conf_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 260)
	center.add_child(panel)

	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.11, 0.13, 0.20, 0.98)
	p_sb.border_color = Color(0.8, 0.5, 0.2, 0.9)
	p_sb.set_border_width_all(2)
	p_sb.set_corner_radius_all(12)
	p_sb.content_margin_left = 20
	p_sb.content_margin_right = 20
	p_sb.content_margin_top = 18
	p_sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", p_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🔄 Перенос Светового Конуса"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)

	var btns_vbox := VBoxContainer.new()
	btns_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(btns_vbox)

	if from_chars.size() == 1:
		var from_char_id: String = from_chars[0]
		var from_data := CharacterRegistry.get_character(from_char_id)
		var from_name: String = from_data.get("name", from_char_id)
		desc.text = "Все копии конуса «%s» заняты персонажем %s.\n\nСнять конус с %s и экипировать на %s?" % [
			cone_name, from_name, from_name, to_name
		]

		var btn_hbox := HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_hbox.add_theme_constant_override("separation", 20)
		btns_vbox.add_child(btn_hbox)

		var ok_btn := Button.new()
		ok_btn.text = "Да, перенести"
		ok_btn.custom_minimum_size = Vector2(150, 42)
		ok_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		ok_btn.pressed.connect(func():
			TeamConfig.equip_light_cone_to_character(to_char_id, lc_id, from_char_id, _team)
			conf_overlay.queue_free()
			if on_confirmed.is_valid():
				on_confirmed.call()
		)
		btn_hbox.add_child(ok_btn)

		var cancel_btn := Button.new()
		cancel_btn.text = "Отмена"
		cancel_btn.custom_minimum_size = Vector2(120, 42)
		cancel_btn.pressed.connect(func(): conf_overlay.queue_free())
		btn_hbox.add_child(cancel_btn)
	else:
		desc.text = "Все копии конуса «%s» заняты.\nВыберите, у кого снять конус для %s:" % [cone_name, to_name]
		for from_char_id in from_chars:
			var from_data := CharacterRegistry.get_character(from_char_id)
			var from_name: String = from_data.get("name", from_char_id)
			var transfer_btn := Button.new()
			transfer_btn.text = "Снять с %s" % from_name
			transfer_btn.custom_minimum_size = Vector2(0, 38)
			var target_from := from_char_id
			transfer_btn.pressed.connect(func():
				TeamConfig.equip_light_cone_to_character(to_char_id, lc_id, target_from, _team)
				conf_overlay.queue_free()
				if on_confirmed.is_valid():
					on_confirmed.call()
			)
			btns_vbox.add_child(transfer_btn)

		var cancel_btn := Button.new()
		cancel_btn.text = "Отмена"
		cancel_btn.custom_minimum_size = Vector2(0, 38)
		cancel_btn.pressed.connect(func(): conf_overlay.queue_free())
		btns_vbox.add_child(cancel_btn)

# Наложение тултипов (описания сетов) на выпадающие списки комплектов реликвий
func _apply_relic_tooltips(opt_btn: OptionButton, is_cavern: bool) -> void:
	var popup: PopupMenu = opt_btn.get_popup()
	for i in opt_btn.item_count:
		var id = opt_btn.get_item_metadata(i)
		var desc := "Описание отсутствует."
		
		if is_cavern:
			match id:
				"symbiosis": desc = "2 части: наносимый ледяной урон увеличен на 10%.\n4 части: после того как владелец пробивает уязвимость противника, он понижает его защиту на 15% до восстановления уязвимости."
				"chaos": desc = "2 части: увеличивает квантовый урон на 10%.\n4 части: Когда ХП владельца опускается ниже 50%, его урон увеличивается на 20%."
				"mortal_world": desc = "2 части: увеличивает физический урон на 10%.\n4 части: Если уязвимость врага не пробита, владелец при атаке дополнительно снимает 5 ед. уязвимости противника."
				"lava_fighter": desc = "2 части: увеличивает огненный урон на 10%.\n4 части: Урон, наносимый владельцем вне своего хода, увеличивается на 20%."
				"light_gift": desc = "2 части: увеличивает электрический урон на 10%.\n4 части: При активации Сверхспособности, владелец восстанавливает 25% от макс. хп."
				"hope_beam": desc = "2 части: увеличивает мнимый урон на 10%.\n4 части: Повышает урон, наносимый навыком владельца, на 12%, а также повышает урон следующей атаки владельца после использования сверхспособности на 12%."
				"rapid_response": desc = "2 части: увеличивает ветряной урон на 10%.\n4 части: После использования сверхспособности действие владельца продвигается вперёд на 25%."
				"biology_doctor": desc = "2 части: увеличивает исходящее исцеление на 10%.\n4 части: В начале боя восстанавливает 1 очко навыков."
				"dying_planet": desc = "2 части: повышает защиту на 15%.\n4 части: Повышает прочность щитов владельца на 20%."
				"lost_self": desc = "2 части: увеличивает силу атаки владельца на 15%.\n4 части: За каждый имеющийся у противника эффект с периодическим уроном (до макс. 3) при нанесении урона владелец игнорирует 6% от защиты этого противника"
				"galilean": desc = "2 части: повышает урон бонус-атаки на 20%.\n4 части: Когда владелец выполняет бонус-атаку, его сила атаки повышается на 6% каждый раз, когда эта бонус-атака наносит урон. Этот эффект может складываться до 8 раз и длится 3 хода. Эффект снимается при следующем выполнении бонус-атаки владельцем."
				"silhouette": desc = "2 части: увеличивает крит. урон на 16%.\n4 части: После того, как владелец получает атаку, его сила атаки повышается на 5% (суммируется до 5 раз). Если владелец Казнит противника, он получает 20 единиц скорости на 2 хода."
				"accepted_sin": desc = "2 части: увеличивает макс. хп владельца на 12%. 4 части: При потере ХП владелец повышает свой крит. шанс на 5% на 1 ход. Эффект может складываться до 6 раз."
				"bereft_future": desc = "2 части: увеличивает скорость владельца на 6%. 4 части: Когда владелец применяет Сверхспособность к союзнику (кроме себя)/союзникам, скорость всех союзников повышается на 12% на 1 ход."
				"damaged_strings": desc = "2 части: Увеличивает Бинарный урон на 15%.\n4 части: После использования Сверхспособности Бинарный урон владельца игнорирует 20% защиты противника на 3 хода."
				"dying_stars_child": desc = "2 части: Увеличивает крит. шанс владельца на 8%.\n4 части: Навыки Q и E владельца восстанавливают 5 единиц Зеро (если активна синергия Антиматерия 1). Если текущее Зеро > 40, увеличивает наносимый владельцем урон на 15%."
				"dark_side_defector": desc = "2 части: +16% Эффекта пробития.\n4 части: Если Эффект пробития владельца >= 130%, урон пробития игнорирует 10% Защиты цели. Если Эффект пробития >= 180%, урон Суперпробития дополнительно игнорирует 15% Защиты цели."
				"bloom_defender": desc = "2 части: +12% Силы Атаки. Пока Дух Памяти владельца на поле боя, Скорость владельца повышается на 6%.\n4 части: Когда Дух Памяти владельца атакует, Крит. урон владельца и Духа Памяти увеличивается на 30% на 2 хода."
		else:
			match id:
				"detroit": desc = "2 части: Повышает силу атаки владельца на 12%. Если скорость владельца выше или равна 120 ед., то его сила атаки повышается на доп. 12%."
				"lost_edge": desc = "2 части: Повышает макс. HP владельца на 12%. Если скорость владельца выше или равна 120 ед., то сила атаки всех союзников повышается на доп. 8%."
				"japan_island": desc = "2 части: Повышает защиту владельца на 15%. Если шанс попадания эффектов владельца выше или равен 50%, то его защита повышается на доп. 15%."
				"krasnodar": desc = "2 части: Повышает крит. шанс владельца на 8%. Если крит. шанс владельца выше или равен 50%, то урон его сверхспособности и бонус-атаки повышается на 15%."
				"other_side_universe": desc = "2 части: Повышает крит. шанс владельца на 12%. Если крит. шанс владельца не меньше 70%, то наносимый его базовой атакой и навыками Q и E урон повышается на 20%."
				"irkutsk": desc = "2 части: Когда союзник выполняет бонус-атаку, владелец получает 1 ур. Статуса Подвиг, до макс. 5 ур. Каждый уровень этого статуса повышает наносимый бонус-атакой владельца урон на 5%. Когда статус Подвиг достигает 5 ур., крит. урон владельца дополнительно повышается на 25%"
				"server_depths": desc = "2 части: Увеличивает скорость на 6%. При использовании Навыка E скорость повышается на 12% на 2 хода. Если этот Навык E наносит Бинарный урон, поражённые противники получают на 10% больше Бинарного урона на 2 хода. Этот эффект складывается только от разных источников."
				"inverted_depths": desc = "2 части: Увеличивает силу атаки на 12%. Если владелец находится не в 1-м слоте (не 0-й индекс), и хотя бы одна фракция первого персонажа совпадает с фракцией владельца, наносимый урон обоих персонажей повышается на 10%."
				"risen_krasnodar": desc = "2 части: +16% Крит. Урона. Если у владельца на поле боя есть призванные существа или Дух Памяти, Крит. урон владельца повышается ещё на 32%."
				"ruins_hq": desc = "2 части: +16% Эффекта пробития. Если Скорость владельца >= 145, Эффект пробития повышается дополнительно на 20%."
		
		popup.set_item_tooltip(i, desc)

func _on_start_pressed() -> void:
	var team: Array[Dictionary] = []
	for i in TEAM_SIZE:
		var slot = _team[i]
		if slot != null:
			var duplicated: Dictionary = slot.duplicate()
			duplicated["slot_idx"] = i # Сохраняем исходный слот отряда
			team.append(duplicated)

	if team.is_empty():
		return

	var mode: String = mode_option.get_item_metadata(mode_option.selected)
	var enemies_selected: Array[Dictionary] = []

	if mode == "custom":
		for i in ENEMY_TEAM_SIZE:
			var slot = _enemy_team[i]
			if slot != null:
				var duplicated: Dictionary = slot.duplicate()
				duplicated["slot_idx"] = i # Сохраняем исходный слот врагов
				enemies_selected.append(duplicated)
		if enemies_selected.is_empty():
			return
	elif mode == "boss":
		enemies_selected.append({"id": "void_boss", "slot_idx": 2})
	elif mode == "fiction":
		for i in 5:
			enemies_selected.append({"id": VoidSoldier.ID, "slot_idx": i})
	elif mode == "test_env":
		var submode: String = "boss"
		if test_submode_option != null:
			submode = test_submode_option.get_item_metadata(test_submode_option.selected)
		var b_hp: float = float(test_boss_hp_spin.value) if test_boss_hp_spin != null else 1500000.0
		var trio_b_hp: float = float(test_trio_boss_hp_spin.value) if test_trio_boss_hp_spin != null else 1200000.0
		var trio_e_hp: float = float(test_trio_elite_hp_spin.value) if test_trio_elite_hp_spin != null else 500000.0
		var fic_hp: float = float(test_fiction_hp_spin.value) if test_fiction_hp_spin != null else 70000.0
		var fic_count: int = int(test_fiction_count_spin.value) if test_fiction_count_spin != null else 30

		match submode:
			"boss":
				enemies_selected.append({"id": "test_boss", "slot_idx": 2, "hp": b_hp, "def": 1200.0})
			"trio":
				enemies_selected.append({"id": "test_elite", "slot_idx": 1, "hp": trio_e_hp, "def": 800.0})
				enemies_selected.append({"id": "test_boss", "slot_idx": 2, "hp": trio_b_hp, "def": 1200.0})
				enemies_selected.append({"id": "test_elite", "slot_idx": 3, "hp": trio_e_hp, "def": 800.0})
			"fiction":
				for i in 5:
					enemies_selected.append({"id": "test_soldier", "slot_idx": i, "hp": fic_hp, "def": 400.0})

	TeamConfig.reset()
	TeamConfig.is_admin_battle = true
	TeamConfig.team_members = team
	TeamConfig.enemy_members = enemies_selected
	TeamConfig.battle_mode = mode
	if mode == "test_env":
		TeamConfig.is_test_mode_battle = true
		if test_submode_option != null:
			TeamConfig.test_submode = test_submode_option.get_item_metadata(test_submode_option.selected)
		if test_boss_hp_spin != null:
			TeamConfig.test_boss_hp = float(test_boss_hp_spin.value)
		if test_trio_boss_hp_spin != null:
			TeamConfig.test_trio_boss_hp = float(test_trio_boss_hp_spin.value)
		if test_trio_elite_hp_spin != null:
			TeamConfig.test_trio_elite_hp = float(test_trio_elite_hp_spin.value)
		if test_fiction_count_spin != null:
			TeamConfig.test_fiction_count = int(test_fiction_count_spin.value)
		if test_fiction_hp_spin != null:
			TeamConfig.test_fiction_hp = float(test_fiction_hp_spin.value)
	
	var init_idx: int = initiator_option.selected
	if init_idx >= 0 and init_idx < initiator_option.item_count:
		TeamConfig.battle_initiator_id = initiator_option.get_item_metadata(init_idx)
	else:
		TeamConfig.battle_initiator_id = team[0].id

	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _get_path_name(path: CombatConstants.Path) -> String:
	match path:
		CombatConstants.Path.ERUDITION: return "Эрудиция"
		CombatConstants.Path.HUNT: return "Охота"
		CombatConstants.Path.DESTRUCTION: return "Разрушение"
		CombatConstants.Path.HARMONY: return "Гармония"
		CombatConstants.Path.ABUNDANCE: return "Изобилие"
		CombatConstants.Path.PRESERVATION: return "Сохранение"
		CombatConstants.Path.NIHILITY: return "Небытие"
		CombatConstants.Path.REMEMBRANCE: return "Память"
		_: return "?"

# --- ВСПОМОГАТЕЛЬНЫЕ ДИАЛОГОВЫЕ ОКНА ДЛЯ ПРЕСЕТОВ ---

# Диалог сохранения шаблона
func _show_save_preset_dialog(char_data: Dictionary, eid_s: SpinBox, lc_s: OptionButton, type_s: OptionButton, s1_s: OptionButton, s2_s: OptionButton, body_s: OptionButton, feet_s: OptionButton, plan_s: OptionButton, sph_s: OptionButton, rope_s: OptionButton) -> void:
	var save_overlay := ColorRect.new()
	save_overlay.color = Color(0, 0, 0, 0.75)
	save_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(save_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 200)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var label := Label.new()
	label.text = "Введите имя шаблона снаряжения:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var input := LineEdit.new()
	input.placeholder_text = "Например: Быстрая Марина"
	input.custom_minimum_size = Vector2(250, 0)
	vbox.add_child(input)
	
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var ok_btn := Button.new()
	ok_btn.text = "Сохранить"
	ok_btn.pressed.connect(func():
		var file_name: String = input.text.strip_edges()
		if file_name.is_empty():
			return
		
		# Формируем структуру пресета
		var cavern_type: int = type_s.selected
		var s1 := ""
		var s2 := ""
		if cavern_type == 1:
			s1 = String(s1_s.get_item_metadata(s1_s.selected))
		elif cavern_type == 2:
			s1 = String(s1_s.get_item_metadata(s1_s.selected))
			s2 = String(s2_s.get_item_metadata(s2_s.selected))
			
		var preset_data: Dictionary = {
			"path": char_data.path, # Храним Путь (класс) для проверки совместимости
			"eidolon": int(eid_s.value),
			"light_cone": String(lc_s.get_item_metadata(lc_s.selected)),
			"cavern_type": cavern_type,
			"cavern_set_1": s1,
			"cavern_set_2": s2,
			"body": body_s.get_item_metadata(body_s.selected),
			"feet": feet_s.get_item_metadata(feet_s.selected),
			"planar_set": String(plan_s.get_item_metadata(plan_s.selected)),
			"sphere": sph_s.get_item_metadata(sph_s.selected),
			"rope": rope_s.get_item_metadata(rope_s.selected)
		}
		
		var file := FileAccess.open("user://presets/" + file_name + ".json", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(preset_data))
			file.close()
			
		save_overlay.queue_free()
	)
	btn_hbox.add_child(ok_btn)
	
	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.pressed.connect(func():
		save_overlay.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

# Диалог загрузки шаблона
func _show_load_preset_dialog(char_data: Dictionary, eid_s: SpinBox, lc_s: OptionButton, type_s: OptionButton, s1_s: OptionButton, s2_s: OptionButton, body_s: OptionButton, feet_s: OptionButton, plan_s: OptionButton, sph_s: OptionButton, rope_s: OptionButton, update_vis_callable: Callable, lc_btn: Button = null) -> void:
	var load_overlay := ColorRect.new()
	load_overlay.color = Color(0, 0, 0, 0.75)
	load_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(load_overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var label := Label.new()
	label.text = "Выберите шаблон снаряжения:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 200)
	vbox.add_child(scroll)
	
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	
	var dir := DirAccess.open("user://presets/")
	var files_found: bool = false
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				files_found = true
				var clean_name: String = file_name.get_basename()
				
				var file_btn := Button.new()
				file_btn.text = "📄 " + clean_name
				file_btn.pressed.connect(func():
					var file := FileAccess.open("user://presets/" + file_name, FileAccess.READ)
					if file != null:
						var json_text: String = file.get_as_text()
						file.close()
						
						var preset_data: Dictionary = JSON.parse_string(json_text)
						if not preset_data.is_empty():
							# ПРОВЕРКА СОВМЕСТИМОСТИ ПУТЕЙ:
							var preset_path: int = int(preset_data.get("path", -1))
							if preset_path == char_data.path:
								# Пути совпадают: полностью загружаем конус (если есть свободные копии)
								var target_lc: String = String(preset_data.get("light_cone", ""))
								if not target_lc.is_empty() and not TeamConfig.can_equip_light_cone(char_data.id, target_lc, _team):
									target_lc = ""
								var lc_idx: int = 0
								for i in lc_s.item_count:
									if lc_s.get_item_metadata(i) == target_lc:
										lc_idx = i
										break
								lc_s.select(lc_idx)
								if lc_btn != null and is_instance_valid(lc_btn):
									_update_team_setup_lc_btn(lc_btn, target_lc)
							else:
								# Пути отличаются: конус не импортируется
								pass
								
							# Загружаем эйдолоны
							eid_s.value = int(preset_data.get("eidolon", 0))
							
							# Загружаем Схему комплектов
							var cavern_type: int = int(preset_data.get("cavern_type", 0))
							type_s.select(cavern_type)
							
							var target_s1: String = String(preset_data.get("cavern_set_1", ""))
							var target_s2: String = String(preset_data.get("cavern_set_2", ""))
							
							if cavern_type == 1:
								for i in s1_s.item_count:
									if s1_s.get_item_metadata(i) == target_s1:
										s1_s.select(i)
										break
							elif cavern_type == 2:
								for i in s1_s.item_count:
									if s1_s.get_item_metadata(i) == target_s1:
										s1_s.select(i)
										break
								for i in s2_s.item_count:
									if s2_s.get_item_metadata(i) == target_s2:
										s2_s.select(i)
										break
										
							# Обновляем видимость Пещерных сетов 1 и 2
							update_vis_callable.call()
							
							# Характеристики тела
							var target_body: String = String(preset_data.get("body", "crit_rate"))
							for i in body_s.item_count:
								if body_s.get_item_metadata(i) == target_body:
									body_s.select(i)
									break
									
							# Характеристики ног
							var target_feet: String = String(preset_data.get("feet", "speed"))
							for i in feet_s.item_count:
								if feet_s.get_item_metadata(i) == target_feet:
									feet_s.select(i)
									break
									
							# Планарный сет
							var target_plan: String = String(preset_data.get("planar_set", ""))
							var plan_idx: int = 0
							for i in plan_s.item_count:
								if plan_s.get_item_metadata(i) == target_plan:
									plan_idx = i
									break
							plan_s.select(plan_idx)
							
							# Сфера
							var target_sph: String = String(preset_data.get("sphere", "ice_dmg"))
							for i in sph_s.item_count:
								if sph_s.get_item_metadata(i) == target_sph:
									sph_s.select(i)
									break
									
							# Веревка
							var target_rope: String = String(preset_data.get("rope", "break_effect"))
							for i in rope_s.item_count:
								if rope_s.get_item_metadata(i) == target_rope:
									rope_s.select(i)
									break
									
							# Накладываем всплывающие тултипы описания на новые выбранные селекторы
							_apply_relic_tooltips(s1_s, true)
							_apply_relic_tooltips(s2_s, true)
							_apply_relic_tooltips(plan_s, false)
							
					load_overlay.queue_free()
				)
				list.add_child(file_btn)
			file_name = dir.get_next()
			
	if not files_found:
		var empty_lbl := Label.new()
		empty_lbl.text = "Нет сохраненных шаблонов."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty_lbl)
		
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(func():
		load_overlay.queue_free()
	)
	vbox.add_child(close_btn)

# --- ДИАЛОГИ СОХРАНЕНИЯ И ЗАГРУЗКИ ОТРЯДОВ ---

func _show_save_team_dialog() -> void:
	var has_members: bool = false
	for slot in _team:
		if slot != null:
			has_members = true
			break
	if not has_members:
		_show_temporary_message("❌ Отряд пуст! Добавьте хотя бы одного персонажа перед сохранением.")
		return

	var save_overlay := ColorRect.new()
	save_overlay.color = Color(0, 0, 0, 0.75)
	save_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(save_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 260)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "💾 Сохранить отряд в профиль"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Введите название отряда (или выберите существующий для перезаписи):"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(hint)

	var input := LineEdit.new()
	input.placeholder_text = "Например: Консоль Мета"
	input.text = "Отряд %d" % (TeamConfig.get_saved_teams().size() + 1)
	input.custom_minimum_size = Vector2(300, 36)
	vbox.add_child(input)

	var existing_teams: Dictionary = TeamConfig.get_saved_teams()
	if not existing_teams.is_empty():
		var quick_scroll := ScrollContainer.new()
		quick_scroll.custom_minimum_size = Vector2(420, 80)
		vbox.add_child(quick_scroll)

		var quick_vbox := VBoxContainer.new()
		quick_vbox.add_theme_constant_override("separation", 4)
		quick_scroll.add_child(quick_vbox)

		for t_name in existing_teams:
			var q_btn := Button.new()
			q_btn.text = "📝 " + t_name
			q_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			q_btn.pressed.connect(func(): input.text = t_name)
			quick_vbox.add_child(q_btn)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)

	var ok_btn := Button.new()
	ok_btn.text = "💾 Сохранить"
	ok_btn.custom_minimum_size = Vector2(130, 40)
	ok_btn.pressed.connect(func():
		var team_name: String = input.text.strip_edges()
		if team_name.is_empty():
			return

		var current_initiator: String = ""
		var init_idx: int = initiator_option.selected
		if init_idx >= 0 and init_idx < initiator_option.item_count:
			current_initiator = String(initiator_option.get_item_metadata(init_idx))

		TeamConfig.save_team_preset(team_name, _team, current_initiator, true)
		save_overlay.queue_free()
		_show_temporary_message("✅ Отряд «%s» успешно сохранён!" % team_name)
	)
	btn_hbox.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.pressed.connect(func():
		save_overlay.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

func _show_load_team_dialog() -> void:
	var load_overlay := ColorRect.new()
	load_overlay.color = Color(0, 0, 0, 0.75)
	load_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(load_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 380)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "📂 Загрузить отряд из сохранения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 250)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	_populate_load_team_list(list, load_overlay)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.pressed.connect(func():
		load_overlay.queue_free()
	)
	vbox.add_child(close_btn)

func _populate_load_team_list(list: VBoxContainer, load_overlay: ColorRect) -> void:
	for c in list.get_children():
		c.queue_free()

	var saved_teams: Dictionary = TeamConfig.get_saved_teams(true)
	if saved_teams.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Нет сохранённых отрядов.\nНажмите «Сохранить отряд», чтобы сохранить текущий состав."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		list.add_child(empty_lbl)
		return

	for t_name in saved_teams:
		var preset: Dictionary = saved_teams[t_name]
		var members: Array = preset.get("members", [])
		var initiator_id: String = preset.get("initiator", "")

		var item_panel := PanelContainer.new()
		var item_style := StyleBoxFlat.new()
		item_style.bg_color = Color(0.12, 0.14, 0.20, 0.9)
		item_style.set_corner_radius_all(6)
		item_style.set_content_margin_all(8)
		item_panel.add_theme_stylebox_override("panel", item_style)
		list.add_child(item_panel)

		var item_hbox := HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 10)
		item_panel.add_child(item_hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(info_vbox)

		var name_lbl := Label.new()
		name_lbl.text = "⚔ " + t_name
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		info_vbox.add_child(name_lbl)

		var members_text := ""
		for slot_i in TEAM_SIZE:
			if slot_i < members.size() and members[slot_i] != null:
				var m_data: Dictionary = members[slot_i]
				var c_reg: Dictionary = CharacterRegistry.get_character(String(m_data.get("id", "")))
				var c_name: String = String(c_reg.get("name", m_data.get("id", "?")))
				var c_elem: int = int(c_reg.get("element", 0))
				var c_sym: String = String(CombatConstants.ELEMENT_SYMBOLS.get(c_elem, ""))
				var lc_id: String = String(m_data.get("light_cone", ""))
				var lc_name: String = ""
				if lc_id != "":
					var lc_data: Dictionary = LightConeRegistry.get_cone(lc_id)
					lc_name = " [%s]" % String(lc_data.get("name", lc_id))
				var eid: int = int(m_data.get("eidolon", 0))
				members_text += "%d. %s %s [%s] E%d%s   " % [slot_i + 1, c_sym, c_name, CombatConstants.get_element_short_name(c_elem), eid, lc_name]
			else:
				members_text += "%d. [Пусто]   " % (slot_i + 1)

		var comp_lbl := Label.new()
		comp_lbl.text = members_text
		comp_lbl.add_theme_font_size_override("font_size", 11)
		comp_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		info_vbox.add_child(comp_lbl)

		var load_btn := Button.new()
		load_btn.text = "📥 Загрузить"
		load_btn.custom_minimum_size = Vector2(100, 36)
		var cur_name: String = String(t_name)
		var cur_members: Array = members
		var cur_init: String = initiator_id
		load_btn.pressed.connect(func():
			for i in TEAM_SIZE:
				if i < cur_members.size() and cur_members[i] != null:
					_team[i] = cur_members[i].duplicate(true)
				else:
					_team[i] = null
			_sanitize_team_light_cones()

			if cur_init != "":
				TeamConfig.battle_initiator_id = cur_init

			TeamConfig.team_members.clear()
			for i in TEAM_SIZE:
				if _team[i] != null:
					var duplicated: Dictionary = _team[i].duplicate(true)
					duplicated["slot_idx"] = i
					TeamConfig.team_members.append(duplicated)

			_refresh_team_slots()
			_refresh_initiator_options()

			if cur_init != "":
				for idx in initiator_option.item_count:
					if initiator_option.get_item_metadata(idx) == cur_init:
						initiator_option.select(idx)
						break

			load_overlay.queue_free()
			_show_temporary_message("✅ Отряд «%s» успешно загружен!" % cur_name)
		)
		item_hbox.add_child(load_btn)

		var del_btn := Button.new()
		del_btn.text = "🗑"
		del_btn.custom_minimum_size = Vector2(36, 36)
		del_btn.pressed.connect(func():
			TeamConfig.delete_team_preset(cur_name, true)
			_populate_load_team_list(list, load_overlay)
		)
		item_hbox.add_child(del_btn)

func _show_temporary_message(msg: String) -> void:
	var msg_label := Label.new()
	msg_label.text = msg
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.92)
	style.border_color = Color(0.3, 0.8, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(msg_label)

	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 10
	panel.offset_left = 200
	panel.offset_right = -200
	add_child(panel)

	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
