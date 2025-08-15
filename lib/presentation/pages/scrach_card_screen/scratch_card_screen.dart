import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_bloc.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_event.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_state.dart';
import 'package:lotto_app/presentation/pages/scrach_card_screen/widgets/scratch_card_bottom_sheet.dart';
import 'package:lotto_app/presentation/pages/scrach_card_screen/widgets/result_type_banner.dart';
import 'package:lotto_app/presentation/pages/scrach_card_screen/widgets/result_card.dart';
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
      body: SafeArea(
        child: BlocListener<TicketCheckBloc, TicketCheckState>(
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
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: ResultCard(
                      type: ResultCardType.loading,
                      theme: theme,
                    ),
                  ),
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
            // Banner always shows - different messages based on scratch state
            ResultTypeBanner(
              result: result,
              shouldShowScratch: shouldShowScratch,
              autoRevealTriggered: _autoRevealTriggered,
              ticketData: widget.ticketData,
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _animation,
                    child: shouldShowScratch
                        ? ResultCard(
                            type: ResultCardType.scratchCard,
                            theme: theme,
                            result: result,
                            ticketData: widget.ticketData,
                            scratcherKey: _scratcherKey,
                            onScratchUpdate: _onScratchUpdate,
                            onThreshold: () {
                              if (!_autoRevealTriggered) {
                                _autoRevealTriggered = true;
                                _autoRevealScratchCard();
                              }
                            },
                            autoRevealTriggered: _autoRevealTriggered,
                            scratchProgress: scratchProgress,
                          )
                        : ResultCard(
                            type: ResultCardType.noResult,
                            theme: theme,
                            result: result,
                            ticketData: widget.ticketData,
                          ),
                  ),
                ),
              ),
            ),
            ScratchCardBottomSheet(
              result: result,
              ticketData: widget.ticketData,
              onCheckAgain: () async => context.go('/barcode_scanner_screen'),
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
}
