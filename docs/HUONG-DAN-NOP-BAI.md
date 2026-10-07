# PocketReceipt — Mini-Project 3

## Các đường dẫn

- Demo web: https://pocketreceipt-demo.onrender.com
- Repository công khai: https://github.com/it2kvku/pocketreceipt-ocr-expense-tracker
- APK, video và báo cáo: https://github.com/it2kvku/pocketreceipt-ocr-expense-tracker/releases/tag/v1.0.0

## Cài Android

1. Tải `app-release.apk` từ mục Releases.
2. Mở file trên điện thoại Android 7.0 trở lên. Cho phép cài từ nguồn tải file nếu Android yêu cầu.
3. Mở PocketReceipt, chọn **Scan a receipt** và cấp quyền camera.
4. Chụp hóa đơn hoặc chọn ảnh có sẵn; kéo hai thanh chỉnh mép cắt ảnh.
5. Chọn **Crop & recognize**, kiểm tra tên cửa hàng, số tiền VND, ngày và danh mục, rồi **Save expense**.
6. Dùng **Expenses** để tìm, lọc, sửa hoặc xóa; dùng **Insights** để xem biểu đồ.

Ứng dụng Android lưu SQLite và ảnh trong vùng riêng của ứng dụng; không có tài khoản hay API OCR đám mây. Gỡ ứng dụng sẽ xóa dữ liệu cục bộ. Bản APK là release mode với chữ ký phát triển, dành cho sideload và bài nộp, không phải bản phát hành Play Store.

## Phạm vi demo

Bản web hỗ trợ nhập văn bản hóa đơn, parser, quản lý giao dịch và biểu đồ; dữ liệu lưu trong trình duyệt. OCR ảnh bằng Google ML Kit chạy trong APK Android. Menu ba chấm có dữ liệu mẫu để khám phá giao diện; nhập văn bản mẫu không phải quét OCR.

`sample-receipt.jpg` trong thư mục `pocket_receipt/docs` là hóa đơn giả lập để kiểm chứng OCR, không chứa thông tin chi tiêu thật. Video minh họa dài 2 phút 30 giây đã dùng ảnh này trên máy ảo Android. Hành vi lấy nét/đèn flash và độ chính xác trên hóa đơn thực tế cần kiểm tra thêm trên điện thoại thật. Không cam kết OCR luôn dưới 100 ms.

## Build từ source

Toolchain đã dùng: Flutter 3.47.5, Dart 3.13.4, Android SDK và Java.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

File APK đầu ra: `build/app/outputs/flutter-apk/app-release.apk`.

Báo cáo dài 4 trang, gồm checklist tính năng, kiến trúc, ảnh chụp ứng dụng và kiểm chứng. Đề bài chưa kèm file mẫu chính thức nên báo cáo được trình bày theo các mục đã yêu cầu.
