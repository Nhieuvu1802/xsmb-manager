# Cloudflare Worker Auto-Deploy

Triển khai tự động Cloudflare Worker sử dụng GitHub Actions + `cloudflare/wrangler-action`.

## Yêu cầu

### 1. Tạo Cloudflare API Token

1. Đăng nhập Cloudflare Dashboard: https://dash.cloudflare.com
2. Go to **My Profile** → **API Tokens** → **Create Token**
3. Use template **"Cloudflare Workers Scripts"**
4. Permission scope:
   - `Cloudflare Workers: Edit`
   - `Cloudflare R2 Storage: Edit` (để manage bucket)
   - `Account: Read` (để lấy account ID)
5. Account Resources: Chọn **All accounts** hoặc account cụ thể
6. Zone Resources: **All zones** hoặc zone cụ thể (nếu dùng custom domain)
7. TTL: Set thời hạn phù hợp
8. **Copy token** — chỉ hiện 1 lần!

### 2. Lấy Account ID

1. Cloudflare Dashboard →右上角 account name → **Account ID**
2. Hoặc: Workers & Pages → Overview → sidebar có Account ID

### 3. Thêm GitHub Secrets

1. Go to repo: **Nhieuvu1802/xsmb-manager**
2. Settings → Secrets and variables → Actions
3. Thêm 2 secrets:

| Secret Name | Giá trị |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Token từ bước 1 |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID từ bước 2 |

### 4. Tạo R2 Bucket (một lần)

Chạy trên local (sau khi `wrangler login`):

```bash
cd worker
wrangler r2 bucket create xsmb-data
```

Hoặc workflow sẽ tự tạo khi deploy lần đầu.

## Workflow

### deploy-worker.yml

**Trigger:** Push to `main` (thay đổi worker/ hoặc public-data/)

**Pipeline:**
1. `validate` job:
   - Typecheck TypeScript
   - Chạy 24 tests
   - Validate public-data snapshot
2. `deploy` job (chỉ khi validate pass):
   - Deploy Worker lên Cloudflare
   - Cron triggers tự động deploy theo wrangler.jsonc
   - Tạo R2 bucket nếu chưa có

### ci.yml

**Trigger:** Mọi push/PR

**Pipeline:**
1. `web` job: Next.js build + lint
2. `worker` job: Typecheck + test + validate
3. `test` job: Python backend tests
4. `container` job: Docker build (chỉ main)

## Cron Triggers

Wrangler.jsonc đã cấu hình:

```
crons:
  - "15,30 9 * * *"    # 09:15, 09:30 UTC (16:15, 16:30 ICT) - XSMN
  - "0 10 * * *"        # 10:00 UTC (17:00 ICT) - XSMN fallback
  - "15,30 11 * * *"    # 11:15, 11:30 UTC (18:15, 18:30 ICT) - XSMB
  - "0 12 * * *"        # 12:00 UTC (19:00 ICT) - XSMB fallback
```

Cron tự activate khi Worker deploy thành công.

## R2 Storage

R2 bucket `xsmb-data` lưu master dataset:
- `latest/xsmb.json`
- `latest/xsmn.json`
- `history/xsmb.json`
- `history/xsmn.json`
- `manifest.json`

Worker ưu tiên đọc R2 → fallback sang bundled snapshot.

## Custom Domain

Sau khi deploy lần đầu thành công:

1. Cloudflare Dashboard → Workers & Pages → xsmb-manager-api
2. Settings → Domains & Routes
3. Thêm custom domain: `api.vvn.freedev.app`
4. Hoặc: Route pattern: `api.vvn.freedev.app/*`

## Monitoring

- Cloudflare Dashboard → Workers & Pages → xsmb-manager-api
- Analytics: Request count, errors, latency
- Logs: Workers & Pages → Logs
- Cron: Workers & Pages → Triggers → Cron Triggers

## Rollback

Nếu deploy sai:

```bash
# Local rollback
cd worker
git checkout <previous-commit>
wrangler deploy

# Hoặc revert PR trên GitHub
```

## Troubleshooting

### "No account id found"
→ Thêm `CLOUDFLARE_ACCOUNT_ID` secret

### "Unauthorized"
→ Kiểm tra `CLOUDFLARE_API_TOKEN` có đúng scope

### R2 bucket already exists
→ Không sao, `continue-on-error: true` xử lý tự động

### Cron không chạy
→ Kiểm tra Workers & Pages → Triggers → Cron Triggers
→ Cron tự activate khi deploy, có thể delay 1-2 phút

### Worker deploy fail
→ Kiểm tra CI log → thường do typecheck hoặc test fail
