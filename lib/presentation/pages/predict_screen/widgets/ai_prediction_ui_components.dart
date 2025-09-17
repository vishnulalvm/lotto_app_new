import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/services/lottery_info_service.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_state.dart';

/// Reusable UI components for AI Prediction Card
class AIPredictionUIComponents {

  /// Builds the header with lottery name and AI icon
  static Widget buildHeader(ThemeData theme) {
    final lotteryName = LotteryInfoService.getLotteryNameForToday();
    
    return Row(
      children: [
        AIIconContainer(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'ai_predicted_numbers'.tr(namedArgs: {'lottery': lotteryName}),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the prize type selector dropdown
  static Widget buildPrizeTypeSelector(
    ThemeData theme,
    int selectedPrizeType,
    ValueChanged<int?> onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedPrizeType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
          items: LotteryInfoService.getAvailablePrizeTypes().map((prizeType) {
            return DropdownMenuItem<int>(
              value: prizeType,
              child: PrizeTypeDropdownItem(prizeType: prizeType),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Builds the loading indicator
  static Widget buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Builds the error state widget
  static Widget buildErrorState(ThemeData theme, String? errorMessage) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'failed_to_generate_predictions'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the numbers grid
  static Widget buildNumbersGrid(ThemeData theme, List<String> numbers) {
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
      itemBuilder: (context, index) => PredictionNumberTile(
        number: numbers[index],
        theme: theme,
      ),
    );
  }

  /// Builds the footer with prediction count
  static Widget buildFooter(ThemeData theme, int predictionCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'predictions_generated'.tr(namedArgs: {'count': predictionCount.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            '✨',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds content based on state
  static Widget buildStateContent(ThemeData theme, AIPredictionState state) {
    return switch (state) {
      AIPredictionLoading() => buildLoadingIndicator(),
      AIPredictionError(:final message) => buildErrorState(theme, message),
      AIPredictionLoaded(:final prediction, :final predictionCount) => Column(
          children: [
            buildNumbersGrid(theme, prediction.predictedNumbers),
            const SizedBox(height: 16),
            buildFooter(theme, predictionCount),
          ],
        ),
      AIPredictionInitial() => buildLoadingIndicator(),
    };
  }
}

/// Stateless widget for AI icon container
class AIIconContainer extends StatelessWidget {
  const AIIconContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

/// Stateless widget for prize type dropdown items
class PrizeTypeDropdownItem extends StatelessWidget {
  final int prizeType;

  const PrizeTypeDropdownItem({
    super.key,
    required this.prizeType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedPrizeType = LotteryInfoService.getPrizeTypeFormatted(prizeType);
    
    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          formattedPrizeType,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Stateless widget for individual prediction number tiles
class PredictionNumberTile extends StatelessWidget {
  final String number;
  final ThemeData theme;

  const PredictionNumberTile({
    super.key,
    required this.number,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
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
  }
}