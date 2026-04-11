import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../post/models/post_model.dart';
import '../../post/widgets/ea_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/interaction_bar.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;

  // Mock comments
  final List<_MockComment> _comments = [
    _MockComment(
        username: 'user_42',
        text: 'Wunderschön! 😍',
        time: const Duration(minutes: 30)),
    _MockComment(
        username: 'laura_m',
        text: 'Wo wurde das aufgenommen?',
        time: const Duration(hours: 1)),
    _MockComment(
        username: 'bergfan_2024',
        text: 'Mega Foto!',
        time: const Duration(hours: 2)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.post.type == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: true,
        allowFullScreen: true,
      );
      if (mounted) setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('[PostDetailScreen] video init error: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(
          0, _MockComment(username: 'ich', text: text, time: Duration.zero));
    });
    _commentController.clear();
    FocusScope.of(context).unfocus();
    debugPrint('[PostDetailScreen] new comment: $text');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Beitrag',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EA Badge
                  EaBadge(post: widget.post),

                  // Author header
                  _DetailHeader(post: widget.post),

                  // Media
                  _buildMedia(),

                  // Interaction bar
                  InteractionBar(post: widget.post),

                  const Divider(height: 1, thickness: 0.5, color: AppColors.divider),

                  // Caption
                  if (widget.post.caption != null &&
                      widget.post.caption!.isNotEmpty)
                    _DetailCaption(post: widget.post),

                  const SizedBox(height: 16),

                  // Comments header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Kommentare',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Comments list
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _comments.length,
                    itemBuilder: (context, index) =>
                        _CommentTile(comment: _comments[index]),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Comment input
          _CommentInput(
            controller: _commentController,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.post.type == 'video') {
      if (_videoInitialized && _chewieController != null) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio > 0
              ? _videoController!.value.aspectRatio
              : 16 / 9,
          child: Chewie(controller: _chewieController!),
        );
      }
      return Container(
        height: 260,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.post.mediaUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: 300,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 300,
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.textDisabled, size: 48),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DetailHeader extends StatelessWidget {
  final PostModel post;
  const _DetailHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
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
                Text(
                  timeago.format(post.createdAt, locale: 'de'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DetailCaption extends StatelessWidget {
  final PostModel post;
  const _DetailCaption({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CommentTile extends StatelessWidget {
  final _MockComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final timeText = comment.time == Duration.zero
        ? 'Gerade eben'
        : timeago.format(
            DateTime.now().subtract(comment.time),
            locale: 'de',
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              comment.username[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.username} ',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: comment.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CommentInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Kommentieren…',
                hintStyle:
                    const TextStyle(color: AppColors.textDisabled, fontSize: 14),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MockComment {
  final String username;
  final String text;
  final Duration time;
  _MockComment({required this.username, required this.text, required this.time});
}
