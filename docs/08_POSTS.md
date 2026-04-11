# 08 — Posts erstellen & anzeigen

## Create Post Screen

```
┌────────────────────────────────┐
│ [X]           Beitrag erstellen [Weiter]│
│                                │
│ ┌────────────────────────────┐│
│ │                            ││
│ │       [MEDIA PREVIEW]       ││  ← Foto oder Video-Thumbnail
│ │                            ││
│ └────────────────────────────┘│
│                                │
│ ┌────────────────────────────┐│
│ │ Was gibt's Neues?           ││  ← Caption-Textfeld
│ └────────────────────────────┘│
│                                │
│ ────────────────────────────── │
│                                │
│ ┌────────────────────────────┐│
│ │ ⚠️  KI-Inhalt markieren     ││  ← ⚠️ EA-TOGGLE (PROMINENT!)
│ │ Ich bestätige, dass dieser ││
│ │ Inhalt mit KI erstellt      ││
│ │ wurde                      ││
│ └────────────────────────────┘│
└────────────────────────────────┘
```

## EA-Toggle — Das WICHTIGSTE Feature

Der EA-Button / Toggle muss **extrem deutlich** sein:

```dart
// ea_toggle.dart — PROMINENT, nicht zu übersehen
Container(
  decoration: BoxDecoration(
    color: Colors.amber.shade50,
    border: Border.all(color: Colors.amber, width: 2),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.psychology, color: Colors.amber.shade800, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'KI-Inhalt markieren',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ),
          Switch(
            value: isEAMarked,
            activeColor: Colors.amber,
            onChanged: (value) => setState(() => isEAMarked = value),
          ),
        ],
      ),
      if (isEAMarked) ...[
        SizedBox(height: 8),
        Text(
          '⚠️ Ich bestätige, dass dieser Inhalt mit Künstlicher Intelligenz erstellt wurde.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.amber.shade800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'KI-generierte Inhalte müssen markiert werden.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.amber.shade600,
          ),
        ),
      ],
    ],
  ),
)
```

### EA-Toggle Design-Regeln
- **Mindestens 2px Border** in Amber/Gelb
- **Hintergrund:** leicht gelblich getönt
- **Icon:** 🧠 oder `psychology` — groß und deutlich
- **Text:** Groß, fett, nicht übersehbar
- **Switch:** Großes Touch-Target (mindestens 48x48dp)
- **Farbe:** NIEMALS blau/primär — nur Gelb/Amber

## Caption-Validierung

```dart
// captions dürfen keine externen links enthalten
final linkRegex = RegExp(r'https?://|www\.|\.com|\.de|\.org');
if (linkRegex.hasMatch(caption)) {
  throw ValidationException('Externe Links sind nicht erlaubt');
}
if (caption.length > 500) {
  throw ValidationException('Caption max 500 Zeichen');
}
```

## Post erstellen (Upload)

```dart
// post_controller.dart
class PostController {
  final SupabaseClient _supabase;
  final StorageService _storage;

  Future<Post> createPost({
    required File mediaFile,
    required String type, // 'photo' | 'video'
    required String caption,
    required bool isEAMarked,
    File? thumbnail,
  }) async {
    // 1. Unique ID generieren
    final postId = UUID.v4();

    // 2. Media uploaden
    final extension = type == 'video' ? 'mp4' : 'jpg';
    final mediaPath = 'posts/$postId/media.$extension';

    await _storage.upload(mediaPath, mediaFile);

    // 3. Thumbnail uploaden (nur Video)
    String? thumbnailUrl;
    if (type == 'video' && thumbnail != null) {
      final thumbPath = 'posts/$postId/thumbnail.jpg';
      await _storage.upload(thumbPath, thumbnail);
      thumbnailUrl = _storage.getPublicUrl(thumbPath);
    }

    // 4. Post-Record in DB
    final post = Post(
      id: postId,
      userId: _supabase.auth.currentUser!.id,
      type: type,
      mediaUrl: _storage.getPublicUrl(mediaPath),
      thumbnailUrl: thumbnailUrl,
      caption: caption.trim(),
      isEaContent: isEAMarked,
    );

    await _supabase.from('posts').insert(post.toJson());

    return post;
  }
}
```

## Post-Detail Screen

```
┌────────────────────────────────┐
│ ←                        ⋮    │
│                                │
│ ┌────────────────────────────┐│
│ │                            ││
│ │       [MEDIA FULL]         ││  ← Foto oder Video
│ │                            ││
│ └────────────────────────────┘│
│                                │
│  ♥ 1.2K  💬 48  ↗  12        │
│  ────────────────────────────  │
│  [Username] Caption Text...     │
│  #hashtag #hashtag             │
│                                │
│  Alle 48 Kommentare ansehen ↓  │
└────────────────────────────────┘
```

## Comments Bottom Sheet

```dart
// comments_sheet.dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    minChildSize: 0.3,
    children: [
      // Header
      Text('Kommentare'),
      // Comment-Liste
      ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, i) => CommentTile(comment: comments[i]),
      ),
      // Input-Feld unten
      TextField(
        decoration: InputDecoration(
          hintText: 'Kommentieren...',
          suffixIcon: IconButton(
            icon: Icon(Icons.send),
            onPressed: () => postController.addComment(postId, text),
          ),
        ),
      ),
    ],
  ),
);
```

## Like toggeln

```dart
Future<void> toggleLike(String postId) async {
  final userId = supabase.auth.currentUser!.id;

  // Check ob bereits geliked
  final existing = await supabase
    .from('likes')
    .select('id')
    .eq('post_id', postId)
    .eq('user_id', userId)
    .maybeSingle();

  if (existing != null) {
    // unlike
    await supabase.from('likes').delete().match({'id': existing['id']});
    await _decrementLikes(postId);
  } else {
    // like
    await supabase.from('likes').insert({'post_id': postId, 'user_id': userId});
    await _incrementLikes(postId);
    await _createNotification(postId, 'like');
  }
}
```

---

## Nächste Docs

← [07 CAMERA](07_CAMERA.md)
→ [09 PROFILE](09_PROFILE.md)
