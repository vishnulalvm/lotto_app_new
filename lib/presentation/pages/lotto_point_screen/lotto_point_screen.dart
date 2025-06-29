import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';

class LottoPointsScreen extends StatefulWidget {
  const LottoPointsScreen({super.key});

  @override
  State<LottoPointsScreen> createState() => _LottoPointsScreenState();
}

class _LottoPointsScreenState extends State<LottoPointsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final int totalPoints = 1250;
  
  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _pointsAnimation;
  int _lastAddedPoints = 0;

  // Dummy data for point history
  final List<Map<String, dynamic>> pointHistory = [
    {
      'lottery': 'Akshaya AK 620',
      'points': 50,
      'date': '2024-06-08',
      'type': 'earned',
      'description': 'ticket_purchase_bonus'.tr()
    },
    {
      'lottery': 'Win Win 520',
      'points': 25,
      'date': '2024-06-07',
      'type': 'earned',
      'description': 'daily_login_bonus'.tr()
    },
    {
      'lottery': 'Karunya Plus KN 520',
      'points': 100,
      'date': '2024-06-06',
      'type': 'earned',
      'description': 'referral_bonus'.tr()
    },
    {
      'lottery': 'Nirmal NR 385',
      'points': 75,
      'date': '2024-06-05',
      'type': 'earned',
      'description': 'prediction_bonus'.tr()
    },
    {
      'lottery': 'Pournami RN 645',
      'points': 30,
      'date': '2024-06-03',
      'type': 'earned',
      'description': 'news_reading_bonus'.tr()
    },
  ];

  // Dummy data for redeem options
  final List<Map<String, dynamic>> redeemOptions = [
    {
      'name': 'Akshaya AK 621',
      'image': 'assets/images/five.jpeg',
      'points': 500,
      'price': '₹80'
    },
    {
      'name': 'Win Win 521',
      'image': 'assets/images/four.jpeg',
      'points': 400,
      'price': '₹30'
    },
    {
      'name': 'Karunya Plus KN 521',
      'image': 'assets/images/seven.jpeg',
      'points': 600,
      'price': '₹40'
    },
    {
      'name': 'Nirmal NR 386',
      'image': 'assets/images/six.jpeg',
      'points': 450,
      'price': '₹40'
    },
    {
      'name': 'Pournami RN 646',
      'image': 'assets/images/tree.jpeg',
      'points': 550,
      'price': '₹40'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Get the last added points (most recent earned points)
    _lastAddedPoints = _getLastAddedPoints();
    
    // Calculate starting points (total - last added)
    int startingPoints = totalPoints - _lastAddedPoints;
    
    // Create animation from starting points to total points
    _pointsAnimation = Tween<double>(
      begin: startingPoints.toDouble(),
      end: totalPoints.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation when screen opens
    _startPointsAnimation();
  }

  int _getLastAddedPoints() {
    // Find the most recent earned points from history
    for (var item in pointHistory) {
      if (item['type'] == 'earned') {
        return item['points'] as int;
      }
    }
    return 0; // Fallback if no earned points found
  }

  void _startPointsAnimation() {
    // Add a small delay before starting animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(theme),
          ];
        },
        body: _buildTabBarView(theme),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
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
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                (theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor)
                    .withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppResponsive.spacing(context, 40)),
                Container(
                  padding: AppResponsive.padding(context, horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: theme.primaryColor,
                        size: AppResponsive.fontSize(context, 32),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 7)),
                      AnimatedBuilder(
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
                      ),
                    ],
                  ),
                ),
                // Show the last added points with animation
                if (_animationController.isAnimating || _animationController.isCompleted)
                  Container(
                    margin: EdgeInsets.only(top: AppResponsive.spacing(context, 8)),
                    padding: AppResponsive.padding(context, horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 12)),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                              SizedBox(width: AppResponsive.spacing(context, 4)),
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
            icon: Icon(Icons.history),
            text: 'points_history'.tr(),
          ),
          Tab(
            icon: Icon(Icons.redeem),
            text: 'redeem_points'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ThemeData theme) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildHistoryTab(theme),
        _buildRedeemTab(theme),
      ],
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return ListView.builder(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 16),
      itemCount: pointHistory.length,
      itemBuilder: (context, index) {
        final item = pointHistory[index];
        return _buildHistoryCard(item, theme);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, ThemeData theme) {
    final isEarned = item['type'] == 'earned';
    
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
                    ? (theme.brightness == Brightness.light ? Colors.green[50] : Colors.green.withValues(alpha: 0.2))
                    : (theme.brightness == Brightness.light ? Colors.red[50] : Colors.red.withValues(alpha: 0.2)),
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
                    item['lottery'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppResponsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    item['date'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: AppResponsive.fontSize(context, 12),
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Points
            Container(
              padding: AppResponsive.padding(context, horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEarned 
                    ? (theme.brightness == Brightness.light ? Colors.green[100] : Colors.green.withValues(alpha: 0.3))
                    : (theme.brightness == Brightness.light ? Colors.red[100] : Colors.red.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 20)),
              ),
              child: Text(
                '${isEarned ? '+' : '-'}${item['points']}',
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

  Widget _buildRedeemTab(ThemeData theme) {
    return Padding(
      padding: AppResponsive.padding(context, horizontal: 12, ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppResponsive.spacing(context, 8),
          mainAxisSpacing: AppResponsive.spacing(context, 8),
        ),
        itemCount: redeemOptions.length,
        itemBuilder: (context, index) {
          final item = redeemOptions[index];
          return _buildRedeemCard(item, theme);
        },
      ),
    );
  }

  Widget _buildRedeemCard(Map<String, dynamic> item, ThemeData theme) {
    final canRedeem = totalPoints >= item['points'];
    
    return Card(
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
        side: BorderSide(
          color: canRedeem 
              ? theme.primaryColor
              : theme.dividerTheme.color!,
          width: canRedeem ? .50 : .5,
        ),
      ),
      child: InkWell(
        onTap: canRedeem ? () => _showComingSoonDialog() : null,
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 16)),
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lottery Image - smaller size
              Container(
                height: AppResponsive.height(context, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
                  image: DecorationImage(
                    image: AssetImage(item['image']),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppResponsive.spacing(context, 8)),
              
              // Lottery Name
              Text(
                item['name'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: AppResponsive.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Price
              Text(
                '${'price'.tr()}${item['price']}',
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              
              const Spacer(),
              
              // Large Points Button
              SizedBox(
                width: double.infinity,
                height: AppResponsive.height(context, 4),
                child: ElevatedButton(
                  onPressed: canRedeem ? () => _showComingSoonDialog() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem 
                        ? theme.primaryColor
                        : theme.disabledColor,
                    foregroundColor: Colors.white,
                    elevation: canRedeem ? 2.0 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
                    ),
                    disabledBackgroundColor: theme.disabledColor,
                    disabledForegroundColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: AppResponsive.fontSize(context, 16),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 6)),
                      Text(
                        '${item['points']}${'points'.tr()}',
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
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
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
        );
      },
    );
  }
}