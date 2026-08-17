#!/bin/sh
# ============================================================================
# fingerprint.sh —— 从 Flutter web 构建产物抽取指纹，用于比对本地与线上一致性
#
# 用法:
#   scripts/fingerprint.sh [<file-or-url>] [<base-url>]
#
# 参数:
#   $1  源：本地文件绝对/相对路径，或 http(s):// URL（默认: build/web/main.dart.js）
#   $2  base-url：仅当 $1 是 URL 时，用于定位线上 l10n 资源，可省略（自动反推）
#
# 指纹组成:
#   - main.dart.js 关键特征计数（home.download / __adOpenSmartLink / ...）
#   - l10n 资源完整性：11 个语言文件是否含 "home.legal" 键（0=缺失）
#
# 输出: 形如 "home.download=1|...|l10n_zh=1|..." 的稳定指纹串（单行）。
#       若源无法读取，输出空串并以非 0 退出。
# ============================================================================
set -eu

SRC="${1:-build/web/main.dart.js}"
FEATURES="home.download __adOpenSmartLink adsterra-banner-slot /privacy hero_char"
LANGS="de en es fil fr ja ms ru th zh zh_TW"

# --- 读取源内容（文件或 URL 都支持）------------------------------------
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

# --- main.dart.js 特征 --------------------------------------------------
FP=""
for f in $FEATURES; do
  n=$(printf '%s' "$CONTENT" | grep -oF "$f" | wc -l | tr -d ' ')
  if [ -z "$FP" ]; then FP="$f=$n"; else FP="$FP|$f=$n"; fi
done

# --- l10n 完整性（home.legal 键计数，0=文件缺失或键缺失）-----------------
L10N_FP=""
if echo "$SRC" | grep -qE '^https?://'; then
  BASE="${2:-}"
  if [ -z "$BASE" ]; then
    BASE=$(printf '%s' "$SRC" | sed -E 's#(https?://[^/]+)/.*#\1#')
  fi
  for lang in $LANGS; do
    n=$(curl -s --max-time 15 "$BASE/assets/assets/l10n/$lang.json" | grep -oF '"home.legal"' | wc -l | tr -d ' ')
    if [ -z "$L10N_FP" ]; then L10N_FP="l10n_$lang=$n"; else L10N_FP="$L10N_FP|l10n_$lang=$n"; fi
  done
else
  L10N_DIR="$(dirname "$SRC")/assets/assets/l10n"
  for lang in $LANGS; do
    n=$(grep -oF '"home.legal"' "$L10N_DIR/$lang.json" 2>/dev/null | wc -l | tr -d ' ')
    if [ -z "$L10N_FP" ]; then L10N_FP="l10n_$lang=$n"; else L10N_FP="$L10N_FP|l10n_$lang=$n"; fi
  done
fi

printf '%s|%s\n' "$FP" "$L10N_FP"