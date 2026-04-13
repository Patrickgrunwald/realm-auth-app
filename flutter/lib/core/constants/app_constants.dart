class AppConstants {
  AppConstants._();

  static const String appName = 'Realm Auth';
  static const String appTagline = 'Deine Welt. Deine Momente.';

  // Text-Limits
  static const int maxCaption = 500;
  static const int maxBio = 150;
  static const int maxCommentLength = 300;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 8;

  // Media-Limits
  static const int maxVideoLengthSeconds = 60;
  static const int maxFileSizeMB = 100;
  static const int maxImageSizeMB = 10;

  // Supabase Tabellen
  static const String usersTable = 'users';
  static const String postsTable = 'posts';
  static const String likesTable = 'likes';
  static const String commentsTable = 'comments';
  static const String followsTable = 'follows';
  static const String eaReportsTable = 'ea_reports';
  static const String notificationsTable = 'notifications';
  static const String storageVideosBucket = 'videos';
  static const String storageAvatarsBucket = 'avatars';
  static const String storageThumbnailsBucket = 'thumbnails';
  static const String storagePostsBucket = 'posts';

  // Debounce
  static const Duration usernameCheckDebounce = Duration(milliseconds: 600);
  static const Duration searchDebounce = Duration(milliseconds: 400);

  // Pagination
  static const int postsPageSize = 10;
  static const int commentsPageSize = 20;
  static const int usersPageSize = 20;
}
