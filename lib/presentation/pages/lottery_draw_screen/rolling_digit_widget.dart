import 'package:flutter/material.dart';
import 'sprite_digit_widget.dart';

/// GPU-optimized rolling digit using sprite sheet technology
/// NO scroll views, NO text rendering per frame - just GPU texture blitting
/// This is the "gold standard" approach used in real slot machines
class RollingDigit extends StatelessWidget {
  final String digit;
  final bool isSpinning;
  final TextStyle style;
  final Duration duration;

  const RollingDigit({
    super.key,
    required this.digit,
    required this.isSpinning,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 22;
    return Stack(
      children: [
        SpriteDigitRoller(
          digit: digit,
          isSpinning: isSpinning,
          width: (fontSize * 1.2).round(), // Increased from 0.8 to 1.2 for better visibility
          cellHeight: (fontSize * 1.5).round(),
          textColor: style.color ?? Colors.black,
          fontSize: fontSize,
        ),
        // OVERLAY: This adds the "Cylindrical" shadow effect
        _buildGradientOverlay(),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}

/// GPU-optimized rolling letter using sprite sheet technology
class RollingLetter extends StatelessWidget {
  final String letter;
  final bool isSpinning;
  final TextStyle style;
  final Duration duration;

  const RollingLetter({
    super.key,
    required this.letter,
    required this.isSpinning,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 24;
    return Stack(
      children: [
        SpriteLetterRoller(
          letter: letter,
          isSpinning: isSpinning,
          width: (fontSize * 1.2).round(), // Increased from 0.8 to 1.2 for better visibility
          cellHeight: (fontSize * 1.5).round(),
          textColor: style.color ?? const Color(0xFF1a1a1a),
          fontSize: fontSize,
        ),
        // OVERLAY: This adds the "Cylindrical" shadow effect
        _buildGradientOverlay(),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
