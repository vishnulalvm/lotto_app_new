import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lottery_draw_cubit.dart';

/// Static lottery letter box - displays the selected lottery's unique letter
/// No rolling animation, just updates when the lottery selection changes
class StaticLotteryLetterBox extends StatelessWidget {
  const StaticLotteryLetterBox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      builder: (context, state) {
        return Container(
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
              // Letter display
              Center(
                child: Text(
                  state.mainLetter1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
              ),
              // Gradient overlay for cylindrical shadow effect
              _buildGradientOverlay(),
            ],
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
