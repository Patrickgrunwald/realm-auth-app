import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../post/models/post_model.dart';
import '../../post/widgets/ea_badge.dart';
import '../../../core/theme/app_colors.dart';
import 'interaction_bar.dart';

/// Video post card with auto-play, mute toggle, and chewie player.
class VideoPostCard extends StatefulWidget {
  final PostModel post;
  final bool autoPlay;

  const VideoPostCard({
    super.key,
    required this.post,
    this.autoPlay = true,
  });

  @override
  State<VideoPostCard> createState() => _VideoPostCardState();
}

class _VideoPostCardState extends State<VideoPostCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isMuted = true;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final url = Uri.parse(widget.post.mediaUrl);
      _videoController = VideoPlayerController.networkUrl(url);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.autoPlay,
        looping: true,
        startAt: Duration.zero,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
      );

      await _videoController!.setVolume(_isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('[VideoPostCard] init error for ${widget.post.id}: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${widget.post.id}', extra: widget.post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EA Banner
          EaBadge(post: widget.post),

          // Header
          _VideoHeader(post: widget.post),

          // Video player
          _buildVideoArea(),

          // Interaction bar
          InteractionBar(
            post: widget.post,
            onCommentTap: () =>
                context.push('/post/${widget.post.id}', extra: widget.post),
          ),

          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.divider,
          ),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            _VideoCaption(post: widget.post),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_hasError) {
      return _thumbnail(showError: true);
    }

    if (!_isInitialized) {
      return _thumbnail();
    }

    final aspectRatio = _videoController!.value.aspectRatio;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Video
        GestureDetector(
          onTap: _togglePlayPause,
          child: AspectRatio(
            aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),
        ),

        // Play/Pause overlay (shown briefly)
        if (_videoController != null && !_videoController!.value.isPlaying)
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
            ),
          ),

        // Mute button (bottom-right)
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnail({bool showError = false}) {
    if (widget.post.thumbnailUrl != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: widget.post.thumbnailUrl!,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
          ),
          if (showError)
            const Icon(Icons.error_outline, color: Colors.white54, size: 48)
          else
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
        ],
      );
    }

    return Container(
      height: 260,
      width: double.infinity,
      color: AppColors.surface,
      child: Center(
        child: showError
            ? const Icon(Icons.broken_image_outlined,
                color: AppColors.textDisabled, size: 48)
            : const CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VideoHeader extends StatelessWidget {
  final PostModel post;
  const _VideoHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final timeText = timeago.format(post.createdAt, locale: 'de');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surface,
            backgroundImage: post.avatarUrl != null
                ? CachedNetworkImageProvider(post.avatarUrl!)
                : null,
            child: post.avatarUrl == null
                ? Text(
                    (post.username ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.displayName ?? post.username ?? 'Unbekannt',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.videocam_outlined,
                        color: AppColors.accent, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Video · $timeText',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => debugPrint('[VideoPostCard] menu: ${post.id}'),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VideoCaption extends StatelessWidget {
  final PostModel post;
  const _VideoCaption({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${post.username ?? ''} ',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: post.caption ?? '',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
