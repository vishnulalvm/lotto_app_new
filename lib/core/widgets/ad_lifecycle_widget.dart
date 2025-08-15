import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class AdLifecycleWidget extends StatefulWidget {
  final Widget child;
  final String adType;
  final bool isDarkTheme;
  final bool preloadOnInit;
  
  const AdLifecycleWidget({
    super.key,
    required this.child,
    required this.adType,
    this.isDarkTheme = false,
    this.preloadOnInit = true,
  });

  @override
  State<AdLifecycleWidget> createState() => _AdLifecycleWidgetState();
}

class _AdLifecycleWidgetState extends State<AdLifecycleWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _hasPreloaded = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (widget.preloadOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadAdSafely();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAd();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background - dispose ads to free memory
        _disposeAd();
        break;
      case AppLifecycleState.resumed:
        // App back to foreground - preload if needed
        if (!_isAdLoaded && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _preloadAdSafely();
          });
        }
        break;
      case AppLifecycleState.detached:
        _disposeAd();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _preloadAdSafely() async {
    if (_hasPreloaded || !mounted) return;
    
    try {
      // Check if system can handle ad loading
      if (!AdMobService.instance.canLoadAds) {
        // Schedule retry later
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _preloadAdSafely();
        });
        return;
      }
      
      _hasPreloaded = true;
      
      switch (widget.adType) {
        case 'home_results':
          await AdMobService.instance.preloadHomeResultsAd(
            isDarkTheme: widget.isDarkTheme,
          );
          break;
        case 'live_video':
          await AdMobService.instance.preloadLiveVideoAd(
            isDarkTheme: widget.isDarkTheme,
          );
          break;
        case 'lotto_points':
          await AdMobService.instance.preloadLottoPointsAd(
            isDarkTheme: widget.isDarkTheme,
          );
          break;
        case 'news_feed':
          await AdMobService.instance.preloadNewsFeedAd(
            isDarkTheme: widget.isDarkTheme,
          );
          break;
      }
      
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to preload ad (${widget.adType}): $e');
      _hasPreloaded = false; // Allow retry
    }
  }
  
  NativeAd? getCachedAd() {
    if (!_isAdLoaded) return null;
    
    try {
      switch (widget.adType) {
        case 'home_results':
          _nativeAd = AdMobService.instance.getCachedHomeResultsAd();
          break;
        case 'live_video':
          _nativeAd = AdMobService.instance.getCachedLiveVideoAd();
          break;
        case 'lotto_points':
          _nativeAd = AdMobService.instance.getCachedLottoPointsAd();
          break;
        case 'news_feed':
          _nativeAd = AdMobService.instance.getCachedNewsFeedAd();
          break;
      }
      
      if (_nativeAd != null) {
        setState(() {
          _isAdLoaded = false; // Mark as consumed
        });
        _hasPreloaded = false; // Allow new preload
        
        // Preload next ad in background
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _preloadAdSafely();
        });
      }
      
      return _nativeAd;
    } catch (e) {
      debugPrint('Failed to get cached ad (${widget.adType}): $e');
      return null;
    }
  }
  
  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Convenient wrapper for native ad widgets
class NativeAdLifecycleWidget extends StatefulWidget {
  final String adType;
  final double height;
  final bool isDarkTheme;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  
  const NativeAdLifecycleWidget({
    super.key,
    required this.adType,
    this.height = 120,
    this.isDarkTheme = false,
    this.padding,
    this.borderRadius,
  });

  @override
  State<NativeAdLifecycleWidget> createState() => _NativeAdLifecycleWidgetState();
}

class _NativeAdLifecycleWidgetState extends State<NativeAdLifecycleWidget> {
  final GlobalKey<_AdLifecycleWidgetState> _adKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return AdLifecycleWidget(
      key: _adKey,
      adType: widget.adType,
      isDarkTheme: widget.isDarkTheme,
      child: Builder(
        builder: (context) {
          final ad = _adKey.currentState?.getCachedAd();
          
          if (ad == null) {
            // Return placeholder while ad loads
            return Container(
              height: widget.height,
              margin: widget.padding,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.3),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            );
          }
          
          return Container(
            height: widget.height,
            margin: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: AdWidget(ad: ad),
          );
        },
      ),
    );
  }
}