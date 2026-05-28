import '../../../domain/models/models.dart';
import 'bingjia_fajia.dart';
import 'rujia_daojia.dart';
import 'mojia_yinyangjia_zonghengjia.dart';

/// 中立卡牌
const List<Card> neutralCards = [
  // 1费随从
  Card(id: 'N001', name: '民兵', type: CardType.minion, cost: 1, attack: 1, health: 2, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '各国民兵，战时出征。'),
  Card(id: 'N002', name: '斥候', type: CardType.minion, cost: 1, attack: 1, health: 1, 
       description: '战吼：抽一张牌', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '斥候探路，信息先行。'),
  Card(id: 'N003', name: '流浪者', type: CardType.minion, cost: 1, attack: 1, health: 1, 
       description: '亡语：抽一张牌', keywords: [Keyword.deathrattle], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '流浪天涯，四海为家。'),
  // 2费随从
  Card(id: 'N004', name: '侍卫', type: CardType.minion, cost: 2, attack: 2, health: 2, 
       description: '嘲讽', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '侍卫护主，忠心耿耿。'),
  Card(id: 'N005', name: '剑客', type: CardType.minion, cost: 2, attack: 2, health: 2, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '剑客游侠，快意恩仇。'),
  Card(id: 'N006', name: '谋士', type: CardType.minion, cost: 2, attack: 2, health: 3, 
       description: '战吼：抽一张牌', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '谋士多智，运筹帷幄。'),
  Card(id: 'N007', name: '药师', type: CardType.minion, cost: 2, attack: 1, health: 3, 
       description: '战吼：恢复2点生命值', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '药师炼丹，治病救人。'),
  // 3费随从
  Card(id: 'N008', name: '甲士', type: CardType.minion, cost: 3, attack: 3, health: 3, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '甲士重装，铜墙铁壁。'),
  Card(id: 'N009', name: '弓手', type: CardType.minion, cost: 3, attack: 2, health: 4, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '弓手远程，百步穿杨。'),
  Card(id: 'N010', name: '骑兵', type: CardType.minion, cost: 3, attack: 3, health: 2, 
       description: '冲锋', keywords: [Keyword.charge], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '骑兵突袭，势不可挡。'),
  Card(id: 'N011', name: '方士', type: CardType.minion, cost: 3, attack: 2, health: 3, 
       description: '战吼：造成1点伤害', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '方士施法，神秘莫测。'),
  Card(id: 'N012', name: '医师', type: CardType.minion, cost: 3, attack: 2, health: 4, 
       description: '战吼：恢复3点生命值', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '医师救人，妙手回春。'),
  // 4费随从
  Card(id: 'N013', name: '将领', type: CardType.minion, cost: 4, attack: 4, health: 3, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '将领指挥，千军万马。'),
  Card(id: 'N014', name: '校尉', type: CardType.minion, cost: 4, attack: 3, health: 4, 
       description: '战吼：获得+1/+1', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '校尉练兵，纪律严明。'),
  Card(id: 'N015', name: '武士', type: CardType.minion, cost: 4, attack: 4, health: 4, 
       description: '嘲讽', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '武士道精神，视死如归。'),
  Card(id: 'N016', name: '刺客', type: CardType.minion, cost: 4, attack: 5, health: 2, 
       description: '潜行', keywords: [Keyword.stealth], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '刺客暗行，一击必杀。'),
  // 5费随从
  Card(id: 'N017', name: '都尉', type: CardType.minion, cost: 5, attack: 5, health: 4, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '都尉一方，守土有责。'),
  Card(id: 'N018', name: '猛将', type: CardType.minion, cost: 5, attack: 6, health: 3, 
       description: '冲锋', keywords: [Keyword.charge], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '猛将如虎，万夫不当。'),
  Card(id: 'N019', name: '谋主', type: CardType.minion, cost: 5, attack: 4, health: 4, 
       description: '战吼：抽两张牌', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.epic,
       flavor: '谋主智囊，决胜千里。'),
  Card(id: 'N020', name: '猛犸', type: CardType.minion, cost: 5, attack: 4, health: 5, 
       description: '嘲讽', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '战象横行，势不可挡。'),
  // 6费随从
  Card(id: 'N021', name: '将军', type: CardType.minion, cost: 6, attack: 6, health: 4, 
       description: '战吼：使所有友方随从获得+1/+1', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.epic,
       flavor: '将军威名，天下敬服。'),
  Card(id: 'N022', name: '勇士', type: CardType.minion, cost: 6, attack: 5, health: 5, 
       description: '战吼：造成2点伤害', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '勇士无双，力敌万夫。'),
  Card(id: 'N023', name: '宗师', type: CardType.minion, cost: 6, attack: 5, health: 5, 
       description: '嘲讽', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '一代宗师，武林盟主。'),
  // 7费随从
  Card(id: 'N024', name: '上将军', type: CardType.minion, cost: 7, attack: 7, health: 5, 
       description: '战吼：抽三张牌', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.epic,
       flavor: '上将军位极人臣，统领三军。'),
  Card(id: 'N025', name: '战神', type: CardType.minion, cost: 7, attack: 8, health: 6, 
       description: '嘲讽，战吼：造成3点伤害', keywords: [Keyword.taunt, Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.legendary,
       flavor: '战神刑天，勇猛无敌。'),
  // 8费随从
  Card(id: 'N026', name: '霸王', type: CardType.minion, cost: 8, attack: 8, health: 8, 
       description: '嘲讽，战吼：使所有敌方随从获得-2/-2', keywords: [Keyword.taunt, Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.legendary,
       flavor: '力拔山兮气盖世。'),
  // 9费随从
  Card(id: 'N027', name: '天帝', type: CardType.minion, cost: 9, attack: 9, health: 9, 
       description: '战吼：消灭所有攻击力低于5的敌方随从', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.legendary,
       flavor: '天命所归，帝王之相。'),
  // 10费随从
  Card(id: 'N028', name: '神龙', type: CardType.minion, cost: 10, attack: 10, health: 10, 
       description: '嘲讽，战吼：恢复所有友方角色10点生命值', keywords: [Keyword.taunt, Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.legendary,
       flavor: '龙腾四海，天下太平。'),
  // 法术
  Card(id: 'N029', name: '调兵遣将', type: CardType.spell, cost: 1, 
       description: '抽两张牌', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '调兵遣将，调度有方。'),
  Card(id: 'N030', name: '四面楚歌', type: CardType.spell, cost: 2, 
       description: '对所有敌方随从造成1点伤害', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '四面楚歌，敌军围困。'),
  Card(id: 'N031', name: '知己知彼', type: CardType.spell, cost: 2, 
       description: '发现一张卡牌', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '知己知彼，百战不殆。'),
  Card(id: 'N032', name: '坚壁清野', type: CardType.spell, cost: 3, 
       description: '使所有随从获得+0/+2', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '坚壁清野，敌军无所获。'),
  Card(id: 'N033', name: '以少胜多', type: CardType.spell, cost: 4, 
       description: '对一个随从造成4点伤害', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '兵贵精不贵多。'),
  Card(id: 'N034', name: '奇袭', type: CardType.spell, cost: 3, 
       description: '对敌方英雄造成3点伤害', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '奇袭得手，敌军大乱。'),
  Card(id: 'N035', name: '增援', type: CardType.spell, cost: 5, 
       description: '召唤两个2/2的士兵', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '增援部队，源源不断。'),
  Card(id: 'N036', name: '决胜局', type: CardType.spell, cost: 6, 
       description: '抽三张牌', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '决战时刻，一决胜负。'),
  Card(id: 'N037', name: '横扫千军', type: CardType.spell, cost: 7, 
       description: '对所有敌方随从造成5点伤害', keywords: [], owner: CardOwner.neutral, rarity: Rarity.epic,
       flavor: '横扫千军如卷席。'),
  Card(id: 'N038', name: '反戈一击', type: CardType.spell, cost: 4, 
       description: '使一个随从获得+3/+3和嘲讽', keywords: [], owner: CardOwner.neutral, rarity: Rarity.rare,
       flavor: '反戈一击，攻守易形。'),
  // 武器
  Card(id: 'NW001', name: '青铜剑', type: CardType.weapon, cost: 1, attack: 2, health: 2, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '标准青铜剑，剑身有纹饰。'),
  Card(id: 'NW002', name: '长戟', type: CardType.weapon, cost: 3, attack: 4, health: 2, 
       description: '', keywords: [], owner: CardOwner.neutral, rarity: Rarity.common,
       flavor: '长戟在手，横扫千军。'),
  Card(id: 'NW003', name: '秦王剑', type: CardType.weapon, cost: 8, attack: 8, health: 3, 
       description: '战吼：消灭一个传说随从', keywords: [Keyword.battlecry], owner: CardOwner.neutral, rarity: Rarity.legendary,
       flavor: '秦始皇佩剑，统一六国。'),
];

/// 获取所有卡牌
List<Card> getAllCards() {
  return [
    ...bingjiaCards,
    ...fajiaCards,
    ...rujiaCards,
    ...daojiaCards,
    ...mojiaCards,
    ...yinyangjiaCards,
    ...zonghengjiaCards,
    ...neutralCards,
  ];
}

/// 获取职业所有卡牌
List<Card> getCardsByOwner(CardOwner owner) {
  return getAllCards().where((c) => c.owner == owner).toList();
}

/// 获取中立卡牌
List<Card> getNeutralCards() {
  return getAllCards().where((c) => c.owner == CardOwner.neutral).toList();
}

/// 获取职业预设卡组(30张)
List<Card> getPresetDeck(CardOwner owner) {
  final exclusive = getCardsByOwner(owner).take(15).toList();
  final neutral = getNeutralCards().take(15).toList();
  return [...exclusive, ...neutral];
}