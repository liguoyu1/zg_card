import 'dart:math';
import 'package:equatable/equatable.dart';
import 'player.dart';
import '../services/deterministic_random.dart';

/// 游戏阶段
enum GamePhase { waiting, mulligan, playing, ended }

/// 游戏状态
class GameState extends Equatable { // 回合数
  
  GameState({
    required this.player1,
    required this.player2,
    this.turn = 1,
    this.phase = GamePhase.waiting,
    required this.activePlayerId,
    this.winnerId,
    this.turnNumber = 0,
    this.seed,
    this.idSeq = 0,
  });
  final Player player1;
  final Player player2;
  final int turn;
  final GamePhase phase;
  final String activePlayerId; // 当前行动玩家
  final String? winnerId; // 胜利者
  final int turnNumber;

  /// 对局确定性种子。联机时两端同步同一种子以保证结果一致；
  /// 单机（null）时首用生成，每局不同。
  final int? seed;

  /// 对局级实例 id 计数（替代原来的进程级静态 _seq）。
  final int idSeq;

  /// 确定性随机源（由 seed 派生）。
  /// 非 props：持有跨 copyWith 的随机游标，不参与相等性比较。
  DeterministicRandom? _rng;

  /// 确定性随机源；无 seed 时退化为真随机（单机 AI 行为不变）。
  DeterministicRandom get rng {
    if (_rng == null) {
      _rng = DeterministicRandom(seed ?? (Random().nextInt(1 << 31)));
    }
    return _rng!;
  }

  /// 分配下一个实例 id 并返回携带新 idSeq 的状态。
  /// id 生成不消耗 rng 随机序列，只推进 idSeq，保证两端 id 唯一且一致。
  GameState nextId() => copyWith(idSeq: idSeq + 1);
  
  /// 获取当前行动玩家
  Player get activePlayer => 
    player1.id == activePlayerId ? player1 : player2;
  
  /// 获取对手
  Player get opponent => 
    player1.id == activePlayerId ? player2 : player1;
  
  /// 游戏是否结束
  bool get isEnded => phase == GamePhase.ended;
  
  /// 获取当前玩家
  Player getCurrentPlayer(String playerId) =>
    player1.id == playerId ? player1 : player2;
  
  /// 更新玩家状态
  GameState updatePlayer(Player player) {
    if (player.id == player1.id) {
      return copyWith(player1: player);
    }
    return copyWith(player2: player);
  }
  
  GameState copyWith({
    Player? player1,
    Player? player2,
    int? turn,
    GamePhase? phase,
    String? activePlayerId,
    String? winnerId,
    int? turnNumber,
    int? seed,
    int? idSeq,
  }) {
    final gs = GameState(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      winnerId: winnerId ?? this.winnerId,
      turnNumber: turnNumber ?? this.turnNumber,
      seed: seed ?? this.seed,
      idSeq: idSeq ?? this.idSeq,
    );
    // 保留同一个 rng 游标；仅在显式更换 seed 时重建（seed 为 null 则惰性由 getter 生成）
    if (seed != null) {
      gs._rng = DeterministicRandom(seed!);
    } else {
      gs._rng = this._rng;
    }
    return gs;
  }
  
  @override
  List<Object?> get props => [player1, player2, turn, phase, activePlayerId, winnerId, turnNumber, seed, idSeq];
}