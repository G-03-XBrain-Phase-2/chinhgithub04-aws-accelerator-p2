# Chuyên đề 02: Admission Controllers và ValidatingAdmissionPolicy (Native)

## 1. Khái niệm Admission Controllers
*   **Admission Controller** là một thành phần trung gian (như một chốt bảo vệ) trong Kubernetes API Server. Nó sẽ can thiệp vào các yêu cầu gửi đến API Server **sau khi** yêu cầu đã được xác thực (Authentication) và phân quyền (Authorization) thành công, nhưng **trước khi** trạng thái tài nguyên được ghi nhận vào cơ sở dữ liệu `etcd`.
*   Có hai loại Admission Controllers chính:
    1.  **Mutating Admission Controllers**: Có khả năng sửa đổi nội dung của tài nguyên gửi đến (ví dụ: tự động inject Sidecar container, tự động gán tài nguyên mặc định). Chạy trước.
    2.  **Validating Admission Controllers**: Chỉ kiểm tra tính hợp lệ của tài nguyên theo các chính sách định sẵn và đưa ra quyết định cho phép (Allow) hoặc từ chối (Reject) yêu cầu. Chạy sau.

---

## 2. ValidatingAdmissionPolicy (K8s 1.30+ Native)
*   Trước đây, để viết các chính sách kiểm duyệt tài nguyên tùy biến phức tạp (ví dụ: "mọi Pod phải chạy non-root", "mọi Service phải có label specific"), cộng đồng bắt buộc phải cài đặt các công cụ bên thứ ba như OPA/Gatekeeper hoặc Kyverno.
*   Từ phiên bản Kubernetes 1.30 (đã stable), K8s giới thiệu **ValidatingAdmissionPolicy** – giải pháp khai báo chính sách kiểm duyệt **gốc (Native)** ngay trong lõi Kubernetes mà không cần cài đặt thêm webhook mở rộng. Nó sử dụng ngôn ngữ biểu diễn biểu thức **CEL (Common Expression Language)** của Google, giúp xử lý cực kỳ nhanh chóng và giảm thiểu tải cho API Server.

---

## 3. Khai báo YAML chuẩn mẫu

### File: `require-labels-policy.yaml` (Định nghĩa luật kiểm tra dùng CEL)
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: "require-environment-label"
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   ["apps"]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["deployments"]
  variables:
  - name: hasEnv
    expression: "has(object.metadata.labels) && 'env' in object.metadata.labels"
  validations:
  - expression: "variables.hasEnv"
    message: "Tài nguyên Deployment bắt buộc phải chứa label 'env' (ví dụ: env: production hoặc env: staging) để phân loại môi trường."
```

### File: `require-labels-binding.yaml` (Ràng buộc áp dụng luật lên namespace)
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: "require-environment-label-binding"
spec:
  policyName: "require-environment-label"
  validationActions: [Deny] # Quyết định reject ngay nếu vi phạm
  matchResources:
    namespaceSelector:
      matchLabels:
        security-enforcement: "enabled"
```

---

## 4. Chế độ hoạt động: Audit (Giám sát) vs Enforce (Thực thi)
Khi triển khai các chính sách kiểm duyệt vào cụm production đang hoạt động, việc áp dụng thẳng chế độ ngăn chặn có thể làm gãy các ứng dụng đang chạy bình thường. Do đó quy trình khuyến nghị bao gồm:

*   **Chế độ Audit (Giám sát)**: 
    *   Hệ thống cho phép tạo tài nguyên bình thường kể cả khi vi phạm luật, nhưng sẽ ghi nhận lại sự vi phạm vào log hệ thống (Audit Log) hoặc phát ra Warning.
    *   *Mục đích*: Giúp quản trị viên thống kê những tài nguyên nào chưa tuân thủ chính sách để sửa đổi trước mà không làm gián đoạn hệ thống.
*   **Chế độ Enforce/Deny (Ngăn chặn triệt để)**:
    *   API Server lập tức từ chối và trả về lỗi `403 Forbidden` kèm thông điệp giải thích lý do vi phạm luật.
    *   *Mục đích*: Bảo vệ độ an toàn tuyệt đối cho cụm, ngăn chặn mọi cấu hình rủi ro lọt vào cụm.
