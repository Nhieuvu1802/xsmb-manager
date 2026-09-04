# Kiến trúc mục tiêu

```text
Flutter Android ───────┐
Next.js PWA ──────────┼── HTTPS/JSON ── FastAPI ── SQLAlchemy ── PostgreSQL/Supabase
Streamlit (legacy) ───┘                     │
                                            └── scraper + logic thống kê dùng chung
```

## Ranh giới thành phần

- `xsmb_manager/analytics.py`, `services.py`, `scraper.py`, `ports.py`: logic nghiệp vụ không phụ thuộc giao diện.
- `xsmb_manager/database.py`: SQLite repository cho ứng dụng Streamlit cũ và nhập/sao lưu cục bộ.
- `xsmb_manager/api/`: FastAPI, JWT, SQLAlchemy models và PostgreSQL repository.
- `scripts/migrate_sqlite_to_postgres.py`: chuyển dữ liệu lịch sử SQLite sang PostgreSQL theo cơ chế upsert.
- `frontend/`: web/PWA, là client API chứ không truy cập database trực tiếp.
- `mobile/`: Flutter Android, là client API và chỉ cache dữ liệu đọc gần nhất trên thiết bị.

Database và JWT secret chỉ tồn tại ở backend. Frontend/Flutter không chứa database password, service-role key hoặc admin password. Mọi tác vụ ghi/đồng bộ phải qua endpoint có JWT quản trị.

## PostgreSQL hoặc Supabase

Backend dùng PostgreSQL chuẩn nên có thể chạy bằng Docker Compose, Railway, Render hoặc Supabase. Với Supabase, đặt `DATABASE_URL` bằng URI direct connection/pooler do dashboard cung cấp và thêm `sslmode=require`, ví dụ:

```text
postgresql+psycopg://USER:PASSWORD@HOST:5432/postgres?sslmode=require
```

Không đưa URI này vào Flutter, biến `NEXT_PUBLIC_*`, GitHub artifact hoặc source control. Chạy migration một lần từ môi trường tin cậy:

```bash
DATABASE_URL="..." python scripts/migrate_sqlite_to_postgres.py xsmb.db
```

## Luồng phát hành

1. Test Python, web và Flutter trên GitHub Actions.
2. Deploy PostgreSQL/Supabase và FastAPI; kiểm tra `/health` và `/docs`.
3. Đặt GitHub variable `API_BASE_URL` trỏ tới API HTTPS.
4. Test APK từ Android CI trên điện thoại thật.
5. Android Release ký APK/AAB bằng upload key trong GitHub Secrets.
6. GitHub Release lưu artifact; tuỳ chọn đưa AAB lên Google Play Internal testing.
7. Sau kiểm thử internal/closed, phát hành production theo tỷ lệ.
