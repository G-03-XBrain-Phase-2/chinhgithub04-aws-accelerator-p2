# Chuyên đề 03: OPA (Open Policy Agent) Gatekeeper và ngôn ngữ Rego

## 1. OPA Rego là gì?
*   **Open Policy Agent (OPA)** là một engine kiểm duyệt chính sách nguồn mở đa năng. **Rego** là ngôn ngữ khai báo chính sách được thiết kế chuyên biệt cho OPA để truy vấn cấu trúc dữ liệu phức tạp (như JSON/YAML) và đưa ra quyết định chấp thuận hay từ chối.
*   Rego hoạt động theo triết lý: Người dùng cung cấp dữ liệu đầu vào (Input) dưới dạng JSON, Rego thực hiện quét các điều kiện logic định sẵn trên dữ liệu này, và xuất ra kết quả (Allow/Deny).

---

## 2. Gatekeeper trong Kubernetes
**Gatekeeper** là một dự án con tối ưu hóa OPA dành riêng cho Kubernetes. Nó tích hợp OPA như một Admission Webhook của Kubernetes API Server và quản lý chính sách thông qua hai khái niệm tài nguyên (CRD):

### ConstraintTemplate (Khuôn mẫu chính sách)
*   Đóng vai trò như một "hàm" định nghĩa logic kiểm duyệt viết bằng ngôn ngữ Rego.
*   Nó khai báo cấu trúc tham số đầu vào mà chính sách chấp nhận.
*   *Ý nghĩa*: Định nghĩa **CÁCH** kiểm tra lỗi (Logic).

### Constraint (Thực thể áp dụng chính sách)
*   Sử dụng khuôn mẫu định nghĩa từ `ConstraintTemplate` và truyền các tham số cụ thể vào.
*   Khai báo phạm vi tài nguyên áp dụng chính sách (Namespaces, Kinds).
*   *Ý nghĩa*: Định nghĩa **ĐỐI TƯỢNG** và **THAM SỐ** áp dụng kiểm tra (ví dụ: áp dụng luật chặn lên namespace `demo`).

---

## 3. Khai báo YAML chuẩn mẫu

### File: `k8sdenyimage-template.yaml` (ConstraintTemplate)
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sdenyimages
spec:
  crd:
    spec:
      names:
        kind: K8sDenyImages
      validation:
        openAPIV3Schema:
          type: object
          properties:
            bannedRepositories:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdenyimages

        violation[{"msg": msg}] {
          # Lấy thông tin image từ container input
          image := input.review.object.spec.containers[_].image
          # Duyệt qua danh sách các repo bị cấm
          banned := input.parameters.bannedRepositories[_]
          # So sánh xem image có bắt đầu bằng tiền tố bị cấm không
          startswith(image, banned)
          msg := sprintf("Hình ảnh container '%v' sử dụng registry bị cấm '%v'.", [image, banned])
        }
```

### File: `k8sdenyimage-constraint.yaml` (Constraint)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDenyImages
metadata:
  name: block-untrusted-registries
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - demo
  parameters:
    bannedRepositories:
      - "docker.io/library/ubuntu" # Cấm sử dụng image Ubuntu gốc từ DockerHub công cộng
      - "untrusted.repo.com"
```

---

## 4. Chế độ vận hành (Enforce vs Audit)
Cũng giống như Native Admission, Gatekeeper hỗ trợ các chế độ thực thi linh hoạt thông qua thuộc tính `enforcementAction` trong cấu hình Constraint:

```yaml
spec:
  enforcementAction: dryrun # Chế độ giám sát (Audit) - chỉ ghi log và cảnh báo, không chặn
```

*   **dryrun**: Thử nghiệm chính sách. Khi Pod vi phạm được đẩy lên, hệ thống vẫn cho phép chạy Pod nhưng sẽ ghi nhận sự vi phạm vào log của Gatekeeper Controller và hiển thị trong trạng thái `status` của đối tượng Constraint.
*   **deny**: Chặn đứng ngay lập tức yêu cầu tạo/cập nhật tài nguyên vi phạm.
*   **warn**: Trả về cảnh báo dưới dạng Warning cho người thực hiện lệnh `kubectl apply` nhưng vẫn cho phép tạo tài nguyên thành công.
