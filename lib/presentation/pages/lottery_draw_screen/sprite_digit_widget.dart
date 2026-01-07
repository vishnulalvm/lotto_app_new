import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ultra-high-performance sprite-based digit roller
/// Uses pre-rendered textures and GPU blitting for 60fps with 80+ animations
class SpriteDigitRoller extends StatefulWidget {
  final String digit;
  final bool isSpinning;
  final int width;
  final int cellHeight; // CRITICAL: Must be integer for pixel-perfect alignment
  final Color textColor;
  final double fontSize;

  const SpriteDigitRoller({
    super.key,
    required this.digit,
    required this.isSpinning,
    required this.width,
    required this.cellHeight,
    required this.textColor,
    this.fontSize = 22,
  });

  @override
  State<SpriteDigitRoller> createState() => _SpriteDigitRollerState();
}

class _SpriteDigitRollerState extends State<SpriteDigitRoller>
    with SingleTickerProviderStateMixin {
  static ui.Image? _cachedSpriteSheet;
  static bool _isGenerating = false;
  late AnimationController _slideController;
  int _previousDigit = 0;
  int _currentDigit = 0;
  int _targetDigit = 0;
  Timer? _spinTimer;
  bool _isStopping = false; // Guard flag to prevent race conditions
  static const _spinIntervalMs = 80; // Fast spinning speed
  static const _finalSpinDelayMs = 150; // Delay before final snap

  @override
  void initState() {
    super.initState();
    _currentDigit = int.tryParse(widget.digit) ?? 0;
    _targetDigit = _currentDigit;
    _previousDigit = _currentDigit;

    // CRITICAL: Duration must be < spinIntervalMs to prevent overlap
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70), // 70ms < 80ms interval
    );

    // CRITICAL: Snap to final position when animation completes
    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset to static state with current digit properly aligned
        _previousDigit = _currentDigit;
        _slideController.value = 0.0;
        if (mounted) setState(() {});
      }
    });

    _loadSpriteSheet();
  }

  Future<void> _loadSpriteSheet() async {
    if (_cachedSpriteSheet != null || _isGenerating) return;

    _isGenerating = true;

    // CRITICAL: Use integer cell height for pixel-perfect alignment
    final h = widget.cellHeight;

    // Generate sprite sheet with all digits 0-9
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // CRITICAL: Fill background with transparent (will be replaced by Paint)
    // The sprite sheet must have opaque text on transparent background
    final backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widget.width.toDouble(), (h * 10).toDouble()),
      backgroundPaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw each digit into the sprite sheet - properly centered
    for (int i = 0; i < 10; i++) {
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace', // Consistent width
          color: widget.textColor,
          height: 1.0, // Prevent extra line spacing
        ),
      );
      // CRITICAL: Deterministic rendering (no scaling)
      textPainter.textScaler = TextScaler.noScaling;
      textPainter.layout(minWidth: 0, maxWidth: widget.width.toDouble());

      // Center the digit both horizontally and vertically in its slot
      final xOffset = (widget.width - textPainter.width) / 2;
      final yOffset = (i * h) + ((h - textPainter.height) / 2);

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }

    final picture = recorder.endRecording();
    _cachedSpriteSheet = await picture.toImage(
      widget.width,
      h * 10,
    );

    _isGenerating = false;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SpriteDigitRoller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newTarget = int.tryParse(widget.digit) ?? 0;

    // Target digit changed
    if (newTarget != _targetDigit) {
      _targetDigit = newTarget;
    }

    // Spinning state changed
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _startSpinning();
      } else {
        _stopSpinning();
      }
    }
  }

  /// Starts autonomous spinning through random digits
  void _startSpinning() {
    _isStopping = false;
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(
      const Duration(milliseconds: _spinIntervalMs),
      (_) => _spinToNextDigit(),
    );
  }

  /// Stops spinning and snaps to target digit
  void _stopSpinning() {
    _isStopping = true;
    _spinTimer?.cancel();
    _spinTimer = null;

    // Snap to target after a brief delay
    Future.delayed(const Duration(milliseconds: _finalSpinDelayMs), () {
      if (mounted && _currentDigit != _targetDigit) {
        _animateToDigit(_targetDigit);
      }
    });
  }

  /// Spins to next random digit (creates spinning effect)
  void _spinToNextDigit() {
    // Guard: Don't spin if we're stopping or already animating
    if (!mounted || _isStopping || _slideController.isAnimating) return;

    final nextDigit = (_currentDigit + 1) % 10;
    _animateToDigit(nextDigit);
  }

  /// Animates transition to a specific digit
  void _animateToDigit(int digit) {
    // Guard: Prevent animation overlap
    if (!mounted || _slideController.isAnimating) return;

    _previousDigit = _currentDigit;
    _currentDigit = digit;
    _slideController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedSpriteSheet == null) {
      // Show placeholder while loading
      return SizedBox(
        width: widget.width.toDouble(),
        height: widget.cellHeight.toDouble(),
        child: Center(
          child: Text(
            widget.digit,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width.toDouble(),
        height: widget.cellHeight.toDouble(),
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return CustomPaint(
              painter: _SpriteDigitPainter(
                spriteSheet: _cachedSpriteSheet!,
                previousDigit: _previousDigit,
                currentDigit: _currentDigit,
                slideProgress: _slideController.value,
                isSpinning: widget.isSpinning,
                digitHeight: widget.cellHeight,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter that performs ultra-fast GPU texture blitting
class _SpriteDigitPainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int previousDigit;
  final int currentDigit;
  final double slideProgress;
  final bool isSpinning;
  final int digitHeight; // CRITICAL: Integer for pixel-perfect alignment

  _SpriteDigitPainter({
    required this.spriteSheet,
    required this.previousDigit,
    required this.currentDigit,
    required this.slideProgress,
    required this.isSpinning,
    required this.digitHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    // CRITICAL: Use integer digitHeight for pixel-perfect calculations
    final slideOffset = slideProgress * digitHeight;

    // Clip to prevent overflow
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (slideProgress > 0.0 && slideProgress < 1.0) {
      // During transition: show previous digit sliding out
      final prevSrcY = (previousDigit * digitHeight).toDouble();
      final prevSrcRect = Rect.fromLTWH(
        0,
        prevSrcY,
        spriteSheet.width.toDouble(),
        digitHeight.toDouble(),
      );
      // CRITICAL: Map to visible area (0,0 to size)
      final prevDstRect = Rect.fromLTWH(
        0,
        -slideOffset,
        size.width,
        digitHeight.toDouble(),
      );
      canvas.drawImageRect(spriteSheet, prevSrcRect, prevDstRect, paint);

      // Show current digit sliding in from below
      final currSrcY = (currentDigit * digitHeight).toDouble();
      final currSrcRect = Rect.fromLTWH(
        0,
        currSrcY,
        spriteSheet.width.toDouble(),
        digitHeight.toDouble(),
      );
      final currDstRect = Rect.fromLTWH(
        0,
        digitHeight - slideOffset,
        size.width,
        digitHeight.toDouble(),
      );
      canvas.drawImageRect(spriteSheet, currSrcRect, currDstRect, paint);
    } else {
      // Static: just show current digit - no transparency, pixel-perfect alignment
      final srcY = (currentDigit * digitHeight).toDouble();
      final srcRect = Rect.fromLTWH(
        0,
        srcY,
        spriteSheet.width.toDouble(),
        digitHeight.toDouble(),
      );
      // CRITICAL: Destination must exactly match widget size
      final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(spriteSheet, srcRect, dstRect, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpriteDigitPainter oldDelegate) {
    return currentDigit != oldDelegate.currentDigit ||
        slideProgress != oldDelegate.slideProgress ||
        isSpinning != oldDelegate.isSpinning;
  }
}

/// Sprite-based letter roller (A-Z)
class SpriteLetterRoller extends StatefulWidget {
  final String letter;
  final bool isSpinning;
  final int width;
  final int cellHeight; // CRITICAL: Must be integer for pixel-perfect alignment
  final Color textColor;
  final double fontSize;

  const SpriteLetterRoller({
    super.key,
    required this.letter,
    required this.isSpinning,
    required this.width,
    required this.cellHeight,
    required this.textColor,
    this.fontSize = 24,
  });

  @override
  State<SpriteLetterRoller> createState() => _SpriteLetterRollerState();
}

class _SpriteLetterRollerState extends State<SpriteLetterRoller>
    with SingleTickerProviderStateMixin {
  static ui.Image? _cachedSpriteSheet;
  static bool _isGenerating = false;
  static const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  late AnimationController _slideController;
  int _previousLetterIndex = 0;
  int _currentLetterIndex = 0;
  int _targetLetterIndex = 0;
  Timer? _spinTimer;
  bool _isStopping = false; // Guard flag to prevent race conditions
  static const _spinIntervalMs = 80; // Fast spinning speed
  static const _finalSpinDelayMs = 150; // Delay before final snap

  @override
  void initState() {
    super.initState();
    _currentLetterIndex = alphabet.indexOf(widget.letter.toUpperCase());
    if (_currentLetterIndex == -1) _currentLetterIndex = 0;
    _targetLetterIndex = _currentLetterIndex;
    _previousLetterIndex = _currentLetterIndex;

    // CRITICAL: Duration must be < spinIntervalMs to prevent overlap
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70), // 70ms < 80ms interval
    );

    // CRITICAL: Snap to final position when animation completes
    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset to static state with current letter properly aligned
        _previousLetterIndex = _currentLetterIndex;
        _slideController.value = 0.0;
        if (mounted) setState(() {});
      }
    });

    _loadSpriteSheet();
  }

  Future<void> _loadSpriteSheet() async {
    if (_cachedSpriteSheet != null || _isGenerating) return;

    _isGenerating = true;

    // CRITICAL: Use integer cell height for pixel-perfect alignment
    final h = widget.cellHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // CRITICAL: Fill background with transparent (will be replaced by Paint)
    // The sprite sheet must have opaque text on transparent background
    final backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widget.width.toDouble(), (h * 26).toDouble()),
      backgroundPaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < alphabet.length; i++) {
      textPainter.text = TextSpan(
        text: alphabet[i],
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace', // Consistent width
          color: widget.textColor,
          height: 1.0, // Prevent extra line spacing
        ),
      );
      // CRITICAL: Deterministic rendering (no scaling)
      textPainter.textScaler = TextScaler.noScaling;
      textPainter.layout(minWidth: 0, maxWidth: widget.width.toDouble());

      // Center the letter both horizontally and vertically in its slot
      final xOffset = (widget.width - textPainter.width) / 2;
      final yOffset = (i * h) + ((h - textPainter.height) / 2);

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }

    final picture = recorder.endRecording();
    _cachedSpriteSheet = await picture.toImage(
      widget.width,
      h * 26,
    );

    _isGenerating = false;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SpriteLetterRoller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newTargetIndex = alphabet.indexOf(widget.letter.toUpperCase());
    final validTargetIndex = newTargetIndex == -1 ? 0 : newTargetIndex;

    // Target letter changed
    if (validTargetIndex != _targetLetterIndex) {
      _targetLetterIndex = validTargetIndex;
    }

    // Spinning state changed
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _startSpinning();
      } else {
        _stopSpinning();
      }
    }
  }

  /// Starts autonomous spinning through letters
  void _startSpinning() {
    _isStopping = false;
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(
      const Duration(milliseconds: _spinIntervalMs),
      (_) => _spinToNextLetter(),
    );
  }

  /// Stops spinning and snaps to target letter
  void _stopSpinning() {
    _isStopping = true;
    _spinTimer?.cancel();
    _spinTimer = null;

    // Snap to target after a brief delay
    Future.delayed(const Duration(milliseconds: _finalSpinDelayMs), () {
      if (mounted && _currentLetterIndex != _targetLetterIndex) {
        debugPrint('Snapping to target letter: ${alphabet[_targetLetterIndex]} (current: ${alphabet[_currentLetterIndex]})');
        _animateToLetter(_targetLetterIndex);
      }
    });
  }

  /// Spins to next letter (creates spinning effect)
  void _spinToNextLetter() {
    // Guard: Don't spin if we're stopping or already animating
    if (!mounted || _isStopping || _slideController.isAnimating) return;

    final nextLetterIndex = (_currentLetterIndex + 1) % alphabet.length;
    _animateToLetter(nextLetterIndex);
  }

  /// Animates transition to a specific letter
  void _animateToLetter(int letterIndex) {
    // Guard: Prevent animation overlap
    if (!mounted || _slideController.isAnimating) return;

    _previousLetterIndex = _currentLetterIndex;
    _currentLetterIndex = letterIndex;
    _slideController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedSpriteSheet == null) {
      return SizedBox(
        width: widget.width.toDouble(),
        height: widget.cellHeight.toDouble(),
        child: Center(
          child: Text(
            widget.letter,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              color: widget.textColor,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width.toDouble(),
        height: widget.cellHeight.toDouble(),
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return CustomPaint(
              painter: _SpriteLetterPainter(
                spriteSheet: _cachedSpriteSheet!,
                previousLetterIndex: _previousLetterIndex,
                currentLetterIndex: _currentLetterIndex,
                slideProgress: _slideController.value,
                isSpinning: widget.isSpinning,
                letterHeight: widget.cellHeight,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpriteLetterPainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int previousLetterIndex;
  final int currentLetterIndex;
  final double slideProgress;
  final bool isSpinning;
  final int letterHeight; // CRITICAL: Integer for pixel-perfect alignment

  _SpriteLetterPainter({
    required this.spriteSheet,
    required this.previousLetterIndex,
    required this.currentLetterIndex,
    required this.slideProgress,
    required this.isSpinning,
    required this.letterHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    // CRITICAL: Use integer letterHeight for pixel-perfect calculations
    final slideOffset = slideProgress * letterHeight;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (slideProgress > 0.0 && slideProgress < 1.0) {
      // Previous letter sliding out
      final prevSrcY = (previousLetterIndex * letterHeight).toDouble();
      final prevSrcRect = Rect.fromLTWH(
        0,
        prevSrcY,
        spriteSheet.width.toDouble(),
        letterHeight.toDouble(),
      );
      // CRITICAL: Map to visible area (0,0 to size)
      final prevDstRect = Rect.fromLTWH(
        0,
        -slideOffset,
        size.width,
        letterHeight.toDouble(),
      );
      canvas.drawImageRect(spriteSheet, prevSrcRect, prevDstRect, paint);

      // Current letter sliding in
      final currSrcY = (currentLetterIndex * letterHeight).toDouble();
      final currSrcRect = Rect.fromLTWH(
        0,
        currSrcY,
        spriteSheet.width.toDouble(),
        letterHeight.toDouble(),
      );
      final currDstRect = Rect.fromLTWH(
        0,
        letterHeight - slideOffset,
        size.width,
        letterHeight.toDouble(),
      );
      canvas.drawImageRect(spriteSheet, currSrcRect, currDstRect, paint);
    } else {
      // Static: just show current letter - no transparency, pixel-perfect alignment
      final srcY = (currentLetterIndex * letterHeight).toDouble();
      final srcRect = Rect.fromLTWH(
        0,
        srcY,
        spriteSheet.width.toDouble(),
        letterHeight.toDouble(),
      );
      // CRITICAL: Destination must exactly match widget size
      final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(spriteSheet, srcRect, dstRect, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpriteLetterPainter oldDelegate) {
    return currentLetterIndex != oldDelegate.currentLetterIndex ||
        slideProgress != oldDelegate.slideProgress ||
        isSpinning != oldDelegate.isSpinning;
  }
}
