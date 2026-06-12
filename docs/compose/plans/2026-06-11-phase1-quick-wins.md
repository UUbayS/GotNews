# Phase 1: Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 5 quality-of-life features to GotNews: Dark Mode, Reading Time, Font Size, Reading History, and Progress Bar.

**Architecture:** PreferencesService singleton for shared state, ThemeProvider for dark mode, Prisma model for reading history, ScrollController for progress tracking.

**Tech Stack:** Flutter, SharedPreferences, Prisma ORM, Elysia.js, PostgreSQL

---

## File Structure

```
frontend/lib/
├── main.dart                          (modify — add ThemeProvider)
├── services/
│   ├── preferences_service.dart       (create — centralized prefs)
│   └── news_service.dart              (modify — add reading history API)
├── models/
│   └── news_item.dart                 (modify — add readingTime getter)
├── screens/
│   ├── feed_screen.dart               (modify — reading time badge, read badge)
│   ├── news_detail_screen.dart        (modify — font size, progress bar, reading history)
│   ├── edit_profile_screen.dart       (modify — theme toggle)
│   └── profile_screen.dart            (modify — reading history section)
├── widgets/
│   └── news_list_tile.dart            (modify — reading time, read badge)

backend/prisma/
└── schema.prisma                      (modify — add ReadingHistory model)

backend/src/routes/
└── interaction.ts                     (modify — add reading history endpoints)
```

---

## Task 1: PreferencesService

**Covers:** [S6]

**Files:**
- Create: `frontend/lib/services/preferences_service.dart`

- [ ] **Step 1: Create PreferencesService**

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeModeKey, value);
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  static Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }
}
```

- [ ] **Step 2: Verify import works**

Run: `cd frontend && flutter analyze lib/services/preferences_service.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/services/preferences_service.dart
git commit -m "feat: add PreferencesService for theme and font size"
```

---

## Task 2: Dark Mode — ThemeProvider

**Covers:** [S1]

**Files:**
- Modify: `frontend/lib/main.dart`

- [ ] **Step 1: Read current main.dart**

Read `frontend/lib/main.dart` to understand current structure.

- [ ] **Step 2: Add ValueNotifier theme and load saved preference**

Replace the `main()` function and `GotNewsApp` to include theme support:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
// ... existing imports

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeNotifier.value = await PreferencesService.getThemeMode();
  runApp(const GotNewsApp());
}

class GotNewsApp extends StatelessWidget {
  const GotNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'GotNews',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: const MainLayout(),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/main.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/main.dart
git commit -m "feat: add dark mode theme support with ThemeProvider"
```

---

## Task 3: Dark Mode — Theme Toggle UI

**Covers:** [S1]

**Files:**
- Modify: `frontend/lib/screens/edit_profile_screen.dart`

- [ ] **Step 1: Read current edit_profile_screen.dart**

Read the file to understand current layout.

- [ ] **Step 2: Add theme toggle section**

Add a "Theme" section after the existing profile fields, before the save button:

```dart
import '../main.dart' show themeNotifier;
import '../services/preferences_service.dart';

// Inside build method, add before the save button:
const SizedBox(height: 24),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Appearance',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      const SizedBox(height: 12),
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return Column(
            children: [
              _buildThemeOption(context, 'System', Icons.brightness_auto, ThemeMode.system, currentMode),
              _buildThemeOption(context, 'Light', Icons.light_mode, ThemeMode.light, currentMode),
              _buildThemeOption(context, 'Dark', Icons.dark_mode, ThemeMode.dark, currentMode),
            ],
          );
        },
      ),
    ],
  ),
),

// Add helper method to the State class:
Widget _buildThemeOption(BuildContext context, String label, IconData icon, ThemeMode mode, ThemeMode current) {
  final isSelected = current == mode;
  return ListTile(
    leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
    title: Text(label),
    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
    onTap: () async {
      themeNotifier.value = mode;
      await PreferencesService.setThemeMode(mode);
    },
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
  );
}
```

- [ ] **Step 3: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/screens/edit_profile_screen.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/screens/edit_profile_screen.dart
git commit -m "feat: add theme toggle UI in edit profile screen"
```

---

## Task 4: Dark Mode — Apply to Feed Screen

**Covers:** [S1]

**Files:**
- Modify: `frontend/lib/screens/feed_screen.dart`

- [ ] **Step 1: Replace hardcoded colors with theme-aware colors**

In `_buildNewsCard`, replace:
- `Colors.black` background with `Theme.of(context).scaffoldBackgroundColor`
- Keep the gradient overlay (it works for both themes)
- Replace `Colors.white` text with `Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white`

- [ ] **Step 2: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/screens/feed_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/screens/feed_screen.dart
git commit -m "feat: apply theme-aware colors to feed screen"
```

---

## Task 5: Dark Mode — Apply to Detail Screen

**Covers:** [S1]

**Files:**
- Modify: `frontend/lib/screens/news_detail_screen.dart`

- [ ] **Step 1: Replace hardcoded white with theme colors**

In `build` method:
- `backgroundColor: Colors.white` → `backgroundColor: Theme.of(context).scaffoldBackgroundColor`
- `AppBar` colors → use `Theme.of(context).appBarTheme`
- Text colors → use `Theme.of(context).textTheme`

- [ ] **Step 2: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/screens/news_detail_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/screens/news_detail_screen.dart
git commit -m "feat: apply theme-aware colors to detail screen"
```

---

## Task 6: Reading Time Indicator

**Covers:** [S2]

**Files:**
- Modify: `frontend/lib/models/news_item.dart`
- Modify: `frontend/lib/widgets/news_list_tile.dart`
- Modify: `frontend/lib/screens/feed_screen.dart`
- Modify: `frontend/lib/screens/news_detail_screen.dart`

- [ ] **Step 1: Add readingTime getter to NewsItem**

In `frontend/lib/models/news_item.dart`, add:

```dart
int get readingTime {
  final content = originalContent ?? summary ?? '';
  final wordCount = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return (wordCount / 200).ceil().clamp(1, 60);
}
```

- [ ] **Step 2: Add reading time badge to NewsListTile**

In `frontend/lib/widgets/news_list_tile.dart`, add after the source/time row:

```dart
const SizedBox(height: 4),
Row(
  children: [
    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
    const SizedBox(width: 4),
    Text(
      '${widget.item.readingTime} min read',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    ),
  ],
),
```

- [ ] **Step 3: Add reading time to feed card**

In `frontend/lib/screens/feed_screen.dart`, in `_buildNewsCard`, add after the "Tap to read full story" text:

```dart
const SizedBox(height: 4),
Row(
  children: [
    const Icon(Icons.access_time, size: 14, color: Colors.white54),
    const SizedBox(width: 6),
    Text(
      '${item.readingTime} min read',
      style: const TextStyle(color: Colors.white54, fontSize: 14),
    ),
  ],
),
```

- [ ] **Step 4: Add reading time to detail screen**

In `frontend/lib/screens/news_detail_screen.dart`, in the metadata section, add after the date:

```dart
const SizedBox(height: 8),
Row(
  children: [
    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
    const SizedBox(width: 8),
    Text(
      'Estimated reading time: ${_item.readingTime} min',
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    ),
  ],
),
```

- [ ] **Step 5: Verify no analyze errors**

Run: `cd frontend && flutter analyze`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/models/news_item.dart frontend/lib/widgets/news_list_tile.dart frontend/lib/screens/feed_screen.dart frontend/lib/screens/news_detail_screen.dart
git commit -m "feat: add reading time indicator to feed and detail screens"
```

---

## Task 7: Font Size Adjustment

**Covers:** [S3]

**Files:**
- Modify: `frontend/lib/screens/news_detail_screen.dart`

- [ ] **Step 1: Add font size state and selector UI**

In `_NewsDetailScreenState`, add:

```dart
double _fontSize = 16.0;

@override
void initState() {
  super.initState();
  _item = widget.item;
  _loadFontSize();
}

Future<void> _loadFontSize() async {
  final size = await PreferencesService.getFontSize();
  if (mounted) setState(() => _fontSize = size);
}
```

- [ ] **Step 2: Add font size selector in AppBar actions**

In the `AppBar` `actions` list, add before the existing icons:

```dart
IconButton(
  icon: const Icon(Icons.text_fields, color: Colors.black87),
  onPressed: () => _showFontSizeDialog(),
),
```

- [ ] **Step 3: Add _showFontSizeDialog method**

```dart
void _showFontSizeDialog() {
  showModalBottomSheet(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Font Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _fontSizeOption('S', 14.0, setModalState),
                  _fontSizeOption('M', 16.0, setModalState),
                  _fontSizeOption('L', 20.0, setModalState),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}

Widget _fontSizeOption(String label, double size, StateSetter setModalState) {
  final isSelected = _fontSize == size;
  return GestureDetector(
    onTap: () async {
      setModalState(() => _fontSize = size);
      setState(() => _fontSize = size);
      await PreferencesService.setFontSize(size);
    },
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.8,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Apply font size to content text**

In the content `Text` widget, change `fontSize: 16` to `fontSize: _fontSize`:

```dart
Text(
  _item.originalContent ?? _item.summary,
  style: TextStyle(
    fontSize: _fontSize,
    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
    height: 1.6,
  ),
),
```

- [ ] **Step 5: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/screens/news_detail_screen.dart`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/screens/news_detail_screen.dart
git commit -m "feat: add font size adjustment in detail screen"
```

---

## Task 8: Reading History — Database Model

**Covers:** [S4]

**Files:**
- Modify: `backend/prisma/schema.prisma`

- [ ] **Step 1: Add ReadingHistory model**

Add to `schema.prisma`:

```prisma
model ReadingHistory {
  id           String   @id @default(cuid())
  userId       String
  articleId    String
  readAt       DateTime @default(now())
  readProgress Float    @default(0)
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  article      Article  @relation(fields: [articleId], references: [id], onDelete: Cascade)

  @@unique([userId, articleId])
  @@index([userId, readAt(sort: Desc)])
}
```

Also add to the `User` model:
```prisma
readingHistory ReadingHistory[]
```

And to the `Article` model:
```prisma
readingHistory ReadingHistory[]
```

- [ ] **Step 2: Run migration**

Run: `cd backend && npx prisma migrate dev --name add_reading_history`
Expected: Migration created successfully

- [ ] **Step 3: Commit**

```bash
git add backend/prisma/schema.prisma backend/prisma/migrations
git commit -m "feat: add ReadingHistory model to database"
```

---

## Task 9: Reading History — Backend Endpoints

**Covers:** [S4]

**Files:**
- Modify: `backend/src/routes/interaction.ts`

- [ ] **Step 1: Add POST /api/reading-history endpoint**

Add to `interaction.ts` after the existing like routes:

```typescript
// READING HISTORY
.post('/reading-history', async ({ body, user, set }) => {
  if (!user) {
    set.status = 401
    return { message: 'Unauthorized' }
  }

  const { articleId, readProgress } = body

  const article = await prisma.article.findUnique({ where: { id: articleId } })
  if (!article) {
    set.status = 404
    return { message: 'Article not found' }
  }

  try {
    const history = await prisma.readingHistory.upsert({
      where: {
        userId_articleId: { userId: user.id, articleId }
      },
      update: {
        readAt: new Date(),
        readProgress: readProgress ?? 0,
      },
      create: {
        userId: user.id,
        articleId,
        readProgress: readProgress ?? 0,
      }
    })
    return { success: true, history }
  } catch (e) {
    console.error('[Interaction] ReadingHistory POST error:', e)
    set.status = 400
    return { message: 'Failed to record reading history' }
  }
}, {
  body: t.Object({
    articleId: t.String(),
    readProgress: t.Optional(t.Number()),
  }),
  requireAuth: true
})
```

- [ ] **Step 2: Add GET /api/reading-history endpoint**

```typescript
.get('/reading-history', async ({ query, user, set }) => {
  if (!user) {
    set.status = 401
    return { message: 'Unauthorized' }
  }

  const limit = Math.min(Number(query.limit) || 20, 50)

  const history = await prisma.readingHistory.findMany({
    where: { userId: user.id },
    include: {
      article: {
        include: {
          _count: { select: { likes: true } }
        }
      }
    },
    orderBy: { readAt: 'desc' },
    take: limit,
  })

  const articleIds = history.map(h => h.articleId)
  const userLikes = await prisma.like.findMany({
    where: { userId: user.id, articleId: { in: articleIds } }
  })
  const userBookmarks = await prisma.bookmark.findMany({
    where: { userId: user.id, articleId: { in: articleIds } }
  })
  const likedSet = new Set(userLikes.map(l => l.articleId))
  const bookmarkedSet = new Set(userBookmarks.map(b => b.articleId))

  return {
    data: history.map(h => ({
      id: h.article.id,
      title: h.article.title,
      summary: h.article.summary,
      imageUrl: h.article.imageUrl,
      sourceName: h.article.sourceName,
      category: h.article.category,
      publishedAt: h.article.publishedAt,
      likesCount: h.article._count.likes,
      isLiked: likedSet.has(h.article.id),
      isBookmarked: bookmarkedSet.has(h.article.id),
      readProgress: h.readProgress,
      readAt: h.readAt,
    })),
  }
}, {
  query: t.Object({
    limit: t.Optional(t.String()),
  }),
  requireAuth: true
})
```

- [ ] **Step 3: Verify server starts**

Run: `cd backend && bun dev`
Expected: Server starts without errors (check out.log)

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/interaction.ts
git commit -m "feat: add reading history API endpoints"
```

---

## Task 10: Reading History — Frontend Service

**Covers:** [S4]

**Files:**
- Modify: `frontend/lib/services/news_service.dart`

- [ ] **Step 1: Add reading history methods**

Add to `NewsService` class:

```dart
static Future<void> recordReadingHistory(String articleId, {double readProgress = 0}) async {
  final headers = await _getAuthHeaders();
  if (headers == null) return;

  await http.post(
    Uri.parse('$_baseUrl/reading-history'),
    headers: {...headers, 'Content-Type': 'application/json'},
    body: jsonEncode({'articleId': articleId, 'readProgress': readProgress}),
  );
}

static Future<List<Map<String, dynamic>>> getReadingHistory({int limit = 20}) async {
  final headers = await _getAuthHeaders();
  if (headers == null) return [];

  final response = await http.get(
    Uri.parse('$_baseUrl/reading-history?limit=$limit'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }
  return [];
}
```

- [ ] **Step 2: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/services/news_service.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/services/news_service.dart
git commit -m "feat: add reading history service methods"
```

---

## Task 11: Reading History — Frontend Integration

**Covers:** [S4]

**Files:**
- Modify: `frontend/lib/screens/news_detail_screen.dart`
- Modify: `frontend/lib/widgets/news_list_tile.dart`
- Modify: `frontend/lib/screens/feed_screen.dart`

- [ ] **Step 1: Record reading history on detail screen open**

In `_NewsDetailScreenState.initState`, add:

```dart
@override
void initState() {
  super.initState();
  _item = widget.item;
  _loadFontSize();
  NewsService.recordReadingHistory(_item.id); // Record read
}
```

- [ ] **Step 2: Add read badge to NewsListTile**

Add a `isRead` parameter and show badge:

```dart
class NewsListTile extends StatefulWidget {
  final NewsItem item;
  final VoidCallback? onTap;
  final bool isRead;

  const NewsListTile({super.key, required this.item, this.onTap, this.isRead = false});
```

In the thumbnail section, add overlay:

```dart
if (widget.isRead)
  Positioned(
    top: 4,
    right: 4,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    ),
  ),
```

- [ ] **Step 3: Add read badge to feed card**

In `feed_screen.dart`, in `_buildNewsCard`, add a checkmark overlay on the image:

```dart
// After the CachedNetworkImage widget, add:
Positioned(
  top: 12,
  right: 12,
  child: Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.9),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check, size: 16, color: Colors.white),
  ),
),
```

(Note: This will need a flag to conditionally show — you can add a `_readArticleIds` Set that's populated from reading history)

- [ ] **Step 4: Verify no analyze errors**

Run: `cd frontend && flutter analyze`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/news_detail_screen.dart frontend/lib/widgets/news_list_tile.dart frontend/lib/screens/feed_screen.dart
git commit -m "feat: integrate reading history UI with read badges"
```

---

## Task 12: Reading Progress Bar

**Covers:** [S5]

**Files:**
- Modify: `frontend/lib/screens/news_detail_screen.dart`

- [ ] **Step 1: Add ScrollController and progress tracking**

In `_NewsDetailScreenState`, add:

```dart
final ScrollController _scrollController = ProgressMonitor();
double _readProgress = 0.0;

@override
void dispose() {
  _scrollController.dispose();
  // Save progress on dispose
  NewsService.recordReadingHistory(_item.id, readProgress: _readProgress);
  super.dispose();
}
```

- [ ] **Step 2: Add progress bar UI**

In `build` method, wrap the `SingleChildScrollView` with a `Column` that has the progress bar on top:

```dart
body: Column(
  children: [
    LinearProgressIndicator(
      value: _readProgress,
      backgroundColor: Colors.grey.shade200,
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      minHeight: 3,
    ),
    Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        // ... existing content
      ),
    ),
  ],
),
```

- [ ] **Step 3: Add scroll listener**

In `initState`, add:

```dart
_scrollController.addListener(_onScroll);
```

Add method:

```dart
void _onScroll() {
  if (_scrollController.hasClients) {
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _readProgress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
      });
    }
  }
}
```

- [ ] **Step 4: Verify no analyze errors**

Run: `cd frontend && flutter analyze lib/screens/news_detail_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/news_detail_screen.dart
git commit -m "feat: add reading progress bar to detail screen"
```

---

## Task 13: Final Verification

**Covers:** [S1, S2, S3, S4, S5]

**Files:** None (verification only)

- [ ] **Step 1: Run full Flutter analyze**

Run: `cd frontend && flutter analyze`
Expected: No errors

- [ ] **Step 2: Run backend and verify endpoints**

Run: `cd backend && bun dev`
Expected: Server starts, reading history endpoints respond

- [ ] **Step 3: Manual test checklist**

- [ ] Dark mode toggle works and persists
- [ ] Reading time shows on feed cards and detail screen
- [ ] Font size selector works and persists
- [ ] Reading history is recorded when opening articles
- [ ] Read badge appears on previously read articles
- [ ] Progress bar updates while scrolling
- [ ] Progress saves when leaving detail screen

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address issues from final verification"
```
