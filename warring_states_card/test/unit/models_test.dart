import 'package:flutter_test/flutter_test.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/services.dart';
import 'package:warring_states_card/data/cards/cards.dart';
import 'package:warring_states_card/data/heroes/heroes_data.dart';

void main() {
  group('Card Model Tests', () {
    test('Card has correct properties', () {
      const card = Card(
        id: 'test_001',
        name: '测试卡牌',
        type: CardType.minion,
        cost: 3,
        attack: 3,
        health: 4,
        description: '测试描述',
        owner: CardOwner.bingjia,
        rarity: Rarity.common,
      );
      
      expect(card.id, 'test_001');
      expect(card.name, '测试卡牌');
      expect(card.cost, 3);
      expect(card.attack, 3);
      expect(card.health, 4);
      expect(card.isMinion, true);
      expect(card.isSpell, false);
    });
    
    test('Card keywords detection', () {
      const card = Card(
        id: 'test_002',
        name: '带关键词卡牌',
        type: CardType.minion,
        cost: 2,
        attack: 2,
        health: 2,
        description: '战吼测试',
        keywords: [Keyword.battlecry, Keyword.charge],
        owner: CardOwner.fajia,
        rarity: Rarity.rare,
      );
      
      expect(card.hasBattlecry, true);
      expect(card.hasCharge, true);
      expect(card.hasDeathrattle, false);
    });
  });
  
  group('Player Model Tests', () {
    test('Player initial state', () {
      const hero = Hero(
        id: 'H_B001',
        name: '孙膑',
        className: 'bingjia',
        kingdom: '齐',
        health: 30,
        heroPowerName: '围魏救赵',
        heroPowerDescription: '获得2点护甲',
        skillType: SkillType.defensive,
      );
      
      final player = Player(
        id: 'player_1',
        hero: hero,
        health: 30,
        mana: 0,
        maxMana: 0,
      );
      
      expect(player.health, 30);
      expect(player.isDead, false);
      expect(player.mana, 0);
      expect(player.boardCount, 0);
      expect(player.handCount, 0);
    });
    
    test('Player death check', () {
      const hero = Hero(
        id: 'H_B001',
        name: '孙膑',
        className: 'bingjia',
        kingdom: '齐',
        health: 30,
        heroPowerName: '围魏救赵',
        heroPowerDescription: '获得2点护甲',
        skillType: SkillType.defensive,
      );
      
      final player = Player(
        id: 'player_1',
        hero: hero,
        health: 0,
      );
      
      expect(player.isDead, true);
    });
  });
  
  group('GameState Tests', () {
    test('GameState active player switching', () {
      const hero1 = Hero(
        id: 'H_B001',
        name: '孙膑',
        className: 'bingjia',
        kingdom: '齐',
        health: 30,
        heroPowerName: '围魏救赵',
        heroPowerDescription: '获得2点护甲',
        skillType: SkillType.defensive,
      );
      
      const hero2 = Hero(
        id: 'H_F001',
        name: '商鞅',
        className: 'fajia',
        kingdom: '秦',
        health: 30,
        heroPowerName: '变法革新',
        heroPowerDescription: '变法革新',
        skillType: SkillType.control,
      );
      
      final state = GameState(
        player1: Player(id: 'p1', hero: hero1),
        player2: Player(id: 'p2', hero: hero2),
        activePlayerId: 'p1',
      );
      
      expect(state.activePlayer.id, 'p1');
      expect(state.opponent.id, 'p2');
    });
  });
  
  group('Card Data Tests', () {
    test('Total cards count', () {
      final cards = getAllCards();
      expect(cards.length, greaterThanOrEqualTo(144));
    });
    
    test('Cards by owner', () {
      final bingjiaCards = getCardsByOwner(CardOwner.bingjia);
      expect(bingjiaCards.isNotEmpty, true);
      
      final neutralCards = getNeutralCards();
      expect(neutralCards.isNotEmpty, true);
    });
    
    test('Preset deck composition', () {
      final deck = getPresetDeck(CardOwner.bingjia);
      expect(deck.length, 30);
    });
  });
  
  group('Hero Data Tests', () {
    test('Total heroes count', () {
      final heroes = getAllHeroes();
      expect(heroes.length, 21);
    });
    
    test('Heroes by class', () {
      final bingjiaHeroes = getHeroesByClass('bingjia');
      expect(bingjiaHeroes.length, 3);
    });
    
    test('Get hero by id', () {
      final hero = getHeroById('H_B001');
      expect(hero?.name, '孙膑');
    });
  });
  
  group('AI Controller Tests', () {
    test('Simple AI random behavior', () {
      final ai = AIController(difficulty: AIDifficulty.simple);
      final hand = [
        const Card(
          id: 'card1',
          name: '卡牌1',
          type: CardType.minion,
          cost: 3,
          attack: 3,
          health: 3,
          description: '',
          owner: CardOwner.neutral,
          rarity: Rarity.common,
        ),
        const Card(
          id: 'card2',
          name: '卡牌2',
          type: CardType.minion,
          cost: 5,
          attack: 5,
          health: 5,
          description: '',
          owner: CardOwner.neutral,
          rarity: Rarity.common,
        ),
      ];
      
      final ordered = ai.getOptimalPlayOrder(hand, const Player(id: 'test', hero: Hero(
        id: 'H_B001',
        name: '孙膑',
        className: 'bingjia',
        kingdom: '齐',
        health: 30,
        heroPowerName: '测试',
        heroPowerDescription: '测试',
        skillType: SkillType.defensive,
      )));
      
      expect(ordered.length, 2);
    });
    
    test('AI combo activation logic', () {
      final simpleAI = AIController(difficulty: AIDifficulty.simple);
      final hardAI = AIController(difficulty: AIDifficulty.hard);
      
      const hand = <Card>[];
      
      // 简单AI不会激活组合
      expect(simpleAI.shouldActivateCombo(hand), false);
      
      // 困难AI手牌>=5时激活
      final bigHand = List.generate(5, (i) => Card(
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
      expect(hardAI.shouldActivateCombo(bigHand), true);
    });
  });
  
  group('ELO System Tests', () {
    test('ELO expected score calculation', () {
      final score = ELOSystem.calculateExpectedScore(1000, 1000);
      expect(score, 0.5);
    });
    
    test('ELO rating change for winner', () {
      final change = ELOSystem.calculateRatingChange(
        playerRating: 1000,
        opponentRating: 1000,
        won: true,
        gameCount: 1,
      );
      expect(change, greaterThan(0));
    });
    
    test('ELO rating change for loser', () {
      final change = ELOSystem.calculateRatingChange(
        playerRating: 1000,
        opponentRating: 1000,
        won: false,
        gameCount: 1,
      );
      expect(change, lessThan(0));
    });
    
    test('Rank calculation', () {
      expect(ELOSystem.getRank(500), 'bronze3');
      expect(ELOSystem.getRank(1500), 'silver3');
      expect(ELOSystem.getRank(2500), 'gold3');
    });
    
    test('Warrior bonus calculation', () {
      expect(WarriorSystem.getWarriorBonus(winStreak: 3, loseStreak: 0, isWin: true), 1.1);
      expect(WarriorSystem.getWarriorBonus(winStreak: 5, loseStreak: 0, isWin: true), 1.3);
      expect(WarriorSystem.getWarriorBonus(winStreak: 0, loseStreak: 3, isWin: false), 0.9);
    });
    
    test('Streak update', () {
      final result = WarriorSystem.updateStreak(winStreak: 2, loseStreak: 0, won: true);
      expect(result.winStreak, 3);
      expect(result.loseStreak, 0);
    });
  });
  
  group('Fusion System Tests', () {
    test('Can fuse check', () {
      final cardIds = ['card1', 'card1', 'card1', 'card2'];
      expect(FusionSystem.canFuse(cardIds, 'card1'), true);
      expect(FusionSystem.canFuse(cardIds, 'card2'), false);
    });
    
    test('Fusion cost calculation', () {
      expect(FusionSystem.getFusionCost('common'), 25);
      expect(FusionSystem.getFusionCost('rare'), 100);
      expect(FusionSystem.getFusionCost('epic'), 400);
      expect(FusionSystem.getFusionCost('legendary'), 1600);
    });
    
    test('Fusion result card id', () {
      expect(FusionSystem.getFusedCardId('card1', 'common'), contains('upgraded_rare'));
      expect(FusionSystem.getFusedCardId('card1', 'rare'), contains('upgraded_epic'));
      expect(FusionSystem.getFusedCardId('card1', 'legendary'), isNull);
    });
  });
  
  group('Combo System Tests', () {
    test('Combo activation check', () {
      const hand = [
        Card(id: 'Z008', name: '苏秦', type: CardType.minion, cost: 0, attack: 0, health: 0, description: '', owner: CardOwner.zonghengjia, rarity: Rarity.epic),
        Card(id: 'Z009', name: '张仪', type: CardType.minion, cost: 0, attack: 0, health: 0, description: '', owner: CardOwner.zonghengjia, rarity: Rarity.epic),
      ];
      
      final recipe = ComboSystem.comboRecipes.first;
      expect(ComboSystem.checkCombo(hand, recipe), true);
    });
    
    test('Get activated combos', () {
      const hand = [
        Card(id: 'Z008', name: '苏秦', type: CardType.minion, cost: 0, attack: 0, health: 0, description: '', owner: CardOwner.zonghengjia, rarity: Rarity.epic),
        Card(id: 'Z009', name: '张仪', type: CardType.minion, cost: 0, attack: 0, health: 0, description: '', owner: CardOwner.zonghengjia, rarity: Rarity.epic),
      ];
      
      final activated = ComboSystem.getActivatedCombos(hand);
      expect(activated.isNotEmpty, true);
    });
  });
}