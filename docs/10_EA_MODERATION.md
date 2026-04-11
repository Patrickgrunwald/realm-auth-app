# 10 — EA-Moderation (Kernfeature)

## Was ist EA-Content?

**EA = External/Artificial** — Inhalte die mit Künstlicher Intelligenz generiert wurden (Bilder, Videos).

## Der EA-Workflow (Schritt für Schritt)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  1. POST WIRD ERSTELLT                                     │
│     ├── EA Toggle = AUS (Standard)                          │
│     └── User erstellt Post mit Foto/Video                   │
│                                                             │
│  2. ANDERE USER KÖNNEN MELDEN                              │
│     ├── Report-Button auf jedem Post                        │
│     ├── Ein User kann nur EINMAL pro Post melden            │
│     └── Bei Meldung: ea_report_count++                     │
│                                                             │
│  3. TRIGGER BEI ≥ 5 MELDUNGEN                              │
│     └── Edge Function: ea-moderation                        │
│         → report_status = 'pending'                         │
│         → is_ea_content = true                               │
│         → Admins werden benachrichtigt                      │
│                                                             │
│  4. ADMIN PRÜFUNG (In-App oder Web-Dashboard)             │
│     ├── confirm → is_ai_confirmed = true                     │
│     │           → report_status = 'confirmed'                │
│     │           → Media wird unscharf + 🧠 Badge            │
│     │           → Nach 24h: AUTO-LÖSCHUNG                  │
│     │                                                       │
│     └── reject → ea_report_count = 0                        │
│                 → report_status = 'rejected'                 │
│                 → is_ea_content = false                      │
│                 → Post bleibt normal sichtbar               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## User-Seite: EA melden

### Report-Button auf jedem Post

Auf jedem Post-Card gibt es ein **Menü (⋮)** → "Als KI-Inhalt melden"

```
┌────────────────────────────────┐
│ [Avatar] Username      · 2h  ⋮│  ← ⋮ Menü
│                                │
│        [MEDIA]                  │
│                                │
│  ♥ 1.2K  💬 48  ↗  12        │
│  [Username] Caption Text...     │
└────────────────────────────────┘

Beim Klick auf ⋮:
┌─────────────────────┐
│  🔗 Link kopieren   │
│  🚫 Post melden      │  ← Diese Option
│  👤 User blockieren  │
│  ⚠️ Als KI melden    │  ← 🧠 EA-MELDUNG (PROMINENT!)
└─────────────────────┘
```

### EA-Report Sheet

```dart
// ea_report_sheet.dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text(
              'KI-Inhalt melden',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Warum meinst du, dass dieser Inhalt mit KI erstellt wurde?',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        // Schnell-Auswahl
        Wrap(
          spacing: 8,
          children: [
            'Unrealistische Details',
            'Keine EXIF-Daten',
            'Stil wirkt KI-generiert',
            'Sonstiges',
          ].map((reason) => 
            ActionChip(
              label: Text(reason),
              onPressed: () => submitReport(reason),
            )
          ).toList(),
        ),
        SizedBox(height: 16),
        // Eigene Begründung
        TextField(
          decoration: InputDecoration(
            hintText: 'Optional: Eigene Begründung...',
          ),
          maxLines: 3,
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Abbrechen'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => submitReport(),
                child: Text('Melden'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

### Report absenden

```dart
// ea_repository.dart
Future<void> reportPost(String postId, String? reason) async {
  final userId = supabase.auth.currentUser!.id;

  // Prüfen ob bereits gemeldet
  final already = await supabase
    .from('ea_reports')
    .select('id')
    .eq('post_id', postId)
    .eq('reporter_id', userId)
    .maybeSingle();

  if (already != null) {
    throw Exception('Du hast diesen Post bereits gemeldet.');
  }

  // Report erstellen
  await supabase.from('ea_reports').insert({
    'post_id': postId,
    'reporter_id': userId,
    'reason': reason,
  });

  // ea_report_count erhöhen
  await supabase.rpc('increment_ea_report_count', params: {'post_id_param': postId});
}
```

## Admin-Bereich

### In-App Admin-View (einfachste Variante)

```dart
// admin_screen.dart
// Nur für is_admin = true User sichtbar
// Zeigt alle Posts mit report_status = 'pending'

Future<List<Post>> getPendingPosts() async {
  return supabase
    .from('posts')
    .select('*, users(*)')
    .eq('report_status', 'pending')
    .eq('deleted_at', null)
    .order('ea_report_count', ascending: false);
}

// Admin-Aktion
Future<void> confirmEA(String postId) async {
  await supabase.from('posts').update({
    'is_ai_confirmed': true,
    'report_status': 'confirmed',
  }).eq('id', postId);

  // Owner benachrichtigen
  await _notifyOwner(postId, 'ea_confirmed');
}

Future<void> rejectEA(String postId) async {
  await supabase.from('posts').update({
    'ea_report_count': 0,
    'report_status': 'rejected',
    'is_ea_content': false,
  }).eq('id', postId);
}
```

### Admin-Post-View

```
┌─────────────────────────────────────────┐
│ ←   EA-Prüfung          3 Pending       │
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ [Avatar] @username    🧠 12 Meldungen││
│ │                                       ││
│ │ [KI-GENERIERT - UNSCHARF]           ││  ← Unscharfes Media
│ │                                       ││
│ │ Meldungen:                            ││
│ │ • "Unrealistische Details" (4x)       ││
│ │ • "Stil wirkt KI-generiert" (6x)      ││
│ │ • "Sonstiges" (2x)                   ││
│ │                                       ││
│ │ [Ablehnen]        [Als KI bestätigen]││  ← GELB/AMBER
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## EA-Bestätigt: Unscharf + Badge

Wenn `is_ai_confirmed == true`:

```dart
// ea_badge.dart
if (post.isAiConfirmed) {
  return Stack(
    children: [
      // Unscharfes Media
      Image.file(
        mediaFile,
        filterQuality: FilterQuality.low, // Low = unscharf
      ),
      // Blur drüber
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black26),
        ),
      ),
      // 🧠 Badge
      Positioned(
        top: 12,
        left: 12,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology, size: 16, color: Colors.black87),
              SizedBox(width: 4),
              Text(
                'KI-generiert — wird bald gelöscht',
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

## Auto-Löschung (Edge Function)

```typescript
// ea-auto-delete/index.ts
// Läuft stündlich via Supabase Cron
// Sucht Posts: is_ai_confirmed = true AND created_at < now() - 24h

const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

const { data: posts } = await supabase
  .from('posts')
  .select('id, media_url')
  .eq('is_ai_confirmed', true)
  .eq('deleted_at', null)
  .lt('created_at', dayAgo.toISOString());

for (const post of posts ?? []) {
  // 1. Media aus Storage löschen
  const mediaPath = post.media_url.split('/').pop();
  await supabase.storage.from('posts').remove([`posts/${post.id}/${mediaPath}`]);
  
  // 2. DB soft-delete
  await supabase.from('posts').update({
    deleted_at: new Date().toISOString(),
  }).eq('id', post.id);
}
```

## Zustandsdiagramm (Post)

```
                                    ┌──────────────────┐
                                    │                  │
                                    │    erstellt      │
                                    │  (ea_content=    │
                                    │   false)         │
                                    └────────┬─────────┘
                                             │ User erstellt
                                             │ EA-Markierung
                                             ▼
                                    ┌──────────────────┐
                                    │  ea_content=true │
                                    │ (freiwillig      │
                                    │  markiert)       │
                                    └────────┬─────────┘
                                             │ 5+ Reports
                                             ▼
                                    ┌──────────────────┐
                                    │    pending       │
                                    │ (wird geprüft)   │
                                    └────────┬─────────┘
                                             │
                              ┌──────────────┴──────────────┐
                              │                              │
                              ▼                              ▼
                   ┌──────────────────┐           ┌──────────────────┐
                   │   confirmed      │           │    rejected      │
                   │ (KI bestätigt)  │           │ (kein KI)        │
                   │ → unscharf      │           │ → normal weiter  │
                   │                 │           │                   │
                   │ 24h → gelöscht │           └──────────────────┘
                   └──────────────────┘
```

---

## Nächste Docs

← [09 PROFILE](09_PROFILE.md)
→ [11 NAVIGATION](11_NAVIGATION.md)
