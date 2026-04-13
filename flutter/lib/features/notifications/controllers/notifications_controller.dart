import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';

@immutable
class NotificationItem {
  final String id;
  final String type; // like, follow, comment, ea_report
  final String? message;
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? targetPostId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    this.message,
    this.actorId,
    this.actorUsername,
    this.actorAvatarUrl,
    this.targetPostId,
    required this.createdAt,
    this.isRead = false,
  });

  // Convenience getter for screen compatibility
  String get actorName => actorUsername ?? 'Jemand';
  bool get read => isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        message: message,
        actorId: actorId,
        actorUsername: actorUsername,
        actorAvatarUrl: actorAvatarUrl,
        targetPostId: targetPostId,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationsState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(notifications: [], isLoading: false);
        return;
      }

      final data = await SupabaseService.client
          .from(AppConstants.notificationsTable)
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      state = state.copyWith(
        notifications: data.map((raw) {
          return NotificationItem(
            id: raw['id'] as String,
            type: raw['type'] as String,
            message: raw['message'] as String?,
            actorId: raw['actor_id'] as String?,
            actorUsername: raw['actor_username'] as String?,
            actorAvatarUrl: raw['actor_avatar_url'] as String?,
            targetPostId: raw['target_post_id'] as String?,
            createdAt: DateTime.parse(raw['created_at'] as String),
            isRead: raw['is_read'] as bool? ?? false,
          );
        }).toList(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[NotificationsController] load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      return n.id == notificationId ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);

    try {
      await SupabaseService.client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('[NotificationsController] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic update
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    try {
      await SupabaseService.client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('[NotificationsController] markAllAsRead error: $e');
    }
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});