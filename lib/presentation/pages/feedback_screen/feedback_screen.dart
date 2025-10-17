import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_bloc.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_event.dart';
import 'package:lotto_app/presentation/blocs/feedback_screen/feedback_state.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final UserService _userService = UserService();

  final List<String> _selectedScreens = [];
  String? _phoneNumber;
  bool _isLoading = true;

  // List of screen names
  final List<Map<String, String>> _screens = [
    {'name': 'Home', 'key': 'homescreen'},
    {'name': 'Predict', 'key': 'predict_screen'},
    {'name': 'Scanner', 'key': 'scanner'},
    {'name': 'Live', 'key': 'live'},
    {'name': 'Scratch Card', 'key': 'scratch_card'},
    {'name': 'Profile', 'key': 'profile'},
    {'name': 'Result Screen', 'key': 'result_screen'},
    {'name': 'Error', 'key': 'error'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreenView(
        screenName: 'feedback_screen',
        screenClass: 'FeedbackScreen',
      );
    });
  }

  Future<void> _loadUserData() async {
    final phoneNumber = await _userService.getPhoneNumber();
    setState(() {
      _phoneNumber = phoneNumber;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    // Validate inputs
    if (_selectedScreens.isEmpty) {
      _showErrorSnackBar('feedback_select_screen'.tr());
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('feedback_enter_message'.tr());
      return;
    }

    if (_phoneNumber == null) {
      _showErrorSnackBar('feedback_phone_error'.tr());
      return;
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Combine selected screens into a single string
    final screenNames = _selectedScreens.join(', ');

    // Track analytics
    AnalyticsService.trackUserEngagement(
      action: 'submit_feedback',
      category: 'feedback',
      label: screenNames,
      parameters: {
        'screen_names': screenNames,
        'message_length': _messageController.text.length,
        'screens_count': _selectedScreens.length,
      },
    );

    // Submit feedback via BLoC
    context.read<FeedbackBloc>().add(
          SubmitFeedbackEvent(
            phoneNumber: _phoneNumber!,
            screenName: screenNames,
            message: _messageController.text.trim(),
          ),
        );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          title: Text(
            'FEEDBACK',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocListener<FeedbackBloc, FeedbackState>(
      listener: (context, state) {
        if (state is FeedbackSuccess) {
          _showSuccessSnackBar('feedback_success'.tr());
          // Clear form
          setState(() {
            _selectedScreens.clear();
            _messageController.clear();
          });
          // Navigate back after delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && context.mounted) {
              context.pop();
            }
          });
        } else if (state is FeedbackError) {
          _showErrorSnackBar('${'error_prefix'.tr()}${state.errorMessage}');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          title: Text(
            'FEEDBACK',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: AppResponsive.padding(context, horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen title
              Text(
                'feedback_screen_label'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),

              // Screen selection chips
              Wrap(
                spacing: AppResponsive.spacing(context, 8),
                runSpacing: AppResponsive.spacing(context, 8),
                children: _screens.map((screen) {
                  final isSelected = _selectedScreens.contains(screen['name']);

                  return FilterChip(
                    label: Text(
                      screen['key']!.tr(),
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedScreens.add(screen['name']!);
                        } else {
                          _selectedScreens.remove(screen['name']);
                        }
                      });
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: theme.primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 20),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.primaryColor
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: AppResponsive.padding(
                      context,
                      horizontal: 12,
                      vertical: 8,
                    ),
                    showCheckmark: true,
                  );
                }).toList(),
              ),

              SizedBox(height: AppResponsive.spacing(context, 30)),

              // Message section
              Text(
                'feedback_message_label'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),

              // Message input field
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppResponsive.spacing(context, 20),
                  ),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 10,
                  maxLength: 500,
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 14),
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'feedback_message_hint'.tr(),
                    hintStyle: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: AppResponsive.padding(
                      context,
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppResponsive.spacing(context, 30)),

              // Submit button
              BlocBuilder<FeedbackBloc, FeedbackState>(
                builder: (context, state) {
                  final isLoading = state is FeedbackLoading;

                  return SizedBox(
                    width: double.infinity,
                    height: AppResponsive.height(context, 7),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoading
                            ? theme.disabledColor
                            : theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppResponsive.spacing(context, 25),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: AppResponsive.fontSize(context, 20),
                              height: AppResponsive.fontSize(context, 20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'feedback_submit'.tr(),
                              style: TextStyle(
                                fontSize: AppResponsive.fontSize(context, 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
