import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/models/deck.dart';

void main() {
  group('Deck Validation', () {
    final sampleCards = List.generate(30, (i) => Card(
      id: 'C${i.toString().padLeft(3, '0')}',
      name: '卡牌$i',
      type: CardType.minion,
      cost: i % 10,
      attack: 2,
      health: 3,
      description: '',
      owner: CardOwner.neutral,
      rarity: Rarity.common,
    ));

    test('Deck with 30 cards is valid', () {
      final deck = Deck(id: 'd1', name: '测试卡组', heroId: 'H_B001', cards: sampleCards, createdAt: DateTime.now());
      expect(deck.isValid, isTrue);
    });

    test('Deck with 29 cards is invalid', () {
      final deck = Deck(id: 'd2', name: '不足卡组', heroId: 'H_B001', cards: sampleCards.sublist(0, 29), createdAt: DateTime.now());
      expect(deck.isValid, isFalse);
    });

    test('Deck with 0 cards is invalid', () {
      final deck = Deck(id: 'd3', name: '空卡组', heroId: 'H_B001', cards: [], createdAt: DateTime.now());
      expect(deck.isValid, isFalse);
    });

    test('Deck.copyWith works correctly', () {
      final deck = Deck(id: 'd1', name: '原卡组', heroId: 'H_B001', cards: sampleCards, createdAt: DateTime.now());
      final copied = deck.copyWith(name: '新卡组');
      expect(copied.name, equals('新卡组'));
      expect(copied.id, equals('d1'));
      expect(copied.cards.length, equals(30));
    });

    test('Deck.id is unique for different instances', () {
      final d1 = Deck(id: 'a', name: 'A', heroId: 'H_B001', cards: [], createdAt: DateTime.now());
      final d2 = Deck(id: 'b', name: 'B', heroId: 'H_B001', cards: [], createdAt: DateTime.now());
      expect(d1.id, isNot(equals(d2.id)));
    });
  });
}
