import 'dart:math';
import '../models/models.dart';

/// AI难度等级
enum AIDifficulty { simple, normal, hard, abyss }

/// AI控制器
class AIController {
  
  AIController({this.difficulty = AIDifficulty.normal});
  final AIDifficulty difficulty;
  final Random _random = Random();
  
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
  
  /// 优先级排序：随从优先于法术，嘲讽/冲锋优先，高费优先
  List<Card> _sortByPriority(List<Card> hand) {
    return hand.toList()..sort((a, b) {
      // 随从优先于法术
      if (a.isMinion && !b.isMinion) return -1;
      if (!a.isMinion && b.isMinion) return 1;
      // 嘲讽/冲锋优先
      final aKey = a.hasTaunt || a.hasCharge ? 1 : 0;
      final bKey = b.hasTaunt || b.hasCharge ? 1 : 0;
      if (aKey != bKey) return bKey.compareTo(aKey);
      // 高费优先
      return b.cost.compareTo(a.cost);
    });
  }
  
  /// 根据配合排序（带战场感知）
  List<Card> _sortBySynergy(List<Card> hand, Player board) {
    return hand.toList()..sort((a, b) {
      // 如果场上没有随从，优先出随从
      if (board.board.isEmpty) {
        if (a.isMinion && !b.isMinion) return -1;
        if (!a.isMinion && b.isMinion) return 1;
      }
      // 战吼优先
      if (a.hasBattlecry && !b.hasBattlecry) return -1;
      if (!a.hasBattlecry && b.hasBattlecry) return 1;
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
  
  /// 嘲讽优先，其次低血量目标（< 3 health）
  Card? _tauntFirstAttack(Player opponent) {
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) return taunts.reduce((a, b) => a.health < b.health ? a : b);
    // 优先低血量随从
    final lowHealth = opponent.board.where((c) => c.health < 3).toList();
    if (lowHealth.isNotEmpty) return lowHealth.first;
    if (opponent.board.isEmpty) return null;
    return opponent.board.first;
  }
  
  /// 价值计算攻击（优先1换2的有利交换）
  Card? _calculatedAttack(Player self, Player opponent) {
    if (opponent.board.isEmpty) return null;
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) return taunts.reduce((a, b) => a.health < b.health ? a : b);
    // 优先攻击能杀死的
    for (final attacker in self.board) {
      final killable = opponent.board.where((c) => c.health <= attacker.attack && attacker.health > c.attack).toList();
      if (killable.isNotEmpty) return killable.reduce((a, b) => a.attack > b.attack ? a : b);
    }
    return opponent.board.reduce((a, b) => a.health < b.health ? a : b);
  }
  
  /// 最优攻击（2回合预判：优先清除高威胁低血量目标）
  Card? _optimalAttack(Player self, Player opponent) {
    if (opponent.board.isEmpty) return null;
    final taunts = opponent.board.where((c) => c.hasTaunt).toList();
    if (taunts.isNotEmpty) return taunts.reduce((a, b) => a.health < b.health ? a : b);
    // 预判：优先清除高威胁（高攻击）低血量目标
    final threats = opponent.board.where((c) => c.attack >= 4 && c.health <= self.board.map((e) => e.attack).fold(0, (a, b) => a > b ? a : b)).toList();
    if (threats.isNotEmpty) return threats.reduce((a, b) => a.attack > b.attack ? a : b);
    for (final attacker in self.board) {
      for (final target in opponent.board) {
        if (target.health <= attacker.attack && attacker.health > target.attack) return target;
      }
    }
    return opponent.board.reduce((a, b) => a.health < b.health ? a : b);
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