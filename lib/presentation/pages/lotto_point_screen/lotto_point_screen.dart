import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_bloc.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_event.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_state.dart';
import 'package:lotto_app/presentation/pages/lotto_point_screen/widget/backgrond.dart';
import 'package:lotto_app/presentation/widgets/native_ad_point_widget.dart';

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
  Timer? _rewardedAdTimer;
  bool _hasShownRewardedAd = false;

  // Get cashback rewards from API data
  List<Map<String, dynamic>> _getCashbackRewards(UserPointsState state) {
    if (state is UserPointsLoaded) {
      return state.userPoints.data.cashbackHistory
          .map((cashback) => {
                'amount': cashback.amount.toInt(),
                'status': cashback.isClaimed ? 'claimed' : 'available',
                'date': cashback.formattedDate,
                'cashbackId': cashback.cashbackId,
                'type': 'cashback'
              })
          .toList();
    } else if (state is UserPointsRefreshing) {
      return state.userPoints.data.cashbackHistory
          .map((cashback) => {
                'amount': cashback.amount.toInt(),
                'status': cashback.isClaimed ? 'claimed' : 'available',
                'date': cashback.formattedDate,
                'cashbackId': cashback.cashbackId,
                'type': 'cashback'
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

    // Fetch user points data
    _fetchUserPoints();

    // Preload rewarded ad for cashback claims
    _adMobService.loadCashbackClaimRewardedAd();
    
    // Load and schedule the lotto points rewarded ad to show after 3 seconds
    _adMobService.loadLottoPointsRewardedAd();
    _startRewardedAdTimer();
  }

  Future<void> _fetchUserPoints() async {
    final phoneNumber = await _userService.getPhoneNumber();
    if (phoneNumber != null && mounted) {
      context.read<UserPointsBloc>().add(
            FetchUserPointsEvent(phoneNumber: phoneNumber),
          );
    }
  }

  void _startRewardedAdTimer() {
    if (_hasShownRewardedAd) return;
    
    _rewardedAdTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasShownRewardedAd && _adMobService.isLottoPointsRewardedAdLoaded) {
        _showLottoPointsRewardedAd();
      }
    });
  }

  void _showLottoPointsRewardedAd() {
    if (_hasShownRewardedAd) return;
    
    _hasShownRewardedAd = true;
    
    _adMobService.showRewardedAd(
      'lotto_points_rewarded',
      onRewardEarned: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanks for watching! Enjoy your lotto points experience.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      onDismissed: () {
        // Ad dismissed, preload next ad for future use
        _adMobService.loadLottoPointsRewardedAd();
      },
      onFailed: (error) {
        // Silently fail - don't show error to user for this type of ad
        // Try to reload for next time
        _adMobService.loadLottoPointsRewardedAd();
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
    _rewardedAdTimer?.cancel();
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
                  AppResponsive.padding(context, horizontal: 6, vertical: 8),
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
                ],
              ),
            ),
          ),

          // Cash Rewards Grid or Empty State
          _getCashbackRewards(state).isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: AppResponsive.height(context, 15),
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
                    childAspectRatio: 0.95,
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
                // Calculate actual redeem item index considering single ad
                int redeemIndex = index;
                if (index > 3) {
                  redeemIndex =
                      index - 1; // Account for single ad at position 3
                }

                // Check if this position should show an ad
                // CRITICAL FIX: AdMob Policy Compliance - Maximum 1 ad per screen
                bool shouldShowAd = false;
                if (index == 3 && redeemOptions.length > 5) {
                  // Show only ONE ad at position 3 (middle of screen) if enough content
                  shouldShowAd = true;
                }

                if (shouldShowAd) {
                  return _buildNativeAdCard(theme, key: ValueKey('ad_$index'));
                }

                // Show redeem card if we have one
                if (redeemIndex >= 0 && redeemIndex < redeemOptions.length) {
                  return _buildRedeemCard(
                    redeemOptions[redeemIndex],
                    theme,
                    totalPoints,
                    key: ValueKey('redeem_$redeemIndex'),
                  );
                }

                // Return empty container if no more items
                return const SizedBox.shrink();
              },
              childCount: redeemOptions.length + 1, // Redeem cards + max 1 ad
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAdCard(ThemeData theme, {Key? key}) {
    return Stack(
      children: [
        NativePointAdWidget(
          key: key,
          height: null, // Let grid control height via aspect ratio
          borderRadius:
              BorderRadius.circular(AppResponsive.spacing(context, 16)),
          margin: EdgeInsets.zero, // No margin as grid handles spacing
        ),
        // CRITICAL: AdMob Policy Compliance - Clear Ad Label
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
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
                  isClaimed ? 'Cashback claimed' : 'Cashback received',
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

                SizedBox(height: AppResponsive.spacing(context, 12)),

                // Claim button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isAvailable ? () => _showClaimDialog(reward) : null,
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

  void _showClaimDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic _) {
            if (didPop) return;

            // Manually handle the pop
            Navigator.of(context).pop();
          },
          child: AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppResponsive.spacing(context, 16)),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.redeem,
                  color: theme.primaryColor,
                  size: AppResponsive.fontSize(context, 24),
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                Text(
                  'Claim Cashback',
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
                  'Claim your ₹${reward['amount']} cashback reward?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                ),
                if (reward['cashbackId'] != null) ...[
                  SizedBox(height: AppResponsive.spacing(context, 8)),
                  Container(
                    padding: AppResponsive.padding(context,
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 8)),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppResponsive.fontSize(context, 16),
                          color: theme.primaryColor,
                        ),
                        SizedBox(width: AppResponsive.spacing(context, 8)),
                        Expanded(
                          child: Text(
                            'ID: ${reward['cashbackId']}',
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 12),
                              color: theme.textTheme.bodySmall?.color,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRewardedAdForClaim(reward);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Claim',
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

  void _showComingSoonDialog() {
    showDialog(
      context: context,
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

  void _showRewardedAdForClaim(Map<String, dynamic> reward) {
    // Load ad if not available
    if (!_adMobService.isCashbackClaimRewardedAdLoaded) {
      _adMobService.loadCashbackClaimRewardedAd();
    }

    // Show the rewarded ad
    _adMobService.showRewardedAd(
      'cashback_claim_rewarded',
      onRewardEarned: () {
        // User completed the ad - show confirmation dialog
        _showCashbackClaimedDialog(reward);
      },
      onDismissed: () {
        // User dismissed the ad without completing it
        // Do nothing - they didn't earn the reward
      },
      onFailed: (error) {
        // Ad failed to show - show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Could not load reward ad. Please try again later.')),
        );
      },
    );
  }

  void _showCashbackClaimedDialog(Map<String, dynamic> reward) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  Icons.check_circle,
                  color: Colors.green,
                  size: AppResponsive.fontSize(context, 24),
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                Text(
                  'Cashback Claimed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: AppResponsive.fontSize(context, 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Congratulations! You have successfully claimed ₹${reward['amount']} cashback.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppResponsive.fontSize(context, 14),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Launch WhatsApp with claim request
                  _launchWhatsAppClaimRequest(reward);
                  // Refresh the points to update the UI
                  _fetchUserPoints();
                  // Preload next ad
                  _adMobService.loadCashbackClaimRewardedAd();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Great!',
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

  Future<void> _launchWhatsAppClaimRequest(Map<String, dynamic> reward) async {
    try {
      // Get user ID from user service
      final phoneNumber = await _userService.getPhoneNumber();
      final userId = phoneNumber ?? 'Unknown';

      // Format the claim message
      final message = '''🎉 *Cashback Claim Request*

👤 *User ID:* $userId
💰 *Amount:* ₹${reward['amount']}
📋 *Cashback ID:* ${reward['cashbackId'] ?? 'N/A'}
📅 *Date:* ${reward['date']}

Please process my cashback claim. I have completed the required ad and am eligible for this reward.

Thank you! 🙏''';

      // WhatsApp number (with country code, no + sign)
      const whatsappNumber = '916238970003';

      // Create WhatsApp URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

      // Launch WhatsApp
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not open WhatsApp. Please make sure WhatsApp is installed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
