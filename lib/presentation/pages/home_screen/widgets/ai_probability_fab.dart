import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';

class AIProbabilityFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Animation<double> slideAnimation;
  final ThemeData theme;

  const AIProbabilityFAB({
    super.key,
    required this.onPressed,
    required this.slideAnimation,
    required this.theme,
  });

  @override
  State<AIProbabilityFAB> createState() => _AIProbabilityFABState();
}

class _AIProbabilityFABState extends State<AIProbabilityFAB> {
  // Cache expensive theme calculations
  late bool _isDark;
  late Color _primaryRed;
  late List<Color> _cachedGradientColors;

  @override
  void initState() {
    super.initState();
    
    // Cache theme colors once
    _updateThemeColors();
  }
  
  void _updateThemeColors() {
    _isDark = widget.theme.brightness == Brightness.dark;
    _primaryRed = _isDark ? const Color(0xFFFF5252) : Colors.red;
    _cachedGradientColors = _getGradientColors();
  }
  
  @override
  void didUpdateWidget(AIProbabilityFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.brightness != widget.theme.brightness) {
      _updateThemeColors();
    }
  }

  // Simple gradient colors
  List<Color> _getGradientColors() {
    // Use your theme's red colors for gradient
    final lightRed = _isDark ? const Color(0xFFFF8A80) : const Color(0xFFFF5252);
    final deepRed = _isDark ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);

    return [
      _primaryRed,
      lightRed,
      deepRed,
      _primaryRed,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 2), // Start 2x height below
        end: const Offset(0, 0),   // End at normal position
      ).animate(CurvedAnimation(
        parent: widget.slideAnimation,
        curve: Curves.easeOutCubic,       // Smooth slide up when showing (safer than easeOutBack)
        reverseCurve: Curves.easeInQuart, // Slower drop when hiding
      )),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _cachedGradientColors,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryRed.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
          label: Padding(
            padding: const EdgeInsets.only(left: 3.0),
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
    );
  }
}
