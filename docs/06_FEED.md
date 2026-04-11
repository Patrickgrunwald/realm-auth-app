# 06 — Feed

## Feed-Übersicht

Zwei Tabs:
1. **FYP (For-You-Page)** — Algorithmus-basiert
2. **Following** — Posts von gefolgten Usern, chronologisch

## For-You-Page (FYP)

### Algorithmus

Jeder Post bekommt einen Score:

```
Score = (likes * 3 + comments * 5 + shares * 10) / hours_since_posted
```

Je neuer ein Post mit vielen Interaktionen, desto höher der Score.

### SQL-Query

```sql
SELECT
  p.*,
  u.username,
  u.avatar_url,
  u.display_name,
  (
    (p.likes_count * 3 + p.comments_count * 5 + p.shares_count * 10)
    / GREATEST(1, EXTRACT(EPOCH FROM (now() - p.created_at)) / 3600)
  ) AS feed_score
FROM posts p
JOIN users u ON u.id = p.user_id
WHERE p.deleted_at IS NULL
  AND p.report_status != 'confirmed'
ORDER BY feed_score DESC
LIMIT 50;
```

### Infinite Scroll

- Lade 20 Posts initial
- Wenn User nach unten scrollt → lade weitere 20 Posts
- Nutze `created_at` des letzten Posts als Cursor

## Following-Feed

```sql
SELECT p.*, u.username, u.avatar_url
FROM posts p
JOIN users u ON u.id = p.user_id
JOIN follows f ON f.following_id = p.user_id
WHERE f.follower_id = auth.uid()
  AND p.deleted_at IS NULL
ORDER BY p.created_at DESC
LIMIT 50;
```

## Post-Card (Foto)

```
┌────────────────────────────────┐
│ [Avatar] Username      · 2h  ⋮│  ← Header: Avatar, Name, Zeit, Menü
│                                │
│                                │
│        [FOTO]                  │  ← Full-width Foto
│                                │
│                                │
│  ♥ 1.2K  💬 48  ↗  12         │  ← Interaktions-Leiste
│  ─────────────────────────────│
│  [Username] Caption Text...     │  ← Caption mit Like-Zähler
│                                │
└────────────────────────────────┘
```

## Video-Post-Card

```
┌────────────────────────────────┐
│ [Avatar] Username      · 2h  ⋮│
│                                │
│  ┌──────────────────────────┐  │
│  │                          │  │
│  │      [VIDEO PLAYING]     │  │  ← Auto-play wenn sichtbar
│  │                          │  │
│  │  [Mute/Unmute]  [Full]  │  │
│  └──────────────────────────┘  │
│                                │
│  ♥ 1.2K  💬 48  ↗  12         │
│  ─────────────────────────────│
│  [Username] Caption Text...     │
└────────────────────────────────┘
```

### Video Player (chewie)

```dart
// video_player_widget.dart
AspectRatio(
  aspectRatio: 16 / 9,  // oder Video-Metadaten nutzen
  child: Chewie(
    controller: ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(url),
      autoPlay: true,
      looping: true,
      muted: true,  // start muted (ohne Ton)
      showControls: false,
    ),
  ),
)
```

### Auto-Play beim Scrollen

```dart
// Feed mit PageView für Videos
PageView.builder(
  itemCount: posts.length,
  scrollDirection: Axis.vertical,
  onPageChanged: (index) {
    // Video an Index index abspielen, andere pausieren
    videoControllers.forEach((vc) => vc.pause());
    videoControllers[index]?.play();
  },
  itemBuilder: (context, index) {
    return posts[index].type == 'video'
      ? VideoPostCard(post: posts[index])
      : PostCard(post: posts[index]);
  },
)
```

## Interaktions-Leiste

### Like Button

```dart
// interaction_bar.dart
Row(
  children: [
    // Like
    GestureDetector(
      onTap: () => postController.toggleLike(postId),
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : null,
      ),
    ),
    Text(' ${formatCount(post.likesCount)} '),

    // Comment
    GestureDetector(
      onTap: () => showCommentsSheet(context, postId),
      child: Icon(Icons.chat_bubble_outline),
    ),
    Text(' ${formatCount(post.commentsCount)} '),

    // Share
    GestureDetector(
      onTap: () => sharePost(postId),
      child: Icon(Icons.ios_share),
    ),
    Text(' ${formatCount(post.sharesCount)} '),
  ],
)
```

## EA-Badge auf Posts

Wenn ein Post als EA markiert ist (report_status != 'none'):

```
┌────────────────────────────────┐
│ 🧠 Dieser Inhalt wurde als    │  ← Gelbes Banner OBEN
│ KI-generiert gemeldet          │
│                                │
│        [MEDIA]                  │
└────────────────────────────────┘
```

```dart
// ea_badge.dart
if (post.reportStatus != 'none') {
  return Column(
    children: [
      Container(
        color: Colors.amber.shade100,
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.psychology, color: Colors.amber.shade700, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dieser Inhalt wurde als KI-generiert gemeldet',
                style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      // Post-Media
    ],
  );
}
```

## Nächste Docs

← [05 AUTH_FLOW](05_AUTH_FLOW.md)
→ [07 CAMERA](07_CAMERA.md)
