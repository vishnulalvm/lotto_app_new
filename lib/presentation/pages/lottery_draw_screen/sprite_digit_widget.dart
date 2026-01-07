import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Ultra-high-performance sprite-based digit roller
/// VERSION 3: GUARANTEED pixel-perfect snapping
/// 
/// The key insight: When not spinning, scrollPosition MUST be an exact integer.
/// During spin: fractional positions are fine (shows motion blur effect)
/// After spin: IMMEDIATELY snap to integer, then animate TO target integer
class SpriteDigitRoller extends StatefulWidget {
  final String digit;
  final bool isSpinning;
  final int width;
  final int cellHeight;
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
  
  // Sprite sheet cache
  static final Map<String, ui.Image> _spriteCache = {};
  static final Set<String> _generating = {};

  // Animation
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;
  
  // State
  int _displayDigit = 0;        // Currently displayed digit (always integer!)
  int _targetDigit = 0;         // Target digit to reach
  int _previousDigit = 0;       // Previous digit (for transition)
  double _transitionProgress = 0.0; // 0.0 = showing _previousDigit, 1.0 = showing _displayDigit
  
  // Spinning
  Timer? _spinTimer;
  bool _isCurrentlySpinning = false;

  String get _cacheKey => 'digit_${widget.width}_${widget.cellHeight}_${widget.fontSize}_${widget.textColor.value}';

  @override
  void initState() {
    super.initState();
    
    _targetDigit = int.tryParse(widget.digit) ?? 0;
    _displayDigit = _targetDigit;
    _previousDigit = _targetDigit;
    _transitionProgress = 0.0; // Static - showing _displayDigit at position 0
    
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    
    _generateSpriteSheet();
    
    if (widget.isSpinning) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startSpinning();
      });
    }
  }

  Future<void> _generateSpriteSheet() async {
    final key = _cacheKey;
    if (_spriteCache.containsKey(key) || _generating.contains(key)) {
      if (mounted) setState(() {});
      return;
    }

    _generating.add(key);

    final h = widget.cellHeight;
    final w = widget.width;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw digits 0-9
    for (int i = 0; i < 10; i++) {
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: widget.textColor,
          height: 1.0,
        ),
      );
      textPainter.textScaler = TextScaler.noScaling;
      textPainter.layout(minWidth: 0, maxWidth: w.toDouble());

      final xOffset = (w - textPainter.width) / 2;
      final yOffset = (i * h) + ((h - textPainter.height) / 2);

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h * 10);
    
    _spriteCache[key] = image;
    _generating.remove(key);
    
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SpriteDigitRoller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newTarget = int.tryParse(widget.digit) ?? 0;
    if (newTarget != _targetDigit) {
      _targetDigit = newTarget;
    }

    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _startSpinning();
      } else {
        _stopSpinning();
      }
    }
  }

  void _startSpinning() {
    if (_isCurrentlySpinning) return;
    _isCurrentlySpinning = true;
    
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) => _spinStep(),
    );
  }

  void _spinStep() {
    if (!mounted || !_isCurrentlySpinning) return;
    
    // Move to next digit
    _previousDigit = _displayDigit;
    _displayDigit = (_displayDigit + 1) % 10;
    
    // Animate the transition
    _transitionProgress = 0.0;
    _snapController.duration = const Duration(milliseconds: 60);
    _snapController.forward(from: 0.0);
    
    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.linear),
    );
    
    _snapAnimation!.addListener(_onTransitionTick);
    _snapController.forward(from: 0.0).then((_) {
      _snapAnimation?.removeListener(_onTransitionTick);
      if (mounted) {
        setState(() {
          _transitionProgress = 0.0; // Reset - now showing _displayDigit statically
          _previousDigit = _displayDigit;
        });
      }
    });
  }

  void _onTransitionTick() {
    if (mounted && _snapAnimation != null) {
      setState(() {
        _transitionProgress = _snapAnimation!.value;
      });
    }
  }

  void _stopSpinning() {
    _isCurrentlySpinning = false;
    _spinTimer?.cancel();
    _spinTimer = null;
    
    // Stop any in-progress animation
    _snapController.stop();
    _snapAnimation?.removeListener(_onTransitionTick);
    
    // CRITICAL: Immediately snap to current integer position
    setState(() {
      _transitionProgress = 0.0;
      _previousDigit = _displayDigit;
    });
    
    // Now animate from current position to target
    _animateToTarget();
  }

  void _animateToTarget() {
    if (!mounted) return;
    if (_displayDigit == _targetDigit) return; // Already at target
    
    // Calculate steps needed (shortest path around the wheel)
    int steps = _targetDigit - _displayDigit;
    if (steps < 0) steps += 10;
    if (steps > 5) steps = steps - 10; // Go backwards if shorter
    
    // Animate step by step to target
    _animateSteps(steps.abs(), steps > 0);
  }

  void _animateSteps(int stepsRemaining, bool forward) {
    if (!mounted || stepsRemaining == 0) return;
    
    _previousDigit = _displayDigit;
    _displayDigit = forward 
        ? (_displayDigit + 1) % 10 
        : (_displayDigit - 1 + 10) % 10;
    
    _snapController.duration = const Duration(milliseconds: 100);
    
    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    
    void listener() {
      if (mounted) {
        setState(() {
          _transitionProgress = _snapAnimation!.value;
        });
      }
    }
    
    _snapAnimation!.addListener(listener);
    _snapController.forward(from: 0.0).then((_) {
      _snapAnimation?.removeListener(listener);
      if (mounted) {
        setState(() {
          _transitionProgress = 0.0;
          _previousDigit = _displayDigit;
        });
        // Continue to next step
        _animateSteps(stepsRemaining - 1, forward);
      }
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _snapAnimation?.removeListener(_onTransitionTick);
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sprite = _spriteCache[_cacheKey];
    
    if (sprite == null) {
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
        child: CustomPaint(
          painter: _DigitPainterV3(
            spriteSheet: sprite,
            previousDigit: _previousDigit,
            currentDigit: _displayDigit,
            transitionProgress: _transitionProgress,
            cellHeight: widget.cellHeight,
          ),
          size: Size(widget.width.toDouble(), widget.cellHeight.toDouble()),
        ),
      ),
    );
  }
}

class _DigitPainterV3 extends CustomPainter {
  final ui.Image spriteSheet;
  final int previousDigit;
  final int currentDigit;
  final double transitionProgress; // 0.0 = show previous, 1.0 = show current
  final int cellHeight;

  _DigitPainterV3({
    required this.spriteSheet,
    required this.previousDigit,
    required this.currentDigit,
    required this.transitionProgress,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none // Pixel-perfect, no interpolation
      ..isAntiAlias = false;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // CRITICAL: Only show transition if progress is meaningfully > 0
    // This prevents any "in-between" rendering
    if (transitionProgress < 0.01) {
      // Static: show previous digit perfectly centered
      _drawDigit(canvas, size, paint, previousDigit, 0.0);
    } else if (transitionProgress > 0.99) {
      // Static: show current digit perfectly centered  
      _drawDigit(canvas, size, paint, currentDigit, 0.0);
    } else {
      // Transitioning: show both digits sliding
      final offset = transitionProgress * cellHeight;
      
      // Previous digit sliding up/out
      _drawDigit(canvas, size, paint, previousDigit, -offset);
      
      // Current digit sliding in from below
      _drawDigit(canvas, size, paint, currentDigit, cellHeight - offset);
    }

    canvas.restore();
  }

  void _drawDigit(Canvas canvas, Size size, Paint paint, int digit, double yOffset) {
    final srcY = (digit * cellHeight).toDouble();
    final srcRect = Rect.fromLTWH(
      0,
      srcY,
      spriteSheet.width.toDouble(),
      cellHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      0,
      yOffset,
      size.width,
      cellHeight.toDouble(),
    );
    canvas.drawImageRect(spriteSheet, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_DigitPainterV3 oldDelegate) {
    return previousDigit != oldDelegate.previousDigit ||
        currentDigit != oldDelegate.currentDigit ||
        transitionProgress != oldDelegate.transitionProgress;
  }
}


/// Sprite-based letter roller (A-Z) - VERSION 3
class SpriteLetterRoller extends StatefulWidget {
  final String letter;
  final bool isSpinning;
  final int width;
  final int cellHeight;
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
  
  static const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  
  static final Map<String, ui.Image> _spriteCache = {};
  static final Set<String> _generating = {};

  late AnimationController _snapController;
  Animation<double>? _snapAnimation;
  
  int _displayIndex = 0;
  int _targetIndex = 0;
  int _previousIndex = 0;
  double _transitionProgress = 0.0;
  
  Timer? _spinTimer;
  bool _isCurrentlySpinning = false;

  String get _cacheKey => 'letter_${widget.width}_${widget.cellHeight}_${widget.fontSize}_${widget.textColor.value}';

  @override
  void initState() {
    super.initState();
    
    _targetIndex = alphabet.indexOf(widget.letter.toUpperCase());
    if (_targetIndex == -1) _targetIndex = 0;
    _displayIndex = _targetIndex;
    _previousIndex = _targetIndex;
    _transitionProgress = 0.0;
    
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    
    _generateSpriteSheet();
    
    if (widget.isSpinning) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startSpinning();
      });
    }
  }

  Future<void> _generateSpriteSheet() async {
    final key = _cacheKey;
    if (_spriteCache.containsKey(key) || _generating.contains(key)) {
      if (mounted) setState(() {});
      return;
    }

    _generating.add(key);

    final h = widget.cellHeight;
    final w = widget.width;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

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
          fontFamily: 'monospace',
          color: widget.textColor,
          height: 1.0,
        ),
      );
      textPainter.textScaler = TextScaler.noScaling;
      textPainter.layout(minWidth: 0, maxWidth: w.toDouble());

      final xOffset = (w - textPainter.width) / 2;
      final yOffset = (i * h) + ((h - textPainter.height) / 2);

      textPainter.paint(canvas, Offset(xOffset, yOffset));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h * alphabet.length);
    
    _spriteCache[key] = image;
    _generating.remove(key);
    
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SpriteLetterRoller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newTargetIndex = alphabet.indexOf(widget.letter.toUpperCase());
    final validTarget = newTargetIndex == -1 ? 0 : newTargetIndex;
    
    if (validTarget != _targetIndex) {
      _targetIndex = validTarget;
    }

    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _startSpinning();
      } else {
        _stopSpinning();
      }
    }
  }

  void _startSpinning() {
    if (_isCurrentlySpinning) return;
    _isCurrentlySpinning = true;
    
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) => _spinStep(),
    );
  }

  void _spinStep() {
    if (!mounted || !_isCurrentlySpinning) return;
    
    _previousIndex = _displayIndex;
    _displayIndex = (_displayIndex + 1) % 26;
    
    _transitionProgress = 0.0;
    _snapController.duration = const Duration(milliseconds: 60);
    
    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.linear),
    );
    
    _snapAnimation!.addListener(_onTransitionTick);
    _snapController.forward(from: 0.0).then((_) {
      _snapAnimation?.removeListener(_onTransitionTick);
      if (mounted) {
        setState(() {
          _transitionProgress = 0.0;
          _previousIndex = _displayIndex;
        });
      }
    });
  }

  void _onTransitionTick() {
    if (mounted && _snapAnimation != null) {
      setState(() {
        _transitionProgress = _snapAnimation!.value;
      });
    }
  }

  void _stopSpinning() {
    _isCurrentlySpinning = false;
    _spinTimer?.cancel();
    _spinTimer = null;
    
    _snapController.stop();
    _snapAnimation?.removeListener(_onTransitionTick);
    
    setState(() {
      _transitionProgress = 0.0;
      _previousIndex = _displayIndex;
    });
    
    _animateToTarget();
  }

  void _animateToTarget() {
    if (!mounted) return;
    if (_displayIndex == _targetIndex) return;
    
    int steps = _targetIndex - _displayIndex;
    if (steps < 0) steps += 26;
    if (steps > 13) steps = steps - 26;
    
    _animateSteps(steps.abs(), steps > 0);
  }

  void _animateSteps(int stepsRemaining, bool forward) {
    if (!mounted || stepsRemaining == 0) return;
    
    _previousIndex = _displayIndex;
    _displayIndex = forward 
        ? (_displayIndex + 1) % 26 
        : (_displayIndex - 1 + 26) % 26;
    
    _snapController.duration = const Duration(milliseconds: 100);
    
    _snapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    
    void listener() {
      if (mounted) {
        setState(() {
          _transitionProgress = _snapAnimation!.value;
        });
      }
    }
    
    _snapAnimation!.addListener(listener);
    _snapController.forward(from: 0.0).then((_) {
      _snapAnimation?.removeListener(listener);
      if (mounted) {
        setState(() {
          _transitionProgress = 0.0;
          _previousIndex = _displayIndex;
        });
        _animateSteps(stepsRemaining - 1, forward);
      }
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _snapAnimation?.removeListener(_onTransitionTick);
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sprite = _spriteCache[_cacheKey];
    
    if (sprite == null) {
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
        child: CustomPaint(
          painter: _LetterPainterV3(
            spriteSheet: sprite,
            previousIndex: _previousIndex,
            currentIndex: _displayIndex,
            transitionProgress: _transitionProgress,
            cellHeight: widget.cellHeight,
          ),
          size: Size(widget.width.toDouble(), widget.cellHeight.toDouble()),
        ),
      ),
    );
  }
}

class _LetterPainterV3 extends CustomPainter {
  final ui.Image spriteSheet;
  final int previousIndex;
  final int currentIndex;
  final double transitionProgress;
  final int cellHeight;

  _LetterPainterV3({
    required this.spriteSheet,
    required this.previousIndex,
    required this.currentIndex,
    required this.transitionProgress,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (transitionProgress < 0.01) {
      _drawLetter(canvas, size, paint, previousIndex, 0.0);
    } else if (transitionProgress > 0.99) {
      _drawLetter(canvas, size, paint, currentIndex, 0.0);
    } else {
      final offset = transitionProgress * cellHeight;
      _drawLetter(canvas, size, paint, previousIndex, -offset);
      _drawLetter(canvas, size, paint, currentIndex, cellHeight - offset);
    }

    canvas.restore();
  }

  void _drawLetter(Canvas canvas, Size size, Paint paint, int index, double yOffset) {
    final srcY = (index * cellHeight).toDouble();
    final srcRect = Rect.fromLTWH(
      0,
      srcY,
      spriteSheet.width.toDouble(),
      cellHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      0,
      yOffset,
      size.width,
      cellHeight.toDouble(),
    );
    canvas.drawImageRect(spriteSheet, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_LetterPainterV3 oldDelegate) {
    return previousIndex != oldDelegate.previousIndex ||
        currentIndex != oldDelegate.currentIndex ||
        transitionProgress != oldDelegate.transitionProgress;
  }
}