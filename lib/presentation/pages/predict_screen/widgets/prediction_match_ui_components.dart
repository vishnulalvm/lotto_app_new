import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/predict_screen/prediction_match_model.dart';

/// UI components for the PredictionMatchCard widget
class PredictionMatchUIComponents {

  /// Builds the loading indicator
  static Widget buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Builds the no data widget (results not published)
  static Widget buildNoDataWidget(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'results_not_published_yet'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the no match widget (no winning numbers matched)
  static Widget buildNoMatchWidget(ThemeData theme, PredictionMatchModel matchResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with lottery name
        Text(
          'prediction_match_numbers_title'.tr(namedArgs: {
            'lottery': matchResult.lotteryName,
            'prizeType': '5th-9th',
          }),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // No matches message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No matches found in any prize type (5th-9th)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the match found widget (some numbers matched)
  static Widget buildMatchFoundWidget(ThemeData theme, PredictionMatchModel matchResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with lottery name
        Text(
          'prediction_match_numbers_title'.tr(namedArgs: {
            'lottery': matchResult.lotteryName,
            'prizeType': '5th-9th',
          }),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Prize type chips showing which types had matches
        _buildPrizeTypeChips(theme, matchResult.matchedPrizeTypes),
        const SizedBox(height: 16),

        // Match summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green[700]!,
              width: .5,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.celebration, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${matchResult.matchedNumbers.length} winning numbers found!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Show only matched numbers in grid
        _buildMatchedNumbersGrid(theme, matchResult.matchedNumbersWithPrizeType),
        const SizedBox(height: 16),

        // View Results button — opens LotteryResultDetailsScreen with first matched number highlighted
        _buildViewResultsButton(theme, matchResult),
      ],
    );
  }

  /// Navigates to LotteryResultDetailsScreen and highlights the first matched number
  static Widget _buildViewResultsButton(ThemeData theme, PredictionMatchModel matchResult) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final firstMatch = matchResult.matchedNumbers.isNotEmpty
                  ? matchResult.matchedNumbers.first
                  : null;
              context.go('/result-details', extra: {
                'uniqueId': matchResult.uniqueId,
                'lotteryNumber': firstMatch,
                'isNew': false,
              });
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Full Results'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green[700],
              side: BorderSide(color: Colors.green[700]!, width: .5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  // Private helper methods

  /// Builds prize type chips showing which types had matches
  static Widget _buildPrizeTypeChips(ThemeData theme, List<String> matchedPrizeTypes) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: matchedPrizeTypes.map((prizeType) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.blue[700]!,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$prizeType Prize',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds a grid showing only matched numbers with their prize types
  static Widget _buildMatchedNumbersGrid(ThemeData theme, Map<String, String> matchedNumbersWithPrizeType) {
    final entries = matchedNumbersWithPrizeType.entries.toList();
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final borderColor = Colors.green[700]!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final number = entry.key;
        final prizeType = entry.value;

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                prizeType,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: borderColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}