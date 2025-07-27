import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class NativePointAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  
  const NativePointAdWidget({
    super.key,
    this.height,
    this.margin,
    this.borderRadius,
  });

  @override
  State<NativePointAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativePointAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isDarkTheme = false;
  bool _isLoadingFromCache = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nativeAd == null) {
      _tryLoadCachedAd();
    }
  }

  void _tryLoadCachedAd() {
    if (!mounted) return;
    
    // Cancel any existing retry timer
    _retryTimer?.cancel();
    
    _isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // Try to get cached ad first (instant loading)
    final cachedAd = AdMobService.instance.getCachedLottoPointsAd();
    if (cachedAd != null) {
      if (mounted) {
        // Dispose existing ad before setting new one
        _nativeAd?.dispose();
        setState(() {
          _nativeAd = cachedAd;
          _isAdLoaded = true;
          _isLoadingFromCache = true;
        });
      }
      return;
    }
    
    // Fallback to loading new ad if no cache available
    _loadNativeAdDirect();
  }
  
  void _loadNativeAdDirect() {
    if (!mounted) return;
    
    // Dispose existing ad before creating new one
    _nativeAd?.dispose();
    
    // Use news-style ad format for better performance
    _nativeAd = AdMobService.instance.createNewsStyleNativeLottoPointsAd(
      isDarkTheme: _isDarkTheme,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isLoadingFromCache = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            // Nullify ad reference on failure
            _nativeAd = null;
            setState(() {
              _isAdLoaded = false;
              _isLoadingFromCache = false;
            });
            // Setup retry timer
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 30), () {
              if (mounted) {
                _tryLoadCachedAd();
              }
            });
          }
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
        onAdWillDismissScreen: (ad) {},
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    // Cancel retry timer to prevent memory leaks
    _retryTimer?.cancel();
    _retryTimer = null;
    
    // Dispose and nullify ad reference
    _nativeAd?.dispose();
    _nativeAd = null;
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: widget.height ?? AppResponsive.height(context, 25),
      margin: widget.margin ?? AppResponsive.margin(context, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(AppResponsive.spacing(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isAdLoaded && _nativeAd != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: widget.borderRadius ?? 
                      BorderRadius.circular(AppResponsive.spacing(context, 12)),
                  child: AdWidget(ad: _nativeAd!),
                ),
                // CRITICAL: Ad Label for AdMob Compliance
                Positioned(
                  top: 4,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _buildAdPlaceholder(theme),
    );
  }

  Widget _buildAdPlaceholder(ThemeData theme) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppResponsive.width(context, 20),
            height: AppResponsive.width(context, 20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
            ),
            child: Icon(
              Icons.ads_click,
              color: theme.primaryColor,
              size: AppResponsive.fontSize(context, 24),
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 8)),
          Text(
            _isLoadingFromCache ? 'loading_cached_ad'.tr() : 'sponsored_content'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: AppResponsive.fontSize(context, 12),
              color: (theme.textTheme.bodySmall?.color ?? theme.textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.6),
            ),
          ),
          if (!_isAdLoaded) ...[
            SizedBox(height: AppResponsive.spacing(context, 4)),
            SizedBox(
              width: AppResponsive.width(context, 5),
              height: AppResponsive.width(context, 5),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}