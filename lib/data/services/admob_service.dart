import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

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
  
  // NATIVE AD UNIT IDs
  static const String nativeHomeResults = 'ca-app-pub-1386225714525775/1332117098';
  static const String nativeLiveVideo = 'ca-app-pub-1386225714525775/5079790413';
  static const String nativeLottoPoints = 'ca-app-pub-1386225714525775/5247311376';
  static const String nativeNewsFeed = 'ca-app-pub-1386225714525775/6560393048';
  
  // REWARDED AD UNIT IDs
  static const String rewardedCashbackClaim = 'ca-app-pub-1386225714525775/9155813941';
  static const String rewardedLottoPoints = 'ca-app-pub-1386225714525775/9572986036';

  // Consolidated ad state management
  final Map<String, AdWrapper<InterstitialAd>> _interstitialAds = {};
  final Map<String, AdWrapper<NativeAd>> _nativeAds = {};
  final Map<String, AdWrapper<RewardedAd>> _rewardedAds = {};
  
  // Stream controllers for reactive state management
  final StreamController<Map<String, AdWrapper<NativeAd>>> _nativeAdsController = 
      StreamController<Map<String, AdWrapper<NativeAd>>>.broadcast();
  final StreamController<Map<String, AdWrapper<InterstitialAd>>> _interstitialAdsController = 
      StreamController<Map<String, AdWrapper<InterstitialAd>>>.broadcast();
  final StreamController<Map<String, AdWrapper<RewardedAd>>> _rewardedAdsController = 
      StreamController<Map<String, AdWrapper<RewardedAd>>>.broadcast();

  // Rate limiting
  DateTime? _lastLoadTime;
  static const Duration _loadCooldown = Duration(seconds: 2);
  
  // Concurrent load tracking
  int _activeLoads = 0;
  static const int _maxConcurrentLoads = 2;

  // Public getters for reactive UI
  Stream<Map<String, AdWrapper<NativeAd>>> get nativeAdsStream => _nativeAdsController.stream;
  Stream<Map<String, AdWrapper<InterstitialAd>>> get interstitialAdsStream => _interstitialAdsController.stream;
  Stream<Map<String, AdWrapper<RewardedAd>>> get rewardedAdsStream => _rewardedAdsController.stream;
  
  Map<String, AdWrapper<NativeAd>> get currentNativeAds => Map.unmodifiable(_nativeAds);
  Map<String, AdWrapper<InterstitialAd>> get currentInterstitialAds => Map.unmodifiable(_interstitialAds);
  Map<String, AdWrapper<RewardedAd>> get currentRewardedAds => Map.unmodifiable(_rewardedAds);

  // Initialization
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Unified ad loading method
  Future<void> loadAd(String adType, {bool isDarkTheme = false}) async {
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
        ? ['home_results', 'predict_interstitial'] 
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
  Future<void> loadHomeResultsAd({bool isDarkTheme = false}) => 
      loadAd('home_results', isDarkTheme: isDarkTheme);
  
  Future<void> loadPredictInterstitialAd() => loadAd('predict_interstitial');
  
  Future<void> loadCashbackClaimRewardedAd() => loadAd('cashback_claim_rewarded');
  
  Future<void> loadLottoPointsRewardedAd() => loadAd('lotto_points_rewarded');
  
  NativeAd? getHomeResultsAd() => getAd<NativeAd>('home_results');
  NativeAd? getSharedHomeResultsAd() => getSharedAd<NativeAd>('home_results');
  InterstitialAd? getPredictInterstitialAd() => getAd<InterstitialAd>('predict_interstitial');
  RewardedAd? getCashbackClaimRewardedAd() => getAd<RewardedAd>('cashback_claim_rewarded');
  RewardedAd? getLottoPointsRewardedAd() => getAd<RewardedAd>('lotto_points_rewarded');
  
  bool get isHomeResultsAdLoaded => isAdLoaded('home_results');
  bool get isPredictInterstitialAdLoaded => isAdLoaded('predict_interstitial');
  bool get isCashbackClaimRewardedAdLoaded => isAdLoaded('cashback_claim_rewarded');
  bool get isLottoPointsRewardedAdLoaded => isAdLoaded('lotto_points_rewarded');

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

  // Show interstitial ad with callback
  Future<void> showInterstitialAd(String adType, {VoidCallback? onDismissed}) async {
    final wrapper = _interstitialAds[adType];
    if (wrapper?.isLoaded != true) return;

    final ad = wrapper!.ad!;
    
    // Update state before showing
    _updateInterstitialAdState(adType, wrapper.copyWith(state: AdState.disposed));
    
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed?.call();
        _scheduleReload(adType);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _updateInterstitialAdState(adType, AdWrapper(
          state: AdState.failed, 
          error: error.toString(),
        ));
        _scheduleReload(adType);
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
        onDismissed?.call();
        _scheduleReload(adType);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _updateRewardedAdState(adType, AdWrapper(
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
    
    _nativeAds.clear();
    _interstitialAds.clear();
    _rewardedAds.clear();
    
    _nativeAdsController.close();
    _interstitialAdsController.close();
    _rewardedAdsController.close();
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

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _updateInterstitialAdState(adType, AdWrapper(
            ad: ad,
            state: AdState.loaded,
            lastLoadTime: DateTime.now(),
          ));
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _updateInterstitialAdState(adType, AdWrapper(
            state: AdState.failed,
            error: error.toString(),
          ));
          completer.complete();
        },
      ),
    );

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
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) => onFailed(ad as NativeAd, error),
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
    return ['home_results', 'live_video', 'lotto_points', 'news_feed'].contains(adType);
  }

  bool _isInterstitialAdType(String adType) {
    return ['predict_interstitial', 'seemore_interstitial'].contains(adType);
  }

  String? _getNativeAdUnitId(String adType) {
    switch (adType) {
      case 'home_results': return nativeHomeResults;
      case 'live_video': return nativeLiveVideo;
      case 'lotto_points': return nativeLottoPoints;
      case 'news_feed': return nativeNewsFeed;
      default: return null;
    }
  }

  String? _getInterstitialAdUnitId(String adType) {
    switch (adType) {
      case 'predict_interstitial': return interstitialResultsPredict;
      case 'seemore_interstitial': return interstitialResultsSeemore;
      default: return null;
    }
  }

  bool _isRewardedAdType(String adType) {
    return ['cashback_claim_rewarded', 'lotto_points_rewarded'].contains(adType);
  }

  String? _getRewardedAdUnitId(String adType) {
    switch (adType) {
      case 'cashback_claim_rewarded': return rewardedCashbackClaim;
      case 'lotto_points_rewarded': return rewardedLottoPoints;
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

  void _updateRewardedAdState(String adType, AdWrapper<RewardedAd> wrapper) {
    _rewardedAds[adType] = wrapper;
    _rewardedAdsController.add(Map.unmodifiable(_rewardedAds));
  }

  // Legacy method support for backward compatibility
  @Deprecated('Use getHomeResultsAd() instead')
  NativeAd createNewsStyleNativeHomeResultsAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNativeAd(
      adUnitId: nativeHomeResults,
      isDarkTheme: isDarkTheme,
      onLoaded: (ad) => listener.onAdLoaded?.call(ad),
      onFailed: (ad, error) => listener.onAdFailedToLoad?.call(ad, error),
    );
  }

  @Deprecated('Use getHomeResultsAd() instead')
  NativeAd? getCachedHomeResultsAd() => getHomeResultsAd();

  @Deprecated('Use internal load management instead')
  bool get canLoadAds => _canLoad();

  @Deprecated('Use preloadAds() instead')
  Future<void> preloadAdsOld() => preloadAds();

  @Deprecated('Use preloadAds() with specific ad types instead')
  Future<void> smartPreload({bool isDarkTheme = false, bool isHomeScreen = false}) {
    final adTypes = isHomeScreen 
        ? ['home_results', 'predict_interstitial']
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
  Future<void> preloadHomeResultsAd({bool isDarkTheme = false}) => 
      loadHomeResultsAd(isDarkTheme: isDarkTheme);

  @Deprecated('Use loadAd() instead')
  Future<void> preloadLiveVideoAd({bool isDarkTheme = false}) => 
      loadAd('live_video', isDarkTheme: isDarkTheme);

  @Deprecated('Use loadAd() instead')
  Future<void> preloadLottoPointsAd({bool isDarkTheme = false}) => 
      loadAd('lotto_points', isDarkTheme: isDarkTheme);

  @Deprecated('Use loadAd() instead')
  Future<void> preloadNewsFeedAd({bool isDarkTheme = false}) => 
      loadAd('news_feed', isDarkTheme: isDarkTheme);

  @Deprecated('Use getAd() instead')
  NativeAd? getCachedLiveVideoAd() => getAd<NativeAd>('live_video');

  @Deprecated('Use getAd() instead')
  NativeAd? getCachedLottoPointsAd() => getAd<NativeAd>('lotto_points');

  @Deprecated('Use getAd() instead')
  NativeAd? getCachedNewsFeedAd() => getAd<NativeAd>('news_feed');

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

  @Deprecated('Use _createNativeAd() or loadAd() instead')
  NativeAd createNewsStyleNativeLottoPointsAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNativeAd(
      adUnitId: nativeLottoPoints,
      isDarkTheme: isDarkTheme,
      onLoaded: (ad) => listener.onAdLoaded?.call(ad),
      onFailed: (ad, error) => listener.onAdFailedToLoad?.call(ad, error),
    );
  }

  @Deprecated('Use _createNativeAd() or loadAd() instead')
  NativeAd createNewsStyleNativeNewsFeedAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNativeAd(
      adUnitId: nativeNewsFeed,
      isDarkTheme: isDarkTheme,
      onLoaded: (ad) => listener.onAdLoaded?.call(ad),
      onFailed: (ad, error) => listener.onAdFailedToLoad?.call(ad, error),
    );
  }
}