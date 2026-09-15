# Primary → InfinityFree data synchronization

## Kiến trúc đã tích hợp

- Primary UI/API: Next.js 16 App Router tại `laptopvvn.vercel.com`, Prisma/PostgreSQL khi có `DATABASE_URL`.
- Thứ tự đọc server: PostgreSQL → Cloudflare Worker JSON → InfinityFree → sample/cache đóng gói.
- Flutter đã có `LotteryDataProvider`, provider chain và SQLite/SharedPreferences cache; browser không scrape nguồn.
- Backup: PHP 8 + PDO MySQL trong `infinityfree/`, schema chuẩn theo region/province/date/results.

Next.js chuyển model `LotteryDraw` hiện hữu sang wire schema chuẩn ngay trước khi sync. Checksum SHA-256 chỉ gồm identity và kết quả. InfinityFree khóa row trong transaction: cùng checksum là `unchanged`; khác checksum là `conflict` và không overwrite.

## Vercel environment variables

```dotenv
BACKUP_API_URL=https://YOUR_INFINITYFREE_DOMAIN/api
BACKUP_SYNC_URL=https://YOUR_INFINITYFREE_DOMAIN/api/sync.php
BACKUP_SYNC_API_KEY=generate-a-long-random-secret
```

Không dùng prefix `NEXT_PUBLIC_` cho ba biến này. Cấu hình trong Vercel rồi redeploy.

## Endpoints

- `GET /api/health`: primary, database, Worker và backup.
- `GET /api/draws`: failover sang backup; sample response có `stale: true`.
- `POST /api/sync`: Bearer `ADMIN_API_KEY`, tối đa 50 kỳ.
- `POST /api/admin/backfill`: Bearer `ADMIN_API_KEY`, khoảng 1–31 ngày, có region/province và result report.
- `POST InfinityFree /api/missing.php`: so danh sách ngày và trả đúng các ngày backup thiếu.

Không đưa `ADMIN_API_KEY`, database credentials hoặc backup sync key vào Flutter/Web client.
