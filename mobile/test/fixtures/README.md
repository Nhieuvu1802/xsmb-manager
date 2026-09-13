# Vector đối chiếu (parity vectors)

`parity_vectors.json` được sinh **từ chính** `web/lib/statistics.ts` (bản web Next.js
trong cùng repo) nên bản Flutter dùng đúng công thức của bản web.

- Được đọc bởi: `test/statistics_test.dart`
- Được sinh bởi: `tool/generate_parity_vectors.ts`

## Sinh lại khi bản web thay đổi

1. Copy `tool/generate_parity_vectors.ts` thành `web/tests/_vectors.test.ts`
2. `cd web; npx vitest run tests/_vectors.test.ts`
3. Xoá `web/tests/_vectors.test.ts` để bản web luôn sạch
4. `cd mobile; flutter test`

Nếu bước 4 báo lệch, chỉnh `lib/src/logic/statistics.dart` cho khớp rồi lặp lại.

## Quy ước

- Số thực được so bằng chuỗi `toFixed(10)` / `toFixed(12)` (JS) và
  `toStringAsFixed(10)` / `toStringAsFixed(12)` (Dart) để tránh lệch định dạng float.
- `collectedAt` (thời điểm chạy) bị bỏ qua khi so sánh.
- Không có dữ liệu thật: toàn bộ dữ liệu mẫu là mô phỏng có seed cố định.
