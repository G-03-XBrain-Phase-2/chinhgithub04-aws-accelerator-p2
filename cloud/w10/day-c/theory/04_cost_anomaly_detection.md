# Chuyên đề 04: Cảnh báo Chi phí Bất thường (AWS Cost Anomaly Detection)

## 1. AWS Cost Anomaly Detection là gì?
*   **AWS Cost Anomaly Detection** là một dịch vụ quản lý chi phí đám mây miễn phí, sử dụng các mô hình học máy (Machine Learning) tiên tiến để liên tục giám sát và phân tích xu hướng chi tiêu dịch vụ của bạn nhằm phát hiện sớm các khoản tăng chi phí bất thường.
*   **Mục đích**: Ngăn ngừa thảm họa "Bill Shock" (hóa đơn tăng vọt ngoài tầm kiểm soát) do lỗi cấu hình (ví dụ: vòng lặp vô tận trong script gọi API, cấu hình Auto Scaling bị lỗi scale out liên tục) hoặc do cụm hạ tầng bị hacker chiếm quyền điều khiển (ví dụ: bị cài container đào coin).

---

## 2. Cơ chế hoạt động của Cost Anomaly Detection
Dịch vụ tự động phân tích hành vi chi tiêu theo các bước:
1.  **Học mẫu chi tiêu**: Thu thập lịch sử chi phí trong vòng 10-14 ngày đầu để xây dựng mô hình chi tiêu chuẩn (Steady Spending Baseline) cho từng tài khoản và dịch vụ.
2.  **Nhận diện bất thường (Outliers)**: Dựa trên baseline, mô hình ML sẽ phát hiện các điểm chi tiêu tăng đột biến không trùng khớp với quy luật thông thường (ví dụ: ngày nghỉ cuối tuần chi phí tăng vọt).
3.  **Phân loại chi phí**: Hỗ trợ 4 loại Monitor:
    *   *AWS Services*: Giám sát riêng lẻ từng dịch vụ AWS (EC2, S3, RDS, v.v.).
    *   *Linked Accounts*: Giám sát theo từng tài khoản thành viên trong AWS Organizations.
    *   *Cost Categories*: Giám sát theo nhóm chi phí tự định nghĩa.
    *   *Cost Allocation Tags*: Giám sát theo nhãn tag gán trên tài nguyên (ví dụ: `Project: Capstone`).

---

## 3. Cấu hình Cảnh báo và Tích hợp
*   **Thiết lập ngưỡng cảnh báo (Alert Threshold)**: Chúng ta cấu hình gửi cảnh báo khi phát hiện bất thường vượt quá một số tiền nhất định (ví dụ: > $50/ngày) hoặc khi tỉ lệ tăng trưởng vượt quá phần trăm định sẵn.
*   **Kênh nhận cảnh báo (Alert Subscriptions)**:
    *   *Email*: Gửi báo cáo định kỳ hàng ngày/hàng tuần hoặc gửi ngay lập tức (Immediate notifications).
    *   *Amazon SNS (Simple Notification Service)*: Đẩy thông tin sang AWS SNS để kích hoạt các webhook tự động gửi cảnh báo vào kênh Slack, Microsoft Teams, hoặc gọi hệ thống trực ban PagerDuty.

---

## 4. Quy trình ứng phó khi nhận Cảnh báo chi phí (Cost Incident Runbook)

Khi nhận được cảnh báo chi phí tăng đột biến, kỹ sư trực ban thực hiện quy trình chẩn đoán và xử lý sau:

```text
  [ Nhận Cảnh Báo ] ──► [ Xác Định Dịch Vụ ] ──► [ Định Vị Tài Nguyên ]
                                                         │
  [ Liên Hệ AWS Support ] ◄── [ Dọn Dẹp / Cô Lập ] ◄─────┘
```

1.  **Xác định dịch vụ gây lỗi**:
    *   Truy cập AWS Billing Console -> Cost Anomaly Detection.
    *   Đọc báo cáo để xác định dịch vụ nào (ví dụ: Amazon EC2) và vùng nào (Region - ví dụ: us-east-1) đang chịu chi phí tăng bất thường.
2.  **Định vị tài nguyên cụ thể**:
    *   Sử dụng **AWS Cost Explorer** để zoom sâu vào chi tiết theo giờ (Hourly granularity).
    *   Đối chiếu log trên **AWS CloudTrail** để tìm kiếm các sự kiện tạo tài nguyên hàng loạt (`RunInstances`, `CreateVolume`) trong khoảng thời gian xảy ra bất thường để tìm ra ID của User/Role thực hiện.
3.  **Đánh giá tính hợp lệ**:
    *   Kiểm tra xem đây là hoạt động hợp lệ có kế hoạch trước của team phát triển (ví dụ: đang chạy load test hệ thống) hay là hành vi bất hợp lệ (rò rỉ tài nguyên, bị tấn công).
4.  **Dọn dẹp & Cách ly**:
    *   Nếu do lỗi code/script: Dừng ngay tiến trình chạy lỗi, xóa các tài nguyên thừa.
    *   Nếu do rò rỉ Access Key / bị hack: Lập tức vô hiệu hóa Access Key bị lộ, đổi mật khẩu tài khoản, thiết lập lại Security Group để cách ly các máy ảo bị nhiễm độc.
5.  **Tối ưu hóa & Đề xuất miễn giảm**:
    *   Liên hệ với AWS Support thông qua ticket hỗ trợ để giải thích sự cố (đặc biệt nếu do bị tấn công hoặc vô tình) để đề xuất AWS hoàn trả/miễn giảm chi phí phát sinh bất thường (AWS Billing concession policy).
