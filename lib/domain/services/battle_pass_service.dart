import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';

/// Battle Pass 服务
class BattlePassService {

  BattlePassService._();
  static final BattlePassService I = BattlePassService._();

  BattlePass? _bp;
  BattlePass get bp => _bp ?? BattlePass();

  static const String _saveKey = 'battle_pass_data';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_saveKey);
    if (str != null) {
      try {
        _bp = BattlePass.fromJson(jsonDecode(str));
        return;
      } catch (_) {}
    }
    _bp = BattlePass();
    _save();
  }

  void _save() {
    if (_bp == null) return;
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_saveKey, jsonEncode(_bp!.toJson())));
  }

  void addXp(int amount) {
    if (_bp == null) return;
    _bp!.xp += amount;
    while (_bp!.xp >= _bp!.xpToNext && _bp!.level < 30) {
      _bp!.xp -= _bp!.xpToNext;
      _bp!.level++;
    }
    _bp!.xp = _bp!.xp.clamp(0, _bp!.xpToNext);
    _save();
  }

  void unlockPremium() {
    if (_bp == null) return;
    _bp!.premium = true;
    _save();
  }

  bool claimFreeReward(int level) {
    if (_bp == null || _bp!.level < level) return false;
    if (_bp!.claimedFreeRewards.contains(level)) return false;
    _bp!.claimedFreeRewards.add(level);
    _save();
    return true;
  }

  bool claimPremiumReward(int level) {
    if (_bp == null || !_bp!.premium || _bp!.level < level) return false;
    if (_bp!.claimedPremiumRewards.contains(level)) return false;
    _bp!.claimedPremiumRewards.add(level);
    _save();
    return true;
  }

  void onEvent(QuestEvent event) {
    int xp = 0;
    switch (event.type) {
      case QuestEventType.matchWin: xp = 10;
      case QuestEventType.bossKilled: xp = 30;
      default: break;
    }
    if (xp > 0) addXp(xp);
  }
}

/// Battle Pass 奖励定义
class BPReward {

  const BPReward({required this.level, required this.isFree, required this.type, this.amount = 0, this.name});
  final int level;
  final bool isFree;
  final String type;
  final int amount;
  final String? name;

  static const List<BPReward> allRewards = [
    BPReward(level: 1, isFree: true, type: 'gold', amount: 50),
    BPReward(level: 5, isFree: true, type: 'pack', amount: 1),
    BPReward(level: 10, isFree: true, type: 'gold', amount: 100),
    BPReward(level: 15, isFree: true, type: 'pack', amount: 1),
    BPReward(level: 20, isFree: true, type: 'gold', amount: 200),
    BPReward(level: 25, isFree: true, type: 'pack', amount: 2),
    BPReward(level: 30, isFree: true, type: 'gold', amount: 300, name: '至尊'),
    BPReward(level: 1, isFree: false, type: 'cardback', amount: 1, name: '青铜'),
    BPReward(level: 5, isFree: false, type: 'skin', amount: 1, name: '墨家'),
    BPReward(level: 10, isFree: false, type: 'pack', amount: 3),
    BPReward(level: 15, isFree: false, type: 'gold', amount: 1, name: '风云'),
    BPReward(level: 20, isFree: false, type: 'skin', amount: 1, name: '法家'),
    BPReward(level: 25, isFree: false, type: 'gold', amount: 1, name: '定秦'),
    BPReward(level: 30, isFree: false, type: 'cardback', amount: 1, name: '黄金至尊'),
  ];

  static List<BPReward> getFreeRewards(int level) =>
      allRewards.where((r) => r.isFree && r.level == level).toList();

  static List<BPReward> getPremiumRewards(int level) =>
      allRewards.where((r) => !r.isFree && r.level == level).toList();
}
