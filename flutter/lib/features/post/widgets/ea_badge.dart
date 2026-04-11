import 'package:flutter/material.dart';
import '../../post/models/post_model.dart';
import '../../../core/theme/app_colors.dart';

/// Yellow banner shown above a post that has been flagged as AI-generated.
/// Only rendered when [post.reportStatus] != 'none'.
class EaBadge extends StatelessWidget {
  final PostModel post;

  const EaBadge({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.reportStatus == 'none') return const SizedBox.shrink();

    final label = _label(post.reportStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.eaAmber,
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.black87, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'confirmed':
        return '🧠 KI-generiert — Dieser Inhalt wurde als KI-generiert bestätigt';
      case 'pending':
        return '🧠 KI-gemeldet — Dieser Inhalt wurde als KI-generiert gemeldet';
      case 'rejected':
        return '✅ Geprüft — KI-Verdacht wurde abgelehnt';
      default:
        return '🧠 Dieser Inhalt wurde als KI-generiert gemeldet';
    }
  }
}
