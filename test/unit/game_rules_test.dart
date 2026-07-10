import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/game_rules.dart';

void main() {
  group('GameRules Tests', () {
    test('canMinionAttack with charge', () {
      const charger = Card(
        id: 'test',
        name: '冲锋',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        keywords: [Keyword.charge],
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      expect(GameRules.canMinionAttack(charger, true), true);
    });
    
    test('canPlayCard - sufficient mana', () {
      const card = Card(
        id: 'test',
        name: '测试',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      const player = Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        mana: 3,
      );
      
      expect(GameRules.canPlayCard(card, player), true);
    });
    
    test('canPlayCard - insufficient mana', () {
      const card = Card(
        id: 'test',
        name: '测试',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      const player = Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        mana: 2,
      );
      
      expect(GameRules.canPlayCard(card, player), false);
    });
    
    test('resolveCombat with divine shield', () {
      const attacker = Card(
        id: 'atk',
        name: '攻击者',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      const defender = Card(
        id: 'def',
        name: '防守者',
        type: CardType.minion,
        cost: 3,
        attack: 2,
        health: 3,
        description: '',
        keywords: [Keyword.divineShield],
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      final result = GameRules.resolveCombat(attacker, defender);
      expect(result.attackerDamage, 2); // 防守者反击2点
      expect(result.defenderDamage, 3); // 攻击者造成3点（圣盾在调用方处理）
    });
    
    test('getTauntTargets', () {
      const player = Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        board: [
          Card(
            id: 'taunt1',
            name: '嘲讽1',
            type: CardType.minion,
            cost: 3,
            attack: 2,
            health: 3,
            description: '',
            keywords: [Keyword.taunt],
            owner: CardOwner.neutral,
            rarity: Rarity.common,
          ),
          Card(
            id: 'normal',
            name: '普通',
            type: CardType.minion,
            cost: 3,
            attack: 2,
            health: 3,
            description: '',
            owner: CardOwner.neutral,
            rarity: Rarity.common,
          ),
        ],
      );
      
      final taunts = GameRules.getTauntTargets(player);
      expect(taunts.length, 1);
      expect(taunts.first.id, 'taunt1');
    });
    
    test('mustAttackTaunt', () {
      const player = Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        board: [
          Card(
            id: 'taunt1',
            name: '嘲讽',
            type: CardType.minion,
            cost: 3,
            attack: 2,
            health: 3,
            description: '',
            keywords: [Keyword.taunt],
            owner: CardOwner.neutral,
            rarity: Rarity.common,
          ),
        ],
      );
      
      expect(GameRules.mustAttackTaunt(player), true);
    });
  });
  
  group('BattlefieldService Tests', () {
    late GameState initialState;
    late Player player1;
    late Player player2;
    
    setUp(() {
      player1 = const Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        mana: 10,
        maxMana: 10,
        hand: [
          Card(
            id: 'card1',
            name: '手牌1',
            type: CardType.minion,
            cost: 3,
            attack: 3,
            health: 3,
            description: '',
            owner: CardOwner.bingjia,
            rarity: Rarity.common,
          ),
        ],
      );
      
      player2 = const Player(
        id: 'p2',
        hero: Hero(
          id: 'H_F001',
          name: '商鞅',
          className: 'fajia',
          kingdom: '秦',
          heroPowerName: '变法革新',
          heroPowerDescription: '变法革新',
          skillType: SkillType.control,
        ),
        mana: 10,
        maxMana: 10,
        board: [
          Card(
            id: 'enemy1',
            name: '敌方随从',
            type: CardType.minion,
            cost: 3,
            attack: 2,
            health: 3,
            description: '',
            owner: CardOwner.fajia,
            rarity: Rarity.common,
          ),
        ],
      );
      
      initialState = GameState(
        player1: player1,
        player2: player2,
        activePlayerId: 'p1',
      );
    });
    
    test('playCard - play minion', () {
      final service = BattlefieldService();
      const card = Card(
        id: 'card1',
        name: '手牌1',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.bingjia,
        rarity: Rarity.common,
      );
      
      final newState = service.playCard(initialState, 'p1', card);
      
      expect(newState.player1.hand.length, 0);
      expect(newState.player1.board.length, 1);
      expect(newState.player1.mana, 7);
    });
    
    test('minionAttack', () {
      final service = BattlefieldService();
      const attacker = Card(
        id: 'attacker',
        name: '攻击者',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.bingjia,
        rarity: Rarity.common,
      );
      
      final stateWithAttacker = initialState.updatePlayer(
        player1.copyWith(board: [attacker]),
      );
      
      final newState = service.minionAttack(stateWithAttacker, 'p1', attacker, 'enemy1');
      
      // 3/3攻击2/3，防守者死亡
      expect(newState.player2.board.length, 0);
    });
  });
  
  group('TurnService Tests', () {
    test('startTurn - increase mana', () {
      const player = Player(
        id: 'p1',
        hero: Hero(
          id: 'H_B001',
          name: '孙膑',
          className: 'bingjia',
          kingdom: '齐',
          heroPowerName: '围魏救赵',
          heroPowerDescription: '获得2点护甲',
          skillType: SkillType.defensive,
        ),
        maxMana: 5,
      );
      
      const state = GameState(
        player1: player,
        player2: Player(
          id: 'p2',
          hero: Hero(
            id: 'H_F001',
            name: '商鞅',
            className: 'fajia',
            kingdom: '秦',
            heroPowerName: '变法革新',
            heroPowerDescription: '变法革新',
            skillType: SkillType.control,
          ),
        ),
        activePlayerId: 'p1',
      );
      
      final service = TurnService();
      final newState = service.startTurn(state, 'p1');
      
      expect(newState.player1.maxMana, 6);
      expect(newState.player1.mana, 6);
    });
    
    test('endTurn - switch active player', () {
      final service = TurnService();
      const state = GameState(
        player1: Player(
          id: 'p1',
          hero: Hero(
            id: 'H_B001',
            name: '孙膑',
            className: 'bingjia',
            kingdom: '齐',
            heroPowerName: '围魏救赵',
            heroPowerDescription: '获得2点护甲',
            skillType: SkillType.defensive,
          ),
        ),
        player2: Player(
          id: 'p2',
          hero: Hero(
            id: 'H_F001',
            name: '商鞅',
            className: 'fajia',
            kingdom: '秦',
            heroPowerName: '变法革新',
            heroPowerDescription: '变法革新',
            skillType: SkillType.control,
          ),
        ),
        activePlayerId: 'p1',
        turnNumber: 1,
      );
      
      final newState = service.endTurn(state, 'p1');
      
      expect(newState.activePlayerId, 'p2');
      expect(newState.turnNumber, 2);
    });
    
    test('drawInitialHands', () {
      final deck = List.generate(30, (i) => Card(
        id: 'card_$i',
        name: '卡牌$i',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 3,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      ));
      
      final result = TurnService.drawInitialHands(deck, GameRules.initialHandSize);

      expect(result.hand.length, GameRules.initialHandSize);
      expect(result.deck.length, 30 - GameRules.initialHandSize);
    });
  });
}