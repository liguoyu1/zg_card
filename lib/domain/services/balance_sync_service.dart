import 'dart:async';
import 'dart:convert';

import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';

/// 经济状态与完整存档云同步：
/// 1) 余额对账：本地多于服务端 → 上报（服务端只入账正差，负差忽略）
/// 2) 完整存档：PlayerData + Collection + 战斗历史 整体上传；登录后若本地
///    无存档则从服务端拉回（跨设备恢复全部资产）
class BalanceSyncService {
  BalanceSyncService._();

  static String? _playerId;
  static String? _token;
  static String? _playerName;
  static Timer? _debounce;
  static bool _syncing = false;

  static void setSession(String playerId, String token, {String? playerName}) {
    _playerId = playerId;
    _token = token;
    _playerName = playerName;
    schedule();
  }

  static void clearSession() {
    _playerId = null;
    _token = null;
    _playerName = null;
    _debounce?.cancel();
  }

  /// 登录后：本地无存档则拉取远端存档（含余额兜底），随后防抖上传本地
  static Future<void> afterLogin() async {
    if (_playerId == null || _token == null) return;
    await _downloadIfEmpty();
    schedule();
  }

  /// 本地存档变动后调用（防抖合并），离线失败下次成功时补齐
  static void schedule() {
    if (_playerId == null || _token == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _syncAll);
  }

  static Future<void> _syncAll() async {
    if (_syncing || _playerId == null || _token == null) return;
    _syncing = true;
    try {
      final data = await SaveManager.loadPlayerData();
      if (data == null) return;
      await BalanceService.syncBalance(_playerId!, _token!,
          gems: data.gems, gold: data.gold);
      await _uploadArchive();
    } catch (_) {
      // 离线/失败静默，下次变动或登录时重试
    } finally {
      _syncing = false;
    }
  }

  static Future<void> _uploadArchive() async {
    if (_playerId == null || _token == null) return;
    final save = await SaveManager.exportSave();
    await BalanceService.uploadSave(_playerId!, _token!, save);
  }

  static Future<void> _downloadIfEmpty() async {
    if (_playerId == null || _token == null) return;
    final local = await SaveManager.loadPlayerData();
    if (local != null) return; // 本地已有存档，不上传覆盖（多端冲突：最后写者胜）
    final remote = await BalanceService.downloadSave(_playerId!, _token!);
    if (remote != null && remote.isNotEmpty) {
      await SaveManager.importSave(remote);
      return;
    }
    // 远端无存档：用服务端余额初始化本地（恢复钻石/金币）
    final b = await BalanceService.getBalance(_playerId!);
    if (b != null) {
      final pd = PlayerData(
        id: _playerId!,
        name: _playerName ?? _playerId!,
        gems: b.gems,
        gold: b.gold,
      );
      await SaveManager.savePlayerData(pd);
    }
  }
}
