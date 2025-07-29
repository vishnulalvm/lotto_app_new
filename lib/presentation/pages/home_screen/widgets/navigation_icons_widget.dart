import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/analytics_service.dart';

class NavigationIconsWidget extends StatelessWidget {
  const NavigationIconsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'scanner'.tr(),
        'route': '/barcode_scanner_screen'
      },
      {'icon': Icons.live_tv, 'label': 'Live'.tr(), 'route': '/live_videos'},
      {
        'icon': Icons.games_outlined,
        'label': 'predict'.tr(),
        'route': '/Predict'
      },
      {'icon': Icons.newspaper, 'label': 'news'.tr(), 'route': '/news_screen'},
      {
        'icon': Icons.bookmark,
        'label': 'saved'.tr(),
        'route': '/saved-results'
      },
    ];

    return Container(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppResponsive.spacing(context, 8),
            offset: Offset(0, AppResponsive.spacing(context, 2)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: navItems.map((item) => _buildNavItem(context, item, theme)).toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    final double iconSize = AppResponsive.fontSize(context, 24);
    final double containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );

    return InkWell(
      onTap: () {
        if (item['route'] != null) {
          // Track navigation analytics
          AnalyticsService.trackUserEngagement(
            action: 'navigation_tap',
            category: 'navigation',
            label: item['label'],
            parameters: {
              'destination': item['route'],
              'feature': item['label'],
            },
          );

          // Direct navigation without ads
          context.go(item['route']);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFF2D1518), // Dark red tint for dark theme
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'],
              color: theme.iconTheme.color,
              size: iconSize,
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 8)),
          SizedBox(
            width: AppResponsive.width(context, 15),
            child: Text(
              item['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 12),
                fontWeight: FontWeight.w500,
                color:
                    theme.textTheme.bodyMedium?.color, // Use theme text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}