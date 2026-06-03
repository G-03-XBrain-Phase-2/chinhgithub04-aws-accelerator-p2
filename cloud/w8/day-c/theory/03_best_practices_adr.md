# Chuyên đề 03: Terraform Best Practices và Quyết định Thiết kế Kiến trúc (ADR)

Triển khai mã nguồn hạ tầng (IaC) thành công đòi hỏi không chỉ kỹ năng lập trình mà còn cả tư duy quản lý vận hành dài hạn. Chuyên đề này tổng hợp các chuẩn mực thực thi tốt nhất (Best Practices) và giới thiệu cách ghi nhận nhật ký kiến trúc hệ thống bằng ADR.

---

## 1. Các Best Practices quan trọng trong Terraform

Để giữ hệ thống ổn định, dễ mở rộng và bảo mật, ta cần tuân thủ các nguyên tắc sau:

### Đặt tên nhất quán (Naming Conventions)
- Sử dụng dấu gạch dưới `_` thay vì gạch ngang `-` khi đặt tên tài nguyên (ví dụ: `resource "aws_s3_bucket" "static_web"` thay vì `static-web`).
- Tên tài nguyên nội bộ không nên lặp lại loại tài nguyên đó (ví dụ: đặt `aws_iam_role "webapp"` thay vì `aws_iam_role "webapp_role"`).

### Phân tách môi trường (Environment Isolation)
- **Không dùng chung State**: Phân chia thư mục backend của các môi trường (Dev, Staging, Production) độc lập hoàn toàn. Lỗi cấu hình ở môi trường Dev không được phép ảnh hưởng đến State của Production.
- Sử dụng cấu trúc thư mục phân tách (Directory-based Isolation) thay vì sử dụng Workspace của Terraform đối với hạ tầng Cloud lớn vì tính trực quan và an toàn cao hơn.

### Khóa phiên bản chặt chẽ (Versioning)
- Luôn khóa phiên bản của nhà cung cấp dịch vụ (Providers) và phiên bản của Terraform Core để tránh tình trạng hạ tầng bị lỗi khi chạy ở môi trường CI/CD khác nhau.
- Cam kết tệp tin khóa `.terraform.lock.hcl` lên kho lưu trữ Git.

### Bảo mật mã khóa (Secrets Management)
- Tuyệt đối không hardcode mật khẩu, token bảo mật vào mã nguồn.
- Sử dụng biến môi trường hoặc các hệ thống quản lý khóa tập trung (AWS Secrets Manager, Vault) để lấy thông tin kết nối an toàn tại runtime.

---

## 2. Quyết định Thiết kế Kiến trúc (ADR - Architecture Decision Record)

### ADR là gì?
- ADR là một tài liệu kỹ thuật ghi chép lại các quyết định thiết kế quan trọng liên quan đến kiến trúc hạ tầng, lý do đưa ra quyết định đó và các tác động đi kèm đối với dự án.
- **Tại sao cần dùng?**: Trong các dự án IaC, kiến trúc thay đổi liên tục. Nếu không ghi nhận lại, các kỹ sư mới tham gia sẽ không hiểu lý do tại sao hệ thống lại được xây dựng như hiện tại (ví dụ: Tại sao chọn S3 Backend mà không chọn Terraform Cloud?).

### Cấu trúc tiêu chuẩn của một tài liệu ADR

Một tài liệu ADR thông thường gồm các phần chính sau:
1. **Tiêu đề**: Tên quyết định ngắn gọn và mã số định danh (Ví dụ: `ADR-001: Sử dụng S3 và DynamoDB làm Backend lưu trữ State`).
2. **Bối cảnh (Context)**: Vấn đề hiện tại cần giải quyết là gì, các ràng buộc kỹ thuật là gì.
3. **Quyết định (Decision)**: Giải pháp kỹ thuật được chọn để thực thi.
4. **Trạng thái (Status)**: Đề xuất (Proposed), Đã duyệt (Accepted), Bị từ chối (Rejected) hoặc Bị thay thế (Superseded).
5. **Hậu quả (Consequences)**: Những tác động tích cực và tiêu cực sau khi giải pháp được áp dụng.

### Ví dụ về một ADR thực tế cho Terraform Backend

```markdown
# ADR-001: Cấu hình lưu trữ State tập trung và Khóa State trên AWS

## Trạng thái
Accepted (Đã phê duyệt)

## Bối cảnh
Dự án có sự tham gia của 3 kỹ sư Cloud cùng thiết lập hạ tầng AWS. Hiện tại, tệp State đang được lưu cục bộ trên máy cá nhân, dẫn đến nguy cơ ghi đè chồng chéo cấu hình và rò rỉ dữ liệu nhạy cảm nếu đẩy lên Git.

## Quyết định
Chúng ta quyết định:
1. Di chuyển toàn bộ tệp State lên lưu trữ từ xa trên AWS S3 Bucket.
2. Bật tính năng S3 Versioning để sao lưu lịch sử State.
3. Sử dụng bảng DynamoDB (tên khóa phân hoạch: `LockID`) để thực hiện cơ chế khóa State.

## Hậu quả
- **Tích cực**: Giải quyết triệt để vấn đề xung đột ghi đè State; dữ liệu State được mã hóa an toàn và kiểm soát quyền truy cập chặt chẽ.
- **Tiêu cực**: Tăng chi phí quản lý vận hành nhỏ cho dịch vụ S3 và DynamoDB trên tài khoản AWS.
```
