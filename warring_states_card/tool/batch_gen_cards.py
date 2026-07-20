#!/usr/bin/env python3
"""
批量生成卡牌图片：三套提示词 → assets/{style}/{card_type}/{en_name}.png
API: OpenAI-compatible (https://api.qianmian.ai/v1, model=gemini-2.5-flash-image-preview)
用法:
  export QIANMIAN_API_KEY=your_key_here
  python3 tool/batch_gen_cards.py                         # 全量生成
  python3 tool/batch_gen_cards.py --style fantasy_rpg     # 只生成一套
  python3 tool/batch_gen_cards.py --types minion spell    # 只生成指定类型
  python3 tool/batch_gen_cards.py --no-resume             # 重新生成已有的
"""

import json, os, sys, time, argparse, base64
from pathlib import Path
from openai import OpenAI

# ===== 配置 =====
API_KEY = os.environ.get("QIANMIAN_API_KEY", "sk-qmcloud-ToKNdw_t5sMPy2hZG40DhiqX6l3mKf5PI2sWjtA_fs8")
API_URL = "https://api.qianmian.ai/v1"
MODEL = "gpt-image-1"
ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
SIZE = "1024x1536"   # 竖版全身像

# ===== 主流程 =====


def adapt_prompt(prompt, ctype):
    if ctype in ('minion', 'hero'):
        return prompt.replace('character portrait',
            'full body portrait, standing, head to toe, feet visible, no cropping')
    if ctype == 'weapon':
        return prompt + ', full weapon visible from tip to handle, no cropping'
    return prompt

def gen_one(client, prompt, dest_path, ctype=""):
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    is_icon = ctype == 'icon'

    prompt = adapt_prompt(prompt, ctype)
    if is_icon:
        full_prompt = prompt
        size = "1024x1024"
    else:
        full_prompt = f"{prompt}, the Chinese characters are written on the image, traditional Chinese calligraphy text"
        size = SIZE

    print(f"    generating...", end=" ", flush=True)
    try:
        resp = client.images.generate(
            model=MODEL,
            prompt=full_prompt,
            n=1,
            size=size,
            response_format="b64_json",
        )
    except Exception as e:
        print(f"FAIL ({e})")
        return False

    # 取结果
    img_data = resp.data[0]
    if img_data.b64_json:
        raw = base64.b64decode(img_data.b64_json)
        with open(dest_path, "wb") as f:
            f.write(raw)
        kb = len(raw) // 1024
        print(f"OK ({kb}KB)")
        return True
    elif img_data.url:
        import httpx
        try:
            r = httpx.get(img_data.url, timeout=30)
            if r.status_code == 200:
                with open(dest_path, "wb") as f:
                    f.write(r.content)
                kb = len(r.content) // 1024
                print(f"OK (url, {kb}KB)")
                return True
        except Exception as e:
            print(f"FAIL (url download: {e})")
            return False
    else:
        print("FAIL (no image data)")
        return False


def process_style(style_name, prompt_file, card_types=None, resume=True):
    """处理一套风格"""
    print(f"\n{'='*60}")
    print(f"🎨 风格: {style_name}")
    print(f"  文件: {prompt_file}")

    with open(prompt_file, encoding="utf-8") as f:
        cards = json.load(f)

    if card_types:
        cards = [c for c in cards if c["card_type"] in card_types]
        if not cards:
            print("  (无匹配类型)")
            return {"ok": 0, "skip": 0, "fail": 0}

    client = OpenAI(api_key=API_KEY, base_url=API_URL)

    # 统计
    type_counts = {}
    for c in cards:
        t = c["card_type"]
        type_counts[t] = type_counts.get(t, 0) + 1
    print(f"  卡量: {len(cards)} 张 ({', '.join(f'{t}={n}' for t, n in sorted(type_counts.items()))})")

    # 处理冲突：同一 (ctype, ename) 多张卡
    name_to_cards = {}
    for c in cards:
        key = (c["card_type"], c["en_name"])
        name_to_cards.setdefault(key, []).append(c)

    # 分配合一文件名
    used = {}  # ctype -> set of filenames
    assignments = {}
    for (ctype, ename), entries in name_to_cards.items():
        base = f"{ename}.png"
        if base not in used.setdefault(ctype, set()):
            assignments[(ctype, ename)] = base
            used[ctype].add(base)
        else:
            idx = 2
            while f"{ename}_{idx}.png" in used[ctype]:
                idx += 1
            fn = f"{ename}_{idx}.png"
            assignments[(ctype, ename)] = fn
            used[ctype].add(fn)
            print(f"  ⚠️ 冲突 {ctype}/{ename} → {fn} ({', '.join(e['name'] for e in entries)})")

    # 逐张生成
    stats = {"ok": 0, "skip": 0, "fail": 0}
    for idx, c in enumerate(cards, 1):
        ctype, ename, prompt, cname = c["card_type"], c["en_name"], c["prompt"], c["name"]
        fname = assignments[(ctype, ename)]
        if ctype == 'icon':
            dest = ASSETS_DIR / "icons" / fname
        else:
            dest = ASSETS_DIR / style_name / ctype / fname

        prefix = f"[{idx}/{len(cards)}]"
        if resume and dest.exists():
            print(f"  {prefix} {cname:12s} SKIP (exists)")
            stats["skip"] += 1
            continue

        print(f"  {prefix} {cname:12s} → {'icons' if ctype == 'icon' else style_name}/{ctype}/{fname}")
        ok = gen_one(client, prompt, dest, ctype)
        if ok:
            stats["ok"] += 1
        else:
            stats["fail"] += 1

    return stats


def main():
    parser = argparse.ArgumentParser(description="批量生成卡牌图片 (gemini-2.5-flash-image-preview)")
    parser.add_argument("--style", choices=["chibi_cute", "euro_fantasy", "fantasy_rpg", "icons", "all"],
                        default="all", help="要生成的风格")
    parser.add_argument("--types", nargs="+", choices=["minion", "spell", "weapon", "hero", "icon"],
                        default=None, help="只生成指定类型")
    parser.add_argument("--no-resume", action="store_true", help="重新生成已存在的")
    args = parser.parse_args()

    if not API_KEY:
        print("❌ 请先设置环境变量: export QIANMIAN_API_KEY=your_key_here")
        sys.exit(1)

    style_map = {
        "chibi_cute": "prompts_chibi_cute.json",
        "euro_fantasy": "prompts_euro_fantasy.json",
        "fantasy_rpg": "prompts_fantasy_rpg.json",
        "icons": "prompts_icons.json",
    }

    to_run = list(style_map.items()) if args.style == "all" else \
             [(s, f) for s, f in style_map.items() if s == args.style]

    total_ok = total_skip = total_fail = 0
    start = time.time()

    for style_name, fname in to_run:
        prompt_file = ASSETS_DIR / fname
        if not prompt_file.exists():
            print(f"❌ 文件不存在: {prompt_file}")
            continue
        stats = process_style(style_name, prompt_file,
                              card_types=args.types,
                              resume=not args.no_resume)
        total_ok += stats["ok"]
        total_skip += stats["skip"]
        total_fail += stats["fail"]

    elapsed = time.time() - start
    total = total_ok + total_skip + total_fail
    print(f"\n{'='*60}")
    print(f"🏁 完成! 耗时 {elapsed/60:.1f} 分钟")
    print(f"  总计: {total} 张 | ✅ {total_ok} | ⏭ {total_skip} | ❌ {total_fail}")


if __name__ == "__main__":
    main()
