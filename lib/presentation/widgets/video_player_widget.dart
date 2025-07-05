import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final VoidCallback? onClose;

  const VideoPlayerWidget({
    super.key,
    required this.videoId,
    required this.videoTitle,
    this.onClose,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late YoutubePlayerController _youtubeController;
  bool _isFullScreen = false;
  bool _isPlayerReady = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          captionLanguage: 'en',
          controlsVisibleAtStart: true,
          showLiveFullscreenButton: true,
        ),
      );

      _youtubeController.addListener(() {
        if (_youtubeController.value.isReady && !_isPlayerReady) {
          setState(() {
            _isPlayerReady = true;
            _hasError = false;
          });
        }

        if (_youtubeController.value.hasError && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = 'error_playing_video'.tr();
          });
        }

        if (_youtubeController.value.isFullScreen != _isFullScreen) {
          setState(() {
            _isFullScreen = _youtubeController.value.isFullScreen;
          });
          
          if (_isFullScreen) {
            _enterFullScreen();
          } else {
            _exitFullScreen();
          }
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'error_playing_video'.tr();
      });
    }
  }

  void _enterFullScreen() {
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Hide status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  void _exitFullScreen() {
    // Allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Show system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: SystemUiOverlay.values);
    
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    
    // Ensure we restore normal orientation when widget is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: SystemUiOverlay.values);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) async {
        if (!didPop && _isFullScreen) {
          _youtubeController.toggleFullScreenMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(
                  widget.videoTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ),
        body: Container(
          color: Colors.black,
          child: Center(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
                onReady: () {
                  setState(() {
                    _isPlayerReady = true;
                  });
                },
                onEnded: (data) {
                  // Auto exit fullscreen when video ends
                  if (_isFullScreen) {
                    _youtubeController.toggleFullScreenMode();
                  }
                },
              ),
              builder: (context, player) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_hasError)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _isPlayerReady = false;
                                });
                                _initializePlayer();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('retry'.tr()),
                            ),
                          ],
                        ),
                      )
                    else if (!_isPlayerReady)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'loading'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      player,
                    if (!_isFullScreen && _isPlayerReady && !_hasError)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.videoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lottery Result Video',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}