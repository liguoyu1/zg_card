# Phase C: 每日任务 + 成就 + Battle Pass

## 现状调研

已有基础设施：
- `PlayerData` (gold, level, exp, winCount, achievedMedals)
- `SaveManager` (JSON 文件持久化)
- 卡牌收集系统 `Collection`

需要的系统都不存在 — 全部新建。

---

## 1. 每日任务系统

### 任务类型 (7种，每天刷新3个)
| 任务 | 目标 | 奖励 |
|------|------|------|
| 胜利3场 | 累计胜利 | 30金 |
| 打10张兵家卡 | 学派计数 | 20金 + 5尘 |
| 造成50伤害 | 伤害计数 | 25金 |
| 使用5次英雄技能 | 技能计数 | 20金 |
| 赢1场冒险Boss | Boss击杀 | 40金 |
| 抽20张牌 | 抽牌计数 | 15金 |
| 融合2张卡 | 融合计数 | 25金 + 10尘 |

### 数据结构
```dart
class DailyQuest {
  final String id;
  final QuestType type;       // win_3, play_cards, deal_damage, ...
  final int target;           // 目标值
  int progress;               // 当前进度
  bool completed;
  bool claimed;
  final int goldReward;
  final int dustReward;       // 可选
}

class QuestManager {
  List<DailyQuest> _dailyQuests;  // 3个每日任务
  DateTime _lastRefreshDate;      // 最后刷新时间

  void checkDailyReset();     // 每天自动刷新
  void reportEvent(QuestEvent event);  // 游戏事件驱动
  void claimReward(int index);
  bool canRefresh;            // 每天可免费刷新1次
  void refreshQuest(int index);
}
```

### 事件驱动
```dart
enum QuestEventType { matchWin, cardPlayed, damageDealt, heroPowerUsed, cardsDrawn, fusionPerformed }

class QuestEvent {
  final QuestEventType type;
  final int value;       // 增量
  final String? cardOwner;  // 学派筛选
  final String? cardId;
}
```

### 持久化
- 文件: `quests.json`
- 格式: `{ "date": "2026-06-05", "quests": [...], "refreshCount": 1 }`

---

## 2. 成就系统

### 成就列表 (10个)
| 成就 | 条件 | 奖励 |
|------|------|------|
| 初出茅庐 | 赢第1场 | 50金 |
| 常胜将军 | 赢50场 | 200金 + 称号 |
| 百战勇士 | 赢100场 | 500金 + 卡背 |
| 收藏家I | 收集30张卡 | 100金 |
| 收藏家II | 收集60张卡 | 200金 |
| 收藏家III | 收集100张卡 | 500金 |
| 冒险家 | 通关1章 | 100金 |
| 无畏探索 | 通关全部 | 300金 |
| 融合大师 | 融合10次 | 200金 |
| 武运昌隆 | 累计5000伤害 | 300金 |

### 实现
- `AchievementService` 监听同 `QuestEvent`
- 检查条件 → 如果 `id` 不在 `PlayerData.achievedMedals` 中则发放奖励
- 成就奖励通过 `SaveManager` 更新 `PlayerData.gold`

---

## 3. Battle Pass (简化版)

### 结构
```dart
class BattlePass {
  int level;              // 当前等级 (1-30)
  int xp;                 // 当前XP
  int xpToNext;           // 升级所需XP (每级+50, 初始200)
  bool premium;           // 是否付费
  List<int> claimedFreeRewards;   // 已领取的免费奖励等级
  List<int> claimedPremiumRewards; // 已领取的付费奖励等级
}
```

### XP 获取
- 完成每日任务: +50 XP each
- 胜利: +10 XP
- 冒险Boss: +30 XP

### 奖励表
| 等级 | 免费奖励 | 付费奖励 |
|------|----------|----------|
| 1 | 50金 | 卡背"青铜" |
| 5 | 卡包x1 | 英雄皮肤"墨家" |
| 10 | 100金 | 卡包x3 |
| 15 | 卡包x1 | 金卡"风云" |
| 20 | 200金 | 英雄皮肤"法家" |
| 25 | 卡包x2 | 金卡"定秦" |
| 30 | 300金 + 称号 | 卡背"黄金至尊" |

---

## 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/domain/models/quest.dart` | 🆕 | DailyQuest, QuestEvent, QuestType |
| `lib/domain/services/quest_manager.dart` | 🆕 | 任务逻辑 + 持久化 |
| `lib/domain/services/achievement_service.dart` | 🆕 | 成就检查 + 奖励 |
| `lib/domain/services/battle_pass_service.dart` | 🆕 | BP等级 + XP |
| `lib/domain/models/battle_pass.dart` | 🆕 | BattlePass 数据类 |
| `lib/presentation/screens/quest_screen.dart` | 🆕 | 任务UI界面 |
| `lib/presentation/screens/battle_pass_screen.dart` | 🆕 | BP界面 |
| `lib/presentation/screens/achievement_screen.dart` | 🆕 | 成就界面 |
| `lib/presentation/screens/home_screen.dart` | ✏️ | 新增3个入口按钮 |
| `lib/main.dart` | ✏️ | 初始化文件加载 |

---

## 工作量估算
~7 新建文件, ~3 修改文件, 总计 ~700 行
