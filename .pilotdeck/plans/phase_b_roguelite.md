# Phase B: Roguelite 冒险模式

## 目标

将现有的 30 关线性冒险改为**路径选择式 Roguelite**，玩家在一次"征途"中经历多场战斗，HP 继承，胜后选牌，死亡则征途终止。

### 核心改动原则

- **最小改动，最大体验变化** — 不重写战斗系统，不新增美术资源
- **使用现有 30 关内容** — 原冒险数据 (adventure_manager.dart) 不变，只重组结构
- **Battle→选择节点→Battle→...→Boss** — 每个章节有 1 条路径，节点类型：Battle / Rest / Shop

---

## 文件清单

| 操作 | 文件 | 说明 |
|------|------|------|
| 🆕 | `lib/domain/models/roguelite_run.dart` | 征途状态（HP/金币/位置/临时卡组） |
| 🆕 | `lib/domain/services/roguelite_service.dart` | 路径图生成 + 征途生命周期 |
| 🆕 | `lib/presentation/widgets/reward_picker.dart` | 战后选牌弹窗（3选1） |
| 🆕 | `lib/presentation/widgets/path_map.dart` | 路径图可视化 Widget |
| ✏️ | `lib/presentation/screens/adventure_screen.dart` | 全面重写为征途主界面 |
| ✏️ | `lib/presentation/screens/game_screen.dart` | + `runHp` 参数 + 战后返回HP |
| ✏️ | `lib/presentation/providers/game_provider.dart` | `initGame` 支持自定义HP |

---

## 数据模型

### RogueliteNode 节点类型
```dart
enum RogueliteNodeType { battle, elite, boss, rest, shop }
```

### RogueliteRun 征途状态
```dart
class RogueliteRun {
  String heroId;
  int currentHp;
  int maxHp;
  int gold;
  int currentLayer;  // 当前在第几层
  String currentNodeId;
  List<RogueliteNode> allNodes;
  List<Card> tempDeck;  // 征途中获得的额外卡牌
  bool isActive;
}
```

### 路径结构（每章 10 关 → 5-6 层路径）
```
第1章示例:
  层1: Battle(1-1) → 层2: [Battle(1-2) | Rest | Shop] → 层3: Battle(1-3) → 
  层4: [Battle(1-4) | Rest] → 层5: Battle(1-5/Boss)
  共用前5关，后5关为第2次征途
```

每章分 2 段征途（各 5 关），每段以 Boss 结尾。

---

## 实现步骤

### Step 1: `roguelite_run.dart` — 数据模型
- `RogueliteNode` 类（id, type, missionId, title, description）
- `RogueliteRun` 类（currentHp, gold, layer, deck, etc）

### Step 2: `roguelite_service.dart` — 路径生成
- `generatePath(chapter, segment)` → 生成 `List<List<RogueliteNode>>`（按层分组）
- 核心逻辑：固定每层的节点组合，Battle 节点指向原冒险任务

### Step 3: `path_map.dart` — 路径可视化
- 竖向滚动的路径节点图
- 节点用圆形表示，类型不同颜色不同（绿=战斗, 蓝=休息, 紫=商店, 金=Boss）
- 连线用 CustomPaint 绘制
- 当前层高亮，不可达节点灰色

### Step 4: `adventure_screen.dart` — 重写
- **去掉**：章节列表 + 任务列表 + 展开折叠
- **改为**：章节选择（左滑）→ 选定章节后进入路径图 → 选择节点
- 已通关章节可重复挑战（无限重玩）

### Step 5: HP 继承机制
- `game_provider.dart.initGame` 接受 `int? playerHealth`
- `game_screen.dart` 接受 `int? runHp`，初始化后覆盖 HP
- 战后 `Navigator.pop(result)` 返回剩余 HP

### Step 6: `reward_picker.dart` — 选牌弹窗
- 战斗胜利后弹窗：展示 3 张随机卡
- 点击选中 → 加入临时卡组 → 继续征途

---

## 工作量估算

| 步骤 | 文件数 | 代码量 |
|------|--------|--------|
| 1. 数据模型 | 1新建 | ~60行 |
| 2. 路径生成 | 1新建 | ~100行 |
| 3. 路径可视化 | 1新建 | ~120行 |
| 4. 选牌弹窗 | 1新建 | ~80行 |
| 5. 重写冒险屏 | 1重写 | ~250行 |
| 6. HP继承（provider+game） | 2修改 | ~40行 |
| **合计** | **7文件** | **~650行** |

---

## 超越竞品的差异化

通过这个改动实现竞品分析中的核心策略：

1. **无限重玩性** — 同样的 30 关内容，每次征途路径选择不同，有不同体验
2. **HP承载紧张感** — HP 继承让每一场战斗都有了更大的赌注
3. **选牌机制** — 让玩家感觉自己正在构建一套"临时卡组"，提高收集欲
4. **文化沉浸** — 路径节点命名融入战国典故，休息节点显示历史小知识
