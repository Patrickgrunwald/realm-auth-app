# 02 — Datenbank-Schema

## Supabase Projekt

**Projekt-URL:** `https://YOUR_PROJECT.supabase.co`
**Datenbank:** PostgreSQL 15+

---

## ER-Diagramm

```
┌────────────┐       ┌────────────┐       ┌────────────┐
│   users    │       │   posts    │       │   likes    │
├────────────┤       ├────────────┤       ├────────────┤
│ id (PK)    │──┐    │ id (PK)    │       │ id (PK)    │
│ username   │  │    │ user_id(FK)│──┐    │ user_id(FK)│──┐
│ email      │  └───→│ type       │  │    │ post_id(FK)│  │
│ avatar_url │       │ media_url  │  │    └────────────┘  │
│ bio        │       │ caption    │  │          │          │
│ created_at │       │ is_ea_*    │  │          ▼          │
└────────────┘       │ likes_count│  │    ┌────────────┐  │
      │               │ created_at│  │    │ comments   │  │
      │               └───────────┘  │    ├────────────┤  │
      │                 │            │    │ id (PK)    │  │
      ▼                 ▼            │    │ user_id(FK)│──┘
┌────────────┐  ┌────────────┐     │    │ post_id(FK)│──┐
│  follows   │  │ ea_reports  │     │    │ content    │  │
├────────────┤  ├────────────┤     │    └────────────┘  │
│ follower_id│  │ post_id(FK)│     │          │          │
│ following_ │  │ reporter_id│─────┘          ▼          │
│   id       │  │ reason     │          ┌────────────┐  │
│ created_at │  │ created_at │          │     ???    │  │
└────────────┘  └────────────┘          └────────────┘  │
      │                                       │         │
      ▼                                       ▼         │
┌────────────┐                         ┌────────────┐   │
│notificatio │                         │    ???     │   │
├────────────┤                         └────────────┘   │
│ user_id(FK)│──────────────────────────────────────────┘
│ type       │
│ actor_id   │
│ post_id    │
│ read       │
│ created_at │
└────────────┘
```

---

## Tabellen

### users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (length(username) BETWEEN 3 AND 20),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT CHECK (length(bio) <= 150),
  followers_count INTEGER NOT NULL DEFAULT 0,
  following_count INTEGER NOT NULL DEFAULT 0,
  posts_count INTEGER NOT NULL DEFAULT 0,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### posts
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('photo', 'video')),
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT CHECK (length(caption) <= 500),
  is_ea_content BOOLEAN NOT NULL DEFAULT false,
  is_ai_confirmed BOOLEAN NOT NULL DEFAULT false,
  ea_report_count INTEGER NOT NULL DEFAULT 0,
  likes_count INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  shares_count INTEGER NOT NULL DEFAULT 0,
  report_status TEXT NOT NULL DEFAULT 'none'
    CHECK (report_status IN ('none', 'pending', 'confirmed', 'rejected')),
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### likes
```sql
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, post_id)
);
```

### comments
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (length(content) BETWEEN 1 AND 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### follows
```sql
CREATE TABLE follows (
  follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id != following_id)
);
```

### ea_reports
```sql
CREATE TABLE ea_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(post_id, reporter_id)
);
```

### notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'ea_resolved', 'ea_confirmed')),
  actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Indexes

```sql
-- Posts: Feed-Queries beschleunigen
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_report_status ON posts(report_status) WHERE deleted_at IS NULL;

-- Likes: Check ob User bereits geliked hat
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);

-- Comments
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_created_at ON comments(created_at ASC);

-- Follows
CREATE INDEX idx_follows_following_id ON follows(following_id);
CREATE INDEX idx_follows_follower_id ON follows(follower_id);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read) WHERE read = false;
```

---

## Row Level Security (RLS)

### Policy-Matrix

| Tabelle | Operation | Wer |
|---|---|---|
| users | SELECT | Alle (öffentliche Profile) |
| users | UPDATE | Nur eigene Zeile (user_id = auth.uid()) |
| users | INSERT | Nur via Trigger bei Registrierung |
| posts | SELECT | Alle, ABER: keine gelöschten Posts |
| posts | INSERT | Authenticated Users |
| posts | UPDATE | Nur Owner's Posts (für likes_count etc.) |
| posts | DELETE | Owner ODER Admin |
| likes | SELECT | Alle |
| likes | INSERT | Authenticated, 1x pro User/Post |
| likes | DELETE | Owner |
| comments | SELECT | Alle |
| comments | INSERT | Authenticated |
| comments | DELETE | Owner |
| follows | SELECT | Alle |
| follows | INSERT | Authenticated |
| follows | DELETE | Owner |
| ea_reports | SELECT | Nur Admins |
| ea_reports | INSERT | Authenticated, 1x pro User/Post |
| notifications | SELECT | Nur eigene (user_id = auth.uid()) |
| notifications | UPDATE | Nur eigene |

### RLS SQL (vereinfacht)

```sql
-- Posts lesen (nur nicht-gelöschte)
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Posts sind öffentlich" ON posts
  FOR SELECT USING (deleted_at IS NULL);

-- Posts erstellen (nur eingeloggte)
CREATE POLICY "Auth Nutzer können posten" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Posts updaten (nur Owner)
CREATE POLICY "Owner kann eigene Posts updaten" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

-- Likes lesen
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Likes sind öffentlich" ON likes FOR SELECT USING (true);

-- Likes erstellen
CREATE POLICY "Auth Nutzer können liken" ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notifications nur eigene
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Nur eigene Notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);
```

---

## Trigger

### posts_count aktuell halten

```sql
-- Nach neuem Post
CREATE OR REPLACE FUNCTION update_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_insert
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION update_posts_count();
```

### follow_counts aktuell halten

```sql
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.following_id;
    UPDATE users SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follow_change
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION update_follow_counts();
```

### Neuem User → users-Eintrag erstellen

```sql
-- Automatisch wenn sich jemand über Supabase Auth registriert
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, email, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## Nächste Docs

← [01 ARCHITECTURE](01_ARCHITECTURE.md)
→ [03 API](03_API.md) — Edge Functions, REST-Endpoints
