import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class GoogleAdService implements AdService {
  bool _initialized = false;

  static final String _rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-6426641989736114/1327110831'
      : 'ca-app-pub-6426641989736114/1096356175';

  static final String _interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-6426641989736114/1055226634'
      : 'ca-app-pub-6426641989736114/9098969272';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  @override
  Future<bool> showRewardedAd({required String placementId}) async {
    if (!_initialized || _isRewardedLoading) return false;
    _isRewardedLoading = true;

    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoading = false;
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoading = false;
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, reward) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    if (!_initialized || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoading = false;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoading = false;
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}
