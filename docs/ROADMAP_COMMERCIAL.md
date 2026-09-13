# Lộ trình online thương mại và Android

## Hiện tại: ứng dụng cá nhân

- Streamlit chạy trên Windows.
- SQLite dùng WAL, khóa ngoại, chỉ mục và schema version; phù hợp lưu nhiều năm dữ liệu cá nhân.
- Sao lưu định kỳ `xsmb.db`; dữ liệu có thể xuất CSV để chuyển hệ thống.

## Online nhiều người dùng

1. Tách lấy dữ liệu và thống kê thành backend FastAPI.
2. Chuyển SQLite sang PostgreSQL, giữ khóa ngày + khu vực + đài + giải + vị trí.
3. Dùng scheduler phía server để cập nhật, không phụ thuộc trình duyệt đang mở.
4. Thêm tài khoản, phân quyền, nhật ký, rate limit, HTTPS và giám sát lỗi.
5. Dùng Redis cache cho bảng trực tiếp và thống kê phổ biến.

## Web và Android

- Web: React/Next.js hoặc Vue/Nuxt, responsive và PWA.
- Android: Flutter hoặc React Native gọi cùng FastAPI; phương án nhanh là đóng gói PWA/TWA.
- Không nhúng trực tiếp Streamlit thành APK sản xuất vì khó tối ưu trải nghiệm, tài khoản và thanh toán.

## Trước khi kinh doanh

- Kiểm tra điều khoản sử dụng nguồn dữ liệu và có nguồn dự phòng chính thức.
- Công bố rõ thống kê không bảo đảm dự đoán kết quả.
- Rà soát pháp luật, chính sách Google Play, quyền riêng tư và bảo vệ dữ liệu.
- Thiết lập backup PostgreSQL, phục hồi sự cố và kiểm thử tải.
