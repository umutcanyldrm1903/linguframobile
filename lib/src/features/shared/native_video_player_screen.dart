import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';

class NativeVideoPlayerScreen extends StatefulWidget {
  const NativeVideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.onOpenExternally,
  });

  final String title;
  final String videoUrl;
  final Future<void> Function() onOpenExternally;

  @override
  State<NativeVideoPlayerScreen> createState() => _NativeVideoPlayerScreenState();
}

class _NativeVideoPlayerScreenState extends State<NativeVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(_handleControllerUpdate);
    _initializeFuture = _controller.initialize().then((_) {
      _controller.setLooping(false);
    });
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }
    await _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: widget.onOpenExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: AppStrings.t('Open Externally'),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _VideoErrorState(onOpenExternally: widget.onOpenExternally);
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: Colors.black,
                            child: VideoPlayer(_controller),
                          ),
                          IconButton.filled(
                            onPressed: _togglePlayback,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.55),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(68, 68),
                            ),
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.brand,
                        bufferedColor: Color(0xFFCBD5E1),
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                    ),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            AppStrings.t(
                              _controller.value.isPlaying ? 'Pause' : 'Play',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: widget.onOpenExternally,
                          icon: const Icon(Icons.open_in_browser),
                          label: Text(AppStrings.t('Open Externally')),
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
    );
  }
}

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState({required this.onOpenExternally});

  final Future<void> Function() onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 54),
            const SizedBox(height: 12),
            Text(
              AppStrings.t('This video could not be previewed here.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: Text(AppStrings.t('Open Externally')),
            ),
          ],
        ),
      ),
    );
  }
}
