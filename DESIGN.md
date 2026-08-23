# DESIGN.md — Warring States Card · Marketing Pages

Single source of truth for the three promotional pages: `web/landing.html`, `web/promo.html`, `web/download.html`.

## Discovery

- **Artifact**: Marketing / landing pages (3 variants: generic promo, download center, ad/promo page) for a free-to-play web card battler.
- **Audience**: Global players (EN default, zh/ja switchable). Desktop + mobile.
- **Primary action**: Play Now (landing/promo) · Download (download page).
- **Brand adjectives**: confident · premium · focused · evocative.
- **3-word essence**: *product-led, quiet, sharp*.

## Direction (committed)

Product-first, modern restraint. The **real game is the hero** — actual gameplay screenshots
(`web/screens/battle.webp`, `heroes.webp`, `collection.webp`, `key.webp`, `cover.webp`)
sell the game; no raw character-portrait dumps. Quiet editorial layouts, generous whitespace,
precise rules. This intentionally avoids the "dark + gold + Cinzel + feature-card" epic-game cliché.

## Aesthetic commitment

Dark, warm near-black canvas; the screenshots supply the color. One gold accent reserved for the
primary CTA and select highlights. Sharp geometry, hairline-defined edges (no diffuse-shadow
stacking), radius 8-12px only. Typography does the heavy lifting.

## Typography

- **Display**: `Archivo` (700/800) — confident grotesque for headlines, tabs, and numerals.
- **Body / UI**: `Noto Sans` — clean, full CJK coverage for zh/ja.
- **CJK display**: `Noto Serif SC` used for CJK emphasis accents only.
- Scale ratio ~1.25 (minor-third), 6 steps. 40px tabular numerals for stats.

## Color (OKLCH-derived, hex for runtime)

- `--bg: #0F0C0A` near-black warm
- `--surface: #161210`
- `--surface-2: #1E1915`
- `--border: #2A2420`
- `--text: #E9E2D6` off-white
- `--text-muted: #A69B8A`
- `--text-dim: #6E6457`
- `--accent: #D4A017` goldBright (primary CTA)
- `--accent-ink: #171005` (text on accent)
- School accents (semantic, used sparingly): bingjia `#C0392B`, fajia `#2E86C1`,
  rujia `#27AE60`, daojia `#8E44AD`, mojia `#D35400`, yinyangjia `#1ABC9C`, zonghengjia `#F39C12`.

## Tokens

- Spacing base 4px; section gaps 96-128px, intra-group 16-24px.
- Radius: 8px (controls) · 12px (media/frames) · max 16px.
- One edge treatment: defined 1px border in `--border`; **no** shadow stacking on the same edge.
- Motion: 160-240ms, cubic-bezier(0.16,1,0.3,1), transform+opacity only. Respect prefers-reduced-motion.

## Signature move

**The full-bleed battle screenshot as the product hero.** The headline sits on a clean, quiet
canvas above a hard-edged, real screenshot — product-led, not poster-led. Screenshots recur as
framed, captioned editorial strips ("See the game").

## Craft decisions

- Sticky minimal top bar: wordmark left, language switcher right.
- Hero: light headline + single primary CTA over a darkened real screenshot; one secondary action.
- "See the game": horizontal, captioned screenshot strip (battle / heroes / collection) — the proof.
- Schools: compact data rows with per-school color dots + name + one-line — not portrait cards.
- Stats: tabular numerals, clean rule-separated line.
- Platforms: quiet labeled list with real download targets.
- Final CTA: screenshot-tinted band, repeat primary action.
- Interactive states: buttons defined across hover/focus/active; focus via box-shadow, not lost outline.
- Imagery: real screenshots only, regraded to the warm dark palette by the overlay gradient.

## Accessibility

WCAG 2.2 AA: 4.5:1 body contrast (muted text checked on `--bg`), 3:1 large text. Visible focus.
Reduced-motion honored. Meaning never by color alone (school dots also carry names).

## Slop-audit (result)

Passed against checklist: no purple/indigo gradient; no gradient text; no cream-by-reflex;
primary face is not Inter/Roboto/system; no icon-tile-above-heading feature cards; not the
hero+3cards+testimonials+CTA boilerplate; no side-tab accent borders; no hairline+wide-shadow
on one element; radius ≤16px; no glassmorphism; no emoji-as-icon; no image-scale-on-hover as
default; no stock/AI imagery (real screenshots instead); spacing varies by relationship;
single named signature move present.

## Changelog

- 2026-08-23 v3: Rebrand from "dark+gold+portrait-dump" to product-led, screenshot-first.
  Real game screenshots added at `web/screens/*.webp`. Type switched Cinzel → Archivo + Noto Sans.
  Removed raw portrait galleries and emoji icons. This document created.

- 2026-08-23 v4 (deployed 24fddd7): Shipped the product-first design across all three pages.
  landing.html: full-bleed battle-screenshot hero + "See it in motion" 3-shot strip + 8-school
  grid + 4-stat band + editorial "Why" + platform cards + screenshot final CTA.
  promo.html: battle-hero + stats band + 8-school chips + 4-point "Why" + platform row.
  download.html: browser-vs-Android cards + 3-step quick start + 3-shot gallery.
  All en/zh/ja i18n, default English, real screenshots served at /screens/*.webp.
  Verified live: all screenshots load (0 broken), no horizontal overflow, 3-lang switching works.
