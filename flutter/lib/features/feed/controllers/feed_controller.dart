import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';
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
// Post loading helpers
// ---------------------------------------------------------------------------

/// Build PostModel list from raw rows, merging user data and like status.
List<PostModel> _buildPostModels(List<Map<String, dynamic>> rawPosts,
    Map<String, bool> likedMap) {
  return rawPosts.map((raw) {
    final userMap = raw['users'] as Map<String, dynamic>?;
    return PostModel.fromJson({
      ...Map<String, dynamic>.from(raw),
      'username': userMap?['username'],
      'display_name': userMap?['display_name'],
      'avatar_url': userMap?['avatar_url'],
      'is_liked_by_me': likedMap[raw['id']] ?? false,
    });
  }).toList();
}

/// Load FYP posts (all non-deleted, non-confirmed posts ordered by newest).
Future<List<PostModel>> _loadFypPosts({
  required int limit,
  required int offset,
}) async {
  final client = SupabaseService.client;
  final currentUid = client.auth.currentUser?.id;

  final postsData = await client
      .from(AppConstants.postsTable)
      .select('*, users:user_id(username, display_name, avatar_url)')
      .filter('deleted_at', 'is', 'null')
      .neq('report_status', 'confirmed')
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  if (postsData.isEmpty) return [];

  Map<String, bool> likedMap = {};
  if (currentUid != null) {
    final postIds = postsData.map((p) => p['id'] as String).toList();
    final likesData = await client
        .from(AppConstants.likesTable)
        .select('post_id')
        .eq('user_id', currentUid)
        .inFilter('post_id', postIds);
    likedMap = {for (var l in likesData) l['post_id'] as String: true};
  }

  return _buildPostModels(postsData.cast<Map<String, dynamic>>(), likedMap);
}

/// Load following feed posts.
Future<List<PostModel>> _loadFollowingPosts({
  required int limit,
  required int offset,
}) async {
  final client = SupabaseService.client;
  final currentUid = client.auth.currentUser?.id;
  if (currentUid == null) return [];

  final followsData = await client
      .from(AppConstants.followsTable)
      .select('following_id')
      .eq('follower_id', currentUid);

  final followingIds =
      followsData.map((f) => f['following_id'] as String).toList();
  if (followingIds.isEmpty) return [];

  final postsData = await client
      .from(AppConstants.postsTable)
      .select('*, users:user_id(username, display_name, avatar_url)')
      .inFilter('user_id', followingIds)
      .filter('deleted_at', 'is', 'null')
      .neq('report_status', 'confirmed')
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  if (postsData.isEmpty) return [];

  Map<String, bool> likedMap = {};
  final likesData = await client
      .from(AppConstants.likesTable)
      .select('post_id')
      .eq('user_id', currentUid)
      .inFilter('post_id', postsData.map((p) => p['id'] as String).toList());
  likedMap = {for (var l in likesData) l['post_id'] as String: true};

  return _buildPostModels(postsData.cast<Map<String, dynamic>>(), likedMap);
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
      final offset = refresh ? 0 : state.fypPosts.length;
      final posts = await _loadFypPosts(limit: _pageSize, offset: offset);
      debugPrint('[FeedController] fetchFYPPosts → ${posts.length} posts');
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

    final currentUid = SupabaseService.client.auth.currentUser?.id;
    if (currentUid == null) {
      state = state.copyWith(
        followingPosts: [],
        isLoadingFollowing: false,
        hasMoreFollowing: false,
      );
      return;
    }

    state = state.copyWith(isLoadingFollowing: true, error: null);

    try {
      final offset = refresh ? 0 : state.followingPosts.length;
      final posts = await _loadFollowingPosts(limit: _pageSize, offset: offset);
      debugPrint('[FeedController] fetchFollowingPosts → ${posts.length} posts');
      state = state.copyWith(
        followingPosts: refresh ? posts : [...state.followingPosts, ...posts],
        isLoadingFollowing: false,
        hasMoreFollowing: posts.length >= _pageSize,
      );
    } catch (e) {
      debugPrint('[FeedController] fetchFollowingPosts error: $e');
      state = state.copyWith(
          isLoadingFollowing: false, error: e.toString());
    }
  }

  // --- Pagination ------------------------------------------------------------

  Future<void> loadMoreFYP() async {
    if (!state.hasMoreFyp || state.isLoadingFyp) return;
    debugPrint('[FeedController] loadMoreFYP');
    await fetchFYPPosts();
  }

  Future<void> loadMoreFollowing() async {
    if (!state.hasMoreFollowing || state.isLoadingFollowing) return;
    debugPrint('[FeedController] loadMoreFollowing');
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
    final currentUid = SupabaseService.client.auth.currentUser?.id;
    if (currentUid == null) return;

    // Determine current state and which list has the post
    bool isLiked = false;
    bool inFyp = state.fypPosts.any((p) => p.id == postId);
    bool inFollowing = state.followingPosts.any((p) => p.id == postId);

    if (inFyp) {
      isLiked = state.fypPosts.firstWhere((p) => p.id == postId).isLikedByMe;
    } else if (inFollowing) {
      isLiked = state.followingPosts.firstWhere((p) => p.id == postId).isLikedByMe;
    } else {
      return;
    }

    final newLikedState = !isLiked;

    // Optimistic update
    if (inFyp) {
      final idx = state.fypPosts.indexWhere((p) => p.id == postId);
      final post = state.fypPosts[idx];
      final newList = [...state.fypPosts];
      newList[idx] = post.copyWith(
        isLikedByMe: newLikedState,
        likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      state = state.copyWith(fypPosts: newList);
    }
    if (inFollowing) {
      final idx = state.followingPosts.indexWhere((p) => p.id == postId);
      final post = state.followingPosts[idx];
      final newList = [...state.followingPosts];
      newList[idx] = post.copyWith(
        isLikedByMe: newLikedState,
        likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      state = state.copyWith(followingPosts: newList);
    }

    // Persist to Supabase and refresh count from DB
    try {
      if (newLikedState) {
        await SupabaseService.client.from(AppConstants.likesTable).upsert({
          'user_id': currentUid,
          'post_id': postId,
        });
      } else {
        await SupabaseService.client
            .from(AppConstants.likesTable)
            .delete()
            .eq('user_id', currentUid)
            .eq('post_id', postId);
      }
      // Refresh count from DB (DB trigger maintains likes_count on posts table)
      await _refreshLikeCount(postId);
    } catch (e) {
      debugPrint('[FeedController] toggleLike persist error: $e');
    }
  }

  Future<void> _refreshLikeCount(String postId) async {
    try {
      final data = await SupabaseService.client
          .from(AppConstants.postsTable)
          .select('likes_count')
          .eq('id', postId)
          .maybeSingle();
      if (data == null) return;
      final dbCount = data['likes_count'] as int? ?? 0;

      List<PostModel>? newFyp;
      List<PostModel>? newFollowing;

      final fypIdx = state.fypPosts.indexWhere((p) => p.id == postId);
      if (fypIdx != -1) {
        final post = state.fypPosts[fypIdx];
        final updated = [...state.fypPosts];
        updated[fypIdx] = post.copyWith(likesCount: dbCount);
        newFyp = updated;
      }

      final followingIdx = state.followingPosts.indexWhere((p) => p.id == postId);
      if (followingIdx != -1) {
        final post = state.followingPosts[followingIdx];
        final updated = [...state.followingPosts];
        updated[followingIdx] = post.copyWith(likesCount: dbCount);
        newFollowing = updated;
      }

      if (newFyp != null || newFollowing != null) {
        state = state.copyWith(
          fypPosts: newFyp ?? state.fypPosts,
          followingPosts: newFollowing ?? state.followingPosts,
        );
      }
    } catch (_) {
      // Silently fail — count will be correct on next refresh
    }
  }

  // --- Share -----------------------------------------------------------------

  void sharePost(String postId) {
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
