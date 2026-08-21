# Google Play 发布填报内容 — 战国卡牌对战游戏（Android 端）

> 应用 ID: com.zgcard.warring_states_card | 包内显示名: 战国卡牌 | 版本: 1.0.0 (versionCode 1)
> 制作: [你的名字/团队名] | 支持邮箱: zgfylgy@163.com | 官网: https://wscard.games/

---

## 0. 上架前必做（技术侧）

| 步骤 | 说明 | 状态 |
|---|---|---|
| 配置正式签名 keystore | `android/app/build.gradle.kts` 里 release 目前用 **debug 签名**，必须改为正式 keystore，否则 Play 拒绝 | ⚠️ 待做 |
| 确认应用 ID 唯一 | `com.zgcard.warring_states_card` 一旦上架不可改 | 确认 |
| 生成 AAB | `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` | 待做 |
| Play Console 账号 | 一次性 $25 开发者注册费 | 待做 |
| 隐私政策 URL | 有 IAP + 广告(AdMob/Adsterra)，必须提供 | 待做 |

---

## 1. 应用基本信息 (Main store listing)

| 字段 | 填写内容 |
|---|---|
| App name（名称） | **战国卡牌**（可加副名: 战国卡牌 Warring States） |
| Short description（短说明，≤80 字） | 百家争鸣卡牌对战，7大学派196卡，3分钟一局，免费开战。 |
| Full description（完整说明） | 见下方第 2 节 |
| Application type | Game |
| Category | **Game → Card** |
| Content rating | 提交 IARC 问卷（见第 5 节） |
| Privacy policy URL | **https://wscard.games/privacy**（已建 `web/privacy.html`，Vercel rewrite 生效） |
| Website | https://wscard.games/ |
| Contact email | zgfylgy@163.com |

---

## 2. 完整说明（中文，Play 用）

```
战国七雄，百家争鸣。这一次，历史在你手中。

《战国卡牌》是一款以战国时代为背景的策略卡牌对战游戏。兵家、法家、
儒家、道家、墨家、阴阳家、纵横家——七大学派，就是七种完全不同的打法。

【特色】
⚔️ 7大学派 = 7种玩法：兵家冲锋、法家律令、墨家机关、道家后发制人…
🃏 196张卡牌：普通74 / 稀有69 / 史诗36 / 传说17
👑 21位传说英雄：孙武、孔子、老子、墨子、鬼谷子…一卡翻盘
🧠 深度策略：法术连击、随从铺场、武器斩杀，套路无穷
⏱️ 3分钟一局：碎片时间随时开战
🌍 11种语言：中、繁、英、日、法、德、西、俄、泰、马来、菲律宾

【免费游玩】
核心内容完全免费。游戏内钻石可通过官方商店购买，
但胜负只由策略决定，拒绝氪金变强。

【联系我们】
客服邮箱：zgfylgy@163.com
官网：https://wscard.games/
```

---

## 3. 图形素材（Play Console 上传）

| 素材 | 规格 | 来源 |
|---|---|---|
| App icon | 512×512 PNG | `assets/icons/app_icon.png` |
| Feature graphic（特色图） | 1024×500 | 用 `poster_gen/poster_v2.png` 重新构图（横幅） |
| Screenshots（截图） | 需 **手机/平板** 截图，最小边长 320，16:9 或 9:16 | 真机/模拟器截图，竖屏优先（卡牌手游） |
| 宣传视频（可选） | YouTube 链接 | `poster_gen/out/` 竖屏视频 |

> 截图建议：竖屏 9:16，覆盖「主界面 / 对局 / 卡牌收藏 / 商店 / 英雄」5 个场景。

---

## 4. 数据安全表单 (Data safety)

> 游戏含广告(AdMob/Adsterra) + 内购(Xsolla/Google IAP)，按真实情况勾选：

| 数据类型 | 是否收集 | 用途 | 是否分享 |
|---|---|---|---|
| 用户 ID（账号/设备ID，广告用） | 是 | 广告投放、防作弊 | 是（广告平台） |
| 购买历史（内购订单） | 是 | 订单核销、客服 | 是（支付平台 Xsolla/Google） |
| 崩溃日志/性能诊断 | 可选 | 改进体验 | 否 |
| 位置/联系人/照片等 | **否** | — | — |

> 关键：勾选内容必须与**实际代码行为一致**，Play 会审核。若广告 SDK 收集设备标识，必须如实声明。

---

## 5. 内容分级（IARC 问卷）

| 问题类别 | 建议答案 |
|---|---|
| 暴力 | 轻度/无 —— 奇幻卡牌战斗，无写实血腥 |
| 血腥 | 无 |
| 性内容 | 无 |
| 语言 | 无粗俗 |
| 赌博 | 抽卡机制需如实说明（若含随机抽取，选"模拟赌博"可能提高分级） |
| 交互 | 用户生成内容/聊天（若开启需勾选） |
| 预期分级 | 大概率 **Everyone (E) / PEGI 7** |

---

## 6. 发布检查清单

- [ ] 生成正式 keystore 并配置 release 签名
- [ ] `flutter build appbundle --release` 生成 AAB
- [ ] Play Console 上传 AAB
- [ ] 填写名称/说明/截图/图标/特色图
- [ ] 提交 IARC 分级问卷
- [ ] 填写数据安全表单
- [ ] 提供隐私政策 URL
- [ ] 设置定价：**免费**（内购走 IAP，另在「应用内商品」配置）
- [ ] 提交审核（首次通常 1-7 天）

---

## 7. 内购配置提醒（涉及 Xsolla/IAP）

> 若 Android 端用 Google Play Billing（`in_app_purchase` 已集成），需在 Play Console「应用内商品」配置与代码一致的 SKU，否则无法充值。若走 Xsolla Web 支付则无需。

---

## 8. 隐私政策模板（必填，单独文件）

> 因含广告 + 内购，Play 强制要求隐私政策 URL。内容需涵盖：
> 1. 收集哪些数据（设备ID、购买记录）
> 2. 用途（广告、订单核销）
> 3. 第三方共享（AdMob/Adsterra、Xsolla/Google）
> 4. 数据存储与删除方式
> 5. 联系方式

需要的话我可以帮你起草完整隐私政策 HTML，挂到 `wscard.games/privacy`。