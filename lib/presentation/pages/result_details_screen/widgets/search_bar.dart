import 'package:flutter/material.dart';

class FloatingSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final double bottomPadding;

  const FloatingSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.bottomPadding = 20.0,
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final backgroundColor = theme.primaryColor;
    final onBackgroundColor = Colors.white;
    final shadowColor = isDarkMode
        ? backgroundColor.withValues(alpha: 0.4)
        : backgroundColor.withValues(alpha: 0.3);

    final maxExpandedWidth = screenWidth - 32.0; // 16px padding on each side
    final expandedWidth = _isExpanded
        ? (maxExpandedWidth > 400.0 ? 400.0 : maxExpandedWidth)
        : 56.0;

    // only animate on collapse to avoid intermediate overflow
    final animationDuration =
        _isExpanded ? Duration.zero : const Duration(milliseconds: 300);

    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottomPadding,
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          width: expandedWidth,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isExpanded
              ? _buildExpandedSearchBar(context, onBackgroundColor)
              : _buildCollapsedSearchButton(context, onBackgroundColor),
        ),
      ),
    );
  }

  Widget _buildExpandedSearchBar(BuildContext context, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Row(
        children: [
          // Search icon with fixed width
          SizedBox(
            width: 48,
            child: Icon(
              Icons.search,
              color: textColor,
              size: 24,
            ),
          ),
          // Flexible text field that takes remaining space
          Flexible(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                isDense: true,
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                widget.onSubmitted?.call(value);
                // Don't collapse search bar on submit to keep search active
                // _collapseSearchBar();
              },
            ),
          ),
          // Close button with fixed width
          SizedBox(
            width: 40,
            child: GestureDetector(
              onTap: _collapseSearchBar,
              child: SizedBox(
                height: 56,
                child: Icon(
                  Icons.close,
                  color: textColor,
                  size: 22,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 8, // Padding between close button and right edge
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSearchButton(BuildContext context, Color iconColor) {
    return GestureDetector(
      onTap: _expandSearchBar,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.search,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  void _expandSearchBar() {
    setState(() {
      _isExpanded = true;
    });
  }

  void _collapseSearchBar() {
    setState(() {
      _isExpanded = false;
      // Don't clear search when collapsed to maintain search state
      // _controller.clear(); // Clear search when collapsed
    });
    
    // Call onChanged with empty string to clear search results
    widget.onChanged?.call('');
  }
}
