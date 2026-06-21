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

### Thứ Tư, 17/06/2026 — Day C: Platform Integration & Cost Guard

> **Nhiệm vụ:** Tự học lý thuyết tích hợp toàn stack từ W8 đến W10, thiết lập ResourceQuota và LimitRange để phân vùng tài nguyên, tìm hiểu Chaos Engineering trên Kubernetes, xây dựng Runbooks xử lý sự cố chuẩn và nghiên cứu giải pháp giám sát AWS Cost Anomaly Detection.

#### 1. Lý thuyết thu hoạch được

*   **Quản lý định mức tài nguyên (ResourceQuota & LimitRange)**:
    *   Thấy rõ tầm quan trọng của việc thiết lập ResourceQuota ở mức namespace để ngăn ngừa hiện tượng "Noisy Neighbor" chiếm dụng tài nguyên toàn cụm.
    *   Nắm vững vai trò của LimitRange trong việc tự động inject các giá trị CPU/Memory mặc định (requests/limits) cho container khi developer không khai báo, cũng như thiết lập các giới hạn max/min để tránh lãng phí hoặc nghẽn.
    *   Hiểu rõ ràng khi một namespace đã áp ResourceQuota, bắt buộc mọi container chạy trong đó phải có khai báo resources (nếu không khai báo và không có LimitRange để inject mặc định, API Server sẽ reject yêu cầu tạo Pod).
*   **Chaos Engineering trên K8s**:
    *   Hiểu bản chất của Chaos Engineering là chủ động tiêm lỗi vào hệ thống (giả lập sập Pod, sập Node, mất gói tin mạng, DNS delay) để kiểm tra khả năng phục hồi tự động (Self-Healing) và co giãn (HPA) của cụm.
    *   Nghiên cứu các công cụ CNCF phổ biến như Chaos Mesh (giao diện UI, dễ tiêm lỗi nhanh) và LitmusChaos (hướng khai báo Operator/CRD, tích hợp tốt CI/CD).
*   **Quy trình ứng phó sự cố & Runbooks**:
    *   Nắm chắc framework xử lý sự cố 6 bước của AWS: Detect -> Triage -> Contain (cách ly) -> Eradicate (loại bỏ) -> Recover -> Post-mortem (mổ xẻ sự cố không đổ lỗi, viết RCA).
    *   Thành thạo cấu trúc viết một Runbook vận hành chuẩn gồm dấu hiệu nhận biết, các lệnh chẩn đoán nhanh (diagnostic CLI commands) và kịch bản xử lý khẩn cấp (mitigation steps) đối với các lỗi phổ biến như OOMKilled.
*   **Giám sát chi phí AWS (Cost Anomaly Detection)**:
    *   Hiểu nguyên lý hoạt động của AWS Cost Anomaly Detection dựa trên mô hình học máy (Machine Learning) để liên tục phân tích và phát hiện các chi tiêu dị thường (outliers) so với baseline lịch sử.
    *   Nắm vững quy trình phản ứng nhanh khi nhận cảnh báo chi phí tăng vọt (kiểm tra Cost Explorer theo giờ, trace CloudTrail để tìm nguồn gốc tạo tài nguyên, xóa dọn dẹp và làm việc với AWS Support).

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day C tại thư mục `cloud/w10/day-c/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thành công cấu trúc thư mục học tập `cloud/w10/day-c/` và hoàn thiện 4 tệp chuyên đề lý thuyết chuyên sâu:
    *   `01_resource_quota_limit_range.md`: Cú pháp YAML, cơ chế hoạt động và cách kết hợp ResourceQuota và LimitRange để bảo vệ cụm K8s.
    *   `02_chaos_engineering.md`: Triết lý Kỹ nghệ hỗn loạn, so sánh Chaos Mesh vs LitmusChaos và quy trình 4 bước chaos test an toàn.
    *   `03_incident_runbooks.md`: AWS 6-step IR playbook, phương pháp viết Runbook và tệp mẫu xử lý sự cố OOMKilled trên K8s.
    *   `04_cost_anomaly_detection.md`: Cơ chế ML của AWS Cost Anomaly Detection, các loại Monitor, cách cấu hình alert qua SNS/Email và kịch bản Cost Incident Runbook.

---

### Thứ Năm + Thứ Sáu, 18-19/06/2026 — Onsite Lab & Challenge: Platform Hardening & Multi-tenancy Isolation

> **Nhiệm vụ:** Thực hiện khắc phục 6 rủi ro bảo mật chính của cụm Kubernetes (RBAC, Gatekeeper Policies, Custom ConstraintTemplate), tích hợp xoay vòng secret qua AWS Secrets Manager và ESO dưới 60 giây (Zero-Downtime), thiết lập CI Trivy Scan, ký ảnh với Cosign, onboard team payments mới với đầy đủ chính sách cô lập Multi-tenancy (NetworkPolicy, LimitRange, ResourceQuota).

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
- **Tác động vĩ mô của Guardrails**: Thấu hiểu tính kế thừa tự động của các chính sách ở phạm vi Cluster (Cluster-scoped) như Gatekeeper Constraints và ClusterImagePolicy. Nhờ đó, bất kỳ namespace mới nào (như `payments`) đều tự động chịu sự kiểm duyệt mà không cần nhân bản cấu hình hoặc can thiệp thủ công.
- **Ranh giới cô lập NetworkPolicy**: Nắm rõ cách viết chính sách mạng cô lập Multi-tenancy thông qua kết hợp `namespaceSelector` và `podSelector`. Hiểu cách chặn đứng kết nối chéo giữa các tenant nhưng vẫn giữ thông suốt cho DNS nội bộ và quyền truy cập internet.
- **Xác thực chữ ký số & Khắc phục lỗ hổng**: Khẳng định sự an toàn khi kết hợp quét lỗ hổng ảnh container (Trivy) ở CI và verify chữ ký số (Cosign) tại Admission Control (Sigstore Policy Controller). Thấu hiểu vì sao deploy ảnh chưa ký bị chặn ngay ở vòng gửi xe (Admission Webhook).

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
- [x] Phân quyền thành công 3 Role rõ rệt (Developer, SRE, Viewer) cho các namespaces và kiểm chứng phân quyền least-privilege cho team payments.
- [x] Thiết lập thành công 4 Gatekeeper Constraints bảo vệ cụm khỏi các manifest không an toàn (latest tag, no limits, run-as-root, hostNetwork).
- [x] Tự định nghĩa thành công Custom ConstraintTemplate yêu cầu bắt buộc có label `owner` cho Deployment/Pod.
- [x] Tích hợp thành công AWS Secrets Manager với ESO và kiểm chứng đồng bộ mật khẩu dưới 60 giây không cần restart Pod (Zero-Downtime rotation qua volume mount).
- [x] Thực thi thành công Trivy Scan chặn merge PR chứa lỗ hổng bảo mật và verify Sigstore Policy Controller chặn đứng ảnh container chưa ký số.
- [x] Cấu hình LimitRange tự động inject resources mặc định cho các Pod của team payments để bypass Gatekeeper và ResourceQuota.
- [x] Áp dụng thành công NetworkPolicy chặn đứng kết nối chéo giữa namespace `payments` và `demo`, verify lỗi Timeout trong khi DNS nội bộ và internet vẫn thông suốt.
- [x] Hoàn thiện toàn bộ báo cáo và lưu trữ ảnh minh chứng tại tệp tin [README.md](lab/README.md).

---
