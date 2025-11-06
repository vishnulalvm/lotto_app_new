import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:lotto_app/data/services/analytics_service.dart';

/// Ad loading states for better state management
enum AdState { idle, loading, loaded, failed, disposed }

/// Ad wrapper to encapsulate state and instance together
class AdWrapper<T> {
  final T? ad;
  final AdState state;
  final String? error;
  final DateTime? lastLoadTime;
  final int usageCount;

  const AdWrapper({
    this.ad,
    this.state = AdState.idle,
    this.error,
    this.lastLoadTime,
    this.usageCount = 0,
  });

  AdWrapper<T> copyWith({
    T? ad,
    AdState? state,
    String? error,
    DateTime? lastLoadTime,
    int? usageCount,
  }) {
    return AdWrapper<T>(
      ad: ad ?? this.ad,
      state: state ?? this.state,
      error: error ?? this.error,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  bool get isLoaded => state == AdState.loaded && ad != null;
  bool get isLoading => state == AdState.loading;
  bool get canLoad => state == AdState.idle || state == AdState.failed;
  bool get needsReload => state == AdState.failed || 
    (lastLoadTime != null && DateTime.now().difference(lastLoadTime!).inMinutes > 30);
}

class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._();
  
  AdMobService._();

  // INTERSTITIAL AD UNIT IDs
  static const String interstitialResultsPredict = 'ca-app-pub-1386225714525775/8656073343';
  static const String interstitialResultsSeemore = 'ca-app-pub-1386225714525775/4716828336';
  static const String interstitialScratchCard = 'ca-app-pub-1386225714525775/6288123744';
  static const String interstitialChallenge = 'ca-app-pub-1386225714525775/7335325539';

  // Test ad unit IDs (use for debugging NO_FILL issues)
  static const String testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Debug mode flag - set to true to use test ads
  static const bool useTestAds = false; // Production mode - using real ad units

  // NATIVE AD UNIT IDs
  static const String nativeLiveVideo = 'ca-app-pub-1386225714525775/5079790413';
  

  // Consolidated ad state management
  final Map<String, AdWrapper<InterstitialAd>> _interstitialAds = {};
  final Map<String, AdWrapper<NativeAd>> _nativeAds = {};
  final Map<String, AdWrapper<RewardedAd>> _rewardedAds = {};
  final Map<String, AdWrapper<RewardedInterstitialAd>> _rewardedInterstitialAds = {};
  
  // Stream controllers for reactive state management
  final StreamController<Map<String, AdWrapper<NativeAd>>> _nativeAdsController = 
      StreamController<Map<String, AdWrapper<NativeAd>>>.broadcast();
  final StreamController<Map<String, AdWrapper<InterstitialAd>>> _interstitialAdsController = 
      StreamController<Map<String, AdWrapper<InterstitialAd>>>.broadcast();
  final StreamController<Map<String, AdWrapper<RewardedAd>>> _rewardedAdsController = 
      StreamController<Map<String, AdWrapper<RewardedAd>>>.broadcast();
  final StreamController<Map<String, AdWrapper<RewardedInterstitialAd>>> _rewardedInterstitialAdsController = 
      StreamController<Map<String, AdWrapper<RewardedInterstitialAd>>>.broadcast();

  // Rate limiting
  DateTime? _lastLoadTime;
  static const Duration _loadCooldown = Duration(seconds: 2);
  
  // Interstitial ad cooldown tracking
  DateTime? _lastScratchCardInterstitialShowTime;
  static const Duration _scratchCardInterstitialCooldown = Duration(seconds: 60);
  
  // Concurrent load tracking
  int _activeLoads = 0;
  static const int _maxConcurrentLoads = 2;

  // Public getters for reactive UI
  Stream<Map<String, AdWrapper<NativeAd>>> get nativeAdsStream => _nativeAdsController.stream;
  Stream<Map<String, AdWrapper<InterstitialAd>>> get interstitialAdsStream => _interstitialAdsController.stream;
  Stream<Map<String, AdWrapper<RewardedAd>>> get rewardedAdsStream => _rewardedAdsController.stream;
  Stream<Map<String, AdWrapper<RewardedInterstitialAd>>> get rewardedInterstitialAdsStream => _rewardedInterstitialAdsController.stream;
  
  Map<String, AdWrapper<NativeAd>> get currentNativeAds => Map.unmodifiable(_nativeAds);
  Map<String, AdWrapper<InterstitialAd>> get currentInterstitialAds => Map.unmodifiable(_interstitialAds);
  Map<String, AdWrapper<RewardedAd>> get currentRewardedAds => Map.unmodifiable(_rewardedAds);
  Map<String, AdWrapper<RewardedInterstitialAd>> get currentRewardedInterstitialAds => Map.unmodifiable(_rewardedInterstitialAds);

  // Initialization
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Unified ad loading method
  Future<void> loadAd(String adType, {bool isDarkTheme = false}) async {
    // Skip loading if ad is already loaded
    if (isAdLoaded(adType)) {
      return;
    }

    if (!_canLoad()) return;

    _activeLoads++;
    _lastLoadTime = DateTime.now();

    try {
      if (_isNativeAdType(adType)) {
        await _loadNativeAd(adType, isDarkTheme: isDarkTheme);
      } else if (_isInterstitialAdType(adType)) {
        await _loadInterstitialAd(adType);
      } else if (_isRewardedAdType(adType)) {
        await _loadRewardedAd(adType);
      } else if (_isRewardedInterstitialAdType(adType)) {
        await _loadRewardedInterstitialAd(adType);
      }
    } finally {
      _activeLoads--;
    }
  }

  // Get ad with automatic reloading
  T? getAd<T>(String adType) {
    if (T == NativeAd) {
      final wrapper = _nativeAds[adType];
      if (wrapper?.isLoaded == true) {
        final ad = wrapper!.ad!;
        
        // Track usage for native ads
        _updateNativeAdState(adType, wrapper.copyWith(
          usageCount: wrapper.usageCount + 1,
        ));
        
        // For native ads, don't remove immediately - let multiple widgets use the same ad
        // Only schedule reload if ad is getting old (30+ minutes) or if explicitly requested
        if (wrapper.needsReload) {
          _scheduleReload(adType);
        }
        
        return ad as T;
      }
    } else if (T == InterstitialAd) {
      final wrapper = _interstitialAds[adType];
      if (wrapper?.isLoaded == true) {
        final ad = wrapper!.ad!;
        
        // For interstitial ads, remove from cache after use (single use)
        _updateInterstitialAdState(adType, const AdWrapper(state: AdState.idle));
        _scheduleReload(adType);
        
        return ad as T;
      }
    } else if (T == RewardedAd) {
      final wrapper = _rewardedAds[adType];
      if (wrapper?.isLoaded == true) {
        final ad = wrapper!.ad!;
        
        // For rewarded ads, remove from cache after use (single use)
        _updateRewardedAdState(adType, const AdWrapper(state: AdState.idle));
        _scheduleReload(adType);
        
        return ad as T;
      }
    } else if (T == RewardedInterstitialAd) {
      final wrapper = _rewardedInterstitialAds[adType];
      if (wrapper?.isLoaded == true) {
        final ad = wrapper!.ad!;
        
        // For rewarded interstitial ads, remove from cache after use (single use)
        _updateRewardedInterstitialAdState(adType, const AdWrapper(state: AdState.idle));
        _scheduleReload(adType);
        
        return ad as T;
      }
    }
    return null;
  }

  // Force refresh an ad (useful when ad becomes invalid)
  Future<void> forceRefreshAd(String adType, {bool isDarkTheme = false}) async {
    if (_isNativeAdType(adType)) {
      final wrapper = _nativeAds[adType];
      if (wrapper?.ad != null) {
        wrapper!.ad!.dispose();
      }
      _updateNativeAdState(adType, const AdWrapper(state: AdState.idle));
      await loadAd(adType, isDarkTheme: isDarkTheme);
    } else if (_isInterstitialAdType(adType)) {
      final wrapper = _interstitialAds[adType];
      if (wrapper?.ad != null) {
        wrapper!.ad!.dispose();
      }
      _updateInterstitialAdState(adType, const AdWrapper(state: AdState.idle));
      await loadAd(adType);
    } else if (_isRewardedAdType(adType)) {
      final wrapper = _rewardedAds[adType];
      if (wrapper?.ad != null) {
        wrapper!.ad!.dispose();
      }
      _updateRewardedAdState(adType, const AdWrapper(state: AdState.idle));
      await loadAd(adType);
    } else if (_isRewardedInterstitialAdType(adType)) {
      final wrapper = _rewardedInterstitialAds[adType];
      if (wrapper?.ad != null) {
        wrapper!.ad!.dispose();
      }
      _updateRewardedInterstitialAdState(adType, const AdWrapper(state: AdState.idle));
      await loadAd(adType);
    }
  }

  // Check ad availability
  bool isAdLoaded(String adType) {
    if (_isNativeAdType(adType)) {
      return _nativeAds[adType]?.isLoaded ?? false;
    } else if (_isInterstitialAdType(adType)) {
      return _interstitialAds[adType]?.isLoaded ?? false;
    } else if (_isRewardedAdType(adType)) {
      return _rewardedAds[adType]?.isLoaded ?? false;
    } else if (_isRewardedInterstitialAdType(adType)) {
      return _rewardedInterstitialAds[adType]?.isLoaded ?? false;
    }
    return false;
  }
  
  // Debug method to get ad status
  String getAdStatus(String adType) {
    if (_isNativeAdType(adType)) {
      final wrapper = _nativeAds[adType];
      if (wrapper == null) return 'Not initialized';
      return 'State: ${wrapper.state}, UsageCount: ${wrapper.usageCount}, Age: ${wrapper.lastLoadTime != null ? DateTime.now().difference(wrapper.lastLoadTime!).inMinutes : "N/A"} min';
    } else if (_isInterstitialAdType(adType)) {
      final wrapper = _interstitialAds[adType];
      if (wrapper == null) return 'Not initialized';
      return 'State: ${wrapper.state}, Age: ${wrapper.lastLoadTime != null ? DateTime.now().difference(wrapper.lastLoadTime!).inMinutes : "N/A"} min';
    } else if (_isRewardedAdType(adType)) {
      final wrapper = _rewardedAds[adType];
      if (wrapper == null) return 'Not initialized';
      return 'State: ${wrapper.state}, Age: ${wrapper.lastLoadTime != null ? DateTime.now().difference(wrapper.lastLoadTime!).inMinutes : "N/A"} min';
    }
    return 'Unknown ad type';
  }

  // Batch preloading with automatic management
  Future<void> preloadAds({
    List<String> adTypes = const [],
    bool isDarkTheme = false,
  }) async {
    final defaultTypes = adTypes.isEmpty 
        ? ['predict_interstitial'] 
        : adTypes;

    final futures = <Future<void>>[];
    for (final adType in defaultTypes) {
      if (_shouldLoad(adType)) {
        futures.add(loadAd(adType, isDarkTheme: isDarkTheme));
      }
    }

    await Future.wait(futures);
  }

  // Convenience methods for specific ad types

  Future<void> loadPredictInterstitialAd() => loadAd('predict_interstitial');

  Future<void> loadScratchCardInterstitialAd() => loadAd('scratch_card_interstitial');

  Future<void> loadChallengeInterstitialAd() => loadAd('challenge_interstitial');


  InterstitialAd? getPredictInterstitialAd() => getAd<InterstitialAd>('predict_interstitial');
  InterstitialAd? getScratchCardInterstitialAd() => getAd<InterstitialAd>('scratch_card_interstitial');
  InterstitialAd? getChallengeInterstitialAd() => getAd<InterstitialAd>('challenge_interstitial');

  bool get isPredictInterstitialAdLoaded => isAdLoaded('predict_interstitial');
  bool get isScratchCardInterstitialAdLoaded => isAdLoaded('scratch_card_interstitial');
  bool get isChallengeInterstitialAdLoaded => isAdLoaded('challenge_interstitial');

  // Get shared ad for multiple widget usage (doesn't increment usage count)
  T? getSharedAd<T>(String adType) {
    if (T == NativeAd) {
      final wrapper = _nativeAds[adType];
      if (wrapper?.isLoaded == true) {
        // Validate the ad is still usable
        try {
          final ad = wrapper!.ad as NativeAd;
          // Access a property to check if ad is still valid
          final _ = ad.adUnitId;
          return ad as T;
        } catch (e) {
          // Ad is disposed, mark as failed and trigger reload
          _updateNativeAdState(adType, const AdWrapper(state: AdState.failed));
          _scheduleReload(adType);
          return null;
        }
      }
    } else if (T == InterstitialAd) {
      final wrapper = _interstitialAds[adType];
      if (wrapper?.isLoaded == true) {
        return wrapper!.ad as T;
      }
    }
    return null;
  }

  // Check if scratch card interstitial ad can be shown (respects cooldown)
  bool canShowScratchCardInterstitialAd() {
    if (!isScratchCardInterstitialAdLoaded) return false;
    
    if (_lastScratchCardInterstitialShowTime == null) return true;
    
    final timeSinceLastShow = DateTime.now().difference(_lastScratchCardInterstitialShowTime!);
    return timeSinceLastShow >= _scratchCardInterstitialCooldown;
  }

  // Show scratch card interstitial ad with cooldown
  Future<void> showScratchCardInterstitialAd({VoidCallback? onDismissed}) async {
    if (!canShowScratchCardInterstitialAd()) return;
    
    _lastScratchCardInterstitialShowTime = DateTime.now();
    await showInterstitialAd('scratch_card_interstitial', onDismissed: onDismissed);
  }

  // Show interstitial ad with callback
  Future<void> showInterstitialAd(String adType, {VoidCallback? onDismissed}) async {
    final wrapper = _interstitialAds[adType];
    if (wrapper?.isLoaded != true) {
      return;
    }

    final ad = wrapper!.ad!;

    // Update state before showing
    _updateInterstitialAdState(adType, wrapper.copyWith(state: AdState.disposed));

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        // Track ad dismissed
        AnalyticsService.trackAdDismissed(
          adFormat: 'interstitial',
          adUnitId: _getInterstitialAdUnitId(adType) ?? 'unknown',
          placement: adType,
        );
        onDismissed?.call();
        _scheduleReload(adType);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        // Track ad show failure
        AnalyticsService.trackEvent(
          eventName: 'ad_show_failed',
          parameters: {
            'ad_format': 'interstitial',
            'ad_type': adType,
            'error_code': error.code.toString(),
            'error_message': error.message,
          },
        );
        // Handle VP9 codec errors specifically
        final errorMessage = error.toString();
        if (errorMessage.contains('MediaCodec') || errorMessage.contains('VP9')) {
          // Don't retry immediately for codec errors
          _updateInterstitialAdState(adType, AdWrapper(
            state: AdState.failed,
            error: 'Video codec not supported on this device',
          ));
        } else {
          _updateInterstitialAdState(adType, AdWrapper(
            state: AdState.failed,
            error: error.toString(),
          ));
          _scheduleReload(adType);
        }
      },
      onAdShowedFullScreenContent: (ad) {
        // Ad displayed successfully - Track impression
        // Estimated eCPM for interstitial ads: $2.00-$5.00
        AnalyticsService.trackAdImpression(
          adFormat: 'interstitial',
          adUnitId: _getInterstitialAdUnitId(adType) ?? 'unknown',
          adSource: 'admob',
          value: 3.5, // Estimated CPM/1000, adjust based on your actual eCPM
          currency: 'USD',
          placement: adType,
        );
      },
      onAdClicked: (ad) {
        // Track ad click
        AnalyticsService.trackAdClick(
          adFormat: 'interstitial',
          adUnitId: _getInterstitialAdUnitId(adType) ?? 'unknown',
          placement: adType,
        );
      },
    );

    await ad.show();
  }

  // Show rewarded ad with callbacks
  Future<void> showRewardedAd(String adType, {
    VoidCallback? onRewardEarned,
    VoidCallback? onDismissed,
    Function(String)? onFailed,
  }) async {
    final wrapper = _rewardedAds[adType];
    if (wrapper?.isLoaded != true) {
      onFailed?.call('Ad not loaded');
      return;
    }

    final ad = wrapper!.ad!;
    
    // Update state before showing
    _updateRewardedAdState(adType, wrapper.copyWith(state: AdState.disposed));
    
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        AnalyticsService.trackAdDismissed(
          adFormat: 'rewarded',
          adUnitId: _getRewardedAdUnitId(adType) ?? 'unknown',
          placement: adType,
        );
        onDismissed?.call();
        _scheduleReload(adType);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        AnalyticsService.trackEvent(
          eventName: 'ad_show_failed',
          parameters: {
            'ad_format': 'rewarded',
            'ad_type': adType,
            'error_code': error.code.toString(),
            'error_message': error.message,
          },
        );
        _updateRewardedAdState(adType, AdWrapper(
          state: AdState.failed,
          error: error.toString(),
        ));
        onFailed?.call(error.toString());
        _scheduleReload(adType);
      },
      onAdShowedFullScreenContent: (ad) {
        // Estimated eCPM for rewarded ads: $5.00-$15.00
        AnalyticsService.trackAdImpression(
          adFormat: 'rewarded',
          adUnitId: _getRewardedAdUnitId(adType) ?? 'unknown',
          adSource: 'admob',
          value: 10.0, // Estimated CPM/1000
          currency: 'USD',
          placement: adType,
        );
      },
      onAdClicked: (ad) {
        AnalyticsService.trackAdClick(
          adFormat: 'rewarded',
          adUnitId: _getRewardedAdUnitId(adType) ?? 'unknown',
          placement: adType,
        );
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) {
      // Track reward earned
      AnalyticsService.trackEvent(
        eventName: 'ad_reward_earned',
        parameters: {
          'ad_format': 'rewarded',
          'ad_type': adType,
          'reward_type': reward.type,
          'reward_amount': reward.amount,
        },
      );
      onRewardEarned?.call();
    });
  }

  // Show rewarded interstitial ad with callbacks
  Future<void> showRewardedInterstitialAd(String adType, {
    VoidCallback? onRewardEarned,
    VoidCallback? onDismissed,
    Function(String)? onFailed,
  }) async {
    final wrapper = _rewardedInterstitialAds[adType];
    if (wrapper?.isLoaded != true) {
      onFailed?.call('Ad not loaded');
      return;
    }

    final ad = wrapper!.ad!;
    
    // Update state before showing
    _updateRewardedInterstitialAdState(adType, wrapper.copyWith(state: AdState.disposed));
    
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed?.call();
        _scheduleReload(adType);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _updateRewardedInterstitialAdState(adType, AdWrapper(
          state: AdState.failed, 
          error: error.toString(),
        ));
        onFailed?.call(error.toString());
        _scheduleReload(adType);
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned?.call();
    });
  }

  // Clean disposal
  void dispose() {
    // Dispose all ads
    for (final wrapper in _nativeAds.values) {
      wrapper.ad?.dispose();
    }
    for (final wrapper in _interstitialAds.values) {
      wrapper.ad?.dispose();
    }
    for (final wrapper in _rewardedAds.values) {
      wrapper.ad?.dispose();
    }
    for (final wrapper in _rewardedInterstitialAds.values) {
      wrapper.ad?.dispose();
    }
    
    _nativeAds.clear();
    _interstitialAds.clear();
    _rewardedAds.clear();
    _rewardedInterstitialAds.clear();
    
    _nativeAdsController.close();
    _interstitialAdsController.close();
    _rewardedAdsController.close();
    _rewardedInterstitialAdsController.close();
  }

  // Private helper methods

  bool _canLoad() {
    if (_activeLoads >= _maxConcurrentLoads) return false;
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!).inSeconds < _loadCooldown.inSeconds) {
      return false;
    }
    return true;
  }

  bool _shouldLoad(String adType) {
    if (_isNativeAdType(adType)) {
      final wrapper = _nativeAds[adType];
      return wrapper?.canLoad ?? true;
    } else if (_isInterstitialAdType(adType)) {
      final wrapper = _interstitialAds[adType];
      return wrapper?.canLoad ?? true;
    } else if (_isRewardedAdType(adType)) {
      final wrapper = _rewardedAds[adType];
      return wrapper?.canLoad ?? true;
    } else if (_isRewardedInterstitialAdType(adType)) {
      final wrapper = _rewardedInterstitialAds[adType];
      return wrapper?.canLoad ?? true;
    }
    return false;
  }

  Future<void> _loadNativeAd(String adType, {bool isDarkTheme = false}) async {
    _updateNativeAdState(adType, const AdWrapper(state: AdState.loading));

    final adUnitId = _getNativeAdUnitId(adType);
    if (adUnitId == null) {
      _updateNativeAdState(adType, const AdWrapper(
        state: AdState.failed, 
        error: 'Invalid ad type',
      ));
      return;
    }

    final completer = Completer<void>();
    
    final ad = _createNativeAd(
      adUnitId: adUnitId,
      isDarkTheme: isDarkTheme,
      onLoaded: (ad) {
        _updateNativeAdState(adType, AdWrapper(
          ad: ad,
          state: AdState.loaded,
          lastLoadTime: DateTime.now(),
        ));
        completer.complete();
      },
      onFailed: (ad, error) {
        ad.dispose();
        _updateNativeAdState(adType, AdWrapper(
          state: AdState.failed,
          error: error.toString(),
        ));
        completer.complete();
      },
    );

    ad.load();
    return completer.future;
  }

  Future<void> _loadInterstitialAd(String adType) async {
    _updateInterstitialAdState(adType, const AdWrapper(state: AdState.loading));

    final adUnitId = _getInterstitialAdUnitId(adType);
    if (adUnitId == null) {
      _updateInterstitialAdState(adType, const AdWrapper(
        state: AdState.failed,
        error: 'Invalid ad type',
      ));
      return;
    }

    final completer = Completer<void>();

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(
          httpTimeoutMillis: 30000,
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _updateInterstitialAdState(adType, AdWrapper(
              ad: ad,
              state: AdState.loaded,
              lastLoadTime: DateTime.now(),
            ));
            // Track ad load success
            AnalyticsService.trackEvent(
              eventName: 'ad_loaded',
              parameters: {
                'ad_format': 'interstitial',
                'ad_unit_id': adUnitId,
                'ad_type': adType,
              },
            );
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            _updateInterstitialAdState(adType, AdWrapper(
              state: AdState.failed,
              error: error.toString(),
            ));
            // Track ad load failure
            AnalyticsService.trackAdLoadFailed(
              adFormat: 'interstitial',
              adUnitId: adUnitId,
              errorCode: error.code.toString(),
              errorMessage: error.message,
            );
            completer.complete();
          },
        ),
      );
    } catch (e) {
      // Catch native GPU/WebView crashes
      _updateInterstitialAdState(adType, AdWrapper(
        state: AdState.failed,
        error: 'Failed to load ad: ${e.toString()}',
      ));
      completer.complete();
    }

    return completer.future;
  }

  NativeAd _createNativeAd({
    required String adUnitId,
    required bool isDarkTheme,
    required Function(NativeAd) onLoaded,
    required Function(NativeAd, LoadAdError) onFailed,
  }) {
    final primaryTextColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.white70 : Colors.black54;
    final tertiaryTextColor = isDarkTheme ? Colors.white60 : Colors.black45;
    final backgroundColor = isDarkTheme ? Colors.grey[850] : Colors.white;
    
    return NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          onLoaded(ad as NativeAd);
          // Track ad load success
          AnalyticsService.trackEvent(
            eventName: 'ad_loaded',
            parameters: {
              'ad_format': 'native',
              'ad_unit_id': adUnitId,
            },
          );
        },
        onAdFailedToLoad: (ad, error) {
          onFailed(ad as NativeAd, error);
          // Track ad load failure
          AnalyticsService.trackAdLoadFailed(
            adFormat: 'native',
            adUnitId: adUnitId,
            errorCode: error.code.toString(),
            errorMessage: error.message,
          );
        },
        onAdImpression: (ad) {
          // Track ad impression (when ad is actually viewed)
          // Estimated eCPM for native ads: $0.50-$2.00
          AnalyticsService.trackAdImpression(
            adFormat: 'native',
            adUnitId: adUnitId,
            adSource: 'admob',
            value: 1.0, // Estimated CPM/1000, adjust based on your actual eCPM
            currency: 'USD',
            placement: 'content_feed',
          );
        },
        onAdClicked: (ad) {
          // Track ad click
          AnalyticsService.trackAdClick(
            adFormat: 'native',
            adUnitId: adUnitId,
            placement: 'content_feed',
          );
        },
        onAdClosed: (ad) {
          // Track ad dismissed (if applicable)
          AnalyticsService.trackAdDismissed(
            adFormat: 'native',
            adUnitId: adUnitId,
            placement: 'content_feed',
          );
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: backgroundColor,
        cornerRadius: 8.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue[600]!,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: primaryTextColor,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: secondaryTextColor,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: tertiaryTextColor,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
        shouldRequestMultipleImages: false,
        shouldReturnUrlsForImageAssets: false,
      ),
    );
  }

  void _updateNativeAdState(String adType, AdWrapper<NativeAd> wrapper) {
    _nativeAds[adType] = wrapper;
    _nativeAdsController.add(Map.unmodifiable(_nativeAds));
  }

  void _updateInterstitialAdState(String adType, AdWrapper<InterstitialAd> wrapper) {
    _interstitialAds[adType] = wrapper;
    _interstitialAdsController.add(Map.unmodifiable(_interstitialAds));
  }

  void _scheduleReload(String adType) {
    Future.delayed(const Duration(seconds: 1), () {
      if (_shouldLoad(adType)) {
        loadAd(adType);
      }
    });
  }

  // Type checking helpers
  bool _isNativeAdType(String adType) {
    return ['live_video'].contains(adType);
  }

  bool _isInterstitialAdType(String adType) {
    return ['predict_interstitial', 'seemore_interstitial', 'scratch_card_interstitial', 'challenge_interstitial'].contains(adType);
  }

  String? _getNativeAdUnitId(String adType) {
    switch (adType) {
      case 'live_video': return nativeLiveVideo;
      default: return null;
    }
  }

  String? _getInterstitialAdUnitId(String adType) {
    switch (adType) {
      case 'predict_interstitial': return useTestAds ? testInterstitial : interstitialResultsPredict;
      case 'seemore_interstitial': return useTestAds ? testInterstitial : interstitialResultsSeemore;
      case 'scratch_card_interstitial': return useTestAds ? testInterstitial : interstitialScratchCard;
      case 'challenge_interstitial': return useTestAds ? testInterstitial : interstitialChallenge;
      default: return null;
    }
  }

  bool _isRewardedAdType(String adType) {
    return false; // No rewarded ads currently in use
  }

  bool _isRewardedInterstitialAdType(String adType) {
    return ['scratch_card_rewarded_interstitial'].contains(adType);
  }

  String? _getRewardedAdUnitId(String adType) {
    // No rewarded ads currently in use
    return null;
  }

  String? _getRewardedInterstitialAdUnitId(String adType) {
    switch (adType) {
      default: return null;
    }
  }

  Future<void> _loadRewardedAd(String adType) async {
    _updateRewardedAdState(adType, const AdWrapper(state: AdState.loading));

    final adUnitId = _getRewardedAdUnitId(adType);
    if (adUnitId == null) {
      _updateRewardedAdState(adType, const AdWrapper(
        state: AdState.failed,
        error: 'Invalid ad type',
      ));
      return;
    }

    final completer = Completer<void>();

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _updateRewardedAdState(adType, AdWrapper(
            ad: ad,
            state: AdState.loaded,
            lastLoadTime: DateTime.now(),
          ));
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _updateRewardedAdState(adType, AdWrapper(
            state: AdState.failed,
            error: error.toString(),
          ));
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  Future<void> _loadRewardedInterstitialAd(String adType) async {
    _updateRewardedInterstitialAdState(adType, const AdWrapper(state: AdState.loading));

    final adUnitId = _getRewardedInterstitialAdUnitId(adType);
    if (adUnitId == null) {
      _updateRewardedInterstitialAdState(adType, const AdWrapper(
        state: AdState.failed,
        error: 'Invalid ad type',
      ));
      return;
    }

    final completer = Completer<void>();

    await RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _updateRewardedInterstitialAdState(adType, AdWrapper(
            ad: ad,
            state: AdState.loaded,
            lastLoadTime: DateTime.now(),
          ));
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _updateRewardedInterstitialAdState(adType, AdWrapper(
            state: AdState.failed,
            error: error.toString(),
          ));
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  void _updateRewardedAdState(String adType, AdWrapper<RewardedAd> wrapper) {
    _rewardedAds[adType] = wrapper;
    _rewardedAdsController.add(Map.unmodifiable(_rewardedAds));
  }

  void _updateRewardedInterstitialAdState(String adType, AdWrapper<RewardedInterstitialAd> wrapper) {
    _rewardedInterstitialAds[adType] = wrapper;
    _rewardedInterstitialAdsController.add(Map.unmodifiable(_rewardedInterstitialAds));
  }

  // Legacy method support for backward compatibility


  @Deprecated('Use internal load management instead')
  bool get canLoadAds => _canLoad();

  @Deprecated('Use preloadAds() instead')
  Future<void> preloadAdsOld() => preloadAds();

  @Deprecated('Use preloadAds() with specific ad types instead')
  Future<void> smartPreload({bool isDarkTheme = false, bool isHomeScreen = false}) {
    final adTypes = isHomeScreen 
        ? ['predict_interstitial']
        : ['live_video', 'lotto_points', 'news_feed'];
    return preloadAds(adTypes: adTypes, isDarkTheme: isDarkTheme);
  }

  @Deprecated('Use dispose() instead')
  void disposeNativeAds() {
    for (final wrapper in _nativeAds.values) {
      wrapper.ad?.dispose();
    }
    _nativeAds.clear();
    _nativeAdsController.add(Map.unmodifiable(_nativeAds));
  }

  // Additional legacy methods for other ad types

  @Deprecated('Use loadAd() instead')
  Future<void> preloadLiveVideoAd({bool isDarkTheme = false}) =>
      loadAd('live_video', isDarkTheme: isDarkTheme);

  @Deprecated('Use getAd() instead')
  NativeAd? getCachedLiveVideoAd() => getAd<NativeAd>('live_video');

  @Deprecated('Use _createNativeAd() or loadAd() instead')
  NativeAd createNewsStyleNativeLiveVideoAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNativeAd(
      adUnitId: nativeLiveVideo,
      isDarkTheme: isDarkTheme,
      onLoaded: (ad) => listener.onAdLoaded?.call(ad),
      onFailed: (ad, error) => listener.onAdFailedToLoad?.call(ad, error),
    );
  }
}