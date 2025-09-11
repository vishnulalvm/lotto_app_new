import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_bloc.dart';
import 'package:lotto_app/presentation/blocs/predict_screen/predict_event.dart';

class LuckyNumberDialog extends StatefulWidget {
  const LuckyNumberDialog({
    super.key,
  });

  @override
  State<LuckyNumberDialog> createState() => _LuckyNumberDialogState();
}

class _LuckyNumberDialogState extends State<LuckyNumberDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<String> numbers = [
    '1', '2', '3',
    '4', '5', '6', 
    '7', '8', '9',
    '0'
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.85,
            maxHeight: screenSize.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              _buildNumberGrid(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Lucky Number',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a number that feels lucky to you today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final number = numbers[index];
              
              return _buildNumberButton(theme, number);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 70,
            child: _buildNumberButton(theme, '0', isZero: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(ThemeData theme, String number, {bool isZero = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 2,
        shadowColor: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            HapticFeedback.mediumImpact();
            
            final bloc = context.read<PredictBloc>();
            final navigator = Navigator.of(context);
            
            bloc.add(
              GetPredictionEvent(peoplesPrediction: number),
            );
            
            // Save today's date to prevent showing again today
            await _saveLuckyNumberDialogDate();
            
            navigator.pop();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.headlineMedium!.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                child: Text(number),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLuckyNumberDialogDate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('lucky_number_dialog_last_shown', todayString);
  }
}