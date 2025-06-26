import 'package:flutter/material.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

class DynamicPrizeSectionsWidget extends StatefulWidget {
  final LotteryResultModel result;
  final List<Map<String, dynamic>> allLotteryNumbers;
  final String highlightedTicketNumber; // Changed from int highlightedIndex

  const DynamicPrizeSectionsWidget({
    super.key,
    required this.result,
    required this.allLotteryNumbers,
    required this.highlightedTicketNumber, // Updated parameter
  });

  @override
  State<DynamicPrizeSectionsWidget> createState() =>
      _DynamicPrizeSectionsWidgetState();
}

class _DynamicPrizeSectionsWidgetState
    extends State<DynamicPrizeSectionsWidget> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: _buildDynamicPrizeSections(theme, widget.result),
    );
  }

  List<Widget> _buildDynamicPrizeSections(
      ThemeData theme, LotteryResultModel result) {
    List<Widget> sections = [];

    // Custom ordering: 1st prize, then consolation, then other prizes
    final prizes = result.prizes;

    // Add 1st prize first
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      sections.add(_buildPrizeSection(theme, firstPrize));
      sections.add(const SizedBox(height: 8));
    }

    // Add consolation prize second
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      sections.add(_buildPrizeSection(theme, consolationPrize));
      sections.add(const SizedBox(height: 8));
    }

    // Add remaining prizes (2nd to 10th)
    final remainingPrizes = prizes
        .where((prize) =>
            prize.prizeType != '1st' && prize.prizeType != 'consolation')
        .toList();

    // Sort remaining prizes by prize type
    remainingPrizes.sort((a, b) {
      final prizeOrder = [
        '2nd',
        '3rd',
        '4th',
        '5th',
        '6th',
        '7th',
        '8th',
        '9th',
        '10th'
      ];
      final aIndex = prizeOrder.indexOf(a.prizeType);
      final bIndex = prizeOrder.indexOf(b.prizeType);
      return aIndex.compareTo(bIndex);
    });

    for (final prize in remainingPrizes) {
      sections.add(_buildPrizeSection(theme, prize));
      sections.add(const SizedBox(height: 8));
    }

    return sections;
  }

  Widget _buildPrizeSection(ThemeData theme, PrizeModel prize) {
    if (prize.isGrid) {
      return _buildGridPrizeSection(theme, prize);
    } else if (prize.hasLocationInfo) {
      return _buildPrizeWithLocationSection(theme, prize);
    } else {
      return _buildSinglePrizeSection(theme, prize);
    }
  }

  Widget _buildPrizeWithLocationSection(ThemeData theme, PrizeModel prize) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
      child: Column(
        children: [
          _buildPrizeHeader(theme, prize.prizeTypeFormatted),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildPrizeAmount(theme, prize.formattedPrizeAmount),
                const SizedBox(height: 10),
                ...prize.ticketsWithLocation.map((ticket) {
                  return _HighlightedTicketWidget(
                    key: ValueKey('${prize.prizeType}_${ticket.ticketNumber}'),
                    ticketNumber: ticket.ticketNumber,
                    category: prize.prizeTypeFormatted,
                    location: ticket.location,
                    allLotteryNumbers: widget.allLotteryNumbers,
                    highlightedTicketNumber: widget.highlightedTicketNumber, // Updated
                    theme: theme,
                    variant: TicketVariant.withLocation,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = prize.allTicketNumbers;
    final hasMultipleNumbers = ticketNumbers.length > 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
      child: Column(
        children: [
          _buildPrizeHeader(theme, prize.prizeTypeFormatted),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildPrizeAmount(theme, prize.formattedPrizeAmount),
                const SizedBox(height: 10),
                if (hasMultipleNumbers)
                  _buildSinglePrizeTwoColumnGrid(
                      ticketNumbers, theme, prize.prizeTypeFormatted)
                else
                  _HighlightedTicketWidget(
                    key: ValueKey('${prize.prizeType}_${ticketNumbers.first}'),
                    ticketNumber: ticketNumbers.first,
                    category: prize.prizeTypeFormatted,
                    allLotteryNumbers: widget.allLotteryNumbers,
                    highlightedTicketNumber: widget.highlightedTicketNumber, // Updated
                    theme: theme,
                    variant: TicketVariant.singleLarge,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePrizeTwoColumnGrid(
      List<String> ticketNumbers, ThemeData theme, String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 12) / 2;

        return Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: ticketNumbers.map((ticketNumber) {
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: ValueKey('${category}_$ticketNumber'),
                ticketNumber: ticketNumber,
                category: category,
                allLotteryNumbers: widget.allLotteryNumbers,
                highlightedTicketNumber: widget.highlightedTicketNumber, // Updated
                theme: theme,
                variant: TicketVariant.twoColumn,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGridPrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = prize.allTicketNumbers;
    final isConsolationPrize = prize.prizeType.toLowerCase() == 'consolation';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
      child: Column(
        children: [
          _buildPrizeHeader(theme, prize.prizeTypeFormatted),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                _buildPrizeAmount(theme, prize.formattedPrizeAmount),
                const SizedBox(height: 10),
                if (isConsolationPrize)
                  _buildConsolationNumberGrid(
                      ticketNumbers, theme, prize.prizeTypeFormatted)
                else
                  _buildStandardNumberGrid(
                      ticketNumbers, theme, prize.prizeTypeFormatted),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationNumberGrid(
      List<String> numbers, ThemeData theme, String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 24) / 2;

        return Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: numbers.map((number) {
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                allLotteryNumbers: widget.allLotteryNumbers,
                highlightedTicketNumber: widget.highlightedTicketNumber, // Updated
                theme: theme,
                variant: TicketVariant.consolationGrid,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStandardNumberGrid(
      List<String> numbers, ThemeData theme, String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 36) / 4;

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: numbers.map((number) {
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                allLotteryNumbers: widget.allLotteryNumbers,
                highlightedTicketNumber: widget.highlightedTicketNumber, // Updated
                theme: theme,
                variant: TicketVariant.standardGrid,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Common header widget
  Widget _buildPrizeHeader(ThemeData theme, String prizeTypeFormatted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Text(
        prizeTypeFormatted,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Common prize amount widget
  Widget _buildPrizeAmount(ThemeData theme, String formattedPrizeAmount) {
    return Text(
      formattedPrizeAmount,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// Enum for different ticket display variants
enum TicketVariant {
  withLocation,
  singleLarge,
  twoColumn,
  consolationGrid,
  standardGrid,
}

// Optimized highlighted ticket widget that only rebuilds when necessary
class _HighlightedTicketWidget extends StatefulWidget {
  final String ticketNumber;
  final String category;
  final String? location;
  final List<Map<String, dynamic>> allLotteryNumbers;
  final String highlightedTicketNumber; // Changed from int highlightedIndex
  final ThemeData theme;
  final TicketVariant variant;

  const _HighlightedTicketWidget({
    super.key,
    required this.ticketNumber,
    required this.category,
    this.location,
    required this.allLotteryNumbers,
    required this.highlightedTicketNumber, // Updated parameter
    required this.theme,
    required this.variant,
  });

  @override
  State<_HighlightedTicketWidget> createState() =>
      _HighlightedTicketWidgetState();
}

class _HighlightedTicketWidgetState extends State<_HighlightedTicketWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateHighlightStatus();
  }

  @override
  void didUpdateWidget(_HighlightedTicketWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update highlight status when highlightedTicketNumber changes
    if (widget.highlightedTicketNumber != oldWidget.highlightedTicketNumber) {
      _updateHighlightStatus();
    }
  }

  void _updateHighlightStatus() {
    final wasHighlighted = _isHighlighted;
    _isHighlighted = _checkIfHighlighted();

    if (_isHighlighted != wasHighlighted) {
      if (_isHighlighted) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  bool _checkIfHighlighted() {
    // Return false if no search query
    if (widget.highlightedTicketNumber.isEmpty) {
      return false;
    }

    // Check if this ticket number matches the search query
    // Support both exact match and partial match for better UX
    return widget.ticketNumber.toLowerCase().contains(
        widget.highlightedTicketNumber.toLowerCase());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: _getPadding(),
            decoration: _getDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  style: _getTextStyle(),
                  child: Text(
                    widget.ticketNumber,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.location != null && widget.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: widget.theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.location!,
                          style: widget.theme.textTheme.bodyLarge?.copyWith(
                            color: widget.theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.variant) {
      case TicketVariant.withLocation:
        return const EdgeInsets.all(12);
      case TicketVariant.singleLarge:
        return const EdgeInsets.symmetric(vertical: 20, horizontal: 16);
      case TicketVariant.twoColumn:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 12);
      case TicketVariant.consolationGrid:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 12);
      case TicketVariant.standardGrid:
        return const EdgeInsets.symmetric(vertical: 10, horizontal: 8);
    }
  }

  BoxDecoration _getDecoration() {
    final baseColor = _isHighlighted
        ? (widget.theme.brightness == Brightness.dark
            ? const Color(0xFF2D1B1B)
            : const Color(0xFFFFEBEE))
        : widget.theme.scaffoldBackgroundColor;

    final borderColor = _isHighlighted
        ? widget.theme.primaryColor
        : (widget.theme.dividerTheme.color ??
            (widget.theme.brightness == Brightness.dark
                ? const Color(0xFF424242)
                : Colors.grey[400]!));

    final borderWidth = _isHighlighted ? 2.0 : 1.0;
    final borderRadius = widget.variant == TicketVariant.singleLarge
        ? 12.0
        : (widget.variant == TicketVariant.standardGrid ? 6.0 : 8.0);

    List<BoxShadow>? shadows;
    if (_isHighlighted) {
      final shadowBlur =
          widget.variant == TicketVariant.singleLarge ? 12.0 : 8.0;
      final shadowOffset = widget.variant == TicketVariant.singleLarge
          ? const Offset(0, 4)
          : const Offset(0, 2);

      shadows = [
        BoxShadow(
          color: widget.theme.primaryColor.withValues(alpha: 0.2),
          blurRadius: shadowBlur,
          offset: shadowOffset,
        )
      ];
    } else if (widget.variant != TicketVariant.standardGrid) {
      shadows = [
        BoxShadow(
          color: (widget.theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey)
              .withValues(alpha: 0.1),
          blurRadius: widget.variant == TicketVariant.singleLarge ? 4.0 : 2.0,
          offset: widget.variant == TicketVariant.singleLarge
              ? const Offset(0, 2)
              : const Offset(0, 1),
        )
      ];
    }

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadows,
    );
  }

  TextStyle _getTextStyle() {
    final baseStyle = switch (widget.variant) {
      TicketVariant.withLocation => widget.theme.textTheme.titleLarge!,
      TicketVariant.singleLarge => widget.theme.textTheme.displaySmall!,
      TicketVariant.twoColumn => widget.theme.textTheme.titleLarge!,
      TicketVariant.consolationGrid => widget.theme.textTheme.titleMedium!,
      TicketVariant.standardGrid => widget.theme.textTheme.bodyMedium!,
    };

    final baseFontSize = switch (widget.variant) {
      TicketVariant.withLocation => 24.0,
      TicketVariant.singleLarge => 24.0,
      TicketVariant.twoColumn => 18.0,
      TicketVariant.consolationGrid => 18.0,
      TicketVariant.standardGrid => 18.0,
    };

    final highlightedFontSize = switch (widget.variant) {
      TicketVariant.withLocation => 28.0,
      TicketVariant.singleLarge => 26.0,
      TicketVariant.twoColumn => 24.0,
      TicketVariant.consolationGrid => 20.0,
      TicketVariant.standardGrid => 20.0,
    };

    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: _isHighlighted ? highlightedFontSize : baseFontSize,
      color: _isHighlighted ? widget.theme.primaryColor : baseStyle.color,
      letterSpacing: widget.variant == TicketVariant.singleLarge ? 1.5 : 0.5,
    );
  }
}