import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lottery_draw_cubit.dart';
import 'sprite_digit_widget.dart';

/// Series-specific letter box that only rotates through the selected series letters
class SeriesLetterBox extends StatelessWidget {
  final bool isSpinning;

  const SeriesLetterBox({
    super.key,
    required this.isSpinning,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      buildWhen: (prev, current) =>
          prev.mainLetter2 != current.mainLetter2 ||
          prev.isDrawing != current.isDrawing ||
          prev.seriesLetters != current.seriesLetters,
      builder: (context, state) {
        final fontSize = 24.0;
        return RepaintBoundary(
          child: Container(
            width: 30,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                // Top shadow
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(1),
                        topRight: Radius.circular(1),
                      ),
                    ),
                  ),
                ),
                // Left shadow
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Letter display with custom alphabet using sprite-based roller
                Center(
                  child: CustomSeriesLetterRoller(
                    letter: state.mainLetter2,
                    isSpinning: isSpinning,
                    width: (fontSize * 1.2).round(),
                    cellHeight: (fontSize * 1.5).round(),
                    textColor: const Color(0xFF1a1a1a),
                    fontSize: fontSize,
                    customAlphabet: state.seriesLetters,
                  ),
                ),
                // Gradient overlay for cylindrical shadow effect
                _buildGradientOverlay(),
              ],
            ),
          ),
        );
      },
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
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
