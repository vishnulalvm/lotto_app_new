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

    for (final prize in result.getOrderedPrizes()) {
      for (final ticketNumber in prize.ticketNumbersList) {
        _allLotteryNumbers.add({
          'number': ticketNumber,
          'category': prize.prizeTypeFormatted,
          'prize': prize.formattedPrizeAmount,
          'location': prize.placeUsed ? prize.place : '',
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _allLotteryNumbers.isEmpty) return;

    final scrollPercentage =
        _scrollController.offset / _scrollController.position.maxScrollExtent;
    final newIndex = (scrollPercentage * _allLotteryNumbers.length).floor();
    final clampedIndex = newIndex.clamp(0, _allLotteryNumbers.length - 1);

    if (clampedIndex != _highlightedIndex) {
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
                  const SizedBox(height: 8),
                  ..._buildDynamicPrizeSections(theme, result),
                  const SizedBox(height: 8),
                  _buildContactSection(theme),
                  const SizedBox(height: 16),
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

    final orderedPrizes = result.getOrderedPrizes();

    for (final prize in orderedPrizes) {
      if (prize.prizeType == 'consolation') {
        sections.add(_buildConsolationSection(theme, prize));
      } else if (prize.isSingleTicket && prize.placeUsed) {
        sections.add(_buildSinglePrizeWithLocationSection(theme, prize));
      } else if (prize.isSingleTicket && !prize.placeUsed) {
        sections.add(_buildSinglePrizeSection(theme, prize));
      } else {
        sections.add(_buildMultiplePrizeSection(theme, prize));
      }
      sections.add(const SizedBox(height: 8));
    }

    return sections;
  }

  Widget _buildSinglePrizeWithLocationSection(
      ThemeData theme, PrizeModel prize) {
    final ticketNumber = prize.ticketNumbersList.first;
    final isHighlighted =
        _isHighlighted(ticketNumber, prize.prizeTypeFormatted);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: isHighlighted
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            color: isHighlighted ? Colors.yellow[50] : null,
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  ticketNumber,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isHighlighted ? theme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (prize.place.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    prize.place,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumber = prize.ticketNumbersList.first;
    final isHighlighted =
        _isHighlighted(ticketNumber, prize.prizeTypeFormatted);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: isHighlighted
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            color: isHighlighted ? Colors.yellow[50] : null,
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  ticketNumber,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isHighlighted ? theme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplePrizeSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = prize.ticketNumbersList;

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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNumberGrid(
                    ticketNumbers, theme, prize.prizeTypeFormatted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationSection(ThemeData theme, PrizeModel prize) {
    final ticketNumbers = prize.ticketNumbersList;

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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Text(
                  prize.formattedPrizeAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildConsolationGrid(
                    ticketNumbers, theme, prize.prizeTypeFormatted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolationGrid(
      List<String> numbers, ThemeData theme, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _createConsolationRows(numbers, theme, category),
      ),
    );
  }

  List<TableRow> _createConsolationRows(
      List<String> numbers, ThemeData theme, String category) {
    List<TableRow> rows = [];

    for (int i = 0; i < numbers.length; i += 2) {
      if (i + 1 < numbers.length) {
        rows.add(
          TableRow(
            children: [
              _buildConsolationCell(numbers[i], theme, category),
              _buildConsolationCell(numbers[i + 1], theme, category),
            ],
          ),
        );
      } else {
        rows.add(
          TableRow(
            children: [
              _buildConsolationCell(numbers[i], theme, category),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(''),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildConsolationCell(
      String number, ThemeData theme, String category) {
    final isHighlighted = _isHighlighted(number, category);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.yellow[100] : null,
          borderRadius: isHighlighted ? BorderRadius.circular(6) : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: theme.textTheme.bodyMedium!.copyWith(
            color: isHighlighted ? theme.primaryColor : null,
            fontWeight: isHighlighted ? FontWeight.bold : null,
            fontSize: isHighlighted ? 18 : 14,
          ),
          child: Text(
            number,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberGrid(
      List<String> numbers, ThemeData theme, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _createNumberRows(numbers, theme, category),
      ),
    );
  }

  List<TableRow> _createNumberRows(
      List<String> numbers, ThemeData theme, String category) {
    List<TableRow> rows = [];

    for (int i = 0; i < numbers.length; i += 4) {
      List<Widget> cells = [];

      for (int j = 0; j < 4; j++) {
        if (i + j < numbers.length) {
          final number = numbers[i + j];
          final isHighlighted = _isHighlighted(number, category);

          cells.add(
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.yellow[50] : null,
                  borderRadius: isHighlighted ? BorderRadius.circular(4) : null,
                ),
                child: Text(
                  number,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHighlighted ? theme.primaryColor : null,
                    fontWeight: isHighlighted ? FontWeight.bold : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          cells.add(
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(''),
            ),
          );
        }
      }

      rows.add(TableRow(children: cells));
    }

    return rows;
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
                child: Text(
                  highlightedItem['location'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
