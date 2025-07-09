import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/repeated_number.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/yesterday_accuracy_widget.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  String? selectedPrizeType = '1st'; // Default to 1st prize
  String? selectedLotteryType; // Add this for lottery selection
  late AnimationController _typewriterController;
  bool _isDisclaimerExpanded = false;

  final List<String> prizeTypes = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th'
  ];
final List<Map<String, String>> lotteryTypes = [
  {'value': 'SAMRUDHI', 'label_key': 'samrudhi_sunday'},
  {'value': 'BHAGYATHARA', 'label_key': 'bhagyathara_monday'},
  {'value': 'STHREE SAKTHI', 'label_key': 'sthree_sakthi_tuesday'},
  {'value': 'DHANALEKSHMI', 'label_key': 'dhanalekshmi_wednesday'},
  {'value': 'KARUNYA PLUS', 'label_key': 'karunya_plus_thursday'},
  {'value': 'SUVARNA KERALAM', 'label_key': 'suvarna_keralam_friday'},
  {'value': 'KARUNYA', 'label_key': 'karunya_saturday'},
];

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    selectedLotteryType = _getLotteryNameForToday();

    // Auto-generate with default prize type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePrediction(_getLotteryNameForToday());
    });
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  String _getLotteryNameForToday() {
    final now = DateTime.now();
    final weekday = now.weekday;

    switch (weekday) {
      case DateTime.sunday:
        return 'SAMRUDHI';
      case DateTime.monday:
        return 'BHAGYATHARA';
      case DateTime.tuesday:
        return 'STHREE SAKTHI';
      case DateTime.wednesday:
        return 'DHANALEKSHMI';
      case DateTime.thursday:
        return 'KARUNYA PLUS';
      case DateTime.friday:
        return 'SUVARNA KERALAM';
      case DateTime.saturday:
        return 'KARUNYA';
      default:
        return 'KARUNYA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todaysLottery = _getLotteryNameForToday();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, todaysLottery),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLotteryTypeSelector(theme), // Add this new widget
                    const SizedBox(height: 10),
                    _buildPrizeTypeSelector(theme),
                    const SizedBox(height: 10),
                    _buildPredictionCard(theme),
                    const SizedBox(height: 10),
                    _buildMostRepeatedCard(theme),
                    const SizedBox(height: 10),
                    _buildYesterdayAccuracyCard(theme), // Add this line
                  ],
                ),
              ),
            ),
          ),
          _buildBottomDisclaimer(theme),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, String lotteryName) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () => context.go('/'),
      ),
      title: Text(
        'predict'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // New lottery type selector widget
  Widget _buildLotteryTypeSelector(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Lottery Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLotteryType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: theme.primaryColor.withOpacity(0.05),
                prefixIcon: Icon(
                  Icons.confirmation_number,
                  color: theme.primaryColor.withOpacity(0.7),
                ),
              ),
              items: lotteryTypes.map((Map<String, String> lottery) {
                return DropdownMenuItem<String>(
                  value: lottery['value'],
                  child: Text(
                    lottery['label_key']!.tr(), // Translate the label here
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLotteryType = newValue;
                });
                if (newValue != null && selectedPrizeType != null) {
                  _generatePrediction(newValue);
                }
              },
              hint: Text(
                'choose_lottery_type'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeTypeSelector(ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'select_prize_type'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPrizeType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: theme.primaryColor.withValues(alpha: 0.05),
                prefixIcon: Icon(
                  Icons.star,
                  color: Colors.amber[600],
                ),
              ),
              items: prizeTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    '$type Prize',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPrizeType = newValue;
                });
                // Auto-generate when prize type changes
                if (newValue != null && selectedLotteryType != null) {
                  _generatePrediction(selectedLotteryType!);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'predicted_numbers'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BlocBuilder<PredictBloc, PredictState>(
              builder: (context, state) {
                if (state is PredictInitial) {
                  return _buildEmptyState(theme);
                } else if (state is PredictLoading) {
                  return _buildLoadingState(theme);
                } else if (state is PredictLoaded) {
                  return _buildNumberGridWithTypewriter(
                      theme, state.prediction.predictedNumbers);
                } else if (state is PredictError) {
                  return _buildErrorState(theme, state.message);
                }
                return _buildEmptyState(theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating your lucky numbers...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Generating predictions...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberGridWithTypewriter(ThemeData theme, List<String> numbers) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: numbers.length == 1 ? 1 : 3,
            childAspectRatio: numbers.length == 1 ? 3 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: numbers.length,
          itemBuilder: (context, index) {
            return TypewriterNumberCard(
              number: numbers[index],
              theme: theme,
              delay: Duration(milliseconds: index * 150),
              fontSize: numbers.length == 1 ? 20 : 16,
            );
          },
        ),
        // const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${numbers.length} prediction${numbers.length > 1 ? 's' : ''} generated ✨',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _generatePrediction(_getLotteryNameForToday()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostRepeatedCard(ThemeData theme) {
    return BlocBuilder<PredictBloc, PredictState>(
      builder: (context, state) {
        List<String> repeatedNumbers = [];

        if (state is PredictLoaded) {
          repeatedNumbers = state.prediction.repeatedNumbers;
        }

        return _buildRepeatedNumbersContent(theme, repeatedNumbers);
      },
    );
  }

  Widget _buildRepeatedNumbersContent(
      ThemeData theme, List<String> repeatedNumbers) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'most_repeated_last_4_digits'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (repeatedNumbers.isEmpty)
              _buildEmptyRepeatedState(theme)
            else
              _buildRepeatedNumbersGrid(theme, repeatedNumbers),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRepeatedState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              size: 32,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No repeated numbers available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate predictions to see historical patterns',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatedNumbersGrid(
      ThemeData theme, List<String> repeatedNumbers) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: repeatedNumbers.length == 1 ? 1 : 3,
            childAspectRatio: repeatedNumbers.length == 1 ? 3 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: repeatedNumbers.length,
          itemBuilder: (context, index) {
            return RepeatedNumberCard(
              number: repeatedNumbers[index],
              theme: theme,
              delay: Duration(milliseconds: index * 100),
              fontSize: repeatedNumbers.length == 1 ? 20 : 16,
            );
          },
        ),
        // const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${repeatedNumbers.length} historical pattern${repeatedNumbers.length > 1 ? 's' : ''} found 📊',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDisclaimer(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Colors.amber.withValues(alpha: _isDisclaimerExpanded ? 0.1 : 0.05),
        border: Border(
          top: BorderSide(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimal disclaimer bar
            InkWell(
              onTap: () {
                setState(() {
                  _isDisclaimerExpanded = !_isDisclaimerExpanded;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For entertainment only • Tap for details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isDisclaimerExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable detailed content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isDisclaimerExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDisclaimerPoint(
                        theme,
                        '🎲',
                        'Entertainment Purpose',
                        'Predictions are for fun and should not guide financial decisions.',
                      ),
                      const SizedBox(height: 8),
                      _buildDisclaimerPoint(
                        theme,
                        '📊',
                        'Statistical Analysis',
                        'Based on historical data, but lottery outcomes remain random.',
                      ),
                      const SizedBox(height: 8),
                      _buildDisclaimerPoint(
                        theme,
                        '⚠️',
                        'Play Responsibly',
                        'Past patterns don\'t guarantee future results.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesterdayAccuracyCard(ThemeData theme) {
    return BlocBuilder<PredictBloc, PredictState>(
      builder: (context, state) {
        YesterdayPredictionAccuracy? accuracyData;

        if (state is PredictLoaded) {
          accuracyData = state.prediction.yesterdayPredictionAccuracy;
        }

        return _buildAccuracyContent(theme, accuracyData);
      },
    );
  }

  Widget _buildAccuracyContent(
      ThemeData theme, YesterdayPredictionAccuracy? accuracyData) {
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'yesterdays_prediction_accuracy'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (accuracyData != null) ...[
              const SizedBox(height: 16),
              _buildAccuracySummary(
                  theme, accuracyData.summary, accuracyData.date),
              const SizedBox(height: 20),
              YesterdayAccuracyWidget(
                digitAccuracy: accuracyData.digitAccuracy,
                theme: theme,
              ),
            ] else
              _buildEmptyAccuracyState(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracySummary(
      ThemeData theme, AccuracySummary summary, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: $date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perfect Matches: ${summary.perfectMatchCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${summary.overallAccuracyPercent.toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAccuracyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 32,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No accuracy data available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate predictions to see yesterday\'s accuracy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerPoint(
      ThemeData theme, String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[800],
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _generatePrediction(String lotteryName) {
    if (selectedPrizeType == null) return;

    context.read<PredictBloc>().add(
          GetPredictionEvent(
            lotteryName: lotteryName,
            prizeType: selectedPrizeType!,
          ),
        );
  }
}

// Custom Typewriter Number Card Widget
class TypewriterNumberCard extends StatefulWidget {
  final String number;
  final ThemeData theme;
  final Duration delay;
  final double fontSize;

  const TypewriterNumberCard({
    super.key,
    required this.number,
    required this.theme,
    required this.delay,
    required this.fontSize,
  });

  @override
  State<TypewriterNumberCard> createState() => _TypewriterNumberCardState();
}

class _TypewriterNumberCardState extends State<TypewriterNumberCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.number.length * 100),
      vsync: this,
    );

    _characterCount = StepTween(
      begin: 0,
      end: widget.number.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.primaryColor.withValues(alpha: 0.8),
              widget.theme.primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: widget.theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _characterCount,
            builder: (context, child) {
              String displayText =
                  widget.number.substring(0, _characterCount.value);
              bool showCursor = _controller.isAnimating &&
                  _characterCount.value < widget.number.length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayText,
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showCursor)
                    AnimatedOpacity(
                      opacity: (_controller.value * 2) % 1 > 0.5 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 100),
                      child: Text(
                        '|',
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: widget.fontSize,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
