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
        bannerColor = isDark ? theme.cardColor : Colors.grey[50]!;
        iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
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
    final double screenWidth = context != null ? MediaQuery.of(context).size.width : 375.0;
    
    // Responsive values
    final double horizontalMargin = (screenWidth * 0.04).clamp(12.0, 20.0);
    final double borderRadius = (screenWidth * 0.04).clamp(12.0, 18.0);
    final double padding = (screenWidth * 0.018).clamp(8.0, 12.0);
    final double iconContainerPadding = (screenWidth * 0.03).clamp(10.0, 14.0);
    final double iconContainerRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    final double iconSize = (screenWidth * 0.06).clamp(20.0, 28.0);
    final double spacing = (screenWidth * 0.03).clamp(10.0, 16.0);
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: horizontalMargin, right: horizontalMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor, bannerColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icons and title
            Row(
              children: [
                // Primary status icon
                Container(
                  padding: EdgeInsets.all(iconContainerPadding),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(iconContainerRadius),
                  ),
                  child: Icon(primaryIcon, color: iconColor, size: iconSize),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: iconColor.withValues(alpha: 0.7),
                          fontSize: (screenWidth * 0.03).clamp(11.0, 14.0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation button for points earned
                if (showPointsButton && context != null) ...[
                  SizedBox(width: spacing * 0.67),
                  ElevatedButton(
                    onPressed: () => context.go('/lottoPoints'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: (screenWidth * 0.04).clamp(12.0, 18.0),
                        vertical: (screenWidth * 0.02).clamp(6.0, 10.0),
                      ),
                      minimumSize: Size(
                        (screenWidth * 0.15).clamp(50.0, 70.0),
                        (screenWidth * 0.08).clamp(28.0, 36.0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius * 0.5),
                      ),
                    ),
                    child: Text(
                      'View ',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // Close button - always show if context is available
                if (context != null) ...[
                  SizedBox(width: spacing * 0.5),
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      padding: EdgeInsets.all(iconContainerPadding * 0.75),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(iconContainerRadius * 0.75),
                      ),
                      child: Icon(
                        Icons.close,
                        color: iconColor,
                        size: iconSize * 0.75,
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