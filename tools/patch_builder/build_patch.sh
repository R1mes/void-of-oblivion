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
"$GODOT_BIN" --headless --export-pack "Web" "$PCK_PATH"

echo "Подпись патча приватным ключом RSA-2048..."
python3 tools/patch_builder/sign_patch.py "$PCK_PATH" "$VERSION" "Автоматическое обновление контента ${VERSION}"

echo "Готово! Файлы для выгрузки на GitHub Releases находятся в ${OUTPUT_DIR}:"
ls -lh "$OUTPUT_DIR"
