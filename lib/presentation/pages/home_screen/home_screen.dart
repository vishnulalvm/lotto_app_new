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
import 'package:lotto_app/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';
import 'package:lotto_app/presentation/pages/contact_us/contact_us.dart';
import 'package:lotto_app/presentation/widgets/rate_us_dialog.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
// import 'package:lotto_app/data/services/admob_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _blinkAnimationController;
  late Animation<double> _blinkAnimation;
  late AnimationController _rotationAnimationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _shimmerAnimationController;
  late Animation<double> _shimmerAnimation;
  bool _isExpanded = true;
  bool _isScrollingDown = false;
  DateTime? _lastRefreshTime;
  Timer? _periodicRefreshTimer;
  bool isBackgroundRefreshing = false;

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

    // Load data immediately
    _loadLotteryResultsWithCache();

    // Set up periodic refresh timer (every 5 minutes)
    _setupPeriodicRefresh();

    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(
          milliseconds: 400), // Slightly longer for smoother feel
      vsync: this,
    );

    // Use a smooth curve for the animation
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutCubic, // Smoother curve
      reverseCurve: Curves.easeInOutCubic,
    );

    _fabAnimationController.forward();
    _scrollController.addListener(_onScroll);

    // Initialize blink animation controller for live badge
    _blinkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start the blinking animation and repeat
    _blinkAnimationController.repeat(reverse: true);

    // Initialize rotation animation controller for lotto points icon
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5 second per rotation
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 3.0, // 3 full rotations (3 turns = 1080 degrees)
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Initialize shimmer animation controller for glance effect
    _shimmerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2 second shimmer
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0, // Move across the button
    ).animate(CurvedAnimation(
      parent: _shimmerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations when app opens - repeat for more visibility
    _startAttentionAnimations();

    _showLanguageDialogIfNeeded();
    
    // Preload common assets for better performance
    _preloadCommonAssets();
  }
  
  /// Preload common assets to improve initial load performance
  void _preloadCommonAssets() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Preload fallback carousel images
      const fallbackImages = [
        'assets/images/bhagyadhara.jpg',
        'assets/images/dhanalakshmi.jpg',
        'assets/images/karunya-plus.jpg',
        'assets/images/karunya.jpg',
        'assets/images/sthreesakthi.jpg',
      ];
      
      for (final assetPath in fallbackImages) {
        precacheImage(AssetImage(assetPath), context);
      }
    });
  }

  @override
  void dispose() {
    // Track session end
    AnalyticsService.trackSessionEnd();
    
    WidgetsBinding.instance.removeObserver(this);
    _periodicRefreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _blinkAnimationController.dispose();
    _rotationAnimationController.dispose();
    _shimmerAnimationController.dispose();
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

  /// Start attention-grabbing animations for lotto points button
  void _startAttentionAnimations() async {
    // Delay the start slightly for better UX
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      // Start both animations simultaneously
      _rotationAnimationController.forward();
      _shimmerAnimationController.forward();
      
      // Listen for rotation completion to repeat
      _rotationAnimationController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Wait a bit then repeat (3 times total)
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _rotationAnimationController.reset();
              _rotationAnimationController.forward();
            }
          });
        }
      });
      
      // Listen for shimmer completion to repeat
      _shimmerAnimationController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Wait a bit then repeat
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _shimmerAnimationController.reset();
              _shimmerAnimationController.forward();
            }
          });
        }
      });
    }
  }

  void _showLanguageDialogIfNeeded() async {
    // Wait a bit for the home screen to settle
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      await FirstTimeLanguageDialog.show(context);
    }
  }

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      // Scrolling down - collapse FAB
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        if (_isExpanded) {
          setState(() {
            _isExpanded = false;
          });
          _fabAnimationController.reverse();
        }
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - expand FAB
      if (_isScrollingDown) {
        _isScrollingDown = false;
        if (!_isExpanded) {
          setState(() {
            _isExpanded = true;
          });
          _fabAnimationController.forward();
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
    // Load from cache first (fast), then refresh from network
    context.read<HomeScreenResultsBloc>().add(LoadLotteryResultsEvent());

    // After a short delay, refresh from network in background
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshResultsInBackground();
      }
    });
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

    // Show background refresh indicator
    if (mounted) {
      setState(() {
        isBackgroundRefreshing = true;
      });
    }

    _lastRefreshTime = DateTime.now();
    context.read<HomeScreenResultsBloc>().add(BackgroundRefreshEvent());

    // Hide indicator after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isBackgroundRefreshing = false;
        });
      }
    });
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

  // Helper method to format points numbers (e.g., 1250 -> "1.25K", 1000000 -> "1M")
  // String _formatPoints(int points) {
  //   if (points < 1000) {
  //     return points.toString();
  //   } else if (points < 1000000) {
  //     double thousands = points / 1000;
  //     if (thousands == thousands.roundToDouble()) {
  //       return '${thousands.round()}K';
  //     } else {
  //       return '${thousands.toStringAsFixed(1)}K';
  //     }
  //   } else {
  //     double millions = points / 1000000;
  //     if (millions == millions.roundToDouble()) {
  //       return '${millions.round()}M';
  //     } else {
  //       return '${millions.toStringAsFixed(1)}M';
  //     }
  //   }
  // }

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
      child: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! < 0) {
            context.go('/news_screen');
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
                          return previous.data.updates.allImages != current.data.updates.allImages;
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
                          fallbackImages: const [
                            'assets/images/sthreesakthi.jpg',
                            'assets/images/bhagyadhara.jpg',
                            'assets/images/karunya-plus.jpg',
                            'assets/images/karunya.jpg',
                            'assets/images/suvarnna-keralam.jpg',
                          ],
                        );
                      },
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 5)),
                    _buildNavigationIcons(theme),
                    SizedBox(height: AppResponsive.spacing(context, 10)),
                    _buildResultsSection(theme),
                    SizedBox(height: AppResponsive.spacing(context, 100)),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildScanButton(theme),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
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
                              transform: GradientRotation(math.pi / 4), // 45 degree angle
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
                        angle: _rotationAnimation.value * 2 * math.pi, // Convert to radians (3 full rotations)
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
                  BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
                    builder: (context, state) {
                      if (state is HomeScreenResultsLoaded) {
                      }
                      return Text(
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
                      );
                    },
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

  Widget _buildNavigationIcons(ThemeData theme) {
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'scanner'.tr(),
        'route': '/barcode_scanner_screen'
      },
      {'icon': Icons.live_tv, 'label': 'Live'.tr(), 'route': '/live_videos'},
      {
        'icon': Icons.games_outlined,
        'label': 'predict'.tr(),
        'route': '/Predict'
      },
      {'icon': Icons.newspaper, 'label': 'news'.tr(), 'route': '/news_screen'},
      {
        'icon': Icons.bookmark,
        'label': 'saved'.tr(),
        'route': '/saved-results'
      },
    ];

    return Container(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppResponsive.spacing(context, 8),
            offset: Offset(0, AppResponsive.spacing(context, 2)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: navItems.map((item) => _buildNavItem(item, theme)).toList(),
      ),
    );
  }

  Widget _buildNavItem(Map<String, dynamic> item, ThemeData theme) {
    final double iconSize = AppResponsive.fontSize(context, 24);
    final double containerSize = AppResponsive.width(
      context,
      AppResponsive.isMobile(context) ? 12 : 8,
    );

    return InkWell(
      onTap: () {
        if (item['route'] != null) {
          // Track navigation analytics
          AnalyticsService.trackUserEngagement(
            action: 'navigation_tap',
            category: 'navigation',
            label: item['label'],
            parameters: {
              'destination': item['route'],
              'feature': item['label'],
            },
          );
          
          // Show interstitial ad before navigating to predict screen (commented out - AdMob account not ready)
          // if (item['route'] == '/Predict') {
          //   _showInterstitialAdAndNavigate(item['route']);
          // } else {
          //   context.go(item['route']);
          // }
          
          // Direct navigation without ads
          context.go(item['route']);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFF2D1518), // Dark red tint for dark theme
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'],
              color: theme.iconTheme.color,
              size: iconSize,
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 8)),
          SizedBox(
            width: AppResponsive.width(context, 15),
            child: Text(
              item['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 12),
                fontWeight: FontWeight.w500,
                color:
                    theme.textTheme.bodyMedium?.color, // Use theme text color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
      buildWhen: (previous, current) {
        // Only rebuild if the actual data changed, not just loading states
        if (previous is HomeScreenResultsLoaded && 
            current is HomeScreenResultsLoaded) {
          return previous.data.results != current.data.results ||
                 previous.isOffline != current.isOffline ||
                 previous.isFiltered != current.isFiltered ||
                 previous.filteredDate != current.filteredDate;
        }
        return true;
      },
      builder: (context, state) {
        if (state is HomeScreenResultsLoading) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.isRefreshing
                      ? 'refreshing_results'.tr()
                      : 'loading_lottery_results'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                ),
                if (state.isRefreshing) ...[
                  const SizedBox(height: 8),
                  Text(
                    'getting_latest_data'.tr(),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                      fontSize: AppResponsive.fontSize(context, 12),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        if (state is HomeScreenResultsError) {
          // If we have offline data, show it with an error banner
          if (state.hasOfflineData && state.offlineData != null) {
            return Column(
              children: [
                // Error banner
                Container(
                  width: double.infinity,
                  color: Colors.red.withValues(alpha: 0.1),
                  padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red,
                          size: AppResponsive.fontSize(context, 20)),
                      SizedBox(width: AppResponsive.spacing(context, 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'connection_error'.tr(),
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppResponsive.fontSize(context, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'showing_cached_data'.tr(),
                              style: TextStyle(
                                color: Colors.red.withValues(alpha: 0.8),
                                fontSize: AppResponsive.fontSize(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _loadLotteryResults,
                        child: Text(
                          'retry'.tr(),
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: AppResponsive.fontSize(context, 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Show cached data
                _buildResultsList(state.offlineData!, theme,
                    isOfflineData: true),
              ],
            );
          }

          // No offline data available
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: AppResponsive.fontSize(context, 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'failed_load_results'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: AppResponsive.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadLotteryResults,
                  icon: const Icon(Icons.refresh),
                  label: Text('try_again'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is HomeScreenResultsLoaded) {
          return _buildResultsList(state.data, theme, state: state);
        }

        return Container(
          padding: const EdgeInsets.all(32),
          child: Text(
            'pull_refresh_lottery_results'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontSize: AppResponsive.fontSize(context, 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateDivider(String text, ThemeData theme) {
    return GestureDetector(
      onTap: _showDatePicker, // Add tap functionality here
      child: Container(
        color: Colors.transparent, // Make the entire area tappable
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider(color: theme.dividerTheme.color)),
              Padding(
                padding: AppResponsive.padding(context, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppResponsive.fontSize(context, 14),
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 6)),
                    Text(
                      text,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Divider(color: theme.dividerTheme.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(HomeScreenResultModel result, ThemeData theme) {
    // Get first 6 consolation tickets for display
    List<String> consolationTickets =
        result.consolationTicketsList.take(6).toList();
    // Split into 2 rows of 3
    List<String> firstRow = consolationTickets.take(3).toList();
    List<String> secondRow = consolationTickets.skip(3).take(3).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            side: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Track lottery result view
              AnalyticsService.trackLotteryEvent(
                eventType: 'result_view',
                lotteryName: result.getFormattedTitle(context),
                resultDate: result.formattedDate,
                additionalParams: {
                  'unique_id': result.uniqueId,
                  'source': 'home_screen_card',
                },
              );
              
              context.go('/result-details', extra: {
                'uniqueId': result.uniqueId,
                'isNew': result.isNew,
              });
            },
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            child: Padding(
              padding:
                  AppResponsive.padding(context, horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with accent line
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: AppResponsive.spacing(context, 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 10)),
                      Expanded(
                        child: Text(
                          result.getFormattedTitle(context),
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 6)),

                  // Prize amount in highlighted container
                  Container(
                    padding: AppResponsive.padding(context,
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.pink[50]
                          : const Color(0xFF2D1518),
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 3)),
                    ),
                    child: Text(
                      result.formattedFirstPrize,
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.pink[900]
                            : Colors.red[300],
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // Winner section
                  Text(
                    'first_prize_winner'.tr(),
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 13),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    result.formattedWinner,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  // Consolation prizes section with divider
                  Divider(
                    color: theme.dividerTheme.color,
                    thickness: 1,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 8)),

                  Text(
                    result.formattedConsolationPrize,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 12)),

                  // First row of consolation prizes
                  if (firstRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: firstRow
                          .map((prize) =>
                              _buildConsolationPrizeContainer(prize, theme))
                          .toList(),
                    ),

                  if (secondRow.isNotEmpty)
                    SizedBox(height: AppResponsive.spacing(context, 8)),

                  // Second row of consolation prizes
                  if (secondRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: secondRow
                          .map((prize) =>
                              _buildConsolationPrizeContainer(prize, theme))
                          .toList(),
                    ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // "See More" button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Track see more button analytics
                        AnalyticsService.trackLotteryEvent(
                          eventType: 'see_more_pressed',
                          lotteryName: result.getFormattedTitle(context),
                          resultDate: result.formattedDate,
                          additionalParams: {
                            'unique_id': result.uniqueId,
                            'source': 'see_more_button',
                          },
                        );
                        
                        context.go('/result-details', extra: {
                          'uniqueId': result.uniqueId,
                          'isNew': result.isNew,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[800]
                            : Colors.red[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 6),
                        elevation:
                            theme.brightness == Brightness.dark ? 2.0 : 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 6)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red[700]!
                                : Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'see_more'.tr(),
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: AppResponsive.fontSize(context, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Badge (New/Live based on time and date)
        if (result.isNew || result.isLive)
          Positioned(
            top: 13,
            right: AppResponsive.spacing(context, 16),
            child: result.isLive
                ? AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _blinkAnimation.value,
                        child: Container(
                          padding: AppResponsive.padding(context,
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  AppResponsive.spacing(context, 8)),
                              bottomRight: Radius.circular(
                                  AppResponsive.spacing(context, 8)),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'live_badge'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppResponsive.fontSize(context, 10),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    padding: AppResponsive.padding(context,
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        bottomLeft:
                            Radius.circular(AppResponsive.spacing(context, 8)),
                        bottomRight:
                            Radius.circular(AppResponsive.spacing(context, 8)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'new_badge'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppResponsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildConsolationPrizeContainer(String prize, ThemeData theme) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey[200]
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 4)),
      ),
      child: Text(
        prize,
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 13),
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildResultsList(
    HomeScreenResultsModel data,
    ThemeData theme, {
    HomeScreenResultsLoaded? state,
    bool isOfflineData = false,
  }) {
    // Build indicators
    List<Widget> indicators = [];

    // Filter indicator
    if (state != null && state.isFiltered && state.filteredDate != null) {
      indicators.add(
        Container(
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
          padding: AppResponsive.padding(context, horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 8)),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                color: theme.colorScheme.primary,
                size: AppResponsive.fontSize(context, 20),
              ),
              SizedBox(width: AppResponsive.spacing(context, 8)),
              Expanded(
                child: Text(
                  '${'showing_results_for'.tr()}${_formatDateForDisplay(state.filteredDate!)}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: AppResponsive.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context
                      .read<HomeScreenResultsBloc>()
                      .add(ClearDateFilterEvent());
                },
                icon: Icon(
                  Icons.clear,
                  size: AppResponsive.fontSize(context, 16),
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'show_all'.tr(),
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 12),
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: AppResponsive.padding(context,
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No results case
    if (data.results.isEmpty) {
      return Column(
        children: [
          ...indicators,
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  size: AppResponsive.fontSize(context, 48),
                ),
                const SizedBox(height: 16),
                Text(
                  (state?.isFiltered == true)
                      ? 'no_results_selected_date'.tr()
                      : 'no_results_available'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 16),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state?.isFiltered == true) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<HomeScreenResultsBloc>()
                          .add(ClearDateFilterEvent());
                    },
                    icon: const Icon(Icons.clear),
                    label: Text(
                      'show_all_results'.tr(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.floatingActionButtonTheme.backgroundColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Group results by date category
    Map<String, List<HomeScreenResultModel>> groupedResults = {};
    for (var result in data.results) {
      String dateCategory = result.formattedDate;
      if (!groupedResults.containsKey(dateCategory)) {
        groupedResults[dateCategory] = [];
      }
      groupedResults[dateCategory]!.add(result);
    }

    // Use CustomScrollView with SliverList for better performance
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        if (indicators.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(children: indicators),
          ),
        ...groupedResults.entries.map((entry) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return _buildDateDivider(entry.key, theme);
                }
                final resultIndex = index - 1;
                if (resultIndex < entry.value.length) {
                  return _buildResultCard(entry.value[resultIndex], theme);
                }
                return null;
              },
              childCount: entry.value.length + 1, // +1 for date divider
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    return AIProbabilityFAB(
      onPressed: () {
        context.pushNamed(RouteNames.probabilityBarcodeScanner);
      },
      sizeAnimation: _fabAnimation,
      theme: theme,
    );
  }
}
