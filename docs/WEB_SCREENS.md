# Thiết kế màn hình — Thống Kê 24 Web

## 1. Sitemap

```
/ (LotteryApp shell)
├── Tổng quan (Overview)          view="overview"
│   ├── KPI cards
│   ├── Kỳ quay mới nhất
│   ├── Nhóm nổi bật (nhiều/ít/lâu)
│   ├── Biểu đồ xu hướng 30 kỳ
│   ├── Heatmap 00–99
│   └── So sánh nhanh 7-365
├── Phân tích (Analyzer)          view="analyzer"
│   ├── Nhập bộ số / tạo random
│   ├── Hồ sơ số (tần suất, z-score, Wilson, streak)
│   ├── So sánh bộ
│   └── Bộ yêu thích (localStorage)
├── Lịch sử (History)             view="history"
│   ├── Bộ lọc (ngày, đài, miền, loại)
│   ├── Bảng danh sách kỳ
│   └── Modal chi tiết kỳ
├── Thống kê (Stats)              view="stats"
│   ├── Tần suất 0-9
│   ├── Heatmap đầu-đuôi
│   ├── Tổng, chẵn/lẻ, khoảng
│   ├── Cặp/bộ ba/chuỗi liên tiếp
│   └── Ngày trong tuần
├── So sánh (Compare)             view="compare"
│   ├── Bảng side-by-side 7/30/90/180/365
│   └── Biểu đồ overlay
├── Xác suất (Methodology)        view="method"
│   ├── Tính xác suất 2-6 chữ số
│   ├── Tổ hợp, EV, Monte Carlo
│   └── Wilson CI, χ²
└── Kho dữ liệu (Data)           view="data"
    ├── Nguồn + trạng thái
    ├── Nhập CSV/JSON
    └── Báo cáo validation
```

## 2. Bố cục di động (≤ 768px)

```

## 4. Wireframe chi tiết

### 4.1 Tổng quan

```
┌──────────────────────────────────────┐
│ TỔNG QUAN XÁC SUẤT                  │
│ Hiểu xác suất. Giữ giới hạn.       │
├────────┬────────┬────────┬───────────┤
│ 122 kỳ │ 3,294  │ 122/122│ 2026-09  │
│ dữ liệu│ kết quả│ tỷ lệ  │ cập nhật │
├────────┴────────┴────────┴───────────┤
│ NHỊP SỐ · Nhóm nổi bật              │
│ 🟡 Nhiều: 07, 42, 99 · Ít: ...      │
│ ❄ Lâu chưa: 15, 31, 68             │
├──────────────────────────────────────┤
│ BIỂU ĐỒ 30 KỲ GẦN NHẤT             │
│ [AreaChart: hits per draw]           │
├──────────────────────────────────────┤
│ BẢN ĐỒ 00–99 · Heatmap              │
│ [Grid 20 columns · gold opacity]     │
├──────────────────────────────────────┤
│ SO SÁNH NHANH · 7/30/90/180/365     │
│ [4 stat cards per window]            │
└──────────────────────────────────────┘
```

### 4.2 Lịch sử

```
┌──────────────────────────────────────┐
│ LỊCH SỬ KỲ QUAY                     │
│ Từ: [date] Đến: [date]              │
│ Đài: [Tất cả ▾] Loại: [Tất cả ▾]   │
├──────────────────────────────────────┤
│ Ngày    │ Đài   │ Miền  │ Mã kỳ    │
│─────────┼───────┼───────┼───────────│
│ 12/09   │ Miền B│ MB    │ MB20260912│
│ 11/09   │ Miền B│ MB    │ MB20260911│
│ [Xem chi tiết →]                     │
│ ◀ 1 2 3 ... 25 ▶                    │
└──────────────────────────────────────┘
```

### 4.3 Thống kê chi tiết

```
┌──────────────────────────────────────┐
│ THỐNG KÊ CHI TIẾT                   │
│ TẦN SUẤT CHỮ SỐ 0–9 [BarChart]     │
│ ĐẦU–ĐUÔI [Heatmap 10×10 grid]       │
│ TỔNG / CHẴN-LẺ / KHOẢNG [bars]     │
│ CẶP TOP 30 · BỘ BA · CHUỖI         │
│ Streak: 07 (7 kỳ liên tiếp)         │
│ NGÀY TRONG TUẦN [BarChart CN–T7]    │
└──────────────────────────────────────┘
```

### 4.4 So sánh cửa sổ

```
┌──────────────────────────────────────┐
│ SO SÁNH DỮ LIỆU                     │
│       │ 7    │ 30   │ 90   │ 180/365│
│-------┼──────┼──────┼──────┼────────│
│ Kỳ    │ 7    │ 30   │ 90   │ 180/365│
│ Phủ  │ 85%  │ 92%  │ 96%  │ ...    │
│ χ²    │ 82   │ 79   │ 93   │ ...    │
│ Top 3 │ 07,..│ 42,..│ 99,..│ ...    │
│ Đáy  │ 68,..│ 15,..│ 31,..│ ...    │
│ [LineChart: overlay trend]           │
└──────────────────────────────────────┘
```

### 4.5 Xác suất & Phương pháp

```
┌──────────────────────────────────────┐
│ CÔNG CỤ XÁC SUẤT                    │
│ Số chữ số: [2 ▾] Bộ: [1] Vị trí:[27]│
│ Xác suất 1 lựa chọn: 1.00% [ℹ]      │
│ Một trong 1: 23.77%                  │
│ EV: Giá vé [10000] Giải [70000]     │
│ MC 10k: 23.45% · χ²: 92.34          │
│ ⚠️ "Dữ liệu lịch sử không thể bảo  │
│    đảm kết quả tương lai..."        │
└──────────────────────────────────────┘
```

## 5. Design Tokens

```
Background:   --bg: #0a0f19 (dark) / #f2f0e9 (light)
Panel:        --panel: #121927 / #fbfaf6
Gold:         --gold: #efbd5b (accent)
Coral:        --coral: #ef6f61 (warning)
Blue:         --blue: #79a8ff (info)
Green:        --green: #63c99d (success)
Text:         --text: #f5f2ea / #171b24
Muted:        --muted: #8d97aa / #697181
Radius:       16px
Font:         Inter (sans), SFMono (mono)
```

## 6. Component Library

| Component | CSS class |
| --- | --- |
| PanelHeader | .panel-header |
| NumberPill | .number-pill .hot/.cold/.gold |
| KPI card | .analysis-metrics article |
| Heatmap grid | .number-heatmap |
| Head-tail grid | .head-tail-grid |
| Empty state | .empty-state |
| Toast | .toast |
| Modal | .modal-overlay + .modal-panel |
| Filter bar | .mobile-filters / .desktop-filters |

┌──────────────────────────────┐
│ ☰  Thống Kê 24    [▶ AN] ◐ │ ← topbar
├──────────────────────────────┤
│ [Miền Bắc ▾][30 kỳ ▾]      │ ← mobile-filters
├──────────────────────────────┤
│        Nội dung trang        │ ← scrollable
│                              │
├──────────────────────────────┤
│ ⬡Tổng  ⬡Phân  ⬡Lịch  ⬡Thống│ ← bottom-nav
└──────────────────────────────┘
```

Bottom nav: Tổng quan / Phân tích / Lịch sử / Thống kê. Các view còn lại truy cập qua hamburger.

## 3. Bố cục máy tính (> 768px)

```
┌──────────┬──────────────────────────────────────────┐
│          │ [Miền ▾] [Loại ▾] [30 kỳ ▾]  [◐] [AN] │
│ Logo     ├──────────────────────────────────────────┤
│ Tổng quan│                                          │
│ Phân tích│          Nội dung trang                   │
│ Lịch sử  │         (scrollable)                     │
│ Thống kê │                                          │
│ So sánh  │                                          │
│ Xác suất │                                          │
│ Kho data │                                          │
├──────────┤──────────────────────────────────────────┤
│ © 2026   │ © 2026 Thống Kê 24                      │
└──────────┴──────────────────────────────────────────┘
```
