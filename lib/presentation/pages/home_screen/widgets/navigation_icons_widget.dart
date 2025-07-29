import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'dart:math' as math;

class NavigationIconsWidget extends StatefulWidget {
  const NavigationIconsWidget({super.key});

  @override
  State<NavigationIconsWidget> createState() => _NavigationIconsWidgetState();
}

class _NavigationIconsWidgetState extends State<NavigationIconsWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize flip animation controller
    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start periodic flip animation
    _startPeriodicFlipAnimation();
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    super.dispose();
  }

  /// Start periodic flip animation for scanner button
  void _startPeriodicFlipAnimation() async {
    // Wait 3 seconds before first flip
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _periodicFlip();
    }
  }

  /// Periodic flip animation
  void _periodicFlip() async {
    if (!mounted) return;

    // Flip to "Get Points" side
    await _flipAnimationController.forward();

    // Wait 2 seconds on "Get Points" side
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Flip back to scanner side
    await _flipAnimationController.reverse();

    // Wait 8 seconds before next flip
    await Future.delayed(const Duration(seconds: 8));

    if (mounted) {
      _periodicFlip(); // Repeat
    }
  }

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
        children: navItems.map((item) {
          // Special handling for scanner button with flip animation
          if (item['route'] == '/barcode_scanner_screen') {
            return _buildFlipNavItem(context, item, theme);
          }
          return _buildNavItem(context, item, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildFlipNavItem(
      BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    final double iconSize = AppResponsive.fontSize(context, 24);
    final double containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isShowingFront = _flipAnimation.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_flipAnimation.value * math.pi),
          child: InkWell(
            onTap: () {
              if (isShowingFront) {
                // Scanner side - navigate to scanner
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
              } else {
                // Get Points side - navigate to lotto points
                AnalyticsService.trackUserEngagement(
                  action: 'navigation_tap',
                  category: 'navigation',
                  label: 'get_points',
                  parameters: {
                    'destination': '/lottoPoints',
                    'feature': 'get_points',
                  },
                );
                context.go('/lottoPoints');
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
                    // Eye-catching premium red gradient for flip side
                    gradient: isShowingFront
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.brightness == Brightness.dark
                                  ? const Color(
                                      0xFFFF8A80) // Light red for dark theme
                                  : const Color(
                                      0xFFFF5252), // Light red for light theme
                              theme.brightness == Brightness.dark
                                  ? const Color(
                                      0xFFD32F2F) // Deep red for dark theme
                                  : const Color(
                                      0xFFB71C1C), // Deep red for light theme
                            ],
                            stops: const [0.0, 1.0],
                          ),
                    color: isShowingFront
                        ? (theme.brightness == Brightness.light
                            ? const Color(0xFFFFE4E6) // Light pink/rose tint
                            : const Color(0xFF2D1518)) // Dark red tint
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: isShowingFront
                      ? Icon(
                          item['icon'],
                          color: theme.iconTheme.color,
                          size: iconSize,
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: Container(
                            width: iconSize *
                                0.6, // Smaller size (60% of original)
                            height: iconSize * 0.6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.8,
                                colors: [
                                  theme.brightness == Brightness.dark
                                      ? const Color(
                                          0xFFFF8A80) // Light red for dark theme
                                      : const Color(
                                          0xFFFF5252), // Light red for light theme
                                  theme.brightness == Brightness.dark
                                      ? const Color(
                                          0xFFD32F2F) // Deep red for dark theme
                                      : const Color(
                                          0xFFB71C1C), // Deep red for light theme
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/lotto_points.png',
                                width: iconSize *
                                    0.8, // Even smaller for the actual image
                                height: iconSize * 0.8,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 8)),
                SizedBox(
                  width: AppResponsive.width(context, 15),
                  child: isShowingFront
                      ? Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 12),
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: Text(
                            'get_points'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 11),
                              fontWeight: FontWeight.w600,
                              // Use theme's primary color (red) for the flip side text
                              color: theme.brightness == Brightness.light
                                  ? theme
                                      .primaryColor // Standard red for light theme
                                  : const Color(
                                      0xFFFF5252), // Vibrant red for dark theme
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      BuildContext context, Map<String, dynamic> item, ThemeData theme) {
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
