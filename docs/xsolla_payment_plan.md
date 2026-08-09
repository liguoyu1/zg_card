# Xsolla 支付接入规划（Web 端）

## 一、目标平台分流（现状已基本符合）

| 平台 | 支付通道 | 说明 |
|---|---|---|
| Web（kIsWeb） | Xsolla PayStation | 浏览器打开支付页，webhook 回调加钻 |
| iOS | Apple StoreKit（IAP） | 强制走官方支付，不开放其他通道 |
| Android | Xsolla 优先，失败降级 Google IAP | 保留现状 |

分流逻辑在 `shop_screen.dart:_buyGem`：iOS 直接 `_buyIAP`；其余平台 `XsollaPaymentService.purchase`，Android 失败再降级 IAP。

## 二、现状能力盘点（已实现）

- 客户端 `lib/data/xsolla_payment_service.dart`：create-token → `launchUrl` 打开 PayStation
- 服务端 `POST /api/payment/create-token`：JWT 鉴权 + 要求注册邮箱 + 创建 PayStation token
- 服务端 `POST /api/payment/webhook`：签名校验 → `order_paid/payment` → `addGemsFromXsolla`（externalId 幂等）
- `GEM_SKU_MAP`：gem_60/300/600/1500/3000

## 三、差距与风险（按优先级，均涉及资金，需修复后上线）

1. **webhook 加钻丢单风险（P0）**
   - 现状：校验通过后**异步**加钻并立即返回 204；`addGemsFromXsolla` 失败被 `.catch` 吞掉 → 用户已付款但钻石丢失，Xsolla 不会重试。
   - 修复：改为**同步处理**；失败返回 500（Xsolla 会重试）；成功返回 204。加 Redis NX 锁防并发重试双发（参考 `verifyIAPReceipt`）。

2. **webhook 签名算法需核对（P0）**
   - 现状：`sha1(rawBody + secret)` 拼接式哈希（官方文档算法），`verifyWebhookSignature` 兼容两种算法，并加测试。

3. **同 SKU 双平台钻石数不一致（P1）**
   - `GEM_SKU_MAP`（Xsolla）：gem_300=300；`IAP_GEM_MAP`（Apple）：gem_300=350（含赠送）。
   - 决策：统一数值（推荐全部按无赠送价，价格一致）；或在 Xsolla 后台按平台配置价格差。需产品确认。

4. **Web 支付完成后余额不回显（P1）**
   - 现状：`_buyGem` web 分支 `delay 3s + _refresh()`，只读本地存档 → 服务端已加钻但界面不变。
   - 修复：支付页返回后客户端调新接口 `POST /api/balance/pull`（服务端返回余额），本地按"服务端 > 本地"的差值并入（`local += server - local`），与现有 sync 对账互补；随后 `bumpDataVersion + _refresh`。

5. **PayStation token 未带商品/金额（P1）**
   - 现状：token 请求只含 settings/user，商品与价格依赖 Xsolla 后台 catalog。
   - 核对：确认后台已建 5 个 SKU 商品（ID 与 `GEM_SKU_MAP` 键一致）、价格、货币；或改为 token 请求体传 `purchase.items`（需 Xsolla 后台"无商品目录"模式）。

6. **环境变量确认（P1）**
   - Railway 需配置：`XSOLLA_MERCHANT_ID`、`XSOLLA_API_KEY`、`XSOLLA_PROJECT_ID`、`XSOLLA_WEBHOOK_SECRET`；Xsolla 后台 webhook URL 指向 `https://app-server-production-39d1.up.railway.app/api/payment/webhook`。

## 四、上线配置清单（Xsolla 后台）

1. 商户控制台：创建商品 gem_60…gem_3000（ID 与代码 SKU 一致），设置 USD 价格
2. 支付设置 → Webhooks：URL 指向 `/api/payment/webhook`，开启 `order_paid`/`payment` 通知
3. 复制 Webhook Secret / Merchant ID / API Key / Project ID → Railway 环境变量
4. 沙盒模式联调：Xsolla 测试卡完成一笔 → 验证 webhook 加钻 + 幂等（重复推送不双发）

## 五、验证清单

- [ ] Web 端购买 gem_60：PayStation 打开 → 测试卡支付 → 返回后钻石 +60、流水出现 `Xsolla购买`
- [ ] webhook 重复推送同一 txnId → 不重复加钻
- [ ] webhook 签名错误 → 拒绝（400）
- [ ] 服务端故障时 webhook 返回非 204 → Xsolla 重试后补发
- [ ] iOS 端不受影响：仍走 IAP（`_buyGem` 平台分支）
- [ ] 余额对账：web 支付后本地余额与服务端一致（pull 逻辑）

## 六、实施顺序

1. P0：webhook 同步处理 + HMAC-SHA1 + Redis 锁 + 测试
2. P1：`/api/balance/pull` + web 端支付返回后调起
3. P1：SKU 钻石数统一（产品决策）
4. 配置联调（需 Xsolla 后台信息）
