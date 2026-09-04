# Flutter Android app

Ứng dụng Flutter đọc XSMB/XSMN từ FastAPI, lưu kết quả gần nhất trên thiết bị để xem khi mất mạng, hiển thị tần suất lô tô và cho quản trị viên kích hoạt đồng bộ.

## Chạy local

Yêu cầu Flutter stable, JDK 17 và Android SDK:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

Với Android Emulator và API chạy trên máy phát triển, dùng `http://10.0.2.2:8000`. Android production phải gọi API qua HTTPS.

Trên điện thoại thật, bấm biểu tượng máy chủ trên thanh tiêu đề rồi nhập URL API. Nếu backend chạy trên máy tính cùng Wi-Fi, dùng IP LAN của máy tính, ví dụ `http://192.168.1.54:8000`; backend phải lắng nghe trên `0.0.0.0` và Windows Firewall phải cho phép cổng 8000. Ứng dụng kiểm tra `/health` trước khi lưu URL.

Trên Windows, từ thư mục gốc dự án có thể khởi động API local và tự tạo `api-mobile.db` từ dữ liệu hiện tại bằng:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_mobile_api.ps1
```

Giữ cửa sổ này mở khi dùng app. Điện thoại và máy tính phải cùng Wi-Fi. URL LAN hiện tại của máy phát triển là `http://192.168.1.54:8000`.

## Kiểm tra và build

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

APK nằm tại `build/app/outputs/flutter-apk/app-release.apk`; AAB nằm tại `build/app/outputs/bundle/release/app-release.aab`.

Không commit keystore hoặc mật khẩu. Workflow phát hành nhận khóa qua GitHub Actions secrets; xem `../docs/ANDROID_RELEASE.md`.
