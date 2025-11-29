import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ServerVideoPlayer extends StatefulWidget {
  final String url;
  const ServerVideoPlayer({Key? key, required this.url}) : super(key: key);

  @override
  State<ServerVideoPlayer> createState() => _ServerVideoPlayerState();
}

class _ServerVideoPlayerState extends State<ServerVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized)
      return const Center(child: CircularProgressIndicator());
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(_controller),
          Positioned(
            bottom: 8,
            left: 8,
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed:
                  () => setState(
                    () =>
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play(),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
