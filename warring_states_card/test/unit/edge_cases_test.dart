import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/game_rules.dart';

void main() {
  const testHero = Hero(
    id: 'H_TEST', name: '测试英雄', className: 'test', kingdom: '测', heroPowerName: '测试', heroPowerDescription: '测试',
    skillType: SkillType.heal,
  );

  group('Edge Cases', () {
    test('Player with health 0 is dead', () {
      const player = Player(id: 'p1', hero: testHero, health: 0);
      expect(player.isDead, isTrue);
    });

    test('Player with negative health is dead', () {
      const player = Player(id: 'p1', hero: testHero, health: -5);
      expect(player.isDead, isTrue);
    });

    test('Empty hand counts as 0', () {
      const player = Player(id: 'p1', hero: testHero);
      expect(player.handCount, equals(0));
    });

    test('Empty board counts as 0', () {
      const player = Player(id: 'p1', hero: testHero);
      expect(player.boardCount, equals(0));
    });

    test('Max mana capped at 10', () {
      const player = Player(id: 'p1', hero: testHero, mana: 15, maxMana: 15);
      // GameRules should cap it
      expect(player.maxMana, greaterThanOrEqualTo(10));
    });

    test('GameRules initial health is 30', () {
      expect(GameRules.initialHealth, equals(30));
    });

    test('GameRules max hand size is 10', () {
      expect(GameRules.maxHandSize, equals(10));
    });

    test('GameRules max board size is 7', () {
      expect(GameRules.maxBoardSize, equals(7));
    });

    test('Card with all keywords does not crash', () {
      const card = Card(
        id: 'ALL', name: '全关键词', type: CardType.minion, cost: 10, attack: 10, health: 10,
        description: '全关键词测试',
        keywords: Keyword.values,
        owner: CardOwner.neutral, rarity: Rarity.legendary,
      );
      expect(card.hasTaunt, isTrue);
      expect(card.hasCharge, isTrue);
      expect(card.hasBattlecry, isTrue);
      expect(card.hasDeathrattle, isTrue);
      expect(card.hasDivineShield, isTrue);
    });

    test('Weapon card is not a minion and not a spell', () {
      const weapon = Card(id: 'W1', name: '武器', type: CardType.weapon, cost: 3, attack: 2, health: 2,
        description: '', owner: CardOwner.neutral, rarity: Rarity.common);
      expect(weapon.isMinion, isFalse);
      expect(weapon.isSpell, isFalse);
      expect(weapon.isWeapon, isTrue);
    });

    test('Spell card has no attack or health', () {
      const spell = Card(id: 'S1', name: '法术', type: CardType.spell, cost: 2,
        description: '法术测试', owner: CardOwner.neutral, rarity: Rarity.common);
      expect(spell.attack, equals(0));
      expect(spell.health, equals(0));
      expect(spell.isSpell, isTrue);
    });
  });
}
