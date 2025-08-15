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
  AdState _adState = AdState.idle;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAd();
      }
    });
  }

  void _initializeAd() {
    if (!mounted) return;
    
    _isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // Try to get existing loaded ad first
    final existingAd = AdMobService.instance.getHomeResultsAd();
    if (existingAd != null) {
      setState(() {
        _nativeAd = existingAd;
        _adState = AdState.loaded;
      });
      return;
    }
    
    // Load new ad if none available
    _loadNewAd();
  }

  Future<void> _loadNewAd() async {
    if (!mounted) return;
    
    setState(() {
      _adState = AdState.loading;
    });
    
    try {
      await AdMobService.instance.loadHomeResultsAd(isDarkTheme: _isDarkTheme);
      
      if (mounted) {
        final newAd = AdMobService.instance.getHomeResultsAd();
        if (newAd != null) {
          setState(() {
            _nativeAd = newAd;
            _adState = AdState.loaded;
          });
        } else {
          setState(() {
            _adState = AdState.failed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adState = AdState.failed;
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose the ad here as it's managed by the service
    super.dispose();
  }
  
  Widget _buildAdContent(ThemeData theme) {
    if (_nativeAd == null || _adState != AdState.loaded) {
      return Container(
        height: 120,
        color: theme.cardColor,
        child: Center(
          child: _adState == AdState.loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : Text(
                  'ad_unavailable'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
        ),
      );
    }
    
    try {
      // Verify ad is still valid by accessing a property
      final _ = _nativeAd!.adUnitId;
      return AdWidget(ad: _nativeAd!);
    } catch (e) {
      // Ad has been disposed, show fallback and try to reload
      debugPrint('Ad widget error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadNewAd();
        }
      });
      return Container(
        height: 120,
        color: theme.cardColor,
        child: Center(
          child: Text(
            'ad_unavailable'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading state if ad is not ready
    if (_adState == AdState.loading) {
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
                'sponsored_content'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.spacing(context, 4)),
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

    // Show fallback if failed or no ad
    if (_adState == AdState.failed || _nativeAd == null) {
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
                Icons.info_outline,
                size: AppResponsive.fontSize(context, 24),
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                'ad_unavailable'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 12),
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
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
                    child: _buildAdContent(theme),
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