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
    final isSmallScreen = screenSize.width < 400 || screenSize.height < 600;
    final isVerySmallScreen = screenSize.width < 350;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isVerySmallScreen 
                ? screenSize.width * 0.95 
                : isSmallScreen 
                    ? screenSize.width * 0.9
                    : screenSize.width * 0.85,
            maxHeight: isSmallScreen 
                ? screenSize.height * 0.75 
                : screenSize.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: theme.dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
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
              _buildHeader(theme, isSmallScreen, isVerySmallScreen),
              _buildNumberGrid(theme, isSmallScreen, isVerySmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSmallScreen, bool isVerySmallScreen) {
    final borderRadius = isSmallScreen ? 16.0 : 24.0;
    final padding = isVerySmallScreen ? 16.0 : isSmallScreen ? 20.0 : 24.0;
    final iconSize = isVerySmallScreen ? 20.0 : isSmallScreen ? 22.0 : 24.0;
    final iconPadding = isVerySmallScreen ? 8.0 : isSmallScreen ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.primaryColor,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guessing a Number',
                      style: (isVerySmallScreen 
                          ? theme.textTheme.titleMedium 
                          : theme.textTheme.titleLarge)?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: isVerySmallScreen ? 2 : 4),
                    Text(
                      'Tap a number that feels lucky to you today',
                      style: isVerySmallScreen 
                          ? theme.textTheme.bodySmall 
                          : theme.textTheme.bodyMedium,
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

  Widget _buildNumberGrid(ThemeData theme, bool isSmallScreen, bool isVerySmallScreen) {
    final padding = isVerySmallScreen ? 16.0 : isSmallScreen ? 20.0 : 24.0;
    final spacing = isVerySmallScreen ? 10.0 : isSmallScreen ? 12.0 : 16.0;
    final zeroButtonHeight = isVerySmallScreen ? 50.0 : isSmallScreen ? 60.0 : 70.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final number = numbers[index];
              
              return _buildNumberButton(theme, number, isSmallScreen: isSmallScreen, isVerySmallScreen: isVerySmallScreen);
            },
          ),
          SizedBox(height: spacing),
          SizedBox(
            width: double.infinity,
            height: zeroButtonHeight,
            child: _buildNumberButton(theme, '0', isZero: true, isSmallScreen: isSmallScreen, isVerySmallScreen: isVerySmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(ThemeData theme, String number, {bool isZero = false, bool isSmallScreen = false, bool isVerySmallScreen = false}) {
    final borderRadius = isVerySmallScreen ? 12.0 : isSmallScreen ? 16.0 : 20.0;
    final fontSize = isVerySmallScreen ? 20.0 : isSmallScreen ? 24.0 : 28.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 2,
        shadowColor: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
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
                  theme.cardTheme.color!,
                  theme.cardTheme.color!.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (isVerySmallScreen 
                    ? theme.textTheme.headlineSmall 
                    : theme.textTheme.headlineMedium)!.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
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
    final now = DateTime.now();

    // Save the current 3 PM cycle date
    // This ensures the dialog won't show again until after 3 PM tomorrow
    final cycleDate = now.hour >= 15
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    final cycleDateString = '${cycleDate.year}-${cycleDate.month}-${cycleDate.day}';
    await prefs.setString('lucky_number_dialog_last_shown', cycleDateString);
  }
}