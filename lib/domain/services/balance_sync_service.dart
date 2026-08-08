import 'dart:async';
import 'dart:convert';

import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';

/// 经济状态与完整存档云同步：
/// 1) 余额对账：本地多于服务端 → 上报（服务端只入账正差，负差忽略）
/// 2) 完整存档：PlayerData + Collection + 战斗历史，按版本（时间戳）最新者胜，
///    空档永不覆盖有资产的档，跨设备恢复全部资产
class BalanceSyncService {
  BalanceSyncService._();

  static String? _playerId;
  static String? _token;
  static String? _playerName;
  static Timer? _debounce;
  static bool _syncing = false;
  static int _lastSyncAt = 0;
  static const int _minSyncIntervalMs = 15000;

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

  /// 登录后：切换到该账号的本地存档区，与云端合并（版本最新者胜），随后防抖上传
  static Future<void> afterLogin() async {
    if (_playerId == null || _token == null) return;
    await SaveManager.ensureAccountStorage(_playerId!);
    await _syncFromCloud();
    schedule();
  }

  static Future<void> _syncFromCloud() async {
    if (_playerId == null || _token == null) return;
    final local = await SaveManager.loadPlayerData();
    final remote = await BalanceService.downloadSave(_playerId!, _token!);
    final localColl = await SaveManager.loadCollection();
    final localHasAssets = local != null &&
        (local.unlockedCards.isNotEmpty ||
            local.unlockedHeroes.length > 1 ||
            (localColl?.cards.isNotEmpty ?? false));
    final remoteJson = remote?.json ?? '';
    final remotePd = _extractPlayerData(remoteJson);
    final remoteHasAssets = remotePd != null &&
        !_emptySave(remotePd, _extractCollection(remoteJson));

    // 云端无档：本地有资产/登录态档上传为初始档；否则服务端余额兜底
    if (remote == null || remotePd == null) {
      if (local == null ||
          (!localHasAssets &&
              local.id != _playerId &&
              !RegExp(r'^\d+$').hasMatch(local.id))) {
        await _initFromServerBalance();
      } else {
        if (local.id != _playerId) {
          await SaveManager.savePlayerData(
              local.copyWith(id: _playerId!, name: _playerName ?? local.name));
        }
        await _uploadArchive();
      }
      return;
    }
    // 云端有资产、本地空档（新设备）→ 恢复云端
    if (remoteHasAssets && !localHasAssets) {
      await SaveManager.importSave(remote.json);
      await _fixOwnership();
      return;
    }
    // 云端空档（被污染）、本地有资产 → 本地覆盖
    if (!remoteHasAssets && localHasAssets) {
      await _uploadArchive();
      return;
    }
    // 双方都有资产：版本最新者胜（服务端 updatedAt vs 本地 save_ts）
    final remoteTs =
        DateTime.tryParse(remote.updatedAt)?.millisecondsSinceEpoch ?? 0;
    final localTs = await SaveManager.loadSavedAt();
    if (remoteTs > localTs) {
      await SaveManager.importSave(remote.json);
      await _fixOwnership();
    } else {
      await _uploadArchive();
    }
  }

  static Future<void> _fixOwnership() async {
    final pd = await SaveManager.loadPlayerData();
    if (pd != null && pd.id != _playerId) {
      await SaveManager.savePlayerData(
          pd.copyWith(id: _playerId!, name: _playerName ?? pd.name));
    }
  }

  /// 云端与本地均无资产时，用服务端余额初始化本地（恢复钻石/金币）
  static Future<void> _initFromServerBalance() async {
    if (_playerId == null || _token == null) return;
    final b = await BalanceService.getBalance(_playerId!);
    if (b == null) return;
    final pd = PlayerData(
      id: _playerId!,
      name: _playerName ?? _playerId!,
      gems: b.gems,
      gold: b.gold,
    );
    await SaveManager.savePlayerData(pd);
    await _uploadArchive();
  }

  static bool _emptySave(PlayerData pd, Collection? coll) =>
      pd.unlockedCards.isEmpty &&
      pd.unlockedHeroes.length <= 1 &&
      (coll == null || coll.cards.isEmpty);

  static bool _isDefaultSave(PlayerData d) =>
      d.firstRun ||
      (d.gems == 0 &&
          d.gold <= 100 &&
          d.unlockedCards.isEmpty &&
          d.unlockedHeroes.length <= 1);

  static PlayerData? _extractPlayerData(String saveJson) {
    try {
      final root = jsonDecode(saveJson);
      final pd = (root is Map && root['playerData'] is Map)
          ? root['playerData']
          : root;
      return PlayerData.fromJson(Map<String, dynamic>.from(pd as Map));
    } catch (_) {
      return null;
    }
  }

  static Collection? _extractCollection(String saveJson) {
    try {
      final root = jsonDecode(saveJson);
      final c = (root is Map && root['collection'] is Map)
          ? root['collection']
          : null;
      return c == null
          ? null
          : Collection.fromJson(Map<String, dynamic>.from(c as Map));
    } catch (_) {
      return null;
    }
  }

  /// 本地存档变动后调用（防抖合并），离线失败下次成功时补齐
  static void schedule() {
    if (_playerId == null || _token == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _syncAll);
  }

  static Future<void> _syncAll() async {
    if (_syncing || _playerId == null || _token == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSyncAt < _minSyncIntervalMs) return; // 节流：至少间隔 15s
    _syncing = true;
    try {
      final data = await SaveManager.loadPlayerData();
      if (data == null) return;
      if (!_isDefaultSave(data)) {
        await BalanceService.syncBalance(_playerId!, _token!,
            gems: data.gems, gold: data.gold);
        await _uploadArchive();
        _lastSyncAt = now;
      }
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
}
