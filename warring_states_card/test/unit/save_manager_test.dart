import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:warring_states_card/data/persistence/save_manager.dart';

/// Helper to run SaveManager tests in a temp directory to avoid side effects.
Future<T> withTempDir<T>(Future<T> Function(String dir) fn) async {
  final tempDir = Directory.systemTemp.createTempSync('save_test_');
  final originalWD = Directory.current;
  try {
    Directory.current = tempDir;
    await SaveManager.init();
    return await fn(tempDir.path);
  } finally {
    Directory.current = originalWD;
    tempDir.deleteSync(recursive: true);
  }
}

void main() {
  group('SaveManager - lifecycle', () {
    test('init creates saves directory', () async {
      await withTempDir((dir) async {
        final saveDir = Directory('$dir/saves');
        expect(await saveDir.exists(), isTrue);
      });
    });
  });

  group('SaveManager - PlayerData', () {
    test('loadPlayerData returns null when no data', () async {
      await withTempDir((_) async {
        final result = await SaveManager.loadPlayerData();
        expect(result, isNull);
      });
    });

    test('save then load roundtrips correctly', () async {
      await withTempDir((_) async {
        final data = PlayerData(
          id: 'test_001',
          name: 'TestPlayer',
          level: 5,
          exp: 100,
          gold: 500,
          gems: 50,
          rankScore: 1200,
          rank: 3,
          unlockedHeroes: ['H_B001', 'H_F001'],
          unlockedCards: ['B001', 'B002', 'F001'],
          totalMatches: 20,
          winCount: 10,
          firstRun: false,
        );
        await SaveManager.savePlayerData(data);
        final loaded = await SaveManager.loadPlayerData();
        expect(loaded, isNotNull);
        expect(loaded!.id, equals('test_001'));
        expect(loaded.name, equals('TestPlayer'));
        expect(loaded.level, equals(5));
        expect(loaded.exp, equals(100));
        expect(loaded.gold, equals(500));
        expect(loaded.gems, equals(50));
        expect(loaded.rankScore, equals(1200));
        expect(loaded.rank, equals(3));
        expect(loaded.totalMatches, equals(20));
        expect(loaded.winCount, equals(10));
        expect(loaded.firstRun, isFalse);
      });
    });

    test('savePlayerData overwrites previous data', () async {
      await withTempDir((_) async {
        await SaveManager.savePlayerData(PlayerData(id: '1', name: 'Old'));
        await SaveManager.savePlayerData(PlayerData(id: '1', name: 'New'));
        final loaded = await SaveManager.loadPlayerData();
        expect(loaded!.name, equals('New'));
      });
    });
  });

  group('SaveManager - Collection', () {
    test('loadCollection returns null when no data', () async {
      await withTempDir((_) async {
        final result = await SaveManager.loadCollection();
        expect(result, isNull);
      });
    });

    test('save then load roundtrips correctly', () async {
      await withTempDir((_) async {
        final collection = Collection(
          cards: {'B001': 2, 'F001': 1, 'N001': 3},
          cardCopies: {'B001': 5, 'F001': 2},
          favoriteCards: ['B001', 'N001'],
        );
        await SaveManager.saveCollection(collection);
        final loaded = await SaveManager.loadCollection();
        expect(loaded, isNotNull);
        expect(loaded!.cards['B001'], equals(2));
        expect(loaded.cards['F001'], equals(1));
        expect(loaded.cardCopies['B001'], equals(5));
        expect(loaded.favoriteCards, contains('B001'));
      });
    });
  });

  group('SaveManager - MatchHistory', () {
    test('loadMatchHistory returns empty list when no data', () async {
      await withTempDir((_) async {
        final result = await SaveManager.loadMatchHistory();
        expect(result, isEmpty);
      });
    });

    test('save then load roundtrips correctly', () async {
      await withTempDir((_) async {
        final records = [
          MatchRecord(
            id: 'm1', timestamp: DateTime(2024, 1, 1),
            playerId: 'p1', opponentId: 'p2',
            isWin: true, duration: 120,
            playerHero: 'H_B001', opponentHero: 'H_F001',
            playerRankScore: 1000, opponentRankScore: 1000,
          ),
          MatchRecord(
            id: 'm2', timestamp: DateTime(2024, 1, 2),
            playerId: 'p1', opponentId: 'ai',
            isWin: false, duration: 90,
            playerHero: 'H_B001', opponentHero: 'H_R001',
            playerRankScore: 980, opponentRankScore: 1000,
          ),
        ];
        await SaveManager.saveMatchHistory(records);
        final loaded = await SaveManager.loadMatchHistory();
        expect(loaded.length, equals(2));
        expect(loaded[0].id, equals('m1'));
        expect(loaded[0].isWin, isTrue);
        expect(loaded[1].id, equals('m2'));
        expect(loaded[1].isWin, isFalse);
      });
    });
  });

  group('SaveManager - export/import', () {
    test('exportSave returns valid JSON', () async {
      await withTempDir((_) async {
        await SaveManager.savePlayerData(PlayerData(id: '1', name: 'Test'));
        final jsonStr = await SaveManager.exportSave();
        final parsed = jsonDecode(jsonStr);
        expect(parsed['playerData'], isNotNull);
        expect(parsed['exportTime'], isNotNull);
      });
    });

    test('importSave restores data correctly', () async {
      await withTempDir((_) async {
        await SaveManager.savePlayerData(PlayerData(id: '1', name: 'Original'));
        const importJson = '''
        {
          "playerData": {"id": "new", "name": "Imported", "level": 10, "exp": 0, "gold": 100, "gems": 0, "rankScore": 1000, "rank": 1, "unlockedHeroes": ["H_B001"], "unlockedCards": [], "achievedMedals": [], "deckSlots": {"slot_1": 0}, "lastLogin": "2024-01-01T00:00:00.000", "totalMatches": 0, "winCount": 0, "firstRun": false},
          "collection": {"cards": {"N001": 1}, "cardCopies": {}, "favoriteCards": []},
          "matchHistory": []
        }
        ''';
        await SaveManager.importSave(importJson);
        final player = await SaveManager.loadPlayerData();
        expect(player!.id, equals('new'));
        expect(player.name, equals('Imported'));
        expect(player.level, equals(10));

        final collection = await SaveManager.loadCollection();
        expect(collection!.cards['N001'], equals(1));
      });
    });
  });

  group('SaveManager - clearAll', () {
    test('clearAll removes all data', () async {
      await withTempDir((_) async {
        await SaveManager.savePlayerData(PlayerData(id: '1', name: 'Test'));
        await SaveManager.clearAll();
        final player = await SaveManager.loadPlayerData();
        expect(player, isNull);
      });
    });
  });

  group('PlayerData model', () {
    test('default values are set correctly', () {
      final data = PlayerData(id: 'test', name: 'Test');
      expect(data.level, equals(1));
      expect(data.gold, equals(100));
      expect(data.rankScore, equals(1000));
      expect(data.firstRun, isTrue);
    });

    test('winRate is calculated correctly', () {
      final data = PlayerData(id: 'test', name: 'Test', totalMatches: 10, winCount: 7);
      expect(data.winRate, closeTo(0.7, 0.001));
    });

    test('winRate is zero when no matches', () {
      final data = PlayerData(id: 'test', name: 'Test');
      expect(data.winRate, equals(0));
    });

    test('copyWith preserves unchanged fields', () {
      final original = PlayerData(id: '1', name: 'Test', level: 5);
      final copy = original.copyWith(name: 'Updated');
      expect(copy.id, equals('1'));
      expect(copy.name, equals('Updated'));
      expect(copy.level, equals(5));
    });

    test('toJson/fromJson roundtrip', () {
      final original = PlayerData(
        id: '1', name: 'Test', level: 10, exp: 500, gold: 1000,
        gems: 200, rankScore: 1500, rank: 5,
        unlockedHeroes: ['H_B001', 'H_F001'],
        unlockedCards: ['B001', 'B002'],
        totalMatches: 30, winCount: 18, firstRun: false,
      );
      final json = original.toJson();
      final restored = PlayerData.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.level, equals(original.level));
      expect(restored.totalMatches, equals(original.totalMatches));
      expect(restored.winCount, equals(original.winCount));
    });
  });

  group('Collection model', () {
    test('default constructor uses empty maps', () {
      final c = Collection();
      expect(c.cards, isEmpty);
      expect(c.cardCopies, isEmpty);
      expect(c.favoriteCards, isEmpty);
    });

    test('toJson/fromJson roundtrip', () {
      final original = Collection(
        cards: {'B001': 2, 'F001': 1},
        cardCopies: {'B001': 5},
        favoriteCards: ['B001'],
      );
      final json = original.toJson();
      final restored = Collection.fromJson(json);
      expect(restored.cards['B001'], equals(2));
      expect(restored.cardCopies['B001'], equals(5));
      expect(restored.favoriteCards.first, equals('B001'));
    });
  });

  group('MatchRecord model', () {
    test('toJson/fromJson roundtrip', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final original = MatchRecord(
        id: 'match_001', timestamp: now,
        playerId: 'p1', opponentId: 'p2',
        isWin: true, duration: 180,
        playerHero: 'H_B001', opponentHero: 'H_F001',
        playerRankScore: 1050, opponentRankScore: 1000,
      );
      final json = original.toJson();
      final restored = MatchRecord.fromJson(json);
      expect(restored.id, equals('match_001'));
      expect(restored.isWin, isTrue);
      expect(restored.duration, equals(180));
      expect(restored.playerHero, equals('H_B001'));
      expect(restored.playerRankScore, equals(1050));
    });
  });
}
