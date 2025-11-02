import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

class JustMissScreen extends StatelessWidget {
  final TicketCheckResponseModel result;

  const JustMissScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final justMissData = result.previousResult.justMissData;

    // If no just miss data, show error message
    if (justMissData == null || !justMissData.hasAnyMatches) {
      return Scaffold(
        appBar: AppBar(
          title: Text('just_miss'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'no_data_available'.tr(),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('just_miss'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            _buildHeaderCard(context, theme, screenWidth),

            SizedBox(height: screenHeight * 0.02),

            // Just Miss for Shuffle
            if (justMissData.shuffleMatches.isNotEmpty)
              _buildJustMissSection(
                context,
                theme,
                screenWidth,
                'just_miss_for_shuffle'.tr(),
                justMissData.shuffleMatches,
              ),

            if (justMissData.shuffleMatches.isNotEmpty)
              SizedBox(height: screenHeight * 0.02),

            // Just Miss for One Number
            if (justMissData.oneNumberMatches.isNotEmpty)
              _buildJustMissSection(
                context,
                theme,
                screenWidth,
                'just_miss_for_one_number'.tr(),
                justMissData.oneNumberMatches,
              ),

            if (justMissData.oneNumberMatches.isNotEmpty)
              SizedBox(height: screenHeight * 0.02),

            // Just Miss for Two Number
            if (justMissData.twoNumberMatches.isNotEmpty)
              _buildJustMissSection(
                context,
                theme,
                screenWidth,
                'just_miss_for_two_number'.tr(),
                justMissData.twoNumberMatches,
              ),

            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    double screenWidth,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lottery name and date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  result.lotteryName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result.previousResult.date,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'draw'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    result.previousResult.drawNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ticket'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    result.ticketNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJustMissSection(
    BuildContext context,
    ThemeData theme,
    double screenWidth,
    String title,
    List<JustMissMatch> matches,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;
    final headerColor = theme.colorScheme.primaryContainer;
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Ticket number header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 8,
            ),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              result.ticketNumber,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Matches list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildMatchItem(theme, screenWidth, match);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(
    ThemeData theme,
    double screenWidth,
    JustMissMatch match,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ticket number
          Expanded(
            flex: 2,
            child: Text(
              match.ticketNumber,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),

          // Prize info
          Expanded(
            flex: 3,
            child: Text(
              '${match.prizeType} ${match.formattedPrize}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
