import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class NativeAdHomeWidget extends StatefulWidget {
  const NativeAdHomeWidget({super.key});

  @override
  State<NativeAdHomeWidget> createState() {
    return _NativeAdHomeWidgetState();
  }
}

class _NativeAdHomeWidgetState extends State<NativeAdHomeWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isDarkTheme = false;
  bool _isLoadingFromCache = false;

  _NativeAdHomeWidgetState();

  @override
  void initState() {
    super.initState();
    // Don't access Theme.of(context) in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadCachedAd();
    });
  }

  void _tryLoadCachedAd() {
    if (!mounted) return;
    
    _isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // Try to get cached ad first (instant loading)
    final cachedAd = AdMobService.instance.getCachedHomeResultsAd();
    if (cachedAd != null) {
      if (mounted) {
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
    
    _nativeAd = AdMobService.instance.createNewsStyleNativeHomeResultsAd(
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
            setState(() {
              _isAdLoaded = false;
              _isLoadingFromCache = false;
            });
            // Retry after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
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
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isAdLoaded || _nativeAd == null) {
      return Card(
        color: theme.cardTheme.color,
        margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
        elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 12)),
          side: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
          ),
        ),
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.ads_click,
                size: AppResponsive.fontSize(context, 32),
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                _isLoadingFromCache ? 'loading_cached_ad'.tr() : 'sponsored_content'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.spacing(context, 4)),
              if (!_isAdLoaded)
                SizedBox(
                  width: AppResponsive.width(context, 4),
                  height: AppResponsive.width(context, 4),
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Ad Card (exact match with lottery result card design)
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            side: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
            ),
          ),
          child: Padding(
            padding:
                AppResponsive.padding(context, horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with accent line (matching lottery card style)
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: AppResponsive.spacing(context, 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 10)),
                    Expanded(
                      child: Text(
                        'sponsored_content'.tr(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.spacing(context, 10)),

                // Native Ad Content Area (clean and minimal)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: AppResponsive.spacing(context, 120),
                    maxHeight: AppResponsive.spacing(context, 320),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 8)),
                    child: AdWidget(ad: _nativeAd!),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Simple "AD" badge (matching lottery result badges)
        Positioned(
          top: 13,
          right: AppResponsive.spacing(context, 16),
          child: Container(
            padding:
                AppResponsive.padding(context, horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppResponsive.spacing(context, 8)),
                bottomRight: Radius.circular(AppResponsive.spacing(context, 8)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppResponsive.fontSize(context, 10),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
