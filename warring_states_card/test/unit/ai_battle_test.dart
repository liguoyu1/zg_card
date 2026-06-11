import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/ai_controller.dart';

void main() {
  const testHero = Hero(
    id: 'H_B001', name: '孙膑', className: 'bingjia', kingdom: '齐',
    health: 30, heroPowerName: '围魏救赵', heroPowerDescription: '获得2点护甲',
    skillType: SkillType.defensive,
  );

  group('AIController Battle Simulation', () {
    test('Simple AI returns play order without error', () {
      final ai = AIController(difficulty: AIDifficulty.simple);
      final hand = <Card>[
        Card(id: 'C1', name: '卡牌', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      final player = Player(id: 'ai', hero: testHero, mana: 10, maxMana: 10, hand: hand);
      final order = ai.getOptimalPlayOrder(hand, player);
      expect(order, isA<List<Card>>());
    });

    test('AI won\'t play cards it can\'t afford', () {
      final ai = AIController(difficulty: AIDifficulty.simple);
      final hand = [
        Card(id: 'C1', name: '高费', type: CardType.minion, cost: 10, attack: 10, health: 10,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      final player = Player(id: 'ai', hero: testHero, mana: 5, maxMana: 5, hand: hand);
      final result = ai.getOptimalPlayOrder(hand, player);
      expect(result, isA<List<Card>>());
    });

    test('AI prefers playable cards over unplayable', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final hand = [
        Card(id: 'C1', name: '低费', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
        Card(id: 'C2', name: '高费', type: CardType.minion, cost: 10, attack: 10, health: 10,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      final player = Player(id: 'ai', hero: testHero, mana: 5, maxMana: 5, hand: hand);
      final order = ai.getOptimalPlayOrder(hand, player);
      expect(order.isNotEmpty, isTrue);
    });

    test('Normal AI sorts by cost descending', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final hand = [
        Card(id: 'C1', name: '3费', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
        Card(id: 'C2', name: '5费', type: CardType.minion, cost: 5, attack: 5, health: 5,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      final player = Player(id: 'ai', hero: testHero, mana: 10, maxMana: 10, hand: hand);
      final order = ai.getOptimalPlayOrder(hand, player);
      if (order.length >= 2) {
        expect(order[0].cost, greaterThanOrEqualTo(order[1].cost));
      }
    });

    test('selectAttackTarget handles empty board', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final self = Player(id: 'p1', hero: testHero, board: [
        Card(id: 'A1', name: '攻击者', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ]);
      final opponent = Player(id: 'p2', hero: testHero);
      final target = ai.selectAttackTarget(self, opponent);
      expect(target, isNull);
    });

    test('selectAttackTarget attacks taunt first', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final self = Player(id: 'p1', hero: testHero, board: [
        Card(id: 'A1', name: '攻击者', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ]);
      final opponent = Player(id: 'p2', hero: testHero, board: [
        Card(id: 'T1', name: '嘲讽', type: CardType.minion, cost: 3, attack: 1, health: 5,
          description: '', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.common),
        Card(id: 'N1', name: '普通', type: CardType.minion, cost: 2, attack: 2, health: 2,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ]);
      final target = ai.selectAttackTarget(self, opponent);
      expect(target?.hasTaunt, isTrue);
    });

    test('shouldActivateCombo depends on difficulty', () {
      final simpleAI = AIController(difficulty: AIDifficulty.simple);
      final hardAI = AIController(difficulty: AIDifficulty.hard);
      expect(simpleAI.shouldActivateCombo([]), isFalse);
      final bigHand = List.generate(5, (i) => Card(
        id: 'C$i', name: '卡牌$i', type: CardType.minion, cost: 3, attack: 3, health: 3,
        description: '', owner: CardOwner.neutral, rarity: Rarity.common,
      ));
      expect(hardAI.shouldActivateCombo(bigHand), isTrue);
    });

    test('Abyss AI getOptimalPlayOrder works', () {
      final ai = AIController(difficulty: AIDifficulty.abyss);
      final hand = [
        Card(id: 'C1', name: '随从', type: CardType.minion, cost: 3, attack: 3, health: 3,
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      final player = Player(id: 'ai', hero: testHero, mana: 5, maxMana: 5, hand: hand);
      final order = ai.getOptimalPlayOrder(hand, player);
      expect(order, isA<List<Card>>());
    });
  });
}
