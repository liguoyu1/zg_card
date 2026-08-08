import 'dart:async';

import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';

/// 经济状态同步 — 登录后与每次本地余额变动后，把本地余额上报服务端对账。
/// 服务端只入账正差（本地多于服务端的部分），负差忽略，保证最终一致且不丢账。
class BalanceSyncService {
  BalanceSyncService._();

  static String? _playerId;
  static String? _token;
  static Timer? _debounce;
  static bool _syncing = false;

  static void setSession(String playerId, String token) {
    _playerId = playerId;
    _token = token;
    schedule();
  }

  static void clearSession() {
    _playerId = null;
    _token = null;
    _debounce?.cancel();
  }

  /// 本地余额变动后调用（防抖合并），离线失败会在下次成功时补上
  static void schedule() {
    if (_playerId == null || _token == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), sync);
  }

  static Future<void> sync() async {
    if (_syncing || _playerId == null || _token == null) return;
    final data = await SaveManager.loadPlayerData();
    if (data == null) return;
    _syncing = true;
    try {
      await BalanceService.syncBalance(_playerId!, _token!,
          gems: data.gems, gold: data.gold);
    } catch (_) {
      // 离线/失败静默，下次变动或登录时重试
    } finally {
      _syncing = false;
    }
  }
}
