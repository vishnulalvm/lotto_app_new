import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._();
  
  AdMobService._();

  // Test Ad Unit IDs for development
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Production Ad Unit IDs (to be updated when you create your AdMob account)
  static const String _prodRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _prodBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _prodNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Ad instances
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  // Ad loading states
  bool _isRewardedAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isBannerAdLoaded = false;

  // Initialization
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Request configuration for test devices (optional)
    if (kDebugMode) {
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: ['YOUR_TEST_DEVICE_ID_HERE'], // Add your test device ID
      );
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    }
  }

  // Get Ad Unit IDs based on environment
  String get rewardedAdUnitId {
    return kDebugMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  }

  String get interstitialAdUnitId {
    return kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  }

  String get bannerAdUnitId {
    return kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  }

  String get nativeAdUnitId {
    return kDebugMode ? _testNativeAdUnitId : _prodNativeAdUnitId;
  }

  // Rewarded Ad Methods
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          
          // Set full screen content callback
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              // Preload next ad
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              if (kDebugMode) {
                print('Rewarded ad failed to show: $error');
              }
            },
          );
          
          if (kDebugMode) {
            print('Rewarded ad loaded successfully');
          }
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          if (kDebugMode) {
            print('Rewarded ad failed to load: $error');
          }
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
    Function()? onAdDismissed,
  }) async {
    if (_rewardedAd != null && _isRewardedAdLoaded) {
      _rewardedAd?.show(
        onUserEarnedReward: onUserEarnedReward,
      );
      
      // Set callback for when ad is dismissed
      if (onAdDismissed != null) {
        _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            onAdDismissed();
            // Preload next ad
            loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            if (kDebugMode) {
              print('Rewarded ad failed to show: $error');
            }
          },
        );
      }
    } else {
      if (kDebugMode) {
        print('Rewarded ad not ready');
      }
    }
  }

  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // Interstitial Ad Methods
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          
          // Set full screen content callback
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Preload next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              if (kDebugMode) {
                print('Interstitial ad failed to show: $error');
              }
            },
          );
          
          if (kDebugMode) {
            print('Interstitial ad loaded successfully');
          }
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }

  Future<void> showInterstitialAd({
    Function()? onAdDismissed,
  }) async {
    if (_interstitialAd != null && _isInterstitialAdLoaded) {
      _interstitialAd?.show();
      
      // Set callback for when ad is dismissed
      if (onAdDismissed != null) {
        _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
            onAdDismissed();
            // Preload next ad
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
            if (kDebugMode) {
              print('Interstitial ad failed to show: $error');
            }
          },
        );
      }
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready');
      }
    }
  }

  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  // Banner Ad Methods
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          if (kDebugMode) {
            print('Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerAdLoaded = false;
          if (kDebugMode) {
            print('Banner ad failed to load: $error');
          }
        },
      ),
    );
  }

  bool get isBannerAdLoaded => _isBannerAdLoaded;

  // Dispose methods
  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  void disposeAll() {
    disposeRewardedAd();
    disposeInterstitialAd();
    disposeBannerAd();
  }

  // Native Ad Methods
  NativeAd createNativeAd({
    required NativeAdListener listener,
    NativeTemplateStyle? templateStyle,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      listener: listener,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle ?? NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.italic,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black45,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
  }

  // Create news-styled native ad for seamless integration
  NativeAd createNewsStyleNativeAd({
    required NativeAdListener listener,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      listener: listener,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 0.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 20.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white60,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
    );
  }

  // Preload ads
  void preloadAds() {
    loadRewardedAd();
    loadInterstitialAd();
  }
}