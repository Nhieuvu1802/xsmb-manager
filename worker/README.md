# Cloudflare Worker API v1 (`xsmb-manager-api`)

Worker đọc trực tiếp các snapshot công khai trong `public-data/` (đã được collector
kiểm định trước khi ghi) và phục vụ chúng qua hợp đồng HTTP giống FastAPI
(`backend/xsmb_manager/api/schemas.py`). Nhờ vậy app Flutter và website chỉ cần
một định dạng dữ liệu duy nhất.

- Không có secret, token, credential hay binding (KV/D1/R2) nào.
- Không gọi mạng ngoài lúc runtime: dữ liệu được bundle vào Worker lúc build.
- Dữ liệu mới = collector cập nhật `public-data/` → push lên GitHub → Cloudflare
  Git deployment tự build lại.

Cập nhật dữ liệu (chi tiết ở `scripts/collector/README.md`):

```powershell
.venv\Scripts\python.exe scripts\collector\update_lottery.py --mirror-database data\api-mobile.db
.venv\Scripts\python.exe scripts\collector\backfill_history.py --region all --days 365 --mirror-database data\api-mobile.db
.venv\Scripts\python.exe scripts\collector\export_public_data.py
```

## Endpoint

| Endpoint | Mô tả |
| --- | --- |
| `GET /v1/health` | Trạng thái API + `datasetDate` + `datasetVersion` |
| `GET /v1/xsmb/latest?days=7` | Các kỳ XSMB gần nhất, 27 giải/kỳ |
| `GET /v1/xsmn/latest?days=7&province=Long%20An` | Các kỳ XSMN, 18 giải/đài |
| `GET /v1/xsmb/{YYYY-MM-DD}` | Đúng một ngày (404 JSON nếu chưa có) |
| `GET /v1/xsmn/{YYYY-MM-DD}` | Đúng một ngày của một đài |
| `GET /v1/xsmb/history?start=&end=` | Lọc theo khoảng ngày (tối đa cả cửa sổ 365 ngày) |
| `GET /v1/xsmn/history?start=&end=` | Lọc theo khoảng ngày (tối đa cả cửa sổ 365 ngày) |
| `GET /v1/config`, `GET /v1/manifest` | Metadata công khai |
| `GET /` | Danh sách endpoint + phiên bản dataset |

Quy ước: mọi phản hồi là JSON (kể cả lỗi), có CORS, `ETag`/`304` và
`Cache-Control` phù hợp. Riêng `/latest`, `days` nhận 1–90 (mặc định 7);
`/history` dùng `start`/`end` nên lấy được cả cửa sổ có trong dataset. Lỗi trả
`{ status: "error", code, message, detail }`.

Ví dụ:

```json
{
  "status": "ok",
  "apiVersion": "v1",
  "datasetDate": "2026-09-12",
  "datasetVersion": "c38bd612c87c942d"
}
```

## Chạy local

```powershell
cd worker
npm install
npm run build       # kiểm tra public-data trước khi chạy
npx wrangler dev    # http://127.0.0.1:8787
```

Kiểm thử:

```powershell
npm test            # vitest + @cloudflare/vitest-pool-workers (SELF.fetch)
npm run typecheck   # tsc --noEmit
npm run dry-run     # build bundle đúng như khi deploy, không cần đăng nhập
```

## Deploy trên Cloudflare (Git integration / Workers Builds)

| Mục | Giá trị |
| --- | --- |
| Worker directory (root directory) | `worker` |
| `package.json` | `worker/package.json` |
| Wrangler config | `worker/wrangler.jsonc` |
| Build command | `npm ci` |
| Deploy command | `npx wrangler deploy` |
| Production branch | `main` |

Sau khi deploy lần đầu thành công, thêm custom domain `api.vvn.freedev.app`
trong dashboard (Worker → Settings → Domains & Routes → Add custom domain).
Không cần khai báo `routes` trong `wrangler.jsonc` nên deploy không phụ thuộc
zone/DNS đã tồn tại hay chưa.

`compatibility_date` được ghim trong `wrangler.jsonc`; `vars` chỉ chứa giá trị
công khai (`API_VERSION`, `ALLOWED_ORIGINS`, `ENVIRONMENT`). Muốn siết CORS thì
đổi `ALLOWED_ORIGINS` thành danh sách origin, ví dụ
`https://vvn.freedev.app,https://xsmb-manager.pages.dev`.

## Độ sâu dữ liệu

- Worker bundle `public-data/{xsmb,xsmn}/latest.json` (một ngày) và
  `history.json` — **cửa sổ 365 ngày** (`historyDays` trong `manifest.json`).
  Nhờ vậy `/history?start=&end=` trả được cả năm kỳ thay vì đúng một ngày.
- Cửa sổ có thể ít hơn 365 ngày khi nguồn thiếu ngày: XSMB hiện có 361 kỳ/365 ngày
  (thiếu 2026-02-16…19, nghỉ Tết), XSMN đủ 365 ngày với nhiều đài mỗi ngày.
- Đổi độ sâu: `scripts/collector/export_public_data.py --days 180`. Muốn thêm ngày
  cũ vào database thì chạy `scripts/collector/backfill_history.py` trước khi export.
- Miền Trung chưa có dữ liệu (giống backend FastAPI).
- Các endpoint cần database ghi (`/auth/token`, `/draws/*`, `/sync/*`) vẫn phải
  dùng backend FastAPI, không thuộc Worker này.
