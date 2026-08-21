# itch.io 发布填报内容 — 战国卡牌对战游戏（Web 端）

> 官网: https://wscard.games/ | 技术: Flutter Web | 版本: 1.0.0
> 制作: [你的名字/团队名] | 支持邮箱: zgfylgy@163.com

---

## 1. 基本资料 (Create project)

| 字段 | 填写内容 |
|---|---|
| Project Title | **Warring States: Card Battles**（或: 战国卡牌 Warring States Card） |
| Project URL | 自动生成，可用 `warring-states-card` |
| Classification | **Games** |
| Kind of project | **Web**（HTML — 上传 `flutter build web --release` 的 `build/web/` 压缩包） |
| Release status | **Released** |
| Price | **Free**（免费游玩；钻石购买走 Xsolla 外部 IAP，不影响免费发布） |

---

## 2. Short description（≤500 字符，列表页展示）

> Turn the Warring States era into a card battler. 7 schools of thought, 196 cards, legendary heroes like Sun Tzu and Mozi — 3-minute matches, free to play. Strategy. History. Chaos.

---

## 3. Details & Embed options

| 字段 | 填写内容 |
|---|---|
| Genre | **Strategy**（另选 Card Game 副类型） |
| Tags | `card-game` `strategy` `turn-based` `warring-states` `ancient-china` `history` `2d` `free-to-play` `web-game` `collection` |
| Input | Keyboard: none required · Mouse: click & drag · Touch: 支持（手机浏览器可玩） |
| Embed | **Allow everyone to embed this game**（推荐：可被其他网站/社群嵌入引流） |
| Playable on mobile | ✓ 勾选（Flutter Web 自适应） |
| Viewer | 保持默认 |

---

## 4. Description（长文案，支持 HTML）

```html
<p>战国七雄，百家争鸣。这一次，历史在你手中。</p>

<p><b>Warring States: Card Battles</b> is a strategic card battler set in the
Warring States era of ancient China. Seven schools of thought become
seven playstyles — the Militarists charge, the Legalists enforce,
the Mohists build siege engines, the Daoists outlast you.</p>

<h3>Featured</h3>
<ul>
  <li>⚔️ <b>7 schools = 7 playstyles</b> — Militarist, Legalist, Confucian, Daoist, Mohist, Yinyang, Zongheng</li>
  <li>🃏 <b>196 unique cards</b> — 74 common, 69 rare, 36 epic, 17 legendary</li>
  <li>👑 <b>21 legendary heroes</b> — Sun Tzu, Confucius, Laozi, Mozi, the Ghost Valley Master…</li>
  <li>🧠 <b>Real strategy</b> — combos, board control, one-card comebacks</li>
  <li>⏱️ <b>3-minute matches</b> — quick games, deep decisions</li>
  <li>🌍 <b>11 languages</b> — EN, 中文, 繁體, 日本語, Français, Deutsch, Español, Русский, ไทย, Melayu, Filipino</li>
  <li>📱 <b>Play anywhere</b> — browser on desktop or mobile</li>
</ul>

<h3>How to play</h3>
<p>Click or drag to play cards, summon minions, cast spells, and swing
weapons. Out-think your opponent and win the war.</p>

<h3>Free to play</h3>
<p>The core game is completely free. Optional in-game gems are purchased
through our official store — no pay-to-win, skill decides the battle.</p>

<h3>Credits</h3>
<p>Developed by [你的名字/团队名] · Made with Flutter<br>
Support: zgfylgy@163.com · Play online: <a href="https://wscard.games/">https://wscard.games/</a><br>
Privacy: <a href="https://wscard.games/privacy">Privacy Policy &amp; Terms</a></p>
```

---

## 5. Media（图片素材）

| 字段 | 要求 | 来源 |
|---|---|---|
| Cover image | 推荐 **630×500**（最小 315×250） | `poster_gen/poster_v2.png`（需裁成 630×500 比例） |
| Screenshots | 4-6 张，推荐 16:9 或 4:3 | `poster_gen/promo_v4/` 卡面图，或运行 Web 版截图 |
| GIF/movie | 可选：竖屏视频 `poster_gen/out/`（make_video 产物） |
| Icon | 可选 | `assets/icons/app_icon.png` |

---

## 6. 内容分级与其他

| 字段 | 填写内容 |
|---|---|
| Age rating (PEGI/ESRB 类) | **Everyone** — 奇幻战斗，无血腥写实 |
| Content rating keywords | `no blood` `no gore` `no sexual content` `no scary elements` |
| Community | 评论开启：✓ 允许评论与评分 |
| Privacy | 默认 |
| Contact/URL | https://wscard.games/ |
| Buy button | 免费游戏无需设置；若加捐赠按钮可选 `itch.io` 打赏 |
| Show in search results | ✓ 允许收录（带来自然流量） |

---

## 7. 发布检查清单

- [ ] 本地执行 `flutter build web --release` → 产出 `build/web/`
- [ ] 压缩 `build/web/` 内容（**index.html 在 zip 根目录**）→ `web.zip`，上传到 itch.io Web project
- [ ] 上传 cover（630×500）+ 4-6 张截图
- [ ] 填好上面第 2-6 节内容
- [ ] 发布后实测嵌入页可玩（卡牌正确渲染、字体/音效资源加载）
- [ ] 在官网/TikTok/FB 简介加 itch.io 链接分流

---

## 8. 注意事项

- **Web 上传格式**：itch.io 只接受 zip，`index.html` 必须在压缩包根目录，不要包一层文件夹
- **外部支付**：Xsolla 钻石 IAP 与 itch.io 无关，免费发布不冲突
- **版本更新**：每次更新重新打包 `build/web/` 上传同一项目即可