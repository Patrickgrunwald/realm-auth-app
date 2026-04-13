import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import '../../post/models/post_model.dart';
import '../../post/widgets/ea_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';
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

  // Real comments from Supabase
  List<CommentItem> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == 'video') {
      _initVideo();
    }
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await SupabaseService.client
          .from(AppConstants.commentsTable)
          .select('*, users:user_id(id, username, display_name, avatar_url)')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);

      setState(() {
        _comments = data.map((raw) {
          final user = raw['users'] as Map<String, dynamic>?;
          return CommentItem(
            id: raw['id'] as String,
            userId: raw['user_id'] as String,
            username: user?['username'] as String? ?? 'unknown',
            displayName: user?['display_name'] as String? ?? '',
            avatarUrl: user?['avatar_url'] as String?,
            content: raw['content'] as String,
            createdAt: DateTime.parse(raw['created_at'] as String),
          );
        }).toList();
        _isLoadingComments = false;
      });
    } catch (e) {
      debugPrint('[PostDetail] loadComments error: $e');
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isPostingComment = true);
    try {
      final result = await SupabaseService.client
          .from(AppConstants.commentsTable)
          .insert({
            'post_id': widget.post.id,
            'user_id': user.id,
            'content': text,
          })
          .select('*, users:user_id(id, username, display_name, avatar_url)')
          .single();

      final userData = result['users'] as Map<String, dynamic>?;
      final newComment = CommentItem(
        id: result['id'] as String,
        userId: result['user_id'] as String,
        username: userData?['username'] as String? ?? 'unknown',
        displayName: userData?['display_name'] as String? ?? '',
        avatarUrl: userData?['avatar_url'] as String?,
        content: result['content'] as String,
        createdAt: DateTime.parse(result['created_at'] as String),
      );

      setState(() {
        _comments = [..._comments, newComment];
        _commentController.clear();
        _isPostingComment = false;
      });
    } catch (e) {
      debugPrint('[PostDetail] postComment error: $e');
      setState(() => _isPostingComment = false);
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

                  // Loading or comments list
                  if (_isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    )
                  else
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
            onSubmit: _postComment,
            isPosting: _isPostingComment,
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
      placeholder: (context, url) => Container(
        height: 300,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      errorWidget: (context, exception, stackTrace) => Container(
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
  final CommentItem comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: comment.avatarUrl != null
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: Text(
              comment.username.isNotEmpty
                  ? comment.username[0].toUpperCase()
                  : '?',
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
                        text: comment.content,
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
                  timeago.format(comment.createdAt, locale: 'de'),
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
  final bool isPosting;

  const _CommentInput({
    required this.controller,
    required this.onSubmit,
    this.isPosting = false,
  });

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
            onTap: isPosting ? null : onSubmit,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPosting ? AppColors.textDisabled : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Real comment model (replaces _MockComment)
class CommentItem {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
