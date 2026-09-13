# Backend XSMB/XSMN

Một chỗ chứa toàn bộ mã Python: app Streamlit (cá nhân, chạy Windows), FastAPI (dùng cho web + mobile) và logic nghiệp vụ dùng chung.

## Thành phần

| File | Vai trò |
| --- | --- |
| `app.py` | Entry point mỏng của Streamlit |
| `xsmb_manager/ui.py` | Giao diện Streamlit (dashboard, thống kê, backtest, Top 4, xuất data) |
| `xsmb_manager/analytics.py` | Hàm thuần: chuẩn hoá ngày, parse CSV, thống kê, ranking, walk-forward backtest |
| `xsmb_manager/config.py` | Đường dẫn database (`data/`), metadata giải, lịch đài XSMN, danh sách nguồn |
| `xsmb_manager/database.py` | Repository SQLite (schema, upsert chống trùng, log đồng bộ) |
| `xsmb_manager/ports.py` | Protocol cho repository và scraper (dependency inversion) |
| `xsmb_manager/scraper.py` | HTTP client + parser HTML cho 3 nguồn XSMB/XSMN, ghi `source_health` |
| `xsmb_manager/services.py` | Use case đồng bộ theo khoảng ngày |
| `xsmb_manager/api/` | FastAPI + JWT + SQLAlchemy models/repository (PostgreSQL hoặc SQLite) |

## Chạy Streamlit

```bash
python -m venv .venv            # ở thư mục gốc repo
.venv\Scripts\activate
pip install -r backend/requirements.txt
cd backend
python -m streamlit run app.py
```

Database được đọc/ghi tại `../data/xsmb.db`. Nếu còn file `xsmb.db` ở thư mục gốc thì `config.resolve_db_path()` vẫn nhận để tránh mất dữ liệu khi nâng cấp.

## Chạy API local

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_mobile_api.ps1
```

Script đặt `DATABASE_URL` trỏ tới `data/api-mobile.db` (SQLite) và sinh `JWT_SECRET` ngẫu nhiên cho mỗi lần chạy. API chạy ở `http://localhost:8000`, tài liệu tại `/docs`, health check tại `/health`.

## Kiểm thử

```bash
cd backend
python -m pytest -q
```

## Docker

Từ thư mục gốc repo (context là repo root):

```bash
docker build -f backend/Dockerfile.api -t xsmb-api .
docker build -f backend/Dockerfile -t xsmb-streamlit .
```
