#!/usr/bin/env python3
"""一致性测试 — 同一风格生成不同卡牌类型，确认视觉一致性"""
import json, os, sys, time, zipfile
from pathlib import Path
import httpx
from gradio_client import Client

API_BASE = os.environ.get("GEN_API_URL", "http://117.50.188.37:7860")
PROMPT_FILE = os.environ.get("PROMPT_FILE",
    "assets/prompts_fantasy_rpg.json")
OUT_DIR = "assets/test_consistency"

def make_client():
    return Client(API_BASE, httpx_kwargs={"timeout": httpx.Timeout(300, connect=15)})

def gen_one(client, prompt, negative="bad image", width=752, height=1328,
            steps=9, poll_sec=120):
    """提交生成，返回zip路径"""
    client.predict(
        prompt, steps, negative, width, height,
        None, "开启",
        "None", 1, "None", 1, "None", 1, "None", 1,
        False, False, 0.45, False,
        api_name="/add_task_to_queue"
    )
    deadline = time.time() + poll_sec
    while time.time() < deadline:
        time.sleep(2)
        r = client.predict(api_name="/refresh_ui_and_process_queue")
        img = r[6]
        if img and img not in ("None", "", None):
            return img
    return None

def download_result(client, out_dir, label):
    """下载并重命名，返回文件路径"""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    try:
        z = client.submit(api_name="/down_zip").result()
        if not z:
            return None
        src = Path(str(z))
        if not src.exists():
            return None
        with zipfile.ZipFile(str(src)) as zf:
            names = zf.namelist()
            for name in names:
                ext = Path(name).suffix or ".png"
                dest_name = f"{label}{ext}"
                dest = out / dest_name
                zf.extract(name, str(out))
                extracted = out / name
                if extracted.exists():
                    os.rename(str(extracted), str(dest))
                print(f"  ✓ {dest}")
            return [str(out / dest_name)]
    except Exception as e:
        print(f"  ✗ download error: {e}")
    return None

def main():
    prompt_file = Path(__file__).parent.parent / PROMPT_FILE
    with open(prompt_file) as f:
        data = json.load(f)

    style = data["style"]
    negative = data["negative_prompt"]
    cards = data["cards"]
    heroes = data["heroes"]

    # 选取测试样本
    samples = [
        ("minion_魏武卒", cards["B001"]["prompt"]),
        ("spell_围魏救赵", cards["B013"]["prompt"]),
        ("weapon_吴钩", cards["BW001"]["prompt"]),
        ("hero_孙膑", heroes["H_B001"]["prompt"]),
    ]

    print(f"=== 风格一致性测试: {style} ===")
    print(f"共计 {len(samples)} 张\n")

    c = make_client()
    print(f"API: {API_BASE}")
    print(f"示例: minion, spell, weapon, hero\n")

    for label, prompt in samples:
        print(f"[{label}] 提交...")
        t0 = time.time()
        img = gen_one(c, prompt, negative)
        elapsed = time.time() - t0
        if img:
            print(f"  完成 ({elapsed:.0f}s), 下载中...")
            out_dir = Path(__file__).parent.parent / OUT_DIR
            download_result(c, out_dir, label)
        else:
            print(f"  ✗ 超时 ({elapsed:.0f}s)")
        time.sleep(1)

    print(f"\n完成! 文件在 {OUT_DIR}/")
    # 列出结果
    out_path = Path(__file__).parent.parent / OUT_DIR
    for f in sorted(out_path.glob("*")):
        print(f"  {f.name}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
