# PROMPT MASTER PLAN — XSMB Manager "Thống Kê 24"

> **Mục đích**: Prompt tổng hợp để Cline/Codex/AI agent hoàn thiện toàn bộ ứng dụng "Thống Kê 24", tích hợp free services best-in-market, và thiết lập database chuẩn mực.

---

## 🧑‍💻 VAI TRÒ

Bạn là **kiến trúc sư phần mềm senior + full-stack developer + DevOps + UI/UX designer + chuyên gia thống kê xác suất**. Bạn sẽ triển khai, nâng cấp và hoàn thiện hệ thống xsmb-manager — monorepo chứa:

| Thư mục | Nội dung | Tech |
|---|---|---|
| `web/` | PWA "Thống Kê 24" | Next.js 16, React 19, Tailwind 4, Recharts, Prisma |
| `backend/` | Streamlit + FastAPI | Python 3.12, SQLAlchemy, PostgreSQL |
| `worker/` | Edge API | Cloudflare Workers, R2, D1 |
| `mobile/` | Android + Web app | Flutter 3.x, SQLite, Provider chain |
| `scripts/` | Pipeline, migration, proxy | Python, PowerShell |

---

## 🎯 MỤC TIÊU

### 1. Hoàn thiện Web "Thống Kê 24"

Ứng dụng thống kê & giáo dục xổ số 18+, mobile-first, nền tối, nhấn vàng/đỏ, chuyển động nhẹ, tiếng Việt.

**8 màn hình cần hoàn thiện:**

1. **Tổng quan** — KPI cards, kỳ mới nhất, nhóm nổi bật (nhiều/ít/lâu), heatmap 00–99, xu hướng 30 kỳ, so sánh nhanh 7–365
2. **Phân tích** — Nhập/tạo bộ số, hồ sơ tần suất/z-score/Wilson/streak, lưu yêu thích (localStorage), so sánh tối đa 4 bộ
3. **Quay thử** — Mô phỏng minh bạch, Web Crypto seed, hiển thị MCRA
4. **Lịch sử** — Bảng cuộn vô hạn, bộ lọc ngày/đài/miền/loại, modal chi tiết kỳ
6. **Thống kê** — Tần suất 0–9, heatmap đầu–đuôi, tổng/chẵn-lẻ/khoảng, cặp/bộ ba/chuỗi, ngày trong tuần
6. **So sánh** — Bảng side-by-side 7/30/90/180/365, overlay chart
7. **Xác suất** — Tính xác suất 2–6 chữ số, tổ hợp, EV, Monte Carlo, Wilson CI, chi bình phương
8. **Kho dữ liệu** — Nguồn + trạng thái, nhập CSV/JSON, validation report

### 2. Tích hợp free services best-in-market
### 3. Thiết lập database chuẩn mực

---

## 🛠 TECH STACK (GIỮ NGUYÊN — KHÔNG thay framework)

| Thành phần | Phiên bản | Vai trò |
|---|---|---|
| Next.js | 16.3.5 | Web framework (App Router) |
| React | 19.3.0 | UI library |
| TypeScript | 5.9.3 | Type safety |
| Tailwind CSS | 4.3.3 | Styling |
| Recharts | 3.10.1 | Charts |
| Zod | 4.6.2 | Validation |
| Prisma | 6.12.0 | ORM |
| Lucide React | 1.45.0 | Icons |
| Vitest | 5.0.0 | Unit testing |
| Playwright | 1.63.0 | E2E testing |
| Python | 3.12 | Backend |
| FastAPI | 0.115+ | REST API |
| SQLAlchemy | 2.0+ | Python ORM |
| PostgreSQL | 16 | Database |
| Cloudflare Workers | - | Edge API |
| Flutter | 3.x | Mobile |
| Cloudflare R2 | - | Object storage |

---

## 🌐 FREE SERVICES — TẤT CẢ ĐANG HOT 2026

### Tier 1: Hosting & Deployment

#### 1.1 Vercel (Web Frontend + API Routes)
- **Dùng cho**: Deploy `web/` (Next.js PWA)
- **Free tier**: 100 GB bandwidth, Serverless Functions, Edge Network, Analytics
- **Cấu hình deploy**: Root Directory = `web`, Framework = Next.js
- **Build**: `prisma generate && next build`
- **Vercel Cron**: 1 lần/ngày (Hobby), schedule `"0 20 * * *"` cho `/api/cron/maintain`
- **Analytics + Speed Insights**: Đã tích hợp trong `layout.tsx`

#### 1.2 Cloudflare Workers (Edge API)
- **Free tier**: 100k requests/ngày
- **Đã cấu hình**: `worker/wrangler.jsonc` với R2 binding, Cron triggers
- **Endpoints**: `/v1/health`, `/v1/xsmb/*`, `/v1/xsmn/*`, `/v1/config`

#### 1.3 Railway / Render (Backend API backup)
- **Railway**: Free $5/tháng, `railway.toml` đã có
- **Render**: Free, auto-sleep, `render.yaml` đã có

### Tier 2: Database

#### 2.1 Neon PostgreSQL (PRIMARY — best choice cho Next.js)
- **Free tier**: 0.5 GB, 24/7 compute (beta), auto-branching
- **Tại sao neon**: Serverless PG chuẩn, connection pooling built-in, scale-to-zero, auto-backup, Prisma 100% compatible
- **Setup**: Đăng ký neon.tech → tạo project → copy DATABASE_URL → set trên Vercel → `npx prisma db push`

#### 2.2 Supabase (Alternative — tốt nếu cần auth.future)
- **Free tier**: 500 MB DB, 1 GB storage
- **Khi nào dùng**: Cần auth, realtime, file storage
- **URI format**: `postgresql+psycopg://USER:PASS@HOST:5432/postgres?sslmode=require`

#### 2.3 Cloudflare D1 (Cho Worker — tương lai)
- **Free**: 5 GB, 10M reads/ngày
- **Trạng thái**: Đã binding trong wrangler.jsonc, Worker hiện đọc snapshot JSON

### Tier 3: Caching — Upstash Redis
- **Free**: 10k commands/ngày, 256 MB
- **Dùng cho**: Cache thống kê phổ biến, rate limiting API

### Tier 4: Monitoring — Sentry + Vercel Analytics
- **Sentry free**: 5k errors/ngày → `npx @sentry/wizard@latest -i nextjs`
- **Vercel Analytics**: Đã tích hợp, miễn phí không giới hạn

### Tier 5: CI/CD — GitHub Actions
- **Free**: 2000 phút/tháng → Python test + Web check + Flutter analyze

### Tier 6: Storage — Cloudflare R2 + GitHub Raw
- **R2 free**: 10 GB → Bucket `xsmb-data` đã cấu hình
- **GitHub Raw**: Unlimited → `public-data/` snapshot

### Tier 7: Proxy — Proxy Pool + 9Router

---

## 🗃 DATABASE DESIGN — CHUẨN MỰC

### Strategy: Dual-database

| Component | Database | ORM | Purpose |
|---|---|---|---|
| Web (Next.js) | Neon PostgreSQL | Prisma 6.12 | Reads + writes, API routes |
| Backend (FastAPI) | Same PostgreSQL | SQLAlchemy 2.0 | Sync, admin, auth |
| Worker (CF Workers) | R2 + bundled JSON | Native | Read-only snapshots |
| Mobile (Flutter) | SQLite local | drift/sqflite | Offline cache |

### Web Schema (Prisma — hiện tại đã tốt, thêm 2 model)

**Models hiện có** (giữ nguyên): LotteryDraw, PrizeResult, NumberTrend, DataImport

**Models cần thêm:**

```prisma
model AnalyticsCache {
  id        String   @id @default(uuid()) @db.Uuid
  cacheKey  String   @unique @map("cache_key") @db.VarChar(255)
  data      Json
  region    String   @db.VarChar(20)
  period    Int
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(3)
  expiresAt DateTime @map("expires_at") @db.Timestamptz(3)
  @@index([cacheKey])
  @@index([region, period])
  @@index([expiresAt])
  @@map("analytics_cache")
}

model AuditLog {
  id        String   @id @default(uuid()) @db.Uuid
  action    String   @db.VarChar(100)
  entity    String   @db.VarChar(100)
  entityId  String?  @map("entity_id") @db.Uuid
  details   Json?
  ipAddress String?  @map("ip_address") @db.VarChar(45)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(3)
  @@index([action])
  @@index([entity])
  @@index([createdAt])
  @@map("audit_logs")
}
```

### Backend Schema (SQLAlchemy — đầy đủ)

- `users` — JWT auth (username, password_hash, is_admin)
- `draws` + `results` — XSMB (PK = draw_date, 27 results/draw)
- `mn_draws` + `mn_results` — XSMN (PK = draw_date + province, 18 results/draw)
- `sync_log` — Audit trail per sync operation
- `source_health` — Latency/success rate per provider
- `backup_sync_state` — Track backup imports

### Database Best Practices

1. **Connection Pooling**: Prisma built-in + SQLAlchemy `pool_pre_ping=True, pool_size=5`
2. **SSL**: Luôn `sslmode=require` trong production
3. **Backups**: Neon auto-backup daily (free), Supabase weekly
4. **Migrations**: Web `npx prisma migrate dev`, Backend `Base.metadata.create_all`
5. **Retention**: Cron xóa > 370 ngày (`DATA_RETENTION_DAYS`)
6. **Cascade**: LotteryDraw delete → PrizeResult/NumberTrend auto-delete
7. **UUID PKs**: Non-sequential, secure, no contention
8. **TIMESTAMPTZ**: Timezone-aware timestamps everywhere


---

## 📋 CÔNG VIỆC CẦN LÀM — PRIORITY ORDER

### Phase 1: Hoàn thiện Web Core (Ưu tiên #1)

#### 1.1 API Routes cần review

| Route | File | Trạng thái |
|---|---|---|
| GET /api/draws | `web/app/api/draws/route.ts` | ✅ CÓ — review fallback chain |
| GET /api/health | `web/app/api/health/route.ts` | ✅ CÓ — review response format |
| GET /api/probability | `web/app/api/probability/route.ts` | ✅ CÓ — review calculation |
| GET /api/stats/compare | `web/app/api/stats/compare/route.ts` | ✅ CÓ — review SQL queries |
| GET /api/stats/trend | `web/app/api/stats/trend/range.ts` | ✅ CÓ — review trend logic |
| POST /api/admin/import | `web/app/api/admin/import/route.ts` | ✅ CÓ — review validation |
| POST /api/admin/seed | `web/app/api/admin/seed/route.ts` | ✅ CÓ — review seed logic |
| POST /api/admin/seed-trends | `web/app/api/admin/seed-trends/range.ts` | ✅ CÓ — review trend seeding |
| GET /api/cron/maintain | `web/app/api/cron/maintain/range.ts` | ✅ CÓ — review retention |

#### 1.2 Server-side Code cần review

| File | Vai trò |
|---|---|
| `web/lib/server/prisma.ts` | Prisma singleton — ✅ OK |
| `web/lib/server/draw-repository.ts` | CRUD, upsert, retention — review query perf |
| `web/lib/server/trend-repository.ts` | Trend data queries — review indexes |
| `web/lib/server/provider.ts` | LOTTERY_PROVIDER_URL adapter — review Zod |
| `web/lib/statistics.ts` | Pure stat functions (~550 dòng) — review accuracy |
| `web/lib/worker-api-client.ts` | CF Worker client — review timeout/fallback |
| `web/lib/sample-data.ts` | Seeded data — ✅ OK |
| `web/lib/stations.ts` | Station catalog — ✅ OK |

#### 1.3 Components cần review

| Component | File |
|---|---|
| LotteryApp (shell + nav + filters) | `lottery-app.tsx` ~800 dòng |
| HistoryView (list + modal) | `history-view.tsx` |
| StatsView (charts + heatmap) | `stats-view.tsx` |
| CompareView (overlay charts) | `compare-view.tsx` |
| SimulatorView (Web Crypto) | `simulator-view.tsx` |
| SouthernDualView (XSMN dual) | `southern-dual-view.tsx` |

#### 1.4 Data Source Fallback Chain (đã triển khai)

```
Priority 1: PostgreSQL (Neon) → Prisma queries
Priority 2: Cloudflare Worker API → fetchWorkerHistory()
Priority 3: Sample data → createSampleDraws()
```

### Phase 2: Database Setup

1. Đăng ký neon.tech → tạo project "xsmb-thongke24"
2. Copy connection string → set `DATABASE_URL` trên Vercel
3. `cd web && npx prisma db push`
4. Seed: `POST /api/admin/seed` với ADMIN_API_KEY
5. Cron: `"0 20 * * *"` cho `/api/cron/maintain`

### Phase 3: Monitoring

1. Sentry: `npx @sentry/wizard@latest -i nextjs`
2. Upstash Redis: Tạo account → set env vars → implement cache
3. Lighthouse target: ≥90 all categories

### Phase 4: Quality Gates

```bash
cd web && npm run typecheck && npm run lint && npm run test && npm run build
cd web && npm run test:e2e
cd backend && python -m pytest -q
cd worker && npm test
cd mobile && flutter analyze && flutter test
```


---

## ⚠️ NGUYÊN TẮC BẮT BUỘC

1. **KHÔNG thay đổi framework/library** — chỉ thêm free services
2. **KHÔNG tự chạy schema migration trong mỗi request** — chỉ khi deploy/cron
3. **KHÔNG hiển thị SAMPLE như kết quả thật** — luôn gắn nhãn rõ ràng
4. **KHÔNG có nạp/rút tiền, đặt cược, ví** — thống kê/giáo dục 18+
5. **KHÔNG đặt secret ở frontend** — `NEXT_PUBLIC_*` chỉ public config
6. **LUÔN có fallback** — DB down → Worker API → Sample data
7. **LUÔN chạy test trước khi merge** — typecheck + lint + test + build
8. **LUÔN giữ disclaimer**: "Dữ liệu lịch sử không thể bảo đảm kết quả tương lai. Mỗi kỳ quay hợp lệ được xem là sự kiện ngẫu nhiên độc lập."
9. **Backup database** trước migration lớn
10. **Commit message tiếng Việt**, PR title tiếng Anh

---

## 📊 BIẾN MÔI TRƯỜNG

```env
# ── Database (Neon PostgreSQL) ──
DATABASE_URL=postgresql://xsmb_user:xxx@ep-xxx.us-east-2.aws.neon.tech/xsmb?sslmode=require

# ── Auth ──
ADMIN_API_KEY=<64-char-random>
CRON_SECRET=<32-char-random>
JWT_SECRET=<32-byte-random-hex>
ADMIN_USERNAME=admin
ADMIN_PASSWORD=<strong-password>
ACCESS_TOKEN_MINUTES=30

# ── CORS ──
CORS_ORIGINS=http://localhost:3000,https://vvn.freedev.app

# ── API Endpoints ──
NEXT_PUBLIC_API_URL=https://api.vvn.freedev.app/v1
WORKER_API_URL=https://xsmb-api.nhieuvu1802.workers.dev

# ── Data Provider (optional) ──
LOTTERY_PROVIDER_URL=
LOTTERY_PROVIDER_TOKEN=

# ── Caching (Upstash Redis) ──
UPSTASH_REDIS_REST_URL=https://xxx.upstash.io
UPSTASH_REDIS_REST_TOKEN=AXxx...

# ── Monitoring (Sentry) ──
SENTRY_DSN=https://xxx@sentry.io/xxx
SENTRY_AUTH_TOKEN=sntrys_xxx
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx

# ── App Config ──
DATA_RETENTION_DAYS=370
ANDROID_PACKAGE_ID=vn.xoso247.manager
GITHUB_PUBLIC_DATA_BASE_URL=https://raw.githubusercontent.com/Nhieuvu1802/xsmb-manager/main/public-data
```

---

## 🚀 DEPLOYMENT MAP

```
┌─────────────────────────────────────────────────────┐
│                PRODUCTION STACK                       │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌─────────────┐         ┌─────────────┐           │
│  │   Vercel     │         │ Cloudflare  │           │
│  │  (Next.js)   │         │  (Workers)  │           │
│  │  web/ deploy │         │  worker/    │           │
│  └──────┬──────┘         └──────┬──────┘           │
│         │ fetch                  │ read snapshot     │
│         ▼                        ▼                   │
│  ┌─────────────┐         ┌─────────────┐           │
│  │Neon PostgreSQL│        │Cloudflare R2│           │
│  │(Prisma ORM)  │        │(xsmb-data)  │           │
│  │0.5 GB free   │        │10 GB free   │           │
│  └─────────────┘         └─────────────┘           │
│         │                                            │
│  ┌──────┴──────┐                                   │
│  │ Upstash Redis│  (optional cache layer)           │
│  │ 256 MB free  │                                   │
│  └─────────────┘                                   │
│                                                      │
│  ┌─────────────┐         ┌─────────────┐           │
│  │   Sentry     │         │   Vercel    │           │
│  │ (5k free)    │         │  Analytics  │           │
│  └─────────────┘         │ (unlimited) │           │
│                           └─────────────┘           │
│                                                      │
│  Mobile (Flutter) ──→ Worker API ──→ R2 snapshot    │
│                    ──→ GitHub Raw ──→ public-data/   │
│                    ──→ SQLite local (offline cache)  │
└─────────────────────────────────────────────────────┘
```

---

*Prompt được tạo ngày 2026-09-14 từ phân tích toàn bộ codebase xsmb-manager.*