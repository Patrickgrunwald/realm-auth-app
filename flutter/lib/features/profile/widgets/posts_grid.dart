import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../post/models/post_model.dart';

class PostsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final Function(PostModel) onPostTap;

  const PostsGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Noch keine Beiträge',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nimm ein Foto oder Video auf!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final post = posts[i];
        return GestureDetector(
          onTap: () => onPostTap(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Post-Thumbnail
              if (post.mediaUrl.isNotEmpty)
                Image.network(
                  post.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, exception, stackTrace) => Container(
                    color: AppColors.surface,
                  ),
                )
              else
                Container(color: AppColors.surface),

              // Video-Icon
              if (post.type == 'video')
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),

              // EA-Badge
              if (post.isEaContent)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.eaAmber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.black87,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
