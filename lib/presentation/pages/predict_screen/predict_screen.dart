import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/lucky_number_dialog.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_card.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/prediction_match_card.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/pattern_statistics_card.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'dart:async';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  bool _isDisclaimerExpanded = false;
  Timer? _adTimer;
  int _selectedPrizeType = 5; // Shared state for synchronizing components
  final _predictionMatchCardKey = GlobalKey<PredictionMatchCardState>();

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'predict_screen',
          screenClass: 'PredictScreen',
          parameters: {
            'lottery_name': _getLotteryNameForToday(),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });

    // Load prediction data and check if lucky number dialog should be shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictBloc>().add(const GetPredictionDataEvent());
      _checkAndShowLuckyNumberDialog();
      _preloadAndScheduleInterstitialAd();
    });
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  String _getLotteryNameForToday() {
    final now = DateTime.now();
    
    // If it's before 3 PM, show today's lottery
    // If it's after 3 PM, show tomorrow's lottery
    final targetDate = now.hour >= 15 ? now.add(const Duration(days: 1)) : now;
    final weekday = targetDate.weekday;

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
      body: BlocBuilder<PredictBloc, PredictState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: _buildBody(theme, state),
              ),
              _buildBottomDisclaimer(theme),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, String lotteryName) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.go('/');
        },
      ),
      title: Text(
        'predict'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBody(ThemeData theme, PredictState state) {
    if (state is PredictLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is PredictError) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<PredictBloc>().add(const GetPredictionDataEvent());
          // Wait a bit for the state to update
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'failed_to_load_prediction_data'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.read<PredictBloc>().add(const GetPredictionDataEvent());
                    },
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state is PredictDataLoaded) {
      final data = state.displayData;
      return _buildDataContentWithRefresh(theme, data);
    }

    if (state is PredictDataWithUserPrediction) {
      final data = state.displayData;
      return _buildDataContentWithRefresh(
        theme,
        data,
        userPredictionState: state,
      );
    }

    if (state is PredictLoaded) {
      final data = state.prediction;
      return _buildDataContentWithRefresh(theme, data);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PredictBloc>().add(const GetPredictionDataEvent());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Text('no_data_available'.tr()),
          ),
        ),
      ),
    );
  }

  Widget _buildDataContentWithRefresh(
    ThemeData theme,
    PredictResponseModel data, {
    PredictDataWithUserPrediction? userPredictionState,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PredictBloc>().add(const GetPredictionDataEvent());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (userPredictionState != null)
              _buildUserPredictionResult(theme, userPredictionState),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMotivationalBanner(theme),
                  const SizedBox(height: 10),
                  _buildPeoplePredictionsCard(theme, data.peoplesPredictions),
                  const SizedBox(height: 5),
                  _buildMostRepeatedLast7DaysCard(theme, data.repeatedSingleDigits),
                  const SizedBox(height: 5),
                  _buildMostRepeatedLast2DigitsCard(theme, data.repeatedTwoDigits),
                  const SizedBox(height: 5),
                  _buildMostRepeatedCard(theme, data.repeatedNumbers),
                  const SizedBox(height: 5),
                  const PatternStatisticsCard(
                    showMockData: true,
                    // forceEmptyState: true, // Uncomment to test empty state
                  ),
                  const SizedBox(height: 5),
                  AiPredictionCard(
                    initialPrizeType: _selectedPrizeType,
                    onPrizeTypeChanged: (newPrizeType) {
                      // Update shared state but don't rebuild entire widget tree
                      _selectedPrizeType = newPrizeType;
                      // Notify PredictionMatchCard of the change
                      _predictionMatchCardKey.currentState?.updatePrizeType(newPrizeType);
                    },
                  ),
                  const SizedBox(height: 5),
                  PredictionMatchCard(
                    key: _predictionMatchCardKey,
                    selectedPrizeType: _selectedPrizeType,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPredictionResult(
      ThemeData theme, PredictDataWithUserPrediction state) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'your_lucky_number'.tr(namedArgs: {'number': state.selectedNumber}),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'prediction_submitted_successfully'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.2),
            theme.primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Use App Daily for More Accurate Predictions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Regular usage helps our AI learn your preferences and improve prediction accuracy',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Last 7 days most repeated numbers
  Widget _buildMostRepeatedLast7DaysCard(
      ThemeData theme, List<RepeatedSingleDigit> data) {
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
                  Icons.trending_up,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'last_7_days_most_repeated_last_digit'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSingleDigitsRow(
                theme,
                data.map((e) => {'number': e.digit, 'count': e.count}).toList(),
                null,
                false,
                true),
          ],
        ),
      ),
    );
  }

  // Top 6 Last 2 Digits from cached data
  Widget _buildMostRepeatedLast2DigitsCard(
      ThemeData theme, List<RepeatedTwoDigit> data) {
    // If no data, don't show the card
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icons.stars,
                  color: Colors.purple[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'top_6_last_2_digits'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTwoDigitsRow(
                theme,
                data.map((e) => {'number': e.digits, 'count': e.count}).toList()),
          ],
        ),
      ),
    );
  }

  // Helper method to build two digits in a responsive grid with purple theme
  Widget _buildTwoDigitsRow(ThemeData theme, List<Map<String, dynamic>> numberData) {
    return Column(
      children: [
        // Use GridView for better responsiveness
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            childAspectRatio: 1.4, // Width to height ratio
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: numberData.length,
          itemBuilder: (context, index) {
            final data = numberData[index];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[800]!, Colors.purple[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data['number'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'count_times'.tr(namedArgs: {'count': data['count'].toString()}),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'two_digits_found'.tr(namedArgs: {'count': numberData.length.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.purple[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // People predictions section
  Widget _buildPeoplePredictionsCard(
      ThemeData theme, List<PeoplesPrediction> data) {
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
                  Icons.people,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'people_predictions'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSingleDigitsRow(
                theme,
                data.map((e) => {'number': e.digit, 'count': e.count}).toList(),
                null,
                true),
          ],
        ),
      ),
    );
  }

  // Helper method to build single digits in a row
  Widget _buildSingleDigitsRow(ThemeData theme,
      List<Map<String, dynamic>> numberData, MaterialColor? color,
      [bool isDarkGreen = false, bool isDarkBlue = false]) {
    return Column(
      children: [
        Row(
          children: numberData.map((data) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkGreen
                        ? [Colors.green[800]!, Colors.green[900]!]
                        : isDarkBlue
                            ? [Colors.blue[800]!, Colors.blue[900]!]
                            : [
                                color!.withValues(alpha: 0.8),
                                color,
                              ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkGreen || isDarkBlue
                          ? Colors.black.withValues(alpha: 0.3)
                          : color!.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['number'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'count_times'.tr(namedArgs: {'count': data['count'].toString()}),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkGreen
                ? Colors.green.withValues(alpha: 0.1)
                : isDarkBlue
                    ? Colors.blue.withValues(alpha: 0.1)
                    : color!.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'digits_found'.tr(namedArgs: {'count': numberData.length.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkGreen
                  ? Colors.green[600]
                  : isDarkBlue
                      ? Colors.blue[600]
                      : color![600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build numbers with count grid
  Widget _buildNumbersWithCountGrid(ThemeData theme,
      List<Map<String, dynamic>> numberData, MaterialColor color) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: numberData.length,
          itemBuilder: (context, index) {
            final data = numberData[index];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[800]!,
                    Colors.orange[900]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['number'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'count_x'.tr(namedArgs: {'count': data['count'].toString()}),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'patterns_found'.tr(namedArgs: {'count': numberData.length.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMostRepeatedCard(ThemeData theme, List<RepeatedNumber> data) {
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
                Expanded(
                  child: Text(
                    'most_repeated_last_4_digits_30_days'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNumbersWithCountGrid(
                theme,
                data
                    .map((e) => {'number': e.number, 'count': e.count})
                    .toList(),
                Colors.orange),
          ],
        ),
      ),
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
                // Provide haptic feedback when disclaimer is toggled
                HapticFeedback.lightImpact();
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
                        'data_driven_predictions_tap_details'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        'important_information'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDisclaimerPoint(
                        theme,
                        '🎯',
                        'pattern_based_analysis'.tr(),
                        'real_data_pattern_analysis'.tr(),
                      ),
                      const SizedBox(height: 8),
                      _buildDisclaimerPoint(
                        theme,
                        '📈',
                        'historical_trends'.tr(),
                        'analyze_previous_results_help_win'.tr(),
                      ),
                      const SizedBox(height: 8),
                      _buildDisclaimerPoint(
                        theme,
                        '⚠️',
                        'responsible_play'.tr(),
                        'no_guaranteed_wins_play_responsibly'.tr(),
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

  Future<void> _checkAndShowLuckyNumberDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayString = '${now.year}-${now.month}-${now.day}';
    final lastShownDate = prefs.getString('lucky_number_dialog_last_shown');
    
    // Check if it's after 3 PM (15:00)
    final isAfter3PM = now.hour >= 15;
    
    // Only show if it's after 3 PM and we haven't shown it today after 3 PM
    if (isAfter3PM && lastShownDate != todayString) {
      // Show dialog after a small delay to ensure screen is loaded
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showLuckyNumberDialog();
        }
      });
    }
  }

  void _showLuckyNumberDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return const LuckyNumberDialog();
      },
    );
  }

  void _preloadAndScheduleInterstitialAd() {
    AdMobService.instance.loadPredictInterstitialAd();

    _adTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _showInterstitialAd();
      }
    });
  }

  void _showInterstitialAd() async {
    if (AdMobService.instance.isPredictInterstitialAdLoaded) {
      await AdMobService.instance.showInterstitialAd('predict_interstitial');
    }
  }
}
