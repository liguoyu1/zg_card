import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:warring_states_card/core/asset_style.dart';
import 'package:warring_states_card/data/data_version.dart';
import 'package:warring_states_card/domain/models/roguelite_run.dart';

/// 存档管理器 - 基于 SharedPreferences，每套图独立存档 key，并按登录账号隔离
class SaveManager {
  /// 本地玩家数据保存后的回调（用于余额变动后触发服务端对账同步）
  static void Function(PlayerData data)? onPlayerDataSaved;
  /// 本地卡牌收藏保存后的回调（触发完整存档云同步）
  static void Function(Collection c)? onCollectionSaved;

  /// 当前存档所属账号（未登录时为 null，使用无后缀 key 兼容旧版游客存档）
  static String? accountId;

  static String get _suffix => AssetStyle.current.name;
  static String get _keyPrefix => accountId == null ? '' : '${accountId}_';
  static String get _playerDataKey => 'save_player_data_$_keyPrefix$_suffix';
  static String get _collectionKey => 'save_collection_$_keyPrefix$_suffix';
  static String get _matchHistoryKey => 'save_match_history_$_keyPrefix$_suffix';
  static const String _saveVersionKey = 'save_version';
  static String get _saveTsKey => 'save_ts_$_keyPrefix$_suffix';

  static Future<void> init() async {}

  /// 切换到指定账号的本地存档区。仅当新 key 无存档、且旧版无账号后缀 key 中
  /// 的存档确实属于该账号（id 一致）时迁移，避免游客/他人存档串号。
  static Future<void> ensureAccountStorage(String playerId) async {
    if (accountId == playerId) return;
    accountId = playerId;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_playerDataKey) != null) return; // 该账号已有本地档
    final legacyKey = 'save_player_data_$_suffix';
    final legacy = prefs.getString(legacyKey);
    if (legacy == null) return;
    try {
      final pd = PlayerData.fromJson(jsonDecode(legacy));
      // 游客档（纯时间戳 id）视为同账号旧档一并迁移；其他账号档不迁移
      if (pd.id != playerId) return;  // 只迁移同账号旧档；游客档不再并入（防卡牌虚高）
      await savePlayerData(pd);
      final legacyColl = prefs.getString('save_collection_$_suffix');
      if (legacyColl != null && prefs.getString(_collectionKey) == null) {
        await saveCollection(Collection.fromJson(jsonDecode(legacyColl)));
      }
      final legacyHist = prefs.getString('save_match_history_$_suffix');
      if (legacyHist != null) {
        await saveMatchHistory((jsonDecode(legacyHist) as List)
            .map((j) => MatchRecord.fromJson(j))
            .toList());
      }
    } catch (_) {}
  }

  static Future<void> savePlayerData(PlayerData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerDataKey, jsonEncode(data.toJson()));
    await prefs.setInt(_saveTsKey, DateTime.now().millisecondsSinceEpoch);
    onPlayerDataSaved?.call(data);
    bumpDataVersion();
  }

  static Future<PlayerData?> loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_playerDataKey);
    if (str == null) return null;
    try { return PlayerData.fromJson(jsonDecode(str)); } catch (_) { return null; }
  }

  static Future<void> saveCollection(Collection c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionKey, jsonEncode(c.toJson()));
    await prefs.setInt(_saveTsKey, DateTime.now().millisecondsSinceEpoch);
    onCollectionSaved?.call(c);
    bumpDataVersion();
  }

  /// 本地存档最后修改时间戳（版本比较用）
  static Future<int> loadSavedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_saveTsKey) ?? 0;
  }

  static Future<Collection?> loadCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_collectionKey);
    if (str == null) return null;
    try { return Collection.fromJson(jsonDecode(str)); } catch (_) { return null; }
  }

  static Future<void> saveMatchHistory(List<MatchRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchHistoryKey, jsonEncode(records.map((r) => r.toJson()).toList()));
    bumpDataVersion();
  }

  static Future<List<MatchRecord>> loadMatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_matchHistoryKey);
    if (str == null) return [];
    try { return (jsonDecode(str) as List).map((j) => MatchRecord.fromJson(j)).toList(); } catch (_) { return []; }
  }

  static Future<void> addMatchRecord(MatchRecord record) async {
    final history = await loadMatchHistory();
    history.add(record);
    if (history.length > 500) history.removeRange(0, history.length - 500);
    await saveMatchHistory(history);
  }

  /// 用户操作明细（事件流）：只增不改、仅存本地，与云同步的状态资产分开保存。
  /// 状态（余额/卡/英雄）= 明细的总结，可通过 addEvent 追溯
  static const String _eventsKey = 'local_events';

  static Future<List<Map<String, dynamic>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_eventsKey);
    if (str == null) return [];
    try {
      return (jsonDecode(str) as List)
          .map((j) => Map<String, dynamic>.from(j as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 追加一条用户操作明细（购买/兑换/抽卡等），失败不影响主要流程
  static Future<void> addEvent(Map<String, dynamic> ev) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await loadEvents();
      events.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'at': DateTime.now().toIso8601String(),
        ...ev,
      });
      // 仅保留最近 500 条防御性上限
      if (events.length > 500) events.removeRange(0, events.length - 500);
      await prefs.setString(_eventsKey, jsonEncode(events));
    } catch (_) {}
  }

  static const String _xsollaPendingKey = 'xsolla_pending';
  static const String _xsollaPreGemsKey = 'xsolla_pre_gems';
  static const String _xsollaPendingAtKey = 'xsolla_pending_at';

  /// 记录支付发起时间戳（跳回后按订单查询服务端是否已入账）
  static Future<void> markXsollaPendingAt(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xsollaPendingAtKey, ms);
  }

  /// 读取并清除支付发起时间戳
  static Future<int?> consumeXsollaPendingAt() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_xsollaPendingAtKey);
    if (v != null) await prefs.remove(_xsollaPendingAtKey);
    return v;
  }

  /// 记录支付发起前的钻石数（跳回后以服务端到账为准判定弹窗结果）
  static Future<void> markXsollaPreGems(int gems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xsollaPreGemsKey, gems);
  }

  /// 读取并清除支付前钻石数
  static Future<int?> consumeXsollaPreGems() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_xsollaPreGemsKey);
    if (v != null) await prefs.remove(_xsollaPreGemsKey);
    return v;
  }

  /// 标记/清除 Xsolla 支付进行中（跳回后用于返回商店页的兜底）
  static Future<void> markXsollaPending(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    if (v) {
      await prefs.setBool(_xsollaPendingKey, true);
    } else {
      await prefs.remove(_xsollaPendingKey);
    }
  }

  /// 读取并清除 Xsolla 支付进行中标记
  static Future<bool> consumeXsollaPending() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_xsollaPendingKey) ?? false;
    if (v) await prefs.remove(_xsollaPendingKey);
    return v;
  }

  /// 资产存档导出（PlayerData + Collection）——对局记录只存本地，不进云端
  static Future<String> exportSave() async => jsonEncode({
    'playerData': (await loadPlayerData())?.toJson(),
    'collection': (await loadCollection())?.toJson(),
    'exportTime': DateTime.now().toIso8601String(),
  });

  static Future<void> importSave(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data['playerData'] != null) await savePlayerData(PlayerData.fromJson(data['playerData']));
    if (data['collection'] != null) await saveCollection(Collection.fromJson(data['collection']));
    // 对局记录仅本地，不随云端资产导入/覆盖
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerDataKey);
    await prefs.remove(_collectionKey);
    await prefs.remove(_matchHistoryKey);
    await prefs.remove(_saveVersionKey);
    bumpDataVersion();
  }

  // Roguelite 存读（也按风格隔离）
  static Future<void> saveRogueliteRun(RogueliteRun run) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('save_roguelite_run_$_suffix', jsonEncode(run.toJson()));
  }

  static Future<RogueliteRun?> loadRogueliteRun() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('save_roguelite_run_$_suffix');
    if (str == null) return null;
    try { return rogueliteRunFromJson(jsonDecode(str)); } catch (_) { return null; }
  }

  static Future<void> clearRogueliteRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('save_roguelite_run_$_suffix');
  }
}

// ─── 数据模型（原在此文件中定义，继续保留） ───

/// 玩家数据
class PlayerData {

  PlayerData({
    required this.id, required this.name,
    this.level = 1, this.exp = 0, this.gold = 100, this.gems = 0,
    this.rankScore = 1000, this.rank = 1,
    this.unlockedHeroes = const ['H_B001'], this.unlockedCards = const [],
    this.achievedMedals = const [], this.deckSlots = const {'slot_1': 0},
    DateTime? lastLogin, this.totalMatches = 0, this.winCount = 0,
    this.firstRun = true, this.stats = const {}, this.lastTrialWeek = 0,
    this.starterSeeded = false,
  }) : lastLogin = lastLogin ?? DateTime.now();

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
    id: json['id'], name: json['name'], level: json['level'] ?? 1,
    exp: json['exp'] ?? 0, gold: json['gold'] ?? 100, gems: json['gems'] ?? 0,
    rankScore: json['rankScore'] ?? 1000, rank: json['rank'] ?? 1,
    unlockedHeroes: List<String>.from(json['unlockedHeroes'] ?? ['H_B001']),
    unlockedCards: List<String>.from(json['unlockedCards'] ?? []),
    achievedMedals: List<String>.from(json['achievedMedals'] ?? []),
    deckSlots: json['deckSlots'] != null ? Map<String, int>.from(json['deckSlots']) : {'slot_1': 0},
    lastLogin: DateTime.parse(json['lastLogin']),
    totalMatches: json['totalMatches'] ?? 0, winCount: json['winCount'] ?? 0,
    firstRun: json['firstRun'] ?? true,
    stats: json['stats'] != null ? Map<String, int>.from(json['stats']) : {},
    lastTrialWeek: json['lastTrialWeek'] ?? 0,
    starterSeeded: json['starterSeeded'] ?? false,
  );
  final String id;
  final String name;
  final int level;
  final int exp;
  final int gold;
  final int gems;
  final int rankScore;
  final int rank;
  final List<String> unlockedHeroes;
  final List<String> unlockedCards;
  final List<String> achievedMedals;
  final Map<String, int> deckSlots;
  final DateTime lastLogin;
  final int totalMatches;
  final int winCount;
  final bool firstRun;
  final Map<String, int> stats;
  final int lastTrialWeek;
  final bool starterSeeded;

  double get winRate => totalMatches > 0 ? winCount / totalMatches : 0;

  PlayerData copyWith({
    String? id, String? name, int? level, int? exp, int? gold, int? gems,
    int? rankScore, int? rank, List<String>? unlockedHeroes, List<String>? unlockedCards,
    List<String>? achievedMedals, Map<String, int>? deckSlots, DateTime? lastLogin,
    int? totalMatches, int? winCount, bool? firstRun, Map<String, int>? stats, int? lastTrialWeek,
    bool? starterSeeded,
  }) => PlayerData(
    id: id ?? this.id, name: name ?? this.name, level: level ?? this.level,
    exp: exp ?? this.exp, gold: gold ?? this.gold, gems: gems ?? this.gems,
    rankScore: rankScore ?? this.rankScore, rank: rank ?? this.rank,
    unlockedHeroes: unlockedHeroes ?? this.unlockedHeroes,
    unlockedCards: unlockedCards ?? this.unlockedCards,
    achievedMedals: achievedMedals ?? this.achievedMedals,
    deckSlots: deckSlots ?? this.deckSlots, lastLogin: lastLogin ?? this.lastLogin,
    totalMatches: totalMatches ?? this.totalMatches, winCount: winCount ?? this.winCount,
    firstRun: firstRun ?? this.firstRun, stats: stats ?? this.stats,
    lastTrialWeek: lastTrialWeek ?? this.lastTrialWeek,
    starterSeeded: starterSeeded ?? this.starterSeeded,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'level': level, 'exp': exp, 'gold': gold, 'gems': gems,
    'rankScore': rankScore, 'rank': rank, 'unlockedHeroes': unlockedHeroes,
    'unlockedCards': unlockedCards, 'achievedMedals': achievedMedals,
    'deckSlots': deckSlots, 'lastLogin': lastLogin.toIso8601String(),
    'totalMatches': totalMatches, 'winCount': winCount, 'firstRun': firstRun,
    'stats': stats, 'lastTrialWeek': lastTrialWeek,
    'starterSeeded': starterSeeded,
  };
}

/// 收藏数据
class Collection {
  Collection({this.cards = const {}, this.cardCopies = const {}, this.favoriteCards = const []});
  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    cards: Map<String, int>.from(json['cards'] ?? {}),
    cardCopies: Map<String, int>.from(json['cardCopies'] ?? {}),
    favoriteCards: List<String>.from(json['favoriteCards'] ?? []),
  );
  final Map<String, int> cards;
  final Map<String, int> cardCopies;
  final List<String> favoriteCards;
  int get totalCards => cards.length;
  Map<String, dynamic> toJson() => {'cards': cards, 'cardCopies': cardCopies, 'favoriteCards': favoriteCards};
  Collection copyWith({Map<String, int>? cards, Map<String, int>? cardCopies, List<String>? favoriteCards}) =>
    Collection(cards: cards ?? this.cards, cardCopies: cardCopies ?? this.cardCopies, favoriteCards: favoriteCards ?? this.favoriteCards);
}

/// 对战记录
class MatchRecord {
  MatchRecord({
    required this.id, required this.timestamp, required this.playerId, required this.opponentId,
    required this.isWin, required this.duration, required this.playerHero, required this.opponentHero,
    required this.playerRankScore, required this.opponentRankScore,
  });
  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
    id: json['id'], timestamp: DateTime.parse(json['timestamp']), playerId: json['playerId'],
    opponentId: json['opponentId'], isWin: json['isWin'], duration: json['duration'],
    playerHero: json['playerHero'], opponentHero: json['opponentHero'],
    playerRankScore: json['playerRankScore'], opponentRankScore: json['opponentRankScore'],
  );
  final String id; final DateTime timestamp; final String playerId; final String opponentId;
  final bool isWin; final int duration; final String playerHero; final String opponentHero;
  final int playerRankScore; final int opponentRankScore;
  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': timestamp.toIso8601String(), 'playerId': playerId,
    'opponentId': opponentId, 'isWin': isWin, 'duration': duration,
    'playerHero': playerHero, 'opponentHero': opponentHero,
    'playerRankScore': playerRankScore, 'opponentRankScore': opponentRankScore,
  };
}
