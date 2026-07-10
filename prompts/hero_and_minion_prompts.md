# 战国卡牌游戏 - 完整AI素材提示词库 v2.0

> 完全匹配游戏实现数据 — 7职业 × 3英雄 = 21英雄, 7×20 + 41中立 ≈ 181条卡牌数据
> 基于 `zg-card-game` skill 的实际 heroes_data.dart 和 cards/*.dart 生成
> 风格锚定: 传统中国水墨画风 + 数字卡牌艺术 (类似 LoR/Shadowverse 品质)
> 输出规格: 英雄卡/随从卡/法术卡/武器卡 3:4, 场景 16:9, UI/特效 1:1

---

## 风格锚定（所有提示词通用）

```
ancient Chinese Warring States period aesthetic,
traditional Chinese painterly brushwork meets digital art,
NOT photorealistic, NOT 3D render, NOT photography,
scholarly yet martial atmosphere,
period-accurate Warring States architecture and clothing,
hand-ink texture overlay for authenticity,
muted earth tones with metallic accents,
cinematic dramatic lighting, rim light on edges,
professional card game art quality
(Legends of Runeterra, Shadowverse, Hearthstone art level)

Negative: NO photorealistic, NO photographic, NO 3D rendering,
NO realistic human face, NO live-action drama style,
NO real person, NO photography lighting, NO CGI render,
NO western oil painting style, NO text, NO watermarks, NO signatures,
NO Chinese characters, NO pseudo-text on scrolls or robes,
NO extra fingers, NO deformed hands (six fingers, missing, claw),
NO asymmetric armor pieces, NO cluttered background,
NO anime style, NO cartoon style, NO modern anime shading,
NO oversaturated colors, NO low quality, NO blurry,
NO modern elements, NO plastic/vinyl textures
```

---

## 职业调色板

| 职业 | 主色 Hex | 辅色 Hex | 强调色 Hex |
|------|----------|----------|-----------|
| 兵家 | #1A3A5C | #FFFFFF | #8B6914 |
| 法家 | #1A1A2E | #D4AF37 | #8B0000 |
| 儒家 | #2D5A27 | #F5F5DC | #8B4513 |
| 道家 | #2F4F4F | #C0C0C0 | #696969 |
| 墨家 | #2C2C2C | #C41E3A | #B87333 |
| 阴阳家 | #4B0082 | #4169E1 | 五行彩 |
| 纵横家 | 杂色混搭 | 各诸侯色 | #36454F |
| 中立 | #696969 | #C0C0C0 | #D4AF37 |

---

# 一、英雄卡提示词 (21英雄, 匹配 heroes_data.dart)

## 兵家 (Bingjia) — 3英雄

### H_B001 孙膑 — 「围魏救赵」防御型 齐
```
A dignified portrait of Sun Bin (孙膑), ancient Chinese military
strategist from Warring States Qi kingdom, wearing elegant
scholar-official robes in Qi blue #1A3A5C and white #FFFFFF,
holding a bamboo scroll of military tactics, subtle wise smile
with piercing intelligent eyes, ink wash painting texture overlay,
jade token on belt, upright dignified pose radiating strategic
brilliance, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body visible, clear heroic silhouette,
military scholar aesthetic, dramatic backlighting with subtle
rim light on robe edges, minimal dark gradient backdrop
(background < 10%), highly detailed, 4K, professional
card game quality, no text on scroll, --ar 3:4 --zoom 2
```

### H_B002 吴起 — 「奖励耕战」增益型 卫
```
A fierce reformer-general Wu Qi (吴起) from Warring States
Wei kingdom in powerful reformer pose, wearing half military
armor half scholar robe (symbolizing both war and governance),
holding dual symbols: halberd in one hand, plow tool in other
(rewarding farming and warfare), determined visionary expression
with sharp eyes, Wei kingdom muted colors with Qi blue #1A3A5C
and bronze #8B6914 accents, traditional Chinese art style with
painterly brushwork, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
reformer-warrior dual aesthetic, dramatic side-lighting,
warm agricultural golden light mixed with cold military blue,
highly detailed, 4K, professional card game quality,
no text on tools, --ar 3:4 --zoom 2
```

### H_B003 廉颇 — 「负荆请罪」防御型 赵
```
An elderly but powerfully-built general Lian Po (廉颇) from
Warring States Zhao kingdom, wearing heavy Zhao red #8B0000
and white #FFFFFF ceremonial armor, carrying thorn branches
on his back (symbol of humility and apology), kneeling or
bowing slightly in gesture of reconciliation, weathered
scarred face with white beard showing decades of battle
experience, dignified humble expression, traditional Chinese
art style with dramatic brushwork, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered
portrait, upper body, imposing defensive silhouette softened
by humble gesture, dramatic frontal key light, dark atmospheric
backdrop, highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 2
```

## 法家 (Fajia) — 3英雄

### H_F001 商鞅 — 「变法革新」控制型 秦
```
A stern transformative lawmaker Shang Yang (商鞅) in official
Qin dynasty Hanfu, holding legal reform bamboo strips with
abstract legal symbols (no text), piercing authoritative gaze,
Qin kingdom black #1A1A2E and gold #D4AF37 colors, confident
standing pose with one hand raised as if proclaiming new laws,
revolutionary determined expression, scrolls of old laws
breaking apart in background (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
legal reform authority aesthetic, dramatic studio lighting
with golden key light, dark gradient background,
highly detailed, 4K, professional card game quality,
no Chinese characters on documents, --ar 3:4 --zoom 2
```

### H_F002 韩非 — 「法家三术」控制型 韩
```
A brilliant melancholic scholar Han Fei (韩非) with stutter
suggested by contemplative hand-to-chin gesture, wearing Han
kingdom green #2D5A27 scholar robes with gold #D4AF37 trim,
holding three abstract symbols representing 势术法 (power,
technique, law — abstract geometric, no text), deep intellectual
expression with furrowed brow, ink wash painting texture,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait,
upper body, philosophical legalist aesthetic, soft dramatic
lighting from above, misty scholarly atmosphere backdrop,
highly detailed, 4K, professional card game quality,
no text on symbols, --ar 3:4 --zoom 2
```

### H_F003 申不害 — 「循名责实」控制型 韩
```
A precise meticulous official Shen Buhai (申不害) in elegant
Han court Hanfu, holding governance register tablets with
abstract positional symbols (no text), calculating administrative
expression with micro-managing intensity, Han kingdom green
#2D5A27 and gold #D4AF37 colors, formal bureaucratic pose
with upright back, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body, administrative precision aesthetic,
dramatic side-lighting emphasizing detail-oriented expression,
dark gradient backdrop, highly detailed, 4K, professional
card game quality, no text on tablets, --ar 3:4 --zoom 2
```

## 儒家 (Rujia) — 3英雄

### H_R001 孔子 — 「有教无类」抽牌型 鲁
```
A wise elderly teacher Confucius (孔子) with kind warm expression,
wearing traditional Confucian robes in Lu green #2D5A27 and
white #F5F5DC, surrounded by diverse students of different
ages and backgrounds (silhouettes in background, subtle),
holding teaching pointer or bamboo scroll, gentle wise smile
with twinkling eyes, subtle golden light rays suggesting
enlightenment and education for all, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
serene scholarly atmosphere, soft warm lighting from above,
peaceful misty backdrop with subtle student silhouettes,
highly detailed, 4K, professional card game quality
(like Shadowverse legendary art), no text on scroll,
--ar 3:4 --zoom 2
```

### H_R002 孟子 — 「民贵君轻」治疗型 邹
```
A passionate philosopher Mengzi (孟子) with expressive
compassionate face, Zou kingdom green #2D5A27 and white
#F5F5DC colors, dynamic teaching pose with arms spread wide
as if addressing a crowd, intense caring expression, common
people silhouettes standing behind him (minimal, representing
"people first"), traditional Chinese art style with painterly
brushwork, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
passionate people-first aesthetic, dramatic warm golden
lighting from behind, golden atmospheric glow suggesting
moral righteousness, highly detailed, 4K, professional
card game quality, no text, --ar 3:4 --zoom 2
```

### H_R003 荀子 — 「隆礼重法」增益型 赵
```
A dignified philosopher Xunzi (荀子) in refined scholarly robes,
Zhao kingdom colors with book-scroll brown #8B4513 accents,
holding both ritual vessel (representing 礼/rites) and law
tablet (representing 法/law), composed authoritative expression
with slight skepticism, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
game art, centered portrait, upper body, scholarly pragmatist
aesthetic, dramatic studio lighting with warm brown tones,
dark gradient backdrop, highly detailed, 4K, professional
card game quality, no text on items, --ar 3:4 --zoom 2
```

## 道家 (Daojia) — 3英雄

### H_D001 老子 — 「道法自然」增益型 楚
```
An elderly Taoist philosopher Laozi (老子) with long flowing
white beard and hair, wearing simple undyed natural Taoist robe,
riding or standing beside an azure water buffalo (青牛),
holding a fly-whisk (拂尘), serene transcendent expression,
surrounded by subtle mystical purple mist (紫气东来) and
floating abstract Dao symbols (yin-yang, trigrams — no text),
ink wash painting meets digital traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body, Daoist sage aesthetic,
soft ethereal lighting from below, misty atmosphere,
natural earth tones #2F4F4F and silver #C0C0C0 colors,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 2
```

### H_D002 庄子 — 「逍遥游」防御型 宋
```
A free-spirited Zhuangzi (庄子) with carefree dreamy
expression, loose flowing Taoist robes in silver white
#C0C0C0 and dark grey #36454F, a butterfly companion
floating near his shoulder (reference to butterfly dream),
one hand reaching toward butterfly, whimsical floating
pose as if carried by wind, dreamlike ethereal atmosphere,
water splashing and fish swimming motifs (symbolizing
freedom), traditional Chinese art style with painterly
elements, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
free-spirited philosophical aesthetic, soft pastel
lighting, misty mystical backdrop, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 2
```

### H_D003 列子 — 「御风而行」增益型 郑
```
A serene philosopher Liezi (列子) in flowing simple Taoist
robe, Zheng kingdom muted colors #2F4F4F, standing in
mid-air pose with robes and hair dramatically blown by wind
(suggesting riding the wind/御风而行), bare feet slightly
off ground, peaceful transcendent expression, cloud wisps
passing beneath, wind ribbons flowing dramatically around
body, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body, ethereal wind-rider aesthetic,
dramatic wind effects on clothing, soft atmospheric lighting,
misty mountain sky backdrop, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 2
```

## 墨家 (Mojia) — 3英雄

### H_M001 墨子 — 「兼爱非攻」召唤型 宋
```
A principled philosopher Mozi (墨子) in practical coarse
black #2C2C2C robes with workshop dust and wear, holding
mechanical blueprint scrolls (abstract symbols, no text)
AND a carpenter's square/compass (规矩), small mechanical
construct (1/1 机关兽) at his feet, determined resolute
expression, Song kingdom muted colors with red #C41E3A accents,
simple dignified pose radiating universal love, mechanical
gears and workshop tools in background (dark silhouettes only,
<10%), ancient Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, craftsman-
philosopher aesthetic, dramatic rim lighting on robe edges,
dark workshop atmosphere, highly detailed, 4K, professional
card game quality, no text on blueprints, --ar 3:4 --zoom 2
```

### H_M002 公输班(鲁班) — 「机关术」增益型 鲁
```
A master craftsman Gongshu Ban 公输班 (Lu Ban 鲁班) in
practical work apron over Hanfu with rolled-up sleeves,
surrounded by floating mechanical contraptions — saws,
planes, drills, gears (ancient Chinese inventions),
holding artisan's measuring tool, proud innovative
craftsman expression with focused eyes, Lu kingdom copper
#B87333 and dark #2C2C2C colors, workshop setting with
wood shavings and mechanical parts (minimal background),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered
portrait, upper body, master craftsman aesthetic, dramatic
workshop lighting with metallic copper highlights, dark
atmospheric backdrop, highly detailed, 4K, professional
card game quality, no text on tools, --ar 3:4 --zoom 2
```

### H_M003 禽滑厘 — 「守城之术」防御型 卫
```
A steadfast defender Qin Huali (禽滑厘), Mozi's chief
disciple, in practical coarse robes with defensive gear,
holding large shield with abstract defensive symbols
(no text), protective defensive stance, experienced
fortress-defender expression with vigilant eyes,
Wei kingdom muted colors with red #C41E3A accents,
fortress wall battlements in background (silhouette, <10%),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered
portrait, upper body, fortress defender aesthetic,
dramatic defensive lighting, dark atmospheric backdrop,
highly detailed, 4K, professional card game quality,
no text on shield, --ar 3:4 --zoom 2
```

## 阴阳家 (Yinyangjia) — 3英雄

### H_Y001 邹衍 — 「五行相生」随机型 齐
```
A mystical philosopher Zou Yan (邹衍) in flowing cosmic
robe richly decorated with Five Elements abstract patterns
(wood/fire/earth/metal/water as colored geometric bands),
holding a celestial orb that glows with shifting colors,
mysterious piercing eyes staring into cosmic distance,
Qi kingdom blue #1A3A5C with cosmic purple #4B0082 accents,
cosmic starfield background (subtle, <10% of frame),
traditional Chinese mystical painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
cosmic mystery aesthetic, dramatic celestial backlight
with purple and gold particles, dark gradient backdrop,
highly detailed, 4K, professional card game quality,
no text, --ar 3:4 --zoom 2
```

### H_Y002 甘德 — 「星象观测」随机型 齐
```
A scholarly stargazer Gan De (甘德) in flowing astronomical
robe decorated with subtle constellation patterns, observing
a celestial sphere/astrolabe covered in star patterns
(abstract dots and lines, no text), Qi kingdom blue #1A3A5C
and celestial purple #4B0082 colors, astronomical instruments
and star charts in background (subtle), holding bronze
sighting tube, studious fascinated expression gazing upward,
traditional Chinese astronomical painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body, cosmic scholar aesthetic,
dramatic starlight illumination from above, dark starry
backdrop with subtle constellation patterns, highly detailed,
4K, professional card game quality, no text on instruments,
--ar 3:4 --zoom 2
```

### H_Y003 石申 — 「天象占卜」随机型 魏
```
A scholarly astronomer Shi Shen (石申) in refined cosmic
Hanfu, holding celestial charts with abstract star
patterns (no text), one hand tracing divination lines,
Wei kingdom colors with celestial blue #4169E1 and
purple #4B0082 accents, contemplative diviner expression,
subtle fortune-telling atmosphere with mystical cards
or bones on table, traditional Chinese astronomical
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
astronomer-diviner aesthetic, dramatic celestial lighting,
dark night sky backdrop with shooting star, highly detailed,
4K, professional card game quality, no text on charts,
--ar 3:4 --zoom 2
```

## 纵横家 (Zonghengjia) — 3英雄

### H_Z001 苏秦 — 「合纵抗秦」减益型 周
```
A charismatic diplomat Su Qin (苏秦) wearing robes subtly
representing a six-nation alliance (mosaic-like patches
of blue/green/purple/red from different kingdoms), holding
a six-sided alliance seal with abstract kingdom symbols
(no text), confident powerful pose with dramatic cape
flowing behind as if wind from all nations converges,
piercing determined eyes, Zhou kingdom central authority
aesthetic, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
centered portrait, upper body, diplomatic alliance power
aesthetic, dramatic multi-directional lighting, dark
atmospheric backdrop with subtle map-like patterns,
highly detailed, 4K, professional card game quality,
no text on seal, --ar 3:4 --zoom 2
```

### H_Z002 张仪 — 「连横破纵」抽牌型 魏
```
A cunning calculating diplomat Zhang Yi (张仪) with sly
knowing smile and sharp intelligent eyes, wearing Wei
kingdom blue #1A3A5C and grey #36454F colors, holding
a map scroll showing east-west horizontal alliance routes
(abstract lines, no text), negotiation pose with one hand
extended as if offering a deal, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, centered portrait, upper body,
strategic cunning aesthetic, dramatic side-lighting
emphasizing calculating expression, dark atmospheric
backdrop, highly detailed, 4K, professional card game quality,
no text on maps, --ar 3:4 --zoom 2
```

### H_Z003 鬼谷子 — 「纵横捭阖」随机型 卫
```
An ancient mystical sage Guiguzi (鬼谷子) with powerful
supernatural aura, wearing dark mystical robes with
swirling abstract patterns that seem alive, surrounded
by swirling ethereal mist and ghostly energy wisps in
multiple colors (representing multiple abilities),
holding ancient bamboo scroll with abstract symbols
(no text) that emit faint light, piercing penetrating
mystical eyes that seem to see through everything,
cave dwelling setting with mystical atmosphere (minimal
dark background), crackling energy around fingertips,
traditional Chinese mystical painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
epic supernatural aesthetic, dramatic bottom-up mystical
lighting in purple and gold, dark atmospheric backdrop
with particle effects, highly detailed, 4K, professional
card game quality (Shadowverse legendary art level),
--ar 3:4 --zoom 2
```

---

# 二、随从卡提示词（按职业分类，匹配实际卡名）

## 兵家 (Bingjia) 随从

### B001 魏武卒 (3/3/4, 战吼, 普通) — 魏之武卒，以度取之
```
Heavy infantry Wei Wuzu (魏武卒) in full three-layer bronze
armor (三属之甲) with heavy crossbow (十二石之弩, ancient
Chinese design), elite soldier stance, imposing powerful
physique, Qi blue #1A3A5C armor with bronze #8B6914 plate
segments, battlefield dust atmosphere (minimal <15%),
fierce disciplined expression, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in lower-center,
full body visible, dramatic key lighting on armor contours,
dark gradient backdrop, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### B002 秦锐士 (2/2/3, 冲锋, 普通) — 秦之锐士，天下无双
```
Elite Qin shock trooper Qin Ruishi (秦锐士) in distinctive
Qin black #1A1A2E and gold #D4AF37 armor, charging forward
with halberd, dynamic running pose with motion blur,
fierce charging expression, unmatched warrior aura,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, character in lower-center, full body visible,
dramatic motion lighting, dark gradient backdrop with
dust trail, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

### B003 赵边骑 (4/3/5, 风怒, 稀有) — 赵边骑天下闻名
```
Zhao border cavalry Zhao Bianqi (赵边骑) on galloping
warhorse, Zhao red #8B0000 and white #FFFFFF cavalry
armor, mounted archer pose with bow drawn, horse in
full gallop, wind-swept mane and rider's cape, frontier
steppe background (minimal), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character on horse in
lower-center, full body visible, dramatic wind lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### B004 燕死士 (1/2/1, 亡语, 普通) — 燕赵多慷慨悲歌之士
```
Yan death-sworn warrior Yan Sishi (燕死士) in simple dark
clothing with suicide mission headband, holding dagger
in reverse grip, desperate determined expression, dramatic
tragic heroic pose, Yan kingdom colors, dark atmospheric
backdrop with dramatic spotlight, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, dramatic tragic lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### B005 楚锐卒 (5/4/6, 嘲讽, 普通) — 楚虽三户，亡秦必楚
```
Chu elite soldier Chu Ruizu (楚锐卒) in distinctive Chu
southern armor style, holding large tower shield, defensive
taunt stance, imposing presence, Chu kingdom bronze #8B6914
and red accent colors, "three households" symbolism
(three small house motifs on shield — abstract, no text),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, character in lower-center, full body visible,
dramatic defensive lighting, dark gradient backdrop,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### B006 齐技击士 (3/2/4, 战吼, 稀有) — 齐技击，天下莫能当
```
Qi martial arts master Qi Jijishi (齐技击士) in flexible
light armor, dynamic martial arts pose mid-technique,
Qi blue #1A3A5C and white #FFFFFF colors, flowing movement
suggested by robe motion, confident martial artist expression,
traditional Chinese wuxia painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, character in lower-center, full body
visible, dramatic action lighting, dark gradient backdrop,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### B007 韩戟兵 (2/1/4, 嘲讽, 普通) — 韩之戟兵，守如磐石
```
Han halberd defender Han Jibing (韩戟兵) in solid defensive
armor, holding long halberd in defensive guard position,
rock-solid unmovable stance, Han kingdom colors, fortress
stone wall background (subtle, <10%), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, dramatic defensive lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### B008 孙武 (9/7/7, 战吼, 传说) — 孙子曰：兵者，国之大事
```
The legendary Sun Wu (孙武/Sun Tzu) in elegant general's
robe with subtle armor, holding The Art of War treatise
(abstract symbols, no text), commanding sweeping gesture
as if directing armies, devastating strategic power aura,
Qi blue #1A3A5C and gold #D4AF37 colors, battlefield
silhouettes being destroyed in background (subtle),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, epic legendary card quality,
dramatic commanding lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### B009 吴起 (6/5/6, 战吼, 史诗) — 吴起为将，与士卒同衣食
```
General Wu Qi (吴起) as a 随从卡, sharing food with common
soldiers scene (与士卒同衣食), half-armored general sitting
among soldiers, breaking bread, inspirational leadership
expression, Wei kingdom colors, campfire warm lighting,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible with soldiers around, dramatic
fireside lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### B010 孙膑 (5/3/5, 战吼, 史诗) — 孙膑围魏救赵
```
Strategist Sun Bin (孙膑) as a 随从卡, holding battle map
showing the 围魏救赵 strategy (encircling Wei to rescue Zhao),
Wei city under siege and Zhao city being saved as abstract
symbols, Qi blue #1A3A5C colors, intellectual strategic
expression, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic strategic
lighting, highly detailed, 4K, professional card game quality,
no text on maps, --ar 3:4 --zoom 1.5
```

### B011 廉颇 (7/6/8, 嘲讽+战吼, 史诗) — 廉颇老矣，尚能饭否
```
Elderly general Lian Po (廉颇) as a 随从卡, eating massive
bowl of rice to prove his vigor (尚能饭否), wearing heavy
Zhao armor, imposing old warrior physique, white beard,
red #8B0000 Zhao colors, proving-himself expression,
traditional Chinese art style with dramatic brushwork,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic warrior lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### B012 李牧 (8/7/7, 战吼, 传说) — 李牧守边匈奴
```
Legendary border general Li Mu (李牧) on the northern
frontier, Zhao kingdom colors, holding command banner
(abstract, no text), Great Wall watchtower in background
(subtle, <10%), disciplined waiting stance (守边 ten years),
imposing patient power, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
epic legendary card quality, dramatic frontier lighting
with cold blue tones, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

## 法家 (Fajia) 随从

### F001 执法吏 (2/2/2, 战吼, 普通) — 法者，天下之公器也
```
Law enforcement officer Zhifa Li (执法吏) in Qin black
#1A1A2E official uniform with gold #D4AF37 trim, holding
law tablet with abstract legal symbols (no text), enforcing
authoritative pose, stern impartial expression, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
character in lower-center, full body visible, dramatic
authoritative lighting, dark gradient backdrop, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### F002 刑徒 (1/1/3, 亡语, 普通) — 法不阿贵，刑过不避大臣
```
Prisoner laborer Xingtu (刑徒) in ragged prison clothing
with punishment marks, carrying heavy wooden cangue,
desperate but defiant expression, Qin black #1A1A2E and
red #8B0000 colors, dark prison atmosphere, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
character in lower-center, full body visible, dramatic
harsh lighting, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

### F003 狱卒 (3/2/4, 嘲讽, 普通) — 狱卒守囚，公正无私
```
Prison guard Yuzu (狱卒) in dark official uniform, holding
heavy keys and cudgel, blocking stance in front of prison
gate, impartial stern expression, Qin black #1A1A2E and
gold #D4AF37 colors, prison gate background (subtle, <10%),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, character in lower-center, full body visible,
dramatic prison lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### F004 律令官 (4/3/5, 战吼, 稀有) — 律令官，掌法令
```
Senior law official Lüling Guan (律令官) in formal court
Hanfu with official hat, holding scroll of legal codes
(abstract symbols, no text), proclaiming pose reading
law aloud, authoritative precise expression, Qin black
#1A1A2E and gold #D4AF37, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic court lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### F005 司寇 (5/4/4, 战吼, 稀有) — 司寇掌刑，惩恶扬善
```
Minister of Justice Sikou (司寇) in imposing judicial robes,
holding executioner's symbolic axe and law scroll, righteous
judge expression, Qin black #1A1A2E with red #8B0000 accents,
court of law background (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic judicial lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### F006 大理 (6/5/6, 战吼, 史诗) — 大理寺卿，掌刑狱
```
Supreme Judge Dali (大理) in the highest judicial robes,
gold #D4AF37 trim on black #1A1A2E, holding supreme court
seal, commanding authoritative presence, stern wise expression,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, epic card quality, dramatic
golden key lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### F007 法家弟子 (1/1/1, 亡语, 普通) — 法家弟子，精研律令
```
Young legalist disciple Fajia Dizi (法家弟子) in student
robes, holding law study materials, eager studious expression,
Qin black #1A1A2E simple colors, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, soft scholarly lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### F008 商鞅 (7/6/6, 战吼, 传说) — 商鞅变法，秦以富强
```
Shang Yang (商鞅) as legendary minion card in imposing
reform pose, standing on elevated platform proclaiming
new laws, scrolls and old law tablets breaking at his
feet (abolishing old systems), Qin black #1A1A2E and
gold #D4AF37, revolutionary transformative aura, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
full body visible, epic legendary card quality, dramatic
revolutionary lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### F009 韩非 (5/4/5, 战吼, 史诗) — 韩非子，法术之祖
```
Han Fei (韩非) as epic minion card, writing legalist
philosophy on bamboo strips, profound intellectual expression,
Han kingdom green #2D5A27 and gold #D4AF37 scholar colors,
study room with scrolls (minimal background), traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
full body visible, dramatic scholarly lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### F010 李悝 (4/3/4, 战吼, 稀有) — 李悝著《法经》
```
Legalist pioneer Li Kui (李悝) holding the first written
legal code 法经 (abstract symbols, no text on cover),
innovative reformer expression, Wei kingdom colors,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, dramatic pioneer lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### F011 申不害 (6/5/5, 战吼, 史诗) — 申不害言术，御下有方
```
Shen Buhai (申不害) as epic minion card in administrative
court setting, holding personnel evaluation tablets,
management expertise expression, subtle hand gesture of
direction (御下有方), Han kingdom green #2D5A27 and gold
#D4AF37, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic administrative
lighting, highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### F012 吴起变法 (8/7/7, 战吼, 传说) — 吴起在楚变法
```
Wu Qi (吴起) in his Chu reform phase as legendary minion,
tearing down aristocratic emblems (废除世卿世禄), old nobility
symbols crumbling, revolutionary reform energy, Chu kingdom
colors, dramatic transformation scene, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, epic legendary card quality, dramatic reform
lighting with breaking symbols, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

## 儒家 (Rujia) 随从

### R001 儒生 (2/1/3, 战吼, 普通) — 手持论语，温文尔雅
```
Confucian scholar Ru Sheng (儒生) in simple student robes,
holding bamboo Analects book (abstract, no text), gentle
cultured expression, Lu green #2D5A27 and white #F5F5DC,
scholarly respectful pose, traditional Chinese painting
style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, soft warm scholarly lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R002 礼官 (3/2/4, 嘲讽, 普通) — 手持玉圭，举止端庄
```
Ritual official Li Guan (礼官) in formal ceremonial robes,
holding jade tablet 玉圭, dignified poised stance, proper
ritual expression, Lu green #2D5A27 and jade green accents,
ceremonial hall background (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, formal ceremonial lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R003 乐师 (2/1/2, 战吼, 普通) — 弹奏古琴，音律和谐
```
Court musician Yue Shi (乐师) in elegant robes, playing
ancient guqin (古琴), musical notes as abstract glowing
symbols floating (no text), harmonious serene expression,
Lu green #2D5A27 with warm wood tones, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, soft musical lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R004 典狱官 (4/3/5, 战吼, 稀有) — 典狱官仁慈执法，教化囚犯
```
Benevolent prison warden Dian Yu Guan (典狱官) in official
robes, teaching prisoners rather than punishing, holding
scroll not whip, kind but firm expression, Lu green #2D5A27
colors, prison background transformed by education (subtle),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, warm reform lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### R005 君子 (5/4/5, 圣盾, 稀有) — 佩玉鸣环，德行高尚
```
Confucian gentleman Junzi (君子) in finest scholarly robes,
jade pendants and rings visible, noble upright bearing,
virtuous dignified expression, Lu green #2D5A27 with gold
#D4AF37 accents, divine shield glow effect around body
(圣盾), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, divine golden lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R006 贤人 (6/5/6, 战吼, 史诗) — 贤德之人，智慧光芒
```
Virtuous sage Xian Ren (贤人) radiating wisdom light rays,
scholar of highest virtue, holding classic texts, enlightened
expression, Lu green #2D5A27 with golden wisdom glow,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, epic card quality, dramatic
wisdom lighting from within, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### R007 夫子 (3/2/3, 亡语, 普通) — 手持戒尺，谆谆教导
```
Elder teacher Fuzi (夫子) in simple teaching robes, holding
teaching rod (戒尺), patient instructing pose, warm wise
expression, Lu green #2D5A27 colors, classroom setting with
student silhouettes (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in lower-center,
full body visible, warm teaching lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### R008 孔子 (10/8/8, 战吼, 传说) — 孔子周游列国
```
The legendary Confucius (孔子) in full epic composition,
traveling between kingdoms with disciples behind, radiating
benevolent golden light, scrolls and teaching tools, ultimate
sage presence, Lu green #2D5A27 with overwhelming gold #D4AF37
glow, epic legendary card quality, dramatic divine lighting,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, highly detailed, 4K, professional
card game quality (Shadowverse legendary art level),
--ar 3:4 --zoom 1.5
```

### R009 孟子 (7/6/6, 战吼, 传说) — 孟子辩论，气势如虹
```
Mengzi (孟子) in passionate debate pose, arm raised for
emphasis, debating with opposing scholars (silhouettes
recoiling), "people first" energy radiating, Lu green
#2D5A27 with dramatic gold #D4AF37 aura, epic legendary
card quality, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic debate lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R010 荀子 (6/5/5, 战吼, 史诗) — 荀子讲学，性恶论
```
Xunzi (荀子) teaching in academy hall, students listening
attentively (silhouettes, subtle), discussing human nature
(性恶论), stern but caring teacher expression, Lu green
#2D5A27 and scholarly brown #8B4513, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, epic card quality, dramatic academic lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### R011 子路 (4/4/4, 冲锋, 稀有) — 子路勇武，手持长剑
```
Confucius's warrior disciple Zilu (子路) in half-scholar
half-warrior attire, charging forward with long sword,
courageous fierce expression, Lu green #2D5A27 with martial
red accents, dynamic combat pose, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic charge lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### R012 曾子 (5/3/6, 亡语, 稀有) — 曾子孝亲，侍奉父母
```
Filial disciple Zengzi (曾子) in respectful bowing pose
toward elderly parents (silhouettes), filial piety virtue
visualized as warm golden glow, Lu green #2D5A27 colors,
gentle devoted expression, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible, warm
family lighting, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

## 道家 (Daojia) 随从

### D001 道童 (1/1/2, 亡语, 普通) — 手持拂尘，天真无邪
```
Young Taoist apprentice Dao Tong (道童) in simple child-size
Taoist robe, holding small fly-whisk (拂尘), innocent pure
expression, natural earth tones #2F4F4F, mountain temple
background (subtle, <10%), traditional Chinese ink wash
style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, soft natural lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### D002 守山人 (3/2/5, 嘲讽, 普通) — 山林隐士，守护山门
```
Mountain gate guardian Shou Shan Ren (守山人) in hermit's
robe, standing guard at mountain temple gate with staff,
unmoving mountain-like stance, weathered hermit face,
Dao grey #696969 and green nature tones, mountain forest
background (subtle), traditional Chinese ink wash style,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in lower-center,
full body visible, dramatic mountain lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### D003 观星者 (2/1/3, 战吼, 普通) — 夜观天象，预知未来
```
Stargazer Guan Xing Zhe (观星者) in Taoist astronomical
robe, gazing at night sky with hand shielding eyes,
star-filled sky background (subtle, <15%), Dao silver
#C0C0C0 and night blue colors, wonder-struck expression,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, character in lower-center, full body visible,
dramatic starlight illumination, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### D004 符师 (4/3/4, 战吼, 稀有) — 朱砂黄纸，符咒飞舞
```
Talisman master Fu Shi (符师) in Taoist ritual robe,
painting talisman in mid-air with glowing brush, cinnabar
red symbols floating (abstract, no text), mystical focused
expression, Dao silver #C0C0C0 and red #8B0000 colors,
traditional Chinese mystical painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic mystical
brush lighting, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

### D005 真人 (5/4/5, 圣盾, 稀有) — 仙风道骨，御气飞行
```
Ascended Taoist Zhen Ren (真人) with immortal bearing,
floating slightly above ground on cloud wisps, celestial
robe flowing, serene enlightened expression, silver white
#C0C0C0 with divine shield glow (圣盾), Dao grey #696969,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game art,
card frame ready, full body visible, ethereal celestial
lighting from below, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### D006 隐士 (6/5/6, 潜行, 史诗) — 深山隐士，逍遥自在
```
Reclusive hermit Yin Shi (隐士) partially hidden in mountain
mist and bamboo grove, visible but fading in and out of
shadow, carefree detached expression, Dao grey #696969
with stealth purple #4B0082 mist, bamboo forest background,
traditional Chinese ink wash style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
frame ready, full body visible, dramatic mist lighting
with shadow play, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

### D007 方士 (3/2/3, 战吼, 普通) — 炉火熊熊，寻求长生
```
Alchemist Fang Shi (方士) tending a bronze cauldron with
mystical fire beneath, elixir vapors rising, seeking
immortality expression, Dao earth tones #2F4F4F with
orange fire glow, workshop setting (minimal background),
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game art,
card frame ready, character in lower-center, full body
visible, dramatic fire glow lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### D008 老子 (9/7/7, 战吼, 传说) — 紫气东来，道德经文环绕
```
Laozi (老子) as legendary card, riding azure water buffalo
(青牛), purple auspicious mist rising from east (紫气东来),
Dao De Jing text as abstract glowing symbols floating
around (no readable text), ultimate sage presence,
Dao grey #696969 with cosmic purple #4B0082, epic legendary
card quality, dramatic mystical lighting, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full
body visible, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

### D009 庄子 (8/6/6, 战吼, 传说) — 庄子梦蝶，物我两忘
```
Zhuangzi (庄子) as legendary card in dream state, half his
body dissolving into butterflies, butterfly dream visual
(梦蝶), transcendent peaceful expression, Dao silver #C0C0C0
and dreamy purple #4B0082 colors, surreal dreamlike atmosphere,
epic legendary card quality, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic dream lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### D010 列子 (7/5/7, 战吼, 史诗) — 列子御风，乘风而行
```
Liezi (列子) as epic card riding the wind, robes and hair
streaming dramatically, cloud surfing pose, wind elemental
energy swirling, free transcendent expression, Dao silver
#C0C0C0 and sky blue accents, epic card quality, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full
body visible, dramatic wind lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### D011 关尹子 (5/4/4, 战吼, 稀有) — 关尹子守关，道德传承
```
Gatekeeper Guan Yinzi (关尹子) at mountain pass gate,
holding Dao De Jing manuscript (abstract, no text),
the one who asked Laozi to write, guardian of wisdom
expression, Dao grey #696969 colors, mountain pass
background (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic gate lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### D012 文子 (4/3/5, 亡语, 稀有) — 文子著书，道家思想传承
```
Taoist scholar Wenzi (文子) writing scrolls, disciple of
Laozi's teachings, studious dedicated expression, Dao
earth tones #2F4F4F, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
game art, card frame ready, full body visible, soft
scholarly lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

## 墨家 (Mojia) 随从

### M001 机关弩手 (2/2/2, 战吼, 普通) — 手持连弩，机械精密
```
Mechanical crossbow operator Jiguan Nushou (机关弩手) in
practical Mo workshop attire, holding repeating crossbow
with visible gear mechanism, precise mechanical action
pose, Mo black #2C2C2C and bronze #B87333 colors, traditional
Chinese steampunk style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
character in lower-center, full body visible, dramatic
mechanical lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### M002 机关兽 (3/2/3, 亡语, 普通) — 齿轮转动，行动灵活
```
Wooden mechanical beast Jiguan Shou (机关兽) in tiger-like
form with visible bronze gears and joints, amber glowing
eyes, steam wisps from joints, bronze #B87333 and dark
wood #2C2C2C colors, ancient Chinese automaton style,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, creature in lower-center,
full body visible, dramatic mechanical lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M003 墨家弟子 (1/1/2, 战吼, 普通) — 手持工具，勤奋钻研
```
Young Mo apprentice Mojia Dizi (墨家弟子) in simple Mo
robes, holding carpenter's tools, eager learning expression,
Mo black #2C2C2C with red #C41E3A headband, workshop
setting (minimal), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
game art, card frame ready, character in lower-center,
full body visible, warm workshop lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M004 护城弩兵 (4/3/5, 嘲讽, 稀有) — 大型弩机，守城利器
```
Fortress crossbow guard Hucheng Nubing (护城弩兵) operating
large mounted siege crossbow on fortress wall, defensive
position behind massive weapon, Mo black #2C2C2C and bronze
#B87333, fortress battlement background (subtle), traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full
body visible, dramatic fortress lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M005 守城工兵 (3/2/4, 战吼, 普通) — 修筑防御工事，工具齐全
```
Fortification engineer Shoucheng Gongbing (守城工兵) with
full construction tools, repairing fortress wall, practical
working pose, Mo black #2C2C2C and earth tones, fortress
background (subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
game art, card frame ready, character in lower-center,
full body visible, dramatic work lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M006 攻城巨械 (7/6/8, 史诗) — 巨型攻城器械，投石车结构
```
Massive siege engine Gongcheng Juxie (攻城巨械), enormous
trebuchet/catapult design in ancient Chinese style, gears
and counterweights visible, imposing destructive presence,
bronze #B87333 and dark #2C2C2C colors, ancient Chinese
siege warfare aesthetic, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
machine in center, full construction visible, dramatic
siege lighting, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

### M007 工匠大师 (5/4/4, 战吼, 稀有) — 发明创造，智慧光芒
```
Master craftsman Gongjiang Dashi (工匠大师) surrounded by
floating mechanical inventions, blueprint sketches, holding
complex gear assembly, innovative genius expression, Mo
black #2C2C2C with bronze #B87333, workshop setting,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game art,
card frame ready, full body visible, dramatic innovation
lighting, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

### M008 墨子 (8/6/8, 战吼, 传说) — 墨子非攻，手持规矩，兼爱光芒
```
Mozi (墨子) as legendary card, radiating universal love
golden light (兼爱), holding carpenter's square and compass
(规矩), two mechanical guardian constructs (3/3 机关守卫)
flanking him, peacekeeper stance, Mo black #2C2C2C with
golden #D4AF37 divine glow, epic legendary card quality,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, full body visible, dramatic divine lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M009 公输班 (6/5/5, 战吼, 史诗) — 木匠祖师，工具发明
```
Gongshu Ban/Lu Ban (公输班/鲁班) as epic card, carpenter
patriarch with legendary tool belt, saw and plane in hands,
master innovator expression, Lu kingdom copper #B87333
with Mo black #2C2C2C, epic card quality, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
full body visible, dramatic craftsman lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### M010 禽滑厘 (4/3/4, 战吼, 稀有) — 墨子大弟子，守城专家
```
Qin Huali (禽滑厘) as Mozi's chief disciple card, fortress
defense expert stance with shield, training disciple
defenders (subtle background), Mo black #2C2C2C with
red #C41E3A, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic defender
lighting, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

### M011 田鸠 (5/4/5, 战吼, 史诗) — 墨家辩士，逻辑严密
```
Mo debater Tian Jiu (田鸠) in passionate logical argument
pose, debating opponent (silhouette), intellectual intensity,
Mo black #2C2C2C with subtle red #C41E3A, debate hall
setting (subtle), epic card quality, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, dramatic debate lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### M012 腹䵍 (3/2/3, 亡语, 普通) — 墨家巨子，执法严明，大义灭亲
```
Mo grandmaster Fu Tun (腹䵍) in stern judicial Mo robes,
holding law enforcement scroll, painful but determined
expression (大义灭亲 — executing own son for justice),
Mo black #2C2C2C with tragic red #C41E3A, traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
character in lower-center, full body visible, dramatic
tragic lighting, highly detailed, 4K, professional card
game quality, --ar 3:4 --zoom 1.5
```

## 阴阳家 (Yinyangjia) 随从

### Y001 巫祝 (2/2/2, 战吼, 普通) — 手持骨笛，神秘仪式
```
Ritual shaman Wu Zhu (巫祝) in ceremonial attire with bone
ornaments, holding bone flute, mystical ritual pose,
purple #4B0082 and dark colors, smoke and incense atmosphere,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game art,
card frame ready, character in lower-center, full body
visible, dramatic ritual lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Y002 占卜师 (3/2/3, 战吼, 普通) — 龟甲灼烧，裂纹解读
```
Diviner Zhanbu Shi (占卜师) heating tortoise shell over
flame, reading cracks forming, mystical fortune-telling
expression, purple #4B0082 and orange fire glow, oracle
bone divination, traditional Chinese mystical painterly illustration,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in lower-center,
full body visible, dramatic fire glow lighting, highly
detailed, 4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Y003 五行弟子 (1/1/2, 亡语, 普通) — 手持五行旗，学习术数
```
Young Five Elements apprentice Wuxing Dizi (五行弟子) in
student robe, holding five-colored flag (五行旗) in five
element colors, eager learning expression, purple #4B0082
accents, traditional Chinese mystical painterly illustration, card game
art, card frame ready, character in lower-center, full body
visible, soft mystical lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Y004 祭司 (4/3/4, 战吼, 稀有) — 主持祭祀，沟通天地
```
High priest Ji Si (祭司) in elaborate ceremonial robes,
conducting heaven-earth communication ritual, arms raised
to sky, mystical connection expression, purple #4B0082
and gold #D4AF37, altar with offerings (subtle), traditional
Chinese ritual traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
full body visible, dramatic celestial lighting from above,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### Y005 星象师 (5/4/5, 战吼, 稀有) — 星图绘制，预知吉凶
```
Astrologer Xingxiang Shi (星象师) drawing star charts on
silk scroll, constellations mapped, predicting fortune
expression, celestial blue #4169E1 and purple #4B0082,
observatory setting (minimal), traditional Chinese astronomical
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, dramatic starlight illumination, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Y006 风水师 (3/2/3, 战吼, 普通) — 罗盘定位，调整气场
```
Feng shui master Fengshui Shi (风水师) holding magnetic
compass (罗盘), adjusting energy flow pose, landscape
energy lines visualized as subtle glowing meridians,
purple #4B0082 and earth tones, traditional Chinese geomancy painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready,
character in lower-center, full body visible, dramatic
energy flow lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### Y007 方术士 (6/5/5, 战吼, 史诗) — 炼丹求仙，神秘莫测
```
Mystical alchemist Fang Shushi (方术士) with elixir
cauldron emitting multi-colored smoke, seeking immortality
through alchemy, mysterious arcane expression, purple
#4B0082 and mystical green smoke, epic card quality,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game art,
card frame ready, full body visible, dramatic alchemical
lighting, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

### Y008 邹衍 (9/7/7, 战吼, 传说) — 邹衍谈天，五行相生
```
Zou Yan (邹衍) as legendary card in cosmic lecture pose,
五大洲/九州 mythical geography visualized behind him,
five elements cycling in cosmic dance, universe-scale
presence, cosmic purple #4B0082 and five element colors,
epic legendary card quality, traditional Chinese cosmic
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, dramatic cosmic lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Y009 甘德 (7/6/6, 战吼, 史诗) — 天文学家甘德，星图绘制
```
Gan De (甘德) as epic card in observatory, mapping stars
on massive star chart, astronomer's tools around, pioneering
discovery expression, celestial blue #4169E1 and purple
#4B0082, epic card quality, traditional Chinese astronomical
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body
visible, dramatic observatory lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Y010 石申 (8/7/7, 战吼, 传说) — 天文学家石申，与甘德齐名
```
Shi Shen (石申) as legendary card, rival/peer of Gan De,
holding celestial globe with star positions mapped, cosmic
energy radiating from star chart, celestial blue #4169E1
with golden #D4AF37 star light, epic legendary card quality,
traditional Chinese astronomical painterly illustration, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic stellar lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### Y011 南公 (5/4/4, 战吼, 稀有) — 预言「楚虽三户，亡秦必楚」
```
Prophet Nan Gong (南公) in mystical prophetic pose, speaking
famous prophecy, three household symbols (三户) and Chu
kingdom symbols, prophetic visionary expression, purple
#4B0082 mystical aura, traditional Chinese mystical art
style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic prophetic lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Y012 安期生 (4/3/5, 亡语, 稀有) — 仙人安期生，长生不老
```
Immortal Anqi Sheng (安期生) in transcendent immortal form,
ageless youthful appearance despite ancient age, immortal
peach in hand, celestial immortal glow, purple #4B0082 and
gold #D4AF37 immortal colors, Penglai island mist background
(subtle), traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game
art, card frame ready, full body visible, ethereal immortal
lighting, highly detailed, 4K, professional card game
quality, --ar 3:4 --zoom 1.5
```

## 纵横家 (Zonghengjia) 随从

### Z001 辩士 (2/2/2, 战吼, 普通) — 纵横辩士，能言善辩
```
Eloquent debater Bian Shi (辩士) in traveling scholar robes,
passionate argument pose, persuasive hand gestures, silver
tongue suggested by subtle glow at mouth, mixed kingdom
colors, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, character in lower-center, full body
visible, dramatic debate lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Z002 说客 (3/2/3, 战吼, 普通) — 说客奔走，瓦解敌军
```
Persuasive envoy Shuoke (说客) in diplomatic traveling
attire, traveling pose with walking staff, silver-tongued
expression, enemy army disintegrating in background (subtle
silhouettes), mixed kingdom colors with grey #36454F,
traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame
ready, character in lower-center, full body visible,
dramatic diplomatic lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Z003 刺客 (2/3/1, 冲锋, 普通) — 刺客一击，致命威胁
```
Stealth assassin Ci Ke (刺客) in dark fitted clothing,
hidden blade extended, dynamic assassination lunge pose,
dark grey #36454F with red #C41E3A blade accent, shadow
and smoke effects, traditional Chinese assassin painterly illustration,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in lower-center,
full body visible, dramatic shadow lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Z004 使者 (4/3/4, 战吼, 稀有) — 使者往来，传递消息
```
Diplomatic messenger Shizhe (使者) on galloping horse carrying
sealed diplomatic message tube, urgent travel pose, mixed
kingdom colors, road/dust background (minimal), traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character
on horse in lower-center, full body visible, dramatic motion
lighting, highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### Z005 谋士 (5/4/4, 战吼, 稀有) — 谋士多谋，料敌先机
```
Strategic advisor Moushi (谋士) studying war maps and enemy
positions, predicting opponent moves expression, multiple
strategy symbols floating (abstract, no text), grey #36454F
colors, war room setting (minimal), traditional Chinese strategy painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full
body visible, dramatic strategic lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Z006 外交官 (4/3/5, 嘲讽+战吼, 稀有) — 外交官斡旋，维护和平
```
Senior diplomat Waijiaoguan (外交官) in formal diplomatic
Hanfu, mediating peace between two warring sides (silhouettes),
dignified peacekeeper expression, mixed kingdom diplomatic
colors, negotiation table background (subtle), traditional
Chinese traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full
body visible, dramatic diplomatic lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```

### Z007 策士 (3/2/4, 亡语, 稀有) — 策士献策，决胜千里
```
Strategic planner Ceshi (策士) presenting battle plan on
map, calculated expression, war tent setting, grey #36454F
colors with map elements, traditional Chinese strategy art
style, traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, character in
lower-center, full body visible, dramatic strategy lighting,
highly detailed, 4K, professional card game quality,
--ar 3:4 --zoom 1.5
```

### Z008 苏秦 (6/5/5, 战吼, 史诗) — 苏秦合纵，六国拜相
```
Su Qin (苏秦) as epic card, receiving six prime minister
seals from six kingdoms simultaneously, triumphant alliance
leader pose, six-colored aura representing six kingdoms,
epic card quality, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card game
art, card frame ready, full body visible, dramatic alliance
lighting from six directions, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Z009 张仪 (6/5/5, 战吼, 史诗) — 张仪连横，瓦解合纵
```
Zhang Yi (张仪) as epic card, breaking alliance chains
with powerful diplomatic gesture, horizontal alliance
symbolism (east-west line), cunning triumphant expression,
Wei kingdom blue #1A3A5C and gold #D4AF37, epic card
quality, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition,
card frame ready, full body visible, dramatic
alliance-breaking lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Z010 范雎 (5/4/5, 战吼, 稀有) — 范雎远交近攻，纵横捭阖
```
Strategist Fan Ju (范雎) pointing at far kingdom on map
while striking near kingdom, "befriend distant, attack
near" strategy visualized, calculating strategic expression,
grey #36454F colors, traditional Chinese strategy painterly illustration,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic strategic lighting, highly detailed, 4K,
professional card game quality, --ar 3:4 --zoom 1.5
```

### Z011 蔺相如 (4/3/4, 圣盾+战吼, 稀有) — 完璧归赵，智慧与勇气并存
```
Lin Xiangru (蔺相如) holding jade disc (和氏璧) protectively,
standing defiant before Qin king's court (subtle silhouettes),
brave intelligent expression, divine shield glow (圣盾),
Zhao kingdom colors, traditional Chinese painterly illustration, stylized ink wash brushwork meets digital card game art, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card
game art, card frame ready, full body visible, dramatic
confrontation lighting, highly detailed, 4K, professional
card game quality, --ar 3:4 --zoom 1.5
```

### Z012 鬼谷子 (10/8/8, 战吼, 传说) — 鬼谷子，纵横家之祖，徒弟遍天下
```
Guiguzi (鬼谷子) as legendary ultimate card, teacher of
Su Qin and Zhang Yi and countless strategists, disciples
gathered in cave (silhouettes), master strategist radiating
overwhelming wisdom and mystery, swirling energy of all
strategies combined, grey #36454F with purple #4B0082
mystical aura, epic legendary card quality, Shadowverse
legendary art level, traditional Chinese mystical painterly illustration,
traditional Chinese painterly illustration, hand-painted aesthetic, NOT photorealistic, NOT 3D render, NOT photography, card game composition, card frame ready, full body visible,
dramatic master-strategist lighting, highly detailed,
4K, professional card game quality, --ar 3:4 --zoom 1.5
```
