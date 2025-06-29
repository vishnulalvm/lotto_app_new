import 'package:flutter/material.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  List<String> predictedNumbers = [];
  String selectedLottery = 'Akshaya AK';

  final List<String> lotteryTypes = [
    'Akshaya AK',
    'Win Win',
    'Nirmal NR',
    'Karunya KR',
    'Karunya Plus KN',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLotterySelector(theme),
              const SizedBox(height: 24),
              _buildPredictionCard(theme),
              const SizedBox(height: 24),
              _buildHistorySection(theme),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePrediction,
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
        foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
        icon: const Icon(Icons.auto_awesome),
        label: Text('generate_numbers'.tr()),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'predict_numbers'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLotterySelector(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_lottery_type'.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLottery,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: lotteryTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedLottery = newValue;
                    predictedNumbers.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'predicted_numbers'.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            if (predictedNumbers.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: theme.primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'tap_generate_lucky_numbers'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildNumberGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: predictedNumbers.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              predictedNumbers[index],
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'hot_numbers'.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildHotNumbersList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHotNumbersList(ThemeData theme) {
    // Sample hot numbers data
    final hotNumbers = [
      {'number': 'AB 123456', 'frequency': '15%'},
      {'number': 'CD 789012', 'frequency': '12%'},
      {'number': 'EF 345678', 'frequency': '10%'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hotNumbers.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            hotNumbers[index]['number']!,
            style: theme.textTheme.bodyLarge,
          ),
          trailing: Text(
            hotNumbers[index]['frequency']!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _generatePrediction() {
    final random = Random();
    setState(() {
      predictedNumbers = List.generate(6, (index) {
        // Generate two letters followed by six digits
        String letters = String.fromCharCodes(
          List.generate(2, (_) => random.nextInt(26) + 65),
        );
        String numbers = List.generate(6, (_) => random.nextInt(10))
            .join();
        return '$letters $numbers';
      });
    });
  }
}