# Chuyên đề 01: Cơ chế quản lý State từ xa và Khóa State trong Terraform

Trong môi trường làm việc thực tế, đặc biệt là khi làm việc nhóm (teamwork), việc lưu trữ tệp tin State cục bộ (Local State) trên máy tính cá nhân bộc lộ nhiều rủi ro nghiêm trọng về bảo mật và tính nhất quán của hạ tầng. Chuyên đề này phân tích cơ chế giải quyết triệt để vấn đề này thông qua Remote State (S3) và State Locking (DynamoDB).

---

## 1. Hạn chế của Local State

Tệp tin `terraform.tfstate` mặc định được lưu trên máy của người thực thi. Cơ chế này gặp phải ba vấn đề lớn:
- **Rò rỉ thông tin nhạy cảm**: Tệp State chứa toàn bộ thông tin tài nguyên dưới dạng plain text (bao gồm cả mật khẩu, khóa bí mật bí mật). Đẩy tệp này lên Git là vi phạm an toàn thông tin nghiêm trọng.
- **Mất đồng bộ hạ tầng (Out of Sync)**: Khi nhiều kỹ sư cùng chỉnh sửa hệ thống, mỗi người sở hữu một tệp State cục bộ riêng, dẫn đến việc Terraform không thể xác định trạng thái thực tế chính xác của hạ tầng chung.
- **Xung đột ghi đè (Race Condition)**: Nếu hai người cùng chạy lệnh `apply` song song, tài nguyên sẽ bị xung đột, dễ dẫn đến lỗi chồng chéo và hỏng hóc hệ thống.

---

## 2. Giải pháp Remote State (Lưu trữ từ xa)

Để giải quyết vấn đề chia sẻ và bảo mật dữ liệu, Terraform hỗ trợ cấu hình **Remote Backend** để lưu tệp State tập trung tại một dịch vụ lưu trữ an toàn (phổ biến nhất là AWS S3, Google Cloud Storage hoặc Terraform Cloud).

### Lợi ích của Remote State trên AWS S3
- **Nguồn chân lý duy nhất (Single Source of Truth)**: Mọi thành viên trong dự án đều đọc và ghi trên cùng một tệp State chung.
- **Mã hóa an toàn (Encryption at Rest)**: Sử dụng AWS KMS để tự động mã hóa dữ liệu State trước khi lưu xuống đĩa cứng của S3.
- **Quản lý phiên bản (Versioning)**: Bật tính năng S3 Versioning cho phép khôi phục lại trạng thái State cũ nếu tệp State hiện tại bị hỏng hoặc cấu hình sai.
- **Phân quyền truy cập**: Sử dụng IAM Policy để kiểm soát chặt chẽ những ai hoặc pipeline CI/CD nào được quyền đọc/ghi tệp State.

---

## 3. Cơ chế Khóa State (State Locking)

Nếu chỉ sử dụng S3 để lưu trữ, hệ thống vẫn có nguy cơ bị ghi đè dữ liệu khi có nhiều lệnh `apply` chạy cùng lúc. Để ngăn chặn điều này, Terraform triển khai cơ chế **State Locking**. Trên AWS, cơ chế này được thực hiện thông qua dịch vụ **DynamoDB**.

### Nguyên lý hoạt động
- Khi cấu hình backend hỗ trợ locking, Terraform yêu cầu một bảng DynamoDB có khóa phân hoạch (Partition Key) tên là **`LockID`** (kiểu String).
- Khi có một phiên làm việc (như `apply` hoặc `destroy`) bắt đầu, Terraform sẽ ghi một bản ghi chứa thông tin chi tiết về phiên chạy vào bảng này để đánh dấu trạng thái "đang khóa".
- Bất kỳ tiến trình nào khác cố gắng chạy song song sẽ bị chặn lại và báo lỗi cho đến khi tiến trình đầu tiên hoàn tất và giải phóng khóa.

---

## 4. Luồng xử lý chi tiết khi thực thi `terraform apply`

Dưới đây là sơ đồ luồng hoạt động khi có cơ chế khóa và lưu trữ từ xa:

```text
[Người dùng chạy terraform apply]
               │
               ▼
┌─────────────────────────────┐
│ 1. Kiểm tra khóa tại        │
│    bảng DynamoDB            │
└──────────────┬──────────────┘
               │
       [Đã có khóa chưa?]
        /            \
    (Có)              (Chưa)
      /                  \
     ▼                    ▼
[Báo lỗi và thoát]   ┌─────────────────────────────┐
                     │ 2. Tạo bản ghi LockID tại   │
                     │    DynamoDB để khóa State   │
                     └────────────┬────────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────────┐
                     │ 3. Tải tệp State mới nhất   │
                     │    từ S3 về bộ nhớ tạm       │
                     └────────────┬────────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────────┐
                     │ 4. So sánh trạng thái thực  │
                     │    tế và thực thi thay đổi  │
                     └────────────┬────────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────────┐
                     │ 5. Ghi đè tệp State mới     │
                     │    lên S3 bucket            │
                     └────────────┬────────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────────┐
                     │ 6. Xóa bản ghi LockID ở     │
                     │    DynamoDB để mở khóa      │
                     └─────────────────────────────┘
```

Trong trường hợp một lệnh chạy bị tắt đột ngột (ví dụ: mất kết nối internet giữa chừng) khiến khóa DynamoDB không kịp giải phóng tự động, ta có thể dùng lệnh `terraform force-unlock <LOCK_ID>` để gỡ khóa thủ công sau khi đã kiểm tra an toàn.
