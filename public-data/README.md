# VVN public data

Thư mục này chỉ chứa cấu hình và snapshot xổ số **công khai** để Flutter dùng
khi API production tạm thời không đáp ứng.

```text
public-data/
├── config.json
├── manifest.json
├── status.json
├── status/health.json
├── xsmb/latest.json      # đúng kỳ mới nhất của XSMB (27 giải)
├── xsmb/history.json     # cửa sổ 365 ngày gần nhất của XSMB
├── xsmn/latest.json      # các đài quay trong ngày mới nhất của XSMN (18 giải/đài)
└── xsmn/history.json     # cửa sổ 365 ngày gần nhất của XSMN
```

- Nguồn chính luôn là `https://api.vvn.freedev.app/v1` và database backend.
- JSON tại đây là bản sao chỉ đọc, không phải database hay source of truth.
- `latest.json` giữ đúng một ngày để client tải nhanh; `history.json` là cửa sổ
  **365 ngày** (`historyDays` trong `manifest.json`) để app có đủ dữ liệu thống
  kê/backtest ngay lần cài đầu và chỉ tải phần còn thiếu ở các lần sau.
- Mỗi kỳ trong snapshot giữ `date` + `station` riêng: miền Nam (và miền Trung)
  mỗi ngày quay một bộ đài khác nhau nên **không** có danh sách đài cố định.
- Cửa sổ có thể ít hơn 365 ngày nếu nguồn không có dữ liệu (ví dụ ngày nghỉ Tết).
- Không đặt password, token, API key, credential, `.env` hoặc database dump
  trong thư mục này.
- Chỉ cập nhật `status.json` sau khi cả hai snapshot đã được kiểm định và ghi
  thành công, để client không nhìn thấy một bộ backup đang cập nhật dở.
- `manifest.json` chứa `datasetVersion`, `historyDays`, `history` (firstDate/
  latestDate/draws từng miền), checksum và kích thước từng snapshot; client có
  thể bỏ qua việc tải/tính lại nếu version không đổi.
