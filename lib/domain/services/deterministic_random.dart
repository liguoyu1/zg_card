import 'dart:math';

/// 对局确定性随机数发生器。
/// 内部封装 [Random]（带种子），保证同一种子产生同一随机序列。
/// 联机时两端用相同种子构造，并在同一状态点按相同顺序调用
/// [nextInt]/[nextDouble]/[nextBool]，即可得到一致的随机结果。
///
/// 单机（无 seed）时退化为未播种 [Random]，保持"每局不同"的原行为。
class DeterministicRandom {
  DeterministicRandom(int seed) : _impl = Random(seed);
  DeterministicRandom.from(Random r) : _impl = r;

  final Random _impl;

  /// [0, max)
  int nextInt(int max) => _impl.nextInt(max);

  /// [min, max] 含上下界
  int nextIntRange(int min, int max) => min + _impl.nextInt(max - min + 1);

  double nextDouble() => _impl.nextDouble();

  bool nextBool() => _impl.nextBool();

  /// 暴露底层 [Random]，供 [List.shuffle] 等直接使用。
  Random get raw => _impl;
}
