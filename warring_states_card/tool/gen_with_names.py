#!/usr/bin/env python3
"""测试生成：按card_image_service映射文件名保存，prompt含卡名"""
import json, os, time, zipfile, shutil
from pathlib import Path
import httpx
from gradio_client import Client

API = os.environ.get("GEN_API_URL", "http://117.50.188.37:7860")
OUT = Path("assets/test_named")
OUT.mkdir(parents=True, exist_ok=True)

c = Client(API, httpx_kwargs={"timeout": httpx.Timeout(300, connect=15)})

# 从card_image_service映射 + inventory.json 获取卡名
with open("assets/prompts_fantasy_rpg.json") as f:
    prompts = json.load(f)
with open("tool/inventory.json") as f:
    inv = json.load(f)
neg = prompts["negative_prompt"]

# 测试集: (卡ID, 类型, 映射文件名, 卡名)
# 从card_image_service.dart和asset_registry.dart提取
test_set = [
    # B001 minion -> bingjia_wuwuzu.png
    ("B001", "minions", "bingjia_wuwuzu.png", "魏武卒"),
    # B013 spell -> spells_spell_weiwz.png (围魏救赵)
    ("B013", "spells", "spells_spell_weiwz.png", "围魏救赵"),
    # BW001 weapon -> weapons_weapon_wugou.png
    ("BW001", "weapons", "weapons_weapon_wugou.png", "吴钩"),
    # H_B001 hero -> bingjia_sunbin.png (孙膑英雄)
    ("H_B001", "heroes", "bingjia_sunbin.png", "孙膑"),
]

for cid, subdir, fname, cname in test_set:
    style = "fantasy_rpg"
    dest_dir = OUT / style / subdir
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / fname

    card = prompts["cards"].get(cid) or prompts["heroes"].get(cid)
    if not card:
        print(f"{cid}: no prompt found")
        continue
    base_prompt = card["prompt"]
    # 加入卡名文字要求
    prompt = f"{base_prompt}, the Chinese characters '{cname}' are written on the image, traditional Chinese calligraphy text"

    print(f"\n--- {cid} {cname} -> {style}/{subdir}/{fname} ---")
    c.predict(prompt, 9, neg, 752, 1328, None, "开启",
              "None",1,"None",1,"None",1,"None",1,
              False, False, 0.45, False,
              api_name="/add_task_to_queue")

    deadline = time.time() + 180
    img = None
    while time.time() < deadline:
        time.sleep(3)
        r = c.predict(api_name="/refresh_ui_and_process_queue")
        img = r[6]
        if img and img not in ("None","",None):
            break

    if not img:
        print(f"  FAIL (no result)")
        continue

    z = c.submit(api_name="/down_zip").result(timeout=30)
    if z:
        src = Path(str(z))
        if src.exists():
            with zipfile.ZipFile(str(src)) as zf:
                names = sorted(zf.namelist())
                if names:
                    last = names[-1]
                    zf.extract(last, str(OUT))
                    extracted = OUT / last
                    if extracted.exists():
                        shutil.move(str(extracted), str(dest))
                        print(f"  -> {dest} ({os.path.getsize(dest)//1024}KB)")

    time.sleep(2)

print(f"\n=== 完成! 结果在 {OUT}/ ===")
for p in sorted(OUT.rglob("*")):
    if p.is_file():
        print(f"  {p.relative_to(OUT)} ({p.stat().st_size//1024}KB)")
