class_name CharacterRegistry
extends RefCounted

static func get_available_characters() -> Array[Dictionary]:
	return [
		{
			"id": "vika",
			"name": "Вика",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 3,
			"description": "Первый бесплатный персонаж Разрушения (Квантовый). Боец со скейлингом урона от своего макс. ХП, легкая для новичков.",
		},
		{
			"id": "marina",
			"name": "Марина",
			"element": CombatConstants.Element.ICE,
			"path": CombatConstants.Path.ERUDITION,
			"rarity": 5,
			"description": "АоЕ ДД ледяного элемента. Накладывает Подавление.",
		},
		{
			"id": "sara",
			"name": "Сара",
			"element": CombatConstants.Element.PHYSICAL,
			"path": CombatConstants.Path.ABUNDANCE,
			"rarity": 4,
			"description": "Целитель физического элемента. Лечит союзников и накладывает «Заплатку».",
			"splash": "res://assets/characters/sara.jpg",
		},
		{
			"id": "arseniy",
			"name": "Арсений",
			"element": CombatConstants.Element.ICE,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 4,
			"description": "Бафер ледяного элемента. «Тёмная печать» и «Новая разработка».",
		},
		{
			"id": "pusenkov",
			"name": "Кирилл",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.HUNT,
			"rarity": 5,
			"description": "Гиперкерри ветряного урона (Охота). Наносит огромный урон по одной цели, имеет низкую живучесть и очень дорогую ульту.",
		},
		{
			"id": "kaori",
			"name": "Каори",
			"element": CombatConstants.Element.PHYSICAL,
			"path": CombatConstants.Path.HUNT,
			"rarity": 4,
			"description": "Охотница пробития (Физический). Понижает защиту врагов, накладывает уязвимости и играет от Эффекта Пробития.",
		},
		{
			"id": "shoji",
			"name": "Сёдзи",
			"element": CombatConstants.Element.FIRE,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 5,
			"description": "Специалист по периодическому огненному урону (Небытие). Снижает защиту врагов за каждый дебафф и взрывает эффекты Горения.",
		},
		{
			"id": "dasha",
			"name": "Даша",
			"element": CombatConstants.Element.LIGHTNING,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 4,
			"description": "Специалист по бонус-атакам и суперпробитию (Разрушение). Входит в «Танец кругов» и обрушивает электрические молнии.",
		},
		{
			"id": "danill",
			"name": "Данилл",
			"element": CombatConstants.Element.FIRE,
			"path": CombatConstants.Path.PRESERVATION,
			"rarity": 4,
			"description": "Первый щитовик (Сохранение). Прочность его щитов и урон базовых атак полностью зависят от его показателя Защиты.",
		},
		{
			"id": "dotseva",
			"name": "Юлия Доцева",
			"element": CombatConstants.Element.IMAGINARY,
			"path": CombatConstants.Path.ERUDITION,
			"rarity": 5,
			"description": "Гиперкерри с бонус-атаки. Бьёт по всем целям и разгоняет свой урон за счёт стаков Калибровки.",
		},
		{
			"id": "milena",
			"name": "Милена",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 5,
			"description": "Универсальный саппорт с особой системой баффов для Обречйнных",
		},
		{
			"id": "naama",
			"name": "Наама",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 4,
			"description": "Специалист по накоплению стаков Опьянения (Небытие). Понижает защиту и наносит сокрушительный DoT урон в связке с Сёдзи.",
		},
		{
			"id": "lenskaya",
			"name": "Ленская",
			"element": CombatConstants.Element.ICE,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 5,
			"description": "Охотник на головы из Рассвета Хаоса (Ледяной). Невероятный керри от бонус-атак, накапливающий заряды Манипуляции при каждом совместном ударе.",
		},
		{
			"id": "rimes",
			"name": "Раймс",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.HUNT,
			"rarity": 5,
			"description": "Безжалостный палач из Рассвета Хаоса (Квантовый). Способен затянуть противника в Вечную Изоляцию и казнить его чистым уроном.",
			"splash": "res://assets/characters/rimes.jpg",
		},
		{
			"id": "isaac",
			"name": "Айзек",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 4,
			"description": "Гениальный теоретик из Академии (Ветряной). Саппорт-баффер, способный продвигать ходы союзников на 100%, повышать их КУ на 100% и накладывать уязвимости.",
			"splash": "res://assets/characters/isaac.jpg",
		},
		{
			"id": "keloist",
			"name": "Келойст",
			"element": CombatConstants.Element.FIRE,
			"path": CombatConstants.Path.ERUDITION,
			"rarity": 4,
			"description": "Специалист по координации союзников из Эмпирейцев (Огненный). Накладывает защитный Ортощит и проводит сокрушительные совместные атаки.",
		},
		{
			"id": "musienko",
			"name": "Мусиенко",
			"element": CombatConstants.Element.FIRE,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 5,
			"description": "Безумный разрушитель из Рассвета Хаоса (Огненный). Меч правосудия, черпающий свою колоссальную мощь напрямую из собственного запаса ХП.",
		},
		{
			"id": "joan",
			"name": "Жоан",
			"element": CombatConstants.Element.LIGHTNING,
			"path": CombatConstants.Path.HUNT,
			"rarity": 4,
			"description": "Участник отряда Искра-гамма. Позволяет концентрировать размазанный урон на одной главной цели. Отлично работает с Эрудитами.",
		},
		{
			"id": "jeff",
			"name": "Джефф",
			"element": CombatConstants.Element.LIGHTNING,
			"path": CombatConstants.Path.ABUNDANCE,
			"rarity": 5,
			"description": "Поп-везда Трущоб. Его музыка лечит союзников, и накладывает ДоТ эффекты на врагов",
		},
		{
			"id": "valramors",
			"name": "Валраморс",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 5,
			"description": "Силуэт, чья личность покрыта тайной. Истощает врагов, позволяя ДД нанести решающий удар.",
		},
		{
			"id": "joan_spirit",
			"name": "Жоан • Дух решимости",
			"element": CombatConstants.Element.IMAGINARY,
			"path": CombatConstants.Path.ERUDITION,
			"rarity": 5,
			"description": "Легендарный гипер-керри Эрудиции (Мнимый). Входит в вечную «Форму духа», раскалывает одиночных боссов на 5 копий и обрушивает лавину Мнимого урона.",
		},
		{
			"id": "isaac_admin",
			"name": "Айзек • Права администратора",
			"element": CombatConstants.Element.PHYSICAL,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 5,
			"description": "Легендарный мейн ДД Консоли (Физический). Повелитель Бинарного урона, аккумулирующий Векторы для перегрузок Таланта и сокрушительного взлома.",
			"splash": "res://assets/characters/isaac_admin.jpg",
		},
		{
			"id": "sara_admin",
			"name": "Сара • Права администратора",
			"element": CombatConstants.Element.LIGHTNING,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 5,
			"description": "Легендарный саппорт Консоли (Электрический). Разворачивает Среду разработки, разгоняет Бинарный урон от своей скорости и активирует протоколы команды.",
			"splash": "res://assets/characters/sara_admin.jpg",
		},
		{
			"id": "arseniy_admin",
			"name": "Арсений • Права администратора",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 4,
			"description": "Дебаффер Консоли (Квантовый). Срезает защиту и повышает получаемый Бинарный урон. Перегружает систему (сброс Векторов) при достижении 150 стаков.",
		},
		{
			"id": "dasha_admin",
			"name": "Даша • Права администратора",
			"element": CombatConstants.Element.IMAGINARY,
			"path": CombatConstants.Path.PRESERVATION,
			"rarity": 4,
			"description": "Элитный щитовик Консоли (Мнимый). Масштабирует прочность щитов от Цифровых следов, обновляет их ультой и усиливает команду.",
		},
		{
			"id": "shoji_swan",
			"name": "Сёдзи • Лебединое озеро",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 5,
			"description": "Легендарный дуальный адаптатор Консоли (Ветряной). На 1 позиции — сокрушительный ДД с Бинарным уроном («Вирус»), на позициях 2–4 — мощный саппорт/сап-дд («Танец»), разгоняющий скорость, не-бинарный урон команды и пробитие сопротивлений гиперкерри.",
		},
		{
			"id": "katarina",
			"name": "Катарина",
			"element": CombatConstants.Element.PHYSICAL,
			"path": CombatConstants.Path.NIHILITY,
			"rarity": 5,
			"description": "Элитный ДД Небытия из Эмпирейцев (Физический). Накладывает физ. уязвимость, входит в неуязвимость Навыком E и обрушивает серию ударов «Журчания крови». Играет через статус «Сломленный дух», требуя Сап-ДД в команде.",
		},
		{
			"id": "dotseva_crimson_tears",
			"name": "Доцева • Багровые слёзы",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.PRESERVATION,
			"rarity": 5,
			"description": "Легендарный щитовик и дебаффер из Эмпирейцев (Ветряной). Разворачивает защитную Зону с перенаправлением урона союзников на себя, ослабляет врагов и накапливает стаки «Закрой глаза».",
		},
		{
			"id": "lenskaya_antimatter",
			"name": "Ленская • Явление антиматерии",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.DESTRUCTION,
			"rarity": 5,
			"description": "Легендарный мейн ДД Антиматерии (Квантовый). Повелитель ресурса Xaeroh и Сверхновой. Переходит в формы «Хранитель Ничто» и «Воин небытия», казнит врагов из состояния «В изнанке» и обрушивает колоссальный урон Сверхспособности.",
		},
		{
			"id": "velzebul",
			"name": "Вельзевул",
			"element": CombatConstants.Element.ICE,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 5,
			"description": "Легендарный саппорт Антиматерии (Ледяной). Собирает Грешные сердца для разблокировки Усиленного Навыка E и Сверхспособности. Накладывает «Печать Вельзевула», разгоняет Зеро, продвигает действия союзников и наделяет команду сокрушительными критами и бонусами урона.",
		},
		{
			"id": "marina_sky_guardian",
			"name": "Марина • Хранитель небес",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.REMEMBRANCE,
			"rarity": 5,
			"description": "Первый легендарный персонаж Пути Памяти (Ветряной). Стандартный кор команд Памяти, сап-ДД и саппорт. Призывает духа памяти «Эго», разворачивает зону «Элизиум», связывает союзников узами Крит. шанса и пробуждает «Деву луны» Хранителей небес.",
		},
		{
			"id": "lenskaya_sky_guardian",
			"name": "Ленская • Хранитель небес",
			"element": CombatConstants.Element.IMAGINARY,
			"path": CombatConstants.Path.HUNT,
			"rarity": 4,
			"description": "Охотница Мнимого урона (4★). ДД и сап-ДД в командах от пробития. Накладывает на врага статус «Враг Свечения» (1.5x эффективность стойкости, +30% урона Пробития и Суперпробития), проводит 6-ударную усиленную базовую атаку и конвертирует атаки команды по пробитым врагам в 60% урона суперпробития.",
		},
		{
			"id": "rimes_ascension",
			"name": "Раймс • Восхождение",
			"element": CombatConstants.Element.QUANTUM,
			"path": CombatConstants.Path.REMEMBRANCE,
			"rarity": 5,
			"description": "Легендарный Hyper-carry Пути Памяти (Квантовый, 5★ Limited). Масштабирует урон от макс. ХП, жертвует здоровьем отряда для сокрушительных совместных атак с Духом Памяти «Лапы антиматерии», накапливает заряды «Крещендо» и разворачивает зону «Разрыв» со срезом всех сопротивлений противников.",
		},
		{
			"id": "sanguinia",
			"name": "Сангиния Ял",
			"element": CombatConstants.Element.FIRE,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 5,
			"description": "Сап-дд и саппорт Пути Гармонии (Огненный) для команд Бонус-атак и Ленской. Накладывает статус «Особый гость», проводит совместные бонус-атаки, накапливает «Журчание волн», продвигает сильнейшего союзника и призывает существ на шкалу действий.",
		},
	]

static func get_character(id: String) -> Dictionary:
	for c in get_available_characters():
		if c.id == id:
			return c
	return {}

static func get_path_name(path: CombatConstants.Path) -> String:
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

static func get_path_icon(path: CombatConstants.Path) -> String:
	match path:
		CombatConstants.Path.ERUDITION: return "📖"
		CombatConstants.Path.HUNT: return "🏹"
		CombatConstants.Path.DESTRUCTION: return "⚔️"
		CombatConstants.Path.HARMONY: return "🎵"
		CombatConstants.Path.ABUNDANCE: return "💖"
		CombatConstants.Path.PRESERVATION: return "🛡️"
		CombatConstants.Path.NIHILITY: return "🌌"
		CombatConstants.Path.REMEMBRANCE: return "❄️"
		_: return "✦"

static func get_path_full_label(path: CombatConstants.Path) -> String:
	return "%s %s" % [get_path_icon(path), get_path_name(path)]

static func get_recommendation(char_id: String, type: String) -> String:
	match char_id:
		"sanguinia":
			match type:
				"allies": return "• [color=gold]Ленская[/color], [color=gold]Раймс • Восхождение[/color], [color=gold]Юлия Доцева[/color], [color=gold]Жоан[/color], [color=gold]Марина[/color]"
				"cones": return "• [color=cyan]Последнее лето[/color] (Сигнатурный)\n• [color=cyan]Я стану богом[/color], [color=cyan]Колыбельная[/color], [color=cyan]Я создам лучший мир[/color], [color=cyan]Коснись - и верни её в бодрствующий мир[/color]"
				"relics": return "• [color=lightgreen]Защитник цветения[/color] (Лучший)\n• [color=lightgreen]Исследователь отнятого будущего[/color] + [color=lightgreen]Штаб Восставших[/color] (Планарный)"
				"tip": return "💡 [i]Сангиния — превосходный саппорт для бонус-атакеров. Накладывайте Навыком E статус «Особый гость» на сильнейшего атакующего для проведения разрушительных совместных бонус-атак![/i]"
		"lenskaya_sky_guardian":
			match type:
				"allies": return "• [color=gold]Каори[/color], [color=gold]Даша[/color], [color=gold]Сара[/color], [color=gold]Валраморс[/color], [color=gold]Марина • Хранитель небес[/color]"
				"cones": return "• [color=cyan]Прощание перед пробуждением[/color] (Сигнатурный)\n• [color=cyan]Стрелы[/color], [color=cyan]Я не могу тебя убить[/color], [color=cyan]Нападение[/color]"
				"relics": return "• [color=lightgreen]Перебежчик тёмной стороны[/color] + [color=lightgreen]Восставший Краснодар[/color] (Планарный)\n• [color=lightgreen]Отпор бренного мира[/color] (Альтернатива)"
				"tip": return "💡 [i]Ленская • Хранитель небес сокрушает стойкость через статус «Враг Свечения» (1.5x стойкость) и конвертирует удары всей команды по пробитым врагам в колоссальный урон Суперпробития![/i]"
		"marina_sky_guardian":
			match type:
				"allies": return "• [color=gold]Раймс • Восхождение[/color], [color=gold]Милена[/color], [color=gold]Валраморс[/color], [color=gold]Сара[/color], [color=gold]Ленская • Хранитель небес[/color], [color=gold]Все (универсал)[/color]"
				"cones": return "• [color=cyan]Пусть прошлое остаётся позади[/color] (Сигнатурный)\n• [color=cyan]И вновь я один[/color], [color=cyan]Нити мнемы[/color], [color=cyan]Сгоревшая страница[/color]"
				"relics": return "• [color=lightgreen]Защитник цветения[/color] + [color=lightgreen]Штаб Восставших[/color] (Планарный)\n• [color=lightgreen]Потерянное в вечности Я[/color] (Альтернатива)"
				"tip": return "💡 [i]Марина • Хранитель небес призывает духа памяти «Эго» и раскрывает зону «Элизиум». Связывайте союзников узами Крит. шанса через Навык Q![/i]"
		"rimes_ascension":
			match type:
				"allies": return "• [color=gold]Марина • Хранитель небес[/color], [color=gold]Сангиния Ял[/color], [color=gold]Милена[/color], [color=gold]Сара[/color], [color=gold]Валраморс[/color]"
				"cones": return "• [color=cyan]И вновь я один[/color] (Сигнатурный)\n• [color=cyan]Пусть прошлое остаётся позади[/color], [color=cyan]Нити мнемы[/color]"
				"relics": return "• [color=lightgreen]Защитник цветения[/color] + [color=lightgreen]Штаб Восставших[/color] (Планарный)\n• [color=lightgreen]Истинный родоначальник хаоса[/color] (Альтернатива)"
				"tip": return "💡 [i]Раймс • Восхождение жертвует здоровьем отряда для накопления «Крещендо» и сокрушительных атак Духа Памяти «Лапы антиматерии». Весь его урон масштабируется от максимального HP![/i]"
				_: return ""
		_:
			return ""
	return ""

static func get_character_splash_path(char_id: String) -> String:
	match char_id:
		"sara": return "res://assets/characters/sara.jpg"
		"sara_admin": return "res://assets/characters/sara_admin.jpg"
		"isaac": return "res://assets/characters/isaac.jpg"
		"isaac_admin": return "res://assets/characters/isaac_admin.jpg"
		"rimes": return "res://assets/characters/rimes.jpg"
		_: return ""

static func has_character_splash(char_id: String) -> bool:
	return get_character_splash_path(char_id) != ""

static func get_character_splash(char_id: String) -> Texture2D:
	var path := get_character_splash_path(char_id)
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var global_p := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_p):
		var img := Image.new()
		if img.load(global_p) == OK:
			return ImageTexture.create_from_image(img)
	return null
