# 《战国风炉石传说》AI辅助开发提示词集

## 一、项目初始化提示词

### 1.1 创建Flutter项目
```
帮我创建一个Flutter项目，支持iOS、Android、Web和桌面端。添加flame游戏引擎依赖，版本使用最新稳定版。
```

### 1.2 生成职业配置
```
根据以下战国百家职业体系，生成一个完整的职业配置文件（JSON格式）：
- 兵家·将：战士职业，正面强攻、军阵统帅，使用长戟、长戈、战车
- 阴阳家·术士：法师职业，五行术数、天地之力，使用五行杖、铜铃、星盘
- 儒家·夫子：牧师职业，仁者爱人、礼乐教化，使用竹简、书卷、玉圭
- 墨家·巧匠：猎人职业，机关弩手、远程狙杀，使用机关弩、飞爪、机关兽
- 道家·真人：术士职业，自然之道、御气养神，使用拂尘、葫芦、木剑
- 纵横家·策士：盗贼职业，纵横捭阖、诡道奇谋，使用短剑、竹简、算筹
- 阴阳家·巫祝：萨满职业，祭祀占卜、通灵驱邪，使用骨笛、铜鼓、符箓
- 兵家·骑士：骑士职业，甲士重骑、护国亲军，使用长枪、重甲、战马

每个职业包含：id、name（百家·流派）、description、weapons数组、class_color、rarity_border_colors、unique_mechanic描述。
```

### 1.3 生成英雄配置
```
基于战国时期历史人物，生成英雄配置文件（JSON格式），包含以下英雄：

秦国：嬴政（法家，30气血，技能"焚书坑儒"：摧毁敌方一张随从）、秦昭襄王（兵家，30气血，技能"远交近攻"：使一个友方随从获得+2/+2）
燕国：燕昭王（兵家，30气血，技能"千金买骨"：抽一张牌）、荆轲（纵横家，30气血，技能"图穷匕见"：造成2点伤害）
赵国：赵武灵王（兵家，30气血，技能"胡服骑射"：所有友方随从获得冲锋）、廉颇（兵家，30气血，技能"负荆请罪"：获得5点护甲）
韩国：韩昭侯（法家，30气血，技能"申子变法"：减少手牌中所有卡牌1点费用）
魏国：魏文侯（法家，30气血，技能"变法图强"：所有友方随从+1/+1）、吴起（兵家，30气血，技能"吴子兵法"：造成3点伤害）
楚国：楚怀王（儒家，30气血，技能"郢都之盟"：恢复3点气血）、屈原（儒家，30气血，技能"九歌天问"：对所有敌方随从造成1点伤害）
齐国：齐威王（纵横家，30气血，技能"一鸣惊人"：发现一张卡牌）、孙膑（兵家，30气血，技能"围魏救赵"：使一个友方随从获得嘲讽）

每个英雄包含：id、name、class（百家）、kingdom（七国）、base_health、hero_power_name、hero_power_text、hero_power_cost、flavor_text、art_path。
```

## 二、卡牌生成提示词

### 2.1 生成兵家卡牌
```
基于战国兵家主题，生成20张兵家卡牌，分为随从和法术两类。要求：
- 随从名称参考历史兵种：魏武卒、秦锐士、赵边骑、燕死士、楚锐卒、齐技击士、韩戟兵
- 法术名称参考兵法典故：围魏救赵、破釜沉舟、背水一战、暗度陈仓、声东击西
- 随从费用范围1-10，攻击力与生命值之和约为费用的两倍
- 稀有度分布：10张普通、6张稀有、3张史诗、1张传说
- 传说卡牌设计为"孙武"，9费7/7，战吼：摧毁所有敌方随从
- 输出JSON格式，包含id、name、type、cost、attack、health、class、kingdom、rarity、text、mechanics、art字段
```

### 2.2 生成法家卡牌
```
基于战国法家主题，生成20张法家卡牌。要求：
- 随从名称：执法吏、刑徒、狱卒、律令官、司寇、大理、法家弟子
- 法术名称：刑名之法、峻法严刑、一断于法、以法治国
- 法家特色：擅长破甲、减益、控制效果
- 输出JSON格式，包含id、name、type、cost、attack、health、class、rarity、text、mechanics、art字段
```

### 2.3 生成儒家卡牌
```
基于战国儒家主题，生成20张儒家卡牌。要求：
- 随从名称：儒生、礼官、乐师、典狱官、君子、贤人、夫子
- 法术名称：仁政化民、礼乐同春、教化众生、仁义之师
- 儒家特色：擅长治疗、增益、控制效果
- 英雄卡：孟子（5费5/5，效果：战吼：抽一张牌，如果是随从牌，使其获得+2/+2）
- 输出JSON格式
```

### 2.4 生成道家卡牌
```
基于战国道家主题，生成20张道家卡牌。要求：
- 随从名称：道童、守山人、观星者、符师、真人、隐士、方士
- 法术名称：道法自然、无为而治、上善若水、虚静无为
- 道家特色：擅长减速、封印、减益效果
- 传说卡牌：老子（8费6/6，效果：战吼：使你手牌中所有法术费用减少2点）
- 输出JSON格式
```

### 2.5 生成墨家卡牌
```
基于战国墨家主题，生成20张墨家卡牌。要求：
- 随从名称：机关弩手、机关兽、墨家弟子、护城弩兵、守城工兵、攻城巨械
- 法术名称：兼爱非攻、墨守成规、机关之术、挡矢之术
- 墨家特色：擅长陷阱、召唤、护盾效果
- 传说卡牌：墨子（7费5/7，效果：亡语：召唤两个2/2的机关兽）
- 输出JSON格式
```

### 2.6 生成阴阳家卡牌
```
基于战国阴阳家主题，生成20张阴阳家卡牌。要求：
- 随从名称：巫祝、占卜师、五行弟子、祭司、星象师、风水师
- 法术名称：五行相生、阴阳调和、天象异变、占星问卜
- 阴阳家特色：擅长元素伤害、天气效果、诅咒与增益
- 传说卡牌：邹衍（8费4/8，效果：战吼：对所有敌人施放随机五行效果）
- 输出JSON格式
```

## 三、UI界面提示词

### 3.1 主菜单界面
```
使用Flutter和Flame创建一个战国风主菜单界面，包含以下元素：
- 背景：战国七国地图
- 按钮：征战、兵书阁、市集、军令状、幕僚
- 顶部：玩家等级、名称、金币数量
- 风格：竹简纹理、青铜纹饰、土黄/青铜色调
- 字体：使用古风字体（如汉碑字体或篆书风格字体）
```

### 3.2 对战界面
```
使用Flame创建一个完整的炉石传说式对战界面，要求：
- 顶部：对手信息栏（英雄立绘、姓名、气血值、手牌数量）
- 中部：战场区域（可容纳7个随从位置，带有格线参考）
- 底部：己方信息栏（手牌区、气力值显示、英雄技能按钮）
- 右侧：回合结束按钮（青铜器风格）
- 英雄：嬴政（秦）、楚怀王（楚）
- 卡牌展示效果：悬停放大、出牌动画、攻击动画
- 音效占位符（出牌声、攻击声、法术声）
```

### 3.3 卡牌组件
```
使用Flame创建一个卡牌组件，要求：
- 外观：竹简样式边框，中间显示卡牌插画
- 属性栏：左上角费用（气力），右下角攻击/气血（随从卡）
- 稀有度边框颜色：普通青铜、稀有白银、史诗黄金、传说玉石
- 属性栏背景：职业对应颜色
- 交互：拖拽出牌、点击查看详情
- 卡牌名称使用小篆风格字体
```

## 四、游戏逻辑提示词

### 4.1 战斗管理器
```
创建一个完整的炉石传说式战斗管理器，包含：
- 回合管理系统（开始阶段-抽牌、主要阶段-行动、结束阶段-结算）
- 卡牌出牌验证（费用检查、目标合法性、回合检查）
- 伤害计算系统（攻击伤害、法术伤害、持续伤害）
- 随从攻击系统（攻击后状态更新、反击伤害）
- 状态效果系统（战吼、亡语、冲锋、嘲讽、圣盾等的战国风实现）
- 胜负判定系统（气血归零、疲劳伤害、特殊胜利条件）

使用TypeScript/Dart实现，要求代码模块化、可扩展。
```

### 4.2 AI对战系统
```
创建一个简单的AI对战系统，要求：
- AI决策树：评估出牌、攻击目标选择
- 基础策略：优先使用气力、优先攻击敌方随从、保护己方高价值随从
- 难度分级：简单（随机出牌）、普通（基础策略）、困难（考虑卡牌组合）
- 延迟模拟：AI行动间隔0.5-1秒，模拟人类思考
```

## 五、服务器端提示词

### 5.1 后端架构
```
设计一个炉石传说风格卡牌游戏的后端架构，要求：
- 语言：Node.js / Go
- 通信：WebSocket实时通信
- 数据库：MongoDB（卡牌数据）/ Redis（匹配队列、对战状态）
- 微服务架构：账号服务、匹配服务、对战服务、商店服务
- 每个对战房间独立状态管理
- 反作弊系统：服务端完全校验所有操作合法性
```

### 5.2 匹配系统
```
创建一个基于ELO等级分的匹配系统，要求：
- 天梯分范围：0-3000
- 匹配规则：优先匹配天梯分±100内的玩家
- 超时放大：每30秒扩大100分搜索范围
- 连胜/连败调整：连胜时匹配稍强对手，连败时匹配稍弱对手
- 数据库存储：玩家天梯分、胜率、匹配记录
```

## 六、资源制作提示词

### 6.1 美术资源规格
```
为战国风卡牌游戏制定美术资源制作规格：
- 英雄立绘：256x256像素，PNG格式，透明背景
- 卡牌插画：512x512像素，PNG格式
- 随从图标：128x128像素，PNG格式
- 法术图标：128x128像素，PNG格式（圆形裁剪）
- UI元素：按实际尺寸，PNG格式，支持九宫格拉伸
- 色彩规范：
  - 背景：土黄色 #D2B48C
  - UI主色：青铜色 #CD7F32
  - 秦：#8B0000（暗红）
  - 燕：#4169E1（皇家蓝）
  - 赵：#8B4513（马鞍棕）
  - 韩：#708090（石板灰）
  - 魏：#006400（深绿）
  - 楚：#800080（紫色）
  - 齐：#DAA520（金菊色）
```

## 七、测试提示词

### 7.1 生成测试用例
```
为战国风卡牌游戏生成测试用例，覆盖：
- 卡牌替换正确性（原ID→新文案映射验证）
- 技能效果验证（每种关键词至少2个测试）
- UI显示验证（多分辨率适配）
- 性能测试（100张卡牌同屏渲染帧率）
- 网络测试（延迟、断线重连）
- 边界测试（满手牌、满场随从、0气血）
```

---

## 八、AI生成负面提示词系统

### 8.1 战国风格专用负面提示词库

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

### 8.2 按资源类型定制的负面提示词

#### 卡牌插画负面提示词
```
modern clothing, contemporary style, futuristic, sci-fi, fantasy armor, European armor, plate armor, chainmail, medieval, renaissance, Victorian, modern weapons, guns, firearms, peaceful, calm, serene, gentle, soft, delicate, fragile, weak, timid, fearful, cowardly, retreating, surrendering, defeated, wounded, injured, bleeding, dying, dead, corpse, skeleton, ghost, spirit, phantom, demon, monster, creature, animal, beast, dragon, phoenix, unicorn, mythical creature, fantasy creature, magical creature, supernatural, magical, mystical, occult, wizard, witch, sorcerer, mage, magic, spell, enchantment, curse, blessing, divine, holy, sacred, religious, spiritual, ritual, ceremony, celebration, festival, party, gathering, crowd, mob, riot, chaos, disorder, confusion, mess, dirty, messy, cluttered
```

#### UI元素负面提示词
```
plastic, rubber, latex, vinyl, polyester, nylon, synthetic fabric, modern fabric, denim, leather, faux leather, suede, velvet, silk, satin, chiffon, lace, mesh, netting, transparent, translucent, glossy, shiny, reflective, metallic, chrome, steel, aluminum, titanium, gold plating, silver plating, platinum, diamond, gemstone, crystal, glass, acrylic, plexiglass, resin, epoxy, ceramic, porcelain, marble, granite, concrete, asphalt, brick, wood grain, modern wood, laminate, veneer, modern texture, digital texture, seamless texture, pattern, print, floral, geometric, striped, polka dot, checkered, plaid, tartan, houndstooth, herringbone, paisley, neon colors, fluorescent, bright colors, vibrant colors, saturated colors, oversaturated, high contrast, low contrast, monochrome, grayscale, black and white, sepia, duotone, tritone, multitone, gradient, ombre, rainbow, prismatic, iridescent, metallic colors, chrome colors, holographic, glitter, sparkle, shine, glow, glowing, luminous, fluorescent, blacklight, UV, electric, digital colors, RGB, CMYK, Pantone, modern color palette, pastel colors, muted colors, desaturated, washed out, faded, vintage, retro, antique
```

### 8.3 负面提示词使用策略

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
- **卡牌插画**：基础 + 历史准确性 + 艺术风格
- **UI元素**：基础 + 材质纹理 + 色彩色调

### 8.4 AI模型适配指南

| AI模型 | 负面提示词长度 | 推荐策略 | 注意事项 |
|:---|:---|:---|:---|
| **SD1.5/SDXL** | 200-300词 | 完整版 | 可包含详细描述，避免过长 |
| **SD3.5 Large** | 50-100词 | 精简版 | 使用自然英语，避免复杂结构 |
| **Midjourney** | 50-100词 | 精简版 | 逗号分隔，关键词明确 |
| **DALL-E 3** | 50-100词 | 精简版 | 自然语言描述，避免技术术语 |

**使用说明**：
1. 将上述提示词直接复制到AI编程助手（如Cursor、Claude、ChatGPT等）
2. 按照章节顺序逐步执行
3. 每次执行后验证结果，根据实际情况调整提示词参数
4. 生成的代码和配置文件统一存放于项目目录中
5. **AI生成资源时**：必须使用对应的负面提示词，确保风格统一

**文档版本**：v1.1  
**最后更新**：2026-05-28  
**更新内容**：新增AI生成负面提示词系统章节