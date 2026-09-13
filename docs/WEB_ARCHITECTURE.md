# Kiến trúc hệ thống — Thống Kê 24 Web

## 1. Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│                    Browsers / PWA                        │
│   Next.js 16 (App Router, React 19, Tailwind 4)       │
│   ┌─────────────┐ ┌──────────────┐ ┌───────────────┐   │
│   │ SSR / RSC   │ │ Client shell │ │ Service Worker│   │
│   └──────┬──────┘ └──────┬───────┘ └───────────────┘   │
│          │               │                               │
│   ┌──────▼───────────────▼───────┐                      │
│   │    lib/statistics.ts (pure)  │                      │
│   │    lib/sample-data.ts        │                      │
│   │    lib/lottery-domain.ts     │                      │
│   └──────────────────────────────┘                      │
└──────────────────────┬──────────────────────────────────┘
                       │ fetch
        ┌──────────────▼──────────────┐
        │     Next.js API Routes      │
        │  /api/probability           │
        │  /api/draws                 │
        │  /api/stats/compare         │
        │  /api/admin/import          │
        │  /api/cron/refresh          │
        │  /api/health                │
        └──────────────┬──────────────┘
                       │
        ┌──────────────▼──────────────┐
        │   lib/draws-repository.ts   │
        │   (sample data OR Prisma)   │
        └──────────────┬──────────────┘
                       │
        ┌──────────────▼──────────────┐
        │  PostgreSQL 16 (Prisma ORM) │  ← optional
        └─────────────────────────────┘
```

## 2. Tech Stack

| Thành phần | Phiên bản | Giấy phép |
| --- | --- | --- |
| Next.js | 16.3.5 | MIT |
| React | 19.3.0 | MIT |
| TypeScript | 5.9.3 | Apache-2.0 |
| Tailwind CSS | 4.3.3 | MIT |
| Recharts | 3.10.1 | MIT |
| Zod | 4.6.2 | MIT |
| Prisma | 6.12.0 | Apache-2.0 |
| Lucide React | 1.45.0 | ISC |
| Vitest | 5.0.0 | MIT |
| Playwright | 1.63.0 | Apache-2.0 |
| ESLint | 9.39.5 | MIT |
| PostgreSQL | 16-alpine | PostgreSQL License |

## 3. Data Flow

```

## 4. Mô hình dữ liệu

### Domain Types (client-side)

```typescript
type Region = "Miền Bắc" | "Miền Trung" | "Miền Nam";

type LotteryDraw = {
  id: string; drawCode: string;
  lotteryType: "TRADITIONAL" | "COMBINATION";
  date: string; drawnAt: string;
  region: Region; station: string;
  source: string; collectedAt: string;
  verification: "SAMPLE" | "PENDING" | "VERIFIED" | "REJECTED";
  results: PrizeResult[];
};

type PrizeResult = {
  prize: string; position: number; value: string;
};

type NumberStat = {
  number: string; count: number; drawHits: number;
  rate: number; drawRate: number;
  gap: number | null; averageGap: number | null;
  zScore: number;
  currentStreak: number;
  longestStreak: number;
};
```

### Database (PostgreSQL via Prisma)

```
lottery_draws (id PK, draw_code UNIQUE, lottery_type, region, station,
               drawn_at, source_url, collected_at, verification, created_at)
               INDEX(region, drawn_at DESC)

prize_results (id PK, draw_id FK→lottery_draws ON DELETE CASCADE,
               prize, position, value, last_two VARCHAR(2) INDEX)
               UNIQUE(draw_id, prize, position)

data_imports (id PK, source, imported_at, accepted_rows, duplicate_rows,
              rejected_rows, report JSONB)
```

## 5. API Design

| Method | Path | Auth | Mô tả |
| --- | --- | --- | --- |
| GET | /api/health | None | Status, version, drawCount |
| GET | /api/probability | None | Xác suất (digits, selections, slots) |
| GET | /api/draws | None | Danh sách kỳ + filter |
| GET | /api/stats/compare | None | So sánh 7/30/90/180/365 |
| POST | /api/admin/import | Bearer ADMIN_API_KEY | Validate + persist |
| GET | /api/cron/refresh | Bearer CRON_SECRET | Lấy dữ liệu từ DATA_SOURCE_URL |

### GET /api/draws

Query: `region`, `type`, `station`, `from`, `to`, `limit` (max 100), `offset`.

Response: `{ draws: LotteryDraw[], total: number, hasMore: boolean }`

### GET /api/stats/compare

Query: `region` (default "Miền Bắc").

Response: `{ windows: [{ period, draws, slots, distinct, chiSquare, top, bottom }] }`

### POST /api/admin/import

Header: `Authorization: Bearer <ADMIN_API_KEY>`.
Body: `{ format: "csv"|"json", data: string, region: string }`.

Response: `{ accepted, duplicates, issues, persisted }`

## 6. Component Architecture

```
web/
  app/
    layout.tsx              RootLayout
    page.tsx                → LotteryApp
    api/                    Route Handlers
  components/
    lottery-app.tsx         Shell + nav + filters
    history-view.tsx        History list + detail modal
    compare-view.tsx        Window comparison
    stats-view.tsx          Detailed statistics
    probability-view.tsx    Probability calculator
    number-detail.tsx       Single number deep-dive
    pwa-register.tsx        Service worker
  lib/
    lottery-domain.ts       Types
    statistics.ts           Pure functions
    sample-data.ts          Seeded sample data
    api.ts                  External API client
    draws-repository.ts     Sample OR Prisma
  tests/                    Vitest
  e2e/                      Playwright
  prisma/schema.prisma      DB schema
```

## 7. Deployment

**Local**: `cd web && npm install && npm run dev`
**Docker**: `docker compose up --build` (postgres + api + web)
**Production**: Vercel/Netlify with Root Directory = `web`
**Cron**: `{ "crons": [{ "path": "/api/cron/refresh", "schedule": "0 20 * * *" }] }`

## 8. Biến môi trường

| Biên | Bắt buộc | Mô tả |
| --- | --- | --- |
| NEXT_PUBLIC_API_URL | No | Worker API URL (hiển thị) |
| ADMIN_API_KEY | No | Bearer token cho admin import |
| DATABASE_URL | No | PostgreSQL connection |
| DATA_SOURCE_URL | No | Legal API cho cron |
| CRON_SECRET | No | Secret cho Vercel Cron |

## 9. Security

- Không secret trên frontend (NEXT_PUBLIC_ chỉ cho public).
- ADMIN_API_KEY chỉ server-side.
- Zod validation tại every API boundary.
- CSP: default-src 'self'.
- Không JWT trong frontend web.

CSV/JSON (user upload)
  → parseCsvDraws / parseJsonDraws
  → Zod validation (client + server)
  → validateCsv / validateDraws
  → Report: { valid, duplicates, issues }

Sample data (default)
  → createSampleDraws(365, seed)
  → useState([]) in LotteryApp
  → Filtered by region + type + period → views

API source (optional)
  → DATA_SOURCE_URL + cron/refresh
  → Zod validation → Prisma upsert → PostgreSQL
```
