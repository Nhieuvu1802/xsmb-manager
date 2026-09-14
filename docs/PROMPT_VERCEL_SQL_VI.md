# Prompt bàn giao cho Cline/Codex

```text
Bạn là kiến trúc sư phần mềm, lập trình viên full-stack, chuyên gia UI/UX và thống kê xác suất. Hãy tiếp tục phát triển repository xsmb-manager hiện có, tập trung vào ứng dụng Next.js trong thư mục web.

Mục tiêu:
1. Duy trì một ứng dụng thống kê xổ số mobile-first, giao diện cao cấp nền tối, nhấn vàng/đỏ, chuyển động nhẹ, tiếng Việt; cho phép đổi theme bằng CSS variables nhưng không sao chép thương hiệu hoặc giao diện độc quyền.
2. Hỗ trợ Miền Bắc, đầy đủ lịch đài Miền Trung và Miền Nam. Bộ lọc toàn cục phải gồm miền, đài, loại phân tích và 7/30/90/180/365 ngày. Với miền có nhiều đài trong một ngày, “90 ngày” phải giữ toàn bộ đài của 90 ngày, không được nhầm thành 90 bản ghi.
3. Dùng PostgreSQL serverless được kết nối qua Vercel Marketplace và Prisma. Chỉ đọc DATABASE_URL ở server. API /api/draws ưu tiên SQL, sau đó dùng Cloudflare Worker hiện có và cuối cùng mới fallback về dữ liệu SAMPLE.
4. Duy trì khoảng một năm dữ liệu: lần đầu lấy 365 ngày, mỗi ngày đồng bộ lại 7 ngày gần nhất, lưu bằng upsert chống trùng drawCode, xóa bản ghi cũ hơn 370 ngày, ghi nhật ký import. Dùng Vercel Cron tối đa một lần/ngày để phù hợp Hobby miễn phí.
5. Nguồn bên ngoài phải là API hợp pháp, khai báo bằng LOTTERY_PROVIDER_URL và LOTTERY_PROVIDER_TOKEN. Validate bằng Zod trước khi ghi. Luôn hiển thị source, collectedAt và verification. Tuyệt đối không trình bày dữ liệu SAMPLE như kết quả thật.
6. CSV cần hỗ trợ cột station để nhiều đài cùng ngày không bị coi là trùng. Phát hiện sai ngày, thiếu kết quả, drawCode trùng và khoảng ngày có thể thiếu.
7. Giữ nguyên thông điệp: kết quả quá khứ không làm tăng xác suất kỳ sau nếu các kỳ độc lập; không có “cầu chắc thắng”; không nạp/rút tiền, đặt cược hoặc thanh toán; hiển thị 18+ và chơi có trách nhiệm.

Kiến trúc cần giữ:
- web/lib/stations.ts: danh mục/lịch đài.
- web/lib/sample-data.ts: dữ liệu mẫu cuộn 365 ngày, seed minh bạch.
- web/lib/statistics.ts: hàm thống kê thuần, không truy cập DB/UI.
- web/lib/server/prisma.ts và draw-repository.ts: kết nối, query, upsert, retention.
- web/lib/server/provider.ts: adapter + Zod cho nguồn hợp pháp.
- web/app/api: route đọc, import, seed, health và cron.
- web/components: chỉ trình bày và tương tác.

Yêu cầu chất lượng:
- Không đưa secret xuống client, không hard-code token.
- Giữ fallback để deploy vẫn hoạt động khi chưa có SQL.
- Không tự động chạy schema migration trong mỗi request.
- Bảo vệ /api/admin/* bằng ADMIN_API_KEY và cron bằng CRON_SECRET.
- Không xóa hoặc ghi đè thay đổi ngoài phạm vi.
- Sau mỗi thay đổi, chạy npm run typecheck, npm run lint, npm test, npm run build và npm run test:e2e.
- Cập nhật web/README.md và docs/VERCEL_SQL_DEPLOY.md nếu quy trình thay đổi.

Trước khi sửa, đọc web/AGENTS.md và tài liệu Next.js cục bộ liên quan trong web/node_modules/next/dist/docs. Hãy triển khai hoàn chỉnh, báo rõ file đã đổi, kiểm thử đã chạy và mọi bước thủ công còn lại trên Vercel.
```
