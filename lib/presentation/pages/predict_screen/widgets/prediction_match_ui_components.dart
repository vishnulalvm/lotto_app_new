import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/predict_screen/prediction_match_model.dart';
import 'package:lotto_app/data/services/prediction_match_service.dart';

/// UI components for the PredictionMatchCard widget
class PredictionMatchUIComponents {
  

  /// Builds the waiting widget shown before 4:30 PM
  static Widget buildWaitingWidget(ThemeData theme) {
    final waitTimeText = PredictionMatchService.getTimeUntilResults();

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 12),
          Text(
            'results_available_after_430'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'check_back_in_time'.tr(namedArgs: {'time': waitTimeText}),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildInfoBox(theme),
        ],
      ),
    );
  }

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
    final lotteryName = PredictionMatchService.getLotteryNameForToday();
    final prizeTypeString = _getPrizeTypeString(matchResult.prediction.prizeType);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'prediction_match_numbers_title'.tr(namedArgs: {
            'lottery': lotteryName,
            'prizeType': prizeTypeString,
          }),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Better prediction tomorrow message
        _buildBetterPredictionMessage(theme),
        const SizedBox(height: 16),
        // Show all predicted numbers with no highlighting
        _buildPredictionNumbersGrid(theme, matchResult.prediction.predictedNumbers, []),
      ],
    );
  }

  /// Builds the match found widget (some numbers matched)
  static Widget buildMatchFoundWidget(ThemeData theme, PredictionMatchModel matchResult) {
    final lotteryName = PredictionMatchService.getLotteryNameForToday();
    final prizeTypeString = _getPrizeTypeString(matchResult.prediction.prizeType);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'prediction_match_numbers_title'.tr(namedArgs: {
            'lottery': lotteryName,
            'prizeType': prizeTypeString,
          }),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Show predicted numbers with matched ones highlighted
        _buildPredictionNumbersGrid(theme, matchResult.prediction.predictedNumbers, matchResult.matchedNumbers),
      ],
    );
  }

  // Private helper methods

  static Widget _buildInfoBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'prediction_match_info'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "better prediction tomorrow" message
  static Widget _buildBetterPredictionMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            size: 24,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Better prediction tomorrow',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds prediction numbers in a grid similar to AI prediction style
  static Widget _buildPredictionNumbersGrid(ThemeData theme, List<String> numbers, List<String> matchedNumbers) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];
        final isMatched = matchedNumbers.contains(number);
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMatched 
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isMatched ? Colors.green : Colors.red).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }


  static String _getPrizeTypeString(int prizeType) {
    switch (prizeType) {
      case 5:
        return '5th';
      case 6:
        return '6th';
      case 7:
        return '7th';
      case 8:
        return '8th';
      case 9:
        return '9th';
      default:
        return '5th';
    }
  }
}