import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/presentation/pages/predict_screen/widgets/lucky_number_dialog.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  bool _isDisclaimerExpanded = false;

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    // Load prediction data and check if lucky number dialog should be shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictBloc>().add(const GetPredictionDataEvent());
      _checkAndShowLuckyNumberDialog();
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
      return Center(
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
              'Failed to load prediction data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.read<PredictBloc>().add(const GetPredictionDataEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (state is PredictDataLoaded) {
      final data = state.displayData;
      return _buildDataContent(theme, data);
    }
    
    if (state is PredictDataWithUserPrediction) {
      final data = state.displayData;
      return Column(
        children: [
          _buildUserPredictionResult(theme, state),
          Expanded(
            child: _buildDataContent(theme, data),
          ),
        ],
      );
    }
    
    if (state is PredictLoaded) {
      final data = state.prediction;
      return _buildDataContent(theme, data);
    }
    
    return const Center(
      child: Text('No data available'),
    );
  }

  Widget _buildDataContent(ThemeData theme, PredictResponseModel data) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPeoplePredictionsCard(theme, data.peoplesPredictions),
            const SizedBox(height: 5),
            _buildMostRepeatedLast7DaysCard(theme, data.repeatedSingleDigits),
            const SizedBox(height: 5),
            _buildMostRepeatedCard(theme, data.repeatedNumbers),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPredictionResult(ThemeData theme, PredictDataWithUserPrediction state) {
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
              Text(
                'Your Lucky Number: ${state.selectedNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prediction submitted successfully! Good luck! 🍀',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Last 7 days most repeated numbers
  Widget _buildMostRepeatedLast7DaysCard(ThemeData theme, List<RepeatedSingleDigit> data) {
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
                Text(
                  'Last 7 Days Most Repeated Last Digit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSingleDigitsRow(theme, data.map((e) => {'number': e.digit, 'count': e.count}).toList(), null, false, true),
          ],
        ),
      ),
    );
  }

  // People predictions section
  Widget _buildPeoplePredictionsCard(ThemeData theme, List<PeoplesPrediction> data) {
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
                Text(
                  'People Predictions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSingleDigitsRow(theme, data.map((e) => {'number': e.digit, 'count': e.count}).toList(), null, true),
          ],
        ),
      ),
    );
  }

  // Helper method to build single digits in a row
  Widget _buildSingleDigitsRow(ThemeData theme, List<Map<String, dynamic>> numberData, MaterialColor? color, [bool isDarkGreen = false, bool isDarkBlue = false]) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${data['count']} times',
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
            '${numberData.length} digits found 📊',
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
  Widget _buildNumbersWithCountGrid(ThemeData theme, List<Map<String, dynamic>> numberData, MaterialColor color) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data['count']}x',
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
            '${numberData.length} patterns found 📊',
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
                Text(
                  'Most Repeated Last 4 Digits (Last 30 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNumbersWithCountGrid(theme, data.map((e) => {'number': e.number, 'count': e.count}).toList(), Colors.orange),
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
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final lastShownDate = prefs.getString('lucky_number_dialog_last_shown');

    if (lastShownDate != todayString) {
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
      builder: (BuildContext context) {
        return const LuckyNumberDialog();
      },
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
        // Provide subtle haptic feedback when each number starts appearing
        HapticFeedback.selectionClick();
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
