# Chuyên đề 03: State Mechanics — Bản đồ Trạng thái, Lệch Cấu hình (Drift) và Tái tạo Tài nguyên

## 1. Bản chất và Vai trò của Terraform State

Khi chúng ta viết cấu hình Terraform và chạy `apply`, các tài nguyên thực tế sẽ được tạo ra trên môi trường (ví dụ: máy ảo EC2 trên AWS, tệp tin trên máy local). Làm thế nào Terraform biết được tài nguyên thực tế nào tương ứng với khối code nào? Câu trả lời là: **Terraform State**.

Terraform tự động tạo và lưu trữ một tệp tin trạng thái mặc định tên là `terraform.tfstate` dưới định dạng **JSON** để ghi nhận toàn bộ thông tin chi tiết về hạ tầng thật.

### Bốn Vai trò Cực kỳ Quan trọng của State:
1.  **Ánh xạ thế giới thực (Mapping)**: Ánh xạ trực tiếp từ các tài nguyên khai báo trong code HCL sang các ID thực tế do cloud provider cấp phát (ví dụ: `aws_instance.web` -> `i-0ac83492db30f`).
2.  **Lưu trữ siêu dữ liệu phụ thuộc (Metadata)**: Lưu trữ thông tin về thứ tự phụ thuộc giữa các tài nguyên để đảm bảo khi xóa hoặc cập nhật, Terraform thực hiện đúng quy trình an toàn.
3.  **Tối ưu hóa hiệu năng (Caching)**: Lưu lại toàn bộ thuộc tính của tài nguyên. Khi chạy `plan`, thay vì liên tục gọi API lên cloud để truy vấn thông tin chi tiết của hàng nghìn tài nguyên (gây nghẽn mạng và chậm trễ), Terraform có thể đọc trực tiếp từ cache trong state (sau khi đã chạy tiến trình sync nhanh).
4.  **Đồng bộ cộng tác (Syncing)**: Khi làm việc nhóm, một file state chung đặt trên Cloud (Remote State như AWS S3) giúp toàn bộ thành viên luôn làm việc trên cùng một phiên bản hạ tầng duy nhất, tránh tình trạng xung đột ghi đè.

---

## 2. Drift (Lệch Cấu hình) là gì và Cách xử lý?

### Định nghĩa Drift
Drift (Lệch cấu hình) xảy ra khi trạng thái thực tế của hạ tầng bị thay đổi bên ngoài tầm kiểm soát của Terraform (thông qua chỉnh sửa trực tiếp bằng giao diện Web UI AWS Console, chạy script thủ công ngoài luồng, hoặc do lỗi phần cứng).

```text
       Cấu hình HCL (.tf)               Môi trường Thực tế (Reality)
    ┌──────────────────────┐             ┌──────────────────────┐
    │  rsa_bits = 4096     │             │  rsa_bits = 4096     │
    │  env      = "dev"    │             │  env      = "prod"   │ <── MANUAL DRIFT!
    └──────────────────────┘             └──────────────────────┘
```

Khi ta chạy `terraform plan` hoặc `terraform apply`, Terraform sẽ tự động thực hiện hành động **Refresh** (quét lại hạ tầng thật), so sánh thực tế với State, phát hiện ra sự khác biệt (Drift) và hiển thị cảnh báo thay đổi.

### Hai lựa chọn xử lý khi xảy ra Drift:

#### Lựa chọn 1: Đồng bộ hóa Reality về lại Code (Reconcile)
*   **Khi nào dùng**: Khi thay đổi ngoài luồng kia là vô ý, sai lầm, hoặc không mong muốn. Ta muốn khôi phục hạ tầng thực tế về đúng chuẩn bảo mật đã khai báo trong code HCL.
*   **Cách làm**: Chỉ cần chạy lại `terraform apply`. Terraform sẽ tự động ghi đè hoặc tạo lại (recreate) tài nguyên thực tế để đưa thuộc tính bị sửa về lại giá trị khai báo trong file cấu hình `.tf`.

#### Lựa chọn 2: Cập nhật Code để chấp nhận Reality (Chấp nhận thay đổi)
*   **Khi nào dùng**: Khi thay đổi trực tiếp ngoài luồng là cần thiết (ví dụ: một cuộc ứng cứu khẩn cấp sửa nóng hệ thống lúc nửa đêm) và ta muốn giữ lại cấu hình mới đó một cách lâu dài.
*   **Cách làm**:
    1.  Cập nhật lại giá trị tương ứng trong code cấu hình `.tf` để khớp chính xác với những gì đã bị thay đổi trực tiếp trên Web UI.
    2.  Chạy `terraform plan` để kiểm tra. Terraform sẽ xác nhận "No changes" (Không còn lệch) và tự động cập nhật lại metadata trong file `.tfstate` cho khớp.

---

## 3. Taint và Ép buộc Tái tạo Tài nguyên (Resource Replacement)

### Khái niệm Tainted (Bị vấy bẩn)
Một tài nguyên bị coi là "tainted" trong các trường hợp:
*   **Tự động**: Trong quá trình chạy `terraform apply`, tài nguyên được tạo thành công một nửa nhưng gặp lỗi giữa chừng (ví dụ: VM tạo xong nhưng cài phần mềm lỗi). Terraform sẽ tự động đánh dấu tài nguyên đó là "tainted" trong State. Ở lần apply tiếp theo, Terraform sẽ chủ động hủy bỏ tài nguyên lỗi này và tạo mới lại từ đầu.
*   **Thủ công**: Khi ta nhận thấy một tài nguyên hoạt động không ổn định (ví dụ: hệ điều hành lỗi cấu hình sâu bên trong mà Terraform không quản lý) và muốn ép buộc tái tạo sạch lại từ đầu.

### Kỹ thuật Thay thế Tài nguyên (Replacement)

#### Phương pháp cũ (Đã bị DEPRECATED): `terraform taint`
Trước đây, ta dùng lệnh `terraform taint <resource_type>.<name>` để đánh dấu. Lệnh này trực tiếp can thiệp và sửa đổi file State. Phương pháp này hiện không còn được khuyến khích vì rủi ro cao và không đi qua quy trình phê duyệt an toàn.

#### Phương pháp hiện đại (RECOMMENDED): Tham số `-replace` trong `terraform apply`
Từ phiên bản Terraform 0.15 trở lên, HashiCorp giới thiệu tham số trực tiếp tại dòng lệnh apply:

```bash
terraform apply -replace="local_file.secure_key"
```

*   **Lợi ích**:
    *   **Không sửa đổi trực tiếp State**: Không cần thay đổi file state trước.
    *   **Có quy trình kiểm duyệt**: Khi chạy lệnh này, Terraform sẽ tạo ra một bản Plan hiển thị ký hiệu thay thế tài nguyên `-/+ replace` (hủy đi tạo lại) để kiểm duyệt trước khi áp dụng.
    *   **An toàn**: Chỉ thực hiện thay thế thực tế sau khi nhập xác nhận `yes`.
