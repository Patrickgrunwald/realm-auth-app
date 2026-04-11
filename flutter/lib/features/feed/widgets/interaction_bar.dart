import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../post/models/post_model.dart';
import '../controllers/feed_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Like / Comment / Share row with animated like button.
class InteractionBar extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onCommentTap;

  const InteractionBar({
    super.key,
    required this.post,
    this.onCommentTap,
  });

  @override
  ConsumerState<InteractionBar> createState() => _InteractionBarState();
}

class _InteractionBarState extends ConsumerState<InteractionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _likeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _likeAnim.dispose();
    super.dispose();
  }

  void _onLikeTap() {
    _likeAnim.forward(from: 0);
    ref.read(feedControllerProvider.notifier).toggleLike(widget.post.id);
  }

  void _onShareTap() {
    ref.read(feedControllerProvider.notifier).sharePost(widget.post.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teilen — noch nicht implementiert'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-read post from state so like toggles stay in sync
    final feedState = ref.watch(feedControllerProvider);
    final post = feedState.fypPosts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => feedState.followingPosts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ♥ Like
          GestureDetector(
            onTap: _onLikeTap,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Icon(
                post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.isLikedByMe ? AppColors.like : AppColors.textSecondary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatCount(post.likesCount),
            style: TextStyle(
              color: post.isLikedByMe ? AppColors.like : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 20),

          // 💬 Comment
          GestureDetector(
            onTap: widget.onCommentTap,
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatCount(post.commentsCount),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 20),

          // ↗ Share
          GestureDetector(
            onTap: _onShareTap,
            child: const Icon(
              Icons.ios_share,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatCount(post.sharesCount),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
