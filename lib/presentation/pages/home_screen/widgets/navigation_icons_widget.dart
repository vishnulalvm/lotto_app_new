import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/analytics_service.dart';

class NavigationIconsWidget extends StatefulWidget {
  const NavigationIconsWidget({super.key});

  @override
  State<NavigationIconsWidget> createState() => _NavigationIconsWidgetState();
}

class _NavigationIconsWidgetState extends State<NavigationIconsWidget> {

  // Cached values for performance
  ThemeData? _cachedTheme;
  late bool _isDark;
  late Color _lightBackground;
  late Color _darkBackground;

  // Cached responsive values
  late double _iconSize;
  late double _imageSize;
  late double _containerSize;
  late double _textWidth;
  late double _spacing;
  late EdgeInsets _padding;
  late double _blurRadius;
  late Offset _shadowOffset;

  // Cached navigation items
  late List<Map<String, dynamic>> _navItems;


  @override
  void initState() {
    super.initState();

    // Initialize navigation items once
    _initializeNavItems();
  }

  void _initializeNavItems() {
    _navItems = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scanner',
        'route': '/barcode_scanner_screen'
      },
      {'icon': Icons.live_tv, 'label': 'Live', 'route': '/live_videos'},
      {
        'icon': Icons.games_outlined,
        'label': 'Predict',
        'route': '/predict'
      },
      {'icon': Icons.newspaper, 'label': 'News', 'route': '/news_screen'},
      {
        'image': 'assets/icons/lotto_points.png',
        'label': 'Points',
        'route': '/lottoPoints'
      },
    ];
  }

  void _cacheThemeValues(ThemeData theme) {
    if (_cachedTheme == theme) return; // Skip if theme hasn't changed

    _cachedTheme = theme;
    _isDark = theme.brightness == Brightness.dark;

    // Cache theme colors
    _lightBackground = const Color(0xFFFFE4E6);
    _darkBackground = const Color(0xFF2D1518);
  }


  void _cacheResponsiveValues(BuildContext context) {
    _iconSize = AppResponsive.fontSize(context, 24);
    _imageSize = AppResponsive.fontSize(context, 24); // Smaller size for images
    _containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );
    _textWidth = AppResponsive.width(context, 15);
    _spacing = AppResponsive.spacing(context, 8);
    _padding = AppResponsive.padding(context, horizontal: 16, vertical: 16);
    _blurRadius = AppResponsive.spacing(context, 8);
    _shadowOffset = Offset(0, AppResponsive.spacing(context, 2));
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cache theme and responsive values
    _cacheThemeValues(theme);
    _cacheResponsiveValues(context);

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: _blurRadius,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _navItems.map((item) {
          // Special handling for points button
          if (item['label'] == 'Points') {
            return _buildPointsButton(context, item, theme);
          }
          return _buildOptimizedNavItem(context, item, theme);
        }).toList(),
      ),
    );
  }





  Widget _buildOptimizedNavItem(
      BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    return InkWell(
      onTap: () => _handleRegularNavTap(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _containerSize,
            height: _containerSize,
            decoration: BoxDecoration(
              color: _isDark ? _darkBackground : _lightBackground,
              shape: BoxShape.circle,
            ),
            child: item['image'] != null
                ? Image.asset(
                    item['image'],
                    width: _imageSize,
                    height: _imageSize,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    item['icon'],
                    color: theme.iconTheme.color,
                    size: _iconSize,
                  ),
          ),
          SizedBox(height: _spacing),
          SizedBox(
            width: _textWidth,
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

  // Dedicated method for the Points button
  Widget _buildPointsButton(
      BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    return InkWell(
      onTap: () => _handleRegularNavTap(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _containerSize,
            height: _containerSize,
            decoration: BoxDecoration(
              color: _isDark
                  ? _darkBackground
                  : _lightBackground, // Use same background as other buttons
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/lotto_points.png',
                width: _imageSize,
                height: _imageSize,
                color: theme
                    .iconTheme.color, // Use theme icon color for both modes
              ),
            ),
          ),
          SizedBox(height: _spacing),
          SizedBox(
            width: _textWidth,
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

  // Helper method to handle regular navigation taps
  void _handleRegularNavTap(Map<String, dynamic> item) {
    HapticFeedback.lightImpact(); // Add haptic feedback

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
