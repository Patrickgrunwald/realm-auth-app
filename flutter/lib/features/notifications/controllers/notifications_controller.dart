import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String type;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final String? postId;
  final bool read;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    this.postId,
    this.read = false,
    required this.createdAt,
  });
}

class NotificationsState {
  final bool isLoading;
  final List<NotificationItem> notifications;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationItem>? notifications,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    // TODO: Supabase laden
    // final data = await SupabaseService.client
    //   .from('notifications')
    //   .select('*, actor:users(*)')
    //   .eq('user_id', auth.uid())
    //   .order('created_at', ascending: false)
    //   .limit(50);

    // Mock-Daten für jetzt
    await Future.delayed(const Duration(milliseconds: 500));

    state = NotificationsState(
      isLoading: false,
      notifications: [],
    );
  }

  Future<void> markAsRead(String id) async {
    // TODO: Supabase update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return NotificationItem(
            id: n.id,
            type: n.type,
            actorId: n.actorId,
            actorName: n.actorName,
            actorAvatar: n.actorAvatar,
            postId: n.postId,
            read: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList(),
    );
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
