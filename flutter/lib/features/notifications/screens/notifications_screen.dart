import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Aktivität',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, color: AppColors.textSecondary, size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'Keine Benachrichtigungen',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationsControllerProvider.notifier).load(),
                  color: AppColors.accent,
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, i) {
                      final n = state.notifications[i];
                      return _NotificationTile(notification: n);
                    },
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'follow':
        return Icons.person_add;
      case 'ea_confirmed':
        return Icons.psychology;
      default:
        return Icons.notifications;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'like':
        return AppColors.like;
      case 'ea_confirmed':
        return AppColors.eaAmber;
      default:
        return AppColors.accent;
    }
  }

  String get _text {
    switch (notification.type) {
      case 'like':
        return '${notification.actorName} hat deinen Beitrag geliked';
      case 'comment':
        return '${notification.actorName} hat kommentiert';
      case 'follow':
        return '${notification.actorName} folgt dir jetzt';
      case 'ea_confirmed':
        return 'Dein Beitrag wurde als KI bestätigt';
      default:
        return 'Neue Benachrichtigung';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.read ? Colors.transparent : AppColors.surface.withValues(alpha: 0.3),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _iconColor.withValues(alpha: 0.2),
          child: Icon(_icon, color: _iconColor, size: 18),
        ),
        title: Text(
          _text,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _timeAgo(notification.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        onTap: () {
          debugPrint('[Notification] tapped: ${notification.id}');
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'jetzt';
  }
}
