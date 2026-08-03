import 'package:flutter/material.dart';
import 'package:popcorn_movie_tracker/core/lifecycle/app_lifecycle_observer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LifecycleTrailerPlayer extends StatefulWidget {
  const LifecycleTrailerPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
  });

  final String videoId;
  final bool autoPlay;

  @override
  State<LifecycleTrailerPlayer> createState() => _LifecycleTrailerPlayerState();
}

class _LifecycleTrailerPlayerState extends State<LifecycleTrailerPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant LifecycleTrailerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId == widget.videoId &&
        oldWidget.autoPlay == widget.autoPlay) {
      return;
    }
    _controller.dispose();
    _controller = _createController(widget.videoId);
  }

  YoutubePlayerController _createController(String videoId) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(autoPlay: widget.autoPlay),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      onPaused: _controller.pause,
      child: YoutubePlayer(controller: _controller),
    );
  }
}
