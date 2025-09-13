import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/data/models/live_video_screen/live_video_model.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_bloc.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_event.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_state.dart';
import 'package:lotto_app/presentation/pages/live_video_screen/widgets/video_player_widget.dart';
import 'package:lotto_app/presentation/widgets/native_ad_video_widget.dart';
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
  bool _isScrollingDown = false;
  bool _isVideoPlaying = false;
  String? _currentPlayingVideoId;

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
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        if (_isExpanded) {
          setState(() {
            _isExpanded = false;
          });
          _fabAnimationController.reverse();
        }
      }
    } else if (direction == ScrollDirection.forward) {
      // Scrolling up - expand FAB
      if (_isScrollingDown) {
        _isScrollingDown = false;
        if (!_isExpanded) {
          setState(() {
            _isExpanded = true;
          });
          _fabAnimationController.forward();
        }
      }
    }
  }

  /// Handle app lifecycle changes (following home screen pattern)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // Video pausing is handled by the YouTube player automatically
        break;
      case AppLifecycleState.resumed:
        // Optionally resume video when app comes back
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
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

  /// Play video in app when card is tapped
  Future<void> _playVideo(LiveVideoModel video) async {
    try {
      setState(() {
        _currentPlayingVideoId = video.youtubeVideoId;
        _isVideoPlaying = true;
      });

      // Extract video ID from YouTube URL
      final extractedVideoId =
          YoutubePlayerController.convertUrlToId(video.youtubeUrl);

      if (extractedVideoId != null) {
        // Navigate to video player screen
        if (mounted) {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerWidget(
                videoId: extractedVideoId,
                videoTitle: video.formattedTitle,
                onClose: () {
                  setState(() {
                    _isVideoPlaying = false;
                    _currentPlayingVideoId = null;
                  });
                },
              ),
            ),
          )
              .then((_) {
            // Reset state when returning from video player
            setState(() {
              _isVideoPlaying = false;
              _currentPlayingVideoId = null;
            });
          });
        }
      } else {
        // Fallback to opening in browser
        await _launchYouTubeUrl(video.youtubeUrl);
      }
    } catch (e) {
      _showErrorSnackBar('error_playing_video'.tr());
      setState(() {
        _isVideoPlaying = false;
        _currentPlayingVideoId = null;
      });
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

    List<Widget> videoWidgets = [];
    bool isFirstVideo = true;
    
    for (int i = 0; i < videos.length; i++) {
      // Add video card
      videoWidgets.add(_buildVideoCard(videos[i], theme));
      
      bool shouldInsertAd = false;
      
      // For the first video, show ad after it
      if (isFirstVideo) {
        shouldInsertAd = true;
        isFirstVideo = false;
      }
      // For subsequent videos, show ad after every 5th video (following home screen pattern)
      else if ((i + 1) % 5 == 0) {
        shouldInsertAd = true;
      }
      
      // Insert ad if conditions are met and not after the last video
      if (shouldInsertAd && i < videos.length - 1) {
        videoWidgets.add(const NativeAdVideoWidget());
      }
    }

    return Column(
      children: videoWidgets,
    );
  }

  Widget _buildVideoCard(LiveVideoModel video, ThemeData theme) {
    final isCurrentlyPlaying =
        _currentPlayingVideoId == video.youtubeVideoId && _isVideoPlaying;

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
            onTap: () => _playVideo(video),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppResponsive.spacing(context, 8)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
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
                          isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
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
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            context.read<LiveVideoBloc>().add(RefreshLiveVideosEvent());
          },
          backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
          foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
          icon: Icon(
            Icons.refresh,
            size: AppResponsive.fontSize(context, 24),
          ),
          label: SizeTransition(
            sizeFactor: _fabAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0,
            child: Padding(
              padding: EdgeInsets.only(
                left: 8.0 * _fabAnimation.value,
              ),
              child: Text(
                'refresh'.tr(),
                style: TextStyle(
                  fontSize: AppResponsive.fontSize(context, 14),
                ),
              ),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Beautiful animated loading indicator
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Loading text with better styling
            Text(
              'loading_videos'.tr(),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: AppResponsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
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
