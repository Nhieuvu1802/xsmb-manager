# Cloudflare Worker API v1 (`xsmb-manager-api`)

Worker đọc trực tiếp các snapshot công khai trong `public-data/` (đã được collector
kiểm định trước khi ghi) và phục vụ chúng qua hợp đồng HTTP giống FastAPI
(`backend/xsmb_manager/api/schemas.py`). Nhờ vậy app Flutter và website chỉ cần
một định dạng dữ liệu duy nhất.

- Không có secret, token, credential hay binding (KV/D1/R2) nào.
- Không gọi mạng ngoài lúc runtime: dữ liệu được bundle vào Worker lúc build.
- Dữ liệu mới = collector cập nhật `public-data/` → push lên GitHub → Cloudflare
  Git deployment tự build lại.

## Endpoint

| Endpoint | Mô tả |
| --- | --- |
| `GET /v1/health` | Trạng thái API + `datasetDate` + `datasetVersion` |
| `GET /v1/xsmb/latest?days=7` | Các kỳ XSMB gần nhất, 27 giải/kỳ |
| `GET /v1/xsmn/latest?days=7&province=Long%20An` | Các kỳ XSMN, 18 giải/đài |
| `GET /v1/xsmb/{YYYY-MM-DD}` | Đúng một ngày (404 JSON nếu chưa có) |
| `GET /v1/xsmn/{YYYY-MM-DD}` | Đúng một ngày của một đài |
| `GET /v1/xsmb/history?start=&end=` | Lọc theo khoảng ngày |
| `GET /v1/xsmn/history?start=&end=` | Lọc theo khoảng ngày |
| `GET /v1/config`, `GET /v1/manifest` | Metadata công khai |
| `GET /` | Danh sách endpoint + phiên bản dataset |

Quy ước: mọi phản hồi là JSON (kể cả lỗi), có CORS, `ETag`/`304` và
`Cache-Control` phù hợp. `days` nhận 1–90 (mặc định 7). Lỗi trả
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

## Giới hạn hiện tại

- Snapshot chỉ chứa **kỳ mới nhất** của mỗi miền, nên `/latest` và `/history`
  chỉ trả được ngày có trong `public-data/`. Muốn nhiều ngày hơn thì mở rộng
  `build_latest_payload` trong `backend/xsmb_manager/public_export.py` (ví dụ
  `--days 30`) rồi chạy lại `scripts/collector/export_public_data.py`.
- Miền Trung chưa có dữ liệu (giống backend FastAPI).
- Các endpoint cần database ghi (`/auth/token`, `/draws/*`, `/sync/*`) vẫn phải
  dùng backend FastAPI, không thuộc Worker này.
