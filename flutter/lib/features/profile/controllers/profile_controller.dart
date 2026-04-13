import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';
import '../../post/models/post_model.dart';

class ProfileState {
  final bool isLoading;
  final String? userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? bioUrl;
  final List<PostModel> posts;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isCurrentUser;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.bioUrl,
    this.posts = const [],
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isCurrentUser = false,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? bioUrl,
    List<PostModel>? posts,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    bool? isCurrentUser,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      bioUrl: bioUrl ?? this.bioUrl,
      posts: posts ?? this.posts,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, userId: userId);

    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    final isCurrentUser = currentUserId == userId;

    try {
      // Load user data
      final data = await SupabaseService.client
          .from(AppConstants.usersTable)
          .select('*')
          .eq('id', userId)
          .single();

      // Load posts
      final postsData = await SupabaseService.client
          .from(AppConstants.postsTable)
          .select('id, media_url, type, caption, created_at')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', 'null')
          .neq('report_status', 'confirmed')
          .order('created_at', ascending: false)
          .limit(20);

      // Check follow status (only if not own profile)
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != userId) {
        final followCheck = await SupabaseService.client
            .from(AppConstants.followsTable)
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();
        isFollowing = followCheck != null;
      }

      state = state.copyWith(
        userId: data['id'] as String,
        username: data['username'] as String? ?? '',
        displayName: data['display_name'] as String? ?? '',
        bio: data['bio'] as String? ?? '',
        avatarUrl: data['avatar_url'] as String?,
        bioUrl: data['bio_url'] as String?,
        posts: postsData.map((p) => PostModel.fromJson(p)).toList(),
        postsCount: data['posts_count'] as int? ?? postsData.length,
        followersCount: data['followers_count'] as int? ?? 0,
        followingCount: data['following_count'] as int? ?? 0,
        isFollowing: isFollowing,
        isCurrentUser: isCurrentUser,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[ProfileController] loadProfile error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFollow() async {
    if (state.userId == null || state.isCurrentUser) return;

    final currentUid = SupabaseService.client.auth.currentUser?.id;
    if (currentUid == null) return;

    final wasFollowing = state.isFollowing;
    state = state.copyWith(
      isFollowing: !wasFollowing,
      followersCount: wasFollowing
          ? state.followersCount - 1
          : state.followersCount + 1,
    );

    try {
      if (wasFollowing) {
        await SupabaseService.client
            .from(AppConstants.followsTable)
            .delete()
            .eq('follower_id', currentUid)
            .eq('following_id', state.userId!);
      } else {
        await SupabaseService.client
            .from(AppConstants.followsTable)
            .insert({
              'follower_id': currentUid,
              'following_id': state.userId!,
            });
      }
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isFollowing: wasFollowing,
        followersCount: wasFollowing
            ? state.followersCount + 1
            : state.followersCount - 1,
      );
      debugPrint('[ProfileController] toggleFollow error: $e');
    }
  }

  Future<void> updateBio(String newBio) async {
    if (state.userId == null) return;

    final previousBio = state.bio;
    state = state.copyWith(bio: newBio);

    try {
      await SupabaseService.client
          .from(AppConstants.usersTable)
          .update({'bio': newBio})
          .eq('id', state.userId!);
    } catch (e) {
      // Revert on error
      state = state.copyWith(bio: previousBio);
      debugPrint('[ProfileController] updateBio error: $e');
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});