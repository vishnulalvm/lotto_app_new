import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';

class FloatingSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function(bool)? onResultsFound; // New callback for haptic feedback

  final bool clearOnClose; // Customizable state management on collapse
  final Duration debounceDuration; // Debounce duration for onChanged

  const FloatingSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onResultsFound,
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

    // Responsive dimensions
    final horizontalPadding = AppResponsive.spacing(context, 12);
    final collapsedSize = AppResponsive.spacing(context, 56);
    final searchBarHeight = AppResponsive.spacing(context, 56);

    // When expanded, take full width with responsive padding on both ends
    final expandedWidth = _isExpanded
        ? screenWidth - (horizontalPadding * 2)
        : collapsedSize;

    // Smooth bi-directional animation
    const animationDuration = Duration(milliseconds: 300);

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: expandedWidth,
      height: searchBarHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 28)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: AppResponsive.spacing(context, 12),
            offset: Offset(0, AppResponsive.spacing(context, 4)),
          ),
        ],
      ),
      child: _isExpanded
          ? _buildExpandedSearchBar(context, onBackgroundColor)
          : _buildCollapsedSearchButton(context, onBackgroundColor),
    );
  }

  Widget _buildExpandedSearchBar(BuildContext context, Color textColor) {
    final searchIconWidth = AppResponsive.spacing(context, 48);
    final closeButtonWidth = AppResponsive.spacing(context, 40);
    final rightPadding = AppResponsive.spacing(context, 8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 28)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only show full content if there's enough space
          final minWidthNeeded = searchIconWidth + closeButtonWidth + rightPadding + 100;

          if (constraints.maxWidth < minWidthNeeded) {
            // During animation, just show search icon centered
            return Center(
              child: Icon(
                Icons.search,
                color: textColor,
                size: AppResponsive.spacing(context, 24),
              ),
            );
          }

          return Row(
            children: [
              // Search icon with responsive width
              SizedBox(
                width: searchIconWidth,
                child: Icon(
                  Icons.search,
                  color: textColor,
                  size: AppResponsive.spacing(context, 24),
                ),
              ),
              // Expanded text field that takes remaining space
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: AppResponsive.fontSize(context, 16),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppResponsive.spacing(context, 16),
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppResponsive.fontSize(context, 16),
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
              // Close button with responsive width
              SizedBox(
                width: closeButtonWidth,
                child: IconButton(
                  onPressed: _collapseSearchBar,
                  icon: Icon(
                    Icons.close,
                    color: textColor,
                    size: AppResponsive.spacing(context, 22),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: closeButtonWidth,
                    minHeight: AppResponsive.spacing(context, 56),
                  ),
                ),
              ),
              SizedBox(
                width: rightPadding,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedSearchButton(BuildContext context, Color iconColor) {
    final buttonSize = AppResponsive.spacing(context, 56);
    return IconButton(
      onPressed: _expandSearchBar,
      icon: Icon(
        Icons.search,
        color: iconColor,
        size: AppResponsive.spacing(context, 24),
      ),
      style: IconButton.styleFrom(
        minimumSize: Size(buttonSize, buttonSize),
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
