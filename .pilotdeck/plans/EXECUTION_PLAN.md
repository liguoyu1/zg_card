# 战国卡牌项目 — 全维度增量执行计划

> 基于 55 项发现的完整执行路线
> 最后更新: 2026-06-02 (讨论确认版)
> 预估工时: ~40 小时

---

## 全局行为准则

本计划全程遵循四条原则：
1. **编码前思考** — 列出假设，呈现权衡，不清楚就问
2. **简洁优先** — 用最少代码，不做过度抽象和推测性扩展
3. **精确修改** — 只碰该碰的，不顺便修无关代码
4. **目标驱动** — 每个任务转换成可验证标准，循环验证通过

---

## 符号说明

| 符号 | 含义 |
|------|------|
| ✅ 我直接做 | 不需要外部支持，纯代码修改 |
| ⚠️ 需讨论 | 实现方式需要你确认 |
| ❌ 需外部支持 | 我不能完成的部分，需要你提供 |
| ➖ 不做/取消 | 讨论后决定取消或已解决 |
| 🔲 待讨论 | 还有没开始讨论的话题 |

---

## 一、P0-A：核心 Bug 修复（~5h）

### 1.1 风怒无限攻击 Bug — ✅ 我直接做（10min）
- **根因**：`hasUsedFirstWindfuryAttack` 未在回合重置中清空
- **文件**：`game_rules.dart:347` — 加 `hasUsedFirstWindfuryAttack: false`
- **联动**：`card.dart:89-96` — 同时简化 `canAttack` 逻辑
- **验证**：风怒随从每回合最多攻击 2 次，不会出现第 3 次

### 1.2 法术牌/武器牌打出 — ✅ 我直接做（1.5h）
- **改动**：`_onHandCardTap` 扩展为 `switch(card.type)` 三分支（minion/spell/weapon）
- **法术**：检查是否需要选目标，进入目标选择模式，打出生效
- **武器**：直接装备到英雄 `player.weapon`，旧武器替换
- **文件**：`game_screen.dart:544-558` / `game_rules.dart` / `game_state.dart`
- **验证**：三种类型卡牌均可从手牌打出并正确生效

### 1.3 英雄技能完整目标选择模式（方案B） — ✅ 我直接做（1.5h）
- **新增** `InteractionMode` 枚举：`none / attackTargeting / heroPowerTargeting`
- **流程**：点英雄头像 → 不需要选目标则直接释放；需要选目标则进入选目标模式
- **取消操作**：再点头像/点空白/点结束回合/点手牌 → 取消选择
- **视觉反馈**：技能释放后目标卡牌绿色边框闪烁 300ms
- **文件**：`game_screen.dart` / `game_provider.dart` / `hero_power.dart`
- **验证**：8 种英雄技能均正常工作，需要选目标的需点击目标后释放

### 1.4 AI 攻击循环游标漂移修复 — ✅ 我直接做（20min）
- **根因**：循环内每次 `state.activePlayer` 可能变化
- **修复**：`aiId` 循环外固定，循环内用 `state.opponent` 取人类玩家
- **文件**：`game_screen.dart:871-899`
- **验证**：AI 回合多次攻击后每次 `minionAttack` 参数始终正确

### 1.5 消灭触发亡语 — ✅ 我直接做（15min）
- **修复**：`destroyMinion` 先调 `EffectExecutor.executeDeathrattle(card, ...)` 再移除
- **文件**：`game_rules.dart:331-336`
- **验证**：消灭一个带亡语的随从时，亡语效果触发

### 1.6 圣盾逻辑简化 — ✅ 我直接做（20min）
- **修复**：`resolveCombat` 移除圣盾处理（只算原始伤害）
- **修复**：`minionAttack` 作为圣盾唯一处理点（目标有圣盾→目标不受伤并移除；攻击者有圣盾→攻击者不受伤并移除）
- **文件**：`game_rules.dart:68-75, 177-212`
- **验证**：圣盾正确抵消第一次伤害，然后消失

---

## 二、P0-B：AI 完整性 + 动画（~4h）

### 2.1 AI 出法术牌 + 用英雄技能 — ✅ 我直接做（1h）
- **出牌**：`_aiPlayCards` 过滤条件改为不过滤类型，AI 按类型分发
- **英雄技能**：`_executeAITurn` 中插入 `shouldUseHeroPower` 判断
- **文件**：`game_screen.dart:853-868, 816-850`
- **验证**：AI 回合中会使用法术牌和英雄技能

### 2.2 AI 攻击动画 + 伤害数字 + 死亡动画（GlobalKey方案） — ✅ 我直接做（2h）
- **定位方案**：每个 `BoardCard` 挂 `GlobalKey('board_card_${card.id}')`，用 `findRenderObject` 取精确坐标
- **顺序**：攻击动画(500ms) → 伤害数字飘出(800ms) → 检测死亡 → 死亡动画(400ms)
- **文件**：`game_screen.dart` / `board_card.dart`
- **验证**：AI 攻击时随从有冲锋动画，命中后飘出伤害数字，血量归零后播放死亡动画

---

## 三、P0-C：效果系统（~1h）

### 3.1 效果映射表验证 — ✅ 我直接做（20min）
- 遍历所有声明了 `hasBattlecry` / `hasDeathrattle` 的卡牌
- 确保 `effect_executor.dart` 中有对应 key
- 缺失的补全映射

### 3.2 回合末效果 — ➖ 暂不做
- 结论：等有卡牌数据需要"回合末触发"效果时再做

---

## 四、P1：完整体验（~8h）

### 4.1 战斗日志 — ✅ 我直接做（1.5h）
- 新增 `lib/domain/models/log_entry.dart`
- `game_provider.dart` 中每个动作追加日志
- `game_screen.dart` 右下角可折叠浮窗
- **验证**：打开日志能看到"XX攻击YY造成3点伤害"等记录

### 4.2 错误反馈（方案B：新增 error 动画状态） — ✅ 我直接做（1h）
- `CardAnimationState` 新增 `error`（红色边框闪烁）
- 所有非法操作分支加 SnackBar + 卡牌闪烁
- **文件**：`game_screen.dart` / `board_card.dart`
- **验证**：法力不足/已攻击过/无效目标时，有红色提示

### 4.3 组合系统接入 — ✅ 我直接做（1h）
- `BattlefieldService.playCard` 末尾检测 `ComboSystem.getActivatedCombos`
- UI 显示组合名称文字（如"合纵连横！"），1.5 秒后淡出
- **验证**：打出触发组合的卡牌时，组合名称弹出

### 4.4 合并升级系统 — ✅ 我直接做（2h）

**核心机制：**
- 同名卡 2 张 0 级 → 合并为 1 张 1 级卡（+1/+1，银框）
- 同名卡 2 张 1 级 → 合并为 1 张 2 级卡（+2/+2，金框）
- 同名卡 2 张 2 级 → 合并为 1 张 3 级卡（+3/+3，金+光效）

**约束：** 卡组最多 4 张同名卡 → 实际可达最高 2 级

**设计：**
- **时机**：手牌中主动操作（合并按钮）
- **消耗**：被合并的卡从游戏中移除
- **数值/等级**：配置化，后期可调
- **视觉**：`card.dart` 新增 `mergeLevel` 字段；`board_card.dart` / `hand_card.dart` 根据等级切换边框

**文件**：`card.dart` / `upgrade_system.dart` / `game_screen.dart` / `hand_card.dart` / `board_card.dart` / `game_provider.dart`
- **验证**：手牌中 2 张同名卡可合并，等级提升后数值和边框变化

### 4.5 卡牌详情查看（方案A2：平台自适应） — ✅ 我直接做（45min）
- iOS：`CupertinoModalPopup`（毛玻璃背景）
- Android：`Material ModalBottomSheet`
- 长按 `HandCard` → 显示卡牌完整信息（名称/费用/攻/血/描述/风味文字/稀有度）
- **文件**：`hand_card.dart` / 新增 `card_detail_dialog.dart`
- **验证**：长按手牌弹出详情浮窗，平台风格正确

---

## 五、P2：品质感与修复（~8h）

### 5.1 卡牌图片映射全面重整 — ✅ 我直接做（1h）
**诊断结论：所有 196 张卡的资源文件都存在，但 `_minionImageMap` 的映射内容全面错位。**
- 英雄卡（X008-X012，共 35 张）配了别人的肖像；兵卒卡（X001-X007，共 49 张）分配混乱
- 法术/武器映射路径有效但命名不统一（`spells_XXX.png` vs `spells_spell_XXX.png`）

**重整内容：**
1. **修正英雄映射** — 每个英雄配自己的肖像（共 33 张独家肖像照）
2. **兵卒合理分配** — 兵卒无专属图，按学派内兵卒→英雄图轮转（不影响英雄正确性）
3. **移除非引用文件** — `assets/spells/` 中 7 张孤儿图移动到 `_unused/`
4. **统一命名** — CardImageService 代码不变，只改映射表内容

**各学派修正对照表：**

| 学派 | 英雄卡 | 对应图 | 当前错误 |
|------|--------|-------|---------|
| 兵家 | B008 孙武 | bingjia_sunwu.png | 现配廉颇 |
| | B009 吴起 | bingjia_wuqi_minion.png | 现配孙膑 |
| | B010 孙膑 | bingjia_sunbin_minion.png | 现配吴起 |
| | B011 廉颇 | bingjia_lianpo_minion.png | 现配孙武 |
| | B012 李牧 | bingjia_li_mu.png | ✅ 已正确 |
| 法家 | F008 商鞅 | fajia_shangyang_minion.png | 现配吴起变法 |
| | F009 韩非 | fajia_hanfei_minion.png | 现配商鞅 |
| | F010 李悝 | fajia_dali.png | 现配申不害 |
| | F011 申不害 | minions_fajia_shenbuhai.png | 现配??? |
| | F012 吴起变法 | fajia_wuqi_biange.png | 现配韩非 |
| 儒家 | R008 孔子 | rujia_kongzi_minion.png | 现配荀子 |
| | R009 孟子 | rujia_mengzi_minion.png | 现配孔子 |
| | R010 荀子 | rujia_xunzi_minion.png | 现配孟子 |
| | R011 子路 | (无专属，复用) | 现配孔子 |
| | R012 曾子 | (无专属，复用) | 现配孟子 |
| 道家 | D008 老子 | daojia_laozi_minion.png | 现配隐士 |
| | D009 庄子 | daojia_zhuangzi_minion.png | 现配老子 |
| | D010 列子 | daojia_liezi_minion.png | 现配庄子 |
| 墨家 | M008 墨子 | mojia_mozi_minion.png | 现配天灸 |
| | M009 公输班 | mojia_gongshuban_minion.png | 现配墨子 |
| | M011 田鸠 | mojia_tianjiu.png | 现配??? |
| 阴阳家 | Y008 邹衍 | yinyangjia_zouyan_minion.png | 现配死神 |
| | Y009 甘德 | yinyangjia_gande_minion.png | 现配方术士 |
| | Y010 石申 | yinyangjia_shishen_minion.png | 现配甘德 |
| 纵横家 | Z008 苏秦 | zonghengjia_suqin_minion.png | 现配张仪 |
| | Z009 张仪 | zonghengjia_zhangyi_minion.png | 现配鬼谷子 |
| | Z012 鬼谷子 | zonghengjia_guiguzi_minion.png | ✅ 已正确 |

**文件：** `lib/data/card_image_service.dart:30-158`（重写全部 112 条映射）

### 5.2 音效框架接入 — ✅ 我直接做（1.5h）
- 在所有游戏动作点调用 `AudioManager`（攻击/出牌/技能/胜利/失败/按钮）
- 并发播放改为 `List<AudioPlayer>` 池

### 5.3 音效文件搜索 — ❌ 需外部支持
- 我能搜索 cc0 免费音效来源并整理清单
- 下载并放到 `assets/sounds/` 需要你来完成

### 5.4 稀有度颜色替换 — ✅ 我直接做（10min）
```
common（白）→ #d4c5a9（羊皮纸色）
rare（蓝）→ #4a7c59（玉色）
epic（紫）→ #8b4513（铜褐色）
legendary（橙）→ #c59538（金色）
```

### 5.5 倒计时进度条 — ✅ 我直接做（15min）
- 回合倒计时数字下方加 `LinearProgressIndicator`
- <5 秒变红色
- **文件**：`game_screen.dart`

### 5.6 服务端匹配队列 TTL — ✅ 我直接做（20min）
- 每 30 秒扫描，超过 5 分钟未匹配的玩家自动移除

### 5.7 ELO 计算修复 — ✅ 我直接做（10min）
- `won=false` 时用 `loserNew` 而非 `winnerNew`
- **文件**：`server/utils/database.ts:163`

### 5.8 服务端 Zod 输入校验 — ✅ 我直接做（30min）
- 引入 `zod`，为 auth/player/match 接口添加 schema 校验
- **文件**：`server/routes/api/`

---

## 六、P2：性能优化（~1h） — ✅ 全部我直接做

| # | 项 | 改动 | 文件 |
|---|-----|------|------|
| 6.1 | BattlefieldService/EffectExecutor 单例 | 在 Provider 中持有实例复用 | `game_provider.dart` |
| 6.2 | Random.secure → Random | 一行 | `draw_service.dart:37` |
| 6.3 | setState 节流 | 数值变化时才调 | `game_screen.dart:56-62` |
| 6.4 | 移除未使用的 Flame 依赖 | 从 pubspec 删除 | `pubspec.yaml` |

---

## 七、P3：工程规范（~10h） — ✅ 全部我直接做

| # | 项 | 改动 |
|---|-----|------|
| 7.1 | Magic Number 集中化 | 新建 `core/game_config.dart`，全局替换 |
| 7.2 | AIGameNotifier 去重 | 3 个攻击方法合并为模板方法 |
| 7.3 | import 路径统一 | 全局改为 `package:warring_states_card/...` |
| 7.4 | 服务端路由拆分 | auth/player/match/leaderboard 分文件 |
| 7.5 | analysis_options 严格化 | 全项目统一修复，启用 20+ 规则 |
| 7.6 | doc comment 补全 | 核心类/方法加三斜杠注释 |

---

## 八、外部支持清单

| 项 | 需要什么 | 我能做什么 |
|---|---------|-----------|
| 卡牌图片问题 | 你描述具体表现（图不对/图不显/其他） | 我根据描述定位修复 |
| 音效文件 | 10 个 MP3（play_card/attack/damage/heal/death/end_turn/victory/defeat/mana/click） | 我搜索 cc0 来源并给出下载链接、整理清单 |
| 部署/环境变量 | 你需要在 Railway 面板操作 | 我提供配置步骤 |
| Flutter widget test | 需要你本地跑 `flutter test` | 我写 unit test，你帮我确认 widget test |

---

## 九、执行时间线

```
P0 (A+B+C): 核心 Bug + AI + 效果系统 — ~10h
P1: 完整体验（日志/反馈/组合/合并/详情） — ~8h
P2: 品质 + 性能优化 — ~9h
P3: 工程规范 — ~10h
```

各阶段按依赖关系顺序执行，每阶段结束可独立测试验证。
