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
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Single animation controller for subtle gradient rotation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

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
    _gradientController.dispose();
    super.dispose();
  }

  // Simple gradient colors
  List<Color> _getGradientColors() {
    final isDark = widget.theme.brightness == Brightness.dark;

    // Use your theme's red colors for gradient
    final primaryRed = isDark ? const Color(0xFFFF5252) : Colors.red;
    final lightRed = isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF5252);
    final deepRed = isDark ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);

    return [
      primaryRed,
      lightRed,
      deepRed,
      primaryRed,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sizeAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            // Cache theme colors to avoid repeated lookups
            final isDark = widget.theme.brightness == Brightness.dark;
            final primaryRed = isDark ? const Color(0xFFFF5252) : Colors.red;

            return AnimatedGradientBorder(
              borderSize: 1.5, // Reduced border width
              glowSize: 0.5, // Reduced glow size
              gradientColors: [
                Colors.transparent,
                primaryRed.withValues(alpha: 0.4),
                primaryRed.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              animationProgress: 0.0, // Removed glow animation
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getGradientColors(),
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: GradientRotation(_gradientAnimation.value *
                        1.57), // Reduced rotation (quarter turn)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withValues(
                          alpha: 0.15), // Reduced shadow opacity
                      blurRadius: 8, // Reduced blur
                      offset: const Offset(0, 2), // Reduced offset
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: widget.onPressed,
                  backgroundColor: Colors.transparent,
                  foregroundColor:
                      widget.theme.floatingActionButtonTheme.foregroundColor,
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
