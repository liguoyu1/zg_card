import 'dart:async';
import 'dart:convert';

import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';
import 'save_merger.dart';

/// 跨端状态同步（多端登录、云端权威、本地仅缓存与离线兜底）：
/// - 余额/购买：服务端事务接口实时处理（单笔、记流水），客户端以返回状态落存
/// - 资产状态：5 秒版本轮询 → 有更新拉资产包 → 卡/英雄/收藏按并集合并，只增不减
/// - 明细：本地事件流（购买/充值/兑换）与状态分开保存，不进云端
/// - 对局：服务端 matches/本地历史，独立于资产同步
/// - 下载失败绝不动本地、绝不覆盖云端；5 秒轮询即重试通道
class BalanceSyncService {
  BalanceSyncService._();

  static String? _playerId;
  static String? _token;
  static String? _playerName;
  static Timer? _debounce;
  static Timer? _pollTimer;
  static bool _syncing = false;
  static bool _bootstrapped = false;
  static int _lastSyncAt = 0;
  static int _lastRemoteVersion = 0;
  static const int _minSyncIntervalMs = 5000;
  static const Duration _pollInterval = Duration(seconds: 5);

  static String? get playerId => _playerId;
  static String? get playerName => _playerName;

  static void setSession(String playerId, String token, {String? playerName}) {
    _playerId = playerId;
    _token = token;
    _playerName = playerName;
    _bootstrapped = false;
    _lastRemoteVersion = 0;
    _lastSyncAt = 0;
    _startPolling();
    schedule();
  }

  static void clearSession() {
    _playerId = null;
    _token = null;
    _playerName = null;
    _debounce?.cancel();
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 登录态下周期拉取云端（前台运行），保证跨端资产及时同步
  static void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refreshNow());
  }


  static Future<void>? _inflight;

  /// 登录后：切换到该账号的本地存档区，与云端合并（进度更强者胜），随后防抖上传
  static Future<void> afterLogin() async {
    if (_playerId == null || _token == null) return;
    await SaveManager.ensureAccountStorage(_playerId!);
    await refreshNow();
    schedule();
  }

  /// 等待登录后首次云端同步完成（供启动页在读取存档前调用，复用同一轮同步）
  static Future<void> waitForInitialSync() => refreshNow();

  /// App 回到前台/页面进入/周期轮询的统一入口：并发请求共享同一轮同步。
  /// 未登录立即完成；同步中调用等待同一轮结束。
  static Future<void> refreshNow() {
    if (_playerId == null || _token == null) return Future<void>.value();
    return _inflight ??= _resync().whenComplete(() => _inflight = null);
  }

  static Future<void> _resync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final v = await BalanceService.fetchRemoteVersion(_playerId!, _token!);
      final needFullSync = !_bootstrapped || v == null || v < 0 || v > _lastRemoteVersion;
      if (needFullSync) {
        // 首次/版本端点不可用/云端有更新 → 拉取并与本地合并
        await _syncFromCloud();
        // 服务端权威余额校正：webhook 等外部入账（如 Xsolla）只更新 player 表，
        // 存档合并拿不到增量，这里用 /balance/get 补差（只增不减）
        await _reconcileBalanceFromServer();
        _lastRemoteVersion = v ?? DateTime.now().millisecondsSinceEpoch;
        _bootstrapped = true;
      }
      await _uploadIfDue();
    } catch (_) {
      // 失败静默：5 秒轮询即重试通道
    } finally {
      _syncing = false;
    }
  }

  /// 本地存档变动后调用（防抖合并），离线失败下次成功时补齐
  static void schedule() {
    if (_playerId == null || _token == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => refreshNow());
  }

  /// 节流窗口内的改动安排在窗口结束后补传，保证改动最终一定上传
  static Future<void> _uploadIfDue() async {
    if (_playerId == null || _token == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSyncAt < _minSyncIntervalMs) {
      _debounce?.cancel();
      _debounce = Timer(
        Duration(milliseconds: _minSyncIntervalMs - (now - _lastSyncAt)),
        () => refreshNow(),
      );
      return;
    }
    final data = await SaveManager.loadPlayerData();
    if (data == null || isDefaultSave(data)) return;
    await BalanceService.syncBalance(_playerId!, _token!,
        gems: data.gems, gold: data.gold);
    final uploadedAt = await _uploadArchive();
    _lastSyncAt = now;
    if (uploadedAt > 0) {
      // 用服务端时间戳对齐版本，避免本端时钟偏差导致漏拉另一端更新
      _lastRemoteVersion = uploadedAt;
    }
  }

  static Future<void> _syncFromCloud() async {
    if (_playerId == null || _token == null) return;
    final local = await SaveManager.loadPlayerData();
    final localColl = await SaveManager.loadCollection();
    final localHasAssets = local != null &&
        (local.unlockedCards.isNotEmpty ||
            local.unlockedHeroes.length > 1 ||
            (localColl?.cards.isNotEmpty ?? false));

    // 下载失败（网络/服务端/解析异常）：绝不动本地、绝不覆盖云端，等待下次重试
    final remote = await BalanceService.downloadSave(_playerId!, _token!);
    if (remote == null) return;

    // 云端无档（ok=true 且空）：本地有真实资产才上传为初始档；否则余额兜底
    // （默认/初始档不上传，避免与服务端空档防护互相空转）
    if (remote.json.isEmpty) {
      if (local != null && localHasAssets && !isDefaultSave(local)) {
        await _uploadArchive();
      } else {
        await _initFromServerBalance();
      }
      return;
    }

    final remotePd = _extractPlayerData(remote.json);
    if (remotePd == null) return; // 云端数据异常：保守不动
    // 云端为旧版初始档（孙膑+全池随机卡，未开局）→ 视同无资产，由本地新初始档覆盖
    final cloudIsLegacyStarter = !remotePd.starterSeeded &&
        remotePd.totalMatches == 0 &&
        remotePd.winCount == 0 &&
        remotePd.gems == 0 &&
        remotePd.gold <= 100 &&
        remotePd.unlockedHeroes.length <= 1 &&
        remotePd.achievedMedals.isEmpty &&
        remotePd.stats.isEmpty;
    final remoteHasAssets = !cloudIsLegacyStarter &&
        !isEmptySave(remotePd, _extractCollection(remote.json));

    // 本地空档（新设备）→ 恢复云端
    if (!localHasAssets) {
      await SaveManager.importSave(remote.json);
      await _fixOwnership();
      return;
    }
    // 云端空档（被污染）、本地有资产 → 本地覆盖
    if (!remoteHasAssets) {
      await _uploadArchive();
      return;
    }
    // 双方都有资产：卡牌/英雄/勋章/收藏为累积型，逐字段合并取并集/更优，
    // 避免一侧整档覆盖导致另一侧已购资产丢失
    await _mergeWithCloud(remote.json);
    await _uploadArchive();
  }

  /// 与云端存档逐字段合并（本地为基准，云端并入）：
  /// 卡/英雄/勋章/收藏并集取更优；数值统计取 max；历史记录归本地，不进云端
  static Future<void> _mergeWithCloud(String remoteJson) async {
    final local = await SaveManager.loadPlayerData();
    final remotePd = _extractPlayerData(remoteJson);
    if (local == null || remotePd == null) {
      await SaveManager.importSave(remoteJson);
      await _fixOwnership();
      return;
    }
    final merged = mergePlayerData(local, remotePd);
    await SaveManager.savePlayerData(
        merged.copyWith(id: _playerId!, name: _playerName ?? merged.name));
    final mergedColl = mergeCollection(
        await SaveManager.loadCollection(), _extractCollection(remoteJson));
    await SaveManager.saveCollection(mergedColl);
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

  /// 用服务端权威余额校正本地（仅当服务端更高时补差，绝不回退）
  static Future<void> _reconcileBalanceFromServer() async {
    if (_playerId == null || _token == null) return;
    final b = await BalanceService.getBalance(_playerId!);
    if (b == null) return;
    final pd = await SaveManager.loadPlayerData();
    if (pd == null) return;
    final gemGain = b.gems - pd.gems;
    final goldGain = b.gold - pd.gold;
    if (gemGain > 0 || goldGain > 0) {
      await SaveManager.savePlayerData(pd.copyWith(
        gems: pd.gems + (gemGain > 0 ? gemGain : 0),
        gold: pd.gold + (goldGain > 0 ? goldGain : 0),
      ));
    }
  }

  /// 上传当前存档；返回服务端保存时间戳（毫秒），供版本对齐（0 表示失败）
  static Future<int> _uploadArchive() async {
    if (_playerId == null || _token == null) return 0;
    final pd = await SaveManager.loadPlayerData();
    if (pd == null) return 0;
    if (pd.id != _playerId) {
      // 上传前强制归属当前账号，避免匿名/游客档污染云端
      await SaveManager.savePlayerData(
          pd.copyWith(id: _playerId!, name: _playerName ?? pd.name));
    }
    final save = await SaveManager.exportSave();
    final res =
        await BalanceService.uploadSave(_playerId!, _token!, save);
    return res.ok ? res.updatedAt : 0;
  }
}
