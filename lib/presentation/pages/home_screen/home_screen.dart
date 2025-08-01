import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/ai_probability_fab.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/costume_carousel.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/first_time_language_dialog.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/lottery_results_section.dart';
import 'package:lotto_app/presentation/pages/home_screen/widgets/navigation_icons_widget.dart';
import 'package:lotto_app/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/presentation/widgets/rate_us_dialog.dart';
import 'package:lotto_app/data/services/analytics_service.dart';

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
  
  // All animations driven by the two controllers
  late Animation<double> _fabAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _badgeShimmerAnimation;

  bool _isExpanded = true;
  bool _isScrollingDown = false;
  DateTime? _lastRefreshTime;
  Timer? _periodicRefreshTimer;
  Timer? _attentionAnimationTimer;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreenView(
        screenName: 'home_screen',
        screenClass: 'HomeScreen',
        parameters: {
          'is_first_visit': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      AnalyticsService.trackSessionStart();
    });

    // Load data immediately (without UI delays)
    _loadLotteryResultsWithCache();

    // Set up periodic refresh timer (every 5 minutes)
    _setupPeriodicRefresh();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _initializeAnimations();
    _startAttentionAnimations();
    _showLanguageDialogIfNeeded();
  }

  void _initializeAnimations() {
    // Primary controller for FAB and main UI animations
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Secondary controller for attention-grabbing animations
    _secondaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 6000), // Longer cycle for all effects
      vsync: this,
    );

    // FAB animation
    _fabAnimation = CurvedAnimation(
      parent: _primaryAnimationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Blink animation (0-1 second in the cycle)
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: const Interval(0.0, 0.17, curve: Curves.easeInOut), // 0-1 sec of 6 sec cycle
    ));

    // Rotation animation (1-2.5 seconds in the cycle)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 3.0, // 3 full rotations
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: const Interval(0.17, 0.42, curve: Curves.easeInOutCubic), // 1-2.5 sec
    ));

    // Shimmer animation (2.5-4.5 seconds in the cycle)
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: const Interval(0.42, 0.75, curve: Curves.easeInOut), // 2.5-4.5 sec
    ));

    // Badge shimmer animation (4.5-6 seconds in the cycle)
    _badgeShimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeInOut), // 4.5-6 sec
    ));

    _primaryAnimationController.forward();
  }

  @override
  void dispose() {
    // Track session end
    AnalyticsService.trackSessionEnd();

    WidgetsBinding.instance.removeObserver(this);
    _periodicRefreshTimer?.cancel();
    _attentionAnimationTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    // Dispose consolidated animation controllers
    _primaryAnimationController.dispose();
    _secondaryAnimationController.dispose();
    super.dispose();
  }

  // Method to show interstitial ad and navigate (commented out - AdMob account not ready)
  // Future<void> _showInterstitialAdAndNavigate(String route) async {
  //   try {
  //     if (AdMobService.instance.isInterstitialAdLoaded) {
  //       await AdMobService.instance.showInterstitialAd(
  //         onAdDismissed: () {
  //           // Navigate after ad is dismissed
  //           if (mounted) {
  //             context.go(route);
  //           }
  //         },
  //       );
  //     } else {
  //       // If no ad is loaded, navigate directly
  //       if (mounted) {
  //         context.go(route);
  //       }
  //     }
  //   } catch (e) {
  //     // If ad fails, navigate directly
  //     if (mounted) {
  //       context.go(route);
  //     }
  //   }
  // }

  /// Start attention-grabbing animations using Timer.periodic for better performance
  void _startAttentionAnimations() {
    // Start the secondary animation controller cycle immediately
    _secondaryAnimationController.forward();
    
    // Use Timer.periodic instead of Future.delayed chains for better performance
    _attentionAnimationTimer = Timer.periodic(
      const Duration(seconds: 8), // Repeat every 8 seconds (6 sec animation + 2 sec pause)
      (timer) {
        if (mounted) {
          _secondaryAnimationController.reset();
          _secondaryAnimationController.forward();
        } else {
          timer.cancel();
        }
      },
    );
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
      // Scrolling down - collapse FAB
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        if (_isExpanded) {
          _isExpanded = false;
          _primaryAnimationController.reverse();
        }
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - expand FAB
      if (_isScrollingDown) {
        _isScrollingDown = false;
        if (!_isExpanded) {
          _isExpanded = true;
          _primaryAnimationController.forward();
        }
      }
    }
  }

  void _loadLotteryResults() {
    // Track user action
    AnalyticsService.trackUserEngagement(
      action: 'load_lottery_results',
      category: 'data_refresh',
      label: 'manual_refresh',
    );

    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());
  }

  /// Load results with cache-first strategy for better UX
  void _loadLotteryResultsWithCache() {
    // Load from cache first (fast), then immediately trigger background refresh
    // Remove UI delays - let the BLoC handle cache-first then network pattern
    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());
    
    // Trigger background refresh immediately without delay
    if (mounted) {
      _refreshResultsInBackground();
    }
  }

  void _refreshResults() {
    _lastRefreshTime = DateTime.now();
    context.read<HomeScreenResultsBloc>().add(RefreshLotteryResultsEvent());
  }

  /// Refresh results in background without showing loading state
  void _refreshResultsInBackground() {
    // Only refresh if we haven't refreshed recently (within 2 minutes)
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!).inMinutes < 2) {
      return;
    }

    _lastRefreshTime = DateTime.now();
    context.read<HomeScreenResultsBloc>().add(BackgroundRefreshEvent());

    // Use BLoC state to manage refresh indicator instead of setState
    // Remove setState calls to eliminate unnecessary rebuilds
  }

  /// Set up periodic refresh timer
  void _setupPeriodicRefresh() {
    _periodicRefreshTimer = Timer.periodic(
      const Duration(minutes: 5), // Refresh every 5 minutes
      (timer) {
        if (mounted) {
          _refreshResultsInBackground();
        }
      },
    );
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - refresh data if it's been a while
        if (mounted) {
          _handleAppResumed();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background - cancel periodic timer to save battery
        _periodicRefreshTimer?.cancel();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Handle app resume - refresh data if needed
  void _handleAppResumed() {
    // Restart periodic refresh timer
    _setupPeriodicRefresh();

    // Refresh data if we haven't refreshed in the last 3 minutes
    if (_lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!).inMinutes >= 3) {
      _refreshResultsInBackground();
    }
  }

  /// Launch website when carousel image is tapped
  Future<void> _launchWebsite() async {
    const String websiteUrl = 'https://lottokeralalotteries.com/';

    try {
      final Uri url = Uri.parse(websiteUrl);

      // Check if the URL can be launched
      final bool canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        // Try to launch the URL with platform default mode first
        final bool launched = await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );

        if (!launched) {
          // If platform default failed, try external application
          final bool launchedExternal = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );

          if (!launchedExternal) {
            _showErrorSnackBar('could_not_open_website'.tr());
          }
        }
      } else {
        _showErrorSnackBar('could_not_open_website'.tr());
      }
    } catch (e) {
      _showErrorSnackBar('error_opening_website'.tr());
    }
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
      // Show loading feedback

      // Let the BLoC handle the filtering
      if (mounted) {
        context
            .read<HomeScreenResultsBloc>()
            .add(LoadLotteryResultsByDateEvent(selectedDate));
      }
    }
  }

  // Helper method to format date for display
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'month_jan'.tr(),
      'month_feb'.tr(),
      'month_mar'.tr(),
      'month_apr'.tr(),
      'month_may'.tr(),
      'month_jun'.tr(),
      'month_jul'.tr(),
      'month_aug'.tr(),
      'month_sep'.tr(),
      'month_oct'.tr(),
      'month_nov'.tr(),
      'month_dec'.tr()
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Handle back button press and show rating dialog
  Future<bool> _handleBackPress() async {
    await RateUsDialog.incrementBackButtonCount();

    final shouldShowDialog = await RateUsDialog.shouldShowRatingDialog();
    if (shouldShowDialog && mounted) {
      await RateUsDialog.show(context);
      // If user rated, we can still exit. If they dismissed, also allow exit.
      return true;
    }

    // Allow normal back navigation
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _handleBackPress();
          if (shouldExit && context.mounted) {
            // Exit the app
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: BlocListener<HomeScreenResultsBloc, HomeScreenResultsState>(
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
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshResults();
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
                    badgeShimmerAnimation: _badgeShimmerAnimation,
                    formatDateForDisplay: _formatDateForDisplay,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 100)),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildScanButton(theme),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      centerTitle: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      // leading: IconButton(
      //   icon: Icon(
      //     Icons.notifications,
      //     color: theme.appBarTheme.actionsIconTheme?.color,
      //     size: AppResponsive.fontSize(context, 24),
      //   ),
      //   onPressed: () => context.go('/notifications'),
      // ),
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
        // Beautiful Coin Button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.spacing(context, 4),
          ),
          child: GestureDetector(
            onTap: () => context.go('/lottoPoints'),
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Original button
                    Container(
                      height: AppResponsive.fontSize(context, 26),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.spacing(context, 6),
                        vertical: AppResponsive.spacing(context, 4),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 204, 61, 25), // Gold
                            Color.fromARGB(255, 206, 71, 4), // Light Gold
                            Color.fromARGB(255, 229, 92, 38), // Gold
                          ],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 18),
                        ),
                        border: Border.all(
                          color: Color(0xFFFFE55C).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: child,
                    ),
                    // Shimmer overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 18),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value, 0),
                              transform: GradientRotation(
                                  math.pi / 4), // 45 degree angle
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value *
                            2 *
                            math.pi, // Convert to radians (3 full rotations)
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/icons/lotto_points.png',
                      width: AppResponsive.fontSize(context, 14),
                      height: AppResponsive.fontSize(context, 14),
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 4)),
                  Text(
                    "Points",
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

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
              'contact_value', // The actual value returned when selected
              Icons.contact_support,
              'contact_us', // This is the translation key
              Theme.of(context),
              context, // Pass context
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'settings_value': // Match the actual returned value
                context.push('/settings');
                break;
              case 'contact_value': // Match the actual returned value
                showContactSheet(context);
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
          Text(
            textKey
                .tr(), // Call .tr() on the textKey to get the translated string
            style: TextStyle(
              fontSize: AppResponsive.fontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    return AIProbabilityFAB(
      onPressed: () {
        // Navigate to the scanner page
        context.pushNamed(RouteNames.probabilityBarcodeScanner);
      },
      sizeAnimation: _fabAnimation,
      theme: theme,
    );
  }
}
