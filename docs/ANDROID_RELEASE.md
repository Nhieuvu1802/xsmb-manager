# Phát hành Flutter lên GitHub và Google Play

Package Android cố định của dự án là `vn.xsmb.xsmb_manager`. Không đổi package sau khi đã tạo ứng dụng trên Play Console.

## 1. Tạo upload key một lần

Thực hiện trên máy an toàn có JDK mới (17 trở lên):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Giữ file và mật khẩu trong password manager/offline backup. Mất upload key sẽ làm quy trình cập nhật ứng dụng phức tạp. Tuyệt đối không commit file `.jks`.

## 2. Cấu hình repository GitHub

Trong **Settings → Secrets and variables → Actions**, tạo:

- Variable `API_BASE_URL`: URL HTTPS của FastAPI production, không có dấu `/` cuối.
- Secret `ANDROID_KEYSTORE_BASE64`: nội dung base64 một dòng của `upload-keystore.jks`.
- Secret `ANDROID_KEYSTORE_PASSWORD`.
- Secret `ANDROID_KEY_ALIAS` (mặc định là `upload`).
- Secret `ANDROID_KEY_PASSWORD`.
- Secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: JSON service account có quyền phát hành; chỉ cần nếu tự động tải lên Play.

PowerShell tạo chuỗi base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

## 3. Kiểm thử điện thoại

1. Mở workflow **Android CI**, chạy thủ công hoặc push thay đổi trong `mobile/`.
2. Tải artifact `android-ci-builds` và cài APK lên máy thử. Artifact CI không dùng upload key production.
3. Kiểm tra API HTTPS, XSMB, XSMN, bộ lọc ngày, cache offline, đăng nhập/đồng bộ, màn hình nhỏ và Android Back.
4. Tạo ứng dụng trên Play Console với package `vn.xsmb.xsmb_manager`, bật Play App Signing và hoàn thành Data safety, privacy policy, content rating, store listing.

## 4. Phát hành

1. Vào **Actions → Android Release → Run workflow**.
2. Nhập tag mới, ví dụ `v1.0.0`.
3. Lần đầu để `publish_to_play=false`; tải APK/AAB từ GitHub Release và xác minh chữ ký.
4. Chạy với tag phiên bản mới và `publish_to_play=true` để đưa AAB lên track `internal`.
5. Phê duyệt trên Play Console rồi lần lượt chuyển qua closed testing và production.

Mỗi lần phát hành phải tăng `version`/build number trong `mobile/pubspec.yaml`; Google Play không chấp nhận build number đã dùng.

Nếu Flutter trên Windows báo lỗi hậu kiểm `failed to strip debug symbols` sau khi Gradle đã tạo AAB, hãy dùng workflow Ubuntu để phát hành. Đây là lỗi Flutter tool đã được theo dõi; không nên bỏ qua lỗi một cách tự động trong pipeline production.
