import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_state.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  String? selectedPrizeType = '1st'; // Default to 1st prize
  late AnimationController _typewriterController;

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

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

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
                    _buildPrizeTypeSelector(theme),
                    const SizedBox(height: 24),
                    _buildPredictionCard(theme),
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
        lotteryName,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
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
            Text(
              'Prize Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
              ),
              items: prizeTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text('$type Prize'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPrizeType = newValue;
                });
                // Auto-generate when prize type changes
                if (newValue != null) {
                  _generatePrediction(_getLotteryNameForToday());
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
        const SizedBox(height: 20),
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

  Widget _buildBottomDisclaimer(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
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
                'For entertainment only • Results are random',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
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
