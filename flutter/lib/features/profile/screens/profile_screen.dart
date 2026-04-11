import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../controllers/profile_controller.dart';
import '../widgets/stats_row.dart';
import '../widgets/posts_grid.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null = eigenes Profil

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final userId = widget.userId ??
        SupabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      ref.read(profileControllerProvider.notifier).loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          state.username != null ? '@${state.username}' : 'Profil',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (state.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.textPrimary),
              onPressed: () {
                debugPrint('[ProfileScreen] Einstellungen — noch nicht implementiert');
              },
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Avatar
                    _AvatarWidget(
                      avatarUrl: state.avatarUrl,
                      isCurrentUser: state.isCurrentUser,
                      onTap: state.isCurrentUser ? () {
                        debugPrint('[Profile] Avatar ändern — Kamera öffnen');
                      } : null,
                    ),

                    const SizedBox(height: 12),

                    // Display Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        state.displayName ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Bio
                    if (state.bio != null && state.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state.bio!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Stats
                    StatsRow(
                      postsCount: state.postsCount,
                      followersCount: state.followersCount,
                      followingCount: state.followingCount,
                      onFollowersTap: () {
                        debugPrint('[Profile] Follower-Liste');
                      },
                      onFollowingTap: () {
                        debugPrint('[Profile] Following-Liste');
                      },
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: state.isCurrentUser
                          ? OutlinedButton(
                              onPressed: () {
                                debugPrint('[Profile] Profil bearbeiten');
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.textSecondary),
                                minimumSize: const Size.fromHeight(40),
                              ),
                              child: const Text(
                                'Profil bearbeiten',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            )
                          : _FollowButton(
                              isFollowing: state.isFollowing,
                              onTap: () {
                                ref.read(profileControllerProvider.notifier).toggleFollow();
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Posts-Grid
                    PostsGrid(
                      posts: const [], // TODO: Posts laden
                      onPostTap: (post) {
                        debugPrint('[Profile] Post tapped: ${post.id}');
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const _AvatarWidget({
    this.avatarUrl,
    required this.isCurrentUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary, size: 48)
                : null,
          ),
          if (isCurrentUser)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isFollowing) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.textSecondary),
          minimumSize: const Size.fromHeight(40),
        ),
        child: const Text(
          'Entfolgen',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
      ),
      child: const Text('Folgen'),
    );
  }
}
