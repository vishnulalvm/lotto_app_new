import 'package:flutter/material.dart';

/// Slot machine digit widget using ListWheelScrollView for authentic reel effect
class RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;
  final Duration duration;

  const RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    this.duration = const Duration(milliseconds: 600), // Pro tip: 600ms feels more "weighted"
  });

  @override
  State<RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<RollingDigit> {
  late FixedExtentScrollController _controller;
  final List<int> _digits = List.generate(10, (i) => i);

  @override
  void initState() {
    super.initState();
    final initialDigit = int.parse(widget.digit);
    _controller = FixedExtentScrollController(initialItem: initialDigit);
    print('[RollingDigit] initState - initialDigit: $initialDigit');
  }

  @override
  void didUpdateWidget(RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      print('[RollingDigit] didUpdateWidget - oldDigit: ${oldWidget.digit}, newDigit: ${widget.digit}');
      _animateToValue();
    }
  }

  void _animateToValue() {
    final int target = int.parse(widget.digit);
    final int currentItem = _controller.selectedItem;

    // Logic: Find the next occurrence of the digit in the loop to ensure it always rolls forward
    int diff = (target - (currentItem % 10) + 10) % 10;
    if (diff == 0) diff = 10; // Force a full spin if the number is the same

    final targetItem = currentItem + diff;

    print('[RollingDigit] _animateToValue - target: $target, currentItem: $currentItem, diff: $diff, targetItem: $targetItem, duration: ${widget.duration.inMilliseconds}ms');

    // Use animateToItem with easeOutBack curve for realistic slot machine physics
    // The overshoot creates that satisfying "click into place" effect
    if (_controller.hasClients) {
      _controller.animateToItem(
        targetItem,
        duration: widget.duration,
        curve: Curves.easeOutBack, // Mimics physical inertia with slight overshoot
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (widget.style.fontSize ?? 24) * 1.5,
      width: (widget.style.fontSize ?? 24) * 0.8,
      child: Stack(
        children: [
          // The spinning reel
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: (widget.style.fontSize ?? 24) * 1.2,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.005, // Adds subtle 3D curve
            diameterRatio: 1.2, // Smaller drum = more aggressive curve (slot machine aesthetic)
            childDelegate: ListWheelChildLoopingListDelegate(
              children: _digits.map((d) => Center(child: Text('$d', style: widget.style))).toList(),
            ),
          ),
          // Gradient overlay for depth effect (top/bottom shadows)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3), // Top shadow (numbers emerging from darkness)
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2), // Bottom shadow (numbers disappearing)
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rolling letter widget using ListWheelScrollView with the same approach as RollingDigit
class RollingLetter extends StatefulWidget {
  final String letter;
  final TextStyle style;
  final Duration duration;

  const RollingLetter({
    super.key,
    required this.letter,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<RollingLetter> createState() => _RollingLetterState();
}

class _RollingLetterState extends State<RollingLetter> {
  late FixedExtentScrollController _controller;
  static const String _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  late final List<String> _lettersList;

  @override
  void initState() {
    super.initState();
    _lettersList = _letters.split('');
    final initialIndex = _letters.indexOf(widget.letter);
    _controller = FixedExtentScrollController(initialItem: initialIndex >= 0 ? initialIndex : 0);
  }

  @override
  void didUpdateWidget(RollingLetter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) {
      _animateToValue();
    }
  }

  void _animateToValue() {
    final int target = _letters.indexOf(widget.letter);
    if (target < 0) return; // Invalid letter

    final int currentItem = _controller.selectedItem;

    // Logic: Find the next occurrence of the letter in the loop to ensure it always rolls forward
    int diff = (target - (currentItem % 26) + 26) % 26;
    if (diff == 0) diff = 26; // Force a full spin if the letter is the same

    final targetItem = currentItem + diff;

    // Use animateToItem with easeOutBack curve for realistic slot machine physics
    // The overshoot creates that satisfying "click into place" effect
    if (_controller.hasClients) {
      _controller.animateToItem(
        targetItem,
        duration: widget.duration,
        curve: Curves.easeOutBack, // Mimics physical inertia with slight overshoot
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (widget.style.fontSize ?? 24) * 1.5,
      width: (widget.style.fontSize ?? 24) * 0.8,
      child: Stack(
        children: [
          // The spinning reel
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: (widget.style.fontSize ?? 24) * 1.2,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.005, // Adds subtle 3D curve
            diameterRatio: 1.2, // Smaller drum = more aggressive curve (slot machine aesthetic)
            childDelegate: ListWheelChildLoopingListDelegate(
              children: _lettersList.map((l) => Center(child: Text(l, style: widget.style))).toList(),
            ),
          ),
          // Gradient overlay for depth effect (top/bottom shadows)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3), // Top shadow (numbers emerging from darkness)
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2), // Bottom shadow (numbers disappearing)
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}