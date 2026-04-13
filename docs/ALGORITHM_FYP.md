# Realm Auth — TikTok-ähnlicher FYP Algorithmus

## Inhalt
1. [Wie TikTok's Algorithmus funktioniert](#wie-tiktoks-algorithmus-funktioniert)
2. [Unsere Architektur](#unsere-architektur)
3. [Daten die wir tracken müssen](#daten-die-wir-tracken-müssen)
4. [Scoring-Formel](#scoring-formel)
5. [Phasen-Plan](#phasen-plan)
6. [Implementierungsdetails](#implementierungsdetails)
7. [Edge Cases & Guardrails](#edge-cases--guardrails)

---

## Wie TikTok's Algorithmus funktioniert

### Die 4 Kern-Signale (TikTok For You Page)

| Signal | Gewicht | Was es misst |
|--------|---------|-------------|
| **Watch Time / Completion Rate** | 🔴 HÖCHST | Wie viel vom Video wurde geschaut? >60% = gut |
| **Engagement Rate** | 🟠 HOCH | Likes, Comments, Shares, Saves — Shares wiegen am schwersten |
| **Video-Information** | 🟡 MITTEL | Hashtags, Sounds, Captions, Themen |
| **User-Interaktionen** | 🟢 BASIS | Was der User liked, teilt, kommentiert, sucht |

**TikTok's eigene Rangliste der Engagement-Gewichtung:**
```
Shares > Comments > Likes > Follows
```

**Wichtigste Metrik: Completion Rate**
> "Videos die zu 60%+ geschaut werden, bekommen exponentiell mehr Reichweite"
> — TikTok Creator Portal, aktualisiert 2025

### Das A/B-Test-Prinzip
TikTok testet jedes Video zunächst bei 100–500 Nutzern. Wenn die Engagement-Signale gut sind → immer größere Audience. Wenn nicht → Distribution wird gestoppt.

---

## Unsere Architektur

### Hybrid-Ansatz: 3 Empfehlungsmodi

```
┌─────────────────────────────────────────────────────┐
│                    FYP FEED                         │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Cold     │  │ Collab.  │  │ Content-Based     │  │
│  │ Start    │  │ Filter   │  │ Similarity        │  │
│  │ (Neu)    │  │ (aktiv)  │  │ (ergänzend)       │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │              │                  │            │
│       ▼              ▼                  ▼            │
│  Popularity       "User              Topic           │
│  Score            Similarity          Match           │
│  (recency +      Score               Score           │
│   engagement)     (co-engagement)     (hashtags/EA)  │
│                   │                                   │
│                   └───────────┬─────────────────────  │
│                               ▼                      │
│                    FINAL SCORE = gewichtete Summe    │
│                   排名 (Ranking) → Feed              │
└─────────────────────────────────────────────────────┘
```

### Modus 1: Cold Start (Neue User, <10 Videos gesehen)
**Problem:** Keine User-Historie vorhanden.
**Lösung:** Popularity Score + Content Diversity

```dart
// Pseudo-Score für Cold Start
score = (popularityScore * 0.7) + (recencyBonus * 0.3)
popularityScore = (likes * 1 + comments * 3 + shares * 5) / totalViews
recencyBonus = max(0, 1 - (hoursSincePost / 72)) // 72h = 3 Tage
```

### Modus 2: Collaborative Filtering (aktive User)
**Problem:** Was sehen User die ähnlich handeln wie ich?
**Lösung:** Co-Engagement Matrix

```
"Wenn User A und User B ähnliche Posts liken/kommentieren,
 dann zeig User A auch die Posts die User B gut fand."
```

**Berechnung (SQL-basiert, Supabase):**
```sql
-- Finde User die ähnlich interagieren wie currentUser
WITH my_likes AS (
  SELECT post_id FROM likes WHERE user_id = :currentUserId
),
similar_users AS (
  SELECT l.user_id, COUNT(*) as overlap
  FROM likes l
  JOIN my_likes ml ON l.post_id = ml.post_id
  WHERE l.user_id != :currentUserId
  GROUP BY l.user_id
  ORDER BY overlap DESC
  LIMIT 50  -- Top 50 ähnlichste User
),
candidate_posts AS (
  SELECT p.id, p.user_id, p.likes_count, p.comments_count,
         p.shares_count, p.created_at
  FROM posts p
  JOIN likes l ON p.id = l.post_id
  JOIN similar_users su ON l.user_id = su.user_id
  WHERE p.deleted_at IS NULL
    AND p.report_status != 'confirmed'
    AND p.user_id != :currentUserId
    AND p.id NOT IN (SELECT post_id FROM my_likes)  -- keine Duplikate
  GROUP BY p.id
)
SELECT *, weighted_score(candidate_posts) FROM candidate_posts;
```

### Modus 3: Content-Based (Ergänzung)
**Problem:** Zeig mehr von dem was der User aktiv sucht/sieht.
**Lösung:** Topic/Hashtag + EA-Score Matching

```
Score = topicMatch(user_topics, post_topics) * EA_relevance_score
```

---

## Daten die wir tracken müssen

### Neue Datenbank-Tabelle: `post_analytics`

```sql
CREATE TABLE IF NOT EXISTS public.post_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- NULL = anon view
  event_type TEXT NOT NULL CHECK (event_type IN (
    'view',           -- Video/Post gesehen
    'watch_time_ms',  -- Millisekunden geschaut (nur Video)
    'like',           -- Geliked
    'unlike',         -- Unliked
    'comment',        -- Kommentiert
    'share',          -- Geteilt
    'save',           -- Gespeichert
    'follow',         -- Creator gefolgt
    'click_through'   -- Auf Profil/Link geklickt
  )),
  watch_duration_ms INTEGER,       -- nur bei view mit video
  video_duration_ms INTEGER,       -- nur bei view mit video
  referrer TEXT,                   -- 'fyp' | 'following' | 'search' | 'profile'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index für schnelle Aggregation
CREATE INDEX IF NOT EXISTS idx_analytics_post_event ON public.post_analytics(post_id, event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_user_event ON public.post_analytics(user_id, event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON public.post_analytics(created_at);
```

### Aggregation-Tabelle für Performance: `post_scores`

```sql
CREATE TABLE IF NOT EXISTS public.post_scores (
  post_id UUID PRIMARY KEY REFERENCES public.posts(id) ON DELETE CASCADE,
  views INTEGER NOT NULL DEFAULT 0,
  unique_viewers INTEGER NOT NULL DEFAULT 0,
  total_watch_time_ms BIGINT NOT NULL DEFAULT 0,
  avg_watch_time_ms INTEGER NOT NULL DEFAULT 0,
  completion_rate DECIMAL(5,4) NOT NULL DEFAULT 0,  -- 0.0000 bis 1.0000
  likes_count INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  shares_count INTEGER NOT NULL DEFAULT 0,
  saves_count INTEGER NOT NULL DEFAULT 0,
  engagement_rate DECIMAL(5,4) NOT NULL DEFAULT 0, -- (likes+comments+shares)/views
  fyp_score DECIMAL(10,6) NOT NULL DEFAULT 0,     -- finaler FYP Score
  last_calculated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Triggers für Auto-Update der post_scores bei neuen Events
CREATE OR REPLACE FUNCTION public.recalc_post_score(post_uuid UUID)
RETURNS VOID AS $$
DECLARE
  v_views INTEGER;
  v_likes INTEGER;
  v_comments INTEGER;
  v_shares INTEGER;
  v_watch_time BIGINT;
  v_avg_watch INTEGER;
  v_completion DECIMAL;
  v_engagement DECIMAL;
  v_score DECIMAL;
BEGIN
  SELECT COUNT(*) INTO v_views FROM post_analytics WHERE post_id = post_uuid AND event_type = 'view';
  SELECT COALESCE(SUM(watch_duration_ms), 0) INTO v_watch_time FROM post_analytics WHERE post_id = post_uuid AND event_type = 'view' AND watch_duration_ms IS NOT NULL;
  SELECT COUNT(*) INTO v_likes FROM post_analytics WHERE post_id = post_uuid AND event_type = 'like';
  SELECT COUNT(*) INTO v_comments FROM post_analytics WHERE post_id = post_uuid AND event_type = 'comment';
  SELECT COUNT(*) INTO v_shares FROM post_analytics WHERE post_id = post_uuid AND event_type = 'share';

  v_avg_watch := CASE WHEN v_views > 0 THEN (v_watch_time / v_views)::INTEGER ELSE 0 END;
  v_completion := CASE WHEN v_views > 0 THEN LEAST((v_watch_time::DECIMAL / NULLIF((SELECT media_url FROM posts WHERE id = post_uuid), '')::DECIMAL), 1.0) ELSE 0 END;
  v_engagement := CASE WHEN v_views > 0 THEN ((v_likes + v_comments + v_shares)::DECIMAL / v_views) ELSE 0 END;

  -- Finale FYP-Formel (siehe unten)
  v_score := (
    (v_completion * 40) +
    (LEAST(v_engagement * 10, 30)) +
    (LEAST((v_shares::DECIMAL / NULLIF(v_views, 0)) * 100, 20)) +
    (LEAST((v_comments::DECIMAL / NULLIF(v_views, 0)) * 60, 10)) +
    (LEAST((v_likes::DECIMAL / NULLIF(v_views, 0)) * 40, 0))
  );

  INSERT INTO post_scores (post_id, views, unique_viewers, total_watch_time_ms,
    avg_watch_time_ms, completion_rate, likes_count, comments_count, shares_count,
    saves_count, engagement_rate, fyp_score, last_calculated_at)
  VALUES (post_uuid, v_views, v_views, v_watch_time, v_avg_watch,
    v_completion, v_likes, v_comments, v_shares, 0, v_engagement, v_score, now())
  ON CONFLICT (post_id) DO UPDATE SET
    views = v_views, total_watch_time_ms = v_watch_time,
    avg_watch_time_ms = v_avg_watch, completion_rate = v_completion,
    likes_count = v_likes, comments_count = v_comments, shares_count = v_shares,
    engagement_rate = v_engagement, fyp_score = v_score, last_calculated_at = now();
END;
$$ LANGUAGE plpgsql;

-- Trigger: bei analytics-Insert → Score neu berechnen
CREATE OR REPLACE FUNCTION public.trigger_recalc_score()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.recalc_post_score(NEW.post_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_analytics_insert ON post_analytics;
CREATE TRIGGER on_analytics_insert
  AFTER INSERT ON post_analytics
  FOR EACH ROW EXECUTE FUNCTION public.trigger_recalc_score();
```

### User-Behavior-Profil (für Personalisierung)

```sql
CREATE TABLE IF NOT EXISTS public.user_content_profile (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  liked_categories JSONB NOT NULL DEFAULT '{}',
  -- z.B. {"tech": 0.8, "lifestyle": 0.6, "gaming": 0.3}
  liked_hashtags JSONB NOT NULL DEFAULT '[]',
  liked_creators JSONB NOT NULL DEFAULT '[]',
  viewed_categories JSONB NOT NULL DEFAULT '{}',
  avg_watch_time_ms INTEGER NOT NULL DEFAULT 0,
  engagement_ratio DECIMAL(5,4) NOT NULL DEFAULT 0,
  posts_seen INTEGER NOT NULL DEFAULT 0,
  last_updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Scoring-Formel

### Die FYP Score-Formel (Final)

```
FYP_Score = Completion_Score + Engagement_Score + Recency_Penalty + Quality_Bonus

其中:

Completion_Score (max 40 Punkte):
  = completion_rate * 40
  (completion_rate = avg_watch_time / video_duration, max 1.0)

Engagement_Score (max 60 Punkte):
  = shares_score (max 20)
    + comments_score (max 20)
    + likes_score (max 15)
    + saves_score (max 5)
  wobei jede Rate relativ zum median der letzten 100 Posts berechnet wird:
    rate = metric / views
    normalized = MIN(rate / median_rate * weight, max_points)

Recency_Penalty:
  = MAX(0, 1 - (hours_since_post / 168))  -- 168h = 7 Tage
  score *= recency_penalty

Quality_Bonus:
  = +5 wenn completion_rate > 0.7 UND engagement_rate > 0.05
  = +10 wenn completion_rate > 0.8 UND engagement_rate > 0.10
  = -100 (soft-ban) wenn report_status = 'pending'
```

### Gewichtung der Signale (TikTok-Prinzip)

```
Share    →  5x Gewicht  (stärkstes Signal: "Das muss ich zeigen")
Comment  →  3x Gewicht
Like     →  1x Gewicht
Watch    →  4x Gewicht  (completion rate)
```

---

## Phasen-Plan

### Phase 1: Analytics-Infrastruktur ✅ Plan
**Aufwand:** Mittel | **Timeline:** Sprint 1

- [ ] `post_analytics` Tabelle anlegen
- [ ] `post_scores` Tabelle anlegen mit Aggregations-Funktion
- [ ] DB-Trigger für auto-recalculation
- [ ] `user_content_profile` Tabelle anlegen
- [ ] Flutter: Analytics-Events beim Post-Schauen tracken
  - view-event beim Start des Posts
  - watch_time_ms alle 5 Sekunden während Video läuft
  - like/unlike/share events
  - comment event
- [ ] Backend: RPC-Function für post_scores
- [ ] Flutter: Feed nutzt post_scores.fyp_score statt ORDER BY created_at

### Phase 2: User-Content-Profile ✅ Plan
**Aufwand:** Mittel | **Timeline:** Sprint 2

- [ ] User Profile bei jedem Like/Unlike/View aktualisieren
- [ ] User Profile bei Kommentar/Share aktualisieren
- [ ] Cron-Job: Nachts user_content_profile auswerten (top categories)
- [ ] Collaborative Filtering in SQL:
  - Co-Engagement Matrix: Welche Posts werden von denselben Usern geliked?
  - Similar-User Lookup: Top 20 ähnlichste User finden
  - Candidate Generation: Posts von ähnlichen Usern als FYP-Kandidaten

### Phase 3: Hybrid FYP Feed ✅ Plan
**Aufwand:** Hoch | **Timeline:** Sprint 3

- [ ] FYP Controller in Flutter: Multi-Stage Ranking
  - Stage 1: 1000 Kandidaten (Cold Start: top scores | Warm: collab + content)
  - Stage 2: Ranking nach finalem FYP-Score
  - Stage 3: Diversity-Balance (nicht mehr als 3 Posts vom selben Creator hintereinander)
  - Stage 4: Freshness-Weighting
- [ ] A/B Testing Framework (anfangs: 80% algorithmisch / 20% random)
- [ ] "Nicht nochmal zeigen" Logik (posts der letzten 7 Tage seen-Log)
- [ ] Interest-Drift Handling (was wenn User plötzlich anderes schaut?)

### Phase 4: Creator Distribution & Moderation ✅ Plan
**Aufwand:** Mittel | **Timeline:** Sprint 4

- [ ] Creator Score (nicht nur Post-Score)
  - Konsistenz-Bonus: Regelmäßig postende Creator bekommen boost
  - Quality-Bonus: Posts mit >70% completion rate
  - Growth-Rate: follower_growth in letzten 7 Tagen
- [ ] Anti-Gaming Measures:
  - Spam-Detection: Unnatürlich hohe Engagement-Raten
  - Bot-Filter: Watch-Time < 500ms pro Post zählt nicht
  - Shadowban-Logik: Posts mit >5 EA_Reports in 1h → automatisch pending
- [ ] EA-Moderation Auto-Score: EA-Posts bekommen 50% FYP-Score bis bestätigt

### Phase 5: Personalisierung & Refinement ✅ Plan
**Aufwand:** Mittel | **Timeline:** Sprint 5

- [ ] Hashtag/Topic Extraction aus Captions (NLP oder Keyword-Matching)
- [ ] "Für dich relevanter" — Explizite Feedback-Schleife
  - User kann "Mehr davon" / "Weniger davon" klicken
  - →调整 user_content_profile Gewichtung
- [ ] Time-of-Day Pattern: Wann postet/liest der User am meisten?
  - Morning / Evening / Late-Night Content-Tracking
- [ ] Stale-Profile Refresh: Nach 7 Tagen Inaktivität → Mix mit Popular-Feed

---

## Implementierungsdetails

### Flutter: Analytics Event Tracking

```dart
// events/analytics_event.dart
enum AnalyticsEventType {
  view,          // Post/Video gestartet
  watchTime,     // Video-Watch-Time Pulse (alle 5s)
  like,
  unlike,
  comment,
  share,
  save,
  followCreator, // Creator-Button geklickt
  clickThrough,  // Auf Profil/Link geklickt
}

// events/analytics_service.dart
class AnalyticsService {
  // Track ein Event
  Future<void> track(AnalyticsEventType type, {
    String? postId,
    String? watchDurationMs,
    String? videoDurationMs,
    String? referrer, // 'fyp' | 'following' | 'search' | 'profile'
  }) async {
    await SupabaseService.client.from('post_analytics').insert({
      'post_id': postId,
      'event_type': type.name,
      'watch_duration_ms': watchDurationMs,
      'video_duration_ms': videoDurationMs,
      'referrer': referrer ?? 'fyp',
    });
  }

  // Watch-Time Pulse (nur Video, alle 5s)
  Timer? _watchTimer;
  int _watchedMs = 0;

  void startVideoTracking(String postId, String videoDurationMs, String referrer) {
    _watchedMs = 0;
    track(AnalyticsEventType.view, postId: postId,
      videoDurationMs: videoDurationMs, referrer: referrer);
    _watchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _watchedMs += 5000;
      track(AnalyticsEventType.watchTime,
        postId: postId, watchDurationMs: '$_watchedMs');
    });
  }

  void stopVideoTracking() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }
}
```

### SQL: Collaborative Filtering Query

```sql
-- FYP Query für User mit mindestens 10 Interaktionen
CREATE OR REPLACE FUNCTION get_fyp_feed(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS SETOF posts AS $$
DECLARE
  v_interaction_count INTEGER;
  v_similar_users UUID[];
  v_excluded_ids UUID[];
BEGIN
  -- Check ob genug User-Historie
  SELECT COUNT(*) INTO v_interaction_count
  FROM post_analytics
  WHERE user_id = p_user_id AND event_type IN ('like','comment','share','view');

  IF v_interaction_count < 10 THEN
    -- Cold Start: Nur Popularität
    RETURN QUERY
    SELECT p.* FROM posts p
    JOIN post_scores ps ON p.id = ps.post_id
    WHERE p.deleted_at IS NULL
      AND p.report_status != 'confirmed'
      AND p.created_at > now() - INTERVAL '7 days'
    ORDER BY ps.fyp_score DESC, p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    RETURN;
  END IF;

  -- 1. Finde Top 20 ähnlichste User (Co-Engagement)
  SELECT ARRAY_AGG(user_id ORDER BY overlap DESC)
  INTO v_similar_users
  FROM (
    SELECT l.user_id, COUNT(*) as overlap
    FROM post_analytics l
    JOIN post_analytics my ON l.post_id = my.post_id
      AND my.user_id = p_user_id
      AND my.event_type IN ('like','comment','share')
      AND l.event_type IN ('like','comment','share')
      AND l.user_id != p_user_id
    GROUP BY l.user_id
    ORDER BY overlap DESC
    LIMIT 20
  ) similar;

  -- 2. Bereits gesehene Posts (nicht nochmal zeigen)
  SELECT ARRAY_AGG(DISTINCT post_id)
  INTO v_excluded_ids
  FROM post_analytics
  WHERE user_id = p_user_id
    AND created_at > now() - INTERVAL '7 days';

  -- 3. FYP Score berechnet sich aus post_scores Tabelle
  -- posts von ähnlichen Usern bekommen Bonus
  RETURN QUERY
  SELECT p.*
  FROM posts p
  JOIN post_scores ps ON p.id = ps.post_id
  LEFT JOIN LATERAL (
    SELECT COUNT(*) as su_engagement
    FROM post_analytics a
    WHERE a.post_id = p.id
      AND a.user_id = ANY(v_similar_users)
      AND a.event_type IN ('like','comment','share')
  ) su ON true
  WHERE p.deleted_at IS NULL
    AND p.report_status != 'confirmed'
    AND p.user_id != p_user_id
    AND p.id != ALL(COALESCE(v_excluded_ids, ARRAY[]::UUID[]))
  ORDER BY
    (ps.fyp_score + COALESCE(su.su_engagement * 0.5, 0)) DESC,
    p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
```

---

## Edge Cases & Guardrails

### Anti-Gaming
- Watch-Time < 1 Sekunde → nicht als echte View zählen
- Gleicher User >50% aller Likes eines Posts → als Spam markieren
- Rapider Follow/Unfollow → Follow-Signal wird ignoriert

### Content Safety
- EA-Posts (KI-generiert) → Starten mit FYP-Score * 0.3
- Posts mit 5+ EA-Reports → FYP-Score = 0 bis Review
- Verified Creator (später) → FYP-Bonus von +15%

### Diversity-Regeln
- Max 3 Posts hintereinander vom selben Creator
- Min 20% Content das NICHT im User-Profil-Match liegt (Entdeckung)
- Keine 2 identischen Hashtags in den Top 3 Posts hintereinander

### Recency Curve
```
Stunde 0-6:   × 1.0  (frisch)
Stunde 6-24:  × 0.9
Stunde 24-48: × 0.7
Stunde 48-72: × 0.4
Stunde 72+:   × 0.1
Nach 7 Tagen: × 0.0  (aus FYP entfernt)
```
