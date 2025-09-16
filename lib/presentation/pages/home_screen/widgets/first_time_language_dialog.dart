// lib/presentation/widgets/first_time_language_dialog.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeLanguageDialog extends StatefulWidget {
  const FirstTimeLanguageDialog({super.key});

  @override
  State<FirstTimeLanguageDialog> createState() =>
      _FirstTimeLanguageDialogState();

  /// Check if this is the first time opening the app
  static Future<bool> shouldShowLanguageDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('language_selected') ?? false);
  }

  /// Mark language as selected (dialog won't show again)
  static Future<void> markLanguageAsSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
  }

  /// Show the language selection dialog
  static Future<void> show(BuildContext context) async {
    final shouldShow = await shouldShowLanguageDialog();
    if (shouldShow && context.mounted) {
      showDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => const FirstTimeLanguageDialog(),
      );
    }
  }
}

class _FirstTimeLanguageDialogState extends State<FirstTimeLanguageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Locale? _selectedLocale;
  bool _isChangingLanguage = false;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'English',
      'nativeName': 'English',
      'locale': const Locale('en'),
      'flag': '🇺🇸',
    },
    {
      'name': 'Malayalam',
      'nativeName': 'മലയാളം',
      'locale': const Locale('ml'),
      'flag': '🇮🇳',
    },
    {
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'locale': const Locale('hi'),
      'flag': '🇮🇳',
    },
    {
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
      'locale': const Locale('ta'),
      'flag': '🇮🇳',
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize locale only once when dependencies are available
    if (!_isInitialized) {
      _selectedLocale = context.locale; // Now context.locale is available
      _isInitialized = true;

      // Start animation after initialization
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.cardColor,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Welcome header
                      _buildHeader(theme),

                      const SizedBox(height: 24),

                      // Language options
                      _buildLanguageOptions(theme),

                      const SizedBox(height: 24),

                      // Action buttons
                      _buildActionButtons(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App icon or logo (you can replace with your app's logo)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.language,
            color: Colors.white,
            size: 30,
          ),
        ),

        const SizedBox(height: 16),

        // Welcome text
        Text(
          'Welcome to LOTTO!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Please select your preferred language',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageOptions(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          children: _languages.map((language) {
            final isSelected = _selectedLocale == language['locale'];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedLocale = language['locale'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : theme.dividerColor.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : theme.cardColor,
                    ),
                    child: Row(
                      children: [
                        // Flag emoji
                        Text(
                          language['flag'],
                          style: const TextStyle(fontSize: 24),
                        ),

                        const SizedBox(width: 16),

                        // Language names
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language['name'],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.primaryColor
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                language['nativeName'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection indicator
                        AnimatedScale(
                          scale: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        // Skip button
        Expanded(
          child: TextButton(
            onPressed: _isChangingLanguage ? null : _skipLanguageSelection,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isChangingLanguage ? null : _confirmLanguageSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isChangingLanguage
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _skipLanguageSelection() async {
    await FirstTimeLanguageDialog.markLanguageAsSelected();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _confirmLanguageSelection() async {
    if (_selectedLocale == null) return;

    setState(() {
      _isChangingLanguage = true;
    });

    try {
      // Change the app language
      await context.setLocale(_selectedLocale!);

      // Mark as selected so dialog won't show again
      await FirstTimeLanguageDialog.markLanguageAsSelected();

      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isChangingLanguage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change language. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
