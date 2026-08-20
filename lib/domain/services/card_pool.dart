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
    // 无卡即为新用户：无论 data 是否为 null，只要 unlockedCards 空就视为新手
    data ??= PlayerData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Player',
      );
    if (data.unlockedCards.isNotEmpty) return;

    final allCards = CardDataProvider.getAllCards();
    final rng = Random(DateTime.now().millisecondsSinceEpoch);

    // 新用户：随机一名各家基础英雄（已有初始英雄则沿用，保证卡牌与其配套）
    final heroId = data.unlockedHeroes.isNotEmpty
        ? data.unlockedHeroes.first
        : starterHeroPool[rng.nextInt(starterHeroPool.length)];

    // 初始卡牌：围绕该英雄的学派编排
    final hero = HeroDataProvider.getHeroById(heroId);
    final owner = hero != null
        ? CardOwner.values.firstWhere(
            (o) => o.name == hero.className,
            orElse: () => CardOwner.neutral)
        : null;

    // 按稀有度取卡：学派卡优先，不足用中立补足
    List<Card> _pick(Rarity rarity, int want) {
      final faction = allCards
          .where((c) => c.rarity == rarity && c.owner == owner)
          .toList();
      final neutral = allCards
          .where((c) => c.rarity == rarity && c.owner == CardOwner.neutral)
          .toList();
      // 学派卡全部纳入（不超过 want），不足由中立补
      if (faction.length >= want) {
        faction.shuffle(rng);
        return faction.take(want).toList();
      }
      final result = List<Card>.from(faction);
      final need = want - result.length;
      neutral.shuffle(rng);
      result.addAll(neutral.take(need));
      return result;
    }

    final commonIds = _pick(Rarity.common, starterCommon).map((c) => c.id).toList();
    final rareIds = _pick(Rarity.rare, starterRare).map((c) => c.id).toList();
    final epicIds = _pick(Rarity.epic, starterEpic).map((c) => c.id).toList();

    final newData = data.copyWith(
      unlockedCards: [...commonIds, ...rareIds, ...epicIds],
      unlockedHeroes: [heroId],
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
