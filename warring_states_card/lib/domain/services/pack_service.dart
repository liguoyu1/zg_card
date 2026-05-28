import 'dart:math';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/domain/services/elo_system.dart';

/// 开包服务
class PackService {
  final Random _random = Random();
  
  /// 抽卡保底计数器
  final Map<String, int> _pityCounters = {};
  
  /// 抽一次卡
  PackResult drawOne(List<Card> pool, {String? owner}) {
    // 过滤卡池
    var availableCards = pool.where((c) => 
      owner == null || c.owner.name == owner
    ).toList();
    
    // 检查保底
    final key = owner ?? 'all';
    final pityCount = _pityCounters[key] ?? 0;
    
    Card? result;
    
    // 保底逻辑：每30抽保底一张稀有或更高
    if (pityCount >= 29) {
      final guaranteedRarity = _getGuaranteedRarity();
      final guaranteed = availableCards.where((c) => 
        _getRarityWeight(c.rarity) >= _getRarityWeight(guaranteedRarity)
      ).toList();
      if (guaranteed.isNotEmpty) {
        result = _weightedRandom(guaranteed);
        _pityCounters[key] = 0;
      }
    }
    
    result ??= _weightedRandom(availableCards);
    
    // 更新保底计数
    if (_getRarityWeight(result.rarity) < _getRarityWeight(Rarity.rare)) {
      _pityCounters[key] = (_pityCounters[key] ?? 0) + 1;
    } else {
      _pityCounters[key] = 0;
    }
    
    return PackResult(
      cards: [result],
      totalCost: 100, // 金币消耗
    );
  }
  
  /// 开一包（5张）
  PackResult openPack(List<Card> pool, {String? owner, int count = 5}) {
    final cards = <Card>[];
    
    for (int i = 0; i < count; i++) {
      final result = drawOne(pool, owner: owner);
      cards.add(result.cards.first);
    }
    
    return PackResult(
      cards: cards,
      totalCost: 100 * count,
    );
  }
  
  /// 十连抽（保底一张稀有）
  PackResult drawTen(List<Card> pool, {String? owner}) {
    final cards = <Card>[];
    
    for (int i = 0; i < 9; i++) {
      final result = drawOne(pool, owner: owner);
      cards.add(result.cards.first);
    }
    
    // 第10抽保底稀有
    final guaranteedRarity = Rarity.rare;
    var availableCards = pool.where((c) => 
      (owner == null || c.owner.name == owner) &&
      _getRarityWeight(c.rarity) >= _getRarityWeight(guaranteedRarity)
    ).toList();
    
    if (availableCards.isEmpty) {
      availableCards = pool.where((c) => owner == null || c.owner.name == owner).toList();
    }
    
    cards.add(_weightedRandom(availableCards));
    
    return PackResult(
      cards: cards,
      totalCost: 1000, // 金币消耗
    );
  }
  
  Rarity _getGuaranteedRarity() {
    final roll = _random.nextDouble();
    if (roll < 0.1) return Rarity.legendary; // 10%传说
    if (roll < 0.3) return Rarity.epic; // 20%史诗
    return Rarity.rare; // 70%稀有
  }
  
  int _getRarityWeight(Rarity rarity) {
    switch (rarity) {
      case Rarity.common: return 1;
      case Rarity.rare: return 2;
      case Rarity.epic: return 3;
      case Rarity.legendary: return 4;
    }
  }
  
  Card _weightedRandom(List<Card> cards) {
    // 按稀有度权重
    final weights = cards.map((c) => 1.0 / _getRarityWeight(c.rarity)).toList();
    final totalWeight = weights.reduce((a, b) => a + b);
    var roll = _random.nextDouble() * totalWeight;
    
    for (int i = 0; i < cards.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return cards[i];
    }
    
    return cards.last;
  }
}

/// 抽卡结果
class PackResult {
  final List<Card> cards;
  final int totalCost;
  
  PackResult({required this.cards, required this.totalCost});
  
  bool get hasLegendary => cards.any((c) => c.rarity == Rarity.legendary);
  bool get hasEpic => cards.any((c) => c.rarity == Rarity.epic);
  bool get hasRare => cards.any((c) => c.rarity == Rarity.rare);
  
  String get summary {
    final parts = <String>[];
    if (hasLegendary) parts.add('传说');
    if (hasEpic) parts.add('史诗');
    if (hasRare) parts.add('稀有');
    return parts.isEmpty ? '普通' : parts.join('/');
  }
}

/// 任务系统
class QuestService {
  final List<Quest> _dailyQuests = [];
  final List<Quest> _weeklyQuests = [];
  
  /// 获取每日任务
  List<Quest> getDailyQuests() {
    if (_dailyQuests.isEmpty) {
      _dailyQuests.addAll(_generateDailyQuests());
    }
    return _dailyQuests;
  }
  
  /// 获取每周任务
  List<Quest> getWeeklyQuests() {
    if (_weeklyQuests.isEmpty) {
      _weeklyQuests.addAll(_generateWeeklyQuests());
    }
    return _weeklyQuests;
  }
  
  /// 刷新每日任务
  void refreshDailyQuests() {
    _dailyQuests.clear();
    _dailyQuests.addAll(_generateDailyQuests());
  }
  
  /// 刷新每周任务
  void refreshWeeklyQuests() {
    _weeklyQuests.clear();
    _weeklyQuests.addAll(_generateWeeklyQuests());
  }
  
  List<Quest> _generateDailyQuests() {
    return [
      Quest(
        id: 'daily_win_1',
        name: '首胜',
        description: '赢得1场对战',
        target: 1,
        progress: 0,
        rewardGold: 50,
        rewardExp: 20,
      ),
      Quest(
        id: 'daily_win_3',
        name: '连胜',
        description: '赢得3场对战',
        target: 3,
        progress: 0,
        rewardGold: 150,
        rewardExp: 50,
      ),
      Quest(
        id: 'daily_draw_10',
        name: '抽卡',
        description: '开启10次卡包',
        target: 10,
        progress: 0,
        rewardGold: 100,
        rewardExp: 30,
      ),
    ];
  }
  
  List<Quest> _generateWeeklyQuests() {
    return [
      Quest(
        id: 'weekly_win_10',
        name: '周胜',
        description: '本周赢得10场对战',
        target: 10,
        progress: 0,
        rewardGold: 500,
        rewardExp: 200,
      ),
      Quest(
        id: 'weekly_rank_up',
        name: '段位提升',
        description: '提升一个段位',
        target: 1,
        progress: 0,
        rewardGold: 800,
        rewardExp: 300,
      ),
    ];
  }
}

/// 任务
class Quest {
  final String id;
  final String name;
  final String description;
  final int target;
  int progress;
  final int rewardGold;
  final int rewardExp;
  bool isCompleted;
  
  Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.progress,
    required this.rewardGold,
    required this.rewardExp,
    this.isCompleted = false,
  });
  
  double get progressPercent => (progress / target).clamp(0.0, 1.0);
  
  /// 更新进度
  void updateProgress(int delta) {
    if (!isCompleted) {
      progress = (progress + delta).clamp(0, target);
      if (progress >= target) {
        isCompleted = true;
      }
    }
  }
}