#!/bin/sh
# ============================================================================
# verify_deploy.sh —— 验证线上部署与本地构建产物的一致性
#
# 用途: 根治「线上线下不一致」问题。在每次 push 触发 Railway 部署后运行，
#       轮询线上 main.dart.js，直到其指纹与本地 build 一致，才判定部署成功。
#
# 用法:
#   scripts/verify_deploy.sh                    # 用线上主域 wscard.games
#   SCRIPTS_BASE_URL=https://your-domain scripts/verify_deploy.sh
#
# 可选环境变量:
#   DEPLOY_URL        线上站点根（默认 https://wscard.games）
#   MAX_WAIT_SEC      最大等待部署完成秒数（默认 300）
#   POLL_INTERVAL     轮询间隔秒数（默认 15）
#   LOCAL_BUILD      本地构建产物路径（默认 build/web/main.dart.js）
# ============================================================================
set -eu

DEPLOY_URL="${DEPLOY_URL:-https://wscard.games}"
MAX_WAIT_SEC="${MAX_WAIT_SEC:-300}"
POLL_INTERVAL="${POLL_INTERVAL:-15}"
LOCAL_BUILD="${LOCAL_BUILD:-build/web/main.dart.js}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# ---- 0. 本地 build 必须存在且是最新构建 ----
if [ ! -f "$LOCAL_BUILD" ]; then
  echo "✗ 本地构建不存在: $LOCAL_BUILD"
  echo "  请先运行: flutter build web --release"
  exit 1
fi

# ---- 1. 抽取本地指纹 ----
LOCAL_FP=$(sh "$SCRIPT_DIR/fingerprint.sh" "$LOCAL_BUILD")
echo "本地 build 指纹: $LOCAL_FP"

# ---- 2. 轮询线上，直到指纹一致（等待 Railway 部署完成）----
echo "开始轮询线上 ${DEPLOY_URL} 部署状态（最多 ${MAX_WAIT_SEC}s）..."
START=$(date +%s)
while :; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if [ "$ELAPSED" -ge "$MAX_WAIT_SEC" ]; then
    echo "✗ 超时（${MAX_WAIT_SEC}s）仍未检测到与本地一致的线上构建。"
    echo "  线上最终指纹: $LIVE_FP"
    echo "  本地最终指纹: $LOCAL_FP"
    echo "  可能原因: Railway 构建失败 / 部署未触发 / Dockerfile 与本地不一致"
    exit 1
  fi

  LIVE_FP=$(sh "$SCRIPT_DIR/fingerprint.sh" "$DEPLOY_URL/main.dart.js")
  if [ "$LIVE_FP" = "$LOCAL_FP" ]; then
    echo "✓ 线上已与本地构建一致（部署完成）"
    echo "  线上指纹: $LIVE_FP"
    exit 0
  fi

  echo "  [$((ELAPSED))s] 线上指纹不匹配，等待部署…"
  echo "    线上: $LIVE_FP"
  sleep "$POLL_INTERVAL"
done
