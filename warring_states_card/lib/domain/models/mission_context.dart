/// 冒险任务上下文 — 从冒险界面传递到游戏界面
class MissionContext {

  MissionContext({
    required this.missionId,
    required this.rewardGold,
    required this.rewardCards,
    required this.onComplete,
  });
  final String missionId;
  final int rewardGold;
  final List<String> rewardCards;
  final void Function(bool victory) onComplete;
}
