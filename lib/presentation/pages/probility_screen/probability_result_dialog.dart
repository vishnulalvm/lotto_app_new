import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';

class ProbabilityResultDialog extends StatefulWidget {
  final String lotteryName;
  final String lotteryNumber;
  final double probability;
  final String? message;
  final VoidCallback? onScanAnother;

  const ProbabilityResultDialog({
    super.key,
    required this.lotteryName,
    required this.lotteryNumber,
    required this.probability,
    this.message,
    this.onScanAnother,
  });

  @override
  State<ProbabilityResultDialog> createState() =>
      _ProbabilityResultDialogState();

  static void show(
    BuildContext context, {
    required String lotteryName,
    required String lotteryNumber,
    required double probability,
    String? message,
    VoidCallback? onScanAnother,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => ProbabilityResultDialog(
        lotteryName: lotteryName,
        lotteryNumber: lotteryNumber,
        probability: probability,
        message: message,
        onScanAnother: onScanAnother,
      ),
    );
  }
}

class _ProbabilityResultDialogState extends State<ProbabilityResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _emojiController;
  late AnimationController _fillController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _emojiAnimation;
  late Animation<double> _fillAnimation;

  // All emojis for different probability ranges
  final List<String> allEmojis = ['😞', '😐', '🤞', '😊', '🎉'];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    _emojiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emojiController,
      curve: Curves.elasticOut,
    ));

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.probability / 100.0,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward().then((_) {
      _scaleController.forward().then((_) {
        _fillController.forward().then((_) {
          _emojiController.forward();
          if (widget.probability >= 70) {
            _pulseController.repeat(reverse: true);
            _sparkleController.repeat(reverse: true);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _emojiController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  ProbabilityTheme _getProbabilityTheme() {
    if (widget.probability >= 80) {
      return ProbabilityTheme(
        color: const Color(0xFF4CAF50),
        emoji: '🎉',
        message: 'excellent_chance'.tr(),
        gradient: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        icon: Icons.celebration,
        title: 'amazing'.tr(),
      );
    } else if (widget.probability >= 60) {
      return ProbabilityTheme(
        color: const Color(0xFFFFEB3B),
        emoji: '😊',
        message: 'good_chance'.tr(),
        gradient: [const Color(0xFFFFEB3B), const Color(0xFFFFC107)],
        backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.1),
        icon: Icons.thumb_up,
        title: 'great'.tr(),
      );
    } else if (widget.probability >= 40) {
      return ProbabilityTheme(
        color: const Color(0xFFFF9800),
        emoji: '🤞',
        message: 'moderate_chance'.tr(),
        gradient: [const Color(0xFFFF9800), const Color(0xFFFF5722)],
        backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
        icon: Icons.trending_up,
        title: 'not_bad'.tr(),
      );
    } else if (widget.probability >= 20) {
      return ProbabilityTheme(
        color: const Color(0xFFFF5722),
        emoji: '😐',
        message: 'low_chance'.tr(),
        gradient: [const Color(0xFFFF5722), const Color(0xFFE91E63)],
        backgroundColor: const Color(0xFFFF5722).withValues(alpha: 0.1),
        icon: Icons.trending_down,
        title: 'keep_trying'.tr(),
      );
    } else {
      return ProbabilityTheme(
        color: const Color(0xFFF44336),
        emoji: '😞',
        message: 'very_low_chance'.tr(),
        gradient: [const Color(0xFFF44336), const Color(0xFF9C27B0)],
        backgroundColor: const Color(0xFFF44336).withValues(alpha: 0.1),
        icon: Icons.sentiment_neutral,
        title: 'try_another'.tr(),
      );
    }
  }

  Widget _buildCircularProgress() {
    final probabilityTheme = _getProbabilityTheme();

    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.probability >= 70 ? _pulseAnimation.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  // Animated fill circle
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: CircularFillPainter(
                        fillPercentage: _fillAnimation.value,
                        fillColor: probabilityTheme.color,
                        gradient: probabilityTheme.gradient,
                      ),
                    ),
                  ),

                  // Inner content circle
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: probabilityTheme.color.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large percentage text
                        Text(
                          '${widget.probability.toInt()}%',
                          style: TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: probabilityTheme.color,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _emojiAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _emojiAnimation.value,
                              child: Text(
                                probabilityTheme.emoji,
                                style: const TextStyle(fontSize: 45),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final angle = (index * 45) * (3.14159 / 180);
            final radius = 120 + (20 * _sparkleAnimation.value);
            final x = radius * cos(angle);
            final y = radius * sin(angle);

            return Positioned(
              left: 110 + x,
              top: 110 + y,
              child: Opacity(
                opacity: _sparkleAnimation.value,
                child: Icon(
                  Icons.star,
                  size: 10 + (8 * _sparkleAnimation.value),
                  color: Colors.amber.withValues(alpha: 0.8),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmojiRow() {
    return AnimatedBuilder(
      animation: _emojiAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(allEmojis.length, (index) {
              final isActive = _getEmojiIndex() == index;

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                width: isActive ? 50 : 38,
                height: isActive ? 50 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? _getProbabilityTheme().color.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isActive
                        ? _getProbabilityTheme().color.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: isActive ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    allEmojis[index],
                    style: TextStyle(
                      fontSize: isActive ? 20 : 24,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  int _getEmojiIndex() {
    if (widget.probability >= 80) return 4;
    if (widget.probability >= 60) return 3;
    if (widget.probability >= 40) return 2;
    if (widget.probability >= 20) return 1;
    return 0;
  }

  void _handleScanAnother() {
    _handleDialogClose();
  }

  void _handleDialogClose() {
    Navigator.of(context).pop();
    // Always call the callback to reset the scanner
    if (widget.onScanAnother != null) {
      widget.onScanAnother!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final probabilityTheme = _getProbabilityTheme();
    final size = MediaQuery.of(context).size;

    // Increased dialog size and made it responsive
    final dialogWidth = min(size.width * 0.9, 450.0);
    final dialogHeight = min(size.height * 0.85, 600.0);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Call the callback to reset the scanner when dialog is dismissed
          if (widget.onScanAnother != null) {
            widget.onScanAnother!();
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: probabilityTheme.color.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header - reduced padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          probabilityTheme.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: probabilityTheme.color,
                          ),
                        ),
                        IconButton(
                          onPressed: _handleDialogClose,
                          icon: const Icon(Icons.close, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content - reduced horizontal padding
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Probability display with fill
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Sparkles
                              if (widget.probability >= 70) _buildSparkles(),

                              // Main circular progress
                              _buildCircularProgress(),
                            ],
                          ),
                          // Lottery info in row format
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: probabilityTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: probabilityTheme.color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Lottery name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'lottery_name'.tr(),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.lotteryName.toUpperCase(),
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: probabilityTheme.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider
                                Container(
                                  width: 1,
                                  height: 35,
                                  color:
                                      theme.colorScheme.outline.withValues(alpha: 0.2),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                ),

                                // Ticket number
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ticket_number'.tr(),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.lotteryNumber,
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // All emojis at bottom - reduced padding
                  _buildEmojiRow(),

                  // Action button - moved after emoji section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleScanAnother,
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: Text(
                          'scan_another'.tr(),
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: probabilityTheme.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
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

class CircularFillPainter extends CustomPainter {
  final double fillPercentage;
  final Color fillColor;
  final List<Color> gradient;

  CircularFillPainter({
    required this.fillPercentage,
    required this.fillColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient paint
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Calculate the sweep angle based on fill percentage
    final sweepAngle = 2 * pi * fillPercentage;

    // Draw the filled arc (starting from top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      true,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProbabilityTheme {
  final Color color;
  final String emoji;
  final String message;
  final List<Color> gradient;
  final Color backgroundColor;
  final IconData icon;
  final String title;

  ProbabilityTheme({
    required this.color,
    required this.emoji,
    required this.message,
    required this.gradient,
    required this.backgroundColor,
    required this.icon,
    required this.title,
  });
}

extension ProbabilityDialogHelper on BuildContext {
  void showProbabilityResult({
    required String lotteryName,
    required String lotteryNumber,
    required double probability,
    String? message,
    VoidCallback? onScanAnother,
  }) {
    ProbabilityResultDialog.show(
      this,
      lotteryName: lotteryName,
      lotteryNumber: lotteryNumber,
      probability: probability,
      message: message,
      onScanAnother: onScanAnother,
    );
  }
}
