# 优化项 1-6 全部实施计划

## 现状摘要

| 领域 | 当前状态 | 问题 |
|------|----------|------|
| 新手教程 | 启动→主菜单, 0引导 | 新玩家0指引, 留存率低 |
| 收藏/组卡 | 简单的Grid列表, 无搜索/筛选/自定义组卡 | 收集无参与感 |
| 广告+付费 | 免费开包+复活, 无首充礼包 | ARPU值极低 |
| AI+平衡 | 4难度, 基础排序策略, 战斗系统有值Bug | AI不够聪明 |
| 开包动画 | 卡片列表淡入, 无特效 | 开包没快感 |
| UI主题 | 各屏独立色值, 无统一主题系统 | 不一致 |

---

## 1. 新手教程 (~3h)

### 机制
```
首次启动 → TutorialOverlay (覆盖在主菜单上, 带遮罩)
Step1: "欢迎来到战国卡牌" → 高亮"冒险"按钮, 提示点击
Step2: "选择你的英雄" → 自动选第一个, 提示点击"开始对战"  
Step3: "这是你的手牌" → 圈选手牌区域, "拖到场上"
Step4: "点击随从攻击" → 圈选场上随从, "点击敌方英雄"
Step5: "胜利!" → "尝试冒险模式"
完成后 → 标记 firstRun=false, 之后不再显示
```

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/presentation/widgets/tutorial_overlay.dart` | 🆕 | 全屏半透明遮罩 + 高亮圈 + 提示文字 |
| `lib/presentation/screens/home_screen.dart` | ✏️ | 首次启动时 `showDialog()` 套 TutorialOverlay |
| `lib/data/persistence/save_manager.dart` | ✏️ | PlayerData + `firstRun: bool` 字段 |

### 实现
- 使用 `Stack` + `Positioned` + `GestureDetector`
- 高亮区域用 `ClipRRect` 镂空遮罩 (CustomPainter画孔)
- 每次点击前进到下一步
- 用 `PlayerData.firstRun` 持久化

---

## 2. 收藏/组卡系统 (~4h)

### 功能
- **搜索栏**: 按名字搜索
- **学筛选签**: 7个学派 + "全部"
- **成本筛选**: 0-3 / 4-6 / 7+ 三段
- **自定义卡组**: 创建/编辑/保存卡组 (30张/组)
- **卡组保存**: PlayerData + deckSlots 字段已存在

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/presentation/screens/deck_editor_screen.dart` | 🆕 | 卡组编辑器（左:卡池 右:卡组 拖拽添加） |
| `lib/presentation/screens/collection_screen.dart` | ✏️ | +搜索栏 +学派Tab +筛选 全面改造 |
| `lib/presentation/widgets/card_tile.dart` | 🆕 | 可复用的卡牌列表项 |

### 数据模型 (已有 collection.dart)
```
Collection 已有: cards(Map<id,count>), cardCopies, favoriteCards
DeckEditor 新建: selectedCards List<Card>, deckName String
```

---

## 3. 更多广告位 + 首充礼包 (~2h)

### 新增广告位
| 位置 | 类型 | 奖励 |
|------|------|------|
| 对战胜利后 | 激励视频 | 双倍金币 |
| 每日签到 | 激励视频 | 额外体力/金币 |
| 卡组栏 | Banner | 非侵入式底部横幅 |

### 首充礼包
- 价格: $0.99 (对应区域定价)
- 内容: 10x卡包 + 300金币 + 限定卡背
- 位置: HomeScreen banner + RPGShop弹窗
- 技术: RevenueCat 非消耗品 + `PurchaseService.I.purchase('starter_bundle')`

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/presentation/screens/home_screen.dart` | ✏️ | +首充礼包banner (校验是否已购) |
| `lib/presentation/screens/game_screen.dart` | ✏️ | 胜利后显示"看广告双倍金币"按钮 |
| `lib/domain/services/purchase_service.dart` | ✏️ | +`isPurchased(id)` 方法 |
| `lib/domain/services/ad_service.dart` | ✏️ | +`showBannerAd()` 接口 |

---

## 4. AI强化 + 卡牌平衡 (~3h)

### AI策略升级
- **simple**: 随机 (不变)
- **normal**: 优先清除低血量随从 (<3血优先)
- **hard**: 计算交换价值 (1换2优先) + 保留AOE
- **abyss**: 预判2回合 + 最优解场

### 数值平衡
| 修改 | 原因 |
|------|------|
| 风怒随从攻击-1 | 现在AI能用风怒, 数值需下调 |
| 初始手牌+1 | 增加开局策略性 |
| 部分高费卡费用-1 | 高费卡使用率低 |

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/domain/services/ai_controller.dart` | ✏️ | 策略升级 |
| `lib/domain/services/game_rules.dart` | ✏️ | initialHandSize+1 |
| `lib/data/cards/cards_data.dart` | ✏️ | 部分卡牌数值 |

---

## 5. 开包动画强化 (~1.5h)

### 效果
1. **包选择**: 扭动+发光 (已有基础)
2. **打开动画**: 包裂开→金光→尘土粒子 (粒子系统)
3. **卡牌翻转**: 从背面→正面翻转动画
4. **稀有度特效**: 蓝→紫→橙 不同光效
5. **声音**: 按稀有度不同音效

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/presentation/screens/pack_screen.dart` | ✏️ | 重写开包动画 |
| `lib/presentation/widgets/pack_opening_effect.dart` | 🆕 | 粒子+光效动画 |

---

## 6. UI主题统一 (~2h)

### 方案
创建统一主题常量文件，替代各屏手写色值：

```dart
class AppTheme {
  static const bgDark = Color(0xFF2C1810);
  static const parchment = Color(0xFFE8D5B7);
  static const goldAccent = Color(0xFFB8860B);
  static const agedWood = Color(0xFF3D2B1F);
  static const cardBack = Color(0xFF4A3728);
  // 七学派色
  static const bingjia = Color(0xFFC0392B);
  static const fajia = Color(0xFF2E86C1);
  // ...
}
```

### 文件清单
| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/core/theme/app_theme.dart` | 🆕 | 统一色值/字体/间距 |
| 各Screen/Widget | ✏️ | 逐一替换 `static const _xxx` → `AppTheme.xxx` |

---

## 执行顺序

```
1. 新手教程 (3h) → 立即提升留存
2. 收藏/组卡 (4h) → 核心功能缺失  
3. 广告+首充 (2h) → 直接收入
4. AI+平衡 (3h) → 核心体验
5. 开包动画 (1.5h) → 付费转化
6. UI主题 (2h) → 最后收尾
总计: ~15.5h 开发量
```
