# Báo cáo kiểm toán & nâng cấp (Phase 1)

Ngày kiểm toán: 2026-09-13 · Phạm vi: toàn bộ repo `xsmb-manager`.

## 1. Hiện trạng trước khi dọn

| Thư mục / file | Kích thước | Vai trò thật |
| --- | --- | --- |
| `app.py` + `xsmb_manager/` | ~1.7 k dòng Python | App Streamlit (XSMB/XSMN) + FastAPI (`xsmb_manager/api/`) + scraper 3 nguồn + thống kê + walk-forward backtest + Top 4 |
| `frontend/` | 34 517 file / 884 MB (chủ yếu `node_modules`) | Next.js 16 App Router PWA “Thống Kê 24”, gọi FastAPI qua `NEXT_PUBLIC_API_URL`, có Prisma schema |
| `mobile/` | 2 751 file / 1 462 MB (`build/` 1 218 MB) | Flutter app `xsmb_manager`, `ApiClient` một-nguồn, cache `SharedPreferences`, 3 tab |
| `trying_flutter/` | 3 361 file / 1 135 MB (`build/` 948 MB, `dist/` 98 MB) | **Bản Flutter thứ hai** port UI “Thống Kê 24” từ web: 14 file `lib/`, ~11 k dòng Dart, parity vectors, icon, script build APK |
| `twa/` | 3 file | Cấu hình Bubblewrap đóng gói PWA thành APK |
| `tests/` | 9 test pytest | analytics, database, api repository, auth, scraper, services, openapi, cấu hình mobile/PWA |
| `scripts/` | 2 script | `migrate_sqlite_to_postgres.py`, `start_mobile_api.ps1` |
| `docs/` | 3 tài liệu | `ARCHITECTURE.md`, `ANDROID_RELEASE.md`, `PRODUCT_MVP.md` |
| `backups/code-20260902-235922/` | 8 file | Backup code app monolith 2.6.0 do tính năng tự cập nhật ZIP sinh ra |
| `xsmb-manager.zip`, `xsmb-manager1.zip` | 25 / 26 KB | Gói cập nhật ZIP chứa `app.py` monolith 74 KB (legacy) |
| `xsmb.db` | 7.6 MB | **Dữ liệu người dùng**: 2 168 kỳ XSMB (2020-09-03 → 2026-09-03), 58 536 dòng kết quả, 9 kỳ/162 dòng XSMN |
| `api-mobile.db` | 7.9 MB | Bản sao dữ liệu trên + bảng `users` cho API SQLite khi chạy local |
| `xsmb-backup-v2.7.db` | 96 KB | Backup rời 2 kỳ gần nhất |
| `.venv/` | 13 412 file / 399 MB | Python venv local (đã gitignore) |
| `analyze.log`, `fluttertest.log` | 1.8 KB | Log `flutter analyze`/`flutter test` cũ |
| `__pycache__/`, `.pytest_cache/`, `mobile/build/`, `trying_flutter/build/`, `frontend/.next/`, `frontend/test-results/` | ~2.2 GB | Cache & artifact build, sinh lại 100% |

Vấn đề chính:

1. **Trùng lặp app Flutter**: `mobile/` và `trying_flutter/` cùng đích nhưng khác kiến trúc — một bên có API client thật nhưng UI nghèo, một bên có UI/statistics đầy đủ nhưng chỉ dùng dữ liệu mẫu và tên package vẫn là `trying_flutter`.
2. **Dữ liệu lẫn source ở thư mục gốc**: 3 file `.db`, 2 gói ZIP, log, cache nằm chung với code.
3. **Tên thư mục không thống nhất**: `frontend/` đứng cạnh `mobile/`; backend Python rải ở gốc.
4. **Flutter chưa có tầng provider**: `ApiClient` chỉ biết đúng một backend, không timeout/retry/fallback/validation theo nguồn.
5. **Flutter chưa có database local**: chỉ cache JSON vào `SharedPreferences`, không đủ cho lịch sử nhiều năm + backtest.
6. **Flutter chưa có scoring/backtest**: chỉ có tần suất thô; logic tốt nằm ở `analytics.py` và `trying_flutter/lib/src/logic/statistics.dart`.
7. **Backend chưa có endpoint tổng hợp** (`/xsmb/latest`, `/xsmn/{date}`, `/history`, `/health` chuẩn hoá) mà app cần cho auto-sync.

## 2. Phân loại KEEP / MOVE / REFACTOR / DELETE

### KEEP — tài sản của dự án

- `xsmb.db`, `api-mobile.db`, `xsmb-backup-v2.7.db`: dữ liệu lịch sử nhiều năm, **tuyệt đối không xoá**.
- `xsmb_manager/*.py` và `xsmb_manager/api/*`: backend + logic nghiệp vụ đang chạy tốt, có test.
- `tests/*.py` (bộ test pytest), `.github/workflows/*`, `scripts/*`, `docs/*`, `compose.yaml`, `render.yaml`, `railway.toml`, `.env.example`.
- `mobile/android/`, `mobile/pubspec.yaml`, `mobile/test/*`: app Android thật, có cấu hình ký và CI.
- `trying_flutter/lib/**`, `test/**`, `tool/**`: **giữ code**, chuyển vào `mobile/`.

### MOVE — di chuyển, không sửa logic

| Từ | Đến | Lý do |
| --- | --- | --- |
| `frontend/` | `web/` | Thống nhất `mobile/` + `web/` |
| `twa/` | `web/twa/` | TWA là cách đóng gói chính PWA đó |
| `app.py`, `xsmb_manager/`, `tests/`, `pyproject.toml`, `requirements*.txt`, `Dockerfile`, `Dockerfile.api`, `.dockerignore`, `.streamlit/`, `sample_xsmb.csv`, `version.txt` | `backend/` | Gộp backend Python vào một chỗ |
| `xsmb.db`, `api-mobile.db`, `xsmb-backup-v2.7.db` | `data/` | Tách dữ liệu khỏi source |
| `xsmb-manager*.zip` | `data/releases/legacy/` | Gói phát hành cũ, giữ để tham chiếu |
| `backups/` | `data/backups/code/` | Backup code do tính năng ZIP sinh ra |
| `ROADMAP_COMMERCIAL.md` | `docs/` | Là tài liệu, không phải file chạy |
| `trying_flutter/{lib,test,tool,web}` | `mobile/` | Hợp nhất hai app Flutter thành một |

### REFACTOR — đã thực hiện

- `mobile/lib` tách thành `core/`, `data/{models,local,providers,repositories}`, `domain/{statistics,scoring,backtest}`, `ui/`.
- `ApiClient` một-nguồn → `LotteryDataProvider` + chuỗi `BackendApiProvider → GitHubJsonProvider → LocalCacheProvider`, có timeout, retry, validation, logging, timestamp, source attribution.
- Backend thêm nhóm endpoint chuẩn hoá (giữ endpoint cũ để không phá client hiện có).
- `scripts/*`, Dockerfile, compose, render, railway, CI cập nhật theo cấu trúc mới.

### DELETE — đã xoá (sinh lại được 100%)

- `__pycache__/` (mọi cấp trừ `.venv`), `.pytest_cache/`, `analyze.log`, `fluttertest.log`.
- `mobile/build/` (1 218 MB), `trying_flutter/build/` (948 MB), `.dart_tool/` của cả hai app.
- `web/.next/`, `web/test-results/`, `web/tsconfig.tsbuildinfo`.
- `trying_flutter/` (khung app trùng) sau khi đã chuyển code sang `mobile/`.
- `mobile/lib/src/{screens,services,widgets,models}` (app cũ) và test cũ tương ứng.

### KHÔNG tự xoá — chờ xác nhận

- `web/node_modules/` (884 MB): xoá được nhưng phải `npm install` lại → giữ để không gián đoạn dev web.
- `.venv/` (399 MB): cần cho `pytest`/`uvicorn` local → giữ, đã gitignore.
- `data/backups/code/code-20260902-235922/`, `data/releases/legacy/*.zip`: code monolith 2.6.0 cũ, đã có trong lịch sử git.
- `xsmb-manager1.zip` (26 KB) còn ở thư mục gốc vì bị tiến trình khác giữ file lúc di chuyển; có thể chuyển vào `data/releases/legacy/` hoặc xoá.

## 3. Cấu trúc sau khi dọn

```text
xsmb-manager/
├── backend/            # Python: Streamlit + FastAPI + logic dùng chung
│   ├── app.py, xsmb_manager/, tests/
│   ├── Dockerfile, Dockerfile.api, requirements*.txt, pyproject.toml
├── mobile/             # Flutter: app duy nhất cho Android + Web
│   ├── lib/{core,data,domain,logic,ui}, test/, tool/, android/, web/
├── web/                # Next.js PWA + web/twa/ (Bubblewrap)
├── data/               # database, backup, bản phát hành (git-ignored)
├── docs/               # ARCHITECTURE, ANDROID_RELEASE, PRODUCT_MVP, AUDIT, ROADMAP
├── scripts/            # migrate PostgreSQL, chạy API local
├── compose.yaml, render.yaml, railway.toml, .env.example
├── README.md, .gitignore
```

## 4. Kết quả Phase 2–13

| Phase | Nội dung | Kết quả |
| --- | --- | --- |
| 1 | Kiểm toán + dọn dẹp + tái cấu trúc | Xong; 22 test Python vẫn xanh sau khi di chuyển |
| 2 | `LotteryDataProvider` + chuỗi dự phòng | `mobile/lib/src/data/providers/*`: 4 hiện thực + `LotteryProviderChain` ghi `provider_status`, log, đo độ trễ |
| 3 | Nguồn dữ liệu miễn phí | Backend API của dự án (chính) + HTML công khai `xoso.com.vn` (native) + cache cục bộ; không cần API key, không có secret trong source |
| 3 | Endpoint chuẩn hoá | `/api/v1/health`, `/api/v1/xsmb/latest`, `/api/v1/xsmb/{date}`, `/api/v1/xsmn/latest`, `/api/v1/xsmn/{date}`, `/api/v1/history` + 11 test mới |
| 4 | GitHub an toàn | `.env.example` giữ mẫu; `.gitignore` chặn `.env`, `*.jks`, `*.keystore`, `*.pem`, `data/**` và file ghi chú tài khoản phát hiện ở gốc repo |
| 5 | Database local | 8 bảng (draws, draw_results, stations, sync_history, provider_status, prediction_runs, prediction_results, backtest_runs) với unique key; SQLite native + localStorage cho web |
| 6 | Engine thống kê 00–99 | `domain/statistics`: occurrences, drawHits, tỷ lệ kỳ, rolling 10/30/60/90, gap, avg gap, độ lệch, momentum, recency, stability, EWMA, xu hướng ngắn/trung/dài, z-score |
| 7 | Scoring model | `domain/scoring/PredictionEngine`: 9 feature chuẩn hoá, trọng số cấu hình được, Điểm thống kê 0–100, kèm cảnh báo không phải xác suất |
| 8 | Backtest engine | `domain/backtest/BacktestEngine`: walk-forward một lượt, cửa sổ 30/90/180/365/toàn bộ, Top 1/4/10, precision@K, baseline tần suất + ngẫu nhiên có seed, kết luận trung thực khi không vượt baseline |
| 9 | UI Top 4 | `ui/tabs/top4_tab.dart`: số, điểm, tần suất 10/30 kỳ, gap, xu hướng, yếu tố đóng góp, hiệu quả backtest của cửa sổ đang chọn |
| 10 | Auto sync | `LotteryRepository.sync()`: kiểm tra ngày cuối → chỉ tải khoảng thiếu → kiểm định → upsert → ghi `sync_history`; UI hiển thị nguồn, số bản ghi mới, lỗi, thời điểm cập nhật |
| 11 | UI | Shell 7 khu vực (Tổng quan, Top 4, Phân tích, Backtest, Kho dữ liệu, Nguồn & cài đặt, Phương pháp), theme sáng/tối, chữ trên nền đúng palette |
| 12 | Test | 74 test Flutter (thống kê, scoring, backtest, provider fallback, database chống trùng, parser HTML, contract API thật, repository sync, widget) + 33 test Python |
| 13 | Build | `flutter analyze` sạch; `flutter build apk --release` OK (51.4 MB universal); `flutter build web --release` OK |

### Lệnh kiểm chứng

```bash
cd backend && ..\.venv\Scripts\python.exe -m pytest -q     # 33 passed
cd mobile && flutter analyze && flutter test               # sạch, 74 passed
flutter build apk --release                                # APK release (debug key)
flutter build web --release                                # bản web
```

### Kiểm chứng end-to-end (đã chạy)

1. Chạy API thật với SQLite: `DATABASE_URL=sqlite+pysqlite:///data/api-mobile.db`, `uvicorn xsmb_manager.api.main:app`.
2. `GET /api/v1/health` → `{"status":"ok","database":"ok"}`.
3. `GET /api/v1/xsmb/latest?days=2` → 2 kỳ, mỗi kỳ 27 giải, ngày 2026-09-03, đài “Hội đồng XSKT miền Bắc”.
4. `GET /api/v1/xsmn/latest?days=1` → 3 đài, mỗi đài 18 giải.
5. Lưu hai payload này thành fixture (`mobile/test/fixtures/backend_xsmb_latest.json`, `backend_xsmn_latest.json`) và kiểm thử `BackendApiProvider` parse + kiểm định thành công trên cả hai.

## 5. Audit collector và cập nhật incremental — 2026-09-13

- Trước cập nhật: `MAX(draw_date) = 2026-09-03` cho cả XSMB và XSMN.
- Nguyên nhân dừng: repo chỉ có sync thủ công từ UI/API, không có CLI hoặc lịch
  chạy collector. Parser/provider không phải nguyên nhân; nguồn vẫn trả đủ dữ
  liệu ngày 04/09 và 12/09.
- Kỳ ngày 13/09 chưa hoàn tất tại thời điểm kiểm tra buổi sáng (giờ Việt Nam),
  nên collector dừng an toàn ở 12/09 thay vì ghi HTML chưa có kết quả.
- Khoảng thiếu đã xử lý: 04/09–12/09 (9 ngày mỗi vùng).
- XSMB: thêm 9 kỳ / 243 kết quả, provider `xosodaiphat.com`.
- XSMN: thêm 29 lượt đài / 522 kết quả, provider `xoso.com.vn`.
- Sau cập nhật: hai database `data/xsmb.db` và `data/api-mobile.db` cùng có
  `MAX(draw_date) = 2026-09-12`; không thiếu ngày trong khoảng, không bản ghi
  trùng, không kỳ sai số lượng giải và không lỗi validation.
- Backup trước khi ghi nằm trong `data/backups/database/` (git-ignored).
- Collector mới: `scripts/collector/update_lottery.py`; exporter snapshot:
  `scripts/collector/export_public_data.py`.

