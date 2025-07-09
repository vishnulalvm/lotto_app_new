import 'package:flutter/material.dart';

class RepeatedNumberCard extends StatefulWidget {
  final String number;
  final ThemeData theme;
  final Duration delay;
  final double fontSize;

  const RepeatedNumberCard({
    super.key,
    required this.number,
    required this.theme,
    required this.delay,
    required this.fontSize,
  });

  @override
  State<RepeatedNumberCard> createState() => _RepeatedNumberCardState();
}

class _RepeatedNumberCardState extends State<RepeatedNumberCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.number.length * 100),
      vsync: this,
    );

    _characterCount = StepTween(
      begin: 0,
      end: widget.number.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.8),
              Colors.orange[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Rank badge

            // Number display
            Center(
              child: AnimatedBuilder(
                animation: _characterCount,
                builder: (context, child) {
                  String displayText =
                      widget.number.substring(0, _characterCount.value);
                  bool showCursor = _controller.isAnimating &&
                      _characterCount.value < widget.number.length;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayText,
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.fontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (showCursor)
                        AnimatedOpacity(
                          opacity:
                              (_controller.value * 2) % 1 > 0.5 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 100),
                          child: Text(
                            '|',
                            style: widget.theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.fontSize,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
