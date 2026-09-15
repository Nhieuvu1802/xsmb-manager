# Hành động còn thiếu

Cập nhật ngày 2026-09-14 sau khi đối chiếu master plan với codebase và chạy toàn bộ quality gate cục bộ.

## Cần thao tác trên dịch vụ production

1. **Database PostgreSQL**
   - Tạo hoặc chọn project Neon/PostgreSQL production và sao lưu trước khi đổi schema.
   - Đặt `DATABASE_URL` trên Vercel, sau đó chạy `cd web && npm run db:push` đúng một lần trong quy trình deploy.
   - Chạy `GET /api/cron/maintain?full=true` với Bearer `CRON_SECRET` để nhập 365 ngày dữ liệu thật từ Worker.
   - Kiểm tra `/api/health`: `storage=postgres` và `trend.ready=true`.

2. **Domain và deploy web/API**
   - `xsmb-api.nhieuvu1802.workers.dev/v1/health` đang hoạt động, R2 và cron đều sẵn sàng.
   - `api.vvn.freedev.app` hiện chưa phân giải DNS: cần gắn custom domain vào Worker hoặc đổi mọi cấu hình client về URL `workers.dev` đang hoạt động.
   - `vvn.freedev.app` hiện trả trang chống bot của hosting cũ, chưa phải bản Next.js trong `web/`: cần deploy Vercel với Root Directory `web` rồi trỏ domain.

3. **Secrets Vercel/GitHub**
   - Đặt `ADMIN_API_KEY`, `CRON_SECRET`, `DATABASE_URL` và kiểm tra Vercel Cron gửi đúng Bearer token.
   - Đặt `UPSTASH_REDIS_REST_URL` và `UPSTASH_REDIS_REST_TOKEN`, rồi xác nhận API thống kê vẫn trả dữ liệu khi Redis tạm lỗi.
   - Đặt `SENTRY_DSN`, `NEXT_PUBLIC_SENTRY_DSN`, `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`; gửi một lỗi thử để xác nhận cả browser, Node và Edge.
   - Không đưa secret vào biến `NEXT_PUBLIC_*`, trừ DSN Sentry vốn là cấu hình public theo thiết kế.

4. **Kiểm tra sau deploy**
   - Chạy smoke test các route `/api/health`, `/api/draws`, `/api/stats/compare`, `/api/stats/trend`, `/api/probability`.
   - Chạy Lighthouse trên URL production và xử lý đến khi bốn nhóm chính đạt mục tiêu 90 trở lên.
   - Xác nhận nhãn `SAMPLE` vẫn hiện rõ khi cả PostgreSQL và Worker cùng không khả dụng.

5. **Phát hành Android**
   - Tạo upload key riêng, đặt các biến `ANDROID_KEYSTORE_*`, chạy workflow Android Release và kiểm tra AAB trước khi đưa lên Google Play.

## Cần chốt trong repository

- Review working tree và tách commit theo phạm vi; hiện có cả thay đổi web/monitoring/database và nhóm proxy/9Router chưa được commit.
- Không commit `.env` chứa secret. File `.env.proxy-pool` chỉ được commit nếu đã xác nhận hoàn toàn là template không có credential thật.
- Tạo PR và để GitHub Actions chạy lại Web, E2E, Worker, Backend và Android CI trước khi merge.

## Đã hoàn tất ở code local

- Sửa thống kê recency: cửa sổ 7/30/90/180/365 lấy kỳ mới nhất; gap và current streak không phụ thuộc thứ tự đầu vào.
- API compare/trend dùng Upstash khi cấu hình, fallback cache bộ nhớ và giữ chuỗi PostgreSQL → Worker → sample.
- Các tác vụ import/seed/cron xóa cache thống kê và ghi `AuditLog` theo kiểu best-effort.
- Sentry dùng `instrumentation-client.ts`, `instrumentation.ts`, global error boundary và tunnel của SDK cho Next.js 16.
- Lịch sử có lọc ngày/đài/loại, modal chi tiết và tải thêm bằng `IntersectionObserver`.
- Màn So sánh có bảng side-by-side và overlay tần suất 00–99; mục Phương pháp đã gộp vào màn Xác suất để giữ đúng 8 màn hình.
