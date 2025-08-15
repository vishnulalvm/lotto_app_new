import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:math';

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

  // Ad instances
  InterstitialAd? _interstitialPredictAd;
  InterstitialAd? _interstitialSeemoreAd;
  
  // Native ad cache
  NativeAd? _cachedHomeResultsAd;
  NativeAd? _cachedLiveVideoAd;
  NativeAd? _cachedLottoPointsAd;
  NativeAd? _cachedNewsFeedAd;

  // Ad loading states
  bool _isInterstitialPredictAdLoaded = false;
  bool _isInterstitialSeemoreAdLoaded = false;
  bool _isHomeResultsAdLoaded = false;
  bool _isLiveVideoAdLoaded = false;
  bool _isLottoPointsAdLoaded = false;
  bool _isNewsFeedAdLoaded = false;

  // Performance tracking
  final Map<String, DateTime> _loadStartTimes = {};
  final Map<String, int> _loadAttempts = {};
  
  // Rate limiting
  DateTime? _lastBatchLoadTime;
  static const Duration _batchLoadCooldown = Duration(seconds: 10);
  
  // Maximum concurrent ad loads
  int _currentLoadOperations = 0;
  static const int _maxConcurrentLoads = 2;

  // Initialization
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Get Production Ad Unit IDs
  String get interstitialPredictAdUnitId => interstitialResultsPredict;
  String get interstitialSeemoreAdUnitId => interstitialResultsSeemore;
  String get nativeHomeResultsAdUnitId => nativeHomeResults;
  String get nativeLiveVideoAdUnitId => nativeLiveVideo;
  String get nativeLottoPointsAdUnitId => nativeLottoPoints;
  String get nativeNewsFeedAdUnitId => nativeNewsFeed;

  // Interstitial Predict Ad Methods
  Future<void> loadInterstitialPredictAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialPredictAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialPredictAd = ad;
          _isInterstitialPredictAdLoaded = true;
          
          // Set full screen content callback
          _interstitialPredictAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialPredictAd = null;
              _isInterstitialPredictAdLoaded = false;
              // Preload next ad
              loadInterstitialPredictAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialPredictAd = null;
              _isInterstitialPredictAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialPredictAdLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitialPredictAd({
    Function()? onAdDismissed,
  }) async {
    if (_interstitialPredictAd != null && _isInterstitialPredictAdLoaded) {
      _interstitialPredictAd?.show();
      
      // Set callback for when ad is dismissed
      if (onAdDismissed != null) {
        _interstitialPredictAd?.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialPredictAd = null;
            _isInterstitialPredictAdLoaded = false;
            onAdDismissed();
            // Preload next ad
            loadInterstitialPredictAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialPredictAd = null;
            _isInterstitialPredictAdLoaded = false;
          },
        );
      }
    }
  }

  bool get isInterstitialPredictAdLoaded => _isInterstitialPredictAdLoaded;

  // Interstitial Seemore Ad Methods
  Future<void> loadInterstitialSeemoreAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialSeemoreAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialSeemoreAd = ad;
          _isInterstitialSeemoreAdLoaded = true;
          
          // Set full screen content callback
          _interstitialSeemoreAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialSeemoreAd = null;
              _isInterstitialSeemoreAdLoaded = false;
              // Preload next ad
              loadInterstitialSeemoreAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialSeemoreAd = null;
              _isInterstitialSeemoreAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialSeemoreAdLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitialSeemoreAd({
    Function()? onAdDismissed,
  }) async {
    if (_interstitialSeemoreAd != null && _isInterstitialSeemoreAdLoaded) {
      _interstitialSeemoreAd?.show();
      
      // Set callback for when ad is dismissed
      if (onAdDismissed != null) {
        _interstitialSeemoreAd?.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialSeemoreAd = null;
            _isInterstitialSeemoreAdLoaded = false;
            onAdDismissed();
            // Preload next ad
            loadInterstitialSeemoreAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialSeemoreAd = null;
            _isInterstitialSeemoreAdLoaded = false;
          },
        );
      }
    }
  }

  bool get isInterstitialSeemoreAdLoaded => _isInterstitialSeemoreAdLoaded;


  // Dispose methods
  void disposeInterstitialPredictAd() {
    _interstitialPredictAd?.dispose();
    _interstitialPredictAd = null;
    _isInterstitialPredictAdLoaded = false;
  }

  void disposeInterstitialSeemoreAd() {
    _interstitialSeemoreAd?.dispose();
    _interstitialSeemoreAd = null;
    _isInterstitialSeemoreAdLoaded = false;
  }

  void disposeNativeAds() {
    _cachedHomeResultsAd?.dispose();
    _cachedLiveVideoAd?.dispose();
    _cachedLottoPointsAd?.dispose();
    _cachedNewsFeedAd?.dispose();
    
    _cachedHomeResultsAd = null;
    _cachedLiveVideoAd = null;
    _cachedLottoPointsAd = null;
    _cachedNewsFeedAd = null;
    
    _isHomeResultsAdLoaded = false;
    _isLiveVideoAdLoaded = false;
    _isLottoPointsAdLoaded = false;
    _isNewsFeedAdLoaded = false;
  }

  void disposeAll() {
    disposeInterstitialPredictAd();
    disposeInterstitialSeemoreAd();
    disposeNativeAds();
  }

  // Legacy Native Ad Methods Removed - All widgets now use optimized news-style methods

  // Create news-styled native ads for different locations
  NativeAd createNewsStyleNativeHomeResultsAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNewsStyleNativeAd(
      adUnitId: nativeHomeResultsAdUnitId,
      listener: listener,
      isDarkTheme: isDarkTheme,
    );
  }

  NativeAd createNewsStyleNativeLiveVideoAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNewsStyleNativeAd(
      adUnitId: nativeLiveVideoAdUnitId,
      listener: listener,
      isDarkTheme: isDarkTheme,
    );
  }

  NativeAd createNewsStyleNativeLottoPointsAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNewsStyleNativeAd(
      adUnitId: nativeLottoPointsAdUnitId,
      listener: listener,
      isDarkTheme: isDarkTheme,
    );
  }

  NativeAd createNewsStyleNativeNewsFeedAd({
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    return _createNewsStyleNativeAd(
      adUnitId: nativeNewsFeedAdUnitId,
      listener: listener,
      isDarkTheme: isDarkTheme,
    );
  }

  // Private helper method for consistent styling
  NativeAd _createNewsStyleNativeAd({
    required String adUnitId,
    required NativeAdListener listener,
    bool isDarkTheme = false,
  }) {
    final primaryTextColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.white70 : Colors.black54;
    final tertiaryTextColor = isDarkTheme ? Colors.white60 : Colors.black45;
    final backgroundColor = isDarkTheme ? Colors.grey[850] : Colors.white;
    
    return NativeAd(
      adUnitId: adUnitId,
      listener: listener,
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

  // Native ad preloading methods  
  Future<void> preloadHomeResultsAd({bool isDarkTheme = false}) async {
    if (_cachedHomeResultsAd != null) {
      _cachedHomeResultsAd!.dispose();
    }
    
    _cachedHomeResultsAd = _createNewsStyleNativeAd(
      adUnitId: nativeHomeResultsAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => _isHomeResultsAdLoaded = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isHomeResultsAdLoaded = false;
        },
      ),
      isDarkTheme: isDarkTheme,
    );
    
    await _cachedHomeResultsAd!.load();
  }
  
  Future<void> preloadLiveVideoAd({bool isDarkTheme = false}) async {
    if (_cachedLiveVideoAd != null) {
      _cachedLiveVideoAd!.dispose();
    }
    
    _cachedLiveVideoAd = _createNewsStyleNativeAd(
      adUnitId: nativeLiveVideoAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => _isLiveVideoAdLoaded = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLiveVideoAdLoaded = false;
        },
      ),
      isDarkTheme: isDarkTheme,
    );
    
    await _cachedLiveVideoAd!.load();
  }
  
  Future<void> preloadLottoPointsAd({bool isDarkTheme = false}) async {
    if (_cachedLottoPointsAd != null) {
      _cachedLottoPointsAd!.dispose();
    }
    
    _cachedLottoPointsAd = _createNewsStyleNativeAd(
      adUnitId: nativeLottoPointsAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => _isLottoPointsAdLoaded = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLottoPointsAdLoaded = false;
        },
      ),
      isDarkTheme: isDarkTheme,
    );
    
    await _cachedLottoPointsAd!.load();
  }
  
  Future<void> preloadNewsFeedAd({bool isDarkTheme = false}) async {
    if (_cachedNewsFeedAd != null) {
      _cachedNewsFeedAd!.dispose();
    }
    
    _cachedNewsFeedAd = _createNewsStyleNativeAd(
      adUnitId: nativeNewsFeedAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => _isNewsFeedAdLoaded = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isNewsFeedAdLoaded = false;
        },
      ),
      isDarkTheme: isDarkTheme,
    );
    
    await _cachedNewsFeedAd!.load();
  }

  // Get cached native ads
  NativeAd? getCachedHomeResultsAd() {
    if (_isHomeResultsAdLoaded && _cachedHomeResultsAd != null) {
      final ad = _cachedHomeResultsAd!;
      _cachedHomeResultsAd = null;
      _isHomeResultsAdLoaded = false;
      // Preload next ad in background
      Future.delayed(const Duration(milliseconds: 100), () {
        preloadHomeResultsAd();
      });
      return ad;
    }
    return null;
  }
  
  NativeAd? getCachedLiveVideoAd() {
    if (_isLiveVideoAdLoaded && _cachedLiveVideoAd != null) {
      final ad = _cachedLiveVideoAd!;
      _cachedLiveVideoAd = null;
      _isLiveVideoAdLoaded = false;
      // Preload next ad in background
      Future.delayed(const Duration(milliseconds: 100), () {
        preloadLiveVideoAd();
      });
      return ad;
    }
    return null;
  }
  
  NativeAd? getCachedLottoPointsAd() {
    if (_isLottoPointsAdLoaded && _cachedLottoPointsAd != null) {
      final ad = _cachedLottoPointsAd!;
      _cachedLottoPointsAd = null;
      _isLottoPointsAdLoaded = false;
      // Preload next ad in background
      Future.delayed(const Duration(milliseconds: 100), () {
        preloadLottoPointsAd();
      });
      return ad;
    }
    return null;
  }
  
  NativeAd? getCachedNewsFeedAd() {
    if (_isNewsFeedAdLoaded && _cachedNewsFeedAd != null) {
      final ad = _cachedNewsFeedAd!;
      _cachedNewsFeedAd = null;
      _isNewsFeedAdLoaded = false;
      // Preload next ad in background
      Future.delayed(const Duration(milliseconds: 100), () {
        preloadNewsFeedAd();
      });
      return ad;
    }
    return null;
  }

  // Check if cached ads are available
  bool get isHomeResultsAdCached => _isHomeResultsAdLoaded;
  bool get isLiveVideoAdCached => _isLiveVideoAdLoaded;
  bool get isLottoPointsAdCached => _isLottoPointsAdLoaded;
  bool get isNewsFeedAdCached => _isNewsFeedAdLoaded;

  // Enhanced native ads preloading with smart batching
  Future<void> preloadNativeAds({bool isDarkTheme = false}) async {
    if (_currentLoadOperations >= _maxConcurrentLoads) {
      // Queue for later if system is busy
      Future.delayed(const Duration(seconds: 5), () {
        preloadNativeAds(isDarkTheme: isDarkTheme);
      });
      return;
    }
    
    // Rate limiting for native ads
    if (_lastBatchLoadTime != null && 
        DateTime.now().difference(_lastBatchLoadTime!).inSeconds < _batchLoadCooldown.inSeconds) {
      return;
    }
    
    _lastBatchLoadTime = DateTime.now();
    
    // Load high-priority ads first (home screen)
    unawaited(_loadWithRetry('native_home', () => preloadHomeResultsAd(isDarkTheme: isDarkTheme)));
    
    // Stagger other native ads with longer delays
    await Future.delayed(const Duration(milliseconds: 800));
    unawaited(_loadWithRetry('native_live', () => preloadLiveVideoAd(isDarkTheme: isDarkTheme)));
    
    await Future.delayed(const Duration(milliseconds: 800));
    unawaited(_loadWithRetry('native_lotto', () => preloadLottoPointsAd(isDarkTheme: isDarkTheme)));
    
    await Future.delayed(const Duration(milliseconds: 800));
    unawaited(_loadWithRetry('native_news', () => preloadNewsFeedAd(isDarkTheme: isDarkTheme)));
  }
  
  // Smart preloading based on app state
  Future<void> smartPreload({bool isDarkTheme = false, bool isHomeScreen = false}) async {
    if (isHomeScreen) {
      // Prioritize home screen ads
      await _loadWithRetry('native_home', () => preloadHomeResultsAd(isDarkTheme: isDarkTheme));
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadWithRetry('interstitial_predict', () => loadInterstitialPredictAd());
    } else {
      // Load other ads in background
      await preloadNativeAds(isDarkTheme: isDarkTheme);
    }
  }
  
  // Check system load before loading ads
  bool get canLoadAds => _currentLoadOperations < _maxConcurrentLoads;
  
  // Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'current_load_operations': _currentLoadOperations,
      'load_attempts': Map.from(_loadAttempts),
      'can_load_ads': canLoadAds,
      'last_batch_load': _lastBatchLoadTime?.toIso8601String(),
    };
  }

  // Enhanced preload with performance optimization
  Future<void> preloadAds() async {
    if (_currentLoadOperations >= _maxConcurrentLoads) {
      return; // Prevent overwhelming the system
    }
    
    // Rate limiting
    if (_lastBatchLoadTime != null && 
        DateTime.now().difference(_lastBatchLoadTime!).inSeconds < _batchLoadCooldown.inSeconds) {
      return;
    }
    
    _lastBatchLoadTime = DateTime.now();
    
    // Load interstitials with staggered timing
    unawaited(_loadWithRetry('interstitial_predict', () => loadInterstitialPredictAd()));
    
    await Future.delayed(const Duration(milliseconds: 500));
    unawaited(_loadWithRetry('interstitial_seemore', () => loadInterstitialSeemoreAd()));
  }
  
  // Enhanced loading with retry logic and performance tracking
  Future<void> _loadWithRetry(String adType, Future<void> Function() loadFunction) async {
    if (_currentLoadOperations >= _maxConcurrentLoads) {
      return;
    }
    
    _currentLoadOperations++;
    _loadStartTimes[adType] = DateTime.now();
    _loadAttempts[adType] = (_loadAttempts[adType] ?? 0) + 1;
    
    try {
      await loadFunction();
      _logLoadSuccess(adType);
    } catch (e) {
      _logLoadFailure(adType, e);
      
      // Retry with exponential backoff if attempts < 3
      if ((_loadAttempts[adType] ?? 0) < 3) {
        final delay = Duration(seconds: pow(2, _loadAttempts[adType]! - 1).toInt());
        await Future.delayed(delay);
        unawaited(_loadWithRetry(adType, loadFunction));
      }
    } finally {
      _currentLoadOperations--;
    }
  }
  
  void _logLoadSuccess(String adType) {
    final loadTime = _loadStartTimes[adType];
    if (loadTime != null) {
      final duration = DateTime.now().difference(loadTime);
      debugPrint('✅ Ad loaded: $adType in ${duration.inMilliseconds}ms');
    }
  }
  
  void _logLoadFailure(String adType, dynamic error) {
    debugPrint('❌ Ad load failed: $adType - $error');
  }
}