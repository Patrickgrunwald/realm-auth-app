# 09 — Profil & Follow-System

## Profil-Screen

```
┌────────────────────────────────┐
│                          [⚙️] │
│                                │
│        [AVATAR]                │  ← Nur Kamera-Aufnahme!
│         Patrick                │
│        @patrick_gr             │
│                                │
│   124   1.2K     89            │
│   Posts Followers Following    │
│                                │
│  ┌──────────────────────────┐  │
│  │ [Profil bearbeiten]       │  │  ← Nur eigenes Profil
│  └──────────────────────────┘  │
│                                │
│  ┌──────────────────────────┐  │
│  │ [Folgen]  [Nachricht]     │  │  ← Andere User
│  └──────────────────────────┘  │
│                                │
│  ────────────────────────────  │
│  [|Alle|] [🔒]                │  ← Grid / Gespeichert / Archiv
└────────────────────────────────┘
```

## Avatar — NUR Kamera

Das Avatar-Foto darf NUR über die Kamera aufgenommen werden:

```dart
// edit_profile_screen.dart
Future<void> pickAvatar() async {
  // Direkt zur Kamera — KEIN Gallery-Picker!
  final file = await Navigator.push<File>(
    context,
    MaterialPageRoute(
      builder: (_) => AvatarCameraScreen(), // Eigene Kamera-Screen
    ),
  );
  if (file != null) {
    // Komprimieren
    final compressed = await ImageCompress.compressAndGetFile(
      file.path,
      quality: 80,
      minWidth: 400,
      minHeight: 400,
      format: CompressFormat.jpeg,
    );
    // Upload
    await _uploadAvatar(compressed);
  }
}

// AvatarCameraScreen — NUR Kamera, kein Gallery-Zugang
class AvatarCameraScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPreview(...), // KEIN gallery-Button!
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture, // Direkter Auslöser
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
```

## Profil bearbeiten

```
┌────────────────────────────────┐
│ ←      Profil bearbeiten       │
│                                │
│          [AVATAR]              │
│       [📷 Ändern]              │
│                                │
│  ┌────────────────────────────┐│
│  │ Anzeigename                 ││
│  └────────────────────────────┘│
│  ┌────────────────────────────┐│
│  │ @username                   ││
│  └────────────────────────────┘│
│  ┌────────────────────────────┐│
│  │ Bio (max 150 Zeichen)       ││
│  └────────────────────────────┘│
│                                │
│  [   Änderungen speichern   ]   │
└────────────────────────────────┘
```

## Follow / Unfollow

```dart
// follow_button.dart
class FollowButton extends StatelessWidget {
  final String targetUserId;
  final bool isFollowing;

  Widget build(BuildContext context) {
    return isFollowing
      ? OutlinedButton(
          onPressed: () => unfollow(targetUserId),
          child: Text('Entfolgen'),
        )
      : ElevatedButton(
          onPressed: () => follow(targetUserId),
          child: Text('Folgen'),
        );
  }

  Future<void> follow(String userId) async {
    await supabase.from('follows').insert({
      'follower_id': supabase.auth.currentUser!.id,
      'following_id': userId,
    });
    // Trigger aktualisiert follower/following_count automatisch
  }

  Future<void> unfollow(String userId) async {
    await supabase.from('follows').delete()
      .eq('follower_id', supabase.auth.currentUser!.id)
      .eq('following_id', userId);
  }
}
```

## Posts-Grid

```
┌──────┬──────┬──────┐
│      │      │      │
│ [●]  │ [●]  │ [●]  │  ← [●] = Video (kleine Play-Anzeige)
│      │      │      │
├──────┼──────┼──────┤
│      │      │      │
│ [●]  │      │ [●]  │
│      │      │      │
└──────┴──────┴──────┘
```

```dart
// posts_grid.dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
  ),
  itemCount: posts.length,
  itemBuilder: (context, i) {
    final post = posts[i];
    return GestureDetector(
      onTap: () => Get.to(PostDetailScreen(postId: post.id)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(imageUrl: post.mediaUrl),
          if (post.type == 'video')
            Positioned(
              right: 4, bottom: 4,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  },
)
```

## Follower / Following Listen

```
┌────────────────────────────────┐
│ ←   Follower            1.2K  │
│                                │
│  ┌──────────────────────────┐  │
│  │ [Avatar] Username        │  │
│  │          Anzeigename     │  │
│  │                   [Folgen]│  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │ [Avatar] Username ...     │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

---

## Nächste Docs

← [08 POSTS](08_POSTS.md)
→ [10 EA_MODERATION](10_EA_MODERATION.md)
