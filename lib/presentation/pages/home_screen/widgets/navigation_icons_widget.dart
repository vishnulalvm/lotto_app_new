import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Cached values for performance
  ThemeData? _cachedTheme;
  late bool _isDark;
  late Color _lightBackground;
  late Color _darkBackground;
  late Color _lightRedGradientStart;
  late Color _lightRedGradientEnd;
  late Color _darkRedGradientStart;
  late Color _darkRedGradientEnd;
  late Color _primaryRed;
  late Color _vibrantRed;
  
  // Cached responsive values
  late double _iconSize;
  late double _containerSize;
  late double _smallIconSize;
  late double _textWidth;
  late double _spacing;
  late EdgeInsets _padding;
  late double _blurRadius;
  late Offset _shadowOffset;
  
  // Cached navigation items
  late List<Map<String, dynamic>> _navItems;
  
  // Manual flip control
  bool _isManualFlipInProgress = false;

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

    // Initialize navigation items once
    _initializeNavItems();
    
    // Start periodic flip animation with Timer instead of recursive async
    _startOptimizedPeriodicFlipAnimation();
  }
  
  void _initializeNavItems() {
    _navItems = [
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
  }
  
  void _cacheThemeValues(ThemeData theme) {
    if (_cachedTheme == theme) return; // Skip if theme hasn't changed
    
    _cachedTheme = theme;
    _isDark = theme.brightness == Brightness.dark;
    
    // Cache theme colors
    _lightBackground = const Color(0xFFFFE4E6);
    _darkBackground = const Color(0xFF2D1518);
    _lightRedGradientStart = const Color(0xFFFF5252);
    _lightRedGradientEnd = const Color(0xFFB71C1C);
    _darkRedGradientStart = const Color(0xFFFF8A80);
    _darkRedGradientEnd = const Color(0xFFD32F2F);
    _primaryRed = theme.primaryColor;
    _vibrantRed = const Color(0xFFFF5252);
  }
  
  void _cacheResponsiveValues(BuildContext context) {
    _iconSize = AppResponsive.fontSize(context, 24);
    _containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );
    _smallIconSize = _iconSize * 0.6;
    _textWidth = AppResponsive.width(context, 15);
    _spacing = AppResponsive.spacing(context, 8);
    _padding = AppResponsive.padding(context, horizontal: 16, vertical: 16);
    _blurRadius = AppResponsive.spacing(context, 8);
    _shadowOffset = Offset(0, AppResponsive.spacing(context, 2));
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    super.dispose();
  }

  /// Optimized periodic flip animation using Timer
  void _startOptimizedPeriodicFlipAnimation() {
    // Use Timer instead of recursive async calls for better performance
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _performFlipCycle();
      }
    });
  }

  /// Single flip cycle without recursion
  void _performFlipCycle() async {
    if (!mounted || _isManualFlipInProgress) return;

    // Flip to "Get Points" side
    await _flipAnimationController.forward();
    
    if (!mounted || _isManualFlipInProgress) return;
    
    // Wait 2 seconds on "Get Points" side
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted || _isManualFlipInProgress) return;

    // Flip back to scanner side
    await _flipAnimationController.reverse();
    
    if (!mounted) return;

    // Schedule next flip cycle (8 seconds later)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_isManualFlipInProgress) {
        _performFlipCycle();
      }
    });
  }
  
  /// Manual flip back to scanner side
  Future<void> _flipToScanner() async {
    if (_flipAnimationController.value > 0.5) {
      _isManualFlipInProgress = true;
      HapticFeedback.lightImpact();
      await _flipAnimationController.reverse();
      _isManualFlipInProgress = false;
      
      // Restart automatic flip cycle after manual intervention
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && !_isManualFlipInProgress) {
          _performFlipCycle();
        }
      });
    }
  }
  
  /// Handle swipe gestures on the flip navigation item
  void _handleSwipe(DragEndDetails details) {
    const double minVelocity = 300.0;
    
    // Check if swipe is horizontal and has sufficient velocity
    if (details.velocity.pixelsPerSecond.dx.abs() > minVelocity) {
      // Any horizontal swipe flips back to scanner
      _flipToScanner();
    }
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
          // Special handling for scanner button with flip animation
          if (item['route'] == '/barcode_scanner_screen') {
            return _buildOptimizedFlipNavItem(context, item, theme);
          }
          return _buildOptimizedNavItem(context, item, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildOptimizedFlipNavItem(
      BuildContext context, Map<String, dynamic> item, ThemeData theme) {
    // Build the front and back widgets just ONCE. They are expensive.
    final Widget frontSide = _buildNavItemContent(
      context: context,
      theme: theme,
      icon: item['icon'],
      label: item['label'],
      isFront: true,
    );

    final Widget backSide = _buildNavItemContentWithImage(
      context: context,
      theme: theme,
      imagePath: 'assets/icons/money_bag.png',
      label: 'Cashbacks',
      isFront: false,
    );

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isShowingFront = _flipAnimation.value < 0.5;
        final flipValue = _flipAnimation.value * math.pi;

        // The builder's only job is to apply the transform, which is cheap.
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(flipValue);

        return GestureDetector(
          onTap: () => _handleFlipNavTap(isShowingFront, item),
          onPanEnd: _handleSwipe,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            // We show either the pre-built front or back side.
            child: isShowingFront ? frontSide : backSide,
          ),
        );
      },
    );
  }

  // Helper method to build the content of each side
  Widget _buildNavItemContent({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool isFront,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _containerSize,
          height: _containerSize,
          decoration: BoxDecoration(
            gradient: isFront
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _isDark ? _darkRedGradientStart : _lightRedGradientStart,
                      _isDark ? _darkRedGradientEnd : _lightRedGradientEnd,
                    ],
                    stops: const [0.0, 1.0],
                  ),
            color: isFront
                ? (_isDark ? _darkBackground : _lightBackground)
                : null,
            shape: BoxShape.circle,
          ),
          child: isFront
              ? Icon(
                  icon,
                  color: theme.iconTheme.color,
                  size: _iconSize,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: Container(
                    width: _smallIconSize,
                    height: _smallIconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          _isDark ? _darkRedGradientStart : _lightRedGradientStart,
                          _isDark ? _darkRedGradientEnd : _lightRedGradientEnd,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: _iconSize * 0.8,
                      ),
                    ),
                  ),
                ),
        ),
        SizedBox(height: _spacing),
        SizedBox(
          width: _textWidth,
          child: isFront
              ? Text(
                  label,
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
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                      color: _isDark ? _vibrantRed : _primaryRed,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNavItemContentWithImage({
    required BuildContext context,
    required ThemeData theme,
    required String imagePath,
    required String label,
    required bool isFront,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _containerSize,
          height: _containerSize,
          decoration: BoxDecoration(
            gradient: isFront
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _isDark ? _darkRedGradientStart : _lightRedGradientStart,
                      _isDark ? _darkRedGradientEnd : _lightRedGradientEnd,
                    ],
                    stops: const [0.0, 1.0],
                  ),
            color: isFront
                ? (_isDark ? _darkBackground : _lightBackground)
                : null,
            shape: BoxShape.circle,
          ),
          child: isFront
              ? Image.asset(
                  imagePath,
                  width: _iconSize,
                  height: _iconSize,
                  fit: BoxFit.contain,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: Container(
                    width: _smallIconSize,
                    height: _smallIconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          _isDark ? _darkRedGradientStart : _lightRedGradientStart,
                          _isDark ? _darkRedGradientEnd : _lightRedGradientEnd,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        width: _iconSize * 0.8,
                        height: _iconSize * 0.8,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
        SizedBox(height: _spacing),
        SizedBox(
          width: _textWidth,
          child: isFront
              ? Text(
                  label,
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
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                      color: _isDark ? _vibrantRed : _primaryRed,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
  
  // Helper method to handle flip navigation taps
  void _handleFlipNavTap(bool isShowingFront, Map<String, dynamic> item) {
    HapticFeedback.lightImpact(); // Add haptic feedback
    
    // Always navigate to barcode scanner screen regardless of flip side
    if (item['route'] != null) {
      AnalyticsService.trackUserEngagement(
        action: 'navigation_tap',
        category: 'navigation',
        label: isShowingFront ? item['label'] : 'scanner_from_points',
        parameters: {
          'destination': item['route'],
          'feature': isShowingFront ? item['label'] : 'scanner_from_points',
          'flip_side': isShowingFront ? 'front' : 'back',
        },
      );
      context.go(item['route']);
    }
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
            child: Icon(
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
                fontWeight: FontWeight.w500,
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
