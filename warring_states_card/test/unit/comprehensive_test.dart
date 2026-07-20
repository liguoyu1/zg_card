import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/data/persistence/save_manager.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/ai_controller.dart';
import 'package:warring_states_card/domain/services/game_rules.dart';

void main() {
  const testHero = Hero(
    id: 'H_TEST',
    name: '测试英雄',
    className: 'test',
    kingdom: '测',
    heroPowerName: '测试技能',
    heroPowerDescription: '测试',
    skillType: SkillType.heal,
  );

  group('英雄数据验证', () {
    test('英雄属性完整', () {
      expect(testHero.id.isNotEmpty, isTrue);
      expect(testHero.name.isNotEmpty, isTrue);
      expect(testHero.className.isNotEmpty, isTrue);
      expect(testHero.heroPowerName.isNotEmpty, isTrue);
    });
  });

  group('游戏规则验证', () {
    test('初始生命值正确', () {
      expect(GameRules.initialHealth, equals(30));
    });

    test('初始手牌数量正确', () {
      expect(GameRules.initialHandSize, equals(4));
    });

    test('最大手牌数正确', () {
      expect(GameRules.maxHandSize, equals(10));
    });

    test('战场随从上限正确', () {
      expect(GameRules.maxBoardSize, equals(7));
    });
  });

  group('Player模型验证', () {
    test('玩家初始状态正确', () {
      const player = Player(id: 'test', hero: testHero);
      
      expect(player.health, equals(30));
      expect(player.mana, equals(0));
      expect(player.maxMana, equals(0));
      expect(player.board.isEmpty, isTrue);
    });
  });

  group('AIController验证', () {
    test('简单AI随机出牌', () {
      final ai = AIController(difficulty: AIDifficulty.simple);
      final hand = <Card>[
        const Card(id: 'C1', name: '测试卡', type: CardType.minion, cost: 3, attack: 2, health: 2, 
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
        const Card(id: 'C2', name: '测试卡2', type: CardType.minion, cost: 4, attack: 3, health: 3, 
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      const player = Player(id: 'ai', hero: testHero);
      
      final order = ai.getOptimalPlayOrder(hand, player);
      expect(order.length, equals(2));
    });

    test('普通AI按费用排序', () {
      final ai = AIController();
      final hand = <Card>[
        const Card(id: 'C1', name: '测试卡', type: CardType.minion, cost: 3, attack: 2, health: 2, 
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
        const Card(id: 'C2', name: '测试卡2', type: CardType.minion, cost: 5, attack: 4, health: 4, 
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
        const Card(id: 'C3', name: '测试卡3', type: CardType.minion, cost: 2, attack: 1, health: 1, 
          description: '', owner: CardOwner.neutral, rarity: Rarity.common),
      ];
      const player = Player(id: 'ai', hero: testHero);
      
      final order = ai.getOptimalPlayOrder(hand, player);
      expect(order[0].cost, greaterThanOrEqualTo(order[1].cost));
      expect(order[1].cost, greaterThanOrEqualTo(order[2].cost));
    });
  });

  group('存档数据验证', () {
    test('PlayerData序列化', () {
      final data = PlayerData(id: 'test', name: '测试玩家');
      final json = data.toJson();
      final restored = PlayerData.fromJson(json);
      
      expect(restored.id, equals('test'));
      expect(restored.name, equals('测试玩家'));
      expect(restored.level, equals(1));
    });

    test('Collection序列化', () {
      final collection = Collection(
        cards: {'C001': 2, 'C002': 1},
        cardCopies: {'C001': 3},
      );
      final json = collection.toJson();
      final restored = Collection.fromJson(json);
      
      expect(restored.cards['C001'], equals(2));
      expect(restored.cards['C002'], equals(1));
    });

    test('MatchRecord序列化', () {
      final record = MatchRecord(
        id: 'match_001',
        timestamp: DateTime.now(),
        playerId: 'p1',
        opponentId: 'ai',
        isWin: true,
        duration: 180,
        playerHero: 'H_B001',
        opponentHero: 'H_F001',
        playerRankScore: 1050,
        opponentRankScore: 1000,
      );
      final json = record.toJson();
      final restored = MatchRecord.fromJson(json);
      
      expect(restored.isWin, isTrue);
      expect(restored.duration, equals(180));
    });
  });

  group('Card模型验证', () {
    test('卡牌类型判断', () {
      const minion = Card(id: 'C1', name: '测试随从', type: CardType.minion, cost: 3, attack: 2, health: 2, 
        description: '', owner: CardOwner.neutral, rarity: Rarity.common);
      const spell = Card(id: 'C2', name: '测试法术', type: CardType.spell, cost: 2, 
        description: '测试', owner: CardOwner.neutral, rarity: Rarity.common);
      const weapon = Card(id: 'C3', name: '测试武器', type: CardType.weapon, cost: 4, attack: 3, health: 2, 
        description: '', owner: CardOwner.neutral, rarity: Rarity.common);
      
      expect(minion.isMinion, isTrue);
      expect(spell.isSpell, isTrue);
      expect(weapon.isWeapon, isTrue);
    });

    test('关键词识别', () {
      const chargeCard = Card(
        id: 'C1', name: '冲锋随从', type: CardType.minion, cost: 3, attack: 2, health: 2,
        description: '', keywords: [Keyword.charge], owner: CardOwner.neutral, rarity: Rarity.common,
      );
      const tauntCard = Card(
        id: 'C2', name: '嘲讽随从', type: CardType.minion, cost: 3, attack: 2, health: 2,
        description: '', keywords: [Keyword.taunt], owner: CardOwner.neutral, rarity: Rarity.common,
      );
      
      expect(chargeCard.hasCharge, isTrue);
      expect(tauntCard.hasTaunt, isTrue);
    });
  });

  group('GameRules验证', () {
    test('游戏结束判定-玩家死亡', () {
      const player1 = Player(id: 'p1', hero: testHero, health: 0);
      const player2 = Player(id: 'p2', hero: testHero);
      
      final result = GameRules.checkGameEnd(player1, player2);
      expect(result, isFalse);
    });

    test('游戏结束判定-双方存活', () {
      const player1 = Player(id: 'p1', hero: testHero);
      const player2 = Player(id: 'p2', hero: testHero);
      
      final result = GameRules.checkGameEnd(player1, player2);
      expect(result, isNull);
    });
  });
}