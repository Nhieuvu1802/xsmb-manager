# Kiến trúc mục tiêu

```text
vvn.freedev.app ── Website chính (Cloudflare Pages target)
api.vvn.freedev.app/v1 ── Cloudflare Worker API ── provider/cache/dataset

Flutter (Android/Web)
├── 1. VVN API
├── 2. GitHub public-data JSON (backup chỉ đọc)
└── 3. SQLite/local storage (offline cache)

GitHub
├── source code
├── public configuration
└── snapshot JSON công khai: latest.json (một ngày) + history.json (cửa sổ 365 ngày)
```

## Cấu trúc monorepo

```text
xsmb-manager/
├── backend/          # Python: Streamlit + FastAPI + logic nghiệp vụ
├── mobile/           # Flutter: app Android + Web
├── web/              # Next.js PWA (twa/ là wrapper Bubblewrap)
├── public-data/      # config + snapshot public dự phòng trên GitHub
├── data/             # database, backup, bản phát hành (git-ignored)
├── docs/             # kiến trúc, phát hành, MVP, audit
└── scripts/          # migrate PostgreSQL, chạy API local
```

## Ranh giới thành phần

- `backend/xsmb_manager/analytics.py`, `services.py`, `scraper.py`, `ports.py`: logic nghiệp vụ không phụ thuộc giao diện.
- `backend/xsmb_manager/config.py`: đường dẫn dữ liệu tập trung — `data/xsmb.db`, `data/backups/*`.
- `backend/xsmb_manager/database.py`: SQLite repository cho ứng dụng Streamlit và nhập/sao lưu cục bộ.
- `backend/xsmb_manager/api/`: FastAPI, JWT, SQLAlchemy models và repository PostgreSQL/SQLite.
- `scripts/migrate_sqlite_to_postgres.py`: chuyển dữ liệu lịch sử SQLite sang PostgreSQL theo cơ chế upsert.
- `web/`: web/PWA, là client API chứ không truy cập database trực tiếp.
- `mobile/`: Flutter Android/Web; nguồn theo thứ tự VVN API → GitHub JSON → SQLite.
- `public-data/`: bản sao public, không phải database chính và không nhận thao tác ghi từ app. Snapshot gồm `latest.json` (một ngày, tải nhanh) và `history.json` (**365 ngày**; mỗi kỳ giữ `date` + `station` riêng vì miền Nam/Trung mỗi ngày quay một bộ đài khác nhau). Sinh lại bằng `scripts/collector/export_public_data.py`; thêm ngày cũ vào database bằng `scripts/collector/backfill_history.py`.

## Ràng buộc hosting hiện tại

InfinityFree free hosting chỉ là legacy website; FastAPI được giữ cho xử lý local.
Production API chuyển sang Worker tại `api.vvn.freedev.app/v1`. DNS hiện chưa có
record cho hostname này và `vvn.freedev.app` không được delegate thành zone riêng,
vì vậy giai đoạn đầu cần endpoint `workers.dev` cho tới khi chủ zone `freedev.app`
cấp DNS/delegation phù hợp.

Database và JWT secret chỉ tồn tại ở backend. Web/Flutter không chứa database password, service-role key hoặc admin password. Mọi tác vụ ghi/đồng bộ phải qua endpoint có JWT quản trị.


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
