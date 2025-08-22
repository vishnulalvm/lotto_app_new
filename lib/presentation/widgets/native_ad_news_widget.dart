import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
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

  void _loadNativeAd() async {
    // Use the modern AdMobService API to load news feed native ads
    try {
      await AdMobService.instance.loadAd('news_feed', isDarkTheme: true);
      
      // Get the loaded ad from the service
      _nativeAd = AdMobService.instance.getAd<NativeAd>('news_feed');
      
      if (_nativeAd != null) {
        setState(() {
          _isAdLoaded = true;
        });
      } else {
        setState(() {
          _isAdLoaded = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAdLoaded = false;
      });
    }
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

    return _buildAdContent(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background similar to news loading
        Container(
          color: Colors.grey[900],
          child: Icon(
            Icons.image_not_supported,
            size: 100,
            color: Colors.white30,
          ),
        ),

        // Gradient overlay (matching news pattern)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
                Colors.black,
              ],
            ),
          ),
        ),

        // Loading indicator positioned like news content
        Positioned(
          left: 16,
          right: 16,
          bottom: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton for headline
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),

              // Skeleton for time/source
              Row(
                children: [
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading indicator
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdContent(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Native Ad background - positioned below app bar
        Positioned(
          top: 200, // Move down below app bar
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: AdWidget(ad: _nativeAd!),
          ),
        ),

        // Content positioned at bottom (matching news layout)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Sponsored headline (matching news title style)
                Text(
                  'Sponsored Headline',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Source and time (matching news pattern)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      'sponsored'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      'promoted'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Content description (matching news content style)
                Text(
                  'This is a sponsored content description that mimics the style of news articles. It provides a brief overview of the ad content, enticing users to learn more about the product or service being advertised. The text is concise and engaging, similar to how news articles summarize key points.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Subtle AD indicator (matching news "read more" style)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ads_click,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'sponsored_content'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Learn more button (matching news website button style)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'learn_more'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
