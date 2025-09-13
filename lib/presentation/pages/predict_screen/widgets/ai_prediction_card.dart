import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotto_app/data/models/predict_screen/ai_prediction_model.dart';
import 'package:lotto_app/data/services/ai_prediction_service.dart';

class AiPredictionCard extends StatefulWidget {
  const AiPredictionCard({super.key});

  @override
  State<AiPredictionCard> createState() => _AiPredictionCardState();
}

class _AiPredictionCardState extends State<AiPredictionCard> {
  int _selectedPrizeType = 5; // Default to 5th prize
  AiPredictionModel? _currentPrediction;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prediction = await AiPredictionService.getTodaysPrediction(_selectedPrizeType);
      setState(() {
        _currentPrediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onPrizeTypeChanged(int? newPrizeType) async {
    if (newPrizeType != null && newPrizeType != _selectedPrizeType) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedPrizeType = newPrizeType;
      });
      await _loadPrediction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildPrizeTypeSelector(theme),
            const SizedBox(height: 20),
            _buildPredictionContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'AI Predicted Numbers',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Select Prize Type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedPrizeType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
              items: [5, 6, 7, 8, 9].map((int prizeType) {
                return DropdownMenuItem<int>(
                  value: prizeType,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prizeType${_getOrdinalSuffix(prizeType)} Prize',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onPrizeTypeChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    switch (number) {
      case 5:
        return 'th';
      case 6:
        return 'th';
      case 7:
        return 'th';
      case 8:
        return 'th';
      case 9:
        return 'th';
      default:
        return 'th';
    }
  }

  Widget _buildPredictionContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentPrediction == null) {
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
              'Failed to generate predictions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildNumbersGrid(theme, _currentPrediction!.predictedNumbers),
        const SizedBox(height: 16),
        _buildFooter(theme),
      ],
    );
  }

  Widget _buildNumbersGrid(ThemeData theme, List<String> numbers) {
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
              numbers[index],
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

  Widget _buildFooter(ThemeData theme) {
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
            '12 predictions generated ',
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
}