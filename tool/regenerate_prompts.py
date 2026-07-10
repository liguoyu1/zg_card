#!/usr/bin/env python3
"""读取 inventory.json → 生成 3 套水墨风 prompt JSON 文件"""
import json, os
from pathlib import Path

INVENTORY = Path("tool/inventory.json")
ASSETS    = Path("assets")
ASSETS.mkdir(exist_ok=True)

with open(INVENTORY) as f:
    inv = json.load(f)

# ── 3 套风格模板 ──────────────────────────────────
STYLES = {
    # ── 水墨Q版（可爱风）────────────────────────
    "chibi_cute": {
        "style": "水墨Q版战国",
        "base": "Chinese ink wash painting style, cute chibi, watercolor texture, soft colors, clean lines, adorable character design, 2D illustration, traditional Chinese painting",
        "negative": "realistic, 3D, dark, scary, violence, gore, modern, futuristic, photorealistic, oil painting, western fantasy",
        "img_type": "chibi_cute",
    },
    # ── 水墨写实史诗（大气风）────────────────────
    "fantasy_rpg": {
        "style": "水墨史诗战国",
        "base": "Chinese ink wash painting style, epic majestic composition, traditional ink brush strokes, atmospheric, dramatic, rich ink tones, calligraphy-inspired lines, traditional Chinese painting, masterpiece",
        "negative": "photorealistic, chibi, cartoon, anime, low quality, blurry, modern, western fantasy, oil painting, 3D render",
        "img_type": "fantasy_rpg",
    },
    # ── 水墨欧美奇幻（水墨基底+奇幻元素）──────────
    "euro_fantasy": {
        "style": "水墨欧美奇幻",
        "base": "Chinese ink wash painting meets Western fantasy, ink brush textures, ethereal, mystical atmosphere, dark ink tones, magical elements, traditional ink wash with fantasy flair, epic fantasy art",
        "negative": "photorealistic, chibi, cartoon, anime, low quality, blurry, modern, oil painting, 3D render",
        "img_type": "euro_fantasy",
    },
}

# ── 类型描述后缀（给 prompt 加具体元素）──────────
TYPE_SUFFIX = {
    "minion": "character portrait, military commander, armor and weapons, warrior",
    "spell": "spell effect, magical energy, swirling ink, dynamic energy, ethereal, mystical",
    "weapon": "weapon design, ancient Chinese weapon, intricate details, floating in ink wash style",
}

OWNER_MAP = {
    "bingjia":     "military strategy school, {name}",
    "fajia":       "legalist school, {name}",
    "rujia":       "confucian school, {name}",
    "daojia":      "taoist school, {name}",
    "mojia":       "mohist school, {name}",
    "yinyangjia":  "yin-yang school, {name}",
    "zonghengjia": "political strategist school, {name}",
}

def make_prompt(base, ctype, name, owner=None):
    parts = [base]
    # 类型元素
    parts.append(TYPE_SUFFIX.get(ctype, ""))
    # 学派元素
    if owner and owner in OWNER_MAP:
        parts.append(OWNER_MAP[owner].format(name=name))
    # 牌名
    parts.append(f"{name}, character portrait, card game art")
    return ", ".join(p for p in parts if p)


for style_key, cfg in STYLES.items():
    out = {
        "style":           cfg["style"],
        "negative_prompt": cfg["negative"],
        "cards":           {},
        "heroes":          {},
    }

    # ── 卡牌 ──
    for cid, cinfo in inv["cards"].items():
        prompt = make_prompt(
            cfg["base"],
            cinfo["type"],
            cinfo["name"],
            cinfo.get("owner"),
        )
        out["cards"][cid] = {
            "name":   cinfo["name"],
            "type":   cinfo["type"],
            "prompt": prompt,
        }

    # ── 英雄 ──
    for hid, hinfo in inv["heroes"].items():
        prompt = (
            f"{cfg['base']}, "
            f"hero character portrait, {hinfo.get('owner','')} school master, "
            f"majestic pose, ancient Chinese philosopher general, "
            f"{hinfo['name']}, leader portrait, card game art"
        )
        out["heroes"][hid] = {
            "name":   hinfo["name"],
            "prompt": prompt,
        }

    dest = ASSETS / f"prompts_{style_key}.json"
    with open(dest, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"✓ {dest}  ({len(out['cards'])} cards + {len(out['heroes'])} heroes)")

print("\nDone. 3 prompt files regenerated with ink wash (水墨) style.")
