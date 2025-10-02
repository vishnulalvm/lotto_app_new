// Refactored LotteryResultDetailsScreen following proper BLoC architecture
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/services/save_results.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_event.dart';
import 'package:lotto_app/presentation/blocs/results_screen/results_details_screen_state.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/dynamic_prize_sections_widget.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/search_bar.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/result_details_app_bar.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/search_instruction_info.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/result_header_section.dart';
import 'package:lotto_app/presentation/pages/result_details_screen/widgets/contact_section.dart';
import 'package:lotto_app/core/widgets/in_app_review_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/data/services/admob_service.dart';
import 'dart:async';

class LotteryResultDetailsScreen extends StatefulWidget {
  final String? uniqueId;
  final String? lotteryNumber;
  final bool isNew;

  const LotteryResultDetailsScreen({
    super.key,
    this.uniqueId,
    this.lotteryNumber,
    this.isNew = false,
  });

  @override
  State<LotteryResultDetailsScreen> createState() =>
      _LotteryResultDetailsScreenState();
}

class _LotteryResultDetailsScreenState extends State<LotteryResultDetailsScreen>
    with TickerProviderStateMixin {
  // UI-only controllers (NOT business logic state)
  final ScrollController _scrollController = ScrollController();
  late AnimationController _blinkAnimationController;
  late Animation<double> _blinkAnimation;

  // ValueNotifier for highlighted ticket (UI optimization)
  late final ValueNotifier<String> _highlightedTicketNotifier;

  // Auto-scroll state (UI-only)
  final Map<String, GlobalKey> _ticketGlobalKeys = {};
  bool _isAutoScrolling = false;

  // Interstitial ad state (UI-only)
  bool _hasShownInterstitialAd = false;
  Timer? _adTimer;

  // Minimum search length constant
  static const int _minSearchLength = 4;

  @override
  void initState() {
    super.initState();

    // Initialize UI-only state
    _highlightedTicketNotifier = ValueNotifier<String>('');

    // Initialize blink animation for live indicator
    _blinkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkAnimationController,
      curve: Curves.easeInOut,
    ));

    _blinkAnimationController.repeat(reverse: true);

    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'result_details_screen',
          screenClass: 'LotteryResultDetailsScreen',
          parameters: {
            'unique_id': widget.uniqueId ?? 'unknown',
            'lottery_number': widget.lotteryNumber ?? 'none',
            'is_new': widget.isNew ? 1 : 0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });

    // Initialize saved results service
    _initializeSavedResultsService();

    // Load lottery result details if uniqueId is provided
    if (widget.uniqueId != null) {
      context.read<LotteryResultDetailsBloc>().add(
            LoadLotteryResultDetailsEvent(
              widget.uniqueId!,
              initialSearchQuery:
                  widget.lotteryNumber, // Auto-search if provided
            ),
          );
    }

    // Schedule interstitial ad
    _scheduleInterstitialAd();
  }

  Future<void> _initializeSavedResultsService() async {
    try {
      await SavedResultsService.init();
    } catch (e) {
      // Handle SavedResultsService initialization error silently
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _blinkAnimationController.dispose();
    _highlightedTicketNotifier.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  // Interstitial Ad Methods (UI-only, not business logic)
  void _scheduleInterstitialAd() {
    AdMobService.instance.loadAd('seemore_interstitial');

    _adTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_hasShownInterstitialAd) {
        _showInterstitialAd();
      }
    });
  }

  Future<void> _showInterstitialAd() async {
    if (_hasShownInterstitialAd) return;

    try {
      await AdMobService.instance.showInterstitialAd(
        'seemore_interstitial',
        onDismissed: () {
          if (mounted) {
            setState(() {
              _hasShownInterstitialAd = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasShownInterstitialAd = true;
        });
      }
    }
  }

  // Helper methods for presentation logic
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'matched':
        return Colors.green;
      case 'repeated':
        return Colors.blue;
      case 'patterns':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'matched':
        return Icons.check_circle_outline;
      case 'repeated':
        return Icons.repeat;
      case 'patterns':
        return Icons.grid_view;
      default:
        return Icons.check_circle_outline;
    }
  }

  bool _isResultLive(LotteryResultModel result) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resultDate = DateTime.parse(result.date);
    final resultDateOnly =
        DateTime(resultDate.year, resultDate.month, resultDate.day);

    return resultDateOnly == today && result.isPublished && !result.reOrder;
  }

  bool _isLiveHours(LotteryResultModel result) {
    return result.isPublished && !result.reOrder;
  }

  // Generate GlobalKeys for auto-scroll (UI optimization)
  void _generateTicketKeys(List<Map<String, dynamic>> filteredNumbers) {
    _ticketGlobalKeys.clear();

    for (final item in filteredNumbers) {
      final ticketNumber = item['number'].toString();
      final category = item['category'].toString();
      final keyId = '${category}_$ticketNumber';
      _ticketGlobalKeys[keyId] = GlobalKey();
    }
  }

  // Auto-scroll to first match (UI-only)
  void _scrollToFirstMatch(
      String searchQuery, List<Map<String, dynamic>> filteredNumbers) {
    if (filteredNumbers.isEmpty ||
        _ticketGlobalKeys.isEmpty ||
        _isAutoScrolling) {
      return;
    }

    try {
      setState(() {
        _isAutoScrolling = true;
      });

      final targetMatch = filteredNumbers.firstWhere(
        (item) {
          final ticketNumber = item['number'].toString().toLowerCase();
          final searchLower = searchQuery.toLowerCase();
          return ticketNumber.contains(searchLower);
        },
        orElse: () => filteredNumbers.first,
      );

      final ticketNumber = targetMatch['number'].toString();
      final category = targetMatch['category'].toString();
      final keyId = '${category}_$ticketNumber';

      final globalKey = _ticketGlobalKeys[keyId];
      if (globalKey?.currentContext != null) {
        Scrollable.ensureVisible(
          globalKey!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.2,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        ).then((_) {
          if (mounted) {
            HapticFeedback.selectionClick();
            setState(() {
              _isAutoScrolling = false;
            });
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isAutoScrolling = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAutoScrolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, context),
      floatingActionButton: _buildFloatingActionButton(),
      body: Stack(
        children: [
          // BlocListener for side effects (SnackBars, Toasts, Navigation)
          BlocListener<LotteryResultDetailsBloc, LotteryResultDetailsState>(
            listener: (context, state) {
              if (state is LotteryResultDetailsLoaded) {
                // Handle success messages
                if (state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(state.successMessage!)),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                      action: state.successMessage!.contains('Saved')
                          ? SnackBarAction(
                              label: 'View',
                              textColor: Colors.white,
                              onPressed: () => context.go('/saved-results'),
                            )
                          : null,
                    ),
                  );
                  // Clear message after showing
                  context
                      .read<LotteryResultDetailsBloc>()
                      .add(const ClearMessagesEvent());
                }

                // Handle error messages
                if (state.errorMessage != null) {
                  if (state.errorMessage!.contains('No results found')) {
                    // Show toast for search errors
                    Fluttertoast.showToast(
                      msg: state.errorMessage!,
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      timeInSecForIosWeb: 2,
                      backgroundColor: Colors.red[800],
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  } else {
                    // Show SnackBar for other errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text(state.errorMessage!)),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  context
                      .read<LotteryResultDetailsBloc>()
                      .add(const ClearMessagesEvent());
                }

                // Update highlighted ticket notifier for search
                if (state.searchQuery.length >= _minSearchLength) {
                  _highlightedTicketNotifier.value = state.searchQuery;

                  // Generate keys and auto-scroll on search
                  if (state.filteredLotteryNumbers.isNotEmpty) {
                    _generateTicketKeys(state.filteredLotteryNumbers);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted) {
                          _scrollToFirstMatch(
                              state.searchQuery, state.filteredLotteryNumbers);
                        }
                      });
                    });

                    // Haptic feedback
                    HapticFeedback.lightImpact();
                  }
                } else {
                  _highlightedTicketNotifier.value = '';
                  _ticketGlobalKeys.clear();
                }
              }
            },
            child: BlocBuilder<LotteryResultDetailsBloc,
                LotteryResultDetailsState>(
              // Optimize rebuilds with buildWhen
              buildWhen: (previous, current) {
                // Only rebuild when display data actually changes
                if (previous is LotteryResultDetailsLoaded &&
                    current is LotteryResultDetailsLoaded) {
                  return previous.filteredLotteryNumbers !=
                          current.filteredLotteryNumbers ||
                      previous.selectedFilter != current.selectedFilter ||
                      previous.matchedNumbers != current.matchedNumbers ||
                      previous.patternNumbers != current.patternNumbers ||
                      previous.newlyUpdatedTickets !=
                          current.newlyUpdatedTickets ||
                      previous.data.result.uniqueId !=
                          current.data.result.uniqueId;
                }
                return true; // Always rebuild for state transitions
              },
              builder: (context, state) {
                if (state is LotteryResultDetailsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is LotteryResultDetailsError) {
                  return _buildErrorWidget(theme, state.message);
                } else if (state is LotteryResultDetailsLoaded) {
                  return _buildLoadedContent(theme, state);
                } else {
                  return _buildInitialWidget(theme);
                }
              },
            ),
          ),
          // Fixed live indicator at top of screen
          BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
            buildWhen: (previous, current) {
              // Only rebuild if live status might have changed
              if (previous is LotteryResultDetailsLoaded &&
                  current is LotteryResultDetailsLoaded) {
                return _isResultLive(previous.data.result) !=
                    _isResultLive(current.data.result);
              }
              return true;
            },
            builder: (context, state) {
              if (state is LotteryResultDetailsLoaded) {
                final isLive = _isResultLive(state.data.result);

                if (isLive) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _blinkAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _blinkAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LIVE - Results updating',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(
      ThemeData theme, LotteryResultDetailsLoaded state) {
    final result = state.data.result;
    final isSearchActive = state.searchQuery.isNotEmpty &&
        state.searchQuery.length >= _minSearchLength;

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.uniqueId != null) {
          context.read<LotteryResultDetailsBloc>().add(
                RefreshLotteryResultDetailsEvent(widget.uniqueId!),
              );
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            top: _isResultLive(result) ? 56.0 : 8.0,
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResultHeaderSection(result: result),
              const SizedBox(height: 6),
              // Show search instruction if query is too short
              if (state.searchQuery.isNotEmpty && !isSearchActive)
                SearchInstructionInfo(
                  minSearchLength: _minSearchLength,
                  currentSearchLength: state.searchQuery.length,
                ),
              const SizedBox(height: 6),
              DynamicPrizeSectionsWidget(
                key: ValueKey('prize_sections_${result.uniqueId}'),
                result: result,
                allLotteryNumbers: state.filteredLotteryNumbers,
                highlightedTicketNotifier: _highlightedTicketNotifier,
                ticketGlobalKeys: _ticketGlobalKeys,
                isLiveHours: _isLiveHours(result),
                newlyUpdatedTickets: state.newlyUpdatedTickets,
                matchedNumbers: state.matchedNumbers,
                matchHighlightColor: Colors.green,
                patternNumbers: state.patternNumbers,
                patternHighlightColor: Colors.purple.shade200,
              ),
              const InAppReviewWidget(
                viewThreshold: 3,
                daysAfterInstall: 7,
              ),
              const SizedBox(height: 6),
              const ContactSection(),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
      buildWhen: (previous, current) {
        // Only rebuild if refresh state or data availability changes
        if (previous is LotteryResultDetailsLoaded &&
            current is LotteryResultDetailsLoaded) {
          return previous.isRefreshing != current.isRefreshing ||
              previous.allLotteryNumbers.isEmpty !=
                  current.allLotteryNumbers.isEmpty;
        }
        return true;
      },
      builder: (context, state) {
        if (state is LotteryResultDetailsLoaded &&
            state.allLotteryNumbers.isNotEmpty) {
          if (widget.isNew && _isLiveHours(state.data.result)) {
            // Show refresh button for new lottery during live hours
            final theme = Theme.of(context);
            return FloatingActionButton.extended(
              onPressed: state.isRefreshing
                  ? null
                  : () {
                      if (widget.uniqueId != null) {
                        context.read<LotteryResultDetailsBloc>().add(
                              RefreshLotteryResultDetailsEvent(
                                  widget.uniqueId!),
                            );
                      }
                    },
              backgroundColor: state.isRefreshing
                  ? theme.colorScheme.surface
                  : theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
              icon: state.isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 24, color: Colors.white),
              label: Text(
                state.isRefreshing ? 'Refreshing...' : 'Refresh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: state.isRefreshing
                      ? theme.colorScheme.onSurface
                      : Colors.white,
                ),
              ),
              tooltip: state.isRefreshing
                  ? 'Refreshing results...'
                  : 'Refresh results',
            );
          } else {
            // Show FloatingSearchBar as FAB
            return FloatingSearchBar(
              hintText: 'Eg. PV409930,',
              onChanged: (query) {
                context.read<LotteryResultDetailsBloc>().add(
                      SearchQueryChangedEvent(query),
                    );
              },
              onSubmitted: (query) {
                context.read<LotteryResultDetailsBloc>().add(
                      SearchQueryChangedEvent(query),
                    );
              },
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, BuildContext context) {
    return _BlocAppBarWrapper(
      getFilterColor: _getFilterColor,
      getFilterIcon: _getFilterIcon,
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed Loading Result',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.uniqueId != null) {
                  context.read<LotteryResultDetailsBloc>().add(
                        LoadLotteryResultDetailsEvent(widget.uniqueId!),
                      );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Lottery Result Selected',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a lottery result to view details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget to make BlocBuilder work with PreferredSizeWidget
class _BlocAppBarWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  final Function(String) getFilterColor;
  final Function(String) getFilterIcon;

  const _BlocAppBarWrapper({
    required this.getFilterColor,
    required this.getFilterIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LotteryResultDetailsBloc, LotteryResultDetailsState>(
      buildWhen: (previous, current) {
        // Only rebuild AppBar if relevant state changes
        if (previous is LotteryResultDetailsLoaded &&
            current is LotteryResultDetailsLoaded) {
          return previous.selectedFilter != current.selectedFilter ||
              previous.isSaved != current.isSaved ||
              previous.isGeneratingPdf != current.isGeneratingPdf;
        }
        return true;
      },
      builder: (context, state) {
        if (state is LotteryResultDetailsLoaded) {
          return ResultDetailsAppBar(
            selectedFilter: state.selectedFilter,
            isSaved: state.isSaved,
            isGeneratingPdf: state.isGeneratingPdf,
            onFilterSelected: (filterType) {
              context.read<LotteryResultDetailsBloc>().add(
                    FilterChangedEvent(filterType),
                  );
            },
            onCopyAndShare: (_) {
              context.read<LotteryResultDetailsBloc>().add(
                    const CopyResultEvent(),
                  );
            },
            onShareAsPdf: (_) {
              context.read<LotteryResultDetailsBloc>().add(
                    const GeneratePdfEvent(),
                  );
            },
            onToggleSave: (_) {
              context.read<LotteryResultDetailsBloc>().add(
                    const ToggleSaveResultEvent(),
                  );
            },
            getFilterColor: getFilterColor,
            getFilterIcon: getFilterIcon,
          );
        }

        // Default AppBar for non-loaded states
        return AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: theme.appBarTheme.iconTheme?.color),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Lottery Result',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
