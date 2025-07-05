import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:lotto_app/presentation/widgets/video_player_widget.dart';

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
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  String? _currentPlayingVideoId;

  // Dummy video data following the home screen pattern
  final List<Map<String, dynamic>> _videoData = [
    {
      'id': 'a7N43fKZ7s8',
      'url': 'https://youtu.be/a7N43fKZ7s8?si=M_U8HB7e0WHB6cIU',
      'title': 'Kerala Lottery Result Today',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'thumbnail': 'https://img.youtube.com/vi/a7N43fKZ7s8/maxresdefault.jpg',
    },
    {
      'id': 'SEbrjBwAfG8',
      'url': 'https://youtu.be/SEbrjBwAfG8?si=VqcvafSQm5OQrup6',
      'title': 'Win Win Lottery Draw',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'thumbnail': 'https://img.youtube.com/vi/SEbrjBwAfG8/maxresdefault.jpg',
    },
    {
      'id': 'Hn_2_tN2UBs',
      'url': 'https://youtu.be/Hn_2_tN2UBs?si=3knFueCmlrqG_EeG',
      'title': 'Akshaya Lottery Result',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'thumbnail': 'https://img.youtube.com/vi/Hn_2_tN2UBs/maxresdefault.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes (following home screen pattern)
    WidgetsBinding.instance.addObserver(this);

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
    _videoController?.dispose();
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
        // Pause video when app goes to background
        if (_videoController?.value.isPlaying == true) {
          _videoController?.pause();
        }
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
  Future<void> _playVideo(String videoId, String youtubeUrl) async {
    try {
      // Stop current video if playing
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }

      setState(() {
        _currentPlayingVideoId = videoId;
        _isVideoPlaying = true;
      });

      // Extract video ID from YouTube URL
      final extractedVideoId = YoutubePlayer.convertUrlToId(youtubeUrl);
      
      if (extractedVideoId != null) {
        // Navigate to video player screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerWidget(
              videoId: extractedVideoId,
              videoTitle: _videoData.firstWhere(
                (video) => video['id'] == videoId,
                orElse: () => {'title': 'Lottery Result Video'},
              )['title'],
              onClose: () {
                setState(() {
                  _isVideoPlaying = false;
                  _currentPlayingVideoId = null;
                });
              },
            ),
          ),
        ).then((_) {
          // Reset state when returning from video player
          setState(() {
            _isVideoPlaying = false;
            _currentPlayingVideoId = null;
          });
        });
      } else {
        // Fallback to opening in browser
        await _launchYouTubeUrl(youtubeUrl);
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // SizedBox(height: AppResponsive.spacing(context, 16)),
              _buildVideosList(theme),
              SizedBox(height: AppResponsive.spacing(context, 100)),
            ],
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
        style: TextStyle(
          fontSize: AppResponsive.fontSize(context, 20),
          fontWeight: FontWeight.bold,
          color: theme.appBarTheme.titleTextStyle?.color,
        ),
      ),
    );
  }

  Widget _buildVideosList(ThemeData theme) {
    return Column(
      children:
          _videoData.map((video) => _buildVideoCard(video, theme)).toList(),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, ThemeData theme) {
    final isCurrentlyPlaying =
        _currentPlayingVideoId == video['id'] && _isVideoPlaying;

    return Card(
      color: theme.cardTheme.color,
      margin: AppResponsive.margin(context, horizontal: 16, vertical: 5),
      elevation: theme.brightness == Brightness.dark ? 4.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 12)),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          width: theme.brightness == Brightness.dark ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail section
          GestureDetector(
            onTap: () => _playVideo(video['id'], video['url']),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppResponsive.spacing(context, 12)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video['thumbnail'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.video_library,
                              size: AppResponsive.fontSize(context, 60),
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
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.vertical(
                        top:
                            Radius.circular(AppResponsive.spacing(context, 5)),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: AppResponsive.padding(context,
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: AppResponsive.fontSize(context, 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video details section
          Padding(
            padding:
                AppResponsive.padding(context, horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with accent line (following home screen pattern)
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
                        video['title'],
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchYouTubeUrl(video['url']),
                      icon: Icon(
                        Icons.open_in_new,
                        size: AppResponsive.fontSize(context, 16),
                      ),
                      label: Text(
                        'youtube'.tr(),
                        style: TextStyle(
                          fontSize: AppResponsive.fontSize(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? Colors.red[50]
                            : Colors.red[900],
                        foregroundColor: theme.brightness == Brightness.light
                            ? Colors.red[800]
                            : Colors.red[100],
                        padding: AppResponsive.padding(context,
                            horizontal: 12, vertical: 12),
                        elevation:
                            theme.brightness == Brightness.dark ? 2.0 : 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppResponsive.spacing(context, 8)),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? Colors.red[700]!
                                : Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Date section
                Text(
                  _formatDateForDisplay(video['date']),
                  style: TextStyle(
                    fontSize: AppResponsive.fontSize(context, 14),
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
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
            // Refresh video list
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('videos_refreshed'.tr()),
                backgroundColor: Colors.green,
              ),
            );
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
}
