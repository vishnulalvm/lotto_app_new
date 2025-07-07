import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
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
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
          enableCaption: true,
          captionLanguage: 'en',
          showVideoAnnotations: false,
          enableJavaScript: true,
        ),
      );

      // Set player as ready after initialization
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isPlayerReady = true;
            _hasError = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'error_playing_video'.tr();
      });
    }
  }


  @override
  void dispose() {
    _youtubeController.close();
    
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Full screen handling is managed by the YouTube player
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
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
                  Expanded(
                    child: YoutubePlayer(
                      controller: _youtubeController,
                    ),
                  ),
                if (_isPlayerReady && !_hasError)
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
                            const Icon(
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
            ),
          ),
        ),
      ),
    );
  }
}