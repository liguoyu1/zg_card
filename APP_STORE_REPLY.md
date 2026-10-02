# App Store 审核回复与操作说明（战 1.0 (8) 被拒）

三个问题：
1. **5.1.1(v) — IAP 要求注册**：iOS 内购前必须先注册账号（收集个人信息）。
2. **5.1.1(v) — 无账号删除**：支持创建账号却没有「删除账号」功能。
3. **2.3.6 — 年龄分级**：App 里没有 Parental Controls / Age Assurance，App Store Connect 分级却勾了「In-App Controls」。

已按下方处理完毕。改完后 **必须重新部署后端（Railway）**，再自增构建号重新提交。

---

## 一、App Store Connect 后台操作（2.3.6 — Age Rating）

1. 登录 App Store Connect → 你的 App → **App 信息**（App Information）。
2. 找到 **年龄分级（Age Rating）** → 点「编辑」。
3. 把 **儿童安全分级（Kids categories）** 相关的 **「In-App Controls」/「Parental Controls」/「Age Assurance」** 全部设为 **None**。
   - 逐项确认：每个开关（如 Unrestricted Web Access、Digital Purchases 之外的控制项）改为 **None**。
4. 保存。
5. 把下方的回复文案粘贴到 **Resolution Center**，把操作说明 + 屏录操作也一并说明。

> 注意：iOS 现在支持「购买前匿名（设备账号）购买」但**不涉及家长控制功能**，App 本身没有需要分级的内容控制，所以分级应标 None。

---

## 二、App Review 回复文案（Resolution Center，英文）

```
Hello App Review Team,

Thank you for the detailed review. We have addressed all three issues in
version 1.0 (9). Please find our responses below.

1) Guideline 5.1.1(v) — "App requires registration before purchasing
   non-account-based in-app purchases."
   We now allow anonymous purchases on iOS. When a user who is not signed
   in purchases gems, the app silently creates a device-bound account on
   the device (identified only by a random, locally generated device
   identifier; no email, name, or other personal information is collected
   or required). The purchase is still validated server-side through the
   App Store receipt, so it is safe from fraud and can be restored. A
   registered account remains optional and is only used if the player
   wants to sync progress across devices. If a player who purchased
   anonymously later creates an account, the anonymous session is upgraded
   in place (same player ID) instead of creating a new account, so the
   already-purchased gems and progress carry over to the new device.
   As a result, purchasing is now possible without any registration or
   personal information.

2) Guideline 5.1.1(v) — "App supports account creation but has no
   in-app account deletion."
   We added a full in-app account deletion flow. A signed-in user can tap
   the account menu in the app and choose "Delete Account". After two
   confirmation prompts, the app permanently deletes the account and all
   of its cloud data (purchases, cards, match history, save data) on the
   server, and clears all local data on the device. A screen recording of
   this flow is attached in the Notes field of App Review Information for
   your convenience.

3) Guideline 2.3.6 — "Age Rating says 'In-App Controls' but the app has
   no Parental Controls or Age Assurance."
   We corrected this. The app does not implement parental controls or age
   assurance features, so we have set the age rating "In-App Controls"
   option to "None" in App Store Connect. The current version reflects
   this change.

Thank you again, and please let us know if any further information is
needed.
```

---

## 三、App Review Information → Notes 附件（强烈建议）

在 App Store Connect → App 版本 → **App Review Information → Notes** 里填写：

```
A screen recording demonstrating the account deletion flow is attached.
Steps in the video: sign in with the demo account → tap the account menu
(top-right) → tap "Delete Account" → confirm twice → app shows
"Account deleted". Both cloud and local data are permanently removed.

Demo account: <在此填写 demo 邮箱/密码>

Note: gems can also be purchased without signing in — the app silently
uses an anonymous device-bound session (no personal information), and
registering later upgrades the same session so purchases are preserved.
```

并在该处**上传屏录视频**（演示删除账号：进入菜单 → 删除账号 → 二次确认 → 提示已删除）。

---

## 四、重新提交前 Checklist

- [x] **后端已重新部署**：`https://app-server-production-39d1.up.railway.app` 部署 `9cb47631`（2026-10-02 19:19）已 SUCCESS，
      线上实测 `migrateToken` 原地升级生效（注册前后 playerId 一致）、`/api/auth/delete` 彻底删除可用。
      ⚠️ 注意：app-server **不走 GitHub 自动部署**，改后端代码后必须在 `server/` 目录执行 `railway up --service app-server`。
- [x] 部署后自测（已通过，测试账号已清理）：

```bash
# 1) 匿名设备账号购买会话
curl -s -X POST https://app-server-production-39d1.up.railway.app/api/auth/device \
  -H 'Content-Type: application/json' -d '{"deviceId":"<device-uuid>"}'
# 2) 拿上一步 token 验证注册升级（返回的 player.id 应与第 1 步完全相同）
curl -s -X POST https://app-server-production-39d1.up.railway.app/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"t@t.com","password":"123456","name":"T","migrateToken":"<上一步 token>"}'
# 3) 清理测试账号
curl -s -X POST https://app-server-production-39d1.up.railway.app/api/auth/delete \
  -H "Authorization: Bearer <token>" -H 'Content-Type: application/json' -d '{}'
```

- [ ] 构建号自增（如 1.0 (9)）。
- [ ] App Store Connect 年龄分级 → In-App Controls 设为 **None**。
- [ ] Resolution Center 粘贴上方英文回复。
- [ ] App Review Information Notes 说明删除账号流程 + 上传屏录。
