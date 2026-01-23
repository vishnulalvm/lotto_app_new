import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/lucky_number_dialog.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/ai_prediction_card.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/prediction_match_card.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/pattern_statistics_card.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/weekly_fancy_number_card.dart';
import 'package:lotto_app/presentation/pages/probility_screen/widgets/ai_probability_fab.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/ai_prediction_service.dart';
import 'package:lotto_app/core/helpers/feedback_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late AnimationController _fabAnimationController;
  late ScrollController _scrollController;
  int _selectedPrizeType = 5; // Shared state for synchronizing components
  final _predictionMatchCardKey = GlobalKey<PredictionMatchCardState>();
  bool _isFabVisible = true;

  // State for Number Variants Generator
  late TextEditingController _variantsInputController;
  final List<String> _generatedVariants =
      List.generate(16, (index) => "1256"); // Mock data for UI

  // Interstitial ad cooldown tracking (stored in memory, resets on app restart)
  static DateTime? _lastAdShowTime;
  static const Duration _adCooldownDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _variantsInputController = TextEditingController();

    // Consolidated post-frame callback for all initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Track screen view for analytics
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

      // Load prediction data and check if lucky number dialog should be shown
      context.read<PredictBloc>().add(const GetPredictionDataEvent());
      _checkAndShowLuckyNumberDialog();
      _loadAndShowInterstitialAd();

      // Trigger FAB animation after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _fabAnimationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _typewriterController.dispose();
    _fabAnimationController.dispose();
    _variantsInputController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollDirection = _scrollController.position.userScrollDirection;

    if (scrollDirection == ScrollDirection.reverse) {
      // Scrolling down - hide FAB
      if (_isFabVisible) {
        _isFabVisible = false;
        _fabAnimationController.reverse();
      }
    } else if (scrollDirection == ScrollDirection.forward) {
      // Scrolling up - show FAB
      if (!_isFabVisible) {
        _isFabVisible = true;
        _fabAnimationController.forward();
      }
    }
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
          return _buildBody(theme, state);
        },
      ),
      floatingActionButton: AIProbabilityFAB(
        onPressed: _navigateToProbabilityScanner,
        slideAnimation: _fabAnimationController,
        theme: theme,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      actions: [
        IconButton(
          icon: Icon(Icons.info, color: theme.appBarTheme.iconTheme?.color),
          onPressed: _showDisclaimerBottomSheet,
          tooltip: 'Important Information',
        ),
        BlocBuilder<PredictBloc, PredictState>(
          builder: (context, state) {
            // Only show copy button when data is loaded
            if (state is PredictDataLoaded ||
                state is PredictDataWithUserPrediction ||
                state is PredictLoaded) {
              return IconButton(
                icon:
                    Icon(Icons.copy, color: theme.appBarTheme.iconTheme?.color),
                onPressed: () => _copyPredictionNumbers(state),
                tooltip: 'Copy Numbers',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context
                          .read<PredictBloc>()
                          .add(const GetPredictionDataEvent());
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
        controller: _scrollController,
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
                  RepaintBoundary(child: _buildMotivationalBanner(theme)),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: AiPredictionCard(
                      initialPrizeType: _selectedPrizeType,
                      onPrizeTypeChanged: (newPrizeType) {
                        // Update shared state but don't rebuild entire widget tree
                        _selectedPrizeType = newPrizeType;
                        // Notify PredictionMatchCard of the change
                        _predictionMatchCardKey.currentState
                            ?.updatePrizeType(newPrizeType);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                      child:
                          _buildMostRepeatedCard(theme, data.repeatedNumbers)),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                      child: _buildNumberVariantsGeneratorCard(theme)),
                  const SizedBox(height: 12),
                  const RepaintBoundary(child: WeeklyFancyNumberCard()),
                  const SizedBox(height: 12),
                  const RepaintBoundary(
                    child: PatternStatisticsCard(
                      showMockData: false, // Use real data from API
                    ),
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                      child: _buildPeoplePredictionsCard(
                          theme, data.peoplesPredictions)),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: _buildMostRepeatedLast7DaysCard(
                        theme, data.repeatedSingleDigits),
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: _buildMostRepeatedLast2DigitsCard(
                        theme, data.repeatedTwoDigits),
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    child: PredictionMatchCard(
                      key: _predictionMatchCardKey,
                      selectedPrizeType: _selectedPrizeType,
                    ),
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
                  'your_lucky_number'
                      .tr(namedArgs: {'number': state.selectedNumber}),
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
        color: theme.cardColor,
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
              color: theme.colorScheme.onSurface,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Regular usage helps our AI learn your preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _launchHowToUseVideo(context),
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: Text('how_to_use'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchHowToUseVideo(BuildContext context) async {
    // Add click feedback
    FeedbackHelper.lightClick();

    final url = Uri.parse('https://youtu.be/Odc0kvjWCSs');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('could_not_open_video'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_video'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Last 7 days most repeated numbers
  Widget _buildMostRepeatedLast7DaysCard(
      ThemeData theme, List<RepeatedSingleDigit> data) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
                data
                    .map((e) => {'number': e.digits, 'count': e.count})
                    .toList()),
          ],
        ),
      ),
    );
  }

  // Helper method to build two digits in a responsive grid with purple theme
  Widget _buildTwoDigitsRow(
      ThemeData theme, List<Map<String, dynamic>> numberData) {
    final borderColor = Colors.purple[700]!;
    final textColor = theme.colorScheme.onSurface;

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
                color: theme.scaffoldBackgroundColor,
                border: Border.all(
                  color: borderColor,
                  width: .5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data['number'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: borderColor,
                          width: .5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'count_times'.tr(
                              namedArgs: {'count': data['count'].toString()}),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'two_digits_found'
                .tr(namedArgs: {'count': numberData.length.toString()}),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // People predictions section
  Widget _buildPeoplePredictionsCard(
      ThemeData theme, List<PeoplesPrediction> data) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
    // Determine border color based on the type
    final borderColor = isDarkGreen
        ? Colors.green[700]!
        : isDarkBlue
            ? Colors.blue[700]!
            : color![700]!;

    // Determine text color based on theme
    final textColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        Row(
          children: numberData.map((data) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(
                    color: borderColor,
                    width: .5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['number'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: borderColor,
                            width: .5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'count_times'.tr(
                              namedArgs: {'count': data['count'].toString()}),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
            color: Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'digits_found'
                .tr(namedArgs: {'count': numberData.length.toString()}),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build numbers with count grid
  Widget _buildNumbersWithCountGrid(ThemeData theme,
      List<Map<String, dynamic>> numberData, MaterialColor color) {
    final borderColor = Colors.orange[700]!;
    final textColor = theme.colorScheme.onSurface;

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
                color: theme.scaffoldBackgroundColor,
                border: Border.all(
                  color: borderColor,
                  width: .5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['number'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border.all(
                          color: borderColor,
                          width: .2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'count_times'
                            .tr(namedArgs: {'count': data['count'].toString()}),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
            color: Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'patterns_found'
                .tr(namedArgs: {'count': numberData.length.toString()}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMostRepeatedCard(ThemeData theme, List<RepeatedNumber> data) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
                    'most_winning_numbers_30_days'.tr(),
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

  // Number Variants Generator Card
  Widget _buildNumberVariantsGeneratorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: theme.primaryColor,
          width: .5,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Number Combinations",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.copy,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _variantsInputController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter numbers Eg: 1256",
                      hintStyle: TextStyle(
                        color: theme.hintColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 70, // Adjust based on visual preference
                decoration: BoxDecoration(
                  color: const Color(0xFF6EDC65), // Green color from image
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    // Logic to generate variants will go here
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(
                    Icons.auto_fix_high,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Results Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8, // Gap between chips
                runSpacing: 8, // Gap between lines
                children: _generatedVariants.map((variant) {
                  // Calculate width for 4 items per row accounting for spacing
                  // (Total Width - (3 * spacing)) / 4
                  final double itemWidth = (constraints.maxWidth - (3 * 8)) / 4;

                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      variant,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Total Count Footer
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: theme.primaryColor,
                  width: .5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total ${_generatedVariants.length} Combinations',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimerBottomSheet() {
    HapticFeedback.lightImpact();

    // Track analytics
    AnalyticsService.trackUserEngagement(
      action: 'view_disclaimer',
      category: 'predict_screen',
      label: 'open_disclaimer_bottom_sheet',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.amber[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'important_information'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDisclaimerPoint(
                  theme,
                  '🎯',
                  'pattern_based_analysis'.tr(),
                  'real_data_pattern_analysis'.tr(),
                ),
                const SizedBox(height: 16),
                _buildDisclaimerPoint(
                  theme,
                  '📈',
                  'historical_trends'.tr(),
                  'analyze_previous_results_help_win'.tr(),
                ),
                const SizedBox(height: 16),
                _buildDisclaimerPoint(
                  theme,
                  '⚠️',
                  'responsible_play'.tr(),
                  'no_guaranteed_wins_play_responsibly'.tr(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

    // Check if it's after 3 PM (15:00)
    final isAfter3PM = now.hour >= 15;

    // Calculate the current 3 PM cycle date
    // If before 3 PM, use yesterday's 3 PM cycle
    // If after 3 PM, use today's 3 PM cycle
    final cycleDate = isAfter3PM
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));

    final cycleDateString =
        '${cycleDate.year}-${cycleDate.month}-${cycleDate.day}';
    final lastShownCycleDate =
        prefs.getString('lucky_number_dialog_last_shown');

    // Only show if it's after 3 PM and we haven't shown it in this 3 PM cycle
    if (isAfter3PM && lastShownCycleDate != cycleDateString) {
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

  /// Check if cooldown period has passed
  bool _canShowAd() {
    if (_lastAdShowTime == null) {
      return true; // Never shown, can show
    }

    final timeSinceLastAd = DateTime.now().difference(_lastAdShowTime!);
    return timeSinceLastAd >= _adCooldownDuration;
  }

  /// Update cooldown timestamp
  void _updateCooldownTimestamp() {
    _lastAdShowTime = DateTime.now();
  }

  /// Load and show ad immediately with cooldown check
  Future<void> _loadAndShowInterstitialAd() async {
    // Check cooldown first
    if (!_canShowAd()) {
      return;
    }

    try {
      // Load ad and wait for it to complete loading
      await AdMobService.instance.loadAd('predict_interstitial');

      if (!mounted) return;

      // Give user a brief moment to see the screen before showing ad
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Verify ad is actually loaded before attempting to show
      if (AdMobService.instance.isAdLoaded('predict_interstitial')) {
        await AdMobService.instance.showInterstitialAd(
          'predict_interstitial',
          onDismissed: () {
            // Update cooldown timestamp when ad is dismissed
            _updateCooldownTimestamp();
          },
        );
      } else {
        // Ad failed to load, update cooldown to prevent rapid retry attempts
        _updateCooldownTimestamp();
      }
    } catch (e) {
      // Ad loading/showing failed, update cooldown to prevent rapid retry attempts
      _updateCooldownTimestamp();
    }
  }

  /// Generates a list of unique random 2-digit numbers (10-99)
  List<int> _generateRandomTwoDigitNumbers(int count) {
    final random = Random();
    final Set<int> numbers = {};

    while (numbers.length < count) {
      numbers.add(random.nextInt(90) + 10); // Generate 10-99
    }

    return numbers.toList();
  }

  /// Generates a random prediction line with the given prefix and 6 unique numbers
  String _generateRandomPredictionLine(String prefix) {
    final numbers = _generateRandomTwoDigitNumbers(6);
    final numbersStr =
        numbers.map((n) => n.toString().padLeft(2, '0')).join('  ');
    return '$prefix - $numbersStr';
  }

  Future<void> _copyPredictionNumbers(PredictState state) async {
    try {
      final todaysLottery = _getLotteryNameForToday();
      // Get the data from the state
      final data = switch (state) {
        PredictDataLoaded() => state.displayData,
        PredictDataWithUserPrediction() => state.displayData,
        PredictLoaded() => state.prediction,
        _ => null,
      };

      if (data == null) return;

      // Fetch AI prediction numbers for current prize type
      final aiPrediction =
          await AiPredictionService.getTodaysPrediction(_selectedPrizeType);

      StringBuffer copyText = StringBuffer();

      // Add AI Predicted Numbers section
      if (aiPrediction != null && aiPrediction.predictedNumbers.isNotEmpty) {
        copyText.writeln('KERALA LOTTERY $todaysLottery');
        copyText.writeln();
        copyText.writeln('Today Guessing Number :');

        copyText.writeln(aiPrediction.predictedNumbers.join('   '));
        copyText.writeln();
      }

      // Add Most Repeated Numbers section (last 4 digits from last 30 days)
      if (data.repeatedNumbers.isNotEmpty) {
        copyText.writeln('Most Winning Numbers (Last 30 Days) :');
        for (var item in data.repeatedNumbers) {
          copyText.writeln('${item.number} - ${item.count} times');
        }
        copyText.writeln();
      }

      // Add Top 6 Last 2 Digits section
      if (data.repeatedTwoDigits.isNotEmpty) {
        copyText.writeln('Top 6 Last 2 Digits :');
        for (var item in data.repeatedTwoDigits) {
          copyText.writeln('${item.digits} - ${item.count} times');
        }
        copyText.writeln();
      }

      // Add Random Prediction Series (AB, BC, AC)
      copyText.writeln(_generateRandomPredictionLine('AB Series'));
      copyText.writeln(_generateRandomPredictionLine('BC Series'));
      copyText.writeln(_generateRandomPredictionLine('AC Series'));
      copyText.writeln();

      // Add download link at the end
      copyText.writeln(
          'Download App : https://play.google.com/store/apps/details?id=app.solidapps.lotto');

      // Copy to clipboard
      if (copyText.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: copyText.toString()));

        // Show confirmation snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Numbers copied to clipboard!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green[700],
            ),
          );
        }

        // Track analytics
        AnalyticsService.trackUserEngagement(
          action: 'copy_numbers',
          category: 'predict_screen',
          label: 'copy_prediction_numbers',
          parameters: {
            'prize_type': _selectedPrizeType,
            'has_ai_numbers': aiPrediction != null,
            'repeated_numbers_count': data.repeatedNumbers.length,
            'two_digits_count': data.repeatedTwoDigits.length,
          },
        );

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy numbers: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _navigateToProbabilityScanner() {
    HapticFeedback.lightImpact();

    // Track analytics
    AnalyticsService.trackUserEngagement(
      action: 'tap_ai_probability_fab',
      category: 'predict_screen',
      label: 'navigate_to_probability_scanner',
      parameters: {
        'source': 'predict_screen',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Navigate to probability barcode scanner
    context.go('/probability_barcode_scanner');
  }
}
