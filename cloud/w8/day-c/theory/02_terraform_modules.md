# Chuyên đề 02: Cấu trúc và quản lý Terraform Modules

Khi hạ tầng phình to, việc viết tất cả tài nguyên vào cùng một tệp tin cấu hình sẽ gây khó khăn cho việc bảo trì, tăng khả năng xảy ra lỗi và vi phạm nguyên tắc thiết kế phần mềm. Terraform Modules là giải pháp chia nhỏ hệ thống thành các khối độc lập, có thể tái sử dụng.

---

## 1. Khái niệm Module và Nguyên lý DRY

### Module là gì?
- Về bản chất, bất kỳ thư mục nào chứa các tệp tin `.tf` đều được coi là một **Module**.
- **Root Module**: Là thư mục làm việc chính nơi ta chạy các lệnh CLI như `terraform apply`.
- **Child Module**: Là các thư mục con hoặc gói tài nguyên bên ngoài được gọi từ Root Module thông qua khối khai báo `module`.

### Nguyên lý DRY (Don't Repeat Yourself)
- Thay vì viết lặp đi lặp lại cấu hình tạo S3 Bucket hay EC2 Instance trên nhiều dự án/môi trường khác nhau, ta đóng gói chúng vào một Module duy nhất.
- Khi cần thay đổi kiến trúc (ví dụ: bổ sung tag mặc định cho tất cả S3 Buckets), ta chỉ cần cập nhật code bên trong Module. Tất cả các dự án sử dụng Module đó sẽ tự động kế thừa cấu trúc mới.

---

## 2. Cấu trúc tiêu chuẩn của một Child Module độc lập

Một Module độc lập được thiết kế tối thiểu với 3 tệp tin cấu hình chính nhằm đảm bảo tính đóng gói (encapsulation):

```text
my_module/
├── main.tf      # Định nghĩa các tài nguyên thực tế của module
├── variables.tf # Khai báo các biến đầu vào (Inputs) để tùy biến module
└── outputs.tf   # Trả về các thuộc tính đầu ra (Outputs) để module khác sử dụng
```

- **Tính đóng gói**: Các tài nguyên bên trong Module hoàn toàn ẩn đối với bên ngoài. Root Module chỉ giao tiếp với Child Module thông qua các biến truyền vào (**Variables**) và các giá trị xuất ra (**Outputs**).
- **Lưu ý**: Không cấu hình các khối `provider` hay `backend` bên trong Child Module. Chúng nên được cấu hình ở Root Module để đảm bảo tính linh hoạt khi tái sử dụng.

---

## 3. Các loại nguồn Module (Module Sources)

Terraform hỗ trợ nạp Module từ nhiều nguồn khác nhau tùy thuộc vào mô hình triển khai của dự án:

### Local Module (Module cục bộ)
Nạp Module trực tiếp từ một thư mục con nằm trong cùng kho lưu trữ Git.
```hcl
module "s3_website" {
  source = "./modules/s3_static_website"
  # Truyền các biến đầu vào tương ứng
  bucket_name = "my-static-web-bucket"
}
```
*Đặc điểm*: Thích hợp cho việc phân tách logic nội bộ trong một dự án, chỉnh sửa code module và gọi module chạy được ngay mà không cần đẩy lên server.

### Git Repository Module (Module từ Git)
Nạp Module từ một repository Git độc lập bên ngoài (hỗ trợ GitHub, GitLab, Bitbucket).
```hcl
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.0.0"
}
```
*Đặc điểm*: Rất mạnh mẽ khi làm việc nhóm. Sử dụng tham số `ref` (nhãn tag, branch hoặc commit hash) để khóa phiên bản Module, tránh tình trạng hạ tầng bị hỏng khi code Module gốc có thay đổi mới.

### Terraform Registry Module (Module từ Registry chính thức)
Nạp các module được cộng đồng hoặc các hãng Cloud lớn đóng gói sẵn từ chợ ứng dụng của HashiCorp.
```hcl
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"
}
```
*Đặc điểm*: Được tối ưu hóa cao, tài liệu chi tiết, hỗ trợ khóa phiên bản qua thuộc tính `version`.
