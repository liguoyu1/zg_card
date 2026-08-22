# 冷启动获客行动清单（已就绪，待人工执行）

> 代码侧可做的工作已全部完成。以下是需要**人工账号操作**的执行清单。
> 素材文档都已备好，直接照抄。

## 0. 已完成（代码侧，已部署到 wscard.games）
- ✅ SEO：index.html 加了 title/description/OG/Twitter Card/JSON-LD 结构化数据，新增 robots.txt + sitemap.xml，加了对爬虫可见的游戏介绍文本
- ✅ 首页补入口：每日任务 / 成就 / 排行榜 / 训练（之前是无入口孤儿页面）
- ✅ 新手引导：首次打开自动显示 5 步教程（已用像素亮度验证生效）
- ✅ 分享裂变：邀请链接 `?ref=playerId` 已完整（复制+3天有效期+注册带 referrer）
- ✅ 营销素材：itch_io_post / google_play_post / facebook_ad_copy / reddit_post / tiktok_post / youtube_promo 等全部写好了

## 1. 搜索引擎收录（0 成本，优先做，1-2 周见效）
- [ ] 打开 Google Search Console → 添加资源 `https://wscard.games/` → 提交 `sitemap.xml`
- [ ] 打开 Bing Webmaster → 添加站点 → 提交 sitemap
- [ ] 百度搜索资源平台 → 提交 `https://wscard.games/`（中国用户靠百度/搜狗）
- [ ] 说明：Flutter 站现在可被索引了（有描述/结构化数据/robots/sitemap），提交后 1-2 周出收录

## 2. itch.io 网页版（0 成本，国际独立游戏门户）
- [ ] 按 `itch_io_post.md` 逐字段填写（已含标题/描述/分类/嵌入选项）
- [ ] 上传包：`flutter build web --release` 后压缩 `build/web/` 为 zip 上传
- [ ] 已有关联：`https://guoyuli.itch.io/warring-states-card`（首页有链接，需确认 Web 版上传完成）

## 3. 视频/图文内容种草（0 成本，中文圈）
- [ ] 抖音/快手：竖屏玩法切片，简介放 `wscard.games`，标题蹭"战国卡牌 免费 网页游戏"
- [ ] B站：长视频讲解（用 `youtube_promo.md` 改编）
- [ ] 贴吧/知乎/小红书：发帖（`reddit_post.md` 中文版）
- [ ] TapTap：发开发者日志（`itch_io_devlog_post.md` 可改）

## 4. 国际渠道（可选）
- [ ] CrazyGames / Poki 提交（按平台要求提供 iframe 版本）
- [ ] Google Play 上传（`google_play_post.md` 已备；注意需 APK 签名）

## 优先级总结
搜索引擎(1) > itch.io(2) > 中文内容(3)。三者都能带来流量，按顺序执行。
核心提醒：这些都是**免费流量**，做了游戏才有人来；现在没人是因为搜索引擎和门户根本看不到这个站。
