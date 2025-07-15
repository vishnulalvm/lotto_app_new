import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:glowy_borders/glowy_borders.dart';

class AIProbabilityFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Animation<double> sizeAnimation;
  final ThemeData theme;

  const AIProbabilityFAB({
    super.key,
    required this.onPressed,
    required this.sizeAnimation,
    required this.theme,
  });

  @override
  State<AIProbabilityFAB> createState() => _AIProbabilityFABState();
}

class _AIProbabilityFABState extends State<AIProbabilityFAB>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _gradientController;
  late Animation<double> _glowAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for the glow effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Animation controller for gradient rotation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  // Cache gradient colors to avoid recalculation
  List<Color>? _cachedGradientColors;
  double _lastGradientProgress = -1;
  
  // Dynamic red gradient colors that shift based on animation
  List<Color> _getAnimatedGradientColors() {
    final progress = _gradientAnimation.value;
    
    // Return cached colors if progress hasn't changed significantly
    if (_cachedGradientColors != null && 
        (_lastGradientProgress - progress).abs() < 0.01) {
      return _cachedGradientColors!;
    }
    
    final isDark = widget.theme.brightness == Brightness.dark;
    
    // Use your theme's red colors for gradient
    final primaryRed = isDark ? const Color(0xFFFF5252) : Colors.red;
    final lightRed = isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF5252);
    final deepRed = isDark ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);
    
    // Create a smooth looping red gradient effect
    _cachedGradientColors = [
      Color.lerp(primaryRed, lightRed, progress)!,
      Color.lerp(lightRed, deepRed, progress)!,
      Color.lerp(deepRed, primaryRed, (progress + 0.5) % 1.0)!,
      Color.lerp(primaryRed, lightRed, (progress + 0.5) % 1.0)!,
    ];
    
    _lastGradientProgress = progress;
    return _cachedGradientColors!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sizeAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _gradientAnimation]),
          builder: (context, child) {
            // Cache theme colors to avoid repeated lookups
            final isDark = widget.theme.brightness == Brightness.dark;
            final primaryRed = isDark ? const Color(0xFFFF5252) : Colors.red;
            final lightRed = isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF5252);
            
            return AnimatedGradientBorder(
              borderSize: 4,
              glowSize: 2,
              gradientColors: [
                Colors.transparent,
                primaryRed.withValues(alpha: 0.3),
                lightRed.withValues(alpha: 0.6),
                primaryRed.withValues(alpha: 0.8),
                Colors.transparent,
              ],
              animationProgress: _glowAnimation.value,
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getAnimatedGradientColors(),
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: GradientRotation(_gradientAnimation.value * 3.14), // Half rotation for smoother loop
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: lightRed.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: widget.onPressed,
                  backgroundColor: Colors.transparent,
                  foregroundColor: widget.theme.floatingActionButtonTheme.foregroundColor,
                  elevation: 0,
                  icon: Icon(
                    Icons.auto_awesome,
                    size: AppResponsive.fontSize(context, 24),
                  ),
                  label: SizeTransition(
                    sizeFactor: widget.sizeAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1.0,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 3.0 * widget.sizeAnimation.value,
                      ),
                      child: Text(
                        'ai_probability'.tr(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}