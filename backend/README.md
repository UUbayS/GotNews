# GotNews (Backend)

Backend API untuk GotNews — dibangun dengan Bun + Elysia + Prisma + PostgreSQL.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Runtime** | Bun |
| **Framework** | Elysia |
| **ORM** | Prisma |
| **Database** | PostgreSQL |
| **Auth** | JWT (access token 1h + refresh token 7d) |
| **AI** | Groq (Llama 3.3 70B) |
| **News Source** | NewsData.io |

## Getting Started

### Prasyarat

- Bun
- PostgreSQL

### Install

```bash
cd backend
bun install
```

### Environment Variables

Buat file `.env` di `backend/`:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/gotnews?schema=public"
JWT_SECRET="your-secret-key-change-in-prod"
GROQ_API_KEY="your-groq-api-key"
NEWSDATA_API_KEY="your-newsdata-api-key"
NEWSAPI_KEY="your-newsapi-key"
AI_PROVIDER="groq"
```

### Database

```bash
# Jalankan migrasi Prisma
npx prisma migrate dev

# Setup full-text search PostgreSQL
bun run-migration.ts

# Seed admin user
bun seed
```

### Run

```bash
bun dev
```

Server berjalan di `http://localhost:3000`.

## API Endpoints

Lihat root [README.md](../README.md) untuk daftar lengkap API endpoints.

## Struktur

```
src/
├── index.ts                  # Entry point — Elysia app + cron jobs
├── routes/
│   ├── auth.ts               # Register, login, refresh, profile
│   ├── feed.ts               # Cursor-paginated feed
│   ├── search.ts             # Full-text search
│   ├── interaction.ts        # Like & bookmark
│   ├── ai.ts                 # Summarize & AI chat
│   └── admin.ts              # Dashboard, user/article/source management
├── middleware/
│   └── auth.ts               # JWT validation plugin
├── services/
│   ├── news-fetcher.ts       # NewsData.io client
│   ├── scraper.ts            # Article content extraction
│   ├── summarizer.ts         # Groq AI summarization
│   └── ai-chat.ts            # Groq chat
├── jobs/
│   └── sync-news.ts          # Scheduled news sync
├── lib/
│   ├── prisma.ts             # Prisma client singleton
│   ├── cursor.ts             # Cursor pagination helper
│   ├── password.ts           # Argon2id hashing
│   └── rate-limit.ts         # Rate limiter
└── seed.ts                   # Admin user seeder

prisma/
└── schema.prisma             # Database schema
```

## Default Admin

| Field | Value |
|-------|-------|
| Email | `admin@gotnews.com` |
| Username | `admin` |
| Password | `admin123` |

## Postman

Import `GotNews_API_collection.json` untuk koleksi API siap pakai dengan auto-token management.
