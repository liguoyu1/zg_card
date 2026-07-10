
/// 合成系统
class FusionSystem {
  /// 合成所需同名牌数量
  static const int fusionRequired = 3;
  
  /// 合成消耗(尘)
  static const Map<String, int> dustCost = {
    'common': 25,
    'rare': 100,
    'epic': 400,
    'legendary': 1600,
  };
  
  /// 分解返还(尘)
  static const Map<String, int> dustReturn = {
    'common': 5,
    'rare': 20,
    'epic': 100,
    'legendary': 400,
  };
  
  /// 升级后分解返还增加50%
  static const double upgradedReturnBonus = 1.5;
  
  /// 检查是否可以合成
  static bool canFuse(List<String> cardIds, String cardId) {
    final count = cardIds.where((id) => id == cardId).length;
    return count >= fusionRequired;
  }
  
  /// 获取合成结果
  static String? getFusedCardId(String cardId, String rarity) {
    switch (rarity) {
      case 'common':
        return '${cardId}_upgraded_rare';
      case 'rare':
        return '${cardId}_upgraded_epic';
      case 'epic':
        return '${cardId}_upgraded_legendary';
      case 'legendary':
        return null; // 最高品质无法合成
      default:
        return null;
    }
  }
  
  /// 获取合成消耗
  static int getFusionCost(String rarity) {
    return dustCost[rarity] ?? 25;
  }
  
  /// 获取分解返还
  static int getDisenchantReturn(String rarity, {bool isUpgraded = false}) {
    final base = dustReturn[rarity] ?? 5;
    return isUpgraded ? (base * upgradedReturnBonus).round() : base;
  }
}