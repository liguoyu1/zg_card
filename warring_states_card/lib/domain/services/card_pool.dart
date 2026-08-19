import 'dart:math';

import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';

/// 卡牌池工具 — 自有卡牌、周试用卡牌、可用卡牌
/// ponytail: 移除开包功能，保留初始种子和卡组编排
class CardPool {
  CardPool._();

  static const int trialCardCount = 8;
  static const int starterCommon = 15;
  static const int starterRare = 5;

  /// 加载自有卡牌，空时自动种子初始化
  static Future<Set<String>> loadOwnedIds() async {
    final data = await SaveManager.loadPlayerData();
    if (data == null || data.unlockedCards.isEmpty) {
      await seedStarterCards();
      final seeded = await SaveManager.loadPlayerData();
      return Set<String>.from(seeded?.unlockedCards ?? []);
    }
    return Set<String>.from(data.unlockedCards);
  }

  /// 新玩家初始卡牌种子：15张随机普通 + 5张随机稀有
  static Future<void> seedStarterCards() async {
    var data = await SaveManager.loadPlayerData();
    data ??= PlayerData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Player',
      );
    if (data.unlockedCards.isNotEmpty) return;

    final allCards = CardDataProvider.getAllCards();
    final rng = Random(DateTime.now().millisecondsSinceEpoch);

    final common = allCards.where((c) => c.rarity == Rarity.common).toList()
      ..shuffle(rng);
    final commonIds = common.take(starterCommon).map((c) => c.id).toList();

    final rare = allCards.where((c) => c.rarity == Rarity.rare).toList()
      ..shuffle(rng);
    final rareIds = rare.take(starterRare).map((c) => c.id).toList();

    final newData = data.copyWith(
      unlockedCards: [...commonIds, ...rareIds],
    );
    await SaveManager.savePlayerData(newData);
  }

  /// 周试用卡牌
  static Future<Set<String>> getWeeklyTrials() async {
    final data = await SaveManager.loadPlayerData();
    if (data == null) return {};

    final ownedIds = Set<String>.from(data.unlockedCards);
    final allCards = CardDataProvider.getAllCards();

    return computeWeeklyTrials(allCards, ownedIds, data.id);
  }

  static Set<String> computeWeeklyTrials(
    List<Card> allCards,
    Set<String> ownedIds,
    String playerId,
  ) {
    final weekNumber = _currentWeekNumber();
    final rng = Random(weekNumber + playerId.hashCode);

    final unowned = allCards.where((c) => !ownedIds.contains(c.id)).toList()
      ..shuffle(rng);

    if (unowned.length <= trialCardCount) return unowned.map((c) => c.id).toSet();
    return unowned.take(trialCardCount).map((c) => c.id).toSet();
  }

  static int currentWeekNumber() => _currentWeekNumber();

  static List<Card> getUsableCards(
    List<Card> allCards,
    Set<String> ownedIds,
    Set<String> trialIds,
  ) {
    return allCards
        .where((c) => ownedIds.contains(c.id) || trialIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
  }

  static int _currentWeekNumber() {
    final epoch = DateTime(2024);
    return DateTime.now().difference(epoch).inDays ~/ 7;
  }
}
