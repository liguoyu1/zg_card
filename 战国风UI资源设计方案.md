# 战国风UI资源设计方案

## 一、UI资源总览

### 1.1 资源分类与数量
| 类别 | 子类 | 数量 | 格式 | 尺寸 | 说明 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **背景图** | 主菜单背景 | 5张 | PNG | 1920×1080 | 不同场景切换 |
| | 对战背景 | 7张 | PNG | 1920×1080 | 七国特色 |
| | 加载背景 | 3张 | PNG | 1920×1080 | 过渡画面 |
| **图标** | 菜单图标 | 20个 | PNG/SVG | 64×64 | 功能入口 |
| | 状态图标 | 15个 | PNG | 32×32 | 游戏状态 |
| | 职业图标 | 8个 | PNG/SVG | 128×128 | 百家职业 |
| | 国家图标 | 7个 | PNG/SVG | 128×128 | 七国旗帜 |
| **按钮** | 主按钮 | 10套 | PNG | 可变 | 不同状态 |
| | 次级按钮 | 8套 | PNG | 可变 | 辅助操作 |
| | 特殊按钮 | 5套 | PNG | 可变 | 确认/取消等 |
| **UI元素** | 进度条 | 4套 | PNG | 可变 | 气血/气力等 |
| | 边框 | 6套 | PNG | 可变 | 卡牌/面板等 |
| | 对话框 | 3套 | PNG | 可变 | 提示/确认等 |
| **特效** | 点击特效 | 5种 | PNG序列 | 128×128 | 交互反馈 |
| | 胜利特效 | 3种 | PNG序列 | 256×256 | 对战结束 |
| | 技能特效 | 8种 | PNG序列 | 128×128 | 百家技能 |

### 1.2 色彩规范
| 用途 | 主色 | 辅助色 | 高亮色 | 文字色 |
| :--- | :--- | :--- | :--- | :--- |
| **整体基调** | #D2B48C (土黄) | #8B4513 (马鞍棕) | #CD7F32 (青铜) | #3C2F2F (深褐) |
| **秦国** | #8B0000 (暗红) | #B22222 (砖红) | #FF4500 (橙红) | #FFFFFF (白) |
| **燕国** | #4169E1 (皇家蓝) | #1E90FF (道奇蓝) | #87CEEB (天蓝) | #FFFFFF (白) |
| **赵国** | #8B4513 (马鞍棕) | #A0522D (赭色) | #D2691E (巧克力) | #FFFFFF (白) |
| **韩国** | #708090 (石板灰) | #778899 (浅灰) | #B0C4DE (钢蓝) | #000000 (黑) |
| **魏国** | #006400 (深绿) | #228B22 (森林绿) | #32CD32 (酸橙绿) | #FFFFFF (白) |
| **楚国** | #800080 (紫色) | #9370DB (中紫) | #DA70D6 (兰紫) | #FFFFFF (白) |
| **齐国** | #DAA520 (金菊色) | #FFD700 (金色) | #FFE4B5 (鹿皮) | #000000 (黑) |

## 二、背景图设计

### 2.1 主菜单背景（5张）

| ID | 名称 | 描述 | AI提示词 |
| :--- | :--- | :--- | :--- |
| BG001 | **战国七国图** | 战国时期地图，七国分界清晰，都城标注，水墨风格 | `战国时期地图，七国疆域分明，水墨画风格，都城标注，竹简质感背景，细节精致，4K分辨率，--ar 16:9` |
| BG002 | **稷下学宫** | 齐国稷下学宫，百家学者辩论，学术氛围浓厚 | `战国时期稷下学宫，百家学者辩论，建筑宏伟，竹简书卷堆积，学术氛围，水墨画风格，4K，--ar 16:9` |
| BG003 | **战场风云** | 两军对垒，战车、骑兵、步兵阵列，硝烟弥漫 | `战国时期战场，两军对垒，战车冲锋，骑兵列阵，硝烟弥漫，水墨战争画，气势磅礴，4K，--ar 16:9` |
| BG004 | **宫廷朝会** | 战国宫廷，君主与大臣议事，青铜器装饰 | `战国时期宫廷，君主与大臣朝会议事，青铜器装饰，帷幔低垂，庄严肃穆，水墨画风格，4K，--ar 16:9` |
| BG005 | **市集繁华** | 战国市集，商人交易，百姓往来，生活气息 | `战国时期市集，商人交易，百姓往来，货物琳琅满目，生活气息浓厚，水墨风俗画，4K，--ar 16:9` |

### 2.2 对战背景（7张 - 按国家）

| ID | 国家 | 名称 | 描述 | AI提示词 |
| :--- | :--- | :--- | :--- | :--- |
| BG101 | **秦** | **咸阳宫** | 秦国咸阳宫，黑色主调，法家严整 | `秦国咸阳宫，黑色建筑，法家严整风格，青铜装饰，庄严肃穆，水墨画，4K，--ar 16:9` |
| BG102 | **燕** | **燕下都** | 燕国都城，北方风格，慷慨悲歌 | `燕国都城，北方建筑风格，慷慨悲歌氛围，风雪背景，水墨画，4K，--ar 16:9` |
| BG103 | **赵** | **邯郸城** | 赵国邯郸，胡服骑射，骑兵训练场 | `赵国邯郸城，胡服骑射风格，骑兵训练场，草原背景，水墨画，4K，--ar 16:9` |
| BG104 | **韩** | **新郑城** | 韩国新郑，四战之地，防御工事 | `韩国新郑城，四战之地，防御工事完善，工匠忙碌，水墨画，4K，--ar 16:9` |
| BG105 | **魏** | **大梁城** | 魏国大梁，中原霸主，魏武卒训练 | `魏国大梁城，中原霸主气势，魏武卒训练场，军事氛围，水墨画，4K，--ar 16:9` |
| BG106 | **楚** | **郢都城** | 楚国郢都，南方风格，楚文化瑰丽 | `楚国郢都城，南方建筑风格，楚文化瑰丽，凤凰图腾，水墨画，4K，--ar 16:9` |
| BG107 | **齐** | **临淄城** | 齐国临淄，商业繁华，稷下学宫 | `齐国临淄城，商业繁华，稷下学宫可见，富庶景象，水墨画，4K，--ar 16:9` |

### 2.3 加载背景（3张）

| ID | 名称 | 描述 | AI提示词 |
| :--- | :--- | :--- | :--- |
| BG201 | **竹简展开** | 竹简缓缓展开，文字浮现，战国典籍 | `竹简缓缓展开，战国文字浮现，典籍质感，水墨动画风格，4K，--ar 16:9` |
| BG202 | **青铜鼎纹** | 青铜鼎上纹饰旋转，神秘古老 | `青铜鼎纹饰旋转，神秘古老，战国纹样，金属质感，4K，--ar 16:9` |
| BG203 | **星象运转** | 战国星象图，星辰运转，阴阳家神秘 | `战国星象图，星辰运转，阴阳家神秘氛围，天文观测，水墨画，4K，--ar 16:9` |

## 三、图标设计

### 3.1 菜单图标（20个）

| ID | 名称 | 用途 | 设计描述 | 尺寸 |
| :--- | :--- | :--- | :--- | :--- |
| IC001 | **征战** | 主菜单-开始对战 | 交叉的剑与戟，战国兵器 | 64×64 |
| IC002 | **兵书阁** | 主菜单-卡牌收藏 | 展开的竹简，上有兵字 | 64×64 |
| IC003 | **市集** | 主菜单-商店 | 战国钱币与货物 | 64×64 |
| IC004 | **军令状** | 主菜单-任务系统 | 卷轴与印章 | 64×64 |
| IC005 | **幕僚** | 主菜单-好友系统 | 两个对话的人物剪影 | 64×64 |
| IC006 | **天梯** | 排位赛入口 | 阶梯与星辰 | 64×64 |
| IC007 | **演武场** | 练习模式 | 训练木桩与兵器 | 64×64 |
| IC008 | **史册** | 历史战绩 | 厚重的竹简册 | 64×64 |
| IC009 | **设置** | 游戏设置 | 齿轮与玉璧结合 | 64×64 |
| IC010 | **退出** | 退出游戏 | 门与离别的身影 | 64×64 |
| IC011 | **卡组编辑** | 卡组构建 | 多张卡牌堆叠 | 64×64 |
| IC012 | **英雄选择** | 选择英雄 | 王冠与百家符号 | 64×64 |
| IC013 | **匹配中** | 匹配等待 | 沙漏与战国纹样 | 64×64 |
| IC014 | **观战** | 观看对战 | 眼睛与战场 | 64×64 |
| IC015 | **成就** | 成就系统 | 玉璧与铭文 | 64×64 |
| IC016 | **邮件** | 消息系统 | 竹简书信 | 64×64 |
| IC017 | **帮助** | 游戏帮助 | 问号与竹简 | 64×64 |
| IC018 | **分享** | 分享功能 | 扩散的波纹 | 64×64 |
| IC019 | **声音** | 音量控制 | 编钟与声波 | 64×64 |
| IC020 | **语言** | 语言切换 | 多国文字竹简 | 64×64 |

### 3.2 状态图标（15个）

| ID | 名称 | 用途 | 设计描述 | 尺寸 |
| :--- | :--- | :--- | :--- | :--- |
| ST001 | **气血** | 生命值 | 心脏与血滴，战国纹样边框 | 32×32 |
| ST002 | **气力** | 法力值 | 旋转的气流，玉璧形状 | 32×32 |
| ST003 | **攻击** | 攻击力 | 剑刃与数字 | 32×32 |
| ST004 | **防御** | 护甲值 | 盾牌与数字 | 32×32 |
| ST005 | **手牌** | 手牌数量 | 手持的卡牌 | 32×32 |
| ST006 | **牌库** | 剩余牌数 | 竹简堆叠 | 32×32 |
| ST007 | **回合** | 回合数 | 日晷与数字 | 32×32 |
| ST008 | **连胜** | 连胜记录 | 火焰与数字 | 32×32 |
| ST009 | **在线** | 在线状态 | 绿色玉璧 | 32×32 |
| ST010 | **离线** | 离线状态 | 灰色玉璧 | 32×32 |
| ST011 | **忙碌** | 忙碌状态 | 红色玉璧 | 32×32 |
| ST012 | **VIP** | 会员标识 | 金色王冠 | 32×32 |
| ST013 | **新消息** | 未读消息 | 红色竹简 | 32×32 |
| ST014 | **活动** | 活动标识 | 彩带与玉璧 | 32×32 |
| ST015 | **警告** | 警告提示 | 三角形与感叹号，战国纹样 | 32×32 |

### 3.3 职业图标（8个）

| ID | 职业 | 设计描述 | 颜色 | 尺寸 |
| :--- | :--- | :--- | :--- | :--- |
| CL001 | **兵家** | 交叉的剑与戟，战车轮廓 | #8B4513 | 128×128 |
| CL002 | **法家** | 法槌与律令竹简 | #006400 | 128×128 |
| CL003 | **儒家** | 展开的《论语》竹简 | #DAA520 | 128×128 |
| CL004 | **道家** | 太极图与拂尘 | #228B22 | 128×128 |
| CL005 | **墨家** | 齿轮与机关弩 | #708090 | 128×128 |
| CL006 | **阴阳家** | 五行图与星辰 | #800080 | 128×128 |
| CL007 | **纵横家** | 合纵连横地图与短剑 | #4169E1 | 128×128 |
| CL008 | **杂家** | 多种元素融合 | #D2B48C | 128×128 |

### 3.4 国家图标（7个 - 七国旗帜）

| ID | 国家 | 设计描述 | 主色 | 尺寸 |
| :--- | :--- | :--- | :--- | :--- |
| CT001 | **秦** | 玄鸟图腾，黑色背景 | #8B0000 | 128×128 |
| CT002 | **燕** | 燕子与长城，蓝色背景 | #4169E1 | 128×128 |
| CT003 | **赵** | 胡服骑射，棕色背景 | #8B4513 | 128×128 |
| CT004 | **韩** | 弩机与城墙，灰色背景 | #708090 | 128×128 |
| CT005 | **魏** | 魏武卒与长戟，绿色背景 | #006400 | 128×128 |
| CT006 | **楚** | 凤凰与荆楚纹样，紫色背景 | #800080 | 128×128 |
| CT007 | **齐** | 海岱与货币，金色背景 | #DAA520 | 128×128 |

## 四、按钮设计

### 4.1 主按钮（10套 - 不同状态）

| 状态 | 正常 | 悬停 | 按下 | 禁用 | 尺寸规范 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **样式** | 青铜质感，凸起 | 金色高光 | 凹陷效果 | 灰色，无光泽 | 高度48px，圆角8px |
| **文字** | 白色，阴影 | 亮白色 | 深色 | 灰色 | 字体：汉仪篆书繁 |
| **边框** | 战国纹样 | 纹样发光 | 纹样加深 | 纹样淡化 | 2px边框 |
| **示例** | 开始游戏 | 开始游戏 | 开始游戏 | 开始游戏 | 宽度自适应 |

**按钮类型**：
1. **确认按钮** - 绿色基调，对勾符号
2. **取消按钮** - 红色基调，叉号符号
3. **开始按钮** - 金色基调，剑戟交叉
4. **返回按钮** - 蓝色基调，箭头向左
5. **下一步按钮** - 蓝色基调，箭头向右
6. **购买按钮** - 金色基调，钱币符号
7. **分享按钮** - 紫色基调，扩散波纹
8. **设置按钮** - 灰色基调，齿轮符号
9. **帮助按钮** - 青色基调，问号符号
10. **退出按钮** - 暗红色基调，门符号

### 4.2 次级按钮（8套）

| 类型 | 设计描述 | 尺寸 | 使用场景 |
| :--- | :--- | :--- | :--- |
| **文字按钮** | 仅文字，无背景，悬停下划线 | 高度32px | 次要操作 |
| **图标按钮** | 圆形，仅图标，青铜边框 | 40×40 | 工具栏 |
| **标签按钮** | 标签样式，可选中状态 | 高度36px | 分类筛选 |
| **开关按钮** | 滑动开关，战国纹样 | 60×30 | 设置开关 |
| **下拉按钮** | 带向下箭头的按钮 | 高度40px | 选择菜单 |
| **翻页按钮** | 左右箭头，竹简样式 | 40×40 | 翻页控制 |
| **最小化按钮** | 减号符号，青铜圆 | 30×30 | 窗口控制 |
| **关闭按钮** | 叉号符号，青铜圆 | 30×30 | 窗口关闭 |

### 4.3 特殊按钮（5套）

| 类型 | 设计描述 | 状态 | 使用场景 |
| :--- | :--- | :--- | :--- |
| **回合结束** | 大型青铜钟，点击敲响 | 正常/高亮/禁用 | 对战界面 |
| **英雄技能** | 职业图标圆形，能量环绕 | 可用/不可用/冷却 | 英雄技能 |
| **卡牌详情** | 放大镜与竹简 | 正常/激活 | 查看卡牌 |
| **表情按钮** | 战国面具表情 | 正常/选中 | 聊天表情 |
| **录制按钮** | 青铜鼎与光晕 | 正常/录制中 | 对战录制 |

## 五、UI元素设计

### 5.1 进度条（4套）

| 类型 | 设计描述 | 尺寸 | 使用场景 |
| :--- | :--- | :--- | :--- |
| **气血条** | 红色液体流动，心脏搏动效果 | 长度200px，高度20px | 英雄生命值 |
| **气力条** | 蓝色气流旋转，玉璧分段 | 长度150px，高度15px | 法力值 |
| **经验条** | 金色竹简展开，文字浮现 | 长度180px，高度12px | 玩家经验 |
| **加载条** | 竹简从左到右展开 | 长度300px，高度8px | 加载进度 |

**进度条状态**：
- 正常：颜色饱满，动态效果
- 危险（低于30%）：闪烁警告，颜色变暗
- 满值：发光效果，特殊动画
- 空值：灰色，无动态

### 5.2 边框（6套）

| 类型 | 设计描述 | 九宫格切片 | 使用场景 |
| :--- | :--- | :--- | :--- |
| **卡牌边框** | 竹简样式，四角青铜包角 | 20×20×20×20 | 卡牌外框 |
| **面板边框** | 战国纹样，青铜质感 | 30×30×30×30 | UI面板 |
| **对话框边框** | 卷轴展开效果 | 40×40×40×40 | 对话提示 |
| **头像边框** | 圆形玉璧，职业颜色 | 圆形，无切片 | 玩家头像 |
| **输入框边框** | 简牍样式，书写区域 | 15×15×15×15 | 文本输入 |
| **特殊边框** | 传说卡牌，玉石镶嵌 | 30×30×30×30 | 稀有物品 |

### 5.3 对话框（3套）

| 类型 | 设计描述 | 尺寸规范 | 使用场景 |
| :--- | :--- | :--- | :--- |
| **提示对话框** | 小型卷轴，简洁提示 | 宽度300px，自适应高度 | 操作提示 |
| **确认对话框** | 中型竹简，按钮区域 | 宽度400px，高度200px | 确认操作 |
| **详情对话框** | 大型卷轴，多页内容 | 宽度500px，高度300px | 详细信息 |

**对话框元素**：
- 标题栏：青铜横条，战国纹样
- 内容区：羊皮纸质感，竹简纹理
- 按钮区：底部对齐，按钮间距
- 关闭按钮：右上角青铜叉号

## 六、特效设计

### 6.1 点击特效（5种）

| ID | 名称 | 帧数 | 尺寸 | 描述 |
| :--- | :--- | :--- | :--- | :--- |
| FX001 | **青铜涟漪** | 8帧 | 128×128 | 点击水面般涟漪，青铜色 |
| FX002 | **竹简展开** | 10帧 | 128×128 | 竹简快速展开又合拢 |
| FX003 | **玉璧光晕** | 6帧 | 128×128 | 玉璧发光扩散 |
| FX004 | **墨点扩散** | 8帧 | 128×128 | 水墨点点击扩散 |
| FX005 | **星辰闪烁** | 12帧 | 128×128 | 星辰点击后闪烁消失 |

### 6.2 胜利特效（3种）

| ID | 名称 | 帧数 | 尺寸 | 描述 |
| :--- | :--- | :--- | :--- | :--- |
| FX101 | **胜利烟花** | 24帧 | 256×256 | 战国纹样烟花绽放 |
| FX102 | **凯旋编钟** | 20帧 | 256×256 | 编钟敲响，音波扩散 |
| FX103 | **王者加冕** | 30帧 | 256×256 | 王冠落下，光芒四射 |

### 6.3 技能特效（8种 - 按职业）

| 职业 | 特效名称 | 帧数 | 尺寸 | 描述 |
| :--- | :--- | :--- | :--- | :--- |
| **兵家** | 剑气纵横 | 15帧 | 128×128 | 剑气划过，战旗飘扬 |
| **法家** | 律令束缚 | 12帧 | 128×128 | 律令文字缠绕目标 |
| **儒家** | 仁爱光辉 | 10帧 | 128×128 | 温暖光芒，治愈效果 |
| **道家** | 太极旋转 | 20帧 | 128×128 | 太极图旋转，阴阳调和 |
| **墨家** | 机关启动 | 18帧 | 128×128 | 齿轮转动，机械运转 |
| **阴阳家** | 五行元素 | 16帧 | 128×128 | 金木水火土元素轮转 |
| **纵横家** | 合纵连横 | 14帧 | 128×128 | 地图线条连接，策略网络 |
| **杂家** | 百家融合 | 22帧 | 128×128 | 多种元素融合，色彩斑斓 |

## 七、字体设计

### 7.1 字体选择
| 用途 | 字体名称 | 字号 | 颜色 | 效果 |
| :--- | :--- | :--- | :--- | :--- |
| **标题** | 汉仪篆书繁 | 24-36px | #3C2F2F | 阴影，青铜色描边 |
| **正文** | 方正清刻本悦宋 | 16-18px | #3C2F2F | 无效果 |
| **按钮** | 汉仪篆书繁 | 18-20px | #FFFFFF | 阴影，轻微描边 |
| **卡牌名称** | 汉仪小篆体 | 14px | #3C2F2F | 无效果 |
| **卡牌描述** | 方正清刻本悦宋 | 12px | #3C2F2F | 行间距1.2 |
| **数字** | DIN Condensed | 20-24px | #FFFFFF | 阴影，粗体 |

### 7.2 特殊字符
- **气血符号**：❤️（红色心脏）
- **气力符号**：⚡（蓝色闪电）
- **攻击符号**：⚔️（交叉剑）
- **防御符号**：🛡️（盾牌）
- **费用符号**：◎（玉璧）
- **稀有度符号**：★（星星，颜色不同）

## 八、AI生成提示词模板

### 8.1 Midjourney模板
```
战国时期UI元素，[元素名称]，[详细描述]，水墨画风格，战国纹样，[颜色描述]，细节精致，透明背景，4K分辨率，--ar [比例] --style raw --no [排除元素]
```

**示例**：
```
战国时期UI图标，兵家职业图标，交叉的剑与戟，战车轮廓，马鞍棕色(#8B4513)，水墨画风格，战国纹样，细节精致，透明背景，4K分辨率，--ar 1:1 --style raw --no text, modern
```

### 8.2 Stable Diffusion模板
```
(masterpiece, best quality, ultra-detailed), 战国时期UI元素，[元素名称]，[详细描述]，水墨画风格，战国纹样，[颜色描述]，细节精致，透明背景，4K分辨率，
Negative prompt: modern, photo, 3D, cartoon, anime, western, European, text, watermark
Steps: 30, Sampler: DPM++ 2M Karras, CFG scale: 7, Seed: -1, Size: [尺寸]
```

### 8.3 DALL-E模板
```
A Warring States period UI element of [元素名称], [详细描述], in Chinese ink painting style, with Warring States patterns, [颜色描述], highly detailed, transparent background, 4K resolution, [比例] aspect ratio
```

## 九、实现规范

### 9.1 文件命名规范
```
[类型]_[ID]_[名称]_[状态]_[尺寸].png

示例：
icon_cl001_bingjia_normal_128x128.png
button_confirm_hover_200x48.png
bg_001_zhanguoqitu_1920x1080.png
```

### 9.2 目录结构
```
assets/
├── ui/
│   ├── backgrounds/          # 背景图
│   │   ├── menu/            # 主菜单背景
│   │   ├── battle/          # 对战背景
│   │   └── loading/         # 加载背景
│   ├── icons/               # 图标
│   │   ├── menu/            # 菜单图标
│   │   ├── status/          # 状态图标
│   │   ├── class/           # 职业图标
│   │   └── country/         # 国家图标
│   ├── buttons/             # 按钮
│   │   ├── primary/         # 主按钮
│   │   ├── secondary/       # 次级按钮
│   │   └── special/         # 特殊按钮
│   ├── elements/            # UI元素
│   │   ├── progressbars/    # 进度条
│   │   ├── borders/         # 边框
│   │   └── dialogs/         # 对话框
│   └── effects/             # 特效
│       ├── click/           # 点击特效
│       ├── victory/         # 胜利特效
│       └── skill/           # 技能特效
├── fonts/                   # 字体文件
└── sounds/                  # 音效文件
```

### 9.3 开发注意事项
1. **适配性**：所有资源需适配多种分辨率（手机、平板、桌面）
2. **性能优化**：大图压缩，小图合并雪碧图
3. **内存管理**：动态加载和卸载资源
4. **本地化**：文字与图标分离，支持多语言
5. **可访问性**：颜色对比度符合WCAG标准

## 十、实施计划

### 10.1 第一阶段（第1-2周）
- [ ] 完成色彩规范和字体选择
- [ ] 设计核心图标（菜单图标、状态图标）
- [ ] 制作主按钮和次级按钮
- [ ] 创建基础背景图（主菜单、对战背景各1张）

### 10.2 第二阶段（第3-4周）
- [ ] 完成职业图标和国家图标
- [ ] 制作特殊按钮和UI元素
- [ ] 设计进度条和边框
- [ ] 创建剩余背景图

### 10.3 第三阶段（第5-6周）
- [ ] 制作对话框和特效
- [ ] 优化所有资源，适配多分辨率
- [ ] 创建资源映射表和配置文档
- [ ] 集成测试和性能优化

### 10.4 第四阶段（第7周）
- [ ] 用户测试和反馈收集
- [ ] 根据反馈调整优化
- [ ] 最终资源打包和部署
- [ ] 文档编写和知识传递

---

**资源统计**：
- **背景图**：15张
- **图标**：50个
- **按钮**：23套（每套3-4个状态）
- **UI元素**：13套
- **特效**：16种

**总文件数**：约200+个资源文件

## 十一、AI生成负面提示词系统

### 11.1 战国风格专用负面提示词库

#### 基础负面提示词（通用）
```
blurry, low quality, distorted, ugly, deformed, disfigured, poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, floating limbs, disconnected limbs, mutation, mutated, ugly, disgusting, amputation, bad proportions, gross proportions, text, error, missing fingers, missing arms, missing legs, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, trademark, watermark, title, multiple views, comic, manga, anime, cartoon, graphic, text, painting, crayon, graphite, abstract, glitch, deformed, mutated, ugly, disfigured
```

#### 历史准确性负面提示词（战国风格专用）
```
modern clothing, modern fashion, contemporary style, futuristic, sci-fi, fantasy armor, European armor, plate armor, chainmail, medieval, renaissance, Victorian, modern weapons, guns, firearms, electricity, neon lights, LED, digital, computer generated, 3D render, CGI, photorealistic, photography, photograph, realistic, hyperrealistic, modern art, abstract art, pop art, graffiti, street art, western art, European art, Greek, Roman, Egyptian, Japanese, Korean, Indian, Arabic, Islamic, Christian, cross, church, cathedral, mosque, temple, modern building, skyscraper, glass building, concrete, steel, plastic, synthetic materials, modern technology, smartphone, computer, screen, monitor, digital display, modern vehicle, car, airplane, train, modern furniture, modern architecture
```

#### 艺术风格负面提示词（避免非战国风格）
```
oil painting, acrylic painting, watercolor, gouache, pastel, charcoal, pencil sketch, digital painting, vector art, pixel art, low poly, isometric, flat design, minimalism, modernism, impressionism, expressionism, surrealism, cubism, abstract expressionism, pop art, art deco, art nouveau, baroque, rococo, gothic, romanticism, realism, hyperrealism, photorealistic, photography, photograph, 3D render, CGI, computer generated, digital art, game art, concept art, illustration, cartoon, anime, manga, comic book, graphic novel, children's book, fantasy art, sci-fi art, steampunk, cyberpunk, dieselpunk, atompunk, biopunk, solarpunk, retrofuturism
```

#### 材质与纹理负面提示词
```
plastic, rubber, latex, vinyl, polyester, nylon, synthetic fabric, modern fabric, denim, leather, faux leather, suede, velvet, silk, satin, chiffon, lace, mesh, netting, transparent, translucent, glossy, shiny, reflective, metallic, chrome, steel, aluminum, titanium, gold plating, silver plating, platinum, diamond, gemstone, crystal, glass, acrylic, plexiglass, resin, epoxy, ceramic, porcelain, marble, granite, concrete, asphalt, brick, wood grain, modern wood, laminate, veneer, modern texture, digital texture, seamless texture, pattern, print, floral, geometric, striped, polka dot, checkered, plaid, tartan, houndstooth, herringbone, paisley
```

#### 色彩与色调负面提示词
```
neon colors, fluorescent, bright colors, vibrant colors, saturated colors, oversaturated, high contrast, low contrast, monochrome, grayscale, black and white, sepia, duotone, tritone, multitone, gradient, ombre, rainbow, prismatic, iridescent, metallic colors, chrome colors, holographic, glitter, sparkle, shine, glow, glowing, luminous, fluorescent, blacklight, UV, electric, digital colors, RGB, CMYK, Pantone, modern color palette, pastel colors, muted colors, desaturated, washed out, faded, vintage, retro, antique
```

### 11.2 按UI资源类型定制的负面提示词

#### 图标负面提示词
```
plastic, rubber, latex, vinyl, polyester, nylon, synthetic fabric, modern fabric, denim, leather, faux leather, suede, velvet, silk, satin, chiffon, lace, mesh, netting, transparent, translucent, glossy, shiny, reflective, metallic, chrome, steel, aluminum, titanium, gold plating, silver plating, platinum, diamond, gemstone, crystal, glass, acrylic, plexiglass, resin, epoxy, ceramic, porcelain, marble, granite, concrete, asphalt, brick, wood grain, modern wood, laminate, veneer, modern texture, digital texture, seamless texture, pattern, print, floral, geometric, striped, polka dot, checkered, plaid, tartan, houndstooth, herringbone, paisley, neon colors, fluorescent, bright colors, vibrant colors, saturated colors, oversaturated, high contrast, low contrast, monochrome, grayscale, black and white, sepia, duotone, tritone, multitone, gradient, ombre, rainbow, prismatic, iridescent, metallic colors, chrome colors, holographic, glitter, sparkle, shine, glow, glowing, luminous, fluorescent, blacklight, UV, electric, digital colors, RGB, CMYK, Pantone, modern color palette, pastel colors, muted colors, desaturated, washed out, faded, vintage, retro, antique
```

#### 背景图负面提示词
```
modern building, skyscraper, glass building, concrete, steel, plastic, synthetic materials, modern technology, smartphone, computer, screen, monitor, digital display, modern vehicle, car, airplane, train, modern furniture, modern architecture, oil painting, acrylic painting, watercolor, gouache, pastel, charcoal, pencil sketch, digital painting, vector art, pixel art, low poly, isometric, flat design, minimalism, modernism, impressionism, expressionism, surrealism, cubism, abstract expressionism, pop art, art deco, art nouveau, baroque, rococo, gothic, romanticism, realism, hyperrealism, photorealistic, photography, photograph, 3D render, CGI, computer generated, digital art, game art, concept art, illustration, cartoon, anime, manga, comic book, graphic novel, children's book, fantasy art, sci-fi art, steampunk, cyberpunk, dieselpunk, atompunk, biopunk, solarpunk, retrofuturism
```

#### 按钮与UI元素负面提示词
```
plastic, rubber, latex, vinyl, polyester, nylon, synthetic fabric, modern fabric, denim, leather, faux leather, suede, velvet, silk, satin, chiffon, lace, mesh, netting, transparent, translucent, glossy, shiny, reflective, metallic, chrome, steel, aluminum, titanium, gold plating, silver plating, platinum, diamond, gemstone, crystal, glass, acrylic, plexiglass, resin, epoxy, ceramic, porcelain, marble, granite, concrete, asphalt, brick, wood grain, modern wood, laminate, veneer, modern texture, digital texture, seamless texture, pattern, print, floral, geometric, striped, polka dot, checkered, plaid, tartan, houndstooth, herringbone, paisley, neon colors, fluorescent, bright colors, vibrant colors, saturated colors, oversaturated, high contrast, low contrast, monochrome, grayscale, black and white, sepia, duotone, tritone, multitone, gradient, ombre, rainbow, prismatic, iridescent, metallic colors, chrome colors, holographic, glitter, sparkle, shine, glow, glowing, luminous, fluorescent, blacklight, UV, electric, digital colors, RGB, CMYK, Pantone, modern color palette, pastel colors, muted colors, desaturated, washed out, faded, vintage, retro, antique
```

### 11.3 负面提示词使用策略

#### 策略1：精简高效版（推荐）
```
# 战国风格精简负面提示词
blurry, low quality, distorted, ugly, deformed, modern, contemporary, futuristic, sci-fi, fantasy, European, medieval, photorealistic, 3D render, CGI, digital art, cartoon, anime, manga, comic, plastic, synthetic, glossy, shiny, neon colors, bright colors, RGB, modern color palette
```

#### 策略2：分阶段使用
1. **初代生成**：使用精简版负面提示词
2. **质量筛选**：对模糊/失真的资源使用完整版重新生成
3. **风格优化**：对风格不纯的资源使用专项负面提示词

#### 策略3：按资源类型选择
- **图标**：基础 + 材质纹理 + 色彩色调
- **背景图**：基础 + 艺术风格 + 材质纹理
- **按钮与UI元素**：基础 + 材质纹理 + 色彩色调

### 11.4 AI模型适配指南

| AI模型 | 负面提示词长度 | 推荐策略 | 注意事项 |
|:---|:---|:---|:---|
| **SD1.5/SDXL** | 200-300词 | 完整版 | 可包含详细描述，避免过长 |
| **SD3.5 Large** | 50-100词 | 精简版 | 使用自然英语，避免复杂结构 |
| **Midjourney** | 50-100词 | 精简版 | 逗号分隔，关键词明确 |
| **DALL-E 3** | 50-100词 | 精简版 | 自然语言描述，避免技术术语 |

**下一步**：
1. 使用AI工具批量生成图标和背景，**必须使用对应的负面提示词**
2. 手动调整和优化关键资源
3. 集成到Flutter项目中
4. 测试UI表现和性能