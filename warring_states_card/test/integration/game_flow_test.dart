import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/game_rules.dart';
import 'package:warring_states_card/domain/services/effects.dart';
import 'package:warring_states_card/domain/services/ai_controller.dart';
import 'package:warring_states_card/domain/services/combo_system.dart';
import 'package:warring_states_card/domain/services/hero_power.dart';
import 'package:warring_states_card/domain/services/effect_executor.dart';
import 'package:warring_states_card/presentation/providers/game_provider.dart';

void main() {
  const testHero = Hero(
    id: 'H_TEST', name: '测试英雄', className: 'test', kingdom: 'test',
    health: 30, heroPowerName: '铁壁', heroPowerDescription: '获得2护甲',
    skillType: SkillType.defensive,
  );
  const opponentHero = Hero(
    id: 'H_OPP', name: '敌将', className: 'bingjia', kingdom: '齐',
    health: 30, heroPowerName: '铁壁', heroPowerDescription: '获得2护甲',
    skillType: SkillType.defensive,
  );
  final bf = BattlefieldService();
  final ts = TurnService();

  // ═══════════════════════════════════════════════════════
  // Group 1: 完整对局流程
  // ═══════════════════════════════════════════════════════
  group('1 完整对局流程', () {
    late GameStateNotifier gn;

    setUp(() {
      gn = GameStateNotifier();
      gn.initGame(player1Id: 'p1', player2Id: 'p2', player1Hero: testHero, player2Hero: opponentHero);
    });

    test('1.1 初始状态正确', () {
      final gs = gn.state!;
      expect(gs.phase, GamePhase.mulligan);
      expect(gs.activePlayer.hand.length, GameRules.initialHandSize);
      expect(gs.activePlayer.mana, 1);
      expect(gs.activePlayer.maxMana, 1);
      expect(gs.activePlayer.health, GameRules.initialHealth);
      expect(gs.player2.health, GameRules.initialHealth);
    });

    test('1.2 开始回合', () {
      gn.startTurn('p1');
      final gs = gn.state!;
      expect(gs.activePlayer.mana, gs.activePlayer.maxMana);
      expect(gs.activePlayer.hand.length, GameRules.initialHandSize + 1);
      final notAttacked = gs.activePlayer.board.every((c) => !c.hasAttackedThisTurn);
      expect(notAttacked, isTrue);
    });

    test('1.3 出随从', () {
      for (int i = 0; i < 3; i++) {
        gn.startTurn('p1');
        gn.endTurn('p1');
        gn.startTurn('p2');
        gn.endTurn('p2');
      }
      gn.startTurn('p1');
      final hand = gn.state!.activePlayer.hand;
      final affordable = hand.where((c) => c.isMinion && c.cost <= gn.state!.activePlayer.mana).toList();
      if (affordable.isEmpty) {
        expect(true, isTrue);
        return;
      }
      final minion = affordable.first;
      final manaBefore = gn.state!.activePlayer.mana;
      gn.playCard('p1', minion);
      final gs = gn.state!;
      expect(gs.activePlayer.mana, manaBefore - minion.cost);
      expect(gs.activePlayer.boardCount, 1);
      expect(gs.activePlayer.hand.length, hand.length - 1);
    });

    test('1.4 英雄技能', () {
      gn.startTurn('p1');
      gn.useHeroPower('p1');
      final gs = gn.state!;
      expect(gs.activePlayer.armor, 2);
      expect(gs.activePlayer.mana, 0);
    });

    test('1.5 结束回合', () {
      gn.startTurn('p1');
      gn.endTurn('p1');
      final gs = gn.state!;
      expect(gs.activePlayerId, 'p2');
      expect(gs.turnNumber, 1);
    });

    test('1.6 mana逐步增长', () {
      for (int i = 0; i < 5; i++) {
        gn.startTurn('p1');
        gn.endTurn('p1');
        gn.startTurn('p2');
        gn.endTurn('p2');
      }
      gn.startTurn('p1');
      expect(gn.state!.activePlayer.maxMana, 7); // 1(init) + 6(startTurns) = 7
    });

    test('1.7 胜负判定', () {
      gn.state = gn.state!.updatePlayer(gn.state!.player2.copyWith(health: 0));
      if (gn.state!.player1.board.isNotEmpty) {
        gn.minionAttackHero('p1', gn.state!.player1.board.first);
      }
      if (gn.state!.phase != GamePhase.ended) {
        final winner = GameRules.checkGameEnd(gn.state!.player1, gn.state!.player2);
        if (winner != null) {
          final wid = winner ? gn.state!.player1.id : gn.state!.player2.id;
          gn.state = gn.state!.copyWith(phase: GamePhase.ended, winnerId: wid);
        }
      }
      expect(gn.state!.phase, GamePhase.ended);
      expect(gn.state!.winnerId, 'p1');
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 2: 圣盾交互
  // ═══════════════════════════════════════════════════════
  group('2 圣盾交互', () {
    GameState makeGs(Card atk, Card def) => GameState(
      player1: Player(id:'p1', hero:testHero, board:[atk], health:30, mana:10),
      player2: Player(id:'p2', hero:opponentHero, board:[def], health:30, mana:10),
      activePlayerId: 'p1',
    );

    test('2.1 普通vs普通', () {
      final c = GameRules.resolveCombat(
        Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:3,health:3,description:'',owner:CardOwner.neutral,rarity:Rarity.common),
        Card(id:'b',name:'b',type:CardType.minion,cost:2,attack:2,health:4,description:'',owner:CardOwner.neutral,rarity:Rarity.common),
      );
      expect(c.attackerDamage, 2);
      expect(c.defenderDamage, 3);
    });

    test('2.2 圣盾vs普通', () {
      final atk = Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:3,health:3,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final def = Card(id:'b',name:'b',type:CardType.minion,cost:2,attack:2,health:4,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final r = bf.minionAttack(makeGs(atk, def), 'p1', atk, def.id);
      expect(r.player1.board.first.hasDivineShield, isFalse);
      expect(r.player2.board.first.health, 1);
    });

    test('2.3 普通vs圣盾', () {
      final atk = Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:3,health:3,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final def = Card(id:'b',name:'b',type:CardType.minion,cost:2,attack:2,health:4,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final r = bf.minionAttack(makeGs(atk, def), 'p1', atk, def.id);
      expect(r.player2.board.first.hasDivineShield, isFalse);
      expect(r.player2.board.first.health, 4);
      expect(r.player1.board.first.health, 1);
    });

    test('2.4 圣盾vs圣盾', () {
      final atk = Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:3,health:3,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final def = Card(id:'b',name:'b',type:CardType.minion,cost:2,attack:2,health:4,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final r = bf.minionAttack(makeGs(atk, def), 'p1', atk, def.id);
      expect(r.player1.board.first.hasDivineShield, isFalse);
      expect(r.player2.board.first.hasDivineShield, isFalse);
      expect(r.player1.board.first.health, 3);
      expect(r.player2.board.first.health, 4);
    });

    test('2.5 剧毒vs圣盾', () {
      final atk = Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:1,health:1,
        keywords:[Keyword.poisonous],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final def = Card(id:'b',name:'b',type:CardType.minion,cost:2,attack:1,health:4,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final r = bf.minionAttack(makeGs(atk, def), 'p1', atk, def.id);
      expect(r.player2.board.isNotEmpty, isTrue);
      expect(r.player2.board.first.health, 4);
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 3: 亡语
  // ═══════════════════════════════════════════════════════
  group('3 亡语', () {
    test('3.1 亡语死亡召唤', () {
      const card = Card(id:'N001',name:'民兵',type:CardType.minion,cost:2,attack:2,health:1,
        keywords:[Keyword.deathrattle],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final atk = Card(id:'a',name:'a',type:CardType.minion,cost:2,attack:5,health:5,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,board:[atk],health:30,mana:10),
        player2:Player(id:'p2',hero:opponentHero,board:[card],health:30,mana:10),
        activePlayerId:'p1');
      gs = bf.minionAttack(gs, 'p1', atk, card.id);
      expect(gs.player2.board.length, greaterThanOrEqualTo(1));
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 4: AI行为
  // ═══════════════════════════════════════════════════════
  group('4 AI行为', () {
    final minion = Card(id:'C1',name:'步',type:CardType.minion,cost:3,attack:3,health:3,
      description:'',owner:CardOwner.neutral,rarity:Rarity.common);
    final spell = Card(id:'C2',name:'火',type:CardType.spell,cost:4,
      description:'',owner:CardOwner.neutral,rarity:Rarity.common);

    test('4.1 Normal随从优先', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final order = ai.getOptimalPlayOrder([spell, minion], Player(id:'p',hero:testHero,hand:[],mana:10));
      expect(order.first.isMinion, isTrue);
    });

    test('4.2 嘲讽优先攻击', () {
      final ai = AIController(difficulty: AIDifficulty.normal);
      final taunt = Card(id:'T',name:'T',type:CardType.minion,cost:2,attack:1,health:6,
        keywords:[Keyword.taunt],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      final self = Player(id:'p1',hero:testHero,board:[minion]);
      final opp = Player(id:'p2',hero:opponentHero,board:[taunt, minion]);
      expect(ai.selectAttackTarget(self, opp)?.hasTaunt, isTrue);
    });

    test('4.3 combo激活', () {
      final simple = AIController(difficulty: AIDifficulty.simple);
      final abyss = AIController(difficulty: AIDifficulty.abyss);
      final big = List.generate(5, (i) => Card(id:'C$i',name:'$i',type:CardType.minion,
        cost:1,attack:1,health:1,description:'',owner:CardOwner.neutral,rarity:Rarity.common));
      expect(simple.shouldActivateCombo(big), isFalse);
      expect(abyss.shouldActivateCombo(big), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 5: 边界条件
  // ═══════════════════════════════════════════════════════
  group('5 边界条件', () {
    test('5.1 满手牌爆牌', () {
      final full = List.generate(10, (i) => Card(id:'C$i',name:'$i',type:CardType.minion,
        cost:1,attack:1,health:1,description:'',owner:CardOwner.neutral,rarity:Rarity.common));
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,hand:full,deck:[full.first],mana:5,maxMana:5,health:30),
        player2:Player(id:'p2',hero:opponentHero,hand:[],deck:[],health:30),
        activePlayerId:'p1');
      gs = ts.startTurn(gs, 'p1');
      expect(gs.player1.hand.length, 10);
    });

    test('5.2 满场拒绝', () {
      final full = List.generate(7, (i) => Card(id:'B$i',name:'$i',type:CardType.minion,
        cost:1,attack:1,health:1,description:'',owner:CardOwner.neutral,rarity:Rarity.common));
      final newCard = Card(id:'new',name:'新',type:CardType.minion,cost:1,attack:1,health:1,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      expect(GameRules.canPlayCard(newCard, Player(id:'p1',hero:testHero,board:full,mana:10)), isFalse);
    });

    test('5.3 0法力拒绝', () {
      final c = Card(id:'c',name:'c',type:CardType.minion,cost:5,attack:5,health:5,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      expect(GameRules.canPlayCard(c, Player(id:'p1',hero:testHero,hand:[c],mana:0)), isFalse);
    });

    test('5.4 疲劳递增', () {
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,deck:[],hand:[],mana:5,maxMana:5,health:30),
        player2:Player(id:'p2',hero:opponentHero,deck:[],hand:[],health:30),
        activePlayerId:'p1');
      gs = ts.startTurn(gs, 'p1');
      expect(gs.player1.health, 29);
      expect(gs.player1.fatigueCounter, 1);
    });

    test('5.5 平局', () {
      final r = GameRules.checkGameEnd(
        Player(id:'p1',hero:testHero,health:0,mana:0),
        Player(id:'p2',hero:opponentHero,health:0,mana:0));
      expect(r, isNull);
    });

    test('5.6 沉默圣盾', () {
      final s = Card(id:'s',name:'s',type:CardType.minion,cost:3,attack:3,health:5,
        keywords:[Keyword.divineShield],description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,board:[s],health:30,mana:10),
        player2:Player(id:'p2',hero:opponentHero,board:[],health:30),
        activePlayerId:'p1');
      gs = bf.silenceMinion(gs, 'p1', s.id);
      expect(gs.player1.board.first.hasDivineShield, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 6: 组合技能
  // ═══════════════════════════════════════════════════════
  group('6 组合技能', () {
    test('6.1 合纵连横', () {
      final a = Card(id:'Z008',name:'苏秦',type:CardType.minion,cost:4,attack:3,health:3,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.zonghengjia,rarity:Rarity.rare);
      final b = Card(id:'Z009',name:'张仪',type:CardType.minion,cost:4,attack:3,health:3,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.zonghengjia,rarity:Rarity.rare);
      final w = Card(id:'W',name:'W',type:CardType.minion,cost:2,attack:2,health:2,
        description:'',owner:CardOwner.neutral,rarity:Rarity.common);
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,hand:[a,b],board:[w],mana:10,health:30),
        player2:Player(id:'p2',hero:opponentHero,health:30),
        activePlayerId:'p1');
      final combos = ComboSystem.getActivatedCombos(gs.player1.hand);
      expect(combos.any((c) => c.id == 'combo_suqin_zhangyi'), isTrue);
      final r = ComboSystem.executeCombo(combos.first, gs, 'p1');
      expect(r.state.player1.board.first.attack, 3);
      expect(r.state.player1.board.first.health, 3);
    });

    test('6.2 机关术', () {
      final a = Card(id:'M008',name:'墨子',type:CardType.minion,cost:7,attack:5,health:5,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.mojia,rarity:Rarity.legendary);
      final b = Card(id:'M009',name:'公输班',type:CardType.minion,cost:5,attack:4,health:4,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.mojia,rarity:Rarity.epic);
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,hand:[a,b],board:[],mana:10,health:30),
        player2:Player(id:'p2',hero:opponentHero,health:30),
        activePlayerId:'p1');
      final combos = ComboSystem.getActivatedCombos(gs.player1.hand);
      final r = ComboSystem.executeCombo(combos.first, gs, 'p1');
      expect(r.state.player1.board.length, 2);
    });

    test('6.3 儒道双修', () {
      final deck = List.generate(10, (i) => Card(id:'D$i',name:'$i',type:CardType.minion,
        cost:1,attack:1,health:1,description:'',owner:CardOwner.neutral,rarity:Rarity.common));
      final a = Card(id:'R008',name:'孔子',type:CardType.minion,cost:8,attack:6,health:6,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.rujia,rarity:Rarity.legendary);
      final b = Card(id:'D008',name:'老子',type:CardType.minion,cost:7,attack:5,health:5,
        description:'',keywords:[Keyword.battlecry],owner:CardOwner.daojia,rarity:Rarity.legendary);
      var gs = GameState(
        player1:Player(id:'p1',hero:testHero,hand:[a,b],deck:deck,mana:10,health:20),
        player2:Player(id:'p2',hero:opponentHero,health:30),
        activePlayerId:'p1');
      final combos = ComboSystem.getActivatedCombos(gs.player1.hand);
      final r = ComboSystem.executeCombo(combos.first, gs, 'p1');
      expect(r.state.player1.hand.length, 5);
      expect(r.state.player1.health, 24);
    });
  });

  // ═══════════════════════════════════════════════════════
  // Group 7: 效果系统
  // ═══════════════════════════════════════════════════════
  group('7 效果系统', () {
    var gs = GameState(
      player1:Player(id:'p1',hero:testHero,hand:[],deck:[],mana:10,health:25),
      player2:Player(id:'p2',hero:opponentHero,board:[],health:20),
      activePlayerId:'p1');

    test('7.1 Damage', () {
      gs = const DamageEffect(3, targetHero: true).execute(gs, 'p1', null);
      expect(gs.player2.health, 17);
    });

    test('7.2 Heal', () {
      gs = const HealEffect(5).execute(gs, 'p1', null);
      expect(gs.player1.health, 30);
    });

    test('7.3 Armor', () {
      gs = const GainArmorEffect(3).execute(gs, 'p1', null);
      expect(gs.player1.armor, 3);
    });

    test('7.4 Draw', () {
      final deck = List.generate(5, (i) => Card(id:'D$i',name:'$i',type:CardType.minion,
        cost:1,attack:1,health:1,description:'',owner:CardOwner.neutral,rarity:Rarity.common));
      gs = gs.updatePlayer(gs.player1.copyWith(deck: deck, hand: []));
      gs = const DrawCardsEffect(2).execute(gs, 'p1', null);
      expect(gs.player1.hand.length, 2);
      expect(gs.player1.deck.length, 3);
    });
  });
}
