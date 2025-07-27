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
import 'package:lotto_app/presentation/widgets/native_ad_home_widget.dart';

class LotteryResultsSection extends StatelessWidget {
  final VoidCallback onLoadLotteryResults;
  final VoidCallback onShowDatePicker;
  final Animation<double> blinkAnimation;
  final Animation<double> badgeShimmerAnimation;
  final String Function(DateTime) formatDateForDisplay;

  const LotteryResultsSection({
    super.key,
    required this.onLoadLotteryResults,
    required this.onShowDatePicker,
    required this.blinkAnimation,
    required this.badgeShimmerAnimation,
    required this.formatDateForDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HomeScreenResultsBloc, HomeScreenResultsState>(
      buildWhen: (previous, current) {
        // Only rebuild if the actual data changed, not just loading states
        if (previous is HomeScreenResultsLoaded &&
            current is HomeScreenResultsLoaded) {
          return previous.data.results != current.data.results ||
              previous.isOffline != current.isOffline ||
              previous.isFiltered != current.isFiltered ||
              previous.filteredDate != current.filteredDate;
        }
        return true;
      },
      builder: (context, state) {
        if (state is HomeScreenResultsLoading) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.isRefreshing
                      ? 'refreshing_results'.tr()
                      : 'loading_lottery_results'.tr(),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                ),
                if (state.isRefreshing) ...[
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

        if (state is HomeScreenResultsError) {
          // If we have offline data, show it with an error banner
          if (state.hasOfflineData && state.offlineData != null) {
            return Column(
              children: [
                // Error banner
                Container(
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
                        onPressed: onLoadLotteryResults,
                        child: Text(
                          'retry'.tr(),
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: AppResponsive.fontSize(context, 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Show cached data
                _buildResultsList(state.offlineData!, theme,
                    isOfflineData: true),
              ],
            );
          }

          // No offline data available
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
                  state.message,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: AppResponsive.fontSize(context, 14),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onLoadLotteryResults,
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

        if (state is HomeScreenResultsLoaded) {
          return _buildResultsList(state.data, theme, state: state);
        }

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
      },
    );
  }

  Widget _buildDateDivider(String text, ThemeData theme, BuildContext context) {
    return GestureDetector(
      onTap: onShowDatePicker,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider(color: theme.dividerTheme.color)),
              Padding(
                padding: AppResponsive.padding(context, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppResponsive.fontSize(context, 14),
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 6)),
                    Text(
                      text,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Divider(color: theme.dividerTheme.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdDivider(ThemeData theme, BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: AppResponsive.padding(context, horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.dividerTheme.color?.withValues(alpha: 0.5),
                thickness: 1,
              ),
            ),
            Padding(
              padding: AppResponsive.padding(context, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ads_click,
                    size: AppResponsive.fontSize(context, 12),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 6)),
                  Text(
                    'sponsored'.tr(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: AppResponsive.fontSize(context, 11),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.dividerTheme.color?.withValues(alpha: 0.5),
                thickness: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      HomeScreenResultModel result, ThemeData theme, BuildContext context) {
    // Get first 6 consolation tickets for display
    List<String> consolationTickets =
        result.consolationTicketsList.take(6).toList();
    // Split into 2 rows of 3
    List<String> firstRow = consolationTickets.take(3).toList();
    List<String> secondRow = consolationTickets.skip(3).take(3).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            side: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
            ),
          ),
          child: InkWell(
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
                'isNew': result.isNew,
              });
            },
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
            child: Padding(
              padding:
                  AppResponsive.padding(context, horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with accent line
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: AppResponsive.spacing(context, 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 10)),
                      Expanded(
                        child: Text(
                          result.getFormattedTitle(context),
                          style: TextStyle(
                            fontSize: AppResponsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 6)),

                  // Prize amount in highlighted container
                  Container(
                    padding: AppResponsive.padding(context,
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.pink[50]
                          : const Color(0xFF2D1518),
                      borderRadius: BorderRadius.circular(
                          AppResponsive.spacing(context, 3)),
                    ),
                    child: Text(
                      result.formattedFirstPrize,
                      style: TextStyle(
                        fontSize: AppResponsive.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? Colors.pink[900]
                            : Colors.red[300],
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // Winner section
                  Text(
                    'first_prize_winner'.tr(),
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 13),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    result.formattedWinner,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  // Consolation prizes section with divider
                  Divider(
                    color: theme.dividerTheme.color,
                    thickness: 1,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 8)),

                  Text(
                    result.formattedConsolationPrize,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  SizedBox(height: AppResponsive.spacing(context, 12)),

                  // First row of consolation prizes
                  if (firstRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: firstRow
                          .map((prize) => _buildConsolationPrizeContainer(
                              prize, theme, context))
                          .toList(),
                    ),

                  if (secondRow.isNotEmpty)
                    SizedBox(height: AppResponsive.spacing(context, 8)),

                  // Second row of consolation prizes
                  if (secondRow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: secondRow
                          .map((prize) => _buildConsolationPrizeContainer(
                              prize, theme, context))
                          .toList(),
                    ),

                  SizedBox(height: AppResponsive.spacing(context, 16)),

                  // "See More" button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Track see more button analytics
                        AnalyticsService.trackLotteryEvent(
                          eventType: 'see_more_pressed',
                          lotteryName: result.getFormattedTitle(context),
                          resultDate: result.formattedDate,
                          additionalParams: {
                            'unique_id': result.uniqueId,
                            'source': 'see_more_button',
                          },
                        );

                        context.go('/result-details', extra: {
                          'uniqueId': result.uniqueId,
                          'isNew': result.isNew,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[800]
                            : Colors.red[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 6),
                        elevation:
                            theme.brightness == Brightness.dark ? 2.0 : 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 6)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red[700]!
                                : Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'see_more'.tr(),
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: AppResponsive.fontSize(context, 10),
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

        // Badge (New/Live/Bumper based on time, date, and lottery type)
        if (result.isNew || result.isLive || result.isBumper)
          Positioned(
            top: 13,
            right: AppResponsive.spacing(context, 16),
            child: result.isBumper
                ? _buildShimmerBadge(
                    context: context,
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shadowColor: Colors.purple.withValues(alpha: 0.4),
                    text: 'BUMPER',
                    icon: Icons.star,
                  )
                : result.isLive
                    ? AnimatedBuilder(
                        animation: blinkAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: blinkAnimation.value,
                            child: Container(
                              padding: AppResponsive.padding(context,
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(
                                      AppResponsive.spacing(context, 8)),
                                  bottomRight: Radius.circular(
                                      AppResponsive.spacing(context, 8)),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'live_badge'.tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppResponsive.fontSize(context, 10),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _buildShimmerBadge(
                        context: context,
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shadowColor: Colors.green.withValues(alpha: 0.4),
                        text: 'new_badge'.tr(),
                        backgroundColor: Colors.green,
                      ),
          ),
      ],
    );
  }

  Widget _buildConsolationPrizeContainer(
      String prize, ThemeData theme, BuildContext context) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey[200]
            : const Color(0xFF2A2A2A),
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

  Widget _buildResultsList(
    HomeScreenResultsModel data,
    ThemeData theme, {
    HomeScreenResultsLoaded? state,
    bool isOfflineData = false,
  }) {
    return Builder(
      builder: (context) {
        // Build all widgets upfront for better maintainability
        final List<Widget> allWidgets = _buildAllWidgets(
          context: context,
          data: data,
          theme: theme,
          state: state,
        );

        // Handle empty results case
        if (allWidgets.isEmpty) {
          return _buildEmptyResultsWidget(context, theme, state);
        }

        // Use CustomScrollView with pre-built widgets
        return CustomScrollView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => allWidgets[index],
                childCount: allWidgets.length,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds all widgets upfront to eliminate index mapping and type checking in builder
  List<Widget> _buildAllWidgets({
    required BuildContext context,
    required HomeScreenResultsModel data,
    required ThemeData theme,
    HomeScreenResultsLoaded? state,
  }) {
    final List<Widget> widgets = [];

    // Add filter indicator if needed
    final filterWidget = _buildFilterIndicator(context, theme, state);
    if (filterWidget != null) {
      widgets.add(filterWidget);
    }

    // Return empty list if no results (handled separately)
    if (data.results.isEmpty) {
      return [];
    }

    // Group results by date category
    final groupedResults = _groupResultsByDate(data.results);

    // Build widgets with proper ad placement: date divider → result cards → ad
    int resultCardCount = 0;
    bool isFirstDateGroup = true;
    
    for (final entry in groupedResults.entries) {
      // Add date divider first
      widgets.add(_buildDateDivider(entry.key, theme, context));
      
      // Add result cards for this date
      for (final result in entry.value) {
        widgets.add(_buildResultCard(result, theme, context));
        resultCardCount++;
        
        bool shouldInsertAd = false;
        
        // For the first date group, show ad after all its result cards are added
        if (isFirstDateGroup && result == entry.value.last) {
          shouldInsertAd = true;
        }
        // For subsequent cards, show ad after every 5th result card
        else if (!isFirstDateGroup && resultCardCount % 5 == 0) {
          shouldInsertAd = true;
        }
        
        // Insert ad if conditions are met and not at the very end
        if (shouldInsertAd && 
            !(entry == groupedResults.entries.last && 
              result == entry.value.last)) {
          widgets.add(_buildAdDivider(theme, context));
          widgets.add(const NativeAdHomeWidget());
        }
      }
      
      // Mark that we've processed the first date group
      if (isFirstDateGroup) {
        isFirstDateGroup = false;
      }
    }

    return widgets;
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
              context
                  .read<HomeScreenResultsBloc>()
                  .add(ClearDateFilterEvent());
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
              padding: AppResponsive.padding(context, horizontal: 8, vertical: 4),
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

  /// Build a badge with shimmer effect for bumper and new badges
  Widget _buildShimmerBadge({
    required BuildContext context,
    Gradient? gradient,
    Color? backgroundColor,
    required Color shadowColor,
    required String text,
    IconData? icon,
  }) {
    return AnimatedBuilder(
      animation: badgeShimmerAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Base badge container
            Container(
              padding: AppResponsive.padding(context, horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: gradient,
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppResponsive.spacing(context, 8)),
                  bottomRight: Radius.circular(AppResponsive.spacing(context, 8)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            ),
            // Shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppResponsive.spacing(context, 8)),
                  bottomRight: Radius.circular(AppResponsive.spacing(context, 8)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(badgeShimmerAnimation.value - 1, 0),
                      end: Alignment(badgeShimmerAnimation.value, 0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: AppResponsive.fontSize(context, 12),
            ),
            SizedBox(width: AppResponsive.spacing(context, 4)),
          ],
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: AppResponsive.fontSize(context, 10),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

}
