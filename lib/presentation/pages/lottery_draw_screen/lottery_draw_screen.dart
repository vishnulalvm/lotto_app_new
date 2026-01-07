import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lottery_draw_cubit.dart';
import 'rolling_digit_widget.dart';
import 'lottery_series_selector.dart';

class LotteryDrawScreen extends StatelessWidget {
  const LotteryDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LotteryDrawCubit(),
      child: const Scaffold(
        backgroundColor: Color(0xFF000000),
        appBar: _StaticAppBar(),
        body: _LotteryBody(),
      ),
    );
  }
}

// Static AppBar widget (won't rebuild)
class _StaticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StaticAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
      actions: [
        IconButton(
          onPressed: () {
            // Copy functionality will be implemented later
          },
          icon: const Icon(
            Icons.copy,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

// Body widget with RepaintBoundary for performance
class _LotteryBody extends StatelessWidget {
  const _LotteryBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF000000)),
      child: Column(
        children: [
          // Lottery and Series selector dropdowns
          const LotterySeriesSelector(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // RepaintBoundary caches the heavy gradient container
                    RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8B1A1A),
                              Color(0xFFB22222),
                              Color(0xFF8B1A1A),
                            ],
                            stops: [0.0, 0.5, 1.0],
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
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LotteryDrawHeader(
                              lotteryName: 'കേരള് ലോട്ടറി',
                              drawNumber: 'BT 36',
                            ),
                            SizedBox(height: 10),
                            _LiveMainWindow(),
                            SizedBox(height: 24),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: _LiveWindowsGrid(),
                            ),
                            SizedBox(height: 16),
                            _FooterSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _LivePressButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Live Main Window - Only this rebuilds
class _LiveMainWindow extends StatelessWidget {
  const _LiveMainWindow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      buildWhen: (prev, current) =>
          prev.mainDigits != current.mainDigits ||
          prev.mainLetter1 != current.mainLetter1 ||
          prev.mainLetter2 != current.mainLetter2 ||
          prev.isDrawing != current.isDrawing,
      builder: (context, state) {
        // Duration is now controlled autonomously by individual reels
        const duration = Duration(milliseconds: 100);

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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8E8E8),
                      Color(0xFFF5F5F5),
                      Color(0xFFDDDDDD),
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
                    _buildLetterBox(state.mainLetter1, duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildLetterBox(state.mainLetter2, duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 6),
                    _buildMainDigitBox(state.mainDigits[0].toString(), duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildMainDigitBox(state.mainDigits[1].toString(), duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildMainDigitBox(state.mainDigits[2].toString(), duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildMainDigitBox(state.mainDigits[3].toString(), duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildMainDigitBox(state.mainDigits[4].toString(), duration, isSpinning: state.isDrawing),
                    const SizedBox(width: 3),
                    _buildMainDigitBox(state.mainDigits[5].toString(), duration, isSpinning: state.isDrawing),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLetterBox(String letter, Duration duration, {bool isSpinning = false}) {
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
      ),
    );
  }

  Widget _buildMainDigitBox(String digit, Duration duration, {bool isSpinning = false}) {
    return RepaintBoundary(
      child: Container(
        width: 28,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          children: [
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
      ),
    );
  }
}

// Live Windows Grid - Only rebuilds when window digits change
class _LiveWindowsGrid extends StatelessWidget {
  const _LiveWindowsGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      buildWhen: (prev, current) =>
          prev.windowDigits != current.windowDigits ||
          prev.isDrawing != current.isDrawing,
      builder: (context, state) {
        // Duration is now controlled autonomously by individual reels
        const duration = Duration(milliseconds: 100);

        // Create 6 rows × 3 columns layout where numbers go down first
        final rows = <List<int>>[];
        for (int row = 0; row < 6; row++) {
          final rowWindows = <int>[];
          for (int col = 0; col < 3; col++) {
            final windowNum = row + 1 + (col * 6); // 1,2,3,4,5,6 | 7,8,9,10,11,12 | 13,14,15,16,17,18
            rowWindows.add(windowNum);
          }
          rows.add(rowWindows);
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
                      child: _buildWindowItem(
                        windowNum,
                        state.windowDigits[windowNum]!,
                        duration,
                        isSpinning: state.isDrawing,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWindowItem(int number, List<int> digits, Duration duration, {bool isSpinning = false}) {
    return RepaintBoundary(
      child: Row(
        children: [
          Container(
            width: 24,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFEB3B),
                  Color(0xFFFFD700),
                  Color(0xFFFFAA00),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8E8E8),
                    Color(0xFFF5F5F5),
                    Color(0xFFDDDDDD),
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
                children: [
                  _buildDigitBox(digits[0].toString(), duration, isSpinning: isSpinning),
                  _buildDigitBox(digits[1].toString(), duration, isSpinning: isSpinning),
                  _buildDigitBox(digits[2].toString(), duration, isSpinning: isSpinning),
                  _buildDigitBox(digits[3].toString(), duration, isSpinning: isSpinning),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(String digit, Duration duration, {bool isSpinning = false}) {
    return Flexible(
      child: RepaintBoundary(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 18,
            minWidth: 14,
          ),
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF888888), width: 0.8),
            // Disable shadows during spinning to reduce raster cost
            boxShadow: isSpinning ? null : [
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
      ),
    );
  }
}

// Footer Section with live indicator
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      buildWhen: (prev, current) => prev.isDrawing != current.isDrawing,
      builder: (context, state) {
        return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD0D0D0),
            Color(0xFFB0B0B0),
            Color(0xFF909090),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8E8E8),
                      Color(0xFFF5F5F5),
                      Color(0xFFDDDDDD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFF888888), width: 1),
                ),
                child: const Center(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F0F0),
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
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isDrawing ? const Color(0xFF00FF00) : const Color(0xFFFF0000),
              boxShadow: [
                BoxShadow(
                  color: state.isDrawing
                      ? Colors.green.withValues(alpha: 0.6)
                      : Colors.red.withValues(alpha: 0.6),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F0F0),
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
      },
    );
  }
}

// Live Press Button - Only rebuilds on button state change
class _LivePressButton extends StatelessWidget {
  const _LivePressButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LotteryDrawCubit, LotteryDrawState>(
      buildWhen: (prev, current) => prev.isDrawing != current.isDrawing,
      builder: (context, state) {
        return GestureDetector(
          onTapDown: (_) {
            if (!state.isDrawing) {
              context.read<LotteryDrawCubit>().startDraw();
            }
          },
          child: AnimatedScale(
            scale: state.isDrawing ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.2),
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
                boxShadow: state.isDrawing
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Center(
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Header widget - Optimized with separated timer widget
class LotteryDrawHeader extends StatelessWidget {
  final String lotteryName;
  final String drawNumber;

  const LotteryDrawHeader({
    super.key,
    required this.lotteryName,
    required this.drawNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B0000),
            Color(0xFF6B0000),
            Color(0xFF5B0000),
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
          _buildLotteryNameSection(),
          Expanded(child: _buildDepartmentSection()),
          const _LiveTimerSection(), // ← Now a separate stateful widget
        ],
      ),
    );
  }

  Widget _buildLotteryNameSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFEB3B),
            Color(0xFFFFD700),
            Color(0xFFFFAA00),
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
            lotteryName,
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
              drawNumber,
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
}

// Separate stateful widget for timer - only this rebuilds every second
class _LiveTimerSection extends StatefulWidget {
  const _LiveTimerSection();

  @override
  State<_LiveTimerSection> createState() => _LiveTimerSectionState();
}

class _LiveTimerSectionState extends State<_LiveTimerSection> {
  late Timer _timer;
  late DateFormat _timeFormat;
  late DateFormat _dateFormat;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    // Create formatters once instead of every second
    _timeFormat = DateFormat('HH:mm:ss');
    _dateFormat = DateFormat('dd.MM.yy');
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final newTime = _timeFormat.format(now);
    final newDate = _dateFormat.format(now);

    // Only call setState if values actually changed (prevent unnecessary rebuilds)
    if (newTime != _currentTime || newDate != _currentDate) {
      setState(() {
        _currentTime = newTime;
        _currentDate = newDate;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
            Text(
              _currentTime,
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
            Text(
              _currentDate,
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
      ),
    );
  }
}
