# Statistics Data

Thống kê 00-99 được tính real-time bởi Worker từ draw data.

Endpoint:
- `GET /v1/statistics/00-99` — XSMB statistics
- `GET /v1/xsmb/statistics` — XSMB statistics
- `GET /v1/xsmn/statistics` — XSMN statistics

Statistics KHÔNG được pre-compute vào JSON file.
Worker tính trên-the-fly khi có request.
