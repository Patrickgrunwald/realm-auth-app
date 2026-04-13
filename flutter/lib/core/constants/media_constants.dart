/// Media upload constraints
class MediaConstants {
  // Photos
  static const int photoMaxSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int photoMaxDimension = 1080;
  static const int photoCompressionQuality = 82;

  // Videos
  static const int videoMaxSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int videoMaxDurationSeconds = 60; // 1 minute for now
  static const int videoMaxDimension = 720; // 720p for upload
}
