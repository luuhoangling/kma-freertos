# Hệ thống Phòng cháy Chữa cháy Hộ gia đình

Đây là một ứng dụng di động dựa trên Flutter được thiết kế để giám sát và điều khiển hệ thống phòng cháy chữa cháy trong hộ gia đình. Ứng dụng tích hợp với Firebase Realtime Database để theo dõi dữ liệu cảm biến (khí gas và lửa), điều khiển thiết bị (máy bơm và quạt), và cấu hình ngưỡng cảnh báo. Giao diện sử dụng chủ đề tối với các điểm nhấn màu cyan, hỗ trợ hiển thị dữ liệu theo thời gian thực và quản lý trạng thái hệ thống.

## Mục lục
- [Tính năng](#tính-năng)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Thư viện yêu cầu](#thư-viện-yêu-cầu)
- [Hướng dẫn cài đặt](#hướng-dẫn-cài-đặt)
- [Cấu trúc cơ sở dữ liệu Firebase](#cấu-trúc-cơ-sở-dữ-liệu-firebase)
- [Cách sử dụng](#cách-sử-dụng)
- [Ảnh chụp màn hình](#ảnh-chụp-màn-hình)
- [Đóng góp](#đóng-góp)
- [Giấy phép](#giấy-phép)

## Tính năng
- **Xác thực người dùng**: Hệ thống đăng nhập đơn giản sử dụng tên đăng nhập và mật khẩu được lưu trong Firebase Realtime Database.
- **Giám sát thời gian thực**:
  - Hiển thị giá trị cảm biến khí gas và lửa kèm chỉ báo cảnh báo.
  - Trực quan hóa dữ liệu cảm biến theo thời gian bằng biểu đồ đường (sử dụng `fl_chart`).
  - Hiển thị trạng thái hệ thống (Bình thường, Bất thường, Khẩn cấp) với mã màu.
- **Điều khiển thiết bị**:
  - Bật/tắt máy bơm và quạt.
  - Chuyển đổi hệ thống giữa chế độ Tự động và Khẩn cấp, với xác nhận cho chế độ Khẩn cấp.
- **Cài đặt**:
  - Cấu hình ngưỡng cảnh báo cho cảm biến khí gas và lửa.
  - Thiết lập thời gian chữa cháy tự động (tính bằng mili giây).
  - Bao gồm ghi chú về độ nhạy ngưỡng cảm biến khí gas và lửa.
- **Trạng thái kết nối**: Theo dõi trạng thái kết nối với Firebase và hiển thị biểu tượng Online/Offline.
- **Chủ đề tối**: Giao diện hiện đại với chủ đề tối, sử dụng màu cyan để tăng độ tương phản.
- **Xử lý lỗi**: Xử lý mạnh mẽ các lỗi từ Firebase, dữ liệu đầu vào không hợp lệ, và timeout mạng.

## Cấu trúc dự án
Mã nguồn được tổ chức trong một tệp `main.dart` duy nhất để đơn giản hóa, bao gồm tất cả các màn hình và thành phần giao diện:

- **Ứng dụng chính** (`MyApp`): Khởi tạo ứng dụng với chủ đề tối và chuyển hướng đến `AuthWrapper`.
- **Xác thực** (`LoginPage`): Xử lý đăng nhập người dùng với Firebase Realtime Database.
- **Màn hình chính** (`HomePage`): Sử dụng `TabBar` với ba tab:
  - **Tổng quan** (`DashboardPage`): Hiển thị dữ liệu cảm biến, trạng thái hệ thống, và biểu đồ thời gian thực.
  - **Điều khiển** (`ControlPage`): Cho phép bật/tắt máy bơm, quạt, và chuyển đổi trạng thái hệ thống.
  - **Cài đặt** (`SettingsPage`): Cấu hình ngưỡng cảm biến và thời gian chữa cháy.
- **Các thành phần giao diện**:
  - `ConnectionStatusIndicator`: Hiển thị trạng thái kết nối Firebase.
  - `SystemStateCard`: Hiển thị trạng thái hệ thống với mã màu.
  - `SensorCard`: Hiển thị giá trị cảm biến với huy hiệu cảnh báo.

## Thư viện yêu cầu
Dự án sử dụng các gói Flutter sau (thêm vào `pubspec.yaml`):
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_database: ^10.4.0
  fl_chart: ^0.68.0
```

## Hướng dẫn cài đặt
1. **Sao chép kho mã nguồn**:
   ```bash
   git clone <repository-url>
   cd household-fire-prevention
   ```

2. **Cài đặt Flutter**:
   Đảm bảo Flutter đã được cài đặt. Xem [hướng dẫn cài đặt Flutter chính thức](https://flutter.dev/docs/get-started/install).

3. **Cài đặt thư viện**:
   Chạy lệnh sau để cài đặt các gói yêu cầu:
   ```bash
   flutter pub get
   ```

4. **Cấu hình Firebase**:
   - Tạo một dự án Firebase trong [Firebase Console](https://console.firebase.google.com/).
   - Thêm ứng dụng Android/iOS vào dự án Firebase và tải tệp cấu hình (`google-services.json` cho Android hoặc `GoogleService-Info.plist` cho iOS).
   - Đặt tệp cấu hình vào thư mục tương ứng (`android/app` cho Android hoặc `ios/Runner` cho iOS).
   - Kích hoạt Firebase Realtime Database trong Firebase Console và thiết lập quy tắc cơ sở dữ liệu (xem bên dưới).

5. **Quy tắc cơ sở dữ liệu Firebase**:
   Cấu hình quy tắc Firebase Realtime Database để cho phép đọc/ghi cho người dùng đã xác thực. Ví dụ:
   ```json
   {
     "rules": {
       ".read": "auth != null",
       ".write": "auth != null"
     }
   }
   ```
   **Lưu ý**: Đây là quy tắc cơ bản cho môi trường phát triển. Trong môi trường sản xuất, cần áp dụng quy tắc nghiêm ngặt hơn dựa trên cơ chế xác thực của bạn.

6. **Chạy ứng dụng**:
   Kết nối thiết bị hoặc trình giả lập và chạy:
   ```bash
   flutter run
   ```

7. **Thêm quyền truy cập Internet** (Android):
   Trong `android/app/src/main/AndroidManifest.xml`, thêm:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

## Cấu trúc cơ sở dữ liệu Firebase
Ứng dụng tương tác với các đường dẫn sau trong Firebase Realtime Database:
- `/account`: Lưu thông tin đăng nhập người dùng (tên đăng nhập, mật khẩu).
  ```json
  {
    "account": {
      "<user_id>": {
        "username": "example_user",
        "password": "example_pass"
      }
    }
  }
  ```
- `/system/lastUpdate`: Dấu thời gian để theo dõi trạng thái kết nối.
- `/system/state`: Trạng thái hệ thống (0: Bình thường, 1: Bất thường, 2: Khẩn cấp).
- `/sensors/gas_value`: Giá trị hiện tại của cảm biến khí gas (số nguyên).
- `/sensors/flame_value`: Giá trị hiện tại của cảm biến lửa (số nguyên).
- `/sensors/gas`: Trạng thái cảnh báo khí gas (boolean).
- `/sensors/flame`: Trạng thái cảnh báo lửa (boolean).
- `/control/pump`: Trạng thái máy bơm (0: Tắt, 1: Bật).
- `/control/fan`: Trạng thái quạt (0: Tắt, 1: Bật).
- `/control/setState`: Thiết lập trạng thái hệ thống (0, 1 hoặc 2).
- `/system/config/thresholds/gas`: Ngưỡng cảm biến khí gas (số nguyên, 0-1023).
- `/system/config/thresholds/flame`: Ngưỡng cảm biến lửa (số nguyên, 0-1023).
- `/system/config/alarmCheckDelay`: Thời gian chữa cháy tự động (mili giây).

## Cách sử dụng
1. **Đăng nhập**:
   - Nhập tên đăng nhập và mật khẩu khớp với dữ liệu trong đường dẫn `/account` của Firebase.
   - Nếu đăng nhập thành công, ứng dụng sẽ chuyển đến `HomePage`.

2. **Tổng quan**:
   - Xem giá trị cảm biến khí gas và lửa theo thời gian thực kèm chỉ báo cảnh báo.
   - Theo dõi trạng thái hệ thống (Bình thường, Bất thường, Khẩn cấp).
   - Quan sát xu hướng dữ liệu cảm biến qua biểu đồ đường (cập nhật mỗi 2 giây).

3. **Điều khiển**:
   - Bật/tắt máy bơm và quạt bằng công tắc.
   - Chuyển hệ thống sang chế độ Tự động hoặc Khẩn cấp (chế độ Khẩn cấp yêu cầu xác nhận).
   - Xem mô tả trạng thái hệ thống.

4. **Cài đặt**:
   - Điều chỉnh ngưỡng cảnh báo cho cảm biến khí gas và lửa (0-1023).
   - Thiết lập thời gian chữa cháy tự động (tính bằng mili giây).
   - Lưu ý: Tăng ngưỡng khí gas sẽ giảm độ nhạy; cảm biến lửa thì ngược lại.

## Giấy phép
Dự án này được cấp phép theo Giấy phép MIT. Xem tệp [LICENSE](LICENSE) để biết chi tiết.