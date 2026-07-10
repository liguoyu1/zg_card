#!/usr/bin/env python3
import json, time, subprocess, urllib.request, os
from pathlib import Path

WEBHOOK = "https://open.larksuite.com/open-apis/bot/v2/hook/ffa7c7e2-d57b-4578-9bda-55235f3dc465"
LOG_FILE = Path(__file__).resolve().parent.parent / "assets" / "gen_fantasy.log"
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "fantasy_rpg"
INTERVAL = 1200  # 20min

TOTAL = 217

def lark_msg(text):
    payload = json.dumps({"msg_type": "text", "content": {"text": text}}).encode()
    req = urllib.request.Request(WEBHOOK, data=payload, headers={"Content-Type": "application/json"})
    try:
        urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        print(f"[monitor] webhook err: {e}")

def check():
    files = list(OUT_DIR.rglob("*.png"))
    done = len(files)

    # 从日志提取 latest
    latest = ""
    if LOG_FILE.exists():
        lines = LOG_FILE.read_text().strip().splitlines()
        for l in reversed(lines):
            if l.startswith("  ") and ("OK" in l or "FAIL" in l or "SKIP" in l):
                latest = l.strip()
                break

    pct = done / TOTAL * 100
    elapsed = time.time() - start_time
    rate = done / elapsed if elapsed > 0 else 0
    eta_sec = (TOTAL - done) / rate if rate > 0 else 0
    eta_min = eta_sec / 60

    pid = open("/tmp/gen_fantasy.pid").read().strip() if os.path.exists("/tmp/gen_fantasy.pid") else "?"
    still_running = os.path.exists(f"/proc/{pid}") if os.name == "posix" else True

    msg = (
        f"🎴 卡牌生成进度\n"
        f"进度: {done}/{TOTAL} ({pct:.0f}%)\n"
        f"耗时: {elapsed/60:.0f}min\n"
        f"速率: {rate*60:.1f} 张/min\n"
        f"预计剩余: {eta_min:.0f}min\n"
        f"最后: {latest}"
    )
    print(msg)
    lark_msg(msg)

if __name__ == "__main__":
    start_time = time.time()
    check()  # 首次立即推送
    while True:
        time.sleep(INTERVAL)
        check()
