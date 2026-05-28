import 'dart:math';
import '../models/models.dart';

/// 抽卡保底系统
class DrawService {
  /// 稀有度概率分布 (合规)
  static const Map<Rarity, double> rarityProbabilities = {
    Rarity.common: 0.70,      // 70%
    Rarity.rare: 0.25,        // 25%
    Rarity.epic: 0.04,        // 4%
    Rarity.legendary: 0.01,   // 1%
  };
  
  /// 保底阈值
  static const Map<Rarity, int> pityThresholds = {
    Rarity.rare: 10,        // 10抽保底稀有
    Rarity.epic: 20,        // 20抽保底史诗
    Rarity.legendary: 50,    // 50抽保底传说
  };
  
  /// 基础概率
  static const Map<Rarity, double> baseProbabilities = {
    Rarity.common: 0.70,
    Rarity.rare: 0.25,
    Rarity.epic: 0.04,
    Rarity.legendary: 0.01,
  };
  
  /// 保底概率增量(每次不中+1%)
  static const double pityIncrement = 0.01;
  
  /// 保底上限(100%)
  static const double pityCap = 1.0;
  
  final Random _random;
  
  DrawService() : _random = Random.secure();
  
  /// 抽一张卡
  DrawResult draw() {
    // 简化：直接用概率分布
    final roll = _random.nextDouble();
    double cumulative = 0;
    
    for (final entry in rarityProbabilities.entries) {
      cumulative += entry.value;
      if (roll < cumulative) {
        return DrawResult(
          rarity: entry.key,
          isPityTriggered: false,
          pityCount: 0,
        );
      }
    }
    
    // 默认返回普通
    return DrawResult(
      rarity: Rarity.common,
      isPityTriggered: false,
      pityCount: 0,
    );
  }
  
  /// 保底抽卡
  DrawResult drawWithPity({
    required int currentPityCount,
    required Rarity targetRarity,
  }) {
    // 计算当前概率(基础+保底加成)
    double currentProb = baseProbabilities[targetRarity]!;
    double pityBonus = (currentPityCount * pityIncrement).clamp(0, pityCap - currentProb);
    double adjustedProb = currentProb + pityBonus;
    
    final roll = _random.nextDouble();
    
    if (roll < adjustedProb) {
      // 命中
      return DrawResult(
        rarity: targetRarity,
        isPityTriggered: currentPityCount >= pityThresholds[targetRarity]!,
        pityCount: 0, // 重置
      );
    }
    
    // 未命中，增加保底计数
    return DrawResult(
      rarity: Rarity.common, // 保底未触发时给普通
      isPityTriggered: false,
      pityCount: currentPityCount + 1,
    );
  }
  
  /// 十连抽
  List<DrawResult> drawTen() {
    final results = <DrawResult>[];
    int rarePity = 0;
    int epicPity = 0;
    int legendaryPity = 0;
    
    for (int i = 0; i < 10; i++) {
      // 检查传说保底
      if (legendaryPity >= pityThresholds[Rarity.legendary]!) {
        results.add(DrawResult(
          rarity: Rarity.legendary,
          isPityTriggered: true,
          pityCount: 0,
        ));
        legendaryPity = 0;
        rarePity++;
      }
      // 检查史诗保底
      else if (epicPity >= pityThresholds[Rarity.epic]!) {
        results.add(DrawResult(
          rarity: Rarity.epic,
          isPityTriggered: true,
          pityCount: 0,
        ));
        epicPity = 0;
        rarePity++;
      }
      // 检查稀有保底
      else if (rarePity >= pityThresholds[Rarity.rare]!) {
        results.add(DrawResult(
          rarity: Rarity.rare,
          isPityTriggered: true,
          pityCount: 0,
        ));
        rarePity = 0;
      }
      // 普通抽卡
      else {
        final result = draw();
        results.add(result);
        
        // 更新保底计数
        switch (result.rarity) {
          case Rarity.common:
            rarePity++;
            epicPity++;
            legendaryPity++;
            break;
          case Rarity.rare:
            rarePity = 0;
            epicPity++;
            legendaryPity++;
            break;
          case Rarity.epic:
            rarePity = 0;
            epicPity = 0;
            legendaryPity++;
            break;
          case Rarity.legendary:
            rarePity = 0;
            epicPity = 0;
            legendaryPity = 0;
            break;
        }
      }
    }
    
    return results;
  }
  
  /// 获取保底信息
  static Map<Rarity, PityInfo> getPityInfo({
    required int rarePityCount,
    required int epicPityCount,
    required int legendaryPityCount,
  }) {
    return {
      Rarity.rare: PityInfo(
        currentCount: rarePityCount,
        threshold: pityThresholds[Rarity.rare]!,
        currentProbability: baseProbabilities[Rarity.rare]! + 
          (rarePityCount * pityIncrement).clamp(0, 0.25),
      ),
      Rarity.epic: PityInfo(
        currentCount: epicPityCount,
        threshold: pityThresholds[Rarity.epic]!,
        currentProbability: baseProbabilities[Rarity.epic]! + 
          (epicPityCount * pityIncrement).clamp(0, 0.04),
      ),
      Rarity.legendary: PityInfo(
        currentCount: legendaryPityCount,
        threshold: pityThresholds[Rarity.legendary]!,
        currentProbability: baseProbabilities[Rarity.legendary]! + 
          (legendaryPityCount * pityIncrement).clamp(0, 0.01),
      ),
    };
  }
}

/// 抽卡结果
class DrawResult {
  final Rarity rarity;
  final bool isPityTriggered;
  final int pityCount;
  
  const DrawResult({
    required this.rarity,
    required this.isPityTriggered,
    required this.pityCount,
  });
  
  String get rarityName {
    switch (rarity) {
      case Rarity.common:
        return '普通';
      case Rarity.rare:
        return '稀有';
      case Rarity.epic:
        return '史诗';
      case Rarity.legendary:
        return '传说';
    }
  }
}

/// 保底信息
class PityInfo {
  final int currentCount;
  final int threshold;
  final double currentProbability;
  
  const PityInfo({
    required this.currentCount,
    required this.threshold,
    required this.currentProbability,
  });
  
  int get remaining {
    return (threshold - currentCount).clamp(0, threshold);
  }
  
  double get progress {
    return currentCount / threshold;
  }
  
  String get description {
    return '还需抽 $remaining 张保底 (概率: ${(currentProbability * 100).toStringAsFixed(1)}%)';
  }
}

/// 概率公示数据
class ProbabilityDisclosure {
  /// 基础概率分布
  static Map<String, dynamic> getBaseProbabilities() {
    return {
      'common': {'probability': 0.70, 'description': '普通卡'},
      'rare': {'probability': 0.25, 'description': '稀有卡'},
      'epic': {'probability': 0.04, 'description': '史诗卡'},
      'legendary': {'probability': 0.01, 'description': '传说卡'},
    };
  }
  
  /// 保底机制
  static Map<String, dynamic> getPityMechanism() {
    return {
      'rare': {'pulls': 10, 'description': '每10抽保底稀有'},
      'epic': {'pulls': 20, 'description': '每20抽保底史诗'},
      'legendary': {'pulls': 50, 'description': '每50抽保底传说'},
    };
  }
  
  /// 概率递增机制
  static Map<String, dynamic> getProbabilityIncrease() {
    return {
      'increment_per_pull': 0.01,
      'cap': 1.0,
      'description': '每次不中相应稀有度，保底概率+1%，封顶100%',
    };
  }
  
  /// 生成合规公示文本
  static String generateDisclosureText() {
    final base = getBaseProbabilities();
    final pity = getPityMechanism();
    final increase = getProbabilityIncrease();
    
    return '''
卡牌抽取概率公示

一、基础概率
普通卡: ${((base['common']!['probability'] as double) * 100).toStringAsFixed(1)}%
稀有卡: ${((base['rare']!['probability'] as double) * 100).toStringAsFixed(1)}%
史诗卡: ${((base['epic']!['probability'] as double) * 100).toStringAsFixed(1)}%
传说卡: ${((base['legendary']!['probability'] as double) * 100).toStringAsFixed(1)}%

二、保底机制
- 稀有卡: 每${pity['rare']!['pulls']}抽必出
- 史诗卡: 每${pity['epic']!['pulls']}抽必出
- 传说卡: 每${pity['legendary']!['pulls']}抽必出

三、概率递增
${increase['description']}

四、公示日期
2024年1月1日

最终解释权归游戏运营方所有
''';
  }
}