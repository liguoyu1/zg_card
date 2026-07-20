/// 广告服务抽象层 — 为后续接入真实广告SDK预留接口
abstract class AdService {
  bool get isInitialized;
  Future<bool> initialize();
  Future<bool> showRewardedAd({required String placementId});
  Future<void> showInterstitialAd({required String placementId});
  void dispose();
}

class AdPlacement {
  AdPlacement._();
  static const String freePack = 'ad_free_pack';
  static const String goldBonus = 'ad_gold_bonus';
  static const String revive = 'ad_revive';
}

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
  void dispose() {}
}
