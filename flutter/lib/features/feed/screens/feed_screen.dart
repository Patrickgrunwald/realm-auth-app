import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_tab_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/video_post_card.dart';
import '../../post/models/post_model.dart';
import '../../camera/screens/camera_screen.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Realm Auth',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              debugPrint('[FeedScreen] Suche — noch nicht implementiert');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suche — noch nicht implementiert'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          bottom: const FeedTabBar(),
        ),
        body: const TabBarView(
          children: [
            _FeedTab(feedType: _FeedType.fyp),
            _FeedTab(feedType: _FeedType.following),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          ),
          backgroundColor: const Color(0xFF6C63FF),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

enum _FeedType { fyp, following }

class _FeedTab extends ConsumerStatefulWidget {
  final _FeedType feedType;

  const _FeedTab({required this.feedType});

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const threshold = 200.0;

    if (currentScroll >= maxScroll - threshold) {
      final notifier = ref.read(feedControllerProvider.notifier);
      if (widget.feedType == _FeedType.fyp) {
        notifier.loadMoreFYP();
      } else {
        notifier.loadMoreFollowing();
      }
    }
  }

  Future<void> _onRefresh() async {
    final notifier = ref.read(feedControllerProvider.notifier);
    if (widget.feedType == _FeedType.fyp) {
      await notifier.refreshFYP();
    } else {
      await notifier.refreshFollowing();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feedState = ref.watch(feedControllerProvider);

    final posts = widget.feedType == _FeedType.fyp
        ? feedState.fypPosts
        : feedState.followingPosts;

    final isLoading = widget.feedType == _FeedType.fyp
        ? feedState.isLoadingFyp
        : feedState.isLoadingFollowing;

    final hasMore = widget.feedType == _FeedType.fyp
        ? feedState.hasMoreFyp
        : feedState.hasMoreFollowing;

    // Initial loading
    if (isLoading && posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    // Error
    if (feedState.error != null && posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onRefresh,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    // Empty following
    if (posts.isEmpty && widget.feedType == _FeedType.following) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline,
                color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(
              'Folge anderen Nutzern,\num ihren Feed zu sehen.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final post = posts[index];
          return _buildPostItem(post);
        },
      ),
    );
  }

  Widget _buildPostItem(PostModel post) {
    if (post.type == 'video') {
      return VideoPostCard(post: post, autoPlay: false);
    }
    return PostCard(post: post);
  }
}
