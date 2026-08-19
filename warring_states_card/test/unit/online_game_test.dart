import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warring_states_card/data/online_game_service.dart';

/// Build a service backed by a MockClient with a JSON responder function.
/// [responder] maps (path, method) -> (statusCode, body). A thrown error
/// simulates a network failure (the service catches it and degrades).
OnlineGameService serviceWith(Future<http.Response> Function(http.Request) responder) =>
    OnlineGameService(client: MockClient((request) async {
      try {
        return await responder(request);
      } catch (e) {
        // Simulate a network-level failure (socket error etc.).
        throw http.ClientException('network error', request.url);
      }
    }));

/// Helper to JSON-encode a body and build a 200 response.
http.Response json200(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

void main() {
  group('OnlineGameService - guestLogin', () {
    test('returns true when token returned', () async {
      final service = serviceWith((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/auth/guest');
        return json200({'token': 'abc', 'player': {'id': 'od_001'}});
      });
      expect(await service.guestLogin('testPlayer'), isTrue);
    });

    test('returns false when no token', () async {
      final service = serviceWith((req) async => json200({'ok': true}));
      expect(await service.guestLogin('testPlayer'), isFalse);
    });

    test('returns false on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.guestLogin('testPlayer'), isFalse);
    });

    test('returns false on HTTP error status', () async {
      final service = serviceWith((_) async => http.Response('oops', 500));
      expect(await service.guestLogin('testPlayer'), isFalse);
    });
  });

  group('OnlineGameService - getPlayerProfile', () {
    test('returns profile on success', () async {
      final service = serviceWith((req) async {
        expect(req.url.path, '/api/player/od_001');
        return json200({'odID': 'od_001', 'odName': 'Test', 'rating': 1200,
          'rank': 'silver', 'totalMatches': 10, 'winCount': 5, 'winRate': 0.5});
      });
      final p = await service.getPlayerProfile('od_001');
      expect(p, isNotNull);
      expect(p!.odName, 'Test');
      expect(p.rating, 1200);
    });

    test('returns null on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.getPlayerProfile('od_001'), isNull);
    });
  });

  group('OnlineGameService - joinMatchQueue', () {
    test('returns true when queued', () async {
      final service = serviceWith((req) async {
        expect(req.url.path, '/api/match/join');
        return json200({'status': 'queued'});
      });
      expect(await service.joinMatchQueue(
        odID: 'od_001', odName: 'Test', odHeroId: 'H_B001', rating: 1000), isTrue);
    });

    test('returns false when not queued', () async {
      final service = serviceWith((_) async => json200({'status': 'waiting'}));
      expect(await service.joinMatchQueue(
        odID: 'od_001', odName: 'Test', odHeroId: 'H_B001', rating: 1000), isFalse);
    });

    test('returns false on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.joinMatchQueue(
        odID: 'od_001', odName: 'Test', odHeroId: 'H_B001', rating: 1000), isFalse);
    });
  });

  group('OnlineGameService - checkMatchStatus', () {
    test('returns MatchResult when matched', () async {
      final service = serviceWith((req) async {
        expect(req.url.path, '/api/match/check');
        return json200({'matched': true, 'roomId': 'room1',
          'opponent': {'odID': 'p2', 'odName': 'Rival', 'odHeroId': 'H_F001'}});
      });
      final r = await service.checkMatchStatus(odID: 'od_001', odHeroId: 'H_B001', rating: 1000);
      expect(r, isNotNull);
      expect(r!.matchId, 'room1');
      expect(r.opponentId, 'p2');
      expect(r.opponentHeroId, 'H_F001');
    });

    test('returns null when not matched', () async {
      final service = serviceWith((_) async => json200({'matched': false}));
      expect(await service.checkMatchStatus(odID: 'od_001', odHeroId: 'H_B001', rating: 1000), isNull);
    });

    test('returns null on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.checkMatchStatus(odID: 'od_001', odHeroId: 'H_B001', rating: 1000), isNull);
    });
  });

  group('OnlineGameService - getLeaderboard', () {
    test('returns entries on success', () async {
      final service = serviceWith((req) async {
        expect(req.url.path, '/api/leaderboard');
        return json200([
          {'rank': 1, 'odID': 'od_001', 'odName': 'Top', 'rating': 2000, 'rankName': 'legend'}
        ]);
      });
      final list = await service.getLeaderboard();
      expect(list, isNotEmpty);
      expect(list.first.odName, 'Top');
    });

    test('returns empty list on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.getLeaderboard(), isEmpty);
    });
  });

  group('OnlineGameService - getPlayerRank', () {
    test('returns rank on success', () async {
      final service = serviceWith((_) async => json200({'odID': 'od_001', 'rank': 42}));
      expect(await service.getPlayerRank('od_001'), 42);
    });

    test('returns -1 on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.getPlayerRank('od_001'), -1);
    });
  });

  group('OnlineGameService - submitAction / pollActions / updateStats', () {
    test('submitAction returns seq and increments', () async {
      final service = serviceWith((req) async {
        expect(req.url.path, '/api/game/submit-action');
        return json200({'ok': true});
      });
      expect(await service.submitAction('m1', 'od_001', 'play_card', data: {'cardId': 'B001'}), 0);
      expect(await service.submitAction('m1', 'od_001', 'end_turn'), 1);
    });

    test('submitAction returns null on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      expect(await service.submitAction('m1', 'od_001', 'play_card'), isNull);
    });

    test('pollActions returns actions on success', () async {
      final service = serviceWith((_) async => json200({'actions': [{'type': 'x'}], 'room': null}));
      final r = await service.pollActions('m1', after: 0);
      expect(r['actions'], isNotEmpty);
    });

    test('pollActions degrades on network error', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      final r = await service.pollActions('m1');
      expect(r['actions'], isEmpty);
    });

    test('updateStats completes without error on network failure', () async {
      final service = serviceWith((_) async => throw Exception('socket'));
      await service.updateStats(odID: 'od_001', won: true, opponentRating: 1000);
    });
  });

  group('MatchResult', () {
    test('creates with required fields', () {
      final result = MatchResult(matchId: 'm1', opponentId: 'p2', opponentName: 'Player2');
      expect(result.matchId, equals('m1'));
      expect(result.opponentId, equals('p2'));
      expect(result.opponentName, equals('Player2'));
    });

    test('allows null opponent fields', () {
      final result = MatchResult(matchId: 'm1');
      expect(result.matchId, equals('m1'));
      expect(result.opponentId, isNull);
      expect(result.opponentName, isNull);
    });
  });

  group('PlayerProfile', () {
    test('fromJson parses correctly', () {
      final json = {
        'odID': 'od_001',
        'odName': 'TestPlayer',
        'rating': 1500,
        'rank': 'gold',
        'totalMatches': 50,
        'winCount': 30,
        'winRate': 0.6,
      };
      final profile = PlayerProfile.fromJson(json);
      expect(profile.odID, equals('od_001'));
      expect(profile.odName, equals('TestPlayer'));
      expect(profile.rating, equals(1500));
      expect(profile.rank, equals('gold'));
      expect(profile.winRate, equals(0.6));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final profile = PlayerProfile.fromJson(json);
      expect(profile.odID, equals(''));
      expect(profile.rating, equals(1000));
      expect(profile.rank, equals('bronze'));
    });
  });

  group('LeaderboardEntry', () {
    test('fromJson parses correctly', () {
      final json = {
        'rank': 1,
        'odID': 'od_001',
        'odName': 'TopPlayer',
        'rating': 2000,
        'rankName': 'legend',
      };
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.rank, equals(1));
      expect(entry.odName, equals('TopPlayer'));
      expect(entry.rating, equals(2000));
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.rank, equals(0));
      expect(entry.odID, equals(''));
    });
  });

  group('GameAction', () {
    test('toJson serializes correctly', () {
      final action = GameAction(type: 'play_card', odID: 'od_001', data: {'cardId': 'B001'});
      final json = action.toJson();
      expect(json['type'], equals('play_card'));
      expect(json['odID'], equals('od_001'));
      expect(json['data'], equals({'cardId': 'B001'}));
    });

    test('toJson omits null data', () {
      final action = GameAction(type: 'end_turn', odID: 'od_001');
      final json = action.toJson();
      expect(json.containsKey('data'), isFalse);
    });
  });

  group('WebSocketService', () {
    test('messages stream is broadcast', () {
      final ws = WebSocketService();
      expect(ws.messages, isNotNull);
      ws.dispose();
    });

    test('sendAction does not throw', () {
      final ws = WebSocketService();
      final action = GameAction(type: 'play_card', odID: 'od_001');
      ws.sendAction('match_1', 'od_001', action);
      ws.dispose();
    });
  });
}
