import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:typewritertext/typewritertext.dart';
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
        border: Border.all(
          color: Colors.red[700]!,
          width: .5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedPrizeType,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.red[700]!),
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

  /// Builds the numbers grid with typewriter animation
  static Widget buildNumbersGrid(ThemeData theme, List<String> numbers,
      {bool triggerAnimation = true}) {
    return TypewriterNumbersGrid(
      numbers: numbers,
      theme: theme,
      triggerAnimation: triggerAnimation,
    );
  }

  /// Builds the footer with prediction count
  static Widget buildFooter(ThemeData theme, int predictionCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red[700]!,
          width: .5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'predictions_generated'
                .tr(namedArgs: {'count': predictionCount.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
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
            buildNumbersGrid(theme, prediction.predictedNumbers,
                triggerAnimation: true),
            const SizedBox(height: 12),
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
    return Icon(
      Icons.auto_awesome,
      color: Colors.red[700]!,
      size: 16,
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
    final formattedPrizeType =
        LotteryInfoService.getPrizeTypeFormatted(prizeType);

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

/// Grid widget that generates all numbers with typewriter effect simultaneously
class TypewriterNumbersGrid extends StatefulWidget {
  final List<String> numbers;
  final ThemeData theme;
  final bool triggerAnimation;

  const TypewriterNumbersGrid({
    super.key,
    required this.numbers,
    required this.theme,
    this.triggerAnimation = true,
  });

  @override
  State<TypewriterNumbersGrid> createState() => _TypewriterNumbersGridState();
}

class _TypewriterNumbersGridState extends State<TypewriterNumbersGrid> {
  bool _showAnimation = false;
  late String _gridKey;

  @override
  void initState() {
    super.initState();
    _gridKey = widget.numbers.join(',');
    _startAnimation();
  }

  @override
  void didUpdateWidget(TypewriterNumbersGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    String newKey = widget.numbers.join(',');
    if (_gridKey != newKey) {
      _gridKey = newKey;
      _restartAnimation();
    }
  }

  void _startAnimation() {
    if (widget.triggerAnimation) {
      setState(() {
        _showAnimation = false;
      });
      // Small delay then start all animations simultaneously
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showAnimation = true;
          });
        }
      });
    } else {
      setState(() {
        _showAnimation = true;
      });
    }
  }

  void _restartAnimation() {
    setState(() {
      _showAnimation = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showAnimation = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.numbers.length,
      itemBuilder: (context, index) => PredictionNumberTile(
        key: ValueKey('${_gridKey}_$index'), // Force rebuild on change
        number: widget.numbers[index],
        theme: widget.theme,
        showAnimation: _showAnimation,
      ),
    );
  }
}

/// Individual prediction number tile with typewriter effect
class PredictionNumberTile extends StatelessWidget {
  final String number;
  final ThemeData theme;
  final bool showAnimation;

  const PredictionNumberTile({
    super.key,
    required this.number,
    required this.theme,
    required this.showAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(
          color: Colors.red[700]!,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: showAnimation
            ? TypeWriter.text(
                number,
                duration: const Duration(milliseconds: 50),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : const SizedBox(width: 20, height: 20),
      ),
    );
  }
}
