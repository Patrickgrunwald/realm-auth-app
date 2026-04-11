import 'package:flutter/foundation.dart';

@immutable
class PostModel {
  final String id;
  final String userId;
  final String type; // 'photo' or 'video'
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final bool isEaContent;
  final bool isAiConfirmed;
  final int eaReportCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final String reportStatus; // none, pending, confirmed, rejected
  final DateTime createdAt;
  // From user join:
  final String? username;
  final String? avatarUrl;
  final String? displayName;
  final bool isLikedByMe;

  const PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.isEaContent = false,
    this.isAiConfirmed = false,
    this.eaReportCount = 0,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    this.reportStatus = 'none',
    required this.createdAt,
    this.username,
    this.avatarUrl,
    this.displayName,
    this.isLikedByMe = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'photo',
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      isEaContent: json['is_ea_content'] as bool? ?? false,
      isAiConfirmed: json['is_ai_confirmed'] as bool? ?? false,
      eaReportCount: json['ea_report_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      reportStatus: json['report_status'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      displayName: json['display_name'] as String?,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
        'is_ea_content': isEaContent,
        'is_ai_confirmed': isAiConfirmed,
        'ea_report_count': eaReportCount,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'shares_count': sharesCount,
        'report_status': reportStatus,
        'created_at': createdAt.toIso8601String(),
        'username': username,
        'avatar_url': avatarUrl,
        'display_name': displayName,
        'is_liked_by_me': isLikedByMe,
      };

  PostModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    bool? isEaContent,
    bool? isAiConfirmed,
    int? eaReportCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    String? reportStatus,
    DateTime? createdAt,
    String? username,
    String? avatarUrl,
    String? displayName,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      isEaContent: isEaContent ?? this.isEaContent,
      isAiConfirmed: isAiConfirmed ?? this.isAiConfirmed,
      eaReportCount: eaReportCount ?? this.eaReportCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      reportStatus: reportStatus ?? this.reportStatus,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}
