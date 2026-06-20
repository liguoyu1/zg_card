# Phase 1: 单人冒险 + 广告变现

> 基于资深游戏行业评估：先做单机验证留存，再考虑商业化
> 目标：TapTap 评分 > 4.0, D1 > 45%, D7 > 18%

---

## 现有资产清单（已存在可用）

| 类别 | 数量 | 说明 |
|------|------|------|
| PNG 卡图 | 196个 | heroes(21) + minions(45) + spells(78) + weapons(18) + gems(4) + icons(12) + frame(1) + back(1) + unused(7) |
| 音效 | 13个 | 12 ogg + 1 mp3 BGM |
| 英雄 | 24个 | 8 学派 × 3，各有独立肖像 |
| 冒险关卡数据 | 12关 | 3章节，数据完整但未接入实战 |
| 开包系统 | ✅ | PackService (保底/权重/十连抽) |
| 任务系统 | ✅ | QuestService (日/周任务框架) |
| 存档系统 | ✅ | SaveManager + PlayerData + Collection |
| 训练模式 | 10关 | TrainingManager 数据+UI框架 |
| 融合系统 | ✅ | FusionSystem (同名卡合成) |
| 升级系统 | ✅ | UpgradeSystem (数值升级) |

---

## 一、修复卡牌图片映射（1h）

### 问题
`card_image_service.dart` 中卡牌 ID → 图片文件名映射全面错位。英雄卡配了别人的头像，兵卒卡分配混乱。

### 方案
重写 `_minionImageMap` 全部 ~112 条映射，规则：
- **英雄卡**（X008-X012）：配自己的官方肖像（assets/heroes/ 下专用文件）
- **兵卒卡**（X001-X007）：按学派轮转分配已有兵卒图
- **法术卡**：`_spellImageMap` 使用 spells_spell_xxx.png 格式（无 dulpicated）
- **武器卡**：`_weaponImageMap` 使用 weapons_weapon_xxx.png 格式

### 验证
- `CardImageService.getImageByType(cardId, 'minion')` 返回正确路径
- 每张卡牌都映射到实际存在的文件
- 已存在的 `_unused/` 中 7 张孤儿图不移除

---

## 二、单人战役模式 ×30 关（4h）

### 现有内容
| 章节 | 现有关卡 | 需新增 |
|------|---------|-------|
| 1. 战国风云 | 5关 | +5 |
| 2. 诸子百家 | 4关 | +6 |
| 3. 天下一统 | 3关 | +7 |
| **合计** | **12关** | **+18 → 30关** |

### 关卡设计方案

#### 第1章：战国风云（10关 — Easy/Normal）
```
1-1 初出茅庐    vs 孙膑    easy   → 教程关：送你 3 张基础卡
1-2 围魏救赵    vs 吴起    easy   → 教程：引导打出随从
1-3 商鞅变法    vs 商鞅    normal → 教程：使用法术
1-4 稷下学宫    vs 孔子    normal → 教程：英雄技能
1-5 合纵连横    vs 苏秦    hard   → **Boss 关**
1-6 老马识途    vs 老子    easy   → 自由战
1-7 仁义之师    vs 孟子    normal → 自由战
1-8 墨守成规    vs 墨子    normal → 自由战
1-9 五雷天心    vs 邹衍    normal → 自由战
1-10 孙庞斗智   vs 孙膑    hard   → **Boss 关**, 孙膑陷阱战术
```

#### 第2章：诸子百家（10关 — Normal/Hard）
```
2-1 老子问道    vs 老子    normal
2-2 法家三术    vs 韩非    hard
2-3 墨家非攻    vs 墨子    hard
2-4 百家争鸣    vs 荀子    extreme → **Boss 关**
2-5 庖丁解牛    vs 庄子    normal
2-6 阴阳五行    vs 邹衍    normal
2-7 法不容情    vs 商鞅    hard
2-8 纵横捭阖    vs 张仪    normal
2-9 兼爱非攻    vs 墨家  hard
2-10 天志明鬼   vs 邹衍  extreme → **Boss 关**
```

#### 第3章：天下一统（10关 — Hard/Extreme）
```
3-1 秦赵长平    vs 廉颇    hard
3-2 荆轲刺秦    vs 甘德    extreme
3-3 王翦灭楚    vs 李牧    hard
3-4 韩非入秦    vs 韩非    hard
3-5 百家归宗    vs 鬼谷子  extreme
3-6 焚书坑儒    vs 李悝    hard
3-7 张仪连横    vs 张仪    extreme
3-8 北击匈奴    vs 李牧    hard
3-9 始皇统一    vs 秦始皇  extreme
3-10 终极决战   vs 秦始皇(加强) extreme → **最终 Boss**
```

### 关卡奖励设计

| 难度 | 金币 | 经验 | 额外 |
|------|------|------|------|
| easy | 30 | 20 | 随机普通卡 ×1 |
| normal | 50 | 35 | 随机普通卡 ×1 |
| hard | 80 | 50 | 随机稀有卡 ×1 |
| extreme | 120 | 80 | 随机稀有卡 ×1 |
| Boss | ×1.5 | ×1.5 | 保底稀有 |
| 最终 Boss | ×2 | ×2 | 史诗卡 ×1 |

### 实现
修改 `AdventureManager._buildChapters()` 扩充到 30 关
修改 `AdventureMission` 模型：新增 `enemyDeckId` 字段（定义 AI 使用的预设卡组）
无需改模型，复用现有类

---

## 三、冒险主界面重做（3h）

### 设计
- **战国卷轴风格**：羊皮纸背景 + 毛笔字体 + 竹子装饰
- **章节地图**：垂直 ScrollView，每个章节是一张大羊皮纸卷
- **关卡节点**：长条状关卡卡片，左边 icon（小旗/🔥/👑），中间名称+难度，右边奖励预览
- **状态提示**：锁定（锁图标+暗色）/ 可玩（亮色+脉冲边框）/ 已通关（✅+灰色）
- **底部进度**：总进度百分比 + 当前章节进度条

### 需要新建
- `lib/presentation/screens/adventure_screen.dart` — 完全替换现有 AdventureScreen（目前在 training_screen.dart 末尾）
- `lib/presentation/widgets/mission_card.dart` — 关卡卡片组件

### 风格统一
复用 `game_screen.dart` 中定义的颜色常量：`_bgDark, _parchment, _goldAccent, _agedWood, _cardBack`

---

## 四、冒险→游戏→结算完整流程（3h）

### 流程
```
AdventureScreen → 选关 → GameScreen(mission context)
                          ↓
                     战斗结束 (赢/输)
                          ↓
                  GameEndOverlay 增强版
                  - 胜利：金币+经验+卡牌奖励动画
                  - 失败：重试按钮
                          ↓
                  SaveManager.savePlayerData()
                  → 回 AdventureScreen (进度更新)
```

### 需求改动

#### 1. GameScreen 改造
- 接受 `MissionContext` 参数（战斗结束后的回调）
- `MissionContext` 包含：
  ```dart
  class MissionContext {
    final String missionId;
    final int rewardGold;
    final List<String> rewardCards;
    final VoidCallback onComplete;
  }
  ```
- 游戏结束时，调用 `context.onComplete()` 并传递结果

#### 2. GameEndOverlay 增强
- 胜利时：展示金币奖励动画（数字飘入）+ 卡牌展示（翻牌动画）
- 失败时：展示"再接再厉" + 重试按钮

#### 3. 存档联动
- `SaveManager.savePlayerData()` 在每次战斗后自动调用
- `PlayerData.gold` 增加
- `Collection` 中增加新卡

### 新增文件
- `lib/domain/models/mission_context.dart`
- `lib/presentation/widgets/reward_overlay.dart`

---

## 五、开包系统 UI（2h）

### 设计
- **开包界面**：`PackScreen` 
- **入口**：主菜单 + 冒险结算页的"开包"按钮
- **流程**：选择卡包 → 动画（包打开 → 五张卡展开 → 逐个翻牌 → 稀有度特效）
- **动画**：STWidget 实现，每张卡 0.2s 延迟翻转
- **稀有度特效**：common(无特效) / rare(蓝光) / epic(紫光) / legendary(金光喷涌)
- **获取途径**：
  - 金币购买：100 金币/包
  - 广告免费：激励视频→免费一包（接入广告 SDK 后开启）
  - 冒险奖励：不消耗金币

### 新增文件
- `lib/presentation/screens/pack_screen.dart`
- `lib/presentation/widgets/pack_opening_widget.dart`
- `lib/presentation/widgets/card_flip_widget.dart`

---

## 六、卡牌收藏界面（2h）

### 设计
- **主页面**：网格 GridView 展示所有卡牌
- **过滤**：按学派（兵/法/儒/道/墨/阴阳/纵横/中立）
- **排序**：费用/稀有度/名称
- **卡牌详情**：点击卡牌弹出详情大图（复用 `card_detail_dialog.dart`）
- **稀有度过滤**：全部/普通/稀有/史诗/传说

### 新增文件
- `lib/presentation/screens/collection_screen.dart`

---

## 七、广告 SDK 接入（1h）

### 方案选择

| 方案 | 适用区域 | 优点 | 缺点 |
|------|---------|------|------|
| Google AdMob | 海外 | 成熟稳定 | 国内可能无法使用 |
| 穿山甲(Pangle) | 中国大陆 | 国内主流 | 需要企业资质 |
| 腾讯优量汇 | 中国大陆 | 容易接入 | 门槛高 |
| **自定义广告位** | 通用 | 先做逻辑，SDK可替换 | 第一次无收入 |

### 实现方式（先做抽象层，后接具体 SDK）

1. **抽象接口**：`AdService`（放置广告占位）
2. **接入点**：
   - 每 24 小时免费开一包（激励视频）
   - 关卡失败后免费复活一次（激励视频）
   - 开包界面底部横幅广告位
3. **SDK 占位**：先显示"看广告免费开包"按钮，点击后播放本地占位动画
4. **接入规范**：`AppOpenAdManager` 管理广告加载时机，避免影响游戏性能

### 文件
- `lib/core/services/ad_service.dart` — 广告服务接口
- `lib/core/services/ad_service_stub.dart` — 占位实现（真机接入时替换）

---

## 八、经济循环完整串联（1h）

### 金币循环
```
完成任务 → 获得金币 → 购买卡包 → 开出新卡 → 增强卡组 → 打过更难关卡
   ↑                                                           |
   └─────────────────── 更多金币 ← 更难关卡奖励更多 ────────────┘
```

### 实现改动
- `GameEndOverlay` 胜利后调用 `SaveManager.addGold(reward)`
- `SaveManager.addCard(cardId)` 添加到 Collection
- `PlayerData.level` 经验满时升级（+10 金币奖励）
- `home_screen.dart` 添加金币/等级显示

---

## 8.5 设计决策确认

| 决策 | 选择 | 理由 |
|------|------|------|
| 冒险 UI 风格 | **垂直卷轴列表** | 章节展开的羊皮卷风格，实现简单，视觉统一 |
| AI 卡组 | **固定核心 + 部分随机** | 每关预设 20 张核心卡+随机补 10 张，难度可控 |
| 开包价格 | **50 金币/包** | 快速获得感，打一关给 30-80 金，2关可买一包 |

---

## 九、执行顺序

```
周次 | 任务
-----|------
1    | ① 卡牌图片映射修复 + ② 30关内容填充
2    | ③ 冒险界面重做 + ④ 游戏流程串联
3    | ⑤ 开包系统 UI + ⑥ 卡牌收藏
4    | ⑦ 广告接入 + ⑧ 经济循环 + 测试 + 修复
```

### 依赖关系
```
① → ② → ③ → ④ → ⑤
                  ↓
            ⑥ ← ⑦ → ⑧
```

---

## 十、风险与权衡

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 卡图映射后仍有错位 | 中 | 低 | 添加自动化测试验证所有映射文件存在 |
| 30关设计不够有趣 | 中 | 高 | 先做10关核心关，后续逐步扩展 |
| 广告SDK审核不通过 | 高 | 低 | 先做占位接口，审核通过后替换 |
| 经济系统不平衡 | 中 | 中 | 配置化数值，上线后热更新 |

---

## 十一、验证标准

```
✅ 所有 196 张卡牌图片正确映射（无空白/错位）
✅ 30 个冒险关卡全部可玩（从选关到胜利到结算）
✅ 胜利获得金币 + 卡牌奖励
✅ 金币可购买卡包
✅ 开包动画正常展示
✅ 收藏界面展示所有已拥有卡牌
✅ 广告接入点展示（占位）
✅ 存档加载/保存正常
```
