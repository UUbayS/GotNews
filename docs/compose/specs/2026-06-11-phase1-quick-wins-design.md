# GotNews Phase 1: Quick Wins Design Spec

**Date**: 2026-06-11
**Status**: Approved
**Scope**: 5 features — Dark Mode, Reading Time, Font Size, Reading History, Progress Bar

---

## [S1] Dark Mode

### Problem
Detail screen uses white background while feed screen is dark. No user preference for theme.

### Solution
Add system-wide dark mode toggle using Flutter's built-in ThemeMode.

### Components
- `ThemeProvider` — `ValueNotifier<ThemeMode>` in `main.dart`, wraps `MaterialApp`
- `SharedPreferences` — persist key `theme_mode` (values: `light`, `dark`, `system`)
- Theme toggle — switch in `edit_profile_screen.dart`

### Behavior
- Default: follow system theme
- User can override to always light or always dark
- All screens respect the active theme (feed, detail, profile, admin, etc.)

### Files to modify
- `frontend/lib/main.dart` — add ThemeProvider, wrap MaterialApp
- `frontend/lib/screens/edit_profile_screen.dart` — add theme toggle UI
- `frontend/lib/screens/news_detail_screen.dart` — use theme colors instead of hardcoded white
- `frontend/lib/screens/feed_screen.dart` — use theme colors instead of hardcoded dark
- All other screens — replace hardcoded colors with theme-aware colors

---

## [S2] Reading Time Indicator

### Problem
User cannot estimate how long an article takes to read before opening it.

### Solution
Calculate and display estimated reading time on feed cards and detail screen.

### Calculation
```
wordCount = (originalContent ?? summary).split(/\s+/).length
readingTime = max(1, ceil(wordCount / 200))
```

### UI Placement
- Feed card: small badge below source name, text "3 min read" in white54 color
- Detail screen: below metadata row, text "Estimated reading time: 3 min"

### Files to modify
- `frontend/lib/models/news_item.dart` — add `int get readingTime` computed property
- `frontend/lib/widgets/news_list_tile.dart` — add reading time badge
- `frontend/lib/screens/feed_screen.dart` — add reading time in card
- `frontend/lib/screens/news_detail_screen.dart` — add reading time in metadata section

---

## [S3] Font Size Adjustment

### Problem
No way to customize text size for comfortable reading.

### Solution
Add font size control in detail screen with persistent preference.

### Options
- 3 presets: Small (14px), Medium (16px), Large (20px)
- Stored in `SharedPreferences` (key: `font_size`, values: `small`, `medium`, `large`)
- Default: `medium`

### UI
- Floating action button or AppBar action in detail screen
- Shows 3 icon buttons: S / M / L
- Applies to article content text only (not title, not metadata)

### Files to modify
- `frontend/lib/screens/news_detail_screen.dart` — add font size selector, apply to content text
- Create `frontend/lib/services/preferences_service.dart` — centralized SharedPreferences access

---

## [S4] Reading History

### Problem
User cannot see which articles they've already read or continue where they left off.

### Solution
Track reading history in database and show read status in UI.

### Database (Prisma)
```prisma
model ReadingHistory {
  id           String   @id @default(cuid())
  userId       String
  articleId    String
  readAt       DateTime @default(now())
  readProgress Float    @default(0) // 0.0 to 1.0
  user         User     @relation(fields: [userId], references: [id])
  article      Article  @relation(fields: [articleId], references: [id])
  @@unique([userId, articleId])
  @@index([userId, readAt(sort: Desc)])
}
```

### Backend Endpoints
- `POST /api/reading-history` — create/update reading record (auth required)
  - Body: `{ articleId: string, readProgress?: number }`
- `GET /api/reading-history?limit=N` — get recent reading history (auth required)
  - Returns: list of articles with readProgress and readAt

### Frontend
- On detail screen `initState`: send POST to record article opened
- On detail screen dispose: update readProgress
- Feed card: show small "✓" checkmark overlay on thumbnail if article is in reading history
- `news_list_tile.dart`: show "✓ Read" text badge

### Files to modify/create
- `backend/prisma/schema.prisma` — add ReadingHistory model
- `backend/src/routes/interaction.ts` — add reading history endpoints
- `frontend/lib/screens/news_detail_screen.dart` — send POST on open, update on dispose
- `frontend/lib/widgets/news_list_tile.dart` — add read badge
- `frontend/lib/screens/feed_screen.dart` — pass read status to cards

---

## [S5] Reading Progress Bar

### Problem
User cannot see how far they've scrolled through a long article.

### Solution
Thin progress bar at top of detail screen showing scroll position.

### UI
- `LinearProgressIndicator` fixed at top of detail screen (above AppBar or inside it)
- Color: blue, height: 3px
- Updates in real-time as user scrolls

### Tracking
- `ScrollController` on `SingleChildScrollView` in `news_detail_screen.dart`
- Calculate: `scrollController.offset / scrollController.position.maxScrollExtent`
- Clamp between 0.0 and 1.0

### Backend Integration
- Save `readProgress` to `ReadingHistory` when user navigates back (dispose)

### Files to modify
- `frontend/lib/screens/news_detail_screen.dart` — add ScrollController, LinearProgressIndicator, save on dispose

---

## [S6] Preferences Service (shared utility)

### Problem
Multiple features need SharedPreferences access. Centralize to avoid duplication.

### Solution
Create a singleton service for all preference reads/writes.

### File
- `frontend/lib/services/preferences_service.dart`

### API
```dart
class PreferencesService {
  static Future<ThemeMode> getThemeMode();
  static Future<void> setThemeMode(ThemeMode mode);
  static Future<String> getFontSize();
  static Future<void> setFontSize(String size);
}
```

---

## Implementation Order

1. **PreferencesService** — foundation for Dark Mode and Font Size
2. **Dark Mode** — ThemeProvider + theme toggle + apply to all screens
3. **Reading Time** — computed property + UI badge
4. **Font Size** — selector UI + apply to detail screen
5. **Reading History** — database model + backend endpoints + frontend tracking
6. **Progress Bar** — ScrollController + progress indicator + save on dispose

## Verification

- Manual test: toggle dark mode, verify all screens change
- Manual test: check reading time shows on feed cards
- Manual test: change font size, verify detail screen text changes
- Manual test: open article, verify reading history is recorded
- Manual test: scroll detail screen, verify progress bar updates
- Run `flutter analyze` to check for lint errors
