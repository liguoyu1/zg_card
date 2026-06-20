# Phase 2：出海基建 — i18n + IAP + 广告

## 总览

- **目标**：完成香港/台湾/东南亚华语市场发布的最低可行基建
- **策略**：字符串 Map 方案（JSON key-value），UI 层 ~72条 + 数据层 ~738条
- **包新增**：`purchases_flutter` (RevenueCat)、`google_mobile_ads` (AdMob)
- **总工作量预估**：5-7个工作日

---

## Step 1：i18n 基础设施（1天）

### 1.1 创建 LocaleService

```
lib/l10n/
├── locale_service.dart    ← 核心服务：加载 JSON、缓存、t() 方法
├── zh.json                ← 简体中文（当前内容，作为 fallback locale）
├── zh_TW.json             ← 繁体中文
└── en.json                ← 英文
```

**`LocaleService` 接口设计：**

```dart
class LocaleService {
  static final LocaleService I = LocaleService._();
  
  Locale _locale = const Locale('zh');
  late Map<String, String> _strings;

  Future<void> init({Locale locale = const Locale('zh')}) async {
    _locale = locale;
    final code = locale.languageCode;
    // 读取 assets/l10n/$code.json
    _strings = ...;
  }

  String t(String key, {Map<String, String>? args}) {
    var s = _strings[key] ?? '⚠$key';
    if (args != null) {
      for (final e in args.entries) {
        s = s.replaceAll('{$e.key}', e.value);
      }
    }
    return s;
  }

  void setLocale(Locale locale) => init(locale: locale);
}
```

### 1.2 JSON 结构设计

两层分离：

```
UI 键:     "adventure.title" / "home.title" / "pack.btn_open"
数据键:    "card.B001.name" / "card.B001.description" / "card.B001.flavor"
           "hero.H_B001.name" / "hero.H_B001.powerName" / "hero.H_B001.powerDescription"
           "mission.ch1_m1.name" / "mission.ch1_m1.description"
           "chapter.ch1.name" / "chapter.ch1.description"
           "difficulty.easy" / "difficulty.normal" ...
           "faction.bingjia" / "faction.fajia" ...
           "kingdom.qi" / "kingdom.chu" ...
```

总条目预估：
| 类别 | 条目 | 示例 |
|------|------|------|
| UI 屏幕文字 | ~72 | `"home.title": "战国卡牌"` |
| 卡牌 (198 张 × 3 字段) | ~594 | `"card.B001.name": "魏武卒"` |
| 英雄 (28 × 4 字段) | ~112 | `"hero.H_B001.name": "孙膑"` |
| 关卡 (30 × 2 + 3 × 2) | ~66 | `"mission.ch1_m1.name": "初战井陉"` |
| 公共标签 (难度/学派/国家) | ~25 | `"difficulty.easy": "简单"` |
| **合计** | **~810** | |

### 1.3 zh.json 生成策略

**不手动写**——编写一个 `tool/generate_l10n_json.dart` 脚本，自动从现有 Dart 源文件中提取所有字符串并生成 zh.json。

原理：
- 解析 `_difficultyLabel()` 中的 switch case
- 扫描所有 Text() / SnackBar() 中的字符串字面量
- 从卡片/英雄/任务数据定义中提取 name/description/flavor
- 输出到 `assets/l10n/zh.json`

这样 zh.json 永远是精确的，且后续增删卡片时只需要重新运行脚本。

### 1.4 数据层适配

卡片/英雄数据目前是 `const List<Card>` 和 `const List<Hero>`，编译期已固定。

**改造方案**：新增 `LocaleDataFactory`：

```dart
class LocaleDataFactory {
  /// 获取当前 locale 下的所有卡牌
  static List<Card> getAllCards() {
    final keys = ...; // 从 JSON 中获取所有 card.* 键
    return keys.map((key) {
      final id = ...;
      return Card(
        id: id,
        name: LocaleService.I.t('card.$id.name'),
        description: LocaleService.I.t('card.$id.description'),
        flavor: LocaleService.I.t('card.$id.flavor'),
        // 其他字段从原始数据中提取（cost, attack, health 等不受 locale 影响）
      );
    }).toList();
  }
}
```

为了不丢失非文本字段（cost/attack/health/rarity 等），需要保留一份模板数据（可以是当前 const list 的副本），从中提取结构字段，文本字段从 JSON 读取。

**更简洁的方案**：保留卡片数据文件，但将字符串引用改为 key：

```dart
// 现有方式
Card(id: 'B001', name: '魏武卒', description: '战吼：...', ...)

// 改造后 - 使用 string key
Card(id: 'B001', nameKey: 'card.B001.name', descriptionKey: 'card.B001.description', ...)
```

但这样每个 Card 实例需要额外字段。更适合在 factory 中按 locale 构建。

---

## Step 2：字符串提取脚本（0.5天）

### 2.1 脚本设计

```
tool/generate_l10n_json.dart
```

功能：
1. 读取 `lib/data/cards/*.dart` 提取所有卡片 ID + name + description + flavor
2. 读取 `lib/data/heroes/heroes_data.dart` 提取所有英雄 ID + name + powerName + powerDescription + flavor
3. 读取 `lib/domain/services/adventure_manager.dart` 提取所有关卡名+描述+章节名+描述
4. 扫描 `lib/presentation/screens/*.dart` 提取所有 Text() 字符串和硬编码标签
5. 输出格式化的 `assets/l10n/zh.json`
6. 输出提取统计（总条目数、各分类数量）

运行方式：
```
dart tool/generate_l10n_json.dart
```

### 2.2 JSON 文件存放

```
assets/l10n/
├── zh.json       ← 由 generate 脚本自动生成
├── zh_TW.json    ← 人工翻译（基于 zh.json 复制后修改）
└── en.json       ← AI 翻译 + 人工校对
```

**zh.json 的 assets 注册**：需要在 pubspec.yaml 中添加：
```yaml
flutter:
  assets:
    - assets/l10n/
```

---

## Step 3：翻译生成（并行，1天）

### 3.1 繁体中文（zh_TW.json）

- 直接从 zh.json 复制，做词汇转换：
  - 「战国」→「戰國」
  - 「孙膑」→「孫臏」
  - 「魏武卒」→「魏武卒」（不变）
  - 「战吼」→「戰吼」
  - 「嘲讽」→「嘲諷」
- 工具辅助：OpenCC（Open Chinese Convert）命令行批量转换
- 特殊处理：36个英雄名/72个地名（如「井陉」→「井陘」）

### 3.2 英文（en.json）

- AI 翻译（ChatGPT/Claude）整份 zh.json → 英文
- 关键要求：
  - 卡牌名保留历史感（"魏武卒" → "Wei Elite Warriors" 而非 "Wei Soldier"）
  - 游戏术语统一（"战吼" → "Battlecry" 保持与炉石一致）
  - 风味文本保留文学性
- 人工校对重点：确保游戏术语的一致性

### 3.3 归档策略

三种语言视为"完整翻译"，不依赖工具的增量更新。一次翻译到位后，后续新增卡牌时才需要同步更新三个 JSON。

---

## Step 4：代码字符串替换（1-1.5天）

将屏幕代码中的硬编码字符串替换为 `LocaleService.I.t('key')` 调用。

### 4.1 屏幕替换清单

| 文件 | 替换条目 | 工作量 | 说明 |
|------|---------|--------|------|
| `home_screen.dart` | ~8条 | 小 | `'战国卡牌'` `'开始对战'` `'训练模式'` 等 |
| `adventure_screen.dart` | ~12条 | 小 | `'简单'` `'普通'` `'冒险模式'` `'BOSS'` 等 |
| `pack_screen.dart` | ~9条 | 小 | `'开包'` `'金币不足'` `'再来一包'` 等 |
| `collection_screen.dart` | ~12条 | 小 | `'收藏'` `'还没有卡牌'` `'关闭'` 等 |
| `game_screen.dart` | ~16条 | 中 | 需要找全所有 Text() 和 SnackBar |
| `hero_select_screen.dart` | ~15条 | 中 | 学派标签、难度名 |
| `training_screen.dart` | ~10条 | 小 | 一些 UI 标签 |
| `deck_edit_screen.dart` | ~6条 | 小 | |
| `leaderboard_screen.dart` | ~2条 | 极小 | |
| `basic_card_screen.dart` | ~1条 | 极小 | |

### 4.2 数据层替换

这是最关键的步骤：

**卡片数据**：建立一个 `CardDataProvider`，从 JSON 读取文本字段 + 从原始 const 列表读取结构字段（cost/attack/health/rarity/keywords 等）

```dart
// lib/domain/services/card_data_provider.dart
class CardDataProvider {
  /// 获取当前语言的所有卡牌
  static List<Card> getAllCards() {
    // 从结构数据提取非文本字段
    final structural = _allStructuralCards; // 无文本的 Card 骨架
    return structural.map((c) => c.copyWith(
      name: LocaleService.I.t('card.${c.id}.name'),
      description: LocaleService.I.t('card.${c.id}.description'),
      flavor: LocaleService.I.t('card.${c.id}.flavor'),
    )).toList();
  }
}
```

改造后，所有 `getAllCards()` 调用改为 `CardDataProvider.getAllCards()`。

**英雄数据**：同理，创建 `HeroDataProvider`。

**冒险数据**：`AdventureManager` 现在从 JSON 读取章节名/关卡名。

---

## Step 5：Locale 切换 UI（0.5天）

### 5.1 设置页面

在 HomeScreen 增加语言切换入口：

```
HomeScreen → 右上角菜单 → 语言设置
                          ├── 简体中文
                          ├── 繁體中文
                          └── English
```

### 5.2 切换逻辑

```dart
void _switchLanguage(BuildContext context, Locale locale) async {
  await LocaleService.I.setLocale(locale);
  // 重启整个 App 以刷新所有字符串
  // 或用状态管理触发 rebuild
}
```

最简单的方案：切换 locale 后调用 `runApp` 重新挂载（对游戏类 app 是可接受的）。

---

## Step 6：RevenueCat 接入（1天）

### 6.1 依赖

```yaml
dependencies:
  purchases_flutter: ^7.0.0
```

### 6.2 购买服务

```dart
// lib/domain/services/purchase_service.dart
class PurchaseService {
  static final PurchaseService I = PurchaseService._();

  bool _initialized = false;
  Purchases? _purchases;

  // 商品定义
  static const String productRemoveAds = 'remove_ads';  // non-consumable
  static const String productGoldSmall = 'gold_small';   // consumable
  static const String productGoldMedium = 'gold_medium';
  static const String productGoldLarge = 'gold_large';

  Future<void> init(String apiKey) async {
    _purchases = await Purchases.setUp(apiKey);
    await _purchases!.restorePurchases(); // 恢复已有购买
    _initialized = true;
  }

  Future<bool> purchase(String productId) async { ... }
  Future<bool> get isAdsRemoved async { ... }
}
```

### 6.3 接入点

| 位置 | 对接 |
|------|------|
| 开包页面 | 金币不足时弹出购买金币包 |
| HomeScreen | 右上角增加"移除广告"购买入口 |
| 冒险结算 | 双倍金币弹窗 → 看广告/购买 |

### 6.4 RevenueCat 配置

需要在 RevenueCat 后台创建：
1. `remove_ads` — Non-Consumable
2. `gold_small` — Consumable (100金币)
3. `gold_medium` — Consumable (500金币)
4. `gold_large` — Consumable (1200金币)

iOS 和 Android 分别关联 App Store Connect / Google Play Console 的商品 ID。

---

## Step 7：AdMob 接入（1天）

### 7.1 依赖

```yaml
dependencies:
  google_mobile_ads: ^5.0.0
```

### 7.2 AdService 实现

替换当前的 `NoOpAdService`，创建 `lib/infrastructure/ad/google_ad_service.dart`：

```dart
class GoogleAdService implements AdService {
  @override
  bool get isInitialized => _initialized;
  bool _initialized = false;

  // 广告位 ID（测试模式下使用 AdMob 提供的测试 ID）
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  @override
  Future<bool> initialize() async {
    MobileAds.instance.initialize();
    _initialized = true;
    return true;
  }

  @override
  Future<bool> showRewardedAd({required String placementId}) async {
    // ... 加载并展示激励视频广告
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    // ... 加载并展示插屏广告
  }
}
```

### 7.3 广告位映射

| 场景 | 广告类型 | 广告位 ID (常量) |
|------|---------|-----------------|
| 免费开包 | Rewarded | `AdPlacement.freePack` |
| 金币翻倍 | Rewarded | `AdPlacement.goldBonus` |
| 关卡复活 | Rewarded | `AdPlacement.revive` |
| 主菜单→对战 | Interstitial | — |
| 对战→主菜单 | Interstitial | — |

### 7.4 插屏触发策略

- 不每次切换都弹插屏（用户体验差）
- 策略：每完成 3 次导航弹一次，且两次间隔至少 60 秒
- 对战结束后不弹（用户刚打完，情绪中）

---

## Step 8：整体集成（0.5天）

### 8.1 main.dart 启动流程

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. i18n 初始化
  await LocaleService.I.init();
  
  // 2. RevenueCat
  await PurchaseService.I.init('your_revenuecat_key');
  
  // 3. AdMob
  final adService = GoogleAdService();
  await adService.initialize();
  
  // 4. 标记已购买的去广告状态
  final adsRemoved = await PurchaseService.I.isAdsRemoved;
  if (!adsRemoved) {
    // 正常加载广告
  } else {
    // 不加载广告
  }
  
  runApp(const WarringStatesApp());
}
```

### 8.2 AdService 注入

需要修改 `NoOpAdService` → `GoogleAdService` 的切换条件（目前直接硬编码 NoOpAdService 的地方改为判断平台）。

---

## 文件变更汇总

### 新增文件

| 路径 | 内容 |
|------|------|
| `lib/l10n/locale_service.dart` | LocaleService 单例 |
| `assets/l10n/zh.json` | 简体中文字符串（自动生成） |
| `assets/l10n/zh_TW.json` | 繁体中文字符串 |
| `assets/l10n/en.json` | 英文字符串 |
| `lib/domain/services/card_data_provider.dart` | 卡片数据按 locale 工厂 |
| `lib/domain/services/hero_data_provider.dart` | 英雄数据按 locale 工厂 |
| `lib/domain/services/purchase_service.dart` | RevenueCat 购买服务 |
| `lib/infrastructure/ad/google_ad_service.dart` | AdMob 广告实现 |
| `tool/generate_l10n_json.dart` | 字符串提取脚本 |

### 修改文件

| 路径 | 改动 |
|------|------|
| `pubspec.yaml` | 添加 `purchases_flutter`、`google_mobile_ads`、`assets/l10n/` |
| `lib/main.dart` | 启动时初始化 LocaleService/PurchaseService/AdService |
| `lib/presentation/screens/home_screen.dart` | 字符串替换 + 语言切换入口 + IAP 入口 |
| `lib/presentation/screens/adventure_screen.dart` | 字符串替换 |
| `lib/presentation/screens/pack_screen.dart` | 字符串替换 + 看广告免费开包 |
| `lib/presentation/screens/collection_screen.dart` | 字符串替换 |
| `lib/presentation/screens/game_screen.dart` | 字符串替换 |
| `lib/presentation/screens/hero_select_screen.dart` | 字符串替换 |
| `lib/domain/services/ad_service.dart` | 无需改，接口已定义 |
| `lib/presentation/screens/leaderboard_screen.dart` | 字符串替换 |

### 删除/废弃

| 路径 | 说明 |
|------|------|
| `lib/data/cards/*.dart` | 卡片数据改为由 CardDataProvider 统一生成，原始 const 列表保留仅作为结构数据源 |

---

## 执行顺序

```
Day 1:  create_json_schema → create_locale_service → generate_zh_json
        → pubspec.yaml 更新
Day 2:  translate_zh_TW.json (OpenCC + 手动修正)
        → translate_en.json (AI + 校对)
Day 3:  screen_string_replacement (替换所有 UI 层字符串)
Day 4:  data_provider (CardDataProvider / HeroDataProvider)
        → adventure_manager 适配
Day 5:  revenuecat_setup → purchase_service → IAP UI
Day 6:  admob_setup → google_ad_service → 广告位接入
Day 7:  integration_test → 跑完整流程 → bug fix
```

---

## 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| RevenueCat 配置复杂 | 中 | 耗时 | 先用 Sandbox 测试模式 |
| AdMob 审核不通过 | 低 | 延迟 | 先用测试广告位 |
| 卡片数据 API 变更导致 generate 脚本失效 | 中 | 需修复脚本 | 拆分纯文本提取逻辑，脚本尽量通用 |
| 繁体转换后术语不统一 | 低 | 需人工检查 | 核心游戏术语做 glossary |
| 英文翻译质量不好 | 中 | 用户感知差 | 关键术语做 glossary，卡牌名用手动校对 |
