# Data Pipeline

## Architecture Overview

```
Lottery Providers (upstream websites)
        │
        ▼
Multi-provider Collector (Python backend or Cloudflare Worker)
        │
        ▼
Parse → Normalize → Validate → Deduplicate
        │
        ▼
Master Dataset (Cloudflare R2 primary, public-data backup)
        │
        ├───────────────┬────────────────┐
        │               │                │
        ▼               ▼                ▼
  Cloudflare R2    GitHub Snapshot   Statistics
  PRIMARY STORAGE    BACKUP           Engine
        │                              │
        ▼                              ▼
  Cloudflare Worker API          Top4 Predictions
        │
        ├─── Website (laptopvvn.vercel.app)
        └─── Flutter App (SQLite cache)
```

## Source of Truth

1. **PRIMARY**: Cloudflare R2 bucket `xsmb-data`
2. **API**: Cloudflare Worker
3. **BACKUP**: GitHub `public-data/` snapshot
4. **CLIENT CACHE**: Flutter SQLite

## Data Flow

### Collection (scheduled via Cloudflare Cron)

1. Cron triggers at scheduled times (09:15, 09:30, 10:00, 11:15, 11:30, 12:00 UTC)
2. Worker determines which region to collect based on current ICT time
3. Fetch from primary provider → fallback on error
4. Parse response → normalize format
5. Validate: date, region, station, prize count, number format
6. Deduplicate: deterministic identity from region + station + date
7. Store to R2 (when R2 binding is active)
8. Update manifest.json in R2
9. GitHub snapshot updated by separate workflow

### Distribution

- Worker serves API from bundled snapshot (fallback) or R2
- Website fetches from Worker API
- Flutter fetches from Worker API → caches in SQLite

## Validation Rules

- Date must be valid ISO format (YYYY-MM-DD)
- Region must be "xsmb" or "xsmn"
- XSMB: exactly 27 prize results per draw
- XSMN: exactly 18 prize results per draw
- All prize values must be digits only
- No future dates allowed
- No duplicate draws (same region + station + date)
- datasetVersion must be deterministic and consistent

## Idempotency

Collector is idempotent:
- Running twice produces same result
- No duplicate data inserted
- Existing data is overwritten only if newer/valid
