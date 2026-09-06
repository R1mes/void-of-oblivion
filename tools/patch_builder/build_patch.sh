#!/usr/bin/env bash
set -e

# Скрипт сборки инкрементального PCK-патча и его автоматической криптоподписи.
# Использование: ./build_patch.sh <версия_патча, например 1.4.0> [список файлов/папок для включения]

VERSION=${1:-"1.4.0"}
OUTPUT_DIR="build/patches"
PCK_NAME="patch_v${VERSION}.pck"
PCK_PATH="${OUTPUT_DIR}/${PCK_NAME}"

mkdir -p "$OUTPUT_DIR"

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -f "$GODOT_BIN" ]; then
    GODOT_BIN=$(which godot || true)
fi

if [ -z "$GODOT_BIN" ]; then
    echo "Ошибка: Godot не найден!"
    exit 1
fi

echo "=================================================="
echo "Сборка PCK-патча версии ${VERSION}..."
echo "Godot: $GODOT_BIN"
echo "Выходной файл: $PCK_PATH"
echo "=================================================="

# Экспорт пакета ресурсов
"$GODOT_BIN" --headless --export-pack "Windows Desktop" "$PCK_PATH"

CHANGELOG=${3:-"Void of Oblivion 1.3.1:\n- Адаптирован масштаб карточек в бою и оптимизирована шкала действий\n- Исправлена кликабельность верхних кнопок боя в полноэкранном режиме\n- Добавлена система регистрации и привязки аккаунта по нику и паролю\n- Исправлено отображение звёздочек и символов"}

echo "Подпись патча приватным ключом RSA-2048..."
python3 tools/patch_builder/sign_patch.py "$PCK_PATH" "$VERSION" "$CHANGELOG"

mkdir -p patches
cp "${OUTPUT_DIR}/version_manifest.json" patches/version_manifest.json
cp "$PCK_PATH" "patches/${PCK_NAME}"

echo "Готово! Файлы для выгрузки на GitHub Releases находятся в ${OUTPUT_DIR} и patches/:"
ls -lh "$OUTPUT_DIR"
