#!/usr/bin/env python3
"""
生成含详细视觉描述的prompt：见图知卡牌/见图知意/见图知名

从Dart源文件读取卡牌数据(name/desc/flavor/type)，
根据历史背景生成每张卡的详细视觉描述prompt。
"""
import re, json, os
from pathlib import Path

SELF_DIR = Path(__file__).parent
PROJ = SELF_DIR.parent
INVENTORY = json.loads((SELF_DIR / 'inventory.json').read_text())
CARD_NAMES = {k: v['name'] for k, v in INVENTORY['cards'].items()}
HERO_NAMES = {k: v['name'] for k, v in INVENTORY['heroes'].items()}

# ---------- 1. Parse Dart source ----------
def parse_card_dart():
    """Read all card Dart files, return dict[id] = {name, desc, flavor, type}"""
    cards = {}
    for fname in ['bingjia_fajia.dart', 'rujia_daojia.dart', 'mojia_yinyangjia_zonghengjia.dart', 'neutral_cards.dart']:
        text = (PROJ / 'lib/data/cards' / fname).read_text()
        for b in re.findall(r'Card\((.*?)\)\s*[,;]', text, re.DOTALL):
            id_m = re.search(r"id:\s*'(\w+)'", b)
            if not id_m: continue
            name_m = re.search(r"name:\s*'(.*?)'", b)
            desc_m = re.search(r"description:\s*'(.*?)'", b)
            flav_m = re.search(r"flavor:\s*'(.*?)'", b)
            kind_m = re.search(r"type:\s*CardType\.(\w+)", b)
            cards[id_m.group(1)] = {
                'name': name_m.group(1) if name_m else '',
                'desc': desc_m.group(1) if desc_m else '',
                'flavor': flav_m.group(1) if flav_m else '',
                'type': kind_m.group(1) if kind_m else 'unknown',
            }
    return cards

def parse_heroes_dart():
    """Parse heroes_data.dart for hero names and class"""
    text = (PROJ / 'lib/data/heroes/heroes_data.dart').read_text()
    heroes = {}
    for m in re.finditer(r"Hero\(.*?name:\s*'(.*?)'.*?className:\s*'(.*?)'\)", text):
        h_id = m.group(1)
        heroes[h_id] = {'name': m.group(1), 'className': m.group(2)}
    return heroes

# ---------- 2. Visual description generation ----------
# Keyword→visual mapping for common historical Chinese terms
VISUAL_DESC = {
    # Weapon types
    '剑': 'ancient Chinese double-edged straight sword (jian), ornate handle with tassel',
    '刀': 'single-edged Chinese broadsword (dao), curved blade, sturdy back',
    '戟': 'Chinese halberd (ji), combining spear point with crescent blade on a long shaft',
    '戈': 'Chinese dagger-axe (ge), bronze blade mounted on long wooden shaft',
    '弓': 'Chinese composite recurve bow, horn and sinew construction',
    '弩': 'Chinese crossbow (nu) with bronze trigger mechanism',
    '矛': 'spear with broad bronze or iron head and long wooden haft',
    '盾': 'Chinese shield, rectangular or round, lacquered wood construction',
    '杖': 'staff or walking stick, gnarled wood',
    '扇': 'Chinese folding fan (shanzi), silk or paper',
    '釜': 'cauldron or cooking vessel',
    '鞭': 'Chinese whip weapon, segmented metal links on a handle',
    '锤': 'Chinese war hammer, heavy metal head',
    '枪': 'Chinese spear, flexible ash wood shaft',

    # Armor types
    '甲': 'lamellar armor composed of overlapping leather or iron plates, worn over silk robes',
    '铠': 'iron armor with riveted plates and leather backing',
    '袍': 'long flowing silk robe in traditional Chinese style',
    '衣': 'traditional Chinese robe (hanfu) with crossed collar and sash',

    # Character types
    '士': 'warrior or scholar-official, dignified bearing',
    '兵': 'foot soldier in ancient Chinese army, armored with helmet',
    '将': 'Chinese general wearing elaborate armor and distinctive helmet with plumes',
    '王': 'Chinese king or ruler wearing imperial robes and crown, seated on throne',
    '卒': 'infantry soldier in unit uniform, carrying weapon',
    '骑': 'mounted cavalry soldier on horse with saddle',
    '军': 'army commander or military strategist',

    # Natural elements (for spells)
    '风': 'wind swirling through bamboo leaves, dynamic flowing lines',
    '火': 'fire blazing across the landscape, orange and red flames in ink wash style',
    '水': 'water flowing like river currents, cascading waterfall',
    '雷': 'lightning striking from dark clouds, jagged energy bolts',
    '电': 'electric sparks and flashes, quick dynamic strokes',
    '山': 'towering mountain peaks shrouded in mist, vertical grandeur',
    '云': 'clouds swirling and merging, ethereal atmospheric effect',
    '雪': 'snow falling on ancient pavilion, white contrast on dark ink background',

    # Architecture
    '城': 'ancient Chinese walled city with watchtowers, crenellations, and massive gates',
    '关': 'mountain pass fortress with defensive walls and gate tower',
    '台': 'raised platform or terrace, often with ritual purposes',
    '宫': 'palace with sweeping curved roofs, red pillars, and golden ornamentation',
    '殿': 'great hall with multiple eaves, ornate roof ridges and dragon ornaments',
}

def describe_figure(name, flavor, desc):
    """Generate visual description for a historical figure/unit."""
    parts = []
    # Check for keywords in name and flavor
    combined = name + flavor

    # Detect figure type
    if any(k in combined for k in ['王', '帝', '皇', '侯', '公', '主']):
        parts.append('noble or ruler wearing elaborate silk robes and ornate crown')
    elif any(k in combined for k in ['将', '帅', '军']):
        parts.append('general in full battle armor with helmet plumes and commanding presence')
    elif any(k in combined for k in ['士', '卒', '兵', '骑']):
        parts.append('ancient Chinese soldier in uniform armor, carrying traditional weapon')
    elif any(k in combined for k in ['子', '师', '生', '儒']):
        parts.append('scholar in flowing robes holding a scroll, with contemplative expression')
    elif any(k in combined for k in ['侠', '客', '豪']):
        parts.append('wandering martial artist in traditional robes, confident and alert')
    elif any(k in combined for k in ['仙', '道', '真人']):
        parts.append('Daoist immortal or sage, flowing robes, ethereal aura, mystical appearance')
    else:
        parts.append('traditional Chinese figure in period attire with distinctive bearing')

    # Add weapon detail from name/flavor
    weapon_descs = []
    for kw, desc_text in VISUAL_DESC.items():
        if kw in combined and kw in ['剑','刀','戟','戈','弓','弩','矛','盾','杖','扇','鞭','锤','枪']:
            weapon_descs.append(f'wielding a {desc_text}')
    if weapon_descs:
        parts.append(weapon_descs[0])

    # Add type-specific description
    if '将' in name:
        parts.append('wearing general\'s armor with distinctive helmet, cape flowing in wind')
    elif '士' in name:
        parts.append('disciplined warrior stance, armor gleaming with battle readiness')

    return ', '.join(parts)

def describe_scene(name, flavor, desc):
    """Generate scene description for a spell/tactic."""
    combined = name + flavor
    parts = []

    # Detect scene type
    if any(k in combined for k in ['围', '攻', '战', '伐', '击', '征']):
        parts.append('battle scene with armies clashing beneath ancient city walls')
    elif any(k in combined for k in ['计', '策', '谋', '略', '智']):
        parts.append('strategic planning scene with maps, tokens, and command tent')
    elif any(k in combined for k in ['天', '地', '阴', '阳', '五行']):
        parts.append('cosmic forces clashing, celestial phenomena with swirling energies')
    elif any(k in combined for k in ['和', '合', '盟', '交', '通']):
        parts.append('diplomatic scene with envoys meeting, banners and ceremonial items')
    else:
        parts.append('dramatic scene')

    # Add natural elements
    for kw, desc_text in VISUAL_DESC.items():
        if kw in combined and kw in ['风','火','水','雷','电','山','云','雪']:
            parts.append(f'with {desc_text}')

    return ', '.join(parts)

def describe_weapon(name, flavor):
    """Generate weapon description."""
    combined = name + flavor
    parts = [f'traditional Chinese weapon: {name}']
    for kw, desc_text in VISUAL_DESC.items():
        if kw in combined and kw in ['剑','刀','戟','戈','弓','弩','矛','盾','杖','扇','鞭','锤','枪']:
            parts.append(f'style of {desc_text}')
            break
    else:
        parts.append('intricate metalwork with Chinese ornamental details')
    parts.append('floating vertically in space, detailed craftsmanship, gleaming metal')
    return ', '.join(parts)

def describe_hero(name):
    """Generate visual description for a specific known hero."""
    hero_specs = {
        '孙膑': 'Sun Bin, military strategist seated in wheeled conveyance (since his feet were crippled), wearing Han dynasty scholar-official robes, holding a military scroll, wise contemplative expression, a walking stick nearby',
        '吴起': 'Wu Qi, stern-faced general and reformer in Qin-style armor, holding a bamboo scroll of military law, commanding presence, battle standard behind him',
        '白起': 'Bai Qi, legendary Qin general known for many victories, wears imposing black iron armor, holding a general\'s sword, fierce battle-hardened expression, blood-red cape',
        '王翦': 'Wang Jian, veteran Qin general in elaborate commander armor, white beard, strategist\'s composure, pointing forward with authority',
        '廉颇': 'Lian Po, elderly but formidable Zhao general, with white beard and battle scars, heavy armor, leaning on a large battle-axe',
        '蔺相如': 'Lin Xiangru, Zhao diplomat and statesman in elegant court robes, holding a jade bi (sacred disc), dignified and composed',
        '信陵君': 'Lord Xinling (Wei Wuji), noble in ornate princely robes, holding a tiger tally (兵符), commanding yet scholarly demeanor',
        '孟尝君': 'Lord Mengchang (Tian Wen), Qi noble in rich purple robes, known for harboring retainers, surrounded by followers',
        '平原君': 'Lord Pingyuan (Zhao Sheng), Zhao noble in formal court attire, diplomatic expression, holding ceremonial tablet',
        '春申君': 'Lord Chunshen (Huang Xie), Chu noble in elaborate southern-style robes, holding a seal of office',
        '李牧': 'Li Mu, Zhao general famous for frontier defense, practical armor, bow and arrow, alert watchful stance',
        '赵奢': 'Zhao She, Zhao general and tax official, dual identity shown with both court robes and military gear',
        '乐毅': 'Yue Yi, Yan general who conquered 70+ cities, commanding presence in full armor, pointing forward',
        '田单': 'Tian Dan, Qi general famous for fire-ox strategy, holding torch and wearing commander armor, decisive expression',
        '商鞅': 'Shang Yang, stern-faced reformer in Qin court robes, holding a bamboo law code, unwavering expression',
        '韩非': 'Han Feizi, legalist philosopher in scholarly robes, holding brush and bamboo slips, contemplative intellectual gaze',
        '申不害': 'Shen Buhai, bureaucrat-reformer in simple official robes, holding administrative scrolls, efficient demeanor',
        '孔子': 'Confucius (Kongzi), elderly sage with long beard and traditional scholar robes, warm wise eyes, holding a scroll',
        '老子': 'Laozi, Daoist sage riding an ox, flowing white robes, wispy white beard, ethereal expression',
        '孟子': 'Mencius (Mengzi), Confucian scholar in flowing robes, animated speaking gesture, wise expression',
        '墨子': 'Mozi, philosopher in simple practical robes, holding tools for engineering, pragmatic and humble demeanor',
        '庄子': 'Zhuangzi, Daoist philosopher in relaxed informal robes, holding a book, whimsical dreamy smile',
        '鲁班': 'Lu Ban, master craftsman in artisan robes, holding a carpenter\'s square, surrounded by woodworking tools',
        '屈原': 'Qu Yuan, poet-minister in flowing Chu robes, standing by riverbank, holding a lotus, melancholy poetic expression',
        '扁鹊': 'Bian Que, legendary physician in simple robes, holding acupuncture needles, compassionate expression',
        '荆轲': 'Jing Ke, assassin in hidden weapon pose, one hand on dagger, decisive determined expression, flowing cape',
        '甘罗': 'Gan Luo, young prodigy diplomat in miniature court robes, boyish face but wise eyes, holding diplomatic credential',
        '毛遂': 'Mao Sui, self-recommending diplomat in travel robes, pointing at self confidently, holding a bamboo slip',
        '苏秦': 'Su Qin, strategist of Vertical Alliance, in travel-worn but dignified robes, holding six-state seal token',
        '张仪': 'Zhang Yi, strategist of Horizontal Alliance, in elegant Wei-style robes, holding a negotiation scroll, sharp eyes',
        '嬴政': 'Qin Shi Huang, emperor in black imperial robes with dragon embroidery, holding jade seal, majestic and commanding',
        '吕不韦': 'Lu Buwei, wealthy merchant-turned-chancellor in luxurious brocade robes, holding a golden ingot and scroll',
        '李斯': 'Li Si, Qin chancellor in formal court robes, holding seal and bamboo slips, shrewd intelligent eyes',
        '王诩': 'Wang Xu (Guiguzi), legendary hermit strategist in Daoist robes, white hair, mystical mountain dwelling aura',
        '范蠡': 'Fan Li, retired strategist-turned-merchant in simple but quality robes, holding a fishing rod or gold ingot',
        '西施': 'Xi Shi, legendary beauty in flowing silk robes, delicate features, standing by lotus pond',
        '赵姬': 'Zhao Ji, queen mother in lavish palace robes, elegant and regal bearing',
        '庞涓': 'Pang Juan, Wei general in Wei-style armor, ambitious and calculating expression',
    }
    return hero_specs.get(name, f'ancient Chinese historical figure {name} in traditional attire, dignified portrait')

def get_visual_desc(card_id, card):
    """Main dispatch: generate visual description for any card."""
    kind = card['type']
    name = card['name']
    flavor = card.get('flavor', '')
    desc = card.get('desc', '')

    if kind == 'minion':
        return describe_figure(name, flavor, desc)
    elif kind == 'spell':
        return describe_scene(name, flavor, desc)
    elif kind == 'weapon':
        return describe_weapon(name, flavor)
    return 'traditional Chinese subject'

# ---------- 3. Build prompts ----------
def build_prompt(card_id, card, style_prefix):
    """Build a single card prompt with visual description."""
    visual = get_visual_desc(card_id, card)
    name = card['name']
    flavor = card.get('flavor', '')
    desc = card.get('desc', '')
    kind = card['type']

    # Core: subject name + visual description
    subject = f'{name}: {visual}'

    # For spells, emphasize scene composition
    # For weapons, emphasize object isolation
    if kind == 'spell':
        subject += ', dramatic ink wash composition, sweeping brushstrokes'
    elif kind == 'weapon':
        subject += ', weapon-only, no human figure, centered composition, detailed texture'
    elif kind == 'minion':
        subject += ', character portrait, half-body or full-figure, dynamic pose'

    return f'{style_prefix}, {subject}, {flavor}'

def build_hero_prompt(hero_id, hero, style_prefix):
    """Build a hero prompt with detailed visual description."""
    name = hero['name']
    visual = describe_hero(name)
    return f'{style_prefix}, {name}: {visual}, heroic portrait, full character illustration'

# ---------- 4. Main ----------
def main():
    cards_data = parse_card_dart()
    # Enrich inventory data with descriptions
    all_cards = {}
    for cid, cinfo in INVENTORY['cards'].items():
        extra = cards_data.get(cid, {})
        all_cards[cid] = {**cinfo, **extra}

    all_heroes = INVENTORY['heroes']
    # Enrich heroes
    parsed_heroes = parse_heroes_dart()

    styles = {
'chibi_cute': {
'prefix': 'Cute cartoon chibi style, adorable oversized head with small body, big expressive eyes, simplified cute faces, soft colors, playful innocent expression, flat vector art style, no realism, chibi human figure, cute stylized human character, not an animal',
'label': 'Q版卡通',
        },
        'fantasy_rpg': {
            'prefix': 'Traditional Chinese ink wash painting (国画水墨), classical brush strokes, elegant composition, grand scroll painting, rich ink tones with subtle color washes, heroic historical atmosphere',
            'label': '水墨史诗',
        },
        'euro_fantasy': {
            'prefix': 'Vintage European fantasy illustration style, medieval woodcut print aesthetic, old manuscript illumination style, muted earthy tones, nostalgic retro fantasy art, storybook illustration, no realism',
            'label': '欧洲复古',
        },
    }

    neg = ('photorealistic, photo, realistic face, real human face, real person, human photograph, '
           'modern elements, text, words, letters, signature, watermark, '
           'border, frame, card frame, card template, UI, digital interface, '
           '3D render, CG artwork, 3D shading, anime, manga, hentai')

    for style_key, style_cfg in styles.items():
        out = {
            'style': style_cfg['label'],
            'negative_prompt': neg,
            'pre_prompt': style_cfg['prefix'],
            'cards': {},
            'heroes': {},
        }
        for cid, card in all_cards.items():
            prompt = build_prompt(cid, card, style_cfg['prefix'])
            out['cards'][cid] = {'name': card['name'], 'prompt': prompt}

        for hid, hero in all_heroes.items():
            prompt = build_hero_prompt(hid, hero, style_cfg['prefix'])
            out['heroes'][hid] = {'name': hero['name'], 'prompt': prompt}

        path = PROJ / 'assets' / f'prompts_{style_key}.json'
        path.write_text(json.dumps(out, ensure_ascii=False, indent=2))
        print(f'Wrote {path} ({len(out["cards"])} cards + {len(out["heroes"])} heroes)')

if __name__ == '__main__':
    main()
