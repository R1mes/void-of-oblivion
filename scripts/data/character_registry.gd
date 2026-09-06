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
		},
		{
			"id": "isaac",
			"name": "Айзек",
			"element": CombatConstants.Element.WIND,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 4,
			"description": "Гениальный теоретик из Академии (Ветряной). Саппорт-баффер, способный продвигать ходы союзников на 100%, повышать их КУ на 100% и накладывать уязвимости.",
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
		},
		{
			"id": "sara_admin",
			"name": "Сара • Права администратора",
			"element": CombatConstants.Element.LIGHTNING,
			"path": CombatConstants.Path.HARMONY,
			"rarity": 5,
			"description": "Легендарный саппорт Консоли (Электрический). Разворачивает Среду разработки, разгоняет Бинарный урон от своей скорости и активирует протоколы команды.",
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
