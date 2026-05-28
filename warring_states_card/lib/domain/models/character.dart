import 'package:equatable/equatable.dart';
import 'hero.dart';

/// 角色数据 (类DNF模式)
class Character extends Equatable {
  final String id;
  final GameClass gameClass;
  final Hero hero;
  final int level;
  final int experience;
  final int dust;
  final List<String> ownedCardIds; // 拥有的卡牌ID列表
  final List<String> unlockedHeroIds; // 已解锁的英雄
  
  const Character({
    required this.id,
    required this.gameClass,
    required this.hero,
    this.level = 1,
    this.experience = 0,
    this.dust = 0,
    this.ownedCardIds = const [],
    this.unlockedHeroIds = const [],
  });
  
  /// 是否拥有某张卡牌
  bool ownsCard(String cardId) => ownedCardIds.contains(cardId);
  
  /// 是否拥有某英雄
  bool hasHero(String heroId) => unlockedHeroIds.contains(heroId);
  
  /// 添加卡牌
  Character addCard(String cardId) {
    if (ownsCard(cardId)) return this;
    return copyWith(ownedCardIds: [...ownedCardIds, cardId]);
  }
  
  /// 添加多张卡牌
  Character addCards(List<String> cardIds) {
    final newIds = cardIds.where((id) => !ownsCard(id)).toList();
    if (newIds.isEmpty) return this;
    return copyWith(ownedCardIds: [...ownedCardIds, ...newIds]);
  }
  
  Character copyWith({
    String? id,
    GameClass? gameClass,
    Hero? hero,
    int? level,
    int? experience,
    int? dust,
    List<String>? ownedCardIds,
    List<String>? unlockedHeroIds,
  }) {
    return Character(
      id: id ?? this.id,
      gameClass: gameClass ?? this.gameClass,
      hero: hero ?? this.hero,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      dust: dust ?? this.dust,
      ownedCardIds: ownedCardIds ?? this.ownedCardIds,
      unlockedHeroIds: unlockedHeroIds ?? this.unlockedHeroIds,
    );
  }
  
  @override
  List<Object?> get props => [id, gameClass, hero, level, experience, dust, ownedCardIds, unlockedHeroIds];
}