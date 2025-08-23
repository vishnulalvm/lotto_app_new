import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function(bool)? onResultsFound; // New callback for haptic feedback
  final double bottomPadding;
  final bool clearOnClose; // Customizable state management on collapse
  final Duration debounceDuration; // Debounce duration for onChanged

  const FloatingSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onResultsFound,
    this.bottomPadding = 20.0,
    this.clearOnClose = true,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isExpanded = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
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

    // Smooth bi-directional animation
    const animationDuration = Duration(milliseconds: 300);

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
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: textColor.withOpacity(0.7),
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
              onChanged: (value) {
                // Provide light haptic feedback when user starts typing
                if (value.isNotEmpty && _controller.text.isEmpty) {
                  HapticFeedback.lightImpact();
                }
                _onSearchChanged(value);
              },
              onSubmitted: (value) {
                _debounceTimer?.cancel();
                widget.onSubmitted?.call(value);
                // Don't collapse search bar on submit to keep search active
                // _collapseSearchBar();
              },
            ),
          ),
          // Close button with fixed width
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: _collapseSearchBar,
              icon: Icon(
                Icons.close,
                color: textColor,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 56,
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
    return IconButton(
      onPressed: _expandSearchBar,
      icon: Icon(
        Icons.search,
        color: iconColor,
        size: 24,
      ),
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        shape: const CircleBorder(),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(value);
    });
  }

  void _expandSearchBar() {
    // Provide medium haptic feedback when search bar expands
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = true;
    });
    // Focus the text field when expanding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _collapseSearchBar() {
    // Provide light haptic feedback when search bar collapses
    HapticFeedback.lightImpact();
    
    // Cancel any pending debounced calls
    _debounceTimer?.cancel();
    
    // Unfocus the text field to dismiss keyboard
    _focusNode.unfocus();
    
    setState(() {
      _isExpanded = false;
      if (widget.clearOnClose) {
        _controller.clear();
      }
    });

    // Call onChanged with empty string to clear search results if clearing
    if (widget.clearOnClose) {
      widget.onChanged?.call('');
    }
  }
}
