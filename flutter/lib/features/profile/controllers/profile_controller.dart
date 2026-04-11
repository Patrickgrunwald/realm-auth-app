import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';

class ProfileState {
  final bool isLoading;
  final String? userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
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

    // TODO: Supabase Query
    // final data = await SupabaseService.client
    //   .from('users').select().eq('id', userId).single();

    // Mock data for now
    state = ProfileState(
      isLoading: false,
      userId: userId,
      username: 'user_${userId.substring(0, 6)}',
      displayName: 'Benutzer',
      avatarUrl: null,
      bio: 'Realm Auth Nutzer',
      postsCount: 0,
      followersCount: 0,
      followingCount: 0,
      isFollowing: false,
      isCurrentUser: isCurrentUser,
    );
  }

  Future<void> toggleFollow() async {
    if (state.isCurrentUser) return;

    final wasFollowing = state.isFollowing;
    state = state.copyWith(
      isFollowing: !wasFollowing,
      followersCount: wasFollowing
          ? state.followersCount - 1
          : state.followersCount + 1,
    );

    // TODO: Supabase upsert/delete follow
    // if (wasFollowing) {
    //   await SupabaseService.client
    //     .from('follows').delete()
    //     .eq('follower_id', currentUserId)
    //     .eq('following_id', state.userId);
    // } else {
    //   await SupabaseService.client
    //     .from('follows').insert(...)
    // }
  }

  Future<void> updateBio(String newBio) async {
    final previousBio = state.bio;
    state = state.copyWith(bio: newBio);

    // TODO: Supabase update
    // await SupabaseService.client
    //   .from('users').update({'bio': newBio}).eq('id', state.userId);
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
