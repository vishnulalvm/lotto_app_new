import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_bloc.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_event.dart';
import 'package:lotto_app/presentation/blocs/auth_screen/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  bool isSignUp = true; // Default to sign up mode

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

  void _handleAuth() {
    if (isSignUp) {
      if (nameController.text.isEmpty || phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('please_fill_all_fields'.tr())),
        );
        return;
      }
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              nameController.text,
              phoneController.text,
            ),
          );
    } else {
      if (phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('please_enter_phone'.tr())),
        );
        return;
      }
      context.read<AuthBloc>().add(
            AuthLoginRequested(phoneController.text),
          );
    }
  }

  void _toggleAuthMode() {
    setState(() {
      isSignUp = !isSignUp;
    });
  }

  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final currentLocale = context.locale;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: theme.primaryColor,
                duration: const Duration(seconds: 1),
                content: Text(state.message)),
          );
          context.go('/'); // Navigate to home page
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('auth_error'.tr())),
          );
        }
      },
      child: Scaffold(
          backgroundColor:
              const Color(0xFFFFF1F2), // Keeping the light pink background
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
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Positioned(
                                          right: 10,
                                          bottom: 4,
                                          child: Text(
                                            'tagline'.tr(),
                                            style: TextStyle(
                                              fontSize:
                                                  size.width > 600 ? 16 : 16,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                              color: Colors.red,
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
                                isSignUp
                                    ? 'sign_up_to_continue'.tr()
                                    : 'sign_in_to_continue'.tr(),
                                style: TextStyle(
                                  fontSize: size.width > 600 ? 18 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
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
                                    AnimatedCrossFade(
                                      firstChild: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.03),
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'name_or_username'.tr(),
                                            hintStyle: const TextStyle(
                                              color: Colors.black38,
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
                                      secondChild: const SizedBox.shrink(),
                                      crossFadeState: isSignUp
                                          ? CrossFadeState.showFirst
                                          : CrossFadeState.showSecond,
                                      duration:
                                          const Duration(milliseconds: 300),
                                    ),
                                    // Phone number field - Always visible
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: phoneController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'mobile_number'.tr(),
                                          hintStyle: const TextStyle(
                                            color: Colors.black38,
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
                                  ],
                                ),
                              ),
                              // Toggle button below text fields
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _toggleAuthMode,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 16.0),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            theme.primaryColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isSignUp
                                          ? 'sign_in'.tr()
                                          : 'sign_up'.tr(),
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
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
                                      color: theme.primaryColor
                                          .withOpacity(isLoading ? 0.2 : 0.3),
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
                                        disabledBackgroundColor:
                                            theme.primaryColor.withOpacity(0.7),
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
                                ? theme.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: theme.primaryColor.withOpacity(0.3),
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
                                  : Colors.black54,
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
