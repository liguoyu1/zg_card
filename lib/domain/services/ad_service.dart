/// 广告服务抽象层 —— Web 接入 Poki Games SDK，原生端零广告。
///
/// Poki SDK 只提供两种广告：`commercialBreak()`（自然停顿处的视频广告）与
/// `rewardedBreak()`（用户主动选择的激励视频），**没有横幅广告位**。
/// 是否真的出广告由 Poki 服务端决定，游戏只管在正确时机上报事件。
///
/// 事件时序（Poki 官方要求）：
///   启动：gameLoadingFinished() → gameplayStart()
///   开局：gameplayStop() → commercialBreak() → gameplayStart()
///   结算：gameplayStop()
library;

/// 游戏内广告位标识，仅用于区分触发场景。
class AdPlacement {
  AdPlacement._();

  /// 战后「翻倍奖励」激励视频位
  static const String goldBonus = 'ad_gold_bonus';

  /// 对局开始前的自然停顿（插屏位）
  static const String interstitial = 'ad_interstitial';
}

/// 广告服务统一接口。
abstract class AdService {
  /// 初始化 SDK。Poki 要求游戏启动时尽早调用一次。
  Future<void> initialize();

  /// 加载完成、玩家可交互 —— 对应 PokiSDK.gameLoadingFinished()。
  void gameLoadingFinished();

  /// 玩家进入实际操作（对局开始 / 复活后）。
  void gameplayStart();

  /// 玩家停下（结算 / 暂停 / 回主菜单）。
  void gameplayStop();

  /// 自然停顿处的视频广告。是否真出广告由 Poki 决定，游戏无需自己做频控。
  Future<void> showInterstitialAd({required String placementId});

  /// 激励视频。返回 true 表示完整观看，可以发奖。
  Future<bool> showRewardedAd({required String placementId});
}

/// 空实现：原生（iOS/Android）零广告。
/// 激励位视为「已观看」直接发奖，保持原生端既有体验。
class NoOpAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  void gameLoadingFinished() {}

  @override
  void gameplayStart() {}

  @override
  void gameplayStop() {}

  @override
  Future<void> showInterstitialAd({required String placementId}) async {}

  @override
  Future<bool> showRewardedAd({required String placementId}) async => true;
}
