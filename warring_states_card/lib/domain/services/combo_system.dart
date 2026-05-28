import 'dart:math';
import '../models/models.dart';

/// 组合技能系统
class ComboSystem {
  /// 组合配方定义
  static final List<ComboRecipe> comboRecipes = [
    // 苏秦+张仪 合纵连横
    ComboRecipe(
      id: 'combo_suqin_zhangyi',
      name: '合纵连横',
      cardIds: ['Z008', 'Z009'],
      effect: 'all_minions_buff',
      description: '所有随从获得+1/+1',
    ),
    // 墨子+公输班 机关术
    ComboRecipe(
      id: 'combo_mozi_gongshuban',
      name: '机关术',
      cardIds: ['M008', 'M009'],
      effect: 'summon_mechanical',
      description: '召唤两个3/3的机关兽',
    ),
    // 邹衍+甘德 五行相生
    ComboRecipe(
      id: 'combo_zouyan_gande',
      name: '五行相生',
      cardIds: ['Y008', 'Y009'],
      effect: 'random_spells',
      description: '随机施放三个五行法术',
    ),
    // 孙膑+吴起 战国双璧
    ComboRecipe(
      id: 'combo_sunbin_wuqi',
      name: '战国双璧',
      cardIds: ['B010', 'B009'],
      effect: 'charge_battlecry',
      description: '所有友方随从获得冲锋，战吼伤害+1',
    ),
    // 孔子+老子 儒道双修
    ComboRecipe(
      id: 'combo_kongzi_laozi',
      name: '儒道双修',
      cardIds: ['R008', 'D008'],
      effect: 'draw_and_heal',
      description: '抽三张牌，恢复4点生命',
    ),
  ];
  
  /// 检查是否满足组合条件
  static bool checkCombo(List<Card> hand, ComboRecipe recipe) {
    final handIds = hand.map((c) => c.id).toSet();
    return recipe.cardIds.every((id) => handIds.contains(id));
  }
  
  /// 获取已激活的组合
  static List<ComboRecipe> getActivatedCombos(List<Card> hand) {
    return comboRecipes.where((r) => checkCombo(hand, r)).toList();
  }
  
  /// 执行组合效果
  static ComboResult executeCombo(
    ComboRecipe recipe,
    GameState state,
    String playerId,
  ) {
    switch (recipe.effect) {
      case 'all_minions_buff':
        return _buffAllMinions(state, playerId);
      case 'summon_mechanical':
        return _summonMechanical(state, playerId);
      case 'random_spells':
        return _randomSpells(state, playerId);
      case 'charge_battlecry':
        return _chargeBattlecry(state, playerId);
      case 'draw_and_heal':
        return _drawAndHeal(state, playerId);
      default:
        return ComboResult(state: state, messages: ['未知组合效果']);
    }
  }
  
  static ComboResult _buffAllMinions(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    final newBoard = player.board.map((card) => card.copyWith(
      attack: card.attack + 1,
      health: card.health + 1,
    )).toList();
    
    return ComboResult(
      state: state.updatePlayer(player.copyWith(board: newBoard)),
      messages: ['合纵连横：所有随从+1/+1'],
    );
  }
  
  static ComboResult _summonMechanical(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    if (player.isBoardFull) {
      return ComboResult(state: state, messages: ['战场已满，召唤失败']);
    }
    
    final mechanical1 = const Card(
      id: 'mech_1',
      name: '机关兽',
      type: CardType.minion,
      cost: 0,
      attack: 3,
      health: 3,
      description: '机关造物',
      owner: CardOwner.mojia,
      rarity: Rarity.common,
    );
    
    final mechanical2 = mechanical1.copyWith(id: 'mech_2');
    final newBoard = [...player.board, mechanical1, mechanical2].take(7).toList();
    
    return ComboResult(
      state: state.updatePlayer(player.copyWith(board: newBoard)),
      messages: ['机关术：召唤两个3/3机关兽'],
    );
  }
  
  static ComboResult _randomSpells(GameState state, String playerId) {
    final random = Random();
    final messages = <String>[];
    
    // 简化的随机法术效果
    final effects = [
      '造成3点随机伤害',
      '恢复3点生命',
      '随机随从获得+2/+2',
    ];
    
    messages.add('五行相生：');
    for (int i = 0; i < 3; i++) {
      final effect = effects[random.nextInt(effects.length)];
      messages.add('  $effect');
    }
    
    return ComboResult(state: state, messages: messages);
  }
  
  static ComboResult _chargeBattlecry(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    final newBoard = player.board.map((card) {
      final keywords = [...card.keywords];
      if (!keywords.contains(Keyword.charge)) {
        keywords.add(Keyword.charge);
      }
      return card.copyWith(keywords: keywords);
    }).toList();
    
    return ComboResult(
      state: state.updatePlayer(player.copyWith(board: newBoard)),
      messages: ['战国双璧：所有随从获得冲锋'],
    );
  }
  
  static ComboResult _drawAndHeal(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    
    // 抽三张牌
    final newDeck = List<Card>.from(player.deck);
    final drawnCards = newDeck.take(3).toList();
    final remainingDeck = newDeck.skip(3).toList();
    
    // 恢复4点生命
    final newHealth = (player.health + 4).clamp(0, 30);
    
    return ComboResult(
      state: state.updatePlayer(player.copyWith(
        deck: remainingDeck,
        hand: [...player.hand, ...drawnCards],
        health: newHealth,
      )),
      messages: ['儒道双修：抽三张牌，恢复4点生命'],
    );
  }
}

/// 组合配方
class ComboRecipe {
  final String id;
  final String name;
  final List<String> cardIds;
  final String effect;
  final String description;
  
  const ComboRecipe({
    required this.id,
    required this.name,
    required this.cardIds,
    required this.effect,
    required this.description,
  });
}

/// 组合效果结果
class ComboResult {
  final GameState state;
  final List<String> messages;
  
  const ComboResult({
    required this.state,
    required this.messages,
  });
}