# 📱 GotNews

> **GotNews** adalah aplikasi pembaca berita modern bergaya *TikTok* (infinite vertical scroll) yang dilengkapi dengan ringkasan bertenaga AI secara real-time dan kurasi berita personal berdasarkan minat pengguna. 

Aplikasi ini dirancang dengan arsitektur modern berkinerja tinggi menggunakan **Flutter** di sisi mobile dan **Elysia.js** (berbasis Bun) di sisi backend dengan **Prisma ORM** + **PostgreSQL** untuk pengelolaan basis data yang cepat dan andal.

---

## 🏗️ Arsitektur Sistem & Aliran Data

Untuk memberikan pemahaman yang jelas tentang bagaimana GotNews bekerja, berikut adalah visualisasi aliran data antar komponen:

```mermaid
graph TD
    subgraph Frontend (Client)
        A[Flutter Mobile App]
    end

    subgraph Backend (Server)
        B[Elysia.js Server]
        C[Prisma Client]
        F[Cron Jobs]
    end

    subgraph Database
        D[(PostgreSQL Database)]
    end

    subgraph External Services
        E[Groq AI Llama 3.3]
        G[NewsData.io API]
    end

    A <-->|HTTP / JWT Auth| B
    B <--> C
    C <--> D
    F -->|Sync News tiap 30m| G
    B -->|AI Summarize & Chat| E
```

---

## 🌟 Fitur Utama & Cara Kerjanya

### 1. TikTok-Style Infinite Scroll
* **Bagaimana cara kerjanya?** Berita disajikan secara vertikal mirip dengan video pendek. Aplikasi menggunakan **Cursor-based Pagination** (menggunakan kombinasi `createdAt` dan `id` artikel sebagai pointer cursor) untuk memastikan transisi pemuatan berita sangat halus dan menghindari duplikasi berita saat ada berita baru masuk.

### 2. Personalized Feed (Umpan Kustom)
* **Bagaimana cara kerjanya?** Sistem melacak kategori berita yang paling sering disimpan (bookmarked) oleh pengguna. Saat pengguna memuat Feed, algoritma backend akan memberikan bobot (*boost*) lebih tinggi pada artikel dengan kategori favorit tersebut, meletakkannya di posisi atas umpan berita.

### 3. On-Demand AI Summarization (Groq AI)
* **Bagaimana cara kerjanya?** Untuk menghemat kuota API dan meningkatkan performa, ringkasan AI diproses secara *on-demand* (saat tombol ringkasan ditekan). Hasil ringkasan disimpan ke kolom `aiSummary` pada database sebagai cache. Request berikutnya akan langsung membaca cache, kecuali admin memilih opsi *force-regenerate*.

### 4. Admin Management Console & News Filter
* **Bagaimana cara kerjanya?** Administrator memiliki tab khusus untuk melihat statistik, mempromosikan/menghapus pengguna, menyunting artikel, serta mengelola sumber berita. Jika admin menonaktifkan suatu sumber berita (`isActive: false`), sikronisasi berita otomatis (cron job tiap 30 menit) akan melewati artikel dari sumber tersebut secara real-time.

---

## 🛠️ Tech Stack

| Layer | Teknologi | Deskripsi |
|-------|-----------|-----------|
| **Frontend** | 💙 Flutter | Android & iOS client (Provider state management) |
| **Backend** | 🦊 Elysia.js | TypeScript Web Framework cepat berbasis Bun runtime |
| **ORM** | 💎 Prisma ORM | Pemetaan objek ke database relasional secara type-safe |
| **Database** | 🐘 PostgreSQL | Penyimpanan data relasional dengan indeks pencarian cepat |
| **AI Engine** | 🤖 Groq SDK | Penyedia LLM tercepat menggunakan model *Llama 3.3 70B* |
| **News API** | 📰 NewsData.io | Sumber data penarikan berita real-time |

---

## 📋 API Endpoints

Semua endpoint backend terdokumentasi dengan baik di bawah ini. Endpoint admin memerlukan header otentikasi admin yang valid.

### 🔐 Auth
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | - | Registrasi akun baru |
| POST | `/api/auth/login` | - | Login akun (kembalikan JWT Token & User Info) |
| POST | `/api/auth/refresh` | - | Mengambil Access Token baru menggunakan Refresh Token |
| GET | `/api/auth/me` | ✓ | Mengambil profil pengguna aktif |
| POST | `/api/auth/logout` | ✓ | Logout & batalkan validitas token saat ini |
| PUT | `/api/auth/profile` | ✓ | Mengubah informasi profil pengguna |

### 📰 Feed & Search
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-------------|
| GET | `/api/feed` | - | Mengambil umpan berita (mendukung personalisasi & cursor) |
| GET | `/api/search` | - | Pencarian berita berbasis teks dengan filter kategori & bahasa |

### 💬 Interactions
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-------------|
| POST | `/api/articles/:id/like` | ✓ | Menyukai artikel |
| DELETE | `/api/articles/:id/like` | ✓ | Batal menyukai artikel |
| POST | `/api/articles/:id/bookmark` | ✓ | Menyimpan artikel ke bookmark |
| DELETE | `/api/articles/:id/bookmark` | ✓ | Menghapus artikel dari bookmark |
| GET | `/api/bookmarks` | ✓ | Mengambil daftar artikel yang dibookmark |

### 🤖 AI (Groq Engine)
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-------------|
| POST | `/api/articles/:id/summarize` | ✓ | Membuat ringkasan berita bertenaga AI (dukung caching) |
| POST | `/api/chat` | ✓ | Bertanya jawab dengan AI mengenai isi konten berita tertentu |

### 👑 Admin Console
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-------------|
| GET | `/api/admin/stats` | Admin | Mengambil data statistik ringkas untuk dashboard |
| GET/POST | `/api/admin/sync` | Admin | Memicu penarikan berita manual dari NewsData API |
| GET | `/api/admin/users` | Admin | Mengambil daftar semua pengguna terdaftar |
| PUT | `/api/admin/users/:id/promote` | Admin | Mengangkat pengguna biasa menjadi Administrator |
| PUT | `/api/admin/users/:id/demote` | Admin | Menurunkan Administrator kembali menjadi pengguna biasa |
| DELETE | `/api/admin/users/:id` | Admin | Menghapus akun pengguna dari database |
| GET | `/api/admin/articles` | Admin | Mengambil daftar artikel (dukung filter, search, & pagination) |
| PUT | `/api/admin/articles/:id` | Admin | Mengubah detail konten berita |
| DELETE | `/api/admin/articles/:id` | Admin | Menghapus artikel |
| POST | `/api/admin/articles/bulk-delete` | Admin | Menghapus artikel massal (berdasarkan ID atau Sumber) |
| POST | `/api/admin/articles/:id/sync-ai-summary` | Admin | Menggenerasi ulang ringkasan AI untuk satu artikel |
| GET | `/api/admin/sources` | Admin | Mengambil semua daftar sumber berita |
| POST | `/api/admin/sources` | Admin | Mendaftarkan sumber berita baru |
| PUT | `/api/admin/sources/:id` | Admin | Mengubah status aktif/non-aktif atau bahasa sumber berita |
| DELETE | `/api/admin/sources/:id` | Admin | Menghapus sumber berita dari database |

---

## 🚀 Memulai Instalasi

### Prasyarat
Sebelum memulai, pastikan perangkat Anda telah terinstal:
* **Bun Runtime** (untuk backend)
* **PostgreSQL** (untuk basis data)
* **Flutter SDK** (untuk mobile app)

---

### Langkah 1: Kloning & Instal Dependensi

```bash
# Clone repositori
git clone https://github.com/UUbayS/GotNews.git
cd GotNews

# Instal dependensi Backend
cd backend
bun install

# Instal dependensi Frontend
cd ../frontend
flutter pub get
```

---

### Langkah 2: Konfigurasi Environment (Backend)

Buat file baru bernama `.env` di dalam folder `backend/` dan isi sebagai berikut:

```env
DATABASE_URL="postgresql://username:password@localhost:5432/newsscroll?schema=public"

JWT_SECRET="masukkan-kunci-rahasia-jwt-anda"
GROQ_API_KEY="masukkan-api-key-groq-anda"
NEWSDATA_API_KEY="masukkan-api-key-newsdata-anda"
AI_PROVIDER="groq"
```

---

### Langkah 3: Setup Basis Data

Jalankan perintah berikut di folder `backend/` untuk menerapkan migrasi tabel dan melakukan seeding akun Administrator pertama:

```bash
# Terapkan skema tabel ke database
npx prisma migrate dev

# Alternatif (jika migrasi error karena shadow database):
# bun x prisma db push

# Buat indeks pencarian teks (Full-Text Search)
bun run run-migration.ts

# Jalankan script seed untuk membuat akun admin default
bun run seed
```

> [!TIP]
> Akun Admin Default setelah menjalankan seed:
> * **Email**: `admin@gotnews.com`
> * **Username**: `admin`
> * **Password**: `admin123`

---

### Langkah 4: Jalankan Server Backend

```bash
cd backend
bun dev
```
Server akan berjalan di alamat `http://localhost:3000`.

---

### Langkah 5: Jalankan Aplikasi Mobile (Frontend)

Hubungkan perangkat Android Anda via USB atau nyalakan emulator, lalu jalankan perintah:

**Uji Coba di Perangkat Fisik Android:**
```bash
# Teruskan port server agar bisa diakses hp
adb reverse tcp:3000 tcp:3000

# Jalankan aplikasi
cd frontend
flutter run
```

* **Android Emulator**: Base URL otomatis mendeteksi alamat IP `10.0.2.2:3000` (tidak perlu menjalankan `adb reverse`).
* **iOS Simulator**: Base URL otomatis mendeteksi alamat IP `localhost:3000`.

---

## 📂 Struktur Folder Proyek

Untuk mempermudah navigasi, berikut adalah struktur folder utama dari repositori GotNews:

```
GotNews/
├── backend/                  # Sisi Server (Elysia.js + Prisma)
│   ├── src/
│   │   ├── index.ts          # Entry point server utama
│   │   ├── routes/           # Router API (Auth, Admin, AI, Interaction, dll.)
│   │   ├── middleware/       # JWT Auth validator & macro
│   │   ├── services/         # Integrasi API (NewsData, Scraper, Groq AI)
│   │   ├── jobs/             # Penjadwalan Cron Job (News Sync tiap 30m)
│   │   ├── lib/              # Helpers (Prisma client, password hashing, cursor)
│   │   └── seed.ts           # Script CLI seeding database
│   ├── prisma/               # Skema database & file migrasi
│   └── package.json
│
└── frontend/                 # Sisi Mobile Client (Flutter App)
    ├── lib/
    │   ├── main.dart         # Entry point aplikasi Flutter
    │   ├── models/           # Data model objek (User, NewsItem)
    │   ├── services/         # Penghubung API client (Auth, News, Admin)
    │   ├── screens/          # Halaman aplikasi (Feed, Login, Admin Dashboard, dll.)
    │   └── widgets/          # Komponen UI reusable (News Tile)
    └── pubspec.yaml          # Konfigurasi package flutter
```

---

## 💾 Skema Tabel Database

Aplikasi ini menggunakan 5 tabel utama pada PostgreSQL:

1. **User**: Menyimpan data akun pengguna, foto avatar, data diri, serta peran (`role: user | admin`).
2. **Article**: Menyimpan data berita hasil tarikan API beserta ringkasan bawaan dan `aiSummary` cache dari Groq. Menampung data `tsvector` untuk optimasi pencarian teks.
3. **Bookmark**: Relasi banyak-ke-banyak antara `User` dan `Article` (untuk riwayat simpan berita).
4. **Like**: Relasi banyak-ke-banyak antara `User` dan `Article` (untuk mencatat suka).
5. **NewsSource**: Menyimpan status keaktifan sumber berita luar (digunakan sebagai *gatekeeper* saat sinkronisasi otomatis).
6. **InvalidatedToken**: Tempat mendaftar token JWT yang telah di-logout sebelum masa kedaluwarsanya habis.

---

## 📬 Postman Collection

Berkas postman tersedia pada folder `backend/GotNews_API_collection.json`. Anda cukup mengimpor berkas tersebut ke Postman untuk langsung menguji seluruh endpoint API lengkap dengan manajemen token otentikasi otomatis.
