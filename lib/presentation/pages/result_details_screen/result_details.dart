import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/dynamic_prize_sections_widget.dart';

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

  // Store all lottery numbers with their categories
  final List<Map<String, dynamic>> _allLotteryNumbers = [];

  // Track the currently highlighted index
  int _highlightedIndex = -1;

  // Global keys for each ticket widget to track their positions
  final List<GlobalKey> _ticketKeys = [];

  // Timer for throttling scroll updates
  bool _isScrollUpdatePending = false;

  @override
  void initState() {
    super.initState();

    // Add scroll listener for dynamic highlighting
    _scrollController.addListener(_onScroll);

    // Load lottery result details if uniqueId is provided
    if (widget.uniqueId != null) {
      context.read<LotteryResultDetailsBloc>().add(
            LoadLotteryResultDetailsEvent(widget.uniqueId!),
          );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrollUpdatePending) return;

    _isScrollUpdatePending = true;

    // Throttle updates to improve performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHighlightedIndex();
        _isScrollUpdatePending = false;
      }
    });
  }

  void _updateHighlightedIndex() {
    if (_allLotteryNumbers.isEmpty || _ticketKeys.isEmpty) return;

    final screenHeight = MediaQuery.of(context).size.height;

    // Define the "focus area" - center third of the screen
    final focusAreaTop = screenHeight * 0.33;
    final focusAreaBottom = screenHeight * 0.67;
    final focusAreaCenter = screenHeight * 0.5;

    int bestIndex = -1;
    double bestDistance = double.infinity;

    // Check each ticket's position relative to the focus area
    for (int i = 0; i < _ticketKeys.length; i++) {
      final key = _ticketKeys[i];
      final context = key.currentContext;

      if (context == null) continue;

      try {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        // Calculate the center of the widget
        final widgetCenter = position.dy + (size.height / 2);

        // Check if widget is in the focus area
        if (widgetCenter >= focusAreaTop && widgetCenter <= focusAreaBottom) {
          // Calculate distance from the center of focus area
          final distanceFromCenter = (widgetCenter - focusAreaCenter).abs();

          if (distanceFromCenter < bestDistance) {
            bestDistance = distanceFromCenter;
            bestIndex = i;
          }
        }
      } catch (e) {
        // Handle cases where RenderBox is not available
        continue;
      }
    }

    // Update highlighted index if it changed
    if (bestIndex != _highlightedIndex) {
      setState(() {
        _highlightedIndex = bestIndex;
      });
    }
  }

  void _initializeLotteryNumbers(LotteryResultModel result) {
    _allLotteryNumbers.clear();
    _ticketKeys.clear();

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

    // Create GlobalKeys for each lottery number
    for (int i = 0; i < _allLotteryNumbers.length; i++) {
      _ticketKeys.add(GlobalKey());
    }

    // Reset highlighted index
    _highlightedIndex = -1;
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

  // Method to scroll to a specific lottery number
  void _scrollToNumber(int index) {
    if (index < 0 || index >= _ticketKeys.length) return;

    final key = _ticketKeys[index];
    final context = key.currentContext;

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item on screen
      );
    }
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
            // Initialize lottery numbers
            _initializeLotteryNumbers(state.data.result);

            return _buildLoadedContent(theme, state.data.result);
          } else {
            return _buildInitialWidget(theme);
          }
        },
      ),
      // Optional: Add floating action button to show current position
      floatingActionButton: _allLotteryNumbers.isNotEmpty &&
              _highlightedIndex >= 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show a dialog with current position info
                _showPositionDialog();
              },
              icon: const Icon(Icons.my_location),
              label:
                  Text('${_highlightedIndex + 1}/${_allLotteryNumbers.length}'),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.9),
            )
          : null,
    );
  }

  void _showPositionDialog() {
    if (_highlightedIndex < 0 || _highlightedIndex >= _allLotteryNumbers.length)
      return;

    final currentNumber = _allLotteryNumbers[_highlightedIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number: ${currentNumber['number']}'),
            Text('Category: ${currentNumber['category']}'),
            Text('Prize: ${currentNumber['prize']}'),
            if (currentNumber['location']?.isNotEmpty == true)
              Text('Location: ${currentNumber['location']}'),
            const SizedBox(height: 16),
            Text(
                'Position: ${_highlightedIndex + 1} of ${_allLotteryNumbers.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(ThemeData theme, LotteryResultModel result) {
    return RefreshIndicator(
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
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme, result),
              const SizedBox(height: 6),
              // Updated to use dynamic highlighting
              DynamicPrizeSectionsWidget(
                key: ValueKey('prize_sections_${result.uniqueId}'),
                highlightedIndex: _highlightedIndex,
                result: result,
                allLotteryNumbers: _allLotteryNumbers,
              ),
              const SizedBox(height: 6),
              _buildContactSection(theme),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
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
              Icon(Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
              Icon(Icons.tag,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
              child: Text(
                'Visit Official Website',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
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
        // Optional: Add action to jump to specific position
        if (_allLotteryNumbers.isNotEmpty)
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert,
                color: theme.appBarTheme.actionsIconTheme?.color),
            onSelected: (index) => _scrollToNumber(index),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.looks_one),
                    SizedBox(width: 8),
                    Text('Go to First Prize'),
                  ],
                ),
              ),
              if (_allLotteryNumbers.length > 1)
                PopupMenuItem(
                  value: _allLotteryNumbers.length - 1,
                  child: const Row(
                    children: [
                      Icon(Icons.last_page),
                      SizedBox(width: 8),
                      Text('Go to Last Number'),
                    ],
                  ),
                ),
            ],
          ),
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
              color: theme.colorScheme.error,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
