import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lottery_draw_cubit.dart';
import 'rolling_digit_widget.dart';

class LotteryDrawScreen extends StatelessWidget {
  const LotteryDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LotteryDrawCubit(),
      child: const _LotteryDrawScreenContent(),
    );
  }
}

class _LotteryDrawScreenContent extends StatefulWidget {
  const _LotteryDrawScreenContent();

  @override
  State<_LotteryDrawScreenContent> createState() => _LotteryDrawScreenContentState();
}

class _LotteryDrawScreenContentState extends State<_LotteryDrawScreenContent> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: const Color(0xFF000000),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
            title: const Text(
              'Virtual Draw Machine',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: Column(
              children: [
                // Draw machine (centered, not full height)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The lottery machine
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            constraints: const BoxConstraints(maxWidth: 600),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF8B1A1A),
                                  const Color(0xFFB22222),
                                  const Color(0xFF8B1A1A),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              border: Border.all(
                                color: const Color(0xFF2a2a2a),
                                width: 6,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 10),
                                _buildMainWindow(state),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: _buildWindowsGrid(state),
                                ),
                                const SizedBox(height: 16),
                                _buildFooter(),
                              ],
                            ),
                          ),
                          // Press and hold button below the machine
                          const SizedBox(height: 24),
                          _buildPressHoldButton(state),
                          const SizedBox(height: 24),
                        ],
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

  Widget _buildHeader() {
    return const LotteryDrawHeader(
      lotteryName: 'കേരള് ലോട്ടറി',
      drawNumber: 'BT 36',
    );
  }

  Widget _buildMainWindow(LotteryDrawState state) {
    final cubit = context.read<LotteryDrawCubit>();
    final duration = cubit.getAnimationDuration();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF8B1A1A),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF2a2a2a),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF666666), width: 0.5),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8E8E8),
                  const Color(0xFFF5F5F5),
                  const Color(0xFFDDDDDD),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Letters
                _buildLetterBox(state.mainLetter1, duration, isSpinning: state.isDrawing),
                const SizedBox(width: 3),
                _buildLetterBox(state.mainLetter2, duration, isSpinning: state.isDrawing),
                const SizedBox(width: 6),
                // Digits (no separator)
                ...state.mainDigits.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(right: entry.key < state.mainDigits.length - 1 ? 3 : 0),
                  child: _buildMainDigitBox(entry.value.toString(), duration, isSpinning: state.isDrawing),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterBox(String letter, Duration duration, {bool isSpinning = false}) {
    return Container(
      width: 30,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          // Top inner shadow
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
          // Left inner shadow
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
          // Rolling Letter
          Center(
            child: RollingLetter(
              letter: letter,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1a1a1a),
              ),
              duration: duration,
              isSpinning: isSpinning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDigitBox(String digit, Duration duration, {bool isSpinning = false}) {
    return Container(
      width: 28,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          // Top inner shadow
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
                    Colors.black.withValues(alpha: 0.3),
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
          // Left inner shadow
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
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Rolling Digit
          Center(
            child: RollingDigit(
              digit: digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
              duration: duration,
              isSpinning: isSpinning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsGrid(LotteryDrawState state) {
    final cubit = context.read<LotteryDrawCubit>();
    final duration = cubit.getAnimationDuration();

    // Simple sequential order: 1, 2, 3 / 4, 5, 6 / 7, 8, 9 / etc.
    final windows = List.generate(18, (index) => index + 1);

    // Split into rows of 3
    final rows = <List<int>>[];
    for (int i = 0; i < windows.length; i += 3) {
      rows.add(windows.sublist(i, i + 3));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((windowNum) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: _buildWindowItem(windowNum, state.windowDigits[windowNum]!, duration, isSpinning: state.isDrawing),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWindowItem(int number, List<int> digits, Duration duration, {bool isSpinning = false}) {
    return Row(
      children: [
        // Window Number (on the left)
        Container(
          width: 24,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFEB3B),
                const Color(0xFFFFD700),
                const Color(0xFFFFAA00),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFFB8860B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Window Display
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8E8E8),
                  const Color(0xFFF5F5F5),
                  const Color(0xFFDDDDDD),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF555555), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: digits.map((digit) => _buildDigitBox(digit.toString(), duration, isSpinning: isSpinning)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitBox(String digit, Duration duration, {bool isSpinning = false}) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 18,
          minWidth: 14,
        ),
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF),
              const Color(0xFFF5F5F5),
              const Color(0xFFE8E8E8),
            ],
          ),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF888888), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: RollingDigit(
            digit: digit,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
            duration: duration,
            isSpinning: isSpinning,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD0D0D0),
            const Color(0xFFB0B0B0),
            const Color(0xFF909090),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        // border: Border.all(color: const Color(0xFF555555), width: 1),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.5),
        //     blurRadius: 6,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Number window and Prize Label
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Single digit number window
              Container(
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE8E8E8),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFDDDDDD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFF888888), width: 1),
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Prize Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF0F0F0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'PRIZE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000000),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          // Red Bulb in Center
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF0000),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),

          // BT and 36 Labels
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BT in dark container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'BT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFFFFF),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 36 in light container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF0F0F0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '36',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000000),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressHoldButton(LotteryDrawState state) {
    return GestureDetector(
      onTapDown: (_) {
        if (!state.isDrawing) {
          context.read<LotteryDrawCubit>().startDraw();
        }
      },
      onTapUp: (_) {
        // User released, stop if needed
      },
      onTapCancel: () {
        // User cancelled touch
      },
      child: AnimatedScale(
        // Visual compression: Shrinks slightly when drawing (pressed state)
        scale: state.isDrawing ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.2), // Highlight at top-left for 3D effect
              radius: 0.8,
              colors: [
                state.isDrawing ? const Color(0xFF999999) : const Color(0xFFFF5555),
                state.isDrawing ? const Color(0xFF555555) : const Color(0xFF990000),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            // Shadow shift: Remove shadow when pressed to simulate being pushed in
            boxShadow: state.isDrawing
                ? [] // No shadow when "pressed"
                : [
                    // Outer glow
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    // Shadow for depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Center(
            child: Icon(
              state.isDrawing ? Icons.autorenew : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom widget for the lottery draw header
class LotteryDrawHeader extends StatefulWidget {
  final String lotteryName;
  final String drawNumber;

  const LotteryDrawHeader({
    super.key,
    required this.lotteryName,
    required this.drawNumber,
  });

  @override
  State<LotteryDrawHeader> createState() => _LotteryDrawHeaderState();
}

class _LotteryDrawHeaderState extends State<LotteryDrawHeader> {
  late Timer _timer;
  String currentTime = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(now);
      currentDate = DateFormat('dd.MM.yy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B0000),
            const Color(0xFF6B0000),
            const Color(0xFF5B0000),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Kerala Lottery Name and Draw Number
          _buildLotteryNameSection(),

          // Center: Government Department Name
          Expanded(
            child: _buildDepartmentSection(),
          ),

          // Right: Digital Timer Display
          _buildTimerSection(),
        ],
      ),
    );
  }

  Widget _buildLotteryNameSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFEB3B),
            const Color(0xFFFFD700),
            const Color(0xFFFFAA00),
          ],
        ),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFB8860B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.lotteryName,
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontWeight: FontWeight.bold,
              fontSize: 9,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              widget.drawNumber,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'GOVERNMENT OF KERALA',
            style: TextStyle(
              color: Color(0xFFFFEB3B),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'STATE LOTTERIES DEPARTMENT',
            style: TextStyle(
              color: Color(0xFFFFEB3B),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF1a1a1a), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time display
          Text(
            currentTime,
            style: const TextStyle(
              color: Color(0xFFFF0000),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.1,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Color(0xFFFF0000),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          // Date display
          Text(
            currentDate,
            style: const TextStyle(
              color: Color(0xFFFF0000),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 9,
              height: 1.1,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0xFFFF0000),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}