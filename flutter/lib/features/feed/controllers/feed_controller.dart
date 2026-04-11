import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../post/models/post_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@immutable
class FeedState {
  final List<PostModel> fypPosts;
  final List<PostModel> followingPosts;
  final bool isLoadingFyp;
  final bool isLoadingFollowing;
  final bool hasMoreFyp;
  final bool hasMoreFollowing;
  final String? error;

  const FeedState({
    this.fypPosts = const [],
    this.followingPosts = const [],
    this.isLoadingFyp = false,
    this.isLoadingFollowing = false,
    this.hasMoreFyp = true,
    this.hasMoreFollowing = true,
    this.error,
  });

  FeedState copyWith({
    List<PostModel>? fypPosts,
    List<PostModel>? followingPosts,
    bool? isLoadingFyp,
    bool? isLoadingFollowing,
    bool? hasMoreFyp,
    bool? hasMoreFollowing,
    String? error,
  }) {
    return FeedState(
      fypPosts: fypPosts ?? this.fypPosts,
      followingPosts: followingPosts ?? this.followingPosts,
      isLoadingFyp: isLoadingFyp ?? this.isLoadingFyp,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      hasMoreFyp: hasMoreFyp ?? this.hasMoreFyp,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

List<PostModel> _buildMockPosts() {
  final now = DateTime.now();
  return [
    PostModel(
      id: 'post-001',
      userId: 'user-001',
      type: 'photo',
      mediaUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      caption:
          'Morgens in den Bergen — nichts schlägt das 🌄',
      isEaContent: false,
      reportStatus: 'none',
      likesCount: 1243,
      commentsCount: 48,
      sharesCount: 12,
      createdAt: now.subtract(const Duration(hours: 2)),
      username: 'bergfotograf',
      displayName: 'Max Bergmann',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=96',
      isLikedByMe: false,
    ),
    PostModel(
      id: 'post-002',
      userId: 'user-002',
      type: 'video',
      mediaUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=800',
      caption: 'Dieses Video wurde mit KI erstellt 🤖',
      isEaContent: true,
      isAiConfirmed: true,
      reportStatus: 'confirmed',
      eaReportCount: 15,
      likesCount: 892,
      commentsCount: 103,
      sharesCount: 56,
      createdAt: now.subtract(const Duration(hours: 5)),
      username: 'ai_creator',
      displayName: 'AI Creator',
      avatarUrl:
          'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=96',
      isLikedByMe: true,
    ),
    PostModel(
      id: 'post-003',
      userId: 'user-003',
      type: 'photo',
      mediaUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800',
      caption: 'Neues Sofa — endlich ein gemütliches Wohnzimmer 🛋️ #interior',
      reportStatus: 'none',
      likesCount: 421,
      commentsCount: 19,
      sharesCount: 4,
      createdAt: now.subtract(const Duration(hours: 8)),
      username: 'interior_anna',
      displayName: 'Anna K.',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=96',
      isLikedByMe: false,
    ),
    PostModel(
      id: 'post-004',
      userId: 'user-004',
      type: 'photo',
      mediaUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      caption: 'Street food at its finest 🍜',
      reportStatus: 'pending',
      isEaContent: true,
      eaReportCount: 3,
      likesCount: 2100,
      commentsCount: 77,
      sharesCount: 88,
      createdAt: now.subtract(const Duration(hours: 12)),
      username: 'foodie_paul',
      displayName: 'Paul F.',
      avatarUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=96',
      isLikedByMe: false,
    ),
    PostModel(
      id: 'post-005',
      userId: 'user-005',
      type: 'video',
      mediaUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1518791841217-8f162f1912da?w=800',
      caption: 'Tutorial: Flutter Animation in 60 Sekunden ⚡',
      reportStatus: 'none',
      likesCount: 3412,
      commentsCount: 214,
      sharesCount: 301,
      createdAt: now.subtract(const Duration(hours: 20)),
      username: 'flutter_dev',
      displayName: 'Dev Sara',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=96',
      isLikedByMe: false,
    ),
    PostModel(
      id: 'post-006',
      userId: 'user-006',
      type: 'photo',
      mediaUrl:
          'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=800',
      caption: 'Natur pur 🌿 #wanderlust #nature',
      reportStatus: 'none',
      likesCount: 654,
      commentsCount: 31,
      sharesCount: 7,
      createdAt: now.subtract(const Duration(days: 1)),
      username: 'naturlover',
      displayName: 'Lena Grün',
      avatarUrl:
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=96',
      isLikedByMe: true,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class FeedController extends StateNotifier<FeedState> {
  FeedController() : super(const FeedState()) {
    fetchFYPPosts();
    fetchFollowingPosts();
  }

  static const int _pageSize = 20;

  // --- FYP -------------------------------------------------------------------

  Future<void> fetchFYPPosts({bool refresh = false}) async {
    if (state.isLoadingFyp) return;

    state = state.copyWith(isLoadingFyp: true, error: null);

    try {
      // TODO: replace with real Supabase query from 06_FEED.md
      debugPrint('[FeedController] fetchFYPPosts — using mock data');
      await Future.delayed(const Duration(milliseconds: 600));

      final posts = _buildMockPosts();
      state = state.copyWith(
        fypPosts: refresh ? posts : [...state.fypPosts, ...posts],
        isLoadingFyp: false,
        hasMoreFyp: posts.length >= _pageSize,
      );
    } catch (e) {
      debugPrint('[FeedController] fetchFYPPosts error: $e');
      state = state.copyWith(isLoadingFyp: false, error: e.toString());
    }
  }

  // --- Following -------------------------------------------------------------

  Future<void> fetchFollowingPosts({bool refresh = false}) async {
    if (state.isLoadingFollowing) return;

    state = state.copyWith(isLoadingFollowing: true, error: null);

    try {
      // TODO: replace with real Supabase query from 06_FEED.md
      debugPrint('[FeedController] fetchFollowingPosts — using mock data');
      await Future.delayed(const Duration(milliseconds: 800));

      // Following: subset of mock posts, chronological
      final posts = _buildMockPosts().reversed
          .take(3)
          .toList();
      state = state.copyWith(
        followingPosts: refresh ? posts : [...state.followingPosts, ...posts],
        isLoadingFollowing: false,
        hasMoreFollowing: posts.length >= _pageSize,
      );
    } catch (e) {
      debugPrint('[FeedController] fetchFollowingPosts error: $e');
      state = state.copyWith(isLoadingFollowing: false, error: e.toString());
    }
  }

  // --- Pagination ------------------------------------------------------------

  Future<void> loadMoreFYP() async {
    if (!state.hasMoreFyp || state.isLoadingFyp) return;
    debugPrint('[FeedController] loadMoreFYP — cursor pagination');
    await fetchFYPPosts();
  }

  Future<void> loadMoreFollowing() async {
    if (!state.hasMoreFollowing || state.isLoadingFollowing) return;
    debugPrint('[FeedController] loadMoreFollowing — cursor pagination');
    await fetchFollowingPosts();
  }

  // --- Refresh ---------------------------------------------------------------

  Future<void> refreshFYP() async {
    debugPrint('[FeedController] refreshFYP');
    state = state.copyWith(fypPosts: [], hasMoreFyp: true);
    await fetchFYPPosts(refresh: true);
  }

  Future<void> refreshFollowing() async {
    debugPrint('[FeedController] refreshFollowing');
    state = state.copyWith(followingPosts: [], hasMoreFollowing: true);
    await fetchFollowingPosts(refresh: true);
  }

  // --- Like ------------------------------------------------------------------

  Future<void> toggleLike(String postId) async {
    debugPrint('[FeedController] toggleLike: $postId');

    // Optimistic update in FYP
    final fypIndex = state.fypPosts.indexWhere((p) => p.id == postId);
    if (fypIndex != -1) {
      final post = state.fypPosts[fypIndex];
      final updated = post.copyWith(
        isLikedByMe: !post.isLikedByMe,
        likesCount: post.isLikedByMe
            ? post.likesCount - 1
            : post.likesCount + 1,
      );
      final newList = [...state.fypPosts];
      newList[fypIndex] = updated;
      state = state.copyWith(fypPosts: newList);
    }

    // Optimistic update in Following
    final flwIndex = state.followingPosts.indexWhere((p) => p.id == postId);
    if (flwIndex != -1) {
      final post = state.followingPosts[flwIndex];
      final updated = post.copyWith(
        isLikedByMe: !post.isLikedByMe,
        likesCount: post.isLikedByMe
            ? post.likesCount - 1
            : post.likesCount + 1,
      );
      final newList = [...state.followingPosts];
      newList[flwIndex] = updated;
      state = state.copyWith(followingPosts: newList);
    }

    // TODO: persist to Supabase (likes table upsert / delete)
  }

  // --- Share -----------------------------------------------------------------

  void sharePost(String postId) {
    // TODO: integrate share_plus when added to pubspec
    debugPrint('[FeedController] sharePost: $postId');
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final feedControllerProvider =
    StateNotifierProvider<FeedController, FeedState>(
  (ref) => FeedController(),
);
