import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

class ResultTypeBanner extends StatelessWidget {
  final TicketCheckResponseModel result;
  final bool shouldShowScratch;
  final bool autoRevealTriggered;
  final Map<String, dynamic> ticketData;

  const ResultTypeBanner({
    super.key,
    required this.result,
    required this.shouldShowScratch,
    required this.autoRevealTriggered,
    required this.ticketData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    late Color bannerColor;
    late Color iconColor;
    late IconData primaryIcon;
    late String title;
    late String subtitle;

    // Show scratch instruction for scratch cards before reveal
    if (shouldShowScratch && !autoRevealTriggered) {
      bannerColor = isDark ? Colors.purple[900]!.withValues(alpha: 0.3) : Colors.purple[50]!;
      iconColor = isDark ? Colors.purple[400]! : Colors.purple[600]!;
      primaryIcon = Icons.touch_app;
      title = '✋ Scratch to Reveal Result';
      subtitle = 'Scratch the card below to see if you won';
      
      return _buildBannerContainer(
        theme: theme,
        bannerColor: bannerColor,
        iconColor: iconColor,
        primaryIcon: primaryIcon,
        title: title,
        subtitle: subtitle,
      );
    }

    // Use resultStatus from API response for better accuracy after reveal
    final String resultStatus = result.resultStatus;

    // Handle cases based on resultStatus from API response
    switch (resultStatus.toLowerCase()) {
      case 'won price today':
        // Case 1: Current Winner
        bannerColor = isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50]!;
        iconColor = isDark ? Colors.green[400]! : Colors.green[600]!;
        primaryIcon = Icons.emoji_events;
        title = '🎉 Congratulations! You Won!';
        subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : ticketData['date'])}';
        break;

      case 'no price today':
        // Case 2: Current Loser - Show points if available
        if (result.points != null && result.points! > 0) {
          bannerColor = isDark ? Colors.blue[900]!.withValues(alpha: 0.3) : Colors.blue[50]!;
          iconColor = isDark ? Colors.blue[400]! : Colors.blue[600]!;
          primaryIcon = Icons.card_giftcard;
          title = '🎁 You Earned ${result.points} Points!';
          subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : ticketData['date'])}';
        } else {
          bannerColor = isDark ? Colors.orange[900]!.withValues(alpha: 0.3) : Colors.orange[50]!;
          iconColor = isDark ? Colors.orange[400]! : Colors.orange[600]!;
          primaryIcon = Icons.info;
          title = 'Better Luck Next Time';
          subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : ticketData['date'])}';
        }
        break;

      case 'previous result':
        // Case 3: Previous Winner
        bannerColor = isDark ? Colors.yellow[900]!.withValues(alpha: 0.3) : Colors.yellow[50]!;
        iconColor = isDark ? Colors.yellow[400]! : Colors.yellow[900]!;
        primaryIcon = Icons.emoji_events;
        title = 'Previous Lottery Winner!';
        subtitle = 'checked on ${_formatDate(result.drawDate)} lottery';
        break;

      case 'previous result no price':
        // Case 4: Previous No Win
        bannerColor = isDark ? theme.cardColor : Colors.grey[50]!;
        iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        primaryIcon = Icons.schedule;
        title = 'Checked Previous Result';
        subtitle = 'checked on ${_formatDate(result.drawDate)} lottery';
        break;

      case 'result is not published':
        // Case 5: Result Not Published
        bannerColor = isDark ? Colors.amber[900]!.withValues(alpha: 0.3) : Colors.amber[50]!;
        iconColor = isDark ? Colors.amber[400]! : Colors.amber[700]!;
        primaryIcon = Icons.access_time;
        title = 'Result Not Published';
        subtitle = 'Result will be available after 3 PM';
        break;

      default:
        // Fallback case
        bannerColor = isDark ? theme.cardColor : Colors.grey[50]!;
        iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        primaryIcon = Icons.help_outline;
        title = 'Status Unknown';
        subtitle = 'Unable to Determine Result';
        break;
    }

    // Determine if we should show the points button
    final bool shouldShowPointsButton = resultStatus.toLowerCase() == 'no price today' && 
                                       result.points != null && 
                                       result.points! > 0;

    return _buildBannerContainer(
      theme: theme,
      bannerColor: bannerColor,
      iconColor: iconColor,
      primaryIcon: primaryIcon,
      title: title,
      subtitle: subtitle,
      showPointsButton: shouldShowPointsButton,
      context: context,
    );
  }

  Widget _buildBannerContainer({
    required ThemeData theme,
    required Color bannerColor,
    required Color iconColor,
    required IconData primaryIcon,
    required String title,
    required String subtitle,
    bool showPointsButton = false,
    BuildContext? context,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor, bannerColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icons and title
            Row(
              children: [
                // Primary status icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(primaryIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: iconColor.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation button for points earned
                if (showPointsButton && context != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/lottoPoints'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}