import 'package:equatable/equatable.dart';
import 'card.dart';
import 'hero.dart';

/// 游戏玩家状态
class Player extends Equatable {
  final String id;
  final Hero hero;
  final int health;
  final int armor;
  final int mana;
  final int maxMana;
  final int spellPower; // 法术增强
  final int fatigueCounter; // 疲劳计数器
  final List<Card> hand;
  final List<Card> deck;
  final List<Card> board; // 战场随从
  final Card? weapon;
  
  const Player({
    required this.id,
    required this.hero,
    this.health = 30,
    this.armor = 0,
    this.mana = 0,
    this.maxMana = 0,
    this.spellPower = 0,
    this.fatigueCounter = 0,
    this.hand = const [],
    this.deck = const [],
    this.board = const [],
    this.weapon,
  });
  
  /// 是否有武器
  bool get hasWeapon => weapon != null;
  
  /// 手牌数量
  int get handCount => hand.length;
  
  /// 牌库数量
  int get deckCount => deck.length;
  
  /// 战场随从数量
  int get boardCount => board.length;
  
  /// 是否生命值耗尽
  bool get isDead => health <= 0;
  
  /// 是否满场
  bool get isBoardFull => boardCount >= 7;
  
  Player copyWith({
    String? id,
    Hero? hero,
    int? health,
    int? armor,
    int? mana,
    int? maxMana,
    int? spellPower,
    int? fatigueCounter,
    List<Card>? hand,
    List<Card>? deck,
    List<Card>? board,
    Card? weapon,
  }) {
    return Player(
      id: id ?? this.id,
      hero: hero ?? this.hero,
      health: health ?? this.health,
      armor: armor ?? this.armor,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      spellPower: spellPower ?? this.spellPower,
      fatigueCounter: fatigueCounter ?? this.fatigueCounter,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      board: board ?? this.board,
      weapon: weapon ?? this.weapon,
    );
  }
  
  @override
  List<Object?> get props => [id, hero, health, armor, mana, maxMana, spellPower, fatigueCounter, hand, deck, board, weapon];
}