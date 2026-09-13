# Đặc tả sản phẩm — Thống Kê 24 Web

## 1. Phạm vi và giả định

Thống Kê 24 là ứng dụng web **thống kê & giáo dục xổ số**, không phải nền tảng cá cược.

- **Độ tuổi**: Người dùng phải đủ 18 tuổi và tuân thủ pháp luật nơi cư trú.
- **Dữ liệu**: Mặc định là mô phỏng có seed cố định và gắn nhãn rõ ràng; người dùng có thể nhập CSV/JSON hợp pháp; API nguồn khi được chủ sở hữu cho phép.
- **Giả định thống kê**:
  - Chữ số 0–9 phân phối đều trong mô hình lý thuyết.
  - Mỗi kỳ quay hợp lệ là sự kiện **ngẫu nhiên độc lập**.
  - Tần suất lịch sử, z-score và khoảng gan **không** được diễn giải thành xác suất chắc thắng.
  - Điểm thống kê 0–100 là **thứ hạng tương đối** từ dữ liệu quá khứ, không phải xác suất trúng.
- **Không thuộc MVP**: nạp/rút tiền, ví, đặt cược, số dư, hoa hồng, cho vay, danh tính ẩn, scraping, thông báo thao túng hành vi.

## 2. Chức năng người dùng

### 2.1 Trang tổng quan (Overview)
- Thẻ KPI: tổng số kỳ, phạm vi dữ liệu, lần cập nhật, tỷ lệ che phủ.
- Kỳ quay mới nhất: bảng giải + kết quả chi tiết.
- Nhóm nhiều / ít / lâu chưa xuất hiện.
- Xu hướng 30 kỳ (biểu đồ đường).
- Heatmap 00–99.
- So sánh nhanh 7/30/90/180/365 kỳ.

### 2.2 Danh sách kỳ quay (History)
- Bảng cuộn vô hạn với cột: ngày, đài, miền, loại, mã kỳ, tổng giải.
- Bộ lọc: khoảng ngày, đài, miền, loại xổ số.
- Nhấp vào kỳ → mở modal chi tiết: toàn bộ giải thưởng + danh sách 2 chữ số cuối.
- Phân trang hoặc infinite scroll (tối thiểu 50 kỳ mỗi tải).

### 2.3 Phân tích bộ số (Analyzer)
- Nhập số (2–6 chữ số) hoặc bộ số (tối đa 10).
- Hồ sơ: tần suất, z-score, khoảng gan, Wilson 95%, streak.
- Lưu bộ yêu thích (localStorage, tối đa 20 bộ).
- Bộ tạo số ngẫu nhiên (Web Crypto + rejection sampling, hiển thị seed/MCRA).
- So sánh tối đa 4 bộ.

### 2.4 Thống kê chi tiết (Statistics)
- **Tần suất chữ số 0–9**: cột bar ± lý thuyết.
- **Đầu–đuôi**: heatmap 10×10.
- **Tổng hai chữ số**: bar chart.
- **Chẵn/lẻ**: progress bar.
- **Khoảng số** (00–19, 20–39, ..., 80–99): cột.
- **Cặp số xuất hiện cùng kỳ**: bảng xếp hạng top 30.
- **Bộ ba liên tiếp**: bảng xếp hạng.
- **Chuỗi xuất hiện liên tiếp**: streak hiện tại / dài nhất / trung bình cho mỗi số.
- **Ngày trong tuần**: frequency theo CN–T7.

### 2.5 So sánh cửa sổ (Compare)
- Bảng side-by-side 7 / 30 / 90 / 180 / 365 kỳ.
- Mỗi cột: draws, slots, distinct numbers, chi², top 3, bottom 3, longest gap.
- Biểu đồ overlay (line) theo số kỳ.

### 2.6 Công cụ xác suất (Probability)
- Xác suất 1–6 chữ số.
- One-in-k, at-least-one-in-n.
- C(n,k) tổ hợp.
- EV = P × prize − cost.
- Monte Carlo (LCG seed 2409, minh họa lặp lại).
- Chi bình phương (df = 99).
- Wilson 95% CI.
- Tooltip giải thích công thức cho mỗi chỉ số.

### 2.7 Kho dữ liệu (Data)
- Nguồn + thời gian cập nhật cuối + trạng thái xác minh.
- Nhập CSV / JSON qua giao diện.
- Validation: thiếu ngày, trùng lặp, sai phạm vi, sai định dạng.
- Báo cáo validation: hợp lệ / trùng / lỗi / cảnh báo.
- Nhập khi không có lỗi nghiêm trọng.
- Prisma persistence khi PostgreSQL được cấu hình.

### 2.8 Phương pháp (Methodology)
- Công thức, ví dụ kiểm chứng, mô tả giả định.
- Cảnh báo kỳ độc lập (mỗi kỳ là sự kiện ngẫu nhiên).

## 3. Hành trình người dùng

```
Mở app → Tổng quan (overview)
  → Đọc KPI → Xem kỳ mới nhất → Xem heatmap
  → Chuyển tab: Phân tích → Nhập bộ số → Lưu yêu thích
  → Chuyển tab: Lịch sử → Lọc theo ngày/đài → Xem chi tiết kỳ
  → Chuyển tab: Thống kê → Xem 0-9 + đầu-đuôi + streak
  → Chuyển tab: So sánh → Bảng 7-365
  → Chuyển tab: Xác suất → Nhập tham số → Đọc kết quả
  → Nhập CSV → Validation → Nhập
```

## 4. Yêu cầu phi chức năng

| Tiêu chí | Mục tiêu |
| --- | --- |
| Hiệu suất | FCP < 1.5s, LCP < 2.5s trên 3G simulated |
| Tương thích | Chrome 90+, Safari 15+, Firefox 90+, Samsung Internet |
| Truy cập | WCAG 2.1 AA: contrast ≥ 4.5:1, focus visible, aria-label |
| Di động | Responsive: mobile-first, bottom nav ≤ 768px |
| Giảm chuyển động | prefers-reduced-motion: reduce tắt animation |
| Offline | PWA cache static assets, hiển thị dữ liệu mẫu khi offline |
| Bảo mật | Không secret trên frontend; ADMIN_API_KEY server-side only |

## 5. Nguyên tắc an toàn

Mỗi trang hiển thị cảnh báo cố định:

> "Dữ liệu lịch sử không thể bảo đảm kết quả tương lai. Mỗi kỳ quay hợp lệ
> được xem là một sự kiện ngẫu nhiên độc lập. Công cụ này chỉ phục vụ mục
> đích thống kê và giáo dục. Người dùng phải đủ tuổi và tuân thủ pháp luật
> tại nơi cư trú."

Không hiển thị:
- Thông báo thắng giả, số dư giả, bộ đếm gây áp lực
- Hiệu ứng dụ đặt cược
- Màu đỏ/green ám chỉ "chắc thắng/chắc thua"

## 6. Nguồn dữ liệu

### 6.1 Dữ liệu mẫu (mặc định)
- Sinh bằng mulberry32 seed 20260912 × 7919.
- 365 kỳ XSMB mô phỏng, gắn nhãn SAMPLE.
- Chạy offline, không cần DB.

### 6.2 Nhập CSV/JSON
- CSV: header row, cột ngày (YYYY-MM-DD), các cột giải.
- JSON: mảng hoặc { records: [...] }.
- Validation Zod phía server + client.

### 6.3 API hợp pháp (tùy chọn)
- Khi DATA_SOURCE_URL được cấu hình, cron job lấy dữ liệu mới nhất.
- Chỉ đọc, không scraping.
- Phải được chủ sở hữu cho phép.

## 7. Không xây dựng

- Nạp/rút tiền, ví, hoa hồng
- Đặt cược tiền thật
- Cơ chế cho vay
- Thông báo thao túng
- Công cụ ẩn danh
- Thu thập dữ liệu trái phép
