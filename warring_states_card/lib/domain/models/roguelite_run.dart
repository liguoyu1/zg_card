import 'card.dart';

/// 路径节点类型
enum RogueliteNodeType { battle, boss, rest, shop }

/// 路径节点 — 一条征途上的一个步骤
class RogueliteNode { // 第几层（0 = 起点）

  const RogueliteNode({
    required this.id,
    required this.type,
    required this.missionId,
    required this.title,
    required this.description,
    required this.layer,
  });
  final String id;
  final RogueliteNodeType type;
  final String missionId; // 对应原冒险任务 ID（battle/boss 类型）
  final String title;
  final String description;
  final int layer;
}

/// 征途结果
enum RunResult { active, won, lost }

/// 征途状态 — 一次 Roguelite 旅程
class RogueliteRun {

  RogueliteRun({
    required this.heroId,
    required this.chapterId,
    required this.segment,
    this.currentHp = 30,
    this.maxHp = 30,
    this.gold = 0,
    this.currentLayer = 0,
    required this.currentNodeId,
    required this.allNodes,
    required this.layers,
    List<Card>? tempDeck,
    this.result = RunResult.active,
    this.failCount = 0,
    this.maxFails = 3,
  }) : tempDeck = tempDeck ?? [];
  final String heroId;
  final String chapterId;
  final int segment;
  int currentHp;
  final int maxHp;
  int gold;
  int currentLayer;
  String currentNodeId;
  final List<RogueliteNode> allNodes;
  final List<List<RogueliteNode>> layers;
  final List<Card> tempDeck;
  RunResult result;
  int failCount; // 本征途失败次数
  final int maxFails;

  bool get isActive => result == RunResult.active;

  /// 是否可以前往指定层（只能去下一层或当前层）
  bool canAccess(int layer) => isActive && layer <= currentLayer + 1;

  /// 是否可以访问指定节点（只能访问当前层的节点或下一层已解锁的节点）
  bool canAccessNode(RogueliteNode node) {
    if (!isActive) return false;
    if (node.layer < currentLayer) return false;
    return node.layer <= currentLayer + 1;
  }

  /// 进入节点（征途推进到该层）
  void enterNode(RogueliteNode node) {
    currentNodeId = node.id;
    if (node.layer > currentLayer) {
      currentLayer = node.layer;
    }
  }

  /// 应用战斗结果
  void applyBattleResult(int remainingHp, int goldEarned, {List<Card>? newCards}) {
    currentHp = remainingHp;
    gold += goldEarned;
    if (newCards != null) tempDeck.addAll(newCards);
    if (currentHp <= 0) {
      currentHp = 0;
      result = RunResult.lost;
    }
  }

  /// 休息（恢复 10 HP，不超过上限）
  void rest() {
    currentHp = (currentHp + 10).clamp(0, maxHp);
  }

  /// 检查是否为最后一场战斗（当前层的所有节点都是 Boss）
  bool isLastLayer() {
    if (layers.isEmpty) return false;
    return currentLayer >= layers.length - 1;
  }
}

/// 征途结果（从 GameScreen 返回）
class RogueliteResult {

  const RogueliteResult({
    required this.victory,
    this.remainingHp = 0,
    this.goldEarned = 0,
  });
  final bool victory;
  final int remainingHp;
  final int goldEarned;
}

// RogueliteRun serialization
extension RogueliteRunJson on RogueliteRun {
  Map<String, dynamic> toJson() => {
    'heroId': heroId,
    'chapterId': chapterId,
    'segment': segment,
    'currentHp': currentHp,
    'maxHp': maxHp,
    'gold': gold,
    'currentLayer': currentLayer,
    'currentNodeId': currentNodeId,
    'allNodes': allNodes.map((n) => {
      'id': n.id, 'type': n.type.name, 'missionId': n.missionId,
      'title': n.title, 'description': n.description, 'layer': n.layer,
    }).toList(),
    'layers': layers.map((l) => l.map((n) => {
      'id': n.id, 'type': n.type.name, 'missionId': n.missionId,
      'title': n.title, 'description': n.description, 'layer': n.layer,
    }).toList()).toList(),
    'tempDeck': tempDeck.map((c) => c.id).toList(),
    'result': result.name,
    'failCount': failCount,
    'maxFails': maxFails,
  };
}

RogueliteRun rogueliteRunFromJson(Map<String, dynamic> j) => RogueliteRun(
    heroId: j['heroId'],
    chapterId: j['chapterId'],
    segment: j['segment'] ?? 0,
    currentHp: j['currentHp'] ?? 30,
    maxHp: j['maxHp'] ?? 30,
    gold: j['gold'] ?? 0,
    currentLayer: j['currentLayer'] ?? 0,
    currentNodeId: j['currentNodeId'],
    allNodes: _nodesFrom(j['allNodes']),
    layers: (j['layers'] as List).map((l) => _nodesFrom(l)).toList(),
    tempDeck: const [],
    result: RunResult.values.firstWhere((r) => r.name == j['result'], orElse: () => RunResult.active),
    failCount: j['failCount'] ?? 0,
    maxFails: j['maxFails'] ?? 3,
  );

List<RogueliteNode> _nodesFrom(dynamic list) =>
    (list as List).map((j) => RogueliteNode(
      id: j['id'], type: RogueliteNodeType.values.firstWhere((t) => t.name == j['type']),
      missionId: j['missionId'], title: j['title'],
      description: j['description'], layer: j['layer'],
    )).toList();
