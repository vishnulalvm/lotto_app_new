import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/services/weekly_fancy_match_service.dart';

class WeeklyFancyNumberCard extends StatefulWidget {
  const WeeklyFancyNumberCard({super.key});

  @override
  State<WeeklyFancyNumberCard> createState() => _WeeklyFancyNumberCardState();
}

class _WeeklyFancyNumberCardState extends State<WeeklyFancyNumberCard> {
  List<String> _fancyNumbers = [];
  List<FancyNumberMatch> _matches = [];
  int _currentDay = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check and update matches first
      await WeeklyFancyMatchService.checkAndUpdateMatches();

      // Load current week's numbers
      final numbers = await WeeklyFancyMatchService.getCurrentWeekNumbers();
      final matches = await WeeklyFancyMatchService.getMatches();
      final day = await WeeklyFancyMatchService.getCurrentDayOfWeek();

      setState(() {
        _fancyNumbers = numbers;
        _matches = matches;
        _currentDay = day;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: Colors.purple[300]!,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: Colors.purple[400],
                  ),
                ),
              )
            else
              _buildNumbersGrid(theme),
            const SizedBox(height: 12),
            _buildWeekInfo(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.stars,
          color: Colors.purple[700],
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'weekly_fancy_numbers'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'day_counter'.tr(namedArgs: {'day': _currentDay.toString()}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumbersGrid(ThemeData theme) {
    // Get matched numbers
    final matchedNumbers = <FancyNumberMatch>[];
    for (final match in _matches) {
      if (match.lotteryName.isNotEmpty && _fancyNumbers.contains(match.number)) {
        matchedNumbers.add(match);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: All numbers display
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _fancyNumbers.map((number) {
            final hasMatch = matchedNumbers.any((m) => m.number == number);
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 28 - 20) / 5,
              child: _buildSimpleNumberCell(theme, number, hasMatch),
            );
          }).toList(),
        ),

        // Section 2: Matched numbers (if any)
        if (matchedNumbers.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildMatchedSection(theme, matchedNumbers),
        ],
      ],
    );
  }

  Widget _buildSimpleNumberCell(ThemeData theme, String number, bool hasMatch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasMatch
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.purple[400]!, Colors.pink[400]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (hasMatch ? Colors.green : Colors.purple).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchedSection(ThemeData theme, List<FancyNumberMatch> matches) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(
          color: Colors.green[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Matched Numbers',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${matches.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...matches.map((match) => _buildMatchItem(theme, match)),
        ],
      ),
    );
  }

  Widget _buildMatchItem(ThemeData theme, FancyNumberMatch match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.number,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.lotteryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      match.prizeType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(match.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.purple[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'week_resets_on'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.purple[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
