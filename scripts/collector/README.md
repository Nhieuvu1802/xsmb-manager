# Incremental lottery collector

Collector chỉ tải các ngày đã hoàn tất sau `MAX(draw_date)`. Trước khi ghi, dữ
liệu được kiểm tra số đài, đủ giải, độ dài chữ số và vị trí trùng. Database được
sao lưu bằng SQLite Backup API trước mỗi đợt có dữ liệu thiếu.

## Cập nhật hằng ngày (chỉ tiến)

```powershell
.venv\Scripts\python.exe scripts\collector\update_lottery.py `
  --mirror-database data\api-mobile.db
```

Để chạy lại có kiểm soát tới một ngày cụ thể:

```powershell
.venv\Scripts\python.exe scripts\collector\update_lottery.py `
  --through 2026-09-12 `
  --mirror-database data\api-mobile.db
```

## Backfill lịch sử một năm (khi database thiếu ngày cũ)

`update_lottery.py` chỉ đi tiếp từ `MAX(draw_date)` nên không lùi về quá khứ.
Khi database chỉ có vài ngày gần nhất (ví dụ XSMN) mà app cần đủ cửa sổ 365 ngày
để thống kê/backtest, dùng `backfill_history.py`:

```powershell
.venv\Scripts\python.exe scripts\collector\backfill_history.py `
  --region all --days 365 `
  --mirror-database data\api-mobile.db
```

- Cửa sổ mặc định 365 ngày (`--days`); chạy từng phần bằng
  `--from 2025-09-13 --through 2025-12-31` và thêm `--no-backup` cho các lượt sau
  khi lượt đầu đã tạo backup trong `data/backups/database/`.
- Ngày đã có dữ liệu **không** bị ghi đè (`INSERT OR IGNORE` + validate trước khi
  ghi). Ngày nguồn không có (nghỉ Tết) chỉ nằm trong `validation_errors` của báo
  cáo và làm exit code thành `2`.
- XSMB hiện có 6 năm trong `data/xsmb.db`; chỉ XSMN cần backfill.

Exit code `2` nghĩa là có ngày không vượt qua bước fetch/validation. Không dùng
script này trực tiếp từ request của Flutter hoặc website.

## Xuất snapshot public (GitHub + Worker)

Sau khi collector PASS, sinh lại snapshot public và manifest:

```powershell
.venv\Scripts\python.exe scripts\collector\export_public_data.py
```

Mặc định ghi **cả cửa sổ 365 ngày** cho mỗi miền:

```text
public-data/xsmb/latest.json     # đúng kỳ mới nhất (client tải nhanh)
public-data/xsmb/history.json    # cửa sổ 365 ngày, mỗi kỳ kèm ngày + đài riêng
public-data/xsmn/latest.json
public-data/xsmn/history.json
```

Đổi độ sâu bằng `--days 180` (manifest ghi lại `historyDays`/`history`). Sau khi
export, commit `public-data/` và push — Cloudflare Git deployment sẽ build lại
Worker với dataset mới.

