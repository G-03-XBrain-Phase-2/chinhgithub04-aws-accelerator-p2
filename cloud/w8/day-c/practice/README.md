# Hướng dẫn Thực hành — Cấu trúc Module và Quản lý Môi trường

Thư mục này triển khai cấu hình thực hành mẫu cho việc phân tách cấu trúc hạ tầng sử dụng Custom Module và chia phân vùng môi trường thực tế (Environments).

---

## 1. Cấu trúc thư mục mô-đun thực hành

```text
practice/
├── modules/
│   └── s3_static_website/       # Module tự định nghĩa tạo AWS S3 Static Website
│       ├── main.tf              # Định nghĩa tài nguyên S3, Website Config, Policy công khai
│       ├── variables.tf         # Tham số đầu vào (bucket_name, tags)
│       └── outputs.tf           # Đầu ra xuất thông tin (bucket_arn, website_url)
└── environments/
    └── dev/                     # Phân vùng cấu hình cho môi trường Development
        ├── main.tf              # Gọi Child Module cục bộ để khởi tạo tài nguyên
        ├── providers.tf         # Khai báo AWS Provider và Remote S3 Backend
        ├── variables.tf         # Các biến cấu hình riêng biệt của môi trường dev
        └── outputs.tf           # Xuất địa chỉ website sau khi chạy xong
```

---

## 2. Giải thích thiết kế kiến trúc

- **Tách biệt Module và Environment**: Các tài nguyên cơ bản được đóng gói độc lập bên trong thư mục `modules/`. Thư mục này không chứa bất kỳ thông tin cụ thể nào về môi trường hay nhà cung cấp tài khoản (không cấu hình provider hay backend). Việc triển khai thực tế sẽ được quyết định tại các phân vùng môi trường cụ thể nằm dưới thư mục `environments/` (như thư mục `dev` hiện tại). Điều này giúp ta dễ dàng nhân bản thêm các môi trường khác (như `staging`, `prod`) trong tương lai mà không cần viết lại mã nguồn hạ tầng cốt lõi.
- **Remote State & Locking**: Trong tệp `environments/dev/providers.tf`, cấu hình backend đã được định nghĩa trỏ về S3 Bucket để lưu trữ tệp State tập trung, kết hợp với bảng DynamoDB làm cơ chế khóa.

---

## 3. Quy trình thực thi kiểm thử (Dry-run)

Do việc chạy thực tế yêu cầu quyền truy cập tài khoản AWS thực tế cùng các tài nguyên S3 Backend tồn tại sẵn, ta thực hiện các bước kiểm tra cú pháp và dựng đồ thị tài nguyên thông qua các lệnh CLI sau:

1. **Di chuyển vào thư mục môi trường dev**:
   ```bash
   cd cloud/w8/day-c/practice/environments/dev
   ```

2. **Khởi tạo thư mục và nạp Module**:
   ```bash
   terraform init
   ```
   *Lưu ý*: Lệnh này sẽ tự động phát hiện khối khai báo `module` cục bộ trong tệp `main.tf`, liên kết mã nguồn từ thư mục `../../modules/s3_static_website` và tải các Provider plugin cần thiết.

3. **Kiểm tra tính hợp lệ của cấu hình**:
   ```bash
   terraform validate
   ```

4. **Chạy mô phỏng kế hoạch triển khai**:
   ```bash
   terraform plan
   ```
   *Kết quả*: Hệ thống sẽ phân tích cú pháp của cả root cấu hình và child module để đưa ra danh sách các tài nguyên AWS sẽ được tạo mà không làm ảnh hưởng đến hạ tầng thực tế.
