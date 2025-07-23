import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class NativeAdNewsWidget extends StatefulWidget {
  const NativeAdNewsWidget({super.key});

  @override
  State<NativeAdNewsWidget> createState() => _NativeAdNewsWidgetState();
}

class _NativeAdNewsWidgetState extends State<NativeAdNewsWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = AdMobService.instance.createNewsStyleNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
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
      return _buildLoadingState(theme);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Native Ad with template
        AdWidget(ad: _nativeAd!),

        // AD Badge overlay
        Positioned(
          top: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ads_click,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'AD',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[800]!.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
                Colors.black,
              ],
            ),
          ),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
