# XSMB Manager — quản lý & thống kê kết quả xổ số

Monorepo gồm ba client và một backend dùng chung:

| Thư mục | Nội dung | Chạy |
| --- | --- | --- |
| `backend/` | Python: Streamlit (cá nhân), FastAPI (web + mobile), logic thống kê & backtest | `cd backend; python -m streamlit run app.py` |
| `mobile/` | Flutter: app Android + Web, database SQLite trên máy, chuỗi provider dự phòng | `cd mobile; flutter run` |
| `web/` | Next.js PWA “Thống Kê 24” (`web/twa/` là wrapper Bubblewrap) | `cd web; npm run dev` |
| `public-data/` | Cấu hình public + snapshot mobile (`latest.json` một ngày, `history.json` 365 ngày) | chỉ đọc qua GitHub Raw |
| `data/` | Database, backup, bản phát hành — **không commit**, xem `data/README.md` | — |

Tài liệu: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/ANDROID_RELEASE.md`](docs/ANDROID_RELEASE.md), [`docs/PRODUCT_MVP.md`](docs/PRODUCT_MVP.md), [`docs/AUDIT.md`](docs/AUDIT.md), [`docs/ROADMAP_COMMERCIAL.md`](docs/ROADMAP_COMMERCIAL.md).

## Backend

```bash
python -m venv .venv
.venv\Scripts\activate            # Windows
pip install -r backend/requirements-dev.txt
cd backend && python -m pytest -q
```

- Streamlit đọc/ghi `../data/xsmb.db` (SQLite WAL, khoá ngoại, unique key theo ngày + giải + vị trí).
- FastAPI chạy với PostgreSQL (Docker/Render/Railway/Supabase) hoặc SQLite local qua `scripts/start_mobile_api.ps1`.
- API production mục tiêu: `https://api.vvn.freedev.app/v1`.
- Endpoint đọc công khai: `/health`, `/config`, `/version`, `/xsmb/latest`, `/xsmb/history`, `/xsmb/{date}`,
  `/xsmn/latest`, `/xsmn/history`, `/xsmn/{date}` (đều tính từ API base URL trên).
  trả cả cửa sổ **365 ngày** đã kiểm định (snapshot `public-data/{region}/history.json`).
- Cập nhật dữ liệu: `scripts/collector/update_lottery.py` (ngày mới),
  `scripts/collector/backfill_history.py` (lấp 1 năm còn thiếu),
  `scripts/collector/export_public_data.py` (sinh lại snapshot + manifest).
- Ghi/đồng bộ cần JWT quản trị: `/api/v1/sync/mb`, `/api/v1/sync/mn`.

```bash
docker compose up --build          # postgres + api + web
```

## Mobile (Flutter)

App duy nhất cho Android + Web, có database cục bộ, chuỗi nguồn dự phòng, engine 00–99, xếp hạng và backtest. Chi tiết kiến trúc ở [`mobile/README.md`](mobile/README.md).

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
flutter build web --release
```

- APK/AAB: `mobile/build/app/outputs/`. Script tạo sẵn bản universal + tách theo ABI vào `mobile/dist/`: `mobile\tool\build_apk.bat`.
- Mặc định app gọi `https://api.vvn.freedev.app/v1`; local Worker có thể truyền
  `--dart-define=API_BASE_URL=http://10.0.2.2:8787/v1`.
- Failover: VVN API → GitHub `public-data` → SQLite/local cache. GitHub không phải source of truth.
- APK release hiện ký bằng keystore debug của Flutter: cài trực tiếp được, chưa đủ điều kiện lên Google Play (xem `docs/ANDROID_RELEASE.md`).
- Trong app, tab **Nguồn & cài đặt** cho phép đổi URL API, xem sức khoẻ nguồn, lịch sử đồng bộ và kích thước database.


## Web (Next.js PWA)

```bash
cd web
npm install
npm run dev          # http://localhost:3000
npm run check        # typecheck + lint + test + build
```

Deploy miễn phí: Vercel/Netlify với **Root Directory = `web`** và biến `NEXT_PUBLIC_API_URL` trỏ tới API HTTPS.

## Quy ước thống kê

- Mỗi số trúng lấy 2 chữ số cuối: `12345` → `45`, `7` → `07`.
- Tần suất = số lần số đó xuất hiện trong khoảng lọc; một kỳ có thể xuất hiện nhiều lần.
- Số ngày gan = số ngày từ lần xuất hiện gần nhất tới ngày cuối khoảng lọc.
- Điểm thống kê 0–100 là **thứ hạng tương đối từ dữ liệu quá khứ**, không phải xác suất trúng và không bảo đảm kết quả tương lai.
- Backtest dùng walk-forward: chỉ dùng dữ liệu trước ngày D để đánh giá ngày D, có so sánh với baseline ngẫu nhiên và baseline tần suất đơn giản.
- Ứng dụng không có nạp/rút tiền, ví, đặt cược hay tuyên bố trúng thưởng.

## Không commit

`.env` chứa secret, keystore (`*.jks`, `*.keystore`), database (`data/**`), `node_modules`, `build/`, APK/AAB.
Xem `.gitignore` và `.env.example`.
