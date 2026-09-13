# Android TWA wrapper

TWA tái sử dụng toàn bộ Next.js PWA; Android package mặc định được đề xuất là `vn.xoso247.manager`.

## 1. Điều kiện đầu vào

- Frontend đã deploy qua HTTPS, ví dụ `https://xoso.example.com`.
- Manifest truy cập được tại `https://xoso.example.com/manifest.webmanifest`.
- Node.js 22; Bubblewrap có thể tải Android SDK/JDK phù hợp trong lần chạy đầu.

## 2. Sinh Android project

Chạy trong thư mục `web/twa/`:

```bash
npm install
npx bubblewrap init --manifest=https://xoso.example.com/manifest.webmanifest
```

Khi Bubblewrap hỏi, dùng application ID `vn.xoso247.manager`, màu theme `#9f1d20`, background `#f7f1e7` và bật Play App Signing khi phát hành. Lệnh init sinh project Android cùng `twa-manifest.json`; commit source project nhưng tuyệt đối không commit keystore hoặc mật khẩu.

## 3. Liên kết domain và chữ ký

Lấy SHA-256 fingerprint do Bubblewrap hiển thị. Nếu dùng Google Play App Signing, lấy thêm fingerprint **App signing key certificate** trong Play Console. Trên Vercel/Netlify đặt:

```text
ANDROID_PACKAGE_ID=vn.xoso247.manager
ANDROID_SHA256_FINGERPRINTS=AA:BB:...,11:22:...
```

Redeploy frontend rồi kiểm tra:

```text
https://xoso.example.com/.well-known/assetlinks.json
```

Endpoint phải trả về package name và đúng mọi fingerprint đang dùng. Không đặt keystore, password hoặc JWT secret vào biến `NEXT_PUBLIC_*`.

## 4. Build và thử trên thiết bị

```bash
npm run doctor
npm run build
npm run install:device
```

Bubblewrap tạo APK/AAB đã ký tùy cấu hình. Thử nghiệm deep link, đăng nhập, offline cache, xoay màn hình, nút Back và quá trình nâng cấp PWA trước khi đưa lên Play Console.

## Lộ trình 4–8 tuần

1. Tuần 1: chốt domain production, package ID, privacy policy và Play Console.
2. Tuần 2: sinh wrapper, tạo upload key, Digital Asset Links và internal testing.
3. Tuần 3–4: kiểm thử thiết bị Android phổ biến, mạng yếu/offline, accessibility và sửa lỗi.
4. Tuần 5–6: closed testing, telemetry/crash monitoring và hoàn thiện store listing.
5. Tuần 7–8: production rollout theo tỷ lệ, theo dõi rồi tăng dần phạm vi phát hành.
