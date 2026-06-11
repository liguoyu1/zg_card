import 'card.dart';
import 'mission_context.dart';

/// 路径节点类型
enum RogueliteNodeType { battle, boss, rest, shop }

/// 路径节点 — 一条征途上的一个步骤
class RogueliteNode {
  final String id;
  final RogueliteNodeType type;
  final String missionId; // 对应原冒险任务 ID（battle/boss 类型）
  final String title;
  final String description;
  final int layer; // 第几层（0 = 起点）

  const RogueliteNode({
    required this.id,
    required this.type,
    required this.missionId,
    required this.title,
    required this.description,
    required this.layer,
  });
}

/// 征途结果
enum RunResult { active, won, lost }

/// 征途状态 — 一次 Roguelite 旅程
class RogueliteRun {
  final String heroId;
  final String chapterId;
  final int segment; // 第几段（每章 2 段，各 5 关 + 1 Boss）
  int currentHp;
  final int maxHp;
  int gold;
  int currentLayer;
  String currentNodeId;
  final List<RogueliteNode> allNodes;
  final List<List<RogueliteNode>> layers; // 按层分组
  final List<Card> tempDeck; // 征途中获得的额外卡牌
  RunResult result;

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
  }) : tempDeck = tempDeck ?? [];

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
  final bool victory;
  final int remainingHp;
  final int goldEarned;

  const RogueliteResult({
    required this.victory,
    this.remainingHp = 0,
    this.goldEarned = 0,
  });
}
