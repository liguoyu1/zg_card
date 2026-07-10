import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/effect_executor.dart';
import 'package:warring_states_card/domain/services/effects.dart';

void main() {
  group('EffectExecutor Tests', () {
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
            name: '魏武卒',
            type: CardType.minion,
            cost: 3,
            attack: 3,
            health: 4,
            description: '战吼：造成1点伤害',
            keywords: [Keyword.battlecry],
            owner: CardOwner.bingjia,
            rarity: Rarity.rare,
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
      );
      
      initialState = GameState(
        player1: player1,
        player2: player2,
        activePlayerId: 'p1',
      );
    });
    
    test('executeBattlecry for B001 (魏武卒)', () {
      final executor = EffectExecutor();
      const card = Card(
        id: 'B001',
        name: '魏武卒',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 4,
        description: '战吼：造成1点伤害',
        keywords: [Keyword.battlecry],
        owner: CardOwner.bingjia,
        rarity: Rarity.rare,
      );
      
      final newState = executor.executeBattlecry(initialState, 'p1', card, null);
      
      expect(newState.player2.health, 29); // 受到1点伤害
    });
    
    test('executeDeathrattle for N001 (民兵)', () {
      final executor = EffectExecutor();
      const card = Card(
        id: 'N001',
        name: '民兵',
        type: CardType.minion,
        cost: 1,
        attack: 1,
        health: 1,
        description: '亡语：召唤一个1/1民兵',
        keywords: [Keyword.deathrattle],
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      final newState = executor.executeDeathrattle(initialState, 'p1', card);
      
      // 亡语召唤民兵
      expect(newState.player1.board.any((c) => c.name == '民兵'), true);
    });
    
    test('handleDeath processes deathrattle', () {
      final executor = EffectExecutor();
      const deadCard = Card(
        id: 'N001',
        name: '民兵',
        type: CardType.minion,
        cost: 1,
        attack: 1,
        health: 1,
        description: '亡语：召唤一个1/1民兵',
        keywords: [Keyword.deathrattle],
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      final newState = executor.handleDeath(initialState, 'p1', deadCard);
      
      expect(newState.player1.board.isNotEmpty, true);
    });
  });
  
  group('ChainTrigger Tests', () {
    late GameState state;
    
    setUp(() {
      state = const GameState(
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
    });
    
    test('checkTrigger onPlay', () {
      expect(ChainTrigger.checkTrigger(state, 'p1', const Card(
        id: 'test',
        name: '测试',
        type: CardType.minion,
        cost: 1,
        attack: 1,
        health: 1,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      ), ChainTriggerType.onPlay), true);
    });
    
    test('getChainTargets for spell', () {
      const card = Card(
        id: 'test',
        name: '测试法术',
        type: CardType.spell,
        cost: 1,
        description: '',
        owner: CardOwner.neutral,
        rarity: Rarity.common,
      );
      
      final targets = ChainTrigger.getChainTargets(state, 'p1', card, ChainTriggerType.onPlay);
      
      expect(targets.isEmpty, true); // 法术无目标
    });
  });
  
  group('DamageEffect Tests', () {
    test('Damage to hero', () {
      const effect = DamageEffect(3, targetHero: true);
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
      );
      
      final newState = effect.execute(state, 'p1', null);
      
      expect(newState.player2.health, 27);
    });
  });
  
  group('BuffEffect Tests', () {
    test('Buff to self', () {
      const buffEffect = BuffEffect(attackBonus: 2, healthBonus: 2, toSelf: true);
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
          board: [
            Card(
              id: 'minion1',
              name: '随从',
              type: CardType.minion,
              cost: 2,
              attack: 2,
              health: 2,
              description: '',
              owner: CardOwner.bingjia,
              rarity: Rarity.common,
            ),
          ],
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
      );
      
      final newState = buffEffect.execute(state, 'p1', 'minion1');
      
      expect(newState.player1.board.first.attack, 4);
      expect(newState.player1.board.first.health, 4);
    });
  });
  
  group('ComboEffect Tests', () {
    test('Combo executes multiple effects', () {
      const combo = ComboEffect([
        DrawCardsEffect(1),
        HealEffect(2),
      ]);
      
      const state = GameState(
        player1: Player(
          id: 'p1',
          health: 25,  // 设置初始生命值25
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
          deck: [
            Card(
              id: 'deck1',
              name: '抽牌测试',
              type: CardType.minion,
              cost: 2,
              attack: 2,
              health: 2,
              description: '',
              owner: CardOwner.neutral,
              rarity: Rarity.common,
            ),
          ],
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
      );
      
      final newState = combo.execute(state, 'p1', null);
      
      expect(newState.player1.hand.length, 1);
      expect(newState.player1.health, 27);
    });
  });
}