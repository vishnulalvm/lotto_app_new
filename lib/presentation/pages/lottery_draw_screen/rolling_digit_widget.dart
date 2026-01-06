import 'package:flutter/material.dart';

/// Slot machine digit widget using ListWheelScrollView for authentic reel effect
class RollingDigit extends StatefulWidget {
  final String digit;
  final bool isSpinning;
  final TextStyle style;
  final Duration duration;

  const RollingDigit({
    super.key,
    required this.digit,
    required this.isSpinning,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<RollingDigit> {
  late FixedExtentScrollController _controller;
  int _counter = 0; // Internal counter to keep the wheel moving forward

  @override
  void initState() {
    super.initState();
    _counter = int.tryParse(widget.digit) ?? 0;
    _controller = FixedExtentScrollController(initialItem: _counter);
  }

  @override
  void didUpdateWidget(RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSpinning && widget.digit != oldWidget.digit) {
      // Move 3 positions per tick for faster visual spinning
      // This prevents animation queue collision where animations are cancelled
      // before completing when tick rate is close to animation duration
      _counter += 3;
      _controller.animateToItem(
        _counter,
        duration: widget.duration,
        curve: Curves.linear, // Smooth linear motion during spinning
      );
    } else if (oldWidget.isSpinning && !widget.isSpinning) {
      // STOPPING: Transition from spinning to still.
      // Snap to the actual target digit provided by the Cubit.
      _snapToTarget();
    }
  }

  void _snapToTarget() {
    final targetDigit = int.tryParse(widget.digit) ?? 0;
    final currentPos = _controller.selectedItem;

    // Calculate distance to the next occurrence of that digit
    int diff = (targetDigit - (currentPos % 10) + 10) % 10;
    if (diff == 0) diff = 10; // Force one last spin for impact

    _controller.animateToItem(
      currentPos + diff,
      duration: widget.duration,
      curve: Curves.easeOutBack, // THE MECHANICAL "CLICK" PHYSICS
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: (widget.style.fontSize ?? 24) * 1.5,
        width: (widget.style.fontSize ?? 24) * 0.8,
        child: Stack(
          children: [
            // The spinning reel - with cacheExtent to reduce raster overhead
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: (widget.style.fontSize ?? 24) * 1.2,
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.005,
              diameterRatio: 1.2,
              renderChildrenOutsideViewport:
                  false, // Don't render off-screen items
              clipBehavior: Clip.hardEdge, // More efficient clipping
              childDelegate: ListWheelChildLoopingListDelegate(
                children: List.generate(
                  10,
                  (i) => Center(
                    child: Text(
                      '$i',
                      style: widget.style.copyWith(
                        // Motion blur simulation: fade slightly while spinning
                        color: widget.style.color?.withValues(
                          alpha: widget.isSpinning ? 0.6 : 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Simplified overlay - removed gradient to reduce raster cost
            if (!widget.isSpinning) // Only show overlay when stopped
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rolling letter widget using ListWheelScrollView with the same approach as RollingDigit
class RollingLetter extends StatefulWidget {
  final String letter;
  final bool isSpinning;
  final TextStyle style;
  final Duration duration;

  const RollingLetter({
    super.key,
    required this.letter,
    required this.isSpinning,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<RollingLetter> createState() => _RollingLetterState();
}

class _RollingLetterState extends State<RollingLetter> {
  late FixedExtentScrollController _controller;
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _counter = _alphabet.indexOf(widget.letter);
    if (_counter == -1) _counter = 0;
    _controller = FixedExtentScrollController(initialItem: _counter);
  }

  @override
  void didUpdateWidget(RollingLetter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSpinning && widget.letter != oldWidget.letter) {
      // Move 3 positions per tick for faster visual spinning
      // This prevents animation queue collision where animations are cancelled
      // before completing when tick rate is close to animation duration
      _counter += 3;
      _controller.animateToItem(
        _counter,
        duration: widget.duration,
        curve: Curves.linear, // Smooth linear motion during spinning
      );
    } else if (oldWidget.isSpinning && !widget.isSpinning) {
      // STOPPING: Transition from spinning to still.
      // Snap to the actual target letter provided by the Cubit.
      _snapToTarget();
    }
  }

  void _snapToTarget() {
    final targetIdx = _alphabet.indexOf(widget.letter);
    final currentPos = _controller.selectedItem;

    // Calculate distance to the next occurrence of that letter
    int diff = (targetIdx - (currentPos % 26) + 26) % 26;
    if (diff == 0) diff = 26; // Force one last spin for impact

    _controller.animateToItem(
      currentPos + diff,
      duration: widget.duration,
      curve: Curves.easeOutBack, // THE MECHANICAL "CLICK" PHYSICS
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: (widget.style.fontSize ?? 24) * 1.5,
        width: (widget.style.fontSize ?? 24) * 0.8,
        child: Stack(
          children: [
            // The spinning reel - with optimizations to reduce raster overhead
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: (widget.style.fontSize ?? 24) * 1.2,
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.005,
              diameterRatio: 1.2,
              renderChildrenOutsideViewport:
                  false, // Don't render off-screen items
              clipBehavior: Clip.hardEdge, // More efficient clipping
              childDelegate: ListWheelChildLoopingListDelegate(
                children: _alphabet
                    .map(
                      (l) => Center(
                        child: Text(
                          l,
                          style: widget.style.copyWith(
                            // Motion blur simulation: fade slightly while spinning
                            color: widget.style.color?.withValues(
                              alpha: widget.isSpinning ? 0.6 : 1.0,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Simplified overlay - only show when stopped to reduce raster cost
            if (!widget.isSpinning)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
