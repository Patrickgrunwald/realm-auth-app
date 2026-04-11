# 12 — Design & UI/UX

## Design-System

## Farben

```dart
// app_colors.dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF1A1A2E);      // Dunkelblau/Schwarz
  static const Color primaryLight = Color(0xFF2D2D44);  // Leicht heller

  // Accent
  static const Color accent = Color(0xFF6C63FF);       // Lila-Blau (Instagram-artig)
  static const Color accentLight = Color(0xFF8B85FF);

  // EA / KI Markierung
  static const Color eaAmber = Color(0xFFFFB800);      // Gelb/Amber für EA
  static const Color eaAmberLight = Color(0xFFFFF3CD);
  static const Color eaAmberDark = Color(0xFF856404);

  // Social Colors
  static const Color like = Color(0xFFFF3B5C);         // Rot für Like
  static const Color comment = Color(0xFF8A8A8A);      // Grau
  static const Color share = Color(0xFF8A8A8A);

  // Backgrounds
  static const Color background = Color(0xFF000000);    // Schwarz (TikTok-Style)
  static const Color surface = Color(0xFF1A1A1A);     // Dunkelgrau
  static const Color card = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF6B6B6B);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB800);
}
```

## Typography

```dart
// app_theme.dart
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.accentLight,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  ),
);
```

## Design-Prinzipien

1. **Dark Mode First** — App ist primär dunkel (wie TikTok)
2. **Vollbild-Medien** — Fotos/Videos nehmen den ganzen Screen ein
3. **Minimal UI** — UI-Elemente treten in den Hintergrund
4. **Große Touch-Targets** — Buttons mind. 48x48dp
5. **Prominente EA-Markierung** — Gelb/Amber sticht gegen Schwarz heraus

## Key-UI-Komponenten

### EA-Badge (Gelb auf Dunkel)

```
┌─────────────────────────────────────────┐
│ 🧠 KI-generiert                          │  ← Gelber Hintergrund
│ Dieser Inhalt wurde als KI markiert      │
└─────────────────────────────────────────┘
```

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  decoration: BoxDecoration(
    color: AppColors.eaAmber,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.psychology, color: Colors.black87, size: 20),
      SizedBox(width: 8),
      Text(
        'KI-generiert',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ],
  ),
)
```

### Follow-Button

```
[ Folgen ]        ← Accent-Farbe, ausgefüllt
[ Entfolgen ]     ← Outline, wenn bereits gefolgt
```

### Like-Animation

Wenn User auf ♥ klickt → kurze Animation (Scale + Farbe):
- 0ms: Scale 1.0, grau
- 100ms: Scale 1.3, rot, Icon füllen
- 200ms: Scale 1.0, rot

## Icons

Material Icons verwenden — keine custom Icon-Fonts nötig.

| Element | Icon |
|---|---|
| Feed | `Icons.home` / `Icons.home_outlined` |
| Kamera | `Icons.add_box` |
| Profil | `Icons.person` / `Icons.person_outlined` |
| Like | `Icons.favorite` / `Icons.favorite_border` |
| Kommentar | `Icons.chat_bubble_outline` |
| Teilen | `Icons.ios_share` |
| EA/KI | `Icons.psychology` |
| Suche | `Icons.search` |
| Bell | `Icons.notifications` / `Icons.notifications_outlined` |
| Einstellungen | `Icons.settings` |
| Zurück | `Icons.arrow_back` |
| Menü | `Icons.more_vert` |

## Avatar

- Größe im Post: 32dp
- Profil-Header: 96dp
- Kommentar: 28dp
- Style: `CircleAvatar` mit `CachedNetworkImage`

---

## Nächste Docs

← [11 NAVIGATION](11_NAVIGATION.md)
→ [13 SETUP](13_SETUP.md)
