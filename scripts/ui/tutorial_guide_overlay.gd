class_name TutorialGuideOverlay
extends Control

## Интерактивный оверлей обучения со светящейся рамкой и динамической стрелкой.
## Отслеживает целевой элемент в реальном времени, адаптируясь к прокрутке,
## перерисовкам UI и изменению разрешения окна.

# Цветовая палитра
const COLOR_BORDER_GOLD := Color(1.0, 0.85, 0.25, 0.95)
const COLOR_BORDER_GLOW := Color(1.0, 0.85, 0.25, 0.35)
const COLOR_BG_PANEL := Color(0.07, 0.09, 0.15, 0.96)

# UI элементы
var dialog_panel: PanelContainer
var header_label: Label
var step_badge: Label
var text_label: RichTextLabel
var btn_next: Button
var btn_skip: Button

var pointer_label: Label
var highlight_rect_control: Control

# Состояние трекинга
var _target_ref: WeakRef = null
var _arrow_direction: String = "auto" # "auto", "up", "down", "left", "right"
var _bob_timer: float = 0.0
var _on_next_callable: Callable = Callable()
var _on_skip_callable: Callable = Callable()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 150 # Всегда поверх большинства интерфейсов

func _ready() -> void:
	_build_ui()

func _process(delta: float) -> void:
	_bob_timer += delta * 5.0
	_update_target_visuals()

# --- 1. СОЗДАНИЕ ИНТЕРФЕЙСА ---

func _build_ui() -> void:
	# 1. Контрол для отрисовки светящейся рамки вокруг цели
	highlight_rect_control = Control.new()
	highlight_rect_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect_control.visible = false
	highlight_rect_control.draw.connect(_on_draw_highlight)
	add_child(highlight_rect_control)

	# 2. Анимированная стрелка-указатель
	pointer_label = Label.new()
	pointer_label.text = "⬇"
	pointer_label.add_theme_font_size_override("font_size", 52)
	pointer_label.add_theme_color_override("font_color", COLOR_BORDER_GOLD)
	pointer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	pointer_label.add_theme_constant_override("outline_size", 10)
	pointer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer_label.visible = false
	add_child(pointer_label)

	# 3. Карточка инструкций (диалог)
	dialog_panel = PanelContainer.new()
	dialog_panel.custom_minimum_size = Vector2(420, 260)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG_PANEL
	sb.border_color = COLOR_BORDER_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	dialog_panel.add_theme_stylebox_override("panel", sb)
	add_child(dialog_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(main_vbox)

	# Шапка карточки: Бейдж шага + Заголовок
	var header_hbox := HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_child(header_hbox)

	step_badge = Label.new()
	step_badge.text = "✦ ОБУЧЕНИЕ ✦"
	step_badge.add_theme_font_size_override("font_size", 13)
	step_badge.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	header_hbox.add_child(step_badge)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	header_label = Label.new()
	header_label.text = "🧭 Наставник"
	header_label.add_theme_font_size_override("font_size", 14)
	header_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	header_hbox.add_child(header_label)

	# Разделитель
	var sep := HSeparator.new()
	var sep_sb := StyleBoxLine.new()
	sep_sb.color = Color(0.3, 0.4, 0.6, 0.5)
	sep_sb.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_sb)
	main_vbox.add_child(sep)

	# Текст инструкций
	text_label = RichTextLabel.new()
	text_label.custom_minimum_size = Vector2(0, 140)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.bbcode_enabled = true
	text_label.add_theme_font_size_override("normal_font_size", 15)
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_child(text_label)

	# Нижняя панель кнопок: Пропустить + Далее
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(btn_hbox)

	btn_skip = Button.new()
	btn_skip.text = "⏩ Пропустить"
	btn_skip.custom_minimum_size = Vector2(130, 40)
	btn_skip.add_theme_font_size_override("font_size", 14)
	var skip_sb := StyleBoxFlat.new()
	skip_sb.bg_color = Color(0.22, 0.18, 0.12, 0.9)
	skip_sb.border_color = Color(0.8, 0.65, 0.25, 0.7)
	skip_sb.set_border_width_all(1)
	skip_sb.set_corner_radius_all(8)
	btn_skip.add_theme_stylebox_override("normal", skip_sb)
	var skip_sb_h := skip_sb.duplicate() as StyleBoxFlat
	skip_sb_h.bg_color = Color(0.35, 0.28, 0.15, 1.0)
	btn_skip.add_theme_stylebox_override("hover", skip_sb_h)
	btn_skip.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	btn_skip.pressed.connect(_on_skip_pressed)
	btn_hbox.add_child(btn_skip)

	btn_next = Button.new()
	btn_next.text = "Далее ➔"
	btn_next.custom_minimum_size = Vector2(160, 42)
	btn_next.add_theme_font_size_override("font_size", 15)
	var next_sb := StyleBoxFlat.new()
	next_sb.bg_color = Color(0.12, 0.50, 0.88, 1.0)
	next_sb.set_corner_radius_all(8)
	btn_next.add_theme_stylebox_override("normal", next_sb)
	var next_sb_h := next_sb.duplicate() as StyleBoxFlat
	next_sb_h.bg_color = Color(0.20, 0.60, 0.98, 1.0)
	btn_next.add_theme_stylebox_override("hover", next_sb_h)
	btn_next.pressed.connect(_on_next_pressed)
	btn_hbox.add_child(btn_next)

	# Исходное положение карточки (справа по центру)
	_place_dialog("right")

# --- 2. МЕТОДЫ УПРАВЛЕНИЯ ОБУЧЕНИЕМ ---

func set_dialog(title: String, text: String, step_str: String = "", show_next: bool = false, next_btn_text: String = "Далее ➔", on_next_cb: Callable = Callable(), show_skip: bool = false) -> void:
	if not header_label or not text_label:
		return
	if not title.is_empty():
		header_label.text = title
	if not step_str.is_empty():
		step_badge.text = step_str
	text_label.text = text
	btn_next.visible = show_next
	btn_next.text = next_btn_text
	_on_next_callable = on_next_cb
	if btn_skip:
		btn_skip.visible = show_skip and _on_skip_callable.is_valid()

func point_at(target: Control, arrow_dir: String = "auto") -> void:
	if not target or not is_instance_valid(target):
		hide_pointer()
		return
	_target_ref = weakref(target)
	_arrow_direction = arrow_dir
	highlight_rect_control.visible = true
	pointer_label.visible = true
	_update_target_visuals()

func hide_pointer() -> void:
	_target_ref = null
	if highlight_rect_control:
		highlight_rect_control.visible = false
	if pointer_label:
		pointer_label.visible = false

func set_skip_callback(cb: Callable) -> void:
	_on_skip_callable = cb
	if btn_skip:
		btn_skip.visible = false # По умолчанию скрыта, отображается только по флагу show_skip на шаге 1

func set_skip_visible(is_vis: bool) -> void:
	if btn_skip:
		btn_skip.visible = is_vis and _on_skip_callable.is_valid()

func set_dialog_position(pos: String) -> void:
	_place_dialog(pos)

# --- 3. ОБНОВЛЕНИЕ ТРЕКИНГА И ОТРИСОВКА ПОДСВЕТКИ ---

func _update_target_visuals() -> void:
	if _target_ref == null:
		return
	var target = _target_ref.get_ref() as Control
	if not target or not is_instance_valid(target) or not target.is_inside_tree() or not target.is_visible_in_tree():
		highlight_rect_control.visible = false
		pointer_label.visible = false
		return

	highlight_rect_control.visible = true
	pointer_label.visible = true

	var rect: Rect2 = target.get_global_rect()
	# Защита от нулевого размера до завершения layout
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		var min_s: Vector2 = target.custom_minimum_size
		if min_s.x > 1.0 and min_s.y > 1.0:
			rect.size = min_s

	# Запрашиваем перерисовку рамки
	highlight_rect_control.queue_redraw()

	# Рассчитываем положение стрелки и карточки диалога
	var viewport_size := get_viewport_rect().size
	var dir := _arrow_direction
	if dir == "auto":
		if rect.position.y > 140.0:
			dir = "down" # Сверху кнопки, стрелка вниз
		elif rect.position.y < viewport_size.y - 200.0:
			dir = "up" # Снизу кнопки, стрелка вверх
		elif rect.position.x > 150.0:
			dir = "right"
		else:
			dir = "left"

	var bob_offset: float = sin(_bob_timer) * 6.0
	var arrow_pos := Vector2.ZERO

	match dir:
		"down":
			pointer_label.text = "⬇"
			arrow_pos = Vector2(rect.position.x + (rect.size.x - 36.0) * 0.5, rect.position.y - 60.0 + bob_offset)
		"up":
			pointer_label.text = "⬆"
			arrow_pos = Vector2(rect.position.x + (rect.size.x - 36.0) * 0.5, rect.end.y + 10.0 + bob_offset)
		"right":
			pointer_label.text = "➡"
			arrow_pos = Vector2(rect.position.x - 55.0 + bob_offset, rect.position.y + (rect.size.y - 45.0) * 0.5)
		"left":
			pointer_label.text = "⬅"
			arrow_pos = Vector2(rect.end.x + 10.0 + bob_offset, rect.position.y + (rect.size.y - 45.0) * 0.5)

	pointer_label.global_position = arrow_pos

	# Адаптивно размещаем диалог, чтобы он не перекрывал цель
	if rect.position.y > viewport_size.y * 0.50:
		_place_dialog("top")
	elif rect.position.y < viewport_size.y * 0.30:
		_place_dialog("bottom")
	elif rect.position.x > viewport_size.x * 0.55:
		_place_dialog("left")
	elif rect.position.x < viewport_size.x * 0.35:
		_place_dialog("right")
	else:
		_place_dialog("top")

func _on_draw_highlight() -> void:
	if _target_ref == null:
		return
	var target = _target_ref.get_ref() as Control
	if not target or not is_instance_valid(target) or not target.is_inside_tree():
		return

	var rect: Rect2 = target.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		var min_s: Vector2 = target.custom_minimum_size
		if min_s.x > 1.0 and min_s.y > 1.0:
			rect.size = min_s

	# Добавляем небольшой отступ вокруг кнопки
	var pad := 4.0
	var draw_r := Rect2(rect.position - Vector2(pad, pad), rect.size + Vector2(pad * 2.0, pad * 2.0))

	# Пульсирующее свечение рамки
	var pulse: float = 0.65 + 0.35 * (sin(_bob_timer) * 0.5 + 0.5)
	var stroke_col := COLOR_BORDER_GOLD
	stroke_col.a = pulse

	# Внешний ореол
	var glow_r := Rect2(draw_r.position - Vector2(2, 2), draw_r.size + Vector2(4, 4))
	highlight_rect_control.draw_rect(glow_r, COLOR_BORDER_GLOW, false, 3.0)
	# Основная рамка
	highlight_rect_control.draw_rect(draw_r, stroke_col, false, 2.5)

func _place_dialog(side: String) -> void:
	if not dialog_panel:
		return
	match side:
		"left":
			dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			dialog_panel.offset_left = 30
			dialog_panel.offset_right = 450
			dialog_panel.offset_bottom = -30
			dialog_panel.offset_top = -290
		"top":
			dialog_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
			dialog_panel.offset_left = -210
			dialog_panel.offset_right = 210
			dialog_panel.offset_top = 30
			dialog_panel.offset_bottom = 290
		"bottom":
			dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			dialog_panel.offset_left = -210
			dialog_panel.offset_right = 210
			dialog_panel.offset_bottom = -30
			dialog_panel.offset_top = -290
		_: # "right"
			dialog_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			dialog_panel.offset_left = -460
			dialog_panel.offset_right = -30
			dialog_panel.offset_top = -130
			dialog_panel.offset_bottom = 130

func _on_next_pressed() -> void:
	if _on_next_callable.is_valid():
		_on_next_callable.call()

func _on_skip_pressed() -> void:
	if _on_skip_callable.is_valid():
		_on_skip_callable.call()
