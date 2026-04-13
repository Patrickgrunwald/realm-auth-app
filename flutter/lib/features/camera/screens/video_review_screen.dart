import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../post/screens/create_post_screen.dart';

class VideoReviewScreen extends StatefulWidget {
  final String filePath;

  const VideoReviewScreen({super.key, required this.filePath});

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final isWebBlob = kIsWeb && widget.filePath.startsWith('blob:');
    if (isWebBlob) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.filePath));
    } else {
      _controller = VideoPlayerController.file(File(widget.filePath));
    }
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.setLooping(true);
        _controller.play();
      }
    });
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final isPlaying = _controller.value.isPlaying;
    if ((isPlaying && _showPlayIcon) || (!isPlaying && !_showPlayIcon)) {
      setState(() => _showPlayIcon = !isPlaying);
    }
  }

  bool _showPlayIcon = false;

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _goToCreatePost() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          mediaPath: widget.filePath,
          mediaType: 'video',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video
          if (_initialized)
            GestureDetector(
              onTap: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Video wird geladen...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),

          // Play-Icon Overlay
          if (_initialized && _showPlayIcon)
            Center(
              child: GestureDetector(
                onTap: () => _controller.play(),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 56),
                ),
              ),
            ),

          // Obere Leiste
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + 60,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xDD000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Beitrag erstellen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Untere Leiste
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xDD000000)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                        label: const Text('Erneut', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      ),
                      _weiterButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weiterButton() {
    return ElevatedButton(
      onPressed: _goToCreatePost,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        minimumSize: const Size(120, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Weiter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }
}