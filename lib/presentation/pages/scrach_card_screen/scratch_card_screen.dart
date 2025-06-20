import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_event.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_state.dart';
import 'package:scratcher/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _checkTicketWithAPI() {
    final ticketNumber = widget.ticketData['ticketNumber'] as String;
    final date = widget.ticketData['date'] as String;
    // final phoneNumber = widget.ticketData['phoneNumber'] as String;

    context.read<TicketCheckBloc>().add(CheckTicketEvent(
          ticketNumber: ticketNumber,
          phoneNumber: "8138946412",
          date: date,
        ));
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
              color: Colors.red[400],
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
            Text(
              error,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<TicketCheckBloc>().add(ResetTicketCheckEvent());
                _checkTicketWithAPI();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('try_again'.tr()),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text('go_back'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, TicketCheckResponseModel result) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: _buildScratchCard(theme, result),
                ),
              ),
            ),
            _buildBottomSheet(theme, result),
          ],
        ),

        // Confetti overlay
        if (_showConfetti && result.isWinner)
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

  Widget _buildLoadingScratchCard(ThemeData theme) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'checking_ticket'.tr(),
                  style: const TextStyle(
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
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Scratcher(
        key: _scratcherKey,
        brushSize: 40,
        threshold: 50,
        color: Colors.grey,
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
              color: result.isWinner ? Colors.green[500] : Colors.red[500],
            ),
            child: Stack(
              children: [
                // Background pattern
                _buildBackgroundIcons(result.isWinner),
                // Result content
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          result.isWinner
                              ? Icons.emoji_events
                              : Icons.sentiment_dissatisfied,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.isWinner
                              ? 'congratulations'.tr()
                              : 'better_luck_next_time'.tr(),
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
                            result.matchedWith,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                        Text(
                          '${'ticket'.tr()}: ${widget.ticketData['ticketNumber']}',
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

  Widget _buildBackgroundIcons(bool isWinner) {
    final iconColor = isWinner ? Colors.green[300] : Colors.red[300];

    return Stack(
      children: [
        // Main icons
        Positioned(
          bottom: 40,
          left: 30,
          child: Icon(
            isWinner
                ? Icons.emoji_events_outlined
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

  Widget _buildBottomSheet(ThemeData theme, TicketCheckResponseModel result) {
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

          // Result message
          Text(
            result.message,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Prize amount or no prize message
          if (result.isWinner) ...[
            Text(
              result.formattedPrize,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.matchedWith,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              'no_prize_won'.tr(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Ticket details
          Text(
            '${'ticket'.tr()}: ${widget.ticketData['ticketNumber']} • ${result.formattedLotteryInfo}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Action buttons based on result
          if (result.isWinner) ...[
            // Winner buttons
            ElevatedButton(
              onPressed: () => _launchClaimProcess(result),
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
            OutlinedButton(
              onPressed: () =>
                  context.go('/result-details', extra: result.uniqueId),
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
                    'see_full_results'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Non-winner buttons
            ElevatedButton(
              onPressed: () =>
                  context.go('/result-details', extra: result.uniqueId),
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

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey[300]),

          const SizedBox(height: 12),

          // Kerala Lottery Logo and text
          GestureDetector(
            onTap: _launchKeralaLotteryWebsite,
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
          ),
        ],
      ),
    );
  }

  void _launchClaimProcess(TicketCheckResponseModel result) {
    // Show claim process information
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('prize_claim_process'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${'congratulations_winning'.tr()} ${result.formattedPrize}!'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('got_it'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchKeralaLotteryWebsite();
              },
              child: Text('visit_website'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchKeralaLotteryWebsite() async {
    final Uri url = Uri.parse('https://statelottery.kerala.gov.in/index.php');
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('website_launch_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
