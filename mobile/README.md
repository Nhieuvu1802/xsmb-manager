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
