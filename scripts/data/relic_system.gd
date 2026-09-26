class_name RelicSystem
extends RefCounted

## Центральный модуль системы Реликвий и Планарных украшений.
## Включает генерацию, расчет статов, роллы сабстатов, прокачку и данжи.

const SLOTS := {
	"head": "Голова",
	"hands": "Руки",
	"body": "Тело",
	"feet": "Ноги",
	"sphere": "Планарная сфера",
	"rope": "Соединительная вязь"
}

const CAVERN_SLOTS := ["head", "hands", "body", "feet"]
const PLANAR_SLOTS := ["sphere", "rope"]

const SET_NAMES := {
	# Пещерные сеты
	"symbiosis": "Жертва долгого симбиоза",
	"chaos": "Истинный родоначальник хаоса",
	"mortal_world": "Отпор бренного мира",
	"lava_fighter": "Боец огня и лавы",
	"light_gift": "Принявший дар света",
	"hope_beam": "Дающий луч надежды путник",
	"rapid_response": "Отряд быстрого реагирования",
	"biology_doctor": "Доктор биологических наук",
	"dying_planet": "Оборона умирающей планеты",
	"lost_self": "Потерянное в вечности «Я»",
	"galilean": "Галилеянин изолированного мира",
	"silhouette": "Прячущийся во тьме силуэт",
	"accepted_sin": "Принявший грех глава",
	"bereft_future": "Исследователь отнятого будущего",
	"damaged_strings": "След из повреждённых строк",
	"dying_stars_child": "Дитя умирающих звёзд",
	"dark_side_defector": "Перебежщик тёмной стороны",
	"bloom_defender": "Защитница цветущей земли",
	# Планарные сеты
	"detroit": "Сияющий Детройт",
	"lost_edge": "Лаборатория сгинувшего края",
	"japan_island": "Свободный остров Япония",
	"krasnodar": "Краснодар – сердце апокалипсиса",
	"other_side_universe": "Другая сторона вселенной",
	"irkutsk": "Погрязший в руинах Иркутск",
	"server_depths": "Сервер в глубинах реальности",
	"inverted_depths": "Потайные глубины Изнанки",
	"risen_krasnodar": "Восставший Краснодар",
	"ruins_hq": "Замурованный под руинами штаб"
}

const SET_DESCRIPTIONS := {
	"symbiosis": "2 части: +10% Ледяного урона.\n4 части: +12% ШПЭ и +15% урона по замороженным врагам.",
	"chaos": "2 части: +10% Квантового урона.\n4 части: Игнорирует 10% Защиты противников (20% при наличии Квантовой уязвимости).",
	"mortal_world": "2 части: +10% Физического урона.\n4 части: +15% Эффективности пробития уязвимости и +25% СА после победы над врагом.",
	"lava_fighter": "2 части: +10% Огненного урона.\n4 части: +12% Крит. шанса и +12% Огненного урона на 1 ход после Сверхспособности.",
	"light_gift": "2 части: +10% Электро урона.\n4 части: +20% СА при использовании Навыка на 1 ход.",
	"hope_beam": "2 части: +10% Мнимого урона.\n4 части: +10% Крит. шанса по врагам с дебаффами и +20% Крит. урона по обездвиженным.",
	"rapid_response": "2 части: +10% Ветряного урона.\n4 части: Продвигает действие владельца на 25% после Сверхспособности.",
	"biology_doctor": "2 части: +10% Исходящего исцеления.\n4 части: Восстанавливает 1 Очко навыков в начале боя.",
	"dying_planet": "2 части: +15% Защиты.\n4 части: +20% Прочности создаваемых щитов.",
	"lost_self": "2 части: +15% Силы Атаки.\n4 части: +6% Скорости и +15% урона Базовых атак.",
	"galilean": "2 части: +20% Урона Бонус-атак.\n4 части: При нанесении урона Бонус-атакой повышает СА на 6% (до 8 стаков).",
	"silhouette": "2 части: +16% Крит. Урона.\n4 части: Накладывает дебафф Маски Силуэта при критических ударах.",
	"accepted_sin": "2 части: +12% Макс. ХП.\n4 части: При изменении ХП владельца повышает Крит. шанс на 8% (до 2 раз).",
	"bereft_future": "2 части: +6% Скорости.\n4 части: Увеличивает Крит. урон всех союзников на 10% после действия владельца.",
	"damaged_strings": "2 части: Увеличивает Бинарный урон на 15%.\n4 части: После использования Сверхспособности Бинарный урон владельца игнорирует 20% защиты противника на 3 хода.",
	"dying_stars_child": "2 части: Увеличивает Крит. шанс владельца на 8%.\n4 части: Навыки Q и E владельца восстанавливают 5 ед. Зеро (если активна синергия Антиматерия 1). Если текущее Зеро > 40, увеличивает наносимый владельцем урон на 15%.",
	"dark_side_defector": "2 части: +16% Эффекта пробития.\n4 части: Если Эффект пробития владельца >= 130%, урон пробития игнорирует 10% Защиты цели. Если Эффект пробития >= 180%, урон Суперпробития игнорирует 15% Защиты цели.",
	"bloom_defender": "2 части: +12% Силы Атаки. Пока Дух Памяти владельца на поле боя, Скорость владельца повышается на 6%.\n4 части: Когда Дух Памяти владельца атакует, Крит. урон владельца и Духа Памяти увеличивается на 30% на 2 хода.",
	# Планарные
	"detroit": "2 части: +12% Силы Атаки. Если Скорость >= 120, дополнительно +12% СА.",
	"lost_edge": "2 части: +12% Макс. ХП. Если Скорость >= 120, повышает СА всех союзников на 8%.",
	"japan_island": "2 части: +15% Защиты. Если ШПЭ >= 50%, дополнительно +15% Защиты.",
	"krasnodar": "2 части: +8% Крит. шанса. Повышает урон Сверхспособности и Бонус-атак на 15% если Крит. шанс >= 50%.",
	"other_side_universe": "2 части: +12% Крит. шанса. Если Крит. шанс >= 70%, повышает урон Базовой атаки и Навыков на 20%.",
	"irkutsk": "2 части: Бонус-атака союзника дает стак Подвига (+5% урона бонус-атак, до 5). При 5 стаках КУ +25%.",
	"server_depths": "2 части: Увеличивает скорость на 6%. При использовании Навыка E скорость повышается на 12% на 2 хода. Если этот Навык E наносит Бинарный урон, поражённые противники получают на 10% больше Бинарного урона на 2 хода (складывается только от разных источников).",
	"inverted_depths": "2 части: Увеличивает силу атаки на 12%. Если владелец находится не в первом слоте (слот 0) и имеет общую фракцию с первым персонажем в отряде, увеличивает наносимый урон обоих персонажей на 10%.",
	"risen_krasnodar": "2 части: +16% Крит. Урона. Если у владельца на поле боя есть призванные существа или Дух Памяти, Крит. урон владельца повышается ещё на 32%.",
	"ruins_hq": "2 части: +16% Эффекта пробития. Если Скорость владельца >= 145, Эффект пробития повышается дополнительно на 20%."
}

const SET_2PC_DESCRIPTIONS := {
	"symbiosis": "+10% Ледяного урона",
	"chaos": "+10% Квантового урона",
	"mortal_world": "+10% Физического урона",
	"lava_fighter": "+10% Огненного урона",
	"light_gift": "+10% Электро урона",
	"hope_beam": "+10% Мнимого урона",
	"rapid_response": "+10% Ветряного урона",
	"biology_doctor": "+10% Исходящего исцеления",
	"dying_planet": "+15% Защиты",
	"lost_self": "+15% Силы Атаки",
	"galilean": "+20% Урона Бонус-атак",
	"silhouette": "+16% Крит. Урона",
	"accepted_sin": "+12% Макс. ХП",
	"bereft_future": "+6% Скорости",
	"damaged_strings": "+15% Бинарного урона",
	"dying_stars_child": "+8% Крит. шанса",
	"dark_side_defector": "+16% Эффекта пробития",
	"bloom_defender": "+12% Силы Атаки (+6% Скорости при активном Духе Памяти)",
	# Планарные
	"lost_edge": "+12% ХП. Дает +8% СА отряду если скорость >= 120 (суммируется)",
	"japan_island": "+15% Защиты (+15% если ШПЭ >= 50%)",
	"krasnodar": "+8% Крит. шанса (+15% ультимейту/бонус-атаке если КШ >= 50%)",
	"detroit": "+12% Силы Атаки (+12% если скорость >= 120)",
	"other_side_universe": "+12% Крит. шанса (+20% к Базовой/Q/E если КШ >= 70%)",
	"irkutsk": "+5-25% урона Бонус-атак за стаки Подвига, +25% КУ на 5 стаках",
	"server_depths": "+6% Скорости. Навык E дает +12% Скорости на 2 хода и +10% Бинарной уязвимости врагам при Бинарном уроне",
	"inverted_depths": "+12% Силы Атаки. Если не в 1-м слоте и фракция совпадает с первым союзником — урон обоих +10%",
	"risen_krasnodar": "+16% Крит. Урона (+32% при наличии призванных существ или Духа Памяти)",
	"ruins_hq": "+16% Эффекта пробития (+20% если Скорость >= 145)"
}

const SET_4PC_DESCRIPTIONS := {
	"symbiosis": "+12% ШПЭ и +15% урона по замороженным врагам",
	"chaos": "Игнорирует 10% Защиты противников (20% при наличии Квантовой уязвимости)",
	"mortal_world": "+15% Эффективности пробития уязвимости и +25% СА после победы над врагом",
	"lava_fighter": "+12% Крит. шанса и +12% Огненного урона на 1 ход после Сверхспособности",
	"light_gift": "+20% СА при использовании Навыка на 1 ход",
	"hope_beam": "+10% Крит. шанса по врагам с дебаффами и +20% Крит. урона по обездвиженным",
	"rapid_response": "Продвигает действие владельца на 25% после Сверхспособности",
	"biology_doctor": "Восстанавливает 1 Очко навыков в начале боя",
	"dying_planet": "+20% Прочности создаваемых щитов",
	"lost_self": "+6% Скорости и +15% урона Базовых атак",
	"galilean": "При нанесении урона Бонус-атакой повышает СА на 6% (до 8 стаков)",
	"silhouette": "Накладывает дебафф Маски Силуэта при критических ударах",
	"accepted_sin": "При изменении ХП владельца повышает Крит. шанс на 8% (до 2 раз)",
	"bereft_future": "Увеличивает Крит. урон всех союзников на 10% после действия владельца",
	"damaged_strings": "После Сверхспособности Бинарный урон игнорирует 20% защиты противника на 3 хода",
	"dying_stars_child": "Навыки Q и E дают +5 Зеро (при Антиматерии 1). Если Зеро > 40, наносимый урон +15%",
	"dark_side_defector": "При ЭП >= 130% урон пробития игнорирует 10% Защиты; при ЭП >= 180% урон Суперпробития игнорирует 15% Защиты",
	"bloom_defender": "Атака Духа Памяти дает +30% Крит. урона владельцу и Духу Памяти на 2 хода"
}

# Доступные основные характеристики по слотам
const MAIN_STATS_BY_SLOT := {
	"head": ["flat_hp"],
	"hands": ["flat_atk"],
	"body": ["hp_pct", "atk_pct", "def_pct", "ehr", "heal", "crit_dmg", "crit_rate"],
	"feet": ["hp_pct", "atk_pct", "def_pct", "speed"],
	"sphere": ["hp_pct", "atk_pct", "def_pct", "phys_dmg", "fire_dmg", "ice_dmg", "lightning_dmg", "wind_dmg", "quantum_dmg", "imaginary_dmg"],
	"rope": ["hp_pct", "atk_pct", "def_pct", "break_effect", "err"]
}

# Все доступные сабстаты (12 сабстатов)
const ALL_SUBSTATS := [
	"flat_hp", "flat_atk", "flat_def",
	"hp_pct", "atk_pct", "def_pct",
	"speed", "crit_rate", "crit_dmg",
	"ehr", "eff_res", "break_effect"
]

# Веса вероятности выпадения сабстатов (из официальной статистики распределения HSR)
const SUBSTAT_WEIGHTS := {
	"flat_hp": 978,
	"flat_atk": 1002,
	"flat_def": 1000,
	"hp_pct": 993,
	"atk_pct": 1028,
	"def_pct": 1007,
	"speed": 435,
	"crit_rate": 660,
	"crit_dmg": 633,
	"ehr": 821,
	"eff_res": 810,
	"break_effect": 830
}

# Возможные значения саброллов: [Low roll, Mid roll, High roll]
# 5★ заданы строго по таблице HSR:
#   Low = 0.8 * High, Mid = 0.9 * High, High = 1.0 * High
# 4★ = 0.8x от 5★, 3★ = 0.6x от 5★
const SUBSTAT_ROLL_TIERS := {
	"flat_hp": {
		5: [33.87, 38.104, 42.338],
		4: [27.096, 30.483, 33.87],
		3: [20.322, 22.862, 25.403]
	},
	"flat_atk": {
		5: [16.935, 19.052, 21.169],
		4: [13.548, 15.242, 16.935],
		3: [10.161, 11.431, 12.701]
	},
	"flat_def": {
		5: [16.935, 19.052, 21.169],
		4: [13.548, 15.242, 16.935],
		3: [10.161, 11.431, 12.701]
	},
	"hp_pct": {
		5: [0.03456, 0.03888, 0.0432],
		4: [0.02765, 0.03110, 0.03456],
		3: [0.02074, 0.02333, 0.02592]
	},
	"atk_pct": {
		5: [0.03456, 0.03888, 0.0432],
		4: [0.02765, 0.03110, 0.03456],
		3: [0.02074, 0.02333, 0.02592]
	},
	"def_pct": {
		5: [0.0432, 0.0486, 0.0540],
		4: [0.03456, 0.03888, 0.0432],
		3: [0.02592, 0.02916, 0.0324]
	},
	"speed": {
		5: [2.0, 2.3, 2.6],
		4: [1.6, 1.8, 2.0],
		3: [1.2, 1.4, 1.6]
	},
	"crit_rate": {
		5: [0.02592, 0.02916, 0.0324],
		4: [0.02074, 0.02333, 0.02592],
		3: [0.01555, 0.01750, 0.01944]
	},
	"crit_dmg": {
		5: [0.05184, 0.05832, 0.0648],
		4: [0.04147, 0.04666, 0.05184],
		3: [0.03110, 0.03499, 0.03888]
	},
	"ehr": {
		5: [0.03456, 0.03888, 0.0432],
		4: [0.02765, 0.03110, 0.03456],
		3: [0.02074, 0.02333, 0.02592]
	},
	"eff_res": {
		5: [0.03456, 0.03888, 0.0432],
		4: [0.02765, 0.03110, 0.03456],
		3: [0.02074, 0.02333, 0.02592]
	},
	"break_effect": {
		5: [0.05184, 0.05832, 0.0648],
		4: [0.04147, 0.04666, 0.05184],
		3: [0.03110, 0.03499, 0.03888]
	}
}

# Таблицы значений основных статов: [Базовое (ур. 0), Максимальное] для 3★, 4★, 5★
const MAIN_STAT_VALUES := {
	"flat_hp": {3: [50.0, 260.0], 4: [80.0, 440.0], 5: [112.0, 705.0]},
	"flat_atk": {3: [25.0, 130.0], 4: [40.0, 220.0], 5: [56.0, 352.0]},
	"hp_pct": {3: [0.041, 0.259], 4: [0.055, 0.345], 5: [0.069, 0.432]},
	"atk_pct": {3: [0.041, 0.259], 4: [0.055, 0.345], 5: [0.069, 0.432]},
	"def_pct": {3: [0.051, 0.324], 4: [0.069, 0.432], 5: [0.086, 0.540]},
	"ehr": {3: [0.041, 0.259], 4: [0.055, 0.345], 5: [0.069, 0.432]},
	"heal": {3: [0.033, 0.207], 4: [0.044, 0.276], 5: [0.055, 0.345]},
	"crit_rate": {3: [0.031, 0.194], 4: [0.041, 0.259], 5: [0.051, 0.324]},
	"crit_dmg": {3: [0.062, 0.388], 4: [0.082, 0.518], 5: [0.103, 0.648]},
	"speed": {3: [2.0, 15.0], 4: [3.0, 20.0], 5: [4.0, 25.0]},
	"break_effect": {3: [0.062, 0.388], 4: [0.082, 0.518], 5: [0.103, 0.648]},
	"err": {3: [0.018, 0.116], 4: [0.025, 0.155], 5: [0.031, 0.194]},
	"phys_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"fire_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"ice_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"lightning_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"wind_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"quantum_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]},
	"imaginary_dmg": {3: [0.037, 0.233], 4: [0.049, 0.311], 5: [0.062, 0.388]}
}

# Шаги прокачки/ролла сабстатов по умолчанию (средний ролл Mid)
const SUBSTAT_STEP_VALUES := {
	"flat_hp": {3: 22.86, 4: 30.48, 5: 38.104},
	"flat_atk": {3: 11.43, 4: 15.24, 5: 19.052},
	"flat_def": {3: 11.43, 4: 15.24, 5: 19.052},
	"hp_pct": {3: 0.0233, 4: 0.0311, 5: 0.03888},
	"atk_pct": {3: 0.0233, 4: 0.0311, 5: 0.03888},
	"def_pct": {3: 0.0292, 4: 0.0389, 5: 0.0486},
	"speed": {3: 1.4, 4: 1.8, 5: 2.3},
	"crit_rate": {3: 0.0175, 4: 0.0233, 5: 0.02916},
	"crit_dmg": {3: 0.0350, 4: 0.0467, 5: 0.05832},
	"ehr": {3: 0.0233, 4: 0.0311, 5: 0.03888},
	"eff_res": {3: 0.0233, 4: 0.0311, 5: 0.03888},
	"break_effect": {3: 0.0350, 4: 0.0467, 5: 0.05832}
}

# Максимальный уровень реликвии по редкости
const MAX_LEVELS := {
	3: 9,
	4: 12,
	5: 15
}

# Опыт для каждого уровня (от уровня L-1 к L)
const EXP_PER_LEVEL: Array[int] = [
	0,    # ур. 0
	300,  # ур. 1
	400,  # ур. 2
	550,  # ур. 3
	750,  # ур. 4
	1000, # ур. 5
	1300, # ур. 6
	1700, # ур. 7
	2200, # ур. 8
	2800, # ур. 9
	3500, # ур. 10
	4300, # ур. 11
	5200, # ур. 12
	6300, # ур. 13
	7600, # ур. 14
	9000  # ур. 15
]

# Базовый опыт при скармливании
const FEED_BASE_EXP := {
	3: 500,
	4: 1000,
	5: 1500
}

# Опыт за один Осколок реликвии
const SHARD_EXP_VALUE: int = 100

# Данжи пещерных реликвий (7 штук)
const CAVERN_DUNGEONS := [
	{
		"id": "dungeon_academy",
		"name": "Академия",
		"icon": "🏛",
		"sets": ["symbiosis", "chaos"],
		"desc": "Жертва долгого симбиоза и Истинный родоначальник хаоса"
	},
	{
		"id": "dungeon_hq",
		"name": "Штаб",
		"icon": "🏢",
		"sets": ["mortal_world", "lava_fighter"],
		"desc": "Отпор бренного мира и Боец огня и лавы"
	},
	{
		"id": "dungeon_kitchens",
		"name": "Район «TheКухни»",
		"icon": "🍳",
		"sets": ["light_gift", "hope_beam"],
		"desc": "Принявший дар света и Дающий луч надежды путник"
	},
	{
		"id": "dungeon_dam",
		"name": "Дмитриевская дамба",
		"icon": "🌊",
		"sets": ["rapid_response", "biology_doctor"],
		"desc": "Отряд быстрого реагирования и Доктор биологических наук"
	},
	{
		"id": "dungeon_dawn_chaos",
		"name": "Штаб «Рассвета хаоса»",
		"icon": "⚔",
		"sets": ["dying_planet", "lost_self"],
		"desc": "Оборона умирающей планеты и Потерянное в вечности «Я»"
	},
	{
		"id": "dungeon_as_house",
		"name": "Дом А.С.",
		"icon": "🏠",
		"sets": ["galilean", "silhouette"],
		"desc": "Галилеянин изолированного мира и Прячущийся во тьме силуэт"
	},
	{
		"id": "dungeon_slums_apt",
		"name": "Квартира посреди Трущоб",
		"icon": "🏚",
		"sets": ["accepted_sin", "bereft_future"],
		"desc": "Принявший грех глава и Исследователь отнятого будущего"
	},
	{
		"id": "dungeon_detroit_airfield",
		"name": "Аэродром Детройта",
		"icon": "🛫",
		"sets": ["damaged_strings", "dying_stars_child"],
		"desc": "След из повреждённых строк и Дитя умирающих звёзд"
	},
	{
		"id": "dungeon_rebellion_ruins",
		"name": "Руины восстания",
		"icon": "🏛",
		"sets": ["dark_side_defector", "bloom_defender"],
		"desc": "Перебежщик тёмной стороны и Защитница цветущей земли"
	}
]

# Данжи планарных украшений (5 штук)
const PLANAR_DUNGEONS := [
	{
		"id": "planar_empyreans",
		"name": "Эмпирейцы",
		"icon": "🌌",
		"sets": ["detroit", "lost_edge"],
		"desc": "Сияющий Детройт и Лаборатория сгинувшего края"
	},
	{
		"id": "planar_slums",
		"name": "Трущобы",
		"icon": "🌆",
		"sets": ["japan_island", "krasnodar"],
		"desc": "Свободный остров Япония и Краснодар – сердце апокалипсиса"
	},
	{
		"id": "planar_detroit",
		"name": "Детройт",
		"icon": "🏙",
		"sets": ["other_side_universe", "irkutsk"],
		"desc": "Другая сторона вселенной и Погрязший в руинах Иркутск"
	},
	{
		"id": "planar_server",
		"name": "Сервер",
		"icon": "🖥",
		"sets": ["server_depths", "inverted_depths"],
		"desc": "Сервер в глубинах реальности и Потайные глубины Изнанки"
	},
	{
		"id": "planar_rebellion_hq",
		"name": "Оплот восстания",
		"icon": "🏰",
		"sets": ["risen_krasnodar", "ruins_hq"],
		"desc": "Восставший Краснодар и Замурованный под руинами штаб"
	}
]

# --- ГЕНЕРАЦИЯ РЕЛИКВИЙ ---

static func generate_relic(set_id: String, slot: String, rarity: int) -> Dictionary:
	rarity = clampi(rarity, 3, 5)
	var uid := "relic_%d_%d" % [int(Time.get_unix_time_from_system() * 1000.0), randi() % 100000]
	
	# Выбор основного стата из разрешенных для слота
	var allowed_mains: Array = MAIN_STATS_BY_SLOT.get(slot, ["hp_pct"])
	var main_stat_id: String = String(allowed_mains[randi() % allowed_mains.size()])
	var main_stat_val: float = calculate_main_stat_value(main_stat_id, rarity, 0)
	
	# Определение стартового количества сабстатов
	var init_sub_count: int = 1
	if rarity == 5:
		init_sub_count = 4 if (randf() < 0.30) else 3
	elif rarity == 4:
		init_sub_count = 3 if (randf() < 0.20) else 2
	else:
		init_sub_count = 2 if (randf() < 0.15) else 1
		
	var substats: Array[Dictionary] = []
	var available_subs := get_available_substats(main_stat_id, [])
	
	for i in range(init_sub_count):
		if available_subs.is_empty():
			break
		var sub_id := pick_weighted_substat(available_subs)
		var picked_idx := available_subs.find(sub_id)
		if picked_idx >= 0:
			available_subs.remove_at(picked_idx)
		
		var step_val: float = roll_substat_step(sub_id, rarity)
		substats.append({
			"type": sub_id,
			"value": step_val,
			"rolls": 1
		})
		
	return {
		"uid": uid,
		"set_id": set_id,
		"slot": slot,
		"rarity": rarity,
		"level": 0,
		"exp": 0,
		"invested_exp": 0,
		"main_stat": {
			"type": main_stat_id,
			"value": main_stat_val
		},
		"substats": substats,
		"equipped_to": ""
	}

# Список доступных сабстатов, исключая основной стат и уже имеющиеся
static func get_available_substats(main_stat_id: String, current_subs: Array) -> Array[String]:
	var current_sub_ids: Array[String] = []
	for s in current_subs:
		if s is Dictionary and s.has("type"):
			current_sub_ids.append(String(s["type"]))
			
	var result: Array[String] = []
	for sub_id in ALL_SUBSTATS:
		if sub_id == main_stat_id:
			continue # Сабстат не может быть таким же как мейнстат!
		if sub_id in current_sub_ids:
			continue # Сабстаты не могут повторяться!
		result.append(sub_id)
	return result

# Взвешенный выбор сабстата на основе распределения HSR
static func pick_weighted_substat(available_subs: Array[String]) -> String:
	if available_subs.is_empty():
		return ""
	var total_weight := 0
	for sub_id in available_subs:
		total_weight += int(SUBSTAT_WEIGHTS.get(sub_id, 1000))
	if total_weight <= 0:
		return available_subs[randi() % available_subs.size()]
	
	var r := randi() % total_weight
	var cumulative := 0
	for sub_id in available_subs:
		cumulative += int(SUBSTAT_WEIGHTS.get(sub_id, 1000))
		if r < cumulative:
			return sub_id
	return available_subs[available_subs.size() - 1]

# Случайный выбор одного из трех значений ролла (Low, Mid, High)
static func roll_substat_step(sub_id: String, rarity: int) -> float:
	var tiers_by_rarity: Dictionary = SUBSTAT_ROLL_TIERS.get(sub_id, {})
	var tier_list: Array = tiers_by_rarity.get(rarity, [1.0, 1.0, 1.0])
	return float(tier_list[randi() % tier_list.size()])

# Шаг значения для сабстата в зависимости от редкости (Mid roll)
static func get_substat_step(sub_id: String, rarity: int) -> float:
	var tiers_by_rarity: Dictionary = SUBSTAT_ROLL_TIERS.get(sub_id, {})
	var tier_list: Array = tiers_by_rarity.get(rarity, [1.0, 1.0, 1.0])
	return float(tier_list[1])

# Расчет значения основного стата по редкости и уровню
static func calculate_main_stat_value(stat_id: String, rarity: int, level: int) -> float:
	var table: Dictionary = MAIN_STAT_VALUES.get(stat_id, {})
	if not table.has(rarity):
		return 1.0
	var range_arr: Array = table[rarity]
	var base_val: float = float(range_arr[0])
	var max_val: float = float(range_arr[1])
	var max_lvl: int = MAX_LEVELS.get(rarity, 15)
	var clamped_lvl := clampi(level, 0, max_lvl)
	return base_val + (max_val - base_val) * (float(clamped_lvl) / float(max_lvl))

# --- ПРОКАЧКА И РОЛЛЫ САБСТАТОВ ---

# Повышение сабстатов на уровнях 3, 6, 9, 12, 15
static func roll_substat_upgrade(relic: Dictionary) -> void:
	var rarity: int = int(relic.get("rarity", 4))
	var main_stat_id: String = String(relic.get("main_stat", {}).get("type", ""))
	var subs: Array = relic.get("substats", [])
	
	if subs.size() < 4:
		# Меньше 4 сабстатов: добавляем новый уникальный сабстат взвешенно
		var avail := get_available_substats(main_stat_id, subs)
		if not avail.is_empty():
			var new_sub_id := pick_weighted_substat(avail)
			var step_val: float = roll_substat_step(new_sub_id, rarity)
			subs.append({
				"type": new_sub_id,
				"value": step_val,
				"rolls": 1
			})
	else:
		# Ровно 4 сабстата: случайно усиливаем один из них
		var roll_idx := randi() % subs.size()
		var target_sub: Dictionary = subs[roll_idx]
		var sub_id: String = String(target_sub.get("type", ""))
		var step_val: float = roll_substat_step(sub_id, rarity)
		target_sub["value"] = float(target_sub.get("value", 0.0)) + step_val
		target_sub["rolls"] = int(target_sub.get("rolls", 1)) + 1
		
	relic["substats"] = subs

# Добавление опыта и проверка повышения уровней с роллами
static func add_exp(relic: Dictionary, exp_to_add: int) -> Dictionary:
	var rarity: int = int(relic.get("rarity", 4))
	var max_lvl: int = MAX_LEVELS.get(rarity, 15)
	var current_lvl: int = int(relic.get("level", 0))
	var current_exp: int = int(relic.get("exp", 0))
	var invested_exp: int = int(relic.get("invested_exp", 0))
	
	if current_lvl >= max_lvl:
		var excess_already: int = exp_to_add
		var shards_already: int = int(ceil(float(excess_already) / float(SHARD_EXP_VALUE))) if excess_already > 0 else 0
		return {
			"levels_gained": 0,
			"rolls_triggered": 0,
			"excess_exp": excess_already,
			"shards_refunded": shards_already
		}
		
	current_exp += exp_to_add
	invested_exp += exp_to_add
	
	var initial_level := current_lvl
	var rolls_triggered := 0
	
	while current_lvl < max_lvl:
		var needed_exp: int = EXP_PER_LEVEL[current_lvl + 1]
		if current_exp >= needed_exp:
			current_exp -= needed_exp
			current_lvl += 1
			
			# Проверка порогов ролла сабстатов (3, 6, 9, 12, 15)
			if current_lvl in [3, 6, 9, 12, 15]:
				roll_substat_upgrade(relic)
				rolls_triggered += 1
		else:
			break
			
	var excess_exp: int = 0
	var shards_refunded: int = 0
	if current_lvl >= max_lvl:
		excess_exp = current_exp
		invested_exp -= excess_exp # Не считаем возвращенный опыт как инвестированный
		current_exp = 0 # Срезаем лишний опыт на капе
		if excess_exp > 0:
			shards_refunded = int(ceil(float(excess_exp) / float(SHARD_EXP_VALUE)))
		
	relic["level"] = current_lvl
	relic["exp"] = current_exp
	relic["invested_exp"] = invested_exp
	
	# Обновляем значение основного стата
	var main_stat_dict: Dictionary = relic.get("main_stat", {})
	var main_stat_id: String = String(main_stat_dict.get("type", ""))
	main_stat_dict["value"] = calculate_main_stat_value(main_stat_id, rarity, current_lvl)
	relic["main_stat"] = main_stat_dict
	
	return {
		"levels_gained": current_lvl - initial_level,
		"rolls_triggered": rolls_triggered,
		"excess_exp": excess_exp,
		"shards_refunded": shards_refunded
	}

# Опыт, который дает реликвия при скармливании
static func get_relic_feed_exp(relic: Dictionary) -> int:
	var rarity: int = int(relic.get("rarity", 3))
	var base_exp: int = int(FEED_BASE_EXP.get(rarity, 500))
	var invested: int = int(relic.get("invested_exp", 0))
	return base_exp + int(float(invested) * 0.80)

# --- ГЕНЕРАЦИЯ ДРОПА В ДАНЖАХ ---

static func generate_dungeon_drops(dungeon_id: String, player_level: int) -> Array[Dictionary]:
	var dungeon_def: Dictionary = {}
	for d in CAVERN_DUNGEONS:
		if d.id == dungeon_id:
			dungeon_def = d
			break
	if dungeon_def.is_empty():
		for d in PLANAR_DUNGEONS:
			if d.id == dungeon_id:
				dungeon_def = d
				break
				
	if dungeon_def.is_empty():
		return []
		
	var is_cavern := dungeon_id.begins_with("dungeon_")
	var possible_slots: Array = CAVERN_SLOTS if is_cavern else PLANAR_SLOTS
	var sets: Array = dungeon_def.get("sets", [])
	
	var drops: Array[Dictionary] = []
	
	# Дроп по правилам ТЗ (удвоенные в 2 раза награды):
	# - до 15 уровня: только 4★ (и 3★) реликвии (6 шт. 4★, 10 шт. 3★)
	# - с 15 уровня: 8 шт. 4★ реликвий, остальные 3★ (8 шт. 4★, 8 шт. 3★)
	# - с 25 уровня: 4 шт. 5★ реликвий, 8 шт. 4★ реликвий, остальные 3★ (4 шт. 5★, 8 шт. 4★, 6 шт. 3★)
	var count_5star := 0
	var count_4star := 0
	var count_3star := 0
	
	if player_level < 15:
		count_5star = 0
		count_4star = 6
		count_3star = 10
	elif player_level < 25:
		count_5star = 0
		count_4star = 8
		count_3star = 8
	else:
		count_5star = 4
		count_4star = 8
		count_3star = 6
		
	# Генерируем 5★
	for i in count_5star:
		var picked_set: String = sets[randi() % sets.size()]
		var picked_slot: String = possible_slots[randi() % possible_slots.size()]
		drops.append(generate_relic(picked_set, picked_slot, 5))
		
	# Генерируем 4★
	for i in count_4star:
		var picked_set: String = sets[randi() % sets.size()]
		var picked_slot: String = possible_slots[randi() % possible_slots.size()]
		drops.append(generate_relic(picked_set, picked_slot, 4))
		
	# Генерируем 3★
	for i in count_3star:
		var picked_set: String = sets[randi() % sets.size()]
		var picked_slot: String = possible_slots[randi() % possible_slots.size()]
		drops.append(generate_relic(picked_set, picked_slot, 3))
		
	return drops

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ФОРМАТИРОВАНИЯ ---

static func get_slot_name(slot: String) -> String:
	return SLOTS.get(slot, slot)

static func get_slot_icon(slot: String) -> String:
	match slot:
		"head": return "👑"
		"hands": return "🧤"
		"body": return "🦺"
		"feet": return "👢"
		"sphere": return "🔮"
		"rope": return "🪢"
		_: return "🛡"

static func get_set_name(set_id: String) -> String:
	return SET_NAMES.get(set_id, set_id)

static func get_set_desc(set_id: String) -> String:
	return SET_DESCRIPTIONS.get(set_id, "")

static func get_set_2pc_desc(set_id: String) -> String:
	return SET_2PC_DESCRIPTIONS.get(set_id, "")

static func get_set_4pc_desc(set_id: String) -> String:
	return SET_4PC_DESCRIPTIONS.get(set_id, "")

static func format_stat_name(stat_id: String) -> String:
	match stat_id:
		"flat_hp": return "ХП"
		"flat_atk": return "Сила Атаки"
		"flat_def": return "Защита"
		"hp_pct": return "ХП%"
		"atk_pct": return "Сила Атаки%"
		"def_pct": return "Защита%"
		"ehr": return "Шанс попадания эффектов"
		"eff_res": return "Сопротивление эффектам"
		"heal": return "Исходящее исцеление"
		"crit_rate": return "Крит. шанс"
		"crit_dmg": return "Крит. урон"
		"speed": return "Скорость"
		"break_effect": return "Эффект пробития"
		"err": return "Восст. энергии"
		"phys_dmg": return "Физ. урон"
		"fire_dmg": return "Огненный урон"
		"ice_dmg": return "Ледяной урон"
		"lightning_dmg": return "Электро урон"
		"wind_dmg": return "Ветряной урон"
		"quantum_dmg": return "Квантовый урон"
		"imaginary_dmg": return "Мнимый урон"
		_: return stat_id

static func format_stat_value(stat_id: String, val: float) -> String:
	match stat_id:
		"flat_hp", "flat_atk", "flat_def":
			return "+%d" % int(round(val))
		"speed":
			return "+%.1f" % val if (absf(val - round(val)) > 0.01) else "+%d" % int(round(val))
		_:
			return "+%.1f%%" % (val * 100.0)

static func get_rarity_color(rarity: int) -> Color:
	match rarity:
		5: return Color(1.0, 0.80, 0.20) # Золотой
		4: return Color(0.75, 0.40, 0.95) # Фиолетовый
		3: return Color(0.30, 0.65, 1.00) # Синий
		_: return Color.WHITE

static func get_dungeon_info(dungeon_id: String) -> Dictionary:
	match dungeon_id:
		"dungeon_academy":
			return {
				"name": "Академия",
				"icon": "🏛",
				"anomaly": "«Симбиоз Нуля и Хаоса»: Ледяной и Квантовый урон +30%, урон по замороженным и пробитым целям +40%!",
				"enemies": "Элитный Страж, Солдат Пустоты x2",
				"rewards": "Жертва долгого симбиоза, Истинный родоначальник хаоса"
			}
		"dungeon_hq":
			return {
				"name": "Штаб",
				"icon": "🏢",
				"anomaly": "«Лавовый отпор»: Огненный и Физ. урон +30%, пробитие уязвимости накладывает Горение (100% СА) на 2 хода!",
				"enemies": "Бронированный Рыцарь, Солдат Пустоты x2",
				"rewards": "Отпор бренного мира, Боец огня и лавы"
			}
		"dungeon_kitchens":
			return {
				"name": "Район «TheКухни»",
				"icon": "🍳",
				"anomaly": "«Световой резонанс»: Электро и Мнимый урон +30%, Навыки лечат 12% макс. ХП и дают +20% СА на 1 ход!",
				"enemies": "Элитный Страж, Заражённый x2",
				"rewards": "Принявший дар света, Дающий луч надежды путник"
			}
		"dungeon_dam":
			return {
				"name": "Дмитриевская дамба",
				"icon": "🌊",
				"anomaly": "«Стремительный поток»: Ветер +30% урона, Ульты продвигают ход на 30%, лечение дает +20% урона на 2 хода!",
				"enemies": "Элитный Страж, Заражённый",
				"rewards": "Отряд быстрого реагирования, Доктор биологических наук"
			}
		"dungeon_dawn_chaos":
			return {
				"name": "Штаб «Рассвета хаоса»",
				"icon": "⚔",
				"anomaly": "«Эгида и Тлен»: Персонажи под щитами получают +30% СА, каждый DoT на враге снижает защиту на 5% (до 30%)!",
				"enemies": "Бронированный Рыцарь, Заражённый x2",
				"rewards": "Оборона умирающей планеты, Потерянное в вечности «Я»"
			}
		"dungeon_as_house":
			return {
				"name": "Дом А.С.",
				"icon": "🏠",
				"anomaly": "«Театр Силуэтов»: Урон бонус-атак +50%, Крит. урон отряда +25%!",
				"enemies": "Элитный Страж, Солдат Пустоты x2",
				"rewards": "Галилеянин изолированного мира, Прячущийся во тьме силуэт"
			}
		"dungeon_slums_apt":
			return {
				"name": "Квартира посреди Трущоб",
				"icon": "🏚",
				"anomaly": "«Принятие Греха»: Смена ХП союзника (потеря от ударов/самоповреждения Мусиенко или лечение) дает +15% КШ и +30% урона на 2 хода (до 2 стаков, суммарно +30% КШ и +60% урона)!",
				"enemies": "Бронированный Рыцарь, Заражённый x2",
				"rewards": "Принявший грех глава, Исследователь отнятого будущего"
			}
		"planar_empyreans":
			return {
				"name": "Эмпирейцы",
				"icon": "🌌",
				"anomaly": "«Скоростной резонанс»: Скорость команды +20 ед., при Скорости >= 120 урон +35%!",
				"enemies": "Повелитель Пустоты (Босс), Элитный Страж",
				"rewards": "Сияющий Детройт, Лаборатория сгинувшего края"
			}
		"planar_slums":
			return {
				"name": "Трущобы",
				"icon": "🌆",
				"anomaly": "«Сердце Апокалипсиса»: Урон Сверхспособностей и Бонус-атак +40%!",
				"enemies": "Орто Мутант (Босс), Бронированный Рыцарь",
				"rewards": "Свободный остров Япония, Краснодар – сердце апокалипсиса"
			}
		"planar_detroit":
			return {
				"name": "Детройт",
				"icon": "🏙",
				"anomaly": "«Другая сторона»: Эффект пробития +50%, поверженный враг продвигает отряд на 25% и восстанавливает 20 энергии!",
				"enemies": "Силуэт в маске (Босс), Серверный Вирус (Босс)",
				"rewards": "Другая сторона вселенной, Погрязший в руинах Иркутск"
			}
		"dungeon_detroit_airfield":
			return {
				"name": "Аэродром Детройта",
				"icon": "🛫",
				"anomaly": "«Бинарный резонанс»: Бинарный урон отряда +30%, восстановление Зеро увеличивает наносимый урон на +20%!",
				"enemies": "Серверный Вирус (Босс), Элитный Страж",
				"rewards": "След из повреждённых строк, Дитя умирающих звёзд"
			}
		"planar_server":
			return {
				"name": "Сервер",
				"icon": "🖥",
				"anomaly": "«Глубины Системы»: Скорость +15%, совпадение фракций союзников с лидером дает +25% урона!",
				"enemies": "Орто Мутант (Босс), Повелитель Пустоты (Босс)",
				"rewards": "Сервер в глубинах реальности, Потайные глубины Изнанки"
			}
		"dungeon_rebellion_ruins":
			return {
				"name": "Руины восстания",
				"icon": "🏛",
				"anomaly": "«Эхо мятежа»: Эффект пробития отряда +40%. Атаки Духов Памяти истощают стойкость на 100% эффективнее. Пробитие уязвимости и Суперпробитие восстанавливают 10 ед. энергии и продвигают действие атакующего на 15%!",
				"enemies": "Восставший (Элитный), Раб Антиматерии x2",
				"rewards": "Перебежщик тёмной стороны, Защитница цветущей земли"
			}
		"planar_rebellion_hq":
			return {
				"name": "Оплот восстания",
				"icon": "🏰",
				"anomaly": "«Оплот свободы»: Крит. урон отряда +30%. Пока на поле боя активен Дух Памяти или призванное существо, отряд игнорирует 20% защиты врагов. Пробитие уязвимости наносит дополнительно 100% базового урона пробития!",
				"enemies": "Кайл • Лидер восстания (Босс), Восставший (Элитный)",
				"rewards": "Восставший Краснодар, Замурованный под руинами штаб"
			}
		_:
			return {
				"name": "Подземелье",
				"icon": "⚔",
				"anomaly": "Особые условия боя",
				"enemies": "Стражи подземелья",
				"rewards": "Комплекты реликвий"
			}

# --- ПРОГРЕССИЯ РАЗБЛОКИРОВКИ СЛОТОВ И ДАНЖЕЙ ---

static func is_slot_unlocked(slot: String, level_progress: int) -> bool:
	match slot:
		"head", "hands":
			return level_progress >= 5
		"body", "feet":
			return level_progress >= 8
		"sphere", "rope":
			return level_progress >= 10
		_:
			return false

static func get_slot_unlock_level(slot: String) -> int:
	match slot:
		"head", "hands": return 5
		"body", "feet": return 8
		"sphere", "rope": return 10
		_: return 5

static func is_dungeon_unlocked(dungeon_id: String, level_progress: int) -> bool:
	if dungeon_id == "dungeon_academy" or dungeon_id == "academy":
		return level_progress >= 5
	elif dungeon_id.begins_with("dungeon_") or dungeon_id in ["hq", "kitchens", "dam", "slums_apt", "cemetery", "snow_ruins"]:
		return level_progress >= 8
	elif dungeon_id.begins_with("planar_") or dungeon_id in ["detroit", "station", "garden"]:
		return level_progress >= 10
	return false

static func get_dungeon_unlock_level(dungeon_id: String) -> int:
	if dungeon_id == "dungeon_academy" or dungeon_id == "academy":
		return 5
	elif dungeon_id.begins_with("dungeon_") or dungeon_id in ["hq", "kitchens", "dam", "slums_apt", "cemetery", "snow_ruins"]:
		return 8
	elif dungeon_id.begins_with("planar_") or dungeon_id in ["detroit", "station", "garden"]:
		return 10
	return 5

# --- УНИЧТОЖЕНИЕ (РАЗБОР) РЕЛИКВИЙ НА ОСКОЛКИ ---

static func calculate_dismantle_shards(relic: Dictionary) -> int:
	var base_exp: int = get_relic_feed_exp(relic)
	return maxi(1, ceili(float(base_exp) / float(SHARD_EXP_VALUE)))

static func dismantle_relic(uid: String) -> int:
	var r := TeamConfig.get_relic(uid)
	if r.is_empty():
		return 0
	if not String(r.get("equipped_to", "")).is_empty():
		return 0 # Надетые реликвии нельзя уничтожать
	var shards := calculate_dismantle_shards(r)
	TeamConfig.remove_relic(uid)
	TeamConfig.add_relic_shards(shards)
	TeamConfig.save_game()
	return shards

# --- ГАРАНТИРОВАННЫЙ НАБОР ДЛЯ ОБУЧЕНИЯ (ВИКА) ---

static func generate_tutorial_drops() -> Array[Dictionary]:
	var drops: Array[Dictionary] = []

	# 1. 4★ Голова сета «chaos» (Истинный родоначальник хаоса)
	var head := generate_relic("chaos", "head", 4)
	head["main_stat"] = {"type": "flat_hp", "value": calculate_main_stat_value("flat_hp", 4, 0)}
	head["substats"] = [
		{"type": "crit_rate", "value": 0.024, "rolls": 1},
		{"type": "crit_dmg", "value": 0.048, "rolls": 1},
		{"type": "hp_pct", "value": 0.034, "rolls": 1}
	]
	drops.append(head)

	# 2. 4★ Руки сета «chaos» (Истинный родоначальник хаоса)
	var hands := generate_relic("chaos", "hands", 4)
	hands["main_stat"] = {"type": "flat_atk", "value": calculate_main_stat_value("flat_atk", 4, 0)}
	hands["substats"] = [
		{"type": "crit_rate", "value": 0.024, "rolls": 1},
		{"type": "atk_pct", "value": 0.034, "rolls": 1},
		{"type": "hp_pct", "value": 0.034, "rolls": 1}
	]
	drops.append(hands)

	# 3. Дополнительные 3★ реликвии на корм и разбор
	for i in range(4):
		var f_slot = ["head", "hands"][i % 2]
		var f_relic = generate_relic("symbiosis", f_slot, 3)
		drops.append(f_relic)

	return drops
