import 'dart:math';

import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/card_data_provider.dart';
import 'package:warring_states_card/domain/services/hero_data_provider.dart';

/// 卡牌池工具 — 自有卡牌、周试用卡牌、可用卡牌
/// ponytail: 移除开包功能，保留初始种子和卡组编排
class CardPool {
  CardPool._();

  static const int trialCardCount = 8;
  // 新玩家初始卡牌 20 张：普通14 + 稀有4 + 史诗2（覆盖低中高稀有度，史诗体验高级卡）
  static const int starterCommon = 14;
  static const int starterRare = 4;
  static const int starterEpic = 2;

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

  /// 新玩家初始卡牌种子：14张随机普通 + 4张随机稀有 + 2张随机史诗
  /// 新用户初始英雄池：各家最基础的英雄（每学派 001 号）
  static const List<String> starterHeroPool = [
    'H_B001', // 兵家·孙膑
    'H_F001', // 法家·商鞅
    'H_R001', // 儒家·孔子
    'H_D001', // 道家·老子
    'H_M001', // 墨家·墨子
    'H_Y001', // 阴阳家·邹衍
    'H_Z001', // 纵横家·苏秦
  ];

  static Future<void> seedStarterCards() async {
    var data = await SaveManager.loadPlayerData();
    final isNew = data == null;
    data ??= PlayerData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Player',
      );
    if (data.unlockedCards.isNotEmpty) return;

    final allCards = CardDataProvider.getAllCards();
    final rng = Random(DateTime.now().millisecondsSinceEpoch);

    // 新用户：随机一名各家基础英雄
    final starterHero = isNew
        ? starterHeroPool[rng.nextInt(starterHeroPool.length)]
        : null;

    // 初始卡牌：围绕该英雄的学派编排（学派卡 + 中立卡混合），
    // 而非全卡池任意随机，保证新手套牌与所选英雄风格一致。
    final hero = starterHero != null
        ? HeroDataProvider.getHeroById(starterHero)
        : null;
    final factionCards = hero != null
        ? allCards
            .where((c) =>
                c.owner.name == hero.className || c.owner == CardOwner.neutral)
            .toList()
        : allCards;

    final common = factionCards
        .where((c) => c.rarity == Rarity.common)
        .toList()
      ..shuffle(rng);
    final commonIds = common.take(starterCommon).map((c) => c.id).toList();

    final rare = factionCards
        .where((c) => c.rarity == Rarity.rare)
        .toList()
      ..shuffle(rng);
    final rareIds = rare.take(starterRare).map((c) => c.id).toList();

    final epic = factionCards
        .where((c) => c.rarity == Rarity.epic)
        .toList()
      ..shuffle(rng);
    final epicIds = epic.take(starterEpic).map((c) => c.id).toList();

    final newData = data.copyWith(
      unlockedCards: [...commonIds, ...rareIds, ...epicIds],
      unlockedHeroes: starterHero != null ? [starterHero] : data.unlockedHeroes,
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
