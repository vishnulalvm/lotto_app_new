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

class LotteryResultsSection extends StatelessWidget {
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
    // Define colors based on theme brightness
    final dividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF616161) // Medium-dark grey for dark mode
        : Colors.grey[600]; // Darker grey for light mode

    final textColor = theme.brightness == Brightness.dark
        ? const Color(0xFFE0E0E0) // Light grey for dark mode
        : Colors.black87; // Normal dark text for light mode

    return GestureDetector(
      onTap: onShowDatePicker,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: AppResponsive.padding(context, horizontal: 24, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: dividerColor,
                  thickness: 1.0, // Thicker divider for better visibility
                ),
              ),
              Padding(
                padding: AppResponsive.padding(context, horizontal: 16),
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppResponsive.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: dividerColor,
                  thickness: 1.0, // Thicker divider for better visibility
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
      HomeScreenResultModel result, ThemeData theme, BuildContext context) {
    // Get first 5 consolation tickets for display
    List<String> consolationTickets =
        result.consolationTicketsList.take(5).toList();
    // Split into 2 rows: 3 in first row, 2 in second row
    List<String> firstRow = consolationTickets.take(3).toList();
    List<String> secondRow = consolationTickets.skip(3).take(2).toList();

    // Define colors based on bumper status
    final bool isBumper = result.isBumper;
    final Gradient firstPrizeGradient = isBumper
        ? const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFFA5053), // #FA5053
              Color(0xFFE75353),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card
        Card(
          color: theme.cardTheme.color,
          margin: AppResponsive.margin(context, horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
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
                'lotteryNumber':
                    null, // No lottery number available from home screen results
                'isNew': result.isNew,
              });
            },
            borderRadius:
                BorderRadius.circular(AppResponsive.spacing(context, 12)),
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

                      // Prize Amount and Date Column
                      Column(
                        children: [
                          // Prize Amount
                          Text(
                            result.firstPrize.amount >= 10000000
                                ? '₹${result.firstPrize.amount.toInt()}/-'
                                : '₹${result.firstPrize.amount.toInt()}/-',
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 18),
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
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
                              .map((prize) =>
                                  ConsolationPrizeContainer(prize: prize))
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
                            ConsolationPrizeContainer(prize: secondRow[0]),
                            // Second prize in second row (if exists)
                            if (secondRow.length > 1)
                              ConsolationPrizeContainer(prize: secondRow[1])
                            else
                              const SizedBox.shrink(),
                            // "See More" button as third item
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isBumper
                                      ? [Colors.purple, Colors.deepPurple]
                                      : const [
                                          Color(0xFFFA5053), // #FA5053
                                          Color(0xFFE75353),
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
                                        fontSize:
                                            AppResponsive.fontSize(context, 12),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            AppResponsive.spacing(context, 3)),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: AppResponsive.fontSize(context, 10),
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
                            color: Colors.red,
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

    // Build widgets: date divider → result cards
    for (final entry in groupedResults.entries) {
      // Add date divider first
      widgets.add(_buildDateDivider(entry.key, theme, context));

      // Add result cards for this date
      for (final result in entry.value) {
        widgets.add(_buildResultCard(result, theme, context));
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

  /// Build a badge with shimmer effect for bumper and new badges - diagonal ribbon style
  Widget _buildShimmerBadge({
    required BuildContext context,
    Gradient? gradient,
    Color? backgroundColor,
    required Color shadowColor,
    required String text,
    IconData? icon,
  }) {
    return Container(
      padding: AppResponsive.padding(context, horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft:
              Radius.circular(AppResponsive.spacing(context, 12)),
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

class ConsolationPrizeContainer extends StatelessWidget {
  final String prize;

  const ConsolationPrizeContainer({
    super.key,
    required this.prize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppResponsive.padding(context, horizontal: 14, vertical: 4),
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
}
