import 'package:flutter/material.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:shimmer/shimmer.dart';

class DynamicPrizeSectionsWidget extends StatefulWidget {
  final LotteryResultModel result;
  final List<Map<String, dynamic>> allLotteryNumbers;
  final ValueNotifier<String> highlightedTicketNotifier;
  final Map<String, GlobalKey> ticketGlobalKeys;
  final bool isLiveHours;
  final Set<String> newlyUpdatedTickets;
  final Set<String> matchedNumbers;
  final Color? matchHighlightColor;
  final Set<String> patternNumbers;
  final Color? patternHighlightColor;

  const DynamicPrizeSectionsWidget({
    super.key,
    required this.result,
    required this.allLotteryNumbers,
    required this.highlightedTicketNotifier,
    required this.ticketGlobalKeys,
    this.isLiveHours = false,
    this.newlyUpdatedTickets = const {},
    this.matchedNumbers = const {},
    this.matchHighlightColor,
    this.patternNumbers = const {},
    this.patternHighlightColor,
  });

  @override
  State<DynamicPrizeSectionsWidget> createState() => _DynamicPrizeSectionsWidgetState();
}

class _DynamicPrizeSectionsWidgetState extends State<DynamicPrizeSectionsWidget> {
  List<Widget>? _cachedSections;
  String _cachedSearchQuery = '';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize cache on first build when Theme is available
    if (!_isInitialized) {
      _isInitialized = true;
      _cachedSearchQuery = widget.highlightedTicketNotifier.value;
      _cachedSections = _buildDynamicPrizeSections(
        Theme.of(context),
        widget.result,
        _cachedSearchQuery,
      );
    }
  }

  @override
  void didUpdateWidget(DynamicPrizeSectionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Invalidate cache if any data that affects rendering has changed
    if (oldWidget.result != widget.result ||
        oldWidget.matchedNumbers != widget.matchedNumbers ||
        oldWidget.patternNumbers != widget.patternNumbers ||
        oldWidget.newlyUpdatedTickets != widget.newlyUpdatedTickets) {
      // Rebuild sections with current search query
      _cachedSearchQuery = widget.highlightedTicketNotifier.value;
      _cachedSections = _buildDynamicPrizeSections(
        Theme.of(context),
        widget.result,
        _cachedSearchQuery,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to search changes at parent level
    return ValueListenableBuilder<String>(
      valueListenable: widget.highlightedTicketNotifier,
      builder: (context, searchQuery, _) {
        // Only rebuild if search query changed
        if (_cachedSearchQuery != searchQuery || _cachedSections == null) {
          _cachedSearchQuery = searchQuery;
          _cachedSections = _buildDynamicPrizeSections(
            Theme.of(context),
            widget.result,
            searchQuery,
          );
        }

        // Return cached list - Flutter will skip diffing if it's the same object
        return Column(
          children: _cachedSections!,
        );
      },
    );
  }

  // Helper to check if ticket matches search query
  bool _isTicketHighlighted(String ticketNumber, String searchQuery) {
    if (searchQuery.isEmpty) return false;
    return ticketNumber.toLowerCase().contains(searchQuery.toLowerCase());
  }

  List<Widget> _buildDynamicPrizeSections(
      ThemeData theme, LotteryResultModel result, String searchQuery) {
    List<Widget> sections = [];

    // Custom ordering: 1st prize, then consolation, then other prizes
    final prizes = result.prizes;

    // Add 1st prize first
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      sections.add(_buildPrizeSection(theme, firstPrize, searchQuery));
      sections.add(const SizedBox(height: 8));
    }

    // Add consolation prize second
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      sections.add(_buildPrizeSection(theme, consolationPrize, searchQuery));
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
      sections.add(_buildPrizeSection(theme, prize, searchQuery));
      sections.add(const SizedBox(height: 8));
    }

    return sections;
  }

  Widget _buildPrizeSection(ThemeData theme, PrizeModel prize, String searchQuery) {
    if (prize.isGrid) {
      return _buildGridPrizeSection(theme, prize, searchQuery);
    } else if (prize.hasLocationInfo) {
      return _buildPrizeWithLocationSection(theme, prize, searchQuery);
    } else {
      return _buildSinglePrizeSection(theme, prize, searchQuery);
    }
  }

  Widget _buildPrizeWithLocationSection(ThemeData theme, PrizeModel prize, String searchQuery) {
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
                  final globalKey = widget.ticketGlobalKeys[keyId];
                  return _HighlightedTicketWidget(
                    key: globalKey ?? ValueKey('${prize.prizeType}_${ticket.ticketNumber}'),
                    ticketNumber: ticket.ticketNumber,
                    category: prize.prizeTypeFormatted,
                    location: ticket.location,
                    theme: theme,
                    variant: TicketVariant.withLocation,
                    isNewlyUpdated: widget.newlyUpdatedTickets.contains(ticket.ticketNumber),
                    isHighlighted: _isTicketHighlighted(ticket.ticketNumber, searchQuery),
                    isMatched: widget.matchedNumbers.contains(ticket.ticketNumber),
                    matchHighlightColor: widget.matchHighlightColor,
                    isPattern: widget.patternNumbers.contains(ticket.ticketNumber),
                    patternHighlightColor: widget.patternHighlightColor,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePrizeSection(ThemeData theme, PrizeModel prize, String searchQuery) {
    final ticketNumbers = widget.result.getPrizeTicketNumbers(prize);
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
                      ticketNumbers, theme, prize.prizeTypeFormatted, searchQuery)
                else
                  () {
                    final keyId = '${prize.prizeTypeFormatted}_${ticketNumbers.first}';
                    final globalKey = widget.ticketGlobalKeys[keyId];
                      return _HighlightedTicketWidget(
                      key: globalKey ?? ValueKey('${prize.prizeType}_${ticketNumbers.first}'),
                      ticketNumber: ticketNumbers.first,
                      category: prize.prizeTypeFormatted,
                      theme: theme,
                      variant: TicketVariant.singleLarge,
                      isNewlyUpdated: widget.newlyUpdatedTickets.contains(ticketNumbers.first),
                      isHighlighted: _isTicketHighlighted(ticketNumbers.first, searchQuery),
                      isMatched: widget.matchedNumbers.contains(ticketNumbers.first),
                      matchHighlightColor: widget.matchHighlightColor,
                      isPattern: widget.patternNumbers.contains(ticketNumbers.first),
                      patternHighlightColor: widget.patternHighlightColor,
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
      List<String> ticketNumbers, ThemeData theme, String category, String searchQuery) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 12) / 2;

        return Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: ticketNumbers.map((ticketNumber) {
            final keyId = '${category}_$ticketNumber';
            final globalKey = widget.ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$ticketNumber'),
                ticketNumber: ticketNumber,
                category: category,
                theme: theme,
                variant: TicketVariant.twoColumn,
                isNewlyUpdated: widget.newlyUpdatedTickets.contains(ticketNumber),
                isHighlighted: _isTicketHighlighted(ticketNumber, searchQuery),
                isMatched: widget.matchedNumbers.contains(ticketNumber),
                matchHighlightColor: widget.matchHighlightColor,
                isPattern: widget.patternNumbers.contains(ticketNumber),
                patternHighlightColor: widget.patternHighlightColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGridPrizeSection(ThemeData theme, PrizeModel prize, String searchQuery) {
    final ticketNumbers = widget.result.getPrizeTicketNumbers(prize);
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
                      ticketNumbers, theme, prize.prizeTypeFormatted, searchQuery)
                else
                  _buildStandardNumberGrid(
                      ticketNumbers, theme, prize.prizeTypeFormatted, searchQuery),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationNumberGrid(
      List<String> numbers, ThemeData theme, String category, String searchQuery) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 24) / 2;

        return Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: numbers.map((number) {
            final keyId = '${category}_$number';
            final globalKey = widget.ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                theme: theme,
                variant: TicketVariant.consolationGrid,
                isNewlyUpdated: widget.newlyUpdatedTickets.contains(number),
                isHighlighted: _isTicketHighlighted(number, searchQuery),
                isMatched: widget.matchedNumbers.contains(number),
                matchHighlightColor: widget.matchHighlightColor,
                isPattern: widget.patternNumbers.contains(number),
                patternHighlightColor: widget.patternHighlightColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStandardNumberGrid(
      List<String> numbers, ThemeData theme, String category, String searchQuery) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 36) / 4;

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: numbers.map((number) {
            final keyId = '${category}_$number';
            final globalKey = widget.ticketGlobalKeys[keyId];
            return SizedBox(
              width: cellWidth,
              child: _HighlightedTicketWidget(
                key: globalKey ?? ValueKey('${category}_$number'),
                ticketNumber: number,
                category: category,
                theme: theme,
                variant: TicketVariant.standardGrid,
                isNewlyUpdated: widget.newlyUpdatedTickets.contains(number),
                isHighlighted: _isTicketHighlighted(number, searchQuery),
                isMatched: widget.matchedNumbers.contains(number),
                matchHighlightColor: widget.matchHighlightColor,
                isPattern: widget.patternNumbers.contains(number),
                patternHighlightColor: widget.patternHighlightColor,
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

// Pure stateless ticket widget - no animations, no listeners, just rendering
class _HighlightedTicketWidget extends StatelessWidget {
  final String ticketNumber;
  final String category;
  final String? location;
  final ThemeData theme;
  final TicketVariant variant;
  final bool isNewlyUpdated;
  final bool isHighlighted; // Pre-calculated highlight status from search
  final bool isMatched; // Pre-calculated match status
  final Color? matchHighlightColor;
  final bool isPattern; // Pre-calculated pattern status
  final Color? patternHighlightColor;

  const _HighlightedTicketWidget({
    super.key,
    required this.ticketNumber,
    required this.category,
    this.location,
    required this.theme,
    required this.variant,
    this.isNewlyUpdated = false,
    this.isHighlighted = false,
    this.isMatched = false,
    this.matchHighlightColor,
    this.isPattern = false,
    this.patternHighlightColor,
  });

  @override
  Widget build(BuildContext context) {
    // Simple container - no animations, no state, just styling based on props
    final content = Container(
      padding: _getPadding(),
      decoration: _getDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ticketNumber,
            style: _getTextStyle(),
            textAlign: TextAlign.center,
          ),
          if (location != null && location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
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
    );

    // Wrap with shimmer if newly updated
    if (isNewlyUpdated) {
      return Shimmer.fromColors(
        baseColor: theme.brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey[300]!,
        highlightColor: theme.brightness == Brightness.dark
            ? Colors.grey[600]!
            : Colors.grey[100]!,
        period: const Duration(milliseconds: 1000),
        child: content,
      );
    }

    return content;
  }

  EdgeInsets _getPadding() {
    switch (variant) {
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
    // Priority: isMatched (green) > isPattern (purple) > isHighlighted (search - red)
    final baseColor = isMatched
        ? (theme.brightness == Brightness.dark
            ? const Color(0xFF1B2D1B) // Dark green background
            : const Color(0xFFE8F5E9)) // Light green background
        : (isPattern
            ? (theme.brightness == Brightness.dark
                ? const Color(0xFF2D1B2D) // Dark purple background
                : const Color(0xFFF3E5F5)) // Light purple background
            : (isHighlighted
                ? (theme.brightness == Brightness.dark
                    ? const Color(0xFF2D1B1B)
                    : const Color(0xFFFFEBEE))
                : theme.scaffoldBackgroundColor));

    final borderColor = isMatched
        ? (matchHighlightColor ?? Colors.green)
        : (isPattern
            ? (patternHighlightColor ?? Colors.purple.shade200)
            : (isHighlighted
                ? theme.primaryColor
                : (theme.dividerTheme.color ??
                    (theme.brightness == Brightness.dark
                        ? const Color(0xFF424242)
                        : Colors.grey[400]!))));

    final borderWidth = (isMatched || isPattern || isHighlighted) ? 2.0 : 1.0;
    final borderRadius = variant == TicketVariant.singleLarge
        ? 12.0
        : (variant == TicketVariant.standardGrid ? 6.0 : 8.0);

    List<BoxShadow>? shadows;
    if (isMatched || isPattern || isHighlighted) {
      final shadowBlur = variant == TicketVariant.singleLarge ? 12.0 : 8.0;
      final shadowOffset = variant == TicketVariant.singleLarge
          ? const Offset(0, 4)
          : const Offset(0, 2);

      final shadowColor = isMatched
          ? (matchHighlightColor ?? Colors.green)
          : (isPattern
              ? (patternHighlightColor ?? Colors.purple.shade200)
              : theme.primaryColor);

      shadows = [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.2),
          blurRadius: shadowBlur,
          offset: shadowOffset,
        )
      ];
    } else if (variant != TicketVariant.standardGrid) {
      shadows = [
        BoxShadow(
          color: (theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey)
              .withValues(alpha: 0.1),
          blurRadius: variant == TicketVariant.singleLarge ? 4.0 : 2.0,
          offset: variant == TicketVariant.singleLarge
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
    final baseStyle = switch (variant) {
      TicketVariant.withLocation => theme.textTheme.titleLarge!,
      TicketVariant.singleLarge => theme.textTheme.displaySmall!,
      TicketVariant.twoColumn => theme.textTheme.titleLarge!,
      TicketVariant.consolationGrid => theme.textTheme.titleMedium!,
      TicketVariant.standardGrid => theme.textTheme.bodyMedium!,
    };

    final baseFontSize = switch (variant) {
      TicketVariant.withLocation => 24.0,
      TicketVariant.singleLarge => 24.0,
      TicketVariant.twoColumn => 18.0,
      TicketVariant.consolationGrid => 18.0,
      TicketVariant.standardGrid => 18.0,
    };

    final highlightedFontSize = switch (variant) {
      TicketVariant.withLocation => 28.0,
      TicketVariant.singleLarge => 26.0,
      TicketVariant.twoColumn => 24.0,
      TicketVariant.consolationGrid => 20.0,
      TicketVariant.standardGrid => 20.0,
    };

    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: isHighlighted ? highlightedFontSize : baseFontSize,
      color: isHighlighted ? theme.primaryColor : baseStyle.color,
      letterSpacing: variant == TicketVariant.singleLarge ? 1.5 : 0.5,
    );
  }
}

