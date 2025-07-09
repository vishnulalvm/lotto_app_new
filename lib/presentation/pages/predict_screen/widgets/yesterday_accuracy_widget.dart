import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

class YesterdayAccuracyWidget extends StatefulWidget {
  final DigitAccuracy digitAccuracy;
  final ThemeData theme;

  const YesterdayAccuracyWidget({
    super.key,
    required this.digitAccuracy,
    required this.theme,
  });

  @override
  State<YesterdayAccuracyWidget> createState() =>
      _YesterdayAccuracyWidgetState();
}

class _YesterdayAccuracyWidgetState extends State<YesterdayAccuracyWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
        4,
        (index) => AnimationController(
              duration: Duration(milliseconds: 400 + (index * 100)),
              vsync: this,
            ));

    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)))
        .toList();

    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get theme-aware colors
  Color _getThemeAwareColor(Color lightColor, Color darkColor) {
    return widget.theme.brightness == Brightness.dark ? darkColor : lightColor;
  }

  Color _getThemeAwareBackgroundColor(Color lightColor) {
    return widget.theme.brightness == Brightness.dark
        ? lightColor.withOpacity(0.1)
        : lightColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;

    final accuracyData = [
      {
        'percentage': '100%',
        'numbers': widget.digitAccuracy.hundredPercent,
        'color': _getThemeAwareColor(
            const Color(0xFF4CAF50), const Color(0xFF66BB6A)),
        'lightColor': _getThemeAwareBackgroundColor(const Color(0xFFE8F5E8)),
        'label_key': 'perfect_match',
        'icon': Icons.stars_rounded,
      },
      {
        'percentage': '75%',
        'numbers': widget.digitAccuracy.seventyFivePercent,
        'color': _getThemeAwareColor(
            const Color(0xFF8BC34A), const Color(0xFF9CCC65)),
        'lightColor': _getThemeAwareBackgroundColor(const Color(0xFFF1F8E9)),
        'label_key': 'close_match',
        'icon': Icons.thumb_up_rounded,
      },
      {
        'percentage': '50%',
        'numbers': widget.digitAccuracy.fiftyPercent,
        'color': _getThemeAwareColor(
            const Color(0xFFFF9800), const Color(0xFFFFB74D)),
        'lightColor': _getThemeAwareBackgroundColor(const Color(0xFFFFF3E0)),
        'label_key': 'partial_match',
        'icon': Icons.trending_up_rounded,
      },
      {
        'percentage': '25%',
        'numbers': widget.digitAccuracy.twentyFivePercent,
        'color': _getThemeAwareColor(
            const Color(0xFFF44336), widget.theme.primaryColor),
        'lightColor': _getThemeAwareBackgroundColor(const Color(0xFFFFEBEE)),
        'label_key': 'low_match',
        'icon': Icons.trending_down_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: widget.theme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'accuracy_breakdown'.tr(),
                style: widget.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? widget.theme.textTheme.bodyLarge?.color
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Accuracy rows
        ...accuracyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _animations[index].value)),
                child: Opacity(
                  opacity: _animations[index].value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: AccuracyRowCard(
                      percentage: data['percentage'] as String,
                      numbers: data['numbers'] as List<String>,
                      color: data['color'] as Color,
                      lightColor: data['lightColor'] as Color,
                      label: (data['label_key'] as String).tr(),
                      icon: data['icon'] as IconData,
                      theme: widget.theme,
                    ),
                  ),
                ),
              );
            },
          );
        }),

        const SizedBox(height: 16),

        // Bottom summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.theme.primaryColor.withOpacity(0.1),
                _getThemeAwareColor(Colors.green, const Color(0xFF66BB6A))
                    .withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: widget.theme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'accuracy_breakdown_yesterday'.tr(),
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Individual Accuracy Row Card
class AccuracyRowCard extends StatelessWidget {
  final String percentage;
  final List<String> numbers;
  final Color color;
  final Color lightColor;
  final String label;
  final IconData icon;
  final ThemeData theme;

  const AccuracyRowCard({
    super.key,
    required this.percentage,
    required this.numbers,
    required this.color,
    required this.lightColor,
    required this.label,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final cardBackgroundColor = isDark ? theme.cardTheme.color : lightColor;
    final numbersSectionBackground = isDark
        ? theme.cardTheme.color?.withOpacity(0.5) ?? const Color(0xFF2E2E2E)
        : Colors.white.withOpacity(0.8);
    final emptyStateBackground = isDark
        ? theme.disabledColor.withOpacity(0.2)
        : Colors.grey.withOpacity(0.1);
    final textColor =
        isDark ? theme.textTheme.bodyMedium?.color : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.5 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Icon and percentage
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      percentage,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? theme.textTheme.titleMedium?.color : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${numbers.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Numbers section
          if (numbers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: emptyStateBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? theme.disabledColor.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'no_numbers_in_category'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: numbersSectionBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(isDark ? 0.4 : 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'numbers'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: numbers.map((number) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withOpacity(isDark ? 0.6 : 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          number,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white : color,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
