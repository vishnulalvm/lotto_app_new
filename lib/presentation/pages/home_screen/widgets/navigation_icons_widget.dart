import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/core/helpers/feedback_helper.dart';

/// Navigation icons widget - converted to StatelessWidget for better performance
/// Flutter's const constructor and element caching handles "caching" better than manual state management
class NavigationIconsWidget extends StatelessWidget {
  const NavigationIconsWidget({super.key});

  // Static navigation items - defined once
  static const List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.qr_code_scanner,
      'label': 'Scanner',
      'route': '/barcode_scanner_screen'
    },
    {'icon': Icons.live_tv, 'label': 'Videos', 'route': '/live_videos'},
    {'icon': Icons.games_outlined, 'label': 'Guessing', 'route': '/predict'},
    {
      'icon': Icons.bar_chart_outlined,
      'label': 'Statistic',
      'route': '/challenge_screen'
    },
    {
      'icon': Icons.casino_outlined,
      'label': 'Draw',
      'route': '/lottery_draw'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lightBackground = theme.primaryColor.withValues(alpha: 0.1);
    final darkBackground = theme.primaryColor.withValues(alpha: 0.2);

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
        children: _navItems.map((item) {
          return _buildNavItem(
            context,
            item,
            theme,
            isDark,
            lightBackground,
            darkBackground,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
    bool isDark,
    Color lightBackground,
    Color darkBackground,
  ) {
    final iconSize = AppResponsive.fontSize(context, 24);
    final imageSize = AppResponsive.fontSize(context, 24);
    final containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );
    final textWidth = AppResponsive.width(context, 15);
    final spacing = AppResponsive.spacing(context, 8);

    return InkWell(
      onTap: () => _handleNavTap(context, item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: isDark ? darkBackground : lightBackground,
              shape: BoxShape.circle,
            ),
            child: item['image'] != null
                ? Image.asset(
                    item['image'],
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    item['icon'],
                    color: theme.iconTheme.color,
                    size: iconSize,
                  ),
          ),
          SizedBox(height: spacing),
          SizedBox(
            width: textWidth,
            child: Text(
              item['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 12),
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to handle navigation taps
  void _handleNavTap(BuildContext context, Map<String, dynamic> item) {
    FeedbackHelper.lightClick(); // Add haptic and sound feedback

    if (item['route'] != null) {
      AnalyticsService.trackUserEngagement(
        action: 'navigation_tap',
        category: 'navigation',
        label: item['label'],
        parameters: {
          'destination': item['route'],
          'feature': item['label'],
        },
      );
      context.go(item['route']);
    }
  }
}
