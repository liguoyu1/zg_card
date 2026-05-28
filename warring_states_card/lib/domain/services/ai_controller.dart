import 'dart:math';
import '../models/models.dart';

/// AI难度等级
enum AIDifficulty { simple, normal, hard, abyss }

/// AI控制器
class AIController {
  final AIDifficulty difficulty;
  final Random _random = Random();
  
  AIController({this.difficulty = AIDifficulty.normal});
  
  /// 获取最优出牌顺序
  List<Card> getOptimalPlayOrder(List<Card> hand, Player board) {
    switch (difficulty) {
      case AIDifficulty.simple:
        return hand..shuffle(_random);
      case AIDifficulty.normal:
        return _sortByPriority(hand);
      case AIDifficulty.hard:
        return _sortBySynergy(hand, board);
      case AIDifficulty.abyss:
        return _sortByOptimal(hand, board);
    }
  }
  
  /// 优先级排序
  List<Card> _sortByPriority(List<Card> hand) {
    return hand.toList()
      ..sort((a, b) => b.cost.compareTo(a.cost)); // 高费优先
  }
  
  /// 根据配合排序
  List<Card> _sortBySynergy(List<Card> hand, Player board) {
    return hand.toList()
      ..sort((a, b) {
        // 优先出有战吼的
        if (a.hasBattlecry && !b.hasBattlecry) return -1;
        if (!a.hasBattlecry && b.hasBattlecry) return 1;
        // 其次按费用
        return b.cost.compareTo(a.cost);
      });
  }
  
  /// 最优排序
  List<Card> _sortByOptimal(List<Card> hand, Player board) {
    return hand.toList()
      ..sort((a, b) {
        // 战吼优先
        if (a.hasBattlecry && !b.hasBattlecry) return -1;
        if (!a.hasBattlecry && b.hasBattlecry) return 1;
        // 嘲讽优先(如果场上有威胁)
        if (a.hasTaunt && !b.hasTaunt) return -1;
        if (!a.hasTaunt && b.hasTaunt) return 1;
        // 按费用排序
        return b.cost.compareTo(a.cost);
      });
  }
  
  /// 选择攻击目标
  Card? selectAttackTarget(Player self, Player opponent) {
    switch (difficulty) {
      case AIDifficulty.simple:
        return _randomAttack(opponent);
      case AIDifficulty.normal:
        return _tauntFirstAttack(opponent);
      case AIDifficulty.hard:
        return _calculatedAttack(self, opponent);
      case AIDifficulty.abyss:
        return _optimalAttack(self, opponent);
    }
  }
  
  /// 随机攻击
  Card? _randomAttack(Player opponent) {
    if (opponent.board.isEmpty) return null;
    return opponent.board[_random.nextInt(opponent.board.length)];
  }
  
  /// 嘲讽优先
  Card? _tauntFirstAttack(Player opponent) {
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) {
      return taunts[_random.nextInt(taunts.length)];
    }
    return _randomAttack(opponent);
  }
  
  /// 计算后攻击
  Card? _calculatedAttack(Player self, Player opponent) {
    if (opponent.board.isEmpty) return null;
    
    // 嘲讽优先
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) {
      // 选择血量最低的嘲讽
      return taunts.reduce((a, b) => a.health < b.health ? a : b);
    }
    
    // 优先攻击能杀死的
    final killable = opponent.board.where((c) => c.health <= self.board.first.attack).toList();
    if (killable.isNotEmpty) {
      return killable[_random.nextInt(killable.length)];
    }
    
    return opponent.board[_random.nextInt(opponent.board.length)];
  }
  
  /// 最优攻击
  Card? _optimalAttack(Player self, Player opponent) {
    if (opponent.board.isEmpty) return null;
    
    // 嘲讽优先
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) {
      return taunts.reduce((a, b) => a.health < b.health ? a : b);
    }
    
    // 优先清除威胁(攻击力高的)
    final sorted = opponent.board.toList()
      ..sort((a, b) => b.attack.compareTo(a.attack));
    
    // 计算最优交换
    for (final attacker in self.board) {
      for (final target in sorted) {
        if (target.health <= attacker.attack && attacker.health > target.attack) {
          return target;
        }
      }
    }
    
    // 否则攻击血量最低的
    return sorted.last;
  }
  
  /// 是否激活组合技能
  bool shouldActivateCombo(List<Card> hand) {
    switch (difficulty) {
      case AIDifficulty.simple:
        return false;
      case AIDifficulty.normal:
        return _random.nextBool();
      case AIDifficulty.hard:
        return hand.length >= 5;
      case AIDifficulty.abyss:
        return hand.length >= 3;
    }
  }
  
  /// 是否升级卡牌
  bool shouldUpgradeCard(Card card, int upgradeCount) {
    switch (difficulty) {
      case AIDifficulty.simple:
        return false;
      case AIDifficulty.normal:
        return _random.nextBool();
      case AIDifficulty.hard:
        return upgradeCount >= 2;
      case AIDifficulty.abyss:
        return true;
    }
  }
  
  /// 使用技能时机
  bool shouldUseHeroPower(GameState state) {
    switch (difficulty) {
      case AIDifficulty.simple:
        return _random.nextBool();
      case AIDifficulty.normal:
        return state.activePlayer.mana >= 2;
      case AIDifficulty.hard:
        return _shouldUseInOptimalTime(state);
      case AIDifficulty.abyss:
        return _shouldUseInOptimalTime(state);
    }
  }
  
  bool _shouldUseInOptimalTime(GameState state) {
    final player = state.activePlayer;
    // 简单判断：手牌多或有高费牌时优先使用技能
    return player.mana >= 2 && player.handCount < 5;
  }
}