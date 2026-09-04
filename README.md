# Ứng dụng quản lý lịch sử XSMB & XSMN

Ứng dụng Streamlit lưu dữ liệu XSMB và các đài XSMN trong SQLite, cập nhật trực tuyến, lọc ngày và thống kê lô 2 số 00–99.

## Cài đặt và chạy

Yêu cầu Python 3.10 trở lên.

```bash
python -m venv .venv

# Windows
.venv\\Scripts\\activate

# macOS/Linux
source .venv/bin/activate

pip install -r requirements.txt
streamlit run app.py
```

## Kiến trúc và kiểm thử

`app.py` là entry point mỏng. Mã nguồn chính nằm trong `xsmb_manager/`:

- `ui.py`: giao diện và điều phối Streamlit.
- `analytics.py`: CSV, chuẩn hóa và thống kê thuần.
- `ports.py`: interface cho database và scraper.
- `database.py`: SQLite repository.
- `scraper.py`: HTTP client và HTML parser.
- `services.py`: các use case đồng bộ có dependency injection.

Chạy kiểm thử cục bộ:

```bash
pip install -r requirements-dev.txt
pytest -q
```

Workflow `.github/workflows/ci.yml` tự động compile và chạy test trên Python 3.10/3.12 cho mỗi push và pull request. Sau khi test xanh, workflow build Docker image; push vào nhánh `main` sẽ phát hành image lên GitHub Container Registry (GHCR).

## FastAPI và PostgreSQL

Sao chép `.env.example` thành `.env`, thay toàn bộ mật khẩu/secret mẫu rồi chạy:

```bash
docker compose up --build
```

- API: `http://localhost:8000/api/v1`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- Health check: `http://localhost:8000/health`

Trong Swagger, gọi `POST /api/v1/auth/token` hoặc bấm **Authorize**, nhập `ADMIN_USERNAME` và `ADMIN_PASSWORD`. Các endpoint đồng bộ và tạo user yêu cầu JWT của tài khoản admin; endpoint đọc kết quả được công khai.

Để chuyển dữ liệu từ `xsmb.db` hiện tại sau khi PostgreSQL đã chạy:

```bash
set DATABASE_URL=postgresql+psycopg://xsmb:password@localhost:5432/xsmb
python scripts/migrate_sqlite_to_postgres.py xsmb.db
```

Script có tính lặp lại: mỗi kỳ được upsert và thay dữ liệu kết quả tương ứng, không nhân bản bản ghi.

## React/Next.js frontend và PWA

Frontend nằm trong `frontend/`, dùng Next.js App Router và TypeScript. Chạy local:

```bash
cd frontend
copy .env.example .env.local
npm install
npm run dev
```

Giao diện gọi URL trong `NEXT_PUBLIC_API_URL`, hỗ trợ desktop/mobile, cache kết quả gần nhất, trạng thái offline, Web App Manifest và service worker. JWT quản trị chỉ giữ trong bộ nhớ tab, không ghi vào local storage.

### Deploy frontend

- **Vercel:** import repository, đặt **Root Directory** là `frontend`, thêm `NEXT_PUBLIC_API_URL=https://<api-domain>`.
- **Netlify:** import repository, đặt **Base directory** là `frontend`; `netlify.toml` đã cấu hình build. Thêm cùng biến `NEXT_PUBLIC_API_URL`.

### Deploy API/PostgreSQL

- **Railway:** tạo PostgreSQL service, deploy repository bằng `railway.toml`, rồi đặt `DATABASE_URL`, `JWT_SECRET`, `ADMIN_PASSWORD` và `CORS_ORIGINS=https://<frontend-domain>`.
- **Render:** dùng Blueprint `render.yaml`; nhập `ADMIN_PASSWORD` và domain frontend cho `CORS_ORIGINS` khi tạo service.

Sau khi có domain chính thức, cấu hình `CORS_ORIGINS` của API bằng đúng origin frontend, không dùng `*`. Có thể khai báo nhiều origin cách nhau bằng dấu phẩy cho production và preview.

## Flutter Android

Ứng dụng Flutter native nằm trong `mobile/`, dùng chung FastAPI cho XSMB/XSMN, có cache offline, thống kê tần suất và đăng nhập quản trị để đồng bộ. Xem [mobile/README.md](mobile/README.md) để chạy local và [docs/ANDROID_RELEASE.md](docs/ANDROID_RELEASE.md) để cấu hình chữ ký, tạo APK/AAB, GitHub Release và Google Play Internal testing.

Workflow `android-ci.yml` kiểm tra/build artifact Android cho mỗi thay đổi mobile. Workflow `android-release.yml` chỉ chạy thủ công, dùng upload key từ GitHub Secrets và có tuỳ chọn tải AAB lên Google Play.

## Android nhanh bằng PWA/TWA (phương án thay thế)

PWA có thể cài trực tiếp từ trình duyệt. Để phát hành Android qua Google Play với chi phí thấp, dùng Bubblewrap theo [twa/README.md](twa/README.md). Frontend cung cấp động `/.well-known/assetlinks.json` từ `ANDROID_PACKAGE_ID` và `ANDROID_SHA256_FINGERPRINTS`, tránh commit fingerprint giả hoặc khóa ký vào repository.

Trình duyệt sẽ mở tại `http://localhost:8501`. Database `xsmb.db` được tạo tự động cạnh `app.py`.

## Cập nhật trực tuyến

- Trong thanh bên, chọn một ngày hoặc khoảng ngày rồi bấm **Cập nhật từ Internet**.
- Có thể bật **Tự kiểm tra hôm nay khi mở app**. Trong mỗi phiên mở app, hệ thống chỉ tự kiểm tra một lần.
- Nguồn mặc định: trang kết quả theo ngày của Xoso.com.vn.
- Hệ thống chỉ ghi database khi tìm thấy đủ 27 số đúng cơ cấu giải XSMB. Ngày đã có sẽ được thay thế, không đếm trùng.
- Website nguồn có thể thay đổi HTML; khi đó app sẽ báo lỗi thay vì lưu dữ liệu thiếu.
- Bảng **XSMB trực tiếp hôm nay** tự làm mới riêng mỗi 30 giây và tự ghi SQLite khi đủ 27 số.
- Tự lưu luôn bật cho cả hai miền. Khi mở app, hệ thống tự bù tối đa 3 ngày tính từ kỳ cuối đã lưu; database hoàn toàn mới không tự tải hàng loạt.
- Tab trực tiếp **Miền Nam** tự nhận các đài mở thưởng trong ngày và tự lưu riêng theo `ngày + tỉnh` khi mỗi đài đủ 18 số.
- Để nhập lịch sử XSMN, chọn ngày/khoảng ngày ở thanh bên rồi bấm **Cập nhật XSMN cùng khoảng ngày**.
- Dưới mỗi bảng trực tiếp có mục mở sẵn **Kết quả hôm qua**. App ưu tiên dữ liệu SQLite; nếu thiếu sẽ tải trực tuyến, kiểm tra và lưu lại.

### Nguồn dự phòng và tự chuyển nguồn

- Xoso.com.vn, Xổ Số Đại Phát và Minh Ngọc.
- Mỗi nguồn có timeout 6 giây. Lỗi mạng, quá thời gian hoặc không đọc được đúng cơ cấu giải sẽ tự chuyển nguồn kế tiếp.
- Bảng `source_health` lưu độ trễ trung bình, số lần thành công/thất bại và trạng thái gần nhất. Lần sau app ưu tiên nguồn đã đo nhanh hơn.
- Tab **Backtest mô hình** hiển thị tình trạng nguồn để kiểm tra minh bạch.

## Giao diện

Trên đầu thanh bên có mục **🎨 Chỉnh màu giao diện** với ba lựa chọn: **Sáng rõ**, **Tối dịu** và **Tương phản cao**. Lựa chọn được áp dụng ngay cho nền, chữ, bảng kết quả và biểu đồ. Các bảng dùng lớp hiển thị riêng để tránh lỗi nền trắng nhưng chữ cũng màu trắng do dark mode của trình duyệt. Nếu vẫn thấy màu cũ sau khi nâng cấp, dừng app bằng `Ctrl+C`, chạy lại rồi nhấn `Ctrl+F5` trong trình duyệt.

## Thống kê XSMN

Tab **XSMN theo đài** hiển thị lịch 21 đài trong cả tuần và luôn cho chọn mọi đài, kể cả đài chưa có dữ liệu. Sau khi chọn tỉnh, có thể lọc thời gian, xem Top 10, bảng ước lượng và xuất CSV. XSMN được lưu trong `mn_draws` và `mn_results`; dữ liệu XSMB cũ trong `draws` và `results` không bị thay đổi.

## Dữ liệu nhiều năm và chuyển đổi

SQLite bật WAL, khóa ngoại, busy timeout, chỉ mục theo ngày/đài/số, schema version và nhật ký đồng bộ. Quy mô dữ liệu xổ số vài năm vẫn nhỏ đối với SQLite. Hãy sao lưu `xsmb.db` định kỳ và chạy `PRAGMA integrity_check;` trong DB Browser khi cần kiểm tra.

## Đồng bộ database backup

- App tự tìm `*.db` trong `backups/database/` và các file `*backup*.db` ở thư mục dự án mỗi khi mở.
- Chỉ file mới hoặc đã thay đổi được quét lại. Trạng thái nằm trong bảng `backup_sync_state`.
- Có thể tải lên nhiều file `.db`, `.sqlite`, `.sqlite3` trong tab **Xuất data**.
- Việc gộp dùng SQLite `ATTACH DATABASE`, thêm bản ghi còn thiếu và chống trùng bằng khóa duy nhất. Database chính được ưu tiên; backup gốc không bị sửa.
- Nút **Tạo database tổng hợp mới** dùng SQLite Backup API để tạo snapshot nhất quán kể cả khi WAL đang hoạt động.
- Kết quả tải trực tuyến vẫn được ghi thẳng theo giao dịch batch vào database chính ngay khi kỳ/đài đủ số.

Xem `ROADMAP_COMMERCIAL.md` để biết lộ trình chuyển sang FastAPI + PostgreSQL cho hệ thống online nhiều người dùng, và Flutter/React Native hoặc PWA/TWA cho Android APK.

## Backtest mô hình thống kê

Tab **Backtest mô hình** dùng walk-forward: mỗi kỳ kiểm tra chỉ dùng các kỳ quá khứ, không nhìn dữ liệu tương lai. App so sánh Bayes dài hạn, tần suất 10 kỳ, EWMA bán rã 30 kỳ và Hybrid 70/30 bằng tỷ lệ Top 10 có trúng và Brier score. Brier score thấp hơn là tốt hơn. Backtest chỉ đánh giá quá khứ, không bảo đảm dự báo tương lai.

## Top 4 kỳ tiếp theo

Tab **Ước lượng MB** và phần thống kê từng đài XSMN hiển thị bốn số đứng đầu cho kỳ tiếp theo. Khi có trên 30 kỳ, app tự chọn mô hình có Brier score backtest thấp nhất; nếu chưa đủ dữ liệu, app tạm dùng Hybrid 70/30. Mỗi số có phần trăm mô hình và thông tin bằng chứng đi kèm. Đây là xếp hạng thống kê, không phải cam kết trúng.

## Ước lượng kỳ tiếp theo

Tab **Ước lượng kỳ tiếp theo** hiển thị ngày dự kiến, Top 10 số và phần trăm mô hình. Công thức kết hợp 70% tỷ lệ lịch sử + 30% tỷ lệ 10 kỳ gần nhất, có làm trơn Laplace. Đây là ước lượng của mô hình từ dữ liệu quá khứ, không phải xác suất thật hoặc bảo đảm cho kết quả tương lai. Nên lọc ít nhất 30 kỳ, tốt hơn là 90–365 kỳ.

## Định dạng CSV

- Bắt buộc có cột ngày tên `date`, `ngay`, `ngày`, `draw_date` hoặc `ngay_quay`.
- Các cột còn lại được xem là cột kết quả. Một ô có thể chứa một hoặc nhiều số, cách nhau bằng dấu phẩy/khoảng trắng.
- Hỗ trợ file dạng rộng có các cột giải (`dac_biet`, `giai_nhat`, ...) và file `xsmb-2-digits.csv` dạng `date` + một/nhiều cột lô 2 số.
- Nên lưu CSV với UTF-8. Ứng dụng cũng thử UTF-8 BOM, CP1258 và Latin-1.
- Nếu nạp lại ngày đã có, kết quả của ngày đó được thay thế để tránh đếm trùng.

Xem `sample_xsmb.csv` để biết ví dụ.

## Quy ước thống kê

- Mỗi số trúng được lấy 2 chữ số cuối; ví dụ `12345` thành `45`, `7` thành `07`.
- Tần suất là tổng số lần số đó xuất hiện trong khoảng lọc.
- Số ngày gan là số ngày từ lần xuất hiện gần nhất tới ngày cuối khoảng lọc. Số chưa từng xuất hiện hiển thị `Chưa xuất hiện`.
- Xác suất ước lượng = số lần xuất hiện / số kỳ quay trong khoảng lọc. Đây là tỷ lệ thống kê, có thể lớn hơn 100% nếu một số xuất hiện nhiều lần trong một kỳ.
- Top 10 “ít nhất” bao gồm cả các số chưa xuất hiện trong N ngày.

## Sao lưu

Tab **Xuất & chất lượng data** kiểm tra kỳ đủ 27 số và cho tải dữ liệu gốc, thống kê, ước lượng hoặc toàn bộ database SQLite. Dữ liệu dài hơn giúp tỷ lệ thực nghiệm ổn định hơn nhưng không làm xổ số trở nên dự đoán chắc chắn.

## Cập nhật phần mềm bằng ZIP

Trong thanh bên, chọn ZIP phiên bản mới, xác nhận đã sao lưu database rồi bấm **Cài bản cập nhật**. App chỉ thay các file mã nguồn được cho phép, giữ nguyên `xsmb.db` và `.venv`, đồng thời sao lưu code cũ trong `backups/`. Sau khi cài, nhấn `Ctrl+C` và chạy lại `python -m streamlit run app.py`. ZIP phải có `app.py` và `requirements.txt`; `version.txt` dùng để hiển thị phiên bản.

App chỉ tự lấy dữ liệu khi chương trình và máy tính đang chạy. Muốn chạy cả khi chưa mở trình duyệt, hãy cấu hình Windows Task Scheduler để khởi động app cùng Windows.
