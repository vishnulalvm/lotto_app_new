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
    return SpriteDigitRoller(
      digit: digit,
      isSpinning: isSpinning,
      width: (fontSize * 0.8).round(),
      cellHeight: (fontSize * 1.5).round(),
      textColor: style.color ?? Colors.black,
      fontSize: fontSize,
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
    return SpriteLetterRoller(
      letter: letter,
      isSpinning: isSpinning,
      width: (fontSize * 0.8).round(),
      cellHeight: (fontSize * 1.5).round(),
      textColor: style.color ?? const Color(0xFF1a1a1a),
      fontSize: fontSize,
    );
  }
}
