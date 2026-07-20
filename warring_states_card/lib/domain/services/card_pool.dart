import 'dart:math';

import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';

/// 卡牌池工具 — 自有卡牌、周试用卡牌、可用卡牌
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

  /// 新玩家初始卡牌种子：15张随机普通 + 5张随机稀有（无史诗/传说）
  static Future<void> seedStarterCards() async {
    var data = await SaveManager.loadPlayerData();
    data ??= PlayerData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Player',
      );
    if (data.unlockedCards.isNotEmpty) return; // 已初始化

    final allCards = CardDataProvider.getAllCards();
    final rng = Random(DateTime.now().millisecondsSinceEpoch);

    // 15张随机普通
    final common = allCards.where((c) => c.rarity == Rarity.common).toList()
      ..shuffle(rng);
    final commonIds = common.take(starterCommon).map((c) => c.id).toList();

    // 5张随机稀有（无史诗/传说）
    final rare = allCards.where((c) => c.rarity == Rarity.rare).toList()
      ..shuffle(rng);
    final rareIds = rare.take(starterRare).map((c) => c.id).toList();

    final newData = data.copyWith(
      unlockedCards: [...commonIds, ...rareIds],
    );
    await SaveManager.savePlayerData(newData);
  }

  /// 周试用卡牌：取未拥有的卡牌中8张，每周一重置
  static Future<Set<String>> getWeeklyTrials() async {
    final data = await SaveManager.loadPlayerData();
    if (data == null) return {};

    final ownedIds = Set<String>.from(data.unlockedCards);
    final allCards = CardDataProvider.getAllCards();

    return computeWeeklyTrials(allCards, ownedIds, data.id);
  }

  /// 计算周试用卡牌（确定性种子：周号 + 玩家ID，每人每固定8张）
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

  /// 当前周号
  static int currentWeekNumber() => _currentWeekNumber();

  /// 可用卡牌 = 自有 ∪ 试用
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
