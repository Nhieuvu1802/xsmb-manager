# Thống Kê 24 — MVP phân tích xác suất xổ số

Ứng dụng Next.js ưu tiên điện thoại, phục vụ thống kê và giáo dục xác suất. Không có nạp/rút tiền, ví, đặt cược, quảng cáo thắng giả hay tuyên bố dự đoán chắc chắn.

## Chạy miễn phí trên máy

Yêu cầu Node.js 20.9 trở lên.

```bash
cd web
npm install
npm run dev
```

Mở `http://localhost:3000`. Dữ liệu mẫu có sẵn nên không cần PostgreSQL hoặc API để xem toàn bộ giao diện.

## Kiểm tra chất lượng

```bash
npm run check        # typecheck + lint + test + build
npm run typecheck
npm run lint
npm run test         # unit + API tests
npm run build
```

Kiểm thử giao diện cần cài Chromium một lần:

```bash
npx playwright install chromium
npm run test:e2e
```

## Tính năng

| Màn hình | Nội dung |
| --- | --- |
| Tổng quan | KPI, kỳ mới nhất, heatmap 00–99, nhóm nổi bật, xu hướng |
| Miền Nam song song | Chọn và xem trọn bảng giải của 2 đài trên cùng màn hình |
| Phân tích | Nhập bộ số, hồ sơ z-score/Wilson/streak, tạo random, lưu yêu thích |
| Quay thử | Lồng cầu Web Crypto và xếp hạng mô tả lịch sử, không tuyên bố dự đoán |
| Lịch sử | Danh sách kỳ, bộ lọc ngày/đài/miền/loại, modal chi tiết |
| Thống kê | Tần suất 0–9, đầu–đuôi, chẵn/lẻ, khoảng, streak, cặp, ngày tuần |
| So sánh | Bảng side-by-side 7/30/90/180/365 kỳ |
| Xác suất | 2–6 chữ số, EV, Monte Carlo, Wilson, χ², công thức và cảnh báo phương pháp |
| Kho dữ liệu | Nhập CSV/JSON, validation, nguồn & cập nhật |

Danh mục hiện có 14 đài miền Trung và 21 đài miền Nam theo lịch quay trong tuần. Dữ liệu mẫu cuộn theo 365 ngày gần nhất; cấu trúc giải miền Bắc là 27 kết quả, miền Trung/miền Nam là 18 kết quả cho mỗi đài.

## Cấu hình tùy chọn

Sao chép `.env.example` thành `.env.local`:

```dotenv
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/thongke24
ADMIN_API_KEY=thay-bang-chuoi-bi-mat-dai
CRON_SECRET=thay-bang-chuoi-ngau-nhien-khac
DATA_RETENTION_DAYS=370
LOTTERY_PROVIDER_URL=
LOTTERY_PROVIDER_TOKEN=
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
SENTRY_DSN=
NEXT_PUBLIC_SENTRY_DSN=
SENTRY_AUTH_TOKEN=
SENTRY_ORG=
SENTRY_PROJECT=
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

- `DATABASE_URL` bật PostgreSQL/Prisma; khi thiếu, ứng dụng dùng Worker API hiện có rồi mới fallback sang dữ liệu mẫu.
- `ADMIN_API_KEY` bảo vệ endpoint POST `/api/admin/import` và `/api/admin/seed`.
- `CRON_SECRET` bảo vệ tác vụ cập nhật hằng ngày của Vercel.
- `LOTTERY_PROVIDER_*` chỉ cần khi có API dữ liệu hợp pháp.
- `UPSTASH_REDIS_REST_*` bật cache thống kê dùng chung; khi thiếu, app dùng cache bộ nhớ có TTL.
- Nhóm `SENTRY_*` bật theo dõi lỗi và source map; khi thiếu, SDK được tắt an toàn.
- `GET /api/probability` và `/api/draws` là API công khai.
- `GET /api/health` kiểm tra trạng thái.
- `GET /api/stats/compare` so sánh 5 cửa sổ.

## Triển khai

### Vercel

1. Push lên GitHub/GitLab/Bitbucket và tạo dự án Hobby.
2. Chọn Root Directory = `web`, Framework = Next.js.
3. Kết nối PostgreSQL miễn phí từ Vercel Marketplace (Neon hoặc Prisma Postgres) để nhận `DATABASE_URL`.
4. Chạy `vercel env pull .env.local`, sau đó `npm run db:push` để tạo bảng.
5. Thêm `ADMIN_API_KEY`, `CRON_SECRET` và deploy.
6. Gọi GET `/api/cron/maintain?full=true` với Bearer `CRON_SECRET` để đồng bộ toàn bộ 365 ngày; cron trong `vercel.json` cập nhật 7 ngày gần nhất mỗi tối và tự đối soát toàn năm vào Chủ nhật.

Hướng dẫn chi tiết: [VERCEL_SQL_DEPLOY.md](../docs/VERCEL_SQL_DEPLOY.md).

### Docker Compose

```bash
docker compose up --build    # postgres + api + web
```

## Cấu trúc

```text
app/
  api/probability/       API xác suất công khai
  api/draws/             API danh sách kỳ
  api/stats/compare/     API so sánh cửa sổ
  api/health/            API trạng thái
  api/admin/import/      API kiểm định + import
  api/admin/seed/        nạp dữ liệu mẫu 365 ngày vào SQL
  api/cron/maintain/     đồng bộ hằng ngày + retention
  page.tsx               điểm vào App Router
components/
  lottery-app.tsx        shell + Tổng quan + Phân tích + Xác suất
  southern-dual-view.tsx bảng giải 2 đài miền Nam song song
  simulator-view.tsx     quay thử minh bạch + điểm nổi bật lịch sử
  history-view.tsx       lịch sử kỳ quay + filter + modal
  stats-view.tsx         thống kê chi tiết (0–9, streak, đầu-đuôi)
  compare-view.tsx       so sánh 7–365 kỳ
lib/
  lottery-domain.ts      kiểu miền nghiệp vụ
  stations.ts            lịch 14 đài miền Trung + 21 đài miền Nam
  sample-data.ts         dữ liệu mô phỏng cuộn 365 ngày
  statistics.ts          công thức, kiểm định, CSV/JSON
  server/                Prisma repository + adapter API hợp pháp
  worker-api-client.ts   adapter Cloudflare Worker hiện có
  api.ts                 API client backend tùy chọn
tests/                   unit + API tests
e2e/                     Playwright smoke test
prisma/schema.prisma     mô hình PostgreSQL
```

## Tài liệu

- [Đặc tả sản phẩm](../docs/WEB_PRODUCT_SPEC.md)
- [Kiến trúc hệ thống](../docs/WEB_ARCHITECTURE.md)
- [Thiết kế màn hình](../docs/WEB_SCREENS.md)
- [Triển khai Vercel + SQL](../docs/VERCEL_SQL_DEPLOY.md)
- [Prompt bàn giao Cline/Codex](../docs/PROMPT_VERCEL_SQL_VI.md)
- [PRODUCT_MVP.md](../docs/PRODUCT_MVP.md)
- [Triển khai backup InfinityFree và đồng bộ](../docs/BACKUP_SYNC.md)

## Giấy phép

Next.js, React, Recharts, Tailwind CSS, Lucide, Zod, Prisma, Vitest, Playwright: MIT hoặc Apache-2.0. Không dùng logo, hình ảnh hay dữ liệu độc quyền từ bên thứ ba.
