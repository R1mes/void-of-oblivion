# Задача: Подготовка проекта к работе в Antigravity

## Что сделано
- Создан файл `AGENTS.md` в корне проекта с описанием стека, команд, ограничений и правил экономии токенов.
- Создан файл `.antigravity/rules.md` для автоматического подхвата правил воркспейса агентом.
- Создана документация `docs/README.md` с описанием архитектуры модулей, локального запуска и проверки тестов.
- Создан шаблон для фиксации изменений `docs/changes/_template.md`.
- Дополнен `.gitignore` (исключены `user/` и `user_data/`).
- Проверена корректность git-репозитория и отсутствие в индексе секретов/ключей.

## Изменённые файлы
- [`AGENTS.md`](file:///Users/rimes/void-of-oblivion/AGENTS.md): инструкции для AI-агентов
- [`.antigravity/rules.md`](file:///Users/rimes/void-of-oblivion/.antigravity/rules.md): правила рабочего пространства Antigravity
- [`docs/README.md`](file:///Users/rimes/void-of-oblivion/docs/README.md): архитектура и запуск
- [`docs/changes/_template.md`](file:///Users/rimes/void-of-oblivion/docs/changes/_template.md): шаблон отчёта о задачах
- [`.gitignore`](file:///Users/rimes/void-of-oblivion/.gitignore): добавлены директории `user/`, `user_data/`

## Как проверить
- Проверить наличие созданных файлов в корне и папке `docs/`.
- Запустить автотесты: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn`

## Что осталось / TODO (для следующего чата)
1. **Баг с продвижением действия Эго**: Айзек (обычный) продвигает действие Эго на 100%, затем ульта на Эго — действие Эго улетает далеко вместо хода сразу после Айзека.
2. **Баг с Навыком Q Сёдзи в форме танца**: Сёдзи в танце жмёт Навык Q (не наносит урон), но Элизиум Марины всё равно наносит урон.
