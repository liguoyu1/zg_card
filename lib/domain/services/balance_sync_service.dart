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

  /// 登录后：切换到该账号的本地存档区，并以云端存档为权威恢复，
  /// 仅当本地是该账号自己的存档且进度更新时才反向覆盖；随后防抖上传。
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
    final localOwn = local != null &&
        (local.id == _playerId || RegExp(r'^\d+$').hasMatch(local.id));
    final remotePd = _extractPlayerData(remote ?? '');
    final remoteEmpty = remote == null ||
        remotePd == null ||
        _isEmptySave(remotePd, _extractCollection(remote));
    if (localOwn && (remoteEmpty || _progressAtLeast(
        _progressOf(local, await SaveManager.loadCollection()),
        _progressOf(remotePd, _extractCollection(remote))))) {
      if (!_isNullSave(local)) await _uploadArchive(); // 本地更完整，覆盖云端
      return;
    }
    if (remote != null && remote.isNotEmpty && !remoteEmpty) {
      await SaveManager.importSave(remote);
      // 修正存档归属（兼容早期被匿名/游客档污染的历史数据）
      final pd = await SaveManager.loadPlayerData();
      if (pd != null && pd.id != _playerId) {
        await SaveManager.savePlayerData(
            pd.copyWith(id: _playerId!, name: _playerName ?? pd.name));
      }
      return;
    }
    // 云端无档：本地匿名档（纯时间戳 id）或本账号档作为账号初始档；否则余额兜底
    if (local != null &&
        (local.id == _playerId || RegExp(r'^\d+$').hasMatch(local.id))) {
      await SaveManager.savePlayerData(
          local.copyWith(id: _playerId!, name: _playerName ?? local.name));
      await _uploadArchive();
      return;
    }
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

  static bool _isEmptySave(PlayerData pd, Collection? coll) =>
      pd.unlockedCards.isEmpty &&
      pd.unlockedHeroes.length <= 1 &&
      (coll == null || coll.cards.isEmpty);

  static bool _isNullSave(PlayerData pd) => _isEmptySave(pd, null);

  /// 粗略进度比较：总局数 + 收藏卡数，用于双端冲突时取较新的一侧
  static ({int matches, int cards}) _progressOf(
      PlayerData pd, Collection? coll) {
    return (matches: pd.totalMatches, cards: coll?.cards.length ?? 0);
  }

  static bool _progressAtLeast(
      ({int matches, int cards}) a, ({int matches, int cards}) b) {
    return a.matches > b.matches ||
        (a.matches == b.matches && a.cards >= b.cards);
  }

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
}
