#!/usr/bin/env python3
"""战国卡牌 - AI素材批量生成脚本"""
import argparse, json, os, sys, time, zipfile
from pathlib import Path
import httpx
from gradio_client import Client

API_BASE = os.environ.get("GEN_API_URL", "http://117.50.188.37:7860")

def make_client():
    return Client(API_BASE, httpx_kwargs={"timeout": httpx.Timeout(300, connect=15)})

def gen_one(client, prompt, negative="bad image", width=752, height=1328,
            steps=9, ref_img=None, sage_attn="开启", auto_4k=False, poll_sec=120):
    """提交生成任务，返回下载路径"""
    client.predict(
        prompt, steps, negative, width, height,
        ref_img, sage_attn,
        "None", 1, "None", 1, "None", 1, "None", 1,
        False, False, 0.45, auto_4k,
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

def download_result(client, out_dir):
    """下载生成结果到目录"""
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
            extracted = []
            for name in names:
                dest = out / name
                zf.extract(name, str(out))
                extracted.append(str(dest))
                print(f"  -> {dest}")
            return extracted
    except Exception as e:
        print(f"  download error: {e}")
    return None

def main():
    parser = argparse.ArgumentParser(description="战国卡牌 AI素材批量生成")
    parser.add_argument("--prompt", help="单张生成提示词")
    parser.add_argument("--output", default="assets/test/output.png", help="输出路径")
    parser.add_argument("--negative", default="bad image")
    parser.add_argument("--width", type=int, default=752)
    parser.add_argument("--height", type=int, default=1328)
    parser.add_argument("--steps", type=int, default=9)
    parser.add_argument("--task-file", help="批量任务JSON文件")
    parser.add_argument("--test", action="store_true", help="测试模式")
    args = parser.parse_args()

    if args.test:
        print("测试模式")
        c = make_client()
        p = gen_one(c, "test cute cat, ink wash painting traditional Chinese style",
                    steps=8, width=512, height=512)
        if p:
            download_result(c, "assets/test")
            print("测试成功")
            return 0
        print("测试失败")
        return 1

    if args.prompt:
        c = make_client()
        p = gen_one(c, args.prompt, args.negative, args.width, args.height, args.steps)
        if p:
            download_result(c, os.path.dirname(args.output) or ".")
        return 0

    if args.task_file:
        with open(args.task_file) as f:
            tasks = json.load(f)
        c = make_client()
        print(f"共 {len(tasks)} 个任务")
        for i, t in enumerate(tasks):
            print(f"\n[{i+1}/{len(tasks)}] {t.get('id', '?')}: {t.get('prompt', '')[:60]}")
            p = gen_one(c, t["prompt"], t.get("negative", args.negative),
                       t.get("width", args.width), t.get("height", args.height),
                       t.get("steps", args.steps))
            if p:
                out_dir = t.get("output_dir", f"assets/generated/{t.get('style', 'unknown')}")
                downloaded = download_result(c, out_dir)
            time.sleep(1)
        return 0

    parser.print_help()
    return 0

if __name__ == "__main__":
    sys.exit(main())
