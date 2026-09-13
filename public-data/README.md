# VVN public data

Thư mục này chỉ chứa cấu hình và snapshot xổ số **công khai** để Flutter dùng
khi API production tạm thời không đáp ứng.

```text
public-data/
├── config.json
├── manifest.json
├── status.json
├── status/health.json
├── xsmb/latest.json
└── xsmn/latest.json
```

- Nguồn chính luôn là `https://api.vvn.freedev.app/v1` và database backend.
- JSON tại đây là bản sao chỉ đọc, không phải database hay source of truth.
- Không đặt password, token, API key, credential, `.env` hoặc database dump
  trong thư mục này.
- Chỉ cập nhật `status.json` sau khi cả hai snapshot đã được kiểm định và ghi
  thành công, để client không nhìn thấy một bộ backup đang cập nhật dở.
- `manifest.json` chứa `datasetVersion`, checksum và kích thước từng snapshot;
  client có thể bỏ qua việc tải/tính lại nếu version không đổi.
