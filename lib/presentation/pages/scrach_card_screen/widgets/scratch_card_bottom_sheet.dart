import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:url_launcher/url_launcher.dart';

class ScratchCardBottomSheet extends StatelessWidget {
  final TicketCheckResponseModel result;
  final Map<String, dynamic> ticketData;
  final Future<void> Function() onCheckAgain;

  const ScratchCardBottomSheet({
    super.key,
    required this.result,
    required this.ticketData,
    required this.onCheckAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Ticket details
          _buildTicketDetails(theme),

          const SizedBox(height: 24),

          // Action buttons based on response type
          _buildActionButtons(context, theme),

          // Divider
          Divider(
            color: isDark ? Colors.grey[600] : Colors.grey[300],
          ),

          const SizedBox(height: 12),

          // Kerala Lottery Logo and text
          _buildFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${'ticket_number'.tr()}: ${result.displayTicketNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (result.lotteryName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'lottery'.tr()}: ${result.lotteryName}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (result.requestedDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'requested_date'.tr()}: ${_formatDate(result.requestedDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (result.formattedLotteryInfo.isNotEmpty &&
              result.responseType != ResponseType.resultNotPublished) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.numbers_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'draw'.tr()}: ${result.formattedLotteryInfo}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (result.drawDate.isNotEmpty &&
              result.responseType != ResponseType.resultNotPublished) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'draw_date'.tr()}: ${_formatDate(result.drawDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    switch (result.responseType) {
      case ResponseType.currentWinner:
        return Column(
          children: [
            // Primary action - Claim Prize
            ElevatedButton(
              onPressed: () => _launchClaimProcess(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.green[600] : Colors.green[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'claim_prize'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Secondary action - View Results
            OutlinedButton(
              onPressed: () => _navigateToResultDetails(context, result),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'view_full_results'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );

      case ResponseType.previousWinner:
        return Column(
          children: [
            // Primary action - Claim Prize (Previous)
            ElevatedButton(
              onPressed: () => _launchClaimProcess(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue[600] : Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.redeem_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'claim_previous_prize'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Secondary action - Check Again
            OutlinedButton(
              onPressed: () => _navigateToResultDetails(context, result),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'view_full_results'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );

      case ResponseType.currentLoser:
        return Column(
          children: [
            // Primary action - View Results
            ElevatedButton(
              onPressed: () => _navigateToResultDetails(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'view_full_results'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Secondary action - Scan Again
            OutlinedButton(
              onPressed: onCheckAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'scan_again'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );

      case ResponseType.resultNotPublished:
        return Column(
          children: [
            // Info message container
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.amber[900]!.withValues(alpha: 0.3)
                    : Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.amber[600]! : Colors.amber[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.amber[400] : Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.message.isNotEmpty
                          ? result.message
                          : 'result_will_be_published_soon'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.amber[300] : Colors.amber[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Primary action - Check Again Later
            ElevatedButton(
              onPressed: onCheckAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.amber[600] : Colors.amber[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'check_again_later'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Secondary action - Scan Again
            OutlinedButton(
              onPressed: onCheckAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.amber[400] : Colors.amber[600],
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(
                  color: isDark ? Colors.amber[400]! : Colors.amber[600]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'scan_again'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );

      case ResponseType.previousLoser:
      case ResponseType.unknown:
        return Column(
          children: [
            // Primary action - see full results
            ElevatedButton(
              onPressed: () => _navigateToResultDetails(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'view_full_results'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Secondary action - Scan Again
            OutlinedButton(
              onPressed: onCheckAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'scan_again'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () => _launchKeralaLotteryWebsite(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 18,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'kerala_state_lotteries'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToResultDetails(
      BuildContext context, TicketCheckResponseModel result) {
    final uniqueId = result.uniqueId;

    if (uniqueId.isNotEmpty) {
      context.go('/result-details', extra: uniqueId);
    } else {
      // Fallback to home if no unique ID available
      context.go('/');
    }
  }

  void _launchClaimProcess(
      BuildContext context, TicketCheckResponseModel result) {
    final isPreviousWin = result.responseType == ResponseType.previousWinner;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          title: Text(
            isPreviousWin
                ? 'previous_prize_claim'.tr()
                : 'prize_claim_process'.tr(),
            style: theme.textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'congratulations_winning'.tr()} ${result.formattedPrize}!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPreviousWin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.blue[900]!.withValues(alpha: 0.3)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.blue[600]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Text(
                      'previous_win_note'.tr(),
                      style: TextStyle(
                        color: isDark ? Colors.blue[300] : Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'to_claim_prize'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• ${'visit_district_collectorate'.tr()}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '• ${'bring_winning_ticket'.tr()}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '• ${'carry_valid_id'.tr()}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '• ${'fill_claim_form'.tr()}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'bank_details_required'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodyMedium?.color,
              ),
              child: Text('got_it'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchKeralaLotteryWebsite(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('visit_website'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchKeralaLotteryWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://statelottery.kerala.gov.in/index.php');
    try {
      await launchUrl(url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('website_launch_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}