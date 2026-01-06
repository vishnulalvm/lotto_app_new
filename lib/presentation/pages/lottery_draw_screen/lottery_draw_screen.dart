import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';

class LotteryDrawScreen extends StatefulWidget {
  const LotteryDrawScreen({super.key});

  @override
  State<LotteryDrawScreen> createState() => _LotteryDrawScreenState();
}

class _LotteryDrawScreenState extends State<LotteryDrawScreen> {
  bool isDrawing = false;
  final Random random = Random();
  Timer? _clockTimer;
  Timer? _drawTimer;
  String currentTime = '';
  String currentDate = '';
  int currentTick = 0;

  // Main window values
  String mainLetter1 = 'B';
  String mainLetter2 = 'V';
  List<int> mainDigits = [8, 5, 6, 2, 8, 1];

  // Timer display
  String timerValue = '30239';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(now);
      currentDate = DateFormat('dd.MM.yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _drawTimer?.cancel();
    super.dispose();
  }
  
  // 18 windows (each with 4 digits)
  Map<int, List<int>> windowDigits = {
    1: [2, 7, 9, 4],
    2: [9, 7, 5, 5],
    3: [4, 3, 5, 5],
    4: [9, 9, 0, 1],
    5: [1, 4, 6, 8],
    6: [5, 8, 9, 2],
    7: [1, 0, 4, 7],
    8: [4, 2, 5, 3],
    9: [7, 8, 0, 3],
    10: [1, 2, 7, 8],
    11: [8, 0, 2, 5],
    12: [2, 5, 9, 4],
    13: [0, 4, 7, 9],
    14: [5, 1, 5, 1],
    15: [8, 5, 4, 6],
    16: [8, 9, 8, 3],
    17: [1, 8, 2, 1],
    18: [6, 8, 5, 7],
  };

  String getRandomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[random.nextInt(letters.length)];
  }

  int getRandomDigit() {
    return random.nextInt(10);
  }

  Duration getAnimationDuration() {
    // Calculate duration based on current tick for gradual slowdown
    // Start fast (50ms), end slow (400ms)
    if (!isDrawing) return const Duration(milliseconds: 200);

    final progress = currentTick / 60.0; // 0.0 to 1.0
    final durationMs = 50 + (progress * 350); // 50ms to 400ms
    return Duration(milliseconds: durationMs.toInt());
  }

  Future<void> startDraw() async {
    if (isDrawing) return;

    setState(() {
      isDrawing = true;
      currentTick = 0;
    });

    // Cancel any existing draw timer
    _drawTimer?.cancel();

    // Animate for 3 seconds
    _drawTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (timer.tick >= 60) {
        timer.cancel();
        setState(() {
          isDrawing = false;
          currentTick = 0;
        });
        return;
      }

      setState(() {
        currentTick = timer.tick;

        // Update main window
        mainLetter1 = getRandomLetter();
        mainLetter2 = getRandomLetter();
        mainDigits = List.generate(6, (_) => getRandomDigit());

        // Update timer
        timerValue = random.nextInt(99999).toString().padLeft(5, '0');

        // Update all 18 windows
        for (int i = 1; i <= 18; i++) {
          windowDigits[i] = List.generate(4, (_) => getRandomDigit());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
                              _buildMainWindow(),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildWindowsGrid(),
                              ),
                              const SizedBox(height: 16),
                              _buildFooter(),
                            ],
                          ),
                        ),
                        // Press and hold button below the machine
                        const SizedBox(height: 24),
                        _buildPressHoldButton(),
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
  }

  Widget _buildHeader() {
    return const LotteryDrawHeader(
      lotteryName: 'കേരള് ലോട്ടറി',
      drawNumber: 'BT 36',
    );
  }

  Widget _buildMainWindow() {
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF666666), width: 0.5),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                _buildLetterBox(mainLetter1),
                const SizedBox(width: 3),
                _buildLetterBox(mainLetter2),
                const SizedBox(width: 6),
                // Digits (no separator)
                ...mainDigits.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(right: entry.key < mainDigits.length - 1 ? 3 : 0),
                  child: _buildMainDigitBox(entry.value.toString()),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterBox(String letter) {
    return Container(
      width: 32,
      height: 40,
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
          // Animated Text
          Center(
            child: AnimatedSwitcher(
              duration: getAnimationDuration(),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: Text(
                letter,
                key: ValueKey(letter),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDigitBox(String digit) {
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
          // Animated Text
          Center(
            child: AnimatedSwitcher(
              duration: getAnimationDuration(),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: Text(
                digit,
                key: ValueKey(digit),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsGrid() {
    final windowOrder = [1, 7, 13, 2, 8, 14, 3, 9, 15, 4, 10, 16, 5, 11, 17, 6, 12, 18];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Always use 3 columns for mobile
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 18,
          itemBuilder: (context, index) {
            final windowNum = windowOrder[index];
            return _buildWindowItem(windowNum, windowDigits[windowNum]!);
          },
        );
      },
    );
  }

  Widget _buildWindowItem(int number, List<int> digits) {
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
              children: digits.map((digit) => _buildDigitBox(digit.toString())).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitBox(String digit) {
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
          child: AnimatedSwitcher(
            duration: getAnimationDuration(),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: Text(
              digit,
              key: ValueKey(digit),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
            ),
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

  Widget _buildPressHoldButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!isDrawing) {
          startDraw();
        }
      },
      onTapUp: (_) {
        // User released, stop if needed
      },
      onTapCancel: () {
        // User cancelled touch
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              isDrawing ? const Color(0xFF888888) : const Color(0xFFFF3333),
              isDrawing ? const Color(0xFF555555) : const Color(0xFFCC0000),
              isDrawing ? const Color(0xFF333333) : const Color(0xFF990000),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: (isDrawing ? Colors.grey : Colors.red).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            // Shadow for depth
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.2,
              colors: [
                isDrawing ? const Color(0xFF666666) : const Color(0xFFFF1111),
                isDrawing ? const Color(0xFF444444) : const Color(0xFFBB0000),
              ],
            ),
            border: Border.all(
              color: isDrawing ? const Color(0xFF222222) : const Color(0xFF880000),
              width: 1.5,
            ),
          ),
          child: Center(
            // Black center button
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF333333),
                    const Color(0xFF000000),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF111111),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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