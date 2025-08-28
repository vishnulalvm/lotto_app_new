import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:shimmer/shimmer.dart';

class DynamicPrizeSectionsWidget extends StatelessWidget {
  final LotteryResultModel result;
  final List<Map<String, dynamic>> allLotteryNumbers;
  final ValueNotifier<String> highlightedTicketNotifier; // Changed to ValueNotifier
  final Map<String, GlobalKey> ticketGlobalKeys; // Add GlobalKeys for auto-scroll
  final bool isLiveHours; // Add isLiveHours parameter
  final Set<String> newlyUpdatedTickets; // Add set of newly updated tickets

  const DynamicPrizeSectionsWidget({
    super.key,
    required this.result,
    required this.allLotteryNumbers,
    required this.highlightedTicketNotifier, // Updated parameter
    required this.ticketGlobalKeys, // Add GlobalKeys parameter
    this.isLiveHours = false, // Default to false
    this.newlyUpdatedTickets = const {}, // Default to empty set
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: _buildDynamicPrizeSections(theme, result),
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
                  final keyId = '${prize.prizeTypeFormatted}_${ticket.ticketNumber}';
                  final globalKey = ticketGlobalKeys[keyId];
                  return _HighlightedTicketWidget(
                    key: globalKey ?? ValueKey('${prize.prizeType}_${ticket.ticketNumber}'),
                    ticketNumber: ticket.ticketNumber,
                    category: prize.prizeTypeFormatted,
                    location: ticket.location,
                    allLotteryNumbers: allLotteryNumbers,
                    highlightedTicketNotifier: highlightedTicketNotifier, // Updated to use ValueNotifier
                    theme: theme,
                    variant: TicketVariant.withLocation,
                    isNewlyUpdated: newlyUpdatedTickets.contains(ticket.ticketNumber),
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
    final ticketNumbers = result.getPrizeTicketNumbers(prize);
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
                  () {
                    final keyId = '${prize.prizeTypeFormatted}_${ticketNumbers.first}';
                    final globalKey = ticketGlobalKeys[keyId];
                      return _HighlightedTicketWidget(
                      key: globalKey ?? ValueKey('${prize.prizeType}_${ticketNumbers.first}'),
                      ticketNumber: ticketNumbers.first,
                      category: prize.prizeTypeFormatted,
                      allLotteryNumbers: allLotteryNumbers,
                      highlightedTicketNotifier: highlightedTicketNotifier, // Updated to use ValueNotifier
                      theme: theme,
                      variant: TicketVariant.singleLarge,
                      isNewlyUpdated: newlyUpdatedTickets.contains(ticketNumbers.first),
                    );
                  }(),
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
            final keyId = '${category}_$ticketNumber';
            final globalKey = ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$ticketNumber'),
                ticketNumber: ticketNumber,
                category: category,
                allLotteryNumbers: allLotteryNumbers,
                highlightedTicketNotifier: highlightedTicketNotifier, // Updated to use ValueNotifier
                theme: theme,
                variant: TicketVariant.twoColumn,
                isNewlyUpdated: newlyUpdatedTickets.contains(ticketNumber),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGridPrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = result.getPrizeTicketNumbers(prize);
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
            final keyId = '${category}_$number';
            final globalKey = ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                allLotteryNumbers: allLotteryNumbers,
                highlightedTicketNotifier: highlightedTicketNotifier, // Updated to use ValueNotifier
                theme: theme,
                variant: TicketVariant.consolationGrid,
                isNewlyUpdated: newlyUpdatedTickets.contains(number),
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
            final keyId = '${category}_$number';
            final globalKey = ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                allLotteryNumbers: allLotteryNumbers,
                highlightedTicketNotifier: highlightedTicketNotifier, // Updated to use ValueNotifier
                theme: theme,
                variant: TicketVariant.standardGrid,
                isNewlyUpdated: newlyUpdatedTickets.contains(number),
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
  final ValueNotifier<String> highlightedTicketNotifier; // Changed to ValueNotifier
  final ThemeData theme;
  final TicketVariant variant;
  final bool isNewlyUpdated; // Renamed from isShimmering for clarity

  const _HighlightedTicketWidget({
    super.key,
    required this.ticketNumber,
    required this.category,
    this.location,
    required this.allLotteryNumbers,
    required this.highlightedTicketNotifier, // Updated parameter
    required this.theme,
    required this.variant,
    this.isNewlyUpdated = false, // Default to false
  });

  @override
  State<_HighlightedTicketWidget> createState() =>
      _HighlightedTicketWidgetState();
}

class _HighlightedTicketWidgetState extends State<_HighlightedTicketWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isShimmering = false;

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

    // Handle shimmer effect locally if this ticket is newly updated
    if (widget.isNewlyUpdated) {
      _isShimmering = true;
      // Stop shimmering this specific ticket after a delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isShimmering = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _checkIfHighlighted(String highlightedTicketNumber) {
    // Return false if no search query
    if (highlightedTicketNumber.isEmpty) {
      return false;
    }

    // Check if this ticket number matches the search query
    // Support both exact match and partial match for better UX
    return widget.ticketNumber.toLowerCase().contains(
        highlightedTicketNumber.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.highlightedTicketNotifier,
      builder: (context, highlightedNumber, child) {
        final isHighlighted = _checkIfHighlighted(highlightedNumber);
        
        // Update animation based on highlight status
        if (isHighlighted && _animationController.value == 0) {
          HapticFeedback.selectionClick();
          _animationController.forward();
        } else if (!isHighlighted && _animationController.value == 1) {
          _animationController.reverse();
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final content = Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: _getPadding(),
                decoration: _getDecoration(isHighlighted: isHighlighted),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      style: _getTextStyle(isHighlighted: isHighlighted),
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

            // Wrap with shimmer effect if this ticket is newly updated
            if (_isShimmering) {
              return Shimmer.fromColors(
                baseColor: widget.theme.brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
                highlightColor: widget.theme.brightness == Brightness.dark
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                period: const Duration(milliseconds: 1000),
                child: content,
              );
            }

            return content;
          },
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

  BoxDecoration _getDecoration({required bool isHighlighted}) {
    final baseColor = isHighlighted
        ? (widget.theme.brightness == Brightness.dark
            ? const Color(0xFF2D1B1B)
            : const Color(0xFFFFEBEE))
        : widget.theme.scaffoldBackgroundColor;

    final borderColor = isHighlighted
        ? widget.theme.primaryColor
        : (widget.theme.dividerTheme.color ??
            (widget.theme.brightness == Brightness.dark
                ? const Color(0xFF424242)
                : Colors.grey[400]!));

    final borderWidth = isHighlighted ? 2.0 : 1.0;
    final borderRadius = widget.variant == TicketVariant.singleLarge
        ? 12.0
        : (widget.variant == TicketVariant.standardGrid ? 6.0 : 8.0);

    List<BoxShadow>? shadows;
    if (isHighlighted) {
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

  TextStyle _getTextStyle({required bool isHighlighted}) {
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
      fontSize: isHighlighted ? highlightedFontSize : baseFontSize,
      color: isHighlighted ? widget.theme.primaryColor : baseStyle.color,
      letterSpacing: widget.variant == TicketVariant.singleLarge ? 1.5 : 0.5,
    );
  }
}