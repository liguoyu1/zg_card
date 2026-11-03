// Web 专属实现：dart:js_interop 调用 Poki Games SDK（window.PokiSDK）。
//
// SDK 由 web/index.html 的 <script src="https://game-cdn.poki.com/scripts/v2/poki-sdk.js">
// 注入；本文件只负责调用，不注入脚本。此文件仅在 Web 编译，原生平台不包含。
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../core/audio/audio_manager.dart';
import 'ad_service.dart';

/// PokiSDK 的 JS 侧形状（只声明用到的部分）。
extension type _PokiSDK._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> init();

  external void gameLoadingFinished();

  external void gameplayStart();

  external void gameplayStop();

  /// [onAdStarted] 在广告真正开始播放时被调用（没广告时可能不调用）。
  external JSPromise<JSAny?> commercialBreak([JSFunction? onAdStarted]);

  /// resolve(true) 表示可发奖（视频开始播放且看完/跳过）。
  external JSPromise<JSAny?> rewardedBreak([JSFunction? onAdStarted]);
}

const String _bgmAsset = 'bgm.mp3';

/// 是否在被 Poki 托管的页面里运行。
///
/// 判断依据与 SDK 内部一致：只要带 `?site_id=<n>` 或 `window.isPokiExternal`。
/// 不在 Poki 里时 `commercialBreak()` 会空等约 7 秒（没有 CMP/广告填充），
/// 所以本地/自有域名直接跳过商业化插播，只有激励视频照常调用（返回 false 不发奖）。
bool get _hostedByPoki {
  final siteId = int.tryParse(Uri.base.queryParameters['site_id'] ?? '');
  if (siteId != null && siteId > 0) return true;
  final ext = globalContext['isPokiExternal'];
  return ext is JSBoolean && ext.toDart;
}

class PokiAdService implements AdService {
  bool _mutedBeforeAd = false;
  bool _bgmBeforeAd = false;

  /// SDK 未加载（本地直开、被广告拦截插件屏蔽）时为 null，所有调用降级为空操作。
  _PokiSDK? get _sdk {
    final obj = globalContext['PokiSDK'];
    if (obj == null || obj.isUndefinedOrNull) return null;
    return _PokiSDK._(obj as JSObject);
  }

  @override
  Future<void> initialize() async {
    final sdk = _sdk;
    if (sdk == null) return;
    try {
      await sdk.init().toDart;
    } catch (_) {
      // Poki 文档明确：init 失败也要照常加载游戏。
    }
  }

  @override
  void gameLoadingFinished() {
    try {
      _sdk?.gameLoadingFinished();
    } catch (_) {}
  }

  @override
  void gameplayStart() {
    try {
      _sdk?.gameplayStart();
    } catch (_) {}
  }

  @override
  void gameplayStop() {
    try {
      _sdk?.gameplayStop();
    } catch (_) {}
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    final sdk = _sdk;
    if (sdk == null || !_hostedByPoki) return;
    try {
      await sdk.commercialBreak(_onAdStarted.toJS).toDart;
    } catch (_) {
      // 广告失败不能阻塞游戏。
    } finally {
      _onAdFinished();
    }
  }

  @override
  Future<bool> showRewardedAd({required String placementId}) async {
    final sdk = _sdk;
    if (sdk == null) return false;
    try {
      final result = await sdk.rewardedBreak(_onAdStarted.toJS).toDart;
      return (result as JSBoolean?)?.toDart ?? false;
    } catch (_) {
      return false;
    } finally {
      _onAdFinished();
    }
  }

  /// 广告开播：Poki 要求期间静音，且此时游戏不该在跑。
  void _onAdStarted() {
    _mutedBeforeAd = AudioManager.I.isMuted;
    _bgmBeforeAd = AudioManager.I.isMusicPlaying;
    AudioManager.I.setMuted(true);
    AudioManager.I.stopBGM();
  }

  void _onAdFinished() {
    if (!_mutedBeforeAd) AudioManager.I.setMuted(false);
    if (_bgmBeforeAd) AudioManager.I.playBGM(_bgmAsset);
    _bgmBeforeAd = false;
  }
}

/// 平台工厂函数：Web 下返回 Poki 实现。
AdService createPlatformAdService() => PokiAdService();
