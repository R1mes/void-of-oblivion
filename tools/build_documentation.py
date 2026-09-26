# -*- coding: utf-8 -*-
import os
import sys

# Add doc_modules to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "doc_modules"))

import section_01_arch_and_core
import section_11_memosprite_and_factions
import section_14_cones
import section_15_characters
import section_16_enemies
import section_17_modes_and_relics
import section_20_meta_and_levels

def generate_full_documentation() -> str:
    header = """# Void of Oblivion — Документация проекта (Версия 1.7)

Пошаговая тактическая 2D RPG на движке **Godot Engine 4.6+** с боевой системой в стиле Honkai: Star Rail.

* **Движок**: Godot Engine 4.6.x (GDScript со статической типизацией, Jolt Physics 3D, рендерер `gl_compatibility` для универсальной совместимости, поддержка Mobile / Forward+).
* **Сетевой бэкенд**: Firebase REST API (Firebase Authentication, Cloud Firestore) с двусторонней синхронизацией и защитой от оффлайна.
* **Целевые платформы**: Windows Desktop, macOS, Android.
* **Система обновлений**: Zero-Trust инкрементальный загрузчик с криптографической верификацией подписанных PCK-пакетов.

---

## Содержание

1. [Архитектура проекта и игровой цикл](#1-архитектура-проекта-и-игровой-цикл)
2. [Структура каталогов](#2-структура-каталогов)
3. [Глобальное состояние, Сохранения и Реестры (TeamConfig)](#3-глобальное-состояние-сохранения-и-реестры-teamconfig)
4. [Ядро боевой системы (Combat Core)](#4-ядро-боевой-системы-combat-core)
5. [Классификация атак (Attack Categories)](#5-классификация-атак-attack-categories)
6. [Механика щитов (Shielding)](#6-механика-щитов-shielding)
7. [Механика срезов защиты (DEF Reductions)](#7-механика-срезов-защиты-def-reductions)
8. [Механика Сопротивления (RES) и Пробития (RES PEN)](#8-механика-сопротивления-res-и-пробития-res-pen)
9. [Механика Чистого урона и Казни (True Damage)](#9-механика-чистого-урона-и-казни-true-damage)
10. [Очередь Сверхспособностей и Кинематографичные Прерывания (Ultimate Queue & Cut-in)](#10-очередь-сверхспособностей-и-кинематографичные-прерывания-ultimate-queue--cut-in)
11. [Подсистема Духов Памяти (Memosprites) и Путь Памяти (Remembrance)](#11-подсистема-духов-памяти-memosprites-и-путь-памяти-remembrance)
12. [Система Синергии Фракций (Factions)](#12-система-синергии-фракций-factions)
13. [Система техник: Атака и Поддержка](#13-система-техник-атака-и-поддержка)
14. [Световые конусы (Light Cones) — 50 видов](#14-световые-конусы-light-cones--50-видов)
15. [Персонажи (Roster) — 34 героя](#15-персонажи-roster--34-героя)
16. [Противники и Боссы (Enemies & Bosses)](#16-противники-и-боссы-enemies--bosses)
17. [Игровые режимы: «Чистый вымысел» и «Зал воспоминаний» (Memory Hall)](#17-игровые-режимы-чистый-вымысел-и-зал-воспоминаний-memory-hall)
18. [Система снаряжения и реликвий (Gear & Relics)](#18-система-снаряжения-и-реликвий-gear--relics)
19. [Система пресетов снаряжения](#19-система-пресетов-снаряжения)
20. [Боевой интерфейс, Анимации и Визуал (Battle UX & VFX)](#20-боевой-интерфейс-анимации-и-визуал-battle-ux--vfx)
21. [Мета-структура: Хаб, Магазин, Инвентарь, Энциклопедия и Промокоды](#21-мета-структура-хаб-магазин-инвентарь-энциклопедия-и-промокоды)
22. [Система Гачи (Gacha Core)](#22-система-гачи-gacha-core)
23. [Сетевой слой, Синхронизация и Обновления (Network, Cloud & Updates)](#23-сетевой-слой-синхронизация-и-обновления-network-cloud--updates)
24. [Система Уровней, Кампании (1–22) и Обучения (LevelManager)](#24-система-уровней-кампании-122-и-обучения-levelmanager)
25. [Раздел усвоенного опыта разработки и предотвращения рекурсий](#25-раздел-усвоенного-опыта-разработки-и-предотвращения-рекурсий)
26. [Автоматическое тестирование (Test Suites)](#26-автоматическое-тестирование-test-suites)

---
"""
    modules = [
        section_01_arch_and_core,
        section_11_memosprite_and_factions,
        section_14_cones,
        section_15_characters,
        section_16_enemies,
        section_17_modes_and_relics,
        section_20_meta_and_levels
    ]
    
    sections = [header.strip()]
    for m in modules:
        content = m.get_content().strip()
        sections.append(content)
        
    return "\n\n---\n\n".join(sections) + "\n"

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    full_doc = generate_full_documentation()
    
    targets = [
        os.path.join(root_dir, "DOCUMENTATION.md"),
        os.path.join(root_dir, "DOCUMENTATION VERSION 1.3.md")
    ]
    
    for target in targets:
        with open(target, "w", encoding="utf-8") as f:
            f.write(full_doc)
        print(f"Successfully wrote {len(full_doc)} characters ({full_doc.count(chr(10))} lines) to {os.path.basename(target)}")

if __name__ == "__main__":
    main()
