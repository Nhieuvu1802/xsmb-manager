# Đặc tả sản phẩm, kiến trúc và thiết kế — Thống Kê 24

## 1. Phạm vi và giả định

Thống Kê 24 là công cụ thống kê/giáo dục 18+, không phải nền tảng cá cược. Bản MVP ưu tiên trải nghiệm chạy ngay, miễn phí, không cần tài khoản. Dữ liệu mặc định là mô phỏng có seed cố định và được gắn nhãn rõ ràng; người dùng có thể nhập CSV/JSON hợp pháp trên thiết bị.

Giả định thống kê chính: các chữ số 0–9 phân phối đều trong mô hình lý thuyết; các kỳ quay hợp lệ độc lập. Tần suất lịch sử, khoảng gan và z-score không được diễn giải thành xác suất chắc thắng. Việc bật dữ liệu sản xuất chỉ được thực hiện khi có API được chủ sở hữu cho phép.

Không thuộc MVP: thanh toán, nạp/rút, ví, đặt cược, số dư, hoa hồng, cho vay, danh tính ẩn, scraping vượt cơ chế bảo vệ và thông báo gây áp lực.

## 2. Sitemap và hành trình

```text
Tổng quan
├─ Bộ lọc miền / loại / 7–365 kỳ
├─ Kỳ quay mới nhất
├─ Nhóm nhiều / ít / lâu chưa xuất hiện
├─ Xu hướng ngày / tuần / tháng
└─ Heatmap 00–99

Phân tích
├─ Nhập và tra một/bộ số
├─ Lưu yêu thích trên thiết bị
├─ Bộ tạo Web Crypto minh bạch
├─ Hồ sơ tần suất / gap / z-score
├─ Đầu / đuôi / tổng / chẵn-lẻ / khoảng / chuỗi
└─ So sánh tối đa bốn bộ

Kho dữ liệu
├─ Nguồn và thời gian cập nhật
├─ Nhập CSV / JSON
└─ Trùng / thiếu / sai ngày / sai phạm vi

Phương pháp
├─ Công thức 2–6 chữ số và tổ hợp
├─ Giá trị kỳ vọng
├─ Monte Carlo
├─ Wilson 95% và chi bình phương
└─ Giả định, giới hạn, trách nhiệm
```

Hành trình chính: mở ứng dụng → chọn phạm vi → đọc nguồn → xem mô tả lịch sử → nhập bộ số → đối chiếu lý thuyết/lịch sử → có thể lưu cục bộ. Hành trình quản trị: mở Kho dữ liệu → chọn CSV/JSON → đọc báo cáo → chỉ nhập khi không có lỗi nghiêm trọng.

## 3. Wireframe

### Điện thoại

```text
┌──────────────────────────┐
│ ☰  Thống Kê 24       ◐ AN│
├──────────────────────────┤
│ [Miền Bắc] [90 kỳ] [2 số]│
│ TỔNG QUAN                 │
│ Tổng quan xác suất        │
│ ┌────────┐ ┌────────┐     │
│ │90 kỳ   │ │số nhiều│     │
│ └────────┘ └────────┘     │
│ ┌──────────────────────┐  │
│ │ kỳ mới nhất          │  │
│ │ bảng giải và kết quả │  │
│ └──────────────────────┘  │
│ ┌──────────────────────┐  │
│ │ biểu đồ / heatmap    │  │
│ └──────────────────────┘  │
├──────────────────────────┤
│ Tổng quan Phân tích Data  │
└──────────────────────────┘
```

### Máy tính

```text
┌──────────────┬─────────────────────────────────────────┐
│ Logo         │ [Miền] [Loại] [Khoảng]             ◐ AN │
│              ├─────────────────────────────────────────┤
│ Tổng quan    │ Tiêu đề                         [CTA]    │
│ Phân tích    │ ┌────┐ ┌────┐ ┌────┐ ┌────┐             │
│ Kho dữ liệu  │ │KPI │ │KPI │ │KPI │ │KPI │             │
│ Phương pháp  │ └────┘ └────┘ └────┘ └────┘             │
│              │ ┌─────────────────┐ ┌───────────────┐   │
│ 18+          │ │ kết quả / chart │ │ xếp hạng     │   │
│              │ └─────────────────┘ └───────────────┘   │
└──────────────┴─────────────────────────────────────────┘
```

## 4. Kiến trúc hệ thống

```text
CSV / JSON / API được phép
          ↓
Zod + kiểm định nghiệp vụ
          ↓
Repository (mẫu cục bộ | Prisma/PostgreSQL)
          ↓
Hàm thống kê thuần trong lib/statistics.ts
          ↓
Next.js App Router API + React UI + Recharts
```

- Trình bày không chứa công thức nghiệp vụ cốt lõi.
- Hàm thống kê thuần, có thể unit test và chạy phía client/server.
- API quản trị yêu cầu Bearer secret qua biến môi trường; không đưa khóa ra frontend.
- Chế độ miễn phí mặc định không cần DB. Khi cần lưu bền vững, dùng PostgreSQL tương thích Prisma.
- Dữ liệu yêu thích chỉ nằm trong `localStorage` dưới khóa `tk24:favorites`.

## 5. Mô hình dữ liệu

`LotteryDraw` gồm UUID, mã kỳ duy nhất, loại xổ số, miền, đài, thời điểm quay theo múi giờ, URL nguồn, thời điểm thu thập, trạng thái xác minh và danh sách `PrizeResult`. Mỗi `PrizeResult` có giải, vị trí, giá trị và hai chữ số cuối để lập chỉ mục. `DataImport` giữ báo cáo số dòng hợp lệ/trùng/lỗi.

Ràng buộc quan trọng: `(drawId, prize, position)` duy nhất; `drawCode` duy nhất; `lastTwo` được đánh chỉ mục; xóa kỳ quay sẽ xóa kết quả con. Chi tiết có thể thực thi nằm trong `web/prisma/schema.prisma`.

## 6. Công thức và ví dụ kiểm chứng

- Kết quả chính xác d chữ số: `P = 10^-d`. Hai chữ số: 1/100; sáu chữ số: 1/1.000.000.
- Một trong k lựa chọn không trùng: `P = k / 10^d`, với `k ≤ 10^d`.
- Ít nhất một lần qua n vị trí độc lập: `P = 1 − (1 − k/10^d)^n`.
- Một số 2 chữ số trong 27 kết quả: `1 − 0,99^27 ≈ 23,77%`.
- Tổ hợp: `C(n,k) = n! / (k!(n−k)!)`; `C(45,6) = 8.145.060`.
- Giá trị kỳ vọng: `EV = P(trúng) × giải thưởng − giá vé`; nhiều mức giải dùng `Σpᵢxᵢ − giá vé`.
- Tần suất: `f = x/N`; sai số chuẩn nhị thức: `SE = √(p(1−p)/N)`.
- Z-score: `z = (x−Np)/√(Np(1−p))`.
- Khoảng tin cậy 95% dùng Wilson vì ổn định hơn xấp xỉ Wald ở mẫu nhỏ/tỷ lệ gần 0.
- Chi bình phương: `χ² = Σ(Oᵢ−Eᵢ)²/Eᵢ`, bậc tự do 99 cho 100 số. Đây là kiểm định độ phù hợp, không phải bộ dự đoán.
- Monte Carlo dùng LCG có seed 2409 để minh họa có thể lặp lại; bộ tạo số cho người dùng dùng Web Crypto và rejection sampling để tránh modulo bias.

## 7. API

- `GET /api/probability`: query `digits=2..6`, `selections`, `slots`; trả xác suất và giả định.
- `POST /api/admin/import`: Bearer `ADMIN_API_KEY`; Zod kiểm tra danh sách kỳ/giải; bản MVP trả báo cáo validation. Repository Prisma là điểm mở rộng để commit transaction.
- API FastAPI hiện hữu trong repository vẫn độc lập và có JWT cho đồng bộ nguồn cũ; frontend mới không phụ thuộc API đó ở chế độ demo.

## 8. An toàn, truy cập và riêng tư

Toàn bộ màn hình hiển thị nhãn dữ liệu mẫu, nguồn/cập nhật và cảnh báo kỳ độc lập. Màu chỉ mã hóa cường độ lịch sử, không gán “đỏ = thắng”. Có navigation bằng nút có nhãn, độ tương phản cao, target chạm hợp lý, layout mobile và `prefers-reduced-motion`. Không thu thập dữ liệu cá nhân; tệp nhập được xử lý trong phiên trình duyệt.

## 9. Thư viện và giấy phép

- Next.js, React, Recharts, Tailwind CSS, Lucide, Zod, Prisma, Vitest và Playwright: giấy phép MIT hoặc Apache-2.0 theo metadata đi kèm từng gói trong `node_modules`/package registry.
- Không dùng logo, hình ảnh, dữ liệu độc quyền hay mã giao diện từ nền tảng xổ số bên ngoài.
- Dữ liệu mặc định là dữ liệu mô phỏng tự sinh; không có giấy phép nguồn bên thứ ba cần kế thừa.

Khi bổ sung API thật, quản trị viên phải ghi rõ chủ sở hữu, URL tài liệu, điều khoản sử dụng, thời hạn lưu trữ và bằng chứng cho phép trước khi bật lịch đồng bộ.

