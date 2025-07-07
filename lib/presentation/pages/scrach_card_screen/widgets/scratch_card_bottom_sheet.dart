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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 16),

          // Ticket details
          _buildTicketDetails(theme),

          const SizedBox(height: 24),

          // Action buttons based on response type
          _buildActionButtons(context, theme),

          // const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey[300]),

          const SizedBox(height: 12),

          // Kerala Lottery Logo and text
          _buildFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
    switch (result.responseType) {
      case ResponseType.currentWinner:
        return Column(
          children: [
            // Primary action - Claim Prize
            ElevatedButton(
              onPressed: () => _launchClaimProcess(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
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
                foregroundColor: Colors.red[600],
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: Colors.red[600]!),
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
                backgroundColor: Colors.blue[600],
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
                foregroundColor: Colors.red[600],
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: Colors.red[600]!),
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
            // Secondary action - Home
            OutlinedButton(
              onPressed: () => context.go('/'),
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
                  const Icon(Icons.home_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'back_to_home'.tr(),
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
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.message.isNotEmpty
                          ? result.message
                          : 'result_will_be_published_soon'.tr(),
                      style: TextStyle(
                        color: Colors.amber[800],
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
                backgroundColor: Colors.amber[600],
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
            // Secondary action - Home
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber[600],
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: Colors.amber[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'back_to_home'.tr(),
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
            // primary action - see full results

            // First button as ElevatedButton
            ElevatedButton(
              onPressed: () => _navigateToResultDetails(context, result),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
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

// Second button as OutlinedButton
            OutlinedButton(
              onPressed: () => context.go('/'),
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
                  const Icon(Icons.home_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'back_to_home'.tr(),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPreviousWin
              ? 'previous_prize_claim'.tr()
              : 'prize_claim_process'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'congratulations_winning'.tr()} ${result.formattedPrize}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isPreviousWin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'previous_win_note'.tr(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'to_claim_prize'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('• ${'visit_district_collectorate'.tr()}'),
                Text('• ${'bring_winning_ticket'.tr()}'),
                Text('• ${'carry_valid_id'.tr()}'),
                Text('• ${'fill_claim_form'.tr()}'),
                const SizedBox(height: 16),
                Text(
                  'bank_details_required'.tr(),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('got_it'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchKeralaLotteryWebsite(context);
              },
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
