# W10 Learning Journal & Reflection — Secure & Operate: RBAC + Secrets + Platform Integration

*   **Họ và tên:** Nguyễn Đức Chinh
*   **ID:** XB-DN26-080
*   **Group:** 3
*   **Tuần học:** Tuần 10 (15/06/2026 – 19/06/2026)
*   **Chuyên ngành:** Cloud / DevOps

---

## Nhật ký Học tập Hàng ngày (Daily Journal)

### Thứ Hai, 15/06/2026 — Day A: RBAC & Admission Policy (OPA/Gatekeeper)

> **Nhiệm vụ:** Tự học lý thuyết RBAC, phân quyền Role/RoleBinding, ClusterRole/ClusterRoleBinding, Service Account, kiểm tra quyền truy cập thông qua `kubectl auth can-i`. Tìm hiểu cơ chế Admission Controllers (Mutating/Validating), chính sách kiểm duyệt Native ValidatingAdmissionPolicy trong K8s 1.30+ và OPA Gatekeeper (ngôn ngữ Rego, ConstraintTemplate, Constraint, chế độ audit vs enforce).

#### 1. Lý thuyết thu hoạch được

*   **Hệ thống phân quyền RBAC**:
    *   Thấu hiểu sự khác biệt cốt lõi giữa **Role** (phạm vi một Namespace cụ thể) và **ClusterRole** (phạm vi toàn cụm K8s).
    *   Nắm vững cơ chế liên kết quyền thông qua **RoleBinding** (gắn quyền vào namespace nhất định) và **ClusterRoleBinding** (phân quyền quản trị diện rộng toàn cụm).
    *   Nhận thức rõ tầm quan trọng của **ServiceAccount** đối với bảo mật ứng dụng chạy bên trong Pod: Tránh chia sẻ token chung, gán đặc quyền vừa đủ (Principle of Least Privilege) giúp thu hẹp phạm vi ảnh hưởng khi Pod bị chiếm quyền.
    *   Thành thạo công cụ kiểm thử nhanh đặc quyền `kubectl auth can-i` bằng cách giả lập các đối tượng (impersonation) để xác minh tính chính xác của RBAC trước khi phân phát tài khoản.
*   **Cơ chế Admission Controllers**:
    *   Nắm vững luồng xử lý request đi qua API Server: Authenticate (Xác thực) -> Authorize (Phân quyền RBAC) -> Mutating Webhook (Sửa đổi tài nguyên nếu cần) -> Schema Validation (Kiểm tra định dạng) -> Validating Webhook (Kiểm duyệt chính sách bảo mật) -> Lưu vào etcd.
    *   **ValidatingAdmissionPolicy (Native)**: Bước tiến lớn của K8s 1.30+, hỗ trợ kiểm duyệt cấu hình tài nguyên sử dụng ngôn ngữ CEL trực tiếp mà không cần cài đặt thêm Webhook bên ngoài, giúp tối ưu hóa hiệu năng hệ thống đáng kể và đơn giản hóa việc quản trị.
*   **OPA Gatekeeper & Ngôn ngữ Rego**:
    *   Học cách viết chính sách kiểm duyệt an toàn thông qua cấu trúc tách biệt của OPA Gatekeeper: **ConstraintTemplate** (chứa logic thuật toán kiểm duyệt viết bằng Rego) và **Constraint** (khai báo tham số truyền vào và đối tượng namespace, resource cần áp dụng).
    *   Phân biệt các chế độ ngăn chặn lỗi: **Audit/Dryrun** (chỉ ghi nhận cảnh báo mà không chặn đứng hạ tầng, cực kỳ hữu dụng để rà soát hệ thống cũ) và **Enforce/Deny** (chặn đứng mọi hành vi sai quy chuẩn từ vòng gửi xe để đảm bảo tuân thủ thiết kế an toàn).

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day A tại thư mục `cloud/w10/day-a/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thư mục và hoàn thiện tệp chuyên đề `theory/01_rbac_foundations.md` chi tiết về kiến trúc phân quyền RBAC, ServiceAccount và các câu lệnh kiểm tra quyền hạn.
*   [x] Hoàn thiện tệp chuyên đề `theory/02_admission_controllers.md` về cơ chế hoạt động của Admission Controllers và giải pháp ValidatingAdmissionPolicy mới của K8s.
*   [x] Hoàn thiện tệp chuyên đề `theory/03_opa_gatekeeper.md` về OPA Gatekeeper, Rego syntax cùng ví dụ viết ConstraintTemplate và Constraint để cấm các container registry không đáng tin cậy.

---

### Thứ Ba, 16/06/2026 — Day B: Secrets Rotation & Supply Chain Security

> **Nhiệm vụ:** Tự học lý thuyết Secrets Rotation, AWS Secrets Manager + External Secrets Operator (ESO), quét lỗ hổng ảnh container bằng Trivy trong CI, ký số ảnh container bằng Cosign (keyless OIDC + key-based) và xác thực chữ ký số tại Admission Control qua Sigstore Policy Controller.

#### 1. Lý thuyết thu hoạch được

*   **Vấn đề xoay vòng Secret & ESO**:
    *   Nhận diện hiểm họa của việc lưu Base64 secrets tĩnh trực tiếp trên Git. Phân tích sự cần thiết của cơ chế rotation (xoay vòng mật khẩu tự động) trên AWS Secrets Manager kết hợp với External Secrets Operator (ESO) để tự động hóa việc đồng bộ bí mật vào cụm.
    *   Phân tích cơ chế nạp cấu hình: Sử dụng biến môi trường (Environment Variables) bắt buộc phải restart Pod để nhận giá trị mới; sử dụng Volume Mount cho phép Kubelet tự cập nhật tệp tin gắn trong container. Kết hợp với cơ chế lắng nghe tệp tin thay đổi (File Watcher) trong code ứng dụng, ta đạt được Zero-Downtime Secrets Rotation thực thụ.
*   **Quét lỗ hổng ảnh container (Trivy)**:
    *   Hiểu rõ triết lý Shift-left Security: quét lỗ hổng và kiểm soát cấu hình sai (misconfigurations) ngay từ phase Build trong CI pipeline thay vì phát hiện muộn ở runtime.
    *   Thành thạo cấu hình Fail-on policy (trả về mã thoát khác 0) để chặn đứng build chạy lỗi và cơ chế tạo ngoại lệ bảo mật tạm thời có quy trình phê duyệt qua `.trivyignore`.
*   **Ký số & Admission Control (Cosign & Sigstore)**:
    *   Nắm vững cơ chế ký Key-based (cặp khóa bất đối xứng tự sinh) và Keyless (ký không dùng khóa, xác thực qua danh tính OIDC của workflow build, Fulcio CA cấp cert tạm thời và Rekor ghi audit log).
    *   Hiểu cách Sigstore Policy Controller hoạt động như chốt chặn Validating Webhook cuối cùng trong cụm để chặn đứng ảnh không khớp chữ ký trong ClusterImagePolicy. Phân tích sự đánh đổi bảo mật giữa Fail-Closed và Fail-Open webhook.

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day B tại thư mục `cloud/w10/day-b/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thành công cấu trúc thư mục học tập `cloud/w10/day-b/` và hoàn thiện 4 tệp chuyên đề lý thuyết chuyên sâu:
    *   `01_eso_secrets_rotation.md`: Kiến trúc ESO, cấu hình YAML mẫu cho SecretStore, ExternalSecret và phân tích cơ chế Zero-Downtime Rotation qua Volume.
    *   `02_trivy_ci_scan.md`: Quy trình Trivy Scan trong CI, cấu hình fail-on pipeline và quản lý CVE ngoại lệ qua `.trivyignore`.
    *   `03_cosign_image_signing.md`: Cơ chế hoạt động của Cosign, so sánh Key-based vs Keyless (OIDC/Fulcio/Rekor).
    *   `04_admission_verify_signature.md`: Cơ chế Validating Webhook verify chữ ký ảnh container của Sigstore, ClusterImagePolicy bypass và phân tích Fail-Closed vs Fail-Open.

---
