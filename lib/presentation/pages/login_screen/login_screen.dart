import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Track login screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreenView(
        screenName: 'login_screen',
        screenClass: 'LoginScreen',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    });
  }
  String? phoneErrorText; // For showing validation errors

  // Language data
  final List<Map<String, dynamic>> languages = [
    {'code': 'en', 'name': 'English', 'locale': Locale('en')},
    {'code': 'hi', 'name': 'हिंदी', 'locale': Locale('hi')},
    {'code': 'ml', 'name': 'മലയാളം', 'locale': Locale('ml')},
    {'code': 'ta', 'name': 'தமிழ்', 'locale': Locale('ta')},
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Mobile number validation function
  String _validateAndFormatPhoneNumber(String input) {
    // Remove spaces and other characters but keep + and digits
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Only remove 91 if it's preceded by + (i.e., +91 prefix)
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3); // Remove +91
    }

    // Remove any remaining + signs
    String digitsOnly = cleaned.replaceAll('+', '');

    return digitsOnly;
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    String cleanNumber = _validateAndFormatPhoneNumber(phoneNumber);
    return cleanNumber.length == 10 &&
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber);
  }

  void _onPhoneNumberChanged(String value) {
    setState(() {
      phoneErrorText = null; // Clear error when user types
    });

    // Format the phone number and update the controller
    String formattedNumber = _validateAndFormatPhoneNumber(value);

    // Limit to 10 digits maximum
    if (formattedNumber.length > 10) {
      formattedNumber = formattedNumber.substring(0, 10);
    }

    // Only update if the formatted number is different to avoid cursor issues
    if (formattedNumber != phoneController.text) {
      phoneController.value = TextEditingValue(
        text: formattedNumber,
        selection: TextSelection.collapsed(offset: formattedNumber.length),
      );
    }
  }

  void _handleAuth() {
    // Clear previous errors
    setState(() {
      phoneErrorText = null;
    });

    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      // Track failed login attempt
      AnalyticsService.trackUserEngagement(
        action: 'login_attempt',
        category: 'authentication',
        label: 'validation_failed',
        parameters: {
          'error_type': 'empty_fields',
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_fill_all_fields'.tr())),
      );
      return;
    }

    if (!_isValidPhoneNumber(phoneController.text)) {
      // Track failed login attempt
      AnalyticsService.trackUserEngagement(
        action: 'login_attempt',
        category: 'authentication',
        label: 'validation_failed',
        parameters: {
          'error_type': 'invalid_phone',
        },
      );
      
      setState(() {
        phoneErrorText = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    // Track successful login attempt
    AnalyticsService.trackLogin(
      loginMethod: 'phone_number',
      success: true,
    );

    context.read<AuthBloc>().add(
          AuthAutoSignInRequested(
            nameController.text,
            _validateAndFormatPhoneNumber(phoneController.text),
          ),
        );
  }


  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final currentLocale = context.locale;
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: theme.primaryColor,
                duration: const Duration(milliseconds: 300),
                content: Text(state.message)),
          );
          
          // Enable notifications after successful sign-in
          FirebaseMessagingService.updateNotificationSettings(true).then((success) {
          }).catchError((error) {
          });
          
          context.go('/'); // Navigate to home page
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('auth_error'.tr())),
          );
        }
      },
      child: Scaffold(
          // Use theme scaffold background instead of hardcoded color
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Main content - wrapped in Expanded to push language selector to bottom
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              size.width > 600 ? size.width * 0.15 : 32.0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 500, // Maximum width for larger screens
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App branding with subtle animation - KEEPING THIS IN THE SAME POSITION
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Column(
                                  children: [
                                    SizedBox(height: size.height * 0.02),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Text(
                                          'LOTTO',
                                          style: TextStyle(
                                            fontSize:
                                                size.width > 600 ? 80 : 72,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            // Use theme text color instead of hardcoded
                                            color: theme
                                                .textTheme.titleLarge?.color,
                                          ),
                                        ),
                                        Positioned(
                                          right: 10,
                                          bottom: 4,
                                          child: Text(
                                            'Be Lucky',
                                            style: TextStyle(
                                              fontSize:
                                                  size.width > 600 ? 16 : 16,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),

                              // Responsive spacing
                              SizedBox(height: size.height * 0.08),

                              // Form title
                              Text(
                                'enter_your_details'.tr(),
                                style: TextStyle(
                                  fontSize: size.width > 600 ? 18 : 16,
                                  fontWeight: FontWeight.w500,
                                  // Use theme text color
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              SizedBox(height: size.height * 0.025),

                              // Dynamic form fields based on mode with maintained animation
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Name field - Always visible
                                    Container(
                                      decoration: BoxDecoration(
                                        // Use card theme color for input fields
                                        color: theme.cardTheme.color,
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black
                                                    .withValues(alpha: 0.3)
                                                : Colors.black
                                                    .withValues(alpha: 0.03),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      margin:
                                          const EdgeInsets.only(bottom: 15),
                                      child: TextField(
                                        controller: nameController,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          // Use theme text color
                                          color: theme
                                              .textTheme.bodyLarge?.color,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'name_or_username'.tr(),
                                          hintStyle: TextStyle(
                                            // Use theme hint color
                                            color: theme
                                                .textTheme.bodySmall?.color,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Phone number field - Always visible
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            // Use card theme color
                                            color: theme.cardTheme.color,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: phoneErrorText != null
                                                ? Border.all(
                                                    color: Colors.red, width: 1)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.black
                                                        .withValues(alpha: 0.3)
                                                    : Colors.black.withValues(
                                                        alpha: 0.03),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            controller: phoneController,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.phone,
                                            maxLength: 10,
                                            onChanged: _onPhoneNumberChanged,
                                            inputFormatters: [
                                              // Custom formatter that handles +91 removal
                                              TextInputFormatter.withFunction(
                                                  (oldValue, newValue) {
                                                String formatted =
                                                    _validateAndFormatPhoneNumber(
                                                        newValue.text);
                                                if (formatted.length > 10) {
                                                  formatted = formatted
                                                      .substring(0, 10);
                                                }
                                                return TextEditingValue(
                                                  text: formatted,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset:
                                                              formatted.length),
                                                );
                                              }),
                                            ],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              // Use theme text color
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'mobile_number'.tr(),
                                              hintStyle: TextStyle(
                                                // Use theme hint color
                                                color: theme
                                                    .textTheme.bodySmall?.color,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              border: InputBorder.none,
                                              counterText:
                                                  '', // Hide character counter
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Error text
                                        if (phoneErrorText != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20, top: 8),
                                            child: Text(
                                              phoneErrorText!,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // KEPT THE SAME SPACING
                              SizedBox(height: size.height * 0.04),

                              // Elegant button with animation - Same as original
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                          alpha: isLoading ? 0.2 : 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    return ElevatedButton(
                                      onPressed: state is AuthLoading
                                          ? null
                                          : _handleAuth,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: const CircleBorder(),
                                        padding: EdgeInsets.all(
                                            size.width > 600 ? 32 : 28),
                                        elevation: 0,
                                        disabledBackgroundColor: theme
                                            .primaryColor
                                            .withValues(alpha: 0.7),
                                      ),
                                      child: state is AuthLoading
                                          ? SizedBox(
                                              width: size.width > 600 ? 32 : 28,
                                              height:
                                                  size.width > 600 ? 32 : 28,
                                              child:
                                                  const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Icon(
                                              Icons.arrow_forward_rounded,
                                              size: size.width > 600 ? 36 : 32,
                                            ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: size.height * 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Language selector at bottom
                Container(
                  padding:
                      const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: languages.map((language) {
                      final isSelected =
                          currentLocale.languageCode == language['code'];
                      return GestureDetector(
                        onTap: () => _changeLanguage(language['locale']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Text(
                            language['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
