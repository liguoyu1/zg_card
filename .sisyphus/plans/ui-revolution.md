# 战国风UI革命 — 对标炉石传说

## 现状
- 纯 Material Design 默认风格
- 16 个 screen + 11 个 widget
- AppTheme 只有色值，无完整设计系统
- 无字体文件，无 TextTheme/ButtonTheme
- 所有按钮用标准 ElevatedButton
- 游戏棋盘用半透明 Container + gradient

## 阶段计划

### P1: 设计系统 Foundation
- [x] AppTheme 设计令牌（色/间距/圆角/阴影/渐变）
- [x] 自定义字体方案
- [x] ThemeExtension：ButtonTheme / PanelTheme
- [x] 基础构建块：纹理背景、装饰边框、牌匾容器
- [x] 替换所有屏幕 Scaffold 背景色

### P2: 导航壳 + HomeScreen 重构
- [ ] 战国风游戏壳（无标准 AppBar）
- [ ] HomeScreen 炉石式主界面（大按钮/牌匾式菜单）
- [ ] 底部导航切换（用炉石式嵌板）

### P3: 卡牌UI重构
- [ ] 自定义卡牌边框绘制器（学派色+稀有度）
- [ ] BoardCard 重绘
- [ ] HandCard 扇形叠层布局
- [ ] HeroAvatar 美化

### P4: 游戏棋盘重绘
- [ ] 木质桌面背景
- [ ] 对战面板布局优化
- [ ] ManaCrystals 美化
- [ ] EndTurnButton 特效
- [ ] 伤害数字/血条优化

### P5: 次级屏幕统一主题化
- [ ] CardLibraryScreen
- [ ] DeckEditorScreen
- [ ] PackScreen
- [ ] BattlePassScreen
- [ ] QuestScreen
- [ ] AchievementScreen

### P6: 动画打磨
- [ ] 抽牌动画
- [ ] 出牌特效
- [ ] 攻击动画
- [ ] 开包动画升级
- [ ] 页面切换过渡

## 执行顺序
1. P1 → 立即让所有屏幕拥有统一皮肤
2. P2 → 用户第一眼看到的 HomeScreen
3. P4 → 实际对局的 GameScreen
4. P3 → 卡牌自身外观
5. P5 → 剩余页面
6. P6 → 最后的 polish
