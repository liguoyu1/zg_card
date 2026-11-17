#!/bin/sh
# IndexNow 推送（Bing/Yandex/Seznam 等共享）：部署后运行，把 sitemap 全部 URL 推给搜索引擎。
# 用法: sh scripts/indexnow.sh   （需线上已能访问 https://wscard.games/$KEY.txt）
# ponytail: 每次全量推送（<20 个 URL，配额充足）；页面多了再改成只推 git diff 涉及的页面。
set -e
KEY=89239087ad7f484782433b40ea1d355b
HOST=wscard.games
cd "$(dirname "$0")/.."
URLS=$(grep -o '<loc>[^<]*' web/sitemap.xml | sed 's/<loc>//' | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}')
curl -sS -o /dev/null -w "IndexNow HTTP %{http_code} (200/202 = ok)\n" \
  -X POST https://www.bing.com/indexnow \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d "{\"host\":\"$HOST\",\"key\":\"$KEY\",\"keyLocation\":\"https://$HOST/$KEY.txt\",\"urlList\":[$URLS]}"
