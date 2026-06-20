import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/elo_system.dart';

/// 存档管理器
class SaveManager {
  static String _saveDir = '';
  static const String _playerDataFile = 'player_data.json';
  static const String _collectionFile = 'collection.json';
  static const String _matchHistoryFile = 'match_history.json';

  /// 初始化存档目录
  static Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _saveDir = '${appDir.path}/saves';
      final dir = Directory(_saveDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (_) {
      // Web: dart:io 和 path_provider 不支持，所有读写静默失败
      _saveDir = '';
    }
  }

  /// 保存玩家数据
  static Future<void> savePlayerData(PlayerData data) async {
    if (_saveDir.isEmpty) return;
    try {
      final file = File('$_saveDir/$_playerDataFile');
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// 加载玩家数据
  static Future<PlayerData?> loadPlayerData() async {
    if (_saveDir.isEmpty) return null;
    try {
      final file = File('$_saveDir/$_playerDataFile');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return PlayerData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 保存收藏
  static Future<void> saveCollection(Collection collection) async {
    if (_saveDir.isEmpty) return;
    try {
      final file = File('$_saveDir/$_collectionFile');
      await file.writeAsString(jsonEncode(collection.toJson()));
    } catch (_) {}
  }

  /// 加载收藏
  static Future<Collection?> loadCollection() async {
    if (_saveDir.isEmpty) return null;
    try {
      final file = File('$_saveDir/$_collectionFile');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return Collection.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 保存对战历史
  static Future<void> saveMatchHistory(List<MatchRecord> records) async {
    if (_saveDir.isEmpty) return;
    try {
      final file = File('$_saveDir/$_matchHistoryFile');
      await file.writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  /// 加载对战历史
  static Future<List<MatchRecord>> loadMatchHistory() async {
    if (_saveDir.isEmpty) return [];
    try {
      final file = File('$_saveDir/$_matchHistoryFile');
      if (!await file.exists()) return [];
      final List<dynamic> json = jsonDecode(await file.readAsString());
      return json.map((j) => MatchRecord.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 导出存档JSON
  static Future<String> exportSave() async {
    final data = {
      'playerData': (await loadPlayerData())?.toJson(),
      'collection': (await loadCollection())?.toJson(),
      'matchHistory': (await loadMatchHistory()).map((r) => r.toJson()).toList(),
      'exportTime': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// 导入存档
  static Future<void> importSave(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data['playerData'] != null) {
      await savePlayerData(PlayerData.fromJson(data['playerData']));
    }
    if (data['collection'] != null) {
      await saveCollection(Collection.fromJson(data['collection']));
    }
    if (data['matchHistory'] != null) {
      await saveMatchHistory(
        (data['matchHistory'] as List).map((j) => MatchRecord.fromJson(j)).toList(),
      );
    }
  }

  /// 删除所有存档
  static Future<void> clearAll() async {
    if (_saveDir.isEmpty) return;
    try {
      final dir = Directory(_saveDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    await init();
  }
}

/// 玩家数据
class PlayerData {
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

  PlayerData({
    required this.id,
    required this.name,
    this.level = 1,
    this.exp = 0,
    this.gold = 100,
    this.gems = 0,
    this.rankScore = 1000,
    this.rank = 1,
    this.unlockedHeroes = const ['H_B001'],
    this.unlockedCards = const [],
    this.achievedMedals = const [],
    this.deckSlots = const {'slot_1': 0},
    DateTime? lastLogin,
    this.totalMatches = 0,
    this.winCount = 0,
    this.firstRun = true,
  }) : lastLogin = lastLogin ?? DateTime.now();

  double get winRate => totalMatches > 0 ? winCount / totalMatches : 0;

  PlayerData copyWith({
    String? id,
    String? name,
    int? level,
    int? exp,
    int? gold,
    int? gems,
    int? rankScore,
    int? rank,
    List<String>? unlockedHeroes,
    List<String>? unlockedCards,
    List<String>? achievedMedals,
    Map<String, int>? deckSlots,
    DateTime? lastLogin,
    int? totalMatches,
    int? winCount,
    bool? firstRun,
  }) {
    return PlayerData(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      rankScore: rankScore ?? this.rankScore,
      rank: rank ?? this.rank,
      unlockedHeroes: unlockedHeroes ?? this.unlockedHeroes,
      unlockedCards: unlockedCards ?? this.unlockedCards,
      achievedMedals: achievedMedals ?? this.achievedMedals,
      deckSlots: deckSlots ?? this.deckSlots,
      lastLogin: lastLogin ?? this.lastLogin,
      totalMatches: totalMatches ?? this.totalMatches,
      winCount: winCount ?? this.winCount,
      firstRun: firstRun ?? this.firstRun,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'exp': exp,
    'gold': gold,
    'gems': gems,
    'rankScore': rankScore,
    'rank': rank,
    'unlockedHeroes': unlockedHeroes,
    'unlockedCards': unlockedCards,
    'achievedMedals': achievedMedals,
    'deckSlots': deckSlots,
    'lastLogin': lastLogin.toIso8601String(),
    'totalMatches': totalMatches,
    'winCount': winCount,
    'firstRun': firstRun,
  };

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
    id: json['id'],
    name: json['name'],
    level: json['level'] ?? 1,
    exp: json['exp'] ?? 0,
    gold: json['gold'] ?? 100,
    gems: json['gems'] ?? 0,
    rankScore: json['rankScore'] ?? 1000,
    rank: json['rank'] ?? 1,
    unlockedHeroes: List<String>.from(json['unlockedHeroes'] ?? ['H_B001']),
    unlockedCards: List<String>.from(json['unlockedCards'] ?? []),
    achievedMedals: List<String>.from(json['achievedMedals'] ?? []),
    deckSlots: Map<String, int>.from(json['deckSlots'] ?? {}),
    lastLogin: DateTime.parse(json['lastLogin']),
    totalMatches: json['totalMatches'] ?? 0,
    winCount: json['winCount'] ?? 0,
    firstRun: json['firstRun'] ?? true,
  );
}

/// 收藏数据
class Collection {
  final Map<String, int> cards; // cardId -> count
  final Map<String, int> cardCopies; // cardId -> 拥有复制数
  final List<String> favoriteCards;

  Collection({
    this.cards = const {},
    this.cardCopies = const {},
    this.favoriteCards = const [],
  });

  Map<String, dynamic> toJson() => {
    'cards': cards,
    'cardCopies': cardCopies,
    'favoriteCards': favoriteCards,
  };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    cards: Map<String, int>.from(json['cards'] ?? {}),
    cardCopies: Map<String, int>.from(json['cardCopies'] ?? {}),
    favoriteCards: List<String>.from(json['favoriteCards'] ?? []),
  );

  Collection copyWith({
    Map<String, int>? cards,
    Map<String, int>? cardCopies,
    List<String>? favoriteCards,
  }) {
    return Collection(
      cards: cards ?? this.cards,
      cardCopies: cardCopies ?? this.cardCopies,
      favoriteCards: favoriteCards ?? this.favoriteCards,
    );
  }
}

/// 对战记录
class MatchRecord {
  final String id;
  final DateTime timestamp;
  final String playerId;
  final String opponentId;
  final bool isWin;
  final int duration; // 秒
  final String playerHero;
  final String opponentHero;
  final int playerRankScore;
  final int opponentRankScore;

  MatchRecord({
    required this.id,
    required this.timestamp,
    required this.playerId,
    required this.opponentId,
    required this.isWin,
    required this.duration,
    required this.playerHero,
    required this.opponentHero,
    required this.playerRankScore,
    required this.opponentRankScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
    'opponentId': opponentId,
    'isWin': isWin,
    'duration': duration,
    'playerHero': playerHero,
    'opponentHero': opponentHero,
    'playerRankScore': playerRankScore,
    'opponentRankScore': opponentRankScore,
  };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    playerId: json['playerId'],
    opponentId: json['opponentId'],
    isWin: json['isWin'],
    duration: json['duration'],
    playerHero: json['playerHero'],
    opponentHero: json['opponentHero'],
    playerRankScore: json['playerRankScore'],
    opponentRankScore: json['opponentRankScore'],
  );
}