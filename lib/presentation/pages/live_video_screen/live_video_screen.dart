import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_bloc.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_event.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_state.dart';
import 'package:lotto_app/data/services/analytics_service.dart';

class LiveVideoScreen extends StatefulWidget {
  const LiveVideoScreen({super.key});

  @override
  State<LiveVideoScreen> createState() => _LiveVideoScreenState();
}

class _LiveVideoScreenState extends State<LiveVideoScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes (following home screen pattern)
    WidgetsBinding.instance.addObserver(this);

    // Track screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        AnalyticsService.trackScreenView(
          screenName: 'live_video_screen',
          screenClass: 'LiveVideoScreen',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      });
    });

    // Load live videos immediately
    context.read<LiveVideoBloc>().add(LoadLiveVideosEvent());

    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Use a smooth curve for the animation (following home screen pattern)
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    _fabAnimationController.forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      // Scrolling down - collapse FAB
      // Only trigger animation if not already animating in that direction
      if (_isExpanded && !_fabAnimationController.isAnimating) {
        _isExpanded = false;
        _fabAnimationController.reverse();
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - expand FAB
      // Only trigger animation if not already animating in that direction
      if (!_isExpanded && !_fabAnimationController.isAnimating) {
        _isExpanded = true;
        _fabAnimationController.forward();
      }
    }
  }

  /// Launch YouTube URL when button is tapped
  Future<void> _launchYouTubeUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final bool canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          _showErrorSnackBar('could_not_open_website'.tr());
        }
      } else {
        _showErrorSnackBar('could_not_open_website'.tr());
      }
    } catch (e) {
      _showErrorSnackBar('error_opening_website'.tr());
    }
  }

  /// Show error snackbar (following home screen pattern)
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'retry'.tr(),
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Format date for display (following home screen pattern)
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'month_jan'.tr(),
      'month_feb'.tr(),
      'month_mar'.tr(),
      'month_apr'.tr(),
      'month_may'.tr(),
      'month_jun'.tr(),
      'month_jul'.tr(),
      'month_aug'.tr(),
      'month_sep'.tr(),
      'month_oct'.tr(),
      'month_nov'.tr(),
      'month_dec'.tr()
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: BlocListener<LiveVideoBloc, LiveVideoState>(
        listener: (context, state) {
          if (state is LiveVideoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('error_prefix'.tr()),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'retry'.tr(),
                  textColor: Colors.white,
                  onPressed: () =>
                      context.read<LiveVideoBloc>().add(LoadLiveVideosEvent()),
                ),
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<LiveVideoBloc>().add(RefreshLiveVideosEvent());
          },
          child: BlocBuilder<LiveVideoBloc, LiveVideoState>(
            builder: (context, state) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (state is LiveVideoLoading && !state.isRefreshing)
                      _buildLoadingState(theme)
                    else if (state is LiveVideoLoaded)
                      _buildVideosList(state.videos, theme)
                    else if (state is LiveVideoError)
                      _buildErrorState(theme, state.message)
                    else
                      _buildLoadingState(theme),
                    SizedBox(height: AppResponsive.spacing(context, 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildRefreshButton(theme),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.appBarTheme.iconTheme?.color,
          size: AppResponsive.fontSize(context, 24),
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'live_video_results'.tr(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVideosList(List<LiveVideoModel> videos, ThemeData theme) {
    if (videos.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Use ListView.builder for lazy loading - much better performance
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: _buildVideoCard(videos[index], theme),
        );
      },
    );
  }

  Widget _buildVideoCard(LiveVideoModel video, ThemeData theme) {
    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
      elevation: theme.brightness == Brightness.dark ? 3.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.08),
          width: theme.brightness == Brightness.dark ? 0.8 : 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail section
          GestureDetector(
            onTap: () => _launchYouTubeUrl(video.youtubeUrl),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppResponsive.spacing(context, 8)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      memCacheWidth: 800, // Limit memory cache size
                      maxWidthDiskCache: 800, // Limit disk cache size
                      errorWidget: (context, url, error) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.video_library,
                              size: AppResponsive.fontSize(context, 50),
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                      placeholder: (context, url) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.vertical(
                        top:
                            Radius.circular(AppResponsive.spacing(context, 16)),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: AppResponsive.padding(context,
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.black87,
                          size: AppResponsive.fontSize(context, 28),
                        ),
                      ),
                    ),
                  ),
                ),
                // Live badge
                if (video.isLive)
                  Positioned(
                    top: AppResponsive.spacing(context, 12),
                    right: AppResponsive.spacing(context, 12),
                    child: Container(
                      padding: AppResponsive.padding(context,
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                            AppResponsive.spacing(context, 6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppResponsive.spacing(context, 4)),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppResponsive.fontSize(context, 9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video details section
          Padding(
            padding:
                AppResponsive.padding(context, horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with accent line
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: AppResponsive.spacing(context, 45),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.formattedTitle,
                            style: TextStyle(
                              fontSize: AppResponsive.fontSize(context, 17),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: theme.textTheme.titleLarge?.color,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppResponsive.spacing(context, 6)),
                          // Highlighted date
                          Container(
                            padding: AppResponsive.padding(context,
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppResponsive.spacing(context, 6)),
                            ),
                            child: Text(
                              _formatDateForDisplay(video.dateTime),
                              style: TextStyle(
                                fontSize: AppResponsive.fontSize(context, 11),
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description (limited)
                if (video.description.isNotEmpty) ...[
                  SizedBox(height: AppResponsive.spacing(context, 10)),
                  Text(
                    video.formattedDescription.length > 80
                        ? '${video.formattedDescription.substring(0, 80)}...'
                        : video.formattedDescription,
                    style: TextStyle(
                      fontSize: AppResponsive.fontSize(context, 12),
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Bottom section with status and YouTube button
                // SizedBox(height: AppResponsive.spacing(context, 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status badge
                    Container(
                      padding: AppResponsive.padding(context,
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: video.isLive
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppResponsive.spacing(context, 8)),
                      ),
                      child: Text(
                        video.statusLabel,
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 10),
                          fontWeight: FontWeight.w600,
                          color: video.isLive
                              ? Colors.red
                              : theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    // YouTube button (bottom right)
                    ElevatedButton.icon(
                      onPressed: () => _launchYouTubeUrl(video.youtubeUrl),
                      icon: Icon(
                        Icons.open_in_new,
                        size: AppResponsive.fontSize(context, 14),
                      ),
                      label: Text(
                        'youtube'.tr(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[700]
                            : Colors.red[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 8)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red[700]!.withValues(alpha: 0.3)
                                : Colors.red[200]!.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    // Pre-build static parts outside AnimatedBuilder
    final icon = Icon(
      Icons.refresh,
      size: AppResponsive.fontSize(context, 24),
    );

    final labelText = Text(
      'refresh'.tr(),
      style: TextStyle(
        fontSize: AppResponsive.fontSize(context, 14),
      ),
    );

    return AnimatedBuilder(
      animation: _fabAnimation,
      child: labelText, // Pass static text as child
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            context.read<LiveVideoBloc>().add(RefreshLiveVideosEvent());
          },
          backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
          foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
          icon: icon,
          label: SizeTransition(
            sizeFactor: _fabAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0,
            child: Padding(
              padding: EdgeInsets.only(
                left: 8.0 * _fabAnimation.value,
              ),
              child: child, // Use pre-built child
            ),
          ),
          extendedPadding: EdgeInsets.symmetric(
            horizontal: 12.0 + (4.0 * _fabAnimation.value),
          ),
          extendedIconLabelSpacing: 0.0,
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // Show 3 shimmer placeholders
      itemBuilder: (context, index) {
        return _buildShimmerCard(theme);
      },
    );
  }

  Widget _buildShimmerCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 8),
      elevation: theme.brightness == Brightness.dark ? 3.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 8)),
        side: BorderSide(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.08),
          width: isDark ? 0.8 : 0.3,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppResponsive.spacing(context, 8)),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),

            // Content placeholder
            Padding(
              padding:
                  AppResponsive.padding(context, horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: AppResponsive.spacing(context, 45),
                        color: Colors.white,
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title lines
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: AppResponsive.spacing(context, 8)),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: AppResponsive.spacing(context, 8)),
                            // Date placeholder
                            Container(
                              width: 100,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 10)),
                  // Description lines
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 6)),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 12)),
                  // Bottom row with status and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
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
            'failed_load_videos'.tr(),
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontSize: AppResponsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<LiveVideoBloc>().add(LoadLiveVideosEvent()),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            size: AppResponsive.fontSize(context, 48),
          ),
          const SizedBox(height: 16),
          Text(
            'no_videos_available'.tr(),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: AppResponsive.fontSize(context, 16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
