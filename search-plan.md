# Plan: Full-Stack Search Feature

## Current State
- **Backend**: `Article` model has unused `searchVector tsvector` column. No search endpoint exists.
- **Frontend**: Explore & Bookmark screens have cosmetic search bars with no handlers. `NewsService` has no search method.
- **DB**: PostgreSQL with Prisma ORM.

---

## Approach

### Backend — New search route

**New file**: `backend/src/routes/search.ts`
- `GET /api/search` with params: `q`, `category`, `language`, `cursor`, `limit`
- Prisma `contains` / `mode: 'insensitive'` on `title` and `summary`
- Reuse cursor pagination + user likes/bookmarks hydration from `feed.ts`

**Modified file**: `backend/src/index.ts`
- Register search route

### Frontend — Wire search bars + API

**Modified file**: `frontend/lib/services/news_service.dart`
- Add `searchNews()` method → `GET /api/search`

**Modified file**: `frontend/lib/screens/explore_screen.dart`
- `onSubmitted` → call API, show results
- Clear button → reset to default view
- Category tabs still work with search

**Modified file**: `frontend/lib/screens/bookmark_screen.dart`
- `onChanged` → local client-side filtering on title/summary/sourceName

---

## Files

| # | File | Action |
|---|------|--------|
| 1 | `backend/src/routes/search.ts` | CREATE |
| 2 | `backend/src/index.ts` | EDIT (1 line) |
| 3 | `frontend/lib/services/news_service.dart` | EDIT |
| 4 | `frontend/lib/screens/explore_screen.dart` | EDIT |
| 5 | `frontend/lib/screens/bookmark_screen.dart` | EDIT |
