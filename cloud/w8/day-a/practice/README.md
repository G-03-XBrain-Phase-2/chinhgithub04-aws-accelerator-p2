# Bài thực hành: Cú pháp HCL, Đồ thị phụ thuộc, Drift & Recreations

Tài liệu này hướng dẫn từng bước thực hành để kiểm chứng các cơ chế hoạt động cốt lõi của Terraform (HCL, State, Drift và Replace) trong môi trường cục bộ.

---

## Bước 1: Khởi tạo, Plan và Apply

1.  Mở terminal và di chuyển vào thư mục practice:
    ```bash
    cd cloud/w8/day-a/practice
    ```

2.  **Khởi tạo thư mục làm việc (`init`)**:
    ```bash
    terraform init
    ```
    *Quan sát:* Terraform tải các nhà cung cấp `hashicorp/local` và `hashicorp/tls`. Thư mục ẩn `.terraform/` và tệp `.terraform.lock.hcl` sẽ được tạo ra tại đây.

3.  **Kiểm tra tính hợp lệ của cấu hình (`validate`)**:
    ```bash
    terraform validate
    ```
    *Quan sát:* Xác nhận cú pháp HCL và tính toàn vẹn kiểu dữ liệu của các biến đã chính xác.

4.  **Chạy thử nghiệm lập kế hoạch (`plan`)**:
    ```bash
    terraform plan
    ```
    *Quan sát:* Lưu ý ký hiệu `+ create`. Xem cách `local_file.secure_credential_file` tham chiếu và đọc giá trị động từ thuộc tính runtime của `tls_private_key.secure_credentials`.

5.  **Áp dụng cấu hình thực tế (`apply`)**:
    ```bash
    terraform apply
    ```
    *Nhập `yes` khi hệ thống yêu cầu xác nhận.*
    *Quan sát:* Hai tệp tin `secure_credential.pem` và `project_metadata.json` được tạo cục bộ trong thư mục này, đồng thời tệp trạng thái `terraform.tfstate` xuất hiện.

---

## Bước 2: Mô phỏng Drift (Lệch cấu hình)

Chúng ta sẽ mô phỏng tình huống lệch cấu hình bằng cách can thiệp thủ công vào tài nguyên bên ngoài tầm kiểm soát của Terraform.

1.  **Chỉnh sửa thủ công tài nguyên**:
    Mở tệp tin `project_metadata.json` vừa được tạo ra bằng trình soạn thảo và sửa đổi một giá trị bất kỳ. Ví dụ, đổi:
    ```json
    "enable_security_logs": true
    ```
    thành:
    ```json
    "enable_security_logs": false
    ```
    *(Lưu lại tệp tin. Lúc này hạ tầng đã bị Drift!)*

2.  **Chạy plan để phát hiện Drift**:
    Quay lại terminal và thực thi:
    ```bash
    terraform plan
    ```
    *Quan sát kết quả:*
    Terraform tự động quét và đối chiếu trạng thái thực tế với cấu hình, phát hiện sự thay đổi thủ công ngoài luồng và đưa ra cảnh báo lệch cấu hình:
    ```diff
    ~ update in-place
    ~ resource "local_file" "project_config_metadata" {
        ~ content         = <<-EOT
            ...
    -       "enable_security_logs": false,
    +       "enable_security_logs": true,
            ...
        EOT
        ...
      }
    ```
    *Terraform thông báo rõ ràng rằng hạ tầng thực tế đã bị lệch so với định nghĩa trong mã nguồn.*

3.  **Đồng bộ hóa khôi phục (Reconcile)**:
    Thực thi:
    ```bash
    terraform apply
    ```
    *Xác nhận `yes`.*
    *Quan sát:* Terraform tự động ghi đè và sửa chữa tài nguyên. Mở lại tệp `project_metadata.json`, giá trị đã được khôi phục về `true` chính xác như định nghĩa trong code.

---

## Bước 3: Ép buộc tái tạo tài nguyên (Replace)

Trong trường hợp cần buộc Terraform phải hủy đi và tạo mới lại một tài nguyên cụ thể dù không có sự thay đổi nào trong code, chúng ta sẽ sử dụng tham số `-replace`.

1.  **Thực thi lệnh thay thế bắt buộc**:
    Chạy lệnh sau:
    ```bash
    terraform apply -replace="local_file.secure_credential_file"
    ```
    *Quan sát kết quả plan:*
    Terraform đánh giá lại đồ thị phụ thuộc và hiển thị ký hiệu thay thế tài nguyên `-/+ replace`:
    ```diff
    -/+ resource "local_file" "secure_credential_file" {
        ~ id              = "..." -> (known after apply) # forces replacement
          ...
      }
    ```
    *Nhập `yes` để xác nhận.*

2.  **Kiểm chứng thay đổi**:
    Terraform sẽ hủy tệp cũ, đọc lại các thuộc tính mã hóa từ key và ghi một tệp mới hoàn toàn. Đây là kỹ thuật vô cùng hữu ích trên Production khi một máy ảo bị lỗi hệ điều hành và cần được tái tạo sạch từ đầu mà không cần can thiệp sửa đổi mã nguồn hạ tầng.

---

## Bước 4: Dọn dẹp tài nguyên (Destroy)

Sau khi hoàn thành thử nghiệm, tiến hành hủy bỏ các tài nguyên cục bộ đã tạo để làm sạch không gian làm việc:
```bash
terraform destroy
```
*Nhập `yes` để xác nhận.*
*Quan sát:* Toàn bộ các tệp tin JSON và PEM đã tạo trước đó đều bị xóa sạch, trả lại thư mục ban đầu.
