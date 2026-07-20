#!/usr/bin/env python3
import json, os, sys, base64, time
from pathlib import Path
from openai import OpenAI

API_KEY = os.environ.get("QIANMIAN_API_KEY",
    "sk-qmcloud-ToKNdw_t5sMPy2hZG40DhiqX6l3mKf5PI2sWjtA_fs8")
API_URL = "https://api.qianmian.ai/v1"
MODEL = "gpt-image-1"
SIZE = "1024x1536"  # 竖版全身像 (gpt-image-1 支持的最大竖版)
ASSETS = Path(__file__).resolve().parent.parent / "assets" / "fantasy_rpg_test"

MINION_CARDS = [
    {"name": "魏武卒", "en_name": "wei_wu_zu"},
    {"name": "孙武",   "en_name": "sun_wu"},
    {"name": "李牧",   "en_name": "li_mu"},
]
SPELL_CARDS = [
    {"name": "围魏救赵","en_name": "wei_wei_jiu_zhao"},
    {"name": "破釜沉舟","en_name": "po_fu_chen_zhou"},
]
WEAPON_CARDS = [
    {"name": "吴钩",   "en_name": "wu_gou"},
    {"name": "越王剑", "en_name": "yue_wang_jian"},
]
HERO_CARDS = [
    {"name": "孙膑",   "en_name": "sun_bin"},
    {"name": "吴起",   "en_name": "wu_qi"},
    {"name": "廉颇",   "en_name": "lian_po"},
]

def resolve_prompts(data, cards, ctype):
    idx = {}
    for c in data:
        idx[(c["card_type"], c["en_name"])] = c["prompt"]
    resolved = []
    for c in cards:
        p = idx.get((ctype, c["en_name"]))
        if p:
            resolved.append({**c, "type": ctype, "prompt": p})
        else:
            print(f"  SKIP {ctype}/{c['en_name']}")
    return resolved

def gen_one(client, card, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    # 对 minion 追加全身像约束，替换 portrait 为 full body
    p = card['prompt']
    if card['type'] in ('minion', 'hero'):
        p = p.replace('character portrait', 'full body portrait, standing, head to toe, feet visible, no cropping')
    elif card['type'] == 'weapon':
        p += ', full weapon visible from tip to handle, no cropping'
    fp = f"{p}, the Chinese characters are written on the image, traditional Chinese calligraphy text"

    print(f"  gen {card['name']} ({card['type']})...", end=" ", flush=True)
    try:
        resp = client.images.generate(
            model=MODEL, prompt=fp, n=1, size=SIZE,
            response_format="b64_json",
        )
    except Exception as e:
        print(f"ERR: {e}")
        return False

    img = resp.data[0]
    if img.b64_json:
        raw = base64.b64decode(img.b64_json)
        dest.write_bytes(raw)
        print(f"OK ({len(raw)//1024}KB)")
        return True
    elif img.url:
        import httpx
        r = httpx.get(img.url, timeout=30)
        if r.status_code == 200:
            dest.write_bytes(r.content)
            print(f"OK (url, {len(r.content)//1024}KB)")
            return True
    print("NOIMG")
    return False

def main():
    with open(Path(__file__).resolve().parent.parent / "assets" / "prompts_fantasy_rpg.json") as f:
        data = json.load(f)

    all_cards = []
    all_cards += resolve_prompts(data, MINION_CARDS, "minion")
    all_cards += resolve_prompts(data, SPELL_CARDS, "spell")
    all_cards += resolve_prompts(data, WEAPON_CARDS, "weapon")
    all_cards += resolve_prompts(data, HERO_CARDS, "hero")
    print(f"测试: {len(all_cards)} 张")
    for c in all_cards:
        print(f"  {c['name']:10s} {c['type']:6s}")

    client = OpenAI(api_key=API_KEY, base_url=API_URL)
    ok = fail = 0
    for c in all_cards:
        dest = ASSETS / c["type"] / f"{c['en_name']}.png"
        if gen_one(client, c, dest):
            ok += 1
        else:
            fail += 1
        time.sleep(1)

    print(f"\n✅ {ok}  ❌ {fail}")
    if ok:
        print(f"📁 {ASSETS}")

if __name__ == "__main__":
    main()
