import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/data/cards/cards.dart';

void main() {
  group('Card Data Integrity', () {
    test('getAllCards returns at least 144 cards', () {
      final cards = getAllCards();
      expect(cards.length, greaterThanOrEqualTo(144));
    });

    test('No card has negative cost/attack/health', () {
      final cards = getAllCards();
      for (final c in cards) {
        expect(c.cost, greaterThanOrEqualTo(0), reason: '${c.id} cost negative');
        if (c.isMinion || c.isWeapon) {
          expect(c.attack, greaterThanOrEqualTo(0), reason: '${c.id} attack negative');
          expect(c.health, greaterThanOrEqualTo(0), reason: '${c.id} health negative');
        }
      }
    });

    test('All cards have non-empty id and name', () {
      final cards = getAllCards();
      for (final c in cards) {
        expect(c.id.isNotEmpty, isTrue);
        expect(c.name.isNotEmpty, isTrue);
      }
    });

    test('No duplicate card IDs', () {
      final cards = getAllCards();
      final ids = cards.map((c) => c.id).toSet();
      expect(ids.length, equals(cards.length));
    });

    test('Cards grouped by owner returns results for all schools', () {
      for (final owner in CardOwner.values) {
        if (owner == CardOwner.neutral) continue;
        final cards = getCardsByOwner(owner);
        expect(cards.isNotEmpty, isTrue, reason: '$owner has no cards');
      }
    });

    test('Preset deck has exactly 30 cards', () {
      for (final owner in CardOwner.values) {
        if (owner == CardOwner.neutral) continue;
        final deck = getPresetDeck(owner);
        expect(deck.length, equals(30), reason: '$owner deck not 30 cards');
      }
    });
  });
}
