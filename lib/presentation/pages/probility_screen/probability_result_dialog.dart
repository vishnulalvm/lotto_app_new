import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
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
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => ProbabilityResultDialog(
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
  late AnimationController _fillController;
  late AnimationController _pulseController; // Only for high probability
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _animationsCompleted = false;
  bool _isInfoExpanded = false;

  // All emojis for different probability ranges
  final List<String> allEmojis = ['😞', '😐', '🤞', '😊', '🎉'];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced duration
      vsync: this,
    );

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Reduced duration
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Reduced duration
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Reduced slide distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic, // Simpler curve
    ));

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.probability / 100.0,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic, // Simpler curve
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Simplified animation sequence
    _slideController.forward().then((_) {
      _fillController.forward().then((_) {
        setState(() {
          _animationsCompleted = true;
        });
        // Only animate pulse for high probability to reduce resource usage
        if (widget.probability >= 80) {
          _pulseController.repeat(reverse: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fillController.dispose();
    _pulseController.dispose();
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
        final pulseScale = (widget.probability >= 80 && _animationsCompleted) 
            ? _pulseAnimation.value 
            : 1.0;
            
        return Transform.scale(
          scale: pulseScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 240, // Reduced size
                height: 240,
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
                width: 240,
                height: 240,
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
                width: 190, // Reduced size
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: probabilityTheme.color.withValues(alpha: 0.2),
                      blurRadius: 10, // Reduced blur
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
                        fontSize: 60, // Reduced size
                        fontWeight: FontWeight.bold,
                        color: probabilityTheme.color,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Simple emoji without animation
                    Text(
                      probabilityTheme.emoji,
                      style: const TextStyle(fontSize: 35), // Reduced size
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _isInfoExpanded = !_isInfoExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _isInfoExpanded 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'probability_info'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'probability_disclaimer_text'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'probability_info_short'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ),
              Icon(
                _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.blue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiRow() {
    final probabilityTheme = _getProbabilityTheme();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(allEmojis.length, (index) {
          final isActive = _getEmojiIndex() == index;

          return Container(
            width: isActive ? 46 : 36, // Reduced sizes
            height: isActive ? 46 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? probabilityTheme.color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
              border: Border.all(
                color: isActive
                    ? probabilityTheme.color.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                allEmojis[index],
                style: TextStyle(
                  fontSize: isActive ? 18 : 16, // Reduced sizes
                ),
              ),
            ),
          );
        }),
      ),
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
    // Close dialog and navigate to home
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final probabilityTheme = _getProbabilityTheme();
    final size = MediaQuery.of(context).size;

    // Increased dialog size for better content fit
    final dialogWidth = min(size.width * 0.9, 450.0);
    final dialogHeight = min(size.height * 0.9, 650.0);

    return PopScope(
      canPop: false, // Prevent default pop behavior
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
                        Expanded(
                          child: Text(
                            probabilityTheme.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: probabilityTheme.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Close dialog and navigate to home
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            // Navigate to home screen to prevent back button issues
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                context.go('/');
                              }
                            });
                          },
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

                  // Main content - removed scroll, using spaceEvenly layout
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Probability display with fill
                          _buildCircularProgress(),
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

                  // Information section
                  _buildInfoSection(),

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
  bool shouldRepaint(covariant CircularFillPainter oldDelegate) {
    return fillPercentage != oldDelegate.fillPercentage ||
           fillColor != oldDelegate.fillColor;
  }
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
