/// 广告服务抽象层 —— 为游戏内投放广告预留统一接口。
///
/// 平台策略：
/// - Web (H5) 构建：接入 Adsterra（智能链接 / Popunder / 原生横幅）。
/// - iOS / Android 原生构建：不投放广告，使用 [NoOpAdService] 空实现（零广告、零崩溃）。
///
/// 通过 [getAdService] 工厂按运行平台返回对应实现，调用方无需关心平台差异。
library;

/// 广告位标识，对应游戏内不同触发场景。
class AdPlacement {
  AdPlacement._();
  // 免费卡包（当前未启用）
  static const String freePack = 'ad_free_pack';
  // 金币加成 / 翻倍金币（激励视频位）
  static const String goldBonus = 'ad_gold_bonus';
  // 战败复活（当前未启用）
  static const String revive = 'ad_revive';
  // 插屏广告（结算前）
  static const String interstitial = 'ad_interstitial';
  // 常驻横幅广告（卡牌页等界面底部，原生横幅位）
  static const String banner = 'ad_banner';
}

/// 广告服务统一接口。
abstract class AdService {
  bool get isInitialized;
  Future<bool> initialize();

  /// 展示激励广告（如「翻倍金币」）。返回 true 表示用户已完成观看/互动，应发放奖励。
  Future<bool> showRewardedAd({required String placementId});

  /// 展示插屏广告（如「结算前」）。无需返回值。
  Future<void> showInterstitialAd({required String placementId});

  /// 展示/隐藏常驻横幅广告（如卡牌页底部的原生横幅）。
  /// [show] 为 true 时显示，false 时隐藏。
  Future<void> showBannerAd({required String placementId, required bool show});

  void dispose();
}

/// 默认空实现：不展示任何广告，所有激励调用均视为「已完成」（用于原生端或未接入时）。
class NoOpAdService implements AdService {
  @override
  bool get isInitialized => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> showRewardedAd({required String placementId}) async => true;

  @override
  Future<void> showInterstitialAd({required String placementId}) async {}

  @override
  Future<void> showBannerAd({required String placementId, required bool show}) async {}

  @override
  void dispose() {}
}
