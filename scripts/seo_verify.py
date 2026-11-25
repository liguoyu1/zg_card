#!/usr/bin/env python3
"""站内 SEO 一致性自检（不需要联网、不需要起服务）。

检查四件事：
  1. 每页 canonical 是否等于它的唯一规范地址（无 .html 后缀）
  2. 语言集群 hreflang 是否完整、互指，且都指向规范地址
  3. 站内链接是否全部指向规范地址（无 *.html、无 /blog/ 这类重复变体）
  4. sitemap.xml 是否恰好收录「可索引页」的规范地址，且不含 noindex 页

用法：python3 scripts/seo_verify.py
退出码非 0 表示存在不一致。
"""
from __future__ import annotations

import re
import sys
import pathlib
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parents[1]
WEB = ROOT / "web"
BASE = "https://wscard.games"

# 文件 → 规范路径
CANON = {
    "index.html": "/",
    "landing.html": "/en",
    "landing-jp.html": "/ja",
    "landing-kr.html": "/ko",
    "landing-th.html": "/th",
    "landing-vi.html": "/vi",
    "landing-de.html": "/de",
    "zh-tw.html": "/zh-tw",
    "about.html": "/about",
    "download.html": "/download",
    "promo.html": "/promo",
    "privacy.html": "/privacy",
    "terms.html": "/terms",
    "data-deletion.html": "/data-deletion",
    "blog/index.html": "/blog",
    "blog/rules-zh.html": "/blog/rules-zh",
    "blog/getting-started-guide.html": "/blog/getting-started-guide",
    "blog/seven-schools-guide.html": "/blog/seven-schools-guide",
}

# 参与 hreflang 集群的语言页（文件 → 语言码）
CLUSTER = {
    "index.html": "zh-Hans",
    "landing.html": "en",
    "landing-jp.html": "ja",
    "landing-kr.html": "ko",
    "landing-th.html": "th",
    "landing-vi.html": "vi",
    "landing-de.html": "de",
    "zh-tw.html": "zh-Hant",
}
XLANG = [("zh-Hans", "/"), ("zh-Hant", "/zh-tw"), ("en", "/en"), ("ja", "/ja"),
         ("ko", "/ko"), ("th", "/th"), ("vi", "/vi"), ("de", "/de"), ("x-default", "/en")]

# 不参与收录（noindex）但需要能访问的页
NOINDEX = {"landing-eu.html", "landing-sea.html", "promo.html"}

SITEMAP_EXPECTED = {"/", "/en", "/ja", "/ko", "/th", "/vi", "/de", "/zh-tw",
                    "/about", "/download", "/blog", "/blog/rules-zh",
                    "/blog/getting-started-guide", "/blog/seven-schools-guide",
                    "/privacy", "/terms", "/data-deletion"}

ASSET_EXT = (".webp", ".png", ".jpg", ".jpeg", ".svg", ".ico", ".css", ".js", ".xml", ".txt", ".apk")


class LinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.canonical: str | None = None
        self.hreflang: list[tuple[str, str]] = []
        self.robots: str | None = None
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "link":
            if a.get("rel") == "canonical":
                self.canonical = a.get("href")
            if a.get("rel") == "alternate" and a.get("hreflang"):
                self.hreflang.append((a["hreflang"], a.get("href", "")))
        if tag == "meta" and a.get("name") == "robots":
            self.robots = (a.get("content") or "").lower()
        if tag == "a" and a.get("href"):
            self.links.append(a["href"])


def to_path(href: str) -> str | None:
    if href.startswith(BASE):
        p = href[len(BASE):]
        return p or "/"
    if href.startswith("http://") or href.startswith("https://") or href.startswith("//"):
        return None  # 站外
    if href.startswith("#") or href.startswith("mailto:") or href.startswith("javascript:"):
        return None
    return href


def main() -> int:
    errors: list[str] = []
    pages: dict[str, LinkParser] = {}

    files = sorted(WEB.glob("*.html")) + sorted((WEB / "blog").glob("*.html"))
    for f in files:
        rel = f.relative_to(WEB).as_posix()
        p = LinkParser()
        p.feed(f.read_text(encoding="utf-8"))
        pages[rel] = p

    # 1. canonical
    for rel, p in pages.items():
        want = CANON.get(rel)
        if rel in NOINDEX:
            if p.canonical:
                errors.append(f"{rel}: noindex 页不应再声明 canonical（{p.canonical}）")
            if p.robots is None or "noindex" not in p.robots:
                errors.append(f"{rel}: 缺少 robots noindex")
            continue
        if want is None:
            errors.append(f"{rel}: 不在规范地址表中")
            continue
        got = p.canonical
        exp = BASE + want
        if got != exp:
            errors.append(f"{rel}: canonical={got} 期望 {exp}")
        if p.robots and "noindex" in p.robots:
            errors.append(f"{rel}: 可索引页却带 noindex")

    # 2. hreflang 集群
    for rel, lang in CLUSTER.items():
        p = pages[rel]
        got = {(l, h.replace(BASE, "") or "/") for l, h in p.hreflang}
        want = set(XLANG)
        missing = want - got
        extra = got - want
        if missing or extra:
            errors.append(f"{rel}: hreflang 缺 {sorted(missing)} 多 {sorted(extra)}")
        if (lang, CANON[rel]) not in got:
            errors.append(f"{rel}: hreflang 未自指 {(lang, CANON[rel])}")

    # 3. 站内链接
    valid = set(CANON.values()) | {BASE + "/"}
    for rel, p in pages.items():
        for href in p.links:
            path = to_path(href)
            if path is None:
                continue
            if path.endswith(ASSET_EXT) or path.startswith("/screens/") or path.startswith("/assets/"):
                continue
            if path.startswith("/dl/"):
                continue
            if path not in valid:
                errors.append(f"{rel}: 站内链接指向非规范地址 {href}")

    # 4. sitemap
    sm = (WEB / "sitemap.xml").read_text(encoding="utf-8")
    locs = {u.replace(BASE, "") or "/" for u in re.findall(r"<loc>([^<]+)</loc>", sm)}
    if locs != SITEMAP_EXPECTED:
        errors.append(f"sitemap: 缺 {sorted(SITEMAP_EXPECTED - locs)} 多 {sorted(locs - SITEMAP_EXPECTED)}")
    for rel in NOINDEX:
        path = CANON.get(rel)
        if path and path in locs:
            errors.append(f"sitemap: 收录了 noindex 页 {path}")

    if errors:
        print(f"❌ 发现 {len(errors)} 处不一致：")
        for e in errors:
            print("  -", e)
        return 1
    print(f"✅ SEO 一致性通过：{len(pages)} 个页面，{len(SITEMAP_EXPECTED)} 条 sitemap，hreflang 集群 {len(CLUSTER)} 语言")
    return 0


if __name__ == "__main__":
    sys.exit(main())
