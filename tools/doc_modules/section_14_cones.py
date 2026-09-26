# -*- coding: utf-8 -*-
import re

def get_path_name(path_expr):
    path_map = {
        "CombatConstants.Path.ERUDITION": "Эрудиция",
        "CombatConstants.Path.HUNT": "Охота",
        "CombatConstants.Path.DESTRUCTION": "Разрушение",
        "CombatConstants.Path.HARMONY": "Гармония",
        "CombatConstants.Path.ABUNDANCE": "Изобилие",
        "CombatConstants.Path.PRESERVATION": "Сохранение",
        "CombatConstants.Path.NIHILITY": "Небытие",
        "CombatConstants.Path.REMEMBRANCE": "Память",
    }
    for k, v in path_map.items():
        if k in path_expr:
            return v
    return "Универсальный"

def get_content():
    with open("scripts/data/light_cone_registry.gd", "r", encoding="utf-8") as f:
        text = f.read()

    start = text.find("LIST := [")
    end = text.find("static func")
    list_text = text[start + 9:end].strip()
    if list_text.endswith("]"):
        list_text = list_text[:-1].strip()

    depth = 0
    cur = []
    blocks = []
    for char in list_text:
        if char == '{':
            if depth == 0:
                cur = ['{']
            else:
                cur.append('{')
            depth += 1
        elif char == '}':
            depth -= 1
            cur.append('}')
            if depth == 0:
                blocks.append(''.join(cur))
                cur = []
        elif depth > 0:
            cur.append(char)

    out = []
    out.append("## 14. Световые конусы (Light Cones) — 50 видов\n\n")
    out.append("Световые конусы представляют собой оружие героев, наделяющее носителя пассивными способностями и характеристиками. Если Путь конуса совпадает с Путем персонажа, активируется его уникальный пассивный навык. Просмотр описаний и статуса экипировки доступен через модальное окно `LightConeDetailsModal` в инвентаре.\n\n")

    for idx, block in enumerate(blocks, 1):
        m_id = re.search(r'\"id\":\s*\"([^\"]+)\"', block)
        m_name = re.search(r'\"name\":\s*\"([^\"]+)\"', block)
        m_path = re.search(r'\"path\":\s*([^,\n\}]+)', block)
        m_rarity = re.search(r'\"rarity\":\s*(\d+)', block)
        m_desc = re.search(r'\"desc\":\s*\"(.*?)\"', block, re.DOTALL)

        cid = m_id.group(1) if m_id else "unknown"
        name = m_name.group(1) if m_name else "Безымянный"
        path_name = get_path_name(m_path.group(1).strip()) if m_path else "Универсальный"
        rarity = m_rarity.group(1) if m_rarity else "3"
        desc = m_desc.group(1).replace("\n", " ").strip() if m_desc else ""

        out.append(f"### {idx}. {name} (★{rarity}, {path_name}, ID: `{cid}`)\n")
        out.append(f"* **Пассивный эффект:** {desc}\n\n")

    return "".join(out)
