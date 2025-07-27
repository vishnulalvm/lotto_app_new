import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/admob_service.dart';

class NativeAdVideoWidget extends StatefulWidget {
  const NativeAdVideoWidget({super.key});

  @override
  State<NativeAdVideoWidget> createState() => _NativeAdVideoWidgetState();
}

class _NativeAdVideoWidgetState extends State<NativeAdVideoWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = AdMobService.instance.createNewsStyleNativeLiveVideoAd(
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
      return _buildLoadingCard(theme);
    }

    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
      elevation: theme.brightness == Brightness.dark ? 3.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.08),
          width: theme.brightness == Brightness.dark ? 0.8 : 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Native Ad thumbnail section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppResponsive.spacing(context, 8)),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 14,
                  child: AdWidget(ad: _nativeAd!),
                ),
              ),
              
              // AD Badge (top-left)
              Positioned(
                top: AppResponsive.spacing(context, 12),
                left: AppResponsive.spacing(context, 12),
                child: Container(
                  padding: AppResponsive.padding(context,
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ads_click,
                        size: AppResponsive.fontSize(context, 10),
                        color: Colors.white,
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 4)),
                      Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppResponsive.fontSize(context, 9),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sponsored badge (top-right)
              Positioned(
                top: AppResponsive.spacing(context, 12),
                right: AppResponsive.spacing(context, 12),
                child: Container(
                  padding: AppResponsive.padding(context,
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 4)),
                      Text(
                        'sponsored'.tr().toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppResponsive.fontSize(context, 9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Ad details section (matching video card design)
          Padding(
            padding: AppResponsive.padding(context, horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with accent line (matching video card style)
                // Row(
                //   children: [
                //     Container(
                //       width: 3,
                //       height: AppResponsive.spacing(context, 45),
                //       decoration: BoxDecoration(
                //         color: theme.colorScheme.primary,
                //         borderRadius: BorderRadius.circular(2),
                //       ),
                //     ),
                //     SizedBox(width: AppResponsive.spacing(context, 12)),
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             'sponsored_content'.tr(),
                //             style: TextStyle(
                //               fontSize: AppResponsive.fontSize(context, 17),
                //               fontWeight: FontWeight.w600,
                //               letterSpacing: 0.1,
                //               color: theme.textTheme.titleLarge?.color,
                //               height: 1.3,
                //             ),
                //             maxLines: 2,
                //             overflow: TextOverflow.ellipsis,
                //           ),
                //           SizedBox(height: AppResponsive.spacing(context, 6)),
                //           // Highlighted date
                //           Container(
                //             padding: AppResponsive.padding(context,
                //                 horizontal: 8, vertical: 3),
                //             decoration: BoxDecoration(
                //               color: theme.colorScheme.primary
                //                   .withValues(alpha: 0.1),
                //               borderRadius: BorderRadius.circular(
                //                   AppResponsive.spacing(context, 6)),
                //             ),
                //             child: Text(
                //               'promoted'.tr(),
                //               style: TextStyle(
                //                 fontSize: AppResponsive.fontSize(context, 11),
                //                 fontWeight: FontWeight.w600,
                //                 color: theme.colorScheme.primary,
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                // Description
                SizedBox(height: AppResponsive.spacing(context, 10)),
                Text(
                  'discover_amazing_products'.tr(),
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 12),
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Bottom section with status and action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    Container(
                      padding: AppResponsive.padding(context,
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppResponsive.spacing(context, 8)),
                      ),
                      child: Text(
                        'sponsored'.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 10),
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    // Learn more button (matching YouTube button style)
                    ElevatedButton.icon(
                      onPressed: () {
                        // The native ad will handle the click automatically
                      },
                      icon: Icon(
                        Icons.touch_app,
                        size: AppResponsive.fontSize(context, 14),
                      ),
                      label: Text(
                        'learn_more'.tr(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.orange[50]
                            : Colors.orange[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.orange[700]
                            : Colors.orange[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 8)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.orange[700]!.withValues(alpha: 0.3)
                                : Colors.orange[200]!.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
      elevation: theme.brightness == Brightness.dark ? 3.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading thumbnail
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppResponsive.spacing(context, 8)),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          // Loading content
          Padding(
            padding: AppResponsive.padding(context, horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}