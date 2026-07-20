#!/usr/bin/env python3
"""Scan all card data files + hero data + card_image_service to build:
1. assets/inventory.json — complete asset inventory
2. tool/prompts_{style}.json — per-card prompts for each style
3. Prints summary counts"""

import re, json, os, sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
LIB = BASE / "lib"
DATA_CARDS = LIB / "data/cards"
HERO_FILE = LIB / "data/heroes/heroes_data.dart"
IMG_SVC = LIB / "data/card_image_service.dart"
OUT_DIR = BASE / "tool"

# ── 1. Parse card data files ──
CARD_PAT = re.compile(
    r"Card\(id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*type:\s*CardType\.(\w+)"
    r"(?:,\s*cost:\s*(\d+))?"
    r"(?:,\s*attack:\s*(\d+))?"
    r"(?:,\s*health:\s*(\d+))?"
    r"[^}]*?owner:\s*CardOwner\.(\w+)"
    r"[^}]*?rarity:\s*Rarity\.(\w+)"
)

cards = {}  # id -> {name, type, cost, attack, health, owner, rarity}
for f in sorted(DATA_CARDS.glob("*.dart")):
    if f.name == "cards.dart": continue
    text = f.read_text(encoding="utf-8")
    for m in CARD_PAT.finditer(text):
        cid = m.group(1)
        cards[cid] = {
            "name": m.group(2),
            "type": m.group(3),
            "cost": int(m.group(4)) if m.group(4) else 0,
            "attack": int(m.group(5)) if m.group(5) else 0,
            "health": int(m.group(6)) if m.group(6) else 0,
            "owner": m.group(7),
            "rarity": m.group(8),
        }

# ── 2. Parse heroes ──
HERO_PAT = re.compile(
    r"Hero\(id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*className:\s*'([^']+)',"
)
heroes = {}
text = HERO_FILE.read_text(encoding="utf-8")
for m in HERO_PAT.finditer(text):
    hid = m.group(1)
    heroes[hid] = {"name": m.group(2), "className": m.group(3)}

# ── 3. Read card_image_service to get existing file names ──
svc_text = IMG_SVC.read_text(encoding="utf-8")

def parse_map(map_name):
    """Parse a Dart const Map from the service file."""
    pat = re.compile(
        rf"{map_name}\s*=\s*\{{(.*?)\}};",
        re.DOTALL
    )
    m = pat.search(svc_text)
    if not m:
        return {}
    entries = {}
    for line in m.group(1).split("\n"):
        line = line.strip()
        if ":" not in line:
            continue
        # skip comments
        if line.startswith("//"):
            continue
        parts = line.split(":", 1)
        key = parts[0].strip().strip("'\"")
        # get filename after last /
        val = parts[1].strip().rstrip(",").strip("'\"")
        entries[key] = val
    return entries

minion_map = parse_map("_minionImageMap")
spell_map = parse_map("_spellImageMap")
weapon_map = parse_map("_weaponImageMap")

# ── 4. Build unified image mapping ──
# Expected dirs: minions/, spells/, weapons/ per style
# Each entry: {file_path (relative to style dir), card_id}

style_map = {}  # card_id -> {minions: file, spells: file, weapons: file}
for cid in cards:
    entry = {}
    if cid in minion_map:
        entry["minions"] = minion_map[cid]
    if cid in spell_map:
        entry["spells"] = spell_map[cid]
    if cid in weapon_map:
        entry["weapons"] = weapon_map[cid]
    style_map[cid] = entry

# ── 5. Generate inventory ──
inventory = {
    "cards": {cid: {**cards[cid], "image": style_map.get(cid, {})} for cid in sorted(cards)},
    "heroes": dict(sorted(heroes.items())),
}

# ── 6. Generate per-card prompts for 3 styles ──

STYLES = {
    "chibi_cute": {
        "name": "Q版水墨战国",
        "prompt_prefix": "cute chibi ink-wash painting style, Warring States period China, watercolor texture, soft colors, adorable character design, clean lines, vibrant but tasteful, 2D illustration",
        "negative": "realistic, 3D, dark, scary, violence, gore, modern, futuristic, photorealistic, oil painting",
    },
    "fantasy_rpg": {
        "name": "写实史诗战国",
        "prompt_prefix": "epic realistic fantasy style, Warring States period China, cinematic lighting, detailed armor and weapons, dramatic composition, rich colors, highly detailed, professional illustration",
        "negative": "chibi, cartoon, anime, low quality, blurry, sketch, watercolor, simple, modern",
    },
    "euro_fantasy": {
        "name": "欧美奇幻战国",
        "prompt_prefix": "western fantasy illustration style, Dungeons and Dragons aesthetic, Warring States China reimagined, dramatic shading, rich texture, heroic pose, mythical atmosphere, vibrant color palette",
        "negative": "chibi, anime, realistic photo, modern, sci-fi, simple, watercolor, ink wash",
    },
}

def make_card_prompt(card, style):
    """Generate a prompt for a single card in given style."""
    name = card["name"]
    ctype = card["type"]
    owner = card["owner"]
    rarity = card["rarity"]
    flavor_words = {
        "legendary": ", legendary figure, epic presence, glowing aura",
        "epic": ", epic scene, impressive, magnificent",
        "rare": ", striking, detailed",
        "common": "",
    }.get(rarity, "")
    
    type_desc = {
        "minion": "character portrait",
        "spell": "action scene, spell effect, dynamic composition",
        "weapon": "weapon showcase, item focus, detailed equipment",
    }.get(ctype, "scene")
    
    school_hint = {
        "bingjia": ", military commander theme, armor and weapons",
        "fajia": ", legal scholar theme, scrolls and laws, solemn atmosphere",
        "rujia": ", Confucian scholar theme, elegant robes, classical Chinese",
        "daojia": ", Daoist theme, mystical, natural elements",
        "mojia": ", Mohist engineer theme, mechanical devices, gears",
        "yinyangjia": ", Yin-Yang theme, cosmic elements, stars and divination",
        "zonghengjia": ", diplomat theme, strategic, sophisticated",
        "neutral": ", commoner theme, everyday life of Warring States",
    }.get(owner, "")
    
    return f"{style['prompt_prefix']}{school_hint}{flavor_words}, {name}, {type_desc}"

def make_hero_prompt(hero, style):
    return f"{style['prompt_prefix']}, character portrait of {hero['name']}, {hero['className']} philosopher-general, full body portrait, majestic pose, {style['name'].split()[-1]} style"

# Build prompts
prompts = {}
for sk, sv in STYLES.items():
    prompts[sk] = {
        "style": sv["name"],
        "negative_prompt": sv["negative"],
        "cards": {},
        "heroes": {},
    }
    for cid, card in cards.items():
        prompts[sk]["cards"][cid] = {
            "name": card["name"],
            "type": card["type"],
            "prompt": make_card_prompt(card, sv),
        }
    for hid, hero in heroes.items():
        prompts[sk]["heroes"][hid] = {
            "name": hero["name"],
            "prompt": make_hero_prompt(hero, sv),
        }

# ── 7. Compute stats ──
total_cards = len(cards)
total_heroes = len(heroes)

by_type = {}
for c in cards.values():
    by_type[c["type"]] = by_type.get(c["type"], 0) + 1

by_owner = {}
for c in cards.values():
    by_owner[c["owner"]] = by_owner.get(c["owner"], 0) + 1

mapped_minions = sum(1 for cid in cards if cards[cid]["type"] == "minion" and cid in minion_map)
mapped_spells = sum(1 for cid in cards if cards[cid]["type"] == "spell" and cid in spell_map)
mapped_weapons = sum(1 for cid in cards if cards[cid]["type"] == "weapon" and cid in weapon_map)

card_reuse_count = 0
for cid in cards:
    if cards[cid]["type"] == "minion" and cid not in minion_map:
        card_reuse_count += 1
for cid in cards:
    if cards[cid]["type"] == "spell" and cid not in spell_map:
        # also check if it shares image with another spell
        pass

# ── 8. Write outputs ──
os.makedirs(OUT_DIR, exist_ok=True)

inv_path = OUT_DIR / "inventory.json"
inv_path.write_text(json.dumps(inventory, ensure_ascii=False, indent=2), encoding="utf-8")

for sk in prompts:
    ppath = OUT_DIR / f"prompts_{sk}.json"
    ppath.write_text(json.dumps(prompts[sk], ensure_ascii=False, indent=2), encoding="utf-8")

# Also write a generate_tasks.py that creates task JSON files for generate_assets.py
gen_tasks = {}
for sk in prompts:
    tasks = []
    # Group cards by type
    for cid, card in cards.items():
        tasks.append({
            "id": cid,
            "name": card["name"],
            "type": card["type"],
            "prompt": prompts[sk]["cards"][cid]["prompt"],
            "negative": prompts[sk]["negative_prompt"],
            "dest": f"assets/{sk}/{card['type']}s/{style_map.get(cid, {}).get(card['type']+'s', cid+'.png')}",
        })
    # Heroes
    for hid, hero in heroes.items():
        tasks.append({
            "id": hid,
            "name": hero["name"],
            "type": "hero",
            "prompt": prompts[sk]["heroes"][hid]["prompt"],
            "negative": prompts[sk]["negative_prompt"],
            "dest": f"assets/{sk}/heroes/{hid}.png",
        })
    gen_tasks[sk] = tasks

tasks_path = OUT_DIR / "generate_tasks.json"
tasks_path.write_text(json.dumps(gen_tasks, ensure_ascii=False, indent=2), encoding="utf-8")

# ── 9. Print summary ──
print(f"""
╔══════════════════════════════════════════╗
║       战国卡牌 - 素材盘点报告             ║
╚══════════════════════════════════════════╝

📊 总计: {total_cards} 张卡牌 + {total_heroes} 个英雄 = {total_cards + total_heroes} 个资产

📦 卡牌类型:
""")
for t, n in sorted(by_type.items()):
    print(f"   {t}: {n}张")

print(f"\n🏛️ 学派:")
for o, n in sorted(by_owner.items()):
    print(f"   {o}: {n}张")

print(f"\n🗺️ 映射现状 (card_image_service.dart):")
print(f"   随从映射: {mapped_minions}/{by_type.get('minion', 0)}")
print(f"   法术映射: {mapped_spells}/{by_type.get('spell', 0)}")
print(f"   武器映射: {mapped_weapons}/{by_type.get('weapon', 0)}")

print(f"""
🎨 生成3套风格:
   ✅ chibi_cute  → {len(prompts['chibi_cute']['cards'])}卡 + {len(prompts['chibi_cute']['heroes'])}英雄
   ✅ fantasy_rpg → {len(prompts['fantasy_rpg']['cards'])}卡 + {len(prompts['fantasy_rpg']['heroes'])}英雄  
   ✅ euro_fantasy → {len(prompts['euro_fantasy']['cards'])}卡 + {len(prompts['euro_fantasy']['heroes'])}英雄

📁 输出文件:
   tool/inventory.json
   tool/prompts_chibi_cute.json
   tool/prompts_fantasy_rpg.json
   tool/prompts_euro_fantasy.json
   tool/generate_tasks.json
""")
