import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scratcher/widgets.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

enum ResultCardType {
  loading,
  noResult,
  scratchCard,
}

class ResponsiveCardSize {
  final double width;
  final double height;
  final double padding;
  final double iconSize;
  final double titleFontSize;
  final double bodyFontSize;

  const ResponsiveCardSize({
    required this.width,
    required this.height,
    required this.padding,
    required this.iconSize,
    required this.titleFontSize,
    required this.bodyFontSize,
  });
}

class ResultCard extends StatelessWidget {
  final ResultCardType type;
  final ThemeData theme;
  final TicketCheckResponseModel? result;
  final Map<String, dynamic>? ticketData;

  // Scratch card specific properties
  final GlobalKey<ScratcherState>? scratcherKey;
  final Function(double)? onScratchUpdate;
  final VoidCallback? onThreshold;
  final bool autoRevealTriggered;
  final double scratchProgress;

  // Size and styling (now optional - will be calculated responsively)
  final double? width;
  final double? height;

  const ResultCard({
    super.key,
    required this.type,
    required this.theme,
    this.result,
    this.ticketData,
    this.scratcherKey,
    this.onScratchUpdate,
    this.onThreshold,
    this.autoRevealTriggered = false,
    this.scratchProgress = 0.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final responsiveSize = _getResponsiveSize(screenSize);

    return Container(
      width: width ?? responsiveSize.width,
      height: height ?? responsiveSize.height,
      decoration: _buildCardDecoration(),
      child: _buildCardContent(context, responsiveSize),
    );
  }

  // Simple responsive logic for different screen sizes
  ResponsiveCardSize _getResponsiveSize(Size screenSize) {
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate card size as percentage of screen width with min/max constraints
    double cardWidth = screenWidth * 0.85; // 85% of screen width
    cardWidth = cardWidth.clamp(280.0, 300.0); // Min 280, Max 300

    // Maintain aspect ratio (1:1 for square cards)
    double cardHeight = cardWidth;

    // For no-result cards, allow slightly taller if needed
    if (type == ResultCardType.noResult) {
      cardHeight = cardWidth.clamp(280.0, 300.0);
    }

    // Adjust for very small screens (iPhone SE, etc.)
    if (screenWidth < 375) {
      cardWidth = screenWidth * 0.90;
      cardHeight = cardWidth;
    }

    // Adjust for very tall screens to ensure card fits
    if (cardHeight > screenHeight * 0.6) {
      cardHeight = screenHeight * 0.6;
      cardWidth = cardHeight;
    }

    return ResponsiveCardSize(
      width: cardWidth,
      height: cardHeight,
      padding: _getResponsivePadding(cardWidth),
      iconSize: _getResponsiveIconSize(cardWidth),
      titleFontSize: _getResponsiveTitleSize(cardWidth),
      bodyFontSize: _getResponsiveBodySize(cardWidth),
    );
  }

  double _getResponsivePadding(double cardWidth) {
    if (cardWidth < 300) return 16.0;
    if (cardWidth < 320) return 20.0;
    return 24.0;
  }

  double _getResponsiveIconSize(double cardWidth) {
    if (cardWidth < 300) return 45.0;
    if (cardWidth < 320) return 50.0;
    return 55.0;
  }

  double _getResponsiveTitleSize(double cardWidth) {
    if (cardWidth < 300) return 16.0;
    if (cardWidth < 320) return 17.0;
    return 18.0;
  }

  double _getResponsiveBodySize(double cardWidth) {
    if (cardWidth < 300) return 14.0;
    if (cardWidth < 320) return 15.0;
    return 16.0;
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildCardContent(
      BuildContext context, ResponsiveCardSize responsiveSize) {
    switch (type) {
      case ResultCardType.loading:
        return _buildLoadingContent(responsiveSize);
      case ResultCardType.noResult:
        return _buildNoResultContent(responsiveSize);
      case ResultCardType.scratchCard:
        return _buildScratchContent(responsiveSize);
    }
  }

  Widget _buildLoadingContent(ResponsiveCardSize responsiveSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
              SizedBox(
                  height: responsiveSize.padding * 0.67), // Responsive spacing
              Text(
                'checking_ticket'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: responsiveSize.bodyFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultContent(ResponsiveCardSize responsiveSize) {
    if (result == null || ticketData == null) {
      return const SizedBox.shrink();
    }

    // Get colors based on result type for better visual distinction
    final bool isDark = theme.brightness == Brightness.dark;
    Color cardColor;
    Color iconColor;
    Color primaryTextColor;
    Color secondaryTextColor;

    if (result!.responseType == ResponseType.previousLoser) {
      // Previous result styling - bluish theme
      cardColor =
          isDark ? Colors.blue[900]!.withValues(alpha: 0.15) : Colors.blue[50]!;
      iconColor = isDark ? Colors.blue[400]! : Colors.blue[600]!;
      primaryTextColor = isDark ? Colors.blue[300]! : Colors.blue[700]!;
      secondaryTextColor = isDark ? Colors.blue[200]! : Colors.blue[500]!;
    } else {
      // Result not published styling - orange theme
      cardColor = isDark
          ? Colors.orange[900]!.withValues(alpha: 0.15)
          : Colors.orange[50]!;
      iconColor = isDark ? Colors.orange[400]! : Colors.orange[700]!;
      primaryTextColor = isDark ? Colors.orange[300]! : Colors.orange[800]!;
      secondaryTextColor = isDark ? Colors.orange[200]! : Colors.orange[700]!;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background decorative elements
          _buildNoResultBackgroundIcons(responsiveSize, iconColor),
          // Main content
          Container(
            padding: EdgeInsets.all(responsiveSize.padding),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main icon with background circle
                  Container(
                    padding: EdgeInsets.all(responsiveSize.padding * 0.75),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.3),
                        width: 0,
                      ),
                    ),
                    child: Icon(
                      result!.responseType == ResponseType.previousLoser
                          ? Icons.sentiment_dissatisfied_outlined
                          : Icons.access_time_outlined,
                      color: iconColor,
                      size: responsiveSize.iconSize * 0.8,
                    ),
                  ),
                  SizedBox(height: responsiveSize.padding * 0.75),
                  Text(
                    _getNoResultTitle(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: responsiveSize.titleFontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: responsiveSize.padding * 0.4),
                  Text(
                    _getNoResultSubtitle(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: responsiveSize.bodyFontSize * 0.95,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: responsiveSize.padding * 0.75),
                  // Ticket info container
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsiveSize.padding * 0.75,
                      vertical: responsiveSize.padding * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${'Ticket No'}: ${ticketData!['ticketNumber']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: responsiveSize.bodyFontSize * 0.85,
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (result!.drawDate.isNotEmpty &&
                            result!.responseType ==
                                ResponseType.previousLoser) ...[
                          SizedBox(height: responsiveSize.padding * 0.2),
                          Text(
                            '${'Ticket name'}: ${result!.lotteryName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: responsiveSize.bodyFontSize * 0.8,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
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

  Widget _buildScratchContent(ResponsiveCardSize responsiveSize) {
    if (result == null || scratcherKey == null) {
      return const SizedBox.shrink();
    }

    final Color cardColor = _getScratchCardColor();
    // Responsive brush size
    final double brushSize = (responsiveSize.width * 0.2).clamp(40.0, 80.0);

    return Scratcher(
      key: scratcherKey,
      brushSize: brushSize,
      threshold: 50,
      color:
          theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey,
      image: Image.asset('assets/images/scrachcard.png'),
      onChange: (value) => onScratchUpdate?.call(value / 100),
      onThreshold: onThreshold,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
          ),
          child: Stack(
            children: [
              // Background pattern
              _buildBackgroundIcons(responsiveSize),
              // Result content
              Container(
                padding: EdgeInsets.all(responsiveSize.padding * 0.67),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getScratchCardIcon(),
                        color: Colors.white,
                        size: responsiveSize.iconSize * 0.73,
                      ),
                      SizedBox(height: responsiveSize.padding * 0.33),
                      Text(
                        _getScratchCardTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: responsiveSize.titleFontSize * 1.15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsiveSize.padding * 0.17),
                      ..._buildScratchCardDetails(responsiveSize),
                      Text(
                        '${'ticket'.tr()}: ${result!.displayTicketNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: responsiveSize.bodyFontSize,
                        ),
                      ),
                      Text(
                        '${'draw'.tr()}: ${result!.formattedLotteryInfo}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontSize: responsiveSize.bodyFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scratch instruction overlay
              if (!autoRevealTriggered && scratchProgress < 0.1)
                _buildScratchInstructionOverlay(responsiveSize),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScratchCardColor() {
    if (result!.responseType == ResponseType.previousWinner) {
      return theme.brightness == Brightness.dark
          ? Colors.blue[600]!
          : Colors.blue[500]!;
    } else {
      return result!.isWinner
          ? (theme.brightness == Brightness.dark
              ? Colors.green[600]!
              : Colors.green[500]!)
          : (theme.brightness == Brightness.dark
              ? Colors.red[600]!
              : Colors.red[500]!);
    }
  }

  IconData _getScratchCardIcon() {
    return result!.isWinner
        ? (result!.responseType == ResponseType.previousWinner
            ? Icons.history_edu
            : Icons.emoji_events)
        : Icons.sentiment_dissatisfied_outlined;
  }

  String _getScratchCardTitle() {
    switch (result!.responseType) {
      case ResponseType.currentWinner:
        return 'congratulations'.tr();
      case ResponseType.currentLoser:
        if ((result!.cashBack != null && result!.cashBack! > 0) || 
            (result!.points != null && result!.points! > 0)) {
          return 'better_luck_next_time'.tr();
        }
        return 'better_luck_next_time'.tr();
      case ResponseType.previousWinner:
        return 'congratulations'.tr();
      case ResponseType.previousLoser:
      case ResponseType.resultNotPublished:
      case ResponseType.unknown:
        return 'better_luck_next_time'.tr();
    }
  }

  List<Widget> _buildScratchCardDetails(ResponsiveCardSize responsiveSize) {
    if (result!.isWinner) {
      return [
        Text(
          result!.formattedPrize,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsiveSize.titleFontSize * 1.35,
          ),
        ),
        SizedBox(height: responsiveSize.padding * 0.33),
        Text(
          result!.matchType,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: responsiveSize.bodyFontSize * 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        if (result!.responseType == ResponseType.previousWinner) ...[
          SizedBox(height: responsiveSize.padding * 0.17),
          Text(
            'previous_draw_win'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontSize: responsiveSize.bodyFontSize * 0.95,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ];
    } else {
      // Check for cash back first, then points, otherwise show no prize
      if (result!.responseType == ResponseType.currentLoser) {
        // Show cash back if available
        if (result!.cashBack != null && result!.cashBack! > 0) {
          return [
            Text(
              '💰 ${result!.formattedCashBack} Cash Back',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: responsiveSize.titleFontSize * 1.35,
              ),
            ),
            SizedBox(height: responsiveSize.padding * 0.17),
            Text(
              'You Earned Cash Back!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                fontSize: responsiveSize.bodyFontSize * 1.05,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsiveSize.padding * 0.33),
          ];
        }
        // Show points if available and no cash back
        else if (result!.points != null && result!.points! > 0) {
          return [
            Text(
              '🎁 +${result!.points} Points',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: responsiveSize.titleFontSize * 1.35,
              ),
            ),
            SizedBox(height: responsiveSize.padding * 0.17),
            Text(
              'You Earned Points',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                fontSize: responsiveSize.bodyFontSize * 1.05,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsiveSize.padding * 0.33),
          ];
        }
      }
      
      // No cash back or points - show no prize
      return [
        Text(
          'no_prize'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsiveSize.titleFontSize * 1.35,
          ),
        ),
        SizedBox(height: responsiveSize.padding * 0.33),
      ];
    }
  }

  Widget _buildBackgroundIcons(ResponsiveCardSize responsiveSize) {
    Color? iconColor;
    final isDark = theme.brightness == Brightness.dark;

    if (result!.responseType == ResponseType.previousWinner) {
      iconColor = isDark ? Colors.blue[400] : Colors.blue[300];
    } else {
      iconColor = result!.isWinner
          ? (isDark ? Colors.green[400] : Colors.green[300])
          : (isDark ? Colors.red[400] : Colors.red[300]);
    }

    // Responsive positioning and sizing
    final double iconSize = responsiveSize.iconSize * 0.73;
    final double smallIconSize = responsiveSize.iconSize * 0.55;
    final double cardWidth = responsiveSize.width;
    final double cardHeight = responsiveSize.height;

    return Stack(
      children: [
        // Main icons - positioned responsively
        Positioned(
          bottom: cardHeight * 0.13,
          left: cardWidth * 0.1,
          child: Icon(
            result!.isWinner
                ? (result!.responseType == ResponseType.previousWinner
                    ? Icons.history_outlined
                    : Icons.emoji_events_outlined)
                : Icons.sentiment_dissatisfied_outlined,
            color: iconColor,
            size: iconSize,
          ),
        ),
        Positioned(
          top: cardHeight * 0.2,
          right: cardWidth * 0.12,
          child: Icon(
            result!.isWinner
                ? Icons.card_giftcard_outlined
                : Icons.close_outlined,
            color: iconColor,
            size: iconSize,
          ),
        ),
        Positioned(
          top: cardHeight * 0.33,
          left: cardWidth * 0.17,
          child: Icon(
            result!.isWinner
                ? Icons.workspace_premium_outlined
                : Icons.sentiment_neutral_outlined,
            color: iconColor,
            size: iconSize,
          ),
        ),
        Positioned(
          bottom: cardHeight * 0.27,
          right: cardWidth * 0.2,
          child: Icon(
            result!.isWinner ? Icons.star_outline : Icons.thumb_down_outlined,
            color: iconColor,
            size: smallIconSize,
          ),
        ),
        // Decorative elements - responsive dots
        ...List.generate(8, (index) {
          final random = Random(index);
          return Positioned(
            top:
                (cardHeight * 0.07) + random.nextDouble() * (cardHeight * 0.86),
            left: (cardWidth * 0.07) + random.nextDouble() * (cardWidth * 0.86),
            child: Container(
              width: responsiveSize.width * 0.025,
              height: responsiveSize.width * 0.025,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScratchInstructionOverlay(ResponsiveCardSize responsiveSize) {
    return Positioned(
      bottom: responsiveSize.padding * 0.83,
      left: responsiveSize.padding * 0.83,
      right: responsiveSize.padding * 0.83,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: responsiveSize.padding * 0.33,
          horizontal: responsiveSize.padding * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(responsiveSize.padding * 0.83),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.white,
              size: responsiveSize.bodyFontSize * 1.07,
            ),
            SizedBox(width: responsiveSize.padding * 0.33),
            Text(
              'scratch_to_reveal'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: responsiveSize.bodyFontSize * 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNoResultTitle() {
    switch (result!.responseType) {
      case ResponseType.previousLoser:
        return 'Better luck next time';
      case ResponseType.resultNotPublished:
        return 'Result Not Published';
      default:
        return 'no_result_available'.tr();
    }
  }

  String _getNoResultSubtitle() {
    switch (result!.responseType) {
      case ResponseType.previousLoser:
        return 'Checked on ${_formatDate(result!.drawDate)} - No prize won';
      case ResponseType.resultNotPublished:
        return result!.message.isNotEmpty
            ? result!.message
            : 'Result will be available after 3 PM';
      default:
        return 'Result will be available after 3 PM';
    }
  }

  Widget _buildNoResultBackgroundIcons(
      ResponsiveCardSize responsiveSize, Color iconColor) {
    final double cardWidth = responsiveSize.width;
    final double cardHeight = responsiveSize.height;
    final Color decorativeColor = iconColor.withValues(alpha: 0.1);

    return Stack(
      children: [
        // Corner decorative icons
        Positioned(
          top: cardHeight * 0.15,
          right: cardWidth * 0.12,
          child: Icon(
            result!.responseType == ResponseType.previousLoser
                ? Icons.schedule_outlined
                : Icons.hourglass_empty_outlined,
            color: decorativeColor,
            size: responsiveSize.iconSize * 0.6,
          ),
        ),
        Positioned(
          bottom: cardHeight * 0.2,
          left: cardWidth * 0.15,
          child: Icon(
            Icons.info_outline,
            color: decorativeColor,
            size: responsiveSize.iconSize * 0.5,
          ),
        ),
        Positioned(
          top: cardHeight * 0.25,
          left: cardWidth * 0.1,
          child: Icon(
            Icons.event_note_outlined,
            color: decorativeColor,
            size: responsiveSize.iconSize * 0.45,
          ),
        ),
        // Decorative dots
        ...List.generate(6, (index) {
          final random =
              Random(index + 100); // Different seed for no-result cards
          return Positioned(
            top: (cardHeight * 0.1) + random.nextDouble() * (cardHeight * 0.8),
            left: (cardWidth * 0.08) + random.nextDouble() * (cardWidth * 0.84),
            child: Container(
              width: responsiveSize.width * 0.015,
              height: responsiveSize.width * 0.015,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: decorativeColor,
              ),
            ),
          );
        }),
      ],
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
