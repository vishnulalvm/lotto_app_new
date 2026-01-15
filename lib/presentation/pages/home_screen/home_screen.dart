import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/costume_carousel.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/first_time_language_dialog.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/lottery_results_section.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/navigation_icons_widget.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/core/utils/date_formatter.dart';
import 'package:lotto_app/core/services/url_launcher_service.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_bloc.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_event.dart';
import 'package:lotto_app/presentation/blocs/rate_us/rate_us_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/core/widgets/rate_us_dialog.dart';
import 'package:lotto_app/presentation/pages/settings_screen/widgets/color_theme_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;

  // Consolidated animation controllers
  late AnimationController _primaryAnimationController;
  late AnimationController _secondaryAnimationController;

  late Animation<double> _blinkAnimation;

  bool _isFabVisible = true;
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Track screen view for analytics (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Run analytics in background to avoid blocking UI
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'home_screen',
          screenClass: 'HomeScreen',
          parameters: {
            'is_first_visit': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
        // Use enhanced session tracking for Google Ads optimization
        AnalyticsService.trackEnhancedSessionStart();
        // Increment screen count for session quality tracking
        AnalyticsService.incrementSessionScreenCount();
      });

      // Check and show rate us dialog using BLoC
      context.read<RateUsBloc>().add(CheckRateUsDialogEvent());
    });

    // Load data and start periodic refresh via BLoC
    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());
    context.read<HomeScreenResultsBloc>().add(StartPeriodicRefreshEvent());

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _initializeAnimations();
    _startBlinkAnimation();
    _showLanguageDialogIfNeeded();
  }

  void _startBlinkAnimation() {
    _secondaryAnimationController.repeat();
  }

  void _initializeAnimations() {
    // Primary controller for FAB and main UI animations
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Slower for drop effect
      vsync: this,
    );

    // Secondary controller for attention-grabbing animations
    _secondaryAnimationController = AnimationController(
      duration:
          const Duration(milliseconds: 6000), // Longer cycle for all effects
      vsync: this,
    );

    // Blink animation (0-1 second in the cycle)
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: const Interval(0.0, 0.17,
          curve: Curves.easeInOut), // 0-1 sec of 6 sec cycle
    ));

    _primaryAnimationController.forward();
  }

  @override
  void dispose() {
    // Track enhanced session end with quality metrics
    AnalyticsService.trackEnhancedSessionEnd();

    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Dispose consolidated animation controllers
    _primaryAnimationController.dispose();
    _secondaryAnimationController.dispose();

    super.dispose();
  }

  void _showLanguageDialogIfNeeded() async {
    // Show language dialog immediately when screen is ready
    // Remove unnecessary delay for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await FirstTimeLanguageDialog.show(context);
        // After language dialog, check if we should show color scheme feature announcement
        _showColorSchemeDialogIfNeeded();
      }
    });
  }

  /// Show color scheme dialog once to existing users to announce the new feature
  void _showColorSchemeDialogIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has seen the color scheme feature announcement
    final hasSeenColorSchemeAnnouncement =
        prefs.getBool('has_seen_color_scheme_announcement') ?? false;

    // Check if user is an existing user (has selected language before)
    final isExistingUser = prefs.getBool('language_selected') ?? false;

    // Show dialog only if:
    // 1. User is an existing user (has used the app before)
    // 2. Has not seen the color scheme announcement yet
    if (isExistingUser && !hasSeenColorSchemeAnnouncement && mounted) {
      // Add a small delay to avoid showing multiple dialogs at once
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Add haptic feedback
        HapticFeedback.lightImpact();

        // Show the color scheme dialog directly
        await showDialog(
          context: context,
          builder: (context) => const ColorThemeDialog(),
        );

        // Mark as seen so it won't show again
        await prefs.setBool('has_seen_color_scheme_announcement', true);
      }
    }
  }

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      // Scrolling down - hide FAB with slide down animation
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        if (_isFabVisible) {
          _isFabVisible = false;
          _primaryAnimationController.reverse();
        }
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - show FAB with slide up animation
      if (_isScrollingDown) {
        _isScrollingDown = false;
        if (!_isFabVisible) {
          _isFabVisible = true;
          _primaryAnimationController.forward();
        }
      }
    }
  }

  void _loadLotteryResults() {
    // Add haptic feedback for refresh action
    HapticFeedback.mediumImpact();

    // Track user action
    AnalyticsService.trackUserEngagement(
      action: 'load_lottery_results',
      category: 'data_refresh',
      label: 'manual_refresh',
    );

    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - notify BLoC
        if (mounted) {
          context
              .read<HomeScreenResultsBloc>()
              .add(AppLifecycleChangedEvent(isResumed: true));
        }
        break;
      case AppLifecycleState.paused:
        // App paused - notify BLoC
        if (mounted) {
          context
              .read<HomeScreenResultsBloc>()
              .add(AppLifecycleChangedEvent(isResumed: false));
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Launch website when carousel image is tapped
  Future<void> _launchWebsite() async {
    // Add haptic feedback for image tap
    HapticFeedback.lightImpact();

    final bool launched = await URLLauncherService.launchWebsite();

    if (!launched && mounted) {
      _showErrorSnackBar('could_not_open_website'.tr());
    }
  }

  /// Launch WhatsApp group when community menu item is tapped
  Future<void> _launchWhatsAppGroup() async {
    // Add haptic feedback for menu selection
    HapticFeedback.lightImpact();

    final bool launched = await URLLauncherService.launchWhatsAppGroup();

    if (!launched && mounted) {
      _showErrorSnackBar('could_not_open_whatsapp'.tr());
    }
  }

  /// Show rate us dialog manually from menu
  void _showRateUsDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => RateUsDialog(
        onNotNow: () {
          context.read<RateUsBloc>().add(RateUsNotNowEvent());
        },
        onContinue: () {
          context.read<RateUsBloc>().add(RateUsContinueEvent());
        },
      ),
    );
  }

  /// Show error snackbar for website launch failures
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'retry'.tr(),
            textColor: Colors.white,
            onPressed: _launchWebsite,
          ),
        ),
      );
    }
  }

  // Method to show date picker and navigate to specific date
  Future<void> _showDatePicker() async {
    // Add haptic feedback for date picker tap
    HapticFeedback.lightImpact();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'select_date_filter_results'.tr(),
      cancelText: 'cancel'.tr(),
      confirmText: 'filter'.tr(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).cardColor,
                  onSurface: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Add confirmation haptic feedback
      HapticFeedback.selectionClick();

      // Let the BLoC handle the filtering
      if (mounted) {
        context
            .read<HomeScreenResultsBloc>()
            .add(LoadLotteryResultsByDateEvent(selectedDate));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Scaffold with AppBar and body
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme),
          body: MultiBlocListener(
            listeners: [
              // HomeScreen results listener
              BlocListener<HomeScreenResultsBloc, HomeScreenResultsState>(
                listener: (context, state) {
                  // Clear any existing snackbars first
                  ScaffoldMessenger.of(context).clearSnackBars();

                  if (state is HomeScreenResultsError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${'error_prefix'.tr()}${state.message}'),
                        backgroundColor: Colors.red,
                        action: SnackBarAction(
                          label: 'retry'.tr(),
                          textColor: Colors.white,
                          onPressed: _loadLotteryResults,
                        ),
                      ),
                    );
                  }
                },
              ),
              // Rate Us BLoC listener
              BlocListener<RateUsBloc, RateUsState>(
                listener: (context, state) {
                  if (state is RateUsShowDialog) {
                    // Capture context before async gap
                    final navigator = Navigator.of(context);
                    final rateUsBloc = context.read<RateUsBloc>();

                    // Small delay to ensure UI is ready
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        HapticFeedback.lightImpact();
                        showDialog(
                          context: navigator.context,
                          barrierDismissible: false,
                          builder: (dialogContext) => RateUsDialog(
                            onNotNow: () {
                              rateUsBloc.add(RateUsNotNowEvent());
                            },
                            onContinue: () {
                              rateUsBloc.add(RateUsContinueEvent());
                            },
                          ),
                        );
                      }
                    });
                  }
                },
              ),
            ],
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                context
                    .read<HomeScreenResultsBloc>()
                    .add(RefreshLotteryResultsEvent());
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Carousel with optimized rebuild logic
                    RepaintBoundary(
                      child: BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
                        buildWhen: (previous, current) {
                          // Only rebuild if images actually changed
                          if (previous is HomeScreenResultsLoaded &&
                              current is HomeScreenResultsLoaded) {
                            // Deep comparison of image lists
                            final prevImages = previous.data.updates.allImages;
                            final currImages = current.data.updates.allImages;

                            // Check if lists are different
                            if (prevImages.length != currImages.length) return true;

                            // Check if content is different
                            for (int i = 0; i < prevImages.length; i++) {
                              if (prevImages[i] != currImages[i]) return true;
                            }

                            // Images are identical, don't rebuild
                            return false;
                          }
                          return previous.runtimeType != current.runtimeType;
                        },
                        builder: (context, state) {
                          List<String> carouselImages = [];

                          // Get images from API response
                          if (state is HomeScreenResultsLoaded) {
                            carouselImages = state.data.updates.allImages;
                          }

                          return SimpleCarouselWidget(
                            images: carouselImages,
                            onImageTap: () => _launchWebsite(),
                            // Optional: Customize colors to match your theme
                            gradientStartColor: Colors.pink.shade100,
                            gradientEndColor: Colors.pink.shade300,
                            // Optional: Custom settings

                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 6),
                          );
                        },
                      ),
                    ),
                    // SizedBox(height: AppResponsive.spacing(context, 5)),
                    const NavigationIconsWidget(),
                    SizedBox(height: AppResponsive.spacing(context, 10)),
                    LotteryResultsSection(
                      onLoadLotteryResults: _loadLotteryResults,
                      onShowDatePicker: _showDatePicker,
                      blinkAnimation: _blinkAnimation,
                      formatDateForDisplay: DateFormatter.formatDateForDisplay,
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 100)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Radial gradient glow overlay at the top (behind and above AppBar)
        IgnorePointer(
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.1,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.3),
                  theme.primaryColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: GestureDetector(
        onTap: _launchWhatsAppGroup,
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 14)),
          child: Image.asset(
            'assets/icons/whatsapp.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      title: const _AppBarTitle(),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.appBarTheme.actionsIconTheme?.color,
            size: AppResponsive.fontSize(context, 24),
          ),
          offset: Offset(0, AppResponsive.spacing(context, 45)),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
          ),
          itemBuilder: (BuildContext menuContext) => _buildMenuItems(menuContext, theme),
          onSelected: (value) {
            _handleMenuSelection(value);
          },
        ),
      ],
    );
  }

  // Extracted menu items builder for better organization
  List<PopupMenuItem<String>> _buildMenuItems(BuildContext menuContext, ThemeData theme) {
    // Static menu definition - structure doesn't change
    const menuItems = [
      ('settings_value', Icons.settings, 'settings'),
      ('saved_value', Icons.bookmark, 'saved'),
      ('color_scheme_value', Icons.palette_outlined, 'color_scheme'),
      ('contact_value', Icons.contact_support, 'contact_us'),
      ('rate_us_value', Icons.star, 'rate_us_title'),
      ('how_to_use_value', Icons.video_library, 'how_to_use'),
    ];

    return menuItems.map((item) {
      final (value, icon, textKey) = item;
      return _buildPopupMenuItem(value, icon, textKey, theme, menuContext);
    }).toList();
  }

  // Extracted menu selection handler
  void _handleMenuSelection(String value) {
    // Add haptic feedback for menu selection
    HapticFeedback.selectionClick();

    switch (value) {
      case 'saved_value':
        context.push('/saved-results');
        break;
      case 'settings_value':
        context.push('/settings');
        break;
      case 'color_scheme_value':
        showDialog(
          context: context,
          builder: (context) => const ColorThemeDialog(),
        );
        break;
      case 'contact_value':
        showContactSheet(context);
        break;
      case 'rate_us_value':
        _showRateUsDialog(context);
        break;
      case 'how_to_use_value':
        context.push('/how-to-use');
        break;
    }
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String textKey,
    ThemeData theme,
    BuildContext context,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.iconTheme.color,
            size: AppResponsive.fontSize(context, 20),
          ),
          SizedBox(width: AppResponsive.spacing(context, 12)),
          Expanded(
            child: Text(
              textKey.tr(),
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Separate widget for AppBar title - improves performance by preventing full AppBar rebuilds
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
      buildWhen: (previous, current) {
        // Only rebuild when offline status changes
        if (previous is HomeScreenResultsLoaded &&
            current is HomeScreenResultsLoaded) {
          return previous.isOffline != current.isOffline;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        // Show offline indicator when offline
        if (state is HomeScreenResultsLoaded && state.isOffline) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.spacing(context, 10),
              vertical: AppResponsive.spacing(context, 6),
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius:
                  BorderRadius.circular(AppResponsive.spacing(context, 20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: AppResponsive.fontSize(context, 16),
                  color: Colors.white,
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                Text(
                  'offline'.tr(),
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 16),
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Show app title
        return Text(
          'LOTTO',
          style: TextStyle(
            fontSize: AppResponsive.fontSize(context, 22),
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        );
      },
    );
  }
}
