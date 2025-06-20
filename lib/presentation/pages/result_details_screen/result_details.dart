import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';

class LotteryResultDetailsScreen extends StatefulWidget {
  final String? uniqueId;

  const LotteryResultDetailsScreen({
    super.key,
    this.uniqueId,
  });

  @override
  State<LotteryResultDetailsScreen> createState() =>
      _LotteryResultDetailsScreenState();
}

class _LotteryResultDetailsScreenState
    extends State<LotteryResultDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Store all lottery numbers with their categories for highlighting
  final List<Map<String, dynamic>> _allLotteryNumbers = [];
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();

    // Load lottery result details if uniqueId is provided
    if (widget.uniqueId != null) {
      context.read<LotteryResultDetailsBloc>().add(
            LoadLotteryResultDetailsEvent(widget.uniqueId!),
          );
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeLotteryNumbers(LotteryResultModel result) {
    _allLotteryNumbers.clear();

    // Custom ordering: 1st prize, then consolation, then other prizes
    final prizes = result.prizes;

    // Add 1st prize numbers first
    final firstPrize = result.getFirstPrize();
    if (firstPrize != null) {
      _addPrizeNumbers(firstPrize);
    }

    // Add consolation prize numbers second
    final consolationPrize = result.getConsolationPrize();
    if (consolationPrize != null) {
      _addPrizeNumbers(consolationPrize);
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
      _addPrizeNumbers(prize);
    }
  }

  void _addPrizeNumbers(PrizeModel prize) {
    // For prizes with tickets array (individual tickets with locations)
    for (final ticket in prize.ticketsWithLocation) {
      _allLotteryNumbers.add({
        'number': ticket.ticketNumber,
        'category': prize.prizeTypeFormatted,
        'prize': prize.formattedPrizeAmount,
        'location': ticket.location ?? '',
      });
    }

    // For prizes with ticket_numbers string (grid format)
    for (final ticketNumber in prize.allTicketNumbers) {
      // Skip if already added from tickets array
      if (!prize.ticketsWithLocation
          .any((t) => t.ticketNumber == ticketNumber)) {
        _allLotteryNumbers.add({
          'number': ticketNumber,
          'category': prize.prizeTypeFormatted,
          'prize': prize.formattedPrizeAmount,
          'location': '',
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _allLotteryNumbers.isEmpty) return;

    // Get the current scroll position
    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Avoid division by zero
    if (maxScrollExtent <= 0) return;

    // Calculate scroll percentage with smoother transition
    final scrollPercentage = (scrollOffset / maxScrollExtent).clamp(0.0, 1.0);

    // Use a smoother calculation that accounts for the total number of items
    final targetIndex =
        (scrollPercentage * (_allLotteryNumbers.length - 1)).round();
    final clampedIndex = targetIndex.clamp(0, _allLotteryNumbers.length - 1);

    if (clampedIndex != _highlightedIndex && mounted) {
      setState(() {
        _highlightedIndex = clampedIndex;
      });
    }
  }

  bool _isHighlighted(String number, String category) {
    if (_highlightedIndex < 0 ||
        _highlightedIndex >= _allLotteryNumbers.length) {
      return false;
    }

    final highlightedItem = _allLotteryNumbers[_highlightedIndex];
    return highlightedItem['number'] == number &&
        highlightedItem['category'] == category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, context),
      body: BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
        builder: (context, state) {
          if (state is LotteryResultDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is LotteryResultDetailsError) {
            return _buildErrorWidget(theme, state.message);
          } else if (state is LotteryResultDetailsLoaded) {
            // Initialize lottery numbers for highlighting
            _initializeLotteryNumbers(state.data.result);

            return _buildLoadedContent(theme, state.data.result);
          } else {
            return _buildInitialWidget(theme);
          }
        },
      ),
    );
  }

  Widget _buildLoadedContent(ThemeData theme, LotteryResultModel result) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            if (widget.uniqueId != null) {
              context.read<LotteryResultDetailsBloc>().add(
                    RefreshLotteryResultDetailsEvent(widget.uniqueId!),
                  );
            }
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(theme, result),
                  const SizedBox(height: 6),
                  ..._buildDynamicPrizeSections(theme, result),
                  const SizedBox(height: 6),
                  _buildContactSection(theme),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ),

        // Floating highlighted card
        if (_highlightedIndex >= 0 &&
            _highlightedIndex < _allLotteryNumbers.length)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildHighlightedCard(theme),
            ),
          ),
      ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              prize.prizeTypeFormatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ...prize.ticketsWithLocation.map((ticket) {
                  final isHighlighted = _isHighlighted(
                      ticket.ticketNumber, prize.prizeTypeFormatted);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isHighlighted ? Colors.yellow[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: isHighlighted
                          ? Border.all(color: theme.primaryColor, width: 2)
                          : Border.all(color: Colors.grey[300]!),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isHighlighted ? 28 : 24,
                            color: isHighlighted ? theme.primaryColor : null,
                          ),
                          child: Text(
                            ticket.ticketNumber,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (ticket.location != null &&
                            ticket.location!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.location!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              prize.prizeTypeFormatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Smart layout: Use 2-column grid for multiple numbers, single column for one number
                if (hasMultipleNumbers)
                  _buildSinglePrizeTwoColumnGrid(
                      ticketNumbers, theme, prize.prizeTypeFormatted)
                else
                  _buildSinglePrizeSingleItem(
                      ticketNumbers.first, theme, prize.prizeTypeFormatted),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Two-column grid layout for multiple numbers
  Widget _buildSinglePrizeTwoColumnGrid(
      List<String> ticketNumbers, ThemeData theme, String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - 12) / 2; // Account for gap

        return Wrap(
          spacing: 10.0, // Horizontal spacing between columns
          runSpacing: 10.0, // Vertical spacing between rows
          children: ticketNumbers.map((ticketNumber) {
            final isHighlighted = _isHighlighted(ticketNumber, category);

            return SizedBox(
              width: cellWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.yellow[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isHighlighted ? theme.primaryColor : Colors.grey[300]!,
                    width: isHighlighted ? 2 : 1,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isHighlighted ? 24 : 18,
                    color: isHighlighted ? theme.primaryColor : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                  child: Text(
                    ticketNumber,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

// Single item layout for when there's only one number (like 1st prize)
  Widget _buildSinglePrizeSingleItem(
      String ticketNumber, ThemeData theme, String category) {
    final isHighlighted = _isHighlighted(ticketNumber, category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.yellow[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? theme.primaryColor : Colors.grey[300]!,
          width: isHighlighted ? 3 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        style: theme.textTheme.displaySmall!.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isHighlighted ? 26 : 24,
          color: isHighlighted ? theme.primaryColor : Colors.black87,
          letterSpacing: 1.5,
        ),
        child: Text(
          ticketNumber,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGridPrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = prize.allTicketNumbers;
    final isConsolationPrize = prize.prizeType.toLowerCase() == 'consolation';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              prize.prizeTypeFormatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Use improved grid layout specifically for consolation prizes
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
        final cellWidth =
            (availableWidth - 24) / 2; // Account for padding and gap

        return Wrap(
          spacing: 12.0, // Horizontal spacing between columns
          runSpacing: 12.0, // Vertical spacing between rows
          children: numbers.map((number) {
            final isHighlighted = _isHighlighted(number, category);

            return SizedBox(
              width: cellWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.yellow[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isHighlighted ? theme.primaryColor : Colors.grey[300]!,
                    width: isHighlighted ? 2 : 1,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: isHighlighted ? theme.primaryColor : Colors.black87,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w600,
                    fontSize: isHighlighted ? 20 : 18,
                    letterSpacing: 0.5,
                  ),
                  child: Text(
                    number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

// Enhanced standard grid for other prizes (4-column layout)
  Widget _buildStandardNumberGrid(
      List<String> numbers, ThemeData theme, String category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellWidth =
            (availableWidth - 36) / 4; // Account for padding and gaps

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: numbers.map((number) {
            final isHighlighted = _isHighlighted(number, category);

            return SizedBox(
              width: cellWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.yellow[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isHighlighted ? theme.primaryColor : Colors.grey[300]!,
                    width: isHighlighted ? 2 : 1,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: isHighlighted ? theme.primaryColor : Colors.black87,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w700,
                    fontSize: isHighlighted ? 20 : 18,
                  ),
                  child: Text(
                    number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeaderSection(ThemeData theme, LotteryResultModel result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                result.formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.tag, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                result.formattedDrawNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCard(ThemeData theme) {
    final highlightedItem = _allLotteryNumbers[_highlightedIndex];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.primaryColor, width: 2),
      ),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                highlightedItem['category'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              highlightedItem['number'],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              highlightedItem['prize'],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
                fontSize: 18,
              ),
            ),
            if (highlightedItem['location'] != null &&
                highlightedItem['location'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      highlightedItem['location'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone, 'Phone: 0471-2305230', theme),
            _buildContactRow(Icons.person, 'Director: 0471-2305193', theme),
            _buildContactRow(
                Icons.email, 'Email: cru.dir.lotteries@kerala.gov.in', theme),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Visit Official Website'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => context.go('/'),
      ),
      title: BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
        builder: (context, state) {
          if (state is LotteryResultDetailsLoaded) {
            return Text(
              state.data.result.lotteryName.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          return Text(
            'Lottery Result',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share,
              color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.bookmark_outline,
              color: theme.appBarTheme.actionsIconTheme?.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Result',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.uniqueId != null) {
                  context.read<LotteryResultDetailsBloc>().add(
                        LoadLotteryResultDetailsEvent(widget.uniqueId!),
                      );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Lottery Result Selected',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a lottery result to view details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
