extends Control

const LenskayaAntimatterAbilities = preload("res://scripts/characters/lenskaya_antimatter.gd")
const VelzebulAbilities = preload("res://scripts/characters/velzebul.gd")
const MarinaSkyGuardianAbilities = preload("res://scripts/characters/marina_sky_guardian.gd")
const LenskayaSkyGuardianAbilities = preload("res://scripts/characters/lenskaya_sky_guardian.gd")
const RimesAscensionAbilities = preload("res://scripts/characters/rimes_ascension.gd")
const SanguiniaAbilities = preload("res://scripts/characters/sanguinia.gd")
const MemoryHallManager = preload("res://scripts/combat/memory_hall_manager.gd")

# Цены персонажей в магазине
const SHOP_PRICES := {
	"marina": 1850,
	"pusenkov": 1850,
	"milena": 1850,
	"jeff": 1850,
	"sara": 480,
	"arseniy": 480,
	"kaori": 480,
	"dasha": 480,
	"danill": 480,
	"naama": 480,
	"isaac": 480,
	"keloist": 480,
	"joan": 480,
	"arseniy_admin": 480,
	"dasha_admin": 480
}

# Полная база описаний Эйдолонов (E1-E6)
const EIDOLON_DESCRIPTIONS := {
	"marina": {
		"E1": "Подавление теперь считается периодическим уроном (DoT) и складывается до 5 раз. Каждый стак наносит 50% СА Марины в ход врага.",
		"E2": "Сверхспособность наносит на 80% больше урона Элитным противникам.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "За каждый стак Подавления на врагах Скорость Марины повышается на 2 ед. (макс. +30).",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Навык теперь также накладывает Подавление, а его скейлинг от СА увеличен на 50%."
	},
	"vika": {
		"E1": "Срабатывание таланта восстанавливает Вике 40 единиц энергии.",
		"E2": "Использование Сверхспособности повышает Крит. шанс Вики на 30% на 2 хода.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Урон Сверхспособности Вики увеличивается на 30%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Состояние «Пробуждение» больше не уменьшает наносимый Викой урон. Вместо этого наносимый урон в состоянии «Пробуждение» увеличен на 20%."
	},
	"pusenkov": {
		"E1": "Конвертация Крит. шанса из Следа 2 увеличивается до 2×.",
		"E2": "Статус «Живым или мёртвым» дополнительно увеличивает получаемый врагом Крит. урон на 20%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Усиленная базовая атака Таланта имеет 40% шанс нанести тройной урон.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Сверхспособность больше не тратит Очки навыков, а урон при снятии статуса увеличен на 140%."
	},
	"sara": {
		"E1": "Базовая атака восстанавливает Саре 10% от её Макс. ХП.",
		"E2": "Статус «Заплатка» дополнительно повышает Сопротивление эффектам союзников на 15%, а входящее исцеление — на 20%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Один раз за бой Сара может воскресить павшего союзника.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "При завершении Сверхспособности снимает все дебаффы со всех союзников."
	},
	"arseniy": {
		"E1": "Когда союзник побеждает врага с «Тёмной печатью», его действие продвигается на 30%.",
		"E2": "Использование стандартного Навыка Q не тратит Очки навыков.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Использование Навыка E снимает все дебаффы с Арсения.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Сверхспособность дополнительно повышает Крит. урон всех союзников на 30% от Крит. урона Арсения."
	},
	"kaori": {
		"E1": "Усиленная базовая атака снимает на 10% больше Стойкости.",
		"E2": "Эффект пробития повышается на 20% в состоянии «Концентрация слабости».",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Если единственный враг на поле — Элитный, Каори накладывает на него Физическую уязвимость на 3 хода.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Усиленная базовая атака теперь восстанавливает 1 Очко навыков."
	},
	"dasha": {
		"E1": "Использование Навыка E повышает Силу атаки Даши на 20% на 3 хода.",
		"E2": "Если в отряде нет персонажа Изобилия, Бонус-атака восстанавливает Даше ХП равное (5% от ЭП)% от её Макс. ХП.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "За каждого павшего союзника Защита Даши повышается на 30%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Бонус-атака игнорирует 20% Защиты врагов. Если цель одна, наносит урон так, словно врагов 5 (урон остальных 4 перенаправляется в одну цель)."
	},
	"danill": {
		"E1": "Базовая атака дополнительно наносит урон в размере 30% от Защиты Данилла.",
		"E2": "Щит от Сверхспособности Данилла становится на 20% прочнее.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "При пробитии уязвимости Элитного врага союзником, Данилл накладывает на этого союзника Щит аналогичный Навыку Q.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Когда ХП союзника опускается до 30% и ниже, дает ему Щит прочностью (20% Защиты Данилла + 100) на 1 ход (перезарядка 3 хода)."
	},
	"milena": {
		"E1": "Сверхспособности «Обречённых» союзников, вызванные Миленой, игнорируют 10% всех типов Сопротивления (RES).",
		"E2": "Базовая атака также задерживает действие цели на 25%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Использование Базовой атаки продвигает собственное действие Милены на 40%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Сверхспособность теперь восстанавливает Энергию любому союзнику (но цепочка ультов срабатывает только если они «Обречённые»)."
	},
	"dotseva": {
		"E1": "Длительность Сверхспособности увеличена на 1 цикл, а стоимость снижена на 10 энергии.",
		"E2": "Максимальное количество стаков Калибровки увеличено на 10.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Состояние «Лёгкий туман» повышает Силу атаки Доцевой на (Калибровка × 35) ед.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Все вновь появляющиеся враги сразу получают статус «Должника» от Навыка E. Навык E становится одиночным, а 30% урона всех союзников по этой цели передаётся соседям."
	},
	"naama": {
		"E1": "Наносимый базовой атакой урон увеличен на 20%.",
		"E2": "Талант дополнительно накладывает 1 стак «Опьянения» при срабатывании «Опьянения» вне хода врага.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "После использования Сверхспособности следующий Навык Е не потратит очки навыков.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Когда «Поцелуй бездны» исчезает, все DoT-эффекты на враге срабатывают ещё один раз, затем восстанавливается 1 очко навыков."
	},
	"lenskaya": {
		"E1": "Бонус-атака Ленской, описанная в Улучшенном Навыке Q, теперь наносит урон всем целям на поле боя в размере 70% СА.",
		"E2": "Бонус-атаки всех союзников игнорируют 40% защиты противника и откладывают действия поражённых целей на 7%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Улучшенный Навык Q накладывает статус «Награда за голову» на 3 хода, вместо одного.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Весь урон Ленской считается Бонус-атаками. Ленская игнорирует 20% любых типов сопротивления противников, а Бонус-атака Улучшенного Навыка Q наносит Чистый урон."
	},
	"rimes": {
		"E1": "Увеличивает количество стаков таланта до 6. В начале боя Раймс моментально получает 2 стака таланта.",
		"E2": "Когда Раймс побеждает врага, он немедленно получает ещё одно действие (1 раз за ход).",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Базовая атака Раймса навсегда заменяется Усиленной Базовой атакой.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Эффекты Казни Раймса теперь распространяются на любые типы противников, в том числе и Боссов."
	},
	"isaac": {
		"E1": "Крит. шанс Айзека увеличен на 40%.",
		"E2": "Использование усиленного Навыка Q теперь не тратит очки навыков.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Использование Усиленного Навыка Q снимает с выбранного союзника все ослабления.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "В начале боя Айзек получает 8 уровней статуса «Теория на практике»."
	},
	"keloist": {
		"E1": "Наносимый Сверхспособностью Келойста урон по противникам с ХП < 30% увеличен на 10%.",
		"E2": "Если союзник со статусом «Ортощит» погибает, Келойст восстанавливает 2 очка навыков.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "В начале боя Келойст восстанавливает 30 единиц энергии.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Использование Навыка E на союзнике снимает с него 1 ослабление."
	},
	"musienko": {
		"E1": "Бонус-атака таланта больше не может досрочно завершить «Аннигиляцию бытия» при повторении. Защита поражённых врагов снижается на 20% на 2 хода.",
		"E2": "В «Аннигиляции бытия» Мусиенко получает +20% пробития огненного сопротивления, ХП не поднимается выше 60%, и его ХП не может опуститься ниже 1 ед. от атак врагов (Бессмертие).",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "После использования Сверхспособности крит. урон Мусиенко увеличивается на 60% на 3 хода.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Наносимый чистый урон Навыка Е равен 60% от записанного значения. Если ХП противника опускается ниже 15%, он Казнится вне зависимости от его типа (включая Элиту/Боссов)."
	},
	"joan": {
		"E1": "Наносимый персонажами Эрудиции урон Сверхспособности увеличен на 10%.",
		"E2": "Наносимый Жоаном урон по противникам со статусом «Не промахнись» увеличен на 20%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Если Жоан пробивает уязвимость противника, он дополнительно откладывает его действие на 30%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "При нанесении бонус-атаки противнику Жоан дополнительно восстанавливает 5 единиц энергии."
	},
	"jeff": {
		"E1": "Использование Сверхспособности активирует талант «Пошумите!».",
		"E2": "Если в отряде есть 2 союзника пути Небытия, исходящее исцеление Джеффа увеличивается на 30%, а DoT-урон на 50%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Использование базовой атаки Джеффом восстанавливает ему 10% от его макс. ХП.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Бонус-атака Джеффа также детонирует все эффекты периодического урона на противнике с 25% эффективностью."
	},
	"valramors": {
		"E1": "Сверхспособность восстанавливает 5 ед. энергии за каждое ослабление у центрального противника.",
		"E2": "Требование Следа 1 снижено до 1/2 Квантовых героев и режет 20% / 30% ВСЕХ типов сопротивления соответственно.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Сверхспособность Валраморса задерживает действия поражённых противников на 20%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Навык Q атакует ВСЕХ противников с базовым шансом 120% снизить защиту на 40%. След 3 активируется всегда."
	},
	"arseniy_admin": {
		"E1": "Победа над противником восстанавливает 5 энергии Арсению • Права администратора.",
		"E2": "Навык Q имеет базовый шанс 100% понизить квантовое сопротивление цели на 12% на 2 хода.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 20%.",
		"E4": "При атаке противника с ослаблениями Арсений • Права администратора наносит дополнительный Бинарный урон в размере 40% от своей силы атаки.",
		"E5": "Повышает уровень Таланта и Сверхспособности на 20%.",
		"E6": "Если текущее значение Векторов больше или равно 60, то все типы сопротивлений противников понижаются на 20%. Эффект действует, пока Векторы больше или равны 60."
	},
	"dasha_admin": {
		"E1": "За каждые 100 ед. защиты выше 3000 Даша • Права администратора получает 150 силы атаки.",
		"E2": "Наносимый Навыком Е Бинарный урон увеличивается на 20%.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 20%.",
		"E4": "Если здоровье любого союзника опускается ниже 20%, Даша • Права администратора немедленно применяет Навык Е без затрат очков навыков (срабатывает 1 раз за бой).",
		"E5": "Повышает уровень Таланта и Сверхспособности на 20%.",
		"E6": "Если использование Навыка Q тратит 30 Цифровых следов, Даша увеличивает Бинарный урон отряда на 30% на 2 хода."
	},
	"joan_spirit": {
		"E1": "В Форме духа урон по одиночным целям дополнительно увеличивается на 30%.",
		"E2": "Сверхспособность накладывает на всех врагов статус «Сожаление» и снижает их сопротивление на 15%.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Накопление стаков Последнего желания продвигает действие Жоана на 25%.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Усиленная базовая атака восстанавливает 1 ОН и наносит чистый урон вместо мнимого."
	},
	"isaac_admin": {
		"E1": "В начале хода любого союзника (кроме самого Айзека • Права администратора), Айзек восстанавливает 3 Вектора.",
		"E2": "Использование Сверхспособности даёт 60 Векторов. Атака таланта игнорирует 20% защиты цели.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 20%.",
		"E4": "Улучшенный Навык Q накладывает статус уязвимости к Бинарному урону на 20% на поражённых врагов на 2 хода.",
		"E5": "Повышает уровень Таланта и Сверхспособности на 20%.",
		"E6": "Весь наносимый союзниками урон считается Бинарным (сохраняя исходный элемент) и получает все соответствующие усиления. Усиленная Базовая атака восстанавливает 20 Векторов."
	},
	"sara_admin": {
		"E1": "Использование Навыка Е увеличивает скорость всех союзников на 30% на 2 хода (эффект не складывается).",
		"E2": "Использование Сверхспособности восстанавливает 1 очко навыков. Базовая атака при попадании по противнику увеличивает получаемый им любой урон на 30% на 2 хода.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 20%.",
		"E4": "Наносимый Сарой • Права администратора Бинарный урон увеличивается на 40%.",
		"E5": "Повышает уровень Таланта и Сверхспособности на 20%.",
		"E6": "Когда союзник наносит Бинарный урон, Сара • Права администратора наносит дополнительный урон в размере 30% от своей силы атаки. За каждое срабатывание этого эффекта действие всех союзников продвигается вперед на 3%."
	},
	"shoji_swan": {
		"E1": "В «Танце» Сверхспособность накладывает 65% уязвимости ко всем типам урона, а её урон растет на +0.75% за Вектор.",
		"E2": "В «Вирусе» Бинарный урон союзников +50%, а КУ Сёдзи растет на +1% за Вектор.",
		"E3": "Увеличивает урон и уровни Базовой атаки и Навыков на 20%.",
		"E4": "Навык E дополнительно генерирует +20 Векторов Консоли.",
		"E5": "Увеличивает урон и уровни Таланта и Сверхспособности на 20%.",
		"E6": "Весь урон всех союзников становится Бинарным, а Бинарный урон получает стандартные баффы урона!"
	},
	"katarina": {
		"E1": "Снижает сопротивление цели ко всем типам урона на 20%, а также снижает её скорость на 30% на 2 хода.",
		"E2": "Сверхспособность атакует всех противников, нанося урон основной цели. Если враг один, урон ульты повышается на 90%.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Применение завершающего удара ультимейта («Рвущий удар») восстанавливает 1 очко навыков.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "След 1 дает всем союзникам 100% КУ безусловно, весь урон по «Сломленному духу» становится критическим, а След 2 дает +40% Бинарного урона!"
	},
	"dotseva_crimson_tears": {
		"E1": "Персонаж под Навыком E получает +40% агро. Если ХП союзника < 25%, экстренно лечит команду на 15% СА Доцевой (откат 4 хода).",
		"E2": "Враги, поражённые Сверхспособностью, получают на 40% больше урона в течение 2 ходов.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Пока действует защитная Зона Навыка E, максимальное ХП всех союзников повышается на 30%.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "Ходы союзников продвигают действие Доцевой на 15%. Улучшенный Q наносит дополнительный чистый урон (50% общей СА отряда)."
	},
	"lenskaya_antimatter": {
		"E1": "В начале хода любого союзника восстанавливает 3 ед. Xaeroh. Когда союзник применяет Сверхспособность, действие Ленской продвигается вперёд на 15%.",
		"E2": "При атаке по одиночной цели игнорирует 20% сопротивления квантовому урону. Атаки накладывают «Разложение» на 2 хода (+30% квант. уязвимости, по элите и боссам +60%). По целям под «Разложением» любая атака персонажа дополнительно наносит 1 удар бинарным уроном (20% СА).",
		"E3": "Повышает уровень Базовой атаки и Навыков на 20%.",
		"E4": "Использование «Уничтожения сверхновой» наносит всем остальным противникам 60% СА квантового Бинарного урона. Урон Бинарных атак повышается на 30%.",
		"E5": "Повышает уровень Таланта и Сверхспособности на 20%.",
		"E6": "Базовая атака и Навык Q «Без формы» конвертируют свой урон в Квантовый Бинарный урон. Вход в любую форму считается нанесением урона сверхспособностью (50% СА). При использовании «Уничтожение сверхновой» расходуется лишь 30% Xaeroh, а персонаж получает дополнительный ход Сверхспособности для выбора формы."
	},
	"velzebul": {
		"E1": "При вступлении в бой сразу переходит в стойку «Подношение Вельзевул». При получении Грешного сердца дополнительно восстанавливает 5 ед. энергии и накапливает 5 Зеро.",
		"E2": "Сверхспособность продвигает действие всех союзников пути Антиматерии на 100%, а других союзников — на 40%.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Применение Навыка Q повышает Скорость Вельзевул на 30% на 2 хода.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "В начале каждого своего хода получает +10 Зеро. За каждую 1 ед. Зеро свыше 30, все союзники наносят на 1% больше урона."
	},
	"marina_sky_guardian": {
		"E1": "Сверхспособность накладывает зону «Элизиум» немедленно при использовании без задержки. Время действия зоны продлевается на 1 ход (всего 3 хода).",
		"E2": "В зоне «Элизиум» урон по связанному противнику дополнительно наносит 30% от нанесенного урона в виде чистого урона.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Когда союзник совершает действие, связанный с ним дух памяти получает +10% к полоске заряда.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "Связанный союзник и его дух памяти наносят на 50% больше урона."
	},
	"lenskaya_sky_guardian": {
		"E1": "Первое использование Навыка E за бой тратит на 1 Очко Навыков меньше.",
		"E2": "Статус «Враг Свечения» дополнительно увеличивает получаемый противником урон Суперпробития на 15% (суммарно 45% для всех союзников).",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Усиленная базовая атака восстанавливает 5 единиц энергии.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "Перед нанесением урона Навыком E накладывает на цель Мнимую уязвимость на 2 хода (без снижения сопротивления)."
	},
	"rimes_ascension": {
		"E1": "Урон Лап антиматерии по противникам с текущим здоровьем <= 80% повышается на 20%, а по противникам с текущим здоровьем <= 50% — на 40%.",
		"E2": "Использование Навыка E дополнительно накапливает +2 заряда Лап (вместо +1), продвигает их действие вперед на 50% и дает 30% шкалы Крещендо.",
		"E3": "Повышает уровень Базовой атаки и Навыков на 2.",
		"E4": "Исходящее исцеление по всем союзникам повышается на 30%.",
		"E5": "Повышает уровень Сверхспособности и Таланта на 2.",
		"E6": "Все атаки Раймса и Лап истощают стойкость врагов независимо от типа уязвимости и обладают +20% квантового пробития сопротивления (RES PEN). При гибели или исчезновении Лап предсмертная серия ударов совершает 9 ударов (вместо 6), а множитель каждого удара повышается до 52% макс. ХП Лап (вместо 40%)."
	}
}

# Описания комплектов реликвий
const RELIC_DESCRIPTIONS := {
	"symbiosis": "❄ [2 ч]: Ледяной урон +10%.\n❄ [4 ч]: Пробитие уязвимости вечно понижает защиту врага на 15% (до восстановления стойкости).",
	"chaos": "🌌 [2 ч]: Квантовый урон +10%.\n🌌 [4 ч]: При ХП < 50% наносимый урон повышается на +20%.",
	"mortal_world": "⚔ [2 ч]: Физический урон +10%.\n⚔ [4 ч]: Эффективность пробития уязвимости повышается на +15%.",
	"lava_fighter": "🔥 [2 ч]: Огненный урон +10%.\n🔥 [4 ч]: Урон вне своего хода (DoT, контратаки, бонус-атаки) +20%.",
	"light_gift": "⚡ [2 ч]: Электрический урон +10%.\n⚡ [4 ч]: Активация Сверхспособности восстанавливает 25% макс. ХП.",
	"hope_beam": "✨ [2 ч]: Мнимый урон +10%.\n✨ [4 ч]: Урон навыков +12%, а следующая атака после ульты наносит +12% урона.",
	"rapid_response": "🌪 [2 ч]: Ветряной урон +10%.\n🌪 [4 ч]: После использования Сверхспособности действие продвигается на 25%.",
	"biology_doctor": "🧪 [2 ч]: Исходящее исцеление +10%.\n🧪 [4 ч]: В начале боя восстанавливает команде +1 Очко навыков.",
	"dying_planet": "🛡 [2 ч]: Защита +15%.\n🛡 [4 ч]: Прочность всех входящих щитов повышается на +20%.",
	"lost_self": "🗡 [2 ч]: Сила атаки +15%.\n🗡 [4 ч]: Игнорирует 6% защиты за каждый DoT на цели (до макс. 18%).",
	"galilean": "🎯 [2 ч]: Урон бонус-атак +20%.\n🎯 [4 ч]: Каждая тычка бонус-атаки дает +6% СА (макс 8 стаков / +32% СА на 3 хода).",
	"silhouette": "👤 [2 ч]: Крит. урон +16%.\n👤 [4 ч]: Получение удара дает +5% СА (макс 5). Совершение Казни дает +20 Скорости на 2 хода.",
	"accepted_sin": "🩸 [2 ч]: Макс. ХП +12%.\n🩸 [4 ч]: При потере здоровья Крит. шанс повышается на +5% на 1 ход (макс 6 стаков / +30%).",
	"bereft_future": "👟 [2 ч]: Скорость +6%.\n👟 [4 ч]: При ульте на союзника скорость всей пати повышается на +12% на 1 ход.",
	"damaged_strings": "💾 [2 ч]: Бинарный урон +15%.\n💾 [4 ч]: После использования Сверхспособности Бинарный урон игнорирует 20% защиты врага на 3 хода.",
	"dying_stars_child": "🌌 [2 ч]: Крит. шанс +8%.\n🌌 [4 ч]: Навыки Q и E восстанавливают +5 Зеро (при синергии Антиматерия 1). Если Зеро > 40, урон +15%.",
	"detroit": "🌆 [2 ч]: Сила атаки +12%. Если СКР >= 120, сила атаки дополнительно повышается на +12% (всего +24%).",
	"lost_edge": "🔬 [2 ч]: Макс. ХП +12%. Если СКР >= 120, сила атаки всех союзников повышается на +8%.",
	"japan_island": "🗾 [2 ч]: Защита +15%. Если ШПЭ >= 50%, защита дополнительно повышается на +15%.",
	"krasnodar": "☀ [2 ч]: Крит. шанс +8%. Если КШ >= 50%, урон Сверхспособности и бонус-атак повышается на +15%.",
	"other_side_universe": "🌌 [2 ч]: Крит. шанс +12%. Если КШ >= 70%, урон базовой атаки и навыков повышается на +20%.",
	"irkutsk": "🧊 [2 ч]: Бонус-атака союзника дает стак Подвига (+5% урона FUA). При 5 стаках КУ +25%.",
	"server_depths": "🖥 [2 ч]: Скорость +6%. При Навыке E скорость +12% на 2 хода. Если Навык E Бинарный, враги получают на 10% больше Бинарного урона на 2 хода (стакается от разных источников).",
	"inverted_depths": "🌀 [2 ч]: Сила атаки +12%. Если не в 1-м слоте и фракция совпадает с 1-м персонажем — наносимый урон обоих повышается на +10%.",
	"dark_side_defector": "🎯 [2 ч]: Эффект пробития +16%.\n🎯 [4 ч]: При ЭП >= 130% урон пробития игнорирует 10% защиты; при ЭП >= 180% Суперпробитие игнорирует ещё 15% защиты.",
	"bloom_defender": "🌸 [2 ч]: Сила атаки +12%. При наличии Духа Памяти скорость владельца +6%.\n🌸 [4 ч]: Атака Духа Памяти дает +30% Крит. урона владельцу и Духу Памяти на 2 хода.",
	"risen_krasnodar": "💥 [2 ч]: Крит. урон +16%. Если на поле есть призванные существа или Дух Памяти, Крит. урон владельца +32%.",
	"ruins_hq": "🏛 [2 ч]: Эффект пробития +16%. Если Скорость >= 145, Эффект пробития дополнительно повышается на +20%."
}

# UI Контейнеры экранов
var main_center_container: CenterContainer
var standard_hub_margin: MarginContainer
var shop_screen: VBoxContainer
var inventory_screen: VBoxContainer
var levels_screen: VBoxContainer
var characters_screen: VBoxContainer
var database_screen: VBoxContainer

# Добавьте в блок переменных main_menu.gd:
var gacha_screen: VBoxContainer
var shine_label: Label
var gacha_info_label: Label
var _menu_bgm_player: AudioStreamPlayer = null

# Элементы интерфейса
var coins_label: Label
var shop_coins_label: Label
var notification_label: Label
var inv_characters_grid: GridContainer
var inv_cones_grid: GridContainer
var shop_grid: GridContainer

# Элементы сборки персонажей
var selected_char_for_build: String = ""
var char_build_roster_container: VBoxContainer
var build_editor_panel: VBoxContainer
var build_char_title: Label
var opt_eidolon: OptionButton
var opt_light_cone: OptionButton
var btn_choose_light_cone: Button
var opt_cavern_type: OptionButton
var opt_cavern_set1: OptionButton
var opt_cavern_set2: OptionButton
var opt_body: OptionButton
var opt_feet: OptionButton
var opt_planar_set: OptionButton
var opt_sphere: OptionButton
var opt_rope: OptionButton

var desc_light_cone: RichTextLabel
var desc_cavern_set1: RichTextLabel
var desc_cavern_set2: RichTextLabel
var desc_planar_set: RichTextLabel
var row_cavern_set1: VBoxContainer
var row_cavern_set2: VBoxContainer
var btn_save_char_build: Button

# Модальное окно улучшения реликвий
var _upgrade_target_relic: Dictionary = {}
var _upgrade_selected_fodder_uids: Array[String] = []
var _upgrade_selected_shards_count: int = 0
var _upgrade_overlay: ColorRect = null
var _upgrade_target_card_container: VBoxContainer = null
var _upgrade_exp_info_lbl: Label = null
var _upgrade_preview_lbl: Label = null
var _upgrade_progress_bar: ProgressBar = null
var _upgrade_fodder_grid: GridContainer = null
var _upgrade_fodder_counter_lbl: Label = null
var _upgrade_shards_info_lbl: Label = null
var _upgrade_shards_btn: Button = null
var _upgrade_btn_apply: Button = null
var _upgrade_btn_auto_shards: Button = null
var selected_dungeon_for_battle: String = ""

# Ссылки на кнопки "Назад" для Мета-Обучения
var btn_levels_back: Button
var btn_char_back: Button
var btn_db_back: Button
var btn_inv_back: Button
var btn_shop_back: Button

# Элементы экрана подготовки к бою (начиная с 6 уровня)
var level_team_setup_screen: VBoxContainer
var selected_level_for_battle: int = 6
var _level_team: Array = [null, null, null, null]
var level_team_slots_container: HBoxContainer
var level_team_roster_container: BoxContainer
var level_initiator_option: OptionButton
var level_setup_title: Label

# Элементы Энциклопедии / Базы Данных
var db_roster_container: VBoxContainer
var db_banner_panel: PanelContainer
var db_title_label: Label
var db_bio_label: Label
var db_skills_text: RichTextLabel
var db_allies_text: RichTextLabel
var db_cones_text: RichTextLabel
var db_relics_text: RichTextLabel
var db_tip_text: RichTextLabel

# Элементы обучения в Главном Меню
var is_menu_tutorial: bool = false
var menu_tut_step: int = 0
const TutorialGuideOverlayScript = preload("res://scripts/ui/tutorial_guide_overlay.gd")
var menu_guide_overlay: Control = null
var menu_tut_overlay: Control = null
var menu_tut_panel: PanelContainer
var menu_tut_label: RichTextLabel
var menu_tut_btn: Button
var menu_tut_pointer: Label

var level_rewards_label: Label

# Переменные кнопок меню для блоков
var btn_menu_levels: Button
var btn_menu_chars: Button
var btn_chars: Button
var btn_menu_db: Button
var btn_menu_inv: Button
var btn_menu_shop: Button
var btn_menu_gacha: Button

# Элементы обновленного интерфейса Хаба
var hub_overview_panel: PanelContainer
var hub_overview_team_vbox: BoxContainer
var hub_overview_progress_lbl: Label
var hub_coins_pill_label: Label
var hub_shine_pill_label: Label
var hub_shards_pill_label: Label

# Элементы экрана «Добыча реликвий»
var btn_menu_relics: Button
var relic_farming_screen: VBoxContainer
var relic_farming_cards_container: GridContainer
var relic_farming_guarantee_lbl: Label
var relic_farming_category: String = "cavern"
var btn_farm_tab_cavern: Button
var btn_farm_tab_planar: Button

# Инвентарь реликвий
var btn_tab_relics: Button
var inv_relics_container: VBoxContainer
var inv_relics_grid: GridContainer
var opt_inv_relic_slot_filter: OptionButton
var opt_inv_relic_rarity_filter: OptionButton

# Слоты экипированных реликвий персонажа
var char_equipped_relics_container: VBoxContainer
var char_active_sets_label: Label

# Ссылки для интерактивного обучения реликвиям
var tut_academy_instant_btn: Button = null
var btn_farming_back: Button = null
var tut_slot_btn_head: Button = null
var tut_slot_btn_hands: Button = null
var tut_slot_btn_upgrade_head: Button = null
var tut_dismantle_btn: Button = null

# Элементы Зала воспоминаний (Memory Hall)
var btn_menu_memory_hall: Button = null
var _memory_hall_shimmer_tween: Tween = null
var memory_hall_screen: VBoxContainer = null
var memory_hall_cards_container: GridContainer = null
var memory_hall_status_label: Label = null
var memory_hall_stars_label: Label = null
var memory_hall_rewards_container: HBoxContainer = null
var selected_memory_hall_floor: int = 0

# Двухкомандная подготовка для 4-го этажа
var memory_hall_team_setup_screen: VBoxContainer = null
var mh_team1_slots_container: HBoxContainer = null
var mh_team2_slots_container: HBoxContainer = null
var mh_roster_container: GridContainer = null
var mh_init_opt_1: OptionButton = null
var mh_init_opt_2: OptionButton = null
var _mh_team_1: Array = [null, null, null, null]
var _mh_team_2: Array = [null, null, null, null]
var _mh_active_target_team: int = 1

# Космический фон для главного меню игры
class CosmicMenuBackground extends Control:
	var _stars: Array[Dictionary] = []

	func _init() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 42981
		for i in range(140):
			var rx := rng.randf_range(15.0, 2545.0)
			var ry := rng.randf_range(15.0, 1425.0)
			var rad := rng.randf_range(1.0, 2.6)
			var a := rng.randf_range(0.3, 0.9)
			var tint := Color(0.85, 0.92, 1.0) if rng.randf() > 0.25 else Color(1.0, 0.85, 0.55)
			_stars.append({"pos": Vector2(rx, ry), "radius": rad, "alpha": a, "tint": tint})

	func _draw_soft_glow(center: Vector2, max_radius: float, base_color: Color) -> void:
		for s in range(5, 0, -1):
			var r := max_radius * (float(s) / 5.0)
			var col := base_color
			col.a = base_color.a * (1.0 - float(s - 1) / 5.0) * 0.4
			draw_circle(center, r, col)

	func _draw() -> void:
		var sz := size
		# 1. Глубокий космический градиент (обсидиановая бездна с сапфировым и аметистовым отливом)
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.045, 0.055, 0.085, 1.0))

		# 2. Мягкие туманности / глубокие неоновые сферы с плавным градиентом
		_draw_soft_glow(Vector2(sz.x * 0.82, sz.y * 0.22), 380.0, Color(0.12, 0.24, 0.52, 0.55))
		_draw_soft_glow(Vector2(sz.x * 0.18, sz.y * 0.78), 340.0, Color(0.26, 0.12, 0.42, 0.45))
		_draw_soft_glow(Vector2(sz.x * 0.50, -30.0), 420.0, Color(0.35, 0.28, 0.12, 0.35))

		# 3. Звёздное поле
		for s in _stars:
			var col: Color = s["tint"]
			col.a = s["alpha"]
			draw_circle(s["pos"], s["radius"], col)

		# 4. Тонкие горизонтальные направляющие линии
		draw_line(Vector2(45, 76), Vector2(sz.x - 45, 76), Color(0.25, 0.35, 0.55, 0.35), 1.0)
		draw_line(Vector2(45, sz.y - 65), Vector2(sz.x - 45, sz.y - 65), Color(0.25, 0.35, 0.55, 0.22), 1.0)

		# 5. Угловые декоративные рамки
		var corner_color := Color(0.35, 0.45, 0.65, 0.40)
		draw_line(Vector2(18, 18), Vector2(45, 18), corner_color, 2.0)
		draw_line(Vector2(18, 18), Vector2(18, 45), corner_color, 2.0)
		draw_line(Vector2(sz.x - 18, 18), Vector2(sz.x - 45, 18), corner_color, 2.0)
		draw_line(Vector2(sz.x - 18, 18), Vector2(sz.x - 18, 45), corner_color, 2.0)
		draw_line(Vector2(18, sz.y - 18), Vector2(45, sz.y - 18), corner_color, 2.0)
		draw_line(Vector2(18, sz.y - 18), Vector2(18, sz.y - 45), corner_color, 2.0)
		draw_line(Vector2(sz.x - 18, sz.y - 18), Vector2(sz.x - 45, sz.y - 18), corner_color, 2.0)
		draw_line(Vector2(sz.x - 18, sz.y - 18), Vector2(sz.x - 18, sz.y - 45), corner_color, 2.0)

# --- УНИВЕРСАЛЬНЫЙ КЛАСС ПЛАВНОГО СКРОЛЛА (ГОРИЗОНТАЛЬНЫЙ И ВЕРТИКАЛЬНЫЙ) ---

class SmoothScrollContainer extends ScrollContainer:
	var target_scroll_h: float = 0.0
	var target_scroll_v: float = 0.0
	var tween_h: Tween = null
	var tween_v: Tween = null
	var is_internal_tween_h: bool = false
	var is_internal_tween_v: bool = false

	func _ready() -> void:
		target_scroll_h = float(scroll_horizontal)
		target_scroll_v = float(scroll_vertical)
		var h_bar := get_h_scroll_bar()
		if h_bar:
			h_bar.value_changed.connect(func(new_val: float):
				if not is_internal_tween_h:
					target_scroll_h = new_val
			)
		var v_bar := get_v_scroll_bar()
		if v_bar:
			v_bar.value_changed.connect(func(new_val: float):
				if not is_internal_tween_v:
					target_scroll_v = new_val
			)

	func _gui_input(event: InputEvent) -> void:
		var can_scroll_v := (vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		var v_bar := get_v_scroll_bar()
		var has_v_overflow := (v_bar != null and (v_bar.max_value - v_bar.page) > 1.0)
		
		var can_scroll_h := (horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		var h_bar := get_h_scroll_bar()
		var has_h_overflow := (h_bar != null and (h_bar.max_value - h_bar.page) > 1.0)

		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					if can_scroll_v and has_v_overflow:
						scroll_v_by(80.0)
						accept_event()
					elif can_scroll_h:
						scroll_h_by(55.0)
						accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					if can_scroll_v and has_v_overflow:
						scroll_v_by(-80.0)
						accept_event()
					elif can_scroll_h:
						scroll_h_by(-55.0)
						accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				if event.pressed and can_scroll_h:
					scroll_h_by(55.0)
					accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
				if event.pressed and can_scroll_h:
					scroll_h_by(-55.0)
					accept_event()
		elif event is InputEventPanGesture:
			if can_scroll_v and has_v_overflow and absf(event.delta.y) > 0.001:
				scroll_v_by(event.delta.y * 35.0)
				accept_event()
			elif can_scroll_h and (absf(event.delta.x) > 0.001 or absf(event.delta.y) > 0.001):
				var delta: float = (event.delta.x + event.delta.y) * 25.0
				scroll_h_by(delta)
				accept_event()

	func scroll_by(amount: float) -> void:
		scroll_h_by(amount)

	func scroll_h_by(amount: float) -> void:
		var h_bar := get_h_scroll_bar()
		var max_s: float = float(h_bar.max_value - h_bar.page) if h_bar else 5300.0
		if max_s <= 0.0:
			max_s = 5300.0
		target_scroll_h = clampf(target_scroll_h + amount, 0.0, max_s)
		if tween_h and tween_h.is_valid():
			tween_h.kill()
		is_internal_tween_h = true
		tween_h = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_h.tween_property(self, "scroll_horizontal", int(target_scroll_h), 0.22)
		tween_h.finished.connect(func(): is_internal_tween_h = false)

	func scroll_v_by(amount: float) -> void:
		var v_bar := get_v_scroll_bar()
		var max_s: float = float(v_bar.max_value - v_bar.page) if v_bar else 5000.0
		if max_s <= 0.0:
			max_s = 5000.0
		target_scroll_v = clampf(target_scroll_v + amount, 0.0, max_s)
		if tween_v and tween_v.is_valid():
			tween_v.kill()
		is_internal_tween_v = true
		tween_v = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_v.tween_property(self, "scroll_vertical", int(target_scroll_v), 0.22)
		tween_v.finished.connect(func(): is_internal_tween_v = false)

static func _get_element_color(element: int) -> Color:
	match element:
		CombatConstants.Element.ICE: return Color(0.4, 0.8, 1.0)
		CombatConstants.Element.FIRE: return Color(1.0, 0.45, 0.3)
		CombatConstants.Element.PHYSICAL: return Color(0.9, 0.9, 0.95)
		CombatConstants.Element.WIND: return Color(0.35, 0.9, 0.55)
		CombatConstants.Element.LIGHTNING: return Color(0.8, 0.5, 1.0)
		CombatConstants.Element.QUANTUM: return Color(0.45, 0.55, 1.0)
		CombatConstants.Element.IMAGINARY: return Color(1.0, 0.85, 0.3)
	return Color(0.4, 0.8, 1.0)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if TeamConfig.has_save_file():
		TeamConfig.load_game()

	# Автоматически восстанавливаем отряд при запуске
	if TeamConfig.team_members.is_empty() and not TeamConfig.last_used_team.is_empty():
		TeamConfig.team_members = TeamConfig.last_used_team.duplicate(true)
	elif TeamConfig.team_members.is_empty() and not TeamConfig.unlocked_characters.is_empty():
		for i in range(mini(4, TeamConfig.unlocked_characters.size())):
			var c_id: String = TeamConfig.unlocked_characters[i]
			var b := TeamConfig.get_saved_build(c_id)
			b["slot_idx"] = i
			TeamConfig.team_members.append(b)

	var bg := CosmicMenuBackground.new()
	add_child(bg)

	_build_ui()

	if has_node("/root/NetworkManager"):
		var net = get_node("/root/NetworkManager")
		if net.get("sync") != null:
			net.sync.sync_completed.connect(_on_cloud_sync_completed)
	
	var is_dungeon_mode := TeamConfig.battle_mode.begins_with("dungeon_") or TeamConfig.battle_mode.begins_with("planar_")
	if is_dungeon_mode:
		_show_screen("relic_farming")
		if TeamConfig.battle_mode.begins_with("planar_"):
			relic_farming_category = "planar"
		else:
			relic_farming_category = "cavern"
		_refresh_relic_farming_ui()
		if not TeamConfig.menu_tutorial_completed:
			is_menu_tutorial = true
			_init_menu_tutorial_ui()
			menu_tut_step = 201
	elif TeamConfig.current_level_progress >= 5 and not TeamConfig.menu_tutorial_completed:
		is_menu_tutorial = true
		_init_menu_tutorial_ui()
		_show_screen("levels")
		_run_menu_tut_step(1)
	elif TeamConfig.battle_mode.begins_with("memory_hall_"):
		_refresh_memory_hall_screen()
		_show_screen("memory_hall")
	elif TeamConfig.battle_mode.begins_with("level_"):
		_show_screen("levels")
	else:
		_show_screen("main")

	# Проверка вывода золотой награды за 5 Уровень
	if TeamConfig.has_meta("show_level_5_reward"):
		TeamConfig.remove_meta("show_level_5_reward")
		_show_level_5_gold_reward_popup()
		
	# Проверка выпавших наград подземелья реликвий
	var had_pending_drops := false
	if TeamConfig.has_meta("pending_relic_drops"):
		var drops = TeamConfig.get_meta("pending_relic_drops")
		TeamConfig.remove_meta("pending_relic_drops")
		if drops is Array and not drops.is_empty():
			had_pending_drops = true
			_show_dungeon_rewards_popup(drops, "Победа в Подземелье!")

	if is_dungeon_mode and not TeamConfig.menu_tutorial_completed and not had_pending_drops:
		_run_menu_tut_step(202)

	# --- Сетевая инициализация и проверка обновлений ---
	_setup_network_and_updater_integration()
	_check_account_registration()
		
func _build_ui() -> void:
	# 1. Главное меню
	main_center_container = CenterContainer.new()
	main_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_center_container)

	var main_vbox := VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 22)
	main_center_container.add_child(main_vbox)
	
	var title := Label.new()
	title.text = "VOID OF OBLIVION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0))
	main_vbox.add_child(title)

	var btn_start := _create_custom_button("🎮 Начать игру", main_vbox, Vector2(450, 65), 20)
	btn_start.pressed.connect(func(): _show_screen("hub"))

	var btn_load := _create_custom_button("📂 Загрузить сохранение", main_vbox, Vector2(450, 65), 20)
	btn_load.pressed.connect(_on_load_pressed)

	var btn_settings_main := _create_custom_button("⚙️ Настройки", main_vbox, Vector2(450, 65), 20)
	btn_settings_main.pressed.connect(_show_settings_dialog)

	var btn_reset := _create_custom_button("🔥 Сбросить прогресс", main_vbox, Vector2(450, 65), 20)
	btn_reset.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	btn_reset.pressed.connect(_show_reset_confirmation_dialog)

	var btn_admin := _create_custom_button("🛠 Админ-панель", main_vbox, Vector2(450, 65), 20)
	btn_admin.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/team_setup/team_setup.tscn"))

	# 2. Меню Стандартного режима (Hub)
	standard_hub_margin = MarginContainer.new()
	standard_hub_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	standard_hub_margin.add_theme_constant_override("margin_left", 45)
	standard_hub_margin.add_theme_constant_override("margin_right", 45)
	standard_hub_margin.add_theme_constant_override("margin_top", 18)
	standard_hub_margin.add_theme_constant_override("margin_bottom", 18)
	standard_hub_margin.visible = false
	add_child(standard_hub_margin)

	var hub_main_vbox := VBoxContainer.new()
	hub_main_vbox.add_theme_constant_override("separation", 12)
	standard_hub_margin.add_child(hub_main_vbox)

	# --- ШАПКА ХАБА (Header Bar) ---
	var header_bar := HBoxContainer.new()
	header_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	hub_main_vbox.add_child(header_bar)

	var hub_title_vbox := VBoxContainer.new()
	hub_title_vbox.add_theme_constant_override("separation", 2)
	header_bar.add_child(hub_title_vbox)

	var hub_title := Label.new()
	hub_title.text = "VOID OF OBLIVION"
	hub_title.add_theme_font_size_override("font_size", 28)
	hub_title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	hub_title_vbox.add_child(hub_title)

	var hub_subtitle := Label.new()
	hub_subtitle.text = "КОМАНДНЫЙ ЦЕНТР • ОПЕРАТИВНЫЙ ТЕРМИНАЛ"
	hub_subtitle.add_theme_font_size_override("font_size", 11)
	hub_subtitle.add_theme_color_override("font_color", Color(0.65, 0.72, 0.88))
	hub_title_vbox.add_child(hub_subtitle)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(header_spacer)

	# Валютные капсулы (Справа вверху)
	var currency_bar := HBoxContainer.new()
	currency_bar.add_theme_constant_override("separation", 10)
	header_bar.add_child(currency_bar)

	hub_coins_pill_label = _create_currency_pill("💰", str(TeamConfig.coins), Color(1.0, 0.85, 0.3), currency_bar)
	coins_label = hub_coins_pill_label
	hub_shine_pill_label = _create_currency_pill("✨", str(TeamConfig.shine), Color(0.4, 0.85, 1.0), currency_bar)
	hub_shards_pill_label = _create_currency_pill("🔮", str(TeamConfig.relic_shards), Color(0.85, 0.55, 1.0), currency_bar)

	# Разделитель
	var div := HSeparator.new()
	var div_sb := StyleBoxLine.new()
	div_sb.color = Color(0.25, 0.35, 0.55, 0.35)
	div_sb.thickness = 1
	div.add_theme_stylebox_override("separator", div_sb)
	hub_main_vbox.add_child(div)

	# --- ОСНОВНАЯ ОБЛАСТЬ (Content Area) ---
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_main_vbox.add_child(content_hbox)

	# Сетка квадратных кнопок-карточек (3 колонки)
	var hub_grid := GridContainer.new()
	hub_grid.columns = 3
	hub_grid.add_theme_constant_override("h_separation", 14)
	hub_grid.add_theme_constant_override("v_separation", 12)
	content_hbox.add_child(hub_grid)

	# 1. Уровни
	btn_menu_levels = _create_hub_card("levels", "🗺", "УРОВНИ", "Экспедиции & Испытания", hub_grid)
	btn_menu_levels.pressed.connect(func():
		_show_screen("levels")
		if is_menu_tutorial and menu_tut_step == 1:
			_run_menu_tut_step(2)
	)

	# 2. Персонажи
	btn_menu_chars = _create_hub_card("chars", "👤", "ПЕРСОНАЖИ", "Отряд, Билды & Эйдолоны", hub_grid)
	btn_chars = btn_menu_chars
	btn_menu_chars.pressed.connect(func():
		_refresh_characters_screen()
		_show_screen("characters")
		if is_menu_tutorial and (menu_tut_step == 2 or menu_tut_step == 203):
			_run_menu_tut_step(3)
	)

	# 3. Добыча реликвий
	btn_menu_relics = _create_hub_card("relics", "🏺", "ДОБЫЧА РЕЛИКВИЙ", "Пещеры коррозии & Планары", hub_grid)
	btn_menu_relics.pressed.connect(func():
		if is_menu_tutorial and menu_tut_step == 2:
			menu_tut_step = 201
		_refresh_relic_farming_ui()
		_show_screen("relic_farming")
		if is_menu_tutorial and menu_tut_step == 201:
			_run_menu_tut_step(201)
	)

	# 4. Гача
	btn_menu_gacha = _create_hub_card("gacha", "✨", "ГАЧА", "Баннеры & Призыв героев", hub_grid)
	btn_menu_gacha.pressed.connect(func():
		_refresh_gacha_ui()
		_show_screen("gacha")
		if is_menu_tutorial and menu_tut_step == 18:
			_run_menu_tut_step(19)
	)

	# 5. Инвентарь
	btn_menu_inv = _create_hub_card("inv", "🎒", "ИНВЕНТАРЬ", "Снаряжение & Осколки", hub_grid)
	btn_menu_inv.pressed.connect(func():
		_refresh_inventory_ui()
		_show_screen("inventory")
		if is_menu_tutorial and (menu_tut_step == 9 or menu_tut_step == 11 or menu_tut_step == 13):
			_run_menu_tut_step(12)
	)

	# 6. Магазин
	btn_menu_shop = _create_hub_card("shop", "🛒", "МАГАЗИН", "Рынок персонажей & Ресурсы", hub_grid)
	btn_menu_shop.pressed.connect(func():
		_refresh_shop_ui()
		_show_screen("shop")
		if is_menu_tutorial and menu_tut_step == 15:
			_run_menu_tut_step(16)
	)

	# 7. База данных
	btn_menu_db = _create_hub_card("db", "📚", "БАЗА ДАННЫХ", "Энциклопедия & Советы", hub_grid)
	btn_menu_db.pressed.connect(func():
		_refresh_database_screen()
		_show_screen("database")
		if is_menu_tutorial and (menu_tut_step == 9 or menu_tut_step == 11):
			_run_menu_tut_step(10)
	)

	# 8. Зал воспоминаний (Memory Hall)
	btn_menu_memory_hall = _create_hub_memory_hall_card(hub_grid)
	btn_menu_memory_hall.pressed.connect(func():
		_refresh_memory_hall_screen()
		_show_screen("memory_hall")
	)

	# Правая инфо-панель (Обзор отряда и профиля)
	hub_overview_panel = PanelContainer.new()
	hub_overview_panel.custom_minimum_size = Vector2(480, 410)
	hub_overview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var op_sb := StyleBoxFlat.new()
	op_sb.bg_color = Color(0.08, 0.10, 0.15, 0.85)
	op_sb.border_color = Color(0.25, 0.35, 0.52, 0.60)
	op_sb.set_border_width_all(2)
	op_sb.set_corner_radius_all(14)
	op_sb.set_content_margin_all(18)
	hub_overview_panel.add_theme_stylebox_override("panel", op_sb)
	content_hbox.add_child(hub_overview_panel)

	_build_hub_overview_content()

	# Инициализация экрана Гачи
	_build_gacha_screen()

	# --- НИЖНЯЯ ПАНЕЛЬ (Bottom Utility Bar) ---
	var bottom_bar := HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 16)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	hub_main_vbox.add_child(bottom_bar)

	var btn_save := _create_action_pill_button("💾 Сохранить", bottom_bar, Vector2(160, 42))
	btn_save.pressed.connect(_on_save_pressed)

	var btn_settings_hub := _create_action_pill_button("⚙️ Настройки", bottom_bar, Vector2(160, 42))
	btn_settings_hub.pressed.connect(_show_settings_dialog)

	var btn_promo := _create_action_pill_button("🎁 Промокод", bottom_bar, Vector2(150, 42))
	btn_promo.pressed.connect(_show_promo_code_dialog)

	var btn_check_update := _create_action_pill_button("🔄 Обновления", bottom_bar, Vector2(160, 42))
	btn_check_update.pressed.connect(_on_check_updates_pressed)

	var btn_back_hub := _create_action_pill_button("↩ Главное меню", bottom_bar, Vector2(170, 42))
	btn_back_hub.pressed.connect(func(): _show_screen("main"))

	notification_label = Label.new()
	notification_label.add_theme_font_size_override("font_size", 16)
	notification_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	bottom_bar.add_child(notification_label)

	# Инициализация всех под-экранов
	_build_shop_screen()
	_build_inventory_screen()
	_build_levels_screen()
	_build_characters_screen()
	_build_database_screen()
	_build_level_team_setup_screen()
	_build_relic_farming_screen()
	_build_memory_hall_screen()
	_build_memory_hall_team_setup_screen()

func _create_hub_card(btn_id: String, icon_text: String, title_text: String, subtitle_text: String, parent: Control, min_size: Vector2 = Vector2(230, 126)) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = min_size
	btn.text = title_text
	btn.add_theme_font_size_override("font_size", 1)
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.09, 0.11, 0.17, 0.90)
	sb_normal.border_color = Color(0.22, 0.28, 0.42, 0.75)
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.14, 0.18, 0.28, 0.95)
	sb_hover.border_color = Color(0.95, 0.75, 0.25, 0.95)
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(14)
	sb_hover.shadow_color = Color(0.95, 0.75, 0.25, 0.22)
	sb_hover.shadow_size = 8
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	sb_pressed.border_color = Color(1.0, 0.85, 0.40, 1.0)
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.03, 0.04, 0.06, 0.95)
	sb_disabled.border_color = Color(0.10, 0.12, 0.16, 0.40)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	btn.set_meta("card_content_node", content)

	var icon_lbl := Label.new()
	icon_lbl.text = icon_text
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_lbl)
	btn.set_meta("card_icon_lbl", icon_lbl)

	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_lbl)
	btn.set_meta("card_title_lbl", title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = subtitle_text
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(sub_lbl)
	btn.set_meta("card_sub_lbl", sub_lbl)

	parent.add_child(btn)
	return btn

func _set_hub_card_disabled(btn: Button, is_disabled: bool) -> void:
	if not btn or not is_instance_valid(btn):
		return
	btn.disabled = is_disabled
	var content: Control = btn.get_meta("card_content_node", null)
	if content and is_instance_valid(content):
		content.modulate = Color(0.24, 0.26, 0.32, 0.40) if is_disabled else Color(1.0, 1.0, 1.0, 1.0)

func _create_currency_pill(icon: String, initial_val: String, text_color: Color, parent: Control) -> Label:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.85)
	sb.border_color = text_color * 0.7
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(5)
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	pill.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	pill.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(icon_lbl)

	var val_lbl := Label.new()
	val_lbl.text = initial_val
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", text_color)
	hbox.add_child(val_lbl)

	parent.add_child(pill)
	return val_lbl

func _create_action_pill_button(text: String, parent: Control, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 15)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.22, 0.90)
	sb.border_color = Color(0.30, 0.40, 0.58, 0.70)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(0.18, 0.24, 0.36, 0.95)
	sb_h.border_color = Color(0.95, 0.80, 0.35, 1.0)
	sb_h.set_border_width_all(1)
	sb_h.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("hover", sb_h)

	parent.add_child(btn)
	return btn

func _build_hub_overview_content() -> void:
	if not hub_overview_panel:
		return
	for c in hub_overview_panel.get_children():
		c.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	hub_overview_panel.add_child(vbox)

	var top_hdr := Label.new()
	top_hdr.text = "⚔ ТЕКУЩИЙ ОТРЯД"
	top_hdr.add_theme_font_size_override("font_size", 18)
	top_hdr.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	vbox.add_child(top_hdr)

	hub_overview_team_vbox = HBoxContainer.new()
	hub_overview_team_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hub_overview_team_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hub_overview_team_vbox)

	var div2 := HSeparator.new()
	var div2_sb := StyleBoxLine.new()
	div2_sb.color = Color(0.25, 0.35, 0.55, 0.30)
	div2.add_theme_stylebox_override("separator", div2_sb)
	vbox.add_child(div2)

	var prog_hdr := Label.new()
	prog_hdr.text = "🏆 ПРОГРЕСС ЭКСПЕДИЦИЙ"
	prog_hdr.add_theme_font_size_override("font_size", 16)
	prog_hdr.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	vbox.add_child(prog_hdr)

	hub_overview_progress_lbl = Label.new()
	hub_overview_progress_lbl.add_theme_font_size_override("font_size", 14)
	hub_overview_progress_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(hub_overview_progress_lbl)

	_refresh_hub_overview()

func _refresh_hub_overview() -> void:
	if not hub_overview_team_vbox:
		return
	for c in hub_overview_team_vbox.get_children():
		hub_overview_team_vbox.remove_child(c)
		c.queue_free()

	for slot_idx in range(4):
		var char_id: String = ""
		if slot_idx < TeamConfig.team_members.size():
			var member_data = TeamConfig.team_members[slot_idx]
			if member_data is Dictionary:
				char_id = String(member_data.get("id", ""))

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(104, 148)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.clip_contents = true

		var card_sb := StyleBoxFlat.new()
		card_sb.set_corner_radius_all(8)
		card_sb.set_content_margin_all(8)

		if char_id != "":
			var unit := _create_dummy_unit_for_db(char_id)
			var elem: int = unit.element if unit else 0
			var elem_col: Color = CombatConstants.get_element_color(elem)
			var elem_lbl: String = CombatConstants.get_element_label(elem)
			var d_name: String = unit.display_name if unit else char_id
			var build := TeamConfig.get_saved_build(char_id)
			var e_lvl: int = int(build.get("eidolon", 0))

			card_sb.bg_color = Color(0.10, 0.12, 0.18, 0.88)
			card_sb.border_color = Color(elem_col.r, elem_col.g, elem_col.b, 0.65)
			card_sb.set_border_width_all(2)
			card.add_theme_stylebox_override("panel", card_sb)

			# Сплеш-арт на заднем фоне карточки слота
			var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
			if splash_tex != null:
				var splash_rect := TextureRect.new()
				splash_rect.name = "HubSlotSplashBG"
				splash_rect.texture = splash_tex
				splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				splash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				splash_rect.modulate = Color(0.40, 0.40, 0.46, 0.45)
				splash_rect.z_index = 0
				card.add_child(splash_rect)

			var card_vbox := VBoxContainer.new()
			card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_vbox.add_theme_constant_override("separation", 4)
			card_vbox.z_index = 1
			card.add_child(card_vbox)

			var top_row := HBoxContainer.new()
			top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_vbox.add_child(top_row)

			var slot_badge := Label.new()
			slot_badge.text = "[%d]" % (slot_idx + 1)
			slot_badge.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
			slot_badge.add_theme_font_size_override("font_size", 12)
			top_row.add_child(slot_badge)

			var sp := Control.new()
			sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top_row.add_child(sp)

			var elem_badge := Label.new()
			elem_badge.text = elem_lbl
			elem_badge.add_theme_color_override("font_color", elem_col)
			elem_badge.add_theme_font_size_override("font_size", 12)
			top_row.add_child(elem_badge)

			var name_lbl := Label.new()
			name_lbl.text = d_name
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_lbl.custom_minimum_size = Vector2(85, 0)
			name_lbl.add_theme_font_size_override("font_size", 13)
			card_vbox.add_child(name_lbl)

			var e_lbl := Label.new()
			e_lbl.text = "★ E%d" % e_lvl
			e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			e_lbl.add_theme_font_size_override("font_size", 11)
			e_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			card_vbox.add_child(e_lbl)
		else:
			card_sb.bg_color = Color(0.07, 0.08, 0.12, 0.50)
			card_sb.border_color = Color(0.25, 0.30, 0.40, 0.40)
			card_sb.set_border_width_all(1)
			card.add_theme_stylebox_override("panel", card_sb)

			var card_vbox := VBoxContainer.new()
			card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_vbox.add_theme_constant_override("separation", 6)
			card.add_child(card_vbox)

			var slot_badge := Label.new()
			slot_badge.text = "[%d]" % (slot_idx + 1)
			slot_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_badge.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
			slot_badge.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(slot_badge)

			var empty_lbl := Label.new()
			empty_lbl.text = "[Пусто]"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
			empty_lbl.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(empty_lbl)

		hub_overview_team_vbox.add_child(card)

	if hub_overview_progress_lbl:
		var completed: int = TeamConfig.completed_levels.size()
		var current_lvl: int = TeamConfig.current_level_progress
		var relic_cnt: int = TeamConfig.relic_inventory.size()
		hub_overview_progress_lbl.text = "• Доступный уровень: %d\n• Пройдено испытаний: %d\n• Реликвий в инвентаре: %d шт." % [current_lvl, completed, relic_cnt]

func _create_custom_button(text: String, parent: Control, min_size: Vector2, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)
	parent.add_child(btn)
	return btn

func _show_screen(screen_name: String) -> void:
	main_center_container.visible = (screen_name == "main")
	standard_hub_margin.visible = (screen_name == "hub")
	shop_screen.visible = (screen_name == "shop")
	inventory_screen.visible = (screen_name == "inventory")
	levels_screen.visible = (screen_name == "levels")
	characters_screen.visible = (screen_name == "characters")
	database_screen.visible = (screen_name == "database")
	gacha_screen.visible = (screen_name == "gacha")
	level_team_setup_screen.visible = (screen_name == "level_team_setup")
	if relic_farming_screen:
		relic_farming_screen.visible = (screen_name == "relic_farming")
	if memory_hall_screen:
		memory_hall_screen.visible = (screen_name == "memory_hall")
	if memory_hall_team_setup_screen:
		memory_hall_team_setup_screen.visible = (screen_name == "memory_hall_team_setup")
	
	if screen_name == "gacha":
		active_banner_idx = 0
		if banner_select_option:
			banner_select_option.select(0)
		_refresh_gacha_ui()

	if screen_name == "hub":
		_refresh_memory_hall_card()
		if btn_menu_relics:
			var title_lbl: Label = btn_menu_relics.get_meta("card_title_lbl", null)
			var icon_lbl: Label = btn_menu_relics.get_meta("card_icon_lbl", null)
			var sub_lbl: Label = btn_menu_relics.get_meta("card_sub_lbl", null)
			if TeamConfig.current_level_progress < 5 and not TeamConfig.menu_tutorial_completed:
				_set_hub_card_disabled(btn_menu_relics, true)
				btn_menu_relics.text = "🔒 Добыча реликвий (с 5 ур.)"
				if title_lbl: title_lbl.text = "ДОБЫЧА РЕЛИКВИЙ"
				if icon_lbl: icon_lbl.text = "🔒"
				if sub_lbl: sub_lbl.text = "Откроется с 5 уровня"
			else:
				btn_menu_relics.text = "🏺 Добыча реликвий"
				if title_lbl: title_lbl.text = "ДОБЫЧА РЕЛИКВИЙ"
				if icon_lbl: icon_lbl.text = "🏺"
				if sub_lbl: sub_lbl.text = "Пещеры коррозии & Планары"
				if not is_menu_tutorial:
					_set_hub_card_disabled(btn_menu_relics, false)
		if hub_overview_panel:
			hub_overview_panel.visible = not is_menu_tutorial
			if not is_menu_tutorial:
				_refresh_hub_overview()
		if not TeamConfig.menu_tutorial_completed and not is_menu_tutorial:
			_lock_hub_buttons(true)
		elif not is_menu_tutorial:
			_lock_hub_buttons(false)

		# Кнопка Уровней ВСЕГДА доступна в хабе вне обучения в меню!
		if not is_menu_tutorial:
			_set_hub_card_disabled(btn_menu_levels, false)
	_update_coins_display()
	
	# Управление фоновой музыкой меню: играет во всех разделах после "Начать игру", отключается на титульном экране ("main")
	if screen_name == "main":
		_stop_menu_bgm()
	else:
		_play_menu_bgm()

func _setup_menu_bgm() -> void:
	if _menu_bgm_player == null or not is_instance_valid(_menu_bgm_player):
		_menu_bgm_player = AudioStreamPlayer.new()
		_menu_bgm_player.name = "MenuBgmPlayer"
		_menu_bgm_player.bus = "Master"
		var stream: AudioStream = load("res://assets/audio/spellbound_dreamscape.mp3")
		if stream is AudioStreamMP3:
			stream.loop = true
		_menu_bgm_player.stream = stream
		_menu_bgm_player.volume_db = linear_to_db(0.75)
		add_child(_menu_bgm_player)

func _play_menu_bgm() -> void:
	_setup_menu_bgm()
	if is_instance_valid(_menu_bgm_player) and not _menu_bgm_player.playing and _menu_bgm_player.stream != null:
		_menu_bgm_player.play()

func _stop_menu_bgm() -> void:
	if is_instance_valid(_menu_bgm_player) and _menu_bgm_player.playing:
		_menu_bgm_player.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		_stop_menu_bgm()

func _update_coins_display() -> void:
	var txt := "💰 Монеты: %d" % TeamConfig.coins
	if hub_coins_pill_label:
		hub_coins_pill_label.text = str(TeamConfig.coins)
	if hub_shine_pill_label:
		hub_shine_pill_label.text = str(TeamConfig.shine)
	if hub_shards_pill_label:
		hub_shards_pill_label.text = str(TeamConfig.relic_shards)
	if coins_label and coins_label != hub_coins_pill_label:
		coins_label.text = txt
	if shop_coins_label:
		shop_coins_label.text = txt
	if shine_label:
		shine_label.text = "✨ Блеск Свечения: %d" % TeamConfig.shine

func _on_cloud_sync_completed(success: bool) -> void:
	if success:
		print("[MainMenu] Cloud sync completed! Refreshing UI with cloud state: coins=%d shine=%d" % [TeamConfig.coins, TeamConfig.shine])
		_update_coins_display()
		_refresh_hub_overview()
		if shop_screen and shop_screen.visible:
			_refresh_shop_ui()

# --- СЕКЦИЯ: БАЗА ДАННЫХ (ЭНЦИКЛОПЕДИЯ ПЕРСОНАЖЕЙ) ---

func _build_database_screen() -> void:
	database_screen = VBoxContainer.new()
	database_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	database_screen.add_theme_constant_override("separation", 10)
	database_screen.visible = false
	add_child(database_screen)

	var header := Label.new()
	header.text = "📚 БАЗА ДАННЫХ ПЕРСОНАЖЕЙ"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	database_screen.add_child(header)

	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 16)
	database_screen.add_child(main_hbox)

	# Левая колонка: Ростер абсолютно всех персонажей (Плавный скролл)
	var scroll_roster := SmoothScrollContainer.new()
	scroll_roster.custom_minimum_size = Vector2(280, 0)
	main_hbox.add_child(scroll_roster)

	db_roster_container = VBoxContainer.new()
	db_roster_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	db_roster_container.add_theme_constant_override("separation", 8)
	scroll_roster.add_child(db_roster_container)

	# Правая колонка: Подробная карточка выбранного героя (Плавный скролл)
	var scroll_details := SmoothScrollContainer.new()
	scroll_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(scroll_details)

	var details_vbox := VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 12)
	scroll_details.add_child(details_vbox)

	# 1. Баннер героя
	db_banner_panel = PanelContainer.new()
	var b_sb := StyleBoxFlat.new()
	b_sb.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	b_sb.border_color = Color(0.35, 0.45, 0.65, 0.8)
	b_sb.set_border_width_all(2)
	b_sb.set_corner_radius_all(12)
	b_sb.set_content_margin_all(14)
	db_banner_panel.add_theme_stylebox_override("panel", b_sb)
	details_vbox.add_child(db_banner_panel)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.add_theme_constant_override("separation", 8)
	db_banner_panel.add_child(banner_vbox)

	db_title_label = Label.new()
	db_title_label.add_theme_font_size_override("font_size", 22)
	db_title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	banner_vbox.add_child(db_title_label)

	var bio_panel := PanelContainer.new()
	var bio_sb := StyleBoxFlat.new()
	bio_sb.bg_color = Color(0.05, 0.06, 0.09, 0.6)
	bio_sb.set_corner_radius_all(8)
	bio_sb.set_content_margin_all(10)
	bio_panel.add_theme_stylebox_override("panel", bio_sb)
	banner_vbox.add_child(bio_panel)

	db_bio_label = Label.new()
	db_bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	db_bio_label.add_theme_font_size_override("font_size", 14)
	db_bio_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	bio_panel.add_child(db_bio_label)

	# 2. Карточка: Способности и Навыки
	var skills_card := _create_db_card("⚔ БОЕВЫЕ СПОСОБНОСТИ И НАВЫКИ", Color(0.4, 0.85, 1.0))
	details_vbox.add_child(skills_card)
	db_skills_text = _create_db_richtext()
	skills_card.get_child(0).add_child(db_skills_text)

	# 3. Карточка: Рекомендуемые союзники
	var allies_card := _create_db_card("👥 РЕКОМЕНДУЕМЫЕ СОЮЗНИКИ И СИНЕРГИИ", Color(0.95, 0.85, 0.4))
	details_vbox.add_child(allies_card)
	db_allies_text = _create_db_richtext()
	allies_card.get_child(0).add_child(db_allies_text)

	# 4. Карточка: Рекомендуемая экипировка (Двухколоночная)
	var equip_card := _create_db_card("🛡 РЕКОМЕНДУЕМАЯ ЭКИПИРОВКА", Color(0.35, 0.9, 0.6))
	details_vbox.add_child(equip_card)
	var equip_hbox := HBoxContainer.new()
	equip_hbox.add_theme_constant_override("separation", 16)
	equip_card.get_child(0).add_child(equip_hbox)

	var cones_col := VBoxContainer.new()
	cones_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_hbox.add_child(cones_col)
	var cones_hdr := Label.new()
	cones_hdr.text = "⚔ Световые конусы:"
	cones_hdr.add_theme_font_size_override("font_size", 15)
	cones_hdr.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	cones_col.add_child(cones_hdr)
	db_cones_text = _create_db_richtext()
	cones_col.add_child(db_cones_text)

	var relics_col := VBoxContainer.new()
	relics_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_hbox.add_child(relics_col)
	var relics_hdr := Label.new()
	relics_hdr.text = "🛡 Комплекты реликвий:"
	relics_hdr.add_theme_font_size_override("font_size", 15)
	relics_hdr.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	relics_col.add_child(relics_hdr)
	db_relics_text = _create_db_richtext()
	relics_col.add_child(db_relics_text)

	# 5. Карточка: Тактический совет
	var tip_card := _create_db_card("💡 ТАКТИЧЕСКИЙ СОВЕТ ПО БОЮ", Color(1.0, 0.8, 0.2))
	var tip_sb := tip_card.get_theme_stylebox("panel") as StyleBoxFlat
	if tip_sb:
		tip_sb.border_color = Color(0.95, 0.8, 0.2, 0.8)
		tip_sb.bg_color = Color(0.12, 0.10, 0.06, 0.95)
	details_vbox.add_child(tip_card)
	db_tip_text = _create_db_richtext()
	tip_card.get_child(0).add_child(db_tip_text)

	# Гарантированное сохранение кнопки Назад!
	btn_db_back = Button.new()
	btn_db_back.text = "↩ Назад в меню"
	btn_db_back.custom_minimum_size = Vector2(250, 48)
	btn_db_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_db_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and (menu_tut_step == 10 or menu_tut_step == 12):
			_run_menu_tut_step(11)
	)
	database_screen.add_child(btn_db_back)

func _create_db_card(title_txt: String, title_col: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.92)
	sb.border_color = Color(0.25, 0.35, 0.50, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var hdr := Label.new()
	hdr.text = title_txt
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", title_col)
	vbox.add_child(hdr)

	var sep := HSeparator.new()
	var sep_sb := StyleBoxLine.new()
	sep_sb.color = Color(title_col.r, title_col.g, title_col.b, 0.25)
	sep.add_theme_stylebox_override("separator", sep_sb)
	vbox.add_child(sep)

	return card

func _create_section_header(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	return lbl

func _create_db_richtext() -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.custom_minimum_size = Vector2(0, 70)
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.add_theme_font_size_override("normal_font_size", 15)
	return rtl

func _refresh_database_screen() -> void:
	for child in db_roster_container.get_children():
		child.queue_free()

	# Автоматически подгружаем ВСЕХ персонажей из CharacterRegistry!
	var all_chars := CharacterRegistry.get_available_characters()
	for char_data in all_chars:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var btn_sb := StyleBoxFlat.new()
		btn_sb.bg_color = Color(0.07, 0.09, 0.14, 0.92)
		btn_sb.border_color = Color(0.22, 0.30, 0.44, 0.7)
		btn_sb.set_border_width_all(1)
		btn_sb.set_corner_radius_all(8)
		btn_sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", btn_sb)
		
		var hover_sb := btn_sb.duplicate() as StyleBoxFlat
		hover_sb.border_color = Color(0.4, 0.6, 0.9, 0.9)
		hover_sb.bg_color = Color(0.10, 0.14, 0.22, 0.95)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", hover_sb)

		var hbox := HBoxContainer.new()
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 10)
		btn.add_child(hbox)

		var sym_lbl := Label.new()
		sym_lbl.text = CombatConstants.ELEMENT_SYMBOLS.get(char_data.element, "✦")
		sym_lbl.add_theme_font_size_override("font_size", 20)
		sym_lbl.custom_minimum_size = Vector2(28, 0)
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.add_theme_color_override("font_color", _get_element_color(char_data.element))
		hbox.add_child(sym_lbl)

		var text_vbox := VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_theme_constant_override("separation", 2)
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_vbox)

		var name_l := Label.new()
		name_l.text = char_data.name
		name_l.add_theme_font_size_override("font_size", 15)
		name_l.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		text_vbox.add_child(name_l)

		var stars_str := "★".repeat(char_data.rarity)
		var elem_name := String(CombatConstants.ELEMENT_NAMES.get(char_data.element, ""))
		var sub_l := Label.new()
		sub_l.text = "%s  •  %s  %s" % [elem_name, CharacterRegistry.get_path_name(char_data.path), stars_str]
		sub_l.add_theme_font_size_override("font_size", 12)
		sub_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if char_data.rarity >= 5 else Color(0.65, 0.75, 0.85))
		text_vbox.add_child(sub_l)

		btn.pressed.connect(_select_char_for_database.bind(char_data.id))
		db_roster_container.add_child(btn)

	if not all_chars.is_empty():
		_select_char_for_database(all_chars[0].id)

func _select_char_for_database(char_id: String) -> void:
	var data := CharacterRegistry.get_character(char_id)
	if data.is_empty():
		return

	var elem_name := String(CombatConstants.ELEMENT_NAMES.get(data.element, ""))
	var path_name := CharacterRegistry.get_path_name(data.path)
	var stars_str := "★".repeat(data.rarity)

	db_title_label.text = "%s %s  •  %s  •  %s  •  %s" % [
		CombatConstants.ELEMENT_SYMBOLS[data.element],
		data.name,
		elem_name,
		path_name,
		stars_str
	]
	
	if db_banner_panel:
		db_banner_panel.clip_contents = true
		var b_sb := db_banner_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if b_sb:
			b_sb.border_color = _get_element_color(data.element)
		var db_splash_bg: TextureRect = db_banner_panel.get_node_or_null("DbSplashBG") as TextureRect
		var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
		if splash_tex != null:
			if db_splash_bg == null:
				db_splash_bg = TextureRect.new()
				db_splash_bg.name = "DbSplashBG"
				db_splash_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				db_splash_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				db_splash_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
				db_splash_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				db_banner_panel.add_child(db_splash_bg)
				db_banner_panel.move_child(db_splash_bg, 0)
			db_splash_bg.texture = splash_tex
			db_splash_bg.modulate = Color(0.35, 0.35, 0.40, 0.28)
			db_splash_bg.visible = true
		elif db_splash_bg != null:
			db_splash_bg.visible = false
	
	db_bio_label.text = "« %s »" % data.description

	# Создаем временного тестового юнита и достаем его Навыки через BattleInfoProvider!
	var dummy_unit := _create_dummy_unit_for_db(char_id)
	if dummy_unit:
		db_skills_text.text = BattleInfoProvider.get_skills_text(dummy_unit)
	else:
		db_skills_text.text = "[color=gray]Информация об умениях формируется...[/color]"

	# Заготовки для рекомендаций (можно кастомизировать под любого героя)
	db_allies_text.text = _get_db_recommendation(char_id, "allies")
	db_cones_text.text = _get_db_recommendation(char_id, "cones")
	db_relics_text.text = _get_db_recommendation(char_id, "relics")
	db_tip_text.text = _get_db_recommendation(char_id, "tip")

# Фабрика создания тестовых сущностей для чтения описания навыков
func _create_dummy_unit_for_db(char_id: String) -> CombatUnit:
	match char_id:
		"vika": return VikaAbilities.create_unit(0)
		"marina": return MarinaAbilities.create_unit(0)
		"sara": return SaraAbilities.create_unit(0)
		"arseniy": return ArseniyAbilities.create_unit(0)
		"pusenkov": return PusenkovAbilities.create_unit(0)
		"kaori": return KaoriAbilities.create_unit(0)
		"shoji": return ShojiAbilities.create_unit(0)
		"dasha": return DashaAbilities.create_unit(0)
		"danill": return DanillAbilities.create_unit(0)
		"dotseva": return DotsevaAbilities.create_unit(0)
		"milena": return MilenaAbilities.create_unit(0)
		"naama": return NaamaAbilities.create_unit(0)
		"lenskaya": return LenskayaAbilities.create_unit(0)
		"rimes": return RimesAbilities.create_unit(0)
		"isaac": return IsaacAbilities.create_unit(0)
		"keloist": return KeloistAbilities.create_unit(0)
		"musienko": return MusienkoAbilities.create_unit(0)
		"joan": return JoanAbilities.create_unit(0)
		"jeff": return JeffAbilities.create_unit(0)
		"valramors": return ValramorsAbilities.create_unit(0)
		"joan_spirit": return JoanSpiritAbilities.create_unit(0)
		"isaac_admin": return IsaacAdminAbilities.create_unit(0)
		"sara_admin": return SaraAdminAbilities.create_unit(0)
		"arseniy_admin": return ArseniyAdminAbilities.create_unit(0)
		"dasha_admin": return DashaAdminAbilities.create_unit(0)
		"shoji_swan": return ShojiSwanAbilities.create_unit(0)
		"katarina": return KatarinaAbilities.create_unit(0)
		"dotseva_crimson_tears": return DotsevaCrimsonTearsAbilities.create_unit(0)
		"lenskaya_antimatter": return LenskayaAntimatterAbilities.create_unit(0)
		"velzebul": return VelzebulAbilities.create_unit(0)
		"marina_sky_guardian": return MarinaSkyGuardianAbilities.create_unit(0)
		"lenskaya_sky_guardian": return LenskayaSkyGuardianAbilities.create_unit(0)
		"rimes_ascension": return RimesAscensionAbilities.create_unit(0)
		"sanguinia": return SanguiniaAbilities.create_unit(0)
		
	return null

# База знаний рекомендаций для персонажей
# База знаний и рекомендаций для всех персонажей в игре
func _get_db_recommendation(char_id: String, type: String) -> String:
	var cr_rec := CharacterRegistry.get_recommendation(char_id, type)
	if not cr_rec.is_empty():
		return cr_rec
	match char_id:
		"vika":
			match type:
				"allies": return "• [color=gold]Валраморс[/color], [color=gold]Милена[/color], [color=gold]Данилл[/color], [color=gold]Сара[/color], [color=gold]Арсений[/color]"
				"cones": return "• [color=cyan]Падение мира неизбежно[/color] (Лучший)\n• [color=cyan]Пробуждение зверя[/color], [color=cyan]Апокалипсис[/color], [color=cyan]Живучесть[/color] (Альтернативы)"
				"relics": return "• [color=lightgreen]Истинный родоначальник хаоса[/color] (Лучший)\n• [color=lightgreen]Принявший грех глава[/color] (Альтернатива)"
				"tip": return "💡 [i]Используйте Навык E перед Сверхспособностью для максимизации урона от баффа Силы Атаки![/i]"
		"marina":
			match type:
				"allies": return "• [color=gold]Жоан[/color], [color=gold]Келойст[/color], [color=gold]Милена[/color], [color=gold]Доцева[/color], [color=gold]Сара[/color], [color=gold]Арсений[/color]"
				"cones": return "• [color=cyan]Мгновение счастья[/color], [color=cyan]В тёплых объятиях[/color], [color=cyan]База данных[/color]"
				"relics": return "• [color=lightgreen]Жертва долгого симбиоза[/color]"
				"tip": return "💡 [i]Марина может играть как Главный ДД, так и Сап-ДД. Экспериментируйте со сборками, чтобы найти лучший вариант![/i]"
		"sara":
			match type:
				"allies": return "• [color=gold]Все персонажи в игре[/color]"
				"cones": return "• [color=cyan]Распространение[/color], [color=cyan]Запах из медкабинета[/color]"
				"relics": return "• [color=lightgreen]Доктор биологических наук[/color]"
				"tip": return "💡 [i]Сверхспособность Сары позволяет союзникам избежать смерти и отлично лечит. Держите её до критического момента, когда у союзников мало здоровья![/i]"
		"arseniy":
			match type:
				"allies": return "• [color=gold]Вика[/color], [color=gold]Кирилл[/color], [color=gold]Каори[/color], [color=gold]Раймс[/color]"
				"cones": return "• [color=cyan]Коснись - и верни её в бодрствующий мир[/color], [color=cyan]Памятник тишине[/color], [color=cyan]Поместить в карантин[/color], [color=cyan]Колыбельная[/color]"
				"relics": return "• [color=lightgreen]Потерянное в вечности Я[/color] + [color=lightgreen]Исследователь отнятого будущего[/color] (2+2)"
				"tip": return "💡 [i]Арсений полезен только в состоянии «Новая разработка». Старайтесь, чтобы он находился в этом состоянии как можно чаще![/i]"
		"pusenkov":
			match type:
				"allies": return "• [color=gold]Айзек[/color], [color=gold]Валраморс[/color], [color=gold]Арсений[/color]"
				"cones": return "• [color=cyan]Я не могу тебя убить[/color], [color=cyan]Рубеж Бытия[/color], [color=cyan]Забудь прошлое Я[/color], [color=cyan]Нападение[/color]"
				"relics": return "• [color=lightgreen]Отряд быстрого реагирования[/color]"
				"tip": return "💡 [i]Кирилл — гиперкерри через Крит. урон против Боссов. Собирайте максимум КШ или активируйте синергию «Эмпирейцы 4»![/i]"
		"kaori":
			match type:
				"allies": return "• [color=gold]Вика[/color], [color=gold]Данилл[/color], [color=gold]Валраморс[/color], [color=gold]Арсений[/color]"
				"cones": return "• [color=cyan]Стрелы[/color], [color=cyan]Забудь прошлое Я[/color]"
				"relics": return "• [color=lightgreen]Отпор бренного мира[/color], [color=lightgreen]Отряд быстрого реагирования[/color]"
				"tip": return "💡 [i]Перед пробитием уязвимости мощной атакой (повторный Навык Е или повторный Ульт) старайтесь нажать Навык Q для максимизации урона![/i]"
		"shoji":
			match type:
				"allies": return "• [color=gold]Наама[/color], [color=gold]Джефф[/color], [color=gold]Валраморс[/color], [color=gold]Милена[/color], [color=gold]Арсений[/color], [color=gold]Марина (Е1)[/color]"
				"cones": return "• [color=cyan]Идеальный метаморфоз[/color], [color=cyan]Что есть реальность[/color], [color=cyan]Утечка[/color]"
				"relics": return "• [color=lightgreen]Потерянное в вечности Я[/color], [color=lightgreen]Боец огня и лавы[/color]"
				"tip": return "💡 [i]Сёдзи играет от Периодического урона (DoT). Старайтесь непрерывно поддерживать DoT-статусы на врагах![/i]"
		"dasha":
			match type:
				"allies": return "• [color=gold]Марина[/color], [color=gold]Милена[/color], [color=gold]Валраморс[/color]"
				"cones": return "• [color=cyan]Пробуждение зверя[/color], [color=cyan]Отголоски прошлого[/color], [color=cyan]Апокалипсис[/color]"
				"relics": return "• [color=lightgreen]Принявший дар света[/color], [color=lightgreen]Отпор бренного мира[/color]"
				"tip": return "💡 [i]Даша бьет Суперпробитием по пробитым врагам. Берите союзников, способных откладывать действия противников![/i]"
		"danill":
			match type:
				"allies": return "• [color=gold]Все персонажи в игре[/color]"
				"cones": return "• [color=cyan]Начало новой жизни[/color], [color=cyan]Стойкость / Напор[/color]"
				"relics": return "• [color=lightgreen]Оборона умирающей планеты[/color]"
				"tip": return "💡 [i]Для быстрого набора энергии Сверхспособности рекомендуется нажимать Навык Е для Провокации врагов![/i]"
		"dotseva":
			match type:
				"allies": return "• [color=gold]Жоан[/color], [color=gold]Айзек[/color], [color=gold]Милена[/color], [color=gold]Марина[/color], [color=gold]Арсений[/color], [color=gold]Келойст[/color], [color=gold]Сара[/color]"
				"cones": return "• [color=cyan]Басня о Багровых слезах[/color], [color=cyan]Мгновение счастья[/color], [color=cyan]Архив[/color]"
				"relics": return "• [color=lightgreen]Дающий луч надежды путник[/color], [color=lightgreen]Галилеянин изолированного мира[/color]"
				"tip": return "💡 [i]Доцева зависит от стаков Калибровки. Она безупречно показывает себя против толп врагов, но слабее против одиночных Боссов![/i]"
		"milena":
			match type:
				"allies": return "• [color=gold]Раймс[/color], [color=gold]Валраморс[/color] + все, кто играет от Силы атаки"
				"cones": return "• [color=cyan]Коснись - и верни её в бодрствующий мир[/color], [color=cyan]Колыбельная[/color], [color=cyan]Поместить в карантин[/color], [color=cyan]Я создам лучший мир[/color]"
				"relics": return "• [color=lightgreen]Исследователь отнятого будущего[/color], [color=lightgreen]Доктор биологических наук[/color]"
				"tip": return "💡 [i]Обновляйте статус «Обертон» Навыком Q, иначе придётся тратить в 2 раза больше ОН на повторный каст Навыка E![/i]"
		"naama":
			match type:
				"allies": return "• [color=gold]Сёдзи[/color], [color=gold]Джефф[/color], [color=gold]Милена[/color], [color=gold]Валраморс[/color]"
				"cones": return "• [color=cyan]Что есть реальность[/color], [color=cyan]Идеальный метаморфоз[/color]"
				"relics": return "• [color=lightgreen]Потерянное в вечности Я[/color], [color=lightgreen]Отряд быстрого реагирования[/color]"
				"tip": return "💡 [i]Нааме критически нужен Шанс Попадания Эффектов (ШПЭ), поэтому в реликвиях обязательно берите Тело на ШПЭ![/i]"
		"lenskaya":
			match type:
				"allies": return "• [color=gold]Сангиния Ял[/color], [color=gold]Жоан[/color], [color=gold]Доцева[/color], [color=gold]Джефф[/color], [color=gold]Валраморс[/color], [color=gold]Данилл[/color], [color=gold]Даша[/color], [color=gold]Мусиенко[/color]"
				"cones": return "• [color=cyan]План по спасению мира[/color], [color=cyan]Пробуждение зверя[/color], [color=cyan]Апокалипсис[/color]"
				"relics": return "• [color=lightgreen]Галилеянин[/color], [color=lightgreen]Погрязший в руинах Иркутск[/color], [color=lightgreen]Жертва долгого симбиоза[/color]"
				"tip": return "💡 [i]Ленской нужны союзники с Бонус-атаками для быстрого накопления стаков «Манипуляции»![/i]"
		"rimes":
			match type:
				"allies": return "• [color=gold]Валраморс[/color], [color=gold]Милена[/color], [color=gold]Арсений[/color], [color=gold]Айзек[/color], [color=gold]Данилл[/color]"
				"cones": return "• [color=cyan]Рубеж бытия[/color], [color=cyan]Я не могу тебя убить[/color], [color=cyan]Забудь прошлое Я[/color], [color=cyan]Нападение[/color], [color=cyan]Стрелы[/color]"
				"relics": return "• [color=lightgreen]Прячущийся во тьме Силуэт[/color], [color=lightgreen]Истинный родоначальник хаоса[/color]"
				"tip": return "💡 [i]Раймс уходит в «Изоляцию» с врагом. С ним не рекомендуется брать Сап-ДД, лучше сосредоточиться на баффах![/i]"
		"isaac":
			match type:
				"allies": return "• [color=gold]Сара[/color], [color=gold]Марина[/color], [color=gold]Кирилл[/color], [color=gold]Доцева[/color], [color=gold]Раймс[/color], [color=gold]Мусиенко[/color], [color=gold]Келойст[/color], [color=gold]Жоан[/color], [color=gold]Валраморс[/color]"
				"cones": return "• [color=cyan]Коснись - и верни её в бодрствующий мир[/color], [color=cyan]Поместить в карантин[/color], [color=cyan]Памятник тишине[/color], [color=cyan]Колыбельная[/color]"
				"relics": return "• [color=lightgreen]Исследователь отнятого будущего[/color], [color=lightgreen]Отряд быстрого реагирования[/color]"
				"tip": return "💡 [i]Айзек идеален с Крит-ДД. Нажимайте Навык Е на врага для максимизации КУ и собирайте синергию «Эмпирейцы 4»![/i]"
		"keloist":
			match type:
				"allies": return "• [color=gold]Марина[/color], [color=gold]Доцева[/color], [color=gold]Ленская[/color], [color=gold]Жоан[/color]"
				"cones": return "• [color=cyan]Басня о Багровых слезах[/color], [color=cyan]В тёплых объятиях[/color], [color=cyan]Архив[/color]"
				"relics": return "• [color=lightgreen]Боец огня и лавы[/color]"
				"tip": return "💡 [i]Келойсту нужны союзники Эрудиции. Накладывайте статус «Ортощит» на ДД и наблюдайте за автоматическими атаками Келойста![/i]"
		"musienko":
			match type:
				"allies": return "• [color=gold]Валраморс[/color], [color=gold]Милена[/color], [color=gold]Айзек[/color], [color=gold]Джефф[/color]"
				"cones": return "• [color=cyan]Падение мира неизбежно[/color], [color=cyan]Пробуждение зверя[/color], [color=cyan]Апокалипсис[/color]"
				"relics": return "• [color=lightgreen]Принявший грех глава[/color], [color=lightgreen]Боец огня и лавы[/color]"
				"tip": return "💡 [i]Урон Мусиенко скейлится от Макс. ХП. В Аннигиляции не повторяйте приемы подряд, чтобы накопить больше чистого урона![/i]"
		"joan":
			match type:
				"allies": return "• [color=gold]Марина[/color], [color=gold]Ленская[/color], [color=gold]Доцева[/color]"
				"cones": return "• [color=cyan]Забудь прошлое Я[/color], [color=cyan]Я не могу тебя убить[/color], [color=cyan]Нападение[/color]"
				"relics": return "• [color=lightgreen]Галилеянин изолированного мира[/color], [color=lightgreen]Принявший дар света[/color]"
				"tip": return "💡 [i]Жоан создан для баффа Эрудитов. Его Навык Е значительно повышает урон по одиночному врагу, а сам он частый FUA-атакер![/i]"
		"jeff":
			match type:
				"allies": return "• [color=gold]Сёдзи[/color], [color=gold]Наама[/color], [color=gold]Ленская[/color]"
				"cones": return "• [color=cyan]Запах из медкабинета[/color], [color=cyan]Распространение[/color]"
				"relics": return "• [color=lightgreen]Доктор биологических наук[/color], [color=lightgreen]Исследователь отнятого будущего[/color]"
				"tip": return "💡 [i]Джефф восстанавливает энергию пати и детонирует DoT. Ходите за союзников Базовой атакой для вызова его FUA![/i]"
		"valramors":
			match type:
				"allies": return "• [color=gold]Раймс[/color], [color=gold]Вика[/color], [color=gold]Кирилл[/color], [color=gold]Сёдзи[/color], [color=gold]Ленская[/color] + все гиперотряды"
				"cones": return "• [color=cyan]Идеальный метаморфоз[/color], [color=cyan]Танец при луне[/color], [color=cyan]Что есть реальность[/color], [color=cyan]Утечка[/color]"
				"relics": return "• [color=lightgreen]Прячущийся во тьме Силуэт[/color], [color=lightgreen]Истинный родоначальник хаоса[/color]"
				"tip": return "💡 [i]Валраморс — сильнейший дебаффер. Передавайте порчу через Навык Е перед атакой своего главного ДД![/i]"
		"joan_spirit":
			match type:
				"allies": return "• [color=gold]Марина[/color], [color=gold]Жоан[/color], [color=gold]Айзек[/color], [color=gold]Валраморс[/color], [color=gold]Милена[/color]"
				"cones": return "• [color=cyan]Солнце, что затмевает луну[/color], [color=cyan]Палящий взор[/color], [color=cyan]Пробуждение зверя[/color], [color=cyan]Апокалипсис[/color]"
				"relics": return "• [color=lightgreen]Дающий луч надежды путник[/color], [color=lightgreen]Другая сторона вселенной[/color]"
				"tip": return "💡 [i]Валраморс — сильнейший дебаффер. Передавайте порчу через Навык Е перед атакой своего главного ДД![/i]"
		"isaac_admin":
			match type:
				"allies": return "• [color=gold]Сара • Права администратора[/color], [color=gold]Даша • Права администратора[/color], [color=gold]Арсений • Права администратора[/color]"
				"cones": return "• [color=cyan]Момент, когда падают сервера[/color], [color=cyan]Отголоски прошлого[/color], [color=cyan]Что есть реальность[/color], [color=cyan]Утечка[/color]"
				"relics": return "• [color=lightgreen]Прячущийся во тьме Силуэт[/color], [color=lightgreen]Истинный родоначальник хаоса[/color]"
				"tip": return "💡 [i]Айзек • Права администратора – ядро команды Консоли. Старайтесь играть им вместе с другими союзниками Консоли, чтобы генерировать много Векторов![/i]"
		"sara_admin":
			match type:
				"allies": return "• [color=gold]Айзек • Права администратора[/color], [color=gold]Даша • Права администратора[/color], [color=gold]Арсений • Права администратораа[/color]"
				"cones": return "• [color=cyan]Повреждённое сохранение[/color], [color=cyan]Поместить в карантин[/color]"
				"relics": return "• [color=lightgreen]Исследователь отнятого будущего[/color], [color=lightgreen]Лаборатория сгинувшего края[/color]"
				"tip": return "💡 [i]Сара • Права администратора – лучший саппорт в команды Консоли. Она генерирует много Векторов, повышает бинарный урон и может заставить союзников Консоли принудительно активировать свой Навык Е.[/i]"
		"arseniy_admin":
			match type:
				"allies": return "• [color=gold]Айзек • Права администратора[/color], [color=gold]Сара • Права администратора[/color], [color=gold]Даша • Права администратораинистратора[/color]"
				"cones": return "• [color=cyan]Танец при луне[/color], [color=cyan]Что есть реальность[/color], [color=cyan]Утечка[/color]"
				"relics": return "• [color=lightgreen]2+ 2 Исследователь отнятого будущего + Потерянное в вечности Я[/color], [color=lightgreen]Лаборатория сгинувшего края[/color], [color=lightgreen]Сияющий Детройт[/color]"
				"tip": return "💡 [i]Арсений • Права администратора – дебаффер, лучше всего раскрывающийся в отрядах консоли. Бейте по врагам, защиту которых снизил Арсений • Права администратора, чтобы получать много Векторов![/i]"
		"dasha_admin":
			match type:
				"allies": return "• [color=gold]Айзек • Права администратора[/color], [color=gold]Сара • Права администратора[/color], [color=gold]Арсений • Права администратора[/color]"
				"cones": return "• [color=cyan]Начало новой жизни[/color], [color=cyan]Напор[/color], [color=cyan]Стойкость[/color]"
				"relics": return "• [color=lightgreen]Оборона умирающей планеты[/color], [color=lightgreen]Свободный остров Япония[/color]"
				"tip": return "💡 [i]Даша • Права администратора — щитовик, который сильно зависит от количества Векторов в команде. Старайтесь играть ей с союзниками, которые могут генерировать много Векторов![/i]"
		"shoji_swan":
			match type:
				"allies": return "• [color=gold]Сара • Права администратора[/color], [color=gold]Даша • Права администратора[/color], [color=gold]Арсений • Права администратора[/color] (Слот 1 ДД) / [color=gold]Любой гиперкерри[/color] (Слот 2-4 Саппорт)"
				"cones": return "• [color=cyan]Идеальный метаморфоз[/color], [color=cyan]Танец при луне[/color], [color=cyan]Что есть реальность[/color], [color=cyan]Утечка[/color]"
				"relics": return "• [color=lightgreen]Исследователь отнятого будущего[/color], [color=lightgreen]Лаборатория сгинувшего края[/color], [color=lightgreen]Сияющий Детройт[/color]"
				"tip": return "💡 [i]Сёдзи • Лебединое озеро меняет роль от позиции в отряде: в Слоте 1 она выступает как Бинарный мейн-ДД Консоли, а в Слотах 2–4 — как универсальный скоростной саппорт и дебаффер для не-Бинарных керри![/i]"
		"katarina":
			match type:
				"allies": return "• [color=gold]Доцева • Багровые слёзы[/color], [color=gold]Валраморс[/color], [color=gold]Сёдзи: Лебединое озеро[/color], [color=gold]Арсений: Лебединое озеро[/color], [color=gold]Милена[/color]"
				"cones": return "• [color=cyan]Почему ты вспомнила меня?[/color], [color=cyan]Танец при луне[/color], [color=cyan]Идеальный метаморфоз[/color]"
				"relics": return "• [color=lightgreen]2+2: Отпор бренного мира[/color], [color=lightgreen]Прячущийся во тьме силуэт[/color], [color=lightgreen]Сияющий Детройт[/color]"
				"tip": return "💡 [i]Катарине необходим союзник Пути Небытия для раскрытия бонуса Крит. урона от Следа 1! Старайтесь как можно быстрее пробивать пороги ХП врагов, чтобы союзники снимали статус «Сломленный дух» и высвобождали накопленный урон.[/i]"
		"dotseva_crimson_tears":
			match type:
				"allies": return "• [color=gold]Катарина[/color], [color=gold]Валраморс[/color], [color=gold]Арсений • Права администратора[/color], [color=gold]Сара • Права администратора[/color]"
				"cones": return "• [color=cyan]История, вымоченная в крови[/color], [color=cyan]Первые минуты войны[/color], [color=cyan]Начало новой жизни[/color]"
				"relics": return "• [color=lightgreen]Обитатель гибнущей планеты[/color], [color=lightgreen]Исследователь отнятого будущего[/color]"
				"tip": return "💡 [i]Поддерживайте защитную Зону Навыка E активной, чтобы перенаправлять урон с союзников и бесплатно применять Улучшенный Навык Q для исцеления всей команды![/i]"
		"lenskaya_antimatter":
			match type:
				"allies": return "• [color=gold]Вика[/color], [color=gold]Раймс[/color], [color=gold]Ленская[/color], [color=gold]Вельзевул[/color] (Фракция Антиматерия)"
				"cones": return "• [color=cyan]Падение мира неизбежно[/color], [color=cyan]Рубеж Бытия[/color], [color=cyan]Апокалипсис[/color]"
				"relics": return "• [color=lightgreen]Истинный родоначальник хаоса[/color], [color=lightgreen]Сияющий Детройт[/color]"
				"tip": return "💡 [i]Накапливайте Xaeroh для сокрушительного удара «Уничтожения сверхновой». В стойке «Воин небытия» используйте Навык E для ухода в Изнанку и последующей казни врагов Навыком Q![/i]"
		"velzebul":
			match type:
				"allies": return "• [color=gold]Ленская • Явление антиматерии[/color], [color=gold]Вика[/color], [color=gold]Раймс[/color], [color=gold]Ленская[/color]"
				"cones": return "• [color=cyan]Рубеж Бытия[/color], [color=cyan]Падение мира неизбежно[/color], [color=cyan]Лучший мир[/color]"
				"relics": return "• [color=lightgreen]Истинный родоначальник хаоса[/color], [color=lightgreen]Сияющий Детройт[/color]"
				"tip": return "💡 [i]Идеальный саппорт под Ленскую: Явление антиматерии и команду Антиматерии. В стойке «Подношение» используйте Усиленные базовые атаки, чтобы накопить 4 Грешных сердца, разблокировать Сверхспособность и активировать постоянный Усиленный Навык E с Печатью Вельзевула![/i]"
			
		_:
			match type:
				"allies": return "• [color=gray]Рекомендуемые союзники подбираются...[/color]"
				"cones": return "• [color=gray]Подходящие световые конусы подбираются...[/color]"
				"relics": return "• [color=gray]Рекомендуемый комплект реликвий подбирается...[/color]"
				"tip": return "💡 [i]Экспериментируйте с синергиями Фракций и подбором элементов под уязвимости противников![/i]"
	return "—"

# Список активных ивентовых 5★ баннеров
const BANNERS := [
	{"id": "velzebul", "name": "Вельзевул", "title": "🩸 Вельзевул (5★)"},
	{"id": "katarina", "name": "Катарина", "title": "⚔ Катарина (5★)"},
	{"id": "dotseva_crimson_tears", "name": "Доцева • Багровые слёзы", "title": "🩸 Доцева • Багровые слёзы (5★)"},
	{"id": "lenskaya_antimatter", "name": "Ленская • Явление антиматерии", "title": "🌌 Ленская • Явление антиматерии (5★)"},
	{"id": "dotseva", "name": "Юлия Доцева", "title": "🌟 Юлия Доцева (5★)"},
	{"id": "shoji", "name": "Сёдзи", "title": "🔥 Сёдзи (5★)"},
	{"id": "lenskaya", "name": "Ленская", "title": "❄ Ленская (5★)"},
	{"id": "rimes", "name": "Раймс", "title": "🌌 Раймс (5★)"},
	{"id": "musienko", "name": "Мусиенко", "title": "🌋 Мусиенко (5★)"},
	{"id": "valramors", "name": "Валраморс", "title": "🔮 Валраморс (5★)"},
	{"id": "joan_spirit", "name": "Жоан • Форма духа", "title": " Жоан • Форма духа (5★)"},
	{"id": "isaac_admin", "name": "Айзек • Права администратора", "title": "🔮 Айзек • Права администратора (5★)"},
	{"id": "sara_admin", "name": "Сара • Права администратора", "title": "🔮 Сара • Права администратора (5★)"},
	{"id": "shoji_swan", "name": "Сёдзи • Лебединое озеро", "title": "🦢 Сёдзи • Лебединое озеро (5★)"},
	{"id": "crimson_tears", "type": "weapon", "title": "⚔ Басня о Багровых слезах (5★ Конус)"},
	{"id": "perfect_metamorphosis", "type": "weapon", "title": "⚔ Идеальный Метаморфоз (5★ Конус)"},
	{"id": "save_the_world_plan", "type": "weapon", "title": "⚔ План по спасению мира (5★ Конус)"},
	{"id": "edge_of_existence", "type": "weapon", "title": "⚔ Рубеж Бытия (5★ Конус)"},
	{"id": "inevitable_fall", "type": "weapon", "title": "⚔ Падение мира неизбежно (5★ Конус)"},
	{"id": "corrupted_save", "type": "weapon", "title": "⚔ Повреждённое сохранение (5★ Конус)"},
	{"id": "server_crash_moment", "type": "weapon", "title": "⚔ Момент, когда падают сервера (5★ Конус)"},
	{"id": "history_soaked_in_blood", "type": "weapon", "title": "🩸 История, вымоченная в крови (5★ Конус)"},
	{"id": "why_did_you_remember_me", "type": "weapon", "title": "⚔ Почему ты вспомнила меня? (5★ Конус)"},
	{"id": "behind_the_curtains", "type": "weapon", "title": "🎭 Выход из-за кулис (5★ Конус)"},
	{"id": "i_will_become_god", "type": "weapon", "title": "👑 Я стану богом (5★ Конус)"},
	{"id": "let_past_stay_behind", "type": "weapon", "title": "⚔ Пусть прошлое остаётся позади (5★ Конус)"},
	{"id": "last_summer", "type": "weapon", "title": "🌸 Последнее лето (5★ Конус)"},
	{"id": "alone_again", "type": "weapon", "title": "🕊️ И вновь я один (5★ Конус)"}
]

const POOL_4LC := ["warm_embraces", "echoes_of_the_past", "forget_past_self", "better_world", "medical_smell", "what_is_reality", "new_life_start", "moon_dance", "quarantine", "first_minutes_of_war", "farewell_before_awakening"]

var active_banner_idx: int = 0
var banner_select_option: OptionButton

func _fill_options(opt: OptionButton, items: Array) -> void:
	opt.clear()
	for i in items.size():
		opt.add_item(items[i].name)
		opt.set_item_metadata(i, items[i].id)

func _fill_options_offset(opt: OptionButton, items: Array) -> void:
	for i in items.size():
		opt.add_item(items[i].name)
		opt.set_item_metadata(i + 1, items[i].id)
		
# --- МЕХАНИКА НАСТРОЙКИ СБОРОК ПЕРСОНАЖЕЙ ---

func _build_characters_screen() -> void:
	characters_screen = VBoxContainer.new()
	characters_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	characters_screen.add_theme_constant_override("separation", 10)
	characters_screen.visible = false
	add_child(characters_screen)

	var header := Label.new()
	header.text = "👤 Настройка Персонажей и Сборок"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	characters_screen.add_child(header)

	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 20)
	characters_screen.add_child(main_hbox)

	var scroll_roster := ScrollContainer.new()
	scroll_roster.custom_minimum_size = Vector2(250, 0)
	main_hbox.add_child(scroll_roster)

	char_build_roster_container = VBoxContainer.new()
	char_build_roster_container.add_theme_constant_override("separation", 8)
	scroll_roster.add_child(char_build_roster_container)

	var scroll_editor := SmoothScrollContainer.new()
	scroll_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(scroll_editor)

	build_editor_panel = VBoxContainer.new()
	build_editor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_editor_panel.add_theme_constant_override("separation", 12)
	scroll_editor.add_child(build_editor_panel)

	build_char_title = Label.new()
	build_char_title.add_theme_font_size_override("font_size", 22)
	build_char_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	build_editor_panel.add_child(build_char_title)

	opt_eidolon = OptionButton.new()
	opt_eidolon.add_item("E0 (По умолчанию)", 0)
	build_editor_panel.add_child(_create_form_row("Уровень Эйдолона:", opt_eidolon))

	opt_light_cone = OptionButton.new()
	btn_choose_light_cone = Button.new()
	btn_choose_light_cone.text = "🗡 Выбрать Световой Конус..."
	btn_choose_light_cone.custom_minimum_size = Vector2(320, 36)
	btn_choose_light_cone.add_theme_font_size_override("font_size", 14)
	btn_choose_light_cone.pressed.connect(func():
		_open_light_cone_selection_dialog(selected_char_for_build)
	)

	var lc_row_hbox := HBoxContainer.new()
	lc_row_hbox.add_theme_constant_override("separation", 10)
	lc_row_hbox.add_child(btn_choose_light_cone)
	opt_light_cone.visible = false
	lc_row_hbox.add_child(opt_light_cone)

	desc_light_cone = _create_info_box()
	build_editor_panel.add_child(_create_form_row("Световой Конус:", lc_row_hbox, desc_light_cone))

	var sep_relics := HSeparator.new()
	build_editor_panel.add_child(sep_relics)

	var relics_sec_label := Label.new()
	relics_sec_label.text = "🛡 Экипированные реликвии (Индивидуальные слоты):"
	relics_sec_label.add_theme_font_size_override("font_size", 18)
	relics_sec_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	build_editor_panel.add_child(relics_sec_label)

	var relics_main_hbox := HBoxContainer.new()
	relics_main_hbox.add_theme_constant_override("separation", 16)
	relics_main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_editor_panel.add_child(relics_main_hbox)

	# Левая часть (3/4): Сетка плиток реликвий
	char_equipped_relics_container = VBoxContainer.new()
	char_equipped_relics_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_equipped_relics_container.size_flags_stretch_ratio = 3.0
	char_equipped_relics_container.add_theme_constant_override("separation", 10)
	relics_main_hbox.add_child(char_equipped_relics_container)

	# Правая часть (1/4): Панель описания активных бонусов комплектов
	var sets_panel := PanelContainer.new()
	sets_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sets_panel.size_flags_stretch_ratio = 1.0
	sets_panel.custom_minimum_size = Vector2(240, 0)
	var sp_sb := StyleBoxFlat.new()
	sp_sb.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	sp_sb.border_color = Color(0.35, 0.45, 0.65, 0.8)
	sp_sb.set_border_width_all(1)
	sp_sb.set_corner_radius_all(10)
	sp_sb.content_margin_left = 14
	sp_sb.content_margin_right = 14
	sp_sb.content_margin_top = 12
	sp_sb.content_margin_bottom = 12
	sets_panel.add_theme_stylebox_override("panel", sp_sb)
	relics_main_hbox.add_child(sets_panel)

	var sets_vbox := VBoxContainer.new()
	sets_vbox.add_theme_constant_override("separation", 8)
	sets_panel.add_child(sets_vbox)

	var sets_title := Label.new()
	sets_title.text = "✨ Бонусы комплектов"
	sets_title.add_theme_font_size_override("font_size", 15)
	sets_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	sets_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sets_vbox.add_child(sets_title)

	var sets_sep := HSeparator.new()
	sets_vbox.add_child(sets_sep)

	char_active_sets_label = Label.new()
	char_active_sets_label.add_theme_font_size_override("font_size", 13)
	char_active_sets_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	char_active_sets_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sets_vbox.add_child(char_active_sets_label)

	opt_light_cone.item_selected.connect(func(_idx):
		var selected_id := String(opt_light_cone.get_item_metadata(opt_light_cone.selected))
		if not selected_id.is_empty():
			if not TeamConfig.can_equip_light_cone(selected_char_for_build, selected_id):
				var eq := TeamConfig.get_light_cone_equipped_characters(selected_id)
				if not eq.is_empty():
					_show_lc_transfer_confirm(selected_char_for_build, selected_id, eq, func():
						_update_lc_description()
						if is_menu_tutorial and menu_tut_step == 3 and selected_id == "apocalypse":
							_run_menu_tut_step(4)
					)
					return
		_update_lc_description()
		if is_menu_tutorial and menu_tut_step == 3:
			if selected_id == "apocalypse":
				_run_menu_tut_step(4)
	)

	btn_save_char_build = Button.new()
	btn_save_char_build.text = "💾 Сохранить сборку персонажа"
	btn_save_char_build.custom_minimum_size = Vector2(0, 48)
	btn_save_char_build.add_theme_font_size_override("font_size", 16)
	btn_save_char_build.pressed.connect(_save_current_char_build)
	build_editor_panel.add_child(btn_save_char_build)

	btn_char_back = Button.new()
	btn_char_back.text = "↩ Назад в меню"
	btn_char_back.custom_minimum_size = Vector2(250, 48)
	btn_char_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_char_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and (menu_tut_step == 10 or menu_tut_step == 102):
			_run_menu_tut_step(9)
	)
	characters_screen.add_child(btn_char_back)

func _create_form_row(label_text: String, control: Control, desc_box: RichTextLabel = null) -> VBoxContainer:
	var row_vbox := VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 4)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(lbl)

	control.custom_minimum_size = Vector2(320, 36)
	hbox.add_child(control)

	row_vbox.add_child(hbox)

	if desc_box:
		row_vbox.add_child(desc_box)

	return row_vbox

func _create_info_box() -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.custom_minimum_size = Vector2(420, 90)
	rtl.bbcode_enabled = true
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.add_theme_font_size_override("normal_font_size", 16)
	rtl.add_theme_font_size_override("bold_font_size", 16)
	rtl.add_theme_color_override("default_color", Color(0.75, 0.9, 1.0))
	return rtl

# Внутри _fill_cavern_sets_option() в main_menu.gd:
func _fill_cavern_sets_option(opt: OptionButton) -> void:
	var all_cavern_sets := [
		{"name": "Жертва долгого симбиоза", "id": "symbiosis", "req_level": 1},
		{"name": "Родоначальник хаоса", "id": "chaos", "req_level": 1},
		# Открываются после 6 уровня (progress >= 7):
		{"name": "Отпор бренного мира", "id": "mortal_world", "req_level": 7},
		{"name": "Боец огня и лавы", "id": "lava_fighter", "req_level": 7},
		{"name": "Принявший дар света", "id": "light_gift", "req_level": 7},
		{"name": "Дающий луч надежды путник", "id": "hope_beam", "req_level": 7},
		{"name": "Отряд быстрого реагирования", "id": "rapid_response", "req_level": 7},
		# Открываются после 9 уровня (progress >= 10):
		{"name": "Потерянное в вечности Я", "id": "lost_self", "req_level": 10},
		{"name": "Галилеянин", "id": "galilean", "req_level": 10},
		{"name": "Прячущийся во тьме силуэт", "id": "silhouette", "req_level": 10},
		# Будущие уровни:
		{"name": "Доктор биологических наук", "id": "biology_doctor", "req_level": 11},
		{"name": "Оборона умирающей планеты", "id": "dying_planet", "req_level": 11},
		{"name": "Принявший грех глава", "id": "accepted_sin", "req_level": 11},
		{"name": "Исследователь будущего", "id": "bereft_future", "req_level": 11},
		{"name": "След из повреждённых строк", "id": "damaged_strings", "req_level": 11},
		{"name": "Дитя умирающих звёзд", "id": "dying_stars_child", "req_level": 11},
		{"name": "Перебежщик тёмной стороны", "id": "dark_side_defector", "req_level": 11},
		{"name": "Защитница цветущей земли", "id": "bloom_defender", "req_level": 11}
	]
	opt.clear()
	var idx := 0
	for item in all_cavern_sets:
		var req_lvl: int = item.get("req_level", 1)
		if TeamConfig.current_level_progress >= req_lvl:
			opt.add_item(item.name)
			opt.set_item_metadata(idx, item.id)
			idx += 1
					
func _update_cavern_visibility() -> void:
	var sel: int = opt_cavern_type.selected
	var has_s1 := (sel > 0)
	var has_s2 := (sel == 2)

	row_cavern_set1.visible = has_s1
	row_cavern_set2.visible = has_s2

	if has_s1: _update_relic_description(opt_cavern_set1, desc_cavern_set1)
	if has_s2: _update_relic_description(opt_cavern_set2, desc_cavern_set2)

func _update_lc_description() -> void:
	var lc_id: String = String(opt_light_cone.get_item_metadata(opt_light_cone.selected))
	if btn_choose_light_cone and is_instance_valid(btn_choose_light_cone):
		if lc_id.is_empty():
			btn_choose_light_cone.text = "🗡 [Без оружия]  [Выбрать конус ▾]"
			btn_choose_light_cone.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			var cone_info: Dictionary = LightConeRegistry.get_cone(lc_id)
			var c_name: String = cone_info.get("name", lc_id)
			var c_rarity: int = int(cone_info.get("rarity", 3))
			var col: Color = Color(1.0, 0.85, 0.3) if c_rarity == 5 else (Color(0.8, 0.5, 1.0) if c_rarity == 4 else Color(0.4, 0.7, 1.0))
			btn_choose_light_cone.text = "🗡 %s (%d★)  [Сменить ▾]" % [c_name, c_rarity]
			btn_choose_light_cone.add_theme_color_override("font_color", col)

	if lc_id.is_empty():
		desc_light_cone.text = "[color=gray]Оружие не выбрано.[/color]"
		return

	var cone: Dictionary = LightConeRegistry.get_cone(lc_id)
	if not cone.is_empty():
		desc_light_cone.text = "⚔ [b]%s[/b] (%d★)\n%s" % [
			cone.get("name", "Конус"),
			cone.get("rarity", 3),
			cone.get("desc", "Описание отсутствует.")
		]

func _open_light_cone_selection_dialog(char_id: String) -> void:
	if char_id.is_empty():
		return
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

	# Header
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "🗡 Выбор Светового Конуса: %s (%s)" % [data.name, CharacterRegistry.get_path_name(data.path)]
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

	var cur_saved := TeamConfig.get_saved_build(char_id)
	var current_lc_id: String = String(cur_saved.get("light_cone", ""))

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
			TeamConfig.unequip_light_cone_from_character(char_id)
			_select_option_by_meta(opt_light_cone, "")
			_update_lc_description()
			overlay.queue_free()
		)
	unequip_hbox.add_child(unequip_btn)

	# 2. Список доступных конусов
	for lc in LightConeRegistry.LIST:
		if lc.path != data.path:
			continue
		var is_3star: bool = (int(lc.get("rarity", 3)) == 3)
		var total_copies: int = TeamConfig.get_light_cone_total_count(lc.id)
		if not is_3star and total_copies <= 0:
			continue

		var equipped_chars: Array[String] = TeamConfig.get_light_cone_equipped_characters(lc.id)
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
			wearers_names.append(ec_data.get("name", ec_id))
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
				TeamConfig.equip_light_cone_to_character(char_id, chosen_lc_id)
				_select_option_by_meta(opt_light_cone, chosen_lc_id)
				_update_lc_description()
				if is_menu_tutorial and menu_tut_step == 3 and chosen_lc_id == "apocalypse":
					_run_menu_tut_step(4)
				overlay.queue_free()
			)
		else:
			action_btn.text = "🔄 Перенести"
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
			var chosen_lc_id: String = lc.id
			var eq_copy: Array[String] = equipped_chars.duplicate()
			action_btn.pressed.connect(func():
				_show_lc_transfer_confirm(char_id, chosen_lc_id, eq_copy, func():
					_select_option_by_meta(opt_light_cone, chosen_lc_id)
					_update_lc_description()
					if is_menu_tutorial and menu_tut_step == 3 and chosen_lc_id == "apocalypse":
						_run_menu_tut_step(4)
					overlay.queue_free()
				)
			)
		card_hbox.add_child(action_btn)

func _show_lc_transfer_confirm(to_char_id: String, lc_id: String, from_chars: Array[String], on_confirmed: Callable) -> void:
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
			TeamConfig.equip_light_cone_to_character(to_char_id, lc_id, from_char_id)
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
				TeamConfig.equip_light_cone_to_character(to_char_id, lc_id, target_from)
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

func _update_relic_description(opt: OptionButton, target_label: RichTextLabel) -> void:
	var set_id: String = String(opt.get_item_metadata(opt.selected))
	if set_id.is_empty():
		target_label.text = "[color=gray]Комплект не выбран.[/color]"
		return

	if RELIC_DESCRIPTIONS.has(set_id):
		target_label.text = RELIC_DESCRIPTIONS[set_id]
	else:
		target_label.text = "[color=gray]Описание комплекта отсутствует.[/color]"

func _refresh_characters_screen() -> void:
	for child in char_build_roster_container.get_children():
		child.queue_free()

	if TeamConfig.unlocked_characters.is_empty():
		build_editor_panel.visible = false
		return

	for char_id in TeamConfig.unlocked_characters:
		var data := CharacterRegistry.get_character(char_id)
		if data.is_empty():
			continue

		var btn := Button.new()
		btn.text = "%s %s  [%s]" % [CombatConstants.ELEMENT_SYMBOLS[data.element], data.name, CombatConstants.get_element_name(data.element)]
		btn.custom_minimum_size = Vector2(230, 46)
		btn.pressed.connect(_select_char_for_build.bind(char_id))
		char_build_roster_container.add_child(btn)

	_select_char_for_build(TeamConfig.unlocked_characters[0])

func _select_char_for_build(char_id: String) -> void:
	selected_char_for_build = char_id
	var data := CharacterRegistry.get_character(char_id)
	if data.is_empty():
		return

	build_editor_panel.visible = true
	build_char_title.text = "Сборка: %s (%s)" % [data.name, CharacterRegistry.get_path_name(data.path)]

	var saved := TeamConfig.get_saved_build(char_id)
	var max_unlocked_e: int = int(saved.get("eidolon", 0))

	opt_eidolon.clear()
	for e in range(max_unlocked_e + 1):
		opt_eidolon.add_item("E%d %s" % [e, "(По умолчанию)" if e == 0 else ""], e)

	opt_light_cone.clear()
	opt_light_cone.add_item("Без оружия")
	opt_light_cone.set_item_metadata(0, "")
	var idx := 1
	for lc in LightConeRegistry.LIST:
		if lc.path == data.path and lc.id in TeamConfig.unlocked_light_cones:
			opt_light_cone.add_item("%s (%d★)" % [lc.name, lc.rarity])
			opt_light_cone.set_item_metadata(idx, lc.id)
			idx += 1

	var popup := opt_light_cone.get_popup()
	for i in opt_light_cone.item_count:
		var id_str := String(opt_light_cone.get_item_metadata(i))
		if not id_str.is_empty():
			var cone := LightConeRegistry.get_cone(id_str)
			if not cone.is_empty():
				popup.set_item_tooltip(i, "⚔ %s (%d★)\n\n%s" % [cone.get("name", ""), cone.get("rarity", 3), cone.get("desc", "")])

	_select_option_by_meta(opt_light_cone, saved.get("light_cone", ""))
	opt_eidolon.select(max_unlocked_e)

	_update_lc_description()
	_update_equipped_relics_ui(char_id)
	
func _select_option_by_meta(opt: OptionButton, meta_val: String) -> void:
	for i in opt.item_count:
		if String(opt.get_item_metadata(i)) == meta_val:
			opt.select(i)
			return
	opt.select(0)

func _save_current_char_build() -> void:
	if selected_char_for_build.is_empty():
		return

	var prev_build := TeamConfig.get_saved_build(selected_char_for_build)
	var existing_slots: Dictionary = prev_build.get("relics", {}).get("slots", {})

	var build_data := {
		"id": selected_char_for_build,
		"eidolon": opt_eidolon.selected,
		"light_cone": String(opt_light_cone.get_item_metadata(opt_light_cone.selected)),
		"relics": {
			"slots": existing_slots
		}
	}

	TeamConfig.set_saved_build(selected_char_for_build, build_data)
	TeamConfig.save_game()
	notification_label.text = "✓ Сборка сохранена!"

	if is_menu_tutorial and (menu_tut_step == 4 or menu_tut_step == 8 or menu_tut_step == 10):
		_run_menu_tut_step(102)

	# Сохранили сборку -> просим игрока выйти назад в главное меню!
	if is_menu_tutorial and menu_tut_step == 10:
		_run_menu_tut_step(102)
		
# --- МЕХАНИКА МАГАЗИНА И ИНВЕНТАРЯ ---

func _build_shop_screen() -> void:
	shop_screen = VBoxContainer.new()
	shop_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_screen.add_theme_constant_override("separation", 15)
	shop_screen.visible = false
	add_child(shop_screen)

	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_screen.add_child(top_bar)

	var header := Label.new()
	header.text = "🛒 Магазин Персонажей   |   "
	header.add_theme_font_size_override("font_size", 28)
	top_bar.add_child(header)

	shop_coins_label = Label.new()
	shop_coins_label.add_theme_font_size_override("font_size", 28)
	shop_coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_bar.add_child(shop_coins_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_screen.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	shop_grid = GridContainer.new()
	shop_grid.columns = 4
	shop_grid.add_theme_constant_override("h_separation", 20)
	shop_grid.add_theme_constant_override("v_separation", 20)
	center.add_child(shop_grid)

	btn_shop_back = Button.new()
	btn_shop_back.text = "↩ Назад в меню"
	btn_shop_back.custom_minimum_size = Vector2(250, 50)
	btn_shop_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_shop_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and menu_tut_step == 17:
			_run_menu_tut_step(18)
	)
	shop_screen.add_child(btn_shop_back)

func _refresh_shop_ui() -> void:
	if not shop_grid:
		return
	for child in shop_grid.get_children():
		child.queue_free()

	for char_id in SHOP_PRICES:
		var char_data := CharacterRegistry.get_character(char_id)
		if char_data.is_empty():
			continue

		var price: int = SHOP_PRICES[char_id]
		var is_owned: bool = char_id in TeamConfig.unlocked_characters
		var current_e: int = 0
		if is_owned:
			var build := TeamConfig.get_saved_build(char_id)
			current_e = int(build.get("eidolon", 0))

		var panel := PanelContainer.new()
		panel.name = "shop_char_" + char_id
		panel.custom_minimum_size = Vector2(180, 220)
		panel.clip_contents = true
		
		var is_5star := (int(char_data.get("rarity", 4)) >= 5)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(2)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		
		if is_5star:
			sb.bg_color = Color(0.24, 0.18, 0.08, 0.85) # полупрозрачный золотой фон
			sb.border_color = Color(0.95, 0.75, 0.25, 0.90) # золотистый бордюр
		else:
			sb.bg_color = Color(0.18, 0.10, 0.26, 0.85) # полупрозрачный фиолетовый фон
			sb.border_color = Color(0.75, 0.45, 0.95, 0.90) # фиолетовый бордюр
			
		panel.add_theme_stylebox_override("panel", sb)

		var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
		if splash_tex != null:
			var shop_bg := TextureRect.new()
			shop_bg.name = "ShopSplashBG"
			shop_bg.texture = splash_tex
			shop_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			shop_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			shop_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shop_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shop_bg.modulate = Color(0.40, 0.40, 0.45, 0.32)
			panel.add_child(shop_bg)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		panel.add_child(vbox)

		var name_lbl := Label.new()
		var e_suffix := " [E%d]" % current_e if is_owned else ""
		name_lbl.text = "%s%s\n(%d★)" % [char_data.name, e_suffix, char_data.rarity]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		if is_5star:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0))
		vbox.add_child(name_lbl)

		var path_badge := PanelContainer.new()
		path_badge.custom_minimum_size = Vector2(140, 32)
		var path_badge_sb := StyleBoxFlat.new()
		path_badge_sb.set_corner_radius_all(6)
		path_badge_sb.set_border_width_all(2)
		if is_5star:
			path_badge_sb.bg_color = Color(0.20, 0.16, 0.10, 0.90)
			path_badge_sb.border_color = Color(0.85, 0.68, 0.25, 0.75)
		else:
			path_badge_sb.bg_color = Color(0.14, 0.10, 0.22, 0.90)
			path_badge_sb.border_color = Color(0.65, 0.40, 0.85, 0.75)
		path_badge.add_theme_stylebox_override("panel", path_badge_sb)

		var desc_lbl := Label.new()
		desc_lbl.text = CharacterRegistry.get_path_full_label(char_data.path)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 14)
		if is_5star:
			desc_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
		else:
			desc_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 1.0))
		path_badge.add_child(desc_lbl)
		vbox.add_child(path_badge)

		var btn_buy := Button.new()
		btn_buy.custom_minimum_size = Vector2(0, 45)
		
		var btn_sb := StyleBoxFlat.new()
		btn_sb.set_corner_radius_all(8)
		btn_sb.set_border_width_all(1)
		if is_5star:
			btn_sb.bg_color = Color(0.35, 0.26, 0.12, 0.9)
			btn_sb.border_color = Color(0.95, 0.75, 0.25, 0.8)
			btn_buy.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		else:
			btn_sb.bg_color = Color(0.26, 0.15, 0.38, 0.9)
			btn_sb.border_color = Color(0.75, 0.45, 0.95, 0.8)
			btn_buy.add_theme_color_override("font_color", Color(0.90, 0.78, 1.0))
		btn_buy.add_theme_stylebox_override("normal", btn_sb)
		var btn_sb_h := btn_sb.duplicate() as StyleBoxFlat
		btn_sb_h.bg_color = btn_sb.bg_color.lightened(0.15)
		btn_buy.add_theme_stylebox_override("hover", btn_sb_h)
		
		if is_owned and current_e >= 6:
			btn_buy.text = "✓ Макс. E6"
			btn_buy.disabled = true
		elif is_owned:
			btn_buy.text = "Улучшить E%d (💰 %d)" % [current_e + 1, price]
			btn_buy.disabled = (TeamConfig.coins < price)
			btn_buy.pressed.connect(_buy_character.bind(char_id, price))
		else:
			btn_buy.text = "Купить (💰 %d)" % price
			btn_buy.disabled = (TeamConfig.coins < price)
			btn_buy.pressed.connect(_buy_character.bind(char_id, price))
		
		vbox.add_child(btn_buy)
		shop_grid.add_child(panel)

# Покупка персонажа / Улучшение Эйдолона с запуском гача-анимации
func _buy_character(char_id: String, price: int) -> void:
	if TeamConfig.coins < price:
		return

	var is_owned: bool = char_id in TeamConfig.unlocked_characters
	var build := TeamConfig.get_saved_build(char_id)
	var current_e: int = int(build.get("eidolon", 0))

	if is_owned and current_e >= 6:
		return

	TeamConfig.coins -= price

	var is_new := not is_owned
	var new_e := 0

	if is_new:
		TeamConfig.unlocked_characters.append(char_id)
		build["eidolon"] = 0
		new_e = 0
	else:
		new_e = current_e + 1
		build["eidolon"] = new_e

	TeamConfig.set_saved_build(char_id, build)
	TeamConfig.save_game()

	_update_coins_display()
	_refresh_shop_ui()
	
	var on_close_cb := Callable()
	if is_menu_tutorial and menu_tut_step == 16 and char_id == "arseniy":
		on_close_cb = func(): _run_menu_tut_step(17)
	
	# Запуск эффектной анимации получения героя!
	_show_character_unlock_animation(char_id, is_new, new_e, "", on_close_cb)


func _build_inventory_screen() -> void:
	inventory_screen = VBoxContainer.new()
	inventory_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_screen.add_theme_constant_override("separation", 15)
	inventory_screen.visible = false
	add_child(inventory_screen)

	var header := Label.new()
	header.text = "🎒 Инвентарь"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	inventory_screen.add_child(header)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	inventory_screen.add_child(tab_hbox)

	var btn_tab_chars := Button.new()
	btn_tab_chars.text = "👥 Персонажи"
	btn_tab_chars.custom_minimum_size = Vector2(160, 40)
	tab_hbox.add_child(btn_tab_chars)

	var btn_tab_cones := Button.new()
	btn_tab_cones.text = "⚔ Световые Конусы (3★)"
	btn_tab_cones.custom_minimum_size = Vector2(180, 40)
	tab_hbox.add_child(btn_tab_cones)

	btn_tab_relics = Button.new()
	btn_tab_relics.text = "🛡 Реликвии"
	btn_tab_relics.custom_minimum_size = Vector2(160, 40)
	tab_hbox.add_child(btn_tab_relics)

	var scroll := SmoothScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 450)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_screen.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	inv_characters_grid = GridContainer.new()
	inv_characters_grid.columns = 5
	inv_characters_grid.add_theme_constant_override("h_separation", 15)
	inv_characters_grid.add_theme_constant_override("v_separation", 15)
	center.add_child(inv_characters_grid)

	inv_cones_grid = GridContainer.new()
	inv_cones_grid.columns = 5
	inv_cones_grid.add_theme_constant_override("h_separation", 15)
	inv_cones_grid.add_theme_constant_override("v_separation", 15)
	inv_cones_grid.visible = false
	center.add_child(inv_cones_grid)

	inv_relics_container = VBoxContainer.new()
	inv_relics_container.add_theme_constant_override("separation", 12)
	inv_relics_container.visible = false
	center.add_child(inv_relics_container)

	# Фильтры реликвий
	var filters_hbox := HBoxContainer.new()
	filters_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	filters_hbox.add_theme_constant_override("separation", 15)
	inv_relics_container.add_child(filters_hbox)

	var lbl_slot := Label.new()
	lbl_slot.text = "Слот:"
	filters_hbox.add_child(lbl_slot)

	opt_inv_relic_slot_filter = OptionButton.new()
	opt_inv_relic_slot_filter.custom_minimum_size = Vector2(160, 36)
	opt_inv_relic_slot_filter.add_item("Все слоты", 0)
	opt_inv_relic_slot_filter.set_item_metadata(0, "")
	var s_idx := 1
	for slt in ["head", "hands", "body", "feet", "sphere", "rope"]:
		opt_inv_relic_slot_filter.add_item(RelicSystem.get_slot_name(slt), s_idx)
		opt_inv_relic_slot_filter.set_item_metadata(s_idx, slt)
		s_idx += 1
	opt_inv_relic_slot_filter.item_selected.connect(func(_idx): _refresh_inventory_relics())
	filters_hbox.add_child(opt_inv_relic_slot_filter)

	var lbl_rarity := Label.new()
	lbl_rarity.text = "Редкость:"
	filters_hbox.add_child(lbl_rarity)

	opt_inv_relic_rarity_filter = OptionButton.new()
	opt_inv_relic_rarity_filter.custom_minimum_size = Vector2(160, 36)
	opt_inv_relic_rarity_filter.add_item("Все редкости", 0)
	opt_inv_relic_rarity_filter.set_item_metadata(0, 0)
	opt_inv_relic_rarity_filter.add_item("5★ Золотые", 1)
	opt_inv_relic_rarity_filter.set_item_metadata(1, 5)
	opt_inv_relic_rarity_filter.add_item("4★ Фиолетовые", 2)
	opt_inv_relic_rarity_filter.set_item_metadata(2, 4)
	opt_inv_relic_rarity_filter.add_item("3★ Синие", 3)
	opt_inv_relic_rarity_filter.set_item_metadata(3, 3)
	opt_inv_relic_rarity_filter.item_selected.connect(func(_idx): _refresh_inventory_relics())
	filters_hbox.add_child(opt_inv_relic_rarity_filter)

	inv_relics_grid = GridContainer.new()
	inv_relics_grid.columns = 4
	inv_relics_grid.add_theme_constant_override("h_separation", 15)
	inv_relics_grid.add_theme_constant_override("v_separation", 15)
	inv_relics_container.add_child(inv_relics_grid)

	btn_tab_chars.pressed.connect(func():
		inv_characters_grid.visible = true
		inv_cones_grid.visible = false
		inv_relics_container.visible = false
	)
	btn_tab_cones.pressed.connect(func():
		inv_characters_grid.visible = false
		inv_cones_grid.visible = true
		inv_relics_container.visible = false
	)
	btn_tab_relics.pressed.connect(func():
		inv_characters_grid.visible = false
		inv_cones_grid.visible = false
		inv_relics_container.visible = true
		_refresh_inventory_relics()
		if is_menu_tutorial and menu_tut_step == 12:
			_run_menu_tut_step(13)
	)

	btn_inv_back = Button.new()
	btn_inv_back.text = "↩ Назад в меню"
	btn_inv_back.custom_minimum_size = Vector2(250, 50)
	btn_inv_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_inv_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and (menu_tut_step == 10 or menu_tut_step == 14 or menu_tut_step == 103):
			_run_menu_tut_step(15)
	)
	inventory_screen.add_child(btn_inv_back)

func _refresh_inventory_ui() -> void:
	for child in inv_characters_grid.get_children():
		child.queue_free()
	for child in inv_cones_grid.get_children():
		child.queue_free()

	# 1. Персонажи с выводом уровня Эйдолона
	for char_id in TeamConfig.unlocked_characters:
		var data := CharacterRegistry.get_character(char_id)
		if data.is_empty():
			continue

		var build := TeamConfig.get_saved_build(char_id)
		var e_lvl: int = int(build.get("eidolon", 0))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 165)
		btn.clip_contents = true
		btn.pressed.connect(_show_eidolon_details_modal.bind(char_id))

		# Сплеш-арт на заднем плане карточки персонажа в инвентаре
		var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
		if splash_tex != null:
			var bg_tex := TextureRect.new()
			bg_tex.name = "InvSplashBG"
			bg_tex.texture = splash_tex
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_tex.modulate = Color(0.38, 0.38, 0.45, 0.40)
			bg_tex.z_index = 0
			btn.add_child(bg_tex)

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 2)
		btn.add_child(vbox)

		var symbol := Label.new()
		symbol.text = CombatConstants.get_element_label(data.element)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.add_theme_font_size_override("font_size", 14)
		symbol.add_theme_color_override("font_color", CombatConstants.get_element_color(data.element))
		vbox.add_child(symbol)

		var name_lbl := Label.new()
		name_lbl.text = data.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(138, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(name_lbl)

		var e_lbl := Label.new()
		e_lbl.text = "★ E%d" % e_lvl
		e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_lbl.add_theme_font_size_override("font_size", 11)
		e_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		vbox.add_child(e_lbl)

		var info_hint := Label.new()
		info_hint.text = "[Подробнее]"
		info_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_hint.add_theme_font_size_override("font_size", 10)
		info_hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
		vbox.add_child(info_hint)

		inv_characters_grid.add_child(btn)

	# 2. Световые конусы
	for cone in LightConeRegistry.LIST:
		var is_3star: bool = (cone.rarity == 3)
		var total_copies: int = TeamConfig.get_light_cone_total_count(cone.id)
		var is_unlocked: bool = is_3star or (total_copies > 0)
		if not is_unlocked:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 160)
		btn.clip_contents = true
		btn.pressed.connect(_show_light_cone_details_modal.bind(cone.id))

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 4)
		btn.add_child(vbox)

		var icon := Label.new()
		icon.text = "⚔"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 28)
		vbox.add_child(icon)

		var name_lbl := Label.new()
		var count_str := (" (x%d)" % total_copies) if (not is_3star and total_copies > 1) else ""
		name_lbl.text = "%s\n(%d★)%s" % [cone.name, cone.rarity, count_str]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(130, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(name_lbl)

		var hint_lbl := Label.new()
		hint_lbl.text = "[Подробнее]"
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.add_theme_font_size_override("font_size", 10)
		hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
		vbox.add_child(hint_lbl)

		inv_cones_grid.add_child(btn)
		
# --- МЕХАНИКА КАРТЫ УРОВНЕЙ ---

func _build_levels_screen() -> void:
	if levels_screen and is_instance_valid(levels_screen):
		levels_screen.queue_free()

	levels_screen = VBoxContainer.new()
	levels_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	levels_screen.add_theme_constant_override("separation", 10)
	levels_screen.visible = false
	add_child(levels_screen)

	var header := Label.new()
	header.text = "🗺 Карта Уровней (Прокрутка вправо →)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	levels_screen.add_child(header)

	# Плавающий контейнер карты с круглой кнопкой поверх
	var map_wrapper := Control.new()
	map_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	levels_screen.add_child(map_wrapper)

	var scroll := SmoothScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_wrapper.add_child(scroll)

	var map_control := LevelMapControl.new()
	map_control.custom_minimum_size = Vector2(5300, 440)
	scroll.add_child(map_control)

	# Навигационная стрелка влево ◀
	var btn_arrow_left := Button.new()
	btn_arrow_left.text = "◀"
	btn_arrow_left.custom_minimum_size = Vector2(46, 70)
	btn_arrow_left.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	btn_arrow_left.offset_left = 12
	btn_arrow_left.offset_right = 58
	btn_arrow_left.offset_top = -35
	btn_arrow_left.offset_bottom = 35
	var sb_arr_l := StyleBoxFlat.new()
	sb_arr_l.bg_color = Color(0.12, 0.16, 0.24, 0.85)
	sb_arr_l.border_color = Color(0.3, 0.6, 1.0, 0.6)
	sb_arr_l.set_border_width_all(2)
	sb_arr_l.set_corner_radius_all(10)
	btn_arrow_left.add_theme_stylebox_override("normal", sb_arr_l)
	btn_arrow_left.add_theme_font_size_override("font_size", 22)
	btn_arrow_left.pressed.connect(func(): scroll.scroll_by(-250.0))
	map_wrapper.add_child(btn_arrow_left)

	# Навигационная стрелка вправо ▶
	var btn_arrow_right := Button.new()
	btn_arrow_right.text = "▶"
	btn_arrow_right.custom_minimum_size = Vector2(46, 70)
	btn_arrow_right.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	btn_arrow_right.offset_left = -58
	btn_arrow_right.offset_right = -12
	btn_arrow_right.offset_top = -35
	btn_arrow_right.offset_bottom = 35
	var sb_arr_r := StyleBoxFlat.new()
	sb_arr_r.bg_color = Color(0.12, 0.16, 0.24, 0.85)
	sb_arr_r.border_color = Color(0.3, 0.6, 1.0, 0.6)
	sb_arr_r.set_border_width_all(2)
	sb_arr_r.set_corner_radius_all(10)
	btn_arrow_right.add_theme_stylebox_override("normal", sb_arr_r)
	btn_arrow_right.add_theme_font_size_override("font_size", 22)
	btn_arrow_right.pressed.connect(func(): scroll.scroll_by(250.0))
	map_wrapper.add_child(btn_arrow_right)

	# Аккуратная круглая плавающая кнопка подарка 🎁 строго в правом нижнем углу!
	var gift_btn := Button.new()
	gift_btn.text = "🎁"
	gift_btn.custom_minimum_size = Vector2(64, 64)
	gift_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gift_btn.offset_left = -90
	gift_btn.offset_right = -26
	gift_btn.offset_top = -90
	gift_btn.offset_bottom = -26
	
	var gift_sb := StyleBoxFlat.new()
	gift_sb.bg_color = Color(0.15, 0.55, 0.95, 1.0)
	gift_sb.border_color = Color(1.0, 0.85, 0.3, 1.0)
	gift_sb.set_border_width_all(2)
	gift_sb.set_corner_radius_all(32) # Идеальный круг
	gift_btn.add_theme_stylebox_override("normal", gift_sb)
	gift_btn.add_theme_font_size_override("font_size", 28)
	gift_btn.pressed.connect(_show_star_rewards_modal)
	map_wrapper.add_child(gift_btn)

	# Нижняя панель
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	levels_screen.add_child(btn_hbox)

	if TeamConfig.current_level_progress < 4 and not "level_3" in TeamConfig.completed_levels and not TeamConfig.tutorial_skipped:
		var btn_skip_tut := Button.new()
		btn_skip_tut.text = "⏩ Пропустить обучение"
		btn_skip_tut.custom_minimum_size = Vector2(220, 48)
		btn_skip_tut.add_theme_font_size_override("font_size", 16)
		btn_skip_tut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		btn_skip_tut.pressed.connect(_show_skip_tutorial_confirmation_dialog)
		btn_hbox.add_child(btn_skip_tut)

	var btn_levels_shop := Button.new()
	btn_levels_shop.text = "🛒 Магазин"
	btn_levels_shop.custom_minimum_size = Vector2(180, 48)
	btn_levels_shop.add_theme_font_size_override("font_size", 16)
	btn_levels_shop.pressed.connect(func():
		_refresh_shop_ui()
		_show_screen("shop")
	)
	btn_hbox.add_child(btn_levels_shop)

	btn_levels_back = Button.new()
	btn_levels_back.text = "↩ Назад в меню"
	btn_levels_back.custom_minimum_size = Vector2(200, 48)
	btn_levels_back.add_theme_font_size_override("font_size", 16)
	btn_levels_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and menu_tut_step == 1:
			_run_menu_tut_step(2)
	)
	btn_hbox.add_child(btn_levels_back)
	
# --- ОБРАБОТЧИКИ КНОПОК И СБРОСА ---

func _on_save_pressed() -> void:
	if TeamConfig.save_game():
		notification_label.text = "✓ Игра успешно сохранена!"
	else:
		notification_label.text = "❌ Ошибка сохранения."

func _on_load_pressed() -> void:
	if TeamConfig.load_game():
		_update_coins_display()
		_show_screen("hub")
		notification_label.text = "✓ Сохранение загружено!"
	else:
		print("Файл сохранения не найден.")

func _show_reset_confirmation_dialog() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 220)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "⚠ СБРОС ИГРОВОГО ПРОГРЕССА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(title)
	
	var msg := Label.new()
	msg.text = "Вы уверены? Весь ваш прогресс (монеты, купленные персонажи, сборки и пройденные уровни) будет полностью удалён!"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)
	
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var confirm_btn := Button.new()
	confirm_btn.text = "Да, сбросить всё"
	confirm_btn.custom_minimum_size = Vector2(180, 48)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	confirm_btn.pressed.connect(func():
		is_menu_tutorial = false
		menu_tut_step = 0
		if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
			menu_guide_overlay.queue_free()
			menu_guide_overlay = null
		TeamConfig.reset_all_progress()
		if has_node("/root/NetworkManager"):
			var nm = get_node("/root/NetworkManager")
			if nm:
				if nm.auth and nm.auth.is_anonymous:
					nm.auth.sign_out()
					nm.auth.sign_in_anonymously()
				elif nm.promo:
					nm.promo.reset_all_redeemed_codes()
		_update_coins_display()
		_build_levels_screen() # Перерисовываем карту (кнопка пропуска снова вернется!)
		_lock_hub_buttons(true)
		_set_hub_card_disabled(btn_menu_levels, false)
		overlay.queue_free()
		notification_label.text = "🔥 Прогресс полностью сброшен!"
	)
	btn_hbox.add_child(confirm_btn)
	
	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(140, 48)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_hbox.add_child(cancel_btn)

# --- ВНУТРЕННИЙ КЛАСС КАРТЫ УРОВНЕЙ ---

# --- ВНУТРЕННИЙ КЛАСС КАРТЫ УРОВНЕЙ ---

# --- ВНУТРЕННИЙ КЛАСС КАРТЫ УРОВНЕЙ (ЗВЕЗДЫ ТОЛЬКО С 7 УРОВНЯ) ---

class LevelMapControl extends Control:
	var points: Array[Vector2] = []

	func _ready() -> void:
		points.clear()
		for i in 30:
			var x := 120.0 + float(i) * 170.0
			var y := 220.0 + sin(float(i) * 0.9) * 100.0
			points.append(Vector2(x, y))

		for i in points.size():
			var level_num := i + 1
			var btn := Button.new()
			btn.text = str(level_num)
			btn.custom_minimum_size = Vector2(60, 60)
			btn.position = points[i] - Vector2(30, 30)
			
			var is_unlocked := (level_num <= TeamConfig.current_level_progress)
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(30)
			
			if is_unlocked:
				var is_current := (level_num == TeamConfig.current_level_progress)
				sb.bg_color = Color(0.18, 0.45, 0.90) if is_current else Color(0.12, 0.55, 0.35)
				sb.border_color = Color(0.5, 0.8, 1.0) if is_current else Color(0.4, 0.85, 0.5)
				sb.set_border_width_all(2)
				btn.add_theme_stylebox_override("normal", sb)
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.disabled = false
			else:
				sb.bg_color = Color(0.04, 0.05, 0.08, 0.92)
				sb.border_color = Color(0.12, 0.14, 0.18, 0.50)
				sb.set_border_width_all(1)
				btn.add_theme_stylebox_override("disabled", sb)
				btn.add_theme_color_override("font_disabled_color", Color(0.24, 0.27, 0.35, 0.45))
				btn.disabled = true
			
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(func(): _on_level_selected(level_num))
			add_child(btn)

			# Отображение Звёздочек СТРОГО начиная с 7 Уровня!
			if level_num >= 7:
				var stars_label := RichTextLabel.new()
				stars_label.custom_minimum_size = Vector2(90, 24)
				stars_label.position = points[i] + Vector2(-45, 34)
				stars_label.bbcode_enabled = true
				stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

				var earned_stars: int = int(TeamConfig.level_stars.get("level_%d" % level_num, 0))

				match earned_stars:
					3: stars_label.text = "[center][color=gold]★ ★ ★[/color][/center]"
					2: stars_label.text = "[center][color=gold]★ ★[/color] [color=gray]★[/color][/center]"
					1: stars_label.text = "[center][color=gold]★[/color] [color=gray]★ ★[/color][/center]"
					_: stars_label.text = "[center][color=gray]★ ★ ★[/color][/center]"

				add_child(stars_label)

	func _on_level_selected(level_num: int) -> void:
		if level_num > TeamConfig.current_level_progress:
			print("Уровень %d пока заблокирован!" % level_num)
			return

		if level_num == 1:
			TeamConfig.reset()
			TeamConfig.battle_mode = "level_1"
			TeamConfig.team_members = [
				TeamConfig.get_saved_build("vika")
			]
			get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
			
		elif level_num == 2:
			TeamConfig.reset()
			TeamConfig.battle_mode = "level_2"
			TeamConfig.team_members = [
				TeamConfig.get_saved_build("vika"),
				TeamConfig.get_saved_build("danill")
			]
			get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

		elif level_num == 3:
			TeamConfig.reset()
			TeamConfig.battle_mode = "level_3"
			TeamConfig.team_members = [
				TeamConfig.get_saved_build("kaori"),
				TeamConfig.get_saved_build("danill"),
				TeamConfig.get_saved_build("vika")
			]
			TeamConfig.battle_initiator_id = "kaori"
			get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

		elif level_num == 4:
			TeamConfig.reset()
			TeamConfig.battle_mode = "level_4"
			TeamConfig.team_members = [
				TeamConfig.get_saved_build("vika"),
				TeamConfig.get_saved_build("danill"),
				TeamConfig.get_saved_build("kaori")
			]
			get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

		else:
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("_open_level_team_setup"):
				main_scene._open_level_team_setup(level_num)

	func _draw() -> void:
		if points.size() > 1:
			draw_polyline(PackedVector2Array(points), Color(0.4, 0.6, 0.9, 0.8), 6.0, true)
			
# Модальное окно просмотра всех Эйдолонов (E1 - E6) персонажа
func _show_eidolon_details_modal(char_id: String) -> void:
	var char_data := CharacterRegistry.get_character(char_id)
	if char_data.is_empty():
		return

	var build := TeamConfig.get_saved_build(char_id)
	var unlocked_e: int = int(build.get("eidolon", 0))

	var overlay := ColorRect.new()
	overlay.name = "EidolonDetailsModal"
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.z_as_relative = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "ModalPanel"
	panel.custom_minimum_size = Vector2(600, 530)
	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.08, 0.10, 0.16, 1.0)
	p_sb.border_color = Color(0.35, 0.50, 0.75, 1.0)
	p_sb.set_border_width_all(2)
	p_sb.set_corner_radius_all(14)
	p_sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", p_sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "✨ Эйдолоны: %s [Разблокировано: E%d]" % [char_data.name, unlocked_e]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var e_list_vbox := VBoxContainer.new()
	e_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(e_list_vbox)

	var char_e_data: Dictionary = EIDOLON_DESCRIPTIONS.get(char_id, {})

	for e_num in range(1, 7):
		var e_key := "E%d" % e_num
		var is_active := (e_num <= unlocked_e)
		
		var desc: String = char_e_data.get(e_key, "")
		if desc.is_empty():
			if e_num == 3:
				desc = "Увеличивает урон и уровни Базовой атаки и Навыков на 20%."
			elif e_num == 5:
				desc = "Увеличивает урон и уровни Таланта и Сверхспособности на 20%."
			else:
				desc = "Информация об Эйдолоне формируется..."

		var rtl := RichTextLabel.new()
		rtl.custom_minimum_size = Vector2(0, 50)
		rtl.fit_content = true
		rtl.bbcode_enabled = true
		rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rtl.add_theme_font_size_override("normal_font_size", 14)

		if is_active:
			rtl.text = "[color=gold]★ %s (АКТИВЕН):[/color]\n%s" % [e_key, desc]
		else:
			rtl.text = "[color=gray]🔒 %s (Заблокирован):[/color]\n[color=gray]%s[/color]" % [e_key, desc]

		e_list_vbox.add_child(rtl)
		e_list_vbox.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(180, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

# Модальное окно детального просмотра светового конуса
func _show_light_cone_details_modal(cone_id: String) -> void:
	var cone := LightConeRegistry.get_cone(cone_id)
	if cone.is_empty():
		return

	var is_3star: bool = (int(cone.get("rarity", 3)) == 3)
	var total_copies: int = TeamConfig.get_light_cone_total_count(cone_id)
	var rarity: int = int(cone.get("rarity", 3))

	var overlay := ColorRect.new()
	overlay.name = "LightConeDetailsModal"
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.z_as_relative = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "ModalPanel"
	panel.custom_minimum_size = Vector2(580, 480)
	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.08, 0.10, 0.16, 1.0)
	var border_col := Color(0.95, 0.80, 0.3) if rarity == 5 else (Color(0.75, 0.45, 0.95) if rarity == 4 else Color(0.35, 0.55, 0.85))
	p_sb.border_color = border_col
	p_sb.set_border_width_all(2)
	p_sb.set_corner_radius_all(14)
	p_sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", p_sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚔ %s (%d★)" % [cone.get("name", "Световой конус"), rarity]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", border_col)
	vbox.add_child(title)

	var path_val: int = int(cone.get("path", 0))
	var path_name := CharacterRegistry.get_path_name(path_val)
	var meta_row := HBoxContainer.new()
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 20)
	vbox.add_child(meta_row)

	var path_lbl := Label.new()
	path_lbl.text = "Путь: %s" % path_name
	path_lbl.add_theme_font_size_override("font_size", 14)
	path_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	meta_row.add_child(path_lbl)

	var copies_lbl := Label.new()
	if is_3star:
		copies_lbl.text = "Количество: Базовый конус (∞)"
	else:
		copies_lbl.text = "В наличии: %d шт." % total_copies
	copies_lbl.add_theme_font_size_override("font_size", 14)
	copies_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
	meta_row.add_child(copies_lbl)

	var desc_box := PanelContainer.new()
	desc_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var db_sb := StyleBoxFlat.new()
	db_sb.bg_color = Color(0.05, 0.06, 0.10, 0.9)
	db_sb.border_color = Color(0.25, 0.32, 0.45, 0.6)
	db_sb.set_border_width_all(1)
	db_sb.set_corner_radius_all(8)
	db_sb.set_content_margin_all(16)
	desc_box.add_theme_stylebox_override("panel", db_sb)
	vbox.add_child(desc_box)

	var desc_scroll := ScrollContainer.new()
	desc_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desc_box.add_child(desc_scroll)

	var desc_lbl := RichTextLabel.new()
	desc_lbl.name = "ConeDescText"
	desc_lbl.bbcode_enabled = true
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.fit_content = true
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("normal_font_size", 15)
	desc_lbl.text = "[b]Пассивный навык:[/b]\n\n" + cone.get("desc", "Описание отсутствует.")
	desc_scroll.add_child(desc_lbl)

	# Определение, на кого надет конус
	var wearers_names: Array[String] = []
	for c_id in TeamConfig.unlocked_characters:
		var b := TeamConfig.get_saved_build(c_id)
		if b.get("light_cone", "") == cone_id:
			var c_data := CharacterRegistry.get_character(c_id)
			wearers_names.append(c_data.get("name", c_id))

	var equip_status_lbl := RichTextLabel.new()
	equip_status_lbl.name = "ConeCarrierText"
	equip_status_lbl.bbcode_enabled = true
	equip_status_lbl.fit_content = true
	equip_status_lbl.add_theme_font_size_override("normal_font_size", 14)
	if not wearers_names.is_empty():
		equip_status_lbl.text = "🛡 [b]Надет на персонажей:[/b] [color=gold]%s[/color]" % (", ".join(wearers_names))
	else:
		equip_status_lbl.text = "✨ [color=lightgreen][b]Свободен[/b] (не надет ни на одного персонажа)[/color]"
	vbox.add_child(equip_status_lbl)

	var close_modal_btn := Button.new()
	close_modal_btn.text = "Закрыть"
	close_modal_btn.custom_minimum_size = Vector2(180, 42)
	close_modal_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_modal_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_modal_btn)

# --- СЕКЦИЯ: СИСТЕМА ГАЧИ ---

func _build_gacha_screen() -> void:
	gacha_screen = VBoxContainer.new()
	gacha_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gacha_screen.add_theme_constant_override("separation", 12)
	gacha_screen.visible = false
	add_child(gacha_screen)

	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	gacha_screen.add_child(top_bar)

	var header := Label.new()
	header.text = "✨ Гача Баннеры   |   "
	header.add_theme_font_size_override("font_size", 26)
	top_bar.add_child(header)

	shine_label = Label.new()
	shine_label.add_theme_font_size_override("font_size", 26)
	shine_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	top_bar.add_child(shine_label)

	# Выпадающий переключатель баннеров
	var sel_hbox := HBoxContainer.new()
	sel_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sel_hbox.add_theme_constant_override("separation", 10)
	gacha_screen.add_child(sel_hbox)

	var sel_lbl := Label.new()
	sel_lbl.text = "Выберите баннер:"
	sel_lbl.add_theme_font_size_override("font_size", 16)
	sel_hbox.add_child(sel_lbl)

	banner_select_option = OptionButton.new()
	banner_select_option.custom_minimum_size = Vector2(300, 42)
	for i in BANNERS.size():
		banner_select_option.add_item(BANNERS[i].title, i)
	banner_select_option.item_selected.connect(func(idx):
		active_banner_idx = idx
		_refresh_gacha_ui()
	)
	sel_hbox.add_child(banner_select_option)

	# Панель вывода баннера
	var banner_center := CenterContainer.new()
	banner_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gacha_screen.add_child(banner_center)

	var banner_panel := PanelContainer.new()
	banner_panel.name = "BannerPanel"
	banner_panel.custom_minimum_size = Vector2(750, 360)
	banner_panel.clip_contents = true
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	banner_panel.add_theme_stylebox_override("panel", sb)
	banner_center.add_child(banner_panel)

	var b_vbox := VBoxContainer.new()
	b_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	b_vbox.add_theme_constant_override("separation", 14)
	banner_panel.add_child(b_vbox)

	var b_title := Label.new()
	b_title.name = "BannerTitle"
	b_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_title.add_theme_font_size_override("font_size", 34)
	b_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	b_vbox.add_child(b_title)

	var b_sub := Label.new()
	b_sub.text = "[ ПОВЫШЕННЫЙ ШАНС! ]"
	b_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_sub.add_theme_font_size_override("font_size", 18)
	b_sub.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	b_vbox.add_child(b_sub)

	gacha_info_label = Label.new()
	gacha_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gacha_info_label.add_theme_font_size_override("font_size", 15)
	gacha_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	b_vbox.add_child(gacha_info_label)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	b_vbox.add_child(btn_hbox)

	var btn_pull_1 := Button.new()
	btn_pull_1.name = "BtnPull1"
	btn_pull_1.text = "1 раз (1 ✨)"
	btn_pull_1.custom_minimum_size = Vector2(200, 50)
	btn_pull_1.add_theme_font_size_override("font_size", 18)
	btn_pull_1.pressed.connect(func(): _execute_gacha_pulls(1))
	btn_hbox.add_child(btn_pull_1)

	var btn_pull_10 := Button.new()
	btn_pull_10.name = "BtnPull10"
	btn_pull_10.text = "10 раз (10 ✨)"
	btn_pull_10.custom_minimum_size = Vector2(200, 50)
	btn_pull_10.add_theme_font_size_override("font_size", 18)
	btn_pull_10.pressed.connect(func(): _execute_gacha_pulls(10))
	btn_hbox.add_child(btn_pull_10)

	var btn_back := Button.new()
	btn_back.name = "BtnGachaBack"
	btn_back.text = "↩ Назад в меню"
	btn_back.custom_minimum_size = Vector2(250, 48)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.pressed.connect(func(): _show_screen("hub"))
	gacha_screen.add_child(btn_back)

func _refresh_gacha_ui() -> void:
	if not gacha_screen or not gacha_screen.visible:
		return

	var active_b: Dictionary = BANNERS[active_banner_idx]
	var is_weapon_banner: bool = (active_b.get("type", "character") == "weapon")
	
	var b_title: Label = gacha_screen.find_child("BannerTitle", true, false)
	if b_title:
		if is_weapon_banner:
			var cone := LightConeRegistry.get_cone(active_b.id)
			b_title.text = "⚔ %s — 5★ Конус" % cone.get("name", "Конус")
		else:
			var c_data := CharacterRegistry.get_character(active_b.id)
			if not c_data.is_empty():
				b_title.text = "🌟 %s (%s) — 5★ Персонаж" % [c_data.name, CharacterRegistry.get_path_name(c_data.path)]

	var b_panel: PanelContainer = gacha_screen.find_child("BannerPanel", true, false)
	if b_panel:
		var splash_bg: TextureRect = b_panel.get_node_or_null("BannerSplashBG") as TextureRect
		var splash_tex: Texture2D = CharacterRegistry.get_character_splash(active_b.id) if not is_weapon_banner else null
		if splash_tex != null:
			if splash_bg == null:
				splash_bg = TextureRect.new()
				splash_bg.name = "BannerSplashBG"
				splash_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				splash_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				splash_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
				splash_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				b_panel.add_child(splash_bg)
				b_panel.move_child(splash_bg, 0)
			splash_bg.texture = splash_tex
			splash_bg.modulate = Color(0.42, 0.42, 0.48, 0.32)
			splash_bg.visible = true
		elif splash_bg != null:
			splash_bg.visible = false

	if gacha_info_label:
		if is_weapon_banner:
			var status_g := "ДА (100%)" if TeamConfig.gacha_weapon_guaranteed_featured else "70/30"
			gacha_info_label.text = "Круток до 5★ Оружия: %d / 80  |  Круток до 4★: %d / 10  |  Гарант Ивента: %s" % [
				TeamConfig.gacha_weapon_5star_pity,
				TeamConfig.gacha_4star_pity,
				status_g
			]
		else:
			var status_g := "ДА (100%)" if TeamConfig.gacha_guaranteed_featured else "50/50 (60%)"
			gacha_info_label.text = "Круток до 5★ Героя: %d / 90  |  Круток до 4★: %d / 10  |  Гарант Ивента: %s" % [
				TeamConfig.gacha_5star_pity,
				TeamConfig.gacha_4star_pity,
				status_g
			]
			
# Выполнение 1 или 10 круток
# Запуск 1 или 10 круток с переходом к шагу 20 во время обучения
func _execute_gacha_pulls(count: int) -> void:
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.hide_pointer()
		if menu_guide_overlay.dialog_panel:
			menu_guide_overlay.dialog_panel.hide()
	if menu_tut_pointer and is_instance_valid(menu_tut_pointer):
		menu_tut_pointer.visible = false

	if TeamConfig.shine < count:
		notification_label.text = "❌ Недостаточно Блеска Свечения!"
		return

	TeamConfig.shine -= count
	var results: Array[Dictionary] = []
	var max_rarity := 3

	for i in count:
		var pull_res := _single_gacha_pull()
		results.append(pull_res)
		max_rarity = max(max_rarity, int(pull_res.get("rarity", 3)))

	TeamConfig.save_game()
	_update_coins_display()
	_refresh_gacha_ui()

	# 1. Запуск цветной кат-сцены
	_play_gacha_cutscene(max_rarity, func():
		if count == 1:
			# Колбэк: Если мы в обучении на шаге 19 (выпала Сара) -> переходим к шагу 20!
			var on_close_cb := Callable()
			if is_menu_tutorial and menu_tut_step == 19:
				on_close_cb = func(): _run_menu_tut_step(20)

			_show_single_gacha_result_with_step(results[0], "", on_close_cb)
		else:
			_show_sequential_ten_pulls(results, 0)
	)
	
# Пошаговый показ 10 карточек по одной друг за другом
func _show_sequential_ten_pulls(results: Array[Dictionary], index: int) -> void:
	if index >= results.size():
		# Все 10 карточек показаны -> выводим итоговую сетку наград!
		_show_ten_gacha_results(results)
		return

	var item := results[index]
	var step_title := "Карточка %d / 10" % (index + 1)
	var rarity: int = int(item.get("rarity", 3))

	if rarity >= 5:
		_play_hsr_five_star_warp_reveal(func():
			_show_single_gacha_result_with_step(item, step_title, func():
				_show_sequential_ten_pulls(results, index + 1)
			)
		)
	else:
		_show_single_gacha_result_with_step(item, step_title, func():
			_show_sequential_ten_pulls(results, index + 1)
		)

func _show_single_gacha_result_with_step(res: Dictionary, step_txt: String, on_close: Callable) -> void:
	if res.type == "character":
		_show_character_unlock_animation(res.id, res.is_new, res.eidolon, step_txt, on_close)
	elif res.type == "light_cone":
		_show_light_cone_unlock_animation(res.id, step_txt, on_close)
	elif res.type == "coins":
		_show_coins_unlock_animation(res.amount, step_txt, on_close)
	elif res.type == "relic_shards":
		_show_shards_unlock_animation(res.amount, step_txt, on_close)
		
# Математика 1 крутки
# Полная математика 1 крутки (Персонажи vs Оружие)
func _single_gacha_pull() -> Dictionary:
	# Проверка обучения на 19 шаге
	if is_menu_tutorial and menu_tut_step == 19:
		var c_id := "sara"
		var is_new := not (c_id in TeamConfig.unlocked_characters)
		var build := TeamConfig.get_saved_build(c_id)
		var cur_e: int = int(build.get("eidolon", 0))

		if is_new:
			TeamConfig.unlocked_characters.append(c_id)
			build["eidolon"] = 0
		else:
			build["eidolon"] = mini(cur_e + 1, 6)

		TeamConfig.set_saved_build(c_id, build)

		# Сразу разблокируем кнопки в гаче и в меню после выпадения Сары
		is_menu_tutorial = false
		TeamConfig.menu_tutorial_completed = true
		TeamConfig.save_game()
		if gacha_screen and is_instance_valid(gacha_screen):
			var btn_b: Button = gacha_screen.find_child("BtnGachaBack", true, false)
			if btn_b: btn_b.disabled = false
			var btn_1: Button = gacha_screen.find_child("BtnPull1", true, false)
			if btn_1: btn_1.disabled = false
			var btn_10: Button = gacha_screen.find_child("BtnPull10", true, false)
			if btn_10: btn_10.disabled = false
			if banner_select_option:
				banner_select_option.disabled = false
		_lock_hub_buttons(false)
		_set_hub_card_disabled(btn_menu_levels, false)
		_set_hub_card_disabled(btn_menu_chars, false)
		_set_hub_card_disabled(btn_menu_relics, false)
		_set_hub_card_disabled(btn_menu_db, false)
		_set_hub_card_disabled(btn_menu_inv, false)
		_set_hub_card_disabled(btn_menu_shop, false)
		_set_hub_card_disabled(btn_menu_gacha, false)

		return {"type": "character", "id": c_id, "rarity": 4, "is_new": is_new, "eidolon": build["eidolon"]}

	TeamConfig.gacha_4star_pity += 1
	var active_b: Dictionary = BANNERS[active_banner_idx]
	var is_weapon_banner: bool = (active_b.get("type", "character") == "weapon")

	# --- 1. РАСЧЕТ И ПРОВЕРКА 5★ ---
	var chance_5star: float = 0.018

	if is_weapon_banner:
		TeamConfig.gacha_weapon_5star_pity += 1
		var pity_w: int = TeamConfig.gacha_weapon_5star_pity
		if pity_w >= 80:
			chance_5star = 1.0 # 80 Хард Пити Оружия
		elif pity_w >= 65:
			chance_5star = 0.01 + 0.25 + float(pity_w - 65) * 0.05
			chance_5star = minf(chance_5star, 1.0)
	else:
		TeamConfig.gacha_5star_pity += 1
		var pity_c: int = TeamConfig.gacha_5star_pity
		if pity_c >= 90:
			chance_5star = 1.0 # 90 Хард Пити Персонажей
		elif pity_c >= 75:
			chance_5star = 0.01 + 0.25 + float(pity_c - 75) * 0.05
			chance_5star = minf(chance_5star, 1.0)

	# ЕСЛИ ВЫПАЛ 5★
	if randf() < chance_5star:
		if is_weapon_banner:
			TeamConfig.gacha_weapon_5star_pity = 0
			var featured_lc_id: String = active_b.id
			var target_lc_id := ""

			# ПРОВЕРКА 70/30 ДЛЯ ОРУЖИЯ
			if TeamConfig.gacha_weapon_guaranteed_featured or randf() < 0.70:
				target_lc_id = featured_lc_id
				TeamConfig.gacha_weapon_guaranteed_featured = false
			else:
				# Проиграл 70/30 -> Стандартный 5★ Конус
				var std_lcs := ["cant_kill_you", "moment_of_happiness", "touch_waking_world", "new_life_start"]
				target_lc_id = std_lcs[randi() % std_lcs.size()]
				TeamConfig.gacha_weapon_guaranteed_featured = true

			TeamConfig.unlocked_light_cones.append(target_lc_id)
			return {"type": "light_cone", "id": target_lc_id, "rarity": 5}

		else:
			TeamConfig.gacha_5star_pity = 0
			var featured_char_id: String = active_b.id
			var char_id := ""

			# ПРОВЕРКА 50/50 ДЛЯ ПЕРСОНАЖЕЙ
			if TeamConfig.gacha_guaranteed_featured or randf() < 0.60:
				char_id = featured_char_id
				TeamConfig.gacha_guaranteed_featured = false
			else:
				# ПРОИГРЫШ 50/50: 70% шанс на стандартного Героя / 30% шанс на 5★ Конус!
				TeamConfig.gacha_guaranteed_featured = true
				
				if randf() < 0.70:
					var std_5stars := ["marina", "pusenkov", "milena", "jeff"]
					char_id = std_5stars[randi() % std_5stars.size()]
				else:
					# Выпал стандартный 5★ Конус из персонажного баннера
					var std_lcs := ["cant_kill_you", "moment_of_happiness", "touch_waking_world", "concert_dead"]
					var dropped_lc_id: String = std_lcs[randi() % std_lcs.size()]
					TeamConfig.unlocked_light_cones.append(dropped_lc_id)
					return {"type": "light_cone", "id": dropped_lc_id, "rarity": 5}

			var is_new := not (char_id in TeamConfig.unlocked_characters)
			var build := TeamConfig.get_saved_build(char_id)
			var cur_e: int = int(build.get("eidolon", 0))

			if is_new:
				TeamConfig.unlocked_characters.append(char_id)
				build["eidolon"] = 0
			else:
				build["eidolon"] = mini(cur_e + 1, 6)

			TeamConfig.set_saved_build(char_id, build)
			return {"type": "character", "id": char_id, "rarity": 5, "is_new": is_new, "eidolon": build["eidolon"]}

	# --- 2. ПРОВЕРКА ВЫПАДЕНИЯ 4★ ---
	var pity_4: int = TeamConfig.gacha_4star_pity
	var chance_4star: float = 0.12
	if pity_4 >= 10:
		chance_4star = 1.0

	if randf() < chance_4star:
		TeamConfig.gacha_4star_pity = 0

		if randf() < 0.50:
			var pool_4c := ["sara", "arseniy", "kaori", "dasha", "danill", "naama", "isaac", "keloist", "joan", "arseniy_admin", "dasha_admin"]
			var c_id: String = pool_4c[randi() % pool_4c.size()]
			var is_new := not (c_id in TeamConfig.unlocked_characters)
			var build := TeamConfig.get_saved_build(c_id)
			var cur_e: int = int(build.get("eidolon", 0))

			if is_new:
				TeamConfig.unlocked_characters.append(c_id)
				build["eidolon"] = 0
			else:
				build["eidolon"] = mini(cur_e + 1, 6)

			TeamConfig.set_saved_build(c_id, build)
			return {"type": "character", "id": c_id, "rarity": 4, "is_new": is_new, "eidolon": build["eidolon"]}
		else:
			var lc_id: String = POOL_4LC[randi() % POOL_4LC.size()]
			TeamConfig.unlocked_light_cones.append(lc_id)
			return {"type": "light_cone", "id": lc_id, "rarity": 4}

	# --- 3. ЕСЛИ НИЧЕГО НЕ ВЫПАЛО — 33% ШАНС НА ОСКОЛКИ РЕЛИКВИЙ, ИНАЧЕ 20 МОНЕТ ---
	if randf() < 0.33:
		var shards_count := 20
		TeamConfig.add_relic_shards(shards_count)
		return {"type": "relic_shards", "amount": shards_count, "rarity": 3}
	else:
		TeamConfig.coins += 20
		return {"type": "coins", "amount": 20, "rarity": 3}
	
# Показ одиночного результата
func _show_single_gacha_result(res: Dictionary) -> void:
	if res.type == "character":
		_show_character_unlock_animation(res.id, res.is_new, res.eidolon)
	elif res.type == "light_cone":
		_show_light_cone_unlock_animation(res.id)
	elif res.type == "coins":
		_show_coins_unlock_animation(res.amount)
	elif res.type == "relic_shards":
		_show_shards_unlock_animation(res.amount)

# Итоговое окно 10 круток
# Итоговое окно 10 круток (с динамическим выводом редкости конусов 3★ / 4★ / 5★)
func _show_ten_gacha_results(results: Array[Dictionary]) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 360)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "✨ РЕЗУЛЬТАТЫ 10 КРУТОК"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	for item in results:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(120, 100)
		
		var r_val: int = int(item.get("rarity", 3))
		var col := Color(1.0, 0.85, 0.2) if r_val == 5 else (Color(0.75, 0.45, 1.0) if r_val == 4 else Color(0.3, 0.7, 1.0))
		
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.12, 0.16)
		sb.border_color = col
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		p.add_theme_stylebox_override("panel", sb)

		var iv := VBoxContainer.new()
		iv.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(iv)

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", col)

		if item.type == "character":
			var c_data := CharacterRegistry.get_character(item.id)
			lbl.text = "👤 %s\n(%d★)" % [c_data.get("name", ""), r_val]
		elif item.type == "light_cone":
			var lc_data := LightConeRegistry.get_cone(item.id)
			var lc_rarity: int = int(lc_data.get("rarity", r_val))
			lbl.text = "⚔ %s\n(%d★)" % [lc_data.get("name", ""), lc_rarity]
		elif item.type == "relic_shards":
			lbl.text = "🔮 Осколки\n(+%d)" % int(item.get("amount", 20))
		else:
			lbl.text = "💰 20 Монет"

		iv.add_child(lbl)
		grid.add_child(p)

	var close_btn := Button.new()
	close_btn.text = "Продолжить"
	close_btn.custom_minimum_size = Vector2(180, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)
	
# Эпическая кат-сцена «Восхождение Звезды» с массивным золотым салютом
func _play_gacha_cutscene(max_rarity: int, on_complete: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.08, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Палитра цвета звезды
	var glow_color := Color(0.3, 0.75, 1.0) # 3★ Голубой
	var fill_color := Color(0.8, 0.95, 1.0)

	if max_rarity == 4:
		glow_color = Color(0.95, 0.35, 0.85)
		fill_color = Color(0.85, 0.45, 0.95) # 4★ Сиреневатый
	elif max_rarity >= 5:
		glow_color = Color(1.0, 0.85, 0.2)
		fill_color = Color(1.0, 1.0, 1.0) # 5★ Слепяще-белый

	var vp_size := get_viewport_rect().size
	var screen_center := Vector2(vp_size.x * 0.5, vp_size.y * 0.5)

	# Нарисованная главная звездочка ✨
	var main_star := SparkleStar.new(glow_color, 1.5)
	overlay.add_child(main_star)

	# Завеса залива экрана
	var screen_fill := ColorRect.new()
	screen_fill.color = fill_color
	screen_fill.color.a = 0.0
	screen_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(screen_fill)

	var start_pos := Vector2(screen_center.x, screen_center.y + 240)

	main_star.position = start_pos
	main_star.scale = Vector2(0.2, 0.2)
	main_star.modulate.a = 0.0

	var star_rise_time := 1.2 if max_rarity >= 5 else 0.85
	var fill_fade_time := 1.2 if max_rarity >= 5 else 0.35
	var hold_white_time := 0.8 if max_rarity >= 5 else 0.1

	var tween := create_tween()
	# 1. Погружение в темноту + Замедленное восхождение звезды ✨
	tween.parallel().tween_property(overlay, "color:a", 1.0, 0.3)
	tween.parallel().tween_property(main_star, "position", screen_center, star_rise_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_star, "scale", Vector2(1.6, 1.6), star_rise_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_star, "modulate:a", 1.0, 0.4)

	# 2. МАССИВНЫЙ САЛЮТ ИЗ 36 ЗОЛОТЫХ ЗВЁЗД ИЗ САМОГО ЦЕНТРА ЭКРАНА ДЛЯ 5★
	if max_rarity >= 5:
		tween.chain().tween_callback(func():
			var gold_shades := [
				Color(1.0, 0.84, 0.0, 0.95),  # Чистое золото
				Color(1.0, 0.92, 0.25, 1.0),  # Сияющее яркое золото
				Color(0.98, 0.72, 0.05, 0.9)  # Глубокое янтарное золото
			]

			for i in 32:
				var gold_col: Color = gold_shades[i % gold_shades.size()]
				var burst_star := SparkleStar.new(gold_col, randf_range(0.4, 0.75))
				burst_star.position = screen_center
				overlay.add_child(burst_star)
				overlay.move_child(burst_star, screen_fill.get_index())

				# Разлет во все стороны из точного центра экрана
				var random_angle := randf_range(0, TAU)
				var random_dist := randf_range(220, 580)
				var dir := Vector2.RIGHT.rotated(random_angle) * random_dist

				var st_tween := create_tween().set_parallel(true)
				st_tween.tween_property(burst_star, "position", screen_center + dir, 1.15)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				st_tween.tween_property(burst_star, "modulate:a", 0.0, 1.15)
				st_tween.tween_property(burst_star, "scale", Vector2(1.8, 1.8), 1.15)
				st_tween.tween_property(burst_star, "rotation_degrees", randf_range(-360, 360), 1.15)
				st_tween.chain().tween_callback(burst_star.queue_free)
		)

	# 3. Медленный налив белого света
	tween.chain().tween_property(screen_fill, "color:a", 1.0, fill_fade_time)

	# 4. Удержание белизны на 0.8 секунды
	tween.chain().tween_interval(hold_white_time)

	# 5. Переход к карточкам
	tween.chain().tween_callback(func():
		overlay.queue_free()
		on_complete.call()
	)

# Карточка Героя с белой вспышкой и вылетом 28 золотых искорок из центра экрана
func _show_character_unlock_animation(char_id: String, is_new: bool, eidolon_lvl: int, step_txt: String = "", on_close: Callable = Callable()) -> void:
	var data := CharacterRegistry.get_character(char_id)
	if data.is_empty(): return

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 150
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
	var has_splash := (splash_tex != null)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(540, 620) if has_splash else Vector2(520, 440)
	card_panel.pivot_offset = Vector2(270, 310) if has_splash else Vector2(260, 220)
	card_panel.clip_contents = true
	center.add_child(card_panel)

	var rarity_color := Color(1.0, 0.85, 0.2) if data.rarity >= 5 else (Color(0.75, 0.45, 1.0) if data.rarity == 4 else Color(0.3, 0.7, 1.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20 if has_splash else 24)
	card_panel.add_theme_stylebox_override("panel", sb)

	# Затемненный сплеш-арт на заднем плане карточки
	if has_splash:
		var bg_splash := TextureRect.new()
		bg_splash.texture = splash_tex
		bg_splash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_splash.modulate = Color(0.30, 0.30, 0.35, 0.35)
		card_panel.add_child(bg_splash)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8 if has_splash else 12)
	card_panel.add_child(vbox)

	if not step_txt.is_empty():
		var step_lbl := Label.new()
		step_lbl.text = step_txt
		step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_lbl.add_theme_font_size_override("font_size", 14)
		step_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(step_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "🎉 НОВЫЙ ПЕРСОНАЖ!" if is_new else "✨ ПОЛУЧЕН ЭЙДОЛОН [E%d]!" % eidolon_lvl
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 22)
	status_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(status_lbl)

	var stars_str := ""
	for s in data.rarity: stars_str += "★ "
	var stars_lbl := Label.new()
	stars_lbl.text = stars_str.strip_edges()
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 26 if has_splash else 28)
	stars_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(stars_lbl)

	if has_splash:
		# Красивый центральный портрет персонажа с золотой/фиолетовой рамкой
		var frame_container := CenterContainer.new()
		frame_container.custom_minimum_size = Vector2(0, 240)
		vbox.add_child(frame_container)

		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(190, 235)
		frame.clip_contents = true
		var frame_sb := StyleBoxFlat.new()
		frame_sb.bg_color = Color(0.04, 0.05, 0.08, 0.90)
		frame_sb.border_color = rarity_color
		frame_sb.set_border_width_all(2)
		frame_sb.set_corner_radius_all(12)
		frame.add_theme_stylebox_override("panel", frame_sb)
		frame_container.add_child(frame)

		var portrait_rect := TextureRect.new()
		portrait_rect.texture = splash_tex
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(portrait_rect)

		# Стильная плашка элемента в углу рамки
		var elem_tag := Label.new()
		elem_tag.text = "%s %s" % [CombatConstants.ELEMENT_SYMBOLS.get(data.element, ""), CombatConstants.get_element_name(data.element)]
		elem_tag.add_theme_font_size_override("font_size", 12)
		elem_tag.add_theme_color_override("font_color", CombatConstants.get_element_color(data.element))
		elem_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(elem_tag)
	else:
		var elem_symbol := Label.new()
		elem_symbol.text = "%s  %s" % [CombatConstants.ELEMENT_SYMBOLS[data.element], CombatConstants.get_element_name(data.element)]
		elem_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elem_symbol.add_theme_font_size_override("font_size", 28)
		elem_symbol.add_theme_color_override("font_color", CombatConstants.get_element_color(data.element))
		vbox.add_child(elem_symbol)

	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 30 if has_splash else 34)
	vbox.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.text = "Путь: %s" % CharacterRegistry.get_path_name(data.path)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 15 if has_splash else 16)
	info_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(info_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Далее ➔" if not step_txt.is_empty() else "Продолжить"
	btn_cont.custom_minimum_size = Vector2(220, 48)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = rarity_color
	btn_sb.set_corner_radius_all(10)
	btn_cont.add_theme_stylebox_override("normal", btn_sb)
	btn_cont.add_theme_color_override("font_color", Color.BLACK)
	btn_cont.pressed.connect(func():
		overlay.queue_free()
		if on_close.is_valid(): on_close.call()
	)
	vbox.add_child(btn_cont)

	# ПЕРЕХОД ИЗ БЕЛИЗНЫ + САЛЮТ ИЗ 28 ЗОЛОТЫХ ИСКР ИЗ ЦЕНТРА ЭКРАНА ДЛЯ 5★
	if data.rarity >= 5:
		var card_flash: ColorRect = null
		if step_txt.is_empty():
			card_flash = ColorRect.new()
			card_flash.color = Color(1.0, 1.0, 1.0, 1.0)
			card_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(card_flash)

			var f_tween := create_tween()
			f_tween.tween_property(card_flash, "color:a", 0.0, 0.6)
			f_tween.chain().tween_callback(card_flash.queue_free)

		var screen_center := Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.5)
		var gold_shades := [
			Color(1.0, 0.84, 0.0, 0.95),
			Color(1.0, 0.92, 0.25, 1.0),
			Color(0.98, 0.72, 0.05, 0.9)
		]

		for i in 28:
			var gold_col: Color = gold_shades[i % gold_shades.size()]
			var card_sparkle := SparkleStar.new(gold_col, randf_range(0.35, 0.7))
			card_sparkle.position = screen_center
			overlay.add_child(card_sparkle)
			if card_flash != null and is_instance_valid(card_flash):
				overlay.move_child(card_sparkle, card_flash.get_index())

			var random_angle := randf_range(0, TAU)
			var random_dist := randf_range(180, 500)
			var dir := Vector2.RIGHT.rotated(random_angle) * random_dist

			var sp_tween := create_tween().set_parallel(true)
			sp_tween.tween_property(card_sparkle, "position", screen_center + dir, 0.95)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			sp_tween.tween_property(card_sparkle, "modulate:a", 0.0, 0.95)
			sp_tween.tween_property(card_sparkle, "scale", Vector2(1.6, 1.6), 0.95)
			sp_tween.tween_property(card_sparkle, "rotation_degrees", randf_range(-270, 270), 0.95)
			sp_tween.chain().tween_callback(card_sparkle.queue_free)

	card_panel.scale = Vector2(0.2, 0.2)
	card_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "color:a", 0.92, 0.25)
	tween.tween_property(card_panel, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.12)
	
# Обновленная карточка 3★ Монет
func _show_coins_unlock_animation(amount: int, step_txt: String = "", on_close: Callable = Callable()) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(440, 360)
	card_panel.pivot_offset = Vector2(220, 180)
	center.add_child(card_panel)

	var rarity_color := Color(0.3, 0.7, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	card_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card_panel.add_child(vbox)

	if not step_txt.is_empty():
		var step_lbl := Label.new()
		step_lbl.text = step_txt
		step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_lbl.add_theme_font_size_override("font_size", 14)
		step_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(step_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "💰 НАГРАДА ЗА КРУТКУ (3★)"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 18)
	status_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(status_lbl)

	var icon_lbl := Label.new()
	icon_lbl.text = "💰"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 64)
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = "+%d МОНЕТ!" % amount
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(name_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Далее ➔" if not step_txt.is_empty() else "Продолжить"
	btn_cont.custom_minimum_size = Vector2(200, 48)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = rarity_color
	btn_sb.set_corner_radius_all(10)
	btn_cont.add_theme_stylebox_override("normal", btn_sb)
	btn_cont.add_theme_color_override("font_color", Color.BLACK)
	btn_cont.pressed.connect(func():
		overlay.queue_free()
		if on_close.is_valid(): on_close.call()
	)
	vbox.add_child(btn_cont)

	card_panel.scale = Vector2(0.2, 0.2)
	card_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "color:a", 0.90, 0.25)
	tween.tween_property(card_panel, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.12)

# Карточка 3★ Осколков реликвий из гачи
func _show_shards_unlock_animation(amount: int, step_txt: String = "", on_close: Callable = Callable()) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(460, 380)
	card_panel.pivot_offset = Vector2(230, 190)
	center.add_child(card_panel)

	var rarity_color := Color(0.3, 0.75, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.15, 0.98)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	card_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card_panel.add_child(vbox)

	if not step_txt.is_empty():
		var step_lbl := Label.new()
		step_lbl.text = step_txt
		step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_lbl.add_theme_font_size_override("font_size", 14)
		step_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(step_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "🔮 НАГРАДА ЗА КРУТКУ (3★)"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 18)
	status_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(status_lbl)

	var icon_lbl := Label.new()
	icon_lbl.text = "🔮"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 64)
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = "+%d ОСКОЛКОВ РЕЛИКВИЙ!" % amount
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	vbox.add_child(name_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "Используются для прокачки характеристик реликвий (+%d опыта)" % (amount * RelicSystem.SHARD_EXP_VALUE)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	vbox.add_child(hint_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Далее ➔" if not step_txt.is_empty() else "Продолжить"
	btn_cont.custom_minimum_size = Vector2(200, 48)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = rarity_color
	btn_sb.set_corner_radius_all(10)
	btn_cont.add_theme_stylebox_override("normal", btn_sb)
	btn_cont.add_theme_color_override("font_color", Color.BLACK)
	btn_cont.pressed.connect(func():
		overlay.queue_free()
		if on_close.is_valid(): on_close.call()
	)
	vbox.add_child(btn_cont)

	card_panel.scale = Vector2(0.2, 0.2)
	card_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "color:a", 0.90, 0.25)
	tween.tween_property(card_panel, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.12)


# Обновленная карточка 4★ Светового Конуса
# Анимация выпадения Светового Конуса (динамический цвет 4★ / 5★)
# Обновленная карточка Светового Конуса (с белой вспышкой и золотым салютом для 5★!)
func _show_light_cone_unlock_animation(lc_id: String, step_txt: String = "", on_close: Callable = Callable()) -> void:
	var cone := LightConeRegistry.get_cone(lc_id)
	if cone.is_empty(): return

	var rarity: int = int(cone.get("rarity", 4))
	var rarity_color := Color(1.0, 0.85, 0.2) if rarity >= 5 else Color(0.75, 0.45, 1.0)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(500, 400)
	card_panel.pivot_offset = Vector2(250, 200)
	center.add_child(card_panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	card_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	card_panel.add_child(vbox)

	if not step_txt.is_empty():
		var step_lbl := Label.new()
		step_lbl.text = step_txt
		step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_lbl.add_theme_font_size_override("font_size", 14)
		step_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(step_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "⚔ СВЕТОВОЙ КОНУС (%d★)" % rarity
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 20)
	status_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(status_lbl)

	var icon_lbl := Label.new()
	icon_lbl.text = "⚔"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 54)
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = cone.get("name", "Конус")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 30)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = cone.get("description", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(desc_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Далее ➔" if not step_txt.is_empty() else "Продолжить"
	btn_cont.custom_minimum_size = Vector2(220, 48)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = rarity_color
	btn_sb.set_corner_radius_all(10)
	btn_cont.add_theme_stylebox_override("normal", btn_sb)
	btn_cont.add_theme_color_override("font_color", Color.BLACK)
	btn_cont.pressed.connect(func():
		overlay.queue_free()
		if on_close.is_valid(): on_close.call()
	)
	vbox.add_child(btn_cont)

	# ПЕРЕХОД ИЗ БЕЛИЗНЫ + ВЗРЫВ 28 ЗОЛОТЫХ ИСКР ДЛЯ 5★ КОНУСОВ
	if rarity >= 5:
		var card_flash: ColorRect = null
		if step_txt.is_empty():
			card_flash = ColorRect.new()
			card_flash.color = Color(1.0, 1.0, 1.0, 1.0)
			card_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(card_flash)

			var f_tween := create_tween()
			f_tween.tween_property(card_flash, "color:a", 0.0, 0.6)
			f_tween.chain().tween_callback(card_flash.queue_free)

		var screen_center := Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.5)
		var gold_shades := [
			Color(1.0, 0.84, 0.0, 0.95),
			Color(1.0, 0.92, 0.25, 1.0),
			Color(0.98, 0.72, 0.05, 0.9)
		]

		for i in 28:
			var gold_col: Color = gold_shades[i % gold_shades.size()]
			var card_sparkle := SparkleStar.new(gold_col, randf_range(0.35, 0.7))
			card_sparkle.position = screen_center
			overlay.add_child(card_sparkle)
			if card_flash != null and is_instance_valid(card_flash):
				overlay.move_child(card_sparkle, card_flash.get_index())

			var random_angle := randf_range(0, TAU)
			var random_dist := randf_range(180, 500)
			var dir := Vector2.RIGHT.rotated(random_angle) * random_dist

			var sp_tween := create_tween().set_parallel(true)
			sp_tween.tween_property(card_sparkle, "position", screen_center + dir, 0.95)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			sp_tween.tween_property(card_sparkle, "modulate:a", 0.0, 0.95)
			sp_tween.tween_property(card_sparkle, "scale", Vector2(1.6, 1.6), 0.95)
			sp_tween.tween_property(card_sparkle, "rotation_degrees", randf_range(-270, 270), 0.95)
			sp_tween.chain().tween_callback(card_sparkle.queue_free)

	card_panel.scale = Vector2(0.2, 0.2)
	card_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "color:a", 0.92, 0.25)
	tween.tween_property(card_panel, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.12)

# Проигрывание стилизованной анимации открытия 5★ при 10 крутках (по референсу HSR)
func _play_hsr_five_star_warp_reveal(on_complete: Callable) -> void:
	var reveal := HsrFiveStarWarpReveal.new(on_complete)
	add_child(reveal)

# Стилизованная кинематографическая анимация открытия 5★ при 10 крутках в стиле Honkai: Star Rail
class HsrFiveStarWarpReveal extends Control:
	var _on_complete: Callable
	var _anim_time: float = 0.0
	var _completed: bool = false

	func _init(on_complete_cb: Callable) -> void:
		name = "HsrFiveStarWarpReveal"
		_on_complete = on_complete_cb
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 160

	func _process(delta: float) -> void:
		_anim_time += delta
		queue_redraw()
		if _anim_time >= 1.85 and not _completed:
			_completed = true
			if _on_complete.is_valid():
				_on_complete.call()
			queue_free()

	func _draw() -> void:
		var w: float = size.x if size.x > 0.0 else 1920.0
		var h: float = size.y if size.y > 0.0 else 1080.0
		var screen_rect := Rect2(Vector2.ZERO, Vector2(w, h))
		var c := Vector2(w * 0.5, h * 0.5)
		var t: float = _anim_time

		# 1. Глубокий тёмный космический фон
		var bg_alpha: float = clampf(t / 0.15, 0.0, 1.0)
		if t >= 1.50:
			bg_alpha *= (1.0 - clampf((t - 1.50) / 0.35, 0.0, 1.0))
		draw_rect(screen_rect, Color(0.005, 0.003, 0.008, 0.98 * bg_alpha), true)

		# 2. Мягкое центральное сияние Бездны
		if t < 1.75:
			var nebula_fade: float = 1.0 if t < 1.48 else (1.0 - (t - 1.48) / 0.27)
			var breathe: float = 1.0 + 0.05 * sin(t * 7.0)
			draw_circle(c, 360.0 * breathe, Color(0.14, 0.09, 0.32, 0.30 * nebula_fade * bg_alpha))
			draw_circle(c, 170.0 * breathe, Color(0.28, 0.18, 0.55, 0.25 * nebula_fade * bg_alpha))

		# 3. Атмосферные вертикальные световые колонны позади пар звёзд (интрига)
		if t < 0.90:
			var side_beams_a: float = smoothstep(0.0, 0.30, t)
			if t > 0.65:
				side_beams_a *= (1.0 - smoothstep(0.65, 0.90, t))
			if side_beams_a > 0.01:
				draw_line(Vector2(c.x - 168.0, 0.0), Vector2(c.x - 168.0, h), Color(0.18, 0.30, 0.55, 0.16 * side_beams_a), 50.0)
				draw_line(Vector2(c.x + 168.0, 0.0), Vector2(c.x + 168.0, h), Color(0.18, 0.30, 0.55, 0.16 * side_beams_a), 50.0)

		# 4. Центральная вертикальная световая расщелина (активируется при появлении 5-й звезды)
		if t >= 0.65:
			var c_beam_prog: float = smoothstep(0.65, 1.10, t)
			var c_beam_a: float = c_beam_prog
			if t >= 1.48:
				c_beam_a *= (1.0 - clampf((t - 1.48) / 0.32, 0.0, 1.0))
			if c_beam_a > 0.01:
				var beam_w: float = lerp(1.0, 2.2, c_beam_prog)
				draw_line(Vector2(c.x, 0.0), Vector2(c.x, h), Color(0.35, 0.55, 0.95, 0.28 * c_beam_a), beam_w * 3.5)
				draw_line(Vector2(c.x, 0.0), Vector2(c.x, h), Color(0.92, 0.96, 1.00, 0.85 * c_beam_a), beam_w)

		# 5. Импульсная кольцевая волна (Кадр 5: расширяется и угасает)
		if t >= 1.48:
			var w_prog: float = clampf((t - 1.48) / 0.37, 0.0, 1.0)
			var wave_r: float = lerp(45.0, 780.0, 1.0 - pow(1.0 - w_prog, 2.5))
			var wave_a: float = (1.0 - w_prog) * 0.95
			if wave_a > 0.005:
				draw_arc(c, wave_r, 0.0, TAU, 72, Color(1.0, 0.96, 0.72, 0.90 * wave_a), 2.5, true)
				draw_arc(c, wave_r, 0.0, TAU, 72, Color(0.85, 0.68, 1.0, 0.45 * wave_a), 6.5, true)
				draw_circle(c, wave_r, Color(0.9, 0.85, 1.0, 0.06 * wave_a))

		# 6. Отрисовка созвездия звёзд с интригующим появлением 5-й звезды
		_draw_suspense_stars(c, t)

	func _draw_suspense_stars(c: Vector2, t: float) -> void:
		# Базовые координаты: 4 боковые звезды строго на уровне y = 0.0
		var star_defs: Array[Dictionary] = [
			{"base_pos": Vector2(-225.0, 0.0), "out_r": 25.0, "in_r": 5.8},  # Звезда 0 (крайняя левая)
			{"base_pos": Vector2(-112.0, 0.0), "out_r": 36.0, "in_r": 8.2},  # Звезда 1 (внутренняя левая)
			{"base_pos": Vector2(0.0, 0.0),     "out_r": 74.0, "in_r": 15.5}, # Звезда 2 (центральная 5-я)
			{"base_pos": Vector2(112.0, 0.0),  "out_r": 36.0, "in_r": 8.2},  # Звезда 3 (внутренняя правая)
			{"base_pos": Vector2(225.0, 0.0),  "out_r": 25.0, "in_r": 5.8}   # Звезда 4 (крайняя правая)
		]

		# Прогресс финального засасывания в центр
		var s_prog: float = 0.0
		if t >= 1.48:
			s_prog = pow(clampf((t - 1.48) / 0.35, 0.0, 1.0), 2.2)

		# Вспышка радости/воодушевления при встраивании 5-й звезды (t = 1.05..1.25)
		var lock_flash: float = 0.0
		if t >= 1.05 and t < 1.30:
			lock_flash = sin(clampf((t - 1.05) / 0.25, 0.0, 1.0) * PI)

		for i in range(5):
			var sd: Dictionary = star_defs[i]
			var spos: Vector2 = sd["base_pos"]
			var out_r: float = float(sd["out_r"])
			var in_r: float = float(sd["in_r"])
			var fill_col: Color = Color(1.0, 0.86, 0.35)
			var core_col: Color = Color(1.0, 0.96, 0.85)
			var alpha: float = 0.0
			var scale_mul: float = 1.0
			var ray_len: float = 0.0

			if i != 2:
				# --- 4 БОКОВЫЕ ЗВЕЗДЫ (2 слева, 2 справа) ---
				# Появляются плавно первыми, создавая интригу
				var enter_start: float = 0.05 if (i == 1 or i == 3) else 0.18
				var enter_dur: float = 0.32
				var enter_prog: float = smoothstep(enter_start, enter_start + enter_dur, t)
				alpha = enter_prog
				scale_mul = enter_prog

				# Тонкое дыхание во время интригующего ожидания (t < 0.65)
				if t < 0.65:
					scale_mul *= (1.0 + 0.04 * sin(t * 8.0 + float(i)))

				# При встраивании 5-й звезды все 4 звезды насыщаются триумфальным золотом
				if t >= 1.05:
					scale_mul *= (1.0 + 0.12 * lock_flash)
					ray_len = out_r * 0.6 * lock_flash
					fill_col = Color(1.0, 0.90, 0.42)
					core_col = Color(1.0, 1.0, 0.92)

			else:
				# --- 5-Я ЦЕНТРАЛЬНАЯ ЗВЕЗДА (Кульминация) ---
				if t < 0.65:
					continue

				# 1. Появление чуть ниже уровня остальных (y = +40.0)
				var appear_prog: float = smoothstep(0.65, 0.85, t)
				alpha = appear_prog
				scale_mul = lerp(0.35, 1.0, appear_prog)

				# 2. Плавное движение снизу вверх и встраивание в ряд (y: 40.0 -> 0.0)
				var rise_prog: float = smoothstep(0.80, 1.10, t)
				var cur_y: float = lerp(40.0, 0.0, rise_prog)
				spos.y = cur_y

				# 3. Эволюция цвета: от ослепительного серебристо-белого до триумфального золота
				if t < 1.05:
					# Первоначально ослепительно серебряная/алмазная звезда
					var silver_t: float = smoothstep(0.65, 1.00, t)
					fill_col = Color(0.95, 0.98, 1.0)
					core_col = Color(1.0, 1.0, 1.0)
					ray_len = out_r * 0.8 * silver_t
				else:
					# Встраивание и триумфальное озарение золотом!
					var gold_prog: float = smoothstep(1.05, 1.25, t)
					fill_col = Color(0.95, 0.98, 1.0).lerp(Color(1.0, 0.94, 0.62), gold_prog)
					core_col = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.98, 0.90), gold_prog)
					# Вспышка масштаба при замковом соединении в ряд
					scale_mul *= (1.0 + 0.18 * lock_flash)
					ray_len = out_r * (0.8 + 0.6 * lock_flash)

			# 4. Финальное засасывание в центр (Кадр 5)
			if s_prog > 0.0:
				spos = spos.lerp(Vector2.ZERO, s_prog)
				var r_target: float = lerp(out_r, 15.0, clampf(s_prog * 2.0, 0.0, 1.0))
				out_r = r_target * (1.0 - s_prog)
				in_r = out_r * 0.22
				alpha *= (1.0 - s_prog)
				ray_len *= (1.0 - s_prog)

			out_r *= scale_mul
			in_r *= scale_mul

			_draw_star_shape(c + spos, out_r, in_r, fill_col, core_col, alpha, ray_len)

	func _draw_star_shape(spos: Vector2, out_r: float, in_r: float, fill_col: Color, core_col: Color, alpha: float, ray_len: float = 0.0) -> void:
		if alpha <= 0.005 or out_r <= 0.5:
			return
		var col := fill_col
		col.a *= alpha
		var c_col := core_col
		c_col.a *= alpha

		# Лучи сияния (Lens flare rays) для вдохновляющего блеска
		if ray_len > 1.0:
			var ray_col := Color(fill_col.r, fill_col.g, fill_col.b, 0.35 * alpha)
			var core_ray_col := Color(1.0, 1.0, 1.0, 0.65 * alpha)
			var r_ext: float = out_r + ray_len
			# Горизонтальный и вертикальный световые лучи
			draw_line(spos + Vector2(-r_ext, 0.0), spos + Vector2(r_ext, 0.0), ray_col, 2.2)
			draw_line(spos + Vector2(0.0, -r_ext), spos + Vector2(0.0, r_ext), ray_col, 2.2)
			draw_line(spos + Vector2(-r_ext * 0.6, 0.0), spos + Vector2(r_ext * 0.6, 0.0), core_ray_col, 1.0)
			draw_line(spos + Vector2(0.0, -r_ext * 0.6), spos + Vector2(0.0, r_ext * 0.6), core_ray_col, 1.0)

		# Внешнее сияющее гало
		if out_r > 15.0:
			draw_circle(spos, out_r * 1.5, Color(fill_col.r, fill_col.g, fill_col.b, 0.22 * alpha))
			draw_circle(spos, out_r * 0.8, Color(fill_col.r, fill_col.g, fill_col.b, 0.40 * alpha))

		# 4-конечная звезда
		var pts := PackedVector2Array([
			spos + Vector2(0.0, -out_r),
			spos + Vector2(in_r, -in_r),
			spos + Vector2(out_r, 0.0),
			spos + Vector2(in_r, in_r),
			spos + Vector2(0.0, out_r),
			spos + Vector2(-in_r, in_r),
			spos + Vector2(-out_r, 0.0),
			spos + Vector2(-in_r, -in_r)
		])
		draw_colored_polygon(pts, col)

		# Яркое внутреннее алмазное ядро
		var c_out: float = out_r * 0.44
		var c_in: float = in_r * 0.35
		var core_pts := PackedVector2Array([
			spos + Vector2(0.0, -c_out),
			spos + Vector2(c_in, -c_in),
			spos + Vector2(c_out, 0.0),
			spos + Vector2(c_in, c_in),
			spos + Vector2(0.0, c_out),
			spos + Vector2(-c_in, c_in),
			spos + Vector2(-c_out, 0.0),
			spos + Vector2(-c_in, -c_in)
		])
		draw_colored_polygon(core_pts, c_col)

# ВНУТРЕННИЙ КЛАСС ПРОГРАММНОЙ ОТРИСОВКИ ДВОЙНОЙ ЗВЕЗДОЧКИ ✨
class SparkleStar extends Control:
	var fill_color: Color
	var outer_r: float = 42.0
	var inner_r: float = 9.0

	func _init(star_color: Color = Color(1.0, 0.85, 0.2), size_scale: float = 1.0) -> void:
		fill_color = star_color
		outer_r *= size_scale
		inner_r *= size_scale
		custom_minimum_size = Vector2(outer_r * 2.5, outer_r * 2.5)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Главная ромбовидная звезда в центре
		_draw_diamond_star(Vector2.ZERO, outer_r, inner_r, fill_color)
		# Маленькая второстепенная звездочка сбоку (для создания формы ✨)
		_draw_diamond_star(Vector2(outer_r * 0.55, -outer_r * 0.55), outer_r * 0.42, inner_r * 0.42, fill_color)

	func _draw_diamond_star(center: Vector2, out_r: float, in_r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		var num_points := 8
		for i in num_points:
			var angle := float(i) * (TAU / float(num_points)) - (PI / 2.0)
			var r := out_r if (i % 2 == 0) else in_r
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			
		draw_colored_polygon(pts, col)
		
		# Сияющее белое внутреннее ядро
		var core_pts := PackedVector2Array()
		for i in num_points:
			var angle := float(i) * (TAU / float(num_points)) - (PI / 2.0)
			var r := (out_r * 0.45) if (i % 2 == 0) else (in_r * 0.35)
			core_pts.append(center + Vector2(cos(angle), sin(angle)) * r)
		draw_colored_polygon(core_pts, Color.WHITE)

# --- СИСТЕМА ОБУЧЕНИЯ В МЕНЮ (ПОСЛЕ 4 УРОВНЯ / НАСТАВНИК) ---

func _init_menu_tutorial_ui() -> void:
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.queue_free()

	menu_guide_overlay = TutorialGuideOverlayScript.new()
	menu_guide_overlay.name = "MenuTutorialGuideOverlay"
	add_child(menu_guide_overlay)
	menu_guide_overlay.set_skip_callback(_show_skip_menu_tutorial_dialog)

	# Сохраняем ссылки для обратной совместимости
	menu_tut_overlay = menu_guide_overlay
	menu_tut_panel = menu_guide_overlay.dialog_panel
	menu_tut_label = menu_guide_overlay.text_label
	menu_tut_btn = menu_guide_overlay.btn_next
	menu_tut_pointer = menu_guide_overlay.pointer_label

func _set_menu_tut_panel_pos(pos: String = "right") -> void:
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.set_dialog_position(pos)

func _run_menu_tut_step(step: int) -> void:
	menu_tut_step = step
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.hide_pointer()
		menu_guide_overlay.btn_next.visible = false
		menu_guide_overlay.set_skip_visible(step == 1)
	elif menu_tut_btn:
		menu_tut_btn.visible = false
		if menu_tut_pointer:
			menu_tut_pointer.visible = false

	if step != 20:
		_lock_hub_buttons(true)
		if hub_overview_panel:
			hub_overview_panel.visible = false
	else:
		_lock_hub_buttons(false)
		if hub_overview_panel:
			hub_overview_panel.visible = true

	match step:
		1:
			_set_menu_tut_text("Поздравляю с победой на 4 уровне!\n\n[b]Теперь выйди в главное меню![/b]", 1, "🗺 Экспедиция завершена")
			if btn_levels_back and is_instance_valid(btn_levels_back):
				btn_levels_back.disabled = false
				_show_menu_pointer_for_control(btn_levels_back, "up")
		2:
			_set_menu_tut_text("Тебе открылась [b]🏺 Добыча реликвий[/b]!\n\nРеликвии дают огромную прибавку к характеристикам персонажей. Сначала отправимся в подземелье и добудем твой первый комплект для Вики!\n\nЗаходи в [b]«Добыча реликвий»[/b].", 2, "🏺 Реликвии")
			if btn_menu_relics and is_instance_valid(btn_menu_relics):
				_set_hub_card_disabled(btn_menu_relics, false)
				_show_menu_pointer_for_control(btn_menu_relics)
		201:
			_set_menu_tut_text("Это пещера коррозии [b]«Академия»[/b]. Здесь добывается квантовый сет [b]«Истинный родоначальник хаоса»[/b], идеально подходящий для Вики!\n\nНажми [b]«⚡ Быстрая зачистка»[/b] (или «В бой»), чтобы получить первые реликвии!", 3, "⚔ Пещера коррозии")
			if tut_academy_instant_btn and is_instance_valid(tut_academy_instant_btn):
				tut_academy_instant_btn.disabled = false
				_show_menu_pointer_for_control(tut_academy_instant_btn, "down")
			elif relic_farming_cards_container and is_instance_valid(relic_farming_cards_container):
				for card in relic_farming_cards_container.get_children():
					var b_inst: Button = card.find_child("BtnInstant_*", true, false)
					if not b_inst:
						var btns := card.find_children("*", "Button", true, false)
						for b in btns:
							if "зачистка" in b.text.to_lower():
								b_inst = b as Button
								break
					if b_inst:
						tut_academy_instant_btn = b_inst
						tut_academy_instant_btn.disabled = false
						_show_menu_pointer_for_control(tut_academy_instant_btn, "down")
						break
		202:
			_set_menu_tut_text("Отлично! Ты получил реликвии Хаоса и материал для прокачки!\n\nВозвращайся назад в меню.", 4, "🏺 Реликвии получены")
			if btn_farming_back and is_instance_valid(btn_farming_back):
				btn_farming_back.disabled = false
				_show_menu_pointer_for_control(btn_farming_back, "up")
		203:
			_set_menu_tut_text("Теперь зайдём в меню [b]«👤 Персонажи»[/b], чтобы настроить и экипировать полученные реликвии!", 5, "👤 Отряд")
			if btn_menu_chars and is_instance_valid(btn_menu_chars):
				_set_hub_card_disabled(btn_menu_chars, false)
				_show_menu_pointer_for_control(btn_menu_chars)
		3:
			_set_menu_tut_text("Сейчас у тебя имеются 3 бесплатных персонажа. Давай настроим Вику!\n\nСначала выбери световой конус [b]«Апокалипсис»[/b] — он увеличивает урон её навыков.", 6, "🗡 Световой конус")
			_select_char_for_build("vika")
			if btn_choose_light_cone and is_instance_valid(btn_choose_light_cone):
				btn_choose_light_cone.disabled = false
				_show_menu_pointer_for_control(btn_choose_light_cone, "right")
			elif opt_light_cone and is_instance_valid(opt_light_cone):
				opt_light_cone.disabled = false
				_show_menu_pointer_for_control(opt_light_cone, "right")
		4:
			_set_menu_tut_text("Теперь наденем реликвии! Реликвии пещер занимают 4 верхних слота (Голова, Руки, Тело, Ноги), а планарные — 2 нижних.\n\nНажми [b]«+ Надеть»[/b] на слоте [b]👑 Голова[/b] и выбери 4★ реликвию Хаоса!", 7, "👑 Слот Головы")
			if tut_slot_btn_head and is_instance_valid(tut_slot_btn_head):
				tut_slot_btn_head.disabled = false
				_show_menu_pointer_for_control(tut_slot_btn_head, "left")
		5:
			_set_menu_tut_text("Отлично! Теперь нажми [b]«+ Надеть»[/b] на слоте [b]🧤 Руки[/b] и выбери вторую 4★ реликвию Хаоса.", 8, "🧤 Слот Рук")
			if tut_slot_btn_hands and is_instance_valid(tut_slot_btn_hands):
				tut_slot_btn_hands.disabled = false
				_show_menu_pointer_for_control(tut_slot_btn_hands, "left")
		6:
			if TeamConfig.relic_shards < 30:
				TeamConfig.add_relic_shards(30)
			_set_menu_tut_text("Посмотри на панель справа: активировался [b]Бонус 2 частей сета Хаоса (+10% Квантового урона)[/b]!\n\nА теперь улучшим Голову. Нажми [b]«⚡ Прокачать»[/b] на слоте Головы!", 9, "⚡ Улучшение сета")
			if tut_slot_btn_upgrade_head and is_instance_valid(tut_slot_btn_upgrade_head):
				tut_slot_btn_upgrade_head.disabled = false
				_show_menu_pointer_for_control(tut_slot_btn_upgrade_head, "left")
		7:
			if TeamConfig.relic_shards < 30:
				TeamConfig.add_relic_shards(30)
			_set_menu_tut_text("В окне прокачки можно скармливать ненужные реликвии или 🔮 Осколки (1 шт. = 100 XP).\n\nНажми [b]«✨ Авто»[/b] (или выбери корм справа), а затем нажми [b]«⚡ Прокачать»[/b]!", 10, "⚡ Прокачка")
			if _upgrade_btn_apply and is_instance_valid(_upgrade_btn_apply):
				_upgrade_btn_apply.disabled = false
			if _upgrade_btn_auto_shards and is_instance_valid(_upgrade_btn_auto_shards):
				_upgrade_btn_auto_shards.disabled = false
				_show_menu_pointer_for_control(_upgrade_btn_auto_shards, "down")
			elif _upgrade_btn_apply and is_instance_valid(_upgrade_btn_apply):
				_show_menu_pointer_for_control(_upgrade_btn_apply, "up")
		8:
			_set_menu_tut_text("Поздравляю с первой прокачкой реликвии! Запомни: не забывай сохранять сборку.\n\nНажми [b]«💾 Сохранить сборку персонажа»[/b]!", 11, "💾 Сохранение сборки")
			if btn_save_char_build and is_instance_valid(btn_save_char_build):
				btn_save_char_build.disabled = false
				_show_menu_pointer_for_control(btn_save_char_build, "up")
		102:
			_set_menu_tut_text("Сборка сохранена! Теперь выходи обратно в главное меню.", 12, "↩ Возврат в меню")
			if btn_char_back and is_instance_valid(btn_char_back):
				btn_char_back.disabled = false
				_show_menu_pointer_for_control(btn_char_back, "up")
		9:
			_set_menu_tut_text("Следующее — [b]База данных[/b]. Заходи!", 13, "📚 База данных")
			if btn_menu_db and is_instance_valid(btn_menu_db):
				_set_hub_card_disabled(btn_menu_db, false)
				_show_menu_pointer_for_control(btn_menu_db)
		10:
			_set_menu_tut_text("Здесь ты можешь почитать всё обо всех персонажах, посмотреть советы по сборкам и союзникам. Однако, никогда не бойся выходить за рамки — вдруг ты откроешь новую мету? Когда дочитаешь — выходи в меню.", 14, "📚 Энциклопедия")
			if btn_db_back and is_instance_valid(btn_db_back):
				btn_db_back.disabled = false
				_show_menu_pointer_for_control(btn_db_back, "up")
		11:
			_set_menu_tut_text("Далее — [b]Инвентарь[/b]! Заходи!", 15, "🎒 Инвентарь")
			if btn_menu_inv and is_instance_valid(btn_menu_inv):
				_set_hub_card_disabled(btn_menu_inv, false)
				_show_menu_pointer_for_control(btn_menu_inv)
		12:
			_set_menu_tut_text("Здесь можно посмотреть, какие у тебя есть персонажи и какие Эйдолоны, а также почитать, что эти Эйдолоны делают и какие баффы дают.\n\nТеперь перейди на вкладку [b]«🛡 Реликвии»[/b]!", 16, "🛡 Вкладка реликвий")
			if btn_tab_relics and is_instance_valid(btn_tab_relics):
				btn_tab_relics.disabled = false
				_show_menu_pointer_for_control(btn_tab_relics, "down")
		13:
			_set_menu_tut_text("Лишние или слабые реликвии можно уничтожать (разбирать) на Осколки!\n\nНажми [b]«🗑 Разобрать»[/b] на любой 3★ реликвии, чтобы превратить её в Осколки для прокачки!", 17, "🗑 Разбор реликвий")
			if btn_tab_relics and is_instance_valid(btn_tab_relics):
				btn_tab_relics.disabled = false
			if inv_characters_grid and inv_relics_container:
				inv_characters_grid.visible = false
				inv_cones_grid.visible = false
				inv_relics_container.visible = true
				_refresh_inventory_relics()
			if tut_dismantle_btn and is_instance_valid(tut_dismantle_btn):
				tut_dismantle_btn.disabled = false
				_show_menu_pointer_for_control(tut_dismantle_btn, "left")
		14:
			_set_menu_tut_text("Отлично! Реликвия разобрана на Осколки. Теперь у тебя есть универсальный ресурс для улучшения экипировки!\n\nВозвращайся в меню.", 18, "🔮 Осколки получены")
			if btn_inv_back and is_instance_valid(btn_inv_back):
				btn_inv_back.disabled = false
				_show_menu_pointer_for_control(btn_inv_back, "up")
		15:
			TeamConfig.coins = max(TeamConfig.coins, 500)
			_update_coins_display()
			_set_menu_tut_text("Далее — [b]Магазин[/b]!", 19, "🛒 Магазин")
			if btn_menu_shop and is_instance_valid(btn_menu_shop):
				_set_hub_card_disabled(btn_menu_shop, false)
				_show_menu_pointer_for_control(btn_menu_shop)
		16:
			_set_menu_tut_text("Здесь ты можешь купить любого персонажа, который тебе нравится (если у тебя, конечно, есть на него деньги). Стандартные 5* персонажи стоят 1850, а 4* — 480 монет. Если ты покупаешь персонажа, который у тебя есть, то ты получаешь на него +1 Эйдолон. Сейчас купи [b]Арсения[/b] — он отлично подойдёт к Вике и Каори в команду!", 20, "🛒 Покупка персонажа")
			_lock_shop_except_arseniy()
		17:
			_set_menu_tut_text("Отлично! Арсений — персонаж Гармонии. Он бафает других персонажей в отряде. Теперь выходи и перейдём К ГАЧЕ...", 21, "🛒 Возврат в меню")
			if btn_shop_back and is_instance_valid(btn_shop_back):
				btn_shop_back.disabled = false
				_show_menu_pointer_for_control(btn_shop_back, "up")
		18:
			_set_menu_tut_text("Жми на [b]Гачу[/b]!", 22, "✨ Призыв героев")
			if btn_menu_gacha and is_instance_valid(btn_menu_gacha):
				_set_hub_card_disabled(btn_menu_gacha, false)
				_show_menu_pointer_for_control(btn_menu_gacha)
		19:
			TeamConfig.shine += 1
			_update_coins_display()
			_set_menu_tut_text("Это гача! Здесь ты можешь получить Лимитированных 5* персонажей, которых нельзя получить никаким другим способом. Сверху ты можешь выбрать баннер персонажа, которого хочешь покрутить. Перед тем, как кого-то крутить, рекомендую почитать, что этот персонаж делает. Сейчас я дам тебе один Блеск Свечения — это валюта, за которую можно крутить Баннеры. 1 Блеск Свечения = 1 крутка. Давай посмотрим, что тебе выпадет!", 23, "✨ Испытай удачу")
			_lock_gacha_except_one_pull()
		20:
			# Немедленно разблокируем все элементы экрана гачи и хаба
			is_menu_tutorial = false
			TeamConfig.menu_tutorial_completed = true
			TeamConfig.save_game()

			if gacha_screen and is_instance_valid(gacha_screen):
				var btn_b: Button = gacha_screen.find_child("BtnGachaBack", true, false)
				if btn_b: btn_b.disabled = false
				var btn_1: Button = gacha_screen.find_child("BtnPull1", true, false)
				if btn_1: btn_1.disabled = false
				var btn_10: Button = gacha_screen.find_child("BtnPull10", true, false)
				if btn_10: btn_10.disabled = false
				if banner_select_option:
					banner_select_option.disabled = false

			if btn_shop_back: btn_shop_back.disabled = false
			if btn_inv_back: btn_inv_back.disabled = false

			_lock_hub_buttons(false)
			_set_hub_card_disabled(btn_menu_levels, false)
			_set_hub_card_disabled(btn_menu_chars, false)
			_set_hub_card_disabled(btn_menu_relics, false)
			_set_hub_card_disabled(btn_menu_db, false)
			_set_hub_card_disabled(btn_menu_inv, false)
			_set_hub_card_disabled(btn_menu_shop, false)
			_set_hub_card_disabled(btn_menu_gacha, false)

			var finish_txt := "Отлично! Тебе выпала [b]Сара[/b]. Сара — хиллер. Она может лечить союзников. Более того — она может блокировать смерть и оставлять союзников живыми на 1 ед. ХП. Она точно будет тебе полезна!\n\nКогда ты пройдёшь 5 уровень, то бесплатно получишь сразу [b]10 Блесков Свечения[/b] и сможешь погрузиться в гачу на полную катушку! Так что быстрее — я жду тебя на пятом уровне!"
			if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
				menu_guide_overlay.hide_pointer()
				menu_guide_overlay.set_dialog("🎉 Поздравляем!", finish_txt, "ФИНАЛ", true, "Вперед! ⚔", _on_menu_tut_next_pressed)
			else:
				_set_menu_tut_text(finish_txt, 24, "🎉 Поздравляем!")
				if menu_tut_btn:
					menu_tut_btn.text = "Вперед! ⚔"
					menu_tut_btn.visible = true

func _on_menu_tut_next_pressed() -> void:
	match menu_tut_step:
		20:
			is_menu_tutorial = false
			TeamConfig.menu_tutorial_completed = true
			TeamConfig.save_game()
			if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
				menu_guide_overlay.queue_free()
				menu_guide_overlay = null
			elif menu_tut_overlay and is_instance_valid(menu_tut_overlay):
				menu_tut_overlay.queue_free()
			if menu_tut_pointer and is_instance_valid(menu_tut_pointer):
				menu_tut_pointer.queue_free()

			# 1. Разблокируем все элементы экрана гачи
			if gacha_screen and is_instance_valid(gacha_screen):
				var btn_b: Button = gacha_screen.find_child("BtnGachaBack", true, false)
				if btn_b: btn_b.disabled = false
				var btn_1: Button = gacha_screen.find_child("BtnPull1", true, false)
				if btn_1: btn_1.disabled = false
				var btn_10: Button = gacha_screen.find_child("BtnPull10", true, false)
				if btn_10: btn_10.disabled = false

			# 2. Разблокируем магазин и инвентарь
			if btn_shop_back: btn_shop_back.disabled = false
			if btn_inv_back: btn_inv_back.disabled = false
			for child in shop_grid.get_children():
				var btn: Button = child.find_child("Button", true, false)
				if btn: btn.disabled = false

			# 3. Возвращаемся в хаб (Главное меню)
			_show_screen("hub")
			_lock_hub_buttons(false)

			# 4. Гарантированно разблокируем ВСЕ разделы меню
			_set_hub_card_disabled(btn_menu_levels, false)
			_set_hub_card_disabled(btn_menu_chars, false)
			_set_hub_card_disabled(btn_menu_relics, false)
			_set_hub_card_disabled(btn_menu_db, false)
			_set_hub_card_disabled(btn_menu_inv, false)
			_set_hub_card_disabled(btn_menu_shop, false)
			_set_hub_card_disabled(btn_menu_gacha, false)

			if hub_overview_panel:
				hub_overview_panel.visible = true
				_refresh_hub_overview()
			if notification_label:
				notification_label.text = "✓ Обучение завершено! Все разделы меню открыты."

func _set_menu_tut_text(txt: String, step_num: int = 0, title: String = "🧭 Обучение в Меню") -> void:
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		var badge := ("ШАГ %d / 20" % step_num) if step_num > 0 else "✦ ОБУЧЕНИЕ ✦"
		menu_guide_overlay.set_dialog(title, txt, badge)
	elif menu_tut_label and is_instance_valid(menu_tut_label):
		menu_tut_label.text = txt

func _set_text_or_tut(txt: String) -> void:
	_set_menu_tut_text(txt)

func _show_menu_pointer(pos: Vector2) -> void:
	if menu_tut_pointer and is_instance_valid(menu_tut_pointer):
		menu_tut_pointer.global_position = pos
		menu_tut_pointer.visible = true

func _show_menu_pointer_for_control(ctrl: Control, arrow_dir: String = "auto") -> void:
	if not ctrl or not is_instance_valid(ctrl):
		return
	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.point_at(ctrl, arrow_dir)
	elif menu_tut_pointer and is_instance_valid(menu_tut_pointer):
		var w: float = ctrl.size.x if ctrl.size.x > 10.0 else ctrl.custom_minimum_size.x
		var px: float = ctrl.global_position.x + (w - 36.0) * 0.5
		var py: float = ctrl.global_position.y - 65.0
		_show_menu_pointer(Vector2(px, py))

func _lock_hub_buttons(locked: bool) -> void:
	var lock_levels: bool = locked and is_menu_tutorial and (menu_tut_step > 1)
	_set_hub_card_disabled(btn_menu_levels, lock_levels)
	_set_hub_card_disabled(btn_menu_chars, locked)
	_set_hub_card_disabled(btn_menu_relics, locked and not TeamConfig.menu_tutorial_completed)
	_set_hub_card_disabled(btn_menu_db, locked)
	_set_hub_card_disabled(btn_menu_inv, locked)
	_set_hub_card_disabled(btn_menu_shop, locked)
	_set_hub_card_disabled(btn_menu_gacha, locked)
	if btn_menu_memory_hall:
		_set_hub_card_disabled(btn_menu_memory_hall, locked)

func _lock_shop_except_arseniy() -> void:
	var target_btn: Button = null
	for child in shop_grid.get_children():
		var btn: Button = child.find_child("Button", true, false)
		if btn:
			btn.disabled = true
			if "arseniy" in child.name.to_lower():
				btn.disabled = false
				target_btn = btn
	if btn_shop_back:
		btn_shop_back.disabled = true
	if target_btn:
		_show_menu_pointer_for_control(target_btn, "up")

func _lock_gacha_except_one_pull() -> void:
	var btn_1: Button = gacha_screen.find_child("BtnPull1", true, false)
	if not btn_1:
		btn_1 = gacha_screen.find_child("Button", true, false)
	var btn_10: Button = gacha_screen.find_child("BtnPull10", true, false)
	var btn_back: Button = gacha_screen.find_child("BtnGachaBack", true, false)
	if btn_10:
		btn_10.disabled = true
	if btn_back:
		btn_back.disabled = true
	if btn_1:
		btn_1.disabled = false
		_show_menu_pointer_for_control(btn_1, "down")

func _show_skip_menu_tutorial_dialog() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 280)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(1.0, 0.85, 0.25, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⏩ Пропустить обучение в меню?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(title)

	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.custom_minimum_size = Vector2(0, 130)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.text = "Вы действительно хотите пропустить обучение в меню?\n\n[b]Вы автоматически получите:[/b]\n• Персонажей [b]Арсений[/b] и [b]Сара[/b]\n• Комплект 4★ реликвий Хаоса и 30 🔮 Осколков\n• 500 монет и 1 ✨ Блеск Свечения\n• Полную свободу действий во всех разделах меню!"
	vbox.add_child(desc)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_confirm := Button.new()
	btn_confirm.text = "Да, пропустить"
	btn_confirm.custom_minimum_size = Vector2(160, 42)
	var c_sb := StyleBoxFlat.new()
	c_sb.bg_color = Color(0.20, 0.50, 0.85, 1.0)
	c_sb.set_corner_radius_all(8)
	btn_confirm.add_theme_stylebox_override("normal", c_sb)
	btn_confirm.pressed.connect(func():
		overlay.queue_free()
		_execute_skip_menu_tutorial()
	)
	btn_row.add_child(btn_confirm)

	var btn_cancel := Button.new()
	btn_cancel.text = "Отмена"
	btn_cancel.custom_minimum_size = Vector2(120, 42)
	var can_sb := StyleBoxFlat.new()
	can_sb.bg_color = Color(0.25, 0.25, 0.30, 1.0)
	can_sb.set_corner_radius_all(8)
	btn_cancel.add_theme_stylebox_override("normal", can_sb)
	btn_cancel.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(btn_cancel)

func _execute_skip_menu_tutorial() -> void:
	is_menu_tutorial = false
	TeamConfig.menu_tutorial_completed = true

	# Разблокируем Арсения и Сару, если ещё не открыты
	if not ("arseniy" in TeamConfig.unlocked_characters):
		TeamConfig.unlocked_characters.append("arseniy")
		TeamConfig.set_saved_build("arseniy", {"light_cone": "", "eidolon": 0})
	if not ("sara" in TeamConfig.unlocked_characters):
		TeamConfig.unlocked_characters.append("sara")
		TeamConfig.set_saved_build("sara", {"light_cone": "", "eidolon": 0})

	# Награды
	TeamConfig.relic_shards = max(TeamConfig.relic_shards, 30)
	TeamConfig.coins = max(TeamConfig.coins, 500)
	TeamConfig.shine = max(TeamConfig.shine, 1)

	# Выдадим 4★ реликвии Хаоса (Голова и Руки), если их ещё нет
	var has_chaos_head := false
	var has_chaos_hands := false
	for r in TeamConfig.relic_inventory:
		if r.get("set_id", "") == "chaos":
			if r.get("slot", "") == "head": has_chaos_head = true
			if r.get("slot", "") == "hands": has_chaos_hands = true
	if not has_chaos_head:
		var head_r := RelicSystem.generate_relic("chaos", "head", 4)
		TeamConfig.relic_inventory.append(head_r)
	if not has_chaos_hands:
		var hands_r := RelicSystem.generate_relic("chaos", "hands", 4)
		TeamConfig.relic_inventory.append(hands_r)

	TeamConfig.save_game()

	if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
		menu_guide_overlay.queue_free()
		menu_guide_overlay = null

	_lock_hub_buttons(false)
	_show_screen("hub")
	if hub_overview_panel:
		hub_overview_panel.visible = true
		_refresh_hub_overview()
	if notification_label:
		notification_label.text = "✓ Обучение в меню пропущено. Все разделы разблокированы!"

# Проверка выбора Тела на %ХП и Ног на %ХП
func _check_tut_body_feet_step() -> void:
	if is_menu_tutorial and menu_tut_step == 7:
		var b_id := String(opt_body.get_item_metadata(opt_body.selected))
		var f_id := String(opt_feet.get_item_metadata(opt_feet.selected))
		if b_id == "hp_pct" and f_id == "hp_pct":
			_run_menu_tut_step(8)

# Проверка выбора Квантовой сферы и Веревки ВЭ
func _check_tut_sphere_rope_step() -> void:
	if is_menu_tutorial and menu_tut_step == 9:
		var s_id := String(opt_sphere.get_item_metadata(opt_sphere.selected))
		var r_id := String(opt_rope.get_item_metadata(opt_rope.selected))
		if s_id == "quantum_dmg" and r_id == "err":
			_run_menu_tut_step(10)

# --- ЭКРАН ПОДГОТОВКИ ОТРЯДА ПЕРЕД БОЕМ (ДЛЯ УРОВНЕЙ 6-10) ---
var level_task_label: Label
var level_enemies_label: RichTextLabel
var level_preview_panel: PanelContainer

func _build_level_team_setup_screen() -> void:
	level_team_setup_screen = VBoxContainer.new()
	level_team_setup_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_team_setup_screen.add_theme_constant_override("separation", 10)
	level_team_setup_screen.visible = false
	add_child(level_team_setup_screen)

	level_setup_title = Label.new()
	level_setup_title.text = "⚔ Подготовка к бою: Уровень 6"
	level_setup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_setup_title.add_theme_font_size_override("font_size", 26)
	level_team_setup_screen.add_child(level_setup_title)

	# Выбор персонажей из ростера
	var roster_label := Label.new()
	roster_label.text = "Доступные персонажи (нажмите, чтобы добавить в отряд):"
	roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roster_label.add_theme_font_size_override("font_size", 15)
	roster_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
	level_team_setup_screen.add_child(roster_label)

	# Горизонтальная карусель: 1 ряд крупных карточек персонажей с навигацией и плавной прокруткой
	var roster_carousel_row := HBoxContainer.new()
	roster_carousel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	roster_carousel_row.add_theme_constant_override("separation", 8)
	roster_carousel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_team_setup_screen.add_child(roster_carousel_row)

	var btn_roster_left := Button.new()
	btn_roster_left.text = "◀"
	btn_roster_left.custom_minimum_size = Vector2(44, 205)
	btn_roster_left.add_theme_font_size_override("font_size", 22)
	roster_carousel_row.add_child(btn_roster_left)

	var scroll_roster := SmoothScrollContainer.new()
	scroll_roster.custom_minimum_size = Vector2(1000, 215)
	scroll_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_roster.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_roster.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	roster_carousel_row.add_child(scroll_roster)

	btn_roster_left.pressed.connect(func(): scroll_roster.scroll_h_by(-320.0))

	var btn_roster_right := Button.new()
	btn_roster_right.text = "▶"
	btn_roster_right.custom_minimum_size = Vector2(44, 205)
	btn_roster_right.add_theme_font_size_override("font_size", 22)
	btn_roster_right.pressed.connect(func(): scroll_roster.scroll_h_by(320.0))
	roster_carousel_row.add_child(btn_roster_right)

	level_team_roster_container = HBoxContainer.new()
	level_team_roster_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	level_team_roster_container.add_theme_constant_override("separation", 14)
	scroll_roster.add_child(level_team_roster_container)

	# Кнопки сохранения и загрузки отряда
	var team_btn_hbox := HBoxContainer.new()
	team_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	team_btn_hbox.add_theme_constant_override("separation", 16)
	level_team_setup_screen.add_child(team_btn_hbox)

	var btn_save_lvl := Button.new()
	btn_save_lvl.text = "💾 Сохранить отряд"
	btn_save_lvl.custom_minimum_size = Vector2(170, 36)
	btn_save_lvl.pressed.connect(_show_save_level_team_dialog)
	team_btn_hbox.add_child(btn_save_lvl)

	var btn_load_lvl := Button.new()
	btn_load_lvl.text = "📂 Загрузить отряд"
	btn_load_lvl.custom_minimum_size = Vector2(170, 36)
	btn_load_lvl.pressed.connect(_show_load_level_team_dialog)
	team_btn_hbox.add_child(btn_load_lvl)

	# 4 Слота отряда
	level_team_slots_container = HBoxContainer.new()
	level_team_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	level_team_slots_container.add_theme_constant_override("separation", 20)
	level_team_setup_screen.add_child(level_team_slots_container)

	for i in 4:
		var slot_panel := _create_level_slot_panel(i)
		level_team_slots_container.add_child(slot_panel)

	# Панель информации о Задании и Врагах Уровня
	level_preview_panel = PanelContainer.new()
	level_preview_panel.custom_minimum_size = Vector2(700, 95)
	level_preview_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	level_preview_panel.add_theme_stylebox_override("panel", sb)
	level_team_setup_screen.add_child(level_preview_panel)

	var prev_vbox := VBoxContainer.new()
	prev_vbox.add_theme_constant_override("separation", 4)
	level_preview_panel.add_child(prev_vbox)
	
	level_task_label = Label.new()
	level_task_label.text = "🎯 Задание: Победить всех врагов за 8 Циклов"
	level_task_label.add_theme_font_size_override("font_size", 16)
	level_task_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	prev_vbox.add_child(level_task_label)

	level_enemies_label = RichTextLabel.new()
	level_enemies_label.custom_minimum_size = Vector2(0, 50)
	level_enemies_label.bbcode_enabled = true
	level_enemies_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_enemies_label.add_theme_font_size_override("normal_font_size", 14)
	prev_vbox.add_child(level_enemies_label)
	
	level_rewards_label = Label.new()
	level_rewards_label.add_theme_font_size_override("font_size", 14)
	level_rewards_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	prev_vbox.add_child(level_rewards_label)

	# Выбор Техники Инициатора
	var init_hbox := HBoxContainer.new()
	init_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	init_hbox.add_theme_constant_override("separation", 12)
	level_team_setup_screen.add_child(init_hbox)

	var init_lbl := Label.new()
	init_lbl.text = "Атакующая техника (Инициатор боя):"
	init_lbl.add_theme_font_size_override("font_size", 15)
	init_hbox.add_child(init_lbl)

	level_initiator_option = OptionButton.new()
	level_initiator_option.custom_minimum_size = Vector2(280, 38)
	init_hbox.add_child(level_initiator_option)

	# Кнопка старта боя и отмена
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 25)
	level_team_setup_screen.add_child(btn_hbox)

	var btn_start_battle := Button.new()
	btn_start_battle.text = "⚔ В БОЙ!"
	btn_start_battle.custom_minimum_size = Vector2(220, 48)
	btn_start_battle.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.15, 0.65, 0.35, 1.0)
	btn_sb.set_corner_radius_all(10)
	btn_start_battle.add_theme_stylebox_override("normal", btn_sb)
	btn_start_battle.pressed.connect(_start_custom_level_battle)
	btn_hbox.add_child(btn_start_battle)

	var btn_setup_shop := Button.new()
	btn_setup_shop.text = "🛒 Магазин"
	btn_setup_shop.custom_minimum_size = Vector2(160, 48)
	btn_setup_shop.add_theme_font_size_override("font_size", 16)
	btn_setup_shop.pressed.connect(func():
		_refresh_shop_ui()
		_show_screen("shop")
	)
	btn_hbox.add_child(btn_setup_shop)

	var btn_back := Button.new()
	btn_back.text = "↩ Отмена"
	btn_back.custom_minimum_size = Vector2(160, 48)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(func():
		if selected_memory_hall_floor > 0:
			selected_memory_hall_floor = 0
			_refresh_memory_hall_screen()
			_show_screen("memory_hall")
		elif not selected_dungeon_for_battle.is_empty():
			selected_dungeon_for_battle = ""
			_show_screen("relic_farming")
		else:
			_show_screen("levels")
	)
	btn_hbox.add_child(btn_back)
	
# Панель слота отряда
func _create_level_slot_panel(slot_idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 210)
	panel.clip_contents = true
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.16)
	sb.border_color = Color(0.4, 0.5, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.name = "SlotVBox"
	vbox.z_index = 1
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var slot_lbl := Label.new()
	slot_lbl.text = "Слот %d" % (slot_idx + 1)
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 14)
	slot_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	vbox.add_child(slot_lbl)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Пусто"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_lbl)

	var remove_btn := Button.new()
	remove_btn.name = "RemoveButton"
	remove_btn.text = "Убрать"
	remove_btn.custom_minimum_size = Vector2(120, 36)
	remove_btn.pressed.connect(_remove_char_from_level_slot.bind(slot_idx))
	remove_btn.visible = false
	vbox.add_child(remove_btn)

	return panel

# Крупная карточка персонажа в карусели ростера при подготовке к уровню
func _create_level_roster_card(char_id: String, on_click: Callable) -> Button:
	var c_data := CharacterRegistry.get_character(char_id)
	if c_data.is_empty():
		return null

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(165, 195)
	btn.clip_contents = true
	btn.pressed.connect(on_click)

	# Сплеш-арт на заднем фоне карточки персонажа
	var splash_tex: Texture2D = CharacterRegistry.get_character_splash(char_id)
	if splash_tex != null:
		var splash_rect := TextureRect.new()
		splash_rect.name = "RosterCardSplashBG"
		splash_rect.texture = splash_tex
		splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		splash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		splash_rect.modulate = Color(0.38, 0.38, 0.45, 0.42)
		splash_rect.z_index = 0
		btn.add_child(splash_rect)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	vbox.z_index = 1
	btn.add_child(vbox)

	var elem_lbl := Label.new()
	elem_lbl.text = CombatConstants.get_element_label(c_data.element)
	elem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_lbl.add_theme_font_size_override("font_size", 14)
	elem_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(c_data.element))
	vbox.add_child(elem_lbl)

	var name_lbl := Label.new()
	name_lbl.text = c_data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(150, 0)
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var path_lbl := Label.new()
	path_lbl.text = "[%s]" % CharacterRegistry.get_path_name(c_data.path)
	path_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_lbl.add_theme_font_size_override("font_size", 11)
	path_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(path_lbl)

	var build := TeamConfig.get_saved_build(char_id)
	var e_lvl: int = int(build.get("eidolon", 0))
	var e_lbl := Label.new()
	e_lbl.text = "★ E%d" % e_lvl
	e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_lbl.add_theme_font_size_override("font_size", 12)
	e_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(e_lbl)

	var add_lbl := Label.new()
	add_lbl.text = "+ В отряд"
	add_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_lbl.add_theme_font_size_override("font_size", 11)
	add_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox.add_child(add_lbl)

	return btn

# Открытие меню подготовки для уровня
func _open_level_team_setup(level_num: int) -> void:
	selected_dungeon_for_battle = ""
	selected_level_for_battle = level_num
	level_setup_title.text = "⚔ Подготовка к бою: Уровень %d" % level_num

	# Автоматически переносим отряд из прошлого боя / сохранения, если слоты еще не заполнены
	var has_slot := false
	for s in _level_team:
		if s != null:
			has_slot = true
			break
	if not has_slot:
		if not TeamConfig.team_members.is_empty():
			for i in range(mini(4, TeamConfig.team_members.size())):
				var member: Dictionary = TeamConfig.team_members[i]
				var c_id: String = String(member.get("id", ""))
				if TeamConfig.is_character_unlocked(c_id):
					_level_team[i] = member.duplicate(true)
		elif not TeamConfig.last_used_team.is_empty():
			for i in range(mini(4, TeamConfig.last_used_team.size())):
				var member: Dictionary = TeamConfig.last_used_team[i]
				var c_id: String = String(member.get("id", ""))
				if TeamConfig.is_character_unlocked(c_id):
					_level_team[i] = member.duplicate(true)
		else:
			for i in range(mini(4, TeamConfig.unlocked_characters.size())):
				var c_id := TeamConfig.unlocked_characters[i]
				_level_team[i] = TeamConfig.get_saved_build(c_id)

	# Заполняем КРУПНЫЕ плитки персонажей карусели
	for child in level_team_roster_container.get_children():
		level_team_roster_container.remove_child(child)
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var card := _create_level_roster_card(char_id, _add_char_to_level_slot.bind(char_id))
		if card != null:
			level_team_roster_container.add_child(card)
	
	if level_num == 6 and not "level_6" in TeamConfig.completed_levels:
		_show_level_6_setup_tutorial()
		
	# Обновление текста Задания и Врагов для уровня
	_update_level_preview_info(level_num)
	_refresh_level_team_slots()
	_show_screen("level_team_setup")

	# Запуск встроенного обучения для 5 Уровня!
	if level_num == 5:
		_show_level_5_setup_tutorial()

func _update_level_preview_info(level_num: int) -> void:
	match level_num:
		5:
			level_task_label.text = "🎯 Задание: Победить всех врагов за 8 Циклов"
			level_enemies_label.text = "👹 [b]Элитный Страж (x1)[/b] — Уязвимости: [color=cyan]❄ Лёд[/color], [color=gray]⚔ Физ.[/color], [color=yellow]✨ Мнимый[/color], [color=green]🌪 Ветер[/color]\n🤖 [b]Солдат Пустоты (x2)[/b] — Уязвимости: [color=cyan]❄ Лёд[/color], [color=red]🔥 Огонь[/color], [color=purple]⚡ Электро[/color]"
			level_rewards_label.text = "🎁 Награда: +10 Блеска Свечения"
		6:
			level_task_label.text = "🎯 Задание: 1. Победить за 4 Цикла  2. Без погибших союзников\n✨ Особенность: Урон персонажей Эрудиции увеличен на +20%"
			level_enemies_label.text = "🤖 [b]Солдат Пустоты (x5)[/b] — Уязвимости: [color=cyan]❄ Лёд[/color], [color=red]🔥 Огонь[/color], [color=purple]⚡ Электро[/color]"
			level_rewards_label.text = "🎁 Награда: 5 Новых комплектов реликвий + 300 Монет"
		7:
			level_task_label.text = "🎯 Задание: 3★ (≤8 циклов) | 2★ (≤10 циклов) | 1★ (≤15 циклов)\n✨ Особенность: Крит. шанс всех союзников увеличен на +50% на 3 хода"
			level_enemies_label.text = "👹 [b]Элитный Страж (x3)[/b] — Уязвимости: [color=cyan]❄ Лёд[/color], [color=gray]⚔ Физ.[/color], [color=yellow]✨ Мнимый[/color], [color=green]🌪 Ветер[/color]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 2 Блеска Свечения за 3★"
		8:
			level_task_label.text = "🎯 Задание: 3★ (≤5 циклов) | 2★ (≤8 циклов) | 1★ (≤12 циклов)\n✨ Особенность: Персонажи Охоты игнорируют 40% Защиты врагов"
			level_enemies_label.text = "👾 [b]Повелитель Бездны [60% ХП][/b] — Уязвимости: [color=gray]⚔ Физ.[/color], [color=green]🌪 Ветер[/color], [color=yellow]✨ Мнимый[/color]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 3 Блеска Свечения за 3★"
		9:
			level_task_label.text = "🎯 Задание: 3★ (≤6 циклов) | 2★ (≤8 циклов) | 1★ (≤12 циклов)\n✨ Особенность: Сверхспособности наносят +30% Чистого урона"
			level_enemies_label.text = "👹 [b]Элитный Страж (x2)[/b] + 🤖 [b]Солдат Пустоты (x3)[/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 5 Новых комплектов реликвий"
		10:
			level_task_label.text = "🎯 Задание: 1. 3★ (≤8 ц) | 2★ (≤10 ц) | 1★ (≤12 ц)  2. Без погибших союзников\n✨ Аномалия: Враги +30% СКР. Старт хода Изобилия/Сохранения лечит пати на 8% ХП/Защиты + 150"
			level_enemies_label.text = "👾 [b]Повелитель Бездны [130% ХП, 200% АТК][/b] + 🤖 [b]Солдат Бездны (x2) [200% ХП, 250% АТК][/b]"
			level_rewards_label.text = "🎁 Награда: 1★ 200 Монет | 2★ Сеты: Доктор наук и Оборона планеты | 3★ +10 Блеска Свечения"
		11:
			level_task_label.text = "🎯 Задание: 3★ (≤5 циклов) | 2★ (≤8 циклов) | 1★ (≤12 циклов)\n✨ Аномалия: Взрывы Заражённых (<30% ХП) наносят 15% урона соседним врагам"
			level_enemies_label.text = "☣ [b]Заражённый (x5)[/b] — Уязвимости: [color=gray]⚔ Физ.[/color], [color=purple]⚡ Электро[/color], [color=green]🌪 Ветер[/color]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 1 Блеск Свечения за 3★"
		12:
			level_task_label.text = "🎯 Задание: 3★ (≤6 циклов) | 2★ (≤9 циклов) | 1★ (≤13 циклов)\n✨ Аномалия: Пробитие уязвимости споры или противника продвигает союзника на 30%"
			level_enemies_label.text = "🧬 [b]Орто Мутант [110% ХП][/b] + ☣ [b]Заражённый (x2) [130% ХП][/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 1 Блеск Свечения за 3★"
		13:
			level_task_label.text = "🎯 Задание: 3★ (≤6 циклов) | 2★ (≤9 циклов) | 1★ (≤14 циклов)\n✨ Аномалия: Урон Пробития +50%. Навыки союзников снижают защиту целей на -10% на 2 хода"
			level_enemies_label.text = "🛡 [b]Бронированный Страж (x2) [ЗАЩ 1250][/b] + 👹 [b]Элитный Страж [220% ХП][/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 2 Блеска Свечения за 3★"
		14:
			level_task_label.text = "🎯 Задание: 3★ (≤7 циклов) | 2★ (≤10 циклов) | 1★ (≤15 циклов)\n✨ Аномалия: Гибель любого противника восстанавливает 10 энергии и лечит отряд на 5% ХП"
			level_enemies_label.text = "🧬 [b]Орто Мутант[/b] + 👹 [b]Элитный Страж[/b] + ☣ [b]Заражённый (x2)[/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 2 Блеска Свечения за 3★"
		15:
			level_task_label.text = "🎯 Задание: 3★ (≤8 циклов) | 2★ (≤11 циклов) | 1★ (≤15 циклов)\n✨ Аномалия: Пробитие стойкости Вируса сносит 2 слоя Файрвола и 10% ХП. Бинарный урон +30%"
			level_enemies_label.text = "👾 [b]Серверный Вирус [МИНИ-БОСС, 4 слоя][/b] + ☣ [b]Заражённый (x2)[/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 6 Блеска Свечения за 3★"
		16:
			level_task_label.text = "🎯 Задание: 3★ (≤7 циклов) | 2★ (≤10 циклов) | 1★ (≤14 циклов)\n✨ Аномалия: Скорость союзников +20 ед. Сверхспособность продвигает следующее действие на 25%"
			level_enemies_label.text = "👾 [b]Серверный Вирус (x2)[/b] + 🤖 [b]Солдат Бездны (x2) [300% ХП][/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 2 Блеска Свечения за 3★"
		17:
			level_task_label.text = "🎯 Задание: 3★ (≤7 циклов) | 2★ (≤10 циклов) | 1★ (≤14 циклов)\n✨ Аномалия: Уничтожение споры наносит 40 стойкости обоим Мутантам и восстанавливает 1 ОН"
			level_enemies_label.text = "🧬 [b]Орто Мутант (x2)[/b] + 🛡 [b]Бронированный Страж [ЗАЩ 1300][/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 2 Блеска Свечения за 3★"
		18:
			level_task_label.text = "🎯 Задание: 3★ (≤8 циклов) | 2★ (≤11 циклов) | 1★ (≤15 циклов)\n✨ Аномалия: Урон бонус-атак (FUA) +35%. Наложение дебаффа повышает получаемый врагом урон на +15% на 2 хода"
			level_enemies_label.text = "👾 [b]Повелитель Бездны [180% ХП][/b] + 👹 [b]Элитный Страж (x2) [250% ХП][/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 3 Блеска Свечения за 3★"
		19:
			level_task_label.text = "🎯 Задание: 3★ (≤8 циклов) | 2★ (≤11 циклов) | 1★ (≤15 циклов)\n✨ Аномалия: За каждый уникальный Путь в отряде весь отряд получает +6% к урону и +4% к КШ"
			level_enemies_label.text = "👾 [b]Серверный Вирус[/b] + 🧬 [b]Орто Мутант[/b] + 👹 [b]Элитный Страж[/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 3 Блеска Свечения за 3★"
		20:
			level_task_label.text = "🎯 Задание: 3★ (≤10 циклов) | 2★ (≤14 циклов) | 1★ (≤18 циклов)\n✨ Аномалия: Без маски или в Изоляции Силуэт получает +40% урона и +50% КУ. Добивание солдата дает +30 энергии"
			level_enemies_label.text = "🎭 [b]Силуэт в Маске [ФИНАЛЬНЫЙ БОСС, 2 Фазы][/b] + 🤖 [b]Солдат Бездны (x2)[/b]"
			level_rewards_label.text = "🎁 Награда: 50 Монет за звезду + 8 Блеска Свечения за 3★"
		_:
			level_task_label.text = "🎯 Задание: Уничтожить волны противников"
			level_enemies_label.text = "👹 [b]Враги Уровня %d[/b]" % level_num
			level_rewards_label.text = "🎁 Награда: Монеты и Блеск Свечения"
			
# Обучение на экране подготовки 5 уровня
func _show_level_5_setup_tutorial() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.custom_minimum_size = Vector2(420, 300)
	panel.offset_left = -450
	panel.offset_right = -30
	panel.offset_top = -150
	panel.offset_bottom = 150

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var label := RichTextLabel.new()
	label.custom_minimum_size = Vector2(0, 200)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.bbcode_enabled = true
	label.add_theme_font_size_override("normal_font_size", 15)
	label.text = "Это — меню настройки отряда. Перед каждым боем тебе нужно будет настроить отряд и выбрать персонажей. Всего в отряде может быть 4 персонажа. Данилл и Сара выполняют одну функцию — защищают союзников, поэтому выбери любого из них на свой вкус. Как будешь готов — начинай бой.\n\nТвоя задача — победить противников за 8 циклов. Посмотреть информацию о задании и врагах можно [b]вот тут[/b]! Осторожно — в этот раз противники настоящие, а не ослабленные!"
	vbox.add_child(label)

	var pointer := Label.new()
	pointer.text = "⬇"
	pointer.add_theme_font_size_override("font_size", 54)
	pointer.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	pointer.global_position = level_preview_panel.global_position + Vector2(250, -60)
	add_child(pointer)

	var close_btn := Button.new()
	close_btn.text = "Понятно ➔"
	close_btn.custom_minimum_size = Vector2(180, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.15, 0.55, 0.95, 1.0)
	btn_sb.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", btn_sb)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(func():
		overlay.queue_free()
		pointer.queue_free()
	)
	vbox.add_child(close_btn)

func _show_level_6_setup_tutorial() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.custom_minimum_size = Vector2(420, 300)
	panel.offset_left = -450
	panel.offset_right = -30
	panel.offset_top = -150
	panel.offset_bottom = 150

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var label := RichTextLabel.new()
	label.custom_minimum_size = Vector2(0, 200)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.bbcode_enabled = true
	label.add_theme_font_size_override("normal_font_size", 15)
	label.text = "Отлично! На этом обучение закончено. Последнее, что хочу сказать: за победу в некоторых уровнях ты будешь получать награды, их можно увидеть [b]вот тут[/b]. Это могут быть как персонажи, так и световые конусы.\n\nЗа победу на этом уровне ты откроешь ещё 5 дополнительных сетов реликвий, что облегчит сборку персонажей! Проходи уровни дальше, чтобы открыть все реликвии и получить монеты и крутки!"
	vbox.add_child(label)

	var pointer := Label.new()
	pointer.text = "⬇"
	pointer.add_theme_font_size_override("font_size", 54)
	pointer.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	pointer.global_position = level_preview_panel.global_position + Vector2(250, -60)
	add_child(pointer)

	var close_btn := Button.new()
	close_btn.text = "Понятно ➔"
	close_btn.custom_minimum_size = Vector2(180, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func():
		overlay.queue_free()
		pointer.queue_free()
	)
	vbox.add_child(close_btn)
	
func _add_char_to_level_slot(char_id: String) -> void:
	# Проверка, нет ли уже персонажа в отряде
	for slot in _level_team:
		if slot != null and slot.id == char_id:
			return

	# Ищем свободный слот
	var free_idx := -1
	for i in 4:
		if _level_team[i] == null:
			free_idx = i
			break

	if free_idx != -1:
		# Автоматически загружаем сохраненную сборку игрока!
		_level_team[free_idx] = TeamConfig.get_saved_build(char_id)
		_refresh_level_team_slots()

func _remove_char_from_level_slot(slot_idx: int) -> void:
	_level_team[slot_idx] = null
	_refresh_level_team_slots()

func _refresh_level_team_slots() -> void:
	var children := level_team_slots_container.get_children()
	for i in mini(children.size(), 4):
		var panel: PanelContainer = children[i]
		var vbox: VBoxContainer = panel.get_node_or_null("SlotVBox") as VBoxContainer
		if vbox == null:
			vbox = panel.get_child(0) as VBoxContainer
		if vbox == null:
			continue
		var name_lbl: Label = vbox.get_node("NameLabel")
		var remove_btn: Button = vbox.get_node("RemoveButton")
		var slot_data = _level_team[i]
		var splash_bg: TextureRect = panel.get_node_or_null("LevelSlotSplashBG") as TextureRect

		if slot_data == null:
			name_lbl.text = "Пусто"
			name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			remove_btn.hide()
			if splash_bg != null:
				splash_bg.visible = false
		else:
			var c_data := CharacterRegistry.get_character(slot_data.id)
			var elem: int = int(c_data.get("element", 0))
			var elem_lbl: String = CombatConstants.get_element_label(elem)
			name_lbl.text = "%s\n%s [E%d]" % [
				c_data.get("name", "?"),
				elem_lbl,
				slot_data.get("eidolon", 0)
			]
			name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(elem))
			remove_btn.show()

			var splash_tex: Texture2D = CharacterRegistry.get_character_splash(slot_data.id)
			if splash_tex != null:
				if splash_bg == null:
					splash_bg = TextureRect.new()
					splash_bg.name = "LevelSlotSplashBG"
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

	# Обновляем выбор техники
	_refresh_level_initiator_options()

	# Синхронизируем с TeamConfig и Хабом
	var active_team: Array[Dictionary] = []
	for s_i in 4:
		var slot = _level_team[s_i]
		if slot != null:
			var duplicated: Dictionary = slot.duplicate(true)
			duplicated["slot_idx"] = s_i
			active_team.append(duplicated)
	if not active_team.is_empty():
		TeamConfig.team_members = active_team
		TeamConfig.last_used_team = active_team.duplicate(true)
		TeamConfig.save_game()
		_refresh_hub_overview()

func _refresh_level_initiator_options() -> void:
	level_initiator_option.clear()
	var idx := 0
	for slot in _level_team:
		if slot != null and MemoryHallManager.has_attack_technique(slot.id):
			var data := CharacterRegistry.get_character(slot.id)
			level_initiator_option.add_item(data.get("name", slot.id))
			level_initiator_option.set_item_metadata(idx, slot.id)
			idx += 1

	if idx == 0:
		level_initiator_option.add_item("Без атакующей техники")
		level_initiator_option.set_item_metadata(0, "")

# --- СОХРАНЕНИЕ И ЗАГРУЗКА ОТРЯДОВ В МЕНЮ УРОВНЕЙ ---

func _show_save_level_team_dialog() -> void:
	var has_members := false
	for slot in _level_team:
		if slot != null:
			has_members = true
			break
	if not has_members:
		notification_label.text = "❌ Отряд пуст! Добавьте хотя бы одного персонажа."
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
		var init_idx: int = level_initiator_option.selected
		if init_idx >= 0 and init_idx < level_initiator_option.item_count:
			current_initiator = String(level_initiator_option.get_item_metadata(init_idx))

		TeamConfig.save_team_preset(team_name, _level_team, current_initiator, false)
		save_overlay.queue_free()
		notification_label.text = "✅ Отряд «%s» успешно сохранён!" % team_name
	)
	btn_hbox.add_child(ok_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.pressed.connect(func():
		save_overlay.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

func _show_load_level_team_dialog() -> void:
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

	var populate_list: Callable
	populate_list = func():
		for c in list.get_children():
			c.queue_free()

		var saved_teams: Dictionary = TeamConfig.get_saved_teams(false)
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
			var has_locked_heroes := false
			for slot_i in 4:
				if slot_i < members.size() and members[slot_i] != null:
					var m_data: Dictionary = members[slot_i]
					var m_id: String = String(m_data.get("id", ""))
					var c_reg: Dictionary = CharacterRegistry.get_character(m_id)
					var c_name: String = String(c_reg.get("name", m_id))
					var c_elem: int = int(c_reg.get("element", 0))
					var c_sym: String = String(CombatConstants.ELEMENT_SYMBOLS.get(c_elem, ""))
					var is_unlocked := TeamConfig.is_character_unlocked(m_id)
					if not is_unlocked:
						has_locked_heroes = true
						members_text += "%d. 🔒 [color=red]%s (Не открыт)[/color]   " % [slot_i + 1, c_name]
					else:
						var lc_id: String = String(m_data.get("light_cone", ""))
						var lc_name: String = ""
						if lc_id != "":
							var lc_data: Dictionary = LightConeRegistry.get_cone(lc_id)
							lc_name = " [%s]" % String(lc_data.get("name", lc_id))
						var eid: int = int(m_data.get("eidolon", 0))
						members_text += "%d. %s %s [%s] E%d%s   " % [slot_i + 1, c_sym, c_name, CombatConstants.get_element_short_name(c_elem), eid, lc_name]
				else:
					members_text += "%d. [Пусто]   " % (slot_i + 1)

			var comp_lbl := RichTextLabel.new()
			comp_lbl.bbcode_enabled = true
			comp_lbl.fit_content = true
			comp_lbl.text = members_text
			comp_lbl.add_theme_font_size_override("normal_font_size", 11)
			info_vbox.add_child(comp_lbl)

			var load_btn := Button.new()
			load_btn.text = "📥 Загрузить"
			load_btn.custom_minimum_size = Vector2(100, 36)
			load_btn.pressed.connect(func():
				var skipped_names: Array[String] = []
				for i in 4:
					if i < members.size() and members[i] != null:
						var c_id: String = String(members[i].get("id", ""))
						if TeamConfig.is_character_unlocked(c_id):
							_level_team[i] = members[i].duplicate(true)
						else:
							_level_team[i] = null
							skipped_names.append(c_id)
					else:
						_level_team[i] = null

				_refresh_level_team_slots()

				if initiator_id != "" and TeamConfig.is_character_unlocked(initiator_id):
					for idx in level_initiator_option.item_count:
						if level_initiator_option.get_item_metadata(idx) == initiator_id:
							level_initiator_option.select(idx)
							break

				load_overlay.queue_free()
				if skipped_names.is_empty():
					notification_label.text = "✅ Отряд «%s» успешно загружен!" % t_name
				else:
					notification_label.text = "⚠ Загружен отряд «%s» (персонажи без доступа не добавлены)!" % t_name
			)
			item_hbox.add_child(load_btn)

			var del_btn := Button.new()
			del_btn.text = "🗑"
			del_btn.custom_minimum_size = Vector2(36, 36)
			del_btn.pressed.connect(func():
				TeamConfig.delete_team_preset(t_name, false)
				populate_list.call()
			)
			item_hbox.add_child(del_btn)

	populate_list.call()

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.pressed.connect(func():
		load_overlay.queue_free()
	)
	vbox.add_child(close_btn)

# Запуск боя уровня с собранным отрядом
func _start_custom_level_battle() -> void:
	var team: Array[Dictionary] = []
	for i in 4:
		var slot = _level_team[i]
		if slot != null:
			var duplicated: Dictionary = slot.duplicate(true)
			duplicated["slot_idx"] = i
			team.append(duplicated)

	if team.is_empty():
		notification_label.text = "❌ Выберите хотя бы одного персонажа!"
		return

	TeamConfig.reset()
	if selected_memory_hall_floor > 0:
		TeamConfig.battle_mode = "memory_hall_%d" % selected_memory_hall_floor
	elif not selected_dungeon_for_battle.is_empty():
		TeamConfig.battle_mode = selected_dungeon_for_battle
	else:
		TeamConfig.battle_mode = "level_%d" % selected_level_for_battle
	TeamConfig.team_members = team
	TeamConfig.last_used_team = team.duplicate(true)
	TeamConfig.save_game()

	var init_idx := level_initiator_option.selected
	if init_idx >= 0 and init_idx < level_initiator_option.item_count:
		TeamConfig.battle_initiator_id = String(level_initiator_option.get_item_metadata(init_idx))
	else:
		TeamConfig.battle_initiator_id = ""

	get_tree().change_scene_to_file.call_deferred("res://scenes/battle/battle.tscn")

# Золотое окно наград +10 Блеска Свечения за 5 уровень
func _show_level_5_gold_reward_popup() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(500, 380)
	card_panel.pivot_offset = Vector2(250, 190)
	center.add_child(card_panel)

	# Золотой стиль 5★
	var gold_col := Color(1.0, 0.85, 0.2)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = gold_col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(20)
	card_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card_panel.add_child(vbox)

	var title := Label.new()
	title.text = "✨ НАГРАДА ЗА 5 УРОВЕНЬ!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", gold_col)
	vbox.add_child(title)

	var icon_lbl := Label.new()
	icon_lbl.text = "✨"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 64)
	vbox.add_child(icon_lbl)

	var reward_lbl := Label.new()
	reward_lbl.text = "+10 БЛЕСТКОВ СВЕЧЕНИЯ!"
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 22)
	reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox.add_child(reward_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Разблокирован Уровень 6! Теперь вы можете делать 10 круток в Гаче!"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(desc_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Отлично! ➔"
	btn_cont.custom_minimum_size = Vector2(200, 48)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 18)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = gold_col
	btn_sb.set_corner_radius_all(10)
	btn_cont.add_theme_stylebox_override("normal", btn_sb)
	btn_cont.add_theme_color_override("font_color", Color.BLACK)
	btn_cont.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_cont)

	# Пружинистый вылет
	card_panel.scale = Vector2(0.2, 0.2)
	card_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card_panel, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.12)

# Диалоговое окно подтверждения пропуска боевого обучения
func _show_skip_tutorial_confirmation_dialog() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 240)
	center.add_child(panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(1.0, 0.85, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚠ ПРОПУСК БОЕВОГО ОБУЧЕНИЯ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "Вы уверены, что хотите пропустить обучение? Вы сразу переместитесь на 5 Уровень, получите все награды за 1–4 уровни (персонажей Данилла и Каори, а также 900 монет) и перейдёте к обучению по Меню!"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 15)
	vbox.add_child(msg)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var confirm_btn := Button.new()
	confirm_btn.text = "Да, пропустить"
	confirm_btn.custom_minimum_size = Vector2(180, 48)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	confirm_btn.pressed.connect(func():
		_execute_skip_tutorial()
		overlay.queue_free()
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.custom_minimum_size = Vector2(140, 48)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_hbox.add_child(cancel_btn)

# Выполнение пропуска боевых уровней и запуск Мета-Обучения в меню
func _execute_skip_tutorial() -> void:
	TeamConfig.tutorial_skipped = true # Кнопка сгорает навсегда!

	if menu_tut_overlay and is_instance_valid(menu_tut_overlay):
		menu_tut_overlay.queue_free()
	if menu_tut_pointer and is_instance_valid(menu_tut_pointer):
		menu_tut_pointer.queue_free()

	if not "level_1" in TeamConfig.completed_levels:
		TeamConfig.completed_levels.append("level_1")
		TeamConfig.coins += 150

	if not "level_2" in TeamConfig.completed_levels:
		TeamConfig.completed_levels.append("level_2")
		TeamConfig.coins += 200

	if not "level_3" in TeamConfig.completed_levels:
		TeamConfig.completed_levels.append("level_3")
		TeamConfig.coins += 250

	if not "level_4" in TeamConfig.completed_levels:
		TeamConfig.completed_levels.append("level_4")
		TeamConfig.coins += 300

	if not "danill" in TeamConfig.unlocked_characters:
		TeamConfig.unlocked_characters.append("danill")

	if not "kaori" in TeamConfig.unlocked_characters:
		TeamConfig.unlocked_characters.append("kaori")

	if TeamConfig.current_level_progress < 5:
		TeamConfig.current_level_progress = 5

	TeamConfig.save_game()
	_update_coins_display()

	# Перерисовываем карту (кнопка пропуска пропадет!)
	_build_levels_screen()
	_show_screen("levels")

	is_menu_tutorial = true
	_init_menu_tutorial_ui()
	_run_menu_tut_step(1)
	
	notification_label.text = "⏩ Боевое обучение пропущено! Разблокирован Уровень 5, получены Данилл, Каори и 900 монет!"
	
# Модальное окно Наград за накопленные Звёзды (12 Звёзд = 5 Блеска Свечения)
func _show_star_rewards_modal() -> void:
	var total_stars := TeamConfig.get_total_stars()

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 280)
	center.add_child(panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎁 Награды за Звёзды (⭐ Всего: %d)" % total_stars
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vbox.add_child(row)

	var reward_info := Label.new()
	reward_info.text = "⭐ 12 Звёзд: +5 Блеска Свечения (✨)"
	reward_info.add_theme_font_size_override("font_size", 16)
	row.add_child(reward_info)

	var claim_btn := Button.new()
	claim_btn.custom_minimum_size = Vector2(140, 42)
	
	var is_claimed := "stars_12" in TeamConfig.claimed_star_rewards
	if is_claimed:
		claim_btn.text = "✓ Забрано"
		claim_btn.disabled = true
	else:
		claim_btn.text = "Забрать"
		claim_btn.disabled = (total_stars < 12)
		claim_btn.pressed.connect(func():
			TeamConfig.shine += 5
			TeamConfig.claimed_star_rewards.append("stars_12")
			TeamConfig.save_game()
			_update_coins_display()
			overlay.queue_free()
			notification_label.text = "✨ Получено +5 Блеска Свечения за 12 Звёзд!"
		)
	row.add_child(claim_btn)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

# ==============================================================================
# --- СИСТЕМА ДОБЫЧИ, ИНВЕНТАРЯ И ПРОКАЧКИ РЕЛИКВИЙ ---
# ==============================================================================

func _build_relic_farming_screen() -> void:
	relic_farming_screen = VBoxContainer.new()
	relic_farming_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	relic_farming_screen.add_theme_constant_override("separation", 14)
	relic_farming_screen.visible = false
	add_child(relic_farming_screen)

	var header := Label.new()
	header.text = "🏺 Добыча реликвий"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	relic_farming_screen.add_child(header)

	relic_farming_guarantee_lbl = Label.new()
	relic_farming_guarantee_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_farming_guarantee_lbl.add_theme_font_size_override("font_size", 15)
	relic_farming_guarantee_lbl.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	relic_farming_screen.add_child(relic_farming_guarantee_lbl)

	# Вкладки выбора: Пещерные или Планарные
	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 24)
	relic_farming_screen.add_child(tab_hbox)

	btn_farm_tab_cavern = Button.new()
	btn_farm_tab_cavern.text = "🏛 Пещерные реликвии (7 Данжей)"
	btn_farm_tab_cavern.custom_minimum_size = Vector2(290, 46)
	btn_farm_tab_cavern.add_theme_font_size_override("font_size", 16)
	btn_farm_tab_cavern.pressed.connect(func(): _switch_relic_farming_tab("cavern"))
	tab_hbox.add_child(btn_farm_tab_cavern)

	btn_farm_tab_planar = Button.new()
	btn_farm_tab_planar.text = "🌌 Планарные украшения (3 Данжа)"
	btn_farm_tab_planar.custom_minimum_size = Vector2(290, 46)
	btn_farm_tab_planar.add_theme_font_size_override("font_size", 16)
	btn_farm_tab_planar.pressed.connect(func(): _switch_relic_farming_tab("planar"))
	tab_hbox.add_child(btn_farm_tab_planar)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	relic_farming_screen.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	relic_farming_cards_container = GridContainer.new()
	relic_farming_cards_container.columns = 2
	relic_farming_cards_container.add_theme_constant_override("h_separation", 24)
	relic_farming_cards_container.add_theme_constant_override("v_separation", 20)
	center.add_child(relic_farming_cards_container)

	btn_farming_back = Button.new()
	btn_farming_back.text = "↩ Назад в меню"
	btn_farming_back.custom_minimum_size = Vector2(250, 50)
	btn_farming_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_farming_back.pressed.connect(func():
		_show_screen("hub")
		if is_menu_tutorial and menu_tut_step == 202:
			_run_menu_tut_step(203)
	)
	relic_farming_screen.add_child(btn_farming_back)

func _switch_relic_farming_tab(cat: String) -> void:
	relic_farming_category = cat
	_update_farming_tab_buttons()
	_refresh_relic_farming_ui()

func _update_farming_tab_buttons() -> void:
	if not btn_farm_tab_cavern or not is_instance_valid(btn_farm_tab_cavern):
		return
	if not btn_farm_tab_planar or not is_instance_valid(btn_farm_tab_planar):
		return

	var is_cavern := (relic_farming_category == "cavern")

	var sb_active := StyleBoxFlat.new()
	sb_active.set_corner_radius_all(8)
	sb_active.set_border_width_all(2)

	var sb_inactive := StyleBoxFlat.new()
	sb_inactive.set_corner_radius_all(8)
	sb_inactive.set_border_width_all(1)
	sb_inactive.bg_color = Color(0.10, 0.12, 0.17, 0.8)
	sb_inactive.border_color = Color(0.25, 0.30, 0.40, 0.5)

	if is_cavern:
		sb_active.bg_color = Color(0.18, 0.28, 0.48, 0.95)
		sb_active.border_color = Color(0.40, 0.75, 1.0)
		btn_farm_tab_cavern.add_theme_stylebox_override("normal", sb_active)
		btn_farm_tab_cavern.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		btn_farm_tab_planar.add_theme_stylebox_override("normal", sb_inactive)
		btn_farm_tab_planar.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	else:
		sb_active.bg_color = Color(0.32, 0.16, 0.50, 0.95)
		sb_active.border_color = Color(0.85, 0.45, 1.0)
		btn_farm_tab_planar.add_theme_stylebox_override("normal", sb_active)
		btn_farm_tab_planar.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		btn_farm_tab_cavern.add_theme_stylebox_override("normal", sb_inactive)
		btn_farm_tab_cavern.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))

func _refresh_relic_farming_ui() -> void:
	_update_farming_tab_buttons()

	if relic_farming_guarantee_lbl:
		var lvl: int = TeamConfig.current_level_progress
		var tier_txt := ""
		if lvl < 15:
			tier_txt = "⭐ Прогресс: Ур. %d | Награды (x2): 6× 4★ и 10× 3★ реликвий" % lvl
		elif lvl < 25:
			tier_txt = "⭐⭐ Прогресс: Ур. %d | Награды (x2): Гарантировано 8× 4★ + 8× 3★ реликвий" % lvl
		else:
			tier_txt = "⭐⭐⭐ Прогресс: Ур. %d | Награды (x2): Гарантировано 4× 5★ + 8× 4★ + 6× 3★ реликвий" % lvl
		relic_farming_guarantee_lbl.text = tier_txt

	if not relic_farming_cards_container:
		return

	for child in relic_farming_cards_container.get_children():
		relic_farming_cards_container.remove_child(child)
		child.queue_free()

	var dungeons: Array = RelicSystem.CAVERN_DUNGEONS if (relic_farming_category == "cavern") else RelicSystem.PLANAR_DUNGEONS

	for d in dungeons:
		var d_info: Dictionary = RelicSystem.get_dungeon_info(d.id)

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(480, 240)
		
		var s_box := StyleBoxFlat.new()
		s_box.bg_color = Color(0.09, 0.11, 0.17, 0.96)
		s_box.set_border_width_all(2)
		s_box.border_color = Color(0.28, 0.40, 0.60, 0.75)
		s_box.set_corner_radius_all(12)
		s_box.content_margin_left = 18
		s_box.content_margin_right = 18
		s_box.content_margin_top = 16
		s_box.content_margin_bottom = 16
		card.add_theme_stylebox_override("panel", s_box)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)

		# Шапка карточки: Иконка + Название + Бейдж категории
		var title_hbox := HBoxContainer.new()
		vbox.add_child(title_hbox)

		var d_title := Label.new()
		d_title.text = "%s %s" % [d.icon, d.name]
		d_title.add_theme_font_size_override("font_size", 20)
		d_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
		title_hbox.add_child(d_title)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_hbox.add_child(spacer)

		var tag_lbl := Label.new()
		tag_lbl.text = "[🏛 Пещера]" if relic_farming_category == "cavern" else "[🌌 Планарное]"
		tag_lbl.add_theme_font_size_override("font_size", 12)
		tag_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0) if relic_farming_category == "cavern" else Color(0.85, 0.5, 1.0))
		title_hbox.add_child(tag_lbl)

		# Комплекты
		var sets_lbl := Label.new()
		var set_names_arr: Array[String] = []
		for s_id in d.sets:
			set_names_arr.append("«%s»" % RelicSystem.get_set_name(s_id))
		sets_lbl.text = "✨ Комплекты: %s" % ", ".join(set_names_arr)
		sets_lbl.add_theme_font_size_override("font_size", 14)
		sets_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
		vbox.add_child(sets_lbl)

		# Враги (со стандартными названиями)
		var enemies_lbl := Label.new()
		enemies_lbl.text = "👹 Враги: %s" % d_info.get("enemies", "Стражи")
		enemies_lbl.add_theme_font_size_override("font_size", 13)
		enemies_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.65))
		vbox.add_child(enemies_lbl)

		# Аномалия
		var anom_lbl := Label.new()
		anom_lbl.text = "⚡ %s" % d_info.get("anomaly", "")
		anom_lbl.add_theme_font_size_override("font_size", 12)
		anom_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.75))
		anom_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		anom_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(anom_lbl)

		# Кнопки действий
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 14)
		vbox.add_child(btn_row)

		var btn_fight := Button.new()
		btn_fight.text = "⚔ В бой"
		btn_fight.custom_minimum_size = Vector2(210, 42)
		btn_fight.add_theme_font_size_override("font_size", 15)
		var bf_sb := StyleBoxFlat.new()
		bf_sb.bg_color = Color(0.35, 0.20, 0.10, 0.95)
		bf_sb.border_color = Color(1.0, 0.65, 0.2)
		bf_sb.set_border_width_all(1)
		bf_sb.set_corner_radius_all(6)
		btn_fight.add_theme_stylebox_override("normal", bf_sb)

		var btn_instant := Button.new()
		btn_instant.text = "⚡ Быстрая зачистка"
		btn_instant.custom_minimum_size = Vector2(210, 42)
		btn_instant.add_theme_font_size_override("font_size", 15)
		var bi_sb := StyleBoxFlat.new()
		bi_sb.bg_color = Color(0.15, 0.22, 0.38, 0.95)
		bi_sb.border_color = Color(0.4, 0.7, 1.0)
		bi_sb.set_border_width_all(1)
		bi_sb.set_corner_radius_all(6)
		btn_instant.add_theme_stylebox_override("normal", bi_sb)

		var is_unlocked: bool = RelicSystem.is_dungeon_unlocked(d.id, TeamConfig.current_level_progress)
		if not is_unlocked:
			var u_lvl: int = RelicSystem.get_dungeon_unlock_level(d.id)
			tag_lbl.text = "🔒 С %d уровня" % u_lvl
			tag_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45))
			s_box.bg_color = Color(0.06, 0.07, 0.10, 0.75)
			s_box.border_color = Color(0.25, 0.28, 0.35, 0.5)
			btn_fight.disabled = true
			btn_fight.text = "🔒 Заблокировано"
			btn_instant.disabled = true
			btn_instant.text = "🔒 Заблокировано"
		else:
			btn_fight.pressed.connect(func():
				if is_menu_tutorial and menu_tut_step == 201:
					TeamConfig.set_meta("tutorial_dungeon_academy", true)
				_open_dungeon_team_setup(d.id)
			)
			btn_instant.pressed.connect(func():
				var drops: Array[Dictionary] = []
				if is_menu_tutorial and menu_tut_step == 201 and (d.id == "dungeon_academy" or d.id == "academy"):
					drops = RelicSystem.generate_tutorial_drops()
					TeamConfig.add_relic_shards(30)
				else:
					drops = RelicSystem.generate_dungeon_drops(d.id, TeamConfig.current_level_progress)
				for r in drops:
					TeamConfig.add_relic(r)
				TeamConfig.save_game()
				_show_dungeon_rewards_popup(drops, "Добыча: " + d.name)
			)
			if is_menu_tutorial and (menu_tut_step == 201 or menu_tut_step == 2) and (d.id == "dungeon_academy" or d.id == "academy"):
				tut_academy_instant_btn = btn_instant

		btn_row.add_child(btn_fight)
		btn_row.add_child(btn_instant)

		relic_farming_cards_container.add_child(card)

# Открытие меню настройки отряда перед входом в подземелье с показом особенности/аномалии
func _open_dungeon_team_setup(dungeon_id: String) -> void:
	selected_dungeon_for_battle = dungeon_id
	selected_level_for_battle = 0
	var d_info := RelicSystem.get_dungeon_info(dungeon_id)

	level_setup_title.text = "⚔ Подготовка к подземелью: %s %s" % [d_info.icon, d_info.name]

	# Заполняем КРУПНЫЕ плитки персонажей карусели ростера
	for child in level_team_roster_container.get_children():
		level_team_roster_container.remove_child(child)
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var card := _create_level_roster_card(char_id, _add_char_to_level_slot.bind(char_id))
		if card != null:
			level_team_roster_container.add_child(card)

	# Если _level_team пустой, подтягиваем текущих бойцов
	var has_slot := false
	for s in _level_team:
		if s != null:
			has_slot = true
			break
	if not has_slot:
		if not TeamConfig.team_members.is_empty():
			for i in range(mini(4, TeamConfig.team_members.size())):
				_level_team[i] = TeamConfig.team_members[i].duplicate(true)
		else:
			for i in range(mini(4, TeamConfig.unlocked_characters.size())):
				var c_id := TeamConfig.unlocked_characters[i]
				_level_team[i] = TeamConfig.get_saved_build(c_id)

	level_task_label.text = "🏛 Подземелье: %s %s\n✨ Аномалия данжа: %s" % [d_info.icon, d_info.name, d_info.anomaly]
	level_enemies_label.text = "👹 [b]Враги:[/b] %s" % d_info.enemies
	level_rewards_label.text = "🎁 [b]Награды:[/b] Комплекты: %s" % d_info.rewards

	_refresh_level_team_slots()
	_show_screen("level_team_setup")

func _start_dungeon_battle(dungeon_id: String) -> void:
	if TeamConfig.team_members.is_empty():
		var team: Array[Dictionary] = []
		for i in range(mini(4, TeamConfig.unlocked_characters.size())):
			var c_id: String = TeamConfig.unlocked_characters[i]
			var b := TeamConfig.get_saved_build(c_id)
			b["slot_idx"] = i
			team.append(b)
		TeamConfig.team_members = team

	if TeamConfig.team_members.is_empty():
		notification_label.text = "❌ Нет доступных персонажей для отряда!"
		return

	TeamConfig.battle_mode = dungeon_id
	if TeamConfig.battle_initiator_id.is_empty():
		TeamConfig.battle_initiator_id = TeamConfig.team_members[0].id

	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _show_dungeon_rewards_popup(drops: Array, title_text: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.08, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 600)
	var p_box := StyleBoxFlat.new()
	p_box.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	p_box.set_border_width_all(2)
	p_box.border_color = Color(0.4, 0.6, 0.9)
	p_box.set_corner_radius_all(12)
	p_box.content_margin_left = 24
	p_box.content_margin_right = 24
	p_box.content_margin_top = 20
	p_box.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", p_box)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎉 %s" % title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var sub_lbl := Label.new()
	sub_lbl.text = "Получено новых реликвий: %d шт. (Добавлены в Инвентарь)" % drops.size()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 15)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(sub_lbl)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)

	for r in drops:
		var r_card := _create_relic_card_widget(r, false)
		grid.add_child(r_card)

	var btn_close := Button.new()
	btn_close.text = "✓ Забрать всё в инвентарь"
	btn_close.custom_minimum_size = Vector2(280, 48)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.pressed.connect(func():
		overlay.queue_free()
		_refresh_inventory_relics()
		notification_label.text = "✓ Получено %d реликвий!" % drops.size()
		if is_menu_tutorial and menu_tut_step == 201:
			_run_menu_tut_step(202)
	)
	vbox.add_child(btn_close)

# Вспомогательный виджет карточки реликвии для инвентаря и наград
func _create_relic_card_widget(r: Dictionary, show_upgrade_btn: bool = true, select_cb: Callable = Callable()) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 210)

	var rarity: int = int(r.get("rarity", 4))
	var col := RelicSystem.get_rarity_color(rarity)

	var p_box := StyleBoxFlat.new()
	p_box.bg_color = Color(0.11, 0.13, 0.17, 0.95)
	p_box.set_border_width_all(2)
	p_box.border_color = col
	p_box.set_corner_radius_all(8)
	p_box.content_margin_left = 10
	p_box.content_margin_right = 10
	p_box.content_margin_top = 10
	p_box.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", p_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Заголовок: Слот, Звезды, Уровень
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	var slot_lbl := Label.new()
	var s_icon := RelicSystem.get_slot_icon(String(r.get("slot", "")))
	slot_lbl.text = "%s %s" % [s_icon, RelicSystem.get_slot_name(r.get("slot", ""))]
	slot_lbl.add_theme_font_size_override("font_size", 13)
	slot_lbl.add_theme_color_override("font_color", col)
	top_row.add_child(slot_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var lvl_lbl := Label.new()
	lvl_lbl.text = "%d★ +%d" % [rarity, int(r.get("level", 0))]
	lvl_lbl.add_theme_font_size_override("font_size", 13)
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_row.add_child(lvl_lbl)

	var set_lbl := Label.new()
	set_lbl.text = "«%s»" % RelicSystem.get_set_name(r.get("set_id", ""))
	set_lbl.add_theme_font_size_override("font_size", 12)
	set_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	set_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(set_lbl)

	# Основной стат
	var m_stat: Dictionary = r.get("main_stat", {})
	var m_type: String = String(m_stat.get("type", ""))
	var m_val: float = float(m_stat.get("value", 0.0))

	var main_lbl := Label.new()
	main_lbl.text = "%s: %s" % [RelicSystem.format_stat_name(m_type), RelicSystem.format_stat_value(m_type, m_val)]
	main_lbl.add_theme_font_size_override("font_size", 13)
	main_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vbox.add_child(main_lbl)

	# Сабстаты
	var subs: Array = r.get("substats", [])
	for s in subs:
		if s is Dictionary:
			var s_type: String = String(s.get("type", ""))
			var s_val: float = float(s.get("value", 0.0))
			var sub_lbl := Label.new()
			sub_lbl.text = "• %s %s" % [RelicSystem.format_stat_name(s_type), RelicSystem.format_stat_value(s_type, s_val)]
			sub_lbl.add_theme_font_size_override("font_size", 11)
			sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			vbox.add_child(sub_lbl)

	var eq_to: String = String(r.get("equipped_to", ""))
	if not eq_to.is_empty():
		var char_data := CharacterRegistry.get_character(eq_to)
		var c_name: String = String(char_data.get("name", eq_to)) if not char_data.is_empty() else eq_to
		var eq_lbl := Label.new()
		eq_lbl.text = "👤 %s" % c_name
		eq_lbl.add_theme_font_size_override("font_size", 11)
		eq_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox.add_child(eq_lbl)

	if show_upgrade_btn:
		var btn_up := Button.new()
		btn_up.text = "⚡ Улучшить"
		btn_up.custom_minimum_size = Vector2(0, 30)
		btn_up.add_theme_font_size_override("font_size", 12)
		btn_up.pressed.connect(_show_relic_upgrade_modal.bind(r))
		vbox.add_child(btn_up)

		if eq_to.is_empty():
			var btn_dismantle := Button.new()
			var d_shards := RelicSystem.calculate_dismantle_shards(r)
			btn_dismantle.text = "🗑 Разобрать (+%d 🔮)" % d_shards
			btn_dismantle.custom_minimum_size = Vector2(0, 30)
			btn_dismantle.add_theme_font_size_override("font_size", 12)
			var d_sb := StyleBoxFlat.new()
			d_sb.bg_color = Color(0.28, 0.12, 0.12, 0.9)
			d_sb.border_color = Color(0.8, 0.35, 0.35)
			d_sb.set_border_width_all(1)
			d_sb.set_corner_radius_all(6)
			btn_dismantle.add_theme_stylebox_override("normal", d_sb)
			btn_dismantle.pressed.connect(_confirm_dismantle_relic.bind(r))
			vbox.add_child(btn_dismantle)
			if tut_dismantle_btn == null or not is_instance_valid(tut_dismantle_btn):
				tut_dismantle_btn = btn_dismantle

	if select_cb.is_valid():
		var btn_sel := Button.new()
		btn_sel.text = "✓ Выбрать"
		btn_sel.custom_minimum_size = Vector2(0, 30)
		btn_sel.add_theme_font_size_override("font_size", 12)
		btn_sel.pressed.connect(func(): select_cb.call(r))
		vbox.add_child(btn_sel)

	return card

func _confirm_dismantle_relic(r: Dictionary) -> void:
	var d_shards := RelicSystem.calculate_dismantle_shards(r)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.16, 0.98)
	sb.border_color = Color(0.9, 0.4, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🗑 Уничтожение реликвии на осколки"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "Вы уверены, что хотите разобрать реликвию:\n«%s» (%s, %d★ +%d)?\n\nВы получите: +%d 🔮 Осколков реликвий." % [
		RelicSystem.get_set_name(r.get("set_id", "")),
		RelicSystem.get_slot_name(r.get("slot", "")),
		int(r.get("rarity", 4)),
		int(r.get("level", 0)),
		d_shards
	]
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 14)
	vbox.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_confirm := Button.new()
	btn_confirm.text = "🗑 Разобрать (+%d 🔮)" % d_shards
	btn_confirm.custom_minimum_size = Vector2(180, 42)
	btn_confirm.add_theme_font_size_override("font_size", 14)
	var c_sb := StyleBoxFlat.new()
	c_sb.bg_color = Color(0.45, 0.15, 0.15, 0.95)
	c_sb.border_color = Color(0.95, 0.4, 0.4)
	c_sb.set_border_width_all(1)
	c_sb.set_corner_radius_all(6)
	btn_confirm.add_theme_stylebox_override("normal", c_sb)
	btn_confirm.pressed.connect(func():
		overlay.queue_free()
		var gained := RelicSystem.dismantle_relic(r.get("uid", ""))
		notification_label.text = "✓ Реликвия разобрана! Получено +%d 🔮 осколков." % gained
		_refresh_inventory_relics()
		_update_coins_display()
		if is_menu_tutorial and (menu_tut_step == 10 or menu_tut_step == 13):
			_run_menu_tut_step(14)
	)
	btn_row.add_child(btn_confirm)

	if is_menu_tutorial and menu_tut_step == 13:
		_show_menu_pointer_for_control(btn_confirm, "down")

	var btn_cancel := Button.new()
	btn_cancel.text = "Отмена"
	btn_cancel.custom_minimum_size = Vector2(120, 42)
	btn_cancel.add_theme_font_size_override("font_size", 14)
	btn_cancel.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(btn_cancel)

func _refresh_inventory_relics() -> void:
	if not inv_relics_grid:
		return
	for child in inv_relics_grid.get_children():
		inv_relics_grid.remove_child(child)
		child.queue_free()

	var filter_slot: String = ""
	if opt_inv_relic_slot_filter and opt_inv_relic_slot_filter.selected >= 0:
		filter_slot = String(opt_inv_relic_slot_filter.get_item_metadata(opt_inv_relic_slot_filter.selected))

	var filter_rarity: int = 0
	if opt_inv_relic_rarity_filter and opt_inv_relic_rarity_filter.selected >= 0:
		filter_rarity = int(opt_inv_relic_rarity_filter.get_item_metadata(opt_inv_relic_rarity_filter.selected))

	var count := 0
	for r in TeamConfig.relic_inventory:
		if not filter_slot.is_empty() and r.get("slot", "") != filter_slot:
			continue
		if filter_rarity > 0 and int(r.get("rarity", 0)) != filter_rarity:
			continue
		var card := _create_relic_card_widget(r, true)
		inv_relics_grid.add_child(card)
		count += 1

	if count == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "Реликвии не найдены.\nДобудьте их в меню «Добыча реликвий»!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		inv_relics_grid.add_child(empty_lbl)

# === НОВОЕ ОКНО ПРОКАЧКИ И УЛУЧШЕНИЯ РЕЛИКВИЙ (БЕЗ ОШИБОК CALLABLE) ===
# === НОВОЕ ОКНО ПРОКАЧКИ И УЛУЧШЕНИЯ РЕЛИКВИЙ (УВЕЛИЧЕННОЕ + ОСКОЛКИ) ===
func _show_relic_upgrade_modal(target_relic: Dictionary) -> void:
	_upgrade_target_relic = target_relic
	_upgrade_selected_fodder_uids.clear()
	_upgrade_selected_shards_count = 0

	if _upgrade_overlay and is_instance_valid(_upgrade_overlay):
		_upgrade_overlay.queue_free()

	_upgrade_overlay = ColorRect.new()
	_upgrade_overlay.color = Color(0.02, 0.03, 0.06, 0.95)
	_upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_upgrade_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.add_child(center)

	# Увеличенный размер модального окна (1180x750)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1180, 750)
	var p_box := StyleBoxFlat.new()
	p_box.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	p_box.set_border_width_all(2)
	p_box.border_color = Color(0.45, 0.65, 0.95)
	p_box.set_corner_radius_all(16)
	p_box.content_margin_left = 26
	p_box.content_margin_right = 26
	p_box.content_margin_top = 22
	p_box.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", p_box)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Заголовок окна
	var title_lbl := Label.new()
	title_lbl.text = "⚙ Прокачка и Улучшение Реликвии"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title_lbl)

	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 24)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_hbox)

	# --- ЛЕВАЯ КОЛОНКА: Текущая реликвия и прогноз прокачки ---
	var left_box := VBoxContainer.new()
	left_box.custom_minimum_size = Vector2(400, 0)
	left_box.add_theme_constant_override("separation", 14)
	content_hbox.add_child(left_box)

	var t_header := Label.new()
	t_header.text = "Улучшаемая реликвия:"
	t_header.add_theme_font_size_override("font_size", 18)
	t_header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	left_box.add_child(t_header)

	_upgrade_target_card_container = VBoxContainer.new()
	left_box.add_child(_upgrade_target_card_container)

	# Панель прогресса и прогноза опыта
	var exp_panel := PanelContainer.new()
	var exp_pbox := StyleBoxFlat.new()
	exp_pbox.bg_color = Color(0.06, 0.08, 0.13, 0.95)
	exp_pbox.set_corner_radius_all(10)
	exp_pbox.content_margin_left = 16
	exp_pbox.content_margin_right = 16
	exp_pbox.content_margin_top = 14
	exp_pbox.content_margin_bottom = 14
	exp_panel.add_theme_stylebox_override("panel", exp_pbox)
	left_box.add_child(exp_panel)

	var exp_vbox := VBoxContainer.new()
	exp_vbox.add_theme_constant_override("separation", 8)
	exp_panel.add_child(exp_vbox)

	_upgrade_exp_info_lbl = Label.new()
	_upgrade_exp_info_lbl.add_theme_font_size_override("font_size", 15)
	_upgrade_exp_info_lbl.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
	exp_vbox.add_child(_upgrade_exp_info_lbl)

	_upgrade_progress_bar = ProgressBar.new()
	_upgrade_progress_bar.custom_minimum_size = Vector2(0, 26)
	_upgrade_progress_bar.show_percentage = false
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.12, 0.15, 0.22)
	pb_bg.set_corner_radius_all(8)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.3, 0.75, 1.0)
	pb_fill.set_corner_radius_all(8)
	_upgrade_progress_bar.add_theme_stylebox_override("background", pb_bg)
	_upgrade_progress_bar.add_theme_stylebox_override("fill", pb_fill)
	exp_vbox.add_child(_upgrade_progress_bar)

	_upgrade_preview_lbl = Label.new()
	_upgrade_preview_lbl.add_theme_font_size_override("font_size", 14)
	_upgrade_preview_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	_upgrade_preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_vbox.add_child(_upgrade_preview_lbl)

	var rule_hint := Label.new()
	rule_hint.text = "💡 Сабстаты открываются и усиливаются на ур. 3, 6, 9, 12, 15.\n🔮 Излишек опыта сверх капа уровня возвращается в виде осколков!"
	rule_hint.add_theme_font_size_override("font_size", 12)
	rule_hint.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80))
	rule_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(rule_hint)

	# --- ПРАВАЯ КОЛОНКА: Осколки (сверху) + Выбор корма ---
	var right_box := VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 14)
	content_hbox.add_child(right_box)

	# 1. КОМПАКТНАЯ СТРОКА ОСКОЛКОВ РЕЛИКВИЙ (ЛЕГКИЙ ИНТЕРФЕЙС)
	var shards_panel := PanelContainer.new()
	var sp_style := StyleBoxFlat.new()
	sp_style.bg_color = Color(0.10, 0.08, 0.16, 0.95)
	sp_style.set_border_width_all(1)
	sp_style.border_color = Color(0.65, 0.45, 0.90, 0.75)
	sp_style.set_corner_radius_all(8)
	sp_style.content_margin_left = 12
	sp_style.content_margin_right = 12
	sp_style.content_margin_top = 8
	sp_style.content_margin_bottom = 8
	shards_panel.add_theme_stylebox_override("panel", sp_style)
	right_box.add_child(shards_panel)

	var shards_row := HBoxContainer.new()
	shards_row.add_theme_constant_override("separation", 6)
	shards_panel.add_child(shards_row)

	_upgrade_shards_info_lbl = Label.new()
	_upgrade_shards_info_lbl.text = "🔮 Осколки: %d шт." % TeamConfig.relic_shards
	_upgrade_shards_info_lbl.add_theme_font_size_override("font_size", 13)
	_upgrade_shards_info_lbl.add_theme_color_override("font_color", Color(0.92, 0.82, 1.0))
	shards_row.add_child(_upgrade_shards_info_lbl)

	var sh_spacer := Control.new()
	sh_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shards_row.add_child(sh_spacer)

	var btn_sub_5 := Button.new()
	btn_sub_5.text = "-5"
	btn_sub_5.custom_minimum_size = Vector2(36, 32)
	btn_sub_5.add_theme_font_size_override("font_size", 12)
	btn_sub_5.pressed.connect(_add_shards_selection.bind(-5))
	shards_row.add_child(btn_sub_5)

	var btn_sub_1 := Button.new()
	btn_sub_1.text = "-1"
	btn_sub_1.custom_minimum_size = Vector2(36, 32)
	btn_sub_1.add_theme_font_size_override("font_size", 12)
	btn_sub_1.pressed.connect(_add_shards_selection.bind(-1))
	shards_row.add_child(btn_sub_1)

	_upgrade_shards_btn = Button.new()
	_upgrade_shards_btn.text = "Выбрано: 0 шт."
	_upgrade_shards_btn.custom_minimum_size = Vector2(160, 32)
	_upgrade_shards_btn.add_theme_font_size_override("font_size", 12)
	_upgrade_shards_btn.pressed.connect(_add_shards_selection.bind(1))
	shards_row.add_child(_upgrade_shards_btn)

	var btn_add_1 := Button.new()
	btn_add_1.text = "+1"
	btn_add_1.custom_minimum_size = Vector2(36, 32)
	btn_add_1.add_theme_font_size_override("font_size", 12)
	btn_add_1.pressed.connect(_add_shards_selection.bind(1))
	shards_row.add_child(btn_add_1)

	var btn_add_5 := Button.new()
	btn_add_5.text = "+5"
	btn_add_5.custom_minimum_size = Vector2(36, 32)
	btn_add_5.add_theme_font_size_override("font_size", 12)
	btn_add_5.pressed.connect(_add_shards_selection.bind(5))
	shards_row.add_child(btn_add_5)

	var btn_auto_shards := Button.new()
	btn_auto_shards.text = "✨ Авто"
	btn_auto_shards.custom_minimum_size = Vector2(65, 32)
	btn_auto_shards.add_theme_font_size_override("font_size", 12)
	var auto_sb := StyleBoxFlat.new()
	auto_sb.bg_color = Color(0.25, 0.16, 0.38, 0.95)
	auto_sb.border_color = Color(0.75, 0.55, 1.0)
	auto_sb.set_border_width_all(1)
	auto_sb.set_corner_radius_all(6)
	btn_auto_shards.add_theme_stylebox_override("normal", auto_sb)
	btn_auto_shards.pressed.connect(_select_shards_for_upgrade)
	_upgrade_btn_auto_shards = btn_auto_shards
	shards_row.add_child(btn_auto_shards)

	var btn_reset_shards := Button.new()
	btn_reset_shards.text = "✕"
	btn_reset_shards.custom_minimum_size = Vector2(32, 32)
	btn_reset_shards.add_theme_font_size_override("font_size", 12)
	btn_reset_shards.pressed.connect(_add_shards_selection.bind(-999999))
	shards_row.add_child(btn_reset_shards)

	# 2. ПАНЕЛЬ ВЫБОРА РЕЛИКВИЙ НА КОРМ
	var action_hbar := HBoxContainer.new()
	action_hbar.add_theme_constant_override("separation", 12)
	right_box.add_child(action_hbar)

	_upgrade_fodder_counter_lbl = Label.new()
	_upgrade_fodder_counter_lbl.text = "🎒 Реликвии на корм: Выбрано 0 / 8"
	_upgrade_fodder_counter_lbl.add_theme_font_size_override("font_size", 15)
	_upgrade_fodder_counter_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_upgrade_fodder_counter_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hbar.add_child(_upgrade_fodder_counter_lbl)

	var btn_all_3star := Button.new()
	btn_all_3star.text = "⚡ Выбрать 3★"
	btn_all_3star.custom_minimum_size = Vector2(130, 34)
	btn_all_3star.add_theme_font_size_override("font_size", 13)
	btn_all_3star.pressed.connect(_select_all_fodder_rarity.bind(3))
	action_hbar.add_child(btn_all_3star)

	var btn_clear := Button.new()
	btn_clear.text = "✕ Сбросить всё"
	btn_clear.custom_minimum_size = Vector2(130, 34)
	btn_clear.add_theme_font_size_override("font_size", 13)
	btn_clear.pressed.connect(_clear_fodder_selection)
	action_hbar.add_child(btn_clear)

	var fodder_scroll := ScrollContainer.new()
	fodder_scroll.custom_minimum_size = Vector2(0, 370)
	fodder_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(fodder_scroll)

	_upgrade_fodder_grid = GridContainer.new()
	_upgrade_fodder_grid.columns = 3
	_upgrade_fodder_grid.add_theme_constant_override("h_separation", 10)
	_upgrade_fodder_grid.add_theme_constant_override("v_separation", 10)
	fodder_scroll.add_child(_upgrade_fodder_grid)

	# --- НИЖНЯЯ ПАНЕЛЬ С КНОПКАМИ ---
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_hbox)

	_upgrade_btn_apply = Button.new()
	_upgrade_btn_apply.text = "⚡ Прокачать выбранным кормом"
	_upgrade_btn_apply.custom_minimum_size = Vector2(360, 52)
	_upgrade_btn_apply.add_theme_font_size_override("font_size", 17)
	_upgrade_btn_apply.pressed.connect(_apply_relic_upgrade_action)
	btn_hbox.add_child(_upgrade_btn_apply)

	var btn_close := Button.new()
	btn_close.text = "✕ Закрыть"
	btn_close.custom_minimum_size = Vector2(160, 52)
	btn_close.add_theme_font_size_override("font_size", 17)
	btn_close.pressed.connect(_close_relic_upgrade_modal)
	btn_hbox.add_child(btn_close)

	_refresh_upgrade_dialog_ui()

	if is_menu_tutorial and menu_tut_step == 6:
		_run_menu_tut_step(7)

# Изменение количества выбранных осколков
func _add_shards_selection(delta: int) -> void:
	var total_avail: int = TeamConfig.relic_shards
	var new_val: int = clampi(_upgrade_selected_shards_count + delta, 0, total_avail)
	if new_val == _upgrade_selected_shards_count:
		if delta > 0 and _upgrade_selected_shards_count >= total_avail:
			notification_label.text = "⚠ Больше нет доступных осколков в инвентаре (%d шт.)" % total_avail
		return
	_upgrade_selected_shards_count = new_val
	_refresh_upgrade_dialog_ui()

# Автоматический выбор осколков реликвий до следующего порога / капа
func _select_shards_for_upgrade() -> void:
	var total_avail: int = TeamConfig.relic_shards
	if total_avail <= 0:
		notification_label.text = "⚠ У вас нет осколков реликвий! Добудьте их в гаче или данжах."
		return
	var rarity: int = int(_upgrade_target_relic.get("rarity", 4))
	var max_lvl: int = RelicSystem.MAX_LEVELS.get(rarity, 15)
	var cur_lvl: int = int(_upgrade_target_relic.get("level", 0))
	var cur_exp: int = int(_upgrade_target_relic.get("exp", 0))

	if cur_lvl >= max_lvl:
		notification_label.text = "ℹ Реликвия уже достигла максимального уровня (+%d)!" % max_lvl
		return

	# Опыт от уже выбранных реликвий
	var fodder_exp := 0
	for f_uid in _upgrade_selected_fodder_uids:
		var f_r := TeamConfig.get_relic(f_uid)
		if not f_r.is_empty():
			fodder_exp += RelicSystem.get_relic_feed_exp(f_r)

	# Определяем следующий целевой рубеж (3, 6, 9, 12, 15) или max_lvl
	var target_milestone := max_lvl
	for ms in [3, 6, 9, 12, 15]:
		if ms <= max_lvl and ms > cur_lvl:
			var exp_to_ms := 0
			for l in range(cur_lvl + 1, ms + 1):
				exp_to_ms += RelicSystem.EXP_PER_LEVEL[l]
			var needed := exp_to_ms - cur_exp - fodder_exp
			var shards_for_ms := ceili(float(maxi(0, needed)) / float(RelicSystem.SHARD_EXP_VALUE))
			if shards_for_ms > _upgrade_selected_shards_count:
				target_milestone = ms
				break

	var needed_exp := 0
	for l in range(cur_lvl + 1, target_milestone + 1):
		needed_exp += RelicSystem.EXP_PER_LEVEL[l]
	needed_exp = maxi(0, needed_exp - cur_exp - fodder_exp)

	var needed_shards := ceili(float(needed_exp) / float(RelicSystem.SHARD_EXP_VALUE))
	var chosen_shards: int = clampi(needed_shards, 0, total_avail)

	if chosen_shards == 0 and needed_exp == 0:
		var full_exp := 0
		for l in range(cur_lvl + 1, max_lvl + 1):
			full_exp += RelicSystem.EXP_PER_LEVEL[l]
		full_exp = maxi(0, full_exp - cur_exp - fodder_exp)
		chosen_shards = clampi(ceili(float(full_exp) / float(RelicSystem.SHARD_EXP_VALUE)), 0, total_avail)

	_upgrade_selected_shards_count = chosen_shards
	notification_label.text = "🔮 Выбрано %d осколков (+%d XP) для прокачки" % [
		_upgrade_selected_shards_count,
		_upgrade_selected_shards_count * RelicSystem.SHARD_EXP_VALUE
	]
	_refresh_upgrade_dialog_ui()
	if is_menu_tutorial and menu_tut_step == 7:
		if _upgrade_btn_apply and is_instance_valid(_upgrade_btn_apply):
			if menu_guide_overlay and is_instance_valid(menu_guide_overlay):
				menu_guide_overlay.set_dialog(
					"⚡ Прокачка реликвии",
					"Отлично! Осколки выбраны. Теперь нажми [b]«⚡ Прокачать»[/b]!",
					"ШАГ 10 / 20"
				)
			_show_menu_pointer_for_control(_upgrade_btn_apply, "up")

# Обновление состояния окна прокачки реликвии
func _refresh_upgrade_dialog_ui() -> void:
	if not _upgrade_overlay or not is_instance_valid(_upgrade_overlay):
		return

	# 1. Карточка улучшаемой реликвии
	for c in _upgrade_target_card_container.get_children():
		c.queue_free()
	_upgrade_target_card_container.add_child(_create_relic_card_widget(_upgrade_target_relic, false))

	var rarity: int = int(_upgrade_target_relic.get("rarity", 4))
	var max_lvl: int = RelicSystem.MAX_LEVELS.get(rarity, 15)
	var cur_lvl: int = int(_upgrade_target_relic.get("level", 0))
	var cur_exp: int = int(_upgrade_target_relic.get("exp", 0))

	# Расчет прибавки от выбранных реликвий + осколков
	var fodder_exp := 0
	for f_uid in _upgrade_selected_fodder_uids:
		var f_r := TeamConfig.get_relic(f_uid)
		if not f_r.is_empty():
			fodder_exp += RelicSystem.get_relic_feed_exp(f_r)

	var shards_exp := _upgrade_selected_shards_count * RelicSystem.SHARD_EXP_VALUE
	var add_exp_val := fodder_exp + shards_exp

	# Обновляем виджет осколков
	if _upgrade_shards_info_lbl and is_instance_valid(_upgrade_shards_info_lbl):
		_upgrade_shards_info_lbl.text = "В наличии: %d шт." % TeamConfig.relic_shards
	if _upgrade_shards_btn and is_instance_valid(_upgrade_shards_btn):
		if _upgrade_selected_shards_count > 0:
			_upgrade_shards_btn.text = "🔮 Выбрано: %d шт. (+%d XP)" % [_upgrade_selected_shards_count, shards_exp]
		else:
			_upgrade_shards_btn.text = "🔮 Осколки не выбраны (нажмите +1 или Авто)"

	if cur_lvl >= max_lvl:
		_upgrade_exp_info_lbl.text = "Уровень: +%d (МАКСИМАЛЬНЫЙ)" % cur_lvl
		_upgrade_progress_bar.max_value = 100
		_upgrade_progress_bar.value = 100
		_upgrade_preview_lbl.text = "Реликвия достигла предельного уровня!"
		_upgrade_btn_apply.disabled = true
		_upgrade_btn_apply.text = "Максимальный уровень"
	else:
		var req_exp: int = RelicSystem.EXP_PER_LEVEL[cur_lvl + 1]
		_upgrade_exp_info_lbl.text = "Уровень: +%d / +%d  |  Опыт: %d / %d" % [cur_lvl, max_lvl, cur_exp, req_exp]
		_upgrade_progress_bar.max_value = req_exp
		_upgrade_progress_bar.value = minf(cur_exp + add_exp_val, req_exp)

		if add_exp_val > 0:
			var sim_exp := cur_exp + add_exp_val
			var sim_lvl := cur_lvl
			var sim_rolls := 0
			while sim_lvl < max_lvl:
				var need: int = RelicSystem.EXP_PER_LEVEL[sim_lvl + 1]
				if sim_exp >= need:
					sim_exp -= need
					sim_lvl += 1
					if sim_lvl in [3, 6, 9, 12, 15]:
						sim_rolls += 1
				else:
					break

			var excess_refund_preview := 0
			if sim_lvl >= max_lvl and sim_exp > 0:
				excess_refund_preview = ceili(float(sim_exp) / float(RelicSystem.SHARD_EXP_VALUE))

			var m_stat_dict: Dictionary = _upgrade_target_relic.get("main_stat", {})
			var m_stat_id := String(m_stat_dict.get("type", ""))
			var cur_m_val := float(m_stat_dict.get("value", 0.0))
			var sim_m_val := RelicSystem.calculate_main_stat_value(m_stat_id, rarity, sim_lvl)
			var roll_info := "\n✨ Новых / усиленных сабстатов: +%d" % sim_rolls if sim_rolls > 0 else ""
			var refund_info := "\n🔮 Излишек будет возвращен: +%d осколков" % excess_refund_preview if excess_refund_preview > 0 else ""

			var source_details := ""
			if fodder_exp > 0 and shards_exp > 0:
				source_details = " (Корм: +%d XP, Осколки: +%d XP)" % [fodder_exp, shards_exp]

			_upgrade_preview_lbl.text = "Прогноз: +%d XP%s\nУровень: +%d ➔ +%d\n%s: %s ➔ %s%s%s" % [
				add_exp_val,
				source_details,
				cur_lvl, sim_lvl,
				RelicSystem.format_stat_name(m_stat_id),
				RelicSystem.format_stat_value(m_stat_id, cur_m_val),
				RelicSystem.format_stat_value(m_stat_id, sim_m_val),
				roll_info,
				refund_info
			]
			_upgrade_btn_apply.disabled = false
			_upgrade_btn_apply.text = "⚡ Улучшить (+%d XP)" % add_exp_val
		else:
			_upgrade_preview_lbl.text = "Выберите реликвии или осколки сверху для прокачки."
			_upgrade_btn_apply.disabled = true
			_upgrade_btn_apply.text = "⚡ Выберите материалы"

	# 2. Счетчик реликвий на корм справа
	_upgrade_fodder_counter_lbl.text = "🎒 Реликвии на корм: Выбрано %d / 8" % _upgrade_selected_fodder_uids.size()

	# 3. Сетка корма
	for c in _upgrade_fodder_grid.get_children():
		c.queue_free()

	if cur_lvl >= max_lvl:
		return

	var available_count := 0
	for r in TeamConfig.relic_inventory:
		var r_uid: String = String(r.get("uid", ""))
		if r_uid == _upgrade_target_relic.get("uid", ""):
			continue
		if not String(r.get("equipped_to", "")).is_empty():
			continue # Надетые реликвии нельзя скармливать

		available_count += 1
		var f_btn := Button.new()
		f_btn.custom_minimum_size = Vector2(215, 78)
		var is_sel: bool = r_uid in _upgrade_selected_fodder_uids
		var exp_val: int = RelicSystem.get_relic_feed_exp(r)
		var r_rar: int = int(r.get("rarity", 3))
		var r_slot := RelicSystem.get_slot_name(String(r.get("slot", "")))
		var r_icon := RelicSystem.get_slot_icon(String(r.get("slot", "")))
		var r_set := RelicSystem.get_set_name(String(r.get("set_id", "")))

		var f_sb := StyleBoxFlat.new()
		f_sb.set_corner_radius_all(8)
		if is_sel:
			f_sb.bg_color = Color(0.12, 0.22, 0.16, 0.95)
			f_sb.border_color = Color(0.35, 1.0, 0.55)
			f_sb.set_border_width_all(2)
		else:
			f_sb.bg_color = Color(0.09, 0.11, 0.16, 0.95)
			f_sb.border_color = RelicSystem.get_rarity_color(r_rar) * 0.75
			f_sb.set_border_width_all(1)
		f_btn.add_theme_stylebox_override("normal", f_sb)

		var sel_mark := "✔ " if is_sel else "○ "
		f_btn.text = "%s%s %s +%d  (%d★)\n«%s»\n+%d XP" % [
			sel_mark, r_icon, r_slot,
			int(r.get("level", 0)),
			r_rar,
			r_set,
			exp_val
		]
		f_btn.add_theme_font_size_override("font_size", 12)
		if is_sel:
			f_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		else:
			f_btn.add_theme_color_override("font_color", RelicSystem.get_rarity_color(r_rar))

		f_btn.pressed.connect(_on_upgrade_fodder_button_pressed.bind(r_uid))
		_upgrade_fodder_grid.add_child(f_btn)

	if available_count == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "Нет свободных реликвий на корм.\nИспользуйте осколки выше или добудьте реликвии в данжах!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
		_upgrade_fodder_grid.add_child(empty_lbl)

# Переключение выбора реликвии на корм
func _on_upgrade_fodder_button_pressed(r_uid: String) -> void:
	if r_uid in _upgrade_selected_fodder_uids:
		_upgrade_selected_fodder_uids.erase(r_uid)
	else:
		if _upgrade_selected_fodder_uids.size() < 8:
			_upgrade_selected_fodder_uids.append(r_uid)
		else:
			notification_label.text = "⚠ Максимум 8 реликвий на корм за один раз!"
	_refresh_upgrade_dialog_ui()

# Быстрый выбор всех реликвий указанной редкости
func _select_all_fodder_rarity(rarity: int) -> void:
	for r in TeamConfig.relic_inventory:
		if _upgrade_selected_fodder_uids.size() >= 8:
			break
		var r_uid: String = String(r.get("uid", ""))
		if r_uid == _upgrade_target_relic.get("uid", ""):
			continue
		if not String(r.get("equipped_to", "")).is_empty():
			continue
		if int(r.get("rarity", 0)) == rarity and not (r_uid in _upgrade_selected_fodder_uids):
			_upgrade_selected_fodder_uids.append(r_uid)
	_refresh_upgrade_dialog_ui()

# Сброс выбора корма и осколков
func _clear_fodder_selection() -> void:
	_upgrade_selected_fodder_uids.clear()
	_upgrade_selected_shards_count = 0
	_refresh_upgrade_dialog_ui()

# Применение улучшения реликвии
func _apply_relic_upgrade_action() -> void:
	if _upgrade_selected_fodder_uids.is_empty() and _upgrade_selected_shards_count <= 0:
		return

	# Снимок состояния до прокачки
	var old_lvl: int = int(_upgrade_target_relic.get("level", 0))
	var old_main: Dictionary = (_upgrade_target_relic.get("main_stat", {}) as Dictionary).duplicate(true)
	var old_subs: Array = []
	for s in _upgrade_target_relic.get("substats", []):
		old_subs.append((s as Dictionary).duplicate(true))

	var total_feed := 0
	for f_uid in _upgrade_selected_fodder_uids:
		var f_r := TeamConfig.get_relic(f_uid)
		if not f_r.is_empty():
			total_feed += RelicSystem.get_relic_feed_exp(f_r)
		TeamConfig.remove_relic(f_uid)

	# Списание выбранных осколков
	if _upgrade_selected_shards_count > 0:
		total_feed += _upgrade_selected_shards_count * RelicSystem.SHARD_EXP_VALUE
		TeamConfig.consume_relic_shards(_upgrade_selected_shards_count)
		_upgrade_selected_shards_count = 0

	var res := RelicSystem.add_exp(_upgrade_target_relic, total_feed)
	var refunded_shards: int = int(res.get("shards_refunded", 0))
	if refunded_shards > 0:
		TeamConfig.add_relic_shards(refunded_shards)

	TeamConfig.save_game()
	_upgrade_selected_fodder_uids.clear()
	_refresh_upgrade_dialog_ui()
	_refresh_inventory_relics()
	if not selected_char_for_build.is_empty():
		_update_equipped_relics_ui(selected_char_for_build)

	# Снимок состояния после прокачки
	var new_lvl: int = int(_upgrade_target_relic.get("level", 0))
	var new_main: Dictionary = (_upgrade_target_relic.get("main_stat", {}) as Dictionary).duplicate(true)
	var new_subs: Array = _upgrade_target_relic.get("substats", [])

	notification_label.text = "✓ Реликвия прокачана до +%d ур. (Роллов: +%d)!" % [
		new_lvl,
		int(res.get("rolls_triggered", 0))
	]

	# Открываем модальное окно с детальным отображением улучшенных характеристик
	_show_relic_upgrade_success_modal(
		_upgrade_target_relic,
		old_lvl,
		new_lvl,
		old_main,
		new_main,
		old_subs,
		new_subs,
		refunded_shards
	)

# Окно детального отображения улучшений характеристик (мейн стат и сабстаты)
func _show_relic_upgrade_success_modal(
	relic: Dictionary,
	old_lvl: int,
	new_lvl: int,
	old_main: Dictionary,
	new_main: Dictionary,
	old_subs: Array,
	new_subs: Array,
	refunded_shards: int
) -> void:
	var modal_overlay := ColorRect.new()
	modal_overlay.color = Color(0.02, 0.03, 0.06, 0.92)
	modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 500)
	var p_box := StyleBoxFlat.new()
	p_box.bg_color = Color(0.09, 0.11, 0.17, 0.98)
	p_box.set_border_width_all(2)
	p_box.border_color = Color(1.0, 0.82, 0.25) # Золотая рамка успеха
	p_box.set_corner_radius_all(16)
	p_box.content_margin_left = 26
	p_box.content_margin_right = 26
	p_box.content_margin_top = 22
	p_box.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", p_box)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Заголовок
	var title_lbl := Label.new()
	title_lbl.text = "🎉 Улучшение реликвии успешно!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title_lbl)

	var lvl_lbl := Label.new()
	var rarity: int = int(relic.get("rarity", 4))
	var slot_name := RelicSystem.get_slot_name(String(relic.get("slot", "")))
	lvl_lbl.text = "%d★ %s  |  Уровень: +%d ➔ +%d" % [rarity, slot_name, old_lvl, new_lvl]
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 17)
	lvl_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vbox.add_child(lvl_lbl)

	# 1. Блок основного стата
	var main_panel := PanelContainer.new()
	var mp_box := StyleBoxFlat.new()
	mp_box.bg_color = Color(0.07, 0.12, 0.19, 0.9)
	mp_box.set_border_width_all(1)
	mp_box.border_color = Color(0.3, 0.6, 0.9)
	mp_box.set_corner_radius_all(8)
	mp_box.content_margin_left = 14
	mp_box.content_margin_right = 14
	mp_box.content_margin_top = 10
	mp_box.content_margin_bottom = 10
	main_panel.add_theme_stylebox_override("panel", mp_box)
	vbox.add_child(main_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	main_panel.add_child(main_vbox)

	var main_title := Label.new()
	main_title.text = "📌 Основной стат:"
	main_title.add_theme_font_size_override("font_size", 14)
	main_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	main_vbox.add_child(main_title)

	var m_type: String = String(new_main.get("type", ""))
	var old_val: float = float(old_main.get("value", 0.0))
	var new_val: float = float(new_main.get("value", 0.0))
	var gain_val: float = new_val - old_val

	var main_diff_lbl := Label.new()
	if gain_val > 0.0001:
		main_diff_lbl.text = "  %s: %s ➔ %s (+%s)" % [
			RelicSystem.format_stat_name(m_type),
			RelicSystem.format_stat_value(m_type, old_val),
			RelicSystem.format_stat_value(m_type, new_val),
			RelicSystem.format_stat_value(m_type, gain_val)
		]
		main_diff_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		main_diff_lbl.text = "  %s: %s (без изменений)" % [
			RelicSystem.format_stat_name(m_type),
			RelicSystem.format_stat_value(m_type, new_val)
		]
		main_diff_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	main_diff_lbl.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(main_diff_lbl)

	# 2. Блок сабстатов
	var subs_panel := PanelContainer.new()
	var sp_box := StyleBoxFlat.new()
	sp_box.bg_color = Color(0.10, 0.09, 0.16, 0.9)
	sp_box.set_border_width_all(1)
	sp_box.border_color = Color(0.6, 0.4, 0.85)
	sp_box.set_corner_radius_all(8)
	sp_box.content_margin_left = 14
	sp_box.content_margin_right = 14
	sp_box.content_margin_top = 10
	sp_box.content_margin_bottom = 10
	subs_panel.add_theme_stylebox_override("panel", sp_box)
	vbox.add_child(subs_panel)

	var subs_vbox := VBoxContainer.new()
	subs_vbox.add_theme_constant_override("separation", 6)
	subs_panel.add_child(subs_vbox)

	var subs_title := Label.new()
	subs_title.text = "✨ Сабстаты (дополнительные характеристики):"
	subs_title.add_theme_font_size_override("font_size", 14)
	subs_title.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	subs_vbox.add_child(subs_title)

	if new_subs.is_empty():
		var empty_subs := Label.new()
		empty_subs.text = "  (Сабстатов пока нет. Они откроются на ур. +3, +6, +9...)"
		empty_subs.add_theme_font_size_override("font_size", 13)
		empty_subs.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		subs_vbox.add_child(empty_subs)
	else:
		# Сопоставляем сабстаты с предыдущими
		for s in new_subs:
			if not (s is Dictionary):
				continue
			var s_type: String = String(s.get("type", ""))
			var s_val: float = float(s.get("value", 0.0))
			var s_rolls: int = int(s.get("rolls", 1))

			# Ищем в старых сабстатах
			var matched_old: Dictionary = {}
			for os in old_subs:
				if os is Dictionary and String(os.get("type", "")) == s_type:
					matched_old = os
					break

			var s_lbl := Label.new()
			s_lbl.add_theme_font_size_override("font_size", 14)

			if matched_old.is_empty():
				# Новый открытый сабстат
				s_lbl.text = "  ✨ [НОВЫЙ!] %s: %s (роллов: %d)" % [
					RelicSystem.format_stat_name(s_type),
					RelicSystem.format_stat_value(s_type, s_val),
					s_rolls
				]
				s_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.7))
			else:
				var os_val: float = float(matched_old.get("value", 0.0))
				var os_rolls: int = int(matched_old.get("rolls", 1))
				var diff_val: float = s_val - os_val

				if diff_val > 0.0001 or s_rolls > os_rolls:
					# Усиленный сабстат
					s_lbl.text = "  ⬆ [УСИЛЕН!] %s: %s ➔ %s (+%s | роллов: %d ➔ %d)" % [
						RelicSystem.format_stat_name(s_type),
						RelicSystem.format_stat_value(s_type, os_val),
						RelicSystem.format_stat_value(s_type, s_val),
						RelicSystem.format_stat_value(s_type, diff_val),
						os_rolls,
						s_rolls
					]
					s_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
				else:
					# Не изменился в этот раз
					s_lbl.text = "  • %s: %s (роллов: %d)" % [
						RelicSystem.format_stat_name(s_type),
						RelicSystem.format_stat_value(s_type, s_val),
						s_rolls
					]
					s_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))

			subs_vbox.add_child(s_lbl)

	# 3. Блок возврата излишков опыта (если есть)
	if refunded_shards > 0:
		var refund_panel := PanelContainer.new()
		var rp_box := StyleBoxFlat.new()
		rp_box.bg_color = Color(0.18, 0.08, 0.24, 0.95)
		rp_box.set_border_width_all(1)
		rp_box.border_color = Color(0.95, 0.45, 0.95)
		rp_box.set_corner_radius_all(8)
		rp_box.content_margin_left = 14
		rp_box.content_margin_right = 14
		rp_box.content_margin_top = 8
		rp_box.content_margin_bottom = 8
		refund_panel.add_theme_stylebox_override("panel", rp_box)
		vbox.add_child(refund_panel)

		var ref_lbl := Label.new()
		ref_lbl.text = "🔮 Излишек опыта сверх максимума возвращен: +%d Осколков реликвий!\n(Осколки зачислены в ваш инвентарь: теперь %d шт.)" % [
			refunded_shards,
			TeamConfig.relic_shards
		]
		ref_lbl.add_theme_font_size_override("font_size", 14)
		ref_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 1.0))
		ref_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		refund_panel.add_child(ref_lbl)

	# Кнопка закрытия окна успеха
	var btn_ok := Button.new()
	btn_ok.text = "✓ Отлично!"
	btn_ok.custom_minimum_size = Vector2(220, 46)
	btn_ok.add_theme_font_size_override("font_size", 16)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ok.pressed.connect(func():
		modal_overlay.queue_free()
		_refresh_upgrade_dialog_ui()
		if is_menu_tutorial and menu_tut_step == 7:
			_close_relic_upgrade_modal()
			_run_menu_tut_step(8)
	)
	vbox.add_child(btn_ok)

# Закрытие модального окна улучшения
func _close_relic_upgrade_modal() -> void:
	if _upgrade_overlay and is_instance_valid(_upgrade_overlay):
		_upgrade_overlay.queue_free()
		_upgrade_overlay = null
	_upgrade_selected_fodder_uids.clear()
	_upgrade_selected_shards_count = 0
	_upgrade_target_relic = {}
	_refresh_inventory_relics()
	if not selected_char_for_build.is_empty():
		_update_equipped_relics_ui(selected_char_for_build)

# Обновление отображения слотов экипировки персонажа: 3/4 слева (2x2 пещеры + разделитель + 2 планарных) и 1/4 справа (описание сетов)
func _update_equipped_relics_ui(char_id: String) -> void:
	if not char_equipped_relics_container:
		return
	for child in char_equipped_relics_container.get_children():
		child.queue_free()

	tut_slot_btn_head = null
	tut_slot_btn_hands = null
	tut_slot_btn_upgrade_head = null

	var equipped := TeamConfig.get_equipped_relics(char_id)
	var lvl_progress := TeamConfig.current_level_progress

	# 1. Секция пещерных реликвий (2x2 квадрат)
	var cavern_header := Label.new()
	cavern_header.text = "🏛 Пещерные реликвии (2х2):"
	cavern_header.add_theme_font_size_override("font_size", 14)
	cavern_header.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	char_equipped_relics_container.add_child(cavern_header)

	var cavern_grid := GridContainer.new()
	cavern_grid.columns = 2
	cavern_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cavern_grid.add_theme_constant_override("h_separation", 10)
	cavern_grid.add_theme_constant_override("v_separation", 10)
	char_equipped_relics_container.add_child(cavern_grid)

	for slot_name in ["head", "hands", "body", "feet"]:
		var tile := _create_equipped_slot_tile(char_id, slot_name, equipped, lvl_progress)
		cavern_grid.add_child(tile)

	# 2. Разделитель между пещерными и планарными
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 8)
	char_equipped_relics_container.add_child(sep)

	# 3. Секция планарных украшений (2 квадратика рядом)
	var planar_header := Label.new()
	planar_header.text = "🌌 Планарные украшения (2 в ряд):"
	planar_header.add_theme_font_size_override("font_size", 14)
	planar_header.add_theme_color_override("font_color", Color(0.88, 0.75, 1.0))
	char_equipped_relics_container.add_child(planar_header)

	var planar_grid := GridContainer.new()
	planar_grid.columns = 2
	planar_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	planar_grid.add_theme_constant_override("h_separation", 10)
	planar_grid.add_theme_constant_override("v_separation", 10)
	char_equipped_relics_container.add_child(planar_grid)

	for slot_name in ["sphere", "rope"]:
		var tile := _create_equipped_slot_tile(char_id, slot_name, equipped, lvl_progress)
		planar_grid.add_child(tile)

	# 4. Подсчет и вывод активных сетовых бонусов в правой панели (1/4)
	if char_active_sets_label:
		var cavern_counts: Dictionary = {}
		for c_s in RelicSystem.CAVERN_SLOTS:
			if equipped.has(c_s):
				var s_id: String = String(equipped[c_s].get("set_id", ""))
				if not s_id.is_empty():
					cavern_counts[s_id] = cavern_counts.get(s_id, 0) + 1
		var active_sets: Array[String] = []
		for s_id in cavern_counts:
			var s_name := RelicSystem.get_set_name(s_id)
			if cavern_counts[s_id] >= 4:
				var desc_2 := RelicSystem.get_set_2pc_desc(s_id)
				var desc_4 := RelicSystem.get_set_4pc_desc(s_id)
				active_sets.append("✦ %s (4 части):\n   • 2 части: %s\n   • 4 части: %s" % [s_name, desc_2, desc_4])
			elif cavern_counts[s_id] >= 2:
				var desc_2 := RelicSystem.get_set_2pc_desc(s_id)
				active_sets.append("✦ %s (2 части):\n   • %s" % [s_name, desc_2])

		if equipped.has("sphere") and equipped.has("rope"):
			var sph_s := String(equipped["sphere"].get("set_id", ""))
			var rope_s := String(equipped["rope"].get("set_id", ""))
			if sph_s == rope_s and not sph_s.is_empty():
				var p_name := RelicSystem.get_set_name(sph_s)
				var p_desc := RelicSystem.get_set_2pc_desc(sph_s)
				active_sets.append("✦ %s (Планарный сет 2 части):\n   • %s" % [p_name, p_desc])

		if active_sets.is_empty():
			char_active_sets_label.text = "Активные бонусы комплектов: Нет\n\n💡 Экипируйте 2 или 4 реликвии одного комплекта для активации бонуса."
		else:
			char_active_sets_label.text = "Активные бонусы комплектов:\n\n" + "\n\n".join(active_sets)

func _create_equipped_slot_tile(char_id: String, slot_name: String, equipped: Dictionary, lvl_progress: int) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(230, 135)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8

	var is_unlocked := RelicSystem.is_slot_unlocked(slot_name, lvl_progress)
	var is_equipped := equipped.has(slot_name)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	tile.add_child(vbox)

	var s_name := "%s %s" % [RelicSystem.get_slot_icon(slot_name), RelicSystem.get_slot_name(slot_name)]

	if not is_unlocked:
		sb.bg_color = Color(0.06, 0.07, 0.10, 0.75)
		sb.border_color = Color(0.25, 0.28, 0.35, 0.6)
		sb.set_border_width_all(1)
		tile.add_theme_stylebox_override("panel", sb)

		var top_row := HBoxContainer.new()
		vbox.add_child(top_row)
		var s_lbl := Label.new()
		s_lbl.text = s_name
		s_lbl.add_theme_font_size_override("font_size", 13)
		s_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		top_row.add_child(s_lbl)

		var center_vbox := VBoxContainer.new()
		center_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(center_vbox)

		var lock_lbl := Label.new()
		var u_lvl := RelicSystem.get_slot_unlock_level(slot_name)
		lock_lbl.text = "🔒 Слот заблокирован\nОткроется на %d уровне" % u_lvl
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock_lbl.add_theme_color_override("font_color", Color(0.65, 0.45, 0.45))
		center_vbox.add_child(lock_lbl)

	elif not is_equipped:
		sb.bg_color = Color(0.08, 0.10, 0.15, 0.85)
		sb.border_color = Color(0.30, 0.40, 0.55, 0.7)
		sb.set_border_width_all(1)
		tile.add_theme_stylebox_override("panel", sb)

		var top_row := HBoxContainer.new()
		vbox.add_child(top_row)
		var s_lbl := Label.new()
		s_lbl.text = s_name
		s_lbl.add_theme_font_size_override("font_size", 14)
		s_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		top_row.add_child(s_lbl)

		var empty_lbl := Label.new()
		empty_lbl.text = "Слот не занят"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		vbox.add_child(empty_lbl)

		var btn_equip := Button.new()
		btn_equip.text = "+ Надеть реликвию"
		btn_equip.custom_minimum_size = Vector2(0, 32)
		btn_equip.add_theme_font_size_override("font_size", 12)
		btn_equip.pressed.connect(_show_slot_relic_picker_modal.bind(char_id, slot_name))
		vbox.add_child(btn_equip)

		if slot_name == "head":
			tut_slot_btn_head = btn_equip
		elif slot_name == "hands":
			tut_slot_btn_hands = btn_equip

	else:
		var r: Dictionary = equipped[slot_name]
		var rarity: int = int(r.get("rarity", 4))
		var col := RelicSystem.get_rarity_color(rarity)
		var m_stat: Dictionary = r.get("main_stat", {})
		var m_type := String(m_stat.get("type", ""))
		var m_val := float(m_stat.get("value", 0.0))

		sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
		sb.border_color = col
		sb.set_border_width_all(1)
		tile.add_theme_stylebox_override("panel", sb)

		var top_row := HBoxContainer.new()
		vbox.add_child(top_row)

		var s_lbl := Label.new()
		s_lbl.text = s_name
		s_lbl.add_theme_font_size_override("font_size", 13)
		s_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		top_row.add_child(s_lbl)

		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(sp)

		var lvl_lbl := Label.new()
		lvl_lbl.text = "%d★ +%d" % [rarity, int(r.get("level", 0))]
		lvl_lbl.add_theme_font_size_override("font_size", 12)
		lvl_lbl.add_theme_color_override("font_color", col)
		top_row.add_child(lvl_lbl)

		var set_lbl := Label.new()
		set_lbl.text = "«%s»" % RelicSystem.get_set_name(String(r.get("set_id", "")))
		set_lbl.add_theme_font_size_override("font_size", 11)
		set_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		set_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(set_lbl)

		var main_lbl := Label.new()
		main_lbl.text = "%s: %s" % [RelicSystem.format_stat_name(m_type), RelicSystem.format_stat_value(m_type, m_val)]
		main_lbl.add_theme_font_size_override("font_size", 12)
		main_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		vbox.add_child(main_lbl)

		var subs: Array = r.get("substats", [])
		var sub_strs: Array[String] = []
		for s in subs:
			if s is Dictionary:
				var st := String(s.get("type", ""))
				var sv := float(s.get("value", 0.0))
				sub_strs.append("%s %s" % [RelicSystem.format_stat_name(st), RelicSystem.format_stat_value(st, sv)])
		var subs_lbl := Label.new()
		subs_lbl.text = "• " + (", ".join(sub_strs) if not sub_strs.is_empty() else "Сабстаты отсутствуют")
		subs_lbl.add_theme_font_size_override("font_size", 10)
		subs_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.76))
		subs_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(subs_lbl)

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		vbox.add_child(btn_row)

		var btn_up := Button.new()
		btn_up.text = "⚡ Прокачать"
		btn_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_up.custom_minimum_size = Vector2(0, 28)
		btn_up.add_theme_font_size_override("font_size", 11)
		btn_up.pressed.connect(_show_relic_upgrade_modal.bind(r))
		btn_row.add_child(btn_up)

		if slot_name == "head":
			tut_slot_btn_upgrade_head = btn_up

		var btn_ch := Button.new()
		btn_ch.text = "🔄"
		btn_ch.custom_minimum_size = Vector2(30, 28)
		btn_ch.add_theme_font_size_override("font_size", 11)
		btn_ch.pressed.connect(_show_slot_relic_picker_modal.bind(char_id, slot_name))
		btn_row.add_child(btn_ch)

		var btn_un := Button.new()
		btn_un.text = "❌"
		btn_un.custom_minimum_size = Vector2(30, 28)
		btn_un.add_theme_font_size_override("font_size", 11)
		btn_un.pressed.connect(func():
			TeamConfig.unequip_relic(char_id, slot_name)
			TeamConfig.save_game()
			_update_equipped_relics_ui(char_id)
		)
		btn_row.add_child(btn_un)

	return tile

# Модальное окно выбора реликвии для определенного слота
func _show_slot_relic_picker_modal(char_id: String, slot: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.08, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(850, 580)
	var p_box := StyleBoxFlat.new()
	p_box.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	p_box.set_border_width_all(2)
	p_box.border_color = Color(0.4, 0.6, 0.9)
	p_box.set_corner_radius_all(12)
	p_box.content_margin_left = 22
	p_box.content_margin_right = 22
	p_box.content_margin_top = 18
	p_box.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", p_box)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Выберите реликвию: %s" % RelicSystem.get_slot_name(slot)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	var count := 0
	var first_card: Control = null
	var select_cb := func(picked_r: Dictionary):
		TeamConfig.equip_relic(char_id, slot, picked_r.get("uid", ""))
		TeamConfig.save_game()
		overlay.queue_free()
		_update_equipped_relics_ui(char_id)
		if is_menu_tutorial and menu_tut_step == 4 and slot == "head":
			_run_menu_tut_step(5)
		elif is_menu_tutorial and menu_tut_step == 5 and slot == "hands":
			_run_menu_tut_step(6)

	for r in TeamConfig.relic_inventory:
		if r.get("slot", "") == slot:
			if is_menu_tutorial and (menu_tut_step == 4 or menu_tut_step == 5) and r.get("set_id", "") != "chaos":
				continue
			var card := _create_relic_card_widget(r, false, select_cb)
			grid.add_child(card)
			if first_card == null:
				first_card = card
			count += 1

	if is_menu_tutorial and (menu_tut_step == 4 or menu_tut_step == 5) and first_card:
		var sel_btn: Button = first_card.find_child("Button", true, false)
		if sel_btn:
			_show_menu_pointer_for_control(sel_btn, "down")
		else:
			_show_menu_pointer_for_control(first_card, "down")

	if count == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "В инвентаре нет реликвий для слота «%s».\nДобудьте их в меню «Добыча реликвий»!" % RelicSystem.get_slot_name(slot)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		grid.add_child(empty_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var btn_unequip := Button.new()
	btn_unequip.text = "❌ Снять текущую"
	btn_unequip.custom_minimum_size = Vector2(180, 44)
	btn_unequip.pressed.connect(func():
		TeamConfig.unequip_relic(char_id, slot)
		TeamConfig.save_game()
		overlay.queue_free()
		_update_equipped_relics_ui(char_id)
	)
	btn_row.add_child(btn_unequip)

	var btn_close := Button.new()
	btn_close.text = "Закрыть"
	btn_close.custom_minimum_size = Vector2(140, 44)
	btn_close.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(btn_close)

# ==============================================================================
# СЕТЕВАЯ ИНТЕГРАЦИЯ, ДИНАМИЧЕСКИЕ БАННЕРЫ, ПРОМОКОДЫ И КРИПТО-ОБНОВЛЕНИЯ
# ==============================================================================

var network_banners: Array[Dictionary] = []

func _setup_network_and_updater_integration() -> void:
	# 1. Подписываемся на обновление баннеров с сервера
	if has_node("/root/NetworkManager"):
		var nm = get_node("/root/NetworkManager")
		if nm and nm.banners:
			nm.banners.banners_updated.connect(_on_server_banners_updated)
			nm.banners.fetch_active_banners()

	# 2. Проверяем наличие PCK-обновлений в фоне
	if has_node("/root/PatchManager"):
		var pm = get_node("/root/PatchManager")
		if pm:
			pm.update_check_finished.connect(_on_background_update_check_finished)
			pm.update_installed.connect(_on_patch_installed)
			pm.update_failed.connect(_on_patch_failed)
			pm.check_for_updates()

func _on_server_banners_updated(banners_list: Array[Dictionary]) -> void:
	if banners_list.is_empty():
		return
	network_banners = banners_list
	if banner_select_option:
		banner_select_option.clear()
		for i in network_banners.size():
			banner_select_option.add_item(network_banners[i].title, i)
		active_banner_idx = 0
		_refresh_gacha_ui()

func _on_background_update_check_finished(has_update: bool, update_info: Dictionary) -> void:
	if has_update and not update_info.is_empty():
		var remote_ver: String = str(update_info.get("latest_version", ""))
		if _is_patch_already_applied(remote_ver):
			print("[MainMenu] Patch v%s is already applied. Skipping dialog." % remote_ver)
			return

		var is_mandatory: bool = bool(update_info.get("mandatory", false))
		if is_mandatory:
			notification_label.text = "⚡ Идёт автозагрузка обязательного обновления v%s..." % remote_ver
		else:
			_show_update_available_dialog(update_info)

func _is_patch_already_applied(remote_ver: String) -> bool:
	if remote_ver.is_empty():
		return false
	if has_node("/root/PatchManager"):
		var pm = get_node("/root/PatchManager")
		if pm and pm.has_method("is_version_already_installed"):
			if pm.is_version_already_installed(remote_ver):
				return true
	var paths := ["user://installed_patches.json", "res://user_data/installed_patches.json"]
	for p in paths:
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f:
				var parsed = JSON.parse_string(f.get_as_text())
				f.close()
				if parsed is Dictionary and str(parsed.get("installed_version", "")) == remote_ver:
					return true
	return false

func _on_check_updates_pressed() -> void:
	if not has_node("/root/PatchManager"):
		_show_info_dialog("Система обновлений", "Модуль обновления не инициализирован.")
		return

	var pm = get_node("/root/PatchManager")
	notification_label.text = "🔍 Проверка наличия обновлений..."
	pm.update_check_finished.connect(func(has_up: bool, info: Dictionary):
		if not has_up or (info.has("latest_version") and _is_patch_already_applied(str(info["latest_version"]))):
			notification_label.text = "✓ У вас установлена самая последняя версия!"
			_show_info_dialog("Обновления", "У вас установлена последняя версия игры: v%s" % pm.CURRENT_VERSION)
	, CONNECT_ONE_SHOT)
	pm.check_for_updates()

func _show_update_available_dialog(update_info: Dictionary) -> void:
	if get_node_or_null("UpdateCanvasLayer") != null:
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "UpdateCanvasLayer"
	canvas_layer.layer = 110
	add_child(canvas_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(550, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.20, 0.98)
	sb.border_color = Color(0.4, 0.7, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	var new_ver: String = str(update_info.get("latest_version", "1.4.0"))
	title.text = "🚀 ДОСТУПНО ОБНОВЛЕНИЕ v%s!" % new_ver
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var changelog_box := RichTextLabel.new()
	changelog_box.bbcode_enabled = true
	var cl_text: String = str(update_info.get("changelog", "Улучшения производительности и новые герои."))
	cl_text = cl_text.replace("\\n", "\n")
	changelog_box.text = "[color=#88ccff]Список изменений:[/color]\n" + cl_text
	changelog_box.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(changelog_box)

	var status_lbl := Label.new()
	status_lbl.text = "Размер: %.2f МБ | Подпись: RSA-2048 (Zero-Trust)" % (float(update_info.get("patch", {}).get("size_bytes", 0)) / (1024.0 * 1024.0))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(status_lbl)

	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_box)

	var btn_install := Button.new()
	btn_install.text = "⬇ Скачать и применить патч"
	btn_install.custom_minimum_size = Vector2(250, 46)
	btn_box.add_child(btn_install)

	var btn_later := Button.new()
	btn_later.text = "Позже"
	btn_later.custom_minimum_size = Vector2(130, 46)
	btn_later.pressed.connect(func(): canvas_layer.queue_free())
	btn_box.add_child(btn_later)

	btn_install.pressed.connect(func():
		btn_install.disabled = true
		status_lbl.text = "⏳ Загрузка и проверка цифровой подписи..."
		var pm = get_node("/root/PatchManager")
		pm.download_and_install_patch(update_info)
	)

func _on_patch_installed(version: String) -> void:
	notification_label.text = "✅ Патч v%s успешно применён! Перезапуск интерфейса..." % version
	var reg_layer = get_node_or_null("RegistrationCanvasLayer")
	if reg_layer:
		reg_layer.queue_free()
	var upd_layer = get_node_or_null("UpdateCanvasLayer")
	if upd_layer:
		upd_layer.queue_free()
	_show_info_dialog("Обновление установлено", "Патч v%s успешно проверен и смонтирован! Перезапуск меню..." % version)
	get_tree().create_timer(1.2).timeout.connect(func():
		get_tree().reload_current_scene()
	)

func _on_patch_failed(err_msg: String) -> void:
	_show_info_dialog("Ошибка обновления", "Безопасность: " + err_msg)

func _show_settings_dialog() -> void:
	if get_node_or_null("SettingsCanvasLayer") != null:
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "SettingsCanvasLayer"
	canvas_layer.layer = 115
	add_child(canvas_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 310)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	sb.border_color = Color(0.85, 0.70, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var lbl_title := Label.new()
	lbl_title.text = "⚙️ НАСТРОЙКИ"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(lbl_title)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# --- СЕКЦИЯ ГРОМКОСТИ ---
	var vol_vbox := VBoxContainer.new()
	vol_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(vol_vbox)

	var vol_header_hbox := HBoxContainer.new()
	vol_vbox.add_child(vol_header_hbox)

	var vol_title := Label.new()
	vol_title.text = "🔊 Общая громкость звука и музыки:"
	vol_title.add_theme_font_size_override("font_size", 16)
	vol_title.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	vol_header_hbox.add_child(vol_title)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_header_hbox.add_child(sp)

	var vol_value_lbl := Label.new()
	vol_value_lbl.text = "%d / 10" % TeamConfig.master_volume
	vol_value_lbl.add_theme_font_size_override("font_size", 18)
	vol_value_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vol_header_hbox.add_child(vol_value_lbl)

	# Ползунок громкости (0 до 10, по умолчанию 7)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 10
	slider.step = 1
	slider.value = TeamConfig.master_volume
	slider.ticks_on_borders = true
	slider.custom_minimum_size = Vector2(460, 36)
	slider.value_changed.connect(func(val: float):
		var v_int := int(val)
		vol_value_lbl.text = "%d / 10" % v_int
		TeamConfig.apply_audio_volume(v_int)
		TeamConfig.save_game(false)
	)
	vol_vbox.add_child(slider)

	# Версия
	var version_lbl := Label.new()
	version_lbl.text = "Версия игры: v%s" % (PatchManager.CURRENT_VERSION if has_node("/root/PatchManager") else "1.7.2")
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.add_theme_font_size_override("font_size", 13)
	version_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	vbox.add_child(version_lbl)

	# Кнопка закрытия
	var btn_close := Button.new()
	btn_close.text = "✓ Закрыть"
	btn_close.custom_minimum_size = Vector2(220, 44)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.20, 0.28, 0.42, 0.95)
	csb.border_color = Color(0.85, 0.70, 0.25)
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(10)
	btn_close.add_theme_stylebox_override("normal", csb)
	btn_close.pressed.connect(func():
		canvas_layer.queue_free()
	)
	vbox.add_child(btn_close)

func _show_promo_code_dialog() -> void:
	if get_node_or_null("PromoCanvasLayer") != null:
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "PromoCanvasLayer"
	canvas_layer.layer = 115
	add_child(canvas_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 280)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	sb.border_color = Color(0.85, 0.7, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var lbl_title := Label.new()
	lbl_title.text = "🎁 АКТИВАЦИЯ ПРОМОКОДА"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(lbl_title)

	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "Введите промокод (например, VOID2026)..."
	line_edit.custom_minimum_size = Vector2(0, 44)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.add_theme_font_size_override("font_size", 18)
	vbox.add_child(line_edit)

	var result_lbl := Label.new()
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(result_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var btn_redeem := Button.new()
	btn_redeem.text = "Активировать"
	btn_redeem.custom_minimum_size = Vector2(160, 44)
	btn_row.add_child(btn_redeem)

	var btn_cancel := Button.new()
	btn_cancel.text = "Закрыть"
	btn_cancel.custom_minimum_size = Vector2(120, 44)
	btn_cancel.pressed.connect(func(): canvas_layer.queue_free())
	btn_row.add_child(btn_cancel)

	var promo_mgr = null
	if has_node("/root/NetworkManager"):
		var nm = get_node("/root/NetworkManager")
		if nm:
			promo_mgr = nm.promo

	var on_redeemed: Callable
	var on_failed: Callable

	var cleanup_promo_signals := func():
		if promo_mgr != null and is_instance_valid(promo_mgr):
			if on_redeemed.is_valid() and promo_mgr.promo_redeemed.is_connected(on_redeemed):
				promo_mgr.promo_redeemed.disconnect(on_redeemed)
			if on_failed.is_valid() and promo_mgr.promo_failed.is_connected(on_failed):
				promo_mgr.promo_failed.disconnect(on_failed)

	canvas_layer.tree_exiting.connect(cleanup_promo_signals)

	on_redeemed = func(c: String, rewards: Dictionary):
		cleanup_promo_signals.call()
		if is_instance_valid(btn_redeem):
			btn_redeem.disabled = false
		if is_instance_valid(result_lbl):
			result_lbl.text = "🎉 Успешно! Получено: %s" % JSON.stringify(rewards)
			result_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		_update_coins_display()

	on_failed = func(c: String, reason: String):
		cleanup_promo_signals.call()
		if is_instance_valid(btn_redeem):
			btn_redeem.disabled = false
		if is_instance_valid(result_lbl):
			result_lbl.text = "❌ " + reason
			result_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	btn_redeem.pressed.connect(func():
		var code := line_edit.text.strip_edges()
		if code.is_empty():
			result_lbl.text = "❌ Введите код!"
			result_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			return

		if promo_mgr == null:
			result_lbl.text = "❌ Сетевой менеджер недоступен."
			return

		cleanup_promo_signals.call()
		promo_mgr.promo_redeemed.connect(on_redeemed)
		promo_mgr.promo_failed.connect(on_failed)

		btn_redeem.disabled = true
		result_lbl.text = "⏳ Проверка кода..."
		result_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

		promo_mgr.redeem_promo_code(code)
	)

func _show_info_dialog(title_txt: String, msg_txt: String) -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 130
	add_child(canvas_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	sb.border_color = Color(0.4, 0.6, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var t := Label.new()
	t.text = title_txt
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 20)
	vbox.add_child(t)

	var m := Label.new()
	m.text = msg_txt
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.add_theme_font_size_override("font_size", 15)
	vbox.add_child(m)

	var btn_ok := Button.new()
	btn_ok.text = "OK"
	btn_ok.custom_minimum_size = Vector2(100, 38)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ok.pressed.connect(func(): canvas_layer.queue_free())
	vbox.add_child(btn_ok)

## Проверка статуса регистрации/привязки аккаунта игрока
func _check_account_registration() -> void:
	if not has_node("/root/NetworkManager"):
		return
	var nm = get_node("/root/NetworkManager")
	if nm == null or nm.auth == null:
		return

	var check_func := func():
		# Не открываем окно, если в фоне скачивается патч
		if has_node("/root/PatchManager"):
			var pm = get_node("/root/PatchManager")
			if pm and pm.is_downloading:
				return

		var auth = nm.auth
		if auth == null:
			return
		# Если игрок анонимный или никнейм не задан — открываем регистрацию
		if auth.is_authenticated():
			if auth.is_anonymous or auth.nickname.is_empty():
				var has_progress := TeamConfig.has_save_file() or TeamConfig.unlocked_characters.size() > 1
				_show_registration_dialog(has_progress)
		else:
			# Если ещё не авторизован, ждём первого сигнала auth_state_changed
			auth.auth_state_changed.connect(func(logged_in: bool, _uid: String):
				if has_node("/root/PatchManager"):
					var pm = get_node("/root/PatchManager")
					if pm and pm.is_downloading:
						return
				if logged_in and (auth.is_anonymous or auth.nickname.is_empty()):
					var has_prog := TeamConfig.has_save_file() or TeamConfig.unlocked_characters.size() > 1
					_show_registration_dialog(has_prog)
			, CONNECT_ONE_SHOT)

	# Вызываем с небольшой задержкой (после загрузки интерфейса)
	get_tree().create_timer(0.4).timeout.connect(check_func)

## Модальное окно обязательной регистрации / привязки аккаунта
func _show_registration_dialog(is_linking_initial: bool) -> void:
	if get_node_or_null("RegistrationCanvasLayer") != null:
		return

	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "RegistrationCanvasLayer"
	canvas_layer.layer = 120
	add_child(canvas_layer)

	var overlay := ColorRect.new()
	overlay.name = "RegistrationOverlay"
	overlay.color = Color(0.02, 0.03, 0.06, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 480)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	sb.border_color = Color(0.3, 0.7, 1.0, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	vbox.add_child(subtitle_lbl)

	# Поле ввода Никнейма
	var lbl_nick := Label.new()
	lbl_nick.text = "Игровой никнейм:"
	lbl_nick.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_nick)

	var nick_edit := LineEdit.new()
	nick_edit.placeholder_text = "Например: Rimes"
	nick_edit.custom_minimum_size = Vector2(0, 42)
	nick_edit.add_theme_font_size_override("font_size", 16)
	vbox.add_child(nick_edit)

	# Поле ввода Пароля
	var lbl_pass := Label.new()
	lbl_pass.text = "Пароль (минимум 6 символов):"
	lbl_pass.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_pass)

	var pass_edit := LineEdit.new()
	pass_edit.placeholder_text = "••••••••"
	pass_edit.secret = true
	pass_edit.custom_minimum_size = Vector2(0, 42)
	pass_edit.add_theme_font_size_override("font_size", 16)
	vbox.add_child(pass_edit)

	# Статус / Сообщение об ошибке
	var status_lbl := Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(status_lbl)

	# Кнопка подтверждения
	var btn_submit := Button.new()
	btn_submit.custom_minimum_size = Vector2(0, 46)
	btn_submit.add_theme_font_size_override("font_size", 16)
	var submit_sb := StyleBoxFlat.new()
	submit_sb.bg_color = Color(0.18, 0.45, 0.85, 1.0)
	submit_sb.set_corner_radius_all(8)
	btn_submit.add_theme_stylebox_override("normal", submit_sb)
	vbox.add_child(btn_submit)

	# Переключатель режима (Регистрация / Вход)
	var btn_toggle_mode := Button.new()
	btn_toggle_mode.flat = true
	btn_toggle_mode.add_theme_font_size_override("font_size", 13)
	btn_toggle_mode.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(btn_toggle_mode)

	# Кнопка «Пропустить и играть как гость»
	var btn_skip := Button.new()
	btn_skip.text = "✖ Пропустить и играть как гость (напомнить позже)"
	btn_skip.flat = true
	btn_skip.add_theme_font_size_override("font_size", 12)
	btn_skip.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	btn_skip.pressed.connect(func():
		canvas_layer.queue_free()
	)
	vbox.add_child(btn_skip)

	# Состояние режима: "link" (привязка), "register" (новый), "login" (вход)
	var current_mode := ["link" if is_linking_initial else "register"]

	var update_mode_ui := func():
		status_lbl.text = ""
		btn_submit.disabled = false
		if current_mode[0] == "link":
			title_lbl.text = "🛡 ПРИВЯЗКА АККАУНТА"
			subtitle_lbl.text = "У вас уже есть игровой прогресс! Привяжите ник и пароль к вашему текущему аккаунту, чтобы не потерять персонажей."
			btn_submit.text = "🔗 Привязать ник и пароль"
			btn_toggle_mode.text = "Уже привязывали ранее? Войти в аккаунт ➔"
		elif current_mode[0] == "register":
			title_lbl.text = "⚔ РЕГИСТРАЦИЯ"
			subtitle_lbl.text = "Создайте аккаунт, чтобы начать путешествие и сохранять прогресс в облаке."
			btn_submit.text = "✨ Зарегистрироваться"
			btn_toggle_mode.text = "Уже есть аккаунт? Войти ➔"
		else: # login
			title_lbl.text = "🔑 ВХОД В АККАУНТ"
			subtitle_lbl.text = "Введите ваш никнейм и пароль для загрузки профиля и персонажей."
			btn_submit.text = "➔ Войти"
			btn_toggle_mode.text = "Создать новый аккаунт / Привязать ➔"

	update_mode_ui.call()

	btn_toggle_mode.pressed.connect(func():
		if current_mode[0] == "login":
			current_mode[0] = "link" if is_linking_initial else "register"
		else:
			current_mode[0] = "login"
		update_mode_ui.call()
	)

	btn_submit.pressed.connect(func():
		var nick := nick_edit.text.strip_edges()
		var password_text := pass_edit.text.strip_edges()

		if nick.length() < 2:
			status_lbl.text = "❌ Никнейм должен содержать минимум 2 символа!"
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			return
		if password_text.length() < 6:
			status_lbl.text = "❌ Пароль должен содержать минимум 6 символов!"
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			return

		btn_submit.disabled = true
		status_lbl.text = "⏳ Обработка..."
		status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

		var nm = get_node_or_null("/root/NetworkManager")
		if nm == null or nm.auth == null:
			canvas_layer.queue_free()
			return

		var auth = nm.auth

		if current_mode[0] == "link":
			auth.link_anonymous_account(nick, password_text, func(ok: bool, msg: String):
				if ok:
					status_lbl.text = "✓ " + msg
					status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
					if nm.sync:
						nm.sync.sync_to_cloud()
					notification_label.text = "✅ Аккаунт привязан к «%s»!" % nick
					get_tree().create_timer(1.0).timeout.connect(func(): canvas_layer.queue_free())
				else:
					btn_submit.disabled = false
					status_lbl.text = "❌ " + msg
					status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			)
		elif current_mode[0] == "register":
			auth.register_with_nickname(nick, password_text, func(ok: bool, msg: String):
				if ok:
					status_lbl.text = "✓ " + msg
					status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
					if nm.sync:
						nm.sync.has_initial_sync_completed = true
						nm.sync.sync_to_cloud()
					notification_label.text = "🎉 Добро пожаловать, «%s»!" % nick
					get_tree().create_timer(1.0).timeout.connect(func(): canvas_layer.queue_free())
				else:
					btn_submit.disabled = false
					status_lbl.text = "❌ " + msg
					status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			)
		else: # login
			auth.login_with_nickname(nick, password_text, func(ok: bool, msg: String):
				if ok:
					status_lbl.text = "✓ " + msg
					status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
					if nm.sync:
						nm.sync.has_initial_sync_completed = false
						nm.sync.sync_from_cloud()
					notification_label.text = "✅ Вход выполнен: «%s»!" % nick
					get_tree().create_timer(1.0).timeout.connect(func():
						canvas_layer.queue_free()
						_refresh_hub_overview()
						_refresh_gacha_ui()
					)
				else:
					btn_submit.disabled = false
					status_lbl.text = "❌ " + msg
					status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			)
	)

# ==============================================================================
# ЗАЛ ВОСПОМИНАНИЙ (MEMORY HALL)
# ==============================================================================

func _create_hub_memory_hall_card(parent: Control) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(230, 126)
	btn.text = "ЗАЛ ВОСПОМИНАНИЙ"
	btn.add_theme_font_size_override("font_size", 1)
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))

	var is_completed: bool = TeamConfig.is_memory_hall_completed()
	var initial_border: Color = Color(0.65, 0.35, 0.90, 0.70) if is_completed else Color(0.80, 0.35, 1.0, 0.95)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.08, 0.18, 0.92)
	sb_normal.border_color = initial_border
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(14)
	if not is_completed:
		sb_normal.shadow_color = Color(0.70, 0.25, 0.95, 0.35)
		sb_normal.shadow_size = 8
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.set_meta("sb_normal", sb_normal)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.16, 0.12, 0.28, 0.96)
	sb_hover.border_color = Color(0.95, 0.65, 1.0, 1.0)
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(14)
	sb_hover.shadow_color = Color(0.9, 0.5, 1.0, 0.40)
	sb_hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.12, 0.07, 0.22, 0.98)
	sb_pressed.border_color = Color(1.0, 0.85, 1.0, 1.0)
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	sb_disabled.border_color = Color(0.18, 0.12, 0.26, 0.40)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	btn.set_meta("card_content_node", content)

	var icon_lbl := Label.new()
	icon_lbl.text = "🏛"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_lbl)
	btn.set_meta("card_icon_lbl", icon_lbl)

	var title_lbl := Label.new()
	title_lbl.text = "ЗАЛ ВОСПОМИНАНИЙ"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_lbl)
	btn.set_meta("card_title_lbl", title_lbl)

	var sub_lbl := Label.new()
	var stars: int = TeamConfig.get_memory_hall_total_stars()
	sub_lbl.text = "Сезон 1 • ⭐ %d/12" % stars
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.90))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(sub_lbl)
	btn.set_meta("card_sub_lbl", sub_lbl)

	parent.add_child(btn)
	_setup_memory_hall_shimmer(btn)
	return btn

func _refresh_memory_hall_card() -> void:
	if not btn_menu_memory_hall or not is_instance_valid(btn_menu_memory_hall):
		return
	var sub_lbl: Label = btn_menu_memory_hall.get_meta("card_sub_lbl", null)
	if sub_lbl:
		var stars: int = TeamConfig.get_memory_hall_total_stars()
		if TeamConfig.is_memory_hall_completed():
			sub_lbl.text = "Сезон пройден! • ⭐ %d/12" % stars
			sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
		else:
			sub_lbl.text = "Сезон 1 • ⭐ %d/12" % stars
			sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.90))
	_setup_memory_hall_shimmer(btn_menu_memory_hall)

func _setup_memory_hall_shimmer(btn: Button) -> void:
	if not btn or not is_instance_valid(btn):
		return
	var sb: StyleBoxFlat = btn.get_meta("sb_normal", null)
	if not sb:
		return
	var is_completed: bool = TeamConfig.is_memory_hall_completed()
	if _memory_hall_shimmer_tween and _memory_hall_shimmer_tween.is_valid():
		_memory_hall_shimmer_tween.kill()
		_memory_hall_shimmer_tween = null

	if is_completed:
		sb.border_color = Color(0.60, 0.35, 0.85, 0.75)
		sb.shadow_size = 0
	else:
		sb.shadow_color = Color(0.75, 0.30, 1.0, 0.35)
		sb.shadow_size = 8
		_memory_hall_shimmer_tween = btn.create_tween().set_loops()
		_memory_hall_shimmer_tween.tween_property(sb, "border_color", Color(0.95, 0.55, 1.0, 1.0), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_memory_hall_shimmer_tween.tween_property(sb, "border_color", Color(0.45, 0.18, 0.70, 0.60), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_memory_hall_screen() -> void:
	if memory_hall_screen and is_instance_valid(memory_hall_screen):
		memory_hall_screen.queue_free()

	memory_hall_screen = VBoxContainer.new()
	memory_hall_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	memory_hall_screen.add_theme_constant_override("separation", 12)
	memory_hall_screen.visible = false
	add_child(memory_hall_screen)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 10)
	memory_hall_screen.add_child(top_spacer)

	var header := Label.new()
	header.text = "🏛 ЗАЛ ВОСПОМИНАНИЙ"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.92, 0.85, 1.0))
	memory_hall_screen.add_child(header)

	memory_hall_status_label = Label.new()
	memory_hall_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_hall_status_label.add_theme_font_size_override("font_size", 15)
	memory_hall_status_label.add_theme_color_override("font_color", Color(0.80, 0.70, 0.95))
	memory_hall_screen.add_child(memory_hall_status_label)

	var turb_panel := PanelContainer.new()
	turb_panel.custom_minimum_size = Vector2(900, 52)
	turb_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var turb_sb := StyleBoxFlat.new()
	turb_sb.bg_color = Color(0.12, 0.08, 0.20, 0.90)
	turb_sb.border_color = Color(0.65, 0.35, 0.95, 0.80)
	turb_sb.set_border_width_all(2)
	turb_sb.set_corner_radius_all(10)
	turb_sb.set_content_margin_all(8)
	turb_panel.add_theme_stylebox_override("panel", turb_sb)
	memory_hall_screen.add_child(turb_panel)

	var turb_lbl := RichTextLabel.new()
	turb_lbl.bbcode_enabled = true
	turb_lbl.fit_content = true
	turb_lbl.scroll_active = false
	turb_lbl.text = "[center]🌪 [b][color=#e0aaff]Турбулентность: «Командная работа»[/color][/b] — Урон союзников фракции «Небожители» [color=#60ff90]+30%[/color]  |  Скорость союзников «Рассвет Хаоса» [color=#60d0ff]+20%[/color][/center]"
	turb_panel.add_child(turb_lbl)

	var rewards_panel := PanelContainer.new()
	rewards_panel.custom_minimum_size = Vector2(900, 64)
	rewards_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var rew_sb := StyleBoxFlat.new()
	rew_sb.bg_color = Color(0.08, 0.09, 0.14, 0.85)
	rew_sb.border_color = Color(0.35, 0.40, 0.60, 0.60)
	rew_sb.set_border_width_all(1)
	rew_sb.set_corner_radius_all(10)
	rew_sb.set_content_margin_all(10)
	rewards_panel.add_theme_stylebox_override("panel", rew_sb)
	memory_hall_screen.add_child(rewards_panel)

	var rew_vbox := VBoxContainer.new()
	rew_vbox.add_theme_constant_override("separation", 6)
	rewards_panel.add_child(rew_vbox)

	var rew_top_hbox := HBoxContainer.new()
	rew_top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rew_top_hbox.add_theme_constant_override("separation", 20)
	rew_vbox.add_child(rew_top_hbox)

	memory_hall_stars_label = Label.new()
	memory_hall_stars_label.add_theme_font_size_override("font_size", 16)
	memory_hall_stars_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	rew_top_hbox.add_child(memory_hall_stars_label)

	var btn_claim := Button.new()
	btn_claim.name = "BtnClaimRewards"
	btn_claim.text = "🎁 Забрать награды"
	btn_claim.custom_minimum_size = Vector2(170, 32)
	btn_claim.pressed.connect(_on_memory_hall_claim_rewards_pressed)
	rew_top_hbox.add_child(btn_claim)

	memory_hall_rewards_container = HBoxContainer.new()
	memory_hall_rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	memory_hall_rewards_container.add_theme_constant_override("separation", 14)
	rew_vbox.add_child(memory_hall_rewards_container)

	var scroll_cards := ScrollContainer.new()
	scroll_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_cards.custom_minimum_size = Vector2(0, 300)
	memory_hall_screen.add_child(scroll_cards)

	var center_cards := CenterContainer.new()
	center_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_cards.add_child(center_cards)

	memory_hall_cards_container = GridContainer.new()
	memory_hall_cards_container.columns = 4
	memory_hall_cards_container.add_theme_constant_override("h_separation", 18)
	memory_hall_cards_container.add_theme_constant_override("v_separation", 14)
	center_cards.add_child(memory_hall_cards_container)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.custom_minimum_size = Vector2(0, 50)
	memory_hall_screen.add_child(bottom_bar)

	var btn_back := Button.new()
	btn_back.text = "↩ Назад в меню"
	btn_back.custom_minimum_size = Vector2(200, 44)
	btn_back.pressed.connect(func(): _show_screen("hub"))
	bottom_bar.add_child(btn_back)

func _refresh_memory_hall_screen() -> void:
	if not memory_hall_screen or not is_instance_valid(memory_hall_screen):
		return

	var is_active := MemoryHallManager.is_season_active()
	if is_active:
		memory_hall_status_label.text = "Сезон 1: Испытание Безмолвия  |  До завершения: %s (МСК / GMT+3)" % MemoryHallManager.get_season_time_remaining_str()
		memory_hall_status_label.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	else:
		memory_hall_status_label.text = "⛔ Сезон завершён! Режим временно заблокирован до следующего обновления."
		memory_hall_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	var total_stars: int = TeamConfig.get_memory_hall_total_stars()
	memory_hall_stars_label.text = "⭐ Всего звёзд: %d / 12" % total_stars

	for c in memory_hall_rewards_container.get_children():
		memory_hall_rewards_container.remove_child(c)
		c.queue_free()

	var milestones := [
		{"key": "stars_3", "label": "3★", "shine": 5},
		{"key": "stars_6", "label": "6★", "shine": 5},
		{"key": "stars_9", "label": "9★", "shine": 5},
		{"key": "stars_12", "label": "12★", "shine": 5},
		{"key": "floor_4_clear", "label": "4 Этаж (≤28 ц)", "shine": 4}
	]

	var can_claim_any := false
	for m in milestones:
		var key: String = m["key"]
		var is_claimed: bool = key in TeamConfig.memory_hall_claimed_rewards
		var is_available: bool = TeamConfig.can_claim_memory_hall_reward(key) and is_active

		if is_available:
			can_claim_any = true

		var btn_milestone := Button.new()
		btn_milestone.custom_minimum_size = Vector2(165, 46)

		if is_claimed:
			btn_milestone.text = "%s: +%d ✨\n✓ Получено" % [m["label"], m["shine"]]
			btn_milestone.disabled = true
			btn_milestone.add_theme_color_override("font_disabled_color", Color(0.4, 0.85, 0.5, 0.9))
		elif is_available:
			btn_milestone.text = "%s: +%d ✨\n🎁 Забрать!" % [m["label"], m["shine"]]
			btn_milestone.disabled = false
			btn_milestone.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
			btn_milestone.pressed.connect(_on_memory_hall_claim_single_reward_pressed.bind(key))
		else:
			btn_milestone.text = "%s: +%d ✨\n🔒 Закрыто" % [m["label"], m["shine"]]
			btn_milestone.disabled = true
			btn_milestone.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65, 0.7))

		memory_hall_rewards_container.add_child(btn_milestone)

	var btn_claim: Button = memory_hall_screen.find_child("BtnClaimRewards", true, false)
	if btn_claim:
		btn_claim.visible = can_claim_any
		btn_claim.disabled = not can_claim_any

	for c in memory_hall_cards_container.get_children():
		memory_hall_cards_container.remove_child(c)
		c.queue_free()

	for f_num in range(1, 5):
		var card := _create_memory_hall_floor_card(f_num, is_active)
		memory_hall_cards_container.add_child(card)

func _on_memory_hall_claim_single_reward_pressed(reward_key: String) -> void:
	var res: Dictionary = TeamConfig.claim_single_memory_hall_reward(reward_key)
	if not res.is_empty():
		_update_coins_display()
		_refresh_memory_hall_screen()
		notification_label.text = "🎉 Получено +%d Блеска Свечения за «%s»!" % [int(res.get("shine", 0)), res.get("name", "")]

func _on_memory_hall_claim_rewards_pressed() -> void:
	var granted: Array[Dictionary] = TeamConfig.claim_memory_hall_rewards()
	if not granted.is_empty():
		var total_shine := 0
		for g in granted:
			total_shine += int(g.get("shine", 0))
		_update_coins_display()
		_refresh_memory_hall_screen()
		notification_label.text = "🎉 Получено +%d Блеска Свечения за Зал воспоминаний!" % total_shine

func _create_memory_hall_floor_card(floor_num: int, is_active: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(215, 290)

	var is_unlocked: bool = (floor_num <= TeamConfig.memory_hall_unlocked_floor)
	var floor_info: Dictionary = MemoryHallManager.FLOORS.get(floor_num, {})
	var title_str: String = String(floor_info.get("title", "Чертог"))
	var is_two_teams: bool = (floor_num == 4)
	var stars: int = TeamConfig.memory_hall_stars.get(str(floor_num), 0)
	var is_cleared: bool = TeamConfig.is_memory_hall_floor_completed(floor_num)

	var sb := StyleBoxFlat.new()
	if not is_unlocked:
		sb.bg_color = Color(0.06, 0.07, 0.10, 0.85)
		sb.border_color = Color(0.2, 0.22, 0.30, 0.5)
	elif is_cleared:
		sb.bg_color = Color(0.10, 0.09, 0.18, 0.95)
		sb.border_color = Color(0.70, 0.40, 1.0, 0.9)
	else:
		sb.bg_color = Color(0.09, 0.11, 0.18, 0.92)
		sb.border_color = Color(0.35, 0.45, 0.70, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Этаж %d\n%s" % [floor_num, title_str]
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4) if is_unlocked else Color(0.5, 0.55, 0.65))
	vbox.add_child(title_lbl)

	var diff_lbl := Label.new()
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.add_theme_font_size_override("font_size", 11)
	match floor_num:
		1:
			diff_lbl.text = "Уровень 1 • 1 Волна\n(Для начинающих)"
			diff_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
		2:
			diff_lbl.text = "Уровень 2 • 1 Волна\n(Средняя сложность)"
			diff_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		3:
			diff_lbl.text = "Уровень 3 • 2 Волны\n(Требуется прокачка!)"
			diff_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		4:
			diff_lbl.text = "Уровень 4 • 2 Отряда\n(2 Волны × 2 Половины)"
			diff_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.6))
	vbox.add_child(diff_lbl)

	var stars_lbl := Label.new()
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 18)
	if not is_unlocked:
		stars_lbl.text = "🔒 Заблокирован"
		stars_lbl.add_theme_font_size_override("font_size", 13)
		stars_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	elif is_cleared:
		var st_text := ""
		for s in range(3):
			st_text += "⭐" if s < stars else "☆"
		stars_lbl.text = st_text
		stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		stars_lbl.text = "☆☆☆"
		stars_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	vbox.add_child(stars_lbl)

	var cond_lbl := Label.new()
	cond_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cond_lbl.add_theme_font_size_override("font_size", 11)
	cond_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	if is_two_teams:
		cond_lbl.text = "3★: ≥20 ц | 2★: ≥16 ц\n1★: ≥12 ц | Макс: 28 ц"
	else:
		cond_lbl.text = "3★: ≥10 ц | 2★: ≥7 ц\n1★: ≥4 ц | Макс: 14 ц"
	vbox.add_child(cond_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn_intel := Button.new()
	btn_intel.text = "🔍 Противники"
	btn_intel.custom_minimum_size = Vector2(0, 32)
	btn_intel.pressed.connect(func(): _show_floor_intel_modal(floor_num))
	vbox.add_child(btn_intel)

	var btn_battle := Button.new()
	btn_battle.custom_minimum_size = Vector2(0, 36)
	if not is_active:
		btn_battle.text = "⛔ Закрыто"
		btn_battle.disabled = true
	elif not is_unlocked:
		btn_battle.text = "🔒 Закрыт"
		btn_battle.disabled = true
	else:
		btn_battle.text = "⚔ В бой!"
		var b_sb := StyleBoxFlat.new()
		b_sb.bg_color = Color(0.40, 0.18, 0.65, 0.95) if is_two_teams else Color(0.18, 0.45, 0.75, 0.95)
		b_sb.border_color = Color(0.85, 0.65, 1.0, 1.0)
		b_sb.set_border_width_all(1)
		b_sb.set_corner_radius_all(8)
		btn_battle.add_theme_stylebox_override("normal", b_sb)
		if is_two_teams:
			btn_battle.pressed.connect(func(): _open_memory_hall_two_team_setup())
		else:
			btn_battle.pressed.connect(func(): _open_memory_hall_single_team_setup(floor_num))
	vbox.add_child(btn_battle)

	return card

func _show_floor_intel_modal(floor_num: int) -> void:
	var intel: Dictionary = MemoryHallManager.get_floor_intel(floor_num)
	var is_two_teams: bool = bool(intel.get("is_two_teams", false))

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 540)
	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.08, 0.08, 0.14, 0.98)
	p_sb.border_color = Color(0.70, 0.40, 1.0, 0.90)
	p_sb.set_border_width_all(2)
	p_sb.set_corner_radius_all(14)
	p_sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", p_sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "🔍 Разведка: Этаж %d — %s" % [floor_num, intel.get("title", "")]
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	var cycles_str := "Лимит: %d циклов" % int(intel.get("cycles", 14))
	var format_str := "2 Отряда (по 2 волны каждый)" if is_two_teams else "%d волны" % (2 if floor_num == 3 else 1)
	sub_lbl.text = "%s  •  Формат: %s" % [cycles_str, format_str]
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	vbox.add_child(sub_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(content_vbox)

	if not is_two_teams:
		var waves: Array = intel.get("waves", [])
		for w_dict in waves:
			var w_num: int = int(w_dict.get("wave", 1))
			var w_lbl := Label.new()
			w_lbl.text = "🌊 ВОЛНА %d / %d:" % [w_num, waves.size()]
			w_lbl.add_theme_font_size_override("font_size", 15)
			w_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			content_vbox.add_child(w_lbl)

			var enemies: Array = w_dict.get("enemies", [])
			for en in enemies:
				_build_intel_enemy_row(en, content_vbox)
	else:
		var h1_lbl := Label.new()
		h1_lbl.text = "⚔ ПЕРВАЯ ПОЛОВИНА (Команда 1):"
		h1_lbl.add_theme_font_size_override("font_size", 16)
		h1_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
		content_vbox.add_child(h1_lbl)

		var h1_waves: Array = intel.get("half1_waves", [])
		for w_dict in h1_waves:
			var w_num: int = int(w_dict.get("wave", 1))
			var w_lbl := Label.new()
			w_lbl.text = "  🌊 Волна %d / 2:" % w_num
			w_lbl.add_theme_font_size_override("font_size", 14)
			w_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			content_vbox.add_child(w_lbl)

			for en in w_dict.get("enemies", []):
				_build_intel_enemy_row(en, content_vbox)

		var h2_lbl := Label.new()
		h2_lbl.text = "\n⚔ ВТОРАЯ ПОЛОВИНА (Команда 2):"
		h2_lbl.add_theme_font_size_override("font_size", 16)
		h2_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
		content_vbox.add_child(h2_lbl)

		var h2_waves: Array = intel.get("half2_waves", [])
		for w_dict in h2_waves:
			var w_num: int = int(w_dict.get("wave", 1))
			var w_lbl := Label.new()
			w_lbl.text = "  🌊 Волна %d / 2:" % w_num
			w_lbl.add_theme_font_size_override("font_size", 14)
			w_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			content_vbox.add_child(w_lbl)

			for en in w_dict.get("enemies", []):
				_build_intel_enemy_row(en, content_vbox)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(160, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

func _build_intel_enemy_row(en: Dictionary, parent: Control) -> void:
	var row := PanelContainer.new()
	var r_sb := StyleBoxFlat.new()
	r_sb.bg_color = Color(0.12, 0.14, 0.20, 0.70)
	r_sb.set_corner_radius_all(6)
	r_sb.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", r_sb)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)

	var is_elite: bool = bool(en.get("is_elite", false))
	var icon_str := "👹" if is_elite else "👾"

	var name_lbl := RichTextLabel.new()
	name_lbl.bbcode_enabled = true
	name_lbl.fit_content = true
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.custom_minimum_size = Vector2(330, 24)
	var elite_badge := " [color=#ff6070][ЭЛИТА][/color]" if is_elite else ""
	name_lbl.text = "%s [b]%s[/b]%s (ХП: %d)" % [icon_str, en.get("name", "Враг"), elite_badge, int(en.get("hp", 0))]
	hbox.add_child(name_lbl)

	var elem_lbl := Label.new()
	var elem_val: int = int(en.get("element", 0))
	elem_lbl.text = "Тип: %s" % CombatConstants.get_element_label(elem_val)
	elem_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(elem_val))
	elem_lbl.add_theme_font_size_override("font_size", 12)
	elem_lbl.custom_minimum_size = Vector2(110, 24)
	hbox.add_child(elem_lbl)

	var weak_lbl := RichTextLabel.new()
	weak_lbl.bbcode_enabled = true
	weak_lbl.fit_content = true
	weak_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	weak_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weak_lbl.custom_minimum_size = Vector2(300, 24)
	var weak_icons: Array[String] = []
	for w_elem in en.get("weaknesses", []):
		var w_val: int = int(w_elem)
		var col_hex := CombatConstants.get_element_color(w_val).to_html(false)
		var w_name := CombatConstants.get_element_label(w_val)
		weak_icons.append("[color=#%s]%s[/color]" % [col_hex, w_name])
	weak_lbl.text = "Уязвимости: " + (", ".join(weak_icons) if not weak_icons.is_empty() else "—")
	hbox.add_child(weak_lbl)

func _open_memory_hall_single_team_setup(floor_num: int) -> void:
	selected_memory_hall_floor = floor_num
	selected_dungeon_for_battle = ""
	selected_level_for_battle = 0

	var floor_info: Dictionary = MemoryHallManager.FLOORS.get(floor_num, {})
	var title_str: String = String(floor_info.get("title", "Чертог"))
	level_setup_title.text = "🏛 Зал воспоминаний — Этаж %d: %s" % [floor_num, title_str]

	var has_slot := false
	for s in _level_team:
		if s != null:
			has_slot = true
			break
	if not has_slot:
		if not TeamConfig.team_members.is_empty():
			for i in range(mini(4, TeamConfig.team_members.size())):
				var member: Dictionary = TeamConfig.team_members[i]
				var c_id: String = String(member.get("id", ""))
				if TeamConfig.is_character_unlocked(c_id):
					_level_team[i] = member.duplicate(true)
		elif not TeamConfig.last_used_team.is_empty():
			for i in range(mini(4, TeamConfig.last_used_team.size())):
				var member: Dictionary = TeamConfig.last_used_team[i]
				var c_id: String = String(member.get("id", ""))
				if TeamConfig.is_character_unlocked(c_id):
					_level_team[i] = member.duplicate(true)
		else:
			for i in range(mini(4, TeamConfig.unlocked_characters.size())):
				var c_id := TeamConfig.unlocked_characters[i]
				_level_team[i] = TeamConfig.get_saved_build(c_id)

	# Заполняем КРУПНЫЕ плитки персонажей карусели ростера
	for child in level_team_roster_container.get_children():
		level_team_roster_container.remove_child(child)
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var card := _create_level_roster_card(char_id, _add_char_to_level_slot.bind(char_id))
		if card != null:
			level_team_roster_container.add_child(card)

	level_task_label.text = "🎯 Задание: 3★ (≥10 циклов) | 2★ (≥7 циклов) | 1★ (≥4 циклов)\n🌪 Турбулентность: Небожители +30% урона, Рассвет Хаоса +20% скор."

	var intel: Dictionary = MemoryHallManager.get_floor_intel(floor_num)
	var enemies_str := ""
	var waves_arr: Array = intel.get("waves", [])
	for w_idx in range(waves_arr.size()):
		var w_dict: Dictionary = waves_arr[w_idx]
		var w_num: int = int(w_dict.get("wave", w_idx + 1))
		var w_en: Array = w_dict.get("enemies", [])
		var en_names: Array[String] = []
		for en in w_en:
			var is_el: bool = bool(en.get("is_elite", false))
			var name_str: String = String(en.get("name", "Враг"))
			if is_el:
				en_names.append("👹 [b]%s[/b]" % name_str)
			else:
				en_names.append("👾 %s" % name_str)
		enemies_str += "• [color=gold]Волна %d:[/color] %s\n" % [w_num, ", ".join(en_names)]
	level_enemies_label.text = enemies_str.strip_edges()

	var stars_earned: int = TeamConfig.memory_hall_stars.get(str(floor_num), 0)
	level_rewards_label.text = "🎁 Награда: Блеск Свечения за звёзды (Текущий результат: %d★)" % stars_earned

	_refresh_level_team_slots()
	_show_screen("level_team_setup")

func _build_memory_hall_team_setup_screen() -> void:
	if memory_hall_team_setup_screen and is_instance_valid(memory_hall_team_setup_screen):
		memory_hall_team_setup_screen.queue_free()

	memory_hall_team_setup_screen = VBoxContainer.new()
	memory_hall_team_setup_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	memory_hall_team_setup_screen.add_theme_constant_override("separation", 10)
	memory_hall_team_setup_screen.visible = false
	add_child(memory_hall_team_setup_screen)

	var title := Label.new()
	title.text = "🏛 Подготовка: Платиновый чертог (4 Этаж — Два отряда)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	memory_hall_team_setup_screen.add_child(title)

	var sub_lbl := Label.new()
	sub_lbl.text = "Лимит: 28 Циклов на обе команды (непотраченные циклы Команды 1 переходят к Команде 2). Персонажи не могут повторяться!"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95))
	memory_hall_team_setup_screen.add_child(sub_lbl)

	var toggle_hbox := HBoxContainer.new()
	toggle_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toggle_hbox.add_theme_constant_override("separation", 20)
	memory_hall_team_setup_screen.add_child(toggle_hbox)

	var btn_toggle_team1 := Button.new()
	btn_toggle_team1.name = "BtnToggleTeam1"
	btn_toggle_team1.text = "▶ Редактировать Команду 1 (Половина 1)"
	btn_toggle_team1.custom_minimum_size = Vector2(300, 36)
	btn_toggle_team1.pressed.connect(func(): _switch_mh_active_target_team(1))
	toggle_hbox.add_child(btn_toggle_team1)

	var btn_toggle_team2 := Button.new()
	btn_toggle_team2.name = "BtnToggleTeam2"
	btn_toggle_team2.text = "▷ Редактировать Команду 2 (Половина 2)"
	btn_toggle_team2.custom_minimum_size = Vector2(300, 36)
	btn_toggle_team2.pressed.connect(func(): _switch_mh_active_target_team(2))
	toggle_hbox.add_child(btn_toggle_team2)

	var scroll_roster := ScrollContainer.new()
	scroll_roster.custom_minimum_size = Vector2(0, 160)
	memory_hall_team_setup_screen.add_child(scroll_roster)

	var center_roster := CenterContainer.new()
	center_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_roster.add_child(center_roster)

	mh_roster_container = GridContainer.new()
	mh_roster_container.columns = 7
	mh_roster_container.add_theme_constant_override("h_separation", 10)
	mh_roster_container.add_theme_constant_override("v_separation", 10)
	center_roster.add_child(mh_roster_container)

	var teams_hbox := HBoxContainer.new()
	teams_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	teams_hbox.add_theme_constant_override("separation", 24)
	memory_hall_team_setup_screen.add_child(teams_hbox)

	var t1_panel := PanelContainer.new()
	t1_panel.custom_minimum_size = Vector2(560, 240)
	var t1_sb := StyleBoxFlat.new()
	t1_sb.bg_color = Color(0.08, 0.10, 0.16, 0.90)
	t1_sb.border_color = Color(0.3, 0.6, 1.0, 0.7)
	t1_sb.set_border_width_all(2)
	t1_sb.set_corner_radius_all(10)
	t1_sb.set_content_margin_all(8)
	t1_panel.add_theme_stylebox_override("panel", t1_sb)
	teams_hbox.add_child(t1_panel)

	var t1_vbox := VBoxContainer.new()
	t1_vbox.add_theme_constant_override("separation", 6)
	t1_panel.add_child(t1_vbox)

	var t1_lbl := Label.new()
	t1_lbl.text = "🔵 Команда 1 (Первая половина)"
	t1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1_lbl.add_theme_font_size_override("font_size", 15)
	t1_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	t1_vbox.add_child(t1_lbl)

	mh_team1_slots_container = HBoxContainer.new()
	mh_team1_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	mh_team1_slots_container.add_theme_constant_override("separation", 10)
	t1_vbox.add_child(mh_team1_slots_container)

	for i in 4:
		var slot_panel := _create_mh_slot_panel(1, i)
		mh_team1_slots_container.add_child(slot_panel)

	var init1_hbox := HBoxContainer.new()
	init1_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	init1_hbox.add_theme_constant_override("separation", 8)
	t1_vbox.add_child(init1_hbox)

	var init1_lbl := Label.new()
	init1_lbl.text = "Инициатор:"
	init1_lbl.add_theme_font_size_override("font_size", 13)
	init1_hbox.add_child(init1_lbl)

	mh_init_opt_1 = OptionButton.new()
	mh_init_opt_1.custom_minimum_size = Vector2(200, 30)
	init1_hbox.add_child(mh_init_opt_1)

	var t2_panel := PanelContainer.new()
	t2_panel.custom_minimum_size = Vector2(560, 240)
	var t2_sb := StyleBoxFlat.new()
	t2_sb.bg_color = Color(0.12, 0.08, 0.18, 0.90)
	t2_sb.border_color = Color(0.8, 0.4, 1.0, 0.7)
	t2_sb.set_border_width_all(2)
	t2_sb.set_corner_radius_all(10)
	t2_sb.set_content_margin_all(8)
	t2_panel.add_theme_stylebox_override("panel", t2_sb)
	teams_hbox.add_child(t2_panel)

	var t2_vbox := VBoxContainer.new()
	t2_vbox.add_theme_constant_override("separation", 6)
	t2_panel.add_child(t2_vbox)

	var t2_lbl := Label.new()
	t2_lbl.text = "🟣 Команда 2 (Вторая половина)"
	t2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2_lbl.add_theme_font_size_override("font_size", 15)
	t2_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
	t2_vbox.add_child(t2_lbl)

	mh_team2_slots_container = HBoxContainer.new()
	mh_team2_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	mh_team2_slots_container.add_theme_constant_override("separation", 10)
	t2_vbox.add_child(mh_team2_slots_container)

	for i in 4:
		var slot_panel := _create_mh_slot_panel(2, i)
		mh_team2_slots_container.add_child(slot_panel)

	var init2_hbox := HBoxContainer.new()
	init2_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	init2_hbox.add_theme_constant_override("separation", 8)
	t2_vbox.add_child(init2_hbox)

	var init2_lbl := Label.new()
	init2_lbl.text = "Инициатор:"
	init2_lbl.add_theme_font_size_override("font_size", 13)
	init2_hbox.add_child(init2_lbl)

	mh_init_opt_2 = OptionButton.new()
	mh_init_opt_2.custom_minimum_size = Vector2(200, 30)
	init2_hbox.add_child(mh_init_opt_2)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 24)
	memory_hall_team_setup_screen.add_child(btn_hbox)

	var btn_start_f4 := Button.new()
	btn_start_f4.text = "⚔ В БОЙ (4 ЭТАЖ)"
	btn_start_f4.custom_minimum_size = Vector2(240, 48)
	btn_start_f4.add_theme_font_size_override("font_size", 18)
	var start_sb := StyleBoxFlat.new()
	start_sb.bg_color = Color(0.50, 0.20, 0.75, 1.0)
	start_sb.border_color = Color(0.9, 0.7, 1.0, 1.0)
	start_sb.set_border_width_all(2)
	start_sb.set_corner_radius_all(10)
	btn_start_f4.add_theme_stylebox_override("normal", start_sb)
	btn_start_f4.pressed.connect(_start_memory_hall_floor4_battle)
	btn_hbox.add_child(btn_start_f4)

	var btn_back := Button.new()
	btn_back.text = "↩ Назад в Зал"
	btn_back.custom_minimum_size = Vector2(160, 48)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(func():
		_refresh_memory_hall_screen()
		_show_screen("memory_hall")
	)
	btn_hbox.add_child(btn_back)

func _create_mh_slot_panel(team_num: int, slot_idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(125, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.13, 0.9)
	sb.border_color = Color(0.3, 0.35, 0.5, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var slot_lbl := Label.new()
	slot_lbl.text = "Слот %d" % (slot_idx + 1)
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 12)
	slot_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vbox.add_child(slot_lbl)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Пусто"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var remove_btn := Button.new()
	remove_btn.name = "RemoveButton"
	remove_btn.text = "Убрать"
	remove_btn.custom_minimum_size = Vector2(90, 28)
	remove_btn.pressed.connect(func(): _remove_char_from_mh_team(team_num, slot_idx))
	remove_btn.visible = false
	vbox.add_child(remove_btn)

	return panel

func _open_memory_hall_two_team_setup() -> void:
	selected_memory_hall_floor = 4
	selected_dungeon_for_battle = ""
	selected_level_for_battle = 0

	_mh_team_1 = [null, null, null, null]
	_mh_team_2 = [null, null, null, null]

	if not TeamConfig.memory_hall_team_1.is_empty():
		for i in range(mini(4, TeamConfig.memory_hall_team_1.size())):
			var m = TeamConfig.memory_hall_team_1[i]
			if m != null and TeamConfig.is_character_unlocked(String(m.get("id", ""))):
				_mh_team_1[i] = m.duplicate(true)
	elif not TeamConfig.team_members.is_empty():
		for i in range(mini(4, TeamConfig.team_members.size())):
			var m = TeamConfig.team_members[i]
			if m != null and TeamConfig.is_character_unlocked(String(m.get("id", ""))):
				_mh_team_1[i] = m.duplicate(true)

	if not TeamConfig.memory_hall_team_2.is_empty():
		for i in range(mini(4, TeamConfig.memory_hall_team_2.size())):
			var m = TeamConfig.memory_hall_team_2[i]
			if m != null and TeamConfig.is_character_unlocked(String(m.get("id", ""))):
				var is_dup := false
				for s1 in _mh_team_1:
					if s1 != null and s1.get("id", "") == m.get("id", ""):
						is_dup = true
						break
				if not is_dup:
					_mh_team_2[i] = m.duplicate(true)

	for child in mh_roster_container.get_children():
		mh_roster_container.remove_child(child)
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var c_data := CharacterRegistry.get_character(char_id)
		if c_data.is_empty():
			continue

		var btn := Button.new()
		btn.name = "MhRoster_%s" % char_id
		btn.set_meta("char_id", char_id)
		btn.custom_minimum_size = Vector2(105, 90)
		btn.pressed.connect(_on_mh_roster_char_clicked.bind(char_id))

		var label := RichTextLabel.new()
		label.name = "RosterLabel"
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.bbcode_enabled = true
		btn.add_child(label)
		mh_roster_container.add_child(btn)

	_mh_active_target_team = 1
	_switch_mh_active_target_team(1)
	_refresh_mh_team_slots()
	_show_screen("memory_hall_team_setup")

func _switch_mh_active_target_team(team_num: int) -> void:
	_mh_active_target_team = team_num
	var btn1: Button = memory_hall_team_setup_screen.find_child("BtnToggleTeam1", true, false)
	var btn2: Button = memory_hall_team_setup_screen.find_child("BtnToggleTeam2", true, false)
	if btn1 and btn2:
		if team_num == 1:
			btn1.text = "▶ Редактировать Команду 1 (Половина 1)"
			btn2.text = "▷ Редактировать Команду 2 (Половина 2)"
		else:
			btn1.text = "▷ Редактировать Команду 1 (Половина 1)"
			btn2.text = "▶ Редактировать Команду 2 (Половина 2)"

func _on_mh_roster_char_clicked(char_id: String) -> void:
	if _mh_active_target_team == 1:
		for s in _mh_team_2:
			if s != null and s.get("id", "") == char_id:
				notification_label.text = "❌ Герой уже во 2-й команде! Дубликаты запрещены."
				return
		for i in 4:
			if _mh_team_1[i] != null and _mh_team_1[i].get("id", "") == char_id:
				_mh_team_1[i] = null
				_refresh_mh_team_slots()
				return
		var free_idx := -1
		for i in 4:
			if _mh_team_1[i] == null:
				free_idx = i
				break
		if free_idx != -1:
			_mh_team_1[free_idx] = TeamConfig.get_saved_build(char_id)
		else:
			notification_label.text = "Команда 1 уже заполнена (4 героя)."
	else:
		for s in _mh_team_1:
			if s != null and s.get("id", "") == char_id:
				notification_label.text = "❌ Герой уже в 1-й команде! Дубликаты запрещены."
				return
		for i in 4:
			if _mh_team_2[i] != null and _mh_team_2[i].get("id", "") == char_id:
				_mh_team_2[i] = null
				_refresh_mh_team_slots()
				return
		var free_idx := -1
		for i in 4:
			if _mh_team_2[i] == null:
				free_idx = i
				break
		if free_idx != -1:
			_mh_team_2[free_idx] = TeamConfig.get_saved_build(char_id)
		else:
			notification_label.text = "Команда 2 уже заполнена (4 героя)."

	_refresh_mh_team_slots()

func _remove_char_from_mh_team(team_num: int, slot_idx: int) -> void:
	if team_num == 1:
		_mh_team_1[slot_idx] = null
	else:
		_mh_team_2[slot_idx] = null
	_refresh_mh_team_slots()

func _refresh_mh_team_slots() -> void:
	var t1_children := mh_team1_slots_container.get_children()
	for i in mini(t1_children.size(), 4):
		var panel: PanelContainer = t1_children[i]
		var vbox: VBoxContainer = panel.get_child(0)
		var name_lbl: Label = vbox.get_node("NameLabel")
		var remove_btn: Button = vbox.get_node("RemoveButton")
		var slot_data = _mh_team_1[i]
		if slot_data == null:
			name_lbl.text = "Пусто"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			remove_btn.hide()
		else:
			var c_data := CharacterRegistry.get_character(slot_data.id)
			var elem: int = int(c_data.get("element", 0))
			name_lbl.text = "%s\n%s" % [c_data.get("name", "?"), CombatConstants.get_element_label(elem)]
			name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(elem))
			remove_btn.show()

	var t2_children := mh_team2_slots_container.get_children()
	for i in mini(t2_children.size(), 4):
		var panel: PanelContainer = t2_children[i]
		var vbox: VBoxContainer = panel.get_child(0)
		var name_lbl: Label = vbox.get_node("NameLabel")
		var remove_btn: Button = vbox.get_node("RemoveButton")
		var slot_data = _mh_team_2[i]
		if slot_data == null:
			name_lbl.text = "Пусто"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			remove_btn.hide()
		else:
			var c_data := CharacterRegistry.get_character(slot_data.id)
			var elem: int = int(c_data.get("element", 0))
			name_lbl.text = "%s\n%s" % [c_data.get("name", "?"), CombatConstants.get_element_label(elem)]
			name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(elem))
			remove_btn.show()

	var t1_ids := {}
	for s in _mh_team_1:
		if s != null: t1_ids[s.id] = true
	var t2_ids := {}
	for s in _mh_team_2:
		if s != null: t2_ids[s.id] = true

	for btn in mh_roster_container.get_children():
		var char_id: String = String(btn.get_meta("char_id", btn.name.trim_prefix("MhRoster_")))
		var c_data := CharacterRegistry.get_character(char_id)
		var label: RichTextLabel = btn.get_node_or_null("RosterLabel")
		if label and not c_data.is_empty():
			var elem_col: String = CombatConstants.get_element_color(c_data.element).to_html(false)
			var team_tag := ""
			if t1_ids.has(char_id):
				team_tag = "\n[color=#50b0ff][b][Отряд 1][/b][/color]"
			elif t2_ids.has(char_id):
				team_tag = "\n[color=#d070ff][b][Отряд 2][/b][/color]"
			label.text = "[center]\n[color=#%s][font_size=12]%s[/font_size][/color]\n[font_size=12][b]%s[/b][/font_size]%s[/center]" % [
				elem_col,
				CombatConstants.get_element_label(c_data.element),
				c_data.name,
				team_tag
			]

	mh_init_opt_1.clear()
	var idx1 := 0
	for s in _mh_team_1:
		if s != null and MemoryHallManager.has_attack_technique(s.id):
			var c_data := CharacterRegistry.get_character(s.id)
			mh_init_opt_1.add_item(c_data.get("name", s.id))
			mh_init_opt_1.set_item_metadata(idx1, s.id)
			idx1 += 1
	if idx1 == 0:
		mh_init_opt_1.add_item("Без атакующей техники")
		mh_init_opt_1.set_item_metadata(0, "")

	mh_init_opt_2.clear()
	var idx2 := 0
	for s in _mh_team_2:
		if s != null and MemoryHallManager.has_attack_technique(s.id):
			var c_data := CharacterRegistry.get_character(s.id)
			mh_init_opt_2.add_item(c_data.get("name", s.id))
			mh_init_opt_2.set_item_metadata(idx2, s.id)
			idx2 += 1
	if idx2 == 0:
		mh_init_opt_2.add_item("Без атакующей техники")
		mh_init_opt_2.set_item_metadata(0, "")

func _start_memory_hall_floor4_battle() -> void:
	if not MemoryHallManager.is_season_active():
		notification_label.text = "⛔ Сезон Зала воспоминаний завершён!"
		return

	var t1: Array[Dictionary] = []
	for i in 4:
		if _mh_team_1[i] != null:
			var d: Dictionary = _mh_team_1[i].duplicate(true)
			d["slot_idx"] = i
			t1.append(d)

	var t2: Array[Dictionary] = []
	for i in 4:
		if _mh_team_2[i] != null:
			var d: Dictionary = _mh_team_2[i].duplicate(true)
			d["slot_idx"] = i
			t2.append(d)

	if t1.is_empty():
		notification_label.text = "❌ В первой команде должен быть хотя бы 1 герой!"
		return
	if t2.is_empty():
		notification_label.text = "❌ Во второй команде должен быть хотя бы 1 герой!"
		return

	var set1 := {}
	for m in t1: set1[m.id] = true
	for m in t2:
		if set1.has(m.id):
			notification_label.text = "❌ Персонаж «%s» выбран в обеих командах!" % m.id
			return

	var init1_id: String = ""
	if mh_init_opt_1 and mh_init_opt_1.selected >= 0 and mh_init_opt_1.item_count > 0:
		var meta = mh_init_opt_1.get_item_metadata(mh_init_opt_1.selected)
		if meta != null and String(meta) != "":
			init1_id = String(meta)

	var init2_id: String = ""
	if mh_init_opt_2 and mh_init_opt_2.selected >= 0 and mh_init_opt_2.item_count > 0:
		var meta = mh_init_opt_2.get_item_metadata(mh_init_opt_2.selected)
		if meta != null and String(meta) != "":
			init2_id = String(meta)

	TeamConfig.reset()
	TeamConfig.battle_mode = "memory_hall_4"
	TeamConfig.team_members = t1
	TeamConfig.memory_hall_team_1 = t1
	TeamConfig.memory_hall_team_2 = t2
	TeamConfig.battle_initiator_id = init1_id
	TeamConfig.memory_hall_initiator_1 = init1_id
	TeamConfig.memory_hall_initiator_2 = init2_id
	TeamConfig.save_game()

	get_tree().change_scene_to_file.call_deferred("res://scenes/battle/battle.tscn")
