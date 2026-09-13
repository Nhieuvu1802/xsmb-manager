# Thư mục dữ liệu runtime

`data/` tách dữ liệu khỏi source code. Toàn bộ nội dung bị `.gitignore` bỏ qua trừ file README này.

```text
data/
├── xsmb.db                  # database chính của app Streamlit (lịch sử nhiều năm)
├── api-mobile.db            # database cho FastAPI khi chạy local (SQLite)
├── xsmb-backup-v2.7.db      # backup rời do người dùng tạo
├── backups/
│   ├── database/            # snapshot SQLite tạo bởi app
│   └── code/                # backup code do tính năng cập nhật ZIP sinh ra
├── releases/
│   ├── legacy/              # gói ZIP phát hành cũ (app monolith 2.6.0)
│   └── preview/             # APK preview đã build trước đó
└── samples/                 # CSV mẫu
```

`sample_xsmb.csv` được giữ trong `backend/` vì app Streamlit dùng nó làm ví dụ nhập liệu.

## Trạng thái dữ liệu (cập nhật 2026-09-13)

- `xsmb.db`: XSMB **2177 kỳ** (2020-09-03 → 2026-09-12; thiếu 4 ngày nghỉ Tết
  2026-02-16…19), XSMN **1148 đài-draw** phủ **365/365 ngày**
  (2025-09-13 → 2026-09-12).
- `api-mobile.db` được mirror đúng lượng dữ liệu mới như trên.
- Backfill 1 năm cho XSMN:
  `scripts/collector/backfill_history.py --region all --days 365 --mirror-database data/api-mobile.db`
  (tự tạo backup trong `data/backups/database/`), sau đó sinh lại snapshot:
  `scripts/collector/export_public_data.py` (mặc định 365 ngày).

## Sao lưu

- Sao lưu tối thiểu: copy `data/xsmb.db` (và `data/*.db-wal` nếu đang chạy).
- App có nút **Tạo database tổng hợp mới** dùng SQLite Backup API để tạo snapshot nhất quán.
- Không commit database lên Git: dữ liệu có thể lớn và chứa thông tin riêng.
- Khi deploy cloud (Render/Railway/Supabase), dữ liệu nằm ở PostgreSQL chứ không ở thư mục này.
