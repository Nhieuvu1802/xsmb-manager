# Disaster Recovery

## Khôi phục R2 Data

Nếu R2 bucket bị mất hoặc corrupt:

```bash
# 1. Tạo lại bucket
wrangler r2 bucket create xsmb-data

# 2. Sync từ GitHub snapshot
# public-data/ chứa bản snapshot gần nhất
# Copy trực tiếp lên R2 bằng Wrangler

# 3. Deploy lại Worker
cd worker && wrangler deploy
```

## Khôi phục từ GitHub Snapshot

GitHub là backup secondary. Không phải primary source.

```bash
# Clone repository
git clone https://github.com/Nhieuvu1802/xsmb-manager.git

# public-data/ chứa:
# - manifest.json
# - status.json
# - config.json
# - xsmb/latest.json
# - xsmb/history.json (365 ngày)
# - xsmn/latest.json
# - xsmn/history.json (365 ngày)
```

## Rebuild Manifest

```bash
cd scripts/collector
python export_public_data.py
```

## Rebuild Statistics

Tính lại trên Worker khi gọi `/v1/statistics/00-99`:
- Không cần rebuild riêng, Worker tính real-time từ draw data.

## Rebuild Model/Top4

Gọi `/v1/predictions/top4`:
- StatisticalScore được tính từ draw history.
- Model version = `top4-v1` (hiện tại dùng statistical score).

## Rebuild Flutter SQLite

Xóa cache trong app → đồng bộ lại từ Worker API.
Flutter tự động tải lại 365 ngày khi cache trống.

## Redeploy Worker

```bash
cd worker
npm install
npm run build    # Verify public-data
npm run test     # Run tests
npm run typecheck
wrangler deploy
```

## Redeploy Website

Website deploy tự động trên Vercel khi push to main.

```bash
# Manual deploy
cd web
npm install
npm run build
vercel --prod
```

## Kiểm tra sau Disaster Recovery

1. `GET /v1/health` → status: "ok"
2. `GET /v1/manifest` → datasetVersion hợp lệ
3. `GET /v1/xsmb/latest` → có draws
4. `GET /v1/xsmn/latest` → có draws
5. Flutter: Mở app → kiểm tra dữ liệu mới nhất
6. Website: Mở laptopvvn.vercel.app → kiểm tra dữ liệu
