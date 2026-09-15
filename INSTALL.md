# 🚀 Hướng dẫn cài đặt — XSMB Manager "Thống Kê 24"

Monorepo gồm 3 client + 1 backend: **Web** (Next.js PWA), **Mobile** (Flutter), **Backend** (Python/FastAPI), **Worker** (Cloudflare Workers), plus **9Router** (AI Router) & **Proxy Pool**.

---

## 📋 Yêu cầu hệ thống

| Thành phần | Phiên bản tối thiểu | Ghi chú |
|---|---|---|
| **Git** | 2.40+ | `git --version` |
| **Node.js** | 20+ | `node --version` |
| **Python** | 3.12+ | `python --version` |
| **Docker** | 24+ | `docker --version` (cho 9Router + backend) |
| **Flutter** | 3.x | Chỉ cần nếu chạy mobile |
| **PostgreSQL** | 16 | Docker hoặc local (cho backend API) |

---

## 1️⃣ Clone & cài đặt nhanh

```bash
git clone https://github.com/Nhieuvu1802/xsmb-manager.git
cd xsmb-manager
copy .env.example .env
# Edit .env — điền JWT_SECRET, ADMIN_PASSWORD, DATABASE_URL
```

---

## 2️⃣ Backend (FastAPI + PostgreSQL)

### Local (SQLite — phát triển nhanh)

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r backend/requirements-dev.txt
cd backend
python -m pytest -q
python -m streamlit run app.py  # Dashboard Streamlit
```

### Docker (PostgreSQL — production-like)

```bash
docker compose up --build       # postgres + api + web
```

API: `http://localhost:8000` | Health: `http://localhost:8000/health`

---

## 3️⃣ Web (Next.js PWA "Thống Kê 24")

```bash
cd web && npm install
npm run dev          # http://localhost:3000
npm run check        # typecheck + lint + test + build
```

Deploy Vercel: Root Directory = `web`, Framework = Next.js

---

## 4️⃣ Mobile (Flutter — Android + Web)

```bash
cd mobile
flutter pub get && flutter analyze && flutter test && flutter run
flutter build apk --release
mobile\tool\build_apk.bat     # Build universal + tách ABI → mobile/dist/
```

---

## 5️⃣ 9Router — Free AI Router & Token Saver ⭐

9Router là AI API gateway miễn phí, **60+ providers**, **100+ models** (Claude, GPT, Gemini...) với auto-fallback 3-tier và RTK tiết kiệm 20-40% tokens.

### Khởi động nhanh

```powershell
.\scripts\start-9router.ps1     # PowerShell — tự động everything
```

Hoặc thủ công:

```bash
docker compose -f compose.proxy-pool.yaml up -d
python scripts/setup-9router-models.py --action setup
```

### 5 Combo Model 3-Tier tối ưu

| Combo | Tier 1 (Subscription) | Tier 2 (Cheap) | Tier 3 (FREE) |
|---|---|---|---|
| **Claude Elite** | `cc/claude-opus-4-6` | `glm/glm-5.1` | `iflow/claude-opus-4-6` |
| **Claude Fast** | `cc/claude-sonnet-4-5` | `minimax/MiniMax-M2.7` | `qwen/qwen3-coder-plus` |
| **Gemini Pro** | `gemini/gemini-3.1-pro-preview` | `glm/glm-5.1` | `oc/claude-opus-4-6` |
| **Codex Value** | `codex/gpt-5-codex` | `deepseek/deepseek-v3.2` | `openrouter/google-gemini-3.1-flash-lite-preview` |
| **Copilot Hybrid** | `copilot/claude-sonnet-4.5` | `kimi/kimi-k2.5` | `nim/qwen/qwen3-coder-480b-a35b-instruct` |

### Trỏ tools tới 9Router

| Tool | Cấu hình |
|---|---|
| **Claude Code** | `export ANTHROPIC_BASE_URL=http://localhost:20128/v1` |
| **Cursor** | Settings → Models → API Base URL → `http://localhost:20128/v1` |
| **Cline** | Settings → API Base URL → `http://localhost:20128/v1` |
| **Codex** | `export OPENAI_BASE_URL=http://localhost:20128/v1` |

Dashboard: `http://localhost:20128` | Lệnh phụ trợ:
```bash
python scripts/setup-9router-models.py --action guide
python scripts/setup-9router-models.py --action combos
python scripts/setup-9router-models.py --action list
python scripts/setup-9router-models.py --action verify
```

---

## 6️⃣ Cloudflare Worker (Edge API)

```bash
cd worker && npm install
npx wrangler dev        # Local
npx wrangler deploy     # Deploy
```

---

## 📂 Cấu trúc thư mục

```
xsmb-manager/
├── backend/                    # FastAPI + Streamlit
│   ├── xsmb_manager/api/       # FastAPI routes + models
│   └── tests/
├── web/                        # Next.js PWA
│   ├── app/                    # App Router
│   ├── components/
│   └── prisma/
├── mobile/                     # Flutter Android + Web
│   └── lib/src/
├── worker/                     # Cloudflare Workers
│   └── src/
├── scripts/                    # Automation scripts
│   ├── setup-9router-models.py # Auto-configure 9Router models
│   ├── start-9router.ps1       # Launch 9Router stack
│   ├── proxy-rotate.py         # Proxy rotation sidecar
│   └── collector/              # Data collection
├── compose.yaml                # Docker: postgres + api + web
├── compose.proxy-pool.yaml     # Docker: 9Router + proxy pool
├── .env.example                # Backend env template
├── .env.proxy-pool             # 9Router env template
├── INSTALL.md                  # Tài liệu cài đặt này
└── README.md
```

---

## 🔑 Biến môi trường quan trọng

| Biên | Mô tả | Bắt buộc |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection | ✅ |
| `JWT_SECRET` | Secret JWT (≥32 bytes) | ✅ |
| `ADMIN_PASSWORD` | Password admin | ✅ |
| `NEXT_PUBLIC_API_URL` | API endpoint | ✅ |
| `ANTHROPIC_API_KEY` | Claude Code (9Router) | Optional |
| `OPENAI_API_KEY` | GPT/Codex (9Router) | Optional |
| `GLM_API_KEY` | GLM — Tier 2 cheap | Optional |

---

## 🛠 Common Issues

| Vấn đề | Giải pháp |
|---|---|
| Docker compose fail | Kiểm tra Docker Desktop đang chạy |
| 9Router không start | `docker compose -f compose.proxy-pool.yaml logs 9router` |
| Port 20128 trùng | Đổi `NINEROUTER_PORT` trong `.env.proxy-pool` |
| Backend DATABASE_URL error | `docker compose up postgres` trước |
| Flutter build fail | `flutter clean && flutter pub get` |
| Model không hoạt động | Kiểm tra API key trong Dashboard 9Router |

---

## 📖 Tài liệu thêm

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Kiến trúc hệ thống
- [`docs/ROADMAP_COMMERCIAL.md`](docs/ROADMAP_COMMERCIAL.md) — Roadmap thương mại
- [`docs/ANDROID_RELEASE.md`](docs/ANDROID_RELEASE.md) — Phát hành APK
- [9Router GitHub](https://github.com/decolua/9router) — Docs 9Router
- [9Router Dashboard](http://localhost:20128) — Quản lý models & providers
