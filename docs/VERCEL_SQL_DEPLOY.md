# Triển khai miễn phí trên Vercel với PostgreSQL

Ứng dụng chạy được ngay cả khi chưa có cơ sở dữ liệu. Thứ tự nguồn là PostgreSQL → Cloudflare Worker hiện có → bộ mẫu 365 ngày. Giao diện luôn hiển thị nguồn đang dùng và không trình bày dữ liệu mô phỏng như kết quả thật.

## 1. Tạo dự án và PostgreSQL miễn phí

1. Đưa repository lên GitHub và import vào Vercel.
2. Chọn **Root Directory** là `web`.
3. Trong dự án Vercel, mở **Storage → Create Database → Marketplace Database**.
4. Chọn gói miễn phí của **Neon** hoặc **Prisma Postgres**, xác nhận điều khoản của nhà cung cấp và kết nối database vào cả Production, Preview và Development.
5. Kiểm tra Vercel đã tạo biến `DATABASE_URL` cho dự án.

Vercel không còn cung cấp sản phẩm “Vercel Postgres” riêng; PostgreSQL hiện được kết nối qua Marketplace.

## 2. Khởi tạo bảng

Từ thư mục `web`, kéo biến môi trường về máy rồi tạo schema:

```powershell
vercel link
vercel env pull .env.local
npm install
npm run db:push
```

`db:push` chỉ nên chạy sau khi kiểm tra `DATABASE_URL` đang trỏ đúng database của dự án này.

## 3. Khai báo bí mật

Trong **Vercel → Project Settings → Environment Variables**, thêm:

| Biến | Bắt buộc | Công dụng |
| --- | --- | --- |
| `DATABASE_URL` | Có | Chuỗi kết nối PostgreSQL do integration cung cấp |
| `ADMIN_API_KEY` | Có | Bảo vệ API nhập/khởi tạo dữ liệu |
| `CRON_SECRET` | Có | Vercel gửi trong header khi chạy cron; dùng chuỗi ngẫu nhiên tối thiểu 16 ký tự |
| `DATA_RETENTION_DAYS` | Không | Mặc định `370`, bị giới hạn trong khoảng 365–400 |
| `LOTTERY_PROVIDER_URL` | Không | API JSON hợp pháp trả dữ liệu lịch sử |
| `LOTTERY_PROVIDER_TOKEN` | Không | Token của API nguồn, chỉ tồn tại phía máy chủ |
| `WORKER_API_URL` | Không | Worker hiện có; đã có URL mặc định trong mã nguồn |

Không đặt token nguồn trong biến bắt đầu bằng `NEXT_PUBLIC_`.

## 4. Nạp dữ liệu ban đầu

Nếu chưa có nguồn dữ liệu hợp pháp, endpoint sau tạo bộ mẫu cuộn 365 ngày cho ba miền. Dữ liệu được gắn trạng thái `SAMPLE`, không giả làm kết quả thật.

```powershell
$headers = @{ Authorization = "Bearer YOUR_ADMIN_API_KEY" }
Invoke-RestMethod -Method Post -Uri "https://YOUR_DOMAIN/api/admin/seed" -Headers $headers
```

Khi đã có API hợp pháp, cấu hình `LOTTERY_PROVIDER_URL`. API cần trả:

```json
{
  "records": [
    {
      "drawCode": "MN-HCM-20260912",
      "lotteryType": "TRADITIONAL",
      "region": "Miền Nam",
      "station": "TP. Hồ Chí Minh",
      "drawnAt": "2026-09-12T16:15:00+07:00",
      "collectedAt": "2026-09-12T18:00:00+07:00",
      "source": "https://data-provider.example/draw/MN-HCM-20260912",
      "verification": "VERIFIED",
      "prizes": [
        { "prize": "Đặc biệt", "position": 1, "value": "123456" }
      ]
    }
  ]
}
```

## 5. Duy trì khoảng một năm

`web/vercel.json` chạy `/api/cron/maintain` mỗi ngày lúc 16:30 UTC, tương đương 23:30 giờ Việt Nam:

- lần đầu lấy tối đa 365 ngày từ API nguồn;
- các lần sau đồng bộ lại 7 ngày gần nhất để xử lý dữ liệu sửa muộn;
- xóa kỳ cũ hơn 370 ngày;
- nếu chưa cấu hình API riêng, đồng bộ dữ liệu đã xác minh từ Worker hiện có;
- chỉ bổ sung dữ liệu mẫu cuộn khi cả nguồn riêng và Worker đều không khả dụng;
- ghi nhật ký vào bảng `data_imports`.

Gói Hobby của Vercel hỗ trợ cron một lần mỗi ngày nhưng thời điểm thực thi có thể lệch trong khung giờ. Endpoint được bảo vệ bằng `CRON_SECRET`.

## 6. Kiểm tra sau triển khai

```text
GET /api/health
GET /api/draws?region=Miền%20Nam&station=TP.%20Hồ%20Chí%20Minh&includeResults=true
GET /api/stats/compare?region=Miền%20Trung
```

`/api/health` trả `storage: "postgres"` khi SQL đã sẵn sàng. `worker` nghĩa là ứng dụng đang đọc dữ liệu thật trực tiếp từ Worker; `sample` nghĩa là đang dùng bộ mô phỏng.
