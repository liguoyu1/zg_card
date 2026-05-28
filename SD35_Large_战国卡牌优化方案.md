# Stable Diffusion 3.5 Large 战国卡牌优化方案

## 一、根因分析

### SD3.5 Large 与 SD1.5/SDXL 的关键区别

| 特性 | SD1.5/SDXL | SD3.5 Large |
|:---|:---|:---|
| **提示词语言** | 英语为主，中文勉强 | **仅支持英语自然语言** |
| **分辨率** | 512×512 / 1024×1024 | **推荐 1024×1024 及以上** |
| **提示词风格** | 标签堆砌（关键词逗号分隔） | **自然语言完整句子** |
| **负面提示词** | 必须 | **效果减弱，更多靠正向** |
| **CFG Scale** | 7-9 | **4-6（更低）** |
| **步数** | 20-40 | **28-50（更多）** |
| **VAE** | 独立 | **内置 T5 XXL 编码器** |

### 你的三个失败原因

1. **图1模糊**：分辨率可能过低（< 1024），或 CFG scale 过高导致过曝
2. **图2空洞**：提示词可能用了中文或标签格式，SD3.5 无法理解
3. **图3极致模糊**：步数不够或采样器不对，T5 编码器输出被截断

## 二、SD3.5 Large 专用提示词格式

### 核心原则：自然英语完整句

**错误（标签堆砌，SD1.5 风格）**：
```
warring states, Wei Wu soldier, heavy armor, bamboo texture, ink painting
```

**正确（SD3.5 风格）**：
```
A heavily armored Wei soldier from the Warring States period of ancient China stands in a military camp, wearing bronze scale armor and holding a long halberd. The scene is rendered in traditional Chinese ink wash painting style with bamboo scroll textures and bronze patina effects. The soldier's expression is fierce and determined. Detailed 4K resolution, sharp focus.
```

### 提示词模板

```
# SD3.5 卡牌插画标准模板

A detailed illustration of [角色描述] from ancient China's Warring States period, 
[动作姿态], [背景环境]. 
Rendered in traditional Chinese ink wash painting style with [纹理] textures, 
[色彩] tones, and [装饰纹样] decorative patterns. 
The artwork has [稀有度光效]. 
High resolution, sharp focus, professional illustration quality.
```

### 200张卡牌 SD3.5 专用提示词（直接使用）

#### 兵家卡牌（20张）

**B001 魏武卒（普通）**
```
A heavily armored Wei soldier from ancient China's Warring States period standing tall in a military encampment, wearing layered bronze scale armor and gripping a long halberd with both hands, his expression fierce and unyielding against a backdrop of military tents and banners. Rendered in traditional Chinese ink wash painting style with visible bamboo scroll texture overlays, bronze patina effects, and cloud thunder decorative patterns around the edges. Muted earth brown and bronze tones. High resolution, sharp focus on the armor details.
```

**B002 秦锐士（普通）**
```
An elite Qin dynasty light infantry soldier from the Warring States period charging forward with a Qin-style bronze sword raised high, wearing leather armor and a distinctive Qin helmet, against a formation of black Qin banners and soldiers in the background. Traditional Chinese ink wash painting style with bamboo texture and kui dragon decorative patterns. Dark red and bronze color scheme. Sharp focus on the sword and determined face.
```

**B003 赵边骑（普通）**
```
A Zhao kingdom cavalry scout from ancient China's Warring States period mounted on a brown warhorse galloping across the northern grasslands, holding a long cavalry spear, with flowing horse mane and dust trailing behind. Traditional Chinese ink wash painting with pan chi dragon decorative motifs and bamboo scroll textures. Brown and gold tones. Clear details on the horse and rider.
```

**B004 齐技击（普通）**
```
A Qi kingdom elite archer from the Warring States period drawing a powerful composite bow, aiming at a distant target, standing on the walls of a Qi city with watchtowers visible behind. Chinese ink wash painting style with bamboo texture overlays. Bronze and navy blue tones. Sharp focus on the bowstring tension and archer's concentrated expression.
```

**B005 楚材官（普通）**
```
A Chu kingdom heavy infantry soldier from the Warring States period wielding a long dagger-axe weapon in a southern jungle clearing, wearing distinctive southern armor with phoenix feather decorations, surrounded by lush vegetation and mist. Traditional Chinese ink wash painting with phoenix motifs and bamboo scroll texture. Purple and green tones. Details clearly visible.
```

**B006 韩弩手（普通）**
```
A Han kingdom crossbowman from the Warring States period crouching in a mountain ambush position, holding a heavy mechanical crossbow with the string drawn taut, against rocky Korean mountain terrain. Chinese ink wash painting style with bamboo texture and bronze effects. Grey and silver tones. Sharp focus on the crossbow mechanism.
```

**B007 燕死士（普通）**
```
A Yan kingdom death warrior from the Warring States period charging fearlessly through snowy terrain with a short bronze sword, wearing fur-lined northern armor, icy wind blowing his cloak. Traditional Chinese ink wash painting with bamboo scroll texture. Blue-white and bronze tones. Clear details on the sword and snow particles.
```

**B008 孙武（传说）**
```
Sun Wu, the legendary military strategist of ancient China's Warring States period, standing atop a war chariot holding a bamboo scroll of The Art of War, with thousands of soldiers formed behind him under a dramatic sky. Divine golden light radiates from the scroll. Traditional Chinese ink wash painting with dragon and phoenix decorative patterns, jade-green legendary glow effects around the border, and bamboo texture overlays. Extraordinary detail, professional illustration, sharp focus.
```

**B009 吴起（史诗）**
```
Wu Qi, the renowned general of the Warring States period, commanding Wei troops from horseback with a raised command flag, his expression authoritative and calculating, against the backdrop of a massive Wei military camp with hundreds of tents. Traditional Chinese ink wash painting with double dragon decorative motifs, golden epic card glow effects radiating from behind. Bronze and gold tones. Sharp focus on the general's face and command flag.
```

**B010 白起（传说）**
```
Bai Qi, the fearsome Qin general known as the God of Slaughter from the Warring States period, standing amid the aftermath of the Battle of Changping, holding a blood-stained bronze sword, a crimson aura surrounding him against a dark stormy sky. Traditional Chinese ink wash painting with legendary jade-green glow effects at the edges, dragon and phoenix decorative patterns. Deep red and black tones. Extraordinary detail on the armor and blood effects.
```

**B011 王翦（史诗）**
```
Wang Jian, the elderly Qin strategist from the Warring States period, seated in a command tent studying a detailed battle map spread across a wooden table, his weathered face illuminated by candlelight, war banners visible through the tent entrance. Chinese ink wash painting with golden epic glow effects and dragon motifs. Bronze and earth tones. Sharp focus on the map details and general's contemplative expression.
```

**B012 廉颇（稀有）**
```
Lian Po, the elderly but formidable Zhao general from the Warring States period, his white hair flowing as he grips a long spear, standing defiantly on the Zhao Great Wall section, his aged but powerful physique showing through his armor. Traditional Chinese ink wash painting with silver rare card glow effects and kui dragon patterns. Grey and bronze tones. Details on the weathered face and spear tip.
```

**B013 李牧（稀有）**
```
Li Mu, the Zhao general famed for defeating the Xiongnu nomads during the Warring States period, riding a black warhorse and drawing a composite bow on the northern grasslands, dust clouds rising behind. Chinese ink wash painting with silver glow effects. Bronze and green tones. Sharp focus on the bow and determined expression.
```

**B014 田单（稀有）**
```
Tian Dan, the Qi strategist of the Warring States period, holding a flaming torch while directing the famous Fire Ox Formation, burning cattle charging in the background toward the besieged city of Jimo. Traditional Chinese ink wash painting with silver glow effects and pan chi patterns. Orange and bronze tones. Details on the torch flames and strategist's face.
```

**B015 项燕（史诗）**
```
Xiang Yan, the last great general of Chu kingdom during the Warring States period, wielding an ornate Chu-style halberd in a southern marshland battlefield, phoenix banners fluttering behind him as mist rises from the water. Chinese ink wash painting with golden epic glow and phoenix decorative motifs. Purple and gold tones. Sharp focus on the weapon details and general's heroic stance.
```

**B016 乐毅（史诗）**
```
Yue Yi, the Yan kingdom commander who led the coalition of five states against Qi during the Warring States period, holding a command arrow high while standing before the walls of a Qi city under siege, coalition banners of five states arrayed behind him. Traditional Chinese ink wash painting with golden epic glow effects. Blue and gold tones. Details on the command arrow and coalition banners.
```

**B017 蒙恬（史诗）**
```
Meng Tian, the Qin general and guardian of the Great Wall during the Warring States period, standing atop a completed section of the Qin Great Wall holding a Qin sword, looking out over the northern frontier with watchtowers stretching into the distance. Chinese ink wash painting with golden epic glow effects. Black and red tones. Sharp focus on the sword and the sweeping landscape.
```

**B018 赵奢（稀有）**
```
Zhao She, the Zhao general victorious at the Battle of Eyu during the Warring States period, gripping a horse whip while surveying the mountainous Eyu battlefield from high ground, his Zhao cavalry visible in the valley below. Traditional Chinese ink wash painting with silver glow effects. Brown and green tones. Details on the whip and general's confident expression.
```

**B019 庞涓（普通）**
```
Pang Juan, the Wei general during the Warring States period, ambushed at Maling Pass, struck by arrows while falling from his horse amid a narrow mountain defile, Wei banners collapsing around him. Chinese ink wash painting style with bamboo texture and cloud thunder patterns. Dark tones. Clear details on the falling figure and arrows.
```

**B020 孙膑（传说）**
```
Sun Bin, the brilliant military strategist of the Warring States period, seated in a wheelchair at the Qi military headquarters, holding bamboo scrolls of military strategy, with ghostly troop formations materializing around him representing his tactical genius. Divine light emanates from the scrolls. Traditional Chinese ink wash painting with legendary jade glow, dragon and phoenix patterns. Extraordinary detail, professional illustration quality.
```

#### 法家卡牌（20张）

**F001 执法吏（普通）**
```
A Legalist law enforcement officer from ancient China's Warring States period in official robes standing sternly in a courtroom, holding bamboo slips inscribed with legal codes, his expression severe and unyielding. A bronze ritual vessel sits on the desk. Traditional Chinese ink wash painting with bamboo scroll texture and cloud thunder decorative patterns. Deep green and earth tones. Sharp focus on the law slips.
```

**F002 刑徒（普通）**
```
A prisoner in the Legalist system of the Warring States period wearing rough hemp clothing with wooden cangue around his neck, kneeling in a dark stone prison cell, iron chains visible. Chinese ink wash painting style with bamboo texture. Dark grey and bronze tones. Clear details on the cangue and chains.
```

**F003 狱吏（普通）**
```
A Legalist prison guard from the Warring States period standing watch in a stone corridor of a dungeon, holding bronze torture instruments and a heavy iron key ring at his belt, torchlight casting shadows on the wall. Traditional Chinese ink wash painting with bamboo texture. Dark green and bronze tones. Sharp focus on the instruments.
```

**F004 令史（普通）**
```
A Legalist clerk official of the Warring States period seated at a wooden desk in a government office, meticulously recording cases on bamboo slips with a writing brush, stacks of legal documents surrounding him. Chinese ink wash painting with bamboo texture and cloud thunder patterns. Earth tones. Details on the writing scene.
```

**F005 廷尉（稀有）**
```
A high-ranking Legalist Chief Justice of the Warring States period seated on an elevated platform in a grand courtroom, holding a ceremonial bronze gavel, law code banners hanging behind him. Traditional Chinese ink wash painting with silver glow effects and kui dragon decorative patterns. Deep green and bronze tones. Sharp focus on the gavel and judicial robes.
```

**F006 御史（稀有）**
```
An imperial censor of the Warring States period standing before the throne holding investigation reports on bamboo slips, his expression fearless and righteous, checking official corruption. Chinese ink wash painting with silver glow effects. Bronze and red tones. Details on the reports.
```

**F007 酷吏（普通）**
```
A harsh Legalist enforcer from the Warring States period with a cruel expression raising a whip in a torture chamber, bronze punishment instruments arranged on the wall behind him. Traditional Chinese ink wash painting with bamboo texture. Dark red and bronze tones. Sharp focus on the whip and cruel face.
```

**F008 商鞅（传说）**
```
Shang Yang, the great Legalist reformer of the Warring States period, standing on a wooden platform before the Qin people in the capital, holding bamboo slips inscribed with his revolutionary new laws, golden light of reform radiating outward across the gathered crowd. Traditional Chinese ink wash painting with legendary jade-green glow effects, dragon and phoenix decorative patterns. Rich bronze and gold tones. Extraordinary detail, professional illustration quality.
```

**F009 韩非（史诗）**
```
Han Fei, the brilliant Legalist philosopher of the Warring States period, seated in his study composing the Han Feizi on bamboo slips, his intense intellectual gaze focused, stacks of philosophical texts surrounding him in candlelight. Chinese ink wash painting with golden epic glow effects and dragon motifs. Bronze and deep green tones. Sharp focus on his face and the bamboo slips.
```

**F010 李斯（史诗）**
```
Li Si, the Qin Chancellor of the Warring States period, standing in the grand hall of Xianyang Palace holding bamboo slips of standardized characters, Qin officials gathered around him as he implements the unification of writing. Traditional Chinese ink wash painting with golden epic glow. Black and red tones. Details on the character slips.
```

**F011 申不害（稀有）**
```
Shen Buhai, the Legalist chancellor of Han kingdom during the Warring States period, seated in the Han palace holding bamboo slips on the art of governance and political manipulation, his expression cunning and calculating. Chinese ink wash painting with silver glow effects. Grey and bronze tones. Sharp focus on his face.
```

**F012 慎到（稀有）**
```
Shen Dao, the Legalist scholar of the Warring States period advocating rule through positional power, debating at the Jixia Academy in Qi, holding bamboo slips on political authority, surrounded by listening scholars. Traditional Chinese ink wash painting with silver glow. Bronze and green tones. Details on the debate scene.
```

**F013 吴起法家版（稀有）**
```
Wu Qi in his role as Legalist reformer of Chu kingdom during the Warring States period, presenting reform proposals on bamboo slips before the Chu court, nobles reacting with mixed expressions. Chinese ink wash painting with silver glow effects. Purple and bronze tones. Details on the court scene.
```

**F014 管仲（史诗）**
```
Guan Zhong, the pioneering Legalist statesman serving as Chancellor of Qi during the Warring States period, standing in the Qi palace holding the Guanzi text on bamboo slips, Qi prosperity visible through palace windows. Traditional Chinese ink wash painting with golden epic glow. Blue and gold tones. Sharp focus on the chancellor.
```

**F015 子产（稀有）**
```
Zi Chan, the Legalist statesman of Zheng state during the Warring States period, overseeing the casting of bronze tripods inscribed with penal laws, artisans working at the bronze foundry behind him. Chinese ink wash painting with silver glow effects. Bronze and earth tones. Details on the tripod casting.
```

**F016 邓析（普通）**
```
Deng Xi, a folk Legalist litigator from the Warring States period, passionately arguing in a marketplace before a gathered crowd, holding litigation bamboo slips, his expression clever and persuasive. Traditional Chinese ink wash painting with bamboo texture. Earth tones. Sharp focus on the arguing figure.
```

**F017 尸佼（普通）**
```
Shi Jiao, a Legalist thinker and teacher of Shang Yang from the Warring States period, instructing students in a school hall, holding bamboo slips of legal theory, diagrams of law drawn on a wooden board. Chinese ink wash painting with bamboo texture. Bronze and green tones. Details on the teaching scene.
```

**F018 赵鞅（稀有）**
```
Zhao Yang, a Legalist statesman of Jin state during the Warring States period, standing before a cast bronze tripod inscribed with penal codes, presiding over the historic codification of laws. Traditional Chinese ink wash painting with silver glow. Bronze and red tones. Sharp focus on the tripod.
```

**F019 范雎（稀有）**
```
Fan Ju, the Qin Chancellor of the Warring States period advocating distant diplomacy and close attack strategy, presenting strategic bamboo slips in the Qin palace, his expression shrewd and calculating. Chinese ink wash painting with silver glow effects. Black and bronze tones. Details on the palace scene.
```

**F020 吕不韦（史诗）**
```
Lu Buwei, the wealthy merchant turned Qin Chancellor of the Warring States period, seated in his luxurious mansion supervising the compilation of the Lu Shi Chun Qiu encyclopedia on bamboo slips, thousands of scholars working in the background. Traditional Chinese ink wash painting with golden epic glow. Rich bronze and gold tones. Extraordinary detail.
```

#### 儒家卡牌（20张）

**R001 儒生（普通）**
```
A young Confucian scholar from ancient China's Warring States period holding bamboo slips of the Analects, standing humbly in a traditional school hall with wooden desks, his expression gentle and learned. Traditional Chinese ink wash painting with bamboo scroll texture and cloud thunder decorative patterns. Warm gold and earth tones. Sharp focus on the bamboo slips.
```

**R002 夫子（普通）**
```
An elderly Confucian teacher from the Warring States period holding a discipline ruler while instructing young students in a private school, shelves of bamboo books behind him. Chinese ink wash painting with bamboo texture. Warm earth tones. Details on the teacher and students.
```

**R003 礼生（普通）**
```
A Confucian ritual master from the Warring States period conducting an elaborate ceremony at an ancestral temple, holding bronze ritual vessels, incense smoke rising. Traditional Chinese ink wash painting with bamboo texture. Gold and bronze tones. Sharp focus on the ritual.
```

**R004 乐师（普通）**
```
A Confucian music master from the Warring States period playing an ancient guqin zither in a music chamber, bronze bells and stone chimes arranged behind, his expression serene. Chinese ink wash painting with bamboo texture. Warm tones. Details on the zither.
```

**R005 史官（稀有）**
```
A Confucian court historian from the Warring States period recording events with a writing brush at a history bureau, bamboo slips chronicling dynasties stacked to the ceiling, his expression impartial and truthful. Traditional Chinese ink wash painting with silver glow effects and kui dragon patterns. Gold and bronze tones. Sharp focus.
```

**R006 博士（稀有）**
```
A Confucian academic doctor from the Warring States period lecturing at the Jixia Academy, holding classical texts on bamboo slips, surrounded by attentive scholars from all schools. Chinese ink wash painting with silver glow. Gold and green tones. Details on the academy.
```

**R007 祭酒（稀有）**
```
The Confucian academy head and libationer from the Warring States period holding a bronze wine vessel while presiding over an academic ceremony, grand academy architecture behind him. Traditional Chinese ink wash painting with silver glow. Gold and bronze tones. Details on the ceremony.
```

**R008 孔子（传说）**
```
Confucius, the great sage of the Warring States period, traveling between states with his loyal disciples following on foot, his expression radiating benevolence and wisdom, holding bamboo slips of the classics, a golden aura of humanity surrounding him against the landscapes of ancient China. Traditional Chinese ink wash painting with legendary jade-green glow effects, dragon and phoenix decorative patterns. Extraordinary detail, professional illustration quality, sharp focus.
```

**R009 孟子（史诗）**
```
Mencius, the Confucian sage of the Warring States period advocating goodness of human nature, standing before a Qi king debating philosophy while holding bamboo slips of the Mencius, his expression confident and righteous. Chinese ink wash painting with golden epic glow effects. Gold and red tones. Sharp focus on the debate.
```

**R010 荀子（史诗）**
```
Xunzi, the Confucian philosopher of the Warring States period advocating that human nature is evil, teaching students at Lanling in Chu, holding the Xunzi text on bamboo slips, his expression intellectual and stern. Traditional Chinese ink wash painting with golden epic glow. Purple and gold tones. Details on the teaching scene.
```

**R011 曾子（稀有）**
```
Zengzi, the Confucian disciple of the Warring States period and filial piety exemplar, holding the Classic of Filial Piety on bamboo slips, kneeling respectfully before his aged parents. Chinese ink wash painting with silver glow effects. Warm gold tones. Sharp focus on filial piety.
```

**R012 子思（稀有）**
```
Zisi, grandson of Confucius from the Warring States period, holding the Doctrine of the Mean on bamboo slips, seated in contemplation at the Confucian ancestral home in Lu. Traditional Chinese ink wash painting with silver glow. Gold and green tones. Details on the contemplative figure.
```

**R013 子夏（普通）**
```
Zixia, the Confucian literature specialist from the Warring States period, holding the Book of Songs on bamboo slips while teaching at Xihe in Wei, his expression scholarly and refined. Chinese ink wash painting with bamboo texture. Green and bronze tones. Details on the teaching.
```

**R014 子游（普通）**
```
Ziyou, the Confucian ritual specialist from the Warring States period, holding the Book of Rites on bamboo slips while governing Wucheng, ritual implements on his desk. Traditional Chinese ink wash painting with bamboo texture. Gold tones. Sharp focus on the bamboo slips.
```

**R015 子张（普通）**
```
Zizhang, the Confucian virtue specialist from the Warring States period, holding bamboo slips on virtuous conduct while teaching in Chen state, his expression earnest and sincere. Chinese ink wash painting with bamboo texture. Warm earth tones. Details on the teaching.
```

**R016 子贡（稀有）**
```
Zigong, the Confucian eloquence specialist and accomplished diplomat from the Warring States period, traveling between states with diplomatic credentials, his expression eloquent and persuasive. Traditional Chinese ink wash painting with silver glow. Gold and bronze tones. Sharp focus on the diplomat.
```

**R017 冉有（普通）**
```
Ran You, the Confucian governance specialist from the Warring States period, holding governance bamboo slips while serving at the Ji family estate, administrative documents on his desk. Chinese ink wash painting with bamboo texture. Earth tones. Details on the office.
```

**R018 颜回（史诗）**
```
Yan Hui, Confucius's most virtuous disciple from the Warring States period, living contentedly in a humble alley dwelling, a simple bowl and gourd on a plain mat, his expression radiating inner peace despite poverty. Traditional Chinese ink wash painting with golden epic glow. Gold and warm tones. Extraordinary spiritual quality.
```

**R019 子路（稀有）**
```
Zilu, the Confucian disciple known for bravery and righteousness from the Warring States period, wearing armor and carrying a sword while protecting Confucius during travels, his expression loyal and fearless. Chinese ink wash painting with silver glow. Bronze and red tones. Sharp focus on his armor.
```

**R020 宰我（普通）**
```
Zai Wo, the Confucian disciple known for sharp eloquence from the Warring States period, engaged in lively debate at a school, his expression clever and quick-witted, gesticulating passionately. Traditional Chinese ink wash painting with bamboo texture. Earth tones. Details on the debate.
```

#### 道家卡牌（20张）

**D001 道童（普通）**
```
A young Daoist apprentice from the Warring States period holding a white horsetail whisk, standing innocently before a mountain Daoist temple gate, morning mist swirling around. Traditional Chinese ink wash painting with bamboo scroll texture and cloud thunder patterns. Green and white tones. Sharp focus on the child.
```

**D002 道士（普通）**
```
A Daoist priest from the Warring States period wielding a peachwood sword while performing a ritual on a Daoist altar, talisman papers and incense burners arranged, his expression focused. Chinese ink wash painting with bamboo texture. Green and gold tones. Details on the ritual.
```

**D003 方士（普通）**
```
A Daoist alchemist from the Warring States period tending a bronze alchemical furnace in a dim workshop, holding a pill vessel, seeking immortality elixirs, colorful smoke rising. Traditional Chinese ink wash painting with bamboo texture. Bronze and green tones. Sharp focus on the furnace.
```

**D004 隐士（普通）**
```
A Daoist hermit from the Warring States period fishing peacefully by a mountain stream, wearing simple hemp clothing, his bamboo fishing rod extended, secluded in nature. Chinese ink wash painting with bamboo texture. Green and grey tones. Details on the hermit.
```

**D005 真人（稀有）**
```
An enlightened Daoist Perfected Being from the Warring States period floating above misty mountain peaks, his robes flowing in ethereal wind, radiating transcendent energy, holding a jade scepter. Traditional Chinese ink wash painting with silver glow effects and kui dragon patterns. Jade green and gold tones. Sharp focus.
```

**D006 仙姑（稀有）**
```
A Daoist immortal maiden from the Warring States period standing by the Jade Pool of the Queen Mother of the West, holding a sacred lotus flower, celestial mist swirling around her, her expression serene and transcendent. Chinese ink wash painting with silver glow. Pink and jade tones. Details on the celestial scene.
```

**D007 炼气士（稀有）**
```
A Daoist Qi cultivation master from the Warring States period meditating in a mountain grotto, visible energy currents swirling around his body, inner alchemy symbols floating, his eyes closed in deep concentration. Traditional Chinese ink wash painting with silver glow. Green and gold tones. Sharp focus on the energy.
```

**D008 老子（传说）**
```
Laozi, the founder of Daoism from the Warring States period, riding a black water buffalo westward through Hangu Pass, purple qi rising from the east illuminating the entire scene, the Daodejing text manifesting as luminous characters floating around him, his expression profoundly serene and wise. Traditional Chinese ink wash painting with legendary jade-green glow effects, dragon and phoenix patterns. Extraordinary detail, professional illustration quality, sharp focus.
```

**D009 庄子（史诗）**
```
Zhuangzi, the great Daoist philosopher of the Warring States period, dreaming of being a butterfly amid a lacquer tree garden, butterflies dancing around his reclining figure, the boundary between dream and reality dissolving. Chinese ink wash painting with golden epic glow effects. Purple and gold tones. Sharp focus on the dreamlike scene.
```

**D010 列子（史诗）**
```
Liezi, the Daoist sage of the Warring States period, riding the wind itself while floating through the skies above Zheng state, his robes billowing in the cosmic breeze, holding the Liezi bamboo scrolls. Traditional Chinese ink wash painting with golden epic glow. Blue and white tones. Extraordinary detail on the wind riding.
```

**D011 文子（稀有）**
```
Wenzi, the Daoist sage and disciple of Laozi from the Warring States period, seated in a Chu kingdom garden composing the Wenzi text, his expression deeply contemplative of the Dao. Chinese ink wash painting with silver glow. Purple and gold tones. Details on the writing.
```

**D012 关尹子（普通）**
```
Guan Yinzi, the Keeper of Hangu Pass from the Warring States period, standing at the pass gate welcoming the approaching Laozi on his ox, his expression reverent and expectant. Traditional Chinese ink wash painting with bamboo texture. Brown and gold tones. Sharp focus on the meeting.
```

**D013 亢仓子（普通）**
```
Kangcangzi, the Daoist sage of the Warring States period demonstrating supernatural perception by seeing through his ears and hearing through his eyes, his expression tranquil, floating symbols around his head. Chinese ink wash painting with bamboo texture. Green tones. Details on the supernatural scene.
```

**D014 鹖冠子（普通）**
```
Heguanzi, the reclusive Daoist sage of the Warring States period wearing his distinctive brown pheasant-feather cap, living deep in the mountains, his expression serene and detached from worldly affairs. Traditional Chinese ink wash painting with bamboo texture. Brown and green tones. Sharp focus on the cap.
```

**D015 彭祖（史诗）**
```
Pengzu, the legendary Daoist immortal of the Warring States period who lived over eight hundred years, standing in a celestial paradise holding a peachwood longevity staff, his white beard flowing to his waist, peaches of immortality hanging from nearby trees. Chinese ink wash painting with golden epic glow. Peach pink and gold tones. Extraordinary detail on the immortal.
```

**D016 广成子（稀有）**
```
Guangchengzi, the Daoist immortal sage of the Warring States period who taught the Yellow Emperor, seated in meditation on Kongtong Mountain, ancient wisdom radiating from him, a bronze sword at his side. Traditional Chinese ink wash painting with silver glow. Gold and bronze tones. Sharp focus on the sage.
```

**D017 赤松子（稀有）**
```
Chisongzi, the Daoist Rain Master immortal of the Warring States period, commanding clouds and summoning rain amid a vast sea of clouds, water droplets suspended around his outstretched hand. Chinese ink wash painting with silver glow. Blue and white tones. Details on the rain magic.
```

**D018 宁封子（普通）**
```
Ningfengzi, the Daoist pottery master of the Warring States period, seated at his kiln holding an exquisitely crafted ceramic vessel, colorful glaze smoke rising from the kiln fire. Traditional Chinese ink wash painting with bamboo texture. Earth and fire tones. Sharp focus on the pottery.
```

**D019 容成公（普通）**
```
Rongchenggong, the Daoist master of nourishing life practices from the Warring States period, holding bamboo slips on health cultivation in his mountain grotto, medicinal herbs hanging to dry. Chinese ink wash painting with bamboo texture. Green tones. Details on the cultivation.
```

**D020 尹喜（稀有）**
```
Yin Xi, the gatekeeper who recognized Laozi and received the Daodejing at Hangu Pass during the Warring States period, eagerly transcribing Laozi's words on bamboo slips at the pass gate, his expression reverent. Traditional Chinese ink wash painting with silver glow. Gold and brown tones. Sharp focus on the transcription.
```

#### 墨家卡牌（20张）

**M001 机关弩手（普通）**
```
A Mohist repeating crossbow engineer from ancient China's Warring States period holding an intricate mechanical crossbow with visible bronze gears and mechanisms, standing in a Mohist workshop filled with mechanical inventions. Traditional Chinese ink wash painting with bamboo scroll texture and cloud thunder patterns. Bronze and green tones. Sharp focus on the mechanism.
```

**M002 工匠（普通）**
```
A Mohist master craftsman from the Warring States period working with precision tools on a wooden mechanical device in a bright workshop, his expression focused on his craft, wood shavings on the floor. Chinese ink wash painting with bamboo texture. Bronze and wood tones. Details on the crafting scene.
```

**M003 守城士（普通）**
```
A Mohist siege defense engineer from the Warring States period operating a complex defensive mechanism atop a city wall, siege equipment visible below, his expression determined to protect the city. Traditional Chinese ink wash painting with bamboo texture. Bronze and grey tones. Sharp focus on the defense equipment.
```

**M004 辩士（普通）**
```
A Mohist debater from the Warring States period passionately arguing against offensive warfare at an academy, holding bamboo slips on universal love, his expression persuasive and principled. Chinese ink wash painting with bamboo texture. Bronze and green tones. Details on the debate.
```

**M005 巨子（稀有）**
```
A Mohist Grand Master and organization leader from the Warring States period standing in the Mohist headquarters holding a ceremonial carpenter's square, Mohist disciples arrayed behind him, his expression commanding and principled. Traditional Chinese ink wash painting with silver glow effects and kui dragon patterns. Bronze and jade tones. Sharp focus on the leader.
```

**M006 侠客（稀有）**
```
A Mohist wandering knight-errant from the Warring States period striding through a bustling marketplace with a bronze sword at his side, his expression righteous and protective of the common people. Chinese ink wash painting with silver glow. Bronze and red tones. Details on the warrior.
```

**M007 医者（稀有）**
```
A Mohist physician from the Warring States period practicing universal love through healing, holding a medicine chest while treating a wounded commoner, his expression compassionate. Traditional Chinese ink wash painting with silver glow. Green and warm tones. Sharp focus on the healing.
```

**M008 墨子（传说）**
```
Mozi, the founder of Mohism from the Warring States period, holding a carpenter's square and compass symbolizing universal standards, surrounded by his mechanical beast inventions and defensive constructs, radiating wisdom and principle against offensive warfare. Traditional Chinese ink wash painting with legendary jade-green glow effects, dragon and phoenix decorative patterns. Extraordinary detail, professional illustration quality, sharp focus.
```

**M009 禽滑厘（史诗）**
```
Qin Guli, the foremost disciple of Mozi and siege defense expert from the Warring States period, standing on the walls of Song state directing the deployment of Mohist defensive engines, his expression resolute. Chinese ink wash painting with golden epic glow. Bronze and green tones. Sharp focus.
```

**M010 孟胜（史诗）**
```
Meng Sheng, the Mohist Grand Master of the Warring States period who sacrificed himself defending the city of Yangcheng, standing defiantly amid burning city walls, his Mohist disciples fighting alongside him. Traditional Chinese ink wash painting with golden epic glow. Red and bronze tones. Dramatic detail on the sacrifice.
```

**M011 田鸠（普通）**
```
Tian Jiu, a Mohist emissary from the Warring States period traveling between states to promote Mohist philosophy, holding bamboo slips, his traveling cloak dust-covered from long journeys. Chinese ink wash painting with bamboo texture. Brown and green tones. Details on the traveler.
```

**M012 腹䵍（稀有）**
```
Fu Tun, a Mohist leader in Qin during the Warring States period, enforcing Mohist laws impartially even against his own son, his expression stern and principled, standing in a Qin courtroom. Traditional Chinese ink wash painting with silver glow. Black and bronze tones. Sharp focus on the judgment.
```

**M013 相里氏（普通）**
```
A Mohist of the Xiangli lineage from the Warring States period, ancestor of the great Mohist Xiangli Qin, working diligently in a Mohist mechanical workshop with specialized tools. Chinese ink wash painting with bamboo texture. Bronze tones. Details on the workshop.
```

**M014 相夫氏（普通）**
```
A Mohist of the Xiangfu lineage, representing the debating faction of Mohism during the Warring States period, holding bamboo slips at an academy debate, his expression sharp and logical. Traditional Chinese ink wash painting with bamboo texture. Green tones. Sharp focus on the debate.
```

**M015 邓陵氏（普通）**
```
A Mohist of the Dengling lineage, representing the knight-errant faction of Mohism during the Warring States period, carrying a bronze sword while traveling through the countryside seeking injustice to correct. Chinese ink wash painting with bamboo texture. Bronze and earth tones. Details on the warrior.
```

**M016 苦获（稀有）**
```
Ku Huo, the Mohist master debater of the Warring States period, engaged in a fierce philosophical debate in Qi state, his expression intensely focused, bamboo slips of argumentation in hand. Traditional Chinese ink wash painting with silver glow. Green and gold tones. Sharp focus on the debate.
```

**M017 已齿（普通）**
```
Yi Chi, the Mohist scholar and friend of Ku Huo from the Warring States period, holding bamboo slips in quiet contemplation at an academy, his expression thoughtful. Chinese ink wash painting with bamboo texture. Green tones. Details on the scholar.
```

**M018 曹公子（普通）**
```
Prince Cao of Song state, a Mohist patron from the Warring States period, standing in Song court robes while supporting Mohist teachings, his expression supportive. Traditional Chinese ink wash painting with bamboo texture. Purple and gold tones. Sharp focus on the patron.
```

**M019 高石子（稀有）**
```
Gao Shizi, the Mohist who resigned from office in Wei rather than compromise principles during the Warring States period, leaving the Wei palace with dignity, his bamboo slips of resignation in hand. Chinese ink wash painting with silver glow. Bronze and green tones. Details on the principled departure.
```

**M020 耕柱子（普通）**
```
Gengzhuzi, a Mohist disciple of the Warring States period driving a horse-drawn cart while serving the Mohist cause, his expression humble and dedicated, traveling through the countryside. Traditional Chinese ink wash painting with bamboo texture. Earth tones. Details on the cart.
```

#### 阴阳家卡牌（20张）

**Y001 巫祝（普通）**
```
A Yin-Yang school shaman priest from ancient China's Warring States period conducting a sacred ritual at a stone altar, holding a bone flute, mysterious smoke swirling, his expression entranced. Traditional Chinese ink wash painting with bamboo scroll texture and cloud thunder patterns. Purple and bronze tones. Sharp focus on the ritual.
```

**Y002 占卜师（普通）**
```
A Yin-Yang school diviner from the Warring States period casting oracle bones inscribed with fiery cracks into the air, interpreting omens in a darkened divination chamber lit by candlelight. Chinese ink wash painting with bamboo texture. Bronze and purple tones. Details on the bones.
```

**Y003 星官（普通）**
```
A Yin-Yang school court astronomer from the Warring States period observing the night sky from a high observation tower, holding a star chart on bamboo slips, constellations mapped above. Traditional Chinese ink wash painting with bamboo texture. Blue and gold tones. Sharp focus on the astronomy.
```

**Y004 方士阴阳版（普通）**
```
A Yin-Yang school alchemist from the Warring States period seeking immortality on a mythical mountain, holding a glowing pill of immortality, celestial energy swirling around the peak. Chinese ink wash painting with bamboo texture. Purple and gold tones. Details on the immortal quest.
```

**Y005 大祭司（稀有）**
```
A grand Yin-Yang priest from the Warring States period presiding over a major state sacrificial ceremony at a grand temple, holding ornate bronze ritual vessels, hundreds of worshippers below. Traditional Chinese ink wash painting with silver glow effects and kui dragon patterns. Purple and gold tones. Sharp focus.
```

**Y006 预言家（稀有）**
```
A Yin-Yang school prophet from the Warring States period foretelling future events in a mystical chamber, his eyes glowing with cosmic insight, visions of future battles manifesting around him. Chinese ink wash painting with silver glow. Purple and blue tones. Details on the prophecy.
```

**Y007 通灵者（稀有）**
```
A Yin-Yang school medium from the Warring States period communing with spirits in a ritual circle, holding paper talismans, spirit entities manifesting in ethereal forms around the chamber. Traditional Chinese ink wash painting with silver glow. Purple and jade tones. Sharp focus on the medium.
```

**Y008 邹衍（传说）**
```
Zou Yan, the great Yin-Yang philosopher of the Warring States period, discoursing on the cosmos with the Five Elements rotating around him in a grand cosmic diagram, the nine continents of his theory manifesting below, his expression profoundly wise. Traditional Chinese ink wash painting with legendary jade-green glow effects, dragon and phoenix decorative patterns. Five cosmic colors. Extraordinary detail, professional illustration quality, sharp focus.
```

**Y009 邹奭（史诗）**
```
Zou Shi, the brilliant Yin-Yang disciple of Zou Yan during the Warring States period, his literary talents manifesting as carved dragons swirling around him while he composes texts at the Jixia Academy. Chinese ink wash painting with golden epic glow. Purple and gold tones. Sharp focus.
```

**Y010 公孙发（史诗）**
```
Gongsun Fa, the Yin-Yang school Five Elements master of the Warring States period, holding a complex Five Elements interaction diagram on bamboo slips, elements manifesting as colored energies around him in the academy. Traditional Chinese ink wash painting with golden epic glow. Five element colors. Sharp focus on the diagram.
```

**Y011 南公（普通）**
```
The Southern Duke, a Yin-Yang Daoist master from Chu during the Warring States period, holding Daoist texts while meditating in a Chu garden, southern mist surrounding him. Chinese ink wash painting with bamboo texture. Purple and green tones. Details on the meditation.
```

**Y012 闾丘子（普通）**
```
Luqiuzi, a Yin-Yang alchemist from Qi during the Warring States period, holding secret immortality formulas on bamboo slips in a Qi workshop, mysterious ingredients on his table. Traditional Chinese ink wash painting with bamboo texture. Bronze and purple tones. Sharp focus on the formulas.
```

**Y013 安期生（普通）**
```
Anqi Sheng, the Yin-Yang immortal from the Warring States period, standing on a mythical island in the Eastern Sea, holding a peach of immortality, waves crashing against mystical rocks. Chinese ink wash painting with bamboo texture. Blue and gold tones. Details on the immortal.
```

**Y014 宋毋忌（普通）**
```
Song Wuji, the Yin-Yang Fire Immortal from the Warring States period, wielding flames in both hands while standing amid a volcanic landscape, his expression fierce and transcendent. Traditional Chinese ink wash painting with bamboo texture. Red and orange tones. Sharp focus on the flames.
```

**Y015 正伯侨（史诗）**
```
Zheng Boqiao, the Yin-Yang immortal who achieved transcendence during the Warring States period, holding an immortal's staff while ascending through celestial clouds toward a heavenly realm. Chinese ink wash painting with golden epic glow. Gold and white tones. Extraordinary transcendent quality.
```

**Y016 羡门高（稀有）**
```
Xianmen Gao, the Yin-Yang alchemist from Yan during the Warring States period, holding rare immortality herbs while standing on a Yan mountain peak, northern lights flickering in the sky above. Traditional Chinese ink wash painting with silver glow. Blue and purple tones. Sharp focus on the herbs.
```

**Y017 充尚（普通）**
```
Chong Shang, a Yin-Yang alchemist from Zhao during the Warring States period, holding secret formulas on bamboo slips while working at a Zhao workshop, his expression intense. Chinese ink wash painting with bamboo texture. Brown and purple tones. Details on the workshop.
```

**Y018 公孙卿（普通）**
```
Gongsun Qing, a Yin-Yang alchemist from the Warring States period serving the Han court, presenting immortal texts on bamboo slips before the emperor, his expression confident. Traditional Chinese ink wash painting with bamboo texture. Gold and red tones. Sharp focus on the presentation.
```

**Y019 李少君（普通）**
```
Li Shaojun, a Yin-Yang alchemist from the Warring States period serving Emperor Wu of Han, tending a bronze alchemical furnace seeking the elixir of life, mysterious vapors rising. Chinese ink wash painting with bamboo texture. Bronze and gold tones. Details on the alchemy.
```

**Y020 栾大（稀有）**
```
Luan Da, a Yin-Yang master of supernatural arts from the Warring States period serving the Han court, displaying magical powers in the imperial palace, his expression confident and mysterious. Traditional Chinese ink wash painting with silver glow. Red and gold tones. Sharp focus on the magic.
```

#### 武器卡牌（20张）

**W001 青铜剑（普通）**
```
An ancient Chinese Warring States period bronze sword displayed against a bamboo scroll background, the elongated double-edged blade showing intricate cloud thunder pattern engravings, bronze patina with subtle green oxidation, ceremonial tassels at the pommel. Traditional Chinese ink wash painting style. Rich bronze tones. Sharp focus on blade details.
```

**W002 吴钩（普通）**
```
An ancient Chinese Warring States period Wu hook curved blade weapon from the Wu-Yue region displayed against bamboo scroll background, the distinctive hooked bronze blade showing engraved patterns, the curvature elegant and deadly. Chinese ink wash painting style. Bronze tones. Sharp focus on the hook.
```

**W003 越王剑（稀有）**
```
The legendary Sword of King Goujian of Yue from ancient China's Warring States period displayed against bamboo scroll background, the perfectly preserved bronze blade gleaming after two thousand years with intricate lozenge pattern and bird script inscriptions, a silver glow radiating from the ancient weapon. Traditional Chinese ink wash painting with silver glow effects. Rich bronze tones. Extraordinary detail on inscriptions.
```

**W004 秦弩（普通）**
```
An ancient Chinese Warring States period Qin dynasty heavy crossbow displayed against bamboo scroll background, the complex bronze trigger mechanism visible, wooden stock showing age, the powerful weapon that unified China. Chinese ink wash painting style. Bronze and wood tones. Sharp focus on mechanism.
```

**W005 楚戈（普通）**
```
An ancient Chinese Warring States period Chu kingdom dagger-axe weapon displayed against bamboo scroll background, the bronze blade head showing phoenix decorative patterns, the long wooden shaft with bronze fittings. Traditional Chinese ink wash painting style. Purple and bronze tones. Sharp focus on blade.
```

**W006 赵戟（普通）**
```
An ancient Chinese Warring States period Zhao kingdom halberd displayed against bamboo scroll background, the complex bronze head combining spear point and axe blade, the weapon of Zhao cavalry, intricate decorative engravings. Chinese ink wash painting style. Bronze tones. Sharp focus on complexity.
```

**W007 齐矛（普通）**
```
An ancient Chinese Warring States period Qi kingdom long spear displayed against bamboo scroll background, the sharp bronze spearhead showing eastern coastal decorative patterns, the long shaft wrapped with cord. Traditional Chinese ink wash painting style. Bronze tones. Sharp focus on spearhead.
```

**W008 燕刀（普通）**
```
An ancient Chinese Warring States period Yan kingdom ring-pommel knife displayed against bamboo scroll background, the northern-style bronze blade with distinctive ring at the pommel, practical and deadly. Chinese ink wash painting style. Bronze tones. Sharp focus on the ring pommel.
```

**W009 韩弓（稀有）**
```
An ancient Chinese Warring States period Han kingdom composite bow displayed against bamboo scroll background, the masterfully crafted bow showing layers of horn and sinew, the string taut, known as the finest bows of the era. Traditional Chinese ink wash painting with silver glow effects. Wood and bronze tones. Sharp focus on craftsmanship.
```

**W010 魏盾（普通）**
```
An ancient Chinese Warring States period Wei kingdom large shield displayed against bamboo scroll background, the bronze-rimmed wooden shield showing Wei military insignia, battle scars visible on the surface. Chinese ink wash painting style. Bronze and brown tones. Sharp focus on shield details.
```

**W011 吴戈（稀有）**
```
An ancient Chinese Warring States period Wu kingdom ornate dagger-axe displayed against bamboo scroll background, the bronze blade head showing exquisite southern decorative patterns, the weapon of Wu nobility. Traditional Chinese ink wash painting with silver glow. Bronze tones. Sharp focus on ornamentation.
```

**W012 越戟（普通）**
```
An ancient Chinese Warring States period Yue kingdom halberd displayed against bamboo scroll background, the southern-style bronze blade with distinctive Yue decorative patterns, elegant proportions. Chinese ink wash painting style. Bronze tones. Sharp focus on blade.
```

**W013 秦剑（史诗）**
```
An ancient Chinese Warring States period Qin dynasty standardized bronze sword displayed against bamboo scroll background, the weapon that armed the army that unified China, showing standardized Qin manufacturing marks, a golden epic glow radiating. Traditional Chinese ink wash painting with golden epic glow effects. Black and bronze tones. Extraordinary detail.
```

**W014 楚剑（稀有）**
```
An ancient Chinese Warring States period Chu kingdom ornate bronze sword displayed against bamboo scroll background, the blade showing elaborate phoenix motif engravings, gold inlay work reflecting Chu artistic excellence. Chinese ink wash painting with silver glow. Purple and gold tones. Sharp focus on inlay.
```

**W015 赵刀（普通）**
```
An ancient Chinese Warring States period Zhao kingdom cavalry saber displayed against bamboo scroll background, the curved bronze blade designed for mounted combat, practical northern design. Traditional Chinese ink wash painting style. Bronze tones. Sharp focus on curvature.
```

**W016 齐戈（普通）**
```
An ancient Chinese Warring States period Qi kingdom dagger-axe displayed against bamboo scroll background, the eastern coastal-style bronze blade showing marine motif patterns, the weapon of Qi warriors. Chinese ink wash painting style. Bronze and blue tones. Sharp focus on marine motifs.
```

**W017 燕剑（稀有）**
```
An ancient Chinese Warring States period Yan kingdom bronze sword displayed against bamboo scroll background, the northern-style blade showing distinctive Yan decorative patterns, the weapon of Yan border warriors. Traditional Chinese ink wash painting with silver glow. Bronze and blue tones. Sharp focus on northern style.
```

**W018 秦王剑（传说）**
```
The Sword of King Zheng of Qin, who would become the First Emperor of China during the Warring States period, displayed against bamboo scroll background, the imperial bronze sword radiating overwhelming authority and the power of unification, legendary jade-green glow effects, dragon motifs engraved on the blade, the weapon that symbolized the end of the Warring States. Traditional Chinese ink wash painting with legendary glow effects. Black, gold, and jade tones. Extraordinary detail, professional illustration quality.
```

**W019 楚王剑（史诗）**
```
An ancient Chinese Warring States period King of Chu ceremonial bronze sword displayed against bamboo scroll background, the lavishly decorated blade with phoenix motifs in gold inlay, the weapon representing Chu royal authority. Chinese ink wash painting with golden epic glow. Purple and gold tones. Extraordinary ornamental detail.
```

**W020 越王矛（稀有）**
```
An ancient Chinese Warring States period King of Yue ceremonial bronze spear displayed against bamboo scroll background, the spearhead showing intricate Yue royal patterns with bird script inscriptions, the royal weapon of Yue. Traditional Chinese ink wash painting with silver glow. Bronze tones. Sharp focus on inscriptions.
```

## 三、SD3.5 Large 专用负面提示词系统

### 3.1 战国风格专用负面提示词库

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

### 3.2 按卡牌类型定制的负面提示词

#### 兵家卡牌负面提示词
```
peaceful, calm, serene, gentle, soft, delicate, fragile, weak, timid, fearful, cowardly, retreating, surrendering, defeated, wounded, injured, bleeding, dying, dead, corpse, skeleton, ghost, spirit, phantom, demon, monster, creature, animal, beast, dragon, phoenix, unicorn, mythical creature, fantasy creature, magical creature, supernatural, magical, mystical, occult, wizard, witch, sorcerer, mage, magic, spell, enchantment, curse, blessing, divine, holy, sacred, religious, spiritual, ritual, ceremony, celebration, festival, party, gathering, crowd, mob, riot, chaos, disorder, confusion, mess, dirty, messy, cluttered,杂乱, 混乱
```

#### 法家卡牌负面提示词
```
lawless, anarchic, chaotic, disorderly, unruly, rebellious, defiant, disobedient, disrespectful, irreverent, blasphemous, sacrilegious, profane, vulgar, crude, rude, impolite, uncivilized, barbaric, savage, primitive, tribal, nomadic, wandering, homeless, vagrant, beggar, poor, impoverished, destitute, needy, hungry, starving, thirsty, dehydrated, exhausted, tired, weary, fatigued, sleepy, drowsy, lazy, idle, inactive, passive, submissive, meek, humble, modest, simple, plain, ordinary, common, average, mediocre, inferior, subpar, inadequate, insufficient, lacking, missing, absent, gone, lost, disappeared, vanished
```

#### 儒家卡牌负面提示词
```
rude, impolite, disrespectful, irreverent, blasphemous, sacrilegious, profane, vulgar, crude, obscene, offensive, insulting, abusive, aggressive, violent, hostile, antagonistic, confrontational, argumentative, contentious, quarrelsome, combative, belligerent, warlike, martial, military, soldier, warrior, fighter, combatant, gladiator, duelist, assassin, murderer, killer, executioner, torturer, sadist, masochist, psychopath, sociopath, criminal, outlaw, bandit, thief, robber, burglar, pirate, smuggler, trafficker, dealer, merchant, trader, businessman, entrepreneur, capitalist, socialist, communist, anarchist, revolutionary, rebel, insurgent, terrorist
```

#### 道家卡牌负面提示词
```
artificial, synthetic, manufactured, industrial, mechanical, robotic, automated, digital, electronic, computerized, programmed, coded, algorithmic, systematic, organized, structured, ordered, arranged, planned, designed, engineered, constructed, built, made, created, produced, manufactured, fabricated, assembled, put together, complicated, complex, intricate, detailed, elaborate, ornate, decorated, adorned, embellished, enhanced, improved, upgraded, advanced, modern, contemporary, current, present, future, futuristic,科幻, 未来主义
```

#### 墨家卡牌负面提示词
```
simple, plain, basic, elementary, fundamental, essential, necessary, required, needed, wanted, desired, wished, hoped, dreamed, imagined, fantasized,虚幻, 幻想, 梦想, 理想, 乌托邦,  dystopia, dystopian, apocalyptic, post-apocalyptic,末日, 后末日, 灾难, catastrophe, disaster, tragedy, calamity, misfortune, adversity, hardship, difficulty, challenge, obstacle, barrier, impediment, hindrance, obstruction, blockage, restriction, limitation, constraint, confinement, imprisonment, captivity, slavery, servitude, bondage, enslavement, oppression, suppression, repression, subjugation, domination, control, power, authority, government, state, nation, country, kingdom, empire, dynasty, reign, rule, governance, administration, management, leadership, command, control
```

#### 阴阳家卡牌负面提示词
```
scientific, rational, logical, reasonable, sensible, practical, pragmatic, realistic, factual, actual, real, true, truthful, honest, sincere, genuine, authentic, original, natural, organic, biological, living, alive,生命, 生活, 生存, existence, being, entity, thing, object, item, article, product, commodity, goods, merchandise, stock, inventory, supply, resource, asset, property, possession, belonging, ownership, possession, control, power, influence, effect, impact, consequence, result, outcome, output, product, production, productivity, efficiency, effectiveness, performance, achievement, accomplishment, success, victory, triumph, win, gain, profit, benefit, advantage, edge, superiority, supremacy, dominance, predominance, preeminence, supremacy, hegemony, leadership, command, control
```

#### 武器卡牌负面提示词
```
broken, damaged, destroyed, ruined, wrecked, shattered, smashed, crushed, pulverized, demolished, obliterated, annihilated, eradicated, eliminated, removed, taken, stolen, lost, missing, absent, gone, disappeared, vanished, evaporated, dissolved, melted, burned, scorched, charred, ashen,灰烬, 灰, ash, dust, dirt, soil, mud, clay, sand, gravel, stone, rock, boulder, mountain, hill, valley, plain, field, meadow, pasture, grassland, prairie, savanna, desert, wilderness, forest, jungle, rainforest, woods, trees, plants, vegetation, flora, fauna, animals, wildlife, nature, natural, environment, ecosystem, habitat, home, dwelling, residence, house, building, structure, architecture, construction, engineering, design, plan, blueprint, diagram, chart, graph, map, guide, manual, instruction, direction, guidance, advice, suggestion, recommendation, tip, hint, clue, sign, signal, indicator, marker, pointer, arrow, direction, path, road, route, way, course, journey, travel, trip, voyage, expedition, adventure, exploration, discovery, finding, uncovering, revealing, exposing, showing, displaying, exhibiting, presenting, demonstrating, illustrating, explaining, describing, telling, narrating, recounting, relating, reporting, informing, notifying, announcing, declaring, proclaiming, stating, saying, speaking, talking, conversing, discussing, debating, arguing, disputing, contesting, challenging, questioning, doubting, suspecting, distrusting, mistrusting,不相信, 怀疑, 质疑
```

### 3.3 负面提示词使用策略

#### 策略1：基础+专项组合
```
# 兵家卡牌完整负面提示词
blurry, low quality, distorted, ugly, deformed, disfigured, poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, floating limbs, disconnected limbs, mutation, mutated, ugly, disgusting, amputation, bad proportions, gross proportions, text, error, missing fingers, missing arms, missing legs, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, trademark, watermark, title, multiple views, comic, manga, anime, cartoon, graphic, text, painting, crayon, graphite, abstract, glitch, deformed, mutated, ugly, disfigured, modern clothing, modern fashion, contemporary style, futuristic, sci-fi, fantasy armor, European armor, plate armor, chainmail, medieval, renaissance, Victorian, modern weapons, guns, firearms, peaceful, calm, serene, gentle, soft, delicate, fragile, weak, timid, fearful, cowardly, retreating, surrendering, defeated, wounded, injured, bleeding, dying, dead, corpse, skeleton, ghost, spirit, phantom, demon, monster, creature, animal, beast, dragon, phoenix, unicorn, mythical creature, fantasy creature, magical creature, supernatural, magical, mystical, occult, wizard, witch, sorcerer, mage, magic, spell, enchantment, curse, blessing, divine, holy, sacred, religious, spiritual, ritual, ceremony, celebration, festival, party, gathering, crowd, mob, riot, chaos, disorder, confusion, mess, dirty, messy, cluttered
```

#### 策略2：精简高效版（SD3.5推荐）
```
# SD3.5 精简负面提示词（效果最佳）
blurry, low quality, distorted, ugly, deformed, modern, contemporary, futuristic, sci-fi, fantasy, European, medieval, photorealistic, 3D render, CGI, digital art, cartoon, anime, manga, comic
```

#### 策略3：分阶段使用
1. **初代生成**：使用精简版负面提示词
2. **质量筛选**：对模糊/失真的图片使用完整版重新生成
3. **风格优化**：对风格不纯的图片使用专项负面提示词

### 3.4 SD3.5 Large 批量生成脚本（完整版）

```python
# sd35_batch_generate_complete.py
import torch
from diffusers import StableDiffusion3Pipeline
import os
from pathlib import Path
import json

# 1. 加载模型
pipe = StableDiffusion3Pipeline.from_pretrained(
    "stabilityai/stable-diffusion-3.5-large",
    torch_dtype=torch.bfloat16,
    cache_dir="./model_cache"
)

# macOS M系列芯片使用 MPS 加速
if torch.backends.mps.is_available():
    pipe = pipe.to("mps")
elif torch.cuda.is_available():
    pipe = pipe.to("cuda")

# 2. 关键参数（SD3.5 专用）
GENERATION_PARAMS = {
    "guidance_scale": 4.5,     # SD3.5 推荐 4-6，不要超过 6
    "num_inference_steps": 40,  # 28-50 步，更多步数更清晰
    "width": 1024,              # 最低 1024
    "height": 1024,             # 最低 1024
    "max_sequence_length": 512, # T5 编码器，不要截断
}

# 3. 负面提示词库
NEGATIVE_PROMPTS = {
    "basic": "blurry, low quality, distorted, ugly, deformed, disfigured, poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, floating limbs, disconnected limbs, mutation, mutated, ugly, disgusting, amputation, bad proportions, gross proportions, text, error, missing fingers, missing arms, missing legs, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, trademark, watermark, title, multiple views, comic, manga, anime, cartoon, graphic, text, painting, crayon, graphite, abstract, glitch, deformed, mutated, ugly, disfigured",
    
    "historical": "modern clothing, modern fashion, contemporary style, futuristic, sci-fi, fantasy armor, European armor, plate armor, chainmail, medieval, renaissance, Victorian, modern weapons, guns, firearms, electricity, neon lights, LED, digital, computer generated, 3D render, CGI, photorealistic, photography, photograph, realistic, hyperrealistic, modern art, abstract art, pop art, graffiti, street art, western art, European art, Greek, Roman, Egyptian, Japanese, Korean, Indian, Arabic, Islamic, Christian, cross, church, cathedral, mosque, temple, modern building, skyscraper, glass building, concrete, steel, plastic, synthetic materials, modern technology, smartphone, computer, screen, monitor, digital display, modern vehicle, car, airplane, train, modern furniture, modern architecture",
    
    "art_style": "oil painting, acrylic painting, watercolor, gouache, pastel, charcoal, pencil sketch, digital painting, vector art, pixel art, low poly, isometric, flat design, minimalism, modernism, impressionism, expressionism, surrealism, cubism, abstract expressionism, pop art, art deco, art nouveau, baroque, rococo, gothic, romanticism, realism, hyperrealism, photorealistic, photography, photograph, 3D render, CGI, computer generated, digital art, game art, concept art, illustration, cartoon, anime, manga, comic book, graphic novel, children's book, fantasy art, sci-fi art, steampunk, cyberpunk, dieselpunk, atompunk, biopunk, solarpunk, retrofuturism",
    
    "simplified": "blurry, low quality, distorted, ugly, deformed, modern, contemporary, futuristic, sci-fi, fantasy, European, medieval, photorealistic, 3D render, CGI, digital art, cartoon, anime, manga, comic",
}

# 4. 按卡牌类型选择负面提示词
def get_negative_prompt(card_type, strategy="simplified"):
    """根据卡牌类型和策略获取负面提示词"""
    base = NEGATIVE_PROMPTS.get(strategy, NEGATIVE_PROMPTS["simplified"])
    
    # 按类型添加专项负面词
    type_specific = {
        "bingjia": "peaceful, calm, serene, gentle, soft, delicate, fragile, weak, timid, fearful, cowardly, retreating, surrendering, defeated",
        "fajia": "lawless, anarchic, chaotic, disorderly, unruly, rebellious, defiant, disobedient",
        "rujia": "rude, impolite, disrespectful, irreverent, blasphemous, sacrilegious, profane, vulgar, crude",
        "daojia": "artificial, synthetic, manufactured, industrial, mechanical, robotic, automated, digital",
        "mojia": "simple, plain, basic, elementary, fundamental, essential",
        "yinyangjia": "scientific, rational, logical, reasonable, sensible, practical, pragmatic, realistic",
        "weapon": "broken, damaged, destroyed, ruined, wrecked, shattered, smashed, crushed",
    }
    
    if card_type in type_specific:
        return f"{base}, {type_specific[card_type]}"
    return base

# 5. 读取提示词并生成
def batch_generate(prompts_list, output_dir, strategy="simplified", seed=42):
    """批量生成函数"""
    os.makedirs(output_dir, exist_ok=True)
    
    generator = torch.Generator(device="mps" if torch.backends.mps.is_available() else "cpu")
    
    results = []
    
    for i, (card_id, prompt, card_type) in enumerate(prompts_list):
        print(f"[{i+1}/{len(prompts_list)}] 生成: {card_id} ({card_type})")
        
        # 获取负面提示词
        negative_prompt = get_negative_prompt(card_type, strategy)
        
        generator.manual_seed(seed + i)
        
        try:
            image = pipe(
                prompt=prompt,
                negative_prompt=negative_prompt,
                generator=generator,
                **GENERATION_PARAMS
            ).images[0]
            
            filepath = os.path.join(output_dir, f"{card_id}.png")
            image.save(filepath)
            
            # 记录结果
            results.append({
                "card_id": card_id,
                "card_type": card_type,
                "filepath": filepath,
                "prompt": prompt[:100] + "..." if len(prompt) > 100 else prompt,
                "negative_prompt": negative_prompt[:100] + "..." if len(negative_prompt) > 100 else negative_prompt,
                "seed": seed + i,
                "status": "success"
            })
            
            print(f"  ✓ 保存到: {filepath}")
            
        except Exception as e:
            print(f"  ✗ 生成失败: {e}")
            results.append({
                "card_id": card_id,
                "card_type": card_type,
                "error": str(e),
                "status": "failed"
            })
            continue
    
    # 保存生成日志
    log_file = os.path.join(output_dir, "generation_log.json")
    with open(log_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\n生成完成！日志保存到: {log_file}")
    return results

# 6. 示例数据格式
def load_prompts_from_file(filepath):
    """从文件加载提示词"""
    prompts = []
    
    # 示例格式：card_id|card_type|prompt
    # B001|bingjia|A heavily armored Wei soldier...
    
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and '|' in line:
                parts = line.split('|', 2)
                if len(parts) == 3:
                    card_id, card_type, prompt = parts
                    prompts.append((card_id.strip(), prompt.strip(), card_type.strip()))
    
    return prompts

# 7. 主程序
if __name__ == "__main__":
    # 加载提示词
    prompts_file = "warring_states_prompts.txt"
    
    if os.path.exists(prompts_file):
        prompts = load_prompts_from_file(prompts_file)
    else:
        # 示例数据（前5张兵家卡牌）
        prompts = [
            ("B001", "bingjia", "A heavily armored Wei soldier from ancient China's Warring States period standing tall in a military encampment, wearing layered bronze scale armor and gripping a long halberd with both hands, his expression fierce and unyielding against a backdrop of military tents and banners. Rendered in traditional Chinese ink wash painting style with visible bamboo scroll texture overlays, bronze patina effects, and cloud thunder decorative patterns around the edges. Muted earth brown and bronze tones. High resolution, sharp focus on the armor details."),
            ("B002", "bingjia", "An elite Qin dynasty light infantry soldier from the Warring States period charging forward with a Qin-style bronze sword raised high, wearing leather armor and a distinctive Qin helmet, against a formation of black Qin banners and soldiers in the background. Traditional Chinese ink wash painting style with bamboo texture and kui dragon decorative patterns. Dark red and bronze color scheme. Sharp focus on the sword and determined face."),
            ("B003", "bingjia", "A Zhao kingdom cavalry scout from ancient China's Warring States period mounted on a brown warhorse galloping across the northern grasslands, holding a long cavalry spear, with flowing horse mane and dust trailing behind. Traditional Chinese ink wash painting with pan chi dragon decorative motifs and bamboo scroll textures. Brown and gold tones. Clear details on the horse and rider."),
            ("B004", "bingjia", "A Qi kingdom elite archer from the Warring States period drawing a powerful composite bow, aiming at a distant target, standing on the walls of a Qi city with watchtowers visible behind. Chinese ink wash painting style with bamboo texture overlays. Bronze and navy blue tones. Sharp focus on the bowstring tension and archer's concentrated expression."),
            ("B005", "bingjia", "A Chu kingdom heavy infantry soldier from the Warring States period wielding a long dagger-axe weapon in a southern jungle clearing, wearing distinctive southern armor with phoenix feather decorations, surrounded by lush vegetation and mist. Traditional Chinese ink wash painting with phoenix motifs and bamboo scroll texture. Purple and green tones. Details clearly visible."),
        ]
    
    # 输出目录
    output_dir = "./output/cards_sd35"
    
    # 生成策略：simplified（推荐）, basic, full
    strategy = "simplified"
    
    # 批量生成
    print(f"开始批量生成，策略: {strategy}")
    print(f"生成数量: {len(prompts)}")
    print(f"输出目录: {output_dir}")
    print("-" * 50)
    
    results = batch_generate(prompts, output_dir, strategy=strategy, seed=42)
    
    # 统计结果
    success = sum(1 for r in results if r.get("status") == "success")
    failed = sum(1 for r in results if r.get("status") == "failed")
    
    print(f"\n{'='*50}")
    print(f"生成统计:")
    print(f"  成功: {success} 张")
    print(f"  失败: {failed} 张")
    print(f"  总计: {len(prompts)} 张")
    print(f"{'='*50}")
```

## 四、模糊问题解决方案

### 4.1 立即检查清单

| 检查项 | 你的设置（推测） | 正确设置 |
|:---|:---|:---|
| 分辨率 | 可能 512×512 | **1024×1024 起** |
| CFG Scale | 可能 7+ | **4.5**（不超过 6） |
| 步数 | 可能 20-28 | **40-50** |
| max_sequence_length | 可能 77（默认截断） | **512**（不截断） |
| 提示词语言 | 可能中文或标签 | **纯英文自然句** |
| Negative prompt | 可能过长 | **极简一句** |
| 数据类型 | FP16 | **BF16**（更稳定） |

### 4.2 如果仍然模糊

```python
# 追加高清处理
params = {
    "guidance_scale": 3.5,      # 再降低
    "num_inference_steps": 50,  # 增加到 50
    "width": 1024,
    "height": 1024,
    "max_sequence_length": 512,
}
```

### 4.3 后处理锐化

```python
from PIL import Image, ImageFilter, ImageEnhance

def sharpen_card(image_path, output_path):
    img = Image.open(image_path)
    img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=150, threshold=3))
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.15)
    img.save(output_path)
```

## 五、总结：SD3.5 Large 核心要点

1. **只用英文自然句**，不用标签堆砌，不用中文
2. **分辨率 ≥ 1024×1024**
3. **CFG scale = 4.5**（4-6 之间）
4. **步数 ≥ 40**
5. **max_sequence_length = 512**
6. **数据类型用 BF16**
7. **负向提示词极简**（甚至可以不传）
8. **提示词要详细描述场景**，不是关键词列表
