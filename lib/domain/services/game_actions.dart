/// 联机对局动作编解码层。
///
/// 真联机依赖两端用**同一确定性引擎** + **同一 seed** 独立演进。
/// 每个玩家操作编码为一个 action，提交到后端中继；两端各自 poll 到全量动作后，
/// 按全局 seq 排序，在本端 GameState 上通过 [applyAction] 应用，得到一致的最终状态。
///
/// 定位用**索引**而非 cardId：
/// - 手牌/战场在两端顺序一致（同种子同洗牌），故手牌索引 [hand] 与战场索引 [att]/[board]
///   在两端指向同一张卡，天然消除重复模板 id 的歧义。
/// - 目标用 {t:'board',i} 或 {t:'hero',side} 编码。
library;

import '../models/models.dart';

/// 目标编码/解码
class ActionTarget {
  const ActionTarget.board(this.index)
      : _type = 'board',
        side = null;
  const ActionTarget.hero(this.side) : _type = 'hero', index = -1;

  final String _type;
  final int index; // board 目标索引
  final String? side; // 'self' | 'opp'

  Map<String, dynamic> toJson() => switch (_type) {
        'board' => {'t': 'board', 'i': index},
        _ => {'t': 'hero', 's': side},
      };

  static ActionTarget? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    if (m['t'] == 'board') return ActionTarget.board(m['i'] as int);
    return ActionTarget.hero(m['s'] as String?);
  }
}

/// 构造一个 action 的 data 载荷。type 与 data 分开存储。
class GameAction {
  const GameAction(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {'type': type, 'data': data};
}

/// 在指定对局驱动器上应用一个动作。
///
/// [GameStateDriver] 抽象了对局状态的可变操作（由 GameStateNotifier 实现），
/// 使动作应用层与具体 provider 解耦、可单测。
abstract class GameStateDriver {
  GameState? get state;

  /// 以 [playerId] 的身份出牌：手牌索引 [handIndex] 的卡，目标 [target]。
  void playCardAt(String playerId, int handIndex, {ActionTarget? target});

  void minionAttackAt(String playerId, int attIndex, int targetIndex);
  void minionAttackHeroAt(String playerId, int attIndex);
  void heroAttackDirect(String playerId);
  void useHeroPowerAt(String playerId, {ActionTarget? target});
  void startTurn(String playerId);
  void endTurn(String playerId);
}

/// 应用一个动作到 [driver]。返回是否成功应用。
/// 这是联机两端共同执行的分派逻辑。
bool applyAction(GameStateDriver driver, String actorId, String type, Map<String, dynamic> data) {
  final st = driver.state;
  if (st == null) return false;
  final player = st.getCurrentPlayer(actorId);

  switch (type) {
    case 'play':
      final hand = data['hand'] as int?;
      if (hand == null || hand < 0 || hand >= player.hand.length) return false;
      final target = ActionTarget.fromJson(data['target'] as Map<String, dynamic>?);
      driver.playCardAt(actorId, hand, target: target);
      return true;
    case 'attack_minion':
      final att = data['att'] as int?;
      final tgt = data['target'] as int?;
      if (att == null || tgt == null) return false;
      if (att < 0 || att >= player.board.length) return false;
      final opp = st.opponent;
      if (tgt < 0 || tgt >= opp.board.length) return false;
      driver.minionAttackAt(actorId, att, tgt);
      return true;
    case 'attack_hero':
      final att = data['att'] as int?;
      if (att == null || att < 0 || att >= player.board.length) return false;
      driver.minionAttackHeroAt(actorId, att);
      return true;
    case 'hero_direct':
      driver.heroAttackDirect(actorId);
      return true;
    case 'power':
      final target = ActionTarget.fromJson(data['target'] as Map<String, dynamic>?);
      driver.useHeroPowerAt(actorId, target: target);
      return true;
    case 'start_turn':
      driver.startTurn(actorId);
      return true;
    case 'end_turn':
      driver.endTurn(actorId);
      return true;
    default:
      return false;
  }
}

/// 把 GameStateNotifier 适配为 [GameStateDriver]。
/// 用于联机动作应用（两端各自持有一个本地 GameStateNotifier）。
class NotifierDriver implements GameStateDriver {
  NotifierDriver(this.notifier);
  // 避免 import 循环：用 dynamic 接收 notifier，运行时为其方法。
  final dynamic notifier;

  @override
  GameState? get state => notifier.state as GameState?;

  @override
  void playCardAt(String playerId, int handIndex, {ActionTarget? target}) {
    final st = notifier.state as GameState?;
    if (st == null) return;
    final card = st.getCurrentPlayer(playerId).hand[handIndex];
    final t = _toTargetId(st, playerId, target);
    notifier.playCard(playerId, card, targetId: t);
  }

  @override
  void minionAttackAt(String playerId, int attIndex, int targetIndex) {
    final st = notifier.state as GameState?;
    if (st == null) return;
    final player = st.getCurrentPlayer(playerId);
    final attacker = player.board[attIndex];
    final opp = st.opponent;
    final targetId = opp.board[targetIndex].id;
    notifier.minionAttack(playerId, attacker, targetId);
  }

  @override
  void minionAttackHeroAt(String playerId, int attIndex) {
    final st = notifier.state as GameState?;
    if (st == null) return;
    final player = st.getCurrentPlayer(playerId);
    final attacker = player.board[attIndex];
    notifier.minionAttackHero(playerId, attacker);
  }

  @override
  void heroAttackDirect(String playerId) => notifier.heroAttackDirect(playerId);

  @override
  void useHeroPowerAt(String playerId, {ActionTarget? target}) {
    final st = notifier.state as GameState?;
    if (st == null) return;
    final t = _toTargetId(st, playerId, target);
    notifier.useHeroPower(playerId, targetId: t);
  }

  @override
  void startTurn(String playerId) => notifier.startTurn(playerId);

  @override
  void endTurn(String playerId) => notifier.endTurn(playerId);

  /// 把编码目标还原为本地 GameState 用的 targetId 字符串。
  String? _toTargetId(GameState st, String playerId, ActionTarget? target) {
    if (target == null) return null;
    if (target._type == 'board') {
      final opp = st.opponent;
      if (target.index < 0 || target.index >= opp.board.length) return null;
      return opp.board[target.index].id;
    }
    // hero 目标
    final id = target.side == 'self' ? playerId : st.opponent.id;
    return 'hero_$id';
  }
}
