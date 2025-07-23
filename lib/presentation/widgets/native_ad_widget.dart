import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class NativeAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  
  const NativeAdWidget({
    super.key,
    this.height,
    this.margin,
    this.borderRadius,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nativeAd == null) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    final theme = Theme.of(context);
    
    _nativeAd = AdMobService.instance.createNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
        onAdClicked: (ad) {
          // Handle ad click
        },
      ),
      templateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        cornerRadius: widget.borderRadius?.topLeft.x ?? 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: theme.primaryColor,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.textTheme.titleMedium?.color ?? Colors.black87,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.textTheme.bodyMedium?.color ?? Colors.black54,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: theme.textTheme.bodySmall?.color ?? Colors.black45,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
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
          ? ClipRRect(
              borderRadius: widget.borderRadius ?? 
                  BorderRadius.circular(AppResponsive.spacing(context, 12)),
              child: AdWidget(ad: _nativeAd!),
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
            'Advertisement',
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