import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:warring_states_card/core/asset_style.dart';
import 'package:warring_states_card/domain/models/roguelite_run.dart';

/// 存档管理器 - 基于 SharedPreferences，每套图独立存档 key
class SaveManager {
  static String get _suffix => AssetStyle.current.name;
  static String get _playerDataKey => 'save_player_data_$_suffix';
  static String get _collectionKey => 'save_collection_$_suffix';
  static String get _matchHistoryKey => 'save_match_history_$_suffix';
  static const String _saveVersionKey = 'save_version';

  static Future<void> init() async {}

  static Future<void> savePlayerData(PlayerData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerDataKey, jsonEncode(data.toJson()));
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

  static Future<String> exportSave() async => jsonEncode({
    'playerData': (await loadPlayerData())?.toJson(),
    'collection': (await loadCollection())?.toJson(),
    'matchHistory': (await loadMatchHistory()).map((r) => r.toJson()).toList(),
    'exportTime': DateTime.now().toIso8601String(),
  });

  static Future<void> importSave(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data['playerData'] != null) await savePlayerData(PlayerData.fromJson(data['playerData']));
    if (data['collection'] != null) await saveCollection(Collection.fromJson(data['collection']));
    if (data['matchHistory'] != null) {
      await saveMatchHistory((data['matchHistory'] as List).map((j) => MatchRecord.fromJson(j)).toList());
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerDataKey);
    await prefs.remove(_collectionKey);
    await prefs.remove(_matchHistoryKey);
    await prefs.remove(_saveVersionKey);
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

  double get winRate => totalMatches > 0 ? winCount / totalMatches : 0;

  PlayerData copyWith({
    String? id, String? name, int? level, int? exp, int? gold, int? gems,
    int? rankScore, int? rank, List<String>? unlockedHeroes, List<String>? unlockedCards,
    List<String>? achievedMedals, Map<String, int>? deckSlots, DateTime? lastLogin,
    int? totalMatches, int? winCount, bool? firstRun, Map<String, int>? stats, int? lastTrialWeek,
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
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'level': level, 'exp': exp, 'gold': gold, 'gems': gems,
    'rankScore': rankScore, 'rank': rank, 'unlockedHeroes': unlockedHeroes,
    'unlockedCards': unlockedCards, 'achievedMedals': achievedMedals,
    'deckSlots': deckSlots, 'lastLogin': lastLogin.toIso8601String(),
    'totalMatches': totalMatches, 'winCount': winCount, 'firstRun': firstRun,
    'stats': stats, 'lastTrialWeek': lastTrialWeek,
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