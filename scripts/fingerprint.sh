#!/bin/sh
# ============================================================================
# fingerprint.sh —— 从 Flutter web 构建产物抽取指纹，用于比对本地与线上一致性
#
# 用法:
#   scripts/fingerprint.sh [<file-or-url>] [<base-url>]
#
# 参数:
#   $1  源：本地文件绝对/相对路径，或 http(s):// URL（默认: build/web/main.dart.js）
#   $2  base-url：仅当 $1 是 URL 时，用于比对 index.html 的额外根，可省略
#
# 输出: 形如 "home.download=1|__adOpenSmartLink=2|..." 的稳定指纹串（单行）。
#       若源无法读取，输出空串并以非 0 退出。
# ============================================================================
set -eu

SRC="${1:-build/web/main.dart.js}"
FEATURES="home.download __adOpenSmartLink adsterra-banner-slot /privacy hero_char"

# 读取源内容（文件或 URL 都支持）
if [ -f "$SRC" ]; then
  CONTENT=$(cat "$SRC")
elif echo "$SRC" | grep -qE '^https?://'; then
  CONTENT=$(curl -s --max-time 20 "$SRC" || true)
  if [ -z "$CONTENT" ]; then
    echo "ERROR: 无法读取线上资源: $SRC" >&2
    exit 1
  fi
else
  echo "ERROR: 找不到源: $SRC" >&2
  exit 1
fi

FP=""
for f in $FEATURES; do
  n=$(printf '%s' "$CONTENT" | grep -oF "$f" | wc -l | tr -d ' ')
  if [ -z "$FP" ]; then FP="$f=$n"; else FP="$FP|$f=$n"; fi
done

printf '%s\n' "$FP"
