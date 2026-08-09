import '../../data/persistence/save_manager.dart';

/// 资产状态合并规则（纯函数，无 IO/网络）：
/// - 卡/英雄/勋章/收藏为累积型资产：并集，只增不减
/// - 数值/统计（余额/等级/局数/段位/槽位）取两者较大值
/// - 多端冲突时任何一端都不丢失已获得资产

PlayerData mergePlayerData(PlayerData local, PlayerData remote) {
  return local.copyWith(
    name: local.name,
    level: _max(local.level, remote.level),
    exp: _max(local.exp, remote.exp),
    gold: _max(local.gold, remote.gold),
    gems: _max(local.gems, remote.gems),
    rankScore: _max(local.rankScore, remote.rankScore),
    rank: _max(local.rank, remote.rank),
    unlockedHeroes: _union(local.unlockedHeroes, remote.unlockedHeroes),
    unlockedCards: _union(local.unlockedCards, remote.unlockedCards),
    achievedMedals: _union(local.achievedMedals, remote.achievedMedals),
    deckSlots: _mergeMaxMap(local.deckSlots, remote.deckSlots),
    totalMatches: _max(local.totalMatches, remote.totalMatches),
    winCount: _max(local.winCount, remote.winCount),
    stats: _mergeMaxMap(local.stats, remote.stats),
    lastTrialWeek: _max(local.lastTrialWeek, remote.lastTrialWeek),
  );
}

Collection mergeCollection(Collection? local, Collection? remote) {
  if (local == null) return remote ?? Collection();
  if (remote == null) return local;
  return Collection(
    cards: _mergeMaxMap(local.cards, remote.cards),
    cardCopies: _mergeMaxMap(local.cardCopies, remote.cardCopies),
    favoriteCards: _union(local.favoriteCards, remote.favoriteCards),
  );
}

/// 无资产判定：无卡、无收藏、仅初始英雄
bool isEmptySave(PlayerData pd, Collection? coll) =>
    pd.unlockedCards.isEmpty &&
    pd.unlockedHeroes.length <= 1 &&
    (coll == null || coll.cards.isEmpty);

/// 默认（初始）档判定：未开局、无余额积累、无卡
bool isDefaultSave(PlayerData d) =>
    d.firstRun ||
    (d.gems == 0 &&
        d.gold <= 100 &&
        d.unlockedCards.isEmpty &&
        d.unlockedHeroes.length <= 1);

int _max(int a, int b) => a > b ? a : b;

List<String> _union(List<String> a, List<String> b) => {...a, ...b}.toList();

Map<String, int> _mergeMaxMap(Map<String, int> a, Map<String, int> b) {
  final out = Map<String, int>.from(a);
  b.forEach((k, v) {
    final cur = out[k];
    if (cur == null || v > cur) out[k] = v;
  });
  return out;
}
