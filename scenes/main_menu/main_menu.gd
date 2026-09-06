extends Control

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
		"E1": "В «Танце» Сверхспособность накладывает 90% уязвимости ко всем типам урона, а её урон растет на +1% за Вектор.",
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
	"detroit": "🌆 [2 ч]: Сила атаки +12%. Если СКР >= 120, сила атаки дополнительно повышается на +12% (всего +24%).",
	"lost_edge": "🔬 [2 ч]: Макс. ХП +12%. Если СКР >= 120, сила атаки всех союзников повышается на +8%.",
	"japan_island": "🗾 [2 ч]: Защита +15%. Если ШПЭ >= 50%, защита дополнительно повышается на +15%.",
	"krasnodar": "☀ [2 ч]: Крит. шанс +8%. Если КШ >= 50%, урон Сверхспособности и бонус-атак повышается на +15%.",
	"other_side_universe": "🌌 [2 ч]: Крит. шанс +12%. Если КШ >= 70%, урон базовой атаки и навыков повышается на +20%.",
	"irkutsk": "🧊 [2 ч]: Бонус-атака союзника дает стак Подвига (+5% урона FUA). При 5 стаках КУ +25%."
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
var level_team_roster_container: GridContainer
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
var menu_tut_overlay: ColorRect
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
var hub_overview_team_vbox: VBoxContainer
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
		_refresh_relic_farming_ui()
		_show_screen("relic_farming")
		if is_menu_tutorial and menu_tut_step == 2:
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

	# Правая инфо-панель (Обзор отряда и профиля)
	hub_overview_panel = PanelContainer.new()
	hub_overview_panel.custom_minimum_size = Vector2(380, 410)
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
	sb_disabled.bg_color = Color(0.06, 0.07, 0.10, 0.80)
	sb_disabled.border_color = Color(0.16, 0.18, 0.24, 0.50)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)

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

	hub_overview_team_vbox = VBoxContainer.new()
	hub_overview_team_vbox.add_theme_constant_override("separation", 8)
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
		c.queue_free()

	for slot_idx in range(4):
		var char_id: String = ""
		if slot_idx < TeamConfig.team_members.size():
			var member_data = TeamConfig.team_members[slot_idx]
			if member_data is Dictionary:
				char_id = String(member_data.get("id", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var slot_badge := Label.new()
		slot_badge.text = "[%d]" % (slot_idx + 1)
		slot_badge.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		slot_badge.add_theme_font_size_override("font_size", 14)
		row.add_child(slot_badge)

		var name_lbl := Label.new()
		if char_id != "":
			var unit := _create_dummy_unit_for_db(char_id)
			var elem_lbl: String = CombatConstants.get_element_label(unit.element) if unit else ""
			var d_name: String = unit.display_name if unit else char_id
			name_lbl.text = "%s  •  %s" % [d_name, elem_lbl]
			name_lbl.add_theme_color_override("font_color", CombatConstants.get_element_color(unit.element) if unit else Color(0.95, 0.95, 1.0))
		else:
			name_lbl.text = "[Пустой слот]"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		name_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(name_lbl)
		hub_overview_team_vbox.add_child(row)

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
	
	if screen_name == "gacha":
		active_banner_idx = 0
		if banner_select_option:
			banner_select_option.select(0)
		_refresh_gacha_ui()

	if screen_name == "hub":
		if btn_menu_relics:
			var title_lbl: Label = btn_menu_relics.get_meta("card_title_lbl", null)
			var icon_lbl: Label = btn_menu_relics.get_meta("card_icon_lbl", null)
			var sub_lbl: Label = btn_menu_relics.get_meta("card_sub_lbl", null)
			if TeamConfig.current_level_progress < 5:
				btn_menu_relics.disabled = true
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
					btn_menu_relics.disabled = false
		if hub_overview_panel:
			hub_overview_panel.visible = not is_menu_tutorial
			if not is_menu_tutorial:
				_refresh_hub_overview()
		if not TeamConfig.menu_tutorial_completed and not is_menu_tutorial:
			_lock_hub_buttons(true)
		
	_update_coins_display()
	
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
		var b_sb := db_banner_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if b_sb:
			b_sb.border_color = _get_element_color(data.element)
	
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
		
	return null

# База знаний рекомендаций для персонажей
# База знаний и рекомендаций для всех персонажей в игре
func _get_db_recommendation(char_id: String, type: String) -> String:
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
				"allies": return "• [color=gold]Жоан[/color], [color=gold]Доцева[/color], [color=gold]Джефф[/color], [color=gold]Валраморс[/color], [color=gold]Данилл[/color], [color=gold]Даша[/color], [color=gold]Мусиенко[/color]"
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
			
		_:
			match type:
				"allies": return "• [color=gray]Рекомендуемые союзники подбираются...[/color]"
				"cones": return "• [color=gray]Подходящие световые конусы подбираются...[/color]"
				"relics": return "• [color=gray]Рекомендуемый комплект реликвий подбирается...[/color]"
				"tip": return "💡 [i]Экспериментируйте с синергиями Фракций и подбором элементов под уязвимости противников![/i]"
	return "—"

# Список активных ивентовых 5★ баннеров
const BANNERS := [
	{"id": "katarina", "name": "Катарина", "title": "⚔ Катарина (5★)"},
	{"id": "dotseva_crimson_tears", "name": "Доцева • Багровые слёзы", "title": "🩸 Доцева • Багровые слёзы (5★)"},
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
	{"id": "why_did_you_remember_me", "type": "weapon", "title": "⚔ Почему ты вспомнила меня? (5★ Конус)"}
]

const POOL_4LC := ["warm_embraces", "echoes_of_the_past", "forget_past_self", "better_world", "medical_smell", "what_is_reality", "new_life_start", "moon_dance", "quarantine", "first_minutes_of_war"]

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
	desc_light_cone = _create_info_box()
	build_editor_panel.add_child(_create_form_row("Световой Конус:", opt_light_cone, desc_light_cone))

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
		_update_lc_description()
		if is_menu_tutorial and menu_tut_step == 3:
			var selected_id := String(opt_light_cone.get_item_metadata(opt_light_cone.selected))
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
		{"name": "Исследователь будущего", "id": "bereft_future", "req_level": 11}
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
		panel.custom_minimum_size = Vector2(180, 220)
		
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

		var elem_color := CombatConstants.get_element_color(char_data.element)
		var elem_badge := PanelContainer.new()
		elem_badge.custom_minimum_size = Vector2(140, 32)
		var elem_badge_sb := StyleBoxFlat.new()
		elem_badge_sb.set_corner_radius_all(6)
		elem_badge_sb.bg_color = Color(elem_color.r * 0.22, elem_color.g * 0.22, elem_color.b * 0.22, 0.88)
		elem_badge_sb.border_color = elem_color
		elem_badge_sb.set_border_width_all(2)
		elem_badge.add_theme_stylebox_override("panel", elem_badge_sb)

		var desc_lbl := Label.new()
		desc_lbl.text = CombatConstants.get_element_full_label(char_data.element)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", elem_color)
		elem_badge.add_child(desc_lbl)
		vbox.add_child(elem_badge)

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
		var is_unlocked: bool = (cone.rarity == 3) or (cone.id in TeamConfig.unlocked_light_cones)
		if not is_unlocked:
			continue

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(130, 150)
		
		panel.tooltip_text = "⚔ %s (%d★)\n\n%s" % [
			cone.get("name", "Конус"),
			cone.get("rarity", 3),
			cone.get("desc", "Описание отсутствует.")
		]

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)

		var icon := Label.new()
		icon.text = "⚔"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 28)
		vbox.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = "%s\n(%d★)" % [cone.name, cone.rarity]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(name_lbl)

		inv_cones_grid.add_child(panel)
		
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
		TeamConfig.reset_all_progress()
		_update_coins_display()
		_build_levels_screen() # Перерисовываем карту (кнопка пропуска снова вернется!)
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
			
			var sb := StyleBoxFlat.new()
			sb.corner_radius_top_left = 30
			sb.corner_radius_top_right = 30
			sb.corner_radius_bottom_left = 30
			sb.corner_radius_bottom_right = 30
			sb.bg_color = Color(0.2, 0.4, 0.8) if level_num <= TeamConfig.current_level_progress else Color(0.25, 0.25, 0.3)
			
			btn.add_theme_stylebox_override("normal", sb)
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
				TeamConfig.get_saved_build("vika"),
				TeamConfig.get_saved_build("danill"),
				TeamConfig.get_saved_build("kaori")
			]
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
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 520)
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
	banner_panel.custom_minimum_size = Vector2(750, 360)
	
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
	btn_pull_1.text = "1 раз (1 ✨)"
	btn_pull_1.custom_minimum_size = Vector2(200, 50)
	btn_pull_1.add_theme_font_size_override("font_size", 18)
	btn_pull_1.pressed.connect(func(): _execute_gacha_pulls(1))
	btn_hbox.add_child(btn_pull_1)

	var btn_pull_10 := Button.new()
	btn_pull_10.text = "10 раз (10 ✨)"
	btn_pull_10.custom_minimum_size = Vector2(200, 50)
	btn_pull_10.add_theme_font_size_override("font_size", 18)
	btn_pull_10.pressed.connect(func(): _execute_gacha_pulls(10))
	btn_hbox.add_child(btn_pull_10)

	var btn_back := Button.new()
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

			if not target_lc_id in TeamConfig.unlocked_light_cones:
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
					if not dropped_lc_id in TeamConfig.unlocked_light_cones:
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
			if not lc_id in TeamConfig.unlocked_light_cones:
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
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(520, 440)
	card_panel.pivot_offset = Vector2(260, 220)
	center.add_child(card_panel)

	var rarity_color := Color(1.0, 0.85, 0.2) if data.rarity >= 5 else (Color(0.75, 0.45, 1.0) if data.rarity == 4 else Color(0.3, 0.7, 1.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(24)
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
	stars_lbl.add_theme_font_size_override("font_size", 28)
	stars_lbl.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(stars_lbl)

	var elem_symbol := Label.new()
	elem_symbol.text = "%s  %s" % [CombatConstants.ELEMENT_SYMBOLS[data.element], CombatConstants.get_element_name(data.element)]
	elem_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_symbol.add_theme_font_size_override("font_size", 28)
	elem_symbol.add_theme_color_override("font_color", CombatConstants.get_element_color(data.element))
	vbox.add_child(elem_symbol)

	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 34)
	vbox.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.text = "Путь: %s" % CharacterRegistry.get_path_name(data.path)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 16)
	info_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(info_lbl)

	var btn_cont := Button.new()
	btn_cont.text = "Далее ➔" if not step_txt.is_empty() else "Продолжить"
	btn_cont.custom_minimum_size = Vector2(220, 50)
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
		var card_flash := ColorRect.new()
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
		var card_flash := ColorRect.new()
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

# --- СИСТЕМА ОБУЧЕНИЯ В МЕНЮ (ПОСЛЕ 5 УРОВНЯ) ---

func _init_menu_tutorial_ui() -> void:
	menu_tut_overlay = ColorRect.new()
	menu_tut_overlay.color = Color(0, 0, 0, 0.25)
	menu_tut_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_tut_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_tut_overlay)

	menu_tut_panel = PanelContainer.new()
	menu_tut_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	menu_tut_panel.custom_minimum_size = Vector2(400, 260)
	menu_tut_panel.offset_left = -430
	menu_tut_panel.offset_right = -30
	menu_tut_panel.offset_top = -130
	menu_tut_panel.offset_bottom = 130
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	sb.border_color = Color(0.9, 0.75, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(14)
	menu_tut_panel.add_theme_stylebox_override("panel", sb)
	menu_tut_overlay.add_child(menu_tut_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	menu_tut_panel.add_child(vbox)

	menu_tut_label = RichTextLabel.new()
	menu_tut_label.custom_minimum_size = Vector2(0, 160)
	menu_tut_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_tut_label.bbcode_enabled = true
	menu_tut_label.add_theme_font_size_override("normal_font_size", 15)
	vbox.add_child(menu_tut_label)

	menu_tut_btn = Button.new()
	menu_tut_btn.text = "Далее ➔"
	menu_tut_btn.custom_minimum_size = Vector2(180, 44)
	menu_tut_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.15, 0.55, 0.95, 1.0)
	btn_sb.set_corner_radius_all(8)
	menu_tut_btn.add_theme_stylebox_override("normal", btn_sb)
	menu_tut_btn.add_theme_font_size_override("font_size", 16)
	menu_tut_btn.pressed.connect(_on_menu_tut_next_pressed)
	vbox.add_child(menu_tut_btn)

	menu_tut_pointer = Label.new()
	menu_tut_pointer.text = "⬇"
	menu_tut_pointer.add_theme_font_size_override("font_size", 54)
	menu_tut_pointer.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	menu_tut_pointer.add_theme_color_override("font_outline_color", Color.BLACK)
	menu_tut_pointer.add_theme_constant_override("outline_size", 8)
	menu_tut_pointer.z_index = 100
	menu_tut_pointer.visible = false
	add_child(menu_tut_pointer)

func _set_menu_tut_panel_pos(pos: String = "right") -> void:
	if not menu_tut_panel or not is_instance_valid(menu_tut_panel):
		return
	if pos == "left":
		menu_tut_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		menu_tut_panel.offset_left = 30
		menu_tut_panel.offset_right = 430
		menu_tut_panel.offset_bottom = -30
		menu_tut_panel.offset_top = -270
	else:
		menu_tut_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		menu_tut_panel.offset_left = -430
		menu_tut_panel.offset_right = -30
		menu_tut_panel.offset_top = -130
		menu_tut_panel.offset_bottom = 130

func _run_menu_tut_step(step: int) -> void:
	menu_tut_step = step
	menu_tut_btn.visible = false
	menu_tut_pointer.visible = false
	_lock_hub_buttons(true)
	if hub_overview_panel:
		hub_overview_panel.visible = false

	if step in [3, 4, 5, 6, 7, 8, 102]:
		_set_menu_tut_panel_pos("left")
	else:
		_set_menu_tut_panel_pos("right")

	match step:
		1:
			_set_menu_tut_text("Поздравляю с победой на 4 уровне!\n\n[b]Теперь выйди в главное меню![/b]")
			if btn_levels_back:
				btn_levels_back.disabled = false
				_show_menu_pointer(btn_levels_back.global_position + Vector2(100, -50))
		2:
			_set_menu_tut_text("Тебе открылась [b]🏺 Добыча реликвий[/b]!\n\nРеликвии дают огромную прибавку к характеристикам персонажей. Сначала отправимся в подземелье и добудем твой первый комплект для Вики!\n\nЗаходи в [b]«Добыча реликвий»[/b].")
			btn_menu_relics.disabled = false
			_show_menu_pointer_for_control(btn_menu_relics)
		201:
			_set_menu_tut_text("Это пещера коррозии [b]«Академия»[/b]. Здесь добывается квантовый сет [b]«Истинный родоначальник хаоса»[/b], идеально подходящий для Вики!\n\nНажми [b]«⚡ Быстрая зачистка»[/b] (или «В бой»), чтобы получить первые реликвии!")
			if tut_academy_instant_btn and is_instance_valid(tut_academy_instant_btn):
				tut_academy_instant_btn.disabled = false
				_show_menu_pointer(tut_academy_instant_btn.global_position + Vector2(100, -45))
		202:
			_set_menu_tut_text("Отлично! Ты получил реликвии Хаоса и материал для прокачки!\n\nВозвращайся назад в меню.")
			if btn_farming_back and is_instance_valid(btn_farming_back):
				btn_farming_back.disabled = false
				_show_menu_pointer(btn_farming_back.global_position + Vector2(100, -50))
		203:
			_set_menu_tut_text("Теперь зайдём в меню [b]«👤 Персонажи»[/b], чтобы настроить и экипировать полученные реликвии!")
			btn_menu_chars.disabled = false
			_show_menu_pointer_for_control(btn_menu_chars)
		3:
			_set_menu_tut_text("Сейчас у тебя имеются 3 бесплатных персонажа. Давай настроим Вику!\n\nСначала выбери световой конус [b]«Апокалипсис»[/b] — он увеличивает урон её навыков.")
			_select_char_for_build("vika")
			if opt_light_cone:
				opt_light_cone.disabled = false
				_show_menu_pointer(opt_light_cone.global_position + Vector2(80, -45))
		4:
			_set_menu_tut_text("Теперь наденем реликвии! Реликвии пещер занимают 4 верхних слота (Голова, Руки, Тело, Ноги), а планарные — 2 нижних.\n\nНажми [b]«+ Надеть»[/b] на слоте [b]👑 Голова[/b] и выбери 4★ реликвию Хаоса!")
			if tut_slot_btn_head and is_instance_valid(tut_slot_btn_head):
				tut_slot_btn_head.disabled = false
				_show_menu_pointer(tut_slot_btn_head.global_position + Vector2(80, -45))
		5:
			_set_menu_tut_text("Отлично! Теперь нажми [b]«+ Надеть»[/b] на слоте [b]🧤 Руки[/b] и выбери вторую 4★ реликвию Хаоса.")
			if tut_slot_btn_hands and is_instance_valid(tut_slot_btn_hands):
				tut_slot_btn_hands.disabled = false
				_show_menu_pointer(tut_slot_btn_hands.global_position + Vector2(80, -45))
		6:
			if TeamConfig.relic_shards < 30:
				TeamConfig.add_relic_shards(30)
			_set_menu_tut_text("Посмотри на панель справа: активировался [b]Бонус 2 частей сета Хаоса (+10% Квантового урона)[/b]!\n\nА теперь улучшим Голову. Нажми [b]«⚡ Прокачать»[/b] на слоте Головы!")
			if tut_slot_btn_upgrade_head and is_instance_valid(tut_slot_btn_upgrade_head):
				tut_slot_btn_upgrade_head.disabled = false
				_show_menu_pointer(tut_slot_btn_upgrade_head.global_position + Vector2(60, -45))
		7:
			if TeamConfig.relic_shards < 30:
				TeamConfig.add_relic_shards(30)
			_set_menu_tut_text("В окне прокачки можно скармливать ненужные реликвии или 🔮 Осколки (1 шт. = 100 XP).\n\nНажми [b]«✨ Авто»[/b] (или выбери корм справа), а затем нажми [b]«⚡ Улучшить»[/b]!")
			if _upgrade_btn_apply and is_instance_valid(_upgrade_btn_apply):
				_upgrade_btn_apply.disabled = false
			if _upgrade_btn_auto_shards and is_instance_valid(_upgrade_btn_auto_shards):
				_upgrade_btn_auto_shards.disabled = false
				_show_menu_pointer(_upgrade_btn_auto_shards.global_position + Vector2(40, -45))
			elif _upgrade_btn_apply and is_instance_valid(_upgrade_btn_apply):
				_show_menu_pointer(_upgrade_btn_apply.global_position + Vector2(100, -45))
		8:
			_set_menu_tut_text("Поздравляю с первой прокачкой реликвии! Запомни: не забывай сохранять сборку.\n\nНажми [b]«💾 Сохранить сборку персонажа»[/b]!")
			if btn_save_char_build and is_instance_valid(btn_save_char_build):
				btn_save_char_build.disabled = false
				_show_menu_pointer(btn_save_char_build.global_position + Vector2(80, -45))
		102: # Шаг выхода обратно в меню после сохранения
			_set_menu_tut_text("Сборка сохранена! Теперь выходи обратно в главное меню.")
			if btn_char_back and is_instance_valid(btn_char_back):
				btn_char_back.disabled = false
				_show_menu_pointer(btn_char_back.global_position + Vector2(80, -45))
		9:
			_set_menu_tut_text("Следующее — [b]База данных[/b]. Заходи!")
			btn_menu_db.disabled = false
			_show_menu_pointer_for_control(btn_menu_db)
		10:
			_set_menu_tut_text("Здесь ты можешь почитать всё обо всех персонажах, посмотреть советы по сборкам и союзникам. Однако, никогда не бойся выходить за рамки — вдруг ты откроешь новую мету? Когда дочитаешь — выходи в меню.")
			if btn_db_back:
				btn_db_back.disabled = false
				_show_menu_pointer(btn_db_back.global_position + Vector2(100, -50))
		11:
			_set_menu_tut_text("Далее — [b]Инвентарь[/b]! Заходи!")
			btn_menu_inv.disabled = false
			_show_menu_pointer_for_control(btn_menu_inv)
		12:
			_set_menu_tut_text("Здесь можно посмотреть, какие у тебя есть персонажи и какие Эйдолоны, а также почитать, что эти Эйдолоны делают и какие баффы дают.\n\nТеперь перейди на вкладку [b]«🛡 Реликвии»[/b]!")
			if btn_tab_relics and is_instance_valid(btn_tab_relics):
				btn_tab_relics.disabled = false
				_show_menu_pointer(btn_tab_relics.global_position + Vector2(60, -45))
		13:
			_set_menu_tut_text("Лишние или слабые реликвии можно уничтожать (разбирать) на Осколки!\n\nНажми [b]«🗑 Разобрать»[/b] на любой 3★ реликвии, чтобы превратить её в Осколки для прокачки!")
			if btn_tab_relics and is_instance_valid(btn_tab_relics):
				btn_tab_relics.disabled = false
			if inv_characters_grid and inv_relics_container:
				inv_characters_grid.visible = false
				inv_cones_grid.visible = false
				inv_relics_container.visible = true
				_refresh_inventory_relics()
			if tut_dismantle_btn and is_instance_valid(tut_dismantle_btn):
				tut_dismantle_btn.disabled = false
				_show_menu_pointer(tut_dismantle_btn.global_position + Vector2(80, -45))
		14:
			_set_menu_tut_text("Отлично! Реликвия разобрана на Осколки. Теперь у тебя есть универсальный ресурс для улучшения экипировки!\n\nВозвращайся в меню.")
			if btn_inv_back and is_instance_valid(btn_inv_back):
				btn_inv_back.disabled = false
				_show_menu_pointer(btn_inv_back.global_position + Vector2(100, -50))
		15:
			TeamConfig.coins = max(TeamConfig.coins, 500)
			_update_coins_display()
			_set_menu_tut_text("Далее — [b]Магазин[/b]!")
			btn_menu_shop.disabled = false
			_show_menu_pointer_for_control(btn_menu_shop)
		16:
			_set_menu_tut_text("Здесь ты можешь купить любого персонажа, который тебе нравится (если у тебя, конечно, есть на него деньги). Стандартные 5* персонажи стоят 1850, а 4* — 480 монет. Если ты покупаешь персонажа, который у тебя есть, то ты получаешь на него +1 Эйдолон. Сейчас купи [b]Арсения[/b] — он отлично подойдёт к Вике и Каори в команду!")
			_lock_shop_except_arseniy()
		17:
			_set_menu_tut_text("Отлично! Арсений — персонаж Гармонии. Он бафает других персонажей в отряде. Теперь выходи и перейдём К ГАЧЕ...")
			if btn_shop_back:
				btn_shop_back.disabled = false
				_show_menu_pointer(btn_shop_back.global_position + Vector2(100, -50))
		18:
			_set_menu_tut_text("Жми на [b]Гачу[/b]!")
			btn_menu_gacha.disabled = false
			_show_menu_pointer_for_control(btn_menu_gacha)
		19:
			TeamConfig.shine += 1
			_update_coins_display()
			_set_menu_tut_text("Это гача! Здесь ты можешь получить Лимитированных 5* персонажей, которых нельзя получить никаким другим способом. Сверху ты можешь выбрать баннер персонажа, которого хочешь покрутить. Перед тем, как кого-то крутить, рекомендую почитать, что этот персонаж делает. Сейчас я дам тебе один Блеск Свечения — это валюта, за которую можно крутить Баннеры. 1 Блеск Свечения = 1 крутка. Давай посмотрим, что тебе выпадет!")
			_lock_gacha_except_one_pull()
		20:
			_set_menu_tut_text("Отлично! Тебе выпала [b]Сара[/b]. Сара — хиллер. Она может лечить союзников. Более того — она может блокировать смерть и оставлять союзников живыми на 1 ед. ХП. Она точно будет тебе полезна!\n\nКогда ты пройдёшь 5 уровень, то бесплатно получишь сразу [b]10 Блесков Свечения[/b] и сможешь погрузиться в гачу на полную катушку! Так что быстрее — я жду тебя на пятом уровне!")
			menu_tut_btn.text = "Вперед! ⚔"
			menu_tut_btn.visible = true
			
func _on_menu_tut_next_pressed() -> void:
	match menu_tut_step:
		20:
			is_menu_tutorial = false
			TeamConfig.menu_tutorial_completed = true
			TeamConfig.save_game()
			menu_tut_overlay.queue_free()
			menu_tut_pointer.queue_free()
			_lock_hub_buttons(false)
			if hub_overview_panel:
				hub_overview_panel.visible = true
				_refresh_hub_overview()

func _set_menu_tut_text(txt: String) -> void:
	menu_tut_label.text = txt

func _set_text_or_tut(txt: String) -> void:
	menu_tut_label.text = txt

func _show_menu_pointer(pos: Vector2) -> void:
	menu_tut_pointer.global_position = pos
	menu_tut_pointer.visible = true

func _show_menu_pointer_for_control(ctrl: Control) -> void:
	if not ctrl or not is_instance_valid(ctrl):
		return
	var w: float = ctrl.size.x if ctrl.size.x > 10.0 else ctrl.custom_minimum_size.x
	var px: float = ctrl.global_position.x + (w - 36.0) * 0.5
	var py: float = ctrl.global_position.y - 65.0
	_show_menu_pointer(Vector2(px, py))

func _lock_hub_buttons(locked: bool) -> void:
	if btn_menu_chars: btn_menu_chars.disabled = locked
	if btn_menu_relics:
		btn_menu_relics.disabled = locked or (TeamConfig.current_level_progress < 5)
	if btn_menu_db: btn_menu_db.disabled = locked
	if btn_menu_inv: btn_menu_inv.disabled = locked
	if btn_menu_shop: btn_menu_shop.disabled = locked
	if btn_menu_gacha: btn_menu_gacha.disabled = locked

func _lock_shop_except_arseniy() -> void:
	for child in shop_grid.get_children():
		var btn: Button = child.find_child("Button", true, false)
		if btn:
			btn.disabled = true
			if "arseniy" in child.name or "Арсений" in child.to_string():
				btn.disabled = false
				_show_menu_pointer(btn.global_position + Vector2(40, -40))

func _lock_gacha_except_one_pull() -> void:
	var btn_1: Button = gacha_screen.find_child("Button", true, false)
	if btn_1:
		_show_menu_pointer(btn_1.global_position + Vector2(40, -40))

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

	# Расширенная область под крупные плитки ростера
	var scroll_roster := ScrollContainer.new()
	scroll_roster.custom_minimum_size = Vector2(0, 240)
	level_team_setup_screen.add_child(scroll_roster)

	var center_roster := CenterContainer.new()
	center_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_roster.add_child(center_roster)

	level_team_roster_container = GridContainer.new()
	level_team_roster_container.columns = 7
	level_team_roster_container.add_theme_constant_override("h_separation", 12)
	level_team_roster_container.add_theme_constant_override("v_separation", 12)
	center_roster.add_child(level_team_roster_container)

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
		if not selected_dungeon_for_battle.is_empty():
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
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.16)
	sb.border_color = Color(0.4, 0.5, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
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

	# Заполняем КРУПНЫЕ плитки персонажей (как в Админ-панели!)
	for child in level_team_roster_container.get_children():
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var c_data := CharacterRegistry.get_character(char_id)
		if c_data.is_empty():
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(115, 105) # Крупная плитка!
		btn.pressed.connect(_add_char_to_level_slot.bind(char_id))

		var label := RichTextLabel.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.bbcode_enabled = true
		var elem_color_hex: String = CombatConstants.get_element_color(c_data.element).to_html(false)
		var elem_label: String = CombatConstants.get_element_label(c_data.element)
		label.text = "[center]\n[color=#%s][font_size=15][b]%s[/b][/font_size][/color]\n[font_size=13][b]%s[/b][/font_size]\n[color=gray][font_size=11][%s][/font_size][/color][/center]" % [
			elem_color_hex,
			elem_label,
			c_data.name,
			CharacterRegistry.get_path_name(c_data.path)
		]
		btn.add_child(label)
		level_team_roster_container.add_child(btn)
	
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
		var vbox: VBoxContainer = panel.get_child(0)
		var name_lbl: Label = vbox.get_node("NameLabel")
		var remove_btn: Button = vbox.get_node("RemoveButton")
		var slot_data = _level_team[i]

		if slot_data == null:
			name_lbl.text = "Пусто"
			remove_btn.hide()
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
		if slot != null:
			if slot.id in ["pusenkov", "kaori", "shoji", "dasha", "vika", "rimes", "musienko", "joan", "joan_spirit", "isaac_admin", "shoji_swan"]:
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
	if not selected_dungeon_for_battle.is_empty():
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
		TeamConfig.battle_initiator_id = team[0].id

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
			if is_menu_tutorial and menu_tut_step == 201 and (d.id == "dungeon_academy" or d.id == "academy"):
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

	# Заполняем КРУПНЫЕ плитки персонажей ростера
	for child in level_team_roster_container.get_children():
		child.queue_free()

	for char_id in TeamConfig.unlocked_characters:
		var c_data := CharacterRegistry.get_character(char_id)
		if c_data.is_empty():
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(115, 105)
		btn.pressed.connect(_add_char_to_level_slot.bind(char_id))

		var label := RichTextLabel.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.bbcode_enabled = true
		var elem_color_hex: String = CombatConstants.get_element_color(c_data.element).to_html(false)
		var elem_label: String = CombatConstants.get_element_label(c_data.element)
		label.text = "[center]\n[color=#%s][font_size=15][b]%s[/b][/font_size][/color]\n[font_size=13][b]%s[/b][/font_size]\n[color=gray][font_size=11][%s][/font_size][/color][/center]" % [
			elem_color_hex,
			elem_label,
			c_data.name,
			CharacterRegistry.get_path_name(c_data.path)
		]
		btn.add_child(label)
		level_team_roster_container.add_child(btn)

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

	if is_menu_tutorial and menu_tut_step == 6:
		_run_menu_tut_step(7)

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
			_show_menu_pointer(_upgrade_btn_apply.global_position + Vector2(100, -45))

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
			count += 1

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
		_show_update_available_dialog(update_info)

func _on_check_updates_pressed() -> void:
	if not has_node("/root/PatchManager"):
		_show_info_dialog("Система обновлений", "Модуль обновления не инициализирован.")
		return

	var pm = get_node("/root/PatchManager")
	notification_label.text = "🔍 Проверка наличия обновлений..."
	pm.update_check_finished.connect(func(has_up: bool, info: Dictionary):
		if not has_up:
			notification_label.text = "✓ У вас установлена самая последняя версия!"
			_show_info_dialog("Обновления", "У вас установлена последняя версия игры: v%s" % pm.CURRENT_VERSION)
	, CONNECT_ONE_SHOT)
	pm.check_for_updates()

func _show_update_available_dialog(update_info: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(550, 360)
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
	btn_later.pressed.connect(func(): overlay.queue_free())
	btn_box.add_child(btn_later)

	btn_install.pressed.connect(func():
		btn_install.disabled = true
		status_lbl.text = "⏳ Загрузка и проверка цифровой подписи..."
		var pm = get_node("/root/PatchManager")
		pm.download_and_install_patch(update_info)
	)

func _on_patch_installed(version: String) -> void:
	_show_info_dialog("Обновление установлено", "Патч v%s успешно проверен и смонтирован в игру без перезапуска!" % version)

func _on_patch_failed(err_msg: String) -> void:
	_show_info_dialog("Ошибка обновления", "Безопасность: " + err_msg)

func _show_promo_code_dialog() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 280)
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
	btn_cancel.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(btn_cancel)

	btn_redeem.pressed.connect(func():
		var code := line_edit.text.strip_edges()
		if code.is_empty():
			result_lbl.text = "❌ Введите код!"
			result_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			return

		var promo_mgr = null
		if has_node("/root/NetworkManager"):
			var nm = get_node("/root/NetworkManager")
			if nm:
				promo_mgr = nm.promo

		if promo_mgr == null:
			result_lbl.text = "❌ Сетевой менеджер недоступен."
			return

		btn_redeem.disabled = true
		result_lbl.text = "⏳ Проверка кода..."
		result_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

		promo_mgr.promo_redeemed.connect(func(c: String, rewards: Dictionary):
			btn_redeem.disabled = false
			result_lbl.text = "🎉 Успешно! Получено: %s" % JSON.stringify(rewards)
			result_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			_update_coins_display()
		, CONNECT_ONE_SHOT)

		promo_mgr.promo_failed.connect(func(c: String, reason: String):
			btn_redeem.disabled = false
			result_lbl.text = "❌ " + reason
			result_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		, CONNECT_ONE_SHOT)

		promo_mgr.redeem_promo_code(code)
	)

func _show_info_dialog(title_txt: String, msg_txt: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 200)
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
	btn_ok.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(btn_ok)
