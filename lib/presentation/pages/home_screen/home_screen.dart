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
      }
    });
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
    return MultiBlocListener(
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
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: RefreshIndicator(
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
                // Replace _buildCarousel() with the custom widget
                BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
                  buildWhen: (previous, current) {
                    // Only rebuild if images actually changed
                    if (previous is HomeScreenResultsLoaded &&
                        current is HomeScreenResultsLoaded) {
                      return previous.data.updates.allImages !=
                          current.data.updates.allImages;
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
                      autoPlayInterval: const Duration(seconds: 4),
                    );
                  },
                ),
                SizedBox(height: AppResponsive.spacing(context, 5)),
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
      title: BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
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
                  const Icon(
                    Icons.wifi_off,
                    size: 16,
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

          // Show app title with refresh indicator when background refreshing
          return Text(
            'LOTTO',
            style: TextStyle(
              fontSize: AppResponsive.fontSize(context, 22),
              fontWeight: FontWeight.bold,
              color: theme.appBarTheme.titleTextStyle?.color,
            ),
          );
        },
      ),
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
          itemBuilder: (BuildContext context) => [
            _buildPopupMenuItem(
              'settings_value', // The actual value returned when selected
              Icons.settings,
              'settings', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
            _buildPopupMenuItem(
              'saved_value', // The actual value returned when selected
              Icons.bookmark,
              'saved', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
            _buildPopupMenuItem(
              'community_value', // The actual value returned when selected
              Icons.group,
              'community', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
            _buildPopupMenuItem(
              'contact_value', // The actual value returned when selected
              Icons.contact_support,
              'contact_us', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
            _buildPopupMenuItem(
              'rate_us_value', // The actual value returned when selected
              Icons.star,
              'rate_us_title', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
            _buildPopupMenuItem(
              'how_to_use_value', // The actual value returned when selected
              Icons.video_library,
              'how_to_use', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
          ],
          onSelected: (value) {
            // Add haptic feedback for menu selection
            HapticFeedback.selectionClick();

            switch (value) {
              case 'saved_value': // Match the actual returned value
                context.push('/saved-results');
                break;
              case 'settings_value': // Match the actual returned value
                context.push('/settings');
                break;
              case 'community_value': // Match the actual returned value
                _launchWhatsAppGroup();
                break;
              case 'contact_value': // Match the actual returned value
                showContactSheet(context);
                break;
              case 'rate_us_value': // Match the actual returned value
                _showRateUsDialog(context);
                break;
              case 'how_to_use_value': // Match the actual returned value
                context.push('/how-to-use');
                break;
            }
          },
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String textKey, // Renamed to textKey to clarify its purpose
    ThemeData theme,
    BuildContext context, // Added context to access AppResponsive
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
              textKey
                  .tr(), // Call .tr() on the textKey to get the translated string
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
