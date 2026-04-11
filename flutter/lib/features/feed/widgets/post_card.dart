import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../post/models/post_model.dart';
import '../../post/widgets/ea_badge.dart';
import '../../../core/theme/app_colors.dart';
import 'interaction_bar.dart';

/// Photo post card. Shown in the feed list.
class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}', extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EA Banner
          EaBadge(post: post),

          // Header: avatar + name + time + menu
          _PostHeader(post: post),

          // Full-width photo
          _PostImage(mediaUrl: post.mediaUrl),

          // Interaction bar
          InteractionBar(
            post: post,
            onCommentTap: () => context.push('/post/${post.id}', extra: post),
          ),

          // Divider
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.divider,
          ),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            _PostCaption(post: post),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PostHeader extends StatelessWidget {
  final PostModel post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final timeText = timeago.format(post.createdAt, locale: 'de');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              debugPrint('[PostCard] tap avatar — user profile not yet implemented');
            },
            child: CircleAvatar(
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
          ),
          const SizedBox(width: 10),

          // Username + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    debugPrint('[PostCard] tap username — user profile not yet implemented');
                  },
                  child: Text(
                    post.displayName ?? post.username ?? 'Unbekannt',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Menu
          GestureDetector(
            onTap: () => _showPostMenu(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.textPrimary),
              title: const Text('Melden', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                debugPrint('[PostCard] Melden: ${post.id}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemeldet — noch nicht implementiert')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share, color: AppColors.textPrimary),
              title: const Text('Teilen', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                debugPrint('[PostCard] Teilen: ${post.id}');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PostImage extends StatelessWidget {
  final String mediaUrl;
  const _PostImage({required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: mediaUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceVariant,
        child: Container(
          height: 300,
          width: double.infinity,
          color: AppColors.surface,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 300,
        width: double.infinity,
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

class _PostCaption extends StatefulWidget {
  final PostModel post;
  const _PostCaption({required this.post});

  @override
  State<_PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<_PostCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final caption = widget.post.caption ?? '';
    final username = widget.post.username ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$username ',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: caption,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
