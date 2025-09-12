import 'package:flutter/material.dart';
import 'dart:math' as math;

class LotteryBackgroundPattern extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color backgroundColor;
  final Brightness brightness; // Add brightness parameter

  const LotteryBackgroundPattern({
    super.key,
    required this.child,
    required this.primaryColor,
    required this.backgroundColor,
    required this.brightness, // Make brightness required
  });

  @override
  State<LotteryBackgroundPattern> createState() => _LotteryBackgroundPatternState();
}

class _LotteryBackgroundPatternState extends State<LotteryBackgroundPattern>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late List<FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _generateFloatingIcons();
  }

  void _generateFloatingIcons() {
    final random = math.Random();
    _floatingIcons = List.generate(15, (index) {
      return FloatingIcon(
        icon: _getLotteryIcons()[random.nextInt(_getLotteryIcons().length)],
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        size: 20 + random.nextDouble() * 25,
        opacity: _getIconOpacity(random),
        speed: 0.5 + random.nextDouble() * 1.5,
      );
    });
  }

  double _getIconOpacity(math.Random random) {
    if (widget.brightness == Brightness.light) {
      return 0.08 + random.nextDouble() * 0.15; // Lighter for light mode
    } else {
      return 0.15 + random.nextDouble() * 0.25; // More visible for dark mode
    }
  }

  List<IconData> _getLotteryIcons() {
    return [
      Icons.monetization_on,
      Icons.stars,
      Icons.card_giftcard,
      Icons.emoji_events,
      Icons.casino,
      Icons.diamond,
      Icons.attach_money,
      Icons.celebration,
      Icons.workspace_premium,
      Icons.redeem,
    ];
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _buildBackgroundGradient(),
      ),
      child: Stack(
        children: [
          // Static pattern background
          CustomPaint(
            painter: LotteryPatternPainter(
              primaryColor: _getPatternColor(),
              brightness: widget.brightness,
            ),
            size: Size.infinite,
          ),
          // Floating animated icons
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                painter: FloatingIconsPainter(
                  icons: _floatingIcons,
                  animation: _floatController.value,
                  pulseAnimation: _pulseController.value,
                  primaryColor: widget.primaryColor,
                  brightness: widget.brightness,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: _buildOverlayGradient(),
            ),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }

  LinearGradient _buildBackgroundGradient() {
    if (widget.brightness == Brightness.light) {
      // Light mode: Subtle gradient with more contrast
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          widget.backgroundColor,
          const Color(0xFFFFF5F5), // Very light pink
          widget.primaryColor.withValues(alpha: 0.03),
          const Color(0xFFFEF2F2), // Another light shade
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      );
    } else {
      // Dark mode: Keep existing gradient
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          widget.backgroundColor,
          widget.backgroundColor.withValues(alpha: 0.8),
          widget.primaryColor.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.6, 1.0],
      );
    }
  }

  LinearGradient _buildOverlayGradient() {
    if (widget.brightness == Brightness.light) {
      // Light mode: Very subtle overlay
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.1),
          widget.primaryColor.withValues(alpha: 0.02),
        ],
      );
    } else {
      // Dark mode: Keep existing overlay
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.2),
          Colors.black.withValues(alpha: 0.5),
        ],
      );
    }
  }

  Color _getPatternColor() {
    if (widget.brightness == Brightness.light) {
      return widget.primaryColor.withValues(alpha: 0.08);
    } else {
      return widget.primaryColor.withValues(alpha: 0.1);
    }
  }
}

class FloatingIcon {
  final IconData icon;
  final double startX;
  final double startY;
  final double size;
  final double opacity;
  final double speed;

  FloatingIcon({
    required this.icon,
    required this.startX,
    required this.startY,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

class LotteryPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Brightness brightness;

  LotteryPatternPainter({
    required this.primaryColor,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = _getStrokeColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Fixed seed for consistent pattern
    
    // Draw scattered decorative elements with better visibility in light mode
    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2 + random.nextDouble() * 6;
      
      if (brightness == Brightness.light && i % 3 == 0) {
        // Add some stroke circles for light mode
        canvas.drawCircle(Offset(x, y), radius + 2, strokePaint);
      }
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw diamond shapes with enhanced visibility
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final size1 = 12 + random.nextDouble() * 8;
      
      _drawDiamond(canvas, Offset(x, y), size1, paint);
      
      if (brightness == Brightness.light && i % 2 == 0) {
        // Add stroke diamonds for light mode
        _drawDiamond(canvas, Offset(x, y), size1 + 3, strokePaint);
      }
    }

    // Add some star patterns for premium feel
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final size1 = 8 + random.nextDouble() * 6;
      
      _drawStar(canvas, Offset(x, y), size1, paint);
    }
  }

  Color _getStrokeColor() {
    if (brightness == Brightness.light) {
      return Colors.red.withValues(alpha: 0.15);
    } else {
      return Colors.red.withValues(alpha: 0.2);
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.7, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.7, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final double angle = (math.pi * 2) / 5;
    
    for (int i = 0; i < 5; i++) {
      final double x = center.dx + size * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + size * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final double innerX = center.dx + (size * 0.4) * math.cos((i + 0.5) * angle - math.pi / 2);
      final double innerY = center.dy + (size * 0.4) * math.sin((i + 0.5) * angle - math.pi / 2);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingIconsPainter extends CustomPainter {
  final List<FloatingIcon> icons;
  final double animation;
  final double pulseAnimation;
  final Color primaryColor;
  final Brightness brightness;

  FloatingIconsPainter({
    required this.icons,
    required this.animation,
    required this.pulseAnimation,
    required this.primaryColor,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < icons.length; i++) {
      final floatingIcon = icons[i];
      final progress = (animation * floatingIcon.speed) % 1.0;
      final x = floatingIcon.startX * size.width;
      final y = (floatingIcon.startY + progress) * size.height % size.height;
      
      // Add pulse effect
      final pulseOffset = math.sin(pulseAnimation * math.pi * 2 + i) * 0.3;
      final dynamicOpacity = floatingIcon.opacity * (1.0 + pulseOffset);
      
      final paint = Paint()
        ..color = _getIconColor(floatingIcon, dynamicOpacity)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = _getIconStrokeColor(floatingIcon, dynamicOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final radius = floatingIcon.size / 4;
      
      // Add stroke for better visibility in light mode
      if (brightness == Brightness.light && i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), radius + 1, strokePaint);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  Color _getIconColor(FloatingIcon icon, double opacity) {
    if (brightness == Brightness.light) {
      return primaryColor.withValues(alpha: opacity.clamp(0.0, 0.25));
    } else {
      return primaryColor.withValues(alpha: opacity.clamp(0.0, 0.4));
    }
  }

  Color _getIconStrokeColor(FloatingIcon icon, double opacity) {
    if (brightness == Brightness.light) {
      return primaryColor.withValues(alpha: (opacity * 1.5).clamp(0.0, 0.3));
    } else {
      return primaryColor.withValues(alpha: (opacity * 1.2).clamp(0.0, 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}