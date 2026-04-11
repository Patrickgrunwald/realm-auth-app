# 03 — API & Edge Functions

## Überblick

Supabase bietet zwei Arten von Backend-Logik:
1. **Direkte DB-Zugriffe** via Supabase Client (Flutter SDK) — für CRUD-Operationen
2. **Edge Functions** (Deno/Runtime) — für serverseitige Logik die nicht in die DB gehört

## Wann was nutzen?

| Use Case | Methode |
|---|---|
| Posts lesen/schreiben | Supabase Client (Flutter SDK) |
| Likes setzen | Supabase Client |
| Media-Upload | Supabase Client → Storage |
| EA-Report bei 5 Meldungen | Edge Function (Triggered by DB) |
| Auto-Löschung (24h nach Bestätigung) | Edge Function (Cron) |
| Push Notifications senden | Edge Function |
| Admin-Aktionen (bestätigen/ablehnen) | Edge Function |

---

## Edge Function 1: EA-Moderation Trigger

**Trigger:** HTTP POST (oder via Supabase DB-Trigger)

### Endpoint
```
POST /functions/v1/ea-moderation
Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
```

### Logik
```
1. Hole Post mit ea_report_count
2. Wenn ea_report_count >= 5 UND report_status == 'none':
   → report_status = 'pending'
   → is_ea_content = true
   → Erstelle Notification für Admins
3. Sonst: nichts tun
```

### Code (Deno)
```typescript
// supabase/functions/ea-moderation/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { post_id, reporter_id } = await req.json()

  // Hole aktuellen Stand
  const { data: post } = await supabase
    .from('posts')
    .select('ea_report_count, report_status')
    .eq('id', post_id)
    .single()

  if (!post || post.report_status !== 'none') {
    return new Response(JSON.stringify({ ok: true, action: 'skipped' }))
  }

  if (post.ea_report_count >= 5) {
    // Markiere als pending
    await supabase.from('posts').update({
      report_status: 'pending',
      is_ea_content: true,
    }).eq('id', post_id)

    // Benachrichtige Admins
    const { data: admins } = await supabase
      .from('users')
      .select('id')
      .eq('is_admin', true)

    if (admins) {
      const notifications = admins.map(admin => ({
        user_id: admin.id,
        type: 'ea_resolved',
        actor_id: reporter_id,
        post_id,
      }))
      await supabase.from('notifications').insert(notifications)
    }

    return new Response(JSON.stringify({ ok: true, action: 'marked_pending' }))
  }

  return new Response(JSON.stringify({ ok: true, action: 'reports_queued' }))
})
```

---

## Edge Function 2: Admin EA Bestätigung/Ablehnung

**Trigger:** HTTP POST

```
POST /functions/v1/ea-admin-action
Authorization: Bearer {ADMIN_API_KEY}
```

### Body
```json
{
  "post_id": "uuid",
  "action": "confirm" | "reject",
  "admin_id": "uuid"
}
```

### Logik
```
Wenn action == 'confirm':
  → is_ai_confirmed = true
  → report_status = 'confirmed'
  → Benachrichtigung an Post-Owner (Inhalt markiert)
  
Wenn action == 'reject':
  → ea_report_count = 0
  → report_status = 'rejected'
  → is_ea_content = false
  → Benachrichtigung an Post-Owner (Vorwurf entkräftet)
```

---

## Edge Function 3: Auto-Delete (stündlicher Cron)

**Trigger:** Supabase Cron (stündlich)

```
POST /functions/v1/ea-auto-delete
Authorization: Bearer {CRON_SECRET}
```

### Logik
```sql
-- Finde Posts die:
-- 1. is_ai_confirmed = true
-- 2. report_status = 'confirmed'  
-- 3. created_at < now() - 24 hours
-- 4. deleted_at IS NULL
-- → setze deleted_at = now()
```

### Resultat
- Media aus Storage löschen: `supabase.storage.from('posts').remove(path)`
- DB-Eintrag soft-delete (deleted_at timestamp)

---

## Edge Function 4: Feed-Score berechnen

**Trigger:** PostgreSQL Function (bei jedem Like/Comment)

Für den Algorithmus brauchen wir keinen externen API-Call — das passiert direkt in Flutter oder via SQL VIEW:

```sql
-- Feed-Score View
CREATE OR REPLACE VIEW feed_posts AS
SELECT
  p.*,
  u.username,
  u.avatar_url,
  u.display_name,
  -- Score: gewichtete Interaktionen / Zeit
  (
    (p.likes_count * 3 + p.comments_count * 5 + p.shares_count * 10)
    / GREATEST(1, EXTRACT(EPOCH FROM (now() - p.created_at)) / 3600)
  ) AS feed_score
FROM posts p
JOIN users u ON u.id = p.user_id
WHERE p.deleted_at IS NULL
  AND p.report_status != 'confirmed'
ORDER BY feed_score DESC;
```

---

## Externe API: Medien-Kompression (optional)

Für schwere Video-Kompression kann eine externe Function genutzt werden:

```
POST /functions/v1/compress-video
Content-Type: multipart/form-data

→ Input: Rohes Video (< 50MB)
→ Output: Komprimiertes Video (< 5MB, 720p, H.264)
```

**Alternative:** Kompression direkt in Flutter mit `ffmpeg_kit_flutter` — keine externe Function nötig.

---

## Supabase REST API (direkte DB-Zugriffe)

Alle Operationen die NICHT Edge Functions brauchen:

```
GET  /rest/v1/posts              → Feed laden
GET  /rest/v1/posts?id=eq.{id}   → Einzelner Post
POST /rest/v1/posts              → Post erstellen
POST /rest/v1/likes              → Like setzen
DELETE /rest/v1/likes?post_id=eq.{id} → Like entfernen
POST /rest/v1/comments           → Kommentar
GET  /rest/v1/users?id=eq.{id}   → Profil
PATCH /rest/v1/users             → Profil aktualisieren
POST /rest/v1/follows            → Folgen
DELETE /rest/v1/follows?follower_id=eq.{id} → Entfolgen
POST /rest/v1/ea_reports         → EA melden
```

---

## Storage API

```
POST /storage/v1/upload/{bucket}/{path}
GET  /storage/v1/sign/{bucket}/{path}   → Signed URL (zeitlich begrenzter Zugriff)
DELETE /storage/v1/object/{bucket}/{path}
```

### Upload-Flow (Flutter)
```dart
final file = File(localPath);
final bytes = await file.readAsBytes();

await supabase.storage
  .from('posts')
  .uploadBinary('${postId}/media.mp4', bytes);
```

---

## Nächste Docs

← [02 DATABASE](02_DATABASE.md)
→ [04 FRONTEND_STRUCTURE](04_FRONTEND_STRUCTURE.md)
