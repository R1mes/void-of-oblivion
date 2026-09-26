extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  ЗАПУСК ТЕСТОВ ИНТЕГРАЦИИ СПЛЕШ-АРТОВ ПЕРСОНАЖЕЙ")
	print("========================================================\n")

	var splash_char_ids := ["sara", "sara_admin", "isaac", "isaac_admin", "rimes"]

	# Тест 1: Проверка реестра и загрузки текстур
	for c_id in splash_char_ids:
		assert(CharacterRegistry.has_character_splash(c_id), "Character %s must have splash registered" % c_id)
		var tex := CharacterRegistry.get_character_splash(c_id)
		assert(tex != null, "Texture for %s must be loaded successfully" % c_id)
		assert(tex.get_width() > 0 and tex.get_height() > 0, "Texture dimensions must be valid for %s" % c_id)
	print("  [PASS] test_1_splash_registry_and_textures_valid")

	# Тест 2: Карточки боя (Battle) — фоновый узел CharacterSplashBG с затемнением
	TeamConfig.reset()
	TeamConfig.battle_mode = "level_1"
	TeamConfig.team_members = [
		TeamConfig.get_saved_build("sara"),
		TeamConfig.get_saved_build("isaac")
	]

	var battle_scene = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var sara_unit: CombatUnit = null
	for ally in battle_scene.battle_manager.allies:
		if ally.id == "sara":
			sara_unit = ally
			break

	assert(sara_unit != null, "Sara must be present in allies")
	var sara_panel: PanelContainer = battle_scene._unit_panels[sara_unit]
	assert(is_instance_valid(sara_panel), "Sara panel must be valid")
	var sara_bg = sara_panel.get_node_or_null("CharacterSplashBG")
	assert(sara_bg != null and sara_bg is TextureRect, "Sara battle card must have CharacterSplashBG TextureRect")
	assert((sara_bg as TextureRect).texture != null, "CharacterSplashBG must have texture set")
	assert((sara_bg as TextureRect).modulate.a <= 0.5, "CharacterSplashBG must be dimmed/darkened in battle")
	print("  [PASS] test_2_battle_card_splash_background")

	# Тест 3: Окно инспекции персонажа в бою
	battle_scene._open_inspect(sara_unit)
	var inspect_panel: PanelContainer = battle_scene.get_node("%InspectPanel")
	assert(inspect_panel != null, "InspectPanel must exist")
	var inspect_bg = inspect_panel.get_node_or_null("InspectSplashBG")
	assert(inspect_bg != null and inspect_bg is TextureRect, "InspectPanel must have InspectSplashBG")
	assert(inspect_bg.visible, "InspectSplashBG must be visible for character with splash")
	battle_scene._close_inspect()
	print("  [PASS] test_3_battle_inspect_splash_background")

	battle_scene.queue_free()
	await get_tree().process_frame

	# Тест 4: Главное меню — магазин и карточки товаров
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu_scene)
	await get_tree().process_frame

	menu_scene._show_screen("shop")
	menu_scene._refresh_shop_ui()
	var shop_sara = menu_scene.shop_grid.get_node_or_null("shop_char_sara")
	assert(shop_sara != null, "Sara must exist in shop")
	var shop_sara_bg = shop_sara.get_node_or_null("ShopSplashBG")
	assert(shop_sara_bg != null and shop_sara_bg is TextureRect, "Shop card for Sara must have ShopSplashBG")
	print("  [PASS] test_4_shop_card_splash_background")

	# Тест 5: Баннер гачи и показ выбитого персонажа
	menu_scene._show_screen("gacha")
	var rimes_banner_idx := -1
	for idx in range(menu_scene.BANNERS.size()):
		if menu_scene.BANNERS[idx].id == "rimes":
			rimes_banner_idx = idx
			break
	if rimes_banner_idx >= 0:
		menu_scene.active_banner_idx = rimes_banner_idx
		menu_scene._refresh_gacha_ui()
		var b_panel: PanelContainer = menu_scene.gacha_screen.find_child("BannerPanel", true, false)
		assert(b_panel != null, "BannerPanel must exist")
		var b_splash = b_panel.get_node_or_null("BannerSplashBG")
		assert(b_splash != null and b_splash.visible, "Rimes banner must display BannerSplashBG")
		print("  [PASS] test_5_gacha_banner_splash_background")

	menu_scene.queue_free()
	await get_tree().process_frame

	var team_scene = load("res://scenes/team_setup/team_setup.tscn").instantiate()
	add_child(team_scene)
	await get_tree().process_frame

	team_scene._team[0] = TeamConfig.get_saved_build("sara")
	team_scene._team[1] = null
	team_scene._refresh_team_slots()
	var slot0: PanelContainer = team_scene.team_slots.get_child(0)
	var slot0_bg = slot0.get_node_or_null("SlotSplashBG")
	assert(slot0_bg != null and slot0_bg.visible, "Slot 0 with Sara must display SlotSplashBG")

	var slot1: PanelContainer = team_scene.team_slots.get_child(1)
	var slot1_bg = slot1.get_node_or_null("SlotSplashBG")
	assert(slot1_bg == null or not slot1_bg.visible, "Empty slot 1 must not display visible SlotSplashBG")
	print("  [PASS] test_6_team_setup_slot_splash_background")

	team_scene.queue_free()
	await get_tree().process_frame

	# Тест 7: Инвентарь — карточки персонажей со сплеш-артами
	var menu2 = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu2)
	await get_tree().process_frame

	if not ("sara" in TeamConfig.unlocked_characters):
		TeamConfig.unlocked_characters.append("sara")
	menu2._show_screen("inventory")
	menu2._refresh_inventory_ui()

	var found_inv_splash := false
	for btn in menu2.inv_characters_grid.get_children():
		var splash_node = btn.get_node_or_null("InvSplashBG")
		if splash_node != null and splash_node is TextureRect and splash_node.texture != null:
			found_inv_splash = true
			assert(splash_node.z_index == 0, "InvSplashBG must be at z_index 0")
			break
	assert(found_inv_splash, "At least one inventory character card must have InvSplashBG")
	print("  [PASS] test_7_inventory_card_splash_background")

	# Тест 8: Меню «Текущий отряд» — карточки в ряд со сплеш-артами
	TeamConfig.team_members = [
		{"id": "sara", "eidolon": 1},
		{"id": "isaac", "eidolon": 0}
	]
	menu2._refresh_hub_overview()
	assert(menu2.hub_overview_team_vbox is HBoxContainer, "hub_overview_team_vbox must be an HBoxContainer (row of cards)")
	assert(menu2.hub_overview_team_vbox.get_child_count() == 4, "Must have exactly 4 slot cards in a row")

	var hub_card_0: PanelContainer = menu2.hub_overview_team_vbox.get_child(0)
	var hub_bg_0 = hub_card_0.get_node_or_null("HubSlotSplashBG")
	assert(hub_bg_0 != null and hub_bg_0 is TextureRect, "Hub slot card with Sara must have HubSlotSplashBG")

	var hub_card_empty: PanelContainer = menu2.hub_overview_team_vbox.get_child(2)
	var hub_bg_empty = hub_card_empty.get_node_or_null("HubSlotSplashBG")
	assert(hub_bg_empty == null or not hub_bg_empty.visible, "Empty hub slot must not display HubSlotSplashBG")
	print("  [PASS] test_8_hub_overview_cards_row_and_splash")

	# Тест 9: Подготовка к уровню — карусель в 1 ряд, крупные карточки со сплеш-артами
	assert(menu2.level_team_roster_container is HBoxContainer, "level_team_roster_container must be HBoxContainer (single row)")
	menu2._open_level_team_setup(6)
	assert(menu2.level_team_roster_container.get_child_count() > 0, "Roster must contain character cards")

	var first_roster_card = menu2.level_team_roster_container.get_child(0)
	assert(first_roster_card.custom_minimum_size.x >= 150, "Roster card must be large (width >= 150)")
	assert(first_roster_card.custom_minimum_size.y >= 180, "Roster card must be large (height >= 180)")

	var found_roster_splash := false
	for card in menu2.level_team_roster_container.get_children():
		var splash_node = card.get_node_or_null("RosterCardSplashBG")
		if splash_node != null and splash_node is TextureRect:
			found_roster_splash = true
			break
	assert(found_roster_splash, "Roster carousel must feature RosterCardSplashBG on characters with splash")
	print("  [PASS] test_9_level_team_setup_single_row_carousel_and_splash")

	# Тест 10: Непрозрачность меню эйдолонов в инвентаре
	menu2._show_eidolon_details_modal("sara")
	var eidolon_modal = menu2.find_child("EidolonDetailsModal", true, false)
	assert(eidolon_modal != null and eidolon_modal is ColorRect, "EidolonDetailsModal must exist when opened")
	assert((eidolon_modal as ColorRect).color.a >= 0.85, "Dimmer behind eidolon modal must be dark and opaque")
	var eidolon_panel = eidolon_modal.find_child("ModalPanel", true, false) as PanelContainer
	assert(eidolon_panel != null, "ModalPanel must exist")
	var eidolon_sb = eidolon_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(eidolon_sb != null, "ModalPanel must have StyleBoxFlat")
	assert(eidolon_sb.bg_color.a == 1.0, "Eidolon modal panel must be 100% opaque (bg_color.a == 1.0)")
	eidolon_modal.queue_free()
	await get_tree().process_frame
	print("  [PASS] test_10_eidolon_modal_is_solid_opaque")

	# Тест 11: Меню светового конуса в инвентаре (описание + статус экипировки)
	var cone_archive: Dictionary = LightConeRegistry.get_cone("archive")
	assert(not cone_archive.is_empty(), "Archive cone must exist in registry")
	
	# Проверяем свободный статус
	menu2._show_light_cone_details_modal("archive")
	var cone_modal = menu2.find_child("LightConeDetailsModal", true, false)
	assert(cone_modal != null and cone_modal is ColorRect, "LightConeDetailsModal must exist when opened")
	assert((cone_modal as ColorRect).color.a >= 0.85, "Dimmer behind cone modal must be dark and opaque")
	var cone_panel = cone_modal.find_child("ModalPanel", true, false) as PanelContainer
	assert(cone_panel != null, "ModalPanel must exist in cone modal")
	var cone_sb = cone_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(cone_sb != null and cone_sb.bg_color.a == 1.0, "Light cone modal must be 100% opaque")
	var cone_desc_node = cone_modal.find_child("ConeDescText", true, false) as RichTextLabel
	assert(cone_desc_node != null and cone_desc_node.text.contains(cone_archive.desc), "Cone modal must contain full description")
	var cone_carrier_node = cone_modal.find_child("ConeCarrierText", true, false) as RichTextLabel
	assert(cone_carrier_node != null and (cone_carrier_node.text.contains("Свободен") or cone_carrier_node.text.contains("Надето")), "Carrier status must be displayed")
	cone_modal.queue_free()
	await get_tree().process_frame
	print("  [PASS] test_11_light_cone_inventory_modal_and_description")

	menu2.queue_free()
	await get_tree().process_frame

	# Тест 12: Кат-сцена Сверхспособности — вылет карточки со сплеш-артом и анимация падения
	TeamConfig.reset()
	TeamConfig.battle_mode = "level_1"
	TeamConfig.team_members = [
		TeamConfig.get_saved_build("sara"),
		TeamConfig.get_saved_build("vika")
	]

	var battle_scene2 = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle_scene2)
	await get_tree().process_frame
	await get_tree().process_frame

	var sara2: CombatUnit = null
	for ally in battle_scene2.battle_manager.allies:
		if ally.id == "sara":
			sara2 = ally
			break
	assert(sara2 != null, "Sara must exist in battle 2")

	# Запускаем кат-сцену ульты
	battle_scene2._on_ultimate_started(sara2)
	assert(battle_scene2.battle_manager.has_meta("is_playing_ult_cutin"), "is_playing_ult_cutin meta must be set")
	
	var cutin_root = battle_scene2.get_node_or_null("UltimateCutInRoot")
	assert(cutin_root != null, "UltimateCutInRoot must be spawned")
	var cutin_card = cutin_root.get_node_or_null("CutinCard") as PanelContainer
	assert(cutin_card != null, "CutinCard must exist")
	var cutin_splash = cutin_card.get_node_or_null("CutinSplashBG") as TextureRect
	assert(cutin_splash != null and cutin_splash.texture != null, "CutinCard must show Sara's splash art")

	# Ожидаем завершения полного цикла анимации (затемнение, падение внутрь, исчезновение, проявление поля)
	var wait_time := 0.0
	while battle_scene2.battle_manager.has_meta("is_playing_ult_cutin") and wait_time < 4.0:
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	assert(not battle_scene2.battle_manager.has_meta("is_playing_ult_cutin"), "Cut-in flag must be cleared after animation finishes")
	assert(battle_scene2.get_node_or_null("UltimateCutInRoot") == null, "UltimateCutInRoot must be freed after animation")
	print("  [PASS] test_12_ultimate_card_popout_and_falling_animation")

	# Тест 13: Порядок Сверхспособности — СНАЧАЛА анимация, ПОТОМ выбор цели на поле
	var vika: CombatUnit = null
	for ally in battle_scene2.battle_manager.allies:
		if ally.id == "vika":
			vika = ally
			break
	assert(vika != null, "Vika must exist in battle 2")
	vika.energy = vika.max_energy

	# Нажимаем ульту Вики (требующей выбора цели)
	battle_scene2._on_card_ult_pressed(vika)
	
	# Проверяем: анимация запущена ПЕРВОЙ, выбор цели пока НЕ активен
	assert(battle_scene2.battle_manager.has_meta("is_playing_ult_cutin"), "Cut-in animation must start FIRST")
	assert(not battle_scene2._selecting_target, "Target selection must NOT be active while cut-in animation is playing")

	# Ждем окончания анимации
	wait_time = 0.0
	while battle_scene2.battle_manager.has_meta("is_playing_ult_cutin") and wait_time < 4.0:
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	assert(not battle_scene2.battle_manager.has_meta("is_playing_ult_cutin"), "Cut-in must finish before target selection")
	# Даем 1 кадр на активацию режима прицеливания
	await get_tree().process_frame
	await get_tree().process_frame

	# Теперь выбор цели должен активироваться на проявившемся поле боя!
	assert(battle_scene2._selecting_target, "Target selection MUST become active AFTER cut-in finishes")
	assert(battle_scene2._target_mode == "ult", "Target mode must be 'ult'")

	# Выбираем первого живого врага
	var enemy: CombatUnit = battle_scene2.battle_manager.get_living_enemies()[0]
	battle_scene2._on_target_pressed(enemy, false)
	assert(not battle_scene2._selecting_target, "Target selection must end after choosing target")
	
	# Ждем полного завершения исполнения ультимейта Вики из очереди
	while battle_scene2.battle_manager._is_processing_ult_queue:
		await get_tree().create_timer(0.05).timeout
	
	print("  [PASS] test_13_ultimate_cutin_before_targeting_flow")

	# Тест 14: Проверка безопасности боевой системы — баффы, дебаффы, очереди и активность ходов не ломаются
	# 1. Проверяем баффы: накладываем 2-ходовой бафф атаки на союзника и 2-ходовой дебафф на врага
	sara2.statuses.atk_buff_turns = 2
	sara2.statuses.atk_buff_percent = 0.30
	enemy.statuses.has_dark_seal = true
	enemy.statuses.dark_seal_turns = 2

	# Устанавливаем, что сейчас идёт активный ход Сары
	battle_scene2.battle_manager.current_unit = sara2
	battle_scene2._is_ally_turn_active = true
	battle_scene2.battle_manager._waiting_for_player = true

	# 2. Сара ультует во время своего хода
	sara2.energy = sara2.max_energy
	battle_scene2._on_card_ult_pressed(sara2)

	# Ульт встал в очередь, энергия потрачена сразу
	assert(sara2.energy < sara2.max_energy, "Energy must be spent upon queuing ultimate")
	assert(battle_scene2.battle_manager.has_meta("is_playing_ult_cutin"), "Cutin animation must be active")

	# Ждем завершения кат-сцены ультимейта Сары
	wait_time = 0.0
	while battle_scene2.battle_manager.has_meta("is_playing_ult_cutin") and wait_time < 4.0:
		await get_tree().create_timer(0.05).timeout
		wait_time += 0.05

	# Ждем исполнения ультимейта Сары
	await get_tree().create_timer(0.8).timeout

	# 3. ПРОВЕРКА БЕЗОПАСНОСТИ БОЕВОЙ СИСТЕМЫ:
	# А) Сверхспособность НЕ является ходом: счетчики баффов и дебаффов НЕ уменьшились!
	assert(sara2.statuses.atk_buff_turns == 2, "Ally buff turns must NOT tick down on ultimate")
	assert(enemy.statuses.dark_seal_turns == 2, "Enemy debuff turns must NOT tick down on ultimate")

	# Б) Ход Сары остался активен и не сбросился
	assert(battle_scene2.battle_manager.current_unit == sara2, "Active turn unit must remain preserved after ultimate")
	assert(battle_scene2.battle_manager._waiting_for_player, "BattleManager must wait for player to finish active ally turn")

	# В) Повторная попытка ультануть Сарой без энергии блокируется
	assert(sara2.energy < sara2.max_energy, "Sara energy is spent")
	var prev_queue_size: int = battle_scene2.battle_manager.ult_queue.size()
	battle_scene2._on_card_ult_pressed(sara2)
	assert(battle_scene2.battle_manager.ult_queue.size() == prev_queue_size, "Cannot queue ultimate without full energy")

	print("  [PASS] test_14_ultimate_buff_turn_and_action_safety")

	battle_scene2.queue_free()
	await get_tree().process_frame

	print("\n--------------------------------------------------------")
	print("  РЕЗУЛЬТАТ: Все 14 тестов успешно пройдены!")
	print("========================================================\n")

	get_tree().quit(0)
