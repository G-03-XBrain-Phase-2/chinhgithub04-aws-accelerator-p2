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
