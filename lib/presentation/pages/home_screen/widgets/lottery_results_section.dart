import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_bloc.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_event.dart';
import 'package:lotto_app/presentation/blocs/home_screen/home_screen_state.dart';
import 'package:lotto_app/data/services/analytics_service.dart';
import 'package:lotto_app/core/services/widget_capture_service.dart';
import 'package:lotto_app/core/constants/theme/app_theme.dart';

class LotteryResultsSection extends StatelessWidget {
  // Map to store GlobalKeys for each result card
  static final Map<String, GlobalKey> _cardKeys = {};
  final VoidCallback onLoadLotteryResults;
  final VoidCallback onShowDatePicker;
  final Animation<double> blinkAnimation;
  final String Function(DateTime) formatDateForDisplay;

  const LotteryResultsSection({
    super.key,
    required this.onLoadLotteryResults,
    required this.onShowDatePicker,
    required this.blinkAnimation,
    required this.formatDateForDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
      // Only rebuild when state type changes or data actually changes
      buildWhen: (previous, current) {
        // Always rebuild for state type changes
        if (previous.runtimeType != current.runtimeType) return true;

        // For loaded states, check if data actually changed
        if (previous is HomeScreenResultsLoaded && current is HomeScreenResultsLoaded) {
          return previous.data != current.data ||
                 previous.isFiltered != current.isFiltered ||
                 previous.filteredDate != current.filteredDate;
        }

        return true;
      },
      builder: (context, state) {
        if (state is HomeScreenResultsLoading) {
          return _LoadingStateWidget(
            theme: theme,
            isRefreshing: state.isRefreshing,
          );
        }

        if (state is HomeScreenResultsError) {
          // If we have offline data, show it with an error banner
          if (state.hasOfflineData && state.offlineData != null) {
            return Column(
              children: [
                // Error banner
                _ErrorBannerWidget(
                  theme: theme,
                  onRetry: onLoadLotteryResults,
                ),
                // Show cached data
                _buildResultsList(state.offlineData!, theme,
                    isOfflineData: true),
              ],
            );
          }

          // No offline data available
          return _ErrorStateWidget(
            theme: theme,
            errorMessage: state.message,
            onRetry: onLoadLotteryResults,
          );
        }

        if (state is HomeScreenResultsLoaded) {
          return _buildResultsList(state.data, theme, state: state);
        }

        return _EmptyStateWidget(theme: theme);
      },
    );
  }

  // This method now delegates to the extracted LotteryResultCard widget
  Widget _buildResultCard(
      HomeScreenResultModel result, ThemeData theme, BuildContext context,
      {int index = -1}) {
    return LotteryResultCard(
      result: result,
      theme: theme,
      blinkAnimation: blinkAnimation,
      index: index,
    );
  }

  Widget _buildResultsList(
    HomeScreenResultsModel data,
    ThemeData theme, {
    HomeScreenResultsLoaded? state,
    bool isOfflineData = false,
  }) {
    return Builder(
      builder: (context) {
        // Handle empty results case
        if (data.results.isEmpty) {
          return _buildEmptyResultsWidget(context, theme, state);
        }

        // Group results by date category once
        final groupedResults = _groupResultsByDate(data.results);

        // Flatten grouped results for efficient indexing
        final flatResults =
            groupedResults.entries.expand((entry) => entry.value).toList();

        // Check if we need to show filter indicator
        final hasFilterIndicator =
            state != null && state.isFiltered && state.filteredDate != null;

        // Build filter indicator widget outside ListView for better performance
        final filterWidget = hasFilterIndicator
            ? _buildFilterIndicator(context, theme, state)
            : null;

        // Use Column to separate filter indicator from ListView
        return Column(
          children: [
            // Filter indicator (if present) - outside ListView so it doesn't rebuild on scroll
            if (filterWidget != null) filterWidget,
            // ListView.builder for lazy loading with RepaintBoundary
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: flatResults.length,
              itemBuilder: (context, index) {
                final result = flatResults[index];
                // Wrap in RepaintBoundary for better performance
                return _buildResultCard(result, theme, context, index: index);
              },
            ),
          ],
        );
      },
    );
  }

  /// Builds filter indicator widget if needed
  Widget? _buildFilterIndicator(
    BuildContext context,
    ThemeData theme,
    HomeScreenResultsLoaded? state,
  ) {
    if (state == null || !state.isFiltered || state.filteredDate == null) {
      return null;
    }

    return Container(
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: theme.colorScheme.primary,
            size: AppResponsive.fontSize(context, 20),
          ),
          SizedBox(width: AppResponsive.spacing(context, 8)),
          Expanded(
            child: Text(
              '${'showing_results_for'.tr()}${formatDateForDisplay(state.filteredDate!)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: AppResponsive.fontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<HomeScreenResultsBloc>().add(ClearDateFilterEvent());
            },
            icon: Icon(
              Icons.clear,
              size: AppResponsive.fontSize(context, 16),
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'show_all'.tr(),
              style: TextStyle(
                fontSize: AppResponsive.fontSize(context, 12),
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  AppResponsive.padding(context, horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty results widget
  Widget _buildEmptyResultsWidget(
    BuildContext context,
    ThemeData theme,
    HomeScreenResultsLoaded? state,
  ) {
    final List<Widget> children = [];

    // Add filter indicator if present
    final filterWidget = _buildFilterIndicator(context, theme, state);
    if (filterWidget != null) {
      children.add(filterWidget);
    }

    // Add empty state content
    children.add(
      Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              size: AppResponsive.fontSize(context, 48),
            ),
            const SizedBox(height: 16),
            Text(
              (state?.isFiltered == true)
                  ? 'no_results_selected_date'.tr()
                  : 'no_results_available'.tr(),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: AppResponsive.fontSize(context, 16),
              ),
              textAlign: TextAlign.center,
            ),
            if (state?.isFiltered == true) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<HomeScreenResultsBloc>()
                      .add(ClearDateFilterEvent());
                },
                icon: const Icon(Icons.clear),
                label: Text(
                  'show_all_results'.tr(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.floatingActionButtonTheme.backgroundColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Column(children: children);
  }

  /// Groups results by formatted date
  Map<String, List<HomeScreenResultModel>> _groupResultsByDate(
    List<HomeScreenResultModel> results,
  ) {
    final Map<String, List<HomeScreenResultModel>> groupedResults = {};

    for (final result in results) {
      final dateCategory = result.formattedDate;
      groupedResults.putIfAbsent(dateCategory, () => []).add(result);
    }

    return groupedResults;
  }
}

/// Separate widget for lottery result card - improves performance by allowing Flutter to cache
class LotteryResultCard extends StatelessWidget {
  final HomeScreenResultModel result;
  final ThemeData theme;
  final Animation<double> blinkAnimation;
  final int index;

  const LotteryResultCard({
    super.key,
    required this.result,
    required this.theme,
    required this.blinkAnimation,
    this.index = -1,
  });

  @override
  Widget build(BuildContext context) {
    // Get first 5 consolation tickets for display
    List<String> consolationTickets =
        result.consolationTicketsList.take(5).toList();
    // Split into 2 rows: 3 in first row, 2 in second row
    List<String> firstRow = consolationTickets.take(3).toList();
    List<String> secondRow = consolationTickets.skip(3).take(2).toList();

    // Define colors based on bumper status
    final bool isBumper = result.isBumper;
    final themeExtension = theme.extension<AppThemeExtension>()!;

    final Gradient firstPrizeGradient = isBumper
        ? LinearGradient(
            colors: [
              themeExtension.bumperPrimaryColor,
              themeExtension.bumperSecondaryColor,
              themeExtension.bumperSecondaryColor.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    // Get or create a GlobalKey for this result card
    final cardKey = LotteryResultsSection._cardKeys.putIfAbsent(
      result.uniqueId,
      () => GlobalKey(),
    );

    return RepaintBoundary(
      key: cardKey,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card
          Card(
            elevation: 1,
            color: theme.cardTheme.color,
            margin: AppResponsive.margin(context, horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppResponsive.spacing(context, 6)),
            ),
            child: GestureDetector(
              onTap: () {
                // Track lottery result view
                AnalyticsService.trackLotteryEvent(
                  eventType: 'result_view',
                  lotteryName: result.getFormattedTitle(context),
                  resultDate: result.formattedDate,
                  additionalParams: {
                    'unique_id': result.uniqueId,
                    'source': 'home_screen_card',
                  },
                );

                context.go('/result-details', extra: {
                  'uniqueId': result.uniqueId,
                  'lotteryNumber':
                      null, // No lottery number available from home screen results
                  'isNew': result.isNew,
                });
              },
              onLongPress: () async {
                // Capture and share the result card
                // Format date for filename (remove special characters)
                final dateForFilename =
                    result.formattedDate.replaceAll('/', '-');

                await WidgetCaptureService.captureAndShare(
                  key: cardKey,
                  fileName:
                      'lottery_${result.lotteryCode}_${result.drawNumber}_$dateForFilename',
                  shareText:
                      '${result.getFormattedTitle(context)} - ${result.formattedDate}\n\nDownload app: https://play.google.com/store/apps/details?id=app.solidapps.lotto',
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section - Lottery Name, Prize Amount, Date
                  Container(
                    width: double.infinity,
                    padding: AppResponsive.padding(context,
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : Colors.grey[900],
                      borderRadius: BorderRadius.only(
                        topLeft:
                            Radius.circular(AppResponsive.spacing(context, 12)),
                        topRight:
                            Radius.circular(AppResponsive.spacing(context, 12)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Lottery Name
                        Text(
                          result.getFormattedTitle(context),
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Date Display
                        Text(
                          result.formattedDate,
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: AppResponsive.padding(context,
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: firstPrizeGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "FIRST PRIZE" Text
                        Text(
                          'FIRST PRIZE',
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),

                        // Winner Number
                        Text(
                          result.firstPrize.ticketNumber,
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 34),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),

                        // Location with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: AppResponsive.fontSize(context, 16),
                              color: Colors.white,
                            ),
                            SizedBox(width: AppResponsive.spacing(context, 4)),
                            Text(
                              result.firstPrize
                                  .place, // You might need to add location to your model
                              style: TextStyle(
                                fontSize: AppResponsive.fontSize(context, 18),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Consolation Section
                  Container(
                    width: double.infinity,
                    padding: AppResponsive.padding(context,
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : Colors.grey[900],
                      borderRadius: BorderRadius.only(
                        bottomLeft:
                            Radius.circular(AppResponsive.spacing(context, 12)),
                        bottomRight:
                            Radius.circular(AppResponsive.spacing(context, 12)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Consolation Prize Title
                        Text(
                          result.formattedConsolationPrize,
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),

                        SizedBox(height: AppResponsive.spacing(context, 10)),

                        // First row of consolation prizes
                        if (firstRow.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: firstRow
                                .map((prize) => ConsolationPrizeContainer(
                                    prize: prize))
                                .toList(),
                          ),

                        if (secondRow.isNotEmpty)
                          SizedBox(height: AppResponsive.spacing(context, 8)),

                        // Second row of consolation prizes with "See More" button
                        if (secondRow.isNotEmpty)
                          Row(
                            // spacing: 18,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First prize in second row
                              ConsolationPrizeContainer(
                                  prize: secondRow[0]),
                              // Second prize in second row (if exists)
                              if (secondRow.length > 1)
                                ConsolationPrizeContainer(
                                    prize: secondRow[1])
                              else
                                const SizedBox.shrink(),
                              // "See More" button as third item
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isBumper
                                        ? [
                                            themeExtension.bumperPrimaryColor,
                                            themeExtension.bumperSecondaryColor,
                                          ]
                                        : [
                                            theme.primaryColor,
                                            theme.primaryColor
                                                .withValues(alpha: 0.85),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      AppResponsive.spacing(context, 4)),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Track see more button analytics
                                    AnalyticsService.trackLotteryEvent(
                                      eventType: 'see_more_pressed',
                                      lotteryName:
                                          result.getFormattedTitle(context),
                                      resultDate: result.formattedDate,
                                      additionalParams: {
                                        'unique_id': result.uniqueId,
                                        'source': 'see_more_button',
                                      },
                                    );

                                    context.go('/result-details', extra: {
                                      'uniqueId': result.uniqueId,
                                      'lotteryNumber': null,
                                      'isNew': result.isNew,
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: AppResponsive.padding(context,
                                        horizontal: 13, vertical: 5),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppResponsive.spacing(context, 7)),
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'See More',
                                        style: TextStyle(
                                          fontSize: AppResponsive.fontSize(
                                              context, 12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(
                                          width: AppResponsive.spacing(
                                              context, 3)),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size:
                                            AppResponsive.fontSize(context, 10),
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                        SizedBox(height: AppResponsive.spacing(context, 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badge (New/Live/Bumper based on time, date, and lottery type)
          // Show NEW badge on first card (index == 0) regardless of date
          if (result.isNew || result.isLive || result.isBumper || index == 0)
            Positioned(
              top: 7,
              right: AppResponsive.spacing(context, 11),
              child: _BadgeWidget(
                result: result,
                blinkAnimation: blinkAnimation,
                themeExtension: themeExtension,
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge widget for NEW/LIVE/BUMPER indicators - extracted for better animation performance
class _BadgeWidget extends StatelessWidget {
  final HomeScreenResultModel result;
  final Animation<double> blinkAnimation;
  final AppThemeExtension themeExtension;

  const _BadgeWidget({
    required this.result,
    required this.blinkAnimation,
    required this.themeExtension,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isBumper) {
      return _buildShimmerBadge(
        context: context,
        gradient: LinearGradient(
          colors: [
            themeExtension.bumperPrimaryColor,
            themeExtension.bumperSecondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: themeExtension.bumperPrimaryColor
            .withValues(alpha: 0.4),
        text: 'BUMPER',
      );
    } else if (result.isLive) {
      return AnimatedBuilder(
        animation: blinkAnimation,
        child: Container(
          padding: AppResponsive.padding(context,
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(
                  AppResponsive.spacing(context, 10)),
              topRight: Radius.circular(
                  AppResponsive.spacing(context, 8)),
            ),
            color: themeExtension.liveColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'live_badge'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: AppResponsive.fontSize(context, 9),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        builder: (context, child) {
          return Opacity(
            opacity: blinkAnimation.value,
            child: child,
          );
        },
      );
    } else {
      return _buildShimmerBadge(
        context: context,
        gradient: LinearGradient(
          colors: [
            themeExtension.newColor,
            themeExtension.newColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor:
            themeExtension.newColor.withValues(alpha: 0.4),
        text: 'new_badge'.tr(),
        backgroundColor: themeExtension.newColor,
      );
    }
  }

  Widget _buildShimmerBadge({
    required BuildContext context,
    Gradient? gradient,
    Color? backgroundColor,
    required Color shadowColor,
    required String text,
  }) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppResponsive.spacing(context, 12)),
          topRight: Radius.circular(AppResponsive.spacing(context, 8)),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: AppResponsive.fontSize(context, 10),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Loading state widget - separate to prevent full screen rebuilds
class _LoadingStateWidget extends StatelessWidget {
  final ThemeData theme;
  final bool isRefreshing;

  const _LoadingStateWidget({
    required this.theme,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            isRefreshing
                ? 'refreshing_results'.tr()
                : 'loading_lottery_results'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: AppResponsive.fontSize(context, 14),
            ),
          ),
          if (isRefreshing) ...[
            const SizedBox(height: 8),
            Text(
              'getting_latest_data'.tr(),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.7),
                fontSize: AppResponsive.fontSize(context, 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error banner widget - separate for better rebuild scope
class _ErrorBannerWidget extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onRetry;

  const _ErrorBannerWidget({
    required this.theme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.withValues(alpha: 0.1),
      padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Colors.red,
              size: AppResponsive.fontSize(context, 20)),
          SizedBox(width: AppResponsive.spacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'connection_error'.tr(),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: AppResponsive.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'showing_cached_data'.tr(),
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: AppResponsive.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'retry'.tr(),
              style: TextStyle(
                  color: Colors.red,
                  fontSize: AppResponsive.fontSize(context, 12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state widget - separate for better rebuild scope
class _ErrorStateWidget extends StatelessWidget {
  final ThemeData theme;
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorStateWidget({
    required this.theme,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: AppResponsive.fontSize(context, 48),
          ),
          const SizedBox(height: 16),
          Text(
            'failed_load_results'.tr(),
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontSize: AppResponsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: AppResponsive.fontSize(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('try_again'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget - separate for better rebuild scope
class _EmptyStateWidget extends StatelessWidget {
  final ThemeData theme;

  const _EmptyStateWidget({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Text(
        'pull_refresh_lottery_results'.tr(),
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          fontSize: AppResponsive.fontSize(context, 14),
        ),
      ),
    );
  }
}

/// Consolation prize container - optimized to look up theme internally
/// This prevents unnecessary rebuilds when parent passes theme as parameter
class ConsolationPrizeContainer extends StatelessWidget {
  final String prize;

  const ConsolationPrizeContainer({
    super.key,
    required this.prize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppResponsive.padding(context, horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 4)),
      ),
      child: Text(
        prize,
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 13),
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
