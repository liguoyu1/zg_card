import 'package:equatable/equatable.dart';

/// 卡牌类型
enum CardType { minion, spell, weapon }

/// 稀有度
enum Rarity { common, rare, epic, legendary }

/// 关键词
enum Keyword {
  battlecry,    // 战吼
  deathrattle,   // 亡语
  charge,       // 冲锋
  taunt,        // 嘲讽
  divineShield,  // 圣盾
  poisonous,    // 剧毒
  windfury,     // 风怒
  inspire,      // 激励
  lifesteal,    // 吸血
  stealth,      // 潜行
  silence,      // 沉默
  combo,        // 连击
  draw,         // 抽牌
}

/// 卡牌归属
enum CardOwner { neutral, bingjia, fajia, rujia, daojia, mojia, yinyangjia, zonghengjia }

/// 卡牌数据模型
class Card extends Equatable {
  
  const Card({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    this.attack = 0,
    this.health = 0,
    this.maxHealth = 0,
    required this.description,
    this.keywords = const [],
    required this.owner,
    required this.rarity,
    this.flavor = '',
    this.imageAsset = '',
    this.hasAttackedThisTurn = false,
    this.isDormant = false,
    this.hasUsedFirstWindfuryAttack = false,
  });
  final String id;
  final String name;
  final CardType type;
  final int cost;
  final int attack;
  final int health;
  final int maxHealth;
  final String description;
  final List<Keyword> keywords;
  final CardOwner owner;
  final Rarity rarity;
  final String flavor;
  /// 卡牌图片资源路径
  final String imageAsset;
  /// 本回合是否已攻击
  final bool hasAttackedThisTurn;
  /// 是否休眠（本回合不能攻击，需要等下回合）
  final bool isDormant;
  /// 风怒第一次攻击是否已使用
  final bool hasUsedFirstWindfuryAttack;
  
  /// 便捷属性
  bool get isMinion => type == CardType.minion;
  bool get isSpell => type == CardType.spell;
  bool get isWeapon => type == CardType.weapon;
  
  // 关键词检测
  bool get hasBattlecry => keywords.contains(Keyword.battlecry);
  bool get hasDeathrattle => keywords.contains(Keyword.deathrattle);
  bool get hasCharge => keywords.contains(Keyword.charge);
  bool get hasTaunt => keywords.contains(Keyword.taunt);
  bool get hasDivineShield => keywords.contains(Keyword.divineShield);
  bool get hasPoisonous => keywords.contains(Keyword.poisonous);
  bool get hasWindfury => keywords.contains(Keyword.windfury);
  bool get hasInspire => keywords.contains(Keyword.inspire);
  bool get hasLifesteal => keywords.contains(Keyword.lifesteal);
  bool get hasStealth => keywords.contains(Keyword.stealth);

  /// 是否可以攻击
  bool get canAttack {
    if (!isMinion || isDormant) return false;
    if (hasAttackedThisTurn) return false;
    return true;
  }

  @override
  List<Object?> get props => [id, name, type, cost, attack, health, maxHealth, description, keywords, owner, rarity, imageAsset, hasAttackedThisTurn, hasUsedFirstWindfuryAttack];
  
  Card copyWith({
    String? id,
    String? name,
    CardType? type,
    int? cost,
    int? attack,
    int? health,
    int? maxHealth,
    String? description,
    List<Keyword>? keywords,
    CardOwner? owner,
    Rarity? rarity,
    String? imageAsset,
    bool? hasAttackedThisTurn,
    bool? isDormant,
    bool? hasUsedFirstWindfuryAttack,
  }) {
    return Card(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      attack: attack ?? this.attack,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      owner: owner ?? this.owner,
      rarity: rarity ?? this.rarity,
      imageAsset: imageAsset ?? this.imageAsset,
      hasAttackedThisTurn: hasAttackedThisTurn ?? this.hasAttackedThisTurn,
      isDormant: isDormant ?? this.isDormant,
      hasUsedFirstWindfuryAttack: hasUsedFirstWindfuryAttack ?? this.hasUsedFirstWindfuryAttack,
    );
  }
}
