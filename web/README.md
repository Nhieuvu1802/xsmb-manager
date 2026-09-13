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
npm run test         # 26 unit + API tests
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
| Phân tích | Nhập bộ số, hồ sơ z-score/Wilson/streak, tạo random, lưu yêu thích |
| Lịch sử | Danh sách kỳ, bộ lọc ngày/đài/miền/loại, modal chi tiết |
| Thống kê | Tần suất 0–9, đầu–đuôi, chẵn/lẻ, khoảng, streak, cặp, ngày tuần |
| So sánh | Bảng side-by-side 7/30/90/180/365 kỳ |
| Xác suất | 2–6 chữ số, EV, Monte Carlo, Wilson, χ² |
| Kho dữ liệu | Nhập CSV/JSON, validation, nguồn & cập nhật |
| Phương pháp | Công thức, giả định, cảnh báo an toàn |

## Cấu hình tùy chọn

Sao chép `.env.example` thành `.env.local`:

```dotenv
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/thongke24
ADMIN_API_KEY=thay-bang-chuoi-bi-mat-dai
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

- `DATABASE_URL` chỉ cần khi bật PostgreSQL/Prisma.
- `ADMIN_API_KEY` bảo vệ endpoint POST /api/admin/import.
- `GET /api/probability` và `/api/draws` là API công khai.
- `GET /api/health` kiểm tra trạng thái.
- `GET /api/stats/compare` so sánh 5 cửa sổ.

## Triển khai

### Vercel

1. Push lên GitHub/GitLab/Bitbucket.
2. New Project → Root Directory = `web`.
3. Framework preset: Next.js; build: `npm run build`.
4. Deploy. Cron có thể cấu hình qua vercel.json.

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
  page.tsx               điểm vào App Router
components/
  lottery-app.tsx        shell + Tổng quan + Phân tích + Phương pháp
  history-view.tsx       lịch sử kỳ quay + filter + modal
  stats-view.tsx         thống kê chi tiết (0–9, streak, đầu-đuôi)
  compare-view.tsx       so sánh 7–365 kỳ
lib/
  lottery-domain.ts      kiểu miền nghiệp vụ
  sample-data.ts         dữ liệu mô phỏng có seed cố định
  statistics.ts          công thức, kiểm định, CSV/JSON
  api.ts                 API client Worker
tests/                   26 unit + API tests
e2e/                     Playwright smoke test
prisma/schema.prisma     mô hình PostgreSQL
```

## Tài liệu

- [Đặc tả sản phẩm](../docs/WEB_PRODUCT_SPEC.md)
- [Kiến trúc hệ thống](../docs/WEB_ARCHITECTURE.md)
- [Thiết kế màn hình](../docs/WEB_SCREENS.md)
- [PRODUCT_MVP.md](../docs/PRODUCT_MVP.md)

## Giấy phép

Next.js, React, Recharts, Tailwind CSS, Lucide, Zod, Prisma, Vitest, Playwright: MIT hoặc Apache-2.0. Không dùng logo, hình ảnh hay dữ liệu độc quyền từ bên thứ ba.


