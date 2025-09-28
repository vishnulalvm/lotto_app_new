import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/widgets/manual_entry_dialog.dart';
import 'package:lotto_app/presentation/pages/challenge_screen/widgets/challenge_scanner_dialog.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isStatisticsExpanded = false;
  final List<LotteryEntry> _lotteryEntries = [
    // Sample data for UI demonstration
    LotteryEntry(
      id: '1',
      serialNo: 1,
      lotteryNumber: '1234',
      lotteryName: 'Akshaya',
      price: 100.0,
      dateAdded: DateTime.now().subtract(const Duration(days: 1)),
      winningAmount: 0.0,
      status: LotteryStatus.lost,
    ),
    LotteryEntry(
      id: '2',
      serialNo: 2,
      lotteryNumber: '5678',
      lotteryName: 'Karunya',
      price: 150.0,
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      winningAmount: 5000.0,
      status: LotteryStatus.won,
    ),
    LotteryEntry(
      id: '3',
      serialNo: 3,
      lotteryNumber: '9012',
      lotteryName: 'Win Win',
      price: 100.0,
      dateAdded: DateTime.now(),
      winningAmount: 0.0,
      status: LotteryStatus.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildMotivationalBanner(theme),
          _buildStatisticsSection(theme),
          // const SizedBox(height: 16),
          Expanded(
            child: _buildCombinedTable(theme),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
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
        'challenge_tracker'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
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

  Widget _buildStatisticsSection(ThemeData theme) {
    final totalExpense = _lotteryEntries.fold<double>(0.0, (sum, entry) => sum + entry.price);
    final totalWinnings = _lotteryEntries.fold<double>(0.0, (sum, entry) => sum + entry.winningAmount);
    final totalTickets = _lotteryEntries.length;
    final netProfitLoss = totalWinnings - totalExpense;
    final winRate = totalTickets > 0 ? (_lotteryEntries.where((e) => e.status == LotteryStatus.won).length / totalTickets) * 100 : 0.0;

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

  Widget _buildCombinedTable(ThemeData theme) {
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
      onPressed: () => _showAddEntryOptions(),
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text('add_entry'.tr()),
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

  void _showAddEntryOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('manual_entry'.tr()),
              subtitle: Text('enter_lottery_details_manually'.tr()),
              onTap: () {
                Navigator.pop(context);
                _showManualEntryDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('scan_lottery'.tr()),
              subtitle: Text('scan_lottery_with_camera'.tr()),
              onTap: () {
                Navigator.pop(context);
                _scanLottery();
              },
            ),
          ],
        ),
      ),
    );
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

  void _scanLottery() {
    showDialog(
      context: context,
      builder: (context) => ChallengeScannerDialog(
        onScanResult: (String lotteryNumber, double? price, DateTime date, String? lotteryName) {
          _addNewEntry(lotteryNumber, price ?? 0.0, date, lotteryName);
        },
      ),
    );
  }

  void _addNewEntry(String lotteryNumber, double price, DateTime date, [String? lotteryName]) {
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