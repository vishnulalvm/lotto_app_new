import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'dart:async';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_bloc.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_event.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_state.dart';
import 'package:lotto_app/presentation/pages/lotto_point_screen/widgets/backgrond.dart';
import 'package:lotto_app/presentation/pages/lotto_point_screen/widgets/cashback_claim_dialog.dart';

class LottoPointsScreen extends StatefulWidget {
  const LottoPointsScreen({super.key});

  @override
  State<LottoPointsScreen> createState() => _LottoPointsScreenState();
}

class _LottoPointsScreenState extends State<LottoPointsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final AdMobService _adMobService = AdMobService.instance;
  Timer? _interstitialAdTimer;
  bool _hasShownInterstitialAd = false;

  // Get cashback rewards from API data
  List<Map<String, dynamic>> _getCashbackRewards(UserPointsState state) {
    if (state is UserPointsLoaded) {
      return state.userPoints.data.cashbackHistory
          .map((cashback) => {
                'amount': cashback.amount.toInt(),
                'status': cashback.isClaimed ? 'claimed' : (cashback.isExpired ? 'expired' : 'available'),
                'date': cashback.formattedDate,
                'cashbackId': cashback.cashbackId,
                'type': 'cashback',
                'isExpired': cashback.isExpired,
                'isAvailable': cashback.isAvailable
              })
          .toList();
    } else if (state is UserPointsRefreshing) {
      return state.userPoints.data.cashbackHistory
          .map((cashback) => {
                'amount': cashback.amount.toInt(),
                'status': cashback.isClaimed ? 'claimed' : (cashback.isExpired ? 'expired' : 'available'),
                'date': cashback.formattedDate,
                'cashbackId': cashback.cashbackId,
                'type': 'cashback',
                'isExpired': cashback.isExpired,
                'isAvailable': cashback.isAvailable
              })
          .toList();
    }
    return [];
  }

  // Dummy data for redeem options
  final List<Map<String, dynamic>> redeemOptions = [
    {
      'name': 'BHAGYATHARA LOTTERY',
      'image': 'assets/images/bhagyadhara.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'DHANALEKSHMI LOTTERY',
      'image': 'assets/images/dhanalakshmi.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'KARUNYA PLUS LOTTERY',
      'image': 'assets/images/karunya-plus.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'KARUNYA LOTTERY',
      'image': 'assets/images/karunya.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'SAMRUDHI LOTTERY',
      'image': 'assets/images/samrudhi.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'STHREE SAKTHI LOTTERY',
      'image': 'assets/images/sthreesakthi.jpg',
      'points': 1000,
      'price': '₹50'
    },
    {
      'name': 'SUVARNA KERALAM LOTTERY',
      'image': 'assets/images/suvarnna-keralam.jpg',
      'points': 1000,
      'price': '₹50'
    },
  ];

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _pointsAnimation;
  int _lastAddedPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animation with default values
    _pointsAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'lotto_points_screen',
          screenClass: 'LottoPointsScreen',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });

    // Fetch user points data
    _fetchUserPoints();

    // Load interstitial ad first and schedule to show after 3 seconds
    _loadInterstitialAdAndSchedule();
  }

  Future<void> _fetchUserPoints() async {
    final phoneNumber = await _userService.getPhoneNumber();
    if (phoneNumber != null && mounted) {
      context.read<UserPointsBloc>().add(
            FetchUserPointsEvent(phoneNumber: phoneNumber),
          );
    }
  }

  int _getDaysUntilExpiration(String dateStr) {
    try {
      // Parse the formatted date (DD-MM-YYYY format)
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dateTime = DateTime(year, month, day);
        final expirationDate = dateTime.add(const Duration(days: 7));
        final now = DateTime.now();
        final difference = expirationDate.difference(now).inDays;
        return difference < 0 ? 0 : difference;
      }
      
      // Fallback: try to parse as ISO format
      final dateTime = DateTime.parse(dateStr);
      final expirationDate = dateTime.add(const Duration(days: 7));
      final now = DateTime.now();
      final difference = expirationDate.difference(now).inDays;
      return difference < 0 ? 0 : difference;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadInterstitialAdAndSchedule() async {
    try {
      // Check if ad is already loaded
      if (_adMobService.isLottoPointsInterstitialAdLoaded) {
        // Ad already loaded, starting timer
        _startInterstitialAdTimer();
        return;
      }
      
      // Load the interstitial ad with retry logic
      await _loadInterstitialAdWithRetry();
      
      // Debug: Check ad status after loading attempts
      // Ad loading completed
      
      // Start timer regardless - if ad loaded, it will show; if not, it will handle gracefully
      _startInterstitialAdTimer();
    } catch (e) {
      // Unexpected error in ad loading process
      // Still start the timer to attempt showing if ad becomes available
      _startInterstitialAdTimer();
    }
  }

  Future<void> _loadInterstitialAdWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3; // Reduced retries since NO_FILL errors won't resolve quickly
    
    while (retryCount < maxRetries) {
      try {
        // Try to load the ad
        await _adMobService.loadLottoPointsInterstitialAd();
        
        // Check if it actually loaded
        if (_adMobService.isLottoPointsInterstitialAdLoaded) {
          // Ad loaded successfully
          return;
        }
        
        retryCount++;
        // Ad loading attempt failed (possibly NO_FILL or rate limited)
        
        // For NO_FILL errors, waiting longer won't help much, but we'll try a few times
        if (retryCount < maxRetries) {
          // Exponential backoff: 3s, 6s, 12s
          final delaySeconds = 3 * (1 << retryCount);
          // Waiting before retry with exponential backoff
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        retryCount++;
        // Ad loading attempt failed with error
        
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }
    
    // Don't throw exception for NO_FILL - it's expected behavior
    // Failed to load interstitial ad - this is normal if no ads are available
  }

  void _startInterstitialAdTimer() {
    if (_hasShownInterstitialAd) return;
    
    // Start with a longer delay to ensure ad is fully loaded
    _interstitialAdTimer = Timer(const Duration(seconds: 5), () {
      _checkAndShowInterstitialAd();
    });
  }

  void _checkAndShowInterstitialAd() {
    if (_hasShownInterstitialAd || !mounted) return;
    
    // Checking interstitial ad availability
    
    if (_adMobService.isLottoPointsInterstitialAdLoaded) {
      _showLottoPointsInterstitialAd();
    } else {
      // Ad not available - this is normal behavior for NO_FILL errors
      // Try a few more times but don't be aggressive about it
      _retryInterstitialAd();
    }
  }

  int _interstitialRetryCount = 0;
  static const int _maxRetries = 2; // Reduced from 3 - less aggressive

  void _retryInterstitialAd() {
    if (_hasShownInterstitialAd || !mounted || _interstitialRetryCount >= _maxRetries) {
      if (_interstitialRetryCount >= _maxRetries) {
        // No interstitial ad available - proceeding without ad (normal behavior)
      }
      return;
    }
    
    _interstitialRetryCount++;
    // Retrying interstitial ad check
    
    // Try to load a fresh ad on retry
    _adMobService.loadLottoPointsInterstitialAd().then((_) {
      if (mounted && !_hasShownInterstitialAd) {
        _interstitialAdTimer = Timer(const Duration(seconds: 3), () {
          _checkAndShowInterstitialAd();
        });
      }
    });
  }

  void _showLottoPointsInterstitialAd() {
    if (_hasShownInterstitialAd) return;
    
    // Attempting to show lotto points interstitial ad
    _hasShownInterstitialAd = true;
    
    _adMobService.showInterstitialAd(
      'lotto_points_interstitial',
      onDismissed: () {
        // Ad dismissed, preloading next ad
        // Ad dismissed, preload next ad for future use
        _adMobService.loadLottoPointsInterstitialAd();
      },
    );
  }

  void _startPointsAnimation(int totalPoints, int lastAddedPoints) {
    // Calculate starting points (total - last added)
    int startingPoints = totalPoints - lastAddedPoints;

    // Update animation values
    _pointsAnimation = Tween<double>(
      begin: startingPoints.toDouble(),
      end: totalPoints.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Add haptic feedback during animation
    _animationController.addStatusListener(_handleAnimationStatus);
    _addHapticFeedbackDuringAnimation(startingPoints, totalPoints);

    // Reset and start animation
    _animationController.reset();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        HapticFeedback
            .lightImpact(); // Initial haptic feedback when animation starts
        _animationController.forward();
      }
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Strong haptic feedback when animation completes
      HapticFeedback.mediumImpact();
      _animationController.removeStatusListener(_handleAnimationStatus);
    }
  }

  void _addHapticFeedbackDuringAnimation(int startingPoints, int totalPoints) {
    // Add haptic feedback at key points during the animation
    int pointsDifference = totalPoints - startingPoints;

    if (pointsDifference > 0) {
      // Add haptic feedback at 25%, 50%, and 75% of animation
      List<double> hapticPoints = [0.25, 0.5, 0.75];

      for (double point in hapticPoints) {
        Future.delayed(Duration(milliseconds: (2000 * point).round()), () {
          if (mounted && _animationController.isAnimating) {
            HapticFeedback.selectionClick(); // Subtle feedback during counting
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _interstitialAdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<UserPointsBloc, UserPointsState>(
        listener: (context, state) {
          if (state is UserPointsLoaded) {
            // Update last added points and start animation
            final history = state.userPoints.data.history;
            _lastAddedPoints =
                history.isNotEmpty ? history.first.pointsEarned : 0;
            _startPointsAnimation(
                state.userPoints.data.totalPoints, _lastAddedPoints);
          }
        },
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(theme, state),
              ];
            },
            body: _buildTabBarView(theme, state),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, UserPointsState state) {
    return SliverAppBar(
      expandedHeight: AppResponsive.height(context, 25),
      floating: false,
      pinned: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.appBarTheme.iconTheme?.color,
          size: AppResponsive.fontSize(context, 24),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'lotto_points'.tr(),
        style: theme.appBarTheme.titleTextStyle?.copyWith(
          fontSize: AppResponsive.fontSize(context, 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: LotteryBackgroundPattern(
          brightness: theme.brightness,
          primaryColor: theme.primaryColor,
          backgroundColor: theme.appBarTheme.backgroundColor ??
              theme.scaffoldBackgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppResponsive.spacing(context, 40)),
                Container(
                  padding: AppResponsive.padding(context,
                      horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPointsDisplay(theme, state),
                    ],
                  ),
                ),
                // Show the last added points with animation
                if (_animationController.isAnimating ||
                    _animationController.isCompleted)
                  Container(
                    margin:
                        EdgeInsets.only(top: AppResponsive.spacing(context, 8)),
                    padding: AppResponsive.padding(context,
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 12)),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return AnimatedOpacity(
                          opacity: _animationController.value,
                          duration: const Duration(milliseconds: 500),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: AppResponsive.fontSize(context, 16),
                              ),
                              SizedBox(
                                  width: AppResponsive.spacing(context, 4)),
                              Text(
                                '+$_lastAddedPoints${'points'.tr()} added',
                                style: TextStyle(
                                  fontSize: AppResponsive.fontSize(context, 12),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        indicatorColor: theme.primaryColor,
        labelStyle: TextStyle(
          fontSize: AppResponsive.fontSize(context, 14),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppResponsive.fontSize(context, 14),
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.redeem),
            text: 'redeem_points'.tr(),
          ),
          Tab(
            icon: Icon(Icons.history),
            text: 'points_history'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsDisplay(ThemeData theme, UserPointsState state) {
    if (state is UserPointsLoading) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
      );
    } else if (state is UserPointsError) {
      return Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: AppResponsive.fontSize(context, 40),
          ),
          SizedBox(height: AppResponsive.spacing(context, 8)),
          Text(
            'Error loading points',
            style: TextStyle(
              fontSize: AppResponsive.fontSize(context, 16),
              color: Colors.red,
            ),
          ),
          TextButton(
            onPressed: _fetchUserPoints,
            child: Text('Retry'),
          ),
        ],
      );
    } else if (state is UserPointsLoaded || state is UserPointsRefreshing) {
      return AnimatedBuilder(
        animation: _pointsAnimation,
        builder: (context, child) {
          return AnimatedFlipCounter(
            value: _pointsAnimation.value.round(),
            duration: const Duration(milliseconds: 300),
            textStyle: TextStyle(
              fontSize: AppResponsive.fontSize(context, 55),
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Text(
        '0',
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 55),
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTabBarView(ThemeData theme, UserPointsState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRedeemTab(theme, state),
        _buildHistoryTab(theme, state),
      ],
    );
  }

  Widget _buildHistoryTab(ThemeData theme, UserPointsState state) {
    if (state is UserPointsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is UserPointsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading history', style: TextStyle(fontSize: 16)),
            TextButton(
              onPressed: _fetchUserPoints,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state is UserPointsLoaded || state is UserPointsRefreshing) {
      final history = state is UserPointsLoaded
          ? state.userPoints.data.history
          : (state as UserPointsRefreshing).userPoints.data.history;

      if (history.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 50,
                color: theme.disabledColor,
              ),
              SizedBox(height: 16),
              Text(
                'No points history available',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _fetchUserPoints();
        },
        child: ListView.builder(
          padding: AppResponsive.padding(context, horizontal: 16, vertical: 16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildHistoryCard(item, theme);
          },
        ),
      );
    } else {
      return const Center(child: Text('No data available'));
    }
  }

  Widget _buildHistoryCard(dynamic item, ThemeData theme) {
    // Handle both old format (Map) and new format (PointHistoryItem)
    final String lotteryName;
    final String date;
    final int points;
    final bool isEarned;

    if (item is Map<String, dynamic>) {
      // Old format (for backward compatibility)
      lotteryName = item['lottery'] ?? '';
      date = item['date'] ?? '';
      points = item['points'] ?? 0;
      isEarned = item['type'] == 'earned' || points > 0;
    } else {
      // New format (PointHistoryItem) - API only returns earned points
      lotteryName = item.lotteryName;
      date = item.date;
      points = item.pointsEarned;
      isEarned = points > 0; // Consider negative points as spent
    }

    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, vertical: 6),
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: AppResponsive.padding(context, horizontal: 10, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: AppResponsive.width(context, 12),
              height: AppResponsive.width(context, 12),
              decoration: BoxDecoration(
                color: isEarned
                    ? (theme.brightness == Brightness.light
                        ? Colors.green[50]
                        : Colors.green.withValues(alpha: 0.2))
                    : (theme.brightness == Brightness.light
                        ? Colors.red[50]
                        : Colors.red.withValues(alpha: 0.2)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEarned ? Icons.add : Icons.remove,
                color: isEarned ? Colors.green : Colors.red,
                size: AppResponsive.fontSize(context, 20),
              ),
            ),

            SizedBox(width: AppResponsive.spacing(context, 16)),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lotteryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppResponsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: AppResponsive.fontSize(context, 12),
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Points
            Container(
              padding:
                  AppResponsive.padding(context, horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEarned
                    ? (theme.brightness == Brightness.light
                        ? Colors.green[100]
                        : Colors.green.withValues(alpha: 0.3))
                    : (theme.brightness == Brightness.light
                        ? Colors.red[100]
                        : Colors.red.withValues(alpha: 0.3)),
                borderRadius:
                    BorderRadius.circular(AppResponsive.spacing(context, 20)),
              ),
              child: Text(
                '${isEarned ? '+' : '-'}$points',
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: isEarned ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemTab(ThemeData theme, UserPointsState state) {
    int totalPoints = 0;

    if (state is UserPointsLoaded) {
      totalPoints = state.userPoints.data.totalPoints;
    } else if (state is UserPointsRefreshing) {
      totalPoints = state.userPoints.data.totalPoints;
    }

    return Padding(
      padding: AppResponsive.padding(
        context,
        horizontal: 10,
        vertical: 15,
      ),
      child: CustomScrollView(
        slivers: [
          // Cash Rewards Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  AppResponsive.padding(context, horizontal: 3, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.redeem,
                    color: theme.primaryColor,
                    size: AppResponsive.fontSize(context, 20),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 8)),
                  Text(
                    'Cash Rewards',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: AppResponsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // SizedBox(width: AppResponsive.spacing(context, 8)),
                  IconButton(
                    onPressed: () => _showCashbackDisclaimer(),
                    icon: Icon(
                      Icons.info_outline,
                      color: theme.primaryColor,
                      size: AppResponsive.fontSize(context, 20),
                    ),
                    constraints: BoxConstraints(
                      minWidth: AppResponsive.width(context, 8),
                      minHeight: AppResponsive.width(context, 8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // Cash Rewards Grid or Empty State
          _getCashbackRewards(state).isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: AppResponsive.height(context, 14),
                    margin: AppResponsive.margin(context, horizontal: 6),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 16)),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.redeem,
                          size: AppResponsive.fontSize(context, 40),
                          color: theme.disabledColor,
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        Text(
                          'No cashback rewards available',
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 4)),
                        Text(
                          'Complete lottery checks to earn cashback',
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 12),
                            color: theme.disabledColor.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: AppResponsive.spacing(context, 8),
                    mainAxisSpacing: AppResponsive.spacing(context, 8),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cashRewards = _getCashbackRewards(state);
                      if (index < cashRewards.length) {
                        return _buildCashRewardCard(
                          cashRewards[index],
                          theme,
                          key: ValueKey('cash_reward_$index'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: _getCashbackRewards(state).length,
                  ),
                ),

          // Section Divider
          SliverToBoxAdapter(
            child: Container(
              margin:
                  AppResponsive.margin(context, vertical: 10, horizontal: 6),
              child: Column(
                children: [
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    thickness: 1,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 16)),
                  Row(
                    children: [
                      Icon(
                        Icons.local_activity,
                        color: theme.primaryColor,
                        size: AppResponsive.fontSize(context, 20),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 8)),
                      Text(
                        'redeem_points'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: AppResponsive.fontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Redeem Cards Grid
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Increased height to prevent overflow
              crossAxisSpacing: AppResponsive.spacing(context, 8),
              mainAxisSpacing: AppResponsive.spacing(context, 8),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Show redeem card if we have one
                if (index < redeemOptions.length) {
                  return _buildRedeemCard(
                    redeemOptions[index],
                    theme,
                    totalPoints,
                    key: ValueKey('redeem_$index'),
                  );
                }

                // Return empty container if no more items
                return const SizedBox.shrink();
              },
              childCount: redeemOptions.length, // Redeem cards only
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRedeemCard(
      Map<String, dynamic> item, ThemeData theme, int totalPoints,
      {Key? key}) {
    final canRedeem = totalPoints >= item['points'];

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
        border: Border.all(
          color: canRedeem
              ? theme.primaryColor.withValues(alpha: 0.3)
              : (theme.dividerTheme.color ?? theme.colorScheme.outline)
                  .withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: canRedeem
                ? theme.primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canRedeem ? () => _showComingSoonDialog() : null,
          borderRadius:
              BorderRadius.circular(AppResponsive.spacing(context, 16)),
          child: Padding(
            padding:
                AppResponsive.padding(context, horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lottery Image with modern styling
                Container(
                  height: AppResponsive.height(context, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 10)),
                    image: DecorationImage(
                      image: AssetImage(item['image']),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 10)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppResponsive.spacing(context, 10)),

                // Content section - takes remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lottery Name (Primary text)
                      Text(
                        item['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppResponsive.fontSize(context, 14),
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: AppResponsive.spacing(context, 4)),

                      // Price (Secondary text)
                      Row(
                        children: [
                          Text(
                            'Price: ',
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 11),
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            item['price'],
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 12),
                              fontWeight: FontWeight.w700,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppResponsive.spacing(context, 6)),

                      // Redeem feature information
                      Container(
                        padding: AppResponsive.padding(context,
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 6)),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: AppResponsive.fontSize(context, 12),
                              color: theme.primaryColor.withValues(alpha: 0.8),
                            ),
                            SizedBox(width: AppResponsive.spacing(context, 4)),
                            Expanded(
                              child: Text(
                                'Use your points to get this lottery ticket',
                                style: TextStyle(
                                  fontSize: AppResponsive.fontSize(context, 10),
                                  color:
                                      theme.primaryColor.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Call to Action Button - pinned to bottom
                      Container(
                        width: double.infinity,
                        height: AppResponsive.height(context, 3.8),
                        decoration: BoxDecoration(
                          gradient: canRedeem
                              ? LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: canRedeem ? null : theme.disabledColor,
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 8)),
                          boxShadow: canRedeem
                              ? [
                                  BoxShadow(
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canRedeem
                                ? () => _showComingSoonDialog()
                                : null,
                            borderRadius: BorderRadius.circular(
                                AppResponsive.spacing(context, 8)),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.redeem,
                                    size: AppResponsive.fontSize(context, 14),
                                    color: canRedeem
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.6),
                                  ),
                                  SizedBox(
                                      width: AppResponsive.spacing(context, 6)),
                                  Text(
                                    'Redeem ${item['points']} pts',
                                    style: TextStyle(
                                      fontSize:
                                          AppResponsive.fontSize(context, 12),
                                      fontWeight: FontWeight.w700,
                                      color: canRedeem
                                          ? Colors.white
                                          : theme.textTheme.bodyMedium?.color
                                              ?.withValues(alpha: 0.6),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashRewardCard(Map<String, dynamic> reward, ThemeData theme,
      {Key? key}) {
    final bool isAvailable = reward['status'] == 'available';
    final bool isClaimed = reward['status'] == 'claimed';
    final bool isExpired = reward['status'] == 'expired';

    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAvailable
              ? [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ]
              : isClaimed
                  ? [
                      Colors.green[600]!,
                      Colors.green[700]!,
                    ]
                  : isExpired
                      ? [
                          Colors.red[600]!,
                          Colors.red[700]!,
                        ]
                      : [
                          Colors.grey[600]!,
                          Colors.grey[700]!,
                        ],
        ),
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
        boxShadow: [
          BoxShadow(
            color: isAvailable
                ? theme.primaryColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Big celebration icon in background
          Positioned(
            top: 20,
            right: -20,
            child: Icon(
              Icons.celebration,
              size: 120,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Background decorative elements
          Positioned(
            top: 20,
            left: 20,
            child: Icon(
              Icons.redeem,
              size: 24,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Icon(
              Icons.star_outline,
              size: 18,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 60,
            left: 40,
            child: Icon(
              Icons.circle,
              size: 12,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Main content
          Padding(
            padding:
                AppResponsive.padding(context, horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppResponsive.spacing(context, 8)),

                // Amount
                Text(
                  '₹${reward['amount']}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppResponsive.fontSize(context, 32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 1)),

                // Description
                Text(
                  isClaimed ? 'Cashback claimed' : isExpired ? 'Cashback expired' : 'Cashback received',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: AppResponsive.fontSize(context, 12),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 6)),

                // Date
                Text(
                  reward['date'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: AppResponsive.fontSize(context, 12),
                  ),
                ),

                // Expiration indicator for available cashback
                if (isAvailable) ...[
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Container(
                    padding: AppResponsive.padding(context, horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 4)),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Expires in ${_getDaysUntilExpiration(reward['date'])} days',
                      style: TextStyle(
                        color: Colors.orange[200],
                        fontSize: AppResponsive.fontSize(context, 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: AppResponsive.spacing(context, 12)),

                // Claim button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isAvailable ? () => _showCashbackClaimDialog(reward) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          isClaimed ? Colors.green[600] : theme.primaryColor,
                      padding: AppResponsive.padding(context, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppResponsive.spacing(context, 6)),
                      ),
                      elevation: 0,
                      minimumSize: Size.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isClaimed) ...[
                          Icon(
                            Icons.check_circle,
                            size: AppResponsive.fontSize(context, 16),
                            color: Colors.green[600],
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 4)),
                        ],
                        Text(
                          isClaimed
                              ? 'Claimed'
                              : isExpired
                                  ? 'Expired'
                                  : isAvailable
                                      ? 'Claim'
                                      : 'Unavailable',
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCashbackClaimDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return CashbackClaimDialog(
          reward: reward,
          onClaimed: () {
            // Refresh points data and preload next ad
            _fetchUserPoints();
          },
        );
      },
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return PopScope(
          canPop: true,
          child: AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppResponsive.spacing(context, 16)),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.primaryColor,
                  size: AppResponsive.fontSize(context, 24),
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                Text(
                  'coming_soon'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: AppResponsive.fontSize(context, 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'feature_under_development'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: Text(
                  'ok'.tr(),
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showCashbackDisclaimer() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.primaryColor,
                size: AppResponsive.fontSize(context, 24),
              ),
              SizedBox(width: AppResponsive.spacing(context, 8)),
              Text(
                'Cashback Terms',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Cashback rewards expire 7 days after being received',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                '• Watch the ad completely to claim your cashback',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                '• Claims are processed via WhatsApp contact',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                '• Expired cashback cannot be claimed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
