import 'dart:math';

import '../models/card.dart' as domain;
import '../models/models.dart';
import '../models/roguelite_run.dart';
import 'adventure_manager.dart';
import 'card_data_provider.dart';

/// Roguelite 服务 — 路径生成 + 征途生命周期
class RogueliteService {
  final AdventureManager _manager = AdventureManager();
  final Random _rng = Random();

  /// 为指定章节和分段生成征途路径
  /// 每章分 2 段：前 5 关 + Boss，后 5 关 + Boss
  List<List<RogueliteNode>> generatePath(String chapterId, int segment) {
    final chapter = _manager.getChapter(chapterId);
    if (chapter == null) return [];

    final startIdx = segment == 0 ? 0 : 5;
    final missions = chapter.missions.sublist(startIdx, startIdx + 6); // 5 normal + Boss

    final layers = <List<RogueliteNode>>[];
    var nodeId = 0;

    for (var i = 0; i < missions.length; i++) {
      final mission = missions[i];
      final isLast = mission.isBoss;

      if (i == 0 || isLast) {
        // 第一层/最后一层：只有战斗节点
        layers.add([
          RogueliteNode(
            id: 'n${nodeId++}',
            type: isLast ? RogueliteNodeType.boss : RogueliteNodeType.battle,
            missionId: mission.id,
            title: mission.name,
            description: mission.description,
            layer: layers.length,
          ),
        ]);
      } else {
        // 中间层：Battle + 随机 Rest/Shop
        final choices = <RogueliteNode>[
          RogueliteNode(
            id: 'n${nodeId++}',
            type: RogueliteNodeType.battle,
            missionId: mission.id,
            title: mission.name,
            description: mission.description,
            layer: layers.length,
          ),
        ];
        // 50% 概率出现 Rest 或 Shop
        if (_rng.nextBool()) {
          choices.add(RogueliteNode(
            id: 'n${nodeId++}',
            type: RogueliteNodeType.rest,
            missionId: '${mission.id}_rest',
            title: '休整',
            description: '恢复 10 点生命值',
            layer: layers.length,
          ));
        } else {
          choices.add(RogueliteNode(
            id: 'n${nodeId++}',
            type: RogueliteNodeType.shop,
            missionId: '${mission.id}_shop',
            title: '集市',
            description: '花费金币购买卡牌',
            layer: layers.length,
          ));
        }
        layers.add(choices);
      }
    }

    return layers;
  }

  /// 开始新的征途
  RogueliteRun startRun(String heroId, String chapterId, int segment) {
    final layers = generatePath(chapterId, segment);
    final allNodes = layers.expand((l) => l).toList();

    return RogueliteRun(
      heroId: heroId,
      chapterId: chapterId,
      segment: segment,
      currentNodeId: allNodes.first.id,
      allNodes: allNodes,
      layers: layers,
    );
  }

  /// 获取当前节点
  RogueliteNode? getCurrentNode(RogueliteRun run) {
    try {
      return run.allNodes.firstWhere((n) => n.id == run.currentNodeId);
    } catch (_) {
      return null;
    }
  }

  /// 获取下一层可选节点
  List<RogueliteNode> getNextLayerNodes(RogueliteRun run) {
    final nextLayer = run.currentLayer + 1;
    if (nextLayer >= run.layers.length) return [];
    return run.layers[nextLayer];
  }

  /// 获取随机卡牌奖励（3 张随从卡供选择）
  List<domain.Card> getRandomRewardCards({CardOwner? owner}) {
    final all = CardDataProvider.getAllCards();
    final pool = owner != null
        ? all.where((c) => c.owner == owner && c.isMinion).toList()
        : all.where((c) => c.isMinion).toList();

    if (pool.isEmpty) return [];
    pool.shuffle(_rng);
    return pool.take(3).toList();
  }
}
