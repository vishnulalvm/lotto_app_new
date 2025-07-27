import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_event.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_state.dart';
import 'package:lotto_app/presentation/pages/scrach_card_screen/widgets/scratch_card_bottom_sheet.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:scratcher/widgets.dart';
import 'package:confetti/confetti.dart';

class ScratchCardResultScreen extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const ScratchCardResultScreen({
    super.key,
    required this.ticketData,
  });

  @override
  State<ScratchCardResultScreen> createState() =>
      _ScratchCardResultScreenState();
}

class _ScratchCardResultScreenState extends State<ScratchCardResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Scratch progress tracking
  double scratchProgress = 0.0;
  bool _showConfetti = false;
  bool _autoRevealTriggered = false;
  late ConfettiController _confettiController;

  // API result data
  TicketCheckResponseModel? _ticketResult;

  // Scratcher key for auto-reveal
  final GlobalKey<ScratcherState> _scratcherKey = GlobalKey<ScratcherState>();

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Setup confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Start the entrance animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
    });

    // Check ticket using API
    _checkTicketWithAPI();
  }

  Future<void> _checkTicketWithAPI() async {
    final ticketNumber = widget.ticketData['ticketNumber'] as String;
    final date = widget.ticketData['date'] as String;

    // Get user's phone number from stored user data
    final userService = UserService();
    String? phoneNumber = await userService.getPhoneNumber();

    // Fallback to default if no user phone number found
    phoneNumber ??= "7306902343";

    // Remove country code if present (+91) to match API format
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3);
    } else if (phoneNumber.startsWith('91') && phoneNumber.length == 12) {
      phoneNumber = phoneNumber.substring(2);
    }

    if (mounted) {
      context.read<TicketCheckBloc>().add(CheckTicketEvent(
            ticketNumber: ticketNumber,
            phoneNumber: phoneNumber,
            date: date,
          ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onScratchUpdate(double progress) {
    setState(() {
      scratchProgress = progress;
      // Auto-reveal when 50% scratched and we have API results
      if (progress >= 0.5 && !_autoRevealTriggered && _ticketResult != null) {
        _autoRevealTriggered = true;
        _autoRevealScratchCard();
      }
    });
  }

  void _autoRevealScratchCard() {
    // Automatically reveal the entire scratch card
    _scratcherKey.currentState
        ?.reveal(duration: const Duration(milliseconds: 500));

    // Show result after auto-reveal animation
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        if (_ticketResult!.isWinner) {
          _confettiController.play();
          _showConfetti = true;
        }
      });
    });
  }

  // Enhanced method to determine if we should show scratch card based on response type
  bool _shouldShowScratchCard(TicketCheckResponseModel result) {
    switch (result.responseType) {
      case ResponseType.currentWinner:
      case ResponseType.currentLoser:
      case ResponseType.previousWinner:
        return true; // Show scratch card for these cases
      case ResponseType.previousLoser:
      case ResponseType.resultNotPublished:
        return false; // Don't show scratch card - no prize and no current result
      case ResponseType.unknown:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'prize_result'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => context.go('/'),
        ),
      ),
      body: BlocListener<TicketCheckBloc, TicketCheckState>(
        listener: (context, state) {
          if (state is TicketCheckSuccess) {
            setState(() {
              _ticketResult = state.result;
            });
            
            // Show toast if user earned points (currentLoser with points)
            if (state.result.responseType == ResponseType.currentLoser && 
                state.result.points != null && 
                state.result.points! > 0) {
              // Delay toast slightly to let the UI update first
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _showPointsEarnedToast(state.result.points!);
                }
              });
            }
          } else if (state is TicketCheckFailure) {
            setState(() {
              _ticketResult = null;
            });
          }
        },
        child: BlocBuilder<TicketCheckBloc, TicketCheckState>(
          builder: (context, state) {
            if (state is TicketCheckLoading) {
              return _buildLoadingState(theme);
            } else if (state is TicketCheckFailure) {
              return _buildErrorState(theme, state.error);
            } else if (state is TicketCheckSuccess) {
              return _buildSuccessState(theme, state.result);
            }
            return _buildLoadingState(theme);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: _buildLoadingScratchCard(theme),
                ),
              ),
            ),
            _buildLoadingBottomSheet(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.brightness == Brightness.dark
                  ? Colors.red[300]
                  : Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'unable_to_check_ticket'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                context.read<TicketCheckBloc>().add(ResetTicketCheckEvent());
                await _checkTicketWithAPI();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('try_again'.tr()),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
              child: Text('go_back'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, TicketCheckResponseModel result) {
    final shouldShowScratch = _shouldShowScratchCard(result);

    return Stack(
      children: [
        Column(
          children: [
            // Enhanced status banner that explains the result type
            _buildResultTypeBanner(theme, result),

            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: shouldShowScratch
                      ? _buildScratchCard(theme, result)
                      : _buildNoResultCard(theme, result),
                ),
              ),
            ),
            ScratchCardBottomSheet(
              result: result,
              ticketData: widget.ticketData,
              onCheckAgain: () async => await _checkTicketWithAPI(),
            ),
          ],
        ),

        // Confetti overlay
        if (_showConfetti && result.isWinner && shouldShowScratch)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),
      ],
    );
  }

  // Enhanced banner that explains different result types with clear user messaging
  Widget _buildResultTypeBanner(
      ThemeData theme, TicketCheckResponseModel result) {
    return _getResultBannerConfig(result, theme);
  }

  Widget _getResultBannerConfig(
      TicketCheckResponseModel result, ThemeData theme) {
    // Use resultStatus from API response for better accuracy
    final String resultStatus = result.resultStatus;
    final bool isDark = theme.brightness == Brightness.dark;

    late Color bannerColor;
    late Color iconColor;
    late IconData primaryIcon;
    late String title;
    late String subtitle;

    // Handle cases based on resultStatus from API response
    switch (resultStatus.toLowerCase()) {
      case 'won price today':
        // Case 1: Current Winner
        bannerColor =
            isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50]!;
        iconColor = isDark ? Colors.green[400]! : Colors.green[600]!;
        primaryIcon = Icons.emoji_events;
        title = '🎉 Congratulations! You Won!';
        subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : widget.ticketData['date'])}';
        break;

      case 'no price today':
        // Case 2: Current Loser - Show points if available
        if (result.points != null && result.points! > 0) {
          bannerColor =
              isDark ? Colors.blue[900]!.withValues(alpha: 0.3) : Colors.blue[50]!;
          iconColor = isDark ? Colors.blue[400]! : Colors.blue[600]!;
          primaryIcon = Icons.card_giftcard;
          title = '🎁 You Earned ${result.points} Points!';
          subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : widget.ticketData['date'])}';
        } else {
          bannerColor =
              isDark ? Colors.orange[900]!.withValues(alpha: 0.3) : Colors.orange[50]!;
          iconColor = isDark ? Colors.orange[400]! : Colors.orange[600]!;
          primaryIcon = Icons.info;
          title = 'Better Luck Next Time';
          subtitle = 'Checked on ${_formatDate(result.drawDate.isNotEmpty ? result.drawDate : widget.ticketData['date'])}';
        }
        break;

      case 'previous result':
        // Case 3: Previous Winner
        bannerColor =
            isDark ? Colors.yellow[900]!.withValues(alpha: 0.3) : Colors.yellow[50]!;
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
        bannerColor =
            isDark ? Colors.amber[900]!.withValues(alpha: 0.3) : Colors.amber[50]!;
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor,
            bannerColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
        ),
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
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 10,
          right: 10,
        ),
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
                  child: Icon(
                    primaryIcon,
                    color: iconColor,
                    size: 24,
                  ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultCard(ThemeData theme, TicketCheckResponseModel result) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(
              width: 2,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[600]!
                  : Colors.grey[300]!,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[500],
                    size: 55,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getNoResultTitle(result),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getNoResultSubtitle(result),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${'Ticket No'}: ${widget.ticketData['ticketNumber']}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (widget.ticketData['date'] != null)
                    Text(
                      '${'requested_date'.tr()}: ${_formatDate(widget.ticketData['date'])}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (result.drawDate.isNotEmpty &&
                      result.responseType == ResponseType.previousLoser)
                    Text(
                      '${'Date checked'}: ${_formatDate(result.drawDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScratchCard(ThemeData theme) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
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
      ),
      child: ClipRRect(
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
                const SizedBox(height: 16),
                Text(
                  'checking_ticket'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScratchCard(ThemeData theme, TicketCheckResponseModel result) {
    // Enhanced color scheme based on result type
    Color cardColor;
    if (result.responseType == ResponseType.previousWinner) {
      cardColor = theme.brightness == Brightness.dark
          ? Colors.blue[600]!
          : Colors.blue[500]!;
    } else {
      cardColor = result.isWinner
          ? (theme.brightness == Brightness.dark
              ? Colors.green[600]!
              : Colors.green[500]!)
          : (theme.brightness == Brightness.dark
              ? Colors.red[600]!
              : Colors.red[500]!);
    }

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
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
      ),
      child: Scratcher(
        key: _scratcherKey,
        brushSize: 60,
        threshold: 50,
        color: theme.brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey,
        image: Image.asset('assets/images/scrachcard.png'),
        onChange: (value) => _onScratchUpdate(value / 100),
        onThreshold: () {
          if (!_autoRevealTriggered) {
            _autoRevealTriggered = true;
            _autoRevealScratchCard();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
            ),
            child: Stack(
              children: [
                // Background pattern
                _buildBackgroundIcons(result.isWinner, result.responseType),
                // Result content
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          result.isWinner
                              ? (result.responseType ==
                                      ResponseType.previousWinner
                                  ? Icons.history_edu
                                  : Icons.emoji_events)
                              : Icons.sentiment_dissatisfied,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getScratchCardTitle(result),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (result.isWinner) ...[
                          Text(
                            result.formattedPrize,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.matchType,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (result.responseType ==
                              ResponseType.previousWinner) ...[
                            const SizedBox(height: 4),
                            Text(
                              'previous_draw_win'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else ...[
                          // Show points for currentLoser if available, otherwise show no prize
                          if (result.responseType == ResponseType.currentLoser && result.points != null && result.points! > 0) ...[
                            Text(
                              '🎁 +${result.points} Points',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Points for participation',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            Text(
                              'no_prize'.tr(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        Text(
                          '${'ticket'.tr()}: ${result.displayTicketNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${'draw'.tr()}: ${result.formattedLotteryInfo}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scratch instruction overlay (only show when not auto-revealed)
                if (!_autoRevealTriggered && scratchProgress < 0.1)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'scratch_to_reveal'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }

  String _getScratchCardTitle(TicketCheckResponseModel result) {
    switch (result.responseType) {
      case ResponseType.currentWinner:
        return 'congratulations'.tr();
      case ResponseType.currentLoser:
        // Show points if available for currentLoser, otherwise show better luck message
        if (result.points != null && result.points! > 0) {
          return 'You Earned Points!';
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

  String _getNoResultTitle(TicketCheckResponseModel result) {
    switch (result.responseType) {
      case ResponseType.previousLoser:
        return 'Better luck next time';
      case ResponseType.resultNotPublished:
        return 'Result Not Published';
      default:
        return 'no_result_available'.tr();
    }
  }

  String _getNoResultSubtitle(TicketCheckResponseModel result) {
    switch (result.responseType) {
      case ResponseType.previousLoser:
        return 'Checked on ${_formatDate(result.drawDate)} - No prize won';
      case ResponseType.resultNotPublished:
        return result.message.isNotEmpty
            ? result.message
            : 'Result will be available after 3 PM';
      default:
        return 'Result will be available after 3 PM';
    }
  }

  Widget _buildBackgroundIcons(bool isWinner, ResponseType responseType) {
    Color? iconColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (responseType == ResponseType.previousWinner) {
      iconColor = isDark ? Colors.blue[400] : Colors.blue[300];
    } else {
      iconColor = isWinner
          ? (isDark ? Colors.green[400] : Colors.green[300])
          : (isDark ? Colors.red[400] : Colors.red[300]);
    }

    return Stack(
      children: [
        // Main icons
        Positioned(
          bottom: 40,
          left: 30,
          child: Icon(
            isWinner
                ? (responseType == ResponseType.previousWinner
                    ? Icons.history_outlined
                    : Icons.emoji_events_outlined)
                : Icons.sentiment_dissatisfied_outlined,
            color: iconColor,
            size: 40,
          ),
        ),
        Positioned(
          top: 60,
          right: 40,
          child: Icon(
            isWinner ? Icons.card_giftcard_outlined : Icons.close_outlined,
            color: iconColor,
            size: 40,
          ),
        ),
        Positioned(
          top: 100,
          left: 50,
          child: Icon(
            isWinner
                ? Icons.workspace_premium_outlined
                : Icons.sentiment_neutral_outlined,
            color: iconColor,
            size: 40,
          ),
        ),
        Positioned(
          bottom: 80,
          right: 60,
          child: Icon(
            isWinner ? Icons.star_outline : Icons.thumb_down_outlined,
            color: iconColor,
            size: 30,
          ),
        ),
        // Decorative elements
        ...List.generate(10, (index) {
          final random = Random(index);
          return Positioned(
            top: 20 + random.nextDouble() * 260,
            left: 20 + random.nextDouble() * 260,
            child: Container(
              width: 8,
              height: 8,
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

  Widget _buildLoadingBottomSheet(ThemeData theme) {
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
          Text(
            'checking_ticket'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'please_wait_verifying'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
        ],
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

  /// Show toast message when user earns points
  void _showPointsEarnedToast(int points) {
    try {
      Fluttertoast.showToast(
        msg: "🎉 Congratulations! You earned $points points!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.blue[700],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Fallback to SnackBar if toast fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "🎉 Congratulations! You earned $points points!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.blue[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
