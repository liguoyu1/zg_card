#!/bin/sh
# ============================================================================
# verify_local.sh —— 校验本地 docker 容器(zg_web)与本地 build 的一致性
#
# 用途: 根治「本地预览与本地代码不一致」问题。之前多次出现：
#   - 更新了 html/js 但忘了同步 nginx.conf（导致 /privacy 回退首页）
#   - 浏览器 service worker 缓存旧 main.dart.js（导致 home.legal 变量名）
#
# 校验项:
#   1. 容器内 main.dart.js 指纹 == 本地 build 指纹
#   2. 容器内 nginx.conf 含 /privacy 配置
#   3. 容器内 privacy.html 存在
#   4. 容器内 /privacy 返回隐私页（非 index）
#   5. 容器内 / 正常
#
# 用法: scripts/verify_local.sh [container]
# ============================================================================
set -u
CONTAINER="${1:-zg_web}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL_BUILD="${LOCAL_BUILD:-build/web/main.dart.js}"

[ -f "$LOCAL_BUILD" ] || { echo "✗ 本地 build 不存在: $LOCAL_BUILD"; exit 1; }

LOCAL_FP=$(sh "$SCRIPT_DIR/fingerprint.sh" "$LOCAL_BUILD")
LIVE_FP=$(sh "$SCRIPT_DIR/fingerprint.sh" "http://localhost:8080/main.dart.js")

echo "本地 fingerprint : $LOCAL_FP"
echo "容器 fingerprint : $LIVE_FP"
[ "$LOCAL_FP" = "$LIVE_FP" ] && echo "✓ 容器 main.dart.js 与本地一致" || { echo "✗ 容器 main.dart.js 与本地不一致（请 docker cp build/web/. $CONTAINER:/usr/share/nginx/html/）"; exit 1; }

echo "--- 检查 nginx /privacy 路由 ---"
if docker exec "$CONTAINER" sh -c 'grep -q "location = /privacy" /etc/nginx/conf.d/default.conf 2>/dev/null'; then
  echo "✓ 容器 nginx.conf 含 /privacy"
else
  echo "✗ 容器 nginx.conf 缺 /privacy（请 docker cp nginx.conf $CONTAINER:/etc/nginx/conf.d/default.conf）"
  exit 1
fi

echo "--- 检查 privacy.html 存在 ---"
docker exec "$CONTAINER" sh -c 'test -f /usr/share/nginx/html/privacy.html' || { echo "✗ 容器缺 privacy.html"; exit 1; }
echo "✓ privacy.html 存在"

echo "--- 检查 /privacy 返回隐私页（非首页 index）---"
PRIV_TITLE=$(curl -s http://localhost:8080/privacy | grep -oE "<title>[^<]*</title>" | head -1)
case "$PRIV_TITLE" in
  *隐私*) echo "✓ /privacy 返回隐私页 ($PRIV_TITLE)" ;;
  *) echo "✗ /privacy 返回了非隐私页: $PRIV_TITLE"; exit 1 ;;
esac

echo "--- 检查首页正常 ---"
curl -s -o /dev/null -w "首页 HTTP %{http_code}\n" http://localhost:8080/ || { echo "✗ 首页不可达"; exit 1; }

echo ""
echo "✓✓ 本地容器与本地代码完全一致 ✓✓"
