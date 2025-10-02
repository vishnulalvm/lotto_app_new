import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/widgets/manual_entry_dialog.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/widgets/challenge_scanner_dialog.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_event.dart';
import 'package:lotto_app/presentation/blocs/lottery_statistics/lottery_statistics_state.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_bloc.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_event.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_state.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_entry_model.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isStatisticsExpanded = false;
  final UserService _userService = UserService();
  List<LotteryEntry> _lotteryEntries = [];
  Timer? _adTimer;
  bool _hasDummyData = false;
  static const String _firstVisitKey = 'challenge_screen_first_visit';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkAndLoadDummyData();
    _loadLotteryStatistics();

    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'challenge_screen',
          screenClass: 'ChallengeScreen',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });

    // Preload and schedule interstitial ad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAndScheduleInterstitialAd();
    });
  }

  Future<void> _checkAndLoadDummyData() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstVisit = prefs.getBool(_firstVisitKey) ?? true;

    if (isFirstVisit) {
      setState(() {
        _hasDummyData = true;
        _lotteryEntries = _generateDummyData();
      });

      // Mark as visited
      await prefs.setBool(_firstVisitKey, false);
    }
  }

  List<LotteryEntry> _generateDummyData() {
    final now = DateTime.now();
    return [
      LotteryEntry(
        id: 'dummy_1',
        serialNo: 1,
        lotteryNumber: 'MN123456',
        lotteryName: 'SAMRUDHI',
        price: 50.0,
        dateAdded: now.subtract(const Duration(days: 2)),
        winningAmount: 0.0,
        status: LotteryStatus.pending,
        lotteryUniqueId: null,
      ),
      LotteryEntry(
        id: 'dummy_2',
        serialNo: 2,
        lotteryNumber: 'PB654321',
        lotteryName: 'KARUNYA PLUS',
        price: 50.0,
        dateAdded: now.subtract(const Duration(days: 5)),
        winningAmount: 100.0,
        status: LotteryStatus.won,
        lotteryUniqueId: null,
      ),
      LotteryEntry(
        id: 'dummy_3',
        serialNo: 3,
        lotteryNumber: 'KB987654',
        lotteryName: 'KARUNYA',
        price: 50.0,
        dateAdded: now.subtract(const Duration(days: 7)),
        winningAmount: 0.0,
        status: LotteryStatus.lost,
        lotteryUniqueId: null,
      ),
    ];
  }

  Future<void> _loadLotteryStatistics({bool forceRefresh = false}) async {
    final userId = await _userService.getPhoneNumber();
    if (userId != null && mounted) {
      if (forceRefresh) {
        context.read<LotteryStatisticsBloc>().add(
          RefreshLotteryStatistics(userId: userId),
        );
      } else {
        context.read<LotteryStatisticsBloc>().add(
          LoadLotteryStatistics(userId: userId),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more entries for infinite scroll
    }
  }



  LotteryEntry _convertToLotteryEntry(LotteryEntryModel model) {
    return LotteryEntry(
      id: model.id.toString(),
      serialNo: model.slNo,
      lotteryNumber: model.lotteryNumber,
      lotteryName: model.lotteryName,
      price: model.price,
      dateAdded: model.dateAdded,
      winningAmount: model.winningAmount,
      status: _convertStatus(model.status),
      lotteryUniqueId: model.lotteryUniqueId,
    );
  }

  LotteryStatus _convertStatus(LotteryEntryStatus status) {
    switch (status) {
      case LotteryEntryStatus.won:
        return LotteryStatus.won;
      case LotteryEntryStatus.lost:
        return LotteryStatus.lost;
      case LotteryEntryStatus.pending:
        return LotteryStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<LotteryStatisticsBloc, LotteryStatisticsState>(
          listener: (context, state) {
            if (state is LotteryStatisticsLoaded) {
              // Don't override if we have dummy data and API returns empty
              if (_hasDummyData && state.data.lotteryEntries.isEmpty) {
                return;
              }

              setState(() {
                _lotteryEntries = state.data.lotteryEntries
                    .map(_convertToLotteryEntry)
                    .toList();

                // If API has real data, remove dummy data flag
                if (state.data.lotteryEntries.isNotEmpty) {
                  _hasDummyData = false;
                }
              });
            }
          },
        ),
        BlocListener<LotteryPurchaseBloc, LotteryPurchaseState>(
          listener: (context, state) {
            if (state is LotteryPurchaseDeleteSuccess) {
              // Hide loading snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('entry_deleted_successfully'.tr())),
              );
              
              // Refresh data
              _loadLotteryStatistics(forceRefresh: true);
            } else if (state is LotteryPurchaseDeleteError) {
              // Hide loading snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${'delete_failed'.tr()}: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: BlocBuilder<LotteryStatisticsBloc, LotteryStatisticsState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildMotivationalBanner(theme),
                _buildStatisticsSection(theme, state),
                Expanded(
                  child: _buildCombinedTable(theme, state),
                ),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(theme),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.go('/');
        },
      ),
      title: Text(
        'Challenge',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.appBarTheme.iconTheme?.color),
          onSelected: (value) {
            if (value == 'manual_entry') {
              _showManualEntryDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'manual_entry',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 12),
                  Text('manual_entry'.tr()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationalBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.2),
            theme.primaryColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.08 : 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add Lottery and Start Challenge',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your wins, losses, and see your progress!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme, LotteryStatisticsState state) {
    double totalExpense = 0.0;
    double totalWinnings = 0.0;
    int totalTickets = 0;
    double netProfitLoss = 0.0;
    double winRate = 0.0;

    if (state is LotteryStatisticsLoaded) {
      final stats = state.data.challengeStatistics;
      totalExpense = stats.totalExpense;
      totalWinnings = stats.totalWinnings;
      totalTickets = stats.totalTickets;
      netProfitLoss = stats.netResult;
      winRate = stats.winRate;
    } else {
      // Fallback to calculate from local data if API data not available
      totalExpense = _lotteryEntries.fold<double>(0.0, (sum, entry) => sum + entry.price);
      totalWinnings = _lotteryEntries.fold<double>(0.0, (sum, entry) => sum + entry.winningAmount);
      totalTickets = _lotteryEntries.length;
      netProfitLoss = totalWinnings - totalExpense;
      winRate = totalTickets > 0 ? (_lotteryEntries.where((e) => e.status == LotteryStatus.won).length / totalTickets) * 100 : 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isStatisticsExpanded = !_isStatisticsExpanded;
              });
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'challenge_statistics'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 20,
                    ),
                  ),
                ),
                Icon(
                  _isStatisticsExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
          // Motivational message for new users
          if (totalTickets == 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.15),
                    theme.primaryColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Start Your Challenge!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your lottery tickets and track your wins! Use the + button to scan or manually enter your lottery entries.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          // Expandable statistics content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isStatisticsExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'total_expense'.tr(),
                  '�${totalExpense.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'total_winnings'.tr(),
                  '�${totalWinnings.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'total_tickets'.tr(),
                  totalTickets.toString(),
                  Icons.confirmation_number,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'win_rate'.tr(),
                  '${winRate.toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: netProfitLoss >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: netProfitLoss >= 0 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  netProfitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: netProfitLoss >= 0 ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'net_result'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: netProfitLoss >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '�${netProfitLoss.abs().toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netProfitLoss >= 0 ? Colors.green : Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedTable(ThemeData theme, LotteryStatisticsState state) {
    if (state is LotteryStatisticsLoading) {
      return _buildLoadingState(theme);
    }

    if (state is LotteryStatisticsError) {
      return _buildErrorState(theme, state.message);
    }

    if (_lotteryEntries.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 80,
          headingRowHeight: 50,
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => theme.primaryColor.withValues(alpha: 0.1),
          ),
          headingTextStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
            fontSize: 16,
          ),
          dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
          ),
          columns: [
            DataColumn(
              label: SizedBox(
                width: 40,
                child: Text(
                  'sl_no'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  'lottery_number'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 100,
                child: Text(
                  'lottery_name'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 60,
                child: Text(
                  'price'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 60,
                child: Text(
                  'date'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 70,
                child: Text(
                  'winnings'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 60,
                child: Text(
                  'status'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 90,
                child: Text(
                  'view_result'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 50,
                child: Text(
                  'action'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          rows: _lotteryEntries.map((entry) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.serialNo.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      entry.lotteryNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.lotteryName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60,
                    child: Text(
                      '₹${entry.price.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60,
                    child: Text(
                      DateFormat('dd/MM').format(entry.dateAdded),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 70,
                    child: Text(
                      entry.winningAmount > 0 ? '₹${entry.winningAmount.toStringAsFixed(0)}' : '-',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: entry.winningAmount > 0 ? Colors.green : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(entry.status),
                        size: 20,
                        color: _getStatusColor(entry.status),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: _shouldShowViewResultButton(entry.status)
                        ? ElevatedButton(
                            onPressed: () => _navigateToResultDetails(entry.lotteryUniqueId, entry.lotteryNumber),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(60, 28),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 1,
                            ),
                            child: Text('view'.tr()),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 50,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withValues(alpha: 0.7),
                        size: 22,
                      ),
                      onPressed: () => _deleteEntry(entry.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading lottery statistics...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadLotteryStatistics(forceRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'no_lottery_entries'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'tap_add_button_to_start'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _scanLottery,
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.qr_code_scanner),
      label: Text('scan_lottery'.tr()),
      elevation: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Color _getStatusColor(LotteryStatus status) {
    switch (status) {
      case LotteryStatus.won:
        return Colors.green;
      case LotteryStatus.lost:
        return Colors.red;
      case LotteryStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(LotteryStatus status) {
    switch (status) {
      case LotteryStatus.won:
        return Icons.check_circle;
      case LotteryStatus.lost:
        return Icons.cancel;
      case LotteryStatus.pending:
        return Icons.access_time;
    }
  }


  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(
        onEntryAdded: (String lotteryNumber, double price, DateTime date, String lotteryName) {
          _addNewEntry(lotteryNumber, price, date, lotteryName);
        },
      ),
    );
  }

  void _scanLottery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeScannerDialog(
          onScanResult: (String lotteryNumber, double? price, DateTime date, String? lotteryName) {
            Navigator.pop(context, {
              'lotteryNumber': lotteryNumber,
              'price': price ?? 0.0,
              'date': date,
              'lotteryName': lotteryName,
            });
          },
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      _addNewEntry(
        result['lotteryNumber'] as String,
        result['price'] as double,
        result['date'] as DateTime,
        result['lotteryName'] as String?,
      );
    }
  }

  void _addNewEntry(String lotteryNumber, double price, DateTime date, [String? lotteryName]) {
    // Optimistic update - add entry to UI immediately
    setState(() {
      // Remove dummy data when first real entry is added
      if (_hasDummyData) {
        _lotteryEntries.clear();
        _hasDummyData = false;
      }

      final newEntry = LotteryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serialNo: _lotteryEntries.length + 1,
        lotteryNumber: lotteryNumber,
        lotteryName: lotteryName ?? 'Unknown',
        price: price,
        dateAdded: date,
        winningAmount: 0.0,
        status: LotteryStatus.pending,
        lotteryUniqueId: null, // Will be updated when API returns the data
      );
      _lotteryEntries.insert(0, newEntry); // Add to the beginning for newest first
    });

    // Refresh statistics from API in background to get updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadLotteryStatistics(forceRefresh: true);
    });
  }

  Future<void> _deleteEntry(String entryId) async {
    // Check if this is a dummy entry
    if (entryId.startsWith('dummy_')) {
      // Simply remove from UI for dummy entries
      setState(() {
        _lotteryEntries.removeWhere((entry) => entry.id == entryId);
        // If all dummy entries are deleted, clear the flag
        if (_lotteryEntries.isEmpty) {
          _hasDummyData = false;
        }
      });
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_entry'.tr()),
        content: Text('delete_entry_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      // Get user ID
      final userId = await _userService.getUserId();
      if (userId == null) {
        throw Exception('User not found');
      }

      // Convert string ID to integer for API call
      final id = int.parse(entryId);

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('deleting_entry'.tr()),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      // Call delete API
      if (!mounted) return;
      context.read<LotteryPurchaseBloc>().add(
        DeleteLotteryPurchase(userId: userId, id: id),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'delete_failed'.tr()}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _preloadAndScheduleInterstitialAd() {
    AdMobService.instance.loadChallengeInterstitialAd();

    _adTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _showInterstitialAd();
      }
    });
  }

  void _showInterstitialAd() async {
    if (AdMobService.instance.isChallengeInterstitialAdLoaded) {
      await AdMobService.instance.showInterstitialAd('challenge_interstitial');
    }
  }

  bool _shouldShowViewResultButton(LotteryStatus status) {
    return status == LotteryStatus.won || status == LotteryStatus.lost;
  }

  void _navigateToResultDetails(String? lotteryUniqueId, String lotteryNumber) {
    if (lotteryUniqueId != null && lotteryUniqueId.isNotEmpty) {
      context.go('/result-details', extra: {
        'uniqueId': lotteryUniqueId,
        'lotteryNumber': lotteryNumber,
        'isNew': false,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lottery_unique_id_not_available'.tr())),
      );
    }
  }
}

// Data Models
class LotteryEntry {
  final String id;
  final int serialNo;
  final String lotteryNumber;
  final String lotteryName;
  final double price;
  final DateTime dateAdded;
  final double winningAmount;
  final LotteryStatus status;
  final String? lotteryUniqueId;

  LotteryEntry({
    required this.id,
    required this.serialNo,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.price,
    required this.dateAdded,
    required this.winningAmount,
    required this.status,
    this.lotteryUniqueId,
  });
}

enum LotteryStatus {
  won,
  lost,
  pending,
}