# InfinityFree backup API

Thư mục này là ứng dụng PHP/MySQL độc lập, không cần Composer, worker hay daemon.

1. Tạo database MySQL và import `database/schema.sql` trong phpMyAdmin.
2. Copy `config/config.example.php` thành `config/config.php`, điền credentials, một `SYNC_API_KEY` ngẫu nhiên và `ADMIN_PASSWORD_HASH` tạo bằng `password_hash()`.
3. Upload nội dung thư mục lên hosting. Giữ `.htaccess` để chặn truy cập trực tiếp vào config.
4. Đặt `ALLOWED_ORIGINS` thành `https://laptopvvn.vercel.com`.
5. Kiểm tra `GET /api/health.php`; public read endpoint là `GET /api/draws.php`.

Write endpoints chỉ nhận Bearer token: `POST /api/sync.php` (single hoặc tối đa 50 draws) và `POST /api/missing.php`. Cùng checksum trả `unchanged`; checksum khác được ghi conflict và không tự động overwrite. Dashboard đăng nhập ở `/admin/`.
