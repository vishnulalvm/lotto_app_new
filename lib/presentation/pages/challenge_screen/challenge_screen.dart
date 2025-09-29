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
import 'package:lotto_app/data/models/lottery_statistics/lottery_entry_model.dart';
import 'package:lotto_app/data/services/user_service.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLotteryStatistics();
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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more entries for infinite scroll
    }
  }



  LotteryEntry _convertToLotteryEntry(LotteryEntryModel model) {
    return LotteryEntry(
      id: model.id,
      serialNo: model.slNo,
      lotteryNumber: model.lotteryNumber,
      lotteryName: model.lotteryName,
      price: model.price,
      dateAdded: model.dateAdded,
      winningAmount: model.winningAmount,
      status: _convertStatus(model.status),
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
    
    return BlocListener<LotteryStatisticsBloc, LotteryStatisticsState>(
      listener: (context, state) {
        if (state is LotteryStatisticsLoaded) {
          setState(() {
            _lotteryEntries = state.data.lotteryEntries
                .map(_convertToLotteryEntry)
                .toList();
          });
        }
      },
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
      // margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.2),
            theme.primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add Lottery and Start Challenge',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your wins, losses, and see your progress!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 14,
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
      margin: const EdgeInsets.all(16),
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
                Icon(
                  Icons.trending_up,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'challenge_statistics'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                Icon(
                  _isStatisticsExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.primaryColor,
                  size: 24,
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
                  Icon(
                    Icons.emoji_events,
                    color: theme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Your Challenge!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your lottery tickets and track your wins! Use the + button to scan or manually enter your lottery entries.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
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
                  color: netProfitLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'net_result'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: netProfitLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '�${netProfitLoss.abs().toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: netProfitLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
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
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 700, // Total of all column widths: 60+150+120+80+80+90+60+50 = 690 + 60 padding
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        'sl_no'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        'lottery_number'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'lottery_name'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'price'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'date'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'winnings'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'status'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 50), // Space for delete button
                  ],
                ),
              ),
              // Table Content
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: _lotteryEntries.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final entry = _lotteryEntries[index];
                    return _buildTableRow(theme, entry, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(ThemeData theme, LotteryEntry entry, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              entry.serialNo.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 150,
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
          SizedBox(
            width: 120,
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
          SizedBox(
            width: 80,
            child: Text(
              '₹${entry.price.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              DateFormat('dd/MM').format(entry.dateAdded),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              entry.winningAmount > 0 ? '₹${entry.winningAmount.toStringAsFixed(0)}' : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: entry.winningAmount > 0 ? Colors.green.shade700 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(entry.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(entry.status),
                size: 20,
                color: _getStatusColor(entry.status),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 22,
              ),
              onPressed: () => _deleteEntry(entry.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
              color: Colors.grey.shade600,
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
        color: theme.cardColor,
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
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
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
        color: theme.cardColor,
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'no_lottery_entries'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'tap_add_button_to_start'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
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
      final newEntry = LotteryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serialNo: _lotteryEntries.length + 1,
        lotteryNumber: lotteryNumber,
        lotteryName: lotteryName ?? 'Unknown',
        price: price,
        dateAdded: date,
        winningAmount: 0.0,
        status: LotteryStatus.pending,
      );
      _lotteryEntries.insert(0, newEntry); // Add to the beginning for newest first
    });
    
    // Refresh statistics from API in background to get updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadLotteryStatistics(forceRefresh: true);
    });
  }

  void _deleteEntry(String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_entry'.tr()),
        content: Text('delete_entry_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _lotteryEntries.removeWhere((entry) => entry.id == entryId);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('entry_deleted_successfully'.tr())),
              );
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
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

  LotteryEntry({
    required this.id,
    required this.serialNo,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.price,
    required this.dateAdded,
    required this.winningAmount,
    required this.status,
  });
}

enum LotteryStatus {
  won,
  lost,
  pending,
}