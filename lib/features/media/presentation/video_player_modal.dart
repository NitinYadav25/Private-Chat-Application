import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class VideoPlayerModal extends StatefulWidget {
  const VideoPlayerModal({
    super.key,
    required this.videoUrl,
    this.title,
  });

  final String videoUrl;
  final String? title;

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  bool get _isLocalFile =>
      widget.videoUrl.startsWith('/') ||
      widget.videoUrl.startsWith('file:') ||
      widget.videoUrl.contains(Platform.pathSeparator);

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (_isLocalFile) {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      await _controller.initialize();
      _controller.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() => _isInitialized = true);
      _controller.play();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(200),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title ?? 'Video Player',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _hasError
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.videoOff, color: AppColors.danger, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Failed to load video.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : !_isInitialized
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Column(
                    children: [
                      // Video display
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_controller),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                  },
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(120),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Player controls bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.black87,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slider(
                              value: _controller.value.position.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, _controller.value.duration.inMilliseconds.toDouble()),
                              min: 0.0,
                              max: _controller.value.duration.inMilliseconds.toDouble(),
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              onChanged: (val) {
                                _controller.seekTo(Duration(milliseconds: val.toInt()));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

