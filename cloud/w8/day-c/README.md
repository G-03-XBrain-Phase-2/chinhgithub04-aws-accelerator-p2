# W8-D3: Nhật ký Tự học — Quản lý Nâng cao với State & Modules

Tài liệu này lưu trữ toàn bộ nội dung nghiên cứu lý thuyết nâng cao và bộ khung cấu hình thực hành phân tách môi trường trong Ngày 3 (Tuần 8).

---

## Cấu trúc thư mục mô-đun

```text
cloud/w8/day-c/
├── theory/
│   ├── 01_remote_state_locking.md   # Phân tích cơ chế Remote State & State Locking
│   ├── 02_terraform_modules.md      # Khái niệm, lợi ích và cấu trúc viết Module
│   └── 03_best_practices_adr.md     # Terraform Best Practices & vai trò của ADR
├── practice/
│   ├── modules/
│   │   └── s3_static_website/       # Module tự định nghĩa tạo AWS S3 Static Website
│   └── environments/
│       └── dev/                     # Môi trường Development gọi Custom Module
└── README.md                        # Trang mục lục điều hướng chính
```

---

## Điểm nhấn của các phân khu

### [1. Lý thuyết](theory/)
Khu vực lưu trữ các ghi chép chi tiết về quản lý nâng cao của Terraform:
- **[Chuyên đề 01: Cơ chế quản lý State từ xa và Khóa State](theory/01_remote_state_locking.md)**: Tìm hiểu rủi ro của Local State, lợi ích bảo mật/đồng bộ của Remote State trên AWS S3 và cơ chế ngăn chặn ghi đè song song sử dụng khóa phiên bản DynamoDB.
- **[Chuyên đề 02: Cấu trúc và quản lý Terraform Modules](theory/02_terraform_modules.md)**: Nghiên cứu nguyên lý DRY, cấu trúc đóng gói 3 tệp tiêu chuẩn của module độc lập và cách nạp Module từ nguồn cục bộ, Git hoặc Registry.
- **[Chuyên đề 03: Terraform Best Practices và Quyết định Thiết kế Kiến trúc (ADR)](theory/03_best_practices_adr.md)**: Các thực hành tốt nhất về đặt tên, cô lập môi trường và bảo mật mã khóa. Khái niệm và cấu trúc tài liệu ghi nhận quyết định kiến trúc ADR.

### [2. Thực hành cấu trúc phân tách](practice/)
Môi trường giả lập cấu trúc thư mục quy mô doanh nghiệp:
- **[Hướng dẫn thực hành cấu trúc Module và Môi trường](practice/README.md)**: Giải thích chi tiết thiết kế chia nhỏ các khối hạ tầng tái sử dụng trong `modules/`, phân vùng cấu hình môi trường trong `environments/dev/` và quy trình thực hiện kiểm thử dry-run.

---

## Bằng chứng đối chiếu và Phản hồi
- Để xem tóm tắt kết quả tự học, bài kiểm tra và phản hồi học tập chi tiết của ngày hôm nay (Thứ Tư, 03/06/2026), vui lòng kiểm tra: **[reflection.md](../reflection.md)**.
